CREATE TABLE [dbo].[Mo_Dep] (
    [DepID]     [dbo].[MoID]       IDENTITY (1, 1) NOT NULL,
    [CompanyID] [dbo].[MoID]       NOT NULL,
    [AdrID]     [dbo].[MoIDoption] NULL,
    [DepType]   [dbo].[MoDep]      NOT NULL,
    [Att]       VARCHAR (150)      NULL,
    [Att2]      VARCHAR (150)      NULL,
    CONSTRAINT [PK_Mo_Dep] PRIMARY KEY CLUSTERED ([DepID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Mo_Dep_Mo_Company__CompanyID] FOREIGN KEY ([CompanyID]) REFERENCES [dbo].[Mo_Company] ([CompanyID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_Dep_DepType]
    ON [dbo].[Mo_Dep]([DepType] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_Dep_AdrID]
    ON [dbo].[Mo_Dep]([AdrID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_Dep_CompanyID]
    ON [dbo].[Mo_Dep]([CompanyID] ASC) WITH (FILLFACTOR = 90);


GO
GRANT SELECT
    ON OBJECT::[dbo].[Mo_Dep] TO PUBLIC
    AS [dbo];


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des départements de compagnie.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Dep';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du département.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Dep', @level2type = N'COLUMN', @level2name = N'DepID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la compagnie (Mo_Company) à laquelle appartient le département.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Dep', @level2type = N'COLUMN', @level2name = N'CompanyID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''adresse (Mo_Adr) du département.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Dep', @level2type = N'COLUMN', @level2name = N'AdrID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Un caractère désignant le type de département dont il s''agit. (''U''=Inconnu, ''H''=???, ''S''=Succursale, ''A''=Adresse)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Dep', @level2type = N'COLUMN', @level2name = N'DepType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom du contact de ce département.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Dep', @level2type = N'COLUMN', @level2name = N'Att';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Contact #2', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Dep', @level2type = N'COLUMN', @level2name = N'Att2';

