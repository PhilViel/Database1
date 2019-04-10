
--  dbo UDF fn_Mo_HumanName
--	and returns the representative name 
CREATE FUNCTION [dbo].[fn_Mo_HumanName] 
(
  @HumanID       MoID
)  
RETURNS MoDesc 
AS  
BEGIN
  DECLARE
    @Result MoDesc;
  
  IF EXISTS(SELECT HumanID FROM dbo.Mo_Human WHERE (HumanID = @HumanID))
    SELECT 
      @Result = LastName +', '+ FirstName 
    FROM dbo.Mo_Human
    WHERE (HumanID = @HumanID)
  ELSE 
    SET @Result = ''


  RETURN(@Result)                  
END

