CREATE TABLE [dbo].[tblCONV_CourrielConsentement] (
    [iID_CourrielConsentement] INT          IDENTITY (1, 1) NOT NULL,
    [iID_Human]                INT          NOT NULL,
    [iID_CourrielTypeEnvoi]    INT          NOT NULL,
    [bAutoriser]               BIT          NULL,
    [dtDate_Creation]          DATETIME     CONSTRAINT [DF_CONV_CourrielConsentement_dtDateCreation] DEFAULT (getdate()) NOT NULL,
    [vcLogin_Creation]         VARCHAR (50) CONSTRAINT [DF_CONV_CourrielConsentement_vcLoginCreation] DEFAULT ([dbo].[GetUserContext]()) NOT NULL,
    [dtDate_Modification]      DATETIME     NULL,
    [vcLogin_Modification]     VARCHAR (50) NULL,
    CONSTRAINT [PK_CONV_CourrielConsentement] PRIMARY KEY CLUSTERED ([iID_CourrielConsentement] ASC),
    CONSTRAINT [FK_CONV_CourrielConsentement_CONV_CourrielTypeEnvoi__iIDCourrielTypeEnvoi] FOREIGN KEY ([iID_CourrielTypeEnvoi]) REFERENCES [dbo].[tblCONV_CourrielTypeEnvoi] ([iID_CourrielTypeEnvoi]),
    CONSTRAINT [FK_CONV_CourrielConsentement_Mo_Human__iIDHuman] FOREIGN KEY ([iID_Human]) REFERENCES [dbo].[Mo_Human] ([HumanID])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_CONV_CourrielConsentement_iIDHuman_iIDCourrielTypeEnvoi]
    ON [dbo].[tblCONV_CourrielConsentement]([iID_Human] ASC, [iID_CourrielTypeEnvoi] ASC);


