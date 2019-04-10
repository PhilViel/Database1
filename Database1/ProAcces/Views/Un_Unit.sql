CREATE VIEW [ProAcces].[Un_Unit] AS
	SELECT UnitID, ConventionID, RepID, RepResponsableID, ModalID, UnitQty, WantSubscriberInsurance, InForceDate,
		   IntReimbDateAdjust, SignatureDate, SaleSourceID, dtFirstDeposit, SubscribeAmountAjustment, LastDepositForDoc,
		   IsActivated = CAST(CASE WHEN ActivationConnectID IS NULL THEN 0 ELSE 1 END AS BIT),
             bActiverSansLettre, iID_BeneficiaireOriginal, iID_RepComActif, TerminatedDate,
		   -- Légacy
		   UnitNo, iSous_Cat_ID, 
		   -- Ce qui suit, devrait être enlevé
	       IntReimbDate, PETransactionId
	FROM dbo.Un_Unit
GO
/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: TR_Un_Unit_Del
						
Historique des modifications:
		Date				Programmeur				Description										Référence
		------------		------------------------	-----------------------------------------	------------
		2015-08-13	Steeve Picard				Création
*********************************************************************************************************************/
CREATE TRIGGER [ProAcces].[TR_Un_Unit_Del] ON [ProAcces].[Un_Unit]
	   INSTEAD OF DELETE
