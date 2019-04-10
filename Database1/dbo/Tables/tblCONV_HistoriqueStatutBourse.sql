CREATE TABLE [dbo].[tblCONV_HistoriqueStatutBourse] (
    [iID_Historique_Statut] INT      IDENTITY (1, 1) NOT NULL,
    [iID_Statut]            INT      NOT NULL,
    [iID_Bourse]            INT      NOT NULL,
    [dtDate_Statut]         DATETIME NOT NULL,
    CONSTRAINT [PK_CONV_HistoriqueStatutBourse] PRIMARY KEY CLUSTERED ([iID_Historique_Statut] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_CONV_HistoriqueStatutBourse_CONV_StatutBourse__iIDStatut] FOREIGN KEY ([iID_Statut]) REFERENCES [dbo].[tblCONV_StatutBourse] ([iID_Statut]),
    CONSTRAINT [FK_CONV_HistoriqueStatutBourse_Un_Scholarship__iIDBourse] FOREIGN KEY ([iID_Bourse]) REFERENCES [dbo].[Un_Scholarship] ([ScholarshipID])
);


GO
ALTER TABLE [dbo].[tblCONV_HistoriqueStatutBourse] NOCHECK CONSTRAINT [FK_CONV_HistoriqueStatutBourse_Un_Scholarship__iIDBourse];


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de l''historique du statut de bourse', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_HistoriqueStatutBourse', @level2type = N'COLUMN', @level2name = N'iID_Historique_Statut';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant du statut de bourse', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_HistoriqueStatutBourse', @level2type = N'COLUMN', @level2name = N'iID_Statut';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant de la bourse', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_HistoriqueStatutBourse', @level2type = N'COLUMN', @level2name = N'iID_Bourse';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date de l''historique du statut de bourse', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_HistoriqueStatutBourse', @level2type = N'COLUMN', @level2name = N'dtDate_Statut';

