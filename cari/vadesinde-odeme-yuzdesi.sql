-- ============================================
-- Mikro ERP: Vadesinde Odeme Yuzdesi + Aylik Trend
-- Kaynak: https://mikroerp.dev/blog/mikro-erp-vadesinde-odeme-yuzdesi-sql
-- Uyumluluk: Mikro V16, V17 | SQL Server 2016+
-- Aciklama: FIFO parca bazli fatura-tahsilat eslestirmesiyle
--           vadesinde odeme yuzdesi, ortalama gecikme gunu ve
--           aylik trend analizi. Kredi derecelendirme giris verisi.
-- ============================================

DECLARE @CariKod VARCHAR(50) = '120.001'; -- << BURAYA KENDI CARI KODUNUZU YAZIN

IF OBJECT_ID('tempdb..#Kesisim') IS NOT NULL DROP TABLE #Kesisim;

;WITH Borclar AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY cha_tarihi ASC, cha_create_date ASC) AS SiraNo,
        CAST(cha_tarihi AS date) AS FaturaTarihi,
        cha_meblag AS Tutar,
        CASE
            WHEN cha_vade BETWEEN 19000101 AND 20991231
            THEN TRY_CONVERT(date, CONVERT(char(8), cha_vade), 112)
            WHEN cha_vade BETWEEN -36500 AND -1
            THEN DATEADD(DAY, ABS(cha_vade), CAST(cha_tarihi AS date))
            ELSE NULL
        END AS VadeTarihi
    FROM CARI_HESAP_HAREKETLERI WITH (NOLOCK)
    WHERE cha_kod = @CariKod
      AND cha_tip = 0 AND cha_iptal = 0 AND cha_meblag > 0
),
Alacaklar AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY cha_tarihi ASC, cha_create_date ASC) AS SiraNo,
        CAST(cha_tarihi AS date) AS OdemeTarihi,
        cha_meblag AS Tutar
    FROM CARI_HESAP_HAREKETLERI WITH (NOLOCK)
    WHERE cha_kod = @CariKod
      AND cha_tip = 1 AND cha_iptal = 0 AND cha_meblag > 0
),
BorcCum AS (
    SELECT *, SUM(Tutar) OVER (ORDER BY SiraNo
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS CumTutar
    FROM Borclar
),
AlacakCum AS (
    SELECT *, SUM(Tutar) OVER (ORDER BY SiraNo
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS CumTutar
    FROM Alacaklar
)

SELECT
    b.SiraNo AS FaturaSiraNo, b.FaturaTarihi, b.VadeTarihi,
    a.OdemeTarihi,
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
    END AS KapananParca
INTO #Kesisim
FROM BorcCum b
INNER JOIN AlacakCum a
    ON a.CumTutar > b.CumTutar - b.Tutar
    AND a.CumTutar - a.Tutar < b.CumTutar;

-- SONUC 1: Genel ozet
SELECT
    @CariKod AS [Cari Kodu],
    CONVERT(decimal(18,0),
        SUM(CASE WHEN VadeTarihi IS NOT NULL THEN KapananParca ELSE 0 END))
        AS [Vadeli Kapanan Tutar],
    CONVERT(decimal(5,1),
        100.0 * SUM(CASE WHEN VadeTarihi IS NOT NULL AND OdemeTarihi <= VadeTarihi
                         THEN KapananParca ELSE 0 END)
              / NULLIF(SUM(CASE WHEN VadeTarihi IS NOT NULL
                                THEN KapananParca ELSE 0 END), 0))
        AS [Vadesinde Odeme %],
    CONVERT(decimal(10,1),
        SUM(CASE WHEN VadeTarihi IS NOT NULL AND OdemeTarihi > VadeTarihi
                 THEN KapananParca * DATEDIFF(DAY, VadeTarihi, OdemeTarihi) ELSE 0 END)
        / NULLIF(SUM(CASE WHEN VadeTarihi IS NOT NULL AND OdemeTarihi > VadeTarihi
                          THEN KapananParca ELSE 0 END), 0))
        AS [Ort Gecikme Gun]
FROM #Kesisim WHERE KapananParca > 0;

-- SONUC 2: Aylik trend
SELECT
    FORMAT(FaturaTarihi, 'yyyy-MM') AS [Ay],
    COUNT(DISTINCT FaturaSiraNo) AS [Fatura Sayisi],
    CONVERT(decimal(5,1),
        100.0 * SUM(CASE WHEN VadeTarihi IS NOT NULL AND OdemeTarihi <= VadeTarihi
                         THEN KapananParca ELSE 0 END)
              / NULLIF(SUM(CASE WHEN VadeTarihi IS NOT NULL
                                THEN KapananParca ELSE 0 END), 0))
        AS [Vadesinde %],
    CONVERT(decimal(10,1),
        SUM(CASE WHEN VadeTarihi IS NOT NULL AND OdemeTarihi > VadeTarihi
                 THEN KapananParca * DATEDIFF(DAY, VadeTarihi, OdemeTarihi) ELSE 0 END)
        / NULLIF(SUM(CASE WHEN VadeTarihi IS NOT NULL AND OdemeTarihi > VadeTarihi
                          THEN KapananParca ELSE 0 END), 0))
        AS [Ort Gecikme Gun]
FROM #Kesisim WHERE KapananParca > 0
GROUP BY FORMAT(FaturaTarihi, 'yyyy-MM')
ORDER BY [Ay];

DROP TABLE #Kesisim;
