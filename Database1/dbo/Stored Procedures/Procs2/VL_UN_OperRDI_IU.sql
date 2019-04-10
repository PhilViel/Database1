/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : VL_UN_OperRDI_IU
Nom du service  : Valider une opération RDI
But             : Ce service est dérivée de VL_UN_OperCHQ_IU
Facette         : OPER

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -------------------------------------
                      iBlobID                    Identifiant unique du blob

Paramètres de sortie: 
vcCode   VARCHAR(5)    Code de d’erreur
vcInfo1  VARCHAR(100)  Première information supplémentaire, permet de faire des messages détaillés.
vcInfo2  VARCHAR(100)  Deuxième information supplémentaire.
vcInfo3  VARCHAR(100)  Troisième information supplémentaire.
Erreurs possibles du Dataset :
Code RDI01 Message Le montant de l’opération doit être plus grand que 0.00$.
Code RDI02 Message La date d’opération doit être plus grande que la date de barrure du système.
Code RDI03 Info1 Nom et prénom du bénéficiaire 
           Info2 Année où le maximum est dépassé
           Message Le montant d'épargne et de frais cotisés pour cette année dépasse le maximum annuel.
Code RDI04 Message Les multiples opérations ne sont pas gérées pour les RDI.
Code RDI05 Le montant d’assurance souscripteur, d’assurance bénéficiaire ou de taxes est différent de celui du dépôt théorique du groupe d’unités.
Code GEN01 Message Pas de détail d'opération.
Code GEN02 Message Pas d'opération.
Code GEN03 Message Plus d'une opération avec le même OperID.
Code GEN04 Message Le blob n'existe pas.
Code GEN05 Message Update du blob par le service par encore fait.
Code GEN06 Message Les deux derniers caractères ne sont pas un saut de ligne et un retour de chariot.
ReturnValue :
 > 0 : Réussite
<= 0 : Erreurs.
  -1 -> Le blob n'existe pas
  -2 -> Update du blob par le service par encore fait
  -3 -> Les deux derniers caractères ne sont pas un saut de ligne et un retour de chariot
 -10 -> Erreur à la suppression du blob

Exemple d’appel     : EXECUTE [dbo].[VL_UN_OperCHQ_IU] 418251

Historique des modifications:
               Date          Programmeur        Description
               ------------  ------------------ --------------------------------------
               2010-03-24    Danielle Côté      Création
