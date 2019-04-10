/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	DL_UN_College
Description         :	Procédure de suppression d’établissement d’enseignement.
Valeurs de retours  :	@ReturnValue :
									> 0 : La suppression a réussie.  La valeur de retour correspond au CollegeID de 
											l’établissement d’enseignement supprimé.
									<= 0: La suppression a échouée.
										-1 :	« Vous ne pouvez supprimer cet établissement d’enseignement car il est utilisé 
												dans des preuves d’inscriptions de paiements de bourses! ».  
										-2 :	« Vous ne pouvez supprimer cet établissement d’enseignement car il est utilisé 
												dans des preuves d’inscriptions sur des bénéficiaires! ».
Note                :	ADX0000730	IA	2005-06-13	Bruno Lapointe		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[DL_UN_College] (
	@ConnectID INTEGER, -- Identifiant unique de la connexion de l’usager.	
	@CollegeID INTEGER ) -- ID du collège à supprimer, correspond au CompanyID.
AS
BEGIN
	DECLARE
		@iResultID INTEGER,
		@iExecResID INTEGER

	-----------------
	BEGIN TRANSACTION
	-----------------

	SET @iResultID = @CollegeID

	IF EXISTS (
		SELECT ScholarshipPmtID
		FROM Un_ScholarshipPmt
		WHERE CollegeID = @CollegeID
		)
		SET @iResultID = -1

	IF @iResultID > 0
	AND EXISTS (
		SELECT BeneficiaryID
		FROM dbo.Un_Beneficiary 
		WHERE CollegeID = @CollegeID
		)
		SET @iResultID = -2

	IF @iResultID > 0
	BEGIN
		DELETE
		FROM Un_College
		WHERE CollegeID = @CollegeID

		IF @@ERROR <> 0
			SET @iResultID = -3
	END

	IF @iResultID > 0
	BEGIN
		EXECUTE @iExecResID = DL_CRQ_Company
			@ConnectID,
			@CollegeID

		IF @iExecResID <= 0
			SET @iResultID = -4
	END

	IF @iResultID > 0
		EXECUTE SP_IU_CRQ_Log @ConnectID, 'Un_College', @CollegeID, 'D', ''

	IF @iResultID > 0
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
		--------------------

	RETURN @iResultID
END


