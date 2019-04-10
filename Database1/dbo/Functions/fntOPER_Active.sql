/****************************************************************************************************
Copyrights (c) 2017 Gestion Universitas inc.

Code du service : fntOPER_Active
Nom du service  : Retourne toutes les opérations actives à une date donnée. 
But             : sélectionner tous les opérations qui n'ont pas été annulées et les transactions bancaires retournées.
Facette         : OPER

Paramètres d’entrée :    
    Paramètre               Description
    --------------------    -----------------------------------------------------------------
    EndDate                 Date à laquelle on veut les opérations actives (optionel: date du jour)

Exemple d’appel :
    SELECT * FROM dbo.fntOPER_Active(DEFAULT) where OperID_Cancel is not null
    SELECT * FROM dbo.fntOPER_Active('2017-12-31')

Paramètres de sortie :
    Champ                   Description
    --------------------    ---------------------------------
    OperID                  Identifiant de l'opération
    OperDate                Date de l'opération
    OperTypeID              Type de l'opération
    ConnectID               Identifiant de la connection à l'origine de l'opération
    dtSequence_Operation    Date & heure que l'opération a été créée

Historique des modifications:
    Date        Programmeur                 Description                                
    ----------  ------------------------    -----------------------------------------------------
    2017-11-14  Steeve Picard               Création du service
    2018-02-14  Steeve Picard               Exclure les transactions bancaires retournées
    2018-03-20  Steeve Picard               Ajout du paramètre «@StartDate» pour accélérer l'IQÉÉ
    2018-03-28  Steeve Picard               Faire le «SELECT DISTINCT» sur le résultat
****************************************************************************************************/
CREATE FUNCTION dbo.fntOPER_Active (@StartDate AS DATE = NULL, @EndDate AS DATE = NULL)
RETURNS TABLE 
AS
RETURN (
    WITH CTE_Oper AS (
        SELECT DISTINCT O.OperID, O.OperDate, O.OperTypeID, O.ConnectID, O.dtSequence_Operation, Ct.EffectDate
          FROM dbo.Un_Oper O
               LEFT JOIN dbo.Un_Cotisation Ct ON Ct.OperID = O.OperID
         WHERE CAST(ISNULL(Ct.EffectDate, O.OperDate) AS DATE) BETWEEN ISNULL(@StartDate, '1900-01-01') AND ISNULL(@EndDate, GETDATE())
    )
    SELECT DISTINCT O.OperID, O.OperDate, O.OperTypeID, O.ConnectID, O.dtSequence_Operation, O.EffectDate
      FROM CTE_Oper O
           LEFT JOIN dbo.Un_OperCancelation OC_1 ON O.OperID = OC_1.OperID
           LEFT JOIN dbo.Un_OperCancelation OC_2 ON O.OperID = OC_2.OperSourceID
           LEFT JOIN dbo.Mo_BankReturnLink BRL ON (BRL.BankReturnSourceCodeID = O.OperID)
           LEFT JOIN dbo.Mo_BankReturnLink BRL2 ON (BRL2.BankReturnCodeID = O.OperID)
     WHERE ISNULL(OC_1.OperSourceID, OC_2.OperID) IS NULL
       AND ISNULL(BRL.BankReturnCodeID, BRL2.BankReturnCodeID) IS NULL 
)
