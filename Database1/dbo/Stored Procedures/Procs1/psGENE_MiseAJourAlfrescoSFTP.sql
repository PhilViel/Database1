
/****************************************************************************************************
Code de service		:		dbo.psGENE_MiseAJourAlfrescoSFTP
Nom du service		:		psGENE_MiseAJourAlfrescoSFTP
But					:		Envois des informations modifiés au service web Alfresco
Facette				:		
Reférence			:		

Parametres d'entrée :	Parametres					Description                              Obligatoire
                        ----------                  ----------------                         --------------                       
						FileName					Nom du fichier à créer (CSV)
													
Exemple d'appel:

	EXEC psGENE_MiseAJourAlfrescoSFTP 'C:\EureeekaConv.csv'	

Parametres de sortie :  Table											Champs							Description
					    -----------------								---------------------------		--------------------------
						N/A
						@iRetour										=1								Traitement effectué avec succès
																		=0								Aucune modification à exporter
																		=-1								Traitement en erreur

						Les champs inscrits dans le fichier CSV sont les suivants :

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
						2011-04-20					Pierre-Luc Simard						Création de la procédure						
						2011-05-04					Pierre-Luc Simard						Création du fichier CSV en UTF-8 (65001), avec en-têtes
						2011-05-05					Pierre-Luc Simard						Remplacement des NULL 
  ****************************************************************************************************/

CREATE PROCEDURE [dbo].[psGENE_MiseAJourAlfrescoSFTP](
	@FileName varchar(100)) 
