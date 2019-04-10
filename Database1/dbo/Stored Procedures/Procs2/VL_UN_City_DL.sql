
/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 			:	VL_UN_City_DL
Description 		:	Validation avant suppression d'une ville
Valeurs de retour	:	Dataset :
								vcErrorCode	VARCHAR(4)	Code d’erreur
								vcErrorText	VARCHAR(255)	Texte de l’erreur

					Code d’erreur	Texte de l’erreur
					DLC1			Impossible de supprimer une ville utilisée dans une fusion

Notes :		ADX0001278	IA	2007-03-16	Alain Quirion		Création
*********************************************************************************/
CREATE PROCEDURE dbo.VL_UN_City_DL(
	@CityID INTEGER)		--	Identifiant de la ville (<0 = Insertion)
AS
BEGIN
	DECLARE @tError TABLE(
		vcErrorCode VARCHAR(4),
		vcErrorText VARCHAR(255))

	IF EXISTS (
				SELECT *
				FROM Mo_CityFusion 
				WHERE CityID = @CityID)
	BEGIN
			INSERT INTO @tError
			VALUES( 'DLC1', 
					'Impossible de supprimer une ville utilisée dans une fusion.')
	END	

	SELECT *
	FROM @tError 
END

