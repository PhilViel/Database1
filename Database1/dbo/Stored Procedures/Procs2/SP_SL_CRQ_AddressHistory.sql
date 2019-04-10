/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SP_SL_CRQ_AddressHistory
Description         :	Historique des adresses

Valeurs de retours  : 	

Note                :	2004-11-19	Bruno Lapointe		Création	IA-ADX0000590
						2014-03-06	Pierre-Luc Simard	Nouveau schéma d'adresses
						2014-04-25	Pierre-Luc Simard	Indiquer les adresses invalides
						2014-05-05	Maxime Martel		Historique adresse avec nouvelles tables		
						2014-10-07	Pierre-Luc Simard	Ajout du tri par InsertTime				
						2015-07-24	Pierre-Luc Simard	Ajout des courriels Professionnel et Autre
						2015-09-11	Steeve Picard			Correction pour les adresses étant une route rurale (iID_TypeBoite = 2 au lieu de 3)
						2015-12-15	Pierre-Luc Simard	Ajout d'un espace entre le téléphone et l'extension

exec SP_SL_CRQ_AddressHistory 'H', 423855

****************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_CRQ_AddressHistory] (
	@AdrTypeID MoAdrType, -- Type d'objet auquel appartient l'adresse ('C'=Adresse de compagnie, 'H'=Adresse d'individu).
	@HumanID INTEGER -- ID unique de l'humain dont on désire 
) AS
BEGIN
	DECLARE @Now datetime = GetDate()
	DECLARE @Today date = Cast(@Now as date) --CAST(dbo.FN_CRQ_DateNoTime(GETDATE()) as datetime)

	select RANK() 
	  over (order by u.Inforce DESC, u.Username, u.address, U.city, u.statename, u.countryid,
			u.countryName, u.zipcode, U.phone1, U.phone2, 
			u.mobile, u.fax, u.othertel, u.email, u.EMailProfessionnel, u.EMailAutre) as AdrID, u.* from (
			
			
	SELECT
		InForce = @Today,
		Address = 	CASE WHEN A.bInvalide = 1 THEN '*** Invalide *** ' ELSE '' END + 
						LTRIM(RTRIM(
						 CASE WHEN A.cID_Pays <> 'CAN' AND A.bNouveau_Format = 1 THEN 
							ISNULL(A.vcInternationale1, '') 
							+ CASE WHEN ISNULL(A.vcInternationale2, '') <> '' THEN SPACE(1) + A.vcInternationale2 ELSE '' END 
							+ CASE WHEN ISNULL(A.vcInternationale3, '') <> '' THEN SPACE(1) + A.vcInternationale3 ELSE '' END
						ELSE 
							CASE WHEN ISNULL(A.vcUnite, '') <> '' THEN A.vcUnite + '-' ELSE '' END
							+ CASE WHEN ISNULL(A.vcNumero_Civique, '') <> '' THEN A.vcNumero_Civique + ',' ELSE '' END
							+ CASE WHEN ISNULL(A.vcNom_Rue, '') <> '' THEN SPACE(1) + A.vcNom_Rue ELSE '' END
							+ CASE WHEN A.iID_TypeBoite = 1 AND ISNULL(A.vcBoite, '') <> '' THEN SPACE(1) + ' CP ' + A.vcBoite ELSE '' END
							+ CASE WHEN A.iID_TypeBoite = 2 AND ISNULL(A.vcBoite, '') <> '' THEN SPACE(1) + ' RR ' + A.vcBoite ELSE '' END
						END)),			
		City = A.vcVille,
		StateName = A.vcProvince,		
		CountryID = A.cID_Pays,
		CountryName = A.vcPays,
		ZipCode = A.vcCodePostal,
		Phone1 = isnull(dbo.fnGENE_TelephoneEnDate (@HumanID, 1, NULL, 1, 1),''),
		Phone2 = isnull(dbo.fnGENE_TelephoneEnDate (@HumanID, 4, NULL, 1, 1),''),
		Mobile = isnull(dbo.fnGENE_TelephoneEnDate (@HumanID, 2, NULL, 1, 1),''),
		Fax = isnull(dbo.fnGENE_TelephoneEnDate (@HumanID, 8, NULL, 1, 1),''),
		WattLine = '',
		OtherTel = isnull(dbo.fnGENE_TelephoneEnDate (@HumanID, 16, NULL, 1, 1),''), 
		Pager = '',
		EMail = isnull(dbo.fnGENE_CourrielEnDate (@HumanID, 1, NULL, 1),''),
		EMailProfessionnel = isnull(dbo.fnGENE_CourrielEnDate (@HumanID, 2, NULL, 1),''),
		EMailAutre = isnull(dbo.fnGENE_CourrielEnDate (@HumanID, 4, NULL,1),''),
		UserName = '',
		InsertTime = @Now
	FROM tblGENE_Adresse A
	left join Un_Rep R on A.iID_Source = R.RepID
	WHERE A.cType_Source = @AdrTypeID
		AND A.iID_Source = @HumanID
		AND A.dtDate_Debut <= @Today
		AND iId_type = CASE isnull(R.RepCode,'') when '' then 1 else 4 END
	union
	SELECT
		InForce = A.dtDate_Debut,
		Address = 	CASE WHEN A.bInvalide = 1 THEN '*** Invalide *** ' ELSE '' END + 
						LTRIM(RTRIM(
						 CASE WHEN A.cID_Pays <> 'CAN' AND A.bNouveau_Format = 1 THEN 
							ISNULL(A.vcInternationale1, '') 
							+ CASE WHEN ISNULL(A.vcInternationale2, '') <> '' THEN SPACE(1) + A.vcInternationale2 ELSE '' END 
							+ CASE WHEN ISNULL(A.vcInternationale3, '') <> '' THEN SPACE(1) + A.vcInternationale3 ELSE '' END
						ELSE 
							CASE WHEN ISNULL(A.vcUnite, '') <> '' THEN A.vcUnite + '-' ELSE '' END
							+ CASE WHEN ISNULL(A.vcNumero_Civique, '') <> '' THEN A.vcNumero_Civique + ',' ELSE '' END
							+ CASE WHEN ISNULL(A.vcNom_Rue, '') <> '' THEN SPACE(1) + A.vcNom_Rue ELSE '' END
							+ CASE WHEN A.iID_TypeBoite = 1 AND ISNULL(A.vcBoite, '') <> '' THEN SPACE(1) + ' CP ' + A.vcBoite ELSE '' END
							+ CASE WHEN A.iID_TypeBoite = 2 AND ISNULL(A.vcBoite, '') <> '' THEN SPACE(1) + ' RR ' + A.vcBoite ELSE '' END
						END)),			
		City = A.vcVille,
		StateName = A.vcProvince,		
		CountryID = A.cID_Pays,
		CountryName = A.vcPays,
		ZipCode = A.vcCodePostal,
		Phone1 = '',
		Phone2 = '',
		Mobile = '',
		Fax = '',
		WattLine = '',
		OtherTel = '', 
		Pager = '',
		EMail = '',
		EMailProfessionnel = '',
		EMailAutre = '',
		UserName = A.vcLogin_Creation,
		InsertTime = A.dtDate_Creation
	FROM tblGENE_Adresse A
	left join Un_Rep R on A.iID_Source = R.RepID
	WHERE A.cType_Source = @AdrTypeID
		AND A.iID_Source = @HumanID
		AND iId_type = CASE isnull(R.RepCode,'') when '' then 1 else 4 END
		--AND A.dtDate_Debut <= @Today
	UNION 
	
	SELECT
		InForce = A.dtDate_Debut,
		Address = 	CASE WHEN A.bInvalide = 1 THEN '*** Invalide *** ' ELSE '' END + 
						LTRIM(RTRIM(
						 CASE WHEN A.cID_Pays <> 'CAN' AND A.bNouveau_Format = 1 THEN 
							ISNULL(A.vcInternationale1, '') 
							+ CASE WHEN ISNULL(A.vcInternationale2, '') <> '' THEN SPACE(1) + A.vcInternationale2 ELSE '' END 
							+ CASE WHEN ISNULL(A.vcInternationale3, '') <> '' THEN SPACE(1) + A.vcInternationale3 ELSE '' END
						ELSE 
							CASE WHEN ISNULL(A.vcUnite, '') <> '' THEN A.vcUnite + '-' ELSE '' END
							+ CASE WHEN ISNULL(A.vcNumero_Civique, '') <> '' THEN A.vcNumero_Civique + ',' ELSE '' END
							+ CASE WHEN ISNULL(A.vcNom_Rue, '') <> '' THEN SPACE(1) + A.vcNom_Rue ELSE '' END
							+ CASE WHEN A.iID_TypeBoite = 1 AND ISNULL(A.vcBoite, '') <> '' THEN SPACE(1) + ' CP ' + A.vcBoite ELSE '' END
							+ CASE WHEN A.iID_TypeBoite = 2 AND ISNULL(A.vcBoite, '') <> '' THEN SPACE(1) + ' RR ' + A.vcBoite ELSE '' END
						END)),			
		City = A.vcVille,
		StateName = A.vcProvince,		
		CountryID = A.cID_Pays,
		CountryName = A.vcPays,
		ZipCode = A.vcCodePostal,
		Phone1 = '',
		Phone2 = '',
		Mobile = '',
		Fax = '',
		WattLine = '',
		OtherTel = '', 
		Pager = '',
		EMail = '',
		EMailProfessionnel = '',
		EMailAutre = '',
		UserName = A.vcLogin_Creation,
		InsertTime = A.dtDate_Creation
	FROM tblGENE_AdresseHistorique A
	left join Un_Rep R on A.iID_Source = R.RepID
	WHERE A.cType_Source = @AdrTypeID
		AND A.iID_Source = @HumanID
		AND iId_type = CASE isnull(R.RepCode,'') when '' then 1 else 4 END
union

SELECT
		InForce = T.dtDate_Debut,
		Address = '',
		City = '',
		StateName = '',		
		CountryID = '',
		CountryName = '',
		ZipCode = '',
		Phone1 = CASE WHEN T.bInvalide = 1
			THEN '*** Invalide *** ' 
			ELSE isnull(T.vcTelephone,'') + CASE WHEN ISNULL(T.vcExtension,'') <> '' THEN ' ' + T.vcExtension  ELSE '' END END,
		Phone2 = '',
		Mobile = '',
		Fax = '',
		WattLine = '',
		OtherTel = '', 
		Pager = '',
		EMail = '',
		EMailProfessionnel = '',
		EMailAutre = '',
		UserName = T.vcLogin_Creation,
		InsertTime = T.dtDate_Creation
	FROM tblGENE_Telephone T
	WHERE T.cType_Source = @AdrTypeID
		AND T.iID_Source = @HumanID
		AND T.iID_Type = 1
		AND T.dtDate_Debut <= @Today
union

SELECT
		InForce = T.dtDate_Debut,
		Address = '',
		City = '',
		StateName = '',		
		CountryID = '',
		CountryName = '',
		ZipCode = '',
		Phone1 = '',
		Phone2 = CASE WHEN T.bInvalide = 1
			THEN '*** Invalide *** ' 
			ELSE isnull(T.vcTelephone,'') + CASE WHEN ISNULL(T.vcExtension,'') <> '' THEN ' ' + T.vcExtension  ELSE '' END END,
		Mobile = '',
		Fax = '',
		WattLine = '',
		OtherTel = '', 
		Pager = '',
		EMail = '',
		EMailProfessionnel = '',
		EMailAutre = '',
		UserName = T.vcLogin_Creation,
		InsertTime = T.dtDate_Creation
	FROM tblGENE_Telephone T
	WHERE T.cType_Source = @AdrTypeID
		AND T.iID_Source = @HumanID
		AND T.iID_Type = 4
		AND T.dtDate_Debut <= @Today
			
union

SELECT
		InForce = T.dtDate_Debut,
		Address = '',
		City = '',
		StateName = '',		
		CountryID = '',
		CountryName = '',
		ZipCode = '',
		Phone1 = '',
		Phone2 = '',
		Mobile = CASE WHEN T.bInvalide = 1
			THEN '*** Invalide *** ' 
			ELSE isnull(T.vcTelephone,'') + CASE WHEN ISNULL(T.vcExtension,'') <> '' THEN ' ' + T.vcExtension ELSE '' END END,
		Fax = '',
		WattLine = '',
		OtherTel = '', 
		Pager = '',
		EMail = '',
		EMailProfessionnel = '',
		EMailAutre = '',
		UserName = T.vcLogin_Creation,
		InsertTime = T.dtDate_Creation
	FROM tblGENE_Telephone T
	WHERE T.cType_Source = @AdrTypeID
		AND T.iID_Source = @HumanID
		AND T.iID_Type = 2
		AND T.dtDate_Debut <= @Today
		
union

SELECT
		InForce = T.dtDate_Debut,
		Address = '',
		City = '',
		StateName = '',		
		CountryID = '',
		CountryName = '',
		ZipCode = '',
		Phone1 = '',
		Phone2 = '',
		Mobile = '',
		Fax = CASE WHEN T.bInvalide = 1
			THEN '*** Invalide *** ' 
			ELSE isnull(T.vcTelephone,'') + CASE WHEN ISNULL(T.vcExtension,'') <> '' THEN ' ' + T.vcExtension ELSE '' END END,
		WattLine = '',
		OtherTel = '', 
		Pager = '',
		EMail = '',
		EMailProfessionnel = '',
		EMailAutre = '',
		UserName = T.vcLogin_Creation,
		InsertTime = T.dtDate_Creation
	FROM tblGENE_Telephone T
	WHERE T.cType_Source = @AdrTypeID
		AND T.iID_Source = @HumanID
		AND T.iID_Type = 8
		AND T.dtDate_Debut <= @Today
union

SELECT
		InForce = T.dtDate_Debut,
		Address = '',
		City = '',
		StateName = '',		
		CountryID = '',
		CountryName = '',
		ZipCode = '',
		Phone1 = '',
		Phone2 = '',
		Mobile = '',
		Fax = '',
		WattLine = '',
		OtherTel = CASE WHEN T.bInvalide = 1
			THEN '*** Invalide *** ' 
			ELSE isnull(T.vcTelephone,'') + CASE WHEN ISNULL(T.vcExtension,'') <> '' THEN ' ' + T.vcExtension ELSE '' END END,
		Pager = '',
		EMail = '',
		EMailProfessionnel = '',
		EMailAutre = '',
		UserName = T.vcLogin_Creation,
		InsertTime = T.dtDate_Creation
	FROM tblGENE_Telephone T
	WHERE T.cType_Source = @AdrTypeID
		AND T.iID_Source = @HumanID
		AND T.iID_Type = 16
		AND T.dtDate_Debut <= @Today
union

SELECT
		InForce = C.dtDate_Debut,
		Address = '',
		City = '',
		StateName = '',		
		CountryID = '',
		CountryName = '',
		ZipCode = '',
		Phone1 = '',
		Phone2 = '',
		Mobile = '',
		Fax = '',
		WattLine = '',
		OtherTel = '', 
		Pager = '',
		EMail = CASE WHEN C.bInvalide = 1
			THEN '*** Invalide *** ' 
			ELSE isnull(C.vcCourriel,'') END,
		EMailProfessionnel = '',
		EMailAutre = '',
		UserName = C.vcLogin_Creation,
		InsertTime = C.dtDate_Creation
	FROM tblGENE_Courriel C
	WHERE C.cType_Source = @AdrTypeID
		AND C.iID_Source = @HumanID
		AND C.iID_Type = 1
		AND C.dtDate_Debut <= @Today

union

	SELECT
		InForce = C.dtDate_Debut,
		Address = '',
		City = '',
		StateName = '',		
		CountryID = '',
		CountryName = '',
		ZipCode = '',
		Phone1 = '',
		Phone2 = '',
		Mobile = '',
		Fax = '',
		WattLine = '',
		OtherTel = '', 
		Pager = '',
		EMail = '',
		EMailProfessionnel = CASE WHEN C.bInvalide = 1
			THEN '*** Invalide *** ' 
			ELSE isnull(C.vcCourriel,'') END,
		EMailAutre = '',
		UserName = C.vcLogin_Creation,
		InsertTime = C.dtDate_Creation
	FROM tblGENE_Courriel C
	WHERE C.cType_Source = @AdrTypeID
		AND C.iID_Source = @HumanID
		AND C.iID_Type = 2
		AND C.dtDate_Debut <= @Today

	union

	SELECT
		InForce = C.dtDate_Debut,
		Address = '',
		City = '',
		StateName = '',		
		CountryID = '',
		CountryName = '',
		ZipCode = '',
		Phone1 = '',
		Phone2 = '',
		Mobile = '',
		Fax = '',
		WattLine = '',
		OtherTel = '', 
		Pager = '',
		EMail = '',
		EMailProfessionnel = '',
		EMailAutre = CASE WHEN C.bInvalide = 1
			THEN '*** Invalide *** ' 
			ELSE isnull(C.vcCourriel,'') END,
		UserName = C.vcLogin_Creation,
		InsertTime = C.dtDate_Creation
	FROM tblGENE_Courriel C
	WHERE C.cType_Source = @AdrTypeID
		AND C.iID_Source = @HumanID
		AND C.iID_Type = 4
		AND C.dtDate_Debut <= @Today

						) u
order by 
	InForce DESC,
	InsertTime DESC
END
