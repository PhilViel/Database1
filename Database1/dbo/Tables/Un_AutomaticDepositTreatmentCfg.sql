CREATE TABLE [dbo].[Un_AutomaticDepositTreatmentCfg] (
    [TreatmentDay]            [dbo].[UnTreatmentDay] NOT NULL,
    [DaysAfterToTreat]        INT                    NULL,
    [DaysAddForNextTreatment] INT                    NULL,
    CONSTRAINT [PK_Un_AutomaticDepositTreatmentCfg] PRIMARY KEY CLUSTERED ([TreatmentDay] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table de configuration du traitement automatique des CPA.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_AutomaticDepositTreatmentCfg';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Jour de prélèvement : 1=Dimanche, 2=Lundi, 3=Mardi, 4=Mercredi, 5=Jeudi, 6=Vendredi et 7=Samedi (Clef primaire unique).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_AutomaticDepositTreatmentCfg', @level2type = N'COLUMN', @level2name = N'TreatmentDay';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nombre de jour à additionner au jour courant pour connaître le dernier jour à traiter.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_AutomaticDepositTreatmentCfg', @level2type = N'COLUMN', @level2name = N'DaysAfterToTreat';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nombre de jour à additionner à DaysAfterToTreat pour le prochain traitement de ce TreatmentDay.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_AutomaticDepositTreatmentCfg', @level2type = N'COLUMN', @level2name = N'DaysAddForNextTreatment';

