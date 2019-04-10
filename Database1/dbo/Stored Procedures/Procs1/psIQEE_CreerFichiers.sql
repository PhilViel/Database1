/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service        : psIQEE_CreerFichiers
Nom du service        : Créer des fichiers de transactions
But                 : Créer un ou plusieurs nouveaux fichiers de transactions pour l’IQÉÉ.
Facette                : IQÉÉ

Paramètres d’entrée    :    Paramètre                    Description
                        --------------------------    -----------------------------------------------------------------
                        bExecution_Differee            Indicateur que les paramètres d’appel du service sont présent dans
                                                    les paramètres applicatifs.  Ce paramètre est requis.  S’il est
                                                    égal à 0, les paramètres passés sont considérés être les paramètres
                                                    du service.  S’il est égal à 1, les paramètres passés sont ignorés
                                                    et les paramètres sont lus directement du système des paramètres
                                                    applicatifs.
                        siAnnee_Fiscale_Debut        Année fiscale de début des fichiers de transactions à créer.  Ce
                                                    paramètre est requis.  L’année fiscale doit être plus grande ou
                                                    égale à 2007.
                        siAnnee_Fiscale_Fin            Année fiscale de fin des fichiers de transactions à créer.  S’il
                                                    est absent, considérer que l’année fiscale de fin est la même que
                                                    l’année fiscale de début.  L’année fiscale de fin doit être plus
                                                    grande ou égale à l’année fiscale de début.  L’année fiscale doit
                                                    être plus grande ou égale à 2007.
                        bPremier_Envoi_Originaux    Indicateur pour traiter seulement les transactions originales (pas les annulations)
                                                    dans le cas du premier envoi trimestriel de l'année.
                        bFichier_Test                Indicateur si le fichier est crée pour fins d’essais ou si c’est
                                                    un fichier réel.  0=Fichier réel, 1=Fichier test.  S’il est absent,
                                                    considérer que c’est un fichier test.
                        bDenominalisation            Indicateur de retrait des noms dans le fichier des demandes.  
                                                    S’applique uniquement pour les fichiers tests.  Les tables des
                                                    types d’enregistrement contiennent les vrais noms et prénoms, mais
                                                    le fichier physique des transactions contiendra « Universitas » en
                                                    remplacement.  S’il est absent, il n’y a pas de dénominalisation.
                        vcCode_Simulation            Le code de simulation est au choix du programmeur.  Il permet
                                                    d’associer un code à un ou plusieurs fichiers de transactions.  
                                                    Si ce paramètre est présent, le fichier est automatiquement considéré
                                                    comme  un fichier test et comme un fichier de simulation.  Les
                                                    fichiers de test qui ne sont pas des simulations sont visibles aux
                                                    utilisateurs.  Par contre, les fichiers de simulation ne sont pas
                                                    visibles aux utilisateurs.  Ils sont accessibles seulement aux
                                                    programmeurs.
                        iID_Convention                Identifiant unique de la convention pour laquelle la création des
                                                    fichiers est demandée.  La convention doit exister.
                        vcChemin_Fichier            Chemin du répertoire dans lequel sera déposé le fichier des
                                                    transactions.  Paramètre optionnel.  S’il n’est pas présent, le fichier 
                                                    physique ne sera pas crée.
                        bArretPremiereErreur        Indicateur si le traitement doit s’arrêter après le premier message
                                                    d’erreur.  S’il est absent, les validations n’arrêtent pas à la première
                                                    erreur.
                        cCode_Portee                Code permettant de définir la portée des validations.
                                                    « T » =  Toutes les validations
                                                    « A » = Toutes les validations excepter les avertissements (Erreurs
                                                            seulement)
                                                    « I » = Uniquement les validations sur lesquelles il est possible
                                                            d’intervenir afin de les corriger
                                                    S’il est absent, toutes les validations sont considérées.
                        iID_Utilisateur_Creation    Identifiant de l’utilisateur qui demande la création du fichier.  S’il
                                                    est absent, considérer l’utilisateur système.
                        vcCourrielsDestination        Liste des courriels qui devront recevoir un courriel de confirmation du
                                                    résultat du traitement.  S’il n’est pas spécifié, il n'y a pas de courriel.
                        bTraiterAnnulations            Indicateur si la création du fichier doit traiter ou non les annulations
                            Manuelles                demandées manuellement.  S'il n'est pas spécifié, les annulations
                                                    manuelles sont traitées.
                        bTraiterAnnulations            Indicateur si la création du fichier doit traiter ou non les annulations
                            Automatiques            déterminées automatiquement.  S'il n'est pas spécifié, les annulations
                                                    automatiques sont traitées.
                        cID_Langue                    Langue du traitement.  Le français est considéré par défaut s'il n'est
                                                    pas spécifié.
                        bit_CasSpecial                Indicateur pour permettre la résolution de cas spéciaux sur des T02 dont le délai de traitement est dépassé. 
                        ListeNoConventions            Contient la liste des nos de convention à générer les déclarations
                                                        (optionel & les numéros doivent être séparés par une virgule)

Exemple d’appel        :    EXECUTE [dbo].[psIQEE_CreerFichiers] 0, 2007, 2008, 0, NULL, NULL, NULL, NULL, NULL,
                                                             '\\gestas2\departements\IQEE\Fichiers\Transmis\', NULL, NULL,
                                                             519626, NULL, NULL, NULL, NULL

Paramètres de sortie:    Table                        Champ                            Description
                          -------------------------    ---------------------------     ---------------------------------
                        S/O                            iCode_Retour                    >= 0 = Traitement terminé normalement,
                                                                                           nombre de fichiers crées.
                                                                                    -1 = Erreur dans les paramètres

