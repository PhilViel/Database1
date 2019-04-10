CREATE TABLE [dbo].[Un_UnitReductionReason] (
    [UnitReductionReasonID]      [dbo].[MoID]      IDENTITY (1, 1) NOT NULL,
    [UnitReductionReason]        [dbo].[MoDesc]    NOT NULL,
    [UnitReductionReasonActive]  [dbo].[MoBitTrue] NOT NULL,
    [bReduitTauxConservationRep] BIT               CONSTRAINT [DF_Un_UnitReductionReason_bReduitTauxConservationRep] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_Un_UnitReductionReason] PRIMARY KEY CLUSTERED ([UnitReductionReasonID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des raisons de réductions d''unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitReductionReason';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la raison de réductions d''unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitReductionReason', @level2type = N'COLUMN', @level2name = N'UnitReductionReasonID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'La raison de réductions d''unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitReductionReason', @level2type = N'COLUMN', @level2name = N'UnitReductionReason';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs boolean non informant si la raison est présentement disponible dans la liste des raisons si on fait une nouvelle réduction (Résiliation et Transfert OUT) ou une modification de réduction d''unités présentement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitReductionReason', @level2type = N'COLUMN', @level2name = N'UnitReductionReasonActive';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Champ booléen permettant de déterminer si la raison de résiliation réduit le taux de conservation du représentant lorsqu''utilisée pour une résiliation ou un transfert.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitReductionReason', @level2type = N'COLUMN', @level2name = N'bReduitTauxConservationRep';

