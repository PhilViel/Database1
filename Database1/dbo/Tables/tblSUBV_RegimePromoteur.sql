CREATE TABLE [dbo].[tblSUBV_RegimePromoteur] (
    [iID_RegimePromoteur] INT           IDENTITY (1, 1) NOT NULL,
    [vcDescription]       VARCHAR (100) NOT NULL,
    [dtSignature]         DATE          NULL,
    [bOffreIQEE]          BIT           NOT NULL,
    [dtCreation]          DATETIME      CONSTRAINT [DF_RegimePromoteur_dtCreation] DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_IQEE_RegimePromoteur] PRIMARY KEY CLUSTERED ([iID_RegimePromoteur] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_IQEE_RegimePromoteur]
    ON [dbo].[tblSUBV_RegimePromoteur]([vcDescription] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom unique du promoteur', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblSUBV_RegimePromoteur', @level2type = N'INDEX', @level2name = N'AK_IQEE_RegimePromoteur';

