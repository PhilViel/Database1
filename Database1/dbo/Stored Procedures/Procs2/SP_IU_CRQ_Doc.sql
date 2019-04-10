
/****************************************************************************************************
Code de service		:		SP_IU_CRQ_Doc
Nom du service		:		SP_IU_CRQ_Doc
But					:		PROCEDURE D'AJOUT ET DE MODIFICATION DE DOCUMENTS.
Facette				:		
Reférence			:		

Parametres d'entrée :	Parametres					Description
		                ----------                  ----------------
						@ConnectID					-- Identifiant unique de connection
						@DocID						-- Identifiant unique d'un document (passer 0 ou NULL pour l'ajout)
						@DocTemplateID				-- Modèle du document
						@DocOrderConnectID			-- Contient le ConnectID de la modification/Ajout
						@DocOrderTime				-- Date et heure d'ajout/modification
						@DocGroup1					-- Info du document
						@DocGroup2					-- Info du document
						@DocGroup3					-- Info du document
						@Doc						-- document stocké dans un blob

						

Exemple d'appel:
					
		
Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
													@ID (@DocID)								-- Conserve la clé générée

Historique des modifications :
			
		Date						Programmeur								Description							Référence
		----------					-------------------------------------	----------------------------		---------------
		12-05-2004					Dominic Létourneau						Création de la procedure pour CRQ-INT-00003
		2009-09-24					Jean-François Gauthier					Remplacement du @@Identity par Scope_Identity()
 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[SP_IU_CRQ_Doc] (
	@ConnectID INTEGER, -- Identifiant unique de connection
	@DocID INTEGER = NULL, -- Identifiant unique d'un document (passer 0 ou NULL pour l'ajout)
	@DocTemplateID INTEGER, -- Modèle du document
	@DocOrderConnectID INTEGER, -- Contient le ConnectID de la modification/Ajout
	@DocOrderTime DATETIME, -- Date et heure d'ajout/modification
	@DocGroup1 VARCHAR(100) = NULL, -- Info du document
	@DocGroup2 VARCHAR(100) = NULL, -- Info du document
	@DocGroup3 VARCHAR(100) = NULL, -- Info du document
	@Doc TEXT) -- document stocké dans un blob
AS

BEGIN

	-- Variables de travail
	DECLARE 
		@ID INTEGER,
		@LogDesc VARCHAR(5000),
		@Err INTEGER,
		@OldDocTemplateID INTEGER, 
		@OldDocOrderConnectID INTEGER, 

		@OldDocOrderTime DATETIME, 
		@OldDocGroup1 VARCHAR(100),
		@OldDocGroup2 VARCHAR(100),
		@OldDocGroup3 VARCHAR(100)

	IF ISNULL(@DocID,0) = 0
	-- Le dossier n'est pas existant; il sera donc créé
	BEGIN

		INSERT CRQ_Doc (
			DocTemplateID,
			DocOrderConnectID,
			DocOrderTime,
			DocGroup1,
			DocGroup2,

			DocGroup3,
			Doc)
		SELECT 
			@DocTemplateID,
			@DocOrderConnectID,
			@DocOrderTime,
			@DocGroup1,
			@DocGroup2,

			@DocGroup3,
			@Doc

		-- Gestion d'erreur
		IF @@ERROR = 0
		BEGIN
			SELECT @ID = SCOPE_IDENTITY() -- Conserve la valeur de la clé du dossier qui vient d'être ajouté
			-- Header du log
			SET @LogDesc = dbo.FN_CRQ_FormatLog ('CRQ_Doc', 'NEW', '', @ID)
			-- Détail du log
			SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('CRQ_Doc', 'DocTemplateID', '', @DocTemplateID)
			SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('CRQ_Doc', 'DocOrderConnectID', '', @DocOrderConnectID)
			SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('CRQ_Doc', 'DocOrderTime', '', @DocOrderTime)
			SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('CRQ_Doc', 'DocGroup1', '', @DocGroup1)
			SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('CRQ_Doc', 'DocGroup2', '', @DocGroup2)
			SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('CRQ_Doc', 'DocGroup3', '', @DocGroup3)
			-- Sauvegarde du log
			EXEC SP_IU_CRQ_Log @ConnectID, 'CRQ_Doc', @ID, 'I', @LogDesc
		END
		ELSE -- Une erreur s'est produite
			SET @ID = 0

	END
	ELSE -- Le dossier est existant et sera modifié
	BEGIN
	
		-- Conserve les anciennes valeurs avant l'update
		SELECT 
			@OldDocTemplateID = DocTemplateID, 
			@OldDocOrderConnectID = DocOrderConnectID,
			@OldDocOrderTime = DocOrderTime,
			@OldDocGroup1 = DocGroup1,
			@OldDocGroup2 = DocGroup2,
			@OldDocGroup3 = DocGroup3
		FROM CRQ_Doc
		WHERE DocID = @DocID 

		-- Mise à jour des données
		UPDATE CRQ_Doc
		SET 
			DocTemplateID = @DocTemplateID, 
			DocOrderConnectID = @DocOrderConnectID,
			DocOrderTime = @DocOrderTime,
			DocGroup1 = @DocGroup1,
			DocGroup2 = @DocGroup2,
			DocGroup3 = @DocGroup3,
			Doc = @Doc
		WHERE DocID = @DocID 

		-- Gestion d'erreur
		IF @@ERROR = 0
		BEGIN
			SET @ID = @DocID -- Conserve la clé générée
			-- Header du log
			SET @LogDesc = dbo.FN_CRQ_FormatLog ('CRQ_Doc', 'MODIF', '', @DocID)
			-- Détail du log
			SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('CRQ_Doc', 'DocTemplateID', @OldDocTemplateID, @DocTemplateID)
			SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('CRQ_Doc', 'DocOrderConnectID', @OldDocOrderConnectID, @DocOrderConnectID)
			SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('CRQ_Doc', 'DocOrderTime', @OldDocOrderTime, @DocOrderTime)
			SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('CRQ_Doc', 'DocGroup1', @OldDocGroup1, @DocGroup1)
			SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('CRQ_Doc', 'DocGroup2', @OldDocGroup2, @DocGroup2)
			SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('CRQ_Doc', 'DocGroup3', @OldDocGroup3, @DocGroup3)
			-- Sauvegarde du log
			EXEC SP_IU_CRQ_Log @ConnectID, 'CRQ_Doc', @DocID, 'U', @LogDesc
		END
		ELSE -- Une erreur s'est produite
			SET @ID = 0
	
	END

	-- Fin des traitements
	RETURN @ID -- Retourne l'ID du dossier si tout a fonctionné, sinon 0

END
