CREATE TABLE [dbo].[Xx_CESPDiffFromCorrection] (
    [OperID]  INT   NOT NULL,
    [fCESG]   MONEY NOT NULL,
    [fACESG]  MONEY NOT NULL,
    [fCLB]    MONEY NOT NULL,
    [fCLBFee] MONEY NOT NULL,
    CONSTRAINT [PK_Xx_CESPDiffFromCorrection] PRIMARY KEY CLUSTERED ([OperID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table des différences des montants CESP suite à des corrections', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Xx_CESPDiffFromCorrection';

