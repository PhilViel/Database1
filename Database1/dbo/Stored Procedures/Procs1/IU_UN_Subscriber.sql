/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 : IU_UN_Subscriber
Description         : Sauvegarde d'ajouts/modifications de souscripteurs
Valeurs de retours  : >0  :	Tout à fonctionn‚
                      <=0 :	Erreur SQL

Note :									2003-05-05	Andr‚ Sanscartier		Modification
										2003-06-05	Bruno Lapointe			Documentation
										2003-10-15	Bruno Lapointe			Modification (point 768) pour gestion des num‚ros d'assurances sociales
										2004-05-21	Dominic L‚tourneau		Migration de l'ancienne procedure selon les nouveaux standards
										2004-05-31	Bruno Lapointe			Ajout du BirthLangID
						ADX0000590	IA	2004-11-19	Bruno Lapointe			Remplacer IMo_Human par SP_IU_CRQ_Human
						ADX0000594	IA	2004-11-24	Bruno Lapointe			Gestion du log
						ADX0000578	IA	2004-11-24	Bruno Lapointe			Correction des erreurs de pré validations
						ADX0001177	BR	2004-12-01	Bruno Lapointe			Changement des codes d'erreurs et des validations
						ADX0001221	BR	2005-01-07	Bruno Lapointe			Correction de bug dans le log de modification
						ADX0001603	BR	2005-10-11	Bruno Lapointe			Erreur de s‚lection de valeurs pour la pré-validation.  Pas de clause WHERE.
						ADX0000826	IA	2006-03-14	Bruno Lapointe			Adaptation des souscripteurs pour PCEE 4.3
						ADX0000848	IA	2006-03-24	Bruno Lapointe			Adaptation des FCB pour PCEE 4.3 
						ADX0001278	IA	2007-03-19	Alain Quirion			Vérification de la province en plus du pays pour la fusion des villes
						ADX0001241	IA	2007-04-11	Alain Quirion			Ajout des champs Spouse, Contact1, Contact2, Contact1Phone, Contact2Phone
										2008-09-15  Radu Trandafir			Ajout du champ PaysOrigine 
																			Ajout du champ PreferenceSuivi
																			Ajout de la table tblCONV_ProfilSouscripteur
										2008-10-02	Patrick Robitaille		Ajout du paramètre pour le champ NEQ
										2009-01-08	Donald Hupp‚			Modification du join tblCONV_PreferenceSuivi en LEFT join car l'historique ne fonctionnait plus
										2009-06-16	Patrick Robitaille		Ajout des champs bSouscripteur_Accepte_Publipostage et
																			bSouscripteur_Desire_Releve_Elect
										2009-12-17	Jean-François Gauthier	Modification pour faire automatiquement une demande de SCEE+
																			dans les cas de saisie d'un NAS de souscripteur (c.f. Formulaire RHDSC)
										2009-12-18	Jean-François Gauthier	Ajout des champs liés au profil du souscripteur
										2010-05-12	Jean-François Gauthier	Élimination des paramètres non utilisés liés au profil souscripteur
										2011-04-08	Corentin Menthonnex		2011-12 : ajout des champs suivants aux informations souscripteur
																				- bRapport_Annuel_Direction
																				- bEtats_Financiers_Annuels
																				- vcOccupation
																				- vcEmployeur
																				- tiNbAnneesService
										2011-06-23	Corentin Menthonnex		2011-12 : ajout des champs suivants aux informations souscripteur
																				- bEtats_Financiers_Semestriels
										2011-10-24	Christian Chénard		Ajout des colonnes iID_Identite_Souscripteur et vcIdentiteVerifieeDescription
										2011-11-02	Christian Chénard		Ajout du champ bAutorisation_Resiliation
										2014-03-06	Pierre-Luc Simard		Retrait du log des téléphone Pager et Wattline
										2014-11-07	Pierre-Luc Simard		Ne plus enregistrer la valeur du champs tiCESPState, qui est maintenant géré par la procédure psCONV_EnregistrerPrevalidationPCEE
										2015-02-13	Pierre-Luc Simard		Ne plus valider l'état du souscripteur avant d'appeler la procédure TT_UN_CESPOfConventions
****************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_Subscriber] (
	@ConnectID INTEGER, -- Identifiant unique de la connection	        
	@SubscriberID INTEGER,                     
	@RepID INTEGER, 
	@StateID INTEGER,                    
	@ScholarshipLevelID UnScholarshipLevel, 
	@AnnualIncome MONEY,                  
	@SemiAnnualStatement BIT = 0,        
	@FirstName VARCHAR(35),                 
	@OrigName VARCHAR(75) = NULL,          	            
	@LastName VARCHAR(50),                   
	@BirthDate DATETIME,                
	@DeathDate DATETIME,                
	@SexID MoSex,                           
	@LangID MoLang,                         
	@CivilID MoCivil,                       
	@SocialNumber VARCHAR(75) = NULL,      
	@ResidID CHAR(4),                     
	@DriverLicenseNo VARCHAR(75) = NULL,   
	@WebSite VARCHAR(75) = NULL,           
	@CompanyName VARCHAR(75) = NULL,       
	@CourtesyTitle VARCHAR(35) = NULL,
	@UsingSocialNumber BIT = 1,        
	@SharePersonalInfo BIT = 1,        
	@MarketingMaterial BIT = 1,        
	@IsCompany BIT = 0,       
	@InForce DATETIME,                         
	@AdrTypeID MoAdrType,                   
	@SourceID INTEGER = NULL,                  
	@Address VARCHAR(75) = NULL,               
	@City VARCHAR(100) = NULL,                    
	@StateName VARCHAR(75) = NULL,         
	@CountryID CHAR(4) = NULL,            
	@ZipCode VARCHAR(10) = NULL,              
	@Phone1 VARCHAR(27) = NULL,              
	@Phone2 VARCHAR(27) = NULL,              
	@Fax VARCHAR(15) = NULL,                    
	@Mobile VARCHAR(15) = NULL,                 
	@WattLine VARCHAR(27) = NULL,            
	@OtherTel VARCHAR(27) = NULL,            
	@Pager VARCHAR(15) = NULL,                  
	@EMail VARCHAR(100) = NULL,                 
	@BirthLangID VARCHAR(3),
	@tiCESPState SMALLINT, -- État du souscripteur au niveau des pré-validations. (0 = Rien ne passe et 1 = La SCEE passe)
	@Spouse VARCHAR(100)  = NULL,
	@Contact1 VARCHAR(100)  = NULL,
	@Contact2 VARCHAR(100)  = NULL,
	@Contact1Phone VARCHAR(15) = NULL,
	@Contact2Phone VARCHAR(100)  = NULL, 
	@PaysOrigineID CHAR(4) = NULL,
	@PreferenceSuiviID INTEGER,
	@vcNEQ VARCHAR(10),
	@bDesireReleveElect BIT = 0,
	@bAcceptePubli BIT = 0,
	@vcOccupation VARCHAR(50) = NULL,			-- 2011-04-08 : + 2011-12 - CM
	@vcEmployeur VARCHAR(50) = NULL,			-- 2011-04-08 : + 2011-12 - CM
	@tiNbAnneesService TINYINT = NULL,			-- 2011-04-08 : + 2011-12 - CM
	@bRapport_Annuel_Direction BIT = 0,			-- 2011-04-08 : + 2011-12 - CM
	@bEtats_Financiers_Annuels BIT = 0,			-- 2011-04-08 : + 2011-12 - CM
	@bEtats_Financiers_Semestriels BIT = 0,		-- 2011-06-23 : + 2011-12 - CM
	@iID_Identite_Souscripteur int = NULL,
	@vcIdentiteVerifieeDescription varchar(75) = NULL,
	@bAutorisation_Resiliation BIT = NULL
	)
