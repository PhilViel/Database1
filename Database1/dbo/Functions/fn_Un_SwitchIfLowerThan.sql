
CREATE FUNCTION dbo.fn_Un_SwitchIfLowerThan
  (@FMoney       	MoMoney,
   @FLowLevel		MoMoney,
   @FDefaultValue	MoMoney )
RETURNS MoMoney 
AS  
BEGIN
  IF (@FMoney < @FLowLevel) OR (@FMoney IS NULL)  
    RETURN(@FDefaultValue)

  RETURN(@FMoney)
END

