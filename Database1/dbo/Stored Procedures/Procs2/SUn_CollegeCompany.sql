

-- Optimisé version 26
CREATE PROC SUn_CollegeCompany (
@ConnectID MoID, 
@CollegeID MoID,
@CollegeTypeID MoDesc OUTPUT,
@EligibilityConditionID MoDesc OUTPUT,
@CollegeCode MoDesc OUTPUT,
@CompanyName MoCompanyName OUTPUT,
@LangID MoLang OUTPUT,
@WebSite MoEmail OUTPUT,
@StateTaxNumber MoDescOption OUTPUT,
@CountryTaxNumber MoDescOption OUTPUT,
@EndBusiness MoDateOption OUTPUT, 
@DepType MoDep OUTPUT,
@Att MoAdress OUTPUT,
@InForce MoDate OUTPUT,
@Address MoAdress OUTPUT,
@City MoCity OUTPUT,
@StateName MoFirstName OUTPUT,
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

  SELECT
    @CollegeTypeID = CollegeTypeID,
    @EligibilityConditionID = EligibilityConditionID,
    @CollegeCode = CollegeCode
  FROM Un_College
  WHERE (CollegeID = @CollegeID);

  SET @DepType = 'A';

  EXECUTE SMo_Company
    @ConnectID,
    @CollegeID,
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
    @WattLine OUTPUT,
    @OtherTel OUTPUT,
    @Pager OUTPUT,
    @EMail OUTPUT,
    @DepID OUTPUT;

END;

