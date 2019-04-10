/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_Bank
Description         :	Procédure de validation d’ajout/modification d’institutions financières.
Valeurs de retours  :	Dataset :
									BankID				INTEGER			ID unique de la succursale
									BankTransit			VARCHAR(75)		Transit de la succursale
									BankTypeID			INTEGER			ID unique de l'institution financière
									BankTypeName		VARCHAR(75)		Nom de l'institution financière
									BankTypeCode		VARCHAR(75)		Code de l'institution financière
									CompanyName			VARCHAR(75)		Nom de la succursale
									LangID				CHAR(3)			Langue
									WebSite				VARCHAR(75)		Site internet
									StateTaxNumber		VARCHAR(75)		Numéro de taxe provincial.
									CountryTaxNumber	VARCHAR(75)		Numéro de taxe fédérale.
									EndBusiness			DATETIME			Date de fin des affaires.
									DepType				CHAR(1)			Un caractère désignant le type de département dont il
																				s'agit. ('U'=Inconnu, 'H'=???, 'S'=Succursale, 'A'=Adresse)
									Att					VARCHAR(75)		Nom du contact de ce département.
									AdrID					INTEGER			ID unique de l'adresse.
									InForce				DATETIME			Date d'entré en vigueur de l'adresse.
									AdrTypeID			CHAR(1)			Type d'objet auquel appartient l'adresse ('C'=Adresse de
																				compagnie, 'H'=Adresse d'individu).
									Address				VARCHAR(75)		No civique, numéro de rue et no d'appartement d'il y a lieu.
									City					VARCHAR(100)	Ville
									StateName			VARCHAR(75)		Province
									CountryID			CHAR(4)			Pays (Code)
									ZipCode				VARCHAR(10)		Code postal.
									Phone1				VARCHAR(27)		Premier numéro de téléphone.
									Phone2				VARCHAR(27)		Deuxième numéro de téléphone.
									Fax					VARCHAR(15)		Numéro de fax.
									Mobile				VARCHAR(15)		Numéro de téléphone mobile.
									WattLine				VARCHAR(27)		Numéro de téléphone sans frais.
									OtherTel				VARCHAR(27)		Autre numéro de téléphone.
									Pager					VARCHAR(15)		Numéro de pagette.
									EMail					VARCHAR(100)	Adresse courriel.
Note                :	ADX0000721	IA	2005-07-08	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_Bank] (
	@BankID INTEGER, -- ID de la succursale voulue, 0 = toutes.
	@BankTypeID INTEGER ) -- ID de l’institution financière dont on veut les succursales, 0 pour toutes.
AS
BEGIN
	SELECT
		B.BankID,
		B.BankTransit,  
		B.BankTypeID,
		BT.BankTypeName,
		BT.BankTypeCode,
		CompanyName = ISNULL(Co.CompanyName,'Unknow'),
		LangID = ISNULL(Co.LangID,'U'),
		WebSite = ISNULL(Co.WebSite,''),
		StateTaxNumber = ISNULL(Co.StateTaxNumber,''),
		CountryTaxNumber = ISNULL(Co.CountryTaxNumber,''),
		EndBusiness = dbo.FN_CRQ_IsDateNull (Co.EndBusiness),
		DepType = ISNULL(D.DepType,'U'),
		Att = ISNULL(D.Att,''),
		AdrID = ISNULL(D.AdrID,0),
		InForce = dbo.FN_CRQ_IsDateNull (A.InForce),
		AdrTypeID = ISNULL(A.AdrTypeID,'H'),
		Address = ISNULL(A.Address,''),
		City = ISNULL(A.City,''),
		StateName = ISNULL(A.StateName,''),
		CountryID = ISNULL(A.CountryID,'UNK'),
		ZipCode = ISNULL(A.ZipCode,''),
		Phone1 = ISNULL(A.Phone1,''),
		Phone2 = ISNULL(A.Phone2,''),
		Fax = ISNULL(A.Fax,''),
		Mobile = ISNULL(A.Mobile,''),
		WattLine = ISNULL(A.WattLine,''),
		OtherTel = ISNULL(A.OtherTel,''),
		Pager = ISNULL(A.Pager,''),
		EMail = ISNULL(A.EMail,'')
	FROM Mo_Bank B
	JOIN Mo_BankType BT ON BT.BankTypeID = B.BankTypeID
	LEFT JOIN Mo_Company Co ON Co.CompanyID = B.BankID
	LEFT JOIN Mo_Dep D ON D.CompanyID = Co.CompanyID AND D.DepType = 'A'
	LEFT JOIN dbo.Mo_Adr A ON A.AdrID = D.AdrID
	WHERE	( @BankID = 0
			OR @BankID = B.BankID
			)
		AND( @BankTypeID = 0
			OR @BankTypeID = BT.BankTypeID
			)
	ORDER BY 
		Co.CompanyName, 
		B.BankTransit
END


