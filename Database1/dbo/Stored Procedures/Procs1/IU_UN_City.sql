

/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 			:	IU_UN_City
Description 		:	Insertion d'une ville
Valeurs de retour	:	@ReturnValue :
							> 0 : [Réussite]
							<= 0 : [Échec].

Notes :		ADX0001278	IA	2007-03-16	Alain Quirion		Création
							2014-04-30	Maxime Martel		Modification dans tblGENE_Adresse au lieu de Mo_Adr
							2015-02-24	Pierre-Luc Simard	Correction dans le nom du trigger
**************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_City](
	@CityID INTEGER,		--	Identifiant de la ville (<0 = Insertion)
	@CityName VARCHAR(100),	--	Nom de la ville	
	@CountryID CHAR(4),		--	Identifiant du pays
	@StateID INTEGER)		--	Identifiant de la province
AS
BEGIN
	DECLARE @iReturn INTEGER

	DECLARE @oldCityName VARCHAR(100),
			@StateName VARCHAR(100),
			@oldStateName VARCHAR(100),
			@oldCountryID CHAR(4)
	
	SET @iReturn = 1

	IF @StateID = 0
		SET @StateID = NULL

	IF @CityID <= 0
	BEGIN
		INSERT INTO Mo_City(CityName, CountryID, StateID)
		VALUES(@CityName, @CountryID, @StateID)

		IF @@ERROR <> 0
			SET @iReturn = -1
		ELSE 
			SET @iReturn = SCOPE_IDENTITY()	
	END	
	ELSE
	BEGIN		
		SELECT 
				@oldCityName = C.CityName,
				@oldStateName = ISNULL(S.StateName,''),
				@oldCountryID = C.CountryID
		FROM Mo_City C
		LEFT JOIN Mo_State S ON S.StateID = C.StateID
		WHERE CityID = @CityID

		SELECT @StateName = StateName
		FROM Mo_State
		WHERE StateID = @StateID

		--MIse à jour de la ville
		UPDATE Mo_City
		SET CityName = @CityName, 
			CountryID = @CountryID,
			StateID = @StateID
		WHERE CityID = @CityID

		IF @@ERROR <> 0
			SET @iReturn = -2
		ELSE
			SET @iReturn = @CityID

		IF @iReturn > 0
			AND (@oldCountryID <> @CountryID
					OR @oldStateName <> @StateName
					OR @oldCityName <> @CityName) --Seulement si le pays ou la province ou la ville a été modifiée
		BEGIN
			IF object_id('tempdb..#DisableTrigger') is null
				CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))
				INSERT INTO #DisableTrigger VALUES('TtblGENE_Adresse')

		
			--Mise à jour des adresses actuelles modifiés
			UPDATE tblGENE_Adresse
			SET vcVille = @CityName
			FROM tblGENE_Adresse A
			WHERE iID_Ville = @CityID
					
						
			Delete #DisableTrigger where vcTriggerName = 'TtblGENE_Adresse'

			UPDATE tblGENE_AdresseHistorique
			SET 
				iID_Ville = NULL
			FROM tblGENE_AdresseHistorique A
			WHERE iID_Ville = @CityID

			IF @@ERROR <> 0
				SET @iReturn = -3
		END
	END

	RETURN @iReturn
END

