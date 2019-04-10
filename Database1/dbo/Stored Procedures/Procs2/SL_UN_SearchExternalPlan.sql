
/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 			:	Procédure qui renvoi la liste des régimes externes correspondant aux critères de recherche.
Description 		:	Procédure qui supprime un régime externe
Valeurs de retour	:	Dataset :
							ExternalPlanID					INTEGER		ID du plan externe (<=0 Insertion)
							ExternalPlanTypeID				CHAR(3)		ID du type de plan externe (IND, COL)
							ExternalPlanGovernmentRegNo		VARCHAR(10) Numéro d’enregistrement gouvernemental
							ExternalPromoID					NTEGER		ID du promoteur externe	
							CompanyName						VARCHAR(75)	Nom du promoteur externe

Note			:		ADX0001159	IA	2007-02-12	Alain Quirion		Création
*************************************************************************************************/
CREATE PROCEDURE dbo.SL_UN_SearchExternalPlan (
	@ExternalPlanGovernmentRegNo VARCHAR(10),	--Numéro d’enregistrement gouvernemental ('' = tous)
	@bIND BIT,									--Inclus ou non les plan individuels (1=Oui)
	@bCOL BIT,									--Inclus ou non les plan collectifs (1=Oui)
	@bFAM BIT,									--Inclus ou non les plan familiaux (1=Oui)
	@bGRO BIT,									--Inclus ou non les plan de groupe (1=Oui)
	@CompanyName VARCHAR(75))					--Nom de la compagnie ('' = tous)	
AS
BEGIN
	DECLARE @ExternalPlanTypeTable TABLE(
		ExternalPlanTypeID CHAR(3))

	--Insertion des type de plan
	IF @bIND = 1
		INSERT INTO @ExternalPlanTypeTable(ExternalPlanTypeID)
		VALUES('IND')
	IF @bCOL = 1
		INSERT INTO @ExternalPlanTypeTable(ExternalPlanTypeID)
		VALUES('COL')
	IF @bFAM = 1
		INSERT INTO @ExternalPlanTypeTable(ExternalPlanTypeID)
		VALUES('FAM')
	IF @bGRO = 1
		INSERT INTO @ExternalPlanTypeTable(ExternalPlanTypeID)
		VALUES('GRO')

	SELECT 
			EPL.ExternalPlanID,					--ID du plan externe (<=0 Insertion)
			EPL.ExternalPlanTypeID,				--ID du type de plan externe (IND, COL)
			EPL.ExternalPlanGovernmentRegNo,	--Numéro d’enregistrement gouvernemental
			EPL.ExternalPromoID,				--ID du promoteur externe	
			C.CompanyName						--Nom du promoteur externe 
	FROM Un_ExternalPlan EPL
	JOIN Un_ExternalPromo EPR ON EPR.ExternalPromoID = EPL.ExternalPromoID
	JOIN Mo_Company C ON C.CompanyID = EPR.ExternalPromoID
	WHERE (EPL.ExternalPlanGovernmentRegNo LIKE @ExternalPlanGovernmentRegNo
			OR @ExternalPlanGovernmentRegNo = '')
			AND EPL.ExternalPlanTypeID IN ( SELECT ExternalPlanTypeID 
											FROM @ExternalPlanTypeTable)
			AND (C.CompanyName LIKE @CompanyName
					OR @CompanyName = '')
	ORDER BY EPL.ExternalPlanGovernmentRegNo
END

