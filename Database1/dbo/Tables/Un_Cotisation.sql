CREATE TABLE [dbo].[Un_Cotisation] (
    [CotisationID]          [dbo].[MoID]      IDENTITY (1, 1) NOT NULL,
    [OperID]                [dbo].[MoID]      NOT NULL,
    [UnitID]                [dbo].[MoID]      NOT NULL,
    [EffectDate]            [dbo].[MoGetDate] NOT NULL,
    [Cotisation]            [dbo].[MoMoney]   NOT NULL,
    [Fee]                   [dbo].[MoMoney]   NOT NULL,
    [BenefInsur]            [dbo].[MoMoney]   NOT NULL,
    [SubscInsur]            [dbo].[MoMoney]   NOT NULL,
    [TaxOnInsur]            [dbo].[MoMoney]   NOT NULL,
    [bInadmissibleComActif] BIT               CONSTRAINT [DF_Un_Cotisation_bInadmissibleComActif] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_Un_Cotisation] PRIMARY KEY CLUSTERED ([CotisationID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_Cotisation_Un_Oper__OperID] FOREIGN KEY ([OperID]) REFERENCES [dbo].[Un_Oper] ([OperID]),
    CONSTRAINT [FK_Un_Cotisation_Un_Unit__UnitID] FOREIGN KEY ([UnitID]) REFERENCES [dbo].[Un_Unit] ([UnitID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Cotisation_OperID_UnitID]
    ON [dbo].[Un_Cotisation]([OperID] ASC, [UnitID] ASC)
    INCLUDE([Cotisation], [Fee]);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Cotisation_UnitID_Cotisation_Fee]
    ON [dbo].[Un_Cotisation]([UnitID] ASC, [Cotisation] ASC, [Fee] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Cotisation_UnitID_OperID_Cotisation_Fee_SubscInsur_BenefInsur_TaxOnInsur]
    ON [dbo].[Un_Cotisation]([UnitID] ASC, [OperID] ASC, [Cotisation] ASC, [Fee] ASC, [SubscInsur] ASC, [BenefInsur] ASC, [TaxOnInsur] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Cotisation_UnitID_CotisationID_EffectDate_OperID]
    ON [dbo].[Un_Cotisation]([UnitID] ASC, [CotisationID] ASC, [EffectDate] ASC, [OperID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Cotisation_CotisationID]
    ON [dbo].[Un_Cotisation]([CotisationID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Cotisation_UnitID_EffectDate_OperID]
    ON [dbo].[Un_Cotisation]([UnitID] ASC, [EffectDate] ASC, [OperID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE STATISTICS [stat_Un_Cotisation_IQEE_1]
    ON [dbo].[Un_Cotisation]([OperID], [CotisationID], [UnitID], [EffectDate]);


GO
CREATE STATISTICS [stat_Un_Cotisation_IQEE_2]
    ON [dbo].[Un_Cotisation]([EffectDate], [OperID], [UnitID]);


GO
/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: TUn_Cotisation

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2009-09-04		Éric Deshaies						Suivre les modifications aux enregistrements
															de la table "Un_Cotisation".						
		2010-10-01		Steve Gouin							Gestion du #DisableTrigger
****************************************************************************************************/
CREATE TRIGGER [dbo].[TUn_Cotisation] ON [dbo].[Un_Cotisation] FOR INSERT, UPDATE, DELETE 
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
  @LastVerifDate MoDate;

  SET @LastVerifDate = (SELECT LastVerifDate + 1 FROM Un_Def);

  IF  (SELECT COUNT(I.CotisationID) 
       FROM INSERTED I
       JOIN Un_Oper O ON (I.OperID = O.OperID)
       LEFT JOIN DELETED D ON (D.OperID = O.OperID)
       WHERE O.OperDate < @LastVerifDate
             AND D.CotisationID IS NULL) > 0
   OR (SELECT COUNT(D.CotisationID) 
       FROM DELETED D
       JOIN Un_Oper O ON (D.OperID = O.OperID)
       LEFT JOIN INSERTED I ON (I.OperID = O.OperID)
       WHERE O.OperDate < @LastVerifDate
           AND I.CotisationID IS NULL) > 0
   OR (SELECT COUNT(D.CotisationID) 
       FROM DELETED D
       JOIN Un_Oper O ON (D.OperID = O.OperID)
       JOIN INSERTED I ON (I.OperID = O.OperID)
       WHERE O.OperDate < @LastVerifDate
         AND (I.Cotisation <> D.Cotisation 
           OR I.Fee <> D.Fee 
           OR I.SubscInsur <> D.SubscInsur 
           OR I.BenefInsur <> D.BenefInsur 
           OR I.TaxOnInsur <> D.TaxOnInsur 
           OR I.CotisationID <> D.CotisationID 
           OR I.UnitID <> D.UnitID 
           OR I.OperID <> D.OperID)) > 0
  BEGIN
    ROLLBACK TRANSACTION;
    RAISERROR('Vous ne pouvez pas travailler dans cette période',16,1)
  END
  ELSE
  BEGIN 
    UPDATE Un_Cotisation SET
      EffectDate = dbo.fn_Mo_DateNoTime(i.EffectDate),
      Cotisation = ROUND(ISNULL(i.Cotisation, 0), 2),
      Fee = ROUND(ISNULL(i.Fee, 0), 2),
      BenefInsur = ROUND(ISNULL(i.BenefInsur, 0), 2),
      SubscInsur = ROUND(ISNULL(i.SubscInsur, 0), 2),
      TaxOnInsur = ROUND(ISNULL(i.TaxOnInsur, 0), 2)
    FROM Un_Cotisation U, inserted i
    WHERE U.CotisationID = i.CotisationID

	---------------------------------------------------------------------------
	-- Suivre les modifications aux enregistrements de la table "Un_Cotisation"
	---------------------------------------------------------------------------

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
		SELECT I.CotisationID, D.CotisationID
		FROM Inserted I
			 LEFT JOIN Deleted D ON D.CotisationID = I.CotisationID

	SET @i = 1

	WHILE @i <= @NbOfRecord
	BEGIN
		SELECT 
			@iID_Nouveau_Enregistrement = ID_Nouveau_Enregistrement, 
			@iID_Ancien_Enregistrement = ID_Ancien_Enregistrement 
		FROM @Tinserted 
		WHERE id = @i

		-- Ajouter la modification dans le suivi des modifications
		EXECUTE psGENE_AjouterSuiviModification 2, @iID_Nouveau_Enregistrement, @iID_Ancien_Enregistrement

		SET @i = @i + 1
	END

  END;
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END;


GO
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	TUn_Cotisation_dtFirstDeposit
Description         :	Trigger qui calcul le champs calcul‚ dtFirstDeposit de la table Un_Unit
Note                :	ADX0001206	IA	2006-11-06	Bruno Lapointe		Cr‚ation
										2010-10-01	Steve Gouin			Gestion du #DisableTrigger
										2018-01-03	Donald Huppé		Ajout de ,'RES','OUT','FRM'
*********************************************************************************************************************/
CREATE TRIGGER [dbo].[TUn_Cotisation_dtFirstDeposit] ON [dbo].[Un_Cotisation] FOR INSERT, DELETE
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

	-- Calcul le champ dtFirstDeposit lors de l'insertion
	IF EXISTS (
		SELECT DISTINCT 
			I.UnitID
		FROM INSERTED I
		JOIN dbo.Un_Unit U ON U.UnitID = I.UnitID
		JOIN Un_Oper O ON O.OperID = I.OperID
		WHERE O.OperTypeID NOT IN ('BEC','RES','OUT','FRM','FRS')
			AND O.OperDate < ISNULL(U.dtFirstDeposit,O.OperDate+1)
		) 
	BEGIN
		UPDATE dbo.Un_Unit 
		SET dtFirstDeposit = O.OperDate
		FROM dbo.Un_Unit U
		JOIN INSERTED I ON I.UnitID = U.UnitID
		JOIN Un_Oper O ON O.OperID = I.OperID
		WHERE O.OperTypeID NOT IN ('BEC','RES','OUT','FRM','FRS')
			AND O.OperDate < ISNULL(U.dtFirstDeposit,O.OperDate+1)
	END
	
	-- Calcul le champ dtFirstDeposit lors de la suppression
	IF EXISTS (
		SELECT DISTINCT 
			D.UnitID
		FROM DELETED D
		JOIN dbo.Un_Unit U ON U.UnitID = D.UnitID
		JOIN Un_Oper O ON O.OperID = D.OperID
		WHERE O.OperTypeID NOT IN ('BEC','RES','OUT','FRM','FRS')
			AND O.OperDate = U.dtFirstDeposit
			AND U.dtFirstDeposit > '1998-01-30' -- On ne gŠre pas la suppression de cotisation ant‚rieure … cette date.
		) 
	BEGIN
		DECLARE @tdtFirstDeposit TABLE (
			UnitID INTEGER PRIMARY KEY )

		INSERT INTO @tdtFirstDeposit
			SELECT DISTINCT
				D.UnitID
			FROM DELETED D
			JOIN dbo.Un_Unit U ON U.UnitID = D.UnitID
			JOIN Un_Oper O ON O.OperID = D.OperID
			WHERE O.OperTypeID NOT IN ('BEC','RES','OUT','FRM','FRS')
				AND O.OperDate = U.dtFirstDeposit

		-- Remet … null le champ dtFirstDeposit quand il s'agit de seul d‚p“t 
		UPDATE dbo.Un_Unit 
		SET dtFirstDeposit = NULL
		FROM dbo.Un_Unit U
		JOIN @tdtFirstDeposit F ON F.UnitID = U.UnitID
		WHERE U.dtFirstDeposit > '1998-01-30' -- On ne gŠre pas la suppression de cotisation ant‚rieure … cette date.
			AND U.UnitID NOT IN (
				SELECT DISTINCT
					F.UnitID
				FROM @tdtFirstDeposit F
				JOIN Un_Cotisation Ct ON Ct.UnitID = F.UnitID
				LEFT JOIN DELETED D ON D.CotisationID = Ct.CotisationID
				JOIN Un_Oper O ON O.OperID = Ct.OperID
				WHERE O.OperTypeID NOT IN ('BEC','RES','OUT','FRM','FRS')
					AND D.CotisationID IS NULL
				)

		-- Remet … null le champ dtFirstDeposit quand il s'agit de seul d‚p“t 
		UPDATE dbo.Un_Unit 
		SET dtFirstDeposit = V.dtFirstDeposit
		FROM dbo.Un_Unit U
		JOIN (
			SELECT 
				F.UnitID,
				dtFirstDeposit = dbo.fn_Mo_DateNoTime(MIN(O.OperDate))
			FROM @tdtFirstDeposit F
			JOIN Un_Cotisation Ct ON Ct.UnitID = F.UnitID
			JOIN Un_Oper O ON O.OperID = Ct.OperID
			WHERE O.OperTypeID NOT IN ('BEC','RES','OUT','FRM','FRS')
				AND Ct.CotisationID NOT IN (
						SELECT CotisationID
						FROM DELETED
						)
			GROUP BY F.UnitID
			) V ON V.UnitID = U.UnitID
		WHERE U.dtFirstDeposit IS NOT NULL
	END
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END


GO
/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	TUn_Cotisation_State
Description         :	Calcul les ‚tats des conventions et de ces groupes d'unit‚s et les mettent … jour,  ce lors 
								d'ajout, modification et suppression de cotisation
Valeurs de retours  :	N/A
Note                :						2004-06-11	Bruno Lapointe		Cr‚ation Point 10.23.02
								ADX0000694	IA	2005-06-03	Bruno Lapointe		Renommer la proc‚dure 
																							TT_UN_ConventionAndUnitStateForUnit
								ADX0001095	BR	2005-12-15	Bruno Lapointe		Correction mise … jour d'‚tat suite … Deadlock.
												2010-10-04	Steve Gouin			Gestion des disable trigger par #DisableTrigger
*********************************************************************************************************************/
CREATE TRIGGER dbo.TUn_Cotisation_State ON dbo.Un_Cotisation AFTER INSERT, UPDATE, DELETE
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

	-- V‚rifie qu'il ya une modification au niveau de l'‚pargne ou les frais
	IF EXISTS (
			SELECT 
				I.CotisationID
			FROM INSERTED I
			LEFT JOIN DELETED D ON I.CotisationID = D.CotisationID
			WHERE D.CotisationID IS NULL) OR
		EXISTS (
			SELECT 
				D.CotisationID
			FROM DELETED D
			LEFT JOIN INSERTED I ON I.CotisationID = D.CotisationID
			WHERE I.CotisationID IS NULL) OR
		EXISTS (
			SELECT 
				D.CotisationID
			FROM DELETED D
			JOIN INSERTED I ON I.CotisationID = D.CotisationID
			WHERE I.Cotisation <> D.Cotisation
				OR I.Fee <> D.Fee)
	BEGIN
		DECLARE 
			@UnitID INTEGER,
			@UnitIDs VARCHAR(8000)
	
		-- Cr‚e une chaŒne de caractŠre avec tout les groupes d'unit‚s affect‚s
		DECLARE UnitIDs CURSOR FOR
			SELECT
				UnitID
			FROM INSERTED 
			UNION
			SELECT
				UnitID
			FROM DELETED 
	
		OPEN UnitIDs
	
		FETCH NEXT FROM UnitIDs
		INTO
			@UnitID
	
		SET @UnitIDs = ''
	
		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			SET @UnitIDs = @UnitIDs + CAST(@UnitID AS VARCHAR(30)) + ','
		
			FETCH NEXT FROM UnitIDs
			INTO
				@UnitID
		END
	
		CLOSE UnitIDs
		DEALLOCATE UnitIDs
	
		-- Appelle la proc‚dure qui met … jour les ‚tats des groupes d'unit‚s et des conventions
		EXECUTE TT_UN_ConventionAndUnitStateForUnit @UnitIDs 
	END

	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END

GO
/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	TUn_Cotisation_Doc
Description         :	Trigger qui commande automatique de document lors de la premiŠre transaction sur un	groupe 
								d'unit‚s
Note                :				IA	2004-06-01	Bruno Lapointe					Création
						ADX0000111	UR	2004-09-24	Bruno Lapointe		Document seulement sur premier CPA ou PRD
						ADX0001089	BR	2004-09-24	Bruno Lapointe		Pas de Certificat d'assurance vie si le montant 
																								à cotiser de la modalit‚ est 0.00$
						ADX0000691	IA	2005-05-06	Bruno Lapointe		Envoi automatique de la lettre d'émission au
																								tuteur sur premier CPA ou PRD.
						ADX0000831	IA	2006-03-30	Bruno Lapointe		Adaptation PCEE 4.3
						ADX0001355	IA	2007-09-20	Bruno Lapointe		Renommer SP_RP_UN_ConventionBourseEtudeIndividuel pour RP_UN_ConventionBourseEtudeIndividuel
													Steve Gouin			Gestion du #DisableTrigger
										2014-10-03	Pierre-Luc Simard	Générer certains documents uniquement si la convention n'a pas été créée via la proposition électronique
																		Ne plus générer le certificat d'assurance
										2014-10-16	Donald Huppé		glpi 12635 : ajout de l'opération CHQ et RDI dans la détermination du premier dépôt
										2015-09-03	Pierre-Luc Simard	Ne plus généré les documents, à part le contrat Individuel
																		Ne plus valider le type de cotisation
																		Exclure les conventions "T"
										2015-09-09	Pierre-Luc Simard	Le premier dépôt ne doit pas être un BEC
										2015-09-21	Pierre-Luc Simard	Le premier dépôt ne doit pas être un BNA ou une RES
										2015-11-23	Pierre-Luc Simard	Ne plus générer la façade Individuel
										2015-12-15	Pierre-Luc Simard	Ne plus appeler RP_UN_ConventionBourseEtudeIndividuel mais remplir la table Un_ConventionTransitionState 
										2016-01-13	Pierre-Luc Simard	Ne pas tenir compte des cotisation de type BEC, BNA, RES
										2016-01-25	Pierre-Luc Simard	Le code de transition est maintenant "1" pour la génération de la façade Individuel

*********************************************************************************************************************/
CREATE TRIGGER [dbo].[TUn_Cotisation_Doc] ON [dbo].[Un_Cotisation] FOR INSERT
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
	
	-- Vérifie si c'est le premier dépôt
	IF EXISTS(
		SELECT DISTINCT 
			I.UnitID
		FROM INSERTED I
		WHERE I.UnitID NOT IN (
				SELECT 
					Ct.UnitID
				FROM INSERTED I
				JOIN Un_Cotisation Ct ON Ct.UnitID = I.UnitID
				JOIN Un_Oper O ON O.OperID = CT.OperID
				WHERE I.CotisationID <> Ct.CotisationID
					AND O.OperTypeID NOT IN ('BEC', 'BNA', 'RES')
				)
		) 
	BEGIN
		
		INSERT INTO Un_ConventionTransitionState(
			ConventionID,
	        TransitionCodeID)
		SELECT DISTINCT
			U.ConventionID,
			1 -- Façade individuel à créer (PremierDepotConventionIndividuelleREEE)
		FROM INSERTED I
		JOIN dbo.Un_Unit U ON U.UnitID = I.UnitID
		JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
		JOIN Un_Plan P ON P.PlanID = C.PlanID
		JOIN Un_Oper O ON O.OperID = I.OperID
		LEFT JOIN ( -- Vérifie si le groupe d'unité a déjà d'autres cotisations
			SELECT 
				Ct.UnitID
			FROM INSERTED I
			JOIN Un_Cotisation Ct ON Ct.UnitID = I.UnitID
			JOIN Un_Oper O ON O.OperID = Ct.OperID
			WHERE I.CotisationID <> Ct.CotisationID
				AND O.OperTypeID NOT IN ('BEC', 'BNA', 'RES')
			) V ON V.UnitID = U.UnitID
		LEFT JOIN ( -- Va chercher l'état actuel de la convention
			SELECT
				CS.ConventionID ,
				CCS.StartDate ,
				CS.ConventionStateID
			FROM Un_ConventionConventionState CS
			JOIN (
				SELECT
					ConventionID ,
					StartDate = MAX(StartDate)
				FROM Un_ConventionConventionState
				GROUP BY ConventionID
					) CCS ON CCS.ConventionID = CS.ConventionID
					AND CCS.StartDate = CS.StartDate 
			) CSS on C.ConventionID = CSS.ConventionID
		WHERE O.OperTypeID NOT IN ('BEC', 'BNA', 'RES')
			AND V.UnitID IS NULL -- La cotisation est le premier dépôt effectué dans ce groupe d'unité
			AND P.PlanTypeID = 'IND' -- La convention doit être de type Individuel
			AND U.InForceDate >= '2003-01-01'
			AND U.TerminatedDate IS NULL -- Pas résilié
			AND U.IntReimbDate IS NULL -- Pas de RI versé
			AND C.ConventionNo NOT LIKE 'T%'
			AND CSS.ConventionStateID = 'REE' -- La convention doit être à l'état REEE
			AND C.ConventionID NOT IN (
				SELECT DISTINCT 
					CTS.ConventionID
				FROM Un_ConventionTransitionState CTS
				WHERE CTS.TransitionCodeID = 1)
		
	END
	
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END

GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des cotisations.  La table des cotisations contient les transactions financières affectant les épargnes, les frais, l''assurance souscripteur, l''assurance bénéficiaire et les taxes.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Cotisation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la cotisation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Cotisation', @level2type = N'COLUMN', @level2name = N'CotisationID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''opération (Un_Oper) dont fait partie la cotisation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Cotisation', @level2type = N'COLUMN', @level2name = N'OperID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du groupe d''unités (Un_Unit) auquel appartient la cotisation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Cotisation', @level2type = N'COLUMN', @level2name = N'UnitID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date effective de la cotisation au gouvernement.  Il arrive que Gestion Universitas reçoive un chèque à la fin de décembre mais en fait l''encaissement seulement en janvier.  Il y a un maximum de cotisation subventionnable par année, alors dans ce cas on mais la date effective en décembre et celle de l''opération en janvier afin de ne pas pénaliser le souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Cotisation', @level2type = N'COLUMN', @level2name = N'EffectDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant d''épargnes de la transaction.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Cotisation', @level2type = N'COLUMN', @level2name = N'Cotisation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de frais de la transaction.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Cotisation', @level2type = N'COLUMN', @level2name = N'Fee';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de prime d''assurance bénéficiaire de la transaction.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Cotisation', @level2type = N'COLUMN', @level2name = N'BenefInsur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de prime d''assurance souscripteur de la transaction.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Cotisation', @level2type = N'COLUMN', @level2name = N'SubscInsur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Taxes sur les primes d''assurances de la transaction.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Cotisation', @level2type = N'COLUMN', @level2name = N'TaxOnInsur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si un groupe d''unité faisant partie de l''opération était inadmissible à recevoir des commisisons sur l''actif au moment de l''opération.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Cotisation', @level2type = N'COLUMN', @level2name = N'bInadmissibleComActif';

