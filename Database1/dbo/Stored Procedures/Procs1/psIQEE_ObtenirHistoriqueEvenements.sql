/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service        : psIQEE_ObtenirHistoriqueEvenements
Nom du service        : Obtenir l'historique des événements
But                 : Obtenir l'historique des événements de l'IQÉÉ et d'UniAccès.  L'historique de l'IQÉÉ est variable
                      selon des paramètres de sélection, de présentation et de tri des informations.  Il est possible
                      d'utiliser ce service pour obtenir le statut IQÉÉ d'une convention.
Facette                : IQEE

Paramètres d’entrée    :    Paramètre                    Description
                        --------------------------    -----------------------------------------------------------------
                        bRetourner_Statut_IQEE_        Indicateur si la procédure est utilisé uniquement pour retourner
                            Convention                le statut IQÉÉ d'une convention.
                        iID_Convention                Identifiant unique de la convention pour laquelle on désire obtenir
                                                    l'historique de l'IQÉÉ ou le statut IQÉÉ.
                        iID_Beneficiaire            Identifiant du bénéficiaire pour lequel on désire obtenir l'historique
                                                    de l'IQÉÉ.
                        iID_Souscripteur            Identifiant du souscripteur pour lequel on désire obtenir l'historique
                                                    de l'IQÉÉ.
                        bTransactions_Anticipees    Indicateur si l'historique de l'IQÉÉ doit tenir compte des transactions
                                                    anticipées soit les transactions qui n'existent pas encore et qui 
                                                    devraient être créées lors de la prochaine création de fichiers de
                                                    transactions.
                        bForcer_Recalcul_            Indicateur pour forcer le recalcule des transactions anticipées 
                            Transactions_Anticipees puisqu'elles ne sont pas recalculer si c'est dans la même journée.
                        iID_Structure_Historique_    Identifiant de la structure de sélection des événements pour 
                            Selection                l'historique de l'IQÉÉ.
                        iID_Structure_Historique_    Identifiant de la structure de présentation des événements pour 
                            Presentation            l'historique de l'IQÉÉ.  La présentation détermine la structure de 
                                                    la grille de l'interface utilisateur
                        iID_Structure_Historique_    Identifiant de la structure de tri des événements pour l'historique
                            Tri                        de l'IQÉÉ.
                        iID_Utilisateur                Identifiant de l'utilisateur qui requière l'historique de l'IQÉÉ afin
                                                    de déterminer ses accès.
                        cID_Langue                    Identifiant de la langue de l'utilisateur.

Exemple d’appel        :    
        declare @vcCode_Message varchar(100), @vcCode_Statut varchar(10)
        EXECUTE [dbo].[psIQEE_ObtenirHistoriqueEvenements] 0, 150490, NULL, NULL, 0, NULL,
                                                                                           1, 3, 6, 519626, 'FRA', 2015, @vcCode_Message OUTPUT, @vcCode_Statut OUTPUT
                        EXECUTE @iCode_Retour = [dbo].[psIQEE_ObtenirHistoriqueEvenements] 0, 150490, NULL, NULL, 0, NULL,
                                                                                           2, 5, 6, 519626, 'FRA', @vcCode_Message OUTPUT, @vcCode_Statut OUTPUT

                        Exemple pour obtenir le statut IQÉÉ d'une convention
                        EXECUTE @iCode_Retour = [dbo].[psIQEE_ObtenirHistoriqueEvenements] 1, 150490, NULL, NULL, NULL, NULL,
                                                                                           NULL, NULL, NULL, NULL, NULL, @vcCode_Message OUTPUT, @vcCode_Statut OUTPUT

Paramètres de sortie:    Table                        Champ                            Description
                          -------------------------    ---------------------------     ---------------------------------
                        S/O                            iCode_Retour                    1 = Traitement réussi
                                                                                    0 = Traitement en erreur prévisible
                                                                                    -1 = Traitement en erreur non
                                                                                         prévisible
                        S/O                            vcCode_Message                    Code de message pour l'interface
                        S/O                            vcCode_Statut                    Code de statut IQÉÉ d'une convention

Historique des modifications:
    Date        Programmeur             Description
    ----------  --------------------    -----------------------------------------------------
    2010-09-28  Éric Deshaies           Création du service
    2012-06-19  Stéphane Barbeau        Correction de la commande INSERT INTO #tblIQEE_AnneesFiscales... WHERE E.dtDate_Evenement IS NOT NULL
    2014-01-03  Stéphane Barbeau        Recherche transactions IQEE; JOINTURE JOIN tblIQEE_HistoStatutsEvenement SEA ON SEA.vcCode_Statut
                                        Retrait de WHEN SF.vcCode_Statut IN ('CRE','APP') THEN 'TRA_MAJ_'+SF.vcCode_Statut afin d'arrêter 
                                        l'affichage annulations-reprises de T02 faussement indiquées en attente mais répondues en réalité.
                                        Changements de bénéficiaire: Correction du Select pour chercher la date du changement plutôt que la date du début de contrat
                                        Affichage des informations de base des remplacements de bénéficiaires T03.
                                        Affichage des informations de base des impôts spéciaux T06.
    2014-06-06  Stéphane Barbeau        Ajout de jointures dans la requête de niveau 4 pour la vue SAC pour éviter les erreurs techniques de type 
                                        'This constraint cannot be enabled as not all values have corresponding parent values.'
    2014-06-09  Stéphane Barbeau        Retrait des jointures la requête de niveau 4 pour la vue SAC.
                                        Remplacé par Exclusion des T03 et T06 dans les requête de niveau 4.
    2015-12-17  Jean-Philippe Simard    Ajout des Details pour les T06                                                            
    2015-12-18  Jean-Philippe Simard    Correctif où des détails de rejet sont retourné pour des évenement absent de la grille
    2016-01-13  Steeve Picard           Correction de la date de réponse pour les impôts spécials (T06)
    2016-01-15  Patrice Côté            Correction du vcDescription_Detail dans le cas d'une erreur de RQ (JIRA PRA-2087)
    2016-02-19  Patrice Côté            Ajout des ID de transactions dans la table #tblIQEE_Conventions (JIRA IQEE-95)
    2016-03-06  Patrice Côté            IQEE-29 Visualiser la transaction Transfert OUT-IN (T0403) dans l'outil IQEE (JIRA-IQEE-29)
    2016-04-28  Patrice Côté            IQEE-28 Ajout de la visualisation des TIO dans les T0403
    2016-04-29  Steeve Picard           IQEE-28 Petit changement suite à la revue de code
    2016-05-01  Patrice Côté            Ajout de la récupération des montants base et majorée d'IQEE pour les T04
    2016-05-04  Steeve Picard           Renommage de la fonction «fnIQEE_ObtenirDateEnregistrementRQ» qui était auparavant «fnIQEE_ObtenirDateEnregistrementRQ»
    2016-11-25  Steeve Picard           Changement d'orientation de la valeur de retour de «fnIQEE_RemplacementBeneficiaireReconnu»
    2017-04-19  Steeve Picard           Exclusion des fichiers dont les flags «bFichier_Test & bSimulation» à vrai
    2017-06-12  Steeve Picard           Permettre le statut d'afficher « Abandonnée » lorsque le statut d'évènement est « X »
    2017-08-09  Steeve Picard           Rendre visible, en tout temps, le «ID Transaction» mais en grisé s'il n'a pas été transmis dans le fichier à RQ
    2017-09-21  Steeve Picard           Fixé la somme de MRQ quand il y a plusieurs réponses
    2017-11-07  Steeve Picard           Ordonner les transactions par ID de transaction après la date chronologique
    2017-11-09  Steeve Picard           Ajout du paramètre «siAnnee_Fiscale» à la fonction «fnIQEE_ConventionConnueRQ»
    2017-12-05  Steeve Picard           Élimination du paramètre «dtReference» dans l'appel à la fonction «fnIQEE_ConventionConnueRQ» qui retourne maintenant la date 
    2017-12-09  Steeve Picard           Ajout des sommaires pour les T06-31
    2018-02-08  Steeve Picard           Déplacement de «siAnnee_Fiscale» de la table «tblIQEE_Fichiers» vers les tables d'évèments
    2018-05-10  Steeve Picard           Modification à tblIQEE_ReponseTransfert, tous les champs de type «money» sont retirés
    2018-06-06  Steeve Picard           Modificiation de la gestion des retours d'erreur par RQ
    2018-07-11  Steeve Picard           Changement pour les T05-01 «PAE» pour le l'IQÉÉ payé
    2018-09-25  Steeve Picard           Correction de l'affichage du «PAE», séparer la majoration du crédit base
***********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_ObtenirHistoriqueEvenements]
(
    @bRetourner_Statut_IQEE_Convention BIT,
    @iID_Convention INT,
    @iID_Beneficiaire INT,
    @iID_Souscripteur INT,
    @bTransactions_Anticipees BIT,
    @bForcer_Recalcul_Transactions_Anticipees BIT,
    @iID_Structure_Historique_Selection INT,
    @iID_Structure_Historique_Presentation INT,
    @iID_Structure_Historique_Tri INT,
    @iID_Utilisateur INT,
    @cID_Langue CHAR(3),
    @siAnneeDebut_Affichage_IdTransaction SMALLINT = 2015,
    @vcCode_Message VARCHAR(10) OUTPUT,
    @vcCode_Statut VARCHAR(3) OUTPUT
)
AS
BEGIN
    -- Date à laquelle on commence à afficher le Id de la transaction fourni à RQ
    DECLARE @dtAffichage_TransactionID varchar(15) = '''2016-09-01''',
            @bIsDebug BIT = dbo.FN_IsDebug()

    IF OBJECT_ID('tempdb..#tblIQEE_Conventions') IS NOT NULL
        DROP TABLE #tblIQEE_Conventions
    IF OBJECT_ID('tempdb..#tblIQEE_Evenements') IS NOT NULL
        DROP TABLE #tblIQEE_Evenements
    IF OBJECT_ID('tempdb..#tblIQEE_Messages') IS NOT NULL
        DROP TABLE #tblIQEE_Messages
    IF OBJECT_ID('tempdb..#tblGENE_Valeurs') IS NOT NULL
        DROP TABLE #tblGENE_Valeurs
    IF OBJECT_ID('tempdb..#tblIQEE_DetailsEvenement') IS NOT NULL
        DROP TABLE #tblIQEE_DetailsEvenement
    IF OBJECT_ID('tempdb..#tblIQEE_AnneesFiscales') IS NOT NULL
        DROP TABLE #tblIQEE_AnneesFiscales

    BEGIN TRY
        ----------------------------------------------
        --
        -- Initialisation et validation des paramètres
        --
        ----------------------------------------------
        BEGIN 
            DECLARE @bUtilise_Statut_IQEE BIT,
                    @vcCode_Structure_Selection VARCHAR(3),
                    @vcCode_Structure_Presentation VARCHAR(3),
                    @vcCode_Structure_Tri VARCHAR(3),
                    @iID_Evenement_Historique INT,
                    @iID_Evenement_Historique2 INT,
                    @iID_Annulation INT,
                    @vcIDs_Annulations_Manuelles VARCHAR(100),
                    @iID_Ancien_Evenement_Historique INT,
                    @vcIDs_Associations VARCHAR(100),
                    @bReponses BIT,
                    @dtDate DATETIME,
                    @vcCode_Message_IQEE VARCHAR(3),
                    @vcCode_Evenement VARCHAR(10),
                    @vcCode_Type VARCHAR(10),
                    @vcCode_Statut_A_Jour VARCHAR(20),
                    @iID_Primaire INT,
                    @vcNom_Table VARCHAR(150),
                    @vcNom_Champ VARCHAR(150),
                    @vcType VARCHAR(150),
                    @vcDescription VARCHAR(MAX),
                    @iID_Enregistrement INT,
                    @iID_Enregistrement_TMP INT,
                    @vcID_Enregistrement VARCHAR(15),
                    @vcValeur VARCHAR(MAX),
                    @iID_Detail_Evenement INT,
                    @mMontant MONEY,
                    @vcCode VARCHAR(3),
                    @iID_Fichier_IQEE INT,
                    @iID_Fichier_IQEE_TMP INT,
                    @bDebut_Erreur BIT,
                    @iID_Utilisateur_Demande INT,
                    @iID_Utilisateur_Action_Menant_Annulation INT,
                    @iID_Humain INT,
                    @vcDescription_Detail VARCHAR(MAX),
                    @vcReponse VARCHAR(MAX),
                    @vcDescription_Message VARCHAR(1000),
                    @vcSQL VARCHAR(MAX),
                    @vcSQL_OrderBy VARCHAR(1000),
                    @bParametre BIT,
                    @iID_Sous_TypeEvenement INT,
                    @vcDescription_Evenement VARCHAR(200),
                    @tiID_Type_Enregistrement INT,
                    @iID_Sous_Type INT,
                    @cCode_Type_Enregistrement CHAR(2),
                    @vcDescription_TypeEvenement VARCHAR(200),
                    @cCode_Sous_Type CHAR(2),
                    @vcDescription_SousTypeEvenement VARCHAR(200),
                    @vcConventionNo_Destination VARCHAR(15),
                    @vcConventionNo_Source VARCHAR(15),
                    @vcDescription_Detail_Transfert VARCHAR(50),
                    @vcConventionNo_Detail_Transfert VARCHAR(15),
                    @iID_Convention_Source INT,
                    @iID_Convention_Destination INT,
                    @iMultiplicateur_Montants_Transfert INT = 1

            SET @vcCode_Message = NULL
            SET @vcCode_Statut = NULL

            IF @bRetourner_Statut_IQEE_Convention IS NULL
                SET @bRetourner_Statut_IQEE_Convention = 0

            -- Forcer la sélection et la présentation TI1 si c'est juste pour obtenir le statut IQÉÉ
            IF @bRetourner_Statut_IQEE_Convention = 1
                BEGIN
                    SET @bTransactions_Anticipees = NULL

                    SELECT @iID_Structure_Historique_Selection = SH.iID_Structure_Historique
                    FROM tblIQEE_HistoStructures SH
                    WHERE SH.cType_Structure = 'S'
                      AND SH.vcCode_Structure = 'TI1'

                    SELECT @iID_Structure_Historique_Presentation = SH.iID_Structure_Historique
                    FROM tblIQEE_HistoStructures SH
                    WHERE SH.cType_Structure = 'P'
                      AND SH.vcCode_Structure = 'TI1'

                    SET @iID_Structure_Historique_Tri = NULL
                    SET @iID_Utilisateur = NULL
                    SET @iID_Beneficiaire = NULL
                    SET @iID_Souscripteur = NULL
                END

            -- Déterminer les structures d'historique par défaut lorsqu'elles ne sont pas spécifiées
            IF @iID_Structure_Historique_Selection IS NULL
                SELECT @iID_Structure_Historique_Selection = SH.iID_Structure_Historique
                FROM tblIQEE_HistoStructures SH
                WHERE SH.cType_Structure = 'S'
                  AND SH.vcCode_Structure = 'SAC'

            IF @iID_Structure_Historique_Presentation IS NULL
                SELECT @iID_Structure_Historique_Presentation = SH.iID_Structure_Historique
                FROM tblIQEE_HistoStructures SH
                WHERE SH.cType_Structure = 'P'
                  AND SH.vcCode_Structure = 'SAC'

            IF @iID_Structure_Historique_Tri IS NULL
                SELECT @iID_Structure_Historique_Tri = SH.iID_Structure_Historique
                FROM tblIQEE_HistoStructures SH
                WHERE SH.cType_Structure = 'T'
                  AND SH.vcCode_Structure = 'DCI'

            -- Déterminer si le statut IQÉÉ de la convention est utilisé
            IF @bRetourner_Statut_IQEE_Convention = 1 OR
               EXISTS(SELECT *
                      FROM tblIQEE_HistoStructures SH
                      WHERE SH.iID_Structure_Historique IN (@iID_Structure_Historique_Selection,@iID_Structure_Historique_Presentation)
                        AND SH.bUtilise_Statut_IQEE = 1)
                SET @bUtilise_Statut_IQEE = 1
            ELSE
                SET @bUtilise_Statut_IQEE = 0

            -- Déterminer les codes pour les structures de l'historique
            SELECT @vcCode_Structure_Selection = SHS.vcCode_Structure,
                   @vcCode_Structure_Presentation = SHP.vcCode_Structure,
                   @vcCode_Structure_Tri = SHT.vcCode_Structure
            FROM tblIQEE_HistoStructures SHS, tblIQEE_HistoStructures SHP, tblIQEE_HistoStructures SHT
            WHERE SHS.iID_Structure_Historique = @iID_Structure_Historique_Selection
              AND SHP.iID_Structure_Historique = @iID_Structure_Historique_Presentation
              AND SHT.iID_Structure_Historique = @iID_Structure_Historique_Tri

            IF @bIsDebug <> 0
                PRINT 'vcCode_Structure_Selection              : ' + @vcCode_Structure_Selection + CHAR(13) + CHAR(10) +
                      'vcCode_Structure_Presentation           : ' + @vcCode_Structure_Presentation + CHAR(13) + CHAR(10) +
                      'vcCode_Structure_Tri                    : ' + @vcCode_Structure_Tri + CHAR(13) + CHAR(10)

            -- Forcer la sélection, la présentation ou le tri sur des combinaisons pas prévu par la programmation
            IF @vcCode_Structure_Selection IN ('TI1','TI2') AND
               @vcCode_Structure_Presentation = 'SAC' 
                SELECT @iID_Structure_Historique_Presentation = SH.iID_Structure_Historique,
                       @vcCode_Structure_Presentation = SH.vcCode_Structure
                FROM tblIQEE_HistoStructures SH
                WHERE SH.cType_Structure = 'P'
                  AND SH.vcCode_Structure = 'TI1'                

            IF @bIsDebug <> 0
                PRINT 'iID_Structure_Historique_Presentation   : ' + LTRIM(STR(@iID_Structure_Historique_Presentation)) + CHAR(13) + CHAR(10)

            -- Considérer le français comme la langue par défaut
            IF @cID_Langue IS NULL
                SET @cID_Langue = 'FRA'

            -- Valider les paramètres
            IF (@bRetourner_Statut_IQEE_Convention = 1 AND (@iID_Convention IS NULL OR @iID_Convention = 0)) OR
               (@bRetourner_Statut_IQEE_Convention = 0 AND (@iID_Convention IS NULL OR @iID_Convention = 0)
                                                       AND (@iID_Beneficiaire IS NULL OR @iID_Beneficiaire = 0)
                                                       AND (@iID_Souscripteur IS NULL OR @iID_Souscripteur = 0)) OR
               (@bRetourner_Statut_IQEE_Convention = 0 AND (@iID_Utilisateur IS NULL OR @iID_Utilisateur = 0))
                BEGIN
                    SET @vcCode_Message = 'GENEE0020'
                    RETURN 0
                END
        END
        
        -----------------------------------------
        --
        -- Rechercher les conventions applicables
        --
        -----------------------------------------
        BEGIN 
            CREATE TABLE #tblIQEE_Conventions(
                iID_Convention INT PRIMARY KEY,
                vcNo_Convention VARCHAR(15),
                dtDate_Debut_Convention DATETIME,
                vcStatut_Convention VARCHAR(3),
                bAcces_Convention BIT,
                bAcces_Historique_SAC BIT,
                bAcces_Historique_EAFB BIT,
                bAcces_Gestion_Rejets BIT,
                bAcces_Gestion_Erreurs BIT,
                bAcces_Modifier_Erreurs BIT,
                iID_Beneficiaire INT,
                vcNom_Beneficiaire VARCHAR(50),
                vcPrenom_Beneficiaire VARCHAR(35),
                bAcces_Beneficiaire BIT,
                iID_Souscripteur INT,
                vcNom_Souscripteur VARCHAR(50),
                vcPrenom_Souscripteur VARCHAR(35),
                bAcces_Souscripteur BIT,
                bAcces_Consulter_Notes BIT,
                bAcces_Ajouter_Note_IQEE BIT,
                bAcces_Consultation_Evenement BIT,
                bAcces_Deplacement BIT,
                bAcces_Annulations_Manuelles BIT,
                iID_Statut_Convention INT,
                vcCode_Statut VARCHAR(3),
                vcCode_Simulation VARCHAR(100),
                vcDescription_Statut VARCHAR(50),
                vcCommentaires_Statut VARCHAR(MAX),
                mCourant_IQEE MONEY,
                mCourant_IQEE_SAC MONEY,
                mCourant_Credit_Base MONEY,
                mCourant_Majoration MONEY,
                mCourant_Interets MONEY,
                mCourant_Cotisations_Ayant_Donne_Droit MONEY)

            -- Rechercher la ou les conventions
            INSERT INTO #tblIQEE_Conventions
                (iID_Convention,
                vcNo_Convention,
                dtDate_Debut_Convention,
                vcStatut_Convention,
                bAcces_Convention,
                bAcces_Historique_SAC,
                bAcces_Historique_EAFB,
                bAcces_Gestion_Rejets,
                bAcces_Gestion_Erreurs,
                bAcces_Modifier_Erreurs,
                iID_Beneficiaire,
                vcNom_Beneficiaire,
                vcPrenom_Beneficiaire,
                bAcces_Beneficiaire,
                iID_Souscripteur,
                vcNom_Souscripteur,
                vcPrenom_Souscripteur,
                bAcces_Souscripteur,
                bAcces_Consulter_Notes,
                bAcces_Ajouter_Note_IQEE,
                bAcces_Consultation_Evenement,
                bAcces_Deplacement,
                bAcces_Annulations_Manuelles)
            SELECT C.ConventionID,
                   C.ConventionNo,
                   dbo.fnIQEE_ObtenirDateEnregistrementRQ(C.ConventionID),
                   CCS.ConventionStateID,
                   dbo.fnSECU_ObtenirAccessibiliteDroitUtilisateur(CAST(ISNULL(@iID_Utilisateur,0) AS VARCHAR(255)),'UnSchConvention'),
                   dbo.fnSECU_ObtenirAccessibiliteDroitUtilisateur(CAST(ISNULL(@iID_Utilisateur,0) AS VARCHAR(255)),'UnShwTransactionHistoryForCS'),
                   dbo.fnSECU_ObtenirAccessibiliteDroitUtilisateur(CAST(ISNULL(@iID_Utilisateur,0) AS VARCHAR(255)),'UnShwTransactionHistoryEAFB'),
                   dbo.fnSECU_ObtenirAccessibiliteDroitUtilisateur(CAST(ISNULL(@iID_Utilisateur,0) AS VARCHAR(255)),'IQEE_REJETS_CONSULTER'),
                   dbo.fnSECU_ObtenirAccessibiliteDroitUtilisateur(CAST(ISNULL(@iID_Utilisateur,0) AS VARCHAR(255)),'IQEE_ERREURS_CONSULTER'),
                   dbo.fnSECU_ObtenirAccessibiliteDroitUtilisateur(CAST(ISNULL(@iID_Utilisateur,0) AS VARCHAR(255)),'IQEE_ERREURS_MODIFIER'),
                   C.BeneficiaryID,
                   HB.LastName,
                   HB.FirstName,
                   dbo.fnSECU_ObtenirAccessibiliteDroitUtilisateur(CAST(ISNULL(@iID_Utilisateur,0) AS VARCHAR(255)),'UnSchBenef'),
                   C.SubscriberID,
                   HS.LastName,
                   HS.FirstName,
                   dbo.fnSECU_ObtenirAccessibiliteDroitUtilisateur(CAST(ISNULL(@iID_Utilisateur,0) AS VARCHAR(255)),'UnSchSubscriber'),
                   dbo.fnSECU_ObtenirAccessibiliteDroitUtilisateur(CAST(ISNULL(@iID_Utilisateur,0) AS VARCHAR(255)),'UnShwNote'),
                   CASE WHEN dbo.fnSECU_ObtenirAccessibiliteDroitUtilisateur(CAST(ISNULL(@iID_Utilisateur,0) AS VARCHAR(255)),'GENE_AJOUTER_NOTE') = 1
                         AND dbo.fnSECU_ObtenirAccessibiliteDroitUtilisateur(CAST(ISNULL(@iID_Utilisateur,0) AS VARCHAR(255)),'GENE_VISUALISER_NOTE_IQEE') = 1 THEN 1
                        ELSE 0
                   END,
                   dbo.fnSECU_ObtenirAccessibiliteDroitUtilisateur(CAST(ISNULL(@iID_Utilisateur,0) AS VARCHAR(255)),'IQEE_EVENEMENT_CONSULTER'),
                   dbo.fnSECU_ObtenirAccessibiliteDroitUtilisateur(CAST(ISNULL(@iID_Utilisateur,0) AS VARCHAR(255)),'IQEE_EVENEMENT_DEPLACEMENT'),
                   dbo.fnSECU_ObtenirAccessibiliteDroitUtilisateur(CAST(ISNULL(@iID_Utilisateur,0) AS VARCHAR(255)),'IQEE_EVENEMENT_ANNULATION_MANUELLES')
            FROM dbo.Un_Convention C
                 -- Statut à jour
                 JOIN Un_ConventionConventionState CCS ON CCS.ConventionID = C.ConventionID 
                                                      AND CCS.StartDate = (SELECT MAX(CCS2.StartDate)
                                                                           FROM Un_ConventionConventionState CCS2
                                                                           WHERE CCS2.ConventionID = C.ConventionID
                                                                             AND CCS2.StartDate <= GETDATE())
                 JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID
                 JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
            WHERE C.ConventionID = ISNULL(@iID_Convention,C.ConventionID)
              AND C.BeneficiaryID = ISNULL(@iID_Beneficiaire,C.BeneficiaryID)
              AND (@iID_Souscripteur IS NULL
                   OR C.SubscriberID = @iID_Souscripteur
                   OR C.CoSubscriberID = @iID_Souscripteur)

            -- Erreur dans les paramètres s'il n'y a aucune convention sélectionnée
            IF (SELECT COUNT(*) FROM #tblIQEE_Conventions) = 0
                BEGIN
                    SET @vcCode_Message = 'GENEE0020'

                    RETURN 0
                END
        END
        
        -------------------------------------------------------------------------------------------------------------------------
        --
        -- Rechercher les simulations existantes et/ou créer les simulations manquantes pour afficher les transactions anticipées
        --
        -------------------------------------------------------------------------------------------------------------------------
-- TODO: Rechercher des simulations existantes sauf si l'utilisateur force le recalcul des transactions anticipées
                -- Code de simulation = "HISTORIQUE_"+[ID de la convention]
                -- pour la même date de création
                -- faire une job SQL pour supprimer les fichiers de simulation?
            -- Créer les fichiers de simulation pour les transactions anticipées pour chaque convention pas couvertes par une simulation
--        IF @bTransactions_Anticipees = 1
--            BEGIN
--            END

        --------------------------------------------------------------------------
        --
        -- Remplir la liste des événements selon la structure de sélection choisie
        --
        --------------------------------------------------------------------------
-- TODO: Dans toute la section, sélectionner aussi les fichiers de simulation en plus des fichiers de production si applicable avec les paramètres d'entrée
        CREATE TABLE #tblIQEE_Evenements(
            -- Base de l'historique
            iID_Evenement_Historique INT IDENTITY(1,1) NOT NULL,
            iID_Transaction INT NULL,
            iID_Convention INT,
            iID_Evenement INT,
            vcCode_Evenement VARCHAR(10),
            vcCode_Type VARCHAR(10),
            iID_Statut_Chronologique INT,
            vcCode_Statut_Chronologique VARCHAR(20),
            iID_Statut_A_Jour INT,
            vcCode_Statut_A_Jour VARCHAR(20),
            vcCode_Statut_Secondaire VARCHAR(20),
            dtDate_Chronologique DATETIME,
            dtDate_Evenement DATETIME,
            -- Identifiant unique des événements
            iID_Primaire INT, -- ID du premier rejet du fichier, ID transaction si transaction, ID de l'erreur, ID première réponse,
                              -- ID de la première demande d'annulation, ID de la note, ID Convention, ID Changement de bénéficiaire,
                              -- ID paiement PAE, ID Changement d'état de convention
            -- Identifiants secondaires des événements
            iID_Fichier_IQEE INT,
            tiID_Type_Enregistrement TINYINT,
            iID_Sous_Type INT,
            iID_Secondaire1 INT,
            iID_Secondaire2 INT,
            iID_Secondaire3 INT,
            -- Options d'interface
            iID_Enregistrement INT,  -- Pour la gestion des erreurs.  S'applique aux erreurs et aux transactions en erreur.  Prendre dernière erreur si plus qu'une erreur pour la transaction.
            iID_Erreur INT,  -- Pour l'édition d'une erreur.  S'applique aux erreurs directements et aux transactions en erreur.  Prendre dernière erreur si plus qu'une erreur pour la transaction.
            bAnnulation_Manuelle BIT, -- Indique si une transaction peut faire l'objet d'une annulation/reprise manuelle
            vcIDs_Annulations_Manuelles VARCHAR(100), -- Liste des demandes d'annulation/reprise manuelles qui peuvent être supprimée.
            vcIDs_Associations VARCHAR(100),
            -- Informations secondaires
            vcCode_Regroupement VARCHAR(3),
            vcNom_Utilisateur VARCHAR(100),
            vcNom_Beneficiaire VARCHAR(100),
            vcNom_Promoteur VARCHAR(100),
            vcNom_Destinataire VARCHAR(100),
            iNo_PAE INT,
            dtDate_Declencheur DATETIME,
            dtDate_Correction DATETIME,
            dtDate_Transmission DATETIME,
            dtDate_Operation DATETIME,
            dtDate_Effectivite DATETIME,
            dtDate_Sequence DATETIME,
            -- Descriptions selon la présentation choisie
            vcDescription_Evenement VARCHAR(200),
            vcDescription_Type VARCHAR(200),
            vcDescription_Statut_Chronologique VARCHAR(200),
            vcDescription_Statut_A_Jour VARCHAR(200),
            vcDescription_Regroupement VARCHAR(200),
            -- Info-bulles
            vcCommentaires_Date_Chronologique VARCHAR(MAX),
            vcCommentaires_Statut_Chronologique VARCHAR(MAX),
            vcCommentaires_Date_Evenement VARCHAR(MAX),
            vcCommentaires_Evenement VARCHAR(MAX),
            vcCommentaires_Type VARCHAR(MAX),
            vcCommentaires_Statut_A_Jour VARCHAR(MAX),
            -- Réponses de RQ aux événements
            mCourant_IQEE_SAC MONEY,
            mCourant_IQEE MONEY,
            mCourant_Credit_Base MONEY,
            mCourant_Majoration MONEY,
            mCourant_Interets MONEY,
            mCourant_Cotisations_Ayant_Donne_Droit MONEY,
            mDetermination_IQEE MONEY,
            mDetermination_Credit_Base MONEY,
            mDetermination_Majoration MONEY,
            mDetermination_Interets MONEY,
            mDetermination_Cotisations_Ayant_Donne_Droit MONEY,
            mSolde_GUI_IQEE MONEY,
            mSolde_GUI_Credit_Base MONEY,
            mSolde_GUI_Majoration MONEY,
            mSolde_GUI_Cotisations_Ayant_Donne_Droit MONEY,
            mDifferentiel_IQEE MONEY,
            mDifferentiel_Credit_Base MONEY,
            mDifferentiel_Majoration MONEY,
            mDifferentiel_Interets MONEY,
            mSolde_RQ_Cumul_IQEE_Beneficiaire MONEY,
            mSolde_RQ_Solde_IQEE MONEY,
            mSolde_RQ_Cotisations_Ayant_Donne_Droit MONEY)
