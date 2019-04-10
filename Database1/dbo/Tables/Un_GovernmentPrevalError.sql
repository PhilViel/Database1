CREATE TABLE [dbo].[Un_GovernmentPrevalError] (
    [GovernmentPrevalError] [dbo].[MoID]        IDENTITY (1, 1) NOT NULL,
    [ConnectID]             [dbo].[MoID]        NOT NULL,
    [CodeID]                [dbo].[MoID]        NOT NULL,
    [TableName]             [dbo].[MoDesc]      NOT NULL,
    [ErrorCode]             [dbo].[UnErrorCode] NOT NULL,
    CONSTRAINT [PK_Un_GovernmentPrevalError] PRIMARY KEY CLUSTERED ([GovernmentPrevalError] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_GovernmentPrevalError_CodeID]
    ON [dbo].[Un_GovernmentPrevalError]([CodeID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table du module de subvention contenant les erreurs de prévalidations.  Lors d''insertion ou modification d''une souscripteur ou d''un bénéficiaire ou encore d''une convention, on valide les champs obligatoires de la SCÉÉ, et lève des erreurs si nécessaire.  Si une erreur est levé l''enregistrement ne part pas à la SCÉÉ avant qu''elle soit corrigée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_GovernmentPrevalError';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la transaction d''erreur de prévalidation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_GovernmentPrevalError', @level2type = N'COLUMN', @level2name = N'GovernmentPrevalError';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de connexion d''usager (Mo_Connect) de l''usager qui a causé l''erreur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_GovernmentPrevalError', @level2type = N'COLUMN', @level2name = N'ConnectID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''objet sur lequel est l''erreur.  Si le TableName = ''Un_Convention'' alors c''est le ConventionID.  Si le TableName = ''Un_Beneficiary'' alors c''est le BeneficiaryID.  Si le TableName = ''Un_Subscriber'' alors c''est le SubscriberID.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_GovernmentPrevalError', @level2type = N'COLUMN', @level2name = N'CodeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Détermine sur quoi est l''erreur (Convention ou Bénéficiaire ou Souscripteur).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_GovernmentPrevalError', @level2type = N'COLUMN', @level2name = N'TableName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Code indiquant l''erreur. (1=Le NAS du bénéficiaire doit être complété, 2=Le NAS du souscripteur doit être complété, 3=Le prénom du bénéficiaire doit être complété, 4=Le nom du bénéficiaire doit être complété, 5=Le prénom du souscripteur doit être complété, 6= Le nom du souscripteur doit être complété, 7=La date de naissance du bénéficiaire est invalide, 8=La date de naissance du souscripteur est invalide, 9=Le sexe du bénéficiaire est invalide, 10=Le sexe du souscripteur est invalide, 11=Le lien du bénéficiaire doit être de 1 à 6, 12=L''adresse du bénéficiaire doit être complétée, 13=La ville du bénéficiaire doit être complétée, 14=La province du bénéficiaire doit être complétée, 15=Le pays du bénéficiaire doit être complété, 16=Le code postal du bénéficiaire est invalide, 17=L''adresse du souscripteur doit être complétée, 18=La ville du souscripteur doit être complétée, 19=La province du souscripteur doit être complétée, 20=Le pays du souscripteur doit être complété, 21=Le code postal du souscripteur est invalide, 28=La langue du bénéficiaire est invalide, 29=La langue du souscripteur est invalide, 30=Le tuteur du bénéficiaire doit être complété, 31=La date du contrat doit être complétée, 32=Le plan du contrat doit être complété, 50=Il n''y a aucun bénéficiaire inscrit au contrat, 51=Il n''y a aucun souscripteur inscrit au contrat)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_GovernmentPrevalError', @level2type = N'COLUMN', @level2name = N'ErrorCode';

