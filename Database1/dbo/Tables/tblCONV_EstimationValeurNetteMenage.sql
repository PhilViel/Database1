CREATE TABLE [dbo].[tblCONV_EstimationValeurNetteMenage] (
    [iID_Estimation_Valeur_Nette_Menage]    INT           IDENTITY (1, 1) NOT NULL,
    [vcCode_Estimation_Valeur_Nette_Menage] VARCHAR (100) NOT NULL,
    [vcDescription]                         VARCHAR (150) NOT NULL,
    CONSTRAINT [PK_CONV_EstimationValeurNetteMenage] PRIMARY KEY CLUSTERED ([iID_Estimation_Valeur_Nette_Menage] ASC) WITH (FILLFACTOR = 90)
);

