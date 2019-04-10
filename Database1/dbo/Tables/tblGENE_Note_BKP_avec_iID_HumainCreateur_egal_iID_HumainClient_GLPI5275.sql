CREATE TABLE [dbo].[tblGENE_Note_BKP_avec_iID_HumainCreateur_egal_iID_HumainClient_GLPI5275] (
    [iID_Note]            INT           IDENTITY (1, 1) NOT NULL,
    [tTexte]              TEXT          NULL,
    [vcTitre]             VARCHAR (250) NOT NULL,
    [dtDateCreation]      DATETIME      NOT NULL,
    [iID_TypeNote]        INT           NOT NULL,
    [iID_HumainClient]    INT           NOT NULL,
    [iID_HumainCreateur]  INT           NOT NULL,
    [vcTexteLienObjetLie] VARCHAR (250) NULL,
    [iId_Objetlie]        INT           NULL,
    [iId_TypeObjet]       INT           NULL,
    [iID_HumainModifiant] INT           NULL,
    [dtDateModification]  DATETIME      NULL
);

