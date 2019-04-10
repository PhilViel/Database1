/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	RP_UN_RepTreatmentTotal
Description         :	Totaux du rapport des commissions
Valeurs de retours  :	Dataset
Note                :	ADX0001206	IA	2007-01-09	Bruno Lapointe		Optimisation.
					2008-01-25	Pierre-Luc Simard	Ajout d'un COALESCE pour accélérer
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_RepTreatmentTotal] (
	@ConnectID INTEGER,
	@RepID INTEGER,
	@RepTreatmentID INTEGER)
AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT

	SET @dtBegin = GETDATE()
	IF @RepID = 0 	
		SET @RepID = NULL

	CREATE TABLE #tRepTot (
		TypeID TINYINT NOT NULL,
		RepTreatmentID INTEGER NOT NULL,
		RepID INTEGER NOT NULL,
		RepTotalFee MONEY NOT NULL,
		RepPeriodAdvance MONEY NOT NULL,
		RepCoveredAdvance MONEY NOT NULL,
		RepCumAdvance MONEY NOT NULL,
		RepPeriodComm MONEY NOT NULL,
		RepFuturComm MONEY NOT NULL,
		RepPeriodBusinessBonus MONEY NOT NULL,
		RepFuturBusinessBonus MONEY NOT NULL,
		RepSweepstakeTot MONEY NOT NULL,
		RepPaidTotal MONEY NOT NULL,
		RepExpensesTotal MONEY NOT NULL,
		CONSTRAINT PK_#tRepTot PRIMARY KEY (TypeID, RepTreatmentID, RepID)
		)

	INSERT INTO #tRepTot
		SELECT 
			TypeID = 1,
			RepTreatmentID,
			RepID,
			RepTotalFee = SUM(TotalFee),
			RepPeriodAdvance = SUM(PeriodAdvance),
			RepCoveredAdvance = SUM(CoverdAdvance),  
			RepCumAdvance = SUM(CumAdvance),
			RepPeriodComm = SUM(PeriodComm),
			RepFuturComm = SUM(FuturComm),
			RepPeriodBusinessBonus = SUM(PeriodBusinessBonus),
			RepFuturBusinessBonus = SUM(FuturBusinessBonus),
			RepSweepstakeTot = SUM(SweepstakeBonusAjust),
			RepPaidTotal = SUM(PaidAmount),
			RepExpensesTotal = SUM(CoverdAdvance)+SUM(PaidAmount)
		FROM Un_Dn_RepTreatment 
		WHERE RepTreatmentID = @RepTreatmentID
			AND RepID = COALESCE(@RepID, RepID)
			-- AND( @RepID = 0
			--	OR @RepID = RepID
			--	)
		GROUP BY 
			RepTreatmentID, 
			RepID
		
	INSERT INTO #tRepTot
		SELECT 
			TypeID = 2,
			C.RepTreatmentID,
			C.RepID,
			RepTotalFee = 0,
			RepPeriodAdvance = 0,
			RepCoveredAdvance = 0,  
			RepCumAdvance = 0,
			RepPeriodComm = 0,
			RepFuturComm = 0,
			RepPeriodBusinessBonus = 0,
			RepFuturBusinessBonus = 0,
			RepSweepstakeTot = SUM(C.RepChargeAmount),
			RepPaidTotal = SUM(C.RepChargeAmount),
	      RepExpensesTotal = SUM(C.RepChargeAmount)
		FROM Un_RepCharge C
		JOIN Un_RepChargeType CT ON CT.RepChargeTypeID = C.RepChargeTypeID
		WHERE C.RepTreatmentID = @RepTreatmentID
			AND RepID = COALESCE(@RepID, RepID)
			-- AND( @RepID = 0
			--	OR @RepID = RepID
			--	)
			AND CT.RepChargeTypeComm <> 0
		GROUP BY 
			C.RepTreatmentID, 
			C.RepID 

	INSERT INTO #tRepTot
		SELECT 
			TypeID = 3,
			C.RepTreatmentID,
			C.RepID,
			RepTotalFee = 0,
			RepPeriodAdvance = 0,
			RepCoveredAdvance = 0,  
			RepCumAdvance = 0,
			RepPeriodComm = 0,
			RepFuturComm = 0,
			RepPeriodBusinessBonus = 0,
			RepFuturBusinessBonus = 0,
			RepSweepstakeTot = SUM(C.RepChargeAmount),
			RepPaidTotal = SUM(C.RepChargeAmount),
	      RepExpensesTotal = 0
		FROM Un_RepCharge C
		JOIN Un_RepChargeType CT ON CT.RepChargeTypeID = C.RepChargeTypeID
		WHERE C.RepTreatmentID = @RepTreatmentID
			AND RepID = COALESCE(@RepID, RepID)
			-- AND( @RepID = 0
			--	OR @RepID = RepID
			--	)
			AND CT.RepChargeTypeComm = 0
		GROUP BY 
			C.RepTreatmentID, 
			C.RepID 

	INSERT INTO #tRepTot
		SELECT
			TypeID = 0,
			RepTreatmentID,
			RepID,
			RepTotalFee = SUM(RepTotalFee),
			RepPeriodAdvance = SUM(RepPeriodAdvance),
			RepCoveredAdvance = SUM(RepCoveredAdvance),  
			RepCumAdvance = SUM(RepCumAdvance),
			RepPeriodComm = SUM(RepPeriodComm),
			RepFuturComm = SUM(RepFuturComm),
			RepPeriodBusinessBonus = SUM(RepPeriodBusinessBonus),
			RepFuturBusinessBonus = SUM(RepFuturBusinessBonus),
			RepSweepstakeTot = SUM(RepSweepstakeTot),
			RepPaidTotal = SUM(RepPaidTotal),
	      RepExpensesTotal = SUM(RepExpensesTotal)
		FROM #tRepTot
		GROUP BY 
			RepTreatmentID, 
			RepID

	INSERT INTO #tRepTot
		SELECT
			TypeID = 0,
			RepTreatmentID,
			RepID = 0,
			RepTotalFee = SUM(RepTotalFee),
			RepPeriodAdvance = SUM(RepPeriodAdvance),
			RepCoveredAdvance = SUM(RepCoveredAdvance),  
			RepCumAdvance = SUM(RepCumAdvance),
			RepPeriodComm = SUM(RepPeriodComm),
			RepFuturComm = SUM(RepFuturComm),
			RepPeriodBusinessBonus = SUM(RepPeriodBusinessBonus),
			RepFuturBusinessBonus = SUM(RepFuturBusinessBonus),
			RepSweepstakeTot = SUM(RepSweepstakeTot),
			RepPaidTotal = SUM(RepPaidTotal),
	      RepExpensesTotal = SUM(RepExpensesTotal)
		FROM #tRepTot
		WHERE TypeID = 0
		GROUP BY 
			RepTreatmentID

	DELETE 
	FROM #tRepTot
	WHERE TypeID <> 0


	SELECT
		VR.RepID,
		VR.RepTotalFee,
		VR.RepPeriodAdvance,
		VR.RepCoveredAdvance,
		VR.RepCumAdvance,
		VR.RepPeriodComm,
		VR.RepFuturComm,
		VR.RepPeriodBusinessBonus,
		VR.RepFuturBusinessBonus,
		VR.RepCoveredAdvance,  
		VR.RepSweepstakeTot,
		VR.RepPaidTotal,
		VR.RepExpensesTotal,
		TotalFee = VT.RepTotalFee,
		PeriodAdvance = VT.RepPeriodAdvance,
		CoveredAdvance = VT.RepCoveredAdvance,
		CumAdvance = VT.RepCumAdvance,
		PeriodComm = VT.RepPeriodComm,
		FuturComm = VT.RepFuturComm,
		PeriodBusinessBonus = VT.RepPeriodBusinessBonus,
		FuturBusinessBonus = VT.RepFuturBusinessBonus,
		CoveredAdvance = VT.RepCoveredAdvance,  
		SweepstakeTot = VT.RepSweepstakeTot,
		PaidTotal = VT.RepPaidTotal,
		ExpensesTotal = VT.RepExpensesTotal
	FROM #tRepTot VR
	JOIN #tRepTot VT ON VT.RepTreatmentID = VR.RepTreatmentID
	WHERE VR.RepID <> 0
		AND VT.RepID = 0

	SET @dtEnd = GETDATE()
	SELECT @siTraceReport = siTraceReport FROM Un_Def

	IF DATEDIFF(SECOND, @dtBegin, @dtEnd) > @siTraceReport
		-- Insère une trace de l'ewxécution si la durée de celle-ci a dépassé le temps minimum défini dans Un_Def.siTraceReport.
		INSERT INTO Un_Trace (
				ConnectID, -- ID de connexion de l’usager
				iType, -- Type de trace (1 = recherche, 2 = rapport)
				fDuration, -- Temps d’exécution de la procédure
				dtStart, -- Date et heure du début de l’exécution.
				dtEnd, -- Date et heure de la fin de l’exécution.
				vcDescription, -- Description de l’exécution (en texte)
				vcStoredProcedure, -- Nom de la procédure stockée
				vcExecutionString ) -- Ligne d’exécution (inclus les paramètres)
			SELECT
				@ConnectID,
				2,
				DATEDIFF(MILLISECOND, @dtBegin, @dtEnd)/1000,
				@dtBegin,
				@dtEnd,
				'Totaux du rapport des commissions',
				'RP_UN_RepTreatmentTotal',
				'EXECUTE RP_UN_RepTreatmentTotal @ConnectID = '+CAST(@ConnectID AS VARCHAR)+
					', @RepTreatmentID = '+CAST(@RepTreatmentID AS VARCHAR)+
					', @RepID = '+CAST(@RepID AS VARCHAR)
END


/*  Sequence de test - par: PLS - 09-05-2008
	exec [dbo].[RP_UN_RepTreatmentTotal] 
	@ConnectID = 1, -- ID de connexion de l'usager
	@RepID = 149653, -- ID du représentant dont on veut la liste, 0 pour Tous, 149653 pour Claude Cossette
	@RepTreatmentID = 282 -- Numéro du traitement voulu
*/
