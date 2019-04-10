CREATE TABLE [dbo].[tblSUBV_RegimeMandataire] (
    [iID_RegimeMandataire] INT           IDENTITY (1, 1) NOT NULL,
    [vcDescription]        VARCHAR (100) NOT NULL,
    [vcNEQ]                VARCHAR (10)  NULL,
    [dtCreation]           DATETIME      CONSTRAINT [DF_RegimeMandataire_dtCreation] DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_IQEE_RegimeMandataire] PRIMARY KEY CLUSTERED ([iID_RegimeMandataire] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_IQEE_RegimeMandataire]
    ON [dbo].[tblSUBV_RegimeMandataire]([vcDescription] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom unique du mandataire', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblSUBV_RegimeMandataire', @level2type = N'INDEX', @level2name = N'AK_IQEE_RegimeMandataire';

