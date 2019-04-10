/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service        : psIQEE_CreerFichierAnnee
Nom du service        : Créer un fichier de transactions pour une année fiscale 
But                 : Créer un nouveau fichier de transactions pour l’IQÉÉ pour une année fiscale.
Facette                : IQÉÉ

Paramètres d’entrée    :    Paramètre                    Description
                        --------------------------    -----------------------------------------------------------------
                        siAnnee_Fiscale                Année fiscale du fichier de transactions à créer.
                        bFichier_Test                Indicateur si le fichier est crée pour fins d’essais ou si c’est
                                                    un fichier réel.  0=Fichier réel, 1=Fichier test.
                        bFichiers_Test              Indicateur si les fichiers test doivent être tenue en compte dans
                                                      la production du fichier.  Normalement ce n’est pas le cas.  Mais
                                                    pour fins d’essais et de simulations il est possible de tenir compte
                                                    des fichiers tests comme des fichiers de production.
                        bDenominalisation            Indicateur de retrait des noms dans le fichier des demandes.  
                                                    Les tables des types d’enregistrement contiennent les vrais noms et
                                                    prénoms, mais le fichier physique des transactions contiendra 
                                                    « Universitas » en remplacement.
                        vcCode_Simulation            Le code de simulation est au choix du programmeur.  Il permet
                                                    d’associer un code à un ou plusieurs fichiers de transactions.  
                                                    Si ce paramètre est présent, le fichier est automatiquement considéré
                                                    comme un fichier test et comme un fichier de simulation.  Les
                                                    fichiers de test qui ne sont pas des simulations sont visibles aux
                                                    utilisateurs.  Par contre, les fichiers de simulation ne sont pas
                                                    visibles aux utilisateurs.  Ils sont accessibles seulement aux
                                                    programmeurs.
                        vcNo_Convention             Numéro unique de la convention pour laquelle la création des fichiers est demandée.
                        vcChemin_Fichier            Chemin du répertoire dans lequel sera déposé le fichier des
                                                    transactions.  Paramètre optionnel.  S’il n’est pas présent, le fichier 
                                                    physique ne sera pas crée.
                        bArretPremiereErreur        Indicateur si le traitement doit s’arrêter après le premier message
                                                    d’erreur.
                        cCode_Portee                Code permettant de définir la portée des validations.
                                                    « T » =  Toutes les validations
                                                    « A » = Toutes les validations excepter les avertissements (Erreurs
                                                            seulement)
                                                    « I » = Uniquement les validations sur lesquelles il est possible
                                                            d’intervenir afin de les corriger
                        iID_Utilisateur_Creation    Identifiant de l’utilisateur qui demande la création du fichier.
                        vcCourrielsDestination        Liste des courriels qui devront recevoir un courriel de confirmation du
                                                    résultat du traitement.  S’il n’est pas spécifié, il n'y a pas de courriel.
                        bTraiterAnnulations            Indicateur si la création du fichier doit traiter ou non les annulations
                            Manuelles                demandées manuellement.
                        bTraiterAnnulations            Indicateur si la création du fichier doit traiter ou non les annulations
                            Automatiques            déterminées automatiquement.
                        cID_Langue                    Langue du traitement.
                        bConsequence_Annulation        Indicateur si le fichier de l'année fiscale est la conséquence seulement
                                                    d'annulations ou aussi parce que l'utilisateur en a fait la demande.
                        iID_Session                    Identifiant de session identifiant de façon unique la création des
                                                    fichiers de transactions
                        dtDate_Creation_Fichiers    Date et heure de la création des fichiers identifiant de façon unique avec
                                                    identifiant de session, la création des    fichiers de transactions.
                        vcNo_Convention                Numéro de la convention pour laquelle la création des
                                                    fichiers est demandée.
                        bit_CasSpecial                Indicateur pour permettre la résolution de cas spéciaux sur des T02 dont le délai de traitement est dépassé. 
                                                    
Exemple d’appel        :    Cette procédure doit être appelée uniquement par "psIQEE_CreerFichiers".

Paramètres de sortie:    
    Champ                   Description
    --------------------    ---------------------------------
    iCode_Retour            >0 = Identifiant du nouveau fichier de transactions
                                                                                    0 = Aucune transaction dans le fichier.
                                                                                        Création du fichier annulée.

