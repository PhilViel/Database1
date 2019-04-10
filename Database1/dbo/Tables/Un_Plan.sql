CREATE TABLE [dbo].[Un_Plan] (
    [PlanID]                              [dbo].[MoID]              IDENTITY (1, 1) NOT NULL,
    [PlanTypeID]                          [dbo].[UnPlanType]        NOT NULL,
    [PlanDesc]                            [dbo].[MoDesc]            NOT NULL,
    [PlanScholarshipQty]                  [dbo].[MoOrder]           NOT NULL,
    [PlanOrderID]                         [dbo].[MoOrder]           NOT NULL,
    [PlanGovernmentRegNo]                 [dbo].[UnGovernmentRegNo] NOT NULL,
    [PlanMaxCotisationFirstYear]          [dbo].[MoMoney]           NOT NULL,
    [PlanMaxCotisationByYear]             [dbo].[MoMoney]           NOT NULL,
    [PlanLifeTimeCotisationByBeneficiary] [dbo].[MoMoney]           NOT NULL,
    [PlanMaxGovernmentGrant]              [dbo].[MoMoney]           NOT NULL,
    [PlanLifeTimeInYear]                  [dbo].[MoID]              NOT NULL,
    [IntReimbAge]                         [dbo].[MoOrder]           NOT NULL,
    [OrderOfPlanInReport]                 INT                       CONSTRAINT [DF_Un_Plan_OrderOfPlanInReport] DEFAULT (100) NULL,
    [bEligibleForCESG]                    BIT                       NOT NULL,
    [bEligibleForACESG]                   BIT                       NOT NULL,
    [bEligibleForCLB]                     BIT                       NOT NULL,
    [tiAgeQualif]                         INT                       CONSTRAINT [DF_Un_Plan_tiAgeQualif] DEFAULT (0) NOT NULL,
    [iID_Regroupement_Regime]             INT                       NOT NULL,
    [mRelDepProjBourse1]                  MONEY                     NULL,
    [mRelDepProjBourse2]                  MONEY                     NULL,
    [mRelDepProjBourse3]                  MONEY                     NULL,
    [EstActif]                            BIT                       CONSTRAINT [DF_Un_Plan_EstActif] DEFAULT ((1)) NOT NULL,
    [PlanDesc_ENU]                        [dbo].[MoDesc]            NULL,
    [NomPlan]                             [dbo].[MoDesc]            NULL,
    [NomPlan_ENU]                         [dbo].[MoDesc]            NULL,
    [cLettre_PrefixeConventionNo]         CHAR (1)                  NULL,
    CONSTRAINT [PK_Un_Plan] PRIMARY KEY CLUSTERED ([PlanID] ASC) WITH (FILLFACTOR = 90)
);


GO
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc.
Nom                 :	TUn_Plan_YearQualif
Description         :	Trigger mettant … jour automatiquement le champ d'ann‚e de qualification
Valeurs de retours  :	N/A
Note                :	ADX0001337	IA	2007-06-04	Bruno Lapointe		Cr‚ation
										2010-10-01	Steve Gouin			Gestion du #DisableTrigger
*********************************************************************************************************************/
CREATE TRIGGER dbo.TUn_Plan_YearQualif ON dbo.Un_Plan FOR UPDATE 
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

	DECLARE 
		@GetDate DATETIME,
		@ConnectID INT
		
	SET @GetDate = GETDATE()
	
	SELECT @ConnectID = MAX(ConnectID)
	FROM Mo_Connect C
	JOIN Mo_User U ON U.UserID = C.UserID
	WHERE U.LoginNameID = 'Compurangers'

	IF EXISTS ( -- Valide si une modification affecte une ann‚e de qualification
			SELECT I.PlanID
			FROM INSERTED I
			JOIN DELETED D ON D.PlanID = I.PlanID
			JOIN dbo.Un_Convention C ON C.PlanID = I.PlanID
			WHERE D.tiAgeQualif <> I.tiAgeQualif -- Modification de l'age du b‚n‚ficiaire … l'ann‚e qualification
			)
	BEGIN
		-- Cr‚e un table temporaire qui contiendra les ann‚es de qualifications calcul‚es
		-- des conventions dont le r‚gime(plan) a chang‚.
		DECLARE @tYearQualif_Upd TABLE (
			ConventionID INT PRIMARY KEY,
			YearQualif INT NOT NULL )
			
		-- Calul les ann‚es de qualifications des conventions affect‚es
		INSERT INTO @tYearQualif_Upd
			SELECT 
				C.ConventionID,
				YearQualif = 
					CASE 
						WHEN P.PlanTypeID = 'IND' THEN 0 -- Si individuel = 0
					ELSE YEAR(HB.BirthDate) + P.tiAgeQualif -- Si collectif Ann‚e de la date de naissance du b‚n‚ficiaire + Age de qualification du r‚gime.
					END
			FROM dbo.Un_Convention C
			JOIN INSERTED I ON C.PlanID = I.PlanID
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID 
			JOIN DELETED D ON D.PlanID = I.PlanID
			WHERE D.tiAgeQualif <> I.tiAgeQualif -- Modification de l'age du b‚n‚ficiaire … l'ann‚e qualification
				AND	CASE 
							WHEN P.PlanTypeID = 'IND' THEN 0 -- Si individuel = 0
						ELSE YEAR(HB.BirthDate) + P.tiAgeQualif -- Si collectif Ann‚e de la date de naissance du b‚n‚ficiaire + Age de qualification du r‚gime.
						END <> C.YearQualif -- L'ann‚e de qualification a chang‚e
			
		-- Inscrit l'ann‚e de qualification calcul‚e sur les conventions
		UPDATE C
		SET YearQualif = Y.YearQualif
		FROM dbo.Un_Convention C
		JOIN @tYearQualif_Upd Y ON Y.ConventionID = C.ConventionID
		
		-- Met la date de fin sur l'historique pr‚c‚dent de changement d'ann‚e de qualification
		UPDATE Un_ConventionYearQualif
		SET TerminatedDate = DATEADD(ms,-2,@GetDate)
		FROM Un_ConventionYearQualif C
		JOIN @tYearQualif_Upd Y ON Y.ConventionID = C.ConventionID
		WHERE C.TerminatedDate IS NULL

		-- InsŠre un historique d'ann‚e de qualification sur les conventions
		INSERT INTO Un_ConventionYearQualif (
				ConventionID, 
				ConnectID, 
				EffectDate, 
				YearQualif)
			SELECT
				C.ConventionID, 
				@ConnectID, 
				@GetDate, 
				Y.YearQualif
			FROM dbo.Un_Convention C
			JOIN @tYearQualif_Upd Y ON Y.ConventionID = C.ConventionID
	END
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END


