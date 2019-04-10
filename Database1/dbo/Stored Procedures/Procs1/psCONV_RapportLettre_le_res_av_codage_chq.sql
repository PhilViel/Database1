/****************************************************************************************************
Copyrights (c) 2011 Gestion Universitas inc.

Code du service		: psCONV_RapportLettre_le_res_av_codage_chq
Nom du service		: Générer la lettre le_res_av_codage_chq
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	psCONV_RapportLettre_le_res_av_codage_chq
						
drop procedure psCONV_RapportLettre_le_res_av_codage_chq

exec psCONV_RapportLettre_le_res_av_codage_chq 150325 
exec psCONV_RapportLettre_le_res_av_codage_chq 149969
exec psCONV_RapportLettre_le_res_av_codage_chq 149972 

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2014-05-13		Maxime Martel						Création du service	
		2014-06-19		Maxime Martel						Remplacer mo_adr par la fonction pour obtenir l'adresse
****************************************************************************************************/
CREATE PROCEDURE dbo.psCONV_RapportLettre_le_res_av_codage_chq 
@humanID integer
AS
BEGIN
	DECLARE
		@today datetime,
		@repID int,
		@finRep date
	
	set @today = GETDATE()

	set @repID = (select RepID FROM dbo.Un_Subscriber where SubscriberID = @humanID)
	set @finRep = (select r.BusinessEnd from un_rep r where RepID = @repID)
	
	--si rep inactif repid = directeur
	if @finRep < getdate()
	begin
	set @repID =
		(SELECT
				BossID = MAX(BossID) -- au cas ou il y a 2 boss avec le même %.  alors on prend l'id le + haut. ex : repid = 497171
		FROM 
			Un_RepBossHist RB
			JOIN (
				SELECT
					RepID,
					RepBossPct = MAX(RepBossPct)
				FROM 
					Un_RepBossHist RB
				WHERE 
					RepRoleID = 'DIR'
					AND StartDate IS NOT NULL
					AND LEFT(CONVERT(VARCHAR, StartDate, 120), 10) <= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10)
					AND (EndDate IS NULL OR LEFT(CONVERT(VARCHAR, EndDate, 120), 10) >= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10)) 
				GROUP BY
					  RepID
				) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
		  WHERE RB.RepRoleID = 'DIR'
				AND RB.StartDate IS NOT NULL
				AND LEFT(CONVERT(VARCHAR, RB.StartDate, 120), 10) <= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10)
				AND (RB.EndDate IS NULL OR LEFT(CONVERT(VARCHAR, RB.EndDate, 120), 10) >= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10))
				AND RB.RepID = @repID
		  GROUP BY
				RB.RepID
				)
	end	
					
	SELECT 
		a.vcNom_Rue as Address,
		a.vcVille as City,
		ZipCode = dbo.fn_Mo_FormatZIP( a.vcCodePostal,A.cId_Pays),
		a.vcProvince as StateName,
		HS.LastName AS nomSous,
		HS.FirstName AS prenomSous,
		HS.LangID,
		
		sex.LongSexName AS appelLong,
		sex.ShortSexName AS appelCourt,
		HS.SexID,
		PlanClassification = [dbo].[fnCONV_ObtenirDossierClient](S.SubscriberID,1) + '\' + replace(LEFT(CONVERT(VARCHAR, @today, 120), 10),'-','')
							+ case HS.langID when 'FRA' then '_le_res_av_codage_chq' when 'ENU' then '_le_res_av_codage_chq_ang' end,
		Rep = HR.FirstName + ' ' + Hr.LastName,
		HR.SexID as sexRep, 
		sexRep.ShortSexName AS appelCourtRep
	FROM dbo.Un_Subscriber S 
	JOIN dbo.Mo_Human HS on S.SubscriberID = HS.HumanID
	join Mo_Sex sex ON sex.SexID = HS.SexID AND sex.LangID = HS.LangID
	join dbo.fntGENE_ObtenirAdresseEnDate(@humanID,1,GETDATE(),1) A on A.iID_Source = HS.HumanID
	JOIN dbo.Mo_Human HR on  HR.HumanID = @repID
	join Mo_Sex sexRep on sexRep.SexID = HR.SexID and sexRep.LangID = HR.LangID
	where S.SubscriberID = @humanID
		
END


