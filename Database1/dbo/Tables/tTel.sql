CREATE TABLE [dbo].[tTel] (
    [Autom]          INT          IDENTITY (1, 1) NOT NULL,
    [Tel]            VARCHAR (27) NULL,
    [RepCode]        VARCHAR (5)  NULL,
    [ACTIF]          VARCHAR (1)  NULL,
    [Date_Vigueur]   VARCHAR (10) NULL,
    [Resiliation]    VARCHAR (10) NULL,
    [Remb_integral]  VARCHAR (10) NULL,
    [Fin_Regime]     VARCHAR (10) NULL,
    [Date24ans]      VARCHAR (10) NULL,
    [Date25ans]      VARCHAR (10) NULL,
    [LastDateBrs3]   VARCHAR (10) NULL,
    [REP_AU_DOSSIER] INT          NULL
);

