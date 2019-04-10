/***********************************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	VL_UN_OperRES_IU
Description         :	Procédure de validation avant la sauvegarde d’ajout/modification de résiliations.
Exemple d'appel		:   EXEC dbo.VL_UN_OperRES_IU 2
Valeurs de retours  :	Dataset : (Vide = pas d’erreur dans les validations)
									vcCode	VARCHAR(5)	Code de d’erreur
									vcInfo1	VARCHAR(100)	Première information supplémentaire, permet de faire des messages détaillés.
									vcInfo2	VARCHAR(100)	Deuxième information supplémentaire.
									vcInfo3	VARCHAR(100)	Troisième information supplémentaire.
								Erreurs possibles du Dataset :
									Code	RES01
									Message	On ne peut pas enregistrer plus d'une réduction d'unités à la fois.
									Code	RES02
									Message	Le montant du RES doit être de 0.00$ quand une raison de non émission de chèque avec implication "RES à 0" est sélectionnée.
									Code	RES03
									Message	Le montant du RES doit être inférieur ou égal à 0.00$.
									Code	RES04
									Message	La raison de la résiliation doit être sélectionnée.
									Code	RES05
									Message	La date d’opération doit être plus grande que la date de barrure du système.
									Code	RES06
									Message	La totalité de l’épargne et des frais doivent être retirés lors d’une résiliation de toutes les unités.
									Code	RES07
									Message : Cette convention possède un montant ou une demande de BEC qui doit être transféré à une autre convention
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
									Code	GEN07
									Message	On a émis un chèque pour cette opération qui n'a pas été refusé ou annulé.
									Code	GEN08
									Message	L'opération est barrée par la fenêtre de validation des changements de destinataire.

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

								ReturnValue :
									> 0 : Réussite
									<= 0 : Erreurs.
										-1 -> Le blob n'existe pas
										-2 -> Update du blob par le service par encore fait
										-3 -> Les deux derniers caractères ne sont pas un saut de ligne et un retour de chariot
										-10 -> Erreur à la suppression du blob
Note                :	ADX0000860	IA	2006-03-23	Bruno Lapointe			Création
										2009-11-10	Jean-François Gauthier	Ajout de la validation RES07
										2010-04-06	Jean-François Gauthier	Ajout des validations sur les champs 
																			concernant la date d'opération et la date effective	
										2010-04-08	Jean-François Gauthier	Ajout de la validation du statut de la convention
																			afin de bloquer le traitement si l'état = "Proposition"																																						
										2010-05-05	Pierre Paquet			COrrection sur l'erreur RES07.
										2010-05-10	Pierre Paquet			Ajustemetn sur RES07.
										2010-05-13	Pierre Paquet			Correction RES07.
										2010-11-26	Pierre Paquet			Correction: Utilisation de @ConventionTable
        2015-12-01      Steeve Picard               Utilisation de la nouvelle fonction «fntCONV_ObtenirStatutConventionEnDate_PourTous»
 *********************************************************************************************************************/
