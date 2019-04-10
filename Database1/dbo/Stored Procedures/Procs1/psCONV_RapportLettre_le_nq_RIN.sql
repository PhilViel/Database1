/********************************************************************************************************************
Copyrights (c) 2011 Gestion Universitas inc.

Code du service		: psCONV_RapportLettre_le_nq_RIN
Nom du service		: Générer la lettre de non qualification RIN
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXEC psCONV_RapportLettre_le_nq_RIN @IDDemandeRIN = 203
						EXEC psCONV_RapportLettre_le_nq_RIN @dtDateCreationDe = '2014-02-17', @dtDateCreationA = '2014-06-24', @iReimprimer = 0, @LangID = 'ENU'
Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2014-04-23		Donald Huppé						Création du service	
		2014-06-25		Donald Huppé						Ajout du paramètre @LangID
		2014-09-08		Donald Huppé						UNDO : Changer la table DemandeHistoriqueDocument pour ImpressionDocumentDemande
		2016-05-03		Donald Huppé						JIRA PROD-1835 : Ne pas générer la lettre si Un_SUBSCRIBER.AddressLost = 1	
		2016-06-20		Donald Huppé						JIRA TI-3691 : Correction suite au JIRA PROD-1835
			
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettre_le_nq_RIN] 
	@IDDemandeRIN int = NULL,
	@dtDateCreationDe datetime = NULL,
	@dtDateCreationA datetime = NULL,
	@LangID varchar(3) = NULL,
	@iReimprimer int = 0
AS
BEGIN
	DECLARE
		@nbSouscripteur integer,
		@nbConvListe integer,
		@nbConv integer,
		@today datetime

	declare @Demande table (IDDemande int)		
	
	set @today = GETDATE()

	if @IDDemandeRIN is not null
		begin
		insert into @Demande values (@IDDemandeRIN)
		end

	if @dtDateCreationDe is not null and @dtDateCreationA is not null
		begin
		insert into @Demande 
		SELECT IDDemande
		from DemandeHistoriqueDocument DHD
		join DemandeRIN DP ON DHD.IDDemande = DP.Id -- on join sur cette table pour rammasser seulement les id de demande RIN
		JOIN dbo.Mo_Human h on h.HumanID = dp.IdSouscripteur
		where DHD.CodeTypeDocument = 'le_nq_rin'
			and LEFT(CONVERT(VARCHAR, DHD.DateCreation, 120), 10) between @dtDateCreationDe and @dtDateCreationA
			and (
				(DHD.EstEmis = 0 /*false*/ and @iReimprimer = 0 /*false*/)
				OR
				(DHD.EstEmis <> 0 /*true*/ and @iReimprimer <> 0 /*true*/)
				)
			and (h.LangID = @LangID or @LangID is null)

		end

	DELETE TD
	FROM 
		DemandeHistoriqueDocument DHD
		JOIN DemandeRIN DP ON DHD.IDDemande = DP.Id -- on join sur cette table pour rammasser seulement les id de demande RIN
		JOIN dbo.Mo_Human h on h.HumanID = dp.IdSouscripteur
		JOIN Un_Subscriber S ON S.SubscriberID = DP.IdSouscripteur
		JOIN @Demande TD ON TD.IDDemande = DHD.IDDemande
	WHERE S.AddressLost = 1

	-- Si on est par plage de date et que ce n'est pas une réimpression, on met EstEmis = 1
	if @dtDateCreationDe is not null and @dtDateCreationA is not null and @iReimprimer = 0
		begin
		UPDATE DHD
		SET DHD.EstEmis = 1
		from DemandeHistoriqueDocument DHD
		JOIN DemandeRIN DP ON DHD.IDDemande = DP.Id -- on join sur cette table pour rammasser seulement les id de demande RIN
		JOIN dbo.Mo_Human h on h.HumanID = dp.IdSouscripteur
		JOIN Un_Subscriber S ON S.SubscriberID = DP.IdSouscripteur AND S.AddressLost = 0
		WHERE DHD.CodeTypeDocument = 'le_nq_rin'
			and DHD.EstEmis = 0
			and LEFT(CONVERT(VARCHAR, DHD.DateCreation, 120), 10)  between @dtDateCreationDe and @dtDateCreationA
			and (h.LangID = @LangID or @LangID is null)
		end

	SELECT 
		IDDemandeRIN = d.Id,
		C.SubscriberID,
		A.Address,
		a.City,
		ZipCode = dbo.fn_Mo_FormatZIP( a.ZipCode,a.countryID),
		a.StateName,
		HS.LastName AS nomSouscripteur,
		HS.FirstName AS prenomSouscripteur,
		LangID = hs.LangID,
		sex.LongSexName AS appelLong,
		sex.ShortSexName AS appelCourt,
		subject = c.ConventionNo + CASE WHEN hs.LangID = 'ENU' THEN ' for ' ELSE ' pour ' end + hb.FirstName,
		PlanClassification = '',--non utilisé
		PrenomBenef = hb.firstname,
		C.ConventionNo,
		C.BeneficiaryID,
		NomBenef = hb.lastname,
		AdresseBenef = Ab.Address,
		CityBenef = Ab.City,
		ZipCodeBenef = Ab.ZipCode,
		StateNameBenef = Ab.StateName,
		CountryBenef = ab.CountryID,
		AppelLongBenef = sexb.LongSexName,
		AppelCourtBenef = sexB.ShortSexName,
		IdRaisonRefus = d.IdRaisonRefus,
		RaisonRefusAutre = d.RaisonRefusAutre
		
	FROM 
		Un_Convention C 
		join DemandeRIN d ON C.ConventionID = d.IdConvention
		join @Demande De ON d.Id = De.IDDemande --or d.Id in (203,204,205) -- pour test plusieurs id
		JOIN dbo.Un_Subscriber S on C.subscriberID = S.SubscriberID 
		JOIN dbo.Mo_Human HS on S.SubscriberID = HS.HumanID
		JOIN dbo.Mo_Human hb ON C.BeneficiaryID = hb.HumanID
		join Mo_Sex sex ON sex.SexID = hs.SexID AND sex.LangID = hs.LangID
		JOIN dbo.Mo_Adr A on HS.AdrID = A.AdrID
		JOIN dbo.Mo_Adr Ab on Hb.AdrID = Ab.AdrID
		join Mo_Sex sexB ON sexb.SexID = hb.SexID AND sexb.LangID = hb.LangID

END


