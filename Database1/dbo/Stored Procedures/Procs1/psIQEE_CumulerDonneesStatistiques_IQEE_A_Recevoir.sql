/****************************************************************************************************
Copyrights (c) 2014 Gestion Universitas inc
Code du service        :    But                 :    Cumuler les données statistiques suivantes dans les tables tblIQEE_Estimer_ARecevoir et tblIQEE_Estimer_APayer.
                            = Demandes de subventions T02 en attente des 3 dernières années.
                            = Rejets traitables des demandes de subventions T02 des 3 dernières années.
                            = Demandes spéculatives des demandes de subventions T02 à venir estimées selon les cotisations versées pour l'année fiscale en cours dans les conventions.
                            = Déclarations des impôts spéciaux T06 en attente depuis le début du programme de l'IQEE.
                            = Rejets traitables des impôts spéciaux T06 depuis le début du programme de l'IQEE.
                            = Déclarations spéculatives des impôts spéciaux T06 à venir selon les événements de l'année fiscale en cours.                             
                            
Valeurs de retour   :    Aucune
Facette                :   IQÉÉ

Paramètres d’entrée    :    Aucun

Exemple d’appel        :    EXECUTE dbo.psIQEE_CumulerDonneesStatistiques_IQEE_A_Recevoir NULL, NULL, NULL, 290556

Paramètres de sortie:    Aucun

Historique des modifications:
    Date        Programmeur             Description                                
    ----------  --------------------    -----------------------------------------
    2014-09-02  Stéphane Barbeau        Création du service.                            
    2014-10-10  Stéphane Barbeau        T06-91: Exclure les impôts spéciaux dont le solde de la convention est négatif 
                                        (Cause: conflit entre le TRI et retrait prématuré de cotisations (T06-22))
    2014-10-14  Stéphane Barbeau        Requêtes @mCBQ_Estime_curseur et @mMMQ_Estime_curseur avec tblIQEE_ReponsesDemande: utilisation de SUM() pour gérer correctement les cas de IsNull.
    2015-01-08  Stéphane Barbeau        Traitement INSERT des variables dtDate_Fin_ARecevoir et dtDate_Enregistrement.
    2015-01-09  Stéphane Barbeau        T06-22 spéculatif: correction du mauvais iId_Sous_Type utilisé.
    2015-03-30  Stéphane Barbeau        Résolution problèmes de syntaxe INSERT T06-1
    2015-10-05  Stéphane Barbeau        Ajustement déclarations taille de variables pour éviter erreur de tronquage.
    2016-02-25  Steeve Picard           Correction de convention exclus lorsque le type de responsable du bénéficiaire était NULL
    2016-03-07  Steeve Picard           Correction de convention exclus lorsque la province du bénéficiaire n'est pas Qc mais est « ResidenceFaitQuebec »
    2016-04-05  Steeve Picard           Reformattage pour uniformiser l'indentation du code
    2016-05-04  Steeve Picard           Renommage de la fonction «fnIQEE_ObtenirDateEnregistrementRQ» qui était auparavant «fnIQEE_ObtenirDateEnregistrementRQ»
    2016-06-09  Steeve Picard           Modification au niveau des paramètres de la fonction «dbo.fntIQEE_CalculerMontantsDemande»
    2016-10-11  Steeve Picard           Correction pour v/rifier la province avec le code ou le nom
    2016-11-25  Steeve Picard           Changement d'orientation de la valeur de retour de «fnIQEE_RemplacementBeneficiaireReconnu»
    2016-04-11  Steeve Picard           Optimisation et ajout du paramètre optionel «@BeneficiaryID»
    2017-09-05  Steeve Picard           Ajout des champs «ConventionStateID & bReconnuRQ» à la table «#TB_ListeConventions»
    2017-09-25  Steeve Picard           Ajout des déclarations T06-02 & T06-31
    2017-11-09  Steeve Picard           Ajout du paramètre «siAnnee_Fiscale» à la fonction «fntIQEE_ConventionConnueRQ_PourTous»
    2017-11-15  Steeve Picard           La T06-02 ne s'applique qu'au contrat familiale mais qu'on a pas chez Universitas
    2017-12-05  Steeve Picard           Élimination du paramètre «dtReference» de la fonction «fntIQEE_ConventionConnueRQ_PourTous»
    2017-12-14  Steeve Picard           Correction pour le pourcentage de majoration quand il y a eu un changement de bénéficiaire
    2018-01-03  Steeve Picard           Correction pour les soldes restants après fermeture
    2018-01-10  Steeve Picard           Remplacement du paramètre «@NbAnnees» par «@AnneeDebut & @AnneeFin»
    2018-01-15  Steeve Picard           Correction des partages entre les conventions d'un même bénéficiaire
    2018-02-08  Steeve Picard           Déplacement de «siAnnee_Fiscale» de la table «tblIQEE_Fichiers» vers les tables d'évèments
    2018-02-22  Steeve Picard           Élimination des paramètres «@dtDebutCotisation & @dtFinCotisation» de la procédure «psIQEE_CreerTransactions02»
    2018-04-04  Steeve Picard           Remplacement de la fonction «fnCONV_ObtenirStatutConventionEnDate_PourTous» par «fntCONV_ObtenirStatutConventionEnDate_PourTous»
    2018-06-06  Steeve Picard           Modificiation de la gestion des retours d'erreur par RQ
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_CumulerDonneesStatistiques_IQEE_A_Recevoir] (
    @dtDateDuJour date = NULL,
    @AnneeDebut INT = NULL,
    @AnneeFin INT = NULL, 
    @BeneficiaryID INT = NULL
) AS 
BEGIN
    SET NoCount ON
    
--    exec DBO.SetUserContext 'IQEE'

    DECLARE @NbConvention INT = 0,
            @ZeroMoney MONEY = 0

    IF @dtDateDuJour IS NULL
       SET @dtDateDuJour  = GetDate()

    DECLARE @AnneeDebut_IQEE SMALLINT = 2007

    -- Trouver le dernier jour du mois précédent
    DECLARE @dtDate_Fin_ARecevoir DATE = DateAdd(day, -Day(@dtDateDuJour), @dtDateDuJour)
    IF YEAR(@dtDate_Fin_ARecevoir) > YEAR(GETDATE())
        SET @dtDate_Fin_ARecevoir = STR(YEAR(GETDATE())) + '-12-31'
    PRINT 'Date_Fin_ARecevoir :' + convert(varchar, @dtDate_Fin_ARecevoir, 120)

    IF ISNULL(@AnneeDebut, 0) < @AnneeDebut_IQEE
        SET @AnneeDebut = @AnneeDebut_IQEE

    IF ISNULL(@AnneeFin, 9999) >= YEAR(@dtDate_Fin_ARecevoir)
        SET @AnneeFin = YEAR(@dtDate_Fin_ARecevoir)

    PRINT 'Année entre ' + Str(@AnneeDebut, 4) + ' et ' + Str(@AnneeFin, 4)

    DECLARE @siAnnee_Fiscale_Min SMALLINT = YEAR(@dtDate_Fin_ARecevoir) - 3
    IF @siAnnee_Fiscale_Min < @AnneeDebut
        SET @siAnnee_Fiscale_Min = @AnneeDebut

    PRINT 'Année fiscale minimale des demandes : ' + Str(@siAnnee_Fiscale_Min, 4)

    PRINT ''
    IF @BeneficiaryID IS NOT NULL
    BEGIN
        DECLARE @vcNomPrenom varchar(15) = (SELECT LastName + ', ' + FirstName From Mo_Human WHERE HumanID = @BeneficiaryID)
        PRINT 'Génère les conventions du bénéficiaire : ' + @vcNomPrenom + ' (' + LTrim(Str(@BeneficiaryID)) + ')'
        DELETE FROM tblIQEE_Estimer_ARecevoir WHERE iID_Beneficiaire = @BeneficiaryID AND siAnnee_Fiscale BETWEEN @AnneeDebut AND @AnneeFin
        DELETE FROM tblIQEE_Estimer_APayer WHERE iID_Beneficiaire = @BeneficiaryID AND siAnnee_Fiscale BETWEEN @AnneeDebut AND @AnneeFin
    END
    ELSE
    BEGIN
        PRINT 'Génère toutes les conventions'
        DELETE FROM tblIQEE_Estimer_ARecevoir WHERE siAnnee_Fiscale BETWEEN @AnneeDebut AND @AnneeFin
        DELETE FROM tblIQEE_Estimer_APayer WHERE siAnnee_Fiscale BETWEEN @AnneeDebut AND @AnneeFin

        --TRUNCATE table tblIQEE_Estimer_ARecevoir
        --TRUNCATE table tblIQEE_Estimer_APayer
    END
    DELETE FROM dbo.tblIQEE_Estimer_ARecevoir WHERE dtFin_ARecevoir <> @dtDate_Fin_ARecevoir OR siAnnee_Fiscale > YEAR(@dtDate_Fin_ARecevoir)
    DELETE FROM dbo.tblIQEE_Estimer_APayer WHERE dtFin_APayer <> @dtDate_Fin_ARecevoir OR siAnnee_Fiscale > YEAR(@dtDate_Fin_ARecevoir)
    PRINT '--------------------------------------------'

    DECLARE @tiID_Type_Fichier      tinyint = (SELECT tiID_Type_Fichier FROM dbo.tblIQEE_TypesFichier WHERE vcCode_Type_Fichier = 'DEM'),
            @tiID_Statut_Fichier    tinyint = (SELECT tiID_Statut_Fichier FROM dbo.tblIQEE_StatutsFichier WHERE vcCode_Statut = 'CRE')

    DECLARE @siAnnee_Fiscale        smallint,
            @iID_Parametres_IQEE    int,
            @iID_Fichier_IQEE       INT,
            @iID_Createur           INT = 3,
            @tiID_Type_Enregistrement        tinyint,
            @tiID_SousType_Enreg    tinyint,
            @StartTime              datetime,
            @ElapsedTime            datetime,
            @nCount                 int

    DECLARE @TB_Fichiers TABLE (FichierID int, AnneeFiscale smallint, DateCreation datetime)

    PRINT ''
    PRINT 'Récupère les fichiers générés à ce jour'
    PRINT '---------------------------------------'
    BEGIN 
        SET @StartTime = GetDate()
        INSERT INTO @TB_Fichiers (FichierID, AnneeFiscale, DateCreation)
        --OUTPUT inserted.*
        SELECT F.iID_Fichier_IQEE, F.siAnnee_Fiscale, F.dtDate_Creation --, bFichier_Test, bInd_Simulation, dtDate_Creation
          FROM dbo.fntIQEE_RechercherFichiers(NULL, @AnneeDebut, @AnneeFin, NULL, NULL, NULL, 0, NULL, 0, NULL, NULL, NULL, NULL) F
         WHERE siAnnee_Fiscale Between @AnneeDebut And @AnneeFin
           AND F.bTeleversable_RQ <> 0
        SET @nCount = @@ROWCOUNT
        SET @ElapsedTime = GetDate() - @StartTime
        PRINT '   Nb insert : ' + LTrim(Str(@nCount)) + ' - Time elapsed: ' + Convert(varchar(12), @ElapsedTime, 114)

        IF Object_ID('tempDB..#TB_ListeConvention') IS NOT NULL
           DROP TABLE #TB_ListeConvention
        CREATE TABLE #TB_ListeConvention (
            RowNo INT Identity(1,1), 
            ConventionID int, 
            ConventionNo varchar(20), 
            ConventionStateID varchar(5), 
            StartDate DATE,
            dtReconnue_RQ DATE,
            CONSTRAINT PK_TB_ListeConvention_ID PRIMARY KEY (ConventionID)
        )
    END

    PRINT ''

    SET @siAnnee_Fiscale = @AnneeDebut
    WHILE (@siAnnee_Fiscale <= @AnneeFin)
    BEGIN
        PRINT ''
        PRINT '==================================='
        PRINT 'Traitement de l''année fiscale ' + Str(@siAnnee_Fiscale, 4)
        PRINT '==================================='
        DECLARE @dtFinCotisation date     = Str(@siAnnee_Fiscale,4) + '-12-31',
                @dtDebutCotisation date   = Str(@siAnnee_Fiscale,4) + '-01-01',
                @dtNaissanceMin DATE = Str(@siAnnee_Fiscale - 18) + '-12-31'

        IF @dtFinCotisation > @dtDate_Fin_ARecevoir
            SET @dtFinCotisation = @dtDate_Fin_ARecevoir
        PRINT ''
        PRINT '   Période du ' + Convert(varchar(10), @dtDebutCotisation, 120) + ' au ' + Convert(varchar(10), @dtFinCotisation, 120) 
        PRINT '   Start time at ' + Convert(varchar(20), GetDate(), 121)

        IF @BeneficiaryID IS NOT NULL
        BEGIN
            SELECT @siAnnee_Fiscale
        END

        PRINT ''
        PRINT 'Récupère les conventions et leur bénéficiaire à cette période'
        PRINT '-------------------------------------------------------------'
        BEGIN
            IF Object_ID('tempDB..#TB_ConventionBeneficiary') IS NOT NULL
               DROP TABLE #TB_ConventionBeneficiary

            SET @StartTime = GetDate()
                                                                              
            SELECT ConventionID, ConventionNo, BeneficiaryID, dtDateDebut 
              INTO #TB_ConventionBeneficiary
              FROM dbo.fntCONV_ObtenirConventionParBeneficiaireEnDate(@dtFinCotisation, @BeneficiaryID)

            SET @nCount = @@ROWCOUNT
            SET @ElapsedTime = GetDate() - @StartTime
            PRINT '   Nb insert : ' + LTrim(Str(@nCount)) + ' - Time elapsed: ' + Convert(varchar(12), @ElapsedTime, 114)

            PRINT ''
            PRINT '   Filtre les conventions actives'

            TRUNCATE TABLE #TB_ListeConvention

            SET @StartTime = GetDate()
            ;WITH CTE_Convention as (
                SELECT DISTINCT C.ConventionID, C.ConventionNo, S.ConventionStateID, S.StartDate
                  FROM dbo.Un_Convention C
                       JOIN #TB_ConventionBeneficiary B ON B.ConventionID = C.ConventionID
                       LEFT JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(Str(@siAnnee_Fiscale, 4)+'-12-31', DEFAULT) S ON S.conventionID = C.ConventionID
                 WHERE S.ConventionStateID = 'REE'
                    OR (S.ConventionStateID = 'FRM' AND YEAR(S.StartDate) = @siAnnee_Fiscale)
                    OR YEAR(C.dtEntreeEnVigueur) = @siAnnee_Fiscale
                    --OR (S.ConventionStateID IN ('PRP', 'TRA') AND YEAR(C.dtEntreeEnVigueur) = @siAnnee_Fiscale)
            )
            INSERT INTO #TB_ListeConvention (ConventionID, ConventionNo, ConventionStateID, StartDate, dtReconnue_RQ)
            SELECT DISTINCT C.ConventionID, C.ConventionNo, C.ConventionStateID, C.StartDate, RQ.dtReconnue_RQ
              FROM CTE_Convention C
                   LEFT JOIN dbo.fntIQEE_ConventionConnueRQ_PourTous(NULL, @siAnnee_Fiscale) RQ ON RQ.iID_Convention = C.ConventionID

            SET @NbConvention = (SELECT Count(Distinct ConventionID) FROM #TB_ListeConvention)
            SET @ElapsedTime = GetDate() - @StartTime
            PRINT '   Nb Conventions à traiter : ' + LTrim(Str(@NbConvention, 10)) + ' - Time elapsed: ' + Convert(varchar(12), @ElapsedTime, 114)

            IF @BeneficiaryID IS NOT NULL
            BEGIN
                SELECT 'Retrouve les conventions actives'
                SELECT * FROM #TB_ListeConvention
            END
        END

        IF @NbConvention > 0
        BEGIN
            PRINT ''
            PRINT 'Préparation le fichier pour l''année fiscale'
            PRINT '-------------------------------------------'
            BEGIN
                DECLARE @vcCommentaire varchar(max) = 'Estimation de l''IQÉÉ à recevoir au ' 
                                                    + LTrim(Str(Day(@dtDate_Fin_ARecevoir), 2)) + dbo.fn_Mo_TranslateIntMonthToStr(MONTH(@dtDate_Fin_ARecevoir), 'FRA') + ' ' + Str(Year(@dtDate_Fin_ARecevoir), 4)

                SELECT 
                    @iID_Parametres_IQEE = iID_Parametres_IQEE 
                FROM 
                    dbo.fntIQEE_RechercherParametres(@siAnnee_Fiscale, 1)

                SET @iID_Fichier_IQEE = 0
                SELECT 
                    @iID_Fichier_IQEE = iID_Fichier_IQEE
                FROM 
                    dbo.fntIQEE_RechercherFichiers(NULL, @siAnnee_Fiscale, @siAnnee_Fiscale, NULL, NULL, NULL, 0, NULL, 1, NULL, NULL, NULL, 'IQÉÉ à recevoir') F
                WHERE 
                    siAnnee_Fiscale = @siAnnee_Fiscale
                    AND iID_Parametres_IQEE = @iID_Parametres_IQEE
                    AND tiID_Type_Fichier = @tiID_Type_Fichier
                    AND tiID_Statut_Fichier = @tiID_Statut_Fichier
                    AND vcChemin_Fichier = ''
                    AND dtDate_Creation_Fichiers = @dtDate_Fin_ARecevoir

                SET @StartTime = GetDate()
                IF IsNull(@iID_Fichier_IQEE, 0) <> 0 BEGIN
                    PRINT '  Réinitialise le fichier'
                    EXEC dbo.psIQEE_SupprimerFichier @iID_Fichier_IQEE, 1

                    UPDATE dbo.tblIQEE_Fichiers
                       SET dtDate_Creation = GetDate(),
                           iID_Utilisateur_Creation = @iID_Createur,
                           iID_Session = @@SPID
                     WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE
                END
                ELSE BEGIN
                    PRINT '  Initialise le fichier'
                    INSERT INTO dbo.tblIQEE_Fichiers (
                        --siAnnee_Fiscale, 
                        dtDate_Creation, iID_Parametres_IQEE, tiID_Type_Fichier, bFichier_Test,
                        tiID_Statut_Fichier, vcNom_Fichier, iID_Utilisateur_Creation, vcChemin_Fichier, vcCode_Simulation,
                        bInd_Simulation, tCommentaires, iID_Session, dtDate_Creation_Fichiers
                    )
                    VALUES (
                        --@siAnnee_Fiscale, 
                        GETDATE(), @iID_Parametres_IQEE, @tiID_Type_Fichier, 0,
                        @tiID_Statut_Fichier, 'IQÉÉ à recevoir', @iID_Createur, '', NULL,
                        1, @vcCommentaire, @@SPID, @dtDate_Fin_ARecevoir
                    )
                    SET @iID_Fichier_IQEE = SCOPE_IDENTITY()
                END
                SET @ElapsedTime = GetDate() - @StartTime
                PRINT '   iID_Fichier_IQEE :' + Str(@iID_Fichier_IQEE) + ' - Time elapsed: ' + Convert(varchar(12), @ElapsedTime, 114)

                IF NOT EXISTS(SELECT TOP 1 * FROM @TB_Fichiers WHERE FichierID = @iID_Fichier_IQEE)
                    INSERT INTO @TB_Fichiers (FichierID, AnneeFiscale, DateCreation)
                         VALUES (@iID_Fichier_IQEE, @siAnnee_Fiscale, @dtDate_Fin_ARecevoir)
            END

            IF @BeneficiaryID IS NOT NULL
                SELECT '@TB_Fichiers', * FROM @TB_Fichiers TF

            PRINT ''
            PRINT 'Génère les déclarations manquantes'
            PRINT '----------------------------------'
            BEGIN
                DECLARE @bFichiers_Test BIT = 1, 
                        @bPremierEnvoiOriginaux BIT = 0,
                        @bArretPremiereErreur BIT = 1, 
                        @cCode_Portee CHAR(1) = '', 
                        @bit_CasSpecial BIT = 0,
                        @tiCode_Version TINYINT = 0,
                        @cID_Langue CHAR(3)

                SET @StartTime = GETDATE()

                IF @siAnnee_Fiscale >= @siAnnee_Fiscale_Min
                BEGIN
                    EXECUTE dbo.psIQEE_CreerTransactions02 @iID_Fichier_IQEE, @siAnnee_Fiscale, @bPremierEnvoiOriginaux, @bArretPremiereErreur, @cCode_Portee, 1, @@SPID,
                                                           @dtDate_Fin_ARecevoir, @cID_Langue, @bit_CasSpecial, @tiCode_Version
                END

                EXECUTE dbo.psIQEE_CreerTransactions03 @iID_Fichier_IQEE, @siAnnee_Fiscale, @bArretPremiereErreur, @cCode_Portee, @bit_CasSpecial, @tiCode_Version

                EXECUTE dbo.psIQEE_CreerTransactions06_01 @iID_Fichier_IQEE, @siAnnee_Fiscale, @bArretPremiereErreur, @cCode_Portee, @iID_Createur, @bit_CasSpecial, @tiCode_Version
                --EXECUTE dbo.psIQEE_CreerTransactions06_02 @iID_Fichier_IQEE, @siAnnee_Fiscale, @bArretPremiereErreur, @cCode_Portee, @iID_Createur, @bit_CasSpecial, @tiCode_Version

                EXECUTE dbo.psIQEE_CreerTransactions06_22 @iID_Fichier_IQEE, @siAnnee_Fiscale, @bArretPremiereErreur, @cCode_Portee, @iID_Createur, @bit_CasSpecial, @tiCode_Version
                EXECUTE dbo.psIQEE_CreerTransactions06_23 @iID_Fichier_IQEE, @siAnnee_Fiscale, @bArretPremiereErreur, @cCode_Portee, @bit_CasSpecial, @tiCode_Version

                EXECUTE dbo.psIQEE_CreerTransactions06_31 @iID_Fichier_IQEE, @siAnnee_Fiscale, @bArretPremiereErreur, @cCode_Portee, @iID_Createur, @bit_CasSpecial, @tiCode_Version

                EXECUTE dbo.psIQEE_CreerTransactions06_41 @iID_Fichier_IQEE, @siAnnee_Fiscale, @bArretPremiereErreur, @cCode_Portee, @iID_Createur, @bit_CasSpecial, @tiCode_Version

                EXECUTE dbo.psIQEE_CreerTransactions06_91 @iID_Fichier_IQEE, @siAnnee_Fiscale, @bArretPremiereErreur, @cCode_Portee, @iID_Createur, @bit_CasSpecial, @tiCode_Version

                SET @ElapsedTime = GetDate() - @StartTime
                PRINT 'Time elapsed : ' + Convert(varchar(12), @ElapsedTime, 114)
            END
        END

        IF Object_ID('tempDB..#TB_Demande') IS NOT NULL
            DROP TABLE #TB_Demande

        CREATE TABLE #TB_Demande (
            ConventionID INT NOT NULL,
            ConventionNo VARCHAR(15) NOT NULL,
            BeneficiaryID INT NOT NULL,
            AnneeNaissance INT NOT NULL,
            iID_Evenement INT,
            cStatut CHAR(1),
            CotisationSubventionnable MONEY,
            CotisationAdmissible MONEY,
            CotisationMajorable MONEY,
            CreditBase MONEY,
            Majoration MONEY,
            PourcentageAdmissible DECIMAL(8,6),
            PourcentageMajorable DECIMAL(8,6),
            CONSTRAINT PK_Convention_BenefConv PRIMARY KEY CLUSTERED (BeneficiaryID, ConventionID)
        )

        SELECT @tiID_Type_Enregistrement = tiID_Type_Enregistrement 
            FROM dbo.vwIQEE_Enregistrement_TypeEtSousType 
            WHERE cCode_Type_Enregistrement = '02'

        IF @siAnnee_Fiscale < @siAnnee_Fiscale_Min
            SET @NbConvention = 0
        ELSE 
        BEGIN 
            PRINT ''
            PRINT 'Retrouve les infos des demandes par convention'
            PRINT '----------------------------------------------'

            SET @StartTime = GetDate()
            ;WITH 
                CTE_Demande as (
                    -- Récupère les conventions de toutes les demandes qui n'ont pas eu de réponse
                    SELECT 
                        D.iID_Convention, D.vcNo_Convention, D.iID_Demande_IQEE, 
                        tiVersion = CASE D.iID_Fichier_IQEE WHEN @iID_Fichier_IQEE THEN NULL ELSE D.tiCode_Version END, 
                        cStatut = CASE D.iID_Fichier_IQEE WHEN @iID_Fichier_IQEE THEN '' ELSE D.cStatut_Reponse END,
                        iID_Beneficiaire = D.iID_Beneficiaire_31Decembre,
                        dtNaissance = D.dtDate_Naissance_Beneficiaire, 
                        mCotisationSubventionnable = D.mTotal_Cotisations_Subventionnables,
                        Row_Num = ROW_NUMBER() OVER(Partition by D.iID_Convention, D.iID_Beneficiaire_31Decembre Order By F.DateCreation DESC, D.tiCode_Version DESC)
                    FROM
                        dbo.tblIQEE_Demandes D
                        JOIN @TB_Fichiers F ON F.FichierID = D.iID_Fichier_IQEE
                    WHERE 
                        D.siAnnee_Fiscale = @siAnnee_Fiscale
                        AND NOT D.cStatut_Reponse in ('X')
                        AND D.iID_Beneficiaire_31Decembre = IsNull(@BeneficiaryID, D.iID_Beneficiaire_31Decembre)
                        AND D.dtDate_Naissance_Beneficiaire > @dtNaissanceMin
                        AND (IsNull(D.vcProvince_Beneficiaire, '') IN ('QC','Québec') OR IsNull(D.bResidence_Quebec, 0) <> 0)
                )
            INSERT INTO #TB_Demande (ConventionID, ConventionNo, BeneficiaryID, AnneeNaissance, iID_Evenement, CotisationSubventionnable, cStatut)
            SELECT DISTINCT 
                D.iID_Convention, D.vcNo_Convention, D.iID_Beneficiaire, year(dtNaissance), D.iID_Demande_IQEE, D.mCotisationSubventionnable, 
                CASE WHEN R.iID_Reponse_Demande IS NOT NULL THEN 'R' ELSE D.cStatut END
            FROM           
                CTE_Demande D
                JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(@dtDateDuJour, DEFAULT) S ON S.conventionID = D.iID_Convention
                LEFT JOIN dbo.tblIQEE_ReponsesDemande R ON R.iID_Demande_IQEE = D.iID_Demande_IQEE
                LEFT JOIN tblIQEE_Erreurs E ON E.iID_Enregistrement = D.iID_Demande_IQEE
                                           AND E.tiID_Type_Enregistrement = @tiID_Type_Enregistrement
            WHERE
                D.Row_Num = 1
                AND S.ConventionStateID <> 'FRM'
                AND IsNull(D.tiVersion, 0) IN (0, 2)
                --AND (   R.iID_Reponse_Demande IS NULL
                --        OR EE.iID_Erreur_Enregistrement IS NOT NULL
                --    )
                AND D.mCotisationSubventionnable > 0
            
            SET @NbConvention = @@RowCount
            SET @ElapsedTime = GetDate() - @StartTime
            PRINT 'Nb insert : ' + LTrim(Str(@NbConvention)) + ' - Time elapsed: ' + Convert(varchar(12), @ElapsedTime, 114)

            IF @BeneficiaryID IS NOT NULL
            BEGIN
                SELECT 'Retrouve info des demandes par convention'
                SELECT * FROM #TB_Demande
            END

            IF Object_ID('tempDB..#TB_MontantRecu_Convention') IS NOT NULL
                DROP TABLE #TB_MontantRecu_Convention

            CREATE TABLE #TB_MontantRecu_Convention (
                iID_Convention INT NOT NULL,
                iID_Beneficiary INT NOT NULL,
                siAnnee_Fiscale INT NOT NULL,
                dtDate_Traitement_RQ DATE,
                Cotisation_Total MONEY,
                Ayant_Droit_IQEE MONEY,
                Credit_Base MONEY,
                Majoration MONEY,
                PourcentageMMQ MONEY
            )
        
            IF @NbConvention > 0
            BEGIN
                PRINT ''
                PRINT 'Retrouve info des montants IQEE reçus par convention'
                PRINT '----------------------------------------------------'
                BEGIN
                    PRINT '  Récupère l''historique de tous les montants reçus'
                    SET @StartTime = GetDate()
                    INSERT INTO #TB_MontantRecu_Convention (iID_Convention, iID_Beneficiary, siAnnee_Fiscale, dtDate_Traitement_RQ, Cotisation_Total, Ayant_Droit_IQEE, Credit_Base, Majoration, PourcentageMMQ)
                    SELECT S.iID_Convention, S.iID_Beneficiary, S.siAnnee_Fiscale, S.dtDate_Traitement_RQ, S.Cotisation, S.Ayant_Droit_IQEE, S.CreditBase, S.Majoration, S.PourcentageMMQ
                           --Row_Num = ROW_NUMBER() OVER(Partition By D.iID_Convention Order By siAnnee_Fiscale DESC, dtDate_Traitement_RQ DESC)
                      FROM dbo.fntIQEE_ObtenirMontantRecu_ParConvention(NULL, NULL, @dtDateDuJour) S
                           JOIN #TB_ConventionBeneficiary C ON C.ConventionID = S.iID_Convention AND C.BeneficiaryID = S.iID_Beneficiary
                     WHERE siAnnee_Fiscale <= @siAnnee_Fiscale
                    SET @nCount = @@RowCount
                    SET @ElapsedTime = GetDate() - @StartTime
                    PRINT '  Nb insert : ' + LTrim(Str(@nCount)) + ' - Time elapsed: ' + Convert(varchar(12), @ElapsedTime, 114)

                    PRINT '  Met à jour les montants reçus pour l''année en cours'
                    SET @StartTime = GetDate()
                    UPDATE D SET
                        CotisationSubventionnable = M.Cotisation_Total,
                        CotisationAdmissible = M.Ayant_Droit_IQEE,
                        CotisationMajorable = CASE WHEN M.Cotisation_Total > 500 THEN 500.0 ELSE M.Cotisation_Total END,
                        CreditBase = m.Credit_Base,
                        Majoration = M.Majoration,
                        PourcentageAdmissible = CASE M.Cotisation_Total WHEN 0 THEN 0 ELSE m.Credit_Base / (M.Cotisation_Total * 0.10) END,
                        PourcentageMajorable = CASE WHEN M.PourcentageMMQ = 0 THEN 0 
                                                    WHEN M.Cotisation_Total = 0 THEN 0 
                                                    ELSE M.Majoration / (CASE WHEN M.Cotisation_Total > 500 THEN 500.0 ELSE M.Cotisation_Total END * M.PourcentageMMQ)
                                               END 
                    FROM
                        #TB_Demande D
                        JOIN #TB_MontantRecu_Convention M ON D.ConventionID = M.iID_Convention AND D.BeneficiaryID = M.iID_Beneficiary
                    WHERE
                        siAnnee_Fiscale = @siAnnee_Fiscale
                    SET @nCount = @@RowCount
                    SET @ElapsedTime = GetDate() - @StartTime
                    PRINT '  Nb update : ' + LTrim(Str(@nCount)) + ' - Time elapsed: ' + Convert(varchar(12), @ElapsedTime, 114)

                    IF @BeneficiaryID IS NOT NULL
                    BEGIN
                        SELECT 'Retrouve info des montants ayant droit à l''IQEE'
                        SELECT ConventionID, ConventionNo, BeneficiaryID, cStatut,
                               CotisationSubventionnable, CotisationAdmissible, CotisationMajorable,
                               CreditBase, Majoration, PourcentageAdmissible, PourcentageMajorable
                          FROM #TB_Demande

                        SELECT iID_Convention, iID_Beneficiary, 
                               Annee_Fiscale = MAX(CASE X.Row_Num WHEN 1 then siAnnee_Fiscale ELSE 0 END), 
                               Date_Traitement_RQ = MAX(CASE X.Row_Num WHEN 1 then dtDate_Traitement_RQ ELSE '1900-01-01' END), 
                               Montant_Recu = SUM(Ayant_Droit_IQEE), 
                               PourcentageMMQ = MIN(CASE x.Row_Num WHEN 1 THEN PourcentageMMQ ELSE 0.1 END)
                          FROM (
                                SELECT *, Row_Num = ROW_NUMBER() OVER(PARTITION BY iID_Convention ORDER BY siAnnee_Fiscale DESC) 
                                FROM #TB_MontantRecu_Convention) X 
                         --WHERE X.Row_Num = 1
                         GROUP BY iID_Convention, iID_Beneficiary
                    END
                END

                PRINT ''
                PRINT 'Somme info des cotisations des conventions par bénéficiare'
                PRINT '----------------------------------------------------------'
                BEGIN
                    IF Object_ID('tempDB..#TB_Beneficiary') IS NOT NULL
                        DROP TABLE #TB_Beneficiary

                    CREATE TABLE #TB_Beneficiary (
                        BeneficiaryID INT NOT NULL,
                        AnneeNaissance int NOT NULL,
                        NbConvention tinyint,
                        CotisationSubventionnable MONEY,
                        CotisationAdmissible MONEY,
                        DroitsAccumules MONEY,
                        CotisationMajorable MONEY,
                        PourcentageMajoration MONEY, --DECIMAL(5,4),
                        CreditBase MONEY,
                        Majoration MONEY,
                        CONSTRAINT PK_Beneficiary_ID PRIMARY KEY CLUSTERED (BeneficiaryID)
                    )
                                                               
                    PRINT '  Retrouve info des cotisations par bénéficiaire'
                    SET @StartTime = GetDate()
                    ;WITH CTE_Beneficiary as (
                        SELECT DISTINCT 
                            D.BeneficiaryID,  D.AnneeNaissance, 
                            NbConvention = Count(*),
                            TotalSubventionnable = Sum(D.CotisationSubventionnable)
                        FROM           
                            #TB_Demande D
                        WHERE
                            D.CotisationSubventionnable > 0
                        GROUP BY
                            D.BeneficiaryID, D.AnneeNaissance
                    ),
                    CTE_MontantRecuAnnuel as (
                        SELECT DISTINCT
                            S.iID_Beneficiary, S.siAnnee_Fiscale, S.dtDate_Traitement_RQ, S.PourcentageMMQ, S.Ayant_Droit_IQEE,
                            Row_Num = ROW_NUMBER() OVER(Partition By S.iID_Beneficiary, S.siAnnee_Fiscale, S.iID_Convention Order By S.dtDate_Traitement_RQ DESC),
                            Row_Num2 = ROW_NUMBER() OVER(Partition By S.iID_Beneficiary Order By S.siAnnee_Fiscale DESC, S.dtDate_Traitement_RQ DESC)
                        FROM 
                            #TB_MontantRecu_Convention S
                            JOIN CTE_Beneficiary B ON B.BeneficiaryID = s.iID_Beneficiary
                    ),
                    CTE_MontantRecuTotal as (
                        SELECT 
                            iID_Beneficiary, 
                            CotisationAyantEuDroit = Cast(Sum(CASE Row_Num WHEN 1 THEN Ayant_Droit_IQEE ELSE 0 END) as money)
                        FROM 
                            CTE_MontantRecuAnnuel S
                        GROUP BY 
                            iID_Beneficiary
                    ),
                    CTE_Pourcent as (
                        SELECT 
                            iID_Beneficiary, PourcentageMMQ
                        FROM 
                            CTE_MontantRecuAnnuel S
                        WHERE
                            Row_Num2 = 1
                    )
                    INSERT INTO #TB_Beneficiary (BeneficiaryID, AnneeNaissance, NbConvention, CotisationSubventionnable, PourcentageMajoration, DroitsAccumules)
                    SELECT DISTINCT
                        B.BeneficiaryID, B.AnneeNaissance, B.NbConvention, B.TotalSubventionnable, ISNULL(P.PourcentageMMQ, 0.0300),
                        CASE WHEN B.AnneeNaissance >= @AnneeDebut_IQEE THEN @siAnnee_Fiscale - B.AnneeNaissance + 1
                                ELSE @siAnnee_Fiscale - @AnneeDebut_IQEE + 1 END * 2500.0 - IsNull(S.CotisationAyantEuDroit, @ZeroMoney) as mDroitsAccumules
                    FROM
                        CTE_Beneficiary B
                        LEFT JOIN CTE_MontantRecuTotal S ON S.iID_Beneficiary = B.BeneficiaryID
                        LEFT JOIN CTE_Pourcent P ON P.iID_Beneficiary = B.BeneficiaryID
                    SET @nCount = @@RowCount
                    SET @ElapsedTime = GetDate() - @StartTime
                    PRINT 'Nb insert : ' + LTrim(Str(@nCount)) + ' - Time elapsed: ' + Convert(varchar(12), @ElapsedTime, 114)

                    IF @BeneficiaryID IS NOT NULL
                    BEGIN
                        SELECT 'Retrouve info des cotisations par bénéficiaire'
                        SELECT * FROM #TB_Beneficiary
                    END
                END

                PRINT ''
                PRINT 'Calcule les montants IQÉÉ à recevoir par bénéficiaire'
                PRINT '-----------------------------------------------------'
                BEGIN
                    SET @StartTime = GetDate()
                    ;WITH CTE_Beneficiary As(
                        SELECT BeneficiaryID, DroitsAccumules, PourcentageMajoration, CotisationSubventionnable,
                               mCotisationAdmissible = CASE WHEN CotisationSubventionnable > 5000.0 THEN 5000.0 
                                                            WHEN CotisationSubventionnable > 0.0 THEN CotisationSubventionnable
                                                            ELSE 0.0 END,
                               mCotisationMajorable = CASE WHEN CotisationSubventionnable > 500.0 THEN 500.0 
                                                           WHEN CotisationSubventionnable > 0.0 THEN CotisationSubventionnable 
                                                           ELSE 0.0 END
                          FROM #TB_Beneficiary
                    ),
                    CTE_Montant as (
                        SELECT BeneficiaryID, PourcentageMajoration, mCotisationMajorable,
                               mMontantAdmissible = CASE WHEN mCotisationAdmissible > DroitsAccumules THEN DroitsAccumules
                                                         ELSE mCotisationAdmissible END
                          FROM CTE_Beneficiary B
                    )
                    UPDATE B SET
                        CotisationAdmissible = M.mMontantAdmissible,
                        CotisationMajorable = M.mCotisationMajorable,
                        CreditBase = M.mMontantAdmissible * 0.10,
                        Majoration = M.mCotisationMajorable * IsNull(M.PourcentageMajoration, 0.0300)
                    FROM
                        #TB_Beneficiary B
                        JOIN CTE_Montant M ON M.BeneficiaryID = B.BeneficiaryID
                    SET @nCount = @@ROWCOUNT
                    SET @ElapsedTime = GetDate() - @StartTime
                    PRINT '   Nb Update : ' + LTrim(Str(@nCount)) + ' - Time elapsed: ' + Convert(varchar(12), @ElapsedTime, 114)

                    IF @BeneficiaryID IS NOT NULL
                    BEGIN
                        SELECT 'Calcul les montants IQÉÉ à recevoir par bénéficiaire'
                        SELECT * FROM #TB_Beneficiary
                    END
                END

                PRINT ''
                PRINT 'Calcule les montants IQÉÉ à recevoir par convention'
                PRINT '---------------------------------------------------'
                BEGIN
                    SET @StartTime = GetDate()
                    ;WITH CTE_Convention As(
                        SELECT D.ConventionID, D.BeneficiaryID, B.DroitsAccumules, 
                               B.PourcentageMajoration,
                               mCotisationAdmissible = CASE WHEN D.CotisationSubventionnable > 5000.0 THEN 5000.0
                                                            WHEN D.CotisationSubventionnable > 0.0 THEN D.CotisationSubventionnable 
                                                            ELSE 0.0 END,
                               mCotisationMajorable = CASE WHEN D.CotisationSubventionnable > 500.0 THEN 500.0 
                                                           WHEN D.CotisationSubventionnable > 0.0 THEN D.CotisationSubventionnable 
                                                           ELSE 0.0 END
                          FROM #TB_Demande D
                               JOIN #TB_Beneficiary B ON B.BeneficiaryID = D.BeneficiaryID
                         WHERE D.cStatut <> 'R'
                    ),
                    CTE_Montant as (
                        SELECT C.ConventionID, C.BeneficiaryID, C.PourcentageMajoration, C.mCotisationMajorable,
                                mCotisationAdmissible = CASE WHEN C.mCotisationAdmissible > C.DroitsAccumules THEN C.DroitsAccumules
                                                             ELSE C.mCotisationAdmissible END
                            FROM CTE_Convention C
                                --JOIN #TB_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
                    )
                    UPDATE D SET
                        CotisationAdmissible = mCotisationAdmissible,
                        CotisationMajorable = mCotisationMajorable,
                        CreditBase = mCotisationAdmissible * 0.10,
                        Majoration = mCotisationMajorable * IsNull(M.PourcentageMajoration, 0.0300)
                    FROM
                        #TB_Demande D
                        JOIN CTE_Montant M ON M.ConventionID = D.ConventionID AND M.BeneficiaryID = D.BeneficiaryID
                    WHERE
                        D.cStatut <> 'R'
                    SET @nCount = @@ROWCOUNT
                                 
                    SET @ElapsedTime = GetDate() - @StartTime
                    PRINT '   Nb Update : ' + LTrim(Str(@nCount)) + ' - Time elapsed: ' + Convert(varchar(12), @ElapsedTime, 114)

                    IF @BeneficiaryID IS NOT NULL
                    BEGIN
                        SELECT 'Calcul les montants IQÉÉ à recevoir par convention'
                        SELECT * FROM #TB_Demande
                    END
                END

                PRINT ''
                PRINT 'Applique la règle de partage des conventions au même bénéficiaire'
                PRINT '-----------------------------------------------------------------'
                BEGIN
                    --IF @BeneficiaryID IS NOT NULL
                    --BEGIN
                    --    ;WITH CTE_Total AS (
                    --        SELECT BeneficiaryID, SUM(CotisationAdmissible) AS Total_Admissible, SUM(CotisationMajorable) AS Total_Majorable
                    --          FROM #TB_Demande
                    --         GROUP BY BeneficiaryID
                    --        HAVING COUNT(*) > 1
                    --    )
                    --    SELECT D.*, T.*, B.*, D.CotisationAdmissible / T.Total_Admissible, D.CotisationMajorable / T.Total_Majorable,
                    --        CreditBase = CASE WHEN T.Total_Admissible > B.CotisationAdmissible THEN D.CreditBase ELSE (B.CreditBase * D.CotisationAdmissible) / T.Total_Admissible END,
                    --        Majoration = CASE WHEN T.Total_Majorable > B.CotisationMajorable THEN D.Majoration ELSE (B.Majoration * D.CotisationMajorable) / T.Total_Majorable END
                    --    FROM
                    --        #TB_Demande D
                    --        JOIN #TB_Beneficiary B ON B.BeneficiaryID = D.BeneficiaryID
                    --        JOIN CTE_Total T ON T.BeneficiaryID = D.BeneficiaryID
                    --    WHERE
                    --        (T.Total_Admissible > B.CotisationAdmissible OR T.Total_Majorable > B.CotisationMajorable)
                    --        AND NOT (T.Total_Admissible = 0 or T.Total_Majorable = 0)
                    --END 

                    SET @StartTime = GetDate()
                    --;WITH CTE_Recu AS (
                    --    SELECT D.BeneficiaryID, --CotisationAdmissible, CreditBase, Majoration
                    --           Total_Admissible = SUM(D.CotisationAdmissible), 
                    --           Total_Majorable = SUM(D.CotisationMajorable),
                    --           Total_CBQ = SUM(D.CreditBase),
                    --           Total_MMQ = SUM(D.Majoration)
                    --      FROM #TB_Demande D 
                    --     WHERE cStatut = 'R'
                    --     GROUP BY D.BeneficiaryID
                    --)
                    --SELECT b.BeneficiaryID, 
                    --        Restant_Admissible = B.CotisationAdmissible - ISNULL(R.Total_Admissible, 0),
                    --        Restant_Majorable = B.CotisationMajorable - ISNULL(R.Total_Majorable, 0),
                    --        Restant_CBQ = B.CreditBase - ISNULL(R.Total_CBQ, 0),
                    --        Restant_MMQ = B.Majoration - ISNULL(R.Total_MMQ, 0)
                    --    FROM #TB_Beneficiary B
                    --        LEFT JOIN CTE_Recu R ON B.BeneficiaryID = R.BeneficiaryID

                    --SELECT D.BeneficiaryID, 
                    --        Attente_Admissible = SUM(D.CotisationAdmissible), 
                    --        Attente_Majorable = SUM(D.CotisationMajorable)
                    --    FROM #TB_Demande D
                    --    WHERE cStatut <> 'R'
                    --    GROUP BY BeneficiaryID

                    ;WITH CTE_Recu AS (
                        SELECT D.BeneficiaryID, --CotisationAdmissible, CreditBase, Majoration
                               Total_Admissible = SUM(D.CotisationAdmissible), 
                               Total_Majorable = SUM(D.CotisationMajorable),
                               Total_CBQ = SUM(D.CreditBase),
                               Total_MMQ = SUM(D.Majoration)
                          FROM #TB_Demande D 
                         WHERE cStatut = 'R'
                         GROUP BY D.BeneficiaryID
                    ),
                    CTE_Beneficiary AS (
                        SELECT b.BeneficiaryID, 
                               Restant_Admissible = B.CotisationAdmissible - ISNULL(R.Total_Admissible, 0),
                               Restant_Majorable = B.CotisationMajorable - ISNULL(R.Total_Majorable, 0),
                               Restant_CBQ = B.CreditBase - ISNULL(R.Total_CBQ, 0),
                               Restant_MMQ = B.Majoration - ISNULL(R.Total_MMQ, 0)
                          FROM #TB_Beneficiary B
                               LEFT JOIN CTE_Recu R ON B.BeneficiaryID = R.BeneficiaryID
                    ),
                    CTE_Attente AS (
                        SELECT D.BeneficiaryID, 
                               Attente_Admissible = SUM(D.CotisationAdmissible), 
                               Attente_Majorable = SUM(D.CotisationMajorable)
                          FROM #TB_Demande D
                         WHERE cStatut <> 'R'
                         GROUP BY BeneficiaryID
                    )
                    UPDATE D SET
                        CreditBase = CASE WHEN B.Restant_Admissible < 0 THEN 0
                                          WHEN A.Attente_Admissible = 0 THEN 0 
                                          WHEN A.Attente_Admissible <= B.Restant_Admissible THEN D.CreditBase 
                                          ELSE (B.Restant_CBQ * D.CotisationAdmissible) / A.Attente_Admissible END,
                        Majoration = CASE WHEN B.Restant_Majorable < 0 THEN 0
                                          WHEN A.Attente_Majorable = 0 THEN 0 
                                          WHEN A.Attente_Majorable <= B.Restant_Majorable THEN D.Majoration 
                                          ELSE (B.Restant_MMQ * D.CotisationMajorable) / A.Attente_Majorable END,
                        PourcentageAdmissible = CASE WHEN B.Restant_Admissible < 0 THEN 0.0000 
                                                     WHEN A.Attente_Admissible <= B.Restant_Admissible THEN 1.0000 
                                                     ELSE D.CotisationAdmissible / A.Attente_Admissible END,
                        PourcentageMajorable = CASE WHEN B.Restant_Majorable < 0 THEN 0.0000 
                                                    WHEN A.Attente_Majorable <= B.Restant_Majorable 
                                                    THEN 1.0000 ELSE D.CotisationMajorable / A.Attente_Majorable END
                    FROM
                        #TB_Demande D
                        JOIN CTE_Beneficiary B ON B.BeneficiaryID = D.BeneficiaryID
                        JOIN CTE_Attente A ON A.BeneficiaryID = D.BeneficiaryID
                    WHERE
                        D.cStatut <> 'R'
                        --AND (A.Attente_Admissible > B.Restant_Admissible OR A.Attente_Majorable > B.Restant_Majorable)

                    SET @nCount = @@ROWCOUNT
                    SET @ElapsedTime = GetDate() - @StartTime
                    PRINT '   Nb Update : ' + LTrim(Str(@nCount)) + ' - Time elapsed: ' + Convert(varchar(12), @ElapsedTime, 114)

                    IF @BeneficiaryID IS NOT NULL
                    BEGIN
                        SELECT 'Partage les montants IQÉÉ à recevoir par convention'
                        SELECT D.*, B.CotisationSubventionnable, B.CotisationAdmissible 
                          FROM #TB_Demande D JOIN #TB_Beneficiary B ON B.BeneficiaryID = D.BeneficiaryID
                    END
                END

                PRINT ''
                PRINT 'Sauvegarde les estimés du IQÉÉ à recevoir'
                PRINT '-----------------------------------------'
                BEGIN
                    SELECT @tiID_Type_Enregistrement = tiID_Type_Enregistrement 
                        FROM dbo.vwIQEE_Enregistrement_TypeEtSousType 
                        WHERE cCode_Type_Enregistrement = '02'

                    SET @StartTime = GetDate()
                    INSERT INTO dbo.tblIQEE_Estimer_ARecevoir (
                        iID_Plan, siAnnee_Cohorte, iID_Beneficiaire, siAnnee_Fiscale, 
                        tiID_TypeEnregistrement, iId_SousType, iID_Evenement, dtEvenement,
                        iID_Convention, vcNo_Convention,
                        mMontant_Subventionnable, mMontant_Admissible, mMontant_Majorable,
                        fPourcentMajoration, mCreditBase_Estime, mMajoration_Estime, mTotal_Estime,
                        fCreditBase_Partage, fMajoration_Partage,
                        dtFin_ARecevoir, dtCreation
                    )
                    SELECT
                        X.PlanID, D.AnneeNaissance + 17, D.BeneficiaryID, @siAnnee_Fiscale, 
                        @tiID_Type_Enregistrement, NULL,
                        D.iID_Evenement, @dtFinCotisation,
                        D.ConventionID, D.ConventionNo, 
                        D.CotisationSubventionnable, D.CotisationAdmissible, D.CotisationMajorable, 
                        B.PourcentageMajoration, D.CreditBase, D.Majoration, D.CreditBase + D.Majoration,
                        D.PourcentageAdmissible, D.PourcentageMajorable,
                        @dtDate_Fin_ARecevoir, @dtDateDuJour
                    FROM
                        #TB_Demande D
                        JOIN #TB_Beneficiary B ON B.BeneficiaryID = D.BeneficiaryID
                        JOIN dbo.Un_Convention X ON X.ConventionID = D.ConventionID
                    WHERE
                        D.cStatut <> 'R'

                    SET @nCount = @@ROWCOUNT
                    SET @ElapsedTime = GetDate() - @StartTime
                    PRINT '   Nb insert : ' + LTrim(Str(@nCount)) + ' - Time elapsed: ' + Convert(varchar(12), @ElapsedTime, 114)
                END
            end
        END

        PRINT ''
        PRINT 'Sauvegarde les estimés du IQÉÉ à payer'
        PRINT '--------------------------------------'
        BEGIN
            SELECT @tiID_Type_Enregistrement = tiID_Type_Enregistrement 
              FROM dbo.vwIQEE_Enregistrement_TypeEtSousType 
             WHERE cCode_Type_Enregistrement = '06'

            SET @StartTime = GetDate()
            ;WITH CTE_ImpotSpecial as (
                SELECT I.iID_Impot_Special, I.iID_Sous_Type, I.tiCode_Version, I.cStatut_Reponse, I.dtDate_Evenement,
                       tiVersion = CASE I.iID_Fichier_IQEE WHEN @iID_Fichier_IQEE THEN NULL ELSE I.tiCode_Version END, 
                       cStatut = CASE I.iID_Fichier_IQEE WHEN @iID_Fichier_IQEE THEN NULL ELSE I.cStatut_Reponse END,
                       I.iID_Convention, I.vcNo_Convention, I.iID_Beneficiaire, 
                       AnneeNaissance = YEAR(I.dtDate_Naissance_Beneficiaire),
                       I.mCotisations_Retirees, I.mCotisations_Donne_Droit_IQEE, I.mSolde_IQEE_Base, I.mSolde_IQEE_Majore, I.mIQEE_ImpotSpecial,
                       Row_Num = ROW_NUMBER() OVER(Partition by I.iID_Convention, I.iID_Sous_Type Order By F.DateCreation DESC)
                  FROM dbo.tblIQEE_ImpotsSpeciaux I
                       JOIN @TB_Fichiers F ON F.FichierID = I.iID_Fichier_IQEE
                 WHERE I.siAnnee_Fiscale = @siAnnee_Fiscale
                   AND I.cStatut_Reponse <> 'X'
                   AND I.iID_Beneficiaire = IsNull(@BeneficiaryID, I.iID_Beneficiaire)
            )
            INSERT INTO dbo.tblIQEE_Estimer_APayer (
                tiID_TypeEnregistrement, iId_SousType, iID_Plan, siAnnee_Cohorte,
                iID_Convention, vcNo_Convention, iID_Beneficiaire, siAnnee_Fiscale,
                iID_Evenement, dtEvenement, tiVersion, cStatut,
                mMontant_Retire, mMontant_AyantEuDroit,
                mCreditBase_Estime, mMajoration_Estime, mTotal_Estime,
                dtFin_APayer, dtCreation
            )
            SELECT
                @tiID_Type_Enregistrement, I.iID_Sous_Type, C.PlanID, I.AnneeNaissance + 17,   
                I.iID_Convention, I.vcNo_Convention, I.iID_Beneficiaire, @siAnnee_Fiscale, 
                I.iID_Impot_Special, I.dtDate_Evenement, I.tiVersion, I.cStatut,
                I.mCotisations_Retirees, I.mCotisations_Donne_Droit_IQEE,
                CreditBase = -1.0 * IsNull(I.mSolde_IQEE_Base, @ZeroMoney), 
                Majoration = -1.0 * IsNull(I.mSolde_IQEE_Majore, @ZeroMoney),  
                ImpotSpecial = -1.0 * IsNull(I.mIQEE_ImpotSpecial, @ZeroMoney), 
                @dtDate_Fin_ARecevoir, @dtDateDuJour
            FROM
                CTE_ImpotSpecial I
                JOIN dbo.Un_Convention C ON C.ConventionID = I.iID_Convention
                LEFT JOIN dbo.tblIQEE_ReponsesImpotsSpeciaux R ON R.iID_Impot_Special_IQEE = I.iID_Impot_Special
                LEFT JOIN tblIQEE_Erreurs E ON E.iID_Enregistrement = I.iID_Impot_Special 
                                           AND E.tiID_Type_Enregistrement = @tiID_Type_Enregistrement
            WHERE
                I.Row_Num = 1
                AND IsNull(I.tiVersion, 0) IN (0, 2)
                AND (   R.iID_Reponse_Impot_Special IS NULL 
                        OR I.cStatut = 'A'
                        OR E.iID_Erreur IS NOT NULL
                    )
                AND E.iID_Erreur IS NULL
            SET @nCount = @@ROWCOUNT
            SET @ElapsedTime = GetDate() - @StartTime
            PRINT '   Nb Insert : ' + LTrim(Str(@nCount)) + ' - Time elapsed: ' + Convert(varchar(12), @ElapsedTime, 114)

            IF @BeneficiaryID IS NOT NULL
                select * FROM dbo.tblIQEE_Estimer_APayer WHERE iID_Beneficiaire = @BeneficiaryID AND siAnnee_Fiscale = @siAnnee_Fiscale
        END
                
        SET @siAnnee_Fiscale = @siAnnee_Fiscale + 1
    END

    PRINT ''
    PRINT 'Sauvegarde les estimés du IQÉÉ à payer pour les conventions fermés'
    PRINT '------------------------------------------------------------------'
    BEGIN

        SELECT @tiID_Type_Enregistrement = tiID_Type_Enregistrement,
               @tiID_SousType_Enreg = iID_Sous_Type
          FROM dbo.vwIQEE_Enregistrement_TypeEtSousType 
         WHERE cCode_Type_Enregistrement = '06'
           AND cCode_Sous_Type = '91'

        SET @StartTime = GetDate()

        IF OBJECT_ID('tempDB..#TB_ConventionFermee') IS NOT NULL 
            DROP TABLE #TB_ConventionFermee

        IF OBJECT_ID('tempDB..#TB_ConventionFermee') IS NOT NULL 
            DROP TABLE #TB_ConventionFermee;

        ;WITH CTE_Convention AS (
            SELECT C.ConventionID, C.ConventionNo, CB.iID_Nouveau_Beneficiaire AS BeneficiaireID, C.PlanID, C.YearQualif, 
                   S.StartDate, S.ConventionStateID,
                   Row_Num = Row_Number() OVER (PARTITION BY C.ConventionID ORDER BY dtDate_Changement_Beneficiaire DESC)
              FROM dbo.Un_Convention C
                   JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(@dtDate_Fin_ARecevoir, NULL) S ON S.conventionID = C.ConventionID
                   JOIN dbo.tblCONV_ChangementsBeneficiaire CB ON CB.iID_Convention = S.conventionID AND CB.dtDate_Changement_Beneficiaire <= S.StartDate
             WHERE S.ConventionStateID = 'FRM'
               AND CB.iID_Nouveau_Beneficiaire = ISNULL(@BeneficiaryID, CB.iID_Nouveau_Beneficiaire)
        )
        SELECT ConventionID, ConventionNo, BeneficiaireID, PlanID, YearQualif, StartDate, ConventionStateID
          INTO #TB_ConventionFermee
          FROM CTE_Convention
         WHERE Row_Num = 1

        IF OBJECT_ID('tempDB..#TB_APayer') IS NOT NULL 
            DROP TABLE #TB_APayer

        SELECT iID_Convention, CreditBase_APayer = SUM(mCreditBase_Estime), Majoration_APayer = SUM(mMajoration_Estime),
               Total_APAyer = SUM(mCreditBase_Estime  +mMajoration_Estime)
          INTO #TB_APayer
          FROM tblIQEE_Estimer_APayer P
         WHERE EXISTS(SELECT * FROM #TB_ConventionFermee F WHERE F.ConventionID = P.iID_Convention)
         GROUP BY iID_Convention

        IF @BeneficiaryID IS NOT NULL --OR @@SERVERNAME = 'SrvSql26'
            SELECT C.*, S.Credit_Base, S.Majoration, P.CreditBase_APayer, P.Majoration_APayer, P.Total_APAyer 
              FROM #TB_ConventionFermee C
                   JOIN dbo.fntIQEE_CalculerSoldeIQEE_ParConvention(NULL, @dtDateDuJour, DEFAULT) S ON S.ConventionID = C.ConventionID
                   LEFT JOIN #TB_APayer P ON P.iID_Convention = C.ConventionID
             WHERE C.BeneficiaireID = ISNULL(@BeneficiaryID, 0)

        INSERT INTO dbo.tblIQEE_Estimer_APayer (
            tiID_TypeEnregistrement, iId_SousType, iID_Plan, siAnnee_Cohorte,
            iID_Convention, vcNo_Convention, iID_Beneficiaire, siAnnee_Fiscale, dtEvenement,
            mMontant_Retire, mMontant_AyantEuDroit,
            mCreditBase_Estime, mMajoration_Estime, mTotal_Estime,
            dtFin_APayer, dtCreation
        )
        SELECT
            @tiID_Type_Enregistrement, @tiID_SousType_Enreg, 
            C.PlanID, C.YearQualif,   
            C.ConventionID, C.ConventionNo, C.BeneficiaireID, 
            YEAR(C.StartDate) + 1, @dtDateDuJour, --C.StartDate,
            0, 0,
            CreditBase = IsNull(-I.CreditBase_APayer, @ZeroMoney) - S.Credit_Base, 
            Majoration = IsNull(-I.Majoration_APayer, @ZeroMoney) - S.Majoration, 
            ImpotSpecial = ISNULL(-Total_APAyer, @ZeroMoney) - (S.Credit_Base + S.Majoration),
            @dtDate_Fin_ARecevoir, @dtDateDuJour
        FROM 
            #TB_ConventionFermee C
            --JOIN #TB_ConventionSolde S ON S.ConventionID = C.ConventionID
            JOIN dbo.fntIQEE_CalculerSoldeIQEE_ParConvention(NULL, @dtDateDuJour, DEFAULT) S ON S.ConventionID = C.ConventionID
            LEFT JOIN #TB_APayer I ON I.iID_Convention = S.ConventionID
        WHERE
            S.Credit_Base + S.Majoration > 0
            AND ISNULL(-Total_APAyer, @ZeroMoney) - (S.Credit_Base + S.Majoration) < 0
            AND (S.Credit_Base <> IsNull(-I.CreditBase_APayer, @ZeroMoney) OR S.Majoration <> IsNull(-I.Majoration_APayer, @ZeroMoney))

        SET @nCount = @@ROWCOUNT
        SET @ElapsedTime = GetDate() - @StartTime
    PRINT '   Nb Insert : ' + LTrim(Str(@nCount)) + ' - Time elapsed: ' + Convert(varchar(12), @ElapsedTime, 114)
    END 
        
    PRINT ''
    PRINT '================================'
    PRINT 'Terminate at ' + Convert(varchar(20), GetDate(), 121)
END