Historique des modifications:
    Date        Programmeur             Description                                
    ----------  --------------------    -----------------------------------------
    2009-01-29  Éric Deshaies           Création du service                            
    2012-08-27  Stéphane Barbeau        Appels des stored procs pour T03 et T06-91,01,22 et 23.
    2012-12-13  Stéphane Barbeau        Ajustements de appels des stored procs T06-91,01,22; Nouveau paramètre @iID_Utilisateur_Creation
    2014-02-28  Stéphane Barbeau        Nouveau paramètre @bPremier_Envoi_Originaux
                                        Ajustements de appels de psIQEE_CreerTransactions02 avec nouveau paramètre @bPremier_Envoi_Originaux
    2014-08-06  Stéphane Barbeau        Ajout du paramètre bit_CasSpecial pour permettre la résolution de cas spéciaux sur des T02 dont le délai de traitement est dépassé. 
    2015-10-22  Stéphane Barbeau        Appel de psIQEE_CreerTransactions06_41.
    2015-12-01  Steeve Picard           Utilisation de la nouvelle fonction «fntCONV_ObtenirStatutConventionEnDate_PourTous»
    2016-02-01  Steeve Picard           Permettre d'exécuter pour une liste de nos de convention via la table #TB_ListeConvention
    2016-04-08  Steeve Picard           Ajout de l'appel à la Stored Proc T04-03
    2016-06-17  Steeve Picard           Ajout de PRINT au début & à la fin avec la durée d'exécution pour mieux suivre le déroulement
    2017-03-27  Steeve Picard           Ajout de la transaction T(04)-01
    2017-06-21  Steeve Picard           Permettre de déclarer les avant 2017 si c'est un cas spécial réglé
    2017-07-10  Steeve Picard           Autoriser seulement la création de T02 des 3 dernières années
    2017-08-03  Steeve Picard           Ajout des champs «ConventionStateID & bReconnuRQ» à la table «#TB_ListeConventions»
    2017-09-06  Steeve Picard           Ajout de la transaction T(06)-02 : Remplacement de bénéficiaire reconnu qui ne sont pas frère & soeur
    2017-11-15  Steeve Picard           La T06-02 ne s'applique qu'au contrat familiale mais qu'on a pas chez Uniersitas
    2017-11-09  Steeve Picard           Ajout du paramètre «siAnnee_Fiscale» à la fonction «fntIQEE_ConventionConnueRQ_PourTous»
    2018-02-08  Steeve Picard           Nouveau paramètre «siAnnee_Fiscale» ajouter à toutes les procédure «psIQEE_CreerTransactions_??»
    2018-02-22  Steeve Picard           Élimination des paramètres «@dtDebutCotisation & @dtFinCotisation» de la procédure «psIQEE_CreerTransactions02»
    2018-03-20  Steeve Picard           Ajustement pour filtrer les conventions pour «ConventionStateID»
    2018-06-01  Steeve Picard           Permettre l'utilisation de «Wildcard» pour le paramètre «@vcNo_Convention»
    2018-07-09  Steeve Picard           Ajout du paramètre «@vcCode_ListeTransaction» pour sélectionner que quelques types de déclaration à RQ, si NULL alors tous
