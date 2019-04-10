CREATE TABLE [dbo].[tblIQEE_TypesReponse] (
    [tiID_Type_Reponse]              TINYINT       IDENTITY (1, 1) NOT NULL,
    [vcCode]                         VARCHAR (3)   NOT NULL,
    [vcDescription]                  VARCHAR (100) NOT NULL,
    [cID_Type_Operation_Convention]  CHAR (3)      NULL,
    [bInverser_Signe_Pour_Injection] BIT           NULL,
    CONSTRAINT [PK_IQEE_TypesReponse] PRIMARY KEY CLUSTERED ([tiID_Type_Reponse] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_IQEE_TypesReponse_vcCode]
    ON [dbo].[tblIQEE_TypesReponse]([vcCode] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur le code du type de réponse.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TypesReponse', @level2type = N'INDEX', @level2name = N'AK_IQEE_TypesReponse_vcCode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index de la clé primaire du type de réponse.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TypesReponse', @level2type = N'CONSTRAINT', @level2name = N'PK_IQEE_TypesReponse';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Liste des types de réponse reçus de RQ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TypesReponse';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''un type de réponse reçu de RQ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TypesReponse', @level2type = N'COLUMN', @level2name = N'tiID_Type_Reponse';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code d''un type de réponse.  Ce code peut être codé en dur dans la programmation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TypesReponse', @level2type = N'COLUMN', @level2name = N'vcCode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description du type de réponse.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TypesReponse', @level2type = N'COLUMN', @level2name = N'vcDescription';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du type d''opération sur une convention (Un_ConventionOperType).  S''il y a un code dans ce champ, le montant de la réponse est transféré automatiquement dans les opérations sur les conventions (Un_ConventionOper) lors de l''importation du fichier de réponse.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TypesReponse', @level2type = N'COLUMN', @level2name = N'cID_Type_Operation_Convention';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur qui permet d''inverser le signe de la réponse de RQ lors de l''injection du montant dans les opérations sur les conventions (Un_ConventionOper) lors de l''importation du fichier de réponse.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TypesReponse', @level2type = N'COLUMN', @level2name = N'bInverser_Signe_Pour_Injection';

