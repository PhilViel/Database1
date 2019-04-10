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
Nom                 :	IU_UN_ScholarshipStep
Description         :	Procédure d’insertion des étapes de PAE.
Valeurs de retours  :	@ReturnValue :
									>0 = Pas d’erreur
									<=0 = Erreur SQL
Note                :	ADX0000704	IA	2005-07-05	Bruno Lapointe		Création
						ADX0001784	BR	2006-03-03	Bruno Lapointe		Modification
										2010-10-04	Steve Gouin			Gestion des disable trigger par #DisableTrigger
                                        2017-09-27  Pierre-Luc Simard   Deprecated - Cette procédure n'est plus utilisée

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_ScholarshipStep] (
	@ConnectID INTEGER, -- ID unique de l’usager qui a provoqué cette insertion.
	@ScholarshipIDs INTEGER, -- ID du blob contenant les ScholarshipID séparés par des « , » des qu’il faut mettre au statut passer en paramètre.
	@iScholarshipStep INTEGER ) -- Étape à laquelle doivent passer les bourses.
AS
BEGIN
    
    SELECT 1/0
    /*
	INSERT INTO Un_ScholarshipStep (
			ScholarshipID,
			iScholarshipStep,
			dtScholarshipStepTime,
			ConnectID )
		SELECT
			Val,
			@iScholarshipStep,
			GETDATE(),
			@ConnectID
		FROM dbo.FN_CRQ_BlobToIntegerTable(@ScholarshipIDs)

	-- Change le status des bourses qui passent à l'étape 3 et dont la preuve d'inscription est complète
	IF @iScholarshipStep = 3
	BEGIN
		CREATE TABLE #tScholarshipToChangeStatus (
			ScholarshipID INTEGER PRIMARY KEY )
		INSERT INTO #tScholarshipToChangeStatus
			SELECT DISTINCT Val
			FROM dbo.FN_CRQ_BlobToIntegerTable(@ScholarshipIDs)

		-- Désactive le trigger de mise à jour des états s'il y a plus de 25 bourses à mettre à jour
		IF (
			SELECT
				COUNT(ScholarshipID)
			FROM #tScholarshipToChangeStatus
			) > 25
		BEGIN
			--ALTER TABLE Un_Scholarship
			--	DISABLE TRIGGER TUn_Scholarship_State
			IF object_id('tempdb..#DisableTrigger') is null
				CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))

			INSERT INTO #DisableTrigger VALUES('TUn_Scholarship_State')				
				
		END

		-- Change le statut des bourses du blob pour celui passer en paramètre
		UPDATE Un_Scholarship
		SET ScholarshipStatusID = 'TPA'
		FROM Un_Scholarship
		JOIN #tScholarshipToChangeStatus S ON S.ScholarshipID = Un_Scholarship.ScholarshipID
		JOIN dbo.Un_Convention C ON C.ConventionID = Un_Scholarship.ConventionID
		JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
		WHERE ISNULL(B.CollegeID,0) > 0
			AND ISNULL(B.StudyStart,0) > 0
			AND ISNULL(B.ProgramLength,0) > 0
			AND ISNULL(B.ProgramYear,0) > 0
			AND B.RegistrationProof <> 0
			AND B.SchoolReport <> 0

		-- Réactive le trigger de mise à jour des états s'il était désactivé
		IF (
			SELECT
				COUNT(ScholarshipID)
			FROM #tScholarshipToChangeStatus
			) > 25
		BEGIN
			--ALTER TABLE Un_Scholarship
			--	ENABLE TRIGGER TUn_Scholarship_State
			Delete #DisableTrigger where vcTriggerName = 'TUn_Scholarship_State'

		END
		
		DROP TABLE #tScholarshipToChangeStatus
	END

	IF @@ERROR = 0
		RETURN 1
	ELSE
		RETURN -1
    */
END