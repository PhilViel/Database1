/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************   */
	
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	TT_UN_MonthlyConventionInterest
Description         :	Fait le calcul des intérêts composés à générer selon les taux de la table 
								Un_InterestRate ce sur le capital des conventions individuelles, sur les 
								subventions, les intérêts sur capital proventant de transfert IN et les 
								intérêts sur subventions provenant transfert IN.
Valeurs de retours  :	> 0 : Traitement réussi
								<= 0 : Erreur durant le traitement.
Note                :	ADX0000546	IA	2004-10-25	Bruno Lapointe		Création
								ADX0001415	BR	2005-04-28	Bruno Lapointe		Correction du bug qui fesait que la procédure ne 
																							fonctionnait jamais la première fois qu'on 
																							traitait un mois.
								ADX0000805	IA	2006-04-11	Bruno Lapointe		Adaptation PCEE 4.3, ajout de la gestion de 
																							l'intérêt BEC et SCEE+.
								ADX0002426	BR	2007-05-23	Bruno Lapointe		Gestion de la table Un_CESP.
								ADX0001175	UP	2007-06-08	Bruno Lapointe		FN_UN_EstimatedIntReimbDate paramêtre 
																							dtIntReimbAjust = NULL au lieu de 0
                                                2018-02-12  Pierre-Luc Simard   N'est plus utilisé, remplacé par psOPER_GenererRendement depuis 2009
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_MonthlyConventionInterest] (
	@ConnectID       MoID,          -- ID Unique de connexion de l'usager qui a commandé le calcul
	@OperDate        MoDateOption)  -- Date de l'opération financière d'intérêt (INT) résultante.