Historique des modifications:
        Date        Programmeur                Description                                
        ----------  --------------------    -----------------------------------------
        2009-01-29  Éric Deshaies           Création du service                            
        2012-06-11  Éric Michaud            Modification projet septembre 2012                    
        2012-08-27  Stéphane Barbeau        Ajustements rapports de création
        2012-08-28  Stéphane Barbeau        Ajustement détail année fiscale pour psIQEE_PayerIQEE_ImpotsSpeciaux.
        2012-12-07  Stéphane Barbeau        Désactivation de l'appel de la stored proc psIQEE_PayerIQEE_ImpotsSpeciaux.
        2013-02-20  Stéphane Barbeau        Ajustements des calculs des requêtes sur les impôts spéciaux 01, 22, 23 et 91 pour totaliser dans le courriel.
        2013-02-22  Stéphane Barbeau        Désactivation création physique des fichiers et envoi du courriel
        2013-03-25  Stéphane Barbeau        Réactivation appel psIQEE_CreerLignesFichier
        2013-09-23  Stéphane Barbeau        Réactivation appel psIQEE_CreerPhysiquementFichier
        2014-02-24  Stéphane Barbeau        Ajout du paramètre @bPremier_Envoi_Originaux.
        2014-02-25  Stéphane Barbeau        Ajustement des appels de fntIQEE_RechercherErreurs pour cumuler toutes les erreurs.
        2014-02-28  Stéphane Barbeau        Ajout du paramètre @bPremier_Envoi_Originaux dans l'appel psIQEE_CreerFichierAnnee.
        2014-03-21  Stéphane Barbeau        Ajustement valeur @iCode_Retour pour éviter de retourner NULL.
        2014-08-06  Stéphane Barbeau        Ajout du paramètre @bit_CasSpecial pour permettre la résolution de cas spéciaux sur des T02 dont le délai de traitement est dépassé. 
        2015-03-21  Stéphane Barbeau        Devancer l'instruction COMMIT TRANSACTION avant la création des fichiers logiques et physiques afin de conserver les transactions de demandes T*.
        2016-01-08  Steeve Picard           Ne plus rendre les erreur «À traiter» en «Traitée - A retourner» pour les type «06»
        2016-02-01  Steeve Picard           Permettre d'exécuter pour une liste de nos de convention
        2016-04-08  Steeve Picard           Correction pour le contenu des conventions dans #TB_ListeConvention
        2016-04-29  Steeve Picard           Ne plus rendre les erreur «À traiter» en «Traitée - A retourner» pour les type «04 & 05»
        2016-06-15  Steeve Picard           Optimisation des requêtes
        2017-06-08  Steeve Picard           Changement au niveau d'un des paramètres de « psIQEE_CreerLignesFichier » pour utiliser le ID du fichier
        2017-07-10  Steeve Picard           Autoriser seulement la création de T02 des 3 dernières années et depuis 2007 pour toutes les autres
        2017-07-10  Steeve Picard           Ne plus filtrer les conventions à partir d'ici, la table « #TB_ListeConvention » sera utilisé qu'à partir de « psIQEE_CreerFichierAnnee »
        2017-07-12  Steeve Picard           Ajout du paramètre « @vcNom_Fichier » lors de l'appel à « psIQEE_CreerPhysiquementFichier »
        2017-08-15  Steeve Picard           Rendre à nouveau les erreur «À traiter» en «Traitée - A retourner» pour les type «06»
        2017-09-14  Steeve Picard           Modification des paramètres de «fnIQEE_FormaterChamp»
        2018-02-08  Steeve Picard           Déplacement de «siAnnee_Fiscale» de la table «tblIQEE_Fichiers» vers les tables d'évèments
        2018-06-06  Steeve Picard           Modificiation de la gestion des retours d'erreur par RQ
        2018-07-09  Steeve Picard           Ajout du paramètre «@vcCode_ListeTransaction» pour sélectionner que quelques types de déclaration à RQ, si NULL alors tous
