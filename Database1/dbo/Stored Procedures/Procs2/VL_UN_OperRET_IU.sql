
/********************************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	VL_UN_OperRET_IU
Description         :	Procédure de validation avant la sauvegarde d’ajout/modification de retraits.
Exemple d'appel		:   EXEC dbo.VL_UN_OperRET_IU 2
Valeurs de retours  :	Dataset : (Vide = pas d’erreur dans les validations)
									vcCode	VARCHAR(5)	Code de d’erreur
									vcInfo1	VARCHAR(100)	Première information supplémentaire, permet de faire des messages détaillés.
									vcInfo2	VARCHAR(100)	Deuxième information supplémentaire.
									vcInfo3	VARCHAR(100)	Troisième information supplémentaire.
								Erreurs possibles du Dataset :
									Code	RET01
									Message	Le montant de l’opération doit être plus petit que 0.00$.
									Code	RET02
									Message	La raison doit être sélectionnée.
									Code	RET03
									Info1	LigneTrans : Ligne de la transaction	
									Info2	Type d'argent (Cotisation, Fee, SubscInsur, BenefInsur ou TaxOnInsur)
									Info3	ConventionNo et InForceDate
									Message	Le montant retiré de [Info2] du groupe d’unité [Info3] est plus élevé que son solde.
									Code	RET04
									Message	La date d’opération doit être plus grande que la date de barrure du système.
									Code	RET05
									Message	Les multiples opérations ne sont pas gérées pour les RET.
									Code	RET06
									Message	Un retrait de cotisations excédentaires ne peut pas être de plus de 4000$ pour un bénéficiaire
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
												Info1 : Vide					Info2 : Vide		
									GEN12 -> Transaction refusée, car la convention est à l'état "Proposition"
												Info1 : Vide					Info2 : Vide						Info3 : Vide

								ReturnValue :
									> 0 : Réussite
									<= 0 : Erreurs.
										-1 -> Le blob n'existe pas
										-2 -> Update du blob par le service par encore fait
										-3 -> Les deux derniers caractères ne sont pas un saut de ligne et un retour de chariot
										-10 -> Erreur à la suppression du blob
Note                :	
						ADX0000862	IA	2006-03-31	Bruno Lapointe			Création
						ADX0001123	IA	2006-10-06	Alain Quirion			Modification : Ajout du code d'erreur RET06
										2010-04-06	Jean-François Gauthier	Ajout des validations sur les champs 
																			concernant la date d'opération et la date effective	
										2010-04-08	Jean-François Gauthier	Ajout de la validation du statut de la convention
																			afin de bloquer le traitement si l'état = "Proposition"																																						
										2010-11-26  Pierre Paquet			Correction: utilisation de @ConventionTable afin d'avoir le conventionID.
 *********************************************************************************************************************/
