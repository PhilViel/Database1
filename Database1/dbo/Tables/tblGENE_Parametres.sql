CREATE TABLE [dbo].[tblGENE_Parametres] (
    [iID_Parametre_Applicatif] INT           IDENTITY (1, 1) NOT NULL,
    [iID_Type_Parametre]       INT           NOT NULL,
    [vcDimension1]             VARCHAR (100) NULL,
    [vcDimension2]             VARCHAR (100) NULL,
    [vcDimension3]             VARCHAR (100) NULL,
    [vcDimension4]             VARCHAR (100) NULL,
    [vcDimension5]             VARCHAR (100) NULL,
    [dtDate_Debut_Application] DATETIME      NOT NULL,
    [dtDate_Fin_Application]   DATETIME      NULL,
    [vcValeur_Parametre]       VARCHAR (MAX) NULL,
    CONSTRAINT [PK_GENE_Parametres] PRIMARY KEY CLUSTERED ([iID_Parametre_Applicatif] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_GENE_Parametres_GENE_TypesParametre__iIDTypeParametre] FOREIGN KEY ([iID_Type_Parametre]) REFERENCES [dbo].[tblGENE_TypesParametre] ([iID_Type_Parametre])
);


GO
CREATE NONCLUSTERED INDEX [IX_GENE_Parametres_iIDTypeParametre_vcDimension1_vcDimension2_vcDimension3_vcDimension4_vcDimension5]
    ON [dbo].[tblGENE_Parametres]([iID_Type_Parametre] ASC, [vcDimension1] ASC, [vcDimension2] ASC, [vcDimension3] ASC, [vcDimension4] ASC, [vcDimension5] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table contenant les paramètres applicatifs', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Parametres';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''une valeur d''un paramètre applicatif', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Parametres', @level2type = N'COLUMN', @level2name = N'iID_Parametre_Applicatif';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du type de paramètre du paramètre applicatif', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Parametres', @level2type = N'COLUMN', @level2name = N'iID_Type_Parametre';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Information de la dimension 1 du paramètre applicatif', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Parametres', @level2type = N'COLUMN', @level2name = N'vcDimension1';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Information de la dimension 2 du paramètre applicatif', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Parametres', @level2type = N'COLUMN', @level2name = N'vcDimension2';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Information de la dimension 3 du paramètre applicatif', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Parametres', @level2type = N'COLUMN', @level2name = N'vcDimension3';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Information de la dimension 4 du paramètre applicatif', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Parametres', @level2type = N'COLUMN', @level2name = N'vcDimension4';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Information de la dimension 5 du paramètre applicatif', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Parametres', @level2type = N'COLUMN', @level2name = N'vcDimension5';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date et heure de début d''application de la valeur du paramètre', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Parametres', @level2type = N'COLUMN', @level2name = N'dtDate_Debut_Application';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date et heure de fin d''application de la valeur du paramètre', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Parametres', @level2type = N'COLUMN', @level2name = N'dtDate_Fin_Application';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Valeur du paramètre dans les dates d''application selon les dimensions du paramètre applicatif', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Parametres', @level2type = N'COLUMN', @level2name = N'vcValeur_Parametre';

