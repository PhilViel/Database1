/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************    */

/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	TT_UN_ScanChequeForScholarship
Description         :	Traitement quotidien qui consultera le module de chèque. Ce traitement modifie l’étape rendu
								du PAE dans l’outil de gestion des paiements de bourses selon l’état de l’opération dans le
								module des chèques. Quand un chèque est proposé sur un PAE, on passe ce dernier à l’étape #6
								dans l’outil. Quand un chèque est annulé ou refusé, on recule l’opération à l’étape #5.
Valeurs de retours  :	@ReturnValue :
									>0 = Pas d’erreur
									<=0 = Erreur SQL
Note                :	ADX0000753	IA	2005-10-05	Bruno Lapointe		Création
                                        2017-09-27  Pierre-Luc Simard   Deprecated - Cette procédure n'est plus utilisée

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_ScanChequeForScholarship] 
AS
BEGIN
    
    SELECT 1/0
    /*
	DECLARE
		@iConnectID INTEGER

	INSERT INTO Mo_Connect (
			UserID,
			CodeID,
			StationName,
			IPAddress)
		SELECT
			UserID,
			0,
			@@SERVERNAME,
			''
		FROM Mo_User
		WHERE LoginNameID = 'Compurangers'

	SET @iConnectID = SCOPE_IDENTITY()

	CREATE TABLE #ScholarshipToPAE (
		ScholarshipID INTEGER PRIMARY KEY)

	INSERT INTO #ScholarshipToPAE
		SELECT
			S.ScholarshipID
		FROM Un_Scholarship S
		JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
		JOIN Un_Plan P ON P.PlanID = C.PlanID
		WHERE S.ScholarshipStatusID IN ('ADM', 'WAI', 'TPA', 'PAD')
			AND P.PlanTypeID = 'COL'

	-- Quand un chèque est proposé sur un PAE, on passe ce dernier à l’étape #6 dans l’outil.
	INSERT INTO Un_ScholarshipStep (
			ScholarshipID,
			iScholarshipStep,
			dtScholarshipStepTime,
			ConnectID )
		SELECT 
			V.ScholarshipID,
			6,
			GETDATE(),
			@iConnectID
		FROM (
			SELECT DISTINCT SStT.ScholarshipID
			FROM (
				SELECT 
					SPAE.ScholarshipID,
					iScholarshipStepID = MAX(iScholarshipStepID)
				FROM #ScholarshipToPAE SPAE
				JOIN Un_ScholarshipStep SSt ON SSt.ScholarshipID = SPAE.ScholarshipID
				GROUP BY SPAE.ScholarshipID
				) SStT 
			JOIN Un_ScholarshipStep SSt ON SSt.iScholarshipStepID = SStT.iScholarshipStepID AND SSt.bOldPAE = 0
			JOIN Un_ScholarshipPmt SP ON SP.ScholarshipID = SStT.ScholarshipID
			JOIN Un_Oper O ON O.OperID = SP.OperID AND O.OperTypeID = 'PAE'
			JOIN Un_OperLinkToCHQOperation L ON L.OperID = O.OperID
			JOIN CHQ_OperationDetail OD ON OD.iOperationID = L.iOperationID
			JOIN CHQ_CheckOperationDetail COD ON COD.iOperationDetailID = OD.iOperationDetailID
			JOIN CHQ_Check C ON C.iCheckID = COD.iCheckID
			WHERE C.iCheckStatusID NOT IN (3,5)
				AND SSt.iScholarshipStep = 5
			) V

	-- Quand un chèque est annulé ou refusé, on recule l’opération à l’étape #5.
	INSERT INTO Un_ScholarshipStep (
			ScholarshipID,
			iScholarshipStep,
			dtScholarshipStepTime,
			ConnectID )
		SELECT 
			SStT.ScholarshipID,
			5,
			GETDATE(),
			@iConnectID
		FROM (
			SELECT 
				SPAE.ScholarshipID,
				iScholarshipStepID = MAX(iScholarshipStepID)
			FROM #ScholarshipToPAE SPAE
			JOIN Un_ScholarshipStep SSt ON SSt.ScholarshipID = SPAE.ScholarshipID
			GROUP BY SPAE.ScholarshipID
			) SStT 
		JOIN Un_ScholarshipStep SSt ON SSt.iScholarshipStepID = SStT.iScholarshipStepID AND SSt.bOldPAE = 0
		LEFT JOIN ( -- Groupe d'unité pour lesquelles un chèque non refusé et non annulé a été émis
			SELECT DISTINCT SPAE.ScholarshipID
			FROM #ScholarshipToPAE SPAE
			JOIN Un_ScholarshipPmt SP ON SP.ScholarshipID = SPAE.ScholarshipID
			JOIN Un_Oper O ON O.OperID = SP.OperID AND O.OperTypeID = 'PAE'
			JOIN Un_OperLinkToCHQOperation L ON L.OperID = O.OperID
			JOIN CHQ_OperationDetail OD ON OD.iOperationID = L.iOperationID
			JOIN CHQ_CheckOperationDetail COD ON COD.iOperationDetailID = OD.iOperationDetailID
			JOIN CHQ_Check C ON C.iCheckID = COD.iCheckID
			WHERE C.iCheckStatusID NOT IN (3,5)
			) V ON V.ScholarshipID = SStT.ScholarshipID 
		WHERE V.ScholarshipID IS NULL
			AND SSt.iScholarshipStep = 6

	DROP TABLE #ScholarshipToPAE
    */
END