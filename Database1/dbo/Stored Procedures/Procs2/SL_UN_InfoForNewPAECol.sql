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
Nom                 :	SL_UN_InfoForNewPAECol
Description         :	Retourne les données nécessaires pour un nouveau PAE collectifs
Valeurs de retours  :	Dataset contenant les données
Note                :	ADX0000593	IA	2005-01-06	Bruno Lapointe		Création
								ADX0001259	BR	2005-02-03	Bruno Lapointe		Retour du champs EligibilityConditionID
								ADX0001007	IA	2006-05-29	Alain Quirion		Ajout et suppression de champs pour PCEE 4.3, Ajout du CountryID pour connaître le pays du Bénef.
								ADX0002426	BR	2007-05-23	Bruno Lapointe		Gestion de la table Un_CESP.
												2010-01-18	Jean-F. Gauthier	Ajout du champ EligibilityConditionID (table Un_Beneficiary) en retour
												2010-01-19	Rémy Rouillard		Ajout d'un appel à la catégorie OPER_TYPE_CONV_CALCUL_INTERET_NOUVEAU_PAE_COLLECTIF 
                                                2017-09-27  Pierre-Luc Simard   Deprecated - Cette procédure n'est plus utilisée

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_InfoForNewPAECol] (
	@ScholarshipID INTEGER) -- ID unique de la bourse que l'on veut payer