-- TODO: Avis de cotisation
--            mAvis_Montant_Declare MONEY,
--            mAvis_Montant_Recu MONEY,
--            mAvis_Solde_Avis_Cotisation MONEY)
;
        IF @bIsDebug <> 0
            PRINT 'bUtilise_Statut_IQEE                    : ' + STR(CAST(@bUtilise_Statut_IQEE AS TINYINT), 1) + CHAR(13) + CHAR(10)

        ---------
        -- REJETS
        ---------
        IF @bUtilise_Statut_IQEE = 1 OR
           EXISTS(SELECT * FROM tblIQEE_HistoSelectionEvenements SE
                           JOIN tblIQEE_HistoEvenements E ON E.iID_Evenement = SE.iID_Evenement
                   WHERE SE.iID_Structure_Historique = @iID_Structure_Historique_Selection AND E.vcCode_Type LIKE 'REJ_%')
            BEGIN
                IF @bIsDebug <> 0
                    PRINT 'Recherche les rejets'

                -- Sélectionner les rejets
                INSERT INTO #tblIQEE_Evenements
                    (iID_Convention,
                    vcCode_Evenement,
                    vcCode_Type,    
                    iID_Fichier_IQEE,
                    dtDate_Chronologique,
                    tiID_Type_Enregistrement,
                    iID_Sous_Type,
                    iID_Secondaire1,
                    iID_Primaire)
                SELECT R.iID_Convention,
                       'T'+TE.cCode_Type_Enregistrement+ISNULL(ST.cCode_Sous_Type,''),
                       'REJ_',
                       F.iID_Fichier_IQEE,
                       F.dtDate_Creation,
                       TE.tiID_Type_Enregistrement,
                       ST.iID_Sous_Type,
                       R.iID_Lien_Vers_Erreur_1,
                       MIN(R.iID_Rejet)
                FROM tblIQEE_Rejets R
                     JOIN #tblIQEE_Conventions C ON C.iID_Convention = R.iID_Convention
                     JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = R.iID_Fichier_IQEE
                                            --AND F.bFichier_Test = 0
                                                       AND F.bFichier_Test = 0 AND F.bInd_Simulation = 0
                     JOIN tblIQEE_Validations V ON V.iID_Validation = R.iID_Validation
                                               AND V.cType = 'E'
                     JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = V.tiID_Type_Enregistrement
                     LEFT JOIN tblIQEE_SousTypeEnregistrement ST ON ST.iID_Sous_Type = V.iID_Sous_Type
                WHERE (@bUtilise_Statut_IQEE = 1 
                   OR EXISTS(SELECT *
                             FROM tblIQEE_HistoSelectionEvenements SE
                                  JOIN tblIQEE_HistoEvenements E ON E.iID_Evenement = SE.iID_Evenement
                                                                AND E.vcCode_Evenement = 'T'+TE.cCode_Type_Enregistrement+ISNULL(ST.cCode_Sous_Type,'')
                                                                AND E.vcCode_Type LIKE 'REJ_%'
                             WHERE SE.iID_Structure_Historique = @iID_Structure_Historique_Selection))
                GROUP BY R.iID_Convention,
                       'T'+TE.cCode_Type_Enregistrement+ISNULL(ST.cCode_Sous_Type,''),
                       F.iID_Fichier_IQEE,
                       F.dtDate_Creation,
                       TE.tiID_Type_Enregistrement,
                       ST.iID_Sous_Type,
                       R.iID_Lien_Vers_Erreur_1

                -- Déterminer le code de type des rejets
                UPDATE #tblIQEE_Evenements
                SET vcCode_Type = vcCode_Type +
                                 CASE WHEN EXISTS(SELECT *
                                                     FROM tblIQEE_Rejets PR
                                                          JOIN tblIQEE_Validations PV ON PV.iID_Validation = PR.iID_Validation
                                                          JOIN tblIQEE_Rejets R ON R.iID_Convention = PR.iID_Convention
                                                                               AND R.iID_Fichier_IQEE = PR.iID_Fichier_IQEE
                                                                               AND ISNULL(R.iID_Lien_Vers_Erreur_1,0) = ISNULL(PR.iID_Lien_Vers_Erreur_1,0)
                                                          JOIN tblIQEE_Validations V ON V.iID_Validation = R.iID_Validation
                                                                                    AND V.tiID_Type_Enregistrement = PV.tiID_Type_Enregistrement
                                                                                    AND ISNULL(V.iID_Sous_Type,0) = ISNULL(PV.iID_Sous_Type,0)
                                                                                    AND V.cType = 'E'
                                                                                    AND V.bCorrection_Possible = 0
                                                     WHERE PR.iID_Rejet = E.iID_Primaire) 
                                    THEN 'INT' ELSE 'TRA'
                                 END
                FROM #tblIQEE_Evenements E
                WHERE E.vcCode_Type = 'REJ_'

                -- Mettre à jour l'identifiant de l'événement et déterminer le statut chronologique
                UPDATE #tblIQEE_Evenements
                SET iID_Evenement = (SELECT E2.iID_Evenement
                                     FROM tblIQEE_HistoEvenements E2
                                     WHERE E2.vcCode_Evenement = E.vcCode_Evenement
                                       AND E2.vcCode_Type = E.vcCode_Type),
                    vcCode_Statut_Chronologique = CASE WHEN E.vcCode_Type = 'REJ_INT' THEN 'REJ_CRO_INT' ELSE 'REJ_CRO_ACO' END,
                    iID_Statut_Chronologique = (SELECT SE.iID_Statut
                                                FROM tblIQEE_HistoStatutsEvenement SE
                                                WHERE SE.vcCode_Statut = CASE WHEN E.vcCode_Type = 'REJ_INT' THEN 'REJ_CRO_INT' ELSE 'REJ_CRO_ACO' END)
                FROM #tblIQEE_Evenements E
                WHERE E.vcCode_Type LIKE 'REJ_%'

                -- Supprimer les rejets qui serait resté sans type d'événement
                DELETE FROM #tblIQEE_Evenements
                WHERE vcCode_Type = 'REJ_'

                -- Supprimer les événements de rejet qui ne font pas partie de la sélection choisie
                IF @bUtilise_Statut_IQEE = 0
                    BEGIN
                        DELETE #tblIQEE_Evenements
                        FROM #tblIQEE_Evenements E
                        WHERE E.vcCode_Type LIKE 'REJ_%'
                          AND NOT EXISTS(SELECT *
                                         FROM tblIQEE_HistoSelectionEvenements SE
                                         WHERE SE.iID_Structure_Historique = @iID_Structure_Historique_Selection
                                           AND SE.iID_Evenement = E.iID_Evenement)
                    END

                -- Déterminer les statuts à jour des rejets
                UPDATE #tblIQEE_Evenements
                SET iID_Secondaire3 = (SELECT TOP 1 D.iID_Demande_IQEE
                                       FROM tblIQEE_Demandes D
                                            JOIN tblIQEE_Fichiers F2 ON F2.iID_Fichier_IQEE = D.iID_Fichier_IQEE
                                                                    --AND F2.bFichier_Test = 0
                                                                    AND F2.bFichier_Test = 0 AND F2.bInd_Simulation = 0
                                                                    AND F2.dtDate_Creation > F.dtDate_Creation
                                       WHERE D.iID_Convention = E.iID_Convention
                                         AND D.siAnnee_Fiscale = D.siAnnee_Fiscale
                                         AND D.tiCode_Version <> 1
                                       ORDER BY F2.dtDate_Creation)
                FROM #tblIQEE_Evenements E
                     JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = E.iID_Fichier_IQEE
                                                 AND F.bFichier_Test = 0 AND F.bInd_Simulation = 0
                WHERE E.vcCode_Type LIKE 'REJ_%'
                  AND E.vcCode_Evenement = 'T02'

                UPDATE #tblIQEE_Evenements
                SET vcCode_Statut_A_Jour = CASE WHEN E.vcCode_Type = 'REJ_INT' AND ISNULL(E.iID_Secondaire3,0) = 0 THEN 'REJ_MAJ_INT'
                                                WHEN E.vcCode_Type = 'REJ_INT' AND ISNULL(E.iID_Secondaire3,0) > 0 THEN 'REJ_MAJ_COI'
                                                WHEN E.vcCode_Type = 'REJ_TRA' AND ISNULL(E.iID_Secondaire3,0) > 0 THEN 'REJ_MAJ_COR'
                                                WHEN E.vcCode_Type = 'REJ_TRA' AND ISNULL(E.iID_Secondaire3,0) = 0 THEN 'REJ_MAJ_ACO'
                                           END
                FROM #tblIQEE_Evenements E
                WHERE vcCode_Type LIKE 'REJ_%'

                UPDATE #tblIQEE_Evenements
                SET iID_Statut_A_Jour = (SELECT SE.iID_Statut
                                         FROM tblIQEE_HistoStatutsEvenement SE
                                         WHERE SE.vcCode_Statut = E.vcCode_Statut_A_Jour)
                FROM #tblIQEE_Evenements E
                WHERE E.vcCode_Type LIKE 'REJ_%'

                -- Supprimer les événements/statuts de rejet qui ne font pas partie de la sélection choisie
                IF @bUtilise_Statut_IQEE = 0
                    BEGIN
                        DELETE #tblIQEE_Evenements
                        FROM #tblIQEE_Evenements E
                        WHERE E.vcCode_Type LIKE 'REJ_%'
                          AND NOT EXISTS(SELECT *
                                         FROM tblIQEE_HistoSelectionEvenements SE
                                         WHERE SE.iID_Structure_Historique = @iID_Structure_Historique_Selection
                                           AND SE.iID_Evenement = E.iID_Evenement
                                           AND (SE.iID_Statut IS NULL OR SE.iID_Statut = E.iID_Statut_A_Jour))
                    END

                -- Définir la date d'événement selon l'événement
-- TODO: Faire la même chose pour les autres événement: Trouver la date d'événement selon la nature de l'événement                
                UPDATE #tblIQEE_Evenements
                SET dtDate_Evenement = dbo.fnGENE_DateDeFinAvecHeure(CAST(CAST(D.siAnnee_Fiscale AS VARCHAR(4))+'-12-31' AS DATETIME))
                FROM #tblIQEE_Evenements E
                     JOIN dbo.tblIQEE_Demandes D ON D.iID_Convention = E.iID_Convention AND D.iID_Fichier_IQEE = E.iID_Fichier_IQEE
                     JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
                                            AND F.bFichier_Test = 0 AND F.bInd_Simulation = 0
                WHERE E.vcCode_Type LIKE 'REJ_%'
                  AND E.vcCode_Evenement = 'T02'

                -- Déterminer le type secondaire des rejets (originale ou reprise)
-- TODO: Faire la même chose pour les autres événement            
                UPDATE #tblIQEE_Evenements
                SET iID_Secondaire2 = (SELECT TOP 1 D.tiCode_Version
                                       FROM tblIQEE_Demandes D
                                            JOIN tblIQEE_Fichiers F2 ON F2.iID_Fichier_IQEE = D.iID_Fichier_IQEE
                                                                    --AND F2.bFichier_Test = 0
                                                                    AND F2.bFichier_Test = 0 AND F2.bInd_Simulation = 0
                                                                    AND F2.dtDate_Creation < F.dtDate_Creation
                                       WHERE D.iID_Convention = E.iID_Convention
                                         AND D.siAnnee_Fiscale = YEAR(E.dtDate_Evenement) --F.siAnnee_Fiscale
                                         AND D.tiCode_Version <> 1
                                       ORDER BY F2.dtDate_Creation DESC)
                FROM #tblIQEE_Evenements E
                     JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = E.iID_Fichier_IQEE
                                                 AND F.bFichier_Test = 0 AND F.bInd_Simulation = 0
                WHERE E.vcCode_Type LIKE 'REJ_%'
                  AND E.vcCode_Evenement = 'T02'

                UPDATE #tblIQEE_Evenements
                SET vcCode_Statut_Secondaire = CASE WHEN E.iID_Secondaire2 IS NOT NULL THEN 'REJ_TYP_REP'
                                                  ELSE 'REJ_TYP_ORI'
                                             END
                FROM #tblIQEE_Evenements E
                WHERE vcCode_Type LIKE 'REJ_%'
            END

        ---------------
        -- Transactions
        ---------------
        IF @bUtilise_Statut_IQEE = 1 OR
           EXISTS(SELECT * FROM tblIQEE_HistoSelectionEvenements SE
                           JOIN tblIQEE_HistoEvenements E ON E.iID_Evenement = SE.iID_Evenement
                   WHERE SE.iID_Structure_Historique = @iID_Structure_Historique_Selection AND E.vcCode_Type LIKE 'TRA_%')
            BEGIN
                IF @bIsDebug <> 0
                    PRINT 'Recherche les transactions'

                -- Sélectionner les transactions de demande d'IQÉÉ - T02
                INSERT INTO #tblIQEE_Evenements
                    (iID_Transaction,
                    iID_Convention,
                    iID_Evenement,
                    vcCode_Evenement,
                    vcCode_Type,    
                    iID_Fichier_IQEE,
                    dtDate_Chronologique,
                    dtDate_Evenement,
                    tiID_Type_Enregistrement,
                    iID_Primaire,
                    iID_Secondaire1,
                    iID_Statut_Chronologique,
                    vcCode_Statut_Chronologique,
                    iID_Statut_A_Jour,
                    vcCode_Statut_A_Jour)
                SELECT D.iID_Ligne_Fichier,
                       D.iID_Convention,
                       HE.iID_Evenement,
                       HE.vcCode_Evenement,
                       HE.vcCode_Type,
                       F.iID_Fichier_IQEE,
                       F.dtDate_Creation,
                       dbo.fnGENE_DateDeFinAvecHeure(CAST(CAST(D.siAnnee_Fiscale AS VARCHAR(4))+'-12-31' AS DATETIME)),
                       TE.tiID_Type_Enregistrement,
                       D.iID_Demande_IQEE,
                       D.siAnnee_Fiscale,
                       SEC.iID_Statut,
                       SEC.vcCode_Statut,
                       SEA.iID_Statut,
                       SEA.vcCode_Statut
                FROM tblIQEE_Demandes D
                     JOIN #tblIQEE_Conventions C ON C.iID_Convention = D.iID_Convention
                     JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
                                      --AND F.bFichier_Test = 0
                                                 AND F.bFichier_Test = 0 AND F.bInd_Simulation = 0
                     JOIN tblIQEE_StatutsFichier SF ON SF.tiID_Statut_Fichier = F.tiID_Statut_Fichier
                     JOIN tblIQEE_TypesEnregistrement TE ON TE.cCode_Type_Enregistrement = '02'
                     JOIN tblIQEE_HistoEvenements HE ON HE.vcCode_Evenement = 'T'+TE.cCode_Type_Enregistrement
                                                    AND HE.vcCode_Type = 'TRA_'+
                                                            CASE WHEN D.mTotal_Cotisations_Subventionnables = 0
                                                                  AND D.tiCode_Version = 2
                                                                  AND EXISTS(SELECT *
                                                                             FROM tblIQEE_Annulations A
                                                                             WHERE A.iID_Enregistrement_Reprise = D.iID_Demande_IQEE
                                                                               AND A.iID_Enregistrement_Reprise_Originale IS NOT NULL) THEN '2A0'
                                                                 ELSE CAST(D.tiCode_Version AS CHAR(1))
                                                            END
                     JOIN tblIQEE_HistoStatutsEvenement SEC ON SEC.vcCode_Statut = 'TRA_CRO_'+
                                                                        CASE WHEN SF.vcCode_Statut IN ('CRE','APP') THEN SF.vcCode_Statut
                                                                             ELSE 'TRM'
                                                                        END
                     JOIN tblIQEE_HistoStatutsEvenement SEA ON SEA.vcCode_Statut = 
                                                                        CASE 
                                                                             WHEN D.cStatut_Reponse IN ('A','E','R','D','T','X') THEN 'TRA_MAJ_'+D.cStatut_Reponse
                                                                             ELSE 'TRA_MAJ_IND'
                                                                        END
                WHERE (@bUtilise_Statut_IQEE = 1 
                   OR EXISTS(SELECT *
                             FROM tblIQEE_HistoSelectionEvenements SE
                             WHERE SE.iID_Structure_Historique = @iID_Structure_Historique_Selection
                               AND SE.iID_Evenement = HE.iID_Evenement
                               AND (SE.iID_Statut IS NULL OR SE.iID_Statut = SEA.iID_Statut)))
