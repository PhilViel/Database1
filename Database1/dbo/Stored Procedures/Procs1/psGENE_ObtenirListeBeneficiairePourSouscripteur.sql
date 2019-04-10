/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psGENE_ObtenirListeBeneficiairePourSouscripteur
Nom du service		: Obtenir la liste des bénéficiaires pour un souscripteur
But 				: Obtenir la liste des bénéficiaires pour un souscripteur
Facette				: GENE
Référence			: Noyau-GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				@iIDSubscriber				Identifiant du souscripteur
							
Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------

Exemple utilisation:																					
	- Obtenir la liste des bénéficiaires
		EXEC psGENE_ObtenirListeBeneficiairePourSouscripteur 606191
	
TODO:
	
Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2011-04-21		Eric Michaud						Création du service	
****************************************************************************************************/
CREATE procedure [dbo].[psGENE_ObtenirListeBeneficiairePourSouscripteur]
	@iIDSubscriber INT

AS
BEGIN
	SET NOCOUNT ON;

	SELECT DISTINCT
		iID = Be.BeneficiaryId, 
		vcNom = hu.lastname,
		vcPrenom = hu.firstname,
		vcAdresse = ad.address,
		vcVille = ad.city,
		vcProvince = ad.StateName,
		vcPays = co.CountryName,
		vcCodePostal = Case when co.CountryName = 'Canada' then left(REPLACE(ad.zipcode,' ', ''),3)+ ' ' + right(REPLACE(ad.zipcode,' ', ''),3) else ad.zipcode end,
		vcTelephone =  CASE when ad.CountryId IN ('CAN','USA') then '(' + SUBSTRING(ad.Phone1,1,3) + ') ' + SUBSTRING(ad.Phone1,4,3) + '-' + SUBSTRING(ad.Phone1,7,4) + CASE WHEN len(ad.Phone1) > 10 THEN ' Ext: ' + SUBSTRING(ad.Phone1,11,20) ELSE '' END else ad.Phone1 end,
		vcLienParente = unre.vcRelationshipType,
		vcRI= coalesce((SELECT distinct 1
						FROM dbo.Un_Unit U
						join  Un_Convention UC on u.ConventionID = UC.ConventionID
						WHERE UC.subscriberID = @iIDSubscriber AND Be.BeneficiaryId = UC.BeneficiaryID AND U.IntReimbDate IS not null),0)
	FROM dbo.Un_Subscriber Su 
					JOIN dbo.Un_Convention unCon on unCon.subscriberid = su.SubscriberId
					JOIN un_RelationshipType unre on unre.tiRelationshipTypeID = unCon.tiRelationshipTypeID
					JOIN dbo.Un_Beneficiary Be on unCon.BeneficiaryId = Be.BeneficiaryId 
					JOIN dbo.mo_Human Hu on Be.BeneficiaryId = hu.humanId
					left JOIN dbo.Mo_Adr ad on Hu.AdrId = ad.adrId
					left join mo_Country co on ad.CountryId = co.CountryId
	WHERE Su.subscriberID = @iIDSubscriber
	--ORDER BY vcRI

END


