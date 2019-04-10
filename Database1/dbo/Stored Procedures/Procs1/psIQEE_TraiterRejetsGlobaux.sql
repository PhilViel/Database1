/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service        : psIQEE_TraiterRejetsGlobaux
Nom du service        : Traiter les rejets globaux
But                 : Traiter les rejets spéciaux qui sont relatif à l’ensemble des transactions créées (pas spécifique
                      à une seule transaction)
Facette                : IQÉÉ

Paramètres d’entrée    :    Paramètre                    Description
                        --------------------------    -----------------------------------------------------------------
                        iID_Session                    Identifiant de session identifiant de façon unique la création des
                                                    fichiers de transactions
                        dtDate_Creation_Fichiers    Date et heure de la création des fichiers identifiant de façon unique avec
                                                    identifiant de session, la création des    fichiers de transactions.
                        bFichiers_Test_Comme_        Indicateur si les fichiers test doivent être tenue en compte dans
                            Production                la production du fichier.  Normalement ce n’est pas le cas.  Mais
                                                    pour fins d’essais et de simulations il est possible de tenir compte
                                                    des fichiers tests comme des fichiers de production.
                                                    
Exemple d’appel        :    Cette procédure doit être appelée uniquement par "psIQEE_CreerFichiers".

Paramètres de sortie:    Table                        Champ                            Description
                          -------------------------    ---------------------------     ---------------------------------
                        S/O

Historique des modifications:
        Date        Programmeur                Description                                
        ----------    --------------------    -----------------------------------------
        2010-02-16    Éric Deshaies            Création du service                            
        2016-08-15    Steeve Picard           Optimisation des requêtes
        2017-07-10    Steeve Picard            La table « #TB_ListeConvention » n'est plus créée dans « psIQEE_CreerFichiers »
        2018-02-08  Steeve Picard           Déplacement de «siAnnee_Fiscale» de la table «tblIQEE_Fichiers» vers les tables d'évèments
****************************************************************************************************/
CREATE PROCEDURE dbo.psIQEE_TraiterRejetsGlobaux
(
    @iID_Session INT,
    @dtDate_Creation_Fichiers DATETIME,
    @bFichiers_Test_Comme_Production BIT
)
AS
BEGIN
    DECLARE @iID_Validation INT,
            @vcDescription VARCHAR(300),
            @iID_Demande_IQEE INT,
            @vcTMP1 VARCHAR(300),
            @iID_Fichier_IQEE INT,
            @iID_Convention INT,
            @siAnnee_Fiscale SMALLINT,
            @tiID_Type_Enregistrement TINYINT

    -----------------------------------------------------------------------------------------------------
    -- Validation #88: Traiter les transactions de reprise qui sont identique aux transactions originales
    -----------------------------------------------------------------------------------------------------
    SELECT @iID_Validation = iID_Validation,
           @vcDescription = vcDescription_Parametrable
    FROM tblIQEE_Validations
    WHERE iCode_Validation = 88

    DECLARE curConventions CURSOR LOCAL FAST_FORWARD FOR
        SELECT DISTINCT D.iID_Convention
        -- Toutes les demandes des fichiers en cours de création
        FROM tblIQEE_Annulations A
             -- Annulation sur les demandes d'IQÉÉ
             JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
                                                AND TE.cCode_Type_Enregistrement = '02'
             -- La raison d'annulation permet d'annuler les transactions identiques
             JOIN tblIQEE_RaisonsAnnulation RA ON RA.iID_Raison_Annulation = A.iID_Raison_Annulation
                                              AND RA.bAnnuler_Annulation_Transactions_Identiques = 1
             -- Rechercher la transaction originale
             JOIN tblIQEE_Demandes D ON D.iID_Demande_IQEE = A.iID_Enregistrement_Demande_Annulation
        -- Demande d'annulations des fichiers en cours de création
        WHERE A.iID_Session = @iID_Session
          AND A.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers
          -- Ne doit pas y avoir une autre demande d'annulation qui ne veux pas effacer les transactions identiques
          AND NOT EXISTS(SELECT *
                         -- Rechercher les demandes d'annulation
                         FROM tblIQEE_Annulations A2
                              -- Qui ne veux pas effacer les transactions identiques
                              JOIN tblIQEE_RaisonsAnnulation RA ON RA.iID_Raison_Annulation = A2.iID_Raison_Annulation
                                                               AND RA.bAnnuler_Annulation_Transactions_Identiques = 0
                              -- Et qui ne sont associé à la même convention
                              JOIN tblIQEE_Demandes D2 ON D2.iID_Demande_IQEE = A2.iID_Enregistrement_Demande_Annulation
                                                      AND D2.iID_Convention = D.iID_Convention
                         -- Demande d'annulations des fichiers en cours de création
                         WHERE A2.iID_Session = @iID_Session
                           AND A2.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers)

    -- Boucler les conventions trouvées
    OPEN curConventions
    FETCH NEXT FROM curConventions INTO @iID_Convention
    WHILE @@FETCH_STATUS = 0
        BEGIN
