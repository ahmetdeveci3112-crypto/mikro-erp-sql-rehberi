-- ============================================
-- Mikro ERP: Banka Hesap Bakiye Raporu
-- Kaynak: https://mikroerp.dev/blog/mikro-erp-banka-hesap-bakiye-sql
-- Uyumluluk: Mikro V16, V17
-- ============================================

SELECT 
    B.cha_kod                                    AS [Banka Kodu],
    C.cari_unvan1                                AS [Banka Adi],
    SUM(CASE WHEN B.cha_tip = 0 THEN B.cha_meblag ELSE 0 END) AS [Toplam Giris],
    SUM(CASE WHEN B.cha_tip = 1 THEN B.cha_meblag ELSE 0 END) AS [Toplam Cikis],
    SUM(CASE WHEN B.cha_tip = 0 THEN B.cha_meblag 
             ELSE -B.cha_meblag END)             AS [Bakiye],
    B.cha_d_cins                                 AS [Doviz Cinsi]
FROM CARI_HESAP_HAREKETLERI B WITH (NOLOCK)
INNER JOIN CARI_HESAPLAR C WITH (NOLOCK) ON B.cha_kod = C.cari_kod
WHERE B.cha_iptal = 0
  AND B.cha_cari_cins = 2        -- Bankamiz
GROUP BY B.cha_kod, C.cari_unvan1, B.cha_d_cins
ORDER BY [Bakiye] DESC;
