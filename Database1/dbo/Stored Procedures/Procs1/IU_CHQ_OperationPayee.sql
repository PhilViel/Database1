/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom			: IU_CHQ_OperationPayee
Description		: Procédure qui fera la sauvegarde de destinataire d'un opération pour chèques.
Valeurs de retours	 : @ReturnValue :
	> 0 : L’opération a réussie. Retourne le ID de destinataire de l'opération.
	< 0 : L’opération a échouée.
Note			: ADX0000709	IA	2005-08-09	Bernie MacIntyre			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_CHQ_OperationPayee]
	@bDelete			BIT,
	@iOperationPayeeID		INTEGER,
	@iPayeeID			INTEGER,
	@iOperationID			INTEGER,
	@dtCreated			DATETIME,
	@iPayeeChangeAccepted	INTEGER,
	@vcReason			VARCHAR(100) = NULL
AS
BEGIN

	SET NOCOUNT ON            -- Ne pas retourner de rowcount.

	DECLARE @ErrorNumber		INTEGER  -- Gestion des erreurs.
	DECLARE @RowCount		INTEGER  -- Gestion des erreurs
	DECLARE @InTransaction	BIT	-- Pour déterminer si on est déjà dans une transaction

	SELECT @InTransaction = @@TRANCOUNT

	IF (@@TRANCOUNT = 0) AND (@InTransaction = 0)
		-----------------
		BEGIN TRANSACTION
		-----------------

	IF @iOperationPayeeID < 0
	BEGIN
		-- Nouvelle enregistrement
		INSERT INTO CHQ_OperationPayee (
			iPayeeID,
			iOperationID,
			dtCreated,
			vcReason,
			iPayeeChangeAccepted )
		VALUES (
			@iPayeeID,
			@iOperationID,
			@dtCreated,
			@vcReason,
			@iPayeeChangeAccepted )

		-- Gestion d'erreur
		-- Utiliser une seule requête si non @@ERROR ou @@ROWCOUNT peut changer
		SELECT @ErrorNumber = @@ERROR, @RowCount = @@ROWCOUNT
		IF @ErrorNumber <> 0 OR @RowCount<> 1 GOTO ERROR_HANDLER

		-- Requête pour avoir le ID de l'opération
		SELECT @iOperationPayeeID = SCOPE_IDENTITY()
	END
	ELSE IF @iOperationPayeeID > 0
	BEGIN
		UPDATE CHQ_OperationPayee
		SET
			iPayeeID = @iPayeeID,
			iOperationID = @iOperationID,
			dtCreated = @dtCreated,
			vcReason = @vcReason,
			iPayeeChangeAccepted = @iPayeeChangeAccepted
		WHERE iOperationPayeeID = @iOperationPayeeID

		-- Gestion d'erreur
		-- Utiliser une seule requête si non @@ERROR ou @@ROWCOUNT peut changer
		SELECT @ErrorNumber = @@ERROR, @RowCount = @@ROWCOUNT
		IF @ErrorNumber <> 0 OR @RowCount<> 1 GOTO ERROR_HANDLER
	END
	ELSE IF @bDelete = 1
	BEGIN
		DELETE CHQ_OperationPayee
		WHERE iOperationPayeeID = @iOperationPayeeID

		-- Gestion d'erreur
		-- Utiliser une seule requête si non @@ERROR ou @@ROWCOUNT peut changer
		SELECT @ErrorNumber = @@ERROR, @RowCount = @@ROWCOUNT
		IF @ErrorNumber <> 0 OR @RowCount<> 1 GOTO ERROR_HANDLER
	END

	IF (@@TRANCOUNT = 1) AND (@InTransaction = 0)
		------------------
		COMMIT TRANSACTION
		------------------

	-- Retourner le ID de destinataire de l'opération
	RETURN @iOperationPayeeID

-- Gestion d'erreur
ERROR_HANDLER:

	IF (@@TRANCOUNT > 0) AND (@InTransaction = 0)BEGIN
		--------------------
		ROLLBACK TRANSACTION
		--------------------
	END

	RETURN -(@ErrorNumber)

END
