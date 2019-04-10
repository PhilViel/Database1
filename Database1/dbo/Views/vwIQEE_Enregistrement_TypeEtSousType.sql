CREATE VIEW dbo.vwIQEE_Enregistrement_TypeEtSousType
AS
    SELECT T.tiID_Type_Enregistrement, S.iID_Sous_Type, T.cCode_Type_Enregistrement, S.cCode_Sous_Type, 
           cCode_Type_SousType = T.cCode_Type_Enregistrement + CASE WHEN S.iID_Sous_Type IS NULL THEN '' ELSE '-' + S.cCode_Sous_Type END,
           T.vcDescription as TypeDescription, S.vcDescription as SousTypeDescription
      FROM dbo.tblIQEE_TypesEnregistrement T
           LEFT JOIN dbo.tblIQEE_SousTypeEnregistrement S ON S.tiID_Type_Enregistrement = T.tiID_Type_Enregistrement
