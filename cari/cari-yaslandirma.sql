-- ============================================
-- Mikro ERP: Cari Yaslandirma - Bakiye Dagitimli (FIFO Aging)
-- Kaynak: https://mikroerp.dev/blog/mikro-erp-cari-yaslandirma-sql-sorgusu
-- Uyumluluk: Mikro V16, V17
-- ONEMLI: Bu sorgu fn_Aysm fonksiyonlarini gerektirir!
--         Fonksiyonlar yoksa ../fonksiyonlar/ klasorune bakiniz.
-- ============================================
-- 7 Adimli Production-Ready Yaslandirma Sorgusu
-- Bakiye dagitim mantigi: En yeni faturadan baslayarak
-- FIFO yontemiyle bakiyeyi ay'lara dagitir.
-- ============================================

SET NOCOUNT ON;

-- ============================================
-- DEGISTIRMENIZ GEREKEN YERLER:
-- @BakiyeTarih  -> Raporun cekilecegi tarih
-- cha_kod LIKE  -> Cari kod prefix filtresi (istege bagli)
-- ============================================

DECLARE @BakiyeTarih datetime = GETDATE();
DECLARE @GunTarih date = CAST(@BakiyeTarih AS date);

-- Temp tablolari temizle
IF OBJECT_ID('tempdb..#AktifCariler') IS NOT NULL DROP TABLE #AktifCariler;
IF OBJECT_ID('tempdb..#HamBakiye') IS NOT NULL DROP TABLE #HamBakiye;
IF OBJECT_ID('tempdb..#Bakiye') IS NOT NULL DROP TABLE #Bakiye;
IF OBJECT_ID('tempdb..#Kaynak') IS NOT NULL DROP TABLE #Kaynak;
IF OBJECT_ID('tempdb..#Dagitim') IS NOT NULL DROP TABLE #Dagitim;

-- ============================================
-- ADIM 1: Aktif Carileri Belirleme
-- Sadece hareket gormus carileri cek
-- ============================================
SELECT DISTINCT cha_kod AS cari_kod
INTO #AktifCariler
FROM dbo.CARI_HESAP_HAREKETLERI WITH (NOLOCK)
WHERE cha_tarihi <= @BakiyeTarih;
-- Istege bagli: Belirli bir prefix ile filtrelemek icin:
-- AND cha_kod LIKE '120%'

-- ============================================
-- ADIM 2: Bakiye Hesaplama (fn_Aysm Fonksiyonu)
-- Mikro'nun kendi bakiye fonksiyonu ile
-- KDV, doviz kuru, masraf, tevkifat dahil hesap
-- ============================================
SELECT
    a.cari_kod,
    CONVERT(decimal(18,2),
        dbo.fn_Aysm_v2_CariHesapAnaDovizBakiye(
            '', 0, a.cari_kod, '', '',
            NULL, NULL, @BakiyeTarih, 0, 0, 0, 0, 0
        )
    ) AS HamBakiye
INTO #HamBakiye
FROM #AktifCariler a;

-- ============================================
-- ADIM 3: Bakiyeleri Ayristirma
-- Sifir bakiyeli carileri ele, borc/alacak tipini belirle
-- ============================================
SELECT
    cari_kod,
    HamBakiye   AS OrjinalBakiye,
    ABS(HamBakiye) AS NetBakiye,
    CASE 
        WHEN HamBakiye > 0 THEN 0   -- Borclu
        WHEN HamBakiye < 0 THEN 1   -- Alacakli
        ELSE -1 
    END AS Tip
INTO #Bakiye
FROM #HamBakiye
WHERE HamBakiye <> 0;

