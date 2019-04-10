CREATE TABLE [dbo].[tblIQEE_Annulations] (
    [iID_Annulation]                           INT           IDENTITY (1, 1) NOT NULL,
    [tiID_Type_Enregistrement]                 TINYINT       NOT NULL,
    [iID_Enregistrement_Demande_Annulation]    INT           NOT NULL,
    [iID_Session]                              INT           NULL,
    [dtDate_Creation_Fichiers]                 DATETIME      NULL,
    [vcCode_Simulation]                        VARCHAR (100) NULL,
    [dtDate_Demande_Annulation]                DATETIME      NOT NULL,
    [iID_Utilisateur_Demande]                  INT           NOT NULL,
    [iID_Type_Annulation]                      INT           NOT NULL,
    [iID_Raison_Annulation]                    INT           NOT NULL,
    [tCommentaires]                            TEXT          NULL,
    [dtDate_Action_Menant_Annulation]          DATETIME      NULL,
    [iID_Utilisateur_Action_Menant_Annulation] INT           NULL,
    [iID_Suivi_Modification]                   INT           NULL,
    [iID_Enregistrement_Annulation]            INT           NULL,
    [iID_Enregistrement_Reprise]               INT           NULL,
    [iID_Enregistrement_Reprise_Originale]     INT           NULL,
    [iID_Raison_Annulation_Annulation]         INT           NULL,
    [iID_Statut_Annulation]                    INT           NOT NULL,
    CONSTRAINT [PK_IQEE_Annulations] PRIMARY KEY CLUSTERED ([iID_Annulation] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_IQEE_Annulations_IQEE_RaisonsAnnulation__iIDRaisonAnnulation] FOREIGN KEY ([iID_Raison_Annulation]) REFERENCES [dbo].[tblIQEE_RaisonsAnnulation] ([iID_Raison_Annulation]),
    CONSTRAINT [FK_IQEE_Annulations_IQEE_RaisonsAnnulationAnnulation__iIDRaisonAnnulationAnnulation] FOREIGN KEY ([iID_Raison_Annulation_Annulation]) REFERENCES [dbo].[tblIQEE_RaisonsAnnulationAnnulation] ([iID_Raison_Annulation_Annulation]),
    CONSTRAINT [FK_IQEE_Annulations_IQEE_StatutsAnnulation__iIDStatutAnnulation] FOREIGN KEY ([iID_Statut_Annulation]) REFERENCES [dbo].[tblIQEE_StatutsAnnulation] ([iID_Statut_Annulation]),
    CONSTRAINT [FK_IQEE_Annulations_IQEE_TypesAnnulation__iIDTypeAnnulation] FOREIGN KEY ([iID_Type_Annulation]) REFERENCES [dbo].[tblIQEE_TypesAnnulation] ([iID_Type_Annulation]),
    CONSTRAINT [FK_IQEE_Annulations_IQEE_TypesEnregistrement__tiIDTypeEnregistrement] FOREIGN KEY ([tiID_Type_Enregistrement]) REFERENCES [dbo].[tblIQEE_TypesEnregistrement] ([tiID_Type_Enregistrement])
);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_Annulations_tiIDTypeEnregistrement_iIDEnregistrementDemandeAnnulation]
    ON [dbo].[tblIQEE_Annulations]([tiID_Type_Enregistrement] ASC, [iID_Enregistrement_Demande_Annulation] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_Annulations_iIDSession_dtDateCreationFichiers]
    ON [dbo].[tblIQEE_Annulations]([iID_Session] ASC, [dtDate_Creation_Fichiers] ASC)
    INCLUDE([iID_Enregistrement_Demande_Annulation], [iID_Raison_Annulation], [tiID_Type_Enregistrement]);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_Annulations_vcCodeSimulation]
    ON [dbo].[tblIQEE_Annulations]([vcCode_Simulation] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_Annulations_iIDEnregistrementReprise]
    ON [dbo].[tblIQEE_Annulations]([iID_Enregistrement_Reprise] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_Annulations_iIDEnregistrementRepriseOriginale]
    ON [dbo].[tblIQEE_Annulations]([iID_Enregistrement_Reprise_Originale] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_Annulations_iIDEnregistrementDemandeAnnulation_iIDSession_dtDateCreationFichiers_vcCodeSimulation_iIDTypeAnnulation]
    ON [dbo].[tblIQEE_Annulations]([iID_Enregistrement_Demande_Annulation] ASC, [iID_Session] ASC, [dtDate_Creation_Fichiers] ASC, [vcCode_Simulation] ASC, [iID_Type_Annulation] ASC)
    INCLUDE([tiID_Type_Enregistrement], [dtDate_Demande_Annulation], [iID_Utilisateur_Demande], [iID_Raison_Annulation]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_Annulations_iIDEnregistrementDemandeAnnulation_iIDSession_dtDateCreationFichiers]
    ON [dbo].[tblIQEE_Annulations]([iID_Enregistrement_Demande_Annulation] ASC, [iID_Session] ASC, [dtDate_Creation_Fichiers] ASC)
    INCLUDE([tiID_Type_Enregistrement]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_Annulations_dtDateCreationFichiers_iIDEnregistrementDemandeAnnulation_iIDSession_vcCodeSimulation_iIDTypeAnnulation_tiID]
    ON [dbo].[tblIQEE_Annulations]([dtDate_Creation_Fichiers] ASC, [iID_Enregistrement_Demande_Annulation] ASC, [iID_Session] ASC, [vcCode_Simulation] ASC, [iID_Type_Annulation] ASC, [tiID_Type_Enregistrement] ASC, [iID_Raison_Annulation] ASC, [iID_Annulation] ASC)
    INCLUDE([iID_Enregistrement_Annulation]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_Annulations_iIDStatutAnnulation]
    ON [dbo].[tblIQEE_Annulations]([iID_Statut_Annulation] ASC) WITH (FILLFACTOR = 90);


