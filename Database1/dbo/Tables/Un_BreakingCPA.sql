CREATE TABLE [dbo].[Un_BreakingCPA] (
    [BreakingID]                    [dbo].[MoID]           IDENTITY (1, 1) NOT NULL,
    [ConventionID]                  [dbo].[MoID]           NOT NULL,
    [BreakingTypeID]                [dbo].[UnBreakingType] NOT NULL,
    [BreakingStartDate]             [dbo].[MoGetDate]      NOT NULL,
    [BreakingEndDate]               [dbo].[MoDateoption]   NULL,
    [BreakingReason]                [dbo].[MoDescoption]   NULL,
    [iID_Utilisateur_Creation]      INT                    NULL,
    [dtDate_Creation_Operation]     DATETIME               NULL,
    [iID_Utilisateur_Modification]  INT                    NULL,
    [dtDate_Modification_Operation] DATETIME               NULL,
    CONSTRAINT [PK_Un_BreakingCPA] PRIMARY KEY CLUSTERED ([BreakingID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_BreakingCPA_Un_Convention__ConventionID] FOREIGN KEY ([ConventionID]) REFERENCES [dbo].[Un_Convention] ([ConventionID])
);

