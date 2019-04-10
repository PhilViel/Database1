CREATE TABLE [dbo].[tblCONV_RaisonFermeture] (
    [iID_Raison_Fermeture] INT           IDENTITY (1, 1) NOT NULL,
    [vcRaison_Fermeture]   VARCHAR (100) NOT NULL,
    [bActif]               BIT           CONSTRAINT [DF_CONV_RaisonFermeture_bActif] DEFAULT ((1)) NOT NULL,
    [vcDescription]        VARCHAR (250) NULL,
    [vcDescriptionENU]     VARCHAR (250) NULL,
    CONSTRAINT [PK_CONV_RaisonFermeture] PRIMARY KEY CLUSTERED ([iID_Raison_Fermeture] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID de la raison de fermeture', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RaisonFermeture', @level2type = N'COLUMN', @level2name = N'iID_Raison_Fermeture';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Raison de la fermeture', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RaisonFermeture', @level2type = N'COLUMN', @level2name = N'vcRaison_Fermeture';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si la raison peut être utilisée', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RaisonFermeture', @level2type = N'COLUMN', @level2name = N'bActif';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description complète de la raison de fermeture', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RaisonFermeture', @level2type = N'COLUMN', @level2name = N'vcDescription';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description complète de la raison de fermeture en anglais', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RaisonFermeture', @level2type = N'COLUMN', @level2name = N'vcDescriptionENU';

