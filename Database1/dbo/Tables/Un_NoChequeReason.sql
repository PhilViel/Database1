CREATE TABLE [dbo].[Un_NoChequeReason] (
    [NoChequeReasonID]            [dbo].[MoID]                        IDENTITY (1, 1) NOT NULL,
    [NoChequeReason]              [dbo].[MoDesc]                      NOT NULL,
    [NoChequeReasonActive]        [dbo].[MoBitTrue]                   NOT NULL,
    [NoChequeReasonImplicationID] [dbo].[UnNoChequeReasonImplication] NOT NULL,
    CONSTRAINT [PK_Un_NoChequeReason] PRIMARY KEY CLUSTERED ([NoChequeReasonID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table contenant les différentes raisons possibles pour ne pas émettre ou émettre partiellement un chèque lors de résiliation ou de transfert OUT.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_NoChequeReason';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la raison.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_NoChequeReason', @level2type = N'COLUMN', @level2name = N'NoChequeReasonID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Raison.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_NoChequeReason', @level2type = N'COLUMN', @level2name = N'NoChequeReason';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs boolean qui indique si la raison est disponible ou non.  (= 0 : Pas disponible, <> 0 : Disponible)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_NoChequeReason', @level2type = N'COLUMN', @level2name = N'NoChequeReasonActive';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Implication de la raison (0=Aucune, 1=RES à zéro obligatoire, 2=Modification du montant du RES)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_NoChequeReason', @level2type = N'COLUMN', @level2name = N'NoChequeReasonImplicationID';