CREATE PROCEDURE [dbo].[VL_UN_OperRES_IU] (
	@iBlobID INT) -- ID du blob de la table CRI_Blob qui contient les objets de l’opération RES à sauvegarder
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

		-- Rempli la table temporaire de réduction d'unités
		INSERT INTO @UnitReductionTable
			SELECT *
			FROM dbo.FN_UN_UnitReductionOfBlob(@iBlobID)	

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
	
		-- GEN07 : On a émis un chèque pour cette opération qui n'a pas été refusé ou annulé.
		IF EXISTS (
			SELECT OT.OperID
			FROM @OperTable OT
			JOIN Un_OperLinkToCHQOperation CO ON CO.OperID = OT.OperID
			JOIN CHQ_OperationDetail OD ON OD.iOperationID = CO.iOperationID
			JOIN CHQ_CheckOperationDetail COD ON COD.iOperationDetailID = OD.iOperationDetailID
			JOIN CHQ_Check C ON C.iCheckID = COD.iCheckID
			WHERE C.iCheckStatusID NOT IN (3,5) -- Pas refusé ou annulé
			)
			INSERT INTO #WngAndErr
				SELECT 
					'GEN07',
					'',
					'',
					''

		-- GEN08 : L'opération est barrée par la fenêtre de validation des changements de destinataire.
		IF EXISTS (
			SELECT OT.OperID
			FROM @OperTable OT
			JOIN Un_OperLinkToCHQOperation CO ON CO.OperID = OT.OperID
			JOIN CHQ_OperationLocked OL ON OL.iOperationID = CO.iOperationID
			)
			INSERT INTO #WngAndErr
				SELECT 
					'GEN08',
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
			@SumConventionOperRES MONEY,
			@SumCotisationRES MONEY

		SELECT 
			@LastVerifDate = LastVerifDate
		FROM Un_Def

		-- Validation sur RES
		IF EXISTS (
				SELECT OperID
				FROM @OperTable
				WHERE OperTypeID = 'RES')
		BEGIN
			-- RES01 -> On ne peut pas enregistrer plus d'une réduction d'unités à la fois
			IF (
					SELECT COUNT(UnitReductionID)
					FROM @UnitReductionTable) > 1 
				INSERT INTO #WngAndErr
					SELECT 
						'RES01',
						'',
						'',
						''

			SET @SumConventionOperRES = 0
			SET @SumCotisationRES = 0

			-- Va chercher le montant d'opération sur convention du RES
			SELECT 
				@SumConventionOperRES = SUM(CO.ConventionOperAmount)
			FROM @OperTable O
			JOIN @ConventionOperTable CO ON CO.OperID = O.OperID
			WHERE O.OperTypeID = 'RES'

			-- Va chercher le montant de cotisation du RES
			SELECT 
				@SumCotisationRES = SUM(Ct.Cotisation+Ct.Fee+Ct.SubscInsur+Ct.BenefInsur+Ct.TaxOnInsur)
			FROM @OperTable O
			JOIN @CotisationTable Ct ON Ct.OperID = O.OperID
			WHERE O.OperTypeID = 'RES'

			-- RES02 -> Le montant du RES doit être de 0.00$ quand une reason de non émission de chèque avec implication "RES à 0" est sélectionnée.
			IF EXISTS (
					SELECT 
						UR.UnitReductionID
					FROM @UnitReductionTable UR
					JOIN Un_NoChequeReason NC ON NC.NoChequeReasonID = UR.NoChequeReasonID
					WHERE NC.NoChequeReasonImplicationID = 1) AND -- RES à 0.00$
				(@SumCotisationRES + @SumConventionOperRES <> 0)
				INSERT INTO #WngAndErr
					SELECT 
						'RES02',
						'',
						'',
						''

			-- RES03 -> Le montant du RES doit être inférieur ou égal à 0.00$.
			IF EXISTS (
					SELECT 
						UR.UnitReductionID
					FROM @UnitReductionTable UR
					LEFT JOIN Un_NoChequeReason NC ON NC.NoChequeReasonID = UR.NoChequeReasonID
					WHERE ISNULL(NC.NoChequeReasonImplicationID,0) <> 1) AND -- autre raison que RES à 0.00$
				(@SumCotisationRES + @SumConventionOperRES > 0)
				INSERT INTO #WngAndErr
					SELECT 
						'RES03',
						'',
						'',
						''

			-- RES04 -> La raison de la résiliation doit être sélectionnée.
			IF EXISTS (
					SELECT *
					FROM @UnitReductionTable UR
					LEFT JOIN Un_UnitReductionReason R ON R.UnitReductionReasonID = UR.UnitReductionReasonID 
					WHERE R.UnitReductionReasonID IS NULL)
				INSERT INTO #WngAndErr
					SELECT 
						'RES04',
						'',
						'',
						''

			-- RES05 -> La date d’opération doit être plus grande que la date de barrure du système
			INSERT INTO #WngAndErr
				SELECT 
					'RES05',
					'',
					'',
					''
				FROM @OperTable OT
				LEFT JOIN Un_Oper O ON OT.OperID = O.OperID
				WHERE ISNULL(dbo.FN_CRQ_DateNoTime(O.OperDate),@LastVerifDate+1) <= dbo.FN_CRQ_DateNoTime(@LastVerifDate)
					OR ISNULL(dbo.FN_CRQ_DateNoTime(OT.OperDate),0) <= dbo.FN_CRQ_DateNoTime(@LastVerifDate)

			--	RES06 ->	La totalité de l’épargne et des frais doivent être retirés lors d’une résiliation de toutes les unités.
			IF EXISTS (
				SELECT U.UnitID 
				FROM @UnitReductionTable URT
				JOIN dbo.Un_Unit U ON U.UnitID = URT.UnitID
				LEFT JOIN Un_UnitReduction UR ON UR.UnitReductionID = URT.UnitReductionID
				WHERE U.UnitQty - (URT.UnitQty-ISNULL(UR.UnitQty,0)) = 0
				)
			BEGIN 
				SELECT U.UnitID
				INTO #tTotalUnitRES
				FROM @UnitReductionTable URT
				JOIN dbo.Un_Unit U ON U.UnitID = URT.UnitID
				LEFT JOIN Un_UnitReduction UR ON UR.UnitReductionID = URT.UnitReductionID
				WHERE U.UnitQty - (URT.UnitQty-ISNULL(UR.UnitQty,0)) = 0

				INSERT INTO #WngAndErr
					SELECT 
						'RES06',
						'',
						'',
						''
					FROM #tTotalUnitRES R
					LEFT JOIN ( -- Solde Cotisation et frais avant résiliation
						SELECT 
							R.UnitID,
							CotisationFee = SUM(Ct.Cotisation+Ct.Fee)
						FROM #tTotalUnitRES R
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
						FROM #tTotalUnitRES R
						JOIN @CotisationTable CtT ON CtT.UnitID = R.UnitID
						LEFT JOIN Un_Cotisation Ct ON Ct.CotisationID = CtT.CotisationID
						GROUP BY R.UnitID
						) CtT ON CtT.UnitID =	R.UnitID
					WHERE ISNULL(Ct.CotisationFee,0)+ISNULL(CtT.CotisationFee,0) <> 0

					DROP TABLE #tTotalUnitRES

			END
				--	RES07 -> Vérification de la présence d'un montant ou demande de BEC.
				INSERT INTO #WngAndErr
				(
					Code
					,Info1
					,Info2
					,Info3
				)
				SELECT
					DISTINCT
					'RES07'
					,''
					,''
					,''
				FROM 
					@CotisationTable CT,
					 dbo.UN_UNIT U,
					 dbo.UN_Convention C,
					 @UnitReductionTable URT
				WHERE
					U.UnitID = CT.UnitID
					AND U.UnitID = URT.UnitID
					AND URT.UnitID = CT.UnitID
					AND U.ConventionID = C.ConventionID
					AND C.bCLBRequested = 1 -- 2010-05-05 Pierre Paquet
					AND ((select SUM(UnitQty) from dbo.fntCONV_ObtenirUnitesConvention (C.ConventionID, null, null)) - 
						URT.UnitQty) = 0
			
		-- Vérifier s'il y a un montant de BEC dans la convention
		CREATE TABLE #ConventionBEC (ConventionID INT, mBEC Money)
		-- Faire la liste de toutes les conventions à résiliation complète.
		INSERT INTO #ConventionBEC 
			SELECT U.ConventionID,0 
				FROM 
					@CotisationTable CT,
					 dbo.UN_UNIT U,
					 dbo.UN_Convention C,
					 @UnitReductionTable URT
				WHERE
					U.UnitID = CT.UnitID
					AND U.UnitID = URT.UnitID
					AND URT.UnitID = CT.UnitID
					AND U.ConventionID = C.ConventionID
					AND ((select SUM(UnitQty) from dbo.fntCONV_ObtenirUnitesConvention (C.ConventionID, null, null)) - 
						URT.UnitQty) = 0

		-- Récupérer le montant BEC s'il y a lieu
		UPDATE	CB
		SET		CB.mBEC = tmp.mMontantBEC
		FROM
			(
			SELECT
				mMontantBEC = SUM(c.fCLB)
				,c.ConventionID
			FROM
				#ConventionBEC  ct
				INNER JOIN dbo.UN_CESP C 
					ON C.ConventionID = ct.ConventionID
			GROUP BY
				c.ConventionID
			) tmp
			INNER JOIN #ConventionBEC CB 
				ON tmp.ConventionID = CB.ConventionID

		-- Soustraire les montants remboursés.
		UPDATE CB
		SET CB.mBEC = CB.mBEC + tmp.mMontantBEC
		FROM
			(
			SELECT
				mMontantBEC = SUM(c.fCLB) -- Solde de BEC à rembourser
				,c.ConventionID
			FROM
				#ConventionBEC ct
				INNER JOIN dbo.UN_CESP400 C
					ON C.ConventionID = ct.ConventionID
				LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = C.iCESP400ID
				LEFT JOIN Un_CESP CE ON CE.OperID = C.OperID
			WHERE C9.iCESP900ID IS NULL
				AND C.iCESP800ID IS NULL
				AND CE.iCESPID IS NULL					
			GROUP BY
				c.ConventionID
			) tmp
			INNER JOIN #ConventionBEC CB
				ON tmp.ConventionID = CB.ConventionID
	
			-- Générer l'erreur RES07 s'il y a un montant de BEC
			INSERT INTO #WngAndErr
			(
				Code
				,Info1
				,Info2
				,Info3
			)
			SELECT
				DISTINCT
				'RES07'
				,''
				,''
				,''
			FROM 
				#ConventionBEC CB
			WHERE
				CB.mBEC <> 0

			DROP TABLE #ConventionBEC
				
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
	SELECT DISTINCT *
	FROM #WngAndErr

	-- Supprime la table temporaire des erreurs
	DROP TABLE #WngAndErr
	RETURN @iResult
END
