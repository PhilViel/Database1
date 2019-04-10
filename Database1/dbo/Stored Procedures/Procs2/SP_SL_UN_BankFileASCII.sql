/****************************************************************************************************
	Procédure retournant les données nécessaire pour générer le fichier ASCII 
	de CPA.
 ******************************************************************************
	2004-08-17 Bruno Lapointe
		Gestion des opérations sur conventions (Intérêt chargés au client)
	2004-10-19 Bruno Lapointe
		Migration, documentation et normalisation
		IA-ADX0000479
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_UN_BankFileASCII] (
	@BankFileID INTEGER) -- ID unique du fichier bancaire
AS
BEGIN
	SELECT 
		O.OperID,
		O.OperDate,
		OAI.AccountName,
		OAI.TransitNo,
		BT.BankTypecode,
		B.BankTransit,
		Montant = CAST((Ct.Montant+ISNULL(Co.Montant,0))*100 AS INTEGER)
	FROM Un_OperBankFile OBF 
	JOIN Un_Oper O ON O.OperID = OBF.OperID
	JOIN Un_OperAccountInfo OAI ON OAI.OperID = O.OperID
	JOIN Mo_Bank B ON B.BankID = OAI.BankID
	JOIN Mo_BankType BT ON BT.BankTypeID = B.BankTypeID
	JOIN ( -- Va chercher les montants de la table Un_Cotisation (Épargnes, frais, assurances et taxes)
		SELECT 
			Ct.OperID,
			Montant = SUM(ISNULL(Ct.Cotisation,0) + ISNULL(Ct.Fee,0) + ISNULL(Ct.BenefInsur,0) + ISNULL(Ct.SubscInsur,0) + ISNULL(Ct.TaxOnInsur,0))
		FROM Un_Cotisation Ct
		JOIN Un_OperBankFile OBF ON OBF.OperID = Ct.OperID
		WHERE OBF.BankFileID = @BankFileID
		GROUP BY 
			Ct.OperID
		) Ct ON Ct.OperID = O.OperID
	LEFT JOIN ( -- Va chercher les montants de la table Un_ConventionOper (Intérêts chargées au client)
		SELECT 
			Co.OperID,
			Montant = SUM(ISNULL(Co.ConventionOperAmount,0))
		FROM Un_ConventionOper Co
		JOIN Un_OperBankFile OBF ON OBF.OperID = Co.OperID
		WHERE OBF.BankFileID = @BankFileID
		GROUP BY 
			Co.OperID
		) Co ON Co.OperID = O.OperID
	WHERE OBF.BankFileID = @BankFileID
	ORDER BY 
		O.OperID 

	RETURN @BankFileID
END

