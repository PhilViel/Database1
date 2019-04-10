CREATE TABLE [dbo].[Un_Tutor] (
    [iTutorID] INT          NOT NULL,
    [vcEN]     VARCHAR (30) NULL,
    CONSTRAINT [PK_Un_Tutor] PRIMARY KEY CLUSTERED ([iTutorID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_Tutor_Mo_Human__iTutorID] FOREIGN KEY ([iTutorID]) REFERENCES [dbo].[Mo_Human] ([HumanID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des tuteurs', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Tutor';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Identifiant unique du tuteur', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Tutor', @level2type = N'COLUMN', @level2name = N'iTutorID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro d''entreprise si le tuteur en est une.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Tutor', @level2type = N'COLUMN', @level2name = N'vcEN';

