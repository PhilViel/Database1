/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service : psIQEE_CreerTransactions04_03
Nom du service  : Créer les transactions de type 04-03 - Transfert entre régimes internes
But             : Sélectionner, valider et créer les transactions de type 04 – 03, concernant les transferts internes
                  dans un nouveau fichier de transactions de l’IQÉÉ.
Facette         : IQÉÉ

Paramètres d’entrée :
    Paramètre               Description
    --------------------    -----------------------------------------------------------------
    iID_Fichier_IQEE        Identifiant du nouveau fichier de transactions dans lequel les transactions doivent être créées.
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
    2016-04-04  Steeve Picard               Création du service (basé sur la psIQEE_CreerTransactions04)
    2016-04-22  Steeve Picard               Ajout des déclarations pour les TIO
    2017-06-09  Steeve Picard               Ajout du paramètre « @tiCode_Version = 0 » pour passer la valeur « 2 » lors d'une annulation/reprise
    2017-07-11  Steeve Picard               Élimination du paramètre « iID_Convention » pour toujours utiliser la table « #TB_ListeConvention »
    2017-11-09  Steeve Picard               Ajout du paramètre «siAnnee_Fiscale» à la fonction «fntIQEE_ConventionConnueRQ_PourTous»
    2017-12-05  Steeve Picard               Élimination du paramètre «dtReference» de la fonction «fntIQEE_ConventionConnueRQ_PourTous»
    2018-02-08  Steeve Picard           Déplacement de «siAnnee_Fiscale» de la table «tblIQEE_Fichiers» vers les tables d'évèments «tblIQEE_Transferts»
    2018-02-26  Steeve Picard           Empêcher que la «dtFinCotisation» soit plus grande que la dernière fin de mois
    2018-06-06  Steeve Picard           Modificiation de la gestion des retours d'erreur par RQ
    2018-09-19  Steeve Picard           Ajout du champ «iID_SousType» à la table «tblIQEE_CasSpeciaux» pour pouvoir filtrer
