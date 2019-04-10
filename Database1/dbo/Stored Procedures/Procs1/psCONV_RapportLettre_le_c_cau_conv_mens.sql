/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	psCONV_RapportLettre_le_c_cau_conv_mens
Description         :	psCONV_RapportLettre_le_c_cau_conv_mens
					
Note                :	2014-06-25	Maxime Martel	Création
						
exec psCONV_RapportLettre_le_c_cau_conv_mens 'I-20120509001'
exec psCONV_RapportLettre_le_c_cau_conv_mens 'U-20110418005'
exec psCONV_RapportLettre_le_c_cau_conv_mens 'X-20130415004'
exec psCONV_RapportLettre_le_c_cau_conv_mens 'R-20060410038'
						
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettre_le_c_cau_conv_mens] (
	@cConventionno varchar(15)
	) 	
AS
BEGIN
	declare
		@today datetime,
		@humanID integer
	
	set @today = GETDATE()

	SET @cConventionno = UPPER(LTRIM(RTRIM(ISNULL(@cConventionno,''))))

	select @humanID = C.subscriberID FROM dbo.Un_Convention C
	where C.ConventionNo = @cConventionno

	SELECT 
		c.ConventionNo,
		appelLong = sex.LongSexName,
		appelCourt = sex.ShortSexName,
		humanID = HS.HumanID,
		nomSous = hs.LastName,
		prenomSous = hs.firstName,
		jourPmt = DAY(c.firstPmtDate),
		regime = UPPER(p.PlanDesc),
		regimeANG = CASE p.PlanDesc 
			when 'Reeeflex' then 'REFLEX' 
			when 'Individuel' then 'INDIVIDUAL' 
			ELSE UPPER(p.planDesc) end, 
		LangID = hs.LangID,
		hs.SexID,
		Address = a.vcNom_Rue,
		a.vcVille as City,
		ZipCode = dbo.fn_Mo_FormatZIP( a.vcCodePostal,A.cId_Pays),
		a.vcProvince as StateName,
		hb.firstName as prenomBene,
		hb.lastName as nomBene,
		PlanClassification = [dbo].[fnCONV_ObtenirDossierClient](c.subscriberID,1) + '\' + replace(LEFT(CONVERT(VARCHAR, @today, 120), 10),'-','')
							+ case hs.langID when 'FRA' then '_le_c_cau_conv_mens' when 'ENU' then '_le_c_cau_conv_mens_ang' end
	FROM
		Un_Convention c
		JOIN dbo.Un_Subscriber S on C.subscriberID = S.SubscriberID 
		JOIN dbo.Mo_Human HS on S.SubscriberID = HS.HumanID
		join Mo_Sex sex ON sex.SexID = hs.SexID AND sex.LangID = hs.LangID
		JOIN dbo.mo_Human HB on C.BeneficiaryID = HB.humanID
		join dbo.fntGENE_ObtenirAdresseEnDate(@humanID,1,GETDATE(),1) A on A.iID_Source = HS.HumanID
		join Un_Plan P on C.PlanID = P.PlanID
	WHERE c.ConventionNo = @cConventionno and c.PmtTypeID = 'AUT'
END


