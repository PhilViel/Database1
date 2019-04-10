CREATE PROCEDURE SMo_Company
 (@ConnectID            MoID,
  @CompanyID            MoID,
  @CompanyName          MoCompanyName OUTPUT,
  @LangID               MoLang OUTPUT,
  @WebSite              MoEmail OUTPUT,
  @StateTaxNumber       MoDescOption OUTPUT,
  @CountryTaxNumber     MoDescOption OUTPUT,
  @EndBusiness          MoDateOption OUTPUT,
  @DepType              MoDep OUTPUT,
  @Att                  MoAdress OUTPUT,
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
  @WattLine	MoPhone output,
  @OtherTel	MoPhone output,
  @Pager                MoPhone OUTPUT,
  @EMail                MoEmail OUTPUT,
  @DepID                MoID OUTPUT)
AS
BEGIN

  IF NOT (@CompanyID IS NULL) AND (@CompanyID <> 0)
  BEGIN
    SET @DepID = (SELECT DepID
                  FROM Mo_Dep
                  WHERE (CompanyID = @CompanyID)
                    AND (DepType = @DepType))

    SELECT
      @CompanyName = CompanyName,
      @LangID = LangID,
      @WebSite = WebSite,
      @StateTaxNumber = StateTaxNumber,
      @CountryTaxNumber = CountryTaxNumber,
      @EndBusiness = EndBusiness
    FROM Mo_Company
    WHERE (CompanyID = @CompanyID);

    IF (@DepID IS NULL) SET @DepID = 0;

  END
  ELSE
    SET @DepID = 0;

  EXECUTE @DepID = SMo_Dep
    @ConnectID,
    @DepID,
    @CompanyID OUTPUT,
    @DepType OUTPUT,
    @Att OUTPUT,
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
    @WattLine	OUTPUT,
    @OtherTel	OUTPUT,
    @Pager OUTPUT,
    @EMail OUTPUT;

  IF (@LangID IS NULL) SET @LangID = 'U';

  IF (@WebSite IS NULL) SET @WebSite = '';

  IF (@StateTaxNumber IS NULL) SET @StateTaxNumber = '';

  IF (@CountryTaxNumber IS NULL) SET @CountryTaxNumber = '';

  EXECUTE SMo_IsDateNull @EndBusiness OUTPUT;

  IF (@CompanyName IS NULL)
  BEGIN

    SET @CompanyName = 'Unknow';

    RETURN (0);
  END
  ELSE
    RETURN @CompanyID;
END;

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SMo_Company] TO PUBLIC
    AS [dbo];

