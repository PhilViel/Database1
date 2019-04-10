/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	TT_UN_CESPSendFile700
Description         :	Génération d'un nouveau fichier sommaire (700).
Valeurs de retours  :	@Return_Value :
									>0  :	Tout à fonctionné
		                  	<=0 :	Erreur SQL
Note                :	ADX0000811	IA	2006-04-12	Bruno Lapointe		Création
								ADX0002426	BR	2007-05-23	Bruno Lapointe		Gestion de la table Un_CESP.
														2015-01-15	Pierre-Luc Simard	Remplacer la validation du tiCESPState par l'état de la convention REE
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_CESPSendFile700] (
	@ConnectID INTEGER, -- ID de connexion de l'usager qui fait la demande
	@dtProcess DATETIME) -- Date de l'évaluation et de l'envoi
AS
BEGIN
	DECLARE
		@iResult INTEGER,
		@iCESPSendFileID INTEGER,
		@iCntCESPSendFile INTEGER,
		@vcProcessDate VARCHAR(75),
		@vcCESPSendFile VARCHAR(75)

	-----------------
	BEGIN TRANSACTION
	-----------------
	
	SET @iResult = 1

	IF @iResult > 0
	BEGIN
		SET @dtProcess = dbo.fn_Mo_DateNoTime(@dtProcess)
		SET @vcProcessDate = CAST(DATEPART(YEAR,@dtProcess) AS VARCHAR)
		IF DATEPART(MONTH,@dtProcess) > 9
			SET @vcProcessDate = @vcProcessDate + CAST(DATEPART(MONTH,@dtProcess) AS VARCHAR)
		ELSE
			SET @vcProcessDate = @vcProcessDate + '0' + CAST(DATEPART(MONTH,@dtProcess) AS VARCHAR)
		IF DATEPART(DAY,@dtProcess) > 9
			SET @vcProcessDate = @vcProcessDate + CAST(DATEPART(DAY,@dtProcess) AS VARCHAR)
		ELSE
			SET @vcProcessDate = @vcProcessDate + '0' + CAST(DATEPART(DAY,@dtProcess) AS VARCHAR)
	
		SET @vcCESPSendFile = 'S0000105444723RC' + @vcProcessDate + '01'
	
		SELECT 
			@iCntCESPSendFile = COUNT(iCESPSendFileID)
		FROM Un_CESPSendFile
		WHERE vcCESPSendFile LIKE 'S0000105444723RC' + @vcProcessDate + '%'
	
		IF @iCntCESPSendFile > 1
			SET @vcCESPSendFile = 
				'S0000105444723RC'+@vcProcessDate+
				CASE 
					WHEN @iCntCESPSendFile < 10 THEN '0' + CAST(@iCntCESPSendFile AS VARCHAR)
				ELSE CAST(@iCntCESPSendFile AS VARCHAR) 
				END
	
		INSERT INTO Un_CESPSendFile (
			vcCESPSendFile,
			dtCESPSendFile)
		VALUES (
			@vcCESPSendFile,
			@dtProcess)
	
		IF @@ERROR <> 0
			SET @iResult = -1 -- Erreur à la sauvegarde du fichier d'envoi
		ELSE
		BEGIN
			SET @iCESPSendFileID = IDENT_CURRENT('Un_CESPSendFile')
			SET @iResult = @iCESPSendFileID
		END
	END

	IF @iResult > 0
	BEGIN
		-- Insère les valeurs marchandes
		INSERT INTO Un_CESP700 (
				iCESPSendFileID,
				ConventionID,
				iPlanGovRegNumber,
				ConventionNo,
				fMarketValue )
			SELECT
				@iCESPSendFileID,
				C.ConventionID,
				P.PlanGovernmentRegNo,
				C.ConventionNo,
				fMarketValue =	ISNULL(Ct.Cotisation,0)+ISNULL(CO.fInterests,0)+ISNULL(CE.fCESP,0)
			FROM dbo.Un_Convention C 
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			LEFT JOIN (
				SELECT
					U.ConventionID,
					Cotisation = SUM(Ct.Cotisation)
				FROM dbo.Un_Unit U
				JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
				JOIN Un_Oper O ON O.OperID = Ct.OperID
				LEFT JOIN Un_OperBankFile OBF ON OBF.OperID = O.OperID
				WHERE	(	O.OperDate <= @dtProcess -- Compte uniquement les opérations qui ont eu lieu antérieurement au dernier jour du mois ou le dernier jour du mois
						-- Ne compte pas les CPAs anticipés
						AND( O.OperTypeID <> 'CPA'
							OR ISNULL(OBF.OperID, 0) > 0
							)
						)
				GROUP BY U.ConventionID
				) Ct ON Ct.ConventionID = C.ConventionID
			LEFT JOIN (
				-- Va chercher les différents intérêts contenu dans les opérations sur convention
				SELECT
					ConventionID,
					fInterests = SUM(CO.ConventionOperAmount)
				FROM Un_ConventionOper CO
				JOIN Un_Oper O ON O.OperID = CO.OperID
				WHERE CO.ConventionOperTypeID IN ('INM', 'INS', 'IST', 'ITR', 'IS+', 'IBC', 'INC') -- Compte uniquement tout les intérêts
					AND O.OperDate <= @dtProcess -- Compte uniquement les opérations qui ont eu lieu antérieurement au dernier jour du mois ou le dernier jour du mois
				GROUP BY CO.ConventionID
				) CO ON CO.ConventionID = C.ConventionID
			LEFT JOIN (
				-- Va chercher la SCEE, SCEE+ et le BEC
				SELECT 
					CE.ConventionID,
					fCESP = SUM(CE.fCESG+CE.fACESG+CE.fCLB)
				FROM Un_CESP CE
				JOIN Un_Oper O ON O.OperID = CE.OperID
				WHERE O.OperDate <= @dtProcess -- Compte uniquement les opérations qui ont eu lieu antérieurement au dernier jour du mois ou le dernier jour du mois
				GROUP BY CE.ConventionID
				) CE ON CE.ConventionID = C.ConventionID
			WHERE C.ConventionID IN (
						-- Convention qui remplis les critères minimums pour être expédié au PCEE
						SELECT DISTINCT
							C.ConventionID
						FROM dbo.Un_Convention C
						JOIN ( -- On s'assure que la convention a déjà été en état REEE
							SELECT DISTINCT
								CS.ConventionID
							FROM Un_ConventionConventionState CS
							WHERE CS.ConventionStateID = 'REE'
							) CSS ON CSS.ConventionID = C.ConventionID
						JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
						JOIN Mo_Connect Cn ON Cn.ConnectID = U.ActivationConnectID -- S'assure qu'au moins un groupe d'unités est activé
						JOIN dbo.Mo_Human S ON S.HumanID = C.SubscriberID
						JOIN dbo.Mo_Human B ON B.HumanID = C.BeneficiaryID
						WHERE C.bSendToCESP <> 0 -- À envoyer au PCEE
							--AND C.tiCESPState > 0 -- Passe le minimum des pré-validations PCEE
							AND U.IntReimbDate IS NULL
							AND U.TerminatedDate IS NULL
							AND U.InforceDate <= @dtProcess
							AND ISNULL(S.SocialNumber,'') <> ''
							AND ISNULL(B.SocialNumber,'') <> ''
						)
				-- Valeur marchande plus grande que 0.00$
				AND ISNULL(Ct.Cotisation,0)+ISNULL(CO.fInterests,0)+ISNULL(CE.fCESP,0) > 0
	
		IF @@ERROR <> 0
			SET @iResult = -2
	END

	IF @iResult > 0
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
		--------------------

	RETURN @iResult
END


