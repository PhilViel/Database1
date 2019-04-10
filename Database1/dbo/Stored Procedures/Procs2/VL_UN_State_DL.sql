/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 			:	VL_UN_State_DL
Description 		:	Validation avant suppression d'une ville
Valeurs de retour	:	Dataset :
								vcErrorCode	CHAR(4)	Code d’erreur
								vcErrorText	VARCHAR(255)	Texte de l’erreur

					Code d’erreur	Texte de l’erreur
					DLS1			Impossible de supprimer une province canadienne
					DLS2			Impossible de supprimer une province utilisé par un souscripteur
					DLS3			Impossible de supprimer une province liée à une ville utilisée dans une fusion

Notes :		ADX0001278	IA	2007-03-16	Alain Quirion		Création
*********************************************************************************/
CREATE PROCEDURE dbo.VL_UN_State_DL(
	@StateID INTEGER)		--	Identifiant de la province
AS
BEGIN
	DECLARE @tError TABLE(
		vcErrorCode VARCHAR(4),
		vcErrorText VARCHAR(255))

	IF EXISTS (
				SELECT *
				FROM Mo_State 
				WHERE StateID = @StateID
						AND CountryID = 'CAN ')
	BEGIN
			INSERT INTO @tError
			VALUES( 'DLS1', 
					'Impossible de supprimer une province du Canada')
	END	

	IF EXISTS (
				SELECT *
				FROM dbo.Un_Subscriber 
				WHERE StateID = @StateID)
	BEGIN
			INSERT INTO @tError
			VALUES( 'DLS2', 
					'Impossible de supprimer une province utilisée par un souscripteur')
	END	

	IF EXISTS (
				SELECT *
				FROM Mo_CityFusion 
				WHERE StateID = @StateID)
	BEGIN
			INSERT INTO @tError
			VALUES( 'DLS3', 
					'Impossible de supprimer une province liée à une ville utilisée dans une fusion')
	END	

	SELECT *
	FROM @tError 
END


