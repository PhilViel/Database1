/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service        : psOPER_ObtenirListePRA
Nom du service        : Liste des PRAs émis
But                 : Retourner la liste des conventions ayant eu une demande de PRA qualifiée
Facette                : OPER

Paramètres d’entrée    :    
    Paramètre                    Description
    --------------------    ------------------------------------------------------------------------------------------
    @StartDate                Date de début de la période visée. Si omis, la date du 1er jour du mois sera utilisé
    @EndDate                Date de fin de la période visée. Si omis, la date du jour sera utilisé

Exemple d’appel     :   EXEC dbo.psOPER_ObtenirListePRA '2015-10-22', '2215-11-10'
                        EXEC dbo.psOPER_ObtenirListePRA @ConventionNo = 'I-20040108001'
                        EXEC dbo.psOPER_ObtenirListePRA @SubscriberID = 206036
                        EXEC dbo.psOPER_ObtenirListePRA @LastName = 'B', @FirstName = 'Ben'

Historique des modifications:
    Date            Programmeur                Description                                                    Référence
    ----------      --------------------    ---------------------------------------------------------   --------------
    2015-11-01      Steeve Picard           Création du service
    2015-11-10      Steeve Picard           Joindre obligatoirement l'opération à une demande
    2015-11-24      Steeve Picard           Ajout du champ «Destinataire»
    2015-12-08      Steeve Picard           Ajout du paramètre pour filtrer par le no convention et ID du souscripteur
    2016-01-09		Steeve Picard			Optimisation en utilisant le ID de convention dans les sous-requêtes
