CREATE TABLE [dbo].[tblREPR_FormationsUFCMatieres] (
    [iID_FormationUFCMatiere] INT             IDENTITY (1, 1) NOT NULL,
    [iID_FormationUFC]        INT             NOT NULL,
    [iID_Matiere]             INT             NOT NULL,
    [iCredit_UFC]             INT             NULL,
    [nNombre_Heure]           NUMERIC (18, 2) NULL,
    CONSTRAINT [PK_REPR_FormationsUFCMatieres] PRIMARY KEY CLUSTERED ([iID_FormationUFCMatiere] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_REPR_FormationsUFCMatieres_REPR_FormationsUFC__iIDFormationUFC] FOREIGN KEY ([iID_FormationUFC]) REFERENCES [dbo].[tblREPR_FormationsUFC] ([iID_FormationUFC]),
    CONSTRAINT [FK_REPR_FormationsUFCMatieres_REPR_Matieres__iIDMatiere] FOREIGN KEY ([iID_Matiere]) REFERENCES [dbo].[tblREPR_Matieres] ([iID_Matiere])
);

