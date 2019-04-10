CREATE TABLE [dbo].[CHQ_CheckStubWithDetail] (
    [vcRefType] VARCHAR (10) NOT NULL,
    CONSTRAINT [PK_CHQ_CheckStubWithDetail] PRIMARY KEY CLUSTERED ([vcRefType] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table de type d''opération pour lesquelles les talons de chèques doivent être détaillés.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_CheckStubWithDetail';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Le type d''opération', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_CheckStubWithDetail', @level2type = N'COLUMN', @level2name = N'vcRefType';

