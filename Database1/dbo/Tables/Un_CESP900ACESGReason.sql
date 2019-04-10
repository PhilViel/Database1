CREATE TABLE [dbo].[Un_CESP900ACESGReason] (
    [cCESP900ACESGReasonID] CHAR (1)      NOT NULL,
    [vcCESP900ACESGReason]  VARCHAR (200) NOT NULL,
    CONSTRAINT [PK_Un_CESP900ACESGReason] PRIMARY KEY CLUSTERED ([cCESP900ACESGReasonID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des raisons de non-paiements SCEE supplémentaire', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP900ACESGReason';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de la raison de non paiement de SCEE supplémentaire', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP900ACESGReason', @level2type = N'COLUMN', @level2name = N'cCESP900ACESGReasonID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Raison de non paiement de SCEE supplémentaire', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP900ACESGReason', @level2type = N'COLUMN', @level2name = N'vcCESP900ACESGReason';

