/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	DL_UN_Unit
Description         :	Suppression d'un groupe d’unités.
Valeurs de retours  :	>0  :	Tout à fonctionné
                     	<=0 :	Erreur SQL
Note                :						2004-05-31	Bruno Lapointe	Création
								ADX0000831	IA	2006-03-21	Bruno Lapointe	Adaptation des conventions pour PCEE 4.3
												2010-10-04	Steve Gouin			Gestion des disable trigger par #DisableTrigger
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[DL_UN_Unit] (
	@ConnectID INTEGER, -- Id unique de la connection de l'usager
	@UnitID INTEGER) -- Id unique du groupe d'unités à supprimer
AS
BEGIN
	-- -1 Erreur de suppression du groupe d'unités
	-- -2 Erreur de suppression des historiques de modalités de paiements rattachés
	-- -3 Erreur de suppression d'horaire de prélèvement
	-- -4 Erreur de suppression d'historique des états des groupes d'unités

	DECLARE
		@iResult INTEGER,
		@iExecResult INTEGER,
		@ConventionID INTEGER
	
	SET @iResult = @UnitID
	
	-----------------
	BEGIN TRANSACTION
	-----------------
	
	-- Va chercher le ID de la convention
	SELECT @ConventionID = ConventionID
	FROM dbo.Un_Unit 
	WHERE UnitID = @UnitID

	-- Détruit les historiques de modalités de paiements rattachés
	DELETE 
	FROM Un_UnitModalHistory
	WHERE UnitID = @UnitID
	IF @@ERROR <> 0 
		SET @iResult = -2 -- Erreur de suppression des historiques de modalités de paiements rattachés
	
	IF @iResult > 0
	BEGIN
		-- Suppression des horaires de prélèvements
		DELETE 
		FROM Un_AutomaticDeposit
		WHERE UnitID = @UnitID

		IF @@ERROR <> 0 
			SET @iResult = -3 -- Erreur de suppression d'horaire de prélèvement
	END

	IF @iResult > 0
	BEGIN
		-- Supprime les enregistrements 400 de demande de BEC non-expédiés (d'autres seront insérés pour les remplacer)
		DELETE Un_CESP400
		FROM Un_CESP400
		JOIN Un_Cotisation Ct ON Ct.CotisationID = Un_CESP400.CotisationID
		WHERE Ct.UnitID = @UnitID
			AND Un_CESP400.iCESPSendFileID IS NULL
			AND Un_CESP400.tiCESP400TypeID = 24 -- BEC

		IF @@ERROR <> 0
			SET @iResult = -6
	END

	IF @iResult > 0
	BEGIN
		DECLARE
			@iBECOperID INTEGER,
			@dtLastVerifDate DATETIME

		SET @iBECOperID = 0

		-- Va chercher la date de blocage
		SELECT @dtLastVerifDate = LastVerifDate
		FROM Un_Def

		-- Va chercher le ID de l'opération BEC s'il y en a une
		SELECT @iBECOperID = MAX(O.OperID)
		FROM Un_Cotisation Ct
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		WHERE Ct.UnitID = @UnitID
			AND O.OperTypeID = 'BEC'

		-- Recule la date de blocage si nécessaire pour la suppression
		IF @iBECOperID > 0
			UPDATE Un_Def
			SET LastVerifDate = (SELECT OperDate FROM Un_Oper WHERE OperID = @iBECOperID)-1
			WHERE LastVerifDate >= (SELECT OperDate FROM Un_Oper WHERE OperID = @iBECOperID)
		
		-- Supprime l'opération BEC
		IF @@ERROR = 0
		BEGIN
			--ALTER TABLE Un_Cotisation
			--	DISABLE TRIGGER TUn_Cotisation_State

			IF object_id('tempdb..#DisableTrigger') is null
				CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))

			INSERT INTO #DisableTrigger VALUES('TUn_Cotisation_State')				

			DELETE
			FROM Un_Cotisation
			WHERE @iBECOperID = OperID

			--ALTER TABLE Un_Cotisation
			--	ENABLE TRIGGER TUn_Cotisation_State

			Delete #DisableTrigger where vcTriggerName = 'TUn_Cotisation_State'

		END

		IF @@ERROR = 0
			DELETE
			FROM Un_Oper
			WHERE @iBECOperID = OperID

		-- Remet la date de blocage à la date qu'elle devrait avoir
		IF @iBECOperID > 0
			UPDATE Un_Def
			SET LastVerifDate = @dtLastVerifDate
			WHERE LastVerifDate <> @dtLastVerifDate

		IF @@ERROR <> 0
			SET @iResult = -7
	END

	IF @iResult > 0
	BEGIN
		-- Suppression de l'historique des états des groupes d'unités
		DELETE 
		FROM Un_UnitUnitState
		WHERE UnitID = @UnitID

		IF @@ERROR <> 0 
			SET @iResult = -4 -- Erreur de suppression d'historique des états des groupes d'unités
	END

	IF @iResult > 0
	BEGIN
		-- Suppression du groupe d'unités 
		DELETE 
		FROM dbo.Un_Unit 
		WHERE UnitID = @UnitID

		IF @@ERROR <> 0 
			SET @iResult = -1 -- Erreur de suppression du groupe d'unités
	END
	
	IF @iResult > 0
	BEGIN
		-- Appelle de la procédure stockée qui gère les enregistrements 100, 200, et 400 de la convention du groupe d'unités.
		EXECUTE @iExecResult = TT_UN_CESPOfConventions @ConnectID, 0, 0, @ConventionID

		IF @iExecResult <= 0
			SET @iResult = -5 -- Erreur à la gestion des enregistrements 100, 200 et des demandes de BEC
	END

	IF @iResult > 0
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
		--------------------
	
	RETURN (@iResult)
END


