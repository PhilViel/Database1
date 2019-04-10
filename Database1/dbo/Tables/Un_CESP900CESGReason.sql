CREATE TABLE [dbo].[Un_CESP900CESGReason] (
    [cCESP900CESGReasonID] CHAR (1)      NOT NULL,
    [vcCESP900CESGReason]  VARCHAR (200) NOT NULL,
    CONSTRAINT [PK_Un_CESP900CESGReason] PRIMARY KEY CLUSTERED ([cCESP900CESGReasonID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des raisons de non-paiements SCEE de base, BEC et subvention provinciale', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP900CESGReason';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de la raison de non paiement de SCEE de base, BEC et subvention provinciale', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP900CESGReason', @level2type = N'COLUMN', @level2name = N'cCESP900CESGReasonID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Raison de non paiement de SCEE de base, BEC et subvention provinciale', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP900CESGReason', @level2type = N'COLUMN', @level2name = N'vcCESP900CESGReason';

