/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service        : psIQEE_SupprimerFichier
Nom du service        : Supprimer un fichier 
But                 : Supprimer un fichier de l’IQÉÉ.
Facette                : IQÉÉ

Paramètres d’entrée    :    Paramètre                    Description
                        --------------------------    -----------------------------------------------------------------
                          iID_Fichier_IQEE            Identifiant unique du fichier à mettre à jour.

Exemple d’appel        :    exec [dbo].[psIQEE_SupprimerFichier] 5825

Paramètres de sortie:    Table                        Champ                            Description
                          -------------------------    ---------------------------     ---------------------------------
                        S/O                            iCode_Retour                    0 = Traitement réussi
                                                                                    -1 = Paramètres incomplets
                                                                                    -2 = Erreur de traitement

Historique des modifications:
    Date        Programmeur             Description
    ----------  --------------------    -----------------------------------------------------
    2008-10-31  Éric Deshaies           Création du service                            
    2009-04-09  Éric Deshaies           Mettre à jour le statut des erreurs de l’IQÉÉ pour tenir compte des erreurs qui ne sont plus 
                                        terminées par les transactions de correction qui avait été créées par le fichier supprimé
    2009-08-17  Éric Deshaies           Remplacement des "ON DELETE CASCADE" sur les contraintes des fichiers de l'IQÉÉ par une
                                        suppression contrôlée par la procédure.
                                        Empêcher la suppression d'un fichier de transactions qui est associé à des réponses
    2016-01-06  Steeve Picard           Ajout de la gestion des fichiers de type «COT»
    2016-05-02  Steeve Picard           Ajout de la supression dans la nouvelle table «tblIQEE_ReponsesTransfert»
    2016-12-16  Steeve Picard           Ajout de la supression dans la table «un_ConventionOper» pour les fichiers «COT»
    2017-04-19  Steeve Picard           Ajout du paramètre «@bConserveFichier» qui conserve le record dans la table «tblIQEE_Fichiers»
    2017-06-08  Steeve Picard           Efface les opérations correspondantes de la table «tblIQEE_ImpotsSpeciaux»
    2018-02-08  Steeve Picard           Déplacement de «siAnnee_Fiscale» de la table «tblIQEE_Fichiers» vers les tables d'évèments
    2018-05-09  Steeve Picard           Ajout des nouveaux fichiers «REM, TRA & PAE» pour les transactions «T53, T54 & T55»
                                        Rectification des statuts dans le cas de fichier d'erreurs ou de réponses
    2018-06-06  Steeve Picard           Modificiation de la gestion des retours d'erreur par RQ
    2018-08-01  Steeve Picard           Correction pour effacer les enregistrement dans «tblIQEE_ConventionOper»
