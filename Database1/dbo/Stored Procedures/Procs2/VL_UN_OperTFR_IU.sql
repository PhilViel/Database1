/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	VL_UN_OperTFR_IU
Description         :	Procédure de validation avant la sauvegarde d’ajout/modification de transferts de frais.
Valeurs de retours  :	Dataset : (Vide = pas d’erreur dans les validations)
									vcCode	VARCHAR(5)	Code de d’erreur
									vcInfo1	VARCHAR(100)	Première information supplémentaire, permet de faire des messages détaillés.
									vcInfo2	VARCHAR(100)	Deuxième information supplémentaire.
									vcInfo3	VARCHAR(100)	Troisième information supplémentaire.
								Erreurs possibles du Dataset :
									Code	TFR01
									Message	Le montant de l’opération TFR doit être égal 0.00$.
									Code	TFR02
									Message	La date d’opération doit être plus grande que la date de barrure du système.
									Code	TFR03
									Info1	LigneTrans	
									Info2	ConventionNo
									Message	Le montant de frais disponibles retirés d’une convention ne doit pas être plus élevé que le solde de frais disponibles de cette convention.
									Code	GEN01
									Message	Pas de détail d'opération.
									Code	GEN02
									Message	Pas d'opération.
									Code	GEN03
									Message	Plus d'une opération avec le même OperID.
									Code	GEN04
									Message	Le blob n'existe pas.
									Code	GEN05
									Message	Update du blob par le service par encore fait.
									Code	GEN06
									Message	Les deux derniers caractères ne sont pas un saut de ligne et un retour de chariot.
								ReturnValue :
									> 0 : Réussite
									<= 0 : Erreurs.
										-1 -> Le blob n'existe pas
										-2 -> Update du blob par le service par encore fait
										-3 -> Les deux derniers caractères ne sont pas un saut de ligne et un retour de chariot
										-10 -> Erreur à la suppression du blob
Note                :	ADX0000863	IA	2006-03-31	Bruno Lapointe		Création
			ADX0001119	IA	2006-11-01	Alain Quirion		Validation pour les frais disponibles utilisés (TFR04), Suppression du code de validation TFR01
 *********************************************************************************************************************/
CREATE PROCEDURE [dbo].[VL_UN_OperTFR_IU] (
	@iBlobID INTEGER) -- ID du blob de la table CRI_Blob qui contient les objets de l’opération TFR à sauvegarder
