CREATE TABLE [dbo].[tblCONV_ImportanceEtudePostSecondaire] (
    [iIDImportanceEtude]    INT          IDENTITY (1, 1) NOT NULL,
    [iCodeImportanceEtude]  INT          NOT NULL,
    [vcDescImportanceEtude] VARCHAR (75) NOT NULL,
    CONSTRAINT [PK_CONV_ImportanceEtudePostSecondaire] PRIMARY KEY CLUSTERED ([iIDImportanceEtude] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table contenant les codes liés à l`importance des études', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ImportanceEtudePostSecondaire';