-- TODO: Adapter pour les autres types d'enregistrement
            -- Déterminer si toutes les transactions de reprises d'une convention sont identiques.  Si elles sont toutes identiques,
            -- elles sont toutes rejetées.  Sinon, elles sont envoyées telles quelles.
            IF NOT EXISTS(SELECT *
                          -- Rechercher les annulations
                          FROM tblIQEE_Annulations A
                               -- Annulation sur les demandes d'IQÉÉ
                               JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
                                                                  AND TE.cCode_Type_Enregistrement = '02'
                               -- Rechercher les transactions originales de la convention
                               JOIN tblIQEE_Demandes D ON D.iID_Demande_IQEE = A.iID_Enregistrement_Demande_Annulation
                                                      AND D.iID_Convention = @iID_Convention
                               JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
                               --  Rechercher les nouvelles transactions.  Elle doivent être dans les fichiers en cours de création.
                               JOIN #tblIQEE_AnneesFiscales AF ON AF.siAnnee_Fiscale = D.siAnnee_Fiscale
-- TODO: A mettre dans une fonction?
                               JOIN tblIQEE_Demandes D2 ON D2.iID_Convention = D.iID_Convention
                                                         AND D2.iID_Fichier_IQEE = AF.iID_Fichier_IQEE
                                                         AND D2.tiCode_Version IN (0,2)
                                                         -- La nouvelle transaction doit être différente de la transaction d'origine
                                                         AND (D2.vcNo_Convention <> D.vcNo_Convention
                                                             OR D2.dtDate_Debut_Convention <> D.dtDate_Debut_Convention
                                                             OR ISNULL(D2.tiNB_Annee_Quebec,0) <> ISNULL(D.tiNB_Annee_Quebec,0)
                                                             OR D2.mCotisations <> D.mCotisations
                                                             OR D2.mTransfert_IN <> D.mTransfert_IN
                                                             OR D2.mTotal_Cotisations_Subventionnables <> D.mTotal_Cotisations_Subventionnables
                                                             OR D2.mTotal_Cotisations <> D.mTotal_Cotisations
                                                             OR D2.iID_Beneficiaire_31Decembre <> D.iID_Beneficiaire_31Decembre
                                                             OR D2.vcNAS_Beneficiaire <> D.vcNAS_Beneficiaire
                                                             OR D2.vcNom_Beneficiaire <> D.vcNom_Beneficiaire
                                                             OR D2.vcPrenom_Beneficiaire <> D.vcPrenom_Beneficiaire
                                                             OR D2.dtDate_Naissance_Beneficiaire <> D.dtDate_Naissance_Beneficiaire
                                                             OR D2.tiSexe_Beneficiaire <> D.tiSexe_Beneficiaire
                                                             OR D2.iID_Adresse_31Decembre_Beneficiaire <> D.iID_Adresse_31Decembre_Beneficiaire
                                                             OR ISNULL(D2.vcAppartement_Beneficiaire,'') <> ISNULL(D.vcAppartement_Beneficiaire,'')
                                                             OR D2.vcNo_Civique_Beneficiaire <> D.vcNo_Civique_Beneficiaire
                                                             OR D2.vcRue_Beneficiaire <> D.vcRue_Beneficiaire
                                                             OR ISNULL(D2.vcLigneAdresse2_Beneficiaire,'') <> ISNULL(D.vcLigneAdresse2_Beneficiaire,'')
                                                             OR ISNULL(D2.vcLigneAdresse3_Beneficiaire,'') <> ISNULL(D.vcLigneAdresse3_Beneficiaire,'')
                                                             OR D2.vcVille_Beneficiaire <> D.vcVille_Beneficiaire
                                                             OR D2.vcProvince_Beneficiaire <> D.vcProvince_Beneficiaire
                                                             OR D2.vcPays_Beneficiaire <> D.vcPays_Beneficiaire
                                                             OR D2.vcCodePostal_Beneficiaire <> D.vcCodePostal_Beneficiaire
                                                             OR D2.bResidence_Quebec <> D.bResidence_Quebec
                                                             OR D2.iID_Souscripteur <> D.iID_Souscripteur
                                                             OR D2.tiType_Souscripteur <> D.tiType_Souscripteur
                                                             OR ISNULL(D2.vcNAS_Souscripteur,'') <> ISNULL(D.vcNAS_Souscripteur,'')
                                                             OR ISNULL(D2.vcNEQ_Souscripteur,'') <> ISNULL(D.vcNEQ_Souscripteur,'')
                                                             OR D2.vcNom_Souscripteur <> D.vcNom_Souscripteur
                                                             OR ISNULL(D2.vcPrenom_Souscripteur,'') <> ISNULL(D.vcPrenom_Souscripteur,'')
                                                             OR D2.tiID_Lien_Souscripteur <> D.tiID_Lien_Souscripteur
                                                             OR D2.iID_Adresse_Souscripteur <> D.iID_Adresse_Souscripteur
                                                             OR ISNULL(D2.vcAppartement_Souscripteur,'') <> ISNULL(D.vcAppartement_Souscripteur,'')
                                                             OR D2.vcNo_Civique_Souscripteur <> D.vcNo_Civique_Souscripteur
                                                             OR D2.vcRue_Souscripteur <> D.vcRue_Souscripteur
                                                             OR ISNULL(D2.vcLigneAdresse2_Souscripteur,'') <> ISNULL(D.vcLigneAdresse2_Souscripteur,'')
                                                             OR ISNULL(D2.vcLigneAdresse3_Souscripteur,'') <> ISNULL(D.vcLigneAdresse3_Souscripteur,'')
                                                             OR D2.vcVille_Souscripteur <> D.vcVille_Souscripteur
                                                             OR D2.vcCodePostal_Souscripteur <> D.vcCodePostal_Souscripteur
                                                             OR ISNULL(D2.vcProvince_Souscripteur,'') <> ISNULL(D.vcProvince_Souscripteur,'')
                                                             OR D2.vcPays_Souscripteur <> D.vcPays_Souscripteur
                                                             OR ISNULL(D2.vcTelephone_Souscripteur,'') <> ISNULL(D.vcTelephone_Souscripteur,'')
                                                             OR ISNULL(D2.iID_Cosouscripteur,0) <> ISNULL(D.iID_Cosouscripteur,0)
                                                             OR ISNULL(D2.vcNAS_Cosouscripteur,'') <> ISNULL(D.vcNAS_Cosouscripteur,'')
                                                             OR ISNULL(D2.vcNom_Cosouscripteur,'') <> ISNULL(D.vcNom_Cosouscripteur,'')
                                                             OR ISNULL(D2.vcPrenom_Cosouscripteur,'') <> ISNULL(D.vcPrenom_Cosouscripteur,'')
                                                             OR ISNULL(D2.tiID_Lien_Cosouscripteur,0) <> ISNULL(D.tiID_Lien_Cosouscripteur,0)
                                                             OR ISNULL(D2.vcTelephone_Cosouscripteur,'') <> ISNULL(D.vcTelephone_Cosouscripteur,'')
                                                             OR ISNULL(D2.tiType_Responsable,0) <> ISNULL(D.tiType_Responsable,0)
                                                             OR ISNULL(D2.vcNAS_Responsable,'') <> ISNULL(D.vcNAS_Responsable,'')
                                                             OR ISNULL(D2.vcNEQ_Responsable,'') <> ISNULL(D.vcNEQ_Responsable,'')
                                                             OR ISNULL(D2.vcNom_Responsable,'') <> ISNULL(D.vcNom_Responsable,'')
                                                             OR ISNULL(D2.vcPrenom_Responsable,'') <> ISNULL(D.vcPrenom_Responsable,'')
                                                             OR ISNULL(D2.tiID_Lien_Responsable,0) <> ISNULL(D.tiID_Lien_Responsable,0)
                                                             OR ISNULL(D2.vcAppartement_Responsable,'') <> ISNULL(D.vcAppartement_Responsable,'')
                                                             OR ISNULL(D2.vcNo_Civique_Responsable,'') <> ISNULL(D.vcNo_Civique_Responsable,'')
                                                             OR ISNULL(D2.vcRue_Responsable,'') <> ISNULL(D.vcRue_Responsable,'')
                                                             OR ISNULL(D2.vcLigneAdresse2_Responsable,'') <> ISNULL(D.vcLigneAdresse2_Responsable,'')
                                                             OR ISNULL(D2.vcLigneAdresse3_Responsable,'') <> ISNULL(D.vcLigneAdresse3_Responsable,'')
                                                             OR ISNULL(D2.vcVille_Responsable,'') <> ISNULL(D.vcVille_Responsable,'')
                                                             OR ISNULL(D2.vcCodePostal_Responsable,'') <> ISNULL(D.vcCodePostal_Responsable,'')
                                                             OR ISNULL(D2.vcProvince_Responsable,'') <> ISNULL(D.vcProvince_Responsable,'')
                                                             OR ISNULL(D2.vcPays_Responsable,'') <> ISNULL(D.vcPays_Responsable,'')
                                                             OR ISNULL(D2.vcTelephone_Responsable,'') <> ISNULL(D.vcTelephone_Responsable,'')
                                                             OR D2.bInd_Cession_IQEE <> D.bInd_Cession_IQEE)
                          -- Demande d'annulations des fichiers en cours de création
                          WHERE A.iID_Session = @iID_Session
                            AND A.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers)
                BEGIN
                    -- Trouver les demandes d'IQÉÉ à rejeter
                    DECLARE curValidation88_02 CURSOR LOCAL FAST_FORWARD FOR
                        SELECT D2.iID_Demande_IQEE, AF.iID_Fichier_IQEE
                        FROM tblIQEE_Annulations A
                               -- Annulation sur les demandes d'IQÉÉ
                               JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
                                                                  AND TE.cCode_Type_Enregistrement = '02'
                               -- Rechercher les transactions originales de la convention
                               JOIN tblIQEE_Demandes D ON D.iID_Demande_IQEE = A.iID_Enregistrement_Demande_Annulation
                                                      AND D.iID_Convention = @iID_Convention
                               JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
                               -- Rechercher les nouvelles transactions.  Elle doivent être dans les fichiers en cours de création.
                               JOIN #tblIQEE_AnneesFiscales AF ON AF.siAnnee_Fiscale = D.siAnnee_Fiscale
                               JOIN tblIQEE_Demandes D2 ON D2.iID_Convention = D.iID_Convention
                                                         AND D2.iID_Fichier_IQEE = AF.iID_Fichier_IQEE
                                                         AND D2.tiCode_Version IN (0,2)
                          -- Demande d'annulations des fichiers en cours de création
                          WHERE A.iID_Session = @iID_Session
                            AND A.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers

                    -- Boucler les demandes trouvées
                    OPEN curValidation88_02
                    FETCH NEXT FROM curValidation88_02 INTO @iID_Demande_IQEE, @iID_Fichier_IQEE
                    WHILE @@FETCH_STATUS = 0
                        BEGIN
                            EXECUTE dbo.psIQEE_AjouterRejet @iID_Fichier_IQEE, @iID_Convention,
                                                 @iID_Validation, @vcDescription,NULL,NULL,
                                                 @iID_Convention,NULL,NULL

                            DELETE FROM tblIQEE_TransactionsDemande
                            WHERE iID_Demande_IQEE = @iID_Demande_IQEE

                            DELETE FROM tblIQEE_Demandes
                            WHERE iID_Demande_IQEE = @iID_Demande_IQEE

                            FETCH NEXT FROM curValidation88_02 INTO @iID_Demande_IQEE, @iID_Fichier_IQEE
                        END
                    CLOSE curValidation88_02
                    DEALLOCATE curValidation88_02
                END

            FETCH NEXT FROM curConventions INTO @iID_Convention
        END
    CLOSE curConventions
    DEALLOCATE curConventions


    --------------------------------------------------------------------------------------------------------------
    -- Validation #56: Une demande d''IQÉÉ ne peux pas être présentée parce qu''il y a une transaction subséquente
    --                   d''annulation/reprise en rejet pour la convention.
    --------------------------------------------------------------------------------------------------------------
    SELECT @iID_Validation = iID_Validation,
           @vcDescription = vcDescription_Parametrable
    FROM tblIQEE_Validations
    WHERE iCode_Validation = 56

    -- Déterminer le type d'enregistrement
    SELECT @tiID_Type_Enregistrement = TE.tiID_Type_Enregistrement
    FROM tblIQEE_TypesEnregistrement TE
    WHERE TE.cCode_Type_Enregistrement = '02'

    -- Trouver les demandes d'IQÉÉ à rejeter
    DECLARE curValidation56_02 CURSOR LOCAL FAST_FORWARD FOR
        SELECT D.iID_Demande_IQEE, D.iID_Fichier_IQEE, D.iID_Convention, A.siAnnee_Fiscale
        -- Toutes les demandes des fichiers en cours de création
        FROM #tblIQEE_AnneesFiscales A
             JOIN tblIQEE_Demandes D ON D.iID_Fichier_IQEE = A.iID_Fichier_IQEE
