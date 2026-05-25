-- ============================================
-- Mikro ERP: Cari Bazli Gunluk Tahsilat Detay Raporu
-- Mikro 046110 Tahsilat Ozet Raporu SQL Alternatifi
-- Kaynak: https://mikroerp.dev/blog/mikro-erp-cari-tahsilat-detay-raporu-sql
-- Uyumluluk: Mikro V16, V17
-- Son Guncelleme: 2026-05-25
-- ============================================
-- 
-- Bu sorgu Mikro 046110 raporunun SQL alternatifidir.
-- Farklar:
--   - Gun gun, cari bazinda, temsilci bazinda detay
--   - Nakit, kredi karti, havale, cek, senet ayri sutunlarda
--   - Cek/senet iadeleri negatif tutar olarak dahil
--   - SSMS ve Mikro Menu Sorgu Yonetimi uyumlu
-- 
-- Mikro Menu Sorgu Yonetimi'nde kullanirken:
--   DECLARE satirlarini kaldirin, @P1/@P2 otomatik gelir.
-- ============================================

-- ⚙️ SSMS Test: Tarihleri kendi araliginiza gore degistirin
-- Mikro Menu Sorgu Yonetimi'ne alirken DECLARE satirlarini kaldirin
DECLARE @P1 DATE = '2026-04-01';
DECLARE @P2 DATE = '2026-04-30';

SELECT
    X.[Tarih],
    X.[Temsilci Kodu],
    X.[Cari Kodu],
    X.[Cari Unvan],

    ROUND(SUM(X.[Nakit]), 2) AS [Nakit],
    ROUND(SUM(X.[Kredi Karti]), 2) AS [Kredi Karti],
    ROUND(SUM(X.[Gelen Havale]), 2) AS [Gelen Havale],
    ROUND(SUM(X.[Cek]), 2) AS [Cek],
    ROUND(SUM(X.[Senet]), 2) AS [Senet],

    ROUND(
        SUM(X.[Nakit])
        + SUM(X.[Kredi Karti])
        + SUM(X.[Gelen Havale])
        + SUM(X.[Cek])
        + SUM(X.[Senet])
    , 2) AS [Toplam]

