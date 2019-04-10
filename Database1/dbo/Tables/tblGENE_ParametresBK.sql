CREATE TABLE [dbo].[tblGENE_ParametresBK] (
    [iID_Parametre_Applicatif] INT            IDENTITY (1, 1) NOT NULL,
    [iID_Type_Parametre]       INT            NOT NULL,
    [vcDimension1]             VARCHAR (100)  NULL,
    [vcDimension2]             VARCHAR (100)  NULL,
    [vcDimension3]             VARCHAR (100)  NULL,
    [vcDimension4]             VARCHAR (100)  NULL,
    [vcDimension5]             VARCHAR (100)  NULL,
    [dtDate_Debut_Application] DATETIME       NOT NULL,
    [dtDate_Fin_Application]   DATETIME       NULL,
    [vcValeur_Parametre]       VARCHAR (2000) NULL
);

