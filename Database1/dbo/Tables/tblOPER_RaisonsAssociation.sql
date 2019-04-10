CREATE TABLE [dbo].[tblOPER_RaisonsAssociation] (
    [iID_Raison_Association]        INT           IDENTITY (1, 1) NOT NULL,
    [vcCode_Raison]                 VARCHAR (10)  NOT NULL,
    [vcDescription]                 VARCHAR (100) NOT NULL,
    [tCommentaires]                 TEXT          NULL,
    [bCascader_Suppression_Enfants] BIT           NOT NULL,
    [bCascader_Annulation_Enfants]  BIT           NOT NULL,
    [bCascader_Suppression_Parent]  BIT           NOT NULL,
    [bCascader_Annulation_Parent]   BIT           NOT NULL,
    CONSTRAINT [PK_OPER_RaisonsAssociation] PRIMARY KEY CLUSTERED ([iID_Raison_Association] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_OPER_RaisonsAssociation_vcCodeRaison]
    ON [dbo].[tblOPER_RaisonsAssociation]([vcCode_Raison] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur le code de raison.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RaisonsAssociation', @level2type = N'INDEX', @level2name = N'AK_OPER_RaisonsAssociation_vcCodeRaison';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur l''identifiant unique d''une raison d''association.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RaisonsAssociation', @level2type = N'CONSTRAINT', @level2name = N'PK_OPER_RaisonsAssociation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'La table des raisons d''association d''opérations permet de conserver l''inventaire des raisons servant à l''association de plusieurs opérations.  Toute association d''opérations doit spécifier la raison de l''association.  La raison d''association indique le comportement que devrait prendre l''application en cas de suppression ou d''annulation de l''une des opérations associées.  2 opérations peuvent être associées pour plus d''une raison.

CONCEPTION: Lorsque 2 opérations sont associées, c’est la raison de l’association entre elles qui détermine si elles sont « liées » ou non dans l’action.  Si 2 opérations sont liées, le fait d’en supprimer ou d’en annuler une peut supprimer ou annuler l’autre.  Un exemple de liaison pourrait être que l’opération de PAE (opération parent) engendre une opération RGC (opération enfant) pour les non résident du Canada.   Si l’opération de PAE est supprimée ou annulée, l’opération RGC n’a plus sa raison d’être et doit être également supprimée ou annulée.  Même chose à l’inverse.  Si l’opération de RGC est supprimée ou annulée, l’opération PAE doit également être supprimée ou annulée.

Cependant, il est possible « d’associer » 2 opérations sans qu’elles soient liées.  Un exemple de cela serait l’association d’un transfert OUT total d’un groupe d’unité avec le même transfert OUT total d’un second groupe d’unité de la même convention.  Le total de ces 2 opérations de transfert correspond à un seul transfert OUT total pour l’IQÉÉ.  Si l’un des 2 transferts est supprimé ou annulé, cela n’affecte pas la seconde opération de transfert.  Pour l’IQÉÉ, le transfert restant deviendra un transfert OUT partiel pour la convention.  Un autre exemple pourrait être une opération faite à postériori et qui complète une opération faite dans le passé lors de délais de développement (exemple IQÉÉ).  L’avantage est que cette opération dans le passé n’est pas modifiée et ne modifie pas les rapports comptables alors que la nouvelle opération vient compléter l’opération dans une date d’opération qui est à l’intérieur de la date de barrure des opérations.  

RÉALISATION: A ce point des développements, la gestion de la suppression et de l’annulation des opérations enfants et parents doit se faire dans les contextes où il y a liaison ou association entre des opérations.  Autrement dit, il n’y a pas de développement centralisé permettant la suppression et l’annulation en cascade des opérations liées.  Si cela devait devenir souhaitable, ça devra faire l’objet de développements supplémentaires.  En attendant ce genre de développement, il n''y a pas de contraintes entre les IDs d''opérations associées et les opérations elles mêmes afin de garder la trace des associations brisées par la suppression de transactions.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RaisonsAssociation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''une raison d''association.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RaisonsAssociation', @level2type = N'COLUMN', @level2name = N'iID_Raison_Association';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code unique d''une raison d''association.  Ce code peut être codé en dur dans la programmation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RaisonsAssociation', @level2type = N'COLUMN', @level2name = N'vcCode_Raison';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description de la raison d''association.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RaisonsAssociation', @level2type = N'COLUMN', @level2name = N'vcDescription';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Commentaires sur la raison de l''association.  Ce qui est écrit dans ce champ n''est pas pour les utilisateurs.  Il sert à l''analyse pour décrire l''utilisation et les impacts de l''association de cette raison.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RaisonsAssociation', @level2type = N'COLUMN', @level2name = N'tCommentaires';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur si les opérations enfant doivent être supprimées en cascade lors de la suppression de l''opération parent.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RaisonsAssociation', @level2type = N'COLUMN', @level2name = N'bCascader_Suppression_Enfants';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur si les opérations enfant doivent être annulées en cascade lors de l''annulation de l''opération parent.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RaisonsAssociation', @level2type = N'COLUMN', @level2name = N'bCascader_Annulation_Enfants';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur si l''opération parent doit être supprimée en cascade lors de la suppression d''une opération enfant.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RaisonsAssociation', @level2type = N'COLUMN', @level2name = N'bCascader_Suppression_Parent';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur si l''opération parent doit être annulée en cascade lors de l''annulation d''une opération enfant.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RaisonsAssociation', @level2type = N'COLUMN', @level2name = N'bCascader_Annulation_Parent';

