CREATE TABLE [dbo].[tblOPER_TauxRendement] (
    [iID_Taux_Rendement]       INT             IDENTITY (1, 1) NOT NULL,
    [iID_Rendement]            INT             NOT NULL,
    [dtDate_Debut_Application] DATETIME        NOT NULL,
    [dtDate_Fin_Application]   DATETIME        NULL,
    [dtDate_Operation]         DATETIME        NOT NULL,
    [dTaux_Rendement]          DECIMAL (10, 3) NOT NULL,
    [dtDate_Creation]          DATETIME        CONSTRAINT [DF_OPER_TauxRendement_dtDateCreation] DEFAULT (getdate()) NOT NULL,
    [iID_Utilisateur_Creation] INT             NOT NULL,
    [iID_Operation]            INT             NULL,
    [mMontant_Genere]          MONEY           NULL,
    [dtDate_Generation]        DATETIME        NULL,
    [tCommentaire]             VARCHAR (MAX)   NULL,
    CONSTRAINT [PK_OPER_TauxRendement] PRIMARY KEY CLUSTERED ([iID_Taux_Rendement] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_OPER_TauxRendement_Mo_Human__iIDUtilisateurCreation] FOREIGN KEY ([iID_Utilisateur_Creation]) REFERENCES [dbo].[Mo_Human] ([HumanID]),
    CONSTRAINT [FK_OPER_TauxRendement_OPER_Rendements__iIDRendement] FOREIGN KEY ([iID_Rendement]) REFERENCES [dbo].[tblOPER_Rendements] ([iID_Rendement]),
    CONSTRAINT [FK_OPER_TauxRendement_Un_Oper__iIDOperation] FOREIGN KEY ([iID_Operation]) REFERENCES [dbo].[Un_Oper] ([OperID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table contenant les taux de rendements pour la génération des intérêts', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_TauxRendement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'iID_Taux_Rendement identifie tblOPER_TauxRendement', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_TauxRendement', @level2type = N'COLUMN', @level2name = N'iID_Taux_Rendement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant du rendement', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_TauxRendement', @level2type = N'COLUMN', @level2name = N'iID_Rendement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date à laquelle le taux de rendement est entrée en vigueur', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_TauxRendement', @level2type = N'COLUMN', @level2name = N'dtDate_Debut_Application';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date à laquelle le taux de rendement ne sera plus en vigueur', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_TauxRendement', @level2type = N'COLUMN', @level2name = N'dtDate_Fin_Application';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Correspond à la dernière journée du mois pour lequel on veut générer du rendement', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_TauxRendement', @level2type = N'COLUMN', @level2name = N'dtDate_Operation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Taux à lequel sera calculé le rendement', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_TauxRendement', @level2type = N'COLUMN', @level2name = N'dTaux_Rendement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date de création du taux de rendement', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_TauxRendement', @level2type = N'COLUMN', @level2name = N'dtDate_Creation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant utilisateur qui a crée le taux de rendement', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_TauxRendement', @level2type = N'COLUMN', @level2name = N'iID_Utilisateur_Creation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant d''opération du taux de rendement', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_TauxRendement', @level2type = N'COLUMN', @level2name = N'iID_Operation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Somme totale des montans générés', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_TauxRendement', @level2type = N'COLUMN', @level2name = N'mMontant_Genere';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date à laquelle le taux de rendement a été généré', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_TauxRendement', @level2type = N'COLUMN', @level2name = N'dtDate_Generation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Commentaire sur le taux de rendement', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_TauxRendement', @level2type = N'COLUMN', @level2name = N'tCommentaire';