GO
CREATE STATISTICS [stat_tblIQEE_Annulations_1]
    ON [dbo].[tblIQEE_Annulations]([iID_Type_Annulation], [dtDate_Creation_Fichiers]);


GO
CREATE STATISTICS [stat_tblIQEE_Annulations_2]
    ON [dbo].[tblIQEE_Annulations]([iID_Enregistrement_Demande_Annulation], [dtDate_Creation_Fichiers]);


GO
CREATE STATISTICS [stat_tblIQEE_Annulations_3]
    ON [dbo].[tblIQEE_Annulations]([tiID_Type_Enregistrement], [dtDate_Creation_Fichiers]);


GO
CREATE STATISTICS [stat_tblIQEE_Annulations_4]
    ON [dbo].[tblIQEE_Annulations]([tiID_Type_Enregistrement], [iID_Raison_Annulation]);


GO
CREATE STATISTICS [stat_tblIQEE_Annulations_5]
    ON [dbo].[tblIQEE_Annulations]([iID_Enregistrement_Demande_Annulation], [iID_Session], [iID_Type_Annulation]);


GO
CREATE STATISTICS [stat_tblIQEE_Annulations_6]
    ON [dbo].[tblIQEE_Annulations]([dtDate_Creation_Fichiers], [iID_Session], [iID_Raison_Annulation], [iID_Enregistrement_Demande_Annulation]);


GO
CREATE STATISTICS [stat_tblIQEE_Annulations_7]
    ON [dbo].[tblIQEE_Annulations]([iID_Raison_Annulation], [iID_Session], [iID_Type_Annulation], [dtDate_Creation_Fichiers]);


GO
CREATE STATISTICS [stat_tblIQEE_Annulations_8]
    ON [dbo].[tblIQEE_Annulations]([iID_Raison_Annulation], [dtDate_Creation_Fichiers], [iID_Session], [tiID_Type_Enregistrement]);


GO
CREATE STATISTICS [stat_tblIQEE_Annulations_9]
    ON [dbo].[tblIQEE_Annulations]([tiID_Type_Enregistrement], [iID_Type_Annulation], [iID_Raison_Annulation], [iID_Enregistrement_Demande_Annulation]);


GO
CREATE STATISTICS [stat_tblIQEE_Annulations_10]
    ON [dbo].[tblIQEE_Annulations]([dtDate_Creation_Fichiers], [iID_Session], [iID_Type_Annulation], [tiID_Type_Enregistrement], [iID_Raison_Annulation]);


