/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	VL_UN_BeneficiaryCeilingForUnit
Description         :	Valide que les plafonds de cotisation annuel et à vie ne sont pas dépassés
Valeurs de retours  :	@ReturnValue :
					> 0  : Réussite
					<= 0 : Échec
				
Note                :				
						2004-05-27 	Bruno Lapointe		Création
	ADX000		IA	2006-11-24	Alain Quirion		Modification : Nom de procédure stockée
	ADX0001314	IA	2007-06-15	Bruno Lapointe		Ajout des colonnes fCESP et fCIREE
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[VL_UN_BeneficiaryCeilingForUnit] (
	@BeneficiaryID INTEGER, -- ID Unique du bénéficiaire
	@InForceDate DATETIME, -- Date de vigueur du groupe d'unités
	@ModalID INTEGER, -- ID Unique de la modalité
	@FirstPmtDate DATETIME, -- Date des dépôts de la convention
	@UnitQty MONEY, -- Nombre d'unités
	@PlanID INTEGER, -- ID Unique du plan de la convention
	@TimeUnit1 SMALLINT = NULL, -- Type d'unité temporelle du 1 horaire s'il y a lieu
	@TimeUnitLap1      INTEGER = NULL, -- Nombre d'unité temporelle du 1 horaire s'il y a lieu
	@TimeUnitStart1    DATETIME = NULL, -- Date de début de la période du 1 horaire s'il y a lieu
	@TimeUnitEnd1      DATETIME = NULL, -- Date de fin de la période du 1 horaire s'il y a lieu
	@TimeUnitFirst1    DATETIME = NULL, -- Date du premier dépôt du 1 horaire s'il y a lieu
	@TimeUnitAmount1   MONEY = NULL, -- Montant en cotisation et frais du 1 horaire s'il y a lieu
	@TimeUnit2         SMALLINT = NULL, -- Type d'unité temporelle du 2 horaire s'il y a lieu
	@TimeUnitLap2      INTEGER = NULL, -- Nombre d'unité temporelle du 2 horaire s'il y a lieu
	@TimeUnitFirst2    DATETIME = NULL, -- Date du dépôt du 2 horaire s'il y a lieu
	@TimeUnitAmount2   MONEY = NULL) -- Montant en cotisation et frais du 2 horaire s'il y a lieu
