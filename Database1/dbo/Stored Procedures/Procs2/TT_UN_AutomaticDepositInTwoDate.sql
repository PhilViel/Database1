/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	TT_UN_AutomaticDepositInTwoDate
Description         :	Procédure générant automatiquement les CPA à envoyé à la banque.
Valeurs de retours  :	@ReturnValue :
									> 0 : Le traitement a réussi.
									<= 0: Le traitement a échouée.
Note                :	
						ADX0000532	IA	2004-10-12	Bruno Lapointe		12.56 - Migration, normalisation, optimisation et
																		modification.
						ADX0000532	IA	2004-10-22	Bruno Lapointe		12.56 - Remet à 0 le nb de jour à ajouter de la 
																		configuration pour cette journée de la semaine.
						ADX0000720	IA	2005-07-19	Bruno Lapointe		Modifier le traitement pour qu'il n'expédie pas 
																		les CPA annulés ou anticipés. 
						ADX0001602	BR	2005-10-11	Bruno Lapointe		SCOPE_IDENTITY au lieu de IDENT_CURRENT
						ADX0000804	IA	2006-04-06	Bruno Lapointe		Création des enregistrements 400
						ADX0001235	IA	2007-02-14	Alain Quirion		Utilisation de dtRegStartDate pour la date de début de régime
						ADX0001355	IA	2007-06-06	Alain Quirion		Utilisation de la nouvelle méthode de calcule pour déterminer 
																						la date de fin de cotisation du groupe d’unités
										2010-10-04	Steve Gouin			Gestion des disable trigger par #DisableTrigger
										2010-10-14	Frederick Thibault	Ajout du champ fACESGPart pour régler le problème SCEE+
										2014-09-25	Pierre-Luc Simard	Génère le 1er CPA lorsque le groupe d'unités a été créé via la proposition électronique
										2015-03-24	Pierre-Luc Simard	Le 1er CPA n'est pas créé si le groupe d'unité a déjà une date de premier dépôt 
																						et s'il est créé via la proposition électronique. Le 1er dépôt a donc été fait manuellement.
										2015-04-20	Pierre-Luc Simard	Retirer la logique avec la table Un_HalfSubscriberInsurance pour simplifier le code puisque plus utilisé. 
										2015-04-20	Pierre-Luc Simard	Créer le premier dépôt dès que possible, à partir de la date du début des opérations financières.
										2015-06-16	Pierre-Luc Simard	Ne plus créer les dépôt subséquents si le premier dépôt n'est pas fait ou avant la date de début des opérations
										2015-08-03	Pierre-Luc Simard	Vérifier l'existence d'une cotisation au lieu d'utiliser la dtFirstDeposit. Permet de créer un CPA même si un TFR existe.
                                        2016-07-18  Pierre-Luc Simard   Utilisation du montant souscrit avec écart pour les dépôts forfaitaires
                                        2018-02-12  Pierre-Luc Simard   Exclure les aussi les groupes d'unités avec un RIN partiel
										2018-05-17	Maxime Martel		JIRA : MC-438 Intégrer le 60 / 40 dans le traitement de nuit
										2018-09-07	Maxime Martel		JIRA MP-699 Ajout de OpertypeID COU
										2018-10-10  Maxime Martel		JIRA : MP-1761 erreur de date effective
										2018-10-31  Maxime Martel		JIRA : PROD-12212 Régime T : s'assurer que la totalité du prélèvement soit en "Épargne" et non 60/40
										2018-12-12	Maxime Martel       PROD-13232 ajouter 1 journée à la date de traitement pour exclure la cotisation lors du split collectif
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_AutomaticDepositInTwoDate] (
	@ConnectID INTEGER, -- Identificateur unique de connexion de l'usager
	@BeginDate DATETIME, -- Date de début de l'interval à traiter
	@EndDate DATETIME ) -- Date de fin de l'interval à traiter
