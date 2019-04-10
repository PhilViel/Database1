/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service        : psIQEE_ObtenirDetailsEvenement
Nom du service        : Obtenir les détails d'un événement
But                 : Obtenir les détails d'un événement de l'IQÉÉ ou d'UniAccès pour l'historique de l'IQÉÉ ou pour
                      consulter les informations d'une transaction de l'IQÉÉ.
Facette                : IQEE

Paramètres d’entrée    :    Paramètre                    Description
                        --------------------------    -----------------------------------------------------------------
                        iID_Utilisateur                Identifiant de l'utilisateur qui requière l'historique de l'IQÉÉ afin
                                                    de déterminer ses accès.
                        cID_Langue                    Identifiant de la langue de l'utilisateur.
                        bRetourner_Donnees_Brut        Indicateur si la procédure doit se contenter de retourner les données
                                                    brut dans la table temporaire
                        iID_Structure_Historique_    Identifiant de la structure de sélection choisie par l’utilisateur
                            Selection                dans l’historique de l’IQÉÉ.
                        iID_Structure_Historique_    Identifiant de la structure de présentation choisie par l’utilisateur
                            Presentation            dans l’historique de l’IQÉÉ.
                        iID_Convention_1            Identifiant de la convention de l’événement à consulter.
                        vcCode_Evenement_1            Code de l’événement à consulter.
                        vcCode_Type_1                Code de type de l’événement à consulter.
                        vcCode_Statut_A_Jour_1        Code de statut à jour de l’événement à consulter.
                        iID_Primaire_1                Identifiant unique primaire de l’événement à consulter.
                        iID_Convention_2            Identifiant de la convention du 2e événement à comparer avec le
                                                    1er événement.
                        vcCode_Evenement_2            Code du 2e événement à comparer avec le 1er événement.
                        vcCode_Type_2                Code de type du 2e événement à comparer avec le 1er événement.
                        vcCode_Statut_A_Jour_2        Code de statut à jour du 2e événement à comparer avec le 1er événement.
                        iID_Primaire_2                Identifiant unique primaire du 2e événement à comparer avec le 1er
                                                    événement.

Exemple d’appel        :    EXECUTE @iCode_Retour = [dbo]. 0, 293215, NULL, NULL, 0,
                                                 NULL, 1, 3, 6, 519626, 'FRA', @vcCode_Message OUTPUT, @vcCode_Statut OUTPUT
                        EXECUTE @iCode_Retour = [dbo]. 0, 293215, NULL, NULL, 0,
                                                 NULL, 2, 5, 6, 519626, 'FRA', @vcCode_Message OUTPUT, @vcCode_Statut OUTPUT
                        EXECUTE @iCode_Retour = [dbo]. 1, 293215, NULL, NULL, NULL,
                                                 NULL, NULL, NULL, NULL, NULL, NULL, @vcCode_Message OUTPUT, @vcCode_Statut OUTPUT

Paramètres de sortie:    Table                        Champ                            Description
                          -------------------------    ---------------------------     ---------------------------------
                        S/O                            iCode_Retour                    1 = Traitement réussi
                                                                                    0 = Traitement en erreur prévisible
                                                                                    -1 = Traitement en erreur non
                                                                                         prévisible
                        S/O                            vcCode_Message                    Code de message pour l'interface

Historique des modifications:
    Date        Programmeur             Description
    ----------  --------------------    -------------------------------------------------------------------------------
    2010-10-26  Éric Deshaies           Création du service
    2015-12-17  Jean-Philippe Simard    Ajout des Details pour les T06
    2016-01-13  Steeve Picard           Correction de la date de réponse pour les impôts spécials (T06)
    2016-04-28  Patrice Côté            IQEE-28 Ajout de la visualisation des TIO dans les T0403
    2016-05-01  Patrice Côté            Ajout de la récupération des montants base et majorée d'IQEE pour les T04
    2017-04-19  Steeve Picard           Exclusion des fichiers dont les flags «bFichier_Test & bSimulation» à vrai
    2017-04-19  Steeve Picard           Correction dans la récupération des champs des tables «tblIQEE_CategoriesErreur & tblIQEE_StatutsErreur»
    2017-12-09  Steeve Picard           Ajout des Details pour les T06-31
    2018-05-10  Steeve Picard           Modification à tblIQEE_ReponseTransfert, tous les champs de type «money» sont retirés
    2018-06-06  Steeve Picard           Modificiation de la gestion des retours d'erreur par RQ