GO
CREATE STATISTICS [stat_tblIQEE_Annulations_11]
    ON [dbo].[tblIQEE_Annulations]([tiID_Type_Enregistrement], [iID_Enregistrement_Demande_Annulation], [iID_Session], [dtDate_Creation_Fichiers], [vcCode_Simulation]);


GO
CREATE STATISTICS [stat_tblIQEE_Annulations_12]
    ON [dbo].[tblIQEE_Annulations]([iID_Session], [tiID_Type_Enregistrement], [iID_Type_Annulation], [iID_Raison_Annulation], [iID_Enregistrement_Demande_Annulation]);


GO
CREATE STATISTICS [stat_tblIQEE_Annulations_13]
    ON [dbo].[tblIQEE_Annulations]([iID_Enregistrement_Demande_Annulation], [tiID_Type_Enregistrement], [iID_Raison_Annulation], [iID_Type_Annulation], [iID_Session]);


GO
CREATE STATISTICS [stat_tblIQEE_Annulations_14]
    ON [dbo].[tblIQEE_Annulations]([iID_Type_Annulation], [iID_Session], [dtDate_Creation_Fichiers], [vcCode_Simulation], [tiID_Type_Enregistrement], [iID_Raison_Annulation]);


GO
CREATE STATISTICS [stat_tblIQEE_Annulations_15]
    ON [dbo].[tblIQEE_Annulations]([iID_Enregistrement_Demande_Annulation], [iID_Type_Annulation], [iID_Session], [dtDate_Creation_Fichiers], [vcCode_Simulation], [iID_Annulation]);


GO
CREATE STATISTICS [stat_tblIQEE_Annulations_16]
    ON [dbo].[tblIQEE_Annulations]([iID_Enregistrement_Demande_Annulation], [iID_Raison_Annulation], [iID_Session], [dtDate_Creation_Fichiers], [vcCode_Simulation], [iID_Type_Annulation]);


GO
CREATE STATISTICS [stat_tblIQEE_Annulations_17]
    ON [dbo].[tblIQEE_Annulations]([iID_Enregistrement_Demande_Annulation], [iID_Annulation], [tiID_Type_Enregistrement], [iID_Raison_Annulation], [iID_Type_Annulation], [iID_Session], [dtDate_Creation_Fichiers]);


GO
CREATE STATISTICS [stat_tblIQEE_Annulations_18]
    ON [dbo].[tblIQEE_Annulations]([iID_Annulation], [iID_Enregistrement_Demande_Annulation], [iID_Session], [dtDate_Creation_Fichiers], [vcCode_Simulation], [iID_Type_Annulation], [tiID_Type_Enregistrement]);


GO
CREATE STATISTICS [stat_tblIQEE_Annulations_19]
    ON [dbo].[tblIQEE_Annulations]([dtDate_Creation_Fichiers], [tiID_Type_Enregistrement], [iID_Type_Annulation], [iID_Raison_Annulation], [iID_Enregistrement_Demande_Annulation], [iID_Session], [vcCode_Simulation], [iID_Annulation]);


GO
CREATE STATISTICS [stat_tblIQEE_Annulations_20]
    ON [dbo].[tblIQEE_Annulations]([iID_Enregistrement_Demande_Annulation], [tiID_Type_Enregistrement], [iID_Raison_Annulation], [iID_Session], [dtDate_Creation_Fichiers], [vcCode_Simulation], [dtDate_Demande_Annulation], [iID_Utilisateur_Demande], [dtDate_Action_Menant_Annulation], [iID_Utilisateur_Action_Menant_Annulation], [iID_Suivi_Modification]);


GO
CREATE STATISTICS [stat_tblIQEE_Annulations_21]
    ON [dbo].[tblIQEE_Annulations]([vcCode_Simulation], [dtDate_Demande_Annulation], [iID_Utilisateur_Demande], [iID_Raison_Annulation], [dtDate_Action_Menant_Annulation], [iID_Utilisateur_Action_Menant_Annulation], [iID_Suivi_Modification], [dtDate_Creation_Fichiers], [iID_Session], [iID_Enregistrement_Demande_Annulation], [iID_Annulation]);


