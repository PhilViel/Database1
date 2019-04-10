
/******************************************************************************
	Destruction d'une raison de ne pas commander de chèques
******************************************************************************
	2004-09-01 Bruno Lapointe
		Création
******************************************************************************/
CREATE PROC SP_IU_UN_Plan (
	@ConnectID INTEGER, -- ID unique de connexion
	@PlanID INTEGER, -- ID unique du plan
	@PlanTypeID UnPlanType, -- Type de plan IND = Individuel, COL = Collectif
	@PlanScholarshipQty SMALLINT, -- Nombre de bourse pour ce plan
	@PlanOrderID SMALLINT, -- 
	@PlanDesc VARCHAR(75), -- Nom du plan
	@PlanGovernmentRegNo VARCHAR(75), -- Numéro d'enregistrement du plan au gouvernement
	@IntReimbAge SMALLINT) -- Age du bénéficiaire pour remboursement intégral
AS
BEGIN
	IF @PlanID = 0
	BEGIN
		DECLARE 
			@OrderOfPlanInReport INTEGER

		SELECT 
			@OrderOfPlanInReport = MAX(OrderOfPlanInReport) +1
		FROM Un_Plan

		INSERT INTO Un_Plan (
			PlanTypeID,
			PlanScholarshipQty,
			PlanOrderID,
			PlanDesc,
			PlanGovernmentRegNo,
			IntReimbAge,
			OrderOfPlanInReport)
		VALUES (
			@PlanTypeID,
			@PlanScholarshipQty,
			@PlanOrderID,
			@PlanDesc,
			@PlanGovernmentRegNo,
			@IntReimbAge,
			@OrderOfPlanInReport)

		IF @@ERROR = 0
		BEGIN
			SET @PlanID = IDENT_CURRENT('Un_Plan');
			EXEC IMo_Log @ConnectID, 'Un_Plan', @PlanID, 'I', ''
		END
	END
	ELSE
	BEGIN
		UPDATE Un_Plan 
		SET
			PlanTypeID = @PlanTypeID,
			PlanScholarshipQty = @PlanScholarshipQty,
			PlanOrderID = @PlanOrderID,
			PlanDesc = @PlanDesc,
			PlanGovernmentRegNo = @PlanGovernmentRegNo,
			IntReimbAge = @IntReimbAge 
		WHERE PlanID = @PlanID

		IF @@ERROR = 0
			EXEC IMo_Log @ConnectID, 'Un_Plan', @PlanID, 'U', ''
		ELSE
			SET @PlanID = 0
	END

	RETURN @PlanID
END

