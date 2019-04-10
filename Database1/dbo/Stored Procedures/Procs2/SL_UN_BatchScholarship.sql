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
Nom                 :	SL_UN_BatchScholarship
Description         :	Procédure retournant les données pour remplir la grille de visualisation de l’outil de 
								gestion des paiements de bourses (PAE).  Elle doit être appelée à l’ouverture de l’outil et 
								lors du rafraîchissement de la liste.
Valeurs de retours  :	Dataset :
									ScholarshipID			ID unique de la bourse.
									ConventionID			ID unique de la convention.
									SubscriberID			ID unique du souscripteur.
									BeneficiaryID			ID unique du bénéficiaire.
									ConventionNo			Numéro de la convention.
									ScholarshipNo			Numéro de bourse.
									UnitQty					Nombre d’unités.
									ScholarshipStatusID	Chaîne de 3 caractères qui donne l'état de la bourse 
																('RES'=En réserve, 'PAD'=Payée, 'ADM'=Admissible, 'WAI'=En attente, 
																'TPA'=À payer, 'DEA'=Décès, 'REN'=Renonciation, '25Y'=25 ans de régime, 
																'24Y'=24 ans d'âge).
									SubscriberLastName	Nom du souscripteur.
									SubscriberFirstName	Prénom du souscripteur.
									BeneficiaryLastName	Nom du bénéficiaire.
									BeneficiaryFirstName	Prénom du bénéficiaire.
									PlanDesc					Régime de la convention (Universitas, Sélect 2000 Plan B, REEEFLEX)
									BeneficiaryBirthDate	Date de naissance du bénéficiaire.
									iStep						Numéro de l’étape actuel du PAE.
									IsChecked				Indique si la case à cocher est supposée être cochée.
									OperID					ID de l’opération PAE si elle a été faite.
									bAddressLost			Indique si l'adresse du bénéficiaire est perdue
Note                :	ADX0000704	IA	2005-06-27	Bruno Lapointe		Création
								ADX0001612	BR	2005-10-14	Bruno Lapointe		Optimisation.
								ADX0001624	BR	2005-10-19	Bruno Lapointe		Preuve d'inscription.
								ADX0001763	BR	2005-11-22	Bruno Lapointe		Gérer le cas des bourses en double dans le blob.
								ADX0001791	BR	2005-12-14	Bruno Lapointe		Nombre d'unités mal calculé.
								ADX0000878	IA	2006-05-31	Bruno Lapointe		Enlever la valeur de retour bPaidCESG.
								ADX0001419	IA	2007-06-19	Bruno Lapointe		Retourne le champs bAddressLost
                                                2017-09-27  Pierre-Luc Simard   Deprecated - Cette procédure n'est plus utilisée

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_BatchScholarship] (
	@ConnectID INTEGER,			-- ID de connexion de l’usager qui demande la liste.
	@ScholarshipIDs INTEGER )	-- ID du blob contenant les ScholarshipID séparés par des « , » des bourses dont on veut 
										--	rafraîchir les données de la grille.  Si 0, alors on veut rafraîchir tout les bourses 
										--	de la grille.
