/****************************************************************************************************
Copyrights (c) 2011 Gestion Universitas inc.

Code du service		: psCONV_RapportLettre_BBaVenir (à partir de psConv_RapportLettre_PostDate)
Nom du service		: Générer la lettre BB à venir
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXEC psCONV_RapportLettre_BBaVenir 'U-20091215048, X-20110518004'
						EXEC psCONV_RapportLettre_BBaVenir 'R-20050225003,R-20050225005'
						EXEC psCONV_RapportLettre_BBaVenir '2037998'

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2013-08-09		Maxime Martel						Création du service			
		2013-09-25		Maxime Martel						Ajout du plan de classification
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettre_BBaVenir] @conv varchar(max)
AS
BEGIN
	DECLARE
		@nbSouscripteur integer,
		@nbConvListe integer,
		@nbConv integer,
		@listeBenef varchar(max),
		@today datetime,
		@premierConvention varchar(30)
	
	set @today = GETDATE()
	SET @conv = UPPER(LTRIM(RTRIM(ISNULL(@conv,''))))

	CREATE TABLE #tbConv (
		ConvNo varchar(15) PRIMARY KEY)

	INSERT INTO #tbConv (ConvNo)
		SELECT Val
		FROM fn_Mo_StringTable(@conv)

	SELECT @nbConvListe = count(*) FROM #tbConv
	select @nbConv = count(*) FROM dbo.Un_Convention c join #tbConv t ON c.ConventionNo = t.ConvNo

	if @nbConvListe = @nbConv
	begin
		SELECT @nbSouscripteur = count(DISTINCT c.SubscriberID)
		FROM dbo.Un_Convention c join #tbConv t ON c.ConventionNo = t.ConvNo 
	end
	else
	BEGIN
		set @nbSouscripteur = 0
	END

	-- replace chaque enregistrement sur une seul ligne 
	-- fonction stuff permet de remplacer un ou des caractères à un endroit dans la string

	SELECT @listeBenef = STUFF((    SELECT distinct ', ' + h.FirstName AS [text()]
                        FROM #tbConv t JOIN dbo.Un_Convention c ON t.ConvNo = c.ConventionNo JOIN dbo.Mo_Human h
						ON c.BeneficiaryID = h.HumanID  
						FOR XML PATH('') 
                        ), 1, 2, '' )

	select top 1 @premierConvention = ConvNo from #tbConv

	SELECT distinct
		@nbSouscripteur AS nbSouscripteur, 
		mois = (select top 1 month(min(u.inforceDate)) from #tbConv t JOIN dbo.Un_Convention c on t.ConvNo = c.ConventionNo
				JOIN dbo.Un_Unit u on c.ConventionID = u.ConventionID),
		C.SubscriberID AS idSouscripteur,
		hr.SexID,
		A.Address,
		a.City,
		ZipCode = dbo.fn_Mo_FormatZIP( a.ZipCode,a.countryID),
		a.StateName,
		HS.LastName AS nomSouscripteur,
		HS.FirstName AS prenomSouscripteur,
		hs.LangID,
		sex.LongSexName AS appelLong,
		sex.ShortSexName AS appelCourt,
		@nbConv AS nbConvention,
		subject = (SELECT STUFF((    SELECT ', ' + t.ConvNo  + ' (' + 
										case when p1.iID_Regroupement_Regime = 1 and LangID = 'ENU' then
											'Universitas'
										when p1.iID_Regroupement_Regime = 2 and LangID = 'ENU' then
											'Reflex'
										when p1.iID_Regroupement_Regime = 3 and LangID = 'ENU' then
											'Individual'
										when p1.iID_Regroupement_Regime = 1 and LangID <> 'ENU' then
											'Universitas'
										when p1.iID_Regroupement_Regime = 2 and LangID <> 'ENU' then
											'Reeeflex'
										when p1.iID_Regroupement_Regime = 3 and LangID <> 'ENU' then
											'Individuel' end
										  + ')' AS [text()]
                        FROM #tbConv t 
                        JOIN dbo.Un_Convention c1 ON t.ConvNo = c1.ConventionNo 
                        join Un_Plan p1 on c1.PlanID = p1.planID
                        JOIN dbo.Mo_Human h
						ON c1.SubscriberID = h.HumanID  
						FOR XML PATH('')
                        ), 1, 2, '' )
					),
		listeBenef =	isnull((select stuff(@listeBenef, LEN(@listeBenef) - 
						CHARINDEX(',', REVERSE(@listeBenef), 1 + 1) + 1, 1, ' et' )
						), @listeBenef),
		PlanClassification = [dbo].[fnCONV_ObtenirDossierClient](c.subscriberID,1) + '\' + replace(LEFT(CONVERT(VARCHAR, @today, 120), 10),'-','') + '_le_acc_bb_' + @premierConvention  
	FROM #tbConv t JOIN dbo.Un_Convention C on t.ConvNo = C.ConventionNo
	join Un_Plan p on c.PlanID = p.planID
	JOIN dbo.Un_Subscriber S on C.subscriberID = S.SubscriberID 
	JOIN dbo.Mo_Human HR on S.RepID = HR.HumanID
	JOIN dbo.Mo_Human HS on S.SubscriberID = HS.HumanID
	join Mo_Sex sex ON sex.SexID = hs.SexID AND sex.LangID = hs.LangID
	JOIN dbo.Mo_Adr A on HS.AdrID = A.AdrID
	group by c.ConventionNo, C.SubscriberID, HR.SexID, a.address, a.City, a.ZipCode, 
	a.StateName, HS.LastName, HS.FirstName, sex.LongSexName, sex.ShortSexName, hs.LangID, a.CountryID, p.iID_Regroupement_Regime
END


