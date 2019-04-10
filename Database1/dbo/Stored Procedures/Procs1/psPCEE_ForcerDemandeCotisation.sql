
/****************************************************************************************************
Code de service	:	psPCEE_ForcerDemandeCotisation
But					:	Forcer les demandes de subventions existantes sur les cotisations.
Description			:	Ce service 	est utilisé pour renverser et resoumettre les demandes de subventions (400) suite à un changement
							au niveau des formulaires reçus dans la convention. 
Facette				:	PCEE

Parametres d'entrée :	Parametres				Description
								----------					----------------
								@ConventionID			Identifiant unique de la convention
								@ConnectID				Identifiant unique de la connection

Exemple d'appel:
				DECLARE @i INT
				EXECUTE @i = dbo.psPCEE_ForcerDemandeCotisation 378750, 2
				PRINT @i
			
Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
                       S/O                          @iResult											> 0 si traitement réussi
																											<= 0	si une erreur est survenue
                    
Historique des modifications :
			
						Date				Programmeur				Description							
						----------		------------------------	----------------------------		
						2015-02-02	Pierre-Luc Simard		Création de la procédure
						2015-02-05	Pierre-Luc Simard		Ajout de la gestion selon les valeurs du champ bFormulaireRecu
 ****************************************************************************************************/

CREATE PROCEDURE dbo.psPCEE_ForcerDemandeCotisation (
    @ConventionID INT ,
    @ConnectID INT,
	@bFormulaireRecuAncien BIT,
	@bFormulaireRecuNouveau BIT
	)