***********************************************************************************************************************/
CREATE PROCEDURE dbo.psIQEE_ObtenirDetailsEvenement
(
    @iID_Utilisateur INT,
    @cID_Langue CHAR(3),
    @bRetourner_Donnees_Brut BIT,
    @iID_Structure_Historique_Selection INT,
    @iID_Structure_Historique_Presentation INT,
    @iID_Convention_1 INT,
    @vcCode_Evenement_1 VARCHAR(10),
    @vcCode_Type_1 VARCHAR(10),
    @vcCode_Statut_A_Jour_1 VARCHAR(20),
    @iID_Primaire_1 INT,
    @iID_Convention_2 INT,
    @vcCode_Evenement_2 VARCHAR(10),
    @vcCode_Type_2 VARCHAR(10),
    @vcCode_Statut_A_Jour_2 VARCHAR(20),
    @iID_Primaire_2 INT,
    @vcCode_Message VARCHAR(10) OUTPUT
)
AS
BEGIN

    BEGIN TRY
        DECLARE @nStep int = 0

        ----------------------------------------------
        --
        -- Initialisation et validation des paramètres
        --
        ----------------------------------------------
        DECLARE @vcCode_Structure_Selection VARCHAR(3),
                @vcCode_Structure_Presentation VARCHAR(3),
                @iID_Convention INT,
                @vcCode_Evenement VARCHAR(10),
                @vcCode_Type VARCHAR(10),
                @vcCode_Statut_A_Jour VARCHAR(20),
                @iID_Primaire INT,
                @Compteur INT,
                @vcCode_Regroupement VARCHAR(3),
                @vcCode_Regroupement1 VARCHAR(3),
                @vcCode_Regroupement2 VARCHAR(3),
                @vcNom_Champs_Retour VARCHAR(MAX),
                @vcNom_Champs_A_Traduire VARCHAR(MAX),
                @vcRequete VARCHAR(MAX),
                @iID_Parametres_IQEE INT,
                @iID_Fichier_IQEE INT,
                @iID_Erreur INT,
                @siCode_Erreur SMALLINT,
                @tiID_Statuts_Erreur TINYINT,
                @tiID_Categorie_Erreur TINYINT,
                @iID_Ligne_Fichier INT,
                @tiID_Type_Reponse TINYINT,
                @tiID_Justification_RQ TINYINT,
                @tiID_Categorie_Justification_RQ TINYINT,
                @iID_Operation INT,
                @iID_Reponse_Demande INT,
                @iID_Annulation INT,
                @iID_Type_Annulation INT,
                @iID_Raison_Annulation INT,
                @iID_Statut_Annulation INT,
                @iID_Rejet INT,
                @iID_Validation INT,
                @iID_Utilisateur_Demande INT,
                @iID_Utilisateur_Action_Menant_Annulation INT,
                @iID_Valeur_Maximum INT,
                @bComparaison BIT,
                @iValeur1 INT,
                @iValeur2 INT,
                @iDifference INT,
                @dtDate1 DATETIME,
                @dtDate2 DATETIME,
                @iID_Detail_Evenement INT,
                @vcNom_Table VARCHAR(150),
                @vcNom_Champ VARCHAR(150),
                @vcValeur VARCHAR(MAX),
                @vcType VARCHAR(200),
                @vcJustificationRQ VARCHAR(200)

        SET @iID_Valeur_Maximum = NULL
        SET @vcCode_Message = NULL
        SET @bComparaison = 0

        --------------
        -- Validations
        --------------
        BEGIN
            -- Considérer le français comme la langue par défaut
            IF @cID_Langue IS NULL
                SET @cID_Langue = 'FRA'

            -- Considérer le retour des données bruts par défaut
            IF @bRetourner_Donnees_Brut IS NULL
                SET @bRetourner_Donnees_Brut = 1

            -- Considérer tous les détails lorsque consultation d'un événement par l'interface utilisateur
            IF @bRetourner_Donnees_Brut = 0
                BEGIN
                    SET @iID_Structure_Historique_Selection = NULL
                    SET @iID_Structure_Historique_Presentation = NULL
                END

            -- Déterminer les structures d'historique par défaut lorsqu'elles ne sont pas spécifiées et le code associé à ces structures
            IF @iID_Structure_Historique_Selection IS NULL
                SET @vcNom_Champs_Retour = '*'
            ELSE
                SELECT @vcCode_Structure_Selection = SHS.vcCode_Structure
                FROM tblIQEE_HistoStructures SHS
                WHERE SHS.iID_Structure_Historique = @iID_Structure_Historique_Selection

            IF @iID_Structure_Historique_Presentation IS NULL
                SELECT @iID_Structure_Historique_Presentation = SH.iID_Structure_Historique
                FROM tblIQEE_HistoStructures SH
                WHERE SH.cType_Structure = 'P'
                  AND SH.vcCode_Structure = 'TI1'

            SELECT @vcCode_Structure_Presentation = SHP.vcCode_Structure
            FROM tblIQEE_HistoStructures SHP
            WHERE SHP.iID_Structure_Historique = @iID_Structure_Historique_Presentation

            -- Valider les paramètres
            IF @iID_Convention_1 IS NULL OR @iID_Convention_1 = 0 OR
               @vcCode_Evenement_1 IS NULL OR @vcCode_Evenement_1 = '' OR
               @vcCode_Type_1 IS NULL OR @vcCode_Type_1 = '' OR
               @vcCode_Statut_A_Jour_1 IS NULL OR @vcCode_Statut_A_Jour_1 = '' OR
               @iID_Primaire_1 IS NULL OR @iID_Primaire_1 = 0
                BEGIN
                    SET @vcCode_Message = 'GENEE0020'
                    RETURN 0
                END
        END
        
        ----------------------------------------
        -- Empêcher les comparaisons impossibles
        ----------------------------------------
        IF @iID_Convention_2 IS NOT NULL AND
           @vcCode_Evenement_2 IS NOT NULL AND
           @vcCode_Type_2 IS NOT NULL AND
           @vcCode_Statut_A_Jour_2 IS NOT NULL AND
           @iID_Primaire_2 IS NOT NULL
            BEGIN
                -- Déterminer les codes de regroupement des événements
                SELECT @vcCode_Regroupement1 = HE.vcCode_Regroupement
                FROM tblIQEE_HistoEvenements HE
                WHERE HE.vcCode_Evenement = @vcCode_Evenement_1
                  AND HE.vcCode_Type = @vcCode_Type_1

                SELECT @vcCode_Regroupement2 = HE.vcCode_Regroupement
                FROM tblIQEE_HistoEvenements HE
                WHERE HE.vcCode_Evenement = @vcCode_Evenement_2
                  AND HE.vcCode_Type = @vcCode_Type_2

                -- Si combinaison possible sinon impossible
                IF (@vcCode_Regroupement1 = 'TRA' AND @vcCode_Regroupement2 = 'TRA' AND @vcCode_Evenement_1 = @vcCode_Evenement_2 AND @iID_Primaire_1 <> @iID_Primaire_2)
                    SET @bComparaison = 1
                ELSE
                    SET @bComparaison = 0
            END
        ELSE
            SET @bComparaison = 0

        -----------------------------------------------
        --
        -- Rechercher les informations des 2 événements
        --
        -----------------------------------------------
        IF OBJECT_ID('tempdb..#tblIQEE_Details') IS NULL
            BEGIN
                CREATE TABLE #tblIQEE_Details(
                    iID_Detail_Evenement INT IDENTITY(1,1) NOT NULL, 
                    iID_Primaire INT,
                    iID_Valeur INT,
                    vcNom_Table VARCHAR(150),
                    vcNom_Champ VARCHAR(150),
                    vcType VARCHAR(150),
                    vcDescription VARCHAR(MAX),
                    iID_Enregistrement INT,
                    vcID_Enregistrement VARCHAR(15),
                    vcValeur1 VARCHAR(MAX),
                    vcValeur2 VARCHAR(MAX),
                    bComparaison BIT,
                    iID_Detail INT,    
                    vcDescription_Courte VARCHAR(MAX),
                    vcNom_Categorie VARCHAR(200),
                    iID_Reponse_Demande INT,
                    iID_Annulation INT,
                    iID_Erreur INT,
                    iID_Rejet INT)
            END
        ELSE
            TRUNCATE TABLE #tblIQEE_Details

        IF OBJECT_ID('tempdb..#tblGENE_Valeurs') IS NULL
            BEGIN
                CREATE TABLE #tblGENE_Valeurs
                    (iID_Session INT NOT NULL,
                    iID_Valeur INT IDENTITY(1,1) NOT NULL, 
                    vcNom_Table VARCHAR(150) NOT NULL,
                    vcNom_Champ VARCHAR(150) NOT NULL,
                    vcType VARCHAR(150) NULL,
                    vcDescription VARCHAR(MAX) NULL,
                    iID_Enregistrement INT NULL,
                    vcID_Enregistrement VARCHAR(15) NULL,
                    vcValeur VARCHAR(MAX) NULL)

                CREATE CLUSTERED INDEX ID_tblGENE_Valeurs ON #tblGENE_Valeurs (iID_Session)
            END
        ELSE
            TRUNCATE TABLE #tblGENE_Valeurs

        -- Boucler les 2 événements s'il y a lieu
        SET @Compteur = 1
        WHILE @Compteur <> 0
            BEGIN
                -- Sélectionner les 2 événements successivement
                IF @Compteur = 1
                    BEGIN
                        SET @iID_Convention = @iID_Convention_1
                        SET @vcCode_Evenement = @vcCode_Evenement_1
                        SET @vcCode_Type = @vcCode_Type_1
                        SET @vcCode_Statut_A_Jour = @vcCode_Statut_A_Jour_1
                        SET @iID_Primaire = @iID_Primaire_1
                    END
                IF @Compteur = 2
                    BEGIN
                        SET @iID_Convention = @iID_Convention_2
                        SET @vcCode_Evenement = @vcCode_Evenement_2
                        SET @vcCode_Type = @vcCode_Type_2
                        SET @vcCode_Statut_A_Jour = @vcCode_Statut_A_Jour_2
                        SET @iID_Primaire = @iID_Primaire_2
                    END

                -- Déterminer le code de regroupement de l'événement
                SELECT @vcCode_Regroupement = HE.vcCode_Regroupement
                FROM tblIQEE_HistoEvenements HE
                WHERE HE.vcCode_Evenement = @vcCode_Evenement
                  AND HE.vcCode_Type = @vcCode_Type


                -------------------------------------------------------
                -- Obtenir les données pour un événement de transaction
                -------------------------------------------------------

                    
                -----------------------------------------
                -- Transferts T02 - Demande de subvention
                -----------------------------------------
                IF @vcCode_Regroupement = 'TRA' AND @vcCode_Evenement = 'T02' 
                    BEGIN
                        -- Obtenir la transaction
                        IF @vcCode_Structure_Selection = 'SAC'
                            SET @vcNom_Champs_Retour = 'mTotal_Cotisations_Subventionnables,vcNAS_Beneficiaire,vcNAS_Souscripteur,vcNAS_Responsable,bInd_Cession_IQEE'
                        IF @vcCode_Structure_Selection IN ('TI1','TI2')
                            SET @vcNom_Champs_Retour = 'mCotisations,mTransfert_IN,mTotal_Cotisations_Subventionnables,mTotal_Cotisations,vcNAS_Beneficiaire,vcNom_Beneficiaire,'+
                                                       'vcPrenom_Beneficiaire,dtDate_Naissance_Beneficiaire,bInd_Cession_IQEE'
                        SET @vcRequete = 'WHERE iID_Demande_IQEE = '+CAST(@iID_Primaire AS VARCHAR)
                        SET @vcNom_Champs_A_Traduire = NULL

                        EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_Demandes','iID_Demande_IQEE',
                                                                                  @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue

                        IF @vcCode_Structure_Selection IS NULL OR @vcCode_Structure_Selection IN ('TI1','TI2')
                            BEGIN
                                -- Obtenir le fichier de la transaction
                                SELECT @iID_Parametres_IQEE = F.iID_Parametres_IQEE,
                                       @iID_Fichier_IQEE = F.iID_Fichier_IQEE,
                                       @iID_Ligne_Fichier = D.iID_Ligne_Fichier
                                FROM tblIQEE_Demandes D
                                     JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
                                                            AND F.bFichier_Test = 0 AND F.bInd_Simulation = 0
                                WHERE D.iID_Demande_IQEE = @iID_Primaire

                                IF @vcCode_Structure_Selection IS NULL
                                    BEGIN
                                        SET @vcNom_Champs_Retour = 'cLigne'
                                        SET @vcRequete = 'WHERE iID_Ligne_Fichier = '+CAST(@iID_Ligne_Fichier AS VARCHAR)
                                        SET @vcNom_Champs_A_Traduire = NULL

                                        EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_LignesFichier','iID_Ligne_Fichier',
                                                                                                  @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue
                                        SET @vcNom_Champs_Retour = '*'
                                    END

                                IF @vcCode_Structure_Selection IN ('TI1','TI2')
                                    SET @vcNom_Champs_Retour = 'dtDate_Creation,vcNom_Fichier,vcCode_Simulation'
                                IF @vcCode_Structure_Selection IS NULL
                                    SET @vcNom_Champs_Retour = 'dtDate_Creation,tiID_Type_Fichier,tiID_Statut_Fichier,iID_Parametres_IQEE,'+
                                                               'bFichier_Test,bInd_Simulation,vcCode_Simulation,vcNom_Fichier,vcChemin_Fichier,tCommentaires'
                                SET @vcRequete = 'WHERE iID_Fichier_IQEE = '+CAST(@iID_Fichier_IQEE AS VARCHAR)
                                SET @vcNom_Champs_A_Traduire = NULL

                                EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_Fichiers','iID_Fichier_IQEE',
                                                                                          @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue

                                -- Obtenir les paramètres de la transaction
                                SET @vcNom_Champs_Retour = 'dtDate_Debut_Cotisation,dtDate_Fin_Cotisation'
                                SET @vcRequete = 'WHERE iID_Parametres_IQEE = '+CAST(@iID_Parametres_IQEE AS VARCHAR)
                                SET @vcNom_Champs_A_Traduire = NULL

                                EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_Parametres','iID_Parametres_IQEE',
                                                                                          @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue

                                SET @vcNom_Champs_Retour = '*'
                            END

                        -- Raisons d'annulation
                        IF @vcCode_Type = 'TRA_1'
                            BEGIN
                                -- Rechercher les annulations
                                DECLARE curIQEE_Annulations CURSOR LOCAL FAST_FORWARD FOR
                                    SELECT A.iID_Annulation,A.iID_Type_Annulation,A.iID_Raison_Annulation,A.iID_Statut_Annulation
                                    FROM tblIQEE_Annulations A
                                         JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
                                                                            AND TE.cCode_Type_Enregistrement = '02'
                                    WHERE A.iID_Enregistrement_Annulation = @iID_Primaire
                                      AND A.vcCode_Simulation IS NULL
                                      AND EXISTS(SELECT *
                                                 FROM tblIQEE_Fichiers F2
                                                 WHERE F2.iID_Session = A.iID_Session
                                                   AND F2.dtDate_Creation_Fichiers = A.dtDate_Creation_Fichiers
                                                   AND F2.bFichier_Test = 0
                                                   AND F2.bInd_Simulation = 0)

                                -- Boucler les annulations
                                OPEN curIQEE_Annulations
                                FETCH NEXT FROM curIQEE_Annulations INTO @iID_Annulation,@iID_Type_Annulation,@iID_Raison_Annulation,@iID_Statut_Annulation
                                WHILE @@FETCH_STATUS = 0
                                    BEGIN
                                        -- Obtenir l'annulation
                                        IF @vcCode_Structure_Selection = 'SAC'
                                            SET @vcNom_Champs_Retour = 'tCommentaires'
                                        IF @vcCode_Structure_Selection IN ('TI1','TI2')
                                            SET @vcNom_Champs_Retour = 'tCommentaires'
                                        SET @vcRequete = 'WHERE iID_Annulation = '+CAST(@iID_Annulation AS VARCHAR)
                                        SET @vcNom_Champs_A_Traduire = NULL

                                        EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_Annulations','iID_Annulation',
                                                                                                  @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue

                                        -- Obtenir le type d'annulation
                                        IF @vcCode_Structure_Selection IS NULL
                                            BEGIN
                                                SET @vcRequete = 'WHERE iID_Type_Annulation = '+CAST(@iID_Type_Annulation AS VARCHAR)
                                                SET @vcNom_Champs_A_Traduire = 'vcDescription'

                                                EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_TypesAnnulation','iID_Type_Annulation',
                                                                                                          @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue
                                            END

                                        -- Obtenir la raison d'annulation
                                        IF @vcCode_Structure_Selection = 'SAC'
                                            SET @vcNom_Champs_Retour = 'vcCode_Raison,vcDescription'
                                        IF @vcCode_Structure_Selection IN ('TI1','TI2')
                                            SET @vcNom_Champs_Retour = 'vcCode_Raison,vcDescription,tCommentaires_TI'
                                        SET @vcRequete = 'WHERE iID_Raison_Annulation = '+CAST(@iID_Raison_Annulation AS VARCHAR)
                                        SET @vcNom_Champs_A_Traduire = 'vcDescription,tCommentaires_TI'

                                        EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_RaisonsAnnulation','iID_Raison_Annulation',
                                                                                                  @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue

                                        -- Obtenir le statut d'annulation
                                        IF @vcCode_Structure_Selection IS NULL
                                            BEGIN

                                                SET @vcRequete = 'WHERE iID_Statut_Annulation = '+CAST(@iID_Statut_Annulation AS VARCHAR)
                                                SET @vcNom_Champs_A_Traduire = 'vcDescription'

                                                EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_StatutsAnnulation','iID_Statut_Annulation',
                                                                                                          @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue
                                            END

                                        FETCH NEXT FROM curIQEE_Annulations INTO @iID_Annulation,@iID_Type_Annulation,@iID_Raison_Annulation,@iID_Statut_Annulation
                                    END
                                CLOSE curIQEE_Annulations
                                DEALLOCATE curIQEE_Annulations
                            END

                        -- Erreurs de la transaction en erreur
                        IF @vcCode_Statut_A_Jour = 'TRA_MAJ_E'
                            BEGIN
                                -- Rechercher les erreurs
                                DECLARE curIQEE_Erreurs CURSOR LOCAL FAST_FORWARD FOR
                                    SELECT E.iID_Erreur,E.siCode_Erreur,E.tiID_Statuts_Erreur,ER.tiID_Categorie_Erreur,E.iID_Fichier_IQEE
                                    FROM tblIQEE_Erreurs E
                                     JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = E.tiID_Type_Enregistrement
                                     JOIN tblIQEE_TypesErreurRQ ER ON ER.siCode_Erreur = E.siCode_Erreur
                                     JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = E.iID_Fichier_IQEE
                                                            AND F.bFichier_Test = 0 AND F.bInd_Simulation = 0
                                    WHERE E.iID_Enregistrement = @iID_Primaire
                                      AND TE.cCode_Type_Enregistrement = '02'
                                    ORDER BY F.dtDate_Creation DESC

                                -- Boucler les erreurs
                                OPEN curIQEE_Erreurs
                                FETCH NEXT FROM curIQEE_Erreurs INTO @iID_Erreur,@siCode_Erreur,@tiID_Statuts_Erreur,@tiID_Categorie_Erreur,@iID_Fichier_IQEE
                                WHILE @@FETCH_STATUS = 0
                                    BEGIN
                                        -- Obtenir l'erreur
                                        IF @vcCode_Structure_Selection = 'SAC'
                                            SET @vcNom_Champs_Retour = 'iID_Fichier_IQEE'
                                        IF @vcCode_Structure_Selection IN ('TI1','TI2')
                                            SET @vcNom_Champs_Retour = 'iID_Fichier_IQEE,vcElement_Erreur,vcValeur_Erreur,tCommentaires'
                                        SET @vcRequete = 'WHERE iID_Erreur = '+CAST(@iID_Erreur AS VARCHAR)
                                        SET @vcNom_Champs_A_Traduire = NULL

                                        EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_Erreurs','iID_Erreur',
                                                                                                  @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue

                                        -- Obtenir le fichier de l'erreur
                                        IF @vcCode_Structure_Selection IN ('TI1','TI2','SAC')
                                            SET @vcNom_Champs_Retour = 'dtDate_Creation,vcNom_Fichier'
                                        IF @vcCode_Structure_Selection IS NULL
                                            SET @vcNom_Champs_Retour = 'dtDate_Creation,tiID_Type_Fichier,tiID_Statut_Fichier,iID_Parametres_IQEE,'+
                                                                       'bFichier_Test,bInd_Simulation,vcCode_Simulation,vcNom_Fichier,vcChemin_Fichier,tCommentaires'
                                        SET @vcRequete = 'WHERE iID_Fichier_IQEE = '+CAST(@iID_Fichier_IQEE AS VARCHAR)
                                        SET @vcNom_Champs_A_Traduire = NULL

                                        EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_Fichiers','iID_Fichier_IQEE',
                                                                                                  @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue
                                        SET @vcNom_Champs_Retour = '*'

                                        -- Obtenir le type d'erreur
                                        IF @vcCode_Structure_Selection = 'SAC'
                                            SET @vcNom_Champs_Retour = 'vcDescription'
                                        IF @vcCode_Structure_Selection IN ('TI1','TI2')
                                            SET @vcNom_Champs_Retour = 'vcDescription,tiID_Categorie_Erreur'
                                        SET @vcRequete = 'WHERE siCode_Erreur = '+CAST(@siCode_Erreur AS VARCHAR)
                                        SET @vcNom_Champs_A_Traduire = 'vcDescription'

                                        EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_TypesErreurRQ','siCode_Erreur',
                                                                                                  @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue

                                        -- Obtenir le statut de l'erreur
                                        IF @vcCode_Structure_Selection IS NULL OR @vcCode_Structure_Selection IN ('TI1','TI2')
                                            BEGIN
                                                IF @vcCode_Structure_Selection IN ('TI1','TI2')
                                                    SET @vcNom_Champs_Retour = 'vcDescription'
                                                SET @vcRequete = 'WHERE tiID_Statuts_Erreur = '+CAST(@tiID_Statuts_Erreur AS VARCHAR)
                                                SET @vcNom_Champs_A_Traduire = 'vcDescription'

                                                SET @nStep = 1
                                                EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_StatutsErreur','tiID_Statuts_Erreur',
                                                                                                          @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue
                                            END

                                        -- Obtenir la catégorie d'erreur
                                        IF @vcCode_Structure_Selection IS NULL OR @vcCode_Structure_Selection IN ('TI1','TI2')
                                            BEGIN
                                                IF @vcCode_Structure_Selection IN ('TI1','TI2')
                                                    SET @vcNom_Champs_Retour = 'vcDescription'
                                                SET @vcRequete = 'WHERE tiID_Categorie_Erreur = '+CAST(@tiID_Categorie_Erreur AS VARCHAR)
                                                SET @vcNom_Champs_A_Traduire = 'vcDescription'

                                                EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_CategoriesErreur','tiID_Categorie_Erreur',
                                                                                                          @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue
                                            END

                                        FETCH NEXT FROM curIQEE_Erreurs INTO @iID_Erreur,@siCode_Erreur,@tiID_Statuts_Erreur,@tiID_Categorie_Erreur,@iID_Fichier_IQEE
                                    END
                                CLOSE curIQEE_Erreurs
                                DEALLOCATE curIQEE_Erreurs
                            END

                        -- Réponses d'une transaction déjà répondue
                        IF @vcCode_Statut_A_Jour IN ('TRA_MAJ_R','TRA_MAJ_D','TRA_MAJ_T')
                            BEGIN
                                -- Rechercher les réponses
                                DECLARE curIQEE_Reponses CURSOR LOCAL FAST_FORWARD FOR
                                    SELECT RD.iID_Reponse_Demande,RD.iID_Fichier_IQEE,RD.tiID_Type_Reponse,RD.tiID_Justification_RQ,J.tiID_Categorie_Justification_RQ,RD.iID_Operation
                                    FROM tblIQEE_ReponsesDemande RD
                                         JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = RD.iID_Fichier_IQEE
                                                                AND F.bFichier_Test = 0 AND F.bInd_Simulation = 0
                                         LEFT JOIN tblIQEE_JustificationsRQ J ON J.tiID_Justification_RQ = RD.tiID_Justification_RQ
                                    WHERE RD.iID_Demande_IQEE = @iID_Primaire
                                    ORDER BY F.dtDate_Creation DESC,RD.iID_Fichier_IQEE

                                -- Boucler les réponses
                                OPEN curIQEE_Reponses
                                FETCH NEXT FROM curIQEE_Reponses INTO @iID_Reponse_Demande,@iID_Fichier_IQEE,@tiID_Type_Reponse,@tiID_Justification_RQ,@tiID_Categorie_Justification_RQ,
                                                                      @iID_Operation
                                WHILE @@FETCH_STATUS = 0
                                    BEGIN
                                        -- Obtenir la réponse
                                        IF @vcCode_Structure_Selection = 'SAC'
                                            SET @vcNom_Champs_Retour = 'iID_Fichier_IQEE,tiID_Type_Reponse,tiID_Justification_RQ,mMontant,bInd_Partage'
                                        IF @vcCode_Structure_Selection IN ('TI1','TI2')
                                            SET @vcNom_Champs_Retour = 'iID_Fichier_IQEE,tiID_Type_Reponse,tiID_Justification_RQ,mMontant,bInd_Partage'
                                        SET @vcRequete = 'WHERE iID_Reponse_Demande = '+CAST(@iID_Reponse_Demande AS VARCHAR)
                                        SET @vcNom_Champs_A_Traduire = NULL

                                        EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_ReponsesDemande','iID_Reponse_Demande',
                                                                                                  @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue

                                        -- Obtenir le fichier de la réponse
                                        IF @vcCode_Structure_Selection IN ('TI1','TI2','SAC')
                                            SET @vcNom_Champs_Retour = 'dtDate_Creation,vcNom_Fichier,dtDate_Paiement'
                                        IF @vcCode_Structure_Selection IS NULL
                                            SET @vcNom_Champs_Retour = 'dtDate_Creation,tiID_Type_Fichier,tiID_Statut_Fichier,iID_Parametres_IQEE,'+
                                                                       'bFichier_Test,bInd_Simulation,vcCode_Simulation,vcNom_Fichier,vcChemin_Fichier,tCommentaires'
                                        SET @vcRequete = 'WHERE iID_Fichier_IQEE = '+CAST(@iID_Fichier_IQEE AS VARCHAR)
                                        SET @vcNom_Champs_A_Traduire = NULL

                                        EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_Fichiers','iID_Fichier_IQEE',
                                                                                                  @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue
                                        SET @vcNom_Champs_Retour = '*'

                                        -- Obtenir le type de réponse
                                        IF @vcCode_Structure_Selection = 'SAC'
                                            SET @vcNom_Champs_Retour = 'vcCode'
                                        IF @vcCode_Structure_Selection IN ('TI1','TI2')
                                            SET @vcNom_Champs_Retour = 'vcCode,vcDescription'
                                        SET @vcRequete = 'WHERE tiID_Type_Reponse = '+CAST(@tiID_Type_Reponse AS VARCHAR)
                                        SET @vcNom_Champs_A_Traduire = 'vcDescription'

                                        EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_TypesReponse','tiID_Type_Reponse',
                                                                                                  @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue

                                        -- Obtenir la justification
                                        IF @tiID_Justification_RQ IS NOT NULL
                                            BEGIN
                                                IF @vcCode_Structure_Selection = 'SAC'
                                                    SET @vcNom_Champs_Retour = 'cCode,vcDescription'
                                                IF @vcCode_Structure_Selection IN ('TI1','TI2')
                                                    SET @vcNom_Champs_Retour = '*'
                                                SET @vcRequete = 'WHERE tiID_Justification_RQ = '+CAST(@tiID_Justification_RQ AS VARCHAR)
                                                SET @vcNom_Champs_A_Traduire = 'vcDescription'

                                                EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_JustificationsRQ','tiID_Justification_RQ',
                                                                                                          @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue
                                            END

                                        -- Obtenir la catégorie de réponse
                                        IF @tiID_Categorie_Justification_RQ IS NOT NULL AND @vcCode_Structure_Selection IS NULL
                                            BEGIN
                                                SET @vcRequete = 'WHERE tiID_Categorie_Justification_RQ = '+CAST(@tiID_Categorie_Justification_RQ AS VARCHAR)
                                                SET @vcNom_Champs_A_Traduire = 'vcDescription'

                                                EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_CategorieJustification','tiID_Categorie_Justification_RQ',
                                                                                                          @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue
                                            END

                                        FETCH NEXT FROM curIQEE_Reponses INTO @iID_Reponse_Demande,@iID_Fichier_IQEE,@tiID_Type_Reponse,@tiID_Justification_RQ,
                                                                              @tiID_Categorie_Justification_RQ,@iID_Operation
                                    END
                                CLOSE curIQEE_Reponses
                                DEALLOCATE curIQEE_Reponses
                            END
                    END
                    
                ----------------------------------------------
                -- Transferts T04 - Transfert entre promoteurs
                ----------------------------------------------
                IF @vcCode_Regroupement = 'TRA' AND @vcCode_Evenement LIKE 'T04%' 
                    BEGIN
                        -- Obtenir la transaction
                        IF @vcCode_Structure_Selection = 'SAC'
                            SET @vcNom_Champs_Retour = 'iID_Operation_RIO, iID_TIO, mCotisations_Donne_Droit_IQEE,mCotisations_Non_Donne_Droit_IQEE,
                                                        mTotal_Transfert,mBEC,mJuste_Valeur_Marchande,iID_Ligne_Fichier,
                                                        mIQEE_CreditBase_Transfere, mIQEE_Majore_Transfere'
                        --IF @vcCode_Structure_Selection IN ('TI1','TI2')
                        --    SET @vcNom_Champs_Retour = 'mCotisations,mTransfert_IN,mTotal_Cotisations_Subventionnables,mTotal_Cotisations,vcNAS_Beneficiaire,vcNom_Beneficiaire,'+
                        --                               'vcPrenom_Beneficiaire,dtDate_Naissance_Beneficiaire,bInd_Cession_IQEE'
                        SET @vcRequete = 'WHERE iID_Transfert = ' + CAST(@iID_Primaire AS VARCHAR)
                        SET @vcNom_Champs_A_Traduire = NULL

                        EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_Transferts','iID_Transfert',
                                                                                  @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue

                        -- Réponses d'une transaction déjà répondue
                        IF @vcCode_Statut_A_Jour IN ('TRA_MAJ_R','TRA_MAJ_D','TRA_MAJ_T')
                            BEGIN
                                -- Rechercher les réponses
                                DECLARE curIQEE_Reponses CURSOR LOCAL FAST_FORWARD FOR
                                    SELECT RI.iID_Reponse_Transfert,RI.iID_Fichier_IQEE
                                    FROM tblIQEE_ReponsesTRansfert RI
                                         JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = RI.iID_Fichier_IQEE
                                                                AND F.bFichier_Test = 0 AND F.bInd_Simulation = 0
                                    WHERE RI.iID_Transfert_IQEE = @iID_Primaire
                                    ORDER BY F.dtDate_Creation DESC,RI.iID_Fichier_IQEE

                                -- Boucler les réponses
                                OPEN curIQEE_Reponses
                                FETCH NEXT FROM curIQEE_Reponses INTO @iID_Reponse_Demande,@iID_Fichier_IQEE
                                WHILE @@FETCH_STATUS = 0
                                    BEGIN
                                        -- Obtenir la réponse
                                        SET @vcNom_Champs_Retour = 'iID_Fichier_IQEE'
                                        SET @vcRequete = 'WHERE iID_Reponse_TRansfert = '+CAST(@iID_Reponse_Demande AS VARCHAR)
                                        SET @vcNom_Champs_A_Traduire = NULL

                                        EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_ReponsesTransfert','iID_Reponse_Transfert',
                                                                                                  @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue

                                        -- Obtenir le fichier de la réponse
                                        IF @vcCode_Structure_Selection IN ('TI1','TI2','SAC')
                                            SET @vcNom_Champs_Retour = 'dtDate_Creation,vcNom_Fichier,dtDate_Paiement'
                                        IF @vcCode_Structure_Selection IS NULL
                                            SET @vcNom_Champs_Retour = 'dtDate_Creation,tiID_Type_Fichier,tiID_Statut_Fichier,iID_Parametres_IQEE,'+
                                                                       'bFichier_Test,bInd_Simulation,vcCode_Simulation,vcNom_Fichier,vcChemin_Fichier,tCommentaires'
                                        SET @vcRequete = 'WHERE iID_Fichier_IQEE = '+CAST(@iID_Fichier_IQEE AS VARCHAR)
                                        SET @vcNom_Champs_A_Traduire = NULL

                                        EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_Fichiers','iID_Fichier_IQEE',
                                                                                                  @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue
                                        SET @vcNom_Champs_Retour = '*'

                                        FETCH NEXT FROM curIQEE_Reponses INTO @iID_Reponse_Demande,@iID_Fichier_IQEE
                                    END
                                CLOSE curIQEE_Reponses
                                DEALLOCATE curIQEE_Reponses
                            END
                    END
                    
                -----------------------------------
                -- Transferts T06 - Impôts spéciaux
                -----------------------------------

                IF @vcCode_Regroupement = 'TRA' AND @vcCode_Evenement IN ('T0601','T0602','T0622','T0623','T0631','T0641','T0691') 
                    BEGIN
                        -- Obtenir la transaction
                        SET @vcNom_Champs_Retour = 'dtDate_Evenement,mCotisations_Retirees,mSolde_IQEE_Base,mSolde_IQEE_Majore,mIQEE_ImpotSpecial,vcNAS_Beneficiaire'
                        SET @vcRequete = 'WHERE iID_Impot_Special = '+CAST(@iID_Primaire AS VARCHAR)
                        SET @vcNom_Champs_A_Traduire = NULL

                        EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_ImpotsSpeciaux','iID_Impot_Special',
                                                                                  @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue

                        -- Raisons d'annulation
                        IF @vcCode_Type = 'TRA_1'
                            BEGIN
                                -- Rechercher les annulations
                                DECLARE curIQEE_Annulations CURSOR LOCAL FAST_FORWARD FOR
                                    SELECT A.iID_Annulation,A.iID_Type_Annulation,A.iID_Raison_Annulation,A.iID_Statut_Annulation
                                    FROM tblIQEE_Annulations A
                                         JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
                                                                            AND TE.cCode_Type_Enregistrement = '06'
                                    WHERE A.iID_Enregistrement_Annulation = @iID_Primaire
                                      AND A.vcCode_Simulation IS NULL
                                      --2015-12-17: Un différentiel existe entre la date creation du fichier IQEE et l'insertion de l'entrée dans la table d'annulation
                                      --AND EXISTS(SELECT *
                                            --     FROM tblIQEE_Fichiers F2
                                            --     WHERE F2.iID_Session = A.iID_Session
                                            --       AND F2.dtDate_Creation_Fichiers = A.dtDate_Creation_Fichiers
                                            --       AND F2.bFichier_Test = 0
                                            --       AND F2.bInd_Simulation = 0)

                                -- Boucler les annulations
                                OPEN curIQEE_Annulations
                                FETCH NEXT FROM curIQEE_Annulations INTO @iID_Annulation,@iID_Type_Annulation,@iID_Raison_Annulation,@iID_Statut_Annulation
                                WHILE @@FETCH_STATUS = 0
                                    BEGIN
                                        -- Obtenir l'annulation
                                        SET @vcNom_Champs_Retour = 'tCommentaires'
                                        SET @vcRequete = 'WHERE iID_Annulation = '+CAST(@iID_Annulation AS VARCHAR)
                                        SET @vcNom_Champs_A_Traduire = NULL

                                        EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_Annulations','iID_Annulation',
                                                                                                  @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue

                                        -- Obtenir le type d'annulation
                                        IF @vcCode_Structure_Selection IS NULL
                                            BEGIN
                                                SET @vcRequete = 'WHERE iID_Type_Annulation = '+CAST(@iID_Type_Annulation AS VARCHAR)
                                                SET @vcNom_Champs_A_Traduire = 'vcDescription'

                                                EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_TypesAnnulation','iID_Type_Annulation',
                                                                                                          @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue
                                            END

                                        -- Obtenir la raison d'annulation
                                        SET @vcNom_Champs_Retour = 'vcCode_Raison,vcDescription'
                                        SET @vcRequete = 'WHERE iID_Raison_Annulation = '+CAST(@iID_Raison_Annulation AS VARCHAR)
                                        SET @vcNom_Champs_A_Traduire = 'vcDescription,tCommentaires_TI'

                                        EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_RaisonsAnnulation','iID_Raison_Annulation',
                                                                                                  @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue

                                        -- Obtenir le statut d'annulation
                                        IF @vcCode_Structure_Selection IS NULL
                                            BEGIN

                                                SET @vcRequete = 'WHERE iID_Statut_Annulation = '+CAST(@iID_Statut_Annulation AS VARCHAR)
                                                SET @vcNom_Champs_A_Traduire = 'vcDescription'

                                                EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_StatutsAnnulation','iID_Statut_Annulation',
                                                                                                          @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue
                                            END

                                        FETCH NEXT FROM curIQEE_Annulations INTO @iID_Annulation,@iID_Type_Annulation,@iID_Raison_Annulation,@iID_Statut_Annulation
                                    END
                                CLOSE curIQEE_Annulations
                                DEALLOCATE curIQEE_Annulations
                            END

                        -- Erreurs de la transaction en erreur
                        IF @vcCode_Statut_A_Jour = 'TRA_MAJ_E'
                            BEGIN
                                -- Rechercher les erreurs
                                DECLARE curIQEE_Erreurs CURSOR LOCAL FAST_FORWARD FOR
                                    SELECT E.iID_Erreur,E.siCode_Erreur,E.tiID_Statuts_Erreur,ER.tiID_Categorie_Erreur,E.iID_Fichier_IQEE
                                    FROM tblIQEE_Erreurs E
                                     JOIN tblIQEE_TypesEnregistrement TE ON E.tiID_Type_Enregistrement = TE.tiID_Type_Enregistrement
                                     JOIN tblIQEE_TypesErreurRQ ER ON ER.siCode_Erreur = E.siCode_Erreur
                                     JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = E.iID_Fichier_IQEE
                                                            AND F.bFichier_Test = 0 AND F.bInd_Simulation = 0
                                    WHERE E.iID_Enregistrement = @iID_Primaire
                                      AND TE.cCode_Type_Enregistrement = '06'
                                    ORDER BY F.dtDate_Creation DESC

                                -- Boucler les erreurs
                                OPEN curIQEE_Erreurs
                                FETCH NEXT FROM curIQEE_Erreurs INTO @iID_Erreur,@siCode_Erreur,@tiID_Statuts_Erreur,@tiID_Categorie_Erreur,@iID_Fichier_IQEE
                                WHILE @@FETCH_STATUS = 0
                                    BEGIN
                                        -- Obtenir l'erreur
                                        SET @vcNom_Champs_Retour = 'iID_Fichier_IQEE'
                                        SET @vcRequete = 'WHERE iID_Erreur = '+CAST(@iID_Erreur AS VARCHAR)
                                        SET @vcNom_Champs_A_Traduire = NULL

                                        EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_Erreurs','iID_Erreur',
                                                                                                  @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue

                                        -- Obtenir le fichier de l'erreur
                                        IF @vcCode_Structure_Selection IN ('TI1','TI2','SAC')
                                            SET @vcNom_Champs_Retour = 'dtDate_Creation,vcNom_Fichier'
                                        IF @vcCode_Structure_Selection IS NULL
                                            SET @vcNom_Champs_Retour = 'dtDate_Creation,tiID_Type_Fichier,tiID_Statut_Fichier,iID_Parametres_IQEE,'+
                                                                       'bFichier_Test,bInd_Simulation,vcCode_Simulation,vcNom_Fichier,vcChemin_Fichier,tCommentaires'
                                        SET @vcRequete = 'WHERE iID_Fichier_IQEE = '+CAST(@iID_Fichier_IQEE AS VARCHAR)
                                        SET @vcNom_Champs_A_Traduire = NULL

                                        EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_Fichiers','iID_Fichier_IQEE',
                                                                                                  @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue
                                        SET @vcNom_Champs_Retour = '*'

                                        -- Obtenir le type d'erreur
                                        SET @vcNom_Champs_Retour = 'vcDescription'
                                        SET @vcRequete = 'WHERE siCode_Erreur = '+CAST(@siCode_Erreur AS VARCHAR)
                                        SET @vcNom_Champs_A_Traduire = 'vcDescription'

                                        EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_TypesErreurRQ','siCode_Erreur',
                                                                                                  @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue

                                        -- Obtenir le statut de l'erreur
                                        IF @vcCode_Structure_Selection IS NULL OR @vcCode_Structure_Selection IN ('TI1','TI2')
                                            BEGIN
                                                IF @vcCode_Structure_Selection IN ('TI1','TI2')
                                                    SET @vcNom_Champs_Retour = 'vcDescription'
                                                ELSE
                                                    SET @vcNom_Champs_Retour = 'vcCode_Statut,vcDescription'
                                                SET @vcRequete = 'WHERE tiID_Statuts_Erreur = '+CAST(@tiID_Statuts_Erreur AS VARCHAR)
                                                SET @vcNom_Champs_A_Traduire = 'vcDescription'

                                                SET @nStep = 2
                                                EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_StatutsErreur','tiID_Statuts_Erreur',
                                                                                                          @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue
                                            END

                                        -- Obtenir la catégorie d'erreur
                                        IF @vcCode_Structure_Selection IS NULL OR @vcCode_Structure_Selection IN ('TI1','TI2')
                                            BEGIN
                                                IF @vcCode_Structure_Selection IN ('TI1','TI2')
                                                    SET @vcNom_Champs_Retour = 'vcDescription'
                                                ELSE
                                                    SET @vcNom_Champs_Retour = 'vcCode_Categorie,vcDescription'
                                                SET @vcRequete = 'WHERE tiID_Categorie_Erreur = '+CAST(@tiID_Categorie_Erreur AS VARCHAR)
                                                SET @vcNom_Champs_A_Traduire = 'vcDescription'

                                                EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_CategoriesErreur','tiID_Categorie_Erreur',
                                                                                                          @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue
                                            END

                                        FETCH NEXT FROM curIQEE_Erreurs INTO @iID_Erreur,@siCode_Erreur,@tiID_Statuts_Erreur,@tiID_Categorie_Erreur,@iID_Fichier_IQEE
                                    END
                                CLOSE curIQEE_Erreurs
                                DEALLOCATE curIQEE_Erreurs
                            END

                        -- Réponses d'une transaction déjà répondue
                        IF @vcCode_Statut_A_Jour IN ('TRA_MAJ_R','TRA_MAJ_D','TRA_MAJ_T')
                            BEGIN
                                -- Rechercher les réponses
                                DECLARE curIQEE_Reponses CURSOR LOCAL FAST_FORWARD FOR
                                    SELECT RI.iID_Reponse_Impot_Special,RI.iID_Fichier_IQEE
                                    FROM tblIQEE_ReponsesImpotsSpeciaux RI
                                         JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = RI.iID_Fichier_IQEE
                                                                AND F.bFichier_Test = 0 AND F.bInd_Simulation = 0
                                    WHERE RI.iID_Impot_Special_IQEE = @iID_Primaire
                                    ORDER BY F.dtDate_Creation DESC,RI.iID_Fichier_IQEE

                                -- Boucler les réponses
                                OPEN curIQEE_Reponses
                                FETCH NEXT FROM curIQEE_Reponses INTO @iID_Reponse_Demande,@iID_Fichier_IQEE
                                WHILE @@FETCH_STATUS = 0
                                    BEGIN
                                        -- Obtenir la réponse
                                        SET @vcNom_Champs_Retour = 'iID_Fichier_IQEE,dtDate_Avis,mMontant_IQEE_Base,mMontant_IQEE_Majore,mMontant_IQEE'
                                        SET @vcRequete = 'WHERE iID_Reponse_Impot_Special = '+CAST(@iID_Reponse_Demande AS VARCHAR)
                                        SET @vcNom_Champs_A_Traduire = NULL

                                        EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_ReponsesImpotsSpeciaux','iID_Reponse_Impot_Special',
                                                                                                  @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue

                                        -- Obtenir le fichier de la réponse
                                        IF @vcCode_Structure_Selection IN ('TI1','TI2','SAC')
                                            SET @vcNom_Champs_Retour = 'dtDate_Creation,vcNom_Fichier,dtDate_Paiement'
                                        IF @vcCode_Structure_Selection IS NULL
                                            SET @vcNom_Champs_Retour = 'dtDate_Creation,tiID_Type_Fichier,tiID_Statut_Fichier,iID_Parametres_IQEE,'+
                                                                       'bFichier_Test,bInd_Simulation,vcCode_Simulation,vcNom_Fichier,vcChemin_Fichier,tCommentaires'
                                        SET @vcRequete = 'WHERE iID_Fichier_IQEE = '+CAST(@iID_Fichier_IQEE AS VARCHAR)
                                        SET @vcNom_Champs_A_Traduire = NULL

                                        EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_Fichiers','iID_Fichier_IQEE',
                                                                                                  @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue
                                        SET @vcNom_Champs_Retour = '*'

                                        ---- Obtenir le type de réponse
                                        --IF @vcCode_Structure_Selection = 'SAC'
                                        --    SET @vcNom_Champs_Retour = 'vcCode'
                                        --IF @vcCode_Structure_Selection IN ('TI1','TI2')
                                        --    SET @vcNom_Champs_Retour = 'vcCode,vcDescription'
                                        --SET @vcRequete = 'WHERE tiID_Type_Reponse = '+CAST(@tiID_Type_Reponse AS VARCHAR)
                                        --SET @vcNom_Champs_A_Traduire = 'vcDescription'

                                        --EXECUTE [dbo].[psGENE_ObtenirValeursEnregistrementsTable] 'tblIQEE_TypesReponse','tiID_Type_Reponse',
                                        --                                                          @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue

                                        -- Obtenir la justification
                                        --IF @tiID_Justification_RQ IS NOT NULL
                                        --    BEGIN
                                        --        IF @vcCode_Structure_Selection = 'SAC'
                                        --            SET @vcNom_Champs_Retour = 'cCode,vcDescription'
                                        --        IF @vcCode_Structure_Selection IN ('TI1','TI2')
                                        --            SET @vcNom_Champs_Retour = '*'
                                        --        SET @vcRequete = 'WHERE tiID_Justification_RQ = '+CAST(@tiID_Justification_RQ AS VARCHAR)
                                        --        SET @vcNom_Champs_A_Traduire = 'vcDescription'

                                        --        EXECUTE [dbo].[psGENE_ObtenirValeursEnregistrementsTable] 'tblIQEE_JustificationsRQ','tiID_Justification_RQ',
                                        --                                                                  @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue
                                        --    END

                                        -- Obtenir la catégorie de réponse
                                        --IF @tiID_Categorie_Justification_RQ IS NOT NULL AND @vcCode_Structure_Selection IS NULL
                                        --    BEGIN
                                        --        SET @vcRequete = 'WHERE tiID_Categorie_Justification_RQ = '+CAST(@tiID_Categorie_Justification_RQ AS VARCHAR)
                                        --        SET @vcNom_Champs_A_Traduire = 'vcDescription'

                                        --        EXECUTE [dbo].[psGENE_ObtenirValeursEnregistrementsTable] 'tblIQEE_CategorieJustification','tiID_Categorie_Justification_RQ',
                                        --                                                                  @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue
                                        --    END

                                        FETCH NEXT FROM curIQEE_Reponses INTO @iID_Reponse_Demande,@iID_Fichier_IQEE
                                    END
                                CLOSE curIQEE_Reponses
                                DEALLOCATE curIQEE_Reponses
                            END
                    END