GO
CREATE STATISTICS [stat_tblIQEE_Annulations_22]
    ON [dbo].[tblIQEE_Annulations]([iID_Enregistrement_Demande_Annulation], [iID_Type_Annulation], [iID_Raison_Annulation], [iID_Session], [dtDate_Creation_Fichiers], [vcCode_Simulation], [dtDate_Demande_Annulation], [iID_Utilisateur_Demande], [dtDate_Action_Menant_Annulation], [iID_Utilisateur_Action_Menant_Annulation], [iID_Suivi_Modification]);


GO
CREATE STATISTICS [stat_tblIQEE_Annulations_23]
    ON [dbo].[tblIQEE_Annulations]([iID_Session], [iID_Enregistrement_Demande_Annulation], [tiID_Type_Enregistrement], [iID_Raison_Annulation], [dtDate_Creation_Fichiers], [iID_Type_Annulation], [vcCode_Simulation], [dtDate_Demande_Annulation], [iID_Utilisateur_Demande], [dtDate_Action_Menant_Annulation], [iID_Utilisateur_Action_Menant_Annulation], [iID_Suivi_Modification]);


GO
CREATE STATISTICS [stat_tblIQEE_Annulations_24]
    ON [dbo].[tblIQEE_Annulations]([iID_Enregistrement_Demande_Annulation], [iID_Annulation], [iID_Type_Annulation], [iID_Raison_Annulation], [iID_Session], [dtDate_Creation_Fichiers], [vcCode_Simulation], [dtDate_Demande_Annulation], [iID_Utilisateur_Demande], [dtDate_Action_Menant_Annulation], [iID_Utilisateur_Action_Menant_Annulation], [iID_Suivi_Modification]);


GO
CREATE STATISTICS [stat_tblIQEE_Annulations_25]
    ON [dbo].[tblIQEE_Annulations]([dtDate_Creation_Fichiers], [iID_Session], [iID_Enregistrement_Demande_Annulation], [tiID_Type_Enregistrement], [iID_Type_Annulation], [iID_Raison_Annulation], [vcCode_Simulation], [dtDate_Demande_Annulation], [iID_Utilisateur_Demande], [dtDate_Action_Menant_Annulation], [iID_Utilisateur_Action_Menant_Annulation], [iID_Suivi_Modification], [iID_Annulation]);


GO
CREATE STATISTICS [stat_tblIQEE_Annulations_26]
    ON [dbo].[tblIQEE_Annulations]([iID_Enregistrement_Demande_Annulation], [dtDate_Creation_Fichiers], [tiID_Type_Enregistrement]);


GO
CREATE STATISTICS [stat_tblIQEE_Annulations_27]
    ON [dbo].[tblIQEE_Annulations]([dtDate_Creation_Fichiers], [iID_Raison_Annulation], [iID_Enregistrement_Demande_Annulation]);


GO
CREATE STATISTICS [stat_tblIQEE_Annulations_28]
    ON [dbo].[tblIQEE_Annulations]([vcCode_Simulation], [iID_Enregistrement_Demande_Annulation], [iID_Session]);