AS
BEGIN
	-- Valeurs de retour
	-- >0  : Le traitement à réussi, la valeur correspond au OperID de l'opération qui contient l'intérêt généré.
	-- <=0 : Erreur lors du traitement
	--		-1 : Erreur à la mise à jour de la date de barrure
	--		-2 : Erreur à la suppression des opérations sur convention de l'opération du traitement
	--		-3 : Erreur à la suppression de la référence entre l'opération INT et le dernier taux d'intérêt configuré
	--		-4 : Erreur à la suppression de l'opération INT
	--		-5 : Erreur à la mise à jour de la date de barrure
	--		-6 : Erreur à l'insertion de l'opération d'intérêt (INT)
	-- 	-7 : Erreur à la mise à jour de la table des intérêts (Un_InterestRate)
	-- 	-8 : Erreur à la création de d'une table temporaire
	-- 	-9 : Erreur à l'insertion des groupes d'unités éligibles à l'intérêt sur remboursement intégral
	-- 	-10 : Erreur au calcul des soldes, d'avant le début du mois, d'épargnes et frais sur convention qui ont des groupes d'unités éligibles à l'intérêt sur remboursement intégral
	-- 	-11 : Erreur au recensement des opérations du mois d'épargnes et frais sur convention qui ont des groupes d'unités éligibles à l'intérêt sur remboursement intégral
	-- 	-12 : Erreur au calcul des soldes, d'avant le début du mois, d'intérêt RI sur convention qui ont des groupes d'unités éligibles à l'intérêt sur remboursement intégral
	-- 	-13 : Erreur au recensement des opérations du mois, d'intérêt RI sur convention qui ont des groupes d'unités éligibles à l'intérêt sur remboursement intégral
	-- 	-14 : Erreur à la génération de l'intérêt RI
	-- 	-15 : Erreur à la suppression de table temporaire
	--		-16 : Erreur au calcul des soldes, d'avant le début du mois, d'épargnes sur convention individuel
	-- 	-17 : Erreur au recensement des opérations du mois d'épargnes sur convention individuel
	-- 	-18 : Erreur au calcul des soldes, d'avant le début du mois, d'intérêt RI sur convention individuel
	-- 	-19 : Erreur au recensement des opérations du mois, d'intérêt RI sur convention individuel
	-- 	-20 : Erreur à la génération de l'intérêt RI
	-- 	-21 : Erreur à la suppression de table temporaire
	-- 	-22 : Erreur au calcul des soldes, d'avant le début du mois, d'int. sur int. TIN
	-- 	-23 : Erreur au recensement des opérations du mois, d'int. sur int. TIN
	-- 	-24 : Erreur à la génération de l'int. sur int. TIN
	-- 	-25 : Erreur à la suppression de table temporaire
	-- 	-26 : Erreur au calcul des soldes, d'avant le début du mois, d'int. sur int. SCEE TIN
	-- 	-27 : Erreur au recensement des opérations du mois, d'int. sur int. SCEE TIN
	-- 	-28 : Erreur à la génération de l'int. sur int. SCEE TIN
	-- 	-29 : Erreur à la suppression de table temporaire
	-- 	-30 : Erreur au calcul des soldes, d'avant le début du mois, de subvention
	-- 	-31 : Erreur au recensement des opérations de subvention du mois
	-- 	-32 : Erreur au calcul des soldes, d'avant le début du mois, d'intérêt SCEE
	-- 	-33 : Erreur au recensement des opérations du mois, d'intérêt SCEE
	-- 	-34 : Erreur à la génération de l'intérêt SCEE
	-- 	-35 : Erreur à la suppression de table temporaire
	--		-36 : Erreur à la mise à jour de la date de barrure
	--		-37 : Erreur à l'exclusion des groupes d'unités dont le montant souscrit n'est pas atteint

	DECLARE
		@Result INTEGER,
		@ProcessedYear MoID,
		@ProcessedMonth MoID,
		@OperID MoID,
		@LastVerifDate MoDate,
		@TmpOperDate MoDate,
		@StartDateForIntAfterEstimatedRI MoDateOption,
		@MonthNoIntAfterEstimatedRI MoID,
		@NbDaysInMonth INTEGER,
		@NbDaysInYear INTEGER,
		@EndMonthDay DATETIME,
		@FirstMonthDay DATETIME,
		@TauxInt MoPct100,
		@TauxIntSCEE MoPct100

	SET @Result = 1

	SET @OperDate = dbo.FN_CRQ_DateNoTime(@OperDate)

	-- Va chercher la date du verrou des opérations financières
	SELECT @LastVerifDate = MAX(LastVerifDate)
	FROM Un_Def

	-- Détermine l'année à traiter qui est toutjours la plus récente des taux d'intérêts
	SELECT @ProcessedYear  = MAX(YearPeriod)
	FROM Un_InterestRate

	-- Détermine le mois à traiter qui est toutjours le plus récent pour l'année à traiter des taux d'intérêts
	SELECT @ProcessedMonth = MAX(MonthPeriod)
	FROM Un_InterestRate
	WHERE YearPeriod = @ProcessedYear

	-- Détermine si la période a déjà été traité
	SELECT 
		@OperID = IR.OperID,
		@TmpOperDate = O.OperDate,
		@TauxInt = IR.InterestRate,
		@TauxIntSCEE = IR.GovernmentGrantInterestRate
	FROM Un_InterestRate IR
	LEFT JOIN Un_Oper O ON IR.OperID = O.OperID
	WHERE IR.YearPeriod  = @ProcessedYear
	  AND IR.MonthPeriod = @ProcessedMonth

	-- Va chercher le nombre de jour qu'il y a dans l'année traitée
	IF @ProcessedYear % 4 = 0
		SET @NbDaysInYear = 366
	ELSE
		SET @NbDaysInYear = 365

	-- Va chercher le nombre de jour qu'il y a dans le mois traité
	IF @ProcessedMonth IN (1, 3, 5, 7, 8, 10, 12)
		SET @NbDaysInMonth = 31
	ELSE IF @ProcessedMonth IN (4, 6, 9, 11)
		SET @NbDaysInMonth = 30
	ELSE IF @NbDaysInYear = 365
		SET @NbDaysInMonth = 28
	ELSE 
		SET @NbDaysInMonth = 29

	SET @EndMonthDay = CAST(CAST(@ProcessedYear AS CHAR(4))+'-'+CAST(@ProcessedMonth AS CHAR(2))+'-'+CAST(@NbDaysInMonth AS CHAR(2)) AS DATETIME)
	SET @FirstMonthDay = CAST(CAST(@ProcessedYear AS CHAR(4))+'-'+CAST(@ProcessedMonth AS CHAR(2))+'-01' AS DATETIME)

	-----------------
	BEGIN TRANSACTION
	-----------------

	-- Si la période a déjà été traité il supprime l'ancien calcul
	IF (@OperID IS NOT NULL) AND (@OperID <> 0)
	BEGIN
		-- Débare la base de données pour permettre la suppression
		UPDATE Un_Def
		SET LastVerifDate = @TmpOperDate - 1

		-- Erreur à la mise à jour de la date de barrure
		IF @@ERROR <> 0
			SET @Result = -1

		IF @Result > 0
		BEGIN
			-- Supprime les opérations sur convention
			DELETE 
			FROM Un_ConventionOper
			WHERE OperID = @OperID

			-- Erreur à la suppression des opérations sur convention de l'opération du traitement
			IF @@ERROR <> 0
				SET @Result = -2
		END

		IF @Result > 0
		BEGIN
			-- Supprime la référence entre l'opération INT et le dernier taux d'intérêt configuré
			UPDATE Un_InterestRate
			SET OperID = NULL
			WHERE OperID = @OperID

			-- Erreur à la suppression de la référence entre l'opération INT et le dernier taux d'intérêt configuré
			IF @@ERROR <> 0
				SET @Result = -3
		END

		IF @Result > 0
		BEGIN
			-- Supprime l'opération INT
			DELETE 
			FROM Un_Oper
			WHERE OperID = @OperID

			-- Erreur à la suppression de l'opération INT
			IF @@ERROR <> 0
				SET @Result = -4
		END
	END

	IF @Result > 0
	BEGIN
		-- Débare la base de données pour créer le calcul
		UPDATE Un_Def
		SET LastVerifDate = @OperDate - 1

		-- Erreur à la mise à jour de la date de barrure
		IF @@ERROR <> 0
			SET @Result = -5
	END

	IF @Result > 0
	BEGIN
		-- Crée l'opération qui contiendra tout les intérêts générés.
		EXECUTE @OperID = SP_IU_UN_Oper
			@ConnectID,
			0,
			'INT',
			@OperDate
	
		-- Erreur à l'insertion de l'opération d'intérêt (INT)
		IF @OperID <= 0
			SET @Result = -6
		ELSE
			SET @Result = @OperID
	END

	IF @Result > 0
	BEGIN
		-- Fait le lien entre les taux d'intérêts et l'opération résultantes
		UPDATE Un_InterestRate
		SET OperID = @OperID
		WHERE YearPeriod  = @ProcessedYear
		  AND MonthPeriod = @ProcessedMonth

		-- Erreur à la mise à jour de la table des intérêts (Un_InterestRate)
		IF @@ERROR <> 0
			SET @Result = -7
	END

	-- Va chercher les paramètres servant à calculer les intérêts après la date estimée du RI.
	SET @StartDateForIntAfterEstimatedRI = NULL
	SET @MonthNoIntAfterEstimatedRI = 0
	SELECT 
		@StartDateForIntAfterEstimatedRI = StartDateForIntAfterEstimatedRI,
		@MonthNoIntAfterEstimatedRI = MonthNoIntAfterEstimatedRI
	FROM Un_Def

	IF (@StartDateForIntAfterEstimatedRI IS NOT NULL) AND (@StartDateForIntAfterEstimatedRI <= @EndMonthDay) AND (@Result > 0)
	BEGIN
		IF EXISTS (
				SELECT 
					MIN(O.OperDate)
				FROM dbo.Un_Convention C 
				JOIN Un_ConventionOper CO ON CO.ConventionID = C.ConventionID
				JOIN Un_Oper O ON O.OperID = CO.OperID
				JOIN Un_Plan P ON P.PlanID = C.PlanID
				WHERE CO.ConventionOperTypeID = 'INM'
				  AND O.OperTypeID = 'INT'
				  AND P.PlanTypeID = 'COL'
				HAVING MIN(O.OperDate) > @StartDateForIntAfterEstimatedRI)
		BEGIN
			SELECT 
				@TmpOperDate = MIN(O.OperDate)
			FROM dbo.Un_Convention C 
			JOIN Un_ConventionOper CO ON CO.ConventionID = C.ConventionID
			JOIN Un_Oper O ON O.OperID = CO.OperID
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			WHERE CO.ConventionOperTypeID = 'INM'
			  AND O.OperTypeID = 'INT'
			  AND P.PlanTypeID = 'COL'  

			SELECT 
				@StartDateForIntAfterEstimatedRI = DATEADD(DAY, 1, MAX(O.OperDate))
			FROM Un_Oper O
			JOIN Un_InterestRate I ON I.OperID = O.OperID
			WHERE O.OperDate < @TmpOperDate
		END

		-- Détermine les unités qui ont droit à l'intérêt après date estimée de remboursement intégral
		CREATE TABLE #UnitIntRI (
			UnitID INTEGER PRIMARY KEY,
			EstimatedRIDate DATETIME,
			IntRIStartDate DATETIME)

		-- Erreur à la création d'une table temporaire
		IF @@ERROR <> 0
			SET @Result = -8

		IF @Result > 0
		BEGIN
			-- Recense les groupes d'unités éligibles à l'intérêt sur remboursement intégral 
			INSERT INTO #UnitIntRI
				SELECT 
					U.UnitID,
					EstimatedRIDate = DATEADD(MONTH, @MonthNoIntAfterEstimatedRI, dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, NULL)),
					IntRIStartDate =
						CASE 
							WHEN DATEADD(MONTH, @MonthNoIntAfterEstimatedRI, dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, NULL)) > @StartDateForIntAfterEstimatedRI THEN 
								DATEADD(MONTH, @MonthNoIntAfterEstimatedRI, dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, NULL))
						ELSE @StartDateForIntAfterEstimatedRI
						END
				FROM dbo.Un_Unit U
				JOIN Un_Modal M ON M.ModalID = U.ModalID
				JOIN Un_Plan P ON P.PlanID = M.PlanID
				WHERE (ISNULL(U.IntReimbDate, @EndMonthDay + 1) > @EndMonthDay)
				  AND (ISNULL(U.TerminatedDate, @EndMonthDay + 1) > @EndMonthDay)
				  AND P.PlanTypeID = 'COL'
				  AND (DATEADD(MONTH, @MonthNoIntAfterEstimatedRI, dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, NULL)) <= @EndMonthDay)

			-- Erreur à l'insertion des groupes d'unités éligibles à l'intérêt sur remboursement intégral
			IF @@ERROR <> 0
				SET @Result = -9
		END

		IF @Result > 0
		BEGIN
			-- Au dernier jour du mois pour lequel l’intérêt est calculé (@EndMonthDay) 
			-- moins le délai d’attente configuré dans le système (@MonthNoIntAfterEstimatedRI)
			-- le montant souscrit du groupe d’unités devait être atteint.
			DELETE
			FROM #UnitIntRI
			WHERE UnitID NOT IN (
				SELECT 
					U.UnitID
				FROM #UnitIntRI URI
				JOIN dbo.Un_Unit U ON URI.UnitID = U.UnitID
				JOIN Un_Modal M ON M.ModalID = U.ModalID
				JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
				JOIN Un_Oper O ON O.OperID = Ct.OperID 
				WHERE O.OperDate < DATEADD(MONTH,-@MonthNoIntAfterEstimatedRI, @EndMonthDay+1)
				GROUP BY 
					U.UnitID,
					U.PmtEndConnectID,
					U.UnitQty,
					M.PmtRate,
					M.PmtQty
				HAVING U.PmtEndConnectID > 0
					OR SUM(Ct.Cotisation + Ct.Fee) >= ROUND(U.UnitQty*M.PmtRate,2)*M.PmtQty
				)

			-- Erreur à l'exclusion des groupes d'unités dont le montant souscrit n'est pas atteint
			IF @@ERROR <> 0
				SET @Result = -37
		END
		
		IF @Result > 0
		BEGIN
			-- Enregistrements de solde d'épargnes et frais
			SELECT 
				U.ConventionID,
				DayInProcessMonth = 0,
				Amount = SUM(Ct.Cotisation + Ct.Fee)
			INTO #RIInterest
			FROM dbo.Un_Unit U
			JOIN #UnitIntRI URI ON URI.UnitID = U.UnitID
			JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
			JOIN Un_Oper O ON O.OperID = Ct.OperID 
			WHERE O.OperDate < @FirstMonthDay
			GROUP BY 
				U.ConventionID

			-- Erreur au calcul des soldes, d'avant le début du mois, d'épargnes et frais sur convention qui ont des groupes d'unités éligibles à l'intérêt sur remboursement intégral
			IF @@ERROR <> 0
				SET @Result = -10
		END

		IF @Result > 0
		BEGIN
			-- Enregistrement de nouvelles transactions d'épargnes et frais du mois
			INSERT INTO #RIInterest
				SELECT 
					U.ConventionID,
					DayInProcessMonth = DAY(O.OperDate),
					Amount = SUM(Ct.Cotisation + Ct.Fee)
				FROM dbo.Un_Unit U
				JOIN #UnitIntRI URI ON URI.UnitID = U.UnitID
				JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
				JOIN Un_Oper O ON O.OperID = Ct.OperID 
				WHERE O.OperDate BETWEEN @FirstMonthDay AND @EndMonthDay
				GROUP BY 
					U.ConventionID,
					O.OperDate
	
			-- Erreur au recensement des opérations du mois d'épargnes et frais sur convention qui ont des groupes d'unités éligibles à l'intérêt sur remboursement intégral
			IF @@ERROR <> 0
				SET @Result = -11
		END

		IF @Result > 0
		BEGIN
			-- Enregistrements de solde d'intérêt RI
			INSERT INTO #RIInterest
				SELECT 
					U.ConventionID,
					DayInProcessMonth = 0,
					Amount = SUM(CO.ConventionOperAmount)
				FROM (
					SELECT DISTINCT 
						U.ConventionID
					FROM dbo.Un_Unit U
					JOIN #UnitIntRI URI ON URI.UnitID = U.UnitID 
					) U
				JOIN Un_ConventionOper CO ON CO.ConventionID = U.ConventionID
				JOIN Un_Oper O ON O.OperID = CO.OperID 
				WHERE (O.OperDate < @FirstMonthDay)
				  AND CO.ConventionOperTypeID = 'INM'
				GROUP BY 
					U.ConventionID
	
			-- Erreur au calcul des soldes, d'avant le début du mois, d'intérêt RI sur convention qui ont des groupes d'unités éligibles à l'intérêt sur remboursement intégral
			IF @@ERROR <> 0
				SET @Result = -12
		END

		IF @Result > 0
		BEGIN
			-- Enregistrement de nouvelles transactions d'intérêt RI du mois
			INSERT INTO #RIInterest
				SELECT 
					U.ConventionID,
					DayInProcessMonth = DAY(O.OperDate),
					Amount = SUM(CO.ConventionOperAmount)
				FROM (
					SELECT DISTINCT 
						U.ConventionID
					FROM dbo.Un_Unit U
					JOIN #UnitIntRI URI ON URI.UnitID = U.UnitID 
					) U
				JOIN Un_ConventionOper CO ON CO.ConventionID = U.ConventionID
				JOIN Un_Oper O ON O.OperID = CO.OperID 
				WHERE (O.OperDate BETWEEN @FirstMonthDay AND @EndMonthDay)
				  AND CO.ConventionOperTypeID = 'INM'
				GROUP BY 
					U.ConventionID,
					O.OperDate
	
			-- Erreur au recensement des opérations du mois, d'intérêt RI sur convention qui ont des groupes d'unités éligibles à l'intérêt sur remboursement intégral
			IF @@ERROR <> 0
				SET @Result = -13
		END

		IF @Result > 0
		BEGIN
			-- Génére les intérêts sur capital des conventions collectives après la date estimée du RI si le RI n'a pas encore eu lieu
			INSERT INTO Un_ConventionOper (OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount)
				SELECT 
					@OperID,
					RII.ConventionID,
					ConventionOperTypeID = 'INM',
					ConventionOperAmount = ROUND(SUM(RII.Amount*@TauxInt/100*(CAST(@NbDaysInMonth AS MONEY)-RII.DayInProcessMonth)/CAST(@NbDaysInYear AS MONEY)),2)
				FROM #RIInterest RII
				GROUP BY
					RII.ConventionID
				HAVING ROUND(SUM(RII.Amount*@TauxInt/100*(CAST(@NbDaysInMonth AS MONEY)-RII.DayInProcessMonth)/CAST(@NbDaysInYear AS MONEY)),2) > 0 -- Intérêt positif seulement.
	
			-- Erreur à la génération de l'intérêt RI
			IF @@ERROR <> 0
				SET @Result = -14
		END

		IF @Result > 0
		BEGIN
			-- Suppression de table temporaire
			DROP TABLE #RIInterest
			DROP TABLE #UnitIntRI

			-- Erreur à la suppression de table temporaire
			IF @@ERROR <> 0
				SET @Result = -15
		END
	END

	-- Génére les intérêts sur capital des conventions individuelles
	IF @Result > 0
	BEGIN
		-- Enregistrements de solde d'épargnes
		SELECT 
			U.ConventionID,
			DayInProcessMonth = 0,
			Amount = SUM(Ct.Cotisation)
		INTO #INDInterest
		FROM dbo.Un_Unit U
		JOIN Un_Modal M ON M.ModalID = U.ModalID
		JOIN Un_Plan P ON P.PlanID = M.PlanID
		JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
		JOIN Un_Oper O ON O.OperID = Ct.OperID 
		WHERE P.PlanTypeID = 'IND'
		  AND O.OperDate < @FirstMonthDay
		GROUP BY 
			U.ConventionID

		-- Erreur au calcul des soldes, d'avant le début du mois, d'épargnes sur convention individuel
		IF @@ERROR <> 0
			SET @Result = -16
	END

	IF @Result > 0
	BEGIN
		-- Enregistrement de nouvelles transactions d'épargnes du mois
		INSERT INTO #INDInterest
			SELECT 
				U.ConventionID,
				DayInProcessMonth = DAY(O.OperDate),
				Amount = SUM(Ct.Cotisation)
			FROM dbo.Un_Unit U
			JOIN Un_Modal M ON M.ModalID = U.ModalID
			JOIN Un_Plan P ON P.PlanID = M.PlanID
			JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
			JOIN Un_Oper O ON O.OperID = Ct.OperID 
			WHERE P.PlanTypeID = 'IND'
			  AND O.OperDate BETWEEN @FirstMonthDay AND @EndMonthDay
			GROUP BY 
				U.ConventionID,
				O.OperDate

		-- Erreur au recensement des opérations du mois d'épargnes sur convention individuel
		IF @@ERROR <> 0
			SET @Result = -17
	END

	IF @Result > 0
	BEGIN
		-- Enregistrements de solde d'intérêt individuel
		INSERT INTO #INDInterest
			SELECT 
				C.ConventionID,
				DayInProcessMonth = 0,
				Amount = SUM(CO.ConventionOperAmount)
			FROM dbo.Un_Convention C
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			JOIN Un_ConventionOper CO ON CO.ConventionID = C.ConventionID
			JOIN Un_Oper O ON O.OperID = CO.OperID 
			WHERE P.PlanTypeID = 'IND'
			  AND (O.OperDate < @FirstMonthDay)
			  AND CO.ConventionOperTypeID = 'INM'
			GROUP BY 
				C.ConventionID

		-- Erreur au calcul des soldes, d'avant le début du mois, d'intérêt RI sur convention individuel
		IF @@ERROR <> 0
			SET @Result = -18
	END

	IF @Result > 0
	BEGIN
		-- Enregistrement de nouvelles transactions d'intérêt individuel du mois
		INSERT INTO #INDInterest
			SELECT 
				C.ConventionID,
				DayInProcessMonth = DAY(O.OperDate),
				Amount = SUM(CO.ConventionOperAmount)
			FROM dbo.Un_Convention C
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			JOIN Un_ConventionOper CO ON CO.ConventionID = C.ConventionID
			JOIN Un_Oper O ON O.OperID = CO.OperID 
			WHERE P.PlanTypeID = 'IND'
			  AND (O.OperDate BETWEEN @FirstMonthDay AND @EndMonthDay)
			  AND CO.ConventionOperTypeID = 'INM'
			GROUP BY 
				C.ConventionID,
				O.OperDate

		-- Erreur au recensement des opérations du mois, d'intérêt RI sur convention individuel
		IF @@ERROR <> 0
			SET @Result = -19
	END

	IF @Result > 0
	BEGIN
		-- Génére les intérêts sur capital des conventions collectives après la date estimée du RI si le RI n'a pas encore eu lieu
		INSERT INTO Un_ConventionOper (OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount)
			SELECT 
				@OperID,
				IND.ConventionID,
				ConventionOperTypeID = 'INM',
				ConventionOperAmount = ROUND(SUM(IND.Amount*@TauxInt/100*(CAST(@NbDaysInMonth AS MONEY)-IND.DayInProcessMonth)/CAST(@NbDaysInYear AS MONEY)),2)
			FROM #INDInterest IND
			GROUP BY
				IND.ConventionID
			HAVING ROUND(SUM(IND.Amount*@TauxInt/100*(CAST(@NbDaysInMonth AS MONEY)-IND.DayInProcessMonth)/CAST(@NbDaysInYear AS MONEY)),2) > 0 -- Intérêt positif seulement.

		-- Erreur à la génération de l'intérêt RI
		IF @@ERROR <> 0
			SET @Result = -20
	END

	IF @Result > 0
	BEGIN
		-- Suppression de table temporaire
		DROP TABLE #INDInterest

		-- Erreur à la suppression de table temporaire
		IF @@ERROR <> 0
			SET @Result = -21
	END

	-- Génére les intérêts sur intérêt transfert IN (Int. sur int. TIN)
	IF @Result > 0
	BEGIN
		-- Enregistrements de solde Int. TIN
		SELECT 
			CO.ConventionID,
			DayInProcessMonth = 0,
			Amount = SUM(CO.ConventionOperAmount)
		INTO #TINInterest
		FROM Un_ConventionOper CO
		JOIN Un_Oper O ON O.OperID = CO.OperID 
		WHERE CO.ConventionOperTypeID = 'ITR'
		  AND (O.OperDate < @FirstMonthDay)
		GROUP BY 
			CO.ConventionID

		-- Erreur au calcul des soldes, d'avant le début du mois, d'int. sur int. TIN
		IF @@ERROR <> 0
			SET @Result = -22
	END

	IF @Result > 0
	BEGIN
		-- Enregistrement de nouvelles transactions d'int. sur int. TIN
		INSERT INTO #TINInterest
			SELECT 
				CO.ConventionID,
				DayInProcessMonth = DAY(O.OperDate),
				Amount = SUM(CO.ConventionOperAmount)
			FROM Un_ConventionOper CO
			JOIN Un_Oper O ON O.OperID = CO.OperID 
			WHERE CO.ConventionOperTypeID = 'ITR'
			  AND (O.OperDate BETWEEN @FirstMonthDay AND @EndMonthDay)
			GROUP BY 
				CO.ConventionID,
				O.OperDate

		-- Erreur au recensement des opérations du mois, d'int. sur int. TIN
		IF @@ERROR <> 0
			SET @Result = -23
	END

	IF @Result > 0
	BEGIN
		-- Génére les int. sur int. TIN
		INSERT INTO Un_ConventionOper (OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount)
			SELECT 
				@OperID,
				TIN.ConventionID,
				ConventionOperTypeID = 'ITR',
				ConventionOperAmount = ROUND(SUM(TIN.Amount*@TauxInt/100*(CAST(@NbDaysInMonth AS MONEY)-TIN.DayInProcessMonth)/CAST(@NbDaysInYear AS MONEY)),2)
			FROM #TINInterest TIN
			GROUP BY
				TIN.ConventionID
			HAVING ROUND(SUM(TIN.Amount*@TauxInt/100*(CAST(@NbDaysInMonth AS MONEY)-TIN.DayInProcessMonth)/CAST(@NbDaysInYear AS MONEY)),2) > 0 -- Intérêt positif seulement.

		-- Erreur à la génération de l'int. sur int. TIN
		IF @@ERROR <> 0
			SET @Result = -24
	END

	IF @Result > 0
	BEGIN
		-- Suppression de table temporaire
		DROP TABLE #TINInterest

		-- Erreur à la suppression de table temporaire
		IF @@ERROR <> 0
			SET @Result = -25
	END

	-- Génére les intérêts sur intérêt sur subventions transfert IN
	IF @Result > 0
	BEGIN
		-- Enregistrements de solde int. sur int. SCEE TIN
		SELECT 
			CO.ConventionID,
			DayInProcessMonth = 0,
			Amount = SUM(CO.ConventionOperAmount)
		INTO #SCEETINInterest
		FROM Un_ConventionOper CO
		JOIN Un_Oper O ON O.OperID = CO.OperID 
		WHERE CO.ConventionOperTypeID = 'IST'
		  AND (O.OperDate < @FirstMonthDay)
		GROUP BY 
			CO.ConventionID

		-- Erreur au calcul des soldes, d'avant le début du mois, d'int. sur int. SCEE TIN
		IF @@ERROR <> 0
			SET @Result = -26
	END

	IF @Result > 0
	BEGIN
		-- Enregistrement de nouvelles transactions d'int. sur int. SCEE TIN
		INSERT INTO #SCEETINInterest
			SELECT 
				CO.ConventionID,
				DayInProcessMonth = DAY(O.OperDate),
				Amount = SUM(CO.ConventionOperAmount)
			FROM Un_ConventionOper CO
			JOIN Un_Oper O ON O.OperID = CO.OperID 
			WHERE CO.ConventionOperTypeID = 'IST'
			  AND (O.OperDate BETWEEN @FirstMonthDay AND @EndMonthDay)
			GROUP BY 
				CO.ConventionID,
				O.OperDate

		-- Erreur au recensement des opérations du mois, d'int. sur int. SCEE TIN
		IF @@ERROR <> 0
			SET @Result = -27
	END

	IF @Result > 0
	BEGIN
		-- Génére les int. sur int. SCEE TIN
		INSERT INTO Un_ConventionOper (OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount)
			SELECT 
				@OperID,
				STIN.ConventionID,
				ConventionOperTypeID = 'IST',
				ConventionOperAmount = ROUND(SUM(STIN.Amount*@TauxIntSCEE/100*(CAST(@NbDaysInMonth AS MONEY)-STIN.DayInProcessMonth)/CAST(@NbDaysInYear AS MONEY)),2)
			FROM #SCEETINInterest STIN
			GROUP BY
				STIN.ConventionID
			HAVING ROUND(SUM(STIN.Amount*@TauxIntSCEE/100*(CAST(@NbDaysInMonth AS MONEY)-STIN.DayInProcessMonth)/CAST(@NbDaysInYear AS MONEY)),2) > 0 -- Intérêt positif seulement.

		-- Erreur à la génération de l'int. sur int. SCEE TIN
		IF @@ERROR <> 0
			SET @Result = -28
	END

	IF @Result > 0
	BEGIN
		-- Suppression de table temporaire
		DROP TABLE #SCEETINInterest

		-- Erreur à la suppression de table temporaire
		IF @@ERROR <> 0
			SET @Result = -29
	END

	-- Génére les intérêts sur la subvention
	IF @Result > 0
	BEGIN
		-- Enregistrements de solde de subvention
		SELECT 
			CE.ConventionID,
			DayInProcessMonth = 0,
			fCESG = SUM(CE.fCESG),
			fACESG = SUM(CE.fACESG),
			fCLB = SUM(CE.fCLB)
		INTO #SCEEInterest
		FROM Un_CESP CE
		JOIN Un_Oper O ON O.OperID = CE.OperID 
		WHERE O.OperDate < @FirstMonthDay
		GROUP BY 
			CE.ConventionID

		-- Erreur au calcul des soldes, d'avant le début du mois, de subvention
		IF @@ERROR <> 0
			SET @Result = -30
	END

	IF @Result > 0
	BEGIN
		-- Enregistrement de nouvelles transactions de subvention du mois
		INSERT INTO #SCEEInterest
			SELECT 
				CE.ConventionID,
				DayInProcessMonth = DAY(O.OperDate),
				fCESG = SUM(CE.fCESG),
				fACESG = SUM(CE.fACESG),
				fCLB = SUM(CE.fCLB)
			FROM Un_CESP CE
			JOIN Un_Oper O ON O.OperID = CE.OperID 
			WHERE O.OperDate BETWEEN @FirstMonthDay AND @EndMonthDay
			GROUP BY 
				CE.ConventionID,
				O.OperDate

		-- Erreur au recensement des opérations de subvention du mois
		IF @@ERROR <> 0
			SET @Result = -31
	END

	IF @Result > 0
	BEGIN
		-- Enregistrements de solde d'intérêt SCEE
		INSERT INTO #SCEEInterest
			SELECT 
				CO.ConventionID,
				DayInProcessMonth = 0,
				fCESG =
					SUM(
						CASE 
							WHEN CO.ConventionOperTypeID = 'INS' THEN CO.ConventionOperAmount
						ELSE 0
						END
						),
				fACESG =
					SUM(
						CASE 
							WHEN CO.ConventionOperTypeID = 'IS+' THEN CO.ConventionOperAmount
						ELSE 0
						END
						),
				fCLB =
					SUM(
						CASE 
							WHEN CO.ConventionOperTypeID = 'IBC' THEN CO.ConventionOperAmount
						ELSE 0
						END
						)
			FROM Un_ConventionOper CO 
			JOIN Un_Oper O ON O.OperID = CO.OperID 
			WHERE CO.ConventionOperTypeID IN ('INS','IS+', 'IBC')
				AND (O.OperDate < @FirstMonthDay)
			GROUP BY 
				CO.ConventionID

		-- Erreur au calcul des soldes, d'avant le début du mois, d'intérêt SCEE
		IF @@ERROR <> 0
			SET @Result = -32
	END

	IF @Result > 0
	BEGIN
		-- Enregistrement de nouvelles transactions d'intérêt SCEE du mois
		INSERT INTO #SCEEInterest
			SELECT 
				CO.ConventionID,
				DayInProcessMonth = DAY(O.OperDate),
				fCESG =
					SUM(
						CASE 
							WHEN CO.ConventionOperTypeID = 'INS' THEN CO.ConventionOperAmount
						ELSE 0
						END
						),
				fACESG =
					SUM(
						CASE 
							WHEN CO.ConventionOperTypeID = 'IS+' THEN CO.ConventionOperAmount
						ELSE 0
						END
						),
				fCLB =
					SUM(
						CASE 
							WHEN CO.ConventionOperTypeID = 'IBC' THEN CO.ConventionOperAmount
						ELSE 0
						END
						)
			FROM Un_ConventionOper CO 
			JOIN Un_Oper O ON O.OperID = CO.OperID 
			WHERE CO.ConventionOperTypeID IN ('INS','IS+', 'IBC')
			  AND (O.OperDate BETWEEN @FirstMonthDay AND @EndMonthDay)
			GROUP BY 
				CO.ConventionID,
				O.OperDate

		-- Erreur au recensement des opérations du mois, d'intérêt SCEE
		IF @@ERROR <> 0
			SET @Result = -33
	END

	IF @Result > 0
	BEGIN
		-- Génére les intérêts sur la SCEE
		INSERT INTO Un_ConventionOper (OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount)
			SELECT 
				@OperID,
				SCEE.ConventionID,
				ConventionOperTypeID = 'INS',
				ConventionOperAmount = ROUND(SUM(SCEE.fCESG*@TauxIntSCEE/100*(CAST(@NbDaysInMonth AS MONEY)-SCEE.DayInProcessMonth)/CAST(@NbDaysInYear AS MONEY)),2)
			FROM #SCEEInterest SCEE
			GROUP BY
				SCEE.ConventionID
			HAVING ROUND(SUM(SCEE.fCESG*@TauxIntSCEE/100*(CAST(@NbDaysInMonth AS MONEY)-SCEE.DayInProcessMonth)/CAST(@NbDaysInYear AS MONEY)),2) > 0 -- Intérêt positif seulement.

		-- Erreur à la génération de l'intérêt SCEE
		IF @@ERROR <> 0
			SET @Result = -34
	END

	IF @Result > 0
	BEGIN
		-- Génére les intérêts sur la SCEE+
		INSERT INTO Un_ConventionOper (OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount)
			SELECT 
				@OperID,
				SCEE.ConventionID,
				ConventionOperTypeID = 'IS+',
				ConventionOperAmount = ROUND(SUM(SCEE.fACESG*@TauxIntSCEE/100*(CAST(@NbDaysInMonth AS MONEY)-SCEE.DayInProcessMonth)/CAST(@NbDaysInYear AS MONEY)),2)
			FROM #SCEEInterest SCEE
			GROUP BY
				SCEE.ConventionID
			HAVING ROUND(SUM(SCEE.fACESG*@TauxIntSCEE/100*(CAST(@NbDaysInMonth AS MONEY)-SCEE.DayInProcessMonth)/CAST(@NbDaysInYear AS MONEY)),2) > 0 -- Intérêt positif seulement.

		-- Erreur à la génération de l'intérêt SCEE+
		IF @@ERROR <> 0
			SET @Result = -35
	END

	IF @Result > 0
	BEGIN
		-- Génére les intérêts sur le BEC
		INSERT INTO Un_ConventionOper (OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount)
			SELECT 
				@OperID,
				SCEE.ConventionID,
				ConventionOperTypeID = 'IBC',
				ConventionOperAmount = ROUND(SUM(SCEE.fCLB*@TauxIntSCEE/100*(CAST(@NbDaysInMonth AS MONEY)-SCEE.DayInProcessMonth)/CAST(@NbDaysInYear AS MONEY)),2)
			FROM #SCEEInterest SCEE
			GROUP BY
				SCEE.ConventionID
			HAVING ROUND(SUM(SCEE.fCLB*@TauxIntSCEE/100*(CAST(@NbDaysInMonth AS MONEY)-SCEE.DayInProcessMonth)/CAST(@NbDaysInYear AS MONEY)),2) > 0 -- Intérêt positif seulement.

		-- Erreur à la génération de l'intérêt BEC
		IF @@ERROR <> 0
			SET @Result = -36
	END

	IF @Result > 0
	BEGIN
		-- Suppression de table temporaire
		DROP TABLE #SCEEInterest

		-- Erreur à la suppression de table temporaire
		IF @@ERROR <> 0
			SET @Result = -37
	END

	IF @Result > 0
	BEGIN
		-- Remet la date de barrure à sa valeur initiale
		UPDATE Un_Def
		SET LastVerifDate = @LastVerifDate

		-- Erreur à la mise à jour de la date de barrure
		IF @@ERROR <> 0
			SET @Result = -38
	END

	IF @Result > 0
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
		--------------------

	RETURN @Result
END