-- TODO: Traiter les autres types de transaction

                -------------------------------------------------
                -- Obtenir les données pour un événement de rejet
                -------------------------------------------------

                -- Transaction de demande
                IF @vcCode_Regroupement = 'REJ'
                    BEGIN
                        -- Rechercher les rejets
                        DECLARE curIQEE_Rejets CURSOR LOCAL FAST_FORWARD FOR
                            SELECT R.iID_Rejet,V.iID_Validation
                            FROM tblIQEE_Rejets PR
                                 JOIN tblIQEE_Validations PV ON PV.iID_Validation = PR.iID_Validation
                                 JOIN tblIQEE_Rejets R ON R.iID_Convention = PR.iID_Convention
                                                    AND R.iID_Fichier_IQEE = PR.iID_Fichier_IQEE
                                                    AND ISNULL(R.iID_Lien_Vers_Erreur_1,0) = ISNULL(PR.iID_Lien_Vers_Erreur_1,0)
                                 JOIN tblIQEE_Validations V ON V.iID_Validation = R.iID_Validation
                                                         AND V.tiID_Type_Enregistrement = PV.tiID_Type_Enregistrement
                                                         AND ISNULL(V.iID_Sous_Type,0) = ISNULL(PV.iID_Sous_Type,0)
                                                         AND V.cType = 'E'
                            WHERE PR.iID_Rejet = @iID_Primaire
                            ORDER BY V.iOrdre_Presentation

                        -- Boucler les rejets
                        OPEN curIQEE_Rejets
                        FETCH NEXT FROM curIQEE_Rejets INTO @iID_Rejet,@iID_Validation
                        WHILE @@FETCH_STATUS = 0
                            BEGIN
                                -- Obtenir le rejet
                                IF @vcCode_Structure_Selection = 'SAC'
                                    SET @vcNom_Champs_Retour = 'vcDescription'
                                IF @vcCode_Structure_Selection IN ('TI1','TI2')
                                    SET @vcNom_Champs_Retour = 'vcDescription'
                                SET @vcRequete = 'WHERE iID_Rejet = '+CAST(@iID_Rejet AS VARCHAR)
                                SET @vcNom_Champs_A_Traduire = 'vcDescription'

                                EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_Rejets','iID_Rejet',
                                                                                          @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue

                                -- Obtenir la validation du rejet
                                IF @vcCode_Structure_Selection = 'SAC'
                                    SET @vcNom_Champs_Retour = 'iCode_Validation'
                                IF @vcCode_Structure_Selection IN ('TI1','TI2')
                                    SET @vcNom_Champs_Retour = 'iCode_Validation'
                                SET @vcRequete = 'WHERE iID_Validation = '+CAST(@iID_Validation AS VARCHAR)
                                SET @vcNom_Champs_A_Traduire = 'vcDescription_Parametrable,vcDescription_Valeur_Reference,vcDescription_Valeur_Erreur,vcDescription_Lien_Vers_Erreur_1,vcDescription_Lien_Vers_Erreur_2,vcDescription_Lien_Vers_Erreur_3'

                                EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_Validations','iID_Validation',
                                                                                          @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue

                                IF @vcCode_Structure_Selection IS NULL OR @vcCode_Structure_Selection IN ('TI1','TI2')
                                    BEGIN
                                        -- Obtenir le fichier de la transaction
                                        SELECT @iID_Parametres_IQEE = F.iID_Parametres_IQEE
                                        FROM tblIQEE_Rejets PR
                                             JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = PR.iID_Fichier_IQEE
                                                                    AND F.bFichier_Test = 0 AND F.bInd_Simulation = 0
                                        WHERE PR.iID_Rejet = @iID_Primaire

                                        -- Obtenir les paramètres de la transaction
                                        SET @vcNom_Champs_Retour = 'dtDate_Debut_Cotisation,dtDate_Fin_Cotisation'
                                        SET @vcRequete = 'WHERE iID_Parametres_IQEE = '+CAST(@iID_Parametres_IQEE AS VARCHAR)
                                        SET @vcNom_Champs_A_Traduire = NULL

                                        EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_Parametres','iID_Parametres_IQEE',
                                                                                                  @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue

                                        SET @vcNom_Champs_Retour = '*'
                                    END

                                FETCH NEXT FROM curIQEE_Rejets INTO @iID_Rejet,@iID_Validation
                            END
                        CLOSE curIQEE_Rejets
                        DEALLOCATE curIQEE_Rejets
                    END

