/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service    : fntIQEE_ConventionConnueRQ_PourTous
Nom du service  : Toutes conventions connues de RQ
But             : Déterminer toutes les conventions qui sont connues par RQ à une date de référence.
Facette         : IQÉÉ

Paramètres d’entrée :
    Paramètre               Description
    --------------------    ---------------------------------------------------------------------------
    dtDate_Reference        Date à laquelle on désire savoir si la convention est connue de RQ.
                            Si elle est absente, la date du jour est considérée.
    iID_Convention          Identifiant de la convention que l'on désire savoir si elle est connue ou non de RQ.

Exemple d’appel :
    SELECT * from dbo.fntIQEE_ConventionConnueRQ_PourTous(490483, 2015)
    SELECT * from dbo.fntIQEE_ConventionConnueRQ_PourTous(NULL, NULL) order by dtReconnue_RQ desc

Paramètres de sortie :
    Champ                   Description
    --------------------    ---------------------------------
    bConventionConnueRQ     0 = La convention n'est pas connue de RQ à la date de référence
                            1 = La convention est connue de RQ à la date de référence

Historique des modifications:
    Date        Programmeur         Description
    ----------  -----------------   -----------------------------------------------------
    2016-02-18  Steeve Picard       Création du service à partir de fnIQEE_ConventionConnueRQ
    2016-09-01  Steeve Picard       Transformer en InLine-Function
    2016-10-25  Steeve Picard       Correction sur les filtres de «siAnnee_Fiscale»
    2017-03-24  Steeve Picard       Correction sur le filtre «siAnnee_Fiscale» remplacé par «dtDate_Traitement_RQ»
    2017-05-10  Steeve Picard       N'utiliser que la table «tblIQEE_Demandes & tblIQEE_Transferts (Cessionnaire)» avec des réponses reçues
    2017-06-22  Steeve Picard       Change « cStatut_Reponse = 'R' » pour « cStatut_Reponse IN ('D','T','R') »
    2017-11-09  Steeve Picard       Ajout du paramètre «siAnnee_Fiscale»
    2017-12-05  Steeve Picard       Éliminer le paramètre «dtReference» pour filtrer seulement sur l'année fiscale
    2018-02-08  Steeve Picard       Déplacement de «siAnnee_Fiscale» de la table «tblIQEE_Fichiers» vers les tables d'évèments
    2018-09-24  Steeve Picard       Considérer aussi les transferts internes
*********************************************************************************************************************/
CREATE FUNCTION [dbo].[fntIQEE_ConventionConnueRQ_PourTous]
(
    @iID_Convention INT = NULL,
    @siAnnee_Fiscale SMALLINT = NULL
)
RETURNS TABLE AS
RETURN (
    SELECT DISTINCT 
        iID_Convention, vcNo_Convention, MIN(RQ.siAnnee_Fiscale) AS siAnnee_Fiscale, Min(RQ.dtPremiereFois) as dtReconnue_RQ
    FROM 
        (    
            -- T02
            SELECT DISTINCT D.iID_Convention, D.vcNo_Convention, D.siAnnee_Fiscale, dtPremiereFois = CAST(STR(D.siAnnee_Fiscale, 4) + '-12-31' AS DATE)
              FROM dbo.tblIQEE_Demandes D 
                   JOIN dbo.tblIQEE_ReponsesDemande RD ON RD.iID_Demande_IQEE = D.iID_Demande_IQEE
                   JOIN dbo.tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
                                              AND F.bFichier_Test = 0 AND F.bInd_Simulation = 0
             WHERE D.iID_Convention = IsNull(@iID_Convention, D.iID_Convention)
                   AND D.cStatut_Reponse IN ('D','T','R')    
                   AND D.siAnnee_Fiscale < IsNull(@siAnnee_Fiscale, Year(GetDate()))

            UNION ALL

            -- T04-02
            SELECT DISTINCT T.iID_Convention, T.vcNo_Convention, T.siAnnee_Fiscale, T.dtDate_Transfert as dtPremiereFois
              FROM dbo.tblIQEE_Transferts T
                   JOIN dbo.vwIQEE_Enregistrement_TypeEtSousType TS ON TS.cCode_Type_Enregistrement = '04' AND TS.iID_Sous_Type = T.iID_Sous_Type
                   JOIN dbo.tblIQEE_ReponsesTransfert RT ON RT.iID_Transfert_IQEE = T.iID_Transfert
                   JOIN dbo.tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = T.iID_Fichier_IQEE
                                              AND F.bFichier_Test = 0 AND F.bInd_Simulation = 0
             WHERE T.iID_Convention = IsNull(@iID_Convention, T.iID_Convention)
                   AND T.cStatut_Reponse IN ('D','T','R')    
                   AND TS.cCode_Sous_Type = '02'
                   AND T.siAnnee_Fiscale <= IsNull(@siAnnee_Fiscale, Year(GetDate()))

            UNION ALL

            -- T04-03
            SELECT DISTINCT iID_Convention = (SELECT ConventionID FROM dbo.Un_Convention WHERE ConventionNo = T.vcNo_Contrat_Autre_Promoteur), 
                   T.vcNo_Contrat_Autre_Promoteur, T.siAnnee_Fiscale, T.dtDate_Transfert as dtPremiereFois
              FROM dbo.tblIQEE_Transferts T
                   JOIN dbo.vwIQEE_Enregistrement_TypeEtSousType TS ON TS.cCode_Type_Enregistrement = '04' AND TS.iID_Sous_Type = T.iID_Sous_Type
                   JOIN dbo.tblIQEE_ReponsesTransfert RT ON RT.iID_Transfert_IQEE = T.iID_Transfert
                   JOIN dbo.tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = T.iID_Fichier_IQEE
                                              AND F.bFichier_Test = 0 AND F.bInd_Simulation = 0
             WHERE T.iID_Convention = IsNull(@iID_Convention, T.iID_Convention)
                   AND T.cStatut_Reponse IN ('D','T','R')    
                   AND TS.cCode_Sous_Type = '03'
                   AND T.siAnnee_Fiscale <= IsNull(@siAnnee_Fiscale, Year(GetDate()))
        ) RQ
    GROUP BY 
        iID_Convention, vcNo_Convention
)