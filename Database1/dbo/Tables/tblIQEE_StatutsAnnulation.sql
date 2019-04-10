CREATE TABLE [dbo].[tblIQEE_StatutsAnnulation] (
    [iID_Statut_Annulation] INT           IDENTITY (1, 1) NOT NULL,
    [vcCode_Statut]         VARCHAR (3)   NOT NULL,
    [vcDescription]         VARCHAR (100) NOT NULL,
    CONSTRAINT [PK_IQEE_StatutsAnnulation] PRIMARY KEY CLUSTERED ([iID_Statut_Annulation] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_IQEE_StatutsAnnulation_vcCodeStatut]
    ON [dbo].[tblIQEE_StatutsAnnulation]([vcCode_Statut] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur le code de statut des demandes d''annulation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatutsAnnulation', @level2type = N'INDEX', @level2name = N'AK_IQEE_StatutsAnnulation_vcCodeStatut';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur la clé unique des statuts des demandes d''annulation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatutsAnnulation', @level2type = N'CONSTRAINT', @level2name = N'PK_IQEE_StatutsAnnulation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Statuts des demandes d''annulation.  Les demandes d''annulation faite par l''utilisateur ou automatiquement par programmation peuvent être actualisées ou non selon le traitement de la création des fichiers de transactions et les réponses de RQ.  Cette table permet grosso modo de savoir si une demande d''annulation est en attente, en erreur ou complétée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatutsAnnulation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''un statut d''une demande d''annulation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatutsAnnulation', @level2type = N'COLUMN', @level2name = N'iID_Statut_Annulation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code unique du statut d''une demande d''annulation. Ce code peut être codé en dur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatutsAnnulation', @level2type = N'COLUMN', @level2name = N'vcCode_Statut';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description du statut d''une demande d''annulation.  Elle est affichée dans l''historique de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatutsAnnulation', @level2type = N'COLUMN', @level2name = N'vcDescription';