-- TODO: Même chose pour les autres types de transaction.  iID_Secondaire1 doit contenir l'identifiant unique de l'événement comme pour le lien 1 des rejets
;                
                -- T03
                INSERT INTO #tblIQEE_Evenements
                    (iID_Transaction,
                    iID_Convention,
                    iID_Evenement,
                    vcCode_Evenement,
                    vcCode_Type,    
                    iID_Fichier_IQEE,
                    dtDate_Chronologique,
                    dtDate_Evenement,
                    tiID_Type_Enregistrement,
                    iID_Primaire,
                    iID_Secondaire1,
                    iID_Statut_Chronologique,
                    vcCode_Statut_Chronologique,
                    iID_Statut_A_Jour,
                    vcCode_Statut_A_Jour)
                SELECT RB.iID_Ligne_Fichier,
                       RB.iID_Convention,
                       HE.iID_Evenement,
                       HE.vcCode_Evenement,
                       HE.vcCode_Type,
                       F.iID_Fichier_IQEE,
                       F.dtDate_Creation,
                       RB.dtDate_Remplacement, --dbo.fnGENE_DateDeFinAvecHeure(CAST(CAST(F.siAnnee_Fiscale AS VARCHAR(4))+'-12-31' AS DATETIME)),
                       TE.tiID_Type_Enregistrement,
                       RB.iID_Remplacement_Beneficiaire,
                       YEAR(RB.dtDate_Remplacement) AS F_siAnnee_Fiscale,
                       SEC.iID_Statut,
                       SEC.vcCode_Statut,
                       SEA.iID_Statut,
                       SEA.vcCode_Statut
                FROM tblIQEE_RemplacementsBeneficiaire RB
                     JOIN #tblIQEE_Conventions C ON C.iID_Convention = RB.iID_Convention
                     JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = RB.iID_Fichier_IQEE
                                            --AND F.bFichier_Test = 0
                                                       AND F.bFichier_Test = 0 AND F.bInd_Simulation = 0
                     JOIN tblIQEE_StatutsFichier SF ON SF.tiID_Statut_Fichier = F.tiID_Statut_Fichier
                     JOIN tblIQEE_TypesEnregistrement TE ON TE.cCode_Type_Enregistrement = '03'
                     JOIN tblIQEE_HistoEvenements HE ON HE.vcCode_Evenement = 'T'+TE.cCode_Type_Enregistrement
                                                    AND HE.vcCode_Type = 'TRA_'+ CAST(RB.tiCode_Version AS CHAR(1))
                     JOIN tblIQEE_HistoStatutsEvenement SEC ON SEC.vcCode_Statut = 'TRA_CRO_'+
                                                                        CASE WHEN SF.vcCode_Statut IN ('CRE','APP') THEN SF.vcCode_Statut
                                                                             ELSE 'TRM'
                                                                        END
                     JOIN tblIQEE_HistoStatutsEvenement SEA ON SEA.vcCode_Statut = 
                                                                        CASE 
                                                                             WHEN RB.cStatut_Reponse IN ('A','E','R','D','T','X') THEN 'TRA_MAJ_'+RB.cStatut_Reponse
                                                                             ELSE 'TRA_MAJ_IND'
                                                                        END
                WHERE (@bUtilise_Statut_IQEE = 1 
                   OR EXISTS(SELECT *
                             FROM tblIQEE_HistoSelectionEvenements SE
                             WHERE SE.iID_Structure_Historique = @iID_Structure_Historique_Selection
                               AND SE.iID_Evenement = HE.iID_Evenement
                               AND (SE.iID_Statut IS NULL OR SE.iID_Statut = SEA.iID_Statut)))
            
            
                --PRINT '@iID_Convention = ' + STR(@iID_Convention)
                --PRINT '@iID_Beneficiaire = ' + STR(@iID_Beneficiaire)
                --PRINT '@iID_Souscripteur = ' + STR(@iID_Souscripteur)
    
                --------------------------------------------------------------------
                -- Sélection des différents sous type d'évènement de transfert 'T04'
                --------------------------------------------------------------------
                BEGIN 
                    CREATE TABLE #TBSousTypeEvenement_Transfert (
                        tiID_Type_Enregistrement INT,
                        iID_Sous_Type INT,
                        cCode_Type_Enregistrement CHAR(2),
                        vcDescription_TypeEvenement VARCHAR(200),
                        cCode_Sous_Type CHAR(2),
                        vcDescription_SousTypeEvenement VARCHAR(200)
                    )
                        
                    INSERT INTO #TBSousTypeEvenement_Transfert (
                         tiID_Type_Enregistrement, iID_Sous_Type,
                         cCode_Type_Enregistrement, vcDescription_TypeEvenement,
                         cCode_Sous_Type, vcDescription_SousTypeEvenement
                    )
                    SELECT 
                        T.tiID_Type_Enregistrement, S.iID_Sous_Type,
                        T.cCode_Type_Enregistrement, T.vcDescription,
                        S.cCode_Sous_Type, S.vcDescription
                    FROM 
                        tblIQEE_TypesEnregistrement T 
                        JOIN tblIQEE_SousTypeEnregistrement S ON T.tiID_Type_Enregistrement = S.tiID_Type_Enregistrement
                    WHERE 
                        T.cCode_Type_Enregistrement = '04'
                    
                    ------------------------------------------------------------
                    -- Boucler à travers les différents sous types de transfert
                    -- 01 = Fiduciaire cédant
                    -- 02 = Fiduciaire cessionnaire
                    -- 03 = Fiduciaire et transfert de régime à l'interne
                    ------------------------------------------------------------
                    SET @iID_Sous_TypeEvenement = 0               
                    WHILE Exists(SELECT TOP 1 * FROM #TBSousTypeEvenement_Transfert WHERE iID_Sous_Type > @iID_Sous_TypeEvenement) 
                        BEGIN
                            SELECT @iID_Sous_TypeEvenement = Min(iID_Sous_Type) 
                              FROM #TBSousTypeEvenement_Transfert 
                             WHERE iID_Sous_Type > @iID_Sous_TypeEvenement

                            SELECT @tiID_Type_Enregistrement = tiID_Type_Enregistrement,
                                   @iID_Sous_Type = iID_Sous_Type,
                                   @cCode_Type_Enregistrement = cCode_Type_Enregistrement,
                                   @vcDescription_TypeEvenement = vcDescription_TypeEvenement,
                                   @cCode_Sous_Type = cCode_Sous_Type,
                                   @vcDescription_SousTypeEvenement = vcDescription_SousTypeEvenement
                              FROM #TBSousTypeEvenement_Transfert 
                             WHERE iID_Sous_Type = @iID_Sous_TypeEvenement
                
                            -- Ajout des évènements de transferts à afficher
                            IF @cCode_Sous_Type IN ('01', '02')
                                INSERT INTO #tblIQEE_Evenements (
                                    iID_Transaction, iID_Convention, iID_Evenement, vcCode_Evenement, vcCode_Type,    
                                    iID_Fichier_IQEE, dtDate_Chronologique, dtDate_Evenement, tiID_Type_Enregistrement,
                                    iID_Primaire, iID_Secondaire1, iID_Statut_Chronologique, vcCode_Statut_Chronologique, 
                                    iID_Statut_A_Jour, vcCode_Statut_A_Jour,
                                    mCourant_Credit_Base,
                                    mCourant_Majoration,
                                    mCourant_IQEE_SAC
                                )        
                                SELECT 
                                    T.iID_Ligne_Fichier, T.iID_Convention, HE.iID_Evenement, HE.vcCode_Evenement, HE.vcCode_Type,
                                    F.iID_Fichier_IQEE, F.dtDate_Creation, T.dtDate_Transfert, TE.tiID_Type_Enregistrement,
                                    T.iID_Transfert, YEAR(T.dtDate_Transfert) AS F_siAnnee_Fiscale, SEC.iID_Statut, SEC.vcCode_Statut,
                                    SEA.iID_Statut, SEA.vcCode_Statut,
                                    CASE WHEN T.tiCode_Version = 1 THEN 1 ELSE -1 END * T.mIQEE_CreditBase_Transfere,
                                    CASE WHEN T.tiCode_Version = 1 THEN 1 ELSE -1 END * T.mIQEE_Majore_Transfere,
                                    CASE WHEN T.tiCode_Version = 1 THEN 1 ELSE -1 END * (T.mIQEE_CreditBase_Transfere + T.mIQEE_Majore_Transfere)
                                FROM 
                                    tblIQEE_Transferts T
                                    JOIN #tblIQEE_Conventions C ON C.iID_Convention = T.iID_Convention
                                    JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = T.iID_Fichier_IQEE AND F.bFichier_Test = 0 AND F.bInd_Simulation = 0
                                    JOIN tblIQEE_StatutsFichier SF ON SF.tiID_Statut_Fichier = F.tiID_Statut_Fichier
                                    JOIN #TBSousTypeEvenement_Transfert TE ON TE.cCode_Type_Enregistrement = @cCode_Type_Enregistrement AND TE.iID_Sous_Type = @iID_Sous_Type
                                                                          AND TE.iID_Sous_Type = T.iID_Sous_Type
                                    JOIN tblIQEE_HistoEvenements HE ON HE.vcCode_Evenement = 'T' +  TE.cCode_Type_Enregistrement + TE.cCode_Sous_Type    
                                                                   AND HE.vcCode_Type = 'TRA_'+ CASE WHEN T.mCotisations_Donne_Droit_IQEE = 0 AND T.tiCode_Version = 2
                                                                                                          AND EXISTS( SELECT * FROM tblIQEE_Annulations A
                                                                                                                       WHERE A.iID_Enregistrement_Reprise = T.iID_Transfert
                                                                                                                         AND A.iID_Enregistrement_Reprise_Originale IS NOT NULL) 
                                                                                                     THEN '2A0'
                                                                                                     ELSE CAST(T.tiCode_Version AS CHAR(1))
                                                                                                END
                                    JOIN tblIQEE_HistoStatutsEvenement SEC ON SEC.vcCode_Statut = 'TRA_CRO_'+ CASE WHEN SF.vcCode_Statut IN ('CRE','APP') THEN SF.vcCode_Statut ELSE 'TRM' END
                                    JOIN tblIQEE_HistoStatutsEvenement SEA ON SEA.vcCode_Statut = CASE  WHEN T.cStatut_Reponse IN ('A','E','R','D','T','X') THEN 'TRA_MAJ_'+ T.cStatut_Reponse ELSE 'TRA_MAJ_IND' END
                                    --LEFT JOIN (
                                    --        SELECT iID_Transfert_IQEE, SUM(mMontantIQEE_Base) AS mMontant_IQEE_Base, SUM(mMontantIQEE_Majore) AS mMontant_IQEE_Majore, SUM(mMontantIQEE) AS mMontant_IQEE
                                    --          FROM tblIQEE_ReponsesTransfert
                                    --         GROUP BY iID_Transfert_IQEE
                                    --    ) RT ON RT.iID_Transfert_IQEE = T.iID_Transfert
                                WHERE 
                                    @bUtilise_Statut_IQEE = 1 
                                    OR EXISTS( SELECT * FROM tblIQEE_HistoSelectionEvenements SE
                                                WHERE SE.iID_Structure_Historique = @iID_Structure_Historique_Selection
                                                  AND SE.iID_Evenement = HE.iID_Evenement
                                                  AND (SE.iID_Statut IS NULL OR SE.iID_Statut = SEA.iID_Statut))
                    
                            --********************************************
                            --  Les transferts RIO utilisent la table tblOPER_OperationsRIO. La convention peut être la source ou la destination.  
                            --  Pour savoir s'il y a un transfert on doit donc valider 2 cas différemment:
                        
                            --    *Si la convention est la source, on retrouve simplement l'ID dans tblIQEE_Transfert via ConventionID. 
                        
                            --    *Sinon, si c'est la destination
                            --    on retrouve l'ID de la source via tblOPER_OperationsRIO -> Un_Unit -> Un_Convention via 
                            --    tblOPER_OperationsRIO.iID_Unite_Destination puis on obtient le lien avec tblIQEE_Transfert via 
                            --    tblOPER_OperationsRIO.iID_Unite_Source
                            --********************************************

                            IF @cCode_Sous_Type = '03'
                                BEGIN
                                    --Lorsque la convention est la source d'un transfert
                                    INSERT INTO #tblIQEE_Evenements (
                                        iID_Transaction, iID_Convention, iID_Evenement, vcCode_Evenement, vcCode_Type, 
                                        iID_Fichier_IQEE, dtDate_Chronologique, dtDate_Evenement, tiID_Type_Enregistrement, 
                                        iID_Primaire, iID_Secondaire1, iID_Statut_Chronologique, vcCode_Statut_Chronologique,
                                        iID_Statut_A_Jour, vcCode_Statut_A_Jour,
                                        mCourant_Credit_Base, 
                                        mCourant_Majoration, 
                                        mCourant_IQEE_SAC
                                    )        
                                    SELECT 
                                        T.iID_Ligne_Fichier, T.iID_Convention, HE.iID_Evenement, HE.vcCode_Evenement, HE.vcCode_Type,
                                        F.iID_Fichier_IQEE, F.dtDate_Creation, T.dtDate_Transfert, TE.tiID_Type_Enregistrement,
                                        T.iID_Transfert, YEAR(T.dtDate_Transfert) AS F_siAnnee_Fiscale, SEC.iID_Statut, SEC.vcCode_Statut,
                                        SEA.iID_Statut, SEA.vcCode_Statut,
                                        CASE WHEN T.tiCode_Version = 1 THEN 1 ELSE -1 END * T.mIQEE_CreditBase_Transfere,
                                        CASE WHEN T.tiCode_Version = 1 THEN 1 ELSE -1 END * T.mIQEE_Majore_Transfere,
                                        CASE WHEN T.tiCode_Version = 1 THEN 1 ELSE -1 END * (T.mIQEE_CreditBase_Transfere + T.mIQEE_Majore_Transfere)
                                    FROM 
                                        tblIQEE_Transferts T
                                        JOIN #tblIQEE_Conventions C ON C.iID_Convention = T.iID_Convention
                                        JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = T.iID_Fichier_IQEE AND F.bFichier_Test = 0 AND F.bInd_Simulation = 0
                                        JOIN tblIQEE_StatutsFichier SF ON SF.tiID_Statut_Fichier = F.tiID_Statut_Fichier
                                        JOIN #TBSousTypeEvenement_Transfert TE ON TE.cCode_Type_Enregistrement = @cCode_Type_Enregistrement AND TE.iID_Sous_Type = @iID_Sous_Type
                                                                              AND TE.iID_Sous_Type = T.iID_Sous_Type
                                        INNER JOIN tblIQEE_HistoEvenements HE ON HE.vcCode_Evenement = 'T' + TE.cCode_Type_Enregistrement + TE.cCode_Sous_Type    
                                                                             AND HE.vcCode_Type = 'TRA_'+ CASE WHEN T.mCotisations_Donne_Droit_IQEE = 0 AND T.tiCode_Version = 2
                                                                                                                    AND EXISTS( SELECT * FROM tblIQEE_Annulations A
                                                                                                                                 WHERE A.iID_Enregistrement_Reprise = T.iID_Transfert
                                                                                                                                   AND A.iID_Enregistrement_Reprise_Originale IS NOT NULL) 
                                                                                                               THEN '2A0'
                                                                                                               ELSE CAST(T.tiCode_Version AS CHAR(1))
                                                                                                          END
                                        JOIN tblIQEE_HistoStatutsEvenement SEC ON SEC.vcCode_Statut = 'TRA_CRO_'+ CASE WHEN SF.vcCode_Statut IN ('CRE','APP') THEN SF.vcCode_Statut ELSE 'TRM'END
                                        JOIN tblIQEE_HistoStatutsEvenement SEA ON SEA.vcCode_Statut = CASE WHEN T.cStatut_Reponse IN ('A','E','R','D','T','X') THEN 'TRA_MAJ_'+ T.cStatut_Reponse ELSE 'TRA_MAJ_IND' END                                                    
                                        --LEFT JOIN (
                                        --        SELECT iID_Transfert_IQEE, SUM(mMontantIQEE_Base) AS mMontant_IQEE_Base, SUM(mMontantIQEE_Majore) AS mMontant_IQEE_Majore, SUM(mMontantIQEE) AS mMontant_IQEE
                                        --          FROM tblIQEE_ReponsesTransfert
                                        --         GROUP BY iID_Transfert_IQEE
                                        --    ) RT ON RT.iID_Transfert_IQEE = T.iID_Transfert
                                    WHERE 
                                        @bUtilise_Statut_IQEE = 1 
                                        OR EXISTS( SELECT * FROM tblIQEE_HistoSelectionEvenements SE
                                                    WHERE SE.iID_Structure_Historique = @iID_Structure_Historique_Selection
                                                      AND SE.iID_Evenement = HE.iID_Evenement
                                                      AND (SE.iID_Statut IS NULL OR SE.iID_Statut = SEA.iID_Statut)
                                                 )
                                                   
                                    --Lorsque la convention est la destination d'un transfert RIO
                                    INSERT INTO #tblIQEE_Evenements (
                                        iID_Transaction, iID_Convention, iID_Evenement, vcCode_Evenement, vcCode_Type, 
                                        iID_Fichier_IQEE, dtDate_Chronologique, dtDate_Evenement, tiID_Type_Enregistrement, 
                                        iID_Primaire, iID_Secondaire1, iID_Statut_Chronologique, vcCode_Statut_Chronologique,
                                        iID_Statut_A_Jour, vcCode_Statut_A_Jour,
                                        mCourant_Credit_Base, 
                                        mCourant_Majoration, 
                                        mCourant_IQEE_SAC
                                    )        
                                    SELECT 
                                        T.iID_Ligne_Fichier, C.iID_Convention, HE.iID_Evenement, HE.vcCode_Evenement, HE.vcCode_Type,
                                        F.iID_Fichier_IQEE, F.dtDate_Creation, T.dtDate_Transfert, TE.tiID_Type_Enregistrement,
                                        T.iID_Transfert, YEAR(T.dtDate_Transfert) AS F_siAnnee_Fiscale, SEC.iID_Statut, SEC.vcCode_Statut,
                                        SEA.iID_Statut, SEA.vcCode_Statut,
                                        CASE WHEN T.tiCode_Version = 1 THEN 1 ELSE -1 END * T.mIQEE_CreditBase_Transfere,
                                        CASE WHEN T.tiCode_Version = 1 THEN 1 ELSE -1 END * T.mIQEE_Majore_Transfere,
                                        CASE WHEN T.tiCode_Version = 1 THEN 1 ELSE -1 END * (T.mIQEE_CreditBase_Transfere + T.mIQEE_Majore_Transfere)
                                    FROM 
                                        tblIQEE_Transferts T
                                        JOIN tblOPER_OperationsRIO RIO ON T.iID_Operation_RIO = RIO.iID_Operation_RIO
                                        JOIN dbo.Un_Unit UD ON UD.UnitID = RIO.iID_Unite_Destination
                                        JOIN #tblIQEE_Conventions C ON C.iID_Convention = UD.ConventionID
                                        JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = T.iID_Fichier_IQEE AND F.bFichier_Test = 0 AND F.bInd_Simulation = 0
                                        JOIN tblIQEE_StatutsFichier SF ON SF.tiID_Statut_Fichier = F.tiID_Statut_Fichier
                                        JOIN #TBSousTypeEvenement_Transfert TE ON TE.cCode_Type_Enregistrement = @cCode_Type_Enregistrement AND TE.iID_Sous_Type = @iID_Sous_Type
                                                                              AND TE.iID_Sous_Type = T.iID_Sous_Type
                                        INNER JOIN tblIQEE_HistoEvenements HE ON HE.vcCode_Evenement = 'T' + TE.cCode_Type_Enregistrement + TE.cCode_Sous_Type    
                                                                             AND HE.vcCode_Type = 'TRA_'+ CASE WHEN T.mCotisations_Donne_Droit_IQEE = 0 AND T.tiCode_Version = 2
                                                                                                                    AND EXISTS( SELECT * FROM tblIQEE_Annulations A
                                                                                                                                 WHERE A.iID_Enregistrement_Reprise = T.iID_Transfert
                                                                                                                                   AND A.iID_Enregistrement_Reprise_Originale IS NOT NULL) 
                                                                                                               THEN '2A0'
                                                                                                               ELSE CAST(T.tiCode_Version AS CHAR(1))
                                                                                                          END
                                        JOIN tblIQEE_HistoStatutsEvenement SEC ON SEC.vcCode_Statut = 'TRA_CRO_'+ CASE WHEN SF.vcCode_Statut IN ('CRE','APP') THEN SF.vcCode_Statut ELSE 'TRM' END
                                        JOIN tblIQEE_HistoStatutsEvenement SEA ON SEA.vcCode_Statut = CASE WHEN T.cStatut_Reponse IN ('A','E','R','D','T','X') THEN 'TRA_MAJ_'+ T.cStatut_Reponse ELSE 'TRA_MAJ_IND' END
                                        --LEFT JOIN (
                                        --        SELECT iID_Transfert_IQEE, SUM(mMontantIQEE_Base) AS mMontant_IQEE_Base, SUM(mMontantIQEE_Majore) AS mMontant_IQEE_Majore, SUM(mMontantIQEE) AS mMontant_IQEE
                                        --          FROM tblIQEE_ReponsesTransfert
                                        --          GROUP BY iID_Transfert_IQEE
                                        --    ) RT ON RT.iID_Transfert_IQEE = T.iID_Transfert
                                    WHERE 
                                        @bUtilise_Statut_IQEE = 1 
                                        OR EXISTS( SELECT * FROM tblIQEE_HistoSelectionEvenements SE
                                                    WHERE SE.iID_Structure_Historique = @iID_Structure_Historique_Selection
                                                      AND SE.iID_Evenement = HE.iID_Evenement
                                                      AND (SE.iID_Statut IS NULL OR SE.iID_Statut = SEA.iID_Statut) )
                            
                                    --Lorsque la convention est la destination d'un transfert TIO
                                    INSERT INTO #tblIQEE_Evenements (
                                        iID_Transaction, iID_Convention, iID_Evenement, vcCode_Evenement, vcCode_Type, 
                                        iID_Fichier_IQEE, dtDate_Chronologique, dtDate_Evenement, tiID_Type_Enregistrement, 
                                        iID_Primaire, iID_Secondaire1, iID_Statut_Chronologique, vcCode_Statut_Chronologique,
                                        iID_Statut_A_Jour, vcCode_Statut_A_Jour,
                                        mCourant_Credit_Base, 
                                        mCourant_Majoration, 
                                        mCourant_IQEE_SAC
                                    )        
                                    SELECT 
                                        T.iID_Ligne_Fichier, C.iID_Convention, HE.iID_Evenement, HE.vcCode_Evenement, HE.vcCode_Type,
                                        F.iID_Fichier_IQEE, F.dtDate_Creation, T.dtDate_Transfert, TE.tiID_Type_Enregistrement,
                                        T.iID_Transfert, YEAR(T.dtDate_Transfert) AS F_siAnnee_Fiscale, SEC.iID_Statut, SEC.vcCode_Statut,
                                        SEA.iID_Statut, SEA.vcCode_Statut,
                                        CASE WHEN T.tiCode_Version = 1 THEN 1 ELSE -1 END * T.mIQEE_CreditBase_Transfere,
                                        CASE WHEN T.tiCode_Version = 1 THEN 1 ELSE -1 END * T.mIQEE_Majore_Transfere,
                                        CASE WHEN T.tiCode_Version = 1 THEN 1 ELSE -1 END * (T.mIQEE_CreditBase_Transfere + T.mIQEE_Majore_Transfere)
                                    FROM 
                                        tblIQEE_Transferts T
                                        JOIN UN_TIO TIO ON TIO.iTIOID = T.iID_TIO
                                        JOIN dbo.Un_ConventionOper CO ON CO.OperID = TIO.iTINOperID
                                        JOIN #tblIQEE_Conventions C ON C.iID_Convention = CO.ConventionID
                                        JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = T.iID_Fichier_IQEE AND F.bFichier_Test = 0 AND F.bInd_Simulation = 0
                                        JOIN tblIQEE_StatutsFichier SF ON SF.tiID_Statut_Fichier = F.tiID_Statut_Fichier
                                        JOIN #TBSousTypeEvenement_Transfert TE ON TE.cCode_Type_Enregistrement = @cCode_Type_Enregistrement AND TE.iID_Sous_Type = @iID_Sous_Type
                                                                              AND TE.iID_Sous_Type = T.iID_Sous_Type
                                        INNER JOIN tblIQEE_HistoEvenements HE ON HE.vcCode_Evenement = 'T' + TE.cCode_Type_Enregistrement + TE.cCode_Sous_Type    
                                                                             AND HE.vcCode_Type = 'TRA_'+ CASE WHEN T.mCotisations_Donne_Droit_IQEE = 0 AND T.tiCode_Version = 2
                                                                                                                    AND EXISTS( SELECT * FROM tblIQEE_Annulations A
                                                                                                                                 WHERE A.iID_Enregistrement_Reprise = T.iID_Transfert
                                                                                                                                   AND A.iID_Enregistrement_Reprise_Originale IS NOT NULL) 
                                                                                                               THEN '2A0'
                                                                                                               ELSE CAST(T.tiCode_Version AS CHAR(1))
                                                                                                          END
                                        JOIN tblIQEE_HistoStatutsEvenement SEC ON SEC.vcCode_Statut = 'TRA_CRO_'+ CASE WHEN SF.vcCode_Statut IN ('CRE','APP') THEN SF.vcCode_Statut ELSE 'TRM' END
                                        JOIN tblIQEE_HistoStatutsEvenement SEA ON SEA.vcCode_Statut =  CASE WHEN T.cStatut_Reponse IN ('A','E','R','D','T','X') THEN 'TRA_MAJ_'+ T.cStatut_Reponse ELSE 'TRA_MAJ_IND' END
                                        --LEFT JOIN (
                                        --        SELECT iID_Transfert_IQEE, SUM(mMontantIQEE_Base) AS mMontant_IQEE_Base, SUM(mMontantIQEE_Majore) AS mMontant_IQEE_Majore, SUM(mMontantIQEE) AS mMontant_IQEE
                                        --          FROM tblIQEE_ReponsesTransfert
                                        --         GROUP BY iID_Transfert_IQEE
                                        --    ) RT ON RT.iID_Transfert_IQEE = T.iID_Transfert
                                    WHERE 
                                        @bUtilise_Statut_IQEE = 1 
                                        OR EXISTS( SELECT * FROM tblIQEE_HistoSelectionEvenements SE
                                                    WHERE SE.iID_Structure_Historique = @iID_Structure_Historique_Selection
                                                      AND SE.iID_Evenement = HE.iID_Evenement
                                                      AND (SE.iID_Statut IS NULL OR SE.iID_Statut = SEA.iID_Statut))
                                END
                        END 
                END
                            
                -- T05
                INSERT INTO #tblIQEE_Evenements (
                    iID_Transaction, iID_Convention, iID_Evenement, vcCode_Evenement, vcCode_Type, 
                    iID_Fichier_IQEE, dtDate_Chronologique, dtDate_Evenement, tiID_Type_Enregistrement,
                    iID_Primaire, iID_Secondaire1, iID_Statut_Chronologique, vcCode_Statut_Chronologique,
                    iID_Statut_A_Jour, vcCode_Statut_A_Jour,
                    mCourant_Credit_Base,
                    mCourant_Majoration,
                    mCourant_IQEE_SAC
                )
                SELECT  
                    PB.iID_Ligne_Fichier, PB.iID_Convention, HE.iID_Evenement, HE.vcCode_Evenement, HE.vcCode_Type,
                    F.iID_Fichier_IQEE, F.dtDate_Creation, PB.dtDate_Paiement, TE.tiID_Type_Enregistrement,
                    PB.iID_Paiement_Beneficiaire, YEAR(PB.dtDate_Paiement) AS F_siAnnee_Fiscale, SEC.iID_Statut, SEC.vcCode_Statut,
                    SEA.iID_Statut, SEA.vcCode_Statut,
                    (CASE WHEN PB.tiCode_Version = 0 THEN PB.mIQEE_CreditBase ELSE 0 END)*-1,
                    (CASE WHEN PB.tiCode_Version = 0 THEN pb.mIQEE_Majoration ELSE 0 END)*-1,
                    (CASE WHEN PB.tiCode_Version = 0 THEN PB.mIQEE_CreditBase + pb.mIQEE_Majoration ELSE 0 END)*-1
                FROM 
                    dbo.tblIQEE_PaiementsBeneficiaires PB
                    JOIN #tblIQEE_Conventions C ON C.iID_Convention = PB.iID_Convention
                    JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = PB.iID_Fichier_IQEE AND F.bFichier_Test = 0 AND F.bInd_Simulation = 0
                    JOIN tblIQEE_StatutsFichier SF ON SF.tiID_Statut_Fichier = F.tiID_Statut_Fichier
                    JOIN tblIQEE_TypesEnregistrement TE ON TE.cCode_Type_Enregistrement = '05'
                    JOIN tblIQEE_SousTypeEnregistrement STE ON STE.iID_Sous_Type = PB.iID_Sous_Type
                    JOIN tblIQEE_HistoEvenements HE ON HE.vcCode_Evenement = 'T'+TE.cCode_Type_Enregistrement+STE.cCode_Sous_Type
                                                   AND HE.vcCode_Type = 'TRA_'+ CAST(PB.tiCode_Version AS CHAR(1))
                    JOIN tblIQEE_HistoStatutsEvenement SEC ON SEC.vcCode_Statut = 'TRA_CRO_'+ CASE WHEN SF.vcCode_Statut IN ('CRE','APP') THEN SF.vcCode_Statut ELSE 'TRM' END
                    JOIN tblIQEE_HistoStatutsEvenement SEA ON SEA.vcCode_Statut = CASE WHEN PB.cStatut_Reponse IN ('A','E','R','D','T','X') THEN 'TRA_MAJ_'+PB.cStatut_Reponse ELSE 'TRA_MAJ_IND' END
                    --LEFT JOIN (
                    --        SELECT iID_Paiement_IQEE, SUM(R.mMontant_IQEE_Base) AS mMontant_IQEE_Base, SUM(mMontant_IQEE_Majore) AS mMontant_IQEE_Majore, SUM(mMontant_IQEE) AS mMontant_IQEE
                    --          FROM dbo.tblIQEE_ReponsesPaiement R
                    --         GROUP BY iID_Paiement_IQEE
                    --    ) RPB ON RPB.iID_Paiement_IQEE = PB.iID_Paiement_Beneficiaire
                WHERE 
                    @bUtilise_Statut_IQEE = 1 
                    OR EXISTS( SELECT * FROM tblIQEE_HistoSelectionEvenements SE
                                WHERE SE.iID_Structure_Historique = @iID_Structure_Historique_Selection
                                  AND SE.iID_Evenement = HE.iID_Evenement
                                  AND (SE.iID_Statut IS NULL OR SE.iID_Statut = SEA.iID_Statut))
                
                --**************************************
                --SELECT * FROM #tblIQEE_Evenements
                --**************************************

                DROP TABLE #TBSousTypeEvenement_Transfert
                            
                -- T06
                INSERT INTO #tblIQEE_Evenements (
                    iID_Transaction, iID_Convention, iID_Evenement, vcCode_Evenement, vcCode_Type, 
                    iID_Fichier_IQEE, dtDate_Chronologique, dtDate_Evenement, tiID_Type_Enregistrement,
                    iID_Primaire, iID_Secondaire1, iID_Statut_Chronologique, vcCode_Statut_Chronologique,
                    iID_Statut_A_Jour, vcCode_Statut_A_Jour,
                    mCourant_Credit_Base,
                    mCourant_Majoration,
                    mCourant_IQEE_SAC
                )
                SELECT  
                    DIS.iID_Ligne_Fichier, DIS.iID_Convention, HE.iID_Evenement, HE.vcCode_Evenement, HE.vcCode_Type,
                    F.iID_Fichier_IQEE, F.dtDate_Creation, DIS.dtDate_Evenement, TE.tiID_Type_Enregistrement,
                    DIS.iID_Impot_Special, YEAR(DIS.dtDate_Evenement) AS F_siAnnee_Fiscale, SEC.iID_Statut, SEC.vcCode_Statut,
                    SEA.iID_Statut, SEA.vcCode_Statut,
                    (CASE WHEN DIS.tiCode_Version = 0 THEN DIS.mSolde_IQEE_Base ELSE 0 END + RIS.mMontant_IQEE_Base)*-1,
                    (CASE WHEN DIS.tiCode_Version = 0 THEN DIS.mSolde_IQEE_Majore ELSE 0 END + RIS.mMontant_IQEE_Majore)*-1,
                    (CASE WHEN DIS.tiCode_Version = 0 THEN DIS.mSolde_IQEE ELSE 0 END + RIS.mMontant_IQEE)*-1
                FROM 
                    tblIQEE_ImpotsSpeciaux DIS
                    JOIN #tblIQEE_Conventions C ON C.iID_Convention = DIS.iID_Convention
                    JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = DIS.iID_Fichier_IQEE AND F.bFichier_Test = 0 AND F.bInd_Simulation = 0
                    JOIN tblIQEE_StatutsFichier SF ON SF.tiID_Statut_Fichier = F.tiID_Statut_Fichier
                    JOIN tblIQEE_TypesEnregistrement TE ON TE.cCode_Type_Enregistrement = '06'
                    JOIN tblIQEE_SousTypeEnregistrement STE ON STE.iID_Sous_Type = DIS.iID_Sous_Type
                    JOIN tblIQEE_HistoEvenements HE ON HE.vcCode_Evenement = 'T'+TE.cCode_Type_Enregistrement+STE.cCode_Sous_Type
                                                   AND HE.vcCode_Type = 'TRA_'+ CAST(DIS.tiCode_Version AS CHAR(1))
                    JOIN tblIQEE_HistoStatutsEvenement SEC ON SEC.vcCode_Statut = 'TRA_CRO_'+ CASE WHEN SF.vcCode_Statut IN ('CRE','APP') THEN SF.vcCode_Statut ELSE 'TRM' END
                    JOIN tblIQEE_HistoStatutsEvenement SEA ON SEA.vcCode_Statut = CASE WHEN DIS.cStatut_Reponse IN ('A','E','R','D','T','X') THEN 'TRA_MAJ_'+DIS.cStatut_Reponse ELSE 'TRA_MAJ_IND' END
                    LEFT JOIN (
                            SELECT iID_Impot_Special_IQEE, SUM(mMontant_IQEE_Base) AS mMontant_IQEE_Base, SUM(mMontant_IQEE_Majore) AS mMontant_IQEE_Majore, SUM(mMontant_IQEE) AS mMontant_IQEE
                              FROM tblIQEE_ReponsesImpotsSpeciaux
                             GROUP BY iID_Impot_Special_IQEE
                        ) RIS ON RIS.iID_Impot_Special_IQEE = DIS.iID_Impot_Special
                WHERE 
                    @bUtilise_Statut_IQEE = 1 
                    OR EXISTS( SELECT * FROM tblIQEE_HistoSelectionEvenements SE
                                WHERE SE.iID_Structure_Historique = @iID_Structure_Historique_Selection
                                  AND SE.iID_Evenement = HE.iID_Evenement
                                  AND (SE.iID_Statut IS NULL OR SE.iID_Statut = SEA.iID_Statut))

            END

        ----------
        -- Erreurs
        ----------
        IF @bUtilise_Statut_IQEE = 1 OR
           EXISTS( SELECT * FROM tblIQEE_HistoSelectionEvenements SE
                            JOIN tblIQEE_HistoEvenements E ON E.iID_Evenement = SE.iID_Evenement AND E.vcCode_Type LIKE 'ERR_%'
                    WHERE SE.iID_Structure_Historique = @iID_Structure_Historique_Selection)
            BEGIN
                -- Sélectionner les erreurs
                INSERT INTO #tblIQEE_Evenements (
                    iID_Convention, iID_Evenement, vcCode_Evenement, vcCode_Type,    
                    iID_Fichier_IQEE, dtDate_Chronologique, dtDate_Evenement, tiID_Type_Enregistrement, iID_Sous_Type, 
                    iID_Primaire, iID_Secondaire1, iID_Statut_Chronologique, vcCode_Statut_Chronologique,
                    iID_Statut_A_Jour, vcCode_Statut_A_Jour
                )
                SELECT 
                    C.iID_Convention, HE.iID_Evenement, HE.vcCode_Evenement, HE.vcCode_Type,
                    F.iID_Fichier_IQEE, F.dtDate_Creation, dbo.fnGENE_DateDeFinAvecHeure(E.dtDate_Transaction), E.tiID_Type_Enregistrement, ST.iID_Sous_Type,
                    E.iID_Erreur, E.iID_Enregistrement, SEC.iID_Statut, SEC.vcCode_Statut,
                    SEA.iID_Statut, SEA.vcCode_Statut
                FROM 
                    #tblIQEE_Conventions C
                    CROSS APPLY dbo.fntIQEE_RechercherErreurs(@cID_Langue, NULL, NULL, NULL, C.iID_Convention, NULL, NULL, NULL, NULL, NULL, NULL, NULL) AS E
                    JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = E.iID_Fichier_IQEE AND F.bFichier_Test = 0 AND F.bInd_Simulation = 0
                    LEFT JOIN tblIQEE_SousTypeEnregistrement ST ON ST.tiID_Type_Enregistrement = E.tiID_Type_Enregistrement AND ST.cCode_Sous_Type = E.cCode_Sous_Type
                    JOIN tblIQEE_CategoriesErreur CE ON CE.tiID_Categorie_Erreur = E.tiID_Categorie_Erreur
                    JOIN tblIQEE_StatutsErreur SE ON SE.tiID_Statuts_Erreur = E.tiID_Statuts_Erreur
                    JOIN tblIQEE_HistoEvenements HE ON HE.vcCode_Evenement = 'T'+E.cCode_Type_Enregistrement+ISNULL(E.cCode_Sous_Type,'')
                                                   AND HE.vcCode_Type = 'ERR_'+CE.vcCode_Categorie
                    JOIN tblIQEE_HistoStatutsEvenement SEC ON SEC.vcCode_Statut = 'ERR_CRO_ACO'
                    JOIN tblIQEE_HistoStatutsEvenement SEA ON SEA.vcCode_Statut = CASE WHEN SE.vcCode_Statut IN ('ATR','TAR','TER') THEN 'ERR_MAJ_'+SE.vcCode_Statut ELSE 'ERR_MAJ_IND' END
                WHERE 
                    @bUtilise_Statut_IQEE = 1 
                    OR EXISTS( SELECT * FROM tblIQEE_HistoSelectionEvenements SE
                                WHERE SE.iID_Structure_Historique = @iID_Structure_Historique_Selection
                                  AND SE.iID_Evenement = HE.iID_Evenement
                                  AND (SE.iID_Statut IS NULL OR SE.iID_Statut = SEA.iID_Statut))
            END

        -----------
        -- Réponses
        -----------
        IF @bUtilise_Statut_IQEE = 1 OR
           EXISTS( SELECT * FROM tblIQEE_HistoSelectionEvenements SE
                            JOIN tblIQEE_HistoEvenements E ON E.iID_Evenement = SE.iID_Evenement AND E.vcCode_Type LIKE 'REP_%'
                    WHERE SE.iID_Structure_Historique = @iID_Structure_Historique_Selection)
            BEGIN
                -- Sélectionner les réponses PRO et NOU
                INSERT INTO #tblIQEE_Evenements (
                    iID_Convention, iID_Evenement, vcCode_Evenement, vcCode_Type,    
                    iID_Fichier_IQEE, dtDate_Chronologique, dtDate_Evenement, tiID_Type_Enregistrement,
                    iID_Primaire, iID_Secondaire1, iID_Statut_Chronologique, vcCode_Statut_Chronologique,
                    iID_Statut_A_Jour, vcCode_Statut_A_Jour
                )
                SELECT 
                    C.iID_Convention, HE.iID_Evenement, HE.vcCode_Evenement, HE.vcCode_Type,
                    F1.iID_Fichier_IQEE, F1.dtDate_Paiement, dbo.fnGENE_DateDeFinAvecHeure(CAST(CAST(D.siAnnee_Fiscale AS VARCHAR(4))+'-12-31' AS DATETIME)), TE.tiID_Type_Enregistrement,
                    MIN(RD.iID_Reponse_Demande), RD.iID_Demande_IQEE, SEC.iID_Statut, SEC.vcCode_Statut,
                    SEA.iID_Statut, SEA.vcCode_Statut
                FROM 
                    #tblIQEE_Conventions C
                    JOIN tblIQEE_Demandes D ON D.iID_Convention = C.iID_Convention
                    JOIN tblIQEE_ReponsesDemande RD ON RD.iID_Demande_IQEE = D.iID_Demande_IQEE
                    JOIN tblIQEE_TypesEnregistrement TE ON TE.cCode_Type_Enregistrement = '02'
                    JOIN tblIQEE_Fichiers F1 ON F1.iID_Fichier_IQEE = RD.iID_Fichier_IQEE AND F1.bFichier_Test = 0 AND F1.bInd_Simulation = 0
                    JOIN tblIQEE_Fichiers F2 ON F2.iID_Fichier_IQEE = D.iID_Fichier_IQEE AND F2.bFichier_Test = 0 AND F2.bInd_Simulation = 0
                    JOIN tblIQEE_TypesFichier TF ON TF.tiID_Type_Fichier = F1.tiID_Type_Fichier
                    JOIN tblIQEE_HistoEvenements HE ON HE.vcCode_Evenement = 'T'+TE.cCode_Type_Enregistrement
                                                   AND HE.vcCode_Type = 'REP_'+TF.vcCode_Type_Fichier
                    JOIN tblIQEE_HistoStatutsEvenement SEC ON SEC.vcCode_Statut = 'REP_CRO_IMP'
                    JOIN tblIQEE_HistoStatutsEvenement SEA ON SEA.vcCode_Statut = 'REP_MAJ_'+D.cStatut_Reponse+CASE WHEN D.cStatut_Reponse = 'R' THEN 'D' ELSE '' END
                WHERE 
                    @bUtilise_Statut_IQEE = 1 
                    OR EXISTS( SELECT * FROM tblIQEE_HistoSelectionEvenements SE
                                WHERE SE.iID_Structure_Historique = @iID_Structure_Historique_Selection
                                  AND SE.iID_Evenement = HE.iID_Evenement
                                  AND (SE.iID_Statut IS NULL OR SE.iID_Statut = SEA.iID_Statut))
                GROUP BY 
                    C.iID_Convention, HE.iID_Evenement, HE.vcCode_Evenement, HE.vcCode_Type,
                    F1.iID_Fichier_IQEE, F1.dtDate_Paiement, dbo.fnGENE_DateDeFinAvecHeure(CAST(CAST(D.siAnnee_Fiscale AS VARCHAR(4))+'-12-31' AS DATETIME)), TE.tiID_Type_Enregistrement,
                    RD.iID_Demande_IQEE, SEC.iID_Statut, SEC.vcCode_Statut,
                    SEA.iID_Statut, SEA.vcCode_Statut

                -- Déterminer le statut de la réponse s'il n'y a pas d'IQÉÉ dans la réponse
                UPDATE E SET 
                    iID_Statut_A_Jour = SEA.iID_Statut,
                    vcCode_Statut_A_Jour = SEA.vcCode_Statut
                FROM 
                    #tblIQEE_Evenements E
                    JOIN tblIQEE_HistoStatutsEvenement SEA ON SEA.vcCode_Statut = 'REP_MAJ_RP'
                WHERE 
                    E.vcCode_Statut_A_Jour = 'REP_MAJ_RD'
                    AND (SELECT SUM(CASE WHEN ISNULL(TR.bInverser_Signe_Pour_Injection,0) = 0 THEN ISNULL(RD.mMontant,0) ELSE ISNULL(RD.mMontant,0)*-1 END)
                           FROM tblIQEE_ReponsesDemande RD
                                JOIN tblIQEE_TypesReponse TR ON TR.tiID_Type_Reponse = RD.tiID_Type_Reponse
                                                            AND TR.vcCode IN ('CDB','MAJ','CBD','MAD')  --NCB, NMA
                           WHERE RD.iID_Demande_IQEE = E.iID_Secondaire1 AND RD.iID_Fichier_IQEE = E.iID_Fichier_IQEE
                        ) = 0

                -- Déterminer le statut de la réponse si le maximum d'IQÉÉ a été obtenu
                UPDATE E SET 
                    iID_Statut_A_Jour = SEA.iID_Statut,
                    vcCode_Statut_A_Jour = SEA.vcCode_Statut
                FROM 
                    #tblIQEE_Evenements E
                    JOIN tblIQEE_HistoStatutsEvenement SEA ON SEA.vcCode_Statut = 'REP_MAJ_RM'
                WHERE 
                    E.vcCode_Statut_A_Jour = 'REP_MAJ_RD'
                    AND EXISTS ( SELECT * FROM tblIQEE_ReponsesDemande RD
                                          JOIN tblIQEE_JustificationsRQ J ON J.tiID_Justification_RQ = RD.tiID_Justification_RQ
                                                                         AND J.cCode IN ('11','12','22','24')
                                  WHERE RD.iID_Demande_IQEE = E.iID_Secondaire1
                                    AND RD.iID_Fichier_IQEE = E.iID_Fichier_IQEE)

                -- Déterminer le statut de la réponse si l'IQÉÉ demandé n'a pas entièrement été obtenu
                UPDATE E SET 
                    iID_Statut_A_Jour = SEA.iID_Statut,
                    vcCode_Statut_A_Jour = SEA.vcCode_Statut
                FROM 
                    #tblIQEE_Evenements E
                    JOIN tblIQEE_Demandes D ON D.iID_Demande_IQEE = E.iID_Secondaire1
                    JOIN tblIQEE_HistoStatutsEvenement SEA ON SEA.vcCode_Statut = 'REP_MAJ_RI'
                WHERE 
                    E.vcCode_Statut_A_Jour = 'REP_MAJ_RD'
                    -- TODO: Paramétriser le 10% de crédit de base
                    AND (SELECT SUM(CASE WHEN ISNULL(TR.bInverser_Signe_Pour_Injection,0) = 0 THEN ISNULL(RD.mMontant,0) ELSE ISNULL(RD.mMontant,0)*-1 END)
                           FROM tblIQEE_ReponsesDemande RD
                                JOIN tblIQEE_TypesReponse TR ON TR.tiID_Type_Reponse = RD.tiID_Type_Reponse AND TR.vcCode IN ('CDB','CBD')
                          WHERE RD.iID_Demande_IQEE = E.iID_Secondaire1 AND RD.iID_Fichier_IQEE = E.iID_Fichier_IQEE
                        ) < ROUND(D.mTotal_Cotisations_Subventionnables * 10 / 100,2)

                -- TODO: Même chose pour les réponses COT
                --26    REP_MAJ_A    Annulation en attente de RQ???
            END

        -----------------------
        -- Annulations/reprises
        -----------------------
        IF @bUtilise_Statut_IQEE = 1 OR
           EXISTS( SELECT * FROM tblIQEE_HistoSelectionEvenements SE
                            JOIN tblIQEE_HistoEvenements E ON E.iID_Evenement = SE.iID_Evenement AND E.vcCode_Type = 'A/R'
                    WHERE SE.iID_Structure_Historique = @iID_Structure_Historique_Selection)
            BEGIN
                -- Sélectionner les annulations/reprises
                INSERT INTO #tblIQEE_Evenements (
                    iID_Transaction, iID_Convention, iID_Evenement, vcCode_Evenement, vcCode_Type,    
                    iID_Fichier_IQEE, dtDate_Chronologique, dtDate_Evenement, tiID_Type_Enregistrement,
                    iID_Primaire, iID_Secondaire1, iID_Statut_Chronologique, vcCode_Statut_Chronologique,
                    iID_Statut_A_Jour, vcCode_Statut_A_Jour
                )
                SELECT 
                    D.iID_Ligne_Fichier, C.iID_Convention, HE.iID_Evenement, HE.vcCode_Evenement, HE.vcCode_Type,
                    D.iID_Fichier_IQEE, A.dtDate_Demande_Annulation, dbo.fnGENE_DateDeFinAvecHeure(CAST(CAST(D.siAnnee_Fiscale AS VARCHAR(4))+'-12-31' AS DATETIME)), TE.tiID_Type_Enregistrement,
                    A.iID_Annulation, A.iID_Enregistrement_Demande_Annulation, SEC.iID_Statut, SEC.vcCode_Statut,
                    SEA.iID_Statut, SEA.vcCode_Statut
                FROM 
                    #tblIQEE_Conventions C
                    JOIN tblIQEE_Demandes D ON D.iID_Convention = C.iID_Convention
                    JOIN tblIQEE_Annulations A ON A.iID_Enregistrement_Demande_Annulation = D.iID_Demande_IQEE
                                              AND (
                                                    (A.iID_Session IS NULL AND A.dtDate_Creation_Fichiers IS NULL AND A.vcCode_Simulation IS NULL)
                                                    OR (
                                                        A.vcCode_Simulation IS NULL
                                                        AND EXISTS( SELECT * FROM tblIQEE_Fichiers F2
                                                                     WHERE F2.iID_Session = A.iID_Session
                                                                       AND F2.dtDate_Creation_Fichiers = A.dtDate_Creation_Fichiers
                                                                       AND F2.bFichier_Test = 0 AND F2.bInd_Simulation = 0
                                                                  )
                                                       )
                                                  )
                    JOIN tblIQEE_TypesAnnulation TA ON TA.iID_Type_Annulation = A.iID_Type_Annulation
                    JOIN tblIQEE_StatutsAnnulation SA ON SA.iID_Statut_Annulation = A.iID_Statut_Annulation
                    JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
                    JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE AND F.bFichier_Test = 0 AND F.bInd_Simulation = 0
                    JOIN tblIQEE_HistoEvenements HE ON HE.vcCode_Evenement = 'T'+TE.cCode_Type_Enregistrement AND HE.vcCode_Type = 'A/R'
                    JOIN tblIQEE_HistoStatutsEvenement SEC ON SEC.vcCode_Statut = CASE WHEN TA.vcCode_Type IN ('MAN','AUT','CON') THEN 'A/R_CRO_'+TA.vcCode_Type ELSE 'A/R_CRO_IND' END
                    JOIN tblIQEE_HistoStatutsEvenement SEA ON SEA.vcCode_Statut = CASE WHEN SA.vcCode_Statut IN ('MAN','ASS','DAR','DAN','ACA','ARA',
                                                                                                                 'A0A','AOA','ACE','ARE','A0E','AOE',
                                                                                                                 'ARI','A0I','AOI','ANC','ARC','A0C','AOC')
                                                                                       THEN 'A/R_MAJ_'+SA.vcCode_Statut
                                                                                       ELSE 'A/R_MAJ_IND'
                                                                                  END
                WHERE 
                    TE.cCode_Type_Enregistrement = '02' 
                    AND NOT (
                        EXISTS(SELECT * FROM tblIQEE_Demandes DA WHERE DA.iID_Demande_IQEE = A.iID_Enregistrement_Annulation)
                        --AND EXISTS(SELECT * FROM tblIQEE_Demandes DR WHERE DR.iID_Demande_IQEE = A.iID_Enregistrement_Reprise)
                    )
                    AND (
                        @bUtilise_Statut_IQEE = 1 
                        OR EXISTS( SELECT * FROM tblIQEE_HistoSelectionEvenements SE
                                    WHERE SE.iID_Structure_Historique = @iID_Structure_Historique_Selection
                                      AND SE.iID_Evenement = HE.iID_Evenement
                                      AND (SE.iID_Statut IS NULL OR SE.iID_Statut = SEA.iID_Statut))
                    )

                -- TODO: Faire la même chose pour les autres types de transaction
            END

        -------------------
        -- Début du contrat
        -------------------
        IF EXISTS( SELECT * FROM tblIQEE_HistoSelectionEvenements SE
                            JOIN tblIQEE_HistoEvenements E ON E.iID_Evenement = SE.iID_Evenement AND E.vcCode_Evenement = 'DEBUT'
                    WHERE SE.iID_Structure_Historique = @iID_Structure_Historique_Selection)
            BEGIN
                -- Sélectionner les conventions
                INSERT INTO #tblIQEE_Evenements (
                    iID_Convention, iID_Evenement, vcCode_Evenement, vcCode_Type,    
                    dtDate_Chronologique, dtDate_Evenement,
                    iID_Primaire, iID_Statut_Chronologique, vcCode_Statut_Chronologique,
                    iID_Statut_A_Jour, vcCode_Statut_A_Jour)
                SELECT 
                    C.iID_Convention, HE.iID_Evenement, HE.vcCode_Evenement, HE.vcCode_Type,
                    C.dtDate_Debut_Convention, C.dtDate_Debut_Convention,
                    C.iID_Convention, SEC.iID_Statut, SEC.vcCode_Statut,
                    SEA.iID_Statut, SEA.vcCode_Statut
                FROM 
                    #tblIQEE_Conventions C
                    JOIN tblIQEE_HistoEvenements HE ON HE.vcCode_Evenement = 'DEBUT' AND HE.vcCode_Type = 'REGIME'
                    JOIN tblIQEE_HistoStatutsEvenement SEC ON SEC.vcCode_Statut = 'CRO_CREE'
                    JOIN tblIQEE_HistoStatutsEvenement SEA ON SEA.vcCode_Statut = CASE WHEN C.vcStatut_Convention IN ('FRM','PRP','REE','TRA') THEN 'CON_MAJ_'+C.vcStatut_Convention ELSE 'CON_MAJ_IND' END
                WHERE 
                    @bUtilise_Statut_IQEE = 1 
                    OR EXISTS( SELECT * FROM tblIQEE_HistoSelectionEvenements SE
                                WHERE SE.iID_Structure_Historique = @iID_Structure_Historique_Selection
                                  AND SE.iID_Evenement = HE.iID_Evenement
                                  AND (SE.iID_Statut IS NULL OR SE.iID_Statut = SEA.iID_Statut))
            END

        ------------------------------
        -- Changements de bénéficiaire
        ------------------------------
        IF EXISTS( SELECT * FROM tblIQEE_HistoSelectionEvenements SE
                            JOIN tblIQEE_HistoEvenements E ON E.iID_Evenement = SE.iID_Evenement AND E.vcCode_Evenement LIKE 'BENEF_%'
                    WHERE SE.iID_Structure_Historique = @iID_Structure_Historique_Selection)
            BEGIN
                -- Sélectionner les changements de bénéficiaire
                INSERT INTO #tblIQEE_Evenements (
                    iID_Convention, iID_Evenement, vcCode_Evenement, vcCode_Type,    
                    dtDate_Chronologique, dtDate_Evenement,
                    iID_Primaire, iID_Statut_Chronologique, vcCode_Statut_Chronologique,
                    iID_Statut_A_Jour, vcCode_Statut_A_Jour
                )
                SELECT 
                    C.iID_Convention, HE.iID_Evenement, HE.vcCode_Evenement, HE.vcCode_Type,
                    CB.dtDate_Changement_Beneficiaire, CB.dtDate_Changement_Beneficiaire,
                    CB.iID_Changement_Beneficiaire, SEC.iID_Statut, SEC.vcCode_Statut,
                    SEA.iID_Statut, SEA.vcCode_Statut
                FROM 
                    #tblIQEE_Conventions C
                    CROSS APPLY dbo.fntCONV_RechercherChangementsBeneficiaire(@cID_Langue, NULL, C.iID_Convention, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL) CB
                    JOIN tblIQEE_HistoEvenements HE ON HE.vcCode_Evenement = 'BENEF_'+CASE WHEN CB.vcCode_Raison = 'INI' THEN 'INI' ELSE 'CHG' END AND HE.vcCode_Type = 'RAISON'
                    JOIN tblIQEE_HistoStatutsEvenement SEC ON SEC.vcCode_Statut = CASE WHEN CB.vcCode_Raison = 'INI' THEN 'CRO_CREE' ELSE 'CRO_CHANG' END
                    JOIN tblIQEE_HistoStatutsEvenement SEA ON SEA.vcCode_Statut = CASE WHEN CB.vcCode_Raison = 'INI' THEN 'CHB_MAJ_INI' 
                                                                                       WHEN dbo.fnIQEE_RemplacementBeneficiaireReconnu(CB.iID_Changement_Beneficiaire, NULL, NULL, NULL, NULL, NULL, NULL) <> 0 THEN 'CHB_MAJ_REC'
                                                                                       ELSE 'CHB_MAJ_NRE'
                                                                                  END
                WHERE 
                    @bUtilise_Statut_IQEE = 1 
                    OR EXISTS( SELECT * FROM tblIQEE_HistoSelectionEvenements SE
                                WHERE SE.iID_Structure_Historique = @iID_Structure_Historique_Selection
                                  AND SE.iID_Evenement = HE.iID_Evenement
                                  AND (SE.iID_Statut IS NULL OR SE.iID_Statut = SEA.iID_Statut))
            END

        -----------------------------------
        -- Changements d'état de convention
        -----------------------------------
        IF EXISTS( SELECT * FROM tblIQEE_HistoSelectionEvenements SE
                            JOIN tblIQEE_HistoEvenements E ON E.iID_Evenement = SE.iID_Evenement AND E.vcCode_Evenement = 'ETAT'
                    WHERE SE.iID_Structure_Historique = @iID_Structure_Historique_Selection)
            BEGIN
                -- Sélectionner les changements d'état
                INSERT INTO #tblIQEE_Evenements(
                    iID_Convention, iID_Evenement, vcCode_Evenement, vcCode_Type,    
                    dtDate_Chronologique, dtDate_Evenement,
                    iID_Primaire, iID_Statut_Chronologique, vcCode_Statut_Chronologique,
                    iID_Statut_A_Jour, vcCode_Statut_A_Jour
                )
                SELECT 
                    C.iID_Convention, HE.iID_Evenement, HE.vcCode_Evenement, HE.vcCode_Type,
                    CCS.StartDate, CCS.StartDate,
                    CCS.ConventionConventionStateID, SEC.iID_Statut, SEC.vcCode_Statut,
                    SEA.iID_Statut, SEA.vcCode_Statut
                FROM 
                    #tblIQEE_Conventions C
                    JOIN Un_ConventionConventionState CCS ON CCS.ConventionID = C.iID_Convention
                    JOIN tblIQEE_HistoEvenements HE ON HE.vcCode_Evenement = 'ETAT' AND HE.vcCode_Type = 'ETAT'
                    JOIN tblIQEE_HistoStatutsEvenement SEC ON SEC.vcCode_Statut = 'CRO_CREE'
                    JOIN tblIQEE_HistoStatutsEvenement SEA ON SEA.vcCode_Statut = CASE WHEN C.vcStatut_Convention IN ('FRM','PRP','REE','TRA') THEN 'CON_MAJ_'+C.vcStatut_Convention ELSE 'CON_MAJ_IND' END
                WHERE 
                    @bUtilise_Statut_IQEE = 1 
                    OR EXISTS( SELECT * FROM tblIQEE_HistoSelectionEvenements SE
                                WHERE SE.iID_Structure_Historique = @iID_Structure_Historique_Selection
                                  AND SE.iID_Evenement = HE.iID_Evenement
                                  AND (SE.iID_Statut IS NULL OR SE.iID_Statut = SEA.iID_Statut))
            END

        ------
        -- PAE
        ------
        IF EXISTS( SELECT * FROM tblIQEE_HistoSelectionEvenements SE
                            JOIN tblIQEE_HistoEvenements E ON E.iID_Evenement = SE.iID_Evenement AND E.vcCode_Evenement = 'PAE'
                    WHERE SE.iID_Structure_Historique = @iID_Structure_Historique_Selection)
            BEGIN
                -- Sélectionner les PAE
                INSERT INTO #tblIQEE_Evenements (
                    iID_Convention, iID_Evenement, vcCode_Evenement, vcCode_Type,    
                    dtDate_Chronologique, dtDate_Evenement,
                    iID_Primaire, iID_Secondaire1, iID_Secondaire2, iID_Statut_Chronologique, vcCode_Statut_Chronologique,
                    iID_Statut_A_Jour, vcCode_Statut_A_Jour
                )
                SELECT --'PAE',
                    C.iID_Convention, HE.iID_Evenement, HE.vcCode_Evenement, HE.vcCode_Type,
                    O.dtSequence_Operation, O.OperDate,
                    SP.ScholarshipPmtID, O.OperID, CH.iCheckID, SEC.iID_Statut, SEC.vcCode_Statut,
                    SEA.iID_Statut, SEA.vcCode_Statut
                FROM 
                    #tblIQEE_Conventions C
                    JOIN Un_Scholarship S ON S.ConventionID = C.iID_Convention AND S.ScholarshipStatusID IN ('PAD','WAI')
                    JOIN Un_ScholarshipPmt SP ON SP.ScholarshipID = S.ScholarshipID
                    JOIN Un_Oper O ON O.OperID = SP.OperID
                    JOIN dbo.Un_Convention C2 ON C2.ConventionID = C.iID_Convention
                    JOIN Un_Plan P ON P.PlanID = C2.PlanID
                    LEFT JOIN Un_OperCancelation OC1 ON OC1.OperSourceID = O.OperID
                    LEFT JOIN Un_OperCancelation OC2 ON OC2.OperID = O.OperID
                    JOIN Un_OperLinkToCHQOperation OL ON OL.OperID = O.OperID
                    JOIN CHQ_Operation CO1 ON CO1.iOperationID = OL.iOperationID
                    LEFT JOIN CHQ_Check CH ON CH.iCheckID = (SELECT MAX(CH2.iCheckID) 
                                                               FROM CHQ_OperationDetail OD
                                                                    JOIN CHQ_CheckOperationDetail COD ON COD.iOperationDetailID = OD.iOperationDetailID
                                                                    JOIN CHQ_Check CH2 ON CH2.iCheckID = COD.iCheckID
                                                              WHERE OD.iOperationID = CO1.iOperationID)
                    JOIN tblIQEE_HistoEvenements HE ON HE.vcCode_Evenement = 'PAE' AND HE.vcCode_Type = CASE WHEN P.PlanTypeID = 'COL' THEN 'BOURSE' ELSE 'PAE' END
                    JOIN tblIQEE_HistoStatutsEvenement SEC ON SEC.vcCode_Statut = 'CRO_CREE'
                    JOIN tblIQEE_HistoStatutsEvenement SEA ON SEA.vcCode_Statut = 'CHQ_MAJ_'+CASE WHEN CH.iCheckStatusID BETWEEN 1 AND 7 THEN CAST(CH.iCheckStatusID AS CHAR(1)) ELSE 'IND' END
