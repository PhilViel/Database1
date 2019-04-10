CREATE TABLE [dbo].[Un_CESP400Type] (
    [tiCESP400TypeID]  TINYINT       NOT NULL,
    [vcCESP400Type]    VARCHAR (200) NOT NULL,
    [bNegOnreceive]    BIT           NOT NULL,
    [bUpdateOnReceive] BIT           NOT NULL,
    CONSTRAINT [PK_Un_CESP400Type] PRIMARY KEY CLUSTERED ([tiCESP400TypeID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des types de transactions 400', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400Type';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID du type de transaction 400', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400Type', @level2type = N'COLUMN', @level2name = N'tiCESP400TypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Type de transaction 400', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400Type', @level2type = N'COLUMN', @level2name = N'vcCESP400Type';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Indique si on doit multiplier par -1 le montant retourné par le PCEE lors de l''importation du fichier de retour', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400Type', @level2type = N'COLUMN', @level2name = N'bNegOnreceive';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Indique si on doit mettre à jour un enregistrement 900 ou en créer un nouveau pour ce type de 400 lors de la réception du fichier de retour.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400Type', @level2type = N'COLUMN', @level2name = N'bUpdateOnReceive';