***********************************************************************************************************************/
CREATE PROCEDURE dbo.psIQEE_CreerFichiers
(
    @bExecution_Differee BIT,
    @siAnnee_Fiscale_Fin SMALLINT,
    @bPremier_Envoi_Originaux BIT,
    @bFichier_Test BIT,
    @bDenominalisation BIT,
    @vcCode_Simulation VARCHAR(100),
    @vcNo_ConventionListe varchar(MAX),
    @vcChemin_Fichier VARCHAR(150),
    @bArretPremiereErreur BIT,
    @cCode_Portee CHAR(1),
    @iID_Utilisateur_Creation INT,
    @vcCourrielsDestination VARCHAR(200),
    @bTraiterAnnulationsManuelles BIT,
    @bTraiterAnnulationsAutomatiques BIT,
    @cID_Langue CHAR(3),
    @bit_CasSpecial BIT,
    @vcCode_ListeTransaction AS VARCHAR(200) = ''
)
AS
BEGIN
    DECLARE @iCode_Retour INT,
            @iID_Session INT,
            @siAnnee_Fiscale_Debut smallint = @siAnnee_Fiscale_Fin - 2,
            @dtDate_Creation_Fichiers DATETIME,
            @siAnnee_Fiscale SMALLINT,
            @siAnnee_FiscaleMax SMALLINT,
            @vcNom_Rapport_Creation VARCHAR(200),
            --@vcNo_Convention VARCHAR(15) = (SELECT ConventionNo FROM dbo.Un_Convention WHERE ConventionID = @iID_Convention),
            @vcNom_Utilisateur VARCHAR(100),
            @dtDate_Creation DATETIME,
            @iNombre_Transactions INT,
            @vcNEQ_GUI VARCHAR(10) = (SELECT TOP 1 D.vcNEQ_GUI FROM Un_Def D),
            @iResultat INT,
            @vcNom_Fichier_Complet VARCHAR(200),
            @bFichier_Physique_Cree BIT,
            @dtTotal DATETIME,
            @vcMessage VARCHAR(MAX),
            @vcSujet VARCHAR(MAX),
            @iNB1 INT,
            @iNB2 INT,
            @iID_Fichier INT,
            @iID_Fichier_IQEE INT,
            @bConsequence_Annulation BIT,
            @vcNom_Fichier VARCHAR(50),
            @vcTMP VARCHAR(200),
            @tiID_Statuts_Erreur TINYINT,
            @tiID_Statuts_Erreur_ATR TINYINT,
            @iID_Utilisateur_Modification INT,
            @iID_Erreur INT,
            @vctrans_remp_bene VARCHAR(25),
            @iNombre_01 int,
            @mMontant_01 money,
            @iNombre_91 int,
            @mMontant_91 money,
            @mMontant_Radiation_91 money,
            @iNombre_22 int,
            @mMontant_22 money,
            @iNombre_23 int,
            @iNombre_temp int,
            @mMontant_temp money,
            @iNombre_03 int,
            @vcnb_demande VARCHAR(25),
            @vcnb_total VARCHAR(25)
    
    SET @iCode_Retour = 0
    SET @dtTotal = GETDATE()
    SET @vcNom_Rapport_Creation = NULL

    -- Créer une table temporaire pour le rapport de création
    IF OBJECT_ID(N'tempDB..##tblIQEE_RapportCreation') IS NOT NULL
        DROP TABLE ##tblIQEE_RapportCreation

    CREATE TABLE ##tblIQEE_RapportCreation (
        cSection CHAR(1) NOT NULL,
        iSequence INT NOT NULL,
        vcMessage VARCHAR(2000) NOT NULL
    )

    BEGIN TRANSACTION

    BEGIN TRY

    ------------------------------------
    -- Obtenir et valider les paramètres
    ------------------------------------

    -- Lors d'une exécution en différée (asynchrone) via l’interface utilisateur, prendre les paramètres du service dans les
    -- paramètres applicatifs
    IF @bExecution_Differee = 1
        SELECT  @siAnnee_Fiscale_Debut = CAST(dbo.fnGENE_ObtenirParametre('IQEE_CREER_FICHIERS_siAnnee_Fiscale_Debut',
                                                                          NULL,NULL,NULL,NULL,NULL,NULL) AS SMALLINT),
                @siAnnee_Fiscale_Fin = CAST(dbo.fnGENE_ObtenirParametre('IQEE_CREER_FICHIERS_siAnnee_Fiscale_Fin',
                                                                        NULL,NULL,NULL,NULL,NULL,NULL) AS SMALLINT),
                @vcNo_ConventionListe = CAST(dbo.fnGENE_ObtenirParametre('IQEE_CREER_FICHIERS_iID_Convention',
                                                                    NULL,NULL,NULL,NULL,NULL,NULL) AS INT),
                @bFichier_Test = CAST(dbo.fnGENE_ObtenirParametre('IQEE_CREER_FICHIERS_bFichier_Test',
                                                                  NULL,NULL,NULL,NULL,NULL,NULL) AS BIT),
                @vcChemin_Fichier = dbo.fnGENE_ObtenirParametre('IQEE_CREER_FICHIERS_vcChemin_Fichier',
                                                                NULL,NULL,NULL,NULL,NULL,NULL),
                @vcCourrielsDestination = dbo.fnGENE_ObtenirParametre('IQEE_CREER_FICHIERS_vcCourrielsDestination',
                                                                      NULL,NULL,NULL,NULL,NULL,NULL),
                @iID_Utilisateur_Creation = CAST(dbo.fnGENE_ObtenirParametre('IQEE_CREER_FICHIERS_iID_Utilisateur_Creation',
                                                                             NULL,NULL,NULL,NULL,NULL,NULL) AS INT),
                @cID_Langue = dbo.fnGENE_ObtenirParametre('IQEE_CREER_FICHIERS_cID_Langue',NULL,NULL,NULL,NULL,NULL,NULL),
                @bTraiterAnnulationsManuelles = CAST(dbo.fnGENE_ObtenirParametre(
                                                     'IQEE_CREER_FICHIERS_bTraiterAnnulationsManuelles',
                                                     NULL,NULL,NULL,NULL,NULL,NULL) AS BIT),
                @bTraiterAnnulationsAutomatiques = CAST(dbo.fnGENE_ObtenirParametre(
                                                        'IQEE_CREER_FICHIERS_bTraiterAnnulationsAutomatiques',
                                                        NULL,NULL,NULL,NULL,NULL,NULL) AS BIT),
                @bDenominalisation = NULL,
                @vcCode_Simulation = NULL,
                @bArretPremiereErreur = NULL,
                @cCode_Portee = NULL
        
    -- Considérer l'année fiscale de début comme année fiscale de fin lorsqu'elle est absente
    IF @siAnnee_Fiscale_Fin IS NULL 
        SET @siAnnee_Fiscale_Fin = @siAnnee_Fiscale_Debut

    -- Valider les paramètres
    IF @siAnnee_Fiscale_Debut IS NULL OR
       @siAnnee_Fiscale_Debut < 2007 OR
       @siAnnee_Fiscale_Fin < 2007 OR
       @siAnnee_Fiscale_Fin < @siAnnee_Fiscale_Debut OR
       @siAnnee_Fiscale_Fin > YEAR(GETDATE())
        RETURN -1

    -- Considérer le français comme langue de défaut
    IF @cID_Langue IS NULL
        SET @cID_Langue = 'FRA'

    -- Considérer un fichier test si ce n'est pas spécifié   
    IF @bFichier_Test IS NULL
        SET @bFichier_Test = 1
    
    -- Considérer comme un fichier test les simulations
    IF @vcCode_Simulation IS NOT NULL
        SET @bFichier_Test = 1

    -- Traiter les annulations manuelles si ce n'est pas spécifié   
    IF @bTraiterAnnulationsManuelles IS NULL OR @bFichier_Test = 0
        SET @bTraiterAnnulationsManuelles = 1

    -- Traiter les annulations automatiques si ce n'est pas spécifié   
    IF @bTraiterAnnulationsAutomatiques IS NULL OR @bFichier_Test = 0
        SET @bTraiterAnnulationsAutomatiques = 1

    -- S'assurer que la denominalisation s'applique uniquement aux fichiers tests
    IF @bDenominalisation IS NULL OR
       (@bDenominalisation = 1 AND @bFichier_Test = 0)
        SET @bDenominalisation = 0

    -- Considérer de ne pas arrêter les validations à la première erreur si ce n'est pas spécifié
    IF @bArretPremiereErreur IS NULL
        SET @bArretPremiereErreur = 0

    -- Considérer toutes les validations si ce n'est pas spécifié
    IF @cCode_Portee IS NULL
        SET @cCode_Portee = 'T'

    -- Prendre l'utilisateur du système s'il est absent en paramètre ou inexistant
    IF @iID_Utilisateur_Creation IS NULL OR
       NOT EXISTS (SELECT * FROM Mo_User WHERE UserID = @iID_Utilisateur_Creation) 
        SELECT TOP 1 @iID_Utilisateur_Creation = iID_Utilisateur_Systeme
        FROM Un_Def

    -- Compléter le nom du chemin des fichiers physiques
    IF @vcChemin_Fichier = ''
        SET @vcChemin_Fichier = NULL

    IF @vcChemin_Fichier IS NOT NULL
        IF SUBSTRING(@vcChemin_Fichier,LEN(@vcChemin_Fichier),1) <> '\'
            SET @vcChemin_Fichier = @vcChemin_Fichier + '\'

    -- Corriger le destinataire
    IF @vcCourrielsDestination = ''
        SET @vcCourrielsDestination = NULL

    -------------------------------------------------------------------------------
    --  Définir une clé unique de la création des fichiers logiques de transactions
    -------------------------------------------------------------------------------
    SET @iID_Session = @@SPID
    SET @dtDate_Creation_Fichiers = GETDATE()
    -------------------------------------------------------------------------------

    -- Définir le nom du rapport de création
    -- Note: Les ":" ne sont pas permis dans les noms de fichier sur disque
    SET @vcNom_Rapport_Creation = @vcChemin_Fichier+REPLACE(REPLACE(CONVERT(VARCHAR(20),@dtDate_Creation_Fichiers,120),':','-'),' ','_')+'.txt'

    -- Préparer les entêtes du rapport de création
