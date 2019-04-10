CREATE TABLE [dbo].[tblCONV_EpargneEtudeEnCours] (
    [iIDEpargneEtudeEnCours]    INT         IDENTITY (1, 1) NOT NULL,
    [vcDescEpargneEtudeEnCours] VARCHAR (3) NOT NULL,
    CONSTRAINT [PK_CONV_EpargneEtudeEnCours] PRIMARY KEY CLUSTERED ([iIDEpargneEtudeEnCours] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table contenant les valeurs indiquant l`épargne-étude est en cours', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_EpargneEtudeEnCours';

