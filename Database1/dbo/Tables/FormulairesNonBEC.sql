CREATE TABLE [dbo].[FormulairesNonBEC] (
    [ConventionNo] VARCHAR (15) NULL,
    [NomBenef]     VARCHAR (50) NULL,
    [PrenomBenef]  VARCHAR (35) NULL,
    [NASBenef]     VARCHAR (75) NULL,
    [DDN]          VARCHAR (50) NULL,
    [NomSous]      VARCHAR (50) NULL,
    [PrenomSous]   VARCHAR (35) NULL,
    [NASSous]      VARCHAR (75) NULL,
    [NomTutor]     VARCHAR (50) NULL,
    [PrenomTutor]  VARCHAR (35) NULL,
    [NASTutor]     VARCHAR (75) NULL,
    [NomPR]        VARCHAR (50) NULL,
    [PrenomPR]     VARCHAR (35) NULL,
    [NASPR]        VARCHAR (75) NULL
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table contenant des informations non liées au BEC dans les formulaires', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'FormulairesNonBEC';

