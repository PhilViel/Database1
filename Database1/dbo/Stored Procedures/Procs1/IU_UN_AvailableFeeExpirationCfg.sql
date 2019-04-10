
/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 				:	IU_UN_AvailableFeeExpirationCfg
Description 		:	Ajout ou édition d’une configuration de frais disponibles
Valeurs de retour	:	@ReturnValue :
							> 0 : [Réussite]
							<= 0 : [Échec].

Notes :		ADX0001253	IA	2007-03-23	Alain Quirion		Création
************************************************************************************************/
CREATE PROCEDURE dbo.IU_UN_AvailableFeeExpirationCfg(
	@AvailableFeeExpirationCfgID INTEGER,	--ID de la configuration (<0 = Insertion)
	@StartDate DATETIME,					--Date de début
	@MonthAvailable INTEGER)				--Expiration (en mois)

AS
BEGIN
	DECLARE @iResult INTEGER

	SET @iResult = 1

	IF @AvailableFeeExpirationCfgID <= 0
	BEGIN
		INSERT INTO Un_AvailableFeeExpirationCfg(				
				StartDate,				
				MonthAvailable)
		VALUES(	@StartDate,				
				@MonthAvailable)

		IF @@ERROR <> 0
			SET @iResult = -1
		ELSE
			SET @iResult = SCOPE_IDENTITY()
	END
	ELSE
	BEGIN
		UPDATE Un_AvailableFeeExpirationCfg
		SET StartDate = @StartDate,				
			MonthAvailable = @MonthAvailable
		WHERE AvailableFeeExpirationCfgID = @AvailableFeeExpirationCfgID

		IF @@ERROR <> 0
			SET @iResult = -2
		ELSE
			SET @iResult = @AvailableFeeExpirationCfgID
	END

	RETURN @iResult
END

