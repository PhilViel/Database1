
/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 			:	SL_UN_City
Description 		:	Renvoi la liste des villes
Valeurs de retour	:	DataSet	

Notes :						2004-05-05	Dominic Létourneau	Migration de l'ancienne procedure selon les nouveaux standards
			ADX0001278	IA	2007-03-16	Alain Quirion		Ajout du StateID et StateName
*********************************************************************************/
CREATE PROCEDURE dbo.SL_UN_City
AS
BEGIN
	-- Retourne les dossiers de la table de villes
	SELECT
		I.CityID,
		I.CityName,
		CountryID = C.CountryID,
		CountryName = C.CountryName,
		StateID = ISNULL(S.StateID,0),
		StateName =ISNULL(S.StateName,'')
	FROM Mo_City I
	LEFT JOIN Mo_State S ON S.StateID = I.StateID
	LEFT JOIN Mo_Country C ON C.CountryID = I.CountryID
	ORDER BY I.CityName
END

