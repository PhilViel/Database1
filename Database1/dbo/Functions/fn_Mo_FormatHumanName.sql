
CREATE FUNCTION dbo.fn_Mo_FormatHumanName
( @LastName	MoFirstNameOption,
  @OrigName	MoDescOption,
  @FirstName	MoFirstNameOption,
  @Initial	MoInitial,
  @CompanyName  MoDescOption,
  @IsCompany	MoBitFalse
)
RETURNS MoDesc
AS
BEGIN
  DECLARE
    @Result MoDesc;

  SET @LastName = ISNULL(@LastName, '');
  SET @OrigName = ' ' + ISNULL(@OrigName, '');
  SET @FirstName = ISNULL(@FirstName, '');
  SET @Initial = ISNULL(@Initial, '');
  SET @CompanyName = ISNULL(@CompanyName, '');

  IF @IsCompany = 1
  BEGIN
    SET @Result = @CompanyName;
    IF (@LastName <> '')
      SET @Result = @Result + ' (' + @LastName + RTRIM(@OrigName) + ', '+ @FirstName + @Initial +')';
  END
  ELSE
  BEGIN
    SET @Result = @LastName + RTRIM(@OrigName) + ', '+ @FirstName + @Initial;
    IF (@CompanyName <> '')
      SET @Result = @Result + ' (' + @CompanyName +')';
  END;

  RETURN(@Result)
END

