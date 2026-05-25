-- ============================================
-- Mikro ERP: Detayli Cari Risk Raporu (046355)
-- fn_CariRiskFoyu Analizi ile Ciro, Risk, Teminat
-- Kaynak: https://mikroerp.dev/blog/mikro-erp-cari-risk-raporu-fn-caririsklfoyu-analizi
-- Uyumluluk: Mikro V16, V17
-- Son Guncelleme: 2026-05-25
-- ============================================
-- 
-- Bu sorgu Mikro ERP 046355 (Detayli Cari Hesap Bakiye-Ciro-Risk-Teminat
-- Karsilastirma Raporu) sonuclarini SQL ile birebir uretir.
-- 
-- Onemli:
--   - fn_CariRiskFoyu fonksiyonu veritabaninda mevcut olmalidir
--   - fn_Evrak_Kalan_Miktar, fn_KurBul, fn_CariKurTipi fonksiyonlari gereklidir
--   - 1600+ cari icin ~15 dk surer (Mikro orijinali 45+ dk)
--   - Temp tablo + clustered index ile optimize edilmistir
-- ============================================

SET NOCOUNT ON;

-- =============================================
-- ⚙️ AYARLAR: Kendi ortaminiza gore degistirin
-- =============================================
DECLARE @FirmaNo INT = 0;
DECLARE @Tarih DATETIME = GETDATE();
DECLARE @CiroBaslangicTarihi DATETIME = '20260101';  -- ⚙️ Ciro baslangici
DECLARE @CariKodLike NVARCHAR(25) = 'M.35%';         -- ⚙️ Cari filtresi
DECLARE @SrmMerkezKodu NVARCHAR(25) = '';
DECLARE @BagliCarileriBirlikteHesapla BIT = 0;
DECLARE @TeminattaVadeKontrol BIT = 0;
DECLARE @SiparisIrsaliyeKDVDahil BIT = 0;            -- ⚙️ KDV dahil/haric
DECLARE @CiroCekRiskSuresiGun INT = 10;               -- ⚙️ Cek risk suresi
DECLARE @CiroSenetRiskSuresiGun INT = 30;              -- ⚙️ Senet risk suresi

DECLARE @CiroCekIlkVade DATETIME 
    = DATEADD(DAY, -@CiroCekRiskSuresiGun, @Tarih);
DECLARE @CiroSenetIlkVade DATETIME 
    = DATEADD(DAY, -@CiroSenetRiskSuresiGun, @Tarih);

IF OBJECT_ID('tempdb..#CariBase') IS NOT NULL DROP TABLE #CariBase;
IF OBJECT_ID('tempdb..#Ciro') IS NOT NULL DROP TABLE #Ciro;
IF OBJECT_ID('tempdb..#AcikSiparis') IS NOT NULL DROP TABLE #AcikSiparis;
IF OBJECT_ID('tempdb..#RiskOzet') IS NOT NULL DROP TABLE #RiskOzet;

------------------------------------------------------------
-- 1) Cari listesi
------------------------------------------------------------
SELECT
    ch.cari_kod,
    ch.cari_unvan1,
    ch.cari_unvan2,
    ch.cari_temsilci_kodu
INTO #CariBase
FROM CARI_HESAPLAR ch WITH (NOLOCK)
WHERE ch.cari_kod LIKE @CariKodLike;

CREATE UNIQUE CLUSTERED INDEX IX_CariBase ON #CariBase(cari_kod);

------------------------------------------------------------
-- 2) Toplam ciro — STOK_HAREKETLERI net satis satir toplami
------------------------------------------------------------
SELECT
    sth.sth_cari_kodu AS cari_kod,
    SUM(
        CASE WHEN ISNULL(sth.sth_normal_iade, 0) = 1 
             THEN -1 ELSE 1 END
        * (
            ISNULL(sth.sth_tutar, 0)
            - (ISNULL(sth.sth_iskonto1, 0) + ISNULL(sth.sth_iskonto2, 0)
             + ISNULL(sth.sth_iskonto3, 0) + ISNULL(sth.sth_iskonto4, 0)
             + ISNULL(sth.sth_iskonto5, 0) + ISNULL(sth.sth_iskonto6, 0))
            + (ISNULL(sth.sth_masraf1, 0) + ISNULL(sth.sth_masraf2, 0)
             + ISNULL(sth.sth_masraf3, 0) + ISNULL(sth.sth_masraf4, 0))
        )
    ) AS ToplamCiro
