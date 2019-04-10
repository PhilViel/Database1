/********************************************************************************************************************
Copyrights (c) 2011 Gestion Universitas inc.

Code du service		: psCONV_RapportLettre_le_conf_chq_RIN
Nom du service		: Générer la lettre de confirmation de chq de RIN
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXEC psCONV_RapportLettre_le_conf_chq_RIN @iCheckID = 171496
						EXEC psCONV_RapportLettre_le_conf_chq_RIN @dtDateCreationDe = '2014-04-01', @dtDateCreationA = '2014-05-02', @iReimprimer = 1
Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2014-04-17		Donald Huppé						Création du service	
		2014-06-25		Donald Huppé						Ajout du paramètre @LangID
		2014-10-01		Donald Huppé						Faire DateCheque = max(cs.dtHistory) au cas où on imprime le cheque plus d'une fois	
		2016-05-03		Donald Huppé						JIRA PROD-1835 : Ne pas générer la lettre si UN_SUBSCRIBER.AddressLost = 1
		2018-02-12		Simon Tanguay						JIRA CRIT-2597 Modifier l'avis de qualification d'un RIN (Ajout du champ SexBenef)
		2018-11-08		Maxime Martel						Utilisation de PlanDesc_ENU de la table plan
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettre_le_conf_chq_RIN] 
	@iCheckID int = NULL,
	@dtDateCreationDe datetime = NULL,
	@dtDateCreationA datetime = NULL,
	@LangID varchar(3) = NULL,
	@iReimprimer int = 1
AS
BEGIN

	declare @tCheckID table (iCheckID int)

	if @iCheckID is not null
		begin
		insert into @tCheckID values (@iCheckID)
		end

	if @dtDateCreationDe is not null and @dtDateCreationA is not null
		begin
		insert into @tCheckID 
		SELECT DISTINCT 
			ch.iCheckID
		from 
			DemandeHistoriqueDocument DHD
			join DemandeRIN DP ON DHD.IDDemande = DP.Id
			JOIN dbo.Mo_Human h on h.HumanID = dp.IdSouscripteur
			join Un_OperLinkToCHQOperation OL ON OL.OperID = DP.IdOperationRin
			JOIN CHQ_Operation cho ON cho.iOperationID = OL.iOperationID
			JOIN CHQ_OperationDetail OD ON OD.iOperationID = cho.iOperationID
			JOIN CHQ_CheckOperationDetail COD ON COD.iOperationDetailID = OD.iOperationDetailID
			join CHQ_Check ch ON ch.iCheckID = COD.iCheckID
		where 
			DHD.CodeTypeDocument = 'le_conf_chq_rin'
			
			and LEFT(CONVERT(VARCHAR, DHD.DateCreation, 120), 10) between @dtDateCreationDe and @dtDateCreationA
			
			and (
				(DHD.EstEmis = 0 /*false*/ and @iReimprimer = 0 /*false*/)
				OR
				(DHD.EstEmis <> 0 /*true*/ and @iReimprimer <> 0 /*true*/)
				)
			and (h.LangID = @LangID or @LangID is null)
			
		end


	DELETE TC
	FROM 
		Un_Convention C 
		JOIN Un_Unit U ON C.ConventionID = U.ConventionID
		JOIN Un_Cotisation CT ON U.UnitID = CT.UnitID
		JOIN Un_Oper O ON CT.OperID = O.OperID
		JOIN Un_Subscriber S ON C.SubscriberID = S.SubscriberID
		JOIN Un_OperLinkToCHQOperation OL ON OL.OperID = CT.OperID
		JOIN CHQ_Operation cho ON cho.iOperationID = OL.iOperationID
		JOIN CHQ_OperationDetail OD ON OD.iOperationID = cho.iOperationID
		JOIN CHQ_CheckOperationDetail COD ON COD.iOperationDetailID = OD.iOperationDetailID
		join CHQ_Check ch ON ch.iCheckID = COD.iCheckID
		JOIN @tCheckID TC ON TC.iCheckID = CH.iCheckID
	WHERE S.AddressLost = 1


	-- Si on est par plage de date et que ce n'est pas une réimpression, on met EstEmis = 1
	if @dtDateCreationDe is not null and @dtDateCreationA is not null and isnull(@iReimprimer,0) = 0
		begin
		UPDATE DHD
		SET DHD.EstEmis = 1
		from DemandeHistoriqueDocument DHD
		join DemandeRIN DP ON DHD.IDDemande = DP.Id
		JOIN dbo.Mo_Human h on h.HumanID = dp.IdSouscripteur
		JOIN Un_Subscriber S ON h.HumanID = S.SubscriberID AND S.AddressLost = 0
		where DHD.CodeTypeDocument = 'le_conf_chq_rin'
			and DHD.EstEmis = 0
			and LEFT(CONVERT(VARCHAR, DHD.DateCreation, 120), 10)  between @dtDateCreationDe and @dtDateCreationA
			and (h.LangID = @LangID or @LangID is null)
		end

	SELECT DISTINCT
		c.ConventionNo,
		hs.LangID, -- La langue du souscripteur
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
		op.iCheckID,
		op.iCheckNumber, 
		MontantCHQ = CONVERT(FLOAT,op.fAmount),
		PlanDesc = CASE 
				WHEN hs.LangID = 'ENU' THEN p.PlanDesc_ENU
				ELSE p.PlanDesc 
				END
		,op.DateCheque -- La date d'impression du chèque
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
		
		join (
			SELECT DISTINCT OL.OperID, ch.iCheckID, ch.iCheckNumber, ch.fAmount, DateCheque = max(cs.dtHistory)
			from CHQ_Check ch
			join CHQ_CheckHistory cs ON cs.iCheckID = ch.iCheckID-- AND cs.iCheckStatusID = 4 
			JOIN CHQ_CheckOperationDetail COD ON ch.iCheckID = COD.iCheckID
			JOIN CHQ_OperationDetail OD ON COD.iOperationDetailID = OD.iOperationDetailID
			JOIN CHQ_Operation cho ON OD.iOperationID = cho.iOperationID
			JOIN Un_OperLinkToCHQOperation OL ON cho.iOperationID = OL.iOperationID
			join Un_Oper o ON ol.OperID = o.OperID and o.OperTypeID = 'RIN'
			join @tCheckID t on t.iCheckID = ch.iCheckID
			where ch.iCheckStatusID = 4 -- Le cheque doit être imprimé
			AND cs.iCheckStatusID = 4 -- on recherche l'historique d'impression pour avoir le max(cs.dtHistory)
			group by OL.OperID, ch.iCheckID, ch.iCheckNumber, ch.fAmount
			)op ON op.OperID = o.OperID
	ORDER BY p.OrderOfPlanInReport,HS.LastName,HS.FirstName

end