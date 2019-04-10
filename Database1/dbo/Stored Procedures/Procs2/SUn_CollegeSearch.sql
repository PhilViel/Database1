

-- Optimisé version 26
CREATE PROC SUn_CollegeSearch (
@SearchType MoOptionCode,
@Search MoDesc)
AS
BEGIN
  IF @SearchType = 'ALL'
  BEGIN
    SELECT
      ISNULL(C.CollegeID, 0) AS CollegeID,
      ISNULL(Co.CompanyName, '') AS CollegeName,
      ISNULL(C.CollegeCode, '') AS CollegeCode,
      ISNULL(C.CollegeTypeID, '') AS CollegeTypeID
    FROM Un_College C
      JOIN Mo_Company Co ON (Co.CompanyID = C.CollegeID)        
    WHERE (Co.CompanyName LIKE @Search)
    ORDER BY Co.CompanyName, C.CollegeCode, C.CollegeTypeID;
  END
  ELSE 
    BEGIN
    SELECT
      ISNULL(C.CollegeID, 0) AS CollegeID,
      ISNULL(Co.CompanyName, '') AS CollegeName,
      ISNULL(C.CollegeCode, '') AS CollegeCode,
      ISNULL(C.CollegeTypeID, '') AS CollegeTypeID
    FROM Un_College C
      JOIN Mo_Company Co ON (Co.CompanyID = C.CollegeID)        
    WHERE (Co.CompanyName LIKE @Search)
       AND (C.CollegeTypeID = @SearchType)
    ORDER BY Co.CompanyName, C.CollegeCode;
    END
  Return(1);
END;

