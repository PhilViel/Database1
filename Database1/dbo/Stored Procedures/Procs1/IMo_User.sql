
-- 2008-08-18	Patrice Peau	Ajout du champs PasswordEndDate et des valeurs NULL aux paramètres

CREATE PROCEDURE [dbo].[IMo_User]
 (@ConnectID            MoID,
  @UserID               MoID,
  @FirstName            MoFirstName,
  @OrigName             MoDescOption = NULL,
  @Initial              MoInitial = NULL,
  @LastName             MoLastName,
  @BirthDate            MoDateOption = NULL,
  @DeathDate            MoDateOption = NULL,
  @SexID                MoSex = NULL,
  @LangID               MoLang,
  @CivilID              MoCivil = NULL,
  @SocialNumber         MoDescOption = NULL,
  @ResidID              MoCountry = NULL,
  @DriverLicenseNo      MoDescOption = NULL,
  @WebSite              MoDescOption = NULL,
  @CompanyName          MoDescOption = NULL,
  @CourtesyTitle        MoFirstNameOption = NULL,
  @UsingSocialNumber    MoBitTrue = NULL,
  @SharePersonalInfo    MoBitTrue = NULL,
  @MarketingMaterial    MoBitTrue = NULL,
  @IsCompany            MoBitFalse = NULL,
  @InForce              MoDate = NULL,
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
  @TerminatedDate       MoDateOption = NULL,
  @PasswordEndDate      MoDateOption = NULL,
  @LoginNameID          MoLoginName,
  @PassWordID           MoLoginName,
  @CodeID               MoIDOption)
AS
BEGIN

DECLARE
  @IUserID              MoID,
  @SUserID              MoIDOption,
  @OldLoginNameID       MoLoginName,
  @OldPassWordID        MoLoginName,
  @PassWordDate         MoDate,
  @UserCount            MoID,
  @MaxActiveUser        MoID

  SELECT @MaxActiveUser = MaxActiveUser
  FROM Mo_Def

  IF @MaxActiveUser IS NOT NULL
  BEGIN
    SELECT @UserCount = Count(*)
    FROM Mo_User
    WHERE TerminatedDate IS NULL
    IF (@UserCount >= @MaxActiveUser) AND (@UserID = 0)
      RETURN(-100)
  END

  SET @LoginNameID = RTRIM(LOWER(@LoginNameID));
  SET @PassWordID = RTRIM(LOWER(@PassWordID));

  IF @TerminatedDate <= 0
    SET @TerminatedDate = NULL;

  IF (@UserID = 0)
  BEGIN
    /* On doit faire une vérification s'il n'existe pas encore le LoginName de l'usager */
    IF (EXISTS (SELECT UserID
                FROM Mo_User
                WHERE (LoginNameID = @LoginNameID) ) )
      RETURN (-1)
  END
  ELSE
  BEGIN
    SELECT
      @SUserID = UserID,
      @OldLoginNameID = LoginNameID,
      @OldPassWordID = PassWordID,
      @PassWordDate = PassWordDate
    FROM Mo_User
    WHERE (UserID = @UserID);

    IF (NOT (@SUserID IS NULL))
    BEGIN
      IF (@OldLoginNameID <> @LoginNameID)
      BEGIN
        /* On doit faire une vérification s'il n'existe pas encore le LoginName de l'usager */
        IF (EXISTS (SELECT *
                    FROM Mo_User
                    WHERE (LoginNameID = @LoginNameID) ) )
          RETURN (-1)
      END
    END
    ELSE
    BEGIN
      /* On doit faire une vérification s'il n'existe pas encore le LoginName de l'usager */
      IF (EXISTS (SELECT *
                  FROM Mo_User
                  WHERE (LoginNameID = @LoginNameID) ) )
        RETURN (-1)
    END
  END

  BEGIN TRANSACTION

  /* Création de l'Mo_Human et l'Mo_Adresse  */
  EXECUTE @IUserID = IMo_Human
    @ConnectID,
    @UserID,
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
    @EMail;

  IF (@IUserID <> 0)
  BEGIN

    IF (@UserID = 0)
    BEGIN

      /* Création de l'utiliateur dans Mo_User */
      INSERT INTO Mo_User (
        UserID,
        LoginNameID,
        PassWordID,
        PassWordDate,
		PassWordEndDate,
        TerminatedDate,
        CodeID)
      VALUES (
        @IUserID,
        @LoginNameID,
        dbo.fn_Mo_Encrypt (@PassWordID),
        GetDate(),
		@PassWordEndDate,
        @TerminatedDate,
        @CodeID);

      IF (@@ERROR <> 0) SET @IUserID = 0;

      EXEC IMo_Log @ConnectID, 'Mo_User', @IUserID, 'I', '';

    END
    ELSE
    BEGIN
      /*
      SELECT
        @SHumanID = HumanID,
        @OldPassWordID = PassWordID,
        @PassWordDate = PassWordDate
      FROM Mo_User
      WHERE (HumanID = @IHumanID);
      */

      IF (@SUserID IS NULL)
      BEGIN
        /* Création de l'utiliateur dans Mo_User */
        INSERT INTO Mo_User (
          UserID,
          LoginNameID,
          PassWordID,
          PassWordDate,
		  PassWordEndDate,
          TerminatedDate,
          CodeID)
        VALUES (
          @IUserID,
          @LoginNameID,
          dbo.fn_Mo_Encrypt (@PassWordID),
          GetDate(),
		  @PassWordEndDate,
          @TerminatedDate,
          @CodeID);

        IF (@@ERROR <> 0) SET @IUserID = 0;

        EXEC IMo_Log @ConnectID, 'Mo_User', @IUserID, 'I', '';
      END
      ELSE
      BEGIN
        IF (@OldPassWordID <> dbo.fn_Mo_Encrypt (@PassWordID)) SET @PassWordDate = GetDate();

        /* Mise à jour des données de l'utilisateur */
        UPDATE Mo_User SET
          TerminatedDate = @TerminatedDate,
          LoginNameID = @LoginNameID,
          PassWordID = dbo.fn_Mo_Encrypt (@PassWordID),
          PassWordDate = @PassWordDate,
		  PassWordEndDate = @PassWordEndDate,
          CodeID = @CodeID
        WHERE (UserID = @IUserID);

        IF (@@ERROR <> 0) SET @IUserID = 0;

        EXEC IMo_Log @ConnectID, 'Mo_User', @IUserID, 'U', '';
      END
    END

  END

  IF (@IUserID <> 0)
    COMMIT TRANSACTION
  ELSE
    ROLLBACK TRANSACTION

  RETURN @IUserID;
END;

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[IMo_User] TO PUBLIC
    AS [dbo];

