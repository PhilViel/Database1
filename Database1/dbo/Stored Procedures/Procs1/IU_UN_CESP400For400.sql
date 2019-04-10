/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_CESP400For400
Description         :	Procédure qui crée un enregistrement 400 selon une liste d'ancien 400
Valeurs de retours  :	@ReturnValue :
									> 0 : Réussite
									<= 0 : Erreurs.
Note                :	
		ADX0002426	BR	2007-05-15	Alain Quirion			Création
		ADX0002465	BR	2007-05-31	Bruno Lapointe			Correction du problème des annualtions de 400 qui
															se doublait quand il avait plus d'une 900 sur la 400 annulée.
		ADX0002502	BR	2007-06-27	Bruno Lapointe			NAS absent mal géré pour les conventions entrées en vigueur avant 
															le 1 janvier 2003
		ADX0001249	UP	2007-09-27	Bruno Lapointe			Erreur sur type 19 : OperID ne peut être null.
						2010-03-29	Jean-François Gauthier	Appel à la fonction FN_CRQ_DateNoTime pour éliminer les heures/min/sec sur dtRegStartDate
						2010-06-29	Pierre Paquet			Ajustement à la création du 400-24 afin de s'assurer que la trx correspondant à la valeur de la case.
						2011-01-31	Frederick Thibault		Ajout du champ fACESGPart pour régler le problème SCEE+

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_CESP400For400] (
	@ConnectID INTEGER, -- ID Unique de connexion de l'usager
	@iBlobID INTEGER, -- ID du blob contant la liste des iCESP400ID a renvoyé
	@tiCESP400TypeID SMALLINT, -- Type d'enregistrement à créer
	@tiCESP400WithdrawReasonID TINYINT) -- Raison du remboursement si s'en est un
	
