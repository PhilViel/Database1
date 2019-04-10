/********************************************************************************************************************
Copyrights (c) 2014 Gestion Universitas inc.

Code du service		: psCONV_RapportLettre_facade_Convention
Nom du service		: Générer la facade d'un groupe d'unité d'une convention
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXEC psCONV_RapportLettre_facade_Convention @UnitID = 526908
EXEC psCONV_RapportLettre_facade_Convention @UnitID = NULL, @ConventionNo = 'X-20130307012' 
EXEC psCONV_RapportLettre_facade_Convention @UnitID = NULL, @ConventionNo = 'I-20151217005' 

EXEC psCONV_RapportLettre_facade_Convention
	@UnitID = NULL, -- 714342,
	@dtDateCreationDe = null,--'2015-11-02',
	@dtDateCreationA = null,--'2015-11-02',
	@LangID = NULL,
	@iReimprimer = 1,
	@ConventionNo = 'X-20150415113',
	@UserID = 'dhuppe' --'dhuppe'

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2014-09-19		Donald Huppé						Création du service	
		2014-12-04		Donald Huppé						Ajout du paramètre @ConventionNo pour sortir toutes les faces d'une convention. Ce paramètre bypass tous les autres
		2015-04-21		Donald Huppé						Modifications pour la nouvelle version de la facade
		2015-08-04		Donald Huppé						Ajout de dbo.
		2015-11-02		Donald Huppé						Si @ConventionNo est saisi, on sort seulement les facades de cette convention créé dans la plage de date saisie (si la plage est saisie)
		2015-11-16		Donald Huppé						Mettre les montants à 0 pour un plan individuel.
		2015-11-17		Donald Huppé						Ajout du parametre UserID + update de DI.EstEmis = 1 sur demande unitaire
		2016-01-19		Donald Huppé						JIRA REF-3677 : Ajout des montants pour l'individuel
		2016-03-14		Donald Huppé						JIRA BD-36 : Si le représentant du groupe d’unités est Siège Social alors sur la façade, mettre le nom du représentant du souscripteur.
		2016-05-03		Donald Huppé						JIRA PROD-1835 : Ne pas générer la lettre si Un_Subscriber.AddressLost = 1
		2016-02-06      Maxime Martel						JIRA PROD-2408 : Afficher le nom du représtant sur le souscripteur au lieu du groupe d'unité
		2018-09-07		Maxime Martel						JIRA MP-699 Ajout de OpertypeID COU
		2018-11-08		Maxime Martel						utilisation de planDesc_Enu de la table plan
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettre_facade_Convention] 
	@UnitID varchar(30),
	@dtDateCreationDe datetime = NULL,
	@dtDateCreationA datetime = NULL,
	@LangID varchar(5) = NULL,
	@iReimprimer int = 0,
	@ConventionNo varchar(30)= NULL,
	@UserID varchar(255) = NULL
AS
BEGIN

	declare @Unite table (UnitID int, RepID int)		

	if @ConventionNo is not NULL and (@dtDateCreationDe is null and @dtDateCreationA is null) -- pas de plage de dates saisie
	-- On sort toutes les facades si pas de dates demandées
		BEGIN
		
		INSERT INTO @Unite
		SELECT 
			u.UnitID,
			RepID = case 
					when U.RepID = 149876 then s.repid -- JIRA BD-36 : Si le représentant du groupe d’unités est Siège Social alors sur la façade, mettre le nom du représentant du souscripteur.
					else U.RepID 
					end
		FROM dbo.Un_Unit u
		JOIN dbo.Un_Convention c on u.ConventionID = c.ConventionID
		JOIN dbo.Un_Subscriber s on c.SubscriberID = s.SubscriberID 
		WHERE 
			c.ConventionNo = @ConventionNo
			AND u.UnitQty > 0
			AND S.AddressLost = 0

		GOTO Convention

		END

	if @UnitID is not null
		begin
		insert into @Unite 
		SELECT 
			u.UnitID,
			RepID = case 
					when U.RepID = 149876 then s.repid -- JIRA BD-36 : Si le représentant du groupe d’unités est Siège Social alors sur la façade, mettre le nom du représentant du souscripteur.
					else U.RepID 
					end
		FROM dbo.Un_Unit u
		JOIN dbo.Un_Convention c on u.ConventionID = c.ConventionID
		JOIN dbo.Un_Subscriber s on c.SubscriberID = s.SubscriberID 
		WHERE 
			u.UnitID = @UnitID
			AND S.AddressLost = 0
		end


	if @dtDateCreationDe is not null and @dtDateCreationA is not null
		begin
		insert into @Unite 
		SELECT 
			u.UnitID,
			RepID = case 
					when U.RepID = 149876 then s.repid -- JIRA BD-36 : Si le représentant du groupe d’unités est Siège Social alors sur la façade, mettre le nom du représentant du souscripteur.
					else U.RepID 
					end
		from dbo.DocumentImpression DI
		join dbo.Un_Unit u on DI.IdObjetLie = u.UnitID
		join dbo.Un_Convention c on u.ConventionID = c.ConventionID
		JOIN dbo.Un_Subscriber s on c.SubscriberID = s.SubscriberID 
		join dbo.Mo_Human h on h.HumanID = c.SubscriberID
		where DI.CodeTypeDocument = 'facade'
			and LEFT(CONVERT(VARCHAR, DI.DateCreation, 120), 10) between @dtDateCreationDe and @dtDateCreationA
			and (
				(DI.EstEmis = 0 /*false*/ and @iReimprimer = 0 /*false*/)
				OR
				(DI.EstEmis <> 0 /*true*/ and @iReimprimer <> 0 /*true*/)
				)
			and (h.LangID = @LangID or @LangID is null)
			and (c.ConventionNo = @ConventionNo or @ConventionNo is null)
			AND S.AddressLost = 0
		end

	-- Si on est par plage de date et que ce n'est pas une réimpression, on met EstEmis = 1
	if @dtDateCreationDe is not null and @dtDateCreationA is not null and @iReimprimer = 0
		begin
		UPDATE DI
		SET DI.EstEmis = 1
		from dbo.DocumentImpression DI
		join dbo.Un_Unit u on DI.IdObjetLie = u.UnitID
		join dbo.Un_Convention c on u.ConventionID = c.ConventionID
		join dbo.Mo_Human h on h.HumanID = c.SubscriberID
		JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID 
		where DI.CodeTypeDocument = 'facade'
			AND DI.EstEmis = 0
			AND LEFT(CONVERT(VARCHAR, DI.DateCreation, 120), 10) between @dtDateCreationDe and @dtDateCreationA
			AND (h.LangID = @LangID or @LangID is null)
			AND (c.ConventionNo = @ConventionNo or @ConventionNo is null)
			AND S.AddressLost = 0
		end

	-- si on demande une impression unitaire par l'outil SSRS - et non par l'application, on met systématiquement EstEmis = 1 peu importe la valeur du paramètre @iReimprimer sélectionnée
	if @UnitID is not null AND isnull(@UserID,'') not like '%svc_sql_ssrs_app%' 
		begin
		UPDATE DI
		SET DI.EstEmis = 1
		from DocumentImpression DI
		JOIN @Unite u on DI.IdObjetLie = u.UnitID
		where DI.CodeTypeDocument = 'facade' /*ceci juste pour être certain que c'est bien un unitID qu'on a */ and di.TypeObjetLie = 1
			and DI.EstEmis = 0
			AND isnull(@UserID,'') not like '%svc_sql_ssrs_app%' 
		end