-- TODO: Appliquer la validation 56 aux autres type de transactions
              -- Existe une transaction subséquente d''annulation/reprise en rejet pour la convention
        WHERE EXISTS (SELECT *
                      -- Rechercher les transactions de demande d'IQÉÉ...
                      FROM tblIQEE_Demandes D2
                           JOIN tblIQEE_Fichiers F2 ON F2.iID_Fichier_IQEE = D2.iID_Fichier_IQEE
                                                   -- faisant partie des fichiers admissibles
                                                   AND (@bFichiers_Test_Comme_Production = 1
                                                        OR F2.bFichier_Test = 0)
                                                   AND F2.bInd_Simulation = 0
                                                   -- qui ne font partie de la création en cours
                                                   AND NOT EXISTS (SELECT *
                                                                   FROM #tblIQEE_AnneesFiscales A2
                                                                   WHERE A2.iID_Fichier_IQEE = F2.iID_Fichier_IQEE)
                        -- pour la même convention
                      WHERE D2.iID_Convention = D.iID_Convention
                        -- subséquentes
                        AND D2.siAnnee_Fiscale > A.siAnnee_Fiscale
                        -- transactions actives
                        AND D2.tiCode_Version IN (0,2)
                        AND D2.cStatut_Reponse IN ('A','R')
                        -- qui font l'objet d'une demande d'annulation dans la création en cours
                        AND EXISTS (SELECT *
                                    FROM tblIQEE_Annulations A
                                    WHERE A.tiID_Type_Enregistrement = @tiID_Type_Enregistrement
                                      AND A.iID_Enregistrement_Demande_Annulation = D2.iID_Demande_IQEE
                                      AND A.iID_Session = @iID_Session
                                      AND A.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers)
                        -- qui ont été rejetées dans la création en cours
                        AND EXISTS (SELECT *
                                    -- Qui existe des rejets pour la convention...
                                    FROM tblIQEE_Rejets R
                                         -- Dans le fichier en cours de création...
                                         JOIN #tblIQEE_AnneesFiscales A3 ON A3.iID_Fichier_IQEE = R.iID_Fichier_IQEE
                                                                        AND A3.siAnnee_Fiscale = D2.siAnnee_Fiscale
                                         -- Qui sont des erreurs...
                                         JOIN tblIQEE_Validations V ON V.iID_Validation = R.iID_Validation
                                                                   AND V.cType = 'E'
                                         -- Sur les transactions de demandes d'IQÉÉ
                                         JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = V.tiID_Type_Enregistrement
                                                                            AND TE.cCode_Type_Enregistrement = '02'
                                   WHERE R.iID_Convention = D.iID_Convention))

    -- Boucler les demandes trouvées
    OPEN curValidation56_02
    FETCH NEXT FROM curValidation56_02 INTO @iID_Demande_IQEE, @iID_Fichier_IQEE, @iID_Convention, @siAnnee_Fiscale
    WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @vcTMP1 = REPLACE(@vcDescription,'%siAnnee_Fiscale%',CAST(@siAnnee_Fiscale AS VARCHAR(4)))
            EXECUTE dbo.psIQEE_AjouterRejet @iID_Fichier_IQEE, @iID_Convention,
                                 @iID_Validation, @vcTMP1,NULL,NULL,
                                 @iID_Convention,NULL,NULL

            DELETE FROM tblIQEE_TransactionsDemande
            WHERE iID_Demande_IQEE = @iID_Demande_IQEE

            DELETE FROM tblIQEE_Demandes
            WHERE iID_Demande_IQEE = @iID_Demande_IQEE

            FETCH NEXT FROM curValidation56_02 INTO @iID_Demande_IQEE, @iID_Fichier_IQEE, @iID_Convention, @siAnnee_Fiscale
        END
    CLOSE curValidation56_02
    DEALLOCATE curValidation56_02

