-- ============================================
-- Mikro ERP: Cek/Senet Gercek Tahsilat Tarihi + Arac Dagilimi
-- Kaynak: https://mikroerp.dev/blog/mikro-erp-cek-senet-gercek-tahsilat-tarihi-sql
-- Uyumluluk: Mikro V16, V17 | SQL Server 2016+
-- Aciklama: Islem tarihi (cha_tarihi) ile gercek tahsilat tarihi
--           (cha_vade) ayrimi. cha_cinsi kodlariyla tahsilat araci
--           turu belirleme ve nakit/cek/senet/kredi karti dagilimi.
-- ============================================

DECLARE @CariKod VARCHAR(50) = '120.001'; -- << BURAYA KENDI CARI KODUNUZU YAZIN

-- BOLUM 1: Detay listesi
SELECT
    CAST(ch.cha_tarihi AS date) AS [Islem Tarihi],
    CASE ch.cha_cinsi
        WHEN 0 THEN 'Nakit/Havale'
        WHEN 1 THEN 'Musteri Ceki'
        WHEN 2 THEN 'Musteri Senedi'
        WHEN 3 THEN 'Firma Ceki'
        WHEN 5 THEN 'Dekont'
        WHEN 19 THEN 'Kredi Karti'
        ELSE 'Diger (' + CAST(ch.cha_cinsi AS VARCHAR) + ')'
    END AS [Tahsilat Turu],
    ch.cha_meblag AS [Tutar],
    ch.cha_evrakno_seri + '-' + CAST(ch.cha_evrakno_sira AS VARCHAR) AS [Evrak No],
    CASE
        WHEN ch.cha_cinsi IN (1, 2) AND ch.cha_vade BETWEEN 19000101 AND 20991231
        THEN TRY_CONVERT(date, CONVERT(char(8), ch.cha_vade), 112)
        WHEN ch.cha_cinsi IN (1, 2) AND ch.cha_vade BETWEEN -36500 AND -1
        THEN DATEADD(DAY, ABS(ch.cha_vade), CAST(ch.cha_tarihi AS date))
        ELSE CAST(ch.cha_tarihi AS date)
    END AS [Gercek Tahsilat Tarihi],
    CASE
        WHEN ch.cha_cinsi IN (1, 2) THEN
            DATEDIFF(DAY, ch.cha_tarihi,
                CASE
                    WHEN ch.cha_vade BETWEEN 19000101 AND 20991231
                    THEN TRY_CONVERT(date, CONVERT(char(8), ch.cha_vade), 112)
                    WHEN ch.cha_vade BETWEEN -36500 AND -1
                    THEN DATEADD(DAY, ABS(ch.cha_vade), CAST(ch.cha_tarihi AS date))
                    ELSE CAST(ch.cha_tarihi AS date)
                END)
        ELSE 0
    END AS [Vade Gun Sayisi]
FROM CARI_HESAP_HAREKETLERI ch WITH (NOLOCK)
WHERE ch.cha_kod = @CariKod
  AND ch.cha_tip = 1 AND ch.cha_iptal = 0 AND ch.cha_meblag > 0
ORDER BY ch.cha_tarihi ASC;

-- BOLUM 2: Ozet dagilim
SELECT
    @CariKod AS [Cari Kodu],
    SUM(CASE WHEN cha_cinsi NOT IN (1,2,19) THEN cha_meblag ELSE 0 END) AS [Nakit/Havale],
    SUM(CASE WHEN cha_cinsi = 1 THEN cha_meblag ELSE 0 END) AS [Cek],
    SUM(CASE WHEN cha_cinsi = 2 THEN cha_meblag ELSE 0 END) AS [Senet],
    SUM(CASE WHEN cha_cinsi = 19 THEN cha_meblag ELSE 0 END) AS [Kredi Karti],
    SUM(cha_meblag) AS [Toplam],
    CONVERT(decimal(5,1),
        100.0 * SUM(CASE WHEN cha_cinsi IN (1,2) THEN cha_meblag ELSE 0 END)
              / NULLIF(SUM(cha_meblag), 0)) AS [Cek+Senet %]
FROM CARI_HESAP_HAREKETLERI WITH (NOLOCK)
WHERE cha_kod = @CariKod
  AND cha_tip = 1 AND cha_iptal = 0 AND cha_meblag > 0;
