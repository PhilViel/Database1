/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service        : psIQEE_ImporterFichierReponses
Nom du service        : Importer un fichier de réponses
But                 : Importer et traiter un fichier physique de réponses de Revenu Québec dans le module de l'IQÉÉ.
Facette                : IQÉÉ

Paramètres d’entrée    :    Paramètre                    Description
                        --------------------------    -----------------------------------------------------------------
                        bExecution_Differee            Indicateur que les paramètres d’appel du service sont présent dans
                                                    les paramètres applicatifs.  Ce paramètre est requis.  S’il est
                                                    égal à 0, les paramètres passés sont considérés être les paramètres
                                                    du service.  S’il est égal à 1, les paramètres passés sont ignorés
                                                    et les paramètres sont lus directement du système des paramètres
                                                    applicatifs.
                        vcChemin_Fichier            Chemin du répertoire dans lequel se trouve le fichier physique de
                                                    réponses à importer.
                        vcNom_Fichier                Nom du fichier physique de réponses à importer.
                        iID_Utilisateur_Creation    Identifiant de l’utilisateur qui demande l'importation du fichier 
                                                    physique.  S’il est absent, considérer l’utilisateur système.
                        vcCourrielsDestination        Liste des courriels qui devront recevoir un courriel de confirmation du
                                                    résultat du traitement.  S’il n’est pas spécifié, il n'y aura pas
                                                    de courriel.
                        cID_Langue                    Langue du traitement.  Le français est considéré par défaut s'il n'est
                                                    pas spécifié.

Exemple d’appel        :    EXECUTE [dbo].[psIQEE_ImporterFichierReponses] 0, '\\gestas2\departements\IQEE\Fichiers\Reçus\',
                                                                       'P11412491782009032617280720090717132854.err',519626,
                                                                       'eric.deshaies@universitas.ca', NULL

