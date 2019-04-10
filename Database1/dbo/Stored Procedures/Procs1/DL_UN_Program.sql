/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	DL_UN_Program
Description         :	Procédure de suppression de programme.
Valeurs de retours  :	@ReturnValue :
									> 0 :	La suppression a réussie.  La valeur de retour correspond au ProgramID du 
											programme supprimé.
									<= 0:	La suppression a échouée.
										-1 :	« Vous ne pouvez supprimer ce programme car il est utilisé dans des preuves 
												d’inscriptions de paiements de bourses! ».  
										-2 :	« Vous ne pouvez supprimer ce programme car il est utilisé dans des preuves 
												d’inscriptions sur des bénéficiaires! ».  
Note                :	ADX0000730	IA	2005-06-22	Bruno Lapointe		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[DL_UN_Program] (
	@ConnectID INTEGER, -- Identifiant unique de la connexion de l’usager.	
	@ProgramID INTEGER ) -- ID du programme à supprimer.
AS
BEGIN
	DECLARE
		@iResult INTEGER

	SET @iResult = @ProgramID

	IF EXISTS (
		SELECT ScholarshipPmtID
		FROM Un_ScholarshipPmt
		WHERE ProgramID = @ProgramID
		)
		SET @iResult = -1

	IF @iResult > 0
	AND EXISTS (
		SELECT BeneficiaryID
		FROM dbo.Un_Beneficiary 
		WHERE ProgramID = @ProgramID
		)
		SET @iResult = -2

	IF @iResult > 0
	BEGIN
		DELETE
		FROM Un_Program
		WHERE ProgramID = @ProgramID

		IF @@ERROR <> 0
			SET @iResult = -3
	END

	RETURN @iResult
END


