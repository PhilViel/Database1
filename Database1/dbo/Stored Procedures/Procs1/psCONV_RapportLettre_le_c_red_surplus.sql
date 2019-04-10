/****************************************************************************************************
Copyrights (c) 2011 Gestion Universitas inc.

Code du service		: psCONV_RapportLettre_le_c_red_surplus
Nom du service		: Générer la lettre résiliation d'unités 
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	
			EXEC psCONV_RapportLettre_le_c_red_surplus 'X-20101203018,U-20110418005'
			EXEC psCONV_RapportLettre_le_c_red_surplus	'U-20050419032,U-20050222033,U-20050419034,U-20050222034'
drop procedure psCONV_RapportLettre_le_c_red_surplus

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2014-08-12		Maxime Martel						Création du service	
		
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettre_le_c_red_surplus] @cConventionno varchar(max)
AS
BEGIN
	DECLARE
		@today datetime,
		@nbConv integer,
		@humanID integer,
		@nbSous integer,
		@nbRow integer,
		@repID int,
		@finRep date,
		@nbNas integer
	
	set @today = GETDATE()
	SET @cConventionno = UPPER(LTRIM(RTRIM(ISNULL(@cConventionno,''))))
	
	CREATE TABLE #tbConv (
		ConvNo varchar(15) PRIMARY KEY,
		BenefNom varchar(50),
		BenefPrenom varchar(50),
		SousID integer,
		BenefID integer,
		NAS bit)

	BEGIN TRANSACTION

		INSERT INTO #tbConv (ConvNo,BenefNom,BenefPrenom,SousID,BenefID, NAS)
			SELECT t.val, B.LastName, B.FirstName, C.SubscriberID, C.BeneficiaryID,
			CASE WHEN B.SocialNumber IS NOT NULL then 1 else 0 end
			FROM fn_Mo_StringTable(@cConventionno) t
			JOIN dbo.Un_Convention C on t.val = C.ConventionNo
			JOIN dbo.Mo_Human B on C.BeneficiaryID = B.HumanID
			
		select @nbRow = @@ROWCOUNT
		select @nbConv = COUNT(*) from fn_Mo_StringTable(@cConventionno)
		select @nbSous = COUNT(distinct t.SousID) from #tbConv t
		select top 1 @humanID = t.SousID from #tbConv t
		select @nbNas = COUNT(distinct t.BenefID) from #tbConv t where NAS = 0
		
	IF @nbRow <> @nbConv or @nbSous > 1
	BEGIN
		ROLLBACK TRANSACTION
		SET @humanID = 0
	END
	ELSE
		COMMIT TRANSACTION
	
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

	SELECT distinct
		humanID = C.SubscriberID,
		Address = a.vcNom_Rue,
		City = a.vcVille,
		ZipCode = dbo.fn_Mo_FormatZIP( a.vcCodePostal,A.cId_Pays),
		StateName = a.vcProvince,
		nomSous = HS.LastName,
		prenomSous = HS.FirstName,
		HS.LangID,
		appelLong = sex.LongSexName,
		appelCourt = sex.ShortSexName,
		HS.SexID,
		nomRep = HR.firstName + ' ' + HR.lastName,
		sexRep = HR.SexID,
		nbConv = @nbConv,
		noConv = (SELECT STUFF((    SELECT ', ' + t.ConvNo + ' (' + t.BenefPrenom + ')' AS [text()]
                        FROM #tbConv t
                        ORDER BY t.BenefPrenom
						FOR XML PATH('')
                        ), 1, 2, '' ))
					,
		listePrenom = (SELECT STUFF((    SELECT distinct ', ' + t.BenefPrenom AS [text()]
                        FROM #tbConv t
                        where NAS = 0
						FOR XML PATH('')
                        ), 1, 2, '' )),
        listePrenomAng = (SELECT STUFF((    SELECT distinct ', ' + t.BenefPrenom + '''s' AS [text()]
                        FROM #tbConv t
                        where NAS = 0
						FOR XML PATH('')
                        ), 1, 2, '' )),
		NbNasManquant = @nbNas,
		sexBenef = (select top 1 H.SexID from #tbConv t JOIN dbo.Mo_Human H on t.BenefID = h.HumanID),
		PlanClassification = [dbo].[fnCONV_ObtenirDossierClient](c.SubscriberID,1) + '\' + replace(LEFT(CONVERT(VARCHAR, @today, 120), 10),'-','')
							+ case HS.langID when 'FRA' then '_le_c_red_surplus' when 'ENU' then '_le_c_red_surplus_ang' end
	FROM #tbConv t JOIN dbo.Un_Convention C on t.ConvNo = C.ConventionNo
	JOIN dbo.Un_Subscriber S on C.SubscriberID = S.SubscriberID
	JOIN dbo.Mo_Human HS on S.SubscriberID = HS.HumanID
	join Mo_Sex sex ON sex.SexID = HS.SexID AND sex.LangID = HS.LangID
	join dbo.fntGENE_ObtenirAdresseEnDate(@humanID,1,GETDATE(),1) A on A.iID_Source = HS.HumanID
	JOIN dbo.Mo_Human HR on  HR.HumanID = @repID
END


