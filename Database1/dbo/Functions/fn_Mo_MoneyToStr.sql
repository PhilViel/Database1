
/*
2012-06-12	Donald Huppé		GLPI 7697 : Mettre une virgule comme séparateur de millier en anglais et enlever l'espace en $ et le montant
								Nathalie Poulin comprend que c'est pour toutes les lettres

*/

CREATE FUNCTION [dbo].[fn_Mo_MoneyToStr]
( @FMoney      MoMoney,
  @FLang       MoLang,     -- Language  FRA = French / ENU = English / UNK = Unknown
  @DollarSign  MoBitTrue   -- Show Dollar sign
)
RETURNS MoDesc
AS
BEGIN
DECLARE
  @FMoneyStr  MoDesc,
  @IntPart    MoDesc,
  @DecPart    MoDesc,
  @Temp       MoDesc,
  @Position   MoID;

  --Default setting is in english
  SET @FMoneyStr = LTRIM(RTRIM(STR(ROUND(@FMoney, 2), 15, 2)))
  SET @IntPart = SUBSTRING(@FMoneyStr, 1, (DATALENGTH(@FMoneyStr)-3))
  SET @DecPart = SUBSTRING(@FMoneyStr, (DATALENGTH(@FMoneyStr)-1), 2)
  SET @Position = DATALENGTH(@IntPart)

  SET @Temp      = ''
  SET @FMoneyStr = ''

  WHILE @Position > 0
  BEGIN
    SET @Temp = SUBSTRING(@IntPart, @Position, 1) + @Temp
    IF (DATALENGTH(@Temp) = 3) OR (@Position = 1)
    BEGIN
      IF @FMoneyStr = ''
        SET @FMoneyStr = @Temp
      ELSE
		IF @FLang = 'FRA'
        SET @FMoneyStr = @Temp + SPACE(1) + @FMoneyStr
        ELSE
        SET @FMoneyStr = @Temp + ',' + @FMoneyStr
      SET @Temp = ''
    END
    SET @Position = @Position -1
  END

  IF @FLang = 'FRA'
  BEGIN
    SET @FMoneyStr = @FMoneyStr + ',' + @DecPart
    IF @DollarSign = 1
      SET @FMoneyStr = @FMoneyStr + ' $'
  END
  ELSE
  BEGIN
    SET @FMoneyStr = @FMoneyStr + '.' + @DecPart
    IF @DollarSign = 1
      SET @FMoneyStr = '$' + @FMoneyStr
  END

  RETURN(@FMoneyStr)
END

