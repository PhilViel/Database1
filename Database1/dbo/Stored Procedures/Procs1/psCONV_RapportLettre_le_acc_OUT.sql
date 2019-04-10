/****************************************************************************************************
Copyrights (c) 2011 Gestion Universitas inc.

Code du service		: psCONV_RapportLettre_le_acc_OUT
Nom du service		: Générer la lettre de résiliaton le_acc_acc_OUT
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXEC psCONV_RapportLettre_le_acc_OUT '2037998,U-20011219005,U-20011219006', '2013-10-10', 'TOTO'
						EXEC psCONV_RapportLettre_le_acc_OUT 'X-20130712006', '2013-10-02'
drop procedure psCONV_RapportLettre_le_acc_OUT

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2013-11-28		Donald Huppé						Création du service	
		2013-12-03		Donald Huppé						Enlever le paramètre de date	
		2013-12-10		Donald Huppé						Mettre out en minuscule dans PlanClassification
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettre_le_acc_OUT] 
	@cConventionno varchar(max), 
	--@date date,
	@NomPromoteur varchar (75)
AS
BEGIN
	DECLARE
		@nbSouscripteur integer,
		@nbBeneficiaire integer,
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

		SELECT @nbBeneficiaire = count(DISTINCT c.BeneficiaryID)
		FROM dbo.Un_Convention c join #tbConv t ON c.ConventionNo = t.ConvNo 
		
	end
	else
	BEGIN
		set @nbSouscripteur = 0
	END

	SELECT DISTINCT
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
		Frais = ISNULL(Frais,0),
		@nbConv AS nbConvention,
		subject = (SELECT STUFF((    SELECT ', ' + t.ConvNo  + ' (' + h.firstName + ')' AS [text()]
                        FROM #tbConv t JOIN dbo.Un_Convention c ON t.ConvNo = c.ConventionNo JOIN dbo.Mo_Human h
						ON c.BeneficiaryID = h.HumanID  
						FOR XML PATH('')
                        ), 1, 2, '' )
					),
		date = @today,
		DateDansUnMois = CASE 
						when datepart(dw, DATEADD(m,1,@today )) =1 THEN DATEADD(d,-2,DATEADD(m,1,@today ) ) -- dimanche
						when datepart(dw, DATEADD(m,1,@today )) =7 THEN DATEADD(d,-1,DATEADD(m,1,@today ) ) -- samedi
						ELSE DATEADD(m,1,@today )end,
		PhraseIQEE = CASE WHEN a.StateName = 'QC' OR isnull(IQEE.mntIQEE,0) > 0 then 1 ELSE 0 END,
		Promoteur = @NomPromoteur,
		PlanClassification = [dbo].[fnCONV_ObtenirDossierClient](c.subscriberID,1) + '\' + replace(LEFT(CONVERT(VARCHAR, @today, 120), 10),'-','')
							+ case hs.langID when 'FRA' then '_le_acc_out' when 'ENU' then '_le_acc_out_ang' end
		,nbBeneficiaire = @nbBeneficiaire
		,sex.SexID
	FROM #tbConv t JOIN dbo.Un_Convention C on t.ConvNo = C.ConventionNo
	JOIN dbo.Un_Subscriber S on C.subscriberID = S.SubscriberID 
	JOIN dbo.Mo_Human HS on S.SubscriberID = HS.HumanID
	join Mo_Sex sex ON sex.SexID = hs.SexID AND sex.LangID = hs.LangID
	JOIN dbo.Mo_Adr A on HS.AdrID = A.AdrID
	left JOIN (
		select 
			c.SubscriberID, Frais = sum(ct.Fee)
		from 
			Un_Convention c
			JOIN dbo.Un_Unit u ON c.ConventionID = u.ConventionID
			join Un_Cotisation ct ON u.UnitID = ct.UnitID
			join Un_Oper o on ct.OperID = o.OperID
			join #tbConv t ON t.ConvNo = c.ConventionNo
		GROUP by c.SubscriberID
		) F on F.SubscriberID = C.SubscriberID
	left JOIN (
		SELECT c1.ConventionID, mntIQEE = SUM(co.ConventionOperAmount)
		FROM dbo.Un_Convention c1
		join Un_ConventionOper co ON c1.ConventionID = co.ConventionID
		join un_oper o on co.OperID= o.OperID
		join #tbConv t ON t.ConvNo = c1.ConventionNo
		where co.ConventionOperTypeID IN ('CBQ','MMQ','ICQ','III','IIQ','IMQ','IQI','MIM')
		group by c1.ConventionID
		)IQEE ON IQEE.ConventionID = C.ConventionID

END


