/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service :   psIQEE_AnnulerTransactionsAnnulation
Nom du service  :   Annuler les transactions d'annulation
But             :   Annuler des demandes d’annulations qui ne peuvent pas ou ne doivent pas s’actualiser
Facette         :   IQÉÉ

Paramètres d’entrée :
    Paramètre                   Description
    ------------------------    -----------------------------------------------------------------
    iID_Session                 Identifiant de session identifiant de façon unique la création des fichiers de transactions
    dtDate_Creation_Fichiers    Date et heure de la création des fichiers identifiant de façon unique avec identifiant de session, 
                                la création des fichiers de transactions.
                                                    
Exemple d’appel :   Cette procédure doit être appelée uniquement par "psIQEE_CreerFichiers".

Paramètres de sortie:   S/O

Historique des modifications:
    Date        Programmeur                 Description                                
    ----------  ------------------------    --------------------------------------------------------
    2009-11-11  Éric Deshaies               Création du service                            
    2018-02-08  Steeve Picard               Déplacement de «siAnnee_Fiscale» de la table «tblIQEE_Fichiers» vers les tables d'évèments
****************************************************************************************************/
CREATE PROCEDURE dbo.psIQEE_AnnulerTransactionsAnnulation 
(
    @iID_Session INT,
    @dtDate_Creation_Fichiers DATETIME
)
AS
BEGIN
    DECLARE @tiID_Type_Enregistrement TINYINT,
            @iID_Raison_Annulation_Annulation INT,
            @iID_Convention INT,
            @iID_Statut_Annulation INT


    ------------------------------------------------------------------------------------------
    -- Traiter les transactions de reprise qui sont identique à la transaction originale (IDE)
    ------------------------------------------------------------------------------------------

    -- Déterminer l'identifiant du statut d'annulation "Demande d'annulation annulée"
    SELECT @iID_Statut_Annulation = SA.iID_Statut_Annulation
    FROM tblIQEE_StatutsAnnulation SA
    WHERE SA.vcCode_Statut = 'DAN'

    -- Déterminer la raison d'annulation d'une demande d'annulation
    SELECT @iID_Raison_Annulation_Annulation = RAA.iID_Raison_Annulation_Annulation
    FROM tblIQEE_RaisonsAnnulationAnnulation RAA
    WHERE RAA.vcCode_Raison = 'IDE'

-- TODO: Adapter toute cette section pour les autres types d'enregistrement
    -- Mettre à jour les demandes d'annulation
    UPDATE tblIQEE_Annulations
    SET iID_Raison_Annulation_Annulation = @iID_Raison_Annulation_Annulation,
        iID_Statut_Annulation = @iID_Statut_Annulation
    -- Rechercher les demandes d'annulation
    FROM tblIQEE_Annulations A
         -- Annulation sur les demandes d'IQÉÉ
         JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
                                            AND TE.cCode_Type_Enregistrement = '02'
         -- Rechercher la transaction originale
         JOIN tblIQEE_Demandes D ON D.iID_Demande_IQEE = A.iID_Enregistrement_Demande_Annulation
         -- Rechercher le fichier de la transaction originale
         JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
    -- Demande d'annulations des fichiers en cours de création
    WHERE A.iID_Session = @iID_Session
      AND A.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers
      -- Uniquement les demandes d'annulation qui n'ont pas encore été rejetés
      AND A.iID_Raison_Annulation_Annulation IS NULL
      -- Il y a des rejets de type transactions identiques qui empêche la reprise de la transaction
      AND EXISTS(SELECT *
                 -- Prendre les rejets de la convention de la transaction originale...
                 FROM tblIQEE_Rejets R
                      -- Dans les fichiers en cours de création et pour la même année fiscale...
                      JOIN #tblIQEE_AnneesFiscales AF ON AF.iID_Fichier_IQEE = R.iID_Fichier_IQEE
                                                    AND AF.siAnnee_Fiscale = R.siAnnee_Fiscale
                      -- Qui sont des erreurs type transactions identiques
                      JOIN tblIQEE_Validations V ON V.iID_Validation = R.iID_Validation
                                                AND V.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
                                                AND V.cType = 'E'
                                                AND V.iCode_Validation = 88
                 WHERE R.iID_Convention = D.iID_Convention)    
      -- Il n'y a pas d'autres rejets que le type transactions identiques qui empêche la reprise de la transaction
      AND NOT EXISTS(SELECT *
                     -- Prendre les rejets de la convention de la transaction originale...
                     FROM tblIQEE_Rejets R
                          -- Dans les fichiers en cours de création et pour la même année fiscale...
                          JOIN #tblIQEE_AnneesFiscales AF ON AF.iID_Fichier_IQEE = R.iID_Fichier_IQEE
                                                        AND AF.siAnnee_Fiscale = R.siAnnee_Fiscale
                          -- Qui sont des erreurs autre que de type transactions identiques
                          JOIN tblIQEE_Validations V ON V.iID_Validation = R.iID_Validation
                                                    AND V.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
                                                    AND V.cType = 'E'
                                                    AND V.iCode_Validation <> 88
                     WHERE R.iID_Convention = D.iID_Convention)    

