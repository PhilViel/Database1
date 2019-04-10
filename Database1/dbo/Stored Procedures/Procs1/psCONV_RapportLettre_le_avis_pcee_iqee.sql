/****************************************************************************************************
Copyrights (c) 2011 Gestion Universitas inc.

Code du service		: psCONV_RapportLettre_le_avis_pcee_iqee
Nom du service		: Générer la lettre le_avis_pcee_iqee
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	psCONV_RapportLettre_le_avis_pcee_iqee
						
drop procedure psCONV_RapportLettre_le_avis_pcee_iqee

exec psCONV_RapportLettre_le_avis_pcee_iqee 'U-20110418005', 'pcee'
exec psCONV_RapportLettre_le_avis_pcee_iqee 'R-20060410038', 'iqee'
Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2014-06-26		Maxime Martel						Création du service	
		
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettre_le_avis_pcee_iqee] 
@cConventionno varchar(15), @type varchar(4)
AS
BEGIN
	DECLARE
		@today datetime = GETDATE(),
		@humanID integer
	
	set @today = GETDATE()

	SET @cConventionno = UPPER(LTRIM(RTRIM(ISNULL(@cConventionno,''))))

	select @humanID = C.subscriberID FROM dbo.Un_Convention C
	where C.ConventionNo = @cConventionno

	SELECT 
		Address = A.vcNom_Rue,
		ConventionNo = C.conventionNo,
		City = A.vcVille,
		ZipCode = dbo.fn_Mo_FormatZIP( A.vcCodePostal,A.cId_Pays),
		StateName = A.vcProvince,
		NomSous = HS.LastName,
		PrenomSous = HS.FirstName,
		HumanID = HS.HumanID,
		HS.LangID,
		AppelLong = sex.LongSexName,
		AppelCourt = sex.ShortSexName,
		HS.SexID,
		NomBene = HB.LastName,
		PrenomBene = HB.firstName,
		SexBenef = HB.SexID,
		PlanClassification = [dbo].[fnCONV_ObtenirDossierClient](S.SubscriberID,1) + '\' + replace(LEFT(CONVERT(VARCHAR, @today, 120), 10),'-','')
							+ CASE HS.langID when 'FRA' then '_le_avis_' + @type when 'ENU' then '_le_avis_' + @type + '_ang' end
	FROM dbo.Un_Subscriber S 
	JOIN dbo.Mo_Human HS on S.SubscriberID = HS.HumanID
	join Mo_Sex sex ON sex.SexID = HS.SexID AND sex.LangID = HS.LangID
	join dbo.fntGENE_ObtenirAdresseEnDate(@humanID,1,GETDATE(),1) A on A.iID_Source = HS.HumanID
	JOIN dbo.Un_Convention C on C.ConventionNo = @cConventionno
	JOIN dbo.Mo_Human HB on C.BeneficiaryID = HB.HumanID
	where @type = 'pcee' or @type = 'iqee'
END