-- TODO: Traiter les autres types de transaction?


                -----------------------------------------------
                -- Obtenir les données pour un événement erreur
                -----------------------------------------------

                -- Erreur
                IF @vcCode_Regroupement = 'ERR'
                    BEGIN
                        -- Rechercher l'erreur
                        SELECT @iID_Erreur = E.iID_Erreur,
                               @siCode_Erreur = E.siCode_Erreur,
                               @tiID_Statuts_Erreur = E.tiID_Statuts_Erreur,
                               @tiID_Categorie_Erreur = ER.tiID_Categorie_Erreur,
                               @iID_Fichier_IQEE = E.iID_Fichier_IQEE
                        FROM tblIQEE_Erreurs E
                         JOIN tblIQEE_TypesErreurRQ ER ON ER.siCode_Erreur = E.siCode_Erreur
                         JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = E.iID_Fichier_IQEE
                                                AND F.bFichier_Test = 0 AND F.bInd_Simulation = 0
                        WHERE E.iID_Erreur = @iID_Primaire
                        ORDER BY F.dtDate_Creation DESC

                        -- Obtenir l'erreur
                        IF @vcCode_Structure_Selection IN ('TI1','TI2')
                            SET @vcNom_Champs_Retour = 'iID_Fichier_IQEE,vcElement_Erreur,vcValeur_Erreur,tCommentaires'
                        SET @vcRequete = 'WHERE iID_Erreur = '+CAST(@iID_Erreur AS VARCHAR)
                        SET @vcNom_Champs_A_Traduire = NULL

                        EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_Erreurs','iID_Erreur',
                                                                                  @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue

                        -- Obtenir le fichier de l'erreur
                        IF @vcCode_Structure_Selection IN ('TI1','TI2')
                            SET @vcNom_Champs_Retour = 'dtDate_Creation,vcNom_Fichier'
                        IF @vcCode_Structure_Selection IS NULL
                            SET @vcNom_Champs_Retour = ',dtDate_Creation,tiID_Type_Fichier,tiID_Statut_Fichier,iID_Parametres_IQEE,'+
                                                       'bFichier_Test,bInd_Simulation,vcCode_Simulation,vcNom_Fichier,vcChemin_Fichier,tCommentaires'
                        SET @vcRequete = 'WHERE iID_Fichier_IQEE = '+CAST(@iID_Fichier_IQEE AS VARCHAR)
                        SET @vcNom_Champs_A_Traduire = NULL

                        EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_Fichiers','iID_Fichier_IQEE',
                                                                                  @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue
                        SET @vcNom_Champs_Retour = '*'

                        -- Obtenir le type d'erreur
                        IF @vcCode_Structure_Selection IN ('TI1','TI2')
                            SET @vcNom_Champs_Retour = 'vcDescription'
                        SET @vcRequete = 'WHERE siCode_Erreur = '+CAST(@siCode_Erreur AS VARCHAR)
                        SET @vcNom_Champs_A_Traduire = 'vcDescription'

                        EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_TypesErreurRQ','siCode_Erreur',
                                                                                  @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue

                        -- Obtenir le statut de l'erreur
                        IF @vcCode_Structure_Selection IN ('TI1','TI2')
                            SET @vcNom_Champs_Retour = 'vcDescription'
                        SET @vcRequete = 'WHERE tiID_Statuts_Erreur = '+CAST(@tiID_Statuts_Erreur AS VARCHAR)
                        SET @vcNom_Champs_A_Traduire = 'vcDescription'

                        SET @nStep = 3
                        EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_StatutsErreur','tiID_Statuts_Erreur',
                                                                                  @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue

                        -- Obtenir la catégorie d'erreur
                        IF @vcCode_Structure_Selection IN ('TI1','TI2')
                            SET @vcNom_Champs_Retour = 'vcDescription'
                        SET @vcRequete = 'WHERE tiID_Categorie_Erreur = '+CAST(@tiID_Categorie_Erreur AS VARCHAR)
                        SET @vcNom_Champs_A_Traduire = 'vcDescription'

                        EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_CategoriesErreur','tiID_Categorie_Erreur',
                                                                                  @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue
                    END


                -----------------------------------------------------
                -- Obtenir les données pour un événement d'annulation
                -----------------------------------------------------

                -- Annulation
                IF @vcCode_Regroupement = 'A/R'
                    BEGIN
                        -- Rechercher l'annulation
                        SELECT @iID_Annulation = A.iID_Annulation,
                               @iID_Type_Annulation = A.iID_Type_Annulation,
                               @iID_Raison_Annulation = A.iID_Raison_Annulation,
                               @iID_Statut_Annulation = A.iID_Statut_Annulation,
                               @iID_Utilisateur_Demande = A.iID_Utilisateur_Demande,
                               @iID_Utilisateur_Action_Menant_Annulation = A.iID_Utilisateur_Action_Menant_Annulation
                        FROM tblIQEE_Annulations A
                        WHERE A.iID_Annulation = @iID_Primaire

                        -- Obtenir l'annulation
                        IF @vcCode_Structure_Selection IN ('TI1','TI2')
                            SET @vcNom_Champs_Retour = 'iID_Utilisateur_Demande,iID_Utilisateur_Action_Menant_Annulation,tCommentaires,dtDate_Action_Menant_Annulation'
                        SET @vcRequete = 'WHERE iID_Annulation = '+CAST(@iID_Annulation AS VARCHAR)
                        SET @vcNom_Champs_A_Traduire = NULL

                        EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_Annulations','iID_Annulation',
                                                                                  @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue

                        -- Obtenir le demandeur
                        IF @iID_Utilisateur_Demande IS NOT NULL
                            BEGIN
                                IF @vcCode_Structure_Selection IN ('TI1','TI2')
                                    SET @vcNom_Champs_Retour = 'FirstName,LastName'
                                SET @vcRequete = 'WHERE HumanID = '+CAST(@iID_Utilisateur_Demande AS VARCHAR)
                                SET @vcNom_Champs_A_Traduire = NULL

                                EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'Mo_Human','HumanID',
                                                                                          @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue
                            END

                        -- Obtenir le déclencheur
                        IF @iID_Utilisateur_Action_Menant_Annulation IS NOT NULL
                            BEGIN
                                IF @vcCode_Structure_Selection IN ('TI1','TI2')
                                    SET @vcNom_Champs_Retour = 'FirstName,LastName'
                                SET @vcRequete = 'WHERE HumanID = '+CAST(@iID_Utilisateur_Action_Menant_Annulation AS VARCHAR)
                                SET @vcNom_Champs_A_Traduire = NULL

                                EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'Mo_Human','HumanID',
                                                                                          @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue
                            END

                        IF @vcCode_Structure_Selection IS NULL
                            BEGIN
                                -- Obtenir le type d'annulation
                                SET @vcRequete = 'WHERE iID_Type_Annulation = '+CAST(@iID_Type_Annulation AS VARCHAR)
                                SET @vcNom_Champs_A_Traduire = 'vcDescription'

                                EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_TypesAnnulation','iID_Type_Annulation',
                                                                                          @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue

                                -- Obtenir la raison d'annulation

                                SET @vcRequete = 'WHERE iID_Raison_Annulation = '+CAST(@iID_Raison_Annulation AS VARCHAR)
                                SET @vcNom_Champs_A_Traduire = 'vcDescription,tCommentaires_TI'

                                EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_RaisonsAnnulation','iID_Raison_Annulation',
                                                                                          @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue

                                -- Obtenir le statut d'annulation
                                SET @vcRequete = 'WHERE iID_Statut_Annulation = '+CAST(@iID_Statut_Annulation AS VARCHAR)
                                SET @vcNom_Champs_A_Traduire = 'vcDescription'

                                EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblIQEE_StatutsAnnulation','iID_Statut_Annulation',
                                                                                          @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue
                            END
                    END


                -------------------------------------------
                -- Obtenir les données pour une note d'IQÉÉ
                -------------------------------------------

                IF @vcCode_Evenement = 'NOTE'
                    BEGIN
                        -- Obtenir la note
                        IF @vcCode_Structure_Selection IN ('TI1','TI2')
                            SET @vcNom_Champs_Retour = 'tTexte'
                        SET @vcRequete = 'WHERE iID_Note = '+CAST(@iID_Primaire AS VARCHAR)
                        SET @vcNom_Champs_A_Traduire = NULL

                        EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblGENE_Note','iID_Note',
                                                                                  @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue
                    END


                ---------------------------------------------------------
                -- Obtenir les données pour un changement de bénéficiaire
                ---------------------------------------------------------

                IF @vcCode_Evenement LIKE 'BENEF_%'
                    BEGIN
                        -- Obtenir le changement de bénéficiaire
                        IF @vcCode_Structure_Selection IN ('TI1','TI2')
                            SET @vcNom_Champs_Retour = 'vcAutre_Raison_Changement_Beneficiaire,bLien_Frere_Soeur_Avec_Ancien_Beneficiaire,bLien_Sang_Avec_Souscripteur_Initial'
                        SET @vcRequete = 'WHERE iID_Changement_Beneficiaire = '+CAST(@iID_Primaire AS VARCHAR)
                        SET @vcNom_Champs_A_Traduire = NULL

                        EXECUTE dbo.psGENE_ObtenirValeursEnregistrementsTable 'tblCONV_ChangementsBeneficiaire','iID_Changement_Beneficiaire',
                                                                                  @vcNom_Champs_Retour,@vcRequete,@vcNom_Champs_A_Traduire,@cID_Langue
                    END

                IF @bRetourner_Donnees_Brut = 0
                    BEGIN
                        INSERT INTO #tblIQEE_Details
                               (iID_Primaire,iID_Valeur,vcNom_Table,vcNom_Champ,vcType,vcDescription,iID_Enregistrement,vcID_Enregistrement,vcValeur1)
                        SELECT @iID_Primaire,V.iID_Valeur,V.vcNom_Table,V.vcNom_Champ,V.vcType,V.vcDescription,V.iID_Enregistrement,V.vcID_Enregistrement,V.vcValeur
                        FROM #tblGENE_Valeurs V
                        WHERE @iID_Valeur_Maximum IS NULL OR V.iID_Valeur > @iID_Valeur_Maximum

                        SELECT @iID_Valeur_Maximum = MAX(V.iID_Valeur)
                        FROM #tblGENE_Valeurs V
                    END

                -- Sélectionner les 2 événements successivement
                IF @Compteur = 2
                    SET @Compteur = 0
                ELSE
                    IF @Compteur = 1 AND 
                       @bComparaison = 1
                        SET @Compteur = 2
                    ELSE
                        SET @Compteur = 0
            END

        -----------------------------------------------------------------------------------------------------------------------------------------
        --
        -- Si le service ne retourne pas les données brutes, comparer les 2 transactions et sortir les données selon la présentation choisie.
        --
        -----------------------------------------------------------------------------------------------------------------------------------------
        IF @bRetourner_Donnees_Brut = 0
            BEGIN
                ---------------------------------
                -- Regrouper les éléments communs
                ---------------------------------
                DECLARE curIQEE_Details CURSOR LOCAL FAST_FORWARD FOR
                    SELECT DE.iID_Detail_Evenement,DE.iID_Primaire,DE.vcNom_Table,DE.vcNom_Champ,DE.vcValeur1
                    FROM #tblIQEE_Details DE
                    ORDER BY DE.iID_Detail_Evenement

                SET @iID_Reponse_Demande = NULL
                SET @iID_Annulation = NULL
                SET @iID_Erreur = NULL
                SET @iID_Rejet = NULL

                OPEN curIQEE_Details
                FETCH NEXT FROM curIQEE_Details INTO @iID_Detail_Evenement,@iID_Primaire,@vcNom_Table,@vcNom_Champ,@vcValeur
                WHILE @@FETCH_STATUS = 0
                    BEGIN
                        IF @vcNom_Table = 'tblIQEE_ReponsesDemande' AND @vcNom_Champ = 'iID_Reponse_Demande'
                            BEGIN
                                SET @iID_Reponse_Demande = CAST(@vcValeur AS INT)
                                SET @iID_Annulation = NULL
                                SET @iID_Erreur = NULL
                                SET @iID_Rejet = NULL
                            END

                        IF @vcNom_Table = 'tblIQEE_Annulations' AND @vcNom_Champ = 'iID_Annulation'
                            BEGIN
                                SET @iID_Annulation = CAST(@vcValeur AS INT)
                                SET @iID_Reponse_Demande = NULL
                                SET @iID_Erreur = NULL
                                SET @iID_Rejet = NULL
                            END

                        IF @vcNom_Table = 'tblIQEE_Erreurs' AND @vcNom_Champ = 'iID_Erreur'
                            BEGIN
                                SET @iID_Erreur = CAST(@vcValeur AS INT)
                                SET @iID_Reponse_Demande = NULL
                                SET @iID_Annulation = NULL
                                SET @iID_Rejet = NULL
                            END

                        IF @vcNom_Table = 'tblIQEE_Demandes' AND @vcNom_Champ = 'iID_Demande_IQEE'
                            BEGIN
                                SET @iID_Reponse_Demande = NULL
                                SET @iID_Annulation = NULL
                                SET @iID_Erreur = NULL
                                SET @iID_Rejet = NULL
                            END

                        IF @vcNom_Table = 'tblIQEE_Rejets' AND @vcNom_Champ = 'iID_Rejet'
                            BEGIN
                                SET @iID_Rejet = CAST(@vcValeur AS INT)
                                SET @iID_Reponse_Demande = NULL
                                SET @iID_Annulation = NULL
                                SET @iID_Erreur = NULL
                            END

        -- TODO: Traiter les autres types de transaction?

                        UPDATE #tblIQEE_Details
                        SET iID_Reponse_Demande = @iID_Reponse_Demande,
                            iID_Annulation = @iID_Annulation,
                            iID_Erreur = @iID_Erreur,
                            iID_Rejet = @iID_Rejet
                        WHERE iID_Detail_Evenement = @iID_Detail_Evenement

                        FETCH NEXT FROM curIQEE_Details INTO @iID_Detail_Evenement,@iID_Primaire,@vcNom_Table,@vcNom_Champ,@vcValeur
                    END
                CLOSE curIQEE_Details
                DEALLOCATE curIQEE_Details



                ------------------------------
                --
                -- Comparer les 2 transactions
                --
                ------------------------------
                IF @bComparaison = 1
                    BEGIN
                        SELECT @iValeur1 = MIN(V.iID_Valeur)
                        FROM #tblIQEE_Details V
                        WHERE V.iID_Primaire = @iID_Primaire_1

                        SELECT @iValeur2 = MIN(V.iID_Valeur)
                        FROM #tblIQEE_Details V
                        WHERE V.iID_Primaire = @iID_Primaire_2

                        SET @iDifference = @iValeur2-@iValeur1

                        UPDATE DE1
                        SET vcValeur2 = DE2.vcValeur1,
                            bComparaison = 1
                        FROM #tblIQEE_Details DE1
                             JOIN #tblIQEE_Details DE2 ON DE2.iID_Primaire = @iID_Primaire_2
                                                               AND DE2.iID_Valeur = DE1.iID_Valeur+@iDifference
                                                               AND DE2.vcNom_Table = DE1.vcNom_Table
                                                               AND DE2.vcNom_Champ = DE1.vcNom_Champ
                        WHERE DE1.iID_Primaire = @iID_Primaire_1
                          AND DE1.iID_Reponse_Demande IS NULL
                          AND DE1.iID_Annulation IS NULL
                          AND DE1.iID_Erreur IS NULL
                          AND DE1.iID_Rejet IS NULL

                        UPDATE DE1
                        SET vcValeur2 = DE2.vcValeur1,
                            bComparaison = 1
                        FROM #tblIQEE_Details DE1
                             JOIN #tblIQEE_Details DE2 ON DE2.iID_Primaire = @iID_Primaire_1
                                                               AND DE2.iID_Valeur = DE1.iID_Valeur-@iDifference
                                                               AND DE2.vcNom_Table = DE1.vcNom_Table
                                                               AND DE2.vcNom_Champ = DE1.vcNom_Champ
                        WHERE DE1.iID_Primaire = @iID_Primaire_2
                          AND DE1.iID_Reponse_Demande IS NULL
                          AND DE1.iID_Annulation IS NULL
                          AND DE1.iID_Erreur IS NULL
                          AND DE1.iID_Rejet IS NULL
                    END



                -------------------------------------------
                --
                -- Formater les données dans une hiérarchie
                --
                -------------------------------------------

