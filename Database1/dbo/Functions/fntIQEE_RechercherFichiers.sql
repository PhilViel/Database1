/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service :   fntIQEE_RechercherFichiers
Nom du service  :   Rechercher des fichiers
But             :   Rechercher à travers les fichiers de l’IQÉÉ et obtenir les informations des fichiers.
Facette         :   IQÉÉ

Paramètres d’entrée :
    Paramètre                   Description
    ------------------------    -----------------------------------------------------------------
    cID_Langue                  Identifiant unique de la langue de l’utilisateur selon « Mo_Lang ». Le français est la langue par défaut si elle n’est pas spécifiée.
    iID_Fichier_IQEE            Identifiant unique du fichier de l’IQÉÉ.  S’il est vide, tous les fichiers sont considérés.
    siAnnee_Fiscale_Debut       Année fiscale de début du fichier.  Si elle est vide, toutes les années sont considérées.
    siAnnee_Fiscale_Fin         Année fiscale de fin du fichier.  Si elle est vide, toutes les années sont considérées.
    dtDate_Debut_Creation       Date de début de création/importation du fichier.  Si elle est vide, toutes les dates de création sont considérées ou jusqu’à la date de fin si elle est présente.
    dtDate_Fin_Creation         Date de fin de création/importation du fichier.  Si elle est vide, toutes les dates de création sont considérées ou à partir de la date de début si elle est présente.
    tiID_Type_Fichier           Type de fichier.  S’il est vide, tous les types sont considérés.
    bFichier_Test               Indicateur de fichier test.  S’il est vide, tous les types de fichier sont considérés.
    tiID_Statut_Fichier         Statut du fichier.  S’il est vide, tous les statuts sont considérés.
    bInd_Simulation             Indicateur de simulation.  Égal à 1 signifie de rechercher uniquement les simulations, égal à 0 signifie de rechercher que les fichiers disponibles à l’utilisateur.  
                                S’il est vide, tous les types de fichier sont considérés.
    vcCode_Simulation           Code de simulation spécifique.  Recherche un fichier résultat d’une ou plusieurs simulations de transactions à venir.
    vcCode_Type_Fichier         Code du type de fichier.  S’il est vide, tous les types sont considérés.
    vcCode_Statut               Code du statut de fichier.  S’il est vide, tous les statuts sont considérés.
    vcNom_Fichier               Nom du fichier de l'IQÉÉ.  S'il est vide, tous les fichiers sont considérés.

Exemple d’appel    :    
    SELECT * FROM dbo.fntIQEE_RechercherFichiers(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)

Paramètres de sortie:   Tous les champs de l’historique des paramètres de l’IQÉÉ (tblIQEE_Parametres) en plus des champs suivants.
    Table                       Champ                           Description
    ----------------------      ----------------------------    ---------------------------------
    tblIQEE_Fichiers            *
    tblIQEE_StatutsFichier      vcCode_Statut                   Code de statut
    tblIQEE_TypesFichier        vcCode_Type_Fichier             Code de type de fichier.
    tblIQEE_TypesFichier        bRequiere_Approbation           Indicateur d’approbation requise.
    tblIQEE_TypesFichier        bTeleversable_RQ                Indicateur de téléversement à RQ.
    Mo_Human                    FirstName et LastName           Nom de l’utilisateur qui a fait la création ou l’importation du fichier.
    Mo_Human                    FirstName et LastName           Nom de l’utilisateur qui a fait l’approbation du fichier.
    Mo_Human                    FirstName et LastName           Nom de l’utilisateur qui a téléverser
    
Historique des modifications:
    Date        Programmeur                 Description
    ----------  --------------------    -----------------------------------------------------------
    2008-09-29  Éric Deshaies           Création du service
    2009-02-02  Éric Deshaies           Ajout des champs de simulation
    2009-03-18  Éric Deshaies           Changer le préfixe du service
    2009-04-24  Éric Deshaies           Ajouter le numéro d'identification de RQ
    2009-06-26  Éric Deshaies           Ajouter les codes de type de fichier et statut de fichier comme    paramètres
    2011-03-28  Éric Deshaies           Tenir compte de la date de fin avec les heures dans la recherche par date de création
    2011-04-08  Éric Deshaies           Ajout de nouveaux paramètres et champs de sortie
    2018-02-08  Steeve Picard           Déplacement de «siAnnee_Fiscale» de la table «tblIQEE_Fichiers» vers les tables d'évèments
    2018-06-06  Steeve Picard           Modificiation de la gestion des retours d'erreur par RQ
    2018-10-31  Steeve Picard           Correction lors qu'il y a plusieurs années dans un même fichier lors des Annulations/Reprises
    2018-11-30  Steeve Picard           Optimisation du code
