/****************************************************************************************************
Copyrights (c) 2014 Gestion Universitas inc
Code du service:	psCONV_EnregistrerPrevalidationPCEE
Nom du service:		Vérifier et mettre à jour les prévalidations des convention pour la SCEE.
But:						Mettre à jour les prévalidations des bénéficiaires, des souscripteurs et des convention, les annexes B, ainsi que les cases pour les demandes au PCEE
Facette:					CONV

Paramètres d’entrée	:	Paramètre						Description
									--------------------------	-----------------------------------------------------------------
		  							ConventionID					Identifiant unique de la convention à traiter. 
									BeneficiaryID					Identifiant unique de la convention à traiter. 
									SubscriberID					Identifiant unique de la convention à traiter. 																		

Exemple d’appel:	EXEC psCONV_EnregistrerPrevalidationPCEE 2, 378750, NULL, NULL, NULL		-- Convention
							EXEC psCONV_EnregistrerPrevalidationPCEE 2, NULL, 601618, NULL, NULL		-- Bénéficiaire
							EXEC psCONV_EnregistrerPrevalidationPCEE 2, NULL, NULL, 601617, NULL		-- Souscripteur
							EXEC psCONV_EnregistrerPrevalidationPCEE 2, NULL, NULL, NULL, 601617		-- Tuteur
							EXEC psCONV_EnregistrerPrevalidationPCEE 2, NULL, NULL, NULL, NULL			-- Tous

Paramètres de sortie:		Table						Champ							Description
		  							-------------------------	--------------------------- 	---------------------------------
									S/O							iCode_Retour					Code de retour standard

Historique des modifications:
						2014-10-30	Pierre-Luc Simard		Création du service
						2014-11-11	Pierre-Luc Simard		Ajout de la gestion du BEC
						2014-11-26	Pierre-Luc Simard		Pré-validations de la convention à 0 si pas REE
						2015-01-09	Pierre-Luc Simard		Annexe B requise si l'ID du tuteur est différent du souscripteur
																			Annexe B requise si le NAS du responsable est différent du souscripteur
						2015-02-02	Pierre-Luc Simard		Appel de la psPCEE_ForcerDemandeCotisation pour mettre à jour les demandes
						2015-09-18	Pierre-Luc Simard		Ne plus journaliser le champ bFormulaireRecu
						2015-09-22	Pierre-Luc Simard		Valider l'annexe B du responsable pour la SCEE+ 
                              2016-10-18     Steeve Picard            Utilisation de la fonction «fntGENE_ObtenirAdresseEnDate_PourTous»
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_EnregistrerPrevalidationPCEE] (
	@ConnectID AS INT = NULL, 
	@ConventionID AS INT = NULL,
	@BeneficiaryID AS INT = NULL,
	@SubscriberID AS INT = NULL,
	@TutorID AS INT = NULL) 
AS
BEGIN
/*
DROP TABLE #tConv -- À retirer
DROP TABLE #tBenef-- À retirer
DROP TABLE #tSousc-- À retirer

DECLARE -- À retirer		
	@ConnectID AS INT, -- À retirer
	@ConventionID AS INT, -- À retirer
	@BeneficiaryID AS INT, -- À retirer
	@SubscriberID AS INT, -- À retirer
	@TutorID AS INT -- À retirer

--SET @ConventionID = 378750 -- À retirer
--SET @BeneficiaryID = 601618 -- À retirer
--SET @BeneficiaryID = 212074 -- À retirer
--SET @SubscriberID = 601617 -- À retirer
SET @TutorID = 601617 -- À retirer
*/
	IF @ConnectID IS NULL
		SET @ConnectID = 2

	DECLARE 
		@Result INT,
		@cSep CHAR(1)
			
	SET @Result = 1
	SET @cSep = CHAR(30)

	------------------------
	BEGIN TRANSACTION
	------------------------
	
	SELECT	
		C.ConventionID,
		C.ConventionNo,
		C.BeneficiaryID,
		C.SubscriberID,
		CSS.ConventionStateID,
		C.bFormulaireRecu,
		C.bCESGRequested,
		C.bACESGRequested,
		C.bCLBRequested,
		CtiCESPState = C.tiCESPState,
		BtiCESPState = B.tiCESPState,
		StiCESPState = S.tiCESPState,
		C.SCEEFormulaire93Recu,
		C.SCEEFormulaire93SCEERefusee,
		C.SCEEFormulaire93SCEEPlusRefusee,
		C.SCEEFormulaire93BECRefuse,
		C.SCEEAnnexeBTuteurRequise,
		C.SCEEAnnexeBTuteurRecue,
		C.SCEEAnnexeBPRespRequise,
		C.SCEEAnnexeBPRespRecue,
		SLastName = SH.LastName,
		SFirstName = SH.FirstName,
		SSocialNumber = SH.SocialNumber,
		B.iTutorID, 
		B.bTutorIsSubscriber,
		TSocialNumber = ISNULL(TuH.SocialNumber, Tu.vcEN),
		TLastName = TuH.LastName, 
		TFirstName = TuH.FirstName,
		B.bPCGIsSubscriber,
		B.vcPCGSINorEN,
		B.vcPCGFirstName,
		B.vcPCGLastName,
		B.tiPCGType
	INTO #tConv
	FROM (
		SELECT DISTINCT
			C.ConventionID
		FROM dbo.Un_Convention C
		JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
		WHERE (C.ConventionID = @ConventionID
			OR C.BeneficiaryID = @BeneficiaryID
			OR C.SubscriberID = @SubscriberID
			OR B.iTutorID = @TutorID
			OR COALESCE(@ConventionID, @BeneficiaryID, @SubscriberID, @TutorID) IS NULL) -- Aucun paramètre donc on traite toutes les conventions
		) CV
	JOIN dbo.Un_Convention C ON C.ConventionID = CV.ConventionID
	JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
	JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
	JOIN dbo.Mo_Human SH ON SH.HumanID = S.SubscriberID
	LEFT JOIN Un_Tutor Tu ON Tu.iTutorID = B.iTutorID
	LEFT JOIN dbo.Mo_Human TuH ON TuH.HumanID = B.iTutorID
	LEFT JOIN (
		SELECT
			CS.ConventionID ,
			CCS.StartDate ,
			CS.ConventionStateID
		FROM Un_ConventionConventionState CS
		JOIN (
			SELECT
				ConventionID ,
				StartDate = MAX(StartDate)
			FROM Un_ConventionConventionState
			--WHERE StartDate < DATEADD(d, 1, GETDATE())
			GROUP BY ConventionID
			 ) CCS ON CCS.ConventionID = CS.ConventionID
				AND CCS.StartDate = CS.StartDate 
		) CSS on C.ConventionID = CSS.ConventionID
	WHERE (C.ConventionID = @ConventionID
			OR C.BeneficiaryID = @BeneficiaryID
			OR C.SubscriberID = @SubscriberID
			OR COALESCE(@ConventionID, @BeneficiaryID, @SubscriberID) IS NULL) -- Aucun paramètre donc on traite toutes les conventions
		AND CSS.ConventionStateID <> 'FRM'

	SELECT 
		B.BeneficiaryID,
		B.BtiCESPState
	INTO #tBenef
	FROM (
		SELECT
			B.BeneficiaryID,
			BtiCESPState = B.tiCESPState
		FROM dbo.Un_Beneficiary B
		WHERE B.BeneficiaryID = @BeneficiaryID
			OR B.iTutorID = @TutorID
		UNION 
		SELECT DISTINCT
			TC.BeneficiaryID,
			TC.BtiCESPState
		FROM #tConv TC
		WHERE TC.BeneficiaryID <> ISNULL(@BeneficiaryID,0)
		) B

	SELECT 
		S.SubscriberID,
		S.StiCESPState
	INTO #tSousc
	FROM (
		SELECT
			S.SubscriberID,
			StiCESPState = S.tiCESPState
		FROM dbo.Un_Subscriber S
		WHERE S.SubscriberID = @SubscriberID
		UNION 
		SELECT DISTINCT
			TC.SubscriberID,
			TC.StiCESPState
		FROM #tConv TC
		WHERE TC.SubscriberID <> ISNULL(@SubscriberID,0)
		) S
		
	--SELECT * FROM #tBenef TB

	IF @@ERROR <> 0
			SET @Result = -1
	
	IF @Result = 1
	BEGIN 
		-- Désactiver les triggers
		IF object_id('tempdb..#DisableTrigger') is null
					CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))
			INSERT INTO #DisableTrigger VALUES('TR_U_Un_Convention_F_dtRegStartDate')		
			INSERT INTO #DisableTrigger VALUES('TUn_Convention')		
			INSERT INTO #DisableTrigger VALUES('TUn_Convention_YearQualif')
			INSERT INTO #DisableTrigger VALUES('TUn_Beneficiary')		
			INSERT INTO #DisableTrigger VALUES('TUn_Subscriber')
	END
    
	--SELECT * FROM #tConv TC

	-- Mise à jour des pré-validations du bénéficiaire
	IF @Result = 1
	BEGIN
        UPDATE B SET  --SELECT
			tiCESPState =	CASE  
										WHEN NAS = 1 AND Tuteur = 1 AND ResidentCanada = 1 AND PrincipalResponsable = 1 AND DateNaissanceBEC = 1 THEN 4
										WHEN NAS = 1 AND Tuteur = 1 AND ResidentCanada = 1 AND PrincipalResponsable = 1 THEN 3
										-- WHEN NAS = 1 AND Tuteur = 1 AND ResidentCanada = 1 AND PrincipalResponsable = 1 AND DateNaissanceBEC = 1 THEN 2 -- Impossible
										WHEN NAS = 1 AND Tuteur = 1 AND ResidentCanada = 1 THEN 1
										ELSE 0 
									END/*,
			VB.*,
			B.*   */ 
		FROM dbo.Un_Beneficiary B
		JOIN (
			SELECT 
				B.BeneficiaryID,
				NAS = CASE WHEN dbo.FN_CRI_CheckSin(ISNULL(HB.SocialNumber, ''), HB.IsCompany) = 1 THEN 1 ELSE 0 END, -- Le NAS doit être valide
				Tuteur = CASE WHEN ISNULL(B.iTutorID, 0) <> 0 THEN 1 ELSE 0 END,
				ResidentCanada = CASE WHEN A.cID_Pays = 'CAN' OR A.bResidenceFaitCanada = 1 THEN 1 ELSE 0 END, 
				PrincipalResponsable =	CASE WHEN 
														LTRIM(RTRIM(ISNULL(B.vcPCGLastName, ''))) <> ''
														AND CASE WHEN B.tiPCGType = 1 THEN LTRIM(RTRIM(ISNULL(B.vcPCGFirstName, ''))) ELSE 'Entreprise' END <> ''
														AND ((B.tiPCGType = 2 AND dbo.fnGENE_ValiderNE(ISNULL(B.vcPCGSINorEN,'')) = 1) OR (B.tiPCGType = 1 AND dbo.FN_CRI_CheckSin(ISNULL(B.vcPCGSINorEN, ''), 0) = 1))
													THEN 1 ELSE 0 END,
				DateNaissanceBEC = CASE WHEN ISNULL(HB.BirthDate, '1950-01-01') > '2003-12-31' THEN 1 ELSE 0 END
			FROM dbo.Un_Beneficiary B
			    JOIN #tBenef TB ON TB.BeneficiaryID = B.BeneficiaryID
			    JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
                   JOIN dbo.fntGENE_ObtenirAdresseEnDate_PourTous(DEFAULT, DEFAULT, GETDATE(), DEFAULT) A ON A.iID_Source = B.BeneficiaryID
			) VB ON VB.BeneficiaryID = B.BeneficiaryID
		WHERE B.tiCESPState <> 
									CASE  
										WHEN NAS = 1 AND Tuteur = 1 AND ResidentCanada = 1 AND PrincipalResponsable = 1 AND DateNaissanceBEC = 1 THEN 4
										WHEN NAS = 1 AND Tuteur = 1 AND ResidentCanada = 1 AND PrincipalResponsable = 1 THEN 3
										-- WHEN NAS = 1 AND Tuteur = 1 AND ResidentCanada = 1 AND PrincipalResponsable = 1 AND DateNaissanceBEC = 1 THEN 2 -- Impossible
										WHEN NAS = 1 AND Tuteur = 1 AND ResidentCanada = 1 THEN 1
										ELSE 0 
									END
			
		IF @@ERROR <> 0
				SET @Result = -2
	END
        
	-- Mise à jour des pré-validations du souscripteur
	IF @Result = 1
	BEGIN
		UPDATE S SET  --SELECT
			tiCESPState =	CASE WHEN NAS = 1 THEN 1 ELSE 0 END/*,
			VS.*,
			S.*    */
		FROM dbo.Un_Subscriber S
		JOIN (
			SELECT 
				S.SubscriberID,
				NAS = CASE WHEN dbo.FN_CRI_CheckSin(ISNULL(HS.SocialNumber, ''), HS.IsCompany) = 1 THEN 1 ELSE 0 END -- Le NAS doit être valide
			FROM dbo.Un_Subscriber S
			JOIN dbo.Mo_Human HS ON HS.HumanID = S.SubscriberID
			JOIN #tSousc TS ON TS.SubscriberID = S.SubscriberID
			) VS ON VS.SubscriberID = S.SubscriberID
		WHERE S.tiCESPState <> CASE WHEN NAS = 1 THEN 1 ELSE 0 END
		
		IF @@ERROR <> 0
			SET @Result = -3
	END

	IF @Result = 1
		AND EXISTS (SELECT TOP 1 ConventionID FROM #tConv TC) -- Vérifie si si au moins une convention est dans la table
	BEGIN
		-- Mise à jour des cases indiquant si les annexes B sont requises pour le tuteur et le principal responsable
		UPDATE C SET 
			SCEEAnnexeBTuteurRequise =	CASE WHEN -- La case se coche si les infos du souscripteur sont différentes des infos du tuteur
															TC.SubscriberID <> ISNULL(TC.iTutorID, 0) 
														THEN 1 ELSE 0 END,
			SCEEAnnexeBTuteurRecue =	CASE WHEN -- La case se décoche si les infos du souscripteur sont identiques aux infos du tuteur
															TC.SubscriberID = ISNULL(TC.iTutorID, 0)
														THEN 0 ELSE TC.SCEEAnnexeBTuteurRecue END,
			SCEEAnnexeBPRespRequise =	CASE WHEN -- La case se coche si les infos du souscripteur sont différentes des infos du principal responsable
															ISNULL(TC.SSocialNumber, 'NULL') <> ISNULL(TC.vcPCGSINorEN, '')
														THEN 1 ELSE 0 END,
			SCEEAnnexeBPRespRecue =	CASE WHEN -- La case se décoche si les infos du souscripteur sont identiques aux infos du principal responsable
															ISNULL(TC.SSocialNumber, 'NULL') = ISNULL(TC.vcPCGSINorEN, '')
														THEN 0 ELSE TC.SCEEAnnexeBPRespRecue END
		FROM dbo.Un_Convention C
		JOIN #tConv TC ON TC.ConventionID = C.ConventionID
		WHERE -- On met à jour la convention unqiuement si le résultat est différent des valeurs existantes
			(ISNULL(TC.SCEEAnnexeBTuteurRequise, 0) 
				<>	CASE WHEN (
							TC.SubscriberID <> ISNULL(TC.iTutorID, 0)
							) 
						THEN 1 ELSE 0 END
				OR ISNULL(TC.SCEEAnnexeBPRespRequise, 0) 
					<>	CASE WHEN ( 
								ISNULL(TC.SSocialNumber, 'NULL') <> ISNULL(TC.vcPCGSINorEN, ''))
							THEN 1 ELSE 0 END)
		
		IF @@ERROR <> 0
			SET @Result = -4
	
		-- Mise à jour des pré-validations de la convention
		IF @Result = 1
		BEGIN
			UPDATE C SET --SELECT
				tiCESPState = CASE 
										WHEN -- SCEE, SCEE+ et BEC (4)
											S.tiCESPState > 0 
											AND B.tiCESPState = 4 
											AND C.SCEEFormulaire93Recu = 1 
											AND CASE WHEN C.SCEEAnnexeBTuteurRequise = 1 THEN C.SCEEAnnexeBTuteurRecue ELSE 1 END = 1 
											AND CASE WHEN C.SCEEAnnexeBPRespRequise = 1 THEN C.SCEEAnnexeBPRespRecue ELSE 1 END = 1 
											AND TC.ConventionStateID = 'REE'
										THEN 4 
										WHEN -- SCEE et SCEE+ (3)
											S.tiCESPState > 0 
											AND B.tiCESPState = 3 
											AND C.SCEEFormulaire93Recu = 1 
											AND CASE WHEN C.SCEEAnnexeBTuteurRequise = 1 THEN C.SCEEAnnexeBTuteurRecue ELSE 1 END = 1 
											AND CASE WHEN C.SCEEAnnexeBPRespRequise = 1 THEN C.SCEEAnnexeBPRespRecue ELSE 1 END = 1 
											AND TC.ConventionStateID = 'REE'
										THEN 3 
										WHEN -- SCEE et BEC (2)
											S.tiCESPState > 0 
											AND B.tiCESPState = 2 
											AND C.SCEEFormulaire93Recu = 1 
											AND CASE WHEN C.SCEEAnnexeBTuteurRequise = 1 THEN C.SCEEAnnexeBTuteurRecue ELSE 1 END = 1 
											AND CASE WHEN C.SCEEAnnexeBPRespRequise = 1 THEN C.SCEEAnnexeBPRespRecue ELSE 1 END = 1 
											AND TC.ConventionStateID = 'REE'
										THEN 2
										WHEN -- SCEE (1)
											S.tiCESPState > 0 
											AND B.tiCESPState > 0
											AND C.SCEEFormulaire93Recu = 1 
											AND CASE WHEN C.SCEEAnnexeBTuteurRequise = 1 THEN C.SCEEAnnexeBTuteurRecue ELSE 1 END = 1 
											AND TC.ConventionStateID = 'REE'
										THEN 1  
									ELSE 0 END/*,
				TC.*,
				C.*    */
			FROM dbo.Un_Convention C
			JOIN #tConv TC ON TC.ConventionID = C.ConventionID
			JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
			JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
			WHERE C.tiCESPState <> CASE 
													WHEN -- SCEE, SCEE+ et BEC (4)
														S.tiCESPState > 0 
														AND B.tiCESPState = 4 
														AND C.SCEEFormulaire93Recu = 1 
														AND CASE WHEN C.SCEEAnnexeBTuteurRequise = 1 THEN C.SCEEAnnexeBTuteurRecue ELSE 1 END = 1 
														AND CASE WHEN C.SCEEAnnexeBPRespRequise = 1 THEN C.SCEEAnnexeBPRespRecue ELSE 1 END = 1 
														AND TC.ConventionStateID = 'REE'
													THEN 4 
													WHEN -- SCEE et SCEE+ (3)
														S.tiCESPState > 0 
														AND B.tiCESPState = 3 
														AND C.SCEEFormulaire93Recu = 1 
														AND CASE WHEN C.SCEEAnnexeBTuteurRequise = 1 THEN C.SCEEAnnexeBTuteurRecue ELSE 1 END = 1 
														AND CASE WHEN C.SCEEAnnexeBPRespRequise = 1 THEN C.SCEEAnnexeBPRespRecue ELSE 1 END = 1 
														AND TC.ConventionStateID = 'REE'
													THEN 3 
													WHEN -- SCEE et BEC (2)
														S.tiCESPState > 0 
														AND B.tiCESPState = 2 
														AND C.SCEEFormulaire93Recu = 1 
														AND CASE WHEN C.SCEEAnnexeBTuteurRequise = 1 THEN C.SCEEAnnexeBTuteurRecue ELSE 1 END = 1 
														AND CASE WHEN C.SCEEAnnexeBPRespRequise = 1 THEN C.SCEEAnnexeBPRespRecue ELSE 1 END = 1 
														AND TC.ConventionStateID = 'REE'
													THEN 2
													WHEN -- SCEE (1)
														S.tiCESPState > 0 
														AND B.tiCESPState > 0
														AND C.SCEEFormulaire93Recu = 1 
														AND CASE WHEN C.SCEEAnnexeBTuteurRequise = 1 THEN C.SCEEAnnexeBTuteurRecue ELSE 1 END = 1 
														AND TC.ConventionStateID = 'REE'
													THEN 1  
												ELSE 0 END
			
			IF @@ERROR <> 0
				SET @Result = -5
		END 

		-- Mise à jour de la case bFormulaire reçu
		IF @Result = 1
		BEGIN
			UPDATE C SET  --SELECT
				bFormulaireRecu = CASE WHEN
													C.SCEEFormulaire93Recu = 1 
													AND CASE WHEN C.SCEEAnnexeBTuteurRequise = 1 THEN C.SCEEAnnexeBTuteurRecue ELSE 1 END = 1 
													THEN 1 
												ELSE 0 END/*,
				TC.*,
				C.*    */
			FROM dbo.Un_Convention C
			JOIN #tConv TC ON TC.ConventionID = C.ConventionID
			WHERE C.bFormulaireRecu <> CASE WHEN
															C.SCEEFormulaire93Recu = 1 
															AND CASE WHEN C.SCEEAnnexeBTuteurRequise = 1 THEN C.SCEEAnnexeBTuteurRecue ELSE 1 END = 1
														THEN 1 ELSE 0 END
			
			IF @@ERROR <> 0
				SET @Result = -6
		END
	
		-- Mise à jour de la case pour les demandes au PCEE
		IF @Result = 1
		BEGIN
			UPDATE C SET 
				bCESGRequested = CASE WHEN C.tiCESPState > 0 
												AND C.SCEEFormulaire93SCEERefusee = 0 THEN 1 ELSE 0 END,
				bACESGRequested = CASE WHEN C.tiCESPState > 2 
																AND C.SCEEFormulaire93SCEEPlusRefusee = 0 THEN 1 ELSE 0 END,
				bCLBRequested = CASE WHEN C.tiCESPState IN (2, 4) 
																AND (dbo.fnCONV_ObtenirConventionBEC(C.BeneficiaryID, 0, NULL) = C.ConventionID 
																	OR (ISNULL(dbo.fnCONV_ObtenirConventionBEC(C.BeneficiaryID, 0, NULL), 0) < 1
																			AND dbo.fnCONV_ObtenirConventionBEC(C.BeneficiaryID, 1, NULL) = C.ConventionID)) 
																AND C.SCEEFormulaire93BECRefuse = 0 THEN 1 ELSE 0 END/*, 
				--C.bSendToCESP = 1,
				TC.*,
				C.*    */
			FROM dbo.Un_Convention C
			JOIN #tConv TC ON TC.ConventionID = C.ConventionID
			--WHERE bSendToCESP <> 1
			WHERE	(C.bCESGRequested <> CASE WHEN C.tiCESPState > 0 
																				AND C.SCEEFormulaire93SCEERefusee = 0 THEN 1 ELSE 0 END
				OR C.bACESGRequested <> CASE WHEN C.tiCESPState > 2 
																			AND C.SCEEFormulaire93SCEEPlusRefusee = 0 THEN 1 ELSE 0 END
				OR C.bCLBRequested <> CASE WHEN C.tiCESPState IN (2, 4) 
																		AND (dbo.fnCONV_ObtenirConventionBEC(C.BeneficiaryID, 0, NULL) = C.ConventionID 
																			OR (ISNULL(dbo.fnCONV_ObtenirConventionBEC(C.BeneficiaryID, 0, NULL), 0) < 1
																				AND dbo.fnCONV_ObtenirConventionBEC(C.BeneficiaryID, 1, NULL) = C.ConventionID)) 
																		AND C.SCEEFormulaire93BECRefuse = 0 THEN 1 ELSE 0 END)
		
			IF @@ERROR <> 0
				SET @Result = -7
		END

		-- Réactiver les triggers
		DELETE #DisableTrigger where vcTriggerName = 'TR_U_Un_Convention_F_dtRegStartDate'
		DELETE #DisableTrigger where vcTriggerName = 'TUn_Convention'
		DELETE #DisableTrigger where vcTriggerName = 'TUn_Convention_YearQualif'
		DELETE #DisableTrigger where vcTriggerName = 'TUn_Beneficiary'			
		DELETE #DisableTrigger where vcTriggerName = 'TUn_Subscriber'

		-- Insertion du log sur les conventions modifiées
		INSERT INTO CRQ_Log (
				ConnectID,
				LogTableName,
				LogCodeID,
				LogTime,
				LogActionID,
				LogDesc,
				LogText)
				SELECT
					@ConnectID,
					'Un_Convention',
					C.ConventionID,
					GETDATE(),
					LA.LogActionID,
					LogDesc = 'Convention : ' + C.ConventionNo,
					LogText =
						CASE 
							WHEN ISNULL(COld.SCEEAnnexeBTuteurRequise,1) <> ISNULL(C.SCEEAnnexeBTuteurRequise,0) THEN
								'SCEEAnnexeBTuteurRequise'+@cSep+
								CAST(ISNULL(COld.SCEEAnnexeBTuteurRequise,1) AS VARCHAR)+@cSep+
								CAST(ISNULL(C.SCEEAnnexeBTuteurRequise,1) AS VARCHAR)+@cSep+
								CASE 
									WHEN ISNULL(COld.SCEEAnnexeBTuteurRequise,1) = 0 THEN 'Non'
								ELSE 'Oui'
								END+@cSep+
								CASE 
									WHEN ISNULL(C.SCEEAnnexeBTuteurRequise,1) = 0 THEN 'Non'
								ELSE 'Oui'
								END+@cSep+
								CHAR(13)+CHAR(10)
						ELSE ''
						END+
						CASE 
							WHEN ISNULL(COld.SCEEAnnexeBTuteurRecue,1) <> ISNULL(C.SCEEAnnexeBTuteurRecue,0) THEN
								'SCEEAnnexeBTuteurRecue'+@cSep+
								CAST(ISNULL(COld.SCEEAnnexeBTuteurRecue,1) AS VARCHAR)+@cSep+
								CAST(ISNULL(C.SCEEAnnexeBTuteurRecue,1) AS VARCHAR)+@cSep+
								CASE 
									WHEN ISNULL(COld.SCEEAnnexeBTuteurRecue,1) = 0 THEN 'Non'
								ELSE 'Oui'
								END+@cSep+
								CASE 
									WHEN ISNULL(C.SCEEAnnexeBTuteurRecue,1) = 0 THEN 'Non'
								ELSE 'Oui'
								END+@cSep+
								CHAR(13)+CHAR(10)
						ELSE ''
						END+
						CASE 
							WHEN ISNULL(COld.SCEEAnnexeBPRespRequise,1) <> ISNULL(C.SCEEAnnexeBPRespRequise,0) THEN
								'SCEEAnnexeBPRespRequise'+@cSep+
								CAST(ISNULL(COld.SCEEAnnexeBPRespRequise,1) AS VARCHAR)+@cSep+
								CAST(ISNULL(C.SCEEAnnexeBPRespRequise,1) AS VARCHAR)+@cSep+
								CASE 
									WHEN ISNULL(COld.SCEEAnnexeBPRespRequise,1) = 0 THEN 'Non'
								ELSE 'Oui'
								END+@cSep+
								CASE 
									WHEN ISNULL(C.SCEEAnnexeBPRespRequise,1) = 0 THEN 'Non'
								ELSE 'Oui'
								END+@cSep+
								CHAR(13)+CHAR(10)
						ELSE ''
						END+
						CASE 
							WHEN ISNULL(COld.SCEEAnnexeBPRespRecue,1) <> ISNULL(C.SCEEAnnexeBPRespRecue,0) THEN
								'SCEEAnnexeBPRespRecue'+@cSep+
								CAST(ISNULL(COld.SCEEAnnexeBPRespRecue,1) AS VARCHAR)+@cSep+
								CAST(ISNULL(C.SCEEAnnexeBPRespRecue,1) AS VARCHAR)+@cSep+
								CASE 
									WHEN ISNULL(COld.SCEEAnnexeBPRespRecue,1) = 0 THEN 'Non'
								ELSE 'Oui'
								END+@cSep+
								CASE 
									WHEN ISNULL(C.SCEEAnnexeBPRespRecue,1) = 0 THEN 'Non'
								ELSE 'Oui'
								END+@cSep+
								CHAR(13)+CHAR(10)
						ELSE ''
						END+
						CASE 
							WHEN ISNULL(COld.CtiCESPState,1) <> ISNULL(C.tiCESPState,0) THEN
								'tiCESPState'+@cSep
												+CAST(ISNULL(COld.CtiCESPState,0) AS VARCHAR)+@cSep+
												+CAST(ISNULL(C.tiCESPState,0) AS VARCHAR)+@cSep+
								CASE ISNULL(COld.CtiCESPState,0)
									WHEN 1 THEN 'SCEE'
									WHEN 2 THEN 'SCEE et BEC'
									WHEN 3 THEN 'SCEE et SCEE+'
									WHEN 4 THEN 'SCEE, SCEE+ et BEC'
								ELSE ''
								END+@cSep+
								CASE ISNULL(C.tiCESPState,0)
									WHEN 1 THEN 'SCEE'
									WHEN 2 THEN 'SCEE et BEC'
									WHEN 3 THEN 'SCEE et SCEE+'
									WHEN 4 THEN 'SCEE, SCEE+ et BEC'
								ELSE ''
								END+@cSep+CHAR(13)+CHAR(10)
						ELSE ''
						END+
						/*CASE 
							WHEN ISNULL(COld.bFormulaireRecu,1) <> ISNULL(C.bFormulaireRecu,0) THEN
								'bFormulaireRecu'+@cSep+
								CAST(ISNULL(COld.bFormulaireRecu,1) AS VARCHAR)+@cSep+
								CAST(ISNULL(C.bFormulaireRecu,1) AS VARCHAR)+@cSep+
								CASE 
									WHEN ISNULL(COld.bFormulaireRecu,1) = 0 THEN 'Non'
								ELSE 'Oui'
								END+@cSep+
								CASE 
									WHEN ISNULL(C.bFormulaireRecu,1) = 0 THEN 'Non'
								ELSE 'Oui'
								END+@cSep+
								CHAR(13)+CHAR(10)
						ELSE ''
						END+	*/
						CASE 
							WHEN ISNULL(COld.bCESGRequested,1) <> ISNULL(C.bCESGRequested,0) THEN
								'bCESGRequested'+@cSep+
								CAST(ISNULL(COld.bCESGRequested,1) AS VARCHAR)+@cSep+
								CAST(ISNULL(C.bCESGRequested,1) AS VARCHAR)+@cSep+
								CASE 
									WHEN ISNULL(COld.bCESGRequested,1) = 0 THEN 'Non'
								ELSE 'Oui'
								END+@cSep+
								CASE 
									WHEN ISNULL(C.bCESGRequested,1) = 0 THEN 'Non'
								ELSE 'Oui'
								END+@cSep+
								CHAR(13)+CHAR(10)
						ELSE ''
						END+
						CASE 
							WHEN ISNULL(COld.bACESGRequested,1) <> ISNULL(C.bACESGRequested,0) THEN
								'bACESGRequested'+@cSep+
								CAST(ISNULL(COld.bACESGRequested,1) AS VARCHAR)+@cSep+
								CAST(ISNULL(C.bACESGRequested,1) AS VARCHAR)+@cSep+
								CASE 
									WHEN ISNULL(COld.bACESGRequested,1) = 0 THEN 'Non'
								ELSE 'Oui'
								END+@cSep+
								CASE 
									WHEN ISNULL(C.bACESGRequested,1) = 0 THEN 'Non'
								ELSE 'Oui'
								END+@cSep+
								CHAR(13)+CHAR(10)
						ELSE ''
						END+
						CASE 
							WHEN ISNULL(COld.bCLBRequested,1) <> ISNULL(C.bCLBRequested,0) THEN
								'bCLBRequested'+@cSep+
								CAST(ISNULL(COld.bCLBRequested,1) AS VARCHAR)+@cSep+
								CAST(ISNULL(C.bCLBRequested,1) AS VARCHAR)+@cSep+
								CASE 
									WHEN ISNULL(COld.bCLBRequested,1) = 0 THEN 'Non'
								ELSE 'Oui'
								END+@cSep+
								CASE 
									WHEN ISNULL(C.bCLBRequested,1) = 0 THEN 'Non'
								ELSE 'Oui'
								END+@cSep+
								CHAR(13)+CHAR(10)
						ELSE ''
						END
					FROM #tConv COld 
					JOIN dbo.Un_Convention C ON C.ConventionID = COld.ConventionID
					JOIN CRQ_LogAction LA ON LA.LogActionShortName = 'U'
					WHERE ISNULL(COld.SCEEAnnexeBTuteurRequise, 0) <> ISNULL(C.SCEEAnnexeBTuteurRequise,0)
						OR ISNULL(COld.SCEEAnnexeBTuteurRecue, 0) <> ISNULL(C.SCEEAnnexeBTuteurRecue,0)
						OR ISNULL(COld.SCEEAnnexeBPRespRequise, 0) <> ISNULL(C.SCEEAnnexeBPRespRequise,0)
						OR ISNULL(COld.SCEEAnnexeBPRespRecue, 0) <> ISNULL(C.SCEEAnnexeBPRespRecue,0)
						OR ISNULL(COld.CtiCESPState, 0) <> ISNULL(C.tiCESPState,0)
						OR ISNULL(COld.bFormulaireRecu, 0) <> ISNULL(C.bFormulaireRecu,0)
						OR ISNULL(COld.bCESGRequested, 0) <> ISNULL(C.bCESGRequested,0)
						OR ISNULL(COld.bACESGRequested, 0) <> ISNULL(C.bACESGRequested,0)
						OR ISNULL(COld.bCLBRequested, 0) <> ISNULL(C.bCLBRequested,0)

			IF @@ERROR <> 0
				SET @Result = -8

			-- Insertion du log sur les bénéficiaires modifiés
			INSERT INTO CRQ_Log (
					ConnectID,
					LogTableName,
					LogCodeID,
					LogTime,
					LogActionID,
					LogDesc,
					LogText)
					SELECT
						@ConnectID,
						'Un_Beneficiary',
						B.BeneficiaryID,
						GETDATE(),
						LA.LogActionID,
						LogDesc = 'Bénéficiaire : ' + H.LastName + ', ' + H.FirstName,
						LogText = 
							CASE 
								WHEN ISNULL(BOld.BtiCESPState,1) <> ISNULL(B.tiCESPState,0) THEN
									'tiCESPState'+@cSep
												 +CAST(ISNULL(BOld.BtiCESPState,0) AS VARCHAR)+@cSep+
												 +CAST(ISNULL(B.tiCESPState,0) AS VARCHAR)+@cSep+
									CASE ISNULL(BOld.BtiCESPState,0)
										WHEN 1 THEN 'SCEE'
										WHEN 2 THEN 'SCEE et BEC'
										WHEN 3 THEN 'SCEE et SCEE+'
										WHEN 4 THEN 'SCEE, SCEE+ et BEC'
									ELSE ''
									END+@cSep+
									CASE ISNULL(B.tiCESPState,0)
										WHEN 1 THEN 'SCEE'
										WHEN 2 THEN 'SCEE et BEC'
										WHEN 3 THEN 'SCEE et SCEE+'
										WHEN 4 THEN 'SCEE, SCEE+ et BEC'
									ELSE ''
									END+@cSep+CHAR(13)+CHAR(10)
							ELSE ''
							END
						FROM #tBenef BOld 
						JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = BOld.BeneficiaryID
						JOIN dbo.Mo_Human H ON H.HumanID = B.BeneficiaryID
						JOIN CRQ_LogAction LA ON LA.LogActionShortName = 'U'
						WHERE ISNULL(BOld.BtiCESPState, 0) <> ISNULL(B.tiCESPState, 0)
			
			IF @@ERROR <> 0
				SET @Result = -9
			
			-- Insertion du log sur les souscripteurs modifiés
			INSERT INTO CRQ_Log (
					ConnectID,
					LogTableName,
					LogCodeID,
					LogTime,
					LogActionID,
					LogDesc,
					LogText)
					SELECT
						@ConnectID,
						'Un_Subscriber',
						S.SubscriberID,
						GETDATE(),
						LA.LogActionID,
						LogDesc = 'Souscripteur : ' + H.LastName + ', ' + H.FirstName,
						LogText = 
							CASE 
								WHEN ISNULL(SOld.StiCESPState,1) <> ISNULL(S.tiCESPState,0) THEN
									'tiCESPState'+@cSep
													+CAST(ISNULL(SOld.StiCESPState,0) AS VARCHAR)+@cSep+
													+CAST(ISNULL(S.tiCESPState,0) AS VARCHAR)+@cSep+
									CASE ISNULL(SOld.StiCESPState,0)
										WHEN 1 THEN 'SCEE'
										WHEN 2 THEN 'SCEE et BEC'
										WHEN 3 THEN 'SCEE et SCEE+'
										WHEN 4 THEN 'SCEE, SCEE+ et BEC'
									ELSE ''
									END+@cSep+
									CASE ISNULL(S.tiCESPState,0)
										WHEN 1 THEN 'SCEE'
										WHEN 2 THEN 'SCEE et BEC'
										WHEN 3 THEN 'SCEE et SCEE+'
										WHEN 4 THEN 'SCEE, SCEE+ et BEC'
									ELSE ''
									END+@cSep+CHAR(13)+CHAR(10)
							ELSE ''
							END
						FROM #tSousc SOld 
						JOIN dbo.Un_Subscriber S ON S.SubscriberID = SOld.SubscriberID
						JOIN dbo.Mo_Human H ON H.HumanID = S.SubscriberID
						JOIN CRQ_LogAction LA ON LA.LogActionShortName = 'U'
						WHERE ISNULL(SOld.StiCESPState, 0) <> ISNULL(S.tiCESPState, 0)
			
			IF @@ERROR <> 0
				SET @Result = -10
			
				-- Gestion des demandes de PCEE lorsque les champs bFormulaireRecu ou bCLBRequested sont modifiés
				DECLARE 
					@iMaxConventionID INT,
					@bFormulaireRecuAncien BIT,
					@bFormulaireRecuNouveau BIT

				SELECT @iMaxConventionID = MAX(COld.ConventionID) 
				FROM #tConv COld 
				JOIN dbo.Un_Convention C ON C.ConventionID = COld.ConventionID
				WHERE (ISNULL(COld.bFormulaireRecu, 0) <> ISNULL(C.bFormulaireRecu, 0)
					OR ISNULL(COld.bCLBRequested, 0) <> ISNULL(C.bCLBRequested, 0))
				            		
			-- Boucler à travers les conventions qui ont changé au niveau des formulaires pour resoumettre les demandes de subventions
				WHILE @iMaxConventionID	IS NOT NULL
					BEGIN
						
						-- Récupère l'ancienne et la nouvelle valeur de la convention courante
						SELECT 
							@bFormulaireRecuAncien = ISNULL(COld.bFormulaireRecu ,0),
							@bFormulaireRecuNouveau = ISNULL(C.bFormulaireRecu ,0)
						FROM #tConv COld 
						JOIN dbo.Un_Convention C ON C.ConventionID = COld.ConventionID
						WHERE COld.ConventionID = @iMaxConventionID

						EXECUTE psPCEE_ForcerDemandeCotisation @iMaxConventionID, @ConnectID, @bFormulaireRecuAncien, @bFormulaireRecuNouveau
																					
						SELECT @iMaxConventionID = MAX(COld.ConventionID) 
						FROM #tConv COld 
						JOIN dbo.Un_Convention C ON C.ConventionID = COld.ConventionID
						WHERE (ISNULL(COld.bFormulaireRecu, 0) <> ISNULL(C.bFormulaireRecu, 0)
							OR ISNULL(COld.bCLBRequested, 0) <> ISNULL(C.bCLBRequested, 0))
							AND COld.ConventionID < @iMaxConventionID	
					END
		
				IF @@ERROR <> 0
					SET @Result = -11
				
			-- Gestion des demandes de BEC lorsque le champ bCLBRequested passe de OUI à NON
				SELECT @iMaxConventionID = MAX(COld.ConventionID) 
				FROM #tConv COld 
				JOIN dbo.Un_Convention C ON C.ConventionID = COld.ConventionID
				WHERE ISNULL(COld.bCLBRequested, 0) = 1
					AND ISNULL(C.bCLBRequested,0) = 0
				            		
				-- Boucler à travers les bénéficiaires qui ont changé d'état de BEC de 1 à 0 pour désactiver les demandes		
				WHILE @iMaxConventionID	IS NOT NULL
					BEGIN
						EXECUTE psPCEE_DesactiverBec NULL, @ConnectID, @iMaxConventionID, 0
																	
						SELECT @iMaxConventionID = MAX(COld.ConventionID) 
						FROM #tConv COld 
						JOIN dbo.Un_Convention C ON C.ConventionID = COld.ConventionID
						WHERE ISNULL(COld.bCLBRequested, 0) = 1 
							AND ISNULL(C.bCLBRequested,0) = 0
							AND COld.ConventionID < @iMaxConventionID	
					END
		
				IF @@ERROR <> 0
					SET @Result = -12
			
			-- Gestion des demandes de BEC lorsque le champ bCLBRequested passe de NON à OUI
				SELECT @iMaxConventionID = MAX(COld.ConventionID) 
				FROM #tConv COld 
				JOIN dbo.Un_Convention C ON C.ConventionID = COld.ConventionID
				WHERE ISNULL(COld.bCLBRequested, 0) = 0 
					AND ISNULL(C.bCLBRequested,0) = 1
					AND dbo.FN_CRQ_DateNoTime(C.dtRegStartDate) <= GETDATE()
            		
				-- Boucler à travers les conventions qui ont changé d'état de BEC de 0 à 1 pour créer les demandes		
				WHILE @iMaxConventionID	IS NOT NULL
					BEGIN
						EXECUTE TT_UN_CLB @iMaxConventionID		
											
						SELECT @iMaxConventionID = MAX(COld.ConventionID) 
						FROM #tConv COld 
						JOIN dbo.Un_Convention C ON C.ConventionID = COld.ConventionID
						WHERE ISNULL(COld.bCLBRequested, 0) = 0 
							AND ISNULL(C.bCLBRequested,0) = 1
							AND COld.ConventionID < @iMaxConventionID	
							AND dbo.FN_CRQ_DateNoTime(C.dtRegStartDate) <= GETDATE()
					END
		
					IF @@ERROR <> 0
						SET @Result = -13
				
	END 

	IF @Result > 0
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
		--------------------

	RETURN @Result
	--SELECT @Result
END
