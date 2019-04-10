/****************************************************************************************************
Copyrights (c) 2011 Gestion Universitas inc.

Code du service		: psCONV_RapportLettre_le_qual_2brs
Nom du service		: Générer la lettre de qualification le_qual_2brs
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXEC psCONV_RapportLettre_le_qual_2brs 'U-20011219006,T-201311011782,T-20140501001', 2
						EXEC psCONV_RapportLettre_le_qual_2brs 'X-20110406006', 1
						EXEC psCONV_RapportLettre_le_qual_2brs 'T-201111011164', 1
drop procedure psCONV_RapportLettre_le_qual_2brs

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2014-05-02		Maxime Martel						Création du service	
		
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettre_le_qual_2brs] @cConventionno varchar(max), @nbPAE integer
AS
BEGIN
	DECLARE
		@today datetime,
		@nbConv integer,
		@nbBenef integer,
		@humanID integer,
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
		select @nbBenef = COUNT(distinct t.BenefID) from #tbConv t
		select top 1 @humanID = t.BenefID from #tbConv t
		
	IF @nbRow <> @nbConv or @nbBenef > 1
	BEGIN
		ROLLBACK TRANSACTION
		SET @humanID = 0
	END
	ELSE
		COMMIT TRANSACTION

	SELECT distinct
		@nbBenef AS nbBenef,
		C.BeneficiaryID AS idBenef,
		a.vcNom_Rue as Address,
		a.vcVille as City,
		ZipCode = dbo.fn_Mo_FormatZIP( a.vcCodePostal,A.cId_Pays),
		a.vcProvince as StateName,
		HB.LastName AS nomBenef,
		HB.FirstName AS prenomBenef,
		HB.LangID,
		sex.LongSexName AS appelLong,
		sex.ShortSexName AS appelCourt,
		HB.SexID,
		@nbConv AS nbConvention,
		noConv = (SELECT STUFF((    SELECT ', ' + t.ConvNo AS [text()]
                        FROM #tbConv t JOIN dbo.Un_Convention c ON t.ConvNo = c.ConventionNo JOIN dbo.Mo_Human h
						ON c.BeneficiaryID = h.HumanID  
						FOR XML PATH('')
                        ), 1, 2, '' )
					),
		PlanClassification = [dbo].[fnCONV_ObtenirDossierClient](c.BeneficiaryID,1) + '\' + replace(LEFT(CONVERT(VARCHAR, @today, 120), 10),'-','')
							+ case HB.langID when 'FRA' then '_le_qual_2brs' when 'ENU' then '_le_qual_2brs_ang' end
	FROM #tbConv t JOIN dbo.Un_Convention C on t.ConvNo = C.ConventionNo
	JOIN dbo.Un_Beneficiary B on C.BeneficiaryID = B.BeneficiaryID 
	JOIN dbo.Mo_Human HB on B.BeneficiaryID = HB.HumanID
	join Mo_Sex sex ON sex.SexID = HB.SexID AND sex.LangID = HB.LangID
	join dbo.fntGENE_ObtenirAdresseEnDate(@humanID,1,GETDATE(),1) A on A.iID_Source = HB.HumanID
END