-- TODO: Temporairement, faire un rapport de création sur les fichiers de simulation
--        IF @vcCode_Simulation IS NULL
--            BEGIN
            SELECT @vcNom_Utilisateur = FirstName + ' ' + LastName
            FROM dbo.Mo_Human 
            WHERE HumanID = @iID_Utilisateur_Creation

            INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
            VALUES ('1',1,'-----------------------------------------------')
            INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
            VALUES ('1',2,'RAPPORT DE CRÉATION DE FICHIERS DE TRANSACTIONS')
            INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
            VALUES ('1',3,'-----------------------------------------------')
            INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
            VALUES ('1',4,' ')
            INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
            VALUES ('1',5,'Paramètres:')
            IF @bExecution_Differee = 1
                INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
                VALUES ('1',6,'       Exécution différée: Oui')
            ELSE
                INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
                VALUES ('1',6,'       Exécution différée: Non')
            --INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
            --VALUES ('1',7,'       Année fiscale de début: '+CAST(@siAnnee_Fiscale_Debut AS VARCHAR))
            INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
            VALUES ('1',8,'       Année fiscale de fin: '+CAST(@siAnnee_Fiscale_Fin AS VARCHAR))

            IF @vcNo_ConventionListe IS NOT NULL
                INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
                VALUES ('1',9,'       #Convention: '+@vcNo_ConventionListe)

            IF @bFichier_Test = 0
                INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
                VALUES ('1',10,'       Type de fichier: Production')
            ELSE
                BEGIN
                    INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
                    VALUES ('1',10,'       Type de fichier: Test')

                    IF @bFichier_Test = 0
                        INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
                        VALUES ('1',11,'              Tenir compte des fichiers test: Non')
                    ELSE
                        INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
                        VALUES ('1',11,'              Tenir compte des fichiers test: Oui')

                    IF @bDenominalisation = 0
                        INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
                        VALUES ('1',12,'              Dénominalisation: Non')
                    ELSE
                        INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
                        VALUES ('1',12,'              Dénominalisation: Oui')

                    IF @bTraiterAnnulationsManuelles = 0
                        INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
                        VALUES ('1',13,'              Traiter les demandes d’annulation manuelles: Non')
                    ELSE
                        INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
                        VALUES ('1',13,'              Traiter les demandes d’annulation manuelles: Oui')

                    IF @bTraiterAnnulationsAutomatiques = 0
                        INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
                        VALUES ('1',14,'              Traiter les demandes d’annulation automatiques: Non')
                    ELSE
                        INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
                        VALUES ('1',14,'              Traiter les demandes d’annulation automatiques: Oui')
                END

            IF @bArretPremiereErreur = 0
                INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)    
                VALUES ('1',15,'       Arret du traitement à la première erreur: Non')
            ELSE
                INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)    
                VALUES ('1',15,'       Arret du traitement à la première erreur: Oui')

            INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
            VALUES ('1',16,'       Code de portée des validations: '+@cCode_Portee)

            INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
            VALUES ('1',17,'       Répertoire de destination: '+@vcChemin_Fichier)
            INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
            VALUES ('1',18,'       Destinataires courriels: '+ISNULL(@vcCourrielsDestination,''))
            INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
            VALUES ('1',19,'       Code de langue: '+@cID_Langue)
            INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)    
            VALUES ('1',20,'       Demandé par: '+@vcNom_Utilisateur+' ('+CAST(@iID_Utilisateur_Creation AS VARCHAR)+')')
            INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)    
            VALUES ('1',21,'       Serveur SQL: '+@@servername)
            INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)    
            VALUES ('1',22,'       Base de données: '+DB_NAME())
            INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
            VALUES ('2',1,' ')
            INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
            VALUES ('2',2,'Messages:')
            INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
            VALUES ('3',1,' ')
            INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
            VALUES ('3',2,'Traces:')
            INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
            VALUES ('3',3,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CreerFichiers                   -'+
                          ' Début du traitement')
-- TODO: Temporairement, faire un rapport de création sur les fichiers de simulation
--            END

    INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
    VALUES ('2',10,'       ID de session: '+CAST(@iID_Session AS VARCHAR))
    INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
    VALUES ('2',20,'       Date de création de l''ensemble des fichiers: '+CONVERT(VARCHAR(25),@dtDate_Creation_Fichiers,121))
    INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
    VALUES ('2',30,' ')

    ----------------------------------------------------------------------------------------------------------------------------------
    -- Considérer comme "Traitée - A retourner" les erreurs RQ qui font partie des catégories pour les TI ainsi que les erreurs RQ qui
    -- font partie des catégories des opérations si le type d'erreur RQ permet de les considérer comme traitées.
    ----------------------------------------------------------------------------------------------------------------------------------
    -- Déterminer les codes de statut de l'erreur

    SELECT @tiID_Statuts_Erreur = SE.tiID_Statuts_Erreur
    FROM tblIQEE_StatutsErreur SE
    WHERE SE.vcCode_Statut = 'ATR'

    -- Rechercher les erreurs à considérer comme "Traitée - A retourner"
