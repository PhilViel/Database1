/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psCONV_ModifierStatutPortail
Nom du service		: Modifier le statut du compte Portail-Client
But 				: Modifier le statut du compte du souscripteur ou du bénéficiaire sur le Portail-Client
Facette				: CONV
Référence			: Noyau-CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				@ConnectID					Identifiant unique de la connection	
						@ID							Identifiant du souscripteur ou du bénéficiaire
						@Action						Activer (0) ou désactiver (1) un compte 

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------

Exemple utilisation:	
	-- Activation d'un compte
		EXEC psCONV_ModifierStatutPortail 1, 601617, 0		
	-- Désactivation d'un compte																				
		EXEC psCONV_ModifierStatutPortail 1, 601617, 1
	
TODO:
	
Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2011-04-21		Pierre-Luc Simard					Création du service			
		2013-01-15		Donald Huppé						glpi 8005 : aller lire directement dans la table tblGENE_PortailEtat si un type d'état peut être activé ou désactivé				
****************************************************************************************************/
CREATE PROCEDURE dbo.psCONV_ModifierStatutPortail (
	@ConnectID INTEGER, -- Identifiant unique de la connection	
	@ID INTEGER, -- Identifiant du souscripteur ou du bénéficiaire
	@Action BIT) -- Activer (0) ou désactiver (1) un compte 
AS
BEGIN
	DECLARE 
		@LogDesc VARCHAR(5000),
		@ResultID INTEGER,
		@AncienEtat VARCHAR(3),
		@NouvelEtat VARCHAR(3),
		@cSep CHAR(1)	-- Variable du caractère séparateur de valeur du blob

	SET @cSep = CHAR(30)

	SET @ResultID = @ID -- Par défaut retourne le ID du souscripteur ou du bénéficiaire, s'il n'y a pas d'erreur la valeur restera celle-ci

	-- Vérifie si le souscripteur ou le bénéficiaire existe et que ce dernier a un compte sur le portail-client
	IF EXISTS (
			SELECT 
				HumanID
			FROM dbo.Mo_Human H
			JOIN tblGENE_PortailAuthentification P ON P.iUserId = H.HumanID
			LEFT JOIN dbo.Un_Subscriber S ON S.SubscriberID = H.HumanID
			LEFT JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = H.HumanID
			WHERE H.HumanID = @ID
				AND (S.SubscriberID IS NOT NULL
					OR B.BeneficiaryID IS NOT NULL)		
			)
	BEGIN -- Le dossier est existant et son statut sera modifié
	
		SELECT 
			@AncienEtat = iEtat
		FROM tblGENE_PortailAuthentification
		WHERE iUserId = @ID		
		
		--IF (@AncienEtat IN (1, 2, 3, 8) AND @Action = 0) -- Activer le compte
		IF (@AncienEtat IN (select iIDEtat from tblGENE_PortailEtat where bActivation = 1 ) AND @Action = 0) -- Activer le compte
			SET @NouvelEtat = 5

		--IF (@AncienEtat IN (1, 2, 4, 5, 8) AND @Action = 1) -- Désactiver le compte
		IF (@AncienEtat IN (select iIDEtat from tblGENE_PortailEtat where bDesactivation = 1 ) AND @Action = 1) -- Désactiver le compte
			SET @NouvelEtat = 3
			
		IF @AncienEtat <> @NouvelEtat 
		BEGIN 
			UPDATE tblGENE_PortailAuthentification
			SET iEtat = @NouvelEtat 
			WHERE iUserId = @ID

			-- Gestion d'erreur
			IF @@ERROR <> 0
				SET @ResultID = -1 -- Erreur : Erreur SQL du Update
			ELSE -- Gestion du log
			BEGIN
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
					CASE WHEN S.SubscriberID IS NOT NULL THEN 'Un_Subscriber' ELSE 'Un_Beneficiary' END,
					@ID,
					GETDATE(),
					LA.LogActionID,
					LogDesc = CASE WHEN S.SubscriberID IS NOT NULL THEN 'Souscripteur : ' ELSE 'Bénéficiaire : ' END + H.LastName + ', ' + H.FirstName,
					LogText =				
						'iEtat'+@cSep+
						CAST(ISNULL(@AncienEtat,0) AS VARCHAR)+@cSep+
						CAST(ISNULL(@NouvelEtat,0) AS VARCHAR)+@cSep+
						CHAR(13)+CHAR(10)
					FROM dbo.Mo_Human H
					JOIN CRQ_LogAction LA ON LA.LogActionShortName = 'U'
					LEFT JOIN dbo.Un_Subscriber S ON S.SubscriberID = H.HumanID
					LEFT JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = H.HumanID
					WHERE H.HumanID = @ID
			END -- Gestion du log
		END
	END
	ELSE
		SET @ResultID = -2 -- Erreur : Le souscripteur ou le bénéficiaire n'existe pas ou son compte n'a pas été créé sur le Portail-Client

	RETURN @ResultID -- Retourne le résultat 
END


