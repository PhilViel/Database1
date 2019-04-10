/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	TT_UN_CESPSendFile
Description         :	Génération des lots de transactions (100, 200 et 400) pour un fichier de production du PCEE.
Valeurs de retours  :	@Return_Value :
					>0  :	Tout à fonctionné
		                  	<=0 :	Erreur SQL
Note                :	ADX0000811	IA	2006-04-12	Bruno Lapointe	Création
								ADX0001153	IA	2006-11-10	Alain Quirion	Empêcher l’envoi des enregistrements 400 tant qu’il y aura des erreurs non corrigées sur un enregistrement 100 ou un enregistrement 200 de la convention
								ADX0001235	IA	2007-02-14	Alain Quirion	Utilisation de dtRegStartDate pour la date de début de régime
								ADX0002426	BR	2007-05-23	Bruno Lapointe	Gestion de la table Un_CESP.
								ADX0002465	BR	2007-05-31	Bruno Lapointe	Correction du problème des annualtions de 400 qui
																	se doublait quand il avait plus d'une 900 sur la 400 annulée.
                                                2008-10-17  Faiha Araar Correcion pour ajouter les enregistrements 511
												2009-02-04	Pierre-Luc Simard	Correction pour envoyer les transactions de la dernière journée du mois, même s'il y a l'heure dans la date
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_CESPSendFile_ORI_20110202] (
	@bForceSendFile BIT) -- Indique si le traitement doit s'effectuer mème s'il y a une réponse en attente du PCEE.
