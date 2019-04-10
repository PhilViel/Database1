/***********************************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	VL_UN_OperOUT_IU
Description         :	Procédure de validation avant la sauvegarde d’ajout/modification de transfert OUT.
Exemple d'appel		:   EXEC dbo.VL_UN_OperOUT_IU 2
Valeurs de retours  :	Dataset : (Vide = pas d’erreur dans les validations)
				vcCode	VARCHAR(5)	Code de d’erreur
				vcInfo1	VARCHAR(100)	Première information supplémentaire, permet de faire des messages détaillés.
				vcInfo2	VARCHAR(100)	Deuxième information supplémentaire.
				vcInfo3	VARCHAR(100)	Troisième information supplémentaire.
					
			ReturnValue :
				> 0 : Réussite
				<= 0 : Erreurs.

Note                :	ADX0000992	IA	2006-05-19	Alain Quirion			Création								
										2010-03-31	Jean-François Gauthier	Ajout des validations sur les champs 
																			concernant la date d'opération et la date effective	
										2010-04-08	Jean-François Gauthier	Ajout de la validation du statut de la convention
																			afin de bloquer le traitement si l'état = "Proposition"
										2010-11-26	Pierre Paquet			Correction: Utilisation de @ConventionTable
        2015-12-01      Steeve Picard               Utilisation de la nouvelle fonction «fntCONV_ObtenirStatutConventionEnDate_PourTous»
***********************************************************************************************************************/
CREATE PROCEDURE [dbo].[VL_UN_OperOUT_IU] (
@iBlobID INT)	--ID du blob
AS
BEGIN
	--Code	GEN01
	--Message	Pas de détail d'opération.
	--Info1 : Vide					Info2 : Vide						Info3 : Vide

	--Code	GEN02
	--Message	Pas d'opération.
	--Info1 : Vide					Info2 : Vide						Info3 : Vide

	--Code	GEN03
	--Message	Plus d'une opération avec le même OperID.
	--Info1 : Vide					Info2 : Vide						Info3 : Vide

	--Code	GEN04
	--Message	Le blob n'existe pas.
	--Info1 : Vide					Info2 : Vide						Info3 : Vide

	--Code	GEN05
	--Message	Update du blob par le service pas encore fait.
	--Info1 : Vide					Info2 : Vide						Info3 : Vide

	--Code	GEN06
	--Message	Les deux derniers caractères ne sont pas un saut de ligne et un retour de chariot.
	--Info1 : Vide					Info2 : Vide						Info3 : Vide
	
	--GEN09 -> Le bénéfiaire actif n'est pas le même qu'à la date effective
	--			Info1 : Vide					Info2 : Vide						Info3 : Vide
	--GEN10 -> La date d'effectivité de la transaction doit être plus grande ou égale à la date 
	--		 de signature de la convention : dtMinSignatureDate
	--			Info1 : Vide					Info2 : Vide						Info3 : Vide
	--GEN11 -> La de l'opération de la transaction doit être plus grande ou égale à la date de signature
	--		 de la convention : dtMinSignatureDate
	--			Info1 : Vide					Info2 : Vide						Info3 : Vide
	--GEN12 -> Transaction refusée, car la convention est à l'état "Proposition"
	--			Info1 : Vide					Info2 : Vide						Info3 : Vide

	--Code	OUT01
	--Message	On ne peut pas enregistrer plus d'une réduction d'unités à la fois.
	--Info1 : Vide					Info2 : Vide						Info3 : Vide

	--Code	OUT02
	--Message	Le montant du OUT doit être de 0.00$ quand une raison de non émission de chèque avec implication "RES à 0" est sélectionnée.
	--Info1 : Vide					Info2 : Vide						Info3 : Vide

	--Code	OUT03
	--Message	Le montant du OUT doit être inférieur ou égal à 0.00$.
	--Info1 : Vide					Info2 : Vide						Info3 : Vide

	--Code	OUT04
	--Message	La raison de la résiliation doit être sélectionnée.
	--Info1 : Vide					Info2 : Vide						Info3 : Vide

	--Code	OUT05
	--Message	La date d’opération doit être plus grande que la date de barrure du système.
	--Info1 : Vide					Info2 : Vide						Info3 : Vide

	--Code	OUT06
	--Message	La totalité de l’épargne et des frais doivent être transférés lors d’un transfert de toutes les unités.
	--Info1 : Vide					Info2 : Vide						Info3 : Vide

	--Code	OUT07
	--Message	Le NAS du bénéficiaire est obligatoire
	--Info1 : Vide					Info2 : Vide						Info3 : Vide

	-- Result = -1 -> Le blob n'existe pas
	-- Result = -2 -> Update du blob par le service par encore fait
	-- Result = -3 -> Les deux derniers caractères ne sont pas un saut de ligne et un retour de chariot
	-- Result = -10 -> Erreur à la suppression du blob

	DECLARE 
		@Result INT

	CREATE TABLE #WngAndErr(
		Code VARCHAR(5),
		Info1 VARCHAR(100),
		Info2 VARCHAR(100),
		Info3 VARCHAR(100)
	)

	-- Validation du blob
	EXEC @Result = VL_UN_BlobFormatOfOper @iBlobID

	IF @Result < 0
	BEGIN
		-- GEN04 -> Le blob n'existe pas
		-- GEN05 -> Update du blob par le service pas encore fait
		-- GEN06 -> Les deux derniers caractères ne sont pas un saut de ligne et un retour de chariot
		INSERT INTO #WngAndErr
			SELECT 
				CASE @Result
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
							iIDBeneficiaire INT)	-- 2010-03-31 : JFG : Ajout du champ
	
		-- Tables temporaires créé à partir du blob contenant les opérations sur conventions et les subventions
		DECLARE @ConventionOperTable TABLE (
										LigneTrans			INT,
										ConventionOperID	INT,
										OperID				INT,
										ConventionID		INT,
										ConventionOperTypeID VARCHAR(3),
										ConventionOperAmount MONEY,
										dtDateSignature		DATETIME)-- 2010-03-31 : JFG : Ajout du champ
	
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
									iIDBeneficiaire INT,	-- 2010-03-31 : JFG : Ajout du champ
									vcEtatConv		VARCHAR(3)) -- 2010-04-08 : JFG : Ajout du champ
		
		-- Table temporaire de proposition de modification de chèque
		DECLARE @ChequeSuggestionTable TABLE (
			ChequeSuggestionID INT,
			OperID INT,
			iHumanID INT)	

		-- Table temporaire de réduction d'unités
		DECLARE @UnitReductionTable TABLE (
			UnitReductionID INT,
			UnitID INT,
			ReductionConnectID INT,
			ReductionDate DATETIME,
			UnitQty MONEY,
			FeeSumByUnit MONEY,
			SubscInsurSumByUnit MONEY,
			UnitReductionReasonID INT,
			NoChequeReasonID INT)

		-- Table temporaire des opérations dans les autres comptes
		DECLARE @OtherAccountOperTable TABLE (
			LigneTrans INT,
			OtherAccountOperID INT,
			OperID INT,
			OtherAccountOperAmount MONEY)		

		-- Table temporaire du transfert OUT
		DECLARE @tOUT TABLE (
			OperID INT,				--ID de l’opération
			ExternalPlanID INT,			--ID de l’autre plan (Plan externe)
			tiBnfRelationWithOtherConvBnf TINYINT,	--Lien de parenté entre les bénéficiaires du REEE cessionnaire (1 = Même, 2 = Frère ou sœur, 3 = Aucun des deux)
			vcOtherConventionNo VARCHAR(15),	--Numéro de l’autre contrat.
			tiREEEType TINYINT,			--Type de REEE (1 = Individuel, 2 = Famille comptant uniquement des frères et des sœurs, 3 = Famille et 4 = Groupe)
			bEligibleForCESG BIT,			--Indique si le promoteur du régime cessionnaire a signé des ententes avec le RHDDC pour administrer la SCEE.
			bEligibleForCLB BIT,			--Indique si le promoteur du régime cessionnaire a signé des ententes avec le RHDDC pour administrer la BEC.
			bOtherContratBnfAreBrothers BIT,	--Indique si les bénéficiaires du régime cessionnaire sont tous des frères ou des sœurs.
			fYearBnfCot MONEY,			--Cotisations versés pour le bénéficiaire cette année.
			fBnfCot MONEY,				--Cotisations cumulatives 
			fNoCESGCotBefore98 MONEY,		--Cotisations non-subventionnées jusqu’en 1998.
			fNoCESGCot98AndAfter MONEY,		--Cotisations non-subventionnées en 1998 et après. 
			fCESGCot MONEY,				--Cotisations subventionnées
			fCESG MONEY,				--SCEE et SCEE+
			fCLB MONEY,				--BEC
			fAIP MONEY,				--Revenues accumulés
			fMarketValue MONEY)			--Valeur marchande

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
	
		-- Rempli la table temporaire de proposition de modification de chèque
		INSERT INTO @ChequeSuggestionTable
			SELECT *
			FROM dbo.FN_UN_ChequeSuggestionOfBlob(@iBlobID)	

		-- Rempli la table temporaire de réduction d'unités
		INSERT INTO @UnitReductionTable
			SELECT *
			FROM dbo.FN_UN_UnitReductionOfBlob(@iBlobID)	

		-- Rempli la table temporaire des opérations dans les autres comptes
		INSERT INTO @OtherAccountOperTable
			SELECT *
			FROM dbo.FN_UN_OtherAccountOperInBlob(@iBlobID)	

		INSERT INTO @tOUT
			SELECT *
			FROM dbo.FN_UN_OUTOfBlob(@iBlobID)

		-- GEN01 : Pas de détail d'opération
		IF NOT EXISTS (SELECT CotisationID FROM @CotisationTable) AND 
			NOT EXISTS (SELECT ConventionOperID FROM @ConventionOperTable) AND
			NOT EXISTS (SELECT OtherAccountOperID FROM @OtherAccountOperTable) AND
			NOT EXISTS (SELECT OperID FROM @tOUT)
			INSERT INTO #WngAndErr
				SELECT 
					'GEN01',
					'',
					'',
					''
	
		-- GEN02 : Pas d'opération
		IF NOT EXISTS (SELECT OperID FROM @OperTable) AND
			NOT EXISTS (SELECT OperID FROM @tOUT)
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
		--*************** 2010-03-31 : Ajout : JFG  ****************************
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
		-- ************ FIN MODIFICICATION DU 2010-03-31 *********************
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
			@MaxYearCotisation MONEY,
			@SumConventionOperRES MONEY,
			@SumCotisationRES MONEY

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
	
		-- Validation sur OUT
		IF EXISTS (
				SELECT OperID
				FROM @OperTable
				WHERE OperTypeID = 'OUT')
		BEGIN
			-- OUT01 -> On ne peut pas enregistrer plus d'une réduction d'unités à la fois
			IF (
					SELECT COUNT(UnitReductionID)
					FROM @UnitReductionTable) > 1 
				INSERT INTO #WngAndErr
					SELECT 
						'OUT01',
						'',
						'',
						''

			SET @SumConventionOperRES = 0
			SET @SumCotisationRES = 0

			-- Va chercher le montant d'opération sur convention du OUT
			SELECT 
				@SumConventionOperRES = SUM(CO.ConventionOperAmount)
			FROM @OperTable O
			JOIN @ConventionOperTable CO ON CO.OperID = O.OperID
			WHERE O.OperTypeID = 'OUT'

			-- Va chercher le montant de cotisation du OUT
			SELECT 
				@SumCotisationRES = SUM(Ct.Cotisation+Ct.Fee+Ct.SubscInsur+Ct.BenefInsur+Ct.TaxOnInsur)
			FROM @OperTable O
			JOIN @CotisationTable Ct ON Ct.OperID = O.OperID
			WHERE O.OperTypeID = 'OUT'

			-- OUT02 -> Le montant du OUT doit être de 0.00$ quand une raison de non émission de chèque avec implication "RES à 0" est sélectionnée.
			IF EXISTS (
					SELECT 
						UR.UnitReductionID
					FROM @UnitReductionTable UR
					JOIN Un_NoChequeReason NC ON NC.NoChequeReasonID = UR.NoChequeReasonID
					WHERE NC.NoChequeReasonImplicationID = 1) AND -- RES à 0.00$
				(@SumCotisationRES + @SumConventionOperRES <> 0)
				INSERT INTO #WngAndErr
					SELECT 
						'OUT02',
						'',
						'',
						''

			-- OUT03 -> Le montant du OUT doit être inférieur ou égal à 0.00$.
			IF EXISTS (
					SELECT 
						UR.UnitReductionID
					FROM @UnitReductionTable UR
					LEFT JOIN Un_NoChequeReason NC ON NC.NoChequeReasonID = UR.NoChequeReasonID
					WHERE ISNULL(NC.NoChequeReasonImplicationID,0) <> 1) AND -- autre raison que RES à 0.00$
				(@SumCotisationRES + @SumConventionOperRES > 0)
				INSERT INTO #WngAndErr
					SELECT 
						'OUT03',
						'',
						'',
						''

			-- OUT04 -> La raison de la résiliation doit être sélectionnée.
			IF EXISTS (
					SELECT *
					FROM @UnitReductionTable UR
					LEFT JOIN Un_UnitReductionReason R ON R.UnitReductionReasonID = UR.UnitReductionReasonID 
					WHERE R.UnitReductionReasonID IS NULL)
				INSERT INTO #WngAndErr
					SELECT 
						'OUT04',
						'',
						'',
						''

			-- OUT05 -> La date d’opération doit être plus grande que la date de barrure du système
			INSERT INTO #WngAndErr
				SELECT 
					'OUT05',
					'',
					'',
					''
				FROM @OperTable OT
				LEFT JOIN Un_Oper O ON OT.OperID = O.OperID
				WHERE ISNULL(dbo.FN_CRQ_DateNoTime(O.OperDate),@LastVerifDate+1) <= dbo.FN_CRQ_DateNoTime(@LastVerifDate)
					OR ISNULL(dbo.FN_CRQ_DateNoTime(OT.OperDate),0) <= dbo.FN_CRQ_DateNoTime(@LastVerifDate)

			-- OUT06 ->	La totalité de l’épargne et des frais doivent être transférés lors d’un transfert de toutes les unités.
			IF EXISTS (
				SELECT U.UnitID 
				FROM @UnitReductionTable URT
				JOIN dbo.Un_Unit U ON U.UnitID = URT.UnitID
				LEFT JOIN Un_UnitReduction UR ON UR.UnitReductionID = URT.UnitReductionID
				WHERE U.UnitQty - (URT.UnitQty-ISNULL(UR.UnitQty,0)) = 0
				)
			BEGIN 
				SELECT U.UnitID
				INTO #tTotalUnitOUT
				FROM @UnitReductionTable URT
				JOIN dbo.Un_Unit U ON U.UnitID = URT.UnitID
				LEFT JOIN Un_UnitReduction UR ON UR.UnitReductionID = URT.UnitReductionID
				WHERE U.UnitQty - (URT.UnitQty-ISNULL(UR.UnitQty,0)) = 0

				INSERT INTO #WngAndErr
					SELECT 
						'OUT06',
						'',
						'',
						''
					FROM #tTotalUnitOUT R
					LEFT JOIN ( -- Solde Cotisation et frais avant résiliation
						SELECT 
							R.UnitID,
							CotisationFee = SUM(Ct.Cotisation+Ct.Fee)
						FROM #tTotalUnitOUT R
						JOIN Un_Cotisation Ct ON Ct.UnitID = R.UnitID
						JOIN Un_Oper O ON O.OperID = Ct.OperID
						LEFT JOIN Un_OperBankFile OBF ON OBF.OperID = O.OperID
						WHERE (	( O.OperTypeID = 'CPA' 
							 		AND OBF.OperID IS NOT NULL
									)
								OR O.OperDate <= GETDATE()
								)
						GROUP BY R.UnitID
						) Ct ON Ct.UnitID = R.UnitID
					LEFT JOIN ( -- Cotisation et frais de la résiliation
						SELECT 
							R.UnitID,
							CotisationFee = SUM(CtT.Cotisation+CtT.Fee-ISNULL(Ct.Cotisation,0)-ISNULL(Ct.Fee,0))
						FROM #tTotalUnitOUT R
						JOIN @CotisationTable CtT ON CtT.UnitID = R.UnitID
						LEFT JOIN Un_Cotisation Ct ON Ct.CotisationID = CtT.CotisationID
						GROUP BY R.UnitID
						) CtT ON CtT.UnitID = R.UnitID
					WHERE ISNULL(Ct.CotisationFee,0)+ISNULL(CtT.CotisationFee,0) <> 0

				DROP TABLE #tTotalUnitOUT
			END

			INSERT INTO #WngAndErr
				SELECT DISTINCT
					'OUT07',
					'',
					'',
					''
				FROM @tOUT T
				JOIN @CotisationTable CT ON CT.OperID = T.OperID
				JOIN dbo.Un_Unit U ON U.UnitID = CT.UnitID
				JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID
				WHERE HB.SocialNumber IS NULL
		END		
	END

	-- Fait le ménage dans les blob vieux de 2 jours ou plus
	IF @Result <= 0
	BEGIN
		DELETE 
		FROM CRI_Blob
		WHERE dtBlob <= DATEADD(DAY,-2,GETDATE())
	
		IF @@ERROR <> 0
		AND @Result > 0
			SET @Result = -10 -- Erreur à la suppression du blob
	END

	SELECT *
	FROM #WngAndErr

	DROP TABLE #WngAndErr;

	RETURN @Result
END
