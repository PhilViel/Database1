﻿/********************************************************************************************************************
Copyrights (c) 2017 Gestion Universitas inc.

Code du service		: psCONV_RapportLettre_le_promo_gp
Nom du service		: Générer la lettre de bienvenue au grand-parent
But 				: jira prod-3491
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXEC psCONV_RapportLettre_le_promo_gp @ConventionNo = 'I-20160113003'

EXEC psCONV_RapportLettre_le_ems_gp
	@ConventionNo = 'X-20151116083'
	--,@dtDateCreationDe = NULL,--'2015-11-11',
	--@dtDateCreationA = NULL,--'2015-11-11',
	--@LangID = NULL,
	--@iReimprimer = 0,
	--@UserID = ''-- 'svc_sql_ssrs_app'
drop proc psCONV_RapportLettre_le_ems_gp
Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description										Référence
		------------	----------------------------------	-----------------------------------------		------------
		2017-01-17		Donald Huppé						Création du service								basé sur psCONV_RapportLettre_le_ems
		2018-11-08		Maxime Martel						Utilisation de planDesc_ENU de la table plan
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettre_le_promo_gp] 
	@ConventionNo varchar(30)
	--@dtDateCreationDe datetime = NULL,
	--@dtDateCreationA datetime = NULL,
	--@LangID varchar(5) = NULL,
	--@iReimprimer int = 0,
	--@UserID varchar(255) = NULL
AS
BEGIN

	declare @Convention table (IDConvention int)		
	
	if @ConventionNo is not null  -- Appel de SSRS ou application
		begin
		insert into @Convention select conventionid FROM dbo.Un_Convention where conventionno = @ConventionNo
		end

/*
	if @dtDateCreationDe is not null and @dtDateCreationA is not null -- Appel de SSRS par plage de date
		begin
		insert into @Convention 
		SELECT c.ConventionID
		from DocumentImpression DI
		JOIN dbo.Un_Convention c on DI.IdObjetLie = c.ConventionID
		JOIN dbo.Mo_Human h on h.HumanID = c.SubscriberID
		where DI.CodeTypeDocument = 'le_ems'
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
		where DI.CodeTypeDocument = 'le_ems'
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
		where DI.CodeTypeDocument = 'le_ems' /*ceci juste pour être certain que c'est bien un unitID qu'on a */ and di.TypeObjetLie = 0
			and DI.EstEmis = 0
			AND isnull(@UserID,'') not like '%svc_sql_ssrs_app%' 
		end
*/
	
	SELECT 
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
		PrenomBenef = hb.firstname,
		NomBenef = hb.lastname,
		C.ConventionNo,
		C.BeneficiaryID,
		Regime = CASE WHEN hs.LangID = 'ENU' THEN p.PlanDesc_ENU ELSE p.PlanDesc END
		,p.PlanTypeID
		,GenreBenef = sexB.SexID
		,PlanClassification = [dbo].[fnCONV_ObtenirDossierClient](c.subscriberID,1) + '\' + replace(LEFT(CONVERT(VARCHAR, getdate(), 120), 10),'-','') + '_le_promo_gp'-- '20130904_le_17'
		
	FROM 
		Un_Convention C 
		join @Convention pc on pc.IDConvention = c.ConventionID
		join un_plan p on c.PlanID = p.PlanID
		JOIN dbo.Un_Subscriber S on C.subscriberID = S.SubscriberID 
		JOIN dbo.Mo_Human HS on S.SubscriberID = HS.HumanID
		JOIN dbo.Mo_Human hb ON C.BeneficiaryID = hb.HumanID
		join Mo_Sex sex ON sex.SexID = hs.SexID AND sex.LangID = hs.LangID
		JOIN dbo.Mo_Adr A on HS.AdrID = A.AdrID
		JOIN dbo.Mo_Adr Ab on Hb.AdrID = Ab.AdrID
		join Mo_Sex sexB ON sexb.SexID = hb.SexID AND sexb.LangID = hb.LangID
	order by 
		HS.LastName , hs.FirstName
END