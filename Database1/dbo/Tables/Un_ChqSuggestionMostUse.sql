CREATE TABLE [dbo].[Un_ChqSuggestionMostUse] (
    [iChqSuggestionMostUseID] INT IDENTITY (1, 1) NOT NULL,
    [iHumanID]                INT NOT NULL,
    CONSTRAINT [PK_Un_ChqSuggestionMostUse] PRIMARY KEY CLUSTERED ([iChqSuggestionMostUseID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_ChqSuggestionMostUse_Mo_Human__iHumanID] FOREIGN KEY ([iHumanID]) REFERENCES [dbo].[Mo_Human] ([HumanID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des propositions de modifications de chèques prédéfinies.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ChqSuggestionMostUse';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Identifiant unique de la proposition de modification de chèque prdéfinie.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ChqSuggestionMostUse', @level2type = N'COLUMN', @level2name = N'iChqSuggestionMostUseID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de l''humain (souscripteur, bénéficiaire et destinataire) destinataire du chèque', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ChqSuggestionMostUse', @level2type = N'COLUMN', @level2name = N'iHumanID';

