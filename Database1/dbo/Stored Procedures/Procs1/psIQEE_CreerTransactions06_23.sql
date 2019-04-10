/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service : psIQEE_CreerTransactions06_23
Nom du service  : Créer les transactions de  type 06, sous type 23 - Retrait et bénéficiaire admissible au PAE
But             : Sélectionner, valider et créer les transactions de type 06 – Impôt spécial, 23 - Retrait et
                  bénéficiaire admissible au PAE, dans un nouveau fichier de transactions de l’IQÉÉ.
Facette         : IQÉÉ

Paramètres d’entrée :
        Paramètre                    Description
        --------------------    -----------------------------------------------------------------
        iID_Fichier_IQEE        Identifiant du nouveau fichier de transactions dans lequel les transactions 06-23 doivent être créées.
        bFichiers_Test          Indicateur si les fichiers test doivent être tenue en compte dans la production du fichier.  
                                Pour fins d’essais et de simulations il est possible de tenir compte des fichiers tests comme des fichiers de production.
                                S’il est absent, les fichiers test ne sont pas considérés.
        iID_Convention          Identifiant unique de la convention pour laquelle la création des fichiers est demandée. La convention doit exister.
        bArretPremiereErreur    Indicateur si le traitement doit s’arrêter après le premier message d’erreur.  
                                S’il est absent, les validations n’arrêtent pas à la première erreur.
        cCode_Portee            Code permettant de définir la portée des validations.
                                    « T » =  Toutes les validations
                                    « A » = Toutes les validations excepter les avertissements (Erreurs seulement)
                                    « I » = Uniquement les validations sur lesquelles il est possible d’intervenir afin de les corriger
                                    S’il est absent, toutes les validations sont considérées.
        bit_CasSpecial          Indicateur pour permettre la résolution de cas spéciaux sur des T02 dont le délai de traitement est dépassé.                                                     

Exemple d’appel : exec [dbo].[psIQEE_CreerTransactions06_23] 10, 0, NULL, 0, 'T',0

Paramètres de sortie :
    Champ                   Description
    --------------------    ---------------------------------
    iCode_Retour            = 0 : Exécution terminée normalement
                            < 0 : Erreur de traitement