Convention:


	SELECT 
		UN.UnitID,
		MntDepotCotisation = ISNULL(MntDepotCotisation,0), 
		MntDepotAss = ISNULL(MntDepotAss,0),
		MntDepotAssTaxe = ISNULL(MntDepotAssTaxe,0),
		MntTotalDepot = ISNULL(MntTotalDepot,0)
	INTO #DEPOT
	FROM @Unite UN	
	LEFT JOIN (
		SELECT 
			op.UnitID, 
			MntDepotCotisation = sum(ct.Cotisation), 
			MntDepotAss = sum(ct.BenefInsur + ct.SubscInsur),
			MntDepotAssTaxe = sum(ct.TaxOnInsur),
			MntTotalDepot = sum(ct.Cotisation + ct.BenefInsur + ct.SubscInsur + ct.TaxOnInsur)
		FROM dbo.Un_Cotisation ct 
		JOIN dbo.Un_Oper o ON ct.OperID = o.OperID
		JOIN (
			SELECT u.UnitID,OperID =  min(o.OperID)
			FROM dbo.Un_Convention c
			join dbo.Un_Plan P on c.PlanID = p.PlanID
			JOIN dbo.Un_Unit u ON c.ConventionID = u.ConventionID
			JOIN @Unite UN ON UN.UnitID = U.UnitID
			JOIN dbo.Un_Cotisation ct ON u.UnitID = ct.UnitID
			JOIN dbo.Un_Oper o ON ct.OperID = o.OperID
			LEFT JOIN dbo.Un_OperCancelation oc1 on oc1.OperSourceID = o.OperID
			LEFT JOIN dbo.Un_OperCancelation oc2 on oc2.OperID = o.OperID
			WHERE P.PlanTypeID = 'IND'
				AND o.OperTypeID IN ('CPA','RDI','CHQ','COU')
				AND oc1.OperSourceID IS NULL
				AND oc2.OperID IS NULL
			GROUP by u.UnitID
			)op ON op.OperID = o.OperID and op.UnitID = ct.UnitID
		GROUP BY op.UnitID
		)T ON T.UnitID = UN.UnitID



	SELECT
		HS.LangID,
		U.ConventionID,
		U.UnitID,
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
		PlanDesc = case 
					when HS.LangID = 'ENU' THEN UPPER(p.PlanDesc_ENU) 
					ELSE p.PlanDesc END,
		S.RepID,
		RepName = HR.LastName + ', ' + HR.FirstName,
		InForceDate = dbo.fn_mo_DateToLongDateStr([dbo].[fnCONV_ObtenirEntreeVigueurObligationLegale](C.ConventionID), HS.LangID),
		TerminatedDate = dbo.fn_mo_DateToLongDateStr((SELECT [dbo].[fnCONV_ObtenirDateFinRegime](C.ConventionID,'R',NULL)), HS.LangID),
		YearQualif = C.YearQualif,
		ConvLastDepositDate = 					
						dbo.fn_mo_DateToLongDateStr(
							CASE 
								WHEN ISNULL(U.LastDepositForDoc,0) <= 0 THEN
									CASE 
										WHEN M.PmtQTY = 1 THEN U.InforceDate
										ELSE DATEADD(MONTH,(12/M.PmtByYearID)*(M.PmtQTY-1), CAST(CAST(YEAR(U.InForceDate) AS CHAR(4)) + '-' + CAST(MONTH(CASE WHEN M.PmtByYearID = 1 THEN C.FirstPmtDate ELSE U.InForceDate END) AS CHAR(2)) + '-' + CAST(DAY(C.FirstPmtDate) AS CHAR(2)) AS DATETIME))
									END
								ELSE 
									U.LastDepositForDoc
							END ,HS.LangID),
		ConvReimbDate = dbo.fn_mo_DateToLongDateStr(dbo.fn_Un_EstimatedIntReimbDate (M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, U.IntReimbDateAdjust) ,HS.LangID),
		ConvDepositMode = 
			CASE C.PmtTypeID
				WHEN 'CHQ' THEN 
					CASE HS.LangID
						WHEN 'FRA' THEN 'Chèque'
						WHEN 'ENU' THEN 'Cheque'
					ELSE '???'
					END
			ELSE 
				CASE HS.LangID
					WHEN 'FRA' THEN 'Prélèvements automatiques'
					WHEN 'ENU' THEN 'Pre-authorized debits'
				ELSE '???'
				END
			END,
		ConvNbrDeposit = M.PmtQTY,
		ConvNbrUnit = dbo.fn_Mo_FloatToStr(U.UnitQTY, HS.LangID, 3, 0),
		MntTotalSouscrit = 
			CASE when c.PlanID = 4 then dbo.fn_Mo_MoneyToStr(ROUND(0,2) , HS.LangID, 1) 
			ELSE		
				dbo.fn_Mo_MoneyToStr(  (ROUND(U.UnitQTY * M.PmtRate,2) * M.PmtQty) , HS.LangID, 1)
			END,

		MntDepotCotisation = 
			CASE when c.PlanID = 4 then dbo.fn_Mo_MoneyToStr(ROUND(DEP.MntDepotCotisation,2) , HS.LangID, case when HS.LangID = 'ENU' then 0 else 1 end) 
			ELSE	
				dbo.fn_Mo_MoneyToStr( ROUND(U.UnitQTY * M.PmtRate,2) , HS.LangID, case when HS.LangID = 'ENU' then 0 else 1 end)
			END,

		MntDepotAss = 
			CASE when c.PlanID = 4 then dbo.fn_Mo_MoneyToStr(ROUND(DEP.MntDepotAss,2) , HS.LangID, case when HS.LangID = 'ENU' then 0 else 1 end) 
			ELSE	
				CASE U.WantSubscriberInsurance
					WHEN 1 THEN dbo.fn_Mo_MoneyToStr(ROUND( M.SubscriberInsuranceRate*U.UnitQty ,2), HS.LangID, case when HS.LangID = 'ENU' then 0 else 1 end)
				ELSE dbo.fn_Mo_MoneyToStr(0 , HS.LangID, case when HS.LangID = 'ENU' then 0 else 1 end)
				END
			END,

		MntDepotAssTaxe = 
			CASE when c.PlanID = 4 then dbo.fn_Mo_MoneyToStr(ROUND(DEP.MntDepotAssTaxe,2) , HS.LangID, case when HS.LangID = 'ENU' then 0 else 1 end) 
			ELSE	
				CASE U.WantSubscriberInsurance
					WHEN 1 THEN dbo.fn_Mo_MoneyToStr(ROUND( (ROUND(M.SubscriberInsuranceRate*U.UnitQty,2) * ST.StateTaxPct) + .0049 ,2), HS.LangID, case when HS.LangID = 'ENU' then 0 else 1 end)
				ELSE dbo.fn_Mo_MoneyToStr(0 , HS.LangID, case when HS.LangID = 'ENU' then 0 else 1 end)
				END
			END,

		MntTotalDepot = 
			CASE when c.PlanID = 4 then dbo.fn_Mo_MoneyToStr(ROUND(DEP.MntTotalDepot,2) , HS.LangID, case when HS.LangID = 'ENU' then 0 else 1 end) 
			ELSE
				CASE U.WantSubscriberInsurance
					WHEN 1 THEN dbo.fn_Mo_MoneyToStr(ROUND(U.UnitQTY * M.PmtRate,2) +
						ROUND(M.SubscriberInsuranceRate*U.UnitQty,2) +
						ROUND((ROUND(M.SubscriberInsuranceRate*U.UnitQty,2) * ST.StateTaxPct) + .0049,2), HS.LangID,case when HS.LangID = 'ENU' then 0 else 1 end)
				ELSE dbo.fn_Mo_MoneyToStr(ROUND(U.UnitQTY * M.PmtRate,2) , HS.LangID, case when HS.LangID = 'ENU' then 0 else 1 end)
				END
			END
		,DateSignature = dbo.fn_mo_DateToLongDateStr(u.SignatureDate, HS.LangID)
		,RepTelephone = dbo.fn_Mo_FormatPhoneNo(ISNULL(tt.vcTelephone,''),'CAN') 
	FROM dbo.Un_Unit U
	join @Unite pu on pu.UnitID = u.UnitID
	JOIN dbo.Un_Convention C ON (U.ConventionID = C.ConventionID)
	JOIN dbo.Un_Subscriber S ON (S.SubscriberID = C.SubscriberID)
	JOIN dbo.Mo_Human HS ON (HS.HumanID = S.SubscriberID)
	JOIN dbo.Mo_Adr Adr ON (Adr.AdrID = HS.AdrID)
	JOIN dbo.Mo_Human HB ON (HB.HumanID = C.BeneficiaryID)
	LEFT JOIN dbo.Mo_Human HR ON (HR.HumanID = S.RepID)
	JOIN dbo.Un_Modal M ON (M.ModalID = U.ModalID)
	JOIN dbo.Un_Plan P ON (P.PlanID = M.PlanID)
	LEFT JOIN dbo.Mo_State ST ON (ST.StateID = S.StateID)
	LEFT JOIN dbo.tblGENE_Telephone tt on S.RepID = tt.iID_Source and tt.iID_Type = 4 
	                                  and getdate() BETWEEN tt.dtDate_Debut and isnull(tt.dtDate_Fin,'9999-12-31')
	--LEFT JOIN (
	--	select 
	--		RepID, RepTelephone
	--	from (
	--		SELECT 
	--			r.RepID,
	--			-- On prend le max juste pour s'assurer qu'on sort juste un tel travail actif, ce qui est théoriquement le cas
	--			RepTelephone = dbo.fn_Mo_FormatPhoneNo( max(ISNULL(tt.vcTelephone,'')),'CAN') 
	--		FROM 
	--			un_rep r
	--			LEFT JOIN dbo.tblGENE_Telephone tt on r.RepID = tt.iID_Source and getdate() BETWEEN tt.dtDate_Debut and isnull(tt.dtDate_Fin,'9999-12-31') and tt.iID_Type = 4
	--		group BY
	--			r.RepID
	--		)V
	--	)rt on S.RepID = rt.RepID
	LEFT JOIN #DEPOT DEP ON DEP.UnitID = u.UnitID
	ORDER BY HS.LastName, HS.FirstName

end