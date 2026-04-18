SET NOCOUNT ON;

-- ═══════════════════════════════════════════
-- GÜVENLİK AYARLARI (Senkron Edilecek Mimari)
-- ═══════════════════════════════════════════
DECLARE @SourceDB NVARCHAR(128) = 'MikroDB_Merkez';  -- En doğru, güncel fonksiyonların olduğu amiral gemisi DB.

-- Hedef Şube Veritabanları (Dağıtım Yapılacak Noktalar)
DECLARE @Targets TABLE (DBName NVARCHAR(128));
INSERT INTO @Targets VALUES
    ('MikroDB_Adana'),
    ('MikroDB_Antalya'),
    ('MikroDB_Bursa'),
    ('MikroDB_Izmir');

-- Kopyalanacak Fonksiyon Ailesi (Pattern)
-- Mikro'nun Cari veya Stok fonksiyonları genellikle belirli bir pattern ile başlar.
DECLARE @Pattern NVARCHAR(50) = 'fn_Aysm_v2_%';

-- ═══════════════════════════════════════════
-- ADIM 1: Hafızaya (RAM) Kaynak Fonksiyonları Okuma
-- ═══════════════════════════════════════════
DECLARE @AllFunctions TABLE (FuncName NVARCHAR(256), FuncDef NVARCHAR(MAX));

-- Kaynak veritabanındaki sys.sql_modules'u sorgula ve Create scriptlerini (Definition) RAM'e al!
DECLARE @FindSQL NVARCHAR(MAX) = N'
SELECT o.name, m.definition
FROM [' + @SourceDB + N'].sys.objects o
INNER JOIN [' + @SourceDB + N'].sys.sql_modules m ON o.object_id = m.object_id
WHERE o.name LIKE ''' + @Pattern + '''
AND o.type IN (''FN'', ''IF'', ''TF'')';

INSERT INTO @AllFunctions EXEC sp_executesql @FindSQL;

PRINT '📦 Kaynak Çekildi: ' + @SourceDB + ' (Toplam ' + CAST((SELECT COUNT(*) FROM @AllFunctions) AS VARCHAR) + ' fonksiyon hazırlandı)';
PRINT '---------------------------------------------------';

-- ═══════════════════════════════════════════
-- ADIM 2: Hedef Veritabanlarına Dinamik Dağıtım (Deploy)
-- ═══════════════════════════════════════════
DECLARE @TargetDB NVARCHAR(128), @FuncName NVARCHAR(256), @FuncDef NVARCHAR(MAX);
DECLARE @DeploySQL NVARCHAR(MAX), @CheckSQL NVARCHAR(MAX);
DECLARE @Exists INT;

DECLARE target_cursor CURSOR FOR SELECT DBName FROM @Targets;
OPEN target_cursor;
FETCH NEXT FROM target_cursor INTO @TargetDB;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT '🚀 Deploying -> [' + @TargetDB + ']';
    
    DECLARE func_cursor CURSOR FOR SELECT FuncName, FuncDef FROM @AllFunctions;
    OPEN func_cursor;
    FETCH NEXT FROM func_cursor INTO @FuncName, @FuncDef;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- FONKSİYON hedefte zaten var mı?
        SET @CheckSQL = N'SELECT @Exists = COUNT(*) FROM [' + @TargetDB + N'].sys.objects 
                          WHERE name = ''' + @FuncName + N''' AND type IN (''FN'', ''IF'', ''TF'')';
        SET @Exists = 0;
        EXEC sp_executesql @CheckSQL, N'@Exists INT OUTPUT', @Exists OUTPUT;

        BEGIN TRY
            IF @Exists > 0
            BEGIN
                -- VARSA: DROP et ve yeniden CREATE et (ALTER yerine daha güvenli geçiş sağlar)
                SET @DeploySQL = N'USE [' + @TargetDB + N']; DROP FUNCTION IF EXISTS dbo.' + @FuncName;
                EXEC sp_executesql @DeploySQL;
                
                SET @DeploySQL = N'USE [' + @TargetDB + N']; EXEC sp_executesql @stmt';
                EXEC sp_executesql @DeploySQL, N'@stmt NVARCHAR(MAX)', @stmt = @FuncDef;
            END
            ELSE
            BEGIN
                -- YOKSA: Sıfırdan Yarat
                SET @DeploySQL = N'USE [' + @TargetDB + N']; EXEC sp_executesql @stmt';
                EXEC sp_executesql @DeploySQL, N'@stmt NVARCHAR(MAX)', @stmt = @FuncDef;
            END
            
        END TRY
        BEGIN CATCH
            PRINT '   ❌ CRASH [' + @FuncName + ']: ' + ERROR_MESSAGE();
        END CATCH

        FETCH NEXT FROM func_cursor INTO @FuncName, @FuncDef;
    END
    CLOSE func_cursor;
    DEALLOCATE func_cursor;
    
    PRINT '   ✅ Bağlantı güncellendi ve kapatıldı.';
    FETCH NEXT FROM target_cursor INTO @TargetDB;
END

CLOSE target_cursor;
DEALLOCATE target_cursor;
PRINT '---------------------------------------------------';
PRINT '🏁 BÜTÜN SUNUCU ROLLOUT İŞLEMİ TAMAMLANDI!';
