/****************************************************************************************************

	PROCEDURE DE SUPPRESSION DE MODÈLES DE DOCUMENTS

*********************************************************************************
	12-05-2004 Dominic Létourneau
		Création de la procedure pour CRQ-INT-00003
*********************************************************************************/
CREATE PROCEDURE [dbo].[SP_DL_CRQ_DocTemplate] (
	@ConnectID INTEGER, -- Identifiant unique de connection
	@DocTemplateID INTEGER) -- Identifiant unique du modèle de documents

AS

BEGIN

	-- Variables de travail
	DECLARE 
		@LogDesc VARCHAR(5000),
		@Err INTEGER,		
		@OldConnectID INTEGER,
		@OldDocTemplateID INTEGER,
		@OldDocTypeID INTEGER,
		@OldLangID VARCHAR(3),
		@OldDocTemplateTime DATETIME

	-- Suppression du modèle de documents
	DELETE CRQ_DocTemplate
	WHERE DocTemplateID = @DocTemplateID
	
	-- Gestion d'erreurs
	SET @Err = @@ERROR

	IF @Err = 0 -- La suppression est réussie
	BEGIN -- Gestion du log
		-- Header du log
		SET @LogDesc = dbo.FN_CRQ_FormatLog ('CRQ_DocTemplate', 'DEL', '', @DocTemplateID)
		-- Détail du log
		SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('CRQ_DocTemplate', 'ConnectID', '', @OldConnectID)
		SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('CRQ_DocTemplate', 'DocDocTemplateID', '', @OldDocTemplateID)
		SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('CRQ_DocTemplate', 'DocTypeID', '', @OldDocTypeID)
		SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('CRQ_DocTemplate', 'LangID', '', @OldLangID)
		SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('CRQ_DocTemplate', 'DocTemplateTime', '', @OldDocTemplateTime)
		-- Sauvegarde du log
		EXEC SP_IU_CRQ_Log @ConnectID, 'CRQ_DocTemplate', @DocTemplateID, 'D', @LogDesc
	END

	-- Fin des traitements	
	RETURN @Err -- Si une erreur s'est produite, elle est retournée, sinon 0 (suppression effectuée avec succès)

END

