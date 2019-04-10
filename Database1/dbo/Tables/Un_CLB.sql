CREATE TABLE [dbo].[Un_CLB] (
    [OperID]        INT NOT NULL,
    [BeneficiaryID] INT NOT NULL,
    CONSTRAINT [PK_Un_CLB] PRIMARY KEY CLUSTERED ([OperID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des liens de compte de BEC', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CLB';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de l''opération.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CLB', @level2type = N'COLUMN', @level2name = N'OperID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID du bénéficiaire', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CLB', @level2type = N'COLUMN', @level2name = N'BeneficiaryID';

