/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	DL_UN_RepException
Description         :	Procédure de suppression d’exception de commissions et/ou de bonis d’affaires.
Valeurs de retours  :	@ReturnValue :
									>0 :	La suppression a réussie.  La valeur de retour correspond au RepExceptionID de
											l’exception supprimée.
									<=0 :	La suppression a échouée.
Note                :	ADX0000723	IA	2005-07-13	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[DL_UN_RepException] (
	@ConnectID INTEGER, -- ID unique de la connexion de l’usager.	
	@RepExceptionID INTEGER ) -- ID unique de l’exception de commissions. 
AS
BEGIN
	DECLARE
		@iResult INTEGER

	SET @iResult = @RepExceptionID

	-- S'assure qu'on ne tente pas de supprimer une exception système.
	IF EXISTS (
		SELECT RE.RepExceptionID
		FROM Un_RepException RE
		JOIN Un_RepExceptionType RET ON RET.RepExceptionTypeID = RE.RepExceptionTypeID
		WHERE RE.RepExceptionID = @RepExceptionID
			AND RET.RepExceptionTypeVisible = 0
		)
		SET @iResult = -1

	-- Effectue la suppression
	IF @iResult > 0
	BEGIN
		DELETE
		FROM Un_RepException
		WHERE RepExceptionID = @RepExceptionID

		IF @@ERROR <> 0
			SET @iResult = -2
	END

	RETURN @iResult
END