FROM
(
    SELECT
        CHA.cha_tarihi AS [Tarih],
        CHA.cha_satici_kodu AS [Temsilci Kodu],
        CHA.cha_kod AS [Cari Kodu],
        LTRIM(RTRIM(
            ISNULL(CH.cari_unvan1, '') + ' ' + ISNULL(CH.cari_unvan2, '')
        )) AS [Cari Unvan],

        -- Nakit tahsilat
        CASE
            WHEN CHA.cha_evrak_tip = 1
                 AND CHA.cha_tip = 1
                 AND CHA.cha_cinsi = 0
                 AND ISNULL(CHA.cha_normal_Iade, 0) = 0
            THEN CHA.cha_meblag
            ELSE 0
        END AS [Nakit],

        -- Kredi karti tahsilati
        CASE
            WHEN CHA.cha_evrak_tip = 1
                 AND CHA.cha_tip = 1
                 AND CHA.cha_cinsi = 19
                 AND ISNULL(CHA.cha_normal_Iade, 0) = 0
            THEN CHA.cha_meblag
            ELSE 0
        END AS [Kredi Karti],

        -- Gelen havale
        CASE
            WHEN CHA.cha_evrak_tip = 34
                 AND CHA.cha_tip = 1
                 AND CHA.cha_cinsi = 0
                 AND ISNULL(CHA.cha_normal_Iade, 0) = 0
            THEN CHA.cha_meblag
            ELSE 0
        END AS [Gelen Havale],

        -- Cek: Normal tahsilat + iade
        CASE
            WHEN CHA.cha_cinsi = 1
                 AND CHA.cha_tip = 1
                 AND CHA.cha_evrak_tip IN (1, 4)
                 AND ISNULL(CHA.cha_normal_Iade, 0) = 0
            THEN CHA.cha_meblag

            WHEN CHA.cha_cinsi = 1
                 AND (
                       ISNULL(CHA.cha_normal_Iade, 0) = 1
                       OR CHA.cha_tip = 0
                       OR CHA.cha_evrak_tip IN (
                           12, 13, 20, 21, 40, 41, 43,
                           46, 47, 74, 80, 81, 86, 87
                       )
                 )
            THEN CHA.cha_meblag * -1

            ELSE 0
        END AS [Cek],

        -- Senet: Normal tahsilat + iade
        CASE
            WHEN CHA.cha_cinsi = 2
                 AND CHA.cha_tip = 1
                 AND CHA.cha_evrak_tip IN (1, 3)
                 AND ISNULL(CHA.cha_normal_Iade, 0) = 0
            THEN CHA.cha_meblag

            WHEN CHA.cha_cinsi = 2
                 AND (
                       ISNULL(CHA.cha_normal_Iade, 0) = 1
                       OR CHA.cha_tip = 0
                       OR CHA.cha_evrak_tip IN (
                           16, 17, 24, 25, 39, 42, 44,
                           45, 48, 75, 78, 79, 84, 85
                       )
                 )
            THEN CHA.cha_meblag * -1

            ELSE 0
        END AS [Senet]

    FROM dbo.CARI_HESAP_HAREKETLERI CHA WITH (NOLOCK)

    LEFT JOIN dbo.CARI_HESAPLAR CH WITH (NOLOCK)
        ON CH.cari_kod = CHA.cha_kod

    WHERE
        CHA.cha_tarihi >= @P1
        AND CHA.cha_tarihi <= @P2
        AND CHA.cha_kod LIKE 'M.%'          -- ⚙️ Musteri carileri
        AND CHA.cha_cinsi IN (0, 1, 2, 19)
        AND (
                -- Nakit
                (
                    CHA.cha_evrak_tip = 1
                    AND CHA.cha_cinsi = 0
                    AND CHA.cha_tip = 1
                    AND ISNULL(CHA.cha_normal_Iade, 0) = 0
                )
                OR
                -- Kredi karti
                (
                    CHA.cha_evrak_tip = 1
                    AND CHA.cha_cinsi = 19
                    AND CHA.cha_tip = 1
                    AND ISNULL(CHA.cha_normal_Iade, 0) = 0
                )
                OR
                -- Gelen havale
                (
                    CHA.cha_evrak_tip = 34
                    AND CHA.cha_cinsi = 0
                    AND CHA.cha_tip = 1
                    AND ISNULL(CHA.cha_normal_Iade, 0) = 0
                )
                OR
                -- Cek: Normal + iade
                (
                    CHA.cha_cinsi = 1
                    AND (
                            (
                                CHA.cha_tip = 1
                                AND CHA.cha_evrak_tip IN (1, 4)
                                AND ISNULL(CHA.cha_normal_Iade, 0) = 0
                            )
                            OR
                            (
                                ISNULL(CHA.cha_normal_Iade, 0) = 1
                                OR CHA.cha_tip = 0
                                OR CHA.cha_evrak_tip IN (
                                    12, 13, 20, 21, 40, 41, 43,
                                    46, 47, 74, 80, 81, 86, 87
                                )
                            )
                    )
                )
                OR
                -- Senet: Normal + iade
                (
                    CHA.cha_cinsi = 2
                    AND (
                            (
                                CHA.cha_tip = 1
                                AND CHA.cha_evrak_tip IN (1, 3)
                                AND ISNULL(CHA.cha_normal_Iade, 0) = 0
                            )
                            OR
                            (
                                ISNULL(CHA.cha_normal_Iade, 0) = 1
                                OR CHA.cha_tip = 0
                                OR CHA.cha_evrak_tip IN (
                                    16, 17, 24, 25, 39, 42, 44,
                                    45, 48, 75, 78, 79, 84, 85
                                )
                            )
                    )
                )
        )

) X

GROUP BY
    X.[Tarih],
    X.[Temsilci Kodu],
    X.[Cari Kodu],
    X.[Cari Unvan]

HAVING
    ROUND(
        SUM(X.[Nakit])
        + SUM(X.[Kredi Karti])
        + SUM(X.[Gelen Havale])
        + SUM(X.[Cek])
        + SUM(X.[Senet])
    , 2) <> 0

ORDER BY
    X.[Tarih],
    X.[Temsilci Kodu],
    X.[Cari Kodu];
