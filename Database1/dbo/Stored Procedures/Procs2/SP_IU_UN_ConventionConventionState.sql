
/****************************************************************************************************
Code de service		:		SP_IU_UN_ConventionConventionState
Nom du service		:		SP_IU_UN_ConventionConventionState
But					:		PROCEDURE D'AJOUT ET DE MODIFICATION D'HISTORIQUES D'ÉTATS DE CONVENTIONS
Facette				:		
Reférence			:		

Parametres d'entrée :	Parametres					Description
		                ----------                  ----------------
						@ConnectID					-- Identifiant unique de la connection	
						@ConventionConventionStateID -- Identifiant unique de l'historique d'états sur convention
						@ConventionID				-- Identifiant unique de la convention
						@ConventionStateID			-- Identifiant unique de l'état de convention
						@StartDate					-- Date d'activation de l'état

Exemple d'appel:
					
		
Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
													@ID (@ConventionConventionStateID)

Historique des modifications :
			
		Date						Programmeur								Description							Référence
		----------					-------------------------------------	----------------------------		---------------
		30-04-2004					Dominic Létourneau				Création de la stored procedure pour 10.23.1 (4.3)
		2004-07-12					Bruno Lapointe						Correction @ConventionStateID est VARCHAR(3) et non integer
		2009-09-24					Jean-François Gauthier			Remplacement du @@Identity par Scope_Identity()
		2015-10-09					Pierre-Luc Simard					Désactiver la procédure pour ne plus permettre de modifications via Delphi 
																						puisque la suppression du droit ne fonctionne pas.		
 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[SP_IU_UN_ConventionConventionState] (
	@ConnectID INTEGER, -- Identifiant unique de la connection	
	@ConventionConventionStateID INTEGER, -- Identifiant unique de l'historique d'états sur convention
	@ConventionID INTEGER, -- Identifiant unique de la convention
	@ConventionStateID VARCHAR(3), -- Identifiant unique de l'état de convention
	@StartDate DATETIME) -- Date d'activation de l'état
AS
BEGIN
	DECLARE @ID MoID

	SET @ID = 1/0
	    
	/*
	IF @ConventionConventionStateID = 0
	-- Le dossier n'est pas existant; il sera donc créé
	BEGIN
		INSERT Un_ConventionConventionState (
			ConventionID,
			ConventionStateID,
			StartDate)
		SELECT 
			@ConventionID,
			@ConventionStateID,
			ISNULL(@StartDate, GETDATE()) -- Prend la date actuelle du traitement si nulle

		-- Gestion d'erreur
		IF @@ERROR = 0
			SELECT @ID = SCOPE_IDENTITY()
		ELSE
			SET @ID = 0
	END
	ELSE -- Le dossier est existant et sera modifié
	BEGIN
		UPDATE Un_ConventionConventionState
		SET 
			StartDate = @StartDate,
			ConventionStateID = @ConventionStateID
		WHERE ConventionConventionStateID = @ConventionConventionStateID 

		-- Gestion d'erreur
		IF @@ERROR = 0
			SET @ID = @ConventionConventionStateID
		ELSE
			SET @ID = 0
	END
	*/
	RETURN @ID -- Retourne l'ID du dossier si tout a fonctionné, sinon 0
	
END