*********************************************************************************************************************/
CREATE PROCEDURE dbo.psIQEE_SupprimerFichier
(
    @iID_Fichier_IQEE INT,
    @bConserveFichier BIT = 0
) AS
BEGIN
    -- Retourner -1 s'il y a des paramètres manquants ou que le fichier n'existe pas
    IF @iID_Fichier_IQEE IS NULL OR @iID_Fichier_IQEE = 0 OR
       NOT EXISTS(SELECT * 
                  FROM tblIQEE_Fichiers
                  WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE)
        RETURN -1

    -- Retourner -2 si le fichier à supprimer est un fichier de demandes qui est associé à une réponse.  Les fichiers de réponses
    -- doivent être supprimées avant le fichier de demandes.
    IF EXISTS(SELECT *
              FROM tblIQEE_ReponsesDemande RD
                     JOIN tblIQEE_Demandes D ON D.iID_Demande_IQEE = RD.iID_Demande_IQEE
                                          AND D.iID_Fichier_IQEE = @iID_Fichier_IQEE) OR
       EXISTS(SELECT *
                FROM tblIQEE_Erreurs E
                     JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = E.tiID_Type_Enregistrement
                     JOIN tblIQEE_Demandes D ON D.iID_Demande_IQEE = E.iID_Enregistrement
               WHERE TE.cCode_Type_Enregistrement = '02'
                     AND D.iID_Fichier_IQEE = @iID_Fichier_IQEE
)
-- TODO: Si présence d'un fichier COT, refuser la suppression
        RETURN -2

    IF object_id('tempdb..#DisableTrigger') IS NULL
        CREATE TABLE #DisableTrigger (vcTriggerName VARCHAR(200))

    BEGIN TRANSACTION

    BEGIN TRY
        -- Trouver les informations utiles
        DECLARE @bFichier_Test BIT,
                @vcCode_Type_Fichier VARCHAR(3)

        SELECT @bFichier_Test = F.bFichier_Test,
               @vcCode_Type_Fichier = TF.vcCode_Type_Fichier
        FROM tblIQEE_Fichiers F
             JOIN tblIQEE_TypesFichier TF ON TF.tiID_Type_Fichier = F.tiID_Type_Fichier
        WHERE F.iID_Fichier_IQEE = @iID_Fichier_IQEE

        -- Suppression des informations du fichier
        DELETE tblIQEE_LignesFichier
        WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE

        -- Inverser l'importation des erreurs
        IF @vcCode_Type_Fichier = 'ERR'
            BEGIN
                UPDATE D SET
                    cStatut_Reponse = CASE D.tiCode_Version WHEN 1 THEN 'D' ELSE 'A' END
                FROM
                    dbo.tblIQEE_Demandes D
                    JOIN dbo.tblIQEE_Erreurs E ON E.iID_Enregistrement = D.iID_Demande_IQEE
                    JOIN dbo.tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = E.tiID_Type_Enregistrement
                WHERE 
                    D.cStatut_Reponse = 'E'
                    AND E.iID_Fichier_IQEE = @iID_Fichier_IQEE
                    AND TE.cCode_Type_Enregistrement = '02'

                UPDATE RB SET
                    cStatut_Reponse = CASE RB.tiCode_Version WHEN 1 THEN 'D' ELSE 'A' END
                FROM
                    dbo.tblIQEE_RemplacementsBeneficiaire RB
                    JOIN dbo.tblIQEE_Erreurs E ON E.iID_Enregistrement = RB.iID_Remplacement_Beneficiaire
                    JOIN dbo.tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = E.tiID_Type_Enregistrement
                WHERE 
                    RB.cStatut_Reponse = 'E'
                    AND E.iID_Fichier_IQEE = @iID_Fichier_IQEE
                    AND TE.cCode_Type_Enregistrement = '03'

                UPDATE T SET
                    cStatut_Reponse = CASE T.tiCode_Version WHEN 1 THEN 'D' ELSE 'A' END
                FROM
                    dbo.tblIQEE_Transferts T
                    JOIN dbo.tblIQEE_Erreurs E ON E.iID_Enregistrement = T.iID_Transfert
                    JOIN dbo.tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = E.tiID_Type_Enregistrement
                WHERE 
                    T.cStatut_Reponse = 'E'
                    AND E.iID_Fichier_IQEE = @iID_Fichier_IQEE
                    AND TE.cCode_Type_Enregistrement = '04'

                UPDATE PB SET
                    cStatut_Reponse = CASE PB.tiCode_Version WHEN 1 THEN 'D' ELSE 'A' END
                FROM
                    dbo.tblIQEE_PaiementsBeneficiaires PB
                    JOIN dbo.tblIQEE_Erreurs E ON E.iID_Enregistrement = PB.iID_Paiement_Beneficiaire
                    JOIN dbo.tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = E.tiID_Type_Enregistrement
                WHERE 
                    PB.cStatut_Reponse = 'E'
                    AND E.iID_Fichier_IQEE = @iID_Fichier_IQEE
                    AND TE.cCode_Type_Enregistrement = '05'

                UPDATE I SET
                    cStatut_Reponse = CASE I.tiCode_Version WHEN 1 THEN 'D' ELSE 'A' END
                FROM
                    dbo.tblIQEE_ImpotsSpeciaux I
                    JOIN dbo.tblIQEE_Erreurs E ON E.iID_Enregistrement = I.iID_Impot_Special
                    JOIN dbo.tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = E.tiID_Type_Enregistrement
                WHERE 
                    I.cStatut_Reponse = 'E'
                    AND E.iID_Fichier_IQEE = @iID_Fichier_IQEE
                    AND TE.cCode_Type_Enregistrement = '06'

                DELETE tblIQEE_Erreurs
                WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE
            END

        IF OBJECT_ID('tempDB..#TB_Oper_ToDeleted') IS NOT NULL 
            DROP TABLE #TB_Oper_ToDeleted
        CREATE TABLE #TB_Oper_ToDeleted (OperID int)

        -- Inverser l'importation des rapports de détermination de crédit
        IF @vcCode_Type_Fichier = 'PRO'
            BEGIN
                UPDATE D SET
                    cStatut_Reponse = CASE D.cStatut_Reponse WHEN 'T' THEN 'D' ELSE 'A' END
                FROM
                    dbo.tblIQEE_Demandes D
                    JOIN dbo.tblIQEE_ReponsesDemande RD ON RD.iID_Demande_IQEE = D.iID_Demande_IQEE
                WHERE 
                    D.cStatut_Reponse IN ('R', 'T')
                    AND RD.iID_Fichier_IQEE = @iID_Fichier_IQEE

                INSERT INTO #DisableTrigger (vcTriggerName) VALUES ('TUn_ConventionOper')

                DELETE FROM CO
                OUTPUT Deleted.OperID INTO #TB_Oper_ToDeleted (OperID)
                  FROM dbo.Un_ConventionOper CO
                       JOIN dbo.tblIQEE_ReponsesDemande R ON R.iID_Transaction_Convention_Ajustement_CBQ = CO.ConventionOperID
                                                          OR R.iID_Transaction_Convention_Ajustement_MMQ = CO.ConventionOperID
                 WHERE R.iID_Fichier_IQEE = @iID_Fichier_IQEE

                DELETE tblIQEE_ReponsesDemande
                WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE
            END

        -- Inverser l'importation des rapports de redétermination de crédit
        IF @vcCode_Type_Fichier = 'NOU'
            BEGIN

                INSERT INTO #DisableTrigger (vcTriggerName) VALUES ('TUn_ConventionOper')

                DELETE FROM CO
                OUTPUT Deleted.OperID INTO #TB_Oper_ToDeleted (OperID)
                  FROM dbo.Un_ConventionOper CO
                       JOIN dbo.tblIQEE_ReponsesDemande R ON R.iID_Transaction_Convention_Ajustement_CBQ = CO.ConventionOperID
                                                          OR R.iID_Transaction_Convention_Ajustement_MMQ = CO.ConventionOperID
                 WHERE R.iID_Fichier_IQEE = @iID_Fichier_IQEE

                DELETE tblIQEE_ReponsesDemande
                WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE
            END

        -- Inverser l'importation des rapports de remplacement bénéficiaire
        IF @vcCode_Type_Fichier = 'REM'
            BEGIN
                UPDATE RB SET
                    cStatut_Reponse = CASE RB.cStatut_Reponse WHEN 'T' THEN 'D' ELSE 'A' END
                FROM
                    dbo.tblIQEE_RemplacementsBeneficiaire RB
                    JOIN dbo.tblIQEE_ReponsesRemplacement RR ON RR.iID_Remplacement_IQEE = RB.iID_Remplacement_Beneficiaire
                WHERE 
                    RB.cStatut_Reponse IN ('R', 'T')
                    AND RR.iID_Fichier_IQEE = @iID_Fichier_IQEE

                DELETE dbo.tblIQEE_ReponsesRemplacement
                WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE
            END

        -- Inverser l'importation des rapports de transfert
        IF @vcCode_Type_Fichier = 'TRA'
            BEGIN
                UPDATE T SET
                    cStatut_Reponse = CASE T.cStatut_Reponse WHEN 'T' THEN 'D' ELSE 'A' END
                FROM
                    dbo.tblIQEE_Transferts T
                    JOIN dbo.tblIQEE_ReponsesTransfert RT ON RT.iID_Transfert_IQEE = T.iID_Transfert
                WHERE 
                    T.cStatut_Reponse IN ('R', 'T')
                    AND RT.iID_Fichier_IQEE = @iID_Fichier_IQEE

                DELETE dbo.tblIQEE_ReponsesTransfert
                WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE
            END

        -- Inverser l'importation des rapports de paiement PAE
        IF @vcCode_Type_Fichier = 'PAE'
            BEGIN
                UPDATE PB SET
                    cStatut_Reponse = CASE PB.cStatut_Reponse WHEN 'T' THEN 'D' ELSE 'A' END
                FROM
                    dbo.tblIQEE_PaiementsBeneficiaires PB
                    JOIN dbo.tblIQEE_ReponsesPaiement RP ON RP.iID_Paiement_IQEE = PB.iID_Paiement_Beneficiaire
                WHERE 
                    PB.cStatut_Reponse IN ('R', 'T')
                    AND RP.iID_Fichier_IQEE = @iID_Fichier_IQEE

                DELETE dbo.tblIQEE_ReponsesPaiement
                WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE
            END

        -- Inverser l'importation des avis de cotisation (COT)
        IF @vcCode_Type_Fichier = 'COT'
            BEGIN
                DELETE dbo.tblIQEE_StatistiquesImpotsSpeciaux
                WHERE iID_Fichier_Reponse_Impots_Speciaux = @iID_Fichier_IQEE

                INSERT INTO #DisableTrigger (vcTriggerName) VALUES ('TUn_ConventionOper')

                ;WITH CTE_Reponse as (
                        SELECT * FROM dbo.tblIQEE_ReponsesImpotsSpeciaux 
                        WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE
                )
                DELETE FROM CO
                OUTPUT Deleted.OperID INTO #TB_Oper_ToDeleted (OperID)
                  FROM dbo.un_ConventionOper CO
                       JOIN dbo.tblIQEE_ReponsesImpotsSpeciaux R ON R.iID_Paiement_Impot_CBQ = CO.ConventionOperID
                                                                 OR R.iID_Paiement_Impot_MMQ = CO.ConventionOperID
                                                                 OR R.iID_Paiement_Impot_MIM = CO.ConventionOperID

                UPDATE I SET
                    cStatut_Reponse = CASE I.cStatut_Reponse WHEN 'T' THEN 'D' ELSE 'A' END
                FROM
                    dbo.tblIQEE_ImpotsSpeciaux I
                    JOIN dbo.tblIQEE_ReponsesImpotsSpeciaux RI ON RI.iID_Impot_Special_IQEE = I.iID_Impot_Special
                WHERE 
                    I.cStatut_Reponse IN ('R', 'T')
                    AND RI.iID_Fichier_IQEE = @iID_Fichier_IQEE

                DELETE dbo.tblIQEE_ReponsesImpotsSpeciaux
                WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE
            END

        ------------------------------------------------
        -- Mettre à jour le statut des erreurs de l’IQÉÉ
        ------------------------------------------------
        IF @vcCode_Type_Fichier = 'DEM' AND @bFichier_Test = 0
            BEGIN
                DECLARE @tiID_Statuts_Erreur TINYINT

                -- Trouver l'identifiant du statut d'erreur "Terminée" (TER)
                SELECT @tiID_Statuts_Erreur = SE.tiID_Statuts_Erreur
                FROM tblIQEE_StatutsErreur SE
                WHERE SE.vcCode_Statut = 'TAR'

                -- Mettre à jour les erreurs sur les demandes d'IQÉÉ
                UPDATE tblIQEE_Erreurs
                SET tiID_Statuts_Erreur = @tiID_Statuts_Erreur
                FROM tblIQEE_Erreurs E
                     JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = E.tiID_Type_Enregistrement
                                                        AND TE.cCode_Type_Enregistrement = '02'
                     JOIN tblIQEE_StatutsErreur SE ON SE.tiID_Statuts_Erreur = E.tiID_Statuts_Erreur
                                                  AND SE.vcCode_Statut = 'TER'
                     JOIN tblIQEE_Demandes D1 ON D1.iID_Demande_IQEE = E.iID_Enregistrement
                     JOIN tblIQEE_Fichiers F1 ON F1.iID_Fichier_IQEE = D1.iID_Fichier_IQEE
                WHERE NOT EXISTS (SELECT *
                                  FROM tblIQEE_Demandes D2
                                       JOIN tblIQEE_Fichiers F2 ON F2.iID_Fichier_IQEE = D2.iID_Fichier_IQEE
                                                               AND F2.dtDate_Creation > F1.dtDate_Creation
                                  WHERE D2.iID_Convention = D1.iID_Convention
                                    AND D2.siAnnee_Fiscale = D1.siAnnee_Fiscale)

                -- Mettre à jour les erreurs sur les remplacements de bénéficiaire
                UPDATE tblIQEE_Erreurs
                SET tiID_Statuts_Erreur = @tiID_Statuts_Erreur
                FROM tblIQEE_Erreurs E
                     JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = E.tiID_Type_Enregistrement
                                                        AND TE.cCode_Type_Enregistrement = '03'
                     JOIN tblIQEE_StatutsErreur SE ON SE.tiID_Statuts_Erreur = E.tiID_Statuts_Erreur
                                                  AND SE.vcCode_Statut = 'TER'
                     JOIN tblIQEE_RemplacementsBeneficiaire RB1 ON RB1.iID_Remplacement_Beneficiaire = E.iID_Enregistrement
                     JOIN tblIQEE_Fichiers F1 ON F1.iID_Fichier_IQEE = RB1.iID_Fichier_IQEE
                WHERE NOT EXISTS (SELECT *
                                  FROM tblIQEE_RemplacementsBeneficiaire RB2
                                       JOIN tblIQEE_Fichiers F2 ON F2.iID_Fichier_IQEE = RB2.iID_Fichier_IQEE
                                                               AND F2.dtDate_Creation > F1.dtDate_Creation
                                  WHERE RB2.iID_Convention = RB1.iID_Convention
                                    AND RB2.iID_Changement_Beneficiaire = RB1.iID_Changement_Beneficiaire
                                    AND RB2.siAnnee_Fiscale = RB1.siAnnee_Fiscale)

                -- Mettre à jour les erreurs sur les transferts
                UPDATE tblIQEE_Erreurs
                SET tiID_Statuts_Erreur = @tiID_Statuts_Erreur
                FROM tblIQEE_Erreurs E
                     JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = E.tiID_Type_Enregistrement
                                                        AND TE.cCode_Type_Enregistrement = '04'
                     JOIN tblIQEE_StatutsErreur SE ON SE.tiID_Statuts_Erreur = E.tiID_Statuts_Erreur
                                                  AND SE.vcCode_Statut = 'TER'
                     JOIN tblIQEE_Transferts T1 ON T1.iID_Transfert = E.iID_Enregistrement
                     JOIN tblIQEE_Fichiers F1 ON F1.iID_Fichier_IQEE = T1.iID_Fichier_IQEE
                WHERE NOT EXISTS (SELECT *
                                  FROM tblIQEE_Transferts T2
                                       JOIN tblIQEE_Fichiers F2 ON F2.iID_Fichier_IQEE = T2.iID_Fichier_IQEE
                                                               AND F2.dtDate_Creation > F1.dtDate_Creation
                                  WHERE T2.iID_Convention = T1.iID_Convention
                                    AND T2.iID_Operation = T1.iID_Operation
                                    AND T2.siAnnee_Fiscale = T1.siAnnee_Fiscale)

                -- Mettre à jour les erreurs sur les paiements aux bénéficiaires
                UPDATE tblIQEE_Erreurs
                SET tiID_Statuts_Erreur = @tiID_Statuts_Erreur
                FROM tblIQEE_Erreurs E
                     JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = E.tiID_Type_Enregistrement
                                                        AND TE.cCode_Type_Enregistrement = '05'
                     JOIN tblIQEE_StatutsErreur SE ON SE.tiID_Statuts_Erreur = E.tiID_Statuts_Erreur
                                                  AND SE.vcCode_Statut = 'TER'
                     JOIN tblIQEE_PaiementsBeneficiaires PB1 ON PB1.iID_Paiement_Beneficiaire = E.iID_Enregistrement
                     JOIN tblIQEE_Fichiers F1 ON F1.iID_Fichier_IQEE = PB1.iID_Fichier_IQEE
                WHERE NOT EXISTS (SELECT *
                                  FROM tblIQEE_PaiementsBeneficiaires PB2
                                       JOIN tblIQEE_Fichiers F2 ON F2.iID_Fichier_IQEE = PB2.iID_Fichier_IQEE
                                                               AND F2.dtDate_Creation > F1.dtDate_Creation
                                  WHERE PB2.iID_Convention = PB1.iID_Convention
                                    AND PB2.iID_Operation = PB1.iID_Operation
                                    AND PB2.siAnnee_Fiscale = PB1.siAnnee_Fiscale)

                -- Mettre à jour les erreurs sur les impôts spéciaux basés sur l'identifiant de remplacement
                -- de bénéficiaire
                UPDATE tblIQEE_Erreurs
                SET tiID_Statuts_Erreur = @tiID_Statuts_Erreur
                FROM tblIQEE_Erreurs E
                     JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = E.tiID_Type_Enregistrement
                                                        AND TE.cCode_Type_Enregistrement = '06'
                     JOIN tblIQEE_StatutsErreur SE ON SE.tiID_Statuts_Erreur = E.tiID_Statuts_Erreur
                                                  AND SE.vcCode_Statut = 'TER'
                     JOIN tblIQEE_ImpotsSpeciaux IS1 ON IS1.iID_Impot_Special = E.iID_Enregistrement
                     JOIN tblIQEE_SousTypeEnregistrement ST ON ST.iID_Sous_Type = IS1.iID_Sous_Type
                                                           AND ST.cCode_Sous_Type = '01'
                     JOIN tblIQEE_Fichiers F1 ON F1.iID_Fichier_IQEE = IS1.iID_Fichier_IQEE
                WHERE NOT EXISTS (SELECT *
                                  FROM tblIQEE_ImpotsSpeciaux IS2
                                       JOIN tblIQEE_Fichiers F2 ON F2.iID_Fichier_IQEE = IS2.iID_Fichier_IQEE
                                                               AND F2.dtDate_Creation > F1.dtDate_Creation
                                  WHERE IS2.iID_Convention = IS1.iID_Convention
                                    AND IS2.iID_Remplacement_Beneficiaire = IS1.iID_Remplacement_Beneficiaire
                                    AND IS2.siAnnee_Fiscale = IS1.siAnnee_Fiscale)

                -- Mettre à jour les erreurs sur les impôts spéciaux basés sur l'identifiant de transfert
                UPDATE tblIQEE_Erreurs
                SET tiID_Statuts_Erreur = @tiID_Statuts_Erreur
                FROM tblIQEE_Erreurs E
                     JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = E.tiID_Type_Enregistrement
                                                        AND TE.cCode_Type_Enregistrement = '06'
                     JOIN tblIQEE_StatutsErreur SE ON SE.tiID_Statuts_Erreur = E.tiID_Statuts_Erreur
                                                  AND SE.vcCode_Statut = 'TER'
                     JOIN tblIQEE_ImpotsSpeciaux IS1 ON IS1.iID_Impot_Special = E.iID_Enregistrement
                     JOIN tblIQEE_SousTypeEnregistrement ST ON ST.iID_Sous_Type = IS1.iID_Sous_Type
                                                           AND ST.cCode_Sous_Type = '11'
                     JOIN tblIQEE_Fichiers F1 ON F1.iID_Fichier_IQEE = IS1.iID_Fichier_IQEE
                WHERE NOT EXISTS (SELECT *
                                  FROM tblIQEE_ImpotsSpeciaux IS2
                                       JOIN tblIQEE_Fichiers F2 ON F2.iID_Fichier_IQEE = IS2.iID_Fichier_IQEE
                                                               AND F2.dtDate_Creation > F1.dtDate_Creation
                                  WHERE IS2.iID_Convention = IS1.iID_Convention
                                    AND IS2.iID_Transfert = IS1.iID_Transfert
                                    AND IS2.siAnnee_Fiscale = IS1.siAnnee_Fiscale)

                -- Mettre à jour les erreurs sur les impôts spéciaux basés sur l'identifiant de l'opération
                UPDATE tblIQEE_Erreurs
                SET tiID_Statuts_Erreur = @tiID_Statuts_Erreur
                FROM tblIQEE_Erreurs E
                     JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = E.tiID_Type_Enregistrement
                                                        AND TE.cCode_Type_Enregistrement = '06'
                     JOIN tblIQEE_StatutsErreur SE ON SE.tiID_Statuts_Erreur = E.tiID_Statuts_Erreur
                                                  AND SE.vcCode_Statut = 'TER'
                     JOIN tblIQEE_ImpotsSpeciaux IS1 ON IS1.iID_Impot_Special = E.iID_Enregistrement
                     JOIN tblIQEE_SousTypeEnregistrement ST ON ST.iID_Sous_Type = IS1.iID_Sous_Type
                                                           AND ST.cCode_Sous_Type IN ('12','23')
                     JOIN tblIQEE_Fichiers F1 ON F1.iID_Fichier_IQEE = IS1.iID_Fichier_IQEE
                WHERE NOT EXISTS (SELECT *
                                  FROM tblIQEE_ImpotsSpeciaux IS2
                                       JOIN tblIQEE_Fichiers F2 ON F2.iID_Fichier_IQEE = IS2.iID_Fichier_IQEE
                                                               AND F2.dtDate_Creation > F1.dtDate_Creation
                                  WHERE IS2.iID_Convention = IS1.iID_Convention
                                    AND IS2.iID_Operation = IS1.iID_Operation
                                    AND IS2.siAnnee_Fiscale = IS1.siAnnee_Fiscale)

                -- Mettre à jour les erreurs sur les impôts spéciaux basés sur l'identifiant du changement de
                -- statut de convention
                UPDATE tblIQEE_Erreurs
                SET tiID_Statuts_Erreur = @tiID_Statuts_Erreur
                FROM tblIQEE_Erreurs E
                     JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = E.tiID_Type_Enregistrement
                                                        AND TE.cCode_Type_Enregistrement = '06'
                     JOIN tblIQEE_StatutsErreur SE ON SE.tiID_Statuts_Erreur = E.tiID_Statuts_Erreur
                                                  AND SE.vcCode_Statut = 'TER'
                     JOIN tblIQEE_ImpotsSpeciaux IS1 ON IS1.iID_Impot_Special = E.iID_Enregistrement
                     JOIN tblIQEE_SousTypeEnregistrement ST ON ST.iID_Sous_Type = IS1.iID_Sous_Type
                                                           AND ST.cCode_Sous_Type = '91'
                     JOIN tblIQEE_Fichiers F1 ON F1.iID_Fichier_IQEE = IS1.iID_Fichier_IQEE
                WHERE NOT EXISTS (SELECT *
                                  FROM tblIQEE_ImpotsSpeciaux IS2
                                       JOIN tblIQEE_Fichiers F2 ON F2.iID_Fichier_IQEE = IS2.iID_Fichier_IQEE
                                                               AND F2.dtDate_Creation > F1.dtDate_Creation
                                  WHERE IS2.iID_Convention = IS1.iID_Convention
                                    AND IS2.iID_Statut_Convention = IS1.iID_Statut_Convention
                                    AND IS2.siAnnee_Fiscale = IS1.siAnnee_Fiscale)

                -- Mettre à jour les erreurs sur les impôts spéciaux basés sur l'année fiscale
                UPDATE tblIQEE_Erreurs
                SET tiID_Statuts_Erreur = @tiID_Statuts_Erreur
                FROM tblIQEE_Erreurs E
                     JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = E.tiID_Type_Enregistrement
                                                        AND TE.cCode_Type_Enregistrement = '06'
                     JOIN tblIQEE_StatutsErreur SE ON SE.tiID_Statuts_Erreur = E.tiID_Statuts_Erreur
                                                  AND SE.vcCode_Statut = 'TER'
                     JOIN tblIQEE_ImpotsSpeciaux IS1 ON IS1.iID_Impot_Special = E.iID_Enregistrement
                     JOIN tblIQEE_SousTypeEnregistrement ST ON ST.iID_Sous_Type = IS1.iID_Sous_Type
                                                           AND ST.cCode_Sous_Type = '22'
                     JOIN tblIQEE_Fichiers F1 ON F1.iID_Fichier_IQEE = IS1.iID_Fichier_IQEE
                WHERE NOT EXISTS (SELECT *
                                  FROM tblIQEE_ImpotsSpeciaux IS2
                                       JOIN tblIQEE_Fichiers F2 ON F2.iID_Fichier_IQEE = IS2.iID_Fichier_IQEE
                                                               AND F2.dtDate_Creation > F1.dtDate_Creation
                                  WHERE IS2.iID_Convention = IS1.iID_Convention
                                    AND IS2.siAnnee_Fiscale = IS1.siAnnee_Fiscale)
            END

        ----------------------------------------------------------------------------------------------------------
        -- Mettre à jour le statut des fichiers de transactions si le fichier supprimer est un fichier de réponses
        ----------------------------------------------------------------------------------------------------------
