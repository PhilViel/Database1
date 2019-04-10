/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service                   : psOPER_ObtenirListePEE
Nom du service                    : Liste des PEEs émis
But                               : Retourner la liste des conventions ayant eu un PEE
Facette                                 : OPER

Paramètres d’entrée        :    
    Paramètre                    Description
    --------------------    ------------------------------------------------------------------------------------------
    @StartDate              Date de début de la période visée. Si omis, la date du 1er jour du mois sera utilisé
    @EndDate                Date de fin de la période visée. Si omis, la date du jour sera utilisé

Exemple d’appel     :   EXEC dbo.psOPER_ObtenirListePEE '1950-10-22', '2215-11-10'
                        EXEC dbo.psOPER_ObtenirListePEE @ConventionNo = 'I-20040108001'
                        EXEC dbo.psOPER_ObtenirListePEE @SubscriberID = 206036
                        EXEC dbo.psOPER_ObtenirListePEE @LastName = 'B', @FirstName = 'Ben'

Historique des modifications:
    Date        Programmeur             Description
    ----------  --------------------    -----------------------------------------------------------------------
    2017-02-13  Steve Bélanger          Création du service   
    2017-02-23  Steve Bélanger          Ne pas retourner toutes les conventions quand le numéro de convention n'est pas valide
    2017-06-05  Steeve Picard           Optimisation en remplaçant les CTE par des tables temporaires
	2017-10-12	Donald Huppé			jira ti-9612 : Ajout de la cohorte
