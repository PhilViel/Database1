
/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 			:	VL_UN_City_IU
Description 		:	Validation avant insertion d'une ville
Valeurs de retour	:	Dataset :
							vcErrorCode		CHAR(4)	Code d’erreur
							vcErrorText		VARCHAR(255)	Texte de l’erreur
							
							Code d’erreur	Texte de l’erreur
							IUC1			Cette ville existe déjà pour cette province et ce pays
							IUC2			Cette ville est présentement fusionnée dans cette province et ce pays.

Notes :		ADX0001278	IA	2007-03-16	Alain Quirion		Création
*********************************************************************************/
CREATE PROCEDURE dbo.VL_UN_City_IU(
	@CityID INTEGER,		--	Identifiant de la ville (<0 = Insertion)
	@CityName VARCHAR(100),	--	Nom de la ville	
	@CountryID CHAR(4),		--	Identifiant du pays
	@StateID INTEGER)		--	Identifiant de la province
AS
BEGIN
	DECLARE @tError TABLE(
		vcErrorCode VARCHAR(4),
		vcErrorText VARCHAR(255))

	IF EXISTS (
				SELECT *
				FROM Mo_City 
				WHERE CityName = @CityName
						AND CountryID = @CountryID
						AND ISNULL(StateID,0) = @StateID
						AND CityID <> @CityID)
	BEGIN
			INSERT INTO @tError
			VALUES( 'IUC1', 
					'Cette ville existe déjà dans cette province pour ce pays')
	END

	IF EXISTS (
				SELECT *
				FROM Mo_CityFusion CF
				JOIN Mo_City C ON C.CityID = CF.CityID
				WHERE CF.OldCityName = @CityName
						AND ISNULL(CF.StateID,0) = @StateID
						AND C.CountryID = @CountryID)
	BEGIN
			INSERT INTO @tError
			VALUES( 'IUC2', 
					'Cette ville est présentement fusionnée dans cette province et ce pays')
	END	

	SELECT *
	FROM @tError 
END

