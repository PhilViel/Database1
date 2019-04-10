CREATE TABLE [dbo].[Un_ScholarshipStep] (
    [iScholarshipStepID]    INT      IDENTITY (1, 1) NOT NULL,
    [ScholarshipID]         INT      NULL,
    [iScholarshipStep]      INT      NULL,
    [dtScholarshipStepTime] DATETIME NULL,
    [ConnectID]             INT      NULL,
    [bOldPAE]               BIT      CONSTRAINT [DF_Un_ScholarshipStep_bOldPAE] DEFAULT (0) NULL,
    CONSTRAINT [PK_Un_ScholarshipStep] PRIMARY KEY CLUSTERED ([iScholarshipStepID] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_ScholarshipStep_iScholarshipStep]
    ON [dbo].[Un_ScholarshipStep]([iScholarshipStep] ASC)
    INCLUDE([ScholarshipID]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_ScholarshipStep_ScholarshipID_iScholarshipStep]
    ON [dbo].[Un_ScholarshipStep]([ScholarshipID] ASC, [iScholarshipStep] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table conservant l''historique des étapes des paiements de bourses fait dans l''outil.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ScholarshipStep';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l’historique des étapes.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ScholarshipStep', @level2type = N'COLUMN', @level2name = N'iScholarshipStepID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de la bourse à laquelle appartient l’historique.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ScholarshipStep', @level2type = N'COLUMN', @level2name = N'ScholarshipID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Étape (1 à 5).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ScholarshipStep', @level2type = N'COLUMN', @level2name = N'iScholarshipStep';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date et heure ou on a passé à cette étape.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ScholarshipStep', @level2type = N'COLUMN', @level2name = N'dtScholarshipStepTime';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de l’usager qui a provoqué le changement d’étape.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ScholarshipStep', @level2type = N'COLUMN', @level2name = N'ConnectID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Indique s''il s''agit du statut d''un PAE en cours de traitement dans l''outil (0) ou du statut d''un PAE qui n''est plus en traitement (1).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ScholarshipStep', @level2type = N'COLUMN', @level2name = N'bOldPAE';

