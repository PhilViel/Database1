

CREATE VIEW [dbo].[Messages] AS
SELECT 
	M.iIdMessages,
	M.vcCode,
	M.Regle,
	Description_FRA = MF.vcDescriptionMessagesTraductions,
	Description_ENU = MA.vcDescriptionMessagesTraductions,
	M.Severite
FROM tblGENE_Messages M
LEFT JOIN tblGENE_MessagesTraductions MF ON MF.iIdMessages = M.iIdMessages AND MF.LangId = 'FRA' 
LEFT JOIN tblGENE_MessagesTraductions MA ON MA.iIdMessages = M.iIdMessages AND MA.LangId = 'ENU' 


