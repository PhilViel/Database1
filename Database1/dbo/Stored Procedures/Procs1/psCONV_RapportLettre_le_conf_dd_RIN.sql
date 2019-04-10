/********************************************************************************************************************
Copyrights (c) 2011 Gestion Universitas inc.

Code du service		: psCONV_RapportLettre_le_conf_dd_RIN
Nom du service		: Générer la lettre de confirmation de dd de RIN
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXEC psCONV_RapportLettre_le_conf_dd_RIN @idDDD = 100044
						EXEC psCONV_RapportLettre_le_conf_dd_RIN @dtDateCreationDe = '2014-04-01', @dtDateCreationA = '2014-05-02', @iReimprimer = 1
Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2014-09-25		Donald Huppé						Création du service	
		2016-05-03		Donald Huppé						JIRA PROD-1835 : Ne pas générer la lettre si Un_SUBSCRIBER.AddressLost = 1	
		2018-02-12		Simon Tanguay						JIRA CRIT-2597 Modifier l'avis de qualification d'un RIN (Ajout du champ SexBenef)
		2018-11-08		Maxime Martel						Utilisation de planDesc_ENU de la table plan
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettre_le_conf_dd_RIN] 
	@idDDD int = NULL,
	@dtDateCreationDe datetime = NULL,
	@dtDateCreationA datetime = NULL,
	@LangID varchar(3) = NULL,
	@iReimprimer int = 1
AS
BEGIN

	declare @tDDD table (IdDDD int)

	if @idDDD is not null
		begin
		insert into @tDDD values (@idDDD)
		end

	if @dtDateCreationDe is not null and @dtDateCreationA is not null
		begin
		insert into @tDDD 
		SELECT DISTINCT 
			DDD.Id
		from 
			DemandeHistoriqueDocument DHD
			join DemandeRIN DP ON DHD.IDDemande = DP.Id
			join DecaissementDepotDirect DDD ON DHD.IDDemande = DDD.IdDemande
			JOIN dbo.Mo_Human h on h.HumanID = DDD.IdDestinataire
		where 
			DHD.CodeTypeDocument = 'le_conf_dd_rin'
			
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
		join DemandeRIN DP ON DHD.IDDemande = DP.Id
		join DecaissementDepotDirect DDD ON DHD.IDDemande = DDD.IdDemande
		JOIN @tDDD TD ON TD.IdDDD = DDD.Id
		JOIN Un_Subscriber S on S.SubscriberID = DDD.IdDestinataire
	WHERE S.AddressLost = 1

	-- Si on est par plage de date et que ce n'est pas une réimpression, on met EstEmis = 1
	if @dtDateCreationDe is not null and @dtDateCreationA is not null and isnull(@iReimprimer,0) = 0
		begin
		UPDATE DHD
		SET DHD.EstEmis = 1
		from DemandeHistoriqueDocument DHD
		join DemandeRIN DP ON DHD.IDDemande = DP.Id
		join DecaissementDepotDirect DDD ON DHD.IDDemande = DDD.IdDemande
		JOIN dbo.Mo_Human h on h.HumanID = DDD.IdDestinataire
		JOIN Un_Subscriber S on S.SubscriberID = DDD.IdDestinataire AND S.AddressLost = 0
		where DHD.CodeTypeDocument = 'le_conf_dd_rin'
			and DHD.EstEmis = 0
			and LEFT(CONVERT(VARCHAR, DHD.DateCreation, 120), 10)  between @dtDateCreationDe and @dtDateCreationA
			and (h.LangID = @LangID or @LangID is null)
		end

	SELECT DISTINCT
		c.ConventionNo,
		LangID = hs.LangID, -- La langue du souscripteur
		c.SubscriberID,
		PrenomSousc = HS.FirstName,
		NomSousc = HS.LastName,		
		AdresseSousc = A.Address,
		CitySousc = A.City,
		ZipCodeSousc = dbo.fn_Mo_FormatZIP(A.ZipCode,a.countryid),
		StateNameSousc = A.StateName,
		CountrySousc = a.CountryID,
		AppelLongSousc = sex.LongSexName,
		AppelCourtSousc = sex.ShortSexName,
		C.BeneficiaryID,
		PrenomBenef = hb.firstname,
		NomBenef = hb.lastname,		
		SexBenef = hb.SexID,
		O.OperID,
		IdDDD = DDD.Id,
		MontantDDD = DDD.Montant,
		PlanDesc = CASE 
				WHEN hs.LangID = 'ENU' THEN p.PlanDesc_ENU
				ELSE p.PlanDesc 
				END
		,DateDecaissement = isnull( DDD.DateDecaissement,GETDATE())
		,p.OrderOfPlanInReport

	FROM 
		Un_Convention c 
		join Un_Plan p ON c.PlanID = p.PlanID
		JOIN dbo.Un_Subscriber Su on C.subscriberID = Su.SubscriberID 
		JOIN dbo.Mo_Human HS on Su.SubscriberID = HS.HumanID
		JOIN dbo.Mo_Human hb ON C.BeneficiaryID = hb.HumanID
		join Mo_Sex sex ON sex.SexID = hs.SexID AND sex.LangID = hs.LangID
		JOIN dbo.Mo_Adr A on HS.AdrID = A.AdrID
		JOIN dbo.Mo_Adr Ab on Hb.AdrID = Ab.AdrID
		join Mo_Sex sexB ON sexb.SexID = hb.SexID AND sexb.LangID = hb.LangID
		JOIN dbo.Un_Unit u On c.ConventionID = u.ConventionID
		join Un_Cotisation ct on u.UnitID = ct.UnitID
		join Un_Oper o ON ct.OperID = o.OperID and o.OperTypeID = 'RIN'
		join DecaissementDepotDirect DDD on DDD.IdOperationFinanciere = o.OperID
		join @tDDD td on td.IdDDD = DDD.Id
	ORDER BY p.OrderOfPlanInReport,HS.LastName,HS.FirstName

end