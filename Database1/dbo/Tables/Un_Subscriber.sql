CREATE TABLE [dbo].[Un_Subscriber] (
    [SubscriberID]                      [dbo].[MoID]               NOT NULL,
    [RepID]                             [dbo].[MoIDoption]         NULL,
    [StateID]                           [dbo].[MoIDoption]         NULL,
    [ScholarshipLevelID]                [dbo].[UnScholarshipLevel] NOT NULL,
    [AnnualIncome]                      [dbo].[MoMoney]            NOT NULL,
    [SemiAnnualStatement]               [dbo].[MoBitFalse]         NOT NULL,
    [BirthLangID]                       VARCHAR (3)                NULL,
    [AddressLost]                       [dbo].[MoBitFalse]         NOT NULL,
    [tiCESPState]                       TINYINT                    NOT NULL,
    [Spouse]                            VARCHAR (100)              NULL,
    [Contact1]                          VARCHAR (100)              NULL,
    [Contact2]                          VARCHAR (100)              NULL,
    [Contact1Phone]                     VARCHAR (15)               NULL,
    [Contact2Phone]                     VARCHAR (15)               NULL,
    [iID_Preference_Suivi]              INT                        CONSTRAINT [DF_Un_Subscriber_iIDPreferenceSuivi] DEFAULT ((3)) NULL,
    [bSouscripteur_Desire_Releve_Elect] BIT                        CONSTRAINT [DF_Un_Subscriber_bSouscripteurDesireReleveElect] DEFAULT ((0)) NULL,
    [bConsentement]                     BIT                        CONSTRAINT [DF_Un_Subscriber_bConsentement] DEFAULT ((0)) NULL,
    [bRapport_Annuel_Direction]         BIT                        CONSTRAINT [DF_Un_Subscriber_bRapportAnnuelDirection] DEFAULT ((0)) NOT NULL,
    [bEtats_Financiers_Annuels]         BIT                        CONSTRAINT [DF_Un_Subscriber_bEtatsFinanciersAnnuels] DEFAULT ((0)) NOT NULL,
    [bEtats_Financiers_Semestriels]     BIT                        CONSTRAINT [DF_Un_Subscriber_bEtatsFinanciersSemestriels] DEFAULT ((0)) NOT NULL,
    [iID_Identite_Souscripteur]         INT                        NULL,
    [vcIdentiteVerifieeDescription]     VARCHAR (75)               NULL,
    [bAutorisation_Resiliation]         BIT                        NULL,
    [bReleve_Papier]                    BIT                        CONSTRAINT [DF_Un_Subscriber_bRelevePapier] DEFAULT ((0)) NOT NULL,
    [vcConjoint_Employeur]              VARCHAR (100)              NULL,
    [vcConjoint_Profession]             VARCHAR (100)              NULL,
    [dConjoint_Embauche]                DATE                       NULL,
    [iID_Preference_Suivi_Siege_Social] INT                        NULL,
    [dtConsentement_Tremplin]           DATETIME                   NULL,
    [bConsentement_Tremplin]            BIT                        NULL,
    CONSTRAINT [PK_Un_Subscriber] PRIMARY KEY CLUSTERED ([SubscriberID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_Subscriber_CONV_IdentiteSouscripteur__iIDIdentiteSouscripteur] FOREIGN KEY ([iID_Identite_Souscripteur]) REFERENCES [dbo].[tblCONV_IdentiteSouscripteur] ([iID_Identite_Souscripteur]),
    CONSTRAINT [FK_Un_Subscriber_CONV_PreferenceSuivi__iIDPreferenceSuivi] FOREIGN KEY ([iID_Preference_Suivi]) REFERENCES [dbo].[tblCONV_PreferenceSuivi] ([iID_Preference_Suivi]),
    CONSTRAINT [FK_Un_Subscriber_CONV_PreferenceSuivi__iIDPreferenceSuiviSiegeSocial] FOREIGN KEY ([iID_Preference_Suivi_Siege_Social]) REFERENCES [dbo].[tblCONV_PreferenceSuivi] ([iID_Preference_Suivi]),
    CONSTRAINT [FK_Un_Subscriber_CRQ_WorldLang__BirthLangID] FOREIGN KEY ([BirthLangID]) REFERENCES [dbo].[CRQ_WorldLang] ([WorldLanguageCodeID]),
    CONSTRAINT [FK_Un_Subscriber_Mo_Human__SubscriberID] FOREIGN KEY ([SubscriberID]) REFERENCES [dbo].[Mo_Human] ([HumanID]),
    CONSTRAINT [FK_Un_Subscriber_Mo_State__StateID] FOREIGN KEY ([StateID]) REFERENCES [dbo].[Mo_State] ([StateID]),
    CONSTRAINT [FK_Un_Subscriber_Un_Rep__RepID] FOREIGN KEY ([RepID]) REFERENCES [dbo].[Un_Rep] ([RepID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Subscriber_RepID]
    ON [dbo].[Un_Subscriber]([RepID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE TRIGGER [dbo].[TUn_Subscriber] ON [dbo].[Un_Subscriber] FOR INSERT, UPDATE 
AS
BEGIN
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Start'
	-- *** AVERTISSEMENT *** Ce script doit toujours figurer en tête de trigger

	-- Si la table #DisableTrigger est présente, il se pourrait que le trigger
	-- ne soit pas à exécuter
	IF object_id('tempdb..#DisableTrigger') is not null 
		-- Le trigger doit être retrouvé dans la table pour être ignoré
		IF EXISTS (SELECT 1 FROM #DisableTrigger WHERE OBJECT_NAME(@@PROCID) like vcTriggerName)
		BEGIN
			-- Ne pas faire le trigger
			EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Trigger Ignored'
			RETURN
		END
	-- *** FIN AVERTISSEMENT *** 

	IF UPDATE(AnnualIncome) BEGIN
		UPDATE	dbo.Un_Subscriber SET
				AnnualIncome = ROUND(ISNULL(i.AnnualIncome, 0), 2)
		FROM	dbo.Un_Subscriber U, inserted i
		WHERE	U.SubscriberID = i.SubscriberID
	END
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END;


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des souscripteurs.  Contient uniquement les informations propre au souscripteur.  Le reste des informations sont dans l''humain (Mo_Human) et dans l''adresse (Mo_Adr).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Subscriber';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Subscriber', @level2type = N'COLUMN', @level2name = N'SubscriberID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du représentant (RepID) dont le souscripteur est le client.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Subscriber', @level2type = N'COLUMN', @level2name = N'RepID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la province (StateID) dont le souscripteur est résident.  On en a besoin pour connaître le pourcentage de taxe qu''il doit payer sur l''assurance.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Subscriber', @level2type = N'COLUMN', @level2name = N'StateID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Chaîne unique de 3 caractères du niveau de scolarité du souscripteur. (''UNK''=Inconnu, ''NDI''=Non diplômé, ''SEC''=Secondaire, ''COL''=Collège, ''UNI''=Université)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Subscriber', @level2type = N'COLUMN', @level2name = N'ScholarshipLevelID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Revenu annuel. Pour fin de statistique.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Subscriber', @level2type = N'COLUMN', @level2name = N'AnnualIncome';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs boolean indiquant si le souscriteur veut un relevé de dépôt semi-annuellement ou annuellement. (=0:Annuellement, <>0:Semi-annuellement)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Subscriber', @level2type = N'COLUMN', @level2name = N'SemiAnnualStatement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Chaîne unique de trois caractères de la langue maternelle (CRQ_WorldLang.WorldLanguageCodeID) du souscripteur. Pour statistique.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Subscriber', @level2type = N'COLUMN', @level2name = N'BirthLangID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs boolean indiquant si l''on a perdu l''adresse du souscripteur (=0:Non, <>0:Oui).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Subscriber', @level2type = N'COLUMN', @level2name = N'AddressLost';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'État du souscripteur au niveau des pré-validations. (0 = Rien ne passe et 1 = La SCEE passe)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Subscriber', @level2type = N'COLUMN', @level2name = N'tiCESPState';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Information du conjoint', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Subscriber', @level2type = N'COLUMN', @level2name = N'Spouse';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Information du contact #1', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Subscriber', @level2type = N'COLUMN', @level2name = N'Contact1';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Information du contact #2', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Subscriber', @level2type = N'COLUMN', @level2name = N'Contact2';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro de téléphone du contact #1', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Subscriber', @level2type = N'COLUMN', @level2name = N'Contact1Phone';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro de téléphone du contact #2', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Subscriber', @level2type = N'COLUMN', @level2name = N'Contact2Phone';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'1 si le souscripteur désire recevoir le rapport annuel de la direction, 0 sinon.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Subscriber', @level2type = N'COLUMN', @level2name = N'bRapport_Annuel_Direction';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'1 si le souscripteur désire recevoir les états financiers annuels, 0 sinon.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Subscriber', @level2type = N'COLUMN', @level2name = N'bEtats_Financiers_Annuels';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'1 si le souscripteur désire recevoir les états financiers semestriels, 0 sinon.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Subscriber', @level2type = N'COLUMN', @level2name = N'bEtats_Financiers_Semestriels';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date que le souscripteur à accepter ou refuser le consentement pour le programme Tremplin.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Subscriber', @level2type = N'COLUMN', @level2name = N'dtConsentement_Tremplin';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur pour le consentement pour le programme Tremplin. (1 = OUI, 0 = NON)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Subscriber', @level2type = N'COLUMN', @level2name = N'bConsentement_Tremplin';

