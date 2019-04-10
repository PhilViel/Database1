CREATE TABLE [dbo].[tblCONV_IdentiteSouscripteur] (
    [iID_Identite_Souscripteur]    INT           IDENTITY (1, 1) NOT NULL,
    [vcCode_Identite_Souscripteur] VARCHAR (100) NOT NULL,
    [vcDescription]                VARCHAR (150) NOT NULL,
    CONSTRAINT [PK_CONV_IdentiteSouscripteur] PRIMARY KEY CLUSTERED ([iID_Identite_Souscripteur] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table contenant les codes des pièces d`identité du souscripteur', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_IdentiteSouscripteur';