INTO #Ciro
FROM STOK_HAREKETLERI sth WITH (NOLOCK)
JOIN #CariBase cb ON cb.cari_kod = sth.sth_cari_kodu
WHERE sth.sth_tarih >= @CiroBaslangicTarihi
  AND sth.sth_tarih <= @Tarih
  AND ISNULL(sth.sth_iptal, 0) = 0
  AND sth.sth_fat_uid IS NOT NULL
  AND sth.sth_fat_uid <> '00000000-0000-0000-0000-000000000000'
GROUP BY sth.sth_cari_kodu;

CREATE UNIQUE CLUSTERED INDEX IX_Ciro ON #Ciro(cari_kod);

------------------------------------------------------------
-- 3) Acik siparis — KDV parametresiyle
------------------------------------------------------------
SELECT
    sip.sip_musteri_kod AS cari_kod,
    SUM(
        CASE WHEN sip.sip_tip = 0 THEN 1 ELSE -1 END
        * dbo.fn_Evrak_Kalan_Miktar(
            sip.sip_miktar, sip.sip_teslim_miktar, sip.sip_kapat_fl
          )
        * (
            (
                sip.sip_tutar
                - (sip.sip_iskonto_1 + sip.sip_iskonto_2 
                 + sip.sip_iskonto_3 + sip.sip_iskonto_4
                 + sip.sip_iskonto_5 + sip.sip_iskonto_6)
                + (sip.sip_masraf_1 + sip.sip_masraf_2
                 + sip.sip_masraf_3 + sip.sip_masraf_4)
                + CASE WHEN @SiparisIrsaliyeKDVDahil = 1
                    THEN (sip.sip_vergi + sip.sip_masvergi 
                        + sip.sip_Otv_Vergi + sip.sip_otvtutari)
                    ELSE 0 END
            ) / NULLIF(sip.sip_miktar, 0)
        )
        * CASE WHEN sip.sip_doviz_cinsi > 0
            THEN dbo.fn_KurBul(
                @Tarih, sip.sip_doviz_cinsi,
                dbo.fn_CariKurTipi(sip.sip_musteri_kod)
            )
            ELSE 1 END
    ) AS AcikSiparisTutar
INTO #AcikSiparis
FROM SIPARISLER sip WITH (NOLOCK)
JOIN #CariBase cb ON cb.cari_kod = sip.sip_musteri_kod
WHERE sip.sip_kapat_fl = 0
  AND sip.sip_miktar > sip.sip_teslim_miktar
  AND (sip.sip_cari_sormerk = @SrmMerkezKodu OR @SrmMerkezKodu = '')
GROUP BY sip.sip_musteri_kod;

CREATE UNIQUE CLUSTERED INDEX IX_AcikSiparis 
    ON #AcikSiparis(cari_kod);