AS
BEGIN

    SELECT 1/0
    /*
	DECLARE
		@iConventionID INTEGER,
		@iPlanID INTEGER,
		@iScholarshipCount INTEGER,
		@iScholarshipNo INTEGER,
		@Bourse MONEY,
		@Retenu MONEY,
		@fCESG MONEY,
		@IntRI MONEY,
		@fTINInt MONEY,
		@fCESGInt MONEY,
		@fTINCESPInt MONEY,
		@Avance MONEY,
		@fACESG MONEY, 
		@fACESGInt MONEY, 
		@fCLB MONEY,
		@fCLBInt MONEY,
		@IntPlan MONEY

	SELECT
		@Bourse = S.ScholarshipAmount * -1,
		@iConventionID = S.ConventionID,
		@iPlanID = C.PlanID,
		@iScholarshipNo = S.ScholarshipNo
	FROM Un_Scholarship S
	JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
	WHERE S.ScholarshipID = @ScholarshipID

	SELECT 
		@fCESG = ISNULL(SUM(fCESG),0) *-1, 		--SCEE
		@fACESG = ISNULL(SUM(fACESG),0) *-1, 		--SCEE+
		@fCLB = ISNULL(SUM(fCLB),0) *-1			--BEC
	FROM Un_CESP					
	WHERE ConventionID = @iConventionID	

	SELECT
		@IntRI =
			SUM	(
				CASE 
					WHEN ConventionOperTypeID = 'INM' THEN ConventionOperAmount
				ELSE	0
				END
				) * -1,
		@fTINInt =
			SUM	(
				CASE 
					WHEN ConventionOperTypeID = 'ITR' THEN ConventionOperAmount
				ELSE	0
				END
				) * -1,
		@fCESGInt =
			SUM	(
				CASE 
					WHEN ConventionOperTypeID = 'INS' THEN ConventionOperAmount
				ELSE	0
				END
				) * -1,
		@fTINCESPInt =
			SUM	(
				CASE 
					WHEN ConventionOperTypeID = 'IST' THEN ConventionOperAmount
				ELSE	0
				END
				) * -1,
		@fACESGInt =
			SUM	(
				CASE 
					WHEN ConventionOperTypeID = 'IS+' THEN ConventionOperAmount
				ELSE	0
				END
				) * -1,
		@fCLBInt =
			SUM	(
				CASE 
					WHEN ConventionOperTypeID = 'IBC' THEN ConventionOperAmount
				ELSE	0
				END
				) * -1
	FROM Un_ConventionOper
	WHERE ConventionID = @iConventionID

	SELECT
		@Avance = ISNULL(SUM(CO.ConventionOperAmount),0) *-1
	FROM Un_Scholarship S
	JOIN Un_ScholarshipPmt SP ON SP.ScholarshipID = S.ScholarshipID
	JOIN Un_ConventionOper CO ON CO.OperID = SP.OperID
	WHERE S.ScholarshipID = @ScholarshipID
		AND CO.ConventionOperTypeID = 'AVC'

	-- Gestion des retenus de 25% pour les non résident du CANADA
	IF EXISTS (
			SELECT
				C.BeneficiaryID
			FROM dbo.Un_Convention C 
			JOIN dbo.Mo_Human H ON H.HumanID = C.BeneficiaryID
			WHERE C.ConventionID = @iConventionID
				AND H.ResidID <> 'CAN'
			)
		SET @Retenu = @Bourse * -0.25
	ELSE
		SET @Retenu = 0

	-- Nombre de bourse restant à payer pour la convention.
	SELECT
		@iScholarshipCount = COUNT(ScholarshipID)
	FROM Un_Scholarship
	WHERE ConventionID = @iConventionID
		AND ScholarshipStatusID IN ('RES','TPA','ADM','WAI')

	-- Vérifie qu'il y a de l'interêt
	IF @IntRI + @fTINInt + @fCESGInt + @fTINCESPInt + @fACESGInt + @fCLBInt < 0
	BEGIN
		SELECT
			@IntPlan = ISNULL(SUM(CO.ConventionOperAmount),0)
		FROM dbo.Un_Convention C
		JOIN Un_ConventionOper CO ON CO.ConventionID = C.ConventionID
		WHERE C.PlanID = @iPlanID
			-- AND CO.ConventionOperTypeID IN ('INM','ITR','INS','IST', 'IS+', 'IBC') Modif 2010-01-19 Rémy		
			AND CO.ConventionOperTypeID IN (SELECT val FROM	dbo.fn_Mo_StringTable(dbo.fnOPER_ObtenirTypesOperationConvCategorie('OPER_TYPE_CONV_CALCUL_INTERET_NOUVEAU_PAE_COLLECTIF')))		
	END

	-- Prorata du nombre de bourse pour ce qui affecte la PCEE
	SET @fCESGInt = ROUND(@fCESGInt / @iScholarshipCount,2)
	SET @fTINCESPInt = ROUND(@fTINCESPInt / @iScholarshipCount,2)
	SET @fCESG = ROUND(@fCESG / @iScholarshipCount,2)
	SET @fACESG = ROUND(@fACESG /  @iScholarshipCount,2)
	SET @fACESGInt = ROUND(@fACESGInt / @iScholarshipCount,2)
	SET @fCLB = ROUND(@fCLB / @iScholarshipCount,2)
	SET @fCLBInt = ROUND(@fCLBInt / @iScholarshipCount,2)
	
	SELECT
		C.ConventionID,
		B.CollegeID,
		CollegeName = ISNULL(Co.CompanyName,''),
		EligibilityConditionID = ISNULL(Col.EligibilityConditionID,''),
		B.ProgramID,
		ProgramDesc = ISNULL(P.ProgramDesc,''),
		B.StudyStart,
		B.ProgramLength,
		B.ProgramYear,
		B.RegistrationProof,
		B.SchoolReport,
		B.EligibilityQty,
		B.CaseOfJanuary,
		Avance = ISNULL(@Avance,0),
		IntRI = ISNULL(@IntRI,0),
		fTINInt = ISNULL(@fTINInt,0),
		fCESGInt = ISNULL(@fCESGInt,0),
		fTINCESPInt = ISNULL(@fTINCESPInt,0),
		fCESG = ISNULL(@fCESG,0),
		Bourse = ISNULL(@Bourse,0),
		Retenu = ISNULL(@Retenu,0),
		fACESG = ISNULL(@fACESG,0),
		fACESGInt = ISNULL(@fACESGInt,0),
		fCLB = ISNULL(@fCLB,0),
		fCLBInt = ISNULL(@fCLBInt,0),
		Cy.CountryID,
		IDConditionEligibleBenef = B.EligibilityConditionID
	FROM dbo.Un_Convention C
	JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
	JOIN dbo.Mo_Human H ON H.HumanID = B.BeneficiaryID
	LEFT JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
	LEFT JOIN Mo_Country Cy ON Cy.CountryID = A.CountryID
	LEFT JOIN Un_Program P ON P.ProgramID = B.ProgramID
	LEFT JOIN Un_College Col ON Col.CollegeID = B.CollegeID
	LEFT JOIN Mo_Company Co ON Co.CompanyID = B.CollegeID
	WHERE C.ConventionID = @iConventionID
    */
END