-- TODO: Regrouper ces commandes
                -- Trouver la catégorie de chaque champ
                UPDATE DE
                SET iID_Detail = HD.iID_Detail,
                    vcDescription_Courte = COALESCE(dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoPresentations','vcDescription',HPE.iID_Presentation,NULL,@cID_Langue),
                                                    HPE.vcDescription,
                                                    dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoDetails','vcDescription',HD.iID_Detail,NULL,@cID_Langue),
                                                    HD.vcDescription,
                                                    DE.vcDescription),
                    vcNom_Categorie = COALESCE(dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoPresentations','vcDescription',HPC.iID_Presentation,NULL,@cID_Langue),
                                                HPC.vcDescription,
                                                dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoDetails','vcNom_Categorie',HD.iID_Detail,NULL,@cID_Langue),
                                                HD.vcNom_Categorie,
                                                'Intéterminé')
                FROM #tblIQEE_Details DE
                     JOIN tblIQEE_HistoDetails HD ON HD.vcNom_Table = DE.vcNom_Table
                                                 AND HD.vcNom_Champ = DE.vcNom_Champ
                                                 AND HD.vcCode_Evenement = CASE WHEN DE.iID_Primaire = @iID_Primaire_1 THEN @vcCode_Evenement_1 ELSE @vcCode_Evenement_2 END
                                                 AND HD.bResume = 0
                     LEFT JOIN tblIQEE_HistoPresentations HPE ON HPE.iID_Structure_Historique = @iID_Structure_Historique_Presentation
                                                             AND HPE.vcCode_Type_Info = 'CON'+HD.vcCode_Evenement
                                                             AND HPE.vcNom_Table = HD.vcNom_Table
                                                             AND HPE.vcNom_Champ = HD.vcNom_Champ
                     LEFT JOIN tblIQEE_HistoPresentations HPC ON HPC.iID_Structure_Historique = @iID_Structure_Historique_Presentation
                                                             AND HPC.vcCode_Type_Info = 'CAT'+HD.vcCode_Evenement
                                                             AND HPC.vcNom_Table = HD.vcNom_Table
                                                             AND HPC.vcNom_Champ = HD.vcNom_Champ
                WHERE DE.iID_Reponse_Demande IS NULL
                  AND DE.iID_Annulation IS NULL
                  AND DE.iID_Erreur IS NULL
                  AND DE.iID_Rejet IS NULL


                UPDATE DE
                SET iID_Detail = HD.iID_Detail,
                    vcDescription_Courte = COALESCE(dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoPresentations','vcDescription',HPE.iID_Presentation,NULL,@cID_Langue),
                                                    HPE.vcDescription,
                                                    dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoDetails','vcDescription',HD.iID_Detail,NULL,@cID_Langue),
                                                    HD.vcDescription,
                                                    DE.vcDescription),
                    vcNom_Categorie = COALESCE(dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoPresentations','vcDescription',HPC.iID_Presentation,NULL,@cID_Langue),
                                                HPC.vcDescription,
                                                dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoDetails','vcNom_Categorie',HD.iID_Detail,NULL,@cID_Langue),
                                                HD.vcNom_Categorie,
                                                'Intéterminé')
                FROM #tblIQEE_Details DE
                     JOIN tblIQEE_HistoDetails HD ON HD.vcNom_Table = DE.vcNom_Table
                                                 AND HD.vcNom_Champ = DE.vcNom_Champ
                                                 AND HD.vcCode_Evenement = CASE WHEN DE.iID_Primaire = @iID_Primaire_1 THEN @vcCode_Evenement_1+'-REP' ELSE @vcCode_Evenement_2+'-REP' END
                                                 AND HD.bResume = 0
                     LEFT JOIN tblIQEE_HistoPresentations HPE ON HPE.iID_Structure_Historique = @iID_Structure_Historique_Presentation
                                                             AND HPE.vcCode_Type_Info = 'CON'+HD.vcCode_Evenement
                                                             AND HPE.vcNom_Table = HD.vcNom_Table
                                                             AND HPE.vcNom_Champ = HD.vcNom_Champ
                     LEFT JOIN tblIQEE_HistoPresentations HPC ON HPC.iID_Structure_Historique = @iID_Structure_Historique_Presentation
                                                             AND HPC.vcCode_Type_Info = 'CAT'+HD.vcCode_Evenement
                                                             AND HPC.vcNom_Table = HD.vcNom_Table
                                                             AND HPC.vcNom_Champ = HD.vcNom_Champ
                WHERE DE.iID_Reponse_Demande IS NOT NULL

                UPDATE DE
                SET iID_Detail = HD.iID_Detail,
                    vcDescription_Courte = COALESCE(dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoPresentations','vcDescription',HPE.iID_Presentation,NULL,@cID_Langue),
                                                    HPE.vcDescription,
                                                    dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoDetails','vcDescription',HD.iID_Detail,NULL,@cID_Langue),
                                                    HD.vcDescription,
                                                    DE.vcDescription),
                    vcNom_Categorie = COALESCE(dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoPresentations','vcDescription',HPC.iID_Presentation,NULL,@cID_Langue),
                                                HPC.vcDescription,
                                                dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoDetails','vcNom_Categorie',HD.iID_Detail,NULL,@cID_Langue),
                                                HD.vcNom_Categorie,
                                                'Intéterminé')
                FROM #tblIQEE_Details DE
                     JOIN tblIQEE_HistoDetails HD ON HD.vcNom_Table = DE.vcNom_Table
                                                 AND HD.vcNom_Champ = DE.vcNom_Champ
                                                 AND HD.vcCode_Evenement = CASE WHEN DE.iID_Primaire = @iID_Primaire_1 THEN @vcCode_Evenement_1+'-ANN' ELSE @vcCode_Evenement_2+'-ANN' END
                                                 AND HD.bResume = 0
                     LEFT JOIN tblIQEE_HistoPresentations HPE ON HPE.iID_Structure_Historique = @iID_Structure_Historique_Presentation
                                                             AND HPE.vcCode_Type_Info = 'CON'+HD.vcCode_Evenement
                                                             AND HPE.vcNom_Table = HD.vcNom_Table
                                                             AND HPE.vcNom_Champ = HD.vcNom_Champ
                     LEFT JOIN tblIQEE_HistoPresentations HPC ON HPC.iID_Structure_Historique = @iID_Structure_Historique_Presentation
                                                             AND HPC.vcCode_Type_Info = 'CAT'+HD.vcCode_Evenement
                                                             AND HPC.vcNom_Table = HD.vcNom_Table
                                                             AND HPC.vcNom_Champ = HD.vcNom_Champ
                WHERE DE.iID_Annulation IS NOT NULL

                UPDATE DE
                SET iID_Detail = HD.iID_Detail,
                    vcDescription_Courte = COALESCE(dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoPresentations','vcDescription',HPE.iID_Presentation,NULL,@cID_Langue),
                                                    HPE.vcDescription,
                                                    dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoDetails','vcDescription',HD.iID_Detail,NULL,@cID_Langue),
                                                    HD.vcDescription,
                                                    DE.vcDescription),
                    vcNom_Categorie = COALESCE(dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoPresentations','vcDescription',HPC.iID_Presentation,NULL,@cID_Langue),
                                                HPC.vcDescription,
                                                dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoDetails','vcNom_Categorie',HD.iID_Detail,NULL,@cID_Langue),
                                                HD.vcNom_Categorie,
                                                'Intéterminé')
                FROM #tblIQEE_Details DE
                     JOIN tblIQEE_HistoDetails HD ON HD.vcNom_Table = DE.vcNom_Table
                                                 AND HD.vcNom_Champ = DE.vcNom_Champ
                                                 AND HD.vcCode_Evenement = CASE WHEN DE.iID_Primaire = @iID_Primaire_1 THEN @vcCode_Evenement_1+'-ERR' ELSE @vcCode_Evenement_2+'-ERR' END
                                                 AND HD.bResume = 0
                     LEFT JOIN tblIQEE_HistoPresentations HPE ON HPE.iID_Structure_Historique = @iID_Structure_Historique_Presentation
                                                             AND HPE.vcCode_Type_Info = 'CON'+HD.vcCode_Evenement
                                                             AND HPE.vcNom_Table = HD.vcNom_Table
                                                             AND HPE.vcNom_Champ = HD.vcNom_Champ
                     LEFT JOIN tblIQEE_HistoPresentations HPC ON HPC.iID_Structure_Historique = @iID_Structure_Historique_Presentation
                                                             AND HPC.vcCode_Type_Info = 'CAT'+HD.vcCode_Evenement
                                                             AND HPC.vcNom_Table = HD.vcNom_Table
                                                             AND HPC.vcNom_Champ = HD.vcNom_Champ
                WHERE DE.iID_Erreur IS NOT NULL

                UPDATE DE
                SET iID_Detail = HD.iID_Detail,
                    vcDescription_Courte = COALESCE(dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoPresentations','vcDescription',HPE.iID_Presentation,NULL,@cID_Langue),
                                                    HPE.vcDescription,
                                                    dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoDetails','vcDescription',HD.iID_Detail,NULL,@cID_Langue),
                                                    HD.vcDescription,
                                                    DE.vcDescription),
                    vcNom_Categorie = COALESCE(dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoPresentations','vcDescription',HPC.iID_Presentation,NULL,@cID_Langue),
                                                HPC.vcDescription,
                                                dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoDetails','vcNom_Categorie',HD.iID_Detail,NULL,@cID_Langue),
                                                HD.vcNom_Categorie,
                                                'Intéterminé')
                FROM #tblIQEE_Details DE
                     JOIN tblIQEE_HistoDetails HD ON HD.vcNom_Table = DE.vcNom_Table
                                                 AND HD.vcNom_Champ = DE.vcNom_Champ
                                                 AND HD.vcCode_Evenement = CASE WHEN DE.iID_Primaire = @iID_Primaire_1 THEN @vcCode_Evenement_1+'-REJ' ELSE @vcCode_Evenement_2+'-REJ' END
                                                 AND HD.bResume = 0
                     LEFT JOIN tblIQEE_HistoPresentations HPE ON HPE.iID_Structure_Historique = @iID_Structure_Historique_Presentation
                                                             AND HPE.vcCode_Type_Info = 'CON'+HD.vcCode_Evenement
                                                             AND HPE.vcNom_Table = HD.vcNom_Table
                                                             AND HPE.vcNom_Champ = HD.vcNom_Champ
                     LEFT JOIN tblIQEE_HistoPresentations HPC ON HPC.iID_Structure_Historique = @iID_Structure_Historique_Presentation
                                                             AND HPC.vcCode_Type_Info = 'CAT'+HD.vcCode_Evenement
                                                             AND HPC.vcNom_Table = HD.vcNom_Table
                                                             AND HPC.vcNom_Champ = HD.vcNom_Champ
                WHERE DE.iID_Rejet IS NOT NULL
