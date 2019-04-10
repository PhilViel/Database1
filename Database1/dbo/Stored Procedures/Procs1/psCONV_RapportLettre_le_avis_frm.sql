/********************************************************************************************************************
Copyrights (c) 2014 Gestion Universitas inc.

Code du service		: psCONV_RapportLettre_le_avis_frm
Nom du service		: Générer la lettre d'avis de fermeture
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXEC psCONV_RapportLettre_le_avis_frm @ConventionNo = 'X-20151110013'

EXEC psCONV_RapportLettre_le_avis_frm 
	@ConventionNo = 'X-20151116084', 
	@dtDateCreationDe = NULL, --'2015-11-10', 
	@dtDateCreationA = NULL, --'2015-11-10', 
	@iReimprimer = 1,
	@UserID =  ''--'svc_sql_ssrs_app'

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2016-03-03		Dominique Pothier					Création du service							À partir de psCONV_RapportLettre_le_tuteur
		2016-05-03		Donald Huppé						JIRA PROD-1835 : Ne pas générer la lettre si Un_Subscriber.AddressLost = 1	
		2019-01-11		Donald Huppé						jira prod-13588	: ajhout de PaysSouscripteur
		2019-01-11		Donald Huppé						ne plus vérifier AddressLost
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettre_le_avis_frm]
	@ConventionNo varchar(30),
	@dtDateCreationDe date = NULL,
	@dtDateCreationA date = NULL,
	@LangID varchar(5) = NULL,
	@iReimprimer int = 0,
	@UserID varchar(255) = NULL
AS
BEGIN

	declare @TB_Convention table (
				ConventionID int,
				ConventionNo varchar(15),
				SubscriberID int,
				BeneficiaryID int,
				dtSignature date,
				iID_Raison_Fermeture int
			)		
	
	if @ConventionNo is not null -- Appel de SSRS ou application
		insert into @TB_Convention 
		select conventionID, ConventionNo, C.SubscriberID, BeneficiaryID, dtSignature, iID_Raison_Fermeture
		FROM dbo.Un_Convention C
			JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID --AND S.AddressLost = 0
		where conventionno = @ConventionNo

	if (@dtDateCreationDe is not null and @dtDateCreationA is not null) -- Appel de SSRS par plage de date
		begin
			insert into @TB_Convention 
			SELECT c.ConventionID, C.ConventionNo, C.SubscriberID, C.BeneficiaryID, C.dtSignature, C.iID_Raison_Fermeture
			from DocumentImpression DI
				JOIN dbo.Un_Convention c on DI.IdObjetLie = c.ConventionID
				JOIN dbo.Mo_Human h on h.HumanID = c.SubscriberID
				JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID --AND S.AddressLost = 0
			where DI.CodeTypeDocument = 'le_avis_frm'
				and Cast(DI.DateCreation as date) between @dtDateCreationDe and @dtDateCreationA
				and (
						(DI.EstEmis = 0 /*false*/ and @iReimprimer = 0 /*false*/)
						OR
						(DI.EstEmis <> 0 /*true*/ and @iReimprimer <> 0 /*true*/)
					)
				and (h.LangID = @LangID or @LangID is null)

			-- Si on est par plage de date ou convention et que ce n'est pas une réimpression, on met EstEmis = 1
			if @iReimprimer = 0
				-- juste pour être certain que ce n'est pas un appel de l'application, mais pas supposé arriver par plage de dates anyway.
				AND isnull(@UserID,'') not like '%svc_sql_ssrs_app%' 
				begin
					UPDATE DI
					SET DI.EstEmis = 1
					from DocumentImpression DI
						JOIN dbo.Un_Convention c on DI.IdObjetLie = c.ConventionID
						JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID --AND S.AddressLost = 0
						JOIN dbo.Mo_Human h on h.HumanID = c.SubscriberID
					where DI.CodeTypeDocument = 'le_avis_frm'
						and DI.EstEmis = 0
						and Cast(DI.DateCreation as date) between @dtDateCreationDe and @dtDateCreationA
						and (h.LangID = @LangID or @LangID is null)
				end
		end

	-- si on demande une impression unitaire par l'outil SSRS - et non par l'application, on met systématiquement EstEmis = 1 peu importe la valeur du paramètre @iReimprimer sélectionnée
	if @ConventionNo is not null AND isnull(@UserID,'') not like '%svc_sql_ssrs_app%' 
		begin
			UPDATE DI
			SET DI.EstEmis = 1
			from DocumentImpression DI
				JOIN @TB_Convention c on DI.IdObjetLie = c.ConventionID
			where DI.CodeTypeDocument = 'le_avis_frm'
				--ceci juste pour être certain que c'est bien un unitID qu'on a
				and di.TypeObjetLie = 0
				and DI.EstEmis = 0
				AND isnull(@UserID,'') not like '%svc_sql_ssrs_app%' 
		end

	SELECT
		Souscripteur.LangID,
		Date = dbo.fn_Mo_DateToLongDateStr(GETDATE(), Souscripteur.LangID), -- Date du jour.
		TitreSouscripteur = 
			CASE
				WHEN SxS.LangID = 'ENU' THEN SxS.ShortSexName
			ELSE SxS.LongSexName
			END, -- Ce sera monsieur, madame, Mr ou Ms selon le sexe du souscripteur et la langue du tuteur.
		NomSouscripteur = Souscripteur.LastName, -- Nom de famille du souscripteur.
		PrenomSouscripteur = Souscripteur.FirstName, -- Prénom du souscripteur.
		IDSouscripteur = Souscripteur.HumanID,
		AdresseSouscripteur = AdS.Address, -- Adresse du souscripteur, incluant le numéro civique, le nom de la rue et le numéro d’appartement s’il y a lieu.
		VilleSouscripteur = AdS.City, -- Ville du souscripteur.
		ProvinceSouscripteur = AdS.StateName, -- Province du souscripteur.
		CodePostalSouscripteur = dbo.fn_Mo_FormatZIP(AdS.ZipCode, AdS.CountryID), -- Code postal du souscripteur.
		PrenomBeneficiaire = HB.FirstName, -- Prénom du bénéficiaire.
		DateConvention = dbo.fn_Mo_DateToLongDateStr(Conv.dtSignature, Souscripteur.LangID), -- Date de signature de la convention. -- JIRA PROD-313
		NoConvention = Conv.ConventionNo, -- Numéro de la convention.
		RaisonFermeture = case when Souscripteur.LangID = 'ENU' then RaisonFermeture.vcDescriptionENU else RaisonFermeture.vcDescription end,
		PaysSouscripteur = CT.CountryName
	FROM @TB_Convention Conv
		JOIN dbo.Mo_Human Souscripteur ON Souscripteur.HumanID = Conv.SubscriberID
		JOIN Mo_Sex SxS ON Souscripteur.LangID = SxS.LangID AND Souscripteur.SexID = SxS.SexID
		JOIN dbo.Mo_Adr AdS ON AdS.AdrID = Souscripteur.AdrID
		JOIN dbo.Mo_Human HB ON HB.HumanID = Conv.BeneficiaryID
		left join dbo.tblCONV_RaisonFermeture RaisonFermeture on RaisonFermeture.iID_Raison_Fermeture = Conv.iID_Raison_Fermeture
		LEFT JOIN Mo_Country CT ON CT.CountryID = ADS.CountryID
END


