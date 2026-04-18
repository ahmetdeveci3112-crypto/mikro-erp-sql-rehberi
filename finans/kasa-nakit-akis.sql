-- ============================================
-- Mikro ERP: Kasa Nakit Akis Raporu
-- Kaynak: https://mikroerp.dev/blog/mikro-erp-kasa-nakit-akis-raporu-sql
-- Uyumluluk: Mikro V16, V17
-- ============================================

SELECT 
    H.cha_kod                                    AS [Kasa Kodu],
    C.cari_unvan1                                AS [Kasa Adi],
    CONVERT(VARCHAR(10), H.cha_tarihi, 104)      AS [Tarih],
    CASE H.cha_tip WHEN 0 THEN 'Giris' ELSE 'Cikis' END AS [Hareket],
    H.cha_evrakno_seri + '-' + 
        CAST(H.cha_evrakno_sira AS VARCHAR)      AS [Evrak No],
    H.cha_aciklama                               AS [Aciklama],
    CASE WHEN H.cha_tip = 0 THEN H.cha_meblag ELSE 0 END AS [Giris Tutar],
    CASE WHEN H.cha_tip = 1 THEN H.cha_meblag ELSE 0 END AS [Cikis Tutar],
    SUM(CASE WHEN H.cha_tip = 0 THEN H.cha_meblag 
             ELSE -H.cha_meblag END) 
        OVER (PARTITION BY H.cha_kod 
              ORDER BY H.cha_tarihi, H.cha_evrakno_sira 
              ROWS UNBOUNDED PRECEDING)          AS [Kasa Bakiye]
FROM CARI_HESAP_HAREKETLERI H WITH (NOLOCK)
INNER JOIN CARI_HESAPLAR C WITH (NOLOCK) ON H.cha_kod = C.cari_kod
WHERE H.cha_iptal = 0
  AND H.cha_cari_cins = 4        -- Kasamiz
  AND H.cha_tarihi >= CONVERT(datetime, '20260101', 112)
ORDER BY H.cha_kod, H.cha_tarihi, H.cha_evrakno_sira;
