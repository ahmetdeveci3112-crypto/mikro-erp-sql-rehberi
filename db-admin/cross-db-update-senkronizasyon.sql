-- GÜVENLİ CROSS-DB SENKRONİZASYON STORED YORDAMI
SET NOCOUNT ON;

DECLARE @KaynakDB NVARCHAR(128) = 'MikroDB_Merkez';
DECLARE @HedefDB NVARCHAR(128) = 'MikroDB_Adana';

-- Hangi tablonun hangi sütunları denetlenecek?
-- (Örnekte Müşteri Sicil Kartları-CARI_HESAPLAR Master alınıyor)

DECLARE @SQL_SENKRON NVARCHAR(MAX) = N'
-- TRANSACT-SQL ERROR HANDLING AÇILIYOR
BEGIN TRY
    BEGIN TRANSACTION;
    
    -- ADIM 1: Sadece "Farklı" olan kayıtları hedefleyip performansı artırıyoruz
    -- Hedef tablodaki Ünvan veya VKN, Ana tablodaki ile aynı DEĞİLSE tetiklenir.
    UPDATE Hedef
    SET 
        Hedef.cari_unvan1 = Kaynak.cari_unvan1,
        Hedef.cari_vdaire_no = Kaynak.cari_vdaire_no
    FROM [' + @HedefDB + N'].dbo.CARI_HESAPLAR Hedef
    INNER JOIN [' + @KaynakDB + N'].dbo.CARI_HESAPLAR Kaynak 
        ON Hedef.cari_kod = Kaynak.cari_kod
    WHERE 
        ISNULL(Hedef.cari_unvan1, '''') <> ISNULL(Kaynak.cari_unvan1, '''')
        OR 
        ISNULL(Hedef.cari_vdaire_no, '''') <> ISNULL(Kaynak.cari_vdaire_no, '''');
        
    -- Eğer etkilenen satır yoksa işlem şeffafça devam eder.
    DECLARE @RowAffected INT = @@ROWCOUNT;

    COMMIT TRANSACTION;
    PRINT ''✅ Senkronizasyon BAŞARILI. Güncellenen Kayıt: '' + CAST(@RowAffected AS NVARCHAR);
    
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
        
    -- Hatayı Log tablonuza yazın veya SysAdmin''e alert çıkartın
    PRINT ''❌ KRİTİK SYNC HATASI'';
    PRINT ''Error Message: '' + ERROR_MESSAGE();
END CATCH
';

EXEC sp_executesql @SQL_SENKRON;
