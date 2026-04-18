-- ============================================
-- Mikro ERP: Alis-Satis Kar Analizi
-- Kaynak: https://mikroerp.dev/blog/mikro-erp-alis-satis-kar-analizi-sql
-- Uyumluluk: Mikro V16, V17
-- Aciklama: Urun bazli alis maliyeti vs satis tutari karsilastirmasi.
-- ============================================

WITH SatisOzet AS (
    SELECT 
        sth_stok_kod,
        SUM(sth_miktar)  AS SatisMiktar,
        SUM(sth_tutar)   AS SatisTutar
    FROM STOK_HAREKETLERI WITH (NOLOCK)
    WHERE sth_iptal = 0
      AND sth_tip = 1 AND sth_cins IN (0,1) AND sth_normal_iade = 0
      AND sth_tarih >= CONVERT(datetime, '20260101', 112)
      AND sth_tarih <= CONVERT(datetime, '20261231', 112)
    GROUP BY sth_stok_kod
),
AlisOzet AS (
    SELECT 
        sth_stok_kod,
        SUM(sth_miktar)  AS AlisMiktar,
        SUM(sth_tutar)   AS AlisTutar
    FROM STOK_HAREKETLERI WITH (NOLOCK)
    WHERE sth_iptal = 0
      AND sth_tip = 0 AND sth_cins IN (0,2) AND sth_normal_iade = 0
      AND sth_tarih >= CONVERT(datetime, '20260101', 112)
      AND sth_tarih <= CONVERT(datetime, '20261231', 112)
    GROUP BY sth_stok_kod
)

SELECT 
    S.sto_kod                                    AS [Stok Kodu],
    S.sto_isim                                   AS [Stok Adi],
    ISNULL(A.AlisMiktar, 0)                      AS [Alis Miktar],
    ISNULL(A.AlisTutar, 0)                       AS [Alis Tutar],
    ISNULL(ST.SatisMiktar, 0)                    AS [Satis Miktar],
    ISNULL(ST.SatisTutar, 0)                     AS [Satis Tutar],
    ISNULL(ST.SatisTutar, 0) - ISNULL(A.AlisTutar, 0) AS [Brut Kar],
    CASE WHEN ISNULL(ST.SatisTutar, 0) > 0 
        THEN ROUND((ISNULL(ST.SatisTutar, 0) - ISNULL(A.AlisTutar, 0)) 
             / ST.SatisTutar * 100, 2) 
        ELSE 0 END                               AS [Kar Marji %]
FROM STOKLAR S WITH (NOLOCK)
LEFT JOIN SatisOzet ST ON S.sto_kod = ST.sth_stok_kod
LEFT JOIN AlisOzet A ON S.sto_kod = A.sth_stok_kod
WHERE ISNULL(ST.SatisTutar, 0) > 0
ORDER BY [Brut Kar] DESC;
