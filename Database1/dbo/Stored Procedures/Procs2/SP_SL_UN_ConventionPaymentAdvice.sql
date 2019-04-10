/****************************************************************************************************
	Historique des avis de dépôt expédiés pour une convention
 ******************************************************************************
	2004-06-15 Bruno Lapointe
		Création Point 12.41.03
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_UN_ConventionPaymentAdvice] (
	@ConventionID INTEGER) -- ID Unique de la convention
AS
BEGIN
	SELECT 
		DocOrderName = OH.LastName + ', ' + OH.FirstName,
		D.DocOrderTime,
		DocPrintName = PH.LastName  + ', ' + PH.FirstName,
		P.DocPrintTime,
		Amount = D.DocGroup3
	FROM CRQ_DocLink L
	JOIN CRQ_Doc D ON L.DocID = D.DocID
	JOIN CRQ_DocTemplate T ON T.DocTemplateID = D.DocTemplateID
	JOIN CRQ_DocType Ty ON Ty.DocTypeID = T.DocTypeID AND Ty.DocTypeCode = 'NoticeOfDeposit'
	JOIN Mo_Connect OC ON D.DocOrderConnectID = OC.ConnectID
	JOIN dbo.Mo_Human OH ON OC.UserID = OH.HumanID
	LEFT JOIN CRQ_DocPrinted P ON D.DocID = P.DocID
	LEFT JOIN Mo_Connect PC ON P.DocPrintConnectID = PC.ConnectID
	LEFT JOIN dbo.Mo_Human PH ON PC.UserID = PH.HumanID
	WHERE L.DocLinkID = @ConventionID
	  AND L.DocLinkType = 1
	ORDER BY D.DocOrderTime DESC

	-- DATASET DE RETOUR
	--------------------
	-- DocOrderName VARCHAR : nom de l'usager qui a commandé l'avis
	-- DocOrderTime DATETIME : date et heure à laquelle l'usager a commandé l'avis
	-- DocPrintName VARCHAR : nom de l'usager qui a imprimé l'avis
	-- DocPrintTime DATETIME : date et heure à laquelle l'usager a imprimé l'avis
	-- Amount VARCHAR : montant de l'avis
END


