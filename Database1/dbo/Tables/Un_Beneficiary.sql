CREATE TABLE [dbo].[Un_Beneficiary] (
    [BeneficiaryID]                   [dbo].[MoID]         NOT NULL,
    [CollegeID]                       [dbo].[MoIDoption]   NULL,
    [ProgramID]                       [dbo].[MoIDoption]   NULL,
    [TutorName]                       [dbo].[MoDescoption] NULL,
    [GovernmentGrantForm]             [dbo].[MoBitFalse]   NOT NULL,
    [PersonalInfo]                    [dbo].[MoBitFalse]   NOT NULL,
    [BirthCertificate]                [dbo].[MoBitFalse]   NOT NULL,
    [StudyStart]                      [dbo].[MoDateoption] NULL,
    [ProgramLength]                   [dbo].[MoID]         NOT NULL,
    [ProgramYear]                     [dbo].[MoID]         NOT NULL,
    [RegistrationProof]               [dbo].[MoBitFalse]   NOT NULL,
    [SchoolReport]                    [dbo].[MoBitFalse]   NOT NULL,
    [EligibilityQty]                  [dbo].[MoOrder]      NOT NULL,
    [CaseOfJanuary]                   [dbo].[MoBitFalse]   NOT NULL,
    [iTutorID]                        INT                  NULL,
    [bTutorIsSubscriber]              BIT                  CONSTRAINT [DF_Un_Beneficiary_bTutorIsSubscriber] DEFAULT (1) NULL,
    [bAddressLost]                    BIT                  CONSTRAINT [DF_Un_Beneficiary_bAddressLost] DEFAULT (0) NOT NULL,
    [vcPCGSINorEN]                    VARCHAR (15)         CONSTRAINT [DF_Un_Beneficiary_vcPCGSINorEN] DEFAULT ('') NULL,
    [vcPCGFirstName]                  VARCHAR (40)         CONSTRAINT [DF_Un_Beneficiary_vcPCGFirstName] DEFAULT ('') NULL,
    [vcPCGLastName]                   VARCHAR (50)         CONSTRAINT [DF_Un_Beneficiary_vcPCGLastName] DEFAULT ('') NULL,
    [tiPCGType]                       [dbo].[UnPCGType]    NULL,
    [bPCGIsSubscriber]                BIT                  NULL,
    [tiCESPState]                     TINYINT              NOT NULL,
    [EligibilityConditionID]          CHAR (3)             NULL,
    [bConsentement]                   BIT                  CONSTRAINT [DF_Un_Beneficiary_bConsentement] DEFAULT ((0)) NULL,
    [bReleve_Papier]                  BIT                  CONSTRAINT [DF_Un_Beneficiary_bRelevePapier] DEFAULT ((0)) NOT NULL,
    [ResponsableNEQ]                  VARCHAR (10)         NULL,
    [ResponsableIDSouscripteur]       INT                  NULL,
    [mMaximisation_Limite]            MONEY                CONSTRAINT [DF_Un_Beneficiary_mMaximisation_Limite] DEFAULT ((0)) NULL,
    [mMaximisation_MontantDisponible] MONEY                CONSTRAINT [DF_Un_Beneficiary_mMaximisation_MontantDisponible] DEFAULT ((0)) NULL,
    [bDevancement_AdmissibilitePAE]   BIT                  CONSTRAINT [DF_Un_Beneficiary_bDevancement_AdmissibilitePAE] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Un_Beneficiary] PRIMARY KEY CLUSTERED ([BeneficiaryID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_Beneficiary_Mo_Human__BeneficiaryID] FOREIGN KEY ([BeneficiaryID]) REFERENCES [dbo].[Mo_Human] ([HumanID]),
    CONSTRAINT [FK_Un_Beneficiary_Mo_Human__iTutorID] FOREIGN KEY ([iTutorID]) REFERENCES [dbo].[Mo_Human] ([HumanID]),
    CONSTRAINT [FK_Un_Beneficiary_Un_College__CollegeID] FOREIGN KEY ([CollegeID]) REFERENCES [dbo].[Un_College] ([CollegeID]),
    CONSTRAINT [FK_Un_Beneficiary_Un_Program__ProgramID] FOREIGN KEY ([ProgramID]) REFERENCES [dbo].[Un_Program] ([ProgramID])
);


GO
CREATE TRIGGER [dbo].[TUn_Beneficiary] ON [dbo].[Un_Beneficiary] FOR INSERT, UPDATE 
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

	IF UPDATE(StudyStart) OR UPDATE(vcPCGSINorEN) BEGIN
		UPDATE	dbo.Un_Beneficiary SET
				StudyStart = dbo.fn_Mo_DateNoTime(i.StudyStart),
				vcPCGSINorEN = replace(i.vcPCGSINorEN, ' ','')
		FROM	dbo.Un_Beneficiary U, inserted i
		WHERE	U.BeneficiaryID = i.BeneficiaryID
	END

	-- En attendant que la Prop. Élect. fixe la valeur passée dans «tiPCGType» pour NULL au lieu d'une chaîne vide
	IF  UPDATE(vcPCGFirstName) OR UPDATE(vcPCGLastName) OR UPDATE(vcPCGSINorEN) OR UPDATE(tiPCGType)
		UPDATE	dbo.Un_Beneficiary SET
				tiPCGType = CASE WHEN (ISNULL(i.vcPCGFirstName, '') + ISNULL(i.vcPCGLastName, '') + ISNULL(i.vcPCGSINorEN, '') = '') THEN NULL ELSE i.tiPCGType END,
                bPCGIsSubscriber = CASE WHEN (ISNULL(i.vcPCGFirstName, '') + ISNULL(i.vcPCGLastName, '') + ISNULL(i.vcPCGSINorEN, '') = '') THEN NULL ELSE ISNULL(i.bPCGIsSubscriber, 0) END     
		FROM	dbo.Un_Beneficiary U, inserted i
		WHERE	U.BeneficiaryID = i.BeneficiaryID
	

	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END

GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Cette table contient les données spécifiques au bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Beneficiary';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du bénéficiaire. Il correspond en fait à un HumanID qui est le ID unique de l''humain.  Il fait le lien avec la table Mo_Human qui contient les données génériques au humain.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Beneficiary', @level2type = N'COLUMN', @level2name = N'BeneficiaryID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''établissement d''enseignement (Un_College) ou le bénéficiaire fait ses études actuellement.  En fait c''est le dernier dont il a informé Gestion Universitas.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Beneficiary', @level2type = N'COLUMN', @level2name = N'CollegeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du programme d''enseignement (Un_Program) auquel est inscrit le bénéficiaire actuellement.  En fait c''est le dernier dont il a informé Gestion Universitas.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Beneficiary', @level2type = N'COLUMN', @level2name = N'ProgramID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom du tuteur légal du bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Beneficiary', @level2type = N'COLUMN', @level2name = N'TutorName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs boolean nous informant si Gestion Universitas a le formulaire de la SCÉÉ de ce bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Beneficiary', @level2type = N'COLUMN', @level2name = N'GovernmentGrantForm';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs boolean nous informant si Gestion Universitas a le formulaire d''informations personnelles de ce bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Beneficiary', @level2type = N'COLUMN', @level2name = N'PersonalInfo';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs boolean nous informant si Gestion Universitas a le certificat de naissance de ce bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Beneficiary', @level2type = N'COLUMN', @level2name = N'BirthCertificate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de début des études.  Si il ne sont pas commencé il sera NULL.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Beneficiary', @level2type = N'COLUMN', @level2name = N'StudyStart';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Durée du programme d''étude.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Beneficiary', @level2type = N'COLUMN', @level2name = N'ProgramLength';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Année du programme d''étude.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Beneficiary', @level2type = N'COLUMN', @level2name = N'ProgramYear';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs boolean nous informant si Gestion Universitas a reçu la preuve d''inscription au programme d''études.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Beneficiary', @level2type = N'COLUMN', @level2name = N'RegistrationProof';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs boolean nous informant si Gestion Universitas a reçu le relevé de notes du bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Beneficiary', @level2type = N'COLUMN', @level2name = N'SchoolReport';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nombre de crédits auxquelles le bénéficiaire est illigible.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Beneficiary', @level2type = N'COLUMN', @level2name = N'EligibilityQty';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs boolean nous informant si ce bénéficiaire est un cas de janvier.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Beneficiary', @level2type = N'COLUMN', @level2name = N'CaseOfJanuary';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Identifiant unique du tuteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Beneficiary', @level2type = N'COLUMN', @level2name = N'iTutorID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Indique si le tuteur (iTutorID) est un souscripteur (Un_Subscriber) ou seulement un tuteur (Un_Tutor).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Beneficiary', @level2type = N'COLUMN', @level2name = N'bTutorIsSubscriber';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs boolean indiquant si l''on a perdu l''adresse du bénéficiaire (=0:Non, <>0:Oui).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Beneficiary', @level2type = N'COLUMN', @level2name = N'bAddressLost';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'NAS ou NE du principal responsable.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Beneficiary', @level2type = N'COLUMN', @level2name = N'vcPCGSINorEN';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Prénom du principal responsable.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Beneficiary', @level2type = N'COLUMN', @level2name = N'vcPCGFirstName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom du principal responsable.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Beneficiary', @level2type = N'COLUMN', @level2name = N'vcPCGLastName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Type de principal responsable (1 = Personne avec un NAS, 2 = Compagnie avec un NE)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Beneficiary', @level2type = N'COLUMN', @level2name = N'tiPCGType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Indique si le principale responsable est un souscripteur ou non.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Beneficiary', @level2type = N'COLUMN', @level2name = N'bPCGIsSubscriber';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'État du bénéficiaire au niveau des pré-validations. (0 = Rien ne passe , 1 = Seul la SCEE passe, 2 = SCEE et BEC passe, 3 = SCEE et SCEE+ passe et 4 = SCEE, BEC et SCEE+ passe)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Beneficiary', @level2type = N'COLUMN', @level2name = N'tiCESPState';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Type d''unité utilisé pour indiquer les conditions de réussite (UNK, YEA, CRS, CDT, SES, 3MT, HRS)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Beneficiary', @level2type = N'COLUMN', @level2name = N'EligibilityConditionID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro d''entreprise du principal responsable au Québec', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Beneficiary', @level2type = N'COLUMN', @level2name = N'ResponsableNEQ';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant du souscripteur correspondant au responsable si les infos proviennent d''un souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Beneficiary', @level2type = N'COLUMN', @level2name = N'ResponsableIDSouscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant limite subventionnable pour la maximisation du bénéficiaire. (Modifié uniquement par un traitement).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Beneficiary', @level2type = N'COLUMN', @level2name = N'mMaximisation_Limite';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant disponible pour la maximisation du bénéficiaire (Limite - (Montant déposé + Montant futur). (Modifié uniquement par un traitement).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Beneficiary', @level2type = N'COLUMN', @level2name = N'mMaximisation_MontantDisponible';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si le bénéficiaire est admissible au PAE même si son année de qualification n''est pas arrivée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Beneficiary', @level2type = N'COLUMN', @level2name = N'bDevancement_AdmissibilitePAE';

