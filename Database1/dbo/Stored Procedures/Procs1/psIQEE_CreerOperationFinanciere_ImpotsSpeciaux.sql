/****************************************************************************************************
Copyrights (c) 2017 Gestion Universitas inc.

Nom du service : psIQEE_CreerOperationFinanciereIQE_DeclarationImpotsSpeciaux
But            : Créer l'opération IQE à afficher dans l'historique EAFB servant à décaisser ou encaisser 
                 les montants de crédit de base CBQ et de la majoration MMQ de l'IQEE dans la convention
                 donnée et insérer les numéros d’opérations CBQ et MMQ dans la table tblIQEE_ImpotsSpeciaux
                 qui sert à déclarer les impôts spéciaux.
Facette        : IQEE
Référence      : IQEE

Paramètres d’entrée    :
        Paramètre               Description
        --------------------    ---------------------------------
        iID_Utilisateur         ID de l'usager
        iID_FichierIQEE         ID du fichier contenant les impôts spéciaux déclarés
        iID_SousType            ID du sous-type d'enregistrement des impôts spéciaux déclarés

Paramètres de sortie:
        Champ                   Description
        --------------------    ---------------------------------

Exemple utilisation:                                                                                    
        EXEC psIQEE_CreerOperationFinanciereIQE_DeclarationImpotsSpeciaux 175,602654

Historique des modifications:
        Date        Programmeur             Description
        ----------  --------------------    --------------------------------------------------------
        2017-02-07  Steeve Picard           Création du service
        2017-06-08  Steeve Picard           Tenir compte des annulation lorsque tiCode_VersiON est à 1
        2017-09-27  Steeve Picard           Ajout du paramètre optionel «@iID_ImpotSpecial»
        2018-01-30  Steeve Picard           Changement pour ne considérer que la dernière transaction par convention
****************************************************************************************************/
CREATE PROCEDURE dbo.psIQEE_CreerOperationFinanciere_ImpotsSpeciaux
    @iID_Utilisateur    INT = NULL,
    @iID_FichierIQEE    INTEGER,
    @iID_SousType       INT,
    @iID_ImpotSpecial   INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTimer datetime = GetDate(),
            @QueryTimer datetime,
            @ElapseTime datetime,
            @iCount int = 0

    PRINT ''
    PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    EXEC psIQEE_CreerOperationFinanciere_ImpotsSpeciaux Started'

    -- Prendre l'utilisateur du système s'il est absent en paramètre ou inexistant
    IF @iID_Utilisateur IS NULL OR
        NOT EXISTS (SELECT * FROM dbo.Mo_User WHERE UserID = @iID_Utilisateur) 
       SELECT @iID_Utilisateur = iID_Utilisateur_Systeme
       FROM dbo.Un_Def

    DECLARE @dtToday date = GetDate(),
            @OperTypeID char(3) = (dbo.fnOPER_ObtenirTypesOperationCategorie('IQEE_CODE_INJECTION_MONTANT_CONVENTION')),
            @vcOPER_MONTANTS_CREDITBASE varchar(100) = (dbo.fnOPER_ObtenirTypesOperationConvCategorie('OPER_MONTANTS_CREDITBASE')),
            @vcOPER_MONTANTS_MAJORATION varchar(100) = (dbo.fnOPER_ObtenirTypesOperationConvCategorie('OPER_MONTANTS_MAJORATION')),
            @ConnectID INT = (SELECT MAX(ConnectID) FROM dbo.Mo_Connect WHERE UserID = @iID_Utilisateur)

    IF OBJECT_ID('tempDB..#TB_ImpotSpecial_OperFin') IS NOT NULL
        DROP TABLE #TB_ImpotSpecial_OperFin

    CREATE TABLE #TB_ImpotSpecial_OperFin (
        Row_Num INT NOT NULL,
        iID_Impot_Special int NOT NULL,
        iID_Convention int NOT NULL,
        tiCode_Version INT NOT NULL,
        iID_Oper int NULL,
        mSolde_IQEE_Base money NOT NULL,
        mSolde_IQEE_Majore money NOT NULL
    )

    PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    - Identifie le(s) impôts(s) spécial(s)'
    SET @QueryTimer = GetDate()
    
    ;WITH CTE_ImpotSpecial AS (
        select
            iID_Convention, iID_Impot_Special, tiCode_Version, cStatut_Reponse,
            mSolde_CBQ = mSolde_IQEE_Base, -- CASE cStatut_Reponse WHEN 'E' THEN -mSolde_IQEE_Base ELSE mSolde_IQEE_Base END, 
            mSolde_MMQ_Majore = mSolde_IQEE_Majore, -- CASE cStatut_Reponse WHEN 'E' THEN -mSolde_IQEE_Majore ELSE mSolde_IQEE_Majore END,
            ROW_NUMBER() OVER(PARTITION BY iID_Convention, iID_Sous_Type ORDER BY iID_Impot_Special DESC) AS Row_Num
        FROM
            dbo.tblIQEE_ImpotsSpeciaux
        WHERE
            iID_Fichier_IQEE = @iID_FichierIQEE
            AND iID_Sous_Type = @iID_SousType
            AND iID_Impot_Special = ISNULL(@iID_ImpotSpecial, iID_Impot_Special)
    )
    INSERT INTO #TB_ImpotSpecial_OperFin (
        Row_Num, iID_Impot_Special, iID_Convention, tiCode_Version, mSolde_IQEE_Base, mSolde_IQEE_Majore
    )
    SELECT
        Row_Number() OVER(ORDER BY iID_Impot_Special),
        iID_Impot_Special, iID_Convention, tiCode_Version,
        CASE tiCode_Version WHEN 1 THEN -mSolde_CBQ ELSE mSolde_CBQ END, 
        CASE tiCode_Version WHEN 1 THEN -mSolde_MMQ_Majore ELSE mSolde_MMQ_Majore END
    FROM
        CTE_ImpotSpecial
    WHERE
        Row_Num = 1
        AND (mSolde_CBQ <> 0 OR mSolde_MMQ_Majore <> 0)
    
    SET @iCount = @@RowCount
    SET @ElapseTime = @QueryTimer - GetDate()
    PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '      » ' + LTrim(Str(@iCount)) + ' retoruvé(s) (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR(20), @ElapseTime, 120), 6) + ')'

    IF dbo.FN_IsDebug() <> 0
        SELECT * FROM #TB_ImpotSpecial_OperFin

    PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    - Créé les opérations financières'
    SET @QueryTimer = GetDate()
    
    INSERT INTO dbo.Un_Oper (
        ConnectID,  OperTypeID, OperDate
    )
    SELECT
        @ConnectID, @OperTypeID, @dtToday
    FROM
        #TB_ImpotSpecial_OperFin
    
    SET @iCount = @@RowCount
    SET @ElapseTime = @QueryTimer - GetDate()
    PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '      » ' + LTrim(Str(@iCount)) + ' ajout(s) (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR(20), @ElapseTime, 120), 6) + ')'

    PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    - Récupère les ID des opérations financières générés'
    SET @QueryTimer = GetDate()
    
    ;WITH CTE_Oper as (
        SELECT
            OperID, ROW_NUMBER () OVER(Order By OperID) AS Row_Num
        FROM
            dbo.Un_Oper
        WHERE
            OperDate = @dtToday
            AND OperTypeID = @OperTypeID
            AND ConnectID = @ConnectID
            AND dtSequence_Operation >= @StartTimer
    )
    UPDATE I SET
        iID_Oper = O.OperID
    FROM
        #TB_ImpotSpecial_OperFin I
        JOIN CTE_Oper O ON O.Row_Num = I.Row_Num
    
    SET @iCount = @@RowCount
    SET @ElapseTime = @QueryTimer - GetDate()
    PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '      » ' + LTrim(Str(@iCount)) + ' récupéré(s) (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR(20), @ElapseTime, 120), 6) + ')'

    IF OBJECT_ID('tempDB..#TB_ConvOper_OperFin') IS NOT NULL
        DROP TABLE #TB_ConvOper_OperFin
    CREATE TABLE #TB_ConvOper_OperFin (ConventionOperID INT, OperID INT, ConventionID int, ConventionOperTypeID VARCHAR(3), ConventionOperAmount MONEY)

    PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    - Ajout des crédits de base d''IQÉÉ des conventions'
    SET @QueryTimer = GetDate()
    
    INSERT INTO dbo.Un_ConventionOper (
        OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
    )
    OUTPUT Inserted.* INTO #TB_ConvOper_OperFin
    SELECT
        iID_Oper, iID_Convention, @vcOPER_MONTANTS_CREDITBASE, -1 * mSolde_IQEE_Base
    FROM
        #TB_ImpotSpecial_OperFin
    WHERE
        mSolde_IQEE_Base <> 0
    
    SET @iCount = @@RowCount
    SET @ElapseTime = @QueryTimer - GetDate()
    PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '      » ' + LTrim(Str(@iCount)) + ' ajouté(s) (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR(20), @ElapseTime, 120), 6) + ')'

    PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    - Ajout des majorations d''IQÉÉ des conventions'
    SET @QueryTimer = GetDate()
    
    INSERT INTO dbo.Un_ConventionOper (
        OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
    )
    OUTPUT Inserted.* INTO #TB_ConvOper_OperFin
    SELECT
        iID_Oper, iID_Convention, @vcOPER_MONTANTS_MAJORATION, -1 * mSolde_IQEE_Majore
    FROM
        #TB_ImpotSpecial_OperFin
    WHERE
        mSolde_IQEE_Majore <> 0
    
    SET @iCount = @@RowCount
    SET @ElapseTime = @QueryTimer - GetDate()
    PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '      » ' + LTrim(Str(@iCount)) + ' ajouté(s) (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR(20), @ElapseTime, 120), 6) + ')'

    IF dbo.FN_IsDebug() <> 0
        SELECT * FROM #TB_ConvOper_OperFin

    PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    - Met à jour le ID de paiement du crédit de base de l''IQÉÉ des impôts spéciaux'
    SET @QueryTimer = GetDate()
    
    UPDATE I SET
        iID_Paiement_Impot_CBQ = CO.ConventionOperID
    FROM
        dbo.tblIQEE_ImpotsSpeciaux I
        JOIN #TB_ImpotSpecial_OperFin X ON X.iID_Impot_Special = I.iID_Impot_Special
        JOIN dbo.Un_ConventionOper CO ON CO.OperID = X.iID_Oper
    WHERE
        CO.ConventionOperTypeID = @vcOPER_MONTANTS_CREDITBASE
    
    SET @iCount = @@RowCount
    SET @ElapseTime = @QueryTimer - GetDate()
    PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '      » ' + LTrim(Str(@iCount)) + ' mis à jour (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR(20), @ElapseTime, 120), 6) + ')'

    PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    - Met à jour le ID de paiement de la majoration de l''IQÉÉ des impôts spéciaux'
    SET @QueryTimer = GetDate()
    
    UPDATE I SET
        iID_Paiement_Impot_MMQ = CO.ConventionOperID
    FROM
        dbo.tblIQEE_ImpotsSpeciaux I
        JOIN #TB_ImpotSpecial_OperFin X ON X.iID_Impot_Special = I.iID_Impot_Special
        JOIN dbo.Un_ConventionOper CO ON CO.OperID = X.iID_Oper
    WHERE
        CO.ConventionOperTypeID = @vcOPER_MONTANTS_MAJORATION
    
    SET @iCount = @@RowCount
    SET @ElapseTime = @QueryTimer - GetDate()
    PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '      » ' + LTrim(Str(@iCount)) + ' mis à jour (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR(20), @ElapseTime, 120), 6) + ')'

    SET @ElapseTime = GetDate() - @StartTimer
    PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    EXEC psIQEE_CreerOperationFinanciere_ImpotsSpeciaux completed' 
                + ' (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR(20), @ElapseTime, 120), 6) + ')'
    PRINT ''
END
