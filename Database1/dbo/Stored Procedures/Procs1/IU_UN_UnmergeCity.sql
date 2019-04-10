


/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 			:	IU_UN_UnMergeCity
Description 		:	Défusion des villes
Valeurs de retour	:	@ReturnValue :
							> 0 : [Réussite]
							<= 0 : [Échec].

Notes :		ADX0001278	IA	2007-03-19	Alain Quirion		Création
							2008-09-29	Pierre-Luc Simard	Correction du problème de suppression lorsque la province était NULL
															La province et le pays envoyés en paramètre sont ceux de la ville remplaçante
*************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_UnmergeCity](
	@oldCityName VARCHAR(100),		--Nom de la ville à fusionnée
	@newCityID INTEGER,				--Identifiant de la ville
	@CountryID CHAR(4),				--Identifiant du pays
	@StateID INTEGER)				--Identifiant de la province

AS
BEGIN
	DECLARE @iResult INTEGER
		
	SET @iResult = 1

	DELETE Mo_CityFusion
	FROM Mo_CityFusion
	JOIN Mo_City C ON C.CityID = Mo_CityFusion.CityID 
	WHERE OldCityName = @oldCityName
			AND Mo_CityFusion.CityID = @newCityID
			AND ISNULL(C.StateID,0) = ISNULL(@StateID,0)
			AND C.CountryID = @CountryID
	
	IF @@ERROR <> 0
		SET @iResult = -1	

	RETURN @iResult	
END


