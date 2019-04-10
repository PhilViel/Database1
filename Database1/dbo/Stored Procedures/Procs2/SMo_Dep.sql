CREATE PROCEDURE SMo_Dep
 (@ConnectID            MoID,
  @DepID                MoID,
  @CompanyID            MoIDOption OUTPUT,
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
  @WattLine             MoPhoneExt OUTPUT,
  @OtherTel             MoPhoneExt OUTPUT,
  @Pager                MoPhone OUTPUT,
  @EMail                MoEmail OUTPUT)
AS
BEGIN

DECLARE
 -- @WattLine             MoPhoneExt,
  --@OtherTel             MoPhoneExt,
  @AdrID                MoIDOption,
  @AdrTypeID            MoAdrType;

  IF (@DepID <> 0)
  BEGIN
    SELECT
      @DepType = DepType,
      @Att = Att,
      @AdrID = AdrID,
      @CompanyID = CompanyID
    FROM Mo_Dep
    WHERE (DepID = @DepID);

    IF (@AdrID IS NULL) SET @AdrID = 0;

    IF (@CompanyID IS NULL) SET @CompanyID = 0;

  END
  ELSE
  BEGIN
    SET @AdrID = NULL;

    SET @CompanyID = 0;
  END

  IF (@Att IS NULL) SET @Att = '';

  SET @AdrTypeID = 'C';

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

  IF (@DepType IS NULL)
  BEGIN
    SET @DepType = 'U';

    RETURN (0);
  END
  ELSE
    RETURN @DepID;
END;

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SMo_Dep] TO PUBLIC
    AS [dbo];

