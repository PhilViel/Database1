CREATE TABLE [dbo].[tblREPR_Matieres] (
    [iID_Matiere]   INT           IDENTITY (1, 1) NOT NULL,
    [vcMatiere]     VARCHAR (25)  NOT NULL,
    [vcDescription] VARCHAR (250) NULL,
    [bActif]        BIT           NOT NULL,
    CONSTRAINT [PK_REPR_Matieres] PRIMARY KEY CLUSTERED ([iID_Matiere] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Titre de la matiere', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_Matieres', @level2type = N'COLUMN', @level2name = N'vcMatiere';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Détails du contenu pédagogique de la matière qui a été validé par la CSF', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_Matieres', @level2type = N'COLUMN', @level2name = N'vcDescription';

