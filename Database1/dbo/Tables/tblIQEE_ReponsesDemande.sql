CREATE TABLE [dbo].[tblIQEE_ReponsesDemande] (
    [iID_Reponse_Demande]                       INT     IDENTITY (1, 1) NOT NULL,
    [iID_Demande_IQEE]                          INT     NULL,
    [iID_Fichier_IQEE]                          INT     NULL,
    [tiID_Type_Reponse]                         TINYINT NOT NULL,
    [tiID_Justification_RQ]                     TINYINT NULL,
    [mMontant]                                  MONEY   NULL,
    [bInd_Partage]                              BIT     NULL,
    [iID_Operation]                             INT     NULL,
    [iID_Transaction_Convention]                INT     NULL,
    [iID_Convention]                            INT     NULL,
    [iID_Transaction_Convention_Ajustement_CBQ] INT     NULL,
    [iID_Transaction_Convention_Ajustement_MMQ] INT     NULL,
    CONSTRAINT [PK_IQEE_ReponsesDemande] PRIMARY KEY CLUSTERED ([iID_Reponse_Demande] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_IQEE_ReponsesDemande_Fichiers__iIDFichierIQEE] FOREIGN KEY ([iID_Fichier_IQEE]) REFERENCES [dbo].[tblIQEE_Fichiers] ([iID_Fichier_IQEE]),
    CONSTRAINT [FK_IQEE_ReponsesDemande_IQEE_Demandes__iIDDemandeIQEE] FOREIGN KEY ([iID_Demande_IQEE]) REFERENCES [dbo].[tblIQEE_Demandes] ([iID_Demande_IQEE]),
    CONSTRAINT [FK_IQEE_ReponsesDemande_IQEE_JustificationsRQ__tiIDJustificationRQ] FOREIGN KEY ([tiID_Justification_RQ]) REFERENCES [dbo].[tblIQEE_JustificationsRQ] ([tiID_Justification_RQ]),
    CONSTRAINT [FK_IQEE_ReponsesDemande_IQEE_TypesReponse__tiIDTypeReponse] FOREIGN KEY ([tiID_Type_Reponse]) REFERENCES [dbo].[tblIQEE_TypesReponse] ([tiID_Type_Reponse])
);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_ReponsesDemande_iIDDemandeIQEE]
    ON [dbo].[tblIQEE_ReponsesDemande]([iID_Demande_IQEE] ASC, [iID_Fichier_IQEE] ASC, [iID_Reponse_Demande] ASC)
    INCLUDE([tiID_Type_Reponse], [tiID_Justification_RQ]);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_ReponsesDemande_iIDFichierIQEE]
    ON [dbo].[tblIQEE_ReponsesDemande]([iID_Fichier_IQEE] ASC, [iID_Demande_IQEE] ASC, [iID_Reponse_Demande] ASC)
    INCLUDE([tiID_Type_Reponse], [tiID_Justification_RQ]);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur l''identifiant unique de la réponse.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ReponsesDemande', @level2type = N'CONSTRAINT', @level2name = N'PK_IQEE_ReponsesDemande';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Réponses aux demandes d''IQÉÉ provenant des rapports de traitement "Transactions de détermination de crédit" et "Transactions de nouvelle détermination de crédit".', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ReponsesDemande';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''une réponse à une demande d''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ReponsesDemande', @level2type = N'COLUMN', @level2name = N'iID_Reponse_Demande';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la demande d''IQÉÉ pour laquelle il y a une réponse.  Le champ est nullable pour permettre de recevoir les réponses de RQ aux demandes d''IQÉÉ faites par d''autres promoteurs lorsque la demande de l’autre promoteur indique à RQ qu’il désire faire la cession de l’IQÉÉ au régime cessionnaire.  Étant donné que ce n’est pas GUI qui en a fait la demande, il n’y a donc pas de lien possible avec une demande d’IQÉÉ de la table tblIQEE_Demandes.  Malgré cela, les réponses de ce type ont les mêmes effet que les réponses aux demandes de l''IQÉÉ faites par GUI.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ReponsesDemande', @level2type = N'COLUMN', @level2name = N'iID_Demande_IQEE';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du fichier de réponse de l''IQÉÉ associé à la réponse.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ReponsesDemande', @level2type = N'COLUMN', @level2name = N'iID_Fichier_IQEE';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du type de réponse à une demande d''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ReponsesDemande', @level2type = N'COLUMN', @level2name = N'tiID_Type_Reponse';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du code de justification de RQ pour l''IQÉÉ si le code de justification s''applique au type de réponse.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ReponsesDemande', @level2type = N'COLUMN', @level2name = N'tiID_Justification_RQ';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant de la réponse à la demande de l''IQÉÉ.  La valeur de ce champ dépend du type de réponse.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ReponsesDemande', @level2type = N'COLUMN', @level2name = N'mMontant';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur de partage d''un montant avec d''autres promoteurs de REÉÉ pour un montant de l''IQÉÉ.  La valeur de ce champ dépend du type de réponse.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ReponsesDemande', @level2type = N'COLUMN', @level2name = N'bInd_Partage';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de l''opération financière (Un_Oper) qui a fait l''importation du montant de réponse de l''IQÉÉ vers un montant de subvention IQÉÉ dans la convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ReponsesDemande', @level2type = N'COLUMN', @level2name = N'iID_Operation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la transaction de subvention IQÉÉ dans la convention (Un_ConventionOper) résultant de l''importation du montant de réponse de l''IQÉÉ d''une demande.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ReponsesDemande', @level2type = N'COLUMN', @level2name = N'iID_Transaction_Convention';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la convention recevant une réponse de RQ.  Dans une réponse à une demande de GUI, c''est le même identifiant que la demande.  Si la réponse provient d''une cession de l''IQÉÉ suite à un transfert total, c''est l''identifiant du numéro de convention de la réponse.  En cas d''erreur dans le numéro de convention, l''identifiant est vide et doit être traité par le support informatique.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ReponsesDemande', @level2type = N'COLUMN', @level2name = N'iID_Convention';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la transaction d''ajustement de crédit de base dans la convention (Un_ConventionOper) résultant de l''importation du montant de réponse de l''IQÉÉ d''une demande.  Ce champ est utile afin de maintenir un lien entre les fichiers de réponses et les montants injectés dans les conventions entre autre pour les rapports comptables des historiques des paiements.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ReponsesDemande', @level2type = N'COLUMN', @level2name = N'iID_Transaction_Convention_Ajustement_CBQ';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la transaction d''ajustement de majoration dans la convention (Un_ConventionOper) résultant de l''importation du montant de réponse de l''IQÉÉ d''une demande.  Ce champ est utile afin de maintenir un lien entre les fichiers de réponses et les montants injectés dans les conventions entre autre pour les rapports comptables des historiques des paiements.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ReponsesDemande', @level2type = N'COLUMN', @level2name = N'iID_Transaction_Convention_Ajustement_MMQ';