AS
BEGIN
	DECLARE
		@iCESPSendFileID INTEGER, -- ID du fichier de production
		@dtToday DATETIME,
		@vcTodayDate VARCHAR(75),
		@dtLimit DATETIME,
		@iCntCESPSendFile INTEGER,
		@iCESGWaitingDays INTEGER,
		@iResult INTEGER,
		@vcCESPSendFile VARCHAR(75)
	
	SET @iResult = 1

	-- Si on ne force pas l'envoi, on retourne une erreur si 
	IF @bForceSendFile = 0
		IF EXISTS (
				SELECT * 
				FROM Un_CESPSendFile
				WHERE vcCESPSendFile LIKE 'P%'
					AND iCESPReceiveFileID IS NULL
				)
			SET @iResult = -1 -- Erreur on a un fichier de production pour lequel on a pas eu de fichier de retour et l'option forcer est à non.

	IF @iResult > 0
	BEGIN
		SET @dtToday = GETDATE()
		SET @dtLimit = CAST(CAST(DATEPART(MONTH,@dtToday) AS VARCHAR)+'-01-'+CAST(DATEPART(YEAR,@dtToday) AS VARCHAR) AS DATETIME)
		--SET @dtLimit = DATEADD(DAY,-1,@dtLimit)

		SET @vcTodayDate = CAST(DATEPART(YEAR,@dtToday) AS VARCHAR)
		IF DATEPART(MONTH,@dtToday) > 9
			SET @vcTodayDate = @vcTodayDate + CAST(DATEPART(MONTH,@dtToday) AS VARCHAR)
		ELSE
			SET @vcTodayDate = @vcTodayDate + '0' + CAST(DATEPART(MONTH,@dtToday) AS VARCHAR)
		IF DATEPART(DAY,@dtToday) > 9
			SET @vcTodayDate = @vcTodayDate + CAST(DATEPART(DAY,@dtToday) AS VARCHAR)
		ELSE
			SET @vcTodayDate = @vcTodayDate + '0' + CAST(DATEPART(DAY,@dtToday) AS VARCHAR)
	
		SET @vcCESPSendFile = 'P0000105444723RC' + @vcTodayDate + '01'
	
		SELECT 
			@iCESGWaitingDays = MAX(CESGWaitingDays)
		FROM Un_Def
	
		SELECT 
			@iCntCESPSendFile = COUNT(iCESPSendFileID)
		FROM Un_CESPSendFile
		WHERE vcCESPSendFile LIKE 'P0000105444723RC' + @vcTodayDate + '%'
	
		IF @iCntCESPSendFile > 1
			SET @vcCESPSendFile = 
				'P0000105444723RC'+@vcTodayDate+
				CASE 
					WHEN @iCntCESPSendFile < 10 THEN '0' + CAST(@iCntCESPSendFile AS VARCHAR)
				ELSE CAST(@iCntCESPSendFile AS VARCHAR) 
				END
	END

	IF @iResult > 0
	BEGIN
		-- Création d'une table temporaire qui contiendra les id des conventions qui remplissent les critères nécessessaires à leurs 
		-- envois au PCEE
		CREATE TABLE #tConventionToSend (
			ConventionID INTEGER PRIMARY KEY )

		INSERT INTO #tConventionToSend
			SELECT DISTINCT
				C.ConventionID
			FROM dbo.Un_Convention C
			JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
			JOIN Mo_Connect Cn ON Cn.ConnectID = U.ActivationConnectID -- S'assure qu'au moins un groupe d'unités est activé
			WHERE C.bSendToCESP <> 0 -- À envoyer au PCEE
				AND C.tiCESPState > 0 -- Passe le minimum des pré-validations PCEE

		IF @@ERROR = 0	
			-- Ne traite pas les conventions qui ont un enregistrement 100 en erreur
			DELETE #tConventionToSend
			FROM #tConventionToSend
			JOIN Un_CESP100 C1 ON C1.ConventionID = #tConventionToSend.ConventionID
			JOIN Un_CESP800ToTreat C8T ON C8T.iCESP800ID = C1.iCESP800ID

		IF @@ERROR <> 0
			SET @iResult = -3 
	END

	IF @iResult > 0
	BEGIN
		CREATE TABLE #tConventionRES (
			ConventionID INTEGER PRIMARY KEY,
			CotisationID INTEGER NOT NULL,
			fCESG MONEY NOT NULL,
			fCLB MONEY NOT NULL )

		INSERT INTO #tConventionRES (
				ConventionID,
				CotisationID,
				fCESG,
				fCLB )
			SELECT 
				U.ConventionID,
				MAX(Ct.CotisationID),
				0,
				0
			FROM dbo.Un_Unit U
			JOIN Un_Cotisation Ct ON U.UnitID = Ct.UnitID
			JOIN Un_Oper O ON O.OperID = Ct.OperID
			JOIN Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID
			WHERE U.ConventionID NOT IN (
					-- Retourne les convnetions qui ne sont pas totalement résiliée
					SELECT ConventionID
					FROM dbo.Un_Unit 
					WHERE TerminatedDate IS NULL
					)
				AND G4.tiCESP400TypeID = 21 -- Remboursement
				AND G4.tiCESP400WithdrawReasonID = 3 -- Raison du remboursement est la résiliation totale
				AND O.OperTypeID = 'RES'
			GROUP BY U.ConventionID

		-- Ne traite pas les conventions qui ont un enregistrement 400 de non expédié
		IF @@ERROR = 0
			DELETE 
			FROM #tConventionRES
			WHERE ConventionID IN (
				SELECT ConventionID
				FROM Un_CESP400
				WHERE iCESPSendFileID IS NULL )

		IF @@ERROR = 0
			UPDATE #tConventionRES
			SET 
				fCESG = V.fCESG,
				fCLB = V.fCLB
			FROM #tConventionRES
			JOIN (
				SELECT
					CE.ConventionID,
					fCESG = SUM(CE.fCESG+CE.fACESG), -- Solde de la SCEE et SCEE+
					fCLB = SUM(CE.fCLB) -- Solde du BEC
				FROM Un_CESP CE
				JOIN #tConventionRES CR ON CR.ConventionID = CE.ConventionID
				GROUP BY CE.ConventionID
				) V ON V.ConventionID = #tConventionRES.ConventionID

		IF @@ERROR = 0
			DELETE
			FROM #tConventionRES
			WHERE	fCESG = 0 -- Solde de SCEE et SCEE+ différent de 0.00$
				AND fCLB = 0 -- Solde de BEC différent de 0.00$

		IF @@ERROR = 0	
			-- Ne traite pas les conventions qui ont un enregistrement 100 en erreur
			DELETE #tConventionRES
			FROM #tConventionRES
			JOIN Un_CESP100 C1 ON C1.ConventionID = #tConventionRES.ConventionID
			JOIN Un_CESP800ToTreat C8T ON C8T.iCESP800ID = C1.iCESP800ID

		IF @@ERROR = 0	
			-- Ne traite pas les conventions dont le bénéficiaire/souscripteur a un enregistrement 200 en erreur
			DELETE #tConventionRES
			FROM #tConventionRES
			JOIN Un_CESP200 C2 ON C2.ConventionID = #tConventionRES.ConventionID
			JOIN Un_CESP200 C2B ON C2.HumanID = C2B.HumanID
			JOIN Un_CESP800ToTreat C8T ON C8T.iCESP800ID = C2B.iCESP800ID		

		IF @@ERROR = 0	
			-- Ne traite pas les conventions qui ont un enregistrement 400 en erreur
			DELETE #tConventionRES
			FROM #tConventionRES
			JOIN Un_CESP400 C4 ON C4.ConventionID = #tConventionRES.ConventionID
			JOIN Un_CESP800ToTreat C8T ON C8T.iCESP800ID = C4.iCESP800ID

		-- Ajout au solde actuel le montant des remboursements qui seront annulés pour connaître le montant du nouveau remboursement.
		IF @@ERROR = 0
			UPDATE #tConventionRES
			SET 
				fCESG = #tConventionRES.fCESG + V.fCESG,
				fCLB = #tConventionRES.fCLB + V.fCLB
			FROM #tConventionRES
			JOIN (
				SELECT
					G4.ConventionID,
					fCESG = SUM(G4.fCESG),
					fCLB = SUM(G4.fCLB)
				FROM Un_CESP400 G4
				JOIN #tConventionRES CR ON G4.CotisationID = CR.CotisationID
				LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
				WHERE	G4.iCESP800ID IS NULL -- Pas revenu en erreur
					AND G4.iReversedCESP400ID IS NULL -- Pas une annulation
					AND R4.iCESP400ID IS NULL -- Pas annulé
				GROUP BY G4.ConventionID
				) V ON V.ConventionID = #tConventionRES.ConventionID		

		IF @@ERROR <> 0
			SET @iResult = -4
	END

	-----------------
	BEGIN TRANSACTION
	-----------------

	IF @iResult > 0
	BEGIN
		INSERT INTO Un_CESPSendFile (
			vcCESPSendFile,
			dtCESPSendFile)
		VALUES (
			@vcCESPSendFile,
			@dtToday)
	
		IF @@ERROR <> 0
			SET @iResult = -2 -- Erreur à la sauvegarde du fichier d'envoi
		ELSE
		BEGIN
			SET @iCESPSendFileID = IDENT_CURRENT('Un_CESPSendFile')
			SET @iResult = @iCESPSendFileID
		END
	END

	IF @iResult > 0
	BEGIN
		-- Mets dans le fichier les enregistrements 100 des conventions concernés qui n'ont pas encore été expédiés
		UPDATE Un_CESP100
		SET iCESPSendFileID = @iCESPSendFileID
		FROM Un_CESP100
		JOIN #tConventionToSend CTS ON CTS.ConventionID = Un_CESP100.ConventionID
		WHERE Un_CESP100.iCESPSendFileID IS NULL -- Pas déjà expédié
			AND Un_CESP100.dtTransaction < @dtLimit -- = @dtLimit -- Exclus les transactions ultérieure à la date limite.
			
		IF @@ERROR <> 0
			SET @iResult = -5 
	END

	IF @iResult > 0
	BEGIN
		-- Mets dans le fichier les enregistrements 200 des conventions concernés qui n'ont pas encore été expédiés
		UPDATE Un_CESP200
		SET iCESPSendFileID = @iCESPSendFileID
		FROM Un_CESP200
		JOIN #tConventionToSend CTS ON CTS.ConventionID = Un_CESP200.ConventionID			
		LEFT JOIN Un_CESP800ToTreat C8T ON C8T.iCESP800ID = Un_CESP200.iCESP800ID	
		WHERE Un_CESP200.iCESPSendFileID IS NULL -- Pas déjà expédié
			AND Un_CESP200.dtTransaction < @dtLimit -- = @dtLimit -- Exclus les transactions ultérieure à la date limite.
			AND C8T.iCESP800ID IS NULL	--Exclus ceux qui ont un enregistrment 200 lié toujours en traitement

		IF @@ERROR <> 0
			SET @iResult = -6 
	END

	IF @iResult > 0
	BEGIN
		IF @@ERROR = 0
			-- Annule les enregistrements 400 expédiés des résiliations dont le montant de remboursement de SCEE, SCEE+ et BEC est 
			-- a ajuster pour les recrées avec les bons montants.
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
					-G4.fCESG,
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
					-G4.fCLB,
					-G4.fEAPCLB,
					-G4.fPG,
					-G4.fEAPPG,
					G4.vcPGProv,
					-G4.fCotisationGranted
				FROM Un_Cotisation Ct
				JOIN Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID
				JOIN #tConventionRES CR ON Ct.CotisationID = CR.CotisationID
				LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
				WHERE	G4.iCESP800ID IS NULL -- Pas revenu en erreur
					AND G4.iReversedCESP400ID IS NULL -- Pas une annulation
					AND R4.iCESP400ID IS NULL -- Pas annulé

		IF @@ERROR = 0
			-- Recrée les enregistrements 400 des résiliations dont le montant de remboursement de SCEE, SCEE+ et BEC est a ajuster 
			-- avec les bons montants.
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
					fEAPCESG,
					fEAP,
					fPSECotisation,
					fCLB,
					fEAPCLB,
					fPG,
					fEAPPG )
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
					HS.SocialNumber,
					HB.SocialNumber,
					0,
					C.bCESGRequested,
					-- Rembourse la totalité de la subvention
					CR.fCESG,
					0,
					0,
					0,
					-- Rembourse la totalité du BEC
					CR.fCLB,
					0,
					0,
					0
				FROM Un_Cotisation Ct
				JOIN #tConventionRES CR ON Ct.CotisationID = CR.CotisationID
				JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
				JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				JOIN Un_Plan P ON P.PlanID = C.PlanID
				JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
				JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
				JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
				WHERE CR.fCESG >= 0
					AND CR.fCLB >= 0
					AND dbo.FN_CRQ_DateNoTime(ISNULL(C.dtRegStartDate,Ct.EffectDate+1)) <= Ct.EffectDate

		IF @@ERROR <> 0
			SET @iResult = -6 
	END

	IF @iResult > 0
	BEGIN
		-- Mets dans le fichier les enregistrements 400 des conventions concernés qui n'ont pas encore été expédiés
		UPDATE Un_CESP400
		SET iCESPSendFileID = @iCESPSendFileID
		FROM Un_CESP400
		JOIN #tConventionToSend CTS ON CTS.ConventionID = Un_CESP400.ConventionID
		LEFT JOIN Un_Cotisation Ct ON Ct.CotisationID = Un_CESP400.CotisationID
		LEFT JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID		
		LEFT JOIN Un_CESP200 C2 ON C2.ConventionID = CTS.ConventionID
		LEFT JOIN Un_CESP800ToTreat C8T ON C8T.iCESP800ID = C2.iCESP800ID
		WHERE Un_CESP400.iCESPSendFileID IS NULL -- Pas déjà expédié
			AND(	( Un_CESP400.dtTransaction < @dtLimit -- = @dtLimit -- Exclus les transactions ultérieure à la date limite.
					AND( Un_CESP400.tiCESP400TypeID NOT IN (21) -- Le délai administratif s'applique uniquement au remboursement
						OR ISNULL(U.IntReimbDate,@dtLimit+1) < @dtLimit -- = @dtLimit -- Pas de délai si le remboursement intégral a eu lieu
						)
					)
				-- Délai administratif sur les remboursements.
				OR	Un_CESP400.dtTransaction < DATEADD(DAY,-@iCESGWaitingDays,@dtLimit) -- = DATEADD(DAY,-@iCESGWaitingDays,@dtLimit)
				)
			AND C8T.iCESP800ID IS NULL 	-- Exclus ceux qui ont un enregistrement 200 lié toujours en traîtement

		IF @@ERROR <> 0
			SET @iResult = -7 
	END

	IF @iResult > 0
	BEGIN
		-- Inscrit le vcTransID avec le ID FIN + <iCESP400ID>.
		UPDATE Un_CESP400
		SET vcTransID = 'FIN'+CAST(iCESP400ID AS VARCHAR(12))
		WHERE vcTransID = 'FIN' 

		IF @@ERROR <> 0
			SET @iResult = -8
	END
    
    --Ajouter les enregistrements 511
	IF @iResult > 0
		
	BEGIN
		UPDATE UN_CESP511
		SET iCESPSendFileID = @iCESPSendFileID
		WHERE iCESPSendFileID IS NULL -- Pas déjà expédié
		AND dtTransaction < @dtLimit -- = @dtLimit -- Exclus les transactions ultérieure à la date limite.
		
		IF @@ERROR<>0
		   SET @iResult = -9 --Une erreur s'est produite lors de la mise èa jour des enregistremsnts 511
	END
    
   if @iResult>0
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
		--------------------

	RETURN @iResult
END


