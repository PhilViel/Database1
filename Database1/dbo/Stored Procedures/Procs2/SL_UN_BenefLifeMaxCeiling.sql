/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_BenefLifeMaxCeiling
Description         :	Cette procédure retourne les valeurs des plafond vie pour un bénéficiaire.
Valeurs de retours  :	Dataset de données
Note                :						2004-06-09	Bruno Lapointe	Création
								ADX0001114	IA	2006-11-20	Alain Quirion	Gestion des deux périodes de calcul de date estimée de RI (FN_UN_EstimatedIntReimbDate)
								ADX0001314	IA	2007-06-15	Bruno Lapointe	Ajout des colonnes fCESP et fCIREE
												2018-09-11	Maxime Martel	JIRA MP-699 Ajout de OpertypeID COU
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_BenefLifeMaxCeiling] (
	@BeneficiaryID INTEGER)
AS 
BEGIN
	SELECT 
		C.ConventionID, 
		C.ConventionNo, 
		C.SubscriberID, 
		SubscriberName = H.LastName + ', '+ H.FirstName,
		SubsAmount = 
			CASE 
				WHEN ISNULL(V1.SubsAmount, 0) = 0 THEN ISNULL(V2.CumAmount, 0)
				ELSE ISNULL(V1.SubsAmount, 0)
			END + ISNULL(A.AutomaticAmount, 0),
		fCESP = ISNULL(CE.fCESP,0),
		fCIREE = 0
	FROM dbo.Un_Convention C
	JOIN dbo.Mo_Human H ON H.HumanID = C.SubscriberID
	LEFT JOIN (
		SELECT
			U.ConventionID,
			SubsAmount = SUM(ROUND(U.UnitQty * M.PmtRate, 2) * M.PmtQty)
		FROM dbo.Un_Unit U
		JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
		JOIN Un_Modal M ON M.ModalID = U.ModalID
		JOIN Un_Plan P ON P.PlanID = M.PlanID
		WHERE C.BeneficiaryID = @BeneficiaryID
		  AND P.PlanTypeID = 'COL'
		  AND U.TerminatedDate IS NULL
		GROUP BY U.ConventionID 
		) V1 ON V1.ConventionID = C.ConventionID
	LEFT JOIN (
		SELECT 
			U.ConventionID,
			CumAmount = SUM(Ct.Fee+Ct.Cotisation)
		FROM dbo.Un_Unit U
		JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
		JOIN Un_Modal M ON M.ModalID = U.ModalID
		JOIN Un_Plan P ON P.PlanID = M.PlanID
		JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		WHERE C.BeneficiaryID = @BeneficiaryID
		  AND U.TerminatedDate IS NULL
		  AND P.PlanTypeID = 'IND'
		  AND O.OperTypeID IN ('ANN', 'CPA', 'CHQ', 'NSF', 'RET', 'PRD', 'RES', 'COU')
		GROUP BY U.ConventionID
		) V2 ON V2.ConventionID = C.ConventionID
	LEFT JOIN (
		SELECT
			C.ConventionID,
			AutomaticAmount = 
				SUM(dbo.fn_Un_NbrAutoDepositBetweenTwoDate(
							A.FirstAutomaticDepositDate,
							A.FirstAutomaticDepositDate,
							CASE
								WHEN dbo.fn_Mo_IsDateNull(A.EndDate) IS NULL THEN 
									dbo.fn_Un_EstimatedIntReimbDate(
											M.PmtByYearID,
											M.PmtQty,
											M.BenefAgeOnBegining,
											U.InForceDate,
											P.IntReimbAge,
											U.IntReimbDateAdjust)  
								ELSE A.EndDate
							END,
							A.TimeUnit,
							A.TimeUnitLap,
							C.ConventionID) 
					* A.CotisationFee)
		FROM Un_AutomaticDeposit A
		JOIN dbo.Un_Unit U ON U.UnitID = A.UnitID
		JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
		JOIN Un_Modal M ON M.ModalID = U.ModalID
		JOIN Un_Plan P ON P.PlanID = M.PlanID
		WHERE C.BeneficiaryID = @BeneficiaryID
		  AND P.PlanTypeID = 'IND'
		  AND A.StartDate < dbo.fn_Un_EstimatedIntReimbDate(
										M.PmtByYearID,
										M.PmtQty,
										M.BenefAgeOnBegining,
										U.InForceDate,
										P.IntReimbAge,
										U.IntReimbDateAdjust)
		GROUP BY C.ConventionID
		) A ON A.ConventionID = C.ConventionID
	LEFT JOIN (
		SELECT
			C.ConventionID,
			fCESP = SUM(CE.fCESG+CE.fACESG)
		FROM dbo.Un_Convention C
		JOIN Un_CESP CE ON CE.ConventionID = C.ConventionID
		WHERE C.BeneficiaryID = @BeneficiaryID
		GROUP BY C.ConventionID 
		) CE ON CE.ConventionID = C.ConventionID
	WHERE C.BeneficiaryID = @BeneficiaryID
END