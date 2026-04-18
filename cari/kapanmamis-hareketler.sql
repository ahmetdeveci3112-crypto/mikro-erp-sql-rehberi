-- ============================================
-- Mikro ERP: Kapanmamis (Acik) Cari Hareketler
-- Kaynak: https://mikroerp.dev/blog/mikro-erp-kapanmamis-cari-hareket-sql
-- Uyumluluk: Mikro V16, V17
-- Aciklama: cha_tpoz = 0 (Acik) olan hareketleri listeler.
--           Yaslandirma ve tahsilat takibi icin temel sorgudur.
-- ============================================

SELECT 
    H.cha_kod                                    AS [Cari Kodu],
    C.cari_unvan1                                AS [Musteri Unvani],
    CONVERT(VARCHAR(10), H.cha_tarihi, 104)      AS [Hareket Tarihi],
    CASE H.cha_tip WHEN 0 THEN 'Borc' ELSE 'Alacak' END AS [Tip],
    CASE H.cha_cinsi
        WHEN 6  THEN 'Toptan Fatura'
        WHEN 7  THEN 'Perakende Fatura'
        WHEN 0  THEN 'Nakit'
        WHEN 1  THEN 'Musteri Ceki'
        WHEN 2  THEN 'Musteri Senedi'
        ELSE CAST(H.cha_cinsi AS VARCHAR)
    END                                          AS [Hareket Cinsi],
    H.cha_evrakno_seri + '-' + 
        CAST(H.cha_evrakno_sira AS VARCHAR)      AS [Evrak No],
    H.cha_belge_no                               AS [Belge No],
    H.cha_meblag                                 AS [Meblag],
    DATEDIFF(DAY, H.cha_tarihi, GETDATE())       AS [Gun Sayisi]
FROM CARI_HESAP_HAREKETLERI H WITH (NOLOCK)
INNER JOIN CARI_HESAPLAR C WITH (NOLOCK) ON H.cha_kod = C.cari_kod
WHERE H.cha_iptal = 0
  AND H.cha_tpoz = 0          -- Sadece ACIK hareketler
  AND H.cha_tip = 0           -- Sadece BORC hareketleri (bize borclu)
ORDER BY H.cha_kod, H.cha_tarihi;
