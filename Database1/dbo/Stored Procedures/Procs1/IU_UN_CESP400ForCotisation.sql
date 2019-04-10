/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_CESP400ForCotisation
Description         :	Procédure qui crée un enregistrement 400 pour une cotisation
Valeurs de retours  :	@ReturnValue :
									> 0 : Réussite
									<= 0 : Erreurs.
Note                :	ADX0001153	IA	2007-01-16	Alain Quirion		Création
								ADX			BR	2007-05-03	Alain Quirion			Modification : Création des enregistrement 400 de demandes de BEC 
								ADX0002426	BR	2007-05-23	Bruno Lapointe	Gestion de la table Un_CESP.
								ADX0002502	BR	2007-06-27	Bruno Lapointe	NAS absent mal géré pour les conventions entrées en vigueur avant le 1 janvier 2003
												2011-01-31	Frederick Thibault		Ajout du champ fACESGPart pour régler le problème SCEE+
												2016-04-13	Pierre-Luc Simard		Ne pas traiter les 421-3 sur les opérations de type FRM
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_CESP400ForCotisation] (
	@ConnectID INTEGER, -- ID Unique de connexion de l'usager
	@CotisationID INTEGER, -- ID de la cotisation a renvoyé
	@tiCESP400TypeID SMALLINT, -- Type d'enregistrement à créer
	@tiCESP400WithdrawReasonID TINYINT ) -- Raison du remboursement si s'en est un
