CREATE TABLE [dbo].[tblGENE_Messages] (
    [vcCode]      VARCHAR (50) NOT NULL,
    [cType]       CHAR (1)     NULL,
    [iIdMessages] INT          IDENTITY (1, 1) NOT NULL,
    [Regle]       INT          NULL,
    [Severite]    INT          NULL,
    CONSTRAINT [PK_GENE_Messages] PRIMARY KEY CLUSTERED ([iIdMessages] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_GENE_Messages_vcCode]
    ON [dbo].[tblGENE_Messages]([vcCode] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Type de message (E = Erreur, A-W = Avertissement, M = Message) (Non utilisé par Proacces)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Messages', @level2type = N'COLUMN', @level2name = N'cType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Type de règle pour laquelle le message est utilisé (Intégrité, Affaire, Fonctionnel, Système)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Messages', @level2type = N'COLUMN', @level2name = N'Regle';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Sévérité du message (Erreur, Avertissement, Information, Succès)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Messages', @level2type = N'COLUMN', @level2name = N'Severite';

