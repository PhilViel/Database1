/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service : psIQEE_CreerTransactions06_01
Nom du service  : Créer les transactions de type 06 sous type 01 - Remplacement de bénéficiaire non reconnu
But             : Sélectionner, valider et créer les transactions de type 06 – Impôt spécial, 01 - Remplacement de bénéficiaire non reconnu, 
                  dans un nouveau fichier de transactions de l’IQÉÉ.
Facette         : IQÉÉ

Paramètres d’entrée :
    Paramètre               Description
    --------------------    -----------------------------------------------------------------
    iID_Fichier_IQEE        Identifiant du nouveau fichier de transactions dans lequel les transactions 06-01 doivent être créées.
    bFichiers_Test          Indicateur si les fichiers test doivent être tenue en compte dans la production du fichier.  
                            Normalement ce n’est pas le cas, mais pour fins d’essais et de simulations il est possible de tenir compte
                            des fichiers tests comme des fichiers de production.  S’il est absent, les fichiers test ne sont pas considérés.
    iID_Convention          Identifiant unique de la convention pour laquelle la création des
                            fichiers est demandée.  La convention doit exister.
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
    Date        Programmeur                 Description
    ----------  ------------------------    --------------------------------------------------------------------------
    2009-02-17  Éric Deshaies               Création du service                            
    2012-05-29  Eric Michaud                Projet septembre 2012    
    2012-08-17  Dominique Pothier           Désactivation validation 305
    2012-08-20  Dominique Pothier           Ajout validation 306
    2012-08-22  Eric Michaud                Modification pour donnée de l'ancien bénéficiaire
    2012-12-13  Stéphane Barbeau            Ajout du paramètre @iID_Utilisateur_Creation et appel psIQEE_CreerOperationFinanciereIQE_DeclarationImpotsSpeciaux pour créer l'opération IQE directement.
    2013-08-09  Stéphane Barbeau            Désactivation validation 303
    2013-08-15  Stéphane Barbeau            Ajout validation 307
    2013-10-17  Stéphane Barbeau            curImpotSpecial01: Ajustement pour exclure les T03 en erreur et respecter ration T03, T06-01 1:1 ; amélioration de la sous-requête
    2013-10-18  Stéphane Barbeau            Réduction des Appels à psIQEE_AjouterRejet pour le rejet générique: condition IF @iResultat <= 0 changée pour IF @iResultat <> 0
                                            Raison: Unless documented otherwise, all system stored procedures return a value of 0. This indicates success and a nonzero value indicates failure.
    2013-11-06  Stéphane Barbeau            Requête curImpotSpecial01: Ajout du paramètre RB.dtDate_Remplacement dans la fonction fnIQEE_ConventionConnueRQ et exclusion si impôt spécial 91 déjà créé.
    2013-11-27  Stéphane Barbeau            Ajustement validation 307    
    2013-12-13  Stéphane Barbeau            Requête -- S'il n'y a pas d'erreur, créer la transaction 06-01: AND R.iID_Lien_Vers_Erreur_1 = @iID_Remplacement_Beneficiaire                                                                             
    2014-03-17  Stéphane Barbeau            Désactivation rejet 307
    2014-07-03  Stéphane Barbeau            curImpotSpecial01: Correction condition AND IPS.cStatut_Reponse NOT IN ('R', 'T') par AND IPS.cStatut_Reponse IN ( 'A', 'R', 'T').  
                                            Retrait de la condition AND RB.cStatut_Reponse <> 'E'
    2014-08-13  Stéphane Barbeau            Ajout validation #308 et paramètre @bit_CasSpecial.
    2015-12-16  Steeve Picard               Activation de la validation #303
    2016-01-08  Steeve Picard               Correction au niveau des validations pour tenir compte de la Convention_ID
    2016-02-02  Steeve Picard               Optimisation en remplaçant les curseurs SQL par des boucles WHILE
    2016-06-13  Steeve Picard               Correction dans le WHERE qui joint les tables «tblIQEE_RemplacementsBeneficiaire» et «fntCONV_RechercherChangementsBeneficiaire»
                                            Utilisation des codes de types & sous-type d'enregistrement au lieu de ID du sous-type pour mieux comprendre
    2016-06-13  Steeve Picard               Correction pour éliminer les doublons
    2016-12-14  Steeve Picard               Optimisation en traitant par batch et non une convention à la fois
    2017-06-09  Steeve Picard               Ajout du paramètre « @tiCode_Version = 0 » pour passer la valeur « 2 » lors d'une annulation/reprise
    2017-07-10  Steeve Picard               Appel à «psIQEE_CreerOperationFinanciere_ImpotsSpeciaux» seulement s'il y a eu création d'au moins une transaction
    2017-07-11  Steeve Picard               Élimination du paramètre « iID_Convention » pour toujours utiliser la table « #TB_ListeConvention »
    2017-11-07  Steeve Picard               Réajustement dû au changement de la T03 pour valider tous les changements bénéficiaires
    2018-01-04  Steeve Picard           Validation de base si @cCode_Portee = '' pour l'estimation du rapport à recevoir
    2018-02-08  Steeve Picard           Déplacement de «siAnnee_Fiscale» de la table «tblIQEE_Fichiers» vers les tables d'évèments «tblIQEE_ImpotsSpeciaux»
    2018-02-26  Steeve Picard           Empêcher que la «dtFinCotisation» soit plus grande que la dernière fin de mois
    2018-03-15  Steeve Picard           Bloquer la déclaration si la T(03) a été préalablement rejeté
    2018-06-06  Steeve Picard           Modificiation de la gestion des retours d'erreur par RQ
