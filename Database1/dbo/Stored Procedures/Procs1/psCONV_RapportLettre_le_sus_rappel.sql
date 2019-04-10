/****************************************************************************************************
Copyrights (c) 2011 Gestion Universitas inc.

Code du service		: psCONV_RapportLettre_le_sus_rappel
Nom du service		: Générer la lettre de rappel de suspension
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXEC psCONV_RapportLettre_le_sus_rappel 'U-20011219006,T-20140501001'
						EXEC psCONV_RapportLettre_le_sus_rappel 'X-20110406006'
						EXEC psCONV_RapportLettre_le_sus_rappel 'T-201111011164'
drop procedure psCONV_RapportLettre_le_sus_rappel

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2014-07-07		Maxime Martel						Création du service	
		
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettre_le_sus_rappel] @cConventionno varchar(max)
AS
BEGIN
	DECLARE
		@today datetime,
		@nbConv integer,
		@humanID integer,
		@nbSous integer,
		@nbRow integer
	
	set @today = GETDATE()
	SET @cConventionno = UPPER(LTRIM(RTRIM(ISNULL(@cConventionno,''))))
	
	CREATE TABLE #tbConv (
		ConvNo varchar(15) PRIMARY KEY,
		BenefNom varchar(50),
		BenefPrenom varchar(50),
		SousID integer,
		BenefID integer)

	BEGIN TRANSACTION

		INSERT INTO #tbConv (ConvNo,BenefNom,BenefPrenom,SousID,BenefID)
			SELECT t.val, B.LastName, B.FirstName, C.SubscriberID, C.BeneficiaryID
			FROM fn_Mo_StringTable(@cConventionno) t
			JOIN dbo.Un_Convention C on t.val = C.ConventionNo
			JOIN dbo.Mo_Human B on C.BeneficiaryID = B.HumanID
			
		select @nbRow = @@ROWCOUNT
		select @nbConv = COUNT(*) from fn_Mo_StringTable(@cConventionno)
		select @nbSous = COUNT(distinct t.SousID) from #tbConv t
		select top 1 @humanID = t.SousID from #tbConv t
		
	IF @nbRow <> @nbConv or @nbSous > 1
	BEGIN
		ROLLBACK TRANSACTION
		SET @humanID = 0
	END
	ELSE
		COMMIT TRANSACTION

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
		noConv = (SELECT STUFF((    SELECT ', ' + t.ConvNo + ' (' + h.FirstName + ')'  AS [text()]
                        FROM #tbConv t JOIN dbo.Un_Convention c ON t.ConvNo = c.ConventionNo JOIN dbo.Mo_Human h
						ON c.BeneficiaryID = h.HumanID  
						FOR XML PATH('')
                        ), 1, 2, '' )
					),
		PlanClassification = [dbo].[fnCONV_ObtenirDossierClient](c.SubscriberID,1) + '\' + replace(LEFT(CONVERT(VARCHAR, @today, 120), 10),'-','')
							+ case HS.langID when 'FRA' then '_le_sus_rappel' when 'ENU' then '_le_sus_rappel_ang' end
	FROM #tbConv t JOIN dbo.Un_Convention C on t.ConvNo = C.ConventionNo
	JOIN dbo.Un_Subscriber S on C.SubscriberID = S.SubscriberID
	JOIN dbo.Mo_Human HS on S.SubscriberID = HS.HumanID
	join Mo_Sex sex ON sex.SexID = HS.SexID AND sex.LangID = HS.LangID
	join dbo.fntGENE_ObtenirAdresseEnDate(@humanID,1,GETDATE(),1) A on A.iID_Source = HS.HumanID
	JOIN dbo.Mo_Human HR on S.RepID = HR.HumanID
END


