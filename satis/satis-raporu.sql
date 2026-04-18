-- ============================================
-- Mikro ERP: Satis Raporu (Donemsel)
-- Kaynak: https://mikroerp.dev/blog/mikro-erp-satis-raporu-sql
-- Uyumluluk: Mikro V16, V17
-- Aciklama: Belirli donem icin urun, musteri ve temsilci bazli
--           satis raporu. Toptan + perakende faturaları.
-- ============================================

SELECT 
    H.sth_stok_kod                               AS [Stok Kodu],
    S.sto_isim                                   AS [Stok Adi],
    H.sth_cari_kodu                              AS [Musteri Kodu],
    C.cari_unvan1                                AS [Musteri],
    H.sth_plasiyer_kodu                          AS [Temsilci],
    SUM(H.sth_miktar)                            AS [Toplam Miktar],
    SUM(H.sth_tutar)                             AS [Toplam Tutar],
    COUNT(*)                                     AS [Islem Sayisi]
FROM STOK_HAREKETLERI H WITH (NOLOCK)
INNER JOIN STOKLAR S WITH (NOLOCK) ON H.sth_stok_kod = S.sto_kod
LEFT JOIN CARI_HESAPLAR C WITH (NOLOCK) ON H.sth_cari_kodu = C.cari_kod
WHERE H.sth_iptal = 0
  AND H.sth_tip = 1              -- Cikis (satis)
  AND H.sth_cins IN (0, 1)       -- Toptan veya Perakende
  AND H.sth_normal_iade = 0      -- Normal (iade degil)
  AND H.sth_tarih >= CONVERT(datetime, '20260101', 112)
  AND H.sth_tarih <= CONVERT(datetime, '20261231', 112)
GROUP BY H.sth_stok_kod, S.sto_isim, H.sth_cari_kodu, C.cari_unvan1, H.sth_plasiyer_kodu
ORDER BY [Toplam Tutar] DESC;
