CREATE TABLE [dbo].[Un_SaleSource] (
    [SaleSourceID]     [dbo].[MoID]   IDENTITY (1, 1) NOT NULL,
    [SaleSourceDesc]   [dbo].[MoDesc] NOT NULL,
    [bIsContestWinner] BIT            CONSTRAINT [DF_Un_SaleSource_bIsContestWinner] DEFAULT (0) NOT NULL,
    CONSTRAINT [PK_Un_SaleSource] PRIMARY KEY CLUSTERED ([SaleSourceID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des traitements de commissions.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_SaleSource';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la source de ventes.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_SaleSource', @level2type = N'COLUMN', @level2name = N'SaleSourceID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'La source de ventes.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_SaleSource', @level2type = N'COLUMN', @level2name = N'SaleSourceDesc';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'bIsContestWinner	BIT		Gagnant de concours (1=Oui, 0=Non)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_SaleSource', @level2type = N'COLUMN', @level2name = N'bIsContestWinner';

