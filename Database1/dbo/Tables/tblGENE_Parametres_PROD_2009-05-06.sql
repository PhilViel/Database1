CREATE TABLE [dbo].[tblGENE_Parametres_PROD_2009-05-06] (
    [iID_Parametre_Applicatif] INT            NOT NULL,
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

