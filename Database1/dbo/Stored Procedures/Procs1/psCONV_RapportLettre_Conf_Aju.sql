/********************************************************************************************************************
Copyrights (c) 2014 Gestion Universitas inc.

Code du service		: psCONV_RapportLettre_Conf_Aju
Nom du service		: Générer la lettre d'ajout d'unité dans une convention
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	
EXEC psCONV_RapportLettre_Conf_Aju 
	@UnitID = NULL,
	@dtDateCreationDe = '2015-12-01',
	@dtDateCreationA = '2015-12-31',
	@LangID  = NULL,
	@iReimprimer = 1,
	@ConventionNo='U-20040603006',
	@userID = 'dhuppe'--'svc_sql_ssrs_app'

EXEC psCONV_RapportLettre_Conf_Aju_test 
	@UnitID = 714903

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2015-04-14		Donald Huppé						Création du service	
		2015-09-10		Donald Huppé						Prendre le Rep de l'ajout d'unité
		2015-10-27		Donald Huppé						Ajout d'une boucle pour génrer les lettres en lot
		2015-10-30		Donald Huppé						Ajout de SubscribeAmountAjustment dans le montant du dépôt et ancien dépôt
		2015-11-02		Donald Huppé						Ajout paramètre @ConventionNo, utiliser avec la plage de date, pour retrouyver les ajouts d'une convention faite dans la plage demandée
		2015-11-04		Donald Huppé						Correction pour calcul du montant forfaitaire ajouté
		2015-11-17		Donald Huppé						Ajout du parametre UserID + update de DI.EstEmis = 1 sur demande unitaire
		2016-05-03		Donald Huppé						JIRA PROD-1835 : Ne pas générer la lettre si Un_Subscriber.AddressLost = 1
		2018-11-08      Maxime Martel						Utiliser planDesc_ENU de la table plan 
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettre_Conf_Aju] 
	@UnitID varchar(30),
	@dtDateCreationDe datetime = NULL,
	@dtDateCreationA datetime = NULL,
	@LangID varchar(5) = NULL,
	@iReimprimer int = 0,
	@ConventionNo varchar(30) = NULL,
	@UserID varchar(255) = NULL
AS
BEGIN

	declare @Unite table (UnitID int)		
	
	if @UnitID is not null
		begin
		insert into @Unite values (@UnitID)
		end


	if @dtDateCreationDe is not null and @dtDateCreationA is not null
		begin
		insert into @Unite 
		SELECT u.UnitID
		from DocumentImpression DI
		JOIN dbo.Un_Unit u on DI.IdObjetLie = u.UnitID
		JOIN dbo.Un_Convention c on u.ConventionID = c.ConventionID
		JOIN dbo.Mo_Human h on h.HumanID = c.SubscriberID
		where DI.CodeTypeDocument = 'le_conf_aju'
			and LEFT(CONVERT(VARCHAR, DI.DateCreation, 120), 10) between @dtDateCreationDe and @dtDateCreationA
			and (
				(DI.EstEmis = 0 /*false*/ and @iReimprimer = 0 /*false*/)
				OR
				(DI.EstEmis <> 0 /*true*/ and @iReimprimer <> 0 /*true*/)
				)
			and (h.LangID = @LangID or @LangID is null)
			and (c.ConventionNo = @ConventionNo or @ConventionNo is null)
		order by u.UnitID
		end

	DELETE UU
	FROM @Unite UU
		JOIN dbo.Un_Unit U	ON U.UnitID = UU.UnitID
		JOIN dbo.Un_Convention C ON U.ConventionID = C.ConventionID
		JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID
	WHERE S.AddressLost = 1

	-- Si on est par plage de date et que ce n'est pas une réimpression, on met EstEmis = 1
	if @dtDateCreationDe is not null and @dtDateCreationA is not null and @iReimprimer = 0
		begin
		UPDATE DI
		SET DI.EstEmis = 1
		from DocumentImpression DI
		JOIN dbo.Un_Unit u on DI.IdObjetLie = u.UnitID
		JOIN dbo.Un_Convention c on u.ConventionID = c.ConventionID
		JOIN dbo.Mo_Human h on h.HumanID = c.SubscriberID
		JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID AND S.AddressLost = 0
		where DI.CodeTypeDocument = 'le_conf_aju'
			and DI.EstEmis = 0
			and LEFT(CONVERT(VARCHAR, DI.DateCreation, 120), 10) between @dtDateCreationDe and @dtDateCreationA
			and (h.LangID = @LangID or @LangID is null)
			and (c.ConventionNo = @ConventionNo or @ConventionNo is null)
		end

	-- si on demande une impression unitaire par l'outil SSRS - et non par l'application, on met systématiquement EstEmis = 1 peu importe la valeur du paramètre @iReimprimer sélectionnée
	if @UnitID is not null AND isnull(@UserID,'') not like '%svc_sql_ssrs_app%' 
		begin
		UPDATE DI
		SET DI.EstEmis = 1
		from DocumentImpression DI
		JOIN @Unite u on DI.IdObjetLie = u.UnitID
		where DI.CodeTypeDocument = 'le_conf_aju' /*ceci juste pour être certain que c'est bien un unitID qu'on a */ and di.TypeObjetLie = 1
			and DI.EstEmis = 0
			AND isnull(@UserID,'') not like '%svc_sql_ssrs_app%' 
		end

