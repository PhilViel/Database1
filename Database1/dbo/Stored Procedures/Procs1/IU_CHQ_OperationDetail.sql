/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom			: IU_CHQ_OperationDetail
Description		: Procédure qui fera la sauvegarde de détail d'opération pour chèques.
Valeurs de retours	 : @ReturnValue :
	> 0 : L’opération a réussie. Retourne le ID de détail de l'opération.
	< 0 : L’opération a échouée.
Note			: ADX0000709	IA	2005-08-09	Bernie MacIntyre			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_CHQ_OperationDetail]
	@bDelete		BIT,
	@iOperationDetailID	INTEGER,
	@iOperationID		INTEGER,
	@fAmount		DECIMAL(18, 4),
	@vcAccount		VARCHAR(75) = NULL,
	@vcDescription		VARCHAR(100) = NULL
AS
BEGIN

	SET NOCOUNT ON            -- Ne pas retourner de rowcount.

	DECLARE @ErrorNumber		INTEGER  -- Gestion des erreurs.
	DECLARE @RowCount		INTEGER  -- Gestion des erreurs
	DECLARE @InTransaction	BIT	-- Pour déterminer si on est déjà dans une transaction

	SELECT @InTransaction = @@TRANCOUNT

	IF (@InTransaction = 0)
		-----------------
		BEGIN TRANSACTION
		-----------------

	IF @iOperationdetailID < 0 BEGIN

		-- Nouvelle enregistrement
		INSERT INTO CHQ_OperationDetail (
			iOperationID,
			fAmount,
			vcAccount,
			vcDescription )
		VALUES (
			@iOperationID,
			@fAmount,
			@vcAccount,
			@vcDescription )

		-- Gestion d'erreur
		-- Utiliser une seule requête si non @@ERROR ou @@ROWCOUNT peut changer
		SELECT @ErrorNumber = @@ERROR, @RowCount = @@ROWCOUNT
		IF @ErrorNumber <> 0 OR @RowCount<> 1 GOTO ERROR_HANDLER

		-- Requête pour avoir le ID de l'opération
		SELECT @iOperationdetailID = SCOPE_IDENTITY()
	END
	ELSE IF @iOperationDetailID > 0
	BEGIN

		UPDATE CHQ_OperationDetail
		SET
			iOperationID = @iOperationID,
			fAmount = @fAmount,
			vcAccount = @vcAccount,
			vcDescription = @vcDescription
		WHERE iOperationDetailID = @iOperationDetailID

		-- Gestion d'erreur
		-- Utiliser une seule requête si non @@ERROR ou @@ROWCOUNT peut changer
		SELECT @ErrorNumber = @@ERROR, @RowCount = @@ROWCOUNT
		IF @ErrorNumber <> 0 OR @RowCount<> 1 GOTO ERROR_HANDLER
	END
	ELSE IF @bDelete = 1
	BEGIN
		DELETE CHQ_OperationDetail
		WHERE iOperationDetailID = @iOperationDetailID

		-- Gestion d'erreur
		-- Utiliser une seule requête si non @@ERROR ou @@ROWCOUNT peut changer
		SELECT @ErrorNumber = @@ERROR, @RowCount = @@ROWCOUNT
		IF @ErrorNumber <> 0 OR @RowCount<> 1 GOTO ERROR_HANDLER

	END

	IF (@@TRANCOUNT = 1) AND (@InTransaction = 0)
		------------------
		COMMIT TRANSACTION
		------------------

	-- Retourner le ID de détail de l'opération
	RETURN @iOperationdetailID

-- Gestion d'erreur
ERROR_HANDLER:

	IF (@@TRANCOUNT > 0) AND (@InTransaction = 0)BEGIN
		ROLLBACK TRANSACTION
	END

	RETURN -(@ErrorNumber)

END
