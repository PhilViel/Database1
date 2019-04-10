/****************************************************************************************************
Copyrights (c) 2018 Gestion Universitas inc.

Code du service : fntIQEE_Transfert_NonDeclare
Nom du service  : Obtenir la liste des transferts qui ne sont pas encore déclarés à RQ
But             : Récupérer tous les opérations financières de transfert n'étant pas déclarés à RQ
Facette         : IQÉÉ

Paramètres d’entrée :
    Paramètre               Description
    --------------------    ---------------------------------------------------------------------------
    iID_Convention          Identifiant de la convention que l'on désire le solde ayant eu droit et non-droit à l'IQÉÉ.
    dtEnDateDu              Date à laquelle on désire connaître le solde.
                            Si elle est absente, la date du jour est considérée.

Exemple d’appel :
    DECLARE @ConventionID INT = (SELECT ConventionID FROM Un_Convention WHERE ConventionNo = 'R-20060831054')
    SELECT * FROM dbo.fntIQEE_Transfert_NonDeclare(@ConventionID, GETDATE())
    ORDER BY ConventionID, OperDate

    SELECT OperTypeID, siAnnee = Year(OperDate), COUNT(*) FROM dbo.fntIQEE_Transfert_NonDeclare(DEFAULT, GETDATE())
    GROUP BY OperTypeID, Year(OperDate)

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
CREATE FUNCTION [dbo].[fntIQEE_Transfert_NonDeclare] (
    @iID_Convention INT = NULL,
    @dtEnDate       DATE = NULL
) RETURNS TABLE
AS RETURN
(
    WITH 
        CTE_Oper AS (
            SELECT DISTINCT CO.ConventionID, O.OperDate, O.OperTypeID, O.OperID
              FROM  dbo.fntOPER_Active('2007-02-21', ISNULL(@dtEnDate, GETDATE())) O
                   JOIN dbo.Un_ConventionOper CO ON CO.OperID = O.OperID
             WHERE O.OperTypeID IN ('OUT', 'RIM', 'RIO', 'TIN', 'TIO', 'TRI')
                   AND CO.ConventionID = ISNULL(@iID_Convention, CO.ConventionID)
                   AND CO.ConventionOperTypeID IN ('CBQ','MMQ')
                   AND CO.ConventionOperAmount <> 0 
        ),
        CTE_Transfert AS (
            SELECT T.iID_Convention, T.dtDate_Transfert, T.cStatut_Reponse, T.iID_Ligne_Fichier 
              FROM (SELECT T.iID_Convention, T.dtDate_Transfert, T.tiCode_Version, T.cStatut_Reponse, T.iID_Ligne_Fichier,
                           RowNum = ROW_NUMBER() OVER(PARTITION BY T.iID_Convention, T.dtDate_Transfert ORDER BY F.dtDate_Creation DESC, ISNULL(T.iID_Ligne_Fichier, 999999999), T.iID_Transfert DESC)
                      FROM dbo.tblIQEE_Transferts T
                           JOIN dbo.vwIQEE_Enregistrement_TypeEtSousType TST ON TSt.iID_Sous_Type = T.iID_Sous_Type
                           JOIN dbo.tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = T.iID_Fichier_IQEE AND F.bFichier_Test = 0 AND F.bInd_Simulation = 0
                     WHERE T.iID_Convention = ISNULL(@iID_Convention, T.iID_Convention)
                           AND T.siAnnee_Fiscale <= YEAR(ISNULL(@dtEnDate, GETDATE()))
                           AND NOT T.cStatut_Reponse IN ('E','X')
                           AND TST.cCode_Type_SousType = '05-01'
                   ) T
             WHERE T.RowNum = 1
                   AND T.tiCode_Version <> 1
        )
    SELECT DISTINCT
        O.ConventionID, O.OperDate, O.OperTypeID, T.cStatut_Reponse
    FROM
        CTE_Oper O
        LEFT JOIN CTE_Transfert T ON T.iID_Convention = O.ConventionID AND T.dtDate_Transfert = O.OperDate
    WHERE
        ISNULL(T.cStatut_Reponse, '') <> 'R'
)