Historique des modifications:
    Date        Programmeur             Description
    ----------  --------------------    ------------------------------------------------------------------
    2009-02-17  Éric Deshaies           Création du service                            
    2012-08-17  Dominique Pothier       Désactivation validation 514
    2012-08-17  Stéphane Barbeau        Nouvelle requête pour curseur curImpotSpecial23
    2012-08-28  Stéphane Barbeau        Ajout d'une requête séparée pour trouver le code postal de l'établissement au moment de l'événement.
    2013-02-01  Stéphane Barbeau        Attribution par défaut du statut 'R' jusqu'à nouvel ordre.
    2013-02-26  Stéphane Barbeau        Curseur curImpotSpecial23: Requête bonifiée pour vérifier l'existence d'opérations sur les compte CBQ et MMQ avant la date de l'événement.
                                        Ajout de la validation 516.
    2013-03-04  Stéphane Barbeau        Correction de la requête bonifiée pour curseur curImpotSpecial23.
    2013-03-11  Stéphane Barbeau        Ajustement requête bonifiée curImpotSpecial23: and OP.OperDate <= CP.OperDate        
    2013-08-01  Stéphane Barbeau        Désactivation validation 503
    2013-10-18  Stéphane Barbeau        Réduction des Appels à psIQEE_AjouterRejet pour le rejet générique: condition IF @iResultat <= 0 changée pour IF @iResultat <> 0
                                            Raison: Unless documented otherwise, all system stored procedures return a value of 0. This indicates success and a nonzero value indicates failure.
    2013-11-06  Stéphane Barbeau        Requête curImpotSpecial23: Ajout du paramètre CP.OperDate dans la fonction fnIQEE_ConventionConnueRQ.
                                                                   Exclusion si impôt spécial 91 déjà créé.                                                
    2013-12-13  Stéphane Barbeau        Requête -- S'il n'y a pas d'erreur, créer la transaction 06-23: Retrait de la condition AND R.iID_Lien_Vers_Erreur_1 = @iID_Cotisation                                                                               
    2014-03-20  Stéphane Barbeau        Insert tblIQEE_ImpotsSpeciaux: cStatut_Reponse='A' (Confirmation RQ novembre 2013)
    2014-06-27  Stéphane Barbeau        Retrait de la validation 516.
    2014-08-14  Stéphane Barbeau        Ajout de la validation 517 et du paramètre @bit_CasSpecial.
    2014-12-14  Stéphane Barbeau        Régression à la version 2014-08-14 pour régler bloquage du traitement global en lots de l'IQEE.
    2015-12-16  Steeve Picard           Activation de la validation #503
    2016-01-08  Steeve Picard           Correction au niveau des validations pour tenir compte de la Convention_ID
    2016-02-02  Steeve Picard           Optimisation en remplaçant les curseurs SQL par des boucles WHILE
    2016-02-19  Steeve Picard           Retrait des 2 derniers paramètres de « fnIQEE_ConventionConnueRQ »
    2016-12-02  Steeve Picard           Optimisation en traitant par batch et non une convention à la fois
    2017-06-09  Steeve Picard           Ajout du paramètre « @tiCode_Version = 0 » pour passer la valeur « 2 » lors d'une annulation/reprise
    2017-07-11  Steeve Picard           Élimination du paramètre « iID_Convention » pour toujours utiliser la table « #TB_ListeConvention »
    2017-08-10  Steeve Picard           Forcer le « cStatut_Reponse = R » pour reçu car on ne reçois pas de réponse
    2017-08-22  Steeve Picard           Utilisation du NAS courant du bénéficiaire au lieu de celui dans l'historique
    2017-12-19  Steeve Picard           Modificiation à la fonction «fntIQEE_CalculerMontantsDemande_PourTous» qui retourne la «RIN_SansPreuve» au lieu de la «RIN_AvecPreuve»
    2018-01-04  Steeve Picard           Validation de base si @cCode_Portee = '' pour l'estimation du rapport à recevoir
    2018-02-08  Steeve Picard           Déplacement de «siAnnee_Fiscale» de la table «tblIQEE_Fichiers» vers les tables d'évèments «tblIQEE_ImpotsSpeciaux»
    2018-02-26  Steeve Picard           Empêcher que la «dtFinCotisation» soit plus grande que la dernière fin de mois
    2018-06-06  Steeve Picard           Modificiation de la gestion des retours d'erreur par RQ
    2018-09-19  Steeve Picard           Ajout du champ «iID_SousType» à la table «tblIQEE_CasSpeciaux» pour pouvoir filtrer
    2018-11-14  Steeve Picard           Utilisation de la fonction «fntIQEE_CalculerMontantsDemande_Details» pour trouver les «RIN» avec preuve
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_CreerTransactions06_23]
(
    @iID_Fichier_IQEE INT,
    @siAnnee_Fiscale SMALLINT,
    @bArretPremiereErreur BIT,
    @cCode_Portee CHAR(1),
    @bit_CasSpecial BIT,
    @tiCode_Version TINYINT = 0
)
AS
BEGIN
    SET NOCOUNT ON

    PRINT ''
    PRINT 'Impôt spécial de sous type 23 - Retrait et bénéficiaire admissible au PAE (T06-23) pour ' + STR(@siAnnee_Fiscale, 4)
    PRINT '--------------------------------------------------------------------------------------------'
    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' EXEC psIQEE_CreerTransactions06_23 started'

    IF Object_ID('tempDB..#TB_ListeConvention') IS NULL
        RAISERROR ('La table « #TB_ListeConvention (RowNo INT Identity(1,1), ConventionID int, ConventionNo varchar(20) » est abesente ', 16, 1)

    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Identifie le(s) convention(s)'
    DECLARE @iCount int = (SELECT Count(*) FROM #TB_ListeConvention)
    IF @iCount > 0
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '   - ' + LTrim(Str(@iCount)) + ' conventions à génèrées'

    DECLARE @StartTimer datetime = GetDate(),
            @QueryTimer datetime,
            @ElapseTime datetime,
            @MaxRow INT = 0,
            @IntervalPrint int = 5000,
            @IsDebug bit = dbo.fn_IsDebug()

    --  Déclaration des variables
    BEGIN 
        DECLARE 
            @tiID_TypeEnregistrement TINYINT,               @iID_SousTypeEnregistrement INT,
            @dtDebutCotisation DATETIME,                    @dtFinCotisation DATETIME,
            @vcNo_Convention VARCHAR(15),                   @dtMaxCotisation DATETIME = DATEADD(DAY, -DAY(GETDATE()), GETDATE())
    
        -- Sélectionner dates applicables aux transactions
        SELECT @dtDebutCotisation = Str(@siAnnee_Fiscale, 4) + '-01-01 00:00:00',
                @dtFinCotisation = STR(@siAnnee_Fiscale, 4) + '-12-31 23:59:59'

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
        AND cCode_Sous_Type = '23'

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

    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Récupération des retraits de cotisation avec preuve à déclarer'
    BEGIN
        IF OBJECT_ID('tempdb..#TB_Convention_06_23') IS NOT NULL
            DROP TABLE #TB_Convention_06_23

        -- SB 2013-03-11: Requête bonifiée pour vérifier l'existence d'opérations sur les compte CBQ et MMQ avant la date de l'événement 
        -- pour réduire le nombre d'erreur 3022 (Selon l'information que nous possédons, le bénéficiaire n'est plus lié à ce contrat au 
        -- moment de la transaction.) de RQ

        -- Identifier et sélectionner les retraits et bénéficiaire admissible au PAE
        SET @QueryTimer = GetDate()
        ;WITH 
        CTE_CP as (
            SELECT DISTINCT 
                X.ConventionID, X.ConventionNo, S.Date_Cotisation, S.CollegeID,
                Cotisations_Retirees = -Sum(CASE WHEN ISNULL(CollegeID, 0) IN (0, 4941) THEN 0 ELSE ISNULL(Cotisations_Transaction, 0) + IsNull(Frais, 0) END)
            FROM
                #TB_ListeConvention X
                JOIN dbo.fntIQEE_CalculerMontantsDemande_Details(NULL, @dtDebutCotisation, @dtFinCotisation) S ON S.ID_Convention = X.ConventionID
            WHERE
                X.dtReconnue_RQ IS NOT NULL
                AND ( NOT ISNULL(CollegeID, 0) IN (0, 4941)
                      OR ( YEAR(Date_Cotisation) >= 2012 
                           AND ( Code_Type_Operation IN ('RIN', 'TFR')
                                 OR ( Code_Type_Operation = 'FRS' AND X.ConventionNo LIKE 'T-%' )
                               )
                         )
                    )
            GROUP BY
                X.ConventionID, X.ConventionNo, S.Date_Cotisation, S.CollegeID
        ),
        CTE_ImpotSpecial AS (
            SELECT
                iID_Convention, dtDate_Evenement, tiCode_Version, cStatut_Reponse
            FROM (
                SELECT 
                    I.iID_Convention, I.dtDate_Evenement, I.tiCode_Version, I.cStatut_Reponse,
                    RowNum = ROW_NUMBER() OVER(PARTITION BY I.iID_Convention, I.dtDate_Evenement ORDER BY F.dtDate_Creation DESC, ISNULL(I.iID_Ligne_Fichier, 999999999), I.iID_Impot_Special DESC)
                FROM
                    #TB_ListeConvention X
                    JOIN dbo.tblIQEE_ImpotsSpeciaux I ON I.iID_Convention = X.ConventionID 
                    JOIN dbo.vwIQEE_Enregistrement_TypeEtSousType T ON T.iID_Sous_Type = I.iID_Sous_Type
                    JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = I.iID_Fichier_IQEE
                WHERE 0=0
                    AND I.siAnnee_Fiscale = @siAnnee_Fiscale
                    AND NOT I.cStatut_Reponse IN ('E','X')
                    AND T.cCode_Type_SousType = '06-23'
                ) X
            WHERE
                RowNum = 1
                AND tiCode_Version <> 1
                AND cStatut_Reponse IN ('A','R')        
        )
        SELECT DISTINCT 
            CP.ConventionID, CP.ConventionNo, CP.Date_Cotisation as dtTraitement, CP.CollegeID, Col.CollegeCode, 
            Cotisations_Retirees = CP.Cotisations_Retirees,
            -- Trouver le bénéficiaire au moment de l'événement
            BeneficiaryID = (SELECT TOP 1 iID_Nouveau_Beneficiaire FROM dbo.tblCONV_ChangementsBeneficiaire 
                              WHERE iID_Convention = CP.ConventionID And dtDate_Changement_Beneficiaire <= CP.Date_Cotisation 
                              ORDER BY dtDate_Changement_Beneficiaire DESC),
            Row_Num = Row_Number() OVER (ORDER BY CP.ConventionID, CP.Date_Cotisation, CP.CollegeID)
        INTO
            #TB_Convention_06_23
        FROM 
            CTE_CP CP
            LEFT JOIN dbo.UN_College Col ON Col.CollegeID = CP.CollegeID
            LEFT JOIN CTE_ImpotSpecial DIS ON DIS.iID_Convention = CP.ConventionID AND DIS.dtDate_Evenement = CP.Date_Cotisation
         WHERE
            (DIS.iID_Convention IS NULL)
            AND CP.Cotisations_Retirees > 0
            --AND (   SELECT  
            --            count(*) 
            --        FROM 
            --            dbo.Un_ConventionOper CO 
            --            JOIN dbo.Un_Oper OP ON CO.OperID=OP.OperID
            --        WHERE
            --            CO.ConventionID= CP.ConventionID
            --            AND CO.ConventionOperTypeID IN ('CBQ','MMQ')
            --            AND OP.OperDate <= CP.Date_Cotisation
            --    ) > 0
        SET @iCount = @@ROWCOUNT
        SET @ElapseTime = @QueryTimer - @QueryTimer

        DECLARE @iNbConvention INT = (SELECT Count(distinct ConventionID) FROM #TB_Convention_06_23)
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    » ' + LTrim(Str(@iCount)) + ' retrait à traitées pour ' + LTRIM(STR(@iNbConvention)) + ' conventions (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

        IF NOT EXISTS(SELECT TOP 1 * FROM #TB_Convention_06_23)
           RETURN

        IF @iCount < 5
            SET @MaxRow = @iCount

        IF @IsDebug <> 0 AND @MaxRow between 1 and 10
            select * from #TB_Convention_06_23 ORDER BY ConventionID

        DECLARE @RowNo INT = 0,
                @iID_Convention INT,
                @dtCotisation DATE,
                @mCotisationRetire MONEY,
                @mTotalCotisation MONEY

        --PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Récupération de la somme des cotisations des conventions dans l''année'
        --BEGIN

        --    IF OBJECT_ID('tempdb..#TB_Cotisation_06_23') IS NOT NULL
        --        DROP TABLE #TB_Cotisation_06_23

        --    SET @QueryTimer = GETDATE()
        --    ;WITH CTE_Convention AS (
        --        SELECT DISTINCT ConventionID
        --          FROM #TB_Convention_06_23
        --    )
        --    SELECT C.ConventionID, S.mCotisations, S.mTransfert_IN, S.mTotal_RIN_AvecPreuve, S.mTotal_RIN_SansPreuve,
        --           mTotal_Cotisations = mCotisations + mTransfert_IN
        --      INTO #TB_Cotisation_06_23
        --      FROM dbo.fntIQEE_CalculerMontantsDemande_PourTous(NULL, @dtDebutCotisation, @dtFinCotisation, DEFAULT) S
        --           JOIN CTE_Convention C ON C.ConventionID = S.iID_Convention

        --    SET @iCount = @@ROWCOUNT
        --    SET @ElapseTime = @QueryTimer - @QueryTimer
        --    PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    » ' + LTrim(Str(@iCount)) + ' sommes récupérées (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

        --    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Vérificiation si le retrait est moindre que les cotisations'

        --    SET @QueryTimer = GETDATE()
        --    WHILE EXISTS(SELECT TOP 1 * FROM #TB_Convention_06_23 WHERE Row_Num > @RowNo)
        --    BEGIN
        --        SELECT TOP 1 @iID_Convention = ConventionID, @mCotisationRetire = Cotisations_Retirees, @RowNo = Row_Num
        --          FROM #TB_Convention_06_23
        --         WHERE Row_Num > @RowNo
        --         ORDER BY Row_Num

        --        SELECT @mTotalCotisation = mTotal_Cotisations
        --          FROM #TB_Cotisation_06_23
        --         WHERE ConventionID = @iID_Convention

        --        IF @mCotisationRetire < @mTotalCotisation
        --        BEGIN
        --            UPDATE #TB_Convention_06_23 SET Cotisations_Retirees = 0
        --             WHERE Row_Num = @RowNo

        --            UPDATE #TB_Cotisation_06_23 SET mTotal_Cotisations = @mTotalCotisation - @mCotisationRetire
        --             WHERE ConventionID = @iID_Convention
        --        END 
        --        ELSE
        --        BEGIN
        --            UPDATE #TB_Convention_06_23 SET Cotisations_Retirees = @mCotisationRetire - @mTotalCotisation
        --             WHERE Row_Num = @RowNo

        --            UPDATE #TB_Cotisation_06_23 SET mTotal_Cotisations = 0
        --             WHERE ConventionID = @iID_Convention
        --        END 
        --    END 

        --    DELETE FROM #TB_Convention_06_23
        --     WHERE Cotisations_Retirees <= 0

        --    SELECT @iCount = @@ROWCOUNT
        --    SET @ElapseTime = @QueryTimer - @QueryTimer
        --    PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    » ' + LTrim(Str(@iCount)) + ' retraits écartés (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

        --    SELECT @iNbConvention= Count(distinct ConventionID), @iCount = COUNT(*) FROM #TB_Convention_06_23
        --    PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    » ' + LTrim(Str(@iCount)) + ' retraits restants à traitées pour ' + LTRIM(STR(@iNbConvention)) + ' conventions (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'
        --END 
    END 
    
    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Récupération des infos de bénéficiaires'
    BEGIN 
        IF OBJECT_ID('tempdb..#TB_Beneficiary_06_23') IS NOT NULL
            DROP TABLE #TB_Beneficiary_06_23

        SET @QueryTimer = GetDate()
        SELECT DISTINCT
            C.BeneficiaryID, 
            LTrim(H.LastName) as Nom, LTrim(H.FirstName) as Prenom, H.SexID as Sexe, H.BirthDate as DateNaissance,
            dbo.fn_Mo_FormatHumanName(H.FirstName, '', H.LastName, '', '', 0) as NomPrenom, 
            NAS = REPLACE(H.SocialNumber, ' ', '') --REPLACE(N.SocialNumber, ' ', '')
        INTO
            #TB_Beneficiary_06_23
        FROM 
            #TB_Convention_06_23 C
            JOIN dbo.Mo_Human H ON H.HumanID = C.BeneficiaryID
            --LEFT JOIN dbo.fntCONV_ObtenirNasParHumainEnDate(@dtFinCotisation) N ON N.HumanID = H.HumanID
        SET @ElapseTime = @QueryTimer - @QueryTimer

        SELECT @iCount = Count(distinct BeneficiaryID) FROM #TB_Beneficiary_06_23
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    » ' + LTrim(Str(@iCount)) + ' bénéficiaires correspondant (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

        IF @iCount < 5
            SET @MaxRow = @iCount

        IF @IsDebug <> 0 AND @MaxRow between 1 and 10
            select * from #TB_Beneficiary_06_23 ORDER BY BeneficiaryID
    END

    --select * from #TB_Convention_06_23 TB JOIN #TB_Beneficiary_06_23 B ON B.ConventionID = TB.ConventionID
    --                                       JOIN dbo.Un_College C ON C.CollegeID = TB.CollegeID
    --WHERE ConventionNo = 'I-20151202007'

    --------------------------------------------------------------------------------------------------------------------------------
    -- Valider les retraits lorsque le bénéficiaire est admissible au PAE et conserver les raisons de rejet en vertu des validations
    --------------------------------------------------------------------------------------------------------------------------------
    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Validation des conventions selon les critères RQ'
    BEGIN
        DECLARE 
            @iID_Validation INT,
            @iCode_Validation INT,
            @vcDescription VARCHAR(300),
            @cType CHAR(1),
            @iCountRejets INT

        -- Prépare la table temporaire pour accumuler les rejets de validation
        IF OBJECT_ID('tempdb..#TB_Rejet_06_23') IS NULL
            CREATE TABLE #TB_Rejets_06_23 (
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
            TRUNCATE TABLE #TB_Rejet_06_23

        IF OBJECT_ID('tempdb..#TB_Validation_06_23') IS NOT NULL
            DROP TABLE #TB_Validation_06_23

        SELECT 
            V.iID_Validation, V.iCode_Validation, V.cType, V.vcDescription_Parametrable as vcDescription
        INTO
            #TB_Validation_06_23
        FROM
            dbo.vwIQEE_Enregistrement_TypeEtSousType T
            JOIN dbo.tblIQEE_Validations V ON V.tiID_Type_Enregistrement = T.tiID_Type_Enregistrement AND ISNULL(V.iID_Sous_Type, 0) = ISNULL(T.iID_Sous_Type, 0)
        WHERE 
            T.cCode_Type_SousType = '06-23'
            AND V.bValidation_Speciale = 0
            AND V.bActif = 1
            AND ( @cCode_Portee = 'T'
                  OR (@cCode_Portee = 'A' AND V.cType = 'E')
                  OR (@cCode_Portee = 'I' AND V.bCorrection_Possible = 1)
                  OR (ISNULL(@cCode_Portee, '') = '' AND V.cType = 'E' AND V.bCorrection_Possible = 0)
                )
        SET @iCount = @@ROWCOUNT
        PRINT '   ' + Convert(varchar(20), GetDate(), 120) + '    » ' + LTrim(Str(@iCount)) + ' validations à appliquer'

        -- Boucler à travers les validations du sous type de transaction
        SET @iID_Validation = 0               
        WHILE Exists(SELECT TOP 1 * FROM #TB_Validation_06_23 WHERE iID_Validation > @iID_Validation) 
        BEGIN
            SET @iCountRejets = 0

            SELECT  @iID_Validation = Min(iID_Validation) 
            FROM    #TB_Validation_06_23
            WHERE   iID_Validation > @iID_Validation

            SELECT  @iCode_Validation = iCode_Validation,
                    @vcDescription = vcDescription,
                    @cType = cType
            FROM    #TB_Validation_06_23 
            WHERE   iID_Validation = @iID_Validation

            PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + ' - Validation #' + LTrim(Str(@iCode_Validation)) + ': ' + @vcDescription

            BEGIN TRY
                -- Validation #501    
                IF @iCode_Validation = 501
                BEGIN
                    INSERT INTO #TB_Rejets_06_23 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        TB.ConventionID, @iID_Validation, REPLACE(@vcDescription, '%vcNo_Convention%', TB.ConventionNo),
                        NULL, NULL, TB.ConventionID, NULL, NULL
                    FROM 
                        #TB_Convention_06_23 TB
                        JOIN tblIQEE_ImpotsSpeciaux TIS ON TIS.iID_Convention = TB.ConventionID and TIS.dtDate_Evenement = TB.dtTraitement
                        JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = TIS.iID_Fichier_IQEE
                    WHERE 0=0
                        --AND TIS.iID_Cotisation = @iID_Cotisation
                        AND TIS.iID_Sous_Type = @iID_SousTypeEnregistrement
                        AND TIS.cStatut_Reponse = 'R'
                        --AND TIS.dtDate_Evenement = @dtDate_Evenement

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation #502    
                IF @iCode_Validation = 502
                BEGIN
                    INSERT INTO #TB_Rejets_06_23 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        TB.ConventionID, @iID_Validation, REPLACE(@vcDescription, '%vcNo_Convention%', TB.ConventionNo),
                        NULL, NULL, TB.ConventionID, NULL, NULL
                    FROM 
                        #TB_Convention_06_23 TB
                        JOIN tblIQEE_ImpotsSpeciaux TIS ON TIS.iID_Convention = TB.ConventionID and TIS.dtDate_Evenement = TB.dtTraitement
                        JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = TIS.iID_Fichier_IQEE
                    WHERE 0=0
                        --AND TIS.iID_Cotisation = @iID_Cotisation
                        AND TIS.iID_Sous_Type = @iID_SousTypeEnregistrement
                        AND TIS.cStatut_Reponse = 'A'
                        AND TIS.tiCode_Version <> 1
                        --AND TIS.dtDate_Evenement = @dtDate_Evenement

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- 2013-08-01 SB: Désactivation
                -- Validation #503   
                IF @iCode_Validation = 503
                BEGIN
                    INSERT INTO #TB_Rejets_06_23 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        TB.ConventionID, @iID_Validation, REPLACE(@vcDescription, '%vcNo_Convention%', TB.ConventionNo),
                        NULL, NULL, TB.ConventionID, NULL, NULL
                    FROM 
                        #TB_Convention_06_23 TB
                        JOIN tblIQEE_ImpotsSpeciaux TIS ON TIS.iID_Convention = TB.ConventionID
                        JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = TIS.iID_Fichier_IQEE
                        JOIN dbo.tblIQEE_Erreurs E ON E.iID_Enregistrement = I.iID_Impot_Special
                        JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = E.tiID_Type_Enregistrement
                        JOIN tblIQEE_StatutsErreur SE ON SE.tiID_Statuts_Erreur = E.tiID_Statuts_Erreur
                    WHERE 0=0
                        --AND TIS.iID_Cotisation = @iID_Cotisation
                        AND TIS.iID_Sous_Type = @iID_SousTypeEnregistrement
                        AND TIS.cStatut_Reponse = 'E'
                        AND TIS.dtDate_Evenement = TB.dtTraitement
                        AND TE.cCode_Type_Enregistrement = '06'
                        AND SE.vcCode_Statut = 'ATR'

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation #504    
                IF @iCode_Validation = 504
                BEGIN
                    --; WITH CTE_
                    INSERT INTO #TB_Rejets_06_23 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        TB.ConventionID, @iID_Validation, REPLACE(@vcDescription, '%vcBeneficiaire%', B.NomPrenom),
                        NULL, NULL, TB.ConventionID, B.BeneficiaryID, NULL
                    FROM 
                        #TB_Convention_06_23 TB
                        JOIN #TB_Beneficiary_06_23 B ON B.BeneficiaryID = TB.BeneficiaryID
                    WHERE
                        dbo.FN_CRI_CheckSin(B.NAS,0) = 0

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation #505 
                IF @iCode_Validation = 505
                BEGIN
                    INSERT INTO #TB_Rejets_06_23 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        TB.ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, TB.ConventionID, B.BeneficiaryID, NULL
                    FROM 
                        #TB_Convention_06_23 TB
                        JOIN #TB_Beneficiary_06_23 B ON B.BeneficiaryID = TB.BeneficiaryID
                    WHERE
                        IsNull(B.Nom, '') = ''

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation #506    
                IF @iCode_Validation = 506
                BEGIN
                    INSERT INTO #TB_Rejets_06_23 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        TB.ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, TB.ConventionID, B.BeneficiaryID, NULL
                    FROM 
                        #TB_Convention_06_23 TB
                        JOIN #TB_Beneficiary_06_23 B ON B.BeneficiaryID = TB.BeneficiaryID
                    WHERE
                        IsNull(B.Prenom, '') = ''

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation #507    
                IF @iCode_Validation = 507
                BEGIN
                    INSERT INTO #TB_Rejets_06_23 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        TB.ConventionID, @iID_Validation, REPLACE(@vcDescription, '%vcBeneficiaire%', B.NomPrenom),
                        NULL, NULL, TB.ConventionID, B.BeneficiaryID, NULL
                    FROM 
                        #TB_Convention_06_23 TB
                        JOIN #TB_Beneficiary_06_23 B ON B.BeneficiaryID = TB.BeneficiaryID
                    WHERE
                        IsNull(B.DateNaissance, '1900-01-01') <= '1900-01-01'

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation #508    
                IF @iCode_Validation = 508
                BEGIN
                    ;WITH CTE_Rejet as (
                        SELECT
                            TB.ConventionID, B.BeneficiaryID, B.NomPrenom, 
                            CONVERT(VARCHAR(10), B.DateNaissance, 120) as dtNaissance, 
                            CONVERT(VARCHAR(10), TB.dtTraitement, 120) as dtEvenement
                        FROM
                            #TB_Convention_06_23 TB
                            JOIN #TB_Beneficiary_06_23 B ON B.BeneficiaryID = TB.BeneficiaryID
                        WHERE
                            IsNull(B.DateNaissance, '1900-01-01') > TB.dtTraitement
                    )
                    INSERT INTO #TB_Rejets_06_23 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        TB.ConventionID, @iID_Validation, REPLACE(REPLACE(@vcDescription, '%vcBeneficiaire%', TB.NomPrenom), '%dtDate_Evenement%', dtEvenement),
                        TB.dtEvenement, TB.dtNaissance, TB.ConventionID, TB.BeneficiaryID, NULL
                    FROM 
                        CTE_Rejet TB
                  
                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation #509
                IF @iCode_Validation = 509
                BEGIN
                    INSERT INTO #TB_Rejets_06_23 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        C.ConventionID, @iID_Validation, REPLACE(@vcDescription, '%vcBeneficiaire%', B.NomPrenom),
                        NULL, B.Sexe, C.ConventionID, C.BeneficiaryID, NULL
                    FROM 
                        #TB_Convention_06_23 C
                        JOIN #TB_Beneficiary_06_23 B ON B.BeneficiaryID = C.BeneficiaryID
                    WHERE
                        NOT IsNull(B.Sexe, '') IN ('F','M')

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation #510    
                IF @iCode_Validation = 510
                BEGIN
                    ;WITH CTE as (
                        SELECT
                            TB.ConventionID, TB.BeneficiaryID, B.Prenom, B.NomPrenom,
                            dbo.fnIQEE_ValiderNom(B.Prenom) as vcCaractereInvalide
                        FROM
                            #TB_Convention_06_23 TB
                        JOIN #TB_Beneficiary_06_23 B ON B.BeneficiaryID = TB.BeneficiaryID
                    )
                    INSERT INTO #TB_Rejets_06_23 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        TB.ConventionID, @iID_Validation, REPLACE(REPLACE(@vcDescription, '%vcBeneficiaire%', TB.NomPrenom),'%vcCaractereNonConforme%', TB.vcCaractereInvalide),
                        NULL, TB.Prenom, TB.ConventionID, TB.BeneficiaryID, NULL
                    FROM 
                        CTE TB
                    WHERE
                        vcCaractereInvalide IS NOT NULL

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation #511    
                IF @iCode_Validation = 511
                BEGIN
                    ;WITH CTE as (
                        SELECT
                            TB.ConventionID, TB.BeneficiaryID, B.Nom, B.NomPrenom,
                            dbo.fnIQEE_ValiderNom(B.Nom) as vcCaractereInvalide
                        FROM
                            #TB_Convention_06_23 TB
                            JOIN #TB_Beneficiary_06_23 B ON B.BeneficiaryID = TB.BeneficiaryID
                    )
                    INSERT INTO #TB_Rejets_06_23 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        TB.ConventionID, @iID_Validation, REPLACE(REPLACE(@vcDescription, '%vcBeneficiaire%', TB.NomPrenom),'%vcCaractereNonConforme%', TB.vcCaractereInvalide),
                        NULL, TB.Nom, TB.ConventionID, TB.BeneficiaryID, NULL
                    FROM 
                        CTE TB
                    WHERE
                        vcCaractereInvalide IS NOT NULL

                    SET @iCountRejets = @@ROWCOUNT
                END
                
                -- Validation #512
                -- Traiter uniquement les conventions ayant un retrait prématuré de cotisations
                IF @iCode_Validation = 512
                BEGIN
                    INSERT INTO #TB_Rejets_06_23 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        TB.ConventionID, @iID_Validation, @vcDescription,
                       NULL, NULL, TB.ConventionID, NULL, NULL
                    FROM 
                        #TB_Convention_06_23 TB
                    GROUP BY
                        TB.ConventionID, TB.ConventionNo
                    HAVING
                        Sum(Cotisations_Retirees) <= 0

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation #513    
                IF @iCode_Validation = 513
                BEGIN
                    PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '      *** Skipped ***'
                    --INSERT INTO #TB_Rejets_06_23 (
                    --    iID_Convention, iID_Validation, vcDescription,
                    --    vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    --)
                    --SELECT 
                    --    TB.ConventionID, @iID_Validation, @vcDescription,
                    --    NULL, NULL, TB.ConventionID, NULL, NULL
                    --FROM
                    --    #TB_Convention_06_23
                    --WHERE
                    --    @vcNo_Convention IN ('C-20001005008','C-20001031021','R-20060717009','R-20060717011','R-20060717008',
                    --                         'U-20051201028','R-20070627056','R-20070627058','F-20011119002','I-20050506001',
                    --                         'I-20070925002','I-20070705002','I-20031223005','D-20010730001','T-20081101067',
                    --                         'I-20071107001','C-19991018042','I-20050923003','T-20081101023','T-20081101028',
                    --                         'U-20080902012','U-20080902012','U-20081028013','U-20080923016','R-20080923006',
                    --                         'R-20080915007','R-20081105003','U-20071213003','U-20080403001','R-20080317046',
                    --                         'R-20080317047','U-20071114068','U-20080411009','R-20080411001','U-20081009005',
                    --                         'R-20080916001','U-20080827021','U-20081105042','R-20071120004','R-20071217029',
                    --                         'U-20071217012','U-20080204002','U-20080930010','T-20081101006','T-20081101017',
                    --                         '1449340',      '2083034',      '2039499',      'I-20050923002')

                    --SET @iCountRejets = @@ROWCOUNT
                END
                
                -- Validation #514
                IF @iCode_Validation = 514
                BEGIN
                    --PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '      *** Skipped ***'
                    ;WITH CTE_ImpotSpecial AS (
                        SELECT 
                            I.iID_Convention, T.cCode_Type_SousType, I.dtDate_Evenement, I.cStatut_Reponse,
                            RowNum = ROW_NUMBER() OVER(PARTITION BY I.iID_Convention, T.cCode_Type_SousType ORDER BY I.siAnnee_Fiscale DESC, I.dtDate_Evenement DESC, F.dtDate_Creation DESC, ISNULL(I.iID_Ligne_Fichier, 999999999))
                        FROM
                            dbo.tblIQEE_ImpotsSpeciaux I
                            JOIN #TB_Convention_06_23 TB ON TB.ConventionID = I.iID_Convention
                            JOIN dbo.vwIQEE_Enregistrement_TypeEtSousType T ON T.iID_Sous_Type = I.iID_Sous_Type
                            JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = I.iID_Fichier_IQEE
                        WHERE 0=0
                            AND NOT I.cStatut_Reponse IN ('E','X')
                            AND T.cCode_Type_Enregistrement = 'O6' AND T.cCode_Sous_Type IN ('91','51')
                            --AND I.dtDate_Evenement < TB.dtTraitement
                    )
                    INSERT INTO #TB_Rejets_06_23 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        TB.ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, TB.ConventionID, NULL, NULL
                    FROM
                        #TB_Convention_06_23 TB
                        JOIN CTE_ImpotSpecial I ON I.iID_Convention = TB.ConventionID
                    WHERE 0=0
                        AND I.RowNum = 1
                        AND I.cStatut_Reponse IN ('A','R')

                    SET @iCountRejets = @@ROWCOUNT
                END
                
                ---- Validation #516
                ----  TODO: Lorsque la transaction T04 sera conçue, il faudra ajouter dans la requête le code nécessaire 
                ----        pour vérifier qu'une T04 n'a pas été envoyée.
                IF @iCode_Validation = 516
                BEGIN
                    PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '      *** Skipped ***'
                    --INSERT INTO #TB_Rejets_06_23 (
                    --    iID_Convention, iID_Validation, vcDescription,
                    --    vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    --)
                    --SELECT 
                    --    TB.ConventionID, @iID_Validation, REPLACE(@vcDescription,'%iID_Convention%',@vcNo_Convention),
                    --    NULL, NULL, TB.ConventionID, NULL, NULL
                    --FROM
                    --    #TB_Convention_06_23 TB
                    --    JOIN dbo.Un_ConventionOper CO ON CO.ConventionID = TB.ConventionID
                    --    JOIN Un_Oper O ON O.OperID = CO.OperID
                    --    --LEFT JOIN dbo.tblIQEE_Transferts T ON T.iID_Operation = O.OperID
                    --WHERE 0=0
                    --    AND CO.ConventionOperTypeID IN ('CBQ', 'MMQ')
                    --    AND O.OperTypeID IN ('TRI','RIM','OUT')
                    --    AND O.OperDate <= @dtFinCotisation
                    --    --AND NOT (T.iID_Transfert IS NOT NULL AND T.cStatut_Reponse = 'R')

                    --SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation #517    
                IF @iCode_Validation = 517 AND @bit_CasSpecial = 0
                BEGIN
                    INSERT INTO #TB_Rejets_06_23 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        TB.ConventionID, @iID_Validation, REPLACE(@vcDescription, '%vcNo_Convention%', TB.ConventionNo),
                        NULL, NULL, TB.ConventionID, NULL, NULL
                    FROM 
                        #TB_Convention_06_23 TB
                        JOIN dbo.tblIQEE_CasSpeciaux CS ON CS.iID_Convention = TB.ConventionID
                    WHERE 
                        bCasRegle = 0
                        AND ISNULL(CS.iID_SousType, @iID_SousTypeEnregistrement) = @iID_SousTypeEnregistrement

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation #518    
                IF @iCode_Validation = 518
                BEGIN
                    INSERT INTO #TB_Rejets_06_23 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        C.ConventionID, @iID_Validation, REPLACE(@vcDescription, '%vcBeneficiaire%', B.NomPrenom),
                        NULL, C.CollegeCode, C.ConventionID, B.BeneficiaryID, C.CollegeID
                    FROM 
                        #TB_Convention_06_23 C
                        JOIN #TB_Beneficiary_06_23 B ON B.BeneficiaryID = C.BeneficiaryID
                    WHERE 
                        ISNULL(C.CollegeID, 0) <= 0
                        OR Len(RTrim(IsNull(C.CollegeCode, ''))) = 0

                    SET @iCountRejets = @@ROWCOUNT
                END

            END TRY
            BEGIN CATCH
                PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '      *** ERREUR_VALIDATION ***'

                INSERT INTO ##tblIQEE_RapportCreation 
                    (cSection, iSequence, vcMessage)
                SELECT
                    '3', 10, '       '+CONVERT(VARCHAR(25),GETDATE(),121)+'     '+vcDescription_Parametrable + ' ' + LTrim(Str(@iCode_Validation))
                FROM
                    dbo.tblIQEE_Validations
                WHERE 
                    iCode_Validation = 110

                RETURN -1
            END CATCH

            -- S'il y a eu des rejets de validation
            IF @iCountRejets > 0
            BEGIN
                PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '      » ' + LTrim(Str(@iCountRejets)) + ' rejets de générer'

                -- Et si on traite seulement les 1ères erreurs de chaque convention
                IF @bArretPremiereErreur = 1 AND @cType = 'E'
                BEGIN
                    -- Efface que les conventions ayant un rejet sur la validation courante
                    DELETE FROM #TB_Convention_06_23
                    WHERE EXISTS (SELECT * FROM #TB_Rejets_06_23 WHERE iID_Convention = ConventionID AND iID_Validation = @iID_Validation)
                END
            END
        END

        -- Efface tous les conventions ayant eu au moins un rejet de validation
        DELETE FROM #TB_Convention_06_23
        WHERE EXISTS (SELECT * FROM #TB_Rejets_06_23 WHERE iID_Convention = ConventionID)

        INSERT INTO dbo.tblIQEE_Rejets (
            iID_Fichier_IQEE, siAnnee_Fiscale, iID_Convention, iID_Validation, vcDescription,
            vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
            --,tCommentaires, iID_Utilisateur_Modification, dtDate_Modification
        )
        SELECT 
            @iID_Fichier_IQEE, @siAnnee_Fiscale, R.iID_Convention, R.iID_Validation, R.vcDescription,
            R.vcValeur_Reference, vcValeur_Erreur, R.iID_Lien_Vers_Erreur_1, R.iID_Lien_Vers_Erreur_2, R.iID_Lien_Vers_Erreur_3
        FROM 
            #TB_Rejets_06_23 R
    END

    ----------------------------------------------------------
    -- Traite les retraits des bénéficiaires admissible au PAE
    ----------------------------------------------------------
    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Déclaration des retraits de bénéficiaire admissible au PAE'
    BEGIN
        DECLARE 
            @iCompteur INT = 0,
            @iTotal INT = (SELECT Count(distinct ConventionID) FROM #TB_Convention_06_23)
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    » ' + LTrim(Str(@iTotal)) + ' conventions à traiter.'

        SET @iCount = 0

        ; WITH CTE_Sexe as (
            SELECT X.rowID as ID, X.strField as Code
            FROM ProAcces.fn_SplitIntoTable('F,M', ',') X
        )
        INSERT INTO dbo.tblIQEE_ImpotsSpeciaux (
            iID_Fichier_IQEE, siAnnee_Fiscale, tiCode_Version, cStatut_Reponse, iID_Convention, vcNo_Convention,
            iID_Sous_Type, --iID_Remplacement_Beneficiaire, iID_Transfert, iID_Operation, iID_Cotisation,
            iID_RI, --iID_Cheque, iID_Statut_Convention, 
                dtDate_Evenement, mCotisations_Retirees,
            --mSolde_IQEE_Base, mSolde_IQEE_Majore, 
                mIQEE_ImpotSpecial, --mRadiation, mCotisations_Donne_Droit_IQEE,
            --mJuste_Valeur_Marchande, mBEC, mSubvention_Canadienne, mSolde_IQEE, 
                iID_Beneficiaire,
            vcNAS_Beneficiaire, vcNom_Beneficiaire, vcPrenom_Beneficiaire, dtDate_Naissance_Beneficiaire, tiSexe_Beneficiaire,
            vcCode_Postal_Etablissement --, vcNom_Etablissement, iID_Ligne_Fichier, iID_Paiement_Impot_CBQ, iID_Paiement_Impot_MMQ,
            --mMontant_A, mMontant_B, mMontant_C, mMontant_AFixe, mEcart_ReelvsFixe,
            --iID_Transaction_Convention_CBQ_Renversee, iID_Transaction_Convention_MMQ_Renversee
        )
        SELECT
            @iID_Fichier_IQEE, @siAnnee_Fiscale, @tiCode_Version, 'A', C.ConventionID, C.ConventionNo,
            @iID_SousTypeEnregistrement, --iID_Remplacement_Beneficiaire, iID_Transfert, iID_Operation, iID_Cotisation,
            C.CollegeID, --iID_Cheque, iID_Statut_Convention, 
                C.dtTraitement, Round(C.Cotisations_Retirees, 2),
            --mSolde_IQEE_Base, mSolde_IQEE_Majore, 
                0.00, --mRadiation, mCotisations_Donne_Droit_IQEE,
            --mJuste_Valeur_Marchande, mBEC, mSubvention_Canadienne, mSolde_IQEE, 
                C.BeneficiaryID,
            B.NAS, Left(B.Nom, 20), Left(B.Prenom, 20), B.DateNaissance, (SELECT ID FROM CTE_Sexe WHERE Code = B.Sexe),
            E.CollegeCode --, vcNom_Etablissement, iID_Ligne_Fichier, iID_Paiement_Impot_CBQ, iID_Paiement_Impot_MMQ,
            --mMontant_A, mMontant_B, mMontant_C, mMontant_AFixe, mEcart_ReelvsFixe,
            --iID_Transaction_Convention_CBQ_Renversee, iID_Transaction_Convention_MMQ_Renversee
        FROM
            #TB_Convention_06_23 C
            JOIN #TB_Beneficiary_06_23 B ON B.BeneficiaryID = C.BeneficiaryID
            LEFT JOIN dbo.Un_College E ON E.CollegeID = C.CollegeID
        WHERE
            Row_Num Between @iCount + 1 And @iCount + @IntervalPrint

        SET @iCompteur += @@ROWCOUNT
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    » ' + LTrim(Str(@iCompteur)) + ' de ' + LTrim(Str(@iTotal)) + ' complétées.'

        SET @ElapseTime = GetDate() - @StartTimer
        PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' EXEC psIQEE_CreerTransactions06_23 completed' 
                    + ' (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'
    END

    -- Retourner 0 si le traitement est réussi
    RETURN 0
END
