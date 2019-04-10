CREATE TABLE [dbo].[tblIQEE_RaisonsAnnulation] (
    [iID_Raison_Annulation]                       INT           IDENTITY (1, 1) NOT NULL,
    [vcCode_Raison]                               VARCHAR (50)  NOT NULL,
    [vcDescription]                               VARCHAR (200) NOT NULL,
    [bActif]                                      BIT           NOT NULL,
    [iID_Type_Annulation]                         INT           NOT NULL,
    [tiID_Type_Enregistrement]                    TINYINT       NOT NULL,
    [iID_Sous_Type]                               INT           NULL,
    [dtDate_Debut_Application]                    DATETIME      NOT NULL,
    [dtDate_Fin_Application]                      DATETIME      NULL,
    [bAccessible_Utilisateur]                     BIT           NOT NULL,
    [tCommentaires_Utilisateur]                   TEXT          NULL,
    [tCommentaires_TI]                            TEXT          NULL,
    [iOrdre_Presentation]                         INT           NULL,
    [bApplicable_Aux_Simulations]                 BIT           NOT NULL,
    [bAffecte_Infos_Pas_Amendable]                BIT           NOT NULL,
    [bAnnuler_Transactions_Depuis_Debut]          BIT           NOT NULL,
    [bAnnuler_Transactions_Subsequentes]          BIT           NOT NULL,
    [bProgrammation_Force_Informations]           BIT           NOT NULL,
    [bAnnuler_Annulation_Transactions_Identiques] BIT           NOT NULL,
    [bObligation_Reprendre_Transaction]           BIT           NOT NULL,
    CONSTRAINT [PK_IQEE_RaisonsAnnulation] PRIMARY KEY CLUSTERED ([iID_Raison_Annulation] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_IQEE_RaisonsAnnulation_IQEE_TypesAnnulation__iIDTypeAnnulation] FOREIGN KEY ([iID_Type_Annulation]) REFERENCES [dbo].[tblIQEE_TypesAnnulation] ([iID_Type_Annulation])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_IQEE_RaisonsAnnulation_vcCodeRaison]
    ON [dbo].[tblIQEE_RaisonsAnnulation]([vcCode_Raison] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index unique sur le code de raison.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RaisonsAnnulation', @level2type = N'INDEX', @level2name = N'AK_IQEE_RaisonsAnnulation_vcCodeRaison';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur la clé primaire soit l''identifiant de la raison d''annulation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RaisonsAnnulation', @level2type = N'CONSTRAINT', @level2name = N'PK_IQEE_RaisonsAnnulation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Liste des raisons menant à l''annulation et reprise de transactions de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RaisonsAnnulation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la raison de l''annulation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RaisonsAnnulation', @level2type = N'COLUMN', @level2name = N'iID_Raison_Annulation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code unique de la raison d''annulation.  Ce code peut être codé en dur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RaisonsAnnulation', @level2type = N'COLUMN', @level2name = N'vcCode_Raison';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description de la raison d''annulation.  Elle est affichée dans l''historique de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RaisonsAnnulation', @level2type = N'COLUMN', @level2name = N'vcDescription';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur si la raison d''annulation est active ou non.  C''est une option pour le support informatique pour désactiver une raison d''annulation qui poserait temporairement des problèmes.  Les dates de début et de fin d''application sont également pris en compte lorsque les programmes doivent déterminer si une raison d''annulation est active ou non.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RaisonsAnnulation', @level2type = N'COLUMN', @level2name = N'bActif';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du type d''annulation de la raison de l''annulation.  Il est relié à la table "tblIQEE_TypesAnnulation".', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RaisonsAnnulation', @level2type = N'COLUMN', @level2name = N'iID_Type_Annulation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du type d''enregistrement sur lequel s''applique la raison d''annulation.  Une raison d''annulation qui s''applique à plusieurs types d''enregistrement doit faire l''objet d''autant de raisons d''annulation dans cette table.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RaisonsAnnulation', @level2type = N'COLUMN', @level2name = N'tiID_Type_Enregistrement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du sous-type d''enregistrement sur lequel s''applique la raison d''annulation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RaisonsAnnulation', @level2type = N'COLUMN', @level2name = N'iID_Sous_Type';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date de début d''application de la raison d''annulation.  Avant cette date, la raison d''annulation n''existait pas.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RaisonsAnnulation', @level2type = N'COLUMN', @level2name = N'dtDate_Debut_Application';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date de fin d''application de la raison d''annulation.  Après cette date, la raison d''annulation n''était plus applicable.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RaisonsAnnulation', @level2type = N'COLUMN', @level2name = N'dtDate_Fin_Application';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur si l''utilisateur peut utiliser ou non cette raison d''annulation.  Cela s''applique uniquement aux raisons d''annulation de type "Manuelle".  Si elle n''est pas accessible à l''utilisateur, celui-ci ne peux pas la sélectionnée dans l''interface.  Elle reste alors disponible uniquement pour l''informatique.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RaisonsAnnulation', @level2type = N'COLUMN', @level2name = N'bAccessible_Utilisateur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Commentaires ou description plus complète de la raison d''annulation qui pourra s''afficher à l''interface pour que l''utilisateur ai plus d''informations sur le choix de cette raison d''annulation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RaisonsAnnulation', @level2type = N'COLUMN', @level2name = N'tCommentaires_Utilisateur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Commentaires ou description plus complète à l''attention de l''informatique qui sert à conserver dans le temps des informations sur le développement de la raison d''annulation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RaisonsAnnulation', @level2type = N'COLUMN', @level2name = N'tCommentaires_TI';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ordre de présentation des raisons d''annulation disponibles aux utilisateurs.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RaisonsAnnulation', @level2type = N'COLUMN', @level2name = N'iOrdre_Presentation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur si la raison d''annulation s''applique ou non aux simulations.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RaisonsAnnulation', @level2type = N'COLUMN', @level2name = N'bApplicable_Aux_Simulations';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur qui permet de savoir si la raison d''annulation implique ou non des modifications à des informations pas amendable selon RQ.  Si c''est le cas d''autres transactions ayant la même information pourrait devoir également être annulées.  Les transactions de reprises doivent être reprises comme des transactions d''origine si elle touche des informations pas amendables.  Le type d''annulation  des autres transactions à annuler sont du même type que celle d''origine.  Cela signifie qu''une demande d''annulation demandée manuellement par l''utilisateur sur une transaction pour une raison d''annulation qui doit affecter des informations pas amendable, pourra causer d''autres demandes d''annulation et ces demandes annulations seront aussi de type "manuelle".  Même chose pour les demandes d''annulation automatiques.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RaisonsAnnulation', @level2type = N'COLUMN', @level2name = N'bAffecte_Infos_Pas_Amendable';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur que la raison d''annulation requière oui ou non l''annulation des transactions de la convention depuis le début soit la première transaction de la convention qui a été transmise à RQ.  Cette option déclenche la reprise des transactions depuis le début avec le même comportement que pour les transactions où l''on modifie des informations pas amendables sauf qu''à la différence que les transactions annulées doivent être reprises comme des transactions de reprise et que le type d''annulation des autres demandes d''annulation seront du type "conséquence".', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RaisonsAnnulation', @level2type = N'COLUMN', @level2name = N'bAnnuler_Transactions_Depuis_Debut';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur que la raison d''annulation requière oui ou non l''annulation des transactions subséquentes à la transaction annulée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RaisonsAnnulation', @level2type = N'COLUMN', @level2name = N'bAnnuler_Transactions_Subsequentes';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur si la programmation de la création des transactions a été modifiée pour forcer des informations dans les transactions de l''IQÉÉ contraire aux informations contenu dans UniAccès pour des raisons spécifiques.  Cette information ne provoque pas d''action.  C''est simplement à titre indicatif.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RaisonsAnnulation', @level2type = N'COLUMN', @level2name = N'bProgrammation_Force_Informations';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur si une transaction de reprise suite à une annulation pour cette raison d''annulation doit être ou non transmise à RQ si elle est identique à la transaction d''origine qui est annulée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RaisonsAnnulation', @level2type = N'COLUMN', @level2name = N'bAnnuler_Annulation_Transactions_Identiques';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur si la raison d''annulation requière ou non une reprise de la transaction.  Présentement, les NID oblige la reprise des transactions de demande de l''IQÉÉ (type 02).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RaisonsAnnulation', @level2type = N'COLUMN', @level2name = N'bObligation_Reprendre_Transaction';

