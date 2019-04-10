/****************************************************************************************************
Copyrights (c) 2011 Gestion Universitas inc.

Code du service		: psCONV_RapportLettre_le_c_change_profil_invest
Nom du service		: Générer la lettre le_c_change_profil_invest
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						SubscriberID				Identifiant de l'humain (souscripteur)

Exemple d’appel		:	exec psCONV_RapportLettre_le_c_change_profil_invest 149972 
exec psCONV_RapportLettre_le_c_change_profil_invest 601617
						
drop procedure psCONV_RapportLettre_le_c_change_profil_invest

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2015-07-06		Maxime Martel						Création du service	
		
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettre_le_c_change_profil_invest] 
@SubscriberID integer
AS
BEGIN
	DECLARE
		@today datetime,
		@repID int,
		@finRep date,
		@businessEndDir date

	set @today = GETDATE()
	
	set @repID = (select RepID FROM dbo.Un_Subscriber where SubscriberID = @SubscriberID)
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
				AND RB.EndDate IS NULL
				AND LEFT(CONVERT(VARCHAR, RB.StartDate, 120), 10) <= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10)
				AND (RB.EndDate IS NULL OR LEFT(CONVERT(VARCHAR, RB.EndDate, 120), 10) >= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10))
				AND RB.RepID = @repID
		  GROUP BY
				RB.RepID
				)	
		set @businessEndDir = (select r.BusinessEnd from un_Rep r where r.repId = @repID)
		if @businessEndDir is not null 
		begin
			set @repID = (select h.humanid FROM dbo.Mo_Human h where h.FirstName = 'Siège' and h.LastName = 'Social')
		end

	end	
	
	select ConventionNo as convNo into #tbConv 
	FROM dbo.Un_Convention C
	where C.SubscriberID = @SubscriberID
	
	SELECT
		s.SubscriberID,
		a.vcNom_Rue as Address,
		a.vcVille as City,
		nbConv = (select count(convNo) from #tbConv),
		ZipCode = dbo.fn_Mo_FormatZIP(a.vcCodePostal,A.cId_Pays),
		a.vcProvince as StateName,
		HS.LastName AS nomSous,
		HS.FirstName AS prenomSous,
		HS.LangID,
		sex.LongSexName AS appelLong,
		sex.ShortSexName AS appelCourt,
		HS.SexID,
		noConv = (SELECT STUFF((    SELECT ', ' + t.ConvNo + ' (' + h.FirstName + ')' AS [text()]
                        FROM #tbConv t JOIN dbo.Un_Convention c ON t.ConvNo = c.ConventionNo JOIN dbo.Mo_Human h
						ON c.BeneficiaryID = h.HumanID
						ORDER BY H.FirstName
						FOR XML PATH('')
                        ), 1, 2, '' )),
		PlanClassification = [dbo].[fnCONV_ObtenirDossierClient](S.SubscriberID,1) + '\' + replace(LEFT(CONVERT(VARCHAR, @today, 120), 10),'-','')
							+ case HS.langID when 'FRA' then '_le_c_change_profil_invest' when 'ENU' then '_le_c_change_profil_invest_ang' end,
		Rep = HR.FirstName + ' ' + Hr.LastName,
		HR.SexID as sexRep, 
		sexRep.ShortSexName AS appelCourtRep,
		ps.DateCueilletteDonnees,
		t.vcTelephone,
		RepID = hr.HumanID
	FROM dbo.Un_Subscriber S 
	JOIN dbo.Mo_Human HS on S.SubscriberID = HS.HumanID
	join Mo_Sex sex ON sex.SexID = HS.SexID AND sex.LangID = HS.LangID
	join dbo.fntGENE_ObtenirAdresseEnDate(@SubscriberID,1,GETDATE(),1) A on A.iID_Source = HS.HumanID
	JOIN dbo.Mo_Human HR on  HR.HumanID = @repID
	join Mo_Sex sexRep on sexRep.SexID = HR.SexID and sexRep.LangID = HR.LangID
	join (
		SELECT DateCueilletteDonnees, iID_Souscripteur 
		FROM tblCONV_ProfilSouscripteur WHERE (iID_Profil_Souscripteur) IN 
			( SELECT MAX(iID_Profil_Souscripteur)
			  FROM tblCONV_ProfilSouscripteur
			  where iID_Souscripteur = @SubscriberID
			  GROUP BY iID_Souscripteur
			)
	) ps on ps.iID_Souscripteur = s.SubscriberID
	left join (
		select t.vcTelephone, t.iID_Source, t.vcExtension from tblgene_telephone t
		where t.iID_Type = 4 and t.dtDate_Fin is null
		and t.iID_Source = @repID
	) t on t.iID_Source = @repID
	where S.SubscriberID = @SubscriberID
END


