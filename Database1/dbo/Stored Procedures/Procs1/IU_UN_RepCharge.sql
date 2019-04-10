/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_RepCharge
Description         :	Procédure de sauvegarde d’ajout ou d’édition d’ajustements/retenus.
Valeurs de retours  :	@ReturnValue :
									>0 :	La sauvegarde a réussie.  La valeur de retour correspond au RepChargeID de
											l’ajustement/retenu sauvegardée.
									<=0 :	La sauvegarde a échouée.
Note                :	ADX0000734	IA	2005-07-15	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_RepCharge] (
	@ConnectID INTEGER, -- ID unique de la connexion de l’usager.	
	@RepChargeID INTEGER, -- ID unique de l’ajustement/retenu. (0= ajout)
	@RepID INTEGER, -- ID du représentant.
	@RepChargeTypeID CHAR(3), -- ID du type de charge.
	@RepChargeDesc VARCHAR(255), -- Note indiquant la raison de l’ajustement ou de la retenu.
	@RepChargeAmount MONEY, -- Montant de l’ajustement(+) ou de la retenu(-)
	@RepTreatmentID INTEGER, -- ID unique du traitement de commissions dans lequel l'ajustement ou la retenu a été traité. Null = pas encore traité.
	@RepChargeDate DATETIME ) -- Date à laquelle l'ajustement ou la retenu a eu lieu.
AS
BEGIN
	IF ISNULL(@RepTreatmentID,0) <= 0
		SET @RepTreatmentID = NULL

	IF @RepChargeID = 0
	BEGIN
		INSERT INTO Un_RepCharge (
			RepID, -- ID du représentant.
			RepChargeTypeID, -- ID du type de charge.
			RepChargeDesc, -- Note indiquant la raison de l’ajustement ou de la retenu.
			RepChargeAmount, -- Montant de l’ajustement(+) ou de la retenu(-)
			RepTreatmentID, -- ID unique du traitement de commissions dans lequel l'ajustement ou la retenu a été traité. Null = pas encore traité.
			RepChargeDate ) -- Date à laquelle l'ajustement ou la retenu a eu lieu.
		VALUES (
			@RepID,
			@RepChargeTypeID,
			@RepChargeDesc,
			@RepChargeAmount,
			@RepTreatmentID,
			@RepChargeDate )

		IF @@ERROR = 0
		BEGIN
			SET @RepChargeID = SCOPE_IDENTITY()
			EXECUTE SP_IU_CRQ_Log @ConnectID, 'Un_RepCharge', @RepChargeID, 'I', ''
		END
		ELSE
			SET @RepChargeID = -1
	END
	ELSE
	BEGIN
		UPDATE Un_RepCharge
		SET
			RepID = @RepID, -- ID du représentant.
			RepChargeTypeID = @RepChargeTypeID, -- ID du type de charge.
			RepChargeDesc = @RepChargeDesc, -- Note indiquant la raison de l’ajustement ou de la retenu.
			RepChargeAmount = @RepChargeAmount, -- Montant de l’ajustement(+) ou de la retenu(-)
			RepTreatmentID = @RepTreatmentID, -- ID unique du traitement de commissions dans lequel l'ajustement ou la retenu a été traité. Null = pas encore traité.
			RepChargeDate = @RepChargeDate -- Date à laquelle l'ajustement ou la retenu a eu lieu.
		WHERE RepChargeID = @RepChargeID

		IF @@ERROR = 0
			EXECUTE SP_IU_CRQ_Log @ConnectID, 'Un_RepCharge', @RepChargeID, 'U', ''
		ELSE
			SET @RepChargeID = -2
	END

	RETURN @RepChargeID
END

