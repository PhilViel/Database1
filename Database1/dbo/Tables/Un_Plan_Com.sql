CREATE TABLE [dbo].[Un_Plan_Com] (
    [iPlan_Com_ID]    INT           IDENTITY (1, 1) NOT NULL,
    [vcPlan_Com_Desc] VARCHAR (250) NULL,
    CONSTRAINT [PK_Un_Plan_Com] PRIMARY KEY CLUSTERED ([iPlan_Com_ID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table contenant la liste des plans avec leur description', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Plan_Com';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant du plan de commission', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Plan_Com', @level2type = N'COLUMN', @level2name = N'iPlan_Com_ID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description du plan de commission', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Plan_Com', @level2type = N'COLUMN', @level2name = N'vcPlan_Com_Desc';

