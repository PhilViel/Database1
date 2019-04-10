
CREATE PROCEDURE [dbo].[SMo_Human]
 (@ConnectID            MoID,
  @HumanID              MoID,
  @FirstName            MoFirstName OUTPUT,
  @OrigName             MoDescOption OUTPUT,
  @Initial              MoInitial OUTPUT,
  @LastName             MoLastName OUTPUT,
  @BirthDate            MoDateOption OUTPUT,
  @DeathDate            MoDateOption OUTPUT,
  @SexID                MoSex OUTPUT,
  @LangID               MoLang OUTPUT,
  @CivilID              MoCivil OUTPUT,
  @SocialNumber         MoDescOption OUTPUT,
  @ResidID              MoCountry OUTPUT,
  @DriverLicenseNo      MoDescOption OUTPUT,
  @WebSite              MoDescOption OUTPUT,
  @CompanyName          MoDescOption OUTPUT,
  @CourtesyTitle        MoFirstNameOption OUTPUT,
  @UsingSocialNumber    MoBitTrue OUTPUT,
  @SharePersonalInfo    MoBitTrue OUTPUT,
  @MarketingMaterial    MoBitTrue OUTPUT,
  @IsCompany            MoBitFalse OUTPUT,
  @InForce              MoDateOption OUTPUT,
  @Address              MoAdress OUTPUT,
  @City                 MoCity OUTPUT,
  @StateName            MoDescOption OUTPUT,
  @CountryID            MoCountry OUTPUT,
  @ZipCode              MoZipCode OUTPUT,
  @Phone1               MoPhoneExt OUTPUT,
  @Phone2               MoPhoneExt OUTPUT,
  @Fax                  MoPhone OUTPUT,
  @Mobile               MoPhone OUTPUT,
  @WattLine             MoPhoneExt OUTPUT,
  @OtherTel             MoPhoneExt OUTPUT,
  @Pager                MoPhone OUTPUT,
  @EMail                MoEmail OUTPUT)
AS
BEGIN

DECLARE
  @AdrID                MoIDOption,
  @AdrTypeID            MoAdrType;

  IF (@HumanID <> 0)
  BEGIN
    SELECT
      @FirstName = FirstName,
      @OrigName = OrigName,
      @Initial = Initial,
      @LastName = LastName,
      @BirthDate = BirthDate,
      @DeathDate = DeathDate,
      @SexID = SexID,
      @LangID = LangID,
      @CivilID = CivilID,
      @ResidID = ResidID,
      @SocialNumber = SocialNumber,
      @ResidID = ResidID,
      @DriverLicenseNo = DriverLicenseNo,
      @WebSite = WebSite,
      @CompanyName = CompanyName,
      @CourtesyTitle = CourtesyTitle,
      @AdrID = AdrID,
      @UsingSocialNumber = UsingSocialNumber,
      @SharePersonalInfo = SharePersonalInfo,
      @MarketingMaterial = MarketingMaterial,
      @IsCompany = IsCompany
    FROM dbo.Mo_Human 
    WHERE (HumanID = @HumanID);
  END
  ELSE
    SET @AdrID = 0;

  IF (@FirstName IS NULL) SET @FirstName = 'Unknow';

  IF (@OrigName IS NULL) SET @OrigName = '';

  IF (@Initial IS NULL) SET @Initial = '';

  IF (@LastName IS NULL) SET @LastName = 'Unknow';

  --IF (@BirthDate IS NULL) EXECUTE SMo_DateNull @BirthDate OUTPUT;
  EXECUTE SMo_IsDateNull @BirthDate OUTPUT;

  --IF (@DeathDate IS NULL) EXECUTE SMo_DateNull @DeathDate OUTPUT;
  EXECUTE SMo_IsDateNull @DeathDate OUTPUT;

  IF (@SexID IS NULL) SET @SexID = 'U';

  IF (@LangID IS NULL) SET @LangID = 'U';

  IF (@CivilID IS NULL) SET @CivilID = 'U';

  IF (@SocialNumber IS NULL) SET @SocialNumber = '';

  IF (@ResidID IS NULL) SET @ResidID = 'UNK';

  SET @AdrTypeID = 'H';

  EXECUTE SMo_Address
    @ConnectID,
    @AdrID,
    @InForce = @InForce OUTPUT,
    @AdrTypeID = @AdrTypeID OUTPUT,
    @Address = @Address OUTPUT,
    @City = @City OUTPUT,
    @StateName = @StateName OUTPUT,
    @CountryID = @CountryID OUTPUT,
    @ZipCode = @ZipCode OUTPUT,
    @Phone1 = @Phone1 OUTPUT,
    @Phone2 = @Phone2 OUTPUT,
    @Fax = @Fax OUTPUT,
    @Mobile = @Mobile OUTPUT,
    @WattLine = @WattLine OUTPUT,
    @OtherTel = @OtherTel OUTPUT,
    @Pager = @Pager OUTPUT,
    @EMail = @EMail OUTPUT;

  IF (@FirstName IS NULL)
  BEGIN
    SET @FirstName = 'Unknow';

    RETURN (0);
  END
  ELSE
    RETURN @HumanID;
END;



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SMo_Human] TO PUBLIC
    AS [dbo];

