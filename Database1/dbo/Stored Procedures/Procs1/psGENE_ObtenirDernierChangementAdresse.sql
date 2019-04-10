/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psGENE_ObtenirDernierChangementAdresse
Nom du service		: Obtenir le dernier changement d'adresse du client
But 				: Obtenir le dernier changement d'adresse du client
Facette				: GENE
Référence			: Noyau-GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				@iID						Identifiant du client
							
Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------

Exemple utilisation:																					
	- Obtenir l'adresse
		EXEC psGENE_ObtenirDernierChangementAdresse 606191
	
TODO:
	
Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2011-04-21		Eric Michaud						Création du service	
****************************************************************************************************/
CREATE procedure [dbo].[psGENE_ObtenirDernierChangementAdresse]
	@iID INT

AS
BEGIN
	SET NOCOUNT ON;

	SELECT DISTINCT
		vcNo_Civique = r.vcNo_Civique,
		vcRue = r.vcRue,
		vcNo_Appartement = r.vcNo_Appartement,
		vcType_Rue = r.vcType_Rue,
		vcCase_Postale = r.vcCase_Postale,	
		vcRoute_Rurale = r.vcRoute_Rurale,	
		vcVille = ad.city,
		vcProvince = ad.StateName,
		vcPaysCode = rtrim(ad.CountryId),
		vcPays = co.CountryName,
		vcCodePostal = Case when co.CountryName = 'Canada' then left(REPLACE(ad.zipcode,' ', ''),3)+ ' ' + right(REPLACE(ad.zipcode,' ', ''),3) else ad.zipcode end,
		vcDate = LEFT(CONVERT(VARCHAR, ad.InForce, 120), 10),
		vcPhone1 = ad.Phone1,
		vcPhone2 = ad.Phone2,
		vcMobile = ad.Mobile
	--	vcTelephone = '(' + SUBSTRING(ad.Phone1,1,3) + ') ' + SUBSTRING(ad.Phone1,4,3) + '-' + SUBSTRING(ad.Phone1,7,4) + CASE WHEN len(ad.Phone1) > 10 THEN ' Ext: ' + SUBSTRING(ad.Phone1,11,20) ELSE '' END
	FROM dbo.mo_Human Hu 
		left JOIN dbo.Mo_Adr ad on hu.humanId = ad.sourceID
		left join mo_Country co on ad.CountryId = co.CountryId
		CROSS APPLY dbo.fntGENE_ObtenirElementsAdresse(ad.address,CASE when ad.CountryId IN ('CAN','USA') then 1 else 0 end) AS r
	WHERE hu.humanId = @iID  
	--	  AND datediff(dd,getdate(),ad.InForce)>= 1 
		  AND ad.AdrID = (SELECT max(ad.AdrID)
								FROM dbo.mo_Human Hu 
								left JOIN dbo.Mo_Adr ad on hu.humanId = ad.sourceID
								WHERE  hu.humanId = @iID)
END


