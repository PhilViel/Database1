
/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 				:	IU_UN_RepFormationFeeCfg
Description 		:	Insertion d’une configuration des frais de formations
Valeurs de retour	:	@ReturnValue :
							> 0 : [Réussite]
							<= 0 : [Échec].

Notes :		ADX0001257	IA	2007-03-23	Alain Quirion		Création
************************************************************************************************/
CREATE PROCEDURE dbo.IU_UN_RepFormationFeeCfg(
	@RepFormationFeeCfgID INTEGER,	--ID de la configuration (<0 = Insertion)
	@StartDate DATETIME,			--Date de début
	@FormationFeeAmount MONEY)		--Frais de formation
AS
BEGIN
	DECLARE @iResult INTEGER

	SET @iResult = 1

	IF @RepFormationFeeCfgID <= 0
	BEGIN
		INSERT INTO Un_RepFormationFeeCfg(				
				StartDate,				
				FormationFeeAmount)
		VALUES(	@StartDate,				
				@FormationFeeAmount)

		IF @@ERROR <> 0
			SET @iResult = -1
		ELSE
			SET @iResult = SCOPE_IDENTITY()
	END
	ELSE
	BEGIN
		UPDATE Un_RepFormationFeeCfg
		SET StartDate = @StartDate,				
			FormationFeeAmount = @FormationFeeAmount
		WHERE RepFormationFeeCfgID = @RepFormationFeeCfgID

		IF @@ERROR <> 0
			SET @iResult = -2
		ELSE
			SET @iResult = @RepFormationFeeCfgID
	END

	RETURN @iResult
END

