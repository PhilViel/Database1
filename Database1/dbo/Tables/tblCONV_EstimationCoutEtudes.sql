CREATE TABLE [dbo].[tblCONV_EstimationCoutEtudes] (
    [iID_Estimation_Cout_Etudes]    INT           IDENTITY (1, 1) NOT NULL,
    [vcCode_Estimation_Cout_Etudes] VARCHAR (100) NOT NULL,
    [vcDescription]                 VARCHAR (150) NOT NULL,
    CONSTRAINT [PK_CONV_EstimationCoutEtudes] PRIMARY KEY CLUSTERED ([iID_Estimation_Cout_Etudes] ASC) WITH (FILLFACTOR = 90)
);