AS 
BEGIN

	DECLARE 
		@IResultID  INTEGER,
		@YearQtyOfMaxYearCotisation INTEGER,
		@InsertYear  INTEGER,
		@IYear INTEGER,
		@PaymentDay INTEGER,
		@PmtRate DECIMAL(10,4),
		@PmtByYearID INTEGER,
		@PmtQty INTEGER,   
		@FromDate DATETIME,
		@ToDate DATETIME,
		@StartDate DATETIME,
		@EndDate DATETIME,
		@EstimatedAmount MONEY,
		@LastDepositDate DATETIME,      
		@YearDateStart DATETIME,
		@YearDateEnd DATETIME,
		@PlanTypeID VARCHAR(3),
		@SumEstimatedAmount MONEY,
		@SubsAmount MONEY,
		@MaxLifeCotisation MONEY,
		@MaxYearCotisation MONEY
  
	SET @IResultID = 1       

	SELECT 
		@YearQtyOfMaxYearCotisation = ISNULL(YearQtyOfMaxYearCotisation, 0)
	FROM Un_Def
   
	SELECT 
		@PlanTypeID = ISNULL(PlanTypeID, '')
	FROM Un_Plan
	WHERE (PlanID = @PlanID)    

	CREATE TABLE #ValEstimated 
	(
		ConventionID INTEGER,
		ConventionNo VARCHAR(75),
		PlanTypeID VARCHAR(3), 
		SubscriberID INTEGER,
		SubscriberName VARCHAR(85),
		InforceDate DATETIME,
		IYear INTEGER,
		YearDateStart DATETIME,
		YearDateEnd DATETIME,   
		PaymentDay INTEGER,
		SubsAmount MONEY,
		EstimatedAmount MONEY,
		CumAmount MONEY,
		CumAutomaticAmount MONEY,
		TheoricAmount MONEY,
		fCESP MONEY,
		fCIREE MONEY,
		LifeCeiling MONEY,
		AnnualCeiling MONEY
	)   

	INSERT INTO #ValEstimated 
		EXEC SL_UN_BenefAnnualMaxCeiling @BeneficiaryID 

	IF @@ROWCOUNT = 0 
		--Sile bénéficiaire a aucun unité 
		SELECT 
			@MaxLifeCotisation = B.LifeCeiling,
			@MaxYearCotisation = B.AnnualCeiling
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
	ELSE 
		SELECT 
			@MaxLifeCotisation = LifeCeiling,
			@MaxYearCotisation = AnnualCeiling
		FROM #ValEstimated 

	SET @PaymentDay = DAY(@FirstPmtDate)

	SELECT 
		@PmtRate     = PmtRate,   
		@PmtByYearID = PmtByYearID,
		@PmtQty      = PmtQty
	FROM Un_Modal 
	WHERE (ModalID = @ModalID)   

	IF @PlanTypeID = 'COL' 
	BEGIN

		SET @LastDepositDate = dbo.fn_Un_GetLastDepositDate(
											@PmtByYearID,   
											@FirstPmtDate,
											@InForceDate,
											@PmtQty)
	
		--Table temporaire sur les années de paiement d'un group d'unités
		CREATE TABLE #ValYear 
		(
			UnitID        INTEGER,
			IYear         INTEGER,
			YearDateStart DATETIME,
			YearDateEnd   DATETIME
		);    

		SET @InsertYear = YEAR(@InForceDate)
		SET @YearDateEnd = @InsertYear

		WHILE (@InsertYear < YEAR(DATEADD(YEAR, @YearQtyOfMaxYearCotisation, @InForceDate)))
		  AND (@InsertYear < = YEAR(@LastDepositDate))
		BEGIN
			IF (@InsertYear = YEAR(@InForceDate))
				SET @YearDateStart = @InForceDate
			ELSE        
				SET @YearDateStart = CAST(CAST(@InsertYear AS VARCHAR) + '-01-01' AS DATETIME)

			IF (@InsertYear = YEAR(@LastDepositDate))
				SET @YearDateEnd = @LastDepositDate
			ELSE 
				SET @YearDateEnd = CAST(CAST(@InsertYear AS VARCHAR) + '-12-31' AS DATETIME)  
      
			INSERT INTO #ValYear (
				UnitID,
				IYear,
				YearDateStart,
				YearDateEnd )
			VALUES (
				0,
				@InsertYear,
				@YearDateStart,
				@YearDateEnd)

			IF (@@ERROR <> 0)
				SET @IResultID = -1       
			SET @InsertYear = (@InsertYear + 1)      
		END

		--Curseur contenant l'information nécessaire pour faire le calcul des montants théorique pour une année 
		DECLARE EstimatedCursor CURSOR FOR
			SELECT 
				Y.IYear,
				Y.YearDateStart AS FromDate,
				Y.YearDateEnd AS ToDate
			FROM #ValYear Y

		OPEN EstimatedCursor
 
		FETCH NEXT FROM EstimatedCursor INTO
			@IYear,
			@FromDate,
			@ToDate

		SET @IResultID = 1

		WHILE (@@FETCH_STATUS = 0) AND (@IResultID > 0)
		BEGIN
			SET @StartDate       = @FromDate
			SET @EndDate   = @FromDate
			SET @EstimatedAmount = 0
    
			IF (@IYear >= YEAR(GetDate()))
			BEGIN
				IF (@TimeUnitLap1 > 0) OR (@TimeUnitLap2 > 0)
				BEGIN
					IF (@TimeUnitLap1 > 0)
					BEGIN
						IF (@IYear = YEAR(@TimeUnitStart1)) AND ((dbo.fn_Mo_IsDateNull(@TimeUnitEnd1) IS NULL) OR (@IYear < YEAR(@TimeUnitEnd1))) 
						BEGIN
							SET @StartDate = @TimeUnitFirst1
							SET @EndDate   = CAST(CAST(@IYear AS VARCHAR) + '-12-31' AS DATETIME)
						END
						ELSE IF (@IYear > YEAR(@TimeUnitStart1)) AND ((dbo.fn_Mo_IsDateNull(@TimeUnitEnd1) IS NULL) OR (@IYear < YEAR(@TimeUnitEnd1))) 
						BEGIN
							SET @StartDate = CAST(CAST(@IYear AS VARCHAR) + '-01-01' AS DATETIME)
							SET @EndDate   = CAST(CAST(@IYear AS VARCHAR) + '-12-31' AS DATETIME)
						END
						ELSE IF (@IYear = YEAR(@TimeUnitStart1)) AND (@IYear = YEAR(@TimeUnitEnd1)) 
						BEGIN
							SET @StartDate = @TimeUnitFirst1
							SET @EndDate   = @TimeUnitEnd1
						END
						ELSE
						BEGIN
							SET @StartDate = CAST(CAST(@IYear AS VARCHAR) + '-01-01' AS DATETIME)
							SET @EndDate   = @TimeUnitEnd1
						END

						SET @EstimatedAmount = (dbo.fn_Un_NbrAutoDepositBetweenTwoDate( 
															@TimeUnitFirst1, 
															@StartDate,
															@EndDate,
															@TimeUnit1,
															@TimeUnitLap1,
															0) * @TimeUnitAmount1) 

					END
					IF (@TimeUnitLap2 > 0) AND (@IYear = YEAR(@TimeUnitFirst2))
					BEGIN
						SET @EstimatedAmount = (dbo.fn_Un_NbrAutoDepositBetweenTwoDate( 
															@TimeUnitFirst2,
															@TimeUnitFirst2,
															@TimeUnitFirst2,
															@TimeUnit2,
															@TimeUnitLap2,
															0) * @TimeUnitAmount2) 
					END
				END
				ELSE
					SET @EstimatedAmount = dbo.fn_Un_EstimatedCotisationAndFee (
														@FromDate,
														@ToDate,
														@PaymentDay,
														@UnitQty, 
														@PmtRate,
														@PmtByYearID,
														@PmtQty,
														@InForceDate)
			END
   
			INSERT INTO #ValEstimated (
				ConventionID,
				ConventionNo, 
				PlanTypeID,
				SubscriberID,
				SubscriberName,
				InforceDate,
				IYear,
				YearDateStart,
				YearDateEnd,   
				PaymentDay,
				SubsAmount,
				EstimatedAmount,
				CumAmount,
				CumAutomaticAmount,
				TheoricAmount,
				fCESP,
				fCIREE,
				LifeCeiling,
				AnnualCeiling)
			VALUES (    
				0,
				'',
				'', 
				0,
				'',
				@InforceDate,
				@IYear,
				@YearDateStart,
				@YearDateEnd,   
				@PaymentDay,
				0,
				@EstimatedAmount,
				0,
				0,
				0,
				0,
				0,
				@MaxLifeCotisation,
				@MaxYearCotisation)

			IF (@@ERROR <> 0)
				SET @IResultID = -1       

			FETCH NEXT FROM EstimatedCursor INTO
				@IYear,
				@FromDate,
				@ToDate

		END
		CLOSE EstimatedCursor
		DEALLOCATE EstimatedCursor
		DROP TABLE #ValYear
	END
    
	--Curseur pour la validation des plafond maximum par année 
	DECLARE ValMaxYearCursor CURSOR FOR
		SELECT 
			E.IYear,
			EstimatedAmount = SUM(E.EstimatedAmount)
		FROM #ValEstimated E
		GROUP BY E.IYear

	OPEN ValMaxYearCursor
 
	FETCH NEXT FROM ValMaxYearCursor INTO
		@IYear,
		@EstimatedAmount

	SET @IResultID = 1

	WHILE (@@FETCH_STATUS = 0) AND (@IResultID > 0)
	BEGIN
    
		IF @EstimatedAmount > @MaxYearCotisation 
			SET @IResultID = -1

		FETCH NEXT FROM ValMaxYearCursor INTO
			@IYear,
			@EstimatedAmount
	END
	CLOSE ValMaxYearCursor
	DEALLOCATE ValMaxYearCursor
   
	IF @IResultID > 0 
	BEGIN
		IF (
			SELECT 
				SUM(EstimatedAmount)
			FROM #ValEstimated) > @MaxLifeCotisation
			SET @IResultID = -2
	END
	ELSE
		IF (
			SELECT 
				SUM(EstimatedAmount)
			FROM #ValEstimated) > @MaxLifeCotisation
			SET @IResultID = -3

	DROP TABLE #ValEstimated

	RETURN(@IResultID)
END


