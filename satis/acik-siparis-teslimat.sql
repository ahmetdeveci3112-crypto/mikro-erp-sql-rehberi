-- ============================================
-- Mikro ERP: Acik Siparis ve Teslimat Takip
-- Kaynak: https://mikroerp.dev/blog/mikro-erp-acik-siparis-teslimat-raporu-sql
-- Uyumluluk: Mikro V16, V17
-- ============================================

SELECT 
    sip_musteri_kod                              AS [Musteri Kodu],
    C.cari_unvan1                                AS [Musteri],
    sip_stok_kod                                 AS [Stok Kodu],
    S.sto_isim                                   AS [Urun Adi],
    CONVERT(VARCHAR(10), sip_tarih, 104)         AS [Siparis Tarihi],
    CONVERT(VARCHAR(10), sip_teslim_tar, 104)    AS [Teslim Tarihi],
    sip_miktar                                   AS [Siparis Miktari],
    sip_teslim_miktar                            AS [Teslim Edilen],
    (sip_miktar - sip_teslim_miktar)             AS [Kalan Miktar],
    ROUND((sip_teslim_miktar / NULLIF(sip_miktar, 0)) * 100, 1) AS [Teslimat Orani %],
    sip_b_fiyat                                  AS [Birim Fiyat],
    (sip_miktar - sip_teslim_miktar) * sip_b_fiyat AS [Kalan Tutar]
FROM SIPARISLER WITH (NOLOCK)
LEFT JOIN CARI_HESAPLAR C WITH (NOLOCK) ON sip_musteri_kod = C.cari_kod
LEFT JOIN STOKLAR S WITH (NOLOCK) ON sip_stok_kod = S.sto_kod
WHERE sip_iptal = 0
  AND sip_kapat_fl = 0           -- Kapatilmamis
  AND sip_tip = 1                -- Satis siparisi
  AND (sip_miktar - sip_teslim_miktar) > 0   -- Henuz teslim edilmemis
ORDER BY sip_teslim_tar, sip_musteri_kod;
