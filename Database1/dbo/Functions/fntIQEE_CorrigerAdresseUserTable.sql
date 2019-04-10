CREATE FUNCTION [dbo].[fntIQEE_CorrigerAdresseUserTable](@pTableAdresse dbo.UDT_tblAdresse READONLY)
RETURNS @TB_Result TABLE (
    iID_Source int NOT NULL,
    iID_Adresse int NOT NULL, 
    NoCivique varchar(20),
    Appartement varchar(10),
    NomRue varchar(100),
    ID_TypeBoite int,
    Boite varchar(50)
) AS 
BEGIN
    DECLARE @TmpAdresse dbo.UDT_tblAdresse

    INSERT INTO @TmpAdresse (
        iID_Source,
        iID_Adresse, 
        vcNoCivique,
        vcAppartement,
        vcNomRue,
        iID_TypeBoite,
        vcBoite
    )
    SELECT
        TB.iiD_Source, 
        TB.iID_Adresse, 
        NoCivique = CASE WHEN A.iID_Adresse Is Not Null THEN A.NoCivique ELSE TB.vcNoCivique END,
        Appartement = CASE WHEN A.iID_Adresse Is Not Null THEN A.Appartement ELSE TB.vcAppartement END,
        NomRue = CASE WHEN A.iID_Adresse Is Not Null THEN A.NomRue ELSE TB.vcNomRue END,
        ID_TypeBoite = CASE WHEN A.iID_Adresse Is Not Null THEN A.ID_TypeBoite ELSE TB.iID_TypeBoite END,
        Boite = CASE WHEN A.iID_Adresse Is Not Null THEN A.Boite ELSE TB.vcBoite END
    FROM
        @pTableAdresse TB 
        LEFT JOIN dbo.fntIQEE_ExtraireNoCiviqueUserTable(@pTableAdresse) A 
             ON A.iid_Source = TB.iID_Source And  A.iID_Adresse = TB.iID_Adresse

    INSERT INTO @TB_Result (
        iID_Source,
        iID_Adresse, 
        NoCivique,
        Appartement,
        NomRue,
        ID_TypeBoite,
        Boite
    )
    SELECT
        TB.iiD_Source, 
        TB.iID_Adresse, 
        NoCivique = CASE WHEN A.iID_Adresse Is Not Null THEN A.NoCivique ELSE TB.vcNoCivique END,
        Appartement = CASE WHEN A.iID_Adresse Is Not Null THEN A.Appartement ELSE TB.vcAppartement END,
        NomRue = CASE WHEN A.iID_Adresse Is Not Null THEN A.NomRue ELSE TB.vcNomRue END,
        ID_TypeBoite = CASE WHEN A.iID_Adresse Is Not Null THEN A.ID_TypeBoite ELSE TB.iID_TypeBoite END,
        Boite = CASE WHEN A.iID_Adresse Is Not Null THEN A.Boite ELSE TB.vcBoite END
    FROM
        @TmpAdresse TB 
        LEFT JOIN dbo.fntIQEE_ExtraireNoUniteUserTable(@TmpAdresse) A 
             ON A.iid_Source = TB.iID_Source And  A.iID_Adresse = TB.iID_Adresse

    RETURN
END
