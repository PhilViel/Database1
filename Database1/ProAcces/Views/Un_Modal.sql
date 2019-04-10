CREATE VIEW [ProAcces].[Un_Modal] AS
	SELECT ModalID, PlanID, ModalDate, PmtByYearID, PmtQty,
		   BenefAgeOnBegining, PmtRate, SubscriberInsuranceRate, FeeByUnit, FeeSplitByUnit,
		   FeeRefundable, BusinessBonusToPay
	FROM dbo.Un_Modal

GO
CREATE TRIGGER [ProAcces].[TR_Un_Modal_Upd] ON [ProAcces].[Un_Modal]
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
			EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Trigger Ignored'
			RETURN
		END
	END

	-- *** FIN AVERTISSEMENT *** 
	INSERT INTO #DisableTrigger VALUES('TR_Un_Modal_Ins')	
	INSERT INTO #DisableTrigger VALUES('TUn_Modal')	
	--INSERT INTO #DisableTrigger VALUES('TUn_Modal_State')	

	UPDATE TB SET
		PlanID = I.PlanID
		,ModalDate = Cast(I.ModalDate as date)
		,PmtByYearID = I.PmtByYearID
		,PmtQty = I.PmtQty
		,BenefAgeOnBegining = I.BenefAgeOnBegining
		,PmtRate = I.PmtRate
		,SubscriberInsuranceRate = I.SubscriberInsuranceRate
		,FeeByUnit = Round(I.FeeByUnit, 2)
		,FeeSplitByUnit = Round(I.FeeSplitByUnit, 2)
		,FeeRefundable = I.FeeRefundable
		,BusinessBonusToPay = I.BusinessBonusToPay
	FROM
		dbo.Un_Modal TB INNER JOIN inserted I ON I.ModalID = TB.ModalID

	IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TUn_Modal'
	--IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
    --    DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TUn_Modal_State'

	IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TR_Un_Modal_Ins'
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END

GO
CREATE TRIGGER [ProAcces].[TR_Un_Modal_Ins] ON [ProAcces].[Un_Modal]
	   INSTEAD OF INSERT
AS BEGIN
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Start'

	SET NoCount ON

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
	INSERT INTO #DisableTrigger VALUES('TR_Un_Modal_Ins')	
	INSERT INTO #DisableTrigger VALUES('TUn_Modal')	
	--INSERT INTO #DisableTrigger VALUES('TUn_Modal_State')	

	INSERT INTO dbo.Un_Modal (
		PlanID
		,ModalDate
		,PmtByYearID
		,PmtQty
		,BenefAgeOnBegining
		,PmtRate
		,SubscriberInsuranceRate
		,FeeByUnit
		,FeeSplitByUnit
		,FeeRefundable
		,BusinessBonusToPay)
	SELECT 
		PlanID
		,Cast(ModalDate as date)
		,PmtByYearID
		,PmtQty
		,BenefAgeOnBegining
		,PmtRate
		,SubscriberInsuranceRate
		,Round(FeeByUnit, 2)
		,Round(FeeSplitByUnit, 2)
		,FeeRefundable
		,BusinessBonusToPay
	FROM inserted

	-- Ce SELECT est obligé et doit être immédiatement après l'insertion afin que Entity Framework puisse recevoir le Id du nouveau record
	SELECT ModalID = IDENT_CURRENT('dbo.Un_Modal')

	IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TUn_Modal'
	--IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
    --    DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TUn_Modal_State'

	IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TR_Un_Modal_Ins'
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END

GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Vue réprsentant l''ancienne table dbo.Un_Modal qui a été recréée dans le schema ProAcces', @level0type = N'SCHEMA', @level0name = N'ProAcces', @level1type = N'VIEW', @level1name = N'Un_Modal';

