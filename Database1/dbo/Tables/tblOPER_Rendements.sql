CREATE TABLE [dbo].[tblOPER_Rendements] (
    [iID_Rendement]           INT      IDENTITY (1, 1) NOT NULL,
    [dtDate_Calcul_Rendement] DATETIME NOT NULL,
    [tiID_Type_Rendement]     TINYINT  NOT NULL,
    CONSTRAINT [PK_OPER_Rendements] PRIMARY KEY CLUSTERED ([iID_Rendement] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_OPER_Rendements_OPER_TypesRendement__tiIDTypeRendement] FOREIGN KEY ([tiID_Type_Rendement]) REFERENCES [dbo].[tblOPER_TypesRendement] ([tiID_Type_Rendement])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_OPER_Rendements_dtDateCalculRendement_tiIDTypeRendement]
    ON [dbo].[tblOPER_Rendements]([dtDate_Calcul_Rendement] ASC, [tiID_Type_Rendement] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table contenant les types rendements et la date de calcul pour la génération des intérêts', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_Rendements';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la table des taux d''intérêts', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_Rendements', @level2type = N'COLUMN', @level2name = N'iID_Rendement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Correspond à la dernière journée du mois pour lequel on veut générer du rendement', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_Rendements', @level2type = N'COLUMN', @level2name = N'dtDate_Calcul_Rendement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Correspond au type de rendement pour lequel on veut générer du rendement', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_Rendements', @level2type = N'COLUMN', @level2name = N'tiID_Type_Rendement';