--    tiID_Type_Enregistrement    cCode_Type_Enregistrement    vcDescription
--            1                            02                        Demande de l'IQÉÉ
--            2                            03                        Remplacement de bénéficiaire
--            3                            04                        Transfert entre régimes
--            4                            05                        Paiement au bénéficiaire
--            5                            06                        Déclaration d'impôt spécial
    
    DECLARE curErreursATR CURSOR LOCAL FAST_FORWARD FOR
        SELECT E.iID_Erreur
        FROM dbo.fntIQEE_RechercherErreurs(NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, @tiID_Statuts_Erreur, NULL) E
             JOIN tblIQEE_CategoriesErreur CE ON CE.tiID_Categorie_Erreur = E.tiID_Categorie_Erreur
             JOIN tblIQEE_TypesErreurRQ TE ON TE.siCode_Erreur = E.siCode_Erreur
             JOIN dbo.vwIQEE_Enregistrement_TypeEtSousType TST ON TST.tiID_Type_Enregistrement = E.tiID_Type_Enregistrement
        WHERE (CE.vcCode_Categorie IN ('TI','TI2') OR TE.bConsiderer_Traite_Creation_Fichiers = 1)
          AND TST.cCode_Type_Enregistrement IN ('02')
        --UNION
        
        --SELECT E.iID_Erreur
        --FROM dbo.fntIQEE_RechercherErreurs(NULL, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, @tiID_Statuts_Erreur, NULL) E
        --     JOIN tblIQEE_CategoriesErreur CE ON CE.tiID_Categorie_Erreur = E.tiID_Categorie_Erreur
        --     JOIN tblIQEE_TypesErreurRQ TE ON TE.siCode_Erreur = E.siCode_Erreur
        --WHERE CE.vcCode_Categorie IN ('TI','TI2')
        --   OR TE.bConsiderer_Traite_Creation_Fichiers = 1
               
        --UNION
        
        --SELECT E.iID_Erreur
        --FROM dbo.fntIQEE_RechercherErreurs(NULL, NULL, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, @tiID_Statuts_Erreur, NULL) E
        --     JOIN tblIQEE_CategoriesErreur CE ON CE.tiID_Categorie_Erreur = E.tiID_Categorie_Erreur
        --     JOIN tblIQEE_TypesErreurRQ TE ON TE.siCode_Erreur = E.siCode_Erreur
        --WHERE CE.vcCode_Categorie IN ('TI','TI2')
        --   OR TE.bConsiderer_Traite_Creation_Fichiers = 1
        
        --UNION
        
        --SELECT E.iID_Erreur
        --FROM dbo.fntIQEE_RechercherErreurs(NULL, NULL, 4, NULL, NULL, NULL, NULL, NULL, NULL, NULL, @tiID_Statuts_Erreur, NULL) E
        --     JOIN tblIQEE_CategoriesErreur CE ON CE.tiID_Categorie_Erreur = E.tiID_Categorie_Erreur
        --     JOIN tblIQEE_TypesErreurRQ TE ON TE.siCode_Erreur = E.siCode_Erreur
        --WHERE CE.vcCode_Categorie IN ('TI','TI2')
        --   OR TE.bConsiderer_Traite_Creation_Fichiers = 1
               
        --UNION

        --SELECT E.iID_Erreur --, E.vcNo_Convention, CE.vcCode_Categorie, TE.bConsiderer_Traite_Creation_Fichiers
        --FROM dbo.fntIQEE_RechercherErreurs(NULL, NULL, 5, NULL, NULL, NULL, NULL, NULL, NULL, NULL, @tiID_Statuts_Erreur, NULL) E
        --     JOIN tblIQEE_CategoriesErreur CE ON CE.tiID_Categorie_Erreur = E.tiID_Categorie_Erreur
        --     JOIN tblIQEE_TypesErreurRQ TE ON TE.siCode_Erreur = E.siCode_Erreur
        --WHERE CE.vcCode_Categorie IN ('TI','TI2')
        --   OR TE.bConsiderer_Traite_Creation_Fichiers = 1
        
    -- Boucler parmis les erreurs sélectionnées
    PRINT '*****  Update Erreur statut'
    OPEN curErreursATR

    SELECT @tiID_Statuts_Erreur = SE.tiID_Statuts_Erreur
    FROM tblIQEE_StatutsErreur SE
    WHERE SE.vcCode_Statut = 'TAR'

    SELECT TOP 1 @iID_Utilisateur_Modification = D.iID_Utilisateur_Systeme
    FROM Un_Def D

    FETCH NEXT FROM curErreursATR INTO @iID_Erreur
    WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Marquer l'erreur comme "Traitée - A retourner"
            UPDATE tblIQEE_Erreurs
            SET tiID_Statuts_Erreur = @tiID_Statuts_Erreur,
                iID_Utilisateur_Traite = E.iID_Utilisateur_Modification,
                dtDate_Traite = E.dtDate_Modification,
                iID_Utilisateur_Modification = @iID_Utilisateur_Modification,
                dtDate_Modification = @dtDate_Creation_Fichiers
            FROM tblIQEE_Erreurs E
            WHERE E.iID_Erreur = @iID_Erreur

            FETCH NEXT FROM curErreursATR INTO @iID_Erreur
        END
    CLOSE curErreursATR
    DEALLOCATE curErreursATR

    ------------------------------------
    -- Traiter les demandes d'annulation
    ------------------------------------
    IF @bPremier_Envoi_Originaux = 0
    BEGIN
        -- Demander les annulations
        INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
        VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CreerFichiers                   '+
                '- Traiter demandes d''annulation.  Appel "psIQEE_DemanderAnnulations"')

        IF (@bTraiterAnnulationsAutomatiques = 1 OR @bTraiterAnnulationsManuelles = 1) 
            EXECUTE dbo.psIQEE_DemanderAnnulations @siAnnee_Fiscale_Debut, @siAnnee_Fiscale_Fin, @bPremier_Envoi_Originaux,@vcCode_Simulation,
                                                    @bTraiterAnnulationsManuelles, @bTraiterAnnulationsAutomatiques, @iID_Session, 
                                                    @dtDate_Creation_Fichiers, @iID_Utilisateur_Creation, @bFichier_Test, @bit_CasSpecial
    END
    -----------------------------------------
    -- Identifier les années fiscales à créer 
    -----------------------------------------
    INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
    VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CreerFichiers                   '+
            '- Identifier années fiscales à créer')

    -- Créer une table temporaire des années fiscales de la création des fichiers logiques
    CREATE TABLE #tblIQEE_AnneesFiscales
       (siAnnee_Fiscale SMALLINT NOT NULL,
        bConsequence_Annulation BIT NOT NULL,
        iID_Fichier_IQEE INT NULL,
        iNombre_Transactions INT NULL,
        bFichier_Physique_Cree BIT NULL)

    CREATE TABLE #tblIQEE_ConsequenceAnnulation (
        siAnnee_Fiscale SMALLINT NOT NULL,
        iID_Convention INT NOT NULL,
        vcNo_Convention varchar(15),
        tiID_Type_Enregistrement INT,
        cCode_Type_Enregistrement varchar(5)
    )

    -- Insérer les années fiscales demandées par l'utilisateur
    SET @siAnnee_Fiscale = 2007 --@siAnnee_Fiscale_Debut
    IF dbo.fn_IsDebug() <> 0
        SET @siAnnee_Fiscale = @siAnnee_Fiscale_Debut
    PRINT 'debug @siAnnee_Fiscale_Debut : ' + convert(varchar, @siAnnee_Fiscale_Debut, 120)
    WHILE @siAnnee_Fiscale <= @siAnnee_Fiscale_Fin
        BEGIN
            INSERT INTO #tblIQEE_AnneesFiscales (siAnnee_Fiscale, bConsequence_Annulation)
            VALUES (@siAnnee_Fiscale, 0)

            SET @siAnnee_Fiscale = @siAnnee_Fiscale + 1
        END    

    -- Insérer les années fiscales qui sont la conséquence d'annulations/reprises de transactions
    IF @bTraiterAnnulationsAutomatiques = 1 OR @bTraiterAnnulationsManuelles = 1
        BEGIN
            INSERT INTO #tblIQEE_ConsequenceAnnulation(siAnnee_Fiscale, iID_Convention, vcNo_Convention, tiID_Type_Enregistrement, cCode_Type_Enregistrement)
            SELECT D.siAnnee_Fiscale, D.iID_Convention, D.vcNo_Convention, A.tiID_Type_Enregistrement, TE.cCode_Type_Enregistrement
              FROM tblIQEE_Annulations A
                   JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
                   JOIN tblIQEE_Demandes D ON D.iID_Demande_IQEE = A.iID_Enregistrement_Demande_Annulation
                   --JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
             WHERE A.iID_Session = @iID_Session
               AND A.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers
               AND TE.cCode_Type_Enregistrement = '02'
               AND D.siAnnee_Fiscale > @siAnnee_Fiscale_Debut

            INSERT INTO #tblIQEE_ConsequenceAnnulation(siAnnee_Fiscale, iID_Convention, vcNo_Convention, tiID_Type_Enregistrement, cCode_Type_Enregistrement)
            SELECT RB.siAnnee_Fiscale, RB.iID_Convention, RB.vcNo_Convention, A.tiID_Type_Enregistrement, TE.cCode_Type_Enregistrement
              FROM tblIQEE_Annulations A
                   JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
                   JOIN tblIQEE_RemplacementsBeneficiaire RB ON RB.iID_Remplacement_Beneficiaire = A.iID_Enregistrement_Demande_Annulation
                   --JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = RB.iID_Fichier_IQEE
             WHERE A.iID_Session = @iID_Session
               AND A.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers
               AND TE.cCode_Type_Enregistrement = '03'

            INSERT INTO #tblIQEE_ConsequenceAnnulation(siAnnee_Fiscale, iID_Convention, vcNo_Convention, tiID_Type_Enregistrement, cCode_Type_Enregistrement)
            SELECT T.siAnnee_Fiscale, T.iID_Convention, T.vcNo_Convention, A.tiID_Type_Enregistrement, TE.cCode_Type_Enregistrement
              FROM tblIQEE_Annulations A
                   JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
                   JOIN tblIQEE_Transferts T ON T.iID_Transfert = A.iID_Enregistrement_Demande_Annulation
                   --JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = T.iID_Fichier_IQEE
             WHERE A.iID_Session = @iID_Session
               AND A.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers
               AND TE.cCode_Type_Enregistrement = '04'

            INSERT INTO #tblIQEE_ConsequenceAnnulation(siAnnee_Fiscale, iID_Convention, vcNo_Convention, tiID_Type_Enregistrement, cCode_Type_Enregistrement)
            SELECT PB.siAnnee_Fiscale, PB.iID_Convention, PB.vcNo_Convention, A.tiID_Type_Enregistrement, TE.cCode_Type_Enregistrement
              FROM tblIQEE_Annulations A
                   JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
                   JOIN tblIQEE_PaiementsBeneficiaires PB ON PB.iID_Paiement_Beneficiaire = A.iID_Enregistrement_Demande_Annulation
                   --JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = PB.iID_Fichier_IQEE
             WHERE A.iID_Session = @iID_Session
               AND A.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers
               AND TE.cCode_Type_Enregistrement = '05'

            INSERT INTO #tblIQEE_ConsequenceAnnulation(siAnnee_Fiscale, iID_Convention, vcNo_Convention, tiID_Type_Enregistrement, cCode_Type_Enregistrement)
            SELECT DIS.siAnnee_Fiscale, DIS.iID_Convention, DIS.vcNo_Convention, A.tiID_Type_Enregistrement, TE.cCode_Type_Enregistrement
              FROM tblIQEE_Annulations A
                   JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
                   JOIN tblIQEE_ImpotsSpeciaux DIS ON DIS.iID_Impot_Special = A.iID_Enregistrement_Demande_Annulation
                   --JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = DIS.iID_Fichier_IQEE
             WHERE A.iID_Session = @iID_Session
               AND A.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers
               AND TE.cCode_Type_Enregistrement = '06'

            -- Prendre les années fiscales des demandes d'annulation
            INSERT INTO #tblIQEE_AnneesFiscales (siAnnee_Fiscale, bConsequence_Annulation)
            SELECT DISTINCT CA.siAnnee_Fiscale, 1
              FROM #tblIQEE_ConsequenceAnnulation CA
                   LEFT JOIN #tblIQEE_AnneesFiscales AF ON AF.siAnnee_Fiscale = CA.siAnnee_Fiscale
                   -- Elle n'est pas déjà présente dans la table temporaire
             WHERE AF.siAnnee_Fiscale IS NULL
        END

    IF dbo.fn_IsDebug() <> 0
        SELECT * FROM #tblIQEE_AnneesFiscales

    ------------------------------------------------------------------------------------------
    -- Créer un fichier logique de transactions de l'IQÉÉ pour chaque année fiscale identifiée
    ------------------------------------------------------------------------------------------
    DECLARE curAnnees_Fiscales CURSOR LOCAL FAST_FORWARD FOR
        SELECT A.siAnnee_Fiscale, A.bConsequence_Annulation
        FROM #tblIQEE_AnneesFiscales A
        WHERE A.siAnnee_Fiscale < YEAR(GETDATE())
        ORDER BY A.siAnnee_Fiscale

    -- Boucler les années fiscales identifiées
    OPEN curAnnees_Fiscales
    FETCH NEXT FROM curAnnees_Fiscales INTO @siAnnee_Fiscale, @bConsequence_Annulation
    WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Créer le fichier logique des transactions de l'année fiscale
            INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
            VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CreerFichiers                   '+
                    '- Créer fichier transactions année fiscale "'+CAST(@siAnnee_Fiscale AS VARCHAR)+
                    '".  Appel "psIQEE_CreerFichierAnnee"')

            EXECUTE @iID_Fichier_IQEE = dbo.psIQEE_CreerFichierAnnee @siAnnee_Fiscale, @bPremier_Envoi_Originaux, @bFichier_Test, 
                                                                     @vcCode_Simulation, @vcNo_ConventionListe,
                                                                     @vcChemin_Fichier, @bArretPremiereErreur, @cCode_Portee,
                                                                     @iID_Utilisateur_Creation, @cID_Langue, @bConsequence_Annulation,
                                                                     @iID_Session, @dtDate_Creation_Fichiers, @bit_CasSpecial,
                                                                     @vcCode_ListeTransaction

            IF @iID_Fichier_IQEE is null
                SET @iID_Fichier_IQEE = 0
                                
            -- Mettre à jour l'identifiant dans la table temporaire des années fiscales
            UPDATE #tblIQEE_AnneesFiscales
            SET iID_Fichier_IQEE = @iID_Fichier_IQEE
            WHERE siAnnee_Fiscale = @siAnnee_Fiscale

            INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
            VALUES ('2',40,'       '+STR(@siAnnee_Fiscale,4)+'-01: ID du nouveau fichier: '+
                           CAST(@iID_Fichier_IQEE AS VARCHAR))
            INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
            VALUES ('2',40,'       '+STR(@siAnnee_Fiscale,4))

            FETCH NEXT FROM curAnnees_Fiscales INTO @siAnnee_Fiscale, @bConsequence_Annulation
        END
    CLOSE curAnnees_Fiscales
    DEALLOCATE curAnnees_Fiscales
    
    INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
    VALUES ('2',100,' ')

