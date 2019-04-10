/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_InfoForNewRES
Description         :	Retourne le solde d'épargne, frais, ass. sous., ass. bénéf. et taxes
Valeurs de retours  :	Dataset contenant les données
Note                :	
							ADX0000575	IA	2005-01-25	Bruno Lapointe		Création
							ADX0000575	IA	2005-01-28	Bruno Lapointe		Ajout de valeur de retour
							ADX0001324	BR 2005-03-09	Bruno Lapointe		La procédure de tenait pas conte de la date 
																			de résiliation.
							ADX0001357	IA	2007-06-04	Alain Quirion		Ajout du champ bIsContestWinner
*********************************************************************************************************************/
CREATE PROCEDURE dbo.SL_UN_InfoForNewRES (
	@UnitID INTEGER, -- ID unique du groupe d'unités
	@ReductionDate DATETIME, -- Date de réduction
	@RESType INTEGER) -- 0 = Remb. frais et ass, 1 = Remb. frais, 2 = Remb. épargne seulement
AS
BEGIN
	DECLARE
		@iNbDeposit INTEGER

	SELECT @iNbDeposit = dbo.fn_Un_EstimatedNumberOfDepositSinceBeginning(@ReductionDate, DAY(C.FirstPmtDate), M.PmtByYearID, M.PmtQty, U.InForceDate)
	FROM dbo.Un_Unit U
	JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
	JOIN Un_Modal M ON M.ModalID = U.ModalID
	WHERE U.UnitID = @UnitID

	SELECT
		U.UnitID,
		U.UnitQty,
		NbDeposit = @iNbDeposit,
		M.PmtRate,
		P.PlanTypeID,
		Cotisation = ISNULL(Ct.Cotisation,0),
		Fee = ISNULL(Ct.Fee,0),
		SubscInsur = ISNULL(Ct.SubscInsur,0),
		BenefInsur = ISNULL(Ct.BenefInsur,0),
		TaxOnInsur = ISNULL(Ct.TaxOnInsur,0),
		bIsContestWinner = ISNULL(SS.bIsContestWinner,0)
	FROM dbo.Un_Unit U
	JOIN Un_Modal M ON M.ModalID = U.ModalID
	LEFT JOIN (
		SELECT
			Ct.UnitID,
			Cotisation = SUM(Ct.Cotisation),
			Fee = SUM(Ct.Fee),
			SubscInsur = SUM(Ct.SubscInsur),
			BenefInsur = SUM(Ct.BenefInsur),
			TaxOnInsur = SUM(Ct.TaxOnInsur)
		FROM Un_Cotisation Ct
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		WHERE O.OperDate <= @ReductionDate
			AND Ct.UnitID = @UnitID
		GROUP BY Ct.UnitID
		) Ct ON Ct.UnitID = U.UnitID
	JOIN Un_Plan P ON P.PlanID = M.PlanID
	LEFT JOIN Un_SaleSource SS ON SS.SaleSourceID = U.SaleSourceID
	WHERE U.UnitID = @UnitID
END


