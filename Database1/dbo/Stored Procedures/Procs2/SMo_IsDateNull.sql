
CREATE PROCEDURE SMo_IsDateNull
  (@DateNull            MoDateOption OUTPUT)
AS
BEGIN
  -- Si la date est NULL et que nous ne devons pas mettre une date null dans le "Stored Proc"
  -- au niveau de Delphi la date est zéro ou NULL.

  IF (@DateNull IS NULL) OR (@DateNull = CONVERT (DATETIME, '1850.01.01', 102))
    SET @DateNull = -2;
END;
