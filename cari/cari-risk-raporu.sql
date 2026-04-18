-- ============================================
-- Mikro ERP: Cari Risk Raporu
-- Kaynak: https://mikroerp.dev/blog/mikro-erp-cari-risk-raporu-sql
-- Uyumluluk: Mikro V16, V17
-- Aciklama: CTE mimarisiyle cari bakiye + teminat + acik siparis
--           birlesimi. Net risk formulü: Bakiye + Siparis - Teminat
-- ============================================

WITH CariBakiye AS (
    SELECT 
        cha_kod,
        SUM(CASE WHEN cha_tip = 0 THEN cha_meblag ELSE -cha_meblag END) AS ToplamBakiye
    FROM CARI_HESAP_HAREKETLERI WITH (NOLOCK)
    WHERE cha_iptal = 0
    GROUP BY cha_kod
    HAVING SUM(CASE WHEN cha_tip = 0 THEN cha_meblag ELSE -cha_meblag END) > 0
),

Teminat AS (
    SELECT 
        ct_carikodu,
        SUM(ct_tutari) AS GecerliTeminat
    FROM CARI_HESAP_TEMINATLARI WITH (NOLOCK)
    WHERE ct_iptal = 0
      AND (ct_vade IS NULL OR ct_vade >= GETDATE())
    GROUP BY ct_carikodu
),

AcikSiparis AS (
    SELECT
        sip_musteri_kod,
        SUM((sip_miktar - sip_teslim_miktar) * sip_b_fiyat) AS OnayliSiparisTutari
    FROM SIPARISLER WITH (NOLOCK)
    WHERE sip_iptal = 0 
      AND sip_kapat_fl = 0
      AND sip_tip = 1 -- Satis siparisi
    GROUP BY sip_musteri_kod
)

SELECT 
    CB.cha_kod                                     AS [Cari Kodu],
    C.cari_unvan1                                  AS [Musteri Unvani],
    CB.ToplamBakiye                                AS [Acik Fatura Bakiyesi],
    ISNULL(S.OnayliSiparisTutari, 0)               AS [Bekleyen Siparis Riski],
    ISNULL(T.GecerliTeminat, 0)                    AS [Gecerli Teminat],
    (CB.ToplamBakiye + ISNULL(S.OnayliSiparisTutari, 0) - ISNULL(T.GecerliTeminat, 0)) 
                                                   AS [NET GERCEK RISK]
FROM CariBakiye CB
INNER JOIN CARI_HESAPLAR C WITH (NOLOCK) ON CB.cha_kod = C.cari_kod
LEFT JOIN Teminat T ON CB.cha_kod = T.ct_carikodu
LEFT JOIN AcikSiparis S ON CB.cha_kod = S.sip_musteri_kod
ORDER BY [NET GERCEK RISK] DESC;
