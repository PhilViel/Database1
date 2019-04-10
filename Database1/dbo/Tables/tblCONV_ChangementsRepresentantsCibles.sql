CREATE TABLE [dbo].[tblCONV_ChangementsRepresentantsCibles] (
    [iID_ChangementRepresentantCible] INT IDENTITY (1, 1) NOT NULL,
    [iID_ChangementRepresentant]      INT NOT NULL,
    [iID_RepresentantCible]           INT NOT NULL,
    CONSTRAINT [PK_CONV_ChangementsRepresentantsCibles] PRIMARY KEY CLUSTERED ([iID_ChangementRepresentantCible] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_CONV_ChangementsRepresentantsCibles_Un_Rep__iIDRepresentantCible] FOREIGN KEY ([iID_RepresentantCible]) REFERENCES [dbo].[Un_Rep] ([RepID]),
    CONSTRAINT [FK_tblCONV_ChangementsRepresentantsCibles_tblCONV_ChangementsRepresentants] FOREIGN KEY ([iID_ChangementRepresentant]) REFERENCES [dbo].[tblCONV_ChangementsRepresentants] ([iID_ChangementRepresentant])
);

