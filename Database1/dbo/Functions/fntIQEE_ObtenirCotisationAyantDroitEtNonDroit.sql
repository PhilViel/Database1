/****************************************************************************************************
Copyrights (c) 2018 Gestion Universitas inc.

Code du service : fntIQEE_ObtenirCotisationAyantDroitEtNonDroit
Nom du service  : Obtenir le solde subventionné par RQ
But             : Récupérer le solde des cotisations ayant eu droit aux subventions de RQ.
Facette         : IQÉÉ

Paramètres d’entrée :
    Paramètre               Description
    --------------------    ---------------------------------------------------------------------------
    iID_Convention          Identifiant de la convention que l'on désire le solde ayant eu droit et non-droit à l'IQÉÉ.
    dtEnDateDu              Date à laquelle on désire connaître le solde.
                            Si elle est absente, la date du jour est considérée.

Exemple d’appel :
    DECLARE @ConventionID INT = (SELECT ConventionID FROM Un_Convention WHERE ConventionNo = 'R-20060831054')
    SELECT * FROM dbo.fntIQEE_ObtenirCotisationAyantDroitEtNonDroit(@ConventionID, '2009-03-05')

Paramètres de sortie :
    Champ                   Description
    --------------------    ---------------------------------
    mCotAyantDroit          Total des cotisations ayant été subventionnées
    mCotNonDroit            Total des cotisations n'ayant pas été subventionnées

Historique des modifications:
    Date        Programmeur         Description
    ----------  -----------------   -----------------------------------------------------
    2018-09-16  Steeve Picard       Création du service
    2018-11-28  Steeve Picard       Améliorations & nettoyage de codes désuets
*********************************************************************************************************************/
CREATE FUNCTION [dbo].[fntIQEE_ObtenirCotisationAyantDroitEtNonDroit] 
(
--declare
    @iID_Convention INT = NULL,
    @dtEnDateDu DATE = NULL
)
RETURNS TABLE AS
RETURN (
    WITH CTE_Fichier AS (
        SELECT DISTINCT 
            iID_Fichier_IQEE, dtDate_Creation, dtDate_Traitement_RQ
        FROM 
            dbo.tblIQEE_Fichiers F
            JOIN dbo.tblIQEE_TypesFichier T ON T.tiID_Type_Fichier = F.tiID_Type_Fichier
        WHERE
            bFichier_Test = 0 AND bInd_Simulation = 0
    ),
    CTE_Demande AS (
        SELECT
            D.iID_Convention, D.siAnnee_Fiscale, D.iID_Demande_IQEE, D.cStatut_Reponse,
            D.mCotisations, D.mTransfert_IN, 
            mCotisations_Subventionnables = D.mTotal_Cotisations_Subventionnables
        FROM 
            dbo.tblIQEE_Demandes D
            JOIN CTE_Fichier F ON F.iid_Fichier_IQEE = D.iid_Fichier_IQEE
        WHERE 
            D.iID_Convention = ISNULL(@iID_Convention, D.iID_Convention)
            AND NOT D.cStatut_Reponse IN('E','X')
            AND D.siAnnee_Fiscale < YEAR(ISNULL(@dtEnDateDu, GETDATE()))
            AND F.dtDate_Creation < ISNULL(@dtEnDateDu, GETDATE())
    ),
    CTE_Reponse AS (
        SELECT
            D.iID_Demande_IQEE, D.cStatut_Reponse, F.dtDate_Traitement_RQ, R.mMontant, TR.vcCode, TR.vcDescription
        FROM 
            CTE_Demande D
            JOIN dbo.tblIQEE_ReponsesDemande R ON R.iID_Demande_IQEE = D.iID_Demande_IQEE
            JOIN CTE_Fichier F ON F.iid_Fichier_IQEE = R.iid_Fichier_IQEE
            JOIN dbo.tblIQEE_TypesReponse TR ON TR.tiID_Type_Reponse = R.tiID_Type_Reponse
        WHERE 
            F.dtDate_Traitement_RQ < ISNULL(@dtEnDateDu, GETDATE())
            AND TR.vcCode in ('SCD','NSC', 'NMC','MCI')	
    ),
    CTE_Solde AS (
        SELECT 
            iID_Convention, siAnnee_Fiscale, dtDate_Traitement_RQ, mCotisations_Subventionnables, 
            mMontantRecu = ISNULL(mMontant, 0),
            RowNum = ROW_NUMBER() OVER(PARTITION BY iID_Convention, siAnnee_Fiscale ORDER BY dtDate_Traitement_RQ DESC)
        FROM
            CTE_Demande D
            LEFT JOIN CTE_Reponse R ON R.iID_Demande_IQEE = D.iID_Demande_IQEE
        WHERE
            vcCode IN ('NMC','MCI')
    ),
    CTE_Cotisation AS (
        SELECT 
            U.ConventionID, siAnnee_Fiscale = YEAR(o.OperDate), mMontantCotise = SUM(Ct.Cotisation + Ct.Fee)
        FROM
            dbo.fntOPER_Active('2007-02-21', @dtEnDateDu) O
            JOIN dbo.Un_Cotisation Ct ON Ct.OperID = O.OperID
            JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
        WHERE 0=0
            AND (NOT O.OperTypeID IN ('OUT', 'TFR') OR O.OperDate < @dtEnDateDu)
            AND U.ConventionID = ISNULL(@iID_Convention, U.ConventionID)
            AND NOT EXISTS(
                SELECT * FROM dbo.tblOPER_CategoriesOperation CO
                         JOIN dbo.tblOPER_OperationsCategorie OC ON OC.iID_Categorie_Oper = CO.iID_Categorie_Oper
                 WHERE CO.vcCode_Categorie = 'IQEE-DEMANDE-COTISATION' AND OC.cID_Type_Oper = O.OperTypeID
            )
        GROUP BY 
            U.ConventionID, YEAR(o.OperDate)
    )
    SELECT
        iID_Convention = Ct.ConventionID, C.ConventionNo, --Ct.siAnnee_Fiscale, 
        dtTraitement_RQ = MAX(S.dtDate_Traitement_RQ),
        mCotisationsDeclares = SUM(Ct.mMontantCotise), --mCotisations_Subventionnables),
        mCotAyantDroit = SUM(ISNULL(S.mMontantRecu, 0)),
        mCotNonDroit = SUM(ISNULL(CASE WHEN YEAR(S.dtDate_Traitement_RQ) < 2010 THEN ROUND(S.mCotisations_Subventionnables + 0.049, 1) 
                                ELSE ROUND(S.mCotisations_Subventionnables + 0.0049, 2) END 
                           - ISNULL(S.mMontantRecu, 0), Ct.mMontantCotise))
    FROM
        CTE_Cotisation Ct
        JOIN dbo.Un_Convention C ON C.ConventionID = Ct.ConventionID
        LEFT JOIN CTE_Solde S ON S.iID_Convention = Ct.ConventionID AND S.siAnnee_Fiscale = Ct.siAnnee_Fiscale AND S.RowNum = 1
    GROUP BY 
        Ct.ConventionID, C.ConventionNo --, Ct.siAnnee_Fiscale
)
