/****************************************************************************************************

	PROCEDURE QUI RETOURNE LES ÉTATS DE GROUPES D'UNITÉS

*********************************************************************************
	03-05-2004 Dominic Létourneau
		Création de la stored procedure pour point 10.23.1 (5.5)
*********************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_UN_UnitState] (
	@ConnectID MoID, -- Identifiant unique de la connection	
	@UnitStateID MoID) -- ID de l'état, 0 pour tous

AS

BEGIN

	-- Retourne les états possibles d'un groupe d'unités
	SELECT 
		UnitStateID, 
		UnitStateName
	FROM Un_UnitState 
	WHERE UnitStateID = ISNULL(NULLIF(@UnitStateID, 0), UnitStateID) -- Si 0, tous les dossiers sont retournés
		AND UnitStateID NOT IN (SELECT DISTINCT OwnerUnitStateID FROM Un_UnitState) -- Ne retourne que les dossiers qui ne sont pas parents
END


