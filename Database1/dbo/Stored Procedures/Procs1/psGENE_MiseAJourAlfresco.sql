
/****************************************************************************************************
Code de service		:		dbo.psGENE_MiseAJourAlfresco
Nom du service		:		psGENE_MiseAJourAlfresco
But					:		Envois des informations modifiés au service web Alfresco
Facette				:		
Reférence			:		

Parametres d'entrée :	Parametres					Description                              Obligatoire
                        ----------                  ----------------                         --------------                       
						bExporterTout				Indique si on doit exporter toutes		= 1 : exporte toutes les conventions, modifiés ou non
													les conventions ou non					= 0 : exporte uniquement les informations modifiés
Exemple d'appel:

			update dbo.Mo_Human
			set FirstName = 'Jocelyn'
			where HumanID = 418145

			update dbo.Mo_Human
			set FirstName = 'Chantal'
			where HumanID = 418966

			DECLARE @i INT
			EXECUTE @i = dbo.psGENE_MiseAJourAlfresco 1
			SELECT @i


Parametres de sortie :  Table											Champs							Description
					    -----------------								---------------------------		--------------------------
						N/A
						@iRetour										=1								Traitement effectué avec succès
																		=0								Aucune modification à exporter
																		=-1								Traitement en erreur

						Les champs envoyés au service web sont les suivants :

						ConventionNo				= c.ConventionNO
						SubscriberID				= c.SubscriberID
						BeneficiaryID				= c.BeneficiaryID
						Nom du souscripteur			= hs.LastName
						Prénom du souscripteur		= hs.FirstName
						Nom du bénéficiaire			= hb.LastName
						Prénom du bénéficiaire		= hb.FirstName
						Date de fin de régime de la convention	= dbo.fnCONV_ObtenirDateFinRegime(c.ConventionID, 'R', NULL) 
						Adresse du souscripteur		= ads.Address
						Ville du souscripteur		= ads.City
						Province du souscripteur	= ads.StateName
						Pays du souscripteur		= cosb.CountryName
						Code postal du souscripteur = ads.ZipCode
						Adresse du bénéficiaire		= adb.Address
						Ville du bénéficiaire		= adb.City
						Province du bénéficiaire	= adb.StateName
						Pays du bénéficiaire		= cob.CountryName
						Code postal du bénéficiaire	= adb.ZipCode

Historique des modifications :
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2011-01-26					Jean-François Gauthier					Création de la procédure						
						2011-03-08					Jean-François Gauthier					Élimination du ID et du UniqueID dans la chaîne de caractère
																							Ajout de l'appel à la fonction CLR
						2011-03-15					Jean-François Gauthier					Correction d'un bug sur l'envois massif
						2011-03-16					Jean-François Gauthier					Ajout de la suppression des données (deleteall = true) avant l'envois massif
						2011-04-20					Pierre-Luc Simard						Modification du Varchar(35) pour un Varchar(50) pour les LastName
  ****************************************************************************************************/

CREATE PROCEDURE dbo.psGENE_MiseAJourAlfresco
		(
			@bExporterTout		BIT = 0
		)
AS
	BEGIN

		SET NOCOUNT ON

		DECLARE 
			@iRetour			INT
			,@iErrSeverity		INT
			,@iErrState			INT
			,@vcErrmsg			VARCHAR(1024)
			,@iCodeErreur		INT			
			,@vcConventionNO	VARCHAR(15)
			,@iSubscriberID		INT
			,@iBeneficiaryID	INT
			,@vcLastNameS		VARCHAR(50)
			,@vcFirstNameS		VARCHAR(50)
			,@vcLastNameB		VARCHAR(50)
			,@FirstNameB		VARCHAR(50)
			,@dtFinRegisme		DATETIME
			,@vcAddressS		VARCHAR(75)
			,@vcCityS			VARCHAR(100)
			,@vcStateNameS		VARCHAR(75)
			,@vcCountryNameS	VARCHAR(75)
			,@vcZipCodeS		VARCHAR(10)
			,@vcAddressB		VARCHAR(75)
			,@vcCityB			VARCHAR(100)
			,@vcStateNameB		VARCHAR(75)
			,@vcCountryNameB	VARCHAR(75)
			,@vcZipCodeB		VARCHAR(10)
			,@vcPost			VARCHAR(4000)
			,@vcLignePost		VARCHAR(1000)
			,@vcLignePostTmp	VARCHAR(1000)
			,@iCompteLignePost	INT
			,@iID				INT				-- ???? D'où provient cette valeur 
			,@vcUniqueId		VARCHAR(100)	-- ???? D'où provient cette valeur 
			,@vcURL						NVARCHAR(255)
			,@bNeedAuthentification		BIT
			,@vcUserName_Post			NVARCHAR(255)
			,@vcPassword_Post			NVARCHAR(255)
			,@iTimeOut					INT		
			,@vcParamNames_tblPipes		NVARCHAR(MAX)
			,@vcParamValues_tblPipes	NVARCHAR(MAX)
			,@vcRetour					NVARCHAR(255)