------------------------------------------------------------
-- 4) Risk ozet — fn_CariRiskFoyu (en agir bolum)
------------------------------------------------------------
SELECT
    cb.cari_kod,
    SUM(ISNULL(rf.[msg_S_1480\T], 0)) AS KrediToplami,
    SUM(ISNULL(rf.[msg_S_1476\T], 0)) AS KullanilanKredi,
    SUM(CASE WHEN rf.[#msg_S_1720] = 1 
        THEN ISNULL(rf.[msg_S_0103\T], 0) ELSE 0 END) AS AcikHesap,
    SUM(CASE WHEN rf.[#msg_S_1720] = 8 
        THEN ISNULL(rf.[msg_S_0103\T], 0) ELSE 0 END) 
        AS FaturalasmamisIrsaliye,
    SUM(CASE WHEN rf.[#msg_S_1720] = 2 
        THEN ISNULL(rf.[msg_S_0103\T], 0) ELSE 0 END) AS KendiCeki,
    SUM(CASE WHEN rf.[#msg_S_1720] = 3 
        THEN ISNULL(rf.[msg_S_0103\T], 0) ELSE 0 END) 
        AS MusterisininCeki,
    SUM(CASE WHEN rf.[#msg_S_1720] = 4 
        THEN ISNULL(rf.[msg_S_0103\T], 0) ELSE 0 END) AS KendiSenedi,
    SUM(CASE WHEN rf.[#msg_S_1720] = 5 
        THEN ISNULL(rf.[msg_S_0103\T], 0) ELSE 0 END) 
        AS MusterisininSenedi
INTO #RiskOzet
FROM #CariBase cb
CROSS APPLY dbo.fn_CariRiskFoyu(
    @FirmaNo, cb.cari_kod,
    @CiroCekIlkVade, @CiroSenetIlkVade, @Tarih,
    0, @SrmMerkezKodu,
    @TeminattaVadeKontrol, @BagliCarileriBirlikteHesapla
) rf
GROUP BY cb.cari_kod;

CREATE UNIQUE CLUSTERED INDEX IX_RiskOzet ON #RiskOzet(cari_kod);

------------------------------------------------------------
-- 5) Final rapor
------------------------------------------------------------
SELECT
    cb.cari_kod                     AS [Cari hesap kodu],
    LTRIM(RTRIM(
        ISNULL(cb.cari_unvan1, '') + ' ' + ISNULL(cb.cari_unvan2, '')
    ))                              AS [Cari hesap adi],
    cb.cari_temsilci_kodu           AS [Temsilci kodu],
    ROUND(ISNULL(c.ToplamCiro, 0), 2)         AS [Toplam ciro],
    ROUND(ISNULL(ro.KrediToplami, 0), 2)      AS [Kredi toplami],
    ROUND(ISNULL(sip.AcikSiparisTutar, 0), 2) AS [Acik siparis],
    ROUND(ISNULL(ro.FaturalasmamisIrsaliye, 0), 2) 
                                    AS [Faturalanmamis irsaliye],
    ROUND(ISNULL(ro.AcikHesap, 0), 2)         AS [Acik hesap],
    ROUND(
        ISNULL(ro.KullanilanKredi, 0) - ISNULL(ro.KrediToplami, 0), 2
    )                               AS [Kredi limiti],
    ROUND(ISNULL(ro.KendiCeki, 0), 2)         AS [Kendi ceki],
    ROUND(ISNULL(ro.MusterisininCeki, 0), 2)   AS [Musterisinin ceki],
    ROUND(ISNULL(ro.KendiSenedi, 0), 2)       AS [Kendi senedi],
    ROUND(ISNULL(ro.MusterisininSenedi, 0), 2) AS [Musterisinin senedi],
    ROUND(
        ISNULL(ro.KendiCeki, 0) + ISNULL(ro.MusterisininCeki, 0)
      + ISNULL(ro.KendiSenedi, 0) + ISNULL(ro.MusterisininSenedi, 0), 2
    )                               AS [Odenmeyen toplam],
    ROUND(
        ISNULL(ro.AcikHesap, 0) + ISNULL(sip.AcikSiparisTutar, 0)
      + ISNULL(ro.FaturalasmamisIrsaliye, 0)
      + ISNULL(ro.KendiCeki, 0) + ISNULL(ro.MusterisininCeki, 0)
      + ISNULL(ro.KendiSenedi, 0) + ISNULL(ro.MusterisininSenedi, 0), 2
    )                               AS [Toplam risk]
FROM #CariBase cb
LEFT JOIN #RiskOzet ro    ON ro.cari_kod = cb.cari_kod
LEFT JOIN #AcikSiparis sip ON sip.cari_kod = cb.cari_kod
LEFT JOIN #Ciro c          ON c.cari_kod = cb.cari_kod
WHERE ISNULL(c.ToplamCiro, 0) <> 0
   OR ISNULL(ro.KrediToplami, 0) <> 0
   OR ISNULL(sip.AcikSiparisTutar, 0) <> 0
   OR ISNULL(ro.AcikHesap, 0) <> 0
   OR ISNULL(ro.KendiCeki, 0) <> 0
   OR ISNULL(ro.MusterisininCeki, 0) <> 0
   OR ISNULL(ro.KendiSenedi, 0) <> 0
   OR ISNULL(ro.MusterisininSenedi, 0) <> 0
ORDER BY [Toplam risk] DESC, cb.cari_kod;
