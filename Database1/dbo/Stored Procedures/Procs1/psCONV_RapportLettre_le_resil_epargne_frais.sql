/****************************************************************************************************
Copyrights (c) 2017 Gestion Universitas inc.

Code du service		: psCONV_RapportLettre_le_resil_epargne_frais (remplace psConv_RapportLettreResiliation_08)
Nom du service		: Générer la lettre de résiliaton avec épargne et frais
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXEC psCONV_RapportLettre_le_resil_epargne_frais '2037998,U-20011219005,U-20011219006'
						EXEC psCONV_RapportLettre_le_resil_epargne_frais 'R-20050225003,R-20050225005'

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2017-08-21		Donald Huppé						Création du service
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettre_le_resil_epargne_frais] @conv varchar(max)
AS
BEGIN
	DECLARE
		@nbSouscripteur integer,
		@nbConvListe integer,
		@nbConv integer,
		@today datetime
		
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

	SELECT 
		@nbSouscripteur AS nbSouscripteur,
		sum(Co.Fee) AS montantFrais,
		sum(Co.Cotisation) AS montantÉpargnes,
		C.SubscriberID AS idSouscripteur,
		HR.LastName AS nomRep,
		HR.FirstName AS prenomRep,
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
		subject = (SELECT STUFF((    SELECT ', ' + t.ConvNo  + ' (' + h.firstName + ')' AS [text()]
                        FROM #tbConv t JOIN dbo.Un_Convention c ON t.ConvNo = c.ConventionNo JOIN dbo.Mo_Human h
						ON c.BeneficiaryID = h.HumanID  
						FOR XML PATH('')
                        ), 1, 2, '' )
					),
		PlanClassification = [dbo].[fnCONV_ObtenirDossierClient](c.subscriberID,1) + '\' + replace(LEFT(CONVERT(VARCHAR, @today, 120), 10),'-','') + '_le_resil_epargne'
		,SexRep = hr.SexID
	FROM #tbConv t JOIN dbo.Un_Convention C on t.ConvNo = C.ConventionNo
	JOIN dbo.Un_Unit U on C.ConventionID =  U.ConventionID 
	join Un_Cotisation Co on U.UnitID = Co.UnitID
	JOIN dbo.Un_Subscriber S on C.subscriberID = S.SubscriberID 
	JOIN dbo.Mo_Human HR on S.RepID = HR.HumanID
	JOIN dbo.Mo_Human HS on S.SubscriberID = HS.HumanID
	join Mo_Sex sex ON sex.SexID = hs.SexID AND sex.LangID = hs.LangID
	JOIN dbo.Mo_Adr A on HS.AdrID = A.AdrID
	group by C.SubscriberID, HR.LastName, HR.FirstName, a.address, a.City, a.ZipCode, 
	a.StateName, HS.LastName, HS.FirstName, sex.LongSexName, sex.ShortSexName, hs.LangID, a.CountryID
	,hr.SexID
END


