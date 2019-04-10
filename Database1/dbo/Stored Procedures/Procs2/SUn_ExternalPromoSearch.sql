

-- Optimisé version 26
--Voir Upd_Mo_9999-99_Un_9999-99.sql
CREATE PROC SUn_ExternalPromoSearch (
@ConnectID MoID)
AS
BEGIN
  SELECT EP.ExternalPromoID,CO.CompanyName
  FROM Un_ExternalPromo EP
  JOIN Mo_Company CO ON (CO.CompanyID = EP.ExternalPromoID)
  ORDER BY CO.CompanyName
  RETURN(1);
END;

