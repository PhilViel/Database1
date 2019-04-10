/****************************************************************************************************
Code de service		:		psCONV_ObtenirSoldesPourCalculateurSprintREEE
Nom du service		:		Pour le Calculateur SprintREEE, obtenir les soldes et autres informations des conventions d'un bénéficiaire apparteant à un souscripteur
But					:		
							
Facette				:		CONV
Reférence			:		?

Parametres d'entrée :	Parametres					DescriptiON                                 Obligatoire
                        ----------                  ----------------                            --------------   
                        SubscriberID															Oui
                        BeneficiaryID			    							                Oui
						dtDateTo					Date du calcul						        Oui

Parametres de sortie :  Table						Champs										Description
					    -----------------			---------------------------					--------------------------
                    
Historique des modifications :
			
						Date					Programmeur							Description							Référence
						----------			---------------------------------	----------------------------		---------------
						2016-09-29			Donald Huppé						Création de la procédure
						2016-10-12			Donald Huppé						s'il n'y a pas de correspondance entre le souscripteur et le bénéficiaire, on arrête
						2016-10-19			Donald Huppé						Gestion des divisions par zéro
						2016-10-21			Donald Huppé						Gestion de la première qui n'est pas au souscripteur demandé
						2016-10-31			Donald Huppé						Correction calcul solde PCEE
						2016-11-03			Donald Huppé						le pays doit être CAN, et inscrire AUTRE si hors QC
						2016-11-08			Donald Huppé						Le benef doit avoir entre 12 et 17 ans au 31 décembre de la date demandée
						2016-11-09			Donald Huppé						Ajouter PrenomBenef dans le dataset
						2016-12-05			Donald Huppé						Ajout du montant souscrit
                        2016-12-07          Pierre-Luc Simard                   Retrait des RIO dans le montant souscrit et ajout des frais pour les T
                        2016-12-08          Pierre-Luc Simard                   Validation sur l'âge du bénéficiaire pour les 17 ans et moins
                                                                                Retrait des frais pour les T (Des TRA seront faits pour corriger ces cas)
                                                                                Si la convention a un RIN, un RIO ou un RIM, on prend les cotisations au lieu du montant souscrit 
						2017-04-06			Donald Huppé						Date de dernier dépot. Valider si c'est CPT alors mettre la date de CPT
						2017-04-13			Donald Huppé						Ajout de CotisINDEtForfaitAnneeEnCour et SCEEResil
						2018-09-07			Maxime Martel						JIRA MP-699 Ajout de OpertypeID COU
exec psCONV_ObtenirSoldesPourCalculateurSprintREEE @SubscriberID = 531974, @BeneficiaryID = 531975
exec psCONV_ObtenirSoldesPourCalculateurSprintREEE @SubscriberID = 575993, @BeneficiaryID = 575994, @DateTo = '2016-10-28'
exec psCONV_ObtenirSoldesPourCalculateurSprintREEE @SubscriberID = 575993, @BeneficiaryID = 577955, @DateTo = '2017-04-13'
exec psCONV_ObtenirSoldesPourCalculateurSprintREEE @SubscriberID = 443255, @BeneficiaryID = 291250

exec psCONV_ObtenirSoldesPourCalculateurSprintREEE @SubscriberID = 416582 , @BeneficiaryID = 416583 , @DateTo = '2016-12-20'
/*

ID souscripteur : 723500
ID bénéficiaire : 723545

*/
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_ObtenirSoldesPourCalculateurSprintREEE] (	
	@SubscriberID INT 
	,@BeneficiaryID INT
	,@DateTo DATETIME = NULL
	) -- ID du représentant, 0 pour ne pas appliquer ce critère
AS

