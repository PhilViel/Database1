/****************************************************************************************************

	PROCEDURE RETOURNANT TOUS LES DOCUMENTS LIÉS À UN OBJET

*********************************************************************************
	12-05-2004 Dominic Létourneau
		Création de la procedure pour CRQ-INT-00003
	20-05-2004 Dominic Létourneau
		Modification suite ajout table CRQ_DocPrinted
*********************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_CRQ_DocLink] (
	@DocLinkID INTEGER, -- Identifiant unique de l'objet
	@DocLinkType INTEGER) -- Type de l'objet
AS
BEGIN
	-- Retourne les documents d'un objet 
	SELECT 
		D.DocID,
		DocPrintedID = ISNULL(P.DocPrintedID,0),
		D.DocTemplateID,
		T.DocTypeID,
		T.DocTypeDesc,
		DocOrderName = OH.LastName + ', ' + OH.FirstName,
		D.DocOrderTime,
		DocPrintName = PH.LastName  + ', ' + PH.FirstName,
		P.DocPrintTime,
		D.DocGroup1,
		D.DocGroup2,
		D.DocGroup3,
		M.LangID,
		Selection = CONVERT(BIT, 0) -- Utilisé dans la grille Quantum pour les checkboxes
	FROM CRQ_DocLink L
	INNER JOIN CRQ_Doc D ON L.DocID = D.DocID
	INNER JOIN CRQ_DocTemplate M ON D.DocTemplateID = M.DocTemplateID
	INNER JOIN CRQ_DocType T ON M.DocTypeID = T.DocTypeID
	INNER JOIN Mo_Connect OC ON D.DocOrderConnectID = OC.ConnectID
	INNER JOIN dbo.Mo_Human OH ON OC.UserID = OH.HumanID
	LEFT JOIN CRQ_DocPrinted P ON D.DocID = P.DocID
	LEFT JOIN Mo_Connect PC ON P.DocPrintConnectID = PC.ConnectID
	LEFT JOIN dbo.Mo_Human PH ON PC.UserID = PH.HumanID
	WHERE L.DocLinkID = @DocLinkID
		AND L.DocLinkType = @DocLinkType
	ORDER BY D.DocOrderTime DESC

	-- Fin des traitements
	RETURN 0
END