CREATE PROCEDURE [dbo].[VL_UN_OperRET_IU] (
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
									iIDBeneficiaire INT,		-- 2010-04-06 : JFG : Ajout du champ
									vcEtatConv		VARCHAR(3)) -- 2010-04-08 : JFG : Ajout du champ
		-- 2010-11-26 
		DECLARE @ConventionTable TABLE (
										OperID INT,
										ConventionID INT,
										dtDateSignature DATETIME)

		-- Table temporaire de raison de retrait
		DECLARE @WithdrawalReasonTable TABLE (
			LigneTrans INT,
			OperID INT,
			WithdrawalReasonID INT,
			tiCESP400WithdrawReasonID TINYINT)
	
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

		-- Rempli la table temporaire des raisons de retrait
		INSERT INTO @WithdrawalReasonTable
			SELECT *
			FROM dbo.FN_UN_WithdrawalReasonOfBlob(@iBlobID)	

		-- 2010-11-26  Remplir la table des conventions ID
		INSERT INTO @ConventionTable 
		SELECT CT.OperID, U.ConventionID, null 
		FROM @CotisationTable CT
			INNER JOIN dbo.UN_Unit U ON U.UnitID = CT.UnitID

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

		--*************** 2010-04-06 : Ajout : JFG  ****************************
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
			@LastVerifDate DATETIME,
			@SumConventionOper MONEY,
			@SumCotisation MONEY,
			@SumCotisationExc MONEY

		SELECT 
			@LastVerifDate = LastVerifDate
		FROM Un_Def

		SET @SumConventionOper = 0
		SET @SumCotisation = 0
		SET @SumCotisationExc = 0
	
		SELECT 
			@SumCotisation = ISNULL(SUM(Cotisation+Fee+BenefInsur+SubscInsur+TaxOnInsur),0)
		FROM @CotisationTable

		SELECT 
			@SumCotisationExc = ISNULL(SUM(Cotisation+Fee+BenefInsur+SubscInsur+TaxOnInsur),0)
		FROM @CotisationTable C
		JOIN @WithdrawalReasonTable WRT ON WRT.OperID = C.OperID
		JOIN Un_CESP400WithdrawReason WR ON WR.tiCESP400WithdrawReasonID = WRT.tiCESP400WithdrawReasonID
		WHERE WR.vcCESP400WithdrawReason = 'Retrait de cotisations excédentaires'
	
		SELECT 
			@SumConventionOper = ISNULL(SUM(ConventionOperAmount),0)
		FROM @ConventionOperTable

		-- Validation sur RET
		IF EXISTS (
				SELECT OperID
				FROM @OperTable
				WHERE OperTypeID = 'RET')
		BEGIN
			-- RET01 -> Le montant de l’opération doit être plus petit que 0.00$.
			IF @SumCotisation + @SumConventionOper >= 0
				INSERT INTO #WngAndErr
					SELECT 
						'RET01',
						'',
						'',
						''
				
			-- RET02 -> La raison du retrait doit être sélectionnée.
			IF NOT EXISTS (
					SELECT *
					FROM @WithdrawalReasonTable W
					LEFT JOIN @OperTable O ON O.OperTypeID = 'RET' AND O.OperID = W.OperID
					WHERE (WithdrawalReasonID BETWEEN 1 AND 6)
					  AND (O.OperID IS NOT NULL
						 OR W.OperID = 0))
				INSERT INTO #WngAndErr
					SELECT 
						'RET02',
						'',
						'',
						''

			-- RET03 -> À l’exception de l’intérêts chargés au client, les montants retirés ne devront pas dépasser ce qu’il y a dans le groupe d’unités.  
			--          Donc si on a cotisé 2.83$ de taxes avant la date d’opération dans le groupe d’unités X on ne pourra pas retirer plus de 2.83$ de taxes à ce dernier.
			INSERT INTO #WngAndErr
				SELECT
					'RET03',
					CAST(N.LigneTrans AS VARCHAR(100)),
					'Cotisation',
					C.ConventionNo + '->' + CAST(U.InForceDate AS VARCHAR(15))
				FROM ( -- Montant qu'on veut sauvegarder
					SELECT 
						UnitID,
						Cotisation = SUM(Cotisation) * -1,
						LigneTrans = MAX(LigneTrans)
					FROM @CotisationTable
					GROUP BY UnitID) N
				JOIN dbo.Un_Unit U ON U.UnitID = N.UnitID
				JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				-- Montant retiré avant la modification (si pas ajout)
				LEFT JOIN (
					SELECT 
						UnitID,
						Cotisation = SUM(Cotisation) * -1
					FROM Un_Cotisation Ct
					JOIN @OperTable OT ON OT.OperID = Ct.OperID
					GROUP BY UnitID) O ON O.UnitID = N.UnitID
				LEFT JOIN ( -- Montant de cotisation disponible avant modification ou ajout
					SELECT 
						Ct.UnitID,
						Cotisation = SUM(Cotisation)
					FROM Un_Cotisation Ct
					JOIN (
						SELECT DISTINCT UnitID
						FROM @CotisationTable 
						) T ON Ct.UnitID = T.UnitID
					GROUP BY Ct.UnitID) Ct ON Ct.UnitID = N.UnitID
				WHERE ((N.Cotisation > 0) -- Vérifie si on retire des cotisations
					AND (N.Cotisation > ISNULL(O.Cotisation,0)) -- Vérifie si le nouveau montant retiré est plus grand que l'ancien
					AND (N.Cotisation - ISNULL(O.Cotisation,0) > ISNULL(Ct.Cotisation,0))) -- Vérifie que le montant soit disponible
				-----
				UNION
				-----
				SELECT
					'RET03',
					CAST(N.LigneTrans AS VARCHAR(100)),
					'Fee',
					C.ConventionNo + '->' + CAST(U.InForceDate AS VARCHAR(15))
				FROM ( -- Montant qu'on veut sauvegarder
					SELECT 
						UnitID,
						Fee = SUM(Fee) * -1,
						LigneTrans = MAX(LigneTrans)
					FROM @CotisationTable
					GROUP BY UnitID) N
				JOIN dbo.Un_Unit U ON U.UnitID = N.UnitID
				JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				-- Montant retiré avant la modification (si pas ajout)
				LEFT JOIN (
					SELECT 
						UnitID,
						Fee = SUM(Fee) * -1
					FROM Un_Cotisation Ct
					JOIN @OperTable OT ON OT.OperID = Ct.OperID
					GROUP BY UnitID) O ON O.UnitID = N.UnitID
				LEFT JOIN ( -- Montant de frais disponible avant modification ou ajout
					SELECT 
						Ct.UnitID,
						Fee = SUM(Fee)
					FROM Un_Cotisation Ct
					JOIN (
						SELECT DISTINCT UnitID
						FROM @CotisationTable 
						) T ON Ct.UnitID = T.UnitID
					GROUP BY Ct.UnitID) Ct ON Ct.UnitID = N.UnitID
				WHERE ((N.Fee > 0) -- Vérifie si on retire des frais
					AND (N.Fee > ISNULL(O.Fee,0)) -- Vérifie si le nouveau montant retiré est plus grand que l'ancien
					AND (N.Fee - ISNULL(O.Fee,0) > ISNULL(Ct.Fee,0))) -- Vérifie que le montant soit disponible
				-----
				UNION
				-----
				SELECT
					'RET03',
					CAST(N.LigneTrans AS VARCHAR(100)),
					'SubscInsur',
					C.ConventionNo + '->' + CAST(U.InForceDate AS VARCHAR(15))
				FROM ( -- Montant qu'on veut sauvegarder
					SELECT 
						UnitID,
						SubscInsur = SUM(SubscInsur) * -1,
						LigneTrans = MAX(LigneTrans)
					FROM @CotisationTable
					GROUP BY UnitID) N
				JOIN dbo.Un_Unit U ON U.UnitID = N.UnitID
				JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				-- Montant retiré avant la modification (si pas ajout)
				LEFT JOIN (
					SELECT 
						UnitID,
						SubscInsur = SUM(SubscInsur) * -1
					FROM Un_Cotisation Ct
					JOIN @OperTable OT ON OT.OperID = Ct.OperID
					GROUP BY UnitID) O ON O.UnitID = N.UnitID
				LEFT JOIN ( -- Montant d'assurance souscripteur disponible avant modification ou ajout
					SELECT 
						Ct.UnitID,
						SubscInsur = SUM(SubscInsur)
					FROM Un_Cotisation Ct
					JOIN (
						SELECT DISTINCT UnitID
						FROM @CotisationTable 
						) T ON Ct.UnitID = T.UnitID
					GROUP BY Ct.UnitID) Ct ON Ct.UnitID = N.UnitID
				WHERE ((N.SubscInsur > 0) -- Vérifie si on retire de l'assurance souscripteur
					AND (N.SubscInsur > ISNULL(O.SubscInsur,0)) -- Vérifie si le nouveau montant retiré est plus grand que l'ancien
					AND (N.SubscInsur - ISNULL(O.SubscInsur,0) > ISNULL(Ct.SubscInsur,0))) -- Vérifie que le montant soit disponible
				-----
				UNION
				-----
				SELECT
					'RET03',
					CAST(N.LigneTrans AS VARCHAR(100)),
					'BenefInsur',
					C.ConventionNo + '->' + CAST(U.InForceDate AS VARCHAR(15))
				FROM ( -- Montant qu'on veut sauvegarder
					SELECT 
						UnitID,
						BenefInsur = SUM(BenefInsur) * -1,
						LigneTrans = MAX(LigneTrans)
					FROM @CotisationTable
					GROUP BY UnitID) N
				JOIN dbo.Un_Unit U ON U.UnitID = N.UnitID
				JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				-- Montant retiré avant la modification (si pas ajout)
				LEFT JOIN (
					SELECT 
						UnitID,
						BenefInsur = SUM(BenefInsur) * -1
					FROM Un_Cotisation Ct
					JOIN @OperTable OT ON OT.OperID = Ct.OperID
					GROUP BY UnitID) O ON O.UnitID = N.UnitID
				LEFT JOIN ( -- Montant d'assurance bénéficiaire disponible avant modification ou ajout
					SELECT 
						Ct.UnitID,
						BenefInsur = SUM(BenefInsur)
					FROM Un_Cotisation Ct
					JOIN (
						SELECT DISTINCT UnitID
						FROM @CotisationTable 
						) T ON Ct.UnitID = T.UnitID
					GROUP BY Ct.UnitID) Ct ON Ct.UnitID = N.UnitID
				WHERE ((N.BenefInsur > 0) -- Vérifie si on retire de l'assurance bénéficiaire
					AND (N.BenefInsur > ISNULL(O.BenefInsur,0)) -- Vérifie si le nouveau montant retiré est plus grand que l'ancien
					AND (N.BenefInsur - ISNULL(O.BenefInsur,0) > ISNULL(Ct.BenefInsur,0))) -- Vérifie que le montant soit disponible
				-----
				UNION
				-----
				SELECT
					'RET03',
					CAST(N.LigneTrans AS VARCHAR(100)),
					'TaxOnInsur',
					C.ConventionNo + '->' + CAST(U.InForceDate AS VARCHAR(15))
				FROM ( -- Montant qu'on veut sauvegarder
					SELECT 
						UnitID,
						TaxOnInsur = SUM(TaxOnInsur) * -1,
						LigneTrans = MAX(LigneTrans)
					FROM @CotisationTable
					GROUP BY UnitID) N
				JOIN dbo.Un_Unit U ON U.UnitID = N.UnitID
				JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				-- Montant retiré avant la modification (si pas ajout)
				LEFT JOIN (
					SELECT 
						UnitID,
						TaxOnInsur = SUM(TaxOnInsur) * -1
					FROM Un_Cotisation Ct
					JOIN @OperTable OT ON OT.OperID = Ct.OperID
					GROUP BY UnitID) O ON O.UnitID = N.UnitID
				LEFT JOIN ( -- Montant de taxes sur l'assurance disponible avant modification ou ajout
					SELECT 
						Ct.UnitID,
						TaxOnInsur = SUM(TaxOnInsur)
					FROM Un_Cotisation Ct
					JOIN (
						SELECT DISTINCT UnitID
						FROM @CotisationTable 
						) T ON Ct.UnitID = T.UnitID
					GROUP BY Ct.UnitID) Ct ON Ct.UnitID = N.UnitID
				WHERE ((N.TaxOnInsur > 0) -- Vérifie si on retire des taxes sur l'assurance
					AND (N.TaxOnInsur > ISNULL(O.TaxOnInsur,0)) -- Vérifie si le nouveau montant retiré est plus grand que l'ancien
					AND (N.TaxOnInsur - ISNULL(O.TaxOnInsur,0) > ISNULL(Ct.TaxOnInsur,0))) -- Vérifie que le montant soit disponible

			-- RET04 -> La date d’opération doit être plus grande que la date de barrure du système
			INSERT INTO #WngAndErr
				SELECT 
					'RET04',
					'',
					'',
					''
				FROM @OperTable OT
				LEFT JOIN Un_Oper O ON OT.OperID = O.OperID
				WHERE ISNULL(dbo.FN_CRQ_DateNoTime(O.OperDate),@LastVerifDate+1) <= dbo.FN_CRQ_DateNoTime(@LastVerifDate)
					OR ISNULL(dbo.FN_CRQ_DateNoTime(OT.OperDate),0) <= dbo.FN_CRQ_DateNoTime(@LastVerifDate)

			-- RET05 : Les multiples opérations ne sont pas géré pour les RET 
			IF EXISTS (SELECT COUNT(OperID) FROM @OperTable HAVING COUNT(OperID) > 1) 
				INSERT INTO #WngAndErr
					SELECT 
						'RET05',
						'',
						'',
						''
			--RET06 : Un retrait de cotisations excédentaires ne peut pas être de plus de 4000$ pour un bénéficiaire.
			IF @SumCotisationExc < -4000
				INSERT INTO #WngAndErr
					SELECT
						'RET06',
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


