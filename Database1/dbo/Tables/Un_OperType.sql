CREATE TABLE [dbo].[Un_OperType] (
    [OperTypeID]              CHAR (3)           NOT NULL,
    [OperTypeDesc]            [dbo].[MoDesc]     NOT NULL,
    [GovernmentTransTypeID]   CHAR (2)           NULL,
    [GovernmentReasonID]      VARCHAR (3)        NULL,
    [HoldGovernmentOnPending] [dbo].[MoBitFalse] NOT NULL,
    [TotalZero]               [dbo].[MoBitFalse] NOT NULL,
    [CommissionToPay]         [dbo].[MoBitTrue]  NOT NULL,
    CONSTRAINT [PK_Un_OperType] PRIMARY KEY CLUSTERED ([OperTypeID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [CK_Un_OperType_GovernmentReasonID] CHECK ([GovernmentReasonID]='11' OR [GovernmentReasonID]='E' OR [GovernmentReasonID]='D' OR [GovernmentReasonID]='C' OR [GovernmentReasonID]='B' OR [GovernmentReasonID]='A' OR [GovernmentReasonID]='9' OR [GovernmentReasonID]='8' OR [GovernmentReasonID]='7' OR [GovernmentReasonID]='6' OR [GovernmentReasonID]='5' OR [GovernmentReasonID]='4' OR [GovernmentReasonID]='3' OR [GovernmentReasonID]='2' OR [GovernmentReasonID]='1' OR [GovernmentReasonID]='0')
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table qui contient les types d''opérations.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OperType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Chaine unique de 3 caractères du type d''opération.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OperType', @level2type = N'COLUMN', @level2name = N'OperTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Type d''opération.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OperType', @level2type = N'COLUMN', @level2name = N'OperTypeDesc';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Pour les transactions affectant la SCÉÉ, ceci donne le type de Transaction 400 correspondant au type d''opération. (NULL=n''affecte pas la subvention, -1= si le montant total de l''opération en épargnes et frais > 0 alors ce sera 11(Cotisations) sinon 21(Remboursement de subvention), 11=Cotisations, 13=Paiement d''aide aux études(Bourses), 14= Remboursement intégral, 19=Transfert IN, 21=Remboursement de subvention, 22=Ajustement de la résiliation, 23=Transfert OUT)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OperType', @level2type = N'COLUMN', @level2name = N'GovernmentTransTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Pour les transactions affectant la SCÉÉ, ceci donne la raison par défaut d''un remboursement de subvention.  (1=Retrait de cotisations, 2=Paiement de revenu accumulé, 3=Résiliation du contrat, 4=Transfert inadmissible, 5=Remplacement d''un bénéficiaire inadmissible, 6=Paiement versé à un établissement d''enseignement, 7=Révocation)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OperType', @level2type = N'COLUMN', @level2name = N'GovernmentReasonID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Valeur True/False indiquant si l`opération de ce type est bloqué au gouvernement pendant le traitement', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OperType', @level2type = N'COLUMN', @level2name = N'HoldGovernmentOnPending';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs boolean indiquant si le total de l''opération doit être 0 (=0 : Non <>0 : Oui).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OperType', @level2type = N'COLUMN', @level2name = N'TotalZero';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs boolean indiquant si on doit payer des commissions sur les frais provenant de type d''opération. (=0 : Non, <>0 : Oui).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OperType', @level2type = N'COLUMN', @level2name = N'CommissionToPay';

