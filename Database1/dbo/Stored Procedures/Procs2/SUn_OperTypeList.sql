

-- Optimisé version 26
CREATE PROC SUn_OperTypeList (
@ConnectID MoID)
AS 
BEGIN
  SELECT OperTypeID,
         OperTypeDesc
  FROM Un_OperType
END;

