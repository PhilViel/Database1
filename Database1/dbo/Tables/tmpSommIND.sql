CREATE TABLE [dbo].[tmpSommIND] (
    [TypeConvention] VARCHAR (5)       NOT NULL,
    [conventionno]   VARCHAR (15)      NOT NULL,
    [DateOuverture]  [dbo].[MoGetDate] NULL,
    [Épargne]        MONEY             NOT NULL,
    [RendInd]        MONEY             NOT NULL,
    [SCEE]           MONEY             NULL,
    [RendSCEE]       MONEY             NULL,
    [BEC]            MONEY             NOT NULL,
    [RendBEC]        MONEY             NOT NULL,
    [IQEE]           MONEY             NULL,
    [RendIQEE]       MONEY             NULL
);

