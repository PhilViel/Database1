
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_Modal
Description         :	Insertion d'une modalité de dépôt
Valeurs de retours  :	@ReturnValue :
								> 0 : Réussite
								<= 0 : Échec

Note                :			ADX0001317	IA	2007-05-01	Alain Quirion	Création
*********************************************************************************************************************/
CREATE PROCEDURE dbo.IU_UN_Modal (	
	@ModalID INTEGER,				--	ID de la modalité de dépôts
	@PlanID INTEGER,				--	ID du régime
	@ModalDate DATETIME,			--	Date d’entrée en vigueur de la modalité de dépôts.
	@PmtByYearID SMALLINT,			--	Nombre de dépôts par année.
	@PmtQty	INTEGER,				--	Nombre total de dépôt.
	@BenefAgeOnBegining INTEGER,	--	Age du bénéficiaire à la d’entrée en vigueur.
	@PmtRate MONEY,					--	Montant d’épargne et de frais par dépôt par unité.
	@SubscriberInsuranceRate MONEY,	--	Montant d’assurance souscripteur par dépôt par unité.
	@FeeByUnit MONEY,				--	Frais par unité.
	@FeeSplitByUnit MONEY,			--	Montant de frais à atteindre avant la répartition 50/50.
	@BusinessBonusToPay	BIT)		--	Indique s’il faut payer des bonis d’affaires pour les groupes d’unités de cette modalité de dépôts.
AS
BEGIN
	DECLARE @iResult INT

	SET @iResult = -1

	IF @ModalID <= 0
	BEGIN
		INSERT INTO Un_Modal(
					PlanID, 
					ModalDate, 
					PmtByYearID, 
					PmtQty, 
					BenefAgeOnBegining,
					PmtRate,
					SubscriberInsuranceRate,
					FeeByUnit,
					FeeSplitByUnit,
					BusinessBonusToPay)
		VALUES(	@PlanID, 
				@ModalDate, 
				@PmtByYearID, 
				@PmtQty, 
				@BenefAgeOnBegining,
				@PmtRate,
				@SubscriberInsuranceRate,
				@FeeByUnit,
				@FeeSplitByUnit,
				@BusinessBonusToPay)

		IF @@ERROR <> 0
			SET @iResult = -1
		ELSE 
			SET @iResult = SCOPE_IDENTITY()	
	END
	ELSE
	BEGIN
		UPDATE Un_Modal
		SET PlanID = @PlanID, 
			ModalDate = @ModalDate, 
			PmtByYearID = @PmtByYearID, 
			PmtQty = @PmtQty, 
			BenefAgeOnBegining = @BenefAgeOnBegining,
			PmtRate = @PmtRate,
			SubscriberInsuranceRate = @SubscriberInsuranceRate,
			FeeByUnit = @FeeByUnit,
			FeeSplitByUnit = @FeeSplitByUnit,
			BusinessBonusToPay = @BusinessBonusToPay
		WHERE ModalID = @ModalID

		IF @@ERROR <> 0
			SET @iResult = -2
		ELSE 
			SET @iResult = @ModalID
	END
	
	RETURN @iResult
END

