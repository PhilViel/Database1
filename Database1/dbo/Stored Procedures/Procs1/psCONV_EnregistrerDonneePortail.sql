/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psCONV_EnregistrerDonneePortail
Nom du service		: Modifier les données Portail-Client
But 				: Modifier les données d'un compte d'un souscripteur ou d'un bénéficiaire pour le Portail-Client
Facette				: CONV
Référence			: Noyau-CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				@ConnectID					Identifiant unique de la connection	
						@ID							Identifiant du souscripteur ou du bénéficiaire
						@bConsentement				Consentement du souscripteur ou du bénéficiaire pour le Portail

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------

Exemple utilisation:	
	-- Consentement refusé par un souscripteur
		EXEC psCONV_EnregistrerDonneePortail 1, 601617, 0		
	-- Consentement accepté par un souscripteur
		EXEC psCONV_EnregistrerDonneePortail 1, 601617, 1
	-- Consentement refusé par un bénéficiaire
		EXEC psCONV_EnregistrerDonneePortail 1, 601618, 0		
	-- Consentement accepté par un bénéficiaire
		EXEC psCONV_EnregistrerDonneePortail 1, 601618, 1

TODO:
	
Historique des modifications:
		Date				Programmeur							Description									Référence
		------------		----------------------------	-----------------------------------------	------------
		2011-04-28	Pierre-Luc Simard			Création du service							
		2014-02-20	Pierre-Luc Simard			Utilisation de bReleve_Papier au lieu de bConsentement
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_EnregistrerDonneePortail] (
	@ConnectID INTEGER,
	@ID INTEGER,                     
	@bConsentement BIT) 
AS
BEGIN
	DECLARE
		@bAncienConsentement BIT,	
		@ResultID INTEGER,
		@cSep CHAR(1) -- Variable du caractère séparateur de valeur du blob

	SET @cSep = CHAR(30)

	SET @ResultID = @ID -- Par défaut retourne le ID du souscripteur ou du bénéficiaire, s'il n'y a pas d'erreur la valeur restera celle-ci

	-----------------
	BEGIN TRANSACTION
	-----------------
/*
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
	BEGIN 
*/
		-- Va chercher les anciennes valeurs
		SELECT
			@bAncienConsentement = ISNULL(S.bReleve_Papier, B.bReleve_Papier)
		FROM dbo.Mo_Human H
		LEFT JOIN dbo.Un_Subscriber S ON S.SubscriberID = H.HumanID
		LEFT JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = H.HumanID
		WHERE H.HumanID = @ID
			 AND ISNULL(S.bReleve_Papier, B.bReleve_Papier) IS NOT NULL
		
		-- Met à jour le consentement du souscripteur si ce dernier existe
		UPDATE dbo.Un_Subscriber 
		SET bReleve_Papier = @bConsentement
		WHERE SubscriberID = @ID

		-- Met à jour le consentement du bénéficiaifre si ce dernier existe
		UPDATE dbo.Un_Beneficiary 
		SET bReleve_Papier = @bConsentement
		WHERE BeneficiaryID = @ID		

		IF @@ERROR <> 0
			SET @ResultID = 0

		-- Vérifie si on doit ajouter un log suite aux modifications
		IF EXISTS (
				SELECT
					H.HumanID
				FROM dbo.Mo_Human H
				LEFT JOIN dbo.Un_Subscriber S ON S.SubscriberID = H.HumanID
				LEFT JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = H.HumanID
				WHERE H.HumanID = @ID
					 AND ISNULL(@bAncienConsentement,0) <> ISNULL(S.bReleve_Papier, ISNULL(B.bReleve_Papier,0))						
				)
		BEGIN
			-- Insère un log de l'objet modifié.
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
					'bReleve_Papier'+@cSep+
					CAST(ISNULL(@bAncienConsentement,0) AS VARCHAR)+@cSep+
					CAST(ISNULL(@bConsentement,0) AS VARCHAR)+@cSep+
					CHAR(13)+CHAR(10)
				FROM dbo.Mo_Human H
				JOIN CRQ_LogAction LA ON LA.LogActionShortName = 'U'
				LEFT JOIN dbo.Un_Subscriber S ON S.SubscriberID = H.HumanID
				LEFT JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = H.HumanID
				WHERE H.HumanID = @ID
		END
/*	END
	ELSE
		SET @ResultID = 0 -- Le souscripteur ou le bénéficiaire n'existe pas ou son compte n'a pas été créé sur le Portail-Client
*/
	IF @@ERROR = 0
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
	BEGIN
		--------------------
		ROLLBACK TRANSACTION
		--------------------
		SET @ResultID = 0
	END
	RETURN(@ResultID)
END


