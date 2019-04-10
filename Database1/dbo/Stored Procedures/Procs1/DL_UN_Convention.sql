/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	DL_UN_Convention
Description         :	Suppression d'une convention
Valeurs de retours  :	>0  : Tout à fonctionné
                     	<=0 : Erreur SQL
									-1		: Erreur à la suppression des groupes d'unités
									-2		: Erreur à la suppression du compte souscripteur
									-3		: Erreur à la suppression de la convention
									-4		: Erreur à la suppression de l'historique des états des groupes d'unités
									-5		: Erreur à la suppression des horaires de prélèvements
									-6		: Erreur à la suppression de l'historique des états de la convention
									-7		: Erreur à la suppression de l'historique de modalité de paiement
									-8		: Erreur à la suppression d'arrêt de paiement
									-9		: Erreur à l'insertion du log de suppression de la convention
									-10	: Erreur à l'insertion du log de suppression de compte bancaire de la convention
									-11   : Erreur à la suppression de l'historique des années de qualification de la convention
									-12   : Erreur à la suppression des enregistrements 400 non-expédiés
									-13   : Erreur à la suppression des enregistrements 200 non-expédiés
									-14   : Erreur à la suppression des enregistrements 100 non-expédiés
Note               :							2004-06-01	Bruno Lapointe	Création
								ADX0000594	IA	2004-11-24	Bruno Lapointe	Log
								ADX0000612	IA	2005-01-06	Bruno Lapointe	Suppression de l'historique d'année de qualification
								ADX0000670	IA	2005-03-14	Bruno Lapointe	Suppression du champ LastDepositForDoc
								ADX0000831	IA	2006-03-20	Bruno Lapointe	Adaptation des conventions pour PCEE 4.3
												2008-12-09	Radu			Ajout de champs dans les logs
												2010-10-04	Steve Gouin		Gestion des disable trigger par #DisableTrigger
												2015-07-29	Steve Picard	Utilisation du "Un_Convention.TexteDiplome" au lieu de la table UN_DiplomaText
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[DL_UN_Convention] (
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@ConventionID INTEGER) -- ID de la convention
AS
BEGIN
	DECLARE
		@iResult INTEGER,
		-- Variable du caractère séparateur de valeur du blob
		@cSep CHAR(1)
	
	SET @cSep = CHAR(30)
	
	SET @iResult = 1
	
	-----------------
	BEGIN TRANSACTION
	-----------------

	-- Suppression de l'historique de modalité de paiement
	DELETE Un_UnitModalHistory
	FROM Un_UnitModalHistory
	JOIN dbo.Un_Unit U ON U.UnitID = Un_UnitModalHistory.UnitID
	WHERE U.ConventionID = @ConventionID
		
	IF @@ERROR <> 0
		SET @iResult = -7 -- Erreur à la suppression de l'historique de modalité de paiement

	IF @iResult > 0
	BEGIN
		-- Suppression des horaires de prélèvements
		DELETE Un_AutomaticDeposit
		FROM Un_AutomaticDeposit
		JOIN dbo.Un_Unit U ON U.UnitID = Un_AutomaticDeposit.UnitID
		WHERE U.ConventionID = @ConventionID

		IF @@ERROR <> 0
			SET @iResult = -5 -- Erreur à la suppression des horaires de prélèvements
	END

	IF @iResult > 0
	BEGIN
		-- Suppression des enregistements 400 non expédiés
		DELETE Un_CESP400
		WHERE ConventionID = @ConventionID
			AND iCESPSendFileID IS NULL

		IF @@ERROR <> 0
			SET @iResult = -12
	END

	IF @iResult > 0
	BEGIN
		-- Suppression des opérations de BEC qui n'ont pas été expédiées
		DECLARE
			@dtLastVerifDate DATETIME

		-- Va chercher la date de blocage
		SELECT @dtLastVerifDate = LastVerifDate
		FROM Un_Def

		-- Va chercher le ID de l'opération BEC s'il y en a une
		DECLARE @tOperBEC TABLE (
			OperID INTEGER PRIMARY KEY )

		INSERT INTO @tOperBEC
			SELECT DISTINCT O.OperID
			FROM dbo.Un_Unit U
			JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
			JOIN Un_Oper O ON O.OperID = Ct.OperID
			WHERE U.ConventionID = @ConventionID
				AND O.OperTypeID = 'BEC'

		-- Recule la date de blocage si nécessaire pour la suppression
		IF EXISTS (SELECT * FROM @tOperBEC)
			UPDATE Un_Def
			SET LastVerifDate = (
					SELECT MIN(O.OperDate)
					FROM @tOperBEC B
					JOIN Un_Oper O ON O.OperID = B.OperID )-1
			WHERE LastVerifDate >= (
					SELECT MIN(O.OperDate)
					FROM @tOperBEC B
					JOIN Un_Oper O ON O.OperID = B.OperID )
		
		--ALTER TABLE Un_Cotisation
		--	DISABLE TRIGGER TUn_Cotisation_State
	IF object_id('tempdb..#DisableTrigger') is null
		CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))

	INSERT INTO #DisableTrigger VALUES('TUn_Cotisation_State')				

		-- Supprime l'opération BEC
		IF @@ERROR = 0
			DELETE
			FROM Un_Cotisation
			WHERE OperID IN (
					SELECT OperID
					FROM @tOperBEC
					)

		--ALTER TABLE Un_Cotisation
		--	ENABLE TRIGGER TUn_Cotisation_State
		Delete #DisableTrigger where vcTriggerName = 'TUn_Cotisation_State'

		IF @@ERROR = 0
			DELETE
			FROM Un_Oper
			WHERE OperID IN (
					SELECT OperID
					FROM @tOperBEC
					)

		-- Remet la date de blocage à la date qu'elle devrait avoir
		IF EXISTS (SELECT * FROM @tOperBEC)
			UPDATE Un_Def
			SET LastVerifDate = @dtLastVerifDate
			WHERE LastVerifDate <> @dtLastVerifDate

		IF @@ERROR <> 0
			SET @iResult = -15
	END

	IF @iResult > 0
	BEGIN
		-- Suppression de l'historique des états des groupes d'unités de la convention
		DELETE Un_UnitUnitState
		FROM Un_UnitUnitState
		JOIN dbo.Un_Unit U ON U.UnitID = Un_UnitUnitState.UnitID
		WHERE U.ConventionID = @ConventionID

		IF @@ERROR <> 0
			SET @iResult = -4 -- Erreur à la suppression de l'historque des états des groupes d'unités
	END

	IF @iResult > 0
	BEGIN
		-- Suppression des groupes d'unités de la convention
		DELETE
		FROM dbo.Un_Unit 
		WHERE ConventionID = @ConventionID

		IF @@ERROR <> 0
			SET @iResult = -1 -- Erreur à la suppression des groupes d'unités
	END

	IF @iResult > 0 
	BEGIN
		-- Insère un log de l'objet inséré.
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
				@ConventionID,
				GETDATE(),
				LA.LogActionID,
				LogDesc = 'Compte bancaire de convention : '+C.ConventionNo,
				LogText =
					'BankID'+@cSep+CAST(AC.BankID AS VARCHAR)+@cSep+ISNULL(BT.BankTypeCode+'-'+B.BankTransit,'')+@cSep+CHAR(13)+CHAR(10)+
					'AccountName'+@cSep+AC.AccountName+@cSep+CHAR(13)+CHAR(10)+
					'TransitNo'+@cSep+AC.TransitNo+@cSep+CHAR(13)+CHAR(10)
				FROM dbo.Un_Convention C
				JOIN Un_ConventionAccount AC ON AC.ConventionID = C.ConventionID
				JOIN Mo_Bank B ON B.BankID = AC.BankID
				JOIN Mo_BankType BT ON BT.BankTypeID = B.BankTypeID
				JOIN CRQ_LogAction LA ON LA.LogActionShortName = 'D'
				WHERE C.ConventionID = @ConventionID

		IF @@ERROR <> 0 
			SET @iResult = -10 -- Erreur à l'insertion du log
	END

	IF @iResult > 0
	BEGIN
		-- Suppression du compte souscripteur de la convention
		DELETE
		FROM Un_ConventionAccount 
		WHERE ConventionID = @ConventionID

		IF @@ERROR <> 0
			SET @iResult = -2 -- Erreur à la suppression du compte souscripteur
	END

	IF @iResult > 0
	BEGIN
		-- Suppression des arrêts de paiements
		DELETE
		FROM Un_Breaking 
		WHERE ConventionID = @ConventionID

		IF @@ERROR <> 0
			SET @iResult = -8 -- Erreur à la suppression des arrêts de paiement
	END

	IF @iResult > 0
	BEGIN
		-- Suppression de l'historique des états de la convention
		DELETE
		FROM Un_ConventionConventionState
		WHERE ConventionID = @ConventionID

		IF @@ERROR <> 0 
			SET @iResult = -6 -- Erreur à la suppression de l'historique des états de la convention
	END

	IF @iResult > 0
	BEGIN
		-- Insère un log de l'objet inséré.
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
				@ConventionID,
				GETDATE(),
				LA.LogActionID,
				LogDesc = 'Convention : '+C.ConventionNo,
				LogText =
					'SubscriberID'+@cSep+CAST(C.SubscriberID AS VARCHAR)+@cSep+ISNULL(S.LastName+', '+S.FirstName,'')+@cSep+CHAR(13)+CHAR(10)+
					CASE 
						WHEN ISNULL(C.CoSubscriberID,0) <= 0 THEN ''
					ELSE 'CoSubscriberID'+@cSep+CAST(C.CoSubscriberID AS VARCHAR)+@cSep+ISNULL(CS.LastName+', '+CS.FirstName,'')+@cSep+CHAR(13)+CHAR(10)
					END+
					'BeneficiaryID'+@cSep+CAST(C.BeneficiaryID AS VARCHAR)+@cSep+ISNULL(B.LastName+', '+B.FirstName,'')+@cSep+CHAR(13)+CHAR(10)+
					'PlanID'+@cSep+CAST(C.PlanID AS VARCHAR)+@cSep+ISNULL(P.PlanDesc,'')+@cSep+CHAR(13)+CHAR(10)+
					'ConventionNo'+@cSep+C.ConventionNo+@cSep+CHAR(13)+CHAR(10)+
					'YearQualif'+@cSep+CAST(C.YearQualif AS VARCHAR)+@cSep+CHAR(13)+CHAR(10)+
					'FirstPmtDate'+@cSep+CONVERT(CHAR(10), C.FirstPmtDate, 20)+@cSep+CHAR(13)+CHAR(10)+
					'PmtTypeID'+@cSep+C.PmtTypeID+@cSep+
					CASE C.PmtTypeID
						WHEN 'AUT' THEN 'Automatique'
						WHEN 'CHQ' THEN 'Chèque'
					ELSE ''
					END+@cSep+
					CHAR(13)+CHAR(10)+
					'tiRelationshipTypeID'+@cSep+CAST(C.tiRelationshipTypeID AS VARCHAR)+@cSep+
					CASE C.tiRelationshipTypeID
						WHEN 1 THEN 'Père/Mère'
						WHEN 2 THEN 'Grand-père/Grand-mère'
						WHEN 3 THEN 'Oncle/Tante'
						WHEN 4 THEN 'Frère/Soeur'
						WHEN 5 THEN 'Aucun lien de parenté'
						WHEN 6 THEN 'Autre'
						WHEN 7 THEN 'Organisme'
					ELSE ''
					END+@cSep+
					CHAR(13)+CHAR(10)+
					CASE 
						WHEN ISNULL(C.GovernmentRegDate,0) <= 0 THEN ''
					ELSE 'GovernmentRegDate'+@cSep+CONVERT(CHAR(10), C.GovernmentRegDate, 20)+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE -- 2015-07-29
						WHEN ISNULL(C.TexteDiplome,'') = '' THEN ''
						ELSE 'TexteDiplome'+@cSep+ISNULL(C.TexteDiplome,'')+@cSep+CHAR(13)+CHAR(10)
					END+
					'bSendToCESP'+@cSep+CAST(ISNULL(C.bSendToCESP,1) AS VARCHAR)+@cSep+
					CASE 
						WHEN ISNULL(C.bSendToCESP,1) = 0 THEN 'Non'
					ELSE 'Oui'
					END+@cSep+
					CHAR(13)+CHAR(10)+
					'bCESGRequested'+@cSep+CAST(ISNULL(C.bCESGRequested,1) AS VARCHAR)+@cSep+
					CASE 
						WHEN ISNULL(C.bCESGRequested,1) = 0 THEN 'Non'
					ELSE 'Oui'
					END+@cSep+
					CHAR(13)+CHAR(10)+
					'bACESGRequested'+@cSep+CAST(ISNULL(C.bACESGRequested,1) AS VARCHAR)+@cSep+
					CASE 
						WHEN ISNULL(C.bACESGRequested,1) = 0 THEN 'Non'
					ELSE 'Oui'
					END+@cSep+
					CHAR(13)+CHAR(10)+
					'bCLBRequested'+@cSep+CAST(ISNULL(C.bCLBRequested,1) AS VARCHAR)+@cSep+
					CASE 
						WHEN ISNULL(C.bCLBRequested,1) = 0 THEN 'Non'
					ELSE 'Oui'
					END+@cSep+
					CHAR(13)+CHAR(10)+
					'tiCESPState'+@cSep+CAST(ISNULL(C.tiCESPState,0) AS VARCHAR)+@cSep+
					CASE ISNULL(C.tiCESPState,0)
						WHEN 1 THEN 'SCEE'
						WHEN 2 THEN 'SCEE et BEC'
						WHEN 3 THEN 'SCEE et SCEE+'
						WHEN 4 THEN 'SCEE, SCEE+ et BEC'
					ELSE ''
					END+@cSep+
					CHAR(13)+CHAR(10)+
					CASE 
						WHEN ISNULL(C.iID_Destinataire_Remboursement,0) <= 0 THEN ''
					ELSE 'iID_Destinataire_Remboursement'+@cSep+CAST(ISNULL(C.iID_Destinataire_Remboursement,0) AS VARCHAR)+@cSep+
					CASE C.iID_Destinataire_Remboursement
						WHEN 1 THEN 'Souscripteur'
						WHEN 2 THEN 'Bénéficiaire'
						WHEN 3 THEN 'Autre'
					ELSE ''
					END+@cSep+
					CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(C.vcDestinataire_Remboursement_Autre,'') = '' THEN ''
					ELSE 'vcDestinataire_Remboursement_Autre'+@cSep+C.vcDestinataire_Remboursement_Autre+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(C.dtDateProspectus,0) <= 0 THEN ''
					ELSE 'dtDateProspectus'+@cSep+CONVERT(CHAR(10), C.dtDateProspectus, 20)+@cSep+CHAR(13)+CHAR(10)
					END+
					'bSouscripteur_Desire_IQEE'+@cSep+CAST(ISNULL(C.bSouscripteur_Desire_IQEE,1) AS VARCHAR)+@cSep+
					CASE 
						WHEN ISNULL(C.bSouscripteur_Desire_IQEE,1) = 0 THEN 'Non'
					ELSE 'Oui'
					END+@cSep+
					CHAR(13)+CHAR(10)+
					CASE 
						WHEN ISNULL(C.tiID_Lien_CoSouscripteur,0) <= 0 THEN ''
					ELSE 'tiID_Lien_CoSouscripteur'+@cSep+CAST(ISNULL(C.tiID_Lien_CoSouscripteur,0) AS VARCHAR)+@cSep+
					CASE C.tiID_Lien_CoSouscripteur
						WHEN 1 THEN 'Père/Mère'
						WHEN 2 THEN 'Grand-père/Grand-mère'
						WHEN 3 THEN 'Oncle/Tante'
						WHEN 4 THEN 'Frère/Soeur'
						WHEN 5 THEN 'Aucun lien de parenté'
						WHEN 6 THEN 'Autre'
						WHEN 7 THEN 'Organisme'
					ELSE ''
					END+@cSep+
					CHAR(13)+CHAR(10)
					END
				FROM dbo.Un_Convention C
				JOIN dbo.Mo_Human S ON S.HumanID = C.SubscriberID
				LEFT JOIN dbo.Mo_Human CS ON CS.HumanID = C.CoSubscriberID
				JOIN dbo.Mo_Human B ON B.HumanID = C.BeneficiaryID
				JOIN CRQ_LogAction LA ON LA.LogActionShortName = 'D'
				JOIN Un_Plan P ON P.PlanID = C.PlanID
				--LEFT JOIN Un_DiplomaText DT ON DT.DiplomaTextID = C.DiplomaTextID		-- 2015-07-29
				WHERE C.ConventionID = @ConventionID

		IF @@ERROR <> 0 
			SET @iResult = -9 -- Erreur à l'insertion du log
	END

	IF @iResult > 0
	BEGIN
		-- Suppression de l'historique des années de qualification de la convention
		DELETE
		FROM Un_ConventionYearQualif
		WHERE ConventionID = @ConventionID

		IF @@ERROR <> 0 
			SET @iResult = -11 -- Erreur à la suppression de l'historique des années de qualification de la convention
	END

	IF @iResult > 0
	BEGIN
		-- Suppression des enregistements 200 non expédiés
		DELETE Un_CESP200
		WHERE ConventionID = @ConventionID
			AND iCESPSendFileID IS NULL

		IF @@ERROR <> 0
			SET @iResult = -13
	END

	IF @iResult > 0
	BEGIN
		-- Suppression des enregistements 100 non expédiés
		DELETE Un_CESP100
		WHERE ConventionID = @ConventionID
			AND iCESPSendFileID IS NULL

		IF @@ERROR <> 0
			SET @iResult = -14
	END

	IF @iResult > 0
	BEGIN
		-- Suppression de la convention
		DELETE
		FROM dbo.Un_Convention 
		WHERE ConventionID = @ConventionID

		IF @@ERROR <> 0 
			SET @iResult = -3 -- Erreur à la suppression de la convention
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


