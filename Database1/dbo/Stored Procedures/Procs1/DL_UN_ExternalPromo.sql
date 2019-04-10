
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas
Nom                 :	DL_UN_ExternalPromo
Description         :	Procédure qui renvoi la liste des promoteurs externes
Valeurs de retours  :	Dataset :
							ErrorCode	CHAR(5)			Code d’erreur
							ErrorText	VARCHAR(255)	Texte de l’erreur

							Code	Texte
							DEPR1	Impossible de supprimer le promoteur externe.  Un régime externe associé à ce promoteur a déjà été utilisé lors d’un transfert externe ou interne.
				
Note                :	ADX0001159	IA	2007-02-09	Alain Quirion		Création
*********************************************************************************************************************/
CREATE PROCEDURE dbo.DL_UN_ExternalPromo(
	@ConnectID INTEGER,				-- ID de connexion
	@ExternalPromoID INTEGER)		-- ID du promoteur externe (<=0 Insertion)
AS
BEGIN
	DECLARE @iResult INTEGER,
			@iExecRes INTEGER

	SET @iResult = 1

	BEGIN TRANSACTION	

	IF EXISTS(	SELECT *
				FROM Un_OUT T
				JOIN Un_ExternalPlan P ON P.ExternalPlanID = T.ExternalPlanID
				JOIN Un_ExternalPromo EP ON EP.ExternalPromoID = P.ExternalPromoID
				WHERE EP.ExternalPromoID = @ExternalPromoID)
		OR EXISTS (	SELECT *
					FROM Un_TIN T
					JOIN Un_ExternalPlan P ON P.ExternalPlanID = T.ExternalPlanID
					JOIN Un_ExternalPromo EP ON EP.ExternalPromoID = P.ExternalPromoID
					WHERE EP.ExternalPromoID = @ExternalPromoID)
				
		SET @iResult = -1	-- Un régime externe associé à ce promoteur a déjà été utilisé lors d’un transfert externe ou interne.
	ELSE
	BEGIN
			-- Suppression des plans du promoteur
			DELETE
			FROM Un_ExternalPlan
			WHERE ExternalPromoID = @ExternalPromoID

			IF @@ERROR <> 0
				SET @iResult = -2

			IF @iResult > 0
			BEGIN
				-- Suppression du promoteur externe
				DELETE 
				FROM Un_ExternalPromo
				WHERE ExternalPromoID = @ExternalPromoID

				IF @@ERROR <> 0
					SET @iResult = -3
			END

			-- Suppression de la compagnie et des départements
			IF @iResult > 0
			BEGIN
				EXECUTE @iExecRes = DL_CRQ_Company
										@ConnectID,
										@ExternalPromoID

				IF @iExecRes <= 0
					SET @iResult = -4
			END
	END
	
	IF @iResult > 0
		COMMIT TRANSACTION	
	ELSE
		ROLLBACK TRANSACTION
	
	SELECT 
			cErrorCode = 'DEPR1',
			vcErrorText = 'Impossible de supprimer le promoteur externe.  Un régime externe associé à ce promoteur a déjà été utilisé lors d’un transfert externe ou interne.'
	WHERE @iResult = -1	

	RETURN @iResult
END