-- TODO: Afficher aussi les PAE d'annulation?
                WHERE 
                    OC1.OperSourceID IS NULL
                    AND OC2.OperID IS NULL
                    AND (   @bUtilise_Statut_IQEE = 1 
                            OR EXISTS( SELECT * FROM tblIQEE_HistoSelectionEvenements SE
                                        WHERE SE.iID_Structure_Historique = @iID_Structure_Historique_Selection
                                          AND SE.iID_Evenement = HE.iID_Evenement
                                          AND (SE.iID_Statut IS NULL OR SE.iID_Statut = SEA.iID_Statut) )
                        )
            END

        ---------------------
        -- Notes de type IQÉÉ
        ---------------------
        IF EXISTS( SELECT * FROM tblIQEE_HistoSelectionEvenements SE
                            JOIN tblIQEE_HistoEvenements E ON E.iID_Evenement = SE.iID_Evenement AND E.vcCode_Evenement = 'NOTE'
                    WHERE SE.iID_Structure_Historique = @iID_Structure_Historique_Selection)
            BEGIN
                -- Sélectionner les notes de type IQÉÉ
                INSERT INTO #tblIQEE_Evenements (
                    iID_Convention, iID_Evenement, vcCode_Evenement, vcCode_Type,    
                    dtDate_Chronologique, dtDate_Evenement,
                    iID_Primaire, iID_Statut_Chronologique, vcCode_Statut_Chronologique,
                    iID_Statut_A_Jour, vcCode_Statut_A_Jour
                )
                SELECT 
                    C.iID_Convention, HE.iID_Evenement, HE.vcCode_Evenement, HE.vcCode_Type,
                    N.dtDateCreation, N.dtDateCreation,
                    iID_Note, SEC.iID_Statut, SEC.vcCode_Statut,
                    SEA.iID_Statut, SEA.vcCode_Statut
                FROM 
                    #tblIQEE_Conventions C
                    JOIN tblGENE_Note N ON N.iID_HumainClient = C.iID_Souscripteur
                    JOIN tblGENE_TypeNote TN ON TN.iId_TypeNote = N.iId_TypeNote
                    JOIN tblIQEE_HistoEvenements HE ON HE.vcCode_Evenement = 'NOTE' AND HE.vcCode_Type = 'TITRE'
                    JOIN tblIQEE_HistoStatutsEvenement SEC ON SEC.vcCode_Statut = 'NOT_CRO_ECR'
                    JOIN tblIQEE_HistoStatutsEvenement SEA ON SEA.vcCode_Statut = 'VIDE'
                WHERE 
                    (   REPLACE(N.vcTitre, 'É', 'E') LIKE '%IQEE%'
                        OR REPLACE(CAST(N.tTexte AS VARCHAR), 'É', 'E') LIKE '%IQEE%'
                        OR TN.cCodeTypeNote = 'IQEE'
                    )
                    AND (   @bUtilise_Statut_IQEE = 1 
                            OR EXISTS( SELECT * FROM tblIQEE_HistoSelectionEvenements SE
                                        WHERE SE.iID_Structure_Historique = @iID_Structure_Historique_Selection
                                          AND SE.iID_Evenement = HE.iID_Evenement
                                          AND (SE.iID_Statut IS NULL OR SE.iID_Statut = SEA.iID_Statut)
                                     )
                        )
            END

        ---------------------------
        -- Remboursements intégraux
        ---------------------------
        -- TODO: À faire quand la sélection sera définitive dans la transaction 06-23
            --174    RI    Remboursement intégral à %vcNom_Destinataire%    PREUVE    Avec preuve d'inscription
            --175    RI    Remboursement intégral à %vcNom_Destinataire%    SANS    Sans preuve d'inscription
            -- Représenter les 3 catégories du concept.   Prévoir un "Indéterminé" pour les retraits de d'autres types.

        -------------
        -- Transferts
        -------------
        -- TODO: À faire quand la sélection sera définitive dans la transaction 04
            --164    TRA_INT    Transfert interne    OUT_PART    Cédant - partiel
            --165    TRA_INT    Transfert interne    OUT_TOTAL    Cédant - total
            --167    TRA_INT    Transfert interne    IN_PART    Cessionnaire - partiel
            --168    TRA_INT    Transfert interne    IN_TOTAL    Cessionnaire - total
            -- Séparer RIO des autres transferts?
            --169    TRA_EXT    Transfert avec %vcNom_Promoteur%    OUT_PART    Cédant - partiel
            --170    TRA_EXT    Transfert avec %vcNom_Promoteur%    OUT_TOTAL    Cédant - total
            --171    TRA_EXT    Transfert avec %vcNom_Promoteur%    IN_PART    Cessionnaire - partiel
            --172    TRA_EXT    Transfert avec %vcNom_Promoteur%    IN_TOTAL    Cessionnaire - total

            --65    TRF_MAJ_AUT    Autorisé
            --66    TRF_MAJ_AUT2011    Autorisé - Mesure 2011
            --67    TRF_MAJ_NAU    Non autorisé

            --68    CHQ_MAJ_1    Proposition
            --69    CHQ_MAJ_2    Proposition - Accepté
            --70    CHQ_MAJ_3    Proposition - Refusé
            --71    CHQ_MAJ_4    Imprimé
            --72    CHQ_MAJ_5    Annulé
            --73    CHQ_MAJ_6    Concilié
            --74    CHQ_MAJ_7    Externe
            --75    CHQ_MAJ_IND    Indéterminé

            --56    CRO_CREE    Crée

        -------------------------------------------------------------------------------------------------------------
        --
        -- Déterminer le statut IQÉÉ de la convention lorsqu'utilisé par la structure de sélection ou de présentation
        --
        -------------------------------------------------------------------------------------------------------------
        IF @bUtilise_Statut_IQEE = 1
            BEGIN
                ----------------------------------------------------------
                -- Déterminer le statut IQÉÉ des conventions sélectionnées
                ----------------------------------------------------------
                -- TODO: Ajouter un statut lorsqu'il a des cotisations pas subventionnée? Oui, requis par les outils RIN et PAE de l'individuel.  Utiliser la simulation?  Ça serait trop long.
                --         Juste prendre les cotisations et faire le lien avec les demandes en vigueur si le montant de la demande est <> 0.
                -- IQÉÉ à demander    GUI doit agir    Demandes d’IQÉÉ incomplètes.  En attente de la fin de l’année fiscale et de la création d’un nouveau fichier de transactions.

                --Statut            Type            Commentaires
                ------------------  --------------  ----------------------------------
                --Inconnue de RQ    Rien à faire    Aucune transaction à RQ.
                --Rejet actif        GUI doit agir    Rejet traitable par les opérations (Geneviève/France).  
                --Erreur active        GUI doit agir    Erreur de RQ à traiter par les opérations ou déjà traitée mais en attente de la création d’un nouveau fichier de transactions.
                --A/R en attente    GUI doit agir    Une demande d’annulation/reprise manuelle a été faite par les opérations et est en attendre de la création d’un nouveau fichier de transactions.
                --IQÉÉ à demander    GUI doit agir    Demandes d’IQÉÉ incomplètes.  En attente de la fin de l’année fiscale et de la création d’un nouveau fichier de transactions.
                --En attente de RQ    RQ doit agir    Une ou plusieurs transactions sont en attente d’une réponse de RQ.
                --OK                Rien à faire    La convention est à jour dans l’IQÉÉ.  Pas de rejet à traiter.  Pas d’erreur à traiter.  Pas d’annulation/reprise en attente de traitement.  Tous les dépôts ont menés à une demande de l’IQÉÉ et toutes ces transactions ont reçues au moins une réponse avec ou sans montant d’IQÉÉ.
                --                                    Avertissement : Il n’est pas toujours possible de savoir si nous devons recevoir la majoration dans le futur.  Parce que si le bénéficiaire n’a pas droit à la majoration, on ne sais pas pourquoi.  À moins que l’on reçoive un code comme quoi le revenu familial est trop élevé, ce qui n’est pas toujours le cas.

                UPDATE #tblIQEE_Conventions
                SET vcCode_Statut = CASE WHEN EXISTS( SELECT * FROM #tblIQEE_Evenements E
                                                       WHERE E.vcCode_Statut_A_Jour = 'REJ_MAJ_ACO') THEN 'REJ'
                                         WHEN dbo.fnIQEE_ConventionConnueRQ(#tblIQEE_Conventions.iID_Convention,DEFAULT) IS NULL THEN 'INC'
                                         WHEN EXISTS( SELECT * FROM #tblIQEE_Evenements E
                                                       WHERE E.vcCode_Statut_A_Jour IN ('ERR_MAJ_ATR','ERR_MAJ_TAR')) THEN 'ERR'
                                         WHEN EXISTS( SELECT * FROM #tblIQEE_Evenements E
                                                       WHERE E.vcCode_Statut_A_Jour = 'A/R_MAJ_MAN') THEN 'ANN'
                                         WHEN EXISTS( SELECT * FROM #tblIQEE_Evenements E
                                                       WHERE E.vcCode_Statut_A_Jour IN ('TRA_MAJ_CRE','TRA_MAJ_APP','TRA_MAJ_A','TRA_MAJ_D','A/R_MAJ_ACA','A/R_MAJ_ARA','A/R_MAJ_A0A','A/R_MAJ_AOA')) THEN 'ATT'
                                         ELSE 'NOR'
                                    END

                ---------------------------------------------------------------------------------------------------
                -- Retourner le statut de la convention si l'exécution de la procédure était uniquement dans ce but
                ---------------------------------------------------------------------------------------------------
                IF @bRetourner_Statut_IQEE_Convention = 1
                    BEGIN
                        SELECT @vcCode_Statut = C.vcCode_Statut
                          FROM #tblIQEE_Conventions C

                        -- Retourner 1 lors de la réussite du traitement
                        RETURN 1
                    END
        
                -------------------------------------------------------------------------------------------------------------------------------------------------
                -- Supprimer les événements qui ne font pas partie de la sélection mais qui avait été créer malgré tout pour déterminer le statut des conventions
                -------------------------------------------------------------------------------------------------------------------------------------------------
                DELETE #tblIQEE_Evenements
                  FROM #tblIQEE_Evenements E
                 WHERE NOT EXISTS( SELECT * FROM tblIQEE_HistoSelectionEvenements SE
                                    WHERE SE.iID_Structure_Historique = @iID_Structure_Historique_Selection
                                      AND SE.iID_Evenement = E.iID_Evenement
                                      AND (SE.iID_Statut IS NULL OR SE.iID_Statut = E.iID_Statut_A_Jour))

                ----------------------------------------------------
                -- Trouver l'identifiant des statuts des conventions
                ----------------------------------------------------
                UPDATE C SET 
                    iID_Statut_Convention = SC.iID_Statut_Convention,
                    vcDescription_Statut = COALESCE(dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoStatutsConventions','vcDescription',SC.iID_Statut_Convention,NULL,@cID_Langue),SC.vcDescription)
                FROM 
                    #tblIQEE_Conventions C
                    JOIN tblIQEE_HistoStatutsConventions SC ON SC.vcCode_Statut = C.vcCode_Statut
            END

        ----------------------------------------------------------------------------------------------------------------------
        --
        -- Déterminer les colonnes d'informations de l'historique selon la présentation choisie et les droits de l'utilisateur
        --
        ----------------------------------------------------------------------------------------------------------------------


        ---------------------------------------------------------------
        -- Déterminer les informations pour les actions de l'historique
        ---------------------------------------------------------------
        -- Gestion des erreurs
        IF dbo.fnSECU_ObtenirAccessibiliteDroitUtilisateur(CAST(ISNULL(@iID_Utilisateur,0) AS VARCHAR(255)),'IQEE_ERREURS_CONSULTER') = 1
            BEGIN
                UPDATE #tblIQEE_Evenements SET iID_Enregistrement = E.iID_Primaire
                  FROM #tblIQEE_Evenements E
                 WHERE E.vcCode_Statut_A_Jour = 'TRA_MAJ_E'

                UPDATE #tblIQEE_Evenements SET iID_Enregistrement = E.iID_Secondaire1
                  FROM #tblIQEE_Evenements E
                 WHERE E.vcCode_Statut_A_Jour LIKE 'ERR_%'
            END

        -- Modification d'une erreur en particulier
        IF dbo.fnSECU_ObtenirAccessibiliteDroitUtilisateur(CAST(ISNULL(@iID_Utilisateur,0) AS VARCHAR(255)),'IQEE_ERREURS_MODIFIER') = 1
            BEGIN
                UPDATE #tblIQEE_Evenements SET iID_Erreur = E.iID_Primaire
                  FROM #tblIQEE_Evenements E
                 WHERE E.vcCode_Statut_A_Jour LIKE 'ERR_%'

                UPDATE #tblIQEE_Evenements SET 
                    iID_Erreur = (SELECT MAX(E2.iID_Erreur) FROM tblIQEE_Erreurs E2
                                   WHERE E2.tiID_Type_Enregistrement = E.tiID_Type_Enregistrement
                                     AND E2.iID_Enregistrement = E.iID_Primaire)
                  FROM #tblIQEE_Evenements E
                 WHERE E.vcCode_Type LIKE 'TRA_%'
                   AND E.vcCode_Statut_A_Jour = 'TRA_MAJ_E'
            END

        -- Annulations/reprises manuelles
        IF dbo.fnSECU_ObtenirAccessibiliteDroitUtilisateur(CAST(ISNULL(@iID_Utilisateur,0) AS VARCHAR(255)),'IQEE_EVENEMENT_ANNULATION_MANUELLES') = 1
            BEGIN
                -- Disponibilité de la demande d'annulation manuelle
                -- TODO: Permettre l'annulation/reprise manuelle sur une transaction de reprise à 0$?  Peut-être sur les annulations reprise à 0$ qui n'ont pas donné lieu à des transactions
                --       de reprise de type originale.  Autrement dit, il faudrait distinguer une reprise à 0$ qui annule une transaction de demande par rapport à une reprise à 0$
                --       qui est accessoire dans le but de modifier des informations pas amendable.
                UPDATE #tblIQEE_Evenements SET bAnnulation_Manuelle = 1
                  FROM #tblIQEE_Evenements E
                 WHERE E.vcCode_Type IN ('TRA_0','TRA_2')
                   AND E.vcCode_Statut_A_Jour IN ('TRA_MAJ_CRE','TRA_MAJ_APP','TRA_MAJ_A','TRA_MAJ_R')
                   AND EXISTS( SELECT * FROM dbo.fntIQEE_RechercherRaisonsAnnulation(@cID_Langue, NULL, NULL, 1, NULL, 'MAN', E.tiID_Type_Enregistrement, E.iID_Sous_Type, 1, NULL))

                -- Identifiants des demandes d'annulation/reprise manuelles qui peuvent être supprimées
                UPDATE #tblIQEE_Evenements SET vcIDs_Annulations_Manuelles = CAST(E.iID_Primaire AS VARCHAR)
                  FROM #tblIQEE_Evenements E
                 WHERE E.vcCode_Type = 'A/R'
                   AND E.vcCode_Statut_A_Jour = 'A/R_MAJ_MAN'

                -- Identifiants des demandes d'annulation/reprise manuelles qui peuvent être supprimées pour chaque transaction
                DECLARE curAnnulations_Manuelles CURSOR LOCAL FAST_FORWARD 
                    FOR SELECT E.iID_Evenement_Historique,A.iID_Annulation
                          FROM #tblIQEE_Evenements E
                               JOIN tblIQEE_Annulations A ON A.tiID_Type_Enregistrement = E.tiID_Type_Enregistrement
                                                         AND A.iID_Enregistrement_Demande_Annulation = E.iID_Primaire
                                                         AND A.iID_Session IS NULL
                                                         AND A.dtDate_Creation_Fichiers IS NULL
                                                         AND A.vcCode_Simulation IS NULL
                               JOIN tblIQEE_TypesAnnulation TA ON TA.iID_Type_Annulation = A.iID_Type_Annulation
                                                              AND TA.vcCode_Type = 'MAN'
                               JOIN tblIQEE_StatutsAnnulation SA ON SA.iID_Statut_Annulation = A.iID_Statut_Annulation
                                                                AND SA.vcCode_Statut = 'MAN'
                         WHERE E.vcCode_Type IN ('TRA_0','TRA_2')
                         ORDER BY E.iID_Evenement_Historique,A.iID_Annulation

                SET @iID_Ancien_Evenement_Historique = 0
                OPEN curAnnulations_Manuelles
                FETCH NEXT FROM curAnnulations_Manuelles INTO @iID_Evenement_Historique,@iID_Annulation
                WHILE @@FETCH_STATUS = 0
                    BEGIN
                        IF @iID_Evenement_Historique <> @iID_Ancien_Evenement_Historique
                            BEGIN
                                IF @iID_Ancien_Evenement_Historique <> 0
                                    UPDATE #tblIQEE_Evenements SET vcIDs_Annulations_Manuelles = @vcIDs_Annulations_Manuelles
                                     WHERE iID_Evenement_Historique = @iID_Ancien_Evenement_Historique
                                
                                SET @iID_Ancien_Evenement_Historique = @iID_Evenement_Historique
                                SET @vcIDs_Annulations_Manuelles = CAST(@iID_Annulation AS VARCHAR)
                            END
                        ELSE
                            SET @vcIDs_Annulations_Manuelles = @vcIDs_Annulations_Manuelles + ','+CAST(@iID_Annulation AS VARCHAR)
                        FETCH NEXT FROM curAnnulations_Manuelles INTO @iID_Evenement_Historique,@iID_Annulation
                    END

                CLOSE curAnnulations_Manuelles
                DEALLOCATE curAnnulations_Manuelles

                IF @iID_Ancien_Evenement_Historique <> 0
                    UPDATE #tblIQEE_Evenements SET vcIDs_Annulations_Manuelles = @vcIDs_Annulations_Manuelles
                     WHERE iID_Evenement_Historique = @iID_Ancien_Evenement_Historique
            END

        -- Déplacement par association
        IF dbo.fnSECU_ObtenirAccessibiliteDroitUtilisateur(CAST(ISNULL(@iID_Utilisateur,0) AS VARCHAR(255)),'IQEE_EVENEMENT_DEPLACEMENT') = 1
            BEGIN
                DECLARE curAssociations CURSOR LOCAL FAST_FORWARD 
                    FOR SELECT E.iID_Evenement_Historique,E2.iID_Evenement_Historique
                          FROM #tblIQEE_Evenements E
                               JOIN #tblIQEE_Evenements E2 ON E2.iID_Evenement_Historique = (
                                                                    SELECT TOP 1 E3.iID_Evenement_Historique
                                                                      FROM #tblIQEE_Evenements E3
                                                                     WHERE E3.iID_Convention = E.iID_Convention
                                                                       AND E3.vcCode_Type IN ('TRA_0','TRA_2')
                                                                       AND E3.vcCode_Evenement = E.vcCode_Evenement
                                                                       AND E3.dtDate_Evenement = E.dtDate_Evenement
                                                                       AND E3.dtDate_Chronologique > E.dtDate_Chronologique
                                                                     ORDER BY E3.dtDate_Chronologique)
                         WHERE E.vcCode_Statut_A_Jour IN ('REJ_MAJ_COR','REJ_MAJ_COI')
                           AND @vcCode_Structure_Presentation IN ('SAC','TI1')
                UNION ALL
                    -- Déplacement des transactions d'annulation vers les transactions de reprises
                    SELECT E.iID_Evenement_Historique,E2.iID_Evenement_Historique
                      FROM #tblIQEE_Evenements E
                           JOIN #tblIQEE_Evenements E2 ON E2.iID_Evenement_Historique = (
                                                                SELECT TOP 1 E3.iID_Evenement_Historique
                                                                  FROM #tblIQEE_Evenements E3
                                                                 WHERE E3.iID_Convention = E.iID_Convention
                                                                   AND E3.vcCode_Type LIKE CASE WHEN E.vcCode_Type = 'TRA_1' THEN 'TRA_2%' ELSE 'TRA_0' END
                                                                   AND E3.vcCode_Evenement = E.vcCode_Evenement
                                                                   AND E3.dtDate_Chronologique >= E.dtDate_Chronologique
                                                                 ORDER BY E3.dtDate_Chronologique)
                     WHERE E.vcCode_Type IN ('TRA_1','TRA_2A0')
                       AND E.vcCode_Statut_A_Jour NOT IN ('TRA_MAJ_E')
                       AND @vcCode_Structure_Presentation IN ('SAC','TI1')
                UNION ALL
                    -- Déplacement d'une transaction en erreur vers les erreurs
                    SELECT E.iID_Evenement_Historique,E2.iID_Evenement_Historique
                    FROM #tblIQEE_Evenements E
                         JOIN #tblIQEE_Evenements E2 ON E2.iID_Convention = E.iID_Convention
                                                    AND E2.vcCode_Statut_A_Jour LIKE 'ERR_MAJ_%'
                                                    AND E2.vcCode_Evenement = E.vcCode_Evenement
                                                    AND E2.iID_Secondaire1 = E.iID_Primaire
                    WHERE E.vcCode_Statut_A_Jour = 'TRA_MAJ_E'
                      AND @vcCode_Structure_Presentation = 'TI1'
                UNION ALL
                    -- Déplacement d'une transaction répondu vers les réponses
                    SELECT E.iID_Evenement_Historique,E2.iID_Evenement_Historique
                    FROM #tblIQEE_Evenements E
                         JOIN #tblIQEE_Evenements E2 ON E2.iID_Convention = E.iID_Convention
                                                    AND E2.vcCode_Statut_A_Jour LIKE 'REP_MAJ_%'
                                                    AND E2.vcCode_Evenement = E.vcCode_Evenement
                                                    AND E2.iID_Secondaire1 = E.iID_Primaire
                    WHERE E.vcCode_Statut_A_Jour IN ('TRA_MAJ_R','TRA_MAJ_D','TRA_MAJ_T')
                      AND @vcCode_Structure_Presentation = 'TI1'
                UNION ALL
                    -- Déplacement d'une erreur non terminée vers la transaction en erreur
                    SELECT E.iID_Evenement_Historique,E2.iID_Evenement_Historique
                    FROM #tblIQEE_Evenements E
                         JOIN #tblIQEE_Evenements E2 ON E2.iID_Convention = E.iID_Convention
                                                    AND E2.vcCode_Statut_A_Jour LIKE 'TRA_MAJ_%'
                                                    AND E2.vcCode_Evenement = E.vcCode_Evenement
                                                    AND E2.iID_Primaire = E.iID_Secondaire1
                    WHERE E.vcCode_Statut_A_Jour LIKE 'ERR_MAJ_%'
                      AND E.vcCode_Statut_A_Jour <> 'ERR_MAJ_TER'
                      AND @vcCode_Structure_Presentation = 'TI1'
                UNION ALL
                    -- Déplacement d'une erreur terminée vers la transaction suivante donc théoriquement la transaction corrigée
                    SELECT E.iID_Evenement_Historique,E2.iID_Evenement_Historique
                    FROM #tblIQEE_Evenements E
                         JOIN #tblIQEE_Evenements E2 ON E2.iID_Evenement_Historique =
                                                                 (SELECT TOP 1 E3.iID_Evenement_Historique
                                                                  FROM #tblIQEE_Evenements E3
                                                                  WHERE    E3.iID_Convention = E.iID_Convention
                                                                    AND E3.vcCode_Type IN ('TRA_0','TRA_2')
                                                                    AND E3.vcCode_Evenement = E.vcCode_Evenement
                                                                    AND E3.dtDate_Chronologique > E.dtDate_Chronologique
                                                                  ORDER BY E3.dtDate_Chronologique)
                    WHERE E.vcCode_Statut_A_Jour = 'ERR_MAJ_TER'
                      AND @vcCode_Structure_Presentation = 'TI1'
                UNION ALL
                    -- Déplacement d'une réponse en voie d'être annulée ou annulée vers les annulations/reprises
                    SELECT E.iID_Evenement_Historique,E2.iID_Evenement_Historique
                    FROM #tblIQEE_Evenements E
                         JOIN #tblIQEE_Evenements E2 ON E2.iID_Convention = E.iID_Convention
                                                    AND E2.vcCode_Statut_A_Jour LIKE 'A/R_MAJ_%'
                                                    AND E2.vcCode_Evenement = E.vcCode_Evenement
                                                    AND E2.iID_Secondaire1 = E.iID_Secondaire1
                    WHERE E.vcCode_Statut_A_Jour IN ('REP_MAJ_D','REP_MAJ_T')
                      AND @vcCode_Structure_Presentation = 'TI1'
                UNION ALL
                    -- Déplacement d'une réponse en vigueur vers la transaction suivante peu importe son type
                    SELECT E.iID_Evenement_Historique,E2.iID_Evenement_Historique
                    FROM #tblIQEE_Evenements E
