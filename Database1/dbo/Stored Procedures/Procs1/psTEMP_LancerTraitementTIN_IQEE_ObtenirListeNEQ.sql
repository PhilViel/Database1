/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psTEMP_LancerTraitementTIN_IQEE_ObtenirListeNEQ
Nom du service		: Procedure pour obtenir la liste des Numéro d'entreprise du Québec (NEQ) 
					  dans l'outil de traitement d'IQEE TIN
But 				: 
Facette				: TEMP

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------


Exemple d’appel		:	

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2016-04-20		Maxime Martel						Création du service		
			


exec psTEMP_LancerTraitementTIN_IQEE_Total 

***********************************************************************************************************************/

CREATE PROCEDURE [dbo].[psTEMP_LancerTraitementTIN_IQEE_ObtenirListeNEQ] 
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
			D.Att2,				--Nom du second contact	
			CAST(Ep.vcneq as varchar) + ' (' + c.companyName + ')' as NEQ 	-- neq + (nom de l'entreprise) 
	FROM Un_ExternalPromo EP
	JOIN Mo_Company C ON C.CompanyID = EP.ExternalPromoID	
	JOIN Mo_Dep D ON D.CompanyID = C.CompanyID
	JOIN dbo.Mo_Adr A ON A.AdrID = D.AdrID
	WHERE ep.vcneq is not null
	ORDER BY C.CompanyName

END