**********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_ObtenirListePRA] (
    @StartDate     DATE = NULL, --'2015-01-01',
    @EndDate         DATE = NULL,
    @ConventionNo  VARCHAR(15) = NULL,
    @SubscriberID  INT = NULL,
    @LastName VARCHAR(75) = NULL,
    @FirstName VARCHAR(75) = NULL
) AS 
BEGIN
     DECLARE @ConventionID INT = (IsNull((SELECT ConventionID From dbo.Un_Convention Where ConventionNo = IsNull(@ConventionNo, '')), 0))

     IF @EndDate IS NULL
       SET @EndDate = GetDate()

    IF @StartDate IS NULL
        SET @StartDate =  '0001-01-01'

    ;WITH CTE_OperPRA as (
            SELECT O.OperID, O.OperDate, O.OperTypeID, OC.OperSourceID
              FROM dbo.Un_Oper O
                   LEFT JOIN dbo.Un_OperCancelation OC ON OC.OperID = O.OperID
                   --LEFT JOIN dbo.Un_Oper O2 ON O2.OperID = OC.OperSourceID
             WHERE O.OperDate BetWeen @StartDate And @EndDate 
               and O.OperTypeID = 'PRA'
      )
    , CTE_OperRET as (
            SELECT DISTINCT O.OperID, C.OperDate, C.OperTypeID, C.OperID as IdOperRTN
              FROM CTE_OperPRA O
                   JOIN dbo.tblOPER_AssociationOperations A ON A.iID_Operation_Parent = O.OperID
                   JOIN dbo.Un_Oper C ON C.OperID = A.iID_Operation_Enfant
      )
    , CTE_ConventionOperPRA as (
            SELECT O.OperID, O.OperDate, CO.ConventionID, OperSourceID,
                   PRA_Disponible = Sum(CASE CO.ConventionOperTypeID WHEN 'RTN' THEN 0 ELSE -CO.ConventionOperAmount END),
                   PRA_Remis = Sum(-CO.ConventionOperAmount),
                   BEC = Sum(CASE WHEN CharIndex(CO.ConventionOperTypeID, 'IBC', 1) > 0 THEN -CO.ConventionOperAmount ELSE 0 END),
                   SCEE = Sum(CASE WHEN CharIndex(CO.ConventionOperTypeID, 'INS', 1) > 0 THEN -CO.ConventionOperAmount ELSE 0 END),
                   SCEE_Plus = Sum(CASE WHEN CharIndex(CO.ConventionOperTypeID, 'IS+', 1) > 0 THEN -CO.ConventionOperAmount ELSE 0 END),
                   PCEE_TIN = Sum(CASE WHEN CharIndex(CO.ConventionOperTypeID, 'IST', 1) > 0 THEN -CO.ConventionOperAmount ELSE 0 END),
                   IQEE = Sum(CASE WHEN CharIndex(CO.ConventionOperTypeID, 'III,ICQ,MIM,IIQ,IQI', 1) > 0 THEN -CO.ConventionOperAmount ELSE 0 END),
                   IQEE_Plus = Sum(CASE WHEN CharIndex(CO.ConventionOperTypeID, 'IMQ', 1) > 0 THEN -CO.ConventionOperAmount ELSE 0 END),
                   Epargne = Sum(CASE WHEN CharIndex(CO.ConventionOperTypeID, 'INM,ITR', 1) > 0 THEN -CO.ConventionOperAmount ELSE 0 END)
              FROM dbo.Un_ConventionOper CO
                   JOIN CTE_OperPRA O ON O.OperID = CO.OperID
			 WHERE (CO.ConventionID = @ConventionID OR @ConventionID = 0)
             GROUP BY O.OperID, O.OperDate, CO.ConventionID, OperSourceID
      )
    , CTE_ConventionOperRTN as (
            SELECT R.OperID, R.OperDate,
                   Impot_Fed = Sum(CASE R.OperTypeID WHEN 'RIF' THEN -CO.ConventionOperAmount ELSE 0 END),
                   Impot_Prov = Sum(CASE R.OperTypeID WHEN 'RIP' THEN -CO.ConventionOperAmount ELSE 0 END)
              FROM CTE_OperRET R
                   JOIN dbo.Un_ConventionOper CO ON CO.OperID =  R.IdOperRTN
			 WHERE (CO.ConventionID = @ConventionID OR @ConventionID = 0)
             GROUP BY R.OperID, R.OperDate
      )
    , CTE_Demande as (
            SELECT DP.Id, DP.idOper, PreuveDeficienceRecue, PourcentageDemande, TypeDestination, DP.CotisationsInutilisees,
                   Souscripteur = hs.FirstName + ' ' + hs.LastName, IdSouscripteur, IdBeneficiaire, DP.InstitutionFinanciereNom
              FROM dbo.DemandePRA DP
                   JOIN CTE_OperPRA O ON IsNull(O.OperSourceID, O.OperID) = DP.IdOper
                   JOIN dbo.Mo_Human hs on DP.IdSouscripteur = hs.HumanID
             WHERE DP.EstQualifiee <> 0 And DP.idOper IS NOT NULL
               AND DP.IdSouscripteur = IsNull(@SubscriberID, DP.IdSouscripteur)
               AND Hs.LastName Like IsNull(@LastName, '') + '%'
               AND Hs.FirstName Like IsNull(@FirstName, '') + '%'
        )
    , CTE_Adresse as (
            select iID_Source, dtDate_Debut, dtDate_Fin, vcProvince --, iID_Province
            from tblGENE_AdresseHistorique A JOIN CTE_Demande D ON D.IdSouscripteur = A.iID_Source
            where cType_Source = 'H' And dtDate_Debut <= @EndDate And dtDate_Fin > @StartDate
            union all 
            select iID_Source, dtDate_Debut, '9999-12-31', vcProvince --, iID_Province
            from tblGENE_Adresse A JOIN CTE_Demande D ON D.IdSouscripteur = A.iID_Source
            where cType_Source = 'H' And dtDate_Debut <= @EndDate
      )
    SELECT DISTINCT 
            DateDu = @StartDate,
            DateAu = @EndDate,
            --DP.ID, PRA.ConventionID,
            PRA.OperID,
            DateTraitee = (SELECT DateTraitee FROM dbo.Demande WHERE Id = DP.Id), 
            ConventionNo = (SELECT ConventionNo FROM  dbo.Un_Convention WHERE ConventionID = PRA.ConventionID), 
            DP.Souscripteur,
            ProvSousc = isnull(adr.vcProvince,'N/D'),
            DP.IdSouscripteur, 
            DP.IdBeneficiaire, 
            PRA.OperDate,
            Type_PRA =    CASE DP.TypeDestination 
                            WHEN 0 THEN 'PRA'
                            WHEN 1 THEN 'REER'
                            WHEN 2 THEN 'REEI'
                            ELSE '-'
                        END,
            Destinataire = CASE TypeDestination
                                WHEN 0 THEN DP.Souscripteur
                                WHEN 1 THEN DP.InstitutionFinanciereNom
                                WHEN 2 THEN DP.InstitutionFinanciereNom
                                ELSE '-'
                        END,
            Deficience_Mental = CASE DP.PreuveDeficienceRecue WHEN 0 THEN 'Non' Else 'Oui' END,
            Pourcentage = Str(DP.PourcentageDemande * 100) + '%',
            PRA.PRA_Disponible,
            Total_Imposable = CASE WHEN PRA.PRA_Disponible < IsNull(DP.CotisationsInutilisees, 0) THEN 0
                                   ELSE PRA.PRA_Disponible - IsNull(DP.CotisationsInutilisees, 0)
                              END,
            Impot_Fed = IsNull(RTN.Impot_Fed, 0),
            Impot_Prov = IsNull(RTN.Impot_Prov, 0),
            PRA.PRA_Remis,
            PRA.BEC,
            PRA.SCEE,
            PRA.SCEE_Plus,
            PRA.PCEE_TIN,
            PRA.IQEE,
            PRA.IQEE_Plus,
            PRA.Epargne
      FROM CTE_ConventionOperPRA PRA
            JOIN CTE_Demande DP ON DP.IdOper = IsNull(PRA.OperSourceID, PRA.OperID)
            JOIN CTE_Adresse ADR on adr.iID_Source = DP.IdSouscripteur and PRA.OperDate >= adr.dtDate_Debut AND PRA.OperDate < adr.dtDate_Fin
            LEFT JOIN CTE_ConventionOperRTN RTN on RTN.OperID = PRA.OperID
     ORDER BY PRA.OperDate DESC, PRA.OperID DESC
END
