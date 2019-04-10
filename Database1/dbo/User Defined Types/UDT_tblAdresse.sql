CREATE TYPE [dbo].[UDT_tblAdresse] AS TABLE (
    [iID_Source]    INT           NOT NULL,
    [iID_Adresse]   INT           NOT NULL,
    [vcNoCivique]   VARCHAR (20)  NULL,
    [vcAppartement] VARCHAR (10)  NULL,
    [vcNomRue]      VARCHAR (100) NULL,
    [iID_TypeBoite] INT           NULL,
    [vcBoite]       VARCHAR (50)  NULL,
    PRIMARY KEY CLUSTERED ([iID_Source] ASC, [iID_Adresse] ASC));

