/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service :   psIQEE_DemanderAnnulations
Nom du service  :   Demander les annulations 
But             :   Demander les annulations qui se déterminent automatiquement et demander les annulations de conséquences
                    des annulations automatiques et manuelles.
Facette         :   IQÉÉ

Paramètres d’entrée :   Paramètre                   Description
                        --------------------------  -----------------------------------------------------------------
                        siAnnee_Fiscale_Debut       Année fiscale de début des fichiers de transactions à créer.
                        siAnnee_Fiscale_Fin         Année fiscale de fin des fichiers de transactions à créer.
                        vcCode_Simulation           Le code de simulation est au choix du programmeur.  Il permet d’associer
                                                    un code à un ou plusieurs fichiers de transactions.  
                                                    Si ce paramètre est présent, le fichier est automatiquement considéré
                                                    comme un fichier test et comme un fichier de simulation. Les fichiers
                                                    de test qui ne sont pas des simulations sont visibles aux utilisateurs.
                                                    Par contre, les fichiers de simulation ne sont pas visibles aux utilisateurs.
                                                    Ils sont accessibles seulement aux programmeurs.
                        iID_Convention              Identifiant unique de la convention pour laquelle la création des
                                                    fichiers est demandée.
                        iID_Utilisateur_Creation    Identifiant de l’utilisateur qui demande la création du fichier.
                        bPremier_Envoi_Originaux    Indicateur pour traiter seulement les transactions originales (pas les annulations)
                                                    dans le cas du premier envoi trimestriel de l'année.
                                                    
                        bTraiterAnnulations            Indicateur si la création du fichier doit traiter ou non les annulations
                            Manuelles                demandées manuellement.
                        bTraiterAnnulations            Indicateur si la création du fichier doit traiter ou non les annulations
                            Automatiques            déterminées automatiquement.
                        @iID_Session                Identifiant de session identifiant de façon unique la création des
                                                    fichiers de transactions
                        @dtDate_Creation_Fichiers    Date et heure de la création des fichiers identifiant de façon unique 
                                                    avec identifiant de session, la création des fichiers de transactions.
                        bFichiers_Test_Comme_        Indicateur si les fichiers test doivent être tenue en compte dans
                            Production                la production du fichier.  Normalement ce n’est pas le cas.  Mais
                                                    pour fins d’essais et de simulations il est possible de tenir compte
                                                    des fichiers tests comme des fichiers de production.
                        bit_CasSpecial                Indicateur pour permettre la résolution de cas spéciaux sur des T02 dont le délai de traitement est dépassé. 

Exemple d’appel :   Cette procédure doit être appelée uniquement par "psIQEE_CreerFichiers".
                    EXECUTE @iResultat = dbo.psIQEE_CreerFichiers 0, 2009, 2010, 0, NULL, NULL, NULL, 301084,
                                                    '\\gestas2\iqee$\Simulations\', NULL, NULL, 628022, 'stephane.barbeau@universitas.ca', NULL, NULL, NULL

Paramètres de sortie:   
        Table                       Champ                       Description
        -------------------------   ------------------------    ---------------------------------
        S/O

Historique des modifications:
        Date        Programmeur                     Description                                
        ----------  -----------------------------   -----------------------------------------
        2009-09-15  Éric Deshaies                   Création du service                
        2012-06-28  Eric Michaud                    Modification RIN sans ID            
        2012-11-07  Stéphane Barbeau                Désactivation des demandes des annulations de conséquence antérieures
        2012-11-19  Stéphane Barbeau                COTISATION_AJOUT_PASSE_02: Ajout de la condition AND F.siAnnee_Fiscale >= @siAnnee_Fiscale_Debut 
                                                                                                     AND F.siAnnee_Fiscale <= @siAnnee_Fiscale_Fin
        2012-11-20  Stéphane Barbeau                DATE_NAISSANCE_BENEFICIAIRE_02: Ajout de la condition AND F.siAnnee_Fiscale >= @siAnnee_Fiscale_Debut 
                                                                                                          AND F.siAnnee_Fiscale <= @siAnnee_Fiscale_Fin
        2012-11-20  Stéphane Barbeau                DATE_NAISSANCE_BENEFICIAIRE_02: Validation de la date de naissance faite seulement selon l'année.
        2012-11-26  Stéphane Barbeau                COTISATION_AJOUT_PASSE_02: Clause Where Exists retirée et remplacée par la comparaison avec la 
                                                    fonction fntIQEE_CalculerMontantsDemande
        2012-11-26  Stéphane Barbeau                Désactivation COTISATION_SUPPRESSION_02 et COTISATION_MODIFICATION_02 
        2012-12-19  Stéphane Barbeau                Annulations de conséquences: Condition restrictive de la table temporaire #tblIQEE_PlusAncienneTransactionConventions 
                                                    avec condition WHERE year(C.dtDate_Transaction_A_Annuler) >= @BorneInferieureAnneeFiscale
        2012-12-20  Stéphane Barbeau                DATE_DEBUT_CONTRAT_02: Nouvelles règles concernant la date de début de contrat.                                                                
        2013-09-13  Stéphane Barbeau                Ajout traitement raisons annulation BENEFICIAIRE_RESIDENT_QUEBEC_02 et BENEFICIAIRE_HORS_QUEBEC_02
                                                    Désactivation traitement 'ANNULATION_TRANSACTION_PASSE_02'
        2013-09-26  Stéphane Barbeau                Ajustement requête curseur DATE_NAISSANCE_BENEFICIAIRE_02
        2013-09-27  Stéphane Barbeau                Curseur curRaisonsAnnulation: Nouvelle requête pour garantir la présence de toutes les raisons d'annulation
                                                    actives des enregistrements de type 1.  Retrait de l'emploi de la fonction fntIQEE_RechercherRaisonsAnnulation.
                                                    DATE_NAISSANCE_BENEFICIAIRE_02: Désactivation de la validation de la règle des 16-17 ans.
        2013-10-11  Stéphane Barbeau                BENEFICIAIRE_RESIDENT_QUEBEC_02 et BENEFICIAIRE_HORS_QUEBEC_02; Curseurs: 
                                                    Emploi des fonctions fntGENE_ObtenirProvincePays et fnGENE_AdresseEnDate avec l'aide de CAST.
        2013-12-10  Stéphane Barbeau                Annulations manuelles: Arrêter de copier les annulations manuelles dont les raisons d'annulation sont désactivées.            
        2013-12-10  Stéphane Barbeau                DATE_NAISSANCE_BENEFICIAIRE_02 : Spécifier seulement Année comme déclencheur.
        2013-12-17  Stéphane Barbeau                Ajustement JOINTURE Copie Annulations manuelles: Arrêter de copier les annulations manuelles dont les raisons d'annulation sont désactivées.            
        2014-02-24  Stéphane Barbeau                Ajout nouveau paramètre @bPremier_Envoi_Originaux et nouvelle assignation @siAnnee_Fiscale_Fin
                                                    Raisons d'annulation: pour réduire le nombre des fichiers
                                                    Curseurs curSituations: Améliorations jointures avec tblIQEE_Fichiers pour parcourir seulement dans la table tblIQEE_Fichiers seulement les fichiers de réponse.
                                                    Ajout d'une condition pour traiter les annulations-reprises antérieures à 3 ans seulement.
        2014-07-09  Stéphane Barbeau                Toutes les raisons d'annulations: Exclure l'ajout d'annulations pour les conventions fermées.  Ajout du code validation 91 des T02.                                                                     
                                                    BENEFICIAIRE_HORS_QUEBEC_02 et BENEFICIAIRE_RESIDENT_QUEBEC_02 : Requêtes directes dans les tables tblGENE_Adresse et tblGENE_AdresseHistorique
        2014-07-30  Stéphane Barbeau                Appel fntIQEE_ObtenirProvincePays: Appel du paramètre cID_Pays à la place de vcPays                                                    
        2014-08-01  Stéphane Barbeau                BENEFICIAIRE_HORS_QUEBEC_02 et BENEFICIAIRE_RESIDENT_QUEBEC_02 : requêtes avec fntGENE_ObtenirAdresseEnDate
        2014-08-06  Stéphane Barbeau                Ajout du paramètre bit_CasSpecial pour permettre la résolution de cas spéciaux sur des T02 dont le délai de traitement est dépassé. 
        2014-09-19  Stéphane Barbeau                DATE_DEBUT_CONTRAT_02 et BENEFICIAIRE_HORS_QUEBEC_02 et BENEFICIAIRE_RESIDENT_QUEBEC_02: Restriction des Raisons d'annulation à l'intervalle de 3 ans.
        2014-10-28  Stéphane Barbeau                #tblIQEE_TransactionsConventions: Condition pour empêcher les annulations de conséquences antérieures à @siAnnee_Fiscale_Debut. 
        2014-11-25  Stéphane Barbeau                DATE_NAISSANCE_BENEFICIAIRE_02: Raffiner la requête selon le bénéficiaire courant.        
                                                    COTISATION_AJOUT_PASSE_02: Éviter de déclencher des reprises si des remboursements ont déjà eu lieu    par le biais de T02-2 et que le bénéficiaire était hors Québec.                                        
                                                    Nouvelle raison d'annulation: DATE_NAISSANCE_BENEFICIAIRE_02_T03
                                                    Ajustement requête raison d'annulation: DATE_NAISSANCE_BENEFICIAIRE_02 pour créer distinction avec DATE_NAISSANCE_BENEFICIAIRE_02_T03
        2016-05-04  Steeve Picard                   Renommage de la fonction «fnIQEE_ObtenirDateEnregistrementRQ» qui était auparavant «fnIQEE_ObtenirDateDebutRegime»
        2016-06-09  Steeve Picard                   Modification au niveau des paramètres de la fonction «dbo.fntIQEE_CalculerMontantsDemande»
        2016-06-15  Steeve Picard                   Optimisation des requêtes
        2017-07-10  Steeve Picard                   La table « #TB_ListeConvention » n'est plus créée dans « psIQEE_CreerFichiers »
        2017-08-17  Steeve Picard                   Modification pour l'utilisation du «@@RowCount»
        2018-02-08  Steeve Picard                   Déplacement de «siAnnee_Fiscale» de la table «tblIQEE_Fichiers» vers les tables d'évèments
        2018-11-13  Steeve Picard                   Déprécier jusqu'à nouvelle ordre
*********************************************************************************************************************/
CREATE PROCEDURE dbo.psIQEE_DemanderAnnulations (
    @siAnnee_Fiscale_Debut SMALLINT,
    @siAnnee_Fiscale_Fin SMALLINT,
    @bPremier_Envoi_Originaux BIT,
    @vcCode_Simulation VARCHAR(100),
--    @iID_Convention INT,
    @bTraiterAnnulationsManuelles BIT,
    @bTraiterAnnulationsAutomatiques BIT,
    @iID_Session INT,
    @dtDate_Creation_Fichiers DATETIME,
    @iID_Utilisateur_Creation INT,
    @bFichiers_Test_Comme_Production BIT,
    @bit_CasSpecial BIT
)
AS
BEGIN
    SET NoCount ON
    PRINT 'EXEC psIQEE_DemanderAnnulations'

    BEGIN
        PRINT '   *** Déclaration non-ignorés jusqu''à revision '
        RETURN
    END 

    IF Object_ID('tempDB..#TB_DemanderAnnulations_Conv') IS NOT NULL
        DROP TABLE #TB_DemanderAnnulations_Conv

    CREATE TABLE #TB_DemanderAnnulations_Conv (
            ConventionID INT NOT NULL,
            ConventionNo VARCHAR(15) NULL,
            ConventionStateID VARCHAR(5) NULL,
            SubscriberID INT NULL,
            BeneficiaryID INT NULL,
            EnAttenteRQ BIT NULL
        )

    INSERT INTO #TB_DemanderAnnulations_Conv (ConventionID, ConventionNo, ConventionStateID, SubscriberID, BeneficiaryID, EnAttenteRQ)
    SELECT C.ConventionID, C.ConventionNo, S.ConventionStateID, C.SubscriberID, C.BeneficiaryID,
            CASE WHEN RQ.iID_Convention IS NULL THEN 0 ELSE 1 END
        FROM dbo.Un_Convention C
            JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(NULL, NULL) S ON S.ConventionID = C.ConventionID
            LEFT JOIN dbo.fntIQEE_ToutesConventionsEnAttenteRQ(NULL, NULL) RQ ON RQ.iID_Convention = C.ConventionID
