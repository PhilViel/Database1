/****************************************************************************************************
Copyrights (c) 2018 Gestion Universitas Inc.

Nom                 :   psCONV_ObtenirDetailsHistoriqueRIN
Description         :   Retourne les remboursements de cotisations, les paiements sur celles-ci ainsi que le détail des 
                        paiements pour une convention ou toutes les conventions liés à un souscripteur.

Valeurs de retours  : Dataset :

        ConventionID            INTEGER     ID unique de la convention
        ConventionNo            VARCHAR()   Numéro de la convention
        SubscriberID            INTEGER     ID unique du souscripteur
        PlanId                  INTEGER     ID unique du régime
        OperID                  INTEGER     ID unique de l'opération qui a effectué le paiement
        OperDate                DATETIME    Date de l'opération financière
        dtSequence_Operation    DATETIME    Date et heure de l'opération financière
        iID_OperationAnnulee    INTEGER     ID de l'opération d'annulation
        Cotisation              MONEY       Montant d'épargne remboursé
        Fee                     MONEY       Montant de frais remboursé
        StudyStart              DATETIME    Date de début du programme
        ProgramYear             INTEGER     Année du programme
        ProgramLength           INTEGER     Durée du programme
        ProgramDesc             VARCHAR(75) Programme
        CompanyName             VARCHAR(75) Établissement d'enseignement
        CESGRenonciation        BIT         Renonciation aux subventions
        AvecPreuve              BIT         Preuve d'inscription

Note :  2018-02-08 Pierre-Luc Simard  Création JIRA CRIT-2146 Afficher l'historique des transactions de RIN dans l'onglet RIN de la convention

Exemple :   EXEC psCONV_ObtenirDetailsHistoriqueRIN 156241, NULL

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_ObtenirDetailsHistoriqueRIN] (
    @iID_Convention INTEGER ,
    @iID_Souscripteur INTEGER) -- ID Unique de la convention.
AS
BEGIN

    ;WITH CTE_RIN AS (-- Liste des RIN par convention
    SELECT
        C.ConventionID,
        C.SubscriberID,
        C.ConventionNo,
        C.PlanID,
        O.OperID,
        O.OperDate,
        O.dtSequence_Operation,
        iID_OperationAnnulee = UOC.OperSourceID,
        Cotisation = SUM(CT.Cotisation),
        Fee = SUM(CT.Fee)
    FROM dbo.Un_Convention C
    JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
    JOIN dbo.Un_Cotisation CT ON CT.UnitID = U.UnitID
    JOIN dbo.Un_Oper O ON O.OperID = CT.OperID
    LEFT JOIN dbo.Un_OperCancelation UOC ON UOC.OperID = O.OperID
    WHERE C.ConventionID = ISNULL(@iID_Convention, C.ConventionID)
        AND C.SubscriberID = ISNULL(@iID_Souscripteur, C.SubscriberID)
        AND O.OperTypeID = 'RIN'
    GROUP BY
        C.ConventionID,
        C.SubscriberID,
        O.OperID,
        O.OperDate,
        UOC.OperSourceID,
        C.PlanID,
        C.ConventionNo,
        O.dtSequence_Operation
    )
    -- Liste des RIN avec informations supplémentaires
    SELECT DISTINCT
        RIN.ConventionID,
        RIN.ConventionNo,
        RIN.SubscriberID,
        RIN.PlanID,
        RIN.OperID,
        RIN.OperDate,
        RIN.dtSequence_Operation,
        RIN.iID_OperationAnnulee,
        RIN.Cotisation,
        RIN.Fee,
        IR.StudyStart,
        IR.ProgramYear,
        IR.ProgramLength,
        P.ProgramDesc,
        CCo.CompanyName,
        IR.CESGRenonciation,
        DR.AvecPreuve
    FROM CTE_RIN RIN
    LEFT JOIN dbo.Un_IntReimbOper IRO ON IRO.OperID = RIN.OperID
    LEFT JOIN dbo.Un_IntReimb IR ON IR.IntReimbID = IRO.IntReimbID
    LEFT JOIN dbo.Un_Program P ON P.ProgramID = IR.ProgramID
    LEFT JOIN dbo.Un_College Co ON Co.CollegeID = IR.CollegeID
    LEFT JOIN dbo.Mo_Company CCo ON CCo.CompanyID = Co.CollegeID
    /*  Si c'est la destination d'une operation de cancellation, on va chercher la source
        pour pouvoir afficher la demande de RIN et le cheque s'il existe. */
    LEFT JOIN dbo.DemandeRin DR ON DR.IdOperationRin = ISNULL(RIN.iID_OperationAnnulee, RIN.OperID)
END