-- TODO: Enlever après les tests
--                         JOIN #tblIQEE_Evenements E4 ON E4.iID_Primaire = E.iID_Secondaire1
--                                                    AND E4.vcCode_Evenement = E.vcCode_Evenement
--                                                    AND E4.vcCode_Type IN ('TRA_0','TRA_2A0','TRA_2')
                         JOIN #tblIQEE_Evenements E2 ON E2.iID_Evenement_Historique =
                                                                 (SELECT TOP 1 E3.iID_Evenement_Historique
                                                                  FROM #tblIQEE_Evenements E3
                                                                  WHERE    E3.iID_Convention = E.iID_Convention
                                                                    AND E3.vcCode_Type IN ('TRA_0','TRA_2')
                                                                    AND E3.dtDate_Evenement > E.dtDate_Evenement
--                                                                    AND E3.dtDate_Chronologique > E4.dtDate_Chronologique
                                                                  ORDER BY E3.dtDate_Chronologique)
                    WHERE E.vcCode_Statut_A_Jour LIKE 'REP_MAJ_R%'
                      AND @vcCode_Structure_Presentation = 'TI1'
                UNION ALL
                    -- Déplacement des transactions en attente d'une réponse vers la transaction suivante peu importe son type
                    SELECT E.iID_Evenement_Historique,E2.iID_Evenement_Historique
                    FROM #tblIQEE_Evenements E
                         JOIN #tblIQEE_Evenements E2 ON E2.iID_Evenement_Historique =
                                                                 (SELECT TOP 1 E3.iID_Evenement_Historique
                                                                  FROM #tblIQEE_Evenements E3
                                                                  WHERE    E3.iID_Convention = E.iID_Convention
                                                                    AND E3.vcCode_Type IN ('TRA_0','TRA_2')
                                                                    AND E3.dtDate_Chronologique >= E.dtDate_Chronologique
                                                                    AND E3.iID_Evenement_Historique <> E.iID_Evenement_Historique
                                                                  ORDER BY E3.dtDate_Chronologique)
                    WHERE E.vcCode_Statut_A_Jour = 'TRA_MAJ_A'
                      AND E.vcCode_Type <> 'TRA_1'
                      AND @vcCode_Structure_Presentation = 'TI1'
                UNION ALL
                    -- Déplacement des annulations/reprises non actualisé par une nouvelle transaction vers la transaction qui doit être annulée
                    SELECT E.iID_Evenement_Historique,E2.iID_Evenement_Historique
                    FROM #tblIQEE_Evenements E
                         JOIN #tblIQEE_Evenements E2 ON E2.iID_Convention = E.iID_Convention
                                                    AND E2.vcCode_Statut_A_Jour LIKE 'TRA_MAJ_%'
                                                    AND E2.vcCode_Evenement = E.vcCode_Evenement
                                                    AND E2.iID_Primaire = E.iID_Secondaire1
                    WHERE E.vcCode_Statut_A_Jour IN ('A/R_MAJ_MAN','A/R_MAJ_DAR','A/R_MAJ_DAN')
                      AND @vcCode_Structure_Presentation = 'TI1'
                UNION ALL
                    -- Déplacement des annulations/reprises actualisé par une nouvelle transaction vers la nouvelle transaction de reprise
                    SELECT E.iID_Evenement_Historique,E2.iID_Evenement_Historique
                    FROM #tblIQEE_Evenements E
                         JOIN tblIQEE_Annulations A ON A.iID_Annulation = E.iID_Primaire
                         JOIN #tblIQEE_Evenements E2 ON E2.iID_Convention = E.iID_Convention
                                                    AND E2.vcCode_Statut_A_Jour LIKE 'TRA_MAJ_%'
                                                    AND E2.tiID_Type_Enregistrement = E.tiID_Type_Enregistrement
                                                    AND E2.iID_Primaire IN (A.iID_Enregistrement_Reprise_Originale,A.iID_Enregistrement_Reprise,A.iID_Enregistrement_Annulation)
                    WHERE E.vcCode_Statut_A_Jour IN ('A/R_MAJ_ACA','A/R_MAJ_ARA','A/R_MAJ_A0A','A/R_MAJ_AOA','A/R_MAJ_ACE','A/R_MAJ_ARE',
                                                     'A/R_MAJ_A0E','A/R_MAJ_AOE','A/R_MAJ_ARI','A/R_MAJ_A0I','A/R_MAJ_AOI','A/R_MAJ_ANC',
                                                     'A/R_MAJ_ARC','A/R_MAJ_A0C','A/R_MAJ_AOC','A/R_MAJ_IND')
                      AND @vcCode_Structure_Presentation = 'TI1'
                ORDER BY E.iID_Evenement_Historique,E2.iID_Evenement_Historique

                -- Formater les identifiants en liste
                SET @iID_Ancien_Evenement_Historique = 0
                OPEN curAssociations
                FETCH NEXT FROM curAssociations INTO @iID_Evenement_Historique,@iID_Evenement_Historique2
                WHILE @@FETCH_STATUS = 0
                    BEGIN
                        IF @iID_Evenement_Historique <> @iID_Ancien_Evenement_Historique
                            BEGIN
                                IF @iID_Ancien_Evenement_Historique <> 0
                                    UPDATE #tblIQEE_Evenements
                                    SET vcIDs_Associations = @vcIDs_Associations
                                    WHERE iID_Evenement_Historique = @iID_Ancien_Evenement_Historique
                                SET @iID_Ancien_Evenement_Historique = @iID_Evenement_Historique
                                SET @vcIDs_Associations = CAST(@iID_Evenement_Historique2 AS VARCHAR)
                            END
                        ELSE
                            SET @vcIDs_Associations = @vcIDs_Associations + ','+CAST(@iID_Evenement_Historique2 AS VARCHAR)
                        FETCH NEXT FROM curAssociations INTO @iID_Evenement_Historique,@iID_Evenement_Historique2
                    END
                CLOSE curAssociations
                DEALLOCATE curAssociations
                IF @iID_Ancien_Evenement_Historique <> 0
                    UPDATE #tblIQEE_Evenements
                    SET vcIDs_Associations = @vcIDs_Associations
                    WHERE iID_Evenement_Historique = @iID_Ancien_Evenement_Historique

                -- Pour tous les autres événements pas déjà associés, prendre l'événement suivant peu importe sont type
                DECLARE curAssociations CURSOR LOCAL FAST_FORWARD FOR
                    SELECT E.iID_Evenement_Historique,ISNULL(E2.iID_Evenement_Historique,E.iID_Evenement_Historique)
                    FROM #tblIQEE_Evenements E
                         JOIN tblIQEE_HistoEvenements HE1 ON HE1.iID_Evenement = E.iID_Evenement
                         LEFT JOIN #tblIQEE_Evenements E2 ON E2.iID_Evenement_Historique =
                                                                 (SELECT TOP 1 E3.iID_Evenement_Historique
                                                                  FROM #tblIQEE_Evenements E3
                                                                       JOIN tblIQEE_HistoEvenements HE2 ON HE2.iID_Evenement = E3.iID_Evenement
                                                                  WHERE    E3.iID_Convention = E.iID_Convention
                                                                    AND (E3.dtDate_Evenement > E.dtDate_Evenement OR
                                                                        (E3.dtDate_Evenement = E.dtDate_Evenement AND HE2.iOrdre_Presentation > HE1.iOrdre_Presentation))
                                                                    AND E3.iID_Evenement_Historique <> E.iID_Evenement_Historique
                                                                  ORDER BY CASE WHEN @vcCode_Structure_Presentation = 'SAC' THEN YEAR(E3.dtDate_Evenement) ELSE 1 END, E3.dtDate_Chronologique,
                                                                            CASE WHEN HE2.vcCode_Regroupement = 'UNI' THEN HE2.iOrdre_Presentation ELSE 999999 END,
                                                                            E3.vcCode_Evenement,ISNULL(E3.dtDate_Sequence,E3.dtDate_Evenement),HE2.iOrdre_Presentation)
                    WHERE E.vcIDs_Associations IS NULL
                      AND @vcCode_Structure_Presentation IN ('SAC','TI1')

                -- Formater les identifiants en liste
                SET @iID_Ancien_Evenement_Historique = 0
                OPEN curAssociations
                FETCH NEXT FROM curAssociations INTO @iID_Evenement_Historique,@iID_Evenement_Historique2
                WHILE @@FETCH_STATUS = 0
                    BEGIN
                        IF @iID_Evenement_Historique <> @iID_Ancien_Evenement_Historique
                            BEGIN
                                IF @iID_Ancien_Evenement_Historique <> 0
                                    UPDATE #tblIQEE_Evenements
                                    SET vcIDs_Associations = @vcIDs_Associations
                                    WHERE iID_Evenement_Historique = @iID_Ancien_Evenement_Historique
                                SET @iID_Ancien_Evenement_Historique = @iID_Evenement_Historique
                                SET @vcIDs_Associations = CAST(@iID_Evenement_Historique2 AS VARCHAR)
                            END
                        ELSE
                            SET @vcIDs_Associations = @vcIDs_Associations + ','+CAST(@iID_Evenement_Historique2 AS VARCHAR)

                        FETCH NEXT FROM curAssociations INTO @iID_Evenement_Historique,@iID_Evenement_Historique2
                    END
                CLOSE curAssociations
                DEALLOCATE curAssociations

                IF @iID_Ancien_Evenement_Historique <> 0
                    UPDATE #tblIQEE_Evenements
                    SET vcIDs_Associations = @vcIDs_Associations
                    WHERE iID_Evenement_Historique = @iID_Ancien_Evenement_Historique
            END

        ---------------------------------------------------------------------------------------------------------------------
        -- Déterminer les informations des réponses aux événements de l'historique selon la structure de présentation choisie
        ---------------------------------------------------------------------------------------------------------------------
        IF @vcCode_Structure_Presentation IN ('SAC','TI1')
            BEGIN
                DECLARE @iID_Demande_IQEE INT,
                        @vcCode_Type_Reponse VARCHAR(3),
                        @cCode_Justification_RQ CHAR(2),
                        @dtSequence_Operation DATETIME,
                        @dtDate_Operation DATETIME,
                        @vcOPER_MONTANTS_IQEE VARCHAR(100),
                        @vcOPER_MONTANTS_CREDITBASE VARCHAR(100),
                        @vcOPER_MONTANTS_MAJORATION VARCHAR(100)

                -- Déterminer s'il y a des réponses dans l'historique
                IF EXISTS(SELECT * 
                          FROM #tblIQEE_Evenements E
                          WHERE E.vcCode_Type LIKE 'REP_%')
                    SET @bReponses = 1
                ELSE
                    SET @bReponses = 0

                DECLARE curReponses CURSOR LOCAL FAST_FORWARD FOR
                    SELECT D.iID_Convention,F2.iID_Fichier_IQEE,RD.iID_Demande_IQEE,TR.vcCode,J.cCode,
                           CASE WHEN ISNULL(TR.bInverser_Signe_Pour_Injection,0) = 0 THEN ISNULL(RD.mMontant,0) ELSE ISNULL(RD.mMontant,0)*-1 END,
                           O.dtSequence_Operation,O.OperDate
                    FROM #tblIQEE_Conventions C
                         JOIN tblIQEE_Demandes D ON D.iID_Convention = C.iID_Convention
                         JOIN tblIQEE_Fichiers F1 ON F1.iID_Fichier_IQEE = D.iID_Fichier_IQEE
                                                 AND F1.bFichier_Test = 0
                                                             AND F1.bFichier_Test = 0 AND F1.bInd_Simulation = 0
                         JOIN tblIQEE_ReponsesDemande RD ON RD.iID_Demande_IQEE = D.iID_Demande_IQEE
                         JOIN tblIQEE_Fichiers F2 ON F2.iID_Fichier_IQEE = RD.iID_Fichier_IQEE
                                                 AND F2.bFichier_Test = 0
                                                             AND F2.bFichier_Test = 0 AND F2.bInd_Simulation = 0
                         JOIN tblIQEE_TypesReponse TR ON TR.tiID_Type_Reponse = RD.tiID_Type_Reponse
                         LEFT JOIN tblIQEE_JustificationsRQ J ON J.tiID_Justification_RQ = RD.tiID_Justification_RQ
                         LEFT JOIN Un_Oper O ON O.OperID = RD.iID_Operation

                OPEN curReponses
                FETCH NEXT FROM curReponses INTO @iID_Convention,@iID_Fichier_IQEE,@iID_Demande_IQEE,@vcCode_Type_Reponse,
                                                 @cCode_Justification_RQ,@mMontant,@dtSequence_Operation,@dtDate_Operation
                WHILE @@FETCH_STATUS = 0
                    BEGIN
                        IF @vcCode_Structure_Presentation = 'TI1'
                            BEGIN
                                IF @dtSequence_Operation IS NOT NULL
                                    BEGIN
                                        IF @bReponses = 0
                                            UPDATE E
                                            SET dtDate_Sequence = @dtSequence_Operation
                                            FROM #tblIQEE_Evenements E
                                            WHERE E.iID_Convention = @iID_Convention
                                              AND E.vcCode_Evenement = 'T02'
                                              AND E.vcCode_Type LIKE 'TRA_%'
                                              AND E.iID_Primaire = @iID_Demande_IQEE
                                              AND E.dtDate_Sequence IS NULL
                                        ELSE
                                            UPDATE E
                                            SET dtDate_Sequence = @dtSequence_Operation
                                            FROM #tblIQEE_Evenements E
                                            WHERE E.iID_Convention = @iID_Convention
                                              AND E.vcCode_Evenement = 'T02'
                                              AND E.vcCode_Type LIKE 'REP_%'
                                              AND E.iID_Secondaire1 = @iID_Demande_IQEE
                                              AND E.iID_Fichier_IQEE = @iID_Fichier_IQEE
                                              AND E.dtDate_Sequence IS NULL
                                    END

                                IF @dtDate_Operation IS NOT NULL
                                    BEGIN
                                        IF @bReponses = 0
                                            UPDATE E
                                            SET dtDate_Sequence = @dtDate_Operation
                                            FROM #tblIQEE_Evenements E
                                            WHERE E.iID_Convention = @iID_Convention
                                              AND E.vcCode_Evenement = 'T02'
                                              AND E.vcCode_Type LIKE 'TRA_%'
                                              AND E.iID_Primaire = @iID_Demande_IQEE
                                              AND E.dtDate_Sequence IS NULL
                                        ELSE
                                            UPDATE E
                                            SET dtDate_Sequence = @dtDate_Operation
                                            FROM #tblIQEE_Evenements E
                                            WHERE E.iID_Convention = @iID_Convention
                                              AND E.vcCode_Evenement = 'T02'
                                              AND E.vcCode_Type LIKE 'REP_%'
                                              AND E.iID_Secondaire1 = @iID_Demande_IQEE
                                              AND E.iID_Fichier_IQEE = @iID_Fichier_IQEE
                                              AND E.dtDate_Sequence IS NULL
                                    END

                                IF @vcCode_Type_Reponse = 'MCI' AND
                                   @mMontant <> 0
                                    BEGIN
                                        IF @bReponses = 0
                                            UPDATE E
                                            SET mCourant_Cotisations_Ayant_Donne_Droit = ISNULL(mCourant_Cotisations_Ayant_Donne_Droit,0) + @mMontant,
                                                mDetermination_Cotisations_Ayant_Donne_Droit = ISNULL(mDetermination_Cotisations_Ayant_Donne_Droit,0) + @mMontant
                                            FROM #tblIQEE_Evenements E
                                            WHERE E.iID_Convention = @iID_Convention
                                              AND E.vcCode_Evenement = 'T02'
                                              AND E.vcCode_Type = 'TRA_0'
                                              AND E.iID_Primaire = @iID_Demande_IQEE
                                        ELSE
                                            UPDATE E
                                            SET mCourant_Cotisations_Ayant_Donne_Droit = ISNULL(mCourant_Cotisations_Ayant_Donne_Droit,0) + @mMontant,
                                                mDetermination_Cotisations_Ayant_Donne_Droit = ISNULL(mDetermination_Cotisations_Ayant_Donne_Droit,0) + @mMontant
                                            FROM #tblIQEE_Evenements E
                                            WHERE E.iID_Convention = @iID_Convention
                                              AND E.vcCode_Evenement = 'T02'
                                              AND E.vcCode_Type = 'REP_PRO'
                                              AND E.iID_Secondaire1 = @iID_Demande_IQEE
                                              AND E.iID_Fichier_IQEE = @iID_Fichier_IQEE
                                    END

                                IF @vcCode_Type_Reponse = 'CIB' AND
                                   @mMontant <> 0
                                    BEGIN
                                        IF @bReponses = 0
                                            UPDATE E
                                            SET mSolde_RQ_Cumul_IQEE_Beneficiaire = ISNULL(mSolde_RQ_Cumul_IQEE_Beneficiaire,0) + @mMontant
                                            FROM #tblIQEE_Evenements E
                                            WHERE E.iID_Convention = @iID_Convention
                                              AND E.vcCode_Evenement = 'T02'
                                              AND E.vcCode_Type = 'TRA_0'
                                              AND E.iID_Primaire = @iID_Demande_IQEE
                                        ELSE
                                            UPDATE E
                                            SET mSolde_RQ_Cumul_IQEE_Beneficiaire = ISNULL(mSolde_RQ_Cumul_IQEE_Beneficiaire,0) + @mMontant
                                            FROM #tblIQEE_Evenements E
                                            WHERE E.iID_Convention = @iID_Convention
                                              AND E.vcCode_Evenement = 'T02'
                                              AND E.vcCode_Type = 'REP_PRO'
                                              AND E.iID_Secondaire1 = @iID_Demande_IQEE
                                              AND E.iID_Fichier_IQEE = @iID_Fichier_IQEE
                                    END

                                IF @vcCode_Type_Reponse = 'SOI' AND
                                   @mMontant <> 0
                                    BEGIN
                                        IF @bReponses = 0
                                            UPDATE E
                                            SET mSolde_RQ_Solde_IQEE = ISNULL(mSolde_RQ_Solde_IQEE,0) + @mMontant
                                            FROM #tblIQEE_Evenements E
                                            WHERE E.iID_Convention = @iID_Convention
                                              AND E.vcCode_Evenement = 'T02'
                                              AND E.vcCode_Type = 'TRA_0'
                                              AND E.iID_Primaire = @iID_Demande_IQEE
                                        ELSE
                                            UPDATE E
                                            SET mSolde_RQ_Solde_IQEE = ISNULL(mSolde_RQ_Solde_IQEE,0) + @mMontant
                                            FROM #tblIQEE_Evenements E
                                            WHERE E.iID_Convention = @iID_Convention
                                              AND E.vcCode_Evenement = 'T02'
                                              AND E.vcCode_Type = 'REP_PRO'
                                              AND E.iID_Secondaire1 = @iID_Demande_IQEE
                                              AND E.iID_Fichier_IQEE = @iID_Fichier_IQEE
                                    END

                                IF @vcCode_Type_Reponse = 'SCD' AND
                                   @mMontant <> 0
                                    BEGIN
                                        IF @bReponses = 0
                                            UPDATE E
                                            SET mSolde_RQ_Cotisations_Ayant_Donne_Droit = ISNULL(mSolde_RQ_Cotisations_Ayant_Donne_Droit,0) + @mMontant
                                            FROM #tblIQEE_Evenements E
                                            WHERE E.iID_Convention = @iID_Convention
                                              AND E.vcCode_Evenement = 'T02'
                                              AND E.vcCode_Type = 'TRA_0'
                                              AND E.iID_Primaire = @iID_Demande_IQEE
                                        ELSE
                                            UPDATE E
                                            SET mSolde_RQ_Cotisations_Ayant_Donne_Droit = ISNULL(mSolde_RQ_Cotisations_Ayant_Donne_Droit,0) + @mMontant
                                            FROM #tblIQEE_Evenements E
                                            WHERE E.iID_Convention = @iID_Convention
                                              AND E.vcCode_Evenement = 'T02'
                                              AND E.vcCode_Type = 'REP_PRO'
                                              AND E.iID_Secondaire1 = @iID_Demande_IQEE
                                              AND E.iID_Fichier_IQEE = @iID_Fichier_IQEE
                                    END

                                IF @vcCode_Type_Reponse = 'NCB' AND
                                   @mMontant <> 0
                                    BEGIN
                                        IF @bReponses = 0
                                            UPDATE E
                                            SET mDetermination_Credit_Base = ISNULL(mDetermination_Credit_Base,0) + @mMontant
                                            FROM #tblIQEE_Evenements E
                                            WHERE E.iID_Convention = @iID_Convention
                                              AND E.vcCode_Evenement = 'T02'
                                              AND E.vcCode_Type IN ('TRA_2A0','TRA_2')
                                              AND E.iID_Primaire = @iID_Demande_IQEE
                                        ELSE
                                            UPDATE E
                                            SET mDetermination_Credit_Base = ISNULL(mDetermination_Credit_Base,0) + @mMontant
                                            FROM #tblIQEE_Evenements E
                                            WHERE E.iID_Convention = @iID_Convention
                                              AND E.vcCode_Evenement = 'T02'
                                              AND E.vcCode_Type = 'REP_NOU'
                                              AND E.iID_Secondaire1 = @iID_Demande_IQEE
                                              AND E.iID_Fichier_IQEE = @iID_Fichier_IQEE
                                    END

                                IF (@vcCode_Type_Reponse = 'NMA' OR @vcCode_Type_Reponse = 'NEM') AND
                                   (@mMontant <> 0 OR
                                    EXISTS(SELECT *
                                           FROM tblIQEE_ReponsesDemande RD
                                                JOIN tblIQEE_TypesReponse TR ON TR.tiID_Type_Reponse = RD.tiID_Type_Reponse
                                                                            AND TR.vcCode = 'NEM'
                                                JOIN tblIQEE_JustificationsRQ J ON J.tiID_Justification_RQ = RD.tiID_Justification_RQ
                                                                               AND J.cCode = '31'
                                           WHERE RD.iID_Demande_IQEE = @iID_Demande_IQEE
                                             AND RD.iID_Fichier_IQEE = @iID_Fichier_IQEE))
                                    BEGIN
                                        IF @bReponses = 0
                                            UPDATE E
                                            SET mDetermination_Majoration = ISNULL(mDetermination_Majoration,0) + @mMontant
                                            FROM #tblIQEE_Evenements E
                                            WHERE E.iID_Convention = @iID_Convention
                                              AND E.vcCode_Evenement = 'T02'
                                              AND E.vcCode_Type IN ('TRA_2A0','TRA_2')
                                              AND E.iID_Primaire = @iID_Demande_IQEE
                                        ELSE
                                            UPDATE E
                                            SET mDetermination_Majoration = ISNULL(mDetermination_Majoration,0) + @mMontant
                                            FROM #tblIQEE_Evenements E
                                            WHERE E.iID_Convention = @iID_Convention
                                              AND E.vcCode_Evenement = 'T02'
                                              AND E.vcCode_Type = 'REP_NOU'
                                              AND E.iID_Secondaire1 = @iID_Demande_IQEE
                                              AND E.iID_Fichier_IQEE = @iID_Fichier_IQEE
                                    END

                                IF @vcCode_Type_Reponse = 'NMC' AND
                                   @mMontant <> 0
                                    BEGIN
                                        IF @bReponses = 0
                                            UPDATE E
                                            SET mDetermination_Cotisations_Ayant_Donne_Droit = ISNULL(mDetermination_Cotisations_Ayant_Donne_Droit,0) + @mMontant
                                            FROM #tblIQEE_Evenements E
                                            WHERE E.iID_Convention = @iID_Convention
                                              AND E.vcCode_Evenement = 'T02'
                                              AND E.vcCode_Type IN ('TRA_2A0','TRA_2')
                                              AND E.iID_Primaire = @iID_Demande_IQEE
                                        ELSE
                                            UPDATE E
                                            SET mDetermination_Cotisations_Ayant_Donne_Droit = ISNULL(mDetermination_Cotisations_Ayant_Donne_Droit,0) + @mMontant
                                            FROM #tblIQEE_Evenements E
                                            WHERE E.iID_Convention = @iID_Convention
                                              AND E.vcCode_Evenement = 'T02'
                                              AND E.vcCode_Type = 'REP_NOU'
                                              AND E.iID_Secondaire1 = @iID_Demande_IQEE
                                              AND E.iID_Fichier_IQEE = @iID_Fichier_IQEE
                                    END

                                IF @vcCode_Type_Reponse = 'NCI' AND
                                   @mMontant <> 0
                                    BEGIN
                                        IF @bReponses = 0
                                            UPDATE E
                                            SET mSolde_RQ_Cumul_IQEE_Beneficiaire = ISNULL(mSolde_RQ_Cumul_IQEE_Beneficiaire,0) + @mMontant
                                            FROM #tblIQEE_Evenements E
                                            WHERE E.iID_Convention = @iID_Convention
                                              AND E.vcCode_Evenement = 'T02'
                                              AND E.vcCode_Type IN ('TRA_2A0','TRA_2')
                                              AND E.iID_Primaire = @iID_Demande_IQEE
                                        ELSE
                                            UPDATE E
                                            SET mSolde_RQ_Cumul_IQEE_Beneficiaire = ISNULL(mSolde_RQ_Cumul_IQEE_Beneficiaire,0) + @mMontant
                                            FROM #tblIQEE_Evenements E
                                            WHERE E.iID_Convention = @iID_Convention
                                              AND E.vcCode_Evenement = 'T02'
                                              AND E.vcCode_Type = 'REP_NOU'
                                              AND E.iID_Secondaire1 = @iID_Demande_IQEE
                                              AND E.iID_Fichier_IQEE = @iID_Fichier_IQEE
                                    END

                                IF @vcCode_Type_Reponse = 'NSI' AND
                                   @mMontant <> 0
                                    BEGIN
                                        IF @bReponses = 0
                                            UPDATE E
                                            SET mSolde_RQ_Solde_IQEE = ISNULL(mSolde_RQ_Solde_IQEE,0) + @mMontant
                                            FROM #tblIQEE_Evenements E
                                            WHERE E.iID_Convention = @iID_Convention
                                              AND E.vcCode_Evenement = 'T02'
                                              AND E.vcCode_Type IN ('TRA_2A0','TRA_2')
                                              AND E.iID_Primaire = @iID_Demande_IQEE
                                        ELSE
                                            UPDATE E
                                            SET mSolde_RQ_Solde_IQEE = ISNULL(mSolde_RQ_Solde_IQEE,0) + @mMontant
                                            FROM #tblIQEE_Evenements E
                                            WHERE E.iID_Convention = @iID_Convention
                                              AND E.vcCode_Evenement = 'T02'
                                              AND E.vcCode_Type = 'REP_NOU'
                                              AND E.iID_Secondaire1 = @iID_Demande_IQEE
                                              AND E.iID_Fichier_IQEE = @iID_Fichier_IQEE
                                    END

                                IF @vcCode_Type_Reponse = 'NSC' AND
                                   @mMontant <> 0
                                    BEGIN
                                        IF @bReponses = 0
                                            UPDATE E
                                            SET mSolde_RQ_Cotisations_Ayant_Donne_Droit = ISNULL(mSolde_RQ_Cotisations_Ayant_Donne_Droit,0) + @mMontant
                                            FROM #tblIQEE_Evenements E
                                            WHERE E.iID_Convention = @iID_Convention
                                              AND E.vcCode_Evenement = 'T02'
                                              AND E.vcCode_Type IN ('TRA_2A0','TRA_2')
                                              AND E.iID_Primaire = @iID_Demande_IQEE
                                        ELSE
                                            UPDATE E
                                            SET mSolde_RQ_Cotisations_Ayant_Donne_Droit = ISNULL(mSolde_RQ_Cotisations_Ayant_Donne_Droit,0) + @mMontant
                                            FROM #tblIQEE_Evenements E
                                            WHERE E.iID_Convention = @iID_Convention
                                              AND E.vcCode_Evenement = 'T02'
                                              AND E.vcCode_Type = 'REP_NOU'
                                              AND E.iID_Secondaire1 = @iID_Demande_IQEE
                                              AND E.iID_Fichier_IQEE = @iID_Fichier_IQEE
                                    END
                            END

                        IF @vcCode_Type_Reponse = 'CDB' AND
                           @mMontant <> 0
                            BEGIN
                                IF @bReponses = 0
                                    UPDATE E
                                    SET mCourant_Credit_Base = ISNULL(mCourant_Credit_Base,0) + @mMontant,
                                        mDetermination_Credit_Base = ISNULL(mDetermination_Credit_Base,0) + @mMontant
                                    FROM #tblIQEE_Evenements E
                                    WHERE E.iID_Convention = @iID_Convention
                                      AND E.vcCode_Evenement = 'T02'
                                      AND E.vcCode_Type = 'TRA_0'
                                      AND E.iID_Primaire = @iID_Demande_IQEE
                                ELSE
                                    UPDATE E
                                    SET mCourant_Credit_Base = ISNULL(mCourant_Credit_Base,0) + @mMontant,
                                        mDetermination_Credit_Base = ISNULL(mDetermination_Credit_Base,0) + @mMontant
                                    FROM #tblIQEE_Evenements E
                                    WHERE E.iID_Convention = @iID_Convention
                                      AND E.vcCode_Evenement = 'T02'
                                      AND E.vcCode_Type = 'REP_PRO'
                                      AND E.iID_Secondaire1 = @iID_Demande_IQEE
                                      AND E.iID_Fichier_IQEE = @iID_Fichier_IQEE
                            END

                        IF (@vcCode_Type_Reponse = 'MAJ' OR @vcCode_Type_Reponse = 'EXM') AND
                           (@mMontant <> 0 OR
                            EXISTS(SELECT *
                                   FROM tblIQEE_ReponsesDemande RD
                                        JOIN tblIQEE_TypesReponse TR ON TR.tiID_Type_Reponse = RD.tiID_Type_Reponse
                                                                    AND TR.vcCode = 'EXM'
                                        JOIN tblIQEE_JustificationsRQ J ON J.tiID_Justification_RQ = RD.tiID_Justification_RQ
                                                                       AND J.cCode = '31'
                                   WHERE RD.iID_Demande_IQEE = @iID_Demande_IQEE
                                     AND RD.iID_Fichier_IQEE = @iID_Fichier_IQEE))
                            BEGIN
                                IF @bReponses = 0
                                    UPDATE E
                                    SET mCourant_Majoration = ISNULL(mCourant_Majoration,0) + @mMontant,
                                        mDetermination_Majoration = ISNULL(mDetermination_Majoration,0) + @mMontant
                                    FROM #tblIQEE_Evenements E
                                    WHERE E.iID_Convention = @iID_Convention
                                      AND E.vcCode_Evenement = 'T02'
                                      AND E.vcCode_Type = 'TRA_0'
                                      AND E.iID_Primaire = @iID_Demande_IQEE
                                ELSE
                                    UPDATE E
                                    SET mCourant_Majoration = ISNULL(mCourant_Majoration,0) + @mMontant,
                                        mDetermination_Majoration = ISNULL(mDetermination_Majoration,0) + @mMontant
                                    FROM #tblIQEE_Evenements E
                                    WHERE E.iID_Convention = @iID_Convention
                                      AND E.vcCode_Evenement = 'T02'
                                      AND E.vcCode_Type = 'REP_PRO'
                                      AND E.iID_Secondaire1 = @iID_Demande_IQEE
                                      AND E.iID_Fichier_IQEE = @iID_Fichier_IQEE
                            END

                        IF @vcCode_Type_Reponse = 'INT' AND
                           @mMontant <> 0
                            BEGIN
                                IF @bReponses = 0
                                    UPDATE E
                                    SET mCourant_Interets = ISNULL(mCourant_Interets,0) + @mMontant,
                                        mDetermination_Interets = ISNULL(mDetermination_Interets,0) + @mMontant
                                    FROM #tblIQEE_Evenements E
                                    WHERE E.iID_Convention = @iID_Convention
                                      AND E.vcCode_Evenement = 'T02'
                                      AND E.vcCode_Type = 'TRA_0'
                                      AND E.iID_Primaire = @iID_Demande_IQEE
                                ELSE
                                    UPDATE E
                                    SET mCourant_Interets = ISNULL(mCourant_Interets,0) + @mMontant,
                                        mDetermination_Interets = ISNULL(mDetermination_Interets,0) + @mMontant
                                    FROM #tblIQEE_Evenements E
                                    WHERE E.iID_Convention = @iID_Convention
                                      AND E.vcCode_Evenement = 'T02'
                                      AND E.vcCode_Type = 'REP_PRO'
                                      AND E.iID_Secondaire1 = @iID_Demande_IQEE
                                      AND E.iID_Fichier_IQEE = @iID_Fichier_IQEE
                            END

                        IF @vcCode_Type_Reponse = 'CBD' AND
                           @mMontant <> 0
                            BEGIN
                                IF @bReponses = 0
                                    UPDATE E
                                    SET mCourant_Credit_Base = ISNULL(mCourant_Credit_Base,0) + @mMontant,
                                        mDifferentiel_Credit_Base = ISNULL(mDifferentiel_Credit_Base,0) + @mMontant
                                    FROM #tblIQEE_Evenements E
                                    WHERE E.iID_Convention = @iID_Convention
                                      AND E.vcCode_Evenement = 'T02'
                                      AND E.vcCode_Type IN ('TRA_2A0','TRA_2')
                                      AND E.iID_Primaire = @iID_Demande_IQEE
                                ELSE
                                    UPDATE E
                                    SET mCourant_Credit_Base = ISNULL(mCourant_Credit_Base,0) + @mMontant,
                                        mDifferentiel_Credit_Base = ISNULL(mDifferentiel_Credit_Base,0) + @mMontant
                                    FROM #tblIQEE_Evenements E
                                    WHERE E.iID_Convention = @iID_Convention
                                      AND E.vcCode_Evenement = 'T02'
                                      AND E.vcCode_Type = 'REP_NOU'
                                      AND E.iID_Secondaire1 = @iID_Demande_IQEE
                                      AND E.iID_Fichier_IQEE = @iID_Fichier_IQEE
                            END

                        IF @vcCode_Type_Reponse = 'MAD' AND
                           @mMontant <> 0
                            BEGIN
                                IF @bReponses = 0
                                    UPDATE E
                                    SET mCourant_Majoration = ISNULL(mCourant_Majoration,0) + @mMontant,
                                        mDifferentiel_Majoration = ISNULL(mDifferentiel_Majoration,0) + @mMontant
                                    FROM #tblIQEE_Evenements E
                                    WHERE E.iID_Convention = @iID_Convention
                                      AND E.vcCode_Evenement = 'T02'
                                      AND E.vcCode_Type IN ('TRA_2A0','TRA_2')
                                      AND E.iID_Primaire = @iID_Demande_IQEE
                                ELSE
                                    UPDATE E
                                    SET mCourant_Majoration = ISNULL(mCourant_Majoration,0) + @mMontant,
                                        mDifferentiel_Majoration = ISNULL(mDifferentiel_Majoration,0) + @mMontant
                                    FROM #tblIQEE_Evenements E
                                    WHERE E.iID_Convention = @iID_Convention
                                      AND E.vcCode_Evenement = 'T02'
                                      AND E.vcCode_Type = 'REP_NOU'
                                      AND E.iID_Secondaire1 = @iID_Demande_IQEE
                                      AND E.iID_Fichier_IQEE = @iID_Fichier_IQEE
                            END

                        IF @vcCode_Type_Reponse = 'IND' AND
                           @mMontant <> 0
                            BEGIN
                                IF @bReponses = 0
                                    UPDATE E
                                    SET mCourant_Interets = ISNULL(mCourant_Interets,0) + @mMontant,
                                        mDifferentiel_Interets = ISNULL(mDifferentiel_Interets,0) + @mMontant
                                    FROM #tblIQEE_Evenements E
                                    WHERE E.iID_Convention = @iID_Convention
                                      AND E.vcCode_Evenement = 'T02'
                                      AND E.vcCode_Type IN ('TRA_2A0','TRA_2')
                                      AND E.iID_Primaire = @iID_Demande_IQEE
                                ELSE
                                    UPDATE E
                                    SET mCourant_Interets = ISNULL(mCourant_Interets,0) + @mMontant,
                                        mDifferentiel_Interets = ISNULL(mDifferentiel_Interets,0) + @mMontant
                                    FROM #tblIQEE_Evenements E
                                    WHERE E.iID_Convention = @iID_Convention
                                      AND E.vcCode_Evenement = 'T02'
                                      AND E.vcCode_Type = 'REP_NOU'
                                      AND E.iID_Secondaire1 = @iID_Demande_IQEE
                                      AND E.iID_Fichier_IQEE = @iID_Fichier_IQEE
                            END

                        FETCH NEXT FROM curReponses INTO @iID_Convention,@iID_Fichier_IQEE,@iID_Demande_IQEE,@vcCode_Type_Reponse,
                                                         @cCode_Justification_RQ,@mMontant,@dtSequence_Operation,@dtDate_Operation
                    END
                CLOSE curReponses
                DEALLOCATE curReponses

                IF @vcCode_Structure_Presentation = 'SAC'
                    BEGIN
                        UPDATE #tblIQEE_Evenements
                        SET mCourant_IQEE_SAC = ISNULL(mCourant_Credit_Base,0) + ISNULL(mCourant_Majoration,0) + ISNULL(mCourant_Interets,0)  
                        WHERE mCourant_Credit_Base IS NOT NULL
                           OR mCourant_Majoration IS NOT NULL
                           OR mCourant_Interets IS NOT NULL
                    END

                IF @vcCode_Structure_Presentation = 'TI1'
                    BEGIN
                        UPDATE #tblIQEE_Evenements
                        SET mCourant_IQEE = ISNULL(mCourant_Credit_Base,0) + ISNULL(mCourant_Majoration,0)
                        WHERE mCourant_Credit_Base IS NOT NULL
                           OR mCourant_Majoration IS NOT NULL

                        UPDATE #tblIQEE_Evenements
                        SET mDetermination_IQEE = ISNULL(mDetermination_Credit_Base,0) + ISNULL(mDetermination_Majoration,0)
                        WHERE mDetermination_Credit_Base IS NOT NULL
                           OR mDetermination_Majoration IS NOT NULL

                        UPDATE #tblIQEE_Evenements
                        SET mSolde_GUI_IQEE = ISNULL(mSolde_GUI_Credit_Base,0) + ISNULL(mSolde_GUI_Majoration,0)
                        WHERE mSolde_GUI_Credit_Base IS NOT NULL
                           OR mSolde_GUI_Majoration IS NOT NULL

                        UPDATE #tblIQEE_Evenements
                        SET mDifferentiel_IQEE = ISNULL(mDifferentiel_Credit_Base,0) + ISNULL(mDifferentiel_Majoration,0)
                        WHERE mDifferentiel_Credit_Base IS NOT NULL
                           OR mDifferentiel_Majoration IS NOT NULL

                        SET @vcOPER_MONTANTS_IQEE = dbo.fnOPER_ObtenirTypesOperationConvCategorie('OPER_MONTANTS_IQEE')
                        SET @vcOPER_MONTANTS_CREDITBASE = dbo.fnOPER_ObtenirTypesOperationConvCategorie('OPER_MONTANTS_CREDITBASE')
                        SET @vcOPER_MONTANTS_MAJORATION = dbo.fnOPER_ObtenirTypesOperationConvCategorie('OPER_MONTANTS_MAJORATION')

                        UPDATE E
                        SET mSolde_GUI_Credit_Base = (SELECT SUM(CO.ConventionOperAmount)
                                                      FROM Un_ConventionOper CO
                                                           JOIN Un_Oper O ON O.OperID = CO.OperID
                                                                         AND ISNULL(O.dtSequence_Operation,O.OperDate) <= ISNULL(E.dtDate_Sequence,E.dtDate_Chronologique)
                                                      WHERE CO.ConventionID = E.iID_Convention
                                                        AND CHARINDEX(CO.ConventionOperTypeID,@vcOPER_MONTANTS_CREDITBASE) > 0)
                        FROM  #tblIQEE_Evenements E
                        WHERE E.mCourant_IQEE IS NOT NULL

                        UPDATE E
                        SET mSolde_GUI_Majoration = (SELECT SUM(CO.ConventionOperAmount)
                                                     FROM Un_ConventionOper CO
                                                          JOIN Un_Oper O ON O.OperID = CO.OperID
                                                                        AND ISNULL(O.dtSequence_Operation,O.OperDate) <= ISNULL(E.dtDate_Sequence,E.dtDate_Chronologique)
                                                     WHERE CO.ConventionID = E.iID_Convention
                                                       AND CHARINDEX(CO.ConventionOperTypeID,@vcOPER_MONTANTS_MAJORATION) > 0)
                        FROM  #tblIQEE_Evenements E
                        WHERE E.mCourant_IQEE IS NOT NULL

                        UPDATE E
                        SET mSolde_GUI_IQEE = (SELECT SUM(CO.ConventionOperAmount)
                                               FROM Un_ConventionOper CO
                                                    JOIN Un_Oper O ON O.OperID = CO.OperID
                                                                  AND ISNULL(O.dtSequence_Operation,O.OperDate) <= ISNULL(E.dtDate_Sequence,E.dtDate_Chronologique)
                                               WHERE CO.ConventionID = E.iID_Convention
                                                 AND CHARINDEX(CO.ConventionOperTypeID,@vcOPER_MONTANTS_IQEE) > 0)
                        FROM  #tblIQEE_Evenements E
                        WHERE E.mCourant_IQEE IS NOT NULL
-- TODO: A faire
--            mSolde_GUI_Cotisations_Ayant_Donne_Droit MONEY,

