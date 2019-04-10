
/****************************************************************************************************
Code de service		:		SP_IU_CRQ_DocTemplate
Nom du service		:		SP_IU_CRQ_DocTemplate
But					:		Procedure d'ajout et de modification de modèles de documents
Facette				:		
Reférence			:		

Parametres d'entrée :	Parametres					Description
		                ----------                  ----------------
						@ConnectID					-- Identifiant unique de la connection	
						@DocTemplateID				-- Identifiant unique d'un modèle (passer 0 ou NULL pour l'ajout)
						@DocTypeID					-- Type de modèle de document
						@LangID						-- Identifiant de la langue du modèle
						@DocTemplateTime			-- Date et heure de création/modification du modèle
						@DocTemplate				-- Modèle de document stocké dans un blob
						

Exemple d'appel:
					
		
Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
													@ID (@DocTemplateID)

Historique des modifications :
			
		Date						Programmeur								Description							Référence
		----------					-------------------------------------	----------------------------		---------------
		2004-05-12					Dominic Létourneau						Création de la procedure pour CRQ-INT-00003
		2004-06-15					Bruno Lapointe							Ajout d'un test de sauvegarde (-1 Il y a déjà un document avec la même date, 		heure, type de document et langue)
		2009-09-24					Jean-François Gauthier					Remplacement du @@Identity par Scope_Identity()
 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[SP_IU_CRQ_DocTemplate] (
	@ConnectID INTEGER, -- Identifiant unique de la connection	
	@DocTemplateID INTEGER = NULL, -- Identifiant unique d'un modèle (passer 0 ou NULL pour l'ajout)
	@DocTypeID INTEGER, -- Type de modèle de document
	@LangID VARCHAR(3), -- Identifiant de la langue du modèle
	@DocTemplateTime DATETIME, -- Date et heure de création/modification du modèle
	@DocTemplate TEXT) -- Modèle de document stocké dans un blob
AS
BEGIN
	-- Variables de travail
	DECLARE 
		@ID INTEGER, -- Clé générée
		@LogDesc VARCHAR(5000), 
		@OldConnectID INTEGER,
		@OldDocTemplateID INTEGER,
		@OldDocTypeID INTEGER,
		@OldLangID VARCHAR(3),
		@OldDocTemplateTime DATETIME

	IF NOT EXISTS ( -- Valide qu'on est un formatage d'inséré dans la base de données pour ce type de document avant la date du template
			SELECT 
				DocTypeID
			FROM CRQ_DocTypeDataFormat
			WHERE DocTypeID = @DocTypeID
			  AND DocTypeTime <= @DocTemplateTime)
		SET @ID = -2		
	ELSE IF ISNULL(@DocTemplateID,0) = 0
	-- Le dossier n'est pas existant; il sera donc créé
	BEGIN
		IF EXISTS ( -- Vérifie si il n'y a pas déjà un document avec la même date, heure, type de document et langue
				SELECT 
					DocTemplateID
				FROM CRQ_DocTemplate
				WHERE DocTypeID = @DocTypeID
				  AND DocTemplateTime = @DocTemplateTime
				  AND LangID = @LangID)
			SET @ID = -1
		ELSE 
		BEGIN
			INSERT CRQ_DocTemplate (
				DocTypeID,
				ConnectID,
				LangID,
				DocTemplateTime,
				DocTemplate)
			SELECT 
				@DocTypeID,
				@ConnectID,
				@LangID,
				@DocTemplateTime,
				@DocTemplate
	
			-- Gestion d'erreur
			IF @@ERROR = 0
			BEGIN
				SELECT @ID = SCOPE_IDENTITY()
				-- Gestion du log
				SET @LogDesc = dbo.FN_CRQ_FormatLog ('CRQ_DocTemplate', 'NEW', '', @ID)
				SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('CRQ_DocTemplate', 'DocTypeID', '', @DocTypeID)
				SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('CRQ_DocTemplate', 'ConnectID', '', @ConnectID)
				SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('CRQ_DocTemplate', 'LangID', '', @LangID)
				SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('CRQ_DocTemplate', 'DocTemplateTime', '', @DocTemplateTime)
				EXEC SP_IU_CRQ_Log @ConnectID, 'CRQ_DocTemplate', @ID, 'I', @LogDesc
			END
			ELSE -- Une erreur s'est produite
				SET @ID = 0
		END
	END
	ELSE -- Le dossier est existant et sera modifié
	BEGIN

		-- Conserve les anciennes valeurs avant l'update
		SELECT 
			@DocTypeID = @DocTypeID,
			@ConnectID = @ConnectID,
			@OldLangID = LangID,
			@OldDocTemplateTime = DocTemplateTime
		FROM CRQ_DocTemplate
		WHERE DocTemplateID = @DocTemplateID

		UPDATE CRQ_DocTemplate
		SET 
			DocTypeID = @DocTypeID,
			ConnectID = @ConnectID,
			LangID = LangID,
			DocTemplateTime = DocTemplateTime,
			DocTemplate = @DocTemplate
		WHERE DocTemplateID = @DocTemplateID 

		-- Gestion d'erreur
		IF @@ERROR = 0
		BEGIN
			SET @ID = @DocTemplateID
			-- Gestion du log
			SET @LogDesc = dbo.FN_CRQ_FormatLog ('CRQ_DocTemplate', 'MODIF', '', @DocTemplateID)
			SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('CRQ_DocTemplate', 'DocTypeID', @OldDocTypeID, @DocTypeID)
			SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('CRQ_DocTemplate', 'ConnectID', @OldConnectID, @ConnectID)
			SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('CRQ_DocTemplate', 'LangID', @OldLangID, @LangID)
			SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('CRQ_DocTemplate', 'DocTemplateTime', @OldDocTemplateTime, @DocTemplateTime)
			EXEC SP_IU_CRQ_Log @ConnectID, 'CRQ_Doc', @DocTemplateID, 'U', @LogDesc
		END
		ELSE -- Une erreur s'est produite
			SET @ID = 0
	
	END

	RETURN @ID 

	-- VALEUR DE RETOUR
	-------------------
	-- >0 : ID = id du template et tout a fonctionné
	-- 0 : Erreur SQL
	-- -1 : Il y a déjà un document avec la même date, heure, type de document et langue
	-- -2 : Il n'y a pas de formatage RTF dans la base de données pour ce type de document à cette date
END
