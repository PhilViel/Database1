/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	VL_UN_Unit_IU
Description         :	Fait les validations BD d'un groupe d'unités avant sa sauvegarde
Valeurs de retours  :	Dataset :
									Code		VARCHAR(3)		Code d'erreur
									Info1		VARCHAR(100)	Premier champ d'information
									Info2		VARCHAR(100)	Deuxième champ d'information
									Info3		VARCHAR(100)	Troisième champ d'information

Note                :							2004-05-26	Bruno Lapointe	Création
						ADX0000831	IA	2006-03-23	Bruno Lapointe		Adaptation des conventions pour PCEE 4.3
										2009-10-06	Pierre-Luc Simard	Ne pas tenir compte des BEC lors de la validation U13
										2015-02-23	Donald Huppé			Enlever la validation U13.  N'est plus valide selon Annie Poirier.
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[VL_UN_Unit_IU] (
	@UnitID INTEGER, -- ID Unique du groupe d'unités (0 = Insertion, > 0 = Modification)
	@SubscriberID  INTEGER, -- ID Unique du souscripteur
	@SignatureDate DATETIME, -- Date de signature du groupe d'unités
	@ConventionID INTEGER, -- ID unique de la convention
	@InForceDate DATETIME, -- Date vigueur du groupe d'unités
	@ModalID INTEGER, -- ID unique de la modalité du groupe d'unités
	@UnitQty MONEY, -- Quantité d'unité  
 	@WantSubscriberInsurance INTEGER, -- 0 = pas d'assurance et <> 0 = assuré
	@PlanID INTEGER, -- ID Unique du plan de la convention
	@RepID INTEGER, -- ID unique du représentant du groupe d'unité
	@BeneficiaryID INTEGER, -- ID Unique du bénéficiaire
	@FirstPmtDate DATETIME, -- Date des dépôts de la convention
	@TimeUnit1 SMALLINT = NULL, -- Type d'unité temporelle du 1 horaire s'il y a lieu
	@TimeUnitLap1 INTEGER = NULL, -- Nombre d'unité temporelle du 1 horaire s'il y a lieu
	@TimeUnitStart1 DATETIME = NULL, -- Date de début de la période du 1 horaire s'il y a lieu
	@TimeUnitEnd1 DATETIME = NULL, -- Date de fin de la période du 1 horaire s'il y a lieu
	@TimeUnitFirst1 DATETIME = NULL, -- Date du premier dépôt du 1 horaire s'il y a lieu
	@TimeUnitAmount1 MONEY = NULL, -- Montant en cotisation et frais du 1 horaire s'il y a lieu
	@TimeUnit2 SMALLINT = NULL, -- Type d'unité temporelle du 2 horaire s'il y a lieu
	@TimeUnitLap2 INTEGER = NULL, -- Nombre d'unité temporelle du 2 horaire s'il y a lieu
	@TimeUnitFirst2 DATETIME = NULL, -- Date du dépôt du 2 horaire s'il y a lieu
	@TimeUnitAmount2 MONEY = NULL) -- Montant en cotisation et frais du 2 horaire s'il y a lieu
