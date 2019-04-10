/****************************************************************************************************
Copyrights (c) 2007 Gestion Universitas Inc.
Nom                 :	SL_CRI_DocPrintQueueDocTypeID
Description         :	Procédure qui renvoi les types de documents à imprimer de la queue d’impression.
Valeurs de retours  :	Dataset :
									DocTypeID	INTEGER		ID du type de document
									DocTypeDesc	VARCHAR(75)	Description du type de document
									iNbDoc		INTEGER		Nombre de documents à imprimer
Note                :	ADX0001206	IA	2007-01-12	Bruno Lapointe		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_CRI_DocPrintQueueDocTypeID] 
AS
BEGIN
	SELECT 
		T.DocTypeID,
		T.DocTypeDesc,
		iNbDoc = COUNT(D.DocID)
	FROM CRQ_Doc D 
	JOIN CRQ_DocTemplate M ON D.DocTemplateID = M.DocTemplateID
	JOIN CRQ_DocType T ON M.DocTypeID = T.DocTypeID
	WHERE D.DocID NOT IN (SELECT DocID FROM CRQ_DocPrinted)
	GROUP BY
		T.DocTypeID,
		T.DocTypeDesc
	ORDER BY 
		T.DocTypeDesc,
		T.DocTypeID
END