-- ============================================
-- ADIM 4: Hareketleri Cekme
-- Bakiye dagitimi icin her carinin hareketlerini,
-- tutar hesaplamasiyla birlikte cek.
-- fn_Aysm_v2_CariHesapMeblag tum vergi/masraf kalemlerini
-- hesaba katar.
-- ============================================
SELECT
    b.cari_kod AS AnaCariKod,
    b.NetBakiye,
    ch.cha_Guid,
    ch.cha_satici_kodu,
    CAST(ch.cha_tarihi AS date) AS EvrakTarihi,
    -- Vade tarihi hesabi: Mikro'da vade farkli formatlarda tutulur
    CASE
        WHEN ch.cha_vade BETWEEN 19000101 AND 20991231 THEN
            TRY_CONVERT(date, CONVERT(char(8), ch.cha_vade), 112)
        WHEN ch.cha_vade BETWEEN -36500 AND -1 THEN
            DATEADD(DAY, ABS(ch.cha_vade), CAST(ch.cha_tarihi AS date))
        ELSE NULL
    END AS VadeTarihi,
    -- Tutar hesabi (fn_Aysm meblag fonksiyonu)
    CONVERT(decimal(18,2),
        dbo.fn_Aysm_v2_CariHesapMeblag(
            ch.cha_meblag, ch.cha_aratoplam,
            ch.cha_vergi1 + ch.cha_vergi2 + ch.cha_vergi3 + ch.cha_vergi4 + 
            ch.cha_vergi5 + ch.cha_vergi6 + ch.cha_vergi7 + ch.cha_vergi8 + 
            ch.cha_vergi9 + ch.cha_vergi10 +
            ch.cha_ilave_edilecek_kdv1 + ch.cha_ilave_edilecek_kdv2 + 
            ch.cha_ilave_edilecek_kdv3 + ch.cha_ilave_edilecek_kdv4 + 
            ch.cha_ilave_edilecek_kdv5 + ch.cha_ilave_edilecek_kdv6 + 
            ch.cha_ilave_edilecek_kdv7 + ch.cha_ilave_edilecek_kdv8 + 
            ch.cha_ilave_edilecek_kdv9 + ch.cha_ilave_edilecek_kdv10,
            ch.cha_d_kur, ch.cha_altd_kur, ch.cha_karsid_kur, 
            ch.cha_cinsi, ch.cha_evrak_tip, 0,
            ch.cha_cari_cins, ch.cha_meblag_ana_doviz_icin_gecersiz_fl, 
            ch.cha_meblag_alt_doviz_icin_gecersiz_fl,
            ch.cha_meblag_orj_doviz_icin_gecersiz_fl, 
            ch.cha_ft_masraf1, ch.cha_ft_masraf2, ch.cha_ft_masraf3,
            ch.cha_ft_masraf4, ch.cha_otvtutari, ch.cha_oivtutari, 
            ch.cha_yuvarlama, ch.cha_tevkifat_toplam,
            ch.cha_stopaj, ch.cha_savsandesfonu, ch.cha_vergifon_toplam, 
            ch.cha_ticaret_turu, ch.cha_kasa_hizmet, ch.cha_kasa_hizkod
        )
    ) AS Meblag,
    ch.cha_create_date
INTO #Kaynak
FROM dbo.CARI_HESAP_HAREKETLERI ch WITH (NOLOCK)
INNER JOIN #Bakiye b
    ON (ch.cha_kod = b.cari_kod OR ch.cha_ciro_cari_kodu = b.cari_kod)
WHERE ch.cha_tarihi <= @BakiyeTarih
  AND dbo.fn_Aysm_v2_CariharBorcAlacak(
        0, ch.cha_tip, ch.cha_tpoz, ch.cha_cari_cins, ch.cha_cinsi, 0, 0, 0, 0
      ) = b.Tip
  AND ch.cha_meblag * ch.cha_d_kur > 1
  AND ch.cha_evrak_tip <> 59;

