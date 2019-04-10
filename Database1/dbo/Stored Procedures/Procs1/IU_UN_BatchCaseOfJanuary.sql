/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************   */

/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_BatchCaseOfJanuary
Description         :	Procédure marquant des bénéficiaires comme cas de janviers.
Valeurs de retours  :	@ReturnValue :
									>0 = Pas d’erreur
									<=0 = Erreur SQL
Note                :	
    Date        Programmeur             Description
    ----------  --------------------    -----------------------------------------------------------------------------
    2005-07-05  Bruno Lapointe          Création
    2006-03-03	Bruno Lapointe		    Ne tient pu compte du status pour déterminer si la bourse doit être traité 
                                        comme cas de janvier regarde à la place qu'elle soit à la première étape de 
                                        l'outil de paiement de bourse.
    2017-09-27  Pierre-Luc Simard       Deprecated - Cette procédure n'est plus utilisée

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_BatchCaseOfJanuary] (
	@ConnectID INTEGER, -- ID unique de l’usager qui a provoqué cette mise à jour.
	@BeneficiaryIDs INTEGER ) 	-- ID du blob contenant les BeneficiaryID séparés par des « , » des bénéficiaires dont il 
										-- faut marquer comme cas de janvier.
AS
BEGIN
    SELECT 1/0
    /*
	DECLARE
		@iResult INTEGER

	-- Met le contenu du blob dans une table temporaire
	CREATE TABLE #tBeneficiary (
		BeneficiaryID INTEGER PRIMARY KEY )
	INSERT INTO #tBeneficiary
		SELECT DISTINCT Val
		FROM dbo.FN_CRQ_BlobToIntegerTable(@BeneficiaryIDs)

	-- Table temporaire des bourses de l'outil de PAE rattaché aux bénéficiaires
	CREATE TABLE #tBatchScholarship (
		ScholarshipID INTEGER PRIMARY KEY )
	INSERT INTO #tBatchScholarship
		SELECT DISTINCT S.ScholarshipID
		FROM #tBeneficiary B
		JOIN dbo.Un_Convention C ON C.BeneficiaryID = B.BeneficiaryID
		JOIN Un_Scholarship S ON S.ConventionID = C.ConventionID
		JOIN Un_Plan P ON P.PlanID = C.PlanID
		JOIN (
			SELECT 
				S.ScholarshipID,
				iScholarshipStepID = MAX(iScholarshipStepID)
			FROM #tBeneficiary B
			JOIN dbo.Un_Convention C ON C.BeneficiaryID = B.BeneficiaryID
			JOIN Un_Scholarship S ON S.ConventionID = C.ConventionID
			JOIN Un_ScholarshipStep SSt ON SSt.ScholarshipID = S.ScholarshipID
			GROUP BY S.ScholarshipID
			) SStT ON SStT.ScholarshipID = S.ScholarshipID
		JOIN Un_ScholarshipStep SSt ON SSt.iScholarshipStepID = SStT.iScholarshipStepID AND SSt.bOldPAE = 0
		WHERE SSt.iScholarshipStep = 1 -- Étape actuel est 1

	SET @iResult = 1

	-----------------
	BEGIN TRANSACTION
	-----------------

	-- Met à true l'indicateur de cas de janvier sur les bénéficaires.
	UPDATE dbo.Un_Beneficiary 
	SET CaseOfJanuary = 1
	FROM dbo.Un_Beneficiary 
	JOIN #tBeneficiary B ON B.BeneficiaryID = Un_Beneficiary.BeneficiaryID

	IF @@ERROR <> 0
		SET @iResult = -1

	IF @iResult > 0
	BEGIN
		-- Change le statut des bourses de l’outil des PAE liés à ce bénéficiaire pour « En attente »
		UPDATE Un_Scholarship
		SET ScholarshipStatusID = 'WAI'
		FROM Un_Scholarship
		JOIN #tBatchScholarship S ON S.ScholarshipID = Un_Scholarship.ScholarshipID

		IF @@ERROR <> 0
			SET @iResult = -2
	END

	IF @iResult > 0
	BEGIN
		-- Insère l'historique de Status de l'étape #2 dans l'outil de PAE
		INSERT INTO Un_ScholarshipStep (
				ScholarshipID, -- ID de la bourse à laquelle appartient l’historique.
				iScholarshipStep, -- Étape (1 à 5)
				iScholarshipStep, -- Étape (1 à 5)
				dtScholarshipStepTime, -- Date et heure ou on a passé à cette étape.
				ConnectID ) -- ID de l’usager qui a provoqué le changement d’étape.
			SELECT
				ScholarshipID,
				2,
				GETDATE(),
				@ConnectID
			FROM #tBatchScholarship

		IF @@ERROR <> 0
			SET @iResult = -3
	END

	IF @iResult > 0
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
		--------------------

	DROP TABLE #tBeneficiary
	DROP TABLE #tBatchScholarship

	RETURN @iResult
    */
END