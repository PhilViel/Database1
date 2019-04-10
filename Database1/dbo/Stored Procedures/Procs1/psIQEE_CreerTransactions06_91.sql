/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service :   psIQEE_CreerTransactions06_91
Nom du service  :   Créer les transactions de  type 06, sous type 91 - Fermeture du contrat
But             :   Sélectionner, valider et créer les transactions de type 06 – Impôt spécial, 91 - Fermeture du contrat, 
                    dans un nouveau fichier de transactions de l’IQÉÉ.
Facette         :   IQÉÉ

Paramètres d’entrée :
    Paramètre               Description
    --------------------    -----------------------------------------------------------------
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

Exemple d’appel :   
    exec dbo.psIQEE_CreerTransactions06_91 10, 0, NULL, 0, 'T',0

Paramètres de sortie:
    Champ               Description
    ------------        ------------------------------------------
    iCode_Retour        = 0 : Exécution terminée normalement
                        < 0 : Erreur de traitement

Historique des modifications:
    Date        Programmeur             Description
    ----------  --------------------    --------------------------------------------------------------------------
    2009-02-17  Éric Deshaies           Création du service        
    2012-05-03  Stéphane Barbeau        Mise en commentaire du traitement des champs facultatifs                    
    2012-05-12  Éric Deshaies           Ajout d'information pour projet Septembre 2012
    2012-05-15  Éric Deshaies           Ajout Condition 618
    2012-08-14  Stéphane Barbeau        Désactivation validation 616 et 617.
    2012-08-15  Dominique Pothier       Modification validation 613
    2012-08-16  Stéphane Barbeau        Correction Validation 614, Désactivation validation 618.
    2012-08-17  Dominique Pothier       Désactivation validation 613
    2012-08-20  Dominique Pothier       Ajout de la validation 620
    2012-08-21  Stéphane Barbeau        Division de l'impôt spécial et arrondissement des montants à 2 décimales à l'INSERT
    2012-08-23  Stéphane Barbeau        Décision de GUI: Retrait du calcul comparatif de la JVM dans l'impôt spécial.  Annulation de la formule de répartition de l'impôt spécial.
    2012-08-28  Stéphane Barbeau        Calcul des solde en temps réel: Utilisation de getdate() plutôt que @dtFinCotisation à cause d'annulations-reprises faites après la fermeture des conventions.
    2012-08-29  Stéphane Barbeau        Ajustement validation 619.
    2012-12-13  Stéphane Barbeau        Ajout du paramètre @iID_Utilisateur_Creation et appel psIQEE_CreerOperationFinanciereIQE_DeclarationImpotsSpeciaux pour créer l'opération IQE directement.
    2013-02-08  Stéphane Barbeau        Ajout validation 621 de l'existence de PAEs.
    2013-08-02  Stéphane Barbeau        Désactivation validation 603.
    2013-10-18  Stéphane Barbeau        Réduction des Appels à psIQEE_AjouterRejet pour le rejet générique: condition IF @iResultat <= 0 changée pour IF @iResultat <> 0
                                        Raison: Unless documented otherwise, all system stored procedures return a value of 0. This indicates success and a nonzero value indicates failure.
    2013-11-06  Stéphane Barbeau        Requête curImpotSpecial91: Ajout du paramètre CS.StatutDate dans la fonction fnIQEE_ConventionConnueRQ et exclusion si impôt spécial 91 déjà créé.                                                            
    2013-11-27  Stéphane Barbeau        Ajustement validation 621.
    2013-12-13  Stéphane Barbeau        Requête -- S'il n'y a pas d'erreur, créer la transaction 06-91, retrait de la condition AND R.iID_Lien_Vers_Erreur_1 = @iID_Statut_Convention                                                                                        
    2014-08-13  Stéphane Barbeau        Ajout validation #622 et ajout paramètre @bit_CasSpecial..
    2015-12-16  Steeve Picard           Activation de la validation #603
    2016-01-08  Steeve Picard           Correction au niveau des validations pour tenir compte de la Convention_ID
    2016-02-02  Steeve Picard           Optimisation en remplaçant les curseurs SQL par des boucles WHILE
    2016-02-19  Steeve Picard           Retrait des 2 derniers paramètres de « fnIQEE_ConventionConnueRQ »
    2016-03-23  Pierre-Luc Simard       Ne plus valdier la table tblIQEE_PaiementsBeneficiaires dans la validation 621 (Temporairement le temps de développer la T05)
    2016-10-04  Steeve Picard           Changement de la validation pour rejeter les conventions avec une des opérations TRI/RIM/OUT
    2017-02-01  Steeve Picard           Optimisation en traitant par batch et non une convention à la fois
    2017-04-21  Steeve Picard           Changement pour récupérer le solde IQEE en date du jour au lieu de la fin d'année fiscale du fichier
    2017-06-09  Steeve Picard           Ajout du paramètre « @tiCode_Version = 0 » pour passer la valeur « 2 » lors d'une annulation/reprise
    2017-07-10  Steeve Picard           Appel à «psIQEE_CreerOperationFinanciere_ImpotsSpeciaux» seulement s'il y a eu création d'au moins une transaction
    2017-07-11  Steeve Picard           Élimination du paramètre « iID_Convention » pour toujours utiliser la table « #TB_ListeConvention »
    2017-10-20  Steeve Picard           Correction pour la validation des cas où la convention est la source ou le destinataire du transfert «RIO» non déclaré à RQ
    2018-01-03  Steeve Picard           Correction pour les soldes restants après fermeture en utilisant de la date du jour
    2018-01-04  Steeve Picard           Validation de base si @cCode_Portee = '' pour l'estimation du rapport à recevoir
    2018-01-30  Steeve Picard           Changement pour ne considérer que la dernière T06-91 par convention
    2018-02-05  Steeve Picard           Ajout de validation afin de rejeter la T06-91 s'il y a une autre transaction en attente de réponse
    2018-02-08  Steeve Picard           Déplacement de «siAnnee_Fiscale» de la table «tblIQEE_Fichiers» vers les tables d'évèments «tblIQEE_ImpotsSpeciaux»
    2018-02-26  Steeve Picard           Empêcher que la «dtFinCotisation» soit plus grande que la dernière fin de mois
    2018-04-01  Steeve Picard           Corrections des soldes restants qui sont calculés 2 fois
    2018-06-06  Steeve Picard           Modificiation de la gestion des retours d'erreur par RQ
    2018-09-19  Steeve Picard           Ajout du champ «iID_SousType» à la table «tblIQEE_CasSpeciaux» pour pouvoir filtrer
    2018-09-20  Steeve Picard           Ajout de la vérification que l'opération «AVC» ait été déclarée préalablement au même titre que les «PAE»
    2018-11-27  Steeve Picard           Ne bloquer la déclaration que si elle a de l'IQÉÉ dans le PAE antérieur et ignorer les opérations «AVC» en fait de compte
    2018-12-06  Steeve Picard           Utilisation des nouvelles fonctions «fntIQEE_Transfert_NonDeclare & fntIQEE_PaiementBeneficiaire_NonDeclare»
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_CreerTransactions06_91]
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
    PRINT 'Déclaration des fermetures du contrat ou d’un dossier bénéficiaire (T06-91) pour ' + STR(@siAnnee_Fiscale, 4)
    PRINT '-------------------------------------------------------------------------------------'
    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' EXEC psIQEE_CreerTransactions06_91 started'

    IF Object_ID('tempDB..#TB_ListeConvention') IS NULL
        RAISERROR ('La table « #TB_ListeConvention (RowNo INT Identity(1,1), ConventionID int, ConventionNo varchar(20) » est abesente ', 16, 1)

    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Identifie le(s) convention(s)'
    DECLARE @iCount int = (SELECT Count(*) FROM #TB_ListeConvention)
    IF @iCount > 0
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '   - ' + LTrim(Str(@iCount)) + ' conventions à génèrées'

    --  Déclaration des varaibles
    DECLARE @StartTimer datetime = GetDate(),
            @QueryTimer datetime,
            @ElapseTime datetime,
            @MaxRow INT = 0,
            @IsDebug bit = dbo.fn_IsDebug()
    
    --  Déclaration des variables
    BEGIN 
        DECLARE 
            @tiID_TypeEnregistrement TINYINT,       @iID_SousTypeEnregistrement INT,
            @dtDebutCotisation DATE,                @dtMinCotisation DATE = '2007-02-21',
            @dtFinCotisation DATE,                  @dtMaxCotisation DATE = DATEADD(DAY, -DAY(GETDATE()), GETDATE()),
            @vcNo_Convention VARCHAR(15)
    
        -- Sélectionner dates applicables aux transactions
        SELECT @dtDebutCotisation = Str(@siAnnee_Fiscale, 4) + '-01-01 00:00:00',
               @dtFinCotisation = STR(@siAnnee_Fiscale, 4) + '-12-31 23:59:59'

        IF @dtDebutCotisation < @dtMinCotisation
            SET @dtDebutCotisation = @dtMinCotisation

        IF @dtFinCotisation > @dtMaxCotisation
            SET @dtFinCotisation = @dtMaxCotisation
    END

    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Récupère les IDs du type & sous-type pour ce type d''enregistrement'
    SELECT 
        @tiID_TypeEnregistrement = tiID_Type_Enregistrement,
        @iID_SousTypeEnregistrement = iID_Sous_Type
    FROM
        dbo.vwIQEE_Enregistrement_TypeEtSousType 
    WHERE
        cCode_Type_Enregistrement = '06'
        AND cCode_Sous_Type = '91'

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
        F.iID_Fichier_IQEE, /*F.siAnnee_Fiscale,*/ F.dtDate_Creation, F.dtDate_Paiement
    FROM 
        dbo.tblIQEE_Fichiers F
        JOIN dbo.tblIQEE_TypesFichier T ON T.tiID_Type_Fichier = F.tiID_Type_Fichier
    WHERE
        0 = 0 --T.bTeleversable_RQ <> 0
        AND (
                (F.bFichier_Test = 0  AND F.bInd_Simulation = 0)
                OR F.iID_Fichier_IQEE = @iID_Fichier_IQEE
            )

    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Récupération des conventions à déclarer'
    BEGIN
        ------------------------------------------------------------------------------------------------------------
        -- Identifier et sélectionner les conventions ayant eu une fermeture du contrat ou d’un dossier bénéficiaire
        ------------------------------------------------------------------------------------------------------------
        IF OBJECT_ID('tempdb..#TB_Convention_06_91') IS NOT NULL
            DROP TABLE #TB_Convention_06_91

        PRINT '   ' + Convert(varchar(20), GetDate(), 120) + '   - Récupère les conventions ayant eu une fermeture du contrat'
        SET @QueryTimer = GetDate()
    
        SET ROWCOUNT @MaxRow

        --DECLARE @dtSoldeAnnuel DATE = dateadd(month, 3, @dtFinCotisation)
        --IF EXISTS(SELECT * FROM dbo.tblIQEE_Fichiers WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE AND bInd_Simulation = 0)
        --    SET @dtSoldeAnnuel = GetDate()

        ;WITH CTE_Convention_FRM as (
            SELECT 
                C.ConventionID, C.ConventionNo, 
                StatutID = CS.ConventionConventionStateID, 
                StatutDate = CS.StartDate
            FROM 
                #TB_ListeConvention C
                JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(NULL, NULL) CS 
                     ON CS.ConventionID = C.ConventionID
            WHERE 
                C.dtReconnue_RQ IS NOT NULL 
                AND CS.StartDate BetWeen @dtDebutCotisation And @dtFinCotisation
                AND CS.ConventionStateID = 'FRM'
        ),
        CTE_ImpotFermeture AS (
            SELECT 
                I.iID_Convention, I.iID_Impot_Special, I.tiCode_Version,
                Row_Num = ROW_NUMBER() OVER(PARTITION BY I.iID_Convention ORDER BY I.iID_Impot_Special DESC)
            FROM 
                dbo.tblIQEE_ImpotsSpeciaux I
                   JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = I.iID_Fichier_IQEE 
            WHERE 
                I.iID_Sous_Type= @iID_SousTypeEnregistrement
                AND NOT I.cStatut_Reponse IN ('E','X')
                --AND I.tiCode_Version IN (0, 2) 
        ),
        CTE_Convention as (
            SELECT 
                C.Conventionid, C.ConventionNo, C.StatutID, C.StatutDate
            FROM 
                CTE_Convention_FRM C
                LEFT JOIN CTE_ImpotFermeture I ON I.iID_Convention = C.ConventionID AND I.Row_Num = 1
            WHERE
                I.iID_Impot_Special IS NULL
                OR I.tiCode_Version = 1
        )
        SELECT
            C.Conventionid, C.ConventionNo, C.StatutID, C.StatutDate,
            Solde_CreditBase = CAST(0 AS MONEY), --ISNULL(S.Credit_Base, 0), 
            Solde_Majoration = CAST(0 AS MONEY), --IsNull(S.Majoration, 0), 
            Solde_Interet = CAST(0 AS MONEY) --IsNull(S.Interet, 0)
        INTO #TB_Convention_06_91
        FROM
            CTE_Convention C
            --LEFT JOIN dbo.fntIQEE_CalculerSoldeIQEE_PourRQ(NULL, @siAnnee_Fiscale, GetDate()) S ON S.iID_Convention = C.ConventionID
            --LEFT JOIN dbo.fntIQEE_CalculerSoldeIQEE_ParConvention(NULL, GetDate(), 0) S ON S.ConventionID = C.ConventionID
        SET @iCount = @@ROWCOUNT
        SET @ElapseTime = GetDate() - @QueryTimer

        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    » ' + LTrim(Str(@iCount)) + ' retrouvées (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR(20), @ElapseTime, 120), 6) + ')'
