CREATE TABLE [dbo].[Un_ScholarshipBatchCheck] (
    [ScholarshipID] INT NOT NULL,
    [ConnectID]     INT NOT NULL,
    CONSTRAINT [PK_Un_ScholarshipBatchCheck] PRIMARY KEY CLUSTERED ([ScholarshipID] ASC, [ConnectID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table conservant les bourses cochées par un usager dans l''outil de paiement de bourses par batch.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ScholarshipBatchCheck';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la bourse', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ScholarshipBatchCheck', @level2type = N'COLUMN', @level2name = N'ScholarshipID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de connexion de l’usager qui a coché la bourse.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ScholarshipBatchCheck', @level2type = N'COLUMN', @level2name = N'ConnectID';