-- TODO: Regrouper ces commandes

                -- Compléter le nom des catégories
                DECLARE curIQEE_Details CURSOR LOCAL FAST_FORWARD FOR
                    SELECT DE.iID_Detail_Evenement,DE.iID_Primaire,DE.vcNom_Table,DE.vcNom_Champ,DE.vcValeur1,DE.iID_Reponse_Demande
                    FROM #tblIQEE_Details DE
                         JOIN tblIQEE_HistoDetails HD ON HD.iID_Detail = DE.iID_Detail
                                                     AND HD.vcCode_Evenement = CASE WHEN DE.iID_Primaire = @iID_Primaire_1 THEN @vcCode_Evenement_1+'-REP' ELSE @vcCode_Evenement_2+'-REP' END
                    WHERE DE.vcNom_Categorie LIKE '%[Date]%'
                    ORDER BY DE.iID_Detail_Evenement

                -- Boucler les détails
                OPEN curIQEE_Details
                FETCH NEXT FROM curIQEE_Details INTO @iID_Detail_Evenement,@iID_Primaire,@vcNom_Table,@vcNom_Champ,@vcValeur,@iID_Reponse_Demande
                WHILE @@FETCH_STATUS = 0
                    BEGIN
                        IF @vcNom_Table = 'tblIQEE_ReponsesDemande' AND @vcNom_Champ = 'iID_Reponse_Demande'
                            BEGIN
                                SET @dtDate1 = NULL
                                SELECT TOP 1 @dtDate1 = CAST(DE.vcValeur1 AS DATETIME)
                                FROM #tblIQEE_Details DE
                                WHERE DE.iID_Primaire = @iID_Primaire
                                  AND DE.vcNom_Table = 'tblIQEE_Fichiers'
                                  AND DE.vcNom_Champ = 'dtDate_Creation'
                                  AND DE.iID_Reponse_Demande = @iID_Reponse_Demande

                                SET @vcType = NULL
                                SELECT TOP 1 @vcType = DE.vcValeur1
                                FROM #tblIQEE_Details DE
                                WHERE DE.iID_Primaire = @iID_Primaire
                                  AND DE.vcNom_Table = 'tblIQEE_TypesReponse'
                                  AND DE.vcNom_Champ = 'vcDescription'
                                  AND DE.iID_Reponse_Demande = @iID_Reponse_Demande

                                SET @vcJustificationRQ = NULL    
                                SELECT TOP 1 @vcJustificationRQ = DE.vcValeur1
                                FROM #tblIQEE_Details DE
                                WHERE DE.iID_Primaire = @iID_Primaire
                                  AND DE.vcNom_Table = 'tblIQEE_JustificationsRQ'
                                  AND DE.vcNom_Champ = 'vcDescription'
                                  AND DE.iID_Reponse_Demande = @iID_Reponse_Demande
                            END

                        UPDATE #tblIQEE_Details
                        SET vcNom_Categorie = REPLACE(REPLACE(REPLACE(vcNom_Categorie,'[Date]',CONVERT(VARCHAR(10),@dtDate1,120)),'[ - Type]',
                                              CASE WHEN @vcType IS NULL THEN '' ELSE ' - '+@vcType END),'[ - Justification]',
                                              CASE WHEN @vcJustificationRQ IS NULL THEN '' ELSE ' - '+@vcJustificationRQ END)
                        WHERE iID_Detail_Evenement = @iID_Detail_Evenement

                        FETCH NEXT FROM curIQEE_Details INTO @iID_Detail_Evenement,@iID_Primaire,@vcNom_Table,@vcNom_Champ,@vcValeur,@iID_Reponse_Demande
                    END
                CLOSE curIQEE_Details
                DEALLOCATE curIQEE_Details

                DECLARE curIQEE_Details CURSOR LOCAL FAST_FORWARD FOR
                    SELECT DE.iID_Detail_Evenement,DE.iID_Primaire,DE.vcNom_Table,DE.vcNom_Champ,DE.vcValeur1,DE.iID_Annulation
                    FROM #tblIQEE_Details DE
                         JOIN tblIQEE_HistoDetails HD ON HD.iID_Detail = DE.iID_Detail
                                                     AND HD.vcCode_Evenement = CASE WHEN DE.iID_Primaire = @iID_Primaire_1 THEN @vcCode_Evenement_1+'-ANN' ELSE @vcCode_Evenement_2+'-ANN' END
                    WHERE DE.vcNom_Categorie LIKE '%[Date]%'
                    ORDER BY DE.iID_Detail_Evenement

                SET @dtDate1 = NULL
                SET @vcType = NULL

                -- Boucler les détails
                OPEN curIQEE_Details
                FETCH NEXT FROM curIQEE_Details INTO @iID_Detail_Evenement,@iID_Primaire,@vcNom_Table,@vcNom_Champ,@vcValeur,@iID_Annulation
                WHILE @@FETCH_STATUS = 0
                    BEGIN
                        IF @vcNom_Table = 'tblIQEE_Annulations' AND @vcNom_Champ = 'iID_Annulation'
                            BEGIN
                                SET @dtDate1 = NULL
                                SELECT TOP 1 @dtDate1 = CAST(DE.vcValeur1 AS DATETIME)
                                FROM #tblIQEE_Details DE
                                WHERE DE.iID_Primaire = @iID_Primaire
                                  AND DE.vcNom_Table = 'tblIQEE_Annulations'
                                  AND DE.vcNom_Champ = 'dtDate_Demande_Annulation'
                                  AND DE.iID_Annulation = @iID_Annulation

                                SET @vcType = NULL
                                SELECT TOP 1 @vcType = DE.vcValeur1
                                FROM #tblIQEE_Details DE
                                WHERE DE.iID_Primaire = @iID_Primaire
                                  AND DE.vcNom_Table = 'tblIQEE_RaisonsAnnulation'
                                  AND DE.vcNom_Champ = 'vcDescription'
                                  AND DE.iID_Annulation = @iID_Annulation
                            END

                        UPDATE #tblIQEE_Details
                        SET vcNom_Categorie = REPLACE(REPLACE(vcNom_Categorie,'[Date]',CONVERT(VARCHAR(10),@dtDate1,120)),'[ - Raison]',
                                              CASE WHEN @vcType IS NULL THEN '' ELSE ' - '+@vcType END)
                        WHERE iID_Detail_Evenement = @iID_Detail_Evenement

                        FETCH NEXT FROM curIQEE_Details INTO @iID_Detail_Evenement,@iID_Primaire,@vcNom_Table,@vcNom_Champ,@vcValeur,@iID_Annulation
                    END
                CLOSE curIQEE_Details
                DEALLOCATE curIQEE_Details

                DECLARE curIQEE_Details CURSOR LOCAL FAST_FORWARD FOR
                    SELECT DE.iID_Detail_Evenement,DE.iID_Primaire,DE.vcNom_Table,DE.vcNom_Champ,DE.vcValeur1,DE.iID_Erreur
                    FROM #tblIQEE_Details DE
                         JOIN tblIQEE_HistoDetails HD ON HD.iID_Detail = DE.iID_Detail
                                                     AND HD.vcCode_Evenement = CASE WHEN DE.iID_Primaire = @iID_Primaire_1 THEN @vcCode_Evenement_1+'-ERR' ELSE @vcCode_Evenement_2+'-ERR' END
                    WHERE DE.vcNom_Categorie LIKE '%[Date]%'
                    ORDER BY DE.iID_Detail_Evenement

                SET @dtDate1 = NULL
                SET @vcType = NULL

                -- Boucler les détails
                OPEN curIQEE_Details
                FETCH NEXT FROM curIQEE_Details INTO @iID_Detail_Evenement,@iID_Primaire,@vcNom_Table,@vcNom_Champ,@vcValeur,@iID_Erreur
                WHILE @@FETCH_STATUS = 0
                    BEGIN
                        IF @vcNom_Table = 'tblIQEE_Erreurs' AND @vcNom_Champ = 'iID_Erreur'
                            BEGIN
                                SET @dtDate1 = NULL
                                SELECT TOP 1 @dtDate1 = CAST(DE.vcValeur1 AS DATETIME)
                                FROM #tblIQEE_Details DE
                                WHERE DE.iID_Primaire = @iID_Primaire
                                  AND DE.vcNom_Table = 'tblIQEE_Fichiers'
                                  AND DE.vcNom_Champ = 'dtDate_Creation'
                                  AND DE.iID_Erreur = @iID_Erreur

                                SET @vcType = NULL
                                SELECT TOP 1 @vcType = DE.vcValeur1
                                FROM #tblIQEE_Details DE
                                WHERE DE.iID_Primaire = @iID_Primaire
                                  AND DE.vcNom_Table = 'tblIQEE_TypesErreurRQ'
                                  AND DE.vcNom_Champ = 'vcDescription'
                                  AND DE.iID_Erreur = @iID_Erreur
                            END

                        UPDATE #tblIQEE_Details
                        SET vcNom_Categorie = REPLACE(REPLACE(vcNom_Categorie,'[Date]',CONVERT(VARCHAR(10),@dtDate1,120)),'[Erreur]',
                                              CASE WHEN @vcType IS NULL THEN '' ELSE @vcType END)
                        WHERE iID_Detail_Evenement = @iID_Detail_Evenement

                        FETCH NEXT FROM curIQEE_Details INTO @iID_Detail_Evenement,@iID_Primaire,@vcNom_Table,@vcNom_Champ,@vcValeur,@iID_Erreur
                    END
                CLOSE curIQEE_Details
                DEALLOCATE curIQEE_Details

                DECLARE curIQEE_Details CURSOR LOCAL FAST_FORWARD FOR
                    SELECT DE.iID_Detail_Evenement,DE.iID_Primaire,DE.vcNom_Table,DE.vcNom_Champ,DE.vcValeur1,DE.iID_Rejet
                    FROM #tblIQEE_Details DE
                         JOIN tblIQEE_HistoDetails HD ON HD.iID_Detail = DE.iID_Detail
                                                     AND HD.vcCode_Evenement = CASE WHEN DE.iID_Primaire = @iID_Primaire_1 THEN @vcCode_Evenement_1+'-REJ' ELSE @vcCode_Evenement_2+'-REJ' END
                    WHERE DE.vcNom_Categorie LIKE '%[Rejet]%'
                    ORDER BY DE.iID_Detail_Evenement

                SET @dtDate1 = NULL
                SET @vcType = NULL

                -- Boucler les détails
                OPEN curIQEE_Details
                FETCH NEXT FROM curIQEE_Details INTO @iID_Detail_Evenement,@iID_Primaire,@vcNom_Table,@vcNom_Champ,@vcValeur,@iID_Rejet
                WHILE @@FETCH_STATUS = 0
                    BEGIN
                        IF @vcNom_Table = 'tblIQEE_Rejets' AND @vcNom_Champ = 'iID_Rejet'
                            BEGIN
                                SET @vcType = NULL
                                SELECT TOP 1 @vcType = DE.vcValeur1
                                FROM #tblIQEE_Details DE
                                WHERE DE.iID_Primaire = @iID_Primaire
                                  AND DE.vcNom_Table = 'tblIQEE_Rejets'
                                  AND DE.vcNom_Champ = 'vcDescription'
                                  AND DE.iID_Rejet = @iID_Rejet
                            END

                        UPDATE #tblIQEE_Details
                        SET vcNom_Categorie = REPLACE(vcNom_Categorie,'[Rejet]',CASE WHEN @vcType IS NULL THEN '' ELSE @vcType END)
                        WHERE iID_Detail_Evenement = @iID_Detail_Evenement

                        FETCH NEXT FROM curIQEE_Details INTO @iID_Detail_Evenement,@iID_Primaire,@vcNom_Table,@vcNom_Champ,@vcValeur,@iID_Rejet
                    END
                CLOSE curIQEE_Details
                DEALLOCATE curIQEE_Details