****************************************************************************************************/
CREATE FUNCTION [dbo].[fntIQEE_RechercherFichiers]
(
    @iID_Fichier_IQEE INT,
    @siAnnee_Fiscale_Debut SMALLINT,
    @siAnnee_Fiscale_Fin SMALLINT,
    @dtDate_Debut_Creation DATETIME = '2007-02-21',
    @dtDate_Fin_Creation DATETIME = '9999-12-31',
    @tiID_Type_Fichier TINYINT,
    @bFichier_Test BIT,
    @tiID_Statut_Fichier TINYINT,
    @bInd_Simulation BIT,
    @vcCode_Simulation VARCHAR(100),
    @vcCode_Type_Fichier VARCHAR(3) = 'ERR',
    @vcCode_Statut VARCHAR(3),
    @vcNom_Fichier VARCHAR(50)
)
RETURNS TABLE AS RETURN
(
    WITH CTE_Fichiers AS (
        SELECT 
            F.iID_Fichier_IQEE, F.dtDate_Creation, F.iID_Parametres_IQEE, F.tiID_Type_Fichier,
            F.bFichier_Test, F.tiID_Statut_Fichier, F.vcNom_Fichier, F.tCommentaires, F.iID_Utilisateur_Creation, 
            F.iID_Utilisateur_Approuve, F.dtDate_Approve, F.vcChemin_Fichier, F.iID_Utilisateur_Transmis, F.dtDate_Transmis,
            F.iID_Lien_Fichier_IQEE_Demande, F.mMontant_Total_Paiement, F.dtDate_Production_Paiement, F.dtDate_Paiement,
            F.iNumero_Paiement, F.vcInstitution_Paiement, F.vcTransit_Paiement, F.vcCompte_Paiement, F.dtDate_Modification, 
            SF.vcCode_Statut, TF.vcCode_Type_Fichier, TF.bRequiere_Approbation, TF.bTeleversable_RQ, F.bInd_Simulation,
            F.vcCode_Simulation, F.vcNo_Identification_RQ, F.mMontant_Total_A_Payer, F.mMontant_Total_Cotise, F.mMontant_Total_Recu,
            F.mMontant_Total_Interets, F.mSolde_Paiement_RQ, F.iID_Session, F.dtDate_Creation_Fichiers, F.dtDate_Traitement_RQ
          FROM dbo.tblIQEE_Fichiers F
               JOIN dbo.tblIQEE_StatutsFichier SF ON SF.tiID_Statut_Fichier = F.tiID_Statut_Fichier
               JOIN dbo.tblIQEE_TypesFichier TF ON TF.tiID_Type_Fichier = F.tiID_Type_Fichier
               LEFT JOIN dbo.tblIQEE_Parametres P ON P.iID_Parametres_IQEE = F.iID_Parametres_IQEE
         WHERE 0 = 0
            AND F.iID_Fichier_IQEE = ISNULL(@iID_Fichier_IQEE, F.iID_Fichier_IQEE)
            AND F.dtDate_Creation BETWEEN ISNULL(@dtDate_Debut_Creation, '1900-01-01') AND ISNULL(@dtDate_Fin_Creation, '9999-12-31') 
            AND F.bFichier_Test = ISNULL(@bFichier_Test, 0) 
            AND F.bInd_Simulation = ISNULL(@bInd_Simulation, 0) 
            AND (UPPER(F.vcNom_Fichier) = UPPER(ISNULL(@vcNom_Fichier, F.vcNom_Fichier)))
            AND ( F.tiID_Type_Fichier = ISNULL(@tiID_Type_Fichier, F.tiID_Type_Fichier)
                  OR ( TF.vcCode_Type_Fichier IN ('ERR','PRO','NOU','COT') 
                       AND EXISTS(SELECT * FROM tblIQEE_TypesFichier WHERE tiID_Type_Fichier = @tiID_Type_Fichier AND vcCode_Type_Fichier = 'FRE')
                     )
                  OR ( TF.vcCode_Type_Fichier IN ('PRO','NOU','COT') 
                       AND EXISTS(SELECT * FROM tblIQEE_TypesFichier WHERE tiID_Type_Fichier = @tiID_Type_Fichier AND vcCode_Type_Fichier = 'RTR')
                     )
                )
            AND ( TF.vcCode_Type_Fichier = ISNULL(@vcCode_Type_Fichier, TF.vcCode_Type_Fichier)
                  OR ( TF.vcCode_Type_Fichier IN ('ERR','PRO','NOU','COT') 
                       AND ISNULL(@vcCode_Type_Fichier, '') = 'FRE'
                     )
                  OR ( TF.vcCode_Type_Fichier IN ('PRO','NOU','COT') 
                       AND ISNULL(@vcCode_Type_Fichier, '') = 'RTR'
                     )
                )
            AND ( F.tiID_Statut_Fichier = ISNULL(@tiID_Statut_Fichier, F.tiID_Statut_Fichier)
                  OR ( TF.vcCode_Type_Fichier IN ('ERR','PRO','NOU','COT') 
                       AND EXISTS(SELECT * FROM tblIQEE_StatutsFichier WHERE tiID_Statut_Fichier = @tiID_Statut_Fichier AND vcCode_Statut = 'IM4')
                     )
                  OR ( TF.vcCode_Type_Fichier IN ('PRO','NOU','COT') 
                       AND EXISTS(SELECT * FROM tblIQEE_StatutsFichier WHERE tiID_Statut_Fichier = @tiID_Statut_Fichier AND vcCode_Statut = 'IM5')
                     )
                )
            AND ( SF.vcCode_Statut = ISNULL(@vcCode_Statut, SF.vcCode_Statut)
                  OR EXISTS(SELECT * FROM tblIQEE_TypesFichier WHERE tiID_Type_Fichier = @tiID_Type_Fichier AND vcCode_Type_Fichier = 'FRE')
                  OR EXISTS(SELECT * FROM tblIQEE_TypesFichier WHERE tiID_Type_Fichier = @tiID_Type_Fichier AND vcCode_Type_Fichier = 'RTR')
                )
    ),
    CTE_Erreur AS (
        SELECT DISTINCT
            E.iID_Fichier_IQEE, 
            siAnnee_Fiscale = COALESCE(D.siAnnee_Fiscale, RB.siAnnee_Fiscale, T.siAnnee_Fiscale, PB.siAnnee_Fiscale, I.siAnnee_Fiscale)
        FROM 
            dbo.tblIQEE_Erreurs E
            JOIN dbo.tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = E.tiID_Type_Enregistrement
            LEFT JOIN dbo.tblIQEE_Demandes D ON D.iID_Demande_IQEE = E.iID_Enregistrement --AND TE.cCode_Type_Enregistrement = '02'
            LEFT JOIN dbo.tblIQEE_RemplacementsBeneficiaire RB ON RB.iID_Remplacement_Beneficiaire = E.iID_Enregistrement --AND TE.cCode_Type_Enregistrement = '03'
            LEFT JOIN dbo.tblIQEE_Transferts T ON T.iID_Transfert = E.iID_Enregistrement --AND TE.cCode_Type_Enregistrement = '04'
            LEFT JOIN dbo.tblIQEE_PaiementsBeneficiaires PB ON PB.iID_Paiement_Beneficiaire = E.iID_Enregistrement --AND TE.cCode_Type_Enregistrement = '05'
            LEFT JOIN dbo.tblIQEE_ImpotsSpeciaux  I ON I.iID_Impot_Special = E.iID_Enregistrement --AND TE.cCode_Type_Enregistrement = '06'
        WHERE
            ISNULL(@vcCode_Type_Fichier, 'ERR') = 'ERR'
            AND ( (TE.cCode_Type_Enregistrement = '02' AND D.iID_Demande_IQEE IS NOT NULL)
                  OR (TE.cCode_Type_Enregistrement = '03' AND RB.iID_Remplacement_Beneficiaire IS NOT NULL)
                  OR (TE.cCode_Type_Enregistrement = '04' AND T.iID_Transfert IS NOT NULL)
                  OR (TE.cCode_Type_Enregistrement = '05' AND PB.iID_Paiement_Beneficiaire IS NOT NULL)
                  OR (TE.cCode_Type_Enregistrement = '06' AND I.iID_Impot_Special IS NOT NULL)
                )
    )
    SELECT --DISTINCT 
        F.iID_Fichier_IQEE, D.siAnnee_Fiscale, 
        F.dtDate_Creation, F.iID_Parametres_IQEE, F.tiID_Type_Fichier,
        F.bFichier_Test, F.tiID_Statut_Fichier, F.vcNom_Fichier, F.tCommentaires, F.iID_Utilisateur_Creation, 
        F.iID_Utilisateur_Approuve, F.dtDate_Approve, F.vcChemin_Fichier, F.iID_Utilisateur_Transmis, F.dtDate_Transmis,
        F.iID_Lien_Fichier_IQEE_Demande, F.mMontant_Total_Paiement, F.dtDate_Production_Paiement, F.dtDate_Paiement,
        F.iNumero_Paiement, F.vcInstitution_Paiement, F.vcTransit_Paiement, F.vcCompte_Paiement,
        F.dtDate_Modification, F.vcCode_Statut, F.vcCode_Type_Fichier, F.bRequiere_Approbation, F.bTeleversable_RQ,
        vcUtilisateur_Createur = ISNULL(U1.FirstName + ' ' + U1.LastName, 'Username not found (UserID: ' + LTRIM(STR(F.iID_Utilisateur_Creation)) + ')'), 
        vcUtilisateur_Approbateur = ISNULL(U2.FirstName + ' ' + U2.LastName, 'Username not found (UserID: ' + LTRIM(STR(F.iID_Utilisateur_Approuve)) + ')'), 
        vcUtilisateur_Transmission = ISNULL(U3.FirstName + ' ' + U3.LastName, 'Username not found (UserID: ' + LTRIM(STR(F.iID_Utilisateur_Transmis)) + ')'), 
        F.bInd_Simulation,
        F.vcCode_Simulation, F.vcNo_Identification_RQ, F.mMontant_Total_A_Payer, F.mMontant_Total_Cotise, F.mMontant_Total_Recu,
        F.mMontant_Total_Interets, F.mSolde_Paiement_RQ, F.iID_Session, F.dtDate_Creation_Fichiers, F.dtDate_Traitement_RQ
    FROM 
        CTE_Fichiers F 
        LEFT JOIN ( 
            SELECT DISTINCT iID_Fichier_IQEE, siAnnee_Fiscale FROM dbo.tblIQEE_Demandes
             WHERE siAnnee_Fiscale BETWEEN ISNULL(@siAnnee_Fiscale_Debut, 1900) AND ISNULL(@siAnnee_Fiscale_Fin, 9999)
            UNION 
            SELECT DISTINCT R.iID_Fichier_IQEE, D.siAnnee_Fiscale
              FROM dbo.tblIQEE_ReponsesDemande R 
                   JOIN dbo.tblIQEE_Demandes D ON D.iID_Demande_IQEE = R.iID_Demande_IQEE
             WHERE siAnnee_Fiscale BETWEEN ISNULL(@siAnnee_Fiscale_Debut, 1900) AND ISNULL(@siAnnee_Fiscale_Fin, 9999)
            UNION 
            SELECT DISTINCT iID_Fichier_IQEE, siAnnee_Fiscale FROM dbo.tblIQEE_RemplacementsBeneficiaire
             WHERE siAnnee_Fiscale BETWEEN ISNULL(@siAnnee_Fiscale_Debut, 1900) AND ISNULL(@siAnnee_Fiscale_Fin, 9999)
            UNION 
            SELECT DISTINCT R.iID_Fichier_IQEE, RB.siAnnee_Fiscale
              FROM dbo.tblIQEE_ReponsesRemplacement R 
                   JOIN dbo.tblIQEE_RemplacementsBeneficiaire RB ON RB.iID_Remplacement_Beneficiaire = R.iID_Remplacement_IQEE
             WHERE siAnnee_Fiscale BETWEEN ISNULL(@siAnnee_Fiscale_Debut, 1900) AND ISNULL(@siAnnee_Fiscale_Fin, 9999)
            UNION 
            SELECT DISTINCT iID_Fichier_IQEE, siAnnee_Fiscale FROM dbo.tblIQEE_Transferts
             WHERE siAnnee_Fiscale BETWEEN ISNULL(@siAnnee_Fiscale_Debut, 1900) AND ISNULL(@siAnnee_Fiscale_Fin, 9999)
            UNION 
            SELECT DISTINCT R.iID_Fichier_IQEE, T.siAnnee_Fiscale
              FROM dbo.tblIQEE_ReponsesTransfert R 
                   JOIN dbo.tblIQEE_Transferts T ON T.iID_Transfert = R.iID_Transfert_IQEE
             WHERE siAnnee_Fiscale BETWEEN ISNULL(@siAnnee_Fiscale_Debut, 1900) AND ISNULL(@siAnnee_Fiscale_Fin, 9999)
            UNION 
            SELECT DISTINCT iID_Fichier_IQEE, siAnnee_Fiscale FROM dbo.tblIQEE_PaiementsBeneficiaires
             WHERE siAnnee_Fiscale BETWEEN ISNULL(@siAnnee_Fiscale_Debut, 1900) AND ISNULL(@siAnnee_Fiscale_Fin, 9999)
            UNION 
            SELECT DISTINCT R.iID_Fichier_IQEE, PB.siAnnee_Fiscale
              FROM dbo.tblIQEE_ReponsesPaiement R 
                   JOIN dbo.tblIQEE_PaiementsBeneficiaires PB ON PB.iID_Paiement_Beneficiaire = R.iID_Paiement_IQEE
             WHERE siAnnee_Fiscale BETWEEN ISNULL(@siAnnee_Fiscale_Debut, 1900) AND ISNULL(@siAnnee_Fiscale_Fin, 9999)
            UNION 
            SELECT DISTINCT iID_Fichier_IQEE, siAnnee_Fiscale FROM dbo.tblIQEE_ImpotsSpeciaux
             WHERE siAnnee_Fiscale BETWEEN ISNULL(@siAnnee_Fiscale_Debut, 1900) AND ISNULL(@siAnnee_Fiscale_Fin, 9999)
            UNION 
            SELECT DISTINCT R.iID_Fichier_IQEE, I.siAnnee_Fiscale
              FROM dbo.tblIQEE_ReponsesImpotsSpeciaux R 
                   JOIN dbo.tblIQEE_ImpotsSpeciaux I ON I.iID_Impot_Special = R.iID_Impot_Special_IQEE
             WHERE siAnnee_Fiscale BETWEEN ISNULL(@siAnnee_Fiscale_Debut, 1900) AND ISNULL(@siAnnee_Fiscale_Fin, 9999)
            UNION 
            SELECT DISTINCT iID_Fichier_IQEE, siAnnee_Fiscale FROM dbo.tblIQEE_Rejets
             WHERE siAnnee_Fiscale BETWEEN ISNULL(@siAnnee_Fiscale_Debut, 1900) AND ISNULL(@siAnnee_Fiscale_Fin, 9999)
            UNION 
            SELECT DISTINCT iID_Fichier_IQEE, siAnnee_Fiscale FROM CTE_Erreur
             WHERE siAnnee_Fiscale BETWEEN ISNULL(@siAnnee_Fiscale_Debut, 1900) AND ISNULL(@siAnnee_Fiscale_Fin, 9999)
        ) D ON D.iID_Fichier_IQEE = F.iID_Fichier_IQEE
        LEFT JOIN dbo.Mo_Human U1 ON U1.HumanID = F.iID_Utilisateur_Creation
        LEFT JOIN dbo.Mo_Human U2 ON U2.HumanID = F.iID_Utilisateur_Approuve
        LEFT JOIN dbo.Mo_Human U3 ON U3.HumanID = F.iID_Utilisateur_Transmis
    WHERE 0 = 0
        --AND D.siAnnee_Fiscale BETWEEN ISNULL(@siAnnee_Fiscale_Debut, 1900) AND ISNULL(@siAnnee_Fiscale_Fin, 9999)
)

