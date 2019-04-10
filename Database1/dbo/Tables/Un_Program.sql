CREATE TABLE [dbo].[Un_Program] (
    [ProgramID]     [dbo].[MoID]   IDENTITY (1, 1) NOT NULL,
    [ProgramDesc]   [dbo].[MoDesc] NOT NULL,
    [ProgramDescEn] [dbo].[MoDesc] NULL,
    [bActif]        BIT            CONSTRAINT [DF_Un_Program_bActif] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_Un_Program] PRIMARY KEY CLUSTERED ([ProgramID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des programmes d''études.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Program';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du programme.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Program', @level2type = N'COLUMN', @level2name = N'ProgramID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom du programme.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Program', @level2type = N'COLUMN', @level2name = N'ProgramDesc';

