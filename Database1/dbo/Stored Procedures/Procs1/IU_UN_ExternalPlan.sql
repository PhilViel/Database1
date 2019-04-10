
/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 			:	IU_UN_ExternalPlan
Description 		:	Procédure de renvoit des listes de régime externe et des informations des promoteurs externes
Valeurs de retour	:	@ReturnValue :
								@ExternalPlanID : [Réussite]
								<= 0			: [Échec].

Note			:		ADX0001159	IA	2007-02-12	Alain Quirion		Création
*************************************************************************************************/
CREATE PROCEDURE dbo.IU_UN_ExternalPlan (
	@ExternalPlanID INTEGER,		-- ID du régime externe
	@ExternalPromoID INTEGER,		-- ID du promoteur externe
	@ExternalPlanTypeID CHAR(3),	-- Type de plan (IND, COL, FAM, GRO)
	@ExternalPlanGovernmentRegNo   VARCHAR(10)) -- Numéro d’enregistrement gouvernemental	
AS
BEGIN
	DECLARE @iResult INTEGER

	SET @iResult = 1

	IF @ExternalPlanID <= 0 -- Insertion
	BEGIN
		INSERT INTO Un_ExternalPlan(
									ExternalPromoID,
									ExternalPlanTypeID,
									ExternalPlanGovernmentRegNo)
		VALUES (@ExternalPromoID,
				@ExternalPlanTypeID,
				@ExternalPlanGovernmentRegNo)

		IF @@ERROR <> 0
			SET @iResult = -1
		ELSE
			SET @iResult = SCOPE_IDENTITY()
		
	END
	ELSE --Mise à jour
	BEGIN
		UPDATE Un_ExternalPlan
		SET ExternalPromoID = @ExternalPromoID,
			ExternalPlanTypeID = @ExternalPlanTypeID,
			ExternalPlanGovernmentRegNo = @ExternalPlanGovernmentRegNo
		WHERE ExternalPlanID = @ExternalPlanID

		IF @@ERROR <> 0
			SET @iResult = -2
		ELSE
			SET @iResult = @ExternalPlanID
	END

	RETURN @iResult
END

