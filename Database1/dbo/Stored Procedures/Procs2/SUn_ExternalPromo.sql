

-- Optimisé version 26
CREATE PROC SUn_ExternalPromo (
@ConnectID MoID,
@ExternalPromoID MoID,
@CompanyName MoCompanyName OUTPUT,
@LangID MoLang OUTPUT,
@WebSite MoEmail OUTPUT,
@StateTaxNumber MoDescOption OUTPUT,
@CountryTaxNumber MoDescOption OUTPUT,
@EndBusiness MoDateOption OUTPUT,
@DepType MoDep OUTPUT,
@Att MoAdress OUTPUT,
@InForce MoDateOption OUTPUT,
@Address MoAdress OUTPUT,
@City MoCity OUTPUT,
@StateName MoDescOption OUTPUT,
@CountryID MoCountry OUTPUT,
@ZipCode MoZipCode OUTPUT,
@Phone1 MoPhoneExt OUTPUT,
@Phone2 MoPhoneExt OUTPUT,
@Fax MoPhone OUTPUT,
@Mobile MoPhone OUTPUT,
@WattLine MoPhone OUTPUT,
@OtherTel MoPhone OUTPUT,
@Pager MoPhone OUTPUT,
@EMail MoEmail OUTPUT,
@DepID MoID OUTPUT)
AS
BEGIN

  SET @DepType = 'U';

  EXECUTE @ExternalPromoID = SMo_Company
    @ConnectID,
    @ExternalPromoID,
    @CompanyName = @CompanyName OUTPUT,
    @LangID = @LangID OUTPUT,
    @WebSite = @WebSite OUTPUT,
    @StateTaxNumber = @StateTaxNumber OUTPUT,
    @CountryTaxNumber = @CountryTaxNumber OUTPUT,
    @EndBusiness = @EndBusiness OUTPUT,
    @DepType = @DepType OUTPUT,
    @Att = @Att OUTPUT,
    @InForce = @InForce OUTPUT,
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
    @OtherTel = 	@OtherTel OUTPUT,
    @Pager = @Pager OUTPUT,
    @EMail = @EMail OUTPUT,
    @DepID = @DepID OUTPUT;

  RETURN @ExternalPromoID

END

