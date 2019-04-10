/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_BenefAnnualMaxCeiling
Description         :	Cette procédure retourne les valeurs des plafond annuel pour un bénéficiaire
Valeurs de retours  :	Dataset de données
Note                :			
						2004-05-27 	Bruno Lapointe		Création
	ADX0001114	IA	2006-11-20	Alain Quirion		Gestion des deux périodes de calcul de date estimée de RI (FN_UN_EstimatedIntReimbDate)
	ADX0001314	IA	2007-06-15	Bruno Lapointe		Ajout des colonnes fCESP et fCIREE
	ADX0002627	BR	2007-09-10	Bruno Lapointe		Bogue : Plus d'une ligne par convention
	ADX0002628	BR	2007-09-10	Bruno Lapointe		Bogue : Tennait pas compte du théoric quand le montant du réel pour l'année était supérieur au montant théoric de l'année
					2018-09-11	Maxime Martel		JIRA MP-699 Ajout de OpertypeID COU
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_BenefAnnualMaxCeiling] (
	@BeneficiaryID  INTEGER) -- ID Unique du bénéficiaire
AS 
BEGIN
	DECLARE 
		@UnitID INTEGER,
		@InForceDate DATETIME,
		@IResultID INTEGER,
		@YearQtyOfMaxYearCotisation INTEGER,
		@InsertYear INTEGER,
		@AutomaticDepositUnitID INTEGER,
		@BreakingUnitID INTEGER,
		@ConventionID INTEGER, 
		@ConventionNo VARCHAR(75), 
		@SubscriberID INTEGER, 
		@IYear INTEGER,
		@PaymentDay INTEGER,
		@UnitQty MONEY,    
		@PmtRate DECIMAL(10,4),   
		@PmtByYearID INTEGER,
		@PmtQty INTEGER,   
		@FromDate  DATETIME,
		@ToDate DATETIME,
		@StartDate DATETIME,
		@EndDate DATETIME,
		@EstimatedAmount MONEY,
		@IntReimbDate DATETIME, 
		@TerminatedDate DATETIME,
		@LastDepositDate DATETIME,      
		@YearDateStart DATETIME,
		@YearDateEnd DATETIME,
		@PlanTypeID VARCHAR(3),
		@SumEstimatedAmount MONEY,
		@SubsAmount MONEY,
		@Today DATETIME
		
	SET @Today = dbo.FN_CRQ_DateNoTime(GETDATE())

	SELECT 
		@YearQtyOfMaxYearCotisation = YearQtyOfMaxYearCotisation
	FROM Un_Def
	
	SET @IResultID = 1       

	--Table temporaire sur les années de paiement d'un group d'unités
	CREATE TABLE #Year (
		UnitID        INTEGER,
		IYear         INTEGER,
		YearDateStart DATETIME,
		YearDateEnd   DATETIME
	)    

	DECLARE YearCursor CURSOR FOR
		SELECT 
			U.UnitID,
			U.InforceDate,
			U.IntReimbDate,
			U.TerminatedDate,
			LastDepositDate =
				CASE 
					WHEN PlanTypeID = 'COL' THEN dbo.fn_Un_GetLastDepositDate(
																M.PmtByYearID,   
																C.FirstPmtDate,
																U.InForceDate,
																M.PmtQty)
				ELSE dbo.fn_Un_EstimatedIntReimbDate(
							M.PmtByYearID,
							M.PmtQty,
							M.BenefAgeOnBegining,
							U.InForceDate,
							P.IntReimbAge,
							U.IntReimbDateAdjust)
				END 
		FROM dbo.Un_Unit U
		JOIN dbo.Un_Convention C ON (C.ConventionID = U.ConventionID)
		JOIN Un_Modal M ON (M.ModalID = U.ModalID)
		JOIN Un_Plan P ON (P.PlanID = M.PlanID)
		WHERE (C.BeneficiaryID = @BeneficiaryID)
		  AND (U.TerminatedDate IS NULL)

	OPEN YearCursor

	FETCH NEXT FROM YearCursor INTO
		@UnitID,
		@InForceDate,
		@IntReimbDate, 
		@TerminatedDate,
		@LastDepositDate      

	WHILE (@@FETCH_STATUS = 0) AND (@IResultID > 0)
	BEGIN
		SET @InsertYear = YEAR(@InForceDate)
		SET @YearDateEnd = @InsertYear
		WHILE (@InsertYear < YEAR(DATEADD(YEAR, @YearQtyOfMaxYearCotisation, @InForceDate)))
		BEGIN
			IF (@InsertYear = YEAR(GetDate())) 
				SET @YearDateStart = dbo.fn_Mo_DateNoTime(GetDate())
			ELSE IF (@InsertYear = YEAR(@InForceDate))
				SET @YearDateStart = @InForceDate
			ELSE        
				SET @YearDateStart = CAST(CAST(@InsertYear AS VARCHAR) + '-01-01' AS DATETIME)

			IF (@InsertYear = YEAR(@LastDepositDate))
			OR (@InsertYear = YEAR(@TerminatedDate)) 
			OR (@InsertYear = YEAR(@IntReimbDate)) 
			BEGIN
				IF ((@TerminatedDate IS NULL) AND (@IntReimbDate IS NULL))
					SET @YearDateEnd = @LastDepositDate
				ELSE 
				BEGIN
					SET @YearDateEnd = @LastDepositDate
					IF ((NOT @TerminatedDate IS NULL) AND @YearDateEnd > @TerminatedDate)
						SET @YearDateEnd = @TerminatedDate
					IF ((NOT @IntReimbDate IS NULL) AND @YearDateEnd > @IntReimbDate)
						SET @YearDateEnd = @IntReimbDate
				END
			END
			ELSE 
				SET @YearDateEnd = CAST(CAST(@InsertYear AS VARCHAR) + '-12-31' AS DATETIME)  
      
			INSERT INTO #Year (
				UnitID,
				IYear,
				YearDateStart,
				YearDateEnd )
			VALUES (
				@UnitID,
				@InsertYear,
				@YearDateStart,
				@YearDateEnd)
			IF (@@ERROR <> 0)
			SET @IResultID = -1       
			SET @InsertYear = (@InsertYear + 1)      
		END

		FETCH NEXT FROM YearCursor INTO
			@UnitID,
			@InForceDate,
			@IntReimbDate, 
			@TerminatedDate,
			@LastDepositDate      

	END
	CLOSE YearCursor
	DEALLOCATE YearCursor

	--Table temporaire sur les arrêts de paiement d'un groupe d'unités 
	SELECT 
		U.UnitID,
		C.ConventionID,
		B.BreakingStartDate,
		dbo.fn_Mo_IsDateNull(B.BreakingEndDate)AS BreakingEndDate
	INTO #Breaking
	FROM Un_Breaking B
	JOIN dbo.Un_Convention C ON (C.ConventionID = B.ConventionID)
	JOIN dbo.Un_Unit U ON (U.ConventionID = B.ConventionID)
	WHERE (C.BeneficiaryID = @BeneficiaryID)
	  AND (NOT B.BreakingEndDate IS NULL)
	UNION
	SELECT 
		U.UnitID,
		C.ConventionID,
		H.StartDate as BreakingStartDate,
		dbo.fn_Mo_IsDateNull(H.EndDate)AS BreakingEndDate
	FROM Un_UnitHoldPayment H
	JOIN dbo.Un_Unit U ON (U.UnitID = H.UnitID)
	JOIN dbo.Un_Convention C ON (C.ConventionID = U.ConventionID)
	WHERE (C.BeneficiaryID = @BeneficiaryID)
	  AND (NOT H.EndDate IS NULL)

	--Table temporaire sur la somme de l'horaire de prélèvement automatique d'un groupe d'unités 
	SELECT
		A.UnitID,
		Y.IYear,
		A.StartDate,
		EndDate = 
			CASE 
				WHEN dbo.fn_Mo_IsDateNull(A.EndDate) IS NULL THEN CAST(CAST(Y.IYear AS VARCHAR) + '-12-31' AS DATETIME)
			ELSE dbo.fn_Mo_IsDateNull(A.EndDate)
			END,
		AutomaticAmount =
			CASE 
				WHEN (Y.IYear = YEAR(A.StartDate)) AND ((dbo.fn_Mo_IsDateNull(A.EndDate) IS NULL) OR (Y.IYear < YEAR(A.EndDate))) THEN
					dbo.fn_Un_NbrAutoDepositBetweenTwoDate( 
						A.FirstAutomaticDepositDate,
						A.FirstAutomaticDepositDate, 
						CAST(CAST(Y.IYear AS VARCHAR) + '-12-31' AS DATETIME),
						A.TimeUnit,
						A.TimeUnitLap,
						C.ConventionID) * A.CotisationFee
				WHEN (Y.IYear > YEAR(A.StartDate)) AND ((dbo.fn_Mo_IsDateNull(A.EndDate) IS NULL) OR (Y.IYear < YEAR(A.EndDate))) THEN
					dbo.fn_Un_NbrAutoDepositBetweenTwoDate( 
						A.FirstAutomaticDepositDate,
						CAST(CAST(Y.IYear AS VARCHAR) + '-01-01' AS DATETIME),
						CAST(CAST(Y.IYear AS VARCHAR) + '-12-31' AS DATETIME),
						A.TimeUnit,
						A.TimeUnitLap,
						C.ConventionID) * A.CotisationFee
				WHEN (Y.IYear = YEAR(A.StartDate)) AND (Y.IYear = YEAR(A.EndDate)) THEN
					dbo.fn_Un_NbrAutoDepositBetweenTwoDate( 
						A.FirstAutomaticDepositDate,
						A.FirstAutomaticDepositDate,
						dbo.fn_Mo_IsDateNull(A.EndDate),
						A.TimeUnit,
						A.TimeUnitLap,
						C.ConventionID) * A.CotisationFee
			ELSE
				dbo.fn_Un_NbrAutoDepositBetweenTwoDate( 
					A.FirstAutomaticDepositDate,
					CAST(CAST(Y.IYear AS VARCHAR) + '-01-01' AS DATETIME),
					dbo.fn_Mo_IsDateNull(A.EndDate),
					A.TimeUnit,
					A.TimeUnitLap,
					C.ConventionID) * A.CotisationFee
			END
	INTO #AutomaticDeposit 
	FROM Un_AutomaticDeposit A
	JOIN dbo.Un_Unit U ON (U.UnitID = A.UnitID)
	JOIN dbo.Un_Convention C ON (C.ConventionID = U.ConventionID)
	JOIN #Year Y ON ((Y.UnitID = A.UnitID) 
					 AND ((Y.IYear = YEAR(A.StartDate)) 
						OR (Y.IYear = YEAR(A.EndDate)) 
						OR ((Y.IYear >= YEAR(A.StartDate)) AND ((dbo.fn_Mo_IsDateNull(A.EndDate) IS NULL) OR (Y.IYear <= YEAR(A.EndDate))))))
	WHERE (C.BeneficiaryID = @BeneficiaryID)

	--Table temporaire sur le calcul des montants théorique pour une année 
	CREATE TABLE #Estimated (
		UnitID          INTEGER,
		ConventionID    INTEGER,
		SubscriberID    INTEGER,
		IYear           INTEGER,
		ConventionNo    VARCHAR(75), 
		InforceDate     DATETIME,
		PlanTypeID      VARCHAR(3),
		EstimatedAmount MONEY,
