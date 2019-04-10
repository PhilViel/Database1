CREATE TABLE [dbo].[tblCONV_HistoriqueRepComActif] (
    [iID_HistoriqueRepComActif] INT          IDENTITY (1, 1) NOT NULL,
    [UnitID]                    INT          NOT NULL,
    [dtDateDebut]               DATETIME     NOT NULL,
    [RepID]                     INT          NOT NULL,
    [LoginName]                 VARCHAR (50) NULL,
    CONSTRAINT [PK_CONV_HistoriqueRepComActif] PRIMARY KEY CLUSTERED ([iID_HistoriqueRepComActif] ASC),
    CONSTRAINT [FK_CONV_HistoriqueRepComActif_Un_Rep__RepID] FOREIGN KEY ([RepID]) REFERENCES [dbo].[Un_Rep] ([RepID]),
    CONSTRAINT [FK_CONV_HistoriqueRepComActif_Un_Unit__UnitID] FOREIGN KEY ([UnitID]) REFERENCES [dbo].[Un_Unit] ([UnitID])
);

