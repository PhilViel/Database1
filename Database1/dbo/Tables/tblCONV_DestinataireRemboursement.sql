CREATE TABLE [dbo].[tblCONV_DestinataireRemboursement] (
    [iID_Destinataire_Remboursement]    INT           IDENTITY (1, 1) NOT NULL,
    [vcCode_Destinataire_Remboursement] VARCHAR (100) NOT NULL,
    [vcDescription]                     VARCHAR (150) NOT NULL,
    CONSTRAINT [PK_CONV_DestinataireRemboursement] PRIMARY KEY CLUSTERED ([iID_Destinataire_Remboursement] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table des codes de destinataire du remboursement', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_DestinataireRemboursement';