BEGIN

	DECLARE	@EndateDu datetime
	DECLARE	@DateFinAnnee datetime
	DECLARE	@DateFinAnneePrec datetime

	SET @EndateDu = CAST( ISNULL(@DateTo, GETDATE()) AS DATE)

	SET @DateFinAnnee = CAST( CAST(YEAR(@EndateDu) as VARCHAR(4)) + '-12-31' AS DATE)
	SET @DateFinAnneePrec = CAST( CAST(YEAR(@EndateDu) - 1 as VARCHAR(4)) + '-12-31' AS DATE)


	-- s'il n'y a pas de correspondance entre le souscripteur et le bénéficiaire, on arrête
	--IF NOT EXISTS (SELECT 1 FROM Un_Convention WHERE SubscriberID = @SubscriberID AND BeneficiaryID = @BeneficiaryID)
	--RETURN

	select 	 
		c.ConventionID
		,IqeeRecueEnMaiAnneeEnCour = CAST(max(o.OperDate) AS DATE)
	INTO #IQEE_DATERECUE
	FROM Un_ConventiON c
	JOIN Un_ConventionOper co ON co.ConventionID = c.ConventionID
	JOIN Un_Oper o ON co.OperID = o.OperID
	where 
		c.BeneficiaryID = @BeneficiaryID
		and o.OperTypeID = 'IQE'
		and YEAR(o.OperDate) = YEAR(@EndateDu) and MONTH(o.OperDate) = 5
		and o.OperDate <= @EndateDu
	GROUP BY c.ConventionID

	-- SOLDE IDEE PAR CONVENTION
	select 
		c.ConventionID
		,c.BeneficiaryID
		,SoldeIQEE31DecPrec = SUM( CASE WHEN o.OperDate <= @DateFinAnneePrec AND co.ConventionOperTypeID = 'CBQ' THEN co.ConventionOperAmount ELSE 0 END)
		,SoldeIQEEPlus31DecPrec = SUM( CASE WHEN o.OperDate <= @DateFinAnneePrec AND co.ConventionOperTypeID = 'MMQ' THEN co.ConventionOperAmount ELSE 0 END)
		,SoldeIQEE = SUM( CASE WHEN co.ConventionOperTypeID = 'CBQ' THEN co.ConventionOperAmount ELSE 0 END)
		,SoldeIQEEPlus = SUM( CASE WHEN co.ConventionOperTypeID = 'MMQ' THEN co.ConventionOperAmount ELSE 0 END)
		,SoldeRevenusSUB = SUM(CASE WHEN co.ConventionOperTypeID in ('IBC','ICQ','III','IIQ','IMQ','INS','IS+','IST','MIM','IQI' /*,'INM','ITR'*/) THEN co.ConventionOperAmount ELSE 0 END)
		,SoldeRevenusIND = SUM(CASE WHEN co.ConventionOperTypeID in ('INM','ITR') THEN co.ConventionOperAmount ELSE 0 END)
	INTO #IQEE_etREND_CONV
	FROM Un_ConventiON c
	JOIN Un_ConventionOper co ON co.ConventionID = c.ConventionID
	JOIN Un_Oper o ON co.OperID = o.OperID
	where 
		c.BeneficiaryID = @BeneficiaryID
		and o.OperDate <= @EndateDu 
		and co.ConventionOperTypeID in ( 'CBQ','MMQ','IBC','ICQ','III','IIQ','IMQ','INS','IS+','IST','INM','MIM','IQI','ITR')
	GROUP by 
		c.BeneficiaryID
		,c.ConventionID


	-- SOLDE SCEE PAR convention
	SELECT 
		c.BeneficiaryID,
		c.ConventionID,
		SoldeSCEECONV = SUM(CE.fCESG),
		SoldeSCEEPlusCONV = SUM(CE.fACESG)
	INTO #SCEE_CONV
	FROM Un_ConventiON c
	JOIN Un_CESP CE ON CE.ConventionID = c.ConventionID
	JOIN Un_Oper OP ON OP.OperID = CE.OperID 
	WHERE 
		c.BeneficiaryID = @BeneficiaryID
		and OP.OperDate <= @EndateDu
	GROUP BY 
		c.BeneficiaryID,
		c.ConventionID
	ORDER BY
		c.ConventionID


	SELECT
		RowNo = ROW_NUMBER() OVER (/*partition by*/ ORDER BY CASE WHEN GroupeSouscripteur = @SubscriberID THEN 0 ELSE 1 END ,UnitIDPeriodique DESC /*important le DESC pour mettre les UnitIDPeriodique <> 0 en premier */)
		,*
	INTO #COTISATION
	FROM (

		SELECT 
			UnitIDPeriodique = CASE WHEN m.PmtQty > 1 AND rr.vcCode_Regroupement <> 'IND' THEN u.UnitID ELSE 0 END,
			GroupeSouscripteur = CASE 
						WHEN m.PmtQty > 1 AND rr.vcCode_Regroupement <> 'IND'	THEN c.SubscriberID
						ELSE 0
					END
						
			,GroupeConvention = CASE 
						WHEN m.PmtQty = 1 AND rr.vcCode_Regroupement <> 'IND'	THEN 'Forfait'
						WHEN m.PmtQty = 1 AND rr.vcCode_Regroupement =  'IND'	THEN 'IND'
						WHEN m.PmtQty > 1 AND rr.vcCode_Regroupement <> 'IND'	THEN 'Périodique - UnitID ' + CAST(U.UnitID AS VARCHAR(10))
					END
			,c.ConventionNo
			,c.BeneficiaryID
			,DateNaissance = CAST(HB.BirthDate AS DATE) 
			,Province = CASE WHEN AB.StateName IN ( 'QC','Québec') THEN 'QC' ELSE 'AUTRE' END
			,c.ConventionID
			,Regime = RR.vcDescription
			,u.UnitID
			,NombreUnite = u.UnitQty
			,OptionsCotisations = CASE
						WHEN m.PmtQty = 1						THEN 'Forfait'
						WHEN m.PmtByYearID = 12					THEN 'Mensuel'
						WHEN m.PmtQty > 1 and m.PmtByYearID = 1 THEN 'Annuel'
						end
			,DatePremierDepot = CAST(u.dtFirstDeposit AS DATE)
			,DateDernierDepot = CAST(
										CASE 
										WHEN UnitStateID = 'CPT' THEN uus.startdate
										ELSE dbo.fn_Un_LastDepositDate(u.InForceDate,c.FirstPmtDate,m.PmtQty,m.PmtByYearID)
										END
								 AS DATE)
			,CotisationPeriodique = ROUND(CAST(u.UnitQty * m.PmtRate * (CASE WHEN M.PmtQty = 1 THEN 0 ELSE 1 END) as money),2)
			,MontantSouscrit = CASE 
								WHEN rr.vcCode_Regroupement = 'IND' THEN SUM(CT.Cotisation) -- Individuel: Cotisations uniquement 
                                WHEN RI.UnitID IS NOT NULL THEN SUM(CT.Cotisation + CT.Fee) -- Collectif avec RIN, RIO ou RIM: Cotisations et frais  
								ELSE CONVERT(money, (ROUND( (U.UnitQty ) * M.PmtRate,2) * M.PmtQty) + U.SubscribeAmountAjustment) -- Collectif sans RIN, RIO et RIM: Montant souscrit
								END
			,SoldeCotisations = SUM(ct.CotisatiON + CASE WHEN rr.vcCode_Regroupement <> 'IND' THEN ct.Fee ELSE 0 END)
			,SoldeCotisation31DecPrec = SUM(CASE WHEN o.OperDate <= @DateFinAnneePrec THEN ct.CotisatiON + ct.Fee ELSE 0 END)	
			,SoldeCotisation31DecPrecPrec = SUM(CASE WHEN o.OperDate <= dateadd(YEAR,-1,@DateFinAnneePrec) THEN ct.CotisatiON + ct.Fee ELSE 0 END)	
			,CotisationEncaisseeAnneePrec = SUM(CASE WHEN YEAR(o.OperDate) = YEAR(@DateFinAnneePrec) THEN ct.CotisatiON + ct.Fee ELSE 0 END)	
			,CotisationEncaisseeAnneeNow = SUM(CASE WHEN YEAR(o.OperDate) = YEAR(@EndateDu) THEN ct.CotisatiON + ct.Fee ELSE 0 END)	

			,CotisINDEtForfaitAnneeEnCour = ISNULL(CotisINDEtForfaitAnneeEnCour,0)

		FROM 
			Un_ConventiON C
			JOIN (
				select 
					Cs.conventionid ,
					ccs.startdate,
					cs.ConventionStateID
				from 
					un_conventionconventionstate cs
					join (
						select 
						conventionid,
						startdate = max(startDate)
						from un_conventionconventionstate
						where startDate < DATEADD(d,1 ,@EndateDu)
						group by conventionid
						) ccs on ccs.conventionid = cs.conventionid 
							and ccs.startdate = cs.startdate 
							and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
				) css ON C.conventionid = css.conventionid
			JOIN Un_Plan P ON C.PlanID = P.PlanID
			JOIN tblCONV_RegroupementsRegimes RR ON P.iID_Regroupement_Regime = RR.iID_Regroupement_Regime
			JOIN Un_Unit U ON C.ConventionID= U.ConventionID

			JOIN (
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
						where startDate < DATEADD(d,1 ,@EndateDu)
						group by unitid
						) uus on uus.unitid = us.unitid 
							and uus.startdate = us.startdate 
							--and us.UnitStateID in ('epg')
				)uus on uus.unitID = u.UnitID

			JOIN Mo_Human HB ON C.BeneficiaryID = HB.HumanID
			JOIN Mo_Adr AB ON HB.AdrID = AB.AdrID
			JOIN Un_Modal m	ON m.ModalID = u.ModalID
			LEFT JOIN Un_Cotisation CT ON U.UnitID = CT.UnitID
			LEFT JOIN Un_Oper O ON CT.OperID = O.OperID AND o.OperDate <= @EndateDu
            LEFT JOIN ( 
                SELECT DISTINCT
                    CT.UnitID
                FROM Un_Cotisation CT
                JOIN Un_Oper O ON O.OperID = CT.OperID
                LEFT JOIN Un_OperCancelation OC ON OC.OperSourceID = O.OperID
                WHERE O.OperTypeID IN ('RIN','RIO', 'RIM')
                    AND OC.OperSourceID IS NULL 
                ) RI ON RI.UnitID = U.UnitID
			LEFT JOIN (
				SELECT 
					U.UnitID
					,CotisINDEtForfaitAnneeEnCour = sum(ct.Cotisation + ct.Fee)
				FROM 
					Un_Convention C
					JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
					JOIN Un_Modal M ON M.ModalID = U.ModalID
					JOIN Un_Plan P ON P.PlanID = C.PlanID
					JOIN tblCONV_RegroupementsRegimes RR ON P.iID_Regroupement_Regime = RR.iID_Regroupement_Regime
					JOIN un_cotisation CT ON CT.UnitID = U.UnitID
					JOIN un_oper O ON CT.OperID = O.OperID
					left JOIN Un_Tio TIOt ON TIOt.iTINOperID = O.operid
					left JOIN Un_Tio TIOo ON TIOo.iOUTOperID = O.operid
				WHERE 
					C.BeneficiaryID = @BeneficiaryID
					AND YEAR(o.OperDate) = YEAR(@EndateDu)
					AND O.OperTypeID IN ( 'CHQ','PRD','NSF','CPA','RDI','COU')
					AND tiot.iTINOperID IS NULL -- TIN qui n'est pas un TIO
					AND (M.PmtQty = 1 OR rr.vcCode_Regroupement =  'IND') -- FORFAITAIRE OU INDIVIDUEL
				GROUP BY 
					U.UnitID
				)CT_Annee ON CT_Annee.UnitID = u.UnitID
		WHERE 1=1
			AND C.BeneficiaryID = @BeneficiaryID
			AND U.TerminatedDate IS NULL
			AND u.UnitQty > 0
			AND ab.CountryID = 'CAN'
            AND dbo.fn_Mo_Age(HB.BirthDate, @DateFinAnnee) <= 17
		GROUP BY
			 C.SubscriberID
			,c.ConventionNo
			,c.BeneficiaryID
			,HB.BirthDate
			,c.ConventionID
			,u.UnitID
			,m.PmtQty
			,m.PmtByYearID
			,u.UnitQty
			,U.SubscribeAmountAjustment
			,m.PmtRate
			,u.InForceDate
			,c.FirstPmtDate
			,CASE WHEN AB.StateName IN ( 'QC','Québec') THEN 'QC' ELSE 'AUTRE' END
			,u.dtFirstDeposit
			,u.UnitQty
			,rr.vcCode_Regroupement
			,RR.vcDescription
            ,RI.UnitID
			,CT_Annee.CotisINDEtForfaitAnneeEnCour
			,UnitStateID
			,uus.startdate
		)V


	-- Si la 1ere ligne n'appartient pas au souscripteur demandé, on décale toutes les lignes de un afin que la 1ere ligne soit vide.
	UPDATE #COTISATION 
	SET RowNo = RowNo + 1 
	WHERE EXISTS (SELECT 1 FROM #COTISATION WHERE rowno = 1 AND GroupeSouscripteur <> @SubscriberID)

		/*
Ligne 1, GU mensuel ou annuel du souscripteur dont on fait la vente
Ligne 2, GU mensuel ou annuel, peu importe qui est le souscripteur
Ligne 3, Forfaitaire(s) Universitas 
Ligne 4, Forfaitaire(s) REEEFLEX 
Ligne 5, Individuel(s)
Lignes 5000 et plus, Le reste

		*/


	select 
		RowNo = CASE 
					WHEN GroupeConvention LIKE 'Périodique%' AND RowNo <= 2			THEN RowNo 
					WHEN GroupeConvention = 'Forfait' AND Regime = 'Universitas'	THEN 3 
					WHEN GroupeConvention = 'Forfait' AND Regime = 'Reeeflex'		THEN 4
					WHEN GroupeConvention =	'IND'									THEN 5
					--WHEN RowNo = 5000												THEN 5000 + RowNo
					ELSE RowNo + 9000 
					END,
		GroupeSouscripteur	,
		Regime,
		Province,
		DateNaissance,
		OptionsCotisations,
		DatePremierDepot = min(DatePremierDepot),
		DateDernierDepot = max(DateDernierDepot),
		CotisationPeriodique = SUM(CotisationPeriodique),
		SoldeScee = SUM(SoldeScee),
		SoldeSceePlus = SUM(SoldeSceePlus),
		SoldeIqee = SUM(SoldeIqee),
		SoldeIqeePlus = SUM(SoldeIqeePlus),
		SoldeCotisations = SUM(SoldeCotisations),
		SoldeRevenusSUB = SUM(SoldeRevenusSUB),
		NombreUnite = SUM(NombreUnite),
		SoldeRevenusIND = SUM(SoldeRevenusIND),
		IQEEaRecevoir = SUM(IQEEaRecevoir),
		MontantSouscrit = SUM(MontantSouscrit),
		CotisINDEtForfaitAnneeEnCour = SUM(CotisINDEtForfaitAnneeEnCour)

	INTO #FINAL

	FROM (
		SELECT 
			RowNo,
			GroupeSouscripteur,
			GroupeConvention,
			CT.Regime,
			ct.province,
			CT.DateNaissance,
			CT.OptionsCotisations,
			CT.DatePremierDepot,
			CT.DateDernierDepot,
			CT.CotisationPeriodique,
			SoldeScee = ROUND( SC.SoldeSceeCONV * (CAST( NombreUnite AS DOUBLE PRECISION) / CAST( NombreUniteCONV AS DOUBLE PRECISION)),2),
			SoldeSceePlus = ROUND( SC.SoldeSceePlusCONV * (CAST( NombreUnite AS DOUBLE PRECISION) / CAST( NombreUniteCONV AS DOUBLE PRECISION)),2),

			-- Le soldeIQEE et SoldeIqeePlus doit être attribué à chaque groupe d'unité selon le ratio de cotisation de chaque groupe d'unité
			-- Mais si les soldes de cotisation sont 0, alors le ratio n'est pas possible.
			--		À la place, on prend le ratio des qté d'unités dans la convention, ce qui n'est pas précis par groupe d'unité mais au total de la convention, la somme des soldes d'iqee sera ok.
			SoldeIqee = 
						ROUND(
							CASE 

								WHEN IqeeDate.IqeeRecueEnMaiAnneeEnCour IS NOT NULL 
										THEN	(

												CASE WHEN SoldeCONVCotisation31DecPrec = 0	THEN (CAST( NombreUnite AS DOUBLE PRECISION) / CAST( NombreUniteCONV AS DOUBLE PRECISION))--NombreUnite / NombreUniteCONV  -- cas d'exception : ratio selon la qté d'unité
													ELSE CAST(SoldeCotisation31DecPrec AS DOUBLE PRECISION) / CAST( SoldeCONVCotisation31DecPrec AS DOUBLE PRECISION) END			-- case standard : ratio selon solde de cotisation
												) 
												* IqeeCONV.SoldeIQEE

								WHEN IqeeDate.IqeeRecueEnMaiAnneeEnCour IS NULL		
										THEN	(
												CASE WHEN SoldeCONVCotisation31DecPrecPrec = 0	THEN (CAST( NombreUnite AS DOUBLE PRECISION) / CAST( NombreUniteCONV AS DOUBLE PRECISION))--NombreUnite / NombreUniteCONV  
													ELSE CAST(SoldeCotisation31DecPrecPrec AS DOUBLE PRECISION) / CAST(SoldeCONVCotisation31DecPrecPrec AS DOUBLE PRECISION) END
												) 
												* IqeeCONV.SoldeIQEE

							END 
						,2),
			SoldeIqeePlus = 
						ROUND(
							CASE 

								WHEN IqeeDate.IqeeRecueEnMaiAnneeEnCour IS NOT NULL 
										THEN	(
												CASE WHEN SoldeCONVCotisation31DecPrec = 0		THEN (CAST( NombreUnite AS DOUBLE PRECISION) / CAST( NombreUniteCONV AS DOUBLE PRECISION))--NombreUnite / NombreUniteCONV  
													ELSE CAST(SoldeCotisation31DecPrec AS DOUBLE PRECISION) / CAST(SoldeCONVCotisation31DecPrec AS DOUBLE PRECISION) END
												) 
												* IqeeCONV.SoldeIqeePlus

								WHEN IqeeDate.IqeeRecueEnMaiAnneeEnCour IS NULL		
										THEN	(
												CASE WHEN SoldeCONVCotisation31DecPrecPrec = 0	THEN (CAST( NombreUnite AS DOUBLE PRECISION) / CAST( NombreUniteCONV AS DOUBLE PRECISION))--NombreUnite / NombreUniteCONV  
													ELSE CAST(SoldeCotisation31DecPrecPrec AS DOUBLE PRECISION) / CAST(SoldeCONVCotisation31DecPrecPrec AS DOUBLE PRECISION) END
												) 
												* IqeeCONV.SoldeIqeePlus

							END
						,2),
			SoldeCotisations,
			SoldeRevenusSUB = ROUND(
								SoldeRevenusSUB * (CAST( NombreUnite AS DOUBLE PRECISION) / CAST( NombreUniteCONV AS DOUBLE PRECISION)) --(NombreUnite / NombreUniteCONV) 
								/*
								CASE 
									WHEN ISNULL(SCEECONV.SoldeSCEECONV,0) <> 0 THEN (SU.SoldeScee / SoldeSCEECONV) * SoldeRevenusSUB
									ELSE (NombreUnite / NombreUniteCONV) * SoldeRevenusSUB
								END
								*/
								,2),
								
			NombreUnite,
			IQEEaRecevoir = CAST (
								CASE 
									-- APRES réceptiON IQEE dans année en cours
								WHEN IqeeDate.IqeeRecueEnMaiAnneeEnCour IS NOT NULL AND CotisationEncaisseeAnneeNow > 0		THEN	CotisationEncaisseeAnneeNow * 0.10 
									-- AVANT réceptiON IQEE dans année en cours
								WHEN IqeeDate.IqeeRecueEnMaiAnneeEnCour IS NULL		AND (CotisationEncaisseeAnneePrec + CotisationEncaisseeAnneeNow) > 0 THEN	(CotisationEncaisseeAnneePrec + CotisationEncaisseeAnneeNow) * 0.10
								END as MONEY
							),
			SoldeRevenusIND =		ROUND(
								SoldeRevenusIND * (CAST( NombreUnite AS DOUBLE PRECISION) / CAST( NombreUniteCONV AS DOUBLE PRECISION)) 
								,2)
			,CT.MontantSouscrit 
			,CT.CotisINDEtForfaitAnneeEnCour

		FROM 
			#COTISATION CT
			LEFT JOIN #IQEE_DATERECUE IqeeDate ON IqeeDate.ConventionID = CT.ConventionID
			LEFT JOIN #SCEE_CONV SC	ON SC.ConventionID = CT.ConventionID
			LEFT JOIN (
				SELECT
					ConventionID
					,SoldeCONVCotisation31DecPrec = SUM(SoldeCotisation31DecPrec)	
					,SoldeCONVCotisation31DecPrecPrec = SUM(SoldeCotisation31DecPrecPrec)
					,NombreUniteCONV = SUM(NombreUnite)
				FROM #COTISATION
				GROUP BY ConventionID
				) SoldeCotConv ON CT.ConventionID = SoldeCotConv.ConventionID

			LEFT JOIN #IQEE_etREND_CONV IqeeCONV ON IqeeCONV.ConventionID = CT.ConventionID
		)V
	GROUP BY		CASE
					WHEN GroupeConvention LIKE 'Périodique%' AND RowNo <= 2 THEN RowNo 
					WHEN GroupeConvention = 'Forfait' AND Regime = 'Universitas' THEN 3 
					WHEN GroupeConvention = 'Forfait' AND Regime = 'Reeeflex' THEN 4
					WHEN GroupeConvention ='IND' THEN 5
					ELSE RowNo + 9000
					END,
		GroupeSouscripteur	,
		GroupeConvention,
		Regime,
		province,
		DateNaissance,
		OptionsCotisations



	SELECT 
		RowNo,
		GroupeSouscripteur = MAX(GroupeSouscripteur),
		Regime = MAX(Regime),
		Province = MAX(Province),
		DateNaissance = MAX(DateNaissance),
		PrenomBenef = HB.FirstName,
		OptionsCotisations = MAX(OptionsCotisations),
		DatePremierDepot = MAX(DatePremierDepot),
		DateDernierDepot = MAX(DateDernierDepot),
		CotisationPeriodique = MAX(CotisationPeriodique),
		SoldeScee = CAST(MAX(ISNULL(SoldeScee,0)) AS MONEY),
		SoldeSceePlus = CAST(MAX(ISNULL(SoldeSceePlus,0)) AS MONEY),
		SoldeIqee = CAST(MAX(ISNULL(SoldeIqee,0)) AS MONEY),
		SoldeIqeePlus = CAST(MAX(ISNULL(SoldeIqeePlus,0)) AS MONEY),
		SoldeCotisations = CAST(MAX(ISNULL(SoldeCotisations,0)) AS MONEY),
		SoldeRevenusSUB = CAST(MAX(ISNULL(SoldeRevenusSUB,0)) AS MONEY),
		NombreUnite = MAX(ISNULL(NombreUnite,0)),
		SoldeRevenusIND = CAST(MAX(ISNULL(SoldeRevenusIND,0)) AS MONEY),
		IQEEaRecevoir = CAST(MAX(ISNULL(IQEEaRecevoir,0)) AS MONEY)	,
		MontantSouscrit = CAST(MAX(ISNULL(MontantSouscrit,0)) AS MONEY),		
		CotisINDEtForfaitAnneeEnCour = CAST(MAX(ISNULL(CotisINDEtForfaitAnneeEnCour,0)) AS MONEY),
		SCEEResil = CAST(ISNULL(SCEEResil,0) AS MONEY)
	FROM (

		SELECT  
			RowNo,
			GroupeSouscripteur,
			Regime,
			Province,
			DateNaissance,
			OptionsCotisations,
			DatePremierDepot,
			DateDernierDepot,
			CotisationPeriodique,
			SoldeScee,
			SoldeSceePlus,
			SoldeIqee,
			SoldeIqeePlus,
			SoldeCotisations,
			SoldeRevenusSUB,
			NombreUnite,
			SoldeRevenusIND,
			IQEEaRecevoir,
			MontantSouscrit,
			CotisINDEtForfaitAnneeEnCour

		FROM #FINAL
		UNION ALL
		SELECT 
			RowNo  = 1,
			GroupeSouscripteur = NULL,
			Regime = NULL,
			Province = NULL,
			DateNaissance = NULL,
			OptionsCotisations = NULL,
			DatePremierDepot = NULL,
			DateDernierDepot = NULL,
			CotisationPeriodique = NULL,
			SoldeScee = NULL,
			SoldeSceePlus = NULL,
			SoldeIqee = NULL,
			SoldeIqeePlus = NULL,
			SoldeCotisations = NULL,
			SoldeRevenusSUB = NULL,
			NombreUnite = NULL,
			SoldeRevenusIND = NULL,
			IQEEaRecevoir = 0,
			MontantSouscrit = 0,
			CotisINDEtForfaitAnneeEnCour = 0

		UNION ALL
		SELECT 
			RowNo  = 2,
			GroupeSouscripteur = NULL,
			Regime = NULL,
			Province = NULL,
			DateNaissance = NULL,
			OptionsCotisations = NULL,
			DatePremierDepot = NULL,
			DateDernierDepot = NULL,
			CotisationPeriodique = NULL,
			SoldeScee = NULL,
			SoldeSceePlus = NULL,
			SoldeIqee = NULL,
			SoldeIqeePlus = NULL,
			SoldeCotisations = NULL,
			SoldeRevenusSUB = NULL,
			NombreUnite = NULL,
			SoldeRevenusIND = NULL,
			IQEEaRecevoir = 0,
			MontantSouscrit = 0,
			CotisINDEtForfaitAnneeEnCour = 0

		UNION ALL
		SELECT 
			RowNo  = 3,
			GroupeSouscripteur = NULL,
			Regime = NULL,
			Province = NULL,
			DateNaissance = NULL,
			OptionsCotisations = NULL,
			DatePremierDepot = NULL,
			DateDernierDepot = NULL,
			CotisationPeriodique = NULL,
			SoldeScee = NULL,
			SoldeSceePlus = NULL,
			SoldeIqee = NULL,
			SoldeIqeePlus = NULL,
			SoldeCotisations = NULL,
			SoldeRevenusSUB = NULL,
			NombreUnite = NULL,
			SoldeRevenusIND = NULL,
			IQEEaRecevoir = 0	,
			MontantSouscrit = 0,
			CotisINDEtForfaitAnneeEnCour = 0

		UNION ALL
		SELECT 
			RowNo  = 4,
			GroupeSouscripteur = NULL,
			Regime = NULL,
			Province = NULL,
			DateNaissance = NULL,
			OptionsCotisations = NULL,
			DatePremierDepot = NULL,
			DateDernierDepot = NULL,
			CotisationPeriodique = NULL,
			SoldeScee = NULL,
			SoldeSceePlus = NULL,
			SoldeIqee = NULL,
			SoldeIqeePlus = NULL,
			SoldeCotisations = NULL,
			SoldeRevenusSUB = NULL,
			NombreUnite = NULL,
			SoldeRevenusIND = NULL,
			IQEEaRecevoir = 0,
			MontantSouscrit = 0	,
			CotisINDEtForfaitAnneeEnCour = 0

		UNION ALL
		SELECT 
			RowNo  = 5, -- ind
			GroupeSouscripteur = NULL,
			Regime = NULL,
			Province = NULL,
			DateNaissance = NULL,
			OptionsCotisations = NULL,
			DatePremierDepot = NULL,
			DateDernierDepot = NULL,
			CotisationPeriodique = NULL,
			SoldeScee = NULL,
			SoldeSceePlus = NULL,
			SoldeIqee = NULL,
			SoldeIqeePlus = NULL,
			SoldeCotisations = NULL,
			SoldeRevenusSUB = NULL,
			NombreUnite = NULL,
			SoldeRevenusIND = NULL,
			IQEEaRecevoir = 0,
			MontantSouscrit = 0,
			CotisINDEtForfaitAnneeEnCour = 0

	)V
	JOIN Mo_Human HB on hb.HumanID = @BeneficiaryID
	LEFT JOIN (
		SELECT 
			BeneficiaryID
			,SCEEResil = SUM(SCEEResil)
		FROM (
			SELECT
				-- REMBOURSEMENT SUITE À UNE RESIL
				C.BeneficiaryID
				,SCEEResil = SUM(CE.fCESG + CE.fACESG)
			FROM Un_Unit U
			JOIN Un_Convention C ON U.ConventionID = C.ConventionID
			JOIN Un_Cotisation CT ON CT.UnitID = U.UnitID
			JOIN Un_Oper O ON O.OperID = Ct.OperID
			LEFT JOIN Un_CESP CE on CE.CotisationID = CT.CotisationID
			WHERE 
				C.BeneficiaryID = @BeneficiaryID
				AND O.OperTypeID = 'RES'
			GROUP BY C.BeneficiaryID

			UNION ALL

			SELECT 
				-- REMBOURSEMENT SUITE À UN CHANGEMENT DE BENEFICIAIRE
				C.BeneficiaryID
				,SCEEResil = SUM(CE.fCESG + CE.fACESG)
			FROM 
				Un_Convention C
				JOIN Un_Unit u ON C.ConventionID = U.ConventionID
				JOIN Un_Cotisation CT ON U.UnitID = CT.UnitID
				JOIN Un_Oper O ON CT.OperID = O.OperID
				JOIN Un_CESP ce ON ct.CotisationID = ce.CotisationID
			WHERE 
				C.BeneficiaryID = @BeneficiaryID
				AND O.OperTypeID = 'BNA'
			GROUP BY C.BeneficiaryID
			)R1
		GROUP BY BeneficiaryID
		)SR ON SR.BeneficiaryID = @BeneficiaryID
	--Il doit y avoir une correspondance entre le souscripteur et le bénéficiaire
	WHERE 
		EXISTS (SELECT 1 FROM Un_Convention WHERE SubscriberID = @SubscriberID AND BeneficiaryID = @BeneficiaryID)
	GROUP BY RowNo,HB.FirstName,SCEEResil
	ORDER BY RowNo


END