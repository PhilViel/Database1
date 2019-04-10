CREATE TABLE [dbo].[tblOPER_TypesFrais] (
    [iID_Type_Frais]           INT           IDENTITY (1, 1) NOT NULL,
    [vcCode_Type_Frais]        VARCHAR (10)  NOT NULL,
    [vcDescription_Type_Frais] VARCHAR (250) NOT NULL,
    [mMontant_Defaut]          MONEY         NOT NULL,
    [iOrdre_Presentation]      INT           NOT NULL,
    [bInd_Visible_Utilisateur] BIT           NOT NULL,
    CONSTRAINT [PK_OPER_TypesFrais] PRIMARY KEY CLUSTERED ([iID_Type_Frais] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table opérationelle référençant les types de frais', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_TypesFrais';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du type de frais', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_TypesFrais', @level2type = N'COLUMN', @level2name = N'iID_Type_Frais';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code du type de frais', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_TypesFrais', @level2type = N'COLUMN', @level2name = N'vcCode_Type_Frais';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description du type de frais', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_TypesFrais', @level2type = N'COLUMN', @level2name = N'vcDescription_Type_Frais';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant par défaut du type de frais', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_TypesFrais', @level2type = N'COLUMN', @level2name = N'mMontant_Defaut';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ordre de présentation du type de frais', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_TypesFrais', @level2type = N'COLUMN', @level2name = N'iOrdre_Presentation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur de visibilité du type de frais', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_TypesFrais', @level2type = N'COLUMN', @level2name = N'bInd_Visible_Utilisateur';

