CREATE TABLE [dbo].[tblCONV_Justification] (
    [iID_Justification]    INT           IDENTITY (1, 1) NOT NULL,
    [vcCode_Justification] VARCHAR (100) NOT NULL,
    [vcDescription]        VARCHAR (150) NOT NULL,
    CONSTRAINT [PK_CONV_Justification] PRIMARY KEY CLUSTERED ([iID_Justification] ASC) WITH (FILLFACTOR = 90)
);

