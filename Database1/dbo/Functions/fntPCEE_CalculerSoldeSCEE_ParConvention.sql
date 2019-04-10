/****************************************************************************************************
Code de service : fntPCEE_CalculerSoldeSCEE_ParConvention
Nom du service  : CalculerSoldeSCEE_ParConvention
But             : Calculer le solde SCEE par convention
Facette         : PCEE
Reférence       : Système de gestion de la relation client

Parametres d'entrée : 
    Parametres          Description
    ----------          -----------------------------------------------------------------------------
    iID_Convention      ID de la convention concernée par l'appel
    dtDate_Fin          Date de fin de la période considérée par l'appel

Exemple d'appel:
    SELECT * FROM DBO.[fntPCEE_CalculerSoldeSCEE_ParConvention] (NULL)
    SELECT * FROM DBO.[fntPCEE_CalculerSoldeSCEE_ParConvention] ('2010-01-01')

Parametres de sortie : 
    Le solde SCEE

Historique des modifications :
    Date        Programmeur         Description
    ----------  ----------------    -----------------------------------------------------------------
    2016-04-06  Steeve Picard       Création de la fonction
    2018-10-25  Steeve Picard       Optimisation de la fonction par un «UNION ALL»
*****************************************************************************************************/
CREATE FUNCTION [dbo].[fntPCEE_CalculerSoldeSCEE_ParConvention]
(    
    @dtDate_Fin          DATETIME = NULL
)
RETURNS TABLE
AS RETURN (

    SELECT 
        ConventionID = C.ConventionID,
        mSCEE_Base = Sum(C.mBase),
        mSCEE_Plus = Sum(C.mPlus),
        mSCEE_BEC = Sum(C.mBEC),
        mSCEE_Interet = SUM(C.mInteret)
    FROM
        dbo.fntOPER_Active(DEFAULT, @dtDate_Fin) O
        JOIN (
            SELECT OperID, ConventionID,
                   mBase = C.fCESG,
                   mPlus = C.fACESG,
                   mBEC = C.fCLB,
                   mInteret = CAST(0 AS MONEY)
              FROM dbo.Un_CESP C
            UNION ALL
            SELECT OperID, ConventionID, 0, 0, 0,
                   mInteret = CO.ConventionOperAmount
              FROM dbo.Un_ConventionOper CO
             WHERE CO.ConventionOperTypeID IN ('IBC','INS','IS+')
            ) C ON C.OperID = O.OperID 
    GROUP BY 
        C.ConventionID
)