GO
/**********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service : tblCONV_CourrielConsentement_U
But                : Met à jour des Consentement dans tblCONV_CourrielConsentement en mettant la date & la personne qui
                  a fait la modifiaction

Historique des modifications:
    Date            Programmeur                    Description                                        
    ----------      ------------------------    -----------------------------------------------------------------------
    2016-05-30        Steve Picard                Création du service            

***********************************************************************************************************************/
CREATE TRIGGER [dbo].[trgCONV_CourrielConsentement_D] ON [dbo].[tblCONV_CourrielConsentement] FOR DELETE
AS
BEGIN
    -- *** AVERTISSEMENT *** Ce script doit toujours figurer en tête de trigger
    DECLARE @vcTriggerName varchar(50) = OBJECT_NAME(@@PROCID)
    
    IF object_id('tempdb..#DisableTrigger') is null 
        CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))
    ELSE
    BEGIN
        -- Si la table #DisableTrigger est présente, il se pourrait que le trigger
        -- ne soit pas à exécuter
        IF EXISTS (SELECT 1 FROM #DisableTrigger WHERE @vcTriggerName like vcTriggerName)
        BEGIN
            -- Ne pas faire le trigger
            EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Trigger Ignored'
            RETURN
        END
    END
    PRINT @vcTriggerName + ' - Start'

    RAISERROR ('Les Consentement ne peuvent être effacés', 16, 0)
    
    PRINT @vcTriggerName + ' - End'
END

GO
/**********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service : tblCONV_CourrielConsentement_I
But                : Met à jour des Consentement dans tblCONV_CourrielConsentement en mettant la date & la personne qui
                  a fait la création

Historique des modifications:
    Date        Programmeur                 Description                                        
    ----------  ------------------------    -----------------------------------------------------------------------
    2016-05-30  Steve Picard                Création du service            
    2018-12-17  Steve Picard                Ajout du «LoginName» dans la table de log «CRQ_Log»
***********************************************************************************************************************/
CREATE TRIGGER dbo.trgCONV_CourrielConsentement_I ON dbo.tblCONV_CourrielConsentement FOR INSERT
AS
BEGIN
    -- *** AVERTISSEMENT *** Ce script doit toujours figurer en tête de trigger
    DECLARE @vcTriggerName varchar(50) = OBJECT_NAME(@@PROCID),
            @Now datetime = GetDate()
    
    IF object_id('tempdb..#DisableTrigger') is null 
        CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))
    ELSE
    BEGIN
        -- Si la table #DisableTrigger est présente, il se pourrait que le trigger
        -- ne soit pas à exécuter
        IF EXISTS (SELECT 1 FROM #DisableTrigger WHERE @vcTriggerName like vcTriggerName)
        BEGIN
            -- Ne pas faire le trigger
            EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Trigger Ignored'
            RETURN
        END
    END
    PRINT @vcTriggerName + ' - Start'

    --    Bloque le trigger des DELETEs
    INSERT INTO #DisableTrigger VALUES(@vcTriggerName)    

    --UPDATE T
    --   SET vcLogin_Creation = CASE WHEN IsNull(I.vcLogin_Creation, '') = '' THEN dbo.GetUserContext() 
    --                               ELSE I.vcLogin_Creation 
    --                          END,
       --    dtDate_Creation = IsNull(I.dtDate_Creation, @Now)
    --  FROM dbo.tblCONV_CourrielConsentement T JOIN inserted I ON I.iID_CourrielConsentement = T.iID_CourrielConsentement
    
    DECLARE @TB_Human TABLE (HumanID int, HumanType char(1), tiCESPStateOld int)

    INSERT INTO @TB_Human (HumanID, HumanType)
    SELECT H.iID_Human, CASE WHEN B.BeneficiaryID IS NOT NULL THEN 'B'
                               WHEN S.SubscriberID IS NOT NULL THEN 'S'
                               WHEN T.iTutorID IS NOT NULL THEN 'T'
                          END
      FROM inserted H LEFT JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = H.iID_Human
                      LEFT JOIN dbo.Un_Subscriber S ON S.SubscriberID = H.iID_Human
                      LEFT JOIN dbo.Un_Tutor T ON T.iTutorID = H.iID_Human
     WHERE Coalesce(B.BeneficiaryID, S.SubscriberID, T.iTutorID, 0) > 0
     
    DECLARE @RecSep CHAR(1) = CHAR(30)
        ,    @CrLf CHAR(2) = CHAR(13) + CHAR(10)
        ,   @ActionID int = (SELECT LogActionID FROM CRQ_LogAction WHERE LogActionShortName = 'I')
        ,    @iID_Utilisateur INT = (SELECT iID_Utilisateur_Systeme FROM dbo.Un_Def)

    ;WITH CTE_Human (iID_Human, cHumanType, bAutoriser, iID_CourrielTypeEnvoi, vcLogin) 
    as (
        SELECT I.iID_Human,
               CASE WHEN B.BeneficiaryID IS NOT NULL THEN 'B'
                    WHEN S.SubscriberID IS NOT NULL THEN 'S'
                    WHEN T.iTutorID IS NOT NULL THEN 'T'
                    WHEN R.RepID IS NOT NULL THEN 'R'
               END,
               I.bAutoriser, I.iID_CourrielTypeEnvoi, vcLogin_Creation
          FROM inserted I
               LEFT JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = I.iID_Human
               LEFT JOIN dbo.Un_Subscriber S ON S.SubscriberID = I.iID_Human
               LEFT JOIN dbo.Un_Tutor T ON T.iTutorID = I.iID_Human
               LEFT JOIN dbo.Un_Rep R ON R.RepID = I.iID_Human
    )
    INSERT INTO CRQ_Log (ConnectID, LogTableName, LogCodeID, LogTime, LogActionID, LogDesc, LogText, LoginName)
            SELECT
                2, 
                CASE cHumanType
                     WHEN 'B' THEN 'Un_Beneficiary'
                     WHEN 'S' THEN 'Un_Subscriber'
                     WHEN 'T' THEN 'Un_Tutor'
                     WHEN 'R' THEN 'Un_Rep'
                END, 
                I.iID_Human, @Now, @ActionID, 
                LogDesc = CASE cHumanType 
                               WHEN 'B' THEN 'Bénéficiaire'
                               WHEN 'S' THEN 'Souscripteur'
                               WHEN 'T' THEN 'Tuteur'
                               WHEN 'R' THEN 'Représentant'
                          END + ' : ' + (H.LastName + ', ' + H.FirstName), 
                LogText = '' +
                    'Consentement - ' + T.vcLibelleFrancais + @RecSep 
                                      + CASE WHEN I.bAutoriser = 1 THEN 'Client'
                                             WHEN I.bAutoriser = 0 THEN 'Révoqué'
                                             ELSE 'Contrat'
                                        END
									  + @RecSep + @CrLf +
                    '', 
                LTRIM(STR(I.iID_Human, 15)) + ' (' + vcLogin + ')'
            FROM
                CTE_Human I
                JOIN ProAcces.Mo_Human H ON H.HumanID = I.iID_Human
                JOIN dbo.tblCONV_CourrielTypeEnvoi T ON T.iID_CourrielTypeEnvoi = I.iID_CourrielTypeEnvoi

    IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName = @vcTriggerName

    EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
    PRINT @vcTriggerName + ' - End'
END

GO
/**********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service : tblCONV_CourrielConsentement_U
But                : Met à jour des Consentement dans tblCONV_CourrielConsentement en mettant la date & la personne qui
                  a fait la modifiaction

Historique des modifications:
    Date        Programmeur                 Description                                        
    ----------  ------------------------    -----------------------------------------------------------------------
    2016-05-30  Steve Picard                Création du service            
    2018-12-17  Steve Picard                Ajout du «LoginName» dans la table de log «CRQ_Log»
***********************************************************************************************************************/
CREATE TRIGGER dbo.trgCONV_CourrielConsentement_U ON dbo.tblCONV_CourrielConsentement FOR UPDATE
AS
BEGIN
    -- *** AVERTISSEMENT *** Ce script doit toujours figurer en tête de trigger
    DECLARE @vcTriggerName varchar(50) = OBJECT_NAME(@@PROCID),
            @Now datetime = GetDate()
    
    IF object_id('tempdb..#DisableTrigger') is null 
        CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))
    ELSE
    BEGIN
        -- Si la table #DisableTrigger est présente, il se pourrait que le trigger
        -- ne soit pas à exécuter
        IF EXISTS (SELECT 1 FROM #DisableTrigger WHERE @vcTriggerName like vcTriggerName)
        BEGIN
            -- Ne pas faire le trigger
            EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Trigger Ignored'
            RETURN
        END
    END
    PRINT @vcTriggerName + ' - Start'

    --    Bloque le trigger des DELETEs
    INSERT INTO #DisableTrigger VALUES(@vcTriggerName)    

    UPDATE T
       SET vcLogin_Modification = CASE WHEN IsNull(I.vcLogin_Modification, '') = '' THEN dbo.GetUserContext() 
                                       ELSE I.vcLogin_Modification 
                                  END,
           dtDate_Modification = IsNull(I.dtDate_Modification, @Now)
      FROM dbo.tblCONV_CourrielConsentement T JOIN inserted I ON I.iID_CourrielConsentement = T.iID_CourrielConsentement
    
    DECLARE @TB_Human TABLE (HumanID int, HumanType char(1), tiCESPStateOld int)

    INSERT INTO @TB_Human (HumanID, HumanType)
    SELECT H.iID_Human, CASE WHEN B.BeneficiaryID IS NOT NULL THEN 'B'
                               WHEN S.SubscriberID IS NOT NULL THEN 'S'
                               WHEN T.iTutorID IS NOT NULL THEN 'T'
                         END
      FROM inserted H LEFT JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = H.iID_Human
                      LEFT JOIN dbo.Un_Subscriber S ON S.SubscriberID = H.iID_Human
                      LEFT JOIN dbo.Un_Tutor T ON T.iTutorID = H.iID_Human
     WHERE Coalesce(B.BeneficiaryID, S.SubscriberID, T.iTutorID, 0) > 0
     
    DECLARE @RecSep CHAR(1) = CHAR(30)
        ,    @CrLf CHAR(2) = CHAR(13) + CHAR(10)
        ,   @ActionID int = (SELECT LogActionID FROM CRQ_LogAction WHERE LogActionShortName = 'U')
        ,    @iID_Utilisateur INT = (SELECT iID_Utilisateur_Systeme FROM dbo.Un_Def)

    ;WITH CTE_New (iID_CourrielConsentement, iID_Human, cHumanType, bAutoriser, iID_CourrielTypeEnvoi, vclogin) 
    as (
        SELECT I.iID_CourrielConsentement, I.iID_Human,
               CASE WHEN B.BeneficiaryID IS NOT NULL THEN 'B'
                    WHEN S.SubscriberID IS NOT NULL THEN 'S'
                    WHEN T.iTutorID IS NOT NULL THEN 'T'
                    WHEN R.RepID IS NOT NULL THEN 'R'
               END,
               I.bAutoriser, I.iID_CourrielTypeEnvoi, I.vcLogin_Modification
          FROM inserted I
               LEFT JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = I.iID_Human
               LEFT JOIN dbo.Un_Subscriber S ON S.SubscriberID = I.iID_Human
               LEFT JOIN dbo.Un_Tutor T ON T.iTutorID = I.iID_Human
               LEFT JOIN dbo.Un_Rep R ON R.RepID = I.iID_Human
    ),
    CTE_Old (iID_CourrielConsentement, bAutoriser) 
    as (
        SELECT D.iID_CourrielConsentement, D.bAutoriser
          FROM deleted D
               JOIN CTE_New I ON I.iID_CourrielConsentement = D.iID_CourrielConsentement
    )
    INSERT INTO CRQ_Log (ConnectID, LogTableName, LogCodeID, LogTime, LogActionID, LogDesc, LogText, LoginName)
        SELECT
            2, 
            CASE cHumanType
                 WHEN 'B' THEN 'Un_Beneficiary'
                 WHEN 'S' THEN 'Un_Subscriber'
                 WHEN 'T' THEN 'Un_Tutor'
                 WHEN 'R' THEN 'Un_Rep'
            END, 
            New.iID_Human, @Now, @ActionID, 
            LogDesc = CASE New.cHumanType 
                           WHEN 'B' THEN 'Bénéficiaire'
                           WHEN 'S' THEN 'Souscripteur'
                           WHEN 'T' THEN 'Tuteur'
                           WHEN 'R' THEN 'Représentant'
                      END + ' : ' + (H.LastName + ', ' + H.FirstName), 
            LogText = '' +
                CASE WHEN Old.bAutoriser = New.bAutoriser THEN ''
                     ELSE 'Consentement - ' + T.vcLibelleFrancais 
                                            + @RecSep + IsNull(Str(Old.bAutoriser,1), '') + @RecSep + IsNull(Str(New.bAutoriser,1), '')
                                            + @RecSep + CASE WHEN Old.bAutoriser = 1 THEN 'Client'
                                                             WHEN Old.bAutoriser = 0 THEN 'Révoqué'
                                                             ELSE 'Contrat'
                                                        END
                                            + @RecSep + CASE WHEN New.bAutoriser = 1 THEN 'Client'
                                                             WHEN New.bAutoriser = 0 THEN 'Révoqué'
                                                             ELSE 'Contrat'
                                                        END
										    + @RecSep + @CrLf
                END,
            LTRIM(STR(New.iID_Human, 15)) + ' (' + vcLogin + ')'
        FROM
            CTE_New New
            JOIN CTE_Old Old ON Old.iID_CourrielConsentement = New.iID_CourrielConsentement
            JOIN ProAcces.Mo_Human H ON H.HumanID = New.iID_Human
            JOIN dbo.tblCONV_CourrielTypeEnvoi T ON T.iID_CourrielTypeEnvoi = New.iID_CourrielTypeEnvoi

    IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName = @vcTriggerName

    EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
    PRINT @vcTriggerName + ' - End'
END
