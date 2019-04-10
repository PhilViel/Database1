/****************************************************************************************************

	PROCEDURE QUI RETOURNE L'HISTORIQUE DES ÉTATS D'UN GROUPE D'UNITÉS

*********************************************************************************
	03-05-2004 Dominic Létourneau
		Création de la stored procedure pour point 10.23.1 (5.5)
*********************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_UN_UnitUnitState] (
	@ConnectID MoID, -- Identifiant unique de la connection	
	@UnitID MoID) -- ID du groupe d'unités

AS

BEGIN

	-- Retourne l'historique des états d'un groupe d'unités
	SELECT 
		U.UnitUnitStateID,
		U.UnitStateID, 
		S.UnitStateName,
		U.StartDate
	FROM Un_UnitUnitState U
	INNER JOIN Un_UnitState S ON U.UnitStateID = S.UnitStateID
	WHERE U.UnitID = @UnitID
	ORDER BY U.StartDate 

END


