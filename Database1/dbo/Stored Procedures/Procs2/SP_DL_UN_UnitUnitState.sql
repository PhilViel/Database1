/****************************************************************************************************

	PROCEDURE DE SUPPRESSION D'HISTORIQUES D'ÉTATS DE GROUPES D'UNITÉS

*********************************************************************************
	30-04-2004	Dominic Létourneau		Création de la stored procedure pour 10.23.1 (5.4)
	2015-10-09	Pierre-Luc Simard			Ne plus permettre l'appel via Delphi. Le retrait des accès ne fonctionne pas.
*********************************************************************************/
CREATE PROCEDURE [dbo].[SP_DL_UN_UnitUnitState] (
	@ConnectID MoID, -- Identifiant unique de la connection	
	@UnitUnitStateID MoID) -- Identifiant unique de l'état sur groupe d'unités

AS

BEGIN

	SELECT 1/0
	/*
	-- Suppression de l'état pour une convention
	DELETE Un_UnitUnitState
	WHERE UnitUnitStateID = @UnitUnitStateID
	*/

	-- Si une erreur s'est produite, elle est retournée, sinon 0 (suppression effectuée avec succès)
	RETURN @@ERROR 

END


