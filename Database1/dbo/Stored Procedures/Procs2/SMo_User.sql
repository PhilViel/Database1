
CREATE PROCEDURE SMo_User
 (@ConnectID            MoID,
  @UserID               MoID,
  @TerminatedDate       MoDateOption OUTPUT,
  @LoginNameID          MoLoginName OUTPUT,
  @PassWordID           MoLoginName OUTPUT,
  @PassWordDate         MoDate OUTPUT,
  @CodeID               MoIDOption OUTPUT,
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
  @EMail                MoEmail OUTPUT,
  @CodeName             MoDescOption OUTPUT)
AS
BEGIN
  SET @CodeName = '';
  SELECT
    @TerminatedDate = TerminatedDate,
    @LoginNameID = LoginNameID,
    @PassWordID = dbo.fn_Mo_Decrypt (PassWordID),
    @PassWordDate = PassWordDate,
    @CodeID = CodeID
  FROM Mo_User
  WHERE (UserID = @UserID);

  IF (@LoginNameID IS NULL) SET @LoginNameID = '';

  IF (@PassWordID IS NULL) SET @PassWordID = '';

  --IF (@PassWordDate IS NULL) EXECUTE SMo_DateNull @PassWordDate OUTPUT;
  EXECUTE SMo_IsDateNull @PassWordDate OUTPUT;

  EXECUTE SMo_IsDateNull @TerminatedDate OUTPUT;

  IF (@CodeID IS NULL) SET @CodeID = 0;

  EXECUTE SMo_Human
    @ConnectID,
    @UserID,
    @FirstName OUTPUT,
    @OrigName OUTPUT,
    @Initial OUTPUT,
    @LastName OUTPUT,
    @BirthDate OUTPUT,
    @DeathDate OUTPUT,
    @SexID OUTPUT,
    @LangID OUTPUT,
    @CivilID OUTPUT,
    @SocialNumber OUTPUT,
    @ResidID OUTPUT,
    @DriverLicenseNo OUTPUT,
    @WebSite OUTPUT,
    @CompanyName OUTPUT,
    @CourtesyTitle OUTPUT,
    @UsingSocialNumber OUTPUT,
    @SharePersonalInfo OUTPUT,
    @MarketingMaterial OUTPUT,
    @IsCompany OUTPUT,
    @InForce OUTPUT,
    @Address OUTPUT,
    @City OUTPUT,
    @StateName OUTPUT,
    @CountryID OUTPUT,
    @ZipCode OUTPUT,
    @Phone1 OUTPUT,
    @Phone2 OUTPUT,
    @Fax OUTPUT,
    @Mobile OUTPUT,
    @WattLine OUTPUT,
    @OtherTel OUTPUT,
    @Pager OUTPUT,
    @EMail OUTPUT;
END;

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SMo_User] TO PUBLIC
    AS [dbo];

