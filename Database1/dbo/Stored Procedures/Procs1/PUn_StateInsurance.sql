
-- Optimisé version 26
CREATE PROCEDURE dbo.PUn_StateInsurance (
@ConnectID MoID,
@StartDate MoGetDate,
@EndDate MoGetDate)
AS
BEGIN
  SET @EndDate = @EndDate + 1;

  SELECT 
     SA.StateName,
     S.LastName + ', ' + S.FirstName AS SubscriberName,
     SA.Address,
     SA.City,
     dbo.fn_Mo_FormatZIP(SA.ZipCode, SA.CountryID) AS ZipCode,
     SA.Phone1,
     SUM(Ct.SubscInsur) AS SubscInsur,
     SUM(Ct.BenefInsur) AS BenefInsur,
     SUM(Ct.SubscInsur + Ct.BenefInsur) AS SubscANDBenefInsur
  FROM dbo.Un_Convention C
  JOIN dbo.Mo_Human S ON (S.HumanID = C.SubscriberID)
  JOIN dbo.Mo_Adr SA ON (SA.AdrID = S.AdrID)
  JOIN dbo.Un_Unit U ON (U.ConventionID = C.ConventionID)
  JOIN Un_Cotisation Ct ON (Ct.UnitID = U.UnitID)
  JOIN Un_Oper O ON (O.OperID = Ct.OperID)
  WHERE O.OperDate >= @StartDate
    AND O.OperDate < @EndDate
  GROUP BY 
    SA.Statename, 
    S.LastName, 
    S.FirstName, 
    SA.Address, 
    SA.City, 
    SA.ZipCode, 
    SA.CountryID, 
    SA.Phone1
  HAVING SUM(Ct.SubscInsur + Ct.BenefInsur) <> 0
  ORDER BY 
    SA.Statename, 
    S.LastName, 
    S.FirstName, 
    SA.Address, 
    SA.City, 
    SA.ZipCode, 
    SA.CountryID, 
    SA.Phone1;  

END;


