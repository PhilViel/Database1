/****************************************************************************************************

	PROCEDURE QUI RETOURNE LES ÉTATS DE CONVENTION

*********************************************************************************
	03-05-2004 Dominic Létourneau
		Création de la stored procedure pour point 10.23.1 (4.5)
*********************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_UN_ConventionState] (
	@ConnectID MoID, -- Identifiant unique de la connection	
	@ConventionStateID MoID) -- ID de l'état, 0 pour tous

AS

BEGIN

	-- Retourne les états possibles d'une convention
	SELECT 
		ConventionStateID,
		ConventionStateName
	FROM Un_ConventionState 
	WHERE ConventionStateID = ISNULL(NULLIF(@ConventionStateID, 0), ConventionStateID) -- Si 0, tous les dossiers sont retournés

END


