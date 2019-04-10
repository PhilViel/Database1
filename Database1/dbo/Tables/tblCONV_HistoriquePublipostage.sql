CREATE TABLE [dbo].[tblCONV_HistoriquePublipostage] (
    [id_HistoriquePublipostage]    INT          IDENTITY (1, 1) NOT NULL,
    [humanID]                      [dbo].[MoID] NOT NULL,
    [dtDateDebut]                  DATETIME     NOT NULL,
    [bHumain_Accepte_Publipostage] BIT          NOT NULL,
    [iID_humain_modif]             [dbo].[MoID] NOT NULL,
    [vcCourriel]                   VARCHAR (80) NOT NULL,
    CONSTRAINT [PK_CONV_HistoriquePublipostage] PRIMARY KEY CLUSTERED ([id_HistoriquePublipostage] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_CONV_HistoriquePublipostage_Mo_Human__humanID] FOREIGN KEY ([humanID]) REFERENCES [dbo].[Mo_Human] ([HumanID]),
    CONSTRAINT [FK_CONV_HistoriquePublipostage_Mo_Human__iIDhumainmodif] FOREIGN KEY ([iID_humain_modif]) REFERENCES [dbo].[Mo_Human] ([HumanID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Tables des historiques publipostage.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_HistoriquePublipostage';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID unique de l''historique publipostage.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_HistoriquePublipostage', @level2type = N'COLUMN', @level2name = N'id_HistoriquePublipostage';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID unique de l''humain.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_HistoriquePublipostage', @level2type = N'COLUMN', @level2name = N'humanID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date d''insertion.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_HistoriquePublipostage', @level2type = N'COLUMN', @level2name = N'dtDateDebut';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur pour l''acceptation de publipostage.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_HistoriquePublipostage', @level2type = N'COLUMN', @level2name = N'bHumain_Accepte_Publipostage';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID unique de l''humain qui à modifier l''acceptation de publipostage.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_HistoriquePublipostage', @level2type = N'COLUMN', @level2name = N'iID_humain_modif';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Courriel de l''humain.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_HistoriquePublipostage', @level2type = N'COLUMN', @level2name = N'vcCourriel';

