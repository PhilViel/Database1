/****************************************************************************************************
Copyrights (c) 2011 Gestion Universitas inc.

Code du service		: psCONV_RapportLettre_le_cbn_annul
Nom du service		: Générer la lettre le_cbn_annul
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	psCONV_RapportLettre_le_cbn_annul
						
drop procedure psCONV_RapportLettre_le_cbn_annul

exec psCONV_RapportLettre_le_cbn_annul 'X-20110406006'
exec psCONV_RapportLettre_le_cbn_annul 'T-201111011164'
exec psCONV_RapportLettre_le_cbn_annul '0960625,0960633,0960641'

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2014-06-10		Maxime Martel						Création du service	
		
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettre_le_cbn_annul] 
@cConventionNo varchar(max)
AS
BEGIN
	DECLARE
		@today datetime,
		@nbConv integer,
		@nbSous integer,
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
		select @nbSous = COUNT(distinct t.SousID) from #tbConv t
		select @nbBenef = COUNT(distinct t.BenefID) from #tbConv t
		select top 1 @humanID = t.SousID from #tbConv t
		
	IF @nbRow <> @nbConv or @nbSous > 1
	BEGIN
		ROLLBACK TRANSACTION
		SET @humanID = 0
	END
	ELSE
		COMMIT TRANSACTION

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
		humanID = @humanID,
		nbBenef = @nbBenef,
		nbConv = @nbConv,
		sexeBenef = (select top 1 h.SexID from #tbConv t JOIN dbo.Mo_Human H on t.BenefID = h.HumanID),
		reference = (SELECT STUFF((    SELECT ', ' + t.ConvNo + ' (' + t.BenefPrenom +  + ' ' + t.BenefNom + ')' AS [text()]
                        FROM #tbConv t
						FOR XML PATH('')
                        ), 1, 2, '' )),
        listeBenef = 
						CASE WHEN @nbBenef > 1 then 
						(SELECT STUFF((    SELECT ', ' + t.BenefPrenom +  + ' ' + t.BenefNom AS [text()]
                        FROM #tbConv t
						FOR XML PATH('')), 1, 2, '' )) 
						ELSE (select top 1 t.BenefPrenom +  + ' ' + t.BenefNom from #tbConv t) end,
        listeConv = (SELECT STUFF((    SELECT ', ' + t.ConvNo AS [text()]
                        FROM #tbConv t
                        ORDER BY t.ConvNo
						FOR XML PATH('')
                        ), 1, 2, '' )),
		PlanClassification = [dbo].[fnCONV_ObtenirDossierClient](S.SubscriberID,1) + '\' + replace(LEFT(CONVERT(VARCHAR, @today, 120), 10),'-','')
							+ case HS.langID when 'FRA' then '_le_cbn_annul' when 'ENU' then '_le_cbn_annul_ang' end
	FROM dbo.Un_Subscriber S 
	JOIN dbo.Mo_Human HS on S.SubscriberID = HS.HumanID
	join Mo_Sex sex ON sex.SexID = HS.SexID AND sex.LangID = HS.LangID
	join dbo.fntGENE_ObtenirAdresseEnDate(@humanID,1,GETDATE(),1) A on A.iID_Source = HS.HumanID
		
END


