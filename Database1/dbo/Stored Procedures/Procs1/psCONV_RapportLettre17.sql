/****************************************************************************************************
Copyrights (c) 2011 Gestion Universitas inc.

Code du service		: psCONV_RapportLettre17
Nom du service		: Générer la lettre 17
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXECUTE psCONV_RapportLettre17 'x-20110921072'

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2012-11-20		Donald Huppé						Création du service		
		2013-09-05		Donald Huppé						Ajout du fil d'arriane du P + nom du fichier
		2014-06-19		Maxime Martel						Remplacer Mo_adr par la fonction pour obtenir l'adresse	
		2014-09-29		Donald Huppé						Ne pas faire de CROSS APPLY sur l'adresse de la succursale car rien ne sort s'il n'y a pas d'adresse.
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettre17] 
(
	@cConventionno varchar(15) --Filtre sur un numéro de convention

)
AS
BEGIN

	declare @today datetime, @humanID integer
	
	set @today = GETDATE()
	SET @cConventionno = UPPER(LTRIM(RTRIM(ISNULL(@cConventionno,''))))

	select @humanID = C.subscriberID FROM dbo.Un_Convention C where C.ConventionNo = @cConventionno

	SELECT 
		DISTINCT 
		SLastName = HS.lastname, 
		SFirstName = HS.firstname, 
		C.conventionno,
		CA.AccountName,
		bt.BankTypeCode,
		BA.BankTransit,
		CA.TransitNo,
		CompteDeBanque = bt.BankTypeCode + '-' + BA.BankTransit +'-' +CA.TransitNo,
		SouscAddress = a.vcNom_Rue,
		SouscCity = a.vcVille,
		SouscStateName = a.vcProvince,
		SouscZipCode = substring( replace(ltrim(rtrim(a.vcCodePostal)),' ',''),1,3) + ' ' + substring( replace(ltrim(rtrim(a.vcCodePostal)),' ',''),4,3),
		SousCountryID = a.cId_Pays,
		HS.SexID,
		BT.BankTypeName,
		BankAddress = isnull(ab.vcNom_Rue,'*** ADRESSE ABSENTE ***'),
		BankCity = ab.vcVille,
		BankStateName = ab.vcProvince,
		BankZipCode = substring( replace(ltrim(rtrim(ab.vcCodePostal)),' ',''),1,3) + ' ' + substring( replace(ltrim(rtrim(ab.vcCodePostal)),' ',''),4,3),
		BankCountryID =ab.cId_Pays,
		Representant = hr.firstname + ' ' + hr.lastname,
		HS.LangID,
		PlanClassification = [dbo].[fnCONV_ObtenirDossierClient](c.subscriberID,1) + '\' + replace(LEFT(CONVERT(VARCHAR, @today, 120), 10),'-','') + '_le_17'-- '20130904_le_17'

	FROM 
		Un_ConventionAccount CA
		JOIN Mo_Bank BA ON BA.BankID = CA.BankID
		JOIN dbo.Un_Convention C ON C.ConventionID = CA.ConventionID
		JOIN dbo.Un_Subscriber S on c.SubscriberID = s.SubscriberID
		JOIN dbo.Mo_Human hr on s.RepID = hr.HumanID
		JOIN dbo.mo_human HS on c.subscriberID = HS.humanID
		join dbo.fntGENE_ObtenirAdresseEnDate(@humanID,1,GETDATE(),1) A on A.iID_Source = HS.HumanID
		LEFT JOIN Mo_BankType BT ON BT.BankTypeID = BA.BankTypeID
		left JOIN Mo_Dep d ON d.CompanyID = BA.BankID and d.DepType = 'A'
		left JOIN Mo_Company co on d.CompanyID = co.CompanyID
		left join tblGENE_Adresse ab on ab.iID_Source = d.DepID
		--CROSS APPLY dbo.fntGENE_ObtenirAdresseEnDate(d.DepID,1,GETDATE(),1) ab
	where c.conventionNO = @cConventionno

end


