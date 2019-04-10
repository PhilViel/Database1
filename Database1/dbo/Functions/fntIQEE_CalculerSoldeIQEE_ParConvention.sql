/****************************************************************************************************
Code de service :   fntIQEE_CalculerSoldeIQEE_ParConvention
Nom du service  :   CalculerSoldeIQEE_Convention
But             :   Calculer le solde de l'IQÉÉ de base & sa majoration de toutes les conventions
Facette         :   IQÉÉ
Reférence       :   Système de gestion de la relation client

Parametres d'entrée :
        Parametres          Description
        ----------          ----------------
        iID_Convention      ID de la convention concernée par l'appel
        dtDate_Fin          Date de fin de la période considérée par l'appel

Exemple d'appel:
        SELECT * FROM dbo.fntIQEE_CalculerSoldeIQEE_ParConvention(NULL, NULL, DEFAULT) WHERE Credit_Base <> 0 and Majoration <> 0
        SELECT * FROM dbo.fntIQEE_CalculerSoldeIQEE_ParConvention(375435, NULL, 1)

Parametres de sortie : Le solde de l'IQEE

Historique des modifications :
    Date         Programmeur             Description
    ----------  --------------------    --------------------------------------------------------
    2016-02-18  Steeve Picard           Création de la fonction basé sur fnIQEE_CalculerSoldeIQEE_Convention
    2016-04-06  Steeve Picard           Ajout de l'intérêt accumulé (rendement)
    2017-04-21  Steeve Picard           Correction des opérations actives
    2017-06-26  Steeve Picard           Arrondissement de la date d'opération
    2018-01-03  Steeve Picard           Utilisation de la fonction «fntOPER_Active»
****************************************************************************************************/
CREATE FUNCTION dbo.fntIQEE_CalculerSoldeIQEE_ParConvention( 
    @iID_Convention INT, 
    @dtDate_Fin DATE,
    @bParOperTypeID BIT = 0
)
RETURNS TABLE
AS RETURN
(
    WITH 
        CTE_ConvOperType as (
            SELECT ConvOperTypeID = Rtrim(LTrim(strField)), 
                   EstInteret = 1
              FROM dbo.fntGENE_SplitIntoTable(dbo.fnOPER_ObtenirTypesOperationConvCategorie('OPER_RENDEMENTS_IQEE'), ',')
             WHERE Rtrim(LTrim(strField)) <> ''
            UNION
            SELECT 'CBQ', 0
            UNION
            SELECT 'MMQ', 0
        ),
        CTE_Oper as (
            SELECT O.OperID, Cast(O.OperDate AS date) AS OperDate, O.OperTypeID
              FROM dbo.Un_Oper O
             WHERE Cast(O.OperDate AS date) <= IsNull(@dtDate_Fin, GETDATE())
        ),
        CTE_OperActive as (
            SELECT O.OperID, O.OperDate, O.OperTypeID
              FROM CTE_Oper O
                   LEFT JOIN dbo.Un_OperCancelation OC_1 ON O.OperID = OC_1.OperID
                   LEFT JOIN dbo.Un_OperCancelation OC_2 ON O.OperID = OC_2.OperSourceID
             WHERE OC_1.OperSourceID IS NULL
               AND OC_2.OperID IS NULL
        ),
        CTE_ConvOper as (
            SELECT CO.ConventionID, CO.ConventionOperTypeID, CO.ConventionOperAmount, O.OperTypeID, EstInteret
              FROM dbo.Un_ConventionOper CO 
                   JOIN CTE_OperActive O ON O.OperID = CO.OperID
                   --JOIN dbo.fntOPER_Active(@dtDate_Fin) O ON O.OperID = CO.OperID
                   JOIN CTE_ConvOperType T ON T.ConvOperTypeID = CO.ConventionOperTypeID
             WHERE (CO.ConventionID = IsNull(@iID_Convention, CO.ConventionID))
        )
    SELECT ConventionID, 
           Credit_Base = Sum(CASE ConventionOperTypeID WHEN 'CBQ' THEN ConventionOperAmount ELSE 0 END),
           Majoration = Sum(CASE ConventionOperTypeID WHEN 'MMQ' THEN ConventionOperAmount ELSE 0 END),
           Interet = Sum(Case EstInteret WHEN 1 THEN CO.ConventionOperAmount ELSE 0 END),
           OperTypeID = CASE @bParOperTypeID WHEN 0 THEN NULL ELSE CO.OperTypeID END
      FROM CTE_ConvOper CO
     GROUP BY ConventionID,
              CASE @bParOperTypeID WHEN 0 THEN NULL ELSE CO.OperTypeID END
)         
