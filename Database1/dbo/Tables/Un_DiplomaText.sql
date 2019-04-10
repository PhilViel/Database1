CREATE TABLE [dbo].[Un_DiplomaText] (
    [DiplomaTextID] INT           IDENTITY (1, 1) NOT NULL,
    [DiplomaText]   VARCHAR (150) CONSTRAINT [DF_Un_DiplomaText_DiplomaText] DEFAULT ('') NOT NULL,
    [VisibleInList] BIT           CONSTRAINT [DF_Un_DiplomaText_VisibleInList] DEFAULT (1) NULL,
    CONSTRAINT [PK_Un_DiplomaText] PRIMARY KEY CLUSTERED ([DiplomaTextID] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_DiplomaText_DiplomaTextID_DiplomaText]
    ON [dbo].[Un_DiplomaText]([DiplomaTextID] ASC, [DiplomaText] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des textes des diplômes.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_DiplomaText';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID Unique du texte du diplôme', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_DiplomaText', @level2type = N'COLUMN', @level2name = N'DiplomaTextID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Le texte du diplôme', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_DiplomaText', @level2type = N'COLUMN', @level2name = N'DiplomaText';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs boolean indiquant si ce texte est disponible dans la liste des textes de diplômes lors de la création ou modification d''une convention. (=0:Non, <>0:Oui)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_DiplomaText', @level2type = N'COLUMN', @level2name = N'VisibleInList';

