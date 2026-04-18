-- ============================================
-- Mikro ERP: fn_Aysm_v2_CariharBorcAlacak
-- Kaynak: https://mikroerp.dev/blog/mikro-erp-cari-yaslandirma-sql-sorgusu
-- Aciklama: Hareketin borc mu alacak mi oldugunu belirler.
--           Teminat mektubu, depozito ceki/senedi gibi ozel
--           durumlari yonetir.
-- ============================================

CREATE FUNCTION [dbo].[fn_Aysm_v2_CariharBorcAlacak] (
    @NormalKarsi AS tinyint,    -- 0:Normal 1:Karsi
    @Tip AS tinyint,            -- 0:Borc 1:Alacak
    @Poz AS tinyint,            -- 0:Acik 1:Kapali
    @Caricins AS tinyint,
    @Cinsi AS tinyint,
    @MusteriTeminatMektubu_Bakiyeyi_Etkilemesin_fl tinyint,
    @FirmaTeminatMektubu_Bakiyeyi_Etkilemesin_fl tinyint,
    @DepozitoCeki_Bakiyeyi_Etkilemesin_fl tinyint,
    @DepozitoSenedi_Bakiyeyi_Etkilemesin_fl tinyint
)
RETURNS tinyint
AS
BEGIN
    DECLARE @out AS tinyint

    IF (@NormalKarsi = 0)
    BEGIN
        IF @Caricins = 0
        BEGIN
            IF (@Cinsi = 37 AND @MusteriTeminatMektubu_Bakiyeyi_Etkilemesin_fl = 1)
            OR (@Cinsi = 38 AND @FirmaTeminatMektubu_Bakiyeyi_Etkilemesin_fl = 1)
            OR (@Cinsi = 39 AND @DepozitoCeki_Bakiyeyi_Etkilemesin_fl = 1)
            OR (@Cinsi = 40 AND @DepozitoSenedi_Bakiyeyi_Etkilemesin_fl = 1)
                SET @out = 2
            ELSE
                SET @out = @Tip
        END
        ELSE
            SET @out = @Tip
    END
    ELSE
        IF @Tip = 0 SET @out = 1
        ELSE SET @out = 0

    RETURN @out
END
GO
