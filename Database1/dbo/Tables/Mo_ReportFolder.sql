CREATE TABLE [dbo].[Mo_ReportFolder] (
    [ReportFolderName]     [dbo].[MoDesc] NOT NULL,
    [ReportFolderParentID] [dbo].[MoID]   NOT NULL,
    [ReportFolderID]       [dbo].[MoID]   IDENTITY (1, 1) NOT NULL,
    CONSTRAINT [PK_Mo_ReportFolder] PRIMARY KEY CLUSTERED ([ReportFolderName] ASC, [ReportFolderParentID] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_ReportFolder_ReportFolderID]
    ON [dbo].[Mo_ReportFolder]([ReportFolderID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_ReportFolder_ReportFolderParentID]
    ON [dbo].[Mo_ReportFolder]([ReportFolderParentID] ASC) WITH (FILLFACTOR = 90);


GO
GRANT DELETE
    ON OBJECT::[dbo].[Mo_ReportFolder] TO PUBLIC
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[dbo].[Mo_ReportFolder] TO PUBLIC
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[Mo_ReportFolder] TO PUBLIC
    AS [dbo];


GO
GRANT UPDATE
    ON OBJECT::[dbo].[Mo_ReportFolder] TO PUBLIC
    AS [dbo];


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Tables utilisé pour le générateur de rapport.  Cette table contient les fichiers (Regroupement de rapport).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ReportFolder';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom du fichier.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ReportFolder', @level2type = N'COLUMN', @level2name = N'ReportFolderName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du fichier parent (Mo_ReportFolder.ReportFolderID).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ReportFolder', @level2type = N'COLUMN', @level2name = N'ReportFolderParentID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du fichier.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ReportFolder', @level2type = N'COLUMN', @level2name = N'ReportFolderID';

