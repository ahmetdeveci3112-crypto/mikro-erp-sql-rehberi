-- ============================================
-- Mikro ERP: cha_vade - Vade Tarihi Hesaplama
-- Kaynak: https://mikroerp.dev/blog/mikro-erp-vade-hesaplama-cha-vade-sql
-- Uyumluluk: Mikro V16, V17
-- Aciklama: cha_vade integer alaninin gercek tarihe donusumu.
--           Mikro kendi fn_Aysm fonksiyonlarini kullanir ama
--           bu sorgu basit donusum saglar.
-- ============================================

-- Vade tarihli borc listesi
SELECT 
    H.cha_kod                                    AS [Cari Kodu],
    C.cari_unvan1                                AS [Musteri],
    CONVERT(VARCHAR(10), H.cha_tarihi, 104)      AS [Islem Tarihi],
    H.cha_meblag                                 AS [Meblag],
    H.cha_vade                                   AS [Vade (Integer)],
    -- fn_Aysm_v2_CariHarVade fonksiyonu ile vade tarihi hesaplanir
    -- Eger fonksiyon yoksa asagidaki yaklasik formul kullanilabilir:
    CASE 
        WHEN H.cha_vade > 0 
        THEN DATEADD(DAY, H.cha_vade, H.cha_tarihi)
        ELSE H.cha_tarihi 
    END                                          AS [Vade Tarihi (Yaklasik)],
    DATEDIFF(DAY, 
        CASE WHEN H.cha_vade > 0 
             THEN DATEADD(DAY, H.cha_vade, H.cha_tarihi) 
             ELSE H.cha_tarihi END, 
        GETDATE())                               AS [Gecen Gun]
FROM CARI_HESAP_HAREKETLERI H WITH (NOLOCK)
INNER JOIN CARI_HESAPLAR C WITH (NOLOCK) ON H.cha_kod = C.cari_kod
WHERE H.cha_iptal = 0
  AND H.cha_tpoz = 0           -- Sadece acik hareketler
  AND H.cha_tip = 0            -- Borc hareketleri
ORDER BY [Gecen Gun] DESC;
