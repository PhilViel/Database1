/********************************************************************************************************************
Copyrights (c) 2018 Gestion Universitas inc.

Code du service		: psGENE_RapportStats_S140_NouvellesVentes
Nom du service		: psGENE_RapportStats_S140_NouvellesVentes
But 				: JIRA PROD-9924 : Obtenir les nouvelles ventes selon un nouveau souscripteur ou un nouveau benef

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						

Exemple d’appel		:	

		EXECUTE psGENE_RapportStats_S140_NouvellesVentes '2018-01-01', '2018-08-31', 0, 0, 'A', 0

Historique des modifications:
		Date			Programmeur			Description									Référence
		------------	------------------- -----------------------------------------	------------
		2018-06-06		Donald Huppé		Création du service				
		2018-09-13		Donald Huppé		Ajout de UnitID et l'age du benef
*********************************************************************************************************************/

CREATE PROCEDURE [dbo].[psGENE_RapportStats_S140_NouvellesVentes]
    (
		@dtStartDate datetime
		,@dtEndDate datetime
		,@RepID INT	= 0
		,@BossID INT = 0
		,@TypeNouvelleVente varchar(30) = 'A' /*toutes*/ --'S' Nouveau souscripteur -- 'B' Nouveau Benef
		,@iID_Regroupement_Regime INT = 0  --SELECT * FROM tblCONV_RegroupementsRegimes
    )
AS 
BEGIN

--	set ARITHABORT ON
/*
DECLARE 
	 @NomRegime VARCHAR(100)
	,@Dossier VARCHAR(1000) = '\\srvapp06\PlanDeClassification\1_GOUVERNANCE_ET_AFFAIRES_CORPO\107_BUREAU_PROJET\107-200_PROJETS_ACTIFS\PR2016-33_Outil_de_statistiques\6_NBRE_SOUSC\'
	--,@Dossier VARCHAR(1000) = '\\srvapp06\PlanDeClassification\000_PANIER_DE_CLASSEMENT\000-100_TOUS\'
	,@dtDateGeneration DATETIME
	,@DossierFinal varchar(500)
	,@vcNomFichier VARCHAR(500)


	IF EXISTS (SELECT 1 FROM SYSOBJECTS WHERE NAME = 'tblTEMP_RapportStats_S140_NouvellesVentesSouscriteurs')
		DROP TABLE tblTEMP_RapportStats_S140_NouvellesVentesSouscriteurs	


	SET	@dtDateGeneration = GETDATE()

	SET @vcNomFichier = 
				@Dossier +

				REPLACE(REPLACE(	REPLACE(LEFT(CONVERT(VARCHAR, @dtDateGeneration, 120), 25),'-',''),' ','_'),':','') + 
				'_S140_NouvellesVentesSouscriteurs_' +
				LEFT(CONVERT(VARCHAR, @dtStartDate, 120), 10) + '_au_' +
				LEFT(CONVERT(VARCHAR, @dtEndDate, 120), 10) + 
				'.CSV'


	IF @iID_Regroupement_Regime = 0
		SET @NomRegime = 'Tous'

	SELECT @NomRegime = vcDescription FROM tblCONV_RegroupementsRegimes WHERE iID_Regroupement_Regime = @iID_Regroupement_Regime
*/



