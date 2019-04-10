/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service : psIQEE_CreerTransactions06_02
Nom du service  : Créer les transactions de type 06 sous type 02 - Remplacement ou ajout de bénéficiaire dans un plan familiale
But             : Sélectionner, valider et créer les transactions de type 06 – Impôt spécial, 02 - Remplacement ou ajout de 
                  bénéficiaire dans un plan familiale qui ne sont pas frère & soeur.
Facette         : IQÉÉ

Paramètres d’entrée :
    Paramètre               Description
    --------------------    -----------------------------------------------------------------
    iID_Fichier_IQEE        Identifiant du nouveau fichier de transactions dans lequel les transactions 06-01 doivent être créées.
    bFichiers_Test          Indicateur si les fichiers test doivent être tenue en compte dans la production du fichier.  
                            Normalement ce n’est pas le cas, mais pour fins d’essais et de simulations il est possible de tenir compte
                            des fichiers tests comme des fichiers de production.  S’il est absent, les fichiers test ne sont pas considérés.
    bArretPremiereErreur    Indicateur si le traitement doit s’arrêter après le premier message d’erreur.
                            S’il est absent, les validations n’arrêtent pas à la première erreur.
    cCode_Portee            Code permettant de définir la portée des validations.
                                « T » = Toutes les validations
                                « A » = Toutes les validations excepter les avertissements (Erreurs
                                        seulement)
                                « I » = Uniquement les validations sur lesquelles il est possible
                                        d’intervenir afin de les corriger
                                S’il est absent, toutes les validations sont considérées.
    bit_CasSpecial          Indicateur pour permettre la résolution de cas spéciaux sur des T02 dont le délai de traitement est dépassé. 

Exemple d’appel : Cette procédure doit être appelée uniquement par "psIQEE_CreerFichierAnnee".

Paramètres de sortie:
    Champ               Description
    ------------        ------------------------------------------
    iCode_Retour        = 0 : Exécution terminée normalement
                        < 0 : Erreur de traitement

Historique des modifications:
    Date        Programmeur             Description
    ----------  --------------------    --------------------------------------------------------------------------
    2017-08-31  Steeve Picard           Création du service
    2017-09-27  Steeve Picard           Utilisation de la fonction «dbo.fntOPER_Active» pour les retrouver les opéraitions
    2017-11-07  Steeve Picard           Réajustement dû au changement de la T03 pour valider tous les changements bénéficiaires
    2017-11-15  Steeve Picard           La T06-02 ne s'applique qu'au contrat familiale mais qu'on a pas chez Uniersitas
    2018-02-08  Steeve Picard           Déplacement de «siAnnee_Fiscale» de la table «tblIQEE_Fichiers» vers les tables d'évèments «tblIQEE_ImpotsSpeciaux»
    2018-02-26  Steeve Picard           Empêcher que la «dtFinCotisation» soit plus grande que la dernière fin de mois
    2018-03-20  Steeve Picard           Ajout d'un paramètre «@StartDate» à la fonction «fntOPER_Active»
    2018-06-06  Steeve Picard           Modificiation de la gestion des retours d'erreur par RQ
