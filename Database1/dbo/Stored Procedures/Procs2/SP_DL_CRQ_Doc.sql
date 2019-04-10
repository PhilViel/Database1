/****************************************************************************************************

	PROCEDURE DE SUPPRESSION DE DOCUMENT

*********************************************************************************
	12-05-2004 Dominic Létourneau
		Création de la procedure pour CRQ-INT-00003
*********************************************************************************/
CREATE PROCEDURE [dbo].[SP_DL_CRQ_Doc] (
	@ConnectID INTEGER, -- Identifiant unique de connection pour logger la suppression
	@DocID INTEGER) -- Identifiant unique du document

AS

BEGIN

	-- Variables de travail
	DECLARE 
		@LogDesc VARCHAR(5000),
		@Err INTEGER,
		@OldDocTemplateID INTEGER, 
		@OldDocOrderConnectID INTEGER, 
		@OldDocOrderTime DATETIME, 

		@OldDocGroup1 VARCHAR(100),
		@OldDocGroup2 VARCHAR(100),
		@OldDocGroup3 VARCHAR(100)

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

	-- Suppression du détail de l'impression du document dans la table CRQ_DocPrinted
	DELETE CRQ_DocPrinted 
	WHERE DocID = @DocID
	
	-- Gestion d'erreur
	SET @Err = @@ERROR

	IF @Err = 0 -- Si aucune erreur, on poursuit le traitement
	BEGIN

		-- Suppression de document
		DELETE CRQ_Doc
		WHERE DocID = @DocID
	
		-- Gestion d'erreur
		SET @Err = @@ERROR
	
		IF @Err = 0 -- La suppression est réussie
		BEGIN -- Gestion du log
			-- Header du log
			SET @LogDesc = dbo.FN_CRQ_FormatLog ('CRQ_Doc', 'DEL', '', @DocID)
			-- Détail du log
			SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('CRQ_Doc', 'DocTemplateID', '', @OldDocTemplateID)
			SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('CRQ_Doc', 'DocOrderConnectID', '', @OldDocOrderConnectID)
			SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('CRQ_Doc', 'DocOrderTime', '', @OldDocOrderTime)
			SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('CRQ_Doc', 'DocGroup1', '', @OldDocGroup1)
			SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('CRQ_Doc', 'DocGroup2', '', @OldDocGroup2)
			SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('CRQ_Doc', 'DocGroup3', '', @OldDocGroup3)
			-- Sauvegarde du log
			EXEC SP_IU_CRQ_Log @ConnectID, 'CRQ_Doc', @DocID, 'D', @LogDesc
		END

	END -- IF @Err = 0

	-- Fin des traitements	
	RETURN @Err -- Si une erreur s'est produite, elle est retournée, sinon 0 (suppression effectuée avec succès)

END

