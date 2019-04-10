CREATE TABLE [dbo].[tblIQEE_StatutsErreur] (
    [tiID_Statuts_Erreur]             TINYINT      IDENTITY (1, 1) NOT NULL,
    [vcCode_Statut]                   VARCHAR (3)  NOT NULL,
    [vcDescription]                   VARCHAR (50) NOT NULL,
    [bInd_Retourner_RQ]               BIT          NOT NULL,
    [bInd_Selectionnable_Utilisateur] BIT          NOT NULL,
    [bInd_Modifiable_Utilisateur]     BIT          NOT NULL,
    [tiOrdre_Presentation]            TINYINT      NOT NULL,
    CONSTRAINT [PK_IQEE_StatutsErreur] PRIMARY KEY CLUSTERED ([tiID_Statuts_Erreur] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_IQEE_StatutsErreur_vcCodeStatut]
    ON [dbo].[tblIQEE_StatutsErreur]([vcCode_Statut] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index du code interne à UniAccès des statuts d''erreur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatutsErreur', @level2type = N'INDEX', @level2name = N'AK_IQEE_StatutsErreur_vcCodeStatut';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index de la clé primaire des statuts des erreur de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatutsErreur', @level2type = N'CONSTRAINT', @level2name = N'PK_IQEE_StatutsErreur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Liste des statuts des erreurs de RQ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatutsErreur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''un statut d''erreur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatutsErreur', @level2type = N'COLUMN', @level2name = N'tiID_Statuts_Erreur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code interne à UniAccès du statut d''erreur.  Ce code peut être codé en dur dans la programmation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatutsErreur', @level2type = N'COLUMN', @level2name = N'vcCode_Statut';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description du statut d''erreur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatutsErreur', @level2type = N'COLUMN', @level2name = N'vcDescription';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur si la transaction en erreur doit être retournée ou non à RQ lorsque l''erreur a ce statut.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatutsErreur', @level2type = N'COLUMN', @level2name = N'bInd_Retourner_RQ';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur si l''utilisateur peux sélectionner le statut d''erreur lors de la modification d''une erreur RQ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatutsErreur', @level2type = N'COLUMN', @level2name = N'bInd_Selectionnable_Utilisateur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur si l''utilisateur peux modifier le statut d''une erreur de RQ lorsque l''erreur RQ est rendu à ce statut.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatutsErreur', @level2type = N'COLUMN', @level2name = N'bInd_Modifiable_Utilisateur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ordre de présentation des statuts d''erreur pour l''interface utilisateur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatutsErreur', @level2type = N'COLUMN', @level2name = N'tiOrdre_Presentation';

