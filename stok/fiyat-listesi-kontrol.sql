-- ============================================
-- Mikro ERP: Fiyat Listesi Kontrol ve Karsilastirma
-- Kaynak: https://mikroerp.dev/blog/mikro-erp-fiyat-listesi-kontrol-sql
-- Uyumluluk: Mikro V16, V17
-- ============================================

SELECT 
    S.sto_kod                                    AS [Stok Kodu],
    S.sto_isim                                   AS [Stok Adi],
    S.sto_birim1_ad                              AS [Birim],
    FL.sfiyat_fiyati                             AS [Liste Fiyati],
    FL.sfiyat_listesirano                        AS [Liste No],
    FL.sfiyat_dovession                          AS [Doviz Cinsi],
    CONVERT(VARCHAR(10), FL.sfiyat_bastar, 104)  AS [Gecerlilik Baslangic],
    CONVERT(VARCHAR(10), FL.sfiyat_bittar, 104)  AS [Gecerlilik Bitis]
FROM STOK_FIYAT_LISTELERI FL WITH (NOLOCK)
INNER JOIN STOKLAR S WITH (NOLOCK) ON FL.sfiyat_stokkod = S.sto_kod
WHERE FL.sfiyat_iptal = 0
  AND (FL.sfiyat_bittar IS NULL OR FL.sfiyat_bittar >= GETDATE())
ORDER BY S.sto_kod, FL.sfiyat_listesirano;
