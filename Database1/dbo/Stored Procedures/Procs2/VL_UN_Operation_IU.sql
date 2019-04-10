/***********************************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	VL_UN_Operation_IU
Description         :	Validation de la création ou la modification d'un opération à partir d'un blob temporaire
Exemple d'appel		:   EXEC dbo.VL_UN_Operation_IU 2
Valeurs de retours  :	
Note                :						2004-07-12	Bruno Lapointe		Création
								ADX0000914	BR	2004-08-24	Bruno Lapointe		Ajout de la validation CPA05
								ADX0000498	IA	2004-09-17	Bruno Lapointe		Gestion des transfert de fonds (TRA)
								ADX0000509	IA	2004-10-04	Bruno Lapointe		Validations de sauvegarde de retrait
								ADX0000574	IA	2004-11-02	Bruno Lapointe		Validation du maximum annuel de 4000$(paramètre)
								ADX0000510	IA	2004-11-15	Bruno Lapointe		Validation de NSF, renommé et adapté pour les 
																							opérations multiples.
								ADX0000575	IA	2004-11-18	Bruno Lapointe		Validation de RES.
								ADX0000568	IA	2004-11-18	Bruno Lapointe		Validation de OUT.
								ADX0000588	IA	2004-11-18	Bruno Lapointe		Validation des AVC.
								ADX0001179	BR	2004-12-01	Bruno Lapointe		Uitlise la table Un_BeneficiaryCeilingCfg au lieu
																							de Un_Def pour le maximum de cotisation annuel.
								ADX0000623	IA	2005-01-04	Bruno Lapointe		Validation des ARI et gestion PlanOper et 
																							OtherAccountOper
								ADX0000625	IA	2004-01-05	Bruno Lapointe		Gestion des RIN
								ADX0000593	IA	2004-01-06	Bruno Lapointe		Gestion des PAE
								ADX0001403	BR	2005-04-19	Bruno Lapointe		Validation CPA qui dépasse maximum annuel. CPA07
								ADX0001418	BR	2005-04-29	Bruno Lapointe		Correction de la validation des plafonds annuels
								ADX0000778	IA	2005-06-23	Bruno Lapointe		Ajout des validations RES06 et OUT06.
								ADX0000753	IA 2005-10-05	Bruno Lapointe		Le codage de l’objet Un_ChequeSuggestion dans le
																							blob va changer pour celui-ci :
																							Un_ChequeSuggestion;ChequeSuggestionID;OperID;HumanID;
																							Lors de modification d’opérations RES, TFR, OUT, RIN,
																							RET, PAE, RGC, AVC on validera qu’il n’y pas de chèque
																							d’émis dans le module des chèques et que les opérations
																							ne sont pas barrées dans le module des chèques.
																							Nouveau code d’erreur :
																							Erreur : GEN07 -> « On a émis un chèque pour cette
																							opération qui n'a pas été refusé ou annulé. »
																							Erreur : GEN08 -> « L'opération est barrée par la
																							fenêtre de validation des changements de destinataire. »
								ADX0001800	BR	2005-12-21	Bruno Lapointe		Validation maximum de cotisation annuel n'exclu pas les 
																							TIN du calcul.
								ADX0001962	BR	2006-06-12	Bruno Lapointe			Adaptation PCEE 4.3.
												2010-03-30	Jean-François Gauthier	Validation de EffectDate > 28 pour le CPA
																					Ajout des validations sur les champs 
																					concernant la date d'opération et la date effective	
												2010-04-08	Jean-François Gauthier	Ajout de la validation du statut de la convention
																					afin de bloquer le traitement si l'état = "Proposition"
												2010-11-26	Pierre Paquet			Correction: Utilisation de @ConventionTable
        2015-12-01      Steeve Picard               Utilisation de la nouvelle fonction «fntCONV_ObtenirStatutConventionEnDate_PourTous»
        2016-12-16      Pierre-Luc Simard           Retrait de la validation EffectDate > 28 pour le CPA (CPA08)
        2017-02-01      Pierre-Luc Simard           Remise en place de la validation (CPA08)
 *********************************************************************************************************************/
CREATE PROCEDURE [dbo].[VL_UN_Operation_IU] (
	@BlobID INT) -- ID Unique du blob (CRI_Blob) contenant l'information
