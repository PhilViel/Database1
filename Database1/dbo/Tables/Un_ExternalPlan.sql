CREATE TABLE [dbo].[Un_ExternalPlan] (
    [ExternalPlanID]              [dbo].[MoID]              IDENTITY (1, 1) NOT NULL,
    [ExternalPromoID]             [dbo].[MoID]              NOT NULL,
    [ExternalPlanTypeID]          [dbo].[UnPlanType]        NOT NULL,
    [ExternalPlanGovernmentRegNo] [dbo].[UnGovernmentRegNo] NOT NULL,
    CONSTRAINT [PK_Un_ExternalPlan] PRIMARY KEY CLUSTERED ([ExternalPlanID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_ExternalPlan_Un_ExternalPromo__ExternalPromoID] FOREIGN KEY ([ExternalPromoID]) REFERENCES [dbo].[Un_ExternalPromo] ([ExternalPromoID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table contenant les plans externes.  Plan appartenant à des promoteurs externes.  Cette table est utilisé par les transferts IN/OUT.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ExternalPlan';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du plan externe.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ExternalPlan', @level2type = N'COLUMN', @level2name = N'ExternalPlanID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du promoteur externe (Un_ExternalPromo) auquel appartient le plan.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ExternalPlan', @level2type = N'COLUMN', @level2name = N'ExternalPromoID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Chaîne de caractères de trois lettres qui dit qu''elle type de plan il s''agit.  COL = Collectif, IND = Individuel', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ExternalPlan', @level2type = N'COLUMN', @level2name = N'ExternalPlanTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro d''enregistrement gouvernemental du plan.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ExternalPlan', @level2type = N'COLUMN', @level2name = N'ExternalPlanGovernmentRegNo';