*********************************************************************************************************************/
CREATE PROCEDURE dbo.psIQEE_CreerTransactions06_02
(
    @iID_Fichier_IQEE INT, 
    @siAnnee_Fiscale SMALLINT,
    @bArretPremiereErreur BIT, 
    @cCode_Portee CHAR(1), 
    @iID_Utilisateur_Creation INT, 
    @bit_CasSpecial BIT,
    @tiCode_Version TINYINT = 0
)
AS
BEGIN
    SET NOCOUNT ON

    PRINT ''
    PRINT 'Déclaration de l?impôt spécial d?un remplacement de bénéficiaire reconnu qui ne sont pas frère/soeur ayant de la majoré (T06-02) pour ' + STR(@siAnnee_Fiscale, 4)
    PRINT '------------------------------------------------------------------------------------------------------------------------------------------'
    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' EXEC psIQEE_CreerTransactions06_02 started'

    BEGIN
        PRINT '   *** Déclaration non-implanté car Universitas n''a aucune convention avec plusieurs bénéficiaire'
        RETURN
    END 

    IF Object_ID('tempDB..#TB_ListeConvention') IS NULL
        RAISERROR ('La table « #TB_ListeConvention (RowNo INT Identity(1,1), ConventionID int, ConventionNo varchar(20) » est abesente ', 16, 1)

    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Identifie le(s) convention(s)'
    DECLARE @iCount int = (SELECT Count(*) FROM #TB_ListeConvention)
    IF @iCount > 0
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '   - ' + LTrim(Str(@iCount)) + ' conventions à génèrées'

    DECLARE @StartTimer datetime = GetDate(),
            --@WhileTimer datetime,
            @QueryTimer datetime,
            @ElapseTime datetime,
            --@IntervalPrint INT = 5000,
            @MaxRow INT = 0
            --,@IsDebug bit = dbo.fn_IsDebug()

    --  Déclaration des variables
    BEGIN 
        DECLARE 
            @tiID_TypeEnregistrement TINYINT,               @iID_SousTypeEnregistrement INT,
            @dtDebutCotisation DATETIME,                    @dtFinCotisation DATETIME,
            @dtMaxCotisation DATETIME = DATEADD(DAY, -DAY(GETDATE()), GETDATE())
    
        -- Sélectionner dates applicables aux transactions
        SELECT @dtDebutCotisation = Str(@siAnnee_Fiscale, 4) + '-01-01 00:00:00',
                @dtFinCotisation = STR(@siAnnee_Fiscale, 4) + '-12-31 23:59:59'

        IF @dtFinCotisation > @dtMaxCotisation
            SET @dtFinCotisation = @dtMaxCotisation
    END

    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Récupère les IDs du type & sous-type pour ce type d?enregistrement'
    SELECT 
        @tiID_TypeEnregistrement = tiID_Type_Enregistrement,
        @iID_SousTypeEnregistrement = iID_Sous_Type
    FROM
        dbo.vwIQEE_Enregistrement_TypeEtSousType 
    WHERE
        cCode_Type_Enregistrement = '06'
        AND cCode_Sous_Type = '02'

    DECLARE @TB_FichierIQEE TABLE (
                iID_Fichier_IQEE INT, 
                --siAnnee_Fiscale INT, 
                dtDate_Creation DATE, 
                dtDate_Paiement DATE
            )

    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Récupère les fichiers IQEE'
    INSERT INTO @TB_FichierIQEE 
        (iID_Fichier_IQEE, /*siAnnee_Fiscale,*/ dtDate_Creation, dtDate_Paiement)
    SELECT DISTINCT 
        iID_Fichier_IQEE, /*siAnnee_Fiscale,*/ dtDate_Creation, dtDate_Paiement
    FROM 
        dbo.tblIQEE_Fichiers F
        JOIN dbo.tblIQEE_TypesFichier T ON T.tiID_Type_Fichier = F.tiID_Type_Fichier
    WHERE
        0 = 0 --T.bTeleversable_RQ <> 0
        AND (
                (bFichier_Test = 0  AND bInd_Simulation = 0)
                OR iID_Fichier_IQEE = @iID_Fichier_IQEE
            )

    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Récupération des conventions à déclarer'
    BEGIN
        IF OBJECT_ID('tempdb..#TB_Convention_06_02') IS NOT NULL
            DROP TABLE #TB_Convention_06_02

        PRINT '   ' + Convert(varchar(20), GetDate(), 120) + '   - Récupère les conventions ayant eu une fermeture du contrat'
        SET @QueryTimer = GetDate()
    
        SET ROWCOUNT @MaxRow

        ;WITH CTE_Remplacement AS (
            SELECT DISTINCT
                RB.iID_Remplacement_Beneficiaire, 
                RB.iID_Changement_Beneficiaire,
                RB.iID_Fichier_IQEE,
                RB.tiCode_Version, 
                RB.cStatut_Reponse,
                RB.iID_Convention,
                RB.dtDate_Remplacement,  
                RB.bLien_Frere_Soeur,
                RB.bInd_Remplacement_Reconnu,
                iID_Beneficiaire = RB.iID_Ancien_Beneficiaire, 
                vcNAS = RB.vcNAS_Ancien_Beneficiaire, 
                vcNom = RB.vcNom_Ancien_Beneficiaire, 
                vcPrenom = RB.vcPrenom_Ancien_Beneficiaire, 
                dtNaissance = RB.dtDate_Naissance_Ancien_Beneficiaire, 
                tiSexe = RB.tiSexe_Ancien_Beneficiaire,
                RowNum = ROW_NUMBER() OVER (PARTITION BY RB.iID_Changement_Beneficiaire ORDER BY RB.iID_Remplacement_Beneficiaire DESC)
            FROM     
                dbo.tblIQEE_RemplacementsBeneficiaire RB
                JOIN #TB_ListeConvention X ON X.ConventionID = RB.iID_Convention
            WHERE 0 = 0
                AND RB.dtDate_Remplacement BETWEEN @dtDebutCotisation AND @dtFinCotisation
                AND X.dtReconnue_RQ IS NOT NULL
        )
        SELECT 
            ConventionID = RB.iID_Convention, 
            ConventionNo = (SELECT ConventionNo FROM dbo.Un_Convention WHERE ConventionID = RB.iID_Convention), 
            iID_Remplacement = RB.iID_Remplacement_Beneficiaire, 
            RB.dtDate_Remplacement,  RB.iID_Beneficiaire, RB.vcNAS, RB.vcNom, RB.vcPrenom, RB.dtNaissance, RB.tiSexe
        INTO
            #TB_Convention_06_02
        FROM 
            CTE_Remplacement RB
            JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = RB.iID_Fichier_IQEE
        WHERE 0 = 0
            AND RB.RowNum = 1
            AND RB.bInd_Remplacement_Reconnu = 1
            AND RB.bLien_Frere_Soeur = 0
            AND RB.tiCode_Version IN (0, 2)
            AND RB.cStatut_Reponse IN ('A','R')
            AND NOT EXISTS(
                    SELECT * FROM dbo.tblIQEE_ImpotsSpeciaux I 
                             JOIN dbo.vwIQEE_Enregistrement_TypeEtSousType TE ON TE.iID_Sous_Type = I.iID_Sous_Type
                                                                             AND TE.cCode_Type_Enregistrement = '06'
                     WHERE I.iID_Convention = RB.iID_Convention
                           AND I.tiCode_Version IN (0, 2)
                           AND (   (    TE.cCode_Sous_Type = '02' 
                                    AND I.cStatut_Reponse IN ('A','R','T') 
                                    AND I.iID_Remplacement_Beneficiaire = RB.iID_Remplacement_Beneficiaire
                                   )
                                OR (    TE.cCode_Sous_Type = '91' 
                                    AND I.cStatut_Reponse IN ('A','R') 
                                   )
                               )
                )
            AND EXISTS(
                    SELECT * FROM dbo.Un_ConventionOper CO
                                  JOIN dbo.fntOPER_Active(DEFAULT, @dtFinCotisation) O ON O.OperID = CO.OperID
                     WHERE CO.ConventionID = RB.iID_Convention
                       AND CO.ConventionOperTypeID = 'MMQ'
                       AND CO.ConventionOperAmount > 0
                       AND O.OperTypeID = 'IQE'
                       AND O.OperDate < RB.dtDate_Remplacement
                )

        SELECT @iCount = Count(distinct ConventionID) FROM #TB_Convention_06_02 AS TC
        SET @ElapseTime = GetDate() - @QueryTimer

        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    » ' + LTrim(Str(@iCount)) + ' retrouvées (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

        SET ROWCOUNT 0

        IF NOT EXISTS(SELECT TOP 1 * FROM #TB_Convention_06_02)
           RETURN

        IF OBJECT_ID('tempdb..#TB_Subvention_06_02') IS NOT NULL
            DROP TABLE #TB_Subvention_06_02

        CREATE TABLE #TB_Subvention_06_02 (
            ConventionID INT NOT NULL,
            dtRemplacement DATETIME,
            Credit_Base MONEY,
            Majoration MONEY,
            Interet MONEY,
            Solde_IQEE MONEY
        )

        SET @QueryTimer = GetDate()
        DECLARE @ID_Convention INT = 0,
                @DateRemplacement DATE

        WHILE EXISTS(SELECT TOP 1 * FROM #TB_Convention_06_02 WHERE ConventionID > @ID_Convention)
        BEGIN
            SELECT @ID_Convention = MIN(ConventionID)
              FROM #TB_Convention_06_02
             WHERE ConventionID > @ID_Convention

            SET @DateRemplacement = CAST(CAST(0 AS DATETIME) AS DATE)
            WHILE EXISTS(SELECT TOP 1 * FROM #TB_Convention_06_02 WHERE ConventionID = @ID_Convention AND dtDate_Remplacement > @DateRemplacement)
            BEGIN
                SELECT @DateRemplacement = MIN(dtDate_Remplacement)
                  FROM #TB_Convention_06_02
                 WHERE ConventionID = @ID_Convention
                   AND dtDate_Remplacement > @DateRemplacement

                INSERT INTO #TB_Subvention_06_02 (ConventionID, dtRemplacement, Credit_Base, Majoration, Interet)
                SELECT S.iID_Convention, @DateRemplacement, S.mCreditBase - ISNULL(X.Sum_CreditBase, 0), S.mMajoration - ISNULL(X.Sum_Majoration, 0), S.mInteret - ISNULL(X.Sum_Interet, 0)
                  FROM dbo.fntIQEE_CalculerSoldeIQEE_PourRQ(@ID_Convention, @siAnnee_Fiscale, @DateRemplacement) S
                       LEFT JOIN (
                            SELECT ConventionID, SUM(Credit_Base) AS Sum_CreditBase, SUM(Majoration) AS Sum_Majoration, SUM(Interet) AS Sum_Interet
                              FROM #TB_Subvention_06_02
                             WHERE ConventionID = @ID_Convention
                               AND dtRemplacement < @DateRemplacement
                             GROUP BY ConventionID
                       ) X ON X.ConventionID = S.iID_Convention
            END
        END

        UPDATE #TB_Subvention_06_02 SET Solde_IQEE = Credit_Base + Majoration

        SET @ElapseTime = @QueryTimer - @QueryTimer

        SELECT @iCount = Count(ConventionID) FROM #TB_Subvention_06_02
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    » ' + LTrim(Str(@iCount)) + ' solde de l?IQÉÉ correspondant (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'
    END

    --------------------------------------------------------------------------------------------------
    -- Valider les fermetures de convention et conserver les raisons de rejet en vertu des validations
    --------------------------------------------------------------------------------------------------
    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Validation des conventions selon les critères RQ'
    BEGIN
        DECLARE
            @iID_Validation INT,                            @iCode_Validation INT, 
            @vcDescription VARCHAR(300),                    @cType CHAR(1), 
            @iCountRejets INT

        IF OBJECT_ID('tempdb..#TB_Rejet_06_02') IS NULL
            CREATE TABLE #TB_Rejets_06_02 (
                    iID_Convention int NOT NULL,
                    iID_Validation int NOT NULL,
                    vcDescription varchar(300) NOT NULL,
                    vcValeur_Reference varchar(200) NULL,
                    vcValeur_Erreur varchar(200) NULL,
                    iID_Lien_Vers_Erreur_1 int NULL,
                    iID_Lien_Vers_Erreur_2 int NULL,
                    iID_Lien_Vers_Erreur_3 int NULL
            )
        ELSE
            TRUNCATE TABLE #TB_Rejet_06_02

        -- Sélectionner les validations à faire pour le sous type de transaction
        IF OBJECT_ID('tempdb..#TB_Validation_06_02') IS NOT NULL
            DROP TABLE #TB_Validation_06_02

        SELECT 
            V.iOrdre_Presentation, V.iID_Validation, V.iCode_Validation, V.cType, V.vcDescription_Parametrable as vcDescription
        INTO
            #TB_Validation_06_02
        FROM
            tblIQEE_Validations V
        WHERE 
            V.tiID_Type_Enregistrement = @tiID_TypeEnregistrement
            AND IsNull(V.iID_Sous_Type, 0) = IsNull(@iID_SousTypeEnregistrement, 0)
            AND V.bValidation_Speciale = 0
            AND V.bActif = 1
            AND (
                @cCode_Portee = 'T'
              OR (@cCode_Portee = 'A' AND V.cType = 'E')
                OR (@cCode_Portee = 'I' AND V.bCorrection_Possible = 1)
            )
        SET @iCount = @@ROWCOUNT
        PRINT '   ' + Convert(varchar(20), GetDate(), 120) + '   » ' + LTrim(Str(@iCount)) + ' validations à appliquer'

        -- Boucler à travers les validations du sous type de transaction
        DECLARE @iOrdre_Presentation int = 0               
        WHILE Exists(SELECT TOP 1 * FROM #TB_Validation_06_02 WHERE iOrdre_Presentation > @iOrdre_Presentation) 
        BEGIN
            SET @iCountRejets = 0

            SELECT TOP 1
                @iOrdre_Presentation = iOrdre_Presentation,
                @iID_Validation = iID_Validation, 
                @iCode_Validation = iCode_Validation,
                @vcDescription = vcDescription,
                @cType = cType
            FROM
                #TB_Validation_06_02 
            WHERE
                iOrdre_Presentation > @iOrdre_Presentation
            ORDER BY 
                iOrdre_Presentation

            PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '   - Validation #' + LTrim(Str(@iCode_Validation)) + ': ' + @vcDescription

            BEGIN TRY
                -- Validation : L'impôt spécial de remplacement de bénéficiaire non reconnu a déjà été envoyé et une réponse reçue de RQ
                IF @iCode_Validation = 301 
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Remplacement
                        FROM
                            #TB_Convention_06_02 C
                        WHERE
                            Exists (
                                SELECT * FROM dbo.tblIQEE_ImpotsSpeciaux I
                                              JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = I.iID_Fichier_IQEE 
                                WHERE 
                                    I.iID_Convention = C.ConventionID
                                    AND I.iID_Remplacement_Beneficiaire = C.iID_Remplacement
                                    AND I.iID_Sous_Type = @iID_SousTypeEnregistrement
                                    AND I.cStatut_Reponse = 'R'
                            )
                    )
                    INSERT INTO #TB_Rejets_06_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, iID_Remplacement, NULL, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : L'impôt spécial de remplacement de bénéficiaire reconnu est en cours de traitement par RQ et est en attente d’une réponse de RQ
                IF @iCode_Validation = 302
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Remplacement
                        FROM
                            #TB_Convention_06_02 C
                        WHERE
                            Exists (
                                SELECT * FROM dbo.tblIQEE_ImpotsSpeciaux I
                                              JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = I.iID_Fichier_IQEE 
                                WHERE 
                                    I.iID_Convention = C.ConventionID
                                    AND I.iID_Remplacement_Beneficiaire = C.iID_Remplacement
                                    AND I.iID_Sous_Type = @iID_SousTypeEnregistrement
                                    AND I.cStatut_Reponse = 'A'
                                    AND I.tiCode_Version <> 1
                            )
                    )
                    INSERT INTO #TB_Rejets_06_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, iID_Remplacement, NULL, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : 
                IF @iCode_Validation = 303
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Remplacement
                        FROM
                            #TB_Convention_06_02 C
                        WHERE
                            Exists (
                                SELECT * FROM dbo.tblIQEE_ImpotsSpeciaux I
                                              JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = I.iID_Fichier_IQEE 
                                              JOIN dbo.tblIQEE_Erreurs E ON E.iID_Enregistrement = I.iID_Impot_Special
                                              JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = E.tiID_Type_Enregistrement
                                              JOIN dbo.tblIQEE_StatutsErreur SE ON SE.tiID_Statuts_Erreur = E.tiID_Statuts_Erreur
                                                                               AND SE.vcCode_Statut = 'ATR'
                                WHERE 
                                    I.iID_Convention = C.ConventionID
                                    AND I.iID_Remplacement_Beneficiaire = C.iID_Remplacement
                                    AND I.iID_Sous_Type = @iID_SousTypeEnregistrement
                                    AND I.cStatut_Reponse = 'E'
                                    AND TE.cCode_Type_Enregistrement = '06'
                            )
                    )
                    INSERT INTO #TB_Rejets_06_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, iID_Remplacement, NULL, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : La convention a été fermée par une transaction d'impôt spécial 91 ou 51
                IF @iCode_Validation = 305
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Remplacement
                        FROM
                            #TB_Convention_06_02 C
                        WHERE
                            Exists (
                                SELECT * FROM dbo.tblIQEE_ImpotsSpeciaux I
                                              JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = I.iID_Fichier_IQEE 
                                              JOIN dbo.tblIQEE_SousTypeEnregistrement ST ON ST.iID_Sous_Type = I.iID_Sous_Type
                                                                                        AND ST.cCode_Sous_Type IN ('91', '51')
                                WHERE 
                                    I.iID_Convention = C.ConventionID
                                    AND I.cStatut_Reponse IN ('A', 'R')
                                    AND I.dtDate_Evenement < C.dtDate_Remplacement
                            )
                    )
                    INSERT INTO #TB_Rejets_06_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, iID_Remplacement, NULL, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : L'impot special est < 0
                IF @iCode_Validation = 306
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Remplacement
                        FROM
                            #TB_Convention_06_02 C
                            JOIN #TB_Subvention_06_02 S ON S.ConventionID = C.ConventionID
                        WHERE
                            S.Solde_IQEE < 0
                    )
                    INSERT INTO #TB_Rejets_06_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, iID_Remplacement, NULL, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END
            END TRY
            BEGIN CATCH
                PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » *** ERREUR_VALIDATION ***'
                PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     »     ' + ERROR_MESSAGE()

                INSERT INTO ##tblIQEE_RapportCreation 
                    (cSection, iSequence, vcMessage)
                SELECT
                    '3', 10, '       '+CONVERT(VARCHAR(25),GETDATE(),121)+'     '+vcDescription_Parametrable + ' ' + LTrim(Str(@iCode_Validation))
                FROM
                    dbo.tblIQEE_Validations
                WHERE 
                    iCode_Validation = 300

                RETURN -1
            END CATCH

            -- S'il y a eu des rejets de validation
            IF @iCountRejets > 0
            BEGIN
                PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » ' + LTrim(Str(@iCountRejets)) + CASE @cType WHEN 'E' THEN ' rejets'
                                                                                                                         WHEN 'A' THEN ' avertissements'
                                                                                                                         ELSE ''
                                                                                                             END
                -- Et si on traite seulement les 1ères erreurs de chaque convention
                IF @bArretPremiereErreur = 1 AND @cType = 'E'
                BEGIN
                    -- Efface que les conventions ayant un rejet sur la validation courante
                    DELETE FROM #TB_Convention_06_02
                    WHERE EXISTS (SELECT * FROM #TB_Rejets_06_02 WHERE iID_Convention = ConventionID AND iID_Validation = @iID_Validation)
                END
            END
        END -- IF @iCode_Validation 

        -- Efface tous les conventions ayant eu au moins un rejet de validation
        DELETE FROM #TB_Convention_06_02
        WHERE EXISTS (SELECT * FROM #TB_Rejets_06_02 R JOIN dbo.tblIQEE_Validations V ON V.iID_Validation = R.iID_Validation WHERE V.cType = 'E' And iID_Convention = ConventionID)

        INSERT INTO dbo.tblIQEE_Rejets (
            iID_Fichier_IQEE, siAnnee_Fiscale, iID_Convention, iID_Validation, vcDescription,
            vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
            --,tCommentaires, iID_Utilisateur_Modification, dtDate_Modification
        )
        SELECT 
            @iID_Fichier_IQEE, @siAnnee_Fiscale, R.iID_Convention, R.iID_Validation, R.vcDescription,
            R.vcValeur_Reference, vcValeur_Erreur, R.iID_Lien_Vers_Erreur_1, R.iID_Lien_Vers_Erreur_2, R.iID_Lien_Vers_Erreur_3
        FROM 
            #TB_Rejets_06_02 R
    END

    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Déclaration des retraits de cotisations'
    BEGIN
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '   Créer les enregistrements d?impôt spéciaux.'
        SET @QueryTimer = GetDate()
        INSERT INTO dbo.tblIQEE_ImpotsSpeciaux (
            iID_Fichier_IQEE, siAnnee_Fiscale, tiCode_Version, cStatut_Reponse, iID_Convention, vcNo_Convention, iID_Sous_Type, iID_Remplacement_Beneficiaire,
            dtDate_Evenement, mSolde_IQEE_Base, mSolde_IQEE_Majore, mIQEE_ImpotSpecial,
            iID_Beneficiaire, vcNAS_Beneficiaire, vcNom_Beneficiaire, vcPrenom_Beneficiaire, 
            dtDate_Naissance_Beneficiaire, tiSexe_Beneficiaire
        )
        SELECT
            @iID_Fichier_IQEE, @siAnnee_Fiscale, @tiCode_Version, 'A', C.ConventionID, Left(C.ConventionNo, 15), @iID_SousTypeEnregistrement, C.iID_Remplacement,
            C.dtDate_Remplacement, ISNULL(S.Credit_Base,0.0), ISNULL(S.Majoration,0.0) , ISNULL(S.Solde_IQEE,0.0),
            C.iID_Beneficiaire, C.vcNAS, C.vcNom, C.vcPrenom, 
            C.dtNaissance, tiSexe
        FROM
            #TB_Convention_06_02 C
            LEFT JOIN #TB_Subvention_06_02 S ON S.ConventionID = C.ConventionID

        SET @iCount = @@RowCount
        SET @ElapseTime = @QueryTimer - GetDate()
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    » ' + LTrim(Str(@iCount)) + ' enregistrements ajoutés (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

        IF @iCount > 0
            IF EXISTS(SELECT * FROM dbo.tblIQEE_Fichiers WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE AND bInd_Simulation = 0)
                EXEC dbo.psIQEE_CreerOperationFinanciere_ImpotsSpeciaux @iID_Utilisateur_Creation, @iID_Fichier_IQEE, @iID_SousTypeEnregistrement
    END

    SET @ElapseTime = GetDate() - @StartTimer
    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' EXEC psIQEE_CreerTransactions06_02 completed' 
                + ' (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

    IF OBJECT_ID('tempdb..#TB_Validation_06_02') IS NOT NULL
        DROP TABLE #TB_Validation_06_02
    IF OBJECT_ID('tempdb..#TB_Rejets_06_02') IS NOT NULL
        DROP TABLE #TB_Rejets_06_02
    IF OBJECT_ID('tempdb..#TB_Beneficiary_06_02') IS NOT NULL
        DROP TABLE #TB_Beneficiary_06_02
    IF OBJECT_ID('tempdb..#TB_Convention_06_02') IS NOT NULL
        DROP TABLE #TB_Convention_06_02

    -- Retourner 0 si le traitement est réussi
    RETURN 0
END
