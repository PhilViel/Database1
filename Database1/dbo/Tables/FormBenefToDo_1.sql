CREATE TABLE [dbo].[FormBenefToDo#1] (
    [BeneficiaryID] INT          NOT NULL,
    [NomBenef]      VARCHAR (50) NOT NULL,
    [PrenomBenef]   VARCHAR (35) NOT NULL,
    [NomTutor]      VARCHAR (50) NOT NULL,
    [PrenomTutor]   VARCHAR (35) NOT NULL,
    [NASTutor]      VARCHAR (75) NULL,
    [NomPR]         VARCHAR (50) NOT NULL,
    [PrenomPR]      VARCHAR (35) NOT NULL,
    [NASPR]         VARCHAR (75) NOT NULL,
    [bImpTutor]     BIT          NOT NULL,
    [bImpPR]        BIT          NOT NULL,
    [tiPCGType]     INT          NOT NULL,
    [TutorSex]      CHAR (1)     NOT NULL,
    [tiCESPState]   INT          NOT NULL,
    [bCLB]          BIT          NOT NULL
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table de bénéficiaires à traiter dans les formulaires', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'FormBenefToDo#1';

