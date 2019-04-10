/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 			:	SL_UN_CityNotMergedNotExists
Description 		:	Renvoi la liste des villes non fusionnée et non existantes
Valeurs de retour	:	Dataset :
							CityName	VARCHAR(75)	Nom de la ville saisie par l’usager
							CountryID	CHAR(4)		Identifiant du pays
							StateID		INTEGER		Identifiant de la province
							StateName	VARCHAR(75)	Nom de la province

Notes :		ADX0001278	IA	2007-03-19	Alain Quirion		Création
*************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_CityNotMergedNotExists]
AS
BEGIN
	SELECT DISTINCT
		CityName = ISNULL(A.City,''),				--Nom de la ville saisie par l’usager
		CountryID = ISNULL(A.CountryID,'UNK '),		--Identifiant du pays
		StateID = ISNULL(S.StateID,0),				--Identifiant de la province
		StateName = ISNULL(A.StateName,'')			--Nom de la province
	FROM dbo.Mo_Adr A	
	LEFT JOIN Mo_State S ON S.StateName = A.StateName
	LEFT JOIN Mo_City C ON C.CityName = A.City
	LEFT JOIN Mo_CityFusion F ON F.OldCityName = A.City
							AND ISNULL(F.StateID,-1) = ISNULL(S.StateID,-1)
	LEFT JOIN Mo_City C2 ON C2.CityID = F.CityID
							AND C2.CountryID = A.CountryID	
	WHERE C.CityName IS NULL	
			AND C2.CityID IS NULL
			--AND ISNULL(A.City,'') <> ''
	ORDER BY ISNULL(A.City,''), ISNULL(A.StateName,''), ISNULL(A.CountryID,'UNK ')
END


