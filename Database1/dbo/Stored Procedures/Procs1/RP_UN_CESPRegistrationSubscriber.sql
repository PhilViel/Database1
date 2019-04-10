/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	RP_UN_CESPRegistrationSubscriber
Description         :	Procédure qui sert au rapport de l'enregistrement de la convention au PCEE.
Valeurs de retours  :	Dataset de données
Note                :	2006-07-18	Mireya Gonthier 	Création  IA-ADX0001061		Convention\ Rapport\ 
												Enregistrement de la convention à la SCEE : 
												Adaptation pour PCEE 4.3														
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_CESPRegistrationSubscriber] (
	@ConventionID INTEGER)
AS 
BEGIN
	CREATE TABLE #Convention (
		ConventionID INTEGER PRIMARY KEY
	) 

	INSERT INTO #Convention
	VALUES (@ConventionID)

	SELECT
		C.ConventionID,
		SubscriberID = SH.HumanID,
		SBirthDate = SH.BirthDate,
		SSexID = SH.SexID,
		SLangID = SH.LangID,
		SAddress = SA.Address,
		SCity = SA.City,
		SStateName = SA.StateNAme,
		SZipCode = SA.ZipCode,
		SCountryName = SC.CountryName,
		SSocialNumber = SH.SocialNumber,
		SubscriberName = RTRIM(SH.Lastname)+', '+RTRIM(SH.Firstname)
	FROM #Convention V
	JOIN dbo.Un_Convention C ON C.ConventionID = V.ConventionID
	JOIN dbo.Mo_Human SH ON SH.HumanID = C.SubscriberID OR SH.HumanID = C.CoSubscriberID
	LEFT JOIN dbo.Mo_Adr SA ON SA.AdrID = SH.AdrID
	LEFT JOIN Mo_Country SC ON SA.CountryID = SC.CountryID
	ORDER BY C.ConventionID
END


