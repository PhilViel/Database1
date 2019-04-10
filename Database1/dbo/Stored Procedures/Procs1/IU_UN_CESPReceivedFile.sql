/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_CESPReceivedFile
Description         :	Procédure de sauvegarde d'ajout ou modification de fichier de retour du PCEE
Valeurs de retours  :	Dataset :
									iCESPSendFileID		INTEGER		ID du fichier d’envoi au PCEE.
									vcCESPSendFile			VARCHAR(75)	Nom du fichier d’envoi au PCEE.
									dtCESPSendFile			DATETIME		Date d’envoi du fichier au PCEE.
									iCESPReceiveFileID	INTEGER		ID du fichier de retour correspondant à ce fichier d’envoi.
Note                :	ADX0000811	IA	2006-04-17	Bruno Lapointe	Création
*********************************************************************************************************************/
CREATE PROC [dbo].[IU_UN_CESPReceivedFile] (
	@iCESPReceiveFileID INTEGER, -- ID unique du fichier reçu de la SCÉÉ (0=nouveau)
	@OperID INTEGER, -- ID unique de l'opération qui contient la subvention reçue
	@dtPeriodStart DATETIME, -- Début de la période de transaction couverte
	@dtPeriodEnd DATETIME, -- Fin de la période de transaction couverte
	@fSumary MONEY, -- Montant sommaire
	@fPayment MONEY,
	@vcPaymentReqID VARCHAR(10))
AS
BEGIN
	DECLARE
		@iResult INTEGER

	IF @iCESPReceiveFileID = 0
	BEGIN
		INSERT INTO Un_CESPReceiveFile (
			OperID,
			dtRead,
			dtPeriodStart,
			dtPeriodEnd,
			fSumary,
			fPayment,
			vcPaymentReqID)
		VALUES (
			@OperID,
			GETDATE(),
			@dtPeriodStart,
			@dtPeriodEnd,
			@fSumary,
			@fPayment,
			@vcPaymentReqID)

		IF @@ERROR = 0
			SET @iResult = IDENT_CURRENT('Un_CESPReceiveFile')
		ELSE
			SET @iResult = 0
	END
	ELSE
	BEGIN
		UPDATE Un_CESPReceiveFile SET
			OperID = @OperID,
			dtPeriodStart = @dtPeriodStart,
			dtPeriodEnd = @dtPeriodEnd,
			fSumary = @fSumary,
			fPayment = @fPayment,
			vcPaymentReqID = @vcPaymentReqID
		WHERE iCESPReceiveFileID = @iCESPReceiveFileID
			
		IF @@ERROR = 0
			SET @iResult = @iCESPReceiveFileID
		ELSE
			SET @iResult = 0
	END

	RETURN @iResult
END

