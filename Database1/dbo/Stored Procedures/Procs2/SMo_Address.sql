
CREATE PROCEDURE [dbo].[SMo_Address]
 (@ConnectID            MoID,
  @AdrID                MoIDOption,
  @InForce              MoDateOption OUTPUT,
  @AdrTypeID            MoAdrType OUTPUT,
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
  /* Sélection d'une adresse */
  IF NOT (@AdrID IS NULL) AND (@AdrID <> 0)
  BEGIN

    SELECT
      @InForce = InForce,
      @AdrTypeID = AdrTypeID,
      @Address = Address,
      @City = City,
      @StateName = StateName,
      @CountryID = CountryID,
      @ZipCode = ZipCode,
      @Phone1 = Phone1,
      @Phone2 = Phone2,
      @Fax = Fax,
      @Mobile = Mobile,
      @WattLine = WattLine,
      @OtherTel = OtherTel,
      @Pager = Pager,
      @EMail = EMail
    FROM dbo.Mo_Adr 
    WHERE (AdrID = @AdrID);

  END

  IF (@AdrTypeID IS NULL) SET @AdrTypeID = 'H';

  IF (@Address IS NULL) SET @Address = '';

  IF (@City IS NULL) SET @City = '';

  IF (@StateName IS NULL) SET @StateName = '';

  IF (@CountryID IS NULL) SET @CountryID = 'UNK';

  IF (@ZipCode IS NULL) SET @ZipCode = '';

  IF (@Phone1 IS NULL) SET @Phone1 = '';

  IF (@Phone2 IS NULL) SET @Phone2 = '';

  IF (@Fax IS NULL) SET @Fax = '';

  IF (@Mobile IS NULL) SET @Mobile = '';

  IF (@Pager IS NULL) SET @Pager = '';

  IF (@EMail IS NULL) SET @EMail = '';

  IF (@InForce IS NULL)
  BEGIN

    --EXECUTE SMo_DateNull @InForce OUTPUT;
    EXECUTE SMo_IsDateNull @InForce OUTPUT;

    RETURN (0);

  END
  ELSE
    RETURN @AdrID;
END;



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SMo_Address] TO PUBLIC
    AS [dbo];