--        SELECT *, @dtFinCotisation FROM #TB_Convention_06_91 

        SET ROWCOUNT 0

        IF NOT EXISTS(SELECT TOP 1 * FROM #TB_Convention_06_91)
           RETURN

        IF @iCount < 5
            SET @MaxRow = @iCount

        PRINT '   ' + Convert(varchar(20), GetDate(), 120) + '   - Ajustement des soldes selon les nouvelles transactions en cours'
        SET @QueryTimer = GetDate()

        --;WITH CTE_ImpotSpecial AS (
        --    SELECT I.iID_Convention,
        --           tiInverser_Signe = CASE I.tiCode_Version WHEN 1 THEN 1 ELSE -1 END,
        --           I.mSolde_IQEE_Base, I.mSolde_IQEE_Majore,
        --           RowNum = ROW_NUMBER() OVER(PARTITION BY I.iID_Convention, I.siAnnee_Fiscale, I.iID_Sous_Type ORDER BY I.iID_Impot_Special DESC)
        --      FROM #TB_Convention_06_91 C 
        --           JOIN dbo.tblIQEE_ImpotsSpeciaux I ON C.conventionID = I.iID_Convention
        --     WHERE 0=1
        --       AND I.iID_Fichier_IQEE = @iID_Fichier_IQEE
        --       AND NOT I.cStatut_Reponse IN ('E','X')
        --       AND I.iID_Sous_Type <> @iID_SousTypeEnregistrement
        --       --AND I.mIQEE_ImpotSpecial <> 0
        --),
        --CTE_Solde AS (
        --    SELECT iID_Convention, 
        --           mCreditBase = SUM(ISNULL(mSolde_IQEE_Base, 0) * tiInverser_Signe),
        --           mMajoration = SUM(ISNULL(mSolde_IQEE_Majore, 0) * tiInverser_Signe)
        --      FROM CTE_ImpotSpecial
        --     WHERE RowNum = 1
        --     GROUP BY iID_Convention
        --)
        UPDATE C SET 
            Solde_CreditBase = S.Credit_Base, -- + IsNull(I.mCreditBase, 0),
            Solde_Majoration = S.Majoration, -- + IsNull(I.mMajoration, 0),
            C.Solde_Interet = S.Interet
        FROM 
            #TB_Convention_06_91 C 
            JOIN dbo.fntIQEE_CalculerSoldeIQEE_ParConvention(NULL, GetDate(), 0) S ON S.ConventionID = C.ConventionID
            --LEFT JOIN CTE_Solde I ON I.iID_Convention = C.conventionID

        SET @iCount = @@ROWCOUNT
        SET @ElapseTime = GetDate() - @QueryTimer

        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    » ' + LTrim(Str(@iCount)) + ' ajustés (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR(20), @ElapseTime, 120), 6) + ')'
    END

    IF @IsDebug <> 0 AND @MaxRow between 1 and 10
        select * 
        from #TB_Convention_06_91 TB
        ORDER BY TB.ConventionNo
    
    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + '   - Récupération les infos des bénéficiaire'
    BEGIN
        IF Object_ID('tempDB..#TB_Beneficiary_06_91') IS NOT NULL
            DROP TABLE #TB_Beneficiary_06_91

        SET @QueryTimer = GetDate()
        ;WITH CTE_Beneficiary as (
            SELECT 
                CB.iID_Convention,
                iID_Beneficiary = CB.iID_Beneficiaire,
                vcNAS = CB.NAS, 
                vcNom = LTRIM(CB.Nom), 
                vcPrenom = LTRIM(CB.Prenom), 
                dtNaissance = CB.DateNaissance, 
                cSexe = CB.Sexe
            FROM 
                #TB_Convention_06_91 TB
                JOIN dbo.fntCONV_ObtenirBeneficiaireParConventionEnDate(@dtFinCotisation, DEFAULT) CB ON CB.iID_Convention = TB.ConventionID
        )
        SELECT 
            TB.*,
            vcNomPrenom = dbo.fn_Mo_FormatHumanName(TB.vcNom, '', TB.vcPrenom, '', '', 0)
        INTO
            #TB_Beneficiary_06_91
        FROM 
            CTE_Beneficiary TB
            JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = TB.iID_Beneficiary
        SET @iCount = @@ROWCOUNT
        SET @ElapseTime = GetDate() - @QueryTimer
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » ' + LTrim(Str(@iCount)) + ' retrouvées (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR(20), @ElapseTime, 120), 6) + ')'
    END
    
    IF @IsDebug <> 0 AND @MaxRow between 1 and 10
        select TB.ConventionNo, B.* 
        from #TB_Convention_06_91 TB JOIN #TB_Beneficiary_06_91 B ON B.iID_Convention = TB.ConventionID
        ORDER BY TB.ConventionNo

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
            CREATE TABLE #TB_Rejets_06_91 (
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
        IF OBJECT_ID('tempdb..#TB_Validation_06_91') IS NOT NULL
            DROP TABLE #TB_Validation_06_91

        SELECT 
            V.iOrdre_Presentation, V.iID_Validation, V.iCode_Validation, V.cType, V.vcDescription_Parametrable as vcDescription
        INTO
            #TB_Validation_06_91
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
        WHILE Exists(SELECT TOP 1 * FROM #TB_Validation_06_91 WHERE iOrdre_Presentation > @iOrdre_Presentation) 
        BEGIN
            SET @iCountRejets = 0

            SELECT TOP 1
                @iOrdre_Presentation = iOrdre_Presentation,
                @iID_Validation = iID_Validation, 
                @iCode_Validation = iCode_Validation,
                @vcDescription = vcDescription,
                @cType = cType
            FROM
                #TB_Validation_06_91 
            WHERE
                iOrdre_Presentation > @iOrdre_Presentation
            ORDER BY 
                iOrdre_Presentation

            PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '   - Validation #' + LTrim(Str(@iCode_Validation)) + ': ' + @vcDescription

            BEGIN TRY
                -- Validation : L'impôt spécial de fermeture de convention a déjà été envoyé et une réponse reçue de RQ
                IF @iCode_Validation = 601 
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.StatutID, I.tiCode_Version, I.cStatut_Reponse,
                            Row_Num = ROW_NUMBER() OVER(PARTITION BY C.conventionID ORDER BY I.iID_Impot_Special DESC)
                        FROM
                            #TB_Convention_06_91 C
                            JOIN dbo.tblIQEE_ImpotsSpeciaux I ON I.iID_Convention = C.ConventionID
                            JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = I.iID_Fichier_IQEE 
                        WHERE
                            I.iID_Sous_Type = @iID_SousTypeEnregistrement
                            AND I.iID_Statut_Convention = C.StatutID
                    )
                    INSERT INTO #TB_Rejets_06_91 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, StatutID, NULL, NULL
                    FROM
                        CTE_Convention
                    WHERE
                        Row_Num = 1
                        AND (tiCode_Version IN (0,2) AND cStatut_Reponse = 'R')

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : L'impôt spécial de fermeture de convention est en cours de traitement par RQ et est en attente d’une réponse de Revenu Québec
                IF @iCode_Validation = 602 
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.StatutID, I.tiCode_Version, I.cStatut_Reponse,
                            Row_Num = ROW_NUMBER() OVER(PARTITION BY C.conventionID ORDER BY I.iID_Impot_Special DESC)
                        FROM
                            #TB_Convention_06_91 C
                            JOIN dbo.tblIQEE_ImpotsSpeciaux I ON I.iID_Convention = C.ConventionID
                            JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = I.iID_Fichier_IQEE 
                        WHERE
                            I.iID_Sous_Type = @iID_SousTypeEnregistrement
                            AND I.iID_Statut_Convention = C.StatutID
                    )
                    INSERT INTO #TB_Rejets_06_91 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, StatutID, NULL, NULL
                    FROM
                        CTE_Convention
                    WHERE
                        Row_Num = 1
                        AND (
                                (tiCode_Version IN (0,2) AND cStatut_Reponse = 'A')
                                OR (tiCode_Version = 1 AND cStatut_Reponse = 'D')
                            )

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le NAS du bénéficiaire relié à la fermeture de convention est absent ou invalide
                IF @iCode_Validation = 604 
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.StatutID, B.iID_Beneficiary, B.vcNomPrenom, B.vcNAS
                        FROM
                            #TB_Convention_06_91 C
                            JOIN #TB_Beneficiary_06_91 B ON B.iID_Convention = C.ConventionID
                        WHERE
                            dbo.FN_CRI_CheckSin(B.vcNAS, 0) = 0
                    )
                    INSERT INTO #TB_Rejets_06_91 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(@vcDescription,'%vcBeneficiaire%', vcNomPrenom),
                        NULL, vcNAS, StatutID, iID_Beneficiary, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le nom du bénéficiaire relié à la fermeture de convention est absent
                IF @iCode_Validation = 605 
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.StatutID, B.iID_Beneficiary, B.vcNomPrenom, B.vcNom
                        FROM
                            #TB_Convention_06_91 C
                            JOIN #TB_Beneficiary_06_91 B ON B.iID_Convention = C.ConventionID
                        WHERE
                            Len(IsNull(B.vcNom, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_06_91 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(@vcDescription,'%vcBeneficiaire%', vcNomPrenom),
                        NULL, NULL, StatutID, iID_Beneficiary, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le prénom du bénéficiaire relié à la fermeture de convention est absent
                IF @iCode_Validation = 606
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.StatutID, B.iID_Beneficiary, B.vcNomPrenom, B.vcPrenom
                        FROM
                            #TB_Convention_06_91 C
                            JOIN #TB_Beneficiary_06_91 B ON B.iID_Convention = C.ConventionID
                        WHERE
                            Len(IsNull(B.vcPrenom, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_06_91 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(@vcDescription,'%vcBeneficiaire%', vcNomPrenom),
                        NULL, NULL, StatutID, iID_Beneficiary, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : La date de naissance du bénéficiaire reliée à la fermeture de convention est absente
                IF @iCode_Validation = 607
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.StatutID, B.iID_Beneficiary, B.vcNomPrenom, B.dtNaissance
                        FROM
                            #TB_Convention_06_91 C
                            JOIN #TB_Beneficiary_06_91 B ON B.iID_Convention = C.ConventionID
                        WHERE
                            B.dtNaissance IS NULL
                    )
                    INSERT INTO #TB_Rejets_06_91 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(@vcDescription,'%vcBeneficiaire%', vcNomPrenom),
                        NULL, NULL, StatutID, iID_Beneficiary, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : La date de naissance du bénéficiaire reliée à la fermeture de convention est invalide
                IF @iCode_Validation = 608
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.StatutID, C.StatutDate, B.iID_Beneficiary, B.vcNomPrenom, B.dtNaissance
                        FROM
                            #TB_Convention_06_91 C
                            JOIN #TB_Beneficiary_06_91 B ON B.iID_Convention = C.ConventionID
                        WHERE
                            B.dtNaissance > C.StatutDate
                    )
                    INSERT INTO #TB_Rejets_06_91 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(@vcDescription,'%vcBeneficiaire%', vcNomPrenom),
                        CONVERT(VARCHAR(10), StatutDate, 120), CONVERT(VARCHAR(10), dtNaissance, 120), StatutID, iID_Beneficiary, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le sexe du bénéficiaire relié à la fermeture de convention n’est pas défini
                IF @iCode_Validation = 609
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.StatutID, C.StatutDate, B.iID_Beneficiary, B.vcNomPrenom, B.cSexe
                        FROM
                            #TB_Convention_06_91 C
                            JOIN #TB_Beneficiary_06_91 B ON B.iID_Convention = C.ConventionID
                        WHERE
                            NOT IsNull(B.cSexe, '') IN ('M', 'F')
                    )
                    INSERT INTO #TB_Rejets_06_91 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(@vcDescription,'%vcBeneficiaire%', vcNomPrenom),
                        NULL, cSexe, StatutID, iID_Beneficiary, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le prénom du bénéficiaire relié à la fermeture de convention contient au moins 1 caractère non conforme
                IF @iCode_Validation = 610
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.StatutID, C.StatutDate, B.iID_Beneficiary, B.vcNomPrenom, B.vcPrenom, 
                            CaractereNonConforme = dbo.fnIQEE_ValiderNom(B.vcPrenom)
                        FROM
                            #TB_Convention_06_91 C
                            JOIN #TB_Beneficiary_06_91 B ON B.iID_Convention = C.ConventionID
                        WHERE
                            Len(vcPrenom) > 0
                    )
                    INSERT INTO #TB_Rejets_06_91 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(@vcDescription,'%vcBeneficiaire%', vcNomPrenom),'%vcCaractereNonConforme%', CaractereNonConforme),
                        NULL, vcPrenom, StatutID, iID_Beneficiary, NULL
                    FROM
                        CTE_Convention
                    WHERE
                        Len(CaractereNonConforme) > 0

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le nom du bénéficiaire relié à la fermeture de convention contient au moins 1 caractère non conforme
                IF @iCode_Validation = 611
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.StatutID, C.StatutDate, B.iID_Beneficiary, B.vcNomPrenom, B.vcNom, 
                            CaractereNonConforme = dbo.fnIQEE_ValiderNom(B.vcNom)
                        FROM
                            #TB_Convention_06_91 C
                            JOIN #TB_Beneficiary_06_91 B ON B.iID_Convention = C.ConventionID
                        WHERE
                            Len(B.vcNom) > 0
                    )
                    INSERT INTO #TB_Rejets_06_91 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(@vcDescription,'%vcBeneficiaire%', vcNomPrenom),'%vcCaractereNonConforme%', CaractereNonConforme),
                        NULL, vcNom, StatutID, iID_Beneficiary, NULL
                    FROM
                        CTE_Convention
                    WHERE
                        Len(CaractereNonConforme) > 0

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Les transactions de la convention sont retenues parce qu'elle a fait l'objet de transactions manuelles de l'IQÉÉ avant que les transactions soient implantées dans UniAccès
                -- TODO
                IF @iCode_Validation = 612
                BEGIN
                    --; WITH CTE_Demande as (
                    --    SELECT
                    --        D.ConventionID
                    --    FROM
                    --        #TB_Demande_06_91 D
                    --    WHERE
                    --        D.ConventionStateID = 'PRP'
                    --)
                    --INSERT INTO #TB_Rejets_06_91 (
                    --    iID_Convention, iID_Validation, vcDescription,
                    --    vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    --)
                    --SELECT 
                    --    ConventionID, @iID_Validation, @vcDescription,
                    --    NULL, NULL, D.ConventionID, NULL, NULL
                    --FROM
                    --    CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : La convention a été fermée par une transaction d'impôt spécial 51
                IF @iCode_Validation = 613
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT DISTINCT
                            C.ConventionID, C.StatutID
                        FROM
                            #TB_Convention_06_91 C
                        WHERE
                            Exists (
                                SELECT * FROM dbo.tblIQEE_ImpotsSpeciaux I
                                              JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = I.iID_Fichier_IQEE 
                                              JOIN dbo.vwIQEE_Enregistrement_TypeEtSousType T ON T.iID_Sous_Type = I.iID_Sous_Type
                                                                                             AND T.cCode_Sous_Type = '51'
                                WHERE 
                                    I.iID_Convention = C.ConventionID
                                    AND I.iID_Statut_Convention = C.StatutID
                                    AND I.cStatut_Reponse IN ('A','R')
                            )
                    )
                    INSERT INTO #TB_Rejets_06_91 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, StatutID, NULL, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le transfert doit être déclaré à RQ avant que la convention puisse être fermée
                IF @iCode_Validation = 619
                BEGIN
                    INSERT INTO #TB_Rejets_06_91 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT
                        TB.ConventionID, @iID_Validation, REPLACE(REPLACE(@vcDescription, '%dtTransfert%', CONVERT(VARCHAR(10), T.OperDate, 120)), '%OperTypeID%', T.OperTypeID), 
                        NULL, NULL, NULL, NULL, NULL
                    FROM
                        dbo.fntIQEE_Transfert_NonDeclare(DEFAULT, @dtFinCotisation) T
                        JOIN #TB_Convention_06_91 TB ON TB.ConventionID = T.ConventionID
                    WHERE
                        T.OperDate < @dtFinCotisation

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : L'impôt spécial est < 0
                IF @iCode_Validation = 620
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT DISTINCT
                            C.ConventionID, C.ConventionNo, C.StatutID
                        FROM
                            #TB_Convention_06_91 C
                        WHERE
                            Solde_CreditBase + Solde_Majoration < 0
                    )
                    INSERT INTO #TB_Rejets_06_91 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, StatutID, NULL, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Les PAEs de la convention doivent être déclarés à RQ avant que la convention puisse être fermée
                IF @iCode_Validation = 621
                BEGIN
                    INSERT INTO #TB_Rejets_06_91 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        TB.ConventionID, @iID_Validation, REPLACE(REPLACE(@vcDescription, '%dtPaiement%', CONVERT(VARCHAR(10), PB.OperDate, 120)), '%ScholarshipNo%', TB.ConventionNo),
                        NULL, NULL, NULL, NULL, NULL
                    FROM
                        dbo.fntIQEE_PaiementBeneficiaire_NonDeclare(DEFAULT, @dtFinCotisation) PB
                        JOIN #TB_Convention_06_91 TB ON TB.ConventionID = PB.ConventionID
                    WHERE
                        PB.OperDate < @dtFinCotisation

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : La convention a des cas spéciaux non résolus avec Revenu Québec en cours
                IF @iCode_Validation = 622
                BEGIN
                    IF @bit_CasSpecial = 0
                        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » Skipped - Ce sont des cas spéciaux'
                    ELSE
                    BEGIN
                        ; WITH CTE_Convention as (
                            SELECT DISTINCT
                                C.ConventionID, C.ConventionNo, C.StatutID
                            FROM
                                #TB_Convention_06_91 C
                                JOIN dbo.tblIQEE_CasSpeciaux CS ON CS.iID_Convention = C.ConventionID
                            WHERE
                                CS.bCasRegle = 0
                                AND ISNULL(CS.tiID_TypeEnregistrement, @tiID_TypeEnregistrement) = @tiID_TypeEnregistrement
                                AND ISNULL(CS.iID_SousType, @iID_SousTypeEnregistrement) = @iID_SousTypeEnregistrement
                        )
                        INSERT INTO #TB_Rejets_06_91 (
                            iID_Convention, iID_Validation, vcDescription,
                            vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                        )
                        SELECT 
                            ConventionID, @iID_Validation, REPLACE(@vcDescription, '%vcNo_Convention%', ConventionNo),
                            NULL, NULL, StatutID, NULL, NULL
                        FROM
                            CTE_Convention

                        SET @iCountRejets = @@ROWCOUNT
                    END
                END

                -- Validation : Une demande de subvention est en cours de traitement par RQ et est en attente d’une réponse de Revenu Québec
                IF @iCode_Validation = 623
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, D.iID_Ligne_Fichier
                        FROM
                            #TB_Convention_06_91 C
                            JOIN dbo.tblIQEE_Demandes D ON D.iID_Convention = C.ConventionID
                            JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
                        WHERE
                            D.cStatut_Reponse = 'A'
                    )
                    INSERT INTO #TB_Rejets_06_91 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, iID_Ligne_Fichier, NULL, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Un remplacement de bénéficiaire est en cours de traitement par RQ et est en attente d’une réponse de Revenu Québec
                IF @iCode_Validation = 624
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, RB.iID_Ligne_Fichier
                        FROM
                            #TB_Convention_06_91 C
                            JOIN dbo.tblIQEE_RemplacementsBeneficiaire RB ON RB.iID_Convention = C.ConventionID
                            JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = RB.iID_Fichier_IQEE
                        WHERE
                            RB.cStatut_Reponse = 'A'
                    )
                    INSERT INTO #TB_Rejets_06_91 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, iID_Ligne_Fichier, NULL, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Un transfert de convention est en cours de traitement par RQ et est en attente d’une réponse de Revenu Québec
                IF @iCode_Validation = 625
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, T.iID_Ligne_Fichier
                        FROM
                            #TB_Convention_06_91 C
                            JOIN dbo.tblIQEE_Transferts T ON T.iID_Convention = C.ConventionID
                            JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = T.iID_Fichier_IQEE
                        WHERE
                            T.cStatut_Reponse = 'A'
                    )
                    INSERT INTO #TB_Rejets_06_91 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, iID_Ligne_Fichier, NULL, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Un paiement d'aide au bénéficiaire est en cours de traitement par RQ et est en attente d’une réponse de Revenu Québec
                IF @iCode_Validation = 626
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, PB.iID_Ligne_Fichier
                        FROM
                            #TB_Convention_06_91 C
                            JOIN dbo.tblIQEE_PaiementsBeneficiaires PB ON PB.iID_Convention = C.ConventionID
                            JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = PB.iID_Fichier_IQEE
                        WHERE
                            PB.cStatut_Reponse = 'A'
                    )
                    INSERT INTO #TB_Rejets_06_91 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, iID_Ligne_Fichier, NULL, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Un autre type d'impôt spécial pour la convention est en cours de traitement par RQ et est en attente d’une réponse de Revenu Québec
                IF @iCode_Validation = 627
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, I.iID_Ligne_Fichier
                        FROM
                            #TB_Convention_06_91 C
                            JOIN dbo.tblIQEE_ImpotsSpeciaux I ON I.iID_Convention = C.ConventionID
                            JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = I.iID_Fichier_IQEE
                        WHERE
                            I.cStatut_Reponse = 'A'
                    )
                    INSERT INTO #TB_Rejets_06_91 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, iID_Ligne_Fichier, NULL, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                --;

                BEGIN
                    -- Validation : Une erreur soulevée par Revenu Québec est en cours de traitement pour l'impôt spécial de fermeture de convention.
                    IF @iCode_Validation = 603 
                    BEGIN
                        ; WITH CTE_Convention as (
                            SELECT
                                C.ConventionID, C.StatutID
                            FROM
                                #TB_Convention_06_91 C
                                JOIN dbo.tblIQEE_ImpotsSpeciaux I ON I.iID_Convention = C.ConventionID 
                                                                 AND I.iID_Statut_Convention = C.StatutID
                                JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = I.iID_Fichier_IQEE 
                                JOIN dbo.tblIQEE_Erreurs E ON E.iID_Enregistrement = I.iID_Impot_Special
                                JOIN dbo.tblIQEE_StatutsErreur SE ON SE.tiID_Statuts_Erreur = E.tiID_Statuts_Erreur 
                                                                 AND SE.vcCode_Statut = 'ATR'
                            WHERE 
                                E.tiID_Type_Enregistrement = @tiID_TypeEnregistrement
                                AND I.iID_Sous_Type = @iID_SousTypeEnregistrement
                                AND I.cStatut_Reponse = 'E'
                        )
                        INSERT INTO #TB_Rejets_06_91 (
                            iID_Convention, iID_Validation, vcDescription,
                            vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                        )
                        SELECT 
                            ConventionID, @iID_Validation, @vcDescription,
                            NULL, NULL, StatutID, NULL, NULL
                        FROM
                            CTE_Convention

                        SET @iCountRejets = @@ROWCOUNT
                    END

                    -- Validation : Toutes les bourses ou PAE ont été payées mais il reste des montants d'IQÉÉ dans la convention
                    IF @iCode_Validation = 614
                    BEGIN
                        ; WITH CTE_Convention as (
                            SELECT DISTINCT
                                C.ConventionID, C.StatutID
                            FROM
                                #TB_Convention_06_91 C
                            WHERE
                                Exists (
                                    SELECT * FROM dbo.Un_Unit U
                                                  JOIN dbo.fntCONV_ObtenirStatutUnitEnDate_PourTous(@dtFinCotisation, NULL) UUS ON UUS.UnitID = U.UnitID
                                    WHERE 
                                        U.ConventionID = C.ConventionID
                                        AND UUS.UnitStateID IN ('PVR','BTP')
                                )
                        )
                        INSERT INTO #TB_Rejets_06_91 (
                            iID_Convention, iID_Validation, vcDescription,
                            vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                        )
                        SELECT 
                            ConventionID, @iID_Validation, @vcDescription,
                            NULL, NULL, StatutID, NULL, NULL
                        FROM
                            CTE_Convention
                        WHERE
                            IsNull(dbo.fnIQEE_CalculerSoldeIQEE_Convention(ConventionID, @dtFinCotisation), 0) > 0

                        SET @iCountRejets = @@ROWCOUNT
                    END

                    -- Validation : La convention individuelle est issue d'un RIO où il reste des montants d'IQÉÉ dans la convention Universitas source
                    IF @iCode_Validation = 615
                    BEGIN
                        ; WITH CTE_Convention as (
                            SELECT DISTINCT
                                C.ConventionID, C.StatutID, 
                                Solde = Sum(CO.ConventionOperAmount) 
                            FROM
                                #TB_Convention_06_91 C
                                JOIN dbo.Un_ConventionOper CO ON CO.ConventionID = C.ConventionID
                            WHERE
                                Exists (
                                    SELECT * FROM dbo.tblOPER_OperationsRIO RIO
                                             LEFT JOIN dbo.tblIQEE_Transferts T ON (T.iID_Convention = RIO.iID_Convention_Source OR T.iID_Convention = RIO.iID_Convention_Destination)
                                                                               AND T.dtDate_Transfert = RIO.dtDate_Enregistrement
                                    WHERE 
                                        (RIO.iID_Convention_Source = C.ConventionID OR RIO.iID_Convention_Destination = C.ConventionID)
                                        AND RIO.bRIO_Annulee = 0
                                        AND RIO.bRIO_QuiAnnule = 0
                                )
                                AND CO.ConventionOperTypeID IN (
                                        SELECT cID_Type_Oper_Convention FROM dbo.fntOPER_ObtenirOperationsCategorie('IQEE_SOMMAIRE_PCEEIQEE_MAJORATION')
                                        UNION
                                        SELECT cID_Type_Oper_Convention FROM dbo.fntOPER_ObtenirOperationsCategorie('IQEE_SOMMAIRE_PCEEIQEE_CREDIT_BASE')
                                )
                            GROUP BY
                                C.ConventionID, C.StatutID
                        )
                        INSERT INTO #TB_Rejets_06_91 (
                            iID_Convention, iID_Validation, vcDescription,
                            vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                        )
                        SELECT 
                            ConventionID, @iID_Validation, @vcDescription,
                            NULL, NULL, StatutID, NULL, NULL
                        FROM
                            CTE_Convention
                        WHERE
                            Solde > 0

                        SET @iCountRejets = @@ROWCOUNT
                    END
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
                    iCode_Validation = 600

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
                    DELETE FROM #TB_Convention_06_91
                    WHERE EXISTS (SELECT * FROM #TB_Rejets_06_91 WHERE iID_Convention = ConventionID AND iID_Validation = @iID_Validation)
                END
            END
        END -- IF @iCode_Validation 

        -- Efface tous les conventions ayant eu au moins un rejet de validation
        DELETE FROM #TB_Convention_06_91
        WHERE EXISTS (SELECT * FROM #TB_Rejets_06_91 R JOIN dbo.tblIQEE_Validations V ON V.iID_Validation = R.iID_Validation WHERE V.cType = 'E' And iID_Convention = ConventionID)

        INSERT INTO dbo.tblIQEE_Rejets (
            iID_Fichier_IQEE, siAnnee_Fiscale, iID_Convention, iID_Validation, vcDescription,
            vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
            --,tCommentaires, iID_Utilisateur_Modification, dtDate_Modification
        )
        SELECT 
            @iID_Fichier_IQEE, @siAnnee_Fiscale, R.iID_Convention, R.iID_Validation, R.vcDescription,
            R.vcValeur_Reference, vcValeur_Erreur, R.iID_Lien_Vers_Erreur_1, R.iID_Lien_Vers_Erreur_2, R.iID_Lien_Vers_Erreur_3
        FROM 
            #TB_Rejets_06_91 R
    END

    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Déclaration des retraits de cotisations'
    BEGIN
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '   Créer les enregistrements d''impôt spéciaux.'
        SET @QueryTimer = GetDate()
        ; WITH CTE_Sexe as (
            SELECT X.rowID as ID, X.strField as Code
            FROM ProAcces.fn_SplitIntoTable('F,M', ',') X
        )
        INSERT INTO dbo.tblIQEE_ImpotsSpeciaux (
            iID_Fichier_IQEE, siAnnee_Fiscale, tiCode_Version, cStatut_Reponse, iID_Convention, vcNo_Convention,
            iID_Sous_Type, iID_Statut_Convention, dtDate_Evenement, 
            mSolde_IQEE_Base, mSolde_IQEE_Majore, mIQEE_ImpotSpecial, mRadiation,
            iID_Beneficiaire, vcNAS_Beneficiaire, vcNom_Beneficiaire, vcPrenom_Beneficiaire, dtDate_Naissance_Beneficiaire, tiSexe_Beneficiaire,
            mMontant_AFixe, mEcart_ReelvsFixe
        )
        SELECT
            @iID_Fichier_IQEE, @siAnnee_Fiscale, @tiCode_Version, 'A', C.ConventionID, Left(C.ConventionNo, 15),
            @iID_SousTypeEnregistrement, C.StatutID, C.StatutDate,
            C.Solde_CreditBase, C.Solde_Majoration , C.Solde_CreditBase + c.Solde_Majoration, NULL,
            B.iID_Beneficiary, B.vcNAS, Left(B.vcNom, 20), Left(B.vcPrenom, 20), B.dtNaissance, (SELECT ID FROM CTE_Sexe WHERE Code = B.cSexe),
            NULL, NULL
        FROM
            #TB_Convention_06_91 C
            JOIN #TB_Beneficiary_06_91 B ON B.iID_Convention = C.ConventionID

        SET @iCount = @@RowCount
        SET @ElapseTime = @QueryTimer - GetDate()
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    » ' + LTrim(Str(@iCount)) + ' enregistrements ajoutés (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR(20), @ElapseTime, 120), 6) + ')'

        IF @iCount > 0
            IF EXISTS(SELECT * FROM dbo.tblIQEE_Fichiers WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE AND bInd_Simulation = 0) 
                EXEC dbo.psIQEE_CreerOperationFinanciere_ImpotsSpeciaux @iID_Utilisateur_Creation, @iID_Fichier_IQEE, @iID_SousTypeEnregistrement
    END

    SET @ElapseTime = GetDate() - @StartTimer
    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' EXEC psIQEE_CreerTransactions06_91 completed' 
                + ' (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR(20), @ElapseTime, 120), 6) + ')'

    IF OBJECT_ID('tempdb..#TB_Validation_06_91') IS NOT NULL
        DROP TABLE #TB_Validation_06_91
    IF OBJECT_ID('tempdb..#TB_Rejets_06_91') IS NOT NULL
        DROP TABLE #TB_Rejets_06_91
    IF OBJECT_ID('tempdb..#TB_Beneficiary_06_91') IS NOT NULL
        DROP TABLE #TB_Beneficiary_06_91
    IF OBJECT_ID('tempdb..#TB_Convention_06_91') IS NOT NULL
        DROP TABLE #TB_Convention_06_91

    -- Retourner 0 si le traitement est réussi
    RETURN 0
END
