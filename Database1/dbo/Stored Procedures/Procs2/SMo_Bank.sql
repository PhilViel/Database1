CREATE PROCEDURE SMo_Bank
 (@ConnectID        MoID,
  @BankID           MoID,
  @BankTransit      MoDesc OUTPUT,
  @CompanyName      MoCompanyName OUTPUT,
  @LangID           MoLang OUTPUT,
  @WebSite          MoEmail OUTPUT,
  @StateTaxNumber   MoDescOption OUTPUT,
  @CountryTaxNumber MoDescOption OUTPUT,
  @EndBusiness      MoDateOption OUTPUT,
  @BankTypeID       MoID OUTPUT,
  @BankTypeName     MoCompanyName OUTPUT,
  @BankTypeCode     MoDesc OUTPUT,
  @DepType          MoDep OUTPUT,
  @Att              MoAdress OUTPUT,
  @InForce          MoDate OUTPUT,
  @Address          MoAdress OUTPUT,
  @City             MoCity OUTPUT,
  @StateName        MoFirstName OUTPUT,
  @CountryID        MoCountry OUTPUT,
  @ZipCode          MoZipCode OUTPUT,
  @Phone1           MoPhoneExt OUTPUT,
  @Phone2           MoPhoneExt OUTPUT,
  @Fax              MoPhone OUTPUT,
  @Mobile           MoPhone OUTPUT,
  @WattLine	    MoPhone output,
  @OtherTel	    MoPhone output,  
  @Pager            MoPhone OUTPUT,
  @EMail            MoEmail OUTPUT,
  @DepID            MoID OUTPUT)
AS
BEGIN
  SELECT
    @BankTypeID = BankTypeID,
    @BankTransit = BankTransit
  FROM Mo_Bank
  WHERE BankID = @BankID;

  SET @DepType = 'A';

  EXECUTE SMo_Company
    @ConnectID,
    @BankID,
    @CompanyName OUTPUT,
    @LangID OUTPUT,
    @WebSite OUTPUT,
    @StateTaxNumber OUTPUT,
    @CountryTaxNumber OUTPUT,
    @EndBusiness OUTPUT,
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
    @WattLine	output,
    @OtherTel	output,  
    @Pager OUTPUT,
    @EMail OUTPUT,
    @DepID OUTPUT;

  SELECT
    @BankTypeName = BankTypeName,
    @BankTypeCode = BankTypeCode
  FROM Mo_BankType
  WHERE (BankTypeID = @BankTypeID);
  
END;

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SMo_Bank] TO PUBLIC
    AS [dbo];

