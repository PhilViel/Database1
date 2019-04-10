/****************************************************************************************************

	PROCEDURE DE SUPPRESSION D'HISTORIQUES D'ÉTATS DE CONVENTIONS

*********************************************************************************
	30-04-2004	Dominic Létourneau		Création de la stored procedure pour 10.23.1 (5.4)
	2015-10-09	Pierre-Luc Simard			Désactiver la procédure pour ne plus permettre de modifications via Delphi 
															puisque la suppression du droit ne fonctionne pas.		
*********************************************************************************/
CREATE PROCEDURE [dbo].[SP_DL_UN_ConventionConventionState] (
	@ConnectID MoID, -- Identifiant unique de la connection	
	@ConventionConventionStateID MoID) -- Identifiant unique de l'état sur conventions

AS

BEGIN
	
	SELECT 1/0
	/*
	-- Suppression de l'état pour une convention
	DELETE Un_ConventionConventionState
	WHERE ConventionConventionStateID = @ConventionConventionStateID
	*/
	-- Si une erreur s'est produite, elle est retournée, sinon 0 (suppression effectuée avec succès)
	RETURN @@ERROR 

END


