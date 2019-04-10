/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: RP_UN_DecaissementIQEE
Nom du service		: Rapport décaissement IQEE
But 				: Les finances nous demandent de séparer le montant de l’impôt spécial calculé en deux (IQEE et IQEE+)
					  afin de leur permettre de préparer les décaissements requis pour le chèque qui devra être envoyé à 
					  Revenu Québec au moment que nous enverrons les fichiers des transactions contenant les impôts spéciaux.  
					  Ces mêmes montants doivent être présentés dans un nouveau rapport de décaissement
Facette				: IQEE
Référence			: IQEE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						@ConnectID					id de connection		
						@StartDate					date debut rapport	
						@EndDate 					date fin du rapport

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------

Exemple utilisation:																					
	- modification courriel
		EXEC RP_UN_DecaissementIQEE 1,'2012-01-01','2012-12-31','2011-01-01','2011-12-31'
			
TODO:

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2012-08-09		Eric Michaud						Création du service					
		2012-09-05		Eric Michaud						Ajout pour corection des mmq sans cbq
		2012-11-15		Stéphane Barbeau					Ajout des requêtes pour tenir compte des réponses aux déclarations des impôts spéciaux
		2012-12-05		Stéphane Barbeau					Ajout des requêtes pour tenir compte des erreurs aux déclarations des impôts spéciaux
        2017-09-21      Steeve Picard                       Simplification des requêtes
        2018-03-20      Steeve Picard                       Ajout d'un paramètre «@StartDate» à la fonction «fntOPER_Active»
*********************************************************************************************************************/
CREATE PROCEDURE dbo.RP_UN_DecaissementIQEE (
	@ConnectID INTEGER,
	@StartDate_oper DATE,
	@EndDate_oper DATE,
	@StartDate_even DATETIME,
	@EndDate_even DATETIME)
AS
BEGIN

	SET @EndDate_even =  @EndDate_even + ' 23:59:59.000'  -- Chaque année, nous avons des événements en date du 31 décembre à 23:59:59.000. Il faut concaténer ' 23:59:59.000'

