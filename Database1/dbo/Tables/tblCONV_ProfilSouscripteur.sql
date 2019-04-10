CREATE TABLE [dbo].[tblCONV_ProfilSouscripteur] (
    [iID_Profil_Souscripteur]                INT           IDENTITY (1, 1) NOT NULL,
    [iID_Souscripteur]                       INT           NOT NULL,
    [iID_Connaissance_Placements]            INT           NULL,
    [iID_Revenu_Familial]                    INT           NULL,
    [iID_Depassement_Bareme]                 BIT           NOT NULL,
    [iID_Identite_Souscripteur]              INT           NULL,
    [iID_ObjectifInvestissementLigne1]       INT           NULL,
    [iID_ObjectifInvestissementLigne2]       INT           NULL,
    [iID_ObjectifInvestissementLigne3]       INT           NULL,
    [tiNB_Personnes_A_Charge]                TINYINT       NOT NULL,
    [vcIdentiteVerifieeDescription]          VARCHAR (75)  NULL,
    [vcDepassementBaremeJustification]       VARCHAR (150) NULL,
    [iIDNiveauEtudeMere]                     INT           NULL,
    [iIDNiveauEtudePere]                     INT           NULL,
    [iIDNiveauEtudeTuteur]                   INT           NULL,
    [iIDImportanceEtude]                     INT           NULL,
    [iIDEpargneEtudeEnCours]                 INT           NULL,
    [iIDContributionFinanciereParent]        INT           NULL,
    [vcJustifObjectifsInvestissement]        VARCHAR (150) NULL,
    [iID_Estimation_Cout_Etudes]             INT           NULL,
    [iID_Estimation_Valeur_Nette_Menage]     INT           NULL,
    [iID_Tolerance_Risque]                   INT           NULL,
    [mMontantMensuelCotiseDansAutreREEE]     MONEY         NULL,
    [vcRaisonResiliationREEEPasse]           VARCHAR (150) NULL,
    [DateProfilInvestisseur]                 DATE          CONSTRAINT [DF_CONV_ProfilSouscripteur_DateProfilInvestisseur] DEFAULT (getdate()) NULL,
    [vcOcupation]                            VARCHAR (50)  NULL,
    [vcEmployeur]                            VARCHAR (50)  NULL,
    [tiNbAnneesService]                      TINYINT       NULL,
    [DateCueilletteDonnees]                  DATETIME      NULL,
    [MntMensCotAutreREEEConjoint]            MONEY         NULL,
    [MntMensCotAutreREEEColAilleurs]         MONEY         NULL,
    [MntMensCotAutreREEEColAilleursConjoint] MONEY         NULL,
    [dDateEmbauche]                          DATE          NULL,
    [LoginName]                              VARCHAR (50)  NULL,
    [bEtrangerPolitiquementVulnerable]       BIT           NULL,
    [bNationalPolitiquementVulnerable]       BIT           NULL,
    [bDirigeantOrganisationInternationale]   BIT           NULL,
    CONSTRAINT [PK_CONV_ProfilSouscripteur] PRIMARY KEY CLUSTERED ([iID_Profil_Souscripteur] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_CONV_ProfilSouscripteur_CONV_ConnaissancesPlacements__iIDConnaissancePlacements] FOREIGN KEY ([iID_Connaissance_Placements]) REFERENCES [dbo].[tblCONV_ConnaissancesPlacements] ([iID_Connaissance_Placements]),
    CONSTRAINT [FK_CONV_ProfilSouscripteur_CONV_ContributionFinanciereParent__iIDContributionFinanciereParent] FOREIGN KEY ([iIDContributionFinanciereParent]) REFERENCES [dbo].[tblCONV_ContributionFinanciereParent] ([iIDContributionFinanciereParent]),
    CONSTRAINT [FK_CONV_ProfilSouscripteur_CONV_EpargneEtudeEnCours__iIDEpargneEtudeEnCours] FOREIGN KEY ([iIDEpargneEtudeEnCours]) REFERENCES [dbo].[tblCONV_EpargneEtudeEnCours] ([iIDEpargneEtudeEnCours]),
    CONSTRAINT [FK_CONV_ProfilSouscripteur_CONV_EstimationCoutEtudes__iIDEstimationCoutEtudes] FOREIGN KEY ([iID_Estimation_Cout_Etudes]) REFERENCES [dbo].[tblCONV_EstimationCoutEtudes] ([iID_Estimation_Cout_Etudes]),
    CONSTRAINT [FK_CONV_ProfilSouscripteur_CONV_EstimationValeurNetteMenage__iIDEstimationValeurNetteMenage] FOREIGN KEY ([iID_Estimation_Valeur_Nette_Menage]) REFERENCES [dbo].[tblCONV_EstimationValeurNetteMenage] ([iID_Estimation_Valeur_Nette_Menage]),
    CONSTRAINT [FK_CONV_ProfilSouscripteur_CONV_IdentiteSouscripteur__iIDIdentiteSouscripteur] FOREIGN KEY ([iID_Identite_Souscripteur]) REFERENCES [dbo].[tblCONV_IdentiteSouscripteur] ([iID_Identite_Souscripteur]),
    CONSTRAINT [FK_CONV_ProfilSouscripteur_CONV_ImportanceEtudePostSecondaire__iIDImportanceEtude] FOREIGN KEY ([iIDImportanceEtude]) REFERENCES [dbo].[tblCONV_ImportanceEtudePostSecondaire] ([iIDImportanceEtude]),
    CONSTRAINT [FK_CONV_ProfilSouscripteur_CONV_NiveauEtudeParent__iIDNiveauEtudeMere] FOREIGN KEY ([iIDNiveauEtudeMere]) REFERENCES [dbo].[tblCONV_NiveauEtudeParent] ([iIDNiveauEtudeParent]),
    CONSTRAINT [FK_CONV_ProfilSouscripteur_CONV_NiveauEtudeParent__iIDNiveauEtudePere] FOREIGN KEY ([iIDNiveauEtudePere]) REFERENCES [dbo].[tblCONV_NiveauEtudeParent] ([iIDNiveauEtudeParent]),
    CONSTRAINT [FK_CONV_ProfilSouscripteur_CONV_NiveauEtudeParent__iIDNiveauEtudeTuteur] FOREIGN KEY ([iIDNiveauEtudeTuteur]) REFERENCES [dbo].[tblCONV_NiveauEtudeParent] ([iIDNiveauEtudeParent]),
    CONSTRAINT [FK_CONV_ProfilSouscripteur_CONV_ObjectifsInvestissement__iIDObjectifInvestissementLigne1] FOREIGN KEY ([iID_ObjectifInvestissementLigne1]) REFERENCES [dbo].[tblCONV_ObjectifsInvestissement] ([iID_Objectif_Investissement]),
    CONSTRAINT [FK_CONV_ProfilSouscripteur_CONV_ObjectifsInvestissement__iIDObjectifInvestissementLigne2] FOREIGN KEY ([iID_ObjectifInvestissementLigne2]) REFERENCES [dbo].[tblCONV_ObjectifsInvestissement] ([iID_Objectif_Investissement]),
    CONSTRAINT [FK_CONV_ProfilSouscripteur_CONV_ObjectifsInvestissement__iIDObjectifInvestissementLigne3] FOREIGN KEY ([iID_ObjectifInvestissementLigne3]) REFERENCES [dbo].[tblCONV_ObjectifsInvestissement] ([iID_Objectif_Investissement]),
    CONSTRAINT [FK_CONV_ProfilSouscripteur_CONV_RevenuFamilial__iIDRevenuFamilial] FOREIGN KEY ([iID_Revenu_Familial]) REFERENCES [dbo].[tblCONV_RevenuFamilial] ([iID_Revenu_Familial]),
    CONSTRAINT [FK_CONV_ProfilSouscripteur_Un_Subscriber__iIDSouscripteur] FOREIGN KEY ([iID_Souscripteur]) REFERENCES [dbo].[Un_Subscriber] ([SubscriberID])
);