--        WHERE (@iID_Convention IS NULL OR C.ConventionID = @iID_Convention)

    -- La demande d'IQÉÉ doit être en vigueur, avoir reçu une réponse et faire partie de la
    -- et la convention ne doit pas être en attente de RQ
    DELETE FROM #TB_DemanderAnnulations_Conv
     WHERE ConventionStateID = 'FRM'
        OR EnAttenteRQ <> 0

    IF Object_ID('tempDB..#TB_DemanderAnnulations') IS NOT NULL
        DROP TABLE #TB_DemanderAnnulations

    CREATE TABLE #TB_DemanderAnnulations (
            iID_Enregistrement int NOT NULL,
            vcProvince varchar(50) NULL, 
            vcVille varchar(100) NULL,
            vcPays varchar(50) NULL,
            vcCodePostal varchar(10) NULL
        )

    DECLARE @BorneInferieureAnneeFiscale SMALLINT;
    DECLARE @BorneSuperieureAnneeFiscale SMALLINT;
    DECLARE @iCount int

    -- S'inspirer de psIQEE_CreerTransactions_02 pour l'intervalle de date de 3 ans
    IF @bit_CasSpecial = 0
        SET @BorneInferieureAnneeFiscale = CAST(dbo.fnGENE_ObtenirParametre('IQEE_CREER_FICHIERS_siAnnee_Fiscale_Debut', NULL, NULL, NULL, NULL, NULL, NULL) AS SMALLINT)
    ELSE
        SET @BorneInferieureAnneeFiscale = @siAnnee_Fiscale_Debut;

    SET @BorneSuperieureAnneeFiscale = CAST(dbo.fnGENE_ObtenirParametre('IQEE_CREER_FICHIERS_siAnnee_Fiscale_Fin', NULL, NULL, NULL, NULL, NULL, NULL) AS SMALLINT);

    PRINT '    Paramètres : '
    PRINT '        Annee_Fiscale : ' + Str(@BorneInferieureAnneeFiscale, 4) + ' à ' + Str( @BorneSuperieureAnneeFiscale, 4)
    PRINT '        Date_Creation_Fichiers : ' + Convert(varchar(20), @dtDate_Creation_Fichiers, 120)
    PRINT '        iID_Session : ' + LTrim(Str(@iID_Session, 4))

    IF @BorneSuperieureAnneeFiscale = @siAnnee_Fiscale_Fin
       -- Vérifier le nombre de fichiers associé à la borne supérieure (premier envoi)
       AND EXISTS( SELECT * FROM dbo.fntIQEE_RechercherFichiers(NULL, NULL, @BorneSuperieureAnneeFiscale, @BorneSuperieureAnneeFiscale, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL))
    BEGIN
       PRINT '    Annulations à traiter';

        -- On traite les annulations-reprises antérieures à 3 ans seulement
        IF @siAnnee_Fiscale_Debut < @BorneInferieureAnneeFiscale
            SET @siAnnee_Fiscale_Debut = @BorneInferieureAnneeFiscale;

        --IF @bPremier_Envoi_Originaux = 1  -- On a affaire au tout premier envoi de l'année fiscale qui vient de se terminer.  
        --                                  --  Intervalle ajusté pour ne pas parcourir inutilement cette année.
        --    SET @siAnnee_Fiscale_Fin = @BorneSuperieureAnneeFiscale -1

        DECLARE @iID_Type_Annulation INT, 
                @iID_Enregistrement INT, 
                @vcCodes_Categorie VARCHAR(200), 
                @dtDate_Action_Menant_Annulation DATETIME,
                @iID_Utilisateur_Action_Menant_Annulation INT,
                @iID_Suivi_Modification INT, 
                @bApplicable_Aux_Simulations BIT, 
                @iID_Raison_Annulation INT, 
                @vcCode_Raison VARCHAR(50), 
                @tiID_Type_Enregistrement TINYINT, 
                @iID_Sous_Type INT, 
                @iID_TMP INT, 
                @iID_Statut_Annulation INT, 
                @vcCode_Message VARCHAR(10), 
                @iID_Annulation INT;

        -- Déterminer l'identifiant du statut d'annulation "Associée à la création de fichiers de transactions"
        SELECT @iID_Statut_Annulation = SA.iID_Statut_Annulation
          FROM tblIQEE_StatutsAnnulation SA
         WHERE SA.vcCode_Statut = 'ASS';

        ----------------------------------------------------------------------------
        -- Demander les annulations pour les raisons d'annulation de type "Manuelle"
        ----------------------------------------------------------------------------
        IF @bTraiterAnnulationsManuelles = 1
        BEGIN
            PRINT '    Traiter Annulations Manuelles'

            IF Object_ID('tempDB..##tblIQEE_RapportCreation') IS NOT NULL
                INSERT INTO ##tblIQEE_RapportCreation( cSection, iSequence, vcMessage)
                     VALUES ('3', 10, '       ' + CONVERT(VARCHAR(25), GETDATE(), 121) 
                                                + ' - psIQEE_DemanderAnnulations             ' 
                                                + '- Demander annulations pour raisons d''annulation type "Manuelle"'
                            );

            -- Déterminer l'identifiant du type d'annulation manuel
            SELECT @iID_Type_Annulation = TA.iID_Type_Annulation
              FROM tblIQEE_TypesAnnulation TA
             WHERE TA.vcCode_Type = 'MAN';

            -- 02: Copier les demandes manuelles d'annulation sur les demandes de l'IQÉÉ pour la création des fichiers en cours
            INSERT INTO dbo.tblIQEE_Annulations (
                    tiID_Type_Enregistrement, iID_Enregistrement_Demande_Annulation, iID_Session, dtDate_Creation_Fichiers, 
                    vcCode_Simulation, dtDate_Demande_Annulation, iID_Utilisateur_Demande, iID_Type_Annulation, iID_Raison_Annulation, 
                    tCommentaires, iID_Statut_Annulation
                )
            SELECT A.tiID_Type_Enregistrement, A.iID_Enregistrement_Demande_Annulation, @iID_Session, @dtDate_Creation_Fichiers, 
                   @vcCode_Simulation, A.dtDate_Demande_Annulation, A.iID_Utilisateur_Demande, A.iID_Type_Annulation, A.iID_Raison_Annulation, 
                   A.tCommentaires, @iID_Statut_Annulation
              FROM tblIQEE_Annulations A -- Raisons d'annulation actives seulement
                   JOIN tblIQEE_RaisonsAnnulation RA ON RA.iID_Raison_Annulation = A.iID_Raison_Annulation
                                                    AND RA.bActif = 1 -- Transactions de demande d'IQÉÉ seulement
                   JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
                                                      AND TE.cCode_Type_Enregistrement = '02' -- La transaction d'origine de la demande d'annulation doit être valide et avoir reçu une réponse de RQ
                   JOIN tblIQEE_Demandes D ON D.iID_Demande_IQEE = A.iID_Enregistrement_Demande_Annulation
                                              -- pour la création d'un fichier pour une seule convention
                                          AND D.siAnnee_Fiscale <= @siAnnee_Fiscale_Fin
                                          AND D.tiCode_Version IN (0, 2)
                                          AND D.cStatut_Reponse = 'R'
                   JOIN #TB_DemanderAnnulations_Conv C ON C.ConventionID = D.iID_Convention
                   -- des fichiers de l'IQÉÉ admissibles
                   JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
                                          AND (@bFichiers_Test_Comme_Production = 1 OR F.bFichier_Test = 0) -- Tenir compte ou non des fichiers test
                                          AND F.bInd_Simulation = 0 -- Ne jamais tenir compte des fichiers de simulation
                   -- Uniquement les demandes d'annulation de type manuelles
             WHERE A.iID_Type_Annulation = @iID_Type_Annulation
                   -- 3 conditions suivantes indique qu'il s'agit d'une demande d'annulation manuelle pas encore appliquée
                   AND A.iID_Session IS NULL
                   AND A.dtDate_Creation_Fichiers IS NULL
                   AND A.vcCode_Simulation IS NULL;
            SET @iCount = @@ROWCOUNT
            PRINT '    ' + Str(@iCount, 6) + ' demandes(s) - T02'

            -- 03: Copier les demandes manuelles d'annulation sur les remplacements de bénéficiaire pour la création des fichiers
            --     en cours
            INSERT INTO dbo.tblIQEE_Annulations (
                    tiID_Type_Enregistrement, iID_Enregistrement_Demande_Annulation, iID_Session, dtDate_Creation_Fichiers, 
                    vcCode_Simulation, dtDate_Demande_Annulation, iID_Utilisateur_Demande, iID_Type_Annulation, iID_Raison_Annulation, 
                    tCommentaires, iID_Statut_Annulation
                )
            SELECT A.tiID_Type_Enregistrement, A.iID_Enregistrement_Demande_Annulation, @iID_Session, @dtDate_Creation_Fichiers, 
                   @vcCode_Simulation, A.dtDate_Demande_Annulation, A.iID_Utilisateur_Demande, A.iID_Type_Annulation, A.iID_Raison_Annulation, 
                   A.tCommentaires, @iID_Statut_Annulation
              FROM tblIQEE_Annulations A -- Transactions de remplacement de bénéficiaire seulement
                   JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
                                                      AND TE.cCode_Type_Enregistrement = '03' -- La transaction d'origine de la demande d'annulation doit être valide et avoir reçu une réponse de RQ
                   JOIN tblIQEE_RemplacementsBeneficiaire RB ON RB.iID_Remplacement_Beneficiaire = A.iID_Enregistrement_Demande_Annulation
                                                            AND RB.siAnnee_Fiscale <= @siAnnee_Fiscale_Fin
                                                                -- pour la création d'un fichier pour une seule convention
                                                            AND RB.tiCode_Version IN (0, 2)
                                                            AND RB.cStatut_Reponse = 'R'
                                                                -- et la convention ne doit pas être en attente de RQ
                   JOIN #TB_DemanderAnnulations_Conv C ON C.ConventionID = RB.iID_Convention
                   -- des fichiers de l'IQÉÉ admissibles
                   JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = RB.iID_Fichier_IQEE
                                          AND (@bFichiers_Test_Comme_Production = 1 OR F.bFichier_Test = 0) -- Tenir compte ou non des fichiers test
                                          AND F.bInd_Simulation = 0 -- Ne jamais tenir compte des fichiers de simulation
             -- Uniquement les demandes d'annulation de type manuelles
             WHERE A.iID_Type_Annulation = @iID_Type_Annulation
                   -- 3 conditions suivantes indique qu'il s'agit d'une demande d'annulation manuelle pas encore appliquée
               AND A.iID_Session IS NULL
               AND A.dtDate_Creation_Fichiers IS NULL
               AND A.vcCode_Simulation IS NULL;
            SET @iCount = @@ROWCOUNT
            PRINT '    ' + Str(@iCount, 6) + ' remplacement(s) bénéficiares - T03'

            -- 04: Copier les demandes manuelles d'annulation sur les transferts pour la création des fichiers en cours
            INSERT INTO dbo.tblIQEE_Annulations (
                    tiID_Type_Enregistrement, iID_Enregistrement_Demande_Annulation, iID_Session, dtDate_Creation_Fichiers, 
                    vcCode_Simulation, dtDate_Demande_Annulation, iID_Utilisateur_Demande, iID_Type_Annulation, iID_Raison_Annulation, 
                    tCommentaires, iID_Statut_Annulation
                )
            SELECT A.tiID_Type_Enregistrement, A.iID_Enregistrement_Demande_Annulation, @iID_Session, @dtDate_Creation_Fichiers, 
                   @vcCode_Simulation, A.dtDate_Demande_Annulation, A.iID_Utilisateur_Demande, A.iID_Type_Annulation, A.iID_Raison_Annulation, 
                   A.tCommentaires, @iID_Statut_Annulation
              FROM tblIQEE_Annulations A -- Transactions de transfert seulement
                   JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
                                                      AND TE.cCode_Type_Enregistrement = '04' -- La transaction d'origine de la demande d'annulation doit être valide et avoir reçu une réponse de RQ
                   JOIN tblIQEE_Transferts T ON T.iID_Transfert = A.iID_Enregistrement_Demande_Annulation
                                            AND T.siAnnee_Fiscale <= @siAnnee_Fiscale_Fin
                                                -- pour la création d'un fichier pour une seule convention
                                            AND T.tiCode_Version IN (0, 2)
                                            AND T.cStatut_Reponse = 'R'
                                                -- et la convention ne doit pas être en attente de RQ
                   JOIN #TB_DemanderAnnulations_Conv C ON C.ConventionID = T.iID_Convention
                   -- des fichiers de l'IQÉÉ admissibles
                   JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = T.iID_Fichier_IQEE
                                          AND (@bFichiers_Test_Comme_Production = 1 OR F.bFichier_Test = 0) -- Tenir compte ou non des fichiers test
                                          AND F.bInd_Simulation = 0 -- Ne jamais tenir compte des fichiers de simulation
             -- Uniquement les demandes d'annulation de type manuelles
             WHERE A.iID_Type_Annulation = @iID_Type_Annulation
                   -- 3 conditions suivantes indique qu'il s'agit d'une demande d'annulation manuelle pas encore appliquée
               AND A.iID_Session IS NULL
               AND A.dtDate_Creation_Fichiers IS NULL
               AND A.vcCode_Simulation IS NULL;
            SET @iCount = @@ROWCOUNT
            PRINT '    ' + Str(@iCount, 6) + ' transfert(s) - T04'

            -- 05: Copier les demandes manuelles d'annulation sur les paiements aux bénéficiaires pour la création des fichiers en cours
            INSERT INTO dbo.tblIQEE_Annulations (
                    tiID_Type_Enregistrement, iID_Enregistrement_Demande_Annulation, iID_Session, dtDate_Creation_Fichiers, 
                    vcCode_Simulation, dtDate_Demande_Annulation, iID_Utilisateur_Demande, iID_Type_Annulation, iID_Raison_Annulation, 
                    tCommentaires, iID_Statut_Annulation
                )
            SELECT A.tiID_Type_Enregistrement, A.iID_Enregistrement_Demande_Annulation, @iID_Session, @dtDate_Creation_Fichiers, 
                   @vcCode_Simulation, A.dtDate_Demande_Annulation, A.iID_Utilisateur_Demande, A.iID_Type_Annulation, A.iID_Raison_Annulation, 
                   A.tCommentaires, @iID_Statut_Annulation
              FROM tblIQEE_Annulations A -- Transactions de paiement au bénéficiaire seulement
                   JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
                                                      AND TE.cCode_Type_Enregistrement = '05' -- La transaction d'origine de la demande d'annulation doit être valide et avoir reçu une réponse de RQ
                   JOIN tblIQEE_PaiementsBeneficiaires PB ON PB.iID_Paiement_Beneficiaire = A.iID_Enregistrement_Demande_Annulation
                                                         AND PB.siAnnee_Fiscale <= @siAnnee_Fiscale_Fin
                                                             -- Sélection de la convention pour la création d'un fichier pour une seule convention
                                                         AND PB.tiCode_Version IN (0, 2)
                                                         AND PB.cStatut_Reponse = 'R'
                                                             -- et la convention ne doit pas être en attente de RQ
                   JOIN #TB_DemanderAnnulations_Conv C ON C.ConventionID = PB.iID_Convention
                   -- des fichiers de l'IQÉÉ admissibles
                   JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = PB.iID_Fichier_IQEE
                                          AND (@bFichiers_Test_Comme_Production = 1 OR F.bFichier_Test = 0) -- Tenir compte ou non des fichiers test
                                          AND F.bInd_Simulation = 0 -- Ne jamais tenir compte des fichiers de simulation
               -- Uniquement les demandes d'annulation de type manuelles
             WHERE A.iID_Type_Annulation = @iID_Type_Annulation
                   -- 3 conditions suivantes indique qu'il s'agit d'une demande d'annulation manuelle pas encore appliquée
               AND A.iID_Session IS NULL
               AND A.dtDate_Creation_Fichiers IS NULL
               AND A.vcCode_Simulation IS NULL;
            SET @iCount = @@ROWCOUNT
            PRINT '    ' + Str(@iCount, 6) + ' paiements(s) aux bénéficiares - T05'

            -- 06: Copier les demandes manuelles d'annulation sur les impôts spéciaux pour la création des fichiers en cours
            INSERT INTO dbo.tblIQEE_Annulations (
                    tiID_Type_Enregistrement, iID_Enregistrement_Demande_Annulation, iID_Session, dtDate_Creation_Fichiers, 
                    vcCode_Simulation, dtDate_Demande_Annulation, iID_Utilisateur_Demande, iID_Type_Annulation, iID_Raison_Annulation, 
                    tCommentaires, iID_Statut_Annulation
                )
            SELECT A.tiID_Type_Enregistrement, A.iID_Enregistrement_Demande_Annulation, @iID_Session, @dtDate_Creation_Fichiers, 
                   @vcCode_Simulation, A.dtDate_Demande_Annulation, A.iID_Utilisateur_Demande, A.iID_Type_Annulation, A.iID_Raison_Annulation, 
                   A.tCommentaires, @iID_Statut_Annulation
              FROM tblIQEE_Annulations A -- Transactions d'impôt spécial seulement
                   JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
                                                      AND TE.cCode_Type_Enregistrement = '06' -- La transaction d'origine de la demande d'annulation doit être valide et avoir reçu une réponse de RQ
                   JOIN tblIQEE_ImpotsSpeciaux TIS ON TIS.iID_Impot_Special = A.iID_Enregistrement_Demande_Annulation
                                                  AND TIS.siAnnee_Fiscale <= @siAnnee_Fiscale_Fin
                                                      -- Sélection de la convention pour la création d'un fichier pour une seule convention
                                                  AND TIS.tiCode_Version IN (0, 2)
                                                  AND TIS.cStatut_Reponse = 'R'
                                                      -- et la convention ne doit pas être en attente de RQ
                   JOIN #TB_DemanderAnnulations_Conv C ON C.ConventionID = TIS.iID_Convention
                   -- des fichiers de l'IQÉÉ admissibles
                   JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = TIS.iID_Fichier_IQEE
                                          AND (@bFichiers_Test_Comme_Production = 1 OR F.bFichier_Test = 0) -- Tenir compte ou non des fichiers test
                                          AND F.bInd_Simulation = 0 -- Ne jamais tenir compte des fichiers de simulation
             -- Uniquement les demandes d'annulation de type manuelles
             WHERE A.iID_Type_Annulation = @iID_Type_Annulation
                   -- 3 conditions suivantes indique qu'il s'agit d'une demande d'annulation manuelle pas encore appliquée
               AND A.iID_Session IS NULL
               AND A.dtDate_Creation_Fichiers IS NULL
               AND A.vcCode_Simulation IS NULL;
            SET @iCount = @@ROWCOUNT
            PRINT '    ' + Str(@iCount, 6) + ' impôt(s) spécials - T06'

        END;  -- IF @bTraiterAnnulationsManuelles = 1

        -------------------------------------------------------------------------------
        -- Demander les annulations pour les raisons d'annulation de type "Automatique"
        -------------------------------------------------------------------------------
        IF @bTraiterAnnulationsAutomatiques = 1
        BEGIN
            DECLARE @siAnnee_Fiscale int
            DECLARE @curSituationSize INT;
            DECLARE @iCounter int

            DECLARE @iID_Fichier int,
                    @iID_ConventionCurrent int,
                    @dtDebutCotisation date,
                    @dtFinCotisation date,
                    @dtDate_Debut_Convention date,
                    @mTotal_Cotisations_Subventionnables money

            DECLARE @iID_Beneficiaire int,
                    @vcProvince VARCHAR(75), 
                    @vcVille VARCHAR(100), 
                    @vcPays CHAR(4), 
                    @vcCodePostal VARCHAR(10);

            DECLARE @vcCodes_Cotisation varchar(200),
                    @vcCodes_TransfertIN VARCHAR(200)

            IF Object_ID('tempDB..##tblIQEE_RapportCreation') IS NOT NULL
                INSERT INTO ##tblIQEE_RapportCreation (cSection, iSequence, vcMessage)
                        VALUES ('3', 10, '       ' + CONVERT(VARCHAR(25), GETDATE(), 121)
                                                + ' - psIQEE_DemanderAnnulations             '
                                                + '- Demander annulations pour raisons d''annulation type "Automatique"'
                            );

            -- Déterminer l'identifiant du type d'annulation automatique
            SELECT @iID_Type_Annulation = TA.iID_Type_Annulation
                FROM tblIQEE_TypesAnnulation TA
                WHERE TA.vcCode_Type = 'AUT';

            PRINT '    Traiter Annulations Automatiques'

            -- Rechercher les raisons d'annulation automatiques
            IF @vcCode_Simulation IS NULL
                SET @bApplicable_Aux_Simulations = NULL;
            ELSE
                SET @bApplicable_Aux_Simulations = 1;

            DECLARE curRaisonsAnnulation CURSOR LOCAL FAST_FORWARD
                FOR SELECT RA.iID_Raison_Annulation, RA.vcCode_Raison, RA.tiID_Type_Enregistrement, RA.iID_Sous_Type
                        FROM tblIQEE_RaisonsAnnulation RA
                            JOIN tblIQEE_TypesAnnulation TA ON TA.iID_Type_Annulation = RA.iID_Type_Annulation
                        WHERE RA.bActif = 1
                        AND RA.tiID_Type_Enregistrement = 1    -- 2013-09-27 SB: Condition Temporaire, il faudra inclure les autres types lorsque le moment sera venu.
                        ORDER BY RA.iOrdre_Presentation;
                                
            --SELECT RA.iID_Raison_Annulation, RA.vcCode_Raison, RA.tiID_Type_Enregistrement, RA.iID_Sous_Type
            --  FROM dbo.fntIQEE_RechercherRaisonsAnnulation(NULL, NULL, NULL, 1, NULL, 'AUT', NULL, NULL, NULL, @bApplicable_Aux_Simulations) RA
            --SELECT RA.iID_Raison_Annulation, RA.vcCode_Raison, RA.tiID_Type_Enregistrement, RA.iID_Sous_Type
            --  FROM dbo.fntIQEE_RechercherRaisonsAnnulation(NULL, NULL, NULL, 1, NULL, 'AUT', NULL, NULL, NULL, NULL) RA
            -- Réponses:
            --      COTISATION_SUPPRESSION_02
            --      COTISATION_AJOUT_PASSE_02
            --      COTISATION_MODIFICATION_02
            --      DATE_NAISSANCE_BENEFICIAIRE_02

            -- Boucler les raisons d'annulation automatiques
            OPEN curRaisonsAnnulation;
            FETCH NEXT FROM curRaisonsAnnulation INTO @iID_Raison_Annulation, @vcCode_Raison, @tiID_Type_Enregistrement, @iID_Sous_Type;
            WHILE @@FETCH_STATUS = 0
            BEGIN
                PRINT '        Raison = ' + @vcCode_Raison

                SET @curSituationSize = 0;
                truncate table #TB_DemanderAnnulations

                -- Suppressions de cotisations
                IF @vcCode_Raison = 'COTISATION_SUPPRESSION_02'
                BEGIN
                    PRINT '    Raison = COTISATION_SUPPRESSION_02 - Skipped'
                --    -- Rechercher les cas de la situation du changement
                --    DECLARE curSituation CURSOR LOCAL FAST_FORWARD 
                --        FOR SELECT DISTINCT D.iID_Demande_IQEE
                --              FROM tblIQEE_TransactionsDemande TD
                --                   -- La demande d'IQÉÉ doit être en vigueur, avoir reçu une réponse et faire partie de la
                --                   -- sélection d'une convention en particulier s'il y a lieu
                --                   JOIN tblIQEE_Demandes D ON D.iID_Demande_IQEE = TD.iID_Demande_IQEE
                --                                          AND D.siAnnee_Fiscale <= @siAnnee_Fiscale_Fin
                --                                          AND D.tiCode_Version IN (0,2)
                --                                          AND D.cStatut_Reponse = 'R'
                --                                              -- et la convention ne doit pas être en attente de RQ
                --                     JOIN #TB_DemanderAnnulations_Conv C ON C.ConventionID = D.iID_Convention
                --                   -- La transaction modifiée doit faire partie des années fiscales demandées par l'utilisateur
                --                   -- et faire partie des fichiers de l'IQÉÉ admissibles
                --                   JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
                --                                          AND (@bFichiers_Test_Comme_Production = 1 OR F.bFichier_Test = 0) -- Tenir compte ou non des fichiers test
                --                                          AND F.bInd_Simulation = 0 -- Ne jamais tenir compte des fichiers de simulation
                --                   -- Rechercher la cotisation
                --                   LEFT JOIN Un_Cotisation C ON C.CotisationID = TD.iID_Transaction
                --             WHERE C.CotisationID IS NULL -- La cotisation doit être supprimée

                --    SET @curSituationSize = 0
                        
                --    -- Demander l'annulation
                --    OPEN curSituation
                --    FETCH NEXT FROM curSituation INTO @iID_Enregistrement
                --    WHILE @@FETCH_STATUS = 0
                --    BEGIN
                --        SELECT '@vcCode_Raison = COTISATION_SUPPRESSION_02'

                --        SET @curSituationSize = @curSituationSize + 1

                --        --EXECUTE dbo.psIQEE_AjouterDemandeAnnulation @tiID_Type_Enregistrement, @iID_Enregistrement,
                --        --                                            @iID_Session, @dtDate_Creation_Fichiers,
                --        --                                            @vcCode_Simulation, @iID_Utilisateur_Creation,
                --        --                                            @iID_Type_Annulation, @iID_Raison_Annulation,
                --        --                                            NULL, NULL, NULL, NULL, @vcCode_Message OUTPUT,
                --        --                                            @iID_Annulation OUTPUT

                --        FETCH NEXT FROM curSituation INTO @iID_Enregistrement
                --    END

                --    --SELECT @curSituationSize as '@curSituationSize Raison = COTISATION_SUPPRESSION_02'
                --    CLOSE curSituation
                --    DEALLOCATE curSituation                            
                END
                
                -- Ajout de cotisations où la date d'effectivité est dans le passé
                IF @vcCode_Raison = 'COTISATION_AJOUT_PASSE_02'
                BEGIN

                    -- Rechercher les cas de la situation du changement
                    SET @vcCodes_Cotisation = dbo.fnOPER_ObtenirTypesOperationCategorie('IQEE-DEMANDE-COTISATION');
                    SET @vcCodes_TransfertIN = dbo.fnOPER_ObtenirTypesOperationCategorie('IQEE_CALCUL_MONTANTS_DEMANDE_TRANSFERT_IN')

                    SET @siAnnee_Fiscale = @siAnnee_Fiscale_Debut
                    WHILE @siAnnee_Fiscale <= @siAnnee_Fiscale_Fin
                    BEGIN
                        TRUNCATE TABLE #TB_DemanderAnnulations

                        SELECT @dtDebutCotisation = P.dtDate_Debut_Cotisation, 
                               @dtFinCotisation = P.dtDate_Fin_Cotisation
                        FROM dbo.tblIQEE_Parametres P
                        WHERE P.siAnnee_Fiscale = @siAnnee_Fiscale

                        INSERT INTO #TB_DemanderAnnulations (iID_Enregistrement)
                        SELECT DISTINCT iID_Demande_IQEE
                        --FROM (
                        --        SELECT D.iID_Demande_IQEE, D.iID_Convention, D.iID_Fichier_IQEE, D.mTotal_Cotisations_Subventionnables
                                FROM tblIQEE_Demandes D -- La transaction modifiée doit faire partie des années fiscales demandées par l'utilisateur
                                    JOIN #TB_DemanderAnnulations_Conv C ON C.ConventionID = D.iID_Convention
                                    -- et faire partie des fichiers de l'IQÉÉ admissibles
                                    JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
                                                            AND tiID_Type_Fichier = 1
                                                                --10: Réponses et erreurs reçues
                                                                --11: Réponses incomplètes
                                                                --14: Réponses reçues
                                                            AND tiID_Statut_Fichier IN (10, 11, 14)
                                                            AND (@bFichiers_Test_Comme_Production = 1 OR F.bFichier_Test = 0) -- Tenir compte ou non des fichiers test
                                                            AND F.bInd_Simulation = 0 -- Ne jamais tenir compte des fichiers de simulation
                                    -- Rechercher les paramètres de l'IQÉÉ applicable au moment de la création de la transaction modifiée
                                    JOIN ( SELECT DISTINCT U.ConventionID, Year(Ct.EffectDate) as EffectYear
                                             FROM dbo.Un_Oper O
                                                  JOIN dbo.Un_Cotisation Ct ON Ct.OperID = O.OperID
                                                  JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
                                            WHERE Year(Ct.EffectDate) = @siAnnee_Fiscale
                                              and Year(O.dtSequence_Operation) > @siAnnee_Fiscale
                                         ) O ON O.ConventionID = D.iID_Convention
                                -- sélection d'une convention en particulier s'il y a lieu
                                WHERE D.siAnnee_Fiscale = @siAnnee_Fiscale
                                  AND D.tiCode_Version IN (0, 2)
                                  AND D.cStatut_Reponse = 'R'
                                      -- Il existe une cotisation admissible au calcul de l'IQÉÉ qui n'a pas été pris en compte dans la transaction d'origine
                                      -- Éviter de déclencher des reprises si des remboursements ont déjà eu lieu    par le biais de T02-2                                        
                                  AND NOT EXISTS (
                                        SELECT *
                                            FROM tblIQEE_Demandes D1
                                                JOIN tblIQEE_Fichiers F1 ON F1.iID_Fichier_IQEE = D1.iID_Fichier_IQEE
                                                                        AND F1.tiID_Type_Fichier = 1
                                                                            --10: Réponses et erreurs reçues
                                                                            --11: Réponses incomplètes
                                                                            --14: Réponses reçues
                                                                        AND F1.tiID_Statut_Fichier IN (10, 11, 14)
                                                                        AND (@bFichiers_Test_Comme_Production = 1 OR F1.bFichier_Test = 0) -- Tenir compte ou non des fichiers test
                                                                        AND F1.bInd_Simulation = 0 -- Ne jamais tenir compte des fichiers de simulation
                                            WHERE D1.iID_Convention = D.iID_Convention
                                            AND D1.siAnnee_Fiscale = @siAnnee_Fiscale
                                            AND D1.tiCode_Version = 2
                                            AND D1.cStatut_Reponse = 'R'
                                            AND D1.mTotal_Cotisations_Subventionnables = 0
                                            AND D1.vcProvince_Beneficiaire <> 'QC'
                                    )
                                ----  2012-11-26 - SB Code Désactivé car retourne toujours vrai                        
                                --AND EXISTS (
                                --         SELECT *
                                --           FROM dbo.Un_Unit U
                                --                -- Trouver les cotisations dans la période admissible selon les paramètres de l'IQÉÉ
                                --                JOIN Un_Cotisation C ON C.UnitID = U.UnitID
                                --                                    AND C.EffectDate BETWEEN P.dtDate_Debut_Cotisation AND P.dtDate_Fin_Cotisation
                                --                -- La cotisation doit être admissible au calcul de l'IQÉÉ
                                --                JOIN Un_Oper O ON O.OperID = C.OperID
                                --                              AND CHARINDEX(','+O.OperTypeID+',',@vcCodes_Categorie) = 0
                                --                -- Sélection de toutes les unités de la convention
                                --                LEFT JOIN Un_IntReimb IR ON IR.UnitID = U.UnitID
                                --          WHERE (U.ConventionID = D.iID_Convention and O.OperTypeID <> 'RIN') 
                                --             OR (U.ConventionID = D.iID_Convention and O.OperTypeID = 'RIN' and IR.CollegeID IS null )
                                --                -- La cotisation n'a pas été pris en compte dans la transaction d'origine
                                --            AND NOT EXISTS (
                                --                     SELECT *
                                --                       FROM tblIQEE_TransactionsDemande TD
                                --                      WHERE TD.iID_Demande_IQEE = D.iID_Demande_IQEE
                                --                        AND TD.iID_Transaction = C.CotisationID
                                --                )
                                --    )
                        --    ) X
                        --WHERE X.mTotal_Cotisations_Subventionnables <> (
                        --            SELECT mTotal_Cotisations_Subventionnables
                        --              FROM fntIQEE_CalculerMontantsDemande(iID_Convention, @dtDebutCotisation, @dtFinCotisation, DEFAULT)
                        --      )
                        SET @iCount = @@ROWCOUNT
                        PRINT '            ' + LTrim(Str(@iCount)) + ' à traité(s) pour ' + Str(@siAnnee_Fiscale,4)

                        --DELETE FROM TB 
                        --  FROM #TB_DemanderAnnulations TB
                        --       JOIN dbo.tblIQEE_Demandes D ON D.iID_Demande_IQEE = TB.iID_Enregistrement
                        -- WHERE D.mTotal_Cotisations_Subventionnables = (
                        --        SELECT mTotal_Cotisations_Subventionnables
                        --          FROM fntIQEE_CalculerMontantsDemande(D.iID_Convention, @dtDebutCotisation, @dtFinCotisation, DEFAULT)
                        --       )
                        --PRINT '            ' + LTrim(Str(@@RowCount)) + ' à skippé(s) pour ' + Str(@siAnnee_Fiscale,4)

                        -- Demander l'annulation
                        SET @iID_Enregistrement = 0
                        SET @iCounter = 0
                        WHILE EXISTS(SELECT TOP 1 * FROM #TB_DemanderAnnulations WHERE iID_Enregistrement > @iID_Enregistrement)
                        BEGIN
                            SELECT @iID_Enregistrement = Min(iID_Enregistrement)
                              FROM #TB_DemanderAnnulations
                             WHERE iID_Enregistrement > @iID_Enregistrement

                            SELECT @iID_ConventionCurrent = D.iID_Convention, 
                                   @iID_Fichier = D.iID_Fichier_IQEE, 
                                   @mTotal_Cotisations_Subventionnables = D.mTotal_Cotisations_Subventionnables
                              FROM dbo.tblIQEE_Demandes D
                             WHERE iID_Demande_IQEE = @iID_Enregistrement

                            IF EXISTS(SELECT mTotal_Cotisations_Subventionnables
                                        FROM fntIQEE_CalculerMontantsDemande(@iID_ConventionCurrent, @dtDebutCotisation, @dtFinCotisation, NULL)
                                       WHERE mTotal_Cotisations_Subventionnables <> @mTotal_Cotisations_Subventionnables
                               )
                            BEGIN

                                -- Déterminer qui a fait la dernière action menant à l'annulation
                                SELECT @dtDate_Action_Menant_Annulation = NULL,
                                        @iID_Utilisateur_Action_Menant_Annulation = NULL,
                                        @iID_Suivi_Modification = NULL;

                                SELECT TOP 1 @dtDate_Action_Menant_Annulation = SM.dtDate_Modification, 
                                                @iID_Utilisateur_Action_Menant_Annulation = SM.iID_Utilisateur_Modification, 
                                                @iID_Suivi_Modification = SM.iID_Suivi_Modification
                                  FROM tblIQEE_Demandes D
                                       JOIN dbo.Un_Unit U ON U.ConventionID = D.iID_Convention
                                       JOIN Un_Cotisation C ON C.UnitID = U.UnitID
                                                           AND C.EffectDate BETWEEN @dtDebutCotisation AND @dtFinCotisation
                                       JOIN Un_Oper O ON O.OperID = C.OperID
                                                     AND CHARINDEX(','+O.OperTypeID+',', @vcCodes_Categorie) = 0
                                       JOIN tblGENE_SuiviModifications SM ON SM.iCode_Table = 2
                                                                         AND SM.iID_Enregistrement = C.CotisationID
                                       JOIN CRQ_LogAction LA ON LA.LogActionID = SM.iID_Action
                                 WHERE D.iID_Demande_IQEE = @iID_Enregistrement
                                 ORDER BY LA.LogActionShortName DESC, SM.dtDate_Modification DESC;

                                EXECUTE dbo.psIQEE_AjouterDemandeAnnulation @tiID_Type_Enregistrement, @iID_Enregistrement, @iID_Session, @dtDate_Creation_Fichiers, 
                                                                            @vcCode_Simulation, @iID_Utilisateur_Creation, @iID_Type_Annulation, @iID_Raison_Annulation, NULL, 
                                                                            @dtDate_Action_Menant_Annulation, @iID_Utilisateur_Action_Menant_Annulation, @iID_Suivi_Modification, 
                                                                            @vcCode_Message OUTPUT, @iID_Annulation OUTPUT;
                                SET @curSituationSize += 1
                            END

                            SET @iCounter += 1;
                            IF @iCounter % 1000 = 0
                                PRINT '            ' + LTrim(Str(@iCounter)) + ' de complété(s)'
                        END;
                    
                        SET @siAnnee_Fiscale += 1
                    END
                END;

                -- Modification de cotisations
                IF @vcCode_Raison = 'COTISATION_MODIFICATION_02'
                BEGIN
                    PRINT '    Raison = COTISATION_MODIFICATION_02 - Skipped'

                --        -- Rechercher les cas de la situation du changement
                --        DECLARE curSituation CURSOR LOCAL FAST_FORWARD 
                --            FOR SELECT DISTINCT D.iID_Demande_IQEE
                --                  FROM tblIQEE_Demandes D  
                --                         JOIN #TB_DemanderAnnulations_Conv C ON C.ConventionID = D.iID_Convention
                --                       -- La transaction modifiée doit faire partie des années fiscales demandées par l'utilisateur
                --                       -- et faire partie des fichiers de l'IQÉÉ admissibles
                --                       JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
                --                                              AND (@bFichiers_Test_Comme_Production = 1 OR F.bFichier_Test = 0) -- Tenir compte ou non des fichiers test
                --                                              AND F.bInd_Simulation = 0 -- Ne jamais tenir compte des fichiers de simulation
                --                        -- Trouver les cotisations de la transaction de demande modifiée
                --                        JOIN tblIQEE_TransactionsDemande TD ON TD.iID_Demande_IQEE = D.iID_Demande_IQEE
                --                        -- La transaction de cotisation doit avoir été modifiée après la création de la transaction modifiée
                --                        JOIN tblGENE_SuiviModifications SM ON SM.iCode_Table = 2
                --                                                          AND SM.iID_Enregistrement = TD.iID_Transaction
                --                                                          AND SM.dtDate_Modification > F.dtDate_Creation
                --                        -- La transaction de cotisation doit avoir été modifiée
                --                        JOIN CRQ_LogAction LA ON LA.LogActionID = SM.iID_Action
                --                                             AND LA.LogActionShortName = 'U'
                --                        -- La demande d'IQÉÉ doit être en vigueur, avoir reçu une réponse et faire partie de la sélection d'une convention en particulier s'il y a lieu
                --                  WHERE D.tiCode_Version IN (0,2)
                --                    AND D.cStatut_Reponse = 'R'
                --                    AND D.siAnnee_Fiscale <= @siAnnee_Fiscale_Fin

                --        -- Demander l'annulation
                --        SET @curSituationSize = 0
                        
                --        OPEN curSituation
                --        FETCH NEXT FROM curSituation INTO @iID_Enregistrement
                --        WHILE @@FETCH_STATUS = 0
                --        BEGIN
                --            SET @curSituationSize = @curSituationSize  + 1

                --            -- Déterminer qui a fait la dernière modification menant à l'annulation
                --            SELECT TOP 1 @dtDate_Action_Menant_Annulation = SM.dtDate_Modification,
                --                         @iID_Utilisateur_Action_Menant_Annulation = SM.iID_Utilisateur_Modification,
                --                         @iID_Suivi_Modification = SM.iID_Suivi_Modification
                --              FROM tblIQEE_Demandes D 
                --                   JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
                --                   JOIN tblIQEE_TransactionsDemande TD ON TD.iID_Demande_IQEE = D.iID_Demande_IQEE
                --                   JOIN tblGENE_SuiviModifications SM ON SM.iCode_Table = 2
                --                                                     AND SM.iID_Enregistrement = TD.iID_Transaction
                --                                                     AND SM.dtDate_Modification > F.dtDate_Creation
                --                   JOIN CRQ_LogAction LA ON LA.LogActionID = SM.iID_Action
                --                                        AND LA.LogActionShortName = 'U'
                --             WHERE D.iID_Demande_IQEE = @iID_Enregistrement
                --             ORDER BY SM.dtDate_Modification DESC

                --            SELECT '@vcCode_Raison = COTISATION_MODIFICATION_02'

                --            --EXECUTE dbo.psIQEE_AjouterDemandeAnnulation @tiID_Type_Enregistrement, @iID_Enregistrement, @iID_Session, @dtDate_Creation_Fichiers,
                --            --                                            @vcCode_Simulation, @iID_Utilisateur_Creation, @iID_Type_Annulation, @iID_Raison_Annulation,
                --            --                                            NULL, @dtDate_Action_Menant_Annulation, @iID_Utilisateur_Action_Menant_Annulation, @iID_Suivi_Modification,
                --            --                                            @vcCode_Message OUTPUT, @iID_Annulation OUTPUT

                --            FETCH NEXT FROM curSituation INTO @iID_Enregistrement
                --        END

                --    CLOSE curSituation
                --    DEALLOCATE curSituation                            
                --    --SELECT @curSituationSize as '@curSituationSize Raison = COTISATION_MODIFICATION_02'
                END

                -- Modification de la date de naissance du bénéficiaire d'origine
                IF @vcCode_Raison = 'DATE_NAISSANCE_BENEFICIAIRE_02'
                BEGIN
                    SET @siAnnee_Fiscale = @siAnnee_Fiscale_Debut
                    WHILE @siAnnee_Fiscale <= @siAnnee_Fiscale_Fin
                    BEGIN
                        TRUNCATE TABLE #TB_DemanderAnnulations

                        -- Rechercher les cas de la situation du changement
                        INSERT INTO #TB_DemanderAnnulations (iID_Enregistrement)
                        SELECT DISTINCT D.iID_Demande_IQEE
                        FROM tblIQEE_Demandes D -- La transaction modifiée doit faire partie des années fiscales demandées par l'utilisateur et faire partie des fichiers de l'IQÉÉ admissibles
                            JOIN #TB_DemanderAnnulations_Conv C ON C.ConventionID = D.iID_Convention 
                                                                -- Tenir compte des demandes seulement concernées avec le bénéficiaire courant (pour éviter les T03)
                                                               And C.BeneficiaryID = D.iID_Beneficiaire_31Decembre
                            JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
                                                    AND tiID_Type_Fichier = 1
                                                        --10: Réponses et erreurs reçues
                                                        --11: Réponses incomplètes
                                                        --14: Réponses reçues
                                                    AND tiID_Statut_Fichier IN (10, 11, 14)
                                                    AND (@bFichiers_Test_Comme_Production = 1 OR F.bFichier_Test = 0) -- Tenir compte ou non des fichiers test
                                                    AND F.bInd_Simulation = 0 -- Ne jamais tenir compte des fichiers de simulation
                            -- La date du bénéficiaire de la transaction modifiée doit avoir changée depuis la transaction
                            JOIN dbo.Mo_Human H ON H.HumanID = D.iID_Beneficiaire_31Decembre
                                                    -- Présume que la disparition de la date, n'est pas un changement de date
                                                AND YEAR(ISNULL(H.BirthDate, D.dtDate_Naissance_Beneficiaire)) <> YEAR(D.dtDate_Naissance_Beneficiaire)
                                                    -- Revérifier la règle des 16-17 ans
                                                --AND NOT (dbo.fn_Mo_Age(H.BirthDate,CAST(CAST(D.siAnnee_Fiscale as VARCHAR(4)) + '-12-31' AS DATETIME)) >= 16)
                            LEFT JOIN (
                                SELECT iID_Remplacement_Beneficiaire, iID_Convention, iID_Nouveau_Beneficiaire
                                  FROM dbo.tblIQEE_RemplacementsBeneficiaire RB
                                       JOIN dbo.tblIQEE_Fichiers FRB ON FRB.iID_Fichier_IQEE = RB.iID_Fichier_IQEE 
                                 --WHERE RB.siAnnee_Fiscale BETWEEN @siAnnee_Fiscale_Debut AND @siAnnee_Fiscale_Fin
                                ) RB ON RB.iID_Convention = D.iID_Convention 
                                    And RB.iID_Nouveau_Beneficiaire = D.iID_Beneficiaire_31Decembre
                                                          
                        -- La demande d'IQÉÉ doit être en vigueur, avoir reçu une réponse et faire partie de la sélection d'une convention en particulier s'il y a lieu
                        WHERE D.siAnnee_Fiscale = @siAnnee_Fiscale
                          AND D.tiCode_Version IN (0, 2)
                          AND D.cStatut_Reponse = 'R'
                          AND RB.iID_Remplacement_Beneficiaire IS NULL
                        SET @iCount = @@ROWCOUNT
                        PRINT '            ' + LTrim(Str(@iCount)) + ' à traité(s) pour ' + Str(@siAnnee_Fiscale,4)

                        -- Demander l'annulation
                        SET @iID_Enregistrement = 0
                        SET @iCounter = 0
                        WHILE EXISTS(SELECT TOP 1 * FROM #TB_DemanderAnnulations WHERE iID_Enregistrement > @iID_Enregistrement)
                        BEGIN
                            SELECT @iID_Enregistrement = Min(iID_Enregistrement)
                              FROM #TB_DemanderAnnulations
                             WHERE iID_Enregistrement > @iID_Enregistrement

                            -- Déterminer qui a fait la dernière modification menant à l'annulation
                            SELECT @dtDate_Action_Menant_Annulation = NULL,
                                   @iID_Utilisateur_Action_Menant_Annulation = NULL,
                                   @iID_Suivi_Modification = NULL;

                            SELECT TOP 1 @dtDate_Action_Menant_Annulation = SM.dtDate_Modification,
                                         @iID_Utilisateur_Action_Menant_Annulation = SM.iID_Utilisateur_Modification, 
                                         @iID_Suivi_Modification = SM.iID_Suivi_Modification
                            FROM tblIQEE_Demandes D
                                JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
                                JOIN dbo.Mo_Human H ON H.HumanID = D.iID_Beneficiaire_31Decembre
                                JOIN tblGENE_SuiviModifications SM ON SM.iCode_Table = 7
                                                                    AND SM.iID_Enregistrement = H.HumanID
                                                                    AND SM.dtDate_Modification > F.dtDate_Creation
                                JOIN CRQ_LogAction LA ON LA.LogActionID = SM.iID_Action
                                                    AND LA.LogActionShortName = 'U'
                            WHERE D.iID_Demande_IQEE = @iID_Enregistrement
                            ORDER BY SM.dtDate_Modification DESC;

                            EXECUTE dbo.psIQEE_AjouterDemandeAnnulation @tiID_Type_Enregistrement, @iID_Enregistrement, @iID_Session, @dtDate_Creation_Fichiers,
                                                                        @vcCode_Simulation, @iID_Utilisateur_Creation, @iID_Type_Annulation, @iID_Raison_Annulation, 
                                                                        NULL, @dtDate_Action_Menant_Annulation, @iID_Utilisateur_Action_Menant_Annulation, @iID_Suivi_Modification, 
                                                                        @vcCode_Message OUTPUT, @iID_Annulation OUTPUT;
                            SET @curSituationSize += 1

                            SET @iCounter += 1;
                            IF @iCounter % 1000 = 0
                                PRINT '            ' + LTrim(Str(@iCounter)) + ' de complété(s)'
                        END;
                    
                        SET @siAnnee_Fiscale += 1
                    END;
                END;

                -- Modification de la date de naissance du bénéficiaire issu d'une T03 (Remplacement de bénéficiaire)
                IF @vcCode_Raison = 'DATE_NAISSANCE_BENEFICIAIRE_02_T03'
                BEGIN
                    SET @siAnnee_Fiscale = @siAnnee_Fiscale_Debut
                    WHILE @siAnnee_Fiscale <= @siAnnee_Fiscale_Fin
                    BEGIN
                        TRUNCATE TABLE #TB_DemanderAnnulations

                        -- Rechercher les cas de la situation du changement
                        INSERT INTO #TB_DemanderAnnulations (iID_Enregistrement)
                        SELECT DISTINCT D.iID_Demande_IQEE
                        FROM tblIQEE_Demandes D -- La transaction modifiée doit faire partie des années fiscales demandées par l'utilisateur
                            JOIN #TB_DemanderAnnulations_Conv C ON C.ConventionID = D.iID_Convention
                                                                -- Tenir compte des demandes seulement concernées avec le bénéficiaire courant (pour éviter les T03)
                                                               And C.BeneficiaryID = D.iID_Beneficiaire_31Decembre
                            -- et faire partie des fichiers de l'IQÉÉ admissibles
                            JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
                                                    AND tiID_Type_Fichier = 1
                                                        --10: Réponses et erreurs reçues
                                                        --11: Réponses incomplètes
                                                        --14: Réponses reçues
                                                    AND tiID_Statut_Fichier IN (10, 11, 14)
                                                    AND (@bFichiers_Test_Comme_Production = 1 OR F.bFichier_Test = 0) -- Tenir compte ou non des fichiers test
                                                    AND F.bInd_Simulation = 0 -- Ne jamais tenir compte des fichiers de simulation
                            -- La date du bénéficiaire de la transaction modifiée doit avoir changée depuis la transaction
                            JOIN dbo.Mo_Human H ON H.HumanID = D.iID_Beneficiaire_31Decembre
                                                    -- Présume que la disparition de la date, n'est pas un changement de date
                                                AND YEAR(ISNULL(H.BirthDate, D.dtDate_Naissance_Beneficiaire)) <> YEAR(D.dtDate_Naissance_Beneficiaire)
                                                --AND NOT (
                                                --    --Revérifier la règle des 16-17 ans
                                                --        dbo.fn_Mo_Age(H.BirthDate,CAST(CAST(D.siAnnee_Fiscale as VARCHAR(4)) + '-12-31' AS DATETIME)) >= 16 
                                                --    )
                            JOIN (
                                SELECT iID_Remplacement_Beneficiaire, iID_Convention, iID_Nouveau_Beneficiaire
                                  FROM dbo.tblIQEE_RemplacementsBeneficiaire RB
                                       JOIN dbo.tblIQEE_Fichiers FRB ON FRB.iID_Fichier_IQEE = RB.iID_Fichier_IQEE
                                 WHERE RB.siAnnee_Fiscale = @siAnnee_Fiscale_Fin
                                ) RB ON RB.iID_Convention = D.iID_Convention 
                                    And RB.iID_Nouveau_Beneficiaire = D.iID_Beneficiaire_31Decembre
                        -- La demande d'IQÉÉ doit être en vigueur, avoir reçu une réponse et faire partie de la sélection d'une convention en particulier s'il y a lieu
                        WHERE D.siAnnee_Fiscale = @siAnnee_Fiscale
                          AND D.tiCode_Version IN (0, 2)
                          AND D.cStatut_Reponse = 'R'
                        SET @iCount = @@ROWCOUNT
                        PRINT '            ' + LTrim(Str(@iCount)) + ' à traité(s) pour ' + Str(@siAnnee_Fiscale,4)

                        -- Demander l'annulation
                        SET @iID_Enregistrement = 0
                        SET @iCounter = 0
                        WHILE EXISTS(SELECT TOP 1 * FROM #TB_DemanderAnnulations WHERE iID_Enregistrement > @iID_Enregistrement)
                        BEGIN
                            SELECT @iID_Enregistrement = Min(iID_Enregistrement)
                              FROM #TB_DemanderAnnulations
                             WHERE iID_Enregistrement > @iID_Enregistrement

                            -- Déterminer qui a fait la dernière modification menant à l'annulation
                            SELECT @dtDate_Action_Menant_Annulation = NULL,
                                   @iID_Utilisateur_Action_Menant_Annulation = NULL,
                                   @iID_Suivi_Modification = NULL;

                            SELECT TOP 1 @dtDate_Action_Menant_Annulation = SM.dtDate_Modification, 
                                         @iID_Utilisateur_Action_Menant_Annulation = SM.iID_Utilisateur_Modification, 
                                         @iID_Suivi_Modification = SM.iID_Suivi_Modification
                              FROM tblIQEE_Demandes D
                                   JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
                                   JOIN dbo.Mo_Human H ON H.HumanID = D.iID_Beneficiaire_31Decembre
                                   JOIN tblGENE_SuiviModifications SM ON SM.iCode_Table = 7
                                                                     AND SM.iID_Enregistrement = H.HumanID
                                                                     AND SM.dtDate_Modification > F.dtDate_Creation
                                   JOIN CRQ_LogAction LA ON LA.LogActionID = SM.iID_Action
                                                        AND LA.LogActionShortName = 'U'
                             WHERE D.iID_Demande_IQEE = @iID_Enregistrement
                             ORDER BY SM.dtDate_Modification DESC;

                            EXECUTE dbo.psIQEE_AjouterDemandeAnnulation @tiID_Type_Enregistrement, @iID_Enregistrement, @iID_Session, @dtDate_Creation_Fichiers, 
                                                                        @vcCode_Simulation, @iID_Utilisateur_Creation, @iID_Type_Annulation, @iID_Raison_Annulation, 
                                                                        NULL, @dtDate_Action_Menant_Annulation, @iID_Utilisateur_Action_Menant_Annulation, @iID_Suivi_Modification, 
                                                                        @vcCode_Message OUTPUT, @iID_Annulation OUTPUT;
                            SET @curSituationSize += 1
                            
                            SET @iCounter += 1;
                            IF @iCounter % 1000 = 0
                                PRINT '            ' + LTrim(Str(@iCounter)) + ' de complété(s)'
                        END;
                    
                        SET @siAnnee_Fiscale += 1
                    END;
                END;

                -- Modification à la date de début de contrat
                IF @vcCode_Raison = 'DATE_DEBUT_CONTRAT_02'
                BEGIN
                    SET @siAnnee_Fiscale = @siAnnee_Fiscale_Debut
                    WHILE @siAnnee_Fiscale <= @siAnnee_Fiscale_Fin
                    BEGIN
                        TRUNCATE TABLE #TB_DemanderAnnulations

                        -- Rechercher les cas de la situation du changement
                        INSERT INTO #TB_DemanderAnnulations (iID_Enregistrement)
                        SELECT DISTINCT iID_Demande_IQEE
                        FROM (
                                SELECT D.iID_Demande_IQEE, D.iID_Convention, D.dtDate_Debut_Convention
                                FROM tblIQEE_Demandes D -- La transaction modifiée doit faire partie des années fiscales demandées par l'utilisateur
                                    JOIN #TB_DemanderAnnulations_Conv C ON C.ConventionID = D.iID_Convention
                                    -- et faire partie des fichiers de l'IQÉÉ admissibles
                                    JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
                                                            AND tiID_Type_Fichier = 1
                                                                --10: Réponses et erreurs reçues
                                                                --11: Réponses incomplètes
                                                                --14: Réponses reçues
                                                            AND tiID_Statut_Fichier IN (10, 11, 14)
                                                            AND (@bFichiers_Test_Comme_Production = 1 OR F.bFichier_Test = 0) -- Tenir compte ou non des fichiers test
                                                            AND F.bInd_Simulation = 0 -- Ne jamais tenir compte des fichiers de simulation
                                -- La demande d'IQÉÉ doit être en vigueur, avoir reçu une réponse et faire partie de la
                                -- sélection d'une convention en particulier s'il y a lieu
                                WHERE D.siAnnee_Fiscale = @siAnnee_Fiscale
                                  AND D.tiCode_Version IN (0, 2)
                                  AND D.cStatut_Reponse = 'R'
                                    -- La date de début de contrat de la transaction modifiée doit avoir changée depuis la transaction
                                    -- SB 2012-12-20: Nouvelles règles concernant la date de début de contrat.
                                    -- Si la nouvelle date de début de contrat est plus jeune que la date actuelle, elle est non amendable donc une Annulation-Reprise est nécessaire
                                    -- Si la nouvelle date de début de contrat est plus vieille que la date actuelle, elle est amendable donc pas besoin d'annulation-reprise.
                            ) X
                        WHERE IsNull(dbo.fnIQEE_ObtenirDateEnregistrementRQ(iID_Convention), dtDate_Debut_Convention) > dtDate_Debut_Convention
                        SET @iCount = @@ROWCOUNT
                        PRINT '            ' + LTrim(Str(@iCount)) + ' à traité(s) pour ' + Str(@siAnnee_Fiscale,4)
                    
                        -- Demander l'annulation
                        SET @iID_Enregistrement = 0
                        SET @iCounter = 0
                        WHILE EXISTS(SELECT TOP 1 * FROM #TB_DemanderAnnulations WHERE iID_Enregistrement > @iID_Enregistrement)
                        BEGIN
                            SELECT @iID_Enregistrement = Min(iID_Enregistrement)
                              FROM #TB_DemanderAnnulations
                             WHERE iID_Enregistrement > @iID_Enregistrement

                            --SELECT @iID_ConventionCurrent = iID_Convention,
                            --       @dtDate_Debut_Convention = dtDate_Debut_Convention
                            --  FROM dbo.tblIQEE_Demandes
                            -- WHERE iID_Demande_IQEE = @iID_Enregistrement

                            ---- Présume que la disparition de la date, n'est pas un changement de date
                            --IF ISNULL(dbo.fnIQEE_ObtenirDateEnregistrementRQ(@iID_ConventionCurrent), @dtDate_Debut_Convention) > @dtDate_Debut_Convention 
                                EXECUTE dbo.psIQEE_AjouterDemandeAnnulation @tiID_Type_Enregistrement, @iID_Enregistrement, @iID_Session, @dtDate_Creation_Fichiers, @vcCode_Simulation, @iID_Utilisateur_Creation, @iID_Type_Annulation, @iID_Raison_Annulation, NULL, NULL, NULL, NULL, @vcCode_Message OUTPUT, @iID_Annulation OUTPUT;

                                SET @curSituationSize += 1
                        
                            SET @iCounter += 1;
                            IF @iCounter % 1000 = 0
                                PRINT '            ' + LTrim(Str(@iCounter)) + ' de complété(s)'
                        END;
                    
                        SET @siAnnee_Fiscale += 1
                    END;
                END;

                -- Annulation des transactions existantes afin de laisser passer une transaction antérieure rejetée
                IF @vcCode_Raison = 'ANNULATION_TRANSACTION_PASSE_02'
                BEGIN
                    PRINT '    Raison - ANNULATION_TRANSACTION_PASSE_02 - Skipped'
--                        -- Rechercher les cas de la situation du changement
--                        DECLARE curSituation CURSOR LOCAL FAST_FORWARD FOR
--                            SELECT D.iID_Convention, MIN(D.iID_Demande_IQEE)
--                            FROM tblIQEE_Demandes D
--                                   JOIN #TB_DemanderAnnulations_Conv C ON C.ConventionID = D.iID_Convention
--                                 -- La transaction doit faire partie des années fiscales demandées par l'utilisateur
--                                 -- et faire partie des fichiers de l'IQÉÉ admissibles
--                                 JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
--                                                        AND (@bFichiers_Test_Comme_Production = 1
--                                                             OR F.bFichier_Test = 0) -- Tenir compte ou non des fichiers test
--                                                        AND F.bInd_Simulation = 0 -- Ne jamais tenir compte des fichiers de
--                                                                                  -- simulation
--                            -- La demande d'IQÉÉ doit être en vigueur, avoir reçu une réponse et faire partie de la
--                            -- sélection d'une convention en particulier s'il y a lieu
--                            WHERE D.siAnnee_Fiscale <= @siAnnee_Fiscale_Fin
--                              AND D.tiCode_Version IN (0,2)
--                              AND D.cStatut_Reponse = 'R'
--                              -- Existe des rejetées dans le passé qui sont traitable et non pas déjà fait l'objet d'une
--                              -- transaction valide
--                              AND EXISTS (SELECT *
--                                          -- Recherche un fichier antérieur à la transaction de demande d'IQÉÉ 
--                                          FROM tblIQEE_Fichiers F2
--                                               -- Uniquement les fichiers de transactions
--                                               JOIN tblIQEE_TypesFichier TF ON TF.tiID_Type_Fichier = F2.tiID_Type_Fichier    
--                                                                           AND TF.vcCode_Type_Fichier = 'DEM'
--                                               -- Obtenir les paramètres en vigueur au moment de la transaction
--                                               JOIN tblIQEE_Parametres P ON P.iID_Parametres_IQEE = F2.iID_Parametres_IQEE
--                                          -- Le fichier est antérieur à la transaction de demande d'IQÉÉ à vérifier
--                                          WHERE F2.dtDate_Creation < F.dtDate_Creation
--                                            -- L'année fiscale du fichier doit être antérieur
--                                            AND F2.siAnnee_Fiscale < F.siAnnee_Fiscale
--                                            -- Mais l'année fiscale doit être dans le nombre d'année antérieur qui est admissible
--                                            -- à une nouvelle transaction
--                                            AND F2.siAnnee_Fiscale >= YEAR(GETDATE())-P.tiNb_Maximum_Annee_Fiscale_Anterieur
--                                            -- Le fichier fait partie des fichiers de l'IQÉÉ admissibles
--                                            AND (@bFichiers_Test_Comme_Production = 1
--                                                 OR F2.bFichier_Test = 0) -- Tenir compte ou non des fichiers test
--                                            AND F2.bInd_Simulation = 0 -- Ne jamais tenir compte des fichiers de simulation
--                                            -- La transaction de demande avait été rejetée dans le passé au moment de la création
--                                            -- du fichier
--                                            AND EXISTS (SELECT *
--                                                        FROM tblIQEE_Rejets R
--                                                             JOIN tblIQEE_Validations V ON V.iID_Validation = R.iID_Validation
--                                                                                      AND V.tiID_Type_Enregistrement =
--                                                                                                        @tiID_Type_Enregistrement
--                                                            WHERE R.iID_Convention = D.iID_Convention
--                                                              AND R.iID_Fichier_IQEE = F2.iID_Fichier_IQEE)
--                                            -- La transaction rejetée dans le passé doit pouvoir potentiellement être créée.  Donc,
--                                            -- ne pas avoir été rejeté par des validations menant à des erreurs sur lesquelles
--                                            -- il n'est théoriquement pas possible d'intervenir et qui sont encore en vigueur
--                                            -- à ce jour
--                                            AND NOT EXISTS (SELECT *
--                                                            FROM tblIQEE_Rejets R
--                                                                 JOIN tblIQEE_Validations V ON V.iID_Validation = R.iID_Validation
--                                                                                      AND V.tiID_Type_Enregistrement =
--                                                                                                        @tiID_Type_Enregistrement
--                                                                                      AND V.cType = 'E'
--                                                                                      AND V.bCorrection_Possible = 0
--                                                                                      AND V.iCode_Validation <> 54    
--                                                                                      AND V.bActif = 1
--                                                            WHERE R.iID_Convention = D.iID_Convention
--                                                              AND R.iID_Fichier_IQEE = F2.iID_Fichier_IQEE)
--                                            -- La transaction qui devrait être annulée pour laisser passer une transaction
--                                            -- antérieur, ne doit pas avoir fait l'objet d'une transaction valide par la suite
--                                            AND NOT EXISTS (SELECT *
--                                                            -- Recherche d'une transaction valide survenue après le rejet
--                                                            FROM tblIQEE_Demandes D2
--                                                                 -- La transaction doit faire partie de la même années fiscales
--                                                                 -- que le fichier sélectionné, avoir été créée après 
--                                                                 -- et faire partie des fichiers de l'IQÉÉ admissibles
--                                                                 JOIN tblIQEE_Fichiers F3 ON F3.iID_Fichier_IQEE =
--                                                                                                            D2.iID_Fichier_IQEE
--                                                                                         AND F3.dtDate_Creation >=
--                                                                                                                F2.dtDate_Creation
--                                                                                         -- Tenir compte ou non des fichiers test
--                                                                                         AND (@bFichiers_Test_Comme_Production = 1
--                                                                                              OR F3.bFichier_Test = 0)
--                                                                                          -- Ne jamais tenir compte des fichiers
--                                                                                          -- de simulation
--                                                                                         AND F3.bInd_Simulation = 0
--                                                            -- La transaction doit être en vigueur, avoir reçu une réponse et
--                                                            -- faire partie de la sélection d'une convention en particulier
--                                                            -- s'il y a lieu
--                                                            WHERE D2.iID_Convention = D.iID_Convention
--                                                              AND D2.siAnnee_Fiscale = F2.siAnnee_Fiscale
--                                                              AND D2.tiCode_Version IN (0,2)
--                                                              AND D2.cStatut_Reponse = 'R'))
--                            GROUP BY D.iID_Convention

--                        -- Demander l'annulation
--                        OPEN curSituation
--                        FETCH NEXT FROM curSituation INTO @iID_TMP, @iID_Enregistrement
--                        WHILE @@FETCH_STATUS = 0
--                            BEGIN
--                                SET @curSituationSize = @curSituationSize + 1
--                                SELECT '@vcCode_Raison = ANNULATION_TRANSACTION_PASSE_02'
--                                --EXECUTE dbo.psIQEE_AjouterDemandeAnnulation @tiID_Type_Enregistrement, @iID_Enregistrement,
--                                --                                            @iID_Session, @dtDate_Creation_Fichiers,
--                                --                                            @vcCode_Simulation, @iID_Utilisateur_Creation,
--                                --                                            @iID_Type_Annulation, @iID_Raison_Annulation,
--                                --                                            NULL, NULL, NULL, NULL, @vcCode_Message OUTPUT,
--                                --                                            @iID_Annulation OUTPUT
--                                FETCH NEXT FROM curSituation INTO @iID_TMP, @iID_Enregistrement
--                            END
--                        CLOSE curSituation
--                        DEALLOCATE curSituation                            
--                        --SELECT @curSituationSize as '@curSituationSize Raison = ANNULATION_TRANSACTION_PASSE_02'
                END

-- TODO: Autres situations d'annulation - type 03, 04, 05 et 06

                IF @vcCode_Raison = 'BENEFICIAIRE_HORS_QUEBEC_02'
                BEGIN
                    SET @siAnnee_Fiscale = @siAnnee_Fiscale_Debut
                    WHILE @siAnnee_Fiscale <= @siAnnee_Fiscale_Fin
                    BEGIN
                        TRUNCATE TABLE #TB_DemanderAnnulations

                        SELECT @dtFinCotisation = P.dtDate_Fin_Cotisation
                        FROM dbo.tblIQEE_Parametres P
                        WHERE P.siAnnee_Fiscale = @siAnnee_Fiscale

                        -- Rechercher les cas de la situation du changement
                        INSERT INTO #TB_DemanderAnnulations (iID_Enregistrement, vcProvince, vcVille, vcPays, vcCodePostal)
                        SELECT DISTINCT iID_Demande_IQEE, A.vcProvince, A.vcVille, A.vcPays, A.vcCodePostal
                        FROM (
                                SELECT DISTINCT D.iID_Demande_IQEE, D.iID_Beneficiaire_31Decembre, D.siAnnee_Fiscale
                                FROM tblIQEE_Demandes D -- La transaction modifiée doit faire partie des années fiscales demandées par l'utilisateur et faire partie des fichiers de l'IQÉÉ admissibles
                                    JOIN #TB_DemanderAnnulations_Conv C ON C.ConventionID = D.iID_Convention
                                    JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
                                                            AND tiID_Type_Fichier = 1
                                                                --10: Réponses et erreurs reçues
                                                                --11: Réponses incomplètes
                                                                --14: Réponses reçues
                                                            AND tiID_Statut_Fichier IN (10, 11, 14)
                                                            AND (@bFichiers_Test_Comme_Production = 1 OR F.bFichier_Test = 0) -- Tenir compte ou non des fichiers test
                                                            AND F.bInd_Simulation = 0 -- Ne jamais tenir compte des fichiers de simulation        
                                -- La demande d'IQÉÉ doit être en vigueur, avoir reçu une réponse et faire partie de la sélection d'une convention en particulier s'il y a lieu
                                WHERE D.siAnnee_Fiscale = @siAnnee_Fiscale
                                  --AND D.siAnnee_Fiscale <= @siAnnee_Fiscale_Fin
                                  AND D.tiCode_Version IN (0, 2)
                                   AND D.cStatut_Reponse = 'R'
                                  AND D.bResidence_Quebec = 1
                            ) X
                            JOIN dbo.fntGENE_ObtenirAdresseEnDate_PourTous(NULL, 1, @dtFinCotisation, 1) A ON A.iID_Source = X.iID_Beneficiaire_31Decembre
                            LEFT JOIN (
                                SELECT S.StateID, S.StateCode, S.StateName, P.CountryID FROM dbo.Mo_State S JOIN dbo.Mo_Country P ON P.CountryID = S.CountryID 
                                 WHERE P.CountryID = 'CAN' --And S.StateCode = 'QC'
                            ) S ON UPPER(LTRIM(RTRIM(S.StateName))) = UPPER(LTRIM(RTRIM(A.vcProvince)))
                        WHERE A.bResidenceFaitQuebec = 0
                          AND (S.CountryID <> 'CAN' OR s.StateCode <> 'QC')
                          --AND EXISTS(SELECT * FROM dbo.fntGENE_ObtenirProvincePays(A.vcProvince, A.vcVille, A.vcPays, A.vcCodePostal) WHERE vcCode_Province <> 'QC')
                        SET @iCount = @@ROWCOUNT
                        PRINT '            ' + LTrim(Str(@iCount)) + ' à traité(s) pour ' + Str(@siAnnee_Fiscale,4)
                        
                        -- Demander l'annulation
                        SET @iID_Enregistrement = 0
                        SET @iCounter = 0
                        WHILE EXISTS(SELECT TOP 1 * FROM #TB_DemanderAnnulations WHERE iID_Enregistrement > @iID_Enregistrement)
                        BEGIN
                            SELECT @iID_Enregistrement = Min(iID_Enregistrement)
                              FROM #TB_DemanderAnnulations
                             WHERE iID_Enregistrement > @iID_Enregistrement

                            SELECT @vcProvince = vcProvince,
                                   @vcVille = vcVille,
                                   @vcPays = vcPays,
                                   @vcCodePostal = vcCodePostal
                              FROM #TB_DemanderAnnulations
                             WHERE iID_Enregistrement = @iID_Enregistrement
                            
                            IF EXISTS(SELECT * FROM dbo.fntGENE_ObtenirProvincePays(@vcProvince, @vcVille, @vcPays, @vcCodePostal) WHERE vcCode_Province <> 'QC')
                            BEGIN
                                EXECUTE dbo.psIQEE_AjouterDemandeAnnulation @tiID_Type_Enregistrement, @iID_Enregistrement, @iID_Session, @dtDate_Creation_Fichiers, 
                                                                            @vcCode_Simulation, @iID_Utilisateur_Creation, @iID_Type_Annulation, @iID_Raison_Annulation, 
                                                                            NULL, NULL, NULL, NULL, @vcCode_Message OUTPUT, @iID_Annulation OUTPUT;
                                SET @curSituationSize += 1
                            END

                            SET @iCounter += 1;
                            IF @iCounter % 1000 = 0
                                PRINT '            ' + LTrim(Str(@iCounter)) + ' de complété(s)'
                        END;
                    
                        SET @siAnnee_Fiscale += 1
                    END;
                END;

                IF @vcCode_Raison = 'BENEFICIAIRE_RESIDENT_QUEBEC_02'
                BEGIN
                    SET @siAnnee_Fiscale = @siAnnee_Fiscale_Debut
                    WHILE @siAnnee_Fiscale <= @siAnnee_Fiscale_Fin
                    BEGIN
                        TRUNCATE TABLE #TB_DemanderAnnulations

                        SELECT @dtFinCotisation = P.dtDate_Fin_Cotisation
                        FROM dbo.tblIQEE_Parametres P
                        WHERE P.siAnnee_Fiscale = @siAnnee_Fiscale

                        -- Rechercher les cas de la situation du changement
                        INSERT INTO #TB_DemanderAnnulations (iID_Enregistrement, vcProvince, vcVille, vcPays, vcCodePostal)
                        SELECT DISTINCT iID_Demande_IQEE, A.vcProvince, A.vcVille, A.vcPays, A.vcCodePostal
                        FROM (
                                SELECT DISTINCT D.iID_Demande_IQEE, D.iID_Beneficiaire_31Decembre, D.siAnnee_Fiscale
                                FROM tblIQEE_Demandes D -- La transaction modifiée doit faire partie des années fiscales demandées par l'utilisateur et faire partie des fichiers de l'IQÉÉ admissibles
                                    JOIN #TB_DemanderAnnulations_Conv C ON C.ConventionID = D.iID_Convention
                                    JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
                                                            AND tiID_Type_Fichier = 1
                                                                --10: Réponses et erreurs reçues
                                                                --11: Réponses incomplètes
                                                                --14: Réponses reçues
                                                            AND tiID_Statut_Fichier IN (10, 11, 14)
                                                            AND (@bFichiers_Test_Comme_Production = 1 OR F.bFichier_Test = 0) -- Tenir compte ou non des fichiers test
                                                            AND F.bInd_Simulation = 0 -- Ne jamais tenir compte des fichiers de simulation
                                -- La demande d'IQÉÉ doit être en vigueur, avoir reçu une réponse et faire partie de la sélection d'une convention en particulier s'il y a lieu
                                WHERE D.tiCode_Version IN (0, 2)
                                  AND D.siAnnee_Fiscale = @siAnnee_Fiscale
                                  --AND D.siAnnee_Fiscale <= @siAnnee_Fiscale_Fin
                                  AND D.cStatut_Reponse = 'R'
                                  AND D.bResidence_Quebec = 0
                            ) X
                            JOIN dbo.fntGENE_ObtenirAdresseEnDate_PourTous(NULL, 1, @dtFinCotisation, 1) A ON A.iID_Source = X.iID_Beneficiaire_31Decembre
                            LEFT JOIN (
                                SELECT S.StateID, S.StateCode, S.StateName, P.CountryID FROM dbo.Mo_State S JOIN dbo.Mo_Country P ON P.CountryID = S.CountryID 
                                 WHERE P.CountryID = 'CAN' --And S.StateCode = 'QC'
                            ) S ON UPPER(LTRIM(RTRIM(S.StateName))) = UPPER(LTRIM(RTRIM(A.vcProvince)))
                        WHERE A.bResidenceFaitQuebec = 0
                          AND (S.CountryID <> 'CAN' OR s.StateCode <> 'QC')
                          --AND EXISTS(SELECT * FROM dbo.fntGENE_ObtenirProvincePays(A.vcProvince, A.vcVille, A.vcPays, A.vcCodePostal) WHERE vcCode_Province <> 'QC')
                        SET @iCount = @@ROWCOUNT
                        PRINT '            ' + LTrim(Str(@iCount)) + ' à traité(s) pour ' + Str(@siAnnee_Fiscale,4)

                        -- Demander l''annulation
                        SET @iID_Enregistrement = 0
                        SET @iCounter = 0
                        WHILE EXISTS(SELECT TOP 1 * FROM #TB_DemanderAnnulations WHERE iID_Enregistrement > @iID_Enregistrement)
                        BEGIN
                            SELECT @iID_Enregistrement = Min(iID_Enregistrement)
                              FROM #TB_DemanderAnnulations
                             WHERE iID_Enregistrement > @iID_Enregistrement

                            SELECT @vcProvince = vcProvince,
                                   @vcVille = vcVille,
                                   @vcPays = vcPays,
                                   @vcCodePostal = vcCodePostal
                              FROM #TB_DemanderAnnulations
                             WHERE iID_Enregistrement = @iID_Enregistrement
                            
                            IF EXISTS(SELECT * FROM dbo.fntGENE_ObtenirProvincePays(@vcProvince, @vcVille, @vcPays, @vcCodePostal) WHERE vcCode_Province <> 'QC')
                            BEGIN
                                EXECUTE dbo.psIQEE_AjouterDemandeAnnulation @tiID_Type_Enregistrement, @iID_Enregistrement, @iID_Session, @dtDate_Creation_Fichiers, 
                                                                            @vcCode_Simulation, @iID_Utilisateur_Creation, @iID_Type_Annulation, @iID_Raison_Annulation, 
                                                                            NULL, NULL, NULL, NULL, @vcCode_Message OUTPUT, @iID_Annulation OUTPUT;
                                SET @curSituationSize += 1
                            END

                            SET @iCounter += 1;
                            IF @iCounter % 1000 = 0
                                PRINT '            ' + LTrim(Str(@iCounter)) + ' de complété(s)'
                        END;
                    
                        SET @siAnnee_Fiscale += 1
                    END;
                END;

                PRINT '        ' + ltrim(str(@curSituationSize, 6)) + ' annulation(s) ajoutée(s)'

                FETCH NEXT FROM curRaisonsAnnulation INTO @iID_Raison_Annulation, @vcCode_Raison, @tiID_Type_Enregistrement, @iID_Sous_Type;
            END;

            CLOSE curRaisonsAnnulation;
            DEALLOCATE curRaisonsAnnulation;
        END
        -----------------------------------------------------------------------------------------------------------------------
        -- Demander les annulations pour les autres transactions suite aux annulations affectant des informations pas amendable
        -- ou les annulations de conséquences pour les annulations qui doivent reprendre les transactions depuis le début
        -----------------------------------------------------------------------------------------------------------------------
        -- SB: 2012-10-16
        -- Après réflexion, il n'a jamais été nécessaire de faire une rétroaction complète des années précédentes.  
        -- Après réflexion, on abordera la technique du 1 pour 1 (1:1)  UN Cycle d'UNE demande pour UNE année fiscale.
        -- On amende seulement les transactions concernées.  On ne compromet pas l'historique des réponses approuvées passées à moins d'avis contraire.  
        -- Dans les cas des informations non amendables (Type enregistrement, Année Fiscale, Année, Id Fiduciaire, Id Contrat, NAS Bénéficiaire), 
        -- on fait une annulation, une reprise à 0$ et une originale pour l'année concernée seulement. 


        IF Object_ID('tempDB..##tblIQEE_RapportCreation') IS NOT NULL
            INSERT INTO ##tblIQEE_RapportCreation (cSection, iSequence, vcMessage)
                 VALUES ('3', 10, '       ' + CONVERT(VARCHAR(25), GETDATE(), 121)
                                            + ' - psIQEE_DemanderAnnulations             '
                                            + '- Annulations affectant informations pas amendable ou reprendre depuis le début'
                        );

        -- Déterminer l'identifiant du type d'annulation de conséquence
        SELECT @iID_Type_Annulation = TA.iID_Type_Annulation
            FROM tblIQEE_TypesAnnulation TA
            WHERE TA.vcCode_Type = 'CON';

        PRINT '    Demander les annulations des demandes (Type 02)'
        -- Demander les annulations des demandes (Type 02)
        INSERT INTO dbo.tblIQEE_Annulations (tiID_Type_Enregistrement, iID_Enregistrement_Demande_Annulation, iID_Session, dtDate_Creation_Fichiers, 
                                             vcCode_Simulation, dtDate_Demande_Annulation, iID_Utilisateur_Demande, iID_Type_Annulation, iID_Raison_Annulation, 
                                             tCommentaires, dtDate_Action_Menant_Annulation, iID_Utilisateur_Action_Menant_Annulation, 
                                             iID_Suivi_Modification, iID_Statut_Annulation
                                            )
        SELECT DISTINCT A.tiID_Type_Enregistrement, D2.iID_Demande_IQEE, A.iID_Session, A.dtDate_Creation_Fichiers, 
                        A.vcCode_Simulation, A.dtDate_Demande_Annulation, A.iID_Utilisateur_Demande,
                        -- Informations pas amendable: on reprend toutes les demandes depuis le début pour la même raison d'annulation
                        -- Reprendre depuis le début: on reprend toutes les demandes depuis de début en annulation de conséquence
                        CASE WHEN RA.bAffecte_Infos_Pas_Amendable = 1 THEN A.iID_Type_Annulation
                             ELSE @iID_Type_Annulation
                        END, 
                        A.iID_Raison_Annulation, 
                        CAST(A.tCommentaires AS VARCHAR(MAX)), A.dtDate_Action_Menant_Annulation, A.iID_Utilisateur_Action_Menant_Annulation, 
                        A.iID_Suivi_Modification, @iID_Statut_Annulation
               -- Rechercher les demandes d'annulation de la création des fichiers
          FROM tblIQEE_Annulations A -- Uniquement ceux que la raison d'annulation requière la reprise des transactions depuis le début
               JOIN tblIQEE_RaisonsAnnulation RA ON RA.iID_Raison_Annulation = A.iID_Raison_Annulation
                                                    -- Uniquement ceux des demandes d'IQÉÉ
                                                AND (RA.bAffecte_Infos_Pas_Amendable = 1 OR RA.bAnnuler_Transactions_Depuis_Debut = 1) 
               JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
                                                  AND TE.cCode_Type_Enregistrement = '02' -- Trouver la transaction à annuler
               JOIN tblIQEE_Demandes D ON D.iID_Demande_IQEE = A.iID_Enregistrement_Demande_Annulation -- La transaction doit être en vigueur, avoir été envoyé à RQ et ne pas avoir déjà fait l'objet d'une demande d'annulation
               JOIN tblIQEE_Demandes D2 ON D2.iID_Convention = D.iID_Convention
                                       AND D2.iID_Demande_IQEE <> D.iID_Demande_IQEE
                                       AND D2.tiCode_Version IN (0, 2)
                                       AND D2.cStatut_Reponse = 'R'
         WHERE A.iID_Session = @iID_Session
           AND A.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers;

        PRINT '        ' + ltrim(str(@curSituationSize, 6)) + ' annulation(s) ajoutée(s)'

        PRINT '    Demander les annulations des demandes (Type 04)'
        -- Demander les annulations des transferts (Type 04) - reprendre depuis le début: on reprend tous les transferts depuis de début en annulation de conséquence
        SELECT @tiID_Type_Enregistrement = TE.tiID_Type_Enregistrement
          FROM tblIQEE_TypesEnregistrement TE
         WHERE TE.cCode_Type_Enregistrement = '04';

        INSERT INTO dbo.tblIQEE_Annulations (
                tiID_Type_Enregistrement, iID_Enregistrement_Demande_Annulation, iID_Session, dtDate_Creation_Fichiers, 
                vcCode_Simulation, dtDate_Demande_Annulation, iID_Utilisateur_Demande, iID_Type_Annulation, iID_Raison_Annulation, 
                tCommentaires, dtDate_Action_Menant_Annulation, iID_Utilisateur_Action_Menant_Annulation, 
                iID_Suivi_Modification, iID_Statut_Annulation
            )
        SELECT DISTINCT
                @tiID_Type_Enregistrement, T2.iID_Transfert, A.iID_Session, A.dtDate_Creation_Fichiers, 
                A.vcCode_Simulation, A.dtDate_Demande_Annulation, A.iID_Utilisateur_Demande, @iID_Type_Annulation, A.iID_Raison_Annulation, 
                CAST(A.tCommentaires AS VARCHAR(MAX)), A.dtDate_Action_Menant_Annulation, A.iID_Utilisateur_Action_Menant_Annulation, 
                A.iID_Suivi_Modification, @iID_Statut_Annulation
               -- Rechercher les demandes d'annulation de la création des fichiers
          FROM tblIQEE_Annulations A -- Uniquement ceux que la raison d'annulation requière la reprise des transactions depuis le début
               JOIN tblIQEE_RaisonsAnnulation RA ON RA.iID_Raison_Annulation = A.iID_Raison_Annulation
                                                AND RA.bAnnuler_Transactions_Depuis_Debut = 1 -- Trouver le type d'enregistrement en demande d'annulation
               JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement -- Rechercher chaque type de transaction d'origine à annuler
               LEFT JOIN tblIQEE_Demandes D ON TE.cCode_Type_Enregistrement = '02'
                                           AND D.iID_Demande_IQEE = A.iID_Enregistrement_Demande_Annulation
               LEFT JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
               LEFT JOIN tblIQEE_RemplacementsBeneficiaire RB ON TE.cCode_Type_Enregistrement = '03'
                                                             AND RB.iID_Remplacement_Beneficiaire = A.iID_Enregistrement_Demande_Annulation
               LEFT JOIN tblIQEE_Transferts T ON TE.cCode_Type_Enregistrement = '04'
                                             AND T.iID_Transfert = A.iID_Enregistrement_Demande_Annulation
               LEFT JOIN tblIQEE_PaiementsBeneficiaires PB ON TE.cCode_Type_Enregistrement = '05'
                                                           AND PB.iID_Paiement_Beneficiaire = A.iID_Enregistrement_Demande_Annulation
               LEFT JOIN tblIQEE_ImpotsSpeciaux TIS ON TE.cCode_Type_Enregistrement = '06'
                                                   AND TIS.iID_Impot_Special = A.iID_Enregistrement_Demande_Annulation -- Rechercher les transactions de transfert des conventions touchées
               JOIN tblIQEE_Transferts T2 ON T2.iID_Convention = CASE WHEN TE.cCode_Type_Enregistrement = '02' THEN D.iID_Convention
                                                                      WHEN TE.cCode_Type_Enregistrement = '03' THEN RB.iID_Convention
                                                                      WHEN TE.cCode_Type_Enregistrement = '04' THEN T.iID_Convention
                                                                      WHEN TE.cCode_Type_Enregistrement = '05' THEN PB.iID_Convention
                                                                      WHEN TE.cCode_Type_Enregistrement = '06' THEN TIS.iID_Convention
                                                                 END
                                             -- Qui ont eues lieu avant ou pendant les transactions en demande d'annulation
                                         AND T2.dtDate_Transfert <= CASE WHEN TE.cCode_Type_Enregistrement = '02' THEN CAST(CAST(D.siAnnee_Fiscale AS VARCHAR(4))+'-12-31' AS DATETIME)
                                                                         WHEN TE.cCode_Type_Enregistrement = '03' THEN RB.dtDate_Remplacement
                                                                         WHEN TE.cCode_Type_Enregistrement = '04' THEN T.dtDate_Transfert
                                                                         WHEN TE.cCode_Type_Enregistrement = '05' THEN PB.dtDate_Paiement
                                                                         WHEN TE.cCode_Type_Enregistrement = '06' THEN TIS.dtDate_Evenement
                                                                    END
                                             -- Et qui sont encore en vigueur
                                         AND T2.tiCode_Version IN (0, 2)
                                             -- Et que RQ ait reçu la transaction
                                         AND T2.cStatut_Reponse = 'R'
         WHERE A.iID_Session = @iID_Session
           AND A.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers;

        -- TODO: Traiter autres types de transaction 03, 04, 05 et 06 pour les reprises d'informations pas amendable?  Je pense que non.
        --         2009-10-14
        ------------------------------------------------------------------------------
        -- Demander les annulations de conséquences pour les transactions subséquentes
        ------------------------------------------------------------------------------

        INSERT INTO ##tblIQEE_RapportCreation(cSection, iSequence, vcMessage)
             VALUES ('3', 10, '       ' + CONVERT(VARCHAR(25), GETDATE(), 121)
                                        + ' - psIQEE_DemanderAnnulations            '
                                        + ' - Demander annulations de conséquences pour transactions subséquentes'
                    );

        -- Créer une table temporaire des transactions de demande d'annulation par conventions
        CREATE TABLE #tblIQEE_TransactionsConventions (
            iID_Convention INT NOT NULL, 
            dtDate_Transaction_A_Annuler DATETIME NOT NULL, 
            iID_Raison_Annulation INT NOT NULL
        );

        CREATE INDEX #IX_tblIQEE_TransactionsConventions ON #tblIQEE_TransactionsConventions (iID_Convention);

        -- Déterminer les conventions impliquées dans une annulation avec conséquences ainsi que la date de la transaction sur laquelle il y a une demande d'annulation
        INSERT INTO #tblIQEE_TransactionsConventions (
            iID_Convention, dtDate_Transaction_A_Annuler, iID_Raison_Annulation
        )
        SELECT CASE WHEN TE.cCode_Type_Enregistrement = '02' THEN D.iID_Convention
                    WHEN TE.cCode_Type_Enregistrement = '03' THEN RB.iID_Convention
                    WHEN TE.cCode_Type_Enregistrement = '04' THEN T.iID_Convention
                    WHEN TE.cCode_Type_Enregistrement = '05' THEN PB.iID_Convention
                    WHEN TE.cCode_Type_Enregistrement = '06' THEN TIS.iID_Convention
               END,
               CASE WHEN TE.cCode_Type_Enregistrement = '02' THEN CAST(CAST(D.siAnnee_Fiscale AS VARCHAR(4))+'-12-31' AS DATETIME)
                    WHEN TE.cCode_Type_Enregistrement = '03' THEN RB.dtDate_Remplacement
                    WHEN TE.cCode_Type_Enregistrement = '04' THEN T.dtDate_Transfert
                    WHEN TE.cCode_Type_Enregistrement = '05' THEN PB.dtDate_Paiement
                    WHEN TE.cCode_Type_Enregistrement = '06' THEN TIS.dtDate_Evenement
               END, A.iID_Raison_Annulation
               -- Rechercher les demandes d'annulation de la création des fichiers
          FROM tblIQEE_Annulations A -- Uniquement les raisons d'annulation qui exige l'annulation des transactions subséquentes
               JOIN tblIQEE_RaisonsAnnulation RA ON RA.iID_Raison_Annulation = A.iID_Raison_Annulation
                                                AND RA.bAnnuler_Transactions_Subsequentes = 1 -- Trouver le type d'enregistrement en demande d'annulation
               JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement -- Rechercher chaque type de transaction d'origine à annuler
               LEFT JOIN tblIQEE_Demandes D ON TE.cCode_Type_Enregistrement = '02'
                                           AND D.iID_Demande_IQEE = A.iID_Enregistrement_Demande_Annulation
               LEFT JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
               LEFT JOIN tblIQEE_RemplacementsBeneficiaire RB ON TE.cCode_Type_Enregistrement = '03'
                                                             AND RB.iID_Remplacement_Beneficiaire = A.iID_Enregistrement_Demande_Annulation
               LEFT JOIN tblIQEE_Transferts T ON TE.cCode_Type_Enregistrement = '04'
                                             AND T.iID_Transfert = A.iID_Enregistrement_Demande_Annulation
               LEFT JOIN tblIQEE_PaiementsBeneficiaires PB ON TE.cCode_Type_Enregistrement = '05'
                                                          AND PB.iID_Paiement_Beneficiaire = A.iID_Enregistrement_Demande_Annulation
               LEFT JOIN tblIQEE_ImpotsSpeciaux TIS ON TE.cCode_Type_Enregistrement = '06'
                                                   AND TIS.iID_Impot_Special = A.iID_Enregistrement_Demande_Annulation
         WHERE A.iID_Session = @iID_Session
           AND A.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers;    

        -- Créer une table temporaire de la plus ancienne transaction pour chaque convention
        CREATE TABLE #tblIQEE_PlusAncienneTransactionConventions (
            iID_Convention INT NOT NULL, 
            dtDate_Transaction_A_Annuler DATETIME NOT NULL, 
            iID_Raison_Annulation INT NULL
        );

        -- Déterminer la plus ancienne transaction en demande d'annulation pour chaque convention
        INSERT INTO #tblIQEE_PlusAncienneTransactionConventions (iID_Convention, dtDate_Transaction_A_Annuler)
        SELECT C.iID_Convention, MIN(C.dtDate_Transaction_A_Annuler)
          FROM #tblIQEE_TransactionsConventions C
               -- 2014-10-28 SB  Condition pour empêcher les annulations de conséquences antérieures à @siAnnee_Fiscale_Debut 
         WHERE YEAR(C.dtDate_Transaction_A_Annuler) >= @siAnnee_Fiscale_Debut
         GROUP BY C.iID_Convention;

        UPDATE #tblIQEE_PlusAncienneTransactionConventions
           SET iID_Raison_Annulation = (
                    SELECT MIN(C.iID_Raison_Annulation)
                      FROM #tblIQEE_TransactionsConventions C
                     WHERE C.iID_Convention = #tblIQEE_PlusAncienneTransactionConventions.iID_Convention
                       AND C.dtDate_Transaction_A_Annuler = #tblIQEE_PlusAncienneTransactionConventions.dtDate_Transaction_A_Annuler
               );

        DROP TABLE #tblIQEE_TransactionsConventions;

        -- TODO 2011: Est-ce que c'est possible d'enlever les unions pour en faire juste une?
        -- Déterminer les transactions à annuler par conséquence pour tous les types d'enregistrement
        --SELECT '#tblIQEE_PlusAncienneTransactionConventions' as '#tblIQEE_PlusAncienneTransactionConventions'
        --SELECT * from #tblIQEE_PlusAncienneTransactionConventions  

        DECLARE curConsequences CURSOR LOCAL FAST_FORWARD
            FOR SELECT TE.tiID_Type_Enregistrement, D.iID_Demande_IQEE, C.iID_Raison_Annulation
                  FROM #tblIQEE_PlusAncienneTransactionConventions C
                            -- La transaction doit être en vigueur, avoir été envoyé à RQ et ne pas avoir déjà fait l'objet d'une autre demande d'annulation
                       JOIN tblIQEE_TypesEnregistrement TE ON TE.cCode_Type_Enregistrement = '02'
                       JOIN tblIQEE_Demandes D ON D.iID_Convention = C.iID_Convention
                                              AND CAST(CAST(D.siAnnee_Fiscale AS VARCHAR(4))+'-12-31' AS DATETIME) > C.dtDate_Transaction_A_Annuler
                                              AND D.tiCode_Version IN (0, 2)
                                              AND D.cStatut_Reponse = 'R'
                                                  -- Ne pas avoir déjà fait l'objet d'une autre demande d'annulation
                                              AND NOT EXISTS (
                                                      SELECT *
                                                        FROM tblIQEE_Annulations A
                                                       WHERE A.tiID_Type_Enregistrement = TE.tiID_Type_Enregistrement
                                                         AND A.iID_Enregistrement_Demande_Annulation = D.iID_Demande_IQEE
                                                         AND A.iID_Session = @iID_Session
                                                         AND A.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers
                                                  ) 
                            -- La transaction d'origine à annuler doit faire partie des années fiscales subséquentes que la plus ancienne transaction
                            -- en demande d'annulation et faire partie des fichiers de l'IQÉÉ admissibles
                       JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
                                                AND (@bFichiers_Test_Comme_Production = 1 OR F.bFichier_Test = 0) -- Tenir compte ou non des fichiers test
                                                AND F.bInd_Simulation = 0 -- Ne jamais tenir compte des fichiers de simulation
                 WHERE YEAR(C.dtDate_Transaction_A_Annuler) >= @BorneInferieureAnneeFiscale
                UNION ALL
                SELECT TE.tiID_Type_Enregistrement,
                       TIS.iID_Impot_Special,
                       C.iID_Raison_Annulation
                  FROM #tblIQEE_PlusAncienneTransactionConventions C
                       JOIN tblIQEE_TypesEnregistrement TE ON TE.cCode_Type_Enregistrement = '06'
                            -- La transaction doit être en vigueur, avoir été envoyé à RQ, être subséquente à la plus ancienne transaction en demande 
                            -- d'annulation de la convention et ne pas avoir déjà fait l'objet d'une autre demande d'annulation
                       JOIN tblIQEE_ImpotsSpeciaux TIS ON TIS.iID_Convention = C.iID_Convention
                                                             AND TIS.tiCode_Version IN (0,2)
                                                             AND TIS.cStatut_Reponse = 'R'
                                                                 -- Doit être subséquente à la plus ancienne transaction en demande d'annulation
                                                             AND TIS.dtDate_Evenement >= C.dtDate_Transaction_A_Annuler
                                                                 -- Ne pas avoir déjà fait l'objet d'une autre demande d'annulation
                                                             AND NOT EXISTS(
                                                                    SELECT *
                                                                      FROM tblIQEE_Annulations A
                                                                     WHERE A.tiID_Type_Enregistrement = TE.tiID_Type_Enregistrement
                                                                       AND A.iID_Enregistrement_Demande_Annulation = TIS.iID_Impot_Special
                                                                       AND A.iID_Session = @iID_Session
                                                                       AND A.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers
                                                                 )
                            -- La transaction d'origine à annuler doit faire partie des fichiers de l'IQÉÉ admissibles
                       JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = TIS.iID_Fichier_IQEE
                                              AND (@bFichiers_Test_Comme_Production = 1 OR F.bFichier_Test = 0) -- Tenir compte ou non des fichiers test
                                              AND F.bInd_Simulation = 0 -- Ne jamais tenir compte des fichiers de simulation     
                --UNION ALL
                --SELECT TE.tiID_Type_Enregistrement,
                --       RB.iID_Remplacement_Beneficiaire,
                --       C.iID_Raison_Annulation
                --  FROM #tblIQEE_PlusAncienneTransactionConventions C
                --       JOIN tblIQEE_TypesEnregistrement TE ON TE.cCode_Type_Enregistrement = '03'
                --            -- La transaction doit être en vigueur, avoir été envoyé à RQ, être subséquente à la plus ancienne transaction en demande 
                --            -- d'annulation de la convention et ne pas avoir déjà fait l'objet d'une autre demande d'annulation
                --       JOIN tblIQEE_RemplacementsBeneficiaire RB ON RB.iID_Convention = C.iID_Convention
                --                                                AND RB.tiCode_Version IN (0,2)
                --                                                AND RB.cStatut_Reponse = 'R'
                --                                                    -- Doit être subséquente à la plus ancienne transaction en demande d'annulation
                --                                                AND RB.dtDate_Remplacement >= C.dtDate_Transaction_A_Annuler
                --                                                    -- Ne pas avoir déjà fait l'objet d'une autre demande d'annulation
                --                                                AND NOT EXISTS (
                --                                                       SELECT *
                --                                                         FROM tblIQEE_Annulations A
                --                                                        WHERE A.tiID_Type_Enregistrement = TE.tiID_Type_Enregistrement
                --                                                          AND A.iID_Enregistrement_Demande_Annulation = RB.iID_Remplacement_Beneficiaire
                --                                                          AND A.iID_Session = @iID_Session
                --                                                          AND A.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers
                --                                                    )
                --            -- La transaction d'origine à annuler doit faire partie des fichiers de l'IQÉÉ admissibles
                --       JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = RB.iID_Fichier_IQEE
                --                              AND (@bFichiers_Test_Comme_Production = 1 OR F.bFichier_Test = 0) -- Tenir compte ou non des fichiers test
                --                              AND F.bInd_Simulation = 0 -- Ne jamais tenir compte des fichiers de simulation
                --UNION ALL
                --SELECT TE.tiID_Type_Enregistrement,
                --       T.iID_Transfert,
                --       C.iID_Raison_Annulation
                --  FROM #tblIQEE_PlusAncienneTransactionConventions C
                --       JOIN tblIQEE_TypesEnregistrement TE ON TE.cCode_Type_Enregistrement = '04'
                --            -- La transaction doit être en vigueur, avoir été envoyé à RQ, être subséquente à la plus ancienne transaction en demande 
                --            -- d'annulation de la convention et ne pas avoir déjà fait l'objet d'une autre demande d'annulation
                --       JOIN tblIQEE_Transferts T ON T.iID_Convention = C.iID_Convention
                --                                AND T.tiCode_Version IN (0,2)
                --                                AND T.cStatut_Reponse = 'R'
                --                                    -- Doit être subséquente à la plus ancienne transaction en demande d'annulation
                --                                AND T.dtDate_Transfert >= C.dtDate_Transaction_A_Annuler
                --                                    -- Ne pas avoir déjà fait l'objet d'une autre demande d'annulation
                --                                AND NOT EXISTS(
                --                                       SELECT *
                --                                         FROM tblIQEE_Annulations A
                --                                        WHERE A.tiID_Type_Enregistrement = TE.tiID_Type_Enregistrement
                --                                          AND A.iID_Enregistrement_Demande_Annulation = T.iID_Transfert
                --                                          AND A.iID_Session = @iID_Session
                --                                          AND A.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers
                --                                    )
                --            -- La transaction d'origine à annuler doit faire partie des fichiers de l'IQÉÉ admissibles
                --       JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = T.iID_Fichier_IQEE
                --                              AND (@bFichiers_Test_Comme_Production = 1 OR F.bFichier_Test = 0) -- Tenir compte ou non des fichiers test
                --                              AND F.bInd_Simulation = 0 -- Ne jamais tenir compte des fichiers de simulation
                --UNION ALL
                --SELECT TE.tiID_Type_Enregistrement,
                --       PB.iID_Paiement_Beneficiaire,
                --       C.iID_Raison_Annulation
                --  FROM #tblIQEE_PlusAncienneTransactionConventions C
                --       JOIN tblIQEE_TypesEnregistrement TE ON TE.cCode_Type_Enregistrement = '05'
                --            -- La transaction doit être en vigueur, avoir été envoyé à RQ, être subséquente à la plus ancienne transaction en demande 
                --            -- d'annulation de la convention et ne pas avoir déjà fait l'objet d'une autre demande d'annulation
                --       JOIN tblIQEE_PaiementsBeneficiaires PB ON PB.iID_Convention = C.iID_Convention
                --                                             AND PB.tiCode_Version IN (0,2)
                --                                             AND PB.cStatut_Reponse = 'R'
                --                                                 -- Doit être subséquente à la plus ancienne transaction en demande d'annulation
                --                                             AND PB.dtDate_Paiement >= C.dtDate_Transaction_A_Annuler
                --                                                 -- Ne pas avoir déjà fait l'objet d'une autre demande d'annulation
                --                                             AND NOT EXISTS(
                --                                                    SELECT *
                --                                                      FROM tblIQEE_Annulations A
                --                                                     WHERE A.tiID_Type_Enregistrement = TE.tiID_Type_Enregistrement
                --                                                       AND A.iID_Enregistrement_Demande_Annulation = PB.iID_Paiement_Beneficiaire
                --                                                       AND A.iID_Session = @iID_Session
                --                                                       AND A.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers
                --                                                 )
                --            -- La transaction d'origine à annuler doit faire partie des fichiers de l'IQÉÉ admissibles
                --       JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = PB.iID_Fichier_IQEE
                --                              AND (@bFichiers_Test_Comme_Production = 1 OR F.bFichier_Test = 0) -- Tenir compte ou non des fichiers test
                --                              AND F.bInd_Simulation = 0 -- Ne jamais tenir compte des fichiers de simulation            

        PRINT '    Traiter Annulations Conséquences';
        -- Demander les annulations de conséquence
        OPEN curConsequences;
        FETCH NEXT FROM curConsequences INTO @tiID_Type_Enregistrement, @iID_Enregistrement, @iID_Raison_Annulation;

        SET @curSituationSize = 0
        WHILE @@FETCH_STATUS = 0
        BEGIN
            EXECUTE dbo.psIQEE_AjouterDemandeAnnulation @tiID_Type_Enregistrement, @iID_Enregistrement, @iID_Session, @dtDate_Creation_Fichiers, 
                                                        @vcCode_Simulation, @iID_Utilisateur_Creation, @iID_Type_Annulation, @iID_Raison_Annulation, 
                                                        NULL, NULL, NULL, NULL, 
                                                        @vcCode_Message OUTPUT, @iID_Annulation OUTPUT;
            SET @curSituationSize += 1

            FETCH NEXT FROM curConsequences INTO @tiID_Type_Enregistrement, @iID_Enregistrement, @iID_Raison_Annulation;
        END;
        PRINT '        ' + ltrim(str(@curSituationSize, 6)) + ' annulation(s) ajoutée(s)'

        CLOSE curConsequences;
        DEALLOCATE curConsequences;
        
        DROP TABLE #tblIQEE_PlusAncienneTransactionConventions;
    END;
END;

