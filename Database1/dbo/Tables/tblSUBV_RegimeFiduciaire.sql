CREATE TABLE [dbo].[tblSUBV_RegimeFiduciaire] (
    [iID_RegimeFiduciaire] INT           IDENTITY (1, 1) NOT NULL,
    [vcDescription]        VARCHAR (100) NOT NULL,
    [vcNEQ]                VARCHAR (10)  NULL,
    [dtSignature]          DATE          NULL,
    [dtCreation]           DATETIME      CONSTRAINT [DF_RegimeFiduciaire_dtCreation] DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_IQEE_RegimeFiduciaire] PRIMARY KEY CLUSTERED ([iID_RegimeFiduciaire] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_IQEE_RegimeFiduciaire]
    ON [dbo].[tblSUBV_RegimeFiduciaire]([vcDescription] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom unique du fiduciaire', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblSUBV_RegimeFiduciaire', @level2type = N'INDEX', @level2name = N'AK_IQEE_RegimeFiduciaire';

