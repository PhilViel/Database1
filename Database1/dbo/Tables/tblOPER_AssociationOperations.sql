CREATE TABLE [dbo].[tblOPER_AssociationOperations] (
    [iID_Association]        INT IDENTITY (1, 1) NOT NULL,
    [iID_Operation_Parent]   INT NOT NULL,
    [iID_Operation_Enfant]   INT NOT NULL,
    [iID_Raison_Association] INT NOT NULL,
    CONSTRAINT [PK_OPER_AssociationOperations] PRIMARY KEY CLUSTERED ([iID_Association] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_OPER_AssociationOperations_OPER_RaisonsAssociation__iIDRaisonAssociation] FOREIGN KEY ([iID_Raison_Association]) REFERENCES [dbo].[tblOPER_RaisonsAssociation] ([iID_Raison_Association])
);


GO
CREATE NONCLUSTERED INDEX [IX_OPER_AssociationOperations_iIDOperationEnfant]
    ON [dbo].[tblOPER_AssociationOperations]([iID_Operation_Enfant] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_OPER_AssociationOperations_iIDOperationParent]
    ON [dbo].[tblOPER_AssociationOperations]([iID_Operation_Parent] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur l''opération enfant.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_AssociationOperations', @level2type = N'INDEX', @level2name = N'IX_OPER_AssociationOperations_iIDOperationEnfant';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur l''opération parent.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_AssociationOperations', @level2type = N'INDEX', @level2name = N'IX_OPER_AssociationOperations_iIDOperationParent';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Lien entre les associations d''opérations et les raisons d''association.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_AssociationOperations', @level2type = N'CONSTRAINT', @level2name = N'FK_OPER_AssociationOperations_OPER_RaisonsAssociation__iIDRaisonAssociation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur l''ID d''association.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_AssociationOperations', @level2type = N'CONSTRAINT', @level2name = N'PK_OPER_AssociationOperations';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'La table d''association d''opérations permet de créer une hiérarchie en arbre entre les opérations de façon à les faire interagir ensembles ou simplement pour les représenter comme une seule opération pour les subventions ou les rapports.  2 opérations peuvent être associées pour plus d''une raison.

CONCEPTION: Lorsque 2 opérations sont associées, c’est la raison de l’association entre elles qui détermine si elles sont « liées » ou non dans l’action.  Si 2 opérations sont liées, le fait d’en supprimer ou d’en annuler une peut supprimer ou annuler l’autre.  Un exemple de liaison pourrait être que l’opération de PAE (opération parent) engendre une opération RGC (opération enfant) pour les non résident du Canada.   Si l’opération de PAE est supprimée ou annulée, l’opération RGC n’a plus sa raison d’être et doit être également supprimée ou annulée.  Même chose à l’inverse.  Si l’opération de RGC est supprimée ou annulée, l’opération PAE doit également être supprimée ou annulée.

Cependant, il est possible « d’associer » 2 opérations sans qu’elles soient liées.  Un exemple de cela serait l’association d’un transfert OUT total d’un groupe d’unité avec le même transfert OUT total d’un second groupe d’unité de la même convention.  Le total de ces 2 opérations de transfert correspond à un seul transfert OUT total pour l’IQÉÉ.  Si l’un des 2 transferts est supprimé ou annulé, cela n’affecte pas la seconde opération de transfert.  Pour l’IQÉÉ, le transfert restant deviendra un transfert OUT partiel pour la convention.  Un autre exemple pourrait être une opération faite à postériori et qui complète une opération faite dans le passé lors de délais de développement (exemple IQÉÉ).  L’avantage est que cette opération dans le passé n’est pas modifiée et ne modifie pas les rapports comptables alors que la nouvelle opération vient compléter l’opération dans une date d’opération qui est à l’intérieur de la date de barrure des opérations.  

RÉALISATION: A ce point des développements, la gestion de la suppression et de l’annulation des opérations enfants et parents doit se faire dans les contextes où il y a liaison ou association entre des opérations.  Autrement dit, il n’y a pas de développement centralisé permettant la suppression et l’annulation en cascade des opérations liées.  Si cela devait devenir souhaitable, ça devra faire l’objet de développements supplémentaires.  En attendant ce genre de développement, il n''y a pas de contraintes entre les IDs d''opérations associées et les opérations elles mêmes afin de garder la trace des associations brisées par la suppression de transactions.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_AssociationOperations';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''une association entre 2 opérations.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_AssociationOperations', @level2type = N'COLUMN', @level2name = N'iID_Association';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de l''opération parent.  C''est l''opération principale soit la plus significative.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_AssociationOperations', @level2type = N'COLUMN', @level2name = N'iID_Operation_Parent';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant de l''opération enfant.  C''est l''opération secondaire soit la moins significative.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_AssociationOperations', @level2type = N'COLUMN', @level2name = N'iID_Operation_Enfant';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant de la raison de l''association entre 2 opérations.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_AssociationOperations', @level2type = N'COLUMN', @level2name = N'iID_Raison_Association';

