
/****************************************************************************************************
Code de service		:		IMo_Human
Nom du service		:		IMo_Human
But					:		
Facette				:		
Reférence			:		

Parametres d'entrée :	Parametres					Description
		                ----------                  ----------------
						  @ConnectID	
						  @HumanID      
						  @FirstName    
						  @OrigName     
						  @Initial      
						  @LastName     
						  @BirthDate    
						  @DeathDate    
						  @SexID        
						  @LangID       
						  @CivilID       
						  @SocialNumber   
						  @ResidID         
						  @DriverLicenseNo 
						  @WebSite          
						  @CompanyName         
						  @CourtesyTitle       
						  @UsingSocialNumber   
						  @SharePersonalInfo   
						  @MarketingMaterial   
						  @IsCompany           
						  @InForce             
						  @Address             
						  @City                
						  @StateName           
						  @CountryID         
						  @ZipCode           
						  @Phone1            
						  @Phone2            
						  @Fax               
						  @Mobile            
						  @WattLine          
						  @OtherTel          
						  @Pager             
						  @EMail             

Exemple d'appel:
							
		
Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
													@HumanID

Historique des modifications :
			
		Date						Programmeur								Description							Référence
		----------				-------------------------------------	----------------------------		---------------
		2009-09-24			Jean-François Gauthier				Remplacement de @@Identity par Scope_Identity()
		2010-01-25			Jean-François Gauthier				Rendre tous les paramètres d'entrée optionel
		2014-03-12			Pierre-Luc Simard						Appeler la procédure SP_IU_CRQ_Adr au lieu de IMo_Adr
 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[IMo_Human]
 (@ConnectID			MoID			= NULL,
  @HumanID              MoID			= NULL,
  @FirstName            MoFirstName		= NULL,
  @OrigName             MoDescOption	= NULL,
  @Initial              MoInitial		= NULL,
  @LastName             MoLastName		= NULL,	
  @BirthDate            MoDateOption	= NULL,
  @DeathDate            MoDateOption	= NULL,
  @SexID                MoSex			= NULL,
  @LangID               MoLang			= NULL,
  @CivilID              MoCivil			= NULL,
  @SocialNumber         MoDescOption	= NULL,
  @ResidID              MoCountry		= NULL,
  @DriverLicenseNo      MoDescOption	= NULL,
  @WebSite              MoDescOption	= NULL,
  @CompanyName          MoDescOption	= NULL,
  @CourtesyTitle        MoFirstNameOption = NULL,
  @UsingSocialNumber    MoBitTrue		= NULL,
  @SharePersonalInfo    MoBitTrue		= NULL,
  @MarketingMaterial    MoBitTrue		= NULL,
  @IsCompany            MoBitFalse		= NULL,
  @InForce              MoDate			= NULL,
  @Address              MoAdress		= NULL,
  @City                 MoCity			= NULL,
  @StateName            MoDescOption	= NULL,
  @CountryID            MoCountry		= NULL,
  @ZipCode              MoZipCode		= NULL,
  @Phone1               MoPhoneExt		= NULL,
  @Phone2               MoPhoneExt		= NULL,
  @Fax                  MoPhone			= NULL,
  @Mobile               MoPhone			= NULL,
  @WattLine             MoPhoneExt		= NULL,
  @OtherTel             MoPhoneExt		= NULL,
  @Pager                MoPhone			= NULL,
  @EMail                MoEmail			= NULL)
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
  @Old_IsCompany            MoBitFalse;

  SET @AdrID  = NULL;
  SET @AdrTypeID = 'H';

  IF RTRIM(@CompanyName) = ''
    SET @CompanyName = NULL;

  EXECUTE IMo_IsDateNull @BirthDate OUTPUT;
  EXECUTE IMo_IsDateNull @DeathDate OUTPUT;

  IF @FirstName <> ''
    SET @FirstName = UPPER(SUBSTRING(@FirstName,1,1))+  SUBSTRING(@FirstName,2,(LEN(@FirstName)-1))
  IF @LastName <> ''
    SET @LastName = UPPER(SUBSTRING(@LastName,1,1))+  SUBSTRING(@LastName,2,(LEN(@LastName)-1))

  IF RTRIM(@SocialNumber) = ''
    SET @SocialNumber = NULL

  IF (@SexID = '') OR (@SexID IS NULL)
    SET @SexID = 'U';

  IF (@LangID = '') OR (@LangID IS NULL)
    SET @LangID = 'UNK';

  --****************************************
  --Initialisation des variables pour le log
  SET @LogDesc = ''

  IF ((@HumanID IS NULL) OR (@HumanID = 0))
    SET @HeaderLog = dbo.fn_Mo_FormatLog ('MO_HUMAN', 'NEW', '', (@LastName + ', '+ @FirstName))
  ELSE
  BEGIN
    SET @HeaderLog = dbo.fn_Mo_FormatLog ('MO_HUMAN', 'MODIF', '', (@LastName + ', '+ @FirstName))
    SELECT
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
      @Old_IsCompany         = IsCompany
    FROM dbo.Mo_Human
    WHERE (HumanID = @HumanID)
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
  IF @LogDesc <> '' SET @LogDesc = @HeaderLog + @LogDesc
  --****************************************

  IF ((@HumanID IS NULL) OR (@HumanID = 0))
  BEGIN
    /* L'humain n'existe pas encore */
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
      IsCompany)
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
      @IsCompany);
      
    IF (@@ERROR = 0)
    BEGIN
      SELECT @HumanID = SCOPE_IDENTITY();

      EXEC IMo_Log @ConnectID, 'Mo_Human', @HumanID, 'I', @LogDesc;
    END
    ELSE
      GOTO ON_ERROR_IHUMAN
  END
  ELSE
  BEGIN
    /* Modifier les informations de l'humain */
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
      IsCompany = @IsCompany
    WHERE (HumanID = @HumanID);

    IF (@@ERROR <> 0)
      GOTO ON_ERROR_IHUMAN

    IF @LogDesc <> ''
      EXEC IMo_Log @ConnectID, 'Mo_Human', @HumanID, 'U', @LogDesc;

    /* On va chercher le code ID de l'adresse */
    SELECT @AdrID = AdrID
    FROM dbo.Mo_Human
    WHERE (HumanID = @HumanID);
  END
  /* Création ou modification de l'adresse */
  EXECUTE @AdrID = SP_IU_CRQ_Adr --IMo_Adr
    @ConnectID,
    @AdrID,
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
    @EMail;

  /* L'adresse sera mis à jour dans la table 'Mo_Human' */
  IF @AdrID <> 0
    UPDATE dbo.Mo_Human SET
      AdrID = @AdrID
    WHERE (HumanID = @HumanID);

  RETURN @HumanID;
  ON_ERROR_IHUMAN:
    RETURN (0)
END;
