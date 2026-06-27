-- ============================================
-- Mikro ERP: Ortalama Tahsilat Suresi (DSO) - Parca Agirlikli FIFO
-- Kaynak: https://mikroerp.dev/blog/mikro-erp-ortalama-tahsilat-suresi-dso-sql
-- Uyumluluk: Mikro V16, V17 | SQL Server 2016+
-- Aciklama: Basit ortalama yerine parca agirlikli FIFO yontemiyle
--           gercek ortalama tahsilat gunu hesaplar. Window Function
--           ile kumulatif toplam ve aralik kesisim algoritmasi kullanir.
-- ============================================

DECLARE @CariKod VARCHAR(50) = '120.001'; -- << BURAYA KENDI CARI KODUNUZU YAZIN

;WITH Borclar AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY cha_tarihi ASC, cha_create_date ASC) AS SiraNo,
        CAST(cha_tarihi AS date) AS FaturaTarihi,
        cha_meblag AS Tutar,
        cha_evrakno_seri + '-' + CAST(cha_evrakno_sira AS VARCHAR) AS EvrakNo
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
),
Kesisim AS (
    SELECT
        b.FaturaTarihi, b.EvrakNo,
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
        END AS KapananParca,
        DATEDIFF(DAY, b.FaturaTarihi, a.OdemeTarihi) AS GunFarki
    FROM BorcCum b
    INNER JOIN AlacakCum a
        ON a.CumTutar > b.CumTutar - b.Tutar
        AND a.CumTutar - a.Tutar < b.CumTutar
)

SELECT
    @CariKod AS [Cari Kodu],
    CONVERT(decimal(18,0), SUM(KapananParca)) AS [Toplam Kapanan Tutar],
    CONVERT(decimal(10,1),
        SUM(KapananParca * GunFarki)
        / NULLIF(SUM(KapananParca), 0)
    ) AS [Agirlikli Ort Tahsilat Gun (DSO)],
    COUNT(*) AS [Parca Sayisi],
    MIN(GunFarki) AS [Min Gun],
    MAX(GunFarki) AS [Max Gun]
FROM Kesisim
WHERE KapananParca > 0;