Paramètres de sortie:    Table                        Champ                            Description
                          -------------------------    ---------------------------     ---------------------------------
                        S/O                            iCode_Retour                    >0 = Traitement terminé normalement,
                                                                                         nombre de fichiers logiques crées.
                                                                                    -1 = Erreur non prévue par la
                                                                                         programmation (voir le rapport
                                                                                         d'importation)
                                                                                    -2 = Erreur prévue par la programmation
                                                                                         (voir le rapport d'importation)

Historique des modifications:
    Date        Programmeur                 Description                                
    ----------  ------------------------    -----------------------------------------
    2009-05-12  Éric Deshaies               Création du service                            
    2012-09-19  Stéphane Barbeau            Activation traitement des T03 et T06
    2012-11-07  Stéphane Barbeau            Assignation de l'année fiscale lors de l'appel de l'importation des fichiers .COT
    2012-11-28  Stéphane Barbeau            Ajout du paramètre @iID_Utilisateur_Creation dans l'appel de psIQEE_ImporterFichierERR
    2014-05-22  Stéphane Barbeau            Fichiers COT: Ajout du traitement des avis fictifs 
    2014-06-27  Stéphane Barbeau            Désactivation du code mentionnant les RIO dans le rapport de traitement des fichiers .PRO, .NOU et .COT
    2015-11-11  Stéphane Barbeau            Résolution problème importation .ERR: IF @vcCode_Type_Fichier = 'PRO' OR @vcCode_Type_Fichier = 'NOU'
    2016-03-01  Steeve Picard               Ajout du paramètre « iSequence » de la procédure « psIQEE_AjouterLigneFichier »
    2016-03-29  Stephane Roussel            Enlever l'année fiscale du nom de fichier de type ERR (changer le parsing du nom de fichier en consequence)
    2016-05-02  Steeve Picard               Met à jour les statuts des transferts qui sont en attente concernant qui ne sont pas en erreur «psIQEE_SimulerReponseTransfert»
    2017-08-17  Steeve Picard               Permettre de importer à nouveau un fichier d'erreur
    2018-02-08  Steeve Picard               Déplacement de «siAnnee_Fiscale» de la table «tblIQEE_Fichiers» vers les tables d'évèments
    2018-03-16  Steeve Picard               Correctif pour associer les fichiers réponses à ceux de déclarations
    2018-05-02  Steeve Picard               L'identifiant du fiduciaire (NEQ) est maintenant traité comme un numérique par RQ
    2018-05-09  Steeve Picard               Ajout des nouveaux fichiers «REM, TRA & PAE» pour les transactions «T53, T54 & T55»
                                            Élimination de la procédure «psIQEE_SimulerReponseTransfert» vu les réponses «T54»
    2018-05-17  Steeve Picard               Ajout du montant total d'impôt spécial en erreur dans le courriel 
    2018-10-31  Steeve Picard               Reformatage
***********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_ImporterFichierReponses]
(
    @bExecution_Differee BIT,
    @vcChemin_Fichier VARCHAR(150),
    @vcNom_Fichier VARCHAR(50),
    @iID_Utilisateur_Creation INT,
    @vcCourrielsDestination VARCHAR(200),
    @cID_Langue CHAR(3)
)
AS
BEGIN
    SET NOCOUNT ON  

    ------------------
    -- Initialisations
    ------------------
    DECLARE @bDejaCreer_RapportImportation bit = 0,
            @iNEQ_GUI INT = (SELECT CAST(vcNEQ_GUI AS INTEGER) FROM dbo.Un_Def)

    -- Créer une table temporaire pour le rapport d'importation 
    IF OBJECT_ID('tempdb..##tblIQEE_RapportImportation') IS NULL
        CREATE TABLE ##tblIQEE_RapportImportation (
                cSection CHAR(1) NOT NULL,
                iSequence INT NOT NULL,
                vcMessage VARCHAR(max) NOT NULL
            )
    ELSE
        SET @bDejaCreer_RapportImportation = 1

    TRUNCATE TABLE ##tblIQEE_RapportImportation

    BEGIN TRY

        -- Déclarations des variables locales
        DECLARE @vcNom_Rapport_Importation VARCHAR(200),
                @iID_Fichier_IQEE INT,
                @vcCode_Type_Fichier VARCHAR(3),
                @bIndicateur_Erreur_Grave BIT,
                @dtDebut_Importation DATETIME,
                @iNombre_Erreur INT,
                @vcMessage VARCHAR(MAX),
                @vcSujet VARCHAR(MAX),
                @iNB1 INT,
                @iNB2 INT,
                @vcTMP VARCHAR(200),
                @dtDate_Paiement_Courriel DATETIME,
                @mMontant_Total_Paiement_Courriel MONEY,
                @mMontant_Total_A_Payer_Courriel MONEY,
                @mSolde_Avis_Fictif MONEY,
                @siAnnee_Fiscale SMALLINT,
                @tiID_Type_Fichier TINYINT,
                @tiID_Statut_Fichier TINYINT,
                @bFichier_Test BIT,
                @dtDate_Creation DATETIME,
                @dtDate_Traitement_RQ DATETIME,
                @vcDate_Traitement_RQ varchar(20),
                @iID_Lien_Fichier_IQEE_Demande INT,
                @vcDescription_Type_Fichier VARCHAR(100),
                @iResultat INT,
                @vcResultat VARCHAR(1000),
                @vcLigne NVARCHAR(max),
                @iCompteur INT,
                @bAvertissements BIT,
                @vcCode_Type_Fichier_Origine VARCHAR(3),
                @iCompte_Erreur INT,
                @iCompte_Reponse INT,
                @iCompte_Attente INT,
                @bInd_Erreur BIT,
                @iCode_Retour INT,
                @iNB_Enregistrement_Sommaire INT,
                @vcCode_Message VARCHAR(10),
                @iCode_Retour_RIO INT,
                @mSolde_Impots MONEY

        DECLARE @tblIQEE_RapportImportationTMP TABLE (
                    cSection CHAR(1),
                    iSequence INT,
                    vcMessage VARCHAR(2000)
                );

        IF OBJECT_ID('tempdb..#tblTMP') IS NOT NULL
            DROP TABLE #tblTMP
        CREATE TABLE #tblTMP (
            iSequence int IDENTITY(1,1), 
            vcLigne VARCHAR(255),
            CONSTRAINT PK_IQEE_ImporterFichierReponses_tblTMP PRIMARY KEY CLUSTERED (iSequence)
        )

        IF OBJECT_ID('tempdb..#tblIQEE_Fichiers_Demandes') IS NOT NULL
            DROP TABLE #tblIQEE_Fichiers_Demandes
        CREATE TABLE #tblIQEE_Fichiers_Demandes (
            iID_Lien_Fichier_IQEE_Demande INT NOT NULL,
            iNB_Transactions INT NOT NULL
        )

        -- Initialisations de variables
        SET @dtDate_Paiement_Courriel = NULL
        SET @mMontant_Total_Paiement_Courriel = 0
        SET @mMontant_Total_A_Payer_Courriel = 0
        SET @mSolde_Avis_Fictif = 0
        SET @iCode_Retour = 0

        ------------------------------------
        -- Valider et ajuster les paramètres
        ------------------------------------

        -- Lors d'une exécution en différée (asynchrone) via l’interface utilisateur, prendre les paramètres du service dans les
        -- paramètres applicatifs
        IF @bExecution_Differee = 1
            SELECT @vcChemin_Fichier = dbo.fnGENE_ObtenirParametre('IQEE_IMPORTER_FICHIER_vcChemin_Fichier', NULL,NULL,NULL,NULL,NULL,NULL),
                   @vcNom_Fichier = dbo.fnGENE_ObtenirParametre('IQEE_IMPORTER_FICHIER_vcNom_Fichier', NULL,NULL,NULL,NULL,NULL,NULL),
                   @vcCourrielsDestination = dbo.fnGENE_ObtenirParametre('IQEE_IMPORTER_FICHIER_vcCourrielsDestination', NULL,NULL,NULL,NULL,NULL,NULL),
                   @iID_Utilisateur_Creation = CAST(dbo.fnGENE_ObtenirParametre('IQEE_IMPORTER_FICHIER_iID_Utilisateur_Creation', NULL,NULL,NULL,NULL,NULL,NULL) AS INT),
                   @cID_Langue = dbo.fnGENE_ObtenirParametre('IQEE_IMPORTER_FICHIER_cID_Langue',NULL,NULL,NULL,NULL,NULL,NULL)

        -- Trimmer le chemin et le nom du fichier
        SET @vcChemin_Fichier = RTRIM(LTRIM(@vcChemin_Fichier))
        SET @vcNom_Fichier = RTRIM(LTRIM(@vcNom_Fichier))

        -- Compléter le chemin du fichier
        IF SUBSTRING(@vcChemin_Fichier,LEN(@vcChemin_Fichier),1) <> '\'
            SET @vcChemin_Fichier = @vcChemin_Fichier + '\'

        -- Définir le nom du rapport d'importation
        SET @vcNom_Rapport_Importation = @vcChemin_Fichier+REPLACE(@vcNom_Fichier,'.','')+'.txt'

        -- Retenir l'heure du début de l'importation
        SET @dtDebut_Importation = GETDATE()

        -- Prendre l'utilisateur du système s'il est absent en paramètre ou inexistant
        IF @iID_Utilisateur_Creation IS NULL OR
           NOT EXISTS (SELECT * FROM Mo_User WHERE UserID = @iID_Utilisateur_Creation) 
            SELECT TOP 1 @iID_Utilisateur_Creation = iID_Utilisateur_Systeme
            FROM Un_Def

        -- Considérer le français comme langue de défaut
        IF @cID_Langue IS NULL
            SET @cID_Langue = 'FRA'

        -- Préparer les entêtes du rapport d'importation
        SELECT @vcTMP = FirstName + ' ' + LastName
          FROM dbo.Mo_Human 
         WHERE HumanID = @iID_Utilisateur_Creation

        INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
              SELECT '1',1,'-----------------------------------------------------------------'
        UNION SELECT '1',2,'RAPPORT D''IMPORTATION D''UN FICHIER DE RÉPONSES DE REVENU QUÉBEC'
        UNION SELECT '1',3,'-----------------------------------------------------------------'
        UNION SELECT '1',4,' '
        UNION SELECT '1',5,'Paramètres:'
        UNION SELECT '1',6,'       Répertoire: '+@vcChemin_Fichier
        UNION SELECT '1',7,'       Nom du fichier: '+@vcNom_Fichier
        UNION SELECT '1',8,'       Demandé par: '+@vcTMP+' ('+CAST(@iID_Utilisateur_Creation AS VARCHAR)+')'
        UNION SELECT '1',9,'       Serveur SQL: '+@@servername
        UNION SELECT '1',10,'       Base de données: '+DB_NAME()
        UNION SELECT '2',1,' '
        UNION SELECT '2',2,'Messages:'
        UNION SELECT '3',1,' '
        UNION SELECT '3',2,'Traces:'
        UNION SELECT '3',3,'       Début du traitement: '+CONVERT(VARCHAR(25),@dtDebut_Importation,121)

        -- Initialisation de variables
        SET @bIndicateur_Erreur_Grave = 0
        SET @iID_Fichier_IQEE = 0

        -- Valider les paramètres
        IF ISNULL(@vcChemin_Fichier, '') = '' OR ISNULL(@vcNom_Fichier, '') = ''
        BEGIN
            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('2',10,'       Erreur: Le répertoire et le nom du fichier sont requis dans les paramètres d''entrées.')

            GOTO ERREUR_TRAITEMENT
        END

        -- Déterminer et valider le type de fichier physique de réponses
        SET @vcCode_Type_Fichier = UPPER(SUBSTRING(@vcNom_Fichier,LEN(@vcNom_Fichier)-2,3))

        IF NOT EXISTS (SELECT * FROM tblIQEE_TypesFichier TF WHERE TF.vcCode_Type_Fichier = @vcCode_Type_Fichier)
        BEGIN
            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('2',10,'       Erreur: Le type du fichier physique (extension) à importer est non reconnu par le programme d''importation.')

            GOTO ERREUR_TRAITEMENT
        END

    --    IF UPPER(SUBSTRING(@vcNom_Fichier,1,1)) = 'T'
    --        BEGIN
    --             INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
    --            VALUES ('2',10,'       Erreur: Les fichiers test ne peuvent pas être importés.  Hors conception de l''IQÉÉ.'+
    --                           '  Développements requis.')
    --
    --            GOTO ERREUR_TRAITEMENT
    --        END

        SELECT @vcDescription_Type_Fichier = TF.vcDescription
          FROM tblIQEE_TypesFichier TF
         WHERE TF.vcCode_Type_Fichier = @vcCode_Type_Fichier

        ------------------------------
        -- Créer les fichiers logiques
        ------------------------------

        INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
        VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_ImporterFichierReponses     - '+
                'Créer les fichiers logiques.')

        -- Créer une table temporaire des nouveaux fichiers logiques
        CREATE TABLE #tblIQEE_Fichiers_Logiques (
            siAnnee_Fiscale SMALLINT NOT NULL PRIMARY KEY,
            iID_Lien_Fichier_IQEE_Demande INT NULL,
            iID_Fichier_IQEE INTEGER NULL
        )

        DECLARE @bFichier_DejaCharger BIT = 0

        -- Vérifier si le fichier physique à déjà été importé
        IF EXISTS (SELECT * FROM tblIQEE_Fichiers F WHERE UPPER(F.vcNom_Fichier) = UPPER(@vcNom_Fichier))
        BEGIN
            PRINT ' *** Fichier existant déjà dans la BD'

            IF RIGHT(@vcNom_Fichier, 4) = '.err'
            BEGIN
                SELECT @iID_Fichier_IQEE = MAX(F.iID_Fichier_IQEE) FROM dbo.tblIQEE_Fichiers F WHERE UPPER(F.vcNom_Fichier) = UPPER(@vcNom_Fichier)
                IF EXISTS(SELECT * FROM dbo.tblIQEE_LignesFichier LF WHERE LF.iID_Fichier_IQEE = @iID_Fichier_IQEE)
                BEGIN 
                    PRINT '   *** Déjà importé auparavant ***'
                    SET @bFichier_DejaCharger = 1
                    --DELETE FROM dbo.tblIQEE_LignesFichier WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE
                END
                ELSE
                    PRINT '   *** Déjà importé vide auparavant ***'
            END 
            ELSE
            BEGIN
                PRINT '   *** FAILED - déjà importé ***'
                INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
                VALUES ('2',10,'       Erreur: Le fichier physique à importer a déjà été importé.')

                GOTO ERREUR_TRAITEMENT
            END
        END

        -- Vérifier l'existence du fichier physique
        SELECT @vcChemin_Fichier,@vcNom_Fichier
        EXECUTE @iResultat = dbo.psGENE_FichierRepertoireExiste @vcChemin_Fichier,@vcNom_Fichier
        IF @iResultat <> 3
        BEGIN
            PRINT ' *** Erreur: Le fichier physique à importer n''existe pas ou est inaccessible'
            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('2',10,'       Erreur: Le fichier physique à importer n''existe pas ou est inaccessible.')

            GOTO ERREUR_TRAITEMENT
        END

        PRINT 'Importer le fichier physique dans une table temporaire.'

        ---------------------------------------------------------
        -- Importer le fichier physique dans une table temporaire
        ---------------------------------------------------------
        INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
        VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_ImporterFichierReponses     - '+
                'Importer le fichier physique dans une table temporaire.')

        SET @vcResultat = 'Exec Master..xp_Cmdshell ''TYPE '+@vcChemin_Fichier+@vcNom_Fichier+''''
        INSERT INTO #tblTMP EXEC (@vcResultat) 

        -- Déterminer les années fiscales touchées par le fichier de réponses physique
        INSERT INTO #tblIQEE_Fichiers_Logiques (siAnnee_Fiscale)
        SELECT DISTINCT CAST(SUBSTRING(T.vcLigne,3,4) AS SMALLINT)
          FROM #tblTMP T, Un_Def D
         WHERE SUBSTRING(T.vcLigne,1,2) IN ('12','22','32','42','43')
               AND dbo.fnIQEE_DeformaterChamp(SUBSTRING(T.vcLigne,7,10), '9', 10, 0) = @iNEQ_GUI
               AND SUBSTRING(T.vcLigne,3,4) <> '0000'
        UNION
        SELECT DISTINCT CAST(SUBSTRING(T.vcLigne,54,4) AS SMALLINT)
          FROM #tblTMP T, Un_Def D
         WHERE SUBSTRING(T.vcLigne,1,2) IN ('53')
               AND dbo.fnIQEE_DeformaterChamp(SUBSTRING(T.vcLigne,19,10), '9', 10, 0) = @iNEQ_GUI
               AND SUBSTRING(T.vcLigne,54,4) <> '0000'
        UNION
        SELECT DISTINCT CAST(SUBSTRING(T.vcLigne,56,4) AS SMALLINT)
          FROM #tblTMP T, Un_Def D
         WHERE SUBSTRING(T.vcLigne,1,2) IN ('54','55')
               AND dbo.fnIQEE_DeformaterChamp(SUBSTRING(T.vcLigne,21,10), '9', 10, 0) = @iNEQ_GUI
               AND SUBSTRING(T.vcLigne,56,4) <> '0000'

        -- En cas d'erreur grave (format), il n'y a pas d'année fiscale spécifique à l'erreur.  Toutes les transactions du fichier
        -- physique d'origine sont en erreur
        IF NOT EXISTS(SELECT * FROM #tblIQEE_Fichiers_Logiques)
            INSERT INTO #tblIQEE_Fichiers_Logiques (siAnnee_Fiscale)
            SELECT DISTINCT F.siAnnee_Fiscale
              FROM dbo.fntIQEE_RechercherFichiers(NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, 0, NULL, NULL, NULL, NULL) F
             WHERE F.vcNom_Fichier LIKE SUBSTRING(@vcNom_Fichier,1,25)+'%'

        -- Déterminer le fichier logique à l'origine du fichier logique de rapport d'erreurs
        IF @vcCode_Type_Fichier = 'ERR'
        BEGIN
            UPDATE TB SET 
                iID_Lien_Fichier_IQEE_Demande = F.iID_Fichier_IQEE
            FROM
                #tblIQEE_Fichiers_Logiques TB
                JOIN dbo.fntIQEE_RechercherFichiers(NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, 0, NULL, 'DEM', NULL, NULL) F ON F.siAnnee_Fiscale = TB.siAnnee_Fiscale
            WHERE 
                F.vcNom_Fichier LIKE LEFT(@vcNom_Fichier,25)+'%'

            IF EXISTS (SELECT * FROM #tblIQEE_Fichiers_Logiques WHERE iID_Lien_Fichier_IQEE_Demande IS NULL)
            BEGIN
                INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
                VALUES ('2',10,'       Erreur: Le nom du rapport d''erreur RQ ne permet pas trouver le fichier logique de transactions à l''origine des erreurs.')

                GOTO ERREUR_TRAITEMENT
            END
        END
        SELECT * FROM #tblIQEE_Fichiers_Logiques

        -- Déterminer le type de fichier et le statut du fichier
        SELECT @tiID_Type_Fichier = tiID_Type_Fichier
          FROM tblIQEE_TypesFichier    
         WHERE vcCode_Type_Fichier = @vcCode_Type_Fichier

        SELECT @tiID_Statut_Fichier = tiID_Statut_Fichier
          FROM tblIQEE_StatutsFichier
         WHERE vcCode_Statut = CASE @vcCode_Type_Fichier 
                                    WHEN 'ERR' THEN 'ATR'
                                    WHEN 'PRO' THEN 'IMP'
                                    WHEN 'NOU' THEN 'IM2'
                                    WHEN 'COT' THEN 'IM3'
                                    ELSE 'IMP'
                               END

        -- Déterminer s'il s'agit d'un fichier test ou de production
        IF UPPER(SUBSTRING(@vcNom_Fichier,1,1)) = 'T'
            SET @bFichier_Test = 1
        ELSE
            SET @bFichier_Test = 0

        -- Déterminer la date de création du fichier et la date de traitement de RQ
        SET @dtDate_Creation = GETDATE()
        IF @vcCode_Type_Fichier IN ('ATT', 'ERR', 'PAE', 'REM', 'TRA')
            SET @vcDate_Traitement_RQ = SUBSTRING(@vcNom_Fichier,26,14)
        ELSE
            SET @vcDate_Traitement_RQ = SUBSTRING(@vcNom_Fichier,16,14)

        SET @vcDate_Traitement_RQ = SubString(@vcDate_Traitement_RQ,1,4)+'-'+
                                    SUBSTRING(@vcDate_Traitement_RQ,5,2)+'-'+
                                    SUBSTRING(@vcDate_Traitement_RQ,7,2)+' '+
                                    SUBSTRING(@vcDate_Traitement_RQ,9,2)+':'+
                                    SUBSTRING(@vcDate_Traitement_RQ,11,2)+':'+
                                    SUBSTRING(@vcDate_Traitement_RQ,13,2)
        PRINT 'Date_Traitement_RQ : ' + @vcDate_Traitement_RQ
        SET @dtDate_Traitement_RQ = Convert(datetime, @vcDate_Traitement_RQ, 120)
        
        -- Créer les fichiers logiques
        IF NOT EXISTS(SELECT TOP 1 * FROM dbo.tblIQEE_Fichiers WHERE vcNom_Fichier = @vcNom_Fichier)
        BEGIN 
            PRINT 'Créer le fichier dans la BD : ' + @vcNom_Fichier
            INSERT INTO dbo.tblIQEE_Fichiers (
                --siAnnee_Fiscale,
                tiID_Type_Fichier, tiID_Statut_Fichier, bFichier_Test, bInd_Simulation, iID_Utilisateur_Creation,
                dtDate_Creation, dtDate_Traitement_RQ, iID_Lien_Fichier_IQEE_Demande, vcNom_Fichier, vcChemin_Fichier)
            SELECT 
                --FL.siAnnee_Fiscale,
                @tiID_Type_Fichier, @tiID_Statut_Fichier, @bFichier_Test, 0, @iID_Utilisateur_Creation,
                @dtDate_Creation, @dtDate_Traitement_RQ, FL.iID_Lien_Fichier_IQEE_Demande, @vcNom_Fichier, @vcChemin_Fichier
            FROM 
                #tblIQEE_Fichiers_Logiques FL
            ORDER BY 
                FL.siAnnee_Fiscale

            SET @iID_Fichier_IQEE = IDENT_CURRENT('dbo.tblIQEE_Fichiers')
        END 
        ELSE
            SELECT @iID_Fichier_IQEE = iID_Fichier_IQEE,
                   @dtDate_Creation = dtDate_Creation
              FROM dbo.tblIQEE_Fichiers
             WHERE vcNom_Fichier = @vcNom_Fichier

        -- Associer les ID des fichiers logiques dans la table temporaire
        UPDATE FL SET iID_Fichier_IQEE = @iID_Fichier_IQEE
          FROM #tblIQEE_Fichiers_Logiques FL

        -- TODO: A enlever
        SELECT * FROM #tblIQEE_Fichiers_Logiques

        ------------------------------------------
        -- Importer le fichier physique dans la BD
        ------------------------------------------

        PRINT 'Importer le fichier dans la BD'
        INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
        VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_ImporterFichierReponses     - '+
                'Importer le fichier dans la BD.')

        -- Déterminer le fichier logique qui contiendra toutes les lignes du fichier physique
        SELECT @iID_Fichier_IQEE = MIN(FL.iID_Fichier_IQEE)
        FROM #tblIQEE_Fichiers_Logiques FL

        DECLARE @iSequence int = 0, 
                @iCompteurMax int,
                @vcLigneTMP nvarchar(1000)
        
        IF @bFichier_DejaCharger = 0
        BEGIN
            SELECT @iCompteur = Min(iSequence), @iCompteurMax = Max(iSequence)
              FROM #tblTMP
        
            SELECT @iNB_Enregistrement_Sommaire = Cast(Substring(vcLigne, 13, 9) AS int)
              FROM #tblTMP
             WHERE vcLigne LIKE '99%'
            PRINT '   '+LTrim(Str(@iNB_Enregistrement_Sommaire))+' lignes à importer'

            -- Boucler les lignes
            WHILE @iCompteur <= @iCompteurMax
            BEGIN
                SET @vcLigne = ''

                -- Regrouper 4 lignes importées (250 caractères de long) pour reformer une ligne complète du fichier physique de l'IQÉÉ
                WHILE Len(@vcLigne+'ÿ') - 1 < 1000 AND @iCompteur <= @iCompteurMax
                BEGIN
                    SELECT @vcLigneTMP = vcLigne
                      FROM #tblTMP
                     WHERE iSequence = @iCompteur

                    IF @iCompteur = 1
                        SET @vcLigneTMP = Substring(@vcLigneTMP, CharIndex('01', @vcLigneTMP), Len(@vcLigneTMP+'ÿ')-1)
                    SET @vcLigne = @vcLigne + @vcLigneTMP --REPLACE(Replace(@vcLigneTMP, Char(13), ''), Char(10), '')
                    SET @iCompteur = @iCompteur + 1
                END

                IF Len(@vcLigne) > 0
                BEGIN
                    SET @iSequence = @iSequence + 1
                    -- select @iID_Fichier_IQEE, @vcLigne
                    -- Ajouter toutes les lignes du fichier physique à l'un des fichiers logiques
                    EXECUTE @iResultat = dbo.psIQEE_AjouterLigneFichier @iID_Fichier_IQEE, @iSequence, @vcLigne
                    IF @iResultat < 0
                    BEGIN
                        INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
                        VALUES ('2',10,'       Erreur #' + LTRIM(STR(ABS(@iResultat))) + ': Erreur dans le service [psIQEE_AjouterLigneFichier].')

                        GOTO ERREUR_TRAITEMENT
                    END

                    IF @iSequence % 1000 = 0
                        PRINT '   @iSequence #' + LTrim(Str(@iSequence)) + ' : ' + @vcLigne
                END
            END
            PRINT '   ----------------------------------------------'+ Char(13) + Char(10) +
                  '   '+LTrim(Str(@iSequence))+' lignes importées sur '+LTrim(Str(@iNB_Enregistrement_Sommaire))+ Char(13) + Char(10) + ''
        END
        ELSE
            PRINT 'Le fichier est déjà importé dans la BD'
    
        IF (SELECT COUNT(*) FROM dbo.tblIQEE_LignesFichier WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE AND cLigne LIKE '01%') <> 1
        BEGIN
            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('2',10,'       Erreur: Il doit avoir un seul enregistrements de type 01 (Entête du fichier).')
            GOTO ERREUR_TRAITEMENT
        END
    
        IF (SELECT COUNT(*) FROM dbo.tblIQEE_LignesFichier WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE AND cLigne LIKE '99%') <> 1
        BEGIN
            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('2',10,'       Erreur: Il doit avoir un seul enregistrements de type 99 (fin de fichier).')
            GOTO ERREUR_TRAITEMENT
        END

        -- Vérifier l'intégrité de l'importation du fichier physique dans la BD
        IF NOT EXISTS (SELECT * FROM tblIQEE_LignesFichier LF, Un_Def D 
                        WHERE LF.iID_Fichier_IQEE = @iID_Fichier_IQEE AND SUBSTRING(LF.cLigne,1,2) = '01'
                              AND dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,3,10), '9', 10, 0) = @iNEQ_GUI)
        BEGIN
            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('2',10,'       Erreur: Il n''y a pas d''enregistrement d''en-tête (type 01) ou le NEQ du fichier est différent du NEQ de GUI.')

            GOTO ERREUR_TRAITEMENT
        END

        SELECT @iCompteur = COUNT(*)
          FROM tblIQEE_LignesFichier LF2
         WHERE LF2.iID_Fichier_IQEE = @iID_Fichier_IQEE

    --    SELECT *
    --    FROM tblIQEE_LignesFichier LF2
    --    WHERE LF2.iID_Fichier_IQEE = @iID_Fichier_IQEE
        IF NOT EXISTS (SELECT * FROM tblIQEE_LignesFichier LF
                        WHERE LF.iID_Fichier_IQEE = @iID_Fichier_IQEE AND SUBSTRING(LF.cLigne,1,2) = '99'
                              AND CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,13,9), '9', NULL, 0) AS INT) = @iCompteur)
        BEGIN
            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('2',10,'       Erreur: Le nombre de lignes de l''enregistrement de fin "99" est différent du nombre de lignes du'+
                            'fichier physique importé.')

            GOTO ERREUR_TRAITEMENT
        END

        IF @vcCode_Type_Fichier IN ('ATT', 'ERR', 'PAE', 'REM', 'TRA')
            SET @iNB_Enregistrement_Sommaire = 0
        ELSE
            SET @iNB_Enregistrement_Sommaire = 1

        IF @iCompteur-@iNB_Enregistrement_Sommaire-2 <> (SELECT COUNT(*) FROM tblIQEE_LignesFichier LF
                                                          WHERE LF.iID_Fichier_IQEE = @iID_Fichier_IQEE AND SUBSTRING(LF.cLigne,1,2) NOT IN ('01','21','31','41','99'))
        BEGIN
            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('2',10,'       Erreur: Le nombre d''enregistrement de type autre que «01 & 99» ne correspond pas au nombre total de ligne de '+
                            'l''enregistrement 99 ajusté (retrait des enregistrements 01, 99 et des en-têtes).  Vérifier l''ordre de lecture des '+
                            'lignes du fichier (SELECT vcLigne FROM #tblTMP).')

            GOTO ERREUR_TRAITEMENT
        END

        BEGIN TRANSACTION

        -------------------------------------------------
        -- Traiter les erreurs (type d'enregistrement 12)
        -------------------------------------------------
        IF @vcCode_Type_Fichier = 'ERR'
        BEGIN
            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_ImporterFichierReponses     - '+
                    'Traiter les erreurs (type d''enregistrement 12).  Appel de "psIQEE_ImporterFichierERR".')

            EXECUTE psIQEE_ImporterFichierERR @iID_Fichier_IQEE, @iID_Utilisateur_Creation, 
                                              @iNombre_Erreur OUTPUT, 
                                              @bIndicateur_Erreur_Grave OUTPUT, 
                                              @mSolde_Avis_Fictif OUT
        END

        ----------------------------------------------------------------------------------------
        -- Traiter les transactions de détermination de crédit (types d'enregistrement 21 et 22)
        ----------------------------------------------------------------------------------------
        IF @vcCode_Type_Fichier = 'PRO'
        BEGIN
            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_ImporterFichierReponses     - '+
                    'Traiter les transactions de détermination de crédit (types d''enregistrement 21 et 22).  Appel de "psIQEE_ImporterFichierPRO".')

            -- L'importation est conçue pour 1 seule année fiscale par rapport de traitement
            IF (SELECT COUNT(*) FROM #tblIQEE_Fichiers_Logiques FL) > 1
            BEGIN
                INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
                VALUES ('2',10,'       Erreur: L''importation est conçue pour 1 seule année fiscale par rapport de traitement.')

                GOTO ERREUR_TRAITEMENT
            END
        
            -- Sélectionner l'année fiscale du rapport de traitement
            SELECT @siAnnee_Fiscale = FL.siAnnee_Fiscale
              FROM #tblIQEE_Fichiers_Logiques FL

            EXECUTE psIQEE_ImporterFichierPRO @iID_Fichier_IQEE, @siAnnee_Fiscale, @cID_Langue,
                                              @dtDate_Paiement_Courriel OUTPUT,
                                              @mMontant_Total_Paiement_Courriel OUTPUT,
                                              @bInd_Erreur OUTPUT
            IF @bInd_Erreur = 1
                GOTO ERREUR_TRAITEMENT
        END

        -------------------------------------------------------------------------------------------------
        -- Traiter les transactions de nouvelle détermination de crédit (types d'enregistrement 31 et 32)
        -------------------------------------------------------------------------------------------------
        IF @vcCode_Type_Fichier = 'NOU'
        BEGIN
            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_ImporterFichierReponses     - '+
                    'Traiter les transactions de nouvelle détermination de crédit (types d''enregistrement 31 et 32).  Appel de "psIQEE_ImporterFichierNOU".')

            -- L'importation est conçue pour 1 seule année fiscale par rapport de traitement
            IF (SELECT COUNT(*) FROM #tblIQEE_Fichiers_Logiques FL) > 1
            BEGIN
                INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
                VALUES ('2',10,'       Erreur: L''importation est conçue pour 1 seule année fiscale par rapport de traitement.')

                GOTO ERREUR_TRAITEMENT
            END
        
            -- Sélectionner l'année fiscale du rapport de traitement
            SELECT @siAnnee_Fiscale = FL.siAnnee_Fiscale
              FROM #tblIQEE_Fichiers_Logiques FL

            EXECUTE psIQEE_ImporterFichierNOU @iID_Fichier_IQEE, @siAnnee_Fiscale, @cID_Langue,
                                              @dtDate_Paiement_Courriel OUTPUT, 
                                              @mMontant_Total_Paiement_Courriel OUTPUT, 
                                              @mMontant_Total_A_Payer_Courriel OUTPUT, 
                                              @bInd_Erreur OUTPUT
                                                    
            IF @bInd_Erreur = 1
                GOTO ERREUR_TRAITEMENT
        END

        -------------------------------------------------------------------
        -- Traiter les avis de cotisation (types d'enregistrement 41 et 42)
        -------------------------------------------------------------------
        IF @vcCode_Type_Fichier = 'COT'
        BEGIN
            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_ImporterFichierReponses     - '+
                    'Traiter les avis de cotisation (types d''enregistrement 41 et 42).  Appel de "psIQEE_ImporterFichierCOT".')

            -- Sélectionner l'année fiscale du rapport de traitement
            SELECT @siAnnee_Fiscale = FL.siAnnee_Fiscale
              FROM #tblIQEE_Fichiers_Logiques FL

            EXECUTE psIQEE_ImporterFichierCOT @iID_Fichier_IQEE, @siAnnee_Fiscale, @cID_Langue,@iID_Utilisateur_Creation,
                                              @dtDate_Paiement_Courriel OUTPUT, 
                                              @mMontant_Total_A_Payer_Courriel OUTPUT,
                                              @mSolde_Avis_Fictif OUT,
                                              @bInd_Erreur OUTPUT
                                        
            IF @bInd_Erreur = 1
                GOTO ERREUR_TRAITEMENT
        END

        -------------------------------------------------
        -- Traiter les erreurs (type d'enregistrement 43)
        -------------------------------------------------
        IF @vcCode_Type_Fichier = 'ATT'
        BEGIN
            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_ImporterFichierReponses     - '+
                    'Traiter les transactions en attente (type d''enregistrement 43).  Appel de "psIQEE_ImporterFichierERR".')

            GOTO ERREUR_TRAITEMENT
            --EXECUTE psIQEE_ImporterFichierATT @iID_Fichier_IQEE,@iID_Utilisateur_Creation,@iNombre_Erreur OUTPUT, @bIndicateur_Erreur_Grave OUTPUT
        END

        -------------------------------------------------
        -- Traiter les erreurs (type d'enregistrement 53)
        -------------------------------------------------
        IF @vcCode_Type_Fichier = 'REM'
        BEGIN
            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_ImporterFichierReponses     - '+
                    'Traiter les remplacements de bénéficiaire (type d''enregistrement 53).  Appel de "psIQEE_ImporterFichierREM".')

            EXECUTE psIQEE_ImporterFichierREM @iID_Fichier_IQEE, @siAnnee_Fiscale, @cID_Langue, 
                                              @bInd_Erreur OUTPUT 

            IF @bInd_Erreur = 1
                GOTO ERREUR_TRAITEMENT
        END

        -------------------------------------------------
        -- Traiter les erreurs (type d'enregistrement 54)
        -------------------------------------------------
        IF @vcCode_Type_Fichier = 'TRA'
        BEGIN
            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_ImporterFichierReponses     - '+
                    'Traiter les transferts (type d''enregistrement 54).  Appel de "psIQEE_ImporterFichierTRA".')

            EXECUTE psIQEE_ImporterFichierTRA @iID_Fichier_IQEE, @siAnnee_Fiscale, @cID_Langue, 
                                              @bInd_Erreur OUTPUT 

            IF @bInd_Erreur = 1
                GOTO ERREUR_TRAITEMENT
        END

        -------------------------------------------------
        -- Traiter les erreurs (type d'enregistrement 55)
        -------------------------------------------------
        IF @vcCode_Type_Fichier = 'PAE'
        BEGIN
            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_ImporterFichierReponses     - '+
                    'Traiter les paiements d''aide aux études (type d''enregistrement 55).  Appel de "psIQEE_ImporterFichierPAE".')

            EXECUTE psIQEE_ImporterFichierPAE @iID_Fichier_IQEE, @siAnnee_Fiscale, @cID_Langue, 
                                              @bInd_Erreur OUTPUT 

            IF @bInd_Erreur = 1
                GOTO ERREUR_TRAITEMENT
        END

        --------------------------------------------------------------------------------------
        -- Mettre à jour le lien entre le fichier de réponse et le plus gros fichier d'origine
        --------------------------------------------------------------------------------------
        IF @vcCode_Type_Fichier IN ('PRO','NOU')
        BEGIN
            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_ImporterFichierReponses     - '+
                    'Mettre à jour lien entre fichier de réponse et fichier d''origine.')

            UPDATE #tblIQEE_Fichiers_Logiques
               SET iID_Lien_Fichier_IQEE_Demande = (SELECT TOP 1 iID_Lien_Fichier_IQEE_Demande FROM #tblIQEE_Fichiers_Demandes FD
                                                     ORDER BY FD.iNB_Transactions DESC)

            UPDATE tblIQEE_Fichiers
               SET iID_Lien_Fichier_IQEE_Demande = (SELECT TOP 1 iID_Lien_Fichier_IQEE_Demande FROM #tblIQEE_Fichiers_Demandes FD
                                                     ORDER BY FD.iNB_Transactions DESC)
             WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE
        END

        ---------------------------------------------------------------------------------------------------------------------
        -- Mettre à jour le lien vers les paramètres de l'IQÉÉ du fichier de réponses basé sur le fichier d'origine principal
        ---------------------------------------------------------------------------------------------------------------------
        UPDATE F SET iID_Parametres_IQEE = FO.iID_Parametres_IQEE
          FROM tblIQEE_Fichiers F
               JOIN #tblIQEE_Fichiers_Logiques FL ON FL.iID_Fichier_IQEE = F.iID_Fichier_IQEE
               JOIN tblIQEE_Fichiers FO ON FO.iID_Fichier_IQEE = FL.iID_Lien_Fichier_IQEE_Demande

        ------------------------------------------------------------
        -- Traiter les annulations/reprises suite aux réponses de RQ
        ------------------------------------------------------------
        IF @vcCode_Type_Fichier IN ('ERR','PRO','NOU','COT')
        BEGIN
            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_ImporterFichierReponses     - '+
                    'Traiter les annulations/reprises suite aux réponses de RQ.  Appel de "psIQEE_ImporterTraiterAnnulations".')

            EXECUTE psIQEE_ImporterTraiterAnnulations @vcCode_Type_Fichier
        END

        -------------------------------------------------------------
        -- Mettre à jour les statuts des fichiers logiques d'origines
        -------------------------------------------------------------

        INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
        VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_ImporterFichierReponses     - '+
                'Mettre à jour les statuts des fichiers logiques d''origines.')

        DECLARE curIQEE_Fichiers_Originaux CURSOR LOCAL FAST_FORWARD 
            FOR SELECT iID_Lien_Fichier_IQEE_Demande
                  FROM #tblIQEE_Fichiers_Logiques FL

        OPEN curIQEE_Fichiers_Originaux

        FETCH NEXT FROM curIQEE_Fichiers_Originaux INTO @iID_Lien_Fichier_IQEE_Demande
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Déterminer le statut
            IF @bIndicateur_Erreur_Grave = 1
                SET @vcCode_Type_Fichier_Origine = 'ERF'
            ELSE
            BEGIN
                -- Initialiser les compteurs par statut de réponse
                SET @iCompte_Attente = 0
                SET @iCompte_Reponse = 0
                SET @iCompte_Erreur = 0

                -- Compter les transactions 02

                SELECT @iCompte_Attente = @iCompte_Attente + COUNT(*)
                  FROM tblIQEE_Demandes
                 WHERE iID_Fichier_IQEE = @iID_Lien_Fichier_IQEE_Demande
                       AND cStatut_Reponse = 'A'

                SELECT @iCompte_Reponse = @iCompte_Reponse + COUNT(*)
                  FROM tblIQEE_Demandes
                 WHERE iID_Fichier_IQEE = @iID_Lien_Fichier_IQEE_Demande
                       AND cStatut_Reponse IN ('R','D','T')

                SELECT @iCompte_Erreur = @iCompte_Erreur + COUNT(*)
                  FROM tblIQEE_Demandes
                 WHERE iID_Fichier_IQEE = @iID_Lien_Fichier_IQEE_Demande
                       AND cStatut_Reponse = 'E'                                        

                -- Compter les transactions 03

                SELECT @iCompte_Attente = @iCompte_Attente + COUNT(*)
                  FROM tblIQEE_RemplacementsBeneficiaire
                 WHERE iID_Fichier_IQEE = @iID_Lien_Fichier_IQEE_Demande
                       AND cStatut_Reponse = 'A'

                SELECT @iCompte_Reponse = @iCompte_Reponse + COUNT(*)
                  FROM tblIQEE_RemplacementsBeneficiaire
                 WHERE iID_Fichier_IQEE = @iID_Lien_Fichier_IQEE_Demande
                       AND cStatut_Reponse = 'R'

                SELECT @iCompte_Erreur = @iCompte_Erreur + COUNT(*)
                  FROM tblIQEE_RemplacementsBeneficiaire
                 WHERE iID_Fichier_IQEE = @iID_Lien_Fichier_IQEE_Demande
                       AND cStatut_Reponse = 'E'
    
                -- Compter les transactions 04
    
                SELECT @iCompte_Attente = @iCompte_Attente + COUNT(*)
                  FROM tblIQEE_Transferts
                 WHERE iID_Fichier_IQEE = @iID_Lien_Fichier_IQEE_Demande
                       AND cStatut_Reponse = 'A'
                                
                SELECT @iCompte_Reponse = @iCompte_Reponse + COUNT(*)
                  FROM tblIQEE_Transferts
                 WHERE iID_Fichier_IQEE = @iID_Lien_Fichier_IQEE_Demande
                       AND cStatut_Reponse = 'R'
    
                SELECT @iCompte_Erreur = @iCompte_Erreur + COUNT(*)
                  FROM tblIQEE_Transferts
                 WHERE iID_Fichier_IQEE = @iID_Lien_Fichier_IQEE_Demande
                       AND cStatut_Reponse = 'E'
    
                -- Compter les transactions 05

                SELECT @iCompte_Attente = @iCompte_Attente + COUNT(*)
                  FROM tblIQEE_PaiementsBeneficiaires
                 WHERE iID_Fichier_IQEE = @iID_Lien_Fichier_IQEE_Demande
                       AND cStatut_Reponse = 'A'
                                
                SELECT @iCompte_Reponse = @iCompte_Reponse + COUNT(*)
                  FROM tblIQEE_PaiementsBeneficiaires
                 WHERE iID_Fichier_IQEE = @iID_Lien_Fichier_IQEE_Demande
                       AND cStatut_Reponse = 'R'
    
                SELECT @iCompte_Erreur = @iCompte_Erreur + COUNT(*)
                  FROM tblIQEE_PaiementsBeneficiaires
                 WHERE iID_Fichier_IQEE = @iID_Lien_Fichier_IQEE_Demande
                       AND cStatut_Reponse = 'E'
             
                -- Compter les transactions 06

                SELECT @iCompte_Attente = @iCompte_Attente + COUNT(*)
                  FROM tblIQEE_ImpotsSpeciaux
                 WHERE iID_Fichier_IQEE = @iID_Lien_Fichier_IQEE_Demande
                       AND cStatut_Reponse = 'A'
                                
                SELECT @iCompte_Reponse = @iCompte_Reponse + COUNT(*)
                  FROM tblIQEE_ImpotsSpeciaux
                 WHERE iID_Fichier_IQEE = @iID_Lien_Fichier_IQEE_Demande
                       AND cStatut_Reponse = 'R'

                SELECT @iCompte_Erreur = @iCompte_Erreur + COUNT(*)
                  FROM tblIQEE_ImpotsSpeciaux
                 WHERE iID_Fichier_IQEE = @iID_Lien_Fichier_IQEE_Demande
                       AND cStatut_Reponse = 'E'

                IF @iCompte_Attente > 0
                    SET @vcCode_Type_Fichier_Origine = 'RIN'
                ELSE
                    IF @iCompte_Erreur > 0 AND @iCompte_Reponse > 0
                        SET @vcCode_Type_Fichier_Origine = 'EER'
                    ELSE
                        IF @iCompte_Erreur > 0
                            SET @vcCode_Type_Fichier_Origine = 'ERR'
                        ELSE
                            SET @vcCode_Type_Fichier_Origine = 'REP'
            END

            -- Déterminer l'identifiant du statut
            SELECT @tiID_Statut_Fichier = tiID_Statut_Fichier
              FROM tblIQEE_StatutsFichier
             WHERE vcCode_Statut = @vcCode_Type_Fichier_Origine

            -- Mettre à jour le statut
            UPDATE tblIQEE_Fichiers SET tiID_Statut_Fichier = @tiID_Statut_Fichier
             WHERE iID_Fichier_IQEE = @iID_Lien_Fichier_IQEE_Demande

            FETCH NEXT FROM curIQEE_Fichiers_Originaux INTO @iID_Lien_Fichier_IQEE_Demande
        END

        CLOSE curIQEE_Fichiers_Originaux
        DEALLOCATE curIQEE_Fichiers_Originaux

        ---------------------------------------------------------------------------------------------------------------------------
        -- Injecter les montants d'IQÉÉ dans les conventions à partir des réponses aux transactions d'IQÉÉ (rapports de traitement)
        ---------------------------------------------------------------------------------------------------------------------------
        IF @vcCode_Type_Fichier IN ('PRO','NOU')
        BEGIN
            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_ImporterFichierReponses     - '+
                    'Injecter les montants d''IQÉÉ dans les conventions.  Appel de "psIQEE_InjecterMontantsConventions".')

            EXECUTE @iResultat = dbo.psIQEE_InjecterMontantsConventions 1, @iID_Utilisateur_Creation

            IF @iResultat = 0
            BEGIN
                INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
                VALUES ('2',10,'       Avertissement: Le service "psIQEE_InjecterMontantsConventions" n''a pas générer de nouvelle'+
                                ' opération de subvention d''IQÉÉ (IQE).')
            END
            IF @iResultat = -1
            BEGIN
                INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
                VALUES ('2',10,'       Erreur: le service "psIQEE_InjecterMontantsConventions" est en erreur non prévue.')

                GOTO ERREUR_TRAITEMENT
            END
        END

        --------------------
        -- Fin du traitement
        --------------------
        -- TODO: A enlever
        PRINT 'COMMIT TRANSACTION-1'
        IF @@tranCount > 0
            COMMIT TRANSACTION

        -- 2014-06-27 SB:  Désactivation du code mentionnant les RIO dans le rapport de traitement
        --    -----------------------------------------------------------------------------------------------------------------------------------------
        --    -- Retransférer vers les conventions individuelles lorsque de l'IQÉÉ a été injecté dans une convention ayant fait l'objet d'un RIO valide
        --    -- Note: Le solde des comptes doivent être tous positif pour faire l'opération
        --    -----------------------------------------------------------------------------------------------------------------------------------------
        --    IF @vcCode_Type_Fichier IN ('PRO','NOU','COT')
        --        BEGIN
        --            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
        --            VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_ImporterFichierReponses     - '+
        --                    'Retransfert RIO.')

        --            BEGIN TRY

        --            BEGIN TRANSACTION
        --                DECLARE @iID_Convention_Source INT,
        --                        @iID_Unite_Source INT,
        --                        @dtDate_Du_Jour DATETIME,
        --                        @vcRIO_TRANSFERT_TRANSAC_CONVENTION VARCHAR(200),
        --                        @iID_Connexion INT,
        --                        @iNB3 INT

        --                -- Trouver les codes transférable par l'opération RIO
        --                SET @vcRIO_TRANSFERT_TRANSAC_CONVENTION = [dbo].[fnOPER_ObtenirTypesOperationConvCategorie]('RIO-TRANSFERT-TRANSAC-CONVENTION')

        --                -- Trouver la dernière connection de l'utilisateur et la date du jour
        --                SELECT @iID_Connexion = MAX(CO.ConnectID)
        --                FROM Mo_Connect CO
        --                WHERE CO.UserID = @iID_Utilisateur_Creation

        --                SET @dtDate_Du_Jour = GETDATE()

        --                -- Rechercher la liste des opérations RIO à faire
        --                DECLARE curRIO CURSOR LOCAL FAST_FORWARD FOR
        --                    SELECT DISTINCT R.iID_Convention_Source, R.iID_Unite_Source
        --                    FROM tblOPER_OperationsRIO R
        --                    -- Rechercher les RIO originaux non annulés...
        --                    WHERE R.bRIO_Annulee = 0
        --                      AND R.bRIO_QuiAnnule = 0
        --                      AND R.dtDate_Enregistrement = (SELECT MIN(R2.dtDate_Enregistrement)
        --                                                     FROM tblOPER_OperationsRIO R2
        --                                                     WHERE R2.iID_Convention_Source = R.iID_Convention_Source AND
        --                                                           R2.bRIO_Annulee = 0 AND
        --                                                           R2.bRIO_QuiAnnule = 0)
        --                      -- qui ont un solde transférable par le RIO...
        --                      AND 0 < (SELECT ISNULL(SUM(OC.ConventionOperAmount),0)
        --                                FROM Un_ConventionOper OC
        --                                WHERE OC.ConventionID = R.iID_Convention_Source
        --                                  AND (CHARINDEX(OC.ConventionOperTypeID,@vcRIO_TRANSFERT_TRANSAC_CONVENTION) > 0))
        --                      -- qui n'ont pas de compte en perte
        --                      AND NOT EXISTS (SELECT CO.ConventionOperTypeID,SUM(CO.ConventionOperAmount)
        --                                      FROM Un_ConventionOper CO
        --                                      WHERE CO.ConventionID = R.iID_Convention_Source
        --                                        AND (CHARINDEX(CO.ConventionOperTypeID,@vcRIO_TRANSFERT_TRANSAC_CONVENTION) > 0)
        --                                      GROUP BY CO.ConventionOperTypeID
        --                                      HAVING SUM(CO.ConventionOperAmount) < 0)

        --                -- Boucler les RIO à faire
        --                SET @iNB3 = 0
        --                OPEN curRIO
        --                FETCH NEXT FROM curRIO INTO @iID_Convention_Source, @iID_Unite_Source
        --                WHILE @@FETCH_STATUS = 0
        --                    BEGIN
        --                        -- Faire le RIO
        ----                        EXECUTE @iCode_Retour_RIO = [dbo].[psOPER_CreerOperationRIO] @iID_Connexion,@iID_Convention_Source,@iID_Unite_Source,@dtDate_Paiement_Courriel,
        ----                                                                                     @dtDate_Paiement_Courriel,NULL,'RIO',1,NULL,NULL,@vcCode_Message OUTPUT
        ----                        SET @iNB3 = @iNB3 + 1
        ----TODO: A Enlever
        ----SET @iNombre_Erreur = 10/0

        --                        FETCH NEXT FROM curRIO INTO @iID_Convention_Source, @iID_Unite_Source
        --                    END
        --                CLOSE curRIO
        --                DEALLOCATE curRIO

        --                INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
        --                VALUES ('2',12,' ')

        --                INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
        --                VALUES ('2',13,'       TRAITEMENT SECONDAIRE DES RETRANSFERTS RIO - OK')

        --                INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
        --                VALUES ('2',14,'       Nombre de retransfert RIO: '+CAST(@iNB3 AS VARCHAR))

        --            END TRY
        --            BEGIN CATCH
        --                IF @@TRANCOUNT > 0
        ---- TODO: A enlever
        --BEGIN
        --PRINT 'ROLLBACK TRANSACTION-3'
        --IF @@tranCount > 0
        --                    ROLLBACK TRANSACTION
        --END
        --                INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
        --                VALUES ('2',10,'       Avertissement: Le traitement d''importation du fichier a fonctionné mais il y a eu un problème avec le '+
        --                               'retransfert RIO.  Cette portion de code peut être réexécuté à part par l''informatique.')
        ---- TODO: Mettre la ligne de commande au complet?
        --                INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
        --                VALUES ('2',10,'              Variable "iID_Convention_Source" = '+ISNULL(CAST(@iID_Convention_Source AS VARCHAR),0))
        --                INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
        --                VALUES ('2',10,'              Variable "iID_Unite_Source" = '+ISNULL(CAST(@iID_Unite_Source AS VARCHAR),0))
        --                INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
        --                VALUES ('2',10,'              Variable "dtDate_Paiement_Courriel" = '+ISNULL(CAST(@dtDate_Paiement_Courriel AS VARCHAR),''))

        --                IF ERROR_NUMBER() IS NOT NULL
        --                    BEGIN
        --                        INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
        --                        VALUES ('2',15,'              Erreur non prévue dans la section du retransfert RIO:')
        --                         INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
        --                        VALUES ('2',15,'                     Temps: '+CONVERT(VARCHAR(25),GETDATE(),121))
        --                        INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
        --                        VALUES ('2',15,'                     Numéro d''erreur: '+CAST(ERROR_NUMBER() AS VARCHAR))
        --                        INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
        --                        VALUES ('2',15,'                     Message d''erreur: '+ERROR_MESSAGE())
        --                        INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
        --                        VALUES ('2',15,'                     Sévérité: '+CAST(ERROR_SEVERITY() AS VARCHAR))
        --                        INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
        --                        VALUES ('2',15,'                     État: '+CAST(ERROR_STATE() AS VARCHAR))
        --                        INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
        --                        VALUES ('2',15,'                     Procédure: '+ERROR_PROCEDURE())
        --                        INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
        --                        VALUES ('2',15,'                     Ligne: '+CAST(ERROR_LINE() AS VARCHAR))
        --                    END

        --                INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
        --                VALUES ('2',15,'       TRAITEMENT SECONDAIRE DES RETRANSFERTS RIO - EN ERREUR')
        --            END CATCH
        -- TODO: A enlever
        --PRINT 'COMMIT TRANSACTION-3'
        --            IF @@TRANCOUNT > 0
        --                COMMIT TRANSACTION
        --        END

        -- TODO: Retransférer OUT, Chèque PAE...

        SELECT @iCode_Retour = COUNT(*)
        FROM #tblIQEE_Fichiers_Logiques FL

        INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
        VALUES ('2',15,' ')
        INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
        VALUES ('2',15,'       TRAITEMENT PRINCIPAL D''IMPORTATION - OK')
         INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
        VALUES ('3',99,'       Fin du traitement: '+CONVERT(VARCHAR(25),GETDATE(),121))

        GOTO RAPPORT_IMPORTATION

    END TRY
    BEGIN CATCH
        PRINT 'Catch : '
        PRINT 'Error     : ' + ERROR_MESSAGE()

        -- Ajouter l'erreur au rapport d'importation
        IF ERROR_NUMBER() IS NOT NULL
        BEGIN
            PRINT 'Procedure : ' + ERROR_PROCEDURE() 
            PRINT 'Ligne     : ' + LTrim(Str(ERROR_LINE()))
                
            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('2',15,'       Erreur non prévue:')
                INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('2',15,'              Temps: '+CONVERT(VARCHAR(25),GETDATE(),121))
            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('2',15,'              Numéro d''erreur: '+CAST(ERROR_NUMBER() AS VARCHAR))
            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('2',15,'              Message d''erreur: '+ERROR_MESSAGE())
            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('2',15,'              Sévérité: '+CAST(ERROR_SEVERITY() AS VARCHAR))
            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('2',15,'              État: '+CAST(ERROR_STATE() AS VARCHAR))
            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('2',15,'              Procédure: '+ERROR_PROCEDURE())
            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('2',15,'              Ligne: '+CAST(ERROR_LINE() AS VARCHAR))
        END

        INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
        VALUES ('2',20,'       TRAITEMENT PRINCIPAL D''IMPORTATION - EN ERREUR')
        INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
        VALUES ('3',15,'       Fin du traitement: '+CONVERT(VARCHAR(25),GETDATE(),121))

        -- Écrire le rapport d'importation dans le répertoire
        IF @vcNom_Rapport_Importation IS NULL
        BEGIN
            -- Compléter le chemin du fichier
            IF SUBSTRING(@vcChemin_Fichier,LEN(@vcChemin_Fichier),1) <> '\'
                SET @vcChemin_Fichier = @vcChemin_Fichier + '\'

            -- Définir le nom du rapport d'importation
            SET @vcNom_Rapport_Importation = @vcChemin_Fichier+REPLACE(@vcNom_Fichier,'.','')+'.txt'
        END

        -- Sauvegarder en mémoire le rapport d'importation parce que la procédure "psGENE_EcrireFichierTexteAPartirRequeteSQL" oblige à faire
        -- un commit.
        INSERT INTO @tblIQEE_RapportImportationTMP (cSection,iSequence,vcMessage)
        SELECT cSection,iSequence,vcMessage
          FROM ##tblIQEE_RapportImportation

        -- Définir que l'importation doit être annulée
        SET @iCode_Retour = -1

        PRINT 'Erreur technique1'
        -- Annuler l'importation
        IF @@TRANCOUNT > 0
        -- TODO: A enlever
        BEGIN
            PRINT 'ROLLBACK TRANSACTION1'
            ROLLBACK TRANSACTION
        END

        DELETE FROM ##tblIQEE_RapportImportation

        INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
        SELECT cSection,iSequence,vcMessage
          FROM @tblIQEE_RapportImportationTMP

        EXECUTE @iResultat = dbo.psGENE_EcrireFichierTexteAPartirRequeteSQL @vcNom_Rapport_Importation,
                             'SELECT vcMessage FROM ##tblIQEE_RapportImportation R ORDER BY R.cSection,R.iSequence',
                             @@servername,1,NULL,1,0,0

        -- TODO: A enlever
        SELECT vcMessage FROM ##tblIQEE_RapportImportation R ORDER BY R.cSection,R.iSequence

        -- Envoyer le courriel de résultat
        GOTO ENVOI_COURRIEL
    END CATCH

ERREUR_TRAITEMENT:
    -- Ajouter des informations au rapport d'importation
    INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
    VALUES ('2',20,'       TRAITEMENT PRINCIPAL D''IMPORTATION - EN ERREUR')
        INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
    VALUES ('3',99,'       Fin du traitement: '+CONVERT(VARCHAR(25),GETDATE(),121))

    -- Définir que l'importation doit être annulée
    SET @iCode_Retour = -2

RAPPORT_IMPORTATION:
    -- Écrire le rapport d'importation dans le répertoire
    IF EXISTS (SELECT * FROM ##tblIQEE_RapportImportation R WHERE R.vcMessage LIKE '%Avertissement:%')
        SET @bAvertissements = 1
    ELSE
        SET @bAvertissements = 0

    -- Sauvegarder en mémoire le rapport d'importation parce que la procédure "psGENE_EcrireFichierTexteAPartirRequeteSQL" oblige à faire
    -- un commit.
    INSERT INTO @tblIQEE_RapportImportationTMP (cSection,iSequence,vcMessage)
    SELECT cSection,iSequence,vcMessage FROM ##tblIQEE_RapportImportation

    -- Annuler l'importation
    IF @iCode_Retour < 0
    BEGIN
        -- TODO: A enlever
        PRINT 'Erreur technique2'
        IF @@TRANCOUNT > 0
        -- TODO: A enlever
        BEGIN
            SELECT cSection,iSequence,vcMessage
            FROM ##tblIQEE_RapportImportation
            PRINT 'ROLLBACK TRANSACTION2'
            IF @@tranCount > 0
                ROLLBACK TRANSACTION
        END
    END

    DELETE FROM ##tblIQEE_RapportImportation

    INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
    SELECT cSection,iSequence,vcMessage
        FROM @tblIQEE_RapportImportationTMP

    EXECUTE @iResultat = dbo.psGENE_EcrireFichierTexteAPartirRequeteSQL @vcNom_Rapport_Importation,
                            'SELECT vcMessage FROM ##tblIQEE_RapportImportation R ORDER BY R.cSection,R.iSequence',
                            @@servername,1,NULL,1,0,0

    -- TODO: A enlever
    SELECT vcMessage FROM ##tblIQEE_RapportImportation R ORDER BY R.cSection,R.iSequence

    ----------------------------------------------------------------------------------
    -- Envoyer un courriel pour informer les utilisateurs du résultat de l'importation
    ----------------------------------------------------------------------------------
ENVOI_COURRIEL:
    -- TODO: A enlever
    PRINT 'Courriel1'

    IF @bDejaCreer_RapportImportation = 0
        DROP TABLE ##tblIQEE_RapportImportation

    -- TODO: A enlever
    PRINT 'Courriel2'

    IF @vcCourrielsDestination IS NOT NULL AND @vcCourrielsDestination <> ''
    BEGIN
        BEGIN TRY
            -- Préparer le message
            SELECT @vcTMP = FirstName + ' ' + LastName
              FROM dbo.Mo_Human 
             WHERE HumanID = @iID_Utilisateur_Creation

            -- Obtenir la structure du message
            SET @vcSujet = dbo.fnGENE_ObtenirParametre('IQEE_IMPORTER_FICHIER_COURRIEL_SUJET',NULL, @cID_Langue,NULL,NULL,NULL,NULL)
            SET @vcMessage = dbo.fnGENE_ObtenirParametre('IQEE_IMPORTER_FICHIER_COURRIEL1',NULL, @cID_Langue,NULL,NULL,NULL,NULL)
            SET @vcMessage = @vcMessage + dbo.fnGENE_ObtenirParametre('IQEE_IMPORTER_FICHIER_COURRIEL2',NULL, @cID_Langue,NULL,NULL,NULL,NULL)
            SET @vcMessage = @vcMessage + dbo.fnGENE_ObtenirParametre('IQEE_IMPORTER_FICHIER_COURRIEL3',NULL, @cID_Langue,NULL,NULL,NULL,NULL)
            SET @vcMessage = @vcMessage + dbo.fnGENE_ObtenirParametre('IQEE_IMPORTER_FICHIER_COURRIEL4',NULL, @cID_Langue,NULL,NULL,NULL,NULL)

            -- Mettre à jour les paramètres du courriel
            SET @vcMessage = REPLACE(@vcMessage,'[vcNom_Fichier]',@vcNom_Fichier)
            SET @vcMessage = REPLACE(@vcMessage,'[vcChemin_Fichier]',@vcChemin_Fichier)
            SET @vcMessage = REPLACE(@vcMessage,'[vcType_Fichier]',@vcDescription_Type_Fichier)
            SET @vcMessage = REPLACE(@vcMessage,'[vcDemandeur]',@vcTMP)
            SET @vcMessage = REPLACE(@vcMessage,'[vcNom_Serveur]',@@servername)
            SET @vcMessage = REPLACE(@vcMessage,'[vcNom_BD]',DB_NAME())
            SET @vcMessage = REPLACE(@vcMessage,'[vcTempsTotal]',CONVERT(VARCHAR(8),GETDATE()-@dtDebut_Importation,108))
            SET @vcMessage = REPLACE(@vcMessage,'[vcNom_Rapport]',@vcNom_Rapport_Importation)

            IF @iCode_Retour > 0
            BEGIN
                -- Le traitement a réussi
                SET @vcMessage = REPLACE(@vcMessage,'{Info1}','')
                SET @vcMessage = REPLACE(@vcMessage,'{Info2}','')
                SET @vcMessage = REPLACE(@vcMessage,'[vcMessNor1]','')
                SET @vcMessage = REPLACE(@vcMessage,'[vcMessNor2]','')
                SET @iNB1 = CHARINDEX('[vcMessEch1]',@vcMessage)-1
                SET @iNB2 = CHARINDEX('[vcMessEch2]',@vcMessage)+12
                SET @vcMessage = SUBSTRING(@vcMessage,1,@iNB1)+SUBSTRING(@vcMessage,@iNB2,2000)

                -- Boucler les fichiers logiques
                DECLARE curFichiers_Logiques CURSOR LOCAL FAST_FORWARD 
                    FOR SELECT FL.siAnnee_Fiscale
                          FROM #tblIQEE_Fichiers_Logiques FL
                         ORDER BY FL.siAnnee_Fiscale

                OPEN curFichiers_Logiques

                SET @vcTMP = ''
                FETCH NEXT FROM curFichiers_Logiques INTO @siAnnee_Fiscale
                WHILE @@FETCH_STATUS = 0
                BEGIN
                    -- Faire l'inventaire des années fiscales touchées par le fichier physique
                    IF @vcTMP = ''
                        SET @vcTMP = @vcTMP + CAST(@siAnnee_Fiscale AS VARCHAR(4))
                    ELSE
                        SET @vcTMP = @vcTMP + ', ' + CAST(@siAnnee_Fiscale AS VARCHAR(4))

                    FETCH NEXT FROM curFichiers_Logiques INTO @siAnnee_Fiscale
                END

                CLOSE curFichiers_Logiques
                DEALLOCATE curFichiers_Logiques

                SET @vcMessage = REPLACE(@vcMessage,'[vcAnnees_Fiscales]',@vcTMP)

                IF @vcCode_Type_Fichier IN ('ATT', 'PAE', 'TRA')
                BEGIN
                    PRINT ''
                    SET @iNB1 = CHARINDEX('{InfoERR1}',@vcMessage)-1
                    SET @iNB2 = CHARINDEX('{InfoAPa2}',@vcMessage)+10
                    SET @vcMessage = LEFT(@vcMessage,@iNB1)+SUBSTRING(@vcMessage,@iNB2,2000)
                END 

                IF @vcCode_Type_Fichier = 'ERR'
                BEGIN
                    -- Rapport d'erreurs
                    SET @vcMessage = REPLACE(@vcMessage,'{InfoERR1}','')
                    SET @vcMessage = REPLACE(@vcMessage,'{InfoERR2}','')
                    SET @iNB1 = CHARINDEX('{InfoARe1}',@vcMessage)-1
                    SET @iNB2 = CHARINDEX('{InfoARe2}',@vcMessage)+10
                    SET @vcMessage = SUBSTRING(@vcMessage,1,@iNB1)+SUBSTRING(@vcMessage,@iNB2,2000)
                    SET @iNB1 = CHARINDEX('{InfoAPa1}',@vcMessage)-1
                    SET @iNB2 = CHARINDEX('{InfoAPa2}',@vcMessage)+10
                    SET @vcMessage = SUBSTRING(@vcMessage,1,@iNB1)+SUBSTRING(@vcMessage,@iNB2,2000)

                    SET @vcMessage = REPLACE(@vcMessage,'[iNB_Erreur]',CAST(ISNULL(@iNombre_Erreur,0) AS VARCHAR(20)))

                    -- A verifier: Est-ce qu'un avis fictif peut etre > 0 ?
                    IF @mSolde_Avis_Fictif <> 0 
                    BEGIN
                        SET @vcMessage = @vcMessage + dbo.fnGENE_ObtenirParametre('IQEE_IMPORTER_FICHIER_COURRIEL5_MONTANTS_ERR',NULL,'FRA',NULL,NULL,NULL,NULL)
                                                    
                        SET @vcMessage = REPLACE(@vcMessage,'[@mSolde_Avis_Fictif]',dbo.fn_Mo_MoneyToStr(ISNULL(ABS(@mSolde_Avis_Fictif),0),'FRA',1))
                    END

                    IF @bIndicateur_Erreur_Grave = 1
                    BEGIN
                        -- Fichier en erreur grave
                        SET @vcMessage = REPLACE(@vcMessage,'[ActGra1]','')
                        IF @bAvertissements = 1
                            SET @vcMessage = REPLACE(@vcMessage,'[ActGra2]','  ')
                        ELSE
                            SET @vcMessage = REPLACE(@vcMessage,'[ActGra2]','')
                    END
                    ELSE
                    BEGIN
                        -- Erreurs RQ importées
                        SET @vcMessage = REPLACE(@vcMessage,'[ActErr1]','')
                        IF @bAvertissements = 1
                            SET @vcMessage = REPLACE(@vcMessage,'[ActErr2]','  ')
                        ELSE
                            SET @vcMessage = REPLACE(@vcMessage,'[ActErr2]','')
                    END
                END -- IF @vcCode_Type_Fichier = 'ERR'
                            
                IF @vcCode_Type_Fichier = 'COT' 
                BEGIN
                    --@mMontant_Total_Paiement_Courriel
                    IF @mMontant_Total_A_Payer_Courriel > 0     
                    BEGIN
                        SET @vcMessage = REPLACE(@vcMessage,'{InfoAPa1}','')
                        SET @vcMessage = REPLACE(@vcMessage,'{InfoAPa2}','')
                                            
                        SET @vcMessage = REPLACE(@vcMessage,'[mMontant_A_Payer]',dbo.fn_Mo_MoneyToStr(ISNULL(@mMontant_Total_A_Payer_Courriel,0),'FRA',1))
                                            
                        SET @vcMessage = REPLACE(@vcMessage,'[ActAPa1]','')
                        SET @vcMessage = REPLACE(@vcMessage,'[ActAPa2]','  ')
                        SET @vcMessage = REPLACE(@vcMessage,'{InfoARe1}','')
                        SET @vcMessage = REPLACE(@vcMessage,'Montant du paiement: [mMontant_Paiement]{InfoARe2}','')
                        SET @vcMessage = REPLACE(@vcMessage,'Nombre d''erreur à traiter: [iNB_Erreur]{InfoERR2}','')
                        SET @vcMessage = REPLACE(@vcMessage,'Nombre d''erreur à traiter: [iNB_Erreur]{InfoERR2}{InfoARe1}','')
                        SET @vcMessage = REPLACE(@vcMessage,'{InfoERR1}[CH13][CH9]','')
                        SET @vcMessage = REPLACE(@vcMessage,'[CH13][CH9]Date du paiement:','')
                        SET @vcMessage = REPLACE(@vcMessage,'[dtDate_Paiement]','')
                        SET @vcMessage = REPLACE(@vcMessage,'{InfoAPa1}','')
                                             
                        SET @vcMessage = REPLACE(@vcMessage,'Montant à payer aux conventions: [mMontant_A_Payer]{InfoAPa2}','')
                                            
                        -- A verifier: Est-ce qu'un avis fictif peut etre > 0 ?
                        IF @mSolde_Avis_Fictif <> 0 
                        BEGIN
                            SET @vcMessage = @vcMessage + dbo.fnGENE_ObtenirParametre('IQEE_IMPORTER_FICHIER_COURRIEL5_MONTANTS_COT',NULL,'FRA',NULL,NULL,NULL,NULL)
                                                    
                            SET @vcMessage = REPLACE(@vcMessage,'[@mSolde_Avis_Fictif]',dbo.fn_Mo_MoneyToStr(ISNULL(ABS(@mSolde_Avis_Fictif),0),'FRA',1))
                                                    
                            set @mSolde_Impots = @mMontant_Total_A_Payer_Courriel- @mSolde_Avis_Fictif
                            SET @vcMessage = REPLACE(@vcMessage,'[@mSolde_Impots]',dbo.fn_Mo_MoneyToStr(ISNULL(ABS(@mSolde_Impots),0),'FRA',1))
                        END
                                            
                    END
                    ELSE  --@mMontant_Total_A_Payer_Courriel < 0
                    BEGIN
                        SELECT @dtDate_Paiement_Courriel as '@dtDate_Paiement_Courriel'
                        SELECT @mMontant_Total_A_Payer_Courriel as '@mMontant_Total_A_Payer_Courriel'
                                            
                        SET @vcMessage = REPLACE(@vcMessage,'{InfoERR1}','')
                        SET @vcMessage = REPLACE(@vcMessage,'Nombre d''erreur à traiter: [iNB_Erreur]{InfoERR2}','')
                        SET @vcMessage = REPLACE(@vcMessage,'{InfoAPa1}','')
                        SET @vcMessage = REPLACE(@vcMessage,'Montant à payer: [mMontant_A_Payer]{InfoAPa2}','')
                        SET @vcMessage = REPLACE(@vcMessage,'{InfoARe1}','')
                        SET @vcMessage = REPLACE(@vcMessage,'{InfoARe2}','')
                        SET @vcMessage = REPLACE(@vcMessage,'[dtDate_Paiement]', CONVERT(VARCHAR(10),ISNULL(@dtDate_Paiement_Courriel,0),120))
                        SET @vcMessage = REPLACE(@vcMessage,'[mMontant_Paiement]',dbo.fn_Mo_MoneyToStr(ISNULL(ABS(@mMontant_Total_A_Payer_Courriel),0),'FRA',1))
                        SET @vcMessage = REPLACE(@vcMessage,'[ActARe1]','')
                        SET @vcMessage = REPLACE(@vcMessage,'[ActARe2]','  ')
                        SET @vcMessage = REPLACE(@vcMessage,'[ActARe2]','')
                                            
                        -- A verifier: Est-ce qu'un avis fictif peut etre > 0
                        IF @mSolde_Avis_Fictif <> 0 
                        BEGIN
                            SET @vcMessage = @vcMessage + dbo.fnGENE_ObtenirParametre('IQEE_IMPORTER_FICHIER_COURRIEL5_MONTANTS_COT',NULL,@cID_Langue,NULL,NULL,NULL,NULL)
                            SET @vcMessage = REPLACE(@vcMessage,'[@mSolde_Avis_Fictif]',dbo.fn_Mo_MoneyToStr(ISNULL(ABS(@mSolde_Avis_Fictif),0),'FRA',1))
                            set @mSolde_Impots = @mMontant_Total_A_Payer_Courriel- @mSolde_Avis_Fictif
                            SET @vcMessage = REPLACE(@vcMessage,'[@mSolde_Impots]',dbo.fn_Mo_MoneyToStr(ISNULL(ABS(@mSolde_Impots),0),'FRA',1))
                        END -- IF @mSolde_Avis_Fictif <> 0 
                    END  -- IF @mMontant_Total_A_Payer_Courriel > 0      
                                                                        
                END  -- IF @vcCode_Type_Fichier = 'COT'
                 
                IF @vcCode_Type_Fichier = 'PRO' OR @vcCode_Type_Fichier = 'NOU'
                BEGIN
                            
                    select @mMontant_Total_Paiement_Courriel as '@mMontant_Total_Paiement_Courriel'
                    -- Rapport de traitement
                    SET @iNB1 = CHARINDEX('{InfoERR1}',@vcMessage)-1
                    SET @iNB2 = CHARINDEX('{InfoERR2}',@vcMessage)+10
                    SET @vcMessage = SUBSTRING(@vcMessage,1,@iNB1)+SUBSTRING(@vcMessage,@iNB2,2000)

                    -- Montant à recevoir
                    IF @mMontant_Total_Paiement_Courriel > 0 --SB 2012-11-01 OR @mMontant_Total_A_Payer_Courriel > 0
                    BEGIN
                        SET @vcMessage = REPLACE(@vcMessage,'{InfoARe1}','')
                        SET @vcMessage = REPLACE(@vcMessage,'{InfoARe2}','')
                        SET @vcMessage = REPLACE(@vcMessage,'[dtDate_Paiement]',
                                                    CONVERT(VARCHAR(10),ISNULL(@dtDate_Paiement_Courriel,0),120))
                        SET @vcMessage = REPLACE(@vcMessage,'[mMontant_Paiement]',dbo.fn_Mo_MoneyToStr(ISNULL(@mMontant_Total_Paiement_Courriel,0),'FRA',1))

                        IF @mMontant_Total_Paiement_Courriel > 0
                        BEGIN
                            SET @vcMessage = REPLACE(@vcMessage,'[ActARe1]','')

                            IF @bAvertissements = 1 OR @mMontant_Total_A_Payer_Courriel > 0
                                SET @vcMessage = REPLACE(@vcMessage,'[ActARe2]','  ')
                            ELSE
                                SET @vcMessage = REPLACE(@vcMessage,'[ActARe2]','')
                        END  -- IF @mMontant_Total_Paiement_Courriel > 0
                    END 
                    ELSE  -- ELSE 
                    BEGIN
                        SET @iNB1 = CHARINDEX('{InfoARe1}',@vcMessage)-1
                        SET @iNB2 = CHARINDEX('{InfoARe2}',@vcMessage)+10
                        SET @vcMessage = SUBSTRING(@vcMessage,1,@iNB1)+SUBSTRING(@vcMessage,@iNB2,2000)
                    END

                    -- Montant à payer
                    IF @mMontant_Total_A_Payer_Courriel > 0
                    BEGIN
                        SET @vcMessage = REPLACE(@vcMessage,'{InfoAPa1}','')
                        SET @vcMessage = REPLACE(@vcMessage,'{InfoAPa2}','')
                        SET @vcMessage = REPLACE(@vcMessage,'[mMontant_A_Payer]',dbo.fn_Mo_MoneyToStr(ISNULL(@mMontant_Total_A_Payer_Courriel,0),'FRA',1))

                        SET @vcMessage = REPLACE(@vcMessage,'[ActAPa1]','')
                        IF @bAvertissements = 1
                            SET @vcMessage = REPLACE(@vcMessage,'[ActAPa2]','  ')
                        ELSE
                            SET @vcMessage = REPLACE(@vcMessage,'[ActAPa2]','')
                    END
                    ELSE
                    BEGIN
                        SET @iNB1 = CHARINDEX('{InfoAPa1}',@vcMessage)-1
                        SET @iNB2 = CHARINDEX('{InfoAPa2}',@vcMessage)+10
                        SET @vcMessage = SUBSTRING(@vcMessage,1,@iNB1)+SUBSTRING(@vcMessage,@iNB2,2000)
                    END  --IF @mMontant_Total_A_Payer_Courriel > 0
                END 

                IF @bAvertissements = 1
                BEGIN
                    SET @vcMessage = REPLACE(@vcMessage,'[ActAvr1]','')
                    SET @vcMessage = REPLACE(@vcMessage,'[ActAvr2]','')
                END
            END 
            ELSE
            BEGIN
                -- Le traitement a échoué
                SET @vcMessage = REPLACE(@vcMessage,'[vcMessEch1]','')
                SET @vcMessage = REPLACE(@vcMessage,'[vcMessEch2]','')
                SET @iNB1 = CHARINDEX('[vcMessNor1]',@vcMessage)-1
                SET @iNB2 = CHARINDEX('[vcMessNor2]',@vcMessage)+12
                SET @vcMessage = SUBSTRING(@vcMessage,1,@iNB1)+SUBSTRING(@vcMessage,@iNB2,2000)

                SET @iNB1 = CHARINDEX('{Info1}',@vcMessage)-1
                SET @iNB2 = CHARINDEX('{Info2}',@vcMessage)+7
                SET @vcMessage = SUBSTRING(@vcMessage,1,@iNB1)+SUBSTRING(@vcMessage,@iNB2,2000)

                SET @vcMessage = REPLACE(@vcMessage,'[ActBug1]','')
                SET @vcMessage = REPLACE(@vcMessage,'[ActBug2]','')
            END

            -- Retrait des messages pas utilisés
            IF CHARINDEX('[ActGra1]',@vcMessage) > 0
            BEGIN
                SET @iNB1 = CHARINDEX('[ActGra1]',@vcMessage)-1
                SET @iNB2 = CHARINDEX('[ActGra2]',@vcMessage)+9
                SET @vcMessage = SUBSTRING(@vcMessage,1,@iNB1)+SUBSTRING(@vcMessage,@iNB2,2000)
            END
            IF CHARINDEX('[ActErr1]',@vcMessage) > 0
            BEGIN
                SET @iNB1 = CHARINDEX('[ActErr1]',@vcMessage)-1
                SET @iNB2 = CHARINDEX('[ActErr2]',@vcMessage)+9
                SET @vcMessage = SUBSTRING(@vcMessage,1,@iNB1)+SUBSTRING(@vcMessage,@iNB2,2000)
            END
            IF CHARINDEX('[ActARe1]',@vcMessage) > 0
            BEGIN
                SET @iNB1 = CHARINDEX('[ActARe1]',@vcMessage)-1
                SET @iNB2 = CHARINDEX('[ActARe2]',@vcMessage)+9
                SET @vcMessage = SUBSTRING(@vcMessage,1,@iNB1)+SUBSTRING(@vcMessage,@iNB2,2000)
            END
            IF CHARINDEX('[ActAPa1]',@vcMessage) > 0
            BEGIN
                SET @iNB1 = CHARINDEX('[ActAPa1]',@vcMessage)-1
                SET @iNB2 = CHARINDEX('[ActAPa2]',@vcMessage)+9
                SET @vcMessage = SUBSTRING(@vcMessage,1,@iNB1)+SUBSTRING(@vcMessage,@iNB2,2000)
            END
            IF CHARINDEX('[ActBug1]',@vcMessage) > 0
            BEGIN
                SET @iNB1 = CHARINDEX('[ActBug1]',@vcMessage)-1
                SET @iNB2 = CHARINDEX('[ActBug2]',@vcMessage)+9
                SET @vcMessage = SUBSTRING(@vcMessage,1,@iNB1)+SUBSTRING(@vcMessage,@iNB2,2000)
            END
            IF CHARINDEX('[ActAvr1]',@vcMessage) > 0
            BEGIN
                SET @iNB1 = CHARINDEX('[ActAvr1]',@vcMessage)-1
                SET @iNB2 = CHARINDEX('[ActAvr2]',@vcMessage)+9
                SET @vcMessage = SUBSTRING(@vcMessage,1,@iNB1)+SUBSTRING(@vcMessage,@iNB2,2000)
            END

            SET @vcMessage = REPLACE(@vcMessage,'[CH13]',CHAR(13))
            SET @vcMessage = REPLACE(@vcMessage,'[CH9]',CHAR(9))

            -- Envoyer le courriel
            EXECUTE msdb.dbo.sp_send_dbmail @recipients = @vcCourrielsDestination, @body = @vcMessage, @subject = @vcSujet;
        END TRY
        BEGIN CATCH
        END CATCH
    END

    -- Retourner le code de retour
    RETURN @iCode_Retour
END

