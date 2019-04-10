CREATE TABLE [dbo].[tblREPR_FormationsUFC] (
    [iID_FormationUFC]      INT           IDENTITY (1, 1) NOT NULL,
    [vcTitre_FormationUFC]  VARCHAR (250) NOT NULL,
    [vcNumero_FormationUFC] VARCHAR (20)  NOT NULL,
    [dtDate_Debut]          DATETIME      NOT NULL,
    [dtDate_Fin]            DATETIME      NOT NULL,
    [iID_TypeFormation]     INT           NOT NULL,
    CONSTRAINT [PK_REPR_FormationsUFC] PRIMARY KEY CLUSTERED ([iID_FormationUFC] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_REPR_FormationsUFC_REPR_FormationsTypes__iIDTypeFormation] FOREIGN KEY ([iID_TypeFormation]) REFERENCES [dbo].[tblREPR_FormationsTypes] ([iID_TypeFormation]),
    CONSTRAINT [FK_REPR_FormationsUFC_REPR_FormationsUFC__iIDFormationUFC] FOREIGN KEY ([iID_FormationUFC]) REFERENCES [dbo].[tblREPR_FormationsUFC] ([iID_FormationUFC])
);

