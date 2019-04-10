/****************************************************************************************************
Code de service        :        fntIQEE_CalculerSoldeIQEE
Nom du service        :        CalculerSoldeIQEE
But                    :        Calculer le solde de l'IQÉÉ de base & sa majoration d'une conventions
Facette                :        IQÉÉ
Reférence            :        Système de gestion de la relation client

Parametres d'entrée :    Parametres                    Description
                        ----------                  ----------------
                        iID_Convention              ID de la convention concernée par l'appel
                        dtDate_Fin                  Date de fin de la période considérée par l'appel

Exemple d'appel:    SELECT * FROM dbo.fntIQEE_CalculerSoldeIQEE(374011, NULL)

Parametres de sortie : Le solde de l'IQEE

Historique des modifications :
            
    Date        Programmeur                 Description
    ----------  -------------------------   -------------------------------------------
    2016-02-18  Steeve Picard               Création de la fonction basé sur fnIQEE_CalculerSoldeIQEE_Convention
    2016-04-06  Steeve Picard               Ajout de l'intérêt accumulé (rendement)
    2017-04-21  Steeve Picard               Correction des opérations actives
****************************************************************************************************/
CREATE FUNCTION dbo.fntIQEE_CalculerSoldeIQEE (
    @iID_Convention INT, 
    @dtDate_Fin DATE = NULL,
    @bParOperTypeID BIT = 0
)
RETURNS @Result TABLE (
    Credit_Base MONEY,
    Majoration MONEY,
    Interet MONEY,
    OperTypeID varchar(5)
) AS
BEGIN
    DECLARE @vcListOper varchar(100) = dbo.fnOPER_ObtenirTypesOperationConvCategorie('OPER_RENDEMENTS_IQEE')

    DECLARE @TB_ConvOperType TABLE ( ConvOperTypeID char(5) NOT NULL, EstInteret bit NOT NULL )

    INSERT INTO @TB_ConvOperType (ConvOperTypeID, EstInteret) VALUES ('CBQ', 0)
    INSERT INTO @TB_ConvOperType (ConvOperTypeID, EstInteret) VALUES ('MMQ', 0)

    INSERT INTO @TB_ConvOperType (ConvOperTypeID, EstInteret)
         SELECT Rtrim(LTrim(strField)), 1
          FROM dbo.fntGENE_SplitIntoTable(@vcListOper, ',')
         WHERE Rtrim(LTrim(strField)) <> ''

    ;WITH CTE_Oper as (
        SELECT O.*
          FROM dbo.Un_Oper O
         WHERE Cast(O.OperDate as DATE) <= IsNull(@dtDate_Fin, GETDATE())
    ),
     CTE_OperActive as (
        SELECT O.*
          FROM CTE_Oper O
              LEFT JOIN dbo.Un_OperCancelation OC_1 ON O.OperID = OC_1.OperID
              LEFT JOIN dbo.Un_OperCancelation OC_2 ON O.OperID = OC_2.OperSourceID
         WHERE OC_1.OperSourceID IS NULL
           AND OC_2.OperID IS NULL
     )
    INSERT INTO @Result (Credit_Base, Majoration, Interet, OperTypeID)
    SELECT Credit_Base = IsNull(Sum(CASE CO.ConventionOperTypeID WHEN 'CBQ' THEN CO.ConventionOperAmount ELSE 0 END), 0),
           Majoration = IsNull(Sum(CASE CO.ConventionOperTypeID WHEN 'MMQ' THEN CO.ConventionOperAmount ELSE 0 END), 0),
           Interet = IsNull(Sum(Case EstInteret WHEN 1 THEN CO.ConventionOperAmount ELSE 0 END), 0),
           CASE @bParOperTypeID WHEN 0 THEN NULL ELSE O.OperTypeID END
      FROM dbo.Un_ConventionOper CO
           JOIN @TB_ConvOperType T ON T.ConvOperTypeID = CO.ConventionOperTypeID
           JOIN CTE_OperActive O ON O.OperID = CO.OperID
     WHERE CO.ConventionID = @iID_Convention
     GROUP BY CASE @bParOperTypeID WHEN 0 THEN NULL ELSE O.OperTypeID END

     RETURN
END