-- TODO: Appliquer la validation 56 des demandes aux autres type de transactions


    ------------------------------------------------------------------------------------------------------------------------------
    -- Validation #87: Une demande d''IQÉÉ ne peux pas être présentée parce qu''il y a une transaction d''annulation/reprise
    --                   en rejet pour la convention.
    -- Note: Les validations #87 et #56 sont semblable mais différentes.  La validation #56 permet de rejeter des transactions
    --         à l'extérieur d'une séquence d'annulation/reprise et aussi à l'intérieur parce que "subséquentes".  La validation #87
    --         s'assure de rejeter les transactions de l'ensemble (à l'intérieur) d'une séquence d'annulation/reprise s'il y a un
    --         rejet dans la série.  Cela permet de ne pas faire une annulation/reprise partiel qui devrait être de toute façon
    --         reprise en entier lors de la création des fichiers suivante.
    ------------------------------------------------------------------------------------------------------------------------------
    SELECT @iID_Validation = iID_Validation,
           @vcDescription = vcDescription_Parametrable
    FROM tblIQEE_Validations
    WHERE iCode_Validation = 87

    -- Trouver les demandes d'IQÉÉ à rejeter
    DECLARE curValidation87_02 CURSOR LOCAL FAST_FORWARD FOR
        SELECT D.iID_Demande_IQEE, D.iID_Fichier_IQEE, D.iID_Convention
        -- Toutes les demandes des fichiers en cours de création
        FROM #tblIQEE_AnneesFiscales A
             JOIN tblIQEE_Demandes D ON D.iID_Fichier_IQEE = A.iID_Fichier_IQEE
-- TODO: Appliquer la validation 56 aux autres type de transactions
              -- La transaction à rejeter est une reprise d'une demande d'annulation
        WHERE EXISTS (SELECT *
                      -- Rechercher les transactions de demande d'IQÉÉ...
                      FROM tblIQEE_Demandes D2
                           JOIN tblIQEE_Fichiers F2 ON F2.iID_Fichier_IQEE = D2.iID_Fichier_IQEE
                                                   -- faisant partie des fichiers admissibles
                                                   AND (@bFichiers_Test_Comme_Production = 1
                                                        OR F2.bFichier_Test = 0)
                                                   AND F2.bInd_Simulation = 0
                                                   -- qui ne font partie de la création en cours
                                                   AND NOT EXISTS (SELECT *
                                                                   FROM #tblIQEE_AnneesFiscales A2
                                                                   WHERE A2.iID_Fichier_IQEE = F2.iID_Fichier_IQEE)
                        -- pour la même convention
                      WHERE D2.iID_Convention = D.iID_Convention
                        -- même année fiscale que la transaction à rejeter
                        AND D2.siAnnee_Fiscale = A.siAnnee_Fiscale
                        -- transactions actives
                        AND D2.tiCode_Version IN (0,2)
                        AND D2.cStatut_Reponse IN ('A','R')
                        -- qui font l'objet d'une demande d'annulation dans la création en cours
                        AND EXISTS (SELECT *
                                    FROM tblIQEE_Annulations A
                                    WHERE A.tiID_Type_Enregistrement = @tiID_Type_Enregistrement
                                      AND A.iID_Enregistrement_Demande_Annulation = D2.iID_Demande_IQEE
                                      AND A.iID_Session = @iID_Session
                                      AND A.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers))
          -- Existe une transaction d''annulation/reprise en rejet précédemment pour la même convention
          AND EXISTS (SELECT *
                      -- Rechercher les transactions de demande d'IQÉÉ...
                      FROM tblIQEE_Demandes D2
                           JOIN tblIQEE_Fichiers F2 ON F2.iID_Fichier_IQEE = D2.iID_Fichier_IQEE
                                                   -- faisant partie des fichiers admissibles
                                                   AND (@bFichiers_Test_Comme_Production = 1
                                                        OR F2.bFichier_Test = 0)
                                                   AND F2.bInd_Simulation = 0
                                                   -- qui ne font partie de la création en cours
                                                   AND NOT EXISTS (SELECT *
                                                                   FROM #tblIQEE_AnneesFiscales A2
                                                                   WHERE A2.iID_Fichier_IQEE = F2.iID_Fichier_IQEE)
                        -- pour la même convention
                      WHERE D2.iID_Convention = D.iID_Convention
                        -- années précédentes
                        AND D2.siAnnee_Fiscale < A.siAnnee_Fiscale
                        -- transactions actives
                        AND D2.tiCode_Version IN (0,2)
                        AND D2.cStatut_Reponse IN ('A','R')
                        -- qui font l'objet d'une demande d'annulation dans la création en cours
                        AND EXISTS (SELECT *
                                    FROM tblIQEE_Annulations A
                                    WHERE A.tiID_Type_Enregistrement = @tiID_Type_Enregistrement
                                      AND A.iID_Enregistrement_Demande_Annulation = D2.iID_Demande_IQEE
                                      AND A.iID_Session = @iID_Session
                                      AND A.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers)
                        -- qui ont été rejetées dans la création en cours
                        AND EXISTS (SELECT *
                                    -- Qui existe des rejets pour la convention...
                                    FROM tblIQEE_Rejets R
                                         -- Dans le fichier en cours de création...
                                         JOIN #tblIQEE_AnneesFiscales A3 ON A3.iID_Fichier_IQEE = R.iID_Fichier_IQEE
                                                                        AND A3.siAnnee_Fiscale = D2.siAnnee_Fiscale
                                         -- Qui sont des erreurs...
                                         JOIN tblIQEE_Validations V ON V.iID_Validation = R.iID_Validation
                                                                   AND V.cType = 'E'
                                         -- Sur les transactions de demandes d'IQÉÉ
                                         JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = V.tiID_Type_Enregistrement
                                                                            AND TE.cCode_Type_Enregistrement = '02'
                                   WHERE R.iID_Convention = D.iID_Convention))

    -- Boucler les demandes trouvées
    OPEN curValidation87_02
    FETCH NEXT FROM curValidation87_02 INTO @iID_Demande_IQEE, @iID_Fichier_IQEE, @iID_Convention
    WHILE @@FETCH_STATUS = 0
        BEGIN
            EXECUTE dbo.psIQEE_AjouterRejet @iID_Fichier_IQEE, @iID_Convention,
                                 @iID_Validation, @vcDescription,NULL,NULL,
                                 @iID_Convention,NULL,NULL

            DELETE FROM tblIQEE_TransactionsDemande
            WHERE iID_Demande_IQEE = @iID_Demande_IQEE

            DELETE FROM tblIQEE_Demandes
            WHERE iID_Demande_IQEE = @iID_Demande_IQEE

            FETCH NEXT FROM curValidation87_02 INTO @iID_Demande_IQEE, @iID_Fichier_IQEE, @iID_Convention
        END
    CLOSE curValidation87_02
    DEALLOCATE curValidation87_02

-- TODO: Appliquer la validation 87 des demandes aux autres type de transactions


    ------------------------------------------------------------------------------------------------------------------------------
    -- Annuler les demandes d'annulation des transactions existantes afin de laisser passer une transaction antérieure rejetée
    -- si la transaction antérieure n'a pas mené à la création d'une transacaction dans le passé
-- TODO?: - Annuler l’annulation/reprise s'il n'y a pas de nouvelles transactions dans le passé pour le cas d’annulation
--            automatique « Annulation des transactions qui sont susceptible de créer des transactions antérieurs valides parce
--            qu'il y a eu des rejets traitables dans le passé et que ces transactions valides ont été créer avant à cause de cela. »
--            Pas grave si ce n’est pas fait, la transaction sera juste repris!  Supprimer demande annulation s’il n’y a pas d’autres
--            transactions d’annulation de ce type et qu’il n’y a pas de nouvelle transaction dans le passé et qu’il n’y a pas de
--            champ modifié par la reprise.  Ajout d’un rejet spécifique pour ça.  Note: Pour faire ça, il ne faut pas qu’il y ai
--            d’autres annulations ou qu’il y ai des annulations de conséquences plus loin.  Pas sûr que je peux faire ça facilement.
-- Idée obsolete si retraiter l'annulation/reprise en cours de création?...
    ------------------------------------------------------------------------------------------------------------------------------

--    DECLARE curAnterieure_02 CURSOR LOCAL FAST_FORWARD FOR
--    SELECT --D.iID_Demande_IQEE, D.iID_Fichier_IQEE, D.iID_Convention, A.siAnnee_Fiscale
--    FROM tblIQEE_Annulations A
--         JOIN tblIQEE_RaisonsAnnulation RA ON RA.iID_Raison_Annulation = A.iID_Raison_Annulation
--                                          AND RA.vcCode_Raison = 'ANNULATION_TRANSACTION_PASSE_02'
----         JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = RA.tiID_Type_Enregistrement
--         JOIN tblIQEE_Demandes D1 ON D1.iID_Demande_IQEE = A.iID_Enregistrement_Demande_Annulation
--         JOIN tblIQEE_Fichiers F1 ON F1.iID_Fichier_IQEE = D1.iID_Fichier_IQEE
--    WHERE A.iID_Session = @iID_Session
--      AND A.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers
--      AND NOT EXISTS (SELECT *
--                      FROM tblIQEE_Demandes D2
--                           JOIN
--                      WHERE D2.iID_Convention = D1.iID_Convention
--
--    -- Boucler...
--    OPEN curAnterieure_02
--    FETCH NEXT FROM curAnterieure_02 INTO 
--    WHILE @@FETCH_STATUS = 0
--        BEGIN
--
--
--            FETCH NEXT FROM curAnterieure_02 INTO 
--        END
--    CLOSE curAnterieure_02
--    DEALLOCATE curAnterieure_02

END
