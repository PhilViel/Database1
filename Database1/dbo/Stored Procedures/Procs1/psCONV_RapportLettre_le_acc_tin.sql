/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	psCONV_RapportLettre_le_acc_tin
Description         :	psCONV_RapportLettre_le_acc_tin
					
Note                :	2013-11-08	Maxime Martel	Création
						2014-06-19	Maxime Martel	remplacer Mo_adr par la fonction pour obtenir l'adresse du
													souscripteur

						exec psCONV_RapportLettre_le_acc_tin '', 'I-20120509001', '%industri%-all%', 'G1K7M3'
						exec psCONV_RapportLettre_le_acc_tin '', 'U-20091203068', '%industri%-all%', 'G1K7M3'
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettre_le_acc_tin] (
	@ref varchar(50),
	@cConventionno varchar(15),
	@NomPromoteur varchar (75),
	@codePostalPromoteur varchar(20)
	) 	
AS
BEGIN
	declare
		@today datetime,
		@humanID integer,
		@companyID integer,
		@companyName varchar(100)
	
	set @today = GETDATE()

	SET @cConventionno = UPPER(LTRIM(RTRIM(ISNULL(@cConventionno,''))))

	select @humanID = C.subscriberID FROM dbo.Un_Convention C
	where C.ConventionNo = @cConventionno

	select top 1 @companyID = D.DepID, @companyName = C.companyName
	FROM Mo_Company C join Mo_Dep D on C.CompanyID = D.CompanyID
	join tblGENE_Adresse A on a.iID_Source = D.DepID
	WHERE 
		replace(REPLACE(ltrim(rtrim(A.vcCodePostal)),' ',''),'-','') = replace(REPLACE(ltrim(rtrim(@codePostalPromoteur)),' ',''),'-','')
		and C.CompanyName LIKE @NomPromoteur 

	SELECT 
		c.ConventionNo,
		sex.LongSexName as appelLong,
		sex.ShortSexName as appelCourt,
		HS.HumanID as idSouscripteur,
		hs.LastName as nomSouscripteur,
		hs.firstName as prenomSouscripteur,
		LangID = hs.LangID,
		hs.SexID,
		a.vcNom_Rue as Address,
		a.vcVille as City,
		ZipCode = dbo.fn_Mo_FormatZIP( a.vcCodePostal,A.cId_Pays),
		a.vcProvince as StateName,
		hb.firstName as prenomBene,
		hb.lastName as nomBene,
		hr.LastName as nomRep,
		hr.firstName as prenomRep,
		hd.LastName as nomDir,
		hd.firstName as prenomDir,
		PlanClassification = [dbo].[fnCONV_ObtenirDossierClient](c.subscriberID,1) + '\' + replace(LEFT(CONVERT(VARCHAR, @today, 120), 10),'-','')
							+ case hs.langID when 'FRA' then '_le_acc_tin' when 'ENU' then '_le_acc_tin_ang' end,
		Promoteur = @companyName,
		PromoteurAdresse = P.vcNom_Rue,
		PromoteurVille = P.vcVille,
		PromoteurProvince = P.vcProvince,
		PromoteurCodePostal = dbo.fn_Mo_FormatZIP( P.vcCodePostal,p.cId_Pays)
	FROM
		Un_Convention c
		JOIN dbo.Un_Subscriber S on C.subscriberID = S.SubscriberID 
		JOIN dbo.Mo_Human HS on S.SubscriberID = HS.HumanID
		join Mo_Sex sex ON sex.SexID = hs.SexID AND sex.LangID = hs.LangID
		JOIN dbo.mo_Human HB on C.BeneficiaryID = HB.humanID
		join dbo.fntGENE_ObtenirAdresseEnDate(@humanID,1,GETDATE(),1) A on A.iID_Source = HS.HumanID
		join un_rep r on s.RepID = r.RepID
		JOIN dbo.Mo_Human hr on hr.HumanID = r.RepID
		left JOIN dbo.Mo_human hd on hd.HumanID =
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
					AND rb.RepID = hr.HumanID
			  GROUP BY
					RB.RepID
			)
		left join dbo.fntGENE_ObtenirAdresseEnDate(@companyID,1,GETDATE(),1) P on 1=1
	WHERE c.ConventionNo = @cConventionno
END


