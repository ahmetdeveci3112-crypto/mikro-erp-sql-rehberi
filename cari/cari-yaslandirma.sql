-- ============================================
-- Mikro ERP: Cari Yaslandirma (FIFO Aging)
-- Kaynak: https://mikroerp.dev/blog/mikro-erp-cari-yaslandirma-sql-sorgusu
-- Uyumluluk: Mikro V16, V17
-- NOT: Bu sorgu fn_Aysm fonksiyonlarini kullanir.
--      Fonksiyonlar sisteminizde yuklu olmalidir.
-- ============================================

-- Basit Yaslandirma (fn_ fonksiyonlari olmadan)
SELECT 
    H.cha_kod                                    AS [Cari Kodu],
    C.cari_unvan1                                AS [Musteri Unvani],
    SUM(CASE WHEN DATEDIFF(DAY, H.cha_tarihi, GETDATE()) BETWEEN 0 AND 30
             THEN CASE WHEN H.cha_tip = 0 THEN H.cha_meblag ELSE -H.cha_meblag END 
             ELSE 0 END)                         AS [0-30 Gun],
    SUM(CASE WHEN DATEDIFF(DAY, H.cha_tarihi, GETDATE()) BETWEEN 31 AND 60
             THEN CASE WHEN H.cha_tip = 0 THEN H.cha_meblag ELSE -H.cha_meblag END 
             ELSE 0 END)                         AS [31-60 Gun],
    SUM(CASE WHEN DATEDIFF(DAY, H.cha_tarihi, GETDATE()) BETWEEN 61 AND 90
             THEN CASE WHEN H.cha_tip = 0 THEN H.cha_meblag ELSE -H.cha_meblag END 
             ELSE 0 END)                         AS [61-90 Gun],
    SUM(CASE WHEN DATEDIFF(DAY, H.cha_tarihi, GETDATE()) > 90
             THEN CASE WHEN H.cha_tip = 0 THEN H.cha_meblag ELSE -H.cha_meblag END 
             ELSE 0 END)                         AS [90+ Gun],
    SUM(CASE WHEN H.cha_tip = 0 THEN H.cha_meblag ELSE -H.cha_meblag END) AS [Toplam Bakiye]
FROM CARI_HESAP_HAREKETLERI H WITH (NOLOCK)
INNER JOIN CARI_HESAPLAR C WITH (NOLOCK) ON H.cha_kod = C.cari_kod
WHERE H.cha_iptal = 0
  AND H.cha_tpoz = 0            -- Sadece acik hareketler
GROUP BY H.cha_kod, C.cari_unvan1
HAVING SUM(CASE WHEN H.cha_tip = 0 THEN H.cha_meblag ELSE -H.cha_meblag END) > 0
ORDER BY [Toplam Bakiye] DESC;

-- ============================================
-- NOT: Profesyonel FIFO aging icin fn_Aysm_v2_CariharBorcAlacak,
-- fn_Aysm_v2_CariHarTarih ve fn_Aysm_v2_CariHarVade fonksiyonlari
-- kullanilmalidir. Detay icin blog yazisina bakiniz.
-- ============================================
