/***********************************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	VL_UN_OperTIN_IU
Description         :	Procédure de validation avant la sauvegarde d’ajout/modification de transfert IN.
Exemple d'appel		:   EXEC dbo.VL_UN_OperTIN_IU 2
Valeurs de retours  :	Dataset : (Vide = pas d’erreur dans les validations)
									vcCode	VARCHAR(5)	Code de d’erreur
									vcInfo1	VARCHAR(100)	Première information supplémentaire, permet de faire des messages détaillés.
									vcInfo2	VARCHAR(100)	Deuxième information supplémentaire.
									vcInfo3	VARCHAR(100)	Troisième information supplémentaire.
								Erreurs possibles du Dataset :
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

									GEN09 -> Le bénéfiaire actif n'est pas le même qu'à la date effective
												Info1 : Vide					Info2 : Vide						Info3 : Vide
									GEN10 -> La date d'effectivité de la transaction doit être plus grande ou égale à la date 
											 de signature de la convention : dtMinSignatureDate
												Info1 : Vide					Info2 : Vide						Info3 : Vide
									GEN11 -> La de l'opération de la transaction doit être plus grande ou égale à la date de signature
											 de la convention : dtMinSignatureDate
												Info1 : Vide					Info2 : Vide						Info3 : Vide
									GEN12 -> Transaction refusée, car la convention est à l'état "Proposition"
												Info1 : Vide					Info2 : Vide						Info3 : Vide

									Code	TIN01
									Message	Le montant de l’opération doit être plus grand que 0.00$.
									Code	TIN02
									Message	La date d’opération doit être plus grande que la date de barrure du système.
									Code	TIN03
									Message	Les multiples opérations ne sont pas gérées pour les TIN.
									Code	TIN04
									Le montant d’assurance souscripteur, d’assurance bénéficiaire ou de taxes est différent de celui du dépôt théorique du groupe d’unités.
									Code	TIN05
									Le NAS du bénéficiaire est oblifatoire
								ReturnValue :
									> 0 : Réussite
									<= 0 : Erreurs.
										-1 -> Le blob n'existe pas
										-2 -> Update du blob par le service par encore fait
										-3 -> Les deux derniers caractères ne sont pas un saut de ligne et un retour de chariot
										-10 -> Erreur à la suppression du blob
Note                :	ADX0000925	IA	2006-05-08	Bruno Lapointe		Création
								ADX0002426	BR	2007-05-23	Bruno Lapointe			Gestion de la table Un_CESP.
												2010-04-06	Jean-François Gauthier	Ajout des validations sur les champs 
																					concernant la date d'opération et la date effective	
												2010-04-08	Jean-François Gauthier	Ajout de la validation du statut de la convention
																			afin de bloquer le traitement si l'état = "Proposition"																																						
												2010-11-26	Pierre Paquet			Correction: Utilisation de @ConventionTable
        2015-12-01      Steeve Picard               Utilisation de la nouvelle fonction «fntCONV_ObtenirStatutConventionEnDate_PourTous»
 *********************************************************************************************************************/
CREATE PROCEDURE [dbo].[VL_UN_OperTIN_IU] (
	@iBlobID INT) -- ID du blob de la table CRI_Blob qui contient les objets de l’opération TIN à sauvegarder