AS
BEGIN
	-- Variables de travail
	DECLARE
		@vcStateCode VARCHAR(75),
		@iErrorID INTEGER,
		-- Variables contenant les anciennes valeurs pour le log
		@iOldSubscriberID INTEGER,
		@vcOldFirstName VARCHAR(35),
		@vcOldOrigName VARCHAR(75),		
		@vcOldLastName VARCHAR(50),
		@dtOldBirthDate DATETIME,
		@dtOldDeathDate DATETIME,
		@cOldSexID MoSex,
		@cOldLangID MoLang,
		@cOldCivilID MoCivil,
		@vcOldSocialNumber VARCHAR(75),
		@cOldResidID CHAR(4),
		@vcOldDriverLicenseNo VARCHAR(75),
		@vcOldWebSite VARCHAR(75),
		@vcOldCompanyName VARCHAR(75),
		@vcOldCourtesyTitle VARCHAR(35),
		@bOldUsingSocialNumber BIT,
		@bOldSharePersonalInfo BIT,
		@bOldMarketingMaterial BIT,
		@bOldIsCompany BIT,
		@dtOldInForce DATETIME,
		@vcOldAddress VARCHAR(75),
		@vcOldCity VARCHAR(100),
		@vcOldStateName VARCHAR(75),
		@cOldCountryID CHAR(4),
		@vcOldZipCode VARCHAR(10),
		@vcOldPhone1 VARCHAR(27),
		@vcOldPhone2 VARCHAR(27),
		@vcOldFax VARCHAR(15),
		@vcOldMobile VARCHAR(15),
		@vcOldWattLine VARCHAR(27),
		@vcOldOtherTel VARCHAR(27),
		@vcOldPager VARCHAR(15),
		@vcOldEMail VARCHAR(100),
		@vcOldOccupation VARCHAR(50),	-- 2011-04-08 : + 2011-12 - CM
		@vcOldEmployeur VARCHAR(50),	-- 2011-04-08 : + 2011-12 - CM
		@tiOldNbAnneesService TINYINT,	-- 2011-04-08 : + 2011-12 - CM
		@iOldRepID INTEGER, 
		@iOldStateID INTEGER,                    
		@cOldScholarshipLevelID UnScholarshipLevel, 
		@myOldAnnualIncome MONEY,                  
		@bOldSemiAnnualStatement BIT,        
		@vcOldBirthLangID VARCHAR(3),
		@tiOldCESPState INTEGER,
		@cOldpaysOrigineID CHAR(4),
		@OldPreferenceSuiviID INTEGER,
		@vcOldNEQ VARCHAR(10),
		@bOldDesireReleveElect BIT,
		@bOldAcceptePubli BIT,
		@bOldRapport_Annuel_Direction BIT,	-- 2011-04-08 : + 2011-12 - CM 
		@bOldEtats_Financiers_Annuels BIT,	-- 2011-04-08 : + 2011-12 - CM 
		@bOldEtats_Financiers_Semestriels BIT,	-- 2011-06-23 : + 2011-12 - CM 
		@iOldID_Identite_Souscripteur int,
		@vcOldIdentiteVerifieeDescription varchar(75),
		@bOldAutorisation_Resiliation BIT,
				
		-- Variable du caractère séparateur de valeur du blob
		@cSep CHAR(1)

	-- Initialisation des variables
	SET @cSep = CHAR(30)

	-----------------
	BEGIN TRANSACTION
	-----------------
	
	-- Va chercher les anciennes valeurs s'il y en a
	SELECT
		@iOldSubscriberID = S.SubscriberID,
		@vcOldFirstName = H.FirstName,
		@vcOldOrigName = H.OrigName,		
		@vcOldLastName = H.LastName,
		@dtOldBirthDate = H.BirthDate,
		@dtOldDeathDate = H.DeathDate,
		@cOldSexID = H.SexID,
		@cOldLangID = H.LangID,
		@cOldCivilID = H.CivilID,
		@vcOldSocialNumber = H.SocialNumber,
		@cOldResidID = H.ResidID,
		@vcOldDriverLicenseNo = H.DriverLicenseNo,
		@vcOldWebSite = H.WebSite,
		@vcOldCompanyName = H.CompanyName,
		@vcOldCourtesyTitle = H.CourtesyTitle,
		@bOldUsingSocialNumber = H.UsingSocialNumber,
		@bOldSharePersonalInfo = H.SharePersonalInfo,
		@bOldMarketingMaterial = H.MarketingMaterial,
		@bOldIsCompany = H.IsCompany,
		@dtOldInForce = A.InForce,
		@vcOldAddress = A.Address,
		@vcOldCity = A.City,
		@vcOldStateName = A.StateName,
		@cOldCountryID = A.CountryID,
		@vcOldZipCode = A.ZipCode,
		@vcOldPhone1 = A.Phone1,
		@vcOldPhone2 = A.Phone2,
		@vcOldFax = A.Fax,
		@vcOldMobile = A.Mobile,
		@vcOldWattLine = A.WattLine,
		@vcOldOtherTel = A.OtherTel,
		@vcOldPager = A.Pager,
		@vcOldEMail = A.EMail,
		@vcOldOccupation = H.vcOccupation,				-- 2011-04-08 : + 2011-12 - CM 
		@vcOldEmployeur = H.vcEmployeur,				-- 2011-04-08 : + 2011-12 - CM 
		@tiOldNbAnneesService = H.tiNbAnneesService,	-- 2011-04-08 : + 2011-12 - CM 
		@iOldRepID = S.RepID, 
		@iOldStateID = S.StateID,                    
		@cOldScholarshipLevelID = S.ScholarshipLevelID, 
		@myOldAnnualIncome = S.AnnualIncome,                  
		@bOldSemiAnnualStatement = S.SemiAnnualStatement,        
		@vcOldBirthLangID = S.BirthLangID,
		@tiOldCESPState = S.tiCESPState,
		@cOldpaysOrigineID=H.cID_Pays_Origine,
		@OldPreferenceSuiviID = S.iID_Preference_Suivi,
		@vcOldNEQ = H.StateCompanyNo,
		@bOldDesireReleveElect = S.bSouscripteur_Desire_Releve_Elect,
		@bOldAcceptePubli = H.bHumain_Accepte_Publipostage,
		@bOldRapport_Annuel_Direction = S.bRapport_Annuel_Direction,			-- 2011-04-08 : + 2011-12 - CM 
		@bOldEtats_Financiers_Annuels = S.bEtats_Financiers_Annuels,			-- 2011-04-08 : + 2011-12 - CM 
		@bOldEtats_Financiers_Semestriels = S.bEtats_Financiers_Semestriels,	-- 2011-06-23 : + 2011-12 - CM 
		@iOldID_Identite_Souscripteur = S.iID_Identite_Souscripteur,
		@vcOldIdentiteVerifieeDescription = S.vcIdentiteVerifieeDescription,
		@bOldAutorisation_Resiliation = S.bAutorisation_Resiliation
	FROM dbo.Un_Subscriber S
	JOIN dbo.Mo_Human H ON H.HumanID = S.SubscriberID
	LEFT JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
	WHERE S.SubscriberID = @SubscriberID
	  AND (	@SubscriberID > 0 
			)

	SET @AnnualIncome = ROUND(@AnnualIncome, 2)
	
	IF @RepID <= 0 
		SET @RepID = NULL
	
	IF @StateID <= 0 
		SET @StateID = NULL
	
	-- Recherche d'une fusion existante pour le nom de ville en paramètre 
	IF EXISTS (
			SELECT *
			FROM Mo_CityFusion F
			LEFT JOIN Mo_State S ON S.StateID = F.StateID
			JOIN Mo_City C ON C.CityID = F.CityID
			WHERE F.OldCityName = @City
			  AND C.CountryID = @CountryID			 
			  AND ISNULL(S.StateName,'') = ISNULL(@StateName,''))
	BEGIN
		SELECT 
			@City = C.CityName
		FROM Mo_CityFusion F
		LEFT JOIN Mo_State S ON S.StateID = F.StateID
		JOIN Mo_City C ON C.CityID = F.CityID		
		WHERE F.OldCityName = @City
			AND C.CountryID = @CountryID	
			AND ISNULL(S.StateName,'') = ISNULL(@StateName,'')
	END

