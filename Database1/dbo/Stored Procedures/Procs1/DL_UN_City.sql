
/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 			:	DL_UN_City
Description 		:	Suppression d'une ville
Valeurs de retour	:	@ReturnValue :
							> 0 : [Réussite]
							<= 0 : [Échec].

Notes :		ADX0001278	IA	2007-03-16	Alain Quirion		Création
*********************************************************************************/
CREATE PROCEDURE dbo.DL_UN_City(
	@CityID INTEGER)		--	Identifiant de la ville (<0 = Insertion)
AS
BEGIN
	DECLARE @iReturn INTEGER
	
	SET @iReturn = 1

	DELETE
	FROM Mo_City
	WHERE CityID = @CityID

	IF @@ERROR <> 0
		SET @iReturn = -1

	RETURN @iReturn
END

