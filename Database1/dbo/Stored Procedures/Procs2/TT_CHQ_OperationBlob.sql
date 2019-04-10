/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom			: TT_CHQ_OperationBlob
Description		: Procédure qui fera la sauvegarde d'opération, des détails de l'opération et du
			destinataire de l'opération pour chèques.
Valeurs de retours	 : @ReturnValue :
	> 0 : L’opération a réussie. Retourne le ID de l'opération.
	< 0 : L’opération a échouée.
Note			: ADX0000709	IA	2005-08-09	Bernie MacIntyre			Création
***************************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_CHQ_OperationBlob]
	@iConnectID INTEGER,  -- ID de connexion de l'usager
	@iBlobID INTEGER	-- ID du blob qui contient l'opération
AS
BEGIN

	DECLARE @iSPID INT
	SELECT @iSPID = @@SPID

	-- Remplir la table avec les objets (en verticale)
	INSERT INTO CRI_ObjectOfBlob (
		iSPID,
		iObjectID,
		vcClassName,
		vcFieldName,
		txValue )
	SELECT
		@iSPID,
		iObjectID,
		vcClassName,
		vcFieldName,
		txValue
	FROM dbo.FN_CRI_DecodeBlob(@iBlobID)

	-- Tables temporaires de CHQ_Operation, CHQ_OperationDetails et CHQ_OperationPayee
	CREATE TABLE #tCHQ_Operation (
		bDelete BIT,
		iOperationID INT,
		bStatus BIT,
		dtOperation DATETIME,
		iConnectID INTEGER,
		vcAccount VARCHAR(50),
		vcDescription VARCHAR(50),
		vcRefType VARCHAR(10) )

	CREATE TABLE #tCHQ_OperationDetail (
		bDelete BIT,
		iOperationDetailID INT,
		fAmount DECIMAL(18, 4),
		iOperationID INT,
		vcAccount VARCHAR(50),
		vcDescription VARCHAR(50) )

	CREATE TABLE #tCHQ_OperationPayee (
		bDelete BIT,
		iOperationPayeeID INT,
		dtCreated DATETIME,
		iOperationID INT,
		iPayeeChangeAccepted INT,
		iPayeeID INT,
		vcReason VARCHAR(255) )

	-- Ramène les objets (en horizontale)
	INSERT INTO #tCHQ_Operation (
		bDelete,
		iOperationID,
		bStatus,
		dtOperation,
		iConnectID,
		vcAccount,
		vcDescription,
		vcRefType )
	SELECT
		bDelete,
		iOperationID,
		bStatus,
		dtOperation,
		iConnectID,
		vcAccount,
		vcDescription,
		vcRefType
	FROM dbo.FN_CHQ_Operation(@iSPID)

	INSERT INTO #tCHQ_OperationDetail (
		bDelete,
		iOperationDetailID,
		fAmount,
		iOperationID,
		vcAccount,
		vcDescription )
	SELECT
		bDelete,
		iOperationDetailID,
		fAmount,
		iOperationID,
		vcAccount,
		vcDescription
	FROM dbo.FN_CHQ_OperationDetail(@iSPID)

	INSERT INTO #tCHQ_OperationPayee (
		bDelete,
		iOperationPayeeID,
		dtCreated,
		iOperationID,
		iPayeeChangeAccepted,
		iPayeeID,
		vcReason )
	SELECT
		bDelete,
		iOperationPayeeID,
		dtCreated,
		iOperationID,
		iPayeeChangeAccepted,
		iPayeeID,
		vcReason
	FROM dbo.FN_CHQ_OperationPayee(@iSPID)

	DELETE FROM CRI_ObjectOfBlob
	WHERE iSPID = @iSPID

	-- Sauvegard de l'opération
	DECLARE @bDelete BIT,
		@iOperationID INT,
		@bStatus BIT,
		@dtOperation DATETIME,
		@vcDescription VARCHAR(100),
		@vcRefType VARCHAR(10),
		@vcAccount VARCHAR(75)

	-- On ne travaille qu'avec un master à la fois
	-- TODO: Ajouter test pour le nombre n'enregistrements dans #tCHQ_Operation

	-- Remplir variables avec l'opération
	SELECT @bDelete = bDelete,
		@iOperationID = iOperationID,
		@bStatus = bStatus,
		@iConnectID = iConnectID,
		@dtOperation = dtOperation,
		@vcDescription = vcDescription,
		@vcRefType = vcRefType,
		@vcAccount = vcAccount
	FROM #tCHQ_Operation

	IF @@TRANCOUNT = 0
		BEGIN TRANSACTION

	EXEC @iOperationID = IU_CHQ_Operation
		@bDelete,
		@iOperationID,
		@bStatus,
		@iConnectID,
		@dtOperation,
		@vcDescription,
		@vcRefType,
		@vcAccount

	IF @@ERROR <> 0 OR @iOperationID < 0 BEGIN
		GOTO ERROR_HANDLER
	END

	DECLARE @iOperationDetailID INTEGER,
		@fAmount decimal(18,4)

	-- Loop avec curseur
	-- Sauvegarde des détails de l'opération
	DECLARE crOperationDetails CURSOR FAST_FORWARD FOR 
	SELECT bDelete, iOperationDetailID, fAmount, vcAccount, vcDescription
	FROM #tCHQ_OperationDetail

	OPEN crOperationDetails

	FETCH NEXT FROM crOperationDetails
	INTO @bDelete, @iOperationDetailID, @fAmount, @vcAccount, @vcDescription

	WHILE @@FETCH_STATUS = 0
	BEGIN

		EXEC @iOperationDetailID = IU_CHQ_OperationDetail
			@bDelete,
			@iOperationDetailID,
			@iOperationID,
			@fAmount,
			@vcAccount,
			@vcDescription

		IF @@ERROR <> 0 OR @iOperationDetailID < 0 BEGIN
			GOTO ERROR_HANDLER
		END

		FETCH NEXT FROM crOperationDetails
		INTO @bDelete, @iOperationDetailID, @fAmount, @vcAccount, @vcDescription
		
	END

	CLOSE crOperationDetails
	DEALLOCATE crOperationDetails

	DECLARE @iOperationPayeeID INTEGER,
		@iPayeeID INTEGER,
		@iPayeeChangeAccepted INTEGER,
		@dtCreated DATETIME,
		@vcReason VARCHAR(255)

	-- Loop avec curseur
	-- Sauvegard de destinataire
	DECLARE crOperationPayee CURSOR FAST_FORWARD FOR 
	SELECT bDelete, iOperationPayeeID, iPayeeID, iPayeeChangeAccepted, dtCreated, vcReason
	FROM #tCHQ_OperationPayee

	OPEN crOperationPayee

	FETCH NEXT FROM crOperationPayee
	INTO @bDelete, @iOperationPayeeID, @iPayeeID, @iPayeeChangeAccepted, @dtCreated, @vcReason

	WHILE @@FETCH_STATUS = 0
	BEGIN

		EXEC @iOperationPayeeID = IU_CHQ_OperationPayee
			@bDelete,
			@iOperationPayeeID,
			@iPayeeID,
			@iOperationID,
			@iPayeeChangeAccepted,
			@dtCreated,
			@vcReason

		IF @@ERROR <> 0 OR @iOperationPayeeID < 0 BEGIN
			GOTO ERROR_HANDLER
		END

		FETCH NEXT FROM crOperationPayee
		INTO @bDelete, @iOperationPayeeID, @iPayeeID, @iPayeeChangeAccepted, @dtCreated, @vcReason
		
	END

	CLOSE crOperationPayee
	DEALLOCATE crOperationPayee

	-- Commit de transaction et on retourne le ID de l'opération
	IF @@TRANCOUNT = 1
		COMMIT TRANSACTION

	RETURN @iOperationID

ERROR_HANDLER:
	IF @@TRANCOUNT > 0 BEGIN
		ROLLBACK TRANSACTION
	END

	RETURN -(@iOperationID)

END
