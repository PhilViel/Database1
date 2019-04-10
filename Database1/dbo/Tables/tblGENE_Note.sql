CREATE TABLE [dbo].[tblGENE_Note] (
    [iID_Note]            INT           IDENTITY (1, 1) NOT NULL,
    [tTexte]              TEXT          NULL,
    [vcTitre]             VARCHAR (250) NOT NULL,
    [dtDateCreation]      DATETIME      NOT NULL,
    [iID_TypeNote]        INT           NOT NULL,
    [iID_HumainClient]    INT           NOT NULL,
    [iID_HumainCreateur]  INT           NOT NULL,
    [vcTexteLienObjetLie] VARCHAR (250) NULL,
    [iId_Objetlie]        INT           NULL,
    [iId_TypeObjet]       INT           NULL,
    [iID_HumainModifiant] INT           NULL,
    [dtDateModification]  DATETIME      NULL,
    CONSTRAINT [PK_GENE_Note] PRIMARY KEY CLUSTERED ([iID_Note] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_GENE_Note_GENE_TypeNote__iIDTypeNote] FOREIGN KEY ([iID_TypeNote]) REFERENCES [dbo].[tblGENE_TypeNote] ([iId_TypeNote]),
    CONSTRAINT [FK_GENE_Note_GENE_TypeObjet__iIdTypeObjet] FOREIGN KEY ([iId_TypeObjet]) REFERENCES [dbo].[tblGENE_TypeObjet] ([iID_TypeObjet]),
    CONSTRAINT [FK_GENE_Note_Mo_Human__iIDHumainClient] FOREIGN KEY ([iID_HumainClient]) REFERENCES [dbo].[Mo_Human] ([HumanID]),
    CONSTRAINT [FK_GENE_Note_Mo_Human__iIDHumainCreateur] FOREIGN KEY ([iID_HumainCreateur]) REFERENCES [dbo].[Mo_Human] ([HumanID]),
    CONSTRAINT [FK_GENE_Note_Mo_Human__iIDHumainModifiant] FOREIGN KEY ([iID_HumainModifiant]) REFERENCES [dbo].[Mo_Human] ([HumanID])
);


GO
CREATE NONCLUSTERED INDEX [IX_GENE_Note_iIDHumainClient]
    ON [dbo].[tblGENE_Note]([iID_HumainClient] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table contenant les notes saisies dans le système', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Note';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'numéro identifiant d’une note', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Note', @level2type = N'COLUMN', @level2name = N'iID_Note';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'texte d’une note', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Note', @level2type = N'COLUMN', @level2name = N'tTexte';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'titre d’une note', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Note', @level2type = N'COLUMN', @level2name = N'vcTitre';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date de création de la note', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Note', @level2type = N'COLUMN', @level2name = N'dtDateCreation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant du type de note', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Note', @level2type = N'COLUMN', @level2name = N'iID_TypeNote';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant du client', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Note', @level2type = N'COLUMN', @level2name = N'iID_HumainClient';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant du créateur de la note', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Note', @level2type = N'COLUMN', @level2name = N'iID_HumainCreateur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant de l''objet lié à la note', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Note', @level2type = N'COLUMN', @level2name = N'iId_Objetlie';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant du type d''objet', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Note', @level2type = N'COLUMN', @level2name = N'iId_TypeObjet';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant de l''humain modifiant', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Note', @level2type = N'COLUMN', @level2name = N'iID_HumainModifiant';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date de modifiation de la note', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Note', @level2type = N'COLUMN', @level2name = N'dtDateModification';

