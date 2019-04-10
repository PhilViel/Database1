CREATE TABLE [dbo].[Un_Account] (
    [iAccountID]          INT          IDENTITY (1, 1) NOT NULL,
    [vcAccount]           VARCHAR (75) NOT NULL,
    [vcClientDescription] VARCHAR (75) CONSTRAINT [DF_Un_Account_vcClientDescription] DEFAULT ('') NOT NULL,
    [vcCode_Compte]       VARCHAR (20) NULL,
    [iID_Regime]          INT          NULL,
    CONSTRAINT [PK_Un_Account] PRIMARY KEY CLUSTERED ([iAccountID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des comptes comptables', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Account';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du compte comptable', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Account', @level2type = N'COLUMN', @level2name = N'iAccountID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Compte comptable', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Account', @level2type = N'COLUMN', @level2name = N'vcAccount';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Description du compte inscrit sur les documents clients (Talons de chèques, etc.)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Account', @level2type = N'COLUMN', @level2name = N'vcClientDescription';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code interne et unique d''un compte comptable.  Ce code peut être codé en dur dans le développement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Account', @level2type = N'COLUMN', @level2name = N'vcCode_Compte';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du régime (Un_Plan) auquel appartient le compte comptable.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Account', @level2type = N'COLUMN', @level2name = N'iID_Regime';

