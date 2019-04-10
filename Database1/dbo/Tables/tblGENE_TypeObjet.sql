CREATE TABLE [dbo].[tblGENE_TypeObjet] (
    [iID_TypeObjet]  INT           IDENTITY (1, 1) NOT NULL,
    [cCodeTypeObjet] CHAR (10)     NOT NULL,
    [vcDescription]  VARCHAR (250) NULL,
    [vcUrlAccess]    VARCHAR (250) NULL,
    CONSTRAINT [PK_GENE_TypeObjet] PRIMARY KEY CLUSTERED ([iID_TypeObjet] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table contenant les codes des objets avec l`URL associé', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_TypeObjet';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant du type d''objet', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_TypeObjet', @level2type = N'COLUMN', @level2name = N'iID_TypeObjet';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code identifiant du type d''objet', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_TypeObjet', @level2type = N'COLUMN', @level2name = N'cCodeTypeObjet';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description de l''objet', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_TypeObjet', @level2type = N'COLUMN', @level2name = N'vcDescription';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'lien url de l''objet', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_TypeObjet', @level2type = N'COLUMN', @level2name = N'vcUrlAccess';

