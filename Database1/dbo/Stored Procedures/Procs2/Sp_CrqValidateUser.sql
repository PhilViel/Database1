

CREATE PROCEDURE Sp_CrqValidateUser (
										@LoginNameID MoLoginName,
										@PasswordID MoLoginName
									)
AS
---------------------------------------------
-- STORED PROCEDURE DE VALIDATION DE L'USAGER
---------------------------------------------

SELECT UserID,
	CodeID,
	PassWordDate,
	TerminatedDate, 
	PassWordEndDate 
FROM Mo_User
WHERE LoginNameID = @LoginNameID
	AND dbo.fn_Mo_Decrypt(PasswordID) = @PasswordID
	AND (TerminatedDate IS NULL OR TerminatedDate > GetDate())

