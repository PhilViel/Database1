﻿CREATE TABLE [dbo].[tblGENE_Telephone] (
    [iID_Telephone]    INT          IDENTITY (1, 1) NOT NULL,
    [iID_Source]       INT          NOT NULL,
    [cType_Source]     CHAR (1)     CONSTRAINT [DF_GENE_Telephone_cTypeSource] DEFAULT ('H') NOT NULL,
    [vcTelephone]      VARCHAR (27) NOT NULL,
    [vcExtension]      VARCHAR (10) NULL,
    [iID_Type]         INT          NOT NULL,
    [dtDate_Debut]     DATE         NOT NULL,
    [dtDate_Fin]       DATE         NULL,
    [bPublic]          BIT          CONSTRAINT [DF_GENE_Telephone_bPublic] DEFAULT ((1)) NOT NULL,
    [bInvalide]        BIT          CONSTRAINT [DF_GENE_Telephone_bInvalide] DEFAULT ((0)) NOT NULL,
    [dtDate_Creation]  DATETIME     NOT NULL,
    [vcLogin_Creation] VARCHAR (50) NULL,
    CONSTRAINT [PK_GENE_Telephone] PRIMARY KEY NONCLUSTERED ([iID_Telephone] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE UNIQUE CLUSTERED INDEX [AK_GENE_Telephone_iIDSource_cTypeSource_iIDType_dtDateDebut]
    ON [dbo].[tblGENE_Telephone]([iID_Source] ASC, [cType_Source] ASC, [iID_Type] ASC, [dtDate_Debut] ASC);


GO
/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service        : TRG_GENE_Telephone_Historisation_D
But                    : Effectue un SOFT DELETE des téléphones dans tblGENE_Telephone lorsqu'on tente de les détruire

Historique des modifications:
    Date        Programmeur             Description                                        
    ----------  --------------------    -----------------------------------------    
    2015-05-27  Steve Picard            Création du service            
    2015-10-05  Steve Picard            Fixe des dates de fin
    2016-11-17  Steeve Picard           Changement du trigger en «INSTEAD OF»
*********************************************************************************************************************/
CREATE TRIGGER [dbo].[TRG_GENE_Telephone_Historisation_D] ON [dbo].[tblGENE_Telephone] INSTEAD OF DELETE
AS
BEGIN
    EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Start'

    -- *** AVERTISSEMENT *** Ce script doit toujours figurer en tête de trigger
    
    IF object_id('tempdb..#DisableTrigger') is null 
        CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))
    ELSE
    BEGIN
        -- Si la table #DisableTrigger est présente, il se pourrait que le trigger
        -- ne soit pas à exécuter
        IF EXISTS (SELECT 1 FROM #DisableTrigger WHERE OBJECT_NAME(@@PROCID) like vcTriggerName)
        BEGIN
            -- Ne pas faire le trigger
            EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Trigger Ignored'

            DELETE FROM TB
            FROM dbo.tblGENE_Telephone TB
            WHERE EXISTS(SELECT * FROM deleted WHERE iID_Telephone = TB.iID_Telephone)

            RETURN
        END
    END

    --    Bloque le trigger des DELETEs
    INSERT INTO #DisableTrigger VALUES('TRG_GENE_Telephone_Historisation_D')    
    INSERT INTO #DisableTrigger VALUES('TRG_GENE_Telephone_Historisation_U')    

    DECLARE @dtToday date = Cast(GetDate() as date),
            @vcLogin varchar(75) = dbo.GetUserContext()

    SELECT D.iID_Telephone, D.iID_Source, D.cType_Source, D.iID_Type, D.vcTelephone, D.vcExtension, D.bPublic, D.bInvalide, 
           D.dtDate_Debut, dtDate_Fin = CAST(NUll as DATE), dtDate_Creation = GetDate(), 
           vcLogin_Creation = CASE WHEN IsNull(D.vcLogin_Creation, '') = '' THEN @vcLogin ELSE D.vcLogin_Creation END,
           iID_Telephone_Before = (SELECT TOP 1 T.iID_Telephone FROM dbo.tblGENE_Telephone T 
                                    WHERE T.iID_Source = D.iID_Source AND T.cType_Source = D.cType_Source AND T.iID_Type = D.iID_Type
                                      AND T.dtDate_Debut < D.dtDate_Debut
                                    ORDER BY T.dtDate_Debut DESC),
           iID_Telephone_After = (SELECT Top 1 T.iID_Telephone FROM dbo.tblGENE_Telephone T 
                                   WHERE T.iID_Source = D.iID_Source AND T.cType_Source = D.cType_Source AND T.iID_Type = D.iID_Type
                                     AND T.dtDate_Debut > D.dtDate_Debut
                                   ORDER BY T.dtDate_Debut ASC)
      INTO #tbl_Telephone
	 FROM deleted D

    DECLARE @TB_Deleted TABLE (
                iID int, iIdSource int, cTypeSource char(1), iIdType int, dtDebut date, dtFin date
            )

    -- Efface ceux qui débutait aujourd'hui
    DELETE FROM TB_Current
    OUTPUT DELETED.iID_Telephone, DELETED.iID_Source, DELETED.cType_Source, DELETED.iID_Type, 
           DELETED.dtDate_Debut, deleted.dtDate_Fin INTO @TB_Deleted
      FROM dbo.tblGENE_Telephone TB_Current
           JOIN #tbl_Telephone D ON D.iID_Telephone = TB_Current.iID_Telephone
     WHERE TB_Current.dtDate_Debut >= @dtToday

    IF @@ROWCOUNT > 0
    BEGIN
        --  Réaligner la date de fin à la date de début suivant si elle l'était auparavant
        UPDATE TB_Before
           SET dtDate_Fin = TB_Current.dtFin
          FROM dbo.tblGENE_Telephone TB_Before
               JOIN @TB_Deleted TB_Current ON TB_Current.iIdSource = TB_Before.iID_Source And TB_Current.cTypeSource = TB_Before.cType_Source
                                          AND TB_Current.iIdType = TB_Before.iID_Type
         WHERE TB_Before.dtDate_Fin = TB_Current.dtDebut
    END

    DELETE FROM TB_Current
      FROM #tbl_Telephone TB_Current
           JOIN @TB_Deleted X ON x.iID = TB_Current.iID_Telephone

    DELETE FROM @TB_Deleted
    
    UPDATE TB_Current
       SET dtDate_Fin = @dtToday
      FROM dbo.tblGENE_Telephone TB_Current
           JOIN #tbl_Telephone D ON D.iID_Telephone = TB_Current.iID_Telephone
     WHERE TB_Current.dtDate_Fin IS NULL
/*
    --  Désactive en inscrivant la date du jour dans la date de fin
    UPDATE TB_Current SET dtDate_Fin = @dtToday
    OUTPUT DELETED.iID_Telephone, DELETED.iID_Source, DELETED.cType_Source, DELETED.iID_Type, 
           DELETED.dtDate_Debut, deleted.dtDate_Fin INTO @TB_Deleted
      FROM dbo.tblGENE_Telephone TB_Current
           JOIN deleted D ON D.iID_Telephone = TB_Current.iID_Telephone
     WHERE TB_Current.dtDate_Debut < @dtToday
       AND IsNull(TB_Current.dtDate_Fin, '9999-12-31') > @dtToday
    
    IF @@ROWCOUNT > 0
    BEGIN
        --  Réaligner la date de fin à la date de début suivant si elle l'était auparavant
        UPDATE TB_Before SET dtDate_Fin = TB_Current.dtDebut
          FROM dbo.tblGENE_Telephone TB_Before
               JOIN @TB_Deleted TB_Current ON TB_Current.iIdSource = TB_Before.iID_Source And TB_Current.cTypeSource = TB_Before.cType_Source
                                          AND TB_Current.iIdType = TB_Before.iID_Type
         WHERE TB_Before.dtDate_Fin = TB_Current.dtDebut

        --  Réaligner la date de début à la date de fin précédente si elle l'était auparavant
        UPDATE TB_After SET dtDate_Debut = TB_Current.dtFin
          FROM dbo.tblGENE_Telephone TB_After
               JOIN @TB_Deleted TB_Current ON TB_Current.iIdSource = TB_After.iID_Source And TB_Current.cTypeSource = TB_After.cType_Source
                                          AND TB_Current.iIdType = TB_After.iID_Type
         WHERE TB_After.dtDate_Debut = TB_Current.dtFin
    END
*/
    IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName Like 'TRG_GENE_Telephone_Historisation__'
    EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END

GO
/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service        : TRG_GENE_Telephone_Historisation_I
But                    : Insert des téléphone dans tblGENE_Telephone en mettant la date de fin du précédent

Historique des modifications:
    Date        Programmeur             Description                                        
    ----------  --------------------    -----------------------------------------    
    2015-05-27  Steeve Picard           Création du service            
    2015-10-05  Steeve Picard           Fixe des dates de fin
    2016-11-08  Steeve Picard           Changement du trigger en «INSTEAD OF»
*********************************************************************************************************************/
CREATE TRIGGER [dbo].[TRG_GENE_Telephone_Historisation_I] ON [dbo].[tblGENE_Telephone] INSTEAD OF INSERT
AS
BEGIN
    EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Start'

    -- *** AVERTISSEMENT *** Ce script doit toujours figurer en tête de trigger
    
    IF object_id('tempdb..#DisableTrigger') is null 
        CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))
    ELSE
    BEGIN
        -- Si la table #DisableTrigger est présente, il se pourrait que le trigger
        -- ne soit pas à exécuter
        IF EXISTS (SELECT 1 FROM #DisableTrigger WHERE OBJECT_NAME(@@PROCID) like vcTriggerName)
        BEGIN
            -- Ne pas faire le trigger
            EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Trigger Ignored'
          
            INSERT INTO dbo.tblGENE_Telephone(iID_Source, cType_Source, vcTelephone, vcExtension, iID_Type, dtDate_Debut, dtDate_Fin, bPublic, bInvalide, dtDate_Creation, vcLogin_Creation)
            SELECT iID_Source, cType_Source, vcTelephone, vcExtension, iID_Type, dtDate_Debut, dtDate_Fin, bPublic, bInvalide, dtDate_Creation, vcLogin_Creation
            FROM inserted
          
            RETURN
        END
    END

    --    Bloque le trigger des DELETEs
    INSERT INTO #DisableTrigger VALUES('TRG_GENE_Telephone_Historisation_I')    
    INSERT INTO #DisableTrigger VALUES('TRG_GENE_Telephone_Historisation_U')    

    DECLARE @dtNow as datetime = GetDate()
    DECLARE @dtToday date = Cast(@dtNow as date),
            @vcLogin varchar(75) = dbo.GetUserContext()

    SELECT I.iID_Source, I.cType_Source, I.iID_Type, I.vcTelephone, I.vcExtension, I.bPublic, I.bInvalide, I.dtDate_Debut, I.dtDate_Fin,
           iID_Telephone_Before = (SELECT TOP 1 T.iID_Telephone FROM dbo.tblGENE_Telephone T 
                                    WHERE T.iID_Source = I.iID_Source AND T.cType_Source = I.cType_Source AND T.iID_Type = I.iID_Type
                                      AND T.dtDate_Debut <= I.dtDate_Debut
                                    ORDER BY T.dtDate_Debut DESC),
           iID_Telephone_After = (SELECT Top 1 T.iID_Telephone FROM dbo.tblGENE_Telephone T 
                                   WHERE T.iID_Source = I.iID_Source AND T.cType_Source = I.cType_Source AND T.iID_Type = I.iID_Type
                                     AND T.dtDate_Debut >= I.dtDate_Debut
                                   ORDER BY T.dtDate_Debut ASC)
      INTO #tbl_Telephone
     FROM inserted I 

    -- Met à jour l'info du précédent s'il commence la même journée
    UPDATE TB_Before
       SET vcTelephone = TB_Current.vcTelephone,
           vcExtension = TB_Current.vcExtension,
           bPublic = TB_Current.bPublic,
           bInvalide = TB_Current.bInvalide,
           dtDate_Creation = @dtNow,
           vcLogin_Creation = @vcLogin
      FROM dbo.tblGENE_Telephone TB_Before
           JOIN #tbl_Telephone TB_Current ON TB_Current.iID_Telephone_Before = TB_Before.iID_Telephone
     WHERE TB_Before.dtDate_Debut = TB_Current.dtDate_Debut

    -- Met à jour l'info du suivant s'il commence la même journée
    UPDATE TB_After
       SET vcTelephone = TB_Current.vcTelephone,
           vcExtension = TB_Current.vcExtension,
           bPublic = TB_Current.bPublic,
           bInvalide = TB_Current.bInvalide,
           dtDate_Creation = @dtNow,
           vcLogin_Creation = @vcLogin
      FROM dbo.tblGENE_Telephone TB_After
           JOIN #tbl_Telephone TB_Current ON TB_Current.iID_Telephone_Before = TB_After.iID_Telephone
     WHERE TB_After.dtDate_Debut = TB_Current.dtDate_Debut

    -- Efface les enregistrements qui ont été mis à jour
    DELETE FROM TB_Current
      FROM #tbl_Telephone TB_Current
           LEFT JOIN dbo.tblGENE_Telephone TB_Before ON TB_Before.iID_Telephone = TB_Current.iID_Telephone_Before
           LEFT JOIN dbo.tblGENE_Telephone TB_After ON TB_After.iID_Telephone = TB_Current.iID_Telephone_Before
     WHERE TB_Before.dtDate_Debut = TB_Current.dtDate_Debut
        OR TB_After.dtDate_Debut = TB_Current.dtDate_Debut

    -- Met à jour la date de fin du précédent s'il y en a un
    UPDATE TB_Before
       SET dtDate_Fin = TB_Current.dtDate_Debut
      FROM dbo.tblGENE_Telephone TB_Before
           JOIN #tbl_Telephone TB_Current ON TB_Current.iID_Telephone_Before = TB_Before.iID_Telephone
     WHERE TB_Before.dtDate_Debut < TB_Current.dtDate_Debut

    -- Met à jour la date de fin du courrant avec la date du suivant s'il y en a un
    UPDATE TB_Current
       SET dtDate_Fin = TB_After.dtDate_Debut
      FROM dbo.tblGENE_Telephone TB_After
           JOIN #tbl_Telephone TB_Current ON TB_Current.iID_Telephone_After = TB_After.iID_Telephone
     WHERE TB_After.dtDate_Debut > TB_Current.dtDate_Debut

    --  Insère ceux restants dont la date début est nouvelle 
    INSERT INTO dbo.tblGENE_Telephone (
        iID_Source, cType_Source, 
        iID_Type, vcTelephone, vcExtension, 
        dtDate_Debut, dtDate_Fin, 
        bPublic, bInvalide, 
        dtDate_Creation, vcLogin_Creation 
    )
    SELECT
        iID_Source, cType_Source, 
        iID_Type, vcTelephone, vcExtension, 
        dtDate_Debut, dtDate_Fin, 
        bPublic, bInvalide, 
        @dtNow, @vcLogin
    FROM
        #tbl_Telephone

    IF @@RowCount > 0
        SELECT iID_Telephone = IDENT_CURRENT('dbo.tblGENE_Telephone')

    IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName Like 'TRG_GENE_Telephone_Historisation__'
    EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END

GO
/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service        : TtblGENE_Adresse
But                    : Effectue un SOFT DELETE des téléphones dans tblGENE_Telephone lorsqu'on tente de les détruire

Historique des modifications:
    Date        Programmeur             Description                                        
    ----------  --------------------    -----------------------------------------    
    2015-05-27  Steeve Picard           Création du service            
    2016-07-25  Steeve Picard           Correction d'historisation
    2016-10-26  Steeve Picard           Correction de l'extension qui se perdait
    2016-11-18  Steeve Picard           Changement du trigger en «INSTEAD OF»
*********************************************************************************************************************/
CREATE TRIGGER [dbo].[TRG_GENE_Telephone_Historisation_U] ON [dbo].[tblGENE_Telephone] INSTEAD OF UPDATE
AS
BEGIN
    EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Start'

    -- *** AVERTISSEMENT *** Ce script doit toujours figurer en tête de trigger
    
    IF object_id('tempdb..#DisableTrigger') is null 
        CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))
    ELSE
    BEGIN
        -- Si la table #DisableTrigger est présente, il se pourrait que le trigger
        -- ne soit pas à exécuter
        IF EXISTS (SELECT 1 FROM #DisableTrigger WHERE OBJECT_NAME(@@PROCID) like vcTriggerName)
        BEGIN
            -- Ne pas faire le trigger
            EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Trigger Ignored'
          
            UPDATE TB SET
                iID_Source = I.iID_Source,
                cType_Source = I.cType_Source,
                vcTelephone = I.vcTelephone,
                vcExtension = I.vcExtension,
                iID_Type = I.iID_Type,
                dtDate_Debut = I.dtDate_Debut,
                dtDate_Fin = I.dtDate_Fin,
                bPublic = I.bPublic,
                bInvalide = I .bInvalide,
                dtDate_Creation = I.dtDate_Creation,
                vcLogin_Creation = I.vcLogin_Creation
            FROM dbo.tblGENE_Telephone TB JOIN inserted I ON I.iID_Telephone = TB.iID_Telephone

            RETURN
        END
    END

    ----    Bloque certains triggers de la table tblGENE_Telephone
    --INSERT INTO #DisableTrigger VALUES('TRG_GENE_Telephone_Historisation_D')    
    INSERT INTO #DisableTrigger VALUES('TRG_GENE_Telephone_Historisation_I')    
    INSERT INTO #DisableTrigger VALUES('TRG_GENE_Telephone_Historisation_U')    

    DECLARE @dtNow as datetime = GetDate()
    DECLARE @dtToday date = Cast(@dtNow as date),
            @vcLogin varchar(75) = dbo.GetUserContext()

    SELECT I.iID_Source, I.cType_Source, I.iID_Type, I.vcTelephone, I.vcExtension, I.bPublic, I.bInvalide, I.dtDate_Debut, I.dtDate_Fin,
           iID_Telephone_Before = (SELECT TOP 1 T.iID_Telephone FROM dbo.tblGENE_Telephone T 
                                    WHERE T.iID_Source = I.iID_Source AND T.cType_Source = I.cType_Source AND T.iID_Type = I.iID_Type
                                      AND T.dtDate_Debut <= I.dtDate_Debut
                                    ORDER BY T.dtDate_Debut DESC),
           iID_Telephone_After = (SELECT Top 1 T.iID_Telephone FROM dbo.tblGENE_Telephone T 
                                   WHERE T.iID_Source = I.iID_Source AND T.cType_Source = I.cType_Source AND T.iID_Type = I.iID_Type
                                     AND T.dtDate_Debut >= I.dtDate_Debut
                                   ORDER BY T.dtDate_Debut ASC)
      INTO #tbl_Telephone
      FROM inserted I JOIN deleted D ON D.iID_Telephone = I.iID_Telephone
     WHERE I.iID_Source <> D.iID_Source OR I.cType_Source <> D.cType_Source
        OR I.iID_Type <> D.iID_Type OR I.vcTelephone <> D.vcTelephone OR IsNull(I.vcExtension, '') <> IsNull(D.vcExtension, '')
        OR I.bPublic <> D.bPublic OR I.bInvalide <> D.bInvalide
        OR I.dtDate_Debut <> D.dtDate_Debut OR IsNull(I.dtDate_Fin, '9999-12-31') <> IsNull(D.dtDate_Fin, '9999-12-31')

    -- Met à jour l'info du précédent s'il commence la même journée
    UPDATE TB_Before
       SET vcTelephone = TB_Current.vcTelephone,
           vcExtension = TB_Current.vcExtension,
           bPublic = TB_Current.bPublic,
           bInvalide = TB_Current .bInvalide,
           dtDate_Creation = @dtNow,
           vcLogin_Creation = @vcLogin
      FROM dbo.tblGENE_Telephone TB_Before
           JOIN #tbl_Telephone TB_Current ON TB_Current.iID_Telephone_Before = TB_Before.iID_Telephone
     WHERE TB_Before.dtDate_Debut = TB_Current.dtDate_Debut

    -- Met à jour l'info du suivant s'il commence la même journée
    UPDATE TB_After
       SET vcTelephone = TB_Current.vcTelephone,
           vcExtension = TB_Current.vcExtension,
           bPublic = TB_Current.bPublic,
           bInvalide = TB_Current .bInvalide,
           dtDate_Creation = @dtNow,
           vcLogin_Creation = @vcLogin
      FROM dbo.tblGENE_Telephone TB_After
           JOIN #tbl_Telephone TB_Current ON TB_Current.iID_Telephone_Before = TB_After.iID_Telephone
     WHERE TB_After.dtDate_Debut = TB_Current.dtDate_Debut

    -- Efface les enregistrements qui ont été mis à jour
    DELETE FROM TB_Current
      FROM #tbl_Telephone TB_Current
           LEFT JOIN dbo.tblGENE_Telephone TB_Before ON TB_Before.iID_Telephone = TB_Current.iID_Telephone_Before
           LEFT JOIN dbo.tblGENE_Telephone TB_After ON TB_After.iID_Telephone = TB_Current.iID_Telephone_Before
     WHERE TB_Before.dtDate_Debut = TB_Current.dtDate_Debut
        OR TB_After.dtDate_Debut = TB_Current.dtDate_Debut

    -- Met à jour la date de fin du précédent s'il y en a un
    UPDATE TB_Before
       SET dtDate_Fin = TB_Current.dtDate_Debut
      FROM dbo.tblGENE_Telephone TB_Before
           JOIN #tbl_Telephone TB_Current ON TB_Current.iID_Telephone_Before = TB_Before.iID_Telephone
     WHERE TB_Before.dtDate_Debut < TB_Current.dtDate_Debut

    -- Met à jour la date de fin du courrant avec la date du suivant s'il y en a un
    UPDATE TB_Current
       SET dtDate_Fin = TB_After.dtDate_Debut
      FROM #tbl_Telephone TB_Current
           LEFT JOIN dbo.tblGENE_Telephone TB_After ON TB_After.iID_Telephone = TB_Current.iID_Telephone_After
     WHERE TB_Current.dtDate_Fin < IsNull(TB_After.dtDate_Debut, '9999-12-31')

    --  Insère ceux restants dont la date début est nouvelle 
    INSERT INTO dbo.tblGENE_Telephone (
        iID_Source, cType_Source, 
        iID_Type, vcTelephone, vcExtension, 
        dtDate_Debut, dtDate_Fin, 
        bPublic, bInvalide, 
        dtDate_Creation, vcLogin_Creation 
    )
    SELECT
        iID_Source, cType_Source, 
        iID_Type, vcTelephone, vcExtension, 
        dtDate_Debut, dtDate_Fin, 
        bPublic, bInvalide, 
        @dtNow, @vcLogin 
    FROM
        #tbl_Telephone

    --UPDATE TB_Current SET dtDate_Fin = TB_After.dtDate_Debut
    --  FROM #tbl_Telephone TB_Current 
    --       JOIN tblGENE_Telephone TB_After ON TB_After.iID_Telephone = TB_Current.iID_Telephone_After

    --INSERT INTO tblGENE_Telephone (
    --           iID_Source, cType_Source, iID_Type, vcTelephone, vcExtension, bPublic, bInvalide, 
    --           dtDate_Debut, dtDate_Fin, dtDate_Creation, vcLogin_Creation
    --       )
    --SELECT iID_Source, cType_Source, iID_Type, vcTelephone, vcExtension, bPublic, bInvalide, 
    --       dtDate_Debut, dtDate_Fin, GetDate(), vcLogin_Creation
    --  FROM #tbl_Telephone

    IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName Like 'TRG_GENE_Telephone_Historisation__'
    EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END

GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Cette table contient les numéros de téléphone des humains et des compagnies.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Telephone';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Type de téléphone (1: résidence, 2: cellulaire, 4: travail, 8: télécopieur, 16: autre).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Telephone', @level2type = N'COLUMN', @level2name = N'iID_Type';

