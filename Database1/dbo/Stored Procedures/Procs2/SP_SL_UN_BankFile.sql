/****************************************************************************************************
	Retourne la liste des fichiers de CPA.
 ******************************************************************************
	2004-10-19 Bruno Lapointe
		Migration, documentation et normalisation
		IA-ADX0000479
 ******************************************************************************/
CREATE PROC [dbo].[SP_SL_UN_BankFile] (
	@BankFileID INTEGER) -- ID unique du fichier bancaire (0 = tous)
AS
BEGIN
	SELECT 
		BF.BankFileID,
		BF.BankFileStartDate,
		BF.BankFileEndDate,
		Total = Ct.TotalAmount + ISNULL(Co.TotalAmount,0)
	FROM Un_BankFile BF
	JOIN (
		SELECT 
			B.BankFileID,
			TotalAmount = SUM(Ct.Cotisation + Ct.Fee + Ct.BenefInsur + Ct.SubscInsur + Ct.TaxOnInsur)
		FROM Un_OperBankFile B
		JOIN Un_Cotisation Ct ON Ct.OperID = B.OperID
		WHERE @BankFileID = B.BankFileID
			OR @BankFileID = 0
		GROUP BY B.BankFileID
		) Ct ON Ct.BankFileID = BF.BankFileID
	LEFT JOIN (
		SELECT 
			B.BankFileID,
			TotalAmount = SUM(Co.ConventionOperAmount)
		FROM Un_OperBankFile B
		JOIN Un_ConventionOper Co ON Co.OperID = B.OperID
		WHERE @BankFileID = B.BankFileID
			OR @BankFileID = 0
		GROUP BY B.BankFileID
		) Co ON Co.BankFileID = BF.BankFileID
	ORDER BY 
		BF.BankFileStartDate DESC, 
		BF.BankFileEndDate DESC
END

