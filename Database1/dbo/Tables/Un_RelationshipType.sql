CREATE TABLE [dbo].[Un_RelationshipType] (
    [tiRelationshipTypeID]    TINYINT      NOT NULL,
    [vcRelationshipType]      VARCHAR (25) NOT NULL,
    [tiCode_Equivalence_IQEE] TINYINT      NOT NULL,
    CONSTRAINT [PK_Un_RelationshipType] PRIMARY KEY CLUSTERED ([tiRelationshipTypeID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des liens de parenté entre les souscripteurs et les bénéficiaires', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RelationshipType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du lien de parenté entre le souscripteur et le bénéficiaire', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RelationshipType', @level2type = N'COLUMN', @level2name = N'tiRelationshipTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Lien de parenté', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RelationshipType', @level2type = N'COLUMN', @level2name = N'vcRelationshipType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code qui sert d''équivalence pour l''IQÉÉ.  Normalement, ce sont les mêmes codes que pour le PCEE.  Le PCEE utilisant l''ID de la table.  Cette équivalence ne doit pas être changé sauf si ça change dans les NID.  Il doit être saisie dans le cas d''un nouveau type de relation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RelationshipType', @level2type = N'COLUMN', @level2name = N'tiCode_Equivalence_IQEE';

