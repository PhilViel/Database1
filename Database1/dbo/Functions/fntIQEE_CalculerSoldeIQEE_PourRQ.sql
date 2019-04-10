/****************************************************************************************************
Code de service :   fntIQEE_CalculerSoldeIQEE_PourRQ
Nom du service  :   CalculerSoldeIQEE_PourRQ
But             :   Calculer le solde de l'IQÉÉ connu par RQ de base & sa majoration de toutes les conventions
Facette         :   IQÉÉ
Reférence       :   Système de gestion de la relation client

Parametres d'entrée :
        Parametres          Description
        ----------          ----------------
        iID_Convention      ID de la convention concernée par l'appel
        dtDate_Fin          Date de fin de la période considérée par l'appel

Exemple d'appel:
        SELECT * FROM dbo.fntIQEE_CalculerSoldeIQEE_PourRQ(NULL, NULL, NULL) WHERE mCreditBase <> 0 and mMajoration <> 0 ORDER BY vcNo_Convention
        SELECT * FROM dbo.fntIQEE_CalculerSoldeIQEE_PourRQ(252807, 2010, NULL)

Parametres de sortie : Le solde de l'IQEE

Historique des modifications :
    Date         Programmeur             Description
    ----------  --------------------    --------------------------------------------------------
    2017-11-07  Steeve Picard           Création de la fonction
    2018-02-08  Steeve Picard           Déplacement de «siAnnee_Fiscale» de la table «tblIQEE_Fichiers» vers les tables d'évèments
****************************************************************************************************/
CREATE FUNCTION dbo.fntIQEE_CalculerSoldeIQEE_PourRQ ( 
    @iID_Convention INT, 
    @siAnnee SMALLINT,
    @dtDate_Fin DATE
)
RETURNS TABLE
AS RETURN
(
    WITH CTE_Fichier AS (
        SELECT iID_Fichier_IQEE, 
               dtDate_Transaction = CAST(COALESCE(dtDate_Paiement, dtDate_Production_Paiement, dtDate_Traitement_RQ, dtDate_Creation, dtDate_Creation_Fichiers) AS DATE)
          FROM dbo.tblIQEE_Fichiers
         WHERE bFichier_Test = 0 AND bInd_Simulation = 0
           AND CAST(COALESCE(dtDate_Paiement, dtDate_Production_Paiement, dtDate_Traitement_RQ, dtDate_Creation, dtDate_Creation_Fichiers) AS DATE) <= ISNULL(@dtDate_Fin, GETDATE())
    )
    , CTE_Demande AS (
        SELECT D.iID_Convention, D.vcNo_Convention, D.siAnnee_Fiscale, D.iID_Demande_IQEE, D.iID_Ligne_Fichier
          FROM dbo.tblIQEE_Demandes D
               JOIN CTE_Fichier F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
         WHERE D.iID_Convention = ISNULL(@iID_Convention, D.iID_Convention)
           AND D.siAnnee_Fiscale <= ISNULL(@siAnnee, D.siAnnee_Fiscale)
    )
    , CTE_Subvention AS (
        SELECT D.iID_Convention, D.vcNo_Convention, D.siAnnee_Fiscale, F.dtDate_Transaction, D.iID_Ligne_Fichier, 
               tiInverser_Signe = CASE ISNULL(TR.bInverser_Signe_Pour_Injection, 0) WHEN 0 THEN 1 ELSE -1 END,
               mCBQ = CASE TR.cID_Type_Operation_Convention WHEN 'CBQ' THEN R.mMontant ELSE 0 END,
               mMMQ = CASE TR.cID_Type_Operation_Convention WHEN 'MMQ' THEN R.mMontant ELSE 0 END,
               mMIM = CASE TR.cID_Type_Operation_Convention WHEN 'MIM' THEN R.mMontant ELSE 0 END
          FROM dbo.tblIQEE_ReponsesDemande R
               JOIN CTE_Demande D ON D.iID_Demande_IQEE = R.iID_Demande_IQEE
               JOIN CTE_Fichier F ON F.iID_Fichier_IQEE = R.iID_Fichier_IQEE
               JOIN dbo.tblIQEE_TypesReponse TR ON TR.tiID_Type_Reponse = R.tiID_Type_Reponse
         WHERE TR.cID_Type_Operation_Convention IN ('CBQ','MMQ','MIM')
    )
    , CTE_ImpotSpecial AS (
        SELECT I.iID_Convention, I.vcNo_Convention, I.siAnnee_Fiscale, F.dtDate_Transaction, I.iID_Ligne_Fichier, I.iID_Impot_Special,
               tiInverser_Signe = CASE I.tiCode_Version WHEN 1 THEN 1 ELSE -1 END,
               I.mSolde_IQEE_Base, I.mSolde_IQEE_Majore
          FROM dbo.tblIQEE_ImpotsSpeciaux I
               JOIN CTE_Fichier F ON F.iID_Fichier_IQEE = I.iID_Fichier_IQEE
         WHERE I.iID_Convention = ISNULL(@iID_Convention, I.iID_Convention)
           AND NOT I.cStatut_Reponse IN ('E','X')
           AND I.siAnnee_Fiscale <= ISNULL(@siAnnee, I.siAnnee_Fiscale)
    )
    , CTE_ReponseImpotSpecial AS (
        SELECT I.siAnnee_Fiscale, F.dtDate_Transaction, I.iID_Impot_Special,
               R.mMontant_IQEE_Base, R.mMontant_IQEE_Majore, R.mMontant_Interets
          FROM dbo.tblIQEE_ReponsesImpotsSpeciaux R
               JOIN CTE_ImpotSpecial I ON R.iID_Impot_Special_IQEE = I.iID_Impot_Special
               JOIN CTE_Fichier F ON F.iID_Fichier_IQEE = R.iID_Fichier_IQEE
    )
    , CTE_Solde AS (
        SELECT iID_Convention, vcNo_Convention, siAnnee_Fiscale, dtDate_Transaction, iID_Ligne_Fichier, 
               mCreditBase = mCBQ * tiInverser_Signe,
               mMajoration = mMMQ * tiInverser_Signe,
               mInteret = mMIM * tiInverser_Signe
          FROM CTE_Subvention
         UNION
        SELECT I.iID_Convention, I.vcNo_Convention, I.siAnnee_Fiscale, I.dtDate_Transaction, I.iID_Ligne_Fichier,
               mCreditBase = (ISNULL(I.mSolde_IQEE_Base, 0) + ISNULL(R.mMontant_IQEE_Base, 0)) * I.tiInverser_Signe,
               mMajoration = (ISNULL(I.mSolde_IQEE_Majore, 0) + ISNULL(R.mMontant_IQEE_Majore, 0)) * I.tiInverser_Signe,
               mInteret = ISNULL(R.mMontant_Interets, 0) * I.tiInverser_Signe
          FROM CTE_ImpotSpecial I
               LEFT JOIN CTE_ReponseImpotSpecial R ON R.iID_Impot_Special = I.iID_Impot_Special
    )
    SELECT iID_Convention, vcNo_Convention,
           siLast_Annee_Fiscale = MAX(siAnnee_Fiscale), 
           dtLast_Transaction = MAX(dtDate_Transaction), 
           mCreditBase = SUM(mCreditBase),
           mMajoration = SUM(mMajoration),
           mInteret = SUM(mInteret)
      FROM CTE_Solde
     GROUP BY iID_Convention, vcNo_Convention
)
