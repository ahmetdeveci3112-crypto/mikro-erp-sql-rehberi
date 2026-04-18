-- ============================================
-- Mikro ERP: Depo Bazli Stok Bakiye
-- Kaynak: https://mikroerp.dev/blog/mikro-erp-depo-bazli-stok-bakiye-sql
-- Uyumluluk: Mikro V16, V17
-- Aciklama: Her depo icin giris-cikis farkindan stok bakiye hesaplar.
-- ============================================

SELECT 
    S.sto_kod                                    AS [Stok Kodu],
    S.sto_isim                                   AS [Stok Adi],
    H.sth_giris_depo_no                          AS [Depo No],
    SUM(CASE 
        WHEN H.sth_tip = 0 THEN H.sth_miktar    -- Giris
        WHEN H.sth_tip = 1 THEN -H.sth_miktar   -- Cikis
        WHEN H.sth_tip = 2 AND H.sth_giris_depo_no = H.sth_giris_depo_no 
            THEN H.sth_miktar                    -- Transfer giris
        ELSE 0 
    END)                                         AS [Bakiye Miktar]
FROM STOK_HAREKETLERI H WITH (NOLOCK)
INNER JOIN STOKLAR S WITH (NOLOCK) ON H.sth_stok_kod = S.sto_kod
WHERE H.sth_iptal = 0
GROUP BY S.sto_kod, S.sto_isim, H.sth_giris_depo_no
HAVING SUM(CASE 
    WHEN H.sth_tip = 0 THEN H.sth_miktar 
    WHEN H.sth_tip = 1 THEN -H.sth_miktar 
    ELSE 0 END) <> 0
ORDER BY S.sto_kod, H.sth_giris_depo_no;
