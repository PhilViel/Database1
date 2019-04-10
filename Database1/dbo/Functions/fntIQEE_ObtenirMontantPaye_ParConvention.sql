/****************************************************************************************************
Code de service        :        fntIQEE_ObtenirMontantPaye_ParConvention
Nom du service        :        Obtient le solde IQEE par convention
But                    :        Obtient le solde IQEE par convention
Facette                :        IQEE
Reférence            :        Système de gestion de la relation client

Parametres d'entrée :    Parametres                    Description
                        ----------                  ----------------
                        iID_Convention              ID de la convention concernée par l'appel
                        Annee_Fiscale               Année fiscale considérée par l'appel


Exemple d'appel:
                SELECT * FROM DBO.fntIQEE_ObtenirMontantPaye_ParConvention (374011, NULL, NULL)
                SELECT * FROM DBO.fntIQEE_ObtenirMontantPaye_ParConvention (150219, 2018, NULL)

Parametres de sortie : Le solde SCEE

Historique des modifications :
            
    Date        Programmeur                                Description                            Référence
    ----------    ------------------------    ----------------------------        ---------------
    2018-03-22  Steeve Picard                Création de la fonction
 ****************************************************************************************************/
CREATE FUNCTION dbo.fntIQEE_ObtenirMontantPaye_ParConvention
(    
    @iID_Convention INT = NULL,
    @siAnneeFiscale INT = NULL,
    @dtEnDateDu DATE = NULL
)
RETURNS TABLE 
AS
RETURN 
(
    WITH CTE_Fichier AS (
        SELECT F.iID_Fichier_IQEE, F.dtDate_Creation, F.dtDate_Traitement_RQ
          FROM dbo.tblIQEE_Fichiers F
         WHERE CAST(ISNULL(F.dtDate_Traitement_RQ, F.dtDate_Creation) AS DATE) <= ISNULL(@dtEnDateDu, GetDate())
           AND F.bFichier_Test = 0 AND F.bInd_Simulation = 0
    ),
    CTE_Impot AS (
        SELECT I.iID_Convention, I.siAnnee_Fiscale, F.dtDate_Creation,
               I.mSolde_IQEE_Base, I.mSolde_IQEE_Majore, I.iID_Impot_Special, I.tiCode_Version, I.cStatut_Reponse,
               RowNum = ROW_NUMBER() OVER(PARTITION BY I.iID_Convention, I.siAnnee_Fiscale ORDER BY I.iID_Ligne_Fichier DESC)
          FROM dbo.tblIQEE_ImpotsSpeciaux I
               JOIN CTE_Fichier F ON F.iID_Fichier_IQEE = I.iID_Fichier_IQEE
         WHERE I.iID_Convention = IsNull(@iID_Convention, I.iID_Convention)
           AND I.siAnnee_Fiscale <= @siAnneeFiscale
           --AND F.dtDate_Creation <= ISNULL(@dtEnDateDu, GetDate())
    ),
    CTE_Reponse AS (
        SELECT I.iID_Convention, I.siAnnee_Fiscale, F.dtDate_Traitement_RQ,
               R.mMontant_IQEE_Base, R.mMontant_IQEE_Majore, R.mMontant_Interets
          FROM CTE_Impot I
               join dbo.tblIQEE_ReponsesImpotsSpeciaux R ON R.iID_Impot_Special_IQEE = I.iID_Impot_Special
               JOIN CTE_Fichier F ON F.iID_Fichier_IQEE = R.iID_Fichier_IQEE
         WHERE I.RowNum = 1
           --AND F.dtDate_Traitement_RQ <= ISNULL(@dtEnDateDu, GetDate())
    )
    SELECT
        I.iID_Convention,  I.siAnnee_Fiscale, 
        dtDate_Traitement_RQ = ISNULL(R.dtDate_Traitement_RQ, I.dtDate_Creation),
        Solde_IQEE = I.mSolde_IQEE_Base + ISNULL(R.mMontant_IQEE_Base, 0),
        Solde_Majoration = I.mSolde_IQEE_Majore + ISNULL(R.mMontant_IQEE_Majore, 0),
        Solde_Interet = ISNULL(R.mMontant_Interets, 0)
    FROM 
        CTE_Impot I 
        LEFT JOIN CTE_Reponse R ON R.iID_Convention = I.iID_Convention AND R.siAnnee_Fiscale = I.siAnnee_Fiscale
    WHERE 
        I.RowNum = 1
        AND I.tiCode_Version IN (0, 2)
        AND I.cStatut_Reponse IN ('A','R')
)
