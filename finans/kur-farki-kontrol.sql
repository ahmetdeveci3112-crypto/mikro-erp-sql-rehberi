-- ============================================
-- Mikro ERP: Doviz Kur Farki Kontrol
-- Kaynak: https://mikroerp.dev/blog/mikro-erp-kur-farki-kontrol-sql
-- Uyumluluk: Mikro V16, V17
-- Aciklama: Dovizli islemlerde islem kuru vs guncel kur arasindaki
--           farki hesaplar.
-- ============================================

SELECT 
    H.cha_kod                                    AS [Cari Kodu],
    C.cari_unvan1                                AS [Musteri],
    CONVERT(VARCHAR(10), H.cha_tarihi, 104)      AS [Tarih],
    H.cha_evrakno_seri + '-' + 
        CAST(H.cha_evrakno_sira AS VARCHAR)      AS [Evrak No],
    CASE H.cha_d_cins 
        WHEN 1 THEN 'USD' 
        WHEN 2 THEN 'EUR' 
        WHEN 3 THEN 'GBP' 
        ELSE CAST(H.cha_d_cins AS VARCHAR)
    END                                          AS [Doviz],
    H.cha_meblag                                 AS [Meblag (TL)],
    H.cha_d_kur                                  AS [Islem Kuru],
    -- Guncel kuru DOVIZ_KURLARI tablosundan almaniz gerekir
    -- Asagida ornek hesaplama:
    H.cha_meblag / NULLIF(H.cha_d_kur, 0)       AS [Doviz Tutari],
    CASE WHEN H.cha_tip = 0 THEN 'Borc' ELSE 'Alacak' END AS [Tip]
FROM CARI_HESAP_HAREKETLERI H WITH (NOLOCK)
LEFT JOIN CARI_HESAPLAR C WITH (NOLOCK) ON H.cha_kod = C.cari_kod
WHERE H.cha_iptal = 0
  AND H.cha_d_cins > 0           -- Sadece dovizli islemler
  AND H.cha_tpoz = 0             -- Acik hareketler
ORDER BY H.cha_d_cins, H.cha_kod;
