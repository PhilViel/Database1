/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	TT_UN_SendCESP400NotSend
Description         :	Envoi les 400 qui n'ont jamais été envoyé et qui devrait l'être car la convention passe les 
								pré-validations.
Valeurs de retours  :	@ReturnValue :
									>0 = Pas d’erreur
									<=0 = Erreur
Note						:	
	ADX0003052	UR	2007-08-31	Bruno Lapointe		Création
	ADX0001228	UP	2007-11-02	Bruno Lapointe		Ne pas tenir compte des FCB annulés ni des FCB d'annulation.
	ADX0001284	UP	2008-02-26	Bruno Lapointe	    Gestion des TFR à envoyer au PCEE.
	ADX0001285	UP	2008-02-26	Bruno Lapointe		Corriger le filtre par dtRegStartDate pour que l'envoi des FCB ce 
													fasse correctement.
					2010-10-14	Frederick Thibault	Ajout du champ fACESGPart pour régler le problème SCEE+
					2013-04-03	Donald Huppé		glpi 9349 : Ajout de l'opération RDI
					2015-01-12	Pierre-Luc Simard	Remplacer la validation du tiCESPState par l'état de la convention REE
					2015-02-17	Donald Huppé	    400-21-1 (RET) : Exclure la raison « RET-erreur administrative »
					2015-03-13	Donald Huppé	    pour les RIN, faire select DISTINCT, sinon il dupplique les 400 selon la qté de groupe d'unité dans la convention
					2017-04-41	Donald Huppé	    Pour la vérification des compte bloqué (1ere clause where de presque chaque cas) vérifier la date du FCB au lieu de dtRegStartDate.
												    Ainsi on évite les cas où le dtRegStartDate est bien avant le FCB (raison inconnu) et qui fait que les CPA fait entre ces 2 dates sont déclarés.
												    Avant cette correction, On gèrait ce cas avec le script de fin de mois "glpi 4982"
                    2018-09-07	Maxime Martel		JIRA MP-699 Ajout de OpertypeID COU
                    2018-10-16  Pierre-Luc Simard   Ajout de la possibilité du ProgramLength à 0 et retrait du CASE pour les négatifs

