/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: SP_IU_UN_SubscriberAddressLost
Nom du service		: Procédure servant à activer/désactiver l'adresse perdue sur le souscripteur
But 				: Procédure servant à activer/désactiver l'adresse perdue sur le souscripteur
Facette				: 

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						iID_Oper					Identifiant unique de connexion de l'usager.
											
Exemple d’appel		:	

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2004-05-31		Bruno Lapointe						Création de la stored procedure pour 10.23.1 (4.3)
		2011-04-12		Corentin Menthonnex					2011-12 : Ajout du log dans la bonne table de log							

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_IU_UN_SubscriberAddressLost] (
	@ConnectID INTEGER, -- Identifiant unique de la connection	
	@SubscriberID INTEGER, -- Identifiant du souscripteur
	@AddressLost BIT) -- Valuer du champs AddressLost
AS
BEGIN

   		DECLARE 
			@LogDesc VARCHAR(5000),
			@ResultID INTEGER,
			@OldAddressLost VARCHAR(3),
			@bAncien_AddressLost BIT,
			@cSep CHAR(1)

		SET @cSep = CHAR(30)
		SET @ResultID = @SubscriberID -- Par défaut retourne le ID du souscripteur, s'il n'y a pas d'erreur la valeur restera celle-ci

		-- Vérifie si le souscripteur existe
		IF EXISTS (
				SELECT 
					SubscriberID
				FROM dbo.Un_Subscriber 
				WHERE SubscriberID = @SubscriberID)
		BEGIN -- Le dossier est existant et sera modifié
	
			SELECT 
				@OldAddressLost =
					CASE AddressLost
						WHEN 0 THEN 'Non'
					ELSE 'Oui'
					END,
				@bAncien_AddressLost = AddressLost
			FROM dbo.Un_Subscriber 
			WHERE SubscriberID = @SubscriberID		

			UPDATE dbo.Un_Subscriber 
			SET AddressLost = @AddressLost 
			WHERE SubscriberID = @SubscriberID

			-- Gestion d'erreur
			IF @@ERROR <> 0
				SET @ResultID = -1 -- Erreur : Erreur SQL du Update
			ELSE -- Gestion du log
			BEGIN
				-- Initialisation des variables pour le log
				SET @LogDesc = ''
				
				-- Header du log
				SET @LogDesc = dbo.FN_CRQ_FormatLog ('Un_Subscriber', 'UPD', '', '')
				-- Détail du log
				SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('Un_Subscriber', 'AddressLost', @OldAddressLost, CASE @AddressLost WHEN 0 
																																		THEN 'Non'
																																		ELSE 'Oui'
																																   END)
				-- Sauvegarde du log
				EXEC SP_IU_CRQ_Log @ConnectID, 'Un_Subscriber', @SubscriberID, 'U', @LogDesc
				
				-- 2011-12 : +CM
				-- Insertion dans le bon log (CRQ_Log)
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
						@SubscriberID,
						GETDATE(),
						2, -- Modification 'U'
						LogDesc = 'Souscripteur : '+H.LastName+', '+H.FirstName,
						LogText =							
							CASE WHEN ISNULL(@bAncien_AddressLost, 0) <> ISNULL(S.AddressLost, 0) 
								THEN 'AddressLost'+@cSep+
									CAST(ISNULL(@bAncien_AddressLost,0) AS CHAR(1))+@cSep+
									CAST(ISNULL(S.AddressLost,0) AS CHAR(1))+@cSep+									
									CASE
										WHEN ISNULL(@bAncien_AddressLost, 0) = 0 
										THEN 'Valide'
										ELSE 'Invalide'
									END+@cSep+
									CASE 
										WHEN ISNULL(S.AddressLost,0) = 0 
										THEN 'Valide'
										ELSE 'Invalide'
									END+@cSep+
									CHAR(13)+CHAR(10)
								ELSE ''
						END
					FROM dbo.Un_Subscriber S
						JOIN dbo.Mo_Human H ON H.HumanID = S.SubscriberID
					WHERE S.SubscriberID = @SubscriberID
				
			END -- Gestion du log
		END
		ELSE
			SET @ResultID = -2 -- Erreur : Le souscripteur n'existe pas

		RETURN @ResultID -- Retourne le résultat 
        
END


