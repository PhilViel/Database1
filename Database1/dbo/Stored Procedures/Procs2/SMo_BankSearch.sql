CREATE PROCEDURE SMo_BankSearch
 (@SearchType              MoOptionCode,
  @Search                  MoDesc)
AS
BEGIN

  SELECT
    B.BankID,
    C.CompanyName AS BankName,
    B.BankTransit,
    T.BankTypeName,
    T.BankTypeCode
  FROM Mo_Bank B
    JOIN Mo_Company C ON (C.CompanyID = B.BankID)
    JOIN Mo_BankType T ON (T.BankTypeID = B.BankTypeID)
  WHERE
    ( ( (@SearchType = 'BNa') AND (C.CompanyName LIKE @Search) ) OR
      ( (@SearchType = 'Tst') AND (B.BankTransit LIKE @Search) ) OR
      ( (@SearchType = 'BTN') AND (T.BankTypeName LIKE @Search) ) OR
      ( (@SearchType = 'BTC') AND (T.BankTypeCode LIKE @Search) ) )
  ORDER  BY CASE @SearchType
               WHEN 'BNa' THEN C.CompanyName
               WHEN 'Tst' THEN B.BankTransit
               WHEN 'BTN' THEN T.BankTypeName
               WHEN 'BTC' THEN T.BankTypeCode
             END
  --ORDER BY BankName, BankTransit, BankTypeName, BankTypeCode;

  /*
  IF @SearchType = 'BNa'
  BEGIN
    SELECT
      ISNULL(BankID, 0) AS BankID,
      ISNULL(BankName, '') AS BankName,
      ISNULL(BankTransit, '') AS BankTransit,
      ISNULL(BankTypeName, '') AS BankTypeName,
      ISNULL(BankTypeCode, '') AS BankTypeCode
    FROM VMo_Bank
    WHERE (BankName LIKE @Search)
    ORDER BY BankName, BankTransit, BankTypeName, BankTypeCode;
  END
  ELSE IF @SearchType = 'Tst'
    BEGIN
      SELECT
        ISNULL(BankID, 0) AS BankID,
        ISNULL(BankName, '') AS BankName,
        ISNULL(BankTransit, '') AS BankTransit,
        ISNULL(BankTypeName, '') AS BankTypeName,
        ISNULL(BankTypeCode, '') AS BankTypeCode
      FROM VMo_Bank
      WHERE (BankTransit LIKE @Search)
      ORDER BY BankTransit, BankName, BankTypeName, BankTypeCode;
    END
    ELSE IF @SearchType = 'BTN'
      BEGIN
        SELECT
          ISNULL(BankID, 0) AS BankID,
          ISNULL(BankName, '') AS BankName,
          ISNULL(BankTransit, '') AS BankTransit,
          ISNULL(BankTypeName, '') AS BankTypeName,
          ISNULL(BankTypeCode, '') AS BankTypeCode
        FROM VMo_Bank
        WHERE (BankTypeName LIKE @Search)
        ORDER BY BankTypeName, BankTypeCode, BankName, BankTransit;
      END
      ELSE IF @SearchType = 'BTC'
        BEGIN
          SELECT
            ISNULL(BankID, 0) AS BankID,
            ISNULL(BankName, '') AS BankName,
            ISNULL(BankTransit, '') AS BankTransit,
            ISNULL(BankTypeName, '') AS BankTypeName,
            ISNULL(BankTypeCode, '') AS BankTypeCode
          FROM VMo_Bank
          WHERE (BankTypeCode LIKE @Search)
          ORDER BY BankTypeCode, BankTypeName, BankName, BankTransit;
        END;
  */
  Return(1);
END;

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SMo_BankSearch] TO PUBLIC
    AS [dbo];

