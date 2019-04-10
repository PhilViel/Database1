


/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 			:	IU_UN_State
Description 		:	Insertion d'une province
Valeurs de retour	:	@ReturnValue :
							> 0 : [Réussite]
							<= 0 : [Échec].

Notes :		ADX0001280	IA	2007-03-19	Alain Quirion		Création
							2008-10-27	Josée Parent		Modifications pour inclure les 
															adresses postdatées dans la modification
							2014-04-30	Maxime Martel		Modification dans tblGENE_Adresse au lieu de Mo_Adr								
							2015-02-24	Pierre-Luc Simard	Correction dans le nom du trigger
*************************IU_UN_State*************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_State](
	@StateID INTEGER,			--	Identifiant de la province (<0 = Insertion)
	@StateName VARCHAR(100),	--	Nom de la province
	@StateCode VARCHAR(5),		--	Code de la province
	@StateTaxPct MONEY,			--  Pourcentage de taxe de la province	
	@CountryID CHAR(4))			--	Identifiant du pays		
AS
BEGIN
	DECLARE @iReturn INTEGER

	DECLARE @oldStateName VARCHAR(100),
			@oldCountryID CHAR(4)
	
	SET @iReturn = 1

	IF @StateID <= 0
	BEGIN
		INSERT INTO Mo_State(StateName, StateCode, StateTaxPct, CountryID)
		VALUES(@StateName, @StateCode, @StateTaxPct, @CountryID)

		IF @@ERROR <> 0
			SET @iReturn = -1
		ELSE 
			SET @iReturn =  SCOPE_IDENTITY()
	END	
	ELSE
	BEGIN
		SELECT 
				@oldStateName = StateName,
				@oldCountryID = CountryID
		FROM Mo_State
		WHERE StateID = @StateID

		--Mise à jour de la province
		UPDATE Mo_State
		SET StateName = @StateName, 
			StateCode = @StateCode,
			StateTaxPct = @StateTaxPct,
			CountryID = @CountryID
		WHERE StateID = @StateID

		IF @@ERROR <> 0
			SET @iReturn = -2
		ELSE 
			SET @iReturn =  @StateID

		IF @iReturn > 0
			AND (@oldCountryID <> @CountryID
					OR @oldStateName <> @StateName) --Seulement si le pays ou la province a été modifiée
		BEGIN
			--Mise à jour des adresses actuelles modifiés
			IF object_id('tempdb..#DisableTrigger') is null
				CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))
				INSERT INTO #DisableTrigger VALUES('TtblGENE_Adresse')
			
			UPDATE tblGENE_Adresse
			SET vcProvince = @StateName
			FROM tblGENE_Adresse A
			WHERE iID_Province = @StateID
					

			Delete #DisableTrigger where vcTriggerName = 'TtblGENE_Adresse'

			UPDATE tblGENE_AdresseHistorique
			SET 
				iID_Province = NULL
			FROM tblGENE_AdresseHistorique A
			WHERE iID_Province = @StateID


			IF @@ERROR <> 0
				SET @iReturn = -3
		END
	END

	RETURN @iReturn
END

