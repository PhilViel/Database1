/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	DL_CRQ_DocBatch
Description         :	Suppression de documents
Valeurs de retours  :	@ReturnValue :
									> 0 : La suppression a réussi.
									<= 0 : La suppression a échoué.
Note                :	ADX0000778 IA	2006-01-27	Bruno Lapointe		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[DL_CRQ_DocBatch] (
	@ConnectID INTEGER, -- ID de connexion de l’usager.
	@iBlobID INTEGER ) -- ID unique du blob (CRI_Blob) qui contient les DocID séparé par des virgules.
AS
BEGIN
	DECLARE
		@iResult INTEGER

	SET @iResult = 1

	CREATE TABLE #tDocToDel (
		iID INTEGER,
		iDocID INTEGER )

	INSERT INTO #tDocToDel
		SELECT *
		FROM dbo.FN_CRI_BlobToIntegerTable(@iBlobID)

	-----------------
	BEGIN TRANSACTION 
	-----------------

	-- Suppression  de l'historique d'impression.
	DELETE CRQ_DocPrinted
	FROM CRQ_DocPrinted
	JOIN #tDocToDel D ON D.iDocID = CRQ_DocPrinted.DocID

	IF @@ERROR <> 0
		SET @iResult = -1

	IF @iResult > 0
	BEGIN
		-- Suppression du lien avec l'objet (Souscripteur, Convention, Bénéficiaire, Groupe d'unités, etc.).
		DELETE CRQ_DocLink
		FROM CRQ_DocLink
		JOIN #tDocToDel D ON D.iDocID = CRQ_DocLink.DocID

		IF @@ERROR <> 0
			SET @iResult = -2
	END

	IF @iResult > 0
	BEGIN
		-- Suppression du document.
		DELETE CRQ_Doc
		FROM CRQ_Doc
		JOIN #tDocToDel D ON D.iDocID = CRQ_Doc.DocID

		IF @@ERROR <> 0
			SET @iResult = -3
	END

	IF @iResult > 0
	BEGIN
		-- Suppression du blob.
		DELETE 
		FROM CRI_Blob
		WHERE iBlobID = @iBlobID

		IF @@ERROR <> 0
			SET @iResult = -4
	END

	IF @iResult > 0
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
		--------------------

	RETURN @iResult
END
