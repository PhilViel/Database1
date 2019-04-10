/****************************************************************************************************
Copyrights (c) 2011 Gestion Universitas inc.

Code du service		: psCONV_RapportLettre_le_nouvelle_emission_benef
Nom du service		: Générer la lettre le_nouvelle_emission_benef
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	psCONV_RapportLettre_le_nouvelle_emission_benef
						
drop procedure psCONV_RapportLettre_le_nouvelle_emission_benef

exec psCONV_RapportLettre_le_nouvelle_emission_benef 'X-20101203018'
exec psCONV_RapportLettre_le_nouvelle_emission_benef 'U-20091030007'

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2014-05-23		Maxime Martel						Création du service	
		
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettre_le_nouvelle_emission_benef] 
@cConventionno varchar(max)
AS
BEGIN
	DECLARE
		@today datetime,
		@humanID integer
	
	set @today = GETDATE()
	SET @cConventionno = UPPER(LTRIM(RTRIM(ISNULL(@cConventionno,''))))
	
	select @humanID = C.subscriberID FROM dbo.Un_Convention C
	where C.ConventionNo = @cConventionno
	
	SELECT distinct 
		a.vcNom_Rue as Address,
		a.vcVille as City,
		ZipCode = dbo.fn_Mo_FormatZIP( a.vcCodePostal,A.cId_Pays),
		a.vcProvince as StateName,
		HS.LastName AS nomSous,
		HS.FirstName AS prenomSous,
		S.SubscriberID,
		HS.LangID,
		sex.LongSexName AS appelLong,
		sex.ShortSexName AS appelCourt,
		HS.SexID,
		PlanClassification = [dbo].[fnCONV_ObtenirDossierClient](S.SubscriberID,1) + '\' + replace(LEFT(CONVERT(VARCHAR, @today, 120), 10),'-','')
							+ case HS.langID when 'FRA' then '_le_nouvelle_emission_benef' when 'ENU' then '_le_nouvelle_emission_benef' end,
		RR.vcDescription,
		HB.LastName as nomBenef,
		HB.FirstName as prenomBenef,
		@cConventionno as noConv				
	FROM dbo.Un_Convention C
	join Un_Plan P on C.PlanID = P.PlanID
	join tblCONV_RegroupementsRegimes RR on P.iID_Regroupement_Regime = RR.iID_Regroupement_Regime
	JOIN dbo.Un_Subscriber S on C.SubscriberID = S.SubscriberID
	JOIN dbo.Mo_Human HS on S.SubscriberID = HS.HumanID
	join Mo_Sex sex ON sex.SexID = HS.SexID AND sex.LangID = HS.LangID
	join dbo.fntGENE_ObtenirAdresseEnDate(@humanID,1,GETDATE(),1) A on A.iID_Source = HS.HumanID
	JOIN dbo.Mo_Human HB on C.BeneficiaryID = HB.HumanID
	where C.ConventionNo = @cConventionno
	
END