AS
BEGIN
    DECLARE
        @vcLigneBlob VARCHAR(MAX) ,
        @vcLigneBlobCotisation VARCHAR(MAX) ,
        @iCompteLigne INT ,
        @iIDOperCur INT ,
        @iIDCotisationCur INT ,
        @dtDateOperCur DATETIME ,
        @iID_OperTypeBlob CHAR(3) ,
        @iIDBlob INT ,
        @iIDCotisationBlob INT ,
        @iResult INT	

	SET @iResult = 1

	-----------------
	BEGIN TRANSACTION
	-----------------
	
	-- Gestion des 400 si les formulaires sont reçus (Passe de NON à OUI)
	IF	@bFormulaireRecuAncien = 0 AND @bFormulaireRecuNouveau = 1 
	BEGIN 
		-- Vérifier s'il existe des transactions 400-11 envoyées avant la date du jour dont la subvention n'avait pas été demandée (même bénéficiaire et même souscripteur) Et pas plus vieille que 36 mois.
		-- Si oui, alors on renverse ces transactions et on les envoi à nouveau avec demande de subvention = oui.
		DECLARE curBlob CURSOR LOCAL FAST_FORWARD
		FOR
		SELECT
			C4.OperID ,
			C4.CotisationID ,
			C4.dtTransaction ,
			O.OperTypeID
		FROM Un_CESP400 C4
		JOIN dbo.Un_Convention C ON C.ConventionID = C4.ConventionID
		LEFT OUTER JOIN Un_CESP400 R4 ON C4.iCESP400ID = R4.iReversedCESP400ID
		LEFT OUTER JOIN Un_Oper O ON C4.OperID = O.OperID
		WHERE C4.ConventionID = @ConventionID
			AND C.bFormulaireRecu = 1
			AND C.bCESGRequested = 1
			AND C4.tiCESP400TypeID = 11 --Type cotisation.
			AND C4.bCESPDemand = 0 --Subvention non-demandée.
			AND C4.iCESP800ID IS NULL
			AND C4.vcBeneficiarySIN IN (
										SELECT SocialNumber
										FROM Un_HumanSocialNumber
										WHERE HumanID = C.BeneficiaryID
										UNION
										SELECT SocialNumber
										FROM dbo.Mo_Human H
										WHERE H.HumanID = C.BeneficiaryID)
			AND C4.vcSubscriberSINorEN IN (
										SELECT SocialNumber
										FROM Un_HumanSocialNumber
										WHERE HumanID = C.SubscriberID)
			AND R4.iCESP400ID IS NULL -- Pas annulé
			AND C4.iReversedCESP400ID IS NULL -- Pas une annulation
			AND DATEDIFF(MONTH, C4.dtTransaction, GETDATE()) <= 36 -- À revoir avec la notion du 7ème jour du mois suivant.
			AND C4.dtTransaction <= GETDATE()
			
		-- INITIALISATION DES VARIABLES CONTENANT LES BLOBS							
		SET @vcLigneBlob = ''
		SET @vcLigneBlobCotisation = ''
		SET @iCompteLigne = 0

		-- CONSTRUCTION DES BLOBS
		OPEN curBlob
		FETCH NEXT FROM curBlob INTO @iIDOperCur, @iIDCotisationCur, @dtDateOperCur, @iID_OperTypeBlob
		WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @vcLigneBlob = @vcLigneBlob + 'Un_Oper' + ';'
					+ CAST(@iCompteLigne AS VARCHAR(10)) + ';'
					+ CAST(ISNULL(@iIDOperCur, '') AS VARCHAR(8)) + ';'
					+ CAST(@ConnectID AS VARCHAR(10)) + ';'
					+ CAST(ISNULL(@iID_OperTypeBlob, '') AS VARCHAR(10)) + ';'
					+ ';' + CONVERT(VARCHAR(25), ISNULL(@dtDateOperCur, ''), 121)
					+ CHAR(13) + CHAR(10)
				SET @vcLigneBlobCotisation = @vcLigneBlobCotisation
					+ CAST(ISNULL(@iIDCotisationCur, '') AS VARCHAR(10)) + ','
				FETCH NEXT FROM curBlob INTO @iIDOperCur, @iIDCotisationCur, @dtDateOperCur, @iID_OperTypeBlob
			END
		CLOSE curBlob
		DEALLOCATE curBlob
		
		IF (RTRIM(LTRIM(@vcLigneBlobCotisation)) <> ''
			AND RTRIM(LTRIM(@vcLigneBlobCotisation)) <> ','
		   )
			BEGIN
				-- INSERTION DES BLOBS
				EXECUTE @iIDBlob			= dbo.IU_CRI_Blob 0, @vcLigneBlob
				EXECUTE @iIDCotisationBlob	= dbo.IU_CRI_Blob 0,
					@vcLigneBlobCotisation
							
				-- RENVERSEMENT ET RENVOIS DES TRANSACTIONS
				EXEC @iResult = dbo.IU_UN_ReSendCotisationCESP400 @ConventionID, @iIDCotisationBlob, @iIDBlob, @ConnectID, 1 -- 2010-04-29 : JFG : Ajout de @bSansVerificationPCEE400
			END
	
		IF @@ERROR <> 0 OR @iResult <= 0
			SET @iResult = -1
	
		-- Mise à jour des transactions 400-11 non-envoyés, on doit mettre bCESPDemand à OUI.
	/*	IF @iResult > 0
			UPDATE C4 SET 
				bCESPDemand = 1/*,
				vcPCGSINorEN =  
					CASE 
						WHEN C.bACESGRequested = 0 THEN NULL
					ELSE ISNULL(C4.vcPCGSINorEN, B.vcPCGSINOrEN)
					END,
				vcPCGFirstName = 
					CASE 
						WHEN C.bACESGRequested = 0 THEN NULL
					ELSE ISNULL(C4.vcPCGFirstName, B.vcPCGFirstName)
					END,
				vcPCGLastName = 
					CASE 
						WHEN C.bACESGRequested = 0 THEN NULL
					ELSE ISNULL(C4.vcPCGLastName, B.vcPCGLastName)
					END,
				tiPCGType = ISNULL(C4.tiPCGType, B.tiPCGType)*/
			FROM Un_CESP400 C4
			JOIN dbo.Un_Convention C ON C.ConventionID = C4.ConventionID
			JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
			WHERE C4.iCESPSendFileID IS NULL
				AND C4.ConventionID = @ConventionID
				AND C4.tiCESP400TypeID = 11
				AND C4.bCESPDemand = 0
				AND C.bFormulaireRecu = 1
				AND C.bCESGRequested = 1
				AND C4.iReversedCESP400ID IS NULL -- Pas une annulation
	*/
		IF @@ERROR <> 0
			SET @iResult = -2
	END 

	-- Gestion des 400 si les formulaires sont reçus (Passe de OUI à NON)
	IF	@bFormulaireRecuAncien = 1 AND @bFormulaireRecuNouveau = 0 
	BEGIN
		-- Mise à jour des transactions 400-11 non-envoyés, on doit mettre bCESPDemand à NON.
		IF @iResult > 0
			UPDATE C4 SET 
				bCESPDemand = 0,
				vcPCGSINorEN = NULL,
				vcPCGFirstName = NULL,
				vcPCGLastName = NULL
			FROM Un_CESP400 C4
			JOIN dbo.Un_Convention C ON C.ConventionID = C4.ConventionID
			WHERE C4.iCESPSendFileID IS NULL
				AND C4.ConventionID = @ConventionID
				AND C4.tiCESP400TypeID = 11
				AND C4.bCESPDemand = 1
				AND (C.bFormulaireRecu = 0
					OR C.bCESGRequested = 0)
				AND C4.iReversedCESP400ID IS NULL -- Pas une annulation
	
		IF @@ERROR <> 0
			SET @iResult = -3

		-- Vérifier s'il existe des transactions 400-11 envoyées avant la date du jour dont la subvention avait été demandée (même bénéficiaire et même souscripteur).
		-- Si oui, alors on renverse ces transactions et on les envoi à nouveau avec demande de subvention = NON.
		IF @iResult > 0
		BEGIN
			DECLARE curBlob CURSOR LOCAL FAST_FORWARD
			FOR
			SELECT
				C4.OperID ,
				C4.CotisationID ,
				C4.dtTransaction ,
				O.OperTypeID
			FROM Un_CESP400 C4
			JOIN dbo.Un_Convention C ON C.ConventionID = C4.ConventionID
			LEFT OUTER JOIN Un_CESP400 R4 ON C4.iCESP400ID = R4.iReversedCESP400ID
			LEFT OUTER JOIN Un_Oper O ON C4.OperID = O.OperID
			WHERE C4.ConventionID = @ConventionID
				AND C.bFormulaireRecu = 0
				AND C4.tiCESP400TypeID = 11 --Type cotisation.
				AND C4.bCESPDemand = 1 --Subvention demandée.
				AND C4.iCESP800ID IS NULL
				AND C4.vcBeneficiarySIN IN (
											SELECT SocialNumber
											FROM Un_HumanSocialNumber
											WHERE HumanID = C.BeneficiaryID
											UNION
											SELECT SocialNumber
											FROM dbo.Mo_Human H
											WHERE H.HumanID = C.BeneficiaryID)
				AND C4.vcSubscriberSINorEN IN (
											SELECT SocialNumber
											FROM Un_HumanSocialNumber
											WHERE HumanID = C.SubscriberID)
				AND R4.iCESP400ID IS NULL -- Pas annulé
				AND C4.iReversedCESP400ID IS NULL -- Pas une annulation
				AND C4.iCESPSendFileID IS NOT NULL -- Envoyée!
	
			-- INITIALISATION DES VARIABLES CONTENANT LES BLOBS							
			SET @vcLigneBlob = ''
			SET @vcLigneBlobCotisation = ''
			SET @iCompteLigne = 0

			-- CONSTRUCTION DES BLOBS
			OPEN curBlob
			FETCH NEXT FROM curBlob INTO @iIDOperCur, @iIDCotisationCur, @dtDateOperCur, @iID_OperTypeBlob
			WHILE @@FETCH_STATUS = 0
				BEGIN
					SET @vcLigneBlob = @vcLigneBlob + 'Un_Oper' + ';'
						+ CAST(@iCompteLigne AS VARCHAR(10)) + ';'
						+ CAST(ISNULL(@iIDOperCur, '') AS VARCHAR(8)) + ';'
						+ CAST(@ConnectID AS VARCHAR(10)) + ';'
						+ CAST(ISNULL(@iID_OperTypeBlob, '') AS VARCHAR(10)) + ';'
						+ ';' + CONVERT(VARCHAR(25), ISNULL(@dtDateOperCur, ''), 121)
						+ CHAR(13) + CHAR(10)
					SET @vcLigneBlobCotisation = @vcLigneBlobCotisation
						+ CAST(ISNULL(@iIDCotisationCur, '') AS VARCHAR(10)) + ','
					FETCH NEXT FROM curBlob INTO @iIDOperCur, @iIDCotisationCur, @dtDateOperCur, @iID_OperTypeBlob
				END
			CLOSE curBlob
			DEALLOCATE curBlob
		
			IF (RTRIM(LTRIM(@vcLigneBlobCotisation)) <> ''
				AND RTRIM(LTRIM(@vcLigneBlobCotisation)) <> ','
			   )
				BEGIN
					-- INSERTION DES BLOBS
					EXECUTE @iIDBlob			= dbo.IU_CRI_Blob 0, @vcLigneBlob
					EXECUTE @iIDCotisationBlob	= dbo.IU_CRI_Blob 0,
						@vcLigneBlobCotisation
						
					-- RENVERSEMENT ET RENVOIS DES TRANSACTIONS
					EXEC @iResult = dbo.IU_UN_ReSendCotisationCESP400 @ConventionID, @iIDCotisationBlob, @iIDBlob, @ConnectID, 1 
				END
		END

		IF @@ERROR <> 0 OR @iResult <= 0
			SET @iResult = -4
	END 
    
	IF @iResult > 0
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
		--------------------
	
	RETURN(@iResult)
END


