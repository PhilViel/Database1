
/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 			:	SL_UN_CityMerged
Description 		:	Renvoi la liste des villes fusionnées
Valeurs de retour	:	Dataset :
						oldCityName		VARCHAR(100)	Nom de la ville fusionnée
						newCityID		INTEGER			Identifiant de la ville remplaçante
						newCityName		VARCHAR(75)		Nom de la ville remplaçante
						CountryID		CHAR(4)			Identifiant du pays
						StateID			INTEGER			Identifiant de la province
						StateName		VARCHAR(75)		Nom de la province

Notes :		ADX0001278	IA	2007-03-19	Alain Quirion		Création
*************************************************************************************************/
CREATE PROCEDURE dbo.SL_UN_CityMerged
AS
BEGIN
	SELECT
		oldCityName = F.OldCityName,				--Nom de la ville fusionnée
		newCityID = F.CityID,						--Identifiant de la ville remplaçante
		newCityName = C.CityName,					--Nom de la ville remplaçante
		CountryID = ISNULL(C.CountryID,'UNK'),		--Identifiant du pays
		StateID = ISNULL(S.StateID,0),				--Identifiant de la province
		StateName =ISNULL(S.StateName,'')			--Nom de la province						
	FROM Mo_CityFusion F
	JOIN Mo_City C ON C.CityID = F.CityID
	LEFT JOIN Mo_State S ON S.StateID = C.StateID
	ORDER BY F.OldCityName, ISNULL(S.StateName,''), ISNULL(C.CountryID,'UNK')
END

