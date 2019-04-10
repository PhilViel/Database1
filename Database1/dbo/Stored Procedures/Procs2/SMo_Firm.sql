CREATE PROCEDURE SMo_Firm
 (@ConnectID            MoID,
  @FirmID               MoID,
  @FirmStatusID         MoFirmStatus OUTPUT,
  @MonthlyTarget        MoMoney OUTPUT,
  @FirmName          	MoCompanyName OUTPUT,
  @LangID               MoLang OUTPUT,
  @WebSite              MoEmail OUTPUT,
  @StateTaxNumber       MoDescOption OUTPUT,
  @CountryTaxNumber     MoDescOption OUTPUT,
  @EndBusiness          MoDateOption OUTPUT,
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
  @WattLine             MoPhone OUTPUT,
  @OtherTel             MoPhone OUTPUT,
  @Pager                MoPhone OUTPUT,
  @EMail                MoEmail OUTPUT,
  @DepID                MoID OUTPUT)
AS
BEGIN

DECLARE
  @IFirmID              MoIDOption,
  @DepType              MoDep;

  SELECT
    @IFirmID = FirmID,
    @FirmStatusID = FirmStatusID,
    @MonthlyTarget = MonthlyTarget
  FROM Mo_Firm
  WHERE (FirmID = @FirmID);

  IF (@IFirmID IS NULL) SET @FirmID = 0;

  IF (@MonthlyTarget IS NULL) SET @MonthlyTarget = 0;

  SET @DepType = 'A';

  EXECUTE SMo_Company
    @ConnectID,
    @CompanyID   = @FirmID,
    @CompanyName = @FirmName OUTPUT,
    @LangID  = @LangID  OUTPUT,
    @WebSite = @WebSite OUTPUT,
    @StateTaxNumber   = @StateTaxNumber   OUTPUT,
    @CountryTaxNumber = @CountryTaxNumber OUTPUT,
    @EndBusiness = @EndBusiness OUTPUT,
    @DepType = @DepType OUTPUT,
    @Att     = @Att     OUTPUT,
    @InForce = @InForce OUTPUT,
    @Address = @Address OUTPUT,
    @City    = @City    OUTPUT,
    @StateName = @StateName OUTPUT,
    @CountryID = @CountryID OUTPUT,
    @ZipCode = @ZipCode OUTPUT,
    @Phone1  = @Phone1  OUTPUT,
    @Phone2  = @Phone2  OUTPUT,
    @Fax     = @Fax     OUTPUT,
    @Mobile  = @Mobile  OUTPUT,
    @WattLine= @WattLine OUTPUT,
    @OtherTel= @OtherTel OUTPUT,
    @Pager   = @Pager   OUTPUT,
    @EMail   = @EMail   OUTPUT,
    @DepID   = @DepID   OUTPUT;

  RETURN @FirmID;
END;
