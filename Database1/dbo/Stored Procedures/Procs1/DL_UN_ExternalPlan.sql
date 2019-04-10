
/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 			:	DL_UN_ExternalPlan
Description 		:	Procédure qui supprime un régime externe
Valeurs de retour	:	Dataset :
							ErrorCode	CHAR(5)			Code d’erreur
							ErrorText	VARCHAR(255)	Texte de l’erreur

						Code	Texte
						DEPL1	Impossible de supprimer le régime externe.  Ce régime a déjà été utilisé pour un transfert externe ou interne

Note			:		ADX0001159	IA	2007-02-12	Alain Quirion		Création
*************************************************************************************************/
CREATE PROCEDURE dbo.DL_UN_ExternalPlan (
	@ExternalPlanID INTEGER) -- ID du régime externe

AS
BEGIN
	DECLARE @ErrTable TABLE(
		cErrorCode CHAR(5),
		vcErrorText VARCHAR(255))

	DECLARE @iResult INTEGER
	
	SET @iResult = 1
		
	IF @ExternalPlanID > 0
	BEGIN
		IF EXISTS ( SELECT *
					FROM Un_OUT
					WHERE ExternalPlanID = @ExternalPlanID)			-- Utilisé dans un OUT
			OR EXISTS ( SELECT *
						FROM Un_TIN
						WHERE ExternalPlanID = @ExternalPlanID)		-- Utilisé dans un TIN
		BEGIN
			INSERT INTO @ErrTable
				SELECT
						'DEPL1',
						'Impossible de supprimer le régime externe.  Ce régime a déjà été utilisé pour un transfert externe ou interne.'		

			SET @iResult = -1		
		END
		ELSE
		BEGIN
			--Suppression du régime
			DELETE 
			FROM Un_ExternalPlan
			WHERE ExternalPlanID = @ExternalPlanID

			IF @@ERROR <> 0
				SET @iResult = -2			
		END		
	END
		
	SELECT *
	FROM @ErrTable

	RETURN @iResult
END

