-- ============================================
-- Mikro ERP: fn_Aysm_v2_CariHesapMeblag
-- Kaynak: https://mikroerp.dev/blog/mikro-erp-cari-yaslandirma-sql-sorgusu
-- Aciklama: Tek bir hareketin net tutarini hesaplar. KDV, masraf,
--           tevkifat, stopaj, OTV, OIV ve doviz kuru gibi tum
--           kalemleri hesaba katar.
-- BAGIMLILIKLARI: fn_Atik_OTV_Maliyete_eklensin
-- ============================================

CREATE FUNCTION [dbo].[fn_Aysm_v2_CariHesapMeblag] (
    @CariMeblag AS float,
    @AraToplam AS float,
    @Vergitop AS float,
    @HDkur AS float,
    @AltDKur AS float,
    @KarsiDKur AS float,
    @HarCinsi AS tinyint,
    @HarEvrakTipi AS tinyint,
    @IstenenDovizTipi AS tinyint,
    @Caricinsi AS tinyint,
    @AnaDovizGecersiz AS bit,
    @AlternatifDovizGecersiz AS bit,
    @OrjinalDovizGecersiz AS bit,
    @Masraf1 AS float,
    @Masraf2 AS float,
    @Masraf3 AS float,
    @Masraf4 AS float,
    @OtvTutar AS float,
    @OivTutar AS float,
    @Yuvarlama AS float,
    @Tevkifat AS float,
    @Stopaj AS float,
    @SavSanDesFonu AS float,
    @Vergifon AS float,
    @HarTicaretTuru AS tinyint,
    @KarsiCaricinsi AS tinyint,
    @KarsiCarikodu AS nvarchar(25)
)
RETURNS float
AS
BEGIN
    DECLARE @OTV_eklenecek_Fl AS bit

    IF (@Caricinsi = 8) AND (@OtvTutar <> 0)
        SET @OTV_eklenecek_Fl = dbo.fn_Atik_OTV_Maliyete_eklensin(@KarsiCarikodu)
    ELSE
        SET @OTV_eklenecek_Fl = 1

    DECLARE @Result AS float
    SET @Result = 0

    SET @Result = CASE
        WHEN (@HarCinsi IN (1,2,3,4,17,18,19,20,21,22))
         AND (@Caricinsi IN (2,4))
        THEN @AraToplam

        WHEN (@HarCinsi IN (9,27))
         AND (@Caricinsi IN (3,5,9,12))
        THEN @CariMeblag - @Vergitop + @Stopaj + @SavSanDesFonu
             - @Yuvarlama + @Tevkifat - @Vergifon

        WHEN (@HarCinsi IN (26))
         AND (@Caricinsi IN (5,6,8))
        THEN @CariMeblag + @Stopaj + @SavSanDesFonu
             - @Tevkifat - @Yuvarlama

        WHEN (@HarCinsi IN (8,14,11,10,28))
         AND (@Caricinsi IN (3,5,6,8,9,12))
        THEN @CariMeblag - @Vergitop - @OivTutar + @Stopaj
             + @SavSanDesFonu - @Yuvarlama + @Tevkifat - @Vergifon

        WHEN (@HarCinsi IN (13,29))
          OR (@HarTicaretTuru IN (2,4)
              AND (@HarCinsi IN (10,11,14,15)
                   OR (@HarCinsi IN (8) AND @KarsiCaricinsi = 6)))
          OR (NOT (@Caricinsi IN (0,1,2,4,6,10,11,13)))
        THEN @CariMeblag - @Vergitop - @OtvTutar - @OivTutar
             + @Stopaj + @SavSanDesFonu - @Vergifon

        WHEN (@HarCinsi = 33) AND (@Caricinsi IN (0,1,6))
        THEN @AraToplam

        WHEN (@Caricinsi IN (10))
        THEN @AraToplam

        WHEN (@HarEvrakTipi IN (108)) AND (@Caricinsi IN (2))
        THEN @AraToplam

        WHEN (@HarEvrakTipi IN (109)) AND (@Caricinsi IN (11))
        THEN @AraToplam

        ELSE @CariMeblag
    END

    IF @OTV_eklenecek_Fl = 0
        SET @Result = @Result - @OtvTutar

    SET @Result = CASE
        WHEN @IstenenDovizTipi = 0
        THEN @Result * @HDkur
        WHEN (@IstenenDovizTipi = 1) AND (@AltDKur != 0)
        THEN @Result * @HDkur / @AltDKur
        WHEN (@IstenenDovizTipi = 1) AND (@AltDKur = 0)
        THEN 0
        WHEN @IstenenDovizTipi = 2
        THEN @Result
        WHEN (@IstenenDovizTipi = 3) AND (@KarsiDKur != 0)
        THEN @Result * @HDkur / @KarsiDKur
        WHEN (@IstenenDovizTipi = 3) AND (@KarsiDKur = 0)
        THEN 0
        ELSE @Result
    END

    SET @Result = CASE
        WHEN ((@HarCinsi = 11) OR (@HarEvrakTipi = 59))
         AND (@IstenenDovizTipi IN (2,3))
        THEN 0
        WHEN (@AnaDovizGecersiz = 1) AND (@IstenenDovizTipi = 0)
        THEN 0
        WHEN (@AlternatifDovizGecersiz = 1) AND (@IstenenDovizTipi = 1)
        THEN 0
        WHEN (@OrjinalDovizGecersiz = 1) AND (@IstenenDovizTipi IN (2,3))
        THEN 0
        ELSE @Result
    END

    RETURN @Result
END
GO