AS
BEGIN
	DECLARE 
		@iResult INTEGER

	CREATE TABLE #WngAndErr(
		Code VARCHAR(5),
		Info1 VARCHAR(100),
		Info2 VARCHAR(100),
		Info3 VARCHAR(100)
	)

	-- Validation du blob
	EXECUTE @iResult = VL_UN_BlobFormatOfOper @iBlobID

	IF @iResult < 0
	BEGIN
		-- GEN04 -> Le blob n'existe pas
		-- GEN05 -> Update du blob par le service pas encore fait
		-- GEN06 -> Les deux derniers caractères ne sont pas un saut de ligne et un retour de chariot
		INSERT INTO #WngAndErr
			SELECT 
				CASE @iResult
					WHEN -1 THEN 'GEN04'
					WHEN -2 THEN 'GEN05'
					WHEN -3 THEN 'GEN06'
				END,
				'',
				'',
				''
	END
	ELSE
	BEGIN
		-- Tables temporaires créé à partir du blob contenant l'opération
		DECLARE @OperTable TABLE (
			LigneTrans INTEGER,
			OperID INTEGER,
			ConnectID INTEGER,
			OperTypeID CHAR(3),
			OperDate DATETIME)
	
		-- Tables temporaires créé à partir du blob contenant les opérations sur conventions et les subventions
		DECLARE @ConventionOperTable TABLE (
			LigneTrans INTEGER,
			ConventionOperID INTEGER,
			OperID INTEGER,
			ConventionID INTEGER,
			ConventionOperTypeID VARCHAR(3),
			ConventionOperAmount MONEY)
	
		-- Tables temporaires créé à partir du blob contenant les cotisations
		DECLARE @CotisationTable TABLE (
			LigneTrans INTEGER,
			CotisationID INTEGER,
			OperID INTEGER,
			UnitID INTEGER,
			EffectDate DATETIME,
			Cotisation MONEY,
			Fee MONEY,
			BenefInsur MONEY,
			SubscInsur MONEY,
			TaxOnInsur MONEY)
	
		-- Table temporaire des opérations dans les autres comptes
		DECLARE @OtherAccountOperTable TABLE (
			LigneTrans INTEGER,
			OtherAccountOperID INTEGER,
			OperID INTEGER,
			OtherAccountOperAmount MONEY)

		-- Table temporaire des frais disponibles utilisés
		DECLARE @AvailableFeeUseTable TABLE (
			iAvailableFeeUseID INTEGER,
			iUnitReductionID INTEGER,
			iOperID INTEGER,
			fUnitQtyUse MONEY
		)	

		-- Rempli la table temporaire de l'opération
		INSERT INTO @OperTable
			SELECT *
			FROM dbo.FN_UN_OperOfBlob(@iBlobID)
		
		-- Rempli la table temporaire des cotisations
		INSERT INTO @CotisationTable
			SELECT *
			FROM dbo.FN_UN_CotisationOfBlob(@iBlobID)
			
		-- Rempli la table temporaire des opérations sur conventions et des subventions
		INSERT INTO @ConventionOperTable
			SELECT *
			FROM dbo.FN_UN_ConventionOperOfBlob(@iBlobID)	
	
		-- Rempli la table temporaire des opérations dans les autres comptes
		INSERT INTO @OtherAccountOperTable
			SELECT *
			FROM dbo.FN_UN_OtherAccountOperOfBlob(@iBlobID)	

		-- Rempli la table temporaire des frais disponibles utilisés
		INSERT INTO @AvailableFeeUseTable
			SELECT *
			FROM dbo.FN_UN_AvailableFeeUseOfBlob(@iBlobID)

		-- GEN01 : Pas de détail d'opération
		IF NOT EXISTS (SELECT CotisationID FROM @CotisationTable) AND 
			NOT EXISTS (SELECT ConventionOperID FROM @ConventionOperTable)
			INSERT INTO #WngAndErr
				SELECT 
					'GEN01',
					'',
					'',
					''
	
		-- GEN02 : Pas d'opération
		IF NOT EXISTS (SELECT OperID FROM @OperTable) 
			INSERT INTO #WngAndErr
				SELECT 
					'GEN02',
					'',
					'',
					''
	
		-- GEN03 : Plus d'une opération avec le même OperID
		IF EXISTS (SELECT OperID, COUNT(OperID) FROM @OperTable GROUP BY OperID HAVING COUNT(OperID) > 1) 
			INSERT INTO #WngAndErr
				SELECT 
					'GEN03',
					'',
					'',
					''
	
		-- Variable qu'on a besoin dans plus d'une validation
		DECLARE
			@LastVerifDate DATETIME

		SELECT 
			@LastVerifDate = LastVerifDate
		FROM Un_Def

		-- Validation sur TFR
		IF EXISTS (
				SELECT OperID
				FROM @OperTable
				WHERE OperTypeID = 'TFR')
		BEGIN				
			-- TFR02 -> La date d’opération doit être plus grande que la date de barrure du système
			INSERT INTO #WngAndErr
				SELECT 
					'TFR02',
					'',
					'',
					''
				FROM @OperTable OT
				LEFT JOIN Un_Oper O ON OT.OperID = O.OperID
				WHERE (	ISNULL(dbo.FN_CRQ_DateNoTime(O.OperDate),@LastVerifDate+1) <= dbo.FN_CRQ_DateNoTime(@LastVerifDate)
						OR ISNULL(dbo.FN_CRQ_DateNoTime(OT.OperDate),0) <= dbo.FN_CRQ_DateNoTime(@LastVerifDate)
						)
				  AND OT.OperTypeID = 'TFR'
	
			-- TFR03 -> Le montant de frais disponibles retirés d’une convention ne doit pas être plus élevé que le solde de frais disponibles de cette convention.
			INSERT INTO #WngAndErr
				SELECT
					'TFR03',
					CAST(N.LigneTrans AS VARCHAR(100)),
					C.ConventionNo,
					''
				FROM ( -- Montant qu'on veut sauvegarder
					SELECT 
						ConventionID,
						ConventionOperAmount = SUM(CO.ConventionOperAmount) * -1,
						LigneTrans = MAX(CO.LigneTrans)
					FROM @ConventionOperTable CO
					JOIN @OperTable OT ON OT.OperID = CO.OperID
					WHERE OT.OperTypeID = 'TFR'
					GROUP BY CO.ConventionID) N
				JOIN dbo.Un_Convention C ON C.ConventionID = N.ConventionID
				-- Montant retiré avant la modification (si pas ajout)
				LEFT JOIN (
					SELECT 
						ConventionID,
						ConventionOperAmount = SUM(ConventionOperAmount) * -1
					FROM Un_ConventionOper CO
					JOIN @OperTable OT ON OT.OperID = CO.OperID
					WHERE OT.OperTypeID = 'TFR'
					GROUP BY ConventionID) O ON O.ConventionID = N.ConventionID
				LEFT JOIN ( -- Montant de frais disponible avant modification ou ajout
					SELECT 
						ConventionID,
						ConventionOperAmount = SUM(ConventionOperAmount) 
					FROM Un_ConventionOper
					WHERE ConventionOperTypeID = 'FDI'
					GROUP BY ConventionID) FDI ON FDI.ConventionID = N.ConventionID
				WHERE (N.ConventionOperAmount > 0) -- Vérifie si on retire des frais disponibles
				  AND (N.ConventionOperAmount > ISNULL(O.ConventionOperAmount,0)) -- Vérifie si le nouveau montant retiré est plus grand que l'ancien
				  AND (N.ConventionOperAmount - ISNULL(O.ConventionOperAmount,0) > ISNULL(FDI.ConventionOperAmount,0)) -- Vérifie que les frais soient disponibles

			DECLARE @NbUnit MONEY,
				@NbUnitUse MONEY

			-- Calcul du nombre d'unités de la convention actuelles
			SELECT @NbUnit = SUM(UnitQty)
			FROM dbo.Un_Convention C
			JOIN(	SELECT U.ConventionID
				FROM @CotisationTable CO 
				JOIN dbo.Un_Unit U ON U.UnitID = CO.UnitID) C1 ON C1.ConventionID = C.ConventionID
			JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID	

			-- Calcul du nombre d'unité utilisé
			SELECT @NbUnitUse = SUM(fUnitQtyUse)
			FROM @AvailableFeeUseTable				
			
			-- TFR04 -> Le nombre d’unité pouvant être sélectionné pour le TFR ne doit pas dépasser le nombre d’unité du groupe d’unités dans lequel on transfère les frais disponibles			
			IF @NbUnitUse > @NbUnit
			INSERT INTO #WngAndErr
					SELECT 
						'TFR04',
						'',
						'',
						''

			-- Calcul du nombre d'unités transférés
			SELECT @NbUnitUse = @NbUnitUse + ISNULL(SUM(fUnitQtyUse),0)
			FROM Un_AvailableFeeUse A
			JOIN Un_Cotisation C ON C.OperID = A.OperID
			JOIN dbo.Un_Unit U ON U.UnitID = C.UnitID
			JOIN @CotisationTable CT ON CT.UnitID=U.UnitID

			-- TFR05 -> Le nombre d’unité pouvant être transférés pour le TFR ne doit pas dépasser le nombre d’unité du groupe d’unités dans lequel on transfère les frais disponibles			
			IF @NbUnitUse > @NbUnit
			INSERT INTO #WngAndErr
					SELECT 
						'TFR05',
						'',
						'',
						''

		END
	END

	-- Fait le ménage dans les blob vieux de 2 jours ou plus
	IF @iResult <= 0
	BEGIN
		DELETE 
		FROM CRI_Blob
		WHERE dtBlob <= DATEADD(DAY,-2,GETDATE())
	
		IF @@ERROR <> 0
		AND @iResult > 0
			SET @iResult = -10 -- Erreur à la suppression du blob
	END

	-- Retourne le dataset des erreurs
	SELECT *
	FROM #WngAndErr

	-- Supprime la table temporaire des erreurs
	DROP TABLE #WngAndErr
	RETURN @iResult
END


