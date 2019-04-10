CREATE TABLE [dbo].[Un_Def] (
    [MaxLifeCotisation]               [dbo].[MoMoney]          NOT NULL,
    [MaxYearCotisation]               [dbo].[MoMoney]          NOT NULL,
    [ScholarshipMode]                 [dbo].[MoOptionCode]     NOT NULL,
    [ScholarshipYear]                 [dbo].[MoID]             NOT NULL,
    [GovernmentBN]                    [dbo].[MoDesc]           NOT NULL,
    [LastVerifDate]                   [dbo].[MoDate]           NULL,
    [MaxRepRisk]                      [dbo].[MoPctPos]         NULL,
    [LastDepositMaxInInterest]        [dbo].[MoMoney]          NULL,
    [YearQtyOfMaxYearCotisation]      [dbo].[MoID]             NOT NULL,
    [MaxPostInForceDate]              [dbo].[MoID]             NULL,
    [MaxSubscribeAmountAjustmentDiff] [dbo].[MoMoney]          NOT NULL,
    [RepProjectionTreatmentDate]      [dbo].[MoDateoption]     NULL,
    [ProjectionCount]                 [dbo].[MoID]             NULL,
    [ProjectionType]                  [dbo].[UnProjectionType] NULL,
    [ProjectionOnNextRepTreatment]    [dbo].[MoBitFalse]       NULL,
    [MaxLifeGovernmentGrant]          [dbo].[MoMoneyoption]    NULL,
    [MaxYearGovernmentGrant]          [dbo].[MoMoneyoption]    NULL,
    [MaxFaceAmount]                   [dbo].[MoMoneyoption]    NULL,
    [StartDateForIntAfterEstimatedRI] [dbo].[MoDateoption]     NULL,
    [MonthNoIntAfterEstimatedRI]      [dbo].[MoID]             NULL,
    [CESGWaitingDays]                 [dbo].[MoID]             NULL,
    [MonthBeforeNoNASNotice]          INT                      NOT NULL,
    [BusinessBonusLimit]              INT                      NULL,
    [dtRINToolLastTreatedDate]        DATETIME                 NULL,
    [dtRINToolLastImportedDate]       DATETIME                 NULL,
    [tiCheckNbMonthBefore]            TINYINT                  CONSTRAINT [DF_Un_Def_tiCheckNbMonthBefore] DEFAULT (5) NOT NULL,
    [tiCheckNbDayBefore]              TINYINT                  CONSTRAINT [DF_Un_Def_tiCheckNbDayBefore] DEFAULT (0) NOT NULL,
    [siTraceSearch]                   SMALLINT                 NOT NULL,
    [siTraceReport]                   SMALLINT                 NOT NULL,
    [iID_Rep_Siege_Social]            INT                      NULL,
    [iID_Utilisateur_Systeme]         INT                      NULL,
    [vcNEQ_GUI]                       VARCHAR (10)             NULL,
    [iNb_Mois_Avant_RIN_Apres_RIO]    INT                      CONSTRAINT [DF_Un_Def_iNbMoisAvantRINApresRIO] DEFAULT ((12)) NOT NULL,
    [vcURLSGRCTableauBord]            VARCHAR (MAX)            NULL,
    [vcURLSGRCCreationTache]          VARCHAR (MAX)            NULL,
    [vcURLNoteConsulter]              VARCHAR (MAX)            NULL,
    [vcURLNoteAjouter]                VARCHAR (MAX)            NULL,
    [vcURLUniaccesBEC]                VARCHAR (MAX)            NULL,
    [vcURLUniaccesChBeneficiaire]     VARCHAR (MAX)            NULL
);


GO

