CREATE TABLE [dbo].[tblIQEE_HistoStatutsConventions] (
    [iID_Statut_Convention] INT          IDENTITY (1, 1) NOT NULL,
    [vcCode_Statut]         VARCHAR (3)  NOT NULL,
    [vcDescription]         VARCHAR (50) NOT NULL,
    [iOrdre_Presentation]   INT          NOT NULL,
    CONSTRAINT [PK_IQEE_HistoStatutsConventions] PRIMARY KEY CLUSTERED ([iID_Statut_Convention] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_IQEE_HistoStatutsConventions_vcCodeStatut]
    ON [dbo].[tblIQEE_HistoStatutsConventions]([vcCode_Statut] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur le code unique des statuts des conventions.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStatutsConventions', @level2type = N'INDEX', @level2name = N'AK_IQEE_HistoStatutsConventions_vcCodeStatut';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur l''identifiant unique des statuts des conventions.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStatutsConventions', @level2type = N'CONSTRAINT', @level2name = N'PK_IQEE_HistoStatutsConventions';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Les statuts de l''IQÉÉ des conventions permet de synthétiser l''état de l''IQÉÉ pour une convention afin de donner une idée générale de la situation de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStatutsConventions';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''un statut d''IQÉÉ des conventions.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStatutsConventions', @level2type = N'COLUMN', @level2name = N'iID_Statut_Convention';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code unique d''un statut d''IQÉÉ des conventions.  Ce code peut être codé en dur dans la programmation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStatutsConventions', @level2type = N'COLUMN', @level2name = N'vcCode_Statut';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description du statut d''IQÉÉ des conventions.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStatutsConventions', @level2type = N'COLUMN', @level2name = N'vcDescription';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ordre de présentation des statuts dans les interfaces.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStatutsConventions', @level2type = N'COLUMN', @level2name = N'iOrdre_Presentation';

