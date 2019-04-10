
/********************************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_CESP400ForOper
Description         :	Procédure qui crée un enregistrement 400 pour une opération
Valeurs de retours  :	@ReturnValue :
									> 0 : Réussite
									<= 0 : Erreurs.
Note                :	ADX0000847	IA	2006-03-16	Bruno Lapointe			Création
						ADX0000992	IA	2006-05-23	Alain Quirion			Gestion du type 23 (OUT)
						ADX0002063	BR	2006-08-15	Bruno Lapointe			Optimisation.
						ADX0002065	BR	2006-08-18	Bruno Lapointe			Gestion du champ Un_CESP400.fCotisationGranted
						ADX0001235	IA	2007-02-14	Alain Quirion			Utilisation de dtRegStartDate pour la date de début de régime
						ADX0002426	BR	2007-05-23	Bruno Lapointe			Gestion de la table Un_CESP.
						ADX0002502	BR	2007-06-27	Bruno Lapointe			NAS absent mal géré pour les conventions entrées en vigueur avant le 1 janvier 2003
										2008-06-11  Jean-Francois Arial		Ajouter les types 230 et 190
										2009-10-29	Jean-François Gauthier	Ajout du paramètre @iTypeRemboursement
										2009-11-11	Jean-François Gauthier	Ajout des types 21-4 BEC, 21-5 (BEC et autre), 21-9 BEC, 21-11 (BEC et autre)
										2009-11-16	Jean-François Gauthier	Ajout de la désactivation du BEC suite à un remboursement 400-21-1 ou 400-21-3
										2010-01-28	Pierre Paquet			Ajout de la section 21-5 pour le changement bénéficiaire
										2010-02-17  Pierre Paquet			Ajustement de la section pour le 21-11 (BEC Autre)
										2010-03-22	Jean-François Gauthier	Ajout des raisons dans l'outil "Assistant-retrait"	
																				01 - Retrait de cotisation
																				03 - Résiliation de contrat
																				04 - Transfert non admissible
																				05 - Remplacement d'un bénéfici
																				07 - Révocation
																				08 - Ne satisfait plus à la condition de frère ou soeur seulement
																				09 - Décès
																				10 - Retrait des cotisation excédentaires
																				11 - Autre
										2010-04-19	Pierre Paquet			Correction problème 400-21-9 (était codé 5).
										2010-04-28	Pierre Paquet			Ajout du CROSS APPLY dans 400-21-5
										2010-05-17	Pierre Paquet			Cas 21-5-3 - Valider avec la date de décès du bénéficiaire s'il y a lieu.
										2010-05-18	Pierre Paquet			Correction: Utilisation de EffectDate plutôt OperDate pour le calcul de 400-21-5.
										2010-05-26	Pierre Paquet			Correction: La gestion du BEC est remplacé par une erreur dans VL_UN_OperRES.
										2011-01-14	Frédérick Thibault		Correction: Remplacé iID_Nouveau_Beneficiaire par iID_Ancien_Beneficiaire pour les 400-21-5.
										2011-01-31	Frederick Thibault		Ajout du champ fACESGPart pour régler le problème SCEE+
										2011-04-06	Donald Huppé			GLPI 5323 DHuppé(2011-04-06) (voir dans le code) : au lieu de prendre la date de la veille, on prend la date du lendemain pour être certain d'avoir le dernier changement de bénéficiaire
										2014-05-08	Donald Huppé			Pour la refonte, dans le type 14 et 21, mettre un distinct pour ne pas duppliquer les 400
										2014-08-15	Donald Huppé			glpi 12174 : Pour la 21-3, modification du "not in" pour ne pas empecher la création à partir d'un type 24
										2016-04-13	Pierre-Luc Simard	    Séparer la création des 421-3 des opérations FRM et des autres types d'opérations 
                                        2017-05-12  Pierre-Luc Simard       Permettre la création d'une 400-19 sans cotisation (TIN)
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_CESP400ForOper]
					(
						@ConnectID					INT,		-- ID Unique de connexion de l'usager
						@OperID						INT,		-- ID de l'opération
						@tiCESP400TypeID			SMALLINT,	-- Type d'enregistrement à créer
						@tiCESP400WithdrawReasonID	TINYINT, 
						@iTypeRemboursement			INT = 1		-- Type de remboursement 1 = SCEE et 2 = BEC et 3 = Changement bénéficiaire.	
					) 
AS
BEGIN
	DECLARE
		@CotisationID			INT,
		@bRIO_QuiAnnule			BIT,
		@iOperID				INT,
		@iOperSourceID			INT,
		@iID_Convention			INT,
		@iID_ConventionSuggere	INT,
		@iID_Beneficiaire		INT,
		@mCLB					MONEY,
		@bBECPresent			BIT,
		@iIDConventionSuggere	INT,
		@iRetour				INT

	DECLARE @tConvention	TABLE
					(			
					iID_Convention			INT
					,iID_Souscripteur		INT
					,iID_Beneficiaire		INT
					,vcConventionNO			VARCHAR(75)
					,cID_PlanType			CHAR(3)
					,vcPlanDesc				VARCHAR(75)
					,bPresenceBec			BIT
					,dtDateEntreeVigueur	DATETIME
					)
		
	-------------
	-- Type 11 --
	-------------
	IF @tiCESP400TypeID = 11 AND @OperID > 0
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
			WHERE Ct.OperID = @OperID
				AND dbo.FN_CRQ_DateNoTime(ISNULL(C.dtRegStartDate,Ct.EffectDate+1)) <= Ct.EffectDate -- Pas dans un compte bloqué
				AND ISNULL(HB.SocialNumber,'') <> ''
				AND Ct.CotisationID NOT IN (
						-- Cotisation qui ont un enregistrement 400 expédié qui est valide.
						SELECT Ct.CotisationID
						FROM Un_Cotisation Ct
						JOIN Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID
						LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
						WHERE Ct.OperID = @OperID
							AND G4.iCESP800ID IS NULL -- Pas revenu en erreur
							AND G4.iReversedCESP400ID IS NULL -- Pas une annulation
							AND R4.iCESP400ID IS NULL -- Pas annulé
						)
	END
	-------------
	-- Type -1 --
	-------------
	ELSE IF @tiCESP400TypeID = -1 AND @OperID > 0
	BEGIN
		DECLARE @tConvTransMin1 TABLE (
			ConventionID INTEGER PRIMARY KEY)

		INSERT INTO @tConvTransMin1
			SELECT 
				U.ConventionID
			FROM Un_Cotisation Ct
			JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			WHERE Ct.OperID = @OperID
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
				fEAPPG,
				fCotisationGranted )
			SELECT
				Ct.OperID,
				Ct.CotisationID,
				C.ConventionID,
				CASE
					WHEN Ct.Cotisation+Ct.Fee > 0 THEN 11
				ELSE 21
				END,
				CASE
					WHEN Ct.Cotisation+Ct.Fee > 0 THEN NULL
				ELSE 1
				END,
				'FIN',
				Ct.EffectDate,
				P.PlanGovernmentRegNo,
				C.ConventionNo,
				ISNULL(HS.SocialNumber,''),
				HB.SocialNumber,
				CASE
					WHEN Ct.Cotisation+Ct.Fee > 0 THEN Ct.Cotisation+Ct.Fee
				ELSE 0
				END,
				C.bCESGRequested,

				-- SCEE
				CASE
					-- Rembourse rien puisqu'il s'agit d'une demande
					WHEN Ct.Cotisation + Ct.Fee > 0 
						THEN 0
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
					WHEN ROUND((ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0)) / (ISNULL(G.fCotisationGranted, 0)+ ISNULL(C4.fCotisationGranted, 0)) * ABS(Ct.Cotisation + Ct.Fee), 2) > ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0) 
						THEN -(ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0))
					-- Rembourse au proprata selon la formule A/B*C du règlement sur l’épargne-études si on retire seulement une partie des cotisations subventionnées
					ELSE 
						-(ROUND((ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0)) / (ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0)) * ABS(Ct.Cotisation + Ct.Fee), 2))
				END,

				-- SCEE+
				CASE
					-- Rembourse rien puisqu'il s'agit d'une demande
					WHEN Ct.Cotisation + Ct.Fee > 0 
						THEN 0
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
						-(ROUND((ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0)) / (ISNULL(G.fCotisationGranted,0) + ISNULL(C4.fCotisationGranted, 0)) * ABS(Ct.Cotisation + Ct.Fee), 2))
				END,
				
				0,
				0,
				0,
				CASE 
					WHEN Ct.Cotisation+Ct.Fee <= 0 THEN NULL
					WHEN C.bACESGRequested = 0 THEN NULL
				ELSE B.vcPCGSINOrEN
				END,
				CASE 
					WHEN Ct.Cotisation+Ct.Fee <= 0 THEN NULL
					WHEN C.bACESGRequested = 0 THEN NULL
				ELSE B.vcPCGFirstName
				END,
				CASE 
					WHEN Ct.Cotisation+Ct.Fee <= 0 THEN NULL
					WHEN C.bACESGRequested = 0 THEN NULL
				ELSE B.vcPCGLastName
				END,
				CASE 
					WHEN Ct.Cotisation+Ct.Fee <= 0 THEN NULL
					WHEN C.bACESGRequested = 0 THEN NULL
				ELSE B.tiPCGType
				END,
				0,
				0,
				0,
				0,
				-- Cotisation
				CASE
					-- Le champs reste à 0 puisqu'il s'agit d'une demande
					WHEN Ct.Cotisation + Ct.Fee > 0 
						THEN 0
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
					I.ConventionID,
					
					-- Solde de la SCEE et SCEE+
					fCESG = SUM(G.fCESG), 
					fACESG = SUM(G.fACESG), 
					
					fCotisationGranted = SUM(G.fCotisationGranted) -- Solde des cotisations subventionnées
				FROM @tConvTransMin1 I
				JOIN Un_CESP G ON G.ConventionID = I.ConventionID
				GROUP BY I.ConventionID
				) G ON G.ConventionID = C.ConventionID
			LEFT JOIN ( -- Solde SCEE et SCEE+ à rembourser
				SELECT
					I.ConventionID,
					
					-- Solde de la SCEE et SCEE+
					fCESG = SUM(C4.fCESG), 
					fACESGPart = SUM(C4.fACESGPart), 
					
					fCotisationGranted = SUM(C4.fCotisationGranted)
				FROM @tConvTransMin1 I
				JOIN Un_CESP400 C4 ON C4.ConventionID = I.ConventionID
				LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID
				LEFT JOIN Un_CESP CE ON CE.OperID = C4.OperID
				WHERE C9.iCESP900ID IS NULL
					AND C4.iCESP800ID IS NULL
					AND CE.iCESPID IS NULL
				GROUP BY I.ConventionID
				) C4 ON C4.ConventionID = C.ConventionID
			WHERE Ct.OperID = @OperID
				AND dbo.FN_CRQ_DateNoTime(ISNULL(C.dtRegStartDate,Ct.EffectDate+1)) <= Ct.EffectDate -- Pas dans un compte bloqué
				AND ISNULL(HB.SocialNumber,'') <> ''
				AND Ct.CotisationID NOT IN (
						-- Cotisation qui ont un enregistrement 400 expédié qui est valide.
						SELECT Ct.CotisationID
						FROM Un_Cotisation Ct
						JOIN Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID
						LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
						WHERE Ct.OperID = @OperID
							AND G4.iCESP800ID IS NULL 		-- Pas revenu en erreur
							AND G4.iReversedCESP400ID IS NULL 	-- Pas une annulation
							AND R4.iCESP400ID IS NULL 		-- Pas annulé
						)
	END
	-------------
	-- Type -2 --
	-------------
	ELSE IF @tiCESP400TypeID = -2 AND @OperID > 0
	BEGIN
		DECLARE @tConvTransMin2 TABLE (
			ConventionID INTEGER PRIMARY KEY)

		DECLARE @ProRataCotisation TABLE(
			CotisationID INTEGER PRIMARY KEY,
			CotisationAndFee MONEY NOT NULL)

		DECLARE @SumCotisationFee MONEY,
			@GlobalSumCotisationFee MONEY,
			@DiffSum MONEY

		SELECT
			@SumCotisationFee = SUM(Cotisation + Fee)
		FROM Un_Cotisation
		WHERE OperID = @OperID				

		IF @SumCotisationFee > 0
		BEGIN
			SELECT
				@GlobalSumCotisationFee = SUM(Cotisation + Fee)
			FROM Un_Cotisation
			WHERE OperID = @OperID
				AND (Cotisation+Fee) > 0

			INSERT INTO @ProRataCotisation(CotisationID, CotisationAndFee)
			SELECT
				CotisationID,
				@SumCotisationFee / (@GlobalSumCotisationFee / (Cotisation + Fee))
			FROM Un_Cotisation
			WHERE OperID = @OperID
				AND (Cotisation+Fee) > 0	

			-- Update pour le 1 cent d'écart
			SELECT
				@GlobalSumCotisationFee = SUM(CotisationAndFee)
			FROM @ProRataCotisation

			SET @DiffSum = @SumCotisationFee - @GlobalSumCotisationFee

			-- Le 1 cent est attribure à la cotisation avec le plus grand ID
			UPDATE @ProRataCotisation
			SET CotisationAndFee = CotisationAndFee + @DiffSum
			WHERE CotisationID IN (SELECT MAX(CotisationID) FROM @ProRataCotisation)
			
		END
		ELSE
		BEGIN
			SELECT
				@GlobalSumCotisationFee = SUM(Cotisation + Fee)
			FROM Un_Cotisation
			WHERE OperID = @OperID
				AND (Cotisation+Fee) < 0

			INSERT INTO @ProRataCotisation(CotisationID, CotisationAndFee)
			SELECT
				CotisationID,
				@SumCotisationFee / (@GlobalSumCotisationFee / (Cotisation + Fee))
			FROM Un_Cotisation
			WHERE OperID = @OperID
				AND (Cotisation+Fee) < 0

			-- Update pour le 1 cent d'écart (erreur d'Arrondi du prorata)
			SELECT
				@GlobalSumCotisationFee = SUM(CotisationAndFee)
			FROM @ProRataCotisation

			SET @DiffSum = @SumCotisationFee - @GlobalSumCotisationFee

			-- Le 1 cent est attribure à la cotisation avec le plus grand ID
			UPDATE @ProRataCotisation
			SET CotisationAndFee = CotisationAndFee + @DiffSum
			WHERE CotisationID IN (SELECT MAX(CotisationID) FROM @ProRataCotisation)
		END	

		INSERT INTO @tConvTransMin2
			SELECT 
				U.ConventionID
			FROM Un_Cotisation Ct
			JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			WHERE Ct.OperID = @OperID
			GROUP BY U.ConventionID

		IF @SumCotisationFee <> 0
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
					vcPCGSINorEN,
					vcPCGFirstName,
					vcPCGLastName,
					tiPCGType,
					fCLB,
					fEAPCLB,
					fPG,
					fEAPPG,
					fCotisationGranted )
				SELECT
					Ct.OperID,
					Ct.CotisationID,
					C.ConventionID,
					CASE
						WHEN PRC.CotisationAndFee > 0 THEN 11
					ELSE 21
					END,
					CASE
						WHEN PRC.CotisationAndFee > 0 THEN NULL
					ELSE 1
					END,
					'FIN',
					Ct.EffectDate,
					P.PlanGovernmentRegNo,
					C.ConventionNo,
					ISNULL(HS.SocialNumber,''),
					HB.SocialNumber,
					CASE
						WHEN PRC.CotisationAndFee > 0 THEN PRC.CotisationAndFee
					ELSE 0
					END,
					C.bCESGRequested,

					-- SCEE
					CASE
						-- Rembourse rien puisqu'il s'agit d'une demande
						WHEN PRC.CotisationAndFee > 0 
							THEN 0
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
						WHEN ROUND((ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0)) / (ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0)) * ABS(PRC.CotisationAndFee), 2) > ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0) 
							THEN -(ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0))
						-- Rembourse au proprata selon la formule A/B*C du règlement sur l’épargne-études si on retire seulement une partie des cotisations subventionnées
						ELSE 
							-(ROUND((ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0)) / (ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0)) * ABS(Ct.Cotisation + Ct.Fee), 2))
					END,

					-- SCEE+
					CASE
						-- Rembourse rien puisqu'il s'agit d'une demande
						WHEN PRC.CotisationAndFee > 0 
							THEN 0
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
						WHEN ROUND((ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0)) / (ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0)) * ABS(PRC.CotisationAndFee), 2) > ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0) 
							THEN -(ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0))
						-- Rembourse au proprata selon la formule A/B*C du règlement sur l’épargne-études si on retire seulement une partie des cotisations subventionnées
						ELSE 
							-(ROUND((ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0)) / (ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0)) * ABS(Ct.Cotisation + Ct.Fee), 2))
					END,

					0,
					0,
					0,
					CASE 
						WHEN PRC.CotisationAndFee <= 0 THEN NULL
						WHEN C.bACESGRequested = 0 THEN NULL
					ELSE B.vcPCGSINOrEN
					END,
					CASE 
						WHEN PRC.CotisationAndFee <= 0 THEN NULL
						WHEN C.bACESGRequested = 0 THEN NULL
					ELSE B.vcPCGFirstName
					END,
					CASE 
						WHEN PRC.CotisationAndFee <= 0 THEN NULL
						WHEN C.bACESGRequested = 0 THEN NULL
					ELSE B.vcPCGLastName
					END,
					CASE 
						WHEN PRC.CotisationAndFee <= 0 THEN NULL
						WHEN C.bACESGRequested = 0 THEN NULL
					ELSE B.tiPCGType
					END,
					0,
					0,
					0,
					0,
					
					CASE
						-- Le champs reste à 0 puisqu'il s'agit d'une demande
						WHEN PRC.CotisationAndFee > 0 
							THEN 0
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
						WHEN ROUND((ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0)) / (ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0)) * ABS(PRC.CotisationAndFee), 2) > ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0) 
							THEN -(ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0))
						-- On rembourse une partie des cotisations subventionnées
						ELSE 
							PRC.CotisationAndFee
					END

				FROM Un_Cotisation Ct
				JOIN @ProRataCotisation PRC ON PRC.CotisationID = Ct.CotisationID
				JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
				JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				JOIN Un_Plan P ON P.PlanID = C.PlanID
				JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
				JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
				JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
				LEFT JOIN ( -- Solde SCEE et SCEE+ et solde de cotisations subventionnées
					SELECT
						I.ConventionID,
						
						-- Solde de la SCEE et SCEE+
						fCESG = SUM(G.fCESG), 
						fACESG = SUM(G.fACESG), 
						
						fCotisationGranted = SUM(G.fCotisationGranted) -- Solde des cotisations subventionnées
					FROM @tConvTransMin2 I
					JOIN Un_CESP G ON G.ConventionID = I.ConventionID
					GROUP BY I.ConventionID
					) G ON G.ConventionID = C.ConventionID
				LEFT JOIN ( -- Solde SCEE et SCEE+ à rembourser
					SELECT
						I.ConventionID,
						
						-- Solde de la SCEE et SCEE+
						fCESG = SUM(C4.fCESG), 
						fACESGPart = SUM(C4.fACESGPart), 
						
						fCotisationGranted = SUM(C4.fCotisationGranted)
					FROM @tConvTransMin2 I
					JOIN Un_CESP400 C4 ON C4.ConventionID = I.ConventionID
					LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID
					LEFT JOIN Un_CESP CE ON CE.OperID = C4.OperID
					WHERE C9.iCESP900ID IS NULL
						AND C4.iCESP800ID IS NULL
						AND CE.iCESPID IS NULL
					GROUP BY I.ConventionID
					) C4 ON C4.ConventionID = C.ConventionID
				WHERE Ct.OperID = @OperID
					AND dbo.FN_CRQ_DateNoTime(ISNULL(C.dtRegStartDate,Ct.EffectDate+1)) <= Ct.EffectDate -- Pas dans un compte bloqué
					AND ISNULL(HB.SocialNumber,'') <> ''
					AND Ct.CotisationID NOT IN (
							-- Cotisation qui ont un enregistrement 400 expédié qui est valide.
							SELECT Ct.CotisationID
							FROM Un_Cotisation Ct
							JOIN Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID
							LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
							WHERE Ct.OperID = @OperID
								AND G4.iCESP800ID IS NULL 		-- Pas revenu en erreur
								AND G4.iReversedCESP400ID IS NULL 	-- Pas une annulation
								AND R4.iCESP400ID IS NULL 		-- Pas annulé
							)

	END
	-------------
	-- Type 13 --
	-------------
	ELSE IF @tiCESP400TypeID = 13
			AND @OperID > 0
	BEGIN
		INSERT INTO Un_CESP400 (
				OperID,
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
				fEAPPG )
			SELECT
				O.OperID,
				C.ConventionID,
				13,
				'FIN',
				O.OperDate,
				P.PlanGovernmentRegNo,
				C.ConventionNo,
				ISNULL(HS.SocialNumber,''),
				HB.SocialNumber,
				0,
				C.bCESGRequested,
				SP.StudyStart,		--dtStudyStart
				CASE CL.CollegeTypeID	--tiStudyYearWeek
					WHEN '01' THEN 30
				ELSE 34 
				END,			
				0,
				0,
				CE.fCESG + CE.fACESG,
				CE.fCLB + CE.fCESG + CE.fACESG + CG.sumOper,		---fEAP
				0,
				SP.ProgramLength,	--tiProgramLength
				CL.CollegeTypeID,		--cCollegeTypeID
				CL.CollegeCode,		--vcCollegeCode
				SP.ProgramYear,		--siProgramYear
				0,
				CE.fCLB,		
				0,
				0	
			FROM Un_ScholarshipPmt SP
			JOIN Un_Scholarship S ON S.ScholarshipID = SP.ScholarshipID
			JOIN Un_Oper O ON O.OperID = SP.OperID
			JOIN Un_College CL ON CL.CollegeID = SP.CollegeID
			JOIN Un_CESP CE ON CE.OperID = O.OperID
			JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID			
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
			JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
			JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
			JOIN (
				SELECT 
					ConventionID,
					sumOper = ISNULL(SUM(ConventionOperAmount),0)					
				FROM Un_ConventionOper 
				WHERE OperID = @OperID
				GROUP BY ConventionID
				) CG ON CG.ConventionID = C.ConventionID
			WHERE O.OperID = @OperID
				AND dbo.FN_CRQ_DateNoTime(ISNULL(C.dtRegStartDate,O.OperDate+1)) <= O.OperDate -- Pas dans un compte bloqué
				AND ISNULL(HB.SocialNumber,'') <> ''
				AND O.OperID NOT IN (
						-- Opération qui ont un enregistrement 400 expédié qui est valide.
						SELECT C4.OperID
						FROM Un_CESP400 C4
						LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = C4.iCESP400ID
						WHERE C4.OperID = @OperID
							AND C4.iCESP800ID IS NULL 		-- Pas revenu en erreur
							AND C4.iReversedCESP400ID IS NULL 	-- Pas une annulation
							AND R4.iCESP400ID IS NULL 		-- Pas annulé
						)
	END

	-------------
	-- Type 14 --
	-------------
	ELSE IF @tiCESP400TypeID = 14
			AND @OperID > 0
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
			SELECT DISTINCT
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
			WHERE Ct.OperID = @OperID
				AND dbo.FN_CRQ_DateNoTime(ISNULL(C.dtRegStartDate,Ct.EffectDate+1)) <= Ct.EffectDate -- Pas dans un compte bloqué
				AND ISNULL(HB.SocialNumber,'') <> ''
				AND Ct.CotisationID NOT IN (
						-- Cotisation qui ont un enregistrement 400 expédié qui est valide.
						SELECT Ct.CotisationID
						FROM Un_Cotisation Ct
						JOIN Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID
						LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
						WHERE Ct.OperID = @OperID
							AND G4.iCESP800ID IS NULL -- Pas revenu en erreur
							AND G4.iReversedCESP400ID IS NULL -- Pas une annulation
							AND R4.iCESP400ID IS NULL -- Pas annulé
						)
	END
	-------------
	-- Type 19 --
	-------------
	ELSE IF @tiCESP400TypeID = 19 AND @OperID > 0
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
				iOtherPlanGovRegNumber,
				vcOtherConventionNo,
				fCLB,
				fEAPCLB,
				fPG,
				fEAPPG )
			SELECT 
				T.OperID,
				Ct.CotisationID,
				C.ConventionID,
				19,
				'FIN',
				ISNULL(Ct.EffectDate, O.OperDate),
				P.PlanGovernmentRegNo,
				C.ConventionNo,
				ISNULL(HS.SocialNumber,''),
				HB.SocialNumber,
				ISNULL(Ct.Cotisation, 0) + ISNULL(Ct.Fee, 0),
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
            JOIN Un_Oper O ON O.OperID = T.OperID
			LEFT JOIN (
				SELECT
					OperID, 
					CotisationID = MIN(CotisationID),
					EffectDate = MAX(EffectDate),
					Cotisation = SUM(Cotisation),
					Fee = SUM(Fee)
				FROM Un_Cotisation
				WHERE OperID = @OperID
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
						WHERE C4.OperID = @OperID
							AND C4.iCESP800ID IS NULL 		-- Pas revenu en erreur
							AND C9.iCESP900ID IS NULL
							AND C4.iReversedCESP400ID IS NULL 	-- Pas une annulation
							AND R4.iCESP400ID IS NULL 		-- Pas annulé
						)
	END

	-------------
	-- Type 190 -- 19 pour transfert RIO
	-------------
	ELSE IF @tiCESP400TypeID = 190 AND @OperID > 0
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
					iOtherPlanGovRegNumber,
					vcOtherConventionNo,
					fCLB,
					fEAPCLB,
					fPG,
					fEAPPG )
				SELECT 
					OpRIO.iID_Oper_RIO,
					CT.CotisationID,
					C.ConventionID,
					19,
					'FIN',
					O.OperDate,
					P.PlanGovernmentRegNo,
					C.ConventionNo,
					ISNULL(HS.SocialNumber,''),
					HB.SocialNumber,
					ISNULL(CT.Cotisation,0)+ISNULL(CT.Fee,0),
					C.bCESGRequested,
					
					ABS(CE.fCESG + CE.fACESG),
					ABS(CE.fACESG),
					
					0,
					0,
					0,
					PAUT.PlanGovernmentRegNo,
					CAUT.ConventionNo,
					ABS(CE.fCLB),
					0,
					0,
					0
				FROM tblOPER_OperationsRIO OpRIO
				JOIN Un_Oper O ON O.OperID = OpRIO.iID_Oper_RIO
				JOIN Un_CESP CE ON CE.OperID = OpRIO.iID_Oper_RIO AND
								   CE.ConventionID = OpRIO.iID_Convention_Destination
				LEFT JOIN Un_Cotisation CT ON CT.CotisationID = CE.CotisationID
				JOIN dbo.Un_Convention C ON C.ConventionID = OpRIO.iID_Convention_Destination
				JOIN Un_Plan P ON P.PlanID = C.PlanID
				JOIN dbo.Un_Convention CAUT ON CAUT.ConventionID = OpRIO.iID_Convention_Source
				JOIN Un_Plan PAUT ON PAUT.PlanID = CAUT.PlanID
				JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID
				JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
				WHERE OpRIO.iID_Oper_RIO = @OperID
					AND NOT EXISTS(
							-- Opération qui ont un enregistrement 400 expédié qui est valide.
							SELECT *
							FROM Un_CESP400 C4
							LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = C4.iCESP400ID
							LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID AND C9.tiCESP900OriginID = 3 -- Transaction 900 dont l'origine n'est pas transfert non-réglé
							WHERE C4.OperID = @OperID
								AND C4.tiCESP400TypeID = 19 -- DU meme type
								AND C4.ConventionID = CE.ConventionID
								AND C4.CotisationID = CE.CotisationID
								
								AND C4.fCESG = ABS(CE.fCESG + CE.fACESG)
								AND C4.fACESGPart = ABS(CE.fACESG)
								
								AND C4.fCLB = ABS(CE.fCLB)
								AND C4.iCESP800ID IS NULL 		-- Pas revenu en erreur
								AND C4.iReversedCESP400ID IS NULL 	-- Pas une annulation
								AND R4.iCESP400ID IS NULL 		-- Pas annulé
								AND C9.iCESP900ID IS NULL
							)
	END

	---------------
	-- Type 21-1 --
	---------------
	ELSE IF @tiCESP400TypeID = 21 
			AND @tiCESP400WithdrawReasonID = 1
			AND @OperID > 0
	BEGIN
		DECLARE @tConvTrans21_1 TABLE (
			ConventionID INTEGER PRIMARY KEY)

		INSERT INTO @tConvTrans21_1
			SELECT 
				U.ConventionID
			FROM Un_Cotisation Ct
			JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			WHERE Ct.OperID = @OperID
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
				fACESGPart,
				fEAPCESG,
				fEAP,
				fPSECotisation,
				fCLB,
				fEAPCLB,
				fPG,
				fEAPPG,
				fCotisationGranted )
			SELECT DISTINCT
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
					WHEN ROUND((ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0)) / (ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0)) * ABS(Ct.Cotisation+Ct.Fee), 2) > ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0) 
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
					I.ConventionID,
					
					-- Solde de la SCEE et SCEE+
					fCESG = SUM(G.fCESG), 
					fACESG = SUM(G.fACESG), 
					
					fCotisationGranted = SUM(G.fCotisationGranted) -- Solde des cotisations subventionnées
				FROM @tConvTrans21_1 I
				JOIN Un_CESP G ON G.ConventionID = I.ConventionID
				GROUP BY I.ConventionID
				) G ON G.ConventionID = C.ConventionID
			LEFT JOIN ( -- Solde SCEE et SCEE+ à rembourser
				SELECT
					I.ConventionID,
					
					-- Solde de la SCEE et SCEE+
					fCESG = SUM(C4.fCESG), 
					fACESGPart = SUM(C4.fACESGPart), 
					
					fCotisationGranted = SUM(C4.fCotisationGranted)
				FROM @tConvTrans21_1 I
				JOIN Un_CESP400 C4 ON C4.ConventionID = I.ConventionID
				LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID
				LEFT JOIN Un_CESP CE ON CE.OperID = C4.OperID
				WHERE C9.iCESP900ID IS NULL
					AND C4.iCESP800ID IS NULL
					AND CE.iCESPID IS NULL
				GROUP BY I.ConventionID
				) C4 ON C4.ConventionID = C.ConventionID
			WHERE Ct.OperID = @OperID
				AND dbo.FN_CRQ_DateNoTime(ISNULL(C.dtRegStartDate,Ct.EffectDate+1)) <= Ct.EffectDate -- Pas dans un compte bloqué
				AND ISNULL(HB.SocialNumber,'') <> ''
				AND Ct.CotisationID NOT IN (
						-- Cotisation qui ont un enregistrement 400 expédié qui est valide.
						SELECT Ct.CotisationID
						FROM Un_Cotisation Ct
						JOIN Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID
						LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
						WHERE Ct.OperID = @OperID
							AND G4.iCESP800ID IS NULL -- Pas revenu en erreur
							AND G4.iReversedCESP400ID IS NULL -- Pas une annulation
							AND R4.iCESP400ID IS NULL -- Pas annulé
						)

/*			-- JFG : 2009-11-18 : Désactivation du BEC
			-- Récupérer l'identifiant unique de la convention, la présence du BEC et l'idenfiant du bénéficiaire
			SELECT 
				@iID_Convention		= co.ConventionID
				,@bBECPresent		= dbo.fnPCEE_ValiderPresenceBEC(co.ConventionID)
				,@iID_Beneficiaire	= c.BeneficiaryID
			FROM
				dbo.Un_ConventionOper co
				INNER JOIN dbo.Un_Convention c
					ON co.ConventionID = c.ConventionID
			WHERE
				co.OperID = @OperID

			IF @bBECPresent = 1 
				BEGIN
					-- Récupérer la somme du BEC
					SELECT
						@mCLB = SUM(ce.fCLB)
					FROM
						@tConvTrans21_1 t
						INNER JOIN dbo.Un_CESP ce
							ON t.ConventionID = ce.ConventionID
					GROUP BY
						t.ConventionID         

					-- Recherche de la convention  suggérée pour effectuer un transfert
					-- Liste des conventions actives du bénéficiaire
					DELETE FROM @tConvention

					INSERT INTO @tConvention
					(
					iID_Convention		
					,iID_Souscripteur	
					,iID_Beneficiaire	
					,vcConventionNO		
					,cID_PlanType		
					,vcPlanDesc			
					,bPresenceBec
					,dtDateEntreeVigueur		
					)
					SELECT
						fnt.iConventionID
						,fnt.iSubscriberID
						,fnt.iBeneficiaryID
						,fnt.vcConventionNO
						,fnt.cPlanTypeID
						,fnt.vcPlanDesc
						,bPresenceBec = dbo.fnPCEE_ValiderPresenceBEC(fnt.iConventionID)
						,u.InForceDate
					FROM
						dbo.fntCONV_ObtenirListeConventionsParBeneficiaire(GETDATE(), @iID_Beneficiaire) fnt	-- LISTE DES CONVENTION REE ACTIVES
						INNER JOIN dbo.Un_Unit u
							ON u.ConventionID = fnt.iConventionID
					WHERE
						fnt.iConventionID <> @iID_Convention
					
					-- RÉCUPÉRER LA CONVENTION SUGGÉRÉE POUR LE BEC SELON L'ORDRE SUIVANT :
					--			- PLUS VIEILLE CONVENTION INDIVIDUELLE
					--			- SINON PLUS VIEILLE CONVENTION COLLECTIVE REEFLEX
					--			- SINON PLUS VIEILLE CONVENTION COLLECTIVE UNIVERSITAS

					SET @iID_ConventionSuggere = (SELECT TOP 1 t.iID_Convention FROM @tConvention t WHERE t.cID_PlanType = 'IND' ORDER BY t.dtDateEntreeVigueur ASC, t.iID_Convention)

					IF @iID_ConventionSuggere IS NULL
						BEGIN
							SET @iID_ConventionSuggere = (SELECT TOP 1 t.iID_Convention FROM @tConvention t WHERE t.vcPlanDesc = 'Reeeflex' ORDER BY t.dtDateEntreeVigueur ASC, t.iID_Convention)
						END

					IF @iID_ConventionSuggere IS NULL
						BEGIN
							SET @iID_Convention = (SELECT TOP 1 t.iID_Convention FROM @tConvention t WHERE t.vcPlanDesc = 'Universitas' ORDER BY t.dtDateEntreeVigueur ASC, t.iID_Convention)				
						END

					IF @iID_ConventionSuggere IS NOT NULL	-- On transfère le BEC
						BEGIN
							EXECUTE @iRetour = dbo.psPCEE_CreerDemandeBec @iID_ConventionSuggere		
						END

					-- Désactiver le BEC actif si le remboursement est à zéro
					IF @mCLB <> 0 
						BEGIN
							EXECUTE @iRetour = dbo.psPCEE_DesactiverBec @iID_Beneficiaire, @ConnectID
						END
			END
*/
	END
	---------------
	-- Type 21-3 --
	---------------
	ELSE IF @tiCESP400TypeID = 21 
			AND @tiCESP400WithdrawReasonID = 3
			AND @OperID > 0
	BEGIN
		DECLARE @tConvTrans21_3 TABLE (
			ConventionID INTEGER PRIMARY KEY)

		-- Traiter les 421-3 pour les opérations qui ne sont pas des FRM
		INSERT INTO @tConvTrans21_3
			SELECT 
				U.ConventionID
			FROM Un_Cotisation Ct
			JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			JOIN Un_Oper O ON O.OperID = CT.OperID
			WHERE Ct.OperID = @OperID
				AND O.OperTypeID <> 'FRM'
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
			JOIN @tConvTrans21_3 TC ON TC.ConventionID = U.ConventionID
			JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
			JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
			JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
			LEFT JOIN ( -- Solde SCEE et SCEE+ et solde de BEC
				SELECT
					I.ConventionID,
					
					-- Solde de la SCEE et SCEE+
					fCESG = SUM(G.fCESG), 
					fACESG = SUM(G.fACESG), 
					
					fCLB = SUM(G.fCLB), -- Solde de BEC
					fCotisationGranted = SUM(G.fCotisationGranted) -- Solde des cotisations subventionnées
				FROM @tConvTrans21_3 I
				JOIN Un_CESP G ON G.ConventionID = I.ConventionID
				GROUP BY I.ConventionID
				) G ON G.ConventionID = C.ConventionID
			LEFT JOIN ( -- Solde SCEE et SCEE+ à rembourser
				SELECT
					I.ConventionID,
					
					-- Solde de la SCEE et SCEE+ à rembourser
					fCESG = SUM(C4.fCESG), 
					fACESGPart = SUM(C4.fACESGPart), 
					
					fCLB = SUM(C4.fCLB), -- Solde de BEC à rembourser
					fCotisationGranted = SUM(C4.fCotisationGranted) -- Solde des cotisations subventionnées
				FROM @tConvTrans21_3 I
				JOIN Un_CESP400 C4 ON C4.ConventionID = I.ConventionID
				LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID
				LEFT JOIN Un_CESP CE ON CE.OperID = C4.OperID
				WHERE C9.iCESP900ID IS NULL
					AND C4.iCESP800ID IS NULL
					AND CE.iCESPID IS NULL
				GROUP BY I.ConventionID
				) C4 ON C4.ConventionID = C.ConventionID
			WHERE Ct.OperID = @OperID
				AND dbo.FN_CRQ_DateNoTime(ISNULL(C.dtRegStartDate,Ct.EffectDate+1)) <= Ct.EffectDate -- Pas dans un compte bloqué
				AND ISNULL(HB.SocialNumber,'') <> ''
				AND Ct.CotisationID NOT IN (
						-- Cotisation qui ont un enregistrement 400 expédié qui est valide.
						SELECT Ct.CotisationID
						FROM Un_Cotisation Ct
						JOIN Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID and /**/ g4.tiCESP400TypeID <> 24 /* -- glpi 12174 pour que tout le "not in" n'affecte pas le type 24 */
						LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
						WHERE Ct.OperID = @OperID
							AND G4.iCESP800ID IS NULL -- Pas revenu en erreur
							AND G4.iReversedCESP400ID IS NULL -- Pas une annulation
							AND R4.iCESP400ID IS NULL -- Pas annulé
						)

		-- Traiter les 421-3 pour les opérations FRM
		DELETE FROM @tConvTrans21_3
		
		INSERT INTO @tConvTrans21_3
			SELECT 
				U.ConventionID
			FROM Un_Cotisation Ct
			JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			JOIN Un_Oper O ON O.OperID = CT.OperID
			WHERE Ct.OperID = @OperID
				AND O.OperTypeID = 'FRM'
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
				O.OperID,
				NULL,
				C.ConventionID,
				21,
				3,
				'FIN',
				O.OperDate,
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
			FROM (
				SELECT DISTINCT
					O.OperID,
					O.OperDate,
					U.ConventionID
				FROM Un_Oper O 
				JOIN Un_Cotisation CT ON CT.OperID = O.OperID
				JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
				WHERE O.OperID = @OperID
				) O
			JOIN dbo.Un_Convention C ON C.ConventionID = O.ConventionID
			JOIN @tConvTrans21_3 TC ON TC.ConventionID = C.ConventionID
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
			JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
			JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
			LEFT JOIN ( -- Solde SCEE et SCEE+ et solde de BEC
				SELECT
					I.ConventionID,
					
					-- Solde de la SCEE et SCEE+
					fCESG = SUM(G.fCESG), 
					fACESG = SUM(G.fACESG), 
					
					fCLB = SUM(G.fCLB), -- Solde de BEC
					fCotisationGranted = SUM(G.fCotisationGranted) -- Solde des cotisations subventionnées
				FROM @tConvTrans21_3 I
				JOIN Un_CESP G ON G.ConventionID = I.ConventionID
				GROUP BY I.ConventionID
				) G ON G.ConventionID = C.ConventionID
			LEFT JOIN ( -- Solde SCEE et SCEE+ à rembourser
				SELECT
					I.ConventionID,
					
					-- Solde de la SCEE et SCEE+ à rembourser
					fCESG = SUM(C4.fCESG), 
					fACESGPart = SUM(C4.fACESGPart), 
					
					fCLB = SUM(C4.fCLB), -- Solde de BEC à rembourser
					fCotisationGranted = SUM(C4.fCotisationGranted) -- Solde des cotisations subventionnées
				FROM @tConvTrans21_3 I
				JOIN Un_CESP400 C4 ON C4.ConventionID = I.ConventionID
				LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID
				LEFT JOIN Un_CESP CE ON CE.OperID = C4.OperID
				WHERE C9.iCESP900ID IS NULL
					AND C4.iCESP800ID IS NULL
					AND CE.iCESPID IS NULL
				GROUP BY I.ConventionID
				) C4 ON C4.ConventionID = C.ConventionID
			WHERE dbo.FN_CRQ_DateNoTime(ISNULL(C.dtRegStartDate,O.OperDate+1)) <= O.OperDate -- Pas dans un compte bloqué
				AND ISNULL(HB.SocialNumber,'') <> ''
				AND O.OperID NOT IN (
						-- Cotisation qui ont un enregistrement 400 expédié qui est valide.
						SELECT CT.OperID
						FROM Un_Cotisation Ct
						JOIN Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID and /**/ g4.tiCESP400TypeID <> 24 /* -- glpi 12174 pour que tout le "not in" n'affecte pas le type 24 */
						LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
						WHERE Ct.OperID = @OperID
							AND G4.iCESP800ID IS NULL -- Pas revenu en erreur
							AND G4.iReversedCESP400ID IS NULL -- Pas une annulation
							AND R4.iCESP400ID IS NULL -- Pas annulé
						)

