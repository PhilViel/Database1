CREATE procEDURE [dbo].[SMo_Adr]
 (@ConnectID            MoID,
  @AdrID                MoIDOption,
  @SourceID             MoIDOption,
  @AdrTypeID            MoAdrType)
AS
BEGIN

  IF NOT (@AdrID IS NULL) AND (@AdrID <> 0)
    SELECT
      AdrID,
      AdrTypeID,
      InForce,
      SourceID,
      Address,
      City,
      StateName,
      CountryID,
      ZipCode,
      Phone1,
      Phone2,
      Fax,
      Mobile,
      WattLine,
      OtherTel,
      Pager,
      EMail
    FROM dbo.Mo_Adr 
    WHERE (AdrID = @AdrID);
  ELSE
    SELECT
     AdrID,
      AdrTypeID,
      InForce,
      SourceID,
      Address,
      City,
      StateName,
      CountryID,
      ZipCode,
      Phone1,
      Phone2,
      Fax,
      Mobile,
      WattLine,
      OtherTel,
      Pager,
      EMail
    FROM dbo.Mo_Adr 
    WHERE (SourceID = @SourceID)
      AND (AdrTypeID = @AdrTypeID)

END;



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SMo_Adr] TO PUBLIC
    AS [dbo];

