CREATE TABLE [dbo].[tblREPR_FormationsRepresentants] (
    [iID_FormationRepresentant] INT             IDENTITY (1, 1) NOT NULL,
    [iID_Formation]             INT             NOT NULL,
    [iID_Representant]          INT             NOT NULL,
    [nNote_Examen]              NUMERIC (18, 2) NULL,
    [vcCommentaire]             VARCHAR (250)   NULL,
    CONSTRAINT [PK_REPR_FormationsRepresentants] PRIMARY KEY CLUSTERED ([iID_FormationRepresentant] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_REPR_FormationsRepresentants_REPR_Formations__iIDFormation] FOREIGN KEY ([iID_Formation]) REFERENCES [dbo].[tblREPR_Formations] ([iID_Formation]),
    CONSTRAINT [FK_REPR_FormationsRepresentants_Un_Rep__iIDRepresentant] FOREIGN KEY ([iID_Representant]) REFERENCES [dbo].[Un_Rep] ([RepID])
);