--		@vcPost = '{'
--		SET @vcLignePost = '"Uniaccess_@@@iCompteLignePost":{"id":@@@iId,"convention_number":"@@@vcConventionNO","subscriber_id":@@@iSubscriberID,"beneficiary_id":@@@iBeneficiaryID,"sous_last_name":"@@@vcLastNameS","sous_first_name":"@@@vcFirstNameS","ben_last_name":"@@@vcLastNameB","ben_first_name":"@@@vcFirstNameB","date_fin_regime":@@@dtFinRegisme,"sous_address":"@@@vcAddressS","sous_city":"@@@vcCityS","sous_state":"@@@vcStateNameS","sous_country":"@@@vcCountryNameS","sous_postalcode":"@@@vcZipCodeS","ben_address":"@@@vcAddressB","ben_city":"@@@vcCityB","ben_state":"@@@vcStateNameB","ben_country":"@@@vcCountryNameB","ben_postalcode":"@@@vcZipCodeB","uniqueid":"@@@vcUniqueId"}'
--		@vcPost = '}'
		
		SET @bExporterTout = ISNULL(@bExporterTout,0)
		
		DECLARE
			@tConvention	TABLE (ConventionID INT)

		BEGIN TRY
			IF @bExporterTout = 0
				BEGIN
					-- SÉLECTION DES ENREGISTREMENTS MODIFIÉS
					INSERT INTO @tConvention
					(
						ConventionID
					)
					SELECT
						c.ConventionID	
					FROM
						dbo.Un_Convention c
						INNER JOIN dbo.Mo_Human hs
							ON hs.HumanId = c.SubscriberId
						INNER JOIN dbo.Mo_Adr ads
							ON hs.AdrId = ads.AdrId
						INNER JOIN dbo.Mo_Country cosb
							ON ads.CountryID = cosb.CountryID
						INNER JOIN dbo.Mo_Human hb
							ON hb.HumanId = c.BeneficiaryId
						INNER JOIN dbo.Mo_Adr adb
							ON hb.AdrId = adb.AdrId
						INNER JOIN dbo.Mo_Country cob
							ON adb.CountryID = cob.CountryID
					WHERE
						(	
							-- changement sur la convention
							(BINARY_CHECKSUM(c.ConventionNO,c.SubscriberID,c.BeneficiaryID,c.dtRegEndDateAdjust, dbo.fnCONV_ObtenirDateFinRegime(c.ConventionID, 'R', NULL)) <> c.iCheckSum)		
							OR -- changement sur souscripteur
							(BINARY_CHECKSUM(hs.LastName, hs.FirstName) <> hs.iCheckSum)			
							OR	-- changement sur le bénéficiaire
							(BINARY_CHECKSUM(hb.LastName, hb.FirstName) <> hb.iCheckSum)			
							OR	-- changement sur les coordonnées du souscripteur
							(BINARY_CHECKSUM(ads.Address, ads.City, ads.StateName, ads.CountryId, ads.ZipCode) <> ads.iCheckSum)			
							OR -- changement sur les coordonnées du bénéficiare
							(BINARY_CHECKSUM(adb.Address, adb.City, adb.StateName, adb.CountryId, adb.ZipCode) <> adb.iCheckSum)			
						)
				END
			ELSE
				BEGIN
					INSERT INTO @tConvention
					(
						ConventionID
					)
					SELECT
						c.ConventionID	
					FROM
						dbo.Un_Convention c
						INNER JOIN dbo.Mo_Human hs
							ON hs.HumanId = c.SubscriberId
						INNER JOIN dbo.Mo_Adr ads
							ON hs.AdrId = ads.AdrId
						INNER JOIN dbo.Mo_Country cosb
							ON ads.CountryID = cosb.CountryID
						INNER JOIN dbo.Mo_Human hb
							ON hb.HumanId = c.BeneficiaryId
						INNER JOIN dbo.Mo_Adr adb
							ON hb.AdrId = adb.AdrId
						INNER JOIN dbo.Mo_Country cob
							ON adb.CountryID = cob.CountryID
				END
			
			-- SI AUCUN ENREGISTREMENT, ON ARRÊTE LE TRAITEMENT
			IF (SELECT COUNT(*) FROM @tConvention) = 0
				BEGIN
					SET @iRetour = 0
					RETURN @iRetour
				END

			-- RÉCUPÉRATION DES PARAMÈTRES DU SERVICE WEB
			SELECT 
				@vcURL						= dbo.fnGENE_ObtenirParametre('POST_ALFRESCO', NULL, 'URLPost', NULL, NULL, NULL, NULL)
				,@bNeedAuthentification		= 0
				,@vcUserName_Post			= dbo.fnGENE_ObtenirParametre('POST_ALFRESCO', NULL, 'user_post', NULL, NULL, NULL, NULL)
				,@vcPassword_Post			= dbo.fnGENE_ObtenirParametre('POST_ALFRESCO', NULL, 'password_post', NULL, NULL, NULL, NULL)	
				,@iTimeOut					= 10000
				,@vcParamNames_tblPipes		= 'deleteall|user_post|password_post|datajson' 
				


			-- CONSTRUCTION DE LA CHAINE DE CARACTÈRE À ENVOYER AU SERVICE WEB				
			DECLARE curPost CURSOR LOCAL FAST_FORWARD
			FOR
				SELECT
						c.ConventionNO
						,c.SubscriberID
						,c.BeneficiaryID
						,hs.LastName
						,hs.FirstName
						,hb.LastName
						,hb.FirstName
						,dtFinRegisme = dbo.fnCONV_ObtenirDateFinRegime(c.ConventionID, 'R', NULL) --dtRegEndDateAdjust = ISNULL(c.dtRegEndDateAdjust,'')
						,ads.Address
						,ads.City
						,ads.StateName
						,cosb.CountryName
						,ads.ZipCode
						,adb.Address
						,adb.City
						,adb.StateName
						,cob.CountryName
						,adb.ZipCode
						,c.ConventionID
				FROM
					@tConvention t
					INNER JOIN dbo.Un_Convention c
						ON t.ConventionID = c.ConventionID
					INNER JOIN dbo.Mo_Human hs
						ON hs.HumanId = c.SubscriberId
					INNER JOIN dbo.Mo_Adr ads
						ON hs.AdrId = ads.AdrId
					INNER JOIN dbo.Mo_Country cosb
						ON ads.CountryID = cosb.CountryID
					INNER JOIN dbo.Mo_Human hb
						ON hb.HumanId = c.BeneficiaryId
					INNER JOIN dbo.Mo_Adr adb
						ON hb.AdrId = adb.AdrId
					INNER JOIN dbo.Mo_Country cob
						ON adb.CountryID = cob.CountryID

			SET @vcPost = '{'
			--SET @vcLignePost = '"Uniaccess_@@@iCompteLignePost":{"id":@@@iId,"convention_number":"@@@vcConventionNO","subscriber_id":@@@iSubscriberID,"beneficiary_id":@@@iBeneficiaryID,"sous_last_name":"@@@vcLastNameS","sous_first_name":"@@@vcFirstNameB","ben_last_name":"@@@vcLastNameB","ben_first_name":"@@@vcFirstNameB","date_fin_regime":"@@@dtFinRegisme","sous_address":"@@@vcAddressS","sous_city":"@@@vcCityS","sous_state":"@@@vcStateNameS","sous_country":"@@@vcCountryNameS","sous_postalcode":"@@@vcZipCodeS","ben_address":"@@@vcAddressB","ben_city":"@@@vcCityB","ben_state":"@@@vcStateNameB","ben_country":"@@@vcCountryNameB","ben_postalcode":"@@@vcZipCodeB","uniqueid":"@@@vcUniqueId"}'
			SET @vcLignePost = '"Uniaccess_@@@iCompteLignePost":{"convention_number":"@@@vcConventionNO","subscriber_id":@@@iSubscriberID,"beneficiary_id":@@@iBeneficiaryID,"sous_last_name":"@@@vcLastNameS","sous_first_name":"@@@vcFirstNameS","ben_last_name":"@@@vcLastNameB","ben_first_name":"@@@vcFirstNameB","date_fin_regime":"@@@dtFinRegisme","sous_address":"@@@vcAddressS","sous_city":"@@@vcCityS","sous_state":"@@@vcStateNameS","sous_country":"@@@vcCountryNameS","sous_postalcode":"@@@vcZipCodeS","ben_address":"@@@vcAddressB","ben_city":"@@@vcCityB","ben_state":"@@@vcStateNameB","ben_country":"@@@vcCountryNameB","ben_postalcode":"@@@vcZipCodeB"}'

			SET @iCompteLignePost = 0	
			SET @vcLignePostTmp = @vcLignePost						


			OPEN curPost
			FETCH NEXT FROM curPost INTO	@vcConventionNO, @iSubscriberID, @iBeneficiaryID, @vcLastNameS, @vcFirstNameS, @vcLastNameB, @FirstNameB, 
											@dtFinRegisme, @vcAddressS, @vcCityS, @vcStateNameS, @vcCountryNameS, @vcZipCodeS, @vcAddressB, @vcCityB, 
											@vcStateNameB, @vcCountryNameB, @vcZipCodeB, @iID				
			WHILE @@FETCH_STATUS = 0
				BEGIN
					IF LEN(@vcPost) >= 3000
						BEGIN
							-- RETRAIT DE LA VIRGULE EN TROP
							SET @vcPost = LEFT(@vcPost, LEN(@vcPost)-1)
							-- FERMETURE DE L'ACCOLADE
							SET @vcPost = @vcPost + '}'					

							-- APPEL DU SERVICE WEB
							SET @vcPost = REPLACE(@vcPost,'"null"','null')
							
							IF @bExporterTout = 0
								BEGIN
									SELECT
										@vcParamValues_tblPipes	= 'false|' + dbo.fnGENE_ObtenirParametre('POST_ALFRESCO', NULL, 'user_post', NULL, NULL, NULL, NULL) + '|' + dbo.fnGENE_ObtenirParametre('POST_ALFRESCO', NULL, 'password_post', NULL, NULL, NULL, NULL) + '|' + @vcPost
								END
							ELSE
								BEGIN
									SELECT
										@vcParamValues_tblPipes	= 'true|' + dbo.fnGENE_ObtenirParametre('POST_ALFRESCO', NULL, 'user_post', NULL, NULL, NULL, NULL) + '|' + dbo.fnGENE_ObtenirParametre('POST_ALFRESCO', NULL, 'password_post', NULL, NULL, NULL, NULL) + '|' + @vcPost
									SET @bExporterTout = 0 -- évite de supprimer à chaque appel
								END
								
							PRINT @vcPost 
							SELECT
								@vcRetour = dbo.fntGENE_RestFullPost(
																	@vcURL						
																	,@bNeedAuthentification		
																	,NULL			
																	,NULL			
																	,@iTimeOut					
																	,@vcParamNames_tblPipes		
																	,@vcParamValues_tblPipes	
																	)
							
							IF LTRIM(RTRIM(@vcRetour)) NOT LIKE '%200%OK%'	-- Il s'est produit une erreur
								BEGIN	
									SET @vcRetour = 'Erreur lors de l''appel au service WEB - ' + @vcRetour
									RAISERROR (
												@vcRetour,	-- Message.
												16,											-- Severité.
												1											-- État.
											   )
								END

							-- RÉINITIALISATION DES VARIABLES NÉCESSAIRES AU POST
							SET @vcPost = '{'
							SET @iCompteLignePost = 0	-- PERMET DE RAMENER LA VALEUR À ZÉRO
						END
					
					-- REMPLACEMENT DES TAGS PAR LES VALEURS DE LA BD
					SET @vcLignePostTmp = REPLACE(@vcLignePostTmp,'@@@iCompteLignePost'	,CAST(@iCompteLignePost AS VARCHAR(6)))
					--SET @vcLignePostTmp = REPLACE(@vcLignePostTmp,'@@@iId'				,@iID)
					SET @vcLignePostTmp = REPLACE(@vcLignePostTmp,'@@@vcConventionNO'	,ISNULL(@vcConventionNO,'null'))
					SET @vcLignePostTmp = REPLACE(@vcLignePostTmp,'@@@iSubscriberID'	,ISNULL(CAST(@iSubscriberID AS VARCHAR(8)),'null'))
					SET @vcLignePostTmp = REPLACE(@vcLignePostTmp,'@@@iBeneficiaryID'	,ISNULL(CAST(@iBeneficiaryID AS VARCHAR(8)),'null'))
					SET @vcLignePostTmp = REPLACE(@vcLignePostTmp,'@@@vcLastNameS'		,ISNULL(@vcLastNameS,'null'))
					SET @vcLignePostTmp = REPLACE(@vcLignePostTmp,'@@@vcFirstNameS'		,ISNULL(@vcFirstNameS,'null'))
					SET @vcLignePostTmp = REPLACE(@vcLignePostTmp,'@@@vcLastNameB'		,ISNULL(@vcLastNameB,'null'))
					SET @vcLignePostTmp = REPLACE(@vcLignePostTmp,'@@@vcFirstNameB'		,ISNULL(@FirstNameB,'null'))
					SET @vcLignePostTmp = REPLACE(@vcLignePostTmp,'@@@dtFinRegisme'		,ISNULL(CONVERT(VARCHAR(10),@dtFinRegisme,121),'null'))			
					SET @vcLignePostTmp = REPLACE(@vcLignePostTmp,'@@@vcAddressS'		,ISNULL(@vcAddressS,'null'))					
					SET @vcLignePostTmp = REPLACE(@vcLignePostTmp,'@@@vcCityS'			,ISNULL(@vcCityS,'null'))					
					SET @vcLignePostTmp = REPLACE(@vcLignePostTmp,'@@@vcStateNameS'		,ISNULL(@vcStateNameS,'null'))					
					SET @vcLignePostTmp = REPLACE(@vcLignePostTmp,'@@@vcCountryNameS'	,ISNULL(@vcCountryNameS,'null'))					
					SET @vcLignePostTmp = REPLACE(@vcLignePostTmp,'@@@vcZipCodeS'		,ISNULL(@vcZipCodeS,'null'))					
					SET @vcLignePostTmp = REPLACE(@vcLignePostTmp,'@@@vcAddressB'		,ISNULL(@vcAddressB,'null'))					
					SET @vcLignePostTmp = REPLACE(@vcLignePostTmp,'@@@vcCityB'			,ISNULL(@vcCityB,'null'))					
					SET @vcLignePostTmp = REPLACE(@vcLignePostTmp,'@@@vcStateNameB'		,ISNULL(@vcStateNameB,'null'))					
					SET @vcLignePostTmp = REPLACE(@vcLignePostTmp,'@@@vcCountryNameB'	,ISNULL(@vcCountryNameB,'null'))					
					SET @vcLignePostTmp = REPLACE(@vcLignePostTmp,'@@@vcZipCodeB'		,ISNULL(@vcZipCodeB,'null'))		
					--SET @vcLignePostTmp = REPLACE(@vcLignePostTmp,'@@@vcUniqueId'		,'id' + CAST(@iCompteLignePost AS VARCHAR(6)))		

					SET  @iCompteLignePost = @iCompteLignePost + 1
					SET @vcPost = @vcPost	+ @vcLignePostTmp + ','
					SET @vcLignePostTmp = @vcLignePost
					
					FETCH NEXT FROM curPost INTO @vcConventionNO, @iSubscriberID, @iBeneficiaryID, @vcLastNameS, @vcFirstNameS, @vcLastNameB, @FirstNameB, @dtFinRegisme, @vcAddressS, @vcCityS, @vcStateNameS, @vcCountryNameS, @vcZipCodeS, @vcAddressB, @vcCityB, @vcStateNameB, @vcCountryNameB, @vcZipCodeB, @iID		
				END
			CLOSE curPost
			DEALLOCATE curPost

			-- ENVOIS DE LA DERNIÈRE CHAINE SI PRÉSENTE
			IF LEN(@vcPost) > 10
				BEGIN
					-- RETRAIT DE LA VIRGULE EN TROP
					SET @vcPost = LEFT(@vcPost, LEN(@vcPost)-1)
					-- FERMETURE DE L'ACCOLADE
					SET @vcPost = @vcPost + '}'					
					
					-- APPEL DU SERVICE WEB
					SET @vcPost = REPLACE(@vcPost,'"null"','null')

					PRINT @vcPost

					SELECT
						@vcParamValues_tblPipes	= 'false|' + dbo.fnGENE_ObtenirParametre('POST_ALFRESCO', NULL, 'user_post', NULL, NULL, NULL, NULL) + '|' + dbo.fnGENE_ObtenirParametre('POST_ALFRESCO', NULL, 'password_post', NULL, NULL, NULL, NULL) + '|' + @vcPost

					SELECT
						@vcRetour = dbo.fntGENE_RestFullPost(
													@vcURL						
													,@bNeedAuthentification		
													,NULL			
													,NULL			
													,@iTimeOut					
													,@vcParamNames_tblPipes		
													,@vcParamValues_tblPipes	
															)

					IF  LTRIM(RTRIM(@vcRetour)) NOT LIKE '%200%OK%'	-- Il s'est produit une erreur
						BEGIN	
							SET @vcRetour = 'Erreur lors de l''appel au service WEB - ' + @vcRetour
							RAISERROR (
										@vcRetour,	-- Message.
										16,											-- Severité.
										1											-- État.
									   )
						END
				END

			-- MISE À JOUR DU CHECKSUM DES ENREGISTREMENTS MODIFIÉS
			-- UN_Convention
			UPDATE c
			SET c.iCheckSum = BINARY_CHECKSUM(c.ConventionNO,c.SubscriberID,c.BeneficiaryID,c.dtRegEndDateAdjust, dbo.fnCONV_ObtenirDateFinRegime(c.ConventionID, 'R', NULL))
			FROM
				@tConvention t
				INNER JOIN dbo.Un_Convention c
					ON t.ConventionID = c.ConventionID		

			-- Mo_Human (soucripteur)
			UPDATE hs
			SET hs.iCheckSum = BINARY_CHECKSUM(hs.LastName,hs.FirstName)
			FROM
				@tConvention t
				INNER JOIN dbo.Un_Convention c
					ON t.ConventionID = c.ConventionID
				INNER JOIN dbo.Mo_Human hs
					ON hs.HumanId = c.SubscriberId

			-- Mo_Human (bénéficiaire)
			UPDATE hb
			SET hb.iCheckSum = BINARY_CHECKSUM(hb.LastName,hb.FirstName)
			FROM
				@tConvention t
				INNER JOIN dbo.Un_Convention c
					ON t.ConventionID = c.ConventionID
				INNER JOIN dbo.Mo_Human hb
					ON hb.HumanId = c.BeneficiaryId

			-- Mo_Adr (souscripteur)
			UPDATE ads
			SET	ads.iCheckSum = BINARY_CHECKSUM(ads.Address, ads.City, ads.StateName, ads.CountryId, ads.ZipCode)	
			FROM
				@tConvention t
				INNER JOIN dbo.Un_Convention c
					ON t.ConventionID = c.ConventionID
				INNER JOIN dbo.Mo_Human hs
					ON hs.HumanId = c.SubscriberId
				INNER JOIN dbo.Mo_Adr ads
					ON hs.AdrId = ads.AdrId

			-- Mo_Adr (bénéficiaire)
			UPDATE adb
			SET	adb.iCheckSum = BINARY_CHECKSUM(adb.Address, adb.City, adb.StateName, adb.CountryId, adb.ZipCode)	
			FROM
				@tConvention t
				INNER JOIN dbo.Un_Convention c
					ON t.ConventionID = c.ConventionID
				INNER JOIN dbo.Mo_Human hb
					ON hb.HumanId = c.BeneficiaryId
				INNER JOIN dbo.Mo_Adr adb
					ON hb.AdrId = adb.AdrId

			SET @iRetour = 1
		END TRY
		BEGIN CATCH
				SELECT
					@vcErrmsg			= REPLACE(ERROR_MESSAGE(),'%',' ')
					,@iErrState			= ERROR_STATE()
					,@iErrSeverity		= ERROR_SEVERITY()
					,@iCodeErreur		= ERROR_NUMBER()
					,@iRetour			= -1

				RAISERROR	(@vcErrmsg, @iErrSeverity, @iErrState) WITH LOG
		END CATCH

		RETURN @iRetour
	END
