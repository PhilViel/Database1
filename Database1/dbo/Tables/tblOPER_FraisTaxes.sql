CREATE TABLE [dbo].[tblOPER_FraisTaxes] (
    [iID_Frais]          INT   NOT NULL,
    [iID_Type_Parametre] INT   NOT NULL,
    [mMontant_Taxe]      MONEY NOT NULL,
    CONSTRAINT [PK_OPER_FraisTaxes] PRIMARY KEY CLUSTERED ([iID_Frais] ASC, [iID_Type_Parametre] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_OPER_FraisTaxes_OPER_Frais__iIDFrais] FOREIGN KEY ([iID_Frais]) REFERENCES [dbo].[tblOPER_Frais] ([iID_Frais])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table d''association d''un frais avec les taxes qui lui sont appliquées.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_FraisTaxes';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du frais', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_FraisTaxes', @level2type = N'COLUMN', @level2name = N'iID_Frais';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du type de paramètre (taxe) associé au frais', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_FraisTaxes', @level2type = N'COLUMN', @level2name = N'iID_Type_Parametre';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant de la taxe applicable au frais', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_FraisTaxes', @level2type = N'COLUMN', @level2name = N'mMontant_Taxe';

