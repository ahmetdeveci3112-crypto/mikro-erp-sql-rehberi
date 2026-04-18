-- ============================================
-- Mikro ERP: Belge Numarasiyla Cari Hareket Bulma
-- Kaynak: https://mikroerp.dev/blog/mikro-erp-belge-no-cari-hareket-bulma-sql
-- Uyumluluk: Mikro V16, V17
-- Aciklama: Fatura/irsaliye belge numarasiyla ilgili cari
--           hareketleri ve stok hareketlerini bulur.
-- ============================================

-- Cari hareketlerde belge no arama
SELECT 
    cha_kod                                     AS [Cari Kodu],
    CONVERT(VARCHAR(10), cha_tarihi, 104)       AS [Tarih],
    CASE cha_tip WHEN 0 THEN 'Borc' ELSE 'Alacak' END AS [Tip],
    cha_evrakno_seri + '-' + 
        CAST(cha_evrakno_sira AS VARCHAR)       AS [Evrak No],
    cha_belge_no                                AS [Belge No],
    cha_meblag                                  AS [Tutar],
    cha_aciklama                                AS [Aciklama]
FROM CARI_HESAP_HAREKETLERI WITH (NOLOCK)
WHERE cha_iptal = 0
  AND cha_belge_no LIKE '%ARANAN_BELGE_NO%'     -- Belge numarasini girin
ORDER BY cha_tarihi DESC;

-- ============================================
-- Stok hareketlerinde belge no arama
-- ============================================
SELECT 
    sth_stok_kod                                AS [Stok Kodu],
    S.sto_isim                                  AS [Stok Adi],
    CONVERT(VARCHAR(10), sth_tarih, 104)        AS [Tarih],
    CASE sth_tip WHEN 0 THEN 'Giris' WHEN 1 THEN 'Cikis' ELSE 'Transfer' END AS [Tip],
    sth_belge_no                                AS [Belge No],
    sth_miktar                                  AS [Miktar],
    sth_tutar                                   AS [Tutar]
FROM STOK_HAREKETLERI H WITH (NOLOCK)
INNER JOIN STOKLAR S WITH (NOLOCK) ON H.sth_stok_kod = S.sto_kod
WHERE sth_iptal = 0
  AND sth_belge_no LIKE '%ARANAN_BELGE_NO%'     -- Belge numarasini girin
ORDER BY sth_tarih DESC;
