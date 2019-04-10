CREATE TABLE [dbo].[tblTEMP_KofaxConv] (
    [ConventionNo]  VARCHAR (15)  NULL,
    [SubscriberID]  INT           NULL,
    [BeneficiaryID] INT           NULL,
    [vcDossier]     VARCHAR (100) NULL,
    [SLastName]     VARCHAR (50)  NULL,
    [SFirstname]    VARCHAR (35)  NULL,
    [UnitQty]       MONEY         NULL
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table temporaire utilisée pour transférer la liste des dossiers du P: à Kofax (psGENE_MiseAJourKofaxSFTP)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblTEMP_KofaxConv';