***********************************************************************************************************************/
CREATE PROCEDURE dbo.psIQEE_CreerFichierAnnee
(
    @siAnnee_Fiscale SMALLINT,
    @bPremier_Envoi_Originaux BIT,
    @bFichier_Test BIT,
    @vcCode_Simulation VARCHAR(100),
    @vcNo_Convention varchar(MAX),
    @vcChemin_Fichier VARCHAR(150),
    @bArretPremiereErreur BIT,
    @cCode_Portee CHAR(1),
    @iID_Utilisateur_Creation INT,
    @cID_Langue CHAR(3),
    @bConsequence_Annulation BIT,
    @iID_Session INT,
    @dtDate_Creation_Fichiers DATETIME,
    @bit_CasSpecial BIT,
    @vcCode_ListeTransaction AS VARCHAR(200) = ''
)
AS
BEGIN
    DECLARE @iID_Fichier_IQEE INT,
            @dtDebutCotisation DATETIME,
            @dtFinCotisation DATETIME,
            @iResult INT

    DECLARE @TB_TypeEtSousType TABLE (vcCode VARCHAR(5))

    DECLARE @StartTime DATETIME = GetDate()

    PRINT ' '
    PRINT 'EXEC psIQEE_CreerFichierAnnee - ' + Str(@siAnnee_Fiscale, 4) + ' - Started at ' + Convert(varchar, @StartTime, 120)
    PRINT Replace(Space(70), ' ', '=')
            
    -- Initialisation de variables
    SET @iID_Fichier_IQEE = 0

    INSERT INTO @TB_TypeEtSousType (vcCode)
    SELECT cCode_Type_SousType
      FROM [dbo].[vwIQEE_Enregistrement_TypeEtSousType]
     WHERE CHARINDEX(cCode_Type_SousType, @vcCode_ListeTransaction) <> 0
           OR LEN(RTRIM(@vcCode_ListeTransaction)) = 0

    -- Considérer toutes les validations si ce n'est pas spécifié
    IF @cCode_Portee IS NULL
        SET @cCode_Portee = 'T'
    
    -- 2016-02-01    Créer la table s'il elle n'existe pas pour compatibilité
    IF Object_ID('tempDB..#TB_ListeConvention') IS NOT NULL
        --PRINT 'Il y a déjà une table temporaire « #TB_ListeConvention » dans la session courante !'
        RAISERROR('Il y a déjà une table temporaire « #TB_ListeConvention » dans la session courante !', 16, 1)
    ELSE    
        CREATE TABLE #TB_ListeConvention (
            RowNo INT Identity(1,1), 
            ConventionID int, 
            ConventionNo varchar(20), 
            ConventionStateID varchar(5), 
            dtReconnue_RQ DATE
        )

    -- Vérifier s'il y a un conflit avec le paramètre @ListeNoConventions
    IF IsNull(@vcNo_Convention, '') <> ''
    BEGIN
        INSERT INTO #TB_ListeConvention (ConventionID, ConventionNo, ConventionStateID)
        SELECT C.ConventionID, C.ConventionNo, S.ConventionStateID 
          FROM dbo.Un_Convention C
               LEFT JOIN dbo.fntGENE_SplitIntoTable(@vcNo_Convention, ',') L ON C.ConventionNo = L.strField
               LEFT JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(Str(@siAnnee_Fiscale, 4)+'-12-31', NULL) S ON S.conventionID = C.ConventionID
         WHERE (L.strField IS NOT NULL OR C.ConventionNo LIKE @vcNo_Convention)
           AND ( (ISNULL(S.ConventionStateID, 'PRP') = 'PRP' AND YEAR(C.dtEntreeEnVigueur) = @siAnnee_Fiscale)
                 OR ISNULL(S.ConventionStateID, '') IN ('TRA', 'REE')
                 OR (ISNULL(S.ConventionStateID, '') = 'FRM' AND YEAR(S.StartDate) = @siAnnee_Fiscale) 
               )

        IF @@rowCount > 1
            PRINT 'Génère pour les conventions : ' + Replace(@vcNo_Convention, ',', Char(13) + Char(10) + Space(30))
        ELSE
            PRINT 'Génère pour la convention : ' + @vcNo_Convention
    END
    ELSE
    BEGIN
        PRINT 'Génère pour toutes les conventions'

        INSERT INTO #TB_ListeConvention (ConventionID, ConventionNo, ConventionStateID)
        SELECT DISTINCT C.ConventionID, C.ConventionNo, S.ConventionStateID
          FROM dbo.Un_Convention C
               LEFT JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(Str(@siAnnee_Fiscale, 4)+'-12-31', NULL) S ON S.conventionID = C.ConventionID
         WHERE (ISNULL(S.ConventionStateID, 'PRP') = 'PRP' AND YEAR(C.dtEntreeEnVigueur) = @siAnnee_Fiscale)
            OR ISNULL(S.ConventionStateID, '') IN ('TRA', 'REE')
            OR (ISNULL(S.ConventionStateID, '') = 'FRM' AND YEAR(S.StartDate) = @siAnnee_Fiscale) 
    END

    UPDATE C SET dtReconnue_RQ = RQ.dtReconnue_RQ
      FROM #TB_ListeConvention C
           JOIN dbo.fntIQEE_ConventionConnueRQ_PourTous(NULL, @siAnnee_Fiscale) RQ ON RQ.iID_Convention = C.ConventionID

    --------------------------------------------------------------------
    -- Créer les paramètres IQÉÉ de l’année fiscale s’ils n’existent pas
    --------------------------------------------------------------------
    INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
    VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CreerFichierAnnee               '+
            '- Créer paramètres IQÉÉ année fiscale si existent pas')

    IF NOT EXISTS(SELECT * FROM dbo.fntIQEE_RechercherParametres(@siAnnee_Fiscale, 1))
        EXECUTE dbo.psIQEE_AjouterParametres @siAnnee_Fiscale, NULL


    ------------------------
    -- Créer le fichier IQÉÉ
    ------------------------
    INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
    VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CreerFichierAnnee               '+
            '- Créer fichier IQÉÉ ' + Str(@siAnnee_Fiscale,4))

    DECLARE
        @dtDate_Creation DATETIME,
        @vcNom_Fichier VARCHAR(50),
        @iID_Parametres_IQEE INT,
        @tiID_Type_Fichier TINYINT,
        @tiID_Statut_Fichier TINYINT,
        @bInd_Simulation BIT,
        @dtDate_Maximale DATETIME,
        @vcCommentaires VARCHAR(100)

    -- Déterminer le nom du fichier en s'assurant qu'il y ai au moins 1 seconde de différence entre chaque fichier
    WAITFOR DELAY '00:00:03'; -- Le délais laisse la chance à la base de données de compléter l'enregistrement des autres 
                              -- fichiers possiblement en cours de traitement en même temps
    SET @dtDate_Creation = GETDATE()

    SELECT @dtDate_Maximale = MAX(F.dtDate_Creation)
    FROM tblIQEE_Fichiers F

    IF ABS(DATEDIFF(SECOND,@dtDate_Maximale,@dtDate_Creation)) < 1
        IF @dtDate_Maximale > @dtDate_Creation
            SET @dtDate_Creation = DATEADD(SECOND,1,@dtDate_Maximale)
        ELSE
            SET @dtDate_Creation = DATEADD(SECOND,1,@dtDate_Creation)

    SET @vcNom_Fichier = 'NOM TEMPORAIRE'

    -- Sélectionner les dates applicables aux transactions
    -- Déterminer la série de paramètres applicables
    SELECT @dtDebutCotisation = P.dtDate_Debut_Cotisation,
           @dtFinCotisation = P.dtDate_Fin_Cotisation,
           @iID_Parametres_IQEE = P.iID_Parametres_IQEE
    FROM dbo.fntIQEE_RechercherParametres(@siAnnee_Fiscale, 1) P

    -- Déterminer le type du fichier
    SELECT @tiID_Type_Fichier = TF.tiID_Type_Fichier
    FROM tblIQEE_TypesFichier TF
    WHERE TF.vcCode_Type_Fichier = 'DEM'

    -- Déterminer le statut du fichier
    SELECT @tiID_Statut_Fichier = SF.tiID_Statut_Fichier
    FROM tblIQEE_StatutsFichier SF
    WHERE SF.vcCode_Statut = 'CRE'

    IF @vcCode_Simulation IS NOT NULL
        SET @bInd_Simulation = 1
    ELSE
        SET @bInd_Simulation = 0

    IF @vcNo_Convention IS NOT NULL
        SET @vcCommentaires = dbo.fnGENE_ObtenirParametre('IQEE_CREER_FICHIERS_CONVENTION',NULL,
                              @cID_Langue,NULL,NULL,NULL,NULL)+@vcNo_Convention
    ELSE
        SET @vcCommentaires = NULL

    -- Créer le fichier des transactions
    INSERT INTO dbo.tblIQEE_Fichiers (
            --siAnnee_Fiscale,
            dtDate_Creation, iID_Parametres_IQEE, tiID_Type_Fichier, bFichier_Test, tiID_Statut_Fichier,
            vcNom_Fichier, iID_Utilisateur_Creation, vcChemin_Fichier, vcCode_Simulation, bInd_Simulation,
            tCommentaires, iID_Session, dtDate_Creation_Fichiers
        )
    VALUES(
        --@siAnnee_Fiscale,
        @dtDate_Creation, @iID_Parametres_IQEE, @tiID_Type_Fichier, @bFichier_Test, @tiID_Statut_Fichier,
        @vcNom_Fichier, @iID_Utilisateur_Creation, @vcChemin_Fichier, @vcCode_Simulation, @bInd_Simulation,
        @vcCommentaires, @iID_Session, @dtDate_Creation_Fichiers
    )
    SET @iID_Fichier_IQEE = SCOPE_IDENTITY()

    --------------------------------------------------------------------
    -- Valider et créer les transactions de chaque type d’enregistrement
    --------------------------------------------------------------------
