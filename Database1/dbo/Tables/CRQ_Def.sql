CREATE TABLE [dbo].[CRQ_Def] (
    [DocMaxSizeInMeg] INT NULL
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Contient un enregistrement contenant les configurations des modules compurangers de l''application.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_Def';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Maximum en megs des documents Word résultant des fusions.  Si on imprime plus d''un document qui utilisent le même template, ils sont mis dans le même document Word.  Le système met donc le maximum de document dans le même .doc sans dépassé le maximum.  Si le maximum est dépassé il crée plus d''un .doc pour des documents qui utilisent le même template.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_Def', @level2type = N'COLUMN', @level2name = N'DocMaxSizeInMeg';

