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

/********************************************************************************************************************
Copyrights (c) 2011 Gestion Universitas inc.

Code du service		:	psCONV_RapportUnitesAdmissiblesPAE
Nom du service		:	Rapport des unités admissibles/qualifiées aux PAE
But 				: 
Facette			:			CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	

	EXECUTE psCONV_RapportUnitesAdmissiblesPAE 2016, 0 ,'',216028 -- Tous
	EXECUTE psCONV_RapportUnitesAdmissiblesPAE 2020, 0, 'R-20040621018' -- Une seule convention
	EXECUTE psCONV_RapportUnitesAdmissiblesPAE 2014, 1 -- Année demandée uniquement

Paramètres de sortie:	

Historique des modifications:
		Date				Programmeur							Description									Référence
		------------		----------------------------------	-----------------------------------------	------------
		2013-12-11	Pierre-Luc Simard					Création du service	
		2014-05-15	Pierre-Luc Simard					On vérifie si le dernier dépôt contient de l'assurance avant d'ajouter la ristourne		
		2014-07-23	Pierre-Luc Simard					Modifier l'appel de fnCONV_ObtenirRistourneAssurance car on ne valide plus le dernier dépôt.
		2014-07-25	Pierre-Luc Simard					Arrondi des unités à 3 décimales
		2016-12-16	Donald Huppé						jira ti-6044 : Ajout du paramètre @iIDBeneficiaire
        2017-09-27  Pierre-Luc Simard                   Deprecated - Cette procédure n'est plus utilisée
																					
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportUnitesAdmissiblesPAE] 
(
	@iAnnee_Admissible INT,
	@bAnnee_EnCoursUniquement BIT = 0,
	@vcConventionNo VARCHAR(25) = NULL,
	@iIDBeneficiaire INT = NULL
)
AS
BEGIN

    SELECT 1/0
    /*
IF @vcConventionNo = ''
	SET @vcConventionNo = NULL

-- Va chercher l'année de la dernière valeur unitaire saisie
SELECT 
	PV.PlanID,
	Cohorte = MAX(PV.ScholarshipYear) 
INTO #tPlanCohorte
FROM Un_PlanValues PV
JOIN Un_Plan P ON P.PlanID = PV.PlanID
WHERE P.PlanTypeID = 'COL'
GROUP BY PV.PlanID

SELECT 
	C.ConventionID,
	C.ConventionNo,
	RR.vcDescription,
	HB.LastName,
	HB.FirstName,
	C.BeneficiaryID,
	HB.BirthDate,
	C.YearQualif,
	U.NbUnitSousc,
	U.NbUnitPAE,
	iAnneeQualif = C.iAnnee_QualifPremierPAE,
	S.NB_PAE,
	U.RistourneASS,
	S1.mPAE1, 
	S2.mPAE2,
	S3.mPAE3
FROM dbo.Un_Convention C
JOIN (		
	SELECT
		uccs.ConventionID,
		ucs.ConventionStateID
	FROM Un_ConventionState	ucs
	INNER JOIN Un_ConventionConventionState uccs ON ucs.ConventionStateID = uccs.ConventionStateID 
	INNER JOIN (	
		SELECT
			ccs.ConventionID, 
			dtDateStatut = MAX(ccs.StartDate)  
		FROM
			dbo.Un_ConventionConventionState ccs
			INNER JOIN	dbo.Un_ConventionState cs
				ON cs.ConventionStateID = ccs.ConventionStateID 
		WHERE ccs.StartDate <= GETDATE()
		GROUP BY
			ccs.ConventionID
		) AS tmp
			ON tmp.ConventionID = uccs.ConventionID AND tmp.dtDateStatut = uccs.StartDate
	) CS ON CS.ConventionID = C.ConventionID
JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID
JOIN Un_Plan P ON P.PlanID = C.PlanID
JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
JOIN (
	SELECT 
		C.ConventionID,
		NbUnitSousc = CAST(SUM(U.UnitQty) AS DECIMAL(10,3)),
		NbUnitPAE = CAST(SUM(U.UnitQty * dbo.fnCONV_ObtenirFacteurConversion(C.PlanID, M.ModalDate, ISNULL(C.iAnnee_QualifPremierPAE, PC.Cohorte))) AS DECIMAL(10,3)),
		RistourneAss = CAST(SUM(U.UnitQty * dbo.fnCONV_ObtenirRistourneAssurance(U.ModalID, ISNULL(C.iAnnee_QualifPremierPAE, PC.Cohorte), U.WantSubscriberInsurance)) AS MONEY)  
	FROM dbo.Un_Convention C
	JOIN #tPlanCohorte PC ON PC.PlanID = C.PlanID
	JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
	JOIN Un_Modal M ON M.ModalID = U.ModalID
	GROUP BY 
		C.ConventionID
	) U ON U.ConventionID = C.ConventionID
LEFT JOIN (
	SELECT
		S.ConventionID,
		NB_PAE = MAX(S.ScholarshipNo)
	FROM Un_Scholarship S
	WHERE S.ScholarshipStatusID = 'PAD'
	GROUP BY 
		S.ConventionID
	) S ON S.ConventionID = C.ConventionID
LEFT JOIN (
	SELECT
		S.ConventionID,
		mPAE1 = S.ScholarshipAmount
	FROM Un_Scholarship S
	WHERE S.ScholarshipNo = 1
	) S1 ON S1.ConventionID = C.ConventionID
LEFT JOIN (
	SELECT
		S.ConventionID,
		mPAE2 = S.ScholarshipAmount 
	FROM Un_Scholarship S
	WHERE S.ScholarshipNo = 2
	) S2 ON S2.ConventionID = C.ConventionID
LEFT JOIN (
	SELECT
		S.ConventionID,
		mPAE3 = S.ScholarshipAmount 
	FROM Un_Scholarship S
	WHERE S.ScholarshipNo = 3
	) S3 ON S3.ConventionID = C.ConventionID
WHERE P.PlanTypeID = 'COL'
	AND CS.ConventionStateID = 'REE'
	AND ISNULL(S.NB_PAE,0) < 3
	--AND dbo.fnCONV_ObtenirStatutConventionEnDate(C.ConventionID, GETDATE()) = 'REE'
	AND ((@bAnnee_EnCoursUniquement = 0 AND ISNULL(S.NB_PAE,0) > 0) -- Permet d'aller chercher les cas ayant eu un PAE sans être rendu à leur année d'admissibilité
		OR 
		(((@bAnnee_EnCoursUniquement = 0 AND C.YearQualif <= @iAnnee_Admissible)
			OR (@bAnnee_EnCoursUniquement <> 0 AND C.YearQualif = @iAnnee_Admissible))))
	AND C.ConventionNo = ISNULL(@vcConventionNo, C.ConventionNo)
	AND C.BeneficiaryID = ISNULL(@iIDBeneficiaire, C.BeneficiaryID)
	
	--AND U.NbUnitSousc <> U.NbUnitPAE  -- Pour avoir juste ceux ayant eu une conversion d'unités
	--AND C.ConventionID = 244812		
    */
END