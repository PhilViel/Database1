/****************************************************************************************************
Code de service : fntIQEE_ObtenirMontantRecu_ParConvention
Nom du service  : Obtient les montant reçus d'IQEE par convention
But             : Obtient le solde IQEE par convention
Facette         : IQEE
Reférence       : Système de gestion de la relation client

Parametres d'entrée :    
    Parametres                    Description
    ----------                  ----------------
    iID_Convention              ID de la convention concernée par l'appel
    Annee_Fiscale               Année fiscale considérée par l'appel

Exemple d'appel:
    SELECT * FROM dbo.fntIQEE_ObtenirMontantRecu_ParConvention (186900, NULL, NULL)

Parametres de sortie : Le solde SCEE

Historique des modifications :
    Date        Programmeur             Description
    ----------    ------------------    -------------------------------------------
    2016-03-21  Steeve Picard           Création de la fonction
    2016-04-08  Steeve Picard           Ajout de champs résultants
    2017-04-12  Steeve Picard           Ajout du champs résultant «iID_Convention»
    2018-02-08  Steeve Picard           Déplacement de «siAnnee_Fiscale» de la table «tblIQEE_Fichiers» vers les tables d'évèments
    2018-06-06  Steeve Picard           Modificiation de la gestion des retours d'erreur par RQ
 ****************************************************************************************************/
CREATE FUNCTION dbo.fntIQEE_ObtenirMontantRecu_ParConvention
( 
    @iID_Convention INT = NULL,
    @dtDate_Debut DATE = NULL,
    @dtDate_Fin DATE = NULL
)
RETURNS TABLE 
AS
RETURN 
(
    WITH CTE_Erreur as (
        SELECT E.iID_Erreur, E.iID_Enregistrement
          FROM dbo.tblIQEE_Erreurs E
               JOIN dbo.tblIQEE_TypesEnregistrement T ON T.tiID_Type_Enregistrement = E.tiID_Type_Enregistrement
         WHERE T.cCode_Type_Enregistrement = '02'
    ),
    CTE_DetailFilter as (
        SELECT RD.iID_Convention, RD.iID_Demande_IQEE, J.cCode, RD.iid_Fichier_IQEE, RD.mMontant,
               Justification_RQ = J.cCode,
               vcCodeReponse = CASE WHEN TR.vcCode = 'NEM' THEN 'EXM' 
                                    WHEN TR.vcCode = 'MAJ' AND J.cCode = '29'  THEN 'EXM' 
                                    ELSE TR.vcCode END 
          FROM dbo.tblIQEE_ReponsesDemande RD
               JOIN dbo.tblIQEE_TypesReponse TR ON TR.tiID_Type_Reponse = RD.tiID_Type_Reponse
               LEFT JOIN dbo.tblIQEE_JustificationsRQ J ON J.tiID_Justification_RQ = RD.tiID_Justification_RQ
         WHERE RD.iID_Convention = IsNull(@iID_Convention, RD.iID_Convention)
           AND TR.vcCode IN ('MCI', 'CDB', 'CBD', 'MAJ', 'MAD', 'INT', 'IND', 'EXM', 'NEM')
    ),
    CTE_Details as (
        SELECT RD.iID_Convention, D.iID_Beneficiaire_31Decembre as iID_Beneficiary, D.siAnnee_Fiscale, F.dtDate_Traitement_RQ, RD.vcCodeReponse, 
               RD.mMontant, D.mCotisations, RD.Justification_RQ,
               Row_Num = Row_Number() OVER(PARTITION BY RD.iID_Convention, RD.vcCodeReponse, D.siAnnee_Fiscale ORDER BY F.dtDate_Traitement_RQ DESC)
          FROM CTE_DetailFilter RD
               JOIN dbo.tblIQEE_Demandes D ON D.iID_Demande_IQEE = RD.iID_Demande_IQEE
               JOIN dbo.tblIQEE_Fichiers F ON F.iid_Fichier_IQEE = RD.iid_Fichier_IQEE
                                          AND F.bFichier_Test = 0 AND F.bInd_Simulation = 0
                                          AND F.dtDate_Traitement_RQ Between IsNull(@dtDate_Debut, '1900-01-01') And IsNull(@dtDate_Fin, GetDate())
         WHERE NOT EXISTS(SELECT * FROM CTE_Erreur WHERE iID_Enregistrement = D.iID_Demande_IQEE)
    ),
    CTE_Summary as (
        SELECT R.iID_Convention, R.iID_Beneficiary, R.siAnnee_Fiscale, Max(R.dtDate_Traitement_RQ) as dtDate_Traitement_RQ, 
               CreditBase = Sum(CASE R.vcCodeReponse WHEN 'CDB' THEN R.mMontant WHEN 'CBD' THEN -R.mMontant ELSE 0 END),
               Majoration = Sum(CASE R.vcCodeReponse WHEN 'MAJ' THEN R.mMontant WHEN 'MAD' THEN -R.mMontant ELSE 0 END),
               PercentMMQ = Max(CASE WHEN R.vcCodeReponse = 'EXM' AND Row_Num = 1 THEN
                                          CASE Justification_RQ WHEN '33' THEN 0.10 
                                                                WHEN '32' THEN 0.05
                                                                WHEN '31' THEN 0.00
                                                                WHEN '29' THEN 0.00
                                                                ELSE NULL END
                                     ELSE NULL END),
               Interet = Sum(CASE R.vcCodeReponse WHEN 'INT' THEN R.mMontant 
                                                  WHEN 'IND' THEN -R.mMontant 
                                                  ELSE 0 END),
               Cotisation = Sum(CASE WHEN R.vcCodeReponse = 'MCI' AND Row_Num = 1 THEN R.mCotisations ELSE 0 END),
               Ayant_Droit_IQEE = Sum(CASE WHEN R.vcCodeReponse = 'MCI' AND Row_Num = 1 THEN R.mMontant ELSE 0 END),
               Row_Num = Row_Number() OVER(PARTITION BY iID_Convention ORDER BY R.siAnnee_Fiscale DESC)
          FROM CTE_Details R
         GROUP BY R.iID_Convention, R.iID_Beneficiary, R.siAnnee_Fiscale --, R.dtDate_Traitement_RQ
    )
    SELECT iID_Convention, iID_Beneficiary, siAnnee_Fiscale, dtDate_Traitement_RQ, Cotisation, 
           Ayant_Droit_IQEE, CreditBase, Majoration, Interet, CAST(PercentMMQ as decimal(10,4)) AS PourcentageMMQ
           --PourcentageMMQ = CAST(CASE WHEN Ayant_Droit_IQEE = 0 THEN NULL
           --                           WHEN Ayant_Droit_IQEE > 500 THEN Majoration / 500
           --                           WHEN Majoration * 5.0 < Ayant_Droit_IQEE THEN Majoration / Ayant_Droit_IQEE
           --                           ELSE NULL
           --                      END as decimal(10, 8))
      FROM CTE_Summary S
)