**********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_ObtenirListePEE] (
    @StartDate     DATE = NULL, --'2015-01-01',
    @EndDate       DATE = NULL,
    @ConventionNo  VARCHAR(15) = NULL,
    @SubscriberID  INT = NULL,
    @LastName VARCHAR(75) = NULL,
    @FirstName VARCHAR(75) = NULL
) AS 
BEGIN
     
     DECLARE  @ConventionID INT = 0
       
     IF @ConventionNo IS NOT NULL
          SET @ConventionID = (SELECT ConventionID FROM dbo.Un_Convention WHERE ConventionNo = @ConventionNo)


     IF @EndDate IS NULL
       SET @EndDate = GETDATE()

       IF @StartDate IS NULL
       SET @StartDate =  '0001-01-01'

    IF OBJECT_ID('tempDB..#CTE_OperPEE') IS NOT NULL
        DROP TABLE #CTE_OperPEE

    SELECT 
        O.OperID, O.OperDate, O.OperTypeID, OC.OperSourceID
    INTO 
        #CTE_OperPEE
    FROM 
        dbo.Un_Oper O
        LEFT JOIN dbo.Un_OperCancelation OC ON OC.OperID = O.OperID                 
    WHERE 
        O.OperDate BETWEEN @StartDate AND @EndDate 
        AND O.OperTypeID = 'PEE'          

    IF OBJECT_ID('tempDB..#CTE_ConventionOperPEE') IS NOT NULL
        DROP TABLE #CTE_ConventionOperPEE

    SELECT 
        O.OperID, O.OperDate, CO.ConventionID, OperSourceID,                  
        PEE_Remis = SUM(-CO.ConventionOperAmount),
        BEC = SUM(CASE WHEN CHARINDEX(CO.ConventionOperTypeID, 'IBC', 1) > 0 THEN -CO.ConventionOperAmount ELSE 0 END),
        SCEE = SUM(CASE WHEN CHARINDEX(CO.ConventionOperTypeID, 'INS', 1) > 0 THEN -CO.ConventionOperAmount ELSE 0 END),
        SCEE_Plus = SUM(CASE WHEN CHARINDEX(CO.ConventionOperTypeID, 'IS+', 1) > 0 THEN -CO.ConventionOperAmount ELSE 0 END),
        PCEE_TIN = SUM(CASE WHEN CHARINDEX(CO.ConventionOperTypeID, 'IST', 1) > 0 THEN -CO.ConventionOperAmount ELSE 0 END),
        IQEE = SUM(CASE WHEN CHARINDEX(CO.ConventionOperTypeID, 'III,ICQ,MIM,IIQ,IQI', 1) > 0 THEN -CO.ConventionOperAmount ELSE 0 END),
        IQEE_Plus = SUM(CASE WHEN CHARINDEX(CO.ConventionOperTypeID, 'IMQ', 1) > 0 THEN -CO.ConventionOperAmount ELSE 0 END),
        Epargne = SUM(CASE WHEN CHARINDEX(CO.ConventionOperTypeID, 'INM,ITR', 1) > 0 THEN -CO.ConventionOperAmount ELSE 0 END)
    INTO 
        #CTE_ConventionOperPEE
    FROM
        dbo.Un_ConventionOper CO
        JOIN #CTE_OperPEE O ON O.OperID = CO.OperID
    WHERE
        (CO.ConventionID = @ConventionID OR @ConventionID = 0)
    GROUP BY
        O.OperID, O.OperDate, CO.ConventionID, OperSourceID

    IF OBJECT_ID('tempDB..#CTE_CONV') IS NOT NULL
        DROP TABLE #CTE_CONV

    SELECT DISTINCT 
        C.ConventionID, C.ConventionNo,
        Regime = O.PlanDesc,
		Cohorte = c.YearQualif,
        IdSouscripteur = C.SubscriberID,
        IdBeneficiaire = C.BeneficiaryID,
        Souscripteur = hs.FirstName + ' ' + hs.LastName, SubscriberID, BeneficiaryID
    INTO 
        #CTE_CONV
    FROM 
        dbo.Un_Convention C
        JOIN #CTE_ConventionOperPEE X ON X.ConventionID = C.ConventionID
        JOIN dbo.Mo_Human hs on C.SubscriberID = hs.HumanID
        JOIN dbo.Un_Plan O on C.PlanID = O.PlanID
    WHERE 
        (C.ConventionID = @ConventionID OR @ConventionID = 0)
        AND C.SubscriberID = ISNULL(@SubscriberID, C.SubscriberID)
        AND Hs.LastName LIKE ISNULL(@LastName, '') + '%'
        AND Hs.FirstName LIKE ISNULL(@FirstName, '') + '%'
    
    ;WITH 
    CTE_Adresse as (
        SELECT 
            iID_Source, dtDate_Debut, dtDate_Fin, vcProvince
        FROM 
            dbo.tblGENE_AdresseHistorique A 
            JOIN #CTE_CONV D ON D.IdSouscripteur = A.iID_Source
        WHERE
            cType_Source = 'H' AND dtDate_Debut <= @EndDate AND dtDate_Fin > @StartDate
        UNION ALL 
        SELECT
            iID_Source, dtDate_Debut, '9999-12-31', vcProvince
        FROM 
            dbo.tblGENE_Adresse A 
            JOIN #CTE_CONV D ON D.IdSouscripteur = A.iID_Source
        WHERE 
            cType_Source = 'H' AND dtDate_Debut <= @EndDate
      )
    SELECT DISTINCT 
            DateDu = @StartDate,
            DateAu = @EndDate,           
            PEE.OperID,           
            C.ConventionNo, 
            C.Regime,
			C.Cohorte,
            C.Souscripteur,
            ProvSousc = ISNULL(adr.vcProvince,'N/D'),
            C.IdSouscripteur, 
            C.IdBeneficiaire, 
            PEE.OperDate,          
            PEE.PEE_Remis,
            PEE.BEC,
            PEE.SCEE,
            PEE.SCEE_Plus,
            PEE.PCEE_TIN,
            PEE.IQEE,
            PEE.IQEE_Plus,
            PEE.Epargne
      FROM #CTE_ConventionOperPEE PEE
            JOIN #CTE_CONV C ON C.ConventionID = PEE.ConventionID
            JOIN CTE_Adresse ADR on adr.iID_Source = C.IdSouscripteur AND PEE.OperDate >= adr.dtDate_Debut AND PEE.OperDate < adr.dtDate_Fin           
     ORDER BY PEE.OperDate DESC, PEE.OperID DESC
END
