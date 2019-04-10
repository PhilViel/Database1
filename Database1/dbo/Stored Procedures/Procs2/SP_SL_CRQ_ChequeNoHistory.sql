/****************************************************************************************************
	Liste les historiques de numéros de chèque pour les chèques dont les IDs sont
	passés en paramètres.             
 ******************************************************************************                                                                             
	2003-06-11 Bruno Lapointe
		Création
	2004-06-15 Bruno Lapointe
		Migration
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_CRQ_ChequeNoHistory] (
	@ChequeIDs   VARCHAR(8000)) -- IDs des chèques dont l'on veut l'historique
AS
BEGIN
	-- Le paramètre @ChequeIDs est un string qui énumère les ID des chèques en 
	-- les séparant par des virgules.  Cette étape les sépares pour qu'on est un
	-- ID par enregistrement dans la table temporaire.

	SELECT 
		H.ChequeID,
		H.ChequeNoHistoryDate,
		H.ChequeNoHistoryID,
		H.ChequeNo
	FROM Mo_ChequeNoHistory H
	JOIN FN_CRQ_IntegerTable(@ChequeIDs) C ON (C.Val = H.ChequeID)
	ORDER BY 
		H.ChequeID, 
		H.ChequeNoHistoryDate DESC, 
		H.ChequeNoHistoryID DESC

	-- DATASET DE RETOUR
	--------------------
	-- ChequeID INTEGER : ID unique du chèque
	-- ChequeNoHistoryDate DATETIME : date d'entrée en vigueur de l'historique
	-- ChequeNoHistoryID INTEGER : ID unique de l'historique de numéro de chèque
	-- ChequeNo VARCHAR : Numéro du chèque
END