GO
CREATE NONCLUSTERED INDEX [IX_CONV_ProfilSouscripteur_iIDSouscripteur]
    ON [dbo].[tblCONV_ProfilSouscripteur]([iID_Souscripteur] ASC)
    INCLUDE([iID_Connaissance_Placements], [iID_Depassement_Bareme], [iID_Identite_Souscripteur], [iID_ObjectifInvestissementLigne1], [iID_ObjectifInvestissementLigne2], [iID_ObjectifInvestissementLigne3], [iID_Profil_Souscripteur], [iID_Revenu_Familial], [iIDContributionFinanciereParent], [iIDEpargneEtudeEnCours], [iIDImportanceEtude], [iIDNiveauEtudeMere], [iIDNiveauEtudePere], [iIDNiveauEtudeTuteur], [tiNB_Personnes_A_Charge], [vcDepassementBaremeJustification], [vcIdentiteVerifieeDescription]);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_CONV_ProfilSouscripteur_iIDSouscripteur_DateProfilInvestisseur]
    ON [dbo].[tblCONV_ProfilSouscripteur]([iID_Souscripteur] ASC, [DateProfilInvestisseur] ASC) WITH (FILLFACTOR = 90);


GO
CREATE TRIGGER [dbo].[TR_tblCONV_ProfilSouscripteur] ON [dbo].[tblCONV_ProfilSouscripteur]
	FOR INSERT
