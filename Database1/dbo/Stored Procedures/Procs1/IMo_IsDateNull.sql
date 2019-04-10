
CREATE PROCEDURE IMo_IsDateNull
  (@DateNull       MoDateOption OUTPUT)
AS
BEGIN
  -- Pour les insertions dans les tables nous devons vérifier si la date est '1850/01/01' ou -2
  -- ce qui va donner à la fin une date NULL

  IF @DateNull IS NOT NULL
  BEGIN
    IF (@DateNull = CONVERT (DATETIME, '1850.01.01', 102)) OR (@DateNull = -2)
      SET @DateNull = NULL;
  END;
END;
