
--  dbo UDF fn_Mo_CompanyName
--	and returns the CompanyName name 
CREATE FUNCTION dbo.fn_Mo_CompanyName 
(
  @CompanyID       MoID
)  
RETURNS MoDesc 
AS  
BEGIN
  DECLARE
    @Result MoDesc;
  
  IF EXISTS(SELECT CompanyID FROM Mo_Company WHERE (CompanyID = @CompanyID))
    SELECT 
      @Result = CompanyName
    FROM Mo_Company 
    WHERE (CompanyID = @CompanyID)
  ELSE 
    SET @Result = ''


  RETURN(@Result)                  
END

