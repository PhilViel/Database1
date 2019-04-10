/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_BeneficiaryAddressLost
Description         :	Procédure servant à activer/désactiver l'adresse perdue sur le bénéficiaire.
Valeurs de retours  :	@ReturnValue :
									>0 :	La sauvegarde a réussie.  La valeur de retour correspond au BeneficiaryID du
											bénéficiaire dont le marqueur d’adresse perdu a été modifié.
									<=0 :	La sauvegarde a échouée.
Note                :	ADX0000706	IA	2005-07-13	Bruno Lapointe			Création
										2011-04-12	Corentin Menthonnex		2011-12 : Ajout du log dans CRQ_Log	
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_BeneficiaryAddressLost] (
	@ConnectID INTEGER, -- Identifiant unique de la connexion de l’usager.	
	@BeneficiaryID INTEGER, -- Identifiant du bénéficiaire.
	@bAddressLost BIT ) -- Valeur du champ bAddressLost.
AS
BEGIN
	DECLARE 
		@LogDesc VARCHAR(5000),
		@ResultID INTEGER,
		@bOldAddressLost VARCHAR(3),
		@bAncien_AddressLost BIT,
		@cSep CHAR(1)

	SET @cSep = CHAR(30)
	SET @ResultID = @BeneficiaryID -- Par défaut retourne le ID du bénéficiaire, s'il n'y a pas d'erreur la valeur restera celle-ci

	-- Vérifie si le bénéficiaire existe
	IF EXISTS (
			SELECT 
				BeneficiaryID
			FROM dbo.Un_Beneficiary 
			WHERE BeneficiaryID = @BeneficiaryID)
	BEGIN -- Le dossier est existant et sera modifié
	
		SELECT 
			@bOldAddressLost =
				CASE bAddressLost
					WHEN 0 THEN 'Non'
				ELSE 'Oui'
				END,
			@bAncien_AddressLost = bAddressLost
		FROM dbo.Un_Beneficiary 
		WHERE BeneficiaryID = @BeneficiaryID		

		UPDATE dbo.Un_Beneficiary 
		SET bAddressLost = @bAddressLost 
		WHERE BeneficiaryID = @BeneficiaryID

		-- Gestion d'erreur
		IF @@ERROR <> 0
			SET @ResultID = -1 -- Erreur : Erreur SQL du Update
		ELSE -- Gestion du log
		BEGIN
			-- Initialisation des variables pour le log
			SET @LogDesc = ''
			
			-- Header du log
			SET @LogDesc = dbo.FN_CRQ_FormatLog ('Un_Beneficiary', 'UPD', '', '')
			-- Détail du log
			SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('Un_Beneficiary', 'bAddressLost', @bOldAddressLost, CASE @bAddressLost WHEN 0 
																																		THEN 'Non'
																																		ELSE 'Oui'
																																   END)
			-- Sauvegarde du log
			EXEC SP_IU_CRQ_Log @ConnectID, 'Un_Beneficiary', @BeneficiaryID, 'U', @LogDesc
				
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
					'Un_Beneficiary',
					@BeneficiaryID,
					GETDATE(),
					2, -- Modification 'U'
					LogDesc = 'Bénéficiaire : '+H.LastName+', '+H.FirstName,
					LogText = 
						CASE WHEN ISNULL(@bAncien_AddressLost, 0) <> ISNULL(B.bAddressLost, 0) 
							THEN 'bAddressLost'+@cSep+
								CAST(ISNULL(@bAncien_AddressLost,0) AS CHAR(1))+@cSep+
								CAST(ISNULL(B.bAddressLost,0) AS CHAR(1))+@cSep+								
								CASE
									WHEN ISNULL(@bAncien_AddressLost, 0) = 0 
									THEN 'Valide'
									ELSE 'Invalide'
								END+@cSep+
								CASE 
									WHEN ISNULL(B.bAddressLost,0) = 0 
									THEN 'Valide'
									ELSE 'Invalide'
								END+@cSep+
								CHAR(13)+CHAR(10)
							ELSE ''
						END
				FROM dbo.Un_Beneficiary B
					JOIN dbo.Mo_Human H ON H.HumanID = B.BeneficiaryID
				WHERE B.BeneficiaryID = @BeneficiaryID
				
		END -- Gestion du log
	END
	ELSE
		SET @ResultID = -2 -- Erreur : Le bénéficiaire n'existe pas

	RETURN @ResultID -- Retourne le résultat 
END