AS
BEGIN
	DECLARE
		@iCESP400ID INTEGER,
		@CotisationID INTEGER,
		@iReturn INTEGER

	SET @iReturn = 1

	DECLARE @tCESP400ID TABLE (
		iValID INTEGER,
		iCESP400ID INTEGER)

	CREATE TABLE #tCESP400IDReversed (
		iValID INTEGER,
		iCESP400ID INTEGER)

	INSERT INTO @tCESP400ID
	SELECT V.*
	FROM dbo.FN_CRI_BlobToIntegerTable (@iBlobID) V
	JOIN Un_CESP400 C4 ON C4.iCESP400ID = V.iVal
	WHERE C4.iReversedCESP400ID IS NULL

	INSERT INTO #tCESP400IDReversed
	SELECT V.*
	FROM dbo.FN_CRI_BlobToIntegerTable (@iBlobID) V
	JOIN Un_CESP400 C4 ON C4.iCESP400ID = V.iVal
	WHERE C4.iReversedCESP400ID IS NOT NULL

	SELECT @iCESP400ID = MAX(iCESP400ID)
	FROM Un_CESP400

	IF EXISTS ( SELECT * 
				FROM @tCESP400ID) --S'il y a des 400 de demandes
	BEGIN
		---------------------------
		-- Type 11 --
		---------------------------
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
					fACESGPart, -- FT
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
					0, -- FT
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
				FROM @tCESP400ID tC4
				JOIN Un_CESP400 C4 ON C4.iCESP400ID = tC4.iCESP400ID
				JOIN Un_Cotisation Ct ON Ct.CotisationID = C4.CotisationID
				JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
				JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				JOIN Un_Plan P ON P.PlanID = C.PlanID
				JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
				JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
				JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID			
				WHERE 
					ISNULL(dbo.FN_CRQ_DateNoTime(C.dtRegStartDate),Ct.EffectDate+1) <= Ct.EffectDate -- Pas dans un compte bloqué
					AND ISNULL(HB.SocialNumber,'') <> ''
					AND Ct.CotisationID NOT IN (
							-- Cotisation qui ont un enregistrement 400 expédié qui est valide.
							SELECT Ct.CotisationID
							FROM Un_Cotisation Ct
							JOIN Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID
							JOIN (	SELECT C4.CotisationID
									FROM Un_CESP400 C4					
									JOIN @tCESP400ID tC4 ON tC4.iCESP400ID = C4.iCESP400ID) tC4 ON tC4.CotisationID = Ct.CotisationID
							LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
							WHERE G4.iCESP800ID IS NULL -- Pas revenu en erreur
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
					fACESGPart, -- FT
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
					0, -- FT
					0,
					0,
					-Ct.Cotisation+Ct.Fee,
					IR.ProgramLength,	--tiProgramLength
					CL.CollegeTypeID,		--cCollegeTypeID
					CL.CollegeCode,		--vcCollegeCode
					IR.ProgramYear,		--siProgramYear
					0,
					0,
					0,
					0,
					Ct.Cotisation+Ct.Fee
				FROM @tCESP400ID tC4
				JOIN Un_CESP400 C4 ON C4.iCESP400ID = tC4.iCESP400ID
				JOIN Un_Cotisation Ct ON Ct.CotisationID = C4.CotisationID
				JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
				JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				JOIN Un_Plan P ON P.PlanID = C.PlanID
				JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
				JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
				JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
				JOIN Un_IntReimbOper IRO ON IRO.OperID = Ct.OperID
				JOIN Un_IntReimb IR ON IR.IntReimbID = IRO.IntReimbID
				JOIN Un_College CL ON CL.CollegeID = IR.CollegeID
				WHERE ISNULL(dbo.FN_CRQ_DateNoTime(C.dtRegStartDate),Ct.EffectDate+1) <= Ct.EffectDate -- Pas dans un compte bloqué
					AND ISNULL(HB.SocialNumber,'') <> ''
					AND Ct.CotisationID NOT IN (
							-- Cotisation qui ont un enregistrement 400 expédié qui est valide.
							SELECT Ct.CotisationID
							FROM Un_Cotisation Ct
							JOIN Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID
							JOIN (	SELECT C4.CotisationID
									FROM Un_CESP400 C4					
									JOIN @tCESP400ID tC4 ON tC4.iCESP400ID = C4.iCESP400ID) tC4 ON tC4.CotisationID = Ct.CotisationID
							LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
							WHERE G4.iCESP800ID IS NULL -- Pas revenu en erreur
								AND G4.iReversedCESP400ID IS NULL -- Pas une annulation
								AND R4.iCESP400ID IS NULL -- Pas annulé
							)
		END
		-------------
		-- Type 19 --
		-------------
		ELSE IF @tiCESP400TypeID = 19
		BEGIN
			DECLARE @tConvTrans19 TABLE (
				OperID INTEGER PRIMARY KEY )

			INSERT INTO @tConvTrans19
				-- Ici on va chercher la 900 originale, ici on s'Appui sur le fait qu'un TIN ne 
				-- peut pas être modifié
				SELECT DISTINCT
					CE.OperID
				FROM @tCESP400ID tC4		
				JOIN Un_CESP400 C4 ON C4.iCESP400ID = tC4.iCESP400ID
				JOIN Un_CESP CE ON CE.OperID = C4.OperID

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
					fACESGPart, -- FT
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
					CE.fACESG, -- FT
					
					0,
					0,
					0,
					EP.ExternalPlanGovernmentRegNo,
					T.vcOtherConventionNo,
					CE.fCLB,
					0,
					0,
					0
				FROM @tConvTrans19 C19
				JOIN Un_TIN T ON C19.OperID = T.OperID
				JOIN (
					SELECT
						Ct.OperID, 
						CotisationID = MIN(Ct.CotisationID),
						EffectDate = MAX(Ct.EffectDate),
						Cotisation = SUM(Ct.Cotisation),
						Fee = SUM(Ct.Fee)
					FROM @tCESP400ID tC4
					JOIN Un_CESP400 C4 ON C4.iCESP400ID = tC4.iCESP400ID
					JOIN Un_Cotisation Ct ON C4.CotisationID = Ct.CotisationID			
					GROUP BY Ct.OperID
					) Ct ON T.OperID = Ct.OperID
				JOIN Un_ExternalPlan EP ON EP.ExternalPlanID = T.ExternalPlanID
				JOIN Un_CESP CE ON CE.OperID = T.OperID
				JOIN Un_CESP900 C9 ON C9.iCESPID = CE.iCESPID
				JOIN dbo.Un_Convention C ON C.ConventionID = CE.ConventionID
				JOIN Un_Plan P ON P.PlanID = C.PlanID
				JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
				JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
				JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
				WHERE T.OperID NOT IN (
							-- Opération qui ont un enregistrement 400 expédié qui est valide.
							SELECT C4.OperID
							FROM Un_CESP400 C4
							JOIN (	SELECT C4.OperID
									FROM Un_CESP400 C4					
									JOIN @tCESP400ID tC4 ON tC4.iCESP400ID = C4.iCESP400ID) tC4 ON tC4.OperID = C4.OperID
							LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = C4.iCESP400ID
							LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID AND C9.tiCESP900OriginID = 3 -- Transaction 900 dont l'origine n'est pas transfert non-réglé
							WHERE C4.iCESP800ID IS NULL 		-- Pas revenu en erreur
								AND C9.iCESP900ID IS NULL
								AND C4.iReversedCESP400ID IS NULL 	-- Pas une annulation
								AND R4.iCESP400ID IS NULL 		-- Pas annulé
							)
					AND C9.iCESP400ID IN (SELECT iCESP400ID FROM @tCESP400ID)	
		END
		---------------
		-- Type 21-1 --
		---------------
		ELSE IF @tiCESP400TypeID = 21 
				AND @tiCESP400WithdrawReasonID = 1
		BEGIN
			DECLARE @tConvTrans21_1 TABLE (
				ConventionID INTEGER PRIMARY KEY )

			INSERT INTO @tConvTrans21_1
				SELECT 
					U.ConventionID
				FROM @tCESP400ID tC4
				JOIN Un_CESP400 C4 ON C4.iCESP400ID = tC4.iCESP400ID
				JOIN Un_Cotisation Ct ON C4.CotisationID = Ct.CotisationID
				JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
				GROUP BY U.ConventionID

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
					fACESGPart, -- FT
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

					-- FT
					-- SCEE
					CASE
						-- Rembourse rien 0.00 si le solde de subvention et négatif ou à 0.00
						WHEN ISNULL(G.fCESG + G.fACESG, 0) - ISNULL(C4.fCESG, 0) <= 0 
							THEN 0
						-- Rembourse tout s'il n'y a pas de cotisations subventionnées
						WHEN ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0) = 0 
							THEN ISNULL(G.fCESG + G.fACESG, 0) - ISNULL(C4.fCESG, 0)
						-- Rembourse tout si on retire toutes les cotisations subventionnées
						WHEN ABS(Ct.Cotisation + Ct.Fee) > ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0) 
							THEN ISNULL(G.fCESG + G.fACESG, 0) - ISNULL(C4.fCESG, 0)
						-- Rembourse tout si le proprata selon la formule A/B*C du règlement sur l’épargne-études est plus élevé que le total de la SCEE
						WHEN ROUND((ISNULL(G.fCESG + G.fACESG, 0) - ISNULL(C4.fCESG, 0)) / (ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0)) * ABS(Ct.Cotisation + Ct.Fee), 2) > ISNULL(G.fCESG + G.fACESG, 0) - ISNULL(C4.fCESG, 0) 
							THEN ISNULL(G.fCESG + G.fACESG, 0) - ISNULL(C4.fCESG, 0)
						-- Rembourse au proprata selon la formule A/B*C du règlement sur l’épargne-études si on retire seulement une partie des cotisations subventionnées
						ELSE 
							ROUND((ISNULL(G.fCESG + G.fACESG, 0) - ISNULL(C4.fCESG, 0)) / (ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0)) * ABS(Ct.Cotisation + Ct.Fee), 2)
					END,
					
					-- FT
					-- SCEE+
					CASE
						-- Rembourse rien 0.00 si le solde de subvention et négatif ou à 0.00
						WHEN ISNULL(G.fACESG, 0) - ISNULL(C4.fACESGPart, 0) <= 0 
							THEN 0
						-- Rembourse tout s'il n'y a pas de cotisations subventionnées
						WHEN ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0) = 0 
							THEN ISNULL(G.fACESG, 0) - ISNULL(C4.fACESGPart, 0)
						-- Rembourse tout si on retire toutes les cotisations subventionnées
						WHEN ABS(Ct.Cotisation + Ct.Fee) > ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0) 
							THEN ISNULL(G.fACESG, 0) - ISNULL(C4.fACESGPart, 0)
						-- Rembourse tout si le proprata selon la formule A/B*C du règlement sur l’épargne-études est plus élevé que le total de la SCEE
						WHEN ROUND((ISNULL(G.fACESG, 0) - ISNULL(C4.fACESGPart, 0)) / (ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0)) * ABS(Ct.Cotisation + Ct.Fee), 2) > ISNULL(G.fACESG, 0) - ISNULL(C4.fACESGPart, 0) 
							THEN ISNULL(G.fACESG, 0) - ISNULL(C4.fACESGPart, 0)
						-- Rembourse au proprata selon la formule A/B*C du règlement sur l’épargne-études si on retire seulement une partie des cotisations subventionnées
						ELSE 
							ROUND((ISNULL(G.fACESG, 0) - ISNULL(C4.fACESGPart, 0)) / (ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0)) * ABS(Ct.Cotisation + Ct.Fee), 2)
					END,

					0,
					0,
					0,
					0,
					0,
					0,
					0,
					-- FT
					-- Cotisation
					CASE
						-- Le montant de cotisations subventionnées ne varie pas car on ne rembourse pas de subvention car il n'y en a pas.
						WHEN ISNULL(G.fCESG + G.fACESG, 0) - ISNULL(C4.fCESG, 0) <= 0 
							THEN 0
						-- Le montant de cotisations subventionnées de la convention est déjà 0.00
						WHEN ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0) = 0 
							THEN 0
						-- On retire toutes les cotisations subventionnées
						WHEN ABS(Ct.Cotisation + Ct.Fee) > ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0) 
							THEN -(ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0))
						-- On retire toutes les cotisations subventionnées
						WHEN ROUND((ISNULL(G.fCESG + G.fACESG, 0) - ISNULL(C4.fCESG, 0)) / (ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0)) * ABS(Ct.Cotisation + Ct.Fee), 2) > ISNULL(G.fCESG + G.fACESG, 0) - ISNULL(C4.fCESG, 0) 
							THEN -(ISNULL(G.fCotisationGranted,0) + ISNULL(C4.fCotisationGranted,0))
						-- On rembourse une partie des cotisations subventionnées
						ELSE 
							Ct.Cotisation + Ct.Fee
					END
				FROM @tCESP400ID tC4
				JOIN Un_CESP400 C4A ON C4A.iCESP400ID = tC4.iCESP400ID
				JOIN Un_Cotisation Ct ON C4A.CotisationID = Ct.CotisationID
				JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
				JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				JOIN Un_Plan P ON P.PlanID = C.PlanID
				JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
				JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
				JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
				LEFT JOIN ( -- Solde SCEE et SCEE+ et solde de cotisations subventionnées
					SELECT
						I.ConventionID,

						-- FT
						--fCESG = SUM(CE.fCESG+CE.fACESG), -- Solde de la SCEE et SCEE+
						fCESG = SUM(CE.fCESG), -- Solde de la SCEE
						fACESG = SUM(CE.fACESG), -- Solde de la SCEE+

						fCotisationGranted = SUM(CE.fCotisationGranted) -- Solde des cotisations subventionnées
					FROM @tConvTrans21_1 I
					JOIN Un_CESP CE ON CE.ConventionID = I.ConventionID
					GROUP BY I.ConventionID
					) G ON G.ConventionID = C.ConventionID
				LEFT JOIN ( -- Solde SCEE et SCEE+ à rembourser
					SELECT
						I.ConventionID,

						fCESG = SUM(C4.fCESG), -- Solde de la SCEE et SCEE+
						-- FT
						fACESGPart = SUM(C4.fACESGPart), -- Solde de la SCEE+

						fCotisationGranted = SUM(C4.fCotisationGranted)
					FROM @tConvTrans21_1 I
					JOIN Un_CESP400 C4 ON C4.ConventionID = I.ConventionID
					WHERE C4.iCESPSendFileID IS NULL
					GROUP BY I.ConventionID
					) C4 ON C4.ConventionID = C.ConventionID
				WHERE ISNULL(dbo.FN_CRQ_DateNoTime(C.dtRegStartDate),Ct.EffectDate+1) <= Ct.EffectDate -- Pas dans un compte bloqué
					AND ISNULL(HB.SocialNumber,'') <> ''
					AND Ct.CotisationID NOT IN (
							-- Cotisation qui ont un enregistrement 400 expédié qui est valide.
							SELECT Ct.CotisationID
							FROM Un_Cotisation Ct
							JOIN Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID
							JOIN (	SELECT C4.CotisationID
									FROM Un_CESP400 C4					
									JOIN @tCESP400ID tC4 ON tC4.iCESP400ID = C4.iCESP400ID) tC4 ON tC4.CotisationID = Ct.CotisationID
							LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
							WHERE G4.iCESP800ID IS NULL -- Pas revenu en erreur
								AND G4.iReversedCESP400ID IS NULL -- Pas une annulation
								AND R4.iCESP400ID IS NULL -- Pas annulé
							)
		END
		---------------
		-- Type 21-3 --
		---------------
		ELSE IF @tiCESP400TypeID = 21 
				AND @tiCESP400WithdrawReasonID = 3
		BEGIN
			DECLARE @tConvTrans21_3 TABLE (
				ConventionID INTEGER PRIMARY KEY )

			INSERT INTO @tConvTrans21_3
				SELECT 
					U.ConventionID
				FROM @tCESP400ID tC4
				JOIN Un_CESP400 C4 ON C4.iCESP400ID = tC4.iCESP400ID
				JOIN Un_Cotisation Ct ON C4.CotisationID = Ct.CotisationID
				JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
				GROUP BY U.ConventionID

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
					fACESGPart, -- FT
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
					-- FT
					--ISNULL(G.fCESG,0)-ISNULL(C4.fCESG,0),
					-- SCEE
					ISNULL(G.fCESG + G.fACESG, 0) - ISNULL(C4.fCESG, 0),
					-- SCEE+
					ISNULL(G.fACESG, 0) - ISNULL(C4.fACESGPart, 0),
					
					0,
					0,
					0,
					-- Rembourse la totalité du BEC
					ISNULL(G.fCLB,0)-ISNULL(C4.fCLB,0),
					0,
					0,
					0,
					-(ISNULL(G.fCotisationGranted,0)+ISNULL(C4.fCotisationGranted,0))
				FROM @tCESP400ID tC4
				JOIN Un_CESP400 C4A ON C4A.iCESP400ID = tC4.iCESP400ID
				JOIN Un_Cotisation Ct ON C4A.CotisationID = Ct.CotisationID
				JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
				JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				JOIN Un_Plan P ON P.PlanID = C.PlanID
				JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
				JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
				JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
				LEFT JOIN ( -- Solde SCEE et SCEE+ et solde de BEC
					SELECT
						I.ConventionID,
						
						-- FT
						--fCESG = SUM(CE.fCESG+CE.fACESG), -- Solde de la SCEE et SCEE+
						fCESG = SUM(CE.fCESG),
						fACESG = SUM(CE.fACESG),
						
						fCLB = SUM(CE.fCLB), -- Solde de BEC
						fCotisationGranted = SUM(CE.fCotisationGranted) -- Solde des cotisations subventionnées
					FROM @tConvTrans21_3 I
					JOIN Un_CESP CE ON CE.ConventionID = I.ConventionID
					GROUP BY I.ConventionID
					) G ON G.ConventionID = C.ConventionID
				LEFT JOIN ( -- Solde SCEE et SCEE+ à rembourser
					SELECT
						I.ConventionID,
						
						-- Solde de la SCEE et SCEE+ à rembourser
						fCESG = SUM(C4.fCESG),
						-- FT
						fACESGPart = SUM(C4.fACESGPart),
						
						fCLB = SUM(C4.fCLB), -- Solde de BEC à rembourser
						fCotisationGranted = SUM(C4.fCotisationGranted) -- Solde des cotisations subventionnées
					FROM @tConvTrans21_3 I
					JOIN Un_CESP400 C4 ON C4.ConventionID = I.ConventionID
					WHERE C4.iCESPSendFileID IS NULL
					GROUP BY I.ConventionID
					) C4 ON C4.ConventionID = C.ConventionID
				WHERE ISNULL(dbo.FN_CRQ_DateNoTime(C.dtRegStartDate),Ct.EffectDate+1) <= Ct.EffectDate -- Pas dans un compte bloqué
					AND ISNULL(HB.SocialNumber,'') <> ''
					AND Ct.CotisationID NOT IN (
							-- Cotisation qui ont un enregistrement 400 expédié qui est valide.
							SELECT Ct.CotisationID
							FROM Un_Cotisation Ct
							JOIN Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID
							JOIN (	SELECT C4.CotisationID
									FROM Un_CESP400 C4					
									JOIN @tCESP400ID tC4 ON tC4.iCESP400ID = C4.iCESP400ID) tC4 ON tC4.CotisationID = Ct.CotisationID
							LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
							WHERE G4.iCESP800ID IS NULL -- Pas revenu en erreur
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

			DECLARE @tConvTrans21_4 TABLE (
				ConventionID INTEGER PRIMARY KEY,
				InForceDate DATETIME NOT NULL )

			INSERT INTO @tConvTrans21_4
				SELECT 
					U.ConventionID,
					InForceDate = MIN(U.InForceDate)
				FROM @tCESP400ID tC4
				JOIN Un_CESP400 C4 ON C4.iCESP400ID = tC4.iCESP400ID
				JOIN Un_Cotisation Ct ON C4.CotisationID = Ct.CotisationID
				JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
				GROUP BY U.ConventionID

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
					fACESGPart, -- FT
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

					-- FT
					-- SCEE
					CASE
						-- Rembourse rien 0.00 si le solde de subvention et négatif ou à 0.00
						WHEN ISNULL(G.fCESG + G.fACESG, 0) - ISNULL(C4.fCESG, 0) <= 0 
							THEN 0
						-- Rembourse tout s'il n'y a pas de cotisations subventionnées
						WHEN ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0) = 0 
							THEN ISNULL(G.fCESG + G.fACESG, 0) - ISNULL(C4.fCESG, 0)
						-- Rembourse tout si on retire toutes les cotisations subventionnées
						WHEN ABS(Ct.Cotisation + Ct.Fee) > ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0) 
							THEN ISNULL(G.fCESG + G.fACESG, 0) - ISNULL(C4.fCESG, 0)
						-- Rembourse tout si le proprata selon la formule A/B*C du règlement sur l’épargne-études est plus élevé que le total de la SCEE
						WHEN ROUND((ISNULL(G.fCESG + G.fACESG, 0) - ISNULL(C4.fCESG, 0)) / (ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0)) * ABS(Ct.Cotisation + Ct.Fee), 2) > ISNULL(G.fCESG + G.fACESG, 0) - ISNULL(C4.fCESG, 0) 
							THEN ISNULL(G.fCESG + G.fACESG, 0) - ISNULL(C4.fCESG, 0)
						-- Rembourse au proprata selon la formule A/B*C du règlement sur l’épargne-études si on retire seulement une partie des cotisations subventionnées
						ELSE 
							ROUND((ISNULL(G.fCESG + G.fACESG, 0) - ISNULL(C4.fCESG, 0)) / (ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0)) * ABS(Ct.Cotisation + Ct.Fee), 2)
					END,
					
					-- FT
					-- SCEE+
					CASE
						-- Rembourse rien 0.00 si le solde de subvention et négatif ou à 0.00
						WHEN ISNULL(G.fACESG, 0)-ISNULL(C4.fACESGPart, 0) <= 0 
							THEN 0
						-- Rembourse tout s'il n'y a pas de cotisations subventionnées
						WHEN ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0) = 0 
							THEN ISNULL(G.fACESG, 0) - ISNULL(C4.fACESGPart, 0)
						-- Rembourse tout si on retire toutes les cotisations subventionnées
						WHEN ABS(Ct.Cotisation + Ct.Fee) > ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0) 
							THEN ISNULL(G.fACESG, 0) - ISNULL(C4.fACESGPart, 0)
						-- Rembourse tout si le proprata selon la formule A/B*C du règlement sur l’épargne-études est plus élevé que le total de la SCEE
						WHEN ROUND((ISNULL(G.fACESG, 0)-ISNULL(C4.fACESGPart, 0)) / (ISNULL(G.fCotisationGranted,0) + ISNULL(C4.fCotisationGranted,0)) * ABS(Ct.Cotisation + Ct.Fee), 2) > ISNULL(G.fACESG, 0)-ISNULL(C4.fACESGPart, 0) 
							THEN ISNULL(G.fACESG, 0) - ISNULL(C4.fACESGPart, 0)
						-- Rembourse au proprata selon la formule A/B*C du règlement sur l’épargne-études si on retire seulement une partie des cotisations subventionnées
						ELSE 
							ROUND((ISNULL(G.fACESG, 0) - ISNULL(C4.fACESGPart, 0)) / (ISNULL(G.fCotisationGranted,0) + ISNULL(C4.fCotisationGranted, 0)) * ABS(Ct.Cotisation + Ct.Fee), 2)
					END,

					0,
					0,
					0,
					0,
					0,
					0,
					0,
					0
				FROM @tCESP400ID tC4
				JOIN Un_CESP400 C4A ON C4A.iCESP400ID = tC4.iCESP400ID
				JOIN Un_Cotisation Ct ON C4A.CotisationID = Ct.CotisationID
				JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
				JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				JOIN Un_Plan P ON P.PlanID = C.PlanID
				JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
				JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
				JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
				LEFT JOIN ( -- Solde SCEE et SCEE+ et solde de cotisations subventionnées
					SELECT
						I.ConventionID,

						-- FT
						--fCESG = SUM(CE.fCESG+CE.fACESG), -- Solde de la SCEE et SCEE+
						-- Solde de la SCEE et SCEE+
						fCESG = SUM(CE.fCESG), 
						fACESG = SUM(CE.fACESG), 

						fCotisationGranted = SUM(CE.fCotisationGranted) -- Solde des cotisations subventionnées
					FROM @tConvTrans21_4 I
					JOIN Un_CESP CE ON CE.ConventionID = I.ConventionID
					GROUP BY I.ConventionID
					) G ON G.ConventionID = C.ConventionID
				LEFT JOIN ( -- Solde SCEE et SCEE+ à rembourser
					SELECT
						I.ConventionID,
						
						-- Solde de la SCEE et SCEE+
						fCESG = SUM(C4.fCESG),
						-- FT
						fACESGPart = SUM(C4.fACESGPart),
						
						fCotisationGranted = SUM(C4.fCotisationGranted)
					FROM @tConvTrans21_4 I
					JOIN Un_CESP400 C4 ON C4.ConventionID = I.ConventionID
					WHERE C4.iCESPSendFileID IS NULL
					GROUP BY I.ConventionID
					) C4 ON C4.ConventionID = C.ConventionID
				WHERE ISNULL(dbo.FN_CRQ_DateNoTime(C.dtRegStartDate),Ct.EffectDate+1) <= Ct.EffectDate -- Pas dans un compte bloqué
					AND ISNULL(HB.SocialNumber,'') <> ''
					AND Ct.CotisationID NOT IN (
							-- Cotisation qui ont un enregistrement 400 expédié qui est valide.
							SELECT Ct.CotisationID
							FROM Un_Cotisation Ct
							JOIN Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID
							JOIN (	SELECT C4.CotisationID
									FROM Un_CESP400 C4					
									JOIN @tCESP400ID tC4 ON tC4.iCESP400ID = C4.iCESP400ID) tC4 ON tC4.CotisationID = Ct.CotisationID
							LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
							WHERE G4.iCESP800ID IS NULL -- Pas revenu en erreur
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
			DECLARE @tConvTrans21_9 TABLE (
				ConventionID INTEGER PRIMARY KEY,
				InForceDate DATETIME NOT NULL )

			INSERT INTO @tConvTrans21_9
				SELECT 
					U.ConventionID,
					InForceDate = MIN(U.InForceDate)
				FROM @tCESP400ID tC4
				JOIN Un_CESP400 C4 ON C4.iCESP400ID = tC4.iCESP400ID
				JOIN Un_Cotisation Ct ON C4.CotisationID = Ct.CotisationID
				JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
				GROUP BY U.ConventionID

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
					fACESGPart, -- FT
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

					-- FT
					-- SCEE
					CASE
						-- Rembourse rien 0.00 si le solde de subvention et négatif ou à 0.00
						WHEN ISNULL(G.fCESG + G.fACESG, 0) - ISNULL(C4.fCESG, 0) <= 0 
							THEN 0
						-- Rembourse tout s'il n'y a pas de cotisations subventionnées
						WHEN ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0) = 0 
							THEN ISNULL(G.fCESG + G.fACESG, 0) - ISNULL(C4.fCESG, 0)
						-- Rembourse tout si on retire toutes les cotisations subventionnées
						WHEN ABS(Ct.Cotisation + Ct.Fee) > ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0) 
							THEN ISNULL(G.fCESG + G.fACESG, 0) - ISNULL(C4.fCESG, 0)
						-- Rembourse tout si le proprata selon la formule A/B*C du règlement sur l’épargne-études est plus élevé que le total de la SCEE
						WHEN ROUND((ISNULL(G.fCESG + G.fACESG, 0) - ISNULL(C4.fCESG, 0)) / (ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0)) * ABS(Ct.Cotisation + Ct.Fee), 2) > ISNULL(G.fCESG + G.fACESG, 0) - ISNULL(C4.fCESG, 0) 
							THEN ISNULL(G.fCESG + G.fACESG, 0) - ISNULL(C4.fCESG, 0)
						-- Rembourse au proprata selon la formule A/B*C du règlement sur l’épargne-études si on retire seulement une partie des cotisations subventionnées
						ELSE 
							ROUND((ISNULL(G.fCESG + G.fACESG, 0) - ISNULL(C4.fCESG, 0)) / (ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0)) * ABS(Ct.Cotisation+Ct.Fee), 2)
					END,

					-- FT
					-- SCEE+
					CASE
						-- Rembourse rien 0.00 si le solde de subvention et négatif ou à 0.00
						WHEN ISNULL(G.fACESG, 0) - ISNULL(C4.fACESGPart, 0) <= 0 
							THEN 0
						-- Rembourse tout s'il n'y a pas de cotisations subventionnées
						WHEN ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0) = 0 
							THEN ISNULL(G.fACESG, 0) - ISNULL(C4.fACESGPart, 0)
						-- Rembourse tout si on retire toutes les cotisations subventionnées
						WHEN ABS(Ct.Cotisation + Ct.Fee) > ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0) 
							THEN ISNULL(G.fACESG, 0) - ISNULL(C4.fACESGPart, 0)
						-- Rembourse tout si le proprata selon la formule A/B*C du règlement sur l’épargne-études est plus élevé que le total de la SCEE
						WHEN ROUND((ISNULL(G.fACESG, 0) - ISNULL(C4.fACESGPart, 0)) / (ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0)) * ABS(Ct.Cotisation + Ct.Fee), 2) > ISNULL(G.fACESG, 0) - ISNULL(C4.fACESGPart, 0) 
							THEN ISNULL(G.fACESG, 0) - ISNULL(C4.fACESGPart, 0)
						-- Rembourse au proprata selon la formule A/B*C du règlement sur l’épargne-études si on retire seulement une partie des cotisations subventionnées
						ELSE 
							ROUND((ISNULL(G.fACESG, 0) - ISNULL(C4.fACESGPart, 0)) / (ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0)) * ABS(Ct.Cotisation + Ct.Fee), 2)
					END,

					0,
					0,
					0,
					0,
					0,
					0,
					0,
					-- FT
					-- Cotisation
					CASE
						-- Le montant de cotisations subventionnées ne varie pas car on ne rembourse pas de subvention car il n'y en a pas.
						WHEN ISNULL(G.fCESG + G.fACESG, 0) - ISNULL(C4.fCESG, 0) <= 0 
							THEN 0
						-- Le montant de cotisations subventionnées de la convention est déjà 0.00
						WHEN ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0) = 0 
							THEN 0
						-- On retire toutes les cotisations subventionnées
						WHEN ABS(Ct.Cotisation + Ct.Fee) > ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0) 
							THEN -(ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0))
						-- On retire toutes les cotisations subventionnées
						WHEN ROUND((ISNULL(G.fCESG + G.fACESG, 0) - ISNULL(C4.fCESG, 0)) / (ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0)) * ABS(Ct.Cotisation+Ct.Fee), 2) > ISNULL(G.fCESG + G.fACESG, 0)-ISNULL(C4.fCESG, 0) THEN -(ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0))
						-- On rembourse une partie des cotisations subventionnées
						ELSE 
							Ct.Cotisation + Ct.Fee
					END
				FROM @tCESP400ID tC4
				JOIN Un_CESP400 C4A ON C4A.iCESP400ID = tC4.iCESP400ID
				JOIN Un_Cotisation Ct ON C4A.CotisationID = Ct.CotisationID
				JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
				JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				JOIN Un_Plan P ON P.PlanID = C.PlanID
				JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
				JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
				JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
				LEFT JOIN ( -- Solde SCEE et SCEE+ et solde de cotisations subventionnées
					SELECT
						I.ConventionID,

						-- FT
						--fCESG = SUM(CE.fCESG+CE.fACESG), -- Solde de la SCEE et SCEE+
						-- Solde de la SCEE et SCEE+
						fCESG = SUM(CE.fCESG), 
						fACESG = SUM(CE.fACESG), 

						fCotisationGranted = SUM(CE.fCotisationGranted) -- Solde des cotisations subventionnées
					FROM @tConvTrans21_9 I
					JOIN Un_CESP CE ON CE.ConventionID = I.ConventionID
					GROUP BY I.ConventionID
					) G ON G.ConventionID = C.ConventionID
				LEFT JOIN ( -- Solde SCEE et SCEE+ à rembourser
					SELECT
						I.ConventionID,

						-- Solde de la SCEE et SCEE+
						fCESG = SUM(C4.fCESG), 
						-- FT
						fACESGPart = SUM(C4.fACESGPart), 

						fCotisationGranted = SUM(C4.fCotisationGranted)
					FROM @tConvTrans21_9 I
					JOIN Un_CESP400 C4 ON C4.ConventionID = I.ConventionID
					WHERE C4.iCESPSendFileID IS NULL
					GROUP BY I.ConventionID
					) C4 ON C4.ConventionID = C.ConventionID
				WHERE ISNULL(dbo.FN_CRQ_DateNoTime(C.dtRegStartDate),Ct.EffectDate+1) <= Ct.EffectDate -- Pas dans un compte bloqué
					AND ISNULL(HB.SocialNumber,'') <> ''
					AND Ct.CotisationID NOT IN (
							-- Cotisation qui ont un enregistrement 400 expédié qui est valide.
							SELECT Ct.CotisationID
							FROM Un_Cotisation Ct
							JOIN Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID
							JOIN (	SELECT C4.CotisationID
									FROM Un_CESP400 C4					
									JOIN @tCESP400ID tC4 ON tC4.iCESP400ID = C4.iCESP400ID) tC4 ON tC4.CotisationID = Ct.CotisationID
							LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
							WHERE G4.iCESP800ID IS NULL -- Pas revenu en erreur
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
			DECLARE @tConvTrans21_10 TABLE (
				ConventionID INTEGER PRIMARY KEY,
				InForceDate DATETIME NOT NULL )

			INSERT INTO @tConvTrans21_10
				SELECT 
					U.ConventionID,
					InForceDate = MIN(U.InForceDate)
				FROM @tCESP400ID tC4
				JOIN Un_CESP400 C4 ON C4.iCESP400ID = tC4.iCESP400ID
				JOIN Un_Cotisation Ct ON C4.CotisationID = Ct.CotisationID
				JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
				GROUP BY U.ConventionID

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
					fACESGPart, -- FT
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
					0, -- FT
					0,
					0,
					0,
					0,
					0,
					0,
					0,
					Ct.Cotisation+Ct.Fee
				FROM @tCESP400ID tC4
				JOIN Un_CESP400 C4A ON C4A.iCESP400ID = tC4.iCESP400ID
				JOIN Un_Cotisation Ct ON C4A.CotisationID = Ct.CotisationID
				JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
				JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				JOIN Un_Plan P ON P.PlanID = C.PlanID
				JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
				JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
				JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
				LEFT JOIN ( -- Solde SCEE et SCEE+ et solde de cotisations subventionnées
					SELECT
						I.ConventionID,

						-- FT
						--fCESG = SUM(CE.fCESG+CE.fACESG), -- Solde de la SCEE et SCEE+
						-- Solde de la SCEE et SCEE+
						fCESG = SUM(CE.fCESG), 
						fACESG = SUM(CE.fACESG), 

						fCotisationGranted = SUM(CE.fCotisationGranted) -- Solde des cotisations subventionnées
					FROM @tConvTrans21_10 I
					JOIN Un_CESP CE ON CE.ConventionID = I.ConventionID
					GROUP BY I.ConventionID
					) G ON G.ConventionID = C.ConventionID
				LEFT JOIN ( -- Solde SCEE et SCEE+ à rembourser
					SELECT
						I.ConventionID,

						-- Solde de la SCEE et SCEE+
						fCESG = SUM(C4.fCESG), 
						-- FT
						fACESGPart = SUM(C4.fACESGPart), 

						fCotisationGranted = SUM(C4.fCotisationGranted)
					FROM @tConvTrans21_10 I
					JOIN Un_CESP400 C4 ON C4.ConventionID = I.ConventionID
					WHERE C4.iCESPSendFileID IS NULL
					GROUP BY I.ConventionID
					) C4 ON C4.ConventionID = C.ConventionID
				WHERE ISNULL(dbo.FN_CRQ_DateNoTime(C.dtRegStartDate),Ct.EffectDate+1) <= Ct.EffectDate -- Pas dans un compte bloqué
					AND ISNULL(HB.SocialNumber,'') <> ''
					AND Ct.CotisationID NOT IN (
							-- Cotisation qui ont un enregistrement 400 expédié qui est valide.
							SELECT Ct.CotisationID
							FROM Un_Cotisation Ct
							JOIN Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID
							JOIN (	SELECT C4.CotisationID
									FROM Un_CESP400 C4					
									JOIN @tCESP400ID tC4 ON tC4.iCESP400ID = C4.iCESP400ID) tC4 ON tC4.CotisationID = Ct.CotisationID
							LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
							WHERE G4.iCESP800ID IS NULL -- Pas revenu en erreur
								AND G4.iReversedCESP400ID IS NULL -- Pas une annulation
								AND R4.iCESP400ID IS NULL -- Pas annulé
							)
		END
		-------------
		-- Type 23 --
		-------------
		ELSE IF @tiCESP400TypeID = 23
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
					fACESGPart, -- FT
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
					CE.fACESG, -- FT

					0,
					0,
					0,
					EP.ExternalPlanGovernmentRegNo,
					T.vcOtherConventionNo,
					CE.fCLB,
					0,
					0,
					0
				FROM @tCESP400ID tC4
				JOIN Un_CESP400 C4A ON C4A.iCESP400ID = tC4.iCESP400ID
				JOIN Un_Cotisation Ct ON C4A.CotisationID = Ct.CotisationID
				JOIN Un_OUT T ON T.OperID = Ct.OperID
				JOIN Un_ExternalPlan EP ON EP.ExternalPlanID = T.ExternalPlanID
				JOIN Un_CESP900 C9 ON C9.iCESP400ID = tC4.iCESP400ID
				JOIN Un_CESP CE ON CE.iCESPID = C9.iCESPID				
				JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
				JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				JOIN Un_Plan P ON P.PlanID = C.PlanID
				JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
				JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
				JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID			
				WHERE Ct.CotisationID NOT IN (
							-- Cotisation qui ont un enregistrement 400 expédié qui est valide.
							SELECT Ct.CotisationID
							FROM Un_Cotisation Ct
							JOIN Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID
							JOIN (	SELECT C4.CotisationID
									FROM Un_CESP400 C4					
									JOIN @tCESP400ID tC4 ON tC4.iCESP400ID = C4.iCESP400ID) tC4 ON tC4.CotisationID = Ct.CotisationID
							LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
							WHERE G4.iCESP800ID IS NULL -- Pas revenu en erreur
								AND G4.iReversedCESP400ID IS NULL -- Pas une annulation
								AND R4.iCESP400ID IS NULL -- Pas annulé
								AND G4.tiCESP400TypeID = 23 -- DU meme type
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
					fACESGPart, -- FT
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
					0, -- FT
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
				FROM @tCESP400ID tC4
				JOIN Un_CESP400 C4A ON C4A.iCESP400ID = tC4.iCESP400ID
				JOIN Un_Cotisation Ct ON C4A.CotisationID = Ct.CotisationID
				JOIN Un_Oper O ON O.OperID = Ct.OperID
				JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
				JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				JOIN Un_Plan P ON P.PlanID = C.PlanID
				JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
				JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
				JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID			
				WHERE ISNULL(HB.SocialNumber,'') <> ''
					AND Ct.CotisationID NOT IN (
							-- Cotisation qui ont un enregistrement 400 expédié qui est valide.
							SELECT Ct.CotisationID
							FROM Un_Cotisation Ct
							JOIN Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID
							JOIN (	SELECT C4.CotisationID
									FROM Un_CESP400 C4					
									JOIN @tCESP400ID tC4 ON tC4.iCESP400ID = C4.iCESP400ID) tC4 ON tC4.CotisationID = Ct.CotisationID
							LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
							WHERE G4.iCESP800ID IS NULL -- Pas revenu en erreur
								AND G4.iReversedCESP400ID IS NULL -- Pas une annulation
								AND R4.iCESP400ID IS NULL -- Pas annulé
								AND G4.tiCESP400TypeID = 24 -- DU meme type
							)	
					AND C4A.bCESPDemand = C.bCLBRequested -- 2010-06-29 Pierre Paquet.  Afin de ne pas envoyer l'inverse de la convention.			
		END	
	END

	--S'il y a des 400 d'annulation
	IF EXISTS (
				SELECT *
				FROM #tCESP400IDReversed)
	BEGIN
		--Annulation du 400 originale
		INSERT INTO Un_CESP400 (
				OperID,
				CotisationID,
				ConventionID,
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
				vcPGProv,
				fCotisationGranted )
		SELECT	
			G4.OperID,
			G4.CotisationID,
			G4.ConventionID,
			G4.iCESP400ID,
			G4.tiCESP400TypeID,
			G4.tiCESP400WithdrawReasonID,
			'FIN',
			G4.dtTransaction,
			G4.iPlanGovRegNumber,
			G4.ConventionNo,
			G4.vcSubscriberSINorEN,
			G4.vcBeneficiarySIN,
			-G4.fCotisation,
			G4.bCESPDemand,
			G4.dtStudyStart,
			G4.tiStudyYearWeek,

			CASE 
				WHEN G4.tiCESP400TypeID = 11 THEN -ISNULL(SUM(C9.fCESG + C9.fACESG),0)
			ELSE -G4.fCESG
			END,

			-- FT
			CASE 
				WHEN G4.tiCESP400TypeID = 11 THEN -ISNULL(SUM(C9.fACESG),0)
			ELSE -G4.fACESGPart
			END,

			-G4.fEAPCESG,
			-G4.fEAP,
			-G4.fPSECotisation,
			G4.iOtherPlanGovRegNumber,
			G4.vcOtherConventionNo,
			G4.tiProgramLength,
			G4.cCollegeTypeID,
			G4.vcCollegeCode,
			G4.siProgramYear,
			G4.vcPCGSINorEN,
			G4.vcPCGFirstName,
			G4.vcPCGLastName,
			G4.tiPCGType,
			CASE 
				WHEN G4.tiCESP400TypeID = 24 THEN -ISNULL(SUM(C9.fCLB),0)
			ELSE -G4.fCLB
			END,
			-G4.fEAPCLB,
			-G4.fPG,
			-G4.fEAPPG,
			G4.vcPGProv,
			-SUM(ISNULL(C9.fCotisationGranted,0))
		FROM #tCESP400IDReversed
		JOIN Un_CESP400 C4 ON C4.iCESP400ID = #tCESP400IDReversed.iCESP400ID
		JOIN Un_CESP400 G4 ON G4.iCESP400ID = C4.iReversedCESP400ID
		LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = G4.iCESP400ID
		GROUP BY
			G4.OperID,
			G4.CotisationID,
			G4.ConventionID,
			G4.iCESP400ID,
			G4.tiCESP400TypeID,
			G4.tiCESP400WithdrawReasonID,
			G4.dtTransaction,
			G4.iPlanGovRegNumber,
			G4.ConventionNo,
			G4.vcSubscriberSINorEN,
			G4.vcBeneficiarySIN,
			G4.fCotisation,
			G4.bCESPDemand,
			G4.dtStudyStart,
			G4.tiStudyYearWeek,
			G4.fCESG,
			G4.fACESGPart,
			G4.fEAPCESG,
			G4.fEAP,
			G4.fPSECotisation,
			G4.iOtherPlanGovRegNumber,
			G4.vcOtherConventionNo,
			G4.tiProgramLength,
			G4.cCollegeTypeID,
			G4.vcCollegeCode,
			G4.siProgramYear,
			G4.vcPCGSINorEN,
			G4.vcPCGFirstName,
			G4.vcPCGLastName,
			G4.tiPCGType,
			G4.fCLB,
			G4.fEAPCLB,
			G4.fPG,
			G4.fEAPPG,
			G4.vcPGProv
	END
	
	IF @@ERROR <> 0 
		SET @iReturn = -1

	IF @iReturn > 0
	BEGIN
		-- Inscrit le vcTransID avec le ID FIN + <iCESP400ID>.
		UPDATE Un_CESP400
		SET vcTransID = 'FIN'+CAST(iCESP400ID AS VARCHAR(12))
		WHERE vcTransID = 'FIN'
			AND iCESP400ID > @iCESP400ID 

		IF @@ERROR <> 0
			SET @iReturn = -2
	END

	RETURN @iReturn
END


