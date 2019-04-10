/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_ExternalPromo
Description         :	Procédure qui renvoi la liste des promoteurs externes
Valeurs de retours  :	Dataset :
							ExternalPromoID		INTEGER			ID du promoteur externe
							CompanyName			VARCHAR(75)		Nom du promoteur externe
							LangID				CHAR(3)			ID de la langue
							WebSite				VARCHAR(75)		Site web du promoteur
							EndBusiness			DATETIME		Date de fermeture du promoteur externe
							AdrID				INTEGER			ID de l’adresse du promoteur
							CountryID			INTEGER			ID du pays
							AdrTypeID			INTEGER			ID du type d’adresse
							Address				VARCHAR(75)		Adresse du promoteur
							City				VARCHAR(100)	Ville
							StateName			VARCHAR(75)		État/Province
							ZipCode				VARCHAR(10)		Code postal ou zip code
							Phone1 				VARCHAR(27)		Premier téléphone
							Phone2				VARCHAR(27)		Second téléphone
							Fax					VARCHAR(15)		Fax
							Mobile				VARCHAR(15)		Cellulaire
							WattLine			VARCHAR(27)	
							OtherTel			VARCHAR(27)		Autre téléphone
							Pager				VARCHAR(15)		Paget
							Email				VARCHAR(100)	Courriel
							Att					VARCHAR(75)		Nom du premier contact
							Att2				VARCHAR(75)		Nom du second contact
				
Note                :	ADX0001159	IA	2007-02-09	Alain Quirion		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_ExternalPromo](
	@ExternalPromoID INTEGER) -- ID du promoteur externe (0=tous)
AS
BEGIN
	SELECT 
			EP.ExternalPromoID,	--ID du promoteur externe
			C.CompanyName,		--Nom du promoteur externe
			C.LangID,			--ID de la langue
			C.WebSite,			--Site web du promoteur
			C.EndBusiness,		--Date de fermeture du promoteur externe
			A.AdrID,			--ID de l’adresse du promoteur
			A.CountryID,		--ID du pays
			A.AdrTypeID,		--ID du type d’adresse
			A.Address,			--Adresse du promoteur
			A.City,				--Ville
			A.StateName,		--État/Province
			A.ZipCode,			--Code postal ou zip code
			A.Phone1,			--Premier téléphone
			A.Phone2,			--Second téléphone
			A.Fax,				--Fax
			A.Mobile,			--Cellulaire
			A.WattLine,			--Téléphone sans frais
			A.OtherTel,			--Autre téléphone
			A.Pager,			--Paget
			A.Email,			--Courriel
			D.Att,				--Nom du premier contact
			D.Att2				--Nom du second contact			
	FROM Un_ExternalPromo EP
	JOIN Mo_Company C ON C.CompanyID = EP.ExternalPromoID	
	JOIN Mo_Dep D ON D.CompanyID = C.CompanyID
	JOIN dbo.Mo_Adr A ON A.AdrID = D.AdrID
	WHERE @ExternalPromoID = ExternalPromoID
			OR @ExternalPromoID = 0
	ORDER BY C.CompanyName
END