*********************************************************************************************************************/
CREATE PROCEDURE dbo.psIQEE_CreerTransactions06_01
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
    PRINT 'Déclaration des remplacements de bénéficiaire non reconnu (T06-01) pour ' + STR(@siAnnee_Fiscale, 4)
    PRINT '----------------------------------------------------------------------------'
    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' EXEC psIQEE_CreerTransactions06_01 started'

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
        AND cCode_Sous_Type = '01'

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

    SELECT @iID_SousTypeEnregistrement = iID_Sous_Type
    FROM tblIQEE_SousTypeEnregistrement ST
         JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = ST.tiID_Type_Enregistrement
    WHERE TE.cCode_Type_Enregistrement = '06'
      AND ST.cCode_Sous_Type = '01'

    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Récupération des conventions à déclarer'
    BEGIN
        IF OBJECT_ID('tempdb..#TB_Convention_06_01') IS NOT NULL
            DROP TABLE #TB_Convention_06_01

        PRINT '   ' + Convert(varchar(20), GetDate(), 120) + '   - Récupère les conventions ayant eu un remplacement de bénéficiaire non reconnu'
        SET @QueryTimer = GetDate()
    
        SET ROWCOUNT @MaxRow

        ;WITH CTE_Remplacement AS (
            SELECT DISTINCT
                RB.iID_Remplacement_Beneficiaire, 
                RB.iID_Changement_Beneficiaire,
                RB.iID_Fichier_IQEE,
                RB.siAnnee_Fiscale,
                RB.tiCode_Version, 
                RB.cStatut_Reponse,
                RB.iID_Convention,
                RB.dtDate_Remplacement,  
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
            RB.dtDate_Remplacement,  RB.iID_Beneficiaire, RB.vcNAS, RB.vcNom, RB.vcPrenom, RB.dtNaissance, RB.tiSexe,
            bRemplacement_Rejete = CAST(ISNULL(R.iID_Rejet, 0) AS bit)
        INTO
            #TB_Convention_06_01
        FROM 
            CTE_Remplacement RB
            JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = RB.iID_Fichier_IQEE
            LEFT JOIN  dbo.tblIQEE_Rejets R ON R.siAnnee_Fiscale = RB.siAnnee_Fiscale AND R.iID_Convention = RB.iID_Convention AND R.iID_Lien_Vers_Erreur_1 = RB.iID_Changement_Beneficiaire
        WHERE 0 = 0
            AND RB.RowNum = 1
            AND RB.bInd_Remplacement_Reconnu = 0
            AND RB.tiCode_Version IN (0, 2)
            AND RB.cStatut_Reponse IN ('A','R')
            AND NOT EXISTS(
                    SELECT * FROM dbo.tblIQEE_ImpotsSpeciaux I 
                             JOIN dbo.vwIQEE_Enregistrement_TypeEtSousType TE ON TE.iID_Sous_Type = I.iID_Sous_Type
                                                                             AND TE.cCode_Type_Enregistrement = '06'
                     WHERE I.iID_Convention = RB.iID_Convention
                           AND I.tiCode_Version IN (0, 2)
                           AND (   (    TE.cCode_Sous_Type = '01' 
                                    AND I.cStatut_Reponse IN ('A','R','T') 
                                    AND I.iID_Remplacement_Beneficiaire = RB.iID_Remplacement_Beneficiaire
                                   )
                                OR (    TE.cCode_Sous_Type = '91' 
                                    AND I.cStatut_Reponse IN ('A','R') 
                                   )
                               )
                )

        SET @iCount = @@ROWCOUNT
        SET @ElapseTime = GetDate() - @QueryTimer

        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    » ' + LTrim(Str(@iCount)) + ' retrouvées (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

        SET ROWCOUNT 0

        IF NOT EXISTS(SELECT TOP 1 * FROM #TB_Convention_06_01)
           RETURN

        IF OBJECT_ID('tempdb..#TB_Subvention_06_01') IS NOT NULL
            DROP TABLE #TB_Subvention_06_01

        CREATE TABLE #TB_Subvention_06_01 (
            ConventionID INT NOT NULL,
            dtRemplacement DATETIME,
            Credit_Base MONEY,
            Majoration MONEY,
            Interet MONEY,
            Solde_IQEE MONEY
        )

        --INSERT INTO #TB_Subvention_06_01 (ConventionID)
        --SELECT DISTINCT ConventionID FROM #TB_Convention_06_01

        SET @QueryTimer = GetDate()
        DECLARE @ID_Convention INT = 0,
                @DateRemplacement DATETIME

        WHILE EXISTS(SELECT TOP 1 * FROM #TB_Convention_06_01 WHERE ConventionID > @ID_Convention)
        BEGIN
            SELECT @ID_Convention = MIN(ConventionID)
              FROM #TB_Convention_06_01
             WHERE ConventionID > @ID_Convention

            SET @DateRemplacement = CAST(0 AS DATETIME)
            WHILE EXISTS(SELECT TOP 1 * FROM #TB_Convention_06_01 WHERE ConventionID = @ID_Convention AND dtDate_Remplacement > @DateRemplacement)
            BEGIN
                SELECT @DateRemplacement = MIN(dtDate_Remplacement)
                  FROM #TB_Convention_06_01
                 WHERE ConventionID = @ID_Convention
                   AND dtDate_Remplacement > @DateRemplacement

                INSERT INTO #TB_Subvention_06_01 (ConventionID, dtRemplacement, Credit_Base, Majoration, Interet)
                SELECT S.iID_Convention, @DateRemplacement, S.mCreditBase - ISNULL(X.Sum_CreditBase, 0), S.mMajoration - ISNULL(X.Sum_Majoration, 0), S.mInteret - ISNULL(X.Sum_Interet, 0)
                  FROM dbo.fntIQEE_CalculerSoldeIQEE_PourRQ(@ID_Convention, @siAnnee_Fiscale, @DateRemplacement) S
                       LEFT JOIN (
                            SELECT ConventionID, SUM(Credit_Base) AS Sum_CreditBase, SUM(Majoration) AS Sum_Majoration, SUM(Interet) AS Sum_Interet
                              FROM #TB_Subvention_06_01
                             WHERE ConventionID = @ID_Convention
                               AND dtRemplacement < @DateRemplacement
                             GROUP BY ConventionID
                       ) X ON X.ConventionID = S.iID_Convention
            END
        END

        UPDATE #TB_Subvention_06_01 SET Solde_IQEE = Credit_Base + Majoration

        SET @ElapseTime = @QueryTimer - @QueryTimer

        SELECT @iCount = Count(distinct ConventionID) FROM #TB_Subvention_06_01
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

        IF OBJECT_ID('tempdb..#TB_Rejet_06_01') IS NULL
            CREATE TABLE #TB_Rejets_06_01 (
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
            TRUNCATE TABLE #TB_Rejet_06_01

        -- Sélectionner les validations à faire pour le sous type de transaction
        IF OBJECT_ID('tempdb..#TB_Validation_06_01') IS NOT NULL
            DROP TABLE #TB_Validation_06_01

        SELECT 
            V.iOrdre_Presentation, V.iID_Validation, V.iCode_Validation, V.cType, V.vcDescription_Parametrable as vcDescription
        INTO
            #TB_Validation_06_01
        FROM
            tblIQEE_Validations V
        WHERE 
            V.tiID_Type_Enregistrement = @tiID_TypeEnregistrement
            AND IsNull(V.iID_Sous_Type, 0) = IsNull(@iID_SousTypeEnregistrement, 0)
            AND V.bValidation_Speciale = 0
            AND V.bActif = 1
            AND ( @cCode_Portee = 'T'
                  OR (@cCode_Portee = 'A' AND V.cType = 'E')
                  OR (@cCode_Portee = 'I' AND V.bCorrection_Possible = 1)
                  OR (ISNULL(@cCode_Portee, '') = '' AND V.cType = 'E' AND V.bCorrection_Possible = 0)
                )
        SET @iCount = @@ROWCOUNT
        PRINT '   ' + Convert(varchar(20), GetDate(), 120) + '   » ' + LTrim(Str(@iCount)) + ' validations à appliquer'

        -- Boucler à travers les validations du sous type de transaction
        DECLARE @iOrdre_Presentation int = 0               
        WHILE Exists(SELECT TOP 1 * FROM #TB_Validation_06_01 WHERE iOrdre_Presentation > @iOrdre_Presentation) 
        BEGIN
            SET @iCountRejets = 0

            SELECT TOP 1
                @iOrdre_Presentation = iOrdre_Presentation,
                @iID_Validation = iID_Validation, 
                @iCode_Validation = iCode_Validation,
                @vcDescription = vcDescription,
                @cType = cType
            FROM
                #TB_Validation_06_01 
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
                            #TB_Convention_06_01 C
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
                    INSERT INTO #TB_Rejets_06_01 (
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

                -- Validation : L'impôt spécial de remplacement de bénéficiaire non reconnu est en cours de traitement par RQ et est en attente d’une réponse de RQ
                IF @iCode_Validation = 302
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Remplacement
                        FROM
                            #TB_Convention_06_01 C
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
                    INSERT INTO #TB_Rejets_06_01 (
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
                            #TB_Convention_06_01 C
                        WHERE
                            Exists (
                                SELECT * FROM dbo.tblIQEE_ImpotsSpeciaux I
                                              JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = I.iID_Fichier_IQEE 
                                              JOIN dbo.tblIQEE_Erreurs E ON E.iID_Enregistrement = I.iID_Impot_Special
                                              JOIN dbo.tblIQEE_StatutsErreur SE ON SE.tiID_Statuts_Erreur = E.tiID_Statuts_Erreur
                                                                               AND SE.vcCode_Statut = 'ATR'
                                WHERE 
                                    I.iID_Convention = C.ConventionID
                                    AND I.iID_Remplacement_Beneficiaire = C.iID_Remplacement
                                    AND I.iID_Sous_Type = @iID_SousTypeEnregistrement
                                    AND I.cStatut_Reponse = 'E'
                                    AND E.tiID_Type_Enregistrement = @tiID_TypeEnregistrement
                            )
                    )
                    INSERT INTO #TB_Rejets_06_01 (
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
                            #TB_Convention_06_01 C
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
                    INSERT INTO #TB_Rejets_06_01 (
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
                            #TB_Convention_06_01 C
                            JOIN #TB_Subvention_06_01 S ON S.ConventionID = C.ConventionID
                        WHERE
                            S.Solde_IQEE < 0
                    )
                    INSERT INTO #TB_Rejets_06_01 (
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

                -- Validation : La declaration de la T(03) correspondante est en rejet
                IF @iCode_Validation = 307
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Remplacement
                        FROM
                            #TB_Convention_06_01 C
                        WHERE
                            --bRemplacement_Rejete <> 0
                            NOT EXISTS (
                                SELECT * FROM dbo.tblIQEE_RemplacementsBeneficiaire RB
                                              JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = RB.iID_Fichier_IQEE 
                                WHERE 
                                    RB.siAnnee_Fiscale = @siAnnee_Fiscale
                                    AND RB.iID_Convention = C.ConventionID
                                    AND RB.dtDate_Remplacement = C.dtDate_Remplacement
                                    AND RB.cStatut_Reponse IN ('A', 'R')
                            )
                    )
                    INSERT INTO #TB_Rejets_06_01 (
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
                    DELETE FROM #TB_Convention_06_01
                    WHERE EXISTS (SELECT * FROM #TB_Rejets_06_01 WHERE iID_Convention = ConventionID AND iID_Validation = @iID_Validation)
                END
            END
        END -- IF @iCode_Validation 

        -- Efface tous les conventions ayant eu au moins un rejet de validation
        DELETE FROM #TB_Convention_06_01
        WHERE EXISTS (SELECT * FROM #TB_Rejets_06_01 R JOIN dbo.tblIQEE_Validations V ON V.iID_Validation = R.iID_Validation WHERE V.cType = 'E' And iID_Convention = ConventionID)

        INSERT INTO dbo.tblIQEE_Rejets (
            iID_Fichier_IQEE, siAnnee_Fiscale, iID_Convention, iID_Validation, vcDescription,
            vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
            --,tCommentaires, iID_Utilisateur_Modification, dtDate_Modification
        )
        SELECT 
            @iID_Fichier_IQEE, @siAnnee_Fiscale, R.iID_Convention, R.iID_Validation, R.vcDescription,
            R.vcValeur_Reference, vcValeur_Erreur, R.iID_Lien_Vers_Erreur_1, R.iID_Lien_Vers_Erreur_2, R.iID_Lien_Vers_Erreur_3
        FROM 
            #TB_Rejets_06_01 R
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
            #TB_Convention_06_01 C
            LEFT JOIN #TB_Subvention_06_01 S ON S.ConventionID = C.ConventionID AND S.dtRemplacement = C.dtDate_Remplacement

        SET @iCount = @@RowCount
        SET @ElapseTime = @QueryTimer - GetDate()
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    » ' + LTrim(Str(@iCount)) + ' enregistrements ajoutés (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

        IF @iCount > 0
            IF EXISTS(SELECT * FROM dbo.tblIQEE_Fichiers WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE AND bInd_Simulation = 0)
                EXEC dbo.psIQEE_CreerOperationFinanciere_ImpotsSpeciaux @iID_Utilisateur_Creation, @iID_Fichier_IQEE, @iID_SousTypeEnregistrement
    END

    SET @ElapseTime = GetDate() - @StartTimer
    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' EXEC psIQEE_CreerTransactions06_01 completed' 
                + ' (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

    IF OBJECT_ID('tempdb..#TB_Validation_06_01') IS NOT NULL
        DROP TABLE #TB_Validation_06_01
    IF OBJECT_ID('tempdb..#TB_Rejets_06_01') IS NOT NULL
        DROP TABLE #TB_Rejets_06_01
    IF OBJECT_ID('tempdb..#TB_Beneficiary_06_01') IS NOT NULL
        DROP TABLE #TB_Beneficiary_06_01
    IF OBJECT_ID('tempdb..#TB_Convention_06_01') IS NOT NULL
        DROP TABLE #TB_Convention_06_01

    -- Retourner 0 si le traitement est réussi
    RETURN 0
END
