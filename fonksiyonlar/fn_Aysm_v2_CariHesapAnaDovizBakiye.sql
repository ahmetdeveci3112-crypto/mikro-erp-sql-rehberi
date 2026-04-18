-- ============================================
-- Mikro ERP: fn_Aysm_v2_CariHesapAnaDovizBakiye
-- Kaynak: https://mikroerp.dev/blog/mikro-erp-cari-yaslandirma-sql-sorgusu
-- Aciklama: Carinin toplam bakiyesini ana doviz cinsinden hesaplar.
-- BAGIMLILIKLARI: fn_CariTutarlar, fn_Aysm_v2_CariHesapBakiye
-- ============================================

CREATE FUNCTION [dbo].[fn_Aysm_v2_CariHesapAnaDovizBakiye] (
    @FIRMALAR AS nvarchar(MAX),
    @CARICINSI AS tinyint,
    @CARIKODU AS nvarchar(25),
    @SORMERKKODU AS nvarchar(25),
    @PROJEKODU AS nvarchar(25),
    @GRUPNO AS tinyint,
    @ILKTARIH AS datetime,
    @SONTARIH AS datetime,
    @ODEMEEMRIDEGERLEMEDOK AS tinyint,
    @MusteriTeminatMektubu_Bakiyeyi_Etkilemesin_fl AS tinyint,
    @FirmaTeminatMektubu_Bakiyeyi_Etkilemesin_fl AS tinyint,
    @DepozitoCeki_Bakiyeyi_Etkilemesin_fl AS tinyint,
    @DepozitoSenedi_Bakiyeyi_Etkilemesin_fl AS tinyint
)
RETURNS float
AS
BEGIN
    DECLARE @Borc AS float
    DECLARE @Alacak AS float

    IF (@ODEMEEMRIDEGERLEMEDOK > 0) OR (@CARICINSI IN (5,9))
       OR (NOT(@ILKTARIH IS NULL)) OR (NOT(@SONTARIH IS NULL))
    BEGIN
        SELECT
            @Borc   = SUM([msg_S_0101\T]),  -- ANA DOVIZ BORC
            @Alacak = SUM([msg_S_0102\T])   -- ANA DOVIZ ALACAK
        FROM dbo.fn_CariTutarlar(
            @FIRMALAR, @CARICINSI, @CARIKODU, @GRUPNO,
            @ILKTARIH, @SONTARIH, @ODEMEEMRIDEGERLEMEDOK,
            @SORMERKKODU, @PROJEKODU
        )
    END
    ELSE
        SET @Borc = dbo.fn_Aysm_v2_CariHesapBakiye(
            @FIRMALAR, @CARICINSI, @CARIKODU,
            @SORMERKKODU, @PROJEKODU, @GRUPNO, 0,
            @MusteriTeminatMektubu_Bakiyeyi_Etkilemesin_fl,
            @FirmaTeminatMektubu_Bakiyeyi_Etkilemesin_fl,
            @DepozitoCeki_Bakiyeyi_Etkilemesin_fl,
            @DepozitoSenedi_Bakiyeyi_Etkilemesin_fl
        )

    RETURN ISNULL(@Borc, 0) - ISNULL(@Alacak, 0)
END
GO
