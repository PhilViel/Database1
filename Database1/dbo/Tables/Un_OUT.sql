CREATE TABLE [dbo].[Un_OUT] (
    [OperID]                        INT          NOT NULL,
    [ConventionID]                  INT          NULL,
    [ExternalPlanID]                INT          NOT NULL,
    [tiBnfRelationWithOtherConvBnf] TINYINT      NOT NULL,
    [vcOtherConventionNo]           VARCHAR (15) NOT NULL,
    [tiREEEType]                    TINYINT      NULL,
    [bEligibleForCESG]              BIT          NOT NULL,
    [bEligibleForCLB]               BIT          NOT NULL,
    [bOtherContratBnfAreBrothers]   BIT          NOT NULL,
    [fNoCESGCotBefore98]            MONEY        NOT NULL,
    [fNoCESGCot98AndAfter]          MONEY        NOT NULL,
    [fYearBnfCot]                   MONEY        NULL,
    [fBnfCot]                       MONEY        NULL,
    [fCESGCot]                      MONEY        NULL,
    [bCES_Authorized]               BIT          NULL,
    [fCESG]                         MONEY        NULL,
    [fCLB]                          MONEY        NULL,
    [fAIP]                          MONEY        NULL,
    [fMarketValue]                  MONEY        NULL,
    [bTransfertPartiel]             BIT          NULL,
    [mEpargne]                      MONEY        NULL,
    [mFrais]                        MONEY        NULL,
    [bIQEE_Autoriser]               BIT          NULL,
    [mIQEE]                         MONEY        NULL,
    [mIQEE_Plus]                    MONEY        NULL,
    [mIQEE_CotAyantDroit]           MONEY        NULL,
    [mIQEE_CotNonDroit]             MONEY        NULL,
    [mIQEE_CotAvantDebut]           MONEY        NULL,
    CONSTRAINT [PK_Un_OUT] PRIMARY KEY CLUSTERED ([OperID] ASC),
    CONSTRAINT [FK_Un_OUT_Un_Convention__ConventionID] FOREIGN KEY ([ConventionID]) REFERENCES [dbo].[Un_Convention] ([ConventionID]),
    CONSTRAINT [FK_Un_OUT_Un_ExternalPlan__ExternalPlanID] FOREIGN KEY ([ExternalPlanID]) REFERENCES [dbo].[Un_ExternalPlan] ([ExternalPlanID]),
    CONSTRAINT [FK_Un_OUT_Un_Oper__OperID] FOREIGN KEY ([OperID]) REFERENCES [dbo].[Un_Oper] ([OperID])
);


GO
/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: trgUn_OUT_SuiviModifications (anciennement: decGENE_Un_OUT_SuiviModifications)
Nom du service		: Suivi des modifications à Un_OUT
But 				: Suivre les modifications aux enregistrements de la table "Un_OUT".
Facette				: GENE
Déclenchement		: Après la mise à jour d'un enregistrement de la table

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2009-09-04		Éric Deshaies						Création du service							
		2010-10-01		Steve Gouin							Gestion #DisableTrigger

****************************************************************************************************/
CREATE TRIGGER dbo.trgUn_OUT_SuiviModifications ON dbo.Un_OUT AFTER INSERT, UPDATE
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
	-- Suivre les modifications aux enregistrements de la table "Un_OUT"
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
		EXECUTE psGENE_AjouterSuiviModification 5, @iID_Nouveau_Enregistrement, @iID_Ancien_Enregistrement

		SET @i = @i + 1
	END

	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END

GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table des Transferts OUT', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OUT';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID de l’opération', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OUT', @level2type = N'COLUMN', @level2name = N'OperID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID de la convention', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OUT', @level2type = N'COLUMN', @level2name = N'ConventionID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID de l''autre plan', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OUT', @level2type = N'COLUMN', @level2name = N'ExternalPlanID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Lien de parenté entre les bénéficiaires du REEE cessionnaire (1 = Même, 2 = Frère ou sœur, 3 = Aucun des deux)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OUT', @level2type = N'COLUMN', @level2name = N'tiBnfRelationWithOtherConvBnf';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro de l’autre contrat', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OUT', @level2type = N'COLUMN', @level2name = N'vcOtherConventionNo';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Type de REEE (1 = Individuel, 2 = Famille comptant uniquement des frères et des sœurs, 3 = Famille et 4 = Groupe)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OUT', @level2type = N'COLUMN', @level2name = N'tiREEEType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si le promoteur du régime cessionnaire a signé des ententes avec le RHDDC pour administrer la SCEE', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OUT', @level2type = N'COLUMN', @level2name = N'bEligibleForCESG';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si le promoteur du régime cessionnaire a signé des ententes avec le RHDDC pour administrer la BEC', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OUT', @level2type = N'COLUMN', @level2name = N'bEligibleForCLB';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si les bénéficiaires du régime cessionnaire sont tous des frères ou des sœurs', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OUT', @level2type = N'COLUMN', @level2name = N'bOtherContratBnfAreBrothers';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Cotisations non-subventionnées jusqu’en 1998', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OUT', @level2type = N'COLUMN', @level2name = N'fNoCESGCotBefore98';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Cotisations non-subventionnées en 1998 et après', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OUT', @level2type = N'COLUMN', @level2name = N'fNoCESGCot98AndAfter';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Cotisations versés pour le bénéficiaire cette année', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OUT', @level2type = N'COLUMN', @level2name = N'fYearBnfCot';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Cotisations cumulatives', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OUT', @level2type = N'COLUMN', @level2name = N'fBnfCot';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Cotisations subventionnées', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OUT', @level2type = N'COLUMN', @level2name = N'fCESGCot';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Déjà reçu de la SCEE+', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OUT', @level2type = N'COLUMN', @level2name = N'bCES_Authorized';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'SCEE et SCEE+', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OUT', @level2type = N'COLUMN', @level2name = N'fCESG';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'BEC', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OUT', @level2type = N'COLUMN', @level2name = N'fCLB';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Revenues accumulés', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OUT', @level2type = N'COLUMN', @level2name = N'fAIP';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Valeur marchande totale des biens transférés', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OUT', @level2type = N'COLUMN', @level2name = N'fMarketValue';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur si c''est un transfert partiel', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OUT', @level2type = N'COLUMN', @level2name = N'bTransfertPartiel';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant des cotisations transférées', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OUT', @level2type = N'COLUMN', @level2name = N'mEpargne';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant des frais transférées', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OUT', @level2type = N'COLUMN', @level2name = N'mFrais';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Déjà reçu de la IQEE+', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OUT', @level2type = N'COLUMN', @level2name = N'bIQEE_Autoriser';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'IQÉÉ inclus dans le transfert', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OUT', @level2type = N'COLUMN', @level2name = N'mIQEE';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'IQÉÉ+ inclus dans le transfert', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OUT', @level2type = N'COLUMN', @level2name = N'mIQEE_Plus';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant de cotisations ayant été subventionné par l''IQÉÉ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OUT', @level2type = N'COLUMN', @level2name = N'mIQEE_CotAyantDroit';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant de cotisations n''ayant pas été subventionné par l''IQÉÉ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OUT', @level2type = N'COLUMN', @level2name = N'mIQEE_CotNonDroit';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant des cotisations effectuées avant les débuts de l''IQÉÉ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OUT', @level2type = N'COLUMN', @level2name = N'mIQEE_CotAvantDebut';

