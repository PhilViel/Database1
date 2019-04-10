CREATE TABLE [dbo].[tblCONV_PreferenceSuivi] (
    [iID_Preference_Suivi]    INT           IDENTITY (1, 1) NOT NULL,
    [vcCode_Preference_Suivi] VARCHAR (100) NOT NULL,
    [vcDescription]           VARCHAR (50)  NOT NULL,
    CONSTRAINT [PK_CONV_PreferenceSuivi] PRIMARY KEY CLUSTERED ([iID_Preference_Suivi] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table des codes liés au mode de contact préféré du souscripteur', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_PreferenceSuivi';

