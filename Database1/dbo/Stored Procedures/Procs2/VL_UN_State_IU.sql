
/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 			:	VL_UN_State_IU
Description 		:	Validation avant insertion d'une ville
Valeurs de retour	:	Dataset :
							vcErrorCode	CHAR(4)			Code d’erreur
							vcErrorText	VARCHAR(255)	Texte de l’erreur
							
							Code d’erreur	Texte de l’erreur
							IUS1			Cette province existe déjà pour ce pays
							IUS2			Code déjà existant pour ce pays
							IUS3			Impossible d’ajouter/éditer une province du canadienne

Notes :		ADX0001278	IA	2007-03-19	Alain Quirion		Création
*********************************************************************************/
CREATE PROCEDURE dbo.VL_UN_State_IU(
	@StateID INTEGER,			--	Identifiant de la province (<0 = Insertion)
	@StateName VARCHAR(100),	--	Nom de la province
	@StateCode VARCHAR(5),		--	Code de la province
	@StateTaxPct MONEY,			--  Pourcentage de taxe de la province	
	@CountryID CHAR(4))			--	Identifiant du pays		
AS
BEGIN
	DECLARE @tError TABLE(
		vcErrorCode VARCHAR(4),
		vcErrorText VARCHAR(255))

	IF EXISTS (
				SELECT *
				FROM Mo_State 
				WHERE StateName = @StateName
						AND CountryID = @CountryID
						AND StateID <> @StateID)
	BEGIN
			INSERT INTO @tError
			VALUES( 'IUS1', 
					'Cette province existe déjà pour ce pays.')
	END

	IF EXISTS (
				SELECT *
				FROM Mo_State 
				WHERE StateCode = @StateCode
						AND CountryID = @CountryID
						AND StateID <> @StateID)
	BEGIN
			INSERT INTO @tError
			VALUES( 'IUS2', 
					'Code déjà existant pour ce pays.')
	END	
	
	SELECT *
	FROM @tError 
END

