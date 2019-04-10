CREATE PROCEDURE SMo_StateList
  (@ConnectID	MoID)
AS
BEGIN
  SELECT
    S.StateID,
    S.StateName,
    S.CountryID,
    C.CountryName
  FROM Mo_State S
    JOIN Mo_Country C ON (C.CountryID = S.CountryID)
  ORDER BY S.StateName;
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SMo_StateList] TO PUBLIC
    AS [dbo];

