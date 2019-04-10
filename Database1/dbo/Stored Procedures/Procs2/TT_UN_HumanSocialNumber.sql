/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	TT_UN_HumanSocialNumber
Description         :	Fait la gestion de la création des historiques de NAS.
Valeurs de retours  :	@ReturnValue :
									>0 = Pas d’erreur
									<=0 = Erreur
									-1 : Message d’erreur : « Un des bénéficiaires à son adresse d’identifiée perdue. »
									<-1 : Erreur SQL

Note                :							
									2003-10-14	Bruno Lapointe			Création #0768-01
									2003-10-21	Bruno Lapointe			Modifition #0768-07 : Gestion des comptes de 
																		garantie bloqués
									2005-04-15	Bruno Lapointe			Correction : on ne doit pas créé de RCB et FCB 
																		pour des conventions entrée en vigueur avant le 
																		1 janvier 2003
					ADX0001818	BR	2006-02-06	Bruno Lapointe			Document : Convention commandé avant que 
																		l'ajustement  la date de fin de régime ait été 
																		appliqué.
					ADX0000848	IA	2006-03-24	Bruno Lapointe			Adaptation des FCB pour PCEE 4.3 (Création 400)
					ADX0001235	IA	2007-02-14	Alain Quirion			Utilisation de IU_UN_HumanSocialNumber au lieu de SP_IU_UN_HumanSocialNumber, Utilisation de dtRegStartDate pour la date de début de régime
					ADX0001355	IA	2007-06-06	Alain Quirion			Mise à jour de dtRegEndDateAdjust en remplacement de RegEndDateAddyear
									2008-11-24	Josée Parent			Modification pour utiliser la fonction "fnCONV_ObtenirDateFinRegime"
									2010-04-16	Jean-François Gauthier	Ajout de validations lors de la saisie du NAS
									2010-04-19	Jean-François Gauthier	Point #12 - Ne pas calculer les CPA dans le FCB (enlever heure dans la date).
									2010-11-26	Pierre Paquet			Correction sur la création du FCB.
									2010-10-14	Frederick Thibault	Ajout du champ fACESGPart pour régler le problème SCEE+
									2011-05-16	Donald Huppé			À la création de la table #PropBefore, ajouter une clause where qui empèche d'insérer si les NAS du souscr ET du benéf ne sont pas présents
																					Donc, si on doit inscrire le NAS du souscr ET du benéf un à la suite de l'autre, les transaction dans le curseur seront créées seulement lorsque le dernier NAS sera saisi
									2014-11-11	Pierre-Luc Simard	Ne plus mettre à jour les case bCESG puisque géré par la procédure psCONV_EnregistrerPrevalidationPCEE avant l'appel de celle-ci
									2015-09-29	Steeve Picard			Effacer l'historique de NAS si c'est un bénéficiaire n'ayant pas de convention en REER ou en transitoire
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_HumanSocialNumber] 
(
	@ConnectID INTEGER, -- Identificateur de la connection de l'usager
	@HumanID INTEGER, -- Id unique de l'humain à qui appartient l'historique du NAS
	@SocialNumber VARCHAR(75)  -- Numéro d'assurance sociale (NAS)
)
AS	
BEGIN
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Start'
	DECLARE
		@iResult INTEGER,
		@Today DATETIME,
		@OldSocialNumber VARCHAR(75)

	SET @iResult = 0
	
	IF IsNull(@SocialNumber, '') <> ''
	BEGIN

		SET @OldSocialNumber = ''

		SELECT @OldSocialNumber = ISNULL(MAX(SN.SocialNumber),'')
		FROM Un_HumanSocialNumber SN
		JOIN (
			SELECT 
				EffectDate = MAX(EffectDate)
			FROM Un_HumanSocialNumber 
			WHERE HumanID = @HumanID
			) V ON V.EffectDate = SN.EffectDate
		WHERE SN.HumanID = @HumanID

		IF IsNull(@SocialNumber, '') <> @OldSocialNumber
		BEGIN
			SET @Today = dbo.FN_CRQ_DateNoTime(GETDATE())	-- 2010-04-19 : JFG : Élimination de la heure de la date

			EXECUTE @iResult = IU_UN_HumanSocialNumber @ConnectID, 0, @HumanID, @Today, @SocialNumber

			IF @iResult <> 0 
				SET @iResult = -10
			ELSE 
			BEGIN 
				-- Inscrit un ajustement de date de fin de régime s'il y a lieu sur les conventions qui on changé d'état 
				-- de transitoire à RÉÉÉ à cause du NAS inscrit.
				IF @OldSocialNumber = ''
				BEGIN	
					UPDATE dbo.Un_Convention 
					SET dtRegEndDateAdjust = (SELECT dbo.fnCONV_ObtenirDateFinRegime(Un_Convention.ConventionID,'T',@Today))
					FROM dbo.Un_Convention 
					JOIN (
						SELECT 
							U.ConventionID, 
							InForceDate = MIN(U.InForceDate)
						FROM dbo.Un_Unit U
						JOIN ( -- Va chercher les conventions qui ne sont plus en proposition suite à l'entré du NAS sur l'humain.
							SELECT DISTINCT
								C.ConventionID
							FROM dbo.Un_Convention C
							JOIN dbo.Mo_Human S ON S.HumanID = C.SubscriberID
							JOIN dbo.Mo_Human B ON B.HumanID = C.BeneficiaryID
							WHERE ISNULL(C.dtRegStartDate,'1950-01-01') >= '2003-01-01'		--date d'entrée en vigueur de la convention
									AND (C.SubscriberID = @HumanID
											OR C.BeneficiaryID = @HumanID)					
									AND (S.SocialNumber IS NOT NULL AND B.SocialNumber IS NOT NULL)
							GROUP BY C.ConventionID
				 			) P ON P.ConventionID = U.ConventionID
						GROUP BY U.ConventionID
						) V ON V.ConventionID = Un_Convention.ConventionID
					WHERE YEAR(@Today) - YEAR(V.InForceDate) > 0
						AND Un_Convention.dtRegEndDateAdjust IS NULL
    
					IF @@ERROR <> 0
						SET @iResult = -5
				END

				-- Gestion des comptes bloqués, ceci crée une opération transférant les cotisations et les frais 
				-- des comptes bloqués aux comptes du régime s'il y a lieu.
				IF (@OldSocialNumber = '' OR @OldSocialNumber = 'Absent' OR @OldSocialNumber = 'absent') AND @iResult > 0
				BEGIN 
					If dbo.FN_IsDebug() <> 0
						PRINT @OldSocialNumber

					SELECT DISTINCT
						C.ConventionID
					INTO #PropBefore
					FROM 
						dbo.Un_Convention C
						INNER JOIN dbo.Mo_Human S ON S.HumanID = C.SubscriberID
						INNER JOIN dbo.Mo_Human B ON B.HumanID = C.BeneficiaryID
					WHERE 
						ISNULL(C.dtRegStartDate,'1950-01-01') >= '2003-01-01'		--date d'entrée en vigueur de la convention
						AND 
						(	C.SubscriberID = @HumanID
							OR 
							C.BeneficiaryID = @HumanID )
						AND	-- 2010-04-16 : JFG : La convention ne doit pas avoir de RI 		
							NOT EXISTS(	SELECT 1 FROM dbo.Un_Unit ut WHERE ut.ConventionID = C.ConventionID AND ut.IntReimbDate IS NOT NULL)	
						AND (S.SocialNumber IS NOT NULL AND B.SocialNumber IS NOT NULL)	
					GROUP BY 
						C.ConventionID
					
					/*	
					-- 2010-04-16 : JFG :	Si la saisie du NAS est celle d'un bénéficiaire
					--						il faut décocher les cases SCEE, SCEE+, BEC
					--						de toutes les conventions ayant un RI
				
					IF EXISTS (	SELECT 1 
								FROM 
									dbo.Mo_Human h
									INNER JOIN dbo.Un_Beneficiary b
										ON h.HumanID = b.BeneficiaryID 
								WHERE
									h.SocialNumber = @SocialNumber )
						BEGIN
							UPDATE c
							SET	c.bCESGRequested	= 0
								,c.bACESGRequested	= 0
								,c.bCLBRequested	= 0
							FROM
								dbo.Un_Convention c
								INNER JOIN dbo.Un_Beneficiary b	ON c.BeneficiaryID = b.BeneficiaryID
								INNER JOIN dbo.Mo_Human h ON h.HumanID = b.BeneficiaryID
							WHERE
								h.SocialNumber = @SocialNumber
								AND	EXISTS(	SELECT 1 FROM dbo.Un_Unit ut WHERE ut.ConventionID = c.ConventionID AND ut.IntReimbDate IS NOT NULL)
							
						END
				
					-- 2010-04-16 : JFG :	Si la saisie du NAS est celle d'un souscripteur
					--						il faut décocher les cases SCEE, SCEE+, BEC
					--						de toutes les conventions ayant un RI
					IF EXISTS (	SELECT 1 
								FROM 
									dbo.Mo_Human h
									INNER JOIN dbo.Un_Subscriber s
										ON h.HumanID = s.SubscriberID 
								WHERE
									h.SocialNumber = @SocialNumber )
						BEGIN
							UPDATE c
							SET	c.bCESGRequested	= 0
								,c.bACESGRequested	= 0
								,c.bCLBRequested	= 0
							FROM
								dbo.Un_Convention c
								INNER JOIN dbo.Un_Subscriber b
									ON c.SubscriberID = b.SubscriberID
								INNER JOIN dbo.Mo_Human h
									ON h.HumanID = b.SubscriberID
							WHERE
								h.SocialNumber = @SocialNumber
								AND	EXISTS(	SELECT 1 FROM dbo.Un_Unit ut WHERE ut.ConventionID = c.ConventionID AND ut.IntReimbDate IS NOT NULL)
						END
						*/

					DECLARE 
						@OperID INTEGER,
						@UnitID INTEGER,
						@Cotisation MONEY,
						@Fee MONEY				

					DECLARE ToDo CURSOR FOR
						SELECT 
							U.UnitID,
							Cotisation = SUM(Ct.Cotisation),
							Fee = SUM(Ct.Fee)
						FROM #PropBefore P
						JOIN dbo.Un_Unit U ON U.ConventionID = P.ConventionID
						JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
						JOIN Un_Oper O ON O.OperID = Ct.OperID
						WHERE O.OperDate < @Today
						GROUP BY U.UnitID
						HAVING (SUM(Ct.Cotisation) <> 0)
							OR (SUM(Ct.Fee) <> 0)
    
					OPEN ToDo

					FETCH NEXT FROM ToDo
					INTO 	@UnitID,
							@Cotisation,
							@Fee

					WHILE @@FETCH_STATUS = 0 AND @iResult > 0
					BEGIN
						-----------------
						BEGIN TRANSACTION
						-----------------

						INSERT INTO Un_Oper (
							ConnectID,
							OperTypeID,
							OperDate)
						VALUES (
							@ConnectID,
							'RCB',
							@Today)
 
						IF @@ERROR = 0
							SET @OperID = SCOPE_IDENTITY()
						ELSE
							SET @iResult = -1
	
						IF @iResult > 0
						BEGIN
							INSERT INTO Un_Cotisation (
								OperID,
								UnitID,
								EffectDate,
								Cotisation,
								Fee,
								BenefInsur,
								SubscInsur,
								TaxOnInsur)
							VALUES (
								@OperID,
								@UnitID,
								@Today,
								-@Cotisation,
								-@Fee,
								0,
								0,
								0)

							IF @@ERROR <> 0
								SET @iResult = -2
						END
	
						IF @iResult > 0
						BEGIN
							INSERT INTO Un_Oper (
								ConnectID,
								OperTypeID,
								OperDate)
							VALUES (
								@ConnectID,
								'FCB',
								@Today)
	 
							IF @@ERROR = 0
								SET @OperID = SCOPE_IDENTITY()
							ELSE
								SET @iResult = -3
						END
	  
						IF @iResult > 0
						BEGIN
							INSERT INTO Un_Cotisation (
								OperID,
								UnitID,
								EffectDate,
								Cotisation,
								Fee,
								BenefInsur,
								SubscInsur,
								TaxOnInsur)
							VALUES (
								@OperID,
								@UnitID,
								@Today,
								@Cotisation,
								@Fee,
								0,
								0,
								0)
	
							IF @@ERROR <> 0
								SET @iResult = -4
						END
	
						-- Crée l'enregistrement 400 de demande de subvention au PCEE.
						IF @iResult > 0
						BEGIN
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
									CASE 
										WHEN C.bACESGRequested = 0 THEN NULL
									ELSE B.tiPCGType
									END,
									0,
									0,
									0,
									0,
									NULL
								FROM Un_Cotisation Ct
								JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
								JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
								JOIN Un_Plan P ON P.PlanID = C.PlanID
								JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
								JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
								JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
								WHERE 
									Ct.OperID = @OperID
			
							IF @@ERROR <> 0 
								SET @iResult = -14
						END
			
						IF @iResult > 0
						BEGIN
							-- Inscrit le vcTransID avec le ID FIN + <iCESP400ID>.
							UPDATE Un_CESP400
							SET vcTransID = 'FIN'+CAST(iCESP400ID AS VARCHAR(12))
							WHERE vcTransID = 'FIN' 
			
							IF @@ERROR <> 0
								SET @iResult = -15
						END					

						IF @iResult <= 0
							--------------------
							ROLLBACK TRANSACTION
							--------------------
						ELSE
							------------------
							COMMIT TRANSACTION
							------------------
	
						FETCH NEXT FROM ToDo
						INTO	@UnitID,
								@Cotisation,
								@Fee
					END

					CLOSE ToDo
					DEALLOCATE ToDo		

					DROP TABLE #PropBefore
				END
			END
		END 
	END 
	ELSE
	BEGIN
		DECLARE @Count int = 0
		;WITH CTE_Convention As (
			SELECT ConventionID
				FROM dbo.Un_Convention
				WHERE BeneficiaryID = @HumanID
		),
		CTE_State As (
			SELECT S.ConventionID, Max(S.StartDate) as LastStartDate
				FROM dbo.Un_ConventionConventionState S
					JOIN CTE_Convention C ON C.ConventionID = S.ConventionID
				GROUP BY S.ConventionID
		)
		SELECT @Count = Count(*)
			FROM dbo.Un_ConventionConventionState CS
				JOIN CTE_State S ON S.ConventionID = CS.ConventionID And S.LastStartDate = CS.StartDate
			WHERE CS.ConventionStateID <> 'PRP'

		IF @Count = 0
			DELETE FROM dbo.Un_HumanSocialNumber
				WHERE HumanID = @HumanID
	END

	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
	RETURN @iResult
END
