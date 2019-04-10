/********************************************************************************************************************
Copyrights (c) 2018 Gestion Universitas inc
Nom                 :	psREPR_RapportCommissionBEC
Description         :	Pour le rapport SSRS "RapCommBec" : permet d'obtenir les commissions sur le BEC
						pour un représentant en particulier pour un mois choisi.
Valeurs de retours  :	Dataset 
Note                :	2018-11-16	Maxime Martel			Création

exec psREPR_RapportCommissionBEC '2018-04-05', '2018-12-07'
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psREPR_RapportCommissionBEC] 
	(
	@StartDate DATETIME,
	@EndDate DateTime
	) 

AS
BEGIN

	SELECT 
		* 
	FROM (
		SELECT
			DateCalculBoni = CBEC.dDate_Calcul,
			PrenomRep = H.FirstName,
			NomRep = H.LastName,
			RepCode = R.RepCode,
			NumeroConvention = C.ConventionNo,
			NomBeneficiaire = HB.LastName,
			PrenomBeneficiaire = HB.FirstName,
			BoniVerse = SUM(CASE WHEN CBEC.mMontant_ComBEC >= 0 THEN CBEC.mMontant_ComBEC ELSE 0 END) OVER(PARTITION BY CBEC.dDate_Calcul, C.ConventionNo, CBEC.RepID, CBEC.RepRoleID, CBEC.dDate_Insertion),
			BoniRepris = SUM(CASE WHEN CBEC.mMontant_ComBEC < 0 THEN CBEC.mMontant_ComBEC ELSE 0 END) OVER(PARTITION BY CBEC.dDate_Calcul, C.ConventionNo, CBEC.RepID, CBEC.RepRoleID, CBEC.dDate_Insertion),
			RepRole = CBEC.RepRoleID,
			Doublon = 1
		FROM tblREPR_CommissionsBEC CBEC
		JOIN (
			-- DOUBLON DE BONI
			SELECT 
				RepID, 
				RepRoleID, 
				BeneficiaryID
			FROM tblREPR_CommissionsBEC
			GROUP BY RepID, RepRoleID, BeneficiaryID
			HAVING count(*) > 1
		)D on D.RepID = CBEC.RepID AND D.RepRoleID = CBEC.RepRoleID AND D.BeneficiaryID = CBEC.BeneficiaryID
		JOIN Un_Rep R on R.RepID = CBEC.RepID
		JOIN Mo_Human H on H.HumanID = R.RepID
		JOIN Un_Unit U ON U.UnitID = CBEC.UnitID
		JOIN Un_Convention C ON C.ConventionID = U.ConventionID
		JOIN Mo_Human HB ON HB.HumanID = CBEC.BeneficiaryID
		WHERE CBEC.dDate_Calcul >= @StartDate AND CBEC.dDate_Calcul <= @EndDate

		UNION ALL

		SELECT
			DateCalculBoni = CBEC.dDate_Calcul,
			PrenomRep = H.FirstName,
			NomRep = H.LastName,
			RepCode = R.RepCode,
			NumeroConvention = C.ConventionNo,
			NomBeneficiaire = HB.LastName,
			PrenomBeneficiaire = HB.FirstName,
			BoniVerse = SUM(CASE WHEN CBEC.mMontant_ComBEC >= 0 THEN CBEC.mMontant_ComBEC ELSE 0 END) OVER(PARTITION BY CBEC.dDate_Calcul, C.ConventionNo, CBEC.RepID, CBEC.RepRoleID, CBEC.dDate_Insertion),
			BoniRepris = SUM(CASE WHEN CBEC.mMontant_ComBEC < 0 THEN CBEC.mMontant_ComBEC ELSE 0 END) OVER(PARTITION BY CBEC.dDate_Calcul, C.ConventionNo, CBEC.RepID, CBEC.RepRoleID, CBEC.dDate_Insertion),
			RepRole = CBEC.RepRoleID,
			Doublon = 0
		FROM tblREPR_CommissionsBEC CBEC
		JOIN Un_Rep R on R.RepID = CBEC.RepID
		JOIN Mo_Human H on H.HumanID = R.RepID
		JOIN Un_Unit U ON U.UnitID = CBEC.UnitID
		JOIN Un_Convention C ON C.ConventionID = U.ConventionID
		JOIN Mo_Human HB ON HB.HumanID = CBEC.BeneficiaryID
		WHERE CBEC.dDate_Calcul >= @StartDate AND CBEC.dDate_Calcul <= @EndDate
	) BEC
	ORDER BY 
		BEC.NumeroConvention, 
		CASE BEC.RepRole WHEN 'REP' THEN 2 ELSE 3 END, 
		Bec.BoniVerse DESC, 
		BEC.DateCalculBoni


END
