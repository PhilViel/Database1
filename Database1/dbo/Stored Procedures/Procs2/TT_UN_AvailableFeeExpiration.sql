/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	TT_UN_AvailableFeeExpiration
Description         :	Traitement de retrait automatique des frais disponibles expirés
Valeurs de retours  :	N/A
Note                :	ADX0000608	IA	2005-01-03	Bruno Lapointe		Migration et expiration immédiate des frais disponible de conventions individuelles
			ADX0001119	IA	2006-11-01	Alain Quirion		Le traitement journalier devra créer des enregistrements dans l’historique des frais disponibles utilisés. Il devra aussi tenir compte de l’historique pour déterminer les frais disponibles expirés. 
															Ajouter une opération (OperID) pour chacun des TFR créés par le traitement pour permettre de traiter individuellement chacun des TFR créés par le traitement. 
							2009-03-30	Donald Huppé		Correction de l'avertissmeent de NULL lors de l'exécution
							2013-11-21	Donald Huppé		glpi 10583 : Vérification des conventions TRI 
															afin de comparer la date du TRI et non les autres Operdate provenant de Un_UnitReductionCotisation qui ont été inséré lors du TRI
															et qu'on ne comprend pas pourquoi on a inséré toutes les cotisations de la collective (avant le TRI) dans cette table
							2016-09-23	Donald Huppé		Ne pas traiter les réductions cancellées

exec TT_UN_AvailableFeeExpiration 1, '2016-09-23'
															
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_AvailableFeeExpiration] (
	@ConnectID MoID, -- ID unique de connexion de l'usager qui l'a lancé
	@TreatmentDate MoDateOption) -- Date de traitement