CREATE TRIGGER [dbo].[TUn_Def] ON [dbo].[Un_Def] FOR INSERT, UPDATE
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

  UPDATE Un_Def SET
    MaxLifeCotisation = ROUND(ISNULL(i.MaxLifeCotisation, 0), 2),
    MaxYearCotisation = ROUND(ISNULL(i.MaxYearCotisation, 0), 2)
  FROM Un_Def U, inserted i
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END;


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des options de l''application qui sont propre à Universitas.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Def';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Maximum de cotisation à vie pour un bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Def', @level2type = N'COLUMN', @level2name = N'MaxLifeCotisation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Maximum de cotisation par année pour un bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Def', @level2type = N'COLUMN', @level2name = N'MaxYearCotisation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Mode de traitement du module des bourses. (PMT = mode paiement, QUA = Qualification)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Def', @level2type = N'COLUMN', @level2name = N'ScholarshipMode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Année présentement en traitement dans le module des bourses.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Def', @level2type = N'COLUMN', @level2name = N'ScholarshipYear';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro d''enregistrement du promoteur Fondation Universitas à la SCÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Def', @level2type = N'COLUMN', @level2name = N'GovernmentBN';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'On ne peut pas ajouter, modifier ou supprimer d''opérations dont la date d''opération est plus petite ou égale à cette date.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Def', @level2type = N'COLUMN', @level2name = N'LastVerifDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Maximum de pourcentage de risque des représentants.  Si le pourcentage de commission est au dessus de cette limite non-seulement les avances mais aussi les commissions de service servent à rembourser les avances sur résiliations et les avances spéciales.  Le pourcentage de commissions c''est la somme des avances non-couvertes / commissions de service.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Def', @level2type = N'COLUMN', @level2name = N'MaxRepRisk';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = '??? - Maximum d''intérêts clients pour le dernier dépôt.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Def', @level2type = N'COLUMN', @level2name = N'LastDepositMaxInInterest';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Maximum d''année après la date de vigueur pour cotiser un groupe d''unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Def', @level2type = N'COLUMN', @level2name = N'YearQtyOfMaxYearCotisation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Maximum de mois dont la date de vigueur peut précéder la date de signature dans un groupe d''unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Def', @level2type = N'COLUMN', @level2name = N'MaxPostInForceDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'La valeur absolue d''un ajustement du montant souscrit d''un groupe d''unités (Un_Unit.SubscribeAmountAjustment) ne doit pas dépasser ce maximum.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Def', @level2type = N'COLUMN', @level2name = N'MaxSubscribeAmountAjustmentDiff';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date à laquelle à eu lieu la dernière projection de commissions.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Def', @level2type = N'COLUMN', @level2name = N'RepProjectionTreatmentDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs de configuration de la prochaine projection.  C''est le nombres traitement à projeter de projections.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Def', @level2type = N'COLUMN', @level2name = N'ProjectionCount';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs de configuration de la prochaine projection.  C''est le type de projections. (1 = annuel, 2 semi-annuel, 4 = trimestriel, 12 = mensuel)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Def', @level2type = N'COLUMN', @level2name = N'ProjectionType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs boolean identifiant si une projection a été commandé pour le prochain traitement de commissions.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Def', @level2type = N'COLUMN', @level2name = N'ProjectionOnNextRepTreatment';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Maximum de subventions que peut obtenir un bénéficiaire à vie.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Def', @level2type = N'COLUMN', @level2name = N'MaxLifeGovernmentGrant';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Maximum de subventions que peut obtenir un bénéficiaire par année.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Def', @level2type = N'COLUMN', @level2name = N'MaxYearGovernmentGrant';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Maximum d''épargnes et de frais non couvert assurable par l''assurance souscripteur.  La somme de tout les montants souscrits - les montants d''épargnes et de frais réels des conventions d''un souscripteur ne doit pas dépasser ce maximum.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Def', @level2type = N'COLUMN', @level2name = N'MaxFaceAmount';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date à partir de laquelle on génère de l''intérêt sur capital pour les conventions collectives après la date estimée de remboursement intégral.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Def', @level2type = N'COLUMN', @level2name = N'StartDateForIntAfterEstimatedRI';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Délai en mois avant de génèrer de l''intérêt sur capital pour les conventions collectives après la date estimée de remboursement intégral.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Def', @level2type = N'COLUMN', @level2name = N'MonthNoIntAfterEstimatedRI';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Délai administratif en jour pour l''envoi des remboursements de subventions sur les retraits, les résiliations et les effets retournées.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Def', @level2type = N'COLUMN', @level2name = N'CESGWaitingDays';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Après ce nombre de mois à partir de la date de vigueur le système envoi automatiquement un avis de NAS manquant si soit le NAS du souscripteur ou encore le NAS du bénéficiaire est encore manquant.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Def', @level2type = N'COLUMN', @level2name = N'MonthBeforeNoNASNotice';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'C''est le champs contentant la limite pour l''attribution de bonis d''affaires.  X années aprés la date d''entrée en vigueur des groupes d''unités, si la totalité des bonis n''a pas été versée, on élimine le reste des bonis à venir.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Def', @level2type = N'COLUMN', @level2name = N'BusinessBonusLimit';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Dernière date de RI traité dans l’outil de gestion des remboursements intégraux (RIN). (Dernière période fermée)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Def', @level2type = N'COLUMN', @level2name = N'dtRINToolLastTreatedDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Dernière date de RI importé dans l’outil de gestion des remboursements intégraux (RIN). (Dernière période fermée)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Def', @level2type = N'COLUMN', @level2name = N'dtRINToolLastImportedDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nombre de mois maximum pour les chèques pré datés', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Def', @level2type = N'COLUMN', @level2name = N'tiCheckNbMonthBefore';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nombre de jours maximum pour les chèques pré datés', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Def', @level2type = N'COLUMN', @level2name = N'tiCheckNbDayBefore';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nombre de seconde minimum pour qu''une trace de la recherche soit conservée', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Def', @level2type = N'COLUMN', @level2name = N'siTraceSearch';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nombre de seconde minimum pour qu''une trace du rapport soit conservée', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Def', @level2type = N'COLUMN', @level2name = N'siTraceReport';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de l''utilisateur système (Mo_User) qui est utilisé lorsqu''UniAccès est l''initiateur de changement dans base de données.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Def', @level2type = N'COLUMN', @level2name = N'iID_Utilisateur_Systeme';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro d''entreprise du Québec (NEQ) qui identifie GUI de façon unique au Québec.  Il est utilisé dans les fichiers de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Def', @level2type = N'COLUMN', @level2name = N'vcNEQ_GUI';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nombre de mois avant de pouvoir faire des remboursements intégraux dans une convention individuelle issue d''un transfert provenant d''une convention Universitas(RIO)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Def', @level2type = N'COLUMN', @level2name = N'iNb_Mois_Avant_RIN_Apres_RIO';