--    DECLARE curConventions CURSOR LOCAL FAST_FORWARD FOR
--        SELECT DISTINCT D.iID_Convention
--        -- Toutes les demandes des fichiers en cours de création
--        FROM tblIQEE_Annulations A
--             -- Annulation sur les demandes d'IQÉÉ
--             JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
--                                                AND TE.cCode_Type_Enregistrement = '02'
--             -- La raison d'annulation permet d'annuler les transactions identiques
--             JOIN tblIQEE_RaisonsAnnulation RA ON RA.iID_Raison_Annulation = A.iID_Raison_Annulation
--                                              AND RA.bAnnuler_Annulation_Transactions_Identiques = 1
--             -- Rechercher la transaction originale
--             JOIN tblIQEE_Demandes D ON D.iID_Demande_IQEE = A.iID_Enregistrement_Demande_Annulation
--        -- Demande d'annulations des fichiers en cours de création
--        WHERE A.iID_Session = @iID_Session
--          AND A.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers
--          -- Uniquement les demandes d'annulation qui n'ont pas encore été rejetés
--          AND A.iID_Raison_Annulation_Annulation IS NULL
--          -- Ne doit pas y avoir une autre demande d'annulation qui ne veux pas effacer les transactions identiques
--          AND NOT EXISTS(SELECT *
--                         -- Rechercher les demandes d'annulation
--                         FROM tblIQEE_Annulations A2
--                              -- Qui ne veux pas effacer les transactions identiques
--                              JOIN tblIQEE_RaisonsAnnulation RA ON RA.iID_Raison_Annulation = A2.iID_Raison_Annulation
--                                                               AND RA.bAnnuler_Annulation_Transactions_Identiques = 0
--                              -- Et qui ne sont associé à la même convention
--                              JOIN tblIQEE_Demandes D2 ON D2.iID_Demande_IQEE = A2.iID_Enregistrement_Demande_Annulation
--                                                      AND D2.iID_Convention = D.iID_Convention
--                         -- Demande d'annulations des fichiers en cours de création
--                         WHERE A2.iID_Session = @iID_Session
--                           AND A2.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers)
--
--    -- Boucler les conventions trouvées
--    OPEN curConventions
--    FETCH NEXT FROM curConventions INTO @iID_Convention
--    WHILE @@FETCH_STATUS = 0
--        BEGIN
---- TODO: Adapter pour les autres types d'enregistrement
--            -- Déterminer si toutes les transactions de reprises d'une convention sont identiques.  Si elles sont toutes identiques,
--            -- elles sont toutes suprimées.  Sinon, elles sont envoyées telles quelles.
--            IF NOT EXISTS(SELECT *
--                          -- Rechercher les annulations
--                          FROM tblIQEE_Annulations A
--                               -- Annulation sur les demandes d'IQÉÉ
--                               JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
--                                                                  AND TE.cCode_Type_Enregistrement = '02'
--                               -- Rechercher les transactions originales de la convention
--                               JOIN tblIQEE_Demandes D ON D.iID_Demande_IQEE = A.iID_Enregistrement_Demande_Annulation
--                                                      AND D.iID_Convention = @iID_Convention
--                               JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
--                               --  Rechercher les nouvelles transactions.  Elle doivent être dans les fichiers en cours de création.
--                               JOIN #tblIQEE_AnneesFiscales AF ON AF.siAnnee_Fiscale = D.siAnnee_Fiscale
---- TODO: A mettre dans une fonction?
--                               JOIN tblIQEE_Demandes D2 ON D2.iID_Convention = D.iID_Convention
--                                                         AND D2.iID_Fichier_IQEE = AF.iID_Fichier_IQEE
--                                                         AND D2.tiCode_Version IN (0,2)
--                                                         -- La nouvelle transaction doit être différente de la transaction d'origine
--                                                         AND (D2.vcNo_Convention <> D.vcNo_Convention
--                                                             OR D2.dtDate_Debut_Convention <> D.dtDate_Debut_Convention
--                                                             OR ISNULL(D2.tiNB_Annee_Quebec,0) <> ISNULL(D.tiNB_Annee_Quebec,0)
--                                                             OR D2.mCotisations <> D.mCotisations
--                                                             OR D2.mTransfert_IN <> D.mTransfert_IN
--                                                             OR D2.mTotal_Cotisations_Subventionnables <> D.mTotal_Cotisations_Subventionnables
--                                                             OR D2.mTotal_Cotisations <> D.mTotal_Cotisations
--                                                             OR D2.iID_Beneficiaire_31Decembre <> D.iID_Beneficiaire_31Decembre
--                                                             OR D2.vcNAS_Beneficiaire <> D.vcNAS_Beneficiaire
--                                                             OR D2.vcNom_Beneficiaire <> D.vcNom_Beneficiaire
--                                                             OR D2.vcPrenom_Beneficiaire <> D.vcPrenom_Beneficiaire
--                                                             OR D2.dtDate_Naissance_Beneficiaire <> D.dtDate_Naissance_Beneficiaire
--                                                             OR D2.tiSexe_Beneficiaire <> D.tiSexe_Beneficiaire
--                                                             OR D2.iID_Adresse_31Decembre_Beneficiaire <> D.iID_Adresse_31Decembre_Beneficiaire
--                                                             OR ISNULL(D2.vcAppartement_Beneficiaire,'') <> ISNULL(D.vcAppartement_Beneficiaire,'')
--                                                             OR D2.vcNo_Civique_Beneficiaire <> D.vcNo_Civique_Beneficiaire
--                                                             OR D2.vcRue_Beneficiaire <> D.vcRue_Beneficiaire
--                                                             OR ISNULL(D2.vcLigneAdresse2_Beneficiaire,'') <> ISNULL(D.vcLigneAdresse2_Beneficiaire,'')
--                                                             OR ISNULL(D2.vcLigneAdresse3_Beneficiaire,'') <> ISNULL(D.vcLigneAdresse3_Beneficiaire,'')
--                                                             OR D2.vcVille_Beneficiaire <> D.vcVille_Beneficiaire
--                                                             OR D2.vcProvince_Beneficiaire <> D.vcProvince_Beneficiaire
--                                                             OR D2.vcPays_Beneficiaire <> D.vcPays_Beneficiaire
--                                                             OR D2.vcCodePostal_Beneficiaire <> D.vcCodePostal_Beneficiaire
--                                                             OR D2.bResidence_Quebec <> D.bResidence_Quebec
--                                                             OR D2.iID_Souscripteur <> D.iID_Souscripteur
--                                                             OR D2.tiType_Souscripteur <> D.tiType_Souscripteur
--                                                             OR ISNULL(D2.vcNAS_Souscripteur,'') <> ISNULL(D.vcNAS_Souscripteur,'')
--                                                             OR ISNULL(D2.vcNEQ_Souscripteur,'') <> ISNULL(D.vcNEQ_Souscripteur,'')
--                                                             OR D2.vcNom_Souscripteur <> D.vcNom_Souscripteur
--                                                             OR ISNULL(D2.vcPrenom_Souscripteur,'') <> ISNULL(D.vcPrenom_Souscripteur,'')
--                                                             OR D2.tiID_Lien_Souscripteur <> D.tiID_Lien_Souscripteur
--                                                             OR D2.iID_Adresse_Souscripteur <> D.iID_Adresse_Souscripteur
--                                                             OR ISNULL(D2.vcAppartement_Souscripteur,'') <> ISNULL(D.vcAppartement_Souscripteur,'')
--                                                             OR D2.vcNo_Civique_Souscripteur <> D.vcNo_Civique_Souscripteur
--                                                             OR D2.vcRue_Souscripteur <> D.vcRue_Souscripteur
--                                                             OR ISNULL(D2.vcLigneAdresse2_Souscripteur,'') <> ISNULL(D.vcLigneAdresse2_Souscripteur,'')
--                                                             OR ISNULL(D2.vcLigneAdresse3_Souscripteur,'') <> ISNULL(D.vcLigneAdresse3_Souscripteur,'')
--                                                             OR D2.vcVille_Souscripteur <> D.vcVille_Souscripteur
--                                                             OR D2.vcCodePostal_Souscripteur <> D.vcCodePostal_Souscripteur
--                                                             OR ISNULL(D2.vcProvince_Souscripteur,'') <> ISNULL(D.vcProvince_Souscripteur,'')
--                                                             OR D2.vcPays_Souscripteur <> D.vcPays_Souscripteur
--                                                             OR ISNULL(D2.vcTelephone_Souscripteur,'') <> ISNULL(D.vcTelephone_Souscripteur,'')
--                                                             OR ISNULL(D2.iID_Cosouscripteur,0) <> ISNULL(D.iID_Cosouscripteur,0)
--                                                             OR ISNULL(D2.vcNAS_Cosouscripteur,'') <> ISNULL(D.vcNAS_Cosouscripteur,'')
--                                                             OR ISNULL(D2.vcNom_Cosouscripteur,'') <> ISNULL(D.vcNom_Cosouscripteur,'')
--                                                             OR ISNULL(D2.vcPrenom_Cosouscripteur,'') <> ISNULL(D.vcPrenom_Cosouscripteur,'')
--                                                             OR ISNULL(D2.tiID_Lien_Cosouscripteur,0) <> ISNULL(D.tiID_Lien_Cosouscripteur,0)
--                                                             OR ISNULL(D2.vcTelephone_Cosouscripteur,'') <> ISNULL(D.vcTelephone_Cosouscripteur,'')
--                                                             OR ISNULL(D2.tiType_Responsable,0) <> ISNULL(D.tiType_Responsable,0)
--                                                             OR ISNULL(D2.vcNAS_Responsable,'') <> ISNULL(D.vcNAS_Responsable,'')
--                                                             OR ISNULL(D2.vcNEQ_Responsable,'') <> ISNULL(D.vcNEQ_Responsable,'')
--                                                             OR ISNULL(D2.vcNom_Responsable,'') <> ISNULL(D.vcNom_Responsable,'')
--                                                             OR ISNULL(D2.vcPrenom_Responsable,'') <> ISNULL(D.vcPrenom_Responsable,'')
--                                                             OR ISNULL(D2.tiID_Lien_Responsable,0) <> ISNULL(D.tiID_Lien_Responsable,0)
--                                                             OR ISNULL(D2.vcAppartement_Responsable,'') <> ISNULL(D.vcAppartement_Responsable,'')
--                                                             OR ISNULL(D2.vcNo_Civique_Responsable,'') <> ISNULL(D.vcNo_Civique_Responsable,'')
--                                                             OR ISNULL(D2.vcRue_Responsable,'') <> ISNULL(D.vcRue_Responsable,'')
--                                                             OR ISNULL(D2.vcLigneAdresse2_Responsable,'') <> ISNULL(D.vcLigneAdresse2_Responsable,'')
--                                                             OR ISNULL(D2.vcLigneAdresse3_Responsable,'') <> ISNULL(D.vcLigneAdresse3_Responsable,'')
--                                                             OR ISNULL(D2.vcVille_Responsable,'') <> ISNULL(D.vcVille_Responsable,'')
--                                                             OR ISNULL(D2.vcCodePostal_Responsable,'') <> ISNULL(D.vcCodePostal_Responsable,'')
--                                                             OR ISNULL(D2.vcProvince_Responsable,'') <> ISNULL(D.vcProvince_Responsable,'')
--                                                             OR ISNULL(D2.vcPays_Responsable,'') <> ISNULL(D.vcPays_Responsable,'')
--                                                             OR ISNULL(D2.vcTelephone_Responsable,'') <> ISNULL(D.vcTelephone_Responsable,'')
--                                                             OR D2.bInd_Cession_IQEE <> D.bInd_Cession_IQEE)
--                          -- Demande d'annulations des fichiers en cours de création
--                          WHERE A.iID_Session = @iID_Session
--                            AND A.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers)
--                BEGIN
--                    -- Annuler les demandes d'annulations où les reprises sont toutes identiques pour la convention
--                    UPDATE tblIQEE_Annulations
--                    SET iID_Raison_Annulation_Annulation = @iID_Raison_Annulation_Annulation
--                    FROM tblIQEE_Annulations A
--                           -- Rechercher les transactions originales de la convention
--                           JOIN tblIQEE_Demandes D ON D.iID_Demande_IQEE = A.iID_Enregistrement_Demande_Annulation
--                                                  AND D.iID_Convention = @iID_Convention
--                      -- Demande d'annulations des fichiers en cours de création
--                      WHERE A.iID_Session = @iID_Session
--                        AND A.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers
--                        -- Uniquement les demandes d'annulation qui n'ont pas encore été rejetés
--                        AND A.iID_Raison_Annulation_Annulation IS NULL
--                END
--
--            FETCH NEXT FROM curConventions INTO @iID_Convention
--        END
--    CLOSE curConventions
--    DEALLOCATE curConventions
--
--    -- Supprimer les transactions de reprises identiques de la convention
--    DELETE FROM tblIQEE_TransactionsDemande
--    -- Rechercher les demandes d'annulation
--    FROM tblIQEE_Annulations A
--         -- Annulation sur les demandes d'IQÉÉ
--         JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
--                                            AND TE.cCode_Type_Enregistrement = '02'
--         -- Rechercher la demande de reprise puisqu'elle est identique
--         JOIN tblIQEE_Demandes D ON D.iID_Demande_IQEE =
--                  -- Rechercher la transaction de reprise à partir de l'originale
--                 (SELECT D3.iID_Demande_IQEE
--                  FROM tblIQEE_Demandes D2 
--                       JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D2.iID_Fichier_IQEE
--                       JOIN #tblIQEE_AnneesFiscales AF ON AF.siAnnee_Fiscale = D2.siAnnee_Fiscale
--                       -- Trouver la transaction de reprise du fichier en cours de création
--                       JOIN tblIQEE_Demandes D3 ON D3.iID_Convention = D2.iID_Convention
--                                               AND D3.iID_Fichier_IQEE = AF.iID_Fichier_IQEE
--                                               AND D3.tiCode_Version IN (0,2) -- Note: À ce point-ci du traitement, il n'y a pas
--                                                                              -- de transaction de reprise à 0 ni de transaction
--                                                                              -- d'annulation
--                  -- Trouver la transaction originale
--                  WHERE D2.iID_Demande_IQEE = A.iID_Enregistrement_Demande_Annulation)
--        -- Supprimer les transactions de la demande qui sera supprimée
--        JOIN tblIQEE_TransactionsDemande TD ON TD.iID_Demande_IQEE = D.iID_Demande_IQEE
--    -- Demande d'annulations des fichiers en cours de création
--    WHERE A.iID_Session = @iID_Session
--      AND A.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers
--      -- Qui ont été identifié dans la requête précédente comme identique
--      AND A.iID_Raison_Annulation_Annulation = @iID_Raison_Annulation_Annulation
--
--    DELETE FROM tblIQEE_Demandes
--    -- Rechercher les demandes d'annulation
--    FROM tblIQEE_Annulations A
--         -- Annulation sur les demandes d'IQÉÉ
--         JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
--                                            AND TE.cCode_Type_Enregistrement = '02'
--         -- Supprimer la demande de reprise puisqu'elle est identique
--         JOIN tblIQEE_Demandes D ON D.iID_Demande_IQEE =
--                  -- Rechercher la transaction de reprise à partir de l'originale
--                 (SELECT D3.iID_Demande_IQEE
--                  FROM tblIQEE_Demandes D2 
--                       JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D2.iID_Fichier_IQEE
--                       JOIN #tblIQEE_AnneesFiscales AF ON AF.siAnnee_Fiscale = D2.siAnnee_Fiscale
--                       -- Trouver la transaction de reprise du fichier en cours de création
--                       JOIN tblIQEE_Demandes D3 ON D3.iID_Convention = D2.iID_Convention
--                                               AND D3.iID_Fichier_IQEE = AF.iID_Fichier_IQEE
--                                               AND D3.tiCode_Version IN (0,2) -- Note: À ce point-ci du traitement, il n'y a pas
--                                                                              -- de transaction de reprise à 0 ni de transaction
--                                                                              -- d'annulation
--                  -- Trouver la transaction originale
--                  WHERE D2.iID_Demande_IQEE = A.iID_Enregistrement_Demande_Annulation)
--    -- Demande d'annulations des fichiers en cours de création
--    WHERE A.iID_Session = @iID_Session
--      AND A.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers
--      -- Qui ont été identifié dans la requête précédente comme identique
--      AND A.iID_Raison_Annulation_Annulation = @iID_Raison_Annulation_Annulation


    -------------------------------------------------------------------------
    -- Traiter les transactions de reprise rejetées par les validations (REJ)
    -------------------------------------------------------------------------

    -- Déterminer l'identifiant du statut d'annulation "Demande d’annulation annulée à la création des transactions - à reprendre"
    SELECT @iID_Statut_Annulation = SA.iID_Statut_Annulation
    FROM tblIQEE_StatutsAnnulation SA
    WHERE SA.vcCode_Statut = 'DAR'

    -- Déterminer la raison d'annulation d'une demande d'annulation
    SELECT @iID_Raison_Annulation_Annulation = RAA.iID_Raison_Annulation_Annulation
    FROM tblIQEE_RaisonsAnnulationAnnulation RAA
    WHERE RAA.vcCode_Raison = 'REJ'