GO

CREATE TRIGGER [dbo].[TUn_Plan] ON [dbo].[Un_Plan] FOR INSERT, UPDATE 
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

  UPDATE Un_Plan SET
    PlanMaxCotisationFirstYear = ROUND(ISNULL(i.PlanMaxCotisationFirstYear, 0), 2),
    PlanMaxCotisationByYear = ROUND(ISNULL(i.PlanMaxCotisationByYear, 0), 2),
    PlanMaxGovernmentGrant = ROUND(ISNULL(i.PlanMaxGovernmentGrant, 0), 2)
  FROM Un_Plan U, inserted i
  WHERE U.PlanID = i.PlanID
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END;


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des plans (Régime) de Fondation Universitas.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Plan';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du plan.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Plan', @level2type = N'COLUMN', @level2name = N'PlanID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Chaîne de 3 caractères identifiant le type du plan (''IND'' = Individuel, ''COL'' = Collectif).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Plan', @level2type = N'COLUMN', @level2name = N'PlanTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom donnée par Gestion Universitas à ce plan. (Correspond au nom de la fiducie)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Plan', @level2type = N'COLUMN', @level2name = N'PlanDesc';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nombre de bourse que génère ce plan pour une convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Plan', @level2type = N'COLUMN', @level2name = N'PlanScholarshipQty';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Inutilisé', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Plan', @level2type = N'COLUMN', @level2name = N'PlanOrderID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro enregistré du régime au gouvernement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Plan', @level2type = N'COLUMN', @level2name = N'PlanGovernmentRegNo';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Inutilisé.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Plan', @level2type = N'COLUMN', @level2name = N'PlanMaxCotisationFirstYear';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Inutilisé.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Plan', @level2type = N'COLUMN', @level2name = N'PlanMaxCotisationByYear';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Inutilisé.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Plan', @level2type = N'COLUMN', @level2name = N'PlanLifeTimeCotisationByBeneficiary';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Inutilisé.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Plan', @level2type = N'COLUMN', @level2name = N'PlanMaxGovernmentGrant';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Durée de vie d''un contract de ce régime.  La date de fin de régime d''une convention est le 31 décembre de la date de vigueur + la valeur de ce champ en année.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Plan', @level2type = N'COLUMN', @level2name = N'PlanLifeTimeInYear';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Age que doit avoir le bénéficiaire pour que la convention soit illigible au remboursement intégral.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Plan', @level2type = N'COLUMN', @level2name = N'IntReimbAge';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs entier indiquant l''ordre d''apparition des plans dans certains rapports.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Plan', @level2type = N'COLUMN', @level2name = N'OrderOfPlanInReport';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Régime admissible à la SCEE (0=non, 1=oui).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Plan', @level2type = N'COLUMN', @level2name = N'bEligibleForCESG';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Régime admissible à la SCEE+ (0=non, 1=oui).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Plan', @level2type = N'COLUMN', @level2name = N'bEligibleForACESG';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Régime admissible au BEC (0=non, 1=oui).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Plan', @level2type = N'COLUMN', @level2name = N'bEligibleForCLB';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Age de qualification', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Plan', @level2type = N'COLUMN', @level2name = N'tiAgeQualif';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant du regroupement de régimes auquel est associé le régime.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Plan', @level2type = N'COLUMN', @level2name = N'iID_Regroupement_Regime';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant utilisé pour la projection de la bourse 1 sur le relevés de dépôts.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Plan', @level2type = N'COLUMN', @level2name = N'mRelDepProjBourse1';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant utilisé pour la projection de la bourse 2 sur le relevés de dépôts.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Plan', @level2type = N'COLUMN', @level2name = N'mRelDepProjBourse2';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant utilisé pour la projection de la bourse 3 sur le relevés de dépôts.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Plan', @level2type = N'COLUMN', @level2name = N'mRelDepProjBourse3';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si le plan est disponbile ou non pour de nouvelles conventions.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Plan', @level2type = N'COLUMN', @level2name = N'EstActif';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom donnée en anglais par Gestion Universitas à ce plan. (Correspond au nom de la fiducie)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Plan', @level2type = N'COLUMN', @level2name = N'PlanDesc_ENU';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom donnée par Gestion Universitas à ce plan.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Plan', @level2type = N'COLUMN', @level2name = N'NomPlan';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom donnée en anglais par Gestion Universitas à ce plan. ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Plan', @level2type = N'COLUMN', @level2name = N'NomPlan_ENU';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Lettre utilisée comme préfixe pour les nouveaux numéros de conventions de ce plan', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Plan', @level2type = N'COLUMN', @level2name = N'cLettre_PrefixeConventionNo';

