CREATE TABLE [dbo].[tblOPER_RendementTaux] (
    [iID_RendementTaux]    INT            IDENTITY (1, 1) NOT NULL,
    [iID_Taux_Rendement]   INT            NOT NULL,
    [PlanID]               INT            NOT NULL,
    [dTaux_AvantDelaiRI]   DECIMAL (6, 3) NULL,
    [dTaux_ApresDelaiRI]   DECIMAL (6, 3) NULL,
    [dTaux_Individuel]     DECIMAL (6, 3) NULL,
    [dTaux_Individuel_RIO] DECIMAL (6, 3) NULL,
    CONSTRAINT [PK_OPER_RendementTaux] PRIMARY KEY CLUSTERED ([iID_RendementTaux] ASC) WITH (FILLFACTOR = 90)
);