AS BEGIN
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Start'

	-- *** AVERTISSEMENT *** Ce script doit toujours figurer en tête de trigger
	IF object_id('tempdb..#DisableTrigger') is null 
		CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))
	ELSE
	BEGIN
		-- Le trigger doit être retrouvé dans la table pour être ignoré
		IF EXISTS (SELECT 1 FROM #DisableTrigger WHERE OBJECT_NAME(@@PROCID) like vcTriggerName)
		BEGIN
			-- Ne pas faire le trigger
			EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Trigger Ignored'
			RETURN
		END
	END
	
	--	Bloque le trigger des DELETEs
	INSERT INTO #DisableTrigger VALUES('TRG_CONV_ProfilSouscripteur_U')	

	UPDATE L
	   SET LoginName = dbo.GetUserContext()
	  FROM dbo.tblCONV_ProfilSouscripteur L JOIN inserted I ON I.iID_Profil_Souscripteur = L.iID_Profil_Souscripteur
	 WHERE L.LoginName IS NULL

	IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName Like 'TRG_CONV_ProfilSouscripteur_U'
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END

GO
/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: TtblGENE_Adresse
But					: Historiser les profils investisseur dans tblCONV_ProfilSouscripteur lors d'un changement sur le record							

Historique des modifications:
		Date				Programmeur				Description										
		------------		-----------------------	-----------------------------------------	
		2015-05-28			Steve Picard			Création du service			

*********************************************************************************************************************/
CREATE TRIGGER [dbo].[TRG_CONV_ProfilSouscripteur_U] ON [dbo].[tblCONV_ProfilSouscripteur] FOR UPDATE
AS
BEGIN
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Start'
	DECLARE @Today date = GetDate()

	-- *** AVERTISSEMENT *** Ce script doit toujours figurer en tête de trigger
	IF object_id('tempdb..#DisableTrigger') is null 
		CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))
	ELSE
	BEGIN
		-- Le trigger doit être retrouvé dans la table pour être ignoré
		IF EXISTS (SELECT 1 FROM #DisableTrigger WHERE OBJECT_NAME(@@PROCID) like vcTriggerName)
		BEGIN
			-- Ne pas faire le trigger
			EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Trigger Ignored'
			RETURN
		END
	END
	
	--	Bloque le trigger
	INSERT INTO #DisableTrigger VALUES('TRG_CONV_ProfilSouscripteur_U')	

	DECLARE @tb_Profil TABLE (IdProfile int, DateProfile date)

	INSERT INTO @tb_Profil (IdProfile, DateProfile)
	SELECT	D.iID_Profil_Souscripteur, d.DateProfilInvestisseur
	FROM	inserted I INNER JOIN deleted D ON D.iID_Profil_Souscripteur = I.iID_Profil_Souscripteur
	WHERE	IsNull(D.DateProfilInvestisseur, Cast(0 as Datetime)) < @Today

	DECLARE @LoginName varchar(50) = dbo.GetUserContext()

	--	Bloque le trigger
	INSERT INTO #DisableTrigger VALUES('TR_tblCONV_ProfilSouscripteur')	

	INSERT INTO dbo.tblCONV_ProfilSouscripteur (
			DateProfilInvestisseur, iID_Souscripteur, iID_Connaissance_Placements, iID_Revenu_Familial, iID_Depassement_Bareme,
			iID_Identite_Souscripteur, iID_ObjectifInvestissementLigne1, iID_ObjectifInvestissementLigne2, iID_ObjectifInvestissementLigne3, 
			tiNB_Personnes_A_Charge, vcIdentiteVerifieeDescription, vcDepassementBaremeJustification, iIDNiveauEtudeMere, iIDNiveauEtudePere, 
			iIDNiveauEtudeTuteur, iIDImportanceEtude, iIDEpargneEtudeEnCours, iIDContributionFinanciereParent, vcJustifObjectifsInvestissement,
			iID_Estimation_Cout_Etudes, iID_Estimation_Valeur_Nette_Menage, iID_Tolerance_Risque, 
               bEtrangerPolitiquementVulnerable, bNationalPolitiquementVulnerable, bDirigeantOrganisationInternationale, 
			mMontantMensuelCotiseDansAutreREEE, vcRaisonResiliationREEEPasse, vcOcupation, vcEmployeur, tiNbAnneesService, DateCueilletteDonnees,
			MntMensCotAutreREEEConjoint, MntMensCotAutreREEEColAilleurs, MntMensCotAutreREEEColAilleursConjoint, dDateEmbauche, LoginName
		)
	SELECT	@Today, I.iID_Souscripteur, I.iID_Connaissance_Placements, I.iID_Revenu_Familial, I.iID_Depassement_Bareme, 
			I.iID_Identite_Souscripteur, I.iID_ObjectifInvestissementLigne1, I.iID_ObjectifInvestissementLigne2, I.iID_ObjectifInvestissementLigne3, 
			I.tiNB_Personnes_A_Charge, I.vcIdentiteVerifieeDescription, I.vcDepassementBaremeJustification, I.iIDNiveauEtudeMere, I.iIDNiveauEtudePere, 
			I.iIDNiveauEtudeTuteur, I.iIDImportanceEtude, I.iIDEpargneEtudeEnCours, I.iIDContributionFinanciereParent, I.vcJustifObjectifsInvestissement,
			I.iID_Estimation_Cout_Etudes, I.iID_Estimation_Valeur_Nette_Menage, I.iID_Tolerance_Risque, 
               I.bEtrangerPolitiquementVulnerable, I.bNationalPolitiquementVulnerable, I.bDirigeantOrganisationInternationale,
			I.mMontantMensuelCotiseDansAutreREEE, I.vcRaisonResiliationREEEPasse, I.vcOcupation, I.vcEmployeur, I.tiNbAnneesService, I.DateCueilletteDonnees, 
			I.MntMensCotAutreREEEConjoint, I.MntMensCotAutreREEEColAilleurs, I.MntMensCotAutreREEEColAilleursConjoint, I.dDateEmbauche, @LoginName
	FROM	inserted I INNER JOIN @tb_Profil D ON D.IdProfile = I.iID_Profil_Souscripteur

	IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName Like 'TR_tblCONV_ProfilSouscripteur'

	UPDATE	P
	   SET	iID_Souscripteur = D.iID_Souscripteur,
			iID_Connaissance_Placements = D.iID_Connaissance_Placements,
			iID_Revenu_Familial = D.iID_Revenu_Familial,
			iID_Depassement_Bareme = D.iID_Depassement_Bareme,
			iID_Identite_Souscripteur = D.iID_Identite_Souscripteur,
			iID_ObjectifInvestissementLigne1 = D.iID_ObjectifInvestissementLigne1,
			iID_ObjectifInvestissementLigne2 = D.iID_ObjectifInvestissementLigne2,
			iID_ObjectifInvestissementLigne3 = D.iID_ObjectifInvestissementLigne3,
			tiNB_Personnes_A_Charge = D.tiNB_Personnes_A_Charge,
			vcIdentiteVerifieeDescription = D.vcIdentiteVerifieeDescription,
			vcDepassementBaremeJustification = D.vcDepassementBaremeJustification,
			iIDNiveauEtudeMere = D.iIDNiveauEtudeMere,
			iIDNiveauEtudePere = D.iIDNiveauEtudePere,
			iIDNiveauEtudeTuteur = D.iIDNiveauEtudeTuteur,
			iIDImportanceEtude = D.iIDImportanceEtude,
			iIDEpargneEtudeEnCours = D.iIDEpargneEtudeEnCours,
			iIDContributionFinanciereParent = D.iIDContributionFinanciereParent,
			vcJustifObjectifsInvestissement = D.vcJustifObjectifsInvestissement,
			iID_Estimation_Cout_Etudes = D.iID_Estimation_Cout_Etudes,
			iID_Estimation_Valeur_Nette_Menage = D.iID_Estimation_Valeur_Nette_Menage,
			iID_Tolerance_Risque = D.iID_Tolerance_Risque,
			bEtrangerPolitiquementVulnerable = D.bEtrangerPolitiquementVulnerable,
               bNationalPolitiquementVulnerable = D.bNationalPolitiquementVulnerable,
               bDirigeantOrganisationInternationale = D.bDirigeantOrganisationInternationale,
			mMontantMensuelCotiseDansAutreREEE = D.mMontantMensuelCotiseDansAutreREEE,
			vcRaisonResiliationREEEPasse = D.vcRaisonResiliationREEEPasse,
			DateProfilInvestisseur = D.DateProfilInvestisseur,
			vcOcupation = D.vcOcupation,
			vcEmployeur = D.vcEmployeur,
			tiNbAnneesService = D.tiNbAnneesService,
			DateCueilletteDonnees = D.DateCueilletteDonnees,
			MntMensCotAutreREEEConjoint = D.MntMensCotAutreREEEConjoint,
			MntMensCotAutreREEEColAilleurs = D.MntMensCotAutreREEEColAilleurs,
			MntMensCotAutreREEEColAilleursConjoint = D.MntMensCotAutreREEEColAilleursConjoint,
			dDateEmbauche = D.dDateEmbauche,
			LoginName = D.LoginName
	FROM	dbo.tblCONV_ProfilSouscripteur P 
	        INNER JOIN @tb_Profil X ON X.IdProfile = P.iID_Profil_Souscripteur
	        INNER JOIN deleted D ON D.iID_Profil_Souscripteur = X.IdProfile

	IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName Like 'TRG_CONV_ProfilSouscripteur_U'
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END

GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table des profils des souscripteurs', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ProfilSouscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Justification des choix de critères d''investissement', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ProfilSouscripteur', @level2type = N'COLUMN', @level2name = N'vcJustifObjectifsInvestissement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date et heure à laquelle les données ont été demandées au souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ProfilSouscripteur', @level2type = N'COLUMN', @level2name = N'DateCueilletteDonnees';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Profil investisseur v3 - Étranger politiquement vulnérable? - oui/non', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ProfilSouscripteur', @level2type = N'COLUMN', @level2name = N'bEtrangerPolitiquementVulnerable';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Profil investisseur v3 - National politiquement vulnérable? - oui/non', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ProfilSouscripteur', @level2type = N'COLUMN', @level2name = N'bNationalPolitiquementVulnerable';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Profil investisseur v3 - Dirigeant d''une organisation internationale? - oui/non', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ProfilSouscripteur', @level2type = N'COLUMN', @level2name = N'bDirigeantOrganisationInternationale';

