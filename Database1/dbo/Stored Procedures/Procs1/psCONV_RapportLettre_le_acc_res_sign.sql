/****************************************************************************************************
Copyrights (c) 2011 Gestion Universitas inc.

Code du service		: psCONV_RapportLettre_le_acc_res_sign
Nom du service		: Générer la lettre de résiliaton le_acc_res_sign
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXEC psCONV_RapportLettre_le_acc_res_sign '2037998,U-20011219005,U-20011219006', '2013-10-02'
						EXEC psCONV_RapportLettre_le_acc_res_sign 'X-20110406006', '2014-03-20'
drop procedure psCONV_RapportLettre_le_acc_res_sign

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2013-10-10		Donald Huppé						Création du service	
		2014-03-20		Donald Huppé						Enlever "where ct.Fee > 0" dans calcul des frais
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettre_le_acc_res_sign] @cConventionno varchar(max), @date date
AS
BEGIN
	DECLARE
		@nbSouscripteur integer,
		@nbConvListe integer,
		@nbConv integer,
		@today datetime
		
	set @today = GETDATE()

	SET @cConventionno = UPPER(LTRIM(RTRIM(ISNULL(@cConventionno,''))))

	CREATE TABLE #tbConv (
		ConvNo varchar(15) PRIMARY KEY)

	INSERT INTO #tbConv (ConvNo)
		SELECT Val
		FROM fn_Mo_StringTable(@cConventionno)

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

	SELECT 
		@nbSouscripteur AS nbSouscripteur,
		C.SubscriberID AS idSouscripteur,
		A.Address,
		a.City,
		ZipCode = dbo.fn_Mo_FormatZIP( a.ZipCode,a.countryID),
		a.StateName,
		HS.LastName AS nomSouscripteur,
		HS.FirstName AS prenomSouscripteur,
		hs.LangID,
		sex.LongSexName AS appelLong,
		sex.ShortSexName AS appelCourt,
		QteUnite = isnull(qu.QteUnite,0),
		Frais = ISNULL(Frais,0),
		@nbConv AS nbConvention,
		subject = (SELECT STUFF((    SELECT ', ' + t.ConvNo  + ' (' + h.firstName + ')' AS [text()]
                        FROM #tbConv t JOIN dbo.Un_Convention c ON t.ConvNo = c.ConventionNo JOIN dbo.Mo_Human h
						ON c.BeneficiaryID = h.HumanID  
						FOR XML PATH('')
                        ), 1, 2, '' )
					),
		date = @date,
		PlanClassification = [dbo].[fnCONV_ObtenirDossierClient](c.subscriberID,1) + '\' + replace(LEFT(CONVERT(VARCHAR, @today, 120), 10),'-','')
							+ case hs.langID when 'FRA' then '_le_acc_res_sign' when 'ENU' then '_le_acc_res_sign_ang' end
	FROM #tbConv t JOIN dbo.Un_Convention C on t.ConvNo = C.ConventionNo
	JOIN dbo.Un_Subscriber S on C.subscriberID = S.SubscriberID 
	JOIN dbo.Mo_Human HS on S.SubscriberID = HS.HumanID
	join Mo_Sex sex ON sex.SexID = hs.SexID AND sex.LangID = hs.LangID
	JOIN dbo.Mo_Adr A on HS.AdrID = A.AdrID
	left join (
		select c.SubscriberID, QteUnite = sum(u.UnitQty + ISNULL(r.QteRes,0))
		FROM dbo.Un_Convention c
		JOIN dbo.Un_Unit u ON c.ConventionID = u.ConventionID
		join #tbConv t ON t.ConvNo = c.ConventionNo
		left JOIN (
			SELECT u.UnitID, QteRes = sum(ur.UnitQty) 
			from Un_UnitReduction ur
			JOIN dbo.Un_Unit u ON ur.UnitID = u.UnitID
			JOIN dbo.Un_Convention c ON u.ConventionID = c.ConventionID
			join #tbConv t ON t.ConvNo = c.ConventionNo
			GROUP by u.UnitID
			)r ON u.UnitID = r.UnitID
		GROUP by c.SubscriberID
		)qu ON qu.SubscriberID = C.SubscriberID
	left JOIN (
		select 
			c.SubscriberID, Frais = sum(ct.Fee)
		from 
			Un_Convention c
			JOIN dbo.Un_Unit u ON c.ConventionID = u.ConventionID
			join Un_Cotisation ct ON u.UnitID = ct.UnitID
			join Un_Oper o on ct.OperID = o.OperID
			join #tbConv t ON t.ConvNo = c.ConventionNo
		--where ct.Fee > 0
		GROUP by c.SubscriberID
		) F on F.SubscriberID = C.SubscriberID
	group by 
		C.SubscriberID, a.address, a.City, a.ZipCode, 
		a.StateName, HS.LastName, HS.FirstName, sex.LongSexName, sex.ShortSexName, hs.LangID, a.CountryID,qu.QteUnite,Frais

END