AS
BEGIN
	--ALTER TABLE Un_Cotisation
	--	DISABLE TRIGGER TUn_Cotisation_State
	IF object_id('tempdb..#DisableTrigger') is null
		CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))

	INSERT INTO #DisableTrigger VALUES('TUn_Cotisation_State')				

	DECLARE
		@ResultID INTEGER,
		@AutomaticDepositDate DATETIME,
		@EffectDateCotisation DATETIME,
		@OldAccountName VARCHAR(75),
		@OldTransitNo VARCHAR(75),
		@OldBankID INTEGER,
		@OldUnitID INTEGER,
		@BankFileID INTEGER,
		@NewOperID INTEGER,
		@OperID INTEGER,
		@UnitID INTEGER,
		@UnitQty MONEY,
		@FeeSplitByUnit MONEY,
		@FeeByUnit MONEY,
		@CotisationID INTEGER,
		@AccountName VARCHAR(75),
		@TransitNo VARCHAR(75),
		@BankID INTEGER,
		@CotisationFee MONEY,
		@mFrais_CotisationCourante MONEY,
		@Cotisation MONEY,
		@Fee MONEY,
		@BenefInsur MONEY,
		@SubscInsur MONEY,
		@TaxOnInsur MONEY,
		@TotCotFee MONEY,
		@MntSouscrit MONEY,
		@ConventionID INTEGER,
		@LastDepositMaxInInterest MONEY

	-- Enlève les heures aux dates de début et de fin de l'interval
	SET @BeginDate = dbo.fn_Mo_DateNoTime(@BeginDate)
	SET @EndDate = dbo.fn_Mo_DateNoTime(@EndDate)

	BEGIN TRANSACTION

	IF @@ERROR <> 0 
		SET @BankFileID = -1
	ELSE
		SET @BankFileID = 1

	IF @BankFileID > 0
	BEGIN
		SELECT
			@LastDepositMaxInInterest = LastDepositMaxInInterest
		FROM Un_Def

		SET @AutomaticDepositDate = @BeginDate

		--Table temporaire contenant les conventions dont la date de dépôt
		--maximal est entre la date de début et la date de fin des CPA
		SELECT
			VI.ConventionID,
			MaxConvDepositDate = DATEADD(YEAR, M.YearQty, CASE 
													  WHEN ISNULL(VI.dtCotisationEndDateAdjust, VI.InForceDate+1) < VI.InForceDate 
																AND ISNULL(VI.dtCotisationEndDateAdjust, VI.InForceDate+1) < ISNULL(C.dtInforceDateTIN, VI.InForceDate)
																THEN VI.dtCotisationEndDateAdjust
													  WHEN ISNULL(C.dtInforceDateTIN, VI.InForceDate+1) < VI.InForceDate THEN C.dtInforceDateTIN
													  ELSE VI.InForceDate
												END)
		INTO #MaxConvDate
		FROM Un_MaxConvDepositDateCfg M
		JOIN (
			SELECT
				ConventionID,
				InForceDate = MIN(InForceDate),
				dtCotisationEndDateAdjust = MIN(dtCotisationEndDateAdjust)
			FROM dbo.Un_Unit
			GROUP BY ConventionID
			) VI ON VI.InForceDate >= M.EffectDate	
		JOIN dbo.Un_Convention C ON C.ConventionID = VI.ConventionID	
		WHERE (M.EffectDate IN( 
			SELECT
				MAX(EffectDate)
			FROM Un_MaxConvDepositDateCfg
			WHERE EffectDate <= VI.InForceDate))
		  AND (DATEADD(YEAR, M.YearQty, VI.InForceDate) <= DATEADD(DAY, 1, @EndDate))

		WHILE (@AutomaticDepositDate < DATEADD(DAY, 1, @EndDate))
		  AND (@BankFileID > 0)
		BEGIN
			-- Création d'une table de ConventionID indexé contenant tous les conventions avec arrêt de paiement
			CREATE TABLE #TT_CPA_Breaking (
				ConventionID INTEGER PRIMARY KEY)

			INSERT INTO #TT_CPA_Breaking
				SELECT DISTINCT
					ConventionID
				FROM Un_Breaking
				WHERE @AutomaticDepositDate BETWEEN BreakingStartDate AND ISNULL(BreakingEndDate, DATEADD(DAY, 1, @AutomaticDepositDate))

			-- Création d'une table de UnitID indexé contenant tous les groupes d'unités avec arrêt de paiement
			CREATE TABLE #TT_CPA_HoldPayment (
				UnitID INTEGER PRIMARY KEY)

			INSERT INTO #TT_CPA_HoldPayment
				SELECT DISTINCT
					UnitID
				FROM dbo.Un_UnitHoldPayment
				WHERE @AutomaticDepositDate BETWEEN StartDate AND ISNULL(EndDate, DATEADD(DAY, 1, @AutomaticDepositDate))

			IF @@ERROR <> 0
				SET @BankFileID = -17 

			-- -------------------------------------
			-- Début de la gestion des CPA anticipés
			-- -------------------------------------
			IF @BankFileID > 0
			BEGIN
				--Suppression des cotisations qui se trouve en arrêt de paiement sur convention
				DELETE Un_Cotisation
				FROM Un_Cotisation
				JOIN (
					SELECT DISTINCT 
						Ct.CotisationID
					FROM Un_Cotisation Ct
					JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
					JOIN Un_Oper O ON O.OperID = Ct.OperID
					JOIN #TT_CPA_Breaking B ON B.ConventionID = U.ConventionID 
					LEFT JOIN Un_OperBankFile OBF ON OBF.OperID = O.OperID
					LEFT JOIN Un_OperCancelation OC ON OC.OperID = O.OperID OR OC.OperSourceID = O.OperID
					WHERE O.OperDate = @AutomaticDepositDate
						AND O.OperTypeID = 'CPA'
						AND OBF.OperID IS NULL
						AND OC.OperID IS NULL
					) V ON V.CotisationID = Un_Cotisation.CotisationID

				IF @@ERROR <> 0
					SET @BankFileID = -3 --Erreur de suppression des cotisations qui se trouve en arrêt de paiement sur convention
			END

			IF @BankFileID > 0
			BEGIN
				--Suppression des cotisations qui se trouve en arrêt de paiement sur groupe d'unités
				DELETE Un_Cotisation
				FROM Un_Cotisation
				JOIN (
					SELECT DISTINCT 
						Ct.CotisationID
					FROM Un_Cotisation Ct
					JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
					JOIN Un_Oper O ON O.OperID = Ct.OperID
					JOIN #TT_CPA_HoldPayment H ON H.UnitID = U.UnitID 
					LEFT JOIN Un_OperBankFile OBF ON OBF.OperID = O.OperID
					LEFT JOIN Un_OperCancelation OC ON OC.OperID = O.OperID OR OC.OperSourceID = O.OperID
					WHERE O.OperDate = @AutomaticDepositDate
						AND O.OperTypeID = 'CPA'
						AND OBF.OperID IS NULL
						AND OC.OperID IS NULL
					) V ON V.CotisationID = Un_Cotisation.CotisationID

				IF @@ERROR <> 0
					SET @BankFileID = -4 -- Erreur de suppression des cotisations qui se trouve en arrêt de paiement sur groupe d'unités
			END

			IF @BankFileID > 0
			BEGIN
				-- Suppression des opérations sur convention (Intérêts chargé au client) qui n'ont pas une cotisation pour la même convention dans la même opération.
				DELETE dbo.Un_ConventionOper
				FROM dbo.Un_ConventionOper
				JOIN (
					SELECT DISTINCT
						CO.ConventionOperID
					FROM dbo.Un_ConventionOper CO
					JOIN Un_Oper O ON O.OperID = CO.OperID
					LEFT JOIN Un_OperBankFile OBF ON (OBF.OperID = O.OperID)
					LEFT JOIN Un_OperCancelation OC ON OC.OperID = O.OperID OR OC.OperSourceID = O.OperID
					LEFT JOIN (
						SELECT DISTINCT
							U.ConventionID,
							O.OperID
						FROM Un_Cotisation Ct
						JOIN Un_Oper O ON O.OperID = Ct.OperID
						JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
						WHERE O.OperDate = @AutomaticDepositDate
						  AND O.OperTypeID = 'CPA'
						) Ct ON Ct.ConventionID = CO.ConventionID AND Ct.OperID = O.OperID
					WHERE O.OperDate = @AutomaticDepositDate
						AND O.OperTypeID = 'CPA'
						AND Ct.OperID IS NULL
						AND OBF.OperID IS NULL
						AND OC.OperID IS NULL
					) V ON V.ConventionOperID = dbo.Un_ConventionOper.ConventionOperID

				IF @@ERROR <> 0
					SET @BankFileID = -5 -- -- Erreur de suppression des opérations sur convention (Intérêts chargé au client) qui n'ont pas une cotisation pour la même convention dans la même opération.
			END

			-- Cette boucle gère les CPA anticipés, elle crée une opération par groupe de CPA anticipé qui on le même compte bancaire sur la convention.
			-- Elle divise aussi les opérations qui ont des CPA sur les conventions qui ont des comptes bancaires différents.
			IF @BankFileID > 0
			BEGIN
				DECLARE UnCPAVentToDo CURSOR FOR
					SELECT
						Ct.CotisationID,
						Ct.UnitID,
						CotisationFee = Ct.Cotisation + Ct.Fee,
						Ct.OperID,
						CT.Fee
					FROM Un_Cotisation Ct
					JOIN Un_Oper O ON O.OperID = Ct.OperID
					LEFT JOIN Un_OperBankFile OBF ON OBF.OperID = O.OperID
					LEFT JOIN Un_OperCancelation OC ON OC.OperID = O.OperID OR OC.OperSourceID = O.OperID
					WHERE O.OperDate = @AutomaticDepositDate
						AND OBF.OperID IS NULL
						AND OC.OperID IS NULL
						AND O.OperTypeID = 'CPA'

				OPEN UnCPAVentToDo

				FETCH NEXT FROM UnCPAVentToDo
				INTO
					@CotisationID,
					@UnitID,
					@CotisationFee,
					@OperID,
					@mFrais_CotisationCourante

				WHILE @@FETCH_STATUS = 0
				  AND (@BankFileID > 0)
				BEGIN
					-- Cette partie du code subdivise les opérations (CPA) qui font référence à des conventions qui ont des comptes bancaires différents.
					-- À la fin, toute les opérations (CPA) n'auront qu'un seul compte bancaire.
					IF EXISTS (
							SELECT
								V.OperID
							FROM (
								SELECT
									O.OperID,
									CA.BankID,
									CA.AccountName,
									CA.TransitNo
								FROM Un_Oper O
								JOIN Un_Cotisation Ct ON (O.OperID = Ct.OperID)
								JOIN dbo.Un_Unit U ON (U.UnitID = Ct.UnitID)
								JOIN dbo.Un_ConventionAccount CA ON (CA.ConventionID = U.ConventionID)
								WHERE (O.OperID = @OperID)
								GROUP BY
									O.OperID,
									CA.BankID,
									CA.AccountName,
									CA.TransitNo
								) V
							GROUP BY
								V.OperID
							HAVING COUNT(CAST(V.BankID AS VARCHAR(4)) + V.AccountName + V.TransitNo) > 1)
					BEGIN
						-- Insert une nouvelle opération
						INSERT INTO Un_Oper (
							ConnectID,
							OperTypeID,
							OperDate)
						VALUES (
							@ConnectID,
							'CPA',
							@AutomaticDepositDate)

						IF @@ERROR <> 0
							SET @BankFileID = -6 -- Erreur à la création d'une opération
						ELSE
						BEGIN
							SET @NewOperID = SCOPE_IDENTITY()

							-- Transfert dans la nouvelle opération les cotisations dont le compte bancaire est le même que celui de la cotisation traitée (Table temporaire).
							UPDATE Un_Cotisation
							SET OperID = @NewOperID
							FROM Un_Cotisation
							JOIN dbo.Un_Unit U ON U.UnitID = Un_Cotisation.UnitID
							JOIN dbo.Un_ConventionAccount CA ON CA.ConventionID = U.ConventionID
							JOIN Un_Cotisation Ct ON Ct.OperID = Un_Cotisation.OperID
							JOIN dbo.Un_Unit U2 ON U2.UnitID = Ct.UnitID
							JOIN dbo.Un_ConventionAccount CA2 ON CA2.ConventionID = U2.ConventionID
							WHERE Ct.CotisationID = @CotisationID
							  AND CA.BankID = CA2.BankID
							  AND CA.AccountName = CA2.AccountName
							  AND CA.TransitNo = CA2.TransitNo

							IF @@ERROR <> 0
								SET @BankFileID = -7 
						END

						IF @BankFileID > 0
						BEGIN
							-- Transfert dans la nouvelle opération les opérations sur convention dont le compte bancaire est le même que celui de la cotisation traitée.
							UPDATE dbo.Un_ConventionOper
							SET OperID = @NewOperID
							FROM dbo.Un_ConventionOper
							JOIN dbo.Un_ConventionAccount CA ON CA.ConventionID = dbo.Un_ConventionOper.ConventionID
							JOIN Un_Cotisation Ct ON Ct.OperID = dbo.Un_ConventionOper.OperID
							JOIN dbo.Un_Unit U2 ON U2.UnitID = Ct.UnitID
							JOIN dbo.Un_ConventionAccount CA2 ON CA2.ConventionID = U2.ConventionID
							WHERE Ct.CotisationID = @CotisationID
							  AND CA.BankID = CA2.BankID
							  AND CA.AccountName = CA2.AccountName
							  AND CA.TransitNo = CA2.TransitNo

							IF @@ERROR <> 0
								SET @BankFileID = -8
						END
					END

					IF @BankFileID > 0
					BEGIN
						SELECT @EffectDateCotisation = EffectDate
						FROM Un_Cotisation
						WHERE CotisationID = @CotisationID

						/* Nous ajoutons 1 journée à la date du traitement pour la date effective de cette cotisation pour ne pas 
						quel soit prise en compte dans le calcul de répartition SUn_NewDepositDistribution afin d'avoir le bon montant 
						en frais et épargne pour cette cotisation.
						*/
						UPDATE Un_Cotisation
						SET EffectDate = DATEADD(DAY, 1, @AutomaticDepositDate) --EffectDate)
						WHERE CotisationID = @CotisationID

						IF @@ERROR <> 0
							SET @BankFileID = -9
						ELSE
						BEGIN
							
							DECLARE @PlanID int,
									@ConventionNo varchar(15)

							SELECT 
								@PlanID = PlanId,
								@ConventionNo = c.ConventionNo
							FROM Un_Unit U
							JOIN Un_Convention C on C.ConventionID = U.ConventionID
							WHERE u.UnitID = @UnitID

							IF @PlanID = 4 
							BEGIN
								
								IF @ConventionNo LIKE 'T-%' 
								BEGIN
									SET @Fee = 0
									SET	@Cotisation = @CotisationFee
								END
								ELSE
								BEGIN

									-- Refait la distribution des frais et de l'épargnes individuel
									DECLARE @frais MoMoney

									SELECT @frais = frais 
									FROM Un_unit U 
									LEFT JOIN dbo.fntCONV_ObtenirFraisIndividuelEnDate(@AutomaticDepositDate, NULL) FRAIS ON FRAIS.UnitID = U.UnitID
									WHERE U.UnitID = @UnitID

									SET @frais = @frais - @mFrais_CotisationCourante

									SELECT 
										@Cotisation = @CotisationFee - dbo.fnGENE_ObtenirPlusPetiteValeurMonetaire(dbo.fnGENE_ObtenirPlusPetiteValeurMonetaire(@CotisationFee * 0.4, 200), 200 - @frais),
										@Fee = dbo.fnGENE_ObtenirPlusPetiteValeurMonetaire(dbo.fnGENE_ObtenirPlusPetiteValeurMonetaire(@CotisationFee * 0.4, 200), 200 - @frais)
								
								END
							END
							ELSE
								-- Refait la distribution des frais et de l'épargnes collective
								EXEC SUn_NewDepositDistribution
								@ConnectID,
								@UnitID,
								@CotisationFee,
								@AutomaticDepositDate,
								@Cotisation OUTPUT,
								@Fee OUTPUT		

							UPDATE Un_Cotisation 
							SET
								Cotisation = @Cotisation,
								Fee = @Fee,
								EffectDate = @EffectDateCotisation
							WHERE CotisationID = @CotisationID
							  AND (Cotisation <> @Cotisation
								 OR Fee <> @Fee
								 OR EffectDate = DATEADD(DAY, 1, @AutomaticDepositDate))

							IF @@ERROR <> 0
								SET @BankFileID = -10

						END
					END

					-- Passe au prochain enregistrement du curseur
					FETCH NEXT FROM UnCPAVentToDo
					INTO
						@CotisationID,
						@UnitID,
						@CotisationFee,
						@OperID,
						@mFrais_CotisationCourante
				END

				-- Ferme le curseur	
				CLOSE UnCPAVentToDo
				DEALLOCATE UnCPAVentToDo

				-- Regroupe les CPA anticipé avec les mêmes informations bancaires
				IF @BankFileID > 0
				BEGIN
					SELECT
						MIN(O.OperID) AS OperID,
						CA.BankID,
						CA.AccountName,
						CA.TransitNo
					INTO #UniqueAccountOper
					FROM Un_Oper O
					JOIN Un_Cotisation Ct ON Ct.OperID = O.OperID
					JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
					JOIN dbo.Un_ConventionAccount CA ON CA.ConventionID = U.ConventionID
					LEFT JOIN Un_OperBankFile OBF ON OBF.OperID = O.OperID
					LEFT JOIN Un_OperCancelation OC ON OC.OperID = O.OperID OR OC.OperSourceID = O.OperID
					WHERE O.OperDate = @AutomaticDepositDate
						AND OBF.OperID IS NULL
						AND OC.OperID IS NULL
					GROUP BY
						CA.BankID,
						CA.AccountName,
						CA.TransitNo

					IF @@ERROR <> 0
						SET @BankFileID = -10
				END

				-- Regroupe les CPA anticipé avec les mêmes informations bancaires
				IF @BankFileID > 0
				BEGIN
					UPDATE Un_Cotisation
					SET OperID = OCA.OperID
					FROM Un_Cotisation
					JOIN dbo.Un_Unit U ON U.UnitID = Un_Cotisation.UnitID
					JOIN dbo.Un_ConventionAccount CA ON CA.ConventionID = U.ConventionID
					JOIN Un_Oper O ON O.OperID = Un_Cotisation.OperID
					LEFT JOIN Un_OperBankFile OBF ON OBF.OperID = O.OperID
					LEFT JOIN Un_OperCancelation OC ON OC.OperID = O.OperID OR OC.OperSourceID = O.OperID
					JOIN #UniqueAccountOper OCA ON OCA.BankID = CA.BankID AND OCA.AccountName = CA.AccountName AND OCA.TransitNo = CA.TransitNo
					WHERE OBF.OperID IS NULL
						AND OC.OperID IS NULL
						AND OCA.OperID <> Un_Cotisation.OperID
						AND O.OperTypeID = 'CPA'
						AND O.OperDate = @AutomaticDepositDate

					IF @@ERROR <> 0
						SET @BankFileID = -11
				END

				-- Regroupe les CPA anticipé avec les mêmes informations bancaires
				IF @BankFileID > 0
				BEGIN
					UPDATE dbo.Un_ConventionOper
					SET OperID = OCA.OperID
					FROM dbo.Un_ConventionOper
					JOIN dbo.Un_ConventionAccount CA ON (CA.ConventionID = dbo.Un_ConventionOper.ConventionID)
					JOIN Un_Oper O ON (O.OperID = dbo.Un_ConventionOper.OperID)
					LEFT JOIN Un_OperBankFile OBF ON (OBF.OperID = O.OperID)
					LEFT JOIN Un_OperCancelation OC ON OC.OperID = O.OperID OR OC.OperSourceID = O.OperID
					JOIN #UniqueAccountOper OCA ON (OCA.BankID = CA.BankID) AND (OCA.AccountName = CA.AccountName) AND (OCA.TransitNo = CA.TransitNo)
					WHERE OBF.OperID IS NULL
						AND OC.OperID IS NULL
						AND OCA.OperID <> dbo.Un_ConventionOper.OperID
						AND O.OperTypeID = 'CPA'
						AND O.OperDate = @AutomaticDepositDate

					IF @@ERROR = 0
						DROP TABLE #UniqueAccountOper

					IF @@ERROR <> 0
						SET @BankFileID = -12
				END
			END
			-- -------------------------------------
			-- Fin de la gestion des CPA anticipés
			-- -------------------------------------

			-- --------------------------------------------
			-- Début de la génération des CPA automatique	
			-- --------------------------------------------
			IF @BankFileID > 0
			BEGIN
				-- Création d'une table de UnitID indexé contenant tous les groupes d'unités avec arrêt de paiement
				CREATE TABLE #TT_CPA_AutomaticDeposit (
					UnitID INTEGER PRIMARY KEY)

				INSERT INTO #TT_CPA_AutomaticDeposit
					SELECT DISTINCT
						UnitID
					FROM Un_AutomaticDeposit
					WHERE (@AutomaticDepositDate >= StartDate)
					  AND ((ISNULL(EndDate,0) <= 0)
						 OR (@AutomaticDepositDate <= EndDate))

				IF @@ERROR <> 0
					SET @BankFileID = -18
			END

			IF @BankFileID > 0
			BEGIN
				-- Création d'une table de cotisation temporaire pour minimiser l'accès à la vrai table Un_Cotisation
				CREATE TABLE #TT_CPA_TmpInsCotisation (
					OperID INTEGER NOT NULL,
					UnitID INTEGER NOT NULL,
					EffectDate DATETIME NOT NULL,
					Cotisation MONEY NOT NULL,
					Fee MONEY NOT NULL,
					BenefInsur MONEY NOT NULL,
					SubscInsur MONEY NOT NULL,
					TaxOnInsur MONEY NOT NULL)

				CREATE TABLE #TT_CPA_CPAToDo (
					UnitID INTEGER,
					UnitQty MONEY,
					FeeSplitByUnit MONEY,
					FeeByUnit MONEY,
					AccountName VARCHAR(75),
					TransitNo VARCHAR(75),
					BankID INTEGER,
					CotisationFee MONEY,
					BenefInsur MONEY,
					SubscInsur MONEY,
					TaxOnInsur MONEY,
					TotCotFee MONEY,
					TotFeeBeforeDep MONEY,
					TotCotBeforeDep MONEY,
					MntSouscrit MONEY,
					HorairePrelevement BIT,
					PlanID int)

				CREATE TABLE #TT_Unit_Sans_Cotisation (
					UnitID INTEGER)

				INSERT INTO #TT_Unit_Sans_Cotisation
				SELECT DISTINCT
					CT.UnitID
				FROM Un_Cotisation CT
				JOIN Un_Oper O ON O.OperID = CT.OperID
				WHERE O.OperTypeID IN ('CHQ', 'CPA', 'PRD', 'RDI', 'TRA', 'TIN', 'COU') -- Ne doit pas tenir compte des TFR

				-- Créer les CPA selon la cédule habituelle, à l'exception du premier dépôt
				INSERT INTO #TT_CPA_CPAToDo
					SELECT
						U.UnitID,
						U.UnitQty,
						M.FeeSplitByUnit,
						M.FeeByUnit,
						CA.AccountName,
						CA.TransitNo,
						CA.BankID,
						CotisationFee = ROUND((U.UnitQty * ISNULL(M.PmtRate,0)),2),
						BenefInsur = ROUND(ISNULL(BI.BenefInsurRate,0),2),
						SubscInsur = 
							CASE U.WantSubscriberInsurance
								WHEN 0 THEN 0
							ELSE ROUND((U.UnitQty * ISNULL(M.SubscriberInsuranceRate,0)),2)
							END,
						TaxOnInsur = 
							CASE U.WantSubscriberInsurance
								WHEN 0 THEN ROUND((ISNULL(BI.BenefInsurRate,0) * ISNULL(St.StateTaxPct,0)) + 0.0049,2)
							ELSE ROUND((((ISNULL(BI.BenefInsurRate,0) + (U.UnitQty * ISNULL(M.SubscriberInsuranceRate,0))) * ISNULL(St.StateTaxPct,0)) + 0.0049),2)
							END,
						TotCotFee = ISNULL(SUM(T.Cotisation + T.Fee),0),
						TotFeeBeforeDep = 0,
						TotCotBeforeDep = 0,
						MntSouscrit = ROUND(U.UnitQty * ISNULL(M.PmtRate,0),2) * ISNULL(M.PmtQty,0),
						HorairePrelevement = 0,
						PlanID = c.PlanID
					FROM dbo.Un_Convention C
					JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
                    LEFT JOIN dbo.fntCONV_ObtenirStatutRINUnite(NULL, NULL, GETDATE()) RIN ON RIN.UnitID = U.UnitID
					JOIN Un_Modal M ON M.ModalID = U.ModalID
					JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
					JOIN dbo.Un_ConventionAccount CA ON CA.ConventionID = C.ConventionID
					JOIN Un_Plan P ON P.PlanID = C.PlanID
					LEFT JOIN Mo_State St ON St.StateID = S.StateID
					LEFT JOIN Un_BenefInsur BI ON BI.BenefInsurID = U.BenefInsurID
					LEFT JOIN Un_Cotisation T ON T.UnitID = U.UnitID
					LEFT JOIN #MaxConvDate VM ON VM.ConventionID = C.ConventionID AND (VM.MaxConvDepositDate < @AutomaticDepositDate)
					JOIN #TT_Unit_Sans_Cotisation USCT ON USCT.UnitID = U.UnitID -- Le premier dépôt est fait
					WHERE (ISNULL(U.TerminatedDate,0) <= 0)
						--AND (ISNULL(U.IntReimbDate,0) <= 0)
                        AND ISNULL(RIN.iStatut_RIN, 0) NOT IN (2, 3) -- Exclure les groupes d'unités avec un RIN partiel ou complet
                        AND (U.ActivationConnectID > 0)
						AND C.ConventionID NOT IN (
							SELECT ConventionID
							FROM #TT_CPA_Breaking) -- Pas d'arrêt de paiement de convention
						AND U.UnitID NOT IN (
							SELECT UnitID
							FROM #TT_CPA_HoldPayment) -- Pas d'arrêt de paiement de groupe d'unités
						AND U.UnitID NOT IN (
							SELECT UnitID
							FROM #TT_CPA_AutomaticDeposit) -- Pas d'horaire de prélèvement automatique
						AND ((ISNULL(VM.ConventionID, 0) = 0) OR (ROUND((U.UnitQty * ISNULL(M.PmtRate,0)),2) <= 0))
						AND (DAY(C.FirstPmtDate) = DAY(@AutomaticDepositDate))
						--AND U.dtFirstDeposit IS NOT NULL -- Le premier dépôt est fait
                        AND U.InForceDate <= @AutomaticDepositDate -- La date de début des opérations financière est avant ou égale à la date du traitement
						AND (C.PmtTypeID = 'AUT')
						AND ((MONTH(@AutomaticDepositDate) - MONTH(U.InForceDate)) % (12/M.PmtByYearID) = 0)
						--AND ((ISNULL(U.PETransactionId, 0) <> 0 AND U.dtFirstDeposit IS NULL)  -- Valide si provient de la propo et qu'aucun dépôt n'a été fait, ou que la date du CPA a créer est différente de la date du premier dépôt.
						--		OR (MONTH(@AutomaticDepositDate) <> MONTH(U.InForceDate) OR YEAR(@AutomaticDepositDate) <> YEAR(U.InForceDate)))
						AND (MONTH(@AutomaticDepositDate) <> MONTH(U.InForceDate) OR YEAR(@AutomaticDepositDate) <> YEAR(U.InForceDate)) -- Pas la date du premier dépôt
						AND (U.PmtEndConnectID IS NULL) -- Pas d'arrêt de paiement forcé
						AND P.PlanTypeID <> 'IND' -- Pas une convention individuel
					GROUP BY
						U.UnitID,
						U.UnitQty,
						M.FeeSplitByUnit,
						M.FeeByUnit,
						CA.AccountName,
						CA.TransitNo,
						CA.BankID,
						U.WantSubscriberInsurance,
						M.PmtQty,
						U.UnitQty,
						M.PmtRate,
						M.PmtByYearID,
						BI.BenefInsurRate,
						St.StateTaxPct,
						M.SubscriberInsuranceRate,
						C.PlanID
					HAVING ISNULL(SUM(T.Cotisation + T.Fee),0) < ROUND(U.UnitQty * ISNULL(M.PmtRate,0),2) * ISNULL(M.PmtQty,0)
                    
				-- Créer le premier dépôt dès que possible, à partir de la date du début des opérations financières
				INSERT INTO #TT_CPA_CPAToDo
					SELECT
						U.UnitID,
						U.UnitQty,
						M.FeeSplitByUnit,
						M.FeeByUnit,
						CA.AccountName,
						CA.TransitNo,
						CA.BankID,
						CotisationFee = CASE WHEN M.PmtByYearID = 1 AND M.PmtQty = 1 -- Paiement unique
                                                    --AND C.PlanID = 12 -- Convention Reeeflex 2010
                                                    AND U.SubscribeAmountAjustment <> 0
                                        THEN ROUND((U.UnitQty * ISNULL(M.PmtRate,0)),2) + U.SubscribeAmountAjustment                                                
                                        ELSE ROUND((U.UnitQty * ISNULL(M.PmtRate,0)),2) 
                                        END,
						BenefInsur = ROUND(ISNULL(BI.BenefInsurRate,0),2),
						SubscInsur = 
							CASE U.WantSubscriberInsurance
								WHEN 0 THEN 0
							ELSE ROUND((U.UnitQty * ISNULL(M.SubscriberInsuranceRate,0)),2)
							END,
						TaxOnInsur = 
							CASE U.WantSubscriberInsurance
								WHEN 0 THEN ROUND((ISNULL(BI.BenefInsurRate,0) * ISNULL(St.StateTaxPct,0)) + 0.0049,2)
							ELSE ROUND((((ISNULL(BI.BenefInsurRate,0) + (U.UnitQty * ISNULL(M.SubscriberInsuranceRate,0))) * ISNULL(St.StateTaxPct,0)) + 0.0049),2)
							END,
						TotCotFee = ISNULL(SUM(T.Cotisation + T.Fee),0),
						TotFeeBeforeDep = 0,
						TotCotBeforeDep = 0,
						MntSouscrit =   CASE WHEN M.PmtByYearID = 1 AND M.PmtQty = 1 -- Paiement unique
                                                    --AND C.PlanID = 12 -- Convention Reeeflex 2010
                                                    AND U.SubscribeAmountAjustment <> 0
                                        THEN ROUND((U.UnitQty * ISNULL(M.PmtRate,0)),2) + U.SubscribeAmountAjustment                                                
                                        ELSE ROUND(U.UnitQty * ISNULL(M.PmtRate,0),2) * ISNULL(M.PmtQty,0)
                                        END,
						HorairePrelevement = 0,
						PlanID = C.PlanID 
					FROM dbo.Un_Convention C
					JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
                    LEFT JOIN dbo.fntCONV_ObtenirStatutRINUnite(NULL, NULL, GETDATE()) RIN ON RIN.UnitID = U.UnitID
					JOIN Un_Modal M ON M.ModalID = U.ModalID
					JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
					JOIN dbo.Un_ConventionAccount CA ON CA.ConventionID = C.ConventionID
					JOIN Un_Plan P ON P.PlanID = C.PlanID
					LEFT JOIN Mo_State St ON St.StateID = S.StateID
					LEFT JOIN Un_BenefInsur BI ON BI.BenefInsurID = U.BenefInsurID
					LEFT JOIN Un_Cotisation T ON T.UnitID = U.UnitID
					LEFT JOIN #MaxConvDate VM ON VM.ConventionID = C.ConventionID AND (VM.MaxConvDepositDate < @AutomaticDepositDate)
					LEFT JOIN #TT_CPA_CPAToDo CPA ON CPA.UnitID = U.UnitID
					LEFT JOIN #TT_Unit_Sans_Cotisation USCT ON USCT.UnitID = U.UnitID
					WHERE (ISNULL(U.TerminatedDate,0) <= 0)
						--AND (ISNULL(U.IntReimbDate,0) <= 0)
                        AND ISNULL(RIN.iStatut_RIN, 0) NOT IN (2, 3) -- Exclure les groupes d'unités avec un RIN partiel ou complet
						AND (U.ActivationConnectID > 0)
						AND C.ConventionID NOT IN (
							SELECT ConventionID
							FROM #TT_CPA_Breaking) -- Pas d'arrêt de paiement de convention
						AND U.UnitID NOT IN (
							SELECT UnitID
							FROM #TT_CPA_HoldPayment) -- Pas d'arrêt de paiement de groupe d'unités
						AND U.UnitID NOT IN (
							SELECT UnitID
							FROM #TT_CPA_AutomaticDeposit) -- Pas d'horaire de prélèvement automatique
						AND ((ISNULL(VM.ConventionID, 0) = 0) OR (ROUND((U.UnitQty * ISNULL(M.PmtRate,0)),2) <= 0))
						AND CPA.UnitID IS NULL -- Pas de CPA déjà en attente d'être créé
						--AND U.dtFirstDeposit IS NULL -- Le premier dépôt n'est pas encore fait
						AND USCT.UnitID IS NULL -- Le premier dépôt n'est pas encore fait
						AND U.InForceDate <= @AutomaticDepositDate -- La date de début des opérations financière est avant ou égale à la date du traitement
						AND (C.PmtTypeID = 'AUT')
						AND (U.PmtEndConnectID IS NULL) -- Pas d'arrêt de paiement forcé
						AND P.PlanTypeID <> 'IND' -- Pas une convention individuel
					GROUP BY
						U.UnitID,
						U.UnitQty,
						M.FeeSplitByUnit,
						M.FeeByUnit,
						CA.AccountName,
						CA.TransitNo,
						CA.BankID,
						U.WantSubscriberInsurance,
						M.PmtQty,
						U.UnitQty,
						M.PmtRate,
						M.PmtByYearID,
						BI.BenefInsurRate,
						St.StateTaxPct,
						M.SubscriberInsuranceRate,
                        U.SubscribeAmountAjustment,
						C.PlanID
					HAVING ISNULL(SUM(T.Cotisation + T.Fee),0) < ROUND(U.UnitQty * ISNULL(M.PmtRate,0),2) * ISNULL(M.PmtQty,0)

				IF @@ERROR <> 0
					SET @BankFileID = -13
			END

			IF @BankFileID > 0
			BEGIN
				-- Créer les CPA à partir de l'horaire de prélèvement
				INSERT INTO #TT_CPA_CPAToDo
					SELECT
						U.UnitID,
						U.UnitQty,
						M.FeeSplitByUnit,
						M.FeeByUnit,
						CA.AccountName,
						CA.TransitNo,
						CA.BankID,
						CotisationFee = ROUND(A.CotisationFee, 2),
						BenefInsur = ROUND(A.BenefInsur, 2),
						SubscInsur = ROUND(A.SubscInsur, 2),
						TaxOnInsur = ROUND((((A.BenefInsur + A.SubscInsur) * ISNULL(St.StateTaxPct,0)) + 0.0049),2),
						TotCotFee = ISNULL(T.Cotisation + T.Fee,0),
						TotFeeBeforeDep = 0,
						TotCotBeforeDep = 0,
						MntSouscrit = ROUND(U.UnitQty * ISNULL(M.PmtRate,0),2) * ISNULL(M.PmtQty,0),
						HorairePrelevement = 1,
						C.PlanID
					FROM dbo.Un_Unit U
                    LEFT JOIN dbo.fntCONV_ObtenirStatutRINUnite(NULL, NULL, GETDATE()) RIN ON RIN.UnitID = U.UnitID
					JOIN Un_AutomaticDeposit A ON A.UnitID = U.UnitID
					JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
					JOIN Un_Modal M ON M.ModalID = U.ModalID
					JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
					JOIN dbo.Un_ConventionAccount CA ON CA.ConventionID = C.ConventionID
					LEFT JOIN Mo_State St ON St.StateID = S.StateID
					LEFT JOIN (
						SELECT 
							UnitID,
							Fee = SUM(Fee),
							Cotisation = SUM(Cotisation)
						FROM Un_Cotisation
						GROUP BY UnitID
						) T ON T.UnitID = U.UnitID
					LEFT JOIN #MaxConvDate VM ON VM.ConventionID = C.ConventionID AND (VM.MaxConvDepositDate < @AutomaticDepositDate)
					WHERE (ISNULL(U.TerminatedDate,0) <= 0)
						--AND (ISNULL(U.IntReimbDate,0) <= 0)
                        AND ISNULL(RIN.iStatut_RIN, 0) NOT IN (2, 3) -- Exclure les groupes d'unités avec un RIN partiel ou complet
						AND (U.ActivationConnectID > 0)
						AND C.PmtTypeID = 'AUT'
						AND C.ConventionID NOT IN (
							SELECT ConventionID
							FROM #TT_CPA_Breaking) -- Pas d'arrêt de paiement de convention
						AND U.UnitID NOT IN (
							SELECT UnitID
							FROM #TT_CPA_HoldPayment) -- Pas d'arrêt de paiement de groupe d'unités
						AND ((@AutomaticDepositDate >= A.FirstAutomaticDepositDate) AND ((A.EndDate IS NULL) OR (A.EndDate <= 0) OR (@AutomaticDepositDate <= A.EndDate)))
						AND (
							 ((A.TimeUnit = 0) AND (A.FirstAutomaticDepositDate = @AutomaticDepositDate)) OR
							 ((A.TimeUnit = 1) AND (CAST(DATEDIFF(DAY, A.FirstAutomaticDepositDate, @AutomaticDepositDate) AS FLOAT) / A.TimeUnitLap) - FLOOR((DATEDIFF(DAY, A.FirstAutomaticDepositDate, @AutomaticDepositDate) / A.TimeUnitLap)) = 0) OR
							 ((A.TimeUnit = 2) AND (DATEPART(dw, A.FirstAutomaticDepositDate) = DATEPART(dw, @AutomaticDepositDate)) AND (CAST(DATEDIFF(WEEK, A.FirstAutomaticDepositDate, @AutomaticDepositDate) AS FLOAT) / A.TimeUnitLap) - FLOOR((DATEDIFF(WEEK, A.FirstAutomaticDepositDate, @AutomaticDepositDate) / A.TimeUnitLap)) = 0) OR
							 ((A.TimeUnit = 3) AND (DATEPART(dd, A.FirstAutomaticDepositDate) = DATEPART(dd, @AutomaticDepositDate)) AND (CAST(DATEDIFF(MONTH, A.FirstAutomaticDepositDate, @AutomaticDepositDate) AS FLOAT) / A.TimeUnitLap) - FLOOR((DATEDIFF(MONTH, A.FirstAutomaticDepositDate, @AutomaticDepositDate) / A.TimeUnitLap)) = 0) OR
							 ((A.TimeUnit = 4) AND (DATEPART(dd, A.FirstAutomaticDepositDate) = DATEPART(dd, @AutomaticDepositDate)) AND (DATEPART(mm, A.FirstAutomaticDepositDate) = DATEPART(mm, @AutomaticDepositDate)) AND (CAST(DATEDIFF(YEAR, A.FirstAutomaticDepositDate, @AutomaticDepositDate) AS FLOAT) / A.TimeUnitLap) - FLOOR((DATEDIFF(YEAR, A.FirstAutomaticDepositDate, @AutomaticDepositDate) / A.TimeUnitLap)) = 0)
							)
						AND ((ISNULL(VM.ConventionID, 0) = 0) OR (ROUND(A.CotisationFee, 2) <= 0))
						AND U.PmtEndConnectID IS NULL
						AND (ISNULL(T.Cotisation + T.Fee,0) < ROUND(U.UnitQty * ISNULL(M.PmtRate,0),2) * ISNULL(M.PmtQty,0))
					ORDER BY 
						CA.TransitNo, 
						CA.AccountName, 
						CA.BankID

				IF @@ERROR <> 0
					SET @BankFileID = -16
			END

			IF @BankFileID > 0
			BEGIN
				UPDATE #TT_CPA_CPAToDo
				SET
					TotFeeBeforeDep = Ct.Fee,
					TotCotBeforeDep = Ct.Cotisation
				FROM #TT_CPA_CPAToDo 
				JOIN (
					SELECT 
						CPA.UnitID,
						Fee = SUM(Ct.Fee),
						Cotisation = SUM(Ct.Cotisation)
					FROM (-- Pour empêcher le dédoublement si deux CPA pour un groupe d'unités
						SELECT DISTINCT 
							UnitID
						FROM #TT_CPA_CPAToDo
						) CPA
					JOIN Un_Cotisation Ct ON Ct.UnitID = CPA.UnitID
					WHERE Ct.EffectDate <= @AutomaticDepositDate
					GROUP BY CPA.UnitID
					) Ct ON Ct.UnitID = #TT_CPA_CPAToDo.UnitID

				IF @@ERROR <> 0
					SET @BankFileID = -28
			END

			IF @BankFileID > 0
			BEGIN
				DECLARE UnCPAToDo CURSOR FOR
					SELECT 
						CPA.UnitID,
						AccountName,
						TransitNo,
						BankID,
						Fee = -- Calcul les frais selon la répartition frais vs épargnes
							CASE WHEN HorairePrelevement = 1 AND PlanID = 4 THEN
								dbo.fnGENE_ObtenirPlusPetiteValeurMonetaire(dbo.fnGENE_ObtenirPlusPetiteValeurMonetaire(CotisationFee * 0.4, 200), 200 - FRAIS.Frais)
							ELSE 
								CASE
									WHEN MntSouscrit - TotCotFee < CotisationFee THEN
										dbo.FN_UN_FeeOfNewDeposit(
											CPA.UnitID,
											(MntSouscrit-TotCotFee),
											@AutomaticDepositDate,
											UnitQty,
											FeeSplitByUnit,
											FeeByUnit,
											TotFeeBeforeDep,
											TotCotBeforeDep)
								ELSE
									dbo.FN_UN_FeeOfNewDeposit(
										CPA.UnitID,
										CotisationFee,
										@AutomaticDepositDate,
										UnitQty,
										FeeSplitByUnit,
										FeeByUnit,
										TotFeeBeforeDep,
										TotCotBeforeDep)
								END
							END,
						Cotisation = -- Calcul les épargnes selon la répartition frais vs épargnes
							CASE WHEN HorairePrelevement = 1 AND PlanID = 4 THEN
								CPA.CotisationFee - dbo.fnGENE_ObtenirPlusPetiteValeurMonetaire(dbo.fnGENE_ObtenirPlusPetiteValeurMonetaire(CotisationFee * 0.4, 200), 200 - FRAIS.Frais)
							ELSE 
								CASE
									WHEN MntSouscrit - TotCotFee < CotisationFee THEN
										(MntSouscrit - TotCotFee) - 
										dbo.FN_UN_FeeOfNewDeposit(
											CPA.UnitID,
											(MntSouscrit-TotCotFee),
											@AutomaticDepositDate,
											UnitQty,
											FeeSplitByUnit,
											FeeByUnit,
											TotFeeBeforeDep,
											TotCotBeforeDep)
								ELSE
									CotisationFee - 
									dbo.FN_UN_FeeOfNewDeposit(
										CPA.UnitID,
										CotisationFee,
										@AutomaticDepositDate,
										UnitQty,
										FeeSplitByUnit,
										FeeByUnit,
										TotFeeBeforeDep,
										TotCotBeforeDep)
								END
							END,
						BenefInsur,
						SubscInsur,
						TaxOnInsur,
						CotisationFee,
						TotCotFee,
						MntSouscrit
					FROM #TT_CPA_CPAToDo CPA
					LEFT JOIN dbo.fntCONV_ObtenirFraisIndividuelEnDate(@AutomaticDepositDate, NULL) FRAIS ON FRAIS.UnitID = CPA.UnitID
					ORDER BY 
						TransitNo, 
						AccountName, 
						BankID, -- Pour qu'ils soient fusionnés
						UnitID

				OPEN UnCPAToDo

				FETCH NEXT FROM UnCPAToDo
				INTO 	
					@UnitID,
					@AccountName,
					@TransitNo,
					@BankID,
					@Fee,
					@Cotisation,
					@BenefInsur,
					@SubscInsur,
					@TaxOnInsur,
					@CotisationFee,
					@TotCotFee,
					@MntSouscrit

				SET @OldUnitID = 0

				WHILE (@@FETCH_STATUS = 0) AND
						(@BankFileID > 0)
				BEGIN
					SET @OldAccountName = @AccountName
					SET @OldTransitNo = @TransitNo
					SET @OldBankID = @BankID

					INSERT INTO Un_Oper (
						ConnectID,
						OperTypeID,
						OperDate)
					VALUES (
						@ConnectID,
						'CPA',
						@AutomaticDepositDate)

					IF @@ERROR <> 0
						SET @BankFileID = -20
					ELSE
						SET @OperID = SCOPE_IDENTITY()

					WHILE @OldAccountName = @AccountName AND
							@OldTransitNo = @TransitNo AND
							@OldBankID = @BankID AND
							@@FETCH_STATUS = 0 AND
							(@BankFileID > 0)
					BEGIN
						-- Recalcul la répartition frais vs épargne si plus de deux CPA sur le même groupe d'unités
						IF @OldUnitID = @UnitID
						BEGIN
							SELECT 
								@Fee = -- Calcul les frais selon la répartition frais vs épargnes
									CASE
										WHEN @MntSouscrit - @TotCotFee < @CotisationFee THEN
											dbo.FN_UN_FeeOfNewDeposit(
												@UnitID,
												(@MntSouscrit-@TotCotFee),
												@AutomaticDepositDate,
												U.UnitQty,
												M.FeeSplitByUnit,
												M.FeeByUnit,
												ISNULL(Ct.Fee,0)+ISNULL(TCt.Fee,0),
												ISNULL(Ct.Cotisation,0)+ISNULL(TCt.Cotisation,0))
									ELSE
										dbo.FN_UN_FeeOfNewDeposit(
											@UnitID,
											@CotisationFee,
											@AutomaticDepositDate,
											U.UnitQty,
											M.FeeSplitByUnit,
											M.FeeByUnit,
											ISNULL(Ct.Fee,0)+ISNULL(TCt.Fee,0),
											ISNULL(Ct.Cotisation,0)+ISNULL(TCt.Cotisation,0))
									END
							FROM dbo.Un_Unit U
							JOIN Un_Modal M ON M.ModalID = U.ModalID
							LEFT JOIN (
								SELECT 
									UnitID,
									Fee = SUM(Fee),
									Cotisation = SUM(Cotisation)
								FROM Un_Cotisation
								WHERE UnitID = @UnitID
								GROUP BY UnitID
								) Ct ON Ct.UnitID = U.UnitID
							LEFT JOIN (
								SELECT 
									UnitID,
									Fee = SUM(Fee),
									Cotisation = SUM(Cotisation)
								FROM #TT_CPA_TmpInsCotisation
								WHERE UnitID = @UnitID
								GROUP BY UnitID
								) TCt ON TCt.UnitID = U.UnitID
							WHERE U.UnitID = @UnitID

							SET @Cotisation = @CotisationFee - @Fee
						END

						IF ((@MntSouscrit - @TotCotFee) < @CotisationFee) AND
							((@MntSouscrit - @TotCotFee) < @LastDepositMaxInInterest)
						BEGIN
							INSERT INTO Un_Oper (
								ConnectID,
								OperTypeID,
								OperDate)
							VALUES (
								@ConnectID,
								'AJU',
								@AutomaticDepositDate)

							SET @NewOperID = SCOPE_IDENTITY()

							IF @@ERROR <> 0
								SET @BankFileID = -21

							IF @BankFileID > 0
							BEGIN
								INSERT INTO #TT_CPA_TmpInsCotisation (
									UnitID,
									OperID,
									EffectDate,
									Cotisation,
									Fee,
									BenefInsur,
									SubscInsur,
									TaxOnInsur)
								VALUES (
									@UnitID,
									@NewOperID,
									@AutomaticDepositDate,
									@Cotisation,
									@Fee,
									0,
									0,
									0)

								IF @@ERROR <> 0
									SET @BankFileID = -22
							END

							IF @BankFileID > 0
							BEGIN
								SELECT
									@ConventionID = ConventionID
								FROM dbo.Un_Unit
								WHERE UnitID = @UnitID

								INSERT INTO dbo.Un_ConventionOper (
									OperID,
									ConventionID,
									ConventionOperTypeID,
									ConventionOperAmount)
								VALUES (
									@NewOperID,
									@ConventionID,
									'INC',
									((@Cotisation + @Fee)*-1))

								IF @@ERROR <> 0
									SET @BankFileID = -23
							END
						END
						ELSE
						BEGIN
							INSERT INTO #TT_CPA_TmpInsCotisation (
								UnitID,
								OperID,
								EffectDate,
								Cotisation,
								Fee,
								BenefInsur,
								SubscInsur,
								TaxOnInsur)
							VALUES (
								@UnitID,
								@OperID,
								@AutomaticDepositDate,
								@Cotisation,
								@Fee,
								@BenefInsur,
								@SubscInsur,
								@TaxOnInsur)

							IF @@ERROR <> 0
								SET @BankFileID = -24
						END

						SET @OldUnitID = @UnitID

						FETCH NEXT FROM UnCPAToDo
						INTO 	
							@UnitID,
							@AccountName,
							@TransitNo,
							@BankID,
							@Fee,
							@Cotisation,
							@BenefInsur,
							@SubscInsur,
							@TaxOnInsur,
							@CotisationFee,
							@TotCotFee,
							@MntSouscrit
					END
				END

				CLOSE UnCPAToDo
				DEALLOCATE UnCPAToDo
			END

			IF @BankFileID > 0
			BEGIN
				-- Insère dans la vrai table Un_Cotisation le contenu de la table temporaire.
				INSERT INTO Un_Cotisation (
					OperID,
					UnitID,
					EffectDate,
					Cotisation,
					Fee,
					BenefInsur,
					SubscInsur,
					TaxOnInsur)
					SELECT 
						OperID,
						UnitID,
						EffectDate,
						Cotisation,
						Fee,
						BenefInsur,
						SubscInsur,
						TaxOnInsur
					FROM #TT_CPA_TmpInsCotisation

				IF @@ERROR <> 0 
					SET @BankFileID = -31
			END

			IF @BankFileID > 0
			BEGIN
				DROP TABLE #TT_CPA_CPAToDo
				DROP TABLE #TT_CPA_Breaking
				DROP TABLE #TT_CPA_HoldPayment
				DROP TABLE #TT_CPA_AutomaticDeposit
				DROP TABLE #TT_CPA_TmpInsCotisation
				DROP TABLE #TT_Unit_Sans_Cotisation

				IF @@ERROR <> 0 
					SET @BankFileID = -32
			END
			-- --------------------------------------------
			-- Fin de la génération des CPA automatique	
			-- --------------------------------------------

			SET @AutomaticDepositDate = @AutomaticDepositDate + 1
		END
	END

	IF @BankFileID > 0
	BEGIN
		-- Insère l'historique du compte de banque des CPA
		INSERT INTO Un_OperAccountInfo (
			OperID,
			BankID,
			AccountName,
			TransitNo)
			SELECT DISTINCT
				O.OperID,
				CA.BankID,
				CA.AccountName,
				CA.TransitNo
			FROM Un_Oper O
			JOIN Un_Cotisation Ct ON Ct.OperID = O.OperID
			JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			JOIN dbo.Un_ConventionAccount CA ON CA.ConventionID = U.ConventionID
			LEFT JOIN Un_OperBankFile OBF ON OBF.OperID = O.OperID
			LEFT JOIN Un_OperCancelation OC ON OC.OperID = O.OperID OR OC.OperSourceID = O.OperID
			LEFT JOIN Un_OperAccountInfo OCA ON OCA.OperID = O.OperID
			WHERE O.OperDate BETWEEN @BeginDate AND @EndDate
				AND O.OperTypeID = 'CPA'
				AND OBF.OperID IS NULL
				AND OCA.OperID IS NULL
				AND OC.OperID IS NULL

		IF @@ERROR <> 0 
			SET @BankFileID = -25
	END

	IF @BankFileID > 0
	BEGIN
		-- Insère le fichier
		SELECT
			@BankFileID = (ISNULL(MAX(BankFileID),0) + 1)
		FROM Un_BankFile

		INSERT INTO Un_BankFile (
			BankFileID,
			BankFileStartDate,
			BankFileEndDate)
		VALUES (
			@BankFileID,
			@BeginDate,
			@EndDate)

		IF @@ERROR <> 0 
			SET @BankFileID = -2
	END

	IF @BankFileID > 0
	BEGIN
		-- Insère les liens entre le fichier et les opérations de type CPA
		INSERT INTO Un_OperBankFile (
			BankFileID,
			OperID)
			SELECT DISTINCT
				@BankFileID AS BankFileID,
				O.OperID
			FROM Un_Oper O
			JOIN Un_Cotisation Ct ON Ct.OperID = O.OperID
			LEFT JOIN Un_OperBankFile OBF ON OBF.OperID = O.OperID
			LEFT JOIN Un_OperCancelation OC ON OC.OperID = O.OperID OR OC.OperSourceID = O.OperID
			JOIN Un_OperAccountInfo OCA ON OCA.OperID = O.OperID
			WHERE O.OperDate BETWEEN @BeginDate AND @EndDate
				AND O.OperTypeID = 'CPA'
				AND OBF.OperID IS NULL
				AND OC.OperID IS NULL

		IF @@ERROR <> 0 
			SET @BankFileID = -26
	END

	IF @BankFileID > 0
	BEGIN
		CREATE TABLE #tConvTrans11_TTCPA (
			ConventionID INTEGER PRIMARY KEY)

		INSERT INTO #tConvTrans11_TTCPA
			SELECT 
				U.ConventionID				
			FROM Un_Cotisation Ct
			JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			JOIN Un_OperBankFile O ON O.OperID = Ct.OperID
			WHERE O.BankFileID = @BankFileID
			GROUP BY U.ConventionID

		CREATE TABLE #tConvEff11_TTCPA (
			ConventionID INTEGER PRIMARY KEY,
			EffectDate DATETIME NOT NULL )

		INSERT INTO #tConvEff11_TTCPA
			SELECT  
				C.ConventionID,
				EffectDate = dbo.FN_CRQ_DateNoTime(C.dtRegStartDate)
			FROM #tConvTrans11_TTCPA I
			JOIN dbo.Un_Convention C ON I.ConventionID = C.ConventionID			
			WHERE C.dtRegStartDate IS NOT NULL			

		DROP TABLE #tConvTrans11_TTCPA

		-- Insère les enregistrements 400 sur l'opération
		INSERT INTO Un_CESP400 (
				iCESPSendFileID,
				OperID,
				CotisationID,
				ConventionID,
				iCESP800ID,
				iReversedCESP400ID,
				tiCESP400TypeID,
				tiCESP400WithdrawReasonID,
				vcTransID,
				dtTransaction,
				iPlanGovRegNumber,
				ConventionNo,
				vcSubscriberSINorEN,
				vcBeneficiarySIN,
				fCotisation,
				bCESPDemand,
				dtStudyStart,
				tiStudyYearWeek,
				fCESG,
				fACESGPart,
				fEAPCESG,
				fEAP,
				fPSECotisation,
				iOtherPlanGovRegNumber,
				vcOtherConventionNo,
				tiProgramLength,
				cCollegeTypeID,
				vcCollegeCode,
				siProgramYear,
				vcPCGSINorEN,
				vcPCGFirstName,
				vcPCGLastName,
				tiPCGType,
				fCLB,
				fEAPCLB,
				fPG,
				fEAPPG,
				vcPGProv )
			SELECT
				NULL,
				Ct.OperID,
				Ct.CotisationID,
				C.ConventionID,
				NULL,
				NULL,
				11,
				NULL,
				'FIN',
				Ct.EffectDate,
				P.PlanGovernmentRegNo,
				C.ConventionNo,
				HS.SocialNumber,
				HB.SocialNumber,
				Ct.Cotisation+Ct.Fee,
				C.bCESGRequested,
				NULL,
				NULL,
				0,
				0,
				0,
				0,
				0,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				CASE 
					WHEN C.bACESGRequested = 0 THEN NULL
				ELSE B.vcPCGSINOrEN
				END,
				CASE 
					WHEN C.bACESGRequested = 0 THEN NULL
				ELSE B.vcPCGFirstName
				END,
				CASE 
					WHEN C.bACESGRequested = 0 THEN NULL
				ELSE B.vcPCGLastName
				END,
				B.tiPCGType,
				0,
				0,
				0,
				0,
				NULL
			FROM Un_OperBankFile OB
			JOIN Un_Cotisation Ct ON OB.OperID = Ct.OperID
			JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
			JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
			JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
			JOIN #tConvEff11_TTCPA FCB ON FCB.ConventionID = C.ConventionID AND FCB.EffectDate <= Ct.EffectDate
			WHERE OB.BankFileID = @BankFileID
				AND ISNULL(HB.SocialNumber,'') <> ''
				AND ISNULL(HS.SocialNumber,'') <> ''
				AND Ct.CotisationID NOT IN (
						-- Cotisation qui ont un enregistrement 400 expédié qui est valide.
						SELECT Ct.CotisationID
						FROM Un_OperBankFile OB
						JOIN Un_Cotisation Ct ON OB.OperID = Ct.OperID
						JOIN Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID
						LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
						WHERE OB.BankFileID = @BankFileID
							AND G4.iCESP800ID IS NULL -- Pas revenu en erreur
							AND G4.iReversedCESP400ID IS NULL -- Pas une annulation
							AND R4.iCESP400ID IS NULL -- Pas annulé
						)

		DROP TABLE #tConvEff11_TTCPA

		-- Inscrit le vcTransID avec le ID FIN + <iCESP400ID>.
		UPDATE Un_CESP400
		SET vcTransID = 'FIN'+CAST(iCESP400ID AS VARCHAR(12))
		WHERE vcTransID = 'FIN' 

		IF @@ERROR <> 0 
			SET @BankFileID = -33
	END

	IF @BankFileID > 0
	BEGIN
		-- Remet à 0 le nb de jour à ajouter de la configuration pour cette journée de la semaine.
		UPDATE Un_AutomaticDepositTreatmentCfg
		SET
			DaysAddForNextTreatment = 0
		WHERE TreatmentDay = DATEPART(dw, GETDATE())

		IF @@ERROR <> 0 
			SET @BankFileID = -27
	END

	IF @BankFileID > 0
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
		--------------------

	--ALTER TABLE Un_Cotisation
	--	ENABLE TRIGGER TUn_Cotisation_State

	Delete #DisableTrigger where vcTriggerName = 'TUn_Cotisation_State'

	RETURN @BankFileID
END