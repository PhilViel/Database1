/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	RP_UN_CESPRegistrationConvention
Description         :	Procédure qui sert au rapport de l'enregistrement des convention à la SCÉÉ et au rapport des 
								conventions avec erreurs en attentes.
								
Exemple d'appel		:	EXECUTE dbo.RP_UN_CESPRegistrationConvention 123311

Valeurs de retours  :	Dataset de données

Note                :	2006-07-18	Mireya Gonthier 		Création  IA-ADX0001061		Convention\ Rapport\ 
															Enregistrement de la convention à la SCEE : 
															Adaptation pour PCEE 4.3														
						2010-04-19	Jean-François Gauthier	Modification afin d'utiliser dtRegStartDate pour la date de transaction
						2015-09-30	Pierre-Luc Simard		Retrait de la jointure GGI puisque plus utilisée et pour régler les problèmes de doublons 								 
						2015-10-21	Pierre-Luc Simard		Ne plus aller chercher la date des enregistrements 100								
*********************************************************************************************************************/
CREATE PROCEDURE dbo.RP_UN_CESPRegistrationConvention (
	@ConventionID INTEGER)
AS
BEGIN
	CREATE TABLE #Convention (
		ConventionID INTEGER PRIMARY KEY
	) 
	
	INSERT INTO #Convention
	VALUES (@ConventionID)

	SELECT
		C.ConventionNo,
		C.ConventionID,
		dtTransaction = C.dtRegStartDate,		-- 2010-04-19 : JFG : Remplace du champ GGI.dtTransaction par dtRegStartDate
		C.GovernmentRegDate,
		vcrelationshiptype = R.vcrelationshiptype,
		P.PlanDesc,
		B.BeneficiaryID,
		TutorName = RTRIM(ISNULL(T.Lastname,''))+', '+RTRIM(ISNULL(T.Firstname,'')),
		BBirthDate = HB.BirthDate,
		BSexID = HB.SexID,
		BLangID = HB.LangID,
		BAddress = AB.Address,
		BCity = AB.City,
		BStateNAme = AB.StateName,
		BZipCode = AB.ZipCode,
		BCountryName = CB.CountryName,
		BSocialNumber = HB.SocialNumber,
		Benefname = RTRIM(HB.Lastname)+', '+RTRIM(HB.Firstname)
	FROM #Convention CE
	JOIN dbo.Un_Convention C ON C.ConventionID = CE.ConventionID
	JOIN Un_Plan P ON C.PlanID = P.PlanID
	JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
	JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
	JOIN UN_RelationShipType R ON R.tirelationshiptypeID = C.tirelationshiptypeID
	LEFT JOIN dbo.Mo_Human T ON T.HumanID = B.iTutorID
	LEFT JOIN dbo.Mo_Adr AB ON AB.AdrID = HB.AdrID
	LEFT JOIN Mo_Country CB ON AB.CountryID = CB.CountryID
	ORDER BY 
		C.ConventionNo, 
		C.ConventionID
END
