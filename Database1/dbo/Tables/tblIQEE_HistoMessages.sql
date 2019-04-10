CREATE TABLE [dbo].[tblIQEE_HistoMessages] (
    [iID_Message]         INT            IDENTITY (1, 1) NOT NULL,
    [vcCode_Message]      VARCHAR (3)    NOT NULL,
    [vcDescription]       VARCHAR (1000) NOT NULL,
    [vcCode_Droit]        VARCHAR (75)   NULL,
    [iOrdre_Presentation] INT            NOT NULL,
    CONSTRAINT [PK_IQEE_HistoMessages] PRIMARY KEY CLUSTERED ([iID_Message] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_IQEE_HistoMessages_vcCodeMessage]
    ON [dbo].[tblIQEE_HistoMessages]([vcCode_Message] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index unique sur le code de message d''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoMessages', @level2type = N'INDEX', @level2name = N'AK_IQEE_HistoMessages_vcCodeMessage';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur l''identifiant unique du message d''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoMessages', @level2type = N'CONSTRAINT', @level2name = N'PK_IQEE_HistoMessages';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table de référence des messages analysant ou rendant état de l''IQÉÉ pour une convention.  Les messages peuvent être affichés dans l''historique de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoMessages';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du message de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoMessages', @level2type = N'COLUMN', @level2name = N'iID_Message';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code unique du message de l''IQÉÉ.  Il peut être codé en dur dans la programmation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoMessages', @level2type = N'COLUMN', @level2name = N'vcCode_Message';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description du message de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoMessages', @level2type = N'COLUMN', @level2name = N'vcDescription';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code du droit d''utilisateur qui est lié au message de l''IQÉÉ.  Si l''utilisateur ne possède pas ce droit, ce message n''est pas affiché à l''utilisateur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoMessages', @level2type = N'COLUMN', @level2name = N'vcCode_Droit';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ordre d''affichage des messages dans les interfaces.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoMessages', @level2type = N'COLUMN', @level2name = N'iOrdre_Presentation';

