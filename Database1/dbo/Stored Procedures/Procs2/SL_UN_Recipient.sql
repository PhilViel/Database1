/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_Recipient
Description         :	Procédure de rafraîchissement de destinataire.
Valeurs de retours  :	Dataset :
									iRecipientID		INTEGER			ID du destinataire, correspond au HumanID.
									FirstName			VARCHAR(35)		Prénom du destinataire
									OrigName				VARCHAR(50)		Nom à la naissance
									Initial				VARCHAR(4)		Initial (Jr, Sr, etc.)
									LastName				VARCHAR(50)		Nom
									BirthDate			DATETIME			Date de naissance
									DeathDate			DATETIME			Date du décès
									SexID					CHAR(1)			Sexe (code)
									LangID				CHAR(3)			Langue (code)
									CivilID				CHAR(1)			Statut civil (code)
									SocialNumber		VARCHAR(75)		Numéro d’assurance sociale
									ResidID				CHAR(3)			Pays de résidence (code)
									ResidName			VARCHAR(75)		Pays de résidence
									DriverLicenseNo	VARCHAR(75)		Numéro de permis
									WebSite				VARCHAR(75)		Site internet
									CompanyName			VARCHAR(75)		Nom de compagnie
									CourtesyTitle		VARCHAR(35)		Titre de courtoisie (Docteur, Professeur, etc.)
									UsingSocialNumber	BIT				Droit d’utiliser le NAS.
									SharePersonalInfo	BIT				Droit de partager les informations personnelles
									MarketingMaterial	BIT				Veux recevoir le matériel publicitaire.
									IsCompany			BIT				Compagny ou humain
									InForce				DATETIME			Date d’entrée en vigueur de l’adresse.
									AdrTypeID			CHAR(1)			Type d’adresse (H = humain, C = Compagnie)
									SourceID	 			INTEGER			ID de l’objet auquel appartient l’adresse (HumanID ou CompanyID)
									Address				VARCHAR(75)		# civique, rue et # d’appartement.
									City					VARCHAR(100)	Ville
									StateName			VARCHAR(75)		Province
									CountryID			CHAR(3)			Pays (code)
									CountryName			VARCHAR(75)		Pays
									ZipCode				VARCHAR(10)		Code postal
									Phone1				VARCHAR(27)		Tél. résidence
									Phone2				VARCHAR(27)		Tél. bureau
									Fax					VARCHAR(15)		Fax
									Mobile				VARCHAR(15)		Tél. cellulaire
									WattLine				VARCHAR(27)		Tél. sans frais
									OtherTel				VARCHAR(27)		Autre téléphone.
									Pager					VARCHAR(15)		Paget
									Email					VARCHAR(100)	Courriel
Note                :	ADX0000754	IA	2005-10-04	Bruno Lapointe		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_Recipient] (
	@iRecipientID INTEGER ) -- ID du destinataire voulu, correspond au HumanID.
AS
BEGIN
	SELECT
		T.iRecipientID,
		H.FirstName,
		H.OrigName,
		H.Initial,
		H.LastName,
		BirthDate = dbo.fn_Mo_IsDateNull(H.BirthDate),
		DeathDate = dbo.fn_Mo_IsDateNull(H.DeathDate),
		H.SexID,
		H.LangID,
		H.CivilID,
		H.SocialNumber,
		H.ResidID,
		H.DriverLicenseNo,
		H.WebSite,
		H.CompanyName,
		H.CourtesyTitle,
		H.UsingSocialNumber,
		H.SharePersonalInfo,
		H.MarketingMaterial,
		H.IsCompany,
		SourceID = A.AdrID,
		A.AdrTypeID,
		A.InForce,
		A.Address,
		A.City,
		A.StateName,
		A.CountryID,
		A.ZipCode,
		Phone1 = dbo.fn_Mo_FormatPhoneNo(A.Phone1, A.CountryID),
		Phone2 = dbo.fn_Mo_FormatPhoneNo(A.Phone2, A.CountryID),
		Fax = dbo.fn_Mo_FormatPhoneNo(A.Fax, A.CountryID),
		Mobile = dbo.fn_Mo_FormatPhoneNo(A.Mobile, A.CountryID),
		WattLine = dbo.fn_Mo_FormatPhoneNo(A.WattLine, A.CountryID),
		OtherTel = dbo.fn_Mo_FormatPhoneNo(A.OtherTel, A.CountryID),
		Pager = dbo.fn_Mo_FormatPhoneNo(A.Pager, A.CountryID),
		A.EMail,
		ResidName = R.CountryName,
		C.CountryName
	FROM Un_Recipient T
	JOIN dbo.Mo_Human H ON H.HumanID = T.iRecipientID
	LEFT JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
	LEFT JOIN Mo_Country R ON R.CountryID = H.ResidID
	LEFT JOIN Mo_Country C ON C.CountryID = A.CountryID
	WHERE T.iRecipientID = @iRecipientID
END