--select * from @Unite

CREATE TABLE #tmpAju(
	[LangID] varchar(150) NULL,
	[ConventionID] int NULL,
	[SubscriberID] int NULL,
	[AppelLong] varchar(150) NULL,
	[AppelCourt] varchar(150) NULL,
	[SubscriberLastName] varchar(150) NULL,
	[SubscriberFirstName] varchar(150) NULL,
	[SubscriberAddress] varchar(150) NULL,
	[SubscriberCity] varchar(150) NULL,
	[SubscriberState] varchar(150) NULL,
	[SubscriberZipCode] varchar(150) NULL,
	[SubscriberPhone] varchar(150) NULL,
	[BeneficiaryFirstName] varchar(150) NULL,
	[BeneficiaryLastName] varchar(150) NULL,
	[BeneficiaryBirthDate] varchar(150) NULL,
	[ConventionNo] varchar(150) NULL,
	[PlanDesc] varchar(150) NULL,
	[RepID] int NULL,
	[RepName] varchar(150) NULL,
	[RepTelephone] varchar(150) NULL,
	[YearQualif] int NULL,
	[ConvNbrUnitTotal] varchar(150)  NULL,
	[QteAjoutUnité] varchar(150) NULL,
	[MntSouscritAjout] varchar(150) NULL,
	[MntTotalAncienDepot] varchar(150) NULL,
	[MntTotalNouveauDepot] varchar(150) NULL,
	[FraisSouscriptionAjout] varchar(150) NULL,
	[ModeDepotAjout] varchar(150) NULL,
	[DateDpotUnique] varchar(150) NULL,
	[BenefSex] varchar(150) NULL
	)

create table #Unite(
		ConventionID int, 
		UnitID int ,
		UnitQty float,
		PmtByYearID INT,
		PmtQty int,
		ModeDepotAjout varchar(50)

	)

