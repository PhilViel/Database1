CREATE TABLE [dbo].[Un_ChequeSuggestion] (
    [ChequeSuggestionID] [dbo].[MoID]      IDENTITY (1, 1) NOT NULL,
    [OperID]             [dbo].[MoID]      NOT NULL,
    [SuggestionAccepted] [dbo].[MoBitTrue] NOT NULL,
    [iHumanID]           INT               NOT NULL,
    CONSTRAINT [PK_Un_ChequeSuggestion] PRIMARY KEY CLUSTERED ([ChequeSuggestionID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_ChequeSuggestion_Mo_Human__iHumanID] FOREIGN KEY ([iHumanID]) REFERENCES [dbo].[Mo_Human] ([HumanID]),
    CONSTRAINT [FK_Un_ChequeSuggestion_Un_Oper__OperID] FOREIGN KEY ([OperID]) REFERENCES [dbo].[Un_Oper] ([OperID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_ChequeSuggestion_iHumanID]
    ON [dbo].[Un_ChequeSuggestion]([iHumanID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table contenant les propositions de modification du destinataire du chèque.  Lors de résiliation, transfert out ou remboursement intégral, il est possible, pour une raison quelconque, au service à la clientèle de faire une proposition de changement du destinataire du chèque qui est par défaut le souscripteur.  Lors de la commande du chèque le service de la comptabilité à le choix d''accepter ou de refuser la proposition.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ChequeSuggestion';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la proposition de modification du destinataire du chèque.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ChequeSuggestion', @level2type = N'COLUMN', @level2name = N'ChequeSuggestionID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''opération (Un_Oper) qui génèrera le chèque sur laquel on a fait la proposition de modification du destinataire du chèque.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ChequeSuggestion', @level2type = N'COLUMN', @level2name = N'OperID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs boolean indiquant si la comptabilité a accepté la proposition (= 1 pour true) ou non (= 0 pour false).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ChequeSuggestion', @level2type = N'COLUMN', @level2name = N'SuggestionAccepted';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de l''humain (souscripteur, bénéficiaire et destinataire) destinataire du chèque', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ChequeSuggestion', @level2type = N'COLUMN', @level2name = N'iHumanID';

