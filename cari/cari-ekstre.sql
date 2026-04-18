-- ============================================
-- Mikro ERP: Cari Hesap Ekstre Raporu
-- Kaynak: https://mikroerp.dev/blog/mikro-erp-cari-ekstre-raporu-sql
-- Uyumluluk: Mikro V16, V17
-- Aciklama: Running total (SUM OVER) ile cari hesap ekstre raporu.
--           Borc/alacak hareketlerini ve her satirda kumulatif
--           bakiyeyi hesaplar.
-- ============================================

-- Tek Cari Ekstre
SELECT 
    ROW_NUMBER() OVER (ORDER BY cha_tarihi, cha_evrakno_sira) AS [Sira],
    CONVERT(VARCHAR(10), cha_tarihi, 104)     AS [Tarih],
    CASE cha_evrak_tip
        WHEN 0  THEN 'Alis Faturasi'
        WHEN 63 THEN 'Satis Faturasi'
        WHEN 1  THEN 'Tahsilat'
        WHEN 64 THEN 'Tediye'
        WHEN 29 THEN 'Acilis Fisi'
        WHEN 31 THEN 'Borc Dekontu'
        WHEN 32 THEN 'Alacak Dekontu'
        ELSE 'Tip: ' + CAST(cha_evrak_tip AS VARCHAR)
    END                                        AS [Evrak Tipi],
    cha_evrakno_seri + '-' + 
        CAST(cha_evrakno_sira AS VARCHAR)       AS [Evrak No],
    cha_belge_no                                AS [Belge No],
    cha_aciklama                                AS [Aciklama],
    CASE WHEN cha_tip = 0 
         THEN cha_meblag ELSE 0 END            AS [Borc],
    CASE WHEN cha_tip = 1 
         THEN cha_meblag ELSE 0 END            AS [Alacak],
    SUM(CASE WHEN cha_tip = 0 THEN cha_meblag 
             ELSE -cha_meblag END) 
        OVER (ORDER BY cha_tarihi, cha_evrakno_sira 
              ROWS UNBOUNDED PRECEDING)         AS [Bakiye]
FROM CARI_HESAP_HAREKETLERI WITH (NOLOCK)
WHERE cha_kod = '120.001'                       -- Cari kodu (degistirin)
  AND cha_iptal = 0                             -- Iptal kayitlari haric
  AND cha_tarihi >= CONVERT(datetime, '20260101', 112)
  AND cha_tarihi <= CONVERT(datetime, '20261231', 112)
ORDER BY cha_tarihi, cha_evrakno_sira;

-- ============================================
-- Tum Carilerin Bakiye Ozet Listesi
-- ============================================
SELECT 
    C.cari_kod                                    AS [Cari Kodu],
    C.cari_unvan1                                 AS [Unvan],
    SUM(CASE WHEN H.cha_tip = 0 THEN H.cha_meblag ELSE 0 END) AS [Toplam Borc],
    SUM(CASE WHEN H.cha_tip = 1 THEN H.cha_meblag ELSE 0 END) AS [Toplam Alacak],
    SUM(CASE WHEN H.cha_tip = 0 THEN H.cha_meblag 
             ELSE -H.cha_meblag END)              AS [Bakiye]
FROM CARI_HESAPLAR C WITH (NOLOCK)
INNER JOIN CARI_HESAP_HAREKETLERI H WITH (NOLOCK) 
    ON C.cari_kod = H.cha_kod
WHERE H.cha_iptal = 0
  AND H.cha_tarihi <= GETDATE()
GROUP BY C.cari_kod, C.cari_unvan1
HAVING SUM(CASE WHEN H.cha_tip = 0 THEN H.cha_meblag ELSE -H.cha_meblag END) <> 0
ORDER BY [Bakiye] DESC;
