/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_RepException
Description         :	Procédure de sauvegarde d’ajout ou d’édition d’exception de commissions et/ou de bonis
								d’affaires.
Valeurs de retours  :	@ReturnValue :
									>0 :	La sauvegarde a réussie.  La valeur de retour correspond au RepExceptionID de
											l’exception sauvegardée.
									<=0 :	La sauvegarde a échouée.
Note                :	ADX0000723	IA	2005-07-13	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_RepException] (
	@ConnectID INTEGER, -- ID unique de la connexion de l’usager.	
	@RepExceptionID INTEGER, -- ID unique de l’exception de commissions. (0= ajout)
	@RepID INTEGER, -- ID du représentant.
	@UnitID INTEGER, -- ID du groupe d’unités.
	@RepLevelID INTEGER, -- ID du niveau du représentant.
	@RepExceptionTypeID CHAR(3), -- Chaîne unique de 3 caractères donnant le type de l'exception.  
	@RepExceptionAmount MONEY, -- Montant de l’exception
	@RepExceptionDate DATETIME ) -- Date d’entrée en vigueur de l’exception.
AS
BEGIN
	IF @RepExceptionID = 0
	BEGIN
		INSERT INTO Un_RepException (
			RepID,
			UnitID,
			RepLevelID,
			RepExceptionTypeID,
			RepExceptionAmount,
			RepExceptionDate )
		VALUES (
			@RepID,
			@UnitID,
			@RepLevelID,
			@RepExceptionTypeID,
			@RepExceptionAmount,
			@RepExceptionDate )

		IF @@ERROR = 0
		BEGIN
			SET @RepExceptionID = SCOPE_IDENTITY()
			EXECUTE SP_IU_CRQ_Log @ConnectID, 'Un_RepException', @RepExceptionID, 'I', ''
		END
		ELSE
			SET @RepExceptionID = -1
	END
	ELSE
	BEGIN
		UPDATE Un_RepException
		SET
			RepID = @RepID,
			UnitID = @UnitID,
			RepLevelID = @RepLevelID,
			RepExceptionTypeID = @RepExceptionTypeID,
			RepExceptionAmount = @RepExceptionAmount,
			RepExceptionDate = @RepExceptionDate 
		WHERE RepExceptionID = @RepExceptionID

		IF @@ERROR = 0
			EXECUTE SP_IU_CRQ_Log @ConnectID, 'Un_RepException', @RepExceptionID, 'U', ''
		ELSE
			SET @RepExceptionID = -2
	END

	RETURN @RepExceptionID
END