-- TODO: Traiter les autres types de transaction



                -------------------------------------------------------------------------------------------
                --
                -- Retourner les données selon la présentation si c'est pour la consultation d'un événement
                --
                -------------------------------------------------------------------------------------------
--                CREATE TABLE #tblIQEE_Details(
--                    iID_Detail_Evenement INT IDENTITY(1,1) NOT NULL, 
--                    iID_Primaire INT,
--                    iID_Valeur INT,
--                    vcNom_Table VARCHAR(150),
--                    vcNom_Champ VARCHAR(150),
--                    vcType VARCHAR(150),
--                    vcDescription VARCHAR(MAX),
--                    iID_Enregistrement INT,
--                    vcID_Enregistrement VARCHAR(15),
--                    vcValeur1 VARCHAR(MAX),
--                    vcValeur2 VARCHAR(MAX),
--                    bComparaison BIT,
--                    iID_Detail INT,    
--                    vcNom_Categorie VARCHAR(200))

--
--iID_Detail
--bResume
--vcCode_Evenement
--vcNom_Table
--vcNom_Champ
--vcDescription
--tCommentaires_Utilisateur
--cAlignement
--vcNom_Categorie

-- TODO: Enlever
--                SELECT *
--                FROM #tblIQEE_Details DE
--                ORDER BY DE.iID_Detail_Evenement
--
--                SELECT CASE WHEN DE.iID_Primaire = @iID_Primaire_1 THEN 'Transaction 1' ELSE 'Transaction 2' END AS vcTransaction,
--                        DE.vcNom_Categorie,
--                        DE.vcDescription_Courte,
--                        DE.vcValeur1,
--                        DE.vcValeur2,
--                        DE.bComparaison
--                FROM #tblIQEE_Details DE
--                     JOIN tblIQEE_HistoDetails HD ON HD.iID_Detail = DE.iID_Detail
--                ORDER BY vcTransaction,HD.vcCode_Evenement,HD.iOrdre_Presentation_Categorie,DE.vcNom_Categorie,HD.iOrdre_Presentation_Champ,DE.iID_Detail_Evenement

                -- Structure de présentation
                SELECT SP.iNiveau,
                       SP.bOuverture_Niveau,
                       SP.vcNom_Colonne,
                       SP.bID_Niveau,
                       SP.bID_Niveau_Precedent,
                       SP.bAfficher,
                       COALESCE(dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoStructurePresentation','vcTitre_Colonne',SP.iID_Structure_Presentation,NULL,@cID_Langue),
                                SP.vcTitre_Colonne) AS vcTitre_Colonne,
                       SP.vcType_Donnee,
                       SP.cAlignement,
                       SP.iLargeur_Colonne,
                       SP.bAfficher_Total
                FROM tblIQEE_HistoStructurePresentation SP
                WHERE SP.iID_Structure_Historique = @iID_Structure_Historique_Presentation
                  AND SP.cCode_Structure = CASE WHEN @bComparaison =  0 THEN 'V' ELSE 'C' END
                ORDER BY SP.iNiveau,SP.iOrdre_Presentation

                CREATE TABLE #tblIQEE_Categories(
                    iID_Categorie INT IDENTITY(1,1) NOT NULL, 
                    iID_Transaction INT,
                    vcTransaction VARCHAR(20),
                    iID_Primaire INT,
                    vcNom_Categorie VARCHAR(200),
                    iOrdre_Presentation_Categorie INT)

                IF @bComparaison = 1
                    BEGIN
                        INSERT INTO #tblIQEE_Categories
                            (iID_Transaction,vcTransaction,iID_Primaire,iOrdre_Presentation_Categorie,vcNom_Categorie)
                        SELECT DISTINCT 
                               CASE WHEN DE.iID_Primaire = @iID_Primaire_1 THEN 1 ELSE 2 END,
                               CASE WHEN DE.iID_Primaire = @iID_Primaire_1 THEN 'Transaction #1' ELSE 'Transaction #2' END,
                               DE.iID_Primaire,
                               HD.iOrdre_Presentation_Categorie,
                               DE.vcNom_Categorie
                        FROM #tblIQEE_Details DE
                             JOIN tblIQEE_HistoDetails HD ON HD.iID_Detail = DE.iID_Detail
                        ORDER BY CASE WHEN DE.iID_Primaire = @iID_Primaire_1 THEN 1 ELSE 2 END,HD.iOrdre_Presentation_Categorie,DE.vcNom_Categorie

                        -- Niveau #1: Transactions
                        SELECT DISTINCT
                               C.iID_Transaction,
                               C.vcTransaction
                        FROM #tblIQEE_Categories C
                        ORDER BY C.iID_Transaction

                        -- Niveau #2: Catégories
                        SELECT  C.iID_Transaction,
                                C.iID_Categorie,
                                C.vcNom_Categorie
                        FROM #tblIQEE_Categories C
                        ORDER BY C.iID_Transaction,C.iID_Categorie

                        -- Niveau #3: Informations
                        SELECT  C.iID_Categorie,
                                DE.iID_Detail_Evenement,
                                DE.vcDescription_Courte,
                                DE.vcDescription AS vcDescription_Courte_InfoBulle,
                                DE.vcValeur1,
                                DE.vcValeur1 AS vcValeur1_InfoBulle,
                                DE.vcValeur2,
                                DE.vcValeur2 AS vcValeur2_InfoBulle,
                                CASE WHEN ((DE.vcValeur1 <> DE.vcValeur2) OR
                                          (DE.vcValeur1 IS NULL AND DE.vcValeur2 IS NOT NULL) OR
                                          (DE.vcValeur1 IS NOT NULL AND DE.vcValeur2 IS NULL))
                                        AND DE.bComparaison = 1
                                     THEN 'B9121B' ELSE NULL END AS vcValeur2_vcCouleur_Fond,
                                CASE WHEN ((DE.vcValeur1 <> DE.vcValeur2) OR
                                          (DE.vcValeur1 IS NULL AND DE.vcValeur2 IS NOT NULL) OR
                                          (DE.vcValeur1 IS NOT NULL AND DE.vcValeur2 IS NULL))
                                        AND DE.bComparaison = 1
                                     THEN '000000' ELSE NULL END AS vcValeur2_vcCouleur_Texte
                        FROM #tblIQEE_Details DE
                             JOIN tblIQEE_HistoDetails HD ON HD.iID_Detail = DE.iID_Detail
                             JOIN #tblIQEE_Categories C ON C.iID_Primaire = DE.iID_Primaire
                                                       AND C.vcNom_Categorie = DE.vcNom_Categorie
                        ORDER BY C.iID_Transaction,C.iID_Categorie,HD.iOrdre_Presentation_Champ,DE.iID_Detail_Evenement
                    END
                ELSE
                    BEGIN
                        INSERT INTO #tblIQEE_Categories
                            (iOrdre_Presentation_Categorie,vcNom_Categorie)
                        SELECT DISTINCT HD.iOrdre_Presentation_Categorie,DE.vcNom_Categorie
                        FROM #tblIQEE_Details DE
                             JOIN tblIQEE_HistoDetails HD ON HD.iID_Detail = DE.iID_Detail
                        ORDER BY HD.iOrdre_Presentation_Categorie,DE.vcNom_Categorie

                        -- Niveau #1: Catégories
                        SELECT DISTINCT C.iID_Categorie,C.vcNom_Categorie
                        FROM #tblIQEE_Categories C
                        ORDER BY C.iID_Categorie

                        -- Niveau #2: Informations
                        SELECT  C.iID_Categorie,
                                DE.iID_Detail_Evenement,
                                DE.vcDescription_Courte,
                                DE.vcDescription AS vcDescription_Courte_InfoBulle,
                                DE.vcValeur1,
                                DE.vcValeur1 AS vcValeur1_InfoBulle
                        FROM #tblIQEE_Details DE
                             JOIN tblIQEE_HistoDetails HD ON HD.iID_Detail = DE.iID_Detail
                             JOIN #tblIQEE_Categories C ON C.vcNom_Categorie = DE.vcNom_Categorie
                        ORDER BY C.iID_Categorie,HD.iOrdre_Presentation_Champ,DE.iID_Detail_Evenement
                    END

                DROP TABLE #tblIQEE_Categories
                DROP TABLE #tblIQEE_Details
            END
    END TRY
    BEGIN CATCH
        -- Lever l'erreur et faire le rollback
        DECLARE @ErrorMessage NVARCHAR(max) = ERROR_MESSAGE() + char(13) + char(10) + ' (Proc: ' + ERROR_PROCEDURE() + ' - Line: ' + LTrim(Str(ERROR_LINE())) + ')',
                @ErrorSeverity INT = ERROR_SEVERITY(),
                @ErrorState INT  =ERROR_STATE(),
                @ErrorLine int = ERROR_LINE()

        SET @ErrorMessage += CHAR(13) + CHAR(10) + ' nStep : ' + STR(@nStep, 1)

        RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState) WITH LOG;

        -- Retourner -1 en cas d'erreur non prévisible de traitement
        RETURN -1
    END CATCH

    -- Retourner 1 lors de la réussite du traitement
    RETURN 1
END
