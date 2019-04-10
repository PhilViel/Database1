CREATE TABLE [dbo].[CRQ_DocTemplate] (
    [DocTemplateID]   INT         IDENTITY (1, 1) NOT NULL,
    [DocTypeID]       INT         NOT NULL,
    [ConnectID]       INT         NOT NULL,
    [LangID]          VARCHAR (3) NULL,
    [DocTemplateTime] DATETIME    CONSTRAINT [DF_CRQ_DocTemplate_DocTemplateTime] DEFAULT (getdate()) NOT NULL,
    [DocTemplate]     TEXT        NOT NULL,
    CONSTRAINT [PK_CRQ_DocTemplate] PRIMARY KEY CLUSTERED ([DocTemplateID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_CRQ_DocTemplate_CRQ_DocType__DocTypeID] FOREIGN KEY ([DocTypeID]) REFERENCES [dbo].[CRQ_DocType] ([DocTypeID])
);


GO
CREATE NONCLUSTERED INDEX [IX_CRQ_DocTemplate_DocTemplateID]
    ON [dbo].[CRQ_DocTemplate]([DocTemplateID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Elle contient les documents RTF qui sont les templates des documents.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_DocTemplate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du template', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_DocTemplate', @level2type = N'COLUMN', @level2name = N'DocTemplateID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du type de document (CRQ_DocType) auquel appartient ce formatage', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_DocTemplate', @level2type = N'COLUMN', @level2name = N'DocTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de connexion (Mo_Connect) de l''usager qui a inséré le template.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_DocTemplate', @level2type = N'COLUMN', @level2name = N'ConnectID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Langue du template', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_DocTemplate', @level2type = N'COLUMN', @level2name = N'LangID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date et heure d''entrée en vigueur du template', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_DocTemplate', @level2type = N'COLUMN', @level2name = N'DocTemplateTime';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Blob contenant le docuement RTF qui est le template', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_DocTemplate', @level2type = N'COLUMN', @level2name = N'DocTemplate';

