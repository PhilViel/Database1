/********************************************************************************************************************
Copyrights (c) 2017 Gestion Universitas inc.

Code du service		:	psCONV_RapportConventionsAdmissiblesPAE
Nom du service		:	Rapport des conventions admissibles aux PAE
But 				: 
Facette			:		CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	

	EXECUTE psCONV_RapportConventionsAdmissiblesPAE 
	EXECUTE psCONV_RapportConventionsAdmissiblesPAE_Convention 'X-20100319004' -- Pour une convention

Paramètres de sortie:	

Historique des modifications:
		Date				Programmeur							Description									Référence
		------------		----------------------------------	-----------------------------------------	------------
		2017-11-28	        Pierre-Luc Simard					Création du service	
        2017-12-08          Pierre-Luc Simard                   La fonction fntCONV_ObtenirConventionAdmissiblePAE gère maintenant 
                                                                les Individuel et les autres critères donc ils ont été retirés
        2017-12-11          Pierre-Luc Simard                   Ajout de YearQualif, SubscriberID, BeneficiaryID, BirthDate, DeathDate et bDevancement_AdmissibilitePAE
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportConventionsAdmissiblesPAE] 
(
	@vcConventionNo VARCHAR(25) = NULL	
)
AS
BEGIN

    DECLARE @iID_Convention INT

    DECLARE @StartTimer datetime = GetDate(),               
            @QueryTimer datetime = GetDate(),                           
            @ElapseTime datetime

    IF ISNULL(@vcConventionNo, '') <> ''
	    SELECT 
            @iID_Convention = C.ConventionID
        FROM Un_Convention C
        WHERE C.ConventionNo = @vcConventionNo

    SET @ElapseTime = GetDate() - @QueryTimer
    PRINT '   @iID_Convention (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

    SET @QueryTimer = GetDate()

    -- Récupèrer les valeurs pour les conventions collectives admissibles au PAE
    SELECT 
        CD.ConventionID,
        CD.ConventionNo,
        CD.NB_Unites_Convention,
        CD.bRIN_Verse,
        CD.Depot,
        CD.MontantSouscrit,
        CD.Taux_Avancement,
        CD.NB_Unites_PAE_Verse,
        CD.NB_Unites_Disponibles_PAE,
        CD.Nb_Unites_Disponibles_PAE_Convertie,
        CD.RistourneAss,
        CD.QuotePart  
    INTO #tConvColAdmPAE
    FROM dbo.fntCONV_ObtenirValeursPAECollectifDisponible(NULL) CD
  
    SET @ElapseTime = GetDate() - @QueryTimer
    PRINT '   fntCONV_ObtenirValeursPAECollectifDisponible (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'
     
    SET @QueryTimer = GetDate()
    
    -- Récupère la liste des toutes les conventions REE et indique si elles sont admissibles au PAE
    SELECT 
        C.ConventionID,
        C.ConventionNo,
        C.YearQualif,
        C.SubscriberID,
        C.BeneficiaryID,
        HB.BirthDate,
        HB.DeathDate,
        bDevancement_AdmissibilitePAE = ISNULL(B.bDevancement_AdmissibilitePAE, 0),
        C.PlanID,
        P.PlanDesc,
        AdmissiblePAE = CASE WHEN CA.ConventionID IS NULL THEN 0 ELSE 1 END 
    INTO #tConv
    FROM dbo.Un_Convention C
    JOIN un_Plan P ON P.PlanID = C.PlanID
    JOIN fntCONV_ObtenirStatutConventionEnDate_PourTous(NULL, NULL) CS ON CS.ConventionID = C.ConventionID
    LEFT JOIN dbo.fntCONV_ObtenirConventionAdmissiblePAE(@iID_Convention) CA ON CA.ConventionID = C.ConventionID
    JOIN Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
    JOIN Mo_Human HB ON HB.HumanID = B.BeneficiaryID
    WHERE C.ConventionID = ISNULL(@iID_Convention, C.ConventionID)
        AND CS.ConventionStateID = 'REE'
    
    SET @ElapseTime = GetDate() - @QueryTimer
    PRINT '   fntCONV_ObtenirConventionAdmissiblePAE (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'
     
    SET @QueryTimer = GetDate()
     
    SELECT 
		CO.ConventionID,			
		IQEE = SUM(CASE WHEN CO.ConventionOperTypeID = 'CBQ' THEN CO.ConventionOperAmount ELSE 0 END),
		IQEEMajore = SUM(CASE WHEN CO.ConventionOperTypeID = 'MMQ' THEN CO.ConventionOperAmount ELSE 0 END),
		INM = SUM(CASE WHEN CO.ConventionOperTypeID = 'INM' THEN CO.ConventionOperAmount ELSE 0 END),
        ITR = SUM(CASE WHEN CO.ConventionOperTypeID = 'ITR' THEN CO.ConventionOperAmount ELSE 0 END),
		IBC = SUM(CASE WHEN CO.ConventionOperTypeID = 'IBC' THEN CO.ConventionOperAmount ELSE 0 END),
		ICQ = SUM(CASE WHEN CO.ConventionOperTypeID = 'ICQ' THEN CO.ConventionOperAmount ELSE 0 END),
		III = SUM(CASE WHEN CO.ConventionOperTypeID = 'III' THEN CO.ConventionOperAmount ELSE 0 END),
		IIQ = SUM(CASE WHEN CO.ConventionOperTypeID = 'IIQ' THEN CO.ConventionOperAmount ELSE 0 END),
		IMQ = SUM(CASE WHEN CO.ConventionOperTypeID = 'IMQ' THEN CO.ConventionOperAmount ELSE 0 END),
		MIM = SUM(CASE WHEN CO.ConventionOperTypeID = 'MIM' THEN CO.ConventionOperAmount ELSE 0 END),
		IQI = SUM(CASE WHEN CO.ConventionOperTypeID = 'IQI' THEN CO.ConventionOperAmount ELSE 0 END),
		INS = SUM(CASE WHEN CO.ConventionOperTypeID = 'INS' THEN CO.ConventionOperAmount ELSE 0 END),
		ISPlus = SUM(CASE WHEN CO.ConventionOperTypeID = 'IS+' THEN CO.ConventionOperAmount ELSE 0 END),
		IST = SUM(CASE WHEN CO.ConventionOperTypeID = 'IST' THEN CO.ConventionOperAmount ELSE 0 END)
	INTO #tConv_Oper
    FROM Un_ConventionOper CO 
    JOIN Un_Oper O ON CO.OperID = O.OperID
    WHERE O.OperDate <= GETDATE()
	    AND CO.ConventionOperTypeID IN ('CBQ','MMQ','IBC','ICQ','III','IIQ','IMQ','INS','IS+','IST','INM','ITR','MIM','IQI')
	GROUP BY CO.ConventionID
	  
    SET @ElapseTime = GetDate() - @QueryTimer
    PRINT '   #tConv_Oper (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'
     
    SET @QueryTimer = GetDate()

	SELECT
		CE.ConventionID,
		SCEE = SUM(CE.fCESG),
		SCEEPlus = SUM(CE.fACESG),
		BEC = SUM(CE.fCLB)
    INTO #tConv_SCEE
	FROM Un_CESP CE
	JOIN Un_Oper O ON O.OperID = CE.OperID
	WHERE O.OperDate <= GETDATE()
	GROUP BY CE.ConventionID
	
    SET @ElapseTime = GetDate() - @QueryTimer
    PRINT '   #tConv_SCEE (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'
     
    SET @QueryTimer = GetDate()

    SELECT 
        C.ConventionID,
        C.ConventionNo,
        C.YearQualif,
        C.SubscriberID,
        C.BeneficiaryID,
        C.BirthDate,
        C.DeathDate,
        C.bDevancement_AdmissibilitePAE,
        C.PlanID,
        C.PlanDesc,
        C.AdmissiblePAE,
        CD.NB_Unites_Convention,
        CD.bRIN_Verse,
        CD.Depot,
        CD.MontantSouscrit,
        CD.Taux_Avancement,
        NB_PAE_Verse = ISNULL(S.NB_PAE_Verse, 0),
        CD.NB_Unites_PAE_Verse,
        CD.NB_Unites_Disponibles_PAE,
        CD.Nb_Unites_Disponibles_PAE_Convertie,
        CD.RistourneAss,
        CD.QuotePart,    
        SCEE = ISNULL(CE.SCEE, 0),
        SCEEPlus = ISNULL(CE.SCEEPlus, 0),
        BEC = ISNULL(CE.BEC, 0),
        IQEE = ISNULL(CO.IQEE, 0),
        IQEEMajore = ISNULL(CO.IQEEMajore, 0),
        -- Revenus sur subventions
            IBC = ISNULL(CO.IBC, 0),
            INS = ISNULL(CO.INS, 0),
            ISPlus = ISNULL(CO.ISPlus, 0),
            IST = ISNULL(CO.IST, 0), 
            ICQ = ISNULL(CO.ICQ, 0),
            MIM = ISNULL(CO.MIM, 0),
            IIQ = ISNULL(CO.IIQ, 0),
            III = ISNULL(CO.III, 0),
            IQI = ISNULL(CO.IQI, 0),
            IMQ = ISNULL(CO.IMQ, 0),
        -- Revenus d'épargne
            INM = ISNULL(CO.INM, 0),
            ITR = ISNULL(CO.ITR, 0),
        /*Total_Disponible =     
            ISNULL(CD.RistourneAss, 0)
            + ISNULL(CD.QuotePart, 0)
            + ISNULL(CE.SCEE, 0)
            + ISNULL(CE.SCEEPlus, 0)
            + ISNULL(CE.BEC, 0)
            + ISNULL(CO.IQEE, 0)
            + ISNULL(CO.IQEEMajore, 0)
            + ISNULL(CO.IBC, 0)
            + ISNULL(CO.INS, 0)
            + ISNULL(CO.ISPlus, 0)
            + ISNULL(CO.IST, 0)
            + ISNULL(CO.ICQ, 0)
            + ISNULL(CO.MIM, 0)
            + ISNULL(CO.IIQ, 0)
            + ISNULL(CO.III, 0)
            + ISNULL(CO.IQI, 0)
            + ISNULL(CO.IMQ, 0)
            + ISNULL(CO.INM, 0)
            + ISNULL(CO.ITR, 0),*/
        Subvention_Negative = 
            CASE WHEN 
                ISNULL(CE.SCEE, 0) < 0
                OR ISNULL(CE.SCEEPlus, 0) < 0
                OR ISNULL(CE.BEC, 0) < 0
                OR ISNULL(CO.IQEE, 0) < 0
                OR ISNULL(CO.IQEEMajore, 0) < 0
            THEN 1 
            ELSE 0 
            END,
        ARI_A_Faire = 
            CASE WHEN 
                ISNULL(CO.IBC, 0) < 0
                OR ISNULL(CO.INS, 0) < 0
                OR ISNULL(CO.ISPlus, 0) < 0
                OR ISNULL(CO.IST, 0) < 0
                OR ISNULL(CO.ICQ, 0) < 0
                OR ISNULL(CO.MIM, 0) < 0
                OR ISNULL(CO.IIQ, 0) < 0
                OR ISNULL(CO.III, 0) < 0
                OR ISNULL(CO.IQI, 0) < 0
                OR ISNULL(CO.IMQ, 0) < 0
                OR ISNULL(CO.INM, 0) < 0
                OR ISNULL(CO.ITR, 0) < 0
            THEN 1 
            ELSE 0 
            END,
        Montant_ARI_EAFB = 
            CASE WHEN 
                ISNULL(CO.IBC, 0)
                + ISNULL(CO.INS, 0)
                + ISNULL(CO.ISPlus, 0)
                + ISNULL(CO.IST, 0)
                + ISNULL(CO.ICQ, 0)
                + ISNULL(CO.MIM, 0)
                + ISNULL(CO.IIQ, 0)
                + ISNULL(CO.III, 0)
                + ISNULL(CO.IQI, 0)
                + ISNULL(CO.IMQ, 0)
                + ISNULL(CO.INM, 0)
                + ISNULL(CO.ITR, 0)    
                < 0 
            THEN 
                -(ISNULL(CO.IBC, 0)
                + ISNULL(CO.INS, 0)
                + ISNULL(CO.ISPlus, 0)
                + ISNULL(CO.IST, 0)
                + ISNULL(CO.ICQ, 0)
                + ISNULL(CO.MIM, 0)
                + ISNULL(CO.IIQ, 0)
                + ISNULL(CO.III, 0)
                + ISNULL(CO.IQI, 0)
                + ISNULL(CO.IMQ, 0)
                + ISNULL(CO.INM, 0)
                + ISNULL(CO.ITR, 0)) 
            ELSE 0 
            END,
        Total_Disponible =     
            ISNULL(CD.RistourneAss, 0)
            + ISNULL(CD.QuotePart, 0)
            + CASE WHEN ISNULL(CE.SCEE, 0) < 0 THEN 0 ELSE ISNULL(CE.SCEE, 0) END 
            + CASE WHEN ISNULL(CE.SCEEPlus, 0) < 0 THEN 0 ELSE ISNULL(CE.SCEEPlus, 0) END 
            + CASE WHEN+ ISNULL(CE.BEC, 0) < 0 THEN 0 ELSE + ISNULL(CE.BEC, 0) END 
            + CASE WHEN ISNULL(CO.IQEE, 0) < 0 THEN 0 ELSE ISNULL(CO.IQEE, 0) END 
            + CASE WHEN ISNULL(CO.IQEEMajore, 0) < 0 THEN 0 ELSE ISNULL(CO.IQEEMajore, 0) END 
            + ISNULL(CO.IBC, 0)
            + ISNULL(CO.INS, 0)
            + ISNULL(CO.ISPlus, 0)
            + ISNULL(CO.IST, 0)
            + ISNULL(CO.ICQ, 0)
            + ISNULL(CO.MIM, 0)
            + ISNULL(CO.IIQ, 0)
            + ISNULL(CO.III, 0)
            + ISNULL(CO.IQI, 0)
            + ISNULL(CO.IMQ, 0)
            + ISNULL(CO.INM, 0)
            + ISNULL(CO.ITR, 0)
            + -- ARI provenant du compte EAFB pour compenser les négatifs
            CASE WHEN 
                ISNULL(CO.IBC, 0)
                + ISNULL(CO.INS, 0)
                + ISNULL(CO.ISPlus, 0)
                + ISNULL(CO.IST, 0)
                + ISNULL(CO.ICQ, 0)
                + ISNULL(CO.MIM, 0)
                + ISNULL(CO.IIQ, 0)
                + ISNULL(CO.III, 0)
                + ISNULL(CO.IQI, 0)
                + ISNULL(CO.IMQ, 0)
                + ISNULL(CO.INM, 0)
                + ISNULL(CO.ITR, 0)    
                < 0 
            THEN 
                -(ISNULL(CO.IBC, 0)
                + ISNULL(CO.INS, 0)
                + ISNULL(CO.ISPlus, 0)
                + ISNULL(CO.IST, 0)
                + ISNULL(CO.ICQ, 0)
                + ISNULL(CO.MIM, 0)
                + ISNULL(CO.IIQ, 0)
                + ISNULL(CO.III, 0)
                + ISNULL(CO.IQI, 0)
                + ISNULL(CO.IMQ, 0)
                + ISNULL(CO.INM, 0)
                + ISNULL(CO.ITR, 0)) 
            ELSE 0 
            END 
    FROM #tConv C 
    LEFT JOIN #tConvColAdmPAE CD ON CD.ConventionID = C.ConventionID
    LEFT JOIN #tConv_Oper CO ON CO.ConventionID = C.ConventionID
    LEFT JOIN #tConv_SCEE CE ON CE.ConventionID = C.ConventionID 
    LEFT JOIN (
        -- Calcul des unités déjà versés en PAE
        SELECT 
            S.ConventionID, 
            NB_PAE_Verse = COUNT(S.ScholarshipID)
        FROM Un_Scholarship S
        WHERE S.ScholarshipStatusID = 'PAD' --IN ('24Y','25Y','DEA','PAD','REN')
        GROUP BY S.ConventionID
        ) S ON S.ConventionID = C.ConventionID

    SET @ElapseTime = GetDate() - @QueryTimer
    PRINT '   Fin (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

    SET @ElapseTime = GetDate() - @StartTimer
    PRINT '   Total (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'
     
END