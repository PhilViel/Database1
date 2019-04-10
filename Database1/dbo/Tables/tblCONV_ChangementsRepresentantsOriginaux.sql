CREATE TABLE [dbo].[tblCONV_ChangementsRepresentantsOriginaux] (
    [ID]                         INT IDENTITY (1, 1) NOT NULL,
    [iID_ChangementRepresentant] INT NOT NULL,
    [iID_RepresentantOriginal]   INT NOT NULL,
    CONSTRAINT [PK_CONV_ChangementsRepresentantsOriginaux] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_CONV_ChangementsRepresentantsOriginaux_Un_Rep__iIDRepresentantOriginal] FOREIGN KEY ([iID_RepresentantOriginal]) REFERENCES [dbo].[Un_Rep] ([RepID]),
    CONSTRAINT [FK_tblCONV_ChangementsRepresentantsOriginaux_tblCONV_ChangementsRepresentants] FOREIGN KEY ([iID_ChangementRepresentant]) REFERENCES [dbo].[tblCONV_ChangementsRepresentants] ([iID_ChangementRepresentant]),
    CONSTRAINT [AK_CONV_ChangementsRepresentantsOriginaux_iIDChangementRepresentant_iIDRepresentantOriginal] UNIQUE NONCLUSTERED ([iID_ChangementRepresentant] ASC, [iID_RepresentantOriginal] ASC) WITH (FILLFACTOR = 90)
);

