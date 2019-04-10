/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service : fntIQEE_CalculerMontantsDemande_Details
Nom du service  : Calculer les montants d’une demande de l’IQÉÉ 
But             : Calculer les montants d’une demande de l’IQÉÉ qui correspondent aux champs « Montant des
                  cotisations annuelles versées dans le régime », « Montant des cotisations annuelles issues d’un
                  transfert », « Montant total des cotisations annuelles » et « Montant total des cotisations
                  versées au régime » du type d’enregistrement 02.  Les montants négatifs sont utilisé pour les
                  transactions de type 06-impôt spécial et de sous-type 22-retrait prématuré de cotisations
Facette         : IQÉÉ

Paramètres d’entrée :
    Paramètre                   Description
    ------------------------    -----------------------------------------------------------------
    iID_Convention              Identifiant unique de la convention pour laquelle le calcul est demandé.
    dtDate_Debut_Application    Date de début d’application des cotisations.  La date effective de la transaction 
                                de cotisation est utilisée pour la sélection.
    dtDate_Fin_Application      Date de fin d’application des cotisations.  La date effective de la transaction 
                                de cotisation est utilisée pour la sélection.

Exemple d’appel : Cette procédure doit être appelée uniquement par les procédures "psIQEE_CreerTransactions02" et
                  declare @id int = (select conventionid from dbo.un_convention where ConventionNo = 'I-20101015005')
                  select * from dbo.fntIQEE_CalculerMontantsDemande_Details(@id, '2011-01-01', '2011-12-31') where ID_Operation_Annulation is null

Paramètres de sortie :
    Champ                       Description
    --------------------        ---------------------------------
    ID_Convention               ID de la convention
    ID_Operation                ID de l'opération
    Code_Type_Operation         Code de l'opération
    ID_Operation_Annulation     ID de l'opération qui annule
    Date_Cotisation             Date de la cotisation
    ID_Cotisation               ID de la cotisation
    Cotisations_Transaction     Montant de la cotisation
    Frais                       Frais prélevé sur la cotisation
    Cotisation_Annee_Transfert_IN
                                Montant de la cotisation provenant d'un «TIN»
    Cotisation_Annee_Transfert_OUT
                                Montant de la cotisation provenant d'un «OUT»
    Cotisations_Sans_SCEE_Avant_1998
                                Montant de la cotisation effectué avant 1998
    Cotisations_Sans_SCEE_APartirDe_1998
                                Montant de la cotisation effectué à partir 1998
    Cotisations_Avec_SCEE       Montant de cotisation du PCEE
    CollegeID                   ID du collège lors d'une «RIN avec preuve» 

Historique des modifications:
    Date        Programmeur             Description
    ----------  --------------------    -----------------------------------------------------
    2017-03-24  Steeve Picard           Création du service à partir de la «fntIQEE_CalculerMontantsDemande_PourTous»
    2017-08-15  Steeve Picard           Correction du filtre sur «Un_IntReimbOper» qui était inversé
    2017-12-18  Steeve Picard           Correction pour tenir compte des transactions NSF
    2018-01-10  Steeve Picard           Exclure les opérations «TFR» en tout temps (auparavant, c'était juste après 2012-11-01
    2018-08-20  Steeve Picard           Gérer les conditions sur les «TFR» dans les procédures appelantes
*********************************************************************************************************************/
CREATE FUNCTION [dbo].[fntIQEE_CalculerMontantsDemande_Details] (
    @iID_Convention INT = NULL,
    @dtDate_Debut_Application DATETIME,
    @dtDate_Fin_Application DATETIME
)
RETURNS TABLE
AS RETURN
(
    SELECT DISTINCT 
        ID_Convention = UN.ConventionID, 
        ID_Operation = OP.OperID, 
        Code_Type_Operation = OP.OperTypeID, 
        ID_Operation_Annulation = COALESCE(CA.OperID, BRL.BankReturnCodeID), 
        Date_Cotisation = CT.EffectDate, 
        CollegeID = IR.CollegeID,
        ID_Cotisation = Min(CT.CotisationID), 
        Cotisations_Transaction = Sum(CT.Cotisation), 
        Frais = Sum(CT.Fee), 
        Cotisation_Annee_Transfert_IN = Sum(ISNULL(TI.fYearBnfCot,0)), 
        Cotisation_Annee_Transfert_OUT = Sum(ISNULL(OU.fYearBnfCot,0)), 
        Cotisations_Sans_SCEE_Avant_1998 = Sum(ISNULL(TI.fNoCESGCotBefore98,0)), 
        Cotisations_Sans_SCEE_APartirDe_1998 = Sum(ISNULL(TI.fNoCESGCot98AndAfter,0)), 
        Cotisations_Avec_SCEE = Sum(ISNULL(TI.fCESGCot,0))
    FROM 
        dbo.Un_Unit UN
        -- Cotisations depuis le début jusqu'à la date de fin d'application
        JOIN (
                SELECT CotisationID, OperID, UnitID, Cotisation, Fee, EffectDate
                  FROM dbo.Un_Cotisation
                 WHERE EffectDate >= '2007-02-21'
                   AND EffectDate Between @dtDate_Debut_Application AND @dtDate_Fin_Application
            ) CT ON CT.UnitID = UN.UnitID
        JOIN dbo.Un_Oper OP ON OP.OperID = CT.OperID
        LEFT JOIN dbo.Un_OperCancelation CA ON CA.OperSourceID = OP.OperID
        LEFT JOIN dbo.Mo_BankReturnLink BRL ON (BRL.BankReturnSourceCodeID = OP.OperID)
        LEFT JOIN dbo.Mo_BankReturnLink BRL2 ON (BRL2.BankReturnCodeID = OP.OperID)
        LEFT JOIN dbo.Un_TIN TI ON TI.OperID = OP.OperID
        LEFT JOIN dbo.Un_OUT OU ON OU.OperID = OP.OperID
        LEFT JOIN (
                SELECT DISTINCT IRO.OperID, IR.CollegeID
                  FROM dbo.Un_IntReimbOper IRO
                       JOIN dbo.Un_IntReimb IR ON IR.IntReimbID = IRO.IntReimbID --UnitID = ct.UnitID
                 --WHERE Year(@dtDate_Debut_Application) >= 2012
            ) IR ON IR.OperID = OP.OperID
    WHERE 
        UN.ConventionID = IsNull(@iID_Convention, UN.ConventionID)
        AND ISNULL(BRL.BankReturnCodeID, BRL2.BankReturnCodeID) IS NULL 
    GROUP BY 
        UN.ConventionID, OP.OperID, OP.OperTypeID, COALESCE(CA.OperID, BRL.BankReturnCodeID), CT.EffectDate, IR.CollegeID
)
