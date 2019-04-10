/********************************************************************************************************************
Copyrights (c) 2011 Gestion Universitas inc.

Code du service		: psCONV_RapportLettre_le_conf_chq_PAE
Nom du service		: Générer la lettre le_conf_chq_PAE
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXEC psCONV_RapportLettre_le_conf_chq_PAE @iCheckID = 211115,@iHumanDestLettreID = 228309
						EXEC psCONV_RapportLettre_le_conf_chq_PAE @vcCodeTypeDocument = 'le_conf_chq_pae_ind', @dtDateCreationDe = '2000-02-01', @dtDateCreationA = '2018-02-19', @iReimprimer = 1,@LangID ='fra'

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2014-04-04		Donald Huppé						Création du service	
		2014-06-25		Donald Huppé						Ajout du paramètre @LangID
		2014-10-01		Donald Huppé						Faire DateCheque = max(cs.dtHistory) au cas où on imprime le cheque plus d'une fois
		2016-05-03		Donald Huppé						JIRA PROD-1835 : Ne pas générer la lettre si Un_BENEFICIARY.bAddressLost = 1	
		2017-11-22		Donald Huppé						Gestion du Destinataire
		2017-11-23		Simon Tanguay						Ajout du champ @iHumanDestLettreID
		2017-12-11      Stephane Roussel					Calcul du BRS en prenant les operations BRS + RST
		2017-12-15		Simon Tanguay						CRIT-1462 Lettre de qualification - Affichage du TIN
		2017-12-28		Simon Tanguay						CRIT-11900 Déplacer 'IQI' de IQEERend à RendInd
		2018-02-19		Donald Huppé						Quand DHD.iHumanDestLettreID est NULL, alors on prend dp.IdBeneficiaire pour faire le JOIN (afin gérer les vieux cas quand c'était toujours le benef)
		2018-11-08		Maxime Martel						Utilisation du planDesc_ENU de la table plan
        2018-11-26		Maxime Martel						Écrire le nom du plan en fonction de la langue du destinataire 
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettre_le_conf_chq_PAE] 
	@iCheckID int = null,
	@vcCodeTypeDocument varchar(25) = NULL,
	@dtDateCreationDe datetime = NULL,
	@dtDateCreationA datetime = NULL,
	@LangID varchar(3) = NULL,
	@iReimprimer int = 0,
	@iHumanDestLettreID INT = NULL --À qui la lettre est adressée (peut être souscripteur ou bénéficiaire)
AS
BEGIN

	declare @tCheckID table (iCheckID INT, iHumanDestLettreID INT)

	if @iCheckID is not NULL AND @iHumanDestLettreID IS NOT NULL
		begin
		insert into @tCheckID values (@iCheckID, @iHumanDestLettreID)
		end

	if @dtDateCreationDe is not null and @dtDateCreationA is not null
		begin
		insert into @tCheckID 
		SELECT DISTINCT 
			ch.iCheckID,
			HumanDestLettre.HumanID AS iHumanDestLettreID
		from 
			DemandeHistoriqueDocument DHD
			JOIN DemandePAE DP ON DHD.IDDemande = DP.Id -- on join sur cette table pour rammasser seulement les id de demande PAE
			JOIN dbo.Mo_Human HumanDestLettre on HumanDestLettre.HumanID = ISNULL(DHD.iHumanDestLettreID,/*0*/ DP.IdBeneficiaire) -- 2018-02-19
			JOIN Un_OperLinkToCHQOperation OL ON OL.OperID = DP.IdOperationFinanciere
			JOIN CHQ_Operation cho ON cho.iOperationID = OL.iOperationID
			JOIN CHQ_OperationDetail OD ON OD.iOperationID = cho.iOperationID
			JOIN CHQ_CheckOperationDetail COD ON COD.iOperationDetailID = OD.iOperationDetailID
			join CHQ_Check ch ON ch.iCheckID = COD.iCheckID
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
	DELETE TC
	FROM 
		Un_Oper O 
		JOIN Un_ScholarshipPmt SP ON SP.OperID = O.OperID
		JOIN Un_Scholarship S ON SP.ScholarshipID = S.ScholarshipID
		JOIN Un_Convention C ON S.ConventionID = C.ConventionID
		JOIN Un_Beneficiary B ON C.BeneficiaryID = B.BeneficiaryID
		JOIN Un_OperLinkToCHQOperation OL ON OL.OperID = O.OperID
		JOIN CHQ_Operation cho ON cho.iOperationID = OL.iOperationID
		JOIN CHQ_OperationDetail OD ON OD.iOperationID = cho.iOperationID
		JOIN CHQ_CheckOperationDetail COD ON COD.iOperationDetailID = OD.iOperationDetailID
		join CHQ_Check ch ON ch.iCheckID = COD.iCheckID
		JOIN @tCheckID TC ON TC.iCheckID = CH.iCheckID
	WHERE TC.iHumanDestLettreID <> C.SubscriberID AND TC.iHumanDestLettreID <> c.BeneficiaryID

	DELETE TC
	FROM 
		Un_Oper O 
		JOIN Un_ScholarshipPmt SP ON SP.OperID = O.OperID
		JOIN Un_Scholarship S ON SP.ScholarshipID = S.ScholarshipID
		JOIN Un_Convention C ON S.ConventionID = C.ConventionID
		JOIN Un_Beneficiary B ON C.BeneficiaryID = B.BeneficiaryID
		JOIN Un_OperLinkToCHQOperation OL ON OL.OperID = O.OperID
		JOIN CHQ_Operation cho ON cho.iOperationID = OL.iOperationID
		JOIN CHQ_OperationDetail OD ON OD.iOperationID = cho.iOperationID
		JOIN CHQ_CheckOperationDetail COD ON COD.iOperationDetailID = OD.iOperationDetailID
		join CHQ_Check ch ON ch.iCheckID = COD.iCheckID
		JOIN @tCheckID TC ON TC.iCheckID = CH.iCheckID AND TC.iHumanDestLettreID = B.BeneficiaryID
	WHERE B.bAddressLost = 1 

	DELETE TC
	FROM 
		Un_Oper O 
		JOIN Un_ScholarshipPmt SP ON SP.OperID = O.OperID
		JOIN Un_Scholarship S ON SP.ScholarshipID = S.ScholarshipID
		JOIN Un_Convention C ON S.ConventionID = C.ConventionID
		JOIN dbo.Un_Subscriber Sub ON C.SubscriberID = Sub.SubscriberID
		JOIN Un_OperLinkToCHQOperation OL ON OL.OperID = O.OperID
		JOIN CHQ_Operation cho ON cho.iOperationID = OL.iOperationID
		JOIN CHQ_OperationDetail OD ON OD.iOperationID = cho.iOperationID
		JOIN CHQ_CheckOperationDetail COD ON COD.iOperationDetailID = OD.iOperationDetailID
		join CHQ_Check ch ON ch.iCheckID = COD.iCheckID
		JOIN @tCheckID TC ON TC.iCheckID = CH.iCheckID AND TC.iHumanDestLettreID = Sub.SubscriberID
	WHERE Sub.AddressLost = 1 

	-- Si on est par plage de date et que ce n'est pas une réimpression, on met EstEmis = 1
	if @dtDateCreationDe is not null and @dtDateCreationA is not null and isnull(@iReimprimer,0) = 0
		begin
		UPDATE DHD
		SET DHD.EstEmis = 1
		from DemandeHistoriqueDocument DHD
		JOIN DemandePAE DP ON DHD.IDDemande = DP.Id -- on join sur cette table pour rammasser seulement les id de demande PAE
		JOIN dbo.Mo_Human h on h.HumanID = DHD.iHumanDestLettreID 
		JOIN Un_Beneficiary B ON h.HumanID = B.BeneficiaryID AND B.bAddressLost = 0
		WHERE DHD.CodeTypeDocument = @vcCodeTypeDocument
			AND DHD.EstEmis = 0
			AND LEFT(CONVERT(VARCHAR, DHD.DateCreation, 120), 10)  between @dtDateCreationDe and @dtDateCreationA
			AND (h.LangID = @LangID or @LangID is null)
		END

		-- Si on est par plage de date et que ce n'est pas une réimpression, on met EstEmis = 1
	if @dtDateCreationDe is not null and @dtDateCreationA is not null and isnull(@iReimprimer,0) = 0
		begin
		UPDATE DHD
		SET DHD.EstEmis = 1
		from DemandeHistoriqueDocument DHD
		JOIN DemandePAE DP ON DHD.IDDemande = DP.Id -- on join sur cette table pour rammasser seulement les id de demande PAE
		JOIN dbo.Mo_Human h on h.HumanID = DHD.iHumanDestLettreID 
		JOIN dbo.Un_Subscriber Sub ON h.HumanID = Sub.SubscriberID AND Sub.AddressLost = 0 
		WHERE DHD.CodeTypeDocument = @vcCodeTypeDocument
			AND DHD.EstEmis = 0
			AND LEFT(CONVERT(VARCHAR, DHD.DateCreation, 120), 10)  between @dtDateCreationDe and @dtDateCreationA
			AND (h.LangID = @LangID or @LangID is null)
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
		op.iCheckID,
		op.iCheckNumber, 
		MontantCHQ = CONVERT(FLOAT,op.fAmount),
		O.OperTypeID,
		SoldeRistourneAssurance = -1 * SUM(case when co.conventionopertypeid = 'RST' then ConventionOperAmount else 0 end),
		SCEE = -1 * (isnull(ce.fCESG,0) + isnull(ce.fACESG,0) + isnull(ce.fCLB,0)),

		--SCEERend = -1 *	sum(case when co.conventionopertypeid IN ('INS','IST','IS+','IBC') then ConventionOperAmount else 0 end ),

		SCEERend = -1 *	sum(case when co.conventionopertypeid IN ('INS','IS+','IBC') then ConventionOperAmount else 0 end ),

		BRS = -1 *	sum(case when co.conventionopertypeid = 'BRS' then ConventionOperAmount else 0 end ),
		RTN = sum(case when co.conventionopertypeid = 'RTN' then ConventionOperAmount else 0 end ),

		--RendInd = -1 *	sum(case when co.conventionopertypeid IN ( 'INM','ITR') then ConventionOperAmount else 0 end ),

		RendInd = -1 *	sum(case when co.conventionopertypeid IN ('IST', 'INM','ITR', 'IQI') then ConventionOperAmount else 0 END ),

		IQEE = -1 *	sum(case when co.conventionopertypeid IN ('CBQ','MMQ') then ConventionOperAmount else 0 end ),
		IQEERend = -1 *	sum(case when co.conventionopertypeid IN ('ICQ','III','IIQ','IMQ','MIM') then ConventionOperAmount else 0 end ),
		s.ScholarshipNo,
		PlanDesc = CASE 
					WHEN HDestLettre.LangID = 'ENU' THEN p.PlanDesc_ENU
					ELSE p.PlanDesc 
					END

		,PrenomSousc = HS.FirstName
		,NomSousc = HS.LastName
		,RendINM = -1 *	sum(case when co.conventionopertypeid = 'INM' then ConventionOperAmount else 0 end )
		,RendITR = -1 *	sum(case when co.conventionopertypeid = 'ITR' then ConventionOperAmount else 0 end )
		,op.DateCheque -- La date d'impression du chèque
		,p.OrderOfPlanInReport

		,DestCHQID = HDestCHQ.HumanID
		,AppelLongDestCHQ = SexDestCHQ.LongSexName
		,AppelCourtDestCHQ = SexDestCHQ.ShortSexName
		,PrenomDestCHQ = HDestCHQ.firstname
		,NomDestCHQ = HDestCHQ.lastname

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
		,DateChequeFormate = dbo.fn_Mo_DateToLongDateStr(op.DateCheque, HDestLettre.LangID) 
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
		join Un_Scholarship s ON c.ConventionID = s.ConventionID
		join Un_ScholarshipPmt sp ON s.ScholarshipID = sp.ScholarshipID
		join Un_Oper o ON sp.OperID = o.OperID 

		join (
			SELECT OL.OperID, ch.iCheckID, ch.iCheckNumber, ch.fAmount, DateCheque = max(cs.dtHistory), t.iHumanDestLettreID
			from CHQ_Check ch
			join CHQ_CheckHistory cs ON cs.iCheckID = ch.iCheckID --AND cs.iCheckStatusID = 4 -- Le cheque doit être imprimé
			JOIN CHQ_CheckOperationDetail COD ON ch.iCheckID = COD.iCheckID
			JOIN CHQ_OperationDetail OD ON COD.iOperationDetailID = OD.iOperationDetailID
			JOIN CHQ_Operation cho ON OD.iOperationID = cho.iOperationID
			JOIN Un_OperLinkToCHQOperation OL ON cho.iOperationID = OL.iOperationID
			join @tCheckID t on t.iCheckID = ch.iCheckID
			where ch.iCheckStatusID = 4 -- Le cheque doit être imprimé
			AND cs.iCheckStatusID = 4 -- on recherche l'historique d'impression pour avoir le max(cs.dtHistory)
			group by OL.OperID, ch.iCheckID, ch.iCheckNumber, ch.fAmount, t.iHumanDestLettreID
			)op ON op.OperID = o.OperID
		left join Un_ConventionOper co ON o.OperID = co.OperID
		LEFT JOIN Un_CESP ce on O.OperID = ce.OperID
		left JOIN demandePAE dp ON dp.IdOperationFinanciere = o.OperID

		LEFT JOIN Mo_Human HDestCHQ on HDestCHQ.HumanID = (CASE WHEN isnull(dp.bDestinataireEstSouscripteur,0) = 1 THEN dp.IdSouscripteur ELSE dp.IdBeneficiaire END)
		LEFT JOIN Mo_Sex SexDestCHQ ON SexDestCHQ.SexID = HDestCHQ.SexID AND SexDestCHQ.LangID = HDestCHQ.LangID
		LEFT JOIN dbo.Mo_Adr ADestCHQ on HDestCHQ.AdrID = ADestCHQ.AdrID

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
		op.iCheckID,
		op.iCheckNumber, 
		CONVERT(FLOAT,op.fAmount),
		O.OperTypeID,
		-1 * (isnull(ce.fCESG,0) + isnull(ce.fACESG,0) + isnull(ce.fCLB,0))
		,dp.SoldeRistourneAssurance,
		s.ScholarshipNo,
		p.PlanID
		,p.PlanDesc
		,p.PlanDesc_ENU
		,HS.FirstName
		,HS.LastName	
		,op.DateCheque
		,p.OrderOfPlanInReport

		,HDestCHQ.HumanID
		,SexDestCHQ.LongSexName
		,SexDestCHQ.ShortSexName
		,HDestCHQ.firstname
		,HDestCHQ.lastname

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


end