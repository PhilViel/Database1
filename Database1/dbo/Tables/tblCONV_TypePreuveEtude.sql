CREATE TABLE [dbo].[tblCONV_TypePreuveEtude] (
    [tiID_TypePreuveEtude] TINYINT      NOT NULL,
    [vcDescriptionFR]      VARCHAR (75) NOT NULL,
    [vcDescriptionEN]      VARCHAR (75) NOT NULL,
    CONSTRAINT [PK_tblCONV_TypePreuveEtude] PRIMARY KEY CLUSTERED ([tiID_TypePreuveEtude] ASC)
);