AS
BEGIN
	DECLARE 
		@iResult INT

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
							LigneTrans	INT,
							OperID		INT,
							ConnectID	INT,
							OperTypeID	CHAR(3),
							OperDate	DATETIME,
							iIDBeneficiaire INT)	-- 2010-04-06 : JFG : Ajout du champ
	
		-- Tables temporaires créé à partir du blob contenant les opérations sur conventions et les subventions
		DECLARE @ConventionOperTable TABLE (
										LigneTrans			INT,
										ConventionOperID	INT,
										OperID				INT,
										ConventionID		INT,
										ConventionOperTypeID VARCHAR(3),
										ConventionOperAmount MONEY,
										dtDateSignature		DATETIME)-- 2010-04-06 : JFG : Ajout du champ
	
		-- Tables temporaires créé à partir du blob contenant les cotisations
		DECLARE @CotisationTable TABLE (
									LigneTrans		INT,
									CotisationID	INT,
									OperID			INT,
									UnitID			INT,
									EffectDate		DATETIME,
									Cotisation		MONEY,
									Fee				MONEY,
									BenefInsur		MONEY,
									SubscInsur		MONEY,
									TaxOnInsur		MONEY,
									iIDBeneficiaire INT,	-- 2010-04-06 : JFG : Ajout du champ
									vcEtatConv		VARCHAR(3)) -- 2010-04-08 : JFG : Ajout du champ
	
		-- Tables temporaires créé à partir du blob contenant les données du transfert IN.
		DECLARE @tTIN TABLE (
			OperID INT,
			ExternalPlanID INT,
			tiBnfRelationWithOtherConvBnf TINYINT,
			vcOtherConventionNo VARCHAR(15),
			dtOtherConvention DATETIME,
			tiOtherConvBnfRelation TINYINT,
			bAIP BIT,
			bACESGPaid BIT,
			bBECInclud BIT,
			bPGInclud BIT,
			fYearBnfCot MONEY,
			fBnfCot MONEY,
			fNoCESGCotBefore98 MONEY,
			fNoCESGCot98AndAfter MONEY,
			fCESGCot MONEY,
			fCESG MONEY,
			fCLB MONEY,
			fAIP MONEY,
			fMarketValue MONEY,
			bPendingApplication BIT)

		-- Rempli la table temporaire de l'opération
		INSERT INTO @OperTable
		(
			LigneTrans,
			OperID,
			ConnectID,
			OperTypeID,
			OperDate
		)
		SELECT 
			LigneTrans,
			OperID,
			ConnectID,
			OperTypeID,
			OperDate
		FROM 
			dbo.FN_UN_OperOfBlob(@iBlobID)
		
		-- Rempli la table temporaire des cotisations
		INSERT INTO @CotisationTable
		(
			LigneTrans,
			CotisationID,
			OperID,
			UnitID,
			EffectDate,
			Cotisation,
			Fee,
			BenefInsur,
			SubscInsur,
			TaxOnInsur
		)
		SELECT 
			LigneTrans,
			CotisationID,
			OperID,
			UnitID,
			EffectDate,
			Cotisation,
			Fee,
			BenefInsur,
			SubscInsur,
			TaxOnInsur
		FROM 
			dbo.FN_UN_CotisationOfBlob(@iBlobID)
			
		-- Rempli la table temporaire des opérations sur conventions et des subventions
		INSERT INTO @ConventionOperTable
		(
			LigneTrans,
			ConventionOperID,
			OperID,
			ConventionID,
			ConventionOperTypeID,
			ConventionOperAmount
		)
		SELECT 
			LigneTrans,
			ConventionOperID,
			OperID,
			ConventionID,
			ConventionOperTypeID,
			ConventionOperAmount 
		FROM 
			dbo.FN_UN_ConventionOperOfBlob(@iBlobID)	
	
		-- Rempli la table temporaire des données de TIN
		INSERT INTO @tTIN
			SELECT *
			FROM dbo.FN_UN_TINOfBlob(@iBlobID)	

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
/*	
		--*************** 2010-04-06 : Ajout : JFG  ****************************
		-- Insertion du bénéficiaire à la date d'opération
		UPDATE o
		SET o.iIDBeneficiaire = fnt.iID_Nouveau_Beneficiaire
		FROM
			@OperTable o
			INNER JOIN @ConventionOperTable co
				ON o.OperID = co.OperID
			INNER JOIN @CotisationTable ct
				ON o.OperID = ct.OperID
			CROSS APPLY (SELECT iID_Nouveau_Beneficiaire FROM dbo.fntCONV_RechercherChangementsBeneficiaire(NULL, NULL, co.ConventionID, NULL, o.OperDate, NULL,1, NULL, NULL, NULL, NULL, NULL, NULL)) fnt
				
		-- Insertion du bénéficiaire à la date effective
		UPDATE	ct
		SET		ct.iIDBeneficiaire = fnt.iID_Nouveau_Beneficiaire
		FROM
			@OperTable o
			INNER JOIN @ConventionOperTable co
				ON o.OperID = co.OperID
			INNER JOIN @CotisationTable ct
				ON o.OperID = ct.OperID
			CROSS APPLY (SELECT iID_Nouveau_Beneficiaire FROM dbo.fntCONV_RechercherChangementsBeneficiaire(NULL, NULL, co.ConventionID, NULL, ct.EffectDate, NULL,1, NULL, NULL, NULL, NULL, NULL, NULL)) fnt		
		
		-- Insertion de la date de signature de la convention
		UPDATE	co
		SET		dtDateSignature = fnt.dtMinSignatureDate
		FROM 
			@ConventionOperTable co
			CROSS APPLY (SELECT dtMinSignatureDate = MIN(dtMinSignatureDate) FROM dbo.fntCONV_ObtenirDatesConvention(co.ConventionID, GETDATE())) fnt
		
		-- GEN09 : validation du bénéficiaire
		IF EXISTS(	SELECT 1 
					FROM 
						@OperTable o
						INNER JOIN @CotisationTable ct
							ON o.OperID = ct.OperID
					WHERE
						o.iIDBeneficiaire <> ct.iIDBeneficiaire )
			BEGIN
				INSERT INTO #WngAndErr
				(
					Code,
					Info1,
					Info2,
					Info3
				)
				SELECT 
					'GEN09',
					'',
					'',
					''
			END

		-- GEN10 : validation de la date effective versus la date de signature (début d'entrée en vigueur)
		IF EXISTS (	SELECT	1
					FROM
						@CotisationTable ct
						INNER JOIN @ConventionOperTable co
							ON ct.OperID = co.OperID
					WHERE
						ct.EffectDate < co.dtDateSignature )
			BEGIN
				INSERT INTO #WngAndErr
				(
					Code,
					Info1,
					Info2,
					Info3
				)
				SELECT 
					'GEN10',
					'',
					'',
					''
			END		
			
		-- GEN11 : validation de la date d'opération versus la date de signature (début de régime)
		IF EXISTS (	SELECT	1
					FROM
						@OperTable o
						INNER JOIN @ConventionOperTable co
							ON o.OperID = co.OperID
					WHERE
						o.OperDate < co.dtDateSignature )
			BEGIN
				INSERT INTO #WngAndErr
				(
					Code,
					Info1,
					Info2,
					Info3
				)
				SELECT 
					'GEN11',
					'',
					'',
					''
			END		
		
		-- ************ FIN MODIFICICATION DU 2010-04-06 *********************
*/

		--*************** 2010-04-06 : Ajout : JFG  ****************************
		-- 2010-11-26 
		DECLARE @ConventionTable TABLE (
										OperID INT,
										ConventionID INT,
										dtDateSignature DATETIME)

		-- 2010-11-26  Remplir la table des conventions ID
		INSERT INTO @ConventionTable 
		SELECT CT.OperID, U.ConventionID, null 
		FROM @CotisationTable CT
			INNER JOIN dbo.UN_Unit U ON U.UnitID = CT.UnitID

		-- Insertion du bénéficiaire à la date d'opération
		UPDATE o
		SET o.iIDBeneficiaire = fnt.iID_Nouveau_Beneficiaire
		FROM
			@OperTable o
			--INNER JOIN @ConventionOperTable co
			INNER JOIN @ConventionTable co
				ON o.OperID = co.OperID
			INNER JOIN @CotisationTable ct
				ON o.OperID = ct.OperID
			CROSS APPLY (SELECT iID_Nouveau_Beneficiaire FROM dbo.fntCONV_RechercherChangementsBeneficiaire(NULL, NULL, co.ConventionID, NULL, o.OperDate, NULL,1, NULL, NULL, NULL, NULL, NULL, NULL)) fnt
				
		-- Insertion du bénéficiaire à la date effective
		UPDATE	ct
		SET		ct.iIDBeneficiaire = fnt.iID_Nouveau_Beneficiaire
		FROM
			@OperTable o
			--INNER JOIN @ConventionOperTable co
			INNER JOIN @ConventionTable co
				ON o.OperID = co.OperID
			INNER JOIN @CotisationTable ct
				ON o.OperID = ct.OperID
			CROSS APPLY (SELECT iID_Nouveau_Beneficiaire FROM dbo.fntCONV_RechercherChangementsBeneficiaire(NULL, NULL, co.ConventionID, NULL, ct.EffectDate, NULL,1, NULL, NULL, NULL, NULL, NULL, NULL)) fnt		
		
		-- Insertion de la date de signature de la convention
		UPDATE	co
		SET		dtDateSignature = fnt.dtMinSignatureDate
		FROM 
			--@ConventionOperTable co
			@ConventionTable co
			CROSS APPLY (SELECT dtMinSignatureDate = MIN(dtMinSignatureDate) FROM dbo.fntCONV_ObtenirDatesConvention(co.ConventionID, GETDATE())) fnt
		
		-- GEN09 : validation du bénéficiaire
		IF EXISTS(	SELECT 1 
					FROM 
						@OperTable o
						INNER JOIN @CotisationTable ct
							ON o.OperID = ct.OperID
					WHERE
						o.iIDBeneficiaire <> ct.iIDBeneficiaire )
			BEGIN
				INSERT INTO #WngAndErr
				(
					Code,
					Info1,
					Info2,
					Info3
				)
				SELECT 
					'GEN09',
					'',
					'',
					''
			END

		-- GEN10 : validation de la date effective versus la date de signature (début d'entrée en vigueur)
		IF EXISTS (	SELECT	1
					FROM
						@CotisationTable ct
						--INNER JOIN @ConventionOperTable co
						INNER JOIN @ConventionTable co
							ON ct.OperID = co.OperID
					WHERE
						ct.EffectDate < co.dtDateSignature )
			BEGIN
				INSERT INTO #WngAndErr
				(
					Code,
					Info1,
					Info2,
					Info3
				)
				SELECT 
					'GEN10',
					'',
					'',
					''
			END		
			
		-- GEN11 : validation de la date d'opération versus la date de signature (début de régime)
		IF EXISTS (	SELECT	1
					FROM
						@OperTable o
						--INNER JOIN @ConventionOperTable co
						INNER JOIN @ConventionTable co
							ON o.OperID = co.OperID
					WHERE
						o.OperDate < co.dtDateSignature )
			BEGIN
				INSERT INTO #WngAndErr
				(
					Code,
					Info1,
					Info2,
					Info3
				)
				SELECT 
					'GEN11',
					'',
					'',
					''
			END		
		
		-- ************ FIN MODIFICICATION DU 2010-04-06 *********************

		-- *************** 2010-04-08 : Ajout : JFG  *************************
		-- GEN12 : Validation de l'état des conventions
		UPDATE	ct
		SET		ct.vcEtatConv = s.ConventionStateID
		FROM
				@CotisationTable ct
				INNER JOIN dbo.Un_Unit u ON ct.UnitID = u.UnitID
                    INNER JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(GETDATE(), NULL) s on s.ConventionID = u.ConventionID
		
		IF EXISTS(SELECT 1 FROM @CotisationTable WHERE vcEtatConv = 'PRP')
			BEGIN
				INSERT INTO #WngAndErr
				(
					Code,
					Info1,
					Info2,
					Info3
				)
				SELECT 
					'GEN12',
					'',
					'',
					''
			END
		-- ************ FIN MODIFICICATION DU 2010-04-08 *********************
		
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
			@UnitID INT

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
	
		-- Validation sur TIN
		IF EXISTS (
				SELECT OperID
				FROM @OperTable
				WHERE OperTypeID = 'TIN')
		BEGIN
			-- TIN01 -> Le montant de l’opération doit être plus grand que 0.00$.
			IF @SumCotisation + @SumConventionOper <= 0
				INSERT INTO #WngAndErr
					SELECT 
						'TIN01',
						'',
						'',
						''
				
			-- TIN02 -> La date d’opération doit être plus grande que la date de barrure du système
			IF EXISTS (
				SELECT *
				FROM @OperTable OT
				LEFT JOIN Un_Oper O ON OT.OperID = O.OperID
				WHERE ISNULL(dbo.FN_CRQ_DateNoTime(O.OperDate),@LastVerifDate+1) <= dbo.FN_CRQ_DateNoTime(@LastVerifDate)
					OR ISNULL(dbo.FN_CRQ_DateNoTime(OT.OperDate),0) <= dbo.FN_CRQ_DateNoTime(@LastVerifDate)
				)
				AND(	EXISTS ( -- Nouvelle opération
							SELECT *
							FROM @OperTable OT
							LEFT JOIN Un_Oper O ON O.OperID = OT.OperID
							WHERE O.OperID IS NULL
							)
					OR	EXISTS ( -- Opération modifié
							SELECT *
							FROM @OperTable OT
							JOIN Un_Oper O ON O.OperID = OT.OperID
							WHERE OT.OperDate <> O.OperDate
								OR OT.OperTypeID <> O.OperTypeID
							)
					OR	EXISTS ( -- Nouvelle cotisation
							SELECT *
							FROM @CotisationTable CtT
							LEFT JOIN Un_Cotisation Ct ON Ct.CotisationID = CtT.CotisationID
							WHERE Ct.CotisationID IS NULL
							)
					OR	EXISTS ( -- Cotisation modifiée
							SELECT *
							FROM @CotisationTable CtT
							JOIN Un_Cotisation Ct ON Ct.OperID = CtT.OperID
							WHERE CtT.OperID <> Ct.OperID
								OR CtT.UnitID <> Ct.UnitID
								OR CtT.EffectDate <> Ct.EffectDate
								OR CtT.Cotisation <> Ct.Cotisation
								OR CtT.Fee <> Ct.Fee
								OR CtT.BenefInsur <> Ct.BenefInsur
								OR CtT.SubscInsur <> Ct.SubscInsur
								OR CtT.TaxOnInsur <> Ct.TaxOnInsur
							)
					OR	EXISTS ( -- Nouvelle opération sur convention
							SELECT *
							FROM @ConventionOperTable CT
							LEFT JOIN Un_ConventionOper C ON C.ConventionOperID = CT.ConventionOperID
							WHERE CT.ConventionOperTypeID NOT IN ('SUB','SU+','BEC')
								AND C.ConventionOperID IS NULL
							)
					OR	EXISTS ( -- Opération sur convention modifiée
							SELECT *
							FROM @ConventionOperTable CT
							JOIN Un_ConventionOper C ON C.ConventionOperID = CT.ConventionOperID
							WHERE CT.ConventionOperTypeID NOT IN ('SUB','SU+','BEC')
								AND( CT.OperID <> C.OperID
									OR CT.ConventionID <> C.ConventionID
									OR CT.ConventionOperTypeID <> C.ConventionOperTypeID
									OR CT.ConventionOperAmount <> C.ConventionOperAmount
									)
							)
					OR	EXISTS ( -- Nouvelle SCEE, SCEE+ ou BEC
							SELECT *
							FROM @ConventionOperTable CT
							LEFT JOIN Un_CESP C ON C.iCESPID = CT.ConventionOperID
							WHERE CT.ConventionOperTypeID IN ('SUB','SU+','BEC')
								AND C.iCESPID IS NULL
							)
					OR	EXISTS ( -- SCEE modifiée
							SELECT *
							FROM @ConventionOperTable CT
							JOIN Un_CESP C ON C.iCESPID = CT.ConventionOperID
							WHERE CT.ConventionOperTypeID = 'SUB'
								AND( CT.OperID <> C.OperID
									OR CT.ConventionOperAmount <> C.fCESG
									)
							)
					OR	EXISTS ( -- SCEE+ modifiée
							SELECT *
							FROM @ConventionOperTable CT
							JOIN Un_CESP C ON C.iCESPID = CT.ConventionOperID
							WHERE CT.ConventionOperTypeID = 'SU+'
								AND( CT.OperID <> C.OperID
									OR CT.ConventionOperAmount <> C.fACESG
									)
							)
					OR	EXISTS ( -- BEC modifié
							SELECT *
							FROM @ConventionOperTable CT
							JOIN Un_CESP C ON C.iCESPID = CT.ConventionOperID
							WHERE CT.ConventionOperTypeID = 'BEC'
								AND( CT.OperID <> C.OperID
									OR CT.ConventionOperAmount <> C.fCLB
									)
							)
					)
				INSERT INTO #WngAndErr
					SELECT 
						'TIN02',
						'',
						'',
						''

			-- TIN03 : Les multiples opérations ne sont pas géré pour les TIN 
			IF EXISTS (SELECT COUNT(OperID) FROM @OperTable HAVING COUNT(OperID) > 1) 
				INSERT INTO #WngAndErr
					SELECT 
						'TIN03',
						'',
						'',
						''

			INSERT INTO #WngAndErr
				SELECT DISTINCT
					'TIN04',
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
					OR ROUND(TaxOnInsur,2) <> CASE U.WantSubscriberInsurance
									WHEN 0 THEN ROUND(((ISNULL(BI.BenefInsurRate,0) * ISNULL(St.StateTaxPct,0)) + 0.0049),2)
									ELSE 
										ROUND((((ISNULL(BI.BenefInsurRate,0) +
										(1 * ISNULL(M.SubscriberInsuranceRate,0)) +
										((U.UnitQty-1) * ISNULL(HSI.HalfSubscriberInsuranceRate,ISNULL(M.SubscriberInsuranceRate,0)))) *
										ISNULL(St.StateTaxPct,0)) + 0.0049),2)
									END	

			INSERT INTO #WngAndErr
				SELECT DISTINCT
					'TIN05',
					'',
					'',
					''
				FROM @tTIN T
				JOIN @CotisationTable CT ON CT.OperID = T.OperID
				JOIN dbo.Un_Unit U ON U.UnitID = CT.UnitID
				JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID
				WHERE HB.SocialNumber IS NULL
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
