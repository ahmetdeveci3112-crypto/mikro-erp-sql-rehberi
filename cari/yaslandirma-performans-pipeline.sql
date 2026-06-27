-- ============================================
-- Mikro ERP: Cari Yaslandirma Performans Pipeline
-- Kaynak: https://mikroerp.dev/blog/mikro-erp-cari-yaslandirma-performans-optimizasyon
-- Uyumluluk: Mikro V16, V17 | SQL Server 2016+
-- Aciklama: fn_Aysm darbogazi icin onfiltreleme + sifir bakiye
--           eleme pipeline'i. fn_Aysm (dogru/yavas) veya
--           manuel hesaplama (hizli/yaklasik) secenekleri.
-- ============================================

SET NOCOUNT ON;
DECLARE @BakiyeTarih DATE = GETDATE();
DECLARE @CariPrefix VARCHAR(10) = '120%'; -- << CARI PREFIX'INIZI DEGISTIRIN

-- ADIM 1: Aktif cari filtresi
IF OBJECT_ID('tempdb..#AktifCariler') IS NOT NULL DROP TABLE #AktifCariler;

SELECT DISTINCT cha_kod AS cari_kod
INTO #AktifCariler
FROM CARI_HESAP_HAREKETLERI WITH (NOLOCK)
WHERE cha_kod LIKE @CariPrefix
  AND cha_tarihi <= @BakiyeTarih
  AND cha_iptal = 0;

PRINT 'Aktif cari sayisi: ' + CAST(@@ROWCOUNT AS VARCHAR);

-- ADIM 2: Bakiye hesapla (fn_Aysm veya basit)
IF OBJECT_ID('tempdb..#HamBakiye') IS NOT NULL DROP TABLE #HamBakiye;

-- Secim A: fn_Aysm ile (dogru ama yavas)
/*
SELECT cari_kod,
    CONVERT(decimal(18,2),
        dbo.fn_Aysm_v2_CariHesapAnaDovizBakiye(
            '', 0, cari_kod, '', '', NULL, NULL, @BakiyeTarih, 0, 0, 0, 0, 0
        )) AS HamBakiye
INTO #HamBakiye
FROM #AktifCariler;
*/

-- Secim B: Manuel hesaplama (hizli ama yaklasik)
SELECT
    a.cari_kod,
    SUM(CASE WHEN ch.cha_tip = 0 THEN ch.cha_meblag ELSE -ch.cha_meblag END) AS HamBakiye
INTO #HamBakiye
FROM #AktifCariler a
INNER JOIN CARI_HESAP_HAREKETLERI ch WITH (NOLOCK)
    ON a.cari_kod = ch.cha_kod
WHERE ch.cha_iptal = 0
  AND ch.cha_tarihi <= @BakiyeTarih
GROUP BY a.cari_kod;

-- ADIM 3: Sifir bakiye ele + sonuc
SELECT
    b.cari_kod AS [Cari Kodu],
    c.cari_unvan1 AS [Musteri],
    b.HamBakiye AS [Bakiye],
    CASE WHEN b.HamBakiye > 0 THEN 'Borclu' ELSE 'Alacakli' END AS [Tip]
FROM #HamBakiye b
INNER JOIN CARI_HESAPLAR c WITH (NOLOCK)
    ON b.cari_kod = c.cari_kod
WHERE b.HamBakiye <> 0
ORDER BY ABS(b.HamBakiye) DESC;

-- ISTATISTIK
SELECT
    (SELECT COUNT(*) FROM CARI_HESAPLAR WHERE cari_kod LIKE @CariPrefix) AS [Toplam Cari],
    (SELECT COUNT(*) FROM #AktifCariler) AS [Aktif Cari],
    (SELECT COUNT(*) FROM #HamBakiye WHERE HamBakiye <> 0) AS [Bakiyesi Olan],
    (SELECT COUNT(*) FROM #HamBakiye WHERE HamBakiye = 0) AS [Sifir Bakiye];

-- TEMIZLIK
DROP TABLE #AktifCariler;
DROP TABLE #HamBakiye;
SET NOCOUNT OFF;
