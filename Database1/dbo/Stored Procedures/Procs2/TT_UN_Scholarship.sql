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
Nom                 :	TT_UN_Scholarship
Description         :	Procédure de création des PAE en batch.  Elle fera les actions suivantes : 
									-	Les opérations financières seront créés (PAE)
									-	Une lettre de transmission de chèque de bourse par opérations sera commandée
									-	Les bourses sélectionnées passeront automatiquement à la l’étape #5
Valeurs de retours  :	@ReturnValue :
									>0 = Pas d’erreur
										1 : Tout est ok 
										2 : Message d’information : « Des conventions dont le bénéficiaire est sans NAS et citoyen canadien n’ont pas été traitées. »
										3 : Message d’erreur : « Un des bénéficiaires à son adresse d’identifiée perdue. »
										4 : Message d’information : « Des conventions dont le bénéficiaire est sans NAS et citoyen canadien n’ont pas été traitées. » 
											 et message d’erreur : « Un des bénéficiaires à son adresse d’identifiée perdue. »
									<=0 = Erreur
Note                :	ADX0000704	IA	2005-07-07	Bruno Lapointe		Création
						ADX0000704	IA	2005-09-28	Bruno Lapointe		Gestion du cas d'adresse perdue.
						ADX0000753	IA	2005-10-05	Bruno Lapointe		Il faut expédier les opérations au module des
																					chèques.  Il faut aussi expédier les destinataires
																					originaux et les changements de destinataire.
																					Il ne faut plus créer et commander de chèque
																					automatiquement.
						ADX0001617	BR	2005-10-18	Bruno Lapointe		Correction message d'adresse perdue.
						ADX0001766	BR	2005-11-22	Bruno Lapointe		Correction : Montant du chèque en négatif
						ADX0000878	IA	2006-05-31	Bruno Lapointe		Suppression du paramètre bPaidCESG
																					Génération des enregistrements 400
																					Paiement du BEC, SCEE+, int. BEC, int. SCEE+, int. PCEE TIN.
						ADX0001909	BR	2006-06-12	Bruno Lapointe		Correction de la gestion des avances, correction
																					de la gestion des RGC avec l'utilisation de retenu 
																					RTN. Correction de la clause de SCEE, SCEE+ et 
																					BEC à 0.00 pour les non-résidents.
						ADX0002104	BR	2006-09-28	Bruno Lapointe		Envoyer le RGC au module des chèques.
						ADX0001235	IA	2007-02-14	Alain Quirion		Utilisation de dtRegStartDate pour la date de début de régime
						ADX0002426	BR	2007-05-24	Bruno Lapointe		Gestion de la table Un_CESP.
						ADX0001419	IA	2007-06-19	Bruno Lapointe		Gestion des conventions dont le bénéficiaire est sans NAS et 
																					citoyen canadien n’ont pas été traitées. Ils ne doivent pas
																					être traitées et un message doit être retournée (Result = 1)
						ADX0002502	BR	2007-06-27	Bruno Lapointe		NAS absent mal géré pour les conventions entrées en vigueur avant le 1 janvier 2003
										2010-01-19	Jean-F. Gauthier	Ajout du champ EligibilityConditionID de la table Un_Beneficiary
										2010-01-19	Rémy Rouillard		Ajout d'un appel à la catégorie OPER_TYPE_CONV_PAIEMENT_INTERET_PAE_MTNSOUSCRIT_SUBTIN_TIN, 
																		OPER_TYPE_CONV_PAIEMENT_INTERET_PAE_SUBVENTION_FEDERALE et OPER_TYPE_CONV_CALCUL_INTERET_PLAN_OPER_MTNSOUSCRIT_SUBTIN_TIN
										2010-03-17	Pierre-Luc Simard	Correction du champ EligibilityConditionID au lieu de ElibilityConditionID
										2010-10-14	Frederick Thibault	Ajout du champ Un_CESP400.fACESGPart pour régler le problème SCEE+
										2012-10-19	Donald Huppé		Générer la 400 après l'appel de IU_UN_OperCheckBatch afin d'inclure les montants d'IQEE dans le PAE qui sont générés via IU_UN_OperCheckBatch
                                        2017-09-27  Pierre-Luc Simard   Deprecated - Cette procédure n'est plus utilisée
										
