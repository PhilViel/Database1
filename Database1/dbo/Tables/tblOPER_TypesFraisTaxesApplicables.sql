CREATE TABLE [dbo].[tblOPER_TypesFraisTaxesApplicables] (
    [iID_Type_Frais]     INT NOT NULL,
    [iID_Type_Parametre] INT NOT NULL,
    CONSTRAINT [PK_OPER_TypesFraisTaxesApplicables] PRIMARY KEY CLUSTERED ([iID_Type_Frais] ASC, [iID_Type_Parametre] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_OPER_TypesFraisTaxesApplicables_OPER_TypesFrais__iIDTypeFrais] FOREIGN KEY ([iID_Type_Frais]) REFERENCES [dbo].[tblOPER_TypesFrais] ([iID_Type_Frais])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table d''association d''un type de frais avec les taxes qui lui sont applicables.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_TypesFraisTaxesApplicables';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du type de frais', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_TypesFraisTaxesApplicables', @level2type = N'COLUMN', @level2name = N'iID_Type_Frais';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du type de paramètre', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_TypesFraisTaxesApplicables', @level2type = N'COLUMN', @level2name = N'iID_Type_Parametre';

