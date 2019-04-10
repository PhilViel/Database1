/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	SP_IU_CRQ_Human
Description         :	Sauvegarde d'ajout ou de mise à jour d'humains.
Valeurs de retours  :	@ReturnValue :
									>0 :	La sauvegarde a réussie.  La valeur de retour correspond au HumanID de l'humain 
											sauvegardé.
									<=0 :	La sauvegarde a échouée.
Note                :	ADX0000590	IA	2004-11-19	Bruno Lapointe					Migration, normalisation et documentation. 
																							Modifié pour qu'elle crée une nouvelle adresse
																							lors de modification plutôt que de modifier celle
																							existante afin de créer l'historique.
								ADX0001602	BR	2005-10-11	Bruno Lapointe			SCOPE_IDENTITY au lieu de IDENT_CURRENT
								ADX0001337	IA	2007-06-04	Bruno Lapointe			Calcul automatique de l'année de qualification.
												2008-09-15  Radu Trandafir			Ajout du champ PaysOrigine 
												2008-10-02  Patrick Robitaille		Ajout de la gestion du NEQ via le champ StateCompanyNo (Champ existant)
												2009-06-16	Patrick Robitaille		Ajout du champ bHumain_Accepte_Publipostage
												2011-04-08	Corentin Menthonnex		2011-12 : ajout des champs suivants aux informations souscripteur
																						- vcOccupation
																						- vcEmployeur
																						- tiNbAnneesService
												2014-02-13	Pierre-Luc Simard	Déplacer l'ancienne adresse dans la table historique
												2014-05-01	Pierre-Luc Simard	@Old_AdrID = 0 pour corriger le problème avec la création de nouveaux humains 
												2014-06-05	Maxime Martel		Ne prend pas en compte le champ bHumain_Accepte_Publipostage dans les insert 
												2014-09-30	Pierre-Luc Simard	Ne prend pas en compte le champ bHumain_Accepte_Publipostage dans les update
												2015-06-30  Steve Picard		L'historisation se fait désormais par les triggers TRG_GENE_Adresse_Historisation
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_IU_CRQ_Human] (
	@ConnectID 				 MoID,
	@HumanID              MoID,
	@FirstName            MoFirstName,
	@OrigName             MoDescOption = NULL,
	@Initial              MoInitial = NULL,
	@LastName             MoLastName,
	@BirthDate            MoDateOption,
	@DeathDate            MoDateOption,
	@SexID                MoSex,
	@LangID               MoLang,
	@CivilID              MoCivil,
	@SocialNumber         MoDescOption = NULL,
	@ResidID              MoCountry,
	@DriverLicenseNo      MoDescOption,
	@WebSite              MoDescOption,
	@CompanyName          MoDescOption,
	@CourtesyTitle        MoFirstNameOption,
	@UsingSocialNumber    MoBitTrue,
	@SharePersonalInfo    MoBitTrue,
	@MarketingMaterial    MoBitTrue,
	@IsCompany            MoBitFalse,
	@InForce              MoDate,
	@Address              MoAdress = NULL,
	@City                 MoCity = NULL,
	@StateName            MoDescOption = NULL,
	@CountryID            MoCountry = NULL,
	@ZipCode              MoZipCode = NULL,
	@Phone1               MoPhoneExt = NULL,
	@Phone2               MoPhoneExt = NULL,
	@Fax                  MoPhone = NULL,
	@Mobile               MoPhone = NULL,
	@WattLine             MoPhoneExt = NULL,
	@OtherTel             MoPhoneExt = NULL,
	@Pager                MoPhone = NULL,
	@EMail                MoEmail = NULL,
	@PaysOrigineID        CHAR(4) = NULL,
	@StateCompanyNo		  MoDescOption = NULL,
	@bHumainAcceptePubli  BIT = 0,
	@vcOccupation		  VARCHAR(50) = NULL,	-- 2011-04-08 : + 2011-12 - CM
	@vcEmployeur		  VARCHAR(50) = NULL,	-- 2011-04-08 : + 2011-12 - CM
	@tiNbAnneesService	  TINYINT = NULL)		-- 2011-04-08 : + 2011-12 - CM
