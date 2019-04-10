CREATE TABLE [dbo].[tmpresult_VenteUniteBruteEtNette_ParRep_PourTableaudeBord] (
    [RepID]         [dbo].[MoID]         NOT NULL,
    [RepCode]       [dbo].[MoDescoption] NULL,
    [RepName]       VARCHAR (86)         NULL,
    [BusinessStart] DATE                 NULL,
    [BusinessEnd]   DATE                 NULL,
    [UniteBrut]     FLOAT (53)           NULL,
    [UniteNet]      FLOAT (53)           NULL,
    [Agence]        VARCHAR (86)         NULL,
    [ConsPctGUI]    FLOAT (53)           NULL
);