AS
BEGIN
	DECLARE
		@myAmountTotal MONEY,
		@iOperID INTEGER,
		@iReturn INTEGER

	SET @iReturn = 1
    
	IF @TreatmentDate IS NULL 
		SET @TreatmentDate = GETDATE()

	-- Frais disponibles expirés non utilisés
	SELECT 
		CO1.ConventionID,
		CO1.UnitReductionID,
		UnitRES = CO1.UnitQty,
		UnitUSE = ISNULL(CO2.UnitQtyUse,0),
		CO1.FeeSumByUnit
	INTO #TABLETEMP1
	FROM ( 	SELECT  CO.ConventionID,		-- Va chercher les quantité d'unités résiliés qui sont expiré
			UR.UnitReductionID,
			UR.UnitQty,
			UR.FeeSumByUnit
		FROM Un_UnitReduction UR
		JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
		JOIN dbo.Un_Convention CO ON CO.ConventionID = U.ConventionID
		JOIN Un_Plan P ON P.PlanID = CO.PlanID
		JOIN Un_UnitReductionCotisation URC ON URC.UnitReductionID = UR.UnitReductionID
		JOIN Un_Cotisation CT ON CT.CotisationID = URC.CotisationID
		JOIN Un_Oper O ON O.OperID = CT.OperID
		JOIN (
			SELECT 
				A1.AvailableFeeExpirationCfgID, 
				A1.StartDate, 
				A1.MonthAvailable, 
				EndDate = DATEADD(DAY, -1,MIN(ISNULL(A2.StartDate,DATEADD(DAY, 1, @TreatmentDate))))
			FROM Un_AvailableFeeExpirationCfg  A1
			LEFT JOIN Un_AvailableFeeExpirationCfg A2 ON (A1.StartDate < A2.StartDate) OR ((A1.StartDate = A2.StartDate) AND (A1.AvailableFeeExpirationCfgID < A2.AvailableFeeExpirationCfgID))
			GROUP BY 
				A1.AvailableFeeExpirationCfgID, 
				A1.StartDate, 
				A1.MonthAvailable
			HAVING ISNULL(MIN(ISNULL(A2.StartDate,DATEADD(DAY, 1, @TreatmentDate))),0) <> A1.StartDate
			) A ON (A.StartDate <= O.OperDate) AND (ISNULL(A.EndDate,@TreatmentDate) > O.OperDate)		
		
		------------------ glpi 10583 ------------------------------
		LEFT JOIN (
			SELECT r.iID_Convention_Source, OperDateTRI = min(o.OperDate)
			FROM tblOPER_OperationsRIO r
			JOIN Un_Oper o ON r.iID_Oper_RIO = o.OperID
			WHERE bRIO_Annulee = 0
			AND bRIO_QuiAnnule = 0
			AND o.OperTypeID = 'TRI'
			GROUP BY r.iID_Convention_Source
			)TRI ON CO.ConventionID = TRI.iID_Convention_Source
		-------------------------------------------------------------
		LEFT JOIN Un_OperCancelation OC1 ON O.OperID = OC1.OperSourceID	
		LEFT JOIN Un_OperCancelation OC2 ON O.OperID = OC2.OperID
		WHERE 
			1=1
			AND (OC1.OperSourceID IS NULL AND OC2.OperID IS NULL) -- 2016-09-23
			AND (

					------------------ glpi 10583 ------------------------------
						(TRI.OperDateTRI IS NULL		AND DATEADD(MONTH,A.MonthAvailable,O.OperDate)		<= @TreatmentDate) -- cas normal
					OR	(TRI.OperDateTRI IS NOT NULL	AND DATEADD(MONTH,A.MonthAvailable,TRI.OperDateTRI) <= @TreatmentDate) -- cas de convention fermée TRI
					-------------------------------------------------------------
					OR	P.PlanTypeID = 'IND' -- cas normal
				)
		GROUP BY CO.ConventionID, UR.UnitReductionID, UR.UnitQty, UR.FeeSumByUnit) CO1
	LEFT JOIN (			-- Va chercher les unités utilisés
			SELECT  UnitReductionID,
				UnitQtyUse = SUM(fUnitQtyUse)
			FROM Un_AvailableFeeUse A
			GROUP BY UnitReductionID) CO2 ON CO2.UnitReductionID = CO1.UnitReductionID
	WHERE CO1.UnitQty - ISNULL(CO2.UnitQtyUse,0) > 0

	IF @@ERROR <> 0
		SET @iReturn = -1
	
	-- Autres frais disponibles n'ayant pas de lien avec la table Un_AvailableFee
	SELECT 
		CO1.ConventionID,
		CO1.Amount + ISNULL(CO2.Amount,0) AS ConventionOperAmount
	INTO #TABLETEMP2
	FROM ( -- Va chercher les frais disponibles échus
		SELECT 
			CO.ConventionID,
			Amount = SUM(CO.ConventionOperAmount)
		FROM Un_ConventionOper CO
		JOIN Un_Oper O ON O.OperID = CO.OperID
		JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
		JOIN Un_Plan P ON P.PlanID = C.PlanID
		JOIN (
			SELECT 
				A1.AvailableFeeExpirationCfgID, 
				A1.StartDate, 
				A1.MonthAvailable, 
				EndDate = DATEADD(DAY, -1,MIN(ISNULL(A2.StartDate,DATEADD(DAY, 1, @TreatmentDate))))
			FROM Un_AvailableFeeExpirationCfg  A1
			LEFT JOIN Un_AvailableFeeExpirationCfg A2 ON (A1.StartDate < A2.StartDate) OR ((A1.StartDate = A2.StartDate) AND (A1.AvailableFeeExpirationCfgID < A2.AvailableFeeExpirationCfgID))
			GROUP BY 
				A1.AvailableFeeExpirationCfgID, 
				A1.StartDate, 
				A1.MonthAvailable
			HAVING ISNULL(MIN(ISNULL(A2.StartDate,DATEADD(DAY, 1, @TreatmentDate))),0) <> A1.StartDate
			) A ON (A.StartDate <= O.OperDate) AND (ISNULL(A.EndDate,@TreatmentDate) > O.OperDate)
		JOIN Un_Cotisation CT ON CT.OperID = O.OperID
		LEFT JOIN Un_UnitReductionCotisation URC ON URC.CotisationID = CT.CotisationID		
		WHERE CO.ConventionOperTypeID = 'FDI'
		  AND CO.ConventionOperAmount > 0
		  AND (	DATEADD(MONTH,A.MonthAvailable,O.OperDate) <= @TreatmentDate
				OR	P.PlanTypeID = 'IND'
				)
		  AND URC.UnitReductionID IS NULL		-- Ne fait pas partie des unités résiliés
		GROUP BY CO.ConventionID
		) CO1
	LEFT JOIN ( -- Va chercher le montant de frais disponible remboursés
		SELECT 
			CO.ConventionID,
			Amount = SUM(CO.ConventionOperAmount)
		FROM Un_ConventionOper CO
		JOIN Un_Oper O ON O.OperID = CO.OperID
		JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
		JOIN Un_Plan P ON P.PlanID = C.PlanID
		WHERE	CO.ConventionOperTypeID = 'FDI'
			AND CO.ConventionOperAmount < 0
		GROUP BY CO.ConventionID
		) CO2 ON CO1.ConventionID = CO2.ConventionID	
	WHERE CO1.Amount + ISNULL(CO2.Amount,0) > 0

	IF @@ERROR <> 0
		SET @iReturn = -1

	BEGIN TRANSACTION

	IF EXISTS (
			SELECT ConventionID 
			FROM #TABLETEMP1)
		AND @iReturn > 0 
	BEGIN
		DECLARE @ConventionID INTEGER,
			@UnitReductionID INTEGER,
			@UnitRES MONEY,
			@UnitUSE MONEY,
			@FeeSumByUnit MONEY

		DECLARE CUR_OperTFR CURSOR FOR
		SELECT 
			ConventionID,
			UnitReductionID,
			UnitRES,
			UnitUSE,
			FeeSumByUnit
		FROM #TABLETEMP1

		OPEN CUR_OperTFR

		FETCH NEXT FROM CUR_OperTFR
		INTO 
			@ConventionID,
			@UnitReductionID,
			@UnitRES,
			@UnitUSE,
			@FeeSumByUnit

		WHILE @@FETCH_STATUS = 0 AND @iReturn > 0	
		BEGIN
			INSERT INTO Un_Oper (
				ConnectID,
				OperTypeID,
				OperDate )
			VALUES (@ConnectID, 'TFR', @TreatmentDate)
	
			IF @@ERROR = 0
				SET @iOperID = SCOPE_IDENTITY()
			ELSE
			BEGIN
				SET @iOperID = 0
				SET @iReturn = -3
			END
	
			IF @iOperID <> 0 
			BEGIN 
				-- Insertion dans Un_ConventionOper
				INSERT INTO Un_ConventionOper (
					OperID,
					ConventionID,
					ConventionOpertypeID,
					ConventionOperAmount)
					VALUES (
						@iOperID,
						@ConventionID,
						'FDI',
						(@UnitRES - @UnitUSE) * @FeeSumByUnit * -1)

				IF @@ERROR <> 0
					SET @iReturn = -4

				IF @iReturn > 0
				BEGIN
					-- Insertion d'un historique dans les frais disponible utilisés
					INSERT INTO Un_AvailableFeeUse(
						UnitReductionID,
						OperID,
						fUnitQtyUse)
					VALUES (@UnitReductionID,@iOperID, (@UnitRES - @UnitUSE))
				
					IF @@ERROR <> 0
						SET @iReturn = -5
				
					IF @iReturn > 0
					BEGIN						
			     			-- Insertion dans Un_OtherAccountOper
						INSERT INTO Un_OtherAccountOper(
							OperID,
							OtherAccountOperAmount)
						VALUES(
							@iOperID,
							(@UnitRES - @UnitUSE) * @FeeSumByUnit)

						IF @@ERROR <> 0
							SET @iReturn = -6
					END
				END
			END --(IF)

			FETCH NEXT FROM CUR_OperTFR
			INTO 
				@ConventionID,
				@UnitReductionID,
				@UnitRES,
				@UnitUSE,
				@FeeSumByUnit
		END

		CLOSE CUR_OperTFR
		DEALLOCATE CUR_OperTFR		
	END

	IF EXISTS (
			SELECT ConventionID 
			FROM #TABLETEMP2)
		AND @iReturn > 0
	BEGIN
		INSERT INTO Un_Oper (
			ConnectID,
			OperTypeID,
			OperDate )
		VALUES (@ConnectID, 'TFR',	@TreatmentDate)

		IF @@ERROR = 0
			SET @iOperID = SCOPE_IDENTITY()
		ELSE
		BEGIN
			SET @iOperID = 0
			SET @iReturn = -7
		END

		IF @iOperID <> 0 
		BEGIN 
			-- Insertion dans Un_ConventionOper
			INSERT INTO Un_ConventionOper (
				OperID,
				ConventionID,
				ConventionOpertypeID,
				ConventionOperAmount)
				SELECT 
					@iOperID,
					ConventionID,
					'FDI',
					ConventionOperAmount * -1
				FROM #TABLETEMP2

			IF @@ERROR <> 0
				SET @iReturn = -8

			IF @iReturn > 0
			BEGIN     
				SELECT 
					@myAmountTotal = SUM(ConventionOperAmount) 
				FROM #TABLETEMP2
	         
				-- Insertion dans Un_OtherAccountOper
				INSERT INTO Un_OtherAccountOper(
					OperID,
					OtherAccountOperAmount)
				VALUES(
					@iOperID,
					@myAmountTotal)
		
				IF @@ERROR <> 0
					SET @iReturn = -9
			END
		END --(IF)  
	END

	IF @iReturn > 0
		COMMIT TRANSACTION
	ELSE
		ROLLBACK TRANSACTION

	RETURN @iReturn

	DROP TABLE #TABLETEMP1
	DROP TABLE #TABLETEMP2
END


