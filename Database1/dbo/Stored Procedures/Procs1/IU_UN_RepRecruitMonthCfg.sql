
/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 				:	IU_UN_RepRecruitMonthCfg
Description 		:	Insertion d’une configuration de durée en mois des recrues
Valeurs de retour	:	@ReturnValue :
							> 0 : [Réussite]
							<= 0 : [Échec].

Notes :		ADX0001254	IA	2007-03-23	Alain Quirion		Création
************************************************************************************************/
CREATE PROCEDURE dbo.IU_UN_RepRecruitMonthCfg(
	@RepRecruitMonthCfgID INTEGER,	--ID de la configuration (<0 = Insertion)
	@EffectDate DATETIME,			--Date de début
	@Months INTEGER)				--Nombre de mois	
AS
BEGIN
	DECLARE @iResult INTEGER

	SET @iResult = 1

	IF @RepRecruitMonthCfgID <= 0
	BEGIN
		INSERT INTO Un_RepRecruitMonthCfg(				
				EffectDate,				
				Months)
		VALUES(	@EffectDate,				
				@Months)

		IF @@ERROR <> 0
			SET @iResult = -1
		ELSE
			SET @iResult = SCOPE_IDENTITY()
	END
	ELSE
	BEGIN
		UPDATE Un_RepRecruitMonthCfg
		SET EffectDate = @EffectDate,				
			Months = @Months
		WHERE RepRecruitMonthCfgID = @RepRecruitMonthCfgID

		IF @@ERROR <> 0
			SET @iResult = -2
		ELSE
			SET @iResult = @RepRecruitMonthCfgID
	END

	RETURN @iResult
END