-- TODO: A Faire avec l'importation des fichiers COT
--            mAvis_Montant_Declare MONEY,
--            mAvis_Montant_Recu MONEY,
--            mAvis_Solde_Avis_Cotisation MONEY
                    END
                    
                --******************************************
                --SELECT 'AVANT' AS TableName, * FROM #tblIQEE_Conventions
                --******************************************
                
                --SELECT ISNULL(E.mCourant_Credit_Base,0) AS CreditBase, ISNULL(E.mCourant_Majoration,0) AS Majoration, E.*
                --                            FROM #tblIQEE_Conventions C 
                --                                JOIN #tblIQEE_Evenements E ON E.iID_Convention = C.iID_Convention
                
                -- Mettre à jour les montants totals par convention
                UPDATE C
                SET mCourant_IQEE = (SELECT SUM(ISNULL(E.mCourant_IQEE,0))
                                     FROM #tblIQEE_Evenements E
                                     WHERE E.iID_Convention = C.iID_Convention),
                    mCourant_IQEE_SAC = (SELECT SUM(ISNULL(E.mCourant_IQEE_SAC,0))
                                         FROM #tblIQEE_Evenements E
                                         WHERE E.iID_Convention = C.iID_Convention),
                    mCourant_Credit_Base = (SELECT SUM(ISNULL(E.mCourant_Credit_Base,0))
                                            FROM #tblIQEE_Evenements E
                                            WHERE E.iID_Convention = C.iID_Convention),
                    mCourant_Majoration = (SELECT SUM(ISNULL(E.mCourant_Majoration,0))
                                           FROM #tblIQEE_Evenements E
                                           WHERE E.iID_Convention = C.iID_Convention),
                    mCourant_Interets = (SELECT SUM(ISNULL(E.mCourant_Interets,0))
                                         FROM #tblIQEE_Evenements E
                                         WHERE E.iID_Convention = C.iID_Convention),
                    mCourant_Cotisations_Ayant_Donne_Droit = (SELECT SUM(ISNULL(E.mCourant_Cotisations_Ayant_Donne_Droit,0))
                                                              FROM #tblIQEE_Evenements E
                                                              WHERE E.iID_Convention = C.iID_Convention)
                FROM #tblIQEE_Conventions C
                
                --******************************************
                --SELECT 'APRÈS' AS TableName, * FROM #tblIQEE_Conventions
                --******************************************

            END

        ----------------------------------------------------------
        -- Déterminer les informations secondaires de l'historique
        ----------------------------------------------------------
        IF @vcCode_Structure_Presentation = 'TI1'
            BEGIN
                -- Déterminer le code de regroupement des événements
                UPDATE #tblIQEE_Evenements
                SET vcCode_Regroupement = HE.vcCode_Regroupement
                FROM #tblIQEE_Evenements E
                     JOIN tblIQEE_HistoEvenements HE ON HE.iID_Evenement = E.iID_Evenement

                -- Utilisateur et date du déclencheur menant aux annulations/reprises
                UPDATE #tblIQEE_Evenements
                SET vcNom_Utilisateur = H.FirstName+' '+H.LastName,
                    dtDate_Declencheur = A.dtDate_Action_Menant_Annulation
                FROM #tblIQEE_Evenements E
                     JOIN tblIQEE_Annulations A ON A.iID_Annulation = E.iID_Primaire
                     JOIN dbo.Mo_Human H ON H.HumanID = A.iID_Utilisateur_Action_Menant_Annulation
                WHERE E.vcCode_Regroupement = 'A/R'

                -- Nom de l'utilisateur qui crée la note
                UPDATE #tblIQEE_Evenements
                SET vcNom_Utilisateur = H.FirstName+' '+H.LastName
                FROM #tblIQEE_Evenements E
                     JOIN tblGENE_Note N ON N.iID_Note = E.iID_Primaire
                     JOIN dbo.Mo_Human H ON H.HumanID = N.iID_HumainCreateur
                WHERE E.vcCode_Evenement = 'NOTE'

                -- Nom de l'utilisateur qui a créer la convention
                UPDATE #tblIQEE_Evenements
                SET vcNom_Utilisateur = H.FirstName+' '+H.LastName
                FROM #tblIQEE_Evenements E
                     JOIN dbo.Un_Convention C ON C.ConventionID = E.iID_Convention
                     JOIN Mo_Connect CO ON CO.ConnectID = C.InsertConnectID
                     JOIN dbo.Mo_Human H ON H.HumanID = CO.UserID
                WHERE E.vcCode_Evenement = 'DEBUT'

                -- Nom du nouveau bénéficiaire et nom de l'utilisateur qui a fait le changement de bénéficiaire
                UPDATE #tblIQEE_Evenements
                SET vcNom_Utilisateur = ISNULL(H.FirstName,'')+' '+ISNULL(H.LastName,''),
                    vcNom_Beneficiaire = ISNULL(HC.FirstName,'')+' '+ISNULL(HC.LastName,'')
                FROM #tblIQEE_Evenements E
                     JOIN tblCONV_ChangementsBeneficiaire CB ON CB.iID_Changement_Beneficiaire = E.iID_Primaire
                     LEFT JOIN dbo.Mo_Human H ON H.HumanID = CB.iID_Utilisateur_Creation
                     LEFT JOIN dbo.Mo_Human HC ON HC.HumanID = CB.iID_Nouveau_Beneficiaire
                WHERE E.vcCode_Evenement LIKE 'BENEF_%'

                -- Informations sur un PAE
                UPDATE #tblIQEE_Evenements
                SET vcNom_Utilisateur = H.FirstName+' '+H.LastName,
                    iNo_PAE = S.ScholarshipNo,
                    vcNom_Destinataire = HD.FirstName+' '+HD.LastName,
                    dtDate_Operation = O.OperDate,
                    dtDate_Sequence = O.dtSequence_Operation
                FROM #tblIQEE_Evenements E
                     JOIN Un_ScholarshipPmt SP ON SP.ScholarshipPmtID = E.iID_Primaire
                     JOIN Un_Scholarship S ON S.ScholarshipID = SP.ScholarshipID
                     JOIN Un_Oper O ON O.OperID = E.iID_Secondaire1
                     JOIN Mo_Connect CO ON CO.ConnectID = O.ConnectID
                     LEFT JOIN CHQ_Check CH ON CH.iCheckID = E.iID_Secondaire2
                     LEFT JOIN dbo.Mo_Human HD ON HD.HumanID = CH.iPayeeID
                     JOIN dbo.Mo_Human H ON H.HumanID = CO.UserID
                WHERE E.vcCode_Evenement = 'PAE'

                -- Date de transmission des transactions
-- TODO: prendre les informations pour les autres types de transaction
                UPDATE #tblIQEE_Evenements
                SET dtDate_Transmission = F.dtDate_Transmis
--                    dtDate_Operation = CASE WHEN TE.cCode_Type_Enregistrement = '02' THEN NULL ELSE NULL END,
--                    dtDate_Effectivite = CASE WHEN TE.cCode_Type_Enregistrement = '02' THEN NULL ELSE NULL END,
--                    dtDate_Sequence = CASE WHEN TE.cCode_Type_Enregistrement = '02' THEN NULL ELSE NULL END
                FROM #tblIQEE_Evenements E
                     JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = E.iID_Fichier_IQEE
                                                 AND F.bFichier_Test = 0 AND F.bInd_Simulation = 0
--                     JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = E.tiID_Type_Enregistrement
--                     LEFT JOIN tblIQEE_SousTypeEnregistrement ST ON ST.iID_Sous_Type = E.iID_Sous_Type
--                     LEFT JOIN tblIQEE_Demandes D ON D.iID_Demande_IQEE = E.iID_Primaire
                WHERE E.vcCode_Regroupement = 'TRA'

                -- Date de correction, utilisateur et date de transmission de la nouvelle transaction pour les erreurs terminées
                UPDATE E
                SET dtDate_Correction = ER.dtDate_Traite,
                    vcNom_Utilisateur = H.FirstName+' '+H.LastName,
                    dtDate_Transmission = F.dtDate_Transmis
                FROM #tblIQEE_Evenements E
                     LEFT JOIN tblIQEE_Erreurs ER ON ER.iID_Erreur = E.iID_Primaire
                     LEFT JOIN dbo.Mo_Human H ON H.HumanID = ER.iID_Utilisateur_Traite
                     LEFT JOIN #tblIQEE_Evenements E2 ON E2.iID_Evenement_Historique =
                                                             (SELECT TOP 1 E3.iID_Evenement_Historique
                                                              FROM #tblIQEE_Evenements E3
                                                              WHERE    E3.iID_Convention = E.iID_Convention
                                                                AND E3.vcCode_Type IN ('TRA_0','TRA_2')
                                                                AND E3.vcCode_Evenement = E.vcCode_Evenement
                                                                AND E3.dtDate_Evenement = E.dtDate_Evenement
                                                                AND E3.dtDate_Chronologique > E.dtDate_Chronologique
                                                              ORDER BY E3.dtDate_Chronologique)
                     LEFT JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = E2.iID_Fichier_IQEE
                                                      AND F.bFichier_Test = 0 AND F.bInd_Simulation = 0
                WHERE E.vcCode_Statut_A_Jour = 'ERR_MAJ_TER'

                -- Date de transmission de la transaction de correction suite à une erreur
                UPDATE E
                SET dtDate_Correction = ISNULL(F.dtDate_Transmis,F.dtDate_Creation)
                FROM #tblIQEE_Evenements E
                     JOIN #tblIQEE_Evenements E2 ON E2.iID_Evenement_Historique =
                                                             (SELECT TOP 1 E3.iID_Evenement_Historique
                                                              FROM #tblIQEE_Evenements E3
                                                              WHERE    E3.iID_Convention = E.iID_Convention
                                                                AND E3.vcCode_Type IN ('TRA_0','TRA_2')
                                                                AND E3.vcCode_Evenement = E.vcCode_Evenement
                                                                AND E3.dtDate_Evenement = E.dtDate_Evenement
                                                                AND E3.dtDate_Chronologique > E.dtDate_Chronologique
                                                              ORDER BY E3.dtDate_Chronologique)
                     JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = E2.iID_Fichier_IQEE
                                                 AND F.bFichier_Test = 0 AND F.bInd_Simulation = 0
                WHERE E.vcCode_Statut_A_Jour = 'TRA_MAJ_E'

                -- Date de transmission de la transaction de reprise suite à une demande d'annulation/reprise
                UPDATE E
                SET dtDate_Transmission = F.dtDate_Transmis
                FROM #tblIQEE_Evenements E
                     JOIN tblIQEE_Annulations A ON A.iID_Annulation = E.iID_Primaire
                     JOIN #tblIQEE_Evenements E2 ON E2.iID_Convention = E.iID_Convention
                                                AND E2.vcCode_Type = 'TRA_1'
                                                AND E2.iID_Primaire = A.iID_Enregistrement_Annulation
                     JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = E2.iID_Fichier_IQEE
                                                 AND F.bFichier_Test = 0 AND F.bInd_Simulation = 0
                WHERE E.vcCode_Regroupement = 'A/R'

                -- Date de correction suite à un rejet
                UPDATE E
                SET dtDate_Correction = ISNULL(F.dtDate_Transmis,F.dtDate_Creation)
                FROM #tblIQEE_Evenements E
                     JOIN #tblIQEE_Evenements E2 ON E2.iID_Convention = E.iID_Convention
                                                AND E2.vcCode_Type IN ('TRA_0','TRA_2')
                                                AND E2.vcCode_Evenement = E.vcCode_Evenement
                                                AND E2.dtDate_Evenement = E.dtDate_Evenement
                                                AND E2.iID_Primaire = E.iID_Secondaire3
                     JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = E2.iID_Fichier_IQEE
                                                 AND F.bFichier_Test = 0 AND F.bInd_Simulation = 0
                WHERE E.vcCode_Statut_A_Jour IN ('REJ_MAJ_COR','REJ_MAJ_COI')

-- TODO: Dates pour les rejets pour les transactions 03 à 06
--        dtDate_Operation        Rejet
--        dtDate_Effectivite        Rejet
--        dtDate_Sequence            Rejet

-- TODO: A faire avec les transferts
--        vcNom_Utilisateur
--        vcNom_Promoteur
--        vcNom_Destinataire
--        dtDate_Operation
--        dtDate_Effectivite
--        dtDate_Sequence

-- TODO: A faire avec les RI
--        vcNom_Utilisateur
--        vcNom_Destinataire
--        dtDate_Operation
--        dtDate_Effectivite
--        dtDate_Sequence
            END

        ----------------------------------------------------------------------------------------------------------
        -- Déterminer les descriptions de l'historique selon la présentation choisie et la langue de l'utilisateur
        ----------------------------------------------------------------------------------------------------------
        IF @vcCode_Structure_Presentation = 'TI1'
            BEGIN
                UPDATE E
                SET vcDescription_Regroupement = COALESCE(dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoPresentations','vcDescription',HP.iID_Presentation,NULL,@cID_Langue),
                                                          HP.vcDescription,
                                                          dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoRegroupementsEvenements','vcDescription',RE.iID_Regroupement_Evenement,NULL,@cID_Langue),
                                                          RE.vcDescription)
                FROM #tblIQEE_Evenements E
                     JOIN tblIQEE_HistoRegroupementsEvenements RE ON RE.vcCode_Regroupement_Evenement = E.vcCode_Regroupement
                     LEFT JOIN tblIQEE_HistoPresentations HP ON HP.iID_Structure_Historique = @iID_Structure_Historique_Presentation
                                                            AND HP.vcCode_Type_Info = 'REG'
                                                            AND HP.vcCode_Info = E.vcCode_Regroupement
            END

        IF @vcCode_Structure_Presentation IN ('SAC','TI1')
            BEGIN
                UPDATE E
                SET vcDescription_Evenement = COALESCE(dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoPresentations','vcDescription',HPE.iID_Presentation,NULL,@cID_Langue),
                                                       HPE.vcDescription,
                                                       dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoEvenements','vcDescription_Evenement',HE.iID_Evenement,NULL,@cID_Langue),
                                                       HE.vcDescription_Evenement),

