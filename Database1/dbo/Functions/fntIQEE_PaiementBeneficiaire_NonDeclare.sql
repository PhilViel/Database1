/****************************************************************************************************
Copyrights (c) 2018 Gestion Universitas inc.

Code du service : fntIQEE_PaiementBeneficiaire_NonDeclare
Nom du service  : Obtenir la liste des PAE qui ne sont pas encore déclarés à RQ
But             : Récupérer tous les opérations financières de PAE n'étant pas déclarés à RQ
Facette         : IQÉÉ

Paramètres d’entrée :
    Paramètre               Description
    --------------------    ---------------------------------------------------------------------------
    iID_Convention          Identifiant de la convention que l'on désire le solde ayant eu droit et non-droit à l'IQÉÉ.
    dtEnDateDu              Date à laquelle on désire connaître le solde.
                            Si elle est absente, la date du jour est considérée.

Exemple d’appel :
    DECLARE @ConventionID INT = (SELECT ConventionID FROM Un_Convention WHERE ConventionNo = 'R-20060831054')
    SELECT * FROM dbo.fntIQEE_PaiementBeneficiaire_NonDeclare(@ConventionID, GETDATE())
    ORDER BY ConventionID, ScholarshipNo

    SELECT * FROM dbo.fntIQEE_PaiementBeneficiaire_NonDeclare(DEFAULT, GETDATE()-1)
    ORDER BY ConventionID, ScholarshipNo

Paramètres de sortie :
    Champ                   Description
    --------------------    ---------------------------------
    ConventionID            Identifiant de la convention
    OperDate                Date du transfert
    OperTypeID              Type de transfert

Historique des modifications:
    Date        Programmeur         Description
    ----------  -----------------   -----------------------------------------------------
    2018-12-06  Steeve Picard       Création du service
*********************************************************************************************************************/
CREATE FUNCTION [dbo].[fntIQEE_PaiementBeneficiaire_NonDeclare] (
    @iID_Convention INT = NULL,
    @dtEnDate       DATE = NULL 
) RETURNS TABLE
AS RETURN
(
    WITH 
        CTE_OperPAE AS (
            SELECT DISTINCT CO.ConventionID, O.OperDate, O.OperID
              FROM  dbo.fntOPER_Active('2007-02-21', ISNULL(@dtEnDate, GETDATE())) O
                   JOIN dbo.Un_ConventionOper CO ON CO.OperID = O.OperID
             WHERE O.OperTypeID = 'PAE'
                   AND CO.ConventionID = ISNULL(@iID_Convention, CO.ConventionID)
                   AND CO.ConventionOperTypeID IN ('CBQ','MMQ')
                   AND CO.ConventionOperAmount <> 0 
        ),
        CTE_Paiement AS (
            SELECT PB.iID_Convention, PB.dtDate_Paiement, PB.cStatut_Reponse, PB.iID_Ligne_Fichier 
              FROM (SELECT P.iID_Convention, P.dtDate_Paiement, P.tiCode_Version, P.cStatut_Reponse, P.iID_Ligne_Fichier,
                           RowNum = ROW_NUMBER() OVER(PARTITION BY P.iID_Convention, P.dtDate_Paiement ORDER BY F.dtDate_Creation DESC, ISNULL(P.iID_Ligne_Fichier, 999999999), P.iID_Paiement_Beneficiaire DESC)
                      FROM dbo.tblIQEE_PaiementsBeneficiaires P
                           JOIN dbo.vwIQEE_Enregistrement_TypeEtSousType TST ON TSt.iID_Sous_Type = P.iID_Sous_Type
                           JOIN dbo.tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = P.iID_Fichier_IQEE AND F.bFichier_Test = 0 AND F.bInd_Simulation = 0
                     WHERE P.iID_Convention = ISNULL(@iID_Convention, P.iID_Convention)
                           AND P.siAnnee_Fiscale <= YEAR(ISNULL(@dtEnDate, GETDATE()))
                           AND NOT P.cStatut_Reponse IN ('E','X')
                           AND TST.cCode_Type_SousType = '05-01'
                   ) PB
             WHERE PB.RowNum = 1
                   AND PB.tiCode_Version <> 1
        )
    SELECT DISTINCT
        O.ConventionID, O.OperDate, S.ScholarshipNo, PB.cStatut_Reponse
    FROM
        CTE_OperPAE O
        JOIN dbo.Un_ScholarshipPmt SP ON SP.OperID = O.OperID
        JOIN dbo.Un_Scholarship S ON S.ScholarshipID = SP.ScholarshipID
        LEFT JOIN CTE_Paiement PB ON PB.iID_Convention = O.ConventionID AND PB.dtDate_Paiement = O.OperDate
    WHERE
        ISNULL(PB.cStatut_Reponse, '') <> 'R'
)