/*
		IF OBJECT_ID('tempdb..#tUnite_T_IBEC')				IS NOT NULL DROP TABLE #tUnite_T_IBEC
		IF OBJECT_ID('tempdb..#tmpNouveauSousc')			IS NOT NULL DROP TABLE #tmpNouveauSousc
		IF OBJECT_ID('tempdb..#tmpNouveauBenef')			IS NOT NULL DROP TABLE #tmpNouveauBenef
*/

	SELECT * 
	INTO #tUnite_T_IBEC
	FROM fntREPR_ObtenirUniteConvT (1) t		




	--DROP TABLE #tmpPlanActif_Debut
	SELECT 
		C.SubscriberID
	INTO #tmpNouveauSousc
	FROM Un_Convention c
	JOIN Un_Unit u ON c.ConventionID = u.ConventionID
	JOIN Un_Modal m ON u.ModalID = m.ModalID
	JOIN Un_Plan p ON c.PlanID = p.PlanID
	JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
	LEFT JOIN #tUnite_T_IBEC t ON t.UnitID = u.UnitID
	GROUP BY 
		C.SubscriberID
	HAVING MIN(
			ISNULL(
				ISNULL(u.dtFirstDeposit,t.dtFirstDeposit)
				,'9999-12-31'
				)
			)  BETWEEN @dtStartDate and @dtEndDate


	--SELECT * 	from #tmpNouveauSousc	ORDER BY SubscriberID DESC


	SELECT 
		C.BeneficiaryID
	INTO #tmpNouveauBenef
	FROM Un_Convention c
	JOIN Un_Unit u ON c.ConventionID = u.ConventionID
	JOIN Un_Modal m ON u.ModalID = m.ModalID
	JOIN Un_Plan p ON c.PlanID = p.PlanID
	JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
	LEFT JOIN #tUnite_T_IBEC t ON t.UnitID = u.UnitID
	GROUP BY 
		C.BeneficiaryID
	HAVING MIN(
			ISNULL(
				ISNULL(u.dtFirstDeposit,t.dtFirstDeposit)
				,'9999-12-31'
				)
			)  BETWEEN @dtStartDate and @dtEndDate




	SELECT

		c.SubscriberID,
		IsNewSubscriberID = CASE WHEN TS.SubscriberID  IS NOT NULL THEN 1 ELSE 0 END,
		C.BeneficiaryID,
		AgeBenef = dbo.fn_Mo_Age(HBen.BirthDate,U.SignatureDate),
		IsNewBeneficiaryID = CASE WHEN TB.BeneficiaryID  IS NOT NULL THEN 1 ELSE 0 END,
		Regime = rr.vcDescription,  
		c.ConventionNo,
		U.UnitID,
		R.RepID,
		R.RepCode,
		REP = HR.FirstName + ' ' + HR.LastName,
		DIR = hb.FirstName + ' ' + HB.LastName,
		UnitesSouscrites_BRUT = SUM(U.UnitQty + ISNULL(UnitRESALL,0)),
		UnitesSouscrites_NET = SUM(U.UnitQty + ISNULL(UnitRESAFTER,0)),
		MontantSouscrit_BRUT = SUM(			CONVERT(money,CASE
											--WHEN ISNULL(SS.bIsContestWinner,0) = 1 THEN 0
											WHEN P.PlanTypeID = 'IND' THEN ISNULL(V1.Cotisation_BRUT,0)
											--WHEN ISNULL(Co.ConnectID,0) = 0 THEN 
											ELSE
												(ROUND( (U.UnitQty +ISNULL(UnitRESALL,0)) * M.PmtRate,2) * M.PmtQty) + U.SubscribeAmountAjustment
											--ELSE ISNULL(V1.CotisationFee,0) + U.SubscribeAmountAjustment
										END)),

		MontantSouscrit_NET = SUM(			CONVERT(money,CASE
											--WHEN ISNULL(SS.bIsContestWinner,0) = 1 THEN 0
											WHEN P.PlanTypeID = 'IND' THEN ISNULL(V1.Cotisation_BRUT,0)
											--WHEN ISNULL(Co.ConnectID,0) = 0 THEN 
											ELSE
												(ROUND( (U.UnitQty + ISNULL(UnitRESAFTER,0)) * M.PmtRate,2) * M.PmtQty) + U.SubscribeAmountAjustment
											--ELSE ISNULL(V1.CotisationFee,0) + U.SubscribeAmountAjustment
										END)),
		Cotisations_BRUT = ISNULL(CotisationFee_BRUT,0),
		Cotisation_NET =  ISNULL(CotisationFee_NET,0)

	FROM 
		dbo.Un_Convention C
		JOIN Mo_Human HBen on HBen.HumanID = C.BeneficiaryID
		LEFT JOIN #tmpNouveauSousc TS ON TS.SubscriberID = C.SubscriberID
		LEFT JOIN #tmpNouveauBenef TB ON TB.BeneficiaryID = C.BeneficiaryID
		JOIN un_unit U ON U.ConventionID = C.ConventionID
		LEFT JOIN (select UnitRESALL = sum(unitqty), unitid from un_unitreduction group by unitid) rALL on u.unitid = rALL.unitid
		LEFT JOIN (select UnitRESAFTER = sum(unitqty), unitid from un_unitreduction where ReductionDate > @dtEndDate group by unitid) rAfter on rAfter.unitid = u.unitid 
		JOIN dbo.Un_Modal M ON M.ModalID = U.ModalID
		JOIN Un_Plan p ON c.PlanID = p.PlanID
		JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
		LEFT JOIN dbo.Mo_Connect Co ON Co.ConnectID = U.PmtEndConnectID --AND Co.ConnectStart BETWEEN ISNULL(null,'1900/01/01') AND ISNULL(null,GETDATE())
		LEFT JOIN dbo.Un_SaleSource SS ON SS.SaleSourceID = U.SaleSourceID
		LEFT JOIN (
			SELECT 
				U.UnitID,
				Cotisation_BRUT = SUM(CASE WHEN o.OperTypeID in ( 'CHQ','PRD','NSF','CPA','RDI','TIN'/*,'OUT','RES','RET'*/) THEN Ct.Cotisation ELSE 0 END),
				CotisationFee_BRUT = SUM(CASE WHEN o.OperTypeID in ( 'CHQ','PRD','NSF','CPA','RDI','TIN'/*,'OUT','RES','RET'*/) THEN Ct.Cotisation + Ct.Fee ELSE 0 END),

				Cotisation_NET = SUM(CASE WHEN o.OperTypeID in ( 'CHQ','PRD','NSF','CPA','RDI','TIN','OUT','RES','RET') THEN Ct.Cotisation ELSE 0 END),
				CotisationFee_NET = SUM(CASE WHEN o.OperTypeID in ( 'CHQ','PRD','NSF','CPA','RDI','TIN','OUT','RES','RET') THEN Ct.Cotisation + Ct.Fee ELSE 0 END)
			FROM 
				dbo.Un_Unit U
				JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
				JOIN Un_Oper O ON O.OperID = Ct.OperID
				left join Un_Tio TIOt on TIOt.iTINOperID = o.operid
				left join Un_Tio TIOo on TIOo.iOUTOperID = o.operid
			WHERE 1=1
				------------------- Même logique que dans les rapports d'opération cashing et payment --------------------
				and o.OperDate BETWEEN  @dtStartDate and @dtEndDate
				and o.OperTypeID in ( 'CHQ','PRD','NSF','CPA','RDI','TIN','OUT','RES','RET')
				and tiot.iTINOperID is NULL -- TIN qui n'est pas un TIO
				and tioo.iOUTOperID is NULL -- OUT qui n'est pas un TIO
			GROUP BY 
				U.UnitID
				) V1 ON V1.UnitID = U.UnitID
		LEFT JOIN #tUnite_T_IBEC t ON t.UnitID = U.UnitID
		LEFT JOIN Un_Rep R ON R.RepID = ISNULL(T.RepID,U.RepID)
		LEFT JOIN Mo_Human HR on HR.HumanID = R.RepID
		LEFT JOIN (
			SELECT
				RB.RepID,
				BossID = MAX(BossID) -- au cas ou il y a 2 boss avec le même %.  alors on prend l'id le + haut. ex : repid = 497171
			FROM 
				Un_RepBossHist RB
				JOIN (
					SELECT
						RepID,
						RepBossPct = MAX(RepBossPct)
					FROM 
						Un_RepBossHist RB
					WHERE 
						RepRoleID = 'DIR'
						AND StartDate IS NOT NULL
						AND LEFT(CONVERT(VARCHAR, StartDate, 120), 10) <= LEFT(CONVERT(VARCHAR, @dtEndDate, 120), 10)
						AND (EndDate IS NULL OR LEFT(CONVERT(VARCHAR, EndDate, 120), 10) >= LEFT(CONVERT(VARCHAR, @dtEndDate, 120), 10)) 
					GROUP BY
							RepID
					) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
				WHERE RB.RepRoleID = 'DIR'
					AND RB.StartDate IS NOT NULL
					AND LEFT(CONVERT(VARCHAR, RB.StartDate, 120), 10) <= LEFT(CONVERT(VARCHAR, @dtEndDate, 120), 10)
					AND (RB.EndDate IS NULL OR LEFT(CONVERT(VARCHAR, RB.EndDate, 120), 10) >= LEFT(CONVERT(VARCHAR, @dtEndDate, 120), 10))
				GROUP BY
					RB.RepID
		) RepDIR on RepDIR.RepID = R.RepID
		LEFT JOIN Mo_Human HB ON HB.HumanID = RepDIR.BossID
	WHERE 1=1

		AND (
			 @TypeNouvelleVente = 'A'
			OR
			(@TypeNouvelleVente = 'S' AND TS.SubscriberID  IS NOT NULL)
			OR
			(@TypeNouvelleVente = 'B' AND TB.BeneficiaryID IS NOT NULL)
			)

		AND
			ISNULL(
				ISNULL(u.dtFirstDeposit,t.dtFirstDeposit)
				,'9999-12-31'
				)
			BETWEEN @dtStartDate and @dtEndDate
		
		AND (RR.iID_Regroupement_Regime = @iID_Regroupement_Regime OR @iID_Regroupement_Regime = 0)
			--and c.ConventionNo = 'X-20160721011'
			--AND C.SubscriberID = 809045

		AND (R.repid =		 @RepID  OR @RepID	= 0)
		AND	(RepDIR.BossID = @BossID OR @BossID = 0)

	GROUP BY 
		c.SubscriberID,
		C.BeneficiaryID,
		HBen.BirthDate,U.SignatureDate,
		TS.SubscriberID,
		TB.BeneficiaryID,
		rr.vcDescription, 
		c.ConventionNo,
		U.UnitID,
		ISNULL(CotisationFee_BRUT,0),
		ISNULL(CotisationFee_NET,0),
		R.RepID,
		R.RepCode,
		HR.FirstName,
		HR.LastName,
		hb.FirstName,
		HB.LastName

	ORDER BY c.SubscriberID, C.BeneficiaryID,c.ConventionNo


	--set ARITHABORT OFF



END