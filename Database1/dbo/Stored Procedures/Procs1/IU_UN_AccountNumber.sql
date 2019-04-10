/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_AccountNumber
Description         :	Procédure de sauvegarde d’ajout ou modification de numéro de compte.
Valeurs de retours  :	@ReturnValue :
									>0 :	La sauvegarde a réussie.  La valeur de retour correspond à l’iAccountNumberID du
											numéro de compte sauvegardé.
									<=0 :	La sauvegarde a échouée.
										-1 :	« La date d’entrée en vigueur doit être supérieure à la date du jour. »
										-2 :	« Il ne peut y avoir plus d’un numéro d’actif à la fois. »
Note                :	ADX0000739	IA	2005-08-03	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_AccountNumber] (
	@ConnectID INTEGER, -- Identifiant unique de la connexion de l’usager.	
	@iAccountNumberID INTEGER, -- ID unique du numéro de compte. (0 = ajout)
	@iAccountID INTEGER, -- ID unique du compte. 
	@dtStart DATETIME, -- 	Date d’entrée en vigueur du numéro de compte.
	@dtEnd DATETIME, -- Date de fin de vigueur du numéro de compte.
	@vcAccountNumber VARCHAR(75) ) -- Numéro de compte.
AS
BEGIN
	IF ISNULL(@dtEnd,0) <= 0
		SET @dtEnd = NULL

	IF EXISTS (
		SELECT iAccountNumberID
		FROM Un_AccountNumber
		WHERE iAccountNumberID = @iAccountNumberID
			AND dtStart <> @dtStart
			AND dtStart < dbo.FN_CRQ_DateNoTime(GETDATE())
		)
		SET @iAccountNumberID = -1
	ELSE IF EXISTS (
		SELECT iAccountNumberID
		FROM Un_AccountNumber
		WHERE iAccountNumberID <> @iAccountNumberID
			AND iAccountID = @iAccountID
			AND(	@dtStart = dtStart
				OR	( @dtStart < dtStart 
					AND( @dtEnd IS NULL 
						OR @dtEnd >= dtStart
						)
					)
				OR	( @dtStart > dtStart 
					AND( dtEnd IS NULL 
						OR dtEnd >= @dtStart
						)
					)
				)
		)
		SET @iAccountNumberID = -2
	ELSE IF @iAccountNumberID = 0
	BEGIN
		INSERT INTO Un_AccountNumber (
			iAccountID,
			dtStart,
			dtEnd,
			vcAccountNumber )
		VALUES (
			@iAccountID,
			@dtStart,
			@dtEnd,
			@vcAccountNumber )

		IF @@ERROR = 0
		BEGIN
			SET @iAccountNumberID = SCOPE_IDENTITY()
			EXECUTE SP_IU_CRQ_Log @ConnectID, 'Un_AccountNumber', @iAccountNumberID, 'I', ''
		END
		ELSE
			SET @iAccountNumberID = -3
	END
	ELSE
	BEGIN
		UPDATE Un_AccountNumber
		SET
			iAccountID = @iAccountID,
			dtStart = @dtStart,
			dtEnd = @dtEnd,
			vcAccountNumber = @vcAccountNumber
		WHERE iAccountNumberID = @iAccountNumberID

		IF @@ERROR = 0
			EXECUTE SP_IU_CRQ_Log @ConnectID, 'Un_AccountNumber', @iAccountNumberID, 'U', ''
		ELSE
			SET @iAccountNumberID = -4
	END

	RETURN @iAccountNumberID
END

