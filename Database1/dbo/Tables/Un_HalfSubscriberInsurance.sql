CREATE TABLE [dbo].[Un_HalfSubscriberInsurance] (
    [ModalID]                     [dbo].[MoID]     NOT NULL,
    [HalfSubscriberInsuranceRate] [dbo].[MoPctPos] NOT NULL,
    CONSTRAINT [PK_Un_HalfSubscriberInsurance] PRIMARY KEY CLUSTERED ([ModalID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_HalfSubscriberInsurance_Un_Modal__ModalID] FOREIGN KEY ([ModalID]) REFERENCES [dbo].[Un_Modal] ([ModalID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des taux d''assurance pour les demis unités.  La raison est que dans les vielles modalités, le taux pour une demi unités n''était pas le même que pour la première unité.  Les derrnières modalités ont eut un taux unique, cette table a donc été créé que pour géré les anciennes modalités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_HalfSubscriberInsurance';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la modalité (Un_Modal) à laquelle appartient le taux de demi.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_HalfSubscriberInsurance', @level2type = N'COLUMN', @level2name = N'ModalID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Taux de prime d''assurance par dépôt pour une demi unité.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_HalfSubscriberInsurance', @level2type = N'COLUMN', @level2name = N'HalfSubscriberInsuranceRate';

