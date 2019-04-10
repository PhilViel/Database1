CREATE TABLE [dbo].[CHQ_Template] (
    [iTemplateID]        INT           IDENTITY (1, 1) NOT NULL,
    [iCheckBookID]       INT           NOT NULL,
    [iTemplateType]      INT           NOT NULL,
    [iMaxStubDtlLines]   INT           NOT NULL,
    [vcTemplateName]     VARCHAR (100) NOT NULL,
    [txTemplateDocument] TEXT          NOT NULL,
    [cTemplateLanguage]  CHAR (3)      NOT NULL,
    [dtCreated]          DATETIME      CONSTRAINT [DF_CHQ_Template_dtCreated] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_CHQ_Template] PRIMARY KEY CLUSTERED ([iTemplateID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_CHQ_Template_CHQ_CheckBook__iCheckBookID] FOREIGN KEY ([iCheckBookID]) REFERENCES [dbo].[CHQ_CheckBook] ([iCheckBookID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'La table des modèles de chèques', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_Template';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID unique du template du chèque', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_Template', @level2type = N'COLUMN', @level2name = N'iTemplateID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID du livret de chèque.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_Template', @level2type = N'COLUMN', @level2name = N'iCheckBookID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Le type de template', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_Template', @level2type = N'COLUMN', @level2name = N'iTemplateType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nombre maximum de lignes pour écriture sur le chèque', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_Template', @level2type = N'COLUMN', @level2name = N'iMaxStubDtlLines';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Le nom de template du chèque', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_Template', @level2type = N'COLUMN', @level2name = N'vcTemplateName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Le texte du template du chèque', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_Template', @level2type = N'COLUMN', @level2name = N'txTemplateDocument';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'La langue du template du chèque', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_Template', @level2type = N'COLUMN', @level2name = N'cTemplateLanguage';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'La date de création', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_Template', @level2type = N'COLUMN', @level2name = N'dtCreated';