-- TODO: Enlever après le test
--                    vcDescription_Type = COALESCE([dbo].[fnGENE_ObtenirTraduction]('tblIQEE_HistoPresentations','vcDescription',HPT2.iID_Presentation,NULL,@cID_Langue),
--                                                  HPT2.vcDescription,
--                                                  [dbo].[fnGENE_ObtenirTraduction]('tblIQEE_HistoStatutsEvenement','vcDescription',SC.iID_Statut,NULL,@cID_Langue),
--                                                  SC.vcDescription,
--                                                  [dbo].[fnGENE_ObtenirTraduction]('tblIQEE_HistoPresentations','vcDescription',HPT.iID_Presentation,NULL,@cID_Langue),
--                                                  HPT.vcDescription,
--                                                  [dbo].[fnGENE_ObtenirTraduction]('tblIQEE_HistoEvenements','vcDescription_Type',HE.iID_Evenement,NULL,@cID_Langue),
--                                                  HE.vcDescription_Type)
                    vcDescription_Type = ISNULL(COALESCE(dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoPresentations','vcDescription',HPT.iID_Presentation,NULL,@cID_Langue),
                                                  HPT.vcDescription,
                                                  dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoEvenements','vcDescription_Type',HE.iID_Evenement,NULL,@cID_Langue),
                                                  HE.vcDescription_Type),'') + CASE WHEN E.vcCode_Statut_Secondaire IS NULL THEN '' ELSE ' (' +
                                        ISNULL(COALESCE(dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoPresentations','vcDescription',HPT2.iID_Presentation,NULL,@cID_Langue),
                                                  HPT2.vcDescription,
                                                  dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoStatutsEvenement','vcDescription',SC.iID_Statut,NULL,@cID_Langue),
                                                  SC.vcDescription),'')+')' END
                FROM #tblIQEE_Evenements E
                     JOIN tblIQEE_HistoEvenements HE ON HE.iID_Evenement = E.iID_Evenement
                     LEFT JOIN tblIQEE_HistoPresentations HPE ON HPE.iID_Structure_Historique = @iID_Structure_Historique_Presentation
                                                             AND HPE.vcCode_Type_Info = 'EVE'
                                                             AND HPE.vcCode_Info = E.vcCode_Evenement
                     LEFT JOIN tblIQEE_HistoPresentations HPT ON HPT.iID_Structure_Historique = @iID_Structure_Historique_Presentation
                                                             AND HPT.vcCode_Type_Info = 'TYP'
                                                             AND HPT.vcCode_Info = E.vcCode_Type
                     LEFT JOIN tblIQEE_HistoStatutsEvenement SC ON SC.vcCode_Statut = E.vcCode_Statut_Secondaire
                     LEFT JOIN tblIQEE_HistoPresentations HPT2 ON HPT2.iID_Structure_Historique = @iID_Structure_Historique_Presentation
                                                              AND HPT2.vcCode_Type_Info = 'STA'
                                                              AND HPT2.vcCode_Info = E.vcCode_Statut_Secondaire
                UPDATE E
                SET vcDescription_Statut_Chronologique = COALESCE(dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoPresentations','vcDescription',HPC.iID_Presentation,NULL,@cID_Langue),
                                                                  HPC.vcDescription,
                                                                  dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoStatutsEvenement','vcDescription',SC.iID_Statut,NULL,@cID_Langue),
                                                                  SC.vcDescription),
                    vcDescription_Statut_A_Jour = COALESCE(dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoPresentations','vcDescription',HPA.iID_Presentation,NULL,@cID_Langue),
                                                           HPA.vcDescription,
                                                           dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoStatutsEvenement','vcDescription',SA.iID_Statut,NULL,@cID_Langue),
                                                           SA.vcDescription)
                FROM #tblIQEE_Evenements E
                     JOIN tblIQEE_HistoStatutsEvenement SC ON SC.iID_Statut = E.iID_Statut_Chronologique
                     JOIN tblIQEE_HistoStatutsEvenement SA ON SA.iID_Statut = E.iID_Statut_A_Jour
                     LEFT JOIN tblIQEE_HistoPresentations HPC ON HPC.iID_Structure_Historique = @iID_Structure_Historique_Presentation
                                                             AND HPC.vcCode_Type_Info = 'STA'
                                                             AND HPC.vcCode_Info = E.vcCode_Statut_Chronologique
                     LEFT JOIN tblIQEE_HistoPresentations HPA ON HPA.iID_Structure_Historique = @iID_Structure_Historique_Presentation
                                                             AND HPA.vcCode_Type_Info = 'STA'
                                                             AND HPA.vcCode_Info = E.vcCode_Statut_A_Jour
            END

        IF @vcCode_Structure_Presentation = 'TI1'
            BEGIN
                UPDATE E
                SET E.vcDescription_Evenement = REPLACE(E.vcDescription_Evenement,'%vcNo_Convention%',C.vcNo_Convention)
                FROM #tblIQEE_Evenements E
                     JOIN #tblIQEE_Conventions C ON C.iID_Convention = E.iID_Convention
                WHERE CHARINDEX('%vcNo_Convention%',E.vcDescription_Evenement) > 0

                UPDATE E
                SET E.vcDescription_Evenement = REPLACE(E.vcDescription_Evenement,'%vcNom_Beneficiaire%',ISNULL(E.vcNom_Beneficiaire,'Indéterminé'))
                FROM #tblIQEE_Evenements E
                WHERE CHARINDEX('%vcNom_Beneficiaire%',E.vcDescription_Evenement) > 0

                UPDATE E
                SET E.vcDescription_Evenement = REPLACE(E.vcDescription_Evenement,'%vcNom_Promoteur%',ISNULL(E.vcNom_Promoteur,'Indéterminé'))
                FROM #tblIQEE_Evenements E
                WHERE CHARINDEX('%vcNom_Promoteur%',E.vcDescription_Evenement) > 0

                UPDATE E
                SET E.vcDescription_Evenement = REPLACE(E.vcDescription_Evenement,'%vcNom_Destinataire%',ISNULL(E.vcNom_Destinataire,'Indéterminé'))
                FROM #tblIQEE_Evenements E
                WHERE CHARINDEX('%vcNom_Destinataire%',E.vcDescription_Evenement) > 0

                UPDATE E
                SET E.vcDescription_Type = REPLACE(E.vcDescription_Type,'%iNo_PAE%',CAST(E.iNo_PAE AS VARCHAR))
                FROM #tblIQEE_Evenements E
                WHERE CHARINDEX('%iNo_PAE%',E.vcDescription_Type) > 0

                UPDATE E
                SET E.vcDescription_Type = ISNULL(dbo.fnGENE_ObtenirTraduction('tblIQEE_RaisonsAnnulation','vcDescription',RA.iID_Raison_Annulation,NULL,@cID_Langue),RA.vcDescription)
                FROM #tblIQEE_Evenements E
                     JOIN tblIQEE_Annulations A ON A.iID_Annulation = E.iID_Primaire
                     JOIN tblIQEE_RaisonsAnnulation RA ON RA.iID_Raison_Annulation = A.iID_Raison_Annulation
                WHERE E.vcCode_Type = 'A/R'

                UPDATE E
                SET E.vcDescription_Type = N.vcTitre
                FROM #tblIQEE_Evenements E
                     JOIN tblGENE_Note N ON N.iID_Note = E.iID_Primaire
                WHERE E.vcCode_Type = 'TITRE'

                UPDATE E
                SET E.vcDescription_Type = ISNULL(dbo.fnGENE_ObtenirTraduction('Un_Plan','PlanDesc',P.PlanID,NULL,@cID_Langue),P.PlanDesc)
                FROM #tblIQEE_Evenements E
                     JOIN dbo.Un_Convention C ON C.ConventionID = E.iID_Convention
                     JOIN Un_Plan P ON P.PlanID = C.PlanID
                WHERE E.vcCode_Type = 'REGIME'

                UPDATE E
                SET E.vcDescription_Type = ISNULL(dbo.fnGENE_ObtenirTraduction('tblCONV_RaisonsChangementBeneficiaire','vcDescription',RA.tiID_Raison_Changement_Beneficiaire,NULL,@cID_Langue),RA.vcDescription)
                FROM #tblIQEE_Evenements E
                     JOIN tblCONV_ChangementsBeneficiaire CB ON CB.iID_Changement_Beneficiaire = E.iID_Primaire
                     JOIN tblCONV_RaisonsChangementBeneficiaire RA ON RA.tiID_Raison_Changement_Beneficiaire = CB.tiID_Raison_Changement_Beneficiaire
                WHERE E.vcCode_Type = 'RAISON'

                UPDATE E
                SET E.vcDescription_Type = ISNULL(dbo.fnGENE_ObtenirTraduction('Un_ConventionState','ConventionStateName',NULL,CS.ConventionStateID,@cID_Langue),CS.ConventionStateName)
                FROM #tblIQEE_Evenements E
                     JOIN Un_ConventionConventionState CCS ON CCS.ConventionConventionStateID = E.iID_Primaire
                     JOIN Un_ConventionState CS ON CS.ConventionStateID = CCS.ConventionStateID
                WHERE E.vcCode_Type = 'ETAT'

                UPDATE E
                SET E.vcDescription_Statut_A_Jour = REPLACE(E.vcDescription_Statut_A_Jour,'%dtDate_Correction%',ISNULL(CONVERT(VARCHAR(11),E.dtDate_Correction,121),'Indéterminé'))
                FROM #tblIQEE_Evenements E
                WHERE CHARINDEX('%dtDate_Correction%',E.vcDescription_Statut_A_Jour) > 0

                UPDATE E
                SET E.vcDescription_Statut_Chronologique = REPLACE(E.vcDescription_Statut_Chronologique,'%dtDate_Transmission%',ISNULL(CONVERT(VARCHAR(11),E.dtDate_Transmission,121),'Indéterminé'))
                FROM #tblIQEE_Evenements E
                WHERE CHARINDEX('%dtDate_Transmission%',E.vcDescription_Statut_Chronologique) > 0
            END

        -----------------------------------------------------------------------------------------------------------------
        --
        -- Déterminer les détails des événements de l'historique selon la sélection choisie et la langue de l'utilisateur
        --
        -----------------------------------------------------------------------------------------------------------------
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

        CREATE TABLE #tblIQEE_DetailsEvenement(
            iID_Detail_Evenement INT IDENTITY(1,1) NOT NULL, 
            iID_Evenement_Historique INT NOT NULL,
            vcNom_Table VARCHAR(150),
            vcNom_Champ VARCHAR(150),
            vcType VARCHAR(150),
            vcDescription VARCHAR(MAX),
            iID_Enregistrement INT,
            vcID_Enregistrement VARCHAR(15),
            vcDescription_Detail VARCHAR(MAX),
            vcValeur VARCHAR(MAX),
            dtDate DATETIME,
            vcReponse VARCHAR(MAX),
            mCredit_Base MONEY,
            mMajoration MONEY,
            mInterets MONEY,
            mIQEE_SAC MONEY)
        
        -- Rechercher les événements qui ont des éléments de détail
        DECLARE curIQEE_Evenements CURSOR LOCAL FAST_FORWARD FOR
            SELECT E.iID_Evenement_Historique,E.iID_Convention,E.vcCode_Evenement,E.vcCode_Type,E.vcCode_Statut_A_Jour,E.iID_Primaire
            FROM #tblIQEE_Evenements E

        SET @iID_Fichier_IQEE = 0

        -- Boucler les événements
        OPEN curIQEE_Evenements
        FETCH NEXT FROM curIQEE_Evenements INTO @iID_Evenement_Historique,@iID_Convention,@vcCode_Evenement,@vcCode_Type,@vcCode_Statut_A_Jour,@iID_Primaire
        WHILE @@FETCH_STATUS = 0
            BEGIN
            
                -------------------------------------------------
                -- TODO: À SUPPRIMER
                -------------------------------------------------
                --PRINT '@vcCode_Evenement = ' + @vcCode_Evenement
                --PRINT '@vcCode_Type = ' + @vcCode_Type
                --PRINT '*******************************'
                --PRINT ''
                
                -- Obtenir les détails de l'événement
                EXECUTE dbo.psIQEE_ObtenirDetailsEvenement @iID_Utilisateur, @cID_Langue, 1, @iID_Structure_Historique_Selection, NULL,
                                                               @iID_Convention, @vcCode_Evenement, @vcCode_Type, @vcCode_Statut_A_Jour, @iID_Primaire,
                                                               NULL, NULL, NULL, NULL, NULL, @vcCode_Message OUTPUT
                IF @vcCode_Message IS NOT NULL
                    RETURN 0
                    
                --PRINT '@vcCode_Evenement = ' + @vcCode_Evenement
                --PRINT '@vcCode_Type = ' + @vcCode_Type
                --PRINT '*******************************'
                --PRINT ''
                
                --SELECT V.vcNom_Table,V.vcNom_Champ,V.vcType,V.vcDescription,V.iID_Enregistrement,V.vcID_Enregistrement,V.vcValeur
                --    FROM #tblGENE_Valeurs V

                -- Rechercher les détails des événements
                DECLARE curIQEE_Valeurs CURSOR LOCAL FAST_FORWARD FOR
                    SELECT V.vcNom_Table,V.vcNom_Champ,V.vcType,V.vcDescription,V.iID_Enregistrement,V.vcID_Enregistrement,V.vcValeur
                    FROM #tblGENE_Valeurs V

                --SET @iID_Fichier_IQEE = 0
                SET @bDebut_Erreur = 0
                SET @bParametre = 0

                -- Boucler les événements
                OPEN curIQEE_Valeurs
                FETCH NEXT FROM curIQEE_Valeurs INTO @vcNom_Table,@vcNom_Champ,@vcType,@vcDescription,@iID_Enregistrement,@vcID_Enregistrement,@vcValeur
                WHILE @@FETCH_STATUS = 0
                    BEGIN
                
                        --*******************************TODO: À SUPPRIMER**************************
                        --PRINT '@vcCode_Evenement = ' + @vcCode_Evenement
                        --PRINT '@vcCode_Type = ' + @vcCode_Type
                        --PRINT '@vcNom_Table = ' + @vcNom_Table
                        --PRINT '@vcNom_Champ = ' + @vcNom_Champ
                        --PRINT '@vcValeur = ' + @vcValeur
                        --PRINT '*******************************'
                        --PRINT ''
                        --**************************************************************************
                        
                        -- Compiler les informations sur les transactions de demande (type 02)
                        IF @vcCode_Evenement = 'T02' AND @vcCode_Type LIKE 'TRA%'
                            BEGIN
                                IF @vcCode_Type <> 'TRA_1' AND @vcNom_Table = 'tblIQEE_Demandes' AND @vcNom_Champ <> 'iID_Demande_IQEE'
                                    INSERT INTO #tblIQEE_DetailsEvenement
                                            (iID_Evenement_Historique,vcNom_Table,vcNom_Champ,vcType,vcDescription,iID_Enregistrement,vcID_Enregistrement,vcValeur)
                                    VALUES (@iID_Evenement_Historique,@vcNom_Table,@vcNom_Champ,@vcType,@vcDescription,@iID_Enregistrement,@vcID_Enregistrement,@vcValeur)

                                IF @vcCode_Type = 'TRA_1' AND @vcNom_Table = 'tblIQEE_RaisonsAnnulation' AND @vcNom_Champ = 'vcDescription'
                                    INSERT INTO #tblIQEE_DetailsEvenement
                                            (iID_Evenement_Historique,vcNom_Table,vcNom_Champ,vcType,vcDescription,iID_Enregistrement,vcID_Enregistrement,vcValeur)
                                    VALUES (@iID_Evenement_Historique,@vcNom_Table,@vcNom_Champ,@vcType,@vcDescription,@iID_Enregistrement,@vcID_Enregistrement,@vcValeur)

                                -- Informations sur les demandes en erreur
                                IF @vcCode_Statut_A_Jour = 'TRA_MAJ_E'
                                    BEGIN
                                        IF @vcNom_Table = 'tblIQEE_Erreurs' AND @vcNom_Champ = 'iID_Erreur'
                                            SET @bDebut_Erreur = 1
            
                                        IF @vcNom_Table = 'tblIQEE_Fichiers' AND @vcNom_Champ = 'dtDate_Creation' AND @bDebut_Erreur = 1
                                            BEGIN
                                                INSERT INTO #tblIQEE_DetailsEvenement
                                                        (iID_Evenement_Historique,dtDate)
                                                VALUES (@iID_Evenement_Historique,CAST(@vcValeur AS DATETIME))
                                                SET @iID_Detail_Evenement = SCOPE_IDENTITY()
                                            END

                                        IF @vcNom_Table = 'tblIQEE_TypesErreurRQ' AND @vcNom_Champ = 'siCode_Erreur'
                                            UPDATE #tblIQEE_DetailsEvenement
                                            SET vcReponse = @vcValeur, vcDescription_Detail = 'MRQ'
                                            WHERE iID_Detail_Evenement = @iID_Detail_Evenement

                                        IF @vcNom_Table = 'tblIQEE_TypesErreurRQ' AND @vcNom_Champ = 'vcDescription'
                                            UPDATE #tblIQEE_DetailsEvenement
                                            SET vcReponse = vcReponse + ' - ' + @vcValeur
                                            WHERE iID_Detail_Evenement = @iID_Detail_Evenement
                                    END

                                -- Informations sur les demandes qui ont une réponse de RQ
                                IF @vcCode_Statut_A_Jour IN ('TRA_MAJ_R','TRA_MAJ_D','TRA_MAJ_T')
                                    BEGIN
                                        IF @vcNom_Table = 'tblIQEE_ReponsesDemande' AND @vcNom_Champ = 'iID_Fichier_IQEE'
                                            SET @iID_Fichier_IQEE_TMP = CAST(@vcValeur AS INT)

                                        IF @vcNom_Table = 'tblIQEE_ReponsesDemande' AND @vcNom_Champ = 'mMontant'
                                            BEGIN
                                                SET @mMontant = CAST(@vcValeur AS MONEY)
                                                IF @iID_Fichier_IQEE_TMP <> @iID_Fichier_IQEE
                                                    BEGIN
                                                        SET @iID_Fichier_IQEE = @iID_Fichier_IQEE_TMP
                                                        INSERT INTO #tblIQEE_DetailsEvenement
                                                                (iID_Evenement_Historique,vcDescription_Detail)
                                                        VALUES (@iID_Evenement_Historique,'MRQ')
                                                        SET @iID_Detail_Evenement = SCOPE_IDENTITY()
                                                    END
                                            END

                                        IF @vcNom_Table = 'tblIQEE_Fichiers' AND @vcNom_Champ = 'dtDate_Paiement'
                                            UPDATE #tblIQEE_DetailsEvenement
                                            SET dtDate = CAST(@vcValeur AS DATETIME)
                                            WHERE iID_Detail_Evenement = @iID_Detail_Evenement

                                        IF @vcNom_Table = 'tblIQEE_TypesReponse' AND @vcNom_Champ = 'vcCode' AND @mMontant IS NOT NULL
                                            BEGIN
                                                SET @vcCode = @vcValeur

                                                IF @mMontant = 0 AND
                                                   (@vcCode NOT IN ('MAJ','MAD') OR
                                                    NOT EXISTS(SELECT *
                                                               FROM tblIQEE_ReponsesDemande RD
                                                                    JOIN tblIQEE_TypesReponse TR ON TR.tiID_Type_Reponse = RD.tiID_Type_Reponse
                                                                                                AND TR.vcCode = 'EXM'
                                                                    JOIN tblIQEE_JustificationsRQ J ON J.tiID_Justification_RQ = RD.tiID_Justification_RQ
                                                                                                   AND J.cCode = '31'
                                                               WHERE RD.iID_Demande_IQEE = @iID_Primaire
                                                                 AND RD.iID_Fichier_IQEE = @iID_Fichier_IQEE_TMP))
                                                    SET @mMontant = NULL

                                                IF @mMontant IS NOT NULL
                                                    BEGIN
                                                        IF (SELECT TR.bInverser_Signe_Pour_Injection
                                                            FROM tblIQEE_TypesReponse TR
                                                            WHERE TR.vcCode = @vcCode) = 1
                                                            SET @mMontant = @mMontant*-1

                                                        IF @vcCode IN ('CDB','CBD')
                                                            UPDATE #tblIQEE_DetailsEvenement
                                                            SET mCredit_Base = ISNULL(mCredit_Base,0) + @mMontant
                                                            WHERE iID_Detail_Evenement = @iID_Detail_Evenement
                                                        IF @vcCode IN ('MAJ','MAD')
                                                            UPDATE #tblIQEE_DetailsEvenement
                                                            SET mMajoration = ISNULL(mMajoration,0) + @mMontant
                                                            WHERE iID_Detail_Evenement = @iID_Detail_Evenement
                                                        IF @vcCode IN ('INT','IND')
                                                            UPDATE #tblIQEE_DetailsEvenement
                                                            SET mInterets = ISNULL(mInterets,0) + @mMontant
                                                            WHERE iID_Detail_Evenement = @iID_Detail_Evenement
                                                    END
                                            END

                                        IF @vcNom_Table = 'tblIQEE_JustificationsRQ' AND @vcNom_Champ = 'cCode'
                                            BEGIN
                                                UPDATE #tblIQEE_DetailsEvenement
                                                SET vcReponse = CASE WHEN vcReponse IS NULL THEN @vcValeur ELSE vcReponse + ', ' + @vcValeur END
                                                WHERE iID_Detail_Evenement = @iID_Detail_Evenement

                                                IF @vcValeur = '31'
                                                    UPDATE #tblIQEE_DetailsEvenement
                                                    SET mMajoration = ISNULL(mMajoration,0) + 0
                                                    WHERE iID_Detail_Evenement = @iID_Detail_Evenement
                                            END

                                        IF @vcNom_Table = 'tblIQEE_JustificationsRQ' AND @vcNom_Champ = 'vcDescription'
                                            UPDATE #tblIQEE_DetailsEvenement
                                            SET vcReponse = vcReponse + ' - ' + @vcValeur
                                            WHERE iID_Detail_Evenement = @iID_Detail_Evenement
                                    END
                            END
                        
                        -------------------------------
                        -- Transferts T04    
                        -------------------------------                
                    IF @vcCode_Evenement = 'T0403'
                    BEGIN
                        IF @vcCode_Evenement = 'T0403' AND @vcCode_Type LIKE 'TRA%'
                            BEGIN
                                IF @vcCode_Type = 'TRA_0' AND @vcNom_Table = 'tblIQEE_Transferts'
                                    BEGIN
                                    
                                        --*******************************TODO: À SUPPRIMER**************************
                                        --PRINT '@vcCode_Evenement = ' + @vcCode_Evenement
                                        --PRINT '@vcCode_Type = ' + @vcCode_Type
                                        --PRINT '@vcNom_Table = ' + @vcNom_Table
                                        --PRINT '@vcNom_Champ = ' + @vcNom_Champ
                                        --PRINT '@vcValeur = ' + @vcValeur
                                        --**************************************************************************
                                        SET @vcConventionNo_Destination = NULL
                                        SET @vcConventionNo_Source = NULL
                                        SET @iID_Convention_Source = 0
                                        SET @iID_Convention_Destination = 0
                                        
                                        IF @vcNom_Champ = 'iID_Operation_RIO'
                                            BEGIN
                                                SELECT @iID_Convention_Source = U_Src.ConventionID, 
                                                        @vcConventionNo_Source = (SELECT ConventionNo FROM dbo.Un_Convention WHERE ConventionID = U_Src.ConventionID),
                                                        @iID_Convention_Destination = U_Dest.ConventionID,
                                                        @vcConventionNo_Destination = (SELECT ConventionNo FROM dbo.Un_Convention WHERE ConventionID = U_Dest.ConventionID)
                                                FROM tblOPER_OperationsRIO RIO
                                                     JOIN dbo.Un_Unit U_Src ON U_Src.UnitID = RIO.iID_Unite_Source
                                                     JOIN dbo.Un_Unit U_Dest ON U_Dest.UnitID = RIO.iID_Unite_Destination
                                                      --LEFT JOIN dbo.Un_Unit U_OUT ON U_OUT.UnitID = RIO.iID_Unite_Source
                                                      --LEFT JOIN Un_Convention C_OUT ON C_OUT.ConventionID = U_OUT.ConventionID
                                                      --LEFT JOIN dbo.Un_Unit U_IN ON U_IN.UnitID = RIO.iID_Unite_Destination
                                                      --LEFT JOIN Un_Convention C_IN ON C_IN.ConventionID = U_IN.ConventionID
                                                WHERE RIO.iID_Operation_RIO = @vcValeur 
                                                  AND (U_Src.ConventionID = @iID_Convention 
                                                        OR U_Dest.ConventionID = @iID_Convention)
                                                
                                            END
                                            
                                        IF @vcNom_Champ = 'iID_TIO'
                                            BEGIN
                                                SELECT @iID_Convention_Source = CO_OUT.ConventionID, 
                                                        @vcConventionNo_Source = (SELECT ConventionNo FROM dbo.Un_Convention WHERE ConventionID = CO_OUT.ConventionID),
                                                        @iID_Convention_Destination = CO_IN.ConventionID,
                                                        @vcConventionNo_Destination = (SELECT ConventionNo FROM dbo.Un_Convention WHERE ConventionID = CO_IN.ConventionID)
                                                FROM Un_TIO TIO
                                                      JOIN Un_ConventionOper CO_OUT ON CO_OUT.OperID = TIO.iOUTOperID
                                                      JOIN Un_ConventionOper CO_IN ON CO_IN.OperID = TIO.iTINOperID
                                                WHERE TIO.iTIOID = @vcValeur 
                                                  AND (CO_OUT.ConventionID = @iID_Convention 
                                                       OR CO_IN.ConventionID = @iID_Convention)
                                            END
                                            
                                        IF @vcNom_Champ IN ('iID_Operation_RIO', 'iID_TIO') AND @vcValeur IS NOT NULL
                                            BEGIN
                                                IF ISNULL(@iID_Convention_Source, 0) <> 0 AND @iID_Convention_Source = @iID_Convention
                                                    BEGIN
                                                        SET @vcDescription_Detail_Transfert = 'Transféré vers nouvelle convention'
                                                        SET @vcConventionNo_Detail_Transfert = @vcConventionNo_Destination
                                                        
                                                        UPDATE #tblIQEE_Evenements
                                                        SET vcDescription_Evenement = 'Transfert >> ' + @vcConventionNo_Destination
                                                        WHERE iID_Evenement_Historique = @iID_Evenement_Historique
                                                    END
                                                    
                                                ELSE IF ISNULL(@iID_Convention_Destination, 0) <> 0 AND @iID_Convention_Destination = @iID_Convention
                                                    BEGIN
                                                        SET @vcDescription_Detail_Transfert = 'Transféré d''une autre convention'
                                                        SET @vcConventionNo_Detail_Transfert = @vcConventionNo_Source
                                                        
                                                        UPDATE #tblIQEE_Evenements
                                                        SET vcDescription_Evenement = 'Transfert << ' + @vcConventionNo_Source
                                                        WHERE iID_Evenement_Historique = @iID_Evenement_Historique
                                                    END
                                                    
                                                ELSE
                                                    BEGIN
                                                        SET @vcDescription_Detail_Transfert = 'Impossible de définir la source et la destination'
                                                        SET @vcConventionNo_Detail_Transfert = ''
                                                    END
                                                
                                                --PRINT '@vcDescription_Detail_Transfert = ' + ISNULL(@vcDescription_Detail_Transfert, 'NULL')
                                                --PRINT '@vcConventionNo_Detail_Transfert = ' + ISNULL(@vcConventionNo_Detail_Transfert, 0)
                                                
                                                INSERT INTO #tblIQEE_DetailsEvenement
                                                        (iID_Evenement_Historique,vcDescription_Detail, vcValeur)
                                                VALUES (@iID_Evenement_Historique,@vcDescription_Detail_Transfert,@vcConventionNo_Detail_Transfert)
                                                SET @iID_Detail_Evenement = SCOPE_IDENTITY()
                                            END
                                            
                                        IF @vcNom_Champ = 'mCotisations_Donne_Droit_IQEE'
                                            BEGIN
                                                INSERT INTO #tblIQEE_DetailsEvenement
                                                        (iID_Evenement_Historique,vcDescription_Detail, vcValeur)
                                                VALUES (@iID_Evenement_Historique,'Montant cotisations ayant donné droit',
                                                        @vcValeur)
                                                SET @iID_Detail_Evenement = SCOPE_IDENTITY()
                                            END
                                            
                                        IF @vcNom_Champ = 'mCotisations_Non_Donne_Droit_IQEE'
                                            BEGIN
                                                INSERT INTO #tblIQEE_DetailsEvenement
                                                        (iID_Evenement_Historique,vcDescription_Detail, vcValeur)
                                                VALUES (@iID_Evenement_Historique,'Montant cotisations n''ayant pas donné droit',
                                                        @vcValeur)
                                                SET @iID_Detail_Evenement = SCOPE_IDENTITY()
                                            END
                                            
                                        IF @vcNom_Champ = 'mTotal_Transfert'
                                            BEGIN
                                                INSERT INTO #tblIQEE_DetailsEvenement
                                                        (iID_Evenement_Historique,vcDescription_Detail, vcValeur)
                                                VALUES (@iID_Evenement_Historique,'Montant total transfert',
                                                        @vcValeur)
                                                SET @iID_Detail_Evenement = SCOPE_IDENTITY()
                                            END
                                            
                                        --IF @vcNom_Champ = 'mIQEE_Reel_Transfere'
                                        --    BEGIN
                                        --        INSERT INTO #tblIQEE_DetailsEvenement
                                        --                (iID_Evenement_Historique,vcDescription_Detail, vcValeur)
                                        --        VALUES (@iID_Evenement_Historique,'Montant IQEE faisant parti du transfert',
                                        --                @vcValeur)
                                        --        SET @iID_Detail_Evenement = SCOPE_IDENTITY()
                                        --    END
                                            
                                        IF @vcNom_Champ = 'mIQEE_CreditBase_Transfere'
                                            BEGIN
                                                IF ISNULL(@iID_Convention_Destination, 0) <> 0 AND @iID_Convention_Destination = @iID_Convention
                                                    BEGIN
                                                        SET @iMultiplicateur_Montants_Transfert = 1
                                                    END
                                                ELSE
                                                    BEGIN
                                                        SET @iMultiplicateur_Montants_Transfert = -1
                                                    END
                                                UPDATE #tblIQEE_DetailsEvenement
                                                SET mCredit_Base = ISNULL(mCredit_Base,0) + CAST(@vcValeur AS MONEY)* @iMultiplicateur_Montants_Transfert
                                                WHERE iID_Detail_Evenement = @iID_Detail_Evenement
                                            END
                                            
                                        IF @vcNom_Champ = 'mIQEE_Majore_Transfere'
                                            BEGIN
                                                IF ISNULL(@iID_Convention_Destination, 0) <> 0 AND @iID_Convention_Destination = @iID_Convention
                                                    BEGIN
                                                        SET @iMultiplicateur_Montants_Transfert = 1
                                                    END
                                                ELSE
                                                    BEGIN
                                                        SET @iMultiplicateur_Montants_Transfert = -1
                                                    END
                                                
                                                UPDATE #tblIQEE_DetailsEvenement
                                                SET mMajoration = ISNULL(mMajoration,0) + CAST(@vcValeur AS MONEY)* @iMultiplicateur_Montants_Transfert
                                                WHERE iID_Detail_Evenement = @iID_Detail_Evenement
                                                
                                            END
                                            
                                        --IF @vcNom_Champ = 'mBEC'
                                        --    BEGIN
                                        --        INSERT INTO #tblIQEE_DetailsEvenement
                                        --                (iID_Evenement_Historique,vcDescription_Detail, vcValeur)
                                        --        VALUES (@iID_Evenement_Historique,'Montant BEC',
                                        --                @vcValeur)
                                        --        SET @iID_Detail_Evenement = SCOPE_IDENTITY()
                                        --    END
                                            
                                        --IF @vcNom_Champ = 'mJuste_Valeur_Marchande'
                                        --    BEGIN
                                        --        INSERT INTO #tblIQEE_DetailsEvenement
                                        --                (iID_Evenement_Historique,vcDescription_Detail, vcValeur)
                                        --        VALUES (@iID_Evenement_Historique,'Juste Valeur Marchande',
                                        --                @vcValeur)
                                        --        SET @iID_Detail_Evenement = SCOPE_IDENTITY()
                                        --    END
                                            
                                    END

                                IF @vcCode_Type = 'TRA_0' AND @vcNom_Table = 'tblIQEE_ReponsesTransfert'
                                    BEGIN
                                        IF @vcNom_Champ = 'iID_Fichier_IQEE'
                                            SET @iID_Fichier_IQEE_TMP = CAST(@vcValeur AS INT)

                                        IF @iID_Fichier_IQEE_TMP <> @iID_Fichier_IQEE
                                            BEGIN
                                                --PRINT '***** (' + cast(@iID_Detail_Evenement as varchar) + ') MRQ : ' + Cast(@iID_Fichier_IQEE_TMP as varchar) + ' / ' + Cast(@iID_Fichier_IQEE as varchar)
                                                SET @iID_Fichier_IQEE = @iID_Fichier_IQEE_TMP
                                                INSERT INTO #tblIQEE_DetailsEvenement
                                                        (iID_Evenement_Historique,vcDescription_Detail, vcReponse)
                                                VALUES (@iID_Evenement_Historique,'MRQ', 'Réponse simulée car RQ ne réponds pas aux transferts')
                                                SET @iID_Detail_Evenement = SCOPE_IDENTITY()
                                            END
                                        --IF @vcNom_Champ = 'mMontantIQEE_Base'
                                        --    BEGIN
                                        --        SET @iID_Fichier_IQEE = @iID_Fichier_IQEE_TMP
                                        --        UPDATE #tblIQEE_Evenements
                                        --        SET mCourant_Credit_Base = (ISNULL(mCourant_Credit_Base,0) + CAST(@vcValeur AS MONEY))*-1
                                        --        WHERE iID_Evenement_Historique = @iID_Evenement_Historique
                                        --    END
                                        --ELSE IF @vcNom_Champ = 'mMontantIQEE_Majore'
                                        --    BEGIN
                                        --        SET @iID_Fichier_IQEE = @iID_Fichier_IQEE_TMP
                                        --        UPDATE #tblIQEE_Evenements
                                        --        SET mCourant_Majoration = (ISNULL(mCourant_Majoration,0) + CAST(@vcValeur AS MONEY))*-1
                                        --        WHERE iID_Evenement_Historique = @iID_Evenement_Historique
                                        --    END
                                        --ELSE IF @vcNom_Champ = 'mMontantIQEE'
                                        --    BEGIN
                                        --        SET @iID_Fichier_IQEE = @iID_Fichier_IQEE_TMP
                                        --        UPDATE #tblIQEE_Evenements
                                        --        SET mCourant_IQEE_SAC = (ISNULL(mCourant_IQEE_SAC,0) + CAST(@vcValeur AS MONEY))*-1
                                        --        WHERE iID_Evenement_Historique = @iID_Evenement_Historique
                                        --    END
                                    END
                            END
                    END 

                        --2015-12-17
                        IF @vcCode_Evenement LIKE 'T06%' AND @vcCode_Type LIKE 'TRA%'
                            BEGIN
                                IF @vcCode_Type <> 'TRA_1' AND @vcNom_Table = 'tblIQEE_ImpotsSpeciaux'
                                    BEGIN
                                        IF @vcNom_Champ IN ('dtDate_Evenement', 'mSolde_IQEE_Base', 'mSolde_IQEE_Majore', 'mIQEE_ImpotSpecial')
                                            BEGIN
                                                IF @iID_Enregistrement_TMP IS NULL OR @iID_Enregistrement_TMP <> @iID_Enregistrement
                                                    BEGIN
                                                        SET @iID_Enregistrement_TMP = @iID_Enregistrement
                                                        INSERT INTO #tblIQEE_DetailsEvenement
                                                                (iID_Evenement_Historique,vcDescription_Detail)
                                                        VALUES (@iID_Evenement_Historique,'Impôt spécial calculé')
                                                        SET @iID_Detail_Evenement = SCOPE_IDENTITY()
                                                    END
                                                IF @vcNom_Champ = 'dtDate_Evenement'
                                                    BEGIN
                                                        SET @iID_Enregistrement_TMP = @iID_Enregistrement
                                                        --UPDATE #tblIQEE_DetailsEvenement
                                                        --SET dtDate = Left(@vcValeur, 10)
                                                        --WHERE iID_Detail_Evenement = @iID_Detail_Evenement
                                                    END
                                                IF @vcNom_Champ = 'mSolde_IQEE_Base'
                                                    BEGIN
                                                        SET @iID_Enregistrement_TMP = @iID_Enregistrement
                                                        UPDATE #tblIQEE_DetailsEvenement
                                                        SET mCredit_Base = ISNULL(mCredit_Base,0) - CAST(@vcValeur AS MONEY)
                                                        WHERE iID_Detail_Evenement = @iID_Detail_Evenement
                                                    END
                                                IF @vcNom_Champ = 'mSolde_IQEE_Majore'
                                                    BEGIN
                                                        SET @iID_Enregistrement_TMP = @iID_Enregistrement
                                                        UPDATE #tblIQEE_DetailsEvenement
                                                        SET mMajoration = ISNULL(mMajoration,0) - CAST(@vcValeur AS MONEY)
                                                        WHERE iID_Detail_Evenement = @iID_Detail_Evenement
                                                    END
                                                IF @vcNom_Champ = 'mIQEE_ImpotSpecial'
                                                    BEGIN
                                                        SET @iID_Enregistrement_TMP = @iID_Enregistrement
                                                        UPDATE #tblIQEE_DetailsEvenement
                                                        SET mIQEE_SAC = ISNULL(mIQEE_SAC,0) - CAST(@vcValeur AS MONEY)
                                                        WHERE iID_Detail_Evenement = @iID_Detail_Evenement
                                                    END
                                                    
                                            END
                                        ELSE IF @vcNom_Champ <> 'iID_Impot_Special'
                                            INSERT INTO #tblIQEE_DetailsEvenement
                                                    (iID_Evenement_Historique,vcNom_Table,vcNom_Champ,vcType,vcDescription,iID_Enregistrement,vcID_Enregistrement,vcValeur)
                                            VALUES (@iID_Evenement_Historique,@vcNom_Table,@vcNom_Champ,@vcType,@vcDescription,@iID_Enregistrement,@vcID_Enregistrement,@vcValeur)
                                    END

                                IF @vcCode_Type = 'TRA_1' AND @vcNom_Table = 'tblIQEE_RaisonsAnnulation' AND @vcNom_Champ = 'vcDescription'
                                    INSERT INTO #tblIQEE_DetailsEvenement
                                            (iID_Evenement_Historique,vcNom_Table,vcNom_Champ,vcType,vcDescription,iID_Enregistrement,vcID_Enregistrement,vcValeur)
                                    VALUES (@iID_Evenement_Historique,@vcNom_Table,@vcNom_Champ,@vcType,@vcDescription,@iID_Enregistrement,@vcID_Enregistrement,@vcValeur)

                                -- Informations sur les demandes en erreur
                                IF @vcCode_Statut_A_Jour = 'TRA_MAJ_E'
                                    BEGIN
                                        IF @vcNom_Table = 'tblIQEE_Erreurs' AND @vcNom_Champ = 'iID_Erreur'
                                            SET @bDebut_Erreur = 1
            
                                        IF @vcNom_Table = 'tblIQEE_Fichiers' AND @vcNom_Champ = 'dtDate_Creation' AND @bDebut_Erreur = 1
                                            BEGIN
                                                INSERT INTO #tblIQEE_DetailsEvenement
                                                        (iID_Evenement_Historique,dtDate)
                                                VALUES (@iID_Evenement_Historique,CAST(@vcValeur AS DATETIME))
                                                SET @iID_Detail_Evenement = SCOPE_IDENTITY()
                                            END

                                        IF @vcNom_Table = 'tblIQEE_TypesErreurRQ' AND @vcNom_Champ = 'siCode_Erreur'
                                            UPDATE #tblIQEE_DetailsEvenement
                                            SET vcDescription_Detail = 'MRQ', vcReponse = @vcValeur
                                            WHERE iID_Detail_Evenement = @iID_Detail_Evenement

                                        IF @vcNom_Table = 'tblIQEE_TypesErreurRQ' AND @vcNom_Champ = 'vcDescription'
                                            UPDATE #tblIQEE_DetailsEvenement
                                            SET vcReponse = vcReponse + ' - ' + @vcValeur
                                            WHERE iID_Detail_Evenement = @iID_Detail_Evenement
                                    END

                                -- Informations sur les demandes qui ont une réponse de RQ
                                IF @vcCode_Statut_A_Jour IN ('TRA_MAJ_R','TRA_MAJ_D','TRA_MAJ_T')
                                    BEGIN
                                        IF @vcNom_Table = 'tblIQEE_ReponsesImpotsSpeciaux' 
                                            BEGIN
                                                --PRINT '***** tblIQEE_ReponsesImpotsSpeciaux'
                                                --PRINT @vcNom_Champ + ' : ' + @vcValeur
                                                --PRINT '***** '
                                                IF @vcNom_Champ = 'iID_Fichier_IQEE'
                                                    SET @iID_Fichier_IQEE_TMP = CAST(@vcValeur AS INT)

                                                IF @iID_Fichier_IQEE_TMP <> @iID_Fichier_IQEE
                                                    BEGIN
                                                        --PRINT '***** (' + cast(@iID_Detail_Evenement as varchar) + ') MRQ : ' + Cast(@iID_Fichier_IQEE_TMP as varchar) + ' / ' + Cast(@iID_Fichier_IQEE as varchar)
                                                        SET @iID_Fichier_IQEE = @iID_Fichier_IQEE_TMP
                                                        INSERT INTO #tblIQEE_DetailsEvenement
                                                                (iID_Evenement_Historique,vcDescription_Detail)
                                                        VALUES (@iID_Evenement_Historique,'MRQ')
                                                        SET @iID_Detail_Evenement = SCOPE_IDENTITY()
                                                    END
                                                
                                                IF @vcNom_Champ = 'dtDate_Avis'
                                                    BEGIN
                                                        --PRINT '***** (' + cast(@iID_Detail_Evenement as varchar) + ')' + Left(@vcValeur, 10)
                                                        SET @iID_Fichier_IQEE = @iID_Fichier_IQEE_TMP
                                                        UPDATE #tblIQEE_DetailsEvenement
                                                        SET dtDate = Left(@vcValeur, 10)
                                                        WHERE iID_Detail_Evenement = @iID_Detail_Evenement
                                                        --PRINT '****** RowCount : ' + cast(@@RowCount as varchar)
                                                    END
                                                ELSE IF @vcNom_Champ = 'mMontant_IQEE_Base'
                                                    BEGIN
                                                        SET @iID_Fichier_IQEE = @iID_Fichier_IQEE_TMP
                                                        UPDATE #tblIQEE_DetailsEvenement
                                                        SET mCredit_Base = ISNULL(mCredit_Base,0) - CAST(@vcValeur AS MONEY)
                                                        WHERE iID_Detail_Evenement = @iID_Detail_Evenement
                                                    END
                                                ELSE IF @vcNom_Champ = 'mMontant_IQEE_Majore'
                                                    BEGIN
                                                        SET @iID_Fichier_IQEE = @iID_Fichier_IQEE_TMP
                                                        UPDATE #tblIQEE_DetailsEvenement
                                                        SET mMajoration = ISNULL(mMajoration,0) - CAST(@vcValeur AS MONEY)
                                                        WHERE iID_Detail_Evenement = @iID_Detail_Evenement
                                                    END
                                                ELSE IF @vcNom_Champ = 'mMontant_IQEE'
                                                    BEGIN
                                                        SET @iID_Fichier_IQEE = @iID_Fichier_IQEE_TMP
                                                        UPDATE #tblIQEE_DetailsEvenement
                                                        SET mIQEE_SAC = ISNULL(mIQEE_SAC,0) - CAST(@vcValeur AS MONEY)
                                                        WHERE iID_Detail_Evenement = @iID_Detail_Evenement
                                                    END
                                            END

                                        IF @vcNom_Table = 'tblIQEE_Fichiers' 
                                        BEGIN
                                            --PRINT '***** tblIQEE_Fichiers'
                                            --PRINT @vcNom_Champ + ' : ' + IsNull(@vcValeur, '')
                                            --PRINT '***** '

                                            IF @vcNom_Champ = 'dtDate_Paiement'
                                            BEGIN
                                                UPDATE #tblIQEE_DetailsEvenement
                                                SET dtDate = CAST(@vcValeur AS DATETIME)
                                                WHERE iID_Detail_Evenement = @iID_Detail_Evenement
                                                  AND dtDate IS NULL
                                            END
                                        END
                                    END

                            END

                        --2015-12-18 Correctif où des détails de rejet sont retourné pour des évenement absent de la grille
                        -- Informations sur les rejets
                        --IF @vcCode_Type LIKE 'REJ%'
                        --    BEGIN
                        --        IF @vcNom_Table = 'tblIQEE_Parametres' AND @vcNom_Champ <> 'iID_Parametres_IQEE' AND @bParametre = 0
                        --            BEGIN
                        --                INSERT INTO #tblIQEE_DetailsEvenement
                        --                        (iID_Evenement_Historique,vcNom_Table,vcNom_Champ,vcType,vcDescription,iID_Enregistrement,vcID_Enregistrement,vcValeur)
                        --                VALUES (@iID_Evenement_Historique,@vcNom_Table,@vcNom_Champ,@vcType,@vcDescription,@iID_Enregistrement,@vcID_Enregistrement,@vcValeur)
                        --                IF @vcNom_Champ = 'dtDate_Fin_Cotisation'
                        --                    SET @bParametre = 1
                        --            END

                        --        IF @vcNom_Table = 'tblIQEE_Rejets' AND @vcNom_Champ = 'vcDescription'
                        --            BEGIN
                        --                INSERT INTO #tblIQEE_DetailsEvenement
                        --                        (iID_Evenement_Historique,vcReponse)
                        --                VALUES (@iID_Evenement_Historique,@vcValeur)
                        --                SET @iID_Detail_Evenement = SCOPE_IDENTITY()
                        --            END

                        --        IF @vcNom_Table = 'tblIQEE_Validations' AND @vcNom_Champ = 'iCode_Validation'
                        --            UPDATE #tblIQEE_DetailsEvenement
                        --            SET vcReponse = @vcValeur + ' - ' + vcReponse
                        --            WHERE iID_Detail_Evenement = @iID_Detail_Evenement
                        --    END

                        -- Informations sur les erreurs
                        IF @vcCode_Type LIKE 'ERR%'
                            BEGIN
                                IF (@vcNom_Table = 'tblIQEE_Erreurs' AND @vcNom_Champ <> 'iID_Erreur' AND @vcNom_Champ <> 'iID_Fichier_IQEE') OR
                                   (@vcNom_Table = 'tblIQEE_Fichiers' AND @vcNom_Champ <> 'iID_Fichier_IQEE') OR
                                   (@vcNom_Table = 'tblIQEE_TypesErreurRQ' AND @vcNom_Champ <> 'siCode_Erreur')
                                    INSERT INTO #tblIQEE_DetailsEvenement
                                            (iID_Evenement_Historique,vcNom_Table,vcNom_Champ,vcType,vcDescription,iID_Enregistrement,vcID_Enregistrement,vcValeur)
                                    VALUES (@iID_Evenement_Historique,@vcNom_Table,@vcNom_Champ,@vcType,@vcDescription,@iID_Enregistrement,@vcID_Enregistrement,@vcValeur)
                            END

                        -- Informations sur les annulations/reprises
                        IF @vcCode_Type LIKE 'A/R%'
                            BEGIN
                                IF @vcNom_Table = 'tblIQEE_Annulations' AND @vcNom_Champ = 'iID_Utilisateur_Demande'
                                    SET @iID_Utilisateur_Demande = CAST(@vcValeur AS INT)

                                IF @vcNom_Table = 'tblIQEE_Annulations' AND @vcNom_Champ = 'iID_Utilisateur_Action_Menant_Annulation'
                                    SET @iID_Utilisateur_Action_Menant_Annulation = CAST(@vcValeur AS INT)

                                IF @vcNom_Table = 'tblIQEE_Annulations' AND @vcNom_Champ IN ('tCommentaires','dtDate_Action_Menant_Annulation')
                                    INSERT INTO #tblIQEE_DetailsEvenement
                                            (iID_Evenement_Historique,vcNom_Table,vcNom_Champ,vcType,vcDescription,iID_Enregistrement,vcID_Enregistrement,vcValeur)
                                    VALUES (@iID_Evenement_Historique,@vcNom_Table,@vcNom_Champ,@vcType,@vcDescription,@iID_Enregistrement,@vcID_Enregistrement,@vcValeur)

                                IF @vcNom_Table = 'Mo_Human' AND @vcNom_Champ = 'HumanID'
                                    SET @iID_Humain = CAST(@vcValeur AS INT)

                                IF @vcNom_Table = 'Mo_Human' AND @vcNom_Champ IN ('FirstName','LastName')
                                    BEGIN
                                        IF @vcNom_Champ = 'FirstName'
                                            BEGIN
                                                IF @iID_Humain = @iID_Utilisateur_Demande 
                                                    INSERT INTO #tblIQEE_DetailsEvenement
                                                            (iID_Evenement_Historique,vcNom_Table,vcNom_Champ,vcType,vcDescription,iID_Enregistrement,vcID_Enregistrement,vcValeur)
                                                    VALUES (@iID_Evenement_Historique,'Annulation1_'+@vcNom_Table,@vcNom_Champ,@vcType,@vcDescription,@iID_Enregistrement,@vcID_Enregistrement,@vcValeur)
                                                ELSE
                                                    INSERT INTO #tblIQEE_DetailsEvenement
                                                            (iID_Evenement_Historique,vcNom_Table,vcNom_Champ,vcType,vcDescription,iID_Enregistrement,vcID_Enregistrement,vcValeur)
                                                    VALUES (@iID_Evenement_Historique,'Annulation2_'+@vcNom_Table,@vcNom_Champ,@vcType,@vcDescription,@iID_Enregistrement,@vcID_Enregistrement,@vcValeur)
                                                SET @iID_Detail_Evenement = SCOPE_IDENTITY()
                                            END

                                        IF @vcNom_Champ = 'LastName'
                                            UPDATE #tblIQEE_DetailsEvenement
                                            SET vcValeur = vcValeur + ' ' + @vcValeur
                                            WHERE iID_Detail_Evenement = @iID_Detail_Evenement
                                    END
                            END

                        -- Informations sur les notes et changements de bénéficiaire
                        IF @vcCode_Evenement = 'NOTE' OR @vcCode_Evenement = 'BENEF_CHG'
                            BEGIN
                                IF (@vcNom_Table = 'tblGENE_Note' AND @vcNom_Champ = 'tTexte') OR
                                   (@vcNom_Table = 'tblCONV_ChangementsBeneficiaire' AND @vcNom_Champ <> 'iID_Changement_Beneficiaire')
                                    INSERT INTO #tblIQEE_DetailsEvenement
                                            (iID_Evenement_Historique,vcNom_Table,vcNom_Champ,vcType,vcDescription,iID_Enregistrement,vcID_Enregistrement,vcValeur)
                                    VALUES (@iID_Evenement_Historique,@vcNom_Table,@vcNom_Champ,@vcType,@vcDescription,@iID_Enregistrement,@vcID_Enregistrement,@vcValeur)
                            END

                        FETCH NEXT FROM curIQEE_Valeurs INTO @vcNom_Table,@vcNom_Champ,@vcType,@vcDescription,@iID_Enregistrement,@vcID_Enregistrement,@vcValeur
                    END
                CLOSE curIQEE_Valeurs
                DEALLOCATE curIQEE_Valeurs

                DELETE FROM #tblGENE_Valeurs

                FETCH NEXT FROM curIQEE_Evenements INTO @iID_Evenement_Historique,@iID_Convention,@vcCode_Evenement,@vcCode_Type,@vcCode_Statut_A_Jour,@iID_Primaire
            END
        CLOSE curIQEE_Evenements
        DEALLOCATE curIQEE_Evenements

        IF @vcCode_Structure_Presentation = 'SAC'
            UPDATE #tblIQEE_DetailsEvenement
            SET mIQEE_SAC = ISNULL(mCredit_Base,0) + ISNULL(mMajoration,0) + ISNULL(mInterets,0)  
            WHERE mCredit_Base IS NOT NULL
               OR mMajoration IS NOT NULL
               OR mInterets IS NOT NULL

        -- Trouver les descriptions des champs selon la présentation choisie
        UPDATE DE
        SET vcDescription_Detail = COALESCE(dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoPresentations','vcDescription',HPE.iID_Presentation,NULL,@cID_Langue),
                                            HPE.vcDescription,
                                            dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoDetails','vcDescription',HD.iID_Detail,NULL,@cID_Langue),
                                            HD.vcDescription,
                                            DE.vcDescription)
        FROM #tblIQEE_DetailsEvenement DE
             LEFT JOIN tblIQEE_HistoDetails HD ON HD.vcNom_Table = DE.vcNom_Table
                                              AND HD.vcNom_Champ = DE.vcNom_Champ
                                              AND HD.bResume = 1
             LEFT JOIN tblIQEE_HistoPresentations HPE ON HPE.iID_Structure_Historique = @iID_Structure_Historique_Presentation
                                                     AND HPE.vcCode_Type_Info = 'DET'
                                                     AND HPE.vcNom_Table = DE.vcNom_Table
                                                     AND HPE.vcNom_Champ = DE.vcNom_Champ
        WHERE vcDescription_Detail IS NULL

        --------------------------------------
        --
        -- Déterminer les messages applicables
        --
        --------------------------------------
        CREATE TABLE #tblIQEE_Messages(
            iID_Convention INT,
            vcCode_Message VARCHAR(3),
            vcDescription VARCHAR(1000))

        IF @vcCode_Structure_Presentation = 'TI1'
            BEGIN
                DECLARE curMessages CURSOR LOCAL FAST_FORWARD FOR
                    SELECT M.vcCode_Message, COALESCE(dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoMessages','vcDescription',M.iID_Message,NULL,@cID_Langue),M.vcDescription)  
                    FROM tblIQEE_HistoMessages M
                    WHERE M.vcCode_Droit IS NULL
                       OR dbo.fnSECU_ObtenirAccessibiliteDroitUtilisateur(CAST(ISNULL(@iID_Utilisateur,0) AS VARCHAR(255)),M.vcCode_Droit) = 1

                OPEN curMessages
                FETCH NEXT FROM curMessages INTO @vcCode_Message_IQEE,@vcDescription_Message
                WHILE @@FETCH_STATUS = 0
                    BEGIN
                        -- Des rejets doivent être traités par les opérations ou sont en attente de la création d'un fichier de transactions.
                        IF @vcCode_Message_IQEE = 'REJ'
                            INSERT INTO #tblIQEE_Messages
                            SELECT C.iID_Convention,'REJ',@vcDescription_Message
                            FROM #tblIQEE_Conventions C
                            WHERE C.vcCode_Statut <> 'INC'
                              AND EXISTS(SELECT *
                                         FROM #tblIQEE_Evenements E
                                         WHERE E.iID_Convention = C.iID_Convention
                                           AND E.vcCode_Statut_A_Jour = 'REJ_MAJ_ACO')

                        -- Avertissement: Il y a au moins un rejet théoriquement intraitable qui a quand même été corrigé par la suite.
                        IF @vcCode_Message_IQEE = 'RIC'
                            INSERT INTO #tblIQEE_Messages
                            SELECT C.iID_Convention,'RIC',@vcDescription_Message
                            FROM #tblIQEE_Conventions C
                            WHERE C.vcCode_Statut <> 'INC'
                              AND EXISTS(SELECT *
                                         FROM #tblIQEE_Evenements E
                                         WHERE E.iID_Convention = C.iID_Convention
                                           AND E.vcCode_Statut_A_Jour = 'REJ_MAJ_COI')

                        -- Des transactions sont en attente de RQ ou sur le point d'être transmises à RQ.
                        IF @vcCode_Message_IQEE = 'ARQ'
                            INSERT INTO #tblIQEE_Messages
                            SELECT C.iID_Convention,'ARQ',@vcDescription_Message
                            FROM #tblIQEE_Conventions C
                            WHERE EXISTS(SELECT *
                                         FROM #tblIQEE_Evenements E
                                         WHERE E.iID_Convention = C.iID_Convention
                                           AND E.vcCode_Statut_A_Jour IN ('TRA_MAJ_CRE','TRA_MAJ_APP','TRA_MAJ_A','TRA_MAJ_D','A/R_MAJ_ACA',
                                                                          'A/R_MAJ_ARA','A/R_MAJ_A0A','A/R_MAJ_AOA'))

                        -- Des erreurs doivent être traitées par les opérations.
                        IF @vcCode_Message_IQEE = 'EOP'
                            INSERT INTO #tblIQEE_Messages
                            SELECT C.iID_Convention,'EOP',@vcDescription_Message
                            FROM #tblIQEE_Conventions C
                            WHERE EXISTS(SELECT *
                                         FROM #tblIQEE_Evenements E
                                         WHERE E.vcCode_Type = 'ERR_OPE'
                                           AND E.iID_Convention = C.iID_Convention
                                           AND E.vcCode_Statut_A_Jour = 'ERR_MAJ_ATR')

                        -- Des erreurs doivent être traitées par les TI.
                        IF @vcCode_Message_IQEE = 'ETI'
                            INSERT INTO #tblIQEE_Messages
                            SELECT C.iID_Convention,'ETI',@vcDescription_Message
                            FROM #tblIQEE_Conventions C
                            WHERE EXISTS(SELECT *
                                         FROM #tblIQEE_Evenements E
                                         WHERE E.iID_Convention = C.iID_Convention
                                           AND E.vcCode_Type = 'ERR_TI'
                                           AND E.vcCode_Statut_A_Jour = 'ERR_MAJ_ATR')

                        -- Des demandes d'annulations sont en attente de la création d'un fichier de transactions.
                        IF @vcCode_Message_IQEE = 'DAA'
                            INSERT INTO #tblIQEE_Messages
                            SELECT C.iID_Convention,'DAA',@vcDescription_Message
                            FROM #tblIQEE_Conventions C
                            WHERE EXISTS(SELECT *
                                         FROM #tblIQEE_Evenements E
                                         WHERE E.iID_Convention = C.iID_Convention
                                           AND E.vcCode_Statut_A_Jour = 'A/R_MAJ_MAN')

                        -- Des notes sur l'IQÉÉ sont présentes au dossier.
                        IF @vcCode_Message_IQEE = 'NOT'
                            INSERT INTO #tblIQEE_Messages
                            SELECT C.iID_Convention,'NOT',@vcDescription_Message
                            FROM #tblIQEE_Conventions C
                            WHERE EXISTS(SELECT *
                                         FROM #tblIQEE_Evenements E
                                         WHERE E.iID_Convention = C.iID_Convention
                                           AND E.vcCode_Evenement = 'NOTE')

                        -- Changement de bénéficiaire non reconnu dans la convention.
                        IF @vcCode_Message_IQEE = 'CBN'
                            INSERT INTO #tblIQEE_Messages
                            SELECT C.iID_Convention,'CBN',@vcDescription_Message
                            FROM #tblIQEE_Conventions C
                            WHERE C.vcCode_Statut <> 'INC'
                              AND EXISTS(SELECT *
                                         FROM #tblIQEE_Evenements E
                                         WHERE E.iID_Convention = C.iID_Convention
                                           AND E.vcCode_Statut_A_Jour = 'CHB_MAJ_NRE')

                        -- Transfert non autorisé dans la convention.
                        IF @vcCode_Message_IQEE = 'TNA'
                            INSERT INTO #tblIQEE_Messages
                            SELECT C.iID_Convention,'TNA',@vcDescription_Message
                            FROM #tblIQEE_Conventions C
                            WHERE C.vcCode_Statut <> 'INC'
                              AND EXISTS(SELECT *
                                         FROM #tblIQEE_Evenements E
                                         WHERE E.iID_Convention = C.iID_Convention
                                           AND E.vcCode_Statut_A_Jour = 'TRF_MAJ_NAU')

                        -- Il y a eu remboursement d'IQÉÉ dans la convention.
                        IF @vcCode_Message_IQEE = 'REM'
                            INSERT INTO #tblIQEE_Messages
                            SELECT C.iID_Convention,'REM',@vcDescription_Message
                            FROM #tblIQEE_Conventions C
                            WHERE EXISTS(SELECT *
                                         FROM #tblIQEE_Evenements E
                                         WHERE E.iID_Convention = C.iID_Convention
                                           AND E.vcCode_Evenement IN ('T0601','T0602','T0611','T0622','T0631','T0632','T0641','T0651','T0691'))

                        -- Erreur: Le solde de l'IQÉÉ de RQ est différent du solde de l'IQÉÉ de GUI.
                        IF @vcCode_Message_IQEE = 'DSI'
                            INSERT INTO #tblIQEE_Messages
                            SELECT C.iID_Convention,'DSI',@vcDescription_Message
                            FROM #tblIQEE_Conventions C
                            WHERE EXISTS(SELECT *
                                         FROM #tblIQEE_Evenements E
                                         WHERE E.iID_Convention = C.iID_Convention
                                           AND E.mSolde_GUI_IQEE <> E.mSolde_RQ_Solde_IQEE)

                        -- Erreur: Le solde des cotisations ayant donné droit de RQ est différent du solde de GUI.
                        IF @vcCode_Message_IQEE = 'DSC'
                            INSERT INTO #tblIQEE_Messages
                            SELECT C.iID_Convention,'DSC',@vcDescription_Message
                            FROM #tblIQEE_Conventions C
                            WHERE EXISTS(SELECT *
                                         FROM #tblIQEE_Evenements E
                                         WHERE E.iID_Convention = C.iID_Convention
                                           AND E.mSolde_GUI_Cotisations_Ayant_Donne_Droit <> E.mSolde_RQ_Cotisations_Ayant_Donne_Droit)

                        -- La convention est en proposition.
                        IF @vcCode_Message_IQEE = 'PRP'
                            INSERT INTO #tblIQEE_Messages
                            SELECT C.iID_Convention,'PRP',@vcDescription_Message
                            FROM #tblIQEE_Conventions C
                            WHERE vcStatut_Convention = 'PRP'

                        -- La convention est fermée.
                        IF @vcCode_Message_IQEE = 'FRM'
                            INSERT INTO #tblIQEE_Messages
                            SELECT C.iID_Convention,'FRM',@vcDescription_Message
                            FROM #tblIQEE_Conventions C
                            WHERE vcStatut_Convention = 'FRM'

                        -- GUI ne connait pas la raison de la non obtention de la majoration.
                        IF @vcCode_Message_IQEE = 'SMA'
                            INSERT INTO #tblIQEE_Messages
                            SELECT C.iID_Convention,'SMA',@vcDescription_Message
                            FROM #tblIQEE_Conventions C
                            WHERE C.vcCode_Statut <> 'INC'
                              AND NOT EXISTS(SELECT *
                                             FROM #tblIQEE_Evenements E
                                             WHERE E.iID_Convention = C.iID_Convention
                                               AND E.vcCode_Type IN ('REP_PRO','REP_NOU')
                                               AND E.mDetermination_Majoration = 0)

-- TODO: Messages à programmer?
                        --Le bénéficiaire a au moins 1 REÉÉ chez un autre fiduciaire.
                        --La convention n'a pas eu tout l'IQÉÉ demandé.
                        --Des pénalités ont été appliqué par RQ.
                        --Une réponse de RQ contenant de l'IQÉÉ n'a pas été importé dans la convention
                        FETCH NEXT FROM curMessages INTO @vcCode_Message_IQEE,@vcDescription_Message
                    END
                CLOSE curMessages
                DEALLOCATE curMessages
            END

        --------------
        --
        -- Info-bulles 
        --
        --------------
        IF @vcCode_Structure_Presentation = 'TI1'
            BEGIN
                DECLARE @cRetour CHAR(1)
                SET @cRetour = CHAR(13)

                -- Valeur du champ comme info-bulle
                UPDATE E
                SET vcCommentaires_Date_Chronologique = CONVERT(VARCHAR(MAX),E.dtDate_Chronologique,121),
                    vcCommentaires_Evenement = E.vcDescription_Evenement,
                    vcCommentaires_Type = E.vcDescription_Type,
                    vcCommentaires_Statut_Chronologique = E.vcDescription_Statut_Chronologique
                FROM #tblIQEE_Evenements E
                     LEFT JOIN tblIQEE_HistoPresentations HPE ON HPE.iID_Structure_Historique = @iID_Structure_Historique_Presentation
                                                             AND HPE.vcCode_Type_Info = 'BUL'

                -- Note sur les notes
                UPDATE E
                SET vcCommentaires_Evenement = N.tTexte
                FROM #tblIQEE_Evenements E
                     JOIN tblGENE_Note N ON N.iID_Note = E.iID_Primaire
                WHERE E.vcCode_Evenement = 'NOTE'

                -- Info-bulle sur le statut chronologique
                UPDATE E
                SET vcCommentaires_Statut_Chronologique = CASE WHEN vcCommentaires_Statut_Chronologique IS NULL THEN '' ELSE vcCommentaires_Statut_Chronologique+@cRetour+@cRetour END +
                                                          REPLACE(COALESCE(dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoPresentations','vcCommentaires_Utilisateur',HP.iID_Presentation,NULL,@cID_Langue),
                                                                  HP.vcCommentaires_Utilisateur),'%vcNom_Utilisateur%',E.vcNom_Utilisateur)
                FROM #tblIQEE_Evenements E
                     JOIN tblIQEE_HistoPresentations HP ON HP.iID_Structure_Historique = @iID_Structure_Historique_Presentation
                                                       AND HP.vcCode_Type_Info = 'BUL-STA'
                                                       AND HP.vcCode_Info = E.vcCode_Statut_Chronologique

                -- Info-bulle sur la date d'événement
                UPDATE E
                SET vcCommentaires_Date_Evenement = REPLACE(REPLACE(REPLACE(REPLACE(
                                                            COALESCE(dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoPresentations','vcCommentaires_Utilisateur',HP.iID_Presentation,NULL,@cID_Langue),
                                                            HP.vcCommentaires_Utilisateur),
                                                            '%dtDate_Evenement%',ISNULL(CONVERT(VARCHAR(MAX),E.dtDate_Evenement,121),'Indéterminé')),
                                                            '%dtDate_Operation%',ISNULL(CONVERT(VARCHAR(MAX),E.dtDate_Operation,121),'Indéterminé')),
                                                            '%dtDate_Effectivite%',ISNULL(CONVERT(VARCHAR(MAX),E.dtDate_Effectivite,121),'Indéterminé')),
                                                            '%dtDate_Sequence%',ISNULL(CONVERT(VARCHAR(MAX),E.dtDate_Sequence,121),'Indéterminé'))
                FROM #tblIQEE_Evenements E
                     JOIN tblIQEE_HistoPresentations HP ON HP.iID_Structure_Historique = @iID_Structure_Historique_Presentation
                                                       AND HP.vcCode_Type_Info = 'BUL'
                                                       AND HP.vcCode_Info = 'dtDate_Evenement'

                -- Info-bulle sur le statut à jour
                DECLARE curDetails CURSOR LOCAL FAST_FORWARD FOR
                    SELECT DE.iID_Evenement_Historique,DE.vcDescription_Detail,DE.vcValeur,DE.dtDate,DE.vcReponse
                    FROM #tblIQEE_DetailsEvenement DE
                    ORDER BY CASE WHEN DE.vcNom_Table IS NULL THEN 1 ELSE 2 END

                OPEN curDetails
                FETCH NEXT FROM curDetails INTO @iID_Evenement_Historique,@vcDescription_Detail,@vcValeur,@dtDate,@vcReponse
                WHILE @@FETCH_STATUS = 0
                    BEGIN
                        UPDATE E
                        SET vcCommentaires_Statut_A_Jour = ISNULL(vcCommentaires_Statut_A_Jour,'') +
                                                           CASE WHEN @vcDescription_Detail IS NOT NULL THEN @cRetour+@vcDescription_Detail+': '+@vcValeur
                                                                ELSE CASE WHEN @dtDate IS NOT NULL THEN @cRetour+SUBSTRING(CONVERT(VARCHAR(MAX),@dtDate,121),1,10)+' - '+@vcReponse
                                                                          ELSE @cRetour+@vcReponse
                                                                     END
                                                           END
                        FROM #tblIQEE_Evenements E
                        WHERE E.iID_Evenement_Historique = @iID_Evenement_Historique

                        FETCH NEXT FROM curDetails INTO @iID_Evenement_Historique,@vcDescription_Detail,@vcValeur,@dtDate,@vcReponse
                    END
                CLOSE curDetails
                DEALLOCATE curDetails

                UPDATE E
                SET vcCommentaires_Statut_A_Jour = CASE WHEN vcCommentaires_Statut_A_Jour IS NULL THEN vcDescription_Statut_A_Jour ELSE vcDescription_Statut_A_Jour+@cRetour+vcCommentaires_Statut_A_Jour END
                FROM #tblIQEE_Evenements E

                -- Info-bulle sur le statut de la convention
                DECLARE curMessages CURSOR LOCAL FAST_FORWARD FOR
                    SELECT M.iID_Convention,M.vcDescription
                    FROM #tblIQEE_Messages M
                         JOIN tblIQEE_HistoMessages HM ON HM.vcCode_Message = M.vcCode_Message
                    ORDER BY HM.iOrdre_Presentation

                OPEN curMessages
                FETCH NEXT FROM curMessages INTO @iID_Convention,@vcDescription_Message
                WHILE @@FETCH_STATUS = 0
                    BEGIN

                        UPDATE C
                        SET vcCommentaires_Statut = CASE WHEN vcCommentaires_Statut IS NULL THEN '- '+@vcDescription_Message
                                                         ELSE vcCommentaires_Statut+@cRetour+'- '+@vcDescription_Message
                                                    END
                        FROM #tblIQEE_Conventions C
                        WHERE C.iID_Convention = @iID_Convention

                        FETCH NEXT FROM curMessages INTO @iID_Convention,@vcDescription_Message
                    END
                CLOSE curMessages
                DEALLOCATE curMessages
            END

        ---------------------------------------------------------------------------
        --
        -- Retourner les informations de l'historique selon la présentation choisie
        --
        ---------------------------------------------------------------------------

        -- Structure de présentation
        SELECT SP.iNiveau,
               SP.bOuverture_Niveau,
               SP.vcNom_Colonne,
               SP.bID_Niveau,
               SP.bID_Niveau_Precedent,
               SP.bAfficher,
               COALESCE(dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoStructurePresentation','vcTitre_Colonne',SP.iID_Structure_Presentation,NULL,@cID_Langue),SP.vcTitre_Colonne) AS vcTitre_Colonne,
               SP.vcType_Donnee,
               SP.cAlignement,
               SP.iLargeur_Colonne,
               SP.bAfficher_Total,
               COALESCE(dbo.fnGENE_ObtenirTraduction('tblIQEE_HistoStructurePresentation','vcTitre_Total',SP.iID_Structure_Presentation,NULL,@cID_Langue),SP.vcTitre_Total) AS vcTitre_Total
        FROM tblIQEE_HistoStructurePresentation SP
        WHERE SP.iID_Structure_Historique = @iID_Structure_Historique_Presentation
          AND SP.cCode_Structure = 'H'
        ORDER BY SP.iNiveau,SP.iOrdre_Presentation

        -------------------
        -- Présentation SAC
        -------------------
        IF @vcCode_Structure_Presentation = 'SAC'
            BEGIN
                DELETE FROM D FROM #tblIQEE_DetailsEvenement D JOIN #tblIQEE_Evenements E ON E.iID_Evenement_Historique = D.iID_Evenement_Historique
                 WHERE E.iID_Transaction IS NULL
                DELETE FROM #tblIQEE_Evenements WHERE iID_Transaction IS NULL 

                -- Niveau #1: Conventions
                SELECT  iID_Convention,
                        vcNo_Convention,
                        vcNo_Convention AS vcNo_Convention_InfoBulle,
                        bAcces_Convention,
                        bAcces_Historique_SAC,
                        bAcces_Historique_EAFB,
                        bAcces_Gestion_Rejets,
                        bAcces_Gestion_Erreurs,
                        bAcces_Modifier_Erreurs,
                        iID_Beneficiaire,
                        vcPrenom_Beneficiaire+' '+vcNom_Beneficiaire AS vcNom_Beneficiaire,
                        vcPrenom_Beneficiaire+' '+vcNom_Beneficiaire AS vcNom_Beneficiaire_InfoBulle,
                        bAcces_Beneficiaire,
                        iID_Souscripteur,
                        vcPrenom_Souscripteur+' '+vcNom_Souscripteur AS vcNom_Souscripteur,
                        vcPrenom_Souscripteur+' '+vcNom_Souscripteur AS vcNom_Souscripteur_InfoBulle,
                        bAcces_Souscripteur,
                        bAcces_Consulter_Notes,
                        bAcces_Ajouter_Note_IQEE,
                        bAcces_Consultation_Evenement,
                        bAcces_Deplacement,
                        bAcces_Annulations_Manuelles,
                        mCourant_Credit_Base,
                        mCourant_Majoration,
                        mCourant_Interets,
                        mCourant_IQEE_SAC,
                        NULL AS vcVide1
                FROM #tblIQEE_Conventions
                ORDER BY vcNo_Convention

                -- Créer les années fiscales pour avoir un ID unique par convention/année fiscale pour que la grille dynamique se comporte bien
                CREATE TABLE #tblIQEE_AnneesFiscales(
                    iID_Annee_Fiscale INT IDENTITY(1,1) NOT NULL,
                    iID_Convention INT NOT NULL,
                    siAnnee_Fiscale SMALLINT NOT NULL)

                INSERT INTO #tblIQEE_AnneesFiscales
                    (iID_Convention,siAnnee_Fiscale)
                SELECT DISTINCT iID_Convention,YEAR(E.dtDate_Evenement)
                FROM #tblIQEE_Evenements E
                WHERE E.dtDate_Evenement IS NOT NULL

                -- Niveau #2: Années fiscales
                SELECT A.iID_Annee_Fiscale,
                       A.iID_Convention,
                       A.siAnnee_Fiscale,
                       SUM(ISNULL(E.mCourant_Credit_Base,0)) AS mCourant_Credit_Base,
                       SUM(ISNULL(E.mCourant_Majoration,0)) AS mCourant_Majoration,
                       SUM(ISNULL(E.mCourant_Interets,0)) AS mCourant_Interets,
                       SUM(ISNULL(E.mCourant_IQEE_SAC,0)) AS mCourant_IQEE_SAC,
                       NULL AS vcVide2
                FROM #tblIQEE_AnneesFiscales A
                     JOIN #tblIQEE_Evenements E ON E.iID_Convention = A.iID_Convention
                                               AND YEAR(E.dtDate_Evenement) = A.siAnnee_Fiscale
                GROUP BY A.iID_Annee_Fiscale,
                         A.iID_Convention,
                         A.siAnnee_Fiscale
                ORDER BY A.iID_Convention,A.siAnnee_Fiscale DESC

                -- Niveau #3: Événements de l'IQÉÉ
                SET @vcSQL = 'SELECT CASE WHEN E.dtDate_Chronologique < ' + @dtAffichage_TransactionID + ' THEN ''<div style="COLOR: lightslategray;">'' + LTrim(Str(E.iID_Transaction)) + ''</div>'' ELSE LTrim(Str(E.iID_Transaction)) END as iID_Transaction,
                                     A.iID_Annee_Fiscale,
                                     E.iID_Convention,
                                     E.iID_Evenement_Historique,
                                     E.dtDate_Chronologique,
                                     E.vcDescription_Evenement,
                                     E.vcDescription_Evenement AS vcDescription_Evenement_InfoBulle,
                                     E.vcDescription_Type,
                                     E.vcDescription_Type AS vcDescription_Type_InfoBulle,
                                     E.vcDescription_Statut_A_Jour,
                                     E.vcDescription_Statut_A_Jour AS vcDescription_Statut_A_Jour_InfoBulle,
                                     E.mCourant_Credit_Base,
                                     E.mCourant_Majoration,
                                     E.mCourant_Interets,
                                     E.mCourant_IQEE_SAC,
                                     E.vcCode_Evenement,
                                     E.vcCode_Type,
                                     E.vcCode_Statut_A_Jour,
                                     E.iID_Primaire,
                                     E.iID_Fichier_IQEE,
                                     E.tiID_Type_Enregistrement,
                                     E.iID_Enregistrement,
                                     E.iID_Erreur,
                                     E.vcIDs_Associations,
                                     E.bAnnulation_Manuelle,
                                     E.iID_Sous_Type,
                                     E.dtDate_Evenement,
                                     E.vcIDs_Annulations_Manuelles,
                                     NULL AS vcVide3 
                              FROM #tblIQEE_Evenements E
                                   JOIN tblIQEE_HistoEvenements HE ON HE.iID_Evenement = E.iID_Evenement
                                   JOIN #tblIQEE_AnneesFiscales A ON A.iID_Convention = E.iID_Convention
                                                                 AND A.siAnnee_Fiscale = YEAR(E.dtDate_Evenement) '

                SET @vcSQL_OrderBy = ''

                IF @vcCode_Structure_Tri = 'DCI' -- Date chronologique inversé/Événement
                    SET @vcSQL_OrderBy = 'ORDER BY E.iID_Convention,YEAR(E.dtDate_Evenement) DESC,E.dtDate_Chronologique DESC,
                                                    CASE WHEN HE.vcCode_Regroupement = ''UNI'' THEN HE.iOrdre_Presentation ELSE 999999 END DESC,
                                                    E.vcCode_Evenement DESC,ISNULL(E.dtDate_Sequence,E.dtDate_Evenement) DESC,HE.iOrdre_Presentation DESC'
                IF @vcCode_Structure_Tri = 'DEE' -- Date d'événement inversé/Événement
                    SET @vcSQL_OrderBy = 'ORDER BY E.iID_Convention,YEAR(E.dtDate_Evenement) DESC,E.dtDate_Evenement DESC,
                                                    CASE WHEN HE.vcCode_Regroupement = ''UNI'' THEN HE.iOrdre_Presentation ELSE 999999 END DESC,
                                                    E.vcCode_Evenement DESC,E.dtDate_Chronologique DESC,HE.iOrdre_Presentation DESC'
                IF @vcCode_Structure_Tri = 'EDC' -- Événement/Date chronologique inversé
                    SET @vcSQL_OrderBy = 'ORDER BY E.iID_Convention,YEAR(E.dtDate_Evenement) DESC,
                                                    CASE WHEN HE.vcCode_Regroupement = ''UNI'' THEN HE.iOrdre_Presentation ELSE 999999 END DESC,
                                                    E.vcCode_Evenement DESC,HE.iOrdre_Presentation DESC,E.dtDate_Chronologique DESC,E.dtDate_Evenement DESC'
                IF @vcCode_Structure_Tri = 'EDE' -- Événement/Date d'événement inversé
                    SET @vcSQL_OrderBy = 'ORDER BY E.iID_Convention,YEAR(E.dtDate_Evenement) DESC,
                                                    CASE WHEN HE.vcCode_Regroupement = ''UNI'' THEN HE.iOrdre_Presentation ELSE 999999 END DESC,
                                                    E.vcCode_Evenement DESC,HE.iOrdre_Presentation DESC,E.dtDate_Evenement DESC,E.dtDate_Chronologique DESC'
                IF LEN(@vcSQL_OrderBy) > 0
                    SET @vcSQL_OrderBy = REPLACE(@vcSQL_OrderBy, 'E.dtDate_Chronologique DESC', 'E.dtDate_Chronologique DESC,E.iID_Transaction DESC')

                SET @vcSQL = @vcSQL + @vcSQL_OrderBy
                EXECUTE(@vcSQL)

                -- Niveau #4: Détails de l'événement
                SELECT --DISTINCT
                       DE.iID_Detail_Evenement
                       ,DE.iID_Evenement_Historique
                       ,DE.vcDescription_Detail
                       ,DE.vcDescription_Detail AS vcDescription_Detail_InfoBulle
                       ,DE.vcValeur
                       ,DE.vcValeur AS vcValeur_InfoBulle
                       ,DE.dtDate
                       ,DE.vcReponse
                       ,DE.vcReponse AS vcReponse_InfoBulle
                       ,DE.mCredit_Base
                       ,DE.mMajoration
                       ,DE.mInterets
                       ,DE.mIQEE_SAC
                       ,NULL AS vcVide4
                FROM #tblIQEE_DetailsEvenement DE
                where NOT EXISTS (SELECT * FROM #tblIQEE_Evenements E1 WHERE E1.iID_Evenement_Historique = DE.iID_Evenement_Historique
                                                                         AND E1.tiID_Type_Enregistrement IN (2))
				 
                    -- 2014-06-06: Ajout de jointures dans la requête de niveau 4 pour la vue SAC pour éviter les erreurs techniques de type 
                    --'This constraint cannot be enabled as not all values have corresponding parent values.'
                    -- causées par un déséquilibre des contenus entre les tables #tblIQEE_Evenements et #tblIQEE_DetailsEvenement. 
                    -- Par exemple, 27 conventions étaient impliquées parce que des rejets de T03 avec bCorrectionPossible=1 étaient présentes dans la
                    -- table #tblIQEE_DetailsEvenement mais dont les valeurs de iID_Evenement étaient inexistantes dans la requête de niveau 3.
                    
                    --JOIN tblIQEE_HistoEvenements HE ON HE.iID_Evenement = DE.iID_Evenement_Historique --E.iID_Evenement
                    --JOIN #tblIQEE_Evenements E ON E.iID_Evenement = DE.iID_Evenement_Historique
                    --JOIN #tblIQEE_AnneesFiscales A ON A.iID_Convention = E.iID_Convention
                ORDER BY DE.iID_Evenement_Historique,CASE WHEN DE.vcNom_Table IS NULL THEN 1 ELSE 2 END,DE.dtDate DESC,DE.vcReponse

            END

        -------------------------------------------------------------
        -- Présentation de l'informatique (version Événements/Résumé)
        -------------------------------------------------------------
        IF @vcCode_Structure_Presentation = 'TI1'
            BEGIN
                -- Niveau #1: Conventions
                SELECT  iID_Convention,
                        vcNo_Convention,
                        bAcces_Convention,
                        bAcces_Historique_SAC,
                        bAcces_Historique_EAFB,
                        bAcces_Gestion_Rejets,
                        bAcces_Gestion_Erreurs,
                        bAcces_Modifier_Erreurs,
                        iID_Beneficiaire,
                        vcPrenom_Beneficiaire+' '+vcNom_Beneficiaire AS vcNom_Beneficiaire,
                        bAcces_Beneficiaire,
                        iID_Souscripteur,
                        vcPrenom_Souscripteur+' '+vcNom_Souscripteur AS vcNom_Souscripteur,
                        bAcces_Souscripteur,
                        bAcces_Consulter_Notes,
                        bAcces_Ajouter_Note_IQEE,
                        bAcces_Consultation_Evenement,
                        bAcces_Deplacement,
                        bAcces_Annulations_Manuelles,
                        vcDescription_Statut,
                        vcCommentaires_Statut AS vcDescription_Statut_InfoBulle,
                        mCourant_IQEE,
                        mCourant_Credit_Base,
                        mCourant_Majoration,
                        mCourant_Interets,
                        mCourant_Cotisations_Ayant_Donne_Droit,
                        NULL AS vcVide1
                FROM #tblIQEE_Conventions
                ORDER BY vcNo_Convention

                -- Niveau #2: Événements de l'IQÉÉ
                SET @vcSQL = 'SELECT CASE WHEN E.dtDate_Chronologique < ' + @dtAffichage_TransactionID + ' THEN ''<div style="COLOR: lightslategray;">'' + LTrim(Str(E.iID_Transaction)) + ''</div>'' ELSE LTrim(Str(E.iID_Transaction)) END as iID_Transaction,
                                     E.iID_Convention,
                                     E.iID_Evenement_Historique,
                                     E.dtDate_Chronologique,
                                     E.vcCommentaires_Date_Chronologique AS dtDate_Chronologique_InfoBulle,
                                     E.vcDescription_Statut_Chronologique,
                                     E.vcCommentaires_Statut_Chronologique AS vcDescription_Statut_Chronologique_InfoBulle,
                                     HPC.vcCouleur_Fond AS vcDescription_Statut_Chronologique_vcCouleur_Fond,
                                     HPC.vcCouleur_Texte AS vcDescription_Statut_Chronologique_vcCouleur_Texte,
                                     HPC.bGras AS vcDescription_Statut_Chronologique_bGras,
                                     E.dtDate_Evenement,
                                     E.vcCommentaires_Date_Evenement AS dtDate_Evenement_InfoBulle,
                                     E.vcDescription_Evenement,
                                     E.vcCommentaires_Evenement AS vcDescription_Evenement_InfoBulle,
                                     E.vcDescription_Type,
                                     E.vcCommentaires_Type AS vcDescription_Type_InfoBulle,
                                     E.vcDescription_Statut_A_Jour,
                                     E.vcCommentaires_Statut_A_Jour AS vcDescription_Statut_A_Jour_InfoBulle,
                                     HPS.vcCouleur_Fond AS vcDescription_Statut_A_Jour_vcCouleur_Fond,
                                     HPS.vcCouleur_Texte AS vcDescription_Statut_A_Jour_vcCouleur_Texte,
                                     HPS.bGras AS vcDescription_Statut_A_Jour_bGras,
                                     E.mCourant_IQEE,
                                     E.mCourant_Credit_Base,
                                     E.mCourant_Majoration,
                                     E.mCourant_Interets,
                                     E.mCourant_Cotisations_Ayant_Donne_Droit,
                                     E.mDetermination_IQEE,
                                     E.mDetermination_Credit_Base,
                                     E.mDetermination_Majoration,
                                     E.mDetermination_Interets,
                                     E.mDetermination_Cotisations_Ayant_Donne_Droit,
                                     E.mSolde_GUI_IQEE,
                                     E.mSolde_GUI_Credit_Base,
                                     E.mSolde_GUI_Majoration,
                                     E.mSolde_GUI_Cotisations_Ayant_Donne_Droit,
                                     E.mDifferentiel_IQEE,
                                     E.mDifferentiel_Credit_Base,
                                     E.mDifferentiel_Majoration,
                                     E.mDifferentiel_Interets,
                                     E.mSolde_RQ_Cumul_IQEE_Beneficiaire,
                                     E.mSolde_RQ_Solde_IQEE,
                                     E.mSolde_RQ_Cotisations_Ayant_Donne_Droit,
                                     E.vcCode_Evenement,
                                     E.vcCode_Type,
                                     E.vcCode_Statut_A_Jour,
                                     E.iID_Primaire,
                                     E.iID_Fichier_IQEE,
                                     E.tiID_Type_Enregistrement,
                                     E.iID_Enregistrement,
                                     E.iID_Erreur,
                                     E.vcIDs_Associations,
                                     E.bAnnulation_Manuelle,
                                     E.iID_Sous_Type,
                                     E.vcIDs_Annulations_Manuelles 
                              FROM #tblIQEE_Evenements E 
                                   JOIN #tblIQEE_Conventions C ON C.iID_Convention = E.iID_Convention 
                                   JOIN tblIQEE_HistoEvenements HE ON HE.iID_Evenement = E.iID_Evenement
                                   LEFT JOIN tblIQEE_HistoPresentations HPC ON HPC.iID_Structure_Historique = '+CAST(@iID_Structure_Historique_Presentation AS VARCHAR)+'
                                                                           AND HPC.vcCode_Type_Info = ''STA''
                                                                           AND HPC.vcCode_Info = E.vcCode_Statut_Chronologique
                                   LEFT JOIN tblIQEE_HistoPresentations HPS ON HPS.iID_Structure_Historique = '+CAST(@iID_Structure_Historique_Presentation AS VARCHAR)+'
                                                                           AND HPS.vcCode_Type_Info = ''STA''
                                                                           AND HPS.vcCode_Info = E.vcCode_Statut_A_Jour '

                SET @vcSQL_OrderBy = ''
                IF @vcCode_Structure_Tri = 'DCI' -- Date chronologique inversé/Événement
                    SET @vcSQL_OrderBy = 'ORDER BY E.iID_Convention,E.dtDate_Chronologique DESC,
                                                    CASE WHEN HE.vcCode_Regroupement = ''UNI'' THEN HE.iOrdre_Presentation ELSE 999999 END DESC,
                                                    E.vcCode_Evenement DESC,ISNULL(E.dtDate_Sequence,E.dtDate_Evenement) DESC,HE.iOrdre_Presentation DESC'
                IF @vcCode_Structure_Tri = 'DEE' -- Date d'événement inversé/Événement
                    SET @vcSQL_OrderBy = 'ORDER BY E.iID_Convention,E.dtDate_Evenement DESC,
                                                    CASE WHEN HE.vcCode_Regroupement = ''UNI'' THEN HE.iOrdre_Presentation ELSE 999999 END DESC,
                                                    E.vcCode_Evenement DESC,E.dtDate_Chronologique DESC,HE.iOrdre_Presentation DESC'
                IF @vcCode_Structure_Tri = 'EDC' -- Événement/Date chronologique inversé
                    SET @vcSQL_OrderBy = 'ORDER BY E.iID_Convention,
                                                    CASE WHEN HE.vcCode_Regroupement = ''UNI'' THEN HE.iOrdre_Presentation ELSE 999999 END DESC,
                                                    E.vcCode_Evenement DESC,HE.iOrdre_Presentation DESC,E.dtDate_Chronologique DESC,E.dtDate_Evenement DESC'
                IF @vcCode_Structure_Tri = 'EDE' -- Événement/Date d'événement inversé
                    SET @vcSQL_OrderBy = 'ORDER BY E.iID_Convention,
                                                    CASE WHEN HE.vcCode_Regroupement = ''UNI'' THEN HE.iOrdre_Presentation ELSE 999999 END DESC,
                                                    E.vcCode_Evenement DESC,HE.iOrdre_Presentation DESC,E.dtDate_Evenement DESC,E.dtDate_Chronologique DESC'

                IF LEN(@vcSQL_OrderBy) > 0
                    SET @vcSQL_OrderBy = REPLACE(@vcSQL_OrderBy, 'E.dtDate_Chronologique DESC', 'E.dtDate_Chronologique DESC,E.iID_Transaction DESC')

                SET @vcSQL = @vcSQL + @vcSQL_OrderBy
                EXECUTE(@vcSQL)

                -- Niveau #3: Détails de l'événement
                SELECT DE.iID_Detail_Evenement,
                       DE.iID_Evenement_Historique,
                       DE.vcDescription_Detail,
                       DE.vcDescription_Detail AS vcDescription_Detail_InfoBulle,
                       DE.vcValeur,
                       DE.vcValeur AS vcValeur_InfoBulle,
                       DE.dtDate,
                       DE.vcReponse,
                       DE.vcReponse AS vcReponse_InfoBulle,
                       DE.mCredit_Base,
                       DE.mMajoration,
                       DE.mInterets,
                       NULL AS vcVide2
                FROM #tblIQEE_DetailsEvenement DE
                ORDER BY DE.iID_Evenement_Historique,CASE WHEN DE.vcNom_Table IS NULL THEN 1 ELSE 2 END,DE.dtDate DESC,DE.vcReponse
            END

    END TRY
    BEGIN CATCH
        -- Lever l'erreur et faire le rollback
        DECLARE @ErrorMessage NVARCHAR(max) = ERROR_MESSAGE() + char(13) + char(10) + ' (Proc: ' + ERROR_PROCEDURE() + ' - Line: ' + LTrim(Str(ERROR_LINE())) + ')',
                @ErrorSeverity INT = ERROR_SEVERITY(),
                @ErrorState INT  =ERROR_STATE(),
                @ErrorLine int = ERROR_LINE()

        RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState) WITH LOG;

        -- Retourner -1 en cas d'erreur non prévisible de traitement
        RETURN -1
    END CATCH

    -- Retourner 1 lors de la réussite du traitement
    RETURN 1
END