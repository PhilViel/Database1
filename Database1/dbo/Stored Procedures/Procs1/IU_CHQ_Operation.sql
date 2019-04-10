/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom			: IU_CHQ_Operation
Description		: Procédure qui fera la sauvegarde d'opération pour chèques.
Valeurs de retours	 : @ReturnValue :
	> 0 : L’opération a réussie. Retourne le ID de l'opération.
	< 0 : L’opération a échouée.
Note			: ADX0000709	IA	2005-08-09	Bernie MacIntyre			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_CHQ_Operation]
	@bDelete	BIT,
	@iOperationID	INTEGER,
	@bStatus	BIT = NULL,
	@iConnectID	INTEGER = NULL,
	@dtOperation	DATETIME,
	@vcDescription	VARCHAR(100) = NULL,
	@vcRefType	VARCHAR(10) = NULL,
	@vcAccount	VARCHAR(75) = NULL
AS
BEGIN

	SET NOCOUNT ON            -- Ne pas retourner de rowcount.

	DECLARE @ErrorNumber	INTEGER	-- Gestion des erreurs.
	DECLARE @RowCount	INTEGER	-- Gestion des erreurs
	DECLARE @InTransaction	BIT	-- Pour déterminer si on est déjà dans une transaction

	SELECT @InTransaction = @@TRANCOUNT

	IF (@InTransaction = 0)
		-----------------
		BEGIN TRANSACTION
		-----------------

	IF (@iOperationID < 0) AND (@bDelete = 0) BEGIN

		-- Nouvelle enregistrement
		INSERT INTO CHQ_Operation (
			bStatus,
			iConnectID,
			dtOperation,
			vcDescription,
			vcRefType,
			vcAccount )
		VALUES (
			@bStatus,
			@iConnectID,
			@dtOperation,
			@vcDescription,
			@vcRefType,
			@vcAccount )

		-- Gestion d'erreur
		-- Utiliser une seule requête si non @@ERROR ou @@ROWCOUNT peut changer
		SELECT 
			@ErrorNumber = @@ERROR,
			@RowCount = @@ROWCOUNT
		IF @ErrorNumber <> 0 OR @RowCount<> 1 GOTO ERROR_HANDLER

		-- Requête pour avoir le ID de l'opération
		SELECT @iOperationID = SCOPE_IDENTITY()
	END
	ELSE IF (@iOperationID > 0) AND (@bDelete = 0) 
	BEGIN
		UPDATE CHQ_Operation
		SET
			bStatus = @bStatus,
			iConnectID = @iConnectID,
			dtOperation = @dtOperation,
			vcDescription = @vcDescription,
			vcRefType = @vcRefType,
			vcAccount = @vcAccount
		WHERE iOperationID = @iOperationID

		-- Gestion d'erreur
		-- Utiliser une seule requête si non @@ERROR ou @@ROWCOUNT peut changer
		SELECT
			@ErrorNumber = @@ERROR,
			@RowCount = @@ROWCOUNT
		IF @ErrorNumber <> 0 OR @RowCount<> 1 GOTO ERROR_HANDLER
	END
	ELSE IF (@iOperationID > 0) AND (@bDelete = 1)
	BEGIN
		DELETE CHQ_Operation
		WHERE iOperationID = @iOperationID

		-- Gestion d'erreur
		-- Utiliser une seule requête si non @@ERROR ou @@ROWCOUNT peut changer
		SELECT
			@ErrorNumber = @@ERROR,
			@RowCount = @@ROWCOUNT
		IF @ErrorNumber <> 0 OR @RowCount <> 1 GOTO ERROR_HANDLER
	END

	IF (@@TRANCOUNT = 1) AND (@InTransaction = 0)
		------------------
		COMMIT TRANSACTION
		------------------

	-- Retourner le ID de l'opération
	RETURN @iOperationID

-- Gestion d'erreur
ERROR_HANDLER:

	IF (@@TRANCOUNT > 0) AND (@InTransaction = 0) BEGIN
		--------------------
		ROLLBACK TRANSACTION
		--------------------
	END

	RETURN -(@ErrorNumber)

END
