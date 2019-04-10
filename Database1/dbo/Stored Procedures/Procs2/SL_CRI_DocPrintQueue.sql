/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 : SL_CRI_DocPrintQueue
Description         : PROCEDURE RETOURNANT LES DOCUMENTS NON-IMPRIMÉS DANS LA FILE D'ATTENTE
Valeurs de retours  : >0  :	Tout à fonctionné
                      <=0 :	Erreur SQL
Note                :		
						12-05-2004 	Dominic Létourneau	Création de la procedure pour CRQ-INT-00003	
			ADX0001206	IA	2006-12-20	Alain Quirion		Optimisation	
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_CRI_DocPrintQueue] (
	@DocTypeID INTEGER = 0)
AS
BEGIN
	SELECT --top 4500
		D.DocID,
		D.DocTemplateID,
		T.DocTypeID,
		T.DocTypeDesc,
		DocOrderName = 
			CASE
				WHEN OH.LastName IS NULL THEN ''
			ELSE OH.LastName + ', ' + OH.FirstName
			END,
		D.DocOrderTime,
		D.DocGroup1,
		D.DocGroup2,
		D.DocGroup3,
		M.LangID,
		Selection = CONVERT(BIT, 0) -- Utilisé dans la grille Quantum pour les checkboxes
	FROM CRQ_Doc D 
	JOIN CRQ_DocTemplate M ON D.DocTemplateID = M.DocTemplateID
	JOIN CRQ_DocType T ON M.DocTypeID = T.DocTypeID
	LEFT JOIN Mo_Connect OC ON D.DocOrderConnectID = OC.ConnectID
	LEFT JOIN dbo.Mo_Human OH ON OC.UserID = OH.HumanID		
	WHERE D.DocID NOT IN (SELECT DocID FROM CRQ_DocPrinted)
		AND (@DocTypeID = 0 OR @DocTypeID = T.DocTypeID)
	ORDER BY T.DocTypeID, D.DocOrderTime

END