AS BEGIN
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Start'

	-- *** AVERTISSEMENT *** Ce script doit toujours figurer en tête de trigger

	-- Si la table #DisableTrigger est présente, il se pourrait que le trigger
	-- ne soit pas à exécuter
	IF object_id('tempdb..#DisableTrigger') is null 
		CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))
	ELSE BEGIN
		-- Le trigger doit être retrouvé dans la table pour être ignoré
		IF EXISTS (SELECT 1 FROM #DisableTrigger WHERE OBJECT_NAME(@@PROCID) like vcTriggerName)
		BEGIN
			-- Ne pas faire le trigger
			EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Trigger Ignored'
			RETURN
		END
	END

	-- *** FIN AVERTISSEMENT *** 
	INSERT INTO #DisableTrigger VALUES('TR_Un_Unit_Del')	
	--INSERT INTO #DisableTrigger VALUES('TUn_Unit')	
	--INSERT INTO #DisableTrigger VALUES('TUn_Unit_State')	
	--INSERT INTO #DisableTrigger VALUES('TR_D_Un_Unit_F_dtRegStartDate')	

	DELETE FROM TB
	FROM dbo.Un_Unit TB INNER JOIN deleted D ON D.UnitID = TB.UnitID

	--IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
    --    DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TUn_Unit'
	--IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
    --    DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TUn_Unit_State'
	--IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
    --    DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TR_D_Un_Unit_F_dtRegStartDate'

	IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TR_Un_Unit_Del'
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END

GO
/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: TR_Un_Unit_Ins
						
Historique des modifications:
		Date		Programmeur			Description									Référence
		----------	------------------	-----------------------------------------	------------
		2015-08-13	Steeve Picard		Création
		2016-05-18	Pierre-Luc Simard   Ajout des champs iID_BeneficiaireOriginal et iID_RepComActif
        2018-09-05  Pierre-Luc Simard   Ajout du champ TerminatedDate
		2018-09-27	Maxime Martel		PROD-11034 Journalisation des cotisations supplémentaires erronée
*********************************************************************************************************************/
CREATE TRIGGER [ProAcces].[TR_Un_Unit_Ins] ON [ProAcces].[Un_Unit]
	   INSTEAD OF INSERT
AS BEGIN
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Start'

	-- *** AVERTISSEMENT *** Ce script doit toujours figurer en tête de trigger

	-- Si la table #DisableTrigger est présente, il se pourrait que le trigger
	-- ne soit pas à exécuter
	IF object_id('tempdb..#DisableTrigger') is null 
		CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))
	ELSE BEGIN
		-- Le trigger doit être retrouvé dans la table pour être ignoré
		IF EXISTS (SELECT 1 FROM #DisableTrigger WHERE OBJECT_NAME(@@PROCID) like vcTriggerName)
		BEGIN
			-- Ne pas faire le trigger
			EXEC dbo.TT_PrintDebugMsg @@PROCID, 'Trigger Ignored'
			RETURN
		END
	END

	-- *** FIN AVERTISSEMENT *** 
	INSERT INTO #DisableTrigger VALUES('TR_Un_Unit_Ins')	
	--INSERT INTO #DisableTrigger VALUES('TUn_Unit')	
	--INSERT INTO #DisableTrigger VALUES('TUn_Unit_State')	
	--INSERT INTO #DisableTrigger VALUES('TR_I_Un_Unit_F_dtRegStartDate')	

	-- Insert le nouveau record

	INSERT INTO dbo.Un_Unit (
		   ConventionID, RepID, RepResponsableID, ModalID, UnitQty, WantSubscriberInsurance, InForceDate,
		   IntReimbDateAdjust, SignatureDate, SaleSourceID, dtFirstDeposit, SubscribeAmountAjustment, LastDepositForDoc,
		   -- Garder pour le Legacy
		   UnitNo, iSous_Cat_ID, ActivationConnectID, 
		   -- Ce qui suit, devrait être enlevé
	       IntReimbDate, PETransactionId, bActiverSansLettre, iID_BeneficiaireOriginal, iID_RepComActif, TerminatedDate
	)
	SELECT
		  ConventionID, NullIf(RepID, 0), NullIf(RepResponsableID, 0), ModalID, ROUND(ISNULL(UnitQty, 0), 4), WantSubscriberInsurance, Cast(InForceDate as date),
		  IntReimbDateAdjust, Cast(SignatureDate as date), NullIf(SaleSourceID, 0), dtFirstDeposit, SubscribeAmountAjustment, LastDepositForDoc,
		  -- Garder pour le Legacy
		  UnitNo = '', iSous_Cat_ID = 1, ActivationConnectID = CASE IsNull(IsActivated, 0) WHEN 0 THEN NULL ELSE 2 END,
		  -- Ce qui suit, devrait être enlevé
	      IntReimbDate, PETransactionId, ISNULL(bActiverSansLettre, 0), iID_BeneficiaireOriginal, iID_RepComActif, TerminatedDate
	FROM inserted

	-- Ce SELECT est obligé et doit être immédiatement après l'insertion afin que Entity Framework puisse recevoir le Id du nouveau record
	DECLARE @Id_Unit int
	SET @Id_Unit = IDENT_CURRENT('dbo.Un_Unit')
	SELECT @Id_Unit as UnitID

	--IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
    --    DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TUn_Unit'
	--IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
    --    DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TUn_Unit_State'
	--IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
    --    DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TR_D_Un_Unit_F_dtRegStartDate'

	-- Insérer la modification dans le suivi des modifications
	-- -------------------------------------------------------

	DECLARE @Now datetime = GetDate()
		,	@ConventionID int = 0
		,	@vcNom_Utilisateur sysname = dbo.getusercontext(),
			@iID_Action int = (SELECT LogActionID FROM CRQ_LogAction WHERE LogActionShortName = 'I')
		,	@RecSep CHAR(1) = CHAR(30)
		,	@CrLf CHAR(2) = CHAR(13) + CHAR(10)
		,	@UnitID int
		,	@ModalID int
		,	@InForceDate datetime
		,	@ConnectID int = 2
		,	@ExecResult int = 0

	DECLARE @Count int = (SELECT COUNT(*) FROM inserted)

	SET @UnitID = @Id_Unit - @Count
	WHILE (@UnitID < @Id_Unit) BEGIN
		SET @UnitID = @UnitID + 1

		SELECT @ConventionID = ConventionID, @ModalID = ModalID, @InForceDate = InForceDate
		  FROM ProAcces.Un_Unit WHERE UnitID = @UnitID

		EXECUTE @ExecResult = SP_IU_UN_UnitModalHistory @ConnectID, 0, @UnitID, @ModalID, @Now
		--IF @iExecResult <= 0 
		--	RaisError -3

		-- Appelle de la procédure stockée qui gère les enregistrements 100, 200, et 400 de la convention du groupe d'unités.
		IF @InForceDate > 0 BEGIN
			EXECUTE @ExecResult = dbo.TT_UN_CESPOfConventions 2, 0, 0, @ConventionID
			--IF @iExecResult <= 0 
			--	RaisError --7
		END
	END

	INSERT INTO dbo.Mo_Log (ConnectID, LogTableName, LogCodeID, LogActionID, LogTime, LogText)
		SELECT 2, 'Un_Unit', New.UnitID, 'I', @Now,
				LogText = 
					IsNull((Select ColumnDesc From CRQ_ColumnDesc Where TableName = 'Un_Unit' And ColumnName = 'SignatureDate'), 'SignatureDate') + ': (' +
						CASE WHEN IsNull(New.SignatureDate, 0) = 0 THEN ''
							 ELSE CONVERT(CHAR(10), New.SignatureDate, 20)
						END + 
						')' + @CrLf +
					IsNull((Select ColumnDesc From CRQ_ColumnDesc Where TableName = 'Un_Unit' And ColumnName = 'InForceDate'), 'InForceDate') + ': (' +
						CONVERT(CHAR(10), New.InForceDate, 20) + 
						')' + @CrLf + 
					IsNull((Select ColumnDesc From CRQ_ColumnDesc Where TableName = 'Un_Unit' And ColumnName = 'ModalID'), 'ModalID') + ': (' +
						(	Select CONVERT(CHAR(10), M.ModalDate, 20) + ' / ' + 
								   CASE M.PmtByYearID WHEN 1 THEN CASE WHEN M.PmtQty = 1 THEN 'Unique' ELSE 'Annuel' END
													  WHEN 2 THEN 'Semi-annuel'
													  WHEN 4 THEN 'Trimestriel'
													  WHEN 12 THEN 'Mensuel'
								   END + CASE WHEN M.PmtByYearID = 1 AND M.PmtQty = 1 THEN '' ELSE ' / ' + 
								   LTrim(Str(M.PmtQty / M.PmtByYearID, 3, 0)) + CASE WHEN M.PmtQty / M.PmtByYearID = 1 THEN ' an' ELSE ' ans' END END
							From ProAcces.Un_Modal M Where M.ModalID = New.ModalID
						) + 
						')' + @CrLf +
					+ 
					IsNull((Select ColumnDesc From CRQ_ColumnDesc Where TableName = 'Un_Unit' And ColumnName = 'UnitQty'), 'UnitQty') + ': (' +
						LTrim(Str(New.UnitQty, 10, 3)) + 
						')' + @CrLf +
					+ 
					IsNull((Select ColumnDesc From CRQ_ColumnDesc Where TableName = 'Un_Unit' And ColumnName = 'WantSubscriberInsurance'), 'WantSubscriberInsurance') + ': (' +
						CASE New.WantSubscriberInsurance WHEN 0 THEN 'Non' ELSE 'Oui' END + 
						')' + @CrLf +
					+ 
					IsNull((Select ColumnDesc From CRQ_ColumnDesc Where TableName = 'Un_Unit' And ColumnName = 'RepID'), 'RepID') + ': (' +
						CASE WHEN IsNull(New.RepID, 0) = 0 THEN ''
							 ELSE ISNULL((Select LastName + ', ' + FirstName From ProAcces.Mo_Human Where HumanID = New.RepID), '')
						END + 
						')' + @CrLf +
					IsNull((Select ColumnDesc From CRQ_ColumnDesc Where TableName = 'Un_Unit' And ColumnName = 'SaleSourceID'), 'SaleSourceID') + ': (' +
						CASE WHEN IsNull(New.SaleSourceID, 0) = 0 THEN ''
							 ELSE ISNULL((Select SaleSourceDesc From dbo.Un_SaleSource Where SaleSourceID = New.SaleSourceID), '')
						END  + 
						')' + @CrLf +
					IsNull((Select ColumnDesc From CRQ_ColumnDesc Where TableName = 'Un_Unit' And ColumnName = 'IntReimbDateAdjust'), 'IntReimbDateAdjust') + ': (' +
						CASE WHEN IsNull(New.IntReimbDateAdjust, 0) = 0 THEN ''
							 ELSE CONVERT(CHAR(10), IntReimbDateAdjust, 20)
						END + 
						')' + @CrLf + 
					IsNull((Select ColumnDesc From CRQ_ColumnDesc Where TableName = 'Un_Unit' And ColumnName = 'bActiverSansLettre'), 'bActiverSansLettre') + ': (' +
						CASE ISNULL(New.bActiverSansLettre, 0) WHEN 0 THEN 'Non' ELSE 'Oui' END + 
						')' + @CrLf +
					+ 
					IsNull((Select ColumnDesc From CRQ_ColumnDesc Where TableName = 'Un_Unit' And ColumnName = 'iID_BeneficiaireOriginal'), 'iID_BeneficiaireOriginal') + ': (' +
						CASE WHEN IsNull(New.iID_BeneficiaireOriginal, 0) = 0 THEN ''
							 ELSE ISNULL((Select LastName + ', ' + FirstName From ProAcces.Mo_Human Where HumanID = New.iID_BeneficiaireOriginal), '')
						END + 
						')' + @CrLf +
					IsNull((Select ColumnDesc From CRQ_ColumnDesc Where TableName = 'Un_Unit' And ColumnName = 'iID_RepComActif'), 'iID_RepComActif') + ': (' +
						CASE WHEN IsNull(New.iID_RepComActif, 0) = 0 THEN ''
							 ELSE ISNULL((Select LastName + ', ' + FirstName From ProAcces.Mo_Human Where HumanID = New.iID_RepComActif), '')
						END + 
						')' + @CrLf +
                    IsNull((Select ColumnDesc From CRQ_ColumnDesc Where TableName = 'Un_Unit' And ColumnName = 'TerminatedDate'), 'TerminatedDate') + ': (' +
						CASE WHEN IsNull(New.TerminatedDate, 0) = 0 THEN ''
							 ELSE CONVERT(CHAR(10), TerminatedDate, 20)
						END + 
						')' + @CrLf + 
					''
		FROM	ProAcces.Un_Unit New
		WHERE	New.UnitID > @Id_Unit - @Count

	-- Réactive les triggers

	IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TR_Un_Unit_Ins'
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END
GO
/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: TR_Un_Unit_Upd

Historique des modifications:
        Date		Programmeur		    Description
        ----------  ------------------  -----------------------------------------------------
        2015-08-13	Steeve Picard		Création
        2016-04-18	Pierre-Luc Simard	Création d'un historique des modalités uniquement s'il y a eu un changement
        2016-05-18	Pierre-Luc Simard   Ajout des champs iID_BeneficiaireOriginal et iID_RepComActif
        2016-08-22	Steeve Picard		Ajout du champ «tisprintREEE»
        2018-09-05  Pierre-Luc Simard   Ajout du champ TerminatedDate
		2018-09-27	Maxime Martel		PROD-11034 Journalisation des cotisations supplémentaires erronée
*********************************************************************************************************************/
CREATE TRIGGER [ProAcces].[TR_Un_Unit_Upd] ON [ProAcces].[Un_Unit]
	   INSTEAD OF UPDATE
AS BEGIN
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Start'

	-- *** AVERTISSEMENT *** Ce script doit toujours figurer en tête de trigger

	-- Si la table #DisableTrigger est présente, il se pourrait que le trigger
	-- ne soit pas à exécuter
	IF object_id('tempdb..#DisableTrigger') is null 
		CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))
	ELSE BEGIN
		-- Le trigger doit être retrouvé dans la table pour être ignoré
		IF EXISTS (SELECT 1 FROM #DisableTrigger WHERE OBJECT_NAME(@@PROCID) like vcTriggerName)
		BEGIN
			-- Ne pas faire le trigger
			EXEC dbo.TT_PrintDebugMsg @@PROCID, 'Trigger Ignored'
			RETURN
		END
	END

	-- *** FIN AVERTISSEMENT *** 
	INSERT INTO #DisableTrigger VALUES('TR_Un_Unit_Upd')	
	--INSERT INTO #DisableTrigger VALUES('TUn_Unit')	
	--INSERT INTO #DisableTrigger VALUES('TUn_Unit_State')	
	--INSERT INTO #DisableTrigger VALUES('TR_U_Un_Unit_F_dtRegStartDate')	

	UPDATE TB SET 
		ConventionID = I.ConventionID
		,RepID = NullIf(I.RepID, 0)
		,RepResponsableID = NullIf(I.RepResponsableID, 0)
		,ModalID = I.ModalID
		,UnitQty = ROUND(IsNull(I.UnitQty, 0), 4)
		,WantSubscriberInsurance = I.WantSubscriberInsurance
		,InForceDate = Cast(I.InForceDate as date)
		,IntReimbDateAdjust = I.IntReimbDateAdjust
		,SignatureDate = Cast(I.SignatureDate as date)
		,SaleSourceID = NullIf(I.SaleSourceID, 0)
		,dtFirstDeposit = I.dtFirstDeposit
		,SubscribeAmountAjustment = I.SubscribeAmountAjustment
		,LastDepositForDoc = I.LastDepositForDoc
		,ActivationConnectID = CASE IsActivated WHEN 0 THEN NULL ELSE 2 END
		-- Ce qui suit, est conservé pour le Legacy
		,UnitNo = I.UnitNo
		,iSous_Cat_ID = I.iSous_Cat_ID --(SELECT iSous_Cat_ID FROM deleted WHERE UnitID = I.UnitID)
		-- Ce qui suit, devrait être enlevé
		,IntReimbDate = Cast(I.IntReimbDate as date)
		,PETransactionId = I.PETransactionId
		,bActiverSansLettre = ISNULL(I.bActiverSansLettre, 0)
		,iID_BeneficiaireOriginal = I.iID_BeneficiaireOriginal
		,iID_RepComActif = I.iID_RepComActif
        ,TerminatedDate = I.TerminatedDate
	FROM
		dbo.Un_Unit TB INNER JOIN inserted I ON I.UnitID = TB.UnitID

	--IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
    --    DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TUn_Unit'
	--IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
    --    DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TUn_Unit_State'
	--IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
    --    DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TR_U_Un_Unit_F_dtRegStartDate'

	-- Insérer la modification dans le suivi des modifications
	-- -------------------------------------------------------

	DECLARE @ConventionID int = 0,
			@UnitID int = 0,
			@ModalID int,
			@Old_ModalID int,
			@HistID INT = 0,
			@ConnectID int = 2,
			@ExecResult int,
			@UnitList varchar(1000) = '',
			@Now datetime = GetDate()

	WHILE EXISTS(Select Top 1 * From Inserted Where UnitID > @UnitID) BEGIN
		SELECT @UnitID = Min(UnitID) From Inserted Where UnitID > @UnitID

		SELECT @ModalID = ModalID FROM Inserted WHERE UnitID = @UnitID
		
		SELECT @Old_ModalID = ModalID FROM Deleted WHERE UnitID = @UnitID

		PRINT 'MODAL ' + CAST(@ModalID AS VARCHAR(10)) + ' ' + CAST(@Old_ModalID AS VARCHAR(10))

		IF @ModalID <> @Old_ModalID -- Valide si la modalité a été modifiée
		BEGIN 
			;WITH CTE_Hist as (
					SELECT UnitID, Max(StartDate) as LastDate
					  FROM dbo.Un_UnitModalHistory
					 WHERE UnitID = @UnitID 
						AND StartDate >= CAST(GETDATE() AS DATE)
					 GROUP BY UnitID
				)
			SELECT @HistID = ISNULL(MAX(X.UnitModalHistoryID), 0)
			FROM dbo.Un_UnitModalHistory X JOIN CTE_Hist H ON H.UnitID = X.UnitID And H.LastDate = X.StartDate  

			EXECUTE @ExecResult = SP_IU_UN_UnitModalHistory @ConnectID, @HistID, @UnitID, @ModalID, @Now
		END 
		--IF @iExecResult <= 0 
		--	RaisError -3

		-- La gestion se fera uniquement si la date d'entrée en vigueur a été modifiée ou si le groupe d'unité a été activé
		SELECT @ConventionID = I.ConventionID 
		 FROM Inserted I JOIN Deleted D On D.UnitID = I.UnitID 
		WHERE I.UnitID = @UnitID And (I.InForceDate <> D.InForceDate OR I.IsActivated <> D.IsActivated)
		
		-- Appelle de la procédure stockée qui gère les enregistrements 100, 200, et 400 de la convention du groupe d'unités.
		IF @ConventionID > 0 BEGIN
			-- Mettre à jour l'état des prévalidations et les CESRequest de la convention
			EXEC dbo.psCONV_EnregistrerPrevalidationPCEE @ConnectID, @ConventionID, NULL, NULL, NULL

			EXEC dbo.TT_PrintDebugMsg @@ProcID, 'TT_UN_CESPOfConventions'
			EXECUTE dbo.TT_UN_CESPOfConventions 2, 0, 0, @ConventionID
		END
	END

	--EXECUTE @ExecResult = dbo.TT_UN_ConventionAndUnitStateForUnit @UnitList

	DECLARE @RecSep CHAR(1) = CHAR(30)
		,	@CrLf CHAR(2) = CHAR(13) + CHAR(10)
		,	@ActionID int = (SELECT LogActionID FROM CRQ_LogAction WHERE LogActionShortName = 'U')

	INSERT INTO dbo.Mo_Log (ConnectID, LogTableName, LogCodeID, LogActionID, LogTime, LogText)
		SELECT 2, 'Un_Unit', New.UnitID, 'U', @Now,
				LogText = 
					CASE WHEN IsNull(Old.SignatureDate, 0) = IsNull(New.SignatureDate, 0) THEN ''
						 ELSE IsNull((Select ColumnDesc From CRQ_ColumnDesc Where TableName = 'Un_Unit' And ColumnName = 'SignatureDate'), 'SignatureDate') + ': (' + 
								CONVERT(CHAR(10), Old.SignatureDate, 20) + 
							  ') -> (' + 
								CONVERT(CHAR(10), New.SignatureDate, 20) + 
							  ')' + @CrLf
					END + 
					CASE WHEN Old.InForceDate = New.InForceDate THEN ''
						 ELSE IsNull((Select ColumnDesc From CRQ_ColumnDesc Where TableName = 'Un_Unit' And ColumnName = 'InForceDate'), 'InForceDate') + ': (' + 
									CONVERT(CHAR(10), Old.InForceDate, 20) + 
								') -> (' + 
									CONVERT(CHAR(10), New.InForceDate, 20) + 
								')' + @CrLf
					END + 
					CASE WHEN Old.ModalID = New.ModalID THEN ''
						 ELSE IsNull((Select ColumnDesc From CRQ_ColumnDesc Where TableName = 'Un_Unit' And ColumnName = 'ModalID'), 'ModalID') + ': (' + 
							  (Select CONVERT(CHAR(10), M.ModalDate, 20) + ' / ' + 
									  CASE M.PmtByYearID WHEN 1 THEN CASE WHEN M.PmtQty = 1 THEN 'Unique' ELSE 'Annuel' END
														 WHEN 2 THEN 'Semi-annuel'
														 WHEN 4 THEN 'Trimestriel'
														 WHEN 12 THEN 'Mensuel'
									  END + CASE WHEN M.PmtByYearID = 1 AND M.PmtQty = 1 THEN '' ELSE ' / ' + 
									  LTrim(Str(M.PmtQty / M.PmtByYearID, 3, 0)) + CASE WHEN M.PmtQty / M.PmtByYearID = 1 THEN ' an' ELSE ' ans' END END
								From ProAcces.Un_Modal M Where M.ModalID = Old.ModalID) +
							  ') -> (' + 
							  (Select CONVERT(CHAR(10), M.ModalDate, 20) + ' / ' + 
									  CASE M.PmtByYearID WHEN 1 THEN CASE WHEN M.PmtQty = 1 THEN 'Unique' ELSE 'Annuel' END
														 WHEN 2 THEN 'Semi-annuel'
														 WHEN 4 THEN 'Trimestriel'
														 WHEN 12 THEN 'Mensuel'
									   END + CASE WHEN M.PmtByYearID = 1 AND M.PmtQty = 1 THEN '' ELSE ' / ' + 
									   LTrim(Str(M.PmtQty / M.PmtByYearID, 3, 0)) + CASE WHEN M.PmtQty / M.PmtByYearID = 1 THEN ' an' ELSE ' ans' END END
								From ProAcces.Un_Modal M Where M.ModalID = New.ModalID) +
							  ')' + @CrLf
					END + 
					CASE WHEN Old.UnitQty = New.UnitQty THEN ''
						 ELSE IsNull((Select ColumnDesc From CRQ_ColumnDesc Where TableName = 'Un_Unit' And ColumnName = 'UnitQty'), 'UnitQty') + ': (' + 
								LTrim(Str(Old.UnitQty, 10, 3)) + 
							  ') -> (' + 
								LTrim(Str(New.UnitQty, 10, 3)) + 
							  ')' + @CrLf
					END + 
					CASE WHEN Old.WantSubscriberInsurance = New.WantSubscriberInsurance THEN ''
						 ELSE IsNull((Select ColumnDesc From CRQ_ColumnDesc Where TableName = 'Un_Unit' And ColumnName = 'WantSubscriberInsurance'), 'WantSubscriberInsurance') + ': (' + 
								CASE Old.WantSubscriberInsurance WHEN 0 THEN 'Non' ELSE 'Oui' END + 
							  ') -> (' + 
								CASE New.WantSubscriberInsurance WHEN 0 THEN 'Non' ELSE 'Oui' END + 
							  ')' + @CrLf
					END + 
					CASE WHEN IsNull(Old.RepID, 0) = IsNull(New.RepID, 0) THEN ''
						 ELSE IsNull((Select ColumnDesc From CRQ_ColumnDesc Where TableName = 'Un_Unit' And ColumnName = 'RepID'), 'RepID') + ': (' + 
								ISNULL((Select LastName + ', ' + FirstName From ProAcces.Mo_Human Where HumanID = Old.RepID), '')  + 
							  ') -> (' + 
								ISNULL((Select LastName + ', ' + FirstName From ProAcces.Mo_Human Where HumanID = New.RepID), '')  + 
							  ')' + @CrLf
					END + 
					CASE WHEN IsNull(Old.SaleSourceID, 0) = IsNull(New.SaleSourceID, 0) THEN ''
						 ELSE IsNull((Select ColumnDesc From CRQ_ColumnDesc Where TableName = 'Un_Unit' And ColumnName = 'SaleSourceID'), 'SaleSourceID') + ': (' + 
								ISNULL((Select SaleSourceDesc From dbo.Un_SaleSource Where SaleSourceID = Old.SaleSourceID), '')  + 
							  ') -> (' + 
								ISNULL((Select SaleSourceDesc From dbo.Un_SaleSource Where SaleSourceID = New.SaleSourceID), '')  + 
							  ')' + @CrLf
					END + 
					CASE WHEN IsNull(Old.IntReimbDateAdjust, 0) = IsNull(New.IntReimbDateAdjust, 0) THEN ''
						 ELSE IsNull((Select ColumnDesc From CRQ_ColumnDesc Where TableName = 'Un_Unit' And ColumnName = 'IntReimbDateAdjust'), 'IntReimbDateAdjust') + ': (' + 
								CASE WHEN Old.IntReimbDateAdjust IS NULL THEN '' ELSE CONVERT(CHAR(10), Old.IntReimbDateAdjust, 20) END + 
							  ') -> (' + 
								CASE WHEN New.IntReimbDateAdjust IS NULL THEN '' ELSE CONVERT(CHAR(10), New.IntReimbDateAdjust, 20) END + 
							  ')' + @CrLf
					END + 
					CASE WHEN ISNULL(Old.bActiverSansLettre, 0) = ISNULL(New.bActiverSansLettre, 0) THEN ''
						 ELSE IsNull((Select ColumnDesc From CRQ_ColumnDesc Where TableName = 'Un_Unit' And ColumnName = 'bActiverSansLettre'), 'bActiverSansLettre') + ': (' + 
								CASE ISNULL(Old.bActiverSansLettre, 0) WHEN 0 THEN 'Non' ELSE 'Oui' END + 
							  ') -> (' + 
								CASE ISNULL(New.bActiverSansLettre, 0) WHEN 0 THEN 'Non' ELSE 'Oui' END + 
							  ')' + @CrLf
					END + 
					CASE WHEN IsNull(Old.iID_BeneficiaireOriginal, 0) = IsNull(New.iID_BeneficiaireOriginal, 0) THEN ''
						 ELSE IsNull((Select ColumnDesc From CRQ_ColumnDesc Where TableName = 'Un_Unit' And ColumnName = 'iID_BeneficiaireOriginal'), 'iID_BeneficiaireOriginal') + ': (' + 
								ISNULL((Select LastName + ', ' + FirstName From ProAcces.Mo_Human Where HumanID = Old.iID_BeneficiaireOriginal), '')  + 
							  ') -> (' + 
								ISNULL((Select LastName + ', ' + FirstName From ProAcces.Mo_Human Where HumanID = New.iID_BeneficiaireOriginal), '')  + 
							  ')' + @CrLf
					END + 
					CASE WHEN IsNull(Old.iID_RepComActif, 0) = IsNull(New.iID_RepComActif, 0) THEN ''
						 ELSE IsNull((Select ColumnDesc From CRQ_ColumnDesc Where TableName = 'Un_Unit' And ColumnName = 'iID_RepComActif'), 'iID_RepComActif') + ': (' + 
								ISNULL((Select LastName + ', ' + FirstName From ProAcces.Mo_Human Where HumanID = Old.iID_RepComActif), '')  + 
							  ') -> (' + 
								ISNULL((Select LastName + ', ' + FirstName From ProAcces.Mo_Human Where HumanID = New.iID_RepComActif), '')  + 
							  ')' + @CrLf
					END + 
                    CASE WHEN ISNULL(Old.TerminatedDate, 0) = ISNULL(New.TerminatedDate, 0) THEN ''
						 ELSE IsNull((Select ColumnDesc From CRQ_ColumnDesc Where TableName = 'Un_Unit' And ColumnName = 'TerminatedDate'), 'TerminatedDate') + ': (' + 
								CASE WHEN Old.TerminatedDate IS NULL THEN '' ELSE CONVERT(CHAR(10), Old.TerminatedDate, 20) END + 
							  ') -> (' + 
								CASE WHEN New.TerminatedDate IS NULL THEN '' ELSE CONVERT(CHAR(10), New.TerminatedDate, 20) END + 
							  ')' + @CrLf
  					END + 
				''
		FROM	inserted New
				JOIN deleted Old ON Old.ConventionID = New.ConventionID
			WHERE IsNull(New.SignatureDate,0) <> IsNull(Old.SignatureDate, 0)
			OR New.InForceDate <> Old.InForceDate
			OR IsNull(New.ModalID,0) <> IsNull(Old.ModalID, 0)
			OR New.UnitQty <> Old.UnitQty 
			OR New.WantSubscriberInsurance <> Old.WantSubscriberInsurance 
			OR IsNull(New.RepID, 0) <> IsNull(Old.RepID, 0) 
			OR IsNull(New.SaleSourceID, 0) <> IsNull(Old.SaleSourceID, 0)
			OR IsNull(New.IntReimbDateAdjust, 0) <> IsNull(Old.IntReimbDateAdjust, 0)
			OR ISNULL(New.bActiverSansLettre, 0) <> ISNULL(Old.bActiverSansLettre, 0)
			OR IsNull(New.iID_BeneficiaireOriginal, 0) <> IsNull(Old.iID_BeneficiaireOriginal, 0)
			OR ISNULL(New.iID_RepComActif, 0) <> ISNULL(Old.iID_RepComActif, 0)
            OR ISNULL(New.TerminatedDate, 0) <> ISNULL(Old.TerminatedDate, 0)
			
	-- Réactive les triggers

	IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TR_Un_Unit_Upd'
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END
GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Vue réprsentant l''ancienne table dbo.Un_Unit qui a été recréée dans le schema ProAcces', @level0type = N'SCHEMA', @level0name = N'ProAcces', @level1type = N'VIEW', @level1name = N'Un_Unit';

