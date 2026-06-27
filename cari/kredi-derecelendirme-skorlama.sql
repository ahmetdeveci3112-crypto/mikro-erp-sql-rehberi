-- ============================================
-- Mikro ERP: Cari Kredi Derecelendirme ve Risk Skorlama
-- Kaynak: https://mikroerp.dev/blog/mikro-erp-cari-kredi-derecelendirme-skorlama-sql
-- Uyumluluk: SQL Server 2016+
-- Aciklama: 5 bilesenden olusan agirlikli puanlama modeli.
--           A-E risk siniflandirmasi. Test verisi dahil,
--           Mikro ERP gerekmez. Kendi metriklerinizle doldurun.
-- Bilesenler: Tahsilat suresi (%30), Vadesinde odeme (%25),
--             Bakiye/limit (%20), Trend (%15), Cek riski (%10)
-- ============================================

-- TEST VERISI
IF OBJECT_ID('tempdb..#CariMetrikler') IS NOT NULL DROP TABLE #CariMetrikler;

CREATE TABLE #CariMetrikler (
    CariKod VARCHAR(50), CariAd VARCHAR(200),
    OrtTahsilatGun DECIMAL(10,1), VadesindeOdemeYuzde DECIMAL(5,1),
    MevcutBakiye DECIMAL(18,2), KrediLimiti DECIMAL(18,2),
    BakiyeOncekiAy DECIMAL(18,2), BakiyeIkiAyOnce DECIMAL(18,2),
    CekOrani DECIMAL(5,1)
);

INSERT INTO #CariMetrikler VALUES
    ('120.001', 'ABC Matbaa Ltd.',    28.5, 92.0, 45000,  100000, 42000,  38000,  15.0),
    ('120.002', 'XYZ Ticaret A.S.',   65.3, 48.0, 180000,  50000, 150000, 120000, 85.0),
    ('120.003', 'DEF Gida San.',      42.0, 71.0, 95000,   80000, 100000, 110000, 45.0),
    ('120.004', 'GHI Insaat',         15.2, 98.0, 12000,  200000, 15000,  10000,   0.0),
    ('120.005', 'JKL Tekstil',        88.7, 35.0, 250000,  30000, 200000, 160000, 92.0);

-- PUANLAMA + SINIFLANDIRMA
;WITH Skorlama AS (
    SELECT *,
        -- Tahsilat suresi puani (0-100)
        CASE WHEN OrtTahsilatGun <= 30 THEN 100
             WHEN OrtTahsilatGun <= 60 THEN 100 - ((OrtTahsilatGun-30) * 100.0/90)
             WHEN OrtTahsilatGun <= 90 THEN 50 - ((OrtTahsilatGun-60) * 50.0/60)
             ELSE 0 END AS P1,
        -- Vadesinde odeme puani
        VadesindeOdemeYuzde AS P2,
        -- Bakiye/limit puani
        CASE WHEN KrediLimiti = 0 THEN 0
             WHEN MevcutBakiye/KrediLimiti <= 0.5 THEN 100
             WHEN MevcutBakiye/KrediLimiti <= 0.8 THEN 75
             WHEN MevcutBakiye/KrediLimiti <= 1.0 THEN 50
             WHEN MevcutBakiye/KrediLimiti <= 1.5 THEN 25
             ELSE 0 END AS P3,
        -- Trend puani
        CASE WHEN MevcutBakiye < BakiyeIkiAyOnce THEN 100
             WHEN MevcutBakiye = BakiyeIkiAyOnce THEN 75
             WHEN MevcutBakiye < BakiyeIkiAyOnce * 1.2 THEN 50
             WHEN MevcutBakiye < BakiyeIkiAyOnce * 1.5 THEN 25
             ELSE 0 END AS P4,
        -- Cek risk puani
        CASE WHEN CekOrani <= 20 THEN 100 WHEN CekOrani <= 40 THEN 80
             WHEN CekOrani <= 60 THEN 60 WHEN CekOrani <= 80 THEN 40
             ELSE 20 END AS P5
    FROM #CariMetrikler
)

SELECT
    CariKod AS [Cari Kodu],
    CariAd AS [Musteri],
    CONVERT(decimal(5,1), P1*0.30 + P2*0.25 + P3*0.20 + P4*0.15 + P5*0.10) AS [Kredi Skoru],
    CASE
        WHEN P1*0.30+P2*0.25+P3*0.20+P4*0.15+P5*0.10 >= 80 THEN 'A - Cok Dusuk Risk'
        WHEN P1*0.30+P2*0.25+P3*0.20+P4*0.15+P5*0.10 >= 65 THEN 'B - Dusuk Risk'
        WHEN P1*0.30+P2*0.25+P3*0.20+P4*0.15+P5*0.10 >= 50 THEN 'C - Orta Risk'
        WHEN P1*0.30+P2*0.25+P3*0.20+P4*0.15+P5*0.10 >= 35 THEN 'D - Yuksek Risk'
        ELSE 'E - Cok Yuksek Risk'
    END AS [Risk Sinifi],
    CONVERT(int, P1) AS [Tahsilat], CONVERT(int, P2) AS [Vade],
    CONVERT(int, P3) AS [Limit], CONVERT(int, P4) AS [Trend], CONVERT(int, P5) AS [Cek],
    CONVERT(VARCHAR, OrtTahsilatGun) + ' gun' AS [Ort Tahsilat],
    CONVERT(VARCHAR, CONVERT(int, VadesindeOdemeYuzde)) + '%' AS [Vadesinde %],
    CONVERT(VARCHAR, CONVERT(int, MevcutBakiye)) + ' / '
        + CONVERT(VARCHAR, CONVERT(int, KrediLimiti)) AS [Bakiye/Limit]
FROM Skorlama
ORDER BY (P1*0.30 + P2*0.25 + P3*0.20 + P4*0.15 + P5*0.10) DESC;

DROP TABLE #CariMetrikler;
