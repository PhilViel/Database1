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
Nom                 :	psTEMP_RapportConvEtape4SoldeIQEENegatif

Description         :	Cette sp reprend la Procédure SL_UN_BatchScholarship retournant les données pour remplir la grille de visualisation de l’outil de 
								gestion des paiements de bourses (PAE).  
						Elle valide les convention qui sont à l'étape 4 et dont un des solde d'IQEE est négatif.
						Le but du rapport est de faire un ARI pour combler le solde négatif avant de faire le PAE
						Sinon, l'IQEE n'est pas décaisser dans la PAE à cause de la mesure temporaire de la sp psTEMP_ObtenirMontantIQEEPourPAE
Valeurs de retours  :	Dataset :

Note                :	2012-10-30	Donald Huppé	Création
                        2017-09-27  Pierre-Luc Simard   Deprecated - Cette procédure n'est plus utilisée
								
exec psTEMP_RapportConvEtape4SoldeIQEENegatif 3
								
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psTEMP_RapportConvEtape4SoldeIQEENegatif] 
	(
	@iEtape int
	)
	
AS
BEGIN

    SELECT 1/0
    /*
	DECLARE
		@UserID INTEGER

	CREATE TABLE #ScholarshipToPAE (
		ScholarshipID INTEGER PRIMARY KEY)

	INSERT INTO #ScholarshipToPAE
		SELECT DISTINCT
			S.ScholarshipID
		FROM Un_Scholarship S
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
	into #tmp
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
	where SSt.iScholarshipStep = @iEtape
	DROP TABLE #ScholarshipToPAE
	
	select 
		t.ConventionNo,

		CBQ = sum(case when co.conventionopertypeid = 'CBQ' then ConventionOperAmount else 0 end ),
		MMQ = sum(case when co.conventionopertypeid = 'MMQ' then ConventionOperAmount else 0 end ),
		
		ICQ = sum(case when co.conventionopertypeid = 'ICQ' then ConventionOperAmount else 0 end ),
		III = sum(case when co.conventionopertypeid = 'III' then ConventionOperAmount else 0 end ),
		IIQ = sum(case when co.conventionopertypeid = 'IIQ' then ConventionOperAmount else 0 end ),
		IMQ = sum(case when co.conventionopertypeid = 'IMQ' then ConventionOperAmount else 0 end ),
		
		MIM = sum(case when co.conventionopertypeid = 'MIM' then ConventionOperAmount else 0 end ),
		IQI = sum(case when co.conventionopertypeid = 'IQI' then ConventionOperAmount else 0 end ),
		
		Negatif = CASE WHEN 
				sum(case when co.conventionopertypeid = 'ICQ' then ConventionOperAmount else 0 end ) < 0
				or sum(case when co.conventionopertypeid = 'III' then ConventionOperAmount else 0 end ) < 0
				or sum(case when co.conventionopertypeid = 'IIQ' then ConventionOperAmount else 0 end ) < 0
				or sum(case when co.conventionopertypeid = 'IMQ' then ConventionOperAmount else 0 end ) < 0
				then 1
				else 0 end
		
	FROM 
		#tmp t
		JOIN dbo.Un_Convention c on t.ConventionID = c.ConventionID
		join Un_ConventionOper co ON c.ConventionID = co.ConventionID
	group BY
		t.ConventionNo
	having
	/*
		(	-- Il reste de la subvention
			sum(case when co.conventionopertypeid = 'CBQ' then ConventionOperAmount else 0 end )>0
			or
			sum(case when co.conventionopertypeid = 'MMQ' then ConventionOperAmount else 0 end )>0
			OR
			sum(case when co.conventionopertypeid = 'MIM' then ConventionOperAmount else 0 end )>0
		)
		AND 
		*/
		(	-- avec un solde de rendement négatif
			sum(case when co.conventionopertypeid = 'ICQ' then ConventionOperAmount else 0 end ) < 0
			or sum(case when co.conventionopertypeid = 'III' then ConventionOperAmount else 0 end ) < 0
			or sum(case when co.conventionopertypeid = 'IIQ' then ConventionOperAmount else 0 end ) < 0
			or sum(case when co.conventionopertypeid = 'IMQ' then ConventionOperAmount else 0 end ) < 0
		)
	*/			
END