AS
	BEGIN

		SET NOCOUNT ON

		DECLARE 
			@iRetour			INT
			,@iErrSeverity		INT
			,@iErrState			INT
			,@vcErrmsg			VARCHAR(1024)
			,@iCodeErreur		INT			
	
		DECLARE
			@tConvention	TABLE (ConventionID INT)
		
		DECLARE @str VARCHAR(1000) 
    
		IF object_id('dbo.tEureeekaConv') is not null
				DROP TABLE tEureeekaConv
			
		CREATE TABLE tEureeekaConv (
			vcConventionNO	VARCHAR(15)
			,iSubscriberID	VARCHAR(8) 
			,iBeneficiaryID	VARCHAR(8) 
			,vcLastNameS	VARCHAR(50)
			,vcFirstNameS	VARCHAR(50)
			,vcLastNameB	VARCHAR(50)
			,FirstNameB		VARCHAR(50)
			,dtFinRegisme	VARCHAR(10) 
			,vcAddressS		VARCHAR(75)
			,vcCityS		VARCHAR(100)
			,vcStateNameS	VARCHAR(75)
			,vcCountryNameS	VARCHAR(75)
			,vcZipCodeS		VARCHAR(10)
			,vcAddressB		VARCHAR(75)
			,vcCityB		VARCHAR(100)
			,vcStateNameB	VARCHAR(75)
			,vcCountryNameB	VARCHAR(75)
			,vcZipCodeB		VARCHAR(10))
		
		BEGIN TRY
			-- Liste des conventions
			INSERT INTO @tConvention
			(
				ConventionID
			)
			SELECT --TOP 1000
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
			ORDER BY ConventionID DESC

			-- SI AUCUN ENREGISTREMENT, ON ARRÊTE LE TRAITEMENT
			IF (SELECT COUNT(*) FROM @tConvention) = 0
				BEGIN
					SET @iRetour = 0
					RETURN @iRetour
				END

			-- Création du fichier CSV
			INSERT INTO tEureeekaConv (
				vcConventionNO	
				,iSubscriberID		
				,iBeneficiaryID	
				,vcLastNameS		
				,vcFirstNameS		
				,vcLastNameB					
				,FirstNameB		
				,dtFinRegisme		
				,vcAddressS		
				,vcCityS			
				,vcStateNameS		
				,vcCountryNameS	
				,vcZipCodeS		
				,vcAddressB		
				,vcCityB			
				,vcStateNameB		
				,vcCountryNameB	
				,vcZipCodeB)
			SELECT
				ISNULL(c.ConventionNO,' ')
				,ISNULL(CAST(c.SubscriberID AS VARCHAR(8)),' ')
				,ISNULL(CAST(c.BeneficiaryID AS VARCHAR(8)),' ')
				,dbo.fnGENE_RemplacerStrNull(REPLACE(hs.LastName,';',''),' ')
				,dbo.fnGENE_RemplacerStrNull(REPLACE(hs.FirstName,';',''),' ')
				,dbo.fnGENE_RemplacerStrNull(REPLACE(hb.LastName,';',''),' ')
				,dbo.fnGENE_RemplacerStrNull(REPLACE(hb.FirstName,';',''),' ')
				,dbo.fnGENE_RemplacerStrNull(CONVERT(VARCHAR(10),dbo.fnCONV_ObtenirDateFinRegime(c.ConventionID, 'R', NULL) ,121),' ')
				,dbo.fnGENE_RemplacerStrNull(REPLACE(ads.Address,';',''),' ')
				,dbo.fnGENE_RemplacerStrNull(REPLACE(ads.City,';',''),' ')			
				,dbo.fnGENE_RemplacerStrNull(REPLACE(ads.StateName,';',''),' ')		
				,dbo.fnGENE_RemplacerStrNull(REPLACE(cosb.CountryName,';',''),' ')
				,dbo.fnGENE_RemplacerStrNull(REPLACE(ads.ZipCode,';',''),' ')				
				,dbo.fnGENE_RemplacerStrNull(REPLACE(adb.Address,';',''),' ')
				,dbo.fnGENE_RemplacerStrNull(REPLACE(adb.City,';',''),' ')		
				,dbo.fnGENE_RemplacerStrNull(REPLACE(adb.StateName,';',''),' ')			
				,dbo.fnGENE_RemplacerStrNull(REPLACE(cob.CountryName,';',''),' ')
				,dbo.fnGENE_RemplacerStrNull(REPLACE(adb.ZipCode,';',''),' ')
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
			
			exec SP_ExportTableToExcelWithColumns 'UnivBase', 'tEureeekaConv', @FileName, '65001', 1
			
			IF object_id('dbo.tEureeekaConv') is not null
			--	DROP TABLE tEureeekaConv
			
			-- MISE À JOUR DU CHECKSUM DES ENREGISTREMENTS MODIFIÉS
			-- Créer la table pour la désactivation des triggers
			IF object_id('tempdb..#DisableTrigger') is null
				CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))

			-- UN_Convention
			INSERT INTO #DisableTrigger VALUES('TR_U_Un_Convention_F_dtRegStartDate')	
			INSERT INTO #DisableTrigger VALUES('TUn_Convention')	
			INSERT INTO #DisableTrigger VALUES('TUn_Convention_State')	
			INSERT INTO #DisableTrigger VALUES('TUn_Convention_YearQualif')	
						
			UPDATE c
			SET c.iCheckSum = BINARY_CHECKSUM(c.ConventionNO,c.SubscriberID,c.BeneficiaryID,c.dtRegEndDateAdjust, dbo.fnCONV_ObtenirDateFinRegime(c.ConventionID, 'R', NULL))
			FROM
				@tConvention t
				INNER JOIN dbo.Un_Convention c
					ON t.ConventionID = c.ConventionID		

			Delete #DisableTrigger where vcTriggerName = 'TR_U_Un_Convention_F_dtRegStartDate'
			Delete #DisableTrigger where vcTriggerName = 'TUn_Convention'
			Delete #DisableTrigger where vcTriggerName = 'TUn_Convention_State'
			Delete #DisableTrigger where vcTriggerName = 'TUn_Convention_YearQualif'
			
			-- Mo_Human
			INSERT INTO #DisableTrigger VALUES('TMo_Human')	
			INSERT INTO #DisableTrigger VALUES('TMo_Human_YearQualif')	
	
			UPDATE hs -- soucripteur
			SET hs.iCheckSum = BINARY_CHECKSUM(hs.LastName,hs.FirstName)
			FROM
				@tConvention t
				INNER JOIN dbo.Un_Convention c
					ON t.ConventionID = c.ConventionID
				INNER JOIN dbo.Mo_Human hs
					ON hs.HumanId = c.SubscriberId
			
			UPDATE hb -- bénéficiaire
			SET hb.iCheckSum = BINARY_CHECKSUM(hb.LastName,hb.FirstName)
			FROM
				@tConvention t
				INNER JOIN dbo.Un_Convention c
					ON t.ConventionID = c.ConventionID
				INNER JOIN dbo.Mo_Human hb
					ON hb.HumanId = c.BeneficiaryId

			Delete #DisableTrigger where vcTriggerName = 'TMo_Human'
			Delete #DisableTrigger where vcTriggerName = 'TMo_Human_YearQualif'

			-- Mo_Adr
			INSERT INTO #DisableTrigger VALUES('TMo_Adr')	
		
			UPDATE ads -- souscripteur
			SET	ads.iCheckSum = BINARY_CHECKSUM(ads.Address, ads.City, ads.StateName, ads.CountryId, ads.ZipCode)	
			FROM
				@tConvention t
				INNER JOIN dbo.Un_Convention c
					ON t.ConventionID = c.ConventionID
				INNER JOIN dbo.Mo_Human hs
					ON hs.HumanId = c.SubscriberId
				INNER JOIN dbo.Mo_Adr ads
					ON hs.AdrId = ads.AdrId

			UPDATE adb -- bénéficiaire
			SET	adb.iCheckSum = BINARY_CHECKSUM(adb.Address, adb.City, adb.StateName, adb.CountryId, adb.ZipCode)	
			FROM
				@tConvention t
				INNER JOIN dbo.Un_Convention c
					ON t.ConventionID = c.ConventionID
				INNER JOIN dbo.Mo_Human hb
					ON hb.HumanId = c.BeneficiaryId
				INNER JOIN dbo.Mo_Adr adb
					ON hb.AdrId = adb.AdrId
	
			Delete #DisableTrigger where vcTriggerName = 'TMo_Adr'

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
