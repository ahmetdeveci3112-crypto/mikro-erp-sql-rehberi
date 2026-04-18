-- ============================================
-- Mikro ERP: Fatura-Siparis Eslestirme
-- Kaynak: https://mikroerp.dev/blog/mikro-erp-fatura-siparis-eslestirme-sql
-- Uyumluluk: Mikro V16, V17
-- ============================================

SELECT 
    SH.sth_stok_kod                              AS [Stok Kodu],
    S.sto_isim                                   AS [Urun Adi],
    SH.sth_evrakno_seri + '-' + 
        CAST(SH.sth_evrakno_sira AS VARCHAR)     AS [Fatura No],
    SH.sth_belge_no                              AS [Irsaliye No],
    CONVERT(VARCHAR(10), SH.sth_tarih, 104)      AS [Fatura Tarihi],
    SH.sth_miktar                                AS [Fatura Miktari],
    SH.sth_tutar                                 AS [Fatura Tutari],
    SH.sth_cari_kodu                             AS [Musteri Kodu],
    C.cari_unvan1                                AS [Musteri]
FROM STOK_HAREKETLERI SH WITH (NOLOCK)
INNER JOIN STOKLAR S WITH (NOLOCK) ON SH.sth_stok_kod = S.sto_kod
LEFT JOIN CARI_HESAPLAR C WITH (NOLOCK) ON SH.sth_cari_kodu = C.cari_kod
WHERE SH.sth_iptal = 0
  AND SH.sth_evraktip IN (3, 4)  -- Giris/Cikis Faturasi
  AND SH.sth_tarih >= CONVERT(datetime, '20260101', 112)
ORDER BY SH.sth_tarih DESC, SH.sth_evrakno_sira;
