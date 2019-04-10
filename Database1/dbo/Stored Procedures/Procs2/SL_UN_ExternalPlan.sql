/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 			:	SL_UN_ExternalPlan
Description 		:	Procédure de renvoit des listes de régime externe et des informations des promoteurs externes
Valeurs de retour	:	DataSet
							ExternalPlanID					INTEGER			ID du régime externe
							ExternalPromoID					INTEGER			ID du promoteur externe.
							ExternalPlanGovernmentRegNo 	NVARCHAR(10)	Numéro d'enregistrement gouvernemental du régime.
							CompanyName						VARCHAR(75)		Nom de la compagnie
							Address							VARCHAR(75)		Adresse
							City							VARCHAR(100)	Ville
							Statename						VARCHAR(75)		Province
							CountryID						CHAR(4)			ID du pays
							CountryName						VARCHAR(75)		Nom du pays
							ZipCode							VARCHAR(10)		Code postal
Note			:	ADX0000925	IA	2006-09-16	Alain Quirion		Création
					ADX0001159	IA	2007-02-12	Alain Quirion		Ajout de ExternalPlanTypeID et ExternalPromoID
*************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_ExternalPlan] (
	@ExternalPlanID INTEGER,		-- ID du régime externe
	@ExternalPromoID INTEGER = 0)   -- ID du promoteur externe (0 = tous)
AS
BEGIN
	SELECT
		EP.ExternalPlanID,
		EP.ExternalPlanTypeID,
		EP.ExternalPromoID,
		EP.ExternalPlanGOvernmentRegNo,
		CompanyName = ISNULL(C.CompanyName,'Unknown'),
		Address = ISNULL(A.Address,''),
		City = ISNULL(A.City,''),
		StateName = ISNULL(A.StateName,''),
		CountryID = ISNULL(A.CountryID,'UNK'),
		CountryName = ISNULL(Cn.CountryName,'Uknown'),
		ZipCode = ISNULL(A.ZipCode,'')		
	FROM	Un_ExternalPlan EP
	LEFT JOIN Mo_Company C ON EP.ExternalPromoID = C.CompanyID
	LEFT JOIN Mo_Dep D ON D.CompanyID = C.CompanyID
	LEFT JOIN dbo.Mo_Adr A ON A.AdrID = D.AdrID		
	LEFT JOIN Mo_Country Cn ON Cn.CountryID = A.CountryID	
	WHERE (@ExternalPlanID = 0
			OR @ExternalPlanID = ExternalPlanID)
			AND (@ExternalPromoID = 0
					OR @ExternalPromoID = ExternalPromoID)
	ORDER BY EP.ExternalPlanGovernmentRegNo	
END