AS
BEGIN
	-- GEN01 -> Pas de détail d'opération
	--				Info1 : Vide					Info2 : Vide						Info3 : Vide
	-- GEN02 -> Pas d'opération
	--				Info1 : Vide					Info2 : Vide						Info3 : Vide
	-- GEN03 -> Plus d'une opération avec le même OperID
	--				Info1 : Vide					Info2 : Vide						Info3 : Vide
	-- GEN04 -> Le blob n'existe pas
	--				Info1 : Vide					Info2 : Vide						Info3 : Vide
	-- GEN05 -> Update du blob par le service par encore fait
	--				Info1 : Vide					Info2 : Vide						Info3 : Vide
	-- GEN06 -> Les deux derniers caractères ne sont pas un saut de ligne et un retour de chariot
	--				Info1 : Vide					Info2 : Vide						Info3 : Vide
	-- GEN07 -> On a émis un chèque pour cette opération qui n'a pas été refusé ou annulé.
	--				Info1 : Vide					Info2 : Vide						Info3 : Vide
	-- GEN08 -> L'opération est barrée par la fenêtre de validation des changements de destinataire.
	--				Info1 : Vide					Info2 : Vide						Info3 : Vide
	-- GEN09 -> Le bénéfiaire actif n'est pas le même qu'à la date effective
	--				Info1 : Vide					Info2 : Vide						Info3 : Vide
	-- GEN10 -> La date d'effectivité de la transaction doit être plus grande ou égale à la date 
	--			 de signature de la convention : dtMinSignatureDate
	--				Info1 : Vide					Info2 : Vide						Info3 : Vide
	-- GEN11 -> La de l'opération de la transaction doit être plus grande ou égale à la date de signature
	--			 de la convention : dtMinSignatureDate
	--				Info1 : Vide					Info2 : Vide						Info3 : Vide
	--
	-- GEN12
	-- Message Transaction refusée, car la convention est à l'état "Proposition"
	--
	-- CPA01 -> Le montant de l’opération doit être plus grand que 0.00$.
	--				Info1 : Vide					Info2 : Vide						Info3 : Vide
	-- CPA02 -> La date d’opération doit être plus grande que la date de barrure du système
	--				Info1 : Vide					Info2 : Vide						Info3 : Vide
	-- CPA03 -> S’il s’agit de l’ajout ou de la modification d’un prélèvement automatique anticipé,  la date de l’opération doit être plus grande que la date des derniers prélèvements automatiques expédiés dans un fichier bancaire.
	--				Info1 : Vide					Info2 : Vide						Info3 : Vide
	-- CPA04 -> Lors de l’édition, si le CPA a déjà été expédié à la banque, la date et le montant de l’opération ne doivent pas avoir été modifiés.
	--				Info1 : Vide					Info2 : Vide						Info3 : Vide
	-- CPA05 -> Pour chargé de l'intérêt client dans un CPA, il doit y avoir une cotisation sur la même convention.
	--				Info1 : LigneTrans			Info2 : ConventionNo				Info3 : Vide
	-- CPA06 -> Les multiples opérations ne sont pas géré pour les CPA 
	--				Info1 : Vide					Info2 : Vide						Info3 : Vide
	-- CPA07 -> Le montant d'épargne et de frais cotisés pour cette année dépasse le maximum annuel
	--				Info1 : Nom et prénom du bénéficiaire	Info2 : Année de le maximum dépasse 	Info3 : Vide
	-- CPA08 -> Le jour de la date d'effectivité doit être inférieur à 29
	--				Info1 : Vide		Info2 : Vide						Info3 : Vide
	
	-- AVC01 -> Les multiples opérations ne sont pas géré pour les AVC 
	--				Info1 : Vide					Info2 : Vide						Info3 : Vide
	-- AVC02 -> Le montant de l’opération doit être plus petit que 0.00$.
	--				Info1 : Vide					Info2 : Vide						Info3 : Vide
	-- AVC03 -> La date d’opération doit être plus grande que la date de barrure du système
	--				Info1 : Vide					Info2 : Vide						Info3 : Vide

	-- ARI01 -> Les multiples opérations ne sont pas géré pour les ARI 
	--				Info1 : Vide					Info2 : Vide						Info3 : Vide
	-- ARI02 -> Le montant de l’opération ARI doit être égal 0.00$.
	--				Info1 : OperID					Info2 : Vide						Info3 : Vide
	-- ARI03 -> La date d’opération doit être plus grande que la date de barrure du système
	--				Info1 : Vide					Info2 : Vide						Info3 : Vide

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
	EXEC @Result = VL_UN_BlobFormatOfOper @BlobID

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
							iIDBeneficiaire INT)	-- 2010-03-30 : JFG : Ajout du champ
	
		-- Tables temporaires créé à partir du blob contenant les opérations sur conventions et les subventions
		DECLARE @ConventionOperTable TABLE (
										LigneTrans			INT,
										ConventionOperID	INT,
										OperID				INT,
										ConventionID		INT,
										ConventionOperTypeID VARCHAR(3),
										ConventionOperAmount MONEY,
										dtDateSignature		DATETIME)-- 2010-03-30 : JFG : Ajout du champ
	
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
									iIDBeneficiaire INT,		-- 2010-03-30 : JFG : Ajout du champ
									vcEtatConv		VARCHAR(3)) -- 2010-04-08 : JFG : Ajout du champ
	
		-- Table temporaire des opérations sur plans
		DECLARE @PlanOperTable TABLE (
			LigneTrans INT,
			PlanOperID INT,
			OperID INT,
			PlanID INT,
			PlanOperTypeID CHAR(3),
			PlanOperAmount MONEY)

		-- Table temporaire des opérations dans les autres comptes
		DECLARE @OtherAccountOperTable TABLE (
			LigneTrans INT,
			OtherAccountOperID INT,
			OperID INT,
			OtherAccountOperAmount MONEY)

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
			dbo.FN_UN_OperOfBlob(@BlobID)
		
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
			dbo.FN_UN_CotisationOfBlob(@BlobID)
			
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
			dbo.FN_UN_ConventionOperOfBlob(@BlobID)	
			
		-- Rempli la table temporaire des opérations sur plans
		INSERT INTO @PlanOperTable
			SELECT *
			FROM dbo.FN_UN_PlanOperOfBlob(@BlobID)	

		-- Rempli la table temporaire des opérations dans les autres comptes
		INSERT INTO @OtherAccountOperTable
			SELECT *
			FROM dbo.FN_UN_OtherAccountOperOfBlob(@BlobID)	

		-- GEN01 : Pas de détail d'opération
		IF NOT EXISTS (SELECT CotisationID FROM @CotisationTable) AND 
			NOT EXISTS (SELECT ConventionOperID FROM @ConventionOperTable) AND
			NOT EXISTS (SELECT PlanOperID FROM @PlanOperTable) AND
			NOT EXISTS (SELECT OtherAccountOperID FROM @OtherAccountOperTable)
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
		--*************** 2010-03-30 : Ajout : JFG  ****************************
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
		-- ************ FIN MODIFICICATION DU 2010-03-30 *********************
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
	
		-- Validation sur CPA
		IF EXISTS (
				SELECT OperID
				FROM @OperTable
				WHERE OperTypeID = 'CPA')
		BEGIN
			-- CPA01 -> Le montant de l’opération doit être plus grand que 0.00$.
			IF @SumCotisation + @SumConventionOper <= 0
				INSERT INTO #WngAndErr
					SELECT 
						'CPA01',
						'',
						'',
						''
				
			-- CPA02 -> La date d’opération doit être plus grande que la date de barrure du système
			INSERT INTO #WngAndErr
				SELECT 
					'CPA02',
					'',
					'',
					''
				FROM @OperTable OT
				LEFT JOIN Un_Oper O ON OT.OperID = O.OperID
				WHERE ISNULL(dbo.FN_CRQ_DateNoTime(O.OperDate),@LastVerifDate+1) <= dbo.FN_CRQ_DateNoTime(@LastVerifDate)
					OR ISNULL(dbo.FN_CRQ_DateNoTime(OT.OperDate),0) <= dbo.FN_CRQ_DateNoTime(@LastVerifDate)
	
			-- CPA03 -> S’il s’agit de l’ajout ou de la modification d’un prélèvement automatique anticipé,  la date de l’opération doit être plus grande que la date des derniers prélèvements automatiques expédiés dans un fichier bancaire.
			DECLARE 
				@LastBankFileDate DATETIME
	
			SELECT @LastBankFileDate = MAX(BankFileEndDate)
			FROM Un_BankFile
	
			IF EXISTS (
					SELECT OperID
					FROM @OperTable 
					WHERE OperDate <= dbo.FN_CRQ_DateNoTime(@LastBankFileDate))
				INSERT INTO #WngAndErr
					SELECT 
						'CPA03',
						'',
						'',
						''
		
			-- CPA04 -> Lors de l’édition, si le CPA a déjà été expédié à la banque, la date et le montant de l’opération ne doivent pas avoir été modifiés.
			IF EXISTS ( 
					SELECT OperID
					FROM @OperTable 
					WHERE OperID > 0)
			BEGIN
				DECLARE 
					@OldSumConventionOper MONEY,
					@OldSumCotisation MONEY
	
				SELECT 
					@OldSumCotisation = SUM(Cotisation+Fee+BenefInsur+SubscInsur+TaxOnInsur)
				FROM Un_Cotisation Ct
				JOIN @OperTable O ON O.OperID = Ct.OperID
		
				SELECT 
					@OldSumConventionOper = SUM(ConventionOperAmount)
				FROM Un_ConventionOper CO
				JOIN @OperTable O ON O.OperID = CO.OperID
	
				IF EXISTS (
						SELECT 
							O.OperID
						FROM Un_Oper O 
						JOIN @OperTable OT ON OT.OperID = O.OperID AND OT.OperDate <> O.OperDate) OR
					(@OldSumCotisation + @OldSumConventionOper <> @SumCotisation + @SumConventionOper)
					INSERT INTO #WngAndErr
						SELECT 
							'CPA04',
							'',
							'',
							''
			END

			-- CPA05 -> Pour chargé de l'intérêt client dans un CPA, il doit y avoir une cotisation sur la même convention.
			INSERT INTO #WngAndErr
				SELECT 
					'CPA05',
					CAST(CO.LigneTrans AS VARCHAR(30)),
					C.ConventionNo,
					''
				FROM @ConventionOperTable CO
				JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
				LEFT JOIN (
					SELECT DISTINCT
						U.ConventionID
					FROM @CotisationTable Ct
					JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
					) Ct ON Ct.ConventionID = CO.ConventionID
				WHERE Ct.ConventionID IS NULL

			-- CPA06 : Les multiples opérations ne sont pas géré pour les CPA 
			IF EXISTS (SELECT COUNT(OperID) FROM @OperTable HAVING COUNT(OperID) > 1) 
				INSERT INTO #WngAndErr
					SELECT 
						'CPA06',
						'',
						'',
						''

			-- Va chercher le maximum annuel de chacun des bénéficiaires qui sont affecté par cette opération
			SELECT
				V.BeneficiaryID,
				BC.BeneficiaryCeilingCfgID
			INTO #Tmp_BeneficiaryCeilingCfgCPA
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

			-- CPA07 -> Le montant d'épargne et de frais cotisés pour cette année dépasse le maximum annuel
			INSERT INTO #WngAndErr
				SELECT 
					'CPA07',
					H.LastName+', '+H.FirstName,
					CAST(NCt.YearEffectDate AS CHAR(4)),
					''
				FROM dbo.Un_Beneficiary B
				JOIN dbo.Mo_Human H ON H.HumanID = B.BeneficiaryID
				JOIN #Tmp_BeneficiaryCeilingCfgCPA TBC ON TBC.BeneficiaryID = B.BeneficiaryID
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
				
			-- CPA08 -> Le jour de la date d'effectivité doit être inférieur à 29 : 2010-03-30 : Ajout : JFG
			IF EXISTS (SELECT 1 FROM @CotisationTable WHERE DAY(EffectDate) > 28)
				BEGIN
					INSERT INTO #WngAndErr
					(
						Code
						,Info1
						,Info2 
						,Info3
					)
					SELECT 
						'CPA08',
						'',
						'',
						''
				END

			DROP TABLE #Tmp_BeneficiaryCeilingCfgCPA
		END
	
		-- Validations sur AVC
		IF EXISTS (
				SELECT OperID
				FROM @OperTable
				WHERE OperTypeID = 'AVC')
		BEGIN
			-- AVC01 : Les multiples opérations ne sont pas géré pour les AVC 
			IF EXISTS (SELECT COUNT(OperID) FROM @OperTable HAVING COUNT(OperID) > 1) 
				INSERT INTO #WngAndErr
					SELECT 
						'AVC01',
						'',
						'',
						''

			-- AVC02 -> Le montant de l’opération doit être plus petit que 0.00$.
			IF @SumConventionOper >= 0
				INSERT INTO #WngAndErr
					SELECT 
						'AVC02',
						'',
						'',
						''
				
			-- AVC03 -> La date d’opération doit être plus grande que la date de barrure du système
			INSERT INTO #WngAndErr
				SELECT 
					'AVC03',
					'',
					'',
					''
				FROM @OperTable OT
				LEFT JOIN Un_Oper O ON OT.OperID = O.OperID
				WHERE ISNULL(dbo.FN_CRQ_DateNoTime(O.OperDate),@LastVerifDate+1) <= dbo.FN_CRQ_DateNoTime(@LastVerifDate)
					OR ISNULL(dbo.FN_CRQ_DateNoTime(OT.OperDate),0) <= dbo.FN_CRQ_DateNoTime(@LastVerifDate)
		END

		-- Validation sur ARI
		IF EXISTS (
				SELECT OperID
				FROM @OperTable
				WHERE OperTypeID = 'ARI')
		BEGIN
			-- ARI01 -> Les multiples opérations ne sont pas géré pour les ARI 
			IF EXISTS (SELECT COUNT(OperID) FROM @OperTable HAVING COUNT(OperID) > 1) 
				INSERT INTO #WngAndErr
					SELECT 
						'ARI01',
						'',
						'',
						''

			-- ARI02 -> Le montant de l’opération ARI doit être égal 0.00$.
			INSERT INTO #WngAndErr
				SELECT 
					'ARI02',
					CAST(O.OperID AS VARCHAR(100)),
					'',
					''
				FROM @OperTable O
				LEFT JOIN (
					SELECT 
						OperID,
						SumPlanOper = SUM(PlanOperAmount)
					FROM @PlanOperTable
					GROUP BY OperID
					) PO ON PO.OperID = O.OperID
				LEFT JOIN (
					SELECT 
						OperID,
						SumOtherAccountOper = SUM(OtherAccountOperAmount)
					FROM @OtherAccountOperTable
					GROUP BY OperID
					) OAO ON OAO.OperID = O.OperID
				LEFT JOIN (
					SELECT 
						OperID,
						SumConventionOper = SUM(ConventionOperAmount)
					FROM @ConventionOperTable
					GROUP BY OperID
					) CO ON CO.OperID = O.OperID
				WHERE O.OperTypeID = 'ARI'
				  AND (ISNULL(PO.SumPlanOper,0) + ISNULL(OAO.SumOtherAccountOper,0) + ISNULL(CO.SumConventionOper,0)) <> 0
				
			-- ARI03 -> La date d’opération doit être plus grande que la date de barrure du système
			INSERT INTO #WngAndErr
				SELECT 
					'ARI03',
					'',
					'',
					''
				FROM @OperTable OT
				LEFT JOIN Un_Oper O ON OT.OperID = O.OperID
				WHERE (	ISNULL(dbo.FN_CRQ_DateNoTime(O.OperDate),@LastVerifDate+1) <= dbo.FN_CRQ_DateNoTime(@LastVerifDate)
						OR ISNULL(dbo.FN_CRQ_DateNoTime(OT.OperDate),0) <= dbo.FN_CRQ_DateNoTime(@LastVerifDate)
						)
				  AND OT.OperTypeID = 'ARI'
		END
	END

	IF @Result <> -1
	BEGIN
		DELETE 
		FROM CRI_Blob
		WHERE dtBlob <= DATEADD(DAY,-2,GETDATE())
	
		IF @@ERROR <> 0
			SET @Result = -10 -- Erreur à la suppression du blob
	END

	SELECT *
	FROM #WngAndErr

	DROP TABLE #WngAndErr
	RETURN @Result
END