-- TODO: Adapter pour les autres types d'enregistrement
    -- Mettre à jour les demandes d'annulation
    UPDATE tblIQEE_Annulations
    SET iID_Raison_Annulation_Annulation = @iID_Raison_Annulation_Annulation,
        iID_Statut_Annulation = @iID_Statut_Annulation
    -- Rechercher les demandes d'annulation
    FROM tblIQEE_Annulations A
         -- Annulation sur les demandes d'IQÉÉ
         JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
                                            AND TE.cCode_Type_Enregistrement = '02'
         -- Rechercher la transaction originale
         JOIN tblIQEE_Demandes D ON D.iID_Demande_IQEE = A.iID_Enregistrement_Demande_Annulation
         -- Rechercher le fichier de la transaction originale
         JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
    -- Demande d'annulations des fichiers en cours de création
    WHERE A.iID_Session = @iID_Session
      AND A.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers
      -- Uniquement les demandes d'annulation qui n'ont pas encore été rejetés
      AND A.iID_Raison_Annulation_Annulation IS NULL
      -- Il y a des rejets de type "Erreur" qui empêche la reprise de la transaction
      AND EXISTS(SELECT *
                 -- Prendre les rejets de la convention de la transaction originale...
                 FROM tblIQEE_Rejets R
                      -- Dans les fichiers en cours de création et pour la même année fiscale...
                      JOIN #tblIQEE_AnneesFiscales AF ON AF.iID_Fichier_IQEE = R.iID_Fichier_IQEE
                                                    AND AF.siAnnee_Fiscale = R.siAnnee_Fiscale
                      -- Qui sont des erreurs...
                      JOIN tblIQEE_Validations V ON V.iID_Validation = R.iID_Validation
                                                AND V.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
                                                AND V.cType = 'E'
                 WHERE R.iID_Convention = D.iID_Convention)


    -------------------------------------------------------------------------------------------------------------
    -- Traiter les transactions de reprise absentes alors qu'elle est obligatoire (erreur de programmation) (REP)
    -- Note: S'applique uniquement aux transactions de demandes (02)
    -------------------------------------------------------------------------------------------------------------

    -- Déterminer la raison d'annulation d'une demande d'annulation
    SELECT @iID_Raison_Annulation_Annulation = RAA.iID_Raison_Annulation_Annulation
    FROM tblIQEE_RaisonsAnnulationAnnulation RAA
    WHERE RAA.vcCode_Raison = 'REP'

    -- Mettre à jour les demandes d'annulation
    UPDATE tblIQEE_Annulations
    SET iID_Raison_Annulation_Annulation = @iID_Raison_Annulation_Annulation,
        iID_Statut_Annulation = @iID_Statut_Annulation
    -- Rechercher les demandes d'annulation
    FROM tblIQEE_Annulations A
         -- Annulation sur les demandes d'IQÉÉ
         JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
                                            AND TE.cCode_Type_Enregistrement = '02'
         -- La raison d'annulation requière une transaction de reprise pour confirmer l'annulation
         JOIN tblIQEE_RaisonsAnnulation RA ON RA.iID_Raison_Annulation = A.iID_Raison_Annulation
                                          AND RA.bObligation_Reprendre_Transaction = 1
         -- Rechercher la transaction originale
         JOIN tblIQEE_Demandes D ON D.iID_Demande_IQEE = A.iID_Enregistrement_Demande_Annulation
         JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
         JOIN #tblIQEE_AnneesFiscales AF ON AF.siAnnee_Fiscale = D.siAnnee_Fiscale
    -- Demande d'annulations des fichiers en cours de création
    WHERE A.iID_Session = @iID_Session
      AND A.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers
      -- Uniquement les demandes d'annulation qui n'ont pas encore été rejetés
      AND A.iID_Raison_Annulation_Annulation IS NULL
      -- La nouvelle transaction n'existe pas
      AND NOT EXISTS(SELECT *
                     FROM tblIQEE_Demandes D2
                     WHERE D2.iID_Convention = D.iID_Convention  
                       AND D2.iID_Fichier_IQEE = AF.iID_Fichier_IQEE
                       AND D2.tiCode_Version IN (0,2))
END
