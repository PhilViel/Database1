/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	IU_CHQ_CancelCheck
Description         :	Procédure qui fera l'annulation d'un chèque.
Valeurs de retours  :	@ReturnValue :
									= 0 : L’opération a réussie.
									< 0 : L’opération a échouée.
Note                :	ADX0000710	IA	2005-10-05	Bernie MacIntyre	Création
			ADX0001179	IA	2006-10-25	Alain Quirion		Modification : Ajout et gestion du paramètre @iRecipientID
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_CHQ_CancelCheck] (
	@iConnectID INTEGER, 		-- ID de connexion de l'usager.
	@iCheckID INTEGER,		-- ID du chèque qu'on veut annuler.
	@vcReason VARCHAR(50),		-- La raison pour laquelle on annule le chèque.
	@iRecipientID INTEGER = 0)	-- ID du nouveau destinataire
AS BEGIN

	SET NOCOUNT ON

	DECLARE
		@iResult INTEGER,
		@vcFirstName VARCHAR(35),
		@vcLastName VARCHAR(50),
		@vcAddress VARCHAR(75),
		@vcCity VARCHAR(100),
		@vcCountry VARCHAR(4),
		@vcZipCode VARCHAR(10),
		@vcStateName VARCHAR(75)

	-- Faire les validations
	-----------------
	BEGIN TRANSACTION
	-----------------

	SET @iResult = 1

	UPDATE CHQ_Check
	SET iCheckStatusID = 5		--Annulé
	WHERE iCheckID = @iCheckID	

	IF @iRecipientID > 0
	BEGIN
		IF NOT EXISTS(SELECT * FROM CHQ_Payee WHERE iPayeeID = @iRecipientID)			
			INSERT INTO CHQ_Payee(iPayeeID)
			VALUES(@iRecipientID)

		DECLARE @Today DATETIME
		
		SET @Today = GETDATE()

		INSERT INTO CHQ_OperationPayee(iPayeeID, iOperationID, iPayeeChangeAccepted, dtCreated, vcReason)
		SELECT DISTINCT
			@iRecipientID,
			O.iOperationID,
			0,
			@Today,
			''
		FROM CHQ_Operation O
		JOIN CHQ_OperationDetail OD ON OD.iOperationID = O.iOperationID
		JOIN CHQ_CheckOperationDetail COD ON COD.iOperationDetailID = OD.iOperationDetailID
		JOIN CHQ_Check C ON C.iCheckID = COD.iCheckID
		WHERE C.iCheckID = @iCheckID			
	END

	IF @@ERROR <> 0
		SET @iResult = -1

	IF @iResult > 0
	BEGIN		

		INSERT INTO CHQ_CheckHistory (
				iCheckID,
				iCheckStatusID,
				dtHistory,
				iConnectID,
				vcReason )
			SELECT
				@iCheckID,
				5,
				GETDATE(),
				@iConnectID,
				@vcReason	

		IF @@ERROR <> 0
			SET @iResult = -2
	END

	IF @iResult > 0
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
		--------------------

	RETURN(@iResult)

END