GO
CREATE STATISTICS [stat_tblIQEE_Annulations_29]
    ON [dbo].[tblIQEE_Annulations]([iID_Session], [iID_Raison_Annulation], [iID_Type_Annulation], [tiID_Type_Enregistrement], [iID_Enregistrement_Demande_Annulation], [vcCode_Simulation]);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index des annulations par enregistrement en demande d''annulation ou déjà annulé.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Annulations', @level2type = N'INDEX', @level2name = N'IX_IQEE_Annulations_tiIDTypeEnregistrement_iIDEnregistrementDemandeAnnulation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index par code de simulation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Annulations', @level2type = N'INDEX', @level2name = N'IX_IQEE_Annulations_vcCodeSimulation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur l''identifiant de la transaction de reprise.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Annulations', @level2type = N'INDEX', @level2name = N'IX_IQEE_Annulations_iIDEnregistrementReprise';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur l''identifiant de la transaction de reprise originale.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Annulations', @level2type = N'INDEX', @level2name = N'IX_IQEE_Annulations_iIDEnregistrementRepriseOriginale';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur l''identifiant du statut de la demande d''annulation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Annulations', @level2type = N'INDEX', @level2name = N'IX_IQEE_Annulations_iIDStatutAnnulation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur la clé unique des annulations.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Annulations', @level2type = N'CONSTRAINT', @level2name = N'PK_IQEE_Annulations';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Informations sur les annulations des enregistrements de l''IQÉÉ.  Cette table permet aux utilisateurs d''enregistrer ou supprimer des demandes d''annulation manuelles.  Lors de la création de fichiers, les demandes automatiques d''annulation sont insérées dans cette table.  Toujours lors de la création de fichiers, les demandes d''annulation sont traitées par des transactions d''annulation et des transactions de reprise.  Les informations de la table sont alors complétées pour la faire passer d''une demande d''annulation à une annulation complète avec toutes les informations qui s''y rattachent.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Annulations';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''une annulation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Annulations', @level2type = N'COLUMN', @level2name = N'iID_Annulation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du type d''enregistrement sur lequel a lieu l''annulation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Annulations', @level2type = N'COLUMN', @level2name = N'tiID_Type_Enregistrement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de l''enregistrement sur lequel a lieu la demande d''annulation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Annulations', @level2type = N'COLUMN', @level2name = N'iID_Enregistrement_Demande_Annulation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant de la session à l''origine de la création du fichier qui est à l''origine de la demande automatique d''annulation.  S''applique uniquement aux annulations automatiques.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Annulations', @level2type = N'COLUMN', @level2name = N'iID_Session';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date de la création du fichier qui est à l''origine de la demande automatique d''annulation.  S''applique uniquement aux annulations automatiques.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Annulations', @level2type = N'COLUMN', @level2name = N'dtDate_Creation_Fichiers';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code de simulation de la création des fichiers qui est à l''origine de la demande automatique d''annulation.  S''applique uniquement aux annulations automatiques.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Annulations', @level2type = N'COLUMN', @level2name = N'vcCode_Simulation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date/heure de la demande d''annulation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Annulations', @level2type = N'COLUMN', @level2name = N'dtDate_Demande_Annulation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant de l''utilisateur à l''origine de la création de la demande d''annulation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Annulations', @level2type = N'COLUMN', @level2name = N'iID_Utilisateur_Demande';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du type d''annulation.  Il fait référence à la table de référence "tblIQEE_TypesAnnulation".', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Annulations', @level2type = N'COLUMN', @level2name = N'iID_Type_Annulation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la raison d''annulation.  Fait référence à la table de référence "tblIQEE_RaisonsAnnulation".', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Annulations', @level2type = N'COLUMN', @level2name = N'iID_Raison_Annulation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Commentaires de la demande d''annulation.  S''applique normalement uniquement pour les demandes d''annulation manuelles.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Annulations', @level2type = N'COLUMN', @level2name = N'tCommentaires';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date/heure de l''action principale ayant menée à la demande d''annulation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Annulations', @level2type = N'COLUMN', @level2name = N'dtDate_Action_Menant_Annulation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant de l''utilisateur de l''action principale ayant menée à la demande d''annulation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Annulations', @level2type = N'COLUMN', @level2name = N'iID_Utilisateur_Action_Menant_Annulation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du suivi de modification à l''origine de l''action principale ayant menée à la demande d''annulation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Annulations', @level2type = N'COLUMN', @level2name = N'iID_Suivi_Modification';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de l''enregistrement qui a fait l''annulation de l''enregistrement annulé.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Annulations', @level2type = N'COLUMN', @level2name = N'iID_Enregistrement_Annulation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de l''enregistrement de reprise suite à l''annulation de l''enregistrement annulé.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Annulations', @level2type = N'COLUMN', @level2name = N'iID_Enregistrement_Reprise';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de l''enregistrement de reprise originale qui est crée lors d''une reprise d''informations pas amendables.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Annulations', @level2type = N'COLUMN', @level2name = N'iID_Enregistrement_Reprise_Originale';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la raison d''annulation de la demande d''annulation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Annulations', @level2type = N'COLUMN', @level2name = N'iID_Raison_Annulation_Annulation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du statut de la demande d''annulation faisant référence à la table "tblIQEE_StatutsAnnulation".', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Annulations', @level2type = N'COLUMN', @level2name = N'iID_Statut_Annulation';

