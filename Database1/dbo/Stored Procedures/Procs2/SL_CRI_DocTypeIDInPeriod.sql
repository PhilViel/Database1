/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 : SL_CRI_DocTypeIDInPeriod
Description         : PROCEDURE RETOURNANT LES Types de documents possibles a ré-imprimer dans une période
Valeurs de retours  : >0  :	Tout à fonctionné
                      <=0 :	Erreur SQL
Note                :		
			ADX0001206	IA	2006-12-20	Alain Quirion		Création-Optimisation	
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_CRI_DocTypeIDInPeriod] (
	@StartDate DATETIME, -- Date de début de la période
	@EndDate DATETIME) -- Date de fin de la période
AS
BEGIN
	SELECT DISTINCT
		T.DocTypeID,
		T.DocTypeDesc,
		iNbDoc = COUNT(D.DocID)		
	FROM CRQ_Doc D 
	JOIN CRQ_DocTemplate M ON D.DocTemplateID = M.DocTemplateID
	JOIN CRQ_DocType T ON M.DocTypeID = T.DocTypeID	
	JOIN CRQ_DocPrinted P ON D.DocID = P.DocID	
	WHERE P.DocPrintTime BETWEEN @StartDate AND @EndDate+1
	GROUP BY
		T.DocTypeID,
		T.DocTypeDesc
	ORDER BY 
		T.DocTypeDesc,
		T.DocTypeID
END