--		DepositAmount   MONEY,
		SubsAmount      MONEY,
		YearDateStart   DATETIME,
		YearDateEnd     DATETIME,   
		PaymentDay      INTEGER,
		UnitQty         MONEY,    
		PmtRate         INTEGER,   
		PmtByYearID     SMALLINT,
		PmtQty          INTEGER
	)

	--Curseur contenant l'information nécessaire pour faire le calcul des montants théorique pour une année 
	DECLARE EstimatedCursor CURSOR FOR
		SELECT 
			U.UnitID,
			C.ConventionID, 
			C.ConventionNo, 
			C.SubscriberID, 
			U.InforceDate,
			Y.IYear,
			PaymentDay = DAY(C.FirstPmtDate),
			U.UnitQty,    
			M.PmtRate,   
			M.PmtByYearID,
			M.PmtQty,
			P.PlanTypeID,   
			FromDate = Y.YearDateStart,
			ToDate = Y.YearDateEnd,
			AutomaticDepositUnitID = ISNULL(A.UnitID , 0),
			BreakingUnitID = ISNULL(B.UnitID , 0)   
		FROM dbo.Un_Unit U
		JOIN dbo.Un_Convention C ON (C.ConventionID = U.ConventionID)
		JOIN Un_Modal M ON (M.ModalID = U.ModalID)
		JOIN Un_Plan P ON (P.PlanID = M.PlanID)
		JOIN #Year Y ON (Y.UnitID = U.UnitID)
		LEFT JOIN (
			SELECT DISTINCT 
				UnitID,
				IYear
			FROM #AutomaticDeposit 
			)A ON ((A.UnitID = U.UnitID) AND (A.IYear = Y.IYear))
		LEFT JOIN (
			SELECT DISTINCT
				UnitID,
				ConventionID
			FROM #Breaking 
			)B ON ((B.UnitID = U.UnitID) /*AND (B.IYear = Y.IYear)*/)
		WHERE (C.BeneficiaryID = @BeneficiaryID)

	OPEN EstimatedCursor
 
	FETCH NEXT FROM EstimatedCursor INTO
		@UnitID,
		@ConventionID, 
		@ConventionNo, 
		@SubscriberID, 
		@InforceDate,
		@IYear,
		@PaymentDay,
		@UnitQty,    
		@PmtRate,   
		@PmtByYearID,
		@PmtQty, 
		@PlanTypeID,   
		@FromDate,
		@ToDate,
		@AutomaticDepositUnitID,
		@BreakingUnitID

	SET @IResultID = 1

	WHILE (@@FETCH_STATUS = 0) AND (@IResultID > 0)
	BEGIN
		SET @StartDate  = @FromDate
		SET @EndDate         = @FromDate
		SET @EstimatedAmount = 0
		SET @SubsAmount      = 0
  
		IF (@PlanTypeID = 'COL') AND (@IYear >= YEAR(GetDate()))
		BEGIN
			IF (@AutomaticDepositUnitID = 0) AND (@BreakingUnitID = 0) 
				SET @EstimatedAmount = dbo.fn_Un_EstimatedCotisationAndFee (
													@FromDate,
													@ToDate,
													@PaymentDay,
													@UnitQty, 
													@PmtRate,
													@PmtByYearID,
													@PmtQty,
													@InforceDate)
			ELSE
			BEGIN
				WHILE YEAR(@StartDate) = @IYear  
				BEGIN
					IF NOT EXISTS (
						SELECT 
							StartDate
						FROM #AutomaticDeposit
						WHERE (UnitID = @AutomaticDepositUnitID)
						  AND (@IYear = IYear)
						  AND ((@StartDate BETWEEN StartDate AND EndDate)
							 OR ((@StartDate >= StartDate) AND (EndDate IS NULL)))
						UNION 
						SELECT 
							StartDate = BreakingStartDate
						FROM #Breaking
						WHERE (UnitID = @BreakingUnitID)        
						  AND ((@StartDate BETWEEN BreakingStartDate AND BreakingEndDate)))
					BEGIN
						SET @EndDate = @StartDate
						WHILE (YEAR(@EndDate+1) = @IYear)
						  AND (NOT EXISTS (
								SELECT 
									EndDate = dbo.fn_Mo_IsDateNull(EndDate)
								FROM #AutomaticDeposit
								WHERE (UnitID = @AutomaticDepositUnitID)
								  AND (@IYear = IYear)
								  AND (((@EndDate+1) BETWEEN StartDate AND EndDate)
									 OR (((@EndDate+1) > = StartDate) AND (EndDate IS NULL)))
								UNION 
								SELECT 
									EndDate = dbo.fn_Mo_IsDateNull(BreakingEndDate)
								FROM #Breaking
								WHERE (UnitID = @BreakingUnitID)        
								  AND ((@EndDate+1) BETWEEN BreakingStartDate AND BreakingEndDate)))
							SET @EndDate = @EndDate + 1
	        
						SET @EstimatedAmount = @EstimatedAmount + 
									dbo.fn_Un_EstimatedCotisationAndFee (
										@StartDate,
										@EndDate,
										@PaymentDay,
										@UnitQty, 
										@PmtRate,
										@PmtByYearID,
										@PmtQty,
										@InforceDate)
						SET @StartDate = @EndDate + 1  
					END
					ELSE
						SET @StartDate = @StartDate + 1
				END
			END
		END
		ELSE 
		BEGIN
			IF (@AutomaticDepositUnitID <> 0)
				SELECT
					@SubsAmount = SUM((dbo.fn_Un_NbrAutoDepositBetweenTwoDate( 
												A.FirstAutomaticDepositDate,
												A.FirstAutomaticDepositDate,
												CASE
													WHEN dbo.fn_Mo_IsDateNull(A.EndDate) IS NULL THEN dbo.fn_Un_EstimatedIntReimbDate(
																							M.PmtByYearID,
																							M.PmtQty,
																							M.BenefAgeOnBegining,
																							U.InForceDate,
																							P.IntReimbAge,
																							U.IntReimbDateAdjust)  
												ELSE A.EndDate
												END,
												A.TimeUnit,
												A.TimeUnitLap,
												C.ConventionID) * A.CotisationFee)) 
				FROM Un_AutomaticDeposit A
				JOIN dbo.Un_Unit U ON (U.UnitID = A.UnitID)
				JOIN dbo.Un_Convention C ON (C.ConventionID = U.ConventionID)
				JOIN Un_Modal M ON (M.ModalID = U.ModalID)
				JOIN Un_Plan P ON (P.PlanID = M.PlanID)
				WHERE (U.ConventionID = @ConventionID)
				  AND (A.StartDate < dbo.fn_Un_EstimatedIntReimbDate(
												M.PmtByYearID,
												M.PmtQty,
												M.BenefAgeOnBegining,
												U.InForceDate,
												P.IntReimbAge,
												U.IntReimbDateAdjust))
				GROUP BY C.ConventionID
		END;
   
		INSERT INTO #Estimated (
			UnitID,
			ConventionID,
			SubscriberID,
			IYear,
			ConventionNo, 
			InforceDate,
			PlanTypeID,
			EstimatedAmount,
