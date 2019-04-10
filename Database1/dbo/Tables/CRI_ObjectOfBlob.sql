CREATE TABLE [dbo].[CRI_ObjectOfBlob] (
    [iSPID]       INT           NOT NULL,
    [dtEntry]     DATETIME      CONSTRAINT [DF_CRI_ObjectOfBlob_dtEntry] DEFAULT (getdate()) NOT NULL,
    [iObjectID]   INT           NOT NULL,
    [vcClassName] VARCHAR (100) NULL,
    [vcFieldName] VARCHAR (100) NOT NULL,
    [txValue]     TEXT          NULL,
    CONSTRAINT [PK_CRI_ObjectOfBlob] PRIMARY KEY CLUSTERED ([iSPID] ASC, [iObjectID] ASC, [vcFieldName] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table temporaires des blobs', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRI_ObjectOfBlob';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de processus', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRI_ObjectOfBlob', @level2type = N'COLUMN', @level2name = N'iSPID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d''insertion de l''enregistrement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRI_ObjectOfBlob', @level2type = N'COLUMN', @level2name = N'dtEntry';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID temporaire de l''objet.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRI_ObjectOfBlob', @level2type = N'COLUMN', @level2name = N'iObjectID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Classe(type) de l''objet.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRI_ObjectOfBlob', @level2type = N'COLUMN', @level2name = N'vcClassName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom de champ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRI_ObjectOfBlob', @level2type = N'COLUMN', @level2name = N'vcFieldName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Valeur du champ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRI_ObjectOfBlob', @level2type = N'COLUMN', @level2name = N'txValue';

