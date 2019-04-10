/********************************************************************************************************************
Copyrights (c) 2011 Gestion Universitas inc.

Code du service		: psCONV_RapportLettre_le_acc_res_sign
Nom du service		: Générer la lettre de résiliaton le_acc_res_sign
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXEC psCONV_RapportLettre_le_nq_PAE @IDDemandePAE = 23
						EXEC psCONV_RapportLettre_le_nq_PAE @dtDateCreationDe = '2014-04-17', @dtDateCreationA = '2014-06-02', @iReimprimer = 1, @LangID='FRA'

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2013-10-10		Donald Huppé						Création du service	
		2014-06-25		Donald Huppé						Ajout du paramètre @LangID
		2014-09-08		Donald Huppé						UNDO : Changer la table DemandeHistoriqueDocument pour ImpressionDocumentDemande
		2016-05-03		Donald Huppé						JIRA PROD-1835 : Ne pas générer la lettre si Un_BENEFICIARY.bAddressLost = 1
		2017-11-16		Simon Tanguay						JIRA CRIT-236: L'avis étant maintenant envoyé au souscripteur, les informations de correspondance on été changer pour celles du souscripteur.
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettre_le_nq_PAE] 
	@IDDemandePAE int = NULL,
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

	if @IDDemandePAE is not null
		begin
		insert into @Demande values (@IDDemandePAE)
		end

	if @dtDateCreationDe is not null and @dtDateCreationA is not null
		begin
		insert into @Demande 
		SELECT IDDemande
		from DemandeHistoriqueDocument DHD
		join DemandePAE DP ON DHD.IDDemande = DP.Id -- on join sur cette table pour rammasser seulement les id de demande PAE
		--JOIN dbo.Mo_Human h on h.HumanID = dp.IdBeneficiaire
		JOIN dbo.Mo_Human hs on hs.HumanID = dp.IdSouscripteur
		where DHD.CodeTypeDocument = 'le_nq_pae'
			and LEFT(CONVERT(VARCHAR, DHD.DateCreation, 120), 10) between @dtDateCreationDe and @dtDateCreationA
			and (
				(DHD.EstEmis = 0 /*false*/ and @iReimprimer = 0 /*false*/)
				OR
				(DHD.EstEmis <> 0 /*true*/ and @iReimprimer <> 0 /*true*/)
				)
			and (hs.LangID = @LangID or @LangID is null)
		end

	DELETE TD
	FROM 
		DemandeHistoriqueDocument DHD
		JOIN DemandePAE DP ON DHD.IDDemande = DP.Id -- on join sur cette table pour rammasser seulement les id de demande PAE
		JOIN Un_Beneficiary B on B.BeneficiaryID = dp.IdBeneficiaire
		JOIN dbo.Un_Subscriber S ON S.SubscriberID = dp.IdSouscripteur
		JOIN @Demande TD ON TD.IDDemande = DHD.IDDemande
	WHERE S.AddressLost = 1

	-- Si on est par plage de date et que ce n'est pas une réimpression, on met EstEmis = 1
	if @dtDateCreationDe is not null and @dtDateCreationA is not null and isnull(@iReimprimer,0) = 0
		begin
		UPDATE DHD
		SET DHD.EstEmis = 1
		from DemandeHistoriqueDocument DHD
		JOIN DemandePAE DP ON DHD.IDDemande = DP.Id -- on join sur cette table pour rammasser seulement les id de demande PAE
		JOIN dbo.Mo_Human h on h.HumanID = dp.IdBeneficiaire
		--JOIN Un_Beneficiary B on B.BeneficiaryID = dp.IdBeneficiaire AND B.bAddressLost = 0
		where DHD.CodeTypeDocument = 'le_nq_pae' 
			and DHD.EstEmis = 0
			and LEFT(CONVERT(VARCHAR, DHD.DateCreation, 120), 10)  between @dtDateCreationDe and @dtDateCreationA
			and (h.LangID = @LangID or @LangID is null)
		end

	SELECT 
		IDDemandePAE = d.Id,
		C.SubscriberID,
		A.Address,
		a.City,
		ZipCode = dbo.fn_Mo_FormatZIP( a.ZipCode,a.countryID),
		a.StateName,
		HS.LastName AS NomSousc,
		HS.FirstName AS PrenomSousc,
		hs.LangID, -- La langue du souscripteur
		sexS.LongSexName AS appelLongSousc,
		sexS.ShortSexName AS appelCourtSousc,
		--nbConvention = @nbConv,
		subject = c.ConventionNo + CASE WHEN hs.LangID = 'ENU' THEN ' for ' ELSE ' pour ' end + hb.FirstName,
		PlanClassification = '',
		--nbSouscripteur = @nbSouscripteur,
		PrenomBenef = hb.firstname,
		C.ConventionNo,
		C.BeneficiaryID,
		NomBenef = hb.lastname,
		AdresseSousc = A.Address,
		CitySousc = isnull(A.City,''),
		ZipCodeSousc = dbo.fn_Mo_FormatZIP( a.ZipCode,a.countryID),
		StateNameSousc = isnull(A.StateName,''),
		CountrySousc = isnull(a.CountryID,''),
		AppelLongSousc = sexS.LongSexName,
		AppelCourtSousc = sexS.ShortSexName,
		IdRaisonRefus = d.IdRaisonRefus,
		RaisonRefusAutre = d.RaisonRefusAutre
		
	FROM 
		Un_Convention C 
		join DemandePAE d ON C.ConventionID = d.IdConvention
		join @Demande De ON d.Id = De.IDDemande
		JOIN dbo.Un_Subscriber S on C.subscriberID = S.SubscriberID 
		JOIN dbo.Mo_Human HS on S.SubscriberID = HS.HumanID
		JOIN dbo.Mo_Human hb ON C.BeneficiaryID = hb.HumanID
		join Mo_Sex sexS ON sexS.SexID = hs.SexID AND sexS.LangID = hs.LangID
		JOIN dbo.Mo_Adr A on HS.AdrID = A.AdrID

END