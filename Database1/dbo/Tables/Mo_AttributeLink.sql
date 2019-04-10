CREATE TABLE [dbo].[Mo_AttributeLink] (
    [AttributeLinkID]     [dbo].[MoID] IDENTITY (1, 1) NOT NULL,
    [AttributeID]         [dbo].[MoID] NOT NULL,
    [ConnectID]           [dbo].[MoID] NOT NULL,
    [AttributeLinkCodeID] [dbo].[MoID] NOT NULL,
    CONSTRAINT [PK_Mo_AttributeLink] PRIMARY KEY CLUSTERED ([AttributeLinkID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Mo_AttributeLink_Mo_Attribute__AttributeID] FOREIGN KEY ([AttributeID]) REFERENCES [dbo].[Mo_Attribute] ([AttributeID]),
    CONSTRAINT [FK_Mo_AttributeLink_Mo_Connect__ConnectID] FOREIGN KEY ([ConnectID]) REFERENCES [dbo].[Mo_Connect] ([ConnectID])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_Mo_AttributeLink_AttributeID_AttributeLinkCodeID]
    ON [dbo].[Mo_AttributeLink]([AttributeID] ASC, [AttributeLinkCodeID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_AttributeLink_AttributeID]
    ON [dbo].[Mo_AttributeLink]([AttributeID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_AttributeLink_AttributeLinkCodeID]
    ON [dbo].[Mo_AttributeLink]([AttributeLinkCodeID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_AttributeLink_ConnectID]
    ON [dbo].[Mo_AttributeLink]([ConnectID] ASC) WITH (FILLFACTOR = 90);


GO
GRANT SELECT
    ON OBJECT::[dbo].[Mo_AttributeLink] TO PUBLIC
    AS [dbo];


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des liens d''attributs.  Dans cette table on fait le lien entre les objets et leurs attributs.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_AttributeLink';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du lien d''attribut.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_AttributeLink', @level2type = N'COLUMN', @level2name = N'AttributeLinkID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''attribut (Mo_Attribute).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_AttributeLink', @level2type = N'COLUMN', @level2name = N'AttributeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de connexion de l''usager (Mo_Connect) qui a donné cette attribut à cette objet.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_AttributeLink', @level2type = N'COLUMN', @level2name = N'ConnectID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''objet auquel on a donné cet attrribut.  Avec la valeur du champs Mo_AttributeType.AttributeTypeClassName qui est le type d''objet, on connait exactement à quel objet (Convention, souscripteur, bénéficiaire, établissement d''enseignement, etc.) on fait référence', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_AttributeLink', @level2type = N'COLUMN', @level2name = N'AttributeLinkCodeID';