/*
			-- JFG : 2009-11-16 : Désactivation du BEC
			-- Récupérer l'identifiant unique de la convention, la présence du BEC et l'idenfiant du bénéficiaire
			SELECT 
				@iID_Convention		= co.ConventionID
				,@bBECPresent		= c.bCLBRequested
				,@iID_Beneficiaire	= c.BeneficiaryID
			FROM
				dbo.Un_ConventionOper co
				INNER JOIN dbo.Un_Convention c
					ON co.ConventionID = c.ConventionID
			WHERE
				co.OperID = @OperID

			-- Si la case 'BEC' est cochée.
			IF @bBECPresent = 1 
				BEGIN
					-- Récupérer la somme du BEC
					SELECT
						@mCLB = SUM(ce.fCLB)
					FROM
						@tConvTrans21_3 t
						INNER JOIN dbo.Un_CESP ce
							ON t.ConventionID = ce.ConventionID
					GROUP BY
						t.ConventionID     

					SELECT
						@mCLB = @mCLB + SUM(C4.fCLB) -- Solde de BEC à rembourser
					FROM @tConvTrans21_3 I
					JOIN Un_CESP400 C4 ON C4.ConventionID = I.ConventionID
					LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID
					LEFT JOIN Un_CESP CE ON CE.OperID = C4.OperID
					WHERE C9.iCESP900ID IS NULL
						AND C4.iCESP800ID IS NULL
						AND CE.iCESPID IS NULL
					GROUP BY I.ConventionID
    
					-- Désactiver le BEC actif si le remboursement est à zéro
					IF @mCLB = 0 
						BEGIN
							EXECUTE @iRetour = dbo.psPCEE_DesactiverBec @iID_Beneficiaire, @ConnectID
						END
				END
*/
	END
	---------------
	-- Type 21-4 --
	---------------
	ELSE IF @tiCESP400TypeID = 21 
			AND @tiCESP400WithdrawReasonID = 4
			AND @OperID > 0
			AND @iTypeRemboursement = 1		-- 2009-11-11 : JFG
	BEGIN

		DECLARE @tConvTrans21_4 TABLE (
			ConventionID INTEGER PRIMARY KEY)

		INSERT INTO @tConvTrans21_4
			SELECT 
				U.ConventionID
			FROM Un_Cotisation Ct
			JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			WHERE Ct.OperID = @OperID
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
					I.ConventionID,
					
					-- Solde de la SCEE et SCEE+
					fCESG = SUM(G.fCESG), 
					fACESG = SUM(G.fACESG), 
					
					fCotisationGranted = SUM(G.fCotisationGranted) -- Solde des cotisations subventionnées
				FROM @tConvTrans21_4 I
				JOIN Un_CESP G ON G.ConventionID = I.ConventionID
				GROUP BY I.ConventionID
				) G ON G.ConventionID = C.ConventionID
			LEFT JOIN ( -- Solde SCEE et SCEE+ à rembourser
				SELECT
					I.ConventionID,
					
					-- Solde de la SCEE et SCEE+
					fCESG = SUM(C4.fCESG), 
					fACESGPart = SUM(C4.fACESGPart), 
					
					fCotisationGranted = SUM(C4.fCotisationGranted)
				FROM @tConvTrans21_4 I
				JOIN Un_CESP400 C4 ON C4.ConventionID = I.ConventionID
				LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID
				LEFT JOIN Un_CESP CE ON CE.OperID = C4.OperID
				WHERE C9.iCESP900ID IS NULL
					AND C4.iCESP800ID IS NULL
					AND CE.iCESPID IS NULL
				GROUP BY I.ConventionID
				) C4 ON C4.ConventionID = C.ConventionID
			WHERE Ct.OperID = @OperID
				AND dbo.FN_CRQ_DateNoTime(ISNULL(C.dtRegStartDate,Ct.EffectDate+1)) <= Ct.EffectDate -- Pas dans un compte bloqué
				AND ISNULL(HB.SocialNumber,'') <> ''
				AND Ct.CotisationID NOT IN (
						-- Cotisation qui ont un enregistrement 400 expédié qui est valide.
						SELECT Ct.CotisationID
						FROM Un_Cotisation Ct
						JOIN Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID
						LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
						WHERE Ct.OperID = @OperID
							AND G4.iCESP800ID IS NULL -- Pas revenu en erreur
							AND G4.iReversedCESP400ID IS NULL -- Pas une annulation
							AND R4.iCESP400ID IS NULL -- Pas annulé
						)
	END
	-------------------
	-- Type 21-4 BEC --
	-------------------		
	ELSE IF @tiCESP400TypeID = 21 
			AND @tiCESP400WithdrawReasonID = 4
			AND @OperID > 0
			AND @iTypeRemboursement = 2
	BEGIN
		DECLARE @tConvTrans21_4BEC TABLE (ConventionID INT PRIMARY KEY)
		
		INSERT INTO @tConvTrans21_4BEC
		(
			ConventionID
		)
		SELECT
			u.ConventionID
		FROM
			dbo.Un_Cotisation ct
			INNER JOIN dbo.Un_Unit u
				ON u.UnitID= ct.UnitID
		WHERE
			ct.OperID = @OperID
		GROUP BY
			u.ConventionID
		
		INSERT INTO dbo.Un_CESP400 
				(	OperID,
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
					fCotisationGranted 
				)
		SELECT
			Ct.OperID,
			Ct.CotisationID,
			C.ConventionID,
			21,
			4,
			'FIN',
			GETDATE(),
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
			-- Rembourse la totalité du BEC
			-(ISNULL(G.fCLB,0)+ISNULL(C4.fCLB,0)),
			0,
			0,
			0,
			0
		FROM 
			dbo.Un_Cotisation Ct
			INNER JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			INNER JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			INNER JOIN dbo.Un_Plan P ON P.PlanID = C.PlanID
			INNER JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
			INNER JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
			INNER JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
			LEFT OUTER JOIN ( -- Solde de BEC
							SELECT
								I.ConventionID,
								fCLB = SUM(G.fCLB) -- Solde de BEC
							FROM 
								@tConvTrans21_4BEC I
								INNER JOIN dbo.Un_CESP G ON G.ConventionID = I.ConventionID
							GROUP BY I.ConventionID
							) G ON G.ConventionID = C.ConventionID
			LEFT OUTER JOIN ( 
							SELECT
								I.ConventionID,
								fCLB = SUM(C4.fCLB) -- Solde de BEC
							FROM 
								@tConvTrans21_4BEC I
								INNER JOIN dbo.Un_CESP400 C4 ON C4.ConventionID = I.ConventionID
								LEFT OUTER JOIN dbo.Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID
								LEFT OUTER JOIN dbo.Un_CESP CE ON CE.OperID = C4.OperID
							WHERE 
									C9.iCESP900ID IS NULL
									AND C4.iCESP800ID IS NULL
									AND CE.iCESPID IS NULL
							GROUP BY I.ConventionID
								) C4 ON C4.ConventionID = C.ConventionID
		WHERE 
			Ct.OperID = @OperID
			AND dbo.FN_CRQ_DateNoTime(ISNULL(C.dtRegStartDate,Ct.EffectDate+1)) <= Ct.EffectDate -- Pas dans un compte bloqué
			AND ISNULL(HB.SocialNumber,'') <> ''
	/*		AND Ct.CotisationID NOT IN 
									(
											-- Cotisation qui ont un enregistrement 400 expédié qui est valide.
										SELECT Ct.CotisationID
										FROM 
											dbo.Un_Cotisation Ct
											INNER JOIN dbo.Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID
											LEFT OUTER JOIN dbo.Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
										WHERE 
											Ct.OperID = @OperID
											AND G4.iCESP800ID IS NULL -- Pas revenu en erreur
											AND G4.iReversedCESP400ID IS NULL -- Pas une annulation
											AND R4.iCESP400ID IS NULL -- Pas annulé
									)		
   */	
   END
	---------------
	-- Type 21-5 --
	---------------
	ELSE IF @tiCESP400TypeID = 21 
			AND @tiCESP400WithdrawReasonID = 5
			AND @OperID > 0
			AND @iTypeRemboursement = 1		-- 2009-11-11 : JFG
	BEGIN

		DECLARE @tConvTrans21_5 TABLE (
			ConventionID INTEGER PRIMARY KEY)

		INSERT INTO @tConvTrans21_5
			SELECT 
				U.ConventionID
			FROM Un_Cotisation Ct
			JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			WHERE Ct.OperID = @OperID
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
				5,
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
					WHEN ROUND((ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0)) / (ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0)) * ABS(Ct.Cotisation+Ct.Fee), 2) > ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0) 
						THEN -(ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0))
					-- Rembourse au proprata selon la formule A/B*C du règlement sur l’épargne-études si on retire seulement une partie des cotisations subventionnées
					ELSE -(ROUND((ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0)) / (ISNULL(G.fCotisationGranted, 0) + ISNULL(C4.fCotisationGranted, 0)) * ABS(Ct.Cotisation + Ct.Fee), 2))
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
					I.ConventionID,
					
					-- Solde de la SCEE et SCEE+
					fCESG = SUM(G.fCESG), 
					fACESG = SUM(G.fACESG), 
					
					fCotisationGranted = SUM(G.fCotisationGranted) -- Solde des cotisations subventionnées
				FROM @tConvTrans21_5 I
				JOIN Un_CESP G ON G.ConventionID = I.ConventionID
				GROUP BY I.ConventionID
				) G ON G.ConventionID = C.ConventionID
			LEFT JOIN ( -- Solde SCEE et SCEE+ à rembourser
				SELECT
					I.ConventionID,
					
					-- Solde de la SCEE et SCEE+
					fCESG = SUM(C4.fCESG), 
					fACESGPart = SUM(C4.fACESGPart), 
					
					fCotisationGranted = SUM(C4.fCotisationGranted)
				FROM @tConvTrans21_5 I
				JOIN Un_CESP400 C4 ON C4.ConventionID = I.ConventionID
				LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID
				LEFT JOIN Un_CESP CE ON CE.OperID = C4.OperID
				WHERE C9.iCESP900ID IS NULL
					AND C4.iCESP800ID IS NULL
					AND CE.iCESPID IS NULL
				GROUP BY I.ConventionID
				) C4 ON C4.ConventionID = C.ConventionID
			WHERE Ct.OperID = @OperID
				AND dbo.FN_CRQ_DateNoTime(ISNULL(C.dtRegStartDate,Ct.EffectDate+1)) <= Ct.EffectDate -- Pas dans un compte bloqué
				AND ISNULL(HB.SocialNumber,'') <> ''
				AND Ct.CotisationID NOT IN (
						-- Cotisation qui ont un enregistrement 400 expédié qui est valide.
						SELECT Ct.CotisationID
						FROM Un_Cotisation Ct
						JOIN Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID
						LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
						WHERE Ct.OperID = @OperID
							AND G4.iCESP800ID IS NULL -- Pas revenu en erreur
							AND G4.iReversedCESP400ID IS NULL -- Pas une annulation
							AND R4.iCESP400ID IS NULL -- Pas annulé
						)

	END

	---------------
	-- Type 21-5 --
    -- 2010-01-28 Pierre Paquet - Changement de bénéficiaire. 
	---------------
	ELSE IF @tiCESP400TypeID = 21 
			AND @tiCESP400WithdrawReasonID = 5
			AND @OperID > 0
			AND @iTypeRemboursement = 3		
	BEGIN

		DECLARE @tConvTrans21_5CB TABLE (
								ConventionID INTEGER PRIMARY KEY
								,NAS_Beneficiaire_Cedant VARCHAR(75)
								,dtDecesBeneficiaire DATETIME
								)
								
		DECLARE 
			@dtDate DATETIME
			
		--SET @dtDate = DATEADD(dd,-1,GETDATE())
		SET @dtDate = DATEADD(dd,+1,GETDATE()) -- GLPI 5323 DHuppé(2011-04-06) : au lieu de prnedre la date de la veille, on prend la date du lendemain pour être certain d'avoir le dernier changement de bénéficiaire

		INSERT INTO @tConvTrans21_5CB
		(
			ConventionID
			,NAS_Beneficiaire_Cedant
			,dtDecesBeneficiaire
		)
		SELECT 
			U.ConventionID
			,hu.SocialNumber
			,hu.deathdate
		FROM 
			Un_Cotisation Ct
			INNER JOIN dbo.Un_Unit U 
				ON U.UnitID = Ct.UnitID
			CROSS APPLY dbo.fntCONV_RechercherChangementsBeneficiaire(NULL, NULL, u.ConventionID, NULL,  @dtDate, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL) fnt 	
			INNER JOIN dbo.Mo_Human hu 
				ON hu.HumanID = fnt.iID_Ancien_Beneficiaire
		WHERE 
			Ct.OperID = @OperID
		GROUP BY 
			U.ConventionID
			,hu.SocialNumber
			,hu.deathdate
	
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
				vcBeneficiarySIN, --à modifier.
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
				5,
				'FIN',
				Ct.EffectDate,
				P.PlanGovernmentRegNo,
				C.ConventionNo,
				ISNULL(HS.SocialNumber,''),
				(SELECT t.NAS_Beneficiaire_Cedant FROM @tConvTrans21_5CB t WHERE t.ConventionID = C.ConventionID) ,
				0,
				C.bCESGRequested,
				-- Rembourse la totalité de la subvention
				-- SCEE
				-(ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0)),
				-- SCEE+
				-(ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0)),
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				-(ISNULL(G.fCotisationGranted,0)+ISNULL(C4.fCotisationGranted,0))
			FROM 
				Un_Cotisation Ct
				JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
				JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				JOIN Un_Plan P ON P.PlanID = C.PlanID
				JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
				JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
				JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
				LEFT JOIN ( -- Solde SCEE et SCEE+
					SELECT
						I.ConventionID,
						
						-- Solde de la SCEE et SCEE+
						fCESG = SUM(G.fCESG), 
						fACESG = SUM(G.fACESG), 
						
						fCotisationGranted = SUM(G.fCotisationGranted) -- Solde des cotisations subventionnées
					FROM	@tConvTrans21_5CB I
							JOIN Un_CESP G ON G.ConventionID = I.ConventionID
							LEFT JOIN UN_Cotisation CO ON G.CotisationID = CO.CotisationID -- 2010-05-17
							-- S'il y a une date de décès, alors on calcul uniquement les transactions AVANT le décès.
							WHERE CO.EffectDate < ISNULL(I.dtDecesBeneficiaire, '9999-01-01')

					GROUP BY I.ConventionID
					) G ON G.ConventionID = C.ConventionID
				LEFT JOIN ( -- Solde SCEE et SCEE+ à rembourser
					SELECT
						I.ConventionID,
						
						-- Solde de la SCEE et SCEE+ à rembourser
						fCESG = SUM(C4.fCESG), 
						fACESGPart = SUM(C4.fACESGPart), 
						
						fCotisationGranted = SUM(C4.fCotisationGranted) -- Solde des cotisations subventionnées
					FROM @tConvTrans21_5CB I
						 JOIN Un_CESP400 C4 ON C4.ConventionID = I.ConventionID
						 LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID
						 LEFT JOIN Un_CESP CE ON CE.OperID = C4.OperID
					WHERE C9.iCESP900ID IS NULL
						AND C4.iCESP800ID IS NULL
						AND CE.iCESPID IS NULL
						AND C4.dtTransaction < ISNULL(I.dtDecesBeneficiaire, '9999-01-01')
					GROUP BY I.ConventionID
					) C4 ON C4.ConventionID = C.ConventionID
			WHERE Ct.OperID = @OperID
				AND dbo.FN_CRQ_DateNoTime(ISNULL(C.dtRegStartDate,Ct.EffectDate+1)) <= Ct.EffectDate -- Pas dans un compte bloqué
				AND ISNULL(HB.SocialNumber,'') <> ''
				AND Ct.CotisationID NOT IN (
						-- Cotisation qui ont un enregistrement 400 expédié qui est valide.
						SELECT Ct.CotisationID
						FROM Un_Cotisation Ct
						JOIN Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID
						LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
						WHERE Ct.OperID = @OperID
							AND G4.iCESP800ID IS NULL -- Pas revenu en erreur
							AND G4.iReversedCESP400ID IS NULL -- Pas une annulation
							AND R4.iCESP400ID IS NULL -- Pas annulé
						)
				
	END

	-------------------
	-- Type 21-5 BEC --
	-------------------		
	ELSE IF @tiCESP400TypeID = 21 
			AND @tiCESP400WithdrawReasonID = 5
			AND @OperID > 0
			AND @iTypeRemboursement = 2
	BEGIN
		DECLARE @tConvTrans21_5BEC TABLE (ConventionID INT PRIMARY KEY)
		
		INSERT INTO @tConvTrans21_5BEC
		(
			ConventionID
		)
		SELECT
			u.ConventionID
		FROM
			dbo.Un_Cotisation ct
			INNER JOIN dbo.Un_Unit u
				ON u.UnitID= ct.UnitID
		WHERE
			ct.OperID = @OperID
		GROUP BY
			u.ConventionID
		
		INSERT INTO dbo.Un_CESP400 
				(	OperID,
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
					fCotisationGranted 
				)
		SELECT			
				Ct.OperID,
				Ct.CotisationID,
				C.ConventionID,
				21,
				5,
				'FIN',
				GETDATE(),
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
				-- Rembourse la totalité du BEC
				-(ISNULL(G.fCLB,0)+ISNULL(C4.fCLB,0)),
				0,
				0,
				0,
				0
		FROM 
			dbo.Un_Cotisation Ct
			INNER JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			INNER JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			INNER JOIN dbo.Un_Plan P ON P.PlanID = C.PlanID
			INNER JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
			INNER JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
			INNER JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
			LEFT OUTER JOIN ( -- Solde de BEC
							SELECT
								I.ConventionID,
								fCLB = SUM(G.fCLB) -- Solde de BEC
							FROM 
								@tConvTrans21_5BEC I
								INNER JOIN dbo.Un_CESP G ON G.ConventionID = I.ConventionID
							GROUP BY I.ConventionID
							) G ON G.ConventionID = C.ConventionID
			LEFT OUTER JOIN ( 
							SELECT
								I.ConventionID,
								fCLB = SUM(C4.fCLB) -- Solde de BEC
							FROM 
								@tConvTrans21_5BEC I
								INNER JOIN dbo.Un_CESP400 C4 ON C4.ConventionID = I.ConventionID
								LEFT OUTER JOIN dbo.Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID
								LEFT OUTER JOIN dbo.Un_CESP CE ON CE.OperID = C4.OperID
							WHERE 
									C9.iCESP900ID IS NULL
									AND C4.iCESP800ID IS NULL
									AND CE.iCESPID IS NULL
							GROUP BY I.ConventionID
								) C4 ON C4.ConventionID = C.ConventionID
		WHERE 
			Ct.OperID = @OperID
			AND dbo.FN_CRQ_DateNoTime(ISNULL(C.dtRegStartDate,Ct.EffectDate+1)) <= Ct.EffectDate -- Pas dans un compte bloqué
			AND ISNULL(HB.SocialNumber,'') <> ''
		/*	AND Ct.CotisationID NOT IN 
									(
											-- Cotisation qui ont un enregistrement 400 expédié qui est valide.
										SELECT Ct.CotisationID
										FROM 
											dbo.Un_Cotisation Ct
											INNER JOIN dbo.Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID
											LEFT OUTER JOIN dbo.Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
										WHERE 
											Ct.OperID = @OperID
											AND G4.iCESP800ID IS NULL -- Pas revenu en erreur
											AND G4.iReversedCESP400ID IS NULL -- Pas une annulation
											AND R4.iCESP400ID IS NULL -- Pas annulé
									)	
	*/	
	END	
		-----------
	-- 21-7	 --	
	-----------
	ELSE IF @tiCESP400TypeID = 21 
			AND @tiCESP400WithdrawReasonID = 7
			AND @OperID > 0
	BEGIN
		DECLARE @tConvTrans21_7 TABLE (
			ConventionID INTEGER PRIMARY KEY)

		INSERT INTO @tConvTrans21_7
			SELECT 
				U.ConventionID
			FROM Un_Cotisation Ct
			JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			WHERE Ct.OperID = @OperID
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
				7,
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
					I.ConventionID,
					
					-- Solde de la SCEE et SCEE+
					fCESG = SUM(G.fCESG), 
					fACESG = SUM(G.fACESG), 
					
					fCLB = SUM(G.fCLB), -- Solde de BEC
					fCotisationGranted = SUM(G.fCotisationGranted) -- Solde des cotisations subventionnées
				FROM @tConvTrans21_7 I
				JOIN Un_CESP G ON G.ConventionID = I.ConventionID
				GROUP BY I.ConventionID
				) G ON G.ConventionID = C.ConventionID
			LEFT JOIN ( -- Solde SCEE et SCEE+ à rembourser
				SELECT
					I.ConventionID,
					
					-- Solde de la SCEE et SCEE+ à rembourser
					fCESG = SUM(C4.fCESG), 
					fACESGPart = SUM(C4.fACESGPart), 
					
					fCLB = SUM(C4.fCLB), -- Solde de BEC à rembourser
					fCotisationGranted = SUM(C4.fCotisationGranted) -- Solde des cotisations subventionnées
				FROM @tConvTrans21_7 I
				JOIN Un_CESP400 C4 ON C4.ConventionID = I.ConventionID
				LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID
				LEFT JOIN Un_CESP CE ON CE.OperID = C4.OperID
				WHERE C9.iCESP900ID IS NULL
					AND C4.iCESP800ID IS NULL
					AND CE.iCESPID IS NULL
				GROUP BY I.ConventionID
				) C4 ON C4.ConventionID = C.ConventionID
			WHERE Ct.OperID = @OperID
				AND dbo.FN_CRQ_DateNoTime(ISNULL(C.dtRegStartDate,Ct.EffectDate+1)) <= Ct.EffectDate -- Pas dans un compte bloqué
				AND ISNULL(HB.SocialNumber,'') <> ''
				AND Ct.CotisationID NOT IN (
						-- Cotisation qui ont un enregistrement 400 expédié qui est valide.
						SELECT Ct.CotisationID
						FROM Un_Cotisation Ct
						JOIN Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID
						LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
						WHERE Ct.OperID = @OperID
							AND G4.iCESP800ID IS NULL -- Pas revenu en erreur
							AND G4.iReversedCESP400ID IS NULL -- Pas une annulation
							AND R4.iCESP400ID IS NULL -- Pas annulé
						)

			-- JFG : 2009-11-16 : Désactivation du BEC
			-- Récupérer l'identifiant unique de la convention, la présence du BEC et l'idenfiant du bénéficiaire
			SELECT 
				@iID_Convention		= co.ConventionID
				,@bBECPresent		= dbo.fnPCEE_ValiderPresenceBEC(co.ConventionID)
				,@iID_Beneficiaire	= c.BeneficiaryID
			FROM
				dbo.Un_ConventionOper co
				INNER JOIN dbo.Un_Convention c
					ON co.ConventionID = c.ConventionID
			WHERE
				co.OperID = @OperID

			IF @bBECPresent = 1 
				BEGIN
					-- Récupérer la somme du BEC
					SELECT
						@mCLB = SUM(ce.fCLB)
					FROM
						@tConvTrans21_7 t
						INNER JOIN dbo.Un_CESP ce
							ON t.ConventionID = ce.ConventionID
					GROUP BY
						t.ConventionID         

					-- Recherche de la convention  suggérée pour effectuer un transfert
					-- Liste des conventions actives du bénéficiaire
					DELETE FROM @tConvention

					INSERT INTO @tConvention
					(
					iID_Convention		
					,iID_Souscripteur	
					,iID_Beneficiaire	
					,vcConventionNO		
					,cID_PlanType		
					,vcPlanDesc			
					,bPresenceBec
					,dtDateEntreeVigueur		
					)
					SELECT
						fnt.iConventionID
						,fnt.iSubscriberID
						,fnt.iBeneficiaryID
						,fnt.vcConventionNO
						,fnt.cPlanTypeID
						,fnt.vcPlanDesc
						,bPresenceBec = dbo.fnPCEE_ValiderPresenceBEC(fnt.iConventionID)
						,u.InForceDate
					FROM
						dbo.fntCONV_ObtenirListeConventionsParBeneficiaire(GETDATE(), @iID_Beneficiaire) fnt	-- LISTE DES CONVENTION REE ACTIVES
						INNER JOIN dbo.Un_Unit u
							ON u.ConventionID = fnt.iConventionID
					WHERE
						fnt.iConventionID <> @iID_Convention
					
					-- RÉCUPÉRER LA CONVENTION SUGGÉRÉE POUR LE BEC SELON L'ORDRE SUIVANT :
					--			- PLUS VIEILLE CONVENTION INDIVIDUELLE
					--			- SINON PLUS VIEILLE CONVENTION COLLECTIVE REEFLEX
					--			- SINON PLUS VIEILLE CONVENTION COLLECTIVE UNIVERSITAS

					SET @iID_ConventionSuggere = (SELECT TOP 1 t.iID_Convention FROM @tConvention t WHERE t.cID_PlanType = 'IND' ORDER BY t.dtDateEntreeVigueur ASC, t.iID_Convention)

					IF @iID_ConventionSuggere IS NULL
						BEGIN
							SET @iID_ConventionSuggere = (SELECT TOP 1 t.iID_Convention FROM @tConvention t WHERE t.vcPlanDesc = 'Reeeflex' ORDER BY t.dtDateEntreeVigueur ASC, t.iID_Convention)
						END

					IF @iID_ConventionSuggere IS NULL
						BEGIN
							SET @iID_Convention = (SELECT TOP 1 t.iID_Convention FROM @tConvention t WHERE t.vcPlanDesc = 'Universitas' ORDER BY t.dtDateEntreeVigueur ASC, t.iID_Convention)				
						END

					IF @iID_ConventionSuggere IS NOT NULL	-- On transfère le BEC
						BEGIN
							EXECUTE @iRetour = dbo.psPCEE_CreerDemandeBec @iID_ConventionSuggere		
						END

					-- Désactiver le BEC actif si le remboursement est à zéro
					IF @mCLB <> 0 
						BEGIN
							EXECUTE @iRetour = dbo.psPCEE_DesactiverBec @iID_Beneficiaire, @ConnectID
						END
				END
		END
	-----------
	-- 21-8	 --	
	-----------
	ELSE IF @tiCESP400TypeID = 21 
			AND @tiCESP400WithdrawReasonID = 8
			AND @OperID > 0
	BEGIN
		DECLARE @tConvTrans21_8 TABLE (
			ConventionID INTEGER PRIMARY KEY)

		INSERT INTO @tConvTrans21_8
			SELECT 
				U.ConventionID
			FROM Un_Cotisation Ct
			JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			WHERE Ct.OperID = @OperID
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
				8,
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
					I.ConventionID,
					
					-- Solde de la SCEE et SCEE+
					fCESG = SUM(G.fCESG), 
					fACESG = SUM(G.fACESG), 
					
					fCLB = SUM(G.fCLB), -- Solde de BEC
					fCotisationGranted = SUM(G.fCotisationGranted) -- Solde des cotisations subventionnées
				FROM @tConvTrans21_8 I
				JOIN Un_CESP G ON G.ConventionID = I.ConventionID
				GROUP BY I.ConventionID
				) G ON G.ConventionID = C.ConventionID
			LEFT JOIN ( -- Solde SCEE et SCEE+ à rembourser
				SELECT
					I.ConventionID,
					
					-- Solde de la SCEE et SCEE+ à rembourser
					fCESG = SUM(C4.fCESG), 
					fACESGPart = SUM(C4.fACESGPart), 
					
					fCLB = SUM(C4.fCLB), -- Solde de BEC à rembourser
					fCotisationGranted = SUM(C4.fCotisationGranted) -- Solde des cotisations subventionnées
				FROM @tConvTrans21_8 I
				JOIN Un_CESP400 C4 ON C4.ConventionID = I.ConventionID
				LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID
				LEFT JOIN Un_CESP CE ON CE.OperID = C4.OperID
				WHERE C9.iCESP900ID IS NULL
					AND C4.iCESP800ID IS NULL
					AND CE.iCESPID IS NULL
				GROUP BY I.ConventionID
				) C4 ON C4.ConventionID = C.ConventionID
			WHERE Ct.OperID = @OperID
				AND dbo.FN_CRQ_DateNoTime(ISNULL(C.dtRegStartDate,Ct.EffectDate+1)) <= Ct.EffectDate -- Pas dans un compte bloqué
				AND ISNULL(HB.SocialNumber,'') <> ''
				AND Ct.CotisationID NOT IN (
						-- Cotisation qui ont un enregistrement 400 expédié qui est valide.
						SELECT Ct.CotisationID
						FROM Un_Cotisation Ct
						JOIN Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID
						LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
						WHERE Ct.OperID = @OperID
							AND G4.iCESP800ID IS NULL -- Pas revenu en erreur
							AND G4.iReversedCESP400ID IS NULL -- Pas une annulation
							AND R4.iCESP400ID IS NULL -- Pas annulé
						)

			-- JFG : 2009-11-16 : Désactivation du BEC
			-- Récupérer l'identifiant unique de la convention, la présence du BEC et l'idenfiant du bénéficiaire
			SELECT 
				@iID_Convention		= co.ConventionID
				,@bBECPresent		= dbo.fnPCEE_ValiderPresenceBEC(co.ConventionID)
				,@iID_Beneficiaire	= c.BeneficiaryID
			FROM
				dbo.Un_ConventionOper co
				INNER JOIN dbo.Un_Convention c
					ON co.ConventionID = c.ConventionID
			WHERE
				co.OperID = @OperID

			IF @bBECPresent = 1 
				BEGIN
					-- Récupérer la somme du BEC
					SELECT
						@mCLB = SUM(ce.fCLB)
					FROM
						@tConvTrans21_8 t
						INNER JOIN dbo.Un_CESP ce
							ON t.ConventionID = ce.ConventionID
					GROUP BY
						t.ConventionID         

					-- Recherche de la convention  suggérée pour effectuer un transfert
					-- Liste des conventions actives du bénéficiaire
					DELETE FROM @tConvention

					INSERT INTO @tConvention
					(
					iID_Convention		
					,iID_Souscripteur	
					,iID_Beneficiaire	
					,vcConventionNO		
					,cID_PlanType		
					,vcPlanDesc			
					,bPresenceBec
					,dtDateEntreeVigueur		
					)
					SELECT
						fnt.iConventionID
						,fnt.iSubscriberID
						,fnt.iBeneficiaryID
						,fnt.vcConventionNO
						,fnt.cPlanTypeID
						,fnt.vcPlanDesc
						,bPresenceBec = dbo.fnPCEE_ValiderPresenceBEC(fnt.iConventionID)
						,u.InForceDate
					FROM
						dbo.fntCONV_ObtenirListeConventionsParBeneficiaire(GETDATE(), @iID_Beneficiaire) fnt	-- LISTE DES CONVENTION REE ACTIVES
						INNER JOIN dbo.Un_Unit u
							ON u.ConventionID = fnt.iConventionID
					WHERE
						fnt.iConventionID <> @iID_Convention
					
					-- RÉCUPÉRER LA CONVENTION SUGGÉRÉE POUR LE BEC SELON L'ORDRE SUIVANT :
					--			- PLUS VIEILLE CONVENTION INDIVIDUELLE
					--			- SINON PLUS VIEILLE CONVENTION COLLECTIVE REEFLEX
					--			- SINON PLUS VIEILLE CONVENTION COLLECTIVE UNIVERSITAS

					SET @iID_ConventionSuggere = (SELECT TOP 1 t.iID_Convention FROM @tConvention t WHERE t.cID_PlanType = 'IND' ORDER BY t.dtDateEntreeVigueur ASC, t.iID_Convention)

					IF @iID_ConventionSuggere IS NULL
						BEGIN
							SET @iID_ConventionSuggere = (SELECT TOP 1 t.iID_Convention FROM @tConvention t WHERE t.vcPlanDesc = 'Reeeflex' ORDER BY t.dtDateEntreeVigueur ASC, t.iID_Convention)
						END

					IF @iID_ConventionSuggere IS NULL
						BEGIN
							SET @iID_Convention = (SELECT TOP 1 t.iID_Convention FROM @tConvention t WHERE t.vcPlanDesc = 'Universitas' ORDER BY t.dtDateEntreeVigueur ASC, t.iID_Convention)				
						END

					IF @iID_ConventionSuggere IS NOT NULL	-- On transfère le BEC
						BEGIN
							EXECUTE @iRetour = dbo.psPCEE_CreerDemandeBec @iID_ConventionSuggere		
						END

					-- Désactiver le BEC actif si le remboursement est à zéro
					IF @mCLB <> 0 
						BEGIN
							EXECUTE @iRetour = dbo.psPCEE_DesactiverBec @iID_Beneficiaire, @ConnectID
						END
				END
		END	
	---------------
	-- Type 21-9 --
	---------------
	ELSE IF @tiCESP400TypeID = 21 
			AND @tiCESP400WithdrawReasonID = 9
			AND @OperID > 0
			AND @iTypeRemboursement = 1		-- 2009-11-11 : JFG
	BEGIN
		DECLARE @tConvTrans21_9 TABLE (
			ConventionID INTEGER PRIMARY KEY)

		INSERT INTO @tConvTrans21_9
			SELECT 
				U.ConventionID
			FROM Un_Cotisation Ct
			JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			WHERE Ct.OperID = @OperID
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
					I.ConventionID,
					
					-- Solde de la SCEE et SCEE+
					fCESG = SUM(G.fCESG), 
					fACESG = SUM(G.fACESG), 
					
					fCotisationGranted = SUM(G.fCotisationGranted) -- Solde des cotisations subventionnées
				FROM @tConvTrans21_9 I
				JOIN Un_CESP G ON G.ConventionID = I.ConventionID
				GROUP BY I.ConventionID
				) G ON G.ConventionID = C.ConventionID
			LEFT JOIN ( -- Solde SCEE et SCEE+ à rembourser
				SELECT
					I.ConventionID,
					
					-- Solde de la SCEE et SCEE+
					fCESG = SUM(C4.fCESG), 
					fACESGPart = SUM(C4.fACESGPart), 
					
					fCotisationGranted = SUM(C4.fCotisationGranted)
				FROM @tConvTrans21_9 I
				JOIN Un_CESP400 C4 ON C4.ConventionID = I.ConventionID
				LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID
				LEFT JOIN Un_CESP CE ON CE.OperID = C4.OperID
				WHERE C9.iCESP900ID IS NULL
					AND C4.iCESP800ID IS NULL
					AND CE.iCESPID IS NULL
				GROUP BY I.ConventionID
				) C4 ON C4.ConventionID = C.ConventionID
			WHERE Ct.OperID = @OperID
				AND dbo.FN_CRQ_DateNoTime(ISNULL(C.dtRegStartDate,Ct.EffectDate+1)) <= Ct.EffectDate -- Pas dans un compte bloqué
				AND ISNULL(HB.SocialNumber,'') <> ''
				AND Ct.CotisationID NOT IN (
						-- Cotisation qui ont un enregistrement 400 expédié qui est valide.
						SELECT Ct.CotisationID
						FROM Un_Cotisation Ct
						JOIN Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID
						LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
						WHERE Ct.OperID = @OperID
							AND G4.iCESP800ID IS NULL -- Pas revenu en erreur
							AND G4.iReversedCESP400ID IS NULL -- Pas une annulation
							AND R4.iCESP400ID IS NULL -- Pas annulé
						)
	END
	---------------
	-- Type 21-9 BEC --
	---------------
	ELSE IF @tiCESP400TypeID = 21 
			AND @tiCESP400WithdrawReasonID = 9
			AND @OperID > 0
			AND @iTypeRemboursement = 2		-- 2009-11-11 : JFG
	BEGIN
		DECLARE @tConvTrans21_9BEC TABLE (
			ConventionID INTEGER PRIMARY KEY)

		INSERT INTO @tConvTrans21_9BEC
			SELECT 
				U.ConventionID
			FROM Un_Cotisation Ct
			JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			WHERE Ct.OperID = @OperID
			GROUP BY U.ConventionID
		
		INSERT INTO dbo.Un_CESP400 
				(	OperID,
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
					fCotisationGranted 
				)
		SELECT
				Ct.OperID,
				Ct.CotisationID,
				C.ConventionID,
				21,
				9,
				'FIN',
				GETDATE(),
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
				-- Rembourse la totalité du BEC
				-(ISNULL(G.fCLB,0)+ISNULL(C4.fCLB,0)),
				0,
				0,
				0,
				0
		FROM 
			dbo.Un_Cotisation Ct
			INNER JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			INNER JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			INNER JOIN dbo.Un_Plan P ON P.PlanID = C.PlanID
			INNER JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
			INNER JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
			INNER JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
			LEFT OUTER JOIN ( -- Solde de BEC
							SELECT
								I.ConventionID,
								fCLB = SUM(G.fCLB) -- Solde de BEC
							FROM 
								@tConvTrans21_9BEC I
								INNER JOIN dbo.Un_CESP G ON G.ConventionID = I.ConventionID
							GROUP BY I.ConventionID
							) G ON G.ConventionID = C.ConventionID
			LEFT OUTER JOIN ( 
							SELECT
								I.ConventionID,
								fCLB = SUM(C4.fCLB) -- Solde de BEC
							FROM 
								@tConvTrans21_9BEC I
								INNER JOIN dbo.Un_CESP400 C4 ON C4.ConventionID = I.ConventionID
								LEFT OUTER JOIN dbo.Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID
								LEFT OUTER JOIN dbo.Un_CESP CE ON CE.OperID = C4.OperID
							WHERE 
									C9.iCESP900ID IS NULL
									AND C4.iCESP800ID IS NULL
									AND CE.iCESPID IS NULL
							GROUP BY I.ConventionID
								) C4 ON C4.ConventionID = C.ConventionID
		WHERE 
			Ct.OperID = @OperID
			AND dbo.FN_CRQ_DateNoTime(ISNULL(C.dtRegStartDate,Ct.EffectDate+1)) <= Ct.EffectDate -- Pas dans un compte bloqué
			AND ISNULL(HB.SocialNumber,'') <> ''
	/*		AND Ct.CotisationID NOT IN 
									(
											-- Cotisation qui ont un enregistrement 400 expédié qui est valide.
										SELECT Ct.CotisationID
										FROM 
											dbo.Un_Cotisation Ct
											INNER JOIN dbo.Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID
											LEFT OUTER JOIN dbo.Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
										WHERE 
											Ct.OperID = @OperID
											AND G4.iCESP800ID IS NULL -- Pas revenu en erreur
											AND G4.iReversedCESP400ID IS NULL -- Pas une annulation
											AND R4.iCESP400ID IS NULL -- Pas annulé
									)		
	*/
	END
	---------------
	-- Type 21-10 --
	---------------
	ELSE IF @tiCESP400TypeID = 21 
			AND @tiCESP400WithdrawReasonID = 10
			AND @OperID > 0
	BEGIN
		DECLARE @tConvTrans21_10 TABLE (
			ConventionID INTEGER PRIMARY KEY)

		INSERT INTO @tConvTrans21_10
			SELECT 
				U.ConventionID
			FROM Un_Cotisation Ct
			JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			WHERE Ct.OperID = @OperID
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
			WHERE Ct.OperID = @OperID
				AND dbo.FN_CRQ_DateNoTime(ISNULL(C.dtRegStartDate,Ct.EffectDate+1)) <= Ct.EffectDate -- Pas dans un compte bloqué
				AND ISNULL(HB.SocialNumber,'') <> ''
				AND Ct.CotisationID NOT IN (
						-- Cotisation qui ont un enregistrement 400 expédié qui est valide.
						SELECT Ct.CotisationID
						FROM Un_Cotisation Ct
						JOIN Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID
						LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
						WHERE Ct.OperID = @OperID
							AND G4.iCESP800ID IS NULL -- Pas revenu en erreur
							AND G4.iReversedCESP400ID IS NULL -- Pas une annulation
							AND R4.iCESP400ID IS NULL -- Pas annulé
						)
	END
	---------------
	-- Type 21-11 --
	---------------
	ELSE IF @tiCESP400TypeID = 21 
			AND @tiCESP400WithdrawReasonID = 11
			AND @OperID > 0
			AND @iTypeRemboursement = 1		-- 2009-11-11 : JFG
	BEGIN

		DECLARE @tConvTrans21_11 TABLE (
			ConventionID INTEGER PRIMARY KEY)

		INSERT INTO @tConvTrans21_11
			SELECT 
				U.ConventionID
			FROM Un_Cotisation Ct
			JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			WHERE Ct.OperID = @OperID
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
				11,
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
					I.ConventionID,
					
					-- Solde de la SCEE et SCEE+
					fCESG = SUM(G.fCESG), 
					fACESG = SUM(G.fACESG), 
					
					fCotisationGranted = SUM(G.fCotisationGranted) -- Solde des cotisations subventionnées
				FROM @tConvTrans21_11 I
				JOIN Un_CESP G ON G.ConventionID = I.ConventionID
				GROUP BY I.ConventionID
				) G ON G.ConventionID = C.ConventionID
			LEFT JOIN ( -- Solde SCEE et SCEE+ à rembourser
				SELECT
					I.ConventionID,
					
					-- Solde de la SCEE et SCEE+
					fCESG = SUM(C4.fCESG), 
					fACESGPart = SUM(C4.fACESGPart), 
					
					fCotisationGranted = SUM(C4.fCotisationGranted)
				FROM @tConvTrans21_11 I
				JOIN Un_CESP400 C4 ON C4.ConventionID = I.ConventionID
				LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID
				LEFT JOIN Un_CESP CE ON CE.OperID = C4.OperID
				WHERE C9.iCESP900ID IS NULL
					AND C4.iCESP800ID IS NULL
					AND CE.iCESPID IS NULL
				GROUP BY I.ConventionID
				) C4 ON C4.ConventionID = C.ConventionID
			WHERE Ct.OperID = @OperID
				AND dbo.FN_CRQ_DateNoTime(ISNULL(C.dtRegStartDate,Ct.EffectDate+1)) <= Ct.EffectDate -- Pas dans un compte bloqué
				AND ISNULL(HB.SocialNumber,'') <> ''
				AND Ct.CotisationID NOT IN (
						-- Cotisation qui ont un enregistrement 400 expédié qui est valide.
						SELECT Ct.CotisationID
						FROM Un_Cotisation Ct
						JOIN Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID
						LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
						WHERE Ct.OperID = @OperID
							AND G4.iCESP800ID IS NULL -- Pas revenu en erreur
							AND G4.iReversedCESP400ID IS NULL -- Pas une annulation
							AND R4.iCESP400ID IS NULL -- Pas annulé
						)
	END
	-------------------
	-- Type 21-11 BEC --
	-------------------		
	ELSE IF @tiCESP400TypeID = 21 
			AND @tiCESP400WithdrawReasonID = 11
			AND @OperID > 0
			AND @iTypeRemboursement = 2
	BEGIN
		DECLARE @tConvTrans21_11BEC TABLE (ConventionID INT PRIMARY KEY)
		
		INSERT INTO @tConvTrans21_11BEC
		(
			ConventionID
		)
		SELECT
			u.ConventionID
		FROM
			dbo.Un_Cotisation ct
			INNER JOIN dbo.Un_Unit u
				ON u.UnitID= ct.UnitID
		WHERE
			ct.OperID = @OperID
		GROUP BY
			u.ConventionID
		
		INSERT INTO dbo.Un_CESP400 
				(	OperID,
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
					fCotisationGranted 
				)
		SELECT	
			Ct.OperID,
			Ct.CotisationID,
			C.ConventionID,
			21,
			11,
			'FIN',
			GETDATE(),
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
			-- Rembourse la totalité du BEC
			-(ISNULL(G.fCLB,0)+ISNULL(C4.fCLB,0)),
			0,
			0,
			0,
			0
		FROM 
			dbo.Un_Cotisation Ct
			INNER JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			INNER JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			INNER JOIN dbo.Un_Plan P ON P.PlanID = C.PlanID
			INNER JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
			INNER JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
			INNER JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
			LEFT OUTER JOIN ( -- Solde de BEC
							SELECT
								I.ConventionID,
								fCLB = SUM(G.fCLB) -- Solde de BEC
							FROM 
								@tConvTrans21_11BEC I
								INNER JOIN dbo.Un_CESP G ON G.ConventionID = I.ConventionID
							GROUP BY I.ConventionID
							) G ON G.ConventionID = C.ConventionID
			LEFT OUTER JOIN ( 
							SELECT
								I.ConventionID,
								fCLB = SUM(C4.fCLB) -- Solde de BEC
							FROM 
								@tConvTrans21_11BEC I
								INNER JOIN dbo.Un_CESP400 C4 ON C4.ConventionID = I.ConventionID
								LEFT OUTER JOIN dbo.Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID
								LEFT OUTER JOIN dbo.Un_CESP CE ON CE.OperID = C4.OperID
							WHERE 
									C9.iCESP900ID IS NULL
									AND C4.iCESP800ID IS NULL
									AND CE.iCESPID IS NULL
							GROUP BY I.ConventionID
								) C4 ON C4.ConventionID = C.ConventionID
		WHERE 
			Ct.OperID = @OperID
			AND dbo.FN_CRQ_DateNoTime(ISNULL(C.dtRegStartDate,Ct.EffectDate+1)) <= Ct.EffectDate -- Pas dans un compte bloqué
			AND ISNULL(HB.SocialNumber,'') <> ''
	/*		AND Ct.CotisationID NOT IN 
									(
											-- Cotisation qui ont un enregistrement 400 expédié qui est valide.
										SELECT Ct.CotisationID
										FROM 
											dbo.Un_Cotisation Ct
											INNER JOIN dbo.Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID
											LEFT OUTER JOIN dbo.Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
										WHERE 
											Ct.OperID = @OperID
											AND G4.iCESP800ID IS NULL -- Pas revenu en erreur
											AND G4.iReversedCESP400ID IS NULL -- Pas une annulation
											AND R4.iCESP400ID IS NULL -- Pas annulé
									)	
	*/	
	END

	-------------
	-- Type 23 --
	-------------
	ELSE IF @tiCESP400TypeID = 23 AND @OperID > 0
	BEGIN		
		SELECT @CotisationID = MIN(CotisationID)
		FROM Un_Cotisation
		WHERE OperID = @OperID

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
						WHERE Ct.OperID = @OperID
							AND C4.iCESP800ID IS NULL -- Pas revenu en erreur
							AND C9.iCESP900ID IS NULL
							AND C4.iReversedCESP400ID IS NULL -- Pas une annulation
							AND R4.iCESP400ID IS NULL -- Pas annulé
							AND C4.tiCESP400TypeID = 23 -- DU meme type
						)
	END
	-------------
	-- Type 230 -- 23 pour transfert RIO
	-------------
	ELSE IF @tiCESP400TypeID = 230 AND @OperID > 0
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
					iOtherPlanGovRegNumber,
					vcOtherConventionNo,
					fCLB,
					fEAPCLB,
					fPG,
					fEAPPG )
				SELECT
					@OperID,
					CT.CotisationID,
					C.ConventionID,
					23,
					'FIN',
					O.OperDate,
					P.PlanGovernmentRegNo,
					C.ConventionNo,
					ISNULL(HS.SocialNumber,''),
					HB.SocialNumber,
					ISNULL(CT.Cotisation,0)+ISNULL(CT.Fee,0),
					C.bCESGRequested,
					ABS(CE.fCESG + CE.fACESG),
					ABS(CE.fACESG),
					0,
					0,
					0,
					PAUT.PlanGovernmentRegNo,
					CAUT.ConventionNo,
					ABS(CE.fCLB),
					0,
					0,
					0
				FROM tblOper_OperationsRIO OpRIO
				JOIN Un_Oper O ON O.OperID = OpRIO.iID_Oper_RIO
				JOIN Un_CESP CE ON CE.OperID = OpRIO.iID_Oper_RIO AND
								   CE.ConventionID = OpRIO.iID_Convention_Source
				LEFT JOIN Un_Cotisation CT ON CT.CotisationID = CE.CotisationID
				JOIN dbo.Un_Convention C ON C.ConventionID = OpRIO.iID_Convention_Source
				JOIN Un_Plan P ON P.PlanID = C.PlanID
				JOIN dbo.Un_Convention CAUT ON CAUT.ConventionID = OpRIO.iID_Convention_Destination
				JOIN Un_Plan PAUT ON PAUT.PlanID = CAUT.PlanID
				JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID
				JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID			
				WHERE OpRIO.iID_Oper_RIO = @OperID 
					AND NOT EXISTS(
							SELECT *
							FROM Un_CESP400 C4 
							LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = C4.iCESP400ID
							LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID AND C9.tiCESP900OriginID = 3 -- Transaction 900 dont l'origine n'est pas transfert non-réglé
							WHERE C4.OperID = @OperID
								AND C4.ConventionID = CE.ConventionID
								AND C4.CotisationID = CE.CotisationID								
								AND C4.tiCESP400TypeID = 23 -- DU meme type
								
								AND C4.fCESG = ABS(CE.fCESG + CE.fACESG)
								AND C4.fACESGPart = ABS(CE.fACESG)
								
								AND C4.fCLB = ABS(CE.fCLB)
								AND C4.iCESP800ID IS NULL -- Pas revenu en erreur
								AND C4.iReversedCESP400ID IS NULL -- Pas une annulation
								AND C9.iCESP900ID IS NULL
								AND R4.iCESP400ID IS NULL -- Pas annulé
							)
	END

	IF @@ERROR <> 0 
		SET @OperID = -100

	IF @OperID > 0
	BEGIN
		-- Inscrit le vcTransID avec le ID FIN + <iCESP400ID>.
		UPDATE Un_CESP400
		SET vcTransID = 'FIN'+CAST(iCESP400ID AS VARCHAR(12))
		WHERE vcTransID = 'FIN' 

		IF @@ERROR <> 0
			SET @OperID = -101
	END

	RETURN @OperID
END



