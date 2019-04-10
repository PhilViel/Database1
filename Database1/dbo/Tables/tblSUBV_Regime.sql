CREATE TABLE [dbo].[tblSUBV_Regime] (
    [iID_Regime]           INT          IDENTITY (1, 1) NOT NULL,
    [vcNoRegime]           VARCHAR (10) NOT NULL,
    [iID_RegimePromoteur]  INT          NOT NULL,
    [iID_RegimeMandataire] INT          NULL,
    [iID_RegimeFiduciaire] INT          NULL,
    [dtCreation]           DATETIME     CONSTRAINT [DF_Regime_dtCreation] DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_IQEE_Regime] PRIMARY KEY CLUSTERED ([iID_Regime] ASC),
    CONSTRAINT [FK_IQEE_Regime_RegimeFiduciaire] FOREIGN KEY ([iID_RegimeFiduciaire]) REFERENCES [dbo].[tblSUBV_RegimeFiduciaire] ([iID_RegimeFiduciaire]),
    CONSTRAINT [FK_IQEE_Regime_RegimeMandataire] FOREIGN KEY ([iID_RegimeMandataire]) REFERENCES [dbo].[tblSUBV_RegimeMandataire] ([iID_RegimeMandataire]),
    CONSTRAINT [FK_IQEE_Regime_RegimePromoteur] FOREIGN KEY ([iID_RegimePromoteur]) REFERENCES [dbo].[tblSUBV_RegimePromoteur] ([iID_RegimePromoteur])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_IQEE_Regime]
    ON [dbo].[tblSUBV_Regime]([iID_RegimePromoteur] ASC, [vcNoRegime] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'No régime unique du promoteur', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblSUBV_Regime', @level2type = N'INDEX', @level2name = N'AK_IQEE_Regime';