AS
BEGIN
	DECLARE
		@iReturn INT,
		@ConventionID INT,
		@OperID INT

	SET @iReturn = 1

	-------------
	-- Type 11 --
	-------------
	IF @tiCESP400TypeID = 11
	BEGIN
		INSERT INTO Un_CESP400 (
				OperID,
				CotisationID,
				ConventionID,
				tiCESP400TypeID,
				vcTransID,
				dtTransaction,
				iPlanGovRegNumber,
				ConventionNo,
				vcSubscriberSINorEN,
				vcBeneficiarySIN,
				fCotisation,
				bCESPDemand,
				fCESG,
				fACESGPart,
				fEAPCESG,
				fEAP,
				fPSECotisation,
				vcPCGSINorEN,
				vcPCGFirstName,
				vcPCGLastName,
				tiPCGType,
				fCLB,
				fEAPCLB,
				fPG,
				fEAPPG )
			SELECT
				Ct.OperID,
				Ct.CotisationID,
				C.ConventionID,
				11,
				'FIN',
				Ct.EffectDate,
				P.PlanGovernmentRegNo,
				C.ConventionNo,
				ISNULL(HS.SocialNumber,''),
				HB.SocialNumber,
				Ct.Cotisation+Ct.Fee,
				C.bCESGRequested,
				0,
				0,
				0,
				0,
				0,
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
				0
			FROM Un_Cotisation Ct
			JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
			JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
			JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
			WHERE Ct.CotisationID = @CotisationID
				AND dbo.FN_CRQ_DateNoTime(ISNULL(dbo.FN_CRQ_DateNoTime(C.dtRegStartDate),Ct.EffectDate+1)) <= Ct.EffectDate -- Pas dans un compte bloqué
				AND ISNULL(HB.SocialNumber,'') <> ''
				AND Ct.CotisationID NOT IN (
						-- Cotisation qui ont un enregistrement 400 expédié qui est valide.
						SELECT Ct.CotisationID
						FROM Un_Cotisation Ct
						JOIN Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID
						LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
						WHERE Ct.CotisationID = @CotisationID
							AND G4.iCESP800ID IS NULL -- Pas revenu en erreur
							AND G4.iReversedCESP400ID IS NULL -- Pas une annulation
							AND R4.iCESP400ID IS NULL -- Pas annulé
						)
	END	
	-------------
	-- Type 13 -- On ne gère pas le PAE car il n'a jamais de cotisation.
	-------------
	-------------
	-- Type 14 --
	-------------
	ELSE IF @tiCESP400TypeID = 14
	BEGIN
		INSERT INTO Un_CESP400 (
				OperID,
				CotisationID,
				ConventionID,
				tiCESP400TypeID,
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
				tiProgramLength,
				cCollegeTypeID,
				vcCollegeCode,
				siProgramYear,
				fCLB,
				fEAPCLB,
				fPG,
				fEAPPG,
				fCotisationGranted )
			SELECT
				Ct.OperID,
				Ct.CotisationID,
				C.ConventionID,
				14,
				'FIN',
				Ct.EffectDate,
				P.PlanGovernmentRegNo,
				C.ConventionNo,
				ISNULL(HS.SocialNumber,''),
				HB.SocialNumber,
				0,
				C.bCESGRequested,
				IR.StudyStart,		--dtStudyStart
				CASE CL.CollegeTypeID	--tiStudyYearWeek
					WHEN '01' THEN 30
				ELSE 34 
				END,			
				0,
				0,
				0,
				0,
				Ct.Cotisation+Ct.Fee,
				IR.ProgramLength,	--tiProgramLength
				CL.CollegeTypeID,		--cCollegeTypeID
				CL.CollegeCode,		--vcCollegeCode
				IR.ProgramYear,		--siProgramYear
				0,
				0,
				0,
				0,
				Ct.Cotisation+Ct.Fee
			FROM Un_Cotisation Ct
			JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
			JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
			JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
			JOIN Un_IntReimbOper IRO ON IRO.OperID = Ct.OperID
			JOIN Un_IntReimb IR ON IR.IntReimbID = IRO.IntReimbID
			JOIN Un_College CL ON CL.CollegeID = IR.CollegeID
			WHERE Ct.CotisationID = @CotisationID
				AND dbo.FN_CRQ_DateNoTime(ISNULL(C.dtRegStartDate,Ct.EffectDate+1)) <= Ct.EffectDate -- Pas dans un compte bloqué
				AND ISNULL(HB.SocialNumber,'') <> ''
				AND Ct.CotisationID NOT IN (
						-- Cotisation qui ont un enregistrement 400 expédié qui est valide.
						SELECT Ct.CotisationID
						FROM Un_Cotisation Ct
						JOIN Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID
						LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
						WHERE Ct.CotisationID = @CotisationID
							AND G4.iCESP800ID IS NULL -- Pas revenu en erreur
							AND G4.iReversedCESP400ID IS NULL -- Pas une annulation
							AND R4.iCESP400ID IS NULL -- Pas annulé
						)
	END
	-------------
	-- Type 19 --
	-------------
	ELSE IF @tiCESP400TypeID = 19
	BEGIN
		SELECT 
			@OperID = Ct.OperID
		FROM Un_Cotisation Ct
		WHERE Ct.CotisationID = @CotisationID

		-- Insère l'enregistrement 400 du TIN
		INSERT INTO Un_CESP400 (
				OperID,
				CotisationID,
				ConventionID,
				tiCESP400TypeID,
				vcTransID,
				dtTransaction,
				iPlanGovRegNumber,
				ConventionNo,
				vcSubscriberSINorEN,
				vcBeneficiarySIN,
				fCotisation,
				bCESPDemand,
				fCESG,
				fACESGPart,
				fEAPCESG,
				fEAP,
				fPSECotisation,
				iOtherPlanGovRegNumber,
				vcOtherConventionNo,
				fCLB,
				fEAPCLB,
				fPG,
				fEAPPG )
			SELECT 
				Ct.OperID,
				Ct.CotisationID,
				C.ConventionID,
				19,
				'FIN',
				Ct.EffectDate,
				P.PlanGovernmentRegNo,
				C.ConventionNo,
				ISNULL(HS.SocialNumber,''),
				HB.SocialNumber,
				Ct.Cotisation+Ct.Fee,
				C.bCESGRequested,
				CE.fCESG + CE.fACESG,
				CE.fACESG,
				0,
				0,
				0,
				EP.ExternalPlanGovernmentRegNo,
				T.vcOtherConventionNo,
				CE.fCLB,
				0,
				0,
				0
			FROM Un_TIN T
			JOIN (
				SELECT
					OperID, 
					CotisationID = MIN(Ct.CotisationID),
					EffectDate = MAX(Ct.EffectDate),
					Cotisation = SUM(Ct.Cotisation),
					Fee = SUM(Ct.Fee)
				FROM Un_Cotisation Ct
				WHERE Ct.OperID = @OperID
				GROUP BY OperID
				) Ct ON T.OperID = Ct.OperID
			JOIN Un_ExternalPlan EP ON EP.ExternalPlanID = T.ExternalPlanID
			JOIN Un_CESP CE ON CE.OperID = T.OperID
			JOIN dbo.Un_Convention C ON C.ConventionID = CE.ConventionID
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
			JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
			JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
			WHERE T.OperID = @OperID
				AND T.OperID NOT IN (
						-- Opération qui ont un enregistrement 400 expédié qui est valide.
						SELECT C4.OperID
						FROM Un_CESP400 C4
						LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = C4.iCESP400ID
						LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID AND C9.tiCESP900OriginID = 3 -- Transaction 900 dont l'origine n'est pas transfert non-réglé
						WHERE C4.CotisationID = @CotisationID
							AND C4.iCESP800ID IS NULL 		-- Pas revenu en erreur
							AND C9.iCESP900ID IS NULL
							AND C4.iReversedCESP400ID IS NULL 	-- Pas une annulation
							AND R4.iCESP400ID IS NULL 		-- Pas annulé
						)
		
	END
	---------------
	-- Type 21-1 --
	---------------
	ELSE IF @tiCESP400TypeID = 21 
			AND @tiCESP400WithdrawReasonID = 1
	BEGIN
		SELECT @ConventionID = U.ConventionID
		FROM Un_Cotisation Ct
		JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
		WHERE Ct.CotisationID = @CotisationID

		INSERT INTO Un_CESP400 (
				OperID,
				CotisationID,
				ConventionID,
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
				fCESG,
				fACESGPart,
				fEAPCESG,
				fEAP,
				fPSECotisation,
				fCLB,
				fEAPCLB,
				fPG,
				fEAPPG,
				fCotisationGranted )
			SELECT
				Ct.OperID,
				Ct.CotisationID,
				C.ConventionID,
				21,
				1,
				'FIN',
				Ct.EffectDate,
				P.PlanGovernmentRegNo,
				C.ConventionNo,
				ISNULL(HS.SocialNumber,''),
				HB.SocialNumber,
				0,
				C.bCESGRequested,

				-- SCEE
				CASE
					-- Rembourse rien 0.00 si le solde de subvention et négatif ou à 0.00
					WHEN ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0) <= 0 
						THEN 0
					-- Rembourse tout s'il n'y a pas de cotisations subventionnées
					WHEN ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0) = 0 
						THEN -(ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0))
					-- Rembourse tout si on retire toutes les cotisations subventionnées
					WHEN ABS(Ct.Cotisation + Ct.Fee) > ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0) 
						THEN -(ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0))
					-- Rembourse tout si le proprata selon la formule A/B*C du règlement sur l’épargne-études est plus élevé que le total de la SCEE
					WHEN ROUND((ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0)) / (ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0)) * ABS(Ct.Cotisation + Ct.Fee), 2) > ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0) 
						THEN -(ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0))
					-- Rembourse au proprata selon la formule A/B*C du règlement sur l’épargne-études si on retire seulement une partie des cotisations subventionnées
					ELSE -(ROUND((ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0)) / (ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0)) * ABS(Ct.Cotisation+Ct.Fee), 2))
				END,

				-- SCEE+
				CASE
					-- Rembourse rien 0.00 si le solde de subvention et négatif ou à 0.00
					WHEN ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0) <= 0 
						THEN 0
					-- Rembourse tout s'il n'y a pas de cotisations subventionnées
					WHEN ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0) = 0 
						THEN -(ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0))
					-- Rembourse tout si on retire toutes les cotisations subventionnées
					WHEN ABS(Ct.Cotisation + Ct.Fee) > ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0) 
						THEN -(ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0))
					-- Rembourse tout si le proprata selon la formule A/B*C du règlement sur l’épargne-études est plus élevé que le total de la SCEE
					WHEN ROUND((ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0)) / (ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0)) * ABS(Ct.Cotisation + Ct.Fee), 2) > ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0) 
						THEN -(ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0))
					-- Rembourse au proprata selon la formule A/B*C du règlement sur l’épargne-études si on retire seulement une partie des cotisations subventionnées
					ELSE 
						-(ROUND((ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0)) / (ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0)) * ABS(Ct.Cotisation + Ct.Fee), 2))
				END,

				0,
				0,
				0,
				0,
				0,
				0,
				0,
				CASE
					-- Le montant de cotisations subventionnées ne varie pas car on ne rembourse pas de subvention car il n'y en a pas.
					WHEN ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0) <= 0 
						THEN 0
					-- Le montant de cotisations subventionnées de la convention est déjà 0.00
					WHEN ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0) = 0 
						THEN 0
					-- On retire toutes les cotisations subventionnées
					WHEN ABS(Ct.Cotisation + Ct.Fee) > ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0) 
						THEN -(ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0))
					-- On retire toutes les cotisations subventionnées
					WHEN ROUND((ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0)) / (ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0)) * ABS(Ct.Cotisation + Ct.Fee), 2) > ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0) 
						THEN -(ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0))
					-- On rembourse une partie des cotisations subventionnées
					ELSE 
						Ct.Cotisation + Ct.Fee
				END
			FROM Un_Cotisation Ct
			JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
			JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
			JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
			LEFT JOIN ( -- Solde SCEE et SCEE+ et solde de cotisations subventionnées
				SELECT
					CE.ConventionID,
					
					-- Solde de la SCEE et SCEE+
					fCESG = SUM(CE.fCESG), 
					fACESG = SUM(CE.fACESG), 
					
					fCotisationGranted = SUM(CE.fCotisationGranted) -- Solde des cotisations subventionnées
				FROM Un_CESP CE 
				WHERE CE.ConventionID = @ConventionID
				GROUP BY CE.ConventionID
				) G ON G.ConventionID = C.ConventionID
			LEFT JOIN ( -- Solde SCEE et SCEE+ à rembourser
				SELECT
					C4.ConventionID,
					
					-- Solde de la SCEE et SCEE+
					fCESG = SUM(C4.fCESG),
					fACESGPart = SUM(C4.fACESGPart),
					
					fCotisationGranted = SUM(C4.fCotisationGranted)
				FROM Un_CESP400 C4
				LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID
				LEFT JOIN Un_CESP CE ON CE.OperID = C4.OperID
				WHERE C9.iCESP900ID IS NULL
					AND C4.iCESP800ID IS NULL
					AND CE.iCESPID IS NULL
					AND C4.ConventionID = @ConventionID
				GROUP BY C4.ConventionID
				) C4 ON C4.ConventionID = C.ConventionID
			WHERE Ct.CotisationID = @CotisationID
				AND dbo.FN_CRQ_DateNoTime(ISNULL(C.dtRegStartDate,Ct.EffectDate+1)) <= Ct.EffectDate -- Pas dans un compte bloqué
				AND ISNULL(HB.SocialNumber,'') <> ''
				AND Ct.CotisationID NOT IN (
						-- Cotisation qui ont un enregistrement 400 expédié qui est valide.
						SELECT Ct.CotisationID
						FROM Un_Cotisation Ct
						JOIN Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID
						LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
						WHERE Ct.CotisationID = @CotisationID
							AND G4.iCESP800ID IS NULL -- Pas revenu en erreur
							AND G4.iReversedCESP400ID IS NULL -- Pas une annulation
							AND R4.iCESP400ID IS NULL -- Pas annulé
						)
	END
	---------------
	-- Type 21-3 --  Sauf pour les opérations FRM qui sont traités par la IU_UN_CESP400ForOper
	---------------
	ELSE IF @tiCESP400TypeID = 21 
			AND @tiCESP400WithdrawReasonID = 3
	BEGIN
		SELECT @ConventionID = U.ConventionID
		FROM Un_Cotisation Ct
		JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		WHERE Ct.CotisationID = @CotisationID
			AND O.OperTypeID <> 'FRM'

		INSERT INTO Un_CESP400 (
				OperID,
				CotisationID,
				ConventionID,
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
				fCESG,
				fACESGPart,
				fEAPCESG,
				fEAP,
				fPSECotisation,
				fCLB,
				fEAPCLB,
				fPG,
				fEAPPG,
				fCotisationGranted )
			SELECT
				Ct.OperID,
				Ct.CotisationID,
				C.ConventionID,
				21,
				3,
				'FIN',
				Ct.EffectDate,
				P.PlanGovernmentRegNo,
				C.ConventionNo,
				ISNULL(HS.SocialNumber,''),
				HB.SocialNumber,
				0,
				C.bCESGRequested,
				
				-- Rembourse la totalité de la subvention
				-- SCEE
				-(ISNULL(G.fCESG + G.fACESG,0) + ISNULL(C4.fCESG,0)),
				-- SCEE+
				-(ISNULL(G.fACESG,0) + ISNULL(C4.fACESGPart,0)),
				
				0,
				0,
				0,
				-- Rembourse la totalité du BEC
				-(ISNULL(G.fCLB,0)+ISNULL(C4.fCLB,0)),
				0,
				0,
				0,
				-(ISNULL(G.fCotisationGranted,0)+ISNULL(C4.fCotisationGranted,0))
			FROM Un_Cotisation Ct
			JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
			JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
			JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
			LEFT JOIN ( -- Solde SCEE et SCEE+ et solde de BEC
				SELECT
					G.ConventionID,
					
					-- Solde de la SCEE et SCEE+
					fCESG = SUM(G.fCESG), 
					fACESG = SUM(G.fACESG), 
					
					fCLB = SUM(G.fCLB), -- Solde de BEC
					fCotisationGranted = SUM(G.fCotisationGranted) -- Solde des cotisations subventionnées
				FROM Un_CESP G 
				WHERE G.ConventionID = @ConventionID
				GROUP BY G.ConventionID
				) G ON G.ConventionID = C.ConventionID
			LEFT JOIN ( -- Solde SCEE et SCEE+ à rembourser
				SELECT
					C4.ConventionID,
					
					-- Solde de la SCEE et SCEE+ à rembourser
					fCESG = SUM(C4.fCESG), 
					fACESGPart = SUM(C4.fACESGPart), 
					
					fCLB = SUM(C4.fCLB), -- Solde de BEC à rembourser
					fCotisationGranted = SUM(C4.fCotisationGranted) -- Solde des cotisations subventionnées
				FROM Un_CESP400 C4 
				LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID
				LEFT JOIN Un_CESP CE ON CE.OperID = C4.OperID
				WHERE C9.iCESP900ID IS NULL
					AND C4.iCESP800ID IS NULL
					AND CE.iCESPID IS NULL
					AND C4.ConventionID = @ConventionID
				GROUP BY C4.ConventionID
				) C4 ON C4.ConventionID = C.ConventionID
			WHERE Ct.CotisationID = @CotisationID
				AND C.ConventionID = @ConventionID
				AND dbo.FN_CRQ_DateNoTime(ISNULL(C.dtRegStartDate,Ct.EffectDate+1)) <= Ct.EffectDate -- Pas dans un compte bloqué
				AND ISNULL(HB.SocialNumber,'') <> ''
				AND Ct.CotisationID NOT IN (
						-- Cotisation qui ont un enregistrement 400 expédié qui est valide.
						SELECT Ct.CotisationID
						FROM Un_Cotisation Ct
						JOIN Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID
						LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
						WHERE Ct.CotisationID = @CotisationID
							AND G4.iCESP800ID IS NULL -- Pas revenu en erreur
							AND G4.iReversedCESP400ID IS NULL -- Pas une annulation
							AND R4.iCESP400ID IS NULL -- Pas annulé
						)
	END
	---------------
	-- Type 21-4 --
	---------------
	ELSE IF @tiCESP400TypeID = 21 
			AND @tiCESP400WithdrawReasonID = 4
	BEGIN
		SELECT @ConventionID = U.ConventionID
		FROM Un_Cotisation Ct
		JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
		WHERE Ct.CotisationID = @CotisationID

		INSERT INTO Un_CESP400 (
				OperID,
				CotisationID,
				ConventionID,
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
				fCESG,
				fACESGPart,
				fEAPCESG,
				fEAP,
				fPSECotisation,
				fCLB,
				fEAPCLB,
				fPG,
				fEAPPG,
				fCotisationGranted )
			SELECT
				Ct.OperID,
				Ct.CotisationID,
				C.ConventionID,
				21,
				4,
				'FIN',
				Ct.EffectDate,
				P.PlanGovernmentRegNo,
				C.ConventionNo,
				ISNULL(HS.SocialNumber,''),
				HB.SocialNumber,
				0,
				C.bCESGRequested,

				-- SCEE
				CASE
					-- Rembourse rien 0.00 si le solde de subvention et négatif ou à 0.00
					WHEN ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0) <= 0 
						THEN 0
					-- Rembourse tout s'il n'y a pas de cotisations subventionnées
					WHEN ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0) = 0 
						THEN -(ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0))
					-- Rembourse tout si on retire toutes les cotisations subventionnées
					WHEN ABS(Ct.Cotisation + Ct.Fee) > ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0) 
						THEN -(ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0))
					-- Rembourse tout si le proprata selon la formule A/B*C du règlement sur l’épargne-études est plus élevé que le total de la SCEE
					WHEN ROUND((ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0)) / (ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0)) * ABS(Ct.Cotisation + Ct.Fee), 2) > ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0) 
						THEN -(ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0))
					-- Rembourse au proprata selon la formule A/B*C du règlement sur l’épargne-études si on retire seulement une partie des cotisations subventionnées
					ELSE 
						-(ROUND((ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0)) / (ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0)) * ABS(Ct.Cotisation + Ct.Fee), 2))
				END,

				-- SCEE+
				CASE
					-- Rembourse rien 0.00 si le solde de subvention et négatif ou à 0.00
					WHEN ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0) <= 0 
						THEN 0
					-- Rembourse tout s'il n'y a pas de cotisations subventionnées
					WHEN ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0) = 0 
						THEN -(ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0))
					-- Rembourse tout si on retire toutes les cotisations subventionnées
					WHEN ABS(Ct.Cotisation + Ct.Fee) > ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0) 
						THEN -(ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0))
					-- Rembourse tout si le proprata selon la formule A/B*C du règlement sur l’épargne-études est plus élevé que le total de la SCEE
					WHEN ROUND((ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0)) / (ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0)) * ABS(Ct.Cotisation + Ct.Fee), 2) > ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0) 
						THEN -(ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0))
					-- Rembourse au proprata selon la formule A/B*C du règlement sur l’épargne-études si on retire seulement une partie des cotisations subventionnées
					ELSE 
						-(ROUND((ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0)) / (ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0)) * ABS(Ct.Cotisation + Ct.Fee), 2))
				END,

				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0
			FROM Un_Cotisation Ct
			JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
			JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
			JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
			LEFT JOIN ( -- Solde SCEE et SCEE+ et solde de cotisations subventionnées
				SELECT
					G.ConventionID,
					
					-- Solde de la SCEE et SCEE+
					fCESG = SUM(G.fCESG), 
					fACESG = SUM(G.fACESG), 
					
					fCotisationGranted = SUM(G.fCotisationGranted) -- Solde des cotisations subventionnées
				FROM Un_CESP G 
				WHERE G.ConventionID = @ConventionID
				GROUP BY G.ConventionID
				) G ON G.ConventionID = C.ConventionID
			LEFT JOIN ( -- Solde SCEE et SCEE+ à rembourser
				SELECT
					C4.ConventionID,
					
					-- Solde de la SCEE et SCEE+
					fCESG = SUM(C4.fCESG), 
					fACESGPart = SUM(C4.fACESGPart), 
					
					fCotisationGranted = SUM(C4.fCotisationGranted)
				FROM Un_CESP400 C4
				LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID
				LEFT JOIN Un_CESP CE ON CE.OperID = C4.OperID
				WHERE C9.iCESP900ID IS NULL
					AND C4.iCESP800ID IS NULL
					AND CE.iCESPID IS NULL
					AND C4.ConventionID = @ConventionID
				GROUP BY C4.ConventionID
				) C4 ON C4.ConventionID = C.ConventionID
			WHERE Ct.CotisationID = @CotisationID
				AND dbo.FN_CRQ_DateNoTime(ISNULL(C.dtRegStartDate,Ct.EffectDate+1)) <= Ct.EffectDate -- Pas dans un compte bloqué
				AND ISNULL(HB.SocialNumber,'') <> ''
				AND Ct.CotisationID NOT IN (
						-- Cotisation qui ont un enregistrement 400 expédié qui est valide.
						SELECT Ct.CotisationID
						FROM Un_Cotisation Ct
						JOIN Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID
						LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
						WHERE Ct.CotisationID = @CotisationID
							AND G4.iCESP800ID IS NULL -- Pas revenu en erreur
							AND G4.iReversedCESP400ID IS NULL -- Pas une annulation
							AND R4.iCESP400ID IS NULL -- Pas annulé
						)
	END
	---------------
	-- Type 21-9 --
	---------------
	ELSE IF @tiCESP400TypeID = 21 
			AND @tiCESP400WithdrawReasonID = 9
	BEGIN
		SELECT @ConventionID = U.ConventionID
		FROM Un_Cotisation Ct
		JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
		WHERE Ct.CotisationID = @CotisationID

		INSERT INTO Un_CESP400 (
				OperID,
				CotisationID,
				ConventionID,
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
				fCESG,
				fACESGPart,
				fEAPCESG,
				fEAP,
				fPSECotisation,
				fCLB,
				fEAPCLB,
				fPG,
				fEAPPG,
				fCotisationGranted )
			SELECT
				Ct.OperID,
				Ct.CotisationID,
				C.ConventionID,
				21,
				9,
				'FIN',
				Ct.EffectDate,
				P.PlanGovernmentRegNo,
				C.ConventionNo,
				ISNULL(HS.SocialNumber,''),
				HB.SocialNumber,
				0,
				C.bCESGRequested,

				-- SCEE
				CASE
					-- Rembourse rien 0.00 si le solde de subvention et négatif ou à 0.00
					WHEN ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0) <= 0 
						THEN 0
					-- Rembourse tout s'il n'y a pas de cotisations subventionnées
					WHEN ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0) = 0 
						THEN -(ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0))
					-- Rembourse tout si on retire toutes les cotisations subventionnées
					WHEN ABS(Ct.Cotisation + Ct.Fee) > ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0) 
						THEN -(ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0))
					-- Rembourse tout si le proprata selon la formule A/B*C du règlement sur l’épargne-études est plus élevé que le total de la SCEE
					WHEN ROUND((ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0)) / (ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0)) * ABS(Ct.Cotisation + Ct.Fee), 2) > ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0) 
						THEN -(ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0))
					-- Rembourse au proprata selon la formule A/B*C du règlement sur l’épargne-études si on retire seulement une partie des cotisations subventionnées
					ELSE 
						-(ROUND((ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0)) / (ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0)) * ABS(Ct.Cotisation+Ct.Fee), 2))
				END,

				-- SCEE+
				CASE
					-- Rembourse rien 0.00 si le solde de subvention et négatif ou à 0.00
					WHEN ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0) <= 0 
						THEN 0
					-- Rembourse tout s'il n'y a pas de cotisations subventionnées
					WHEN ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0) = 0 
						THEN -(ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0))
					-- Rembourse tout si on retire toutes les cotisations subventionnées
					WHEN ABS(Ct.Cotisation + Ct.Fee) > ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0) 
						THEN -(ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0))
					-- Rembourse tout si le proprata selon la formule A/B*C du règlement sur l’épargne-études est plus élevé que le total de la SCEE
					WHEN ROUND((ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0)) / (ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0)) * ABS(Ct.Cotisation + Ct.Fee), 2) > ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0) 
						THEN -(ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0))
					-- Rembourse au proprata selon la formule A/B*C du règlement sur l’épargne-études si on retire seulement une partie des cotisations subventionnées
					ELSE 
						-(ROUND((ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0)) / (ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0)) * ABS(Ct.Cotisation + Ct.Fee), 2))
				END,

				0,
				0,
				0,
				0,
				0,
				0,
				0,
				CASE
					-- Le montant de cotisations subventionnées ne varie pas car on ne rembourse pas de subvention car il n'y en a pas.
					WHEN ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0) <= 0 
						THEN 0
					-- Le montant de cotisations subventionnées de la convention est déjà 0.00
					WHEN ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0) = 0 
						THEN 0
					-- On retire toutes les cotisations subventionnées
					WHEN ABS(Ct.Cotisation + Ct.Fee) > ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0) 
						THEN -(ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0))
					-- On retire toutes les cotisations subventionnées
					WHEN ROUND((ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0)) / (ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0)) * ABS(Ct.Cotisation + Ct.Fee), 2) > ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0) 
						THEN -(ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0))
					-- On rembourse une partie des cotisations subventionnées
					ELSE 
						Ct.Cotisation + Ct.Fee
				END
			FROM Un_Cotisation Ct
			JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
			JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
			JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
			LEFT JOIN ( -- Solde SCEE et SCEE+ et solde de cotisations subventionnées
				SELECT
					G.ConventionID,
					
					-- Solde de la SCEE et SCEE+
					fCESG = SUM(G.fCESG), 
					fACESG = SUM(G.fACESG), 
					
					fCotisationGranted = SUM(G.fCotisationGranted) -- Solde des cotisations subventionnées
				FROM Un_CESP G 
				WHERE G.ConventionID = @ConventionID
				GROUP BY G.ConventionID
				) G ON G.ConventionID = C.ConventionID
			LEFT JOIN ( -- Solde SCEE et SCEE+ à rembourser
				SELECT
					C4.ConventionID,
					
					-- Solde de la SCEE et SCEE+
					fCESG = SUM(C4.fCESG), 
					fACESGPart = SUM(C4.fACESGPart), 
					
					fCotisationGranted = SUM(C4.fCotisationGranted)
				FROM Un_CESP400 C4
				LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID
				LEFT JOIN Un_CESP CE ON CE.OperID = C4.OperID
				WHERE C9.iCESP900ID IS NULL
					AND C4.iCESP800ID IS NULL
					AND CE.iCESPID IS NULL
					AND C4.ConventionID = @ConventionID
				GROUP BY C4.ConventionID
				) C4 ON C4.ConventionID = C.ConventionID
			WHERE Ct.CotisationID = @CotisationID
				AND dbo.FN_CRQ_DateNoTime(ISNULL(C.dtRegStartDate,Ct.EffectDate+1)) <= Ct.EffectDate -- Pas dans un compte bloqué
				AND ISNULL(HB.SocialNumber,'') <> ''
				AND Ct.CotisationID NOT IN (
						-- Cotisation qui ont un enregistrement 400 expédié qui est valide.
						SELECT Ct.CotisationID
						FROM Un_Cotisation Ct
						JOIN Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID
						LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
						WHERE Ct.CotisationID = @CotisationID
							AND G4.iCESP800ID IS NULL -- Pas revenu en erreur
							AND G4.iReversedCESP400ID IS NULL -- Pas une annulation
							AND R4.iCESP400ID IS NULL -- Pas annulé
						)
	END
	---------------
	-- Type 21-10 --
	---------------
	ELSE IF @tiCESP400TypeID = 21 
			AND @tiCESP400WithdrawReasonID = 10
	BEGIN
		SELECT @ConventionID = U.ConventionID
		FROM Un_Cotisation Ct
		JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
		WHERE Ct.CotisationID = @CotisationID

		INSERT INTO Un_CESP400 (
				OperID,
				CotisationID,
				ConventionID,
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
				fCESG,
				fACESGPart,
				fEAPCESG,
				fEAP,
				fPSECotisation,
				fCLB,
				fEAPCLB,
				fPG,
				fEAPPG,
				fCotisationGranted )
			SELECT
				Ct.OperID,
				Ct.CotisationID,
				C.ConventionID,
				21,
				10,
				'FIN',
				Ct.EffectDate,
				P.PlanGovernmentRegNo,
				C.ConventionNo,
				ISNULL(HS.SocialNumber,''),
				HB.SocialNumber,
				0,
				C.bCESGRequested,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				Ct.Cotisation+Ct.Fee
			FROM Un_Cotisation Ct
			JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
			JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
			JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
			WHERE Ct.CotisationID = @CotisationID
				AND dbo.FN_CRQ_DateNoTime(ISNULL(C.dtRegStartDate,Ct.EffectDate+1)) <= Ct.EffectDate -- Pas dans un compte bloqué
				AND ISNULL(HB.SocialNumber,'') <> ''
				AND Ct.CotisationID NOT IN (
						-- Cotisation qui ont un enregistrement 400 expédié qui est valide.
						SELECT Ct.CotisationID
						FROM Un_Cotisation Ct
						JOIN Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID
						LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
						WHERE Ct.CotisationID = @CotisationID
							AND G4.iCESP800ID IS NULL -- Pas revenu en erreur
							AND G4.iReversedCESP400ID IS NULL -- Pas une annulation
							AND R4.iCESP400ID IS NULL -- Pas annulé
						)
	END
	-------------
	-- Type 23 --
	-------------
	ELSE IF @tiCESP400TypeID = 23
	BEGIN	
		-- Ici on va chercher l'OperID
		SELECT 
			@OperID = Ct.OperID
		FROM Un_Cotisation Ct
		WHERE Ct.CotisationID = @CotisationID

		INSERT INTO Un_CESP400 (
				OperID,
				CotisationID,
				ConventionID,
				tiCESP400TypeID,
				vcTransID,
				dtTransaction,
				iPlanGovRegNumber,
				ConventionNo,
				vcSubscriberSINorEN,
				vcBeneficiarySIN,
				fCotisation,
				bCESPDemand,
				fCESG,
				fACESGPart,
				fEAPCESG,
				fEAP,
				fPSECotisation,
				iOtherPlanGovRegNumber,
				vcOtherConventionNo,
				fCLB,
				fEAPCLB,
				fPG,
				fEAPPG )
			SELECT
				Ct.OperID,
				Ct.CotisationID,
				C.ConventionID,
				23,
				'FIN',
				Ct.EffectDate,
				P.PlanGovernmentRegNo,
				C.ConventionNo,
				ISNULL(HS.SocialNumber,''),
				HB.SocialNumber,
				Ct.Cotisation+Ct.Fee,
				C.bCESGRequested,
				CE.fCESG + CE.fACESG,
				CE.fACESG,
				0,
				0,
				0,
				EP.ExternalPlanGovernmentRegNo,
				T.vcOtherConventionNo,
				CE.fCLB,
				0,
				0,
				0
			FROM Un_Cotisation Ct
			JOIN Un_OUT T ON T.OperID = Ct.OperID
			JOIN Un_ExternalPlan EP ON EP.ExternalPlanID = T.ExternalPlanID
			JOIN Un_CESP CE ON CE.OperID = Ct.OperID
			JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
			JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
			JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID			
			WHERE Ct.CotisationID = @CotisationID
				AND Ct.CotisationID NOT IN (
						-- Cotisation qui ont un enregistrement 400 expédié qui est valide.
						SELECT Ct.CotisationID
						FROM Un_Cotisation Ct
						JOIN Un_CESP400 C4 ON C4.CotisationID = Ct.CotisationID
						LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = C4.iCESP400ID
						LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID AND C9.tiCESP900OriginID = 3 -- Transaction 900 dont l'origine n'est pas transfert non-réglé
						WHERE Ct.CotisationID = @CotisationID
							AND C4.iCESP800ID IS NULL -- Pas revenu en erreur
							AND C9.iCESP900ID IS NULL
							AND C4.iReversedCESP400ID IS NULL -- Pas une annulation
							AND R4.iCESP400ID IS NULL -- Pas annulé
							AND C4.tiCESP400TypeID = 23 -- DU meme type
						)	
	END
	-------------
	-- Type 24 --
	-------------
	ELSE IF @tiCESP400TypeID = 24
	BEGIN
		INSERT INTO Un_CESP400 (
				OperID,
				CotisationID,
				ConventionID,
				tiCESP400TypeID,
				vcTransID,
				dtTransaction,
				iPlanGovRegNumber,
				ConventionNo,
				vcSubscriberSINorEN,
				vcBeneficiarySIN,
				fCotisation,
				bCESPDemand,
				fCESG,
				fACESGPart,
				fEAPCESG,
				fEAP,
				fPSECotisation,
				vcPCGSINorEN,
				vcPCGFirstName,
				vcPCGLastName,
				tiPCGType,
				fCLB,
				fEAPCLB,
				fPG,
				fEAPPG )
			SELECT
				Ct.OperID,
				Ct.CotisationID,
				C.ConventionID,
				24,
				'FIN',
				CASE
					WHEN DATEDIFF(YEAR, Ct.EffectDate, GETDATE()) >= 2 THEN dbo.FN_CRQ_DateNoTime(GETDATE())
				ELSE Ct.EffectDate
				END,
				P.PlanGovernmentRegNo,
				C.ConventionNo,
				ISNULL(HS.SocialNumber,''),
				HB.SocialNumber,
				0,
				C.bCLBRequested,
				0,
				0,
				0,
				0,
				0,
				B.vcPCGSINOrEN,
				B.vcPCGFirstName,
				B.vcPCGLastName,
				B.tiPCGType,
				0,
				0,
				0,
				0
			FROM Un_Cotisation Ct
			JOIN Un_Oper O ON O.OperID = Ct.OperID
			JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
			JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
			JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID			
			WHERE Ct.CotisationID = @CotisationID
				AND ISNULL(HB.SocialNumber,'') <> ''
				AND Ct.CotisationID NOT IN (
						-- Cotisation qui ont un enregistrement 400 expédié qui est valide.
						SELECT Ct.CotisationID
						FROM Un_Cotisation Ct
						JOIN Un_CESP400 C4 ON C4.CotisationID = Ct.CotisationID
						LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = C4.iCESP400ID
						WHERE Ct.CotisationID = @CotisationID
							AND C4.iCESP800ID IS NULL -- Pas revenu en erreur
							AND C4.iReversedCESP400ID IS NULL -- Pas une annulation
							AND R4.iCESP400ID IS NULL -- Pas annulé
							AND C4.tiCESP400TypeID = 24 -- DU meme type
						)				
	END	
	
	IF @@ERROR <> 0 
		SET @iReturn = -1

	IF @iReturn > 0
	BEGIN
		-- Inscrit le vcTransID avec le ID FIN + <iCESP400ID>.
		UPDATE Un_CESP400
		SET vcTransID = 'FIN'+CAST(iCESP400ID AS VARCHAR(12))
		WHERE vcTransID = 'FIN'

		IF @@ERROR <> 0
			SET @iReturn = -2
	END

	RETURN @iReturn
END