AS
BEGIN
    
    SELECT 1/0
    /*
	DECLARE
		@UserID INTEGER

	SELECT @UserID = UserID
	FROM Mo_Connect
	WHERE ConnectID = @ConnectID

	CREATE TABLE #ScholarshipToPAE (
		ScholarshipID INTEGER PRIMARY KEY)

	IF @ScholarshipIDs = 0
		INSERT INTO #ScholarshipToPAE
			SELECT DISTINCT
				S.ScholarshipID
			FROM Un_Scholarship S
			JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			WHERE S.ScholarshipStatusID IN ('ADM', 'WAI', 'TPA', 'PAD')
				AND P.PlanTypeID = 'COL'
	ELSE
		INSERT INTO #ScholarshipToPAE
			SELECT DISTINCT
				ScholarshipID = B.Val
			FROM dbo.FN_CRQ_BlobToIntegerTable(@ScholarshipIDs) B
			JOIN Un_Scholarship S ON S.ScholarshipID = B.Val
			JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			WHERE S.ScholarshipStatusID IN ('ADM', 'WAI', 'TPA', 'PAD')
				AND P.PlanTypeID = 'COL'
		
	SELECT 
		S.ScholarshipID, -- ID unique de la bourse.
		C.ConventionID, -- ID unique de la convention.
		C.SubscriberID, -- ID unique du souscripteur.
		C.BeneficiaryID, -- ID unique du bénéficiaire.
		C.ConventionNo, -- Numéro de la convention.
		S.ScholarshipNo, -- Numéro de bourse.
		UnitQty = ISNULL(U.UnitQty,0), -- Nombre d’unités.
		S.ScholarshipStatusID, -- Chaîne de 3 caractères qui donne l'état de la bourse ('RES'=En réserve, 'PAD'=Payée, 'ADM'=Admissible, 'WAI'=En attente, TPA'=À payer, 'DEA'=Décès, 'REN'=Renonciation, '25Y'=25 ans de régime, '24Y'=24 ans d'âge).
		SubscriberLastName = HS.LastName, -- Nom du souscripteur.
		SubscriberFirstName = HS.FirstName, -- Prénom du souscripteur.
		BeneficiaryLastName = HB.LastName, -- Nom du bénéficiaire.
		BeneficiaryFirstName = HB.FirstName, -- Prénom du bénéficiaire.
		P.PlanDesc, -- Régime de la convention (Universitas, Sélect 2000 Plan B, REEEFLEX)
		BeneficiaryBirthDate = HB.BirthDate, -- Date de naissance du bénéficiaire.
		iStep = SSt.iScholarshipStep, -- Numéro de l’étape actuel du PAE.
		IsChecked = 
			CASE 
				WHEN Cn.ConnectID IS NULL THEN 0
			ELSE 1
			END, -- Indique si la case à cocher est supposée être cochée.
		OperID = ISNULL(O.OperID,0), -- ID de l’opération PAE si elle a été faite.
		HB.ResidID,
		RegistrationProof =
			CAST	(
					CASE
						WHEN ISNULL(B.CollegeID,0) > 0
							AND ISNULL(B.StudyStart,0) > 0
							AND B.ProgramYear > 0
							AND B.ProgramLength > 0 
							AND B.RegistrationProof <> 0 
							AND B.SchoolReport <> 0 THEN 1
					ELSE 0
					END AS BIT
					),
		b.bAddressLost
	FROM #ScholarshipToPAE SPAE
	JOIN Un_Scholarship S ON S.ScholarshipID = SPAE.ScholarshipID
	JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
	JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
	JOIN Un_Plan P ON P.PlanID = C.PlanID
	JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
	JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID
	JOIN (
		SELECT 
			SPAE.ScholarshipID,
			iScholarshipStepID = MAX(iScholarshipStepID)
		FROM #ScholarshipToPAE SPAE
		JOIN Un_ScholarshipStep SSt ON SSt.ScholarshipID = SPAE.ScholarshipID
		GROUP BY SPAE.ScholarshipID
		) SStT ON SStT.ScholarshipID = S.ScholarshipID
	JOIN Un_ScholarshipStep SSt ON SSt.iScholarshipStepID = SStT.iScholarshipStepID AND SSt.bOldPAE = 0
	LEFT JOIN (
		SELECT 
			S.ScholarshipID,
			UnitQty = SUM(U.UnitQty)
		FROM #ScholarshipToPAE SPAE
		JOIN Un_Scholarship S ON S.ScholarshipID = SPAE.ScholarshipID
		JOIN dbo.Un_Unit U ON U.ConventionID = S.ConventionID
		GROUP BY S.ScholarshipID
		) U ON U.ScholarshipID = S.ScholarshipID
	LEFT JOIN Un_ScholarshipBatchCheck SCh ON SCh.ScholarshipID = S.ScholarshipID
	LEFT JOIN Mo_Connect Cn ON Cn.ConnectID = SCh.ConnectID AND Cn.UserID = @UserID
	LEFT JOIN (
		SELECT
			SPAE.ScholarshipID,
			O.OperID
		FROM #ScholarshipToPAE SPAE
		JOIN Un_ScholarshipPmt P ON P.ScholarshipID = SPAE.ScholarshipID
		JOIN Un_Oper O ON O.OperID = P.OperID
		LEFT JOIN Un_OperCancelation OC ON OC.OperID = O.OperID OR OC.OperSourceID = O.OperID
		LEFT JOIN Mo_Cheque C ON C.ChequeCodeID = O.OperID AND C.ChequeName = 'UN_OPER'
		WHERE O.OperTypeID = 'PAE'
			AND OC.OperID IS NULL
		) O ON O.ScholarshipID = S.ScholarshipID

	DROP TABLE #ScholarshipToPAE
    */
END