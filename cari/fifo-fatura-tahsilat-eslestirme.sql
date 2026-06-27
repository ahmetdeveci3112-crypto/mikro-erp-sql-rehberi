-- ============================================
-- Mikro ERP: FIFO Fatura-Tahsilat Eslestirme
-- Kaynak: https://mikroerp.dev/blog/mikro-erp-fifo-fatura-tahsilat-eslestirme-sql
-- Uyumluluk: Mikro V16, V17 | SQL Server 2016+
-- Aciklama: Window Function ile kumulatif toplam ve aralik kesisim
--           formuluyle set-based FIFO eslestirme. Cursor gerektirmez.
--           Test verisi dahil — herhangi bir SQL Server'da calisir.
-- ============================================

-- TEST VERISI
IF OBJECT_ID('tempdb..#Faturalar') IS NOT NULL DROP TABLE #Faturalar;
IF OBJECT_ID('tempdb..#Odemeler') IS NOT NULL DROP TABLE #Odemeler;

CREATE TABLE #Faturalar (FaturaNo VARCHAR(10), Tarih DATE, Tutar DECIMAL(18,2));
CREATE TABLE #Odemeler (OdemeNo VARCHAR(10), Tarih DATE, Tutar DECIMAL(18,2));

INSERT INTO #Faturalar VALUES
    ('F001', '2026-01-10', 50000),
    ('F002', '2026-01-20', 80000),
    ('F003', '2026-02-05', 30000);

INSERT INTO #Odemeler VALUES
    ('T001', '2026-02-15', 60000),
    ('T002', '2026-03-10', 70000);

-- FIFO ESLESTIRME
;WITH BorcCum AS (
    SELECT
        FaturaNo, Tarih AS FaturaTarihi, Tutar,
        SUM(Tutar) OVER (ORDER BY Tarih, FaturaNo
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS CumTutar
    FROM #Faturalar
),
AlacakCum AS (
    SELECT
        OdemeNo, Tarih AS OdemeTarihi, Tutar,
        SUM(Tutar) OVER (ORDER BY Tarih, OdemeNo
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS CumTutar
    FROM #Odemeler
),
Kesisim AS (
    SELECT
        b.FaturaNo, b.FaturaTarihi, b.Tutar AS FaturaTutar,
        a.OdemeNo, a.OdemeTarihi, a.Tutar AS OdemeTutar,
        CASE
            WHEN (CASE WHEN b.CumTutar < a.CumTutar
                       THEN b.CumTutar ELSE a.CumTutar END)
               - (CASE WHEN b.CumTutar - b.Tutar > a.CumTutar - a.Tutar
                       THEN b.CumTutar - b.Tutar
                       ELSE a.CumTutar - a.Tutar END) > 0
            THEN (CASE WHEN b.CumTutar < a.CumTutar
                       THEN b.CumTutar ELSE a.CumTutar END)
               - (CASE WHEN b.CumTutar - b.Tutar > a.CumTutar - a.Tutar
                       THEN b.CumTutar - b.Tutar
                       ELSE a.CumTutar - a.Tutar END)
            ELSE 0
        END AS KapananParca,
        DATEDIFF(DAY, b.FaturaTarihi, a.OdemeTarihi) AS GunFarki
    FROM BorcCum b
    INNER JOIN AlacakCum a
        ON a.CumTutar > b.CumTutar - b.Tutar
        AND a.CumTutar - a.Tutar < b.CumTutar
)

SELECT
    FaturaNo, FaturaTarihi, FaturaTutar,
    OdemeNo, OdemeTarihi, OdemeTutar,
    CONVERT(decimal(18,2), KapananParca) AS [Kapanan Parca],
    GunFarki AS [Gun Farki]
FROM Kesisim
WHERE KapananParca > 0
ORDER BY FaturaNo, OdemeNo;

-- TEMIZLIK
DROP TABLE #Faturalar;
DROP TABLE #Odemeler;
