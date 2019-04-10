/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_CHQSuggestionMostUse
Description         :	Procédure retournant la proposition de modification de chèque prédéfinie.
Valeurs de retours  :	Dataset :
									iHumanID				INTEGER			ID de l’humain qui sera le destinataire du chèque
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
Note                :	ADX0000693	IA	2005-05-17	Bruno Lapointe		Création
								ADX0000754	IA	2005-10-04	Bruno Lapointe		Modification
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_CHQSuggestionMostUse] 
AS
BEGIN
	SELECT
		M.iHumanID, -- ID de l’humain qui sera le destinataire du chèque
		H.FirstName, -- Prénom du destinataire
		H.OrigName, -- Nom à la naissance
		H.Initial, -- Initial (Jr, Sr, etc.)
		H.LastName, -- Nom
		BirthDate = dbo.fn_Mo_IsDateNull(H.BirthDate), -- Date de naissance
		DeathDate = dbo.fn_Mo_IsDateNull(H.DeathDate), -- Date du décès
		H.SexID, -- Sexe (code)
		H.LangID, -- Langue (code)
		H.CivilID, -- Statut civil (code)
		H.SocialNumber, -- Numéro d’assurance sociale
		H.ResidID, -- Pays de résidence (code)
		ResidName = R.CountryName, -- Pays de résidence
		H.DriverLicenseNo, -- Numéro de permis
		H.WebSite, -- Site internet
		H.CompanyName, -- Nom de compagnie
		H.CourtesyTitle, -- Titre de courtoisie (Docteur, Professeur, etc.)
		H.UsingSocialNumber, -- Droit d’utiliser le NAS.
		H.SharePersonalInfo, -- Droit de partager les informations personnelles
		H.MarketingMaterial, -- Veux recevoir le matériel publicitaire.
		H.IsCompany, -- Compagny ou humain
		A.InForce, -- Date d’entrée en vigueur de l’adresse.
		A.AdrTypeID, -- Type d’adresse (H = humain, C = Compagnie)
		A.SourceID, -- ID de l’objet auquel appartient l’adresse (HumanID ou CompanyID)
		A.Address, -- # civique, rue et # d’appartement.
		A.City, -- Ville
		A.StateName, -- Province
		A.CountryID, -- Pays (code)
		C.CountryName, -- Pays
		A.ZipCode, -- Code postal
		Phone1 = dbo.fn_Mo_FormatPhoneNo(A.Phone1, A.CountryID), -- Tél. résidence
		Phone2 = dbo.fn_Mo_FormatPhoneNo(A.Phone2, A.CountryID), -- Tél. bureau
		Fax = dbo.fn_Mo_FormatPhoneNo(A.Fax, A.CountryID), -- Fax
		Mobile = dbo.fn_Mo_FormatPhoneNo(A.Mobile, A.CountryID), -- Tél. cellulaire
		WattLine = dbo.fn_Mo_FormatPhoneNo(A.WattLine, A.CountryID), -- Tél. sans frais
		OtherTel = dbo.fn_Mo_FormatPhoneNo(A.OtherTel, A.CountryID), -- Autre téléphone.
		Pager = dbo.fn_Mo_FormatPhoneNo(A.Pager, A.CountryID), -- Paget
		A.Email -- Courriel
	FROM Un_CHQSuggestionMostUse M
	JOIN dbo.Mo_Human H ON H.HumanID = M.iHumanID
	LEFT JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
	LEFT JOIN Mo_Country R ON R.CountryID = H.ResidID
	LEFT JOIN Mo_Country C ON C.CountryID = A.CountryID
END


