/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service :   psIQEE_CreerTransactions06_41
Nom du service  :   Créer les transactions de  type 06, sous type 41 - Fermeture du contrat
But             :   Sélectionner, valider et créer les transactions de type 06 – Impôt spécial, 41 - Fermeture du contrat, 
                    dans un nouveau fichier de transactions de l’IQÉÉ.
Facette         :   IQÉÉ

Paramètres d’entrée :
        Paramètre               Description
        --------------------    -----------------------------------------------------------------
        iID_Fichier_IQEE        Identifiant du nouveau fichier de transactions dans lequel les transactions 03 doivent être créées.
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
        iID_Utilisateur         Indicateur de l'usager qui a lancé le processus
        bit_CasSpecial          Indicateur pour permettre la résolution de cas spéciaux sur des T02 dont le délai de traitement est dépassé. 

Exemple d’appel :   
        exec dbo.psIQEE_CreerTransactions06_41 10, 0, NULL, 0, 'T',0

Paramètres de sortie :
        Champ               Description
        ------------        ------------------------------------------
        iCode_Retour        = 0 : Exécution terminée normalement
                            < 0 : Erreur de traitement

Historique des modifications:
    Date        Programmeur             Description
    ----------  --------------------    --------------------------------------------------------------------------
    2015-09-22  Steeve Picard            Création du service  pour les PRA (Basé sur dbo.psIQEE_CreerTransactions06_91) 
    2015-11-05  Stéphane Barbeau        Requête curImpotSpecial_41: Ajout de DISTINCT pour éviter envoi multiple et retrait de la clause And CO.ConventionOperTypeID = 'RTN'
    2015-11-06  Stéphane Barbeau        Ajout traitement @iID_Operation                                                    
    2015-12-16  Steeve Picard            Activation de la validation #1203
    2016-01-08  Steeve Picard            Correction au niveau des validations pour tenir compte de la Convention_ID
    2016-02-02    Steeve Picard            Optimisation en remplaçant les curseurs SQL par des boucles WHILE
    2016-02-19    Steeve Picard            Retrait des 2 derniers paramètres de « fnIQEE_ConventionConnueRQ »
    2016-03-23    Pierre-Luc Simard        Ne plus vérifier la table tblIQEE_PaiementsBeneficiaires pour la validation 1216 (Temporairement le temps de développer la T05)
    2016-10-04  Steeve Picard           Changement de la validation pour rejeter les conventions avec une des opérations TRI/RIM/OUT
    2017-02-01  Steeve Picard           Optimisation en traitant par batch et non une convention à la fois
    2017-06-09  Steeve Picard           Ajout du paramètre « @tiCode_Version = 0 » pour passer la valeur « 2 » lors d'une annulation/reprise
    2017-07-10  Steeve Picard           Appel à «psIQEE_CreerOperationFinanciere_ImpotsSpeciaux» seulement s'il y a eu création d'au moins une transaction
    2017-07-11  Steeve Picard           Élimination du paramètre « iID_Convention » pour toujours utiliser la table « #TB_ListeConvention »
    2018-01-04  Steeve Picard           Validation de base si @cCode_Portee = '' pour l'estimation du rapport à recevoir
    2018-02-08  Steeve Picard           Déplacement de «siAnnee_Fiscale» de la table «tblIQEE_Fichiers» vers les tables d'évèments «tblIQEE_ImpotsSpeciaux»
    2018-02-26  Steeve Picard           Empêcher que la «dtFinCotisation» soit plus grande que la dernière fin de mois
    2018-06-06  Steeve Picard           Modificiation de la gestion des retours d'erreur par RQ
    2018-09-19  Steeve Picard           Ajout du champ «iID_SousType» à la table «tblIQEE_CasSpeciaux» pour pouvoir filtrer
    2018-09-20  Steeve Picard           Ajout de la vérification que l'opération «AVC» ait été déclarée préalablement au même titre que les «PAE»
    2018-11-27  Steeve Picard           Ne bloquer la déclaration que si elle a de l'IQÉÉ dans le PAE antérieur et ignorer les opérations «AVC» en fait de compte
    2018-12-06  Steeve Picard           Utilisation des nouvelles fonctions «fntIQEE_Transfert_NonDeclare & fntIQEE_PaiementBeneficiaire_NonDeclare»
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_CreerTransactions06_41]
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
    PRINT 'Déclaration des paiement de revenus accumulés au contrat ou d’un dossier bénéficiaire (T06-41) pour ' + STR(@siAnnee_Fiscale, 4)
    PRINT '--------------------------------------------------------------------------------------------------------'
    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' EXEC psIQEE_CreerTransactions06_41 started'

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
        AND cCode_Sous_Type = '41'

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

    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Identifie les conventions devant déclarer une T06-41'
    BEGIN
        ------------------------------------------------------------------------------------------------------------
        -- Identifier et sélectionner les conventions ayant eu un PRA au contrat ou d’un dossier bénéficiaire
        ------------------------------------------------------------------------------------------------------------
        IF OBJECT_ID('tempdb..#TB_Convention_06_41') IS NOT NULL
            DROP TABLE #TB_Convention_06_41

        PRINT '   ' + Convert(varchar(20), GetDate(), 120) + '   - Récupère les conventions ayant eu un «PRA» au contrat'
        SET @QueryTimer = GetDate()
    
        SET ROWCOUNT @MaxRow

        ;WITH CTE_Convention_PRA as (
            SELECT DISTINCT
                C.ConventionID, C.ConventionNo, O.OperID, O.OperDate
            FROM 
                #TB_ListeConvention C
                JOIN dbo.Un_ConventionOper CO ON CO.ConventionID = C.ConventionID --And CO.ConventionOperTypeID = 'RTN' 
                JOIN dbo.Un_Oper O ON O.OperID = CO.OperID AND O.OperTypeID = 'PRA' 
            WHERE 
                O.OperDate Between @dtDebutCotisation And @dtFinCotisation
                AND C.dtReconnue_RQ IS NOT NULL
        ),
        CTE_Convention as (
            SELECT 
                C.Conventionid, C.ConventionNo, C.OperID, C.OperDate,
                StatutID = CS.ConventionConventionStateID, 
                StatutDate = CS.StartDate                
            FROM 
                CTE_Convention_PRA C
                JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(@dtFinCotisation, NULL) CS ON CS.ConventionID = C.ConventionID
        )
        SELECT
            C.Conventionid, C.ConventionNo, C.OperID, C.OperDate, C.StatutID, C.StatutDate,
            Solde_CreditBase = IsNull(S.Credit_Base, 0), 
            Solde_Majoration = IsNull(S.Majoration, 0), 
            Solde_Interet = IsNull(S.Interet, 0)
        INTO #TB_Convention_06_41
        FROM
            CTE_Convention C
            LEFT JOIN dbo.fntIQEE_CalculerSoldeIQEE_ParConvention(NULL, @dtFinCotisation, 0) S ON S.ConventionID = C.ConventionID
            LEFT JOIN (
                SELECT * FROM dbo.tblIQEE_ImpotsSpeciaux I
                WHERE iID_Sous_Type= @iID_SousTypeEnregistrement
                        AND tiCode_Version IN (0, 2) 
                        AND cStatut_Reponse = 'R'
            ) DIS ON DIS.iID_Convention = C.ConventionID
        WHERE
            DIS.iID_Impot_Special IS NULL

        SET @iCount = @@ROWCOUNT
        SET @ElapseTime = GetDate() - @QueryTimer

        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    » ' + LTrim(Str(@iCount)) + ' retrouvées (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'
--        SELECT *, @dtFinCotisation FROM #TB_Convention_06_41 

        SET ROWCOUNT 0

        IF NOT EXISTS(SELECT TOP 1 * FROM #TB_Convention_06_41)
           RETURN

        IF @iCount < 5
            SET @MaxRow = @iCount

        IF Object_ID('tempDB..#TB_Beneficiary_06_41') IS NOT NULL
            DROP TABLE #TB_Beneficiary_06_41

        PRINT '   ' + Convert(varchar(20), GetDate(), 120) + '   - Récupération les infos des bénéficiaire'
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
                #TB_Convention_06_41 TB
                JOIN dbo.fntCONV_ObtenirBeneficiaireParConventionEnDate(@dtFinCotisation, DEFAULT) CB ON CB.iID_Convention = TB.ConventionID
        )
        SELECT 
            TB.*,
            vcNomPrenom = dbo.fn_Mo_FormatHumanName(TB.vcNom, '', TB.vcPrenom, '', '', 0)
        INTO
            #TB_Beneficiary_06_41
        FROM 
            CTE_Beneficiary TB
            JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = TB.iID_Beneficiary
        SET @iCount = @@ROWCOUNT
        SET @ElapseTime = GetDate() - @QueryTimer
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » ' + LTrim(Str(@iCount)) + ' retrouvées (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

        IF @IsDebug <> 0 AND @MaxRow between 1 and 10
            select * 
            from #TB_Convention_06_41 TB JOIN #TB_Beneficiary_06_41 B ON B.iID_Convention = TB.ConventionID
            ORDER BY TB.ConventionNo
    END

    --------------------------------------------------------------------------------------------------
    -- Valider les «PRA» des convention et conserver les raisons de rejet en vertu des validations
    --------------------------------------------------------------------------------------------------
    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Validation des conventions selon les critères RQ'
    BEGIN
        DECLARE
            @iID_Validation INT,                            @iCode_Validation INT, 
            @vcDescription VARCHAR(300),                    @cType CHAR(1), 
            @iCountRejets INT

        IF OBJECT_ID('tempdb..#TB_Rejet_06_01') IS NULL
            CREATE TABLE #TB_Rejets_06_41 (
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
        IF OBJECT_ID('tempdb..#TB_Validation_06_41') IS NOT NULL
            DROP TABLE #TB_Validation_06_41

        SELECT 
            V.iOrdre_Presentation, V.iID_Validation, V.iCode_Validation, V.cType, V.vcDescription_Parametrable as vcDescription
        INTO
            #TB_Validation_06_41
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
        WHILE Exists(SELECT TOP 1 * FROM #TB_Validation_06_41 WHERE iOrdre_Presentation > @iOrdre_Presentation) 
        BEGIN
            SET @iCountRejets = 0

            SELECT TOP 1
                @iOrdre_Presentation = iOrdre_Presentation,
                @iID_Validation = iID_Validation, 
                @iCode_Validation = iCode_Validation,
                @vcDescription = vcDescription,
                @cType = cType
            FROM
                #TB_Validation_06_41 
            WHERE
                iOrdre_Presentation > @iOrdre_Presentation
            ORDER BY 
                iOrdre_Presentation

            PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '   - Validation #' + LTrim(Str(@iCode_Validation)) + ': ' + @vcDescription

            BEGIN TRY
                -- Validation : L'impôt spécial de «PRA» de convention a déjà été envoyé et une réponse reçue de RQ
                IF @iCode_Validation = 1201 
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.StatutID
                        FROM
                            #TB_Convention_06_41 C
                        WHERE
                            Exists (
                                SELECT * FROM dbo.tblIQEE_ImpotsSpeciaux I
                                              JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = I.iID_Fichier_IQEE 
                                WHERE 
                                    I.iID_Convention = C.ConventionID
                                    AND I.iID_Statut_Convention = C.StatutID
                                    AND I.iID_Sous_Type = @iID_SousTypeEnregistrement
                                    AND I.cStatut_Reponse = 'R'
                            )
                    )
                    INSERT INTO #TB_Rejets_06_41 (
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

                -- Validation : L'impôt spécial de «PRA» de convention est en cours de traitement par RQ et est en attente d’une réponse de Revenu Québec
                IF @iCode_Validation = 1202 
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.StatutID
                        FROM
                            #TB_Convention_06_41 C
                        WHERE
                            Exists (
                                SELECT * FROM dbo.tblIQEE_ImpotsSpeciaux I
                                              JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = I.iID_Fichier_IQEE 
                                WHERE 
                                    I.iID_Convention = C.ConventionID
                                    AND I.iID_Statut_Convention = C.StatutID
                                    AND I.iID_Sous_Type = @iID_SousTypeEnregistrement
                                    AND I.cStatut_Reponse = 'A'
                                    AND I.tiCode_Version <> 1
                            )
                    )
                    INSERT INTO #TB_Rejets_06_41 (
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

                -- Validation : Une erreur soulevée par Revenu Québec est en cours de traitement pour l'impôt spécial de paiement de revenus accumulés (PRA)
                IF @iCode_Validation = 1203 
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.StatutID
                        FROM
                            #TB_Convention_06_41 C
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
                    INSERT INTO #TB_Rejets_06_41 (
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

                -- Validation : Le NAS du bénéficiaire relié au «PRA» de convention est absent ou invalide
                IF @iCode_Validation = 1204 
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.StatutID, B.iID_Beneficiary, B.vcNomPrenom, B.vcNAS
                        FROM
                            #TB_Convention_06_41 C
                            JOIN #TB_Beneficiary_06_41 B ON B.iID_Convention = C.ConventionID
                        WHERE
                            dbo.FN_CRI_CheckSin(B.vcNAS, 0) = 0
                    )
                    INSERT INTO #TB_Rejets_06_41 (
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

                -- Validation : Le nom du bénéficiaire relié au «PRA» de convention est absent
                IF @iCode_Validation = 1205 
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.StatutID, B.iID_Beneficiary, B.vcNomPrenom, B.vcNom
                        FROM
                            #TB_Convention_06_41 C
                            JOIN #TB_Beneficiary_06_41 B ON B.iID_Convention = C.ConventionID
                        WHERE
                            Len(IsNull(B.vcNom, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_06_41 (
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

                -- Validation : Le prénom du bénéficiaire relié au «PRA» de convention est absent
                IF @iCode_Validation = 1206
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.StatutID, B.iID_Beneficiary, B.vcNomPrenom, B.vcPrenom
                        FROM
                            #TB_Convention_06_41 C
                            JOIN #TB_Beneficiary_06_41 B ON B.iID_Convention = C.ConventionID
                        WHERE
                            Len(IsNull(B.vcPrenom, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_06_41 (
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

                -- Validation : La date de naissance du bénéficiaire reliée au «PRA» de convention est absente
                IF @iCode_Validation = 1207
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.StatutID, B.iID_Beneficiary, B.vcNomPrenom, B.dtNaissance
                        FROM
                            #TB_Convention_06_41 C
                            JOIN #TB_Beneficiary_06_41 B ON B.iID_Convention = C.ConventionID
                        WHERE
                            B.dtNaissance IS NULL
                    )
                    INSERT INTO #TB_Rejets_06_41 (
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

                -- Validation : La date de naissance du bénéficiaire reliée au «PRA» de convention est invalide
                IF @iCode_Validation = 1208
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.StatutID, C.StatutDate, B.iID_Beneficiary, B.vcNomPrenom, B.dtNaissance
                        FROM
                            #TB_Convention_06_41 C
                            JOIN #TB_Beneficiary_06_41 B ON B.iID_Convention = C.ConventionID
                        WHERE
                            B.dtNaissance > C.StatutDate
                    )
                    INSERT INTO #TB_Rejets_06_41 (
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

                -- Validation : Le sexe du bénéficiaire relié au «PRA» de convention n’est pas défini
                IF @iCode_Validation = 1209
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.StatutID, C.StatutDate, B.iID_Beneficiary, B.vcNomPrenom, B.cSexe
                        FROM
                            #TB_Convention_06_41 C
                            JOIN #TB_Beneficiary_06_41 B ON B.iID_Convention = C.ConventionID
                        WHERE
                            NOT IsNull(B.cSexe, '') IN ('M', 'F')
                    )
                    INSERT INTO #TB_Rejets_06_41 (
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

                -- Validation : Le prénom du bénéficiaire relié au «PRA» de convention contient au moins 1 caractère non conforme
                IF @iCode_Validation = 1210
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.StatutID, C.StatutDate, B.iID_Beneficiary, B.vcNomPrenom, B.vcPrenom, 
                            CaractereNonConforme = dbo.fnIQEE_ValiderNom(B.vcPrenom)
                        FROM
                            #TB_Convention_06_41 C
                            JOIN #TB_Beneficiary_06_41 B ON B.iID_Convention = C.ConventionID
                        WHERE
                            Len(vcPrenom) > 0
                    )
                    INSERT INTO #TB_Rejets_06_41 (
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

                -- Validation : Le nom du bénéficiaire relié au «PRA» de convention contient au moins 1 caractère non conforme
                IF @iCode_Validation = 1211
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.StatutID, C.StatutDate, B.iID_Beneficiary, B.vcNomPrenom, B.vcNom, 
                            CaractereNonConforme = dbo.fnIQEE_ValiderNom(B.vcNom)
                        FROM
                            #TB_Convention_06_41 C
                            JOIN #TB_Beneficiary_06_41 B ON B.iID_Convention = C.ConventionID
                        WHERE
                            Len(B.vcNom) > 0
                    )
                    INSERT INTO #TB_Rejets_06_41 (
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

                -- Validation : La convention a été fermée par une transaction d'impôt spécial 51
                IF @iCode_Validation = 1212
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT DISTINCT
                            C.ConventionID, C.StatutID
                        FROM
                            #TB_Convention_06_41 C
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
                    INSERT INTO #TB_Rejets_06_41 (
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

                -- Validation : L'impôt spécial est < 0
                IF @iCode_Validation = 1213
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT DISTINCT
                            C.ConventionID, C.ConventionNo, C.StatutID
                        FROM
                            #TB_Convention_06_41 C
                        WHERE
                            Solde_CreditBase + Solde_Majoration < 0
                    )
                    INSERT INTO #TB_Rejets_06_41 (
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

                -- Validation : La convention a des cas spéciaux non résolus avec Revenu Québec en cours
                IF @iCode_Validation = 1214
                BEGIN
                    IF @bit_CasSpecial = 0
                        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » Skipped - Ce sont des cas spéciaux'
                    ELSE
                    BEGIN
                        ; WITH CTE_Convention as (
                            SELECT DISTINCT
                                C.ConventionID, C.ConventionNo, C.StatutID
                            FROM
                                #TB_Convention_06_41 C
                                JOIN dbo.tblIQEE_CasSpeciaux CS ON CS.iID_Convention = C.ConventionID
                            WHERE
                                CS.bCasRegle = 0
                                AND ISNULL(CS.tiID_TypeEnregistrement, @tiID_TypeEnregistrement) = @tiID_TypeEnregistrement
                                AND ISNULL(CS.iID_SousType, @iID_SousTypeEnregistrement) = @iID_SousTypeEnregistrement
                        )
                        INSERT INTO #TB_Rejets_06_41 (
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

                -- Validation : Le transfert doit être déclaré à RQ avant que la convention puisse être fermée
                IF @iCode_Validation = 1215
                BEGIN
                    INSERT INTO #TB_Rejets_06_41 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT
                        TB.ConventionID, @iID_Validation, REPLACE(REPLACE(@vcDescription, '%dtTransfert%', CONVERT(VARCHAR(10), T.OperDate, 120)), '%OperTypeID%', T.OperTypeID), 
                        NULL, NULL, NULL, NULL, NULL
                    FROM
                        dbo.fntIQEE_Transfert_NonDeclare(DEFAULT, @dtFinCotisation) T
                        JOIN #TB_Convention_06_41 TB ON TB.ConventionID = T.ConventionID
                    WHERE
                        T.OperDate < TB.OperDate

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Les PAEs de la convention doivent être déclarés à RQ avant que la convention puisse être fermée
                IF @iCode_Validation = 1216
                BEGIN
                    INSERT INTO #TB_Rejets_06_41 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        TB.ConventionID, @iID_Validation, REPLACE(REPLACE(@vcDescription, '%dtPaiement%', CONVERT(VARCHAR(10), PB.OperDate, 120)), '%ScholarshipNo%', TB.ConventionNo),
                        NULL, NULL, NULL, NULL, NULL
                    FROM
                        dbo.fntIQEE_PaiementBeneficiaire_NonDeclare(DEFAULT, @dtFinCotisation) PB
                        JOIN #TB_Convention_06_41 TB ON TB.ConventionID = PB.ConventionID
                    WHERE
                        PB.OperDate < TB.OperDate

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
                    iCode_Validation = 1200

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
                    DELETE FROM #TB_Convention_06_41
                    WHERE EXISTS (SELECT * FROM #TB_Rejets_06_41 WHERE iID_Convention = ConventionID AND iID_Validation = @iID_Validation)
                END
            END
        END -- IF @iCode_Validation 

        -- Efface tous les conventions ayant eu au moins un rejet de validation
        DELETE FROM #TB_Convention_06_41
        WHERE EXISTS (SELECT * FROM #TB_Rejets_06_41 R JOIN dbo.tblIQEE_Validations V ON V.iID_Validation = R.iID_Validation WHERE V.cType = 'E' And iID_Convention = ConventionID)

        INSERT INTO dbo.tblIQEE_Rejets (
            iID_Fichier_IQEE, siAnnee_Fiscale, iID_Convention, iID_Validation, vcDescription,
            vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
            --,tCommentaires, iID_Utilisateur_Modification, dtDate_Modification
        )
        SELECT 
            @iID_Fichier_IQEE, @siAnnee_Fiscale, R.iID_Convention, R.iID_Validation, R.vcDescription,
            R.vcValeur_Reference, vcValeur_Erreur, R.iID_Lien_Vers_Erreur_1, R.iID_Lien_Vers_Erreur_2, R.iID_Lien_Vers_Erreur_3
        FROM 
            #TB_Rejets_06_41 R
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
            iID_Sous_Type, iID_Statut_Convention, dtDate_Evenement, iID_Operation, 
            mSolde_IQEE_Base, mSolde_IQEE_Majore, mIQEE_ImpotSpecial, mRadiation,
            iID_Beneficiaire, vcNAS_Beneficiaire, vcNom_Beneficiaire, vcPrenom_Beneficiaire, dtDate_Naissance_Beneficiaire, tiSexe_Beneficiaire,
            mMontant_AFixe, mEcart_ReelvsFixe
        )
        SELECT
            @iID_Fichier_IQEE, @siAnnee_Fiscale, @tiCode_Version, 'A', C.ConventionID, Left(C.ConventionNo, 15),
            @iID_SousTypeEnregistrement, C.StatutID, C.OperDate, C.OperID,
            C.Solde_CreditBase, C.Solde_Majoration , C.Solde_CreditBase + c.Solde_Majoration, 0,
            B.iID_Beneficiary, B.vcNAS, Left(B.vcNom, 20), Left(B.vcPrenom, 20), B.dtNaissance, (SELECT ID FROM CTE_Sexe WHERE Code = B.cSexe),
            NULL, NULL
        FROM
            #TB_Convention_06_41 C
            JOIN #TB_Beneficiary_06_41 B ON B.iID_Convention = C.ConventionID

        SET @iCount = @@RowCount
        SET @ElapseTime = @QueryTimer - GetDate()
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    » ' + LTrim(Str(@iCount)) + ' enregistrements ajoutés (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

        IF @iCount > 0
            IF EXISTS(SELECT * FROM dbo.tblIQEE_Fichiers WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE AND bInd_Simulation = 0)
                EXEC dbo.psIQEE_CreerOperationFinanciere_ImpotsSpeciaux @iID_Utilisateur_Creation, @iID_Fichier_IQEE, @iID_SousTypeEnregistrement
    END

    SET @ElapseTime = GetDate() - @StartTimer
    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' EXEC psIQEE_CreerTransactions06_41 completed' 
                + ' (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

    IF OBJECT_ID('tempdb..#TB_Validation_06_41') IS NOT NULL
        DROP TABLE #TB_Validation_06_41
    IF OBJECT_ID('tempdb..#TB_Rejets_06_41') IS NOT NULL
        DROP TABLE #TB_Rejets_06_41
    IF OBJECT_ID('tempdb..#TB_Beneficiary_06_41') IS NOT NULL
        DROP TABLE #TB_Beneficiary_06_41
    IF OBJECT_ID('tempdb..#TB_Convention_06_41') IS NOT NULL
        DROP TABLE #TB_Convention_06_41

    -- Retourner 0 si le traitement est réussi
    RETURN 0
END
