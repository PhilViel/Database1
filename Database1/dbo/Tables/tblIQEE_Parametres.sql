CREATE TABLE [dbo].[tblIQEE_Parametres] (
    [iID_Parametres_IQEE]                  INT      IDENTITY (1, 1) NOT NULL,
    [siAnnee_Fiscale]                      SMALLINT NOT NULL,
    [dtDate_Debut_Application]             DATETIME NOT NULL,
    [dtDate_Fin_Application]               DATETIME NULL,
    [dtDate_Debut_Cotisation]              DATETIME NOT NULL,
    [dtDate_Fin_Cotisation]                DATETIME NOT NULL,
    [siNb_Jour_Limite_Demande]             SMALLINT NOT NULL,
    [tiNb_Maximum_Annee_Fiscale_Anterieur] TINYINT  NOT NULL,
    [iID_Utilisateur_Creation]             INT      NOT NULL,
    [iID_Utilisateur_Modification]         INT      NULL,
    [dtDate_Modification]                  DATETIME NULL,
    CONSTRAINT [PK_IQEE_Parametres] PRIMARY KEY CLUSTERED ([iID_Parametres_IQEE] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_IQEE_Parametres_siAnneeFiscale_dtDateFinApplication]
    ON [dbo].[tblIQEE_Parametres]([siAnnee_Fiscale] ASC, [dtDate_Fin_Application] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index par année fiscale et date de fin d''application.  Utilisé lors de la création d''un fichier pour déterminer l''identifiant des paramètres en vigueur pour l''année fiscale (dtDate_Fin_Application=Null).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Parametres', @level2type = N'INDEX', @level2name = N'AK_IQEE_Parametres_siAnneeFiscale_dtDateFinApplication';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur la clé primaire des paramètres de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Parametres', @level2type = N'CONSTRAINT', @level2name = N'PK_IQEE_Parametres';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Historique des paramètres de l''IQÉÉ par année fiscale.  Il y a qu''une seule série de paramètre en vigueur par année fiscale.  Les paramètres ne doivent pas être modifiés si un fichier de transactions de production a été crée en vertu de ces paramètres.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Parametres';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''une série de paramètres de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Parametres', @level2type = N'COLUMN', @level2name = N'iID_Parametres_IQEE';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Année fiscale de la série des paramètres.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Parametres', @level2type = N'COLUMN', @level2name = N'siAnnee_Fiscale';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date et heure de début d''application de la série des paramètres.  Correspond à la date de fin d''application de la série précédente plus 2 millisecondes.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Parametres', @level2type = N'COLUMN', @level2name = N'dtDate_Debut_Application';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date de fin d''application de la série des paramètres.  Null indique que les paramètres sont en vigueur.  Il existe 1 seul enregistrement en vigueur par année fiscale.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Parametres', @level2type = N'COLUMN', @level2name = N'dtDate_Fin_Application';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date de début d''admissibilité des cotisations à l''IQÉÉ.  L''heure est à 0 pour prendre toutes les transactions de la journée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Parametres', @level2type = N'COLUMN', @level2name = N'dtDate_Debut_Cotisation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date de fin d''admissibilité des cotisations à l''IQÉÉ.  L''heure 2007-12-31 23:59:59.997 est appliqué à la date afin de prendre toutes les transactions de la journée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Parametres', @level2type = N'COLUMN', @level2name = N'dtDate_Fin_Cotisation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nombre limite de jour après la fin de l''année fiscale pour faire une demande qui est considérée dans les délais.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Parametres', @level2type = N'COLUMN', @level2name = N'siNb_Jour_Limite_Demande';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nombre maximum d''années fiscales antérieurs à l''année en cours qu''il est permis de faire une demande en retard.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Parametres', @level2type = N'COLUMN', @level2name = N'tiNb_Maximum_Annee_Fiscale_Anterieur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de l''utilisateur ayant fait la création de la série des paramètres.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Parametres', @level2type = N'COLUMN', @level2name = N'iID_Utilisateur_Creation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de l''utilisateur ayant fait la dernière modification de la série des paramètres.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Parametres', @level2type = N'COLUMN', @level2name = N'iID_Utilisateur_Modification';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date et heure de la dernière modification.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Parametres', @level2type = N'COLUMN', @level2name = N'dtDate_Modification';

