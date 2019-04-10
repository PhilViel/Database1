/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_ReturnBankLinkForRIT
Description         :	Fait l'insertion des NSF de la lecture des fichier de retour de la banque.  Elle crée des
								arrêts de paiement automatiquement, selon le cas.  Elle crée aussi des CPA 60 jours s'il y a
								lieu.
Valeurs de retours  :	@ReturnValue :
									> 0 : Le traitement a réussi.
									<= 0 : Le traitement a échoué.
Note                :	ADX0000479	IA	2004-10-19	Bruno Lapointe		Migration, normalisation et documentation
								ADX0000510	IA	2004-11-17	Bruno Lapointe		Une lettre par opération.
								ADX0001588	BR	2005-09-23	Bruno Lapointe		Remplacer les IDENT_CURRENT par des SCOPE_IDENTITY() 
								ADX0000800	IA	2006-02-02	Bruno Lapointe		Lettre de deuxième provision insuffisante
								ADX0000801	IA	2006-02-03	Bruno Lapointe		Lettre d’effet retourné pour raison de compte fermé
								ADX0000802	IA	2006-02-03	Bruno Lapointe		Lettre d’effet retourné pour raison de paiement arrêté
								ADX0000859	IA	2006-03-24	Bruno Lapointe		Adaptation des NSF pour PCEE 4.3
								ADX0001929	BR 2006-08-04	Bruno Lapointe		Ne double pas les arrêts de paiements ni les 
																							lettres (Documents).
								ADX0002310	BR	2007-02-23	Bruno Lapointe		Plusieurs arrêts de paiements créés pour un NSF
																							quand le CPA a plus d'une cotisation pour une même
																							conventions.
												2012-01-25	Éric Deshaies		La date d'effectivité du NSF doit être la date
																				d'effectivité de la transaction d'origine
												2014-06-18	Maxime Martel		BankReturnTypeID varchar(3) -> varchar(4)
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_ReturnBankLinkForRIT] (
	@ConnectID MoID, -- Identificateur unique de connexion de l'usager
	@SourceOperID MoID, -- Opération qui est la cause du NSF (L'effet retourné)
	@BankReturnFileID MoID, -- ID du fichier de retour de la banque.
	@BankReturnTypeID varchar(4), -- ID du type d'effet retourné (NSF, compte fermé etc.)
	@BankReturnTypeDesc MoDesc, -- Description du type d'effet retourné
	@BankReturnDate MoGetDate) -- Date à laquel on veut inscrire l'effet retourné.
AS
BEGIN
	DECLARE
		@iResult INTEGER,
		@OperID MoID,
		@OperID60Days MoID,
		@OperDate60Days MoGetDate,
		@SourceOperDate MoGetDate,
		@OperDate MoGetDate,
		@ProcResult MoID,
		@ConventionID MoID

	SELECT 
		@OperDate = BankReturnFileDate
	FROM Mo_BankReturnFile
	WHERE BankReturnFileID = @BankReturnFileID

	SET @iResult = 1
	SET @OperID = 0

	IF NOT EXISTS (
		SELECT *
		FROM Un_Oper
		WHERE OperID = @SourceOperID
		)
		SET @iResult = -1

	IF @iResult > 0
		SELECT 
			@SourceOperDate = ISNULL(OperDate,GETDATE())
		FROM Un_Oper
		WHERE OperID = @SourceOperID

	IF @iResult > 0
	AND NOT EXISTS (
		SELECT 
			BankReturnCodeID
		FROM Mo_BankReturnLink
		WHERE BankReturnSourceCodeID = @SourceOperID)
	BEGIN
		-----------------
		BEGIN TRANSACTION
		-----------------

		IF NOT EXISTS (
				SELECT
					BankReturnTypeID
				FROM Mo_BankReturnType 
				WHERE @BankReturnTypeID = BankReturnTypeID)
			INSERT INTO Mo_BankReturnType (
				BankReturnTypeID,
				BankReturnTypeDesc)
			VALUES (
				@BankReturnTypeID,
				@BankReturnTypeDesc)

		IF @@ERROR <> 0
			SET @iResult = -2

		IF @iResult > 0
		BEGIN
			INSERT INTO Un_Oper (
				ConnectID,
				OperTypeID,
				OperDate)
			VALUES (
				@ConnectID,
				'NSF',
				@BankReturnDate)

			IF @@ERROR <> 0
				SET @iResult = -3
			ELSE
			BEGIN
				SET @OperID = SCOPE_IDENTITY()
				SET @iResult = @OperID
			END
		END

		IF @iResult > 0
		BEGIN
			INSERT INTO Un_Cotisation (
					UnitID, 
					OperID, 
					EffectDate, 
					Cotisation, 
					Fee, 
					BenefInsur, 
					SubscInsur, 
					TaxOnInsur)
				SELECT
					UnitID,
					@OperID,
					EffectDate,
					Cotisation * -1,
					Fee * -1,
					BenefInsur * -1,
					SubscInsur * -1,
					TaxOnInsur * -1
				FROM Un_Cotisation
				WHERE OperID = @SourceOperID

			IF @@ERROR <> 0
				SET @iResult = -4
		END

		IF @iResult > 0
		BEGIN
			INSERT INTO Un_PlanOper (
					OperID,
					PlanID,
					PlanOperTypeID,
					PlanOperAmount)
				SELECT 
					@OperID,
					PlanID,
					PlanOperTypeID,
					PlanOperAmount * -1
				FROM Un_PlanOper
				WHERE OperID = @SourceOperID

			IF @@ERROR <> 0
				SET @iResult = -5
		END

		IF @iResult > 0
		BEGIN
			INSERT INTO Un_ConventionOper (
					OperID,
					ConventionID,
					ConventionOperTypeID,
					ConventionOperAmount)
				SELECT 
					@OperID,
					ConventionID,
					ConventionOperTypeID,
					ConventionOperAmount * -1
				FROM Un_ConventionOper
				WHERE OperID = @SourceOperID

			IF @@ERROR <> 0
				SET @iResult = -5
		END

		IF @iResult > 0
		BEGIN
			INSERT INTO Mo_BankReturnLink (
					BankReturnFileID,
					BankReturnCodeID,
					BankReturnSourceCodeID,
					BankReturnTypeID)
				VALUES (
					@BankReturnFileID,
					@OperID,
					@SourceOperID,
					@BankReturnTypeID)

			IF @@ERROR <> 0
				SET @iResult = -6
		END

		IF @iResult > 0
		AND @BankReturnTypeID NOT IN ('901','908','911')
		BEGIN
			INSERT INTO Un_Breaking (
					ConventionID,
					BreakingTypeID,
					BreakingStartDate,
					BreakingEndDate,
					BreakingReason)
				SELECT DISTINCT
					U.ConventionID,
					'STP',
					@OperDate,
					NULL,
					@BankReturnTypeDesc
				FROM Un_Cotisation Ct
				JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
				LEFT JOIN Un_Breaking BRK ON BRK.ConventionID = U.ConventionID 
													AND @OperDate >= BRK.BreakingStartDate 
													AND ISNULL(BRK.BreakingEndDate,0) <= 0
				WHERE Ct.OperID = @SourceOperID
				  AND BRK.BreakingID IS NULL

			IF @@ERROR <> 0
				SET @iResult = -7
		END

		IF @iResult > 0
		AND @BankReturnTypeID IN ('901','908','911')
		BEGIN
			INSERT INTO Un_Breaking (
					ConventionID,
					BreakingTypeID,
					BreakingStartDate,
					BreakingEndDate,
					BreakingReason)
				SELECT DISTINCT
					U.ConventionID,
					'STP',
					@OperDate,
					NULL,
					@BankReturnTypeDesc
				FROM Un_Cotisation Ct
				JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
				LEFT JOIN Un_Breaking BRK ON BRK.ConventionID = U.ConventionID 
													AND @OperDate >= BRK.BreakingStartDate 
													AND ISNULL(BRK.BreakingEndDate,0) <= 0
				JOIN (
					SELECT 
						Ct.UnitID
					FROM Un_Cotisation Ct
					JOIN Un_Oper O ON O.OperID = Ct.OperID
					WHERE O.OperTypeID = 'NSF'
						AND (O.OperDate >= DATEADD(MONTH, -1, @SourceOperDate))
						AND (O.OperDate < @BankReturnDate)
					) NSF ON NSF.UnitID = Ct.UnitID
				WHERE Ct.OperID = @SourceOperID
				  AND BRK.BreakingID IS NULL

			IF @@ERROR <> 0
				SET @iResult = -8
		END

		IF @iResult > 0
		AND @BankReturnTypeID IN ('901','908','911')
		AND EXISTS (
				SELECT 
					Ct.CotisationID
				FROM Un_Cotisation Ct
				JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
				LEFT JOIN Un_Breaking BRK ON BRK.ConventionID = U.ConventionID 
													AND @OperDate >= BRK.BreakingStartDate 
													AND ISNULL(BRK.BreakingEndDate,0) <= 0
				LEFT JOIN (
					SELECT 
						Ct.UnitID
					FROM Un_Cotisation Ct
					JOIN Un_Oper O ON (O.OperID = Ct.OperID)
					WHERE (O.OperTypeID = 'NSF')
					  AND (O.OperDate >= DATEADD(MONTH, -1, @SourceOperDate))
					  AND (O.OperDate < @BankReturnDate)
					) NSF ON NSF.UnitID = Ct.UnitID
				WHERE Ct.OperID = @SourceOperID
				  AND BRK.BreakingID IS NULL
				  AND NSF.UnitID IS NULL)
		BEGIN
			SET @OperDate60Days = DATEADD(MONTH,2,@SourceOperDate)
         
			INSERT INTO Un_Oper (
				ConnectID,
				OperTypeID,
				OperDate)
			VALUES (
				@ConnectID,
				'CPA',
				@OperDate60Days)

			IF @@ERROR <> 0
				SET @iResult = -9
			ELSE
				SET @OperID60Days = SCOPE_IDENTITY()

			IF @iResult > 0
			BEGIN
				INSERT INTO Un_Cotisation (
						UnitID, 
						OperID, 
						EffectDate, 
						Cotisation, 
						Fee, 
						BenefInsur, 
						SubscInsur, 
						TaxOnInsur)
					SELECT 
						Ct.UnitID,
						@OperID60Days,
						@OperDate60Days,
						Ct.Cotisation,
						Ct.Fee,
						Ct.BenefInsur,
						Ct.SubscInsur,
						Ct.TaxOnInsur
					FROM Un_Cotisation Ct
					JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
					JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
					LEFT JOIN Un_Breaking BRK ON BRK.ConventionID = U.ConventionID 
														AND @OperDate >= BRK.BreakingStartDate 
														AND ISNULL(BRK.BreakingEndDate,0) <= 0
					LEFT JOIN (
						SELECT 
							Ct.UnitID
						FROM Un_Cotisation Ct
						JOIN Un_Oper O ON O.OperID = Ct.OperID
						WHERE O.OperTypeID = 'NSF'
							AND (O.OperDate >= DATEADD(MONTH, -1, @SourceOperDate))
							AND (O.OperDate < @BankReturnDate)
						) NSF ON NSF.UnitID = Ct.UnitID
					WHERE Ct.OperID = @SourceOperID
					  AND BRK.BreakingID IS NULL
					  AND NSF.UnitID IS NULL	

				IF @@ERROR <> 0
					SET @iResult = -10
			END

			IF @iResult > 0
			BEGIN
				INSERT INTO Un_ConventionOper (
						ConventionID, 
						OperID, 
						ConventionOperTypeID, 
						ConventionOperAmount)
					SELECT 
						Co.ConventionID,
						@OperID60Days,
						Co.ConventionOperTypeID,
						Co.ConventionOperAmount
					FROM Un_ConventionOper Co
					JOIN ( -- Opération sur convention seulement si une cotisation a été créé pour la même convention
						SELECT DISTINCT
							U.ConventionID
						FROM Un_Cotisation Ct
						JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
						WHERE OperID = @OperID60Days
						) C ON C.ConventionID = Co.ConventionID
					WHERE Co.OperID = @SourceOperID

				IF @@ERROR <> 0
					SET @iResult = -11
			END
		END

		-- Supprime les 400 non-expédiés de l'opération qui est la cause de l'effet retourné.
		IF @iResult > 0
		BEGIN
			DELETE Un_CESP400
			FROM Un_CESP400
			JOIN Un_Cotisation Ct ON Un_CESP400.CotisationID = Ct.CotisationID
			WHERE Ct.OperID = @SourceOperID
				AND Un_CESP400.iCESPSendFileID IS NULL

			IF @@ERROR <> 0
				SET @iResult = -12
		END

		-- Annule les 400 expédiés de l'opération qui est la cause de l'effet retourné.
		IF @iResult > 0
			EXECUTE @iResult = IU_UN_ReverseCESP400 @ConnectID, 0, @SourceOperID

		IF @iResult > 0
			------------------
			COMMIT TRANSACTION
			------------------
		ELSE
			--------------------
			ROLLBACK TRANSACTION
			--------------------

		DECLARE 
			@dtToday DATETIME,
			@iDocTypeID INTEGER,
			@vcConventionNos VARCHAR(7000),
			@vcConventionNo VARCHAR(75)

		-- Commande les lettres de NSF
		IF @iResult > 0 
		BEGIN
			IF @BankReturnTypeID = '901'
			-- Vérifie qu'il n'y ai pas eu de NSF le mois précédent 
			AND EXISTS (	SELECT DISTINCT
									Ct.UnitID
								FROM Un_Cotisation Ct2
								JOIN Un_Cotisation Ct ON Ct.UnitID = Ct2.UnitID
								JOIN Un_Oper O ON O.OperID = Ct.OperID
								JOIN Mo_BankReturnLink BL ON BL.BankReturnCodeID = O.OperID AND BL.BankReturnTypeID = '901'
								WHERE Ct2.OperID = @SourceOperID
									AND O.OperTypeID = 'NSF'
									AND (O.OperDate >= DATEADD(MONTH, -1, @SourceOperDate))
									AND (O.OperDate < @BankReturnDate)
									AND @BankReturnTypeID = '901'
							)
			BEGIN
				SET @dtToday = GETDATE()

				-- Va chercher le plus vieux numéro de convention.
				SELECT @vcConventionNo = C.ConventionNo
				FROM dbo.Un_Convention C
				JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
				JOIN (
					SELECT UnitID = MIN(U.UnitID)
					FROM dbo.Un_Unit U
					JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
					JOIN Un_Oper O ON O.OperID = Ct.OperID
					JOIN (
						SELECT InForceDate = MIN(U.InForceDate)
						FROM dbo.Un_Unit U
						JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
						JOIN Un_Oper O ON O.OperID = Ct.OperID
						WHERE O.OperID = @OperID
						) V ON V.InForceDate = U.InForceDate
					WHERE O.OperID = @OperID
					) V ON V.UnitID = U.UnitID

				-- Va chercher le bon type de document
				SELECT 
					@iDocTypeID = DocTypeID
				FROM CRQ_DocType
				WHERE DocTypeCode = '2ndPILetter'

				-- Commande la lettre uniquement si dans les deux derniers jours elle n'a pas déjà été commandée.
				IF NOT EXISTS (
					SELECT D.DocID
					FROM dbo.Un_Convention C
					JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
					JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
					JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
					JOIN Un_Oper ONSF ON ONSF.OperID = Ct.OperID
					JOIN Mo_BankReturnLink BL ON BL.BankReturnCodeID = ONSF.OperID
					JOIN Un_Oper O ON O.OperID = BL.BankReturnSourceCodeID
					JOIN ( -- Va chercher les templates les plus récents et qui n'entrent pas en vigueur dans le futur
						SELECT 
							LangID,
							DocTypeID,
							DocTemplateTime = MAX(DocTemplateTime)
						FROM CRQ_DocTemplate
						WHERE DocTypeID = @iDocTypeID
							AND (DocTemplateTime < @dtToday)
						GROUP BY
							LangID,
							DocTypeID
						) DT ON DT.LangID = HS.LangID
					JOIN CRQ_DocTemplate T ON DT.DocTypeID = T.DocTypeID AND DT.DocTemplateTime = T.DocTemplateTime AND T.LangID = HS.LangID
					JOIN CRQ_Doc D ON D.DocTemplateID = T.DocTemplateID AND D.DocGroup1 = @vcConventionNo 
										AND D.DocGroup2 = HS.LastName+', '+HS.FirstName
										AND D.DocOrderTime BETWEEN DATEADD(DAY,-2,@dtToday) AND @dtToday
					WHERE ONSF.OperID = @OperID
					)
					-- Lettre de deuxième provision insufisante
					EXECUTE RP_UN_2ndPILetter @ConnectID, 0, @OperID, 0
			END
			ELSE IF @BankReturnTypeID = '905'
			BEGIN
				SET @dtToday = GETDATE()

				-- Va chercher le plus vieux numéro de convention.
				SELECT @vcConventionNo = C.ConventionNo
				FROM dbo.Un_Convention C
				JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
				JOIN (
					SELECT UnitID = MIN(U.UnitID)
					FROM dbo.Un_Unit U
					JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
					JOIN Un_Oper O ON O.OperID = Ct.OperID
					JOIN (
						SELECT InForceDate = MIN(U.InForceDate)
						FROM dbo.Un_Unit U
						JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
						JOIN Un_Oper O ON O.OperID = Ct.OperID
						WHERE O.OperID = @OperID
						) V ON V.InForceDate = U.InForceDate
					WHERE O.OperID = @OperID
					) V ON V.UnitID = U.UnitID

				-- Va chercher le bon type de document
				SELECT 
					@iDocTypeID = DocTypeID
				FROM CRQ_DocType
				WHERE DocTypeCode = 'ClosedAccountLetter'

				-- Commande la lettre uniquement si dans les deux derniers jours elle n'a pas déjà été commandée.
				IF NOT EXISTS (
					SELECT D.DocID
					FROM dbo.Un_Convention C
					JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
					JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
					JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
					JOIN Un_Oper ONSF ON ONSF.OperID = Ct.OperID
					JOIN Mo_BankReturnLink BL ON BL.BankReturnCodeID = ONSF.OperID
					JOIN Un_Oper O ON O.OperID = BL.BankReturnSourceCodeID
					JOIN ( -- Va chercher les templates les plus récents et qui n'entrent pas en vigueur dans le futur
						SELECT 
							LangID,
							DocTypeID,
							DocTemplateTime = MAX(DocTemplateTime)
						FROM CRQ_DocTemplate
						WHERE DocTypeID = @iDocTypeID
							AND (DocTemplateTime < @dtToday)
						GROUP BY
							LangID,
							DocTypeID
						) DT ON DT.LangID = HS.LangID
					JOIN CRQ_DocTemplate T ON DT.DocTypeID = T.DocTypeID AND DT.DocTemplateTime = T.DocTemplateTime AND T.LangID = HS.LangID
					JOIN CRQ_Doc D ON D.DocTemplateID = T.DocTemplateID AND D.DocGroup1 = @vcConventionNo 
										AND D.DocGroup2 = HS.LastName+', '+HS.FirstName
										AND D.DocOrderTime BETWEEN DATEADD(DAY,-2,@dtToday) AND @dtToday
					WHERE ONSF.OperID = @OperID
					)
					-- Lettre d’effet retourné pour raison de compte fermé
					EXECUTE RP_UN_ClosedAccountLetter @ConnectID, 0, @OperID, 0
			END
			ELSE IF @BankReturnTypeID = '903'
			BEGIN
				SET @dtToday = GETDATE()

				-- Va chercher le plus vieux numéro de convention.
				SELECT @vcConventionNo = C.ConventionNo
				FROM dbo.Un_Convention C
				JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
				JOIN (
					SELECT UnitID = MIN(U.UnitID)
					FROM dbo.Un_Unit U
					JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
					JOIN Un_Oper O ON O.OperID = Ct.OperID
					JOIN (
						SELECT InForceDate = MIN(U.InForceDate)
						FROM dbo.Un_Unit U
						JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
						JOIN Un_Oper O ON O.OperID = Ct.OperID
						WHERE O.OperID = @OperID
						) V ON V.InForceDate = U.InForceDate
					WHERE O.OperID = @OperID
					) V ON V.UnitID = U.UnitID

				-- Va chercher le bon type de document
				SELECT 
					@iDocTypeID = DocTypeID
				FROM CRQ_DocType
				WHERE DocTypeCode = 'PaymentStoppedLetter'

				-- Commande la lettre uniquement si dans les deux derniers jours elle n'a pas déjà été commandée.
				IF NOT EXISTS (
					SELECT D.DocID
					FROM dbo.Un_Convention C
					JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
					JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
					JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
					JOIN Un_Oper ONSF ON ONSF.OperID = Ct.OperID
					JOIN Mo_BankReturnLink BL ON BL.BankReturnCodeID = ONSF.OperID
					JOIN Un_Oper O ON O.OperID = BL.BankReturnSourceCodeID
					JOIN ( -- Va chercher les templates les plus récents et qui n'entrent pas en vigueur dans le futur
						SELECT 
							LangID,
							DocTypeID,
							DocTemplateTime = MAX(DocTemplateTime)
						FROM CRQ_DocTemplate
						WHERE DocTypeID = @iDocTypeID
							AND (DocTemplateTime < @dtToday)
						GROUP BY
							LangID,
							DocTypeID
						) DT ON DT.LangID = HS.LangID
					JOIN CRQ_DocTemplate T ON DT.DocTypeID = T.DocTypeID AND DT.DocTemplateTime = T.DocTemplateTime AND T.LangID = HS.LangID
					JOIN CRQ_Doc D ON D.DocTemplateID = T.DocTemplateID AND D.DocGroup1 = @vcConventionNo 
										AND D.DocGroup2 = HS.LastName+', '+HS.FirstName
										AND D.DocOrderTime BETWEEN DATEADD(DAY,-2,@dtToday) AND @dtToday
					WHERE ONSF.OperID = @OperID
					)
					-- Lettre d’effet retourné pour raison de paiement arrêté
					EXECUTE RP_UN_PaymentStoppedLetter @ConnectID, 0, @OperID, 0
			END
			ELSE IF @BankReturnTypeID = '901'
			BEGIN
				SET @dtToday = GETDATE()

				-- Curseur de détail des objets d'opérations (Un_Oper)
				DECLARE CrConventionNo CURSOR FOR
					SELECT 
						C.ConventionNo
					FROM Un_Cotisation Ct 
					JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
					JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
					WHERE Ct.OperID = @OperID
					-----
					UNION
					-----
					SELECT 
						C.ConventionNo
					FROM Un_ConventionOper CO 
					JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
					WHERE CO.OperID = @OperID
						
				-- Ouvre le curseur
				OPEN CrConventionNo
			
				-- Va chercher la première opération
				FETCH NEXT FROM CrConventionNo
				INTO
					@vcConventionNo
			
				SET @vcConventionNos = ''
			
				WHILE @@FETCH_STATUS = 0
				BEGIN
					IF @vcConventionNos = ''
						SET @vcConventionNos = @vcConventionNo
					ELSE
						SET @vcConventionNos = @vcConventionNos+', '+@vcConventionNo
				
					FETCH NEXT FROM CrConventionNo
					INTO
						@vcConventionNo
				END
			
				-- Libère le curseur
				CLOSE CrConventionNo
				DEALLOCATE CrConventionNo

				-- Va chercher le bon type de document
				SELECT 
					@iDocTypeID = DocTypeID
				FROM CRQ_DocType
				WHERE DocTypeCode = 'NSFLetter'
				
				-- Commande la lettre uniquement si dans les deux derniers jours elle n'a pas déjà été commandée.
				IF NOT EXISTS (
					SELECT D.DocID
					FROM dbo.Un_Convention C
					JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
					JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
					JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
					JOIN Un_Oper ONSF ON ONSF.OperID = Ct.OperID
					JOIN Mo_BankReturnLink BL ON BL.BankReturnCodeID = ONSF.OperID
					JOIN Un_Oper O ON O.OperID = BL.BankReturnSourceCodeID
					JOIN ( -- Va chercher les templates les plus récents et qui n'entrent pas en vigueur dans le futur
						SELECT 
							LangID,
							DocTypeID,
							DocTemplateTime = MAX(DocTemplateTime)
						FROM CRQ_DocTemplate
						WHERE DocTypeID = @iDocTypeID
							AND (DocTemplateTime < @dtToday)
						GROUP BY
							LangID,
							DocTypeID
						) DT ON DT.LangID = HS.LangID
					JOIN CRQ_DocTemplate T ON DT.DocTypeID = T.DocTypeID AND DT.DocTemplateTime = T.DocTemplateTime AND T.LangID = HS.LangID
					JOIN CRQ_Doc D ON D.DocTemplateID = T.DocTemplateID 
										AND D.DocGroup1 = @vcConventionNos 
										AND D.DocGroup2 = HS.LastName+', '+HS.FirstName
										AND D.DocOrderTime BETWEEN DATEADD(DAY,-2,@dtToday) AND @dtToday
					WHERE ONSF.OperID = @OperID
					)
					-- Lettre 1 PI
					EXECUTE SP_RP_UN_NSFLetter @ConnectID, 0, @OperID, 0
			END
		END
	END
	ELSE
		SELECT 
			@iResult = BankReturnCodeID
		FROM Mo_BankReturnLink
		WHERE BankReturnSourceCodeID = @SourceOperID
	
	RETURN @iResult
END