***********************************************************************************************************************/
CREATE PROCEDURE dbo.psIQEE_CreerTransactions04_03
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
    PRINT 'Déclaration des transferts à l''interne entre convention (T04-03) pour ' + STR(@siAnnee_Fiscale, 4)
    PRINT '---------------------------------------------------------------------------'
    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' EXEC psIQEE_CreerTransactions04_03 started'

    -- Empêcher ces déclarations en PROD
    IF @siAnnee_Fiscale < 2018 AND @bit_CasSpecial = 0 --AND @@SERVERNAME IN ('SRVSQL12', 'SRVSQL25')
    BEGIN
        PRINT '   *** Déclaration non-implanté en PROD ou avant 2018'
        RETURN
    END 

    IF Object_ID('tempDB..#TB_ListeConvention') IS NULL
        RAISERROR ('La table « #TB_ListeConvention (RowNo INT Identity(1,1), ConventionID int, ConventionNo varchar(20) » est abesente ', 16, 1)

    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Identifie le(s) convention(s)'
    DECLARE @iCount int = (SELECT Count(*) FROM #TB_ListeConvention)
    IF @iCount > 0
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '   - ' + LTrim(Str(@iCount)) + ' conventions à génèrées'

    DECLARE
        @iID_Convention_Src INT, 
        @iID_Convention_Dest INT, 
        @vcNo_Convention_Src VARCHAR(15), 
        @vcNo_Convention_Dest VARCHAR(15), 
        @dtDate_Transfert DATETIME, 
        @dtDate_TransfertOld DATETIME, 
        @mSoldeReel_IQEE MONEY, 
        @mCreditBase_IQEE MONEY,
        @mMajore_IQEE MONEY,
        @mInteret_IQEE MONEY, 
        @mSolde_PCEE MONEY, 
        @mSolde_BEC MONEY, 
        @mInteret_PCEE MONEY, 
        @Solde_Subvention MONEY, 
        @mTotal_Cotisation MONEY,
        @mTotal_Frais MONEY,
        @mTotal_Transfert MONEY, 
        @mCotisations_Donne_Droit_IQEE MONEY, 
        @mCotisations_Sans_Droit_IQEE MONEY, 
        @mCotisations_Avant_Debut_IQEE MONEY, 
        --@vcListe_TypeOperation VARCHAR(200), 
        @vcType_Operation VARCHAR(3), 
        @dtDate_Debut_Convention DATE, 
        @iID_Sous_Type INT, 
        @iID_TIO INT, 
        @iID_Operation INT, 
        @iID_RIO INT, 

        --@iID_TMP INT, 
        --@iID_Cotisation INT, 
        --@iID_Cheque INT, 

        @vcNEQ VARCHAR(10),
        @iID_Autre_Promoteur INT = 0, 
        @iID_Regime_Autre_Promoteur INT = 1, 
        @vcNo_Contrat_Autre_Promoteur VARCHAR(15), 
        @vcNEQ_Autre_Promoteur VARCHAR(10), 

        --@bTransfert_Total BIT, 
        @bPRA_Deja_Verse BIT, 
        @mJuste_Valeur_Marchande MONEY, 
        --@mTMP_Interets_IQEE MONEY, 

        @iID_Beneficiaire INT,
        @vcNAS_Beneficiaire VARCHAR(9), 
        @vcNom_Beneficiaire VARCHAR(20), 
        @vcPrenom_Beneficiaire VARCHAR(20), 
        @dtDate_Naissance_Beneficiaire DATETIME, 
        --@tiSexe_Beneficiaire TINYINT, 
        @cSexe_Beneficiaire CHAR(1), 
        @vcNom_Benef_Long VARCHAR(100), 

        @iID_Adresse_Beneficiaire INT, 
        --@vcAppartement_Beneficiaire VARCHAR(6), 
        @vcNo_Civique_Beneficiaire VARCHAR(10), 
        @vcRue_Beneficiaire VARCHAR(75), 
        --@vcLigneAdresse2_Beneficiaire VARCHAR(40), 
        --@vcLigneAdresse3_Beneficiaire VARCHAR(40), 
        @vcVille_Beneficiaire VARCHAR(30), 
        @vcProvince_Beneficiaire VARCHAR(75), 
        @cID_Pays_Beneficiaire VARCHAR(4), 
        @vcCodePostal_Beneficiaire VARCHAR(10), 
        @iTypeBoite_Beneficiaire INT,
        @vcBoite_Beneficiaire VARCHAR(20),
        @vcAdresse_TMP VARCHAR(100),

        @iID_Souscripteur INT, 
        @tiRelationshipTypeID TINYINT,

        @iID_Adresse_Souscripteur INT, 
        --@vcAppartement_Souscripteur VARCHAR(6), 
        @vcNo_Civique_Souscripteur VARCHAR(10), 
        @vcRue_Souscripteur VARCHAR(75), 
        --@vcLigneAdresse2_Souscripteur VARCHAR(40), 
        --@vcLigneAdresse3_Souscripteur VARCHAR(40), 
        @vcVille_Souscripteur VARCHAR(30), 
        @vcProvince_Souscripteur VARCHAR(75), 
        @cID_Pays_Souscripteur VARCHAR(4), 
        @vcCodePostal_Souscripteur VARCHAR(10), 
        @iTypeBoite_Souscripteur INT,
        @vcBoite_Souscripteur VARCHAR(20),
        --@vcAdresse_Souscripteur_TMP VARCHAR(100),

        @iID_Validation INT, 
        @iCode_Validation INT, 
        @vcDescription VARCHAR(300), 
        @cType CHAR(1), 

        @iResultat INT, 
        @vcTMP1 VARCHAR(100), 
        @vcTMP2 VARCHAR(100), 
        --@iCompteur INT, 
        @iTotal INT
        --,@IsDebug bit = dbo.fn_IsDebug()

    DECLARE @TB_SoldeIQEE TABLE (
                DateTraitement date,
                OperTypeID varchar(5),
                Credit_Base MONEY,
                Majoration MONEY,
                Interet MONEY
            )
    DECLARE @TB_SoldePCEE TABLE (
                DateTraitement date,
                OperTypeID varchar(5),
                mSCEE_Base MONEY DEFAULT(0),
                mSCEE_Plus MONEY DEFAULT(0),
                mSCEE_BEC MONEY DEFAULT(0),
                mSCEE_Interet MONEY DEFAULT(0)
            )

    --  Déclaration des variables
    BEGIN 
        DECLARE 
            @tiID_TypeEnregistrement TINYINT,               @iID_SousTypeEnregistrement INT,
            @dtDebutCotisation DATETIME,                    @dtFinCotisation DATETIME,
            @bTransfert_Autorise BIT = 1,                   @dtMaxCotisation DATETIME = DATEADD(DAY, -DAY(GETDATE()), GETDATE())
    
        -- Sélectionner dates applicables aux transactions
        SELECT @dtDebutCotisation = Str(@siAnnee_Fiscale, 4) + '-01-01 00:00:00',
               @dtFinCotisation = STR(@siAnnee_Fiscale, 4) + '-12-31 23:59:59'

        IF @dtFinCotisation > @dtMaxCotisation
            SET @dtFinCotisation = @dtMaxCotisation
    END

    --==============================================
    --
    -- Transfert de sous type 03 - Fiduciaire cédant et cessionnaire (transfert interne)
    --
    --==============================================

    -- Initialiser le sous type de transaction
    SELECT @iID_Sous_Type = iID_Sous_Type
      FROM dbo.tblIQEE_SousTypeEnregistrement ST
           JOIN dbo.tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = ST.tiID_Type_Enregistrement
     WHERE TE.cCode_Type_Enregistrement = '04'
       AND ST.cCode_Sous_Type = '03'

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

    -- Curseur des validations
    IF OBJECT_ID('tempdb..#TB_Validation_04_03') IS NOT NULL
        DROP TABLE #TB_Validation_04_03

    -- Sélectionner les validations à faire pour le sous type de transaction
    SELECT V.iID_Validation, V.iCode_Validation, V.vcDescription_Parametrable as vcDescription, V.cType
      INTO #TB_Validation_04_03
      FROM dbo.tblIQEE_Validations V
           JOIN dbo.tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = V.tiID_Type_Enregistrement
                                                  AND TE.cCode_Type_Enregistrement = '04'
           JOIN dbo.tblIQEE_SousTypeEnregistrement ST ON ST.iID_Sous_Type = V.iID_Sous_Type
                                                     AND ST.cCode_Sous_Type = '03'
     WHERE V.bValidation_Speciale = 0
       AND V.bActif = 1
       AND ( @cCode_Portee = 'T'
             OR (@cCode_Portee = 'A' AND V.cType = 'E')
             OR (@cCode_Portee = 'I' AND V.bCorrection_Possible = 1)
           )

    IF OBJECT_ID('tempdb..#TB_Transfert_04_03') IS NOT NULL
        DROP TABLE #TB_Transfert_04_03

    CREATE TABLE #TB_Transfert_04_03 (
                    iID_Convention_Source int NOT NULL,
                    iID_Convention_Destination int NOT NULL, 
                    iID_Unite int NULL,
                    OperTypeID    varchar(5) NOT NULL, 
                    DateTraitement datetime NOT NULL, 
                    OperID int NOT NULL, 
                    OperID_RIO int NULL, 
                    OperID_TIO int NULL, 
                    --MontantCotisation money NULL, 
                    SoldeIQEE money NOT NULL,
                    SoldePCEE money NOT NULL,
                    Row_Num int
                )

    -- Identifier et sélectionner les transferts RIO
    ;WITH CTE_Oper as ( 
        SELECT DISTINCT RIO.iID_Convention_Source, RIO.iID_Convention_Destination, RIO.iID_Unite_Source, 
               O.OperID, O.OperDate, O.OperTypeID, RIO.iID_Operation_RIO
          FROM dbo.Un_Oper O
               JOIN dbo.tblOPER_OperationsRIO RIO ON RIO.iID_Oper_RIO = O.OperID
               JOIN #TB_ListeConvention X ON X.ConventionID = RIO.iID_Convention_Source AND X.dtReconnue_RQ IS NOT NULL
               LEFT JOIN (
                            SELECT OC.OperSourceID, OC.OperID
                              FROM dbo.Un_OperCancelation OC
                                   JOIN dbo.Un_Oper O ON O.OperID = OC.OperID
                             WHERE O.OperDate <= @dtFinCotisation
                         ) OC ON OC.OperSourceID = O.OperID OR OC.OperID = O.OperID
         WHERE O.OperDate Between @dtDebutCotisation and @dtFinCotisation
           AND O.OperTypeID = 'RIO' 
           --AND RIO.dtDate_Enregistrement between @dtDebutCotisation and @dtFinCotisation
           AND (RIO.bRIO_Annulee = 0 AND RIO.bRIO_QuiAnnule = 0)
           AND (OC.OperSourceID IS NULL AND OC.OperID IS NULL)
        )
    INSERT INTO #TB_Transfert_04_03 (iID_Convention_Source, iID_Convention_Destination, iID_Unite, OperTypeID, DateTraitement, OperID, OperID_RIO, OperID_TIO, SoldeIQEE, SoldePCEE, Row_Num)
    SELECT O.iID_Convention_Source, O.iID_Convention_Destination, O.iID_Unite_Source, O.OperTypeID, O.OperDate as dtDateTraitement, 
           O.OperID, O.iID_Operation_RIO as iID_RIO, NULL as iID_TIO,
           --MontantCotisation = -1 * IsNull(Ct.Cotisation + Ct.Fee, 0),
           SoldeIQEE = -1 * IsNull(IQEE.Solde, 0),
           SoldePCEE = -1 * IsNull(PCEE.Solde, 0),
           Row_Num = Row_Number() OVER (PARTITION BY O.iID_Convention_Source, O.OperDate, O.iID_Convention_Destination ORDER BY O.OperDate DESC, O.OperID)
           --,Row_Num = Row_Number() OVER (PARTITION BY O.iID_Convention_Source ORDER BY O.OperDate DESC, O.OperID)
      FROM CTE_Oper O
           LEFT JOIN (
                SELECT ConventionID, OperID, Sum(ConventionOperAmount) as Solde
                  FROM dbo.Un_ConventionOper 
                 WHERE ConventionOperTypeID IN ('MMQ', 'CBQ')
                 GROUP BY ConventionID, OperID 
                HAVING Sum(ConventionOperAmount) <> 0
           ) IQEE ON IQEE.ConventionID = O.iID_Convention_Source
                 AND IQEE.OperID = O.OperID
           LEFT JOIN (
                SELECT ConventionID, OperID, Sum(fCESG + fACESG + fCLB) as Solde
                  FROM dbo.Un_CESP
                 GROUP BY ConventionID, OperID
                HAVING Sum(fCESG + fACESG + fCLB) <> 0
           ) PCEE ON PCEE.ConventionID = O.iID_Convention_Source
                 AND PCEE.OperID = O.OperID
     --ORDER BY O.ConventionID, O.Row_Num DESC

    -- Identifier et sélectionner les transferts TIO
    ;WITH CTE_ConvOper as (
        SELECT DISTINCT CO.OperID, O.OperTypeID, O.OperDate, CO.ConventionID
          FROM dbo.Un_Oper O
               JOIN dbo.Un_ConventionOper CO ON CO.OperID = O.OperID
               LEFT JOIN (
                    SELECT OC.OperSourceID, OC.OperID
                      FROM dbo.Un_OperCancelation OC
                           JOIN dbo.Un_Oper O ON O.OperID = OC.OperID
                     WHERE O.OperDate <= @dtFinCotisation
               ) OC ON OC.OperSourceID = O.OperID OR OC.OperID = O.OperID
         WHERE O.OperDate Between @dtDebutCotisation and @dtFinCotisation
           AND O.OperTypeID IN ('OUT', 'TIN')
           AND CO.ConventionOperTypeID IN ('CBQ', 'MMQ')
           AND CO.ConventionOperAmount <> 0
    ),
    CTE_Oper as (
        SELECT X.iTIOID, S.ConventionID as iID_Source, D.ConventionID as iID_Destination, S.OperTypeID, S.OperDate, S.OperID
          FROM dbo.Un_TIO X
               JOIN CTE_ConvOper S ON S.OperID = X.iOUTOperID
               JOIN CTE_ConvOper D ON D.OperID = X.iTINOperID
               JOIN #TB_ListeConvention TB ON TB.ConventionID = S.ConventionID
    )
    INSERT INTO #TB_Transfert_04_03 (iID_Convention_Source, iID_Convention_Destination, iID_Unite, OperTypeID, DateTraitement, OperID, OperID_RIO, OperID_TIO, SoldeIQEE, SoldePCEE, Row_Num)
    SELECT O.iID_Source, O.iID_Destination, Ct.UnitID, O.OperTypeID, O.OperDate as dtDateTraitement, 
           O.OperID, NULL as iID_RIO, iTIOID as iID_TIO,
           SoldeIQEE = -1 * IsNull(IQEE.Solde, 0),
           SoldePCEE = -1 * IsNull(PCEE.Solde, 0)
           ,Row_Num = Row_Number() OVER (PARTITION BY O.iID_Source, O.OperDate, O.iID_Destination ORDER BY O.OperDate DESC, O.OperID)
      FROM CTE_Oper O
           LEFT JOIN dbo.Un_Cotisation Ct ON Ct.OperID = O.OperID
           LEFT JOIN (
                SELECT ConventionID, OperID, Sum(ConventionOperAmount) as Solde
                  FROM dbo.Un_ConventionOper 
                 WHERE ConventionOperTypeID IN ('MMQ', 'CBQ')
                 GROUP BY ConventionID, OperID 
                HAVING Sum(ConventionOperAmount) <> 0
           ) IQEE ON IQEE.ConventionID = O.iID_Source
                 AND IQEE.OperID = O.OperID
           LEFT JOIN (
                SELECT ConventionID, OperID, Sum(fCESG + fACESG + fCLB) as Solde
                  FROM dbo.Un_CESP
                 GROUP BY ConventionID, OperID
                HAVING Sum(fCESG + fACESG + fCLB) <> 0
           ) PCEE ON PCEE.ConventionID = O.iID_Source
                 AND PCEE.OperID = O.OperID
           JOIN dbo.fntIQEE_ConventionConnueRQ_PourTous(NULL, @siAnnee_Fiscale) RQ ON RQ.iID_Convention = O.iID_Source

    IF dbo.fn_IsDebug() <> 0 BEGIN
        SELECT @iTotal = COUNT(*) FROM #TB_Transfert_04_03 WHERE Row_Num = 1
        PRINT Str(@iTotal) + ' T04-03 à traiter'
    END

    IF NOT EXISTS(SELECT TOP 1 * FROM #TB_Transfert_04_03)
       RETURN

    ;WITH CTE_OperTypeExclus as (
        SELECT val as OperTypeID_Exclus
          FROM dbo.fn_Mo_StringTable((SELECT dbo.fnOPER_ObtenirTypesOperationCategorie('OPER_IQEE_BLOQUANT_TRANSFERT'))) X
    )
    SELECT DISTINCT U.ConventionID, O.OperTypeID, O.OperDate
      INTO #TB_OperType_Exlcus_04_03
      FROM #TB_Transfert_04_03 TB
           JOIN dbo.Un_Unit U ON U.ConventionID = TB.iID_Convention_Source
           JOIN dbo.Un_Cotisation Ct ON Ct.UnitID = U.UnitID
           JOIN dbo.Un_Oper O ON O.OperID = Ct.OperID
           JOIN CTE_OperTypeExclus E ON E.OperTypeID_Exclus = O.OperTypeID
     WHERE Year(O.OperDate) < 2016

    ---- Retrouve les bénéficiaires des conventions concernés
    --SELECT B.*
    --  INTO #TB_Beneficiary_04_03
    --  FROM #TB_Transfert_04_03 TB
    --       JOIN dbo.fntCONV_ObtenirBeneficiaireParConventionEnDate(@dtFinCotisation, NULL) B ON B.iID_Convention = TB.iID_Convention_Source

    -- Boucler parmis les transferts RIO de l'année fiscale
    SET @iID_Convention_Src = 0
    WHILE EXISTS(SELECT TOP 1 * FROM #TB_Transfert_04_03 WHERE iID_Convention_Source > @iID_Convention_Src And SoldeIQEE <> 0)
    BEGIN
        SELECT @iID_Convention_Src = Min(iID_Convention_Source) 
            FROM #TB_Transfert_04_03 
            WHERE iID_Convention_Source > @iID_Convention_Src

        SELECT @vcNo_Convention_Src = SUBSTRING(ConventionNo, 1, 15),
               @iID_Souscripteur = C.SubscriberID,
               @tiRelationshipTypeID = C.tiRelationshipTypeID
          FROM dbo.Un_Convention C
         WHERE ConventionID = @iID_Convention_Src

        SELECT @dtDate_Debut_Convention = dbo.fnIQEE_ObtenirDateEnregistrementRQ(@iID_Convention_Src)

        IF dbo.fn_IsDebug() <> 0 BEGIN
            PRINT '@iID_Convention          = ' + STR(ISNULL(@iID_Convention_Src, 0))
            PRINT '@vcNo_Convention_Src     = ' + @vcNo_Convention_Src
            PRINT '@dtDate_Debut_Convention = ' + Convert(varchar, @dtDate_Debut_Convention, 120)
        END

        DELETE FROM @TB_SoldeIQEE
        DELETE FROM @TB_SoldePCEE

        --SELECT * FROM #TB_Transfert_04_03 WHERE iID_Convention_Source = @iID_Convention_Src

        SELECT @dtDate_TransfertOld = Max(O.OperDate)
          FROM dbo.Un_ConventionOper C
               JOIN dbo.Un_Oper O ON C.OperID = O.OperID
         WHERE C.ConventionID = @iID_Convention_Src
           AND C.ConventionOperTypeID IN ('MMQ', 'CBQ')
           AND C.ConventionOperAmount <> 0
           AND O.OperTypeID IN ('RIO', 'TIN', 'OUT')
           AND O.OperDate < @dtDebutCotisation
           --AND Year(O.OperDate) >= 2016

        SET @dtDate_TransfertOld = IsNull(@dtDate_TransfertOld, 0)

        WHILE EXISTS(SELECT TOP 1 * FROM #TB_Transfert_04_03 WHERE iID_Convention_Source = @iID_Convention_Src 
                                                               And DateTraitement > @dtDate_TransfertOld
                                                               And SoldeIQEE <> 0)
        BEGIN
            SELECT @dtDate_Transfert = Min(DateTraitement) 
                FROM #TB_Transfert_04_03 
                WHERE iID_Convention_Source = @iID_Convention_Src
                  AND DateTraitement > @dtDate_TransfertOld
                  And SoldeIQEE <> 0
            
            SELECT @iID_Convention_Dest = iID_Convention_Destination,
                   @vcType_Operation = OperTypeID, 
                   @iID_Operation = OperID, 
                   @iID_TIO = OperID_TIO, 
                   @iID_RIO = OperID_RIO
              FROM #TB_Transfert_04_03
             WHERE iID_Convention_Source = @iID_Convention_Src
               AND DateTraitement = @dtDate_Transfert
               AND Row_Num = 1

            IF EXISTS(SELECT TOP 1 * FROM #TB_OperType_Exlcus_04_03 WHERE ConventionID = @iID_Convention_Src) -- and OperDate < @dtDate_TransfertOld)
            BEGIN
                SELECT @iID_Validation = iID_Validation, 
                       @vcDescription = vcDescription_Parametrable
                  FROM dbo.tblIQEE_Validations V
                 WHERE iCode_Validation = 1719

                DECLARE @vcTmp varchar(1000) = Replace(@vcDescription, '%vcNo_Convention%', @vcNo_Convention_Src)

                EXECUTE @iResultat = dbo.psIQEE_AjouterRejet @iID_Fichier_IQEE, @iID_Convention_Src, 
                                                             @iID_Validation, @vcTmp, 
                                                             NULL, NULL, @iID_Operation, NULL, NULL

                GOTO FIN_VALIDATION
            END

            SELECT @vcNo_Convention_Dest = SUBSTRING(ConventionNo, 1, 15)
              FROM dbo.Un_Convention C
             WHERE ConventionID = @iID_Convention_Dest

            IF dbo.fn_IsDebug() <> 0 BEGIN
                PRINT '-----------------------------------------'
                PRINT '@dtDate_Transfert        = ' + Convert(varchar, @dtDate_Transfert, 120)
                PRINT '@dtDate_TransfertOld     = ' + Convert(varchar, @dtDate_TransfertOld, 120)
                PRINT '@vcNo_Convention_Dest    = ' + @vcNo_Convention_Dest
                PRINT '@iID_Operation           = ' + STR(ISNULL(@iID_Operation, 0))
                PRINT '@vcType_Operation        = ' + ISNULL(@vcType_Operation, 'NULL')
                PRINT '@iID_RIO                 = ' + STR(ISNULL(@iID_RIO, 0))
                PRINT '@iID_TIO                 = ' + STR(ISNULL(@iID_TIO, 0))
            END

            -------------------------------------------------------------
            -- Récupère l'information requise à propos du bénéficiaire --
            -------------------------------------------------------------

            -- Rechercher les informations du bénéficiaire au moment du transfert
            SELECT @iID_Beneficiaire = iID_Beneficiaire,
                   @vcNAS_Beneficiaire = NAS, 
                   @vcNom_Beneficiaire = LTRIM(Nom), 
                   @vcPrenom_Beneficiaire = LTRIM(Prenom), 
                   @dtDate_Naissance_Beneficiaire = DateNaissance, 
                   @cSexe_Beneficiaire = Sexe
              FROM dbo.fntCONV_ObtenirBeneficiaireParConventionEnDate(@dtDate_Transfert, @iID_Convention_Src) --#TB_Beneficiary_04_03

            SET @vcNom_Benef_Long = dbo.fn_Mo_FormatHumanName(@vcNom_Beneficiaire, '', @vcPrenom_Beneficiaire, '', '', 0)

            --    Récupère l'adresse du bénéficiaire à la fin de cette année fiscale
            SELECT @iID_Adresse_Beneficiaire = A.iID_Adresse,
                   --@vcAppartement_Beneficiaire = A.vcUnite, 
                   @vcNo_Civique_Beneficiaire = A.vcNumero_Civique, 
                   @vcRue_Beneficiaire = A.vcNom_Rue, 
                   --@vcLigneAdresse2_Beneficiaire = A.vcInternationale2, 
                   --@vcLigneAdresse3_Beneficiaire = A.vcInternationale3,
                   @vcVille_Beneficiaire = A.vcVille,
                   @vcProvince_Beneficiaire = IsNull(S.StateCode, LEFT(a.vcProvince, 2)),
                   @cID_Pays_Beneficiaire = A.cID_Pays,
                   @vcCodePostal_Beneficiaire = A.vcCodePostal,
                   @iTypeBoite_Beneficiaire = A.iID_TypeBoite,
                   @vcBoite_Beneficiaire = A.vcBoite
              FROM dbo.fntGENE_ObtenirAdresseEnDate(@iID_Beneficiaire, 1, @dtDate_Transfert, 0) A
                   LEFT JOIN dbo.Mo_State S ON S.StateID = A.iID_Province

            -- Séparer les éléments de l'adresse du beneficiaire
            SET @vcAdresse_TMP = @vcRue_Beneficiaire
            IF @vcNo_Civique_Beneficiaire  IS NULL
            BEGIN
                SELECT @vcNo_Civique_Beneficiaire = vcNo_Civique, 
                       @vcRue_Beneficiaire = 
                            CASE @iTypeBoite_Beneficiaire 
                                -- Ancien format des adresses
                                WHEN 0 THEN LTRIM( ISNULL(vcRue, '') + 
                                                   CASE WHEN vcCase_Postale IS NULL THEN '' 
                                                        ELSE ' CP '+vcCase_Postale 
                                                   END
                                                 )
                                -- Nouveau format des adresses selon le mode de livraison (Case Postale, Route Rurale)
                                WHEN 1 THEN @vcAdresse_TMP + ' CP ' + @vcBoite_Beneficiaire
                                WHEN 2 THEN @vcAdresse_TMP + ' RR ' + @vcBoite_Beneficiaire
                                ELSE vcRue
                            END
                       --,@vcAppartement_Beneficiaire = vcNo_Appartement
                  FROM dbo.fntGENE_ObtenirElementsAdresse(@vcAdresse_TMP, 0)
            END

            DELETE FROM @TB_SoldeIQEE
            INSERT INTO @TB_SoldeIQEE (Credit_Base, Majoration, Interet, OperTypeID)
            SELECT T1.Credit_Base - IsNull(T2.Credit_Base, 0), 
                   T1.Majoration - IsNull(T2.Majoration, 0), 
                   T1.Interet - IsNull(T2.Interet, 0), 
                   T1.OperTypeID
              FROM dbo.fntIQEE_CalculerSoldeIQEE(@iID_Convention_Src, @dtDate_Transfert, 1) T1
                   LEFT JOIN dbo.fntIQEE_CalculerSoldeIQEE(@iID_Convention_Src, @dtDate_TransfertOld, 1) T2 ON T1.OperTypeID = T2.OperTypeID

            DELETE FROM @TB_SoldePCEE
            INSERT INTO @TB_SoldePCEE (mSCEE_Base, mSCEE_Plus, mSCEE_BEC, mSCEE_Interet, OperTypeID)
            SELECT T1.mSCEE_Base - IsNull(T2.mSCEE_Base, 0), 
                   T1.mSCEE_Plus - IsNull(T2.mSCEE_Plus, 0), 
                   T1.mSCEE_BEC - IsNull(T2.mSCEE_BEC, 0), 
                   T1.mSCEE_Interet - IsNull(T2.mSCEE_Interet, 0), 
                   T1.OperTypeID
              FROM dbo.fntPCEE_CalculerSoldeSCEE(@iID_Convention_Src, @dtDate_Transfert, 1) T1
                   LEFT JOIN dbo.fntPCEE_CalculerSoldeSCEE(@iID_Convention_Src, @dtDate_TransfertOld, 1) T2 ON T1.OperTypeID = T2.OperTypeID

            --SELECT T1.*, T2.*
            --  FROM dbo.fntPCEE_CalculerSoldeSCEE(@iID_Convention_Src, @dtDate_Transfert, 1) T1
            --       LEFT JOIN dbo.fntPCEE_CalculerSoldeSCEE(@iID_Convention_Src, @dtDate_TransfertOld, 1) T2 ON T1.OperTypeID = T2.OperTypeID

            IF dbo.fn_IsDebug() <> 0 BEGIN
                select * from @TB_SoldeIQEE
                Select * from @TB_SoldePCEE
                select * from #TB_Transfert_04_03 WHERE iID_Convention_Source = @iID_Convention_Src
            END

            -------------------------------------------------
            -- Calcul le montant total propre au transfert --
            -------------------------------------------------

            SELECT @mTotal_Cotisation = -Sum(CASE O.OperTypeID WHEN 'TFR' THEN 0
                                                              ELSE Ct.Cotisation + Ct.Fee
                                            END),
                   @mTotal_Frais = Sum(CASE O.OperTypeID WHEN 'TFR' THEN Ct.Cotisation + Ct.Fee
                                                              ELSE 0
                                            END)
              FROM dbo.Un_Unit U
                   JOIN dbo.Un_Cotisation Ct ON Ct.UnitID = U.UnitID
                   JOIN dbo.Un_Oper O ON O.OperID = Ct.OperID
                   LEFT JOIN (
                                SELECT OC.OperSourceID, OC.OperID
                                  FROM dbo.Un_OperCancelation OC
                                       JOIN dbo.Un_Oper O ON O.OperID = OC.OperID
                                 WHERE O.OperDate <= @dtDate_Transfert-1
                             ) OC ON OC.OperSourceID = O.OperID OR OC.OperID = O.OperID
             WHERE U.ConventionID = @iID_Convention_Src
               AND O.OperDate Between @dtDate_TransfertOld + 1 And @dtDate_Transfert
               AND (O.OperTypeID = @vcType_Operation OR O.OperTypeID = 'TFR')
               AND OC.OperID IS NULL

            SET @mTotal_Cotisation = IsNull(@mTotal_Cotisation, 0)
            SET @mTotal_Frais = IsNull(@mTotal_Frais, 0)

            IF EXISTS(SELECT TOP 1 * FROM @TB_SoldeIQEE WHERE OperTypeID = @vcType_Operation)
            SELECT @mCreditBase_IQEE = -1 * IsNull(Credit_Base, 0),
                   @mMajore_IQEE = -1 * IsNull(Majoration, 0),
                   @mInteret_IQEE = -1 * IsNull(Interet, 0)
              FROM @TB_SoldeIQEE
             WHERE OperTypeID = @vcType_Operation
            ELSE
                SELECT @mCreditBase_IQEE = 0, @mMajore_IQEE = 0, @mInteret_IQEE = 0

            IF EXISTS(SELECT TOP 1 * FROM @TB_SoldePCEE WHERE OperTypeID = @vcType_Operation)
                SELECT @mSolde_PCEE = -1 * sum(IsNull(mSCEE_Base, 0) + IsNull(mSCEE_PLUS, 0) + IsNull(mSCEE_BEC, 0) + IsNull(mSCEE_Interet, 0))
                  FROM @TB_SoldePCEE
                 WHERE OperTypeID = @vcType_Operation
            ELSE
                SELECT @mSolde_PCEE = 0

            SET @mSoldeReel_IQEE = @mCreditBase_IQEE + @mMajore_IQEE
        
            SET @mTotal_Transfert = @mTotal_Cotisation + (@mCreditBase_IQEE + @mMajore_IQEE + @mInteret_IQEE) + @mSolde_PCEE       

            IF dbo.fn_IsDebug() <> 0 BEGIN
                PRINT '-----------------------------------------'
                PRINT '   @mTotal_Cotisation             = ' + STR(@mTotal_Cotisation, 10, 2)
                PRINT '   @mTotal_FraisPerdu             = ' + STR(@mTotal_Frais, 10, 2)
                PRINT '   @mCreditBase_IQEE              = ' + STR(@mCreditBase_IQEE, 10, 2)
                PRINT '   @mMajore_IQEE                  = ' + STR(@mMajore_IQEE, 10, 2)
                PRINT '   @mInteret_IQEE                 = ' + STR(@mInteret_IQEE, 10, 2)
                PRINT '   @mTotal_IQEE                   = ' + STR(@mCreditBase_IQEE + @mMajore_IQEE + @mInteret_IQEE, 10, 2)
                PRINT '   @mTotal_PCEE                   = ' + STR(@mSolde_PCEE, 10, 2)
                PRINT '   @mTotal_Transfert              = ' + STR(@mTotal_Transfert, 10, 2)
            END

            -----------------------------------------------------------------------------
            -- Calcul le total de cotisation actuel, puis avant le 20 fév 2007 & après --
            -----------------------------------------------------------------------------

            -- Calculer les montants retirés dans l'année fiscale
            --SELECT O.OperDate, O.OperTypeID, Ct.Cotisation, Ct.Fee
            --  FROM dbo.Un_Unit U
            --       JOIN dbo.Un_Cotisation Ct ON Ct.UnitID = U.UnitID
            --       JOIN dbo.Un_Oper O ON O.OperID = Ct.OperID
            --       LEFT JOIN (
            --                    SELECT OC.OperSourceID, OC.OperID
            --                      FROM dbo.Un_OperCancelation OC
            --                           JOIN dbo.Un_Oper O ON O.OperID = OC.OperID
            --                     WHERE O.OperDate <= @dtDate_Transfert-1
            --                 ) OC ON OC.OperSourceID = O.OperID OR OC.OperID = O.OperID
            -- WHERE U.ConventionID = @iID_Convention_Src
            --   --AND O.OperDate < @dtDate_Transfert
            --   --AND O.OperTypeID <> @vcType_Operation
            --   AND (
            --        (O.OperDate <= @dtDate_TransfertOld)
            --        OR
            --        (O.OperDate <= @dtDate_Transfert And O.OperTypeID <> @vcType_Operation)
            --       )
            --   AND OC.OperID IS NULL

            DECLARE @mCotisations_Apres_Debut_IQEE money, 
                    @mCotisations_Restante_IQEE money 
            SELECT @mCotisations_Avant_Debut_IQEE  = Sum(CASE WHEN O.OperTypeID <> @vcType_Operation and O.OperDate < '2007-02-21' THEN Ct.Cotisation + Ct.Fee ELSE 0 END),
                   @mCotisations_Apres_Debut_IQEE  = Sum(CASE WHEN O.OperTypeID <> @vcType_Operation and O.OperDate > '2007-02-20' THEN Ct.Cotisation + Ct.Fee ELSE 0 END),
                   @mCotisations_Restante_IQEE = Sum(CASE WHEN O.OperTypeID <> @vcType_Operation and O.OperDate > @dtDate_TransfertOld THEN Ct.Cotisation + Ct.Fee ELSE 0 END)
              FROM dbo.Un_Unit U
                   JOIN dbo.Un_Cotisation Ct ON Ct.UnitID = U.UnitID
                   JOIN ( SELECT OperID, OperTypeID, Cast(OperDate as date) as OperDate FROM dbo.Un_Oper
                        ) O ON O.OperID = Ct.OperID
                   LEFT JOIN (
                                SELECT OC.OperSourceID, OC.OperID
                                  FROM dbo.Un_OperCancelation OC
                                       JOIN dbo.Un_Oper O ON O.OperID = OC.OperID
                                 WHERE Cast(O.OperDate as date) <= @dtDate_Transfert-1
                             ) OC ON OC.OperSourceID = O.OperID OR OC.OperID = O.OperID
             WHERE U.ConventionID = @iID_Convention_Src
               --AND O.OperDate < @dtDate_Transfert
               --AND O.OperTypeID <> @vcType_Operation
               AND (
                    (O.OperDate <= @dtDate_TransfertOld)
                    OR
                    (O.OperDate Between @dtDate_TransfertOld + 1 And @dtDate_Transfert 
                        And (O.OperTypeID <> @vcType_Operation AND O.OperTypeID <> 'TFR')
                    )
                   )
               AND OC.OperID IS NULL

            IF dbo.fn_IsDebug() <> 0 BEGIN
                PRINT '   -----------------------------------------'
                PRINT '   @mCotisations_Avant_Fev_2007   = ' + STR(@mCotisations_Avant_Debut_IQEE, 10, 2)
                PRINT '   @mCotisations_Apres_Fev_2007   = ' + STR(@mCotisations_Apres_Debut_IQEE, 10, 2)
                PRINT '   @mCotisations_Non_Transfées    = ' + STR(@mCotisations_Restante_IQEE, 10, 2)
            END

            SET @mTotal_Cotisation = 0
            SELECT @mTotal_Cotisation = Sum(CASE O.OperTypeID WHEN 'TFR' THEN 0
                                                              ELSE Ct.Cotisation + Ct.Fee
                                            END),
                   @mTotal_Frais = Sum(CASE O.OperTypeID WHEN 'TFR' THEN Ct.Cotisation + Ct.Fee
                                                              ELSE 0
                                            END)
              FROM dbo.Un_Unit U
                   JOIN dbo.Un_Cotisation Ct ON Ct.UnitID = U.UnitID
                   JOIN dbo.Un_Oper O ON O.OperID = Ct.OperID
                   LEFT JOIN (
                                SELECT OC.OperSourceID, OC.OperID
                                  FROM dbo.Un_OperCancelation OC
                                       JOIN dbo.Un_Oper O ON O.OperID = OC.OperID
                                 WHERE O.OperDate <= @dtDate_Transfert-1
                             ) OC ON OC.OperSourceID = O.OperID OR OC.OperID = O.OperID
             WHERE U.ConventionID = @iID_Convention_Src
               AND (
                    (O.OperDate <= @dtDate_TransfertOld)
                    OR
                    --(O.OperDate <= @dtDate_Transfert And O.OperTypeID <> @vcType_Operation And O.OperTypeID <> 'TFR')
                    --OR
                    (O.OperDate Between @dtDate_TransfertOld + 1 And @dtDate_Transfert And O.OperTypeID <> @vcType_Operation)
                    --(O.OperDate Between @dtDate_TransfertOld + 1 And @dtDate_Transfert And O.OperTypeID = 'TFR')
                   )
               AND OC.OperID IS NULL

            ------------------------------------------------------------------
            -- Calcul les soldes restants du IQEE & PCEE avant le transfert --
            ------------------------------------------------------------------

            SELECT @mCreditBase_IQEE = 0, @mMajore_IQEE = 0, @mInteret_IQEE = 0
            SELECT @mCreditBase_IQEE = IsNull(Sum(Credit_Base), 0),
                   @mMajore_IQEE = IsNull(Sum(Majoration), 0),
                   @mInteret_IQEE = IsNull(Sum(Interet), 0)
              FROM @TB_SoldeIQEE
             WHERE OperTypeID <> @vcType_Operation

            SELECT @mSolde_PCEE = sum(mSCEE_Base + mSCEE_PLUS), 
                   @mSolde_BEC = sum(mSCEE_BEC), 
                   @mInteret_PCEE = sum(mSCEE_Interet)
              FROM @TB_SoldePCEE
             WHERE OperTypeID <> @vcType_Operation

            SET @Solde_Subvention = @mCreditBase_IQEE + @mMajore_IQEE + @mInteret_IQEE + @mSolde_PCEE + @mSolde_BEC + @mInteret_PCEE
             
            IF dbo.fn_IsDebug() <> 0 BEGIN
                PRINT '   --------------------------------------------'
                PRINT '   @mTotal_Cotisation             = ' + STR(@mTotal_Cotisation, 10, 2)
                PRINT '   @mTotal_FraisPerdu             = ' + STR(@mTotal_Frais, 10, 2)
                PRINT '   @mSolde_Subvention             = ' + STR(@Solde_Subvention, 10, 2)
                PRINT '   @mTotal_Transfert              = ' + STR(@mTotal_Transfert, 10, 2)
                PRINT '   @mCreditBase_IQEE              = ' + STR(@mCreditBase_IQEE, 10, 2)
                PRINT '   @mMajore_IQEE                  = ' + STR(@mMajore_IQEE, 10, 2)
                PRINT '   @mInteret_IQEE                 = ' + STR(@mInteret_IQEE, 10, 2)
                PRINT '   @mSolde_PCEE                   = ' + STR(@mSolde_PCEE, 10, 2)
                PRINT '   @mSolde_BEC                    = ' + STR(@mSolde_BEC, 10, 2)
                PRINT '   @mInteret_PCEE                 = ' + STR(@mInteret_PCEE, 10, 2)
            END

            SET @mJuste_Valeur_Marchande = @mTotal_Cotisation + @mTotal_Frais + @Solde_Subvention

            SELECT @mCotisations_Donne_Droit_IQEE = Solde_Ayant_Droit_IQEE
                   --,@mTotal_Cotisation = Solde_Cotisation
              FROM dbo.fntIQEE_CotisationsEtAyantEuDroit_ParConvention(@iID_Convention_Src, @siAnnee_Fiscale, @dtDate_Transfert)

            IF @mTotal_Cotisation > @mCotisations_Donne_Droit_IQEE
                SET @mCotisations_Sans_Droit_IQEE = @mTotal_Cotisation - @mCotisations_Donne_Droit_IQEE
            ELSE
                SET @mCotisations_Sans_Droit_IQEE = 0

            IF dbo.fn_IsDebug() <> 0 BEGIN
                PRINT '   --------------------------------------------'
                PRINT '   @mJuste_Valeur_Marchande       = ' + STR(@mJuste_Valeur_Marchande, 10, 2)
                PRINT '   @mCotisations_Donne_Droit_IQEE = ' + STR(@mCotisations_Donne_Droit_IQEE, 10, 2)
                PRINT '   @mCotisations_Sans_Droit_IQEE  = ' + STR(@mCotisations_Sans_Droit_IQEE, 10, 2)
                PRINT '   @mCotisations_Avant_Fev_2007   = ' + STR(@mCotisations_Avant_Debut_IQEE, 10, 2)
                PRINT '   @mCotisations_Apres_Fev_2007   = ' + STR(@mCotisations_Apres_Debut_IQEE, 10, 2)
                PRINT ''
            END

            SET @bTransfert_Autorise = 0

            IF @vcType_Operation = 'RIO'
            BEGIN
                SET @bTransfert_Autorise = 1

                SELECT TOP 1 @vcNEQ = vcNEQ_GUI FROM dbo.Un_Def

                SET @vcNo_Contrat_Autre_Promoteur = @vcNo_Convention_Dest

                SELECT TOP 1
                       @iID_Autre_Promoteur = P.ExternalPromoID, 
                       @vcNEQ_Autre_Promoteur = P.vcNEQ,
                       @iID_Regime_Autre_Promoteur = EP.ExternalPlanID
                  FROM dbo.mo_Company C 
                       join dbo.Un_ExternalPromo P ON C.CompanyID = P.ExternalPromoID
                       join dbo.Un_ExternalPlan EP ON P.ExternalPromoID = EP.ExternalPromoID
                 where C.CompanyName = 'universitas'
                   and EP.ExternalPlanTypeID = 'IND'

                IF @mJuste_Valeur_Marchande < @mTotal_Transfert
                    SET @mJuste_Valeur_Marchande = @mTotal_Transfert
            END
            IF @vcType_Operation = 'OUT'
            BEGIN
                SET @bTransfert_Autorise = 1

                SELECT TOP 1
                       @vcNEQ = P.vcNEQ
                  FROM dbo.Un_TIO T
                       join dbo.Un_TIN I ON I.OperID = T.iTINOperID
                       join dbo.Un_ExternalPlan EP ON EP.ExternalPlanID = I.ExternalPlanID
                       join dbo.Un_ExternalPromo P ON P.ExternalPromoID = EP.ExternalPromoID
                       JOIN dbo.mo_Company C ON C.CompanyID = P.ExternalPromoID
                 where T.iTIOID = @iID_TIO

                SELECT TOP 1
                       @iID_Autre_Promoteur = P.ExternalPromoID, 
                       @vcNEQ_Autre_Promoteur = P.vcNEQ,
                       @iID_Regime_Autre_Promoteur = EP.ExternalPlanID,
                       @vcNo_Contrat_Autre_Promoteur = I.vcOtherConventionNo
                  FROM dbo.Un_TIO T
                       join dbo.Un_OUT I ON I.OperID = T.iOUTOperID
                       join dbo.Un_ExternalPlan EP ON EP.ExternalPlanID = I.ExternalPlanID
                       join dbo.Un_ExternalPromo P ON P.ExternalPromoID = EP.ExternalPromoID
                       JOIN dbo.mo_Company C ON C.CompanyID = P.ExternalPromoID
                 where T.iTIOID = @iID_TIO
            END

            IF dbo.fn_IsDebug() <> 0
            BEGIN
                PRINT '   --------------------------------------------'
                PRINT '   @iID_Autre_Promoteur       = ' + LTrim(Str(@iID_Autre_Promoteur, 6))
                PRINT '   @vcNEQ_Autre_Promoteur       = ' + @vcNEQ_Autre_Promoteur
                PRINT '   @iID_Regime_Autre_Promoteur  = ' + LTrim(Str(@iID_Regime_Autre_Promoteur, 6))
            END

            IF EXISTS(SELECT TOP 1 * FROM dbo.Un_Oper O
                               LEFT JOIN (
                                            SELECT OC.OperSourceID, OC.OperID
                                              FROM dbo.Un_OperCancelation OC
                                                   JOIN dbo.Un_Oper O ON O.OperID = OC.OperID
                                             WHERE O.OperDate <= @dtDate_Transfert-1
                                         ) OC ON OC.OperSourceID = O.OperID OR OC.OperID = O.OperID
                       WHERE OperTypeID = 'PRA' AND OperDate < @dtDate_Transfert)
                SET @bPRA_Deja_Verse = 1
            ELSE
                SET @bPRA_Deja_Verse = 0

            IF dbo.fn_IsDebug() <> 0
                PRINT '*******************************************'

            -----------------------------------------------------------------------------------------------------------
            -- Valider les transferts et conserver les raisons de rejet des transferts rejetés en vertu des validations
            -----------------------------------------------------------------------------------------------------------

            -- Boucler à travers les validations de l'IQÉÉ
            SET @iID_Validation = 0               
            WHILE Exists(SELECT TOP 1 * FROM #TB_Validation_04_03 WHERE iID_Validation > @iID_Validation) 
            BEGIN
                SELECT @iID_Validation = Min(iID_Validation) 
                  FROM #TB_Validation_04_03 
                 WHERE iID_Validation > @iID_Validation

                SELECT @iCode_Validation = iCode_Validation, 
                       @vcDescription = vcDescription, 
                       @cType = cType
                  FROM #TB_Validation_04_03 
                 WHERE iID_Validation = @iID_Validation

                -- Validation #1701
                IF @iCode_Validation = 1701 
                    AND EXISTS(
                        SELECT *
                          FROM tblIQEE_Transferts T
                               JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = T.iID_Fichier_IQEE 
                         WHERE T.iID_Convention = @iID_Convention_Src
                           AND T.iID_Operation = @iID_Operation
                           AND T.iID_Sous_Type = @iID_Sous_Type
                           AND T.cStatut_Reponse = 'R'
                    )
                    BEGIN
                        EXECUTE @iResultat = dbo.psIQEE_AjouterRejet @iID_Fichier_IQEE, @iID_Convention_Src, 
                                                @iID_Validation, @vcDescription, NULL, NULL, 
                                                @iID_Operation, NULL, NULL
                        IF @iResultat <= 0
                            GOTO ERREUR_VALIDATION
                        IF @bArretPremiereErreur = 1 AND @cType = 'E'
                            GOTO FIN_VALIDATION
                    END

                -- Validation #1702
                IF @iCode_Validation = 1702 
                    AND EXISTS(
                        SELECT *
                          FROM tblIQEE_Transferts T
                               JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = T.iID_Fichier_IQEE 
                         WHERE T.iID_Convention = @iID_Convention_Src
                           AND T.iID_Operation = @iID_Operation
                           AND T.iID_Sous_Type = @iID_Sous_Type
                           AND T.cStatut_Reponse = 'A'
                           AND T.tiCode_Version <> 1
                    )
                    BEGIN
                        EXECUTE @iResultat = dbo.psIQEE_AjouterRejet @iID_Fichier_IQEE, @iID_Convention_Src, 
                                                @iID_Validation, @vcDescription, NULL, NULL, 
                                                @iID_Operation, NULL, NULL
                        IF @iResultat <= 0
                            GOTO ERREUR_VALIDATION
                        IF @bArretPremiereErreur = 1 AND @cType = 'E'
                            GOTO FIN_VALIDATION
                    END

                -- Validation #1703
                IF @iCode_Validation = 1703 
                    AND EXISTS (
                        SELECT *
                          FROM tblIQEE_Transferts T
                               JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = T.iID_Fichier_IQEE 
                               JOIN dbo.tblIQEE_Erreurs E ON E.iID_Enregistrement = T.iID_Transfert
                               JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = E.tiID_Type_Enregistrement
                               JOIN tblIQEE_StatutsErreur SE ON SE.tiID_Statuts_Erreur = E.tiID_Statuts_Erreur 
                                                            AND SE.vcCode_Statut = 'ATR'
                         WHERE T.iID_Convention = @iID_Convention_Src
                           AND T.iID_Operation = @iID_Operation
                           AND T.iID_Sous_Type = @iID_Sous_Type
                           AND T.cStatut_Reponse = 'E'
                           AND TE.cCode_Type_Enregistrement = '04'
                    )
                    BEGIN
                        EXECUTE @iResultat = dbo.psIQEE_AjouterRejet @iID_Fichier_IQEE, @iID_Convention_Src, 
                                                @iID_Validation, @vcDescription, NULL, NULL, 
                                                @iID_Operation, NULL, NULL
                        IF @iResultat <= 0
                            GOTO ERREUR_VALIDATION
                        IF @bArretPremiereErreur = 1 AND @cType = 'E'
                            GOTO FIN_VALIDATION
                    END

                -- Validation #1704
                IF @iCode_Validation = 1704 
                    AND dbo.FN_CRI_CheckSin(@vcNAS_Beneficiaire, 0) = 0
                    BEGIN
                        SET @vcDescription = REPLACE(@vcDescription, '%vcBeneficiaire%', @vcNom_Benef_Long)
                        EXECUTE @iResultat = dbo.psIQEE_AjouterRejet @iID_Fichier_IQEE, @iID_Convention_Src, 
                                                                     @iID_Validation, @vcDescription, NULL, @vcNAS_Beneficiaire, 
                                                                     @iID_Operation, @iID_Beneficiaire, NULL
                        IF @iResultat <= 0
                            GOTO ERREUR_VALIDATION
                        IF @bArretPremiereErreur = 1 AND @cType = 'E'
                            GOTO FIN_VALIDATION
                    END

                -- Validation #1705
                IF @iCode_Validation = 1705 
                    AND IsNull(@vcNom_Beneficiaire, '') = ''
                    BEGIN
                        EXECUTE @iResultat = dbo.psIQEE_AjouterRejet @iID_Fichier_IQEE, @iID_Convention_Src, 
                                                                     @iID_Validation, @vcDescription, NULL, NULL, 
                                                                     @iID_Operation, @iID_Beneficiaire, NULL
                        IF @iResultat <= 0
                            GOTO ERREUR_VALIDATION
                        IF @bArretPremiereErreur = 1 AND @cType = 'E'
                            GOTO FIN_VALIDATION
                    END

                -- Validation #1706
                IF @iCode_Validation = 1706  
                    AND IsNull(@vcPrenom_Beneficiaire, '') = ''
                    BEGIN
                        EXECUTE @iResultat = dbo.psIQEE_AjouterRejet @iID_Fichier_IQEE, @iID_Convention_Src, 
                                                                     @iID_Validation, @vcDescription, NULL, NULL, 
                                                                     @iID_Operation, @iID_Beneficiaire, NULL
                        IF @iResultat <= 0
                            GOTO ERREUR_VALIDATION
                        IF @bArretPremiereErreur = 1 AND @cType = 'E'
                            GOTO FIN_VALIDATION
                    END

                -- Validation #1707
                IF @iCode_Validation = 1707 
                    AND @dtDate_Naissance_Beneficiaire IS NULL
                    BEGIN
                        SET @vcDescription = REPLACE(@vcDescription, '%vcBeneficiaire%', @vcNom_Benef_Long)
                        EXECUTE @iResultat = dbo.psIQEE_AjouterRejet @iID_Fichier_IQEE, @iID_Convention_Src, 
                                                                     @iID_Validation, @vcDescription, NULL, NULL, 
                                                                     @iID_Operation, @iID_Beneficiaire, NULL
                        IF @iResultat <= 0
                            GOTO ERREUR_VALIDATION
                        IF @bArretPremiereErreur = 1 AND @cType = 'E'
                            GOTO FIN_VALIDATION
                    END

                -- Validation #1708
                IF @iCode_Validation = 1708 
                    AND @dtDate_Naissance_Beneficiaire > @dtDate_Transfert
                    BEGIN
                        SET @vcTMP1 = CONVERT(VARCHAR(10), @dtDate_Transfert, 120)
                        SET @vcTMP2 = CONVERT(VARCHAR(10), @dtDate_Naissance_Beneficiaire, 120)
                        SET @vcDescription = REPLACE(@vcDescription, '%vcBeneficiaire%', @vcNom_Benef_Long)
                        SET @vcDescription = REPLACE(@vcDescription, '%dtDate_Transfert%', @vcTMP1)
                        EXECUTE @iResultat = dbo.psIQEE_AjouterRejet @iID_Fichier_IQEE, @iID_Convention_Src, 
                                                                     @iID_Validation, @vcDescription, @vcTMP1, @vcTMP2, 
                                                                     @iID_Operation, @iID_Beneficiaire, NULL
                        IF @iResultat <= 0
                            GOTO ERREUR_VALIDATION
                        IF @bArretPremiereErreur = 1 AND @cType = 'E'
                            GOTO FIN_VALIDATION
                    END

                -- Validation #1709
                IF @iCode_Validation = 1709 
                    AND IsNull(@cSexe_Beneficiaire, '') NOT IN ('F', 'M')
                    BEGIN
                        SET @vcDescription = REPLACE(@vcDescription, '%vcBeneficiaire%', @vcNom_Benef_Long)
                        EXECUTE @iResultat = dbo.psIQEE_AjouterRejet @iID_Fichier_IQEE, @iID_Convention_Src, 
                                                                     @iID_Validation, @vcDescription, NULL, NULL, 
                                                                     @iID_Operation, @iID_Beneficiaire, NULL
                        IF @iResultat <= 0
                            GOTO ERREUR_VALIDATION
                        IF @bArretPremiereErreur = 1 AND @cType = 'E'
                            GOTO FIN_VALIDATION
                    END

                -- Validation #1710
                IF @iCode_Validation = 1710
                    BEGIN
                        SET @vcTMP1 = dbo.fnIQEE_ValiderNom(@vcPrenom_Beneficiaire)
                        IF @vcTMP1 IS NOT NULL
                            BEGIN
                                SET @vcDescription = REPLACE(@vcDescription, '%vcBeneficiaire%', @vcNom_Benef_Long)
                                SET @vcDescription = REPLACE(@vcDescription, '%vcCaractereNonConforme%', @vcTMP1)
                                EXECUTE @iResultat = dbo.psIQEE_AjouterRejet @iID_Fichier_IQEE, @iID_Convention_Src, 
                                                                             @iID_Validation, @vcDescription, NULL, @vcPrenom_Beneficiaire, 
                                                                             @iID_Operation, @iID_Beneficiaire, NULL
                                IF @iResultat <= 0
                                    GOTO ERREUR_VALIDATION
                                IF @bArretPremiereErreur = 1 AND @cType = 'E'
                                    GOTO FIN_VALIDATION
                            END
                    END

                -- Validation #1711
                IF @iCode_Validation = 1711
                    BEGIN
                        SET @vcTMP1 = dbo.fnIQEE_ValiderNom(@vcNom_Beneficiaire)
                        IF @vcTMP1 IS NOT NULL
                            BEGIN
                                SET @vcDescription = REPLACE(@vcDescription, '%vcBeneficiaire%', @vcNom_Benef_Long)
                                SET @vcDescription = REPLACE(@vcDescription, '%vcCaractereNonConforme%', @vcTMP1)
                                EXECUTE @iResultat = dbo.psIQEE_AjouterRejet @iID_Fichier_IQEE, @iID_Convention_Src, 
                                                                             @iID_Validation, @vcDescription, NULL, @vcNom_Beneficiaire, 
                                                                             @iID_Operation, @iID_Beneficiaire, NULL
                                IF @iResultat <= 0
                                    GOTO ERREUR_VALIDATION
                                IF @bArretPremiereErreur = 1 AND @cType = 'E'
                                    GOTO FIN_VALIDATION
                            END
                    END
    ;
                -- Validation #1712
                IF @iCode_Validation = 1712 
                    AND dbo.fnGENE_ValiderNEQ(@vcNEQ) = 0
                    BEGIN
                        EXECUTE @iResultat = dbo.psIQEE_AjouterRejet @iID_Fichier_IQEE, @iID_Convention_Src, 
                                                @iID_Validation, @vcDescription, NULL, @vcNEQ, 
                                                @iID_Operation, NULL, NULL
                        IF @iResultat <= 0
                            GOTO ERREUR_VALIDATION
                        IF @bArretPremiereErreur = 1 AND @cType = 'E'
                            GOTO FIN_VALIDATION
                    END

                -- Validation #1713
                IF @iCode_Validation = 1713 
                    AND @mTotal_Transfert <= 0
                    BEGIN
                        EXECUTE @iResultat = dbo.psIQEE_AjouterRejet @iID_Fichier_IQEE, @iID_Convention_Src, 
                                                                     @iID_Validation, @vcDescription, NULL, NULL, 
                                                                     @iID_Operation, NULL, NULL
                        IF @iResultat <= 0
                            GOTO ERREUR_VALIDATION
                        IF @bArretPremiereErreur = 1 AND @cType = 'E'
                            GOTO FIN_VALIDATION
                    END

                -- Validation #1714    TODO: applicable?
                IF @iCode_Validation = 1714 
                    AND @mTotal_Transfert > @mJuste_Valeur_Marchande
                    BEGIN
                        SET @vcTMP1 = CAST(@mJuste_Valeur_Marchande AS VARCHAR(100))
                        SET @vcTMP2 = CAST(@mTotal_Transfert AS VARCHAR(100))
                        EXECUTE @iResultat = dbo.psIQEE_AjouterRejet @iID_Fichier_IQEE, @iID_Convention_Src, 
                                                @iID_Validation, @vcDescription, @vcTMP1, @vcTMP2, 
                                                @iID_Operation, NULL, NULL
                        IF @iResultat <= 0
                            GOTO ERREUR_VALIDATION
                        IF @bArretPremiereErreur = 1 AND @cType = 'E'
                            GOTO FIN_VALIDATION
                    END

                -- Validation #1715
                IF @iCode_Validation = 1715 
                    AND @bTransfert_Autorise = 0 AND @mSoldeReel_IQEE > 0
                    BEGIN
                        SET @vcTMP1 = CAST(@mSoldeReel_IQEE AS VARCHAR(100))
                        EXECUTE @iResultat = dbo.psIQEE_AjouterRejet @iID_Fichier_IQEE, @iID_Convention_Src, 
                                                @iID_Validation, @vcDescription, NULL, @vcTMP1, 
                                                @iID_Operation, NULL, NULL
                        IF @iResultat <= 0
                            GOTO ERREUR_VALIDATION
                        IF @bArretPremiereErreur = 1 AND @cType = 'E'
                            GOTO FIN_VALIDATION
                    END

                -- Validation #1716
                IF @iCode_Validation = 1716 
                    AND @vcNo_Convention_Src IN ('C-20001005008', 'C-20001031021', 'R-20060717009', 'R-20060717011', 'R-20060717008', 
                                             'U-20051201028', 'R-20070627056', 'R-20070627058', 'F-20011119002', 'I-20050506001', 
                                             'I-20070925002', 'I-20070705002', 'I-20031223005', '2039499', 'D-20010730001', 
                                             '1449340', '2083034', 'I-20071107001', 'C-19991018042', 'I-20050923003', 'I-20050923002', 
                                             'U-20080902012', 'U-20080902012', 'U-20081028013', 'U-20080923016', 'R-20080923006', 
                                             'R-20080915007', 'R-20081105003', 'U-20071213003', 'U-20080403001', 'R-20080317046', 
                                             'R-20080317047', 'U-20071114068', 'U-20080411009', 'R-20080411001', 'U-20081009005', 
                                             'R-20080916001', 'U-20080827021', 'U-20081105042', 'R-20071120004', 'R-20071217029', 
                                             'U-20071217012', 'U-20080204002', 'U-20080930010', 'T-20081101006', 'T-20081101017', 
                                             'T-20081101023', 'T-20081101028', 'T-20081101067')
                    BEGIN
                        EXECUTE @iResultat = dbo.psIQEE_AjouterRejet @iID_Fichier_IQEE, @iID_Convention_Src, 
                                                                     @iID_Validation, @vcDescription, NULL, NULL, 
                                                                     @iID_Operation, NULL, NULL
                        IF @iResultat <= 0
                            GOTO ERREUR_VALIDATION
                        IF @bArretPremiereErreur = 1 AND @cType = 'E'
                            GOTO FIN_VALIDATION
                    END

                -- Validation #1717
                IF @iCode_Validation = 1717 
                    AND EXISTS (
                        SELECT *
                          FROM tblIQEE_ImpotsSpeciaux I
                               JOIN tblIQEE_SousTypeEnregistrement ST ON ST.iID_Sous_Type = I.iID_Sous_Type
                                                                     AND ST.cCode_Sous_Type IN ('91', '51')
                               JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = I.iID_Fichier_IQEE 
                         WHERE I.iID_Convention = @iID_Convention_Src
                           AND I.cStatut_Reponse IN ('A', 'R')
                           AND I.dtDate_Evenement < @dtDate_Transfert
                    )
                    BEGIN
                        EXECUTE @iResultat = dbo.psIQEE_AjouterRejet @iID_Fichier_IQEE, @iID_Convention_Src, 
                                                                     @iID_Validation, @vcDescription, NULL, NULL, 
                                                                     @iID_Operation, NULL, NULL
                        IF @iResultat <= 0
                            GOTO ERREUR_VALIDATION
                        IF @bArretPremiereErreur = 1 AND @cType = 'E'
                            GOTO FIN_VALIDATION
                    END

                    -- Validation #1718   
                    IF @iCode_Validation = 1718 
                        AND @bit_CasSpecial = 0
                        AND EXISTS (SELECT TOP 1 * FROM tblIQEE_CasSpeciaux 
                                     WHERE iID_Convention = @iID_Convention_Src AND bCasRegle = 0 AND ISNULL(iID_SousType, @iID_SousTypeEnregistrement) = @iID_SousTypeEnregistrement)
                    BEGIN
                        SET @vcDescription = REPLACE(@vcDescription, '%vcNo_Convention%', @vcNo_Convention_Src)

                        EXECUTE dbo.psIQEE_AjouterRejet @iID_Fichier_IQEE, @iID_Convention_Src, 
                                                        @iID_Validation, @vcDescription, NULL, NULL, 
                                                        @iID_Convention_Src, NULL, NULL

                        IF @bArretPremiereErreur = 1 AND @cType = 'E'
                            GOTO FIN_VALIDATION
                    END

        --        -- Validation #1719
        --        IF @iCode_Validation = 1719
                    --AND dbo.fnGENE_ValiderNEQ(@vcNEQ_Autre_Promoteur) = 0
        --            BEGIN
        --                EXECUTE @iResultat = dbo.psIQEE_AjouterRejet @iID_Fichier_IQEE, @iID_Convention_Src, 
        --                                        @iID_Validation, @vcDescription, NULL, @vcNEQ_Autre_Promoteur, 
        --                                        @iID_Operation, NULL, NULL
        --                IF @iResultat <= 0
        --                    GOTO ERREUR_VALIDATION
        --                IF @bArretPremiereErreur = 1 AND @cType = 'E'
        --                    GOTO FIN_VALIDATION
        --            END
            END

FIN_VALIDATION:
            -- S'il n'y a pas d'erreur, créer la transaction 04-01
            IF NOT EXISTS(SELECT *
                            FROM tblIQEE_Rejets R
                                 JOIN tblIQEE_Validations V ON V.iID_Validation = R.iID_Validation
                                                           AND V.cType = 'E'
                                 JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = V.tiID_Type_Enregistrement
                                                                    AND TE.cCode_Type_Enregistrement = '04'
                                 JOIN tblIQEE_SousTypeEnregistrement ST ON ST.iID_Sous_Type = V.iID_Sous_Type
                                                                       AND ST.cCode_Sous_Type = '03'
                            WHERE R.iID_Fichier_IQEE = @iID_Fichier_IQEE
                              AND R.iID_Convention = @iID_Convention_Src
                              AND R.iID_Lien_Vers_Erreur_1 = @iID_Operation
                )
            BEGIN
                ----------------------------------------------------------
                -- Récupère l'information requise à propos du souscripteur
                ----------------------------------------------------------

                --    Récupère l'adresse du souscripteur à la fin de cette année fiscale
                SELECT @iID_Adresse_Souscripteur = A.iID_Adresse,
                       --@vcAppartement_Souscripteur = A.vcUnite, 
                       @vcNo_Civique_Souscripteur = A.vcNumero_Civique, 
                       @vcRue_Souscripteur = A.vcNom_Rue, 
                       --@vcLigneAdresse2_Souscripteur = A.vcInternationale2, 
                       --@vcLigneAdresse3_Souscripteur = @vcLigneAdresse3_Souscripteur,
                       @vcVille_Souscripteur = A.vcVille,
                       @vcProvince_Souscripteur = IsNull(S.StateCode, LEFT(a.vcProvince, 2)),
                       @cID_Pays_Souscripteur = A.cID_Pays,
                       @vcCodePostal_Souscripteur = A.vcCodePostal,
                       @iTypeBoite_Souscripteur = A.iID_TypeBoite,
                       @vcBoite_Souscripteur = A.vcBoite
                  FROM dbo.fntGENE_ObtenirAdresseEnDate(@iID_Souscripteur, 1, @dtDate_Transfert, 0) A
                       LEFT JOIN dbo.Mo_State S ON S.StateID = A.iID_Province

                -- Séparer les éléments de l'adresse du souscripteur
                SET @vcAdresse_TMP = @vcRue_Souscripteur
                IF @vcNo_Civique_Souscripteur  IS NULL
                BEGIN
                    SELECT @vcNo_Civique_Souscripteur = vcNo_Civique, 
                           @vcRue_Souscripteur = 
                                CASE @iTypeBoite_Souscripteur 
                                    -- Ancien format des adresses
                                    WHEN 0 THEN LTRIM( ISNULL(vcRue, '') + 
                                                       CASE WHEN vcCase_Postale IS NULL THEN '' 
                                                            ELSE ' CP '+vcCase_Postale 
                                                       END
                                                     )
                                    -- Nouveau format des adresses selon le mode de livraison (Case Postale, Route Rurale)
                                    WHEN 1 THEN @vcAdresse_TMP + ' CP ' + @vcBoite_Souscripteur
                                    WHEN 2 THEN @vcAdresse_TMP + ' RR ' + @vcBoite_Souscripteur
                                    ELSE vcRue
                                END
                           --,@vcAppartement_Souscripteur = vcNo_Appartement
                      FROM dbo.fntGENE_ObtenirElementsAdresse(@vcAdresse_TMP, 0)
                END

                ---------------------------------------------------------------
                -- Sauvegarde la déclaration de la transaction 04 du transfert 
                ---------------------------------------------------------------

                INSERT INTO dbo.tblIQEE_Transferts (
                        iID_Fichier_IQEE, siAnnee_Fiscale, cStatut_Reponse, iID_Convention, vcNo_Convention, dtDate_Debut_Convention, 
                        tiCode_Version, iID_Sous_Type, iID_Operation, iID_TIO, iID_Operation_RIO, 
                        dtDate_Transfert, mTotal_Transfert, mCotisations_Donne_Droit_IQEE, mCotisations_Non_Donne_Droit_IQEE, 
                        mIQEE_CreditBase_Transfere, mIQEE_Majore_Transfere, ID_Autre_Promoteur, ID_Regime_Autre_Promoteur, vcNo_Contrat_Autre_Promoteur, 
                        iID_Beneficiaire, vcNAS_Beneficiaire, vcNom_Beneficiaire, vcPrenom_Beneficiaire, dtDate_Naissance_Beneficiaire, tiSexe_Beneficiaire, 
                        iID_Adresse_Beneficiaire, vcNo_Civique_Beneficiaire, vcRue_Beneficiaire, vcVille_Beneficiaire, vcProvince_Beneficiaire, vcPays_Beneficiaire, vcCodePostal_Beneficiaire, 
                        bTransfert_Total, bPRA_Deja_Verse, mJuste_Valeur_Marchande, mBEC, bTransfert_Autorise, 
                        iID_Souscripteur, tiType_Souscripteur, vcNAS_Souscripteur, vcNom_Souscripteur, vcPrenom_Souscripteur, tiID_Lien_Souscripteur, 
                        iID_Adresse_Souscripteur, vcNo_Civique_Souscripteur, vcRue_Souscripteur, vcVille_Souscripteur, vcProvince_Souscripteur, vcPays_Souscripteur, vcCodePostal_Souscripteur, 
                        mCotisations_Versees_Avant_Debut_IQEE
                    )
                SELECT @iID_Fichier_IQEE, @siAnnee_Fiscale, 'A', @iID_Convention_Src, @vcNo_Convention_Src, @dtDate_Debut_Convention, 
                       @tiCode_Version, @iID_Sous_Type, @iID_Operation, @iID_TIO, @iID_RIO, 
                       @dtDate_Transfert, @mTotal_Transfert, @mCotisations_Donne_Droit_IQEE, @mCotisations_Sans_Droit_IQEE, 
                       @mCreditBase_IQEE, @mMajore_IQEE, @iID_Autre_Promoteur, @iID_Regime_Autre_Promoteur, @vcNo_Contrat_Autre_Promoteur, 
                       @iID_Beneficiaire, @vcNAS_Beneficiaire, @vcNom_Beneficiaire, @vcPrenom_Beneficiaire, @dtDate_Naissance_Beneficiaire, 
                            CASE @cSexe_Beneficiaire WHEN 'F' THEN 1 WHEN 'M' THEN 2 ELSE NULL END,
                       @iID_Adresse_Beneficiaire, @vcNo_Civique_Beneficiaire, @vcRue_Beneficiaire, @vcVille_Beneficiaire, @vcProvince_Beneficiaire, @cID_Pays_Beneficiaire, @vcCodePostal_Beneficiaire, 
                       CASE WHEN @mTotal_Transfert < @mJuste_Valeur_Marchande THEN 0 ELSE 1 END, 
                            @bPRA_Deja_Verse, @mJuste_Valeur_Marchande, @mSolde_BEC, 
                            @bTransfert_Autorise, 
                       --@iID_Souscripteur, @vcNAS_Souscripteur, @vcNom_Souscripteur, @vcPrenom_Souscripteur, @dtDate_Naissance_Souscripteur, 
                       S.HumanID, 1, S.SocialNumber, S.LastName, S.FirstName, @tiRelationshipTypeID, 
                       @iID_Adresse_Souscripteur, @vcNo_Civique_Souscripteur, @vcRue_Souscripteur, @vcVille_Souscripteur, @vcProvince_Souscripteur, @cID_Pays_Souscripteur, @vcCodePostal_Souscripteur, 
                       @mCotisations_Avant_Debut_IQEE
                  FROM dbo.Mo_Human S
                 WHERE S.HumanID = @iID_Souscripteur
    /*            VALUES (
                        @iID_Fichier_IQEE, 'A', @iID_Convention_Src, @vcNo_Convention_Src, @dtDate_Debut_Convention, 
                        0, @iID_Sous_Type, @iID_Operation, @iID_TIO, @iID_Operation_RIO, @iID_Cotisation, NULL, 
                        @dtDate_Transfert, @mTotal_Transfert, @mCotisations_Donne_Droit_IQEE, @mCotisations_Sans_Droit_IQEE, 
                        @mCreditBase_IQEE, @mMajore_IQEE, NULL, @iID_Regime_Autre_Promoteur, @vcNo_Contrat_Autre_Promoteur, 
                        @iID_Beneficiaire, @vcNAS_Beneficiaire, @vcNom_Beneficiaire, @vcPrenom_Beneficiaire, @dtDate_Naissance_Beneficiaire, 
                            CASE @cSexe_Beneficiaire WHEN 'F' THEN 1 ELSE 2 END,     -- Confirmer le sexe du bénéficiaire
                        @bTransfert_Total, @bPRA_Deja_Verse, @mJuste_Valeur_Marchande, @mBEC, @bTransfert_Autorise
                    )
    */
            END

            SET @dtDate_TransfertOld = @dtDate_Transfert
        END
    END

    -- Retourner 0 si le traitement est réussi
    RETURN 0

ERREUR_VALIDATION:
    SELECT @iID_Validation = iID_Validation, 
            @vcDescription = vcDescription_Parametrable
        FROM dbo.tblIQEE_Validations
        WHERE iCode_Validation = 1700

    EXECUTE dbo.psIQEE_AjouterRejet @iID_Fichier_IQEE, @iID_Convention_Src, 
                            @iID_Validation, @vcDescription, NULL, NULL, 
                            @iID_Operation, NULL, NULL
    GOTO FIN_VALIDATION
END