AS
BEGIN
	-- U01 -> Age maximum pour l'assurance souscripteur
	-- U02 -> Age minimal du souscripteur
	-- U03 -> Age du bénéficiaire versus la modalité de paiement
	-- U04 -> Nombre d'unités minimum dans une convention
	-- U05 -> Assurance souscripteur uniquement pour les résidents du canada
	-- U06 -> Dépôt minimum par plan et modalité de paiement
	-- U07 -> Le représentant du groupe d'unité n'est pas le même que celui du souscripteur
	-- U08 -> Maximum de capital assuré
	-- U09 -> Plafond annuel
	-- U10 -> Plafond à vie
	-- U11 -> Depôt minimum pour unique
	--	U12 -> Cet ajout d’unités affecte la date d’entrée en vigueur de la convention. 
	--	U13 -> La date d’entrée en vigueur doit être antérieure aux dates effectives de toutes les transactions de ce groupe d’unités.
	--	U14 -> La date d’entrée en vigueur de la convention est modifiée par ce changement, la convention sera réexpédiée au PCEE.

	DECLARE 
		@Result INTEGER
	
	CREATE TABLE #WngAndErr(
		Code VARCHAR(3),
		Info1 VARCHAR(100),
		Info2 VARCHAR(100),
		Info3 VARCHAR(100)
	)

	-- U01 -> Age maximum pour l'assurance souscripteur
	IF EXISTS (
		SELECT *
		FROM dbo.Mo_Human S
		WHERE S.HumanID = @SubscriberID
			AND S.IsCompany = 0 
			AND S.BirthDate > 0
		)
	BEGIN
		EXEC @Result = SP_VL_UN_MaxSubscInsurAgeForUnit @SubscriberID, @SignatureDate
		IF @Result <= 0 
			INSERT INTO #WngAndErr
				SELECT 
					'U01',
					'',
					'',
					''
	END

	-- U02 -> Age minimal du souscripteur
	IF EXISTS (
		SELECT *
		FROM dbo.Mo_Human S
		WHERE S.HumanID = @SubscriberID
			AND S.IsCompany = 0 
			AND S.BirthDate > 0
		)
	BEGIN
		EXEC @Result = SP_VL_UN_MinSubscriberAgeForUnit @SubscriberID, @SignatureDate
		IF @Result <= 0 
			INSERT INTO #WngAndErr
				SELECT 
					'U02',
					'',
					'',
					''
	END

	CREATE TABLE #ConventionNo(
		ConventionNo VARCHAR(75)
	)
	-- U03 -> Age du bénéficiaire versus la modalité de paiement
	INSERT INTO #ConventionNo
		EXEC SP_VL_UN_BenefAgeVsModalForUnit @ConventionID, @InForceDate, @ModalID
	INSERT INTO #WngAndErr
		SELECT 
			'U03',
			ConventionNo,
			'',
			''
		FROM #ConventionNo
	DELETE FROM #ConventionNo

	-- U04 -> Nombre d'unités minimum dans une convention
	CREATE TABLE #MinConvUnitQty(
		MinConvUnitQty MONEY
	)
	INSERT INTO #MinConvUnitQty
		EXEC SP_VL_UN_MinConvUnitQtyForUnit @ConventionID, @UnitID, @UnitQty, @InforceDate
	INSERT INTO #WngAndErr
		SELECT 
			'U04',
			CAST(MinConvUnitQty AS VARCHAR),
			'',
			''
		FROM #MinConvUnitQty
	DROP TABLE #MinConvUnitQty

	-- U05 -> Assurance souscripteur uniquement pour les résidents du canada
	INSERT INTO #ConventionNo
		EXEC SP_VL_UN_SubsInsOnlyForCanadianForUnit @ConventionID, @WantSubscriberInsurance
	INSERT INTO #WngAndErr
		SELECT 
			'U05',
			ConventionNo,
			'',
			''
		FROM #ConventionNo
	DELETE FROM #ConventionNo

	-- U06 -> Dépôt minimum par plan et modalité de paiement
	CREATE TABLE #MinDeposit(
		ModalTypeID INTEGER,
		MinConvUnitQty MONEY
	)
	INSERT INTO #MinDeposit
		EXEC SP_VL_UN_MinDepositForUnit @PlanID, @ModalID, @ConventionID, @InforceDate, @UnitQty
	INSERT INTO #WngAndErr
		SELECT 
			'U06',
			CAST(ModalTypeID AS VARCHAR),
			CAST(MinConvUnitQty AS VARCHAR),
			''
		FROM #MinDeposit
	DROP TABLE #MinDeposit

	-- U07 -> Le représentant du groupe d'unité n'est pas le même que celui du souscripteur
	CREATE TABLE #Rep(
		LastName VARCHAR(50),
		FirstName VARCHAR(35)
	)
	INSERT INTO #Rep
		EXEC SP_VL_UN_UnitRep @SubscriberID, @RepID, @UnitID
	INSERT INTO #WngAndErr
		SELECT 
			'U07',
			LastName+', '+FirstName,
			'',
			''
		FROM #Rep
	DROP TABLE #Rep

	-- Validations pour insertion seulement 
	IF @UnitID = 0
	BEGIN
		-- U08 -> Maximum de capital assuré
		CREATE TABLE #MaxFaceAmount(
			MaxFaceAmount MONEY,
			TotalCapitalInsured MONEY
		)
		INSERT INTO #MaxFaceAmount
			EXEC SP_VL_UN_MaxFaceAmountForUnit @SubscriberID, @UnitQty, @WantSubscriberInsurance, @ModalID
		INSERT INTO #WngAndErr
			SELECT 
				'U08',
				CAST(MaxFaceAmount AS VARCHAR),
				CAST(TotalCapitalInsured AS VARCHAR),
				''
			FROM #MaxFaceAmount
		DROP TABLE #MaxFaceAmount

		EXEC @Result = VL_UN_BeneficiaryCeilingForUnit 
			@BeneficiaryID, 
			@InForceDate, 
			@ModalID,
			@FirstPmtDate,
			@UnitQty,
			@PlanID,
			@TimeUnit1,
			@TimeUnitLap1,
			@TimeUnitStart1,
			@TimeUnitEnd1,
			@TimeUnitFirst1,
			@TimeUnitAmount1,
			@TimeUnit2,
			@TimeUnitLap2,
			@TimeUnitFirst2,
			@TimeUnitAmount2
		-- U09 -> Plafond annuel
		IF @Result IN (-1,-3) 
			INSERT INTO #WngAndErr
				SELECT 
					'U09',
					'',
					'',
					''
		-- U10 -> Plafond à vie
		IF @Result IN (-2,-3) 
			INSERT INTO #WngAndErr
				SELECT 
					'U10',
					'',
					'',
					''

		-- U11 -> Depôt minimum pour unique
		CREATE TABLE #MinUnique(
			MinAmount MONEY
		)
		INSERT INTO #MinUnique
			EXEC SP_VL_UN_MinUniqueDep @ConventionID, @ModalID, @InForceDate, @UnitQty
		INSERT INTO #WngAndErr
			SELECT 
				'U11',
				CAST(MinAmount AS VARCHAR),
				'',
				''
			FROM #MinUnique
		DROP TABLE #MinUnique

		--	U12 -> Cet ajout d’unités affecte la date d’entrée en vigueur de la convention. 
		IF EXISTS (
				SELECT 
					ConventionID,
					InForceDate = MIN(InForceDate)
				FROM dbo.Un_Unit 
				WHERE ConventionID = @ConventionID
				GROUP BY ConventionID
				HAVING MIN(InForceDate) > @InForceDate
				)
			INSERT INTO #WngAndErr
				SELECT 
					'U12',
					'',
					'',
					''
	END

	-- Validations pour modification seulement 
	IF @UnitID <> 0
	BEGIN
	/*
		--	U13 -> La date d’entrée en vigueur doit être antérieure aux dates effectives de toutes les transactions de ce groupe d’unités.
		IF EXISTS (
				SELECT *
				FROM Un_Cotisation Ct
				LEFT JOIN Un_Oper O ON O.OperID = Ct.OperID
				WHERE Ct.UnitID = @UnitID
					AND Ct.EffectDate < @InForceDate
					AND O.OperTypeID <> 'BEC'
				)
			
			INSERT INTO #WngAndErr
				SELECT 
					'U13',
					'',
					'',
					''
		*/
		--	U14 -> La date d’entrée en vigueur de la convention est modifiée par ce changement, la convention sera réexpédiée au PCEE.
		IF EXISTS ( -- La date d'entrée en vigueur a changée
				SELECT *
				FROM dbo.Un_Unit 
				WHERE UnitID = @UnitID
					AND InForceDate <> @InForceDate
				)
			AND(	NOT EXISTS ( -- Il n'y avait pas d'autres groupes d'unités sur la convention avec une date antérieur ou égale à celle du groupe d'unités modifié.
					SELECT *
					FROM dbo.Un_Unit U
					JOIN dbo.Un_Unit U2 ON U2.ConventionID = U.ConventionID AND U.UnitID <> U2.UnitID
					WHERE U.UnitID = @UnitID
						AND U.InForceDate >= U2.InForceDate
					)
				OR	@InForceDate < (SELECT MIN(InForceDate) FROM dbo.Un_Unit WHERE ConventionID = @ConventionID)
				)
			INSERT INTO #WngAndErr
				SELECT 
					'U14',
					'',
					'',
					''
	END

	DROP TABLE #ConventionNo

	SELECT *
	FROM #WngAndErr

	DROP TABLE #WngAndErr
END


