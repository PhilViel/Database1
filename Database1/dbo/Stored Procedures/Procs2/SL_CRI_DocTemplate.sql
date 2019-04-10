/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	SL_CRI_DocTemplate
Description         :	PROCEDURE RETOURNANT LES DOSSIERS DE LA TABLE CRQ_DocTemplate
Valeurs de retours  :	Dataset
Note                :						12-05-2004 	Dominic Létourneau	Création de la procedure pour CRQ-INT-00003	
								ADX0001206	IA	2006-12-20	Alain Quirion			Optimisation
								ADX0001206	IA	2007-01-16	Bruno Lapointe			Optimisation
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_CRI_DocTemplate] (
	@ConnectID INTEGER) -- Identifiant unique de la connection	
AS
BEGIN
	-- Retourne tous les dossiers de la table CRQ_DocTemplate
	SELECT 
		T.DocTemplateID,
		TY.DocTypeID,
		TY.DocTypeDesc,
		T.LangID,
		T.DocTemplateTime
--		T.DocTemplate
	FROM CRQ_DocTemplate T
	JOIN CRQ_DocType TY ON T.DocTypeID = TY.DocTypeID
	ORDER BY 
		TY.DocTypeDesc,
		TY.DocTypeID,
		T.DocTemplateTime
END