while (select count(*) from @Unite) > 0
begin
	select top 1 @UnitID = UnitID from @Unite

	delete from #Unite

	-- l'ajout d'unité
	insert into #Unite
	select u.ConventionID, u.UnitID,u.UnitQty, m.PmtByYearID,m.PmtQty
			,ModeDepotAjout = case 
					when m.PmtByYearID = 1 and PmtQty = 1 then 'Unique'
					when m.PmtByYearID = 1 and PmtQty > 1 then 'Annuel'
					when m.PmtByYearID = 12 then 'Mensuel'
					else 'Autre'
					End
	--into #Unite
	FROM dbo.Un_Unit u
	join Un_Modal m on u.ModalID = m.ModalID
	--join @Unite un on u.UnitID = un.UnitID
	where @UnitID = u.UnitID


	-- Les autres groupes d'unité en épargne de la convention ayant la même modalité (non forfaitaire) que celle ajoutée
	insert into #Unite
	select u.ConventionID, u.UnitID,u.UnitQty, m.PmtByYearID,m.PmtQty,ModeDepotAjout
	FROM dbo.Un_Unit u
	join (
		select 
			us.unitid,
			uus.startdate,
			us.UnitStateID
		from 
			Un_UnitunitState us
			join (
				select 
				unitid,
				startdate = max(startDate)
				from un_unitunitstate
				--where startDate < DATEADD(d,1 ,'2014-02-08')
				group by unitid
				) uus on uus.unitid = us.unitid 
					and uus.startdate = us.startdate 
					and us.UnitStateID in ('EPG','TRA')
		)uss on u.UnitID = uss.UnitID
	join #Unite un on u.ConventionID = un.ConventionID and un.unitID <> u.UnitID
	join Un_Modal m on u.ModalID = m.ModalID and m.PmtByYearID = un.PmtByYearID /*and m.PmtQty = un.PmtQty*/ /*(non forfaitaire -->*/ and m.PmtQty > 1



	insert into #tmpAju
	SELECT
		HS.LangID,
		U.ConventionID,
		c.SubscriberID,
		--U.UnitID,
		AppelLong = sex.LongSexName,
		AppelCourt = sex.ShortSexName,
		SubscriberLastName = HS.LastName,
		SubscriberFirstName = HS.FirstName,
		SubscriberAddress = Adr.Address,
		SubscriberCity = Adr.City,
		SubscriberState = Adr.StateName,
		SubscriberZipCode = dbo.fn_Mo_FormatZIP(Adr.ZipCode, ADR.CountryID),
		SubscriberPhone = dbo.fn_Mo_FormatPhoneNo(Adr.Phone1,ADR.CountryID),
		BeneficiaryFirstName = HB.FirstName,
		BeneficiaryLastName = HB.LastName,
		BeneficiaryBirthDate = dbo.fn_mo_DateToLongDateStr(HB.BirthDate, HS.LangID),
		C.ConventionNo,
		PlanDesc = case when HS.LangID = 'ENU' then p.PlanDesc_ENU else p.PlanDesc end,
		S.RepID,
		RepName =  HR.FirstName + ' ' + HR.LastName,
		RepTelephone = dbo.fn_Mo_FormatPhoneNo( max(ISNULL(tt.vcTelephone,'')),'can'),

		YearQualif = C.YearQualif,
		ConvNbrUnitTotal = dbo.fn_Mo_FloatToStr(0, HS.LangID, 3, 0), -- non utilisé dans la lettre
		QteAjoutUnité = dbo.fn_Mo_FloatToStr(uajout.UnitQty, HS.LangID, 3, 0),
		MntSouscritAjout = dbo.fn_Mo_MoneyToStr( ROUND(uajout.UnitQTY * majout.PmtRate,2) * majout.PmtQty + ROUND(uajout.SubscribeAmountAjustment,2) , HS.LangID, 1),

		MntTotalAncienDepot = dbo.fn_Mo_MoneyToStr( -- le total des dépôt des groupe qui ont le même type de modalité que celui ajouté
						sum(
							case when u.TerminatedDate is null and  uajout.UnitID <> u.UnitID and m.PmtByYearID = majout.PmtByYearID /*and m.PmtQty = majout.PmtQty*/ then
									CASE U.WantSubscriberInsurance
										WHEN 1 THEN 
												ROUND(U.UnitQTY * M.PmtRate,2) +
												ROUND(M.SubscriberInsuranceRate*U.UnitQty,2) +
												ROUND((ROUND(M.SubscriberInsuranceRate*U.UnitQty,2) * ST.StateTaxPct) + .0049,2)
												 + ROUND(U.SubscribeAmountAjustment,2)
										ELSE
												ROUND(U.UnitQTY * M.PmtRate,2) 
												 + ROUND(U.SubscribeAmountAjustment,2)
										END
							else 0 
							end
							), HS.LangID, 1),

		MntTotalNouveauDepot = dbo.fn_Mo_MoneyToStr( 
						sum(
							case when (m.PmtByYearID = majout.PmtByYearID /**/ and majout.PmtQty <> 1/**/ /*and m.PmtQty = majout.PmtQty*/)  -- le total des dépôt des groupe qui ont le même type de modalité que celui ajouté
										or (majout.PmtQty = 1 and uajout.UnitID = u.UnitID)  -- OU le montant du dépot unique
								then
									CASE U.WantSubscriberInsurance
										WHEN 1 THEN 
												ROUND(U.UnitQTY * M.PmtRate,2) +
												ROUND(M.SubscriberInsuranceRate*U.UnitQty,2) +
												ROUND((ROUND(M.SubscriberInsuranceRate*U.UnitQty,2) * ST.StateTaxPct) + .0049,2)
												 + ROUND(U.SubscribeAmountAjustment,2)
										ELSE
												ROUND(U.UnitQTY * M.PmtRate,2) 
												 + ROUND(U.SubscribeAmountAjustment,2)
										END
							else 0 
							end
							), HS.LangID, 1)

		,FraisSouscriptionAjout = dbo.fn_Mo_MoneyToStr(uajout.UnitQty * 200, HS.LangID, 1)
		,ModeDepotAjout
		,DateDpotUnique = LEFT(CONVERT(VARCHAR, uajout.dtFirstDeposit , 103), 10)
		,BenefSex = hb.SexID

	FROM dbo.Un_Unit U
	join #Unite un on un.UnitID = u.UnitID

	JOIN dbo.Un_Unit uajout on uajout.UnitID = @UnitID
	join Un_Modal majout on majout.ModalID = uajout.ModalID
	
	JOIN dbo.Un_Convention C ON (U.ConventionID = C.ConventionID)
	JOIN dbo.Un_Subscriber S ON (S.SubscriberID = C.SubscriberID)
	JOIN dbo.Mo_Human HS ON (HS.HumanID = S.SubscriberID)
	JOIN Mo_Sex sex on hs.SexID = sex.SexID and hs.LangID = sex.LangID
	JOIN dbo.Mo_Adr Adr ON (Adr.AdrID = HS.AdrID)
	JOIN dbo.Mo_Human HB ON (HB.HumanID = C.BeneficiaryID)
	LEFT JOIN dbo.Mo_Human HR ON (HR.HumanID = uajout.RepID)
	JOIN Un_Modal M ON (M.ModalID = U.ModalID)
	JOIN Un_Plan P ON (P.PlanID = M.PlanID)
	LEFT JOIN Mo_State ST ON (ST.StateID = S.StateID)
	LEFT JOIN tblGENE_Telephone tt on HR.HumanID = tt.iID_Source and getdate() BETWEEN tt.dtDate_Debut and isnull(tt.dtDate_Fin,'9999-12-31') and tt.iID_Type = 4

	GROUP BY

		HS.LangID,
		U.ConventionID,
		c.SubscriberID,
		--U.UnitID,
		sex.LongSexName,
		sex.ShortSexName,
		HS.LastName,
		HS.FirstName,
		Adr.Address,
		Adr.City,
		Adr.StateName,
		dbo.fn_Mo_FormatZIP(Adr.ZipCode, ADR.CountryID),
		dbo.fn_Mo_FormatPhoneNo(Adr.Phone1,ADR.CountryID),
		HB.FirstName,
		HB.LastName,
		dbo.fn_mo_DateToLongDateStr(HB.BirthDate, HS.LangID),
		C.ConventionNo,
		case when HS.LangID = 'ENU' then p.PlanDesc_ENU else p.PlanDesc end,
		S.RepID,
		HR.LastName,HR.FirstName,

		--InForceDate = dbo.fn_mo_DateToLongDateStr([dbo].[fnCONV_ObtenirEntreeVigueurObligationLegale](C.ConventionID), HS.LangID),

		C.YearQualif,

		uajout.UnitQty
		,ModeDepotAjout
		,uajout.dtFirstDeposit
		,hb.SexID
		,majout.PmtRate,majout.PmtQty 
		,uajout.SubscribeAmountAjustment

	
	delete from @Unite where UnitID = @UnitID

end


	select * from #tmpAju order by SubscriberLastName, SubscriberFirstname

end