AS
BEGIN
	DECLARE
		@AdrID                    MoIDOption,
		@AdrTypeID                MoAdrType,
		@LogDesc                  MoNoteDescOption,
		@HeaderLog                MoNoteDescOption,
		@Old_AdrID                MoIDOption,
		@Old_FirstName            MoFirstName,
		@Old_OrigName             MoDescOption,
		@Old_Initial              MoInitial,
		@Old_LastName             MoLastName,
		@Old_BirthDate            MoDateOption,
		@Old_DeathDate            MoDateOption,
		@Old_SexID                MoSex,
		@Old_LangID               MoLang,
		@Old_CivilID              MoCivil,
		@Old_SocialNumber         MoDescOption,
		@Old_ResidID              MoCountry,
		@Old_DriverLicenseNo      MoDescOption,
		@Old_WebSite              MoDescOption,
		@Old_CompanyName          MoDescOption,
		@Old_CourtesyTitle        MoFirstNameOption,
		@Old_UsingSocialNumber    MoBitTrue,
		@Old_SharePersonalInfo    MoBitTrue,
		@Old_MarketingMaterial    MoBitTrue,
		@Old_IsCompany            MoBitFalse,
		@OldPaysOrigineID         CHAR(4),
		@Old_StateCompanyNo		  MoDescOption,
		@Old_AcceptePubli		  BIT,
		@vcOldOccupation		  VARCHAR(50),	-- 2011-04-08 : + 2011-12 - CM
		@vcOldEmployeur			  VARCHAR(50),	-- 2011-04-08 : + 2011-12 - CM
		@tiOldNbAnneesService	  TINYINT		-- 2011-04-08 : + 2011-12 - CM

	SET @AdrID = 0
	SET @AdrTypeID = 'H'

	IF RTRIM(@CompanyName) = ''
		SET @CompanyName = NULL

	EXECUTE IMo_IsDateNull @BirthDate OUTPUT
	EXECUTE IMo_IsDateNull @DeathDate OUTPUT

	IF @FirstName <> ''
		SET @FirstName = UPPER(SUBSTRING(@FirstName,1,1))+  SUBSTRING(@FirstName,2,(LEN(@FirstName)-1))
	IF @LastName <> ''
		SET @LastName = UPPER(SUBSTRING(@LastName,1,1))+  SUBSTRING(@LastName,2,(LEN(@LastName)-1))

	IF RTRIM(@SocialNumber) = ''
		SET @SocialNumber = NULL

	IF @SexID = '' OR 
		@SexID IS NULL
		SET @SexID = 'U'

	IF @LangID = '' OR 
		@LangID IS NULL
		SET @LangID = 'UNK'

	IF @HumanID IS NULL
		SET @HumanID = 0

	--****************************************
	--Initialisation des variables pour le log
	SET @LogDesc = ''

	IF @HumanID = 0
		SET @HeaderLog = dbo.fn_Mo_FormatLog ('MO_HUMAN', 'NEW', '', (@LastName + ', '+ @FirstName))
	ELSE
	BEGIN
		SET @HeaderLog = dbo.fn_Mo_FormatLog ('MO_HUMAN', 'MODIF', '', (@LastName + ', '+ @FirstName))
		SELECT
			@Old_AdrID			= AdrID,
			@Old_FirstName       = FirstName,
			@Old_OrigName        = OrigName,
			@Old_Initial         = Initial,
			@Old_LastName        = LastName,
			@Old_BirthDate       = BirthDate,
			@Old_DeathDate       = DeathDate,
			@Old_SexID           = SexID,
			@Old_LangID          = LangID,
			@Old_CivilID         = CivilID,
			@Old_SocialNumber    = SocialNumber,
			@Old_ResidID         = ResidID,
			@Old_DriverLicenseNo = DriverLicenseNo,
			@Old_WebSite         = WebSite,
			@Old_CompanyName     = CompanyName,
			@Old_CourtesyTitle   = CourtesyTitle,
			@Old_UsingSocialNumber = UsingSocialNumber,
			@Old_SharePersonalInfo = SharePersonalInfo,
			@Old_MarketingMaterial = MarketingMaterial,
			@Old_IsCompany         = IsCompany,
			@OldPaysOrigineID      = CID_Pays_Origine,
			@Old_StateCompanyNo	   = StateCompanyNo,
			@Old_AcceptePubli	 = bHumain_Accepte_Publipostage,
			@vcOldOccupation		  = vcOccupation,		-- 2011-04-08 : + 2011-12 - CM
			@vcOldEmployeur			  = vcEmployeur,		-- 2011-04-08 : + 2011-12 - CM
			@tiOldNbAnneesService	  = tiNbAnneesService	-- 2011-04-08 : + 2011-12 - CM
		FROM dbo.Mo_Human
		WHERE HumanID = @HumanID
	END

	SET @LogDesc = @LogDesc + dbo.fn_Mo_FormatLog ('MO_HUMAN', 'FIRSTNAME', @Old_FirstName, @FirstName)
	SET @LogDesc = @LogDesc + dbo.fn_Mo_FormatLog ('MO_HUMAN', 'LASTNAME', @Old_LastName, @LastName)
	SET @LogDesc = @LogDesc + dbo.fn_Mo_FormatLog ('MO_HUMAN', 'ORIGNAME', @Old_OrigName, @OrigName)
	SET @LogDesc = @LogDesc + dbo.fn_Mo_FormatLog ('MO_HUMAN', 'INITIAL', @Old_Initial, @Initial)
	SET @LogDesc = @LogDesc + dbo.fn_Mo_FormatLog ('MO_HUMAN', 'BIRTHDATE', CAST(@Old_BirthDate AS CHAR), CAST(@BirthDate AS CHAR))
	SET @LogDesc = @LogDesc + dbo.fn_Mo_FormatLog ('MO_HUMAN', 'DEATHDATE', CAST(@Old_DeathDate AS CHAR), CAST(@DeathDate AS CHAR))
	SET @LogDesc = @LogDesc + dbo.fn_Mo_FormatLog ('MO_HUMAN', 'SEXID', dbo.fn_Mo_SexDesc(@Old_SexID), dbo.fn_Mo_SexDesc(@SexID))
	SET @LogDesc = @LogDesc + dbo.fn_Mo_FormatLog ('MO_HUMAN', 'LANGID', dbo.fn_Mo_LangDesc(@Old_LangID), dbo.fn_Mo_LangDesc(@LangID))
	SET @LogDesc = @LogDesc + dbo.fn_Mo_FormatLog ('MO_HUMAN', 'CIVILID', dbo.fn_Mo_CivilDesc(@Old_CivilID), dbo.fn_Mo_CivilDesc(@CivilID))
	SET @LogDesc = @LogDesc + dbo.fn_Mo_FormatLog ('MO_HUMAN', 'SOCIALNUMBER', @Old_SocialNumber, @SocialNumber)
	SET @LogDesc = @LogDesc + dbo.fn_Mo_FormatLog ('MO_HUMAN', 'RESIDID', @Old_ResidID, @ResidID)
	SET @LogDesc = @LogDesc + dbo.fn_Mo_FormatLog ('MO_HUMAN', 'DRIVERLICENSENO', @Old_DriverLicenseNo, @DriverLicenseNo)
	SET @LogDesc = @LogDesc + dbo.fn_Mo_FormatLog ('MO_HUMAN', 'WEBSITE', @Old_WebSite, @WebSite)
	SET @LogDesc = @LogDesc + dbo.fn_Mo_FormatLog ('MO_HUMAN', 'COMPANYNAME', @Old_CompanyName, @CompanyName)
	SET @LogDesc = @LogDesc + dbo.fn_Mo_FormatLog ('MO_HUMAN', 'COURTESYTITLE', @Old_CourtesyTitle, @CourtesyTitle)
	SET @LogDesc = @LogDesc + dbo.fn_Mo_FormatLog ('MO_HUMAN', 'UsingSocialNumber', CAST(@Old_UsingSocialNumber AS CHAR), CAST(@UsingSocialNumber AS CHAR))
	SET @LogDesc = @LogDesc + dbo.fn_Mo_FormatLog ('MO_HUMAN', 'SharePersonalInfo', CAST(@Old_SharePersonalInfo AS CHAR), CAST(@SharePersonalInfo AS CHAR))
	SET @LogDesc = @LogDesc + dbo.fn_Mo_FormatLog ('MO_HUMAN', 'MarketingMaterial', CAST(@Old_MarketingMaterial AS CHAR), CAST(@MarketingMaterial AS CHAR))
	SET @LogDesc = @LogDesc + dbo.fn_Mo_FormatLog ('MO_HUMAN', 'IsCompany', CAST(@Old_IsCompany AS CHAR), CAST(@IsCompany AS CHAR))
	SET @LogDesc = @LogDesc + dbo.fn_Mo_FormatLog ('MO_HUMAN', 'PaysOrigineID', @OldPaysOrigineID, @PaysOrigineID)
	SET @LogDesc = @LogDesc + dbo.fn_Mo_FormatLog ('MO_HUMAN', 'StateCompanyNo', @Old_StateCompanyNo, @StateCompanyNo)
	--SET @LogDesc = @Logdesc + dbo.fn_Mo_FormatLog ('MO_HUMAN', 'bHumain_Accepte_Publipostage', CAST(@Old_AcceptePubli AS CHAR), CAST(@bHumainAcceptePubli AS CHAR))
	SET @LogDesc = @LogDesc + dbo.fn_Mo_FormatLog ('MO_HUMAN', 'vcOccupation', @vcOldOccupation, @vcOccupation)														-- 2011-04-08 : + 2011-12 - CM
	SET @LogDesc = @LogDesc + dbo.fn_Mo_FormatLog ('MO_HUMAN', 'vcEmployeur', @vcOldEmployeur, @vcEmployeur)														-- 2011-04-08 : + 2011-12 - CM
	SET @LogDesc = @LogDesc + dbo.fn_Mo_FormatLog ('MO_HUMAN', 'tiNbAnneesService', CAST(@tiOldNbAnneesService AS VARCHAR), CAST(@tiNbAnneesService AS VARCHAR))	-- 2011-04-08 : + 2011-12 - CM
	IF @LogDesc <> '' 
		SET @LogDesc = @HeaderLog + @LogDesc
	--****************************************

	IF @HumanID = 0
	BEGIN
		-- L'humain n'existe pas encore 
		INSERT INTO dbo.Mo_Human (
			FirstName,
			OrigName,
			Initial,
			LastName,
			BirthDate,
			DeathDate,
			SexID,
			LangID,
			CivilID,
			SocialNumber,
			ResidID,
			DriverLicenseNo,
			WebSite,
			CompanyName,
			CourtesyTitle,
			UsingSocialNumber,
			SharePersonalInfo,
			MarketingMaterial,
			IsCompany,
			InsertConnectID,
			cID_Pays_Origine,
			StateCompanyNo,
			--bHumain_Accepte_Publipostage,
			vcOccupation,			-- 2011-04-08 : + 2011-12 - CM
			vcEmployeur,			-- 2011-04-08 : + 2011-12 - CM
			tiNbAnneesService)	-- 2011-04-08 : + 2011-12 - CM
		VALUES (
			@FirstName,
			@OrigName,
			@Initial,
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
			@ConnectID,
			@PaysOrigineID,
			@StateCompanyNo,
			--@bHumainAcceptePubli,
			@vcOccupation,			-- 2011-04-08 : + 2011-12 - CM
			@vcEmployeur,			-- 2011-04-08 : + 2011-12 - CM
			@tiNbAnneesService)	-- 2011-04-08 : + 2011-12 - CM
      
		IF @@ERROR = 0
		BEGIN
			SET @HumanID = SCOPE_IDENTITY()

			EXEC IMo_Log @ConnectID, 'Mo_Human', @HumanID, 'I', @LogDesc
		END
	END
	ELSE
	BEGIN
		-- Modifier les informations de l'humain 
		UPDATE dbo.Mo_Human SET
			FirstName = @FirstName,
			OrigName = @OrigName,
			Initial = @Initial,
			LastName = @LastName,
			BirthDate = @BirthDate,
			DeathDate = @DeathDate,
			SexID = @SexID,
			LangID = @LangID,
			CivilID = @CivilID,
			SocialNumber = @SocialNumber,
			ResidID = @ResidID,
			DriverLicenseNo = @DriverLicenseNo,
			WebSite = @WebSite,
			CompanyName = @CompanyName,
			CourtesyTitle = @CourtesyTitle,
			UsingSocialNumber = @UsingSocialNumber,
			SharePersonalInfo = @SharePersonalInfo,
			MarketingMaterial = @MarketingMaterial,
			IsCompany = @IsCompany,
			LastUpdateConnectID = @ConnectID,
			cID_Pays_Origine = @PaysOrigineID,
			StateCompanyNo = @StateCompanyNo,
			--bHumain_Accepte_Publipostage = @bHumainAcceptePubli,
			vcOccupation = @vcOccupation,				-- 2011-04-08 : + 2011-12 - CM
			vcEmployeur = @vcEmployeur,					-- 2011-04-08 : + 2011-12 - CM
			tiNbAnneesService = @tiNbAnneesService	-- 2011-04-08 : + 2011-12 - CM
		WHERE HumanID = @HumanID

		IF @@ERROR <> 0
			SET @HumanID = 0
		ELSE
		BEGIN
			IF @LogDesc <> ''
				EXEC IMo_Log @ConnectID, 'Mo_Human', @HumanID, 'U', @LogDesc
		END
	END

	IF @HumanID > 0
	BEGIN 
		/*
	    -- On va chercher le code ID de l'adresse 
   		SELECT @Old_AdrID = ISNULL(AdrID,0)
	    FROM dbo.Mo_Human
   		WHERE HumanID = @HumanID
		*/
		IF @Old_AdrID IS NULL	
			SET @Old_AdrID = 0
		
		-- Création ou modification de l'adresse 
		EXECUTE @AdrID = SP_IU_CRQ_Adr
			@ConnectID,
			@Old_AdrID,
			@InForce,
			@AdrTypeID,
			@HumanID,
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
			@EMail
			
		IF @AdrID > 0
		BEGIN 
			-- L'adresse sera mis à jour dans la table 'Mo_Human' 
			UPDATE dbo.Mo_Human
			SET AdrID = @AdrID
			WHERE HumanID = @HumanID
/*
			-- Récupère l'ID de l'adresse en cours au cas où elle n'aurait pas été modifiée
			SELECT @AdrID = H.AdrID
			FROM dbo.Mo_Human H
			WHERE H.HumanID = @HumanID
*/
			-- Supprimer les autres adresses de la même journée
			DELETE tblGENE_Adresse
			WHERE iID_Source = @HumanID
				AND iID_Type = 1
				AND dtDate_Debut = dbo.FN_CRQ_DateNoTime(GETDATE())
				AND iID_Adresse <> @AdrID
			
			--	Déplacer l'ancienne adresse dans la table historique si celle-ci n'a pas été supprimée 
			--IF EXISTS (SELECT 1 FROM tblGENE_Adresse A WHERE A.iID_Adresse = @Old_AdrID) 
			--BEGIN
				---- On insère l'ancienne adresse dans la table des adresses historiques
				--INSERT INTO tblGENE_AdresseHistorique (
				--	iID_Source,
				--	cType_Source,
				--	iID_Type,
				--	dtDate_Debut,
				--	dtDate_Fin,
				--	bInvalide,
				--	dtDate_Creation,
				--	vcLogin_Creation,
				--	vcNumero_Civique,
				--	vcNom_Rue,
				--	vcUnite,
				--	vcCodePostal,
				--	vcBoite,
				--	iID_TypeBoite,
				--	iID_Ville,
				--	vcVille,
				--	iID_Province,
				--	vcProvince,
				--	cID_Pays,
				--	vcPays,
				--	bNouveau_Format,
				--	bResidenceFaitQuebec,
				--	bResidenceFaitCanada,
				--	vcInternationale1,
				--	vcInternationale2,
				--	vcInternationale3)
				--SELECT     
				--	iID_Source,
				--	cType_Source,
				--	iID_Type,
				--	dtDate_Debut,
				--	dbo.FN_CRQ_DateNoTime(GETDATE()), 
				--	bInvalide,
				--	dtDate_Creation,
				--	vcLogin_Creation,
				--	vcNumero_Civique,
				--	vcNom_Rue,
				--	vcUnite,
				--	vcCodePostal,
				--	vcBoite,
				--	iID_TypeBoite,
				--	iID_Ville,
				--	vcVille,
				--	iID_Province,
				--	vcProvince,
				--	cID_Pays,
				--	vcPays,
				--	bNouveau_Format,
				--	bResidenceFaitQuebec,
				--	bResidenceFaitCanada,
				--	vcInternationale1,
				--	vcInternationale2,
				--	vcInternationale3
				--FROM tblGENE_Adresse A
				----WHERE A.iID_Adresse = @Old_AdrID
				--WHERE iID_Source = @HumanID
				--	AND iID_Type = 1
				--	AND dtDate_Debut < dbo.FN_CRQ_DateNoTime(GETDATE())
				--	AND iID_Adresse <> @AdrID
				
				-- On supprime l'ancienne adresse de la table des adresses courantes
				DELETE FROM tblGENE_Adresse 
				--WHERE iID_Adresse = @Old_AdrID
				WHERE iID_Source = @HumanID
					AND iID_Type = 1
					AND dtDate_Debut < dbo.FN_CRQ_DateNoTime(GETDATE())
					AND iID_Adresse <> @AdrID
			END 
			
			--PRINT @Old_AdrID
			
		--END
		
		IF @@ERROR <> 0
			SET @HumanID = 0
	END

	RETURN @HumanID
END 

