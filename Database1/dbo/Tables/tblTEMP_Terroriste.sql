CREATE TABLE [dbo].[tblTEMP_Terroriste] (
    [F1]           VARCHAR (255)  NULL,
    [NOM]          VARCHAR (255)  NULL,
    [Prenom1]      VARCHAR (255)  NULL,
    [Prenom2]      VARCHAR (255)  NULL,
    [Prenom3]      VARCHAR (255)  NULL,
    [Prenom4]      VARCHAR (255)  NULL,
    [LDN]          VARCHAR (255)  NULL,
    [AltLDN]       VARCHAR (255)  NULL,
    [DDN]          VARCHAR (255)  NULL,
    [DDN2]         VARCHAR (255)  NULL,
    [DDN3]         VARCHAR (255)  NULL,
    [DDN4]         VARCHAR (255)  NULL,
    [Nationalite1] VARCHAR (255)  NULL,
    [Nationalite2] VARCHAR (255)  NULL,
    [Nationalite3] VARCHAR (255)  NULL,
    [Titre]        VARCHAR (2000) NULL,
    [F17]          VARCHAR (255)  NULL
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table temporaire utilisée pour la vérification des terroristes (psGENE_RapportVerifTerroriste)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblTEMP_Terroriste';

