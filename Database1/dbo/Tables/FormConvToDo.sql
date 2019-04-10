CREATE TABLE [dbo].[FormConvToDo] (
    [ConventionNo]  VARCHAR (15) NOT NULL,
    [BeneficiaryID] INT          NOT NULL,
    [NomBenef]      VARCHAR (50) NOT NULL,
    [PrenomBenef]   VARCHAR (35) NOT NULL,
    [NomPR]         VARCHAR (50) NOT NULL,
    [PrenomPR]      VARCHAR (35) NOT NULL,
    [NASPR]         VARCHAR (75) NOT NULL,
    [bImpPR]        BIT          NOT NULL,
    [tiPCGType]     INT          NOT NULL,
    [tiCESPState]   INT          NOT NULL,
    [bCLB]          BIT          NOT NULL
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table des conventions à traiter dans les formulaires', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'FormConvToDo';