-- TODO: Temporaire

    ----------------------------------------------------------------------------------------------------------------------------
    -- Traiter les rejets globaux qui sont relatifs à l’ensemble des transactions créées (pas spécifique à une seule transaction)
    ----------------------------------------------------------------------------------------------------------------------------
    INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
    VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CreerFichiers                   '+
            '- Traiter rejets globaux.  Appel "psIQEE_TraiterRejetsGlobaux"')
PRINT 'psIQEE_TraiterRejetsGlobaux'
    EXECUTE dbo.psIQEE_TraiterRejetsGlobaux @iID_Session, @dtDate_Creation_Fichiers, @bFichier_Test

    -- Calculer les montants non traités directement dans les transactions
-- TODO:    Est-il possible de calculer les soldes des montants au travers toutes type de transactions?
--            Probablement à déplacer après "l'annulation des demandes d'annulations"
--            EXECUTE dbo.psIQEE_CalculerMontantsTransactions @iID_Fichier_IQEE

    ------------------------------------------------------------------------------------------
    -- Annulation des demandes d’annulations qui ne peuvent pas ou ne doivent pas s’actualiser
    ------------------------------------------------------------------------------------------
    IF @bPremier_Envoi_Originaux = 0
    BEGIN
            INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
            VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CreerFichiers                   '+
                    '- Annulation demandes d’annulations'+
                    ' qui ne peuvent ou ne doivent pas s’actualiser.  Appel "psIQEE_AnnulerTransactionsAnnulation"')
        PRINT 'psIQEE_AnnulerTransactionsAnnulation'
            EXECUTE dbo.psIQEE_AnnulerTransactionsAnnulation @iID_Session, @dtDate_Creation_Fichiers

            ----------------------------------------
            -- Compléter les annulations et reprises
            ----------------------------------------
            INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
            VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CreerFichiers                   '+
                    '- Compléter annulations/reprises.  Appel "psIQEE_CompleterTransactionsAnnulation"')
        PRINT 'psIQEE_CompleterTransactionsAnnulation'
            EXECUTE dbo.psIQEE_CompleterTransactionsAnnulation @bFichier_Test, @iID_Session, @dtDate_Creation_Fichiers

    END
