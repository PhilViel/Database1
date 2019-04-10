
--  dbo UDF fn_Mo_BankAccountDesc
--	and returns the Bank account no and name description 
CREATE FUNCTION dbo.fn_Mo_BankAccountDesc 
(
  @BankAccountID       MoID
)  
RETURNS MoDesc 
AS  
BEGIN
  DECLARE
    @Result MoDesc;
  
  IF EXISTS(SELECT BankAccountID FROM Mo_BankAccount WHERE (BankAccountID = @BankAccountID))
    SELECT 
      @Result = AccountName +' ('+ AccountNo+')' 
    FROM Mo_BankAccount
    WHERE (BankAccountID = @BankAccountID)
  ELSE 
    SET @Result = ''


  RETURN(@Result)                  
END