---- Pour les demandes
    ;WITH CTE_ConvOper AS (
        SELECT 
            CO.ConventionID,  CO.ConventionOperID, OperDate = CAST(O.OperDate AS DATE), CO.ConventionOperTypeID, CO.ConventionOperAmount
          FROM dbo.fntOPER_Active(@StartDate_oper, @EndDate_oper) O
               JOIN dbo.Un_ConventionOper CO ON CO.OperID = O.OperID
         WHERE O.OperDate BETWEEN @StartDate_oper AND DATEADD(DAY, 1, @EndDate_oper)
           AND O.OperTypeID = 'IQE'
           AND CO.ConventionOperTypeID IN ('CBQ', 'MMQ', 'MIM')
    )
    SELECT GrRegime = RR.vcDescription,
		   P.OrderOfPlanInReport,
           C.ConventionNo,
		   SubscriberName = RTRIM(SH.LastName) + ', ' + RTRIM(SH.FirstName),
		   OperDate, 
           mSolde_IQEE_Base = SUM(IQEE_Base), 
           mSolde_IQEE_Majore = SUM(IQEE_Majore), 
           Montant_Interets = SUM(Interets),
		   Total = SUM(IQEE_Base + IQEE_Majore)
    FROM (
		---- Pour les demandes  CBQ et MMQ
		SELECT 
			OperDate = isNUll(CBQ.OperDate, MMQ.OperDate),
            S.iID_Convention,
			--S.dtDate_Evenement, -- Pour débogage seulement
			IQEE_Base = ISNULL(CBQ.ConventionOperAmount, 0),--Montant_CBQ =1 
		    IQEE_Majore = ISNULL(MMQ.ConventionOperAmount, 0),
		    Interets = 0 --isnull(S.mMontant_Interets,0.00)
		FROM 
            tblIQEE_ImpotsSpeciaux S
		    LEFT JOIN CTE_ConvOper CBQ ON CBQ.ConventionOperID = S.iID_Paiement_Impot_CBQ
		    LEFT JOIN CTE_ConvOper MMQ ON MMQ.ConventionOperID = S.iID_Paiement_Impot_MMQ
		WHERE 0=0
			AND S.dtDate_Evenement BETWEEN  @StartDate_even AND  @EndDate_even
		    AND ISNULL(CBQ.ConventionOperID, MMQ.ConventionOperID) IS NOT NULL
		    --AND (CO_CBQ.ConventionOperAmount < 0  OR CO_MMQ.ConventionOperAmount < 0 )
				
	    UNION ALL
		---- Pour les réponses  CBQ et MMQ
		SELECT 
			OperDate = isNUll(CBQ.OperDate, MMQ.OperDate),
            S.iID_Convention,
			--S.dtDate_Evenement, -- Pour débogage seulement
			IQEE_Base = ISNULL(CBQ.ConventionOperAmount, 0),--Montant_CBQ =1 
		    IQEE_Majore = ISNULL(MMQ.ConventionOperAmount, 0),
		    Interets = 0 --isnull(S.mMontant_Interets,0.00)
		FROM 
            tblIQEE_ReponsesImpotsSpeciaux RIS
    		JOIN tblIQEE_ImpotsSpeciaux S ON RIS.iID_Impot_Special_IQEE = S.iID_Impot_Special
		    LEFT JOIN CTE_ConvOper CBQ ON CBQ.ConventionOperID = RIS.iID_Paiement_Impot_CBQ
		    LEFT JOIN CTE_ConvOper MMQ ON MMQ.ConventionOperID = RIS.iID_Paiement_Impot_MMQ
		WHERE 0=0
			AND S.dtDate_Evenement BETWEEN  @StartDate_even AND  @EndDate_even
		    AND ISNULL(CBQ.ConventionOperID, MMQ.ConventionOperID) IS NOT NULL
			--AND (CO_CBQ.ConventionOperAmount < 0 OR CO_MMQ.ConventionOperAmount < 0)

    	UNION ALL
		---- Pour les erreurs CBQ et MMQ
		SELECT 
			OperDate = isNUll(CBQ.OperDate, MMQ.OperDate),
            S.iID_Convention,
			--S.dtDate_Evenement, -- Pour débogage seulement
			--mSolde_IQEE_Base = SUM(ISNULL(CBQ.ConventionOperAmount, 0.00)),--Montant_CBQ =1 
		 --   mSolde_IQEE_Majore = SUM(ISNULL(MMQ.ConventionOperAmount, 0.00)),
			IQEE_Base = ISNULL(CBQ.ConventionOperAmount, 0),--Montant_CBQ =1 
		    IQEE_Majore = ISNULL(MMQ.ConventionOperAmount, 0),
		    Interets = 0 --isnull(S.mMontant_Interets,0.00)
		FROM 
            tblIQEE_ImpotsSpeciaux S
		    LEFT JOIN CTE_ConvOper CBQ ON CBQ.ConventionOperID = S.iID_Transaction_Convention_CBQ_Renversee
		    LEFT JOIN CTE_ConvOper MMQ ON MMQ.ConventionOperID = S.iID_Transaction_Convention_MMQ_Renversee
		WHERE 0=0
			AND S.dtDate_Evenement BETWEEN  @StartDate_even AND  @EndDate_even
		    AND ISNULL(CBQ.ConventionOperID, MMQ.ConventionOperID) IS NOT NULL
		    --AND (CO_CBQ.ConventionOperAmount < 0  OR CO_MMQ.ConventionOperAmount < 0 )

        ) S
	    JOIN dbo.Un_Convention C ON C.ConventionID = S.iID_Convention
	    JOIN UN_PLAN P ON P.PlanID = C.PlanID
	    JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
	    JOIN dbo.Mo_Human SH ON SH.HumanID = C.SubscriberID
	GROUP BY 
        RR.vcDescription,
		OrderOfPlanInReport,
		OperDate,
		C.ConventionNo,
		RTRIM(SH.LastName) + ', ' + RTRIM(SH.FirstName)
	ORDER BY 
        RR.vcDescription,
		OrderOfPlanInReport,
		C.ConventionNo,
		SubscriberName,
		OperDate
END