****************************************************************************************************/
CREATE PROCEDURE [dbo].[VL_UN_OperRDI_IU] 
(
   @iBlobID INTEGER
)
AS
BEGIN
	DECLARE 
		@iResult INTEGER

   CREATE TABLE #WngAndErr(
		Code VARCHAR(5),
		Info1 VARCHAR(100),
		Info2 VARCHAR(100),
		Info3 VARCHAR(100))

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
			@LastVerifDate DATETIME,
			@SumConventionOper MONEY,
			@SumCotisation MONEY,
			@TheoricalAmount FLOAT,		
			@TheoricalSousAssAmount FLOAT,	
			@TheoricalBenefAssAmount FLOAT,	
			@TheoricalTaxesAmount FLOAT,
			@RealAmount FLOAT,		
			@RealSousAssAmount FLOAT,	
			@RealBenefAssAmount FLOAT,	
			@RealTaxesAmount FLOAT,
			@bError BIT,
			@UnitID INTEGER

		SET @bError = 0
		SET @SumConventionOper = 0
		SET @SumCotisation = 0
	
		SELECT 
			@LastVerifDate = LastVerifDate
		FROM Un_Def

		SELECT 
			@SumCotisation = ISNULL(SUM(Cotisation+Fee+BenefInsur+SubscInsur+TaxOnInsur),0)
		FROM @CotisationTable
	
		SELECT 
			@SumConventionOper = ISNULL(SUM(ConventionOperAmount),0)
		FROM @ConventionOperTable		
	
		-- Validation sur RDI
		IF EXISTS (
				SELECT OperID
				FROM @OperTable
				WHERE OperTypeID = 'RDI')
		BEGIN
			-- RDI01 -> Le montant de l’opération doit être plus grand que 0.00$.
			IF @SumCotisation + @SumConventionOper <= 0
				INSERT INTO #WngAndErr
					SELECT 
						'RDI01',
						'',
						'',
						''
				
			-- RDI02 -> La date d’opération doit être plus grande que la date de barrure du système
			INSERT INTO #WngAndErr
				SELECT 
					'RDI02',
					'',
					'',
					''
				FROM @OperTable OT
				LEFT JOIN Un_Oper O ON OT.OperID = O.OperID
				WHERE ISNULL(dbo.FN_CRQ_DateNoTime(O.OperDate),@LastVerifDate+1) <= dbo.FN_CRQ_DateNoTime(@LastVerifDate)
					OR ISNULL(dbo.FN_CRQ_DateNoTime(OT.OperDate),0) <= dbo.FN_CRQ_DateNoTime(@LastVerifDate)

			-- Va chercher le maximum annuel de chacun des bénéficiaires qui sont affecté par cette opération
			SELECT
				V.BeneficiaryID,
				BC.BeneficiaryCeilingCfgID
			INTO #Tmp_BeneficiaryCeilingCfgRDI
			FROM (
				SELECT
					C.BeneficiaryID,
					EffectDate = MAX(BC.EffectDate)
				FROM @CotisationTable Ct
				JOIN dbo.Un_Unit U ON Ct.UnitID = U.UnitID
				JOIN dbo.Un_Convention C ON U.ConventionID = C.ConventionID
				JOIN dbo.Mo_Human B ON C.BeneficiaryID = B.HumanID
				JOIN Un_BeneficiaryCeilingCfg BC ON ISNULL(B.BirthDate, '1985-01-01') >= BC.EffectDate
				GROUP BY C.BeneficiaryID
				) V 
			JOIN Un_BeneficiaryCeilingCfg BC ON V.EffectDate = BC.EffectDate

			-- RDI03 -> Le montant d'épargne et de frais cotisés pour cette année dépasse le maximum annuel
			INSERT INTO #WngAndErr
				SELECT 
					'RDI03',
					H.LastName+', '+H.FirstName,
					CAST(NCt.YearEffectDate AS CHAR(4)),
					''
				FROM dbo.Un_Beneficiary B
				JOIN dbo.Mo_Human H ON H.HumanID = B.BeneficiaryID
				JOIN #Tmp_BeneficiaryCeilingCfgRDI TBC ON TBC.BeneficiaryID = B.BeneficiaryID
				JOIN Un_BeneficiaryCeilingCfg BC ON BC.BeneficiaryCeilingCfgID = TBC.BeneficiaryCeilingCfgID
				JOIN (
					SELECT 
						C.BeneficiaryID,
						YearEffectDate = YEAR(EffectDate),
						SumCotisationFee = SUM(Cotisation+Fee)
					FROM @CotisationTable CT
					JOIN dbo.Un_Unit U ON Ct.UnitID = U.UnitID
					JOIN dbo.Un_Convention C ON U.ConventionID = C.ConventionID
					GROUP BY 
						C.BeneficiaryID,
						YEAR(EffectDate)
					) NCt ON NCt.BeneficiaryID = B.BeneficiaryID
				LEFT JOIN (
					SELECT 
						B.BeneficiaryID,
						YearEffectDate = YEAR(Ct.EffectDate),
						SumCotisationFee = SUM(Ct.Cotisation+Ct.Fee)
					FROM dbo.Un_Beneficiary B
					JOIN dbo.Un_Convention C ON C.BeneficiaryID = B.BeneficiaryID
					JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
					JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
					JOIN Un_Oper O ON O.OperID = Ct.OperID
					LEFT JOIN @CotisationTable NCt ON NCt.CotisationID = Ct.CotisationID
					WHERE B.BeneficiaryID IN (
								SELECT C.BeneficiaryID 
								FROM @CotisationTable Ct
								JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
								JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID)
						AND NCt.CotisationID IS NULL
						AND O.OperTypeID <> 'TIN'
					GROUP BY 
						B.BeneficiaryID,
						YEAR(Ct.EffectDate)
					) Ct ON Ct.BeneficiaryID = B.BeneficiaryID AND NCt.YearEffectDate = Ct.YearEffectDate
				GROUP BY
					B.BeneficiaryID,
					H.LastName,
					H.FirstName,
					NCt.YearEffectDate,
					BC.AnnualCeiling
				HAVING SUM(NCt.SumCotisationFee+ISNULL(Ct.SumCotisationFee,0)) > BC.AnnualCeiling

			DROP TABLE #Tmp_BeneficiaryCeilingCfgRDI

			-- RDI04 : Les multiples opérations ne sont pas géré pour les RDI 
			IF EXISTS (SELECT COUNT(OperID) FROM @OperTable HAVING COUNT(OperID) > 1) 
				INSERT INTO #WngAndErr
					SELECT 
						'RDI04',
						'',
						'',
						''
			
			INSERT INTO #WngAndErr
				SELECT DISTINCT
					'RDI05',
					CT.LigneTrans,
					'',
					''										
				FROM @CotisationTable CT
				JOIN dbo.Un_Unit U ON U.UnitID = CT.UnitID
				JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
				JOIN Un_Modal M ON M.ModalID = U.ModalID
				LEFT JOIN Un_HalfSubscriberInsurance HSI ON HSI.ModalID = M.ModalID
				LEFT JOIN Un_BenefInsur BI ON BI.BenefInsurID = U.BenefInsurID
				LEFT JOIN (
						SELECT MIN(UnitID) AS UnitID 
						FROM dbo.Un_Unit 
						GROUP BY ConventionID 
						) MU ON MU.UnitID = U.UnitID
				JOIN Un_Plan P ON P.PlanID = C.PlanID
				LEFT JOIN Mo_State ST ON ST.StateID = S.StateID
				WHERE ROUND(SubscInsur,2) <> CASE  
									WHEN U.WantSubscriberInsurance = 0 THEN 0
									WHEN MU.UnitID IS NULL THEN 
										ROUND(U.UnitQty * ISNULL(HSI.HalfSubscriberInsuranceRate,M.SubscriberInsuranceRate),2)
									WHEN U.UnitQty >= 1 THEN
										ROUND(ROUND(1 * M.SubscriberInsuranceRate,2) + 
										((U.UnitQty-1) * ISNULL(HSI.HalfSubscriberInsuranceRate,M.SubscriberInsuranceRate)),2)
									ELSE 
										ROUND(U.UnitQty * M.SubscriberInsuranceRate,2) 
								END
					OR ROUND(BenefInsur,2) <> ROUND(ISNULL(BI.BenefInsurRate,0),2)
					OR ROUND(TaxOnInsur,2) <> CASE 
								WHEN U.WantSubscriberInsurance = 0 THEN dbo.FN_CRQ_TaxRounding(ISNULL(BI.BenefInsurRate,0) * ISNULL(St.StateTaxPct,0))
								WHEN MU.UnitID IS NULL THEN 
									dbo.FN_CRQ_TaxRounding(ROUND((U.UnitQty * ISNULL(HSI.HalfSubscriberInsuranceRate,M.SubscriberInsuranceRate) +
									ISNULL(BI.BenefInsurRate,0)),2) * ISNULL(St.StateTaxPct,0))				
								WHEN U.UnitQty >= 1 THEN 									
									dbo.FN_CRQ_TaxRounding(
												ROUND((	ISNULL(BI.BenefInsurRate,0) +
														(1 * ISNULL(M.SubscriberInsuranceRate,0)) +
														((U.UnitQty-1) * ISNULL(HSI.HalfSubscriberInsuranceRate,ISNULL(M.SubscriberInsuranceRate,0)))	),2) *
														ISNULL(St.StateTaxPct,0))
								ELSE 
									dbo.FN_CRQ_TaxRounding((ROUND(M.SubscriberInsuranceRate * U.UnitQty,2) + ISNULL(BI.BenefInsurRate,0)) * ISNULL(St.StateTaxPct,0))
								END			
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