--			DepositAmount,
			SubsAmount,
			YearDateStart,
			YearDateEnd,
			PaymentDay,
			UnitQty,    
			PmtRate,   
			PmtByYearID,
			PmtQty )
		VALUES (    
			@UnitID,
			@ConventionID,
			@SubscriberID,
			@IYear,
			@ConventionNo, 
			@InforceDate,
			@PlanTypeID,
			@EstimatedAmount,
--			ROUND((@UnitQty * @PmtRate), 2),
			CASE 
				WHEN @PlanTypeID = 'COL' THEN ROUND((@UnitQty * @PmtRate), 2) * @PmtQty
			ELSE @SubsAmount
			END,
			@FromDate,
			@ToDate,                 
			@PaymentDay,
			@UnitQty,    
			@PmtRate,   
			@PmtByYearID,
			@PmtQty )

		IF (@@ERROR <> 0)
			SET @IResultID = -1       

		FETCH NEXT FROM EstimatedCursor INTO
			@UnitID,
			@ConventionID, 
			@ConventionNo, 
			@SubscriberID, 
			@InforceDate,
			@IYear,
			@PaymentDay,
			@UnitQty,    
			@PmtRate,   
			@PmtByYearID,
			@PmtQty,
			@PlanTypeID,   
			@FromDate,
			@ToDate,
			@AutomaticDepositUnitID,
			@BreakingUnitID

	END
	CLOSE EstimatedCursor
	DEALLOCATE EstimatedCursor

	--Table temporaire des retards de paiement par groupe d'unités.
	CREATE TABLE #LatePmt (
		UnitID INT,
		ConventionID INT,
		fLatePmt	MONEY	)

	INSERT INTO #LatePmt
		SELECT
			U.UnitID,
			C.ConventionID,
			fLatePmt = 
				dbo.FN_UN_EstimatedCotisationAndFee (
						U.InForceDate, -- Date de départ
						@Today, -- Date de fin
						DAY(C.FirstPmtDate), -- Jour de paiement        
						U.UnitQty, -- Nombre d'unités  
						M.PmtRate, -- Montant de paiement par unité 
						M.PmtByYearID, -- Nombre de dépôt par année
						M.PmtQty, -- Nombre de dépôt total pour un groupe d'unité       
						U.InForceDate ) -- Date d'entrée en vigueur  
				- ISNULL(SUM(Ct.Cotisation+Ct.Fee),0)
		FROM dbo.Un_Convention C
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
		JOIN Un_Modal M ON M.ModalID = U.ModalID
		LEFT JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
		WHERE C.BeneficiaryID = @BeneficiaryID
			AND Ct.EffectDate <= @Today
		GROUP BY 
			U.UnitID,
			C.ConventionID,
			U.InForceDate,
			C.FirstPmtDate,
			U.UnitQty,
			M.PmtRate,
			M.PmtByYearID,
			M.PmtQty

	SELECT 
		E.UnitID,
		E.ConventionID, 
		E.ConventionNo,
		E.PlanTypeID, 
		E.SubscriberID, 
		SubscriberName = H.LastName + ', '+ H.FirstName,
		E.InforceDate,
		E.IYear,
		E.YearDateStart,
		E.YearDateEnd,
		E.PaymentDay,
		E.UnitQty,    
		E.PmtRate,   
		E.PmtByYearID,
		E.PmtQty,
		SubsAmount = E.SubsAmount,
		EstimatedAmount =
			CASE 
				WHEN (E.PlanTypeID = 'COL') AND (E.IYEAR >= YEAR(GetDate())) THEN
					CASE 
						WHEN (E.IYEAR = YEAR(GetDate())) THEN 
							CASE 
								WHEN /*(ISNULL(V1.CumCotisation, 0) + ISNULL(V1.CumFee, 0))*/ 0 >= (E.EstimatedAmount + ISNULL(A.AutomaticAmount, 0)) THEN (ISNULL(V1.CumCotisation, 0) + ISNULL(V1.CumFee, 0))
							ELSE ((E.EstimatedAmount + ISNULL(A.AutomaticAmount, 0)) + ISNULL(V1.CumCotisation, 0) + ISNULL(V1.CumFee, 0))
							END + ISNULL(LP.fLatePmt,0)  
					ELSE (E.EstimatedAmount + ISNULL(A.AutomaticAmount, 0))
					END
				WHEN ((E.PlanTypeID = 'IND') AND (E.IYEAR >= YEAR(GetDate()))) THEN 
					CASE 
						WHEN (E.IYEAR = YEAR(GetDate())) THEN (ISNULL(V1.CumCotisation, 0) + ISNULL(A.AutomaticAmount, 0))
					ELSE ISNULL(A.AutomaticAmount, 0)
					END
			ELSE ISNULL(V1.CumCotisation, 0) + ISNULL(V1.CumFee, 0)
			END, 
		CumAmount = ISNULL(V1.CumCotisation, 0) + + ISNULL(V1.CumFee, 0),
		CumAutomaticAmount = ISNULL(A.AutomaticAmount, 0),
		TheoricAmount = E.EstimatedAmount,
		fCESP = ISNULL(CE.fCESP,0),
		fCIREE = 0
	INTO #Final
	FROM #Estimated E
	JOIN dbo.Mo_Human H ON (H.HumanID = E.SubscriberID)
	LEFT JOIN (
		--Somme des montant dans cotisation
		SELECT 
			Ct.UnitID,
			IYear = YEAR(Ct.EffectDate), 
			CumFee = SUM(Ct.Fee),
			CumCotisation = SUM(Ct.Cotisation)  
		FROM dbo.Un_Unit U
		JOIN dbo.Un_Convention C ON (C.ConventionID = U.ConventionID)
		JOIN Un_Cotisation Ct ON (Ct.UnitID = U.UnitID)
		JOIN Un_Oper O ON (O.OperID = Ct.OperID)
		WHERE C.BeneficiaryID = @BeneficiaryID
			AND O.OperTypeID IN ('ANN', 'CPA', 'CHQ', 'NSF', 'RET', 'PRD', 'RES', 'COU')
			AND Ct.EffectDate <= @Today
		GROUP BY Ct.UnitID, YEAR(Ct.EffectDate)
		) V1 ON ((V1.UnitID = E.UnitID) AND (V1.IYear = E.IYear)) 
	LEFT JOIN (
		--Somme des prélêvement automatique pour chaque année3    
		SELECT 
			UnitID,
			IYear,
			AutomaticAmount = SUM(AutomaticAmount)
		FROM #AutomaticDeposit 
		GROUP BY UnitID, IYear
		) A ON ((A.UnitID = E.UnitID) AND (A.IYear = E.IYear))
	LEFT JOIN (
		SELECT
			C.ConventionID,
			IYear = YEAR(O.OperDate), 
			fCESP = SUM(CE.fCESG+CE.fACESG)
		FROM dbo.Un_Convention C
		JOIN Un_CESP CE ON CE.ConventionID = C.ConventionID
		JOIN Un_Oper O ON O.OperID = CE.OperID
		WHERE C.BeneficiaryID = @BeneficiaryID
			AND O.OperDate <= @Today
		GROUP BY C.ConventionID, YEAR(O.OperDate)
		) CE ON CE.ConventionID = E.ConventionID AND CE.IYear = E.IYear
	LEFT JOIN #LatePmt LP ON E.UnitID = LP.UnitID AND E.IYear = YEAR(@Today)
	ORDER BY E.IYear, E.ConventionNo

	DECLARE 
		@AmountToDistribute MONEY,
		@CumAmount          MONEY,
		@MaxAmountAllowed   MONEY;  

	DECLARE FinalCursor SCROLL CURSOR FOR
		SELECT 
			F.UnitID,
			F.IYear,
			F.PlanTypeID,
			F.SubsAmount,
			F.EstimatedAmount,
			F.CumAmount
		FROM #Final F

	OPEN FinalCursor

	FETCH LAST FROM FinalCursor INTO
		@UnitID,
		@IYear,
		@PlanTypeID,
		@SubsAmount,
		@EstimatedAmount,
		@CumAmount

	SET @IResultID = 1

	WHILE (@@FETCH_STATUS = 0) AND (@IResultID > 0)
	BEGIN
		IF @SubsAmount > @CumAmount 
			SET @MaxAmountAllowed = @SubsAmount
		ELSE 
			SET @MaxAmountAllowed = @CumAmount

		IF (
			SELECT
				SUM(EstimatedAmount)
			FROM #Final
			WHERE (UnitID = @UnitID)
			GROUP BY UnitID) > @MaxAmountAllowed
		BEGIN
			--Diminution du montant théorique par rapport au trop calculé  
			
			IF @EstimatedAmount >= ((
					SELECT
						SUM(EstimatedAmount)
					FROM #Final
					WHERE (UnitID = @UnitID)
					GROUP BY UnitID) - @MaxAmountAllowed)     
				SET @EstimatedAmount = @EstimatedAmount - ((
					SELECT
						SUM(EstimatedAmount)
					FROM #Final
					WHERE (UnitID = @UnitID)
					GROUP BY UnitID) - @MaxAmountAllowed)
			ELSE 
				SET @EstimatedAmount = 0

			UPDATE #Final SET 
				EstimatedAmount = @EstimatedAmount 
			WHERE ((UnitID = @UnitID) AND (IYear = @IYear))
		END
		ELSE
		BEGIN
			--Répartition des montants pour atteindre le montant souscrit, dans la derniere années 
			SET @AmountToDistribute = @MaxAmountAllowed - (
				SELECT
					SUM(EstimatedAmount)
				FROM #Final
				WHERE (UnitID = @UnitID)
				GROUP BY UnitID) 

			UPDATE #Final SET 
				EstimatedAmount = (@EstimatedAmount + @AmountToDistribute)
			WHERE ((UnitID = @UnitID) AND (IYear = @IYear))
      END
    
		FETCH PRIOR FROM FinalCursor INTO
			@UnitID,
			@IYear,
			@PlanTypeID, 
			@SubsAmount,
			@EstimatedAmount,
			@CumAmount
	END
	CLOSE FinalCursor
	DEALLOCATE FinalCursor

	SELECT 
		F.ConventionID, 
		F.ConventionNo,
		F.PlanTypeID, 
		F.SubscriberID, 
		F.SubscriberName,
		InforceDate = MIN(F.InforceDate),
		F.IYear,
		YearDateStart = MIN(F.YearDateStart),
		YearDateEnd = MAX(F.YearDateEnd),
		F.PaymentDay,
		SubsAmount = SUM(F.SubsAmount),
		EstimatedAmount = SUM(F.EstimatedAmount), 
		CumAmount = SUM(F.CumAmount),
		CumAutomaticAmount = SUM(F.CumAutomaticAmount),
		TheoricAmount = SUM(F.TheoricAmount),
		F.fCESP,
		F.fCIREE,
		LifeCeiling = ISNULL(V.LifeCeiling, 0),
		AnnualCeiling = ISNULL(V.AnnualCeiling, 0)
	FROM #Final F
	LEFT JOIN ( 
		SELECT 
			V.BeneficiaryID,
			B.LifeCeiling,
			B.AnnualCeiling
		FROM Un_BeneficiaryCeilingCfg B
		LEFT JOIN(
			SELECT
				BeneficiaryID = H.HumanID,
				EffectDate = MAX(EffectDate)
			FROM Un_BeneficiaryCeilingCfg B
			JOIN dbo.Mo_Human H ON (H.HumanID = @BeneficiaryID) 
			WHERE (dbo.fn_Mo_DateNoTime(H.BirthDate) >= dbo.fn_Mo_DateNoTime(B.EffectDate)) 
			GROUP BY H.HumanID
			) V ON (V.EffectDate = B.EffectDate)
		) V ON (V.BeneficiaryID = @BeneficiaryID) 
	GROUP BY
		F.ConventionID, 
		F.ConventionNo,
		F.PlanTypeID, 
		F.SubscriberID, 
		F.SubscriberName,
		F.IYear,
		F.PaymentDay,
		F.fCESP,
		F.fCIREE,
		V.LifeCeiling,
		V.AnnualCeiling
	ORDER BY 
		F.IYear,
		F.SubscriberName,
		F.SubscriberID, 
		F.ConventionNo,
		F.ConventionID

	DROP TABLE #Year
	DROP TABLE #AutomaticDeposit
	DROP TABLE #Breaking
	DROP TABLE #Estimated
	DROP TABLE #Final
END