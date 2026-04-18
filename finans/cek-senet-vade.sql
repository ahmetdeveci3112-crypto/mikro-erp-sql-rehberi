-- ============================================
-- Mikro ERP: Cek/Senet Vade Takip Raporu
-- Kaynak: https://mikroerp.dev/blog/mikro-erp-cek-senet-vade-takip-sql
-- Uyumluluk: Mikro V16, V17
-- Aciklama: Portfoydeki cek ve senetlerin vade tarihlerine gore
--           takibi. Bugun, bu hafta, bu ay vadesi dolan kagitlar.
-- ============================================

SELECT 
    H.cha_kod                                    AS [Cari Kodu],
    C.cari_unvan1                                AS [Musteri],
    CASE H.cha_cinsi 
        WHEN 1 THEN 'Musteri Ceki'
        WHEN 2 THEN 'Musteri Senedi'
        WHEN 3 THEN 'Firma Ceki'
        WHEN 4 THEN 'Firma Senedi'
    END                                          AS [Kagit Tipi],
    CASE H.cha_sntck_poz
        WHEN 0 THEN 'Portfolyde'
        WHEN 1 THEN 'Ciro'
        WHEN 2 THEN 'Tahsilde'
        WHEN 3 THEN 'Teminatta'
        WHEN 10 THEN 'Odendi'
        ELSE CAST(H.cha_sntck_poz AS VARCHAR)
    END                                          AS [Pozisyon],
    H.cha_evrakno_seri + '-' + 
        CAST(H.cha_evrakno_sira AS VARCHAR)      AS [Evrak No],
    H.cha_belge_no                               AS [Belge No],
    H.cha_meblag                                 AS [Tutar],
    CONVERT(VARCHAR(10), H.cha_tarihi, 104)      AS [Islem Tarihi],
    -- Vade hesabi
    CASE WHEN H.cha_vade > 0 
         THEN CONVERT(VARCHAR(10), DATEADD(DAY, H.cha_vade, H.cha_tarihi), 104)
         ELSE '' END                             AS [Vade Tarihi],
    CASE 
        WHEN H.cha_vade > 0 AND DATEADD(DAY, H.cha_vade, H.cha_tarihi) < GETDATE() 
            THEN 'GECMIS'
        WHEN H.cha_vade > 0 AND DATEADD(DAY, H.cha_vade, H.cha_tarihi) <= DATEADD(DAY, 7, GETDATE()) 
            THEN 'BU HAFTA'
        WHEN H.cha_vade > 0 AND DATEADD(DAY, H.cha_vade, H.cha_tarihi) <= DATEADD(MONTH, 1, GETDATE()) 
            THEN 'BU AY'
        ELSE 'ILERI TARIH'
    END                                          AS [Vade Durumu]
FROM CARI_HESAP_HAREKETLERI H WITH (NOLOCK)
LEFT JOIN CARI_HESAPLAR C WITH (NOLOCK) ON H.cha_kod = C.cari_kod
WHERE H.cha_iptal = 0
  AND H.cha_cinsi IN (1, 2, 3, 4)   -- Cek ve Senetler
  AND H.cha_sntck_poz IN (0, 2, 3)  -- Portfolyde, Tahsilde veya Teminatta
ORDER BY [Vade Tarihi];
