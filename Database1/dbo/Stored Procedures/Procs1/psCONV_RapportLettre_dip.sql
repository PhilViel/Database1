
/********************************************************************************************************************
Copyrights (c) 2014 Gestion Universitas inc.

Code du service		: psCONV_RapportLettre_dip
Nom du service		: Générer le diplôme
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXEC psCONV_RapportLettre_dip @ConventionNo = 'X-20151110002'

EXEC psCONV_RapportLettre_dip
	@ConventionNo = NULL,--'X-20150415113',
	@dtDateCreationDe = '2015-04-15',
	@dtDateCreationA = '2015-04-15',
	@LangID = NULL,
	@iReimprimer = 0,
	@UserID = ''

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2014-09-19		Donald Huppé						Création du service	
		2015-07-29		Steve Picard						Utilisation du "Un_Convention.TexteDiplome" au lieu de la table UN_DiplomaText
		2015-11-10		Donald Huppé						Gestion du paramètre ConventionNo (même principe que par plage de date) + ajout du paramètre @UserID
		2015-11-12		Donald Huppé						Enlever : Gestion du paramètre ConventionNo (même principe que par plage de date)
		2015-11-17		Donald Huppé						Update de DI.EstEmis = 1 sur demande unitaire
		2016-05-03		Donald Huppé						JIRA PROD-1835 : Ne pas générer la lettre si Un_Subscriber.AddressLost = 1
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettre_dip] (
	@ConventionNo varchar(30),
	@dtDateCreationDe datetime = NULL,
	@dtDateCreationA datetime = NULL,
	@LangID varchar(5) = NULL, -- Pour la demande d'impression directement dans SSRS par plage de date afin que les convention demandées soient toute de la même langue 
								--  dans le cas ou on demande sans fond 
	@iReimprimer int = 0,	
	@UserID varchar(255) = NULL
	)
	
AS
BEGIN

	declare @TB_Convention table (IDConvention int)
	
	if @ConventionNo is not null  -- Appel de SSRS ou application
		begin
		insert into @TB_Convention select conventionid FROM dbo.Un_Convention where conventionno = @ConventionNo
		end

	if @dtDateCreationDe is not null and @dtDateCreationA is not null -- Appel de SSRS par plage de date
		
		begin
		insert into @TB_Convention 
		SELECT c.ConventionID
		from DocumentImpression DI
		JOIN dbo.Un_Convention c on DI.IdObjetLie = c.ConventionID
		JOIN dbo.Mo_Human h on h.HumanID = c.BeneficiaryID
		where DI.CodeTypeDocument = 'dip'
			and LEFT(CONVERT(VARCHAR, DI.DateCreation, 120), 10) between @dtDateCreationDe and @dtDateCreationA
			and (
				(DI.EstEmis = 0 /*false*/ and @iReimprimer = 0 /*false*/)
				OR
				(DI.EstEmis <> 0 /*true*/ and @iReimprimer <> 0 /*true*/)
				)
			and (h.LangID = @LangID or @LangID is null)

		end

	DELETE CC
	FROM @TB_Convention CC
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
		JOIN dbo.Mo_Human h on h.HumanID = c.BeneficiaryID
		JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID AND S.AddressLost = 0
		where DI.CodeTypeDocument = 'dip'
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
		JOIN @TB_Convention c on DI.IdObjetLie = c.IDConvention
		where DI.CodeTypeDocument = 'dip'
		 /*ceci juste pour être certain que c'est bien un unitID qu'on a */ and di.TypeObjetLie = 0
			and DI.EstEmis = 0
			AND isnull(@UserID,'') not like '%svc_sql_ssrs_app%' 
		end

	SELECT
		C.ConventionNO,
		HB.LangID,
		BenefFirstName = HB.FirstName,
		BenefLastName = HB.LastName,
		SubsFirstName = HS.FirstName,
		SubsLastName = HS.LastName,
		DateDay = dbo.fn_Mo_DateToCompleteDayStr(MIN(U.InForceDate), HB.LangID),
		DateLongMonth = dbo.fn_Mo_TranslateMonthToStr(MIN(U.InForceDate), HB.LangID),
		DateYear = YEAR(MIN(U.InForceDate)),
		DiplomaText = IsNull(C.TexteDiplome, '') -- 2015-07-29

	FROM dbo.Un_Convention C
	join @TB_Convention TB on TB.IDConvention = c.ConventionID
	JOIN dbo.mo_Human HB ON HB.HumanID = C.BeneficiaryID
	JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
	JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
	--LEFT JOIN Un_DiplomaText DT ON DT.DiplomaTextID = C.DiplomaTextID  -- 2015-07-29
	group BY
		C.ConventionNO,
		HB.LangID,
		HB.FirstName,
		HB.LastName,
		HS.FirstName,
		HS.LastName,
		IsNull(C.TexteDiplome, '')
	order by 
		hb.LastName, hb.FirstName
END


