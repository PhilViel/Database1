CREATE TABLE [dbo].[Un_TIN] (
    [OperID]                         INT          NOT NULL,
    [ExternalPlanID]                 INT          NOT NULL,
    [tiBnfRelationWithOtherConvBnf]  TINYINT      NOT NULL,
    [vcOtherConventionNo]            VARCHAR (15) NOT NULL,
    [dtOtherConvention]              DATETIME     NOT NULL,
    [tiOtherConvBnfRelation]         TINYINT      NULL,
    [bAIP]                           BIT          NOT NULL,
    [bACESGPaid]                     BIT          NOT NULL,
    [bBECInclud]                     BIT          NOT NULL,
    [bPGInclud]                      BIT          NOT NULL,
    [fYearBnfCot]                    MONEY        NOT NULL,
    [fBnfCot]                        MONEY        NOT NULL,
    [fNoCESGCotBefore98]             MONEY        NOT NULL,
    [fNoCESGCot98AndAfter]           MONEY        NOT NULL,
    [fCESGCot]                       MONEY        NOT NULL,
    [fCESG]                          MONEY        NOT NULL,
    [fCLB]                           MONEY        NOT NULL,
    [fAIP]                           MONEY        NOT NULL,
    [fMarketValue]                   MONEY        NOT NULL,
    [bPendingApplication]            BIT          NOT NULL,
    [mIQEE]                          MONEY        NULL,
    [mIQEE_Rendement]                MONEY        NULL,
    [mIQEE_Plus]                     MONEY        NULL,
    [mIQEE_Plus_Rendement]           MONEY        NULL,
    [mIQEE_CotisationsAyantDroit]    MONEY        NULL,
    [mIQEE_CotisationsAyantPasDroit] MONEY        NULL,
    CONSTRAINT [PK_Un_TIN] PRIMARY KEY CLUSTERED ([OperID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_TIN_Un_ExternalPlan__ExternalPlanID] FOREIGN KEY ([ExternalPlanID]) REFERENCES [dbo].[Un_ExternalPlan] ([ExternalPlanID]),
    CONSTRAINT [FK_Un_TIN_Un_Oper__OperID] FOREIGN KEY ([OperID]) REFERENCES [dbo].[Un_Oper] ([OperID])
);


GO
/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: decGENE_Un_TIN_SuiviModifications
Nom du service		: Suivi des modifications à Un_TIN
But 				: Suivre les modifications aux enregistrements de la table "Un_TIN".
Facette				: GENE
Déclenchement		: Après la mise à jour d'un enregistrement de la table

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2009-09-04		Éric Deshaies						Création du service							
		2010-10-01		Steve Gouin							Gestion #DisableTrigger

****************************************************************************************************/
CREATE TRIGGER dbo.decGENE_Un_TIN_SuiviModifications ON dbo.Un_TIN AFTER INSERT, UPDATE
AS 
BEGIN
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Start'
	SET NOCOUNT ON;

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

	--------------------------------------------------------------------
	-- Suivre les modifications aux enregistrements de la table "Un_TIN"
	--------------------------------------------------------------------
	DECLARE @iID_Nouveau_Enregistrement INT,
			@iID_Ancien_Enregistrement INT,
			@NbOfRecord int,
			@i int

	DECLARE @Tinserted TABLE (
		Id INT IDENTITY (1,1),  
		ID_Nouveau_Enregistrement INT, 
		ID_Ancien_Enregistrement INT)

	SELECT @NbOfRecord = COUNT(*) FROM inserted

	INSERT INTO @Tinserted (ID_Nouveau_Enregistrement,ID_Ancien_Enregistrement)
		SELECT I.OperID, D.OperID
		FROM Inserted I
			 LEFT JOIN Deleted D ON D.OperID = I.OperID

	SET @i = 1

	WHILE @i <= @NbOfRecord
	BEGIN
		SELECT 
			@iID_Nouveau_Enregistrement = ID_Nouveau_Enregistrement, 
			@iID_Ancien_Enregistrement = ID_Ancien_Enregistrement 
		FROM @Tinserted 
		WHERE id = @i

		-- Ajouter la modification dans le suivi des modifications
		EXECUTE psGENE_AjouterSuiviModification 4, @iID_Nouveau_Enregistrement, @iID_Ancien_Enregistrement

		SET @i = @i + 1
	END

	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des Transferts (TIN)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_TIN';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de l’opération', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_TIN', @level2type = N'COLUMN', @level2name = N'OperID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de l’autre plan (Plan externe)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_TIN', @level2type = N'COLUMN', @level2name = N'ExternalPlanID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Lien de parenté entre les bénéficiaires du REEE cédant (1 = Même, 2 = Frère ou soeur et est agé de moins de 21 ans, 3 = Aucun des deux)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_TIN', @level2type = N'COLUMN', @level2name = N'tiBnfRelationWithOtherConvBnf';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro de l’autre contrat', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_TIN', @level2type = N'COLUMN', @level2name = N'vcOtherConventionNo';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d’entrée en vigueur de l’autre convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_TIN', @level2type = N'COLUMN', @level2name = N'dtOtherConvention';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Type de REEE (1 = Individuel, 2 = Famille comptant uniquement des frères et des sœurs, 3 = Famille et 4 = Groupe)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_TIN', @level2type = N'COLUMN', @level2name = N'tiOtherConvBnfRelation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Indique si un paiement de revenu accumulé a été effectué sur le REEE cédant.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_TIN', @level2type = N'COLUMN', @level2name = N'bAIP';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Indique si la SCEE+ a déjà été versée dans le REEE cédant.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_TIN', @level2type = N'COLUMN', @level2name = N'bACESGPaid';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Indique si le BEC est inclus dans le transfert.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_TIN', @level2type = N'COLUMN', @level2name = N'bBECInclud';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Indique si la subvention provincial est incluse dans le transfert.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_TIN', @level2type = N'COLUMN', @level2name = N'bPGInclud';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Cotisations versés pour le bénéficiaire cette année.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_TIN', @level2type = N'COLUMN', @level2name = N'fYearBnfCot';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Cotisations cumulatives', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_TIN', @level2type = N'COLUMN', @level2name = N'fBnfCot';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Cotisations non-subventionnées jusqu’en 1998.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_TIN', @level2type = N'COLUMN', @level2name = N'fNoCESGCotBefore98';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Cotisations non-subventionnées en 1998 et après.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_TIN', @level2type = N'COLUMN', @level2name = N'fNoCESGCot98AndAfter';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Cotisations subventionnées', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_TIN', @level2type = N'COLUMN', @level2name = N'fCESGCot';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'SCEE et SCEE+', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_TIN', @level2type = N'COLUMN', @level2name = N'fCESG';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'BEC', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_TIN', @level2type = N'COLUMN', @level2name = N'fCLB';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Revenues accumulés', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_TIN', @level2type = N'COLUMN', @level2name = N'fAIP';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = ' Valeur marchande totale des biens transférés', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_TIN', @level2type = N'COLUMN', @level2name = N'fMarketValue';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Indique s’il y a une demande de BEC, SCEE ou de subvention provinciale en cours.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_TIN', @level2type = N'COLUMN', @level2name = N'bPendingApplication';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant de base versé de l''IQEE', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_TIN', @level2type = N'COLUMN', @level2name = N'mIQEE';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Intérêt de base versé de l''IQEE', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_TIN', @level2type = N'COLUMN', @level2name = N'mIQEE_Rendement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant de majoration versé de l''IQEE+', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_TIN', @level2type = N'COLUMN', @level2name = N'mIQEE_Plus';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Intérêt de majoration versé de l''IQEE+', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_TIN', @level2type = N'COLUMN', @level2name = N'mIQEE_Plus_Rendement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant des cotisations versées après le 20 février 2007 ayant donné droit à l''IQEE', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_TIN', @level2type = N'COLUMN', @level2name = N'mIQEE_CotisationsAyantDroit';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant des cotisations versées après le 20 février 2007 n''ayant pas donné droit à l''IQEE', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_TIN', @level2type = N'COLUMN', @level2name = N'mIQEE_CotisationsAyantPasDroit';

