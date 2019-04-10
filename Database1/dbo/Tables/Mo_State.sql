CREATE TABLE [dbo].[Mo_State] (
    [StateID]      [dbo].[MoID]          IDENTITY (1, 1) NOT NULL,
    [CountryID]    [dbo].[MoCountry]     NOT NULL,
    [StateName]    [dbo].[MoCompanyName] NOT NULL,
    [StateCode]    [dbo].[MoDescoption]  NULL,
    [StateTaxPct]  [dbo].[MoPctPos]      NOT NULL,
    [vcNomWeb_FRA] VARCHAR (100)         NULL,
    [vcNomWeb_ENU] VARCHAR (100)         NULL,
    CONSTRAINT [PK_Mo_State] PRIMARY KEY CLUSTERED ([StateID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Mo_State_Mo_Country__CountryID] FOREIGN KEY ([CountryID]) REFERENCES [dbo].[Mo_Country] ([CountryID])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_Mo_State_CountryID_StateCode]
    ON [dbo].[Mo_State]([CountryID] ASC, [StateCode] ASC)
    INCLUDE([StateName]);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Tables des provinces/états.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_State';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la province/état.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_State', @level2type = N'COLUMN', @level2name = N'StateID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du pays (Mo_Country) dont fait parti la province ou l''état.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_State', @level2type = N'COLUMN', @level2name = N'CountryID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom de la province ou de l''état.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_State', @level2type = N'COLUMN', @level2name = N'StateName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Code de caratères de la province ou de l''état.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_State', @level2type = N'COLUMN', @level2name = N'StateCode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Pourcentage de taxe de cette province ou état.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_State', @level2type = N'COLUMN', @level2name = N'StateTaxPct';