--    ---------------------------------------------------------------------
--    -- Traiter les exceptions manuelles dans les données des transactions
--    ---------------------------------------------------------------------
--    INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
--    VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CreerFichiers                   '+
--            '- Exceptions manuelles données des transactions.  Appel "psIQEE_TraiterExceptionsManuellesDonneesTransactions"')
--   PRINT 'psIQEE_TraiterExceptionsManuellesDonneesTransactions'
--    EXECUTE dbo.psIQEE_TraiterExceptionsManuellesDonneesTransactions @bFichier_Test, @iID_Session, @dtDate_Creation_Fichiers

    -- Les fichiers de simulation créent toujours un fichier logique même s'il ne contient pas de transactions.
    -- Les fichiers de simulation ne sont pas crées dans le format des NID de RQ et ne sont donc pas créés physiquement
    -- sur un disque.  Les utilisateurs ne sont pas informés par courriel de la création d'un fichier de simulation.
    IF @vcCode_Simulation IS NULL
        BEGIN
            -----------------------------------
            -- Modifier les statuts des erreurs
            -----------------------------------
            INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
            VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CreerFichiers                   '+
                    '- Modifier les statuts'+
                    ' des erreurs (fichiers de production).  Appel "psIQEE_ModifierStatutErreurs"')

