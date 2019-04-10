/****************************************************************************************************
Copyrights (c) 2014 Gestion Universitas inc.

Code du service		: psGENE_RapportStatistiqueInscriptionNouveauPortail
Nom du service		: 
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXEC psGENE_RapportStatistiqueInscriptionNouveauPortail

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2015-05-28		Donald Huppé						Création du service	glpi 14568
		2016-10-04		Donald Huppé						jira ti-4990 : utiliser la vue "vwInscriptionsPortail" afin que ce soit plus rapide
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_RapportStatistiqueInscriptionNouveauPortail] 
	--(

	--)
	
AS
BEGIN

DECLARE @SQL VARCHAR(2000)
declare @ServeurPortail varchar(255)

set @ServeurPortail = dbo.fnGENE_ObtenirParametre('GENE_BD_USER_PORTAIL', NULL, NULL, NULL, NULL, NULL, NULL) 

	SET @sql = 
		'select
			EnDateDu = GETDATE(),
			QteSouscInscrit = count(DISTINCT s.SubscriberID),
			QteSouscInscritQuiEtaitInscritAncienPortail = sum(case when s.SubscriberID is not NULL and PA.iUserId is not null then 1 else 0 end),
			QteBenefInscrit = count(DISTINCT b.BeneficiaryID),
			QteBenefInscritQuiEtaitInscritAncienPortail = sum(case when b.BeneficiaryID is not NULL and PA.iUserId is not null then 1 else 0 end)
		from '
			 + @ServeurPortail+ '.dbo.vwInscriptionsPortail U
			left join tblGENE_PortailAuthentification PA		on cast(PA.iUserId as varchar) = U.UserName
			left JOIN dbo.Un_Subscriber s							on cast(s.SubscriberID as varchar) = U.UserName
			left JOIN dbo.Un_Beneficiary b							on cast(b.BeneficiaryID as varchar) = U.UserName
		where 
			LEFT(CONVERT(VARCHAR, U.LastLoginDate, 120), 10) <> ''1900-01-01'' 
			and isnull(cast(U.comment as VARCHAR),'''') = ''''
			'


	--SET @sql = 
	--	'select
	--		EnDateDu = GETDATE(),
	--		QteSouscInscrit = count(DISTINCT s.SubscriberID),
	--		QteSouscInscritQuiEtaitInscritAncienPortail = sum(case when s.SubscriberID is not NULL and PA.iUserId is not null then 1 else 0 end),
	--		QteBenefInscrit = count(DISTINCT b.BeneficiaryID),
	--		QteBenefInscritQuiEtaitInscritAncienPortail = sum(case when b.BeneficiaryID is not NULL and PA.iUserId is not null then 1 else 0 end)
	--	from '
	--		 + @ServeurPortail+ '.dbo.profiles P
	--		join ' + @ServeurPortail+ '.dbo.Users U				on P.userId = U.userID
	--		join ' + @ServeurPortail+ '.dbo.[Memberships] m		on m.UserId = p.UserId
	--		left join tblGENE_PortailAuthentification PA		on cast(PA.iUserId as varchar) = U.UserName
	--		left JOIN dbo.Un_Subscriber s							on cast(s.SubscriberID as varchar) = U.UserName
	--		left JOIN dbo.Un_Beneficiary b							on cast(b.BeneficiaryID as varchar) = U.UserName
	--	where 
	--		LEFT(CONVERT(VARCHAR, m.LastLoginDate, 120), 10) <> ''1900-01-01'' 
	--		and isnull(cast(m.comment as VARCHAR),'''') = ''''
	--		'

	--print @sql
	exec (@sql)

END


