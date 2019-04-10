CREATE TABLE [dbo].[tblIQEE_RaisonsAnnulationAnnulation] (
    [iID_Raison_Annulation_Annulation] INT           IDENTITY (1, 1) NOT NULL,
    [vcCode_Raison]                    VARCHAR (3)   NOT NULL,
    [vcDescription]                    VARCHAR (100) NOT NULL,
    CONSTRAINT [PK_IQEE_RaisonsAnnulationAnnulation] PRIMARY KEY CLUSTERED ([iID_Raison_Annulation_Annulation] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_IQEE_RaisonsAnnulationAnnulation_vcCodeRaison]
    ON [dbo].[tblIQEE_RaisonsAnnulationAnnulation]([vcCode_Raison] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur le code de raison d''annulation des demandes d''annulation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RaisonsAnnulationAnnulation', @level2type = N'INDEX', @level2name = N'AK_IQEE_RaisonsAnnulationAnnulation_vcCodeRaison';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur la clé unique des raisons d''annulation des demandes d''annulation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RaisonsAnnulationAnnulation', @level2type = N'CONSTRAINT', @level2name = N'PK_IQEE_RaisonsAnnulationAnnulation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Raisons d''annulation des demandes d''annulation.  Les demandes d''annulation faite par l''utilisateur ou automatiquement par programmation peuvent être actualisées ou non selon le traitement de la création des fichiers de transactions. La principale raison d''annulation des demandes d''annulation est que la transaction de reprise n''a pas pûe être créée parce qu''elle ne passe pas les validations (rejets).  Selon les paramètres des raisons d''annulation,  les transactions de reprises identiques aux transactions originales ne sont pas transmises à RQ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RaisonsAnnulationAnnulation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''une raison d''annulation d''une demande d''annulation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RaisonsAnnulationAnnulation', @level2type = N'COLUMN', @level2name = N'iID_Raison_Annulation_Annulation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code unique de la raison d''annulation d''une demande d''annulation. Ce code peut être codé en dur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RaisonsAnnulationAnnulation', @level2type = N'COLUMN', @level2name = N'vcCode_Raison';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description de la raison d''annulation d''une demande d''annulation.  Elle est affichée dans l''historique de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RaisonsAnnulationAnnulation', @level2type = N'COLUMN', @level2name = N'vcDescription';

