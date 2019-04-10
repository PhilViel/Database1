
/********************************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	VL_UN_OperAJU_IU
Description         :	Procédure de validation avant la sauvegarde d’ajout/modification d'un ajustement.
Exemple d'appel		:   EXEC dbo.[VL_UN_OperAJU_IU] 2
Valeurs de retours  :	Dataset : (Vide = pas d’erreur dans les validations)
									vcCode	VARCHAR(5)	Code de d’erreur
									vcInfo1	VARCHAR(100)	Première information supplémentaire, permet de faire des messages détaillés.
									vcInfo2	VARCHAR(100)	Deuxième information supplémentaire.
									vcInfo3	VARCHAR(100)	Troisième information supplémentaire.
								Erreurs possibles du Dataset :
									
									Code	AJU01
									Message	La date d'opération doit être plus grande que la date de barrure du système. 
									Code	AJU02
									Message	Le montant d'épargne et de frais cotisés pour cette année dépasse le maximum annuel. 
									
									Message	Les multiples opérations ne sont pas gérées pour les CHQ.
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
									
									Code	GEN09
									Message	Le bénéfiaire actif n'est pas le même qu'à la date effective
									Code	GEN10
									Message	La date d'effectivité de la transaction doit être plus grande ou égale à la date 
											de signature de la convention : dtMinSignatureDate
									Code	GEN11
									Message	La de l'opération de la transaction doit être plus grande ou égale à la date de signature
											de la convention : dtMinSignatureDate
									Code	GEN12
									Message Transaction refusée, car la convention est à l'état "Proposition"
											
								ReturnValue :
									> 0 : Réussite
									<= 0 : Erreurs.
										-1 -> Le blob n'existe pas
										-2 -> Update du blob par le service par encore fait
										-3 -> Les deux derniers caractères ne sont pas un saut de ligne et un retour de chariot
										-10 -> Erreur à la suppression du blob
										
Note                :	
							ADX0001054	IA	2006-08-02	Mireya Gonthier			Création
											2010-03-30	Jean-François Gauthier	Ajout des validations sur les champs 
																				concernant la date d'opération et la date effective	
											2010-04-08	Jean-François Gauthier	Ajout de la validation du statut de la convention
																				afin de bloquer le traitement si l'état = "Proposition"
											2010-11-26	Pierre Paquet			Correction: Utilisation de @ConventionTable
 *********************************************************************************************************************/
CREATE PROCEDURE [dbo].[VL_UN_OperAJU_IU] (
	@iBlobID INT) -- ID du blob de la table CRI_Blob qui contient les objets de l’opération AJU à sauvegarder
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
							LigneTrans		INT,
							OperID			INT,
							ConnectID		INT,
							OperTypeID		CHAR(3),
							OperDate		DATETIME,
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
		SET		ct.vcEtatConv = dbo.fnCONV_ObtenirStatutConventionEnDate(u.ConventionID,GETDATE())
		FROM
				@CotisationTable ct
				INNER JOIN dbo.Un_Unit u
					ON ct.UnitID = u.UnitID
		
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
			@LastVerifDate DATETIME
			
		
		SELECT 
			@LastVerifDate = LastVerifDate
		FROM Un_Def
		
		-- Validation sur AJU
		IF EXISTS (
				SELECT OperID
				FROM @OperTable
				WHERE OperTypeID = 'AJU')
		BEGIN
			
			-- AJU1 -> La date d'opération doit être plus grande que la date de barrure du système. 
			INSERT INTO #WngAndErr
				SELECT 
					'AJU01',
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
			INTO #Tmp_BeneficiaryCeilingCfgAJU
			FROM (
				SELECT
					C.BeneficiaryID,
					EffectDate = MAX(BC.EffectDate)
				FROM @CotisationTable Ct
				JOIN Un_Unit U ON Ct.UnitID = U.UnitID
				JOIN Un_Convention C ON U.ConventionID = C.ConventionID
				JOIN Mo_Human B ON C.BeneficiaryID = B.HumanID
				JOIN Un_BeneficiaryCeilingCfg BC ON ISNULL(B.BirthDate, '1985-01-01') >= BC.EffectDate
				GROUP BY C.BeneficiaryID
				) V 
			JOIN Un_BeneficiaryCeilingCfg BC ON V.EffectDate = BC.EffectDate

			-- AJU2 -> Le montant d'épargne et de frais cotisés pour cette année dépasse le maximum annuel
			INSERT INTO #WngAndErr
				SELECT 
					'AJU02',
					-----H.LastName+', '+H.FirstName,
					H.FirstName+' '+H.LastName,
					CAST(NCt.YearEffectDate AS CHAR(4)),
					''
				FROM Un_Beneficiary B
				JOIN Mo_Human H ON H.HumanID = B.BeneficiaryID
				JOIN #Tmp_BeneficiaryCeilingCfgAJU TBC ON TBC.BeneficiaryID = B.BeneficiaryID
				JOIN Un_BeneficiaryCeilingCfg BC ON BC.BeneficiaryCeilingCfgID = TBC.BeneficiaryCeilingCfgID
				JOIN (
					SELECT 
						C.BeneficiaryID,
						YearEffectDate = YEAR(EffectDate),
						SumCotisationFee = SUM(Cotisation+Fee)
					FROM @CotisationTable CT
					JOIN Un_Unit U ON Ct.UnitID = U.UnitID
					JOIN Un_Convention C ON U.ConventionID = C.ConventionID
					GROUP BY 
						C.BeneficiaryID,
						YEAR(EffectDate)
					) NCt ON NCt.BeneficiaryID = B.BeneficiaryID
				LEFT JOIN (
					SELECT 
						B.BeneficiaryID,
						YearEffectDate = YEAR(Ct.EffectDate),
						SumCotisationFee = SUM(Ct.Cotisation+Ct.Fee)
					FROM Un_Beneficiary B
					JOIN Un_Convention C ON C.BeneficiaryID = B.BeneficiaryID
					JOIN Un_Unit U ON U.ConventionID = C.ConventionID
					JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
					JOIN Un_Oper O ON O.OperID = Ct.OperID
					LEFT JOIN @CotisationTable NCt ON NCt.CotisationID = Ct.CotisationID
					WHERE B.BeneficiaryID IN (
								SELECT C.BeneficiaryID 
								FROM @CotisationTable Ct
								JOIN Un_Unit U ON U.UnitID = Ct.UnitID
								JOIN Un_Convention C ON C.ConventionID = U.ConventionID)
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

			DROP TABLE #Tmp_BeneficiaryCeilingCfgAJU
			
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