exec TT_UN_Scholarship 1454899,872964
										
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_Scholarship] (
	@ConnectID INTEGER, -- ID unique de l’usager qui a provoqué ces opérations.
	@ScholarshipIDs INTEGER ) -- ID du blob contenant les ScholarshipID séparés par des « , » des bourses dont il faut faire le PAE.
AS
BEGIN
    
    SELECT 1/0
    /*
	DECLARE
		@iSPID INTEGER,
		@bAddressLost BIT,
		@iResult INTEGER,
		@DefProgram INTEGER,
		@DefCollege INTEGER,
		@StartOperID INTEGER,
		@iScholarshipYear INTEGER,
		@iExecRes INTEGER
	
	-- Établissement d'enseignement par défaut
	SELECT 
		@DefCollege = MIN(CollegeID) 
	FROM Un_College
	
	-- Programme par défaut
	SELECT 
		@DefProgram = MIN(ProgramID) 
	FROM Un_Program

	IF EXISTS (
			SELECT S.ScholarshipID
			FROM Un_Scholarship S
			JOIN dbo.FN_CRQ_BlobToIntegerTable(@ScholarshipIDs) V ON V.Val = S.ScholarshipID
			JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
			JOIN dbo.Mo_Human H ON H.HumanID = C.BeneficiaryID
			-- Les deux prochaines lignes trouvent les conventions dont le bénéficiaire est citoyen canadien et sans NAS
			WHERE ISNULL(H.SocialNumber,'') = '' -- NAS absent
				AND H.ResidID = 'CAN' -- Citoyen du Canada
			)
		SET @iResult = 2 -- Message d’information : « Des conventions dont le bénéficiaire est sans NAS et citoyen canadien n’ont pas été traitées. »
	ELSE
		SET @iResult = 1
	
	SET @iSPID = @@SPID

	-- Va chercher les informations nécessaires pour faire les paiements de bourses
	CREATE TABLE #tScholarshipToPaid (
		ScholarshipID INTEGER PRIMARY KEY,
		ScholarshipToPaidID INTEGER IDENTITY,
		PlanID INTEGER,
		ConventionID INTEGER,
		ScholarshipNo INTEGER,
		ScholarshipAmount MONEY,
		AdvanceAmount MONEY,
		NonResidAmount MONEY,
		ScholarshipCount INTEGER )
	INSERT INTO #tScholarshipToPaid (
			ScholarshipID,
			PlanID,
			ConventionID,
			ScholarshipNo,
			ScholarshipAmount,
			AdvanceAmount,
			NonResidAmount,
			ScholarshipCount )
		SELECT
			S.ScholarshipID,
			C.PlanID,
			C.ConventionID,
			S.ScholarshipNo,
			S.ScholarshipAmount,
			AdvanceAmount = SUM(-ISNULL(CO.ConventionOperAmount,0)),
			NonResidAmount = 
				CASE
					WHEN H.ResidID <> 'CAN' THEN ROUND(S.ScholarshipAmount * 0.25,2)
				ELSE 0
				END,
			ST.ScholarshipCount
		FROM Un_Scholarship S
		JOIN dbo.FN_CRQ_BlobToIntegerTable(@ScholarshipIDs) V ON V.Val = S.ScholarshipID
		JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
		JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
		JOIN dbo.Mo_Human H ON H.HumanID = C.BeneficiaryID
		JOIN (
			SELECT
				S.ScholarshipID,
				ScholarshipCount = COUNT(ST.ScholarshipID)
			FROM Un_Scholarship S
			JOIN Un_Scholarship ST ON ST.ConventionID = S.ConventionID AND ST.ScholarshipStatusID IN ('RES','TPA','ADM','WAI')
			GROUP BY S.ScholarshipID
			) ST ON ST.ScholarshipID = S.ScholarshipID
		LEFT JOIN Un_ScholarshipPmt SP ON SP.ScholarshipID = S.ScholarshipID
		LEFT JOIN Un_ConventionOper CO ON CO.OperID = SP.OperID AND CO.ConventionOperTypeID = 'AVC'
		WHERE B.bAddressLost = 0
			-- Les deux prochaines lignes exclus les conventions dont le bénéficiaire est citoyen canadien et sans NAS
			AND( ISNULL(H.SocialNumber,'') <> '' -- NAS présent
				OR H.ResidID <> 'CAN' -- Pas citoyen du Canada
				)
		GROUP BY
			S.ScholarshipID,
			C.PlanID,
			C.ConventionID,
			S.ScholarshipNo,
			S.ScholarshipAmount,
			H.ResidID,
			ST.ScholarshipCount
		ORDER BY
			NonResidAmount DESC,
			S.ScholarshipID

	-----------------
	BEGIN TRANSACTION
	-----------------

	-- Gestion des cas d'adresse perdue sur bénéficiaire
	IF @iResult > 0
	AND EXISTS (
			SELECT
				S.ScholarshipID
			FROM Un_Scholarship S
			JOIN dbo.FN_CRQ_BlobToIntegerTable(@ScholarshipIDs) V ON V.Val = S.ScholarshipID
			JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
			JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
			JOIN dbo.Mo_Human H ON H.HumanID = C.BeneficiaryID
			JOIN Un_Scholarship ST ON ST.ConventionID = C.ConventionID AND ST.ScholarshipStatusID IN ('RES','TPA','ADM','WAI')
			WHERE B.bAddressLost <> 0
			)
		SET @bAddressLost = 1
	ELSE
		SET @bAddressLost = 0

	-- Paye le 25% au gouvernment pour les boursiers qui ne sont pas résidents canadien
	IF @iResult > 0
	AND EXISTS 
			(
			SELECT *
			FROM #tScholarshipToPaid
			WHERE NonResidAmount > 0
			)
	BEGIN
		-- Va chercher le dernier OperID avant l'insertion des nouvelles opérations
		SET @StartOperID = IDENT_CURRENT('Un_Oper')

		-- Insère l'opération
		INSERT INTO Un_Oper (
				ConnectID,
				OperTypeID,
				OperDate)
			SELECT
				@ConnectID,
				'RGC',
				GETDATE()
			FROM #tScholarshipToPaid
			WHERE NonResidAmount > 0

		IF @@ERROR <> 0
			SET @iResult = -3

		IF @iResult > 0
		BEGIN
			-- Insère l'historique de paiement de bourse qui fait le lien entre la bourse et l'opération qui la paie et qui garde une historique de la preuve d'inscription.
			INSERT INTO Un_ScholarshipPmt (
					OperID, 
					ScholarshipID,
					CollegeID,
					ProgramID,
					StudyStart,
					ProgramLength,
					ProgramYear,
					RegistrationProof,
					SchoolReport,
					EligibilityQty,
					CaseOfJanuary,
					EligibilityConditionID)--ElibilityConditionID)		-- 2010-01-19 : JFG : ajout
				SELECT 
					STP.ScholarshipToPaidID + @StartOperID, 
					S.ScholarshipID,
					ISNULL(B.CollegeID, @DefCollege),
					ISNULL(B.ProgramID, @DefProgram),
					B.StudyStart,
					B.ProgramLength,
					B.ProgramYear,
					B.RegistrationProof,
					B.SchoolReport,
					B.EligibilityQty,
					B.CaseOfJanuary,
					B.EligibilityConditionID	-- 2010-01-19 : JFG : ajout
				FROM #tScholarshipToPaid STP
				JOIN Un_Scholarship S ON S.ScholarshipID = STP.ScholarshipID
				JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
				JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
				WHERE STP.NonResidAmount > 0

			IF @@ERROR <> 0
				SET @iResult = -4
		END

		IF @iResult > 0
		BEGIN
			-- Insère l'opération sur convention qui enlève le 25% du montant de la bourse
			INSERT INTO Un_ConventionOper (
					OperID,
					ConventionID,
					ConventionOperTypeID,
					ConventionOperAmount)
				SELECT
					STP.ScholarshipToPaidID + @StartOperID,
					S.ConventionID,
					'RTN',
					- STP.NonResidAmount
				FROM #tScholarshipToPaid STP
				JOIN Un_Scholarship S ON S.ScholarshipID = STP.ScholarshipID
				WHERE STP.NonResidAmount > 0

			IF @@ERROR <> 0
				SET @iResult = -5
		END

		-- Exportes les opérations dans le module des chèques
		IF @iResult > 0
		BEGIN
			INSERT INTO Un_OperToExportInCHQ (
					OperID,
					iSPID )
				SELECT
					STP.ScholarshipToPaidID + @StartOperID,
					@iSPID
				FROM #tScholarshipToPaid STP
				WHERE STP.NonResidAmount > 0

			IF @@ERROR <> 0
				SET @iResult = -6
		END
	END

	-- Insertion des bourses (PAE)
	IF @iResult > 0
	BEGIN
		-- Va chercher le dernier OperID avant l'insertion des nouvelles opérations
		SET @StartOperID = IDENT_CURRENT('Un_Oper')

		-- Insère l'opération
		INSERT INTO Un_Oper (
				ConnectID,
				OperTypeID,
				OperDate)
			SELECT
				@ConnectID,
				'PAE',
				GETDATE()
			FROM #tScholarshipToPaid

		IF @@ERROR <> 0
			SET @iResult = -8
	END

	IF @iResult > 0
	BEGIN
		-- Insère l'historique de paiement de bourse qui fait le lien entre la bourse et l'opération qui la paie et qui garde une historique de la preuve d'inscription.
		INSERT INTO Un_ScholarshipPmt (
				OperID, 
				ScholarshipID,
				CollegeID,
				ProgramID,
				StudyStart,
				ProgramLength,
				ProgramYear,
				RegistrationProof,
				SchoolReport,
				EligibilityQty,
				CaseOfJanuary,
				EligibilityConditionID)		-- 2010-01-19 : JFG : ajout
			SELECT 
				STP.ScholarshipToPaidID + @StartOperID, 
				S.ScholarshipID,
				ISNULL(B.CollegeID, @DefCollege),
				ISNULL(B.ProgramID, @DefProgram),
				B.StudyStart,
				B.ProgramLength,
				B.ProgramYear,
				B.RegistrationProof,
				B.SchoolReport,
				B.EligibilityQty,
				B.CaseOfJanuary,
				B.EligibilityConditionID	-- 2010-01-19 : JFG : ajout
			FROM #tScholarshipToPaid STP
			JOIN Un_Scholarship S ON S.ScholarshipID = STP.ScholarshipID
			JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
			JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID

		IF @@ERROR <> 0
			SET @iResult = -9
	END
	IF @iResult > 0
	BEGIN
		-- Insère une opération sur convention qui reprend les avances de bourses versées.
		INSERT INTO Un_ConventionOper (
				OperID,
				ConventionID,
				ConventionOperTypeID,
				ConventionOperAmount)
			SELECT
				STP.ScholarshipToPaidID + @StartOperID,
				S.ConventionID,
				'AVC',
				AdvanceAmount
			FROM #tScholarshipToPaid STP
			JOIN Un_Scholarship S ON S.ScholarshipID = STP.ScholarshipID
			WHERE AdvanceAmount <> 0

		IF @@ERROR <> 0
			SET @iResult = -11
	END
	IF @iResult > 0
	BEGIN
		-- Insère une opération sur convention qui paie la bourse
		INSERT INTO Un_ConventionOper (
				OperID,
				ConventionID,
				ConventionOperTypeID,
				ConventionOperAmount)
			SELECT
				STP.ScholarshipToPaidID + @StartOperID,
				S.ConventionID,
				'BRS',
				-STP.ScholarshipAmount
			FROM #tScholarshipToPaid STP
			JOIN Un_Scholarship S ON S.ScholarshipID = STP.ScholarshipID

		IF @@ERROR <> 0
			SET @iResult = -12
	END
	IF @iResult > 0
	BEGIN
		-- Insère une opération sur convention qui paie la bourse
		INSERT INTO Un_ConventionOper (
				OperID,
				ConventionID,
				ConventionOperTypeID,
				ConventionOperAmount)
			SELECT
				STP.ScholarshipToPaidID + @StartOperID,
				S.ConventionID,
				'RTN',
				STP.NonResidAmount
			FROM #tScholarshipToPaid STP
			JOIN Un_Scholarship S ON S.ScholarshipID = STP.ScholarshipID
			WHERE STP.NonResidAmount > 0

		IF @@ERROR <> 0
			SET @iResult = -13
	END
	IF @iResult > 0
	BEGIN
		-- Insère une opération sur convention qui paie l'intérêt sur montant souscrit, l'intérêt sur subvention
		-- provenent d'un transfert IN et l'intérêt sur capital provenent d'un transfert IN
		INSERT INTO Un_ConventionOper (
				OperID,
				ConventionID,
				ConventionOperTypeID,
				ConventionOperAmount)
			SELECT
				STP.ScholarshipToPaidID + @StartOperID,
				S.ConventionID,
				CO.ConventionOperTypeID,
				-SUM(CO.ConventionOperAmount)
			FROM #tScholarshipToPaid STP
			JOIN Un_Scholarship S ON S.ScholarshipID = STP.ScholarshipID
			JOIN Un_ConventionOper CO ON CO.ConventionID = S.ConventionID
			--WHERE CO.ConventionOperTypeID IN ('INM','IST','ITR') Modif 2010-01-19 Rémy
			WHERE CO.ConventionOperTypeID IN (SELECT val FROM	dbo.fn_Mo_StringTable(dbo.fnOPER_ObtenirTypesOperationConvCategorie('OPER_TYPE_CONV_PAIEMENT_INTERET_PAE_MTNSOUSCRIT_SUBTIN_TIN')))
			GROUP BY
				STP.ScholarshipToPaidID,
				S.ScholarshipID,
				S.ConventionID,
				CO.ConventionOperTypeID
			HAVING SUM(CO.ConventionOperAmount) > 0

		IF @@ERROR <> 0
			SET @iResult = -14
	END
	IF @iResult > 0
	BEGIN
		-- Insère une opération sur convention qui paie l'intérêt sur subvention
		INSERT INTO Un_ConventionOper (
				OperID,
				ConventionID,
				ConventionOperTypeID,
				ConventionOperAmount)
			SELECT
				STP.ScholarshipToPaidID + @StartOperID,
				S.ConventionID,
				CO.ConventionOperTypeID,
				-ROUND(SUM(CO.ConventionOperAmount)/ STP.ScholarshipCount,2)
			FROM #tScholarshipToPaid STP
			JOIN Un_Scholarship S ON S.ScholarshipID = STP.ScholarshipID
			JOIN Un_ConventionOper CO ON CO.ConventionID = S.ConventionID
			--WHERE CO.ConventionOperTypeID IN ('INS','IS+', 'IBC') Modif 2010-01-19 Rémy
			WHERE CO.ConventionOperTypeID IN (SELECT val FROM	dbo.fn_Mo_StringTable(dbo.fnOPER_ObtenirTypesOperationConvCategorie('OPER_TYPE_CONV_PAIEMENT_INTERET_PAE_SUBVENTION_FEDERALE')))
				AND STP.ScholarshipCount > 0
			GROUP BY
				STP.ScholarshipToPaidID,
				S.ScholarshipID,
				S.ConventionID,
				CO.ConventionOperTypeID,
				STP.ScholarshipCount
			HAVING SUM(CO.ConventionOperAmount) > 0

		IF @@ERROR <> 0
			SET @iResult = -15
	END
	IF @iResult > 0
	BEGIN
		-- Insère une opération sur convention qui paie la subvention
		INSERT INTO Un_CESP (
				OperID,
				ConventionID,
				OperSourceID,
				fCESG,
				fACESG,
				fCLB,
				fCLBFee,
				fPG,
				fCotisationGranted)
			SELECT
				STP.ScholarshipToPaidID + @StartOperID,
				S.ConventionID,
				STP.ScholarshipToPaidID + @StartOperID,
				-ROUND(SUM(CE.fCESG)/ STP.ScholarshipCount,2),
				-ROUND(SUM(CE.fACESG)/ STP.ScholarshipCount,2),
				-ROUND(SUM(CE.fCLB)/ STP.ScholarshipCount,2),
				0,
				-ROUND(SUM(CE.fPG)/ STP.ScholarshipCount,2),
				-ROUND(SUM(CE.fCotisationGranted)/ STP.ScholarshipCount,2)
			FROM #tScholarshipToPaid STP
			JOIN Un_Scholarship S ON S.ScholarshipID = STP.ScholarshipID
			JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
			JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID
			JOIN Un_CESP CE ON CE.ConventionID = S.ConventionID
			WHERE STP.ScholarshipCount > 0
				AND STP.NonResidAmount = 0
			GROUP BY
				STP.ScholarshipToPaidID,
				S.ScholarshipID,
				S.ConventionID,
				STP.ScholarshipCount,
				HB.SocialNumber
			HAVING SUM(CE.fCESG) > 0
				OR SUM(CE.fACESG) > 0
				OR SUM(CE.fCLB) > 0
				OR SUM(CE.fPG) > 0

		IF @@ERROR <> 0
			SET @iResult = -16
	END
	
	-- 400 ici

	-- Calcul l'intérêt collectif
	IF @iResult > 0
	BEGIN
		CREATE TABLE #tConventionInterest (
			ConventionID INTEGER PRIMARY KEY, -- ID de la convention
			Interest MONEY ) -- Intérêt de type INM, ITR, et IST
		INSERT INTO #tConventionInterest (
				ConventionID,
				Interest )
			SELECT
				S.ConventionID,
				Interest = SUM(CO.ConventionOperAmount)
			FROM #tScholarshipToPaid STP
			JOIN Un_Scholarship S ON S.ScholarshipID = STP.ScholarshipID
			JOIN Un_ConventionOper CO ON CO.ConventionID = S.ConventionID
			--WHERE CO.ConventionOperTypeID IN ('INM','ITR','IST') Modif 2010-01-19 Rémy
			WHERE CO.ConventionOperTypeID IN (SELECT val FROM	dbo.fn_Mo_StringTable(dbo.fnOPER_ObtenirTypesOperationConvCategorie('OPER_TYPE_CONV_CALCUL_INTERET_PLAN_OPER_MTNSOUSCRIT_SUBTIN_TIN')))
			GROUP BY S.ConventionID
			HAVING SUM(CO.ConventionOperAmount) > 0

		CREATE TABLE #tPlanInterest (
				PlanID INTEGER PRIMARY KEY, -- ID du plan
				Interest MONEY ) -- Intérêt de type INC
		INSERT INTO #tPlanInterest (
				PlanID,
				Interest )
			SELECT
				PlanID,
				Interest = SUM(PlanOperAmount)
			FROM Un_PlanOper
			WHERE PlanOperTypeID = 'INC'
			GROUP BY PlanID
			HAVING SUM(PlanOperAmount) > 0

		-- Insère l'intérêt collectif
		INSERT INTO Un_PlanOper (
				OperID,
				PlanID,
				PlanOperTypeID,
				PlanOperAmount)
			SELECT
				STP.ScholarshipToPaidID + @StartOperID,
				C.PlanID,
				'INC',
				- ROUND(PIn.Interest * (CI.Interest / PIn.Interest),2)
			FROM #tScholarshipToPaid STP
			JOIN Un_Scholarship S ON S.ScholarshipID = STP.ScholarshipID
			JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
			JOIN #tConventionInterest CI ON CI.ConventionID = C.ConventionID
			JOIN #tPlanInterest PIn ON PIn.PlanID = C.PlanID
			WHERE ROUND(PIn.Interest * (CI.Interest / PIn.Interest),2) <> 0
		DROP TABLE #tConventionInterest
		DROP TABLE #tPlanInterest

		IF @@ERROR <> 0
			SET @iResult = -20
	END	
	IF @iResult > 0
	BEGIN
		CREATE TABLE #tConventionCESG (
			ConventionID INTEGER PRIMARY KEY, -- ID de la convention
			fCESG MONEY ) -- Subvention de la convention
		INSERT INTO #tConventionCESG (
				ConventionID,
				fCESG )
			SELECT
				S.ConventionID,
				Interest = SUM(CE.fCESG)
			FROM #tScholarshipToPaid STP
			JOIN Un_Scholarship S ON S.ScholarshipID = STP.ScholarshipID
			JOIN Un_CESP CE ON CE.ConventionID = S.ConventionID
			WHERE STP.ScholarshipCount > 0
			GROUP BY S.ConventionID
			HAVING SUM(CE.fCESG) > 0
			
		CREATE TABLE #tConventionCESGInterest (
			ConventionID INTEGER PRIMARY KEY, -- Numéro de convention
			fCESGInt MONEY ) -- Intérêt sur subvention de la convention
		INSERT INTO #tConventionCESGInterest (
				ConventionID,
				fCESGInt )
			SELECT
				S.ConventionID,
				Interest = SUM(CO.ConventionOperAmount)
			FROM #tScholarshipToPaid STP
			JOIN Un_Scholarship S ON S.ScholarshipID = STP.ScholarshipID
			JOIN Un_ConventionOper CO ON CO.ConventionID = S.ConventionID
			WHERE CO.ConventionOperTypeID = 'INS'
			GROUP BY S.ConventionID
			HAVING SUM(CO.ConventionOperAmount) > 0

		-- Va chercher l'année de traitement de bourses
		SELECT @iScholarshipYear = MAX(ScholarshipYear)
		FROM Un_Def

		INSERT INTO Un_PlanOper (
				OperID,
				PlanID,
				PlanOperTypeID,
				PlanOperAmount)
			SELECT
				STP.ScholarshipToPaidID + @StartOperID,
				C.PlanID,
				'SUC',
				- ROUND(PV.CollectiveGrantAmount * ((ROUND(ISNULL(CE.fCESG,0) / STP.ScholarshipCount,2) + ROUND(ISNULL(CEI.fCESGInt,0) / STP.ScholarshipCount,2)) / PV.ScholarshipGrantAmount),2)
			FROM #tScholarshipToPaid STP
			JOIN Un_Scholarship S ON S.ScholarshipID = STP.ScholarshipID
			JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
			LEFT JOIN #tConventionCESG CE ON CE.ConventionID = C.ConventionID
			LEFT JOIN #tConventionCESGInterest CEI ON CEI.ConventionID = C.ConventionID
			JOIN Un_PlanValues PV ON PV.PlanID = C.PlanID AND PV.ScholarshipNo = S.ScholarshipNo AND PV.ScholarshipYear = @iScholarshipYear AND PV.ScholarshipGrantAmount > 0
			WHERE STP.ScholarshipCount > 0
				AND ROUND(PV.CollectiveGrantAmount * ((ROUND(ISNULL(CE.fCESG,0) / STP.ScholarshipCount,2) + ROUND(ISNULL(CEI.fCESGInt,0) / STP.ScholarshipCount,2)) / PV.ScholarshipGrantAmount),2) <> 0

		DROP TABLE #tConventionCESG
		DROP TABLE #tConventionCESGInterest

		IF @@ERROR <> 0
			SET @iResult = -21
	END	

	-- Réécrit le blob en excluant les bourses des bénéficiaires dont l'adresse est perdue.
	IF @iResult > 0
	BEGIN
		DECLARE
			@vcScholarshipID VARCHAR(20),
			@pBlob BINARY(16),
			@iBlobLength INTEGER
		
		DECLARE 
			crScholarshipIDs CURSOR FOR
				SELECT DISTINCT CAST(ScholarshipID AS VARCHAR)+','
				FROM #tScholarshipToPaid
	
		-- Crée un pointeur sur le blob qui servira lors des mises à jour.
		SELECT @pBlob = TEXTPTR(Blob)
		FROM CRQ_Blob
		WHERE BlobID = @ScholarshipIDs

		SET @vcScholarshipID = ''

		OPEN crScholarshipIDs

		FETCH NEXT FROM crScholarshipIDs INTO
			@vcScholarshipID

		-- Vide le blob, pour le recréé
		UPDATE CRQ_Blob
		SET Blob = @vcScholarshipID
		WHERE BlobID = @ScholarshipIDs

		IF @@FETCH_STATUS = 0
			FETCH NEXT FROM crScholarshipIDs INTO
				@vcScholarshipID

		-- Parcours du curseur et contrôle des données :
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SELECT @iBlobLength = DATALENGTH(Blob)
			FROM CRQ_Blob
			WHERE BlobID = @ScholarshipIDs
	
			UPDATETEXT CRQ_Blob.Blob @pBlob @iBlobLength 0 @vcScholarshipID
	
			FETCH NEXT FROM crScholarshipIDs INTO
				@vcScholarshipID
		END
	
		CLOSE crScholarshipIDs
		DEALLOCATE crScholarshipIDs		
	END

	-- Change le status des bourses pour payées
	IF @iResult > 0
	AND EXISTS (
		SELECT BlobID
		FROM CRQ_Blob
		WHERE BlobID = @ScholarshipIDs
			AND DATALENGTH(Blob) > 0
			)
	BEGIN
		EXECUTE @iExecRes = IU_UN_BatchScholarshipStatus @ConnectID, @ScholarshipIDs, 'PAD'

		IF @iExecRes <= 0
			SET @iResult = -22
	END

	--	Les bourses sélectionnées passeront automatiquement à la l’étape #5
	IF @iResult > 0
	AND EXISTS (
		SELECT BlobID
		FROM CRQ_Blob
		WHERE BlobID = @ScholarshipIDs
			AND DATALENGTH(Blob) > 0
			)
	BEGIN
		EXECUTE @iExecRes = IU_UN_ScholarshipStep @ConnectID, @ScholarshipIDs, 5

		IF @iExecRes <= 0
			SET @iResult = -23
	END

	-- Exportes les opérations dans le module des chèques
	IF @iResult > 0
	BEGIN
		DECLARE
			@iCheckResultID INTEGER
	
		INSERT INTO Un_OperToExportInCHQ (
				OperID,
				iSPID )
			SELECT
				@StartOperID+ScholarshipToPaidID,
				@iSPID
			FROM #tScholarshipToPaid
	
		EXECUTE @iCheckResultID = IU_UN_OperCheckBatch 1, @iSPID --- IQEE ici
	
		IF @iCheckResultID <> @iSPID
			SET @iResult = -24
	END

	-- Génération des enregistrements 400
	IF @iResult > 0
	BEGIN
		INSERT INTO Un_CESP400 (
				OperID,
				ConventionID,
				tiCESP400TypeID,
				vcTransID,
				dtTransaction,
				iPlanGovRegNumber,
				ConventionNo,
				vcSubscriberSINorEN,
				vcBeneficiarySIN,
				fCotisation,
				bCESPDemand,
				dtStudyStart,
				tiStudyYearWeek,
				fCESG,
				fACESGPart,
				fEAPCESG,
				fEAP,
				fPSECotisation,
				tiProgramLength,
				cCollegeTypeID,
				vcCollegeCode,
				siProgramYear,
				fCLB,
				fEAPCLB,
				fPG,
				fEAPPG )
			SELECT
				O.OperID,
				C.ConventionID,
				13,
				'FIN',
				O.OperDate,
				P.PlanGovernmentRegNo,
				C.ConventionNo,
				HS.SocialNumber,
				HB.SocialNumber,
				0,
				C.bCESGRequested,
				SP.StudyStart,
				CASE Col.CollegeTypeID
					WHEN '01' THEN 30
				ELSE 34 
				END,
				0,
				0,
				-(CE.fCESG + CE.fACESG),
				-(CE.fCLB + CE.fCESG + CE.fACESG + CG.sumOper),
				0,
				SP.ProgramLength,
				Col.CollegeTypeID,
				Col.CollegeCode,
				SP.ProgramYear,
				0,
				-CE.fCLB,		
				0,
				0
			FROM #tScholarshipToPaid STP
			JOIN Un_Scholarship S ON S.ScholarshipID = STP.ScholarshipID
			JOIN Un_Oper O ON O.OperID = STP.ScholarshipToPaidID + @StartOperID
			JOIN Un_ScholarshipPmt SP ON SP.OperID = O.OperID
			JOIN Un_College Col ON Col.CollegeID = SP.CollegeID
			JOIN Un_CESP CE ON CE.OperID = O.OperID
			JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID
			JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
			JOIN (
				SELECT 
					STP.ScholarshipID,
					sumOper = SUM(CO.ConventionOperAmount)
				FROM #tScholarshipToPaid STP
				JOIN Un_ConventionOper CO ON CO.OperID = STP.ScholarshipToPaidID + @StartOperID
				GROUP BY STP.ScholarshipID
				) CG ON CG.ScholarshipID = STP.ScholarshipID
			WHERE dbo.FN_CRQ_DateNoTime(ISNULL(C.dtRegStartDate,O.OperDate+1)) <= O.OperDate	
				AND ISNULL(HB.SocialNumber,'') <> ''

		IF @@ERROR <> 0
			SET @iResult = -17
		ELSE
		BEGIN
			-- Inscrit le vcTransID avec le ID FIN + <iCESP400ID>.
			UPDATE Un_CESP400
			SET vcTransID = 'FIN'+CAST(iCESP400ID AS VARCHAR(12))
			WHERE vcTransID = 'FIN' 
	
			IF @@ERROR <> 0
				SET @iResult = -18
		END
	END

	--	Une lettre de transmission de chèque de bourse par opérations sera commandée
	IF @iResult > 0
	AND EXISTS (
		SELECT BlobID
		FROM CRQ_Blob
		WHERE BlobID = @ScholarshipIDs
			AND DATALENGTH(Blob) > 0
			)
	BEGIN
		EXECUTE @iExecRes = RP_UN_ScholarshipChequeLetterBatch @ConnectID, @ScholarshipIDs, 0

		IF @iExecRes <= 0
			SET @iResult = -25
	END
	
	IF @iResult > 0
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
		--------------------

	-- Fait le traitement mais indique tout de même que certain cas n'ont pas été traité à cause que l'adresse du bénéficiaire est perdue.
	IF @bAddressLost = 1 AND @iResult > 0
		SET @iResult = @iResult+2

	RETURN @iResult
    */
END