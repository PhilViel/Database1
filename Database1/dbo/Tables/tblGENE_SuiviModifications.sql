CREATE TABLE [dbo].[tblGENE_SuiviModifications] (
    [iID_Suivi_Modification]       INT      IDENTITY (1, 1) NOT NULL,
    [iCode_Table]                  INT      NOT NULL,
    [iID_Enregistrement]           INT      NOT NULL,
    [iID_Action]                   INT      NOT NULL,
    [dtDate_Modification]          DATETIME NOT NULL,
    [iID_Utilisateur_Modification] INT      NOT NULL,
    CONSTRAINT [PK_GENE_SuiviModifications] PRIMARY KEY CLUSTERED ([iID_Suivi_Modification] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [IX_GENE_SuiviModifications_iCodeTable_iIDEnregistrement_dtDateModification]
    ON [dbo].[tblGENE_SuiviModifications]([iCode_Table] ASC, [iID_Enregistrement] ASC, [dtDate_Modification] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index unique d''une modification à un enregistrement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_SuiviModifications', @level2type = N'INDEX', @level2name = N'IX_GENE_SuiviModifications_iCodeTable_iIDEnregistrement_dtDateModification';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur l''identifiant unique de la modification.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_SuiviModifications', @level2type = N'CONSTRAINT', @level2name = N'PK_GENE_SuiviModifications';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table de suivi des modifications aux enregistrements de certaines tables prédéterminées.  Cette table est remplis avec des déclencheurs de mise à jour sur les tables que l''on désire suivre les modifications.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_SuiviModifications';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la modification apportée à un enregistrement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_SuiviModifications', @level2type = N'COLUMN', @level2name = N'iID_Suivi_Modification';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code arbitraire et unique de la table qui fait l''objet de la modification d''un enregistrement. Ce code peut être codé en dur dans la programmation.  La table "tblGENE_TablesSuivi" présente les valeurs permises de ce champs.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_SuiviModifications', @level2type = N'COLUMN', @level2name = N'iCode_Table';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de l''enregistrement modifié.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_SuiviModifications', @level2type = N'COLUMN', @level2name = N'iID_Enregistrement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de l''action.  Ce champ fait référence à la table "CRQ_LogAction".', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_SuiviModifications', @level2type = N'COLUMN', @level2name = N'iID_Action';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date et heure de la modification.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_SuiviModifications', @level2type = N'COLUMN', @level2name = N'dtDate_Modification';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de l''utilisateur qui a fait la modification.  S''il ne peux pas être déterminé avec certitude, l''utilisateur système est utilisé.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_SuiviModifications', @level2type = N'COLUMN', @level2name = N'iID_Utilisateur_Modification';

