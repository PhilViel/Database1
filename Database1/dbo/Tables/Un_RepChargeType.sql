CREATE TABLE [dbo].[Un_RepChargeType] (
    [RepChargeTypeID]      [dbo].[MoOptionCode] NOT NULL,
    [RepChargeTypeDesc]    [dbo].[MoDesc]       NOT NULL,
    [RepChargeTypeVisible] [dbo].[MoBitTrue]    NOT NULL,
    [RepChargeTypeComm]    [dbo].[MoBitTrue]    NOT NULL,
    CONSTRAINT [PK_Un_RepChargeType] PRIMARY KEY CLUSTERED ([RepChargeTypeID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des types d''ajustements et retenus des représentants.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepChargeType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Chaîne unique de 3 caractères du type d''ajustement ou de retenu (Un_RepChargeType).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepChargeType', @level2type = N'COLUMN', @level2name = N'RepChargeTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom du type d''ajustement ou de retenu.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepChargeType', @level2type = N'COLUMN', @level2name = N'RepChargeTypeDesc';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs boolean qui détermine si l''usager peut voir ce type dans la fenêtre d''édition et visualisation (0 : Non, <>0 : Oui).  On a créer ce champs pour empêcher les usagers d''Avoir accèes à modifier des types d''ajustements ou retenus gérer automatique par le système.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepChargeType', @level2type = N'COLUMN', @level2name = N'RepChargeTypeVisible';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs boolean qui détermine s''il s''agit d''un ajustement ou d''une retenu. (=0 : Retenu, <>0 : Ajustement)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepChargeType', @level2type = N'COLUMN', @level2name = N'RepChargeTypeComm';

