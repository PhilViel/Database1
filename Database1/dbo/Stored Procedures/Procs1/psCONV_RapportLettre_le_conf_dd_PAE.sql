/********************************************************************************************************************
Copyrights (c) 2011 Gestion Universitas inc.

Code du service		: psCONV_RapportLettre_le_conf_dd_PAE
Nom du service		: Générer la lettre de conf de DD de PAE
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXEC psCONV_RapportLettre_le_conf_dd_PAE @idDDD = 53810, @iHumanDestLettreID = 415638
						EXEC psCONV_RapportLettre_le_conf_dd_PAE @vcCodeTypeDocument = 'le_conf_dd_pae_col', @dtDateCreationDe = '2018-01-01', @dtDateCreationA = '2018-06-26', @iReimprimer = 0,@LangID ='fra'

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2014-09-26		Donald Huppé						Création du service	
		2016-05-03		Donald Huppé						JIRA PROD-1835 : Ne pas générer la lettre si Un_BENEFICIARY.bAddressLost = 1
		2017-11-23		Simon Tanguay						JIRA CRIT-298 : Gérer les destinataires de la lettre
        2017-12-12      Pierre-Luc Simard                   Ajout du compte RST dans le compte BRS
		2017-12-15		Simon Tanguay						CRIT-1462 Lettre de qualification - Affichage du TIN
		2018-02-19		Donald Huppé						Quand DHD.iHumanDestLettreID est NULL, alors on prend dp.IdBeneficiaire pour faire le JOIN (afin gérer les vieux cas quand c'était toujours le benef)
		2018-11-08		Maxime Martel						Utilisation de planDesc_ENU de la table plan
        2018-11-26		Maxime Martel						Écrire le nom du plan en fonction de la langue du destinataire
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettre_le_conf_dd_PAE] 
	@idDDD INT = NULL,
	@vcCodeTypeDocument VARCHAR(25) = NULL,
	@dtDateCreationDe DATETIME = NULL,
	@dtDateCreationA DATETIME = NULL,
	@LangID VARCHAR(3) = NULL,
	@iReimprimer INT = 0,
	@iHumanDestLettreID INT = NULL --À qui la lettre est adressée (peut être souscripteur ou bénéficiaire)	
AS
BEGIN

	declare @tDDD table (IdDDD int, iHumanDestLettreID INT)

	--Si une seule lettre demandée
	if @idDDD is not NULL AND @iHumanDestLettreID IS NOT NULL
		begin
		insert into @tDDD 
		SELECT @idDDD, @iHumanDestLettreID
		FROM DecaissementDepotDirect DDD
		JOIN dbo.DemandePAE DP ON DP.Id = DDD.IdDemande
		WHERE DDD.Id = @idDDD AND (DP.IdSouscripteur = @iHumanDestLettreID OR DP.IdBeneficiaire = @iHumanDestLettreID)
		end

	--Si plage de date
	if @dtDateCreationDe is not null and @dtDateCreationA is not null
		begin
		insert into @tDDD 
		SELECT DISTINCT 
			DDD.Id,
			HumanDestLettre.HumanID AS iHumanDestLettreID
		from 
			DemandeHistoriqueDocument DHD
			JOIN DemandePAE DP ON DHD.IDDemande = DP.Id -- on join sur cette table pour rammasser seulement les id de demande PAE
			JOIN DecaissementDepotDirect DDD ON DHD.IDDemande = DDD.IdDemande
			JOIN dbo.Mo_Human HumanDestLettre on HumanDestLettre.HumanID = ISNULL(DHD.iHumanDestLettreID, /*0*/ DP.IdBeneficiaire) -- 2018-02-19
		where 
			DHD.CodeTypeDocument = @vcCodeTypeDocument

			and LEFT(CONVERT(VARCHAR, DHD.DateCreation, 120), 10) between @dtDateCreationDe and @dtDateCreationA

			and (
				(DHD.EstEmis = 0 /*false*/ and @iReimprimer = 0 /*false*/)
				OR
				(DHD.EstEmis <> 0 /*true*/ and @iReimprimer <> 0 /*true*/)
				)
			and (HumanDestLettre.LangID = @LangID or @LangID is null) 

		END

	--On s'assure que le ID reçu correspond soit au souscripteur ou au bénéficiare.  
	DELETE TD
	FROM 
		DemandeHistoriqueDocument DHD
		JOIN DemandePAE DP ON DHD.IDDemande = DP.Id -- on join sur cette table pour rammasser seulement les id de demande PAE
		JOIN DecaissementDepotDirect DDD ON DHD.IDDemande = DDD.IdDemande
		JOIN @tDDD TD ON TD.IdDDD = DDD.Id
	WHERE TD.iHumanDestLettreID <> DP.IdSouscripteur AND TD.iHumanDestLettreID <> DP.IdBeneficiaire

	--Adresse perdu - Beneficiaire
	DELETE TD
	FROM 
		DemandeHistoriqueDocument DHD
		JOIN DemandePAE DP ON DHD.IDDemande = DP.Id -- on join sur cette table pour rammasser seulement les id de demande PAE
		JOIN DecaissementDepotDirect DDD ON DHD.IDDemande = DDD.IdDemande
		JOIN @tDDD TD ON TD.IdDDD = DDD.Id
		JOIN Un_Beneficiary B on B.BeneficiaryID = TD.iHumanDestLettreID 
	WHERE B.bAddressLost = 1

	--Adresse perdu - Souscripteur
	DELETE TD
	FROM 
		DemandeHistoriqueDocument DHD
		JOIN DemandePAE DP ON DHD.IDDemande = DP.Id -- on join sur cette table pour rammasser seulement les id de demande PAE
		JOIN DecaissementDepotDirect DDD ON DHD.IDDemande = DDD.IdDemande
		JOIN @tDDD TD ON TD.IdDDD = DDD.Id
		JOIN dbo.Un_Subscriber S on S.SubscriberID = TD.iHumanDestLettreID 
	WHERE S.AddressLost = 1

	-- Si on est par plage de date et que ce n'est pas une réimpression, on met EstEmis = 1 (bénéficiaire)
	if @dtDateCreationDe is not null and @dtDateCreationA is not null and isnull(@iReimprimer,0) = 0
		begin
		UPDATE DHD
		SET DHD.EstEmis = 1
		from DemandeHistoriqueDocument DHD
		JOIN DemandePAE DP ON DHD.IDDemande = DP.Id -- on join sur cette table pour rammasser seulement les id de demande PAE
		JOIN dbo.Mo_Human h on h.HumanID = DHD.iHumanDestLettreID
		JOIN Un_Beneficiary B on B.BeneficiaryID = DHD.iHumanDestLettreID AND B.bAddressLost = 0
		where DHD.CodeTypeDocument = @vcCodeTypeDocument
			and DHD.EstEmis = 0
			and LEFT(CONVERT(VARCHAR, DHD.DateCreation, 120), 10)  between @dtDateCreationDe and @dtDateCreationA
			and (h.LangID = @LangID or @LangID is null)
		END

	-- Si on est par plage de date et que ce n'est pas une réimpression, on met EstEmis = 1 (souscripteur)
	if @dtDateCreationDe is not null and @dtDateCreationA is not null and isnull(@iReimprimer,0) = 0
		begin
		UPDATE DHD
		SET DHD.EstEmis = 1
		from DemandeHistoriqueDocument DHD
		JOIN DemandePAE DP ON DHD.IDDemande = DP.Id -- on join sur cette table pour rammasser seulement les id de demande PAE
		JOIN dbo.Mo_Human h on h.HumanID = DHD.iHumanDestLettreID
		JOIN dbo.Un_Subscriber S on S.SubscriberID = DHD.iHumanDestLettreID AND S.AddressLost = 0
		where DHD.CodeTypeDocument = @vcCodeTypeDocument
			and DHD.EstEmis = 0
			and LEFT(CONVERT(VARCHAR, DHD.DateCreation, 120), 10)  between @dtDateCreationDe and @dtDateCreationA
			and (h.LangID = @LangID or @LangID is null)
		end

	SELECT 
		c.ConventionNo,
		LangID = HDestLettre.LangID, -- La langue du bénéficiaire
		PrenomBenef = hb.firstname,
		C.BeneficiaryID,
		C.SubscriberID,
		NomBenef = hb.lastname,
		AdresseBenef = Ab.Address,
		CityBenef = Ab.City,
		ZipCodeBenef = dbo.fn_Mo_FormatZIP(Ab.ZipCode,ab.countryid),
		StateNameBenef = Ab.StateName,
		CountryBenef = ab.CountryID,
		AppelLongBenef = sexb.LongSexName,
		AppelCourtBenef = sexB.ShortSexName,
		SexBenef = sexB.SexID,

		O.OperID,
		IdDDD = DDD.Id,
		MontantDDD = DDD.Montant,
		DateDecaissement = ISNULL(DDD.DateDecaissement,GETDATE()),
		O.OperTypeID,
		SoldeRistourneAssurance = -1 *	SUM(CASE WHEN co.conventionopertypeid = 'RST' THEN ConventionOperAmount ELSE 0 END ),
		SCEE = -1 * (ISNULL(ce.fCESG,0) + ISNULL(ce.fACESG,0) + ISNULL(ce.fCLB,0)),

		--SCEERend = -1 *	SUM(CASE WHEN co.conventionopertypeid IN ('INS','IST','IS+','IBC') THEN ConventionOperAmount ELSE 0 END ),

		SCEERend = -1 *	sum(case when co.conventionopertypeid IN ('INS','IS+','IBC') then ConventionOperAmount else 0 end ),

		BRS = -1 *	SUM(CASE WHEN co.conventionopertypeid = 'BRS' THEN ConventionOperAmount ELSE 0 END ),
		RTN = SUM(CASE WHEN co.conventionopertypeid = 'RTN' THEN ConventionOperAmount ELSE 0 END ),

		--RendInd = -1 *	SUM(CASE WHEN co.conventionopertypeid IN ('INM','ITR') THEN ConventionOperAmount ELSE 0 END ),

		RendInd = -1 *	sum(case when co.conventionopertypeid IN ('IST', 'INM','ITR') then ConventionOperAmount else 0 END ),

		IQEE = -1 *	SUM(CASE WHEN co.conventionopertypeid IN ( 'CBQ','MMQ') THEN ConventionOperAmount ELSE 0 END ),
		IQEERend = -1 *	SUM(CASE WHEN co.conventionopertypeid IN ('ICQ','III','IIQ','IMQ','MIM','IQI') THEN ConventionOperAmount ELSE 0 END ),
		s.ScholarshipNo,
		PlanDesc = CASE 
					WHEN HDestLettre.LangID = 'ENU' THEN p.PlanDesc_ENU
					ELSE p.PlanDesc 
					END

		,PrenomSousc = HS.FirstName
		,NomSousc = HS.LastName
		,RendINM = -1 *	SUM(CASE WHEN co.conventionopertypeid = 'INM' THEN ConventionOperAmount ELSE 0 END )
		,RendITR = -1 *	SUM(CASE WHEN co.conventionopertypeid = 'ITR' THEN ConventionOperAmount ELSE 0 END )
		,p.OrderOfPlanInReport

		,DestPaiementID = HDestPaiement.HumanID
		,AppelLongDestPaiement = SexDestPaiement.LongSexName
		,AppelCourDestPaiement = SexDestPaiement.ShortSexName
		,PrenomDestPaiement = HDestPaiement.firstname
		,NomDestPaiement = HDestPaiement.lastname

		,DestLettreID = HDestLettre.HumanID
		,AppelLongDestLettre = SexDestLettre.LongSexName
		,AppelCourtDestLettre = SexDestLettre.ShortSexName
		,PrenomDestLettre = HDestLettre.firstname
		,NomDestLettre = HDestLettre.lastname
		,AdresseDestLettre = ADestLettre.Address
		,CityDestLettre = ADestLettre.City
		,ZipCodeDestLettre = dbo.fn_Mo_FormatZIP(ADestLettre.ZipCode,ADestLettre.countryid)
		,StateNameDestLettre = ADestLettre.StateName
		,CountryDestLettre = ADestLettre.CountryID	

		,dp.bDestinataireEstSouscripteur
		,DateDecaissementFormate = dbo.fn_Mo_DateToLongDateStr(ISNULL(DDD.DateDecaissement,GETDATE()), HDestLettre.LangID) 

	FROM 
		Un_Convention c 
		JOIN Un_Plan p ON c.PlanID = p.PlanID
		JOIN dbo.Un_Subscriber Su ON C.subscriberID = Su.SubscriberID 
		JOIN dbo.Mo_Human HS ON Su.SubscriberID = HS.HumanID
		JOIN dbo.Mo_Human hb ON C.BeneficiaryID = hb.HumanID
		JOIN Mo_Sex sex ON sex.SexID = hs.SexID AND sex.LangID = hs.LangID
		JOIN dbo.Mo_Adr A ON HS.AdrID = A.AdrID
		JOIN dbo.Mo_Adr Ab ON Hb.AdrID = Ab.AdrID
		JOIN Mo_Sex sexB ON sexb.SexID = hb.SexID AND sexb.LangID = hb.LangID
		JOIN Un_Scholarship s ON c.ConventionID = s.ConventionID
		JOIN Un_ScholarshipPmt sp ON s.ScholarshipID = sp.ScholarshipID
		JOIN Un_Oper o ON sp.OperID = o.OperID 
		JOIN DecaissementDepotDirect DDD ON DDD.IdOperationFinanciere = o.OperID
		JOIN @tDDD td ON td.IdDDD = DDD.Id -- TODO AND td.iHumanDestLettreID =  
		LEFT JOIN Un_ConventionOper co ON o.OperID = co.OperID
		LEFT JOIN Un_CESP ce ON O.OperID = ce.OperID
		LEFT JOIN demandePAE dp ON dp.IdOperationFinanciere = o.OperID

		LEFT JOIN Mo_Human HDestPaiement on HDestPaiement.HumanID = (CASE WHEN isnull(dp.bDestinataireEstSouscripteur,0) = 1 THEN dp.IdSouscripteur ELSE dp.IdBeneficiaire END)
		LEFT JOIN Mo_Sex SexDestPaiement ON SexDestPaiement.SexID = HDestPaiement.SexID AND SexDestPaiement.LangID = HDestPaiement.LangID
		LEFT JOIN dbo.Mo_Adr ADestPaiement on HDestPaiement.AdrID = ADestPaiement.AdrID

		LEFT JOIN Mo_Human HDestLettre on HDestLettre.HumanID = iHumanDestLettreID
		LEFT JOIN Mo_Sex SexDestLettre ON SexDestLettre.SexID = HDestLettre.SexID AND SexDestLettre.LangID = HDestLettre.LangID
		LEFT JOIN dbo.Mo_Adr ADestLettre on HDestLettre.AdrID = ADestLettre.AdrID

	GROUP BY
		c.ConventionNo,
		hb.firstname,
		C.BeneficiaryID,
		C.SubscriberID,
		hb.lastname,
		Ab.Address,
		Ab.City,
		Ab.ZipCode,
		Ab.StateName,
		ab.CountryID,
		sexb.LongSexName,
		sexB.ShortSexName,
		sexB.SexID,
		O.OperID,

		DDD.Id,
		DDD.Montant,
		ISNULL(DDD.DateDecaissement,GETDATE()),

		O.OperTypeID,
		-1 * (ISNULL(ce.fCESG,0) + ISNULL(ce.fACESG,0) + ISNULL(ce.fCLB,0))
		,dp.SoldeRistourneAssurance,
		s.ScholarshipNo,
		p.PlanID
		,p.PlanDesc
		,p.PlanDesc_ENU
		,HS.FirstName
		,HS.LastName	

		,p.OrderOfPlanInReport

		,HDestPaiement.HumanID
		,SexDestPaiement.LongSexName
		,SexDestPaiement.ShortSexName
		,HDestPaiement.firstname
		,HDestPaiement.lastname

		,HDestLettre.HumanID
		,HDestLettre.LangID
		,SexDestLettre.LongSexName
		,SexDestLettre.ShortSexName
		,HDestLettre.firstname
		,HDestLettre.lastname
		,ADestLettre.Address
		,ADestLettre.City
		,ADestLettre.ZipCode
		,ADestLettre.StateName
		,ADestLettre.CountryID	

		,dp.bDestinataireEstSouscripteur
	ORDER BY p.OrderOfPlanInReport,hb.lastname,hb.firstname

END