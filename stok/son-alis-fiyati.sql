-- ============================================
-- Mikro ERP: Son Alis Fiyati Raporu
-- Kaynak: https://mikroerp.dev/blog/mikro-erp-son-alis-fiyati-sql
-- Uyumluluk: Mikro V16, V17
-- Aciklama: Her urunun en son alis fiyatini ve tarihini getirir.
-- ============================================

SELECT 
    H.sth_stok_kod                               AS [Stok Kodu],
    S.sto_isim                                   AS [Stok Adi],
    H.sth_birimfiyat                             AS [Son Alis Fiyati],
    H.sth_miktar                                 AS [Son Alis Miktari],
    CONVERT(VARCHAR(10), H.sth_tarih, 104)       AS [Son Alis Tarihi],
    H.sth_belge_no                               AS [Belge No],
    H.sth_cari_kodu                              AS [Tedarikci Kodu]
FROM STOK_HAREKETLERI H WITH (NOLOCK)
INNER JOIN STOKLAR S WITH (NOLOCK) ON H.sth_stok_kod = S.sto_kod
WHERE H.sth_iptal = 0
  AND H.sth_tip = 0              -- Giris (alis)
  AND H.sth_cins IN (0, 2)       -- Toptan veya Dis Ticaret
  AND H.sth_normal_iade = 0      -- Normal (iade degil)
  AND H.sth_tarih = (
      SELECT MAX(H2.sth_tarih)
      FROM STOK_HAREKETLERI H2 WITH (NOLOCK)
      WHERE H2.sth_stok_kod = H.sth_stok_kod
        AND H2.sth_iptal = 0
        AND H2.sth_tip = 0
        AND H2.sth_cins IN (0, 2)
        AND H2.sth_normal_iade = 0
  )
ORDER BY S.sto_isim;
