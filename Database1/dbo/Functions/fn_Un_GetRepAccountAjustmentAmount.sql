

--  dbo UDF fn_Un_GetRepAccountAjustmentAmount
--      This function takes as input a commission to pay, 
--                                     advance to pay,
--                                     Previous ajustment amount from Un_RepAccount,
--                                     Future Commission,
--                                     Maximum Representative risk %
--      and returns the ajustment amount
CREATE FUNCTION dbo.fn_Un_GetRepAccountAjustmentAmount
( @FCommission          MoMoney,
  @FAdvance             MoMoney,
  @FOldAjust            MoMoney,
  @FuturCom             MoMoney,
  @MaxRepRisk           MoPctPos
)
RETURNS MoMoney
AS
BEGIN
  DECLARE
    @RepRisk    MoPctPos, 
    @Ajustment  MoMoney

  SET @RepRisk   = 0
  SET @Ajustment = 0

  IF @FAdvance > 0
  BEGIN 
    SET @RepRisk = (@FAdvance / (@FuturCom + @FAdvance)) * 100  

    IF @RepRisk >= @MaxRepRisk
      SET @Ajustment = (@FCommission + @FAdvance + @FOldAjust) - (((@MaxRepRisk/100)*(@FCommission + @FAdvance + @FOldAjust)) - @FOldAjust)
    ELSE SET @Ajustment = - @FOldAjust
  END 
  ELSE SET @Ajustment = - @FOldAjust
  RETURN(@Ajustment)
END

