CREATE TABLE [dbo].[tblOPER_TypesRendement] (
    [tiID_Type_Rendement]     TINYINT       IDENTITY (1, 1) NOT NULL,
    [vcCode_Rendement]        VARCHAR (3)   NOT NULL,
    [vcDescription]           VARCHAR (100) NOT NULL,
    [siOrdrePresentation]     SMALLINT      NOT NULL,
    [siOrdreGenererRendement] SMALLINT      NOT NULL,
    [vcCode_Rendement_Enfant] VARCHAR (3)   NULL,
    CONSTRAINT [PK_OPER_TypesRendement] PRIMARY KEY CLUSTERED ([tiID_Type_Rendement] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table contenant les types de taux de rendements pour la génération des intérêts', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_TypesRendement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'tiID_Type_Rendement identifie tblOPER_TypesRendement', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_TypesRendement', @level2type = N'COLUMN', @level2name = N'tiID_Type_Rendement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code de rendement qui est associé au type de rendement', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_TypesRendement', @level2type = N'COLUMN', @level2name = N'vcCode_Rendement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description du type de rendement', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_TypesRendement', @level2type = N'COLUMN', @level2name = N'vcDescription';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Order dans lequel le type de rendement doit-être affiché', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_TypesRendement', @level2type = N'COLUMN', @level2name = N'siOrdrePresentation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ordre dans lequel le type de rendement doit-être généré', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_TypesRendement', @level2type = N'COLUMN', @level2name = N'siOrdreGenererRendement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code du type de rendement-enfant qui est relié', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_TypesRendement', @level2type = N'COLUMN', @level2name = N'vcCode_Rendement_Enfant';

