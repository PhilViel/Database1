/********************************************************************************************************************
Copyrights (c) 2017 Gestion Universitas inc.

Code du service : psIQEE_CreerTransactions04_02
Nom du service  : Créer les transactions de type 04-02 - Transfert cessionnaire d'un promoteur externe
But             : Sélectionner, valider et créer les transactions de type 04 – 02, concernant les transferts vers l'interne
                  dans un nouveau fichier de transactions de l’IQÉÉ.
Facette         : IQÉÉ

Paramètres d’entrée :
        Paramètre               Description
        --------------------    -----------------------------------------------------------------
        iID_Fichier_IQEE        Identifiant du nouveau fichier de transactions dans lequel les transactions 04-01 doivent être créées.
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

Exemple d’appel : exec dbo.psIQEE_CreerTransactions04_02 10, 0, NULL, 0, 'T'

Paramètres de sortie:
        Champ               Description
        ------------        ------------------------------------------
        iCode_Retour        = 0 : Exécution terminée normalement
                            < 0 : Erreur de traitement

Historique des modifications:
    Date        Programmeur             Description
    ----------  --------------------    --------------------------------------------------------------------------
    2017-09-19  Steeve Picard           Création du service (basé sur la psIQEE_CreerTransactions04_02)
    2018-02-08  Steeve Picard           Déplacement de «siAnnee_Fiscale» de la table «tblIQEE_Fichiers» vers les tables d'évèments «tblIQEE_Transferts»
    2018-02-26  Steeve Picard           Empêcher que la «dtFinCotisation» soit plus grande que la dernière fin de mois
    2018-06-06  Steeve Picard           Modificiation de la gestion des retours d'erreur par RQ
    2018-09-19  Steeve Picard           Ajout du champ «iID_SousType» à la table «tblIQEE_CasSpeciaux» pour pouvoir filtrer
***********************************************************************************************************************/
CREATE PROCEDURE dbo.psIQEE_CreerTransactions04_02
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
    PRINT 'Déclaration des transferts cédant vers l''interne (T04-02) pour ' + STR(@siAnnee_Fiscale, 4)
    PRINT '--------------------------------------------------------------------------'
    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' EXEC psIQEE_CreerTransactions04_02 started'

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

    DECLARE @StartTimer datetime = GetDate(),
            --@WhileTimer datetime,
            @QueryTimer datetime,
            @ElapseTime datetime,
            --@IntervalPrint INT = 5000,
            @MaxRow INT = 0,
            @IsDebug bit = dbo.fn_IsDebug()

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
    
    -- Sélectionner dates applicables aux transactions
    SELECT @dtDebutCotisation = Str(@siAnnee_Fiscale, 4) + '-01-01 00:00:00',
           @dtFinCotisation = Str(@siAnnee_Fiscale, 4) + '-12-31 23:59:59'

    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Récupère les IDs du type & sous-type pour ce type d''enregistrement'
    SELECT 
        @tiID_TypeEnregistrement = tiID_Type_Enregistrement,
        @iID_SousTypeEnregistrement = iID_Sous_Type
    FROM
        dbo.vwIQEE_Enregistrement_TypeEtSousType 
    WHERE
        cCode_Type_Enregistrement = '04'
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

    SELECT @iID_SousTypeEnregistrement = iID_Sous_Type
    FROM tblIQEE_SousTypeEnregistrement ST
         JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = ST.tiID_Type_Enregistrement
    WHERE TE.cCode_Type_Enregistrement = '04'
      AND ST.cCode_Sous_Type = '01'

    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Récupération des conventions à déclarer'
    BEGIN
        IF OBJECT_ID('tempdb..#TB_Transfert_04_02') IS NOT NULL
            DROP TABLE #TB_Transfert_04_02

        PRINT '   ' + Convert(varchar(20), GetDate(), 120) + '   - Récupère les conventions ayant eu un transfert cédant'
        SET @QueryTimer = GetDate()
    
        SET ROWCOUNT @MaxRow

        ;WITH CTE_Transfert as (
            SELECT DISTINCT 
                O.OperID, O.OperDate
            FROM 
                Un_Oper O
                LEFT JOIN (
                        SELECT OC.OperSourceID, OC.OperID
                          FROM dbo.Un_OperCancelation OC
                               JOIN dbo.Un_Oper O ON O.OperID = OC.OperID
                         WHERE O.OperDate <= @dtFinCotisation
                ) OC ON OC.OperSourceID = O.OperID OR OC.OperID = O.OperID
            WHERE 0=0
                AND O.OperTypeID = 'TIN'
                AND O.OperDate Between @dtDebutCotisation and @dtFinCotisation
                AND OC.OperSourceID IS NULL
                AND NOT EXISTS (
                        SELECT * FROM dbo.Un_TIO WHERE iOUTOperID = O.OperID
                    )
        ),
        CTE_Montant as (
            SELECT
                T.OperID, X.ConventionID, MontantTransfert = Sum(X.Montant)
            FROM
                CTE_Transfert T 
                JOIN (
                    SELECT
                        OperID, ConventionID, Montant = Sum(ConventionOperAmount)
                    FROM
                        dbo.Un_ConventionOper CO
                    WHERE
                        EXISTS(SELECT * FROM #TB_ListeConvention WHERE ConventionID = CO.ConventionID)
                    GROUP BY
                        OperID, ConventionID
                    UNION
                    SELECT DISTINCT 
                        Ct.OperID, U.ConventionID, Sum(Ct.Cotisation + Ct.Fee)
                    FROM 
                        dbo.Un_Cotisation Ct
                        JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
                    WHERE
                        EXISTS(SELECT * FROM #TB_ListeConvention WHERE ConventionID = U.ConventionID)
                    GROUP BY
                        OperID, ConventionID
                    UNION
                    SELECT DISTINCT 
                        OperID, ConventionID, Sum(fCESG + fACESG + fCLB)
                    FROM 
                        dbo.Un_CESP C
                    WHERE
                        EXISTS(SELECT * FROM #TB_ListeConvention WHERE ConventionID = C.ConventionID)
                    GROUP BY
                        OperID, ConventionID
                ) X ON X.OperID = T.OperID
            GROUP BY
                T.OperID, X.ConventionID
        )
        SELECT 
            M.ConventionID, X.ConventionNo, 
            BeneficiaryID = (SELECT TOP 1 iID_Nouveau_Beneficiaire FROM dbo.tblCONV_ChangementsBeneficiaire 
                              WHERE iID_Convention = M.ConventionID AND dtDate_Changement_Beneficiaire <= T.OperDate 
                              ORDER BY dtDate_Changement_Beneficiaire DESC),
            dtEnregistrementRQ = DE.dtDate_EnregistrementRQ,
            iID_Operation = T.OperID, 
            dtTransfert = T.OperDate, 
            M.MontantTransfert,
            vcNEQ_ExtPromo = CASE WHEN Pr.bOffre_IQEE <> 0 THEN Pr.vcNEQ ELSE '000000000' END, 
            vcRegimeNo_ExtPromo = Pl.ExternalPlanGovernmentRegNo, 
            vcConventionNo_ExtPromo = O.vcOtherConventionNo,
            O.ExternalPlanID, O.tiBnfRelationWithOtherConvBnf, O.vcOtherConventionNo, O.tiREEEType, O.bEligibleForCESG, O.bEligibleForCLB, O.bOtherContratBnfAreBrothers,
            O.fYearBnfCot, O.fBnfCot, O.fNoCESGCotBefore98, O.fNoCESGCot98AndAfter, O.fCESGCot, O.fCESG, O.fCLB, O.fAIP, O.fMarketValue
        INTO
            #TB_Transfert_04_02
        FROM
            CTE_Transfert T
            JOIN CTE_Montant M ON M.OperID = T.OperID
            JOIN #TB_ListeConvention X ON X.ConventionID = M.ConventionID AND X.dtReconnue_RQ IS NOT NULL
            JOIN dbo.Un_OUT O ON O.OperID = T.OperID
            LEFT JOIN dbo.fntIQEE_ObtenirDateEnregistrementRQ_PourTous(DEFAULT) DE ON DE.iID_Convention = M.ConventionID
            JOIN dbo.Un_ExternalPlan Pl ON Pl.ExternalPlanID = O.ExternalPlanID
            JOIN dbo.Un_ExternalPromo Pr ON Pr.ExternalPromoID = Pl.ExternalPromoID
            LEFT JOIN dbo.tblIQEE_CasSpeciaux AS CS ON CS.iID_Convention = X.ConventionID
        WHERE
            Year(T.OperDate) > 2016
            OR IsNull(CS.bCasRegle, 0) <> 0
        ORDER BY
            M.ConventionID

        SET @iCount = @@ROWCOUNT
        SET @ElapseTime = GetDate() - @QueryTimer

        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    » ' + LTrim(Str(@iCount)) + ' retrouvées (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

        IF @iCount < 5
            SET @MaxRow = @iCount

        SET ROWCOUNT 0

        IF @IsDebug <> 0 AND @MaxRow between 1 and 10
            SELECT * FROM #TB_Transfert_04_02

        IF OBJECT_ID('tempdb..#TB_Beneficiary_04_02') IS NOT NULL
            DROP TABLE #TB_Beneficiary_04_02

        PRINT '   ' + Convert(varchar(20), GetDate(), 120) + '   - Récupère les bénéficiaires ayant eu un transfert cédant'
        SET @QueryTimer = GetDate()

        ;WITH CTE_Beneficiaire as (
            SELECT DISTINCT
                T.BeneficiaryID,
                vcNom = H.LastName, 
                vcPrenom = H.FirstName, 
                dtNaissance = Cast(H.Birthdate as Date),
                cSexe = H.SexID,
                H.SocialNumber
            FROM 
                #TB_Transfert_04_02 T
                JOIN dbo.Mo_Human H ON H.HumanID = T.BeneficiaryID
        )
        SELECT 
            B.BeneficiaryID, B.vcNom, B.vcPrenom, B.dtNaissance, B.cSexe,
            vcNomPrenom = dbo.fn_Mo_FormatHumanName(B.vcNom, '', B.vcPrenom, '', '', 0),
            vcNAS = B.SocialNumber --N.SocialNumber
        INTO
            #TB_Beneficiary_04_02
       FROM 
            CTE_Beneficiaire B
            --JOIN dbo.fntCONV_ObtenirNasParHumainEnDate(@dtFinCotisation) N ON N.HumanID = B.BeneficiaryID

        SET @iCount = @@ROWCOUNT
        SET @ElapseTime = GetDate() - @QueryTimer

        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    » ' + LTrim(Str(@iCount)) + ' retrouvées (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

        IF NOT EXISTS(SELECT TOP 1 * FROM #TB_Transfert_04_02)
           RETURN

        IF @IsDebug <> 0 AND @MaxRow between 1 and 10
            SELECT * FROM #TB_Beneficiary_04_02

        PRINT '   ' + Convert(varchar(20), GetDate(), 120) + '   - Récupère les solde de subventions ayant eu un transfert cédant'

        IF OBJECT_ID('tempdb..#TB_Subvention_04_02') IS NOT NULL
            DROP TABLE #TB_Subvention_04_02

        SET @QueryTimer = GetDate()
       ;WITH CTE_Transfert as (
            SELECT
                ConventionID, iID_Operation, dtTransfert, 
                Row_Num = Row_Number() OVER(Partition By ConventionID, dtTransfert Order By iID_Operation)
            FROM
                #TB_Transfert_04_02
        )
        , CTE_ConvOper as (
          SELECT DISTINCT
                TB.ConventionID, TB.dtTransfert, CO.ConventionOperTypeID, CO.ConventionOperAmount
            FROM
                CTE_Transfert TB
                JOIN dbo.Un_ConventionOper CO ON CO.ConventionID = TB.ConventionID
                JOIN dbo.Un_Oper O ON O.OperID = CO.OperID
                                  AND O.OperDate < TB.dtTransfert
             LEFT JOIN dbo.Un_OperCancelation OC ON OC.OperID = O.OperID OR OC.OperSourceID = O.OperID
                LEFT JOIN dbo.fntGENE_SplitIntoTable(dbo.fnOPER_ObtenirTypesOperationConvCategorie('OPER_RENDEMENTS_IQEE'), ',') X
                    ON X.strField = CO.ConventionOperTypeID
           WHERE 
                0=0 --TB.Row_Num = 1
                AND (   (O.OperTypeID <> 'IQE' AND O.OperDate < IsNull(TB.dtTransfert, GETDATE()))
                    OR     (O.OperTypeID = 'IQE' AND CO.ConventionOperAmount < 0.00)
                    OR    (O.OperTypeID = 'IQE' AND O.OperDate < IsNull(TB.dtTransfert, GETDATE()))
                 ) 
              AND OC.OperSourceID IS NULL
                AND (X.strField IS NOT NULL OR CO.ConventionOperTypeID IN ('CBQ', 'MMQ'))
        )
        SELECT 
            ConventionID, dtTransfert,
           Credit_Base = Sum(CASE ConventionOperTypeID WHEN 'CBQ' THEN ConventionOperAmount ELSE 0 END),
          Majoration = Sum(CASE ConventionOperTypeID WHEN 'MMQ' THEN ConventionOperAmount ELSE 0 END),
          Interet = Sum(Case WHEN ConventionOperTypeID IN ('CBQ', 'MMQ') THEN 0 ELSE CO.ConventionOperAmount END)
        INTO
            #TB_Subvention_04_02
       FROM 
            CTE_ConvOper CO
       GROUP BY 
            ConventionID, dtTransfert

        SET @iCount = @@ROWCOUNT
        SET @ElapseTime = GetDate() - @QueryTimer

        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    » ' + LTrim(Str(@iCount)) + ' solde de l''IQÉÉ correspondant (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

        IF @IsDebug <> 0 AND @MaxRow between 1 and 10
            SELECT * FROM #TB_Subvention_04_02

        PRINT '   ' + Convert(varchar(20), GetDate(), 120) + '   - Récupère les totaux de cotisations ayant eu un transfert cédant'

        IF OBJECT_ID('tempdb..#TB_Cotisation_04_02') IS NOT NULL
            DROP TABLE #TB_Cotisation_04_02

        SET @QueryTimer = GetDate()
       ;WITH CTE_Transfert as (
            SELECT
                ConventionID, dtTransfert, Max(iID_Operation) as iID_Operation
            FROM
                #TB_Transfert_04_02
            GROUP BY
                ConventionID, dtTransfert
        ),
        CTE_Cotisation as (
            SELECT 
                T.ConventionID, dtTransfert,
                TotalCotisation = Sum(CASE O.OperTypeID WHEN 'TFR' THEN 0 ELSE Ct.Cotisation + Ct.Fee END),
                TotalFrais = Sum(CASE O.OperTypeID WHEN 'TFR' THEN Ct.Cotisation + Ct.Fee ELSE 0 END),
                TotalCotisationAvantIQEE = Sum(CASE WHEN O.OperTypeID = 'TFR' THEN 0 
                                                    WHEN Ct.EffectDate < '2007-02-20' THEN Ct.Cotisation + Ct.Fee
                                                    ELSE 0 END)
            FROM 
                CTE_Transfert T
                JOIN dbo.Un_Unit U ON U.ConventionID = T.ConventionID
                JOIN dbo.Un_Cotisation Ct ON Ct.UnitID = U.UnitID
                JOIN dbo.Un_Oper O ON O.OperID = Ct.OperID
                LEFT JOIN (
                    SELECT 
                        OC.OperSourceID, OC.OperID
                    FROM 
                        dbo.Un_OperCancelation OC
                        JOIN dbo.Un_Oper O ON O.OperID = OC.OperID
                    WHERE 
                        O.OperDate <= @dtFinCotisation
                    ) OC ON OC.OperSourceID = O.OperID OR OC.OperID = O.OperID
            WHERE 0=0
                AND O.OperDate <= T.dtTransfert 
                AND O.OperID < T.iID_Operation
                AND OC.OperSourceID IS NULL
            GROUP BY 
                T.ConventionID, dtTransfert --, T.iID_Operation
        ),
        CTE_Solde as (
            SELECT 
                R.ConventionID, R.dtTransfert,
                dtDate_Traitement_RQ = Max(R.dtDate_Traitement_RQ), 
                Solde_IQEE = Sum(CASE R.vcCodeReponse WHEN 'CDB' THEN R.mMontant ELSE 0 END),
                Solde_Majoration = Sum(CASE R.vcCodeReponse WHEN 'MAJ' THEN R.mMontant ELSE 0 END),
                Solde_Interet = Sum(CASE R.vcCodeReponse WHEN 'INT' THEN R.mMontant ELSE 0 END),
                Solde_Ayant_Droit_IQEE = Sum(CASE R.vcCodeReponse WHEN 'MCI' THEN R.mMontant ELSE 0 END),
                Solde_Cotisation = Sum(CASE R.vcCodeReponse WHEN 'MCI' THEN R.mCotisations ELSE 0 END)
            FROM ( 
                SELECT 
                    T.ConventionID, T.dtTransfert, T.siAnnee_Fiscale, TR.vcCode as vcCodeReponse, RD.mMontant, F.dtDate_Traitement_RQ, D.mCotisations,
                    Row_Num = Row_Number() OVER(PARTITION BY T.ConventionID, T.dtTransfert, TR.vcCode ORDER BY F.dtDate_Traitement_RQ DESC)
                FROM
                    #TB_Transfert_04_02 T 
                    JOIN dbo.tblIQEE_ReponsesDemande RD ON RD.iID_Convention = T.ConventionID
                    join dbo.tblIQEE_TypesReponse TR ON TR.tiID_Type_Reponse = RD.tiID_Type_Reponse
                    join dbo.tblIQEE_Demandes D ON D.iID_Demande_IQEE = RD.iID_Demande_IQEE AND TR.vcCode = 'MCI'
                    join dbo.tblIQEE_Fichiers F ON F.iid_Fichier_IQEE = RD.iid_Fichier_IQEE
                                               AND F.dtDate_Traitement_RQ < T.dtTransfert
               WHERE 
                    TR.vcCode IN ('CDB', 'MCI', 'MAJ', 'INT')
                    AND F.dtDate_Traitement_RQ < T.dtTransfert
               ) R
            WHERE 
                R.Row_Num = 1
            GROUP BY
                R.ConventionID, R.dtTransfert --, R.siAnnee_Fiscale, R.dtDate_Traitement_RQ        
        )
        SELECT
            Ct.ConventionID,  Ct.dtTransfert, Ct.TotalCotisation, RQ.Solde_Ayant_Droit_IQEE,
            CASE WHEN Ct.TotalCotisation < IsNull(RQ.Solde_Ayant_Droit_IQEE, 0) THEN 0
                 ELSE Ct.TotalCotisation - IsNull(RQ.Solde_Ayant_Droit_IQEE, 0)
            END as Solde_Non_Droit_IQEE,
            Ct.TotalCotisationAvantIQEE
        INTO
            #TB_Cotisation_04_02
        FROM
            CTE_Cotisation Ct
            LEFT JOIN CTE_Solde RQ ON RQ.ConventionID = Ct.ConventionID And Ct.dtTransfert = RQ.dtTransfert
            
        SET @iCount = @@ROWCOUNT
        SET @ElapseTime = GetDate() - @QueryTimer

        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    » ' + LTrim(Str(@iCount)) + ' solde de l''IQÉÉ correspondant (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

        IF @IsDebug <> 0 AND @MaxRow between 1 and 10
            SELECT * FROM #TB_Cotisation_04_02

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

        IF OBJECT_ID('tempdb..#TB_Rejet_04_02') IS NULL
            CREATE TABLE #TB_Rejets_04_02 (
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
            TRUNCATE TABLE #TB_Rejet_04_02

        -- Sélectionner les validations à faire pour le sous type de transaction
        IF OBJECT_ID('tempdb..#TB_Validation_04_02') IS NOT NULL
            DROP TABLE #TB_Validation_04_02

        SELECT 
            V.iOrdre_Presentation, V.iID_Validation, V.iCode_Validation, V.cType, V.vcDescription_Parametrable as vcDescription
        INTO
            #TB_Validation_04_02
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
        WHILE Exists(SELECT TOP 1 * FROM #TB_Validation_04_02 WHERE iOrdre_Presentation > @iOrdre_Presentation) 
        BEGIN
            SET @iCountRejets = 0

            SELECT TOP 1
                @iOrdre_Presentation = iOrdre_Presentation,
                @iID_Validation = iID_Validation, 
                @iCode_Validation = iCode_Validation,
                @vcDescription = vcDescription,
                @cType = cType
            FROM
                #TB_Validation_04_02 
            WHERE
                iOrdre_Presentation > @iOrdre_Presentation
            ORDER BY 
                iOrdre_Presentation

            PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '   - Validation #' + LTrim(Str(@iCode_Validation)) + ': ' + @vcDescription

            BEGIN TRY
                -- Validation : Le transfert cédant a déjà été envoyé et une réponse reçue de RQ.
                IF @iCode_Validation = 1401 
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Operation
                        FROM
                            #TB_Transfert_04_02 C
                        WHERE
                            Exists (
                                SELECT * FROM dbo.tblIQEE_Transferts T
                                              JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = T.iID_Fichier_IQEE 
                                WHERE 
                                    T.iID_Convention = C.ConventionID
                                    AND T.iID_Sous_Type = @iID_SousTypeEnregistrement
                                    AND T.iID_Operation = C.iID_Operation
                                    AND T.cStatut_Reponse = 'R'
                            )
                    )
                    INSERT INTO #TB_Rejets_04_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, iID_Operation, NULL, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : L'impôt spécial de remplacement de bénéficiaire non reconnu est en cours de traitement par RQ et est en attente d’une réponse de RQ
                IF @iCode_Validation = 702
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Operation
                        FROM
                            #TB_Transfert_04_02 C
                        WHERE
                            Exists (
                                SELECT * FROM dbo.tblIQEE_Transferts T
                                              JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = T.iID_Fichier_IQEE 
                                WHERE 
                                    T.iID_Convention = C.ConventionID
                                    AND T.iID_Sous_Type = @iID_SousTypeEnregistrement
                                    AND T.iID_Operation = C.iID_Operation
                                    AND T.cStatut_Reponse = 'A'
                                    AND T.tiCode_Version <> 1
                            )
                    )
                    INSERT INTO #TB_Rejets_04_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, iID_Operation, NULL, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Une erreur soulevée par Revenu Québec est en cours de traitement pour le transfert cédant
                IF @iCode_Validation = 703
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Operation
                        FROM
                            #TB_Transfert_04_02 C
                        WHERE
                            Exists (
                                SELECT * FROM dbo.tblIQEE_Transferts T
                                              JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = T.iID_Fichier_IQEE 
                                              JOIN dbo.tblIQEE_Erreurs E ON E.iID_Enregistrement = T.iID_Transfert
                                              JOIN dbo.tblIQEE_StatutsErreur SE ON SE.tiID_Statuts_Erreur = E.tiID_Statuts_Erreur
                                                                               AND SE.vcCode_Statut = 'ATR'
                                WHERE 
                                    T.iID_Convention = C.ConventionID
                                    AND E.tiID_Type_Enregistrement = @tiID_TypeEnregistrement
                                    AND T.iID_Sous_Type = @iID_SousTypeEnregistrement
                                    AND T.iID_Operation = C.iID_Operation
                                    AND T.cStatut_Reponse = 'E'
                            )
                    )
                    INSERT INTO #TB_Rejets_04_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, iID_Operation, NULL, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le NAS du bénéficiaire du transfert cédant est absent ou invalide
                IF @iCode_Validation = 704
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Operation, B.BeneficiaryID, B.vcNomPrenom, B.vcNAS
                        FROM
                            #TB_Transfert_04_02 C
                            JOIN #TB_Beneficiary_04_02 B ON B.BeneficiaryID = C.BeneficiaryID
                        WHERE
                            Len(IsNull(B.vcNAS, '')) = 0
                            OR dbo.FN_CRI_CheckSin(B.vcNAS, 0) = 0
                    )
                    INSERT INTO #TB_Rejets_04_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, REPLACE(@vcDescription, '%vcBeneficiaire%', vcNomPrenom),
                        NULL, vcNAS, iID_Operation, BeneficiaryID, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le nom du bénéficiaire du transfert cédant est absent ou invalide
                IF @iCode_Validation = 705
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Operation, B.BeneficiaryID
                        FROM
                            #TB_Transfert_04_02 C
                            JOIN #TB_Beneficiary_04_02 B ON B.BeneficiaryID = C.BeneficiaryID
                        WHERE
                            Len(IsNull(B.vcNom, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_04_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, iID_Operation, BeneficiaryID, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le prénom du bénéficiaire du transfert cédant est absent ou invalide
                IF @iCode_Validation = 706
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Operation, B.BeneficiaryID
                        FROM
                            #TB_Transfert_04_02 C
                            JOIN #TB_Beneficiary_04_02 B ON B.BeneficiaryID = C.BeneficiaryID
                        WHERE
                            Len(IsNull(B.vcPrenom, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_04_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, iID_Operation, BeneficiaryID, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : La date de naissance du bénéficiaire du transfert cédant est absent
                IF @iCode_Validation = 707
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Operation, B.BeneficiaryID, B.vcNomPrenom
                        FROM
                            #TB_Transfert_04_02 C
                            JOIN #TB_Beneficiary_04_02 B ON B.BeneficiaryID = C.BeneficiaryID
                        WHERE
                            IsNull(B.dtNaissance, '1900-01-01') = '1900-01-01'
                    )
                    INSERT INTO #TB_Rejets_04_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, REPLACE(@vcDescription, '%vcBeneficiaire%', vcNomPrenom),
                        NULL, NULL, iID_Operation, BeneficiaryID, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : La date de naissance du bénéficiaire du transfert cédant est plus grande que la date du transfert
                IF @iCode_Validation = 708
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Operation, C.dtTransfert, B.BeneficiaryID, B.vcNomPrenom, B.dtNaissance
                        FROM
                            #TB_Transfert_04_02 C
                            JOIN #TB_Beneficiary_04_02 B ON B.BeneficiaryID = C.BeneficiaryID
                        WHERE
                            B.dtNaissance > C.dtTransfert
                    )
                    INSERT INTO #TB_Rejets_04_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, REPLACE(@vcDescription, '%vcBeneficiaire%', vcNomPrenom),
                        CONVERT(VARCHAR(10), dtTransfert, 120), CONVERT(VARCHAR(10), dtNaissance, 120), iID_Operation, BeneficiaryID, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le sexe du bénéficiaire du transfert cédant n’est pas défini
                IF @iCode_Validation = 709
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Operation, B.BeneficiaryID, B.vcNomPrenom, B.cSexe
                        FROM
                            #TB_Transfert_04_02 C
                            JOIN #TB_Beneficiary_04_02 B ON B.BeneficiaryID = C.BeneficiaryID
                        WHERE
                            IsNull(B.cSexe, '') NOT IN ('F', 'M')
                    )
                    INSERT INTO #TB_Rejets_04_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, REPLACE(@vcDescription, '%vcBeneficiaire%', vcNomPrenom),
                        NULL, NULL, iID_Operation, BeneficiaryID, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le prénom du bénéficiaire de transfert cédant contient au moins 1 caractère non conforme
                IF @iCode_Validation = 710
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Operation, B.BeneficiaryID, B.vcNomPrenom, B.vcPrenom, 
                            vcNonConforme = dbo.fnIQEE_ValiderNom(B.vcPrenom)
                        FROM
                            #TB_Transfert_04_02 C
                            JOIN #TB_Beneficiary_04_02 B ON B.BeneficiaryID = C.BeneficiaryID
                    )
                    INSERT INTO #TB_Rejets_04_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, REPLACE(REPLACE(@vcDescription, '%vcBeneficiaire%', vcNomPrenom), '%vcCaractereNonConforme%', vcNonConforme),
                        NULL, vcPrenom, iID_Operation, BeneficiaryID, NULL
                    FROM
                        CTE_Convention
                    WHERE
                        Len(vcNonConforme) > 0

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le nom du bénéficiaire de transfert cédant contient au moins 1 caractère non conforme
                IF @iCode_Validation = 711
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Operation, B.BeneficiaryID, B.vcNomPrenom, B.vcNom, 
                            vcNonConforme = dbo.fnIQEE_ValiderNom(B.vcNom)
                        FROM
                            #TB_Transfert_04_02 C
                            JOIN #TB_Beneficiary_04_02 B ON B.BeneficiaryID = C.BeneficiaryID
                    )
                    INSERT INTO #TB_Rejets_04_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, REPLACE(REPLACE(@vcDescription, '%vcBeneficiaire%', vcNomPrenom), '%vcCaractereNonConforme%', vcNonConforme),
                        NULL, vcNom, iID_Operation, BeneficiaryID, NULL
                    FROM
                        CTE_Convention
                    WHERE
                        Len(vcNonConforme) > 0

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le numéro d’entreprise du Québec (NEQ) du cessionnaire pour un transfert cédant est absent ou invalide
                IF @iCode_Validation = 712
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Operation, C.vcNEQ_ExtPromo
                        FROM
                            #TB_Transfert_04_02 C
                        WHERE
                            Len(IsNull(C.vcNEQ_ExtPromo, '')) = 0
                            OR dbo.fnGENE_ValiderNEQ(C.vcNEQ_ExtPromo) = 0
                    )
                    INSERT INTO #TB_Rejets_04_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, vcNEQ_ExtPromo, iID_Operation, NULL, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le montant total du transfert cédant calculé doit être plus grand que 0
                IF @iCode_Validation = 713
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Operation
                        FROM
                            #TB_Transfert_04_02 C
                        WHERE
                            C.MontantTransfert < 0
                    )
                    INSERT INTO #TB_Rejets_04_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, iID_Operation, NULL, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Un montant d'IQÉÉ fait partie d'un transfert cédant non autorisé (L'IQÉÉ doit être récupéré ou GUI doit prendre la perte)
                IF @iCode_Validation = 715
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Operation, SoldeIQEE = IsNull(S.Credit_Base, 0) + IsNull(S.Majoration, 0)
                        FROM
                            #TB_Transfert_04_02 C
                            JOIN #TB_Subvention_04_02 S ON S.ConventionID = C.ConventionID
                        WHERE
                            IsNull(S.Credit_Base, 0) + IsNull(S.Majoration, 0) < 0
                            AND @bTransfert_Autorise = 0
                    )
                    INSERT INTO #TB_Rejets_04_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, LTrim(Str(SoldeIQEE, 10, 2)), iID_Operation, NULL, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Les transactions de la convention sont retenues parce qu'elle a fait l'objet de transactions manuelles de l'IQÉÉ avant que les transactions soient implantées dans UniAccès
                IF @iCode_Validation = 716
                BEGIN
                    PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » *** Skipped ***'

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : La convention a été fermée par une transaction d'impôt spécial 91 ou 51
                IF @iCode_Validation = 717
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Operation
                        FROM
                            #TB_Transfert_04_02 C
                        WHERE
                            Exists (
                                SELECT * FROM dbo.tblIQEE_Transferts T
                                              JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = T.iID_Fichier_IQEE 
                                              JOIN dbo.tblIQEE_SousTypeEnregistrement ST ON ST.iID_Sous_Type = T.iID_Sous_Type
                                                                                        AND ST.cCode_Sous_Type IN ('91', '51')
                                WHERE 
                                    T.iID_Convention = C.ConventionID
                                    AND T.cStatut_Reponse IN ('A', 'R')
                                    AND T.dtDate_Transfert < C.dtTransfert
                            )
                    )
                    INSERT INTO #TB_Rejets_04_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, iID_Operation, NULL, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : La convention a des cas spéciaux non résolus avec Revenu Québec en cours
                IF @iCode_Validation = 718
                BEGIN
                    INSERT INTO #TB_Rejets_04_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        C.ConventionID, @iID_Validation, REPLACE(@vcDescription, '%vcNo_Convention%', C.ConventionNo),
                        NULL, NULL, C.iID_Operation, NULL, NULL
                    FROM
                        #TB_Transfert_04_02 C
                        JOIN dbo.tblIQEE_CasSpeciaux CS ON CS.iID_Convention = C.ConventionID
                    WHERE
                        CS.bCasRegle = 0
                        AND ISNULL(CS.iID_SousType, @iID_SousTypeEnregistrement) = @iID_SousTypeEnregistrement

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
                    iCode_Validation = 700

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
                    DELETE FROM #TB_Transfert_04_02
                    WHERE EXISTS (SELECT * FROM #TB_Rejets_04_02 WHERE iID_Convention = ConventionID AND iID_Validation = @iID_Validation)
                END
            END
        END -- IF @iCode_Validation 

        -- Efface tous les conventions ayant eu au moins un rejet de validation
        DELETE FROM #TB_Transfert_04_02
        WHERE EXISTS (SELECT * FROM #TB_Rejets_04_02 R JOIN dbo.tblIQEE_Validations V ON V.iID_Validation = R.iID_Validation WHERE V.cType = 'E' And iID_Convention = ConventionID)

        INSERT INTO dbo.tblIQEE_Rejets (
            iID_Fichier_IQEE, siAnnee_Fiscale, iID_Convention, iID_Validation, vcDescription,
            vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
            --,tCommentaires, iID_Utilisateur_Modification, dtDate_Modification
        )
        SELECT 
            @iID_Fichier_IQEE, @siAnnee_Fiscale, R.iID_Convention, R.iID_Validation, R.vcDescription,
            R.vcValeur_Reference, vcValeur_Erreur, R.iID_Lien_Vers_Erreur_1, R.iID_Lien_Vers_Erreur_2, R.iID_Lien_Vers_Erreur_3
        FROM 
            #TB_Rejets_04_02 R
    END

    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Déclaration des retraits de cotisations'
    BEGIN
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '   Créer les enregistrements d''impôt spéciaux.'
        SET @QueryTimer = GetDate()
        ; WITH CTE_Sexe as (
            SELECT X.rowID as ID, X.strField as Code
            FROM ProAcces.fn_SplitIntoTable('F,M', ',') X
        ),
        CTE_Transfert As (
            SELECT
                T.ConventionID, T.ConventionNo, T.BeneficiaryID, T.dtEnregistrementRQ, T.dtTransfert, 
                T.vcNEQ_ExtPromo, T.vcRegimeNo_ExtPromo, T.vcConventionNo_ExtPromo,
                iID_Operation = Max(T.iID_Operation),
                MontantTransfert = Sum(T.MontantTransfert),
                Credit_Base = Sum(IsNull(S.Credit_Base, 0)), 
                Majoration = Sum(IsNull(S.Majoration, 0))
            FROM
                #TB_Transfert_04_02 T
                LEFT JOIN #TB_Subvention_04_02 S ON S.ConventionID = T.ConventionID AND S.dtTransfert = T.dtTransfert
            GROUP BY
                T.ConventionID, T.ConventionNo, T.BeneficiaryID, T.dtEnregistrementRQ, T.dtTransfert, 
                T.vcNEQ_ExtPromo, T.vcRegimeNo_ExtPromo, T.vcConventionNo_ExtPromo
        )
        INSERT INTO dbo.tblIQEE_Transferts (
            iID_Fichier_IQEE, siAnnee_Fiscale, tiCode_Version, cStatut_Reponse, iID_Convention, vcNo_Convention, dtDate_Debut_Convention, iID_Sous_Type, 
            iID_Operation, dtDate_Transfert, mTotal_Transfert, mIQEE_CreditBase_Transfere, mIQEE_Majore_Transfere, mCotisations_Donne_Droit_IQEE, 
            ID_Autre_Promoteur, ID_Regime_Autre_Promoteur, vcNo_Contrat_Autre_Promoteur, 
            iID_Beneficiaire, vcNAS_Beneficiaire, vcNom_Beneficiaire, vcPrenom_Beneficiaire, dtDate_Naissance_Beneficiaire, tiSexe_Beneficiaire, 
            bTransfert_Total, bPRA_Deja_Verse, bTransfert_Autorise, mCotisations_Versees_Avant_Debut_IQEE, mCotisations_Non_Donne_Droit_IQEE
        )
        SELECT
            @iID_Fichier_IQEE, @siAnnee_Fiscale, @tiCode_Version, 'R', T.ConventionID, T.ConventionNo, T.dtEnregistrementRQ, @iID_SousTypeEnregistrement, 
            T.iID_Operation, T.dtTransfert, T.MontantTransfert, T.Credit_Base, T.Majoration, Ct.Solde_Ayant_Droit_IQEE, 
            T.vcNEQ_ExtPromo, T.vcRegimeNo_ExtPromo, T.vcConventionNo_ExtPromo,
            B.BeneficiaryID, B.vcNAS, Left(B.vcNom, 20), Left(B.vcPrenom, 20), B.dtNaissance, (SELECT ID FROM CTE_Sexe WHERE Code = B.cSexe),
            1, 0, @bTransfert_Autorise, Ct.TotalCotisationAvantIQEE, Ct.Solde_Non_Droit_IQEE
        FROM
            CTE_Transfert T
            JOIN #TB_Beneficiary_04_02 B ON B.BeneficiaryID = T.BeneficiaryID
            LEFT JOIN #TB_Cotisation_04_02 Ct ON Ct.ConventionID = T.ConventionID AND Ct.dtTransfert = T.dtTransfert

        SET @iCount = @@RowCount
        SET @ElapseTime = @QueryTimer - GetDate()
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    » ' + LTrim(Str(@iCount)) + ' enregistrements ajoutés (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'
    END

    SET @ElapseTime = GetDate() - @StartTimer
    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' EXEC psIQEE_CreerTransactions04_02 completed' 
                + ' (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

    IF OBJECT_ID('tempdb..#TB_Validation_04_02') IS NOT NULL
        DROP TABLE #TB_Validation_04_02
    IF OBJECT_ID('tempdb..#TB_Rejets_04_02') IS NOT NULL
        DROP TABLE #TB_Rejets_04_02
    IF OBJECT_ID('tempdb..#TB_Beneficiary_04_02') IS NOT NULL
        DROP TABLE #TB_Beneficiary_04_02
    IF OBJECT_ID('tempdb..#TB_Transfert_04_02') IS NOT NULL
        DROP TABLE #TB_Transfert_04_02

    -- Retourner 0 si le traitement est réussi
    RETURN 0
END
