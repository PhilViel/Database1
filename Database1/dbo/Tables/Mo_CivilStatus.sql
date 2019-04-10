CREATE TABLE [dbo].[Mo_CivilStatus] (
    [CivilStatusID]   [dbo].[MoOptionCode] NOT NULL,
    [LangID]          CHAR (3)             NOT NULL,
    [SexID]           [dbo].[MoSex]        NOT NULL,
    [CivilStatusName] [dbo].[MoDescoption] NULL,
    CONSTRAINT [PK_Mo_CivilStatus] PRIMARY KEY CLUSTERED ([CivilStatusID] ASC, [LangID] ASC, [SexID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Mo_CivilStatus_Mo_Sex__LangID_SexID] FOREIGN KEY ([SexID], [LangID]) REFERENCES [dbo].[Mo_Sex] ([SexID], [LangID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des description des statuts civils selon la langue et le sexe.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_CivilStatus';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Un caractère identifiant le statut civil. (D=Divorcé, J=Conjoint de fait, M=Marié, P=Séparé, S=Célibataire, U=Inconnu, W=Veuf)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_CivilStatus', @level2type = N'COLUMN', @level2name = N'CivilStatusID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Trois caractères identifiant la langue (Mo_Lang) de la description.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_CivilStatus', @level2type = N'COLUMN', @level2name = N'LangID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Un caractère identifiant le sexe (Mo_Sex) de la description. (F=Féminin, M=Masculin, U=Inconnu)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_CivilStatus', @level2type = N'COLUMN', @level2name = N'SexID';

