CREATE TABLE [dbo].[Mo_Family] (
    [FamilyID]   [dbo].[MoID]          IDENTITY (1, 1) NOT NULL,
    [FamilyName] [dbo].[MoCompanyName] NOT NULL,
    CONSTRAINT [PK_Mo_Family] PRIMARY KEY CLUSTERED ([FamilyID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Tables des familles.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Family';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la famille.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Family', @level2type = N'COLUMN', @level2name = N'FamilyID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom de la famille.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Family', @level2type = N'COLUMN', @level2name = N'FamilyName';