exec TT_UN_SendCESP400NotSend
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_SendCESP400NotSend]
AS
BEGIN
	CREATE TABLE #LockAccount (
		ConventionID INTEGER PRIMARY KEY,
		dtRegStartDate DATETIME,
		FCBOperID INTEGER,
		DateFCB DATETIME
		)

	-- Recense toutes les conventions en REEE et va chercher la date à laquelle le dernier NAS a été saisie
	-- ainsi que la date ou la convention est entrée en REEE et finalement l'OperID du FCB s'il y en a un
	INSERT INTO #LockAccount	
		SELECT 
			C.ConventionID,
			dbo.Fn_CRQ_DateNoTime(dtRegStartDate),
			FCB.FCBOperID,
			O.OperDate
		FROM dbo.Un_Convention C 
		LEFT JOIN (
			SELECT 
				U.ConventionID,
				FCBOperID = MAX(O.OperID)
			FROM dbo.Un_Unit U
			JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
			JOIN Un_Oper O ON O.OperID = Ct.OperID
			WHERE O.OperTypeID = 'FCB'
				-- Ne tient pas compte des FCB annulés ni des FCB d'annulation.
				AND O.OperID NOT IN (
					SELECT OperID
					FROM Un_OperCancelation
					-----
					UNION
					-----
					SELECT OperSourceID
					FROM Un_OperCancelation
					)
			GROUP BY U.ConventionID
			) FCB ON FCB.ConventionID = C.ConventionID
		LEFT JOIN Un_Oper O on o.OperID = FCB.FCBOperID
		LEFT JOIN (-- Retrouve l'état actuel d'une convention
			SELECT 
				T.ConventionID,
				CCS.ConventionStateID
			FROM (-- Retourne la plus grande date de début d'un état par convention
				SELECT 
					S.ConventionID,
					MaxDate = MAX(S.StartDate)
				FROM Un_ConventionConventionState S
				WHERE S.StartDate <= GETDATE()
				GROUP BY S.ConventionID
				) T
			JOIN Un_ConventionConventionState CCS ON T.ConventionID = CCS.ConventionID AND T.MaxDate = CCS.StartDate -- Retrouve l'état correspondant à la plus grande date par convention
			) CS ON C.ConventionID = CS.ConventionID
		WHERE dtRegStartDate IS NOT NULL
			AND CS.ConventionStateID = 'REE' -- Convention à l'état REEE seulement

	-- CPA, CHQ, PRD, FCB, RDI et COU
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
			HS.SocialNumber,
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
		FROM #LockAccount L
		JOIN dbo.Un_Convention C ON C.ConventionID = L.ConventionID
		JOIN ( -- On s'assure que la convention a déjà été en état REEE : 2017-03-31 : inutile car dans #LockAccount, on a juste les contrat REE actuellement
			SELECT DISTINCT
				CS.ConventionID
			FROM Un_ConventionConventionState CS
			WHERE CS.ConventionStateID = 'REE'
			) CSS ON CSS.ConventionID = C.ConventionID
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
		JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		JOIN Un_Plan P ON P.PlanID = C.PlanID
		JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
		JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
		JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
		LEFT JOIN Un_TFR TFR ON TFR.OperID = O.OperID
		LEFT JOIN Un_OperBankFile OB ON OB.OperID = O.OperID
			-- L'opération n'a pas été faite dans un compte bloqué
		WHERE 
				/*
				( Ct.EffectDate > L.dtRegStartDate
				OR ( Ct.EffectDate = L.dtRegStartDate
					AND Ct.OperID >= ISNULL(L.FCBOperID,Ct.OperID-1)
					)
				)
				*/
				--2017-04-41
				( Ct.EffectDate > COALESCE(L.DateFCB, L.dtRegStartDate)
				OR ( Ct.EffectDate = COALESCE(L.DateFCB, L.dtRegStartDate)
					AND Ct.OperID >= ISNULL(L.FCBOperID,Ct.OperID-1)
					)
				)

			-- Pas une opération de SOBECO
			AND Ct.EffectDate >= '1998-02-01'
			-- Cotisation et frais supérieur à 0.00$
			AND Ct.Cotisation + Ct.Fee > 0
			-- Traite seulement les dépôts
			AND( O.OperTypeID IN ('PRD', 'CHQ', 'CPA', 'FCB', 'RDI', 'COU')
				OR ( O.OperTypeID = 'TFR'
					AND ISNULL(TFR.bSendToPCEE, 0) = 1
					)
				)
			-- Jamais de 400 envoyé
			AND Ct.CotisationID NOT IN (SELECT CotisationID FROM Un_CESP400 WHERE CotisationID IS NOT NULL)
			-- Pas une opération annulée ni une annulation
			AND O.OperID NOT IN (
				SELECT OperSourceID 
				FROM Un_OperCancelation
				-----
				UNION
				-----
				SELECT OperID 
				FROM Un_OperCancelation
				)
			-- Pas revenu en NSF
			AND O.OperID NOT IN (SELECT BankReturnSourceCodeID FROM Mo_BankReturnLink)
			-- Case à cocher "À envoyer au PCEE" cochée
			AND C.bSendToCESP = 1
			-- Passe les pré-validations PCEE
			--AND C.tiCESPState >= 1
			AND ISNULL(HS.SocialNumber,'') <> ''
			AND ISNULL(HB.SocialNumber,'') <> ''
			-- Si c'est un CPA, il n'est pas anticipé.
			AND( O.OperTypeID <> 'CPA'
				OR OB.OperID IS NOT NULL
				OR O.OperDate < '2002-03-15' -- Date du premier fichier de CPA
				)

	-- RIN sans renonciation
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
            IR.ProgramLength, --tiProgramLength
			/*CASE 
				WHEN IR.ProgramLength < 0 THEN 0
			ELSE IR.ProgramLength
			END,*/	--tiProgramLength
			CL.CollegeTypeID,		--cCollegeTypeID
			CL.CollegeCode,		--vcCollegeCode
			IR.ProgramYear,		--siProgramYear
			0,
			0,
			0,
			0,
			Ct.Cotisation+Ct.Fee
		FROM #LockAccount L
		JOIN dbo.Un_Convention C ON C.ConventionID = L.ConventionID
		JOIN ( -- On s'assure que la convention a déjà été en état REEE
			SELECT DISTINCT
				CS.ConventionID
			FROM Un_ConventionConventionState CS
			WHERE CS.ConventionStateID = 'REE'
			) CSS ON CSS.ConventionID = C.ConventionID
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
		JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		JOIN Un_Plan P ON P.PlanID = C.PlanID
		JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
		JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
		JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
		JOIN Un_IntReimbOper IRO ON IRO.OperID = O.OperID
		JOIN Un_IntReimb IR ON IR.IntReimbID = IRO.IntReimbID
		JOIN Un_College CL ON CL.CollegeID = IR.CollegeID
			-- L'opération n'a pas été faite dans un compte bloqué
		WHERE /*( Ct.EffectDate > L.dtRegStartDate
				OR ( Ct.EffectDate = L.dtRegStartDate
					AND Ct.OperID > ISNULL(L.FCBOperID,Ct.OperID-1)
					)
				)*/
				--2017-04-41
				( Ct.EffectDate > COALESCE(L.DateFCB, L.dtRegStartDate)
				OR ( Ct.EffectDate = COALESCE(L.DateFCB, L.dtRegStartDate)
					AND Ct.OperID > ISNULL(L.FCBOperID,Ct.OperID-1)
					)
				)

			-- Pas une opération de SOBECO
			AND Ct.EffectDate >= '1998-02-01'
			-- Cotisation et frais inférieur à 0.00$
			AND Ct.Cotisation + Ct.Fee < 0
			-- Traite seulement les RI
			AND O.OperTypeID = 'RIN'
			-- Traite seulement les RI dont on n'a pas renoncé à la SCEE.
			AND IR.CESGRenonciation = 0
			-- Preuve d'inscription complète
			AND ISNULL(IR.StudyStart,0) > '1965-01-01'
			AND ISNULL(IR.ProgramLength, -1) >= 0 -- On permet maintenant les 0 (Moins d'une année) 
			AND ISNULL(CL.CollegeTypeID,'00') IN ('01','02','03','04')
			AND ISNULL(CL.CollegeCode,'') <> ''
			AND ISNULL(IR.ProgramYear, 0) > 0
			-- Jamais de 400 envoyé
			AND Ct.CotisationID NOT IN (SELECT CotisationID FROM Un_CESP400 WHERE CotisationID IS NOT NULL)
			-- Pas une opération annulée ni une annulation
			AND O.OperID NOT IN (
				SELECT OperSourceID 
				FROM Un_OperCancelation
				-----
				UNION
				-----
				SELECT OperID 
				FROM Un_OperCancelation
				)
			-- Case à cocher "À envoyer au PCEE" cochée
			AND C.bSendToCESP = 1
			-- Passe les pré-validations PCEE
			--AND C.tiCESPState >= 1
			AND ISNULL(HS.SocialNumber,'') <> ''
			AND ISNULL(HB.SocialNumber,'') <> ''

	-- RIN avec renonciation.
	DECLARE @tConvTransRIN TABLE (
		CotisationID INTEGER PRIMARY KEY,
		ConventionID INTEGER,
		EffectDate DATETIME)

	INSERT INTO @tConvTransRIN
		SELECT DISTINCT
			Ct.CotisationID,
			C.ConventionID,
			Ct.EffectDate
		FROM #LockAccount L
		JOIN dbo.Un_Convention C ON C.ConventionID = L.ConventionID
		JOIN ( -- On s'assure que la convention a déjà été en état REEE
			SELECT DISTINCT
				CS.ConventionID
			FROM Un_ConventionConventionState CS
			WHERE CS.ConventionStateID = 'REE'
			) CSS ON CSS.ConventionID = C.ConventionID
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
		JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		JOIN Un_Plan P ON P.PlanID = C.PlanID
		JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
		JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
		JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
		JOIN Un_IntReimbOper IRO ON IRO.OperID = O.OperID
		JOIN Un_IntReimb IR ON IR.IntReimbID = IRO.IntReimbID
		JOIN Un_College Cl ON Cl.CollegeID = IR.CollegeID
			-- L'opération n'a pas été faite dans un compte bloqué
		WHERE /*( Ct.EffectDate > L.dtRegStartDate
				OR ( Ct.EffectDate = L.dtRegStartDate
					AND Ct.OperID > ISNULL(L.FCBOperID,Ct.OperID-1)
					)
				)*/
				--2017-04-41
				( Ct.EffectDate > COALESCE(L.DateFCB, L.dtRegStartDate)
				OR ( Ct.EffectDate = COALESCE(L.DateFCB, L.dtRegStartDate)
					AND Ct.OperID > ISNULL(L.FCBOperID,Ct.OperID-1)
					)
				)

			-- Pas une opération de SOBECO
			AND Ct.EffectDate >= '1998-02-01'
			-- Cotisation et frais inférieur à 0.00$
			AND Ct.Cotisation + Ct.Fee < 0
			-- Traite seulement les RI
			AND O.OperTypeID = 'RIN'
			-- Traite seulement les RI dont on n'a pas renoncé à la SCEE.
			AND IR.CESGRenonciation = 1
			-- Jamais de 400 envoyé
			AND Ct.CotisationID NOT IN (SELECT CotisationID FROM Un_CESP400 WHERE CotisationID IS NOT NULL)
			-- Pas une opération annulée ni une annulation
			AND O.OperID NOT IN (
				SELECT OperSourceID 
				FROM Un_OperCancelation
				-----
				UNION
				-----
				SELECT OperID 
				FROM Un_OperCancelation
				)
			-- Case à cocher "À envoyer au PCEE" cochée
			AND C.bSendToCESP = 1
			-- Passe les pré-validations PCEE
			--AND C.tiCESPState >= 1
			AND ISNULL(HS.SocialNumber,'') <> ''
			AND ISNULL(HB.SocialNumber,'') <> ''

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
		FROM @tConvTransRIN Ct21
		JOIN Un_Cotisation Ct ON Ct.CotisationID = Ct21.CotisationID
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
			FROM @tConvTransRIN I
			JOIN Un_CESP G ON G.ConventionID = I.ConventionID
			JOIN Un_Oper O ON O.OperID = G.OperID
			GROUP BY I.ConventionID
			) G ON G.ConventionID = C.ConventionID
		LEFT JOIN ( -- Solde SCEE et SCEE+ à rembourser
			SELECT
				I.ConventionID,

				-- Solde de la SCEE et SCEE+
				fCESG = SUM(C4.fCESG), 
				fACESGPart = SUM(C4.fACESGPart), 

				fCotisationGranted = SUM(C4.fCotisationGranted)
			FROM @tConvTransRIN I
			JOIN Un_CESP400 C4 ON C4.ConventionID = I.ConventionID
			LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID
			LEFT JOIN Un_CESP CE ON CE.OperID = C4.OperID
			WHERE C9.iCESP900ID IS NULL
				AND C4.iCESP800ID IS NULL
				AND CE.iCESPID IS NULL
			GROUP BY I.ConventionID
			) C4 ON C4.ConventionID = C.ConventionID
		WHERE ISNULL(HB.SocialNumber,'') <> ''

	-- RES et RET
	DECLARE @tConvTrans21_1 TABLE (
		CotisationID INTEGER PRIMARY KEY,
		ConventionID INTEGER,
		EffectDate DATETIME)

	INSERT INTO @tConvTrans21_1
		SELECT DISTINCT
			Ct.CotisationID,
			C.ConventionID,
			Ct.EffectDate
		FROM #LockAccount L
		JOIN dbo.Un_Convention C ON C.ConventionID = L.ConventionID
		JOIN ( -- On s'assure que la convention a déjà été en état REEE
			SELECT DISTINCT
				CS.ConventionID
			FROM Un_ConventionConventionState CS
			WHERE CS.ConventionStateID = 'REE'
			) CSS ON CSS.ConventionID = C.ConventionID
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
		JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		JOIN Un_Plan P ON P.PlanID = C.PlanID
		JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
		JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
		JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID

		LEFT JOIN Un_WithdrawalReason wr on wr.OperID = o.OperID and o.OperTypeID = 'RET'

			-- L'opération n'a pas été faite dans un compte bloqué
		WHERE /*( Ct.EffectDate > L.dtRegStartDate
				OR ( Ct.EffectDate = L.dtRegStartDate
					AND Ct.OperID > ISNULL(L.FCBOperID,Ct.OperID-1)
					)
				)*/
				--2017-04-41
				( Ct.EffectDate > COALESCE(L.DateFCB, L.dtRegStartDate)
				OR ( Ct.EffectDate = COALESCE(L.DateFCB, L.dtRegStartDate)
					AND Ct.OperID > ISNULL(L.FCBOperID,Ct.OperID-1)
					)
				)

			-- Pas une opération de SOBECO
			AND Ct.EffectDate >= '1998-02-01'
			-- Cotisation et frais inférieur à 0.00$
			AND Ct.Cotisation + Ct.Fee < 0
			-- Traite seulement les RET ET RES
			AND O.OperTypeID IN ('RES','RET')
			-- Jamais de 400 envoyé
			AND Ct.CotisationID NOT IN (SELECT CotisationID FROM Un_CESP400 WHERE CotisationID IS NOT NULL)
			-- Pas une opération annulée ni une annulation
			AND O.OperID NOT IN (
				SELECT OperSourceID 
				FROM Un_OperCancelation
				-----
				UNION
				-----
				SELECT OperID 
				FROM Un_OperCancelation
				)
			-- Pas revenu en NSF
			AND O.OperID NOT IN (SELECT BankReturnSourceCodeID FROM Mo_BankReturnLink)
			-- Case à cocher "À envoyer au PCEE" cochée
			AND C.bSendToCESP = 1
			-- Passe les pré-validations PCEE
			--AND C.tiCESPState >= 1
			AND ISNULL(HS.SocialNumber,'') <> ''
			AND ISNULL(HB.SocialNumber,'') <> ''

			-- Exclure la raison « RET-erreur administrative »
			AND ISNULL(wr.tiCESP400WithdrawReasonID,0) <> 12

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
		FROM @tConvTrans21_1 Ct21
		JOIN Un_Cotisation Ct ON Ct.CotisationID = Ct21.CotisationID
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
			JOIN Un_Oper O ON O.OperID = G.OperID
			WHERE O.OperDate < I.EffectDate
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
				AND C4.dtTransaction < I.EffectDate
			GROUP BY I.ConventionID
			) C4 ON C4.ConventionID = C.ConventionID
		WHERE ISNULL(HB.SocialNumber,'') <> ''

	-- Inscrit le vcTransID avec le ID FIN + <iCESP400ID>.
	UPDATE Un_CESP400
	SET vcTransID = 'FIN'+CAST(iCESP400ID AS VARCHAR(12))
	WHERE vcTransID = 'FIN' 

	DROP TABLE #LockAccount
END