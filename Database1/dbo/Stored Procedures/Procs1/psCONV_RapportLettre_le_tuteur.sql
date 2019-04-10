/********************************************************************************************************************
Copyrights (c) 2014 Gestion Universitas inc.

Code du service		: psCONV_RapportLettre_le_tuteur
Nom du service		: Générer la lettre du tuteur
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXEC psCONV_RapportLettre_le_tuteur @ConventionNo = 'X-20151110013'

EXEC psCONV_RapportLettre_le_tuteur 
	@ConventionNo = 'X-20151116084', 
	@dtDateCreationDe = NULL, --'2015-11-10', 
	@dtDateCreationA = NULL, --'2015-11-10', 
	@iReimprimer = 1,
	@UserID =  ''--'svc_sql_ssrs_app'

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2015-08-12		Donald Huppé						Création du service							À partir de RP_UN_TutorLetter
		2015-11-03		Donald Huppé						Gestion du paramètre ConventionNo (même principe que par plage de date)
		2015-11-12		Donald Huppé						ajout du paramètre @UserID + enlever modif précédente du 2015-11-03
		2015-11-17		Donald Huppé						Update de DI.EstEmis = 1 sur demande unitaire
		2015-12-10		Donald Huppé						JIRA PROD-313 : DateConvention doit être la date de signature, en remplacement de InforcDate
		2016-05-03		Donald Huppé						JIRA PROD-1835 : Ne pas générer la lettre si Un_Subscriber.AddressLost = 1	
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettre_le_tuteur] 
	@ConventionNo varchar(30),
	@dtDateCreationDe datetime = NULL,
	@dtDateCreationA datetime = NULL,
	@LangID varchar(5) = NULL,
	@iReimprimer int = 0,
	@UserID varchar(255) = NULL
AS
BEGIN

	declare @Convention table (IDConvention int)		
	
	if @ConventionNo is not null -- Appel de SSRS ou application
		begin
		insert into @Convention select conventionid FROM dbo.Un_Convention where conventionno = @ConventionNo
		end

	if (@dtDateCreationDe is not null and @dtDateCreationA is not null) -- Appel de SSRS par plage de date
		begin
		insert into @Convention 
		SELECT c.ConventionID
		from DocumentImpression DI
		JOIN dbo.Un_Convention c on DI.IdObjetLie = c.ConventionID
		JOIN dbo.Mo_Human h on h.HumanID = c.SubscriberID
		where DI.CodeTypeDocument = 'le_tuteur'
			and LEFT(CONVERT(VARCHAR, DI.DateCreation, 120), 10) between @dtDateCreationDe and @dtDateCreationA
			and (
				(DI.EstEmis = 0 /*false*/ and @iReimprimer = 0 /*false*/)
				OR
				(DI.EstEmis <> 0 /*true*/ and @iReimprimer <> 0 /*true*/)
				)
			and (h.LangID = @LangID or @LangID is null)

		end

	DELETE CC
	FROM @Convention CC
		JOIN dbo.Un_Convention C ON CC.IDConvention = C.ConventionID
		JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID
	WHERE S.AddressLost = 1

	-- Si on est par plage de date ou convention et que ce n'est pas une réimpression, on met EstEmis = 1
	if (@dtDateCreationDe is not null and @dtDateCreationA is not null )
		and @iReimprimer = 0
		-- juste pour être certain que ce n'est pas un appel de l'application, mais pas supposé arriver par plage de dates anyway.
		AND isnull(@UserID,'') not like '%svc_sql_ssrs_app%' 
		begin
		UPDATE DI
		SET DI.EstEmis = 1
		from DocumentImpression DI
		JOIN dbo.Un_Convention c on DI.IdObjetLie = c.ConventionID
		JOIN dbo.Mo_Human h on h.HumanID = c.SubscriberID
		JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID AND S.AddressLost = 0
		where DI.CodeTypeDocument = 'le_tuteur'
			and DI.EstEmis = 0
			and LEFT(CONVERT(VARCHAR, DI.DateCreation, 120), 10) between @dtDateCreationDe and @dtDateCreationA
			and (h.LangID = @LangID or @LangID is null)
		end

	-- si on demande une impression unitaire par l'outil SSRS - et non par l'application, on met systématiquement EstEmis = 1 peu importe la valeur du paramètre @iReimprimer sélectionnée
	if @ConventionNo is not null AND isnull(@UserID,'') not like '%svc_sql_ssrs_app%' 
		begin
		UPDATE DI
		SET DI.EstEmis = 1
		from DocumentImpression DI
		JOIN @Convention c on DI.IdObjetLie = c.IDConvention
		where DI.CodeTypeDocument = 'le_tuteur'
		 /*ceci juste pour être certain que c'est bien un unitID qu'on a */ and di.TypeObjetLie = 0
			and DI.EstEmis = 0
			AND isnull(@UserID,'') not like '%svc_sql_ssrs_app%' 
		end

	SELECT
		HT.LangID,
		Date = dbo.fn_Mo_DateToLongDateStr(GETDATE(), HT.LangID), -- Date du jour.
		TitreTuteur	= 
			CASE
				WHEN SxT.LangID = 'ENU' THEN SxT.ShortSexName
			ELSE SxT.LongSexName
			END, -- Ce sera monsieur, madame, Mr ou Ms selon le sexe et la langue du tuteur.
		NomTuteur = HT.LastName, -- Nom de famille du tuteur.
		PrenomTuteur = HT.FirstName, -- Prénom du tuteur.
		AdresseTuteur = AdT.Address, -- Adresse du tuteur, incluant le numéro civique, le nom de la rue et le numéro d’appartement s’il y a lieu.
		VilleTuteur = AdT.City, -- Ville du tuteur.
		ProvinceTuteur = AdT.StateName, -- Province du tuteur.
		CodePostalTuteur = dbo.fn_Mo_FormatZIP(AdT.ZipCode, AdT.CountryID), -- Code postal du tuteur.
		TitreSouscripteur = 
			CASE
				WHEN SxS.LangID = 'ENU' THEN SxS.ShortSexName
			ELSE SxS.LongSexName
			END, -- Ce sera monsieur, madame, Mr ou Ms selon le sexe du souscripteur et la langue du tuteur.
		NomSouscripteur = HS.LastName, -- Nom de famille du souscripteur.
		PrenomSouscripteur = HS.FirstName, -- Prénom du souscripteur.
		AdresseSouscripteur = AdS.Address, -- Adresse du souscripteur, incluant le numéro civique, le nom de la rue et le numéro d’appartement s’il y a lieu.
		VilleSouscripteur = AdS.City, -- Ville du souscripteur.
		ProvinceSouscripteur = AdS.StateName, -- Province du souscripteur.
		CodePostalSouscripteur = dbo.fn_Mo_FormatZIP(AdS.ZipCode, AdS.CountryID), -- Code postal du souscripteur.
		NomBeneficiaire = HB.LastName, -- Nom du bénéficiaire.
		PrenomBeneficiaire = HB.FirstName, -- Prénom du bénéficiaire.
		--DateConvention = dbo.fn_Mo_DateToLongDateStr(V.InForceDate, HT.LangID), -- Date d’entrée en vigueur de la convention.
		DateConvention = dbo.fn_Mo_DateToLongDateStr(V.SignatureDate, HT.LangID), -- Date de signature de la convention. -- JIRA PROD-313
		NoConvention = C.ConventionNo, -- Numéro de la convention.
		Regime = P.PlanDesc, -- Régime de la convention (Universitas, REEEFLEX, Sélect 2000 Plan B, etc.)
		DescriptifRepresentant =
				CASE
					WHEN HR.SexID = 'F' THEN 'La représentante'
				ELSE 'Le représentant'
				END, -- « La représentante » ou « Le représentant » selon le sexe du représentant.  Toujours en français.
		TitreRepresentant = 
			CASE
				WHEN SxR.LangID = 'ENU' THEN SxR.ShortSexName
			ELSE SxR.LongSexName
			END, -- Ce sera monsieur, madame, Mr ou Ms selon le sexe du représentant du souscripteur et la langue du tuteur.
		TitreCoursRepresentant = SxR.ShortSexName, -- Ce sera M, Mme, Mr ou Ms selon le sexe du représentant du souscripteur et la langue du tuteur.
		NomRepresentant = HR.LastName, -- Nom de famille du représentant du souscripteur.
		PrenomRepresentant = HR.FirstName, -- Prénom du représentant de souscripteur.
		PronomRepresentant =
			CASE
				WHEN SxT.LangID = 'ENU' AND HR.SexID = 'F' THEN 'her'
				WHEN SxT.LangID = 'ENU' THEN 'his'
				WHEN SxT.LangID = 'FRA' AND HR.SexID = 'F' THEN 'elle'
				WHEN SxT.LangID = 'FRA' THEN 'lui'
			END, -- elle, lui, her ou his selon le sexe du représentant du souscripteur et la langue du tuteur
		TelephoneRepresentant = dbo.FN_CRQ_FormatPhoneNo(AdR.Phone2, AdR.CountryID) -- Téléphone du représentant de souscripteur.
	FROM dbo.Un_Convention C
	join @Convention cc on c.ConventionID = cc.IDConvention
	JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
	JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
	JOIN dbo.Mo_Human HT ON HT.HumanID = B.iTutorID
	JOIN Mo_Sex SxT ON HT.LangID = SxT.LangID AND HT.SexID = SxT.SexID
	JOIN dbo.Mo_Adr AdT ON AdT.AdrID = HT.AdrID
	JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
	JOIN Mo_Sex SxS ON HT.LangID = SxS.LangID AND HS.SexID = SxS.SexID
	JOIN dbo.Mo_Adr AdS ON AdS.AdrID = HS.AdrID
	JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID
	JOIN dbo.Mo_Human HR ON HR.HumanID = S.RepID
	LEFT JOIN Mo_Sex SxR ON HT.LangID = SxR.LangID AND HR.SexID = SxR.SexID
	LEFT JOIN dbo.Mo_Adr AdR ON AdR.AdrID = HR.AdrID
	JOIN Un_Plan P ON P.PlanID = C.PlanID
	JOIN (
		SELECT
			ConventionID,
			InForceDate = MIN(InForceDate)
			,SignatureDate = min(SignatureDate)
		FROM dbo.Un_Unit 
		GROUP BY ConventionID
		) V ON V.ConventionID = C.ConventionID
	ORDER by HT.LastName, ht.FirstName

END


