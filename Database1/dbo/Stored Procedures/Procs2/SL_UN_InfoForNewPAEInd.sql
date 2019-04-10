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
Nom                 :	SL_UN_InfoForNewPAEInd
Description         :	Retourne les données nécessaires pour un nouveau PAE individuels
Valeurs de retours  :	Dataset contenant les données
Note                :	ADX0000593	IA	2005-01-06	Bruno Lapointe			Création
								ADX0001259	BR	2005-02-03	Bruno Lapointe		Retour du champs EligibilityConditionID
								ADX0001007	IA	2006-05-29	Alain Quirion		Ajout et suppression de champs pour la PCEE 4.3
								ADX0002426	BR	2007-05-23	Bruno Lapointe		Gestion de la table Un_CESP.
												2010-01-18	Jean-F. Gauthier	Ajout du champ EligibilityConditionID (table Un_Beneficiary) en retour
                                                2017-09-27  Pierre-Luc Simard   Deprecated - Cette procédure n'est plus utilisée
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_InfoForNewPAEInd] (
	@ConventionID INTEGER) -- ID unique de la convention sur laquel on veut faire un PAE ind
AS
BEGIN
	DECLARE 
		@fCESG MONEY,
		@fACESG MONEY,
		@fCLB MONEY

	SELECT 
		@fCESG = ISNULL(SUM(fCESG),0), 		--SCEE
		@fACESG = ISNULL(SUM(fACESG),0), 	--SCEE+
		@fCLB = ISNULL(SUM(fCLB),0)		--BEC
	FROM Un_CESP
	WHERE ConventionID = @ConventionID
	
	SELECT
		C.ConventionID,
		B.CollegeID,
		CollegeName = ISNULL(Cl.CompanyName,''),
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
		Interest = 
			ISNULL(
				SUM	(
					CASE 
						WHEN CO.ConventionOperTypeID= 'INM' THEN CO.ConventionOperAmount
					ELSE	0
					END
					),0)*-1,
		fTINInt =
			ISNULL(
				SUM	(
					CASE 
						WHEN CO.ConventionOperTypeID = 'ITR' THEN CO.ConventionOperAmount
					ELSE	0
					END
					),0)*-1,
		fCESGInt =
			ISNULL(
				SUM	(
					CASE 
						WHEN CO.ConventionOperTypeID = 'INS' THEN CO.ConventionOperAmount
					ELSE	0
					END
					),0)*-1,
		fTINPCEEInt =
			ISNULL(
				SUM	(
					CASE 
						WHEN CO.ConventionOperTypeID = 'IST' THEN CO.ConventionOperAmount
					ELSE	0
					END
					),0)*-1,
		fACESGInt =
			ISNULL(
				SUM	(
					CASE 
						WHEN CO.ConventionOperTypeID = 'IS+' THEN CO.ConventionOperAmount
					ELSE	0
					END
					),0)*-1,
		fCLBInt =
			ISNULL(
				SUM	(
					CASE 
						WHEN CO.ConventionOperTypeID = 'IBC' THEN CO.ConventionOperAmount
					ELSE	0
					END
					),0)*-1,
		fCESG = ISNULL(@fCESG,0)*-1,
		fACESG = ISNULL(@fACESG,0)*-1,
		fCLB = ISNULL(@fCLB,0)*-1,
		IDConditionEligibleBenef = B.EligibilityConditionID
	FROM dbo.Un_Convention C
	JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
	LEFT JOIN Un_ConventionOper CO ON CO.ConventionID = C.ConventionID
	LEFT JOIN Un_Program P ON P.ProgramID = B.ProgramID
	LEFT JOIN Un_College Col ON Col.CollegeID = B.CollegeID
	LEFT JOIN Mo_Company Cl ON Cl.CompanyID = B.CollegeID
	WHERE C.ConventionID = @ConventionID
	GROUP BY
		C.ConventionID,
		B.CollegeID,
		Cl.CompanyName,
		B.ProgramID,
		P.ProgramDesc,
		B.StudyStart,
		B.ProgramLength,
		B.ProgramYear,
		B.RegistrationProof,
		B.SchoolReport,
		B.EligibilityQty,
		B.CaseOfJanuary,
		Col.EligibilityConditionID,
		B.EligibilityConditionID
		
END