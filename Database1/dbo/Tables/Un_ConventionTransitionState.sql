CREATE TABLE [dbo].[Un_ConventionTransitionState] (
    [ConventionTransitionStateID] INT           IDENTITY (1, 1) NOT NULL,
    [ConventionID]                INT           NOT NULL,
    [TransitionCodeID]            INT           NOT NULL,
    [ParameterValues]             VARCHAR (100) NULL,
    [CreationDate]                DATETIME2 (7) CONSTRAINT [DF_Un_ConventionTransitionState_CreationDate] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_Un_ConventionTransitionState] PRIMARY KEY CLUSTERED ([ConventionTransitionStateID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [CK_Un_ConventionTransitionState_TransitionCodeID] CHECK ([TransitionCodeID]=(2) OR [TransitionCodeID]=(1) OR [TransitionCodeID]=(0)),
    CONSTRAINT [FK_Un_ConventionTransitionState_Un_Convention__ConventionID] FOREIGN KEY ([ConventionID]) REFERENCES [dbo].[Un_Convention] ([ConventionID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Type de transition (0 = TransitoireVersREEE1, 1 = PremierDepotConventionIndividuelleREEE)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ConventionTransitionState', @level2type = N'COLUMN', @level2name = N'TransitionCodeID';

