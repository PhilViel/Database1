CREATE TABLE [dbo].[Un_SubscriberAgeLimitCfg] (
    [SubscriberAgeLimitCfgID] INT               IDENTITY (1, 1) NOT NULL,
    [Effectdate]              [dbo].[MoGetDate] NOT NULL,
    [MaxAgeForSubscInsur]     [dbo].[MoID]      NOT NULL,
    [MinSubscriberAge]        [dbo].[MoID]      NOT NULL,
    CONSTRAINT [PK_Un_SubscriberAgeLimitCfg] PRIMARY KEY CLUSTERED ([SubscriberAgeLimitCfgID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table de configuration des limites d''age des souscripteurs.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_SubscriberAgeLimitCfg';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la configuration.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_SubscriberAgeLimitCfg', @level2type = N'COLUMN', @level2name = N'SubscriberAgeLimitCfgID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d''entrée en vigueur de la configuration.  Ces limites sont gérées lors d''ajout ou de modification de groupe d''unités.  Pour connaître la configuration qui s''applique, on doit prendre l''enregistrement dont cette date est la plus élevé dans ceux dont cette date est plus petite ou égale à la date de vigueur (Un_Unit.InForceDate) du groupe d''unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_SubscriberAgeLimitCfg', @level2type = N'COLUMN', @level2name = N'Effectdate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Age maximum que peut avoir le souscripteur à la date de vigueur du groupe d''unités pour être illigible à l''assurance souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_SubscriberAgeLimitCfg', @level2type = N'COLUMN', @level2name = N'MaxAgeForSubscInsur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Age minimum que doit avoir le souscripteur à la date de vigueur du groupe d''unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_SubscriberAgeLimitCfg', @level2type = N'COLUMN', @level2name = N'MinSubscriberAge';

