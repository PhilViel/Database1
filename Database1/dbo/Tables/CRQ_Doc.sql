CREATE TABLE [dbo].[CRQ_Doc] (
    [DocID]             INT            IDENTITY (1, 1) NOT NULL,
    [DocTemplateID]     INT            NOT NULL,
    [DocOrderConnectID] INT            NOT NULL,
    [DocOrderTime]      DATETIME       NOT NULL,
    [DocGroup1]         VARCHAR (1500) NULL,
    [DocGroup2]         VARCHAR (100)  NULL,
    [DocGroup3]         VARCHAR (100)  NULL,
    [Doc]               TEXT           NOT NULL,
    CONSTRAINT [PK_CRQ_Doc] PRIMARY KEY CLUSTERED ([DocID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_CRQ_Doc_CRQ_DocTemplate__DocTemplateID] FOREIGN KEY ([DocTemplateID]) REFERENCES [dbo].[CRQ_DocTemplate] ([DocTemplateID])
);


GO
CREATE NONCLUSTERED INDEX [IX_CRQ_Doc_DocTemplateID]
    ON [dbo].[CRQ_Doc]([DocTemplateID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_CRQ_Doc_DocOrderConnectID_DocOrderTime]
    ON [dbo].[CRQ_Doc]([DocOrderConnectID] ASC, [DocOrderTime] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Elle contient les documents.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_Doc';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du document', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_Doc', @level2type = N'COLUMN', @level2name = N'DocID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du template (CRQ_DocTemplate).  Cela nous permet de connaître quel est le template qu''utilise le docuement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_Doc', @level2type = N'COLUMN', @level2name = N'DocTemplateID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du connexion (Mo_Connect.ConnectID) de l''usager qui a commandé le document.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_Doc', @level2type = N'COLUMN', @level2name = N'DocOrderConnectID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date et heure à laquelle le document a été commandé.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_Doc', @level2type = N'COLUMN', @level2name = N'DocOrderTime';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'C''est un champs de description qui donne des informations supplémentaires à l''usager sur le document. Par exemple, on met le numéro de contrat sur un relevé afin de savoir à quel contrat appartient le relevé dans la queue d''impression.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_Doc', @level2type = N'COLUMN', @level2name = N'DocGroup1';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'C''est un champs de description qui donne des informations supplémentaires à l''usager sur le document. Par exemple, on met le numéro de contrat sur un relevé afin de savoir à quel contrat appartient le relevé dans la queue d''impression.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_Doc', @level2type = N'COLUMN', @level2name = N'DocGroup2';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'C''est un champs de description qui donne des informations supplémentaires à l''usager sur le document. Par exemple, on met le numéro de contrat sur un relevé afin de savoir à quel contrat appartient le relevé dans la queue d''impression.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_Doc', @level2type = N'COLUMN', @level2name = N'DocGroup3';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Blob contenant les données qu''il faut fusionner dans le template pour créé le document Word.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_Doc', @level2type = N'COLUMN', @level2name = N'Doc';