-- TODO: Section à faire

        -----------------------------------------------------------------------------------
        -- Mettre à jour le statut des transactions passé selon les transactions supprimées
        -----------------------------------------------------------------------------------
-- TODO: Section à faire


        -- Inverser la création d'un fichier de transactions
        IF @vcCode_Type_Fichier = 'DEM'
            BEGIN
-- TODO: Supprimer les demandes d'annulations reliés aux transactions du fichier

                DELETE tblIQEE_Rejets
                WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE

                DELETE tblIQEE_TransactionsDemande
                FROM tblIQEE_TransactionsDemande TD
                     JOIN tblIQEE_Demandes D ON D.iID_Demande_IQEE = TD.iID_Demande_IQEE
                                            AND D.iID_Fichier_IQEE = @iID_Fichier_IQEE

                DELETE tblIQEE_Demandes
                WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE

                DELETE tblIQEE_RemplacementsBeneficiaire
                WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE

                DELETE dbo.tblIQEE_ReponsesTransfert
                WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE

                DELETE tblIQEE_Transferts
                WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE

                DELETE tblIQEE_PaiementsBeneficiaires
                WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE

                DECLARE @TB_ConvOper TABLE (iID int, iID_CBQ int, iID_MMQ int)
                DECLARE @TB_Oper TABLE (iID int)

                DELETE tblIQEE_ImpotsSpeciaux
                OUTPUT Deleted.iID_Impot_Special, Deleted.iID_Paiement_Impot_CBQ, Deleted.iID_Paiement_Impot_MMQ
                  INTO @TB_ConvOper  
                 WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE

                IF EXISTS(SELECT * FROM @TB_ConvOper)
                    DELETE FROM CO
                    OUTPUT Deleted.OperID
                      INTO #TB_Oper_ToDeleted  
                      FROM dbo.Un_ConventionOper CO
                           JOIN @TB_ConvOper TB ON TB.iID_CBQ = CO.ConventionOperID OR TB.iID_MMQ = CO.ConventionOperID
            END

        IF OBJECT_ID('tempDB..#TB_Oper_ToDeleted') IS NOT NULL
        BEGIN
            INSERT INTO #DisableTrigger (vcTriggerName) VALUES ('TUn_Oper')

            DELETE FROM O
                FROM dbo.Un_Oper O JOIN #TB_Oper_ToDeleted TB ON TB.OperID = O.OperID
             WHERE NOT EXISTS(SELECT * FROM dbo.Un_ConventionOper CO WHERE CO.OperID = O.OperID)
        END 

       -- Supprimer le fichier
        IF @bConserveFichier = 0
           DELETE tblIQEE_Fichiers
            WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE

       COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        SELECT
            ERROR_NUMBER() AS ErrorNumber
            ,ERROR_SEVERITY() AS ErrorSeverity
            ,ERROR_STATE() AS ErrorState
            ,ERROR_PROCEDURE() AS ErrorProcedure
            ,ERROR_LINE() AS ErrorLine
            ,ERROR_MESSAGE() AS ErrorMessage;        -- Retourner -2 en cas d'erreur de traitement

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION
        RETURN -3
    END CATCH

    -- Retourner 0 en cas de réussite du traitement
    RETURN 0
END
