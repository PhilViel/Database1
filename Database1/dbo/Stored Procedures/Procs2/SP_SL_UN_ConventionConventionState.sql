/****************************************************************************************************

	PROCEDURE QUI RETOURNE L'HISTORIQUE DES ÉTATS D'UNE CONVENTION

*********************************************************************************
	03-05-2004 Dominic Létourneau
		Création de la stored procedure pour point 10.23.1 (4.6)
*********************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_UN_ConventionConventionState] (
	@ConnectID MoID, -- Identifiant unique de la connection	
	@ConventionID MoID) -- ID de la convention

AS

BEGIN

	-- Retourne l'historique des états d'une convention
	SELECT 
		C.ConventionConventionStateID,
		C.ConventionStateID, 
		S.ConventionStateName,
		C.StartDate
	FROM Un_ConventionConventionState C
	INNER JOIN Un_ConventionState S ON C.ConventionStateID = S.ConventionStateID
	WHERE C.ConventionID = @ConventionID
	ORDER BY C.StartDate 

END


