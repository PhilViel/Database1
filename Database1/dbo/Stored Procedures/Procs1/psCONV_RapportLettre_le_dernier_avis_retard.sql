/****************************************************************************************************
Copyrights (c) 2017 Gestion Universitas inc.

Code du service		: psCONV_RapportLettre_le_dernier_avis_retard
Nom du service		: Générer la lettre de dernier avis de retard
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						@SubscriberID
						@CotisationAcombler			Montqant de cotisation à combler

Exemple d’appel		:	

EXEC psCONV_RapportLettre_le_dernier_avis_retard 673320, 215



Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2017-11-07		Donald Huppé						Création du service	
		
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettre_le_dernier_avis_retard] 
	@SubscriberID INT,
	@CotisationAcombler MONEY
AS
BEGIN
	DECLARE
		@today datetime,
		@nbConv integer,
		@humanID integer,
		@nbBenef integer,
		@nbSous integer,
		@nbRow integer
	
	set @today = GETDATE()
	
	CREATE TABLE #tbConv (
		ConventionNo varchar(15),
		BenefNom varchar(50),
		BenefPrenom varchar(50),
		SubscriberID integer,
		BeneficiaryID integer)




		INSERT INTO #tbConv (ConventionNo,BenefNom,BenefPrenom,SubscriberID,BeneficiaryID)
			SELECT c.ConventionNo, B.LastName, B.FirstName, C.SubscriberID, C.BeneficiaryID
			FROM dbo.Un_Convention C
			JOIN Un_Breaking BR	ON BR.ConventionID = C.ConventionID AND GETDATE() BETWEEN BR.BreakingStartDate AND ISNULL(BR.BreakingEndDate,'9999-12-31')
			JOIN dbo.Mo_Human B on C.BeneficiaryID = B.HumanID
			WHERE c.SubscriberID = @SubscriberID
			
		--select @nbRow = @@ROWCOUNT
		select @nbConv = COUNT(DISTINCT ConventionNo) from #tbConv
		select @nbSous = COUNT(distinct SubscriberID) from #tbConv
		select @nbBenef = COUNT(distinct BeneficiaryID) from #tbConv

		

	SELECT distinct
		humanID = C.SubscriberID,
		Adresse = ad.Address,
		Ville = ad.City,
		CodePostal = dbo.fn_Mo_FormatZIP( ad.ZipCode,ad.CountryID),
		Province = ad.StateName,
		SouscNom = HS.LastName,
		SouscPrenom = HS.FirstName,
		Langue = HS.LangID,
		appelLong = sex.LongSexName,
		appelCourt = sex.ShortSexName,
		HS.SexID,
		nomRep = HR.firstName + ' ' + HR.lastName,
		sexRep = HR.SexID,
		nbConv = @nbConv,
		nbBenef = @nbBenef,
		ProchaineDate = CAST(DATEADD(MONTH,1,@today) AS DATE),
		CotisationAcombler = @CotisationAcombler,
		SoldeFrais = ISNULL(SoldeFrais,0),
		noConv = (SELECT STUFF((    SELECT ', ' + t.ConventionNo + ' (' + h.FirstName + ')'  AS [text()]
                        FROM #tbConv t 
						JOIN dbo.Un_Convention c ON t.ConventionNo = c.ConventionNo 
						JOIN dbo.Mo_Human h	ON c.BeneficiaryID = h.HumanID  
						FOR XML PATH('')
                        ), 1, 2, '' )
					),
		PlanClassification = [dbo].[fnCONV_ObtenirDossierClient](c.SubscriberID,1) + '\' + replace(LEFT(CONVERT(VARCHAR, @today, 120), 10),'-','')
							+ case HS.langID when 'FRA' then '_le_dernier_avis_retard' when 'ENU' then '_le_dernier_avis_retard_ang' end
	FROM #tbConv t JOIN dbo.Un_Convention C on t.ConventionNo = C.ConventionNo
	JOIN dbo.Un_Subscriber S on C.SubscriberID = S.SubscriberID
	JOIN dbo.Mo_Human HS on S.SubscriberID = HS.HumanID
	join Mo_Sex sex ON sex.SexID = HS.SexID AND sex.LangID = HS.LangID
	join Mo_Adr ad on ad.AdrID = HS.AdrID
	JOIN dbo.Mo_Human HR on S.RepID = HR.HumanID
	LEFT JOIN (
		SELECT c.SubscriberID, SoldeFrais = SUM(ct.Fee)
		FROM Un_Convention C
		JOIN #tbConv t on c.ConventionNo = t.ConventionNo
		JOIN Un_Unit U ON C.ConventionID= U.ConventionID
		JOIN Un_Cotisation CT ON U.UnitID = CT.UnitID
		GROUP BY c.SubscriberID
		)F ON F.SubscriberID = t.SubscriberID
END