-- ============================================
-- ADIM 5: Bakiye Dagitimi (FIFO)
-- Bakiyeyi en yeniden en eskiye dogru dagit.
-- Window function ile kumulatif toplam hesaplanir.
-- ============================================
;WITH Sira AS (
    SELECT
        k.*,
        SUM(k.Meblag) OVER (
            PARTITION BY k.AnaCariKod 
            ORDER BY k.EvrakTarihi DESC, k.cha_create_date DESC, k.cha_Guid DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS KumulatifTutar
    FROM #Kaynak k
),
Dagitim AS (
    SELECT
        AnaCariKod,
        cha_Guid,
        cha_satici_kodu,
        EvrakTarihi,
        VadeTarihi,
        CASE
            -- Kumulatif tutar bakiyeden kucukse: tamamini al
            WHEN KumulatifTutar < NetBakiye THEN Meblag
            -- Bu satirda bakiyeyi gectiyse: kalan farki al
            WHEN KumulatifTutar - Meblag < NetBakiye THEN NetBakiye - (KumulatifTutar - Meblag)
            -- Bakiye zaten dolduysa: 0
            ELSE 0
        END AS DagitilanTutar
    FROM Sira
)
SELECT *
INTO #Dagitim
FROM Dagitim
WHERE DagitilanTutar > 0;

-- ============================================
-- ADIM 6: Teminat Bilgileri
-- ============================================
;WITH Teminat AS (
    SELECT
        ct_carikodu,
        SUM(ISNULL(ct_tutari, 0)) AS CariLimiti
    FROM dbo.CARI_HESAP_TEMINATLARI WITH (NOLOCK)
    WHERE ISNULL(ct_iptal, 0) = 0
    GROUP BY ct_carikodu
)

-- ============================================
-- ADIM 7: Final - Ay Bazli Yaslandirma Raporu
-- Tarih araliklarini kendi raporunuzun donemine gore guncelleyin
-- ============================================
SELECT
    c.cari_kod              AS [Hesap Kodu],
    LTRIM(RTRIM(CONCAT(
        ISNULL(c.cari_unvan1,''), ' ', ISNULL(c.cari_unvan2,'')
    )))                     AS [Hesap Adi],
    c.cari_temsilci_kodu    AS [Temsilci],
    ISNULL(a.adr_il,'')     AS [Il],
    ISNULL(a.adr_ilce,'')   AS [Ilce],
    ISNULL(b.OrjinalBakiye, 0) AS [Toplam Bakiye],
    CASE WHEN ISNULL(c.cari_cari_kilitli_flg, 0) = 1 
        THEN N'Kilitli' ELSE N'Aktif' 
    END                     AS [Durum],
    ABS(ISNULL(c.cari_odemeplan_no, 0)) AS [Vade (Gun)],
    CONVERT(decimal(18,2), ISNULL(t.CariLimiti, 0)) AS [Teminat],
    
    -- Vadesi gecen toplam
    CONVERT(decimal(18,2), SUM(
        CASE WHEN d.VadeTarihi IS NOT NULL AND d.VadeTarihi < @GunTarih 
        THEN d.DagitilanTutar ELSE 0 END
    )) AS [Vadesi Gecen],

    -- Aylik dagilim
    CONVERT(decimal(18,2), SUM(CASE 
        WHEN d.EvrakTarihi >= DATEADD(MONTH, -1, DATEFROMPARTS(YEAR(@GunTarih), MONTH(@GunTarih), 1))
         AND d.EvrakTarihi <  DATEFROMPARTS(YEAR(@GunTarih), MONTH(@GunTarih), 1)
        THEN d.DagitilanTutar ELSE 0 END)) AS [1 Ay Once],

    CONVERT(decimal(18,2), SUM(CASE
        WHEN d.EvrakTarihi >= DATEADD(MONTH, -2, DATEFROMPARTS(YEAR(@GunTarih), MONTH(@GunTarih), 1))
         AND d.EvrakTarihi <  DATEADD(MONTH, -1, DATEFROMPARTS(YEAR(@GunTarih), MONTH(@GunTarih), 1))
        THEN d.DagitilanTutar ELSE 0 END)) AS [2 Ay Once],

    CONVERT(decimal(18,2), SUM(CASE
        WHEN d.EvrakTarihi >= DATEADD(MONTH, -3, DATEFROMPARTS(YEAR(@GunTarih), MONTH(@GunTarih), 1))
         AND d.EvrakTarihi <  DATEADD(MONTH, -2, DATEFROMPARTS(YEAR(@GunTarih), MONTH(@GunTarih), 1))
        THEN d.DagitilanTutar ELSE 0 END)) AS [3 Ay Once],

    CONVERT(decimal(18,2), SUM(CASE
        WHEN d.EvrakTarihi >= DATEADD(MONTH, -6, DATEFROMPARTS(YEAR(@GunTarih), MONTH(@GunTarih), 1))
         AND d.EvrakTarihi <  DATEADD(MONTH, -3, DATEFROMPARTS(YEAR(@GunTarih), MONTH(@GunTarih), 1))
        THEN d.DagitilanTutar ELSE 0 END)) AS [3-6 Ay Once],

    CONVERT(decimal(18,2), SUM(CASE
        WHEN d.EvrakTarihi < DATEADD(MONTH, -6, DATEFROMPARTS(YEAR(@GunTarih), MONTH(@GunTarih), 1))
        THEN d.DagitilanTutar ELSE 0 END)) AS [6+ Ay Once]

FROM dbo.CARI_HESAPLAR c WITH (NOLOCK)
INNER JOIN #Bakiye b ON b.cari_kod = c.cari_kod
LEFT JOIN dbo.CARI_HESAP_ADRESLERI a WITH (NOLOCK)
    ON a.adr_cari_kod = c.cari_kod AND a.adr_adres_no = 1
LEFT JOIN Teminat t ON t.ct_carikodu = c.cari_kod
LEFT JOIN #Dagitim d ON d.AnaCariKod = c.cari_kod
GROUP BY
    c.cari_kod, c.cari_unvan1, c.cari_unvan2,
    c.cari_temsilci_kodu, a.adr_il, a.adr_ilce,
    c.cari_cari_kilitli_flg, c.cari_odemeplan_no,
    t.CariLimiti, b.OrjinalBakiye
ORDER BY b.OrjinalBakiye DESC;
