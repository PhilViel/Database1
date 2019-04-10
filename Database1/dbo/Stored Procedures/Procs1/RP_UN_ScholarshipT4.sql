/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	RP_UN_ScholarshipT4
Description         :	Rapport des T4 et relevés 8
Valeurs de retours  :	Dataset de données
Note                :						2004-06-28	Bruno Lapointe		Création
								ADX0000753	IA	2005-11-03	Bruno Lapointe		La procédure va chercher le montant du chèque
																							dans les nouvelles tables au lieu de celles 
																							d'UniSQL 
												2010-02-08	Pierre-Luc Simard	Affiche un message demandant à l'informatioque de générer le 
																				bon fichier à l'aide du script RP_UN_ScholarshipT4Formulatrix.
exec RP_UN_ScholarshipT4

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_ScholarshipT4] 
AS
BEGIN
	SELECT 
		BeneficiaryLastName = 'Veuillez',
		BeneficiaryFirstName = 'demander',
		BeneficiarySocialNumber = 'la',
		ChequeAmount = 0,
		BeneficiaryAddress = 'version',
		BeneficiaryCity = 'pour',
		BeneficiaryState = 'Formulatrix',
		BeneficiaryZipCode = '!!!'
	/*
	SELECT 
		BeneficiaryLastName = RTRIM(BH.LastName),
		BeneficiaryFirstName = RTRIM(BH.FirstName),
		BeneficiarySocialNumber = RTRIM(BH.SocialNumber),
		ChequeAmount = SUM(CH.fAmount),
		BeneficiaryAddress = RTRIM(A.Address),
		BeneficiaryCity = RTRIM(A.City),
		BeneficiaryState = ' (' + RTRIM(A.StateName) + ')',
		BeneficiaryZipCode = dbo.fn_Mo_FormatZIP(ISNULL(RTRIM(UPPER(A.ZipCode)),''), A.CountryID)
	FROM (
		SELECT
			V.OperID,
			C.fAmount
		FROM (
			SELECT 
				L.OperID,
				iCheckID = MAX(C.iCheckID)
			FROM Un_ScholarshipPmt SP
			JOIN Un_Oper O ON O.OperID = SP.OperID AND O.OperTypeID IN ('PAE','AVC')
			JOIN Un_OperLinkToCHQOperation L ON SP.OperID = L.OperID
			JOIN CHQ_OperationDetail OD ON OD.iOperationID = L.iOperationID
			JOIN CHQ_CheckOperationDetail COD ON COD.iOperationDetailID = OD.iOperationDetailID
			JOIN CHQ_Check C ON C.iCheckID = COD.iCheckID
			GROUP BY L.OperID
			) V
		JOIN CHQ_Check C ON C.iCheckID = V.iCheckID
		WHERE C.iCheckStatusID IN (4,6)
			AND (YEAR(C.dtEmission) = (YEAR(GETDATE())-1))
		) CH
	JOIN Un_Oper O ON O.OperID = CH.OperID
	JOIN Un_ScholarshipPmt P ON P.OperID = O.OperID
	JOIN Un_Scholarship S ON S.ScholarshipID = P.ScholarshipID
	JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
	JOIN dbo.Mo_Human BH ON BH.HumanID = C.BeneficiaryID
	LEFT JOIN dbo.Mo_Adr A ON A.AdrID = BH.AdrID
	WHERE BH.ResidID = 'CAN'
	GROUP BY 
		BH.HumanID,
		BH.LastName,
		BH.FirstName,
		BH.SocialNumber,
		A.Address,
		A.City,
		A.StateName,
		A.ZipCode,
		A.CountryID
	ORDER BY
		BH.LastName,
		BH.FirstName
	*/
END


