
/****************************************************************************************************
Code de service		:		SP_IU_CRQ_Log
Nom du service		:		SP_IU_CRQ_Log
But					:		PROCEDURE DE CREATION DE LOG
Facette				:		
Reférence			:		

Parametres d'entrée :	Parametres					Description
		                ----------                  ----------------
						@ConnectID					-- Identifiant unique de la connection	
						@LogTableName				-- Nom de la table où a eu lieu la modification/ajout/suppression
						@LogCodeID					-- Clé du dossier modifié
						@LogActionID				-- Type d'action - U: modification, I: ajout, D: suppression
						@LogText					-- Information à conserver

						

Exemple d'appel:
					
		
Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
													- Retourne l'ID du dossier créé si tout s'est bien déroulé
													- RETURN (0) -- Une erreur est survenue
													- RETURN -1 -- Opération en erreur car @ConnectID = 0

Historique des modifications :
			
		Date						Programmeur								Description							Référence
		----------					-------------------------------------	----------------------------		---------------
		14-05-2004					Dominic Létourneau						Migration de l'ancienne procedure selon les nouveaux standards
		2009-09-24					Jean-François Gauthier					Remplacement du @@Identity par Scope_Identity()
 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_IU_CRQ_Log] (
	@ConnectID INTEGER, -- Identifiant unique de la connection	
	@LogTableName VARCHAR(75), -- Nom de la table où a eu lieu la modification/ajout/suppression
	@LogCodeID INTEGER = NULL, -- Clé du dossier modifié
	@LogActionID CHAR(1), -- Type d'action - U: modification, I: ajout, D: suppression
	@LogText TEXT) -- Information à conserver

AS

BEGIN

	IF @ConnectID <> 0
	BEGIN

		-- Création d'un nouveaux dossier contenant l'information dans la table de log
		INSERT Mo_Log (
			ConnectID,
			LogTableName,
			LogCodeID ,
			LogActionID,
			LogText)
		VALUES (
			@ConnectID,
			@LogTableName,
			@LogCodeID,
			@LogActionID,
			@LogText)
		
		IF (@@ERROR = 0)
			RETURN SCOPE_IDENTITY() -- Retourne l'ID du dossier créé si tout s'est bien déroulé
		ELSE
			RETURN (0) -- Une erreur est survenue

	END -- IF @ConnectID <> 0
	ELSE 
		RETURN -1 -- Opération en erreur car @ConnectID = 0

END