PRINT 'psIQEE_ModifierStatutErreurs'
            EXECUTE dbo.psIQEE_ModifierStatutErreurs @bFichier_Test, @dtDate_Creation_Fichiers

            COMMIT TRANSACTION

            --------------------------------------------------------------------
            -- Compter le nombre total de transactions de chaque fichier logique
            --------------------------------------------------------------------
            INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
            VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CreerFichiers                   '+
                    '- Compter nombre transactions de chaque fichier logique')

            UPDATE #tblIQEE_AnneesFiscales
            SET iNombre_Transactions = (SELECT COUNT(*)
                                        FROM tblIQEE_Demandes D
                                        WHERE D.iID_Fichier_IQEE = #tblIQEE_AnneesFiscales.iID_Fichier_IQEE) +
                                       (SELECT COUNT(*)
                                        FROM tblIQEE_RemplacementsBeneficiaire RB
                                        WHERE RB.iID_Fichier_IQEE = #tblIQEE_AnneesFiscales.iID_Fichier_IQEE) +
                                       (SELECT COUNT(*)
                                        FROM tblIQEE_Transferts T
                                        WHERE T.iID_Fichier_IQEE = #tblIQEE_AnneesFiscales.iID_Fichier_IQEE) +
                                       (SELECT COUNT(*)
                                        FROM tblIQEE_PaiementsBeneficiaires PB
                                        WHERE PB.iID_Fichier_IQEE = #tblIQEE_AnneesFiscales.iID_Fichier_IQEE) +
                                       (SELECT COUNT(*)
                                        FROM tblIQEE_ImpotsSpeciaux TIS
                                        WHERE TIS.iID_Fichier_IQEE = #tblIQEE_AnneesFiscales.iID_Fichier_IQEE)

            --------------------------------------------------------------------------------
            -- Annuler la création des fichiers logiques s’il n’y a pas de transaction créée
            --------------------------------------------------------------------------------
            INSERT  INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
            VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CreerFichiers                   '+
                    '- Annuler création fichiers logiques si pas de transaction')

            -- Rechercher les fichiers vides
            DECLARE curAnnees_Fiscales CURSOR LOCAL FAST_FORWARD FOR
                SELECT A.iID_Fichier_IQEE,A.siAnnee_Fiscale
                FROM #tblIQEE_AnneesFiscales A
                WHERE A.iID_Fichier_IQEE = 0
                   OR A.iNombre_Transactions = 0

            -- Boucler les fichiers à supprimer
            OPEN curAnnees_Fiscales
            FETCH NEXT FROM curAnnees_Fiscales INTO @iID_Fichier_IQEE, @siAnnee_Fiscale
            WHILE @@FETCH_STATUS = 0
                BEGIN
-- TODO: Temporairement retiré pour voir le résultat des tests
--                    -- Supprimer les rejets s'il y a lieu
--                    DELETE FROM tblIQEE_Rejets
--                    WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE
--
--                    -- Supprimer le fichier logique
--                    DELETE FROM tblIQEE_Fichiers
--                    WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE
--
--                    DELETE FROM #tblIQEE_AnneesFiscales
--                    WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE

                    INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
                    VALUES ('2',40,'       '+CAST(@siAnnee_Fiscale AS VARCHAR)+'-02: La création du fichier logique de l''année'+
                            ' fiscale "'+CAST(@siAnnee_Fiscale AS VARCHAR)+'" est annulée parce que le traitement n''a pas pû'+
                            ' générer des transactions valides.  Les rejets ont été aussi supprimés.')

                    FETCH NEXT FROM curAnnees_Fiscales INTO @iID_Fichier_IQEE, @siAnnee_Fiscale
                END
            CLOSE curAnnees_Fiscales
            DEALLOCATE curAnnees_Fiscales

            -----------------------------------------------------------------------------------
            -- Déterminer les fichiers de transactions physiques à partir des fichiers logiques
            -----------------------------------------------------------------------------------

            DECLARE curFichiers_Physiques CURSOR LOCAL FAST_FORWARD FOR
                SELECT DISTINCT iID_Fichier_IQEE, dtDate_Creation
                FROM tblIQEE_Fichiers
                -- Rechercher les fichiers en cours de création...
                WHERE iID_Session = @iID_Session
                  AND dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers
                ORDER BY dtDate_Creation, iID_Fichier_IQEE

            DECLARE @bRepertoireExistant bit = 0
            EXECUTE @iResultat = dbo.psGENE_FichierRepertoireExiste @vcChemin_Fichier, NULL
            IF @iResultat > 1
                SET @bRepertoireExistant = 1

            -- Boucler les fichiers physiques
            OPEN curFichiers_Physiques
            FETCH NEXT FROM curFichiers_Physiques INTO @iID_Fichier_IQEE, @dtDate_Creation
            WHILE @@FETCH_STATUS = 0
                BEGIN
                    -- Définir le début d'un nom de fichier physique
                    SET @vcNom_Fichier = CASE @bFichier_Test WHEN 0 THEN 'P' ELSE 'T' END + @vcNEQ_GUI +
                                         dbo.fnIQEE_FormaterChamp(@dtDate_Creation,'D',14,NULL)

                    -- Appliquer le nom au fichier physique associé à l'année
                    UPDATE tblIQEE_Fichiers
                       SET vcNom_Fichier = @vcNom_Fichier
                      FROM tblIQEE_Fichiers
                     WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE

                    INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
                    VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CreerFichiers                   '+
                            '- Créer lignes fichier physique "'+@vcNom_Fichier+
                            '" selon format NID.  Appel "psIQEE_CreerLignesFichier"')

                    -- Créer les lignes des fichiers physiques de transactions IQÉÉ selon le format des NID
                    PRINT 'psIQEE_CreerLignesFichier'
                    EXECUTE dbo.psIQEE_CreerLignesFichier @iID_Fichier_IQEE, @bDenominalisation, @vcNEQ_GUI

                    DECLARE @NbLignes INT = (SELECT COUNT(*) FROM dbo.tblIQEE_LignesFichier WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE)

                    SELECT  @iID_Fichier_IQEE as '@iID_Fichier_IQEE', @vcNom_Fichier AS 'Nom Fichier', @NbLignes AS 'Nb Lignes'

                    -- Créer le fichier physique dans le répertoire de destination
                    IF @vcChemin_Fichier IS NOT NULL AND @NbLignes > 2
                    BEGIN
                        INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
                        VALUES ('2',50,'')

                        INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
                        VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CreerFichiers                   '+
                                '- Créer fichier physique «'+@vcNom_Fichier+'» sur disque.  Appel "psIQEE_CreerPhysiquementFichier"')

                        IF @bRepertoireExistant = 0
                        BEGIN
                            DECLARE @cmd nvarchar(1000) = 'mkdir "' + @vcChemin_Fichier
                            EXEC XP_CMDSHELL @cmd 
                            SET @bRepertoireExistant = 1
                        END

                        -- Sauvegarder les fichiers physiques sur le disque dans le répertoire de destination
                        EXECUTE @iResultat = dbo.psIQEE_CreerPhysiquementFichier @iID_Fichier_IQEE, @vcChemin_Fichier --, @vcNom_Fichier
                        IF @iResultat = 0
                            BEGIN
                                INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
                                VALUES ('2',50,'       01: Le fichier physique "' +
                                        @vcChemin_Fichier + @vcNom_Fichier + '" a été sauvegardé sur le disque.')

                                -- Mettre à jour l'indicateur de création du fichier
                                UPDATE #tblIQEE_AnneesFiscales 
                                   SET bFichier_Physique_Cree = 1
                                 WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE
                            END
                        ELSE
                            BEGIN
                                PRINT '   Erreur @iResultat : ' + LTrim(Str(@iResultat))

                                INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
                                VALUES ('2',50,'       01: Le fichier physique "'+
                                        @vcChemin_Fichier + @vcNom_Fichier + '" n''a pas été sauvegardé sur le disque.')
                            END
                    END

                    FETCH NEXT FROM curFichiers_Physiques INTO @iID_Fichier_IQEE, @dtDate_Creation
                END
            CLOSE curFichiers_Physiques
            DEALLOCATE curFichiers_Physiques

            PRINT '@iID_Fichier_IQEE sortie de la boucle : ' + LTrim(Str(@iID_Fichier_IQEE))

            -- Mettre à jour l'indicateur de création du fichier pour les fichiers physiques non crées
            UPDATE #tblIQEE_AnneesFiscales
               SET bFichier_Physique_Cree = 0
             WHERE bFichier_Physique_Cree IS NULL

        END -- Fin si ce n'est pas des fichiers de simulation
  
    END TRY
    BEGIN CATCH
        IF @vcChemin_Fichier IS NOT NULL 
-- TODO: Temporairement, faire un rapport de création sur les fichiers de simulation
--        AND @vcCode_Simulation IS NULL
            BEGIN
                -- Créer le rapport de création
                IF ERROR_NUMBER() IS NOT NULL
                    BEGIN
                        INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
                        VALUES ('2',999990,' ')
                        INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
                        VALUES ('2',999991,'       Erreur non prévue:')
                         INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
                        VALUES ('2',999992,'              Temps: '+CONVERT(VARCHAR(25),GETDATE(),121))
                        INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
                        VALUES ('2',999993,'              Numéro d''erreur: '+CAST(ERROR_NUMBER() AS VARCHAR))
                        INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
                        VALUES ('2',999994,'              Message d''erreur: '+ERROR_MESSAGE())
                        INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
                        VALUES ('2',999995,'              Sévérité: '+CAST(ERROR_SEVERITY() AS VARCHAR))
                        INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
                        VALUES ('2',999996,'              État: '+CAST(ERROR_STATE() AS VARCHAR))
                        INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
                        VALUES ('2',999997,'              Procédure: '+ERROR_PROCEDURE())
                        INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
                        VALUES ('2',999998,'              Ligne: '+CAST(ERROR_LINE() AS VARCHAR))

                        PRINT 'Temps: '+CONVERT(VARCHAR(25),GETDATE(),121)
                        PRINT 'Numéro d''erreur: '+CAST(ERROR_NUMBER() AS VARCHAR)
                        PRINT 'Message d''erreur: '+ERROR_MESSAGE()
                        PRINT 'Sévérité: '+CAST(ERROR_SEVERITY() AS VARCHAR)
                        PRINT 'État: '+CAST(ERROR_STATE() AS VARCHAR)
                        PRINT 'Procédure: '+ERROR_PROCEDURE()
                        PRINT 'Ligne: '+CAST(ERROR_LINE() AS VARCHAR)
                    END

                INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
                VALUES ('2',999999,'       TRAITEMENT EN ERREUR')
                 INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
                VALUES ('3',999999,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CreerFichiers - Fin du traitement')

                -- Écrire le rapport de création dans le répertoire
                IF @vcNom_Rapport_Creation IS NULL
                BEGIN
                    -- Compléter le chemin du fichier
                    IF SUBSTRING(@vcChemin_Fichier,LEN(@vcChemin_Fichier),1) <> '\'
                        SET @vcChemin_Fichier = @vcChemin_Fichier + '\'

                    -- Définir le nom du rapport de création
                    SET @vcNom_Rapport_Creation = @vcChemin_Fichier+REPLACE(CONVERT(VARCHAR(20),GETDATE(),120),':',';')+'.txt'
                END

                -- Sauvegarder dans une variable table le rapport comme dans l'importation.
                -- TODO: [psGENE_EcrireFichierTexteAPartirRequeteSQL] oblige à faire un commit.  
                EXECUTE dbo.psGENE_EcrireFichierTexteAPartirRequeteSQL @vcNom_Rapport_Creation,
                                     'SELECT vcMessage FROM ##tblIQEE_RapportCreation R ORDER BY R.cSection,R.iSequence,vcMessage',
                                     @@servername,1,NULL,1,0,0
            END

        -- Lever l'erreur et faire le rollback
        DECLARE @ErrorMessage NVARCHAR(4000),
                @ErrorSeverity INT,
                @ErrorState INT

        SET @ErrorMessage = ERROR_MESSAGE()
        SET @ErrorSeverity = ERROR_SEVERITY()
        SET @ErrorState = ERROR_STATE()

        Select * from ##tblIQEE_RapportCreation

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION

        DROP TABLE ##tblIQEE_RapportCreation

        RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState) WITH LOG;
        RETURN 0
    END CATCH

    ---- TODO: [psGENE_EcrireFichierTexteAPartirRequeteSQL] oblige à faire un commit.  Sauvegarder dans une variable table le rapport comme dans l'importation.
    SELECT vcMessage FROM ##tblIQEE_RapportCreation R ORDER BY R.cSection,R.iSequence,vcMessage
        
    DROP TABLE ##tblIQEE_RapportCreation

    RETURN 1
END
