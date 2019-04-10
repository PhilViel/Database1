CREATE TABLE [dbo].[tblCONV_ObjectifsInvestissement] (
    [iID_Objectif_Investissement]    INT           IDENTITY (1, 1) NOT NULL,
    [vcCode_Objectif_Investissement] VARCHAR (100) NOT NULL,
    [siID_LigneCritere]              SMALLINT      NOT NULL,
    [vcDescription]                  VARCHAR (150) NOT NULL,
    CONSTRAINT [PK_CONV_ObjectifsInvestissement] PRIMARY KEY CLUSTERED ([iID_Objectif_Investissement] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table des codes liés aux objectifs de placement des investisseurs', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ObjectifsInvestissement';