/*
	--2009-12-17 : JFG
	-- VÉRIFICATION SI AJOUT DE NAS AU SOUSCRIPTEUR
	IF (NULLIF(LTRIM(RTRIM(@vcOldSocialNumber)), '') IS NULL)		-- L'ANCIEN NAS DOIT ÊTRE À BLANC
		AND	
		(NULLIF(RTRIM(LTRIM(@SocialNumber)), '') IS NOT NULL)		-- LE NOUVEAU NAS NE DOIT PAS ÊTRE À BLANC
		BEGIN
			-- RÉCUPÉRER L'ENSEMBLE DES CONVENTIONS SUR LESQUELLES LE SOUSCRIPTEUR EST ACTIF
			-- POUR CHAQUE CONVENTION RÉCUPÉRÉE SI :
			--			- tiCESPState IN (,3,4)
			--			- bFormulaireRecu = 1
			--			- bCESGRequested = 1
			--			- Statut convention <> 'FRM'
			UPDATE c
			SET c.bACESGRequested = 1
			FROM 
				dbo.fntCONV_ObtenirListeConventions(GETDATE(), @SubscriberID, NULL, 0) fnt
				INNER JOIN dbo.Un_Convention c
					ON fnt.ConventionID = c.ConventionID
			WHERE
				dbo.fnConv_ObtenirStatutConventionEnDate(fnt.ConventionID, GETDATE()) <> 'FRM'			
				AND
				c.tiCESPState IN (3,4)
				AND
				c.bFormulaireRecu = 1
				AND
				c.bCESGRequested = 1

		END
*/

	-- Création des dossiers dans Mo_Human et Mo_Adr 
	EXECUTE @SubscriberID = SP_IU_CRQ_Human
		@ConnectID,
		@SubscriberID,
		@FirstName,
		@OrigName,
		'',
		@LastName,
		@BirthDate,
		@DeathDate,
		@SexID,
		@LangID,
		@CivilID,
		@SocialNumber,
		@ResidID,
		@DriverLicenseNo,
		@WebSite,
		@CompanyName,
		@CourtesyTitle,
		@UsingSocialNumber,
		@SharePersonalInfo,
		@MarketingMaterial,
		@IsCompany,
		@InForce,
		@Address,
		@City,
		@StateName,
		@CountryID,
		@ZipCode,
		@Phone1,
		@Phone2,
		@Fax,
		@Mobile,
		@WattLine,
		@OtherTel,
		@Pager,
		@EMail,
		@PaysOrigineID,
		@vcNEQ,
		@bAcceptePubli,
		@vcOccupation,		-- 2011-04-08 : + 2011-12 - CM 
		@vcEmployeur,		-- 2011-04-08 : + 2011-12 - CM 
		@tiNbAnneesService	-- 2011-04-08 : + 2011-12 - CM 
		
	IF @SubscriberID <> 0
	BEGIN
		IF NOT EXISTS(
				SELECT SubscriberID
				FROM dbo.Un_Subscriber 
				WHERE SubscriberID = @SubscriberID)
		BEGIN
			INSERT Un_Subscriber (
				SubscriberID,
				RepID,
				StateID,
				ScholarshipLevelID,
				AnnualIncome,
				SemiAnnualStatement,
				BirthLangID,
				tiCESPState,
				Spouse, 
				Contact1,
				Contact2,
				Contact1Phone,
				Contact2Phone,
				bSouscripteur_Desire_Releve_Elect,
				iID_Preference_Suivi,
				bRapport_Annuel_Direction,		-- 2011-04-08 : + 2011-12 - CM 
				bEtats_Financiers_Annuels,		-- 2011-04-08 : + 2011-12 - CM 
				bEtats_Financiers_Semestriels,	-- 2011-06-23 : + 2011-12 - CM 
				iID_Identite_Souscripteur,
				vcIdentiteVerifieeDescription,
				bAutorisation_Resiliation)
			VALUES (
				@SubscriberID,
				@RepID,
				@StateID,
				@ScholarshipLevelID,
				@AnnualIncome,
				@SemiAnnualStatement,
				@BirthLangID,
				0, --@tiCESPState,
				@Spouse, 
				@Contact1,
				@Contact2,
				@Contact1Phone,
				@Contact2Phone,
				@bDesireReleveElect,
				@PreferenceSuiviID,
				ISNULL(@bRapport_Annuel_Direction, 0),		-- 2011-04-08 : + 2011-12 - CM 
				ISNULL(@bEtats_Financiers_Annuels, 0),		-- 2011-04-08 : + 2011-12 - CM 
				ISNULL(@bEtats_Financiers_Semestriels, 0),	-- 2011-06-23 : + 2011-12 - CM
				@iID_Identite_Souscripteur,
				@vcIdentiteVerifieeDescription,
				@bAutorisation_Resiliation)

			IF @@ERROR <> 0
				SET @SubscriberID = 0

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
					'Un_Subscriber',
					@SubscriberID,
					GETDATE(),
					LA.LogActionID,
					LogDesc = 'Souscripteur : '+H.LastName+', '+H.FirstName,
					LogText =
						CASE 
							WHEN ISNULL(H.FirstName,'') = '' THEN ''
						ELSE 'FirstName'+@cSep+H.FirstName+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(H.LastName,'') = '' THEN ''
						ELSE 'LastName'+@cSep+H.LastName+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(H.OrigName,'') = '' THEN ''
						ELSE 'OrigName'+@cSep+H.OrigName+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(H.BirthDate,0) <= 0 THEN ''
						ELSE 'BirthDate'+@cSep+CONVERT(CHAR(10), H.BirthDate, 20)+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(H.DeathDate,0) <= 0 THEN ''
						ELSE 'DeathDate'+@cSep+CONVERT(CHAR(10), H.DeathDate, 20)+@cSep+CHAR(13)+CHAR(10)
						END+
						'LangID'+@cSep+H.LangID+@cSep+L.LangName+@cSep+CHAR(13)+CHAR(10)+
						'SexID'+@cSep+H.SexID+@cSep+Sx.SexName+@cSep+CHAR(13)+CHAR(10)+
						'CivilID'+@cSep+H.CivilID+@cSep+CS.CivilStatusName+@cSep+CHAR(13)+CHAR(10)+
						CASE 
							WHEN ISNULL(H.SocialNumber,'') = '' THEN ''
						ELSE 'SocialNumber'+@cSep+H.SocialNumber+@cSep+CHAR(13)+CHAR(10)
						END+
						'ResidID'+@cSep+H.ResidID+@cSep+R.CountryName+@cSep+CHAR(13)+CHAR(10)+
						CASE 
							WHEN ISNULL(H.DriverLicenseNo,'') = '' THEN ''
						ELSE 'DriverLicenseNo'+@cSep+H.DriverLicenseNo+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(H.WebSite,'') = '' THEN ''
						ELSE 'WebSite'+@cSep+H.WebSite+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(H.CompanyName,'') = '' THEN ''
						ELSE 'CompanyName'+@cSep+H.CompanyName+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(H.CourtesyTitle,'') = '' THEN ''
						ELSE 'CourtesyTitle'+@cSep+H.CourtesyTitle+@cSep+CHAR(13)+CHAR(10)
						END+
						'UsingSocialNumber'+@cSep+CAST(ISNULL(H.UsingSocialNumber,1) AS CHAR(1))+@cSep+
						CASE 
							WHEN ISNULL(H.UsingSocialNumber,1) = 1 THEN 'Oui'
						ELSE 'Non'
						END+@cSep+
						CHAR(13)+CHAR(10)+
						'SharePersonalInfo'+@cSep+CAST(ISNULL(H.SharePersonalInfo,1) AS CHAR(1))+@cSep+
						CASE 
							WHEN ISNULL(H.SharePersonalInfo,1) = 1 THEN 'Oui'
						ELSE 'Non'
						END+@cSep+
						CHAR(13)+CHAR(10)+
						'MarketingMaterial'+@cSep+CAST(ISNULL(H.MarketingMaterial,1) AS CHAR(1))+@cSep+
						CASE 
							WHEN ISNULL(H.MarketingMaterial,1) = 1 THEN 'Oui'
						ELSE 'Non'
						END+@cSep+
						CHAR(13)+CHAR(10)+
						'IsCompany'+@cSep+CAST(ISNULL(H.IsCompany,0) AS CHAR(1))+@cSep+
						CASE 
							WHEN ISNULL(H.IsCompany,0) = 1 THEN 'Oui'
						ELSE 'Non'
						END+@cSep+
						CHAR(13)+CHAR(10)+
						CASE 
							WHEN ISNULL(A.Address,'') = '' THEN ''
						ELSE 'Address'+@cSep+A.Address+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(A.City,'') = '' THEN ''
						ELSE 'City'+@cSep+A.City+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(A.StateName,'') = '' THEN ''
						ELSE 'StateName'+@cSep+A.StateName+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(A.CountryID,'') = '' THEN ''
						ELSE 'CountryID'+@cSep+A.CountryID+@cSep+C.CountryName+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(A.ZipCode,'') = '' THEN ''
						ELSE 'ZipCode'+@cSep+A.ZipCode+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(A.Phone1,'') = '' THEN ''
						ELSE 'Phone1'+@cSep+A.Phone1+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(A.Phone2,'') = '' THEN ''
						ELSE 'Phone2'+@cSep+A.Phone2+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(A.Fax,'') = '' THEN ''
						ELSE 'Fax'+@cSep+A.Fax+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(A.Mobile,'') = '' THEN ''
						ELSE 'Mobile'+@cSep+A.Mobile+@cSep+CHAR(13)+CHAR(10)
						END+/*
						CASE 
							WHEN ISNULL(A.WattLine,'') = '' THEN ''
						ELSE 'WattLine'+@cSep+A.WattLine+@cSep+CHAR(13)+CHAR(10)
						END+*/
						CASE 
							WHEN ISNULL(A.OtherTel,'') = '' THEN ''
						ELSE 'OtherTel'+@cSep+A.OtherTel+@cSep+CHAR(13)+CHAR(10)
						END+/*
						CASE 
							WHEN ISNULL(A.Pager,'') = '' THEN ''
						ELSE 'Pager'+@cSep+A.Pager+@cSep+CHAR(13)+CHAR(10)
						END+*/
						CASE 
							WHEN ISNULL(A.EMail,'') = '' THEN ''
						ELSE 'EMail'+@cSep+A.EMail+@cSep+CHAR(13)+CHAR(10)
						END+
						
						CASE	-- 2011-04-08 : + 2011-12 - CM 
							WHEN ISNULL(H.vcOccupation,'') = '' THEN ''
						ELSE 'vcOccupation'+@cSep+H.vcOccupation+@cSep+CHAR(13)+CHAR(10) 
						END+ 
						
						CASE	-- 2011-04-08 : + 2011-12 - CM 
							WHEN ISNULL(H.vcEmployeur,'') = '' THEN '' 
						ELSE 'vcEmployeur'+@cSep+H.vcEmployeur+@cSep+CHAR(13)+CHAR(10) 
						END+ 
						
						CASE	-- 2011-04-08 : + 2011-12 - CM 
							WHEN ISNULL(H.tiNbAnneesService,'') = '' THEN '' 
						ELSE 'tiNbAnneesService'+@cSep+CAST(H.tiNbAnneesService AS VARCHAR)+@cSep+CHAR(13)+CHAR(10) 
						END+ 
						
						CASE 
							WHEN ISNULL(S.RepID,0) <= 0 THEN ''
						ELSE 'RepID'+@cSep+CAST(S.RepID AS VARCHAR)+@cSep+ISNULL(HR.LastName+', '+HR.FirstName,'')+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(S.StateID,0) <= 0 THEN ''
						ELSE 'StateID'+@cSep+CAST(S.StateID AS VARCHAR)+@cSep+ISNULL(St.StateName,'')+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(S.ScholarshipLevelID,'') = '' THEN ''
						ELSE 
							'ScholarshipLevelID'+@cSep+S.ScholarshipLevelID+@cSep+
							CASE S.ScholarshipLevelID
								WHEN 'UNK' THEN 'Inconnu'
								WHEN 'NDI' THEN 'Non diplômé'
								WHEN 'SEC' THEN 'Secondaire'
								WHEN 'COL' THEN 'Collège'
								WHEN 'UNI' THEN 'Université'
							ELSE ''
							END+@cSep+
							CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(S.AnnualIncome,0) <= 0 THEN ''
						ELSE 'AnnualIncome'+@cSep+CAST(S.AnnualIncome AS VARCHAR)+@cSep+CHAR(13)+CHAR(10)
						END+
						'SemiAnnualStatement'+@cSep+CAST(ISNULL(S.SemiAnnualStatement,0) AS CHAR(1))+@cSep+
						CASE 
							WHEN ISNULL(S.SemiAnnualStatement,0) = 1 THEN 'Oui'
						ELSE 'Non'
						END+@cSep+
						CHAR(13)+CHAR(10)+
						CASE 
							WHEN ISNULL(S.BirthLangID,'') = '' THEN ''
						ELSE 'BirthLangID'+@cSep+S.BirthLangID+@cSep+ISNULL(WL.WorldLanguage,'')+@cSep+CHAR(13)+CHAR(10)
						END+/*
						'tiCESPState'+@cSep+CAST(ISNULL(S.tiCESPState,0) AS VARCHAR)+@cSep+
						CASE 
							WHEN ISNULL(S.tiCESPState,0) = 1 THEN 'Oui'
						ELSE 'Non'
						END+@cSep+
						CHAR(13)+CHAR(10)+*/
						CASE
							WHEN ISNULL(H.cID_Pays_Origine,'') = '' THEN ''
						ELSE 'PaysOrigineID'+@cSep+H.cID_Pays_Origine+@cSep+CO.CountryName+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE
							WHEN ISNULL(S.iID_Preference_Suivi,0) <= 0 THEN ''
						ELSE 'PreferenceSuiviID'+@cSep+CAST(ISNULL(S.iID_Preference_Suivi,0)AS VARCHAR)+@cSep+ISNULL(PS.vcDescription,'')+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(H.StateCompanyNo,'') = '' THEN ''
						ELSE 'NEQ'+@cSep+H.StateCompanyNo+@cSep+CHAR(13)+CHAR(10)
						END+
						'bDesireReleveElect'+@cSep+CAST(ISNULL(S.bSouscripteur_Desire_Releve_Elect,0) AS CHAR(1))+@cSep+
						CASE
							WHEN ISNULL(S.bSouscripteur_Desire_Releve_Elect,0) = 1 THEN 'Oui'
						ELSE 'Non'
						END+@cSep+
						CHAR(13)+CHAR(10)+
						'bAcceptePublipostage'+@cSep+CAST(ISNULL(H.bHumain_Accepte_Publipostage,0) AS CHAR(1))+@cSep+
						CASE 
							WHEN ISNULL(H.bHumain_Accepte_Publipostage,0) = 1 THEN 'Oui'
						ELSE 'Non'
						END+@cSep+
						CHAR(13)+CHAR(10)+
						
						-- 2011-04-08 : + 2011-12 - CM
						'bRapport_Annuel_Direction'+@cSep+
						CASE
							WHEN ISNULL(S.bRapport_Annuel_Direction,0) = 1 
								THEN 'Oui'
								ELSE 'Non'
						END
						+@cSep+CHAR(13)+CHAR(10)+
						
						-- 2011-04-08 : + 2011-12 - CM
						'bEtats_Financiers_Annuels'+@cSep+
						CASE
							WHEN ISNULL(S.bEtats_Financiers_Annuels,0) = 1 
								THEN 'Oui'
								ELSE 'Non'
						END
						+@cSep+CHAR(13)+CHAR(10)+
						
						-- 2011-06-23 : + 2011-12 - CM
						'bEtats_Financiers_Semestriels'+@cSep+
						CASE
							WHEN ISNULL(S.bEtats_Financiers_Semestriels,0) = 1 
								THEN 'Oui'
								ELSE 'Non'
						END
						+@cSep+CHAR(13)+CHAR(10)+					
						
						'iID_Identite_Souscripteur'+@cSep+CAST(ISNULL(S.iID_Identite_Souscripteur,0) AS CHAR(1))+@cSep+
						CASE 
							WHEN ISNULL(S.iID_Identite_Souscripteur,0) = 0 THEN ''
						ELSE IDS.vcDescription+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(S.vcIdentiteVerifieeDescription,'') = '' THEN ''
						ELSE
							'vcIdentiteVerifieeDescription'+@cSep+S.vcIdentiteVerifieeDescription+@cSep+CHAR(13)+CHAR(10)
						END+@cSep+CHAR(13)+CHAR(10)+
						'bAutorisation_Resiliation'+@cSep+
						CASE
							WHEN ISNULL(S.bAutorisation_Resiliation,0) = 1 
								THEN 'Oui'
								ELSE 'Non'
						END
					FROM dbo.Un_Subscriber S
					JOIN dbo.Mo_Human H ON H.HumanID = S.SubscriberID
					JOIN Mo_Lang L ON L.LangID = H.LangID
					JOIN Mo_Sex Sx ON Sx.LangID = 'FRA' AND Sx.SexID = H.SexID
					JOIN Mo_CivilStatus CS ON CS.LangID = 'FRA' AND CS.SexID = H.SexID AND CS.CivilStatusID = H.CivilID
					JOIN CRQ_LogAction LA ON LA.LogActionShortName = 'I'
					JOIN Mo_Country R ON R.CountryID = H.ResidID
					LEFT JOIN dbo.Mo_Human HR ON HR.HumanID = S.RepID
					LEFT JOIN Mo_State St ON St.StateID = S.StateID
					LEFT JOIN CRQ_WorldLang WL ON WL.WorldLanguageCodeID = S.BirthLangID
					LEFT JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
					LEFT JOIN Mo_Country C ON C.CountryID = A.CountryID
					LEFT JOIN Mo_Country CO ON CO.CountryID = H.cID_Pays_Origine
					JOIN tblCONV_PreferenceSuivi PS ON PS.iID_Preference_Suivi = S.iID_Preference_Suivi
					LEFT JOIN tblCONV_IdentiteSouscripteur IDS ON IDS.iID_Identite_Souscripteur = S.iID_Identite_Souscripteur
					WHERE S.SubscriberID = @SubscriberID
		END
		ELSE
		BEGIN
			UPDATE dbo.Un_Subscriber 
			SET 
				RepID = @RepID,
				StateID = @StateID,
				ScholarshipLevelID = @ScholarshipLevelID,
				AnnualIncome = @AnnualIncome,
				SemiAnnualStatement = @SemiAnnualStatement,
				BirthLangID = @BirthLangID,
				--tiCESPState = @tiCESPState,
				Spouse = @Spouse,
				Contact1 = @Contact1,
				Contact2 = @Contact2,
				Contact1Phone = @Contact1Phone,
				Contact2Phone = @Contact2phone,
				iID_Preference_Suivi = @PreferenceSuiviID,
				bSouscripteur_Desire_Releve_Elect = @bDesireReleveElect,
				bRapport_Annuel_Direction = ISNULL(@bRapport_Annuel_Direction, 0),			-- 2011-04-08 : + 2011-12 - CM
				bEtats_Financiers_Annuels = ISNULL(@bEtats_Financiers_Annuels, 0),			-- 2011-04-08 : + 2011-12 - CM
				bEtats_Financiers_Semestriels = ISNULL(@bEtats_Financiers_Semestriels, 0),	-- 2011-06-23 : + 2011-12 - CM
				iID_Identite_Souscripteur = @iID_Identite_Souscripteur,
				vcIdentiteVerifieeDescription = @vcIdentiteVerifieeDescription, 
				bAutorisation_Resiliation = @bAutorisation_Resiliation				
			WHERE 
				SubscriberID = @SubscriberID

			IF @@ERROR <> 0
				SET @SubscriberID = 0

			IF EXISTS	(
					SELECT SubscriberID
					FROM dbo.Un_Subscriber S
					JOIN dbo.Mo_Human H ON H.HumanID = S.SubscriberID
					WHERE S.SubscriberID = @SubscriberID
						AND	(	ISNULL(@vcOldFirstName,'') <> ISNULL(H.FirstName,'')
								OR	ISNULL(@vcOldOrigName,'') <> ISNULL(H.OrigName,'')
								OR ISNULL(@vcOldLastName,'') <> ISNULL(H.LastName,'')
								OR ISNULL(@cOldLangID,'') <> ISNULL(H.LangID,'')
								OR ISNULL(@cOldSexID,'') <> ISNULL(H.SexID,'')
								OR ISNULL(@cOldCivilID,'') <> ISNULL(H.CivilID,'')
								OR ISNULL(@dtOldBirthDate,0) <> ISNULL(H.BirthDate,0)
								OR ISNULL(@dtOldDeathDate,0) <> ISNULL(H.DeathDate,0)
								OR ISNULL(@cOldResidID,'') <> ISNULL(H.ResidID,'')
								OR ISNULL(@iOldRepID,0) <> ISNULL(S.RepID,0)
								OR ISNULL(@cOldScholarshipLevelID,'') <> ISNULL(S.ScholarshipLevelID,'')
								OR ISNULL(@vcOldBirthLangID,'') <> ISNULL(S.BirthLangID,'')
								OR ISNULL(@myOldAnnualIncome,0) <> ISNULL(S.AnnualIncome,0)
								OR @bOldSemiAnnualStatement <> S.SemiAnnualStatement
								OR ISNULL(@iOldStateID,0) <> ISNULL(S.StateID,0)
								OR ISNULL(@cOldpaysOrigineID,'') <> ISNULL(H.cID_Pays_Origine,'')
								OR ISNULL(@OldPreferenceSuiviID,0) <> ISNULL(s.iID_Preference_Suivi,0)
								OR ISNULL(@vcOldNEQ,'') <> ISNULL(H.StateCompanyNo,'')
								OR @bOldDesireReleveElect <> S.bSouscripteur_Desire_Releve_Elect
								OR @bOldAcceptePubli <> H.bHumain_Accepte_Publipostage	
								OR @vcOldOccupation <> H.vcOccupation										-- 2011-04-08 : + 2011-12 - CM
								OR @vcOldEmployeur <> H.vcEmployeur											-- 2011-04-08 : + 2011-12 - CM
								OR @tiOldNbAnneesService <> H.tiNbAnneesService								-- 2011-04-08 : + 2011-12 - CM
								OR @bOldRapport_Annuel_Direction <> S.bRapport_Annuel_Direction				-- 2011-04-08 : + 2011-12 - CM
								OR @bOldEtats_Financiers_Annuels <> S.bEtats_Financiers_Annuels				-- 2011-04-08 : + 2011-12 - CM
								OR @bOldEtats_Financiers_Semestriels <> S.bEtats_Financiers_Semestriels		-- 2011-06-23 : + 2011-12 - CM
								OR @iOldID_Identite_Souscripteur <> ISNULL(S.iID_Identite_Souscripteur,0)
								OR @vcOldIdentiteVerifieeDescription <> ISNULL(S.vcIdentiteVerifieeDescription,'')
								OR @bAutorisation_Resiliation <> ISNULL(S.bAutorisation_Resiliation,0)
								)
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
						'Un_Subscriber',
						@SubscriberID,
						GETDATE(),
						LA.LogActionID,
						LogDesc = 'Souscripteur : '+H.LastName+', '+H.FirstName,
						LogText =
							CASE 
								WHEN ISNULL(@vcOldFirstName,'') <> ISNULL(H.FirstName,'') THEN
									'FirstName'+@cSep+
									CASE 
										WHEN ISNULL(@vcOldFirstName,'') = '' THEN ''
									ELSE @vcOldFirstName
									END+@cSep+
									CASE 
										WHEN ISNULL(H.FirstName,'') = '' THEN ''
									ELSE H.FirstName
									END+@cSep+
									CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE 
								WHEN ISNULL(@vcOldLastName,'') <> ISNULL(H.LastName,'') THEN
									'LastName'+@cSep+
									CASE 
										WHEN ISNULL(@vcOldLastName,'') = '' THEN ''
									ELSE @vcOldLastName
									END+@cSep+
									CASE 
										WHEN ISNULL(H.LastName,'') = '' THEN ''
									ELSE H.LastName
									END+@cSep+
									CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE 
								WHEN ISNULL(@vcOldOrigName,'') <> ISNULL(H.OrigName,'') THEN
									'OrigName'+@cSep+
									CASE 
										WHEN ISNULL(@vcOldOrigName,'') = '' THEN ''
									ELSE @vcOldOrigName
									END+@cSep+
									CASE 
										WHEN ISNULL(H.OrigName,'') = '' THEN ''
									ELSE H.OrigName
									END+@cSep+
									CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE
								WHEN @cOldLangID <> H.LangID THEN
									'LangID'+@cSep+@cOldLangID+@cSep+H.LangID+@cSep+OL.LangName+@cSep+L.LangName+@cSep+CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE
								WHEN @cOldSexID <> H.SexID THEN
									'SexID'+@cSep+@cOldSexID+@cSep+H.SexID+@cSep+OS.SexName+@cSep+Sx.SexName+@cSep+CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE
								WHEN @cOldCivilID <> H.CivilID THEN
									'CivilID'+@cSep+@cOldCivilID+@cSep+H.CivilID+@cSep+OCS.CivilStatusName+@cSep+CS.CivilStatusName+@cSep+CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE 
								WHEN ISNULL(@dtOldBirthDate,0) <> ISNULL(H.BirthDate,0) THEN
									'BirthDate'+@cSep+
									CASE 
										WHEN ISNULL(@dtOldBirthDate,0) <= 0 THEN ''
									ELSE CONVERT(CHAR(10), @dtOldBirthDate, 20)
									END+@cSep+
									CASE 
										WHEN ISNULL(H.BirthDate,0) <= 0 THEN ''
									ELSE CONVERT(CHAR(10), H.BirthDate, 20)
									END+@cSep+
									CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE 
								WHEN ISNULL(@dtOldDeathDate,0) <> ISNULL(H.DeathDate,0) THEN
									'DeathDate'+@cSep+
									CASE 
										WHEN ISNULL(@dtOldDeathDate,0) <= 0 THEN ''
									ELSE CONVERT(CHAR(10), @dtOldDeathDate, 20)
									END+@cSep+
									CASE 
										WHEN ISNULL(H.DeathDate,0) <= 0 THEN ''
									ELSE CONVERT(CHAR(10), H.DeathDate, 20)
									END+@cSep+
									CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE 
								WHEN ISNULL(@cOldResidID,'') <> ISNULL(H.ResidID,'') THEN
									'ResidID'+@cSep+
									CASE 
										WHEN ISNULL(@cOldResidID,'') = '' THEN ''
									ELSE @cOldResidID
									END+@cSep+
									CASE 
										WHEN ISNULL(H.ResidID,'') = '' THEN ''
									ELSE H.ResidID
									END+@cSep+
									ISNULL(RO.CountryName,'')+@cSep+
									ISNULL(R.CountryName,'')+@cSep+
									CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE 
								WHEN ISNULL(@iOldRepID,0) <> ISNULL(S.RepID,0) THEN
									'RepID'+@cSep+
									CASE 
										WHEN ISNULL(@iOldRepID,0) <= 0 THEN ''
									ELSE CAST(@iOldRepID AS VARCHAR)
									END+@cSep+
									CASE 
										WHEN ISNULL(S.RepID,0) <= 0 THEN ''
									ELSE CAST(S.RepID AS VARCHAR)
									END+@cSep+
									ISNULL(OHR.LastName+', '+OHR.FirstName,'')+@cSep+
									ISNULL(HR.LastName+', '+HR.FirstName,'')+@cSep+
									CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE 
								WHEN ISNULL(@iOldStateID,0) <> ISNULL(S.StateID,0) THEN
									'StateID'+@cSep+
									CASE 
										WHEN ISNULL(@iOldStateID,0) <= 0 THEN ''
									ELSE CAST(@iOldStateID AS VARCHAR)
									END+@cSep+
									CASE 
										WHEN ISNULL(S.StateID,0) <= 0 THEN ''
									ELSE CAST(S.StateID AS VARCHAR)
									END+@cSep+
									ISNULL(OSt.StateName,'')+@cSep+
									ISNULL(St.StateName,'')+@cSep+
									CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE 
								WHEN ISNULL(@cOldScholarshipLevelID,'') <> ISNULL(S.ScholarshipLevelID,'') THEN
									'ScholarshipLevelID'+@cSep+
									CASE 
										WHEN ISNULL(@cOldScholarshipLevelID,'') = '' THEN ''
									ELSE @cOldScholarshipLevelID
									END+@cSep+
									CASE 
										WHEN ISNULL(S.ScholarshipLevelID,'') = '' THEN ''
									ELSE S.ScholarshipLevelID
									END+@cSep+
									CASE ISNULL(@cOldScholarshipLevelID,'')
										WHEN 'UNK' THEN 'Inconnu'
										WHEN 'NDI' THEN 'Non diplômé'
										WHEN 'SEC' THEN 'Secondaire'
										WHEN 'COL' THEN 'Collège'
										WHEN 'UNI' THEN 'Université'
									ELSE ''
									END+@cSep+
									CASE ISNULL(S.ScholarshipLevelID,'')
										WHEN 'UNK' THEN 'Inconnu'
										WHEN 'NDI' THEN 'Non diplômé'
										WHEN 'SEC' THEN 'Secondaire'
										WHEN 'COL' THEN 'Collège'
										WHEN 'UNI' THEN 'Université'
									ELSE ''
									END+@cSep+
									CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE 
								WHEN ISNULL(@vcOldBirthLangID,'') <> ISNULL(S.BirthLangID,'') THEN
									'BirthLangID'+@cSep+
									CASE 
										WHEN ISNULL(@vcOldBirthLangID,'') = '' THEN ''
									ELSE @vcOldBirthLangID
									END+@cSep+
									CASE 
										WHEN ISNULL(S.BirthLangID,'') = '' THEN ''
									ELSE S.BirthLangID
									END+@cSep+
									ISNULL(OWL.WorldLanguage,'')+@cSep+
									ISNULL(WL.WorldLanguage,'')+@cSep+
									CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE 
								WHEN ISNULL(@myOldAnnualIncome,0) <> ISNULL(S.AnnualIncome,0) THEN
									'AnnualIncome'+@cSep+
									CASE 
										WHEN ISNULL(@myOldAnnualIncome,0) <= 0 THEN ''
									ELSE CAST(@myOldAnnualIncome AS VARCHAR)
									END+@cSep+
									CASE 
										WHEN ISNULL(S.AnnualIncome,0) <= 0 THEN ''
									ELSE CAST(S.AnnualIncome AS VARCHAR)
									END+@cSep+
									CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE 
								WHEN ISNULL(@bOldSemiAnnualStatement,0) <> ISNULL(S.SemiAnnualStatement,0) THEN
									'SemiAnnualStatement'+@cSep+
									CAST(ISNULL(@bOldSemiAnnualStatement,0) AS VARCHAR)+@cSep+
									CAST(ISNULL(S.SemiAnnualStatement,0) AS VARCHAR)+@cSep+
									CASE 
										WHEN ISNULL(@bOldSemiAnnualStatement,0) = 0 THEN 'Non'
									ELSE 'Oui'
									END+@cSep+
									CASE 
										WHEN ISNULL(S.SemiAnnualStatement,0) = 0 THEN 'Non'
									ELSE 'Oui'
									END+@cSep+
									CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE
								WHEN ISNULL(@cOldpaysOrigineID,'') <> ISNULL(H.cID_Pays_Origine,'') THEN
									'PaysOrigineID'+@cSep+
									CASE
										WHEN ISNULL(@cOldpaysOrigineID,'') = '' THEN ''
									ELSE @cOldpaysOrigineID
									END+@cSep+
									CASE
										WHEN ISNULL(H.cID_Pays_Origine,'') = '' THEN ''
									ELSE H.cID_Pays_Origine
									END+@cSep+
									ISNULL(OCO.CountryName, '')+@cSep+
									ISNULL(CO.CountryName,'')+@cSep+
									CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE
								WHEN ISNULL(@OldPreferenceSuiviID,0) <> ISNULL(S.iID_Preference_Suivi,0) THEN
									'PreferenceSuiviID'+@cSep+
									CASE
										WHEN ISNULL(@OldPreferenceSuiviID,0) <= 0 THEN ''
									ELSE CAST(@OldPreferenceSuiviID AS VARCHAR)
									END+@cSep+
									CASE
										WHEN ISNULL(S.iID_Preference_Suivi,'') <= '' THEN ''
									ELSE CAST(S.iID_Preference_Suivi AS VARCHAR)
									END+@cSep+
									ISNULL(OPS.vcDescription, '')+@cSep+
									ISNULL(PS.vcDescription,'')+@cSep+
									CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE 
								WHEN ISNULL(@vcOldNEQ,'') <> ISNULL(H.StateCompanyNo,'') THEN
									'NEQ'+@cSep+
									CASE 
										WHEN ISNULL(@vcOldNEQ,'') = '' THEN ''
									ELSE @vcOldNEQ
									END+@cSep+
									CASE 
										WHEN ISNULL(H.StateCompanyNo,'') = '' THEN ''
									ELSE H.StateCompanyNo
									END+@cSep+
									CHAR(13)+CHAR(10)
							ELSE ''
							END+

							CASE
								WHEN ISNULL(@bOldDesireReleveElect, 0) <> ISNULL(S.bSouscripteur_Desire_Releve_Elect, 0) THEN
									'bDesireReleveElect'+@cSep+
									CAST(ISNULL(@bOldDesireReleveElect,0) AS CHAR(1))+@cSep+
									CAST(ISNULL(S.bSouscripteur_Desire_Releve_Elect,0) AS CHAR(1))+@cSep+
									CASE
										WHEN ISNULL(@bOldDesireReleveElect,0) = 0 THEN 'Non'
									ELSE 'Oui'
									END+@cSep+
									CASE 
										WHEN ISNULL(S.bSouscripteur_Desire_Releve_Elect,0) = 0 THEN 'Non'
									ELSE 'Oui'
									END+@cSep+
									CHAR(13)+CHAR(10)
							ELSE ''
							END+

							CASE
								WHEN ISNULL(@bOldAcceptePubli, 0) <> ISNULL(H.bHumain_Accepte_Publipostage, 0) THEN
									'bAcceptePublipostage'+@cSep+
									CAST(ISNULL(@bOldAcceptePubli,0) AS CHAR(1))+@cSep+
									CAST(ISNULL(H.bHumain_Accepte_Publipostage,0) AS CHAR(1))+@cSep+									
									CASE
										WHEN ISNULL(@bOldAcceptePubli, 0) = 0 THEN 'Non'
									ELSE 'Oui'
									END+@cSep+
									CASE 
										WHEN ISNULL(H.bHumain_Accepte_Publipostage,0) = 0 THEN 'Non'
									ELSE 'Oui'
									END+@cSep+
									CHAR(13)+CHAR(10)
							ELSE ''
							END+

							-- 2011-04-08 : + 2011-12 - CM
							CASE 
								WHEN ISNULL(@vcOldOccupation,'') <> ISNULL(H.vcOccupation,'') 
								THEN 'vcOccupation'+@cSep+
									CASE 
										WHEN ISNULL(@vcOldOccupation,'') = '' 
										THEN ''
										ELSE @vcOldOccupation
									END+@cSep+
									CASE 
										WHEN ISNULL(H.vcOccupation,'') = '' 
										THEN ''
										ELSE H.vcOccupation
									END+@cSep+
									CHAR(13)+CHAR(10)
								ELSE ''
							END+

							-- 2011-04-08 : + 2011-12 - CM
							CASE 
								WHEN ISNULL(@vcOldEmployeur,'') <> ISNULL(H.vcEmployeur,'') 
								THEN 'vcEmployeur'+@cSep+
									CASE 
										WHEN ISNULL(@vcOldEmployeur,'') = '' 
										THEN ''
										ELSE @vcOldEmployeur
									END+@cSep+
									CASE 
										WHEN ISNULL(H.vcEmployeur,'') = '' 
										THEN ''
										ELSE H.vcEmployeur
									END+@cSep+
									CHAR(13)+CHAR(10)
								ELSE ''
							END+

							-- 2011-04-08 : + 2011-12 - CM
							CASE 
								WHEN ISNULL(@tiOldNbAnneesService,'') <> ISNULL(H.tiNbAnneesService,'') 
								THEN 'tiNbAnneesService'+@cSep+
									CASE 
										WHEN ISNULL(@tiOldNbAnneesService,'') = '' 
										THEN ''
										ELSE CAST(@tiOldNbAnneesService AS VARCHAR)
									END+@cSep+
									CASE 
										WHEN ISNULL(H.tiNbAnneesService,'') = '' 
										THEN ''
										ELSE CAST(H.tiNbAnneesService AS VARCHAR)
									END+@cSep+
									CHAR(13)+CHAR(10)
								ELSE ''
							END+

							-- 2011-04-08 : + 2011-12 - CM
							CASE
								WHEN ISNULL(@bOldRapport_Annuel_Direction, 0) <> ISNULL(S.bRapport_Annuel_Direction, 0) 
									THEN 'bRapport_Annuel_Direction'+@cSep+
										CAST(ISNULL(@bOldRapport_Annuel_Direction,0) AS CHAR(1))+@cSep+
										CAST(ISNULL(S.bRapport_Annuel_Direction,0) AS CHAR(1))+@cSep+									
										CASE
											WHEN ISNULL(@bOldRapport_Annuel_Direction, 0) = 0 
											THEN 'Non'
											ELSE 'Oui'
										END+@cSep+
										CASE 
											WHEN ISNULL(S.bRapport_Annuel_Direction,0) = 0 
											THEN 'Non'
											ELSE 'Oui'
										END+@cSep+
										CHAR(13)+CHAR(10)
									ELSE ''
							END+

							-- 2011-04-08 : + 2011-12 - CM
							CASE
								WHEN ISNULL(@bOldEtats_Financiers_Annuels, 0) <> ISNULL(S.bEtats_Financiers_Annuels, 0) 
									THEN 'bEtats_Financiers_Annuels'+@cSep+
										CAST(ISNULL(@bOldEtats_Financiers_Annuels,0) AS CHAR(1))+@cSep+
										CAST(ISNULL(S.bEtats_Financiers_Annuels,0) AS CHAR(1))+@cSep+									
										CASE
											WHEN ISNULL(@bOldEtats_Financiers_Annuels, 0) = 0 
											THEN 'Non'
											ELSE 'Oui'
										END+@cSep+
										CASE 
											WHEN ISNULL(S.bEtats_Financiers_Annuels,0) = 0 
											THEN 'Non'
											ELSE 'Oui'
										END+@cSep+
										CHAR(13)+CHAR(10)
									ELSE ''
							END+

							-- 2011-06-23 : + 2011-12 - CM
							CASE
								WHEN ISNULL(@bOldEtats_Financiers_Semestriels, 0) <> ISNULL(S.bEtats_Financiers_Semestriels, 0) 
									THEN 'bEtats_Financiers_Semestriels'+@cSep+
										CAST(ISNULL(@bOldEtats_Financiers_Semestriels,0) AS CHAR(1))+@cSep+
										CAST(ISNULL(S.bEtats_Financiers_Semestriels,0) AS CHAR(1))+@cSep+									
										CASE
											WHEN ISNULL(@bOldEtats_Financiers_Semestriels, 0) = 0 
											THEN 'Non'
											ELSE 'Oui'
										END+@cSep+
										CASE 
											WHEN ISNULL(S.bEtats_Financiers_Semestriels,0) = 0 
											THEN 'Non'
											ELSE 'Oui'
										END+@cSep+
										CHAR(13)+CHAR(10)
								ELSE ''
							END+
							CASE
								WHEN ISNULL(@iOldID_Identite_Souscripteur,0) <> ISNULL(S.iID_Identite_Souscripteur,0) THEN
									'iID_Identite_Souscripteur'+@cSep+
									CASE
										WHEN ISNULL(@iOldID_Identite_Souscripteur,0) <= 0 THEN ''
									ELSE CAST(@iOldID_Identite_Souscripteur AS VARCHAR)
									END+@cSep+
									CASE
										WHEN ISNULL(S.iID_Identite_Souscripteur,0) <= 0 THEN ''
									ELSE CAST(S.iID_Identite_Souscripteur AS VARCHAR)
									END+@cSep+
									ISNULL(OIDS.vcDescription, '')+@cSep+
									ISNULL(IDS.vcDescription,'')+@cSep+
									CHAR(13)+CHAR(10)
								ELSE ''
							END+
							CASE
								WHEN ISNULL(@vcOldIdentiteVerifieeDescription,'') <> ISNULL(S.vcIdentiteVerifieeDescription,'') THEN
									'IdentiteVerifieeDescription'+@cSep+
									CASE
										WHEN ISNULL(@vcOldIdentiteVerifieeDescription,'') = '' THEN ''
									ELSE @vcOldIdentiteVerifieeDescription 
									END+@cSep+
									CASE
										WHEN ISNULL(S.vcIdentiteVerifieeDescription, '') = '' THEN ''
									ELSE S.vcIdentiteVerifieeDescription
									END+@cSep+
									CHAR(13)+CHAR(10)
								ELSE ''
							END+
							CASE
								WHEN ISNULL(@bOldAutorisation_Resiliation, 0) <> ISNULL(S.bAutorisation_Resiliation, 0) THEN
									'bAutorisation_Resiliation'+@cSep+
									CAST(ISNULL(@bOldAutorisation_Resiliation,0) AS CHAR(1))+@cSep+
									CAST(ISNULL(S.bAutorisation_Resiliation,0) AS CHAR(1))+@cSep+
									CASE
										WHEN ISNULL(@bOldAutorisation_Resiliation,0) = 0 THEN 'Non'
									ELSE 'Oui'
									END+@cSep+
									CASE 
										WHEN ISNULL(S.bAutorisation_Resiliation,0) = 0 THEN 'Non'
									ELSE 'Oui'
									END+@cSep+
									CHAR(13)+CHAR(10)
							ELSE ''
							END
						FROM dbo.Un_Subscriber S
						JOIN dbo.Mo_Human H ON H.HumanID = S.SubscriberID
						JOIN Mo_Lang L ON L.LangID = H.LangID
						JOIN Mo_Lang OL ON OL.LangID = @cOldLangID
						JOIN Mo_Sex Sx ON Sx.SexID = H.SexID AND Sx.LangID = 'FRA'
						JOIN Mo_Sex OS ON OS.SexID = @cOldSexID AND OS.LangID = 'FRA'
						JOIN Mo_CivilStatus CS ON CS.LangID = 'FRA' AND CS.SexID = H.SexID AND CS.CivilStatusID = H.CivilID
						JOIN Mo_CivilStatus OCS ON OCS.LangID = 'FRA' AND OCS.SexID = @cOldSexID AND OCS.CivilStatusID = @cOldCivilID
						LEFT JOIN Mo_Country R ON R.CountryID = H.ResidID
						LEFT JOIN Mo_Country RO ON RO.CountryID = @cOldResidID
						LEFT JOIN Mo_Country CO ON CO.CountryID = H.cID_Pays_Origine
						LEFT JOIN Mo_Country OCO ON OCO.CountryID = @cOldpaysOrigineID
						LEFT JOIN dbo.Mo_Human HR ON HR.HumanID = S.RepID
						LEFT JOIN dbo.Mo_Human OHR ON OHR.HumanID = @iOldRepID
						LEFT JOIN Mo_State St ON St.StateID = S.StateID
						LEFT JOIN Mo_State OSt ON OSt.StateID = @iOldStateID
						LEFT JOIN CRQ_WorldLang WL ON WL.WorldLanguageCodeID = S.BirthLangID
						LEFT JOIN CRQ_WorldLang OWL ON OWL.WorldLanguageCodeID = @vcOldBirthLangID
						JOIN CRQ_LogAction LA ON LA.LogActionShortName = 'U'
						JOIN tblCONV_PreferenceSuivi PS ON PS.iID_Preference_Suivi = S.iID_Preference_Suivi
						LEFT JOIN tblCONV_PreferenceSuivi OPS ON OPS.iID_Preference_Suivi = @OldPreferenceSuiviID
						LEFT JOIN tblCONV_IdentiteSouscripteur IDS ON IDS.iID_Identite_Souscripteur = S.iID_Identite_Souscripteur
						LEFT JOIN tblCONV_IdentiteSouscripteur OIDS ON OIDS.iID_Identite_Souscripteur = @iOLDID_Identite_Souscripteur
						WHERE S.SubscriberID = @SubscriberID
			END
		END
	END

	-- Mettre à jour l'état des prévalidations du souscripteur
	EXEC @iErrorID = psCONV_EnregistrerPrevalidationPCEE @ConnectID, NULL, NULL, @SubscriberID, NULL

	IF @iErrorID <= 0 
			SET @SubscriberID = 0

	SELECT
		@tiCESPState = tiCESPState
	FROM dbo.Un_Subscriber S
	WHERE S.SubscriberID = @SubscriberID

	-- Gestion de l'historique des NAS
	IF @SubscriberID <> 0
		EXECUTE TT_UN_HumanSocialNumber @ConnectID, @SubscriberID, @SocialNumber
	
	/*
	-- Gestion des enregistrements 100, 200 et 400
	IF @SubscriberID <> 0
	AND @tiCESPState <> @tiOldCESPState
	BEGIN
		-- Met à jour l'état de pré-validations des conventions du souscripteur
		UPDATE dbo.Un_Convention 
		SET tiCESPState = 
				CASE 
					WHEN ISNULL(CS.tiCESPState,1) = 0 
						OR S.tiCESPState = 0 
						OR B.tiCESPState = 0 THEN 0
				ELSE B.tiCESPState
				END
		FROM dbo.Un_Convention 
		JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = Un_Convention.BeneficiaryID
		JOIN dbo.Un_Subscriber S ON S.SubscriberID = Un_Convention.SubscriberID
		LEFT JOIN dbo.Un_Subscriber CS ON CS.SubscriberID = Un_Convention.CoSubscriberID
		WHERE S.SubscriberID = @SubscriberID
			AND Un_Convention.tiCESPState <> 
						CASE 
							WHEN ISNULL(CS.tiCESPState,1) = 0 
								OR S.tiCESPState = 0 
								OR B.tiCESPState = 0 THEN 0
						ELSE B.tiCESPState
						END

		IF @@ERROR <> 0
			SET @SubscriberID = 0
	END
	*/

	-- Gestion des enregistrements 100, 200 et 400
	IF --@tiCESPState = 1
	--AND 
	@SubscriberID <> 0
	AND EXISTS (	SELECT S.SubscriberID
						FROM dbo.Un_Subscriber S
						JOIN dbo.Mo_Human H ON H.HumanID = S.SubscriberID
						JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
						WHERE S.SubscriberID = @SubscriberID
							-- Vérifie s'il y a des informations modifiés qui affecte les enregistrements 100, 200 ou 400
							OR H.LastName <> @vcOldLastName
							OR H.IsCompany <> @bOldIsCompany
							OR (H.FirstName <> @vcOldFirstName AND H.IsCompany = 0)
							OR H.SocialNumber <> @vcOldSocialNumber
							OR A.Address <> @vcOldAddress
							OR A.City <> @vcOldCity
							OR A.Statename <> @vcOldStateName
							OR A.ZipCode <> @vcOldZipCode
							OR A.CountryID <> @cOldCountryID
							OR S.tiCESPState <> @tiOldCESPState
					)
	BEGIN
		DECLARE 
			@iExecResult INTEGER

		-- Appelle de la procédure stockée qui gère les enregistrements 100, 200, et 400 de toutes les conventions du bénéficiaire.
		EXECUTE @iExecResult = TT_UN_CESPOfConventions @ConnectID, 0, @SubscriberID, 0

		IF @iExecResult <= 0
			SET @SubscriberID = 0
	END

	-- Fin des traitements
	IF @@ERROR = 0
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
	BEGIN
		--------------------
		ROLLBACK TRANSACTION
		--------------------
		SET @SubscriberID = 0
	END

	RETURN(@SubscriberID)
END


