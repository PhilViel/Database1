CREATE TABLE [dbo].[Mo_Right] (
    [RightID]      [dbo].[MoID]       IDENTITY (1, 1) NOT NULL,
    [RightTypeID]  [dbo].[MoIDoption] NULL,
    [RightCode]    [dbo].[MoDesc]     NOT NULL,
    [RightDesc]    [dbo].[MoLongDesc] NOT NULL,
    [RightVisible] [dbo].[MoBitTrue]  NOT NULL,
    [RightDate]    DATETIME           CONSTRAINT [DF_Mo_Right_RightDate] DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_Mo_Right] PRIMARY KEY CLUSTERED ([RightID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Mo_Right_Mo_RightType__RightTypeID] FOREIGN KEY ([RightTypeID]) REFERENCES [dbo].[Mo_RightType] ([RightTypeID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Tables des droits.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Right';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du droit.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Right', @level2type = N'COLUMN', @level2name = N'RightID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du type de droit (Mo_RightType).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Right', @level2type = N'COLUMN', @level2name = N'RightTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Code unique de ce droit.  Permet de retrouver le droit par requête et ne change pas selon la base de données.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Right', @level2type = N'COLUMN', @level2name = N'RightCode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom du droit.  Ce champs permet le multi-langue.  C''est-à-dire qu''on peut y inscrire le nom en plusieurs langue et que selon la langue de l''usager la bon s''affichera.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Right', @level2type = N'COLUMN', @level2name = N'RightDesc';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs boolean indiquant si le droit est visible dans l''application (=0:Non, <>0:Oui).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Right', @level2type = N'COLUMN', @level2name = N'RightVisible';

