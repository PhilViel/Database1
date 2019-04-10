CREATE TABLE [dbo].[tblOPER_Frais] (
    [iID_Frais]                  INT      IDENTITY (1, 1) NOT NULL,
    [iID_Oper]                   INT      NOT NULL,
    [iID_Type_Frais]             INT      NOT NULL,
    [mMontant_Frais]             MONEY    NOT NULL,
    [iID_Utilisateur_Creation]   INT      NOT NULL,
    [dtDate_Creation]            DATETIME NOT NULL,
    [iID_Utilisateur_Annulation] INT      NULL,
    [dtDate_Annulation]          DATETIME NULL,
    CONSTRAINT [PK_OPER_Frais] PRIMARY KEY CLUSTERED ([iID_Frais] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_OPER_Frais_OPER_TypesFrais__iIDTypeFrais] FOREIGN KEY ([iID_Type_Frais]) REFERENCES [dbo].[tblOPER_TypesFrais] ([iID_Type_Frais]),
    CONSTRAINT [FK_OPER_Frais_Un_Oper__iIDOper] FOREIGN KEY ([iID_Oper]) REFERENCES [dbo].[Un_Oper] ([OperID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table opérationnelle pour la gestion des frais', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_Frais';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID unique d''un frais', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_Frais', @level2type = N'COLUMN', @level2name = N'iID_Frais';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID unique de l''opération à laquelle appartient le frais', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_Frais', @level2type = N'COLUMN', @level2name = N'iID_Oper';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID unique du type de frais auquel appartient le frais', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_Frais', @level2type = N'COLUMN', @level2name = N'iID_Type_Frais';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant du frais (hors taxes s''il y en a)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_Frais', @level2type = N'COLUMN', @level2name = N'mMontant_Frais';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID unique de l''utilisateur qui a engendré la création du frais', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_Frais', @level2type = N'COLUMN', @level2name = N'iID_Utilisateur_Creation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date de création du frais', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_Frais', @level2type = N'COLUMN', @level2name = N'dtDate_Creation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID unique de l''utilisateur ayant annulé le frais', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_Frais', @level2type = N'COLUMN', @level2name = N'iID_Utilisateur_Annulation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date d''annulation du frais', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_Frais', @level2type = N'COLUMN', @level2name = N'dtDate_Annulation';