-- TODO: A faire
    -- Les transactions d'événements spéciaux s'applique uniquement à partir de l'année fiscale 2008
    IF @siAnnee_Fiscale > 2007
    BEGIN
        
        -- Transactions du type d'enregistrement 03 - Remplacement de bénéficiaire
        IF EXISTS(SELECT * FROM @TB_TypeEtSousType WHERE vcCode = '03') 
        BEGIN
            INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
            VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CreerFichierAnnee               - Transactions type 03: Remplacement de bénéficiaire.  Appel "psIQEE_CreerTransactions03')
            EXECUTE dbo.psIQEE_CreerTransactions03 @iID_Fichier_IQEE, @siAnnee_Fiscale, @bArretPremiereErreur, @cCode_Portee, @bit_CasSpecial
        END
        
        --  Transactions du type d'enregistrement 04 - Transfert
        IF EXISTS(SELECT * FROM @TB_TypeEtSousType WHERE vcCode like '04-__')
        BEGIN
            --  Sous-type 01 - Transfert cédant vers un autre promoteur
            IF EXISTS(SELECT * FROM @TB_TypeEtSousType WHERE vcCode like '04-01') BEGIN
                INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
                VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CreerFichierAnnee               - Transactions type 04-01: Transfert cédant vers un autre promoteur.  Appel "psIQEE_CreerTransactions04_01')
                EXECUTE dbo.psIQEE_CreerTransactions04_01 @iID_Fichier_IQEE, @siAnnee_Fiscale, @bArretPremiereErreur, @cCode_Portee, @bit_CasSpecial
            END

            --  Sous-type 02 - Transfert cessionnaire d'un autre promoteur
            IF EXISTS(SELECT * FROM @TB_TypeEtSousType WHERE vcCode like '04-02') BEGIN
                INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
                VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CreerFichierAnnee               - Transactions type 04-02: Transfert cessionnaire d?un autre promoteur.  Appel "psIQEE_CreerTransactions04_02')
                EXECUTE dbo.psIQEE_CreerTransactions04_02 @iID_Fichier_IQEE, @siAnnee_Fiscale, @bArretPremiereErreur, @cCode_Portee, @bit_CasSpecial
            END

            --  Sous-type 03 - Transfert interne entre contrat
            IF EXISTS(SELECT * FROM @TB_TypeEtSousType WHERE vcCode like '04-03') BEGIN
                INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
                VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CreerFichierAnnee               - Transactions type 04-03: Transfert entre régimes.  Appel "psIQEE_CreerTransactions04_03')
                EXECUTE dbo.psIQEE_CreerTransactions04_03 @iID_Fichier_IQEE, @siAnnee_Fiscale, @bArretPremiereErreur, @cCode_Portee, @bit_CasSpecial
            END
        END 
        
        --  Transactions du type d'enregistrement 05 - Paiement de bourse
        IF EXISTS(SELECT * FROM @TB_TypeEtSousType WHERE vcCode like '05-__') 
        BEGIN
            --  Sous-type 05 - Paiement aux bénéficiaires
            IF EXISTS(SELECT * FROM @TB_TypeEtSousType WHERE vcCode like '05-01') BEGIN
                INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
                VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CreerFichierAnnee               - Transactions type 05-01: Paiement d?aide aux études (PAE).  Appel "psIQEE_CreerTransactions05_01')
                EXECUTE dbo.psIQEE_CreerTransactions05_01 @iID_Fichier_IQEE, @siAnnee_Fiscale, @bArretPremiereErreur, @cCode_Portee, @bit_CasSpecial
            END 

            ----  Sous-type 02 - Paiement pour études post-secondaires (EPS)
            --IF EXISTS(SELECT * FROM @TB_TypeEtSousType WHERE vcCode like '05-02') BEGIN
            --    INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
            --    VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121) + ' - psIQEE_CreerFichierAnnee               - Transactions type 05-02: Paiement pour études post-secondaires (EPS).  Appel "psIQEE_CreerTransactions05_02')
            --    EXECUTE dbo.psIQEE_CreerTransactions05_02 @iID_Fichier_IQEE, @siAnnee_Fiscale, @bArretPremiereErreur, @cCode_Portee, @bit_CasSpecial
            --END
        END 
        
        --  Transactions du type d'enregistrement 06 - Impôts spécials
        IF EXISTS(SELECT * FROM @TB_TypeEtSousType WHERE vcCode like '06-__')
        BEGIN
            --  Sous-type 01 - Remplacement de bénéficiaire non reconnu
            IF EXISTS(SELECT * FROM @TB_TypeEtSousType WHERE vcCode like '06-01') BEGIN
                INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
                VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CreerFichierAnnee               - Transactions type 06-01: Impôt Spécial – Remplacement de bénéficiaire non reconnu.  Appel "psIQEE_CreerTransactions06_01')
                EXECUTE dbo.psIQEE_CreerTransactions06_01 @iID_Fichier_IQEE, @siAnnee_Fiscale, @bArretPremiereErreur, @cCode_Portee, @iID_Utilisateur_Creation, @bit_CasSpecial
            END
        
            ----  Sous-type 02 - Remplacement ou ajout de bénéficiaire dans un plan familiale
            --IF EXISTS(SELECT * FROM @TB_TypeEtSousType WHERE vcCode like '06-02') BEGIN
            --    --  *** Universitas ne fait pas de plan à plusieurs bénéficiaires
            --    INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
            --    VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CreerFichierAnnee               - Transactions type 06-02: Impôt Spécial – Remplacement ou ajout de bénéficiaire dans un paln familiale.  Appel "psIQEE_CreerTransactions06_02')
            --    EXECUTE dbo.psIQEE_CreerTransactions06_02 @iID_Fichier_IQEE, @siAnnee_Fiscale, @bArretPremiereErreur, @cCode_Portee, @iID_Utilisateur_Creation, @bit_CasSpecial
            --END

            ----  Sous-type 11 - Transfert inadmissible
            --IF EXISTS(SELECT * FROM @TB_TypeEtSousType WHERE vcCode like '06-11') BEGIN
            --    INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
            --    VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CreerFichierAnnee               - Transactions type 06-02: Impôt Spécial – Remplacement ou ajout de bénéficiaire dans un paln familiale.  Appel "psIQEE_CreerTransactions06_02')
            --    EXECUTE dbo.psIQEE_CreerTransactions06_11 @iID_Fichier_IQEE, @siAnnee_Fiscale, @bArretPremiereErreur, @cCode_Portee, @iID_Utilisateur_Creation, @bit_CasSpecial
            --END
        
            --  Sous-type 22 - Retrait prématuré de cotisations
            IF EXISTS(SELECT * FROM @TB_TypeEtSousType WHERE vcCode like '06-22') BEGIN
                INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
                VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CreerFichierAnnee               - Transactions type 06-22: Impôt Spécial – Retrait prématuré de cotisations.  Appel "psIQEE_CreerTransactions06_22"')
                EXECUTE dbo.psIQEE_CreerTransactions06_22 @iID_Fichier_IQEE, @siAnnee_Fiscale, @bArretPremiereErreur, @cCode_Portee, @iID_Utilisateur_Creation, @bit_CasSpecial
            END
        
            --  Sous-type 23 - Retrait et bénéficiaire admissible au PAE
            IF EXISTS(SELECT * FROM @TB_TypeEtSousType WHERE vcCode like '06-23') BEGIN
                INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
                VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CreerFichierAnnee               - Transactions type 06-23: Impôt Spécial – Retrait et bénéficiaire admissible au PAE.  Appel "psIQEE_CreerTransactions06_23')
                EXECUTE dbo.psIQEE_CreerTransactions06_23 @iID_Fichier_IQEE, @siAnnee_Fiscale, @bArretPremiereErreur, @cCode_Portee, @bit_CasSpecial
            END
            ;
            ----  Sous-type 24 - Retrait de cotisations excédentaires
            --IF EXISTS(SELECT * FROM @TB_TypeEtSousType WHERE vcCode like '06-24') BEGIN
            --    INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
            --    VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CreerFichierAnnee               - Transactions type 06-02: Impôt Spécial – Remplacement ou ajout de bénéficiaire dans un paln familiale.  Appel "psIQEE_CreerTransactions06_02')
            --    EXECUTE dbo.psIQEE_CreerTransactions06_24 @iID_Fichier_IQEE, @siAnnee_Fiscale, @bArretPremiereErreur, @cCode_Portee, @iID_Utilisateur_Creation, @bit_CasSpecial
            --END
            ;
            --  Sous-type 31 - Paiement versé à un établissement d'enseignement (PEE)
            IF EXISTS(SELECT * FROM @TB_TypeEtSousType WHERE vcCode like '06-31') BEGIN
                INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
                VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CreerFichierAnnee               - Transactions type 06-31: Impôt Spécial – Paiement versé à un établissement d?enseignement.  Appel "psIQEE_CreerTransactions06_23')
                EXECUTE dbo.psIQEE_CreerTransactions06_31 @iID_Fichier_IQEE, @siAnnee_Fiscale, @bArretPremiereErreur, @cCode_Portee, @iID_Utilisateur_Creation, @bit_CasSpecial
            END
            ;
            ----  Sous-type 32 - PAE versé à un autre bénéficiaire
            --IF EXISTS(SELECT * FROM @TB_TypeEtSousType WHERE vcCode like '06-32') BEGIN
            --    INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
            --    VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CreerFichierAnnee               - Transactions type 06-02: Impôt Spécial – Remplacement ou ajout de bénéficiaire dans un paln familiale.  Appel "psIQEE_CreerTransactions06_02')
            --    EXECUTE dbo.psIQEE_CreerTransactions06_32 @iID_Fichier_IQEE, @siAnnee_Fiscale, @bArretPremiereErreur, @cCode_Portee, @iID_Utilisateur_Creation, @bit_CasSpecial
            --END
            ;
            --  Sous-type 41 - Paiement de revenus accumulés (PRA)
            IF EXISTS(SELECT * FROM @TB_TypeEtSousType WHERE vcCode like '06-41') BEGIN
                INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
                VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CreerFichierAnnee               - Transactions type 06-41: Impôt Spécial – Déclaration des PRAs.  Appel "psIQEE_CreerTransactions06_41')
                EXECUTE dbo.psIQEE_CreerTransactions06_41 @iID_Fichier_IQEE, @siAnnee_Fiscale, @bArretPremiereErreur, @cCode_Portee, @iID_Utilisateur_Creation, @bit_CasSpecial
            END

            --  Sous-type 91 - Fermeture du contrat
            IF EXISTS(SELECT * FROM @TB_TypeEtSousType WHERE vcCode like '06-91') BEGIN
                INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
                VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CreerFichierAnnee               - Transactions type 06-91: Impôt Spécial –Fermeture du contrat.  Appel "psIQEE_CreerTransactions06_91')
                EXECUTE dbo.psIQEE_CreerTransactions06_91 @iID_Fichier_IQEE, @siAnnee_Fiscale, @bArretPremiereErreur, @cCode_Portee, @iID_Utilisateur_Creation, @bit_CasSpecial
            END
        END

        IF EXISTS(SELECT * FROM @TB_TypeEtSousType WHERE vcCode = '02') AND @siAnnee_Fiscale >= Year(GetDate()) - 3
        BEGIN
            -- Transactions du type d'enregistrement 02 - Demande de l'IQÉÉ
            INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
            VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CreerFichierAnnee               '+
                    '- Transactions type 02: Demande de l?IQÉÉ.  Appel "psIQEE_CreerTransactions02"')
            EXECUTE dbo.psIQEE_CreerTransactions02 @iID_Fichier_IQEE, @siAnnee_Fiscale, @bPremier_Envoi_Originaux, 
                                                   @bArretPremiereErreur, @cCode_Portee, @bConsequence_Annulation, @iID_Session,
                                                   @dtDate_Creation_Fichiers, @cID_Langue, @bit_CasSpecial
        END
    END

    DECLARE @EndTime DATETIME = GetDate()
    DECLARE @ElapsedTime datetime = @EndTime - @StartTime
    PRINT ''
    PRINT '    ' + Replace(Space(67), ' ', '=')
    PRINT '    psIQEE_CreerFichierAnnee - ' + Str(@siAnnee_Fiscale, 4) + ' - terminated at ' + Convert(varchar, @EndTime, 120) + ' (Elapsed time: ' + Convert(varchar, @ElapsedTime, 120) + ')'


    -- Retourner l'identifiant du nouveau fichier
    RETURN @iID_Fichier_IQEE
END
