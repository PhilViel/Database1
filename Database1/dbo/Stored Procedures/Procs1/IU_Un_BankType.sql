/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_Un_BankType
Description         :	Procédure de sauvegarde d’ajout et modification d’institutions financières.
Valeurs de retours  :	@ReturnValue :
									>0 :	La sauvegarde a réussie.  La valeur de retour correspond au BankTypeID de
											l’institution financière sauvegardée.
									<=0 :	La sauvegarde a échouée.
Note                :	ADX0000721	IA	2005-07-08	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_Un_BankType] (
	@ConnectID INTEGER, -- Identifiant unique de la connexion de l’usager.	
	@BankTypeID INTEGER, -- ID unique de l'institution financière à sauvegarder, 0 pour ajouter.
	@BankTypeCode VARCHAR(75), -- Code de l'institution financière.
	@BankTypeName VARCHAR(75) ) -- Nom de l'institution financière.
AS
BEGIN
	IF @BankTypeID = 0
	BEGIN
		INSERT INTO Mo_BankType (
			BankTypeCode,
			BankTypeName )
		VALUES (
			@BankTypeCode,
			@BankTypeName )

		IF @@ERROR = 0
		BEGIN
			SET @BankTypeID = SCOPE_IDENTITY()
			EXECUTE SP_IU_CRQ_Log @ConnectID, 'Mo_BankType', @BankTypeID, 'I', ''
		END
		ELSE
			SET @BankTypeID = -1
	END
	ELSE
	BEGIN
		UPDATE Mo_BankType
		SET
			BankTypeCode = @BankTypeCode,
			BankTypeName = @BankTypeName
		WHERE BankTypeID = @BankTypeID

		IF @@ERROR = 0
			EXECUTE SP_IU_CRQ_Log @ConnectID, 'Mo_BankType', @BankTypeID, 'U', ''
		ELSE
			SET @BankTypeID = -2
	END

	RETURN @BankTypeID
END

