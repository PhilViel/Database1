CREATE TABLE [dbo].[FormSexTutor] (
    [PrenomTutor] VARCHAR (35) NOT NULL,
    [bGirl]       SMALLINT     NULL
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table indiquant le sexe des prénoms de tuteur dans les formulaires', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'FormSexTutor';

