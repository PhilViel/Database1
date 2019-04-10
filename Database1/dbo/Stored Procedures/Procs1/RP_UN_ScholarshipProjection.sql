
/********************************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	RP_UN_ScholarshipProjection
Description         :	Procédure de génération de projection de bourse
Valeurs de retours  :	Dataset :
							UnitID 				INTEGER			ID du groupe d’unités.
							PlanDesc			VARCHAR(75)		Description du plan.
							ConventionNo		VARCHAR(75)		Numéro de convention
							InForceDate			DATETIME		Date d’entrée en vigueur du groupe d’unités
							BirthDate			DATETIME		Date de naissance du bénéficiaire
							UnitQty				MONEY			Nombre d’unités
							CotisationFee		MONEY			Montant d’épargne et frais par dépôt
							PmtByYearID			INTEGER			Nombre de dépôt par année
							SubscInsurRate		MONEY			Prime d’assurance par dépôt
							fTotCotisation		MONEY			Total des épargnes
							fTotFee				MONEY			Total des frais
							dtEstimateRI		DATETIME		Date estimée de remboursement intégral
							fCESG				MONEY			SCEE
							bCESGRequested		BIT				SCEE voulue « OUI » ou « NON »
							dtLastDeposit		DATETIME		Date prévue du dernier dépôt
							YearQualif			INTEGER			Année de qualification
							fACESG				MONEY			SCEE+
							bACESGRequested		BIT				SCEE+ voulue « OUI » ou « NON »
							fCLB				MONEY			BEC
							bCLBRequested		BIT				BEC voulue « OUI » ou « NON »
							StateName			VARCHAR(75)		Province
							IQEE				MONEY			IQEE (Crédit de base)
							IQEEMaj				MONEY			IQEE (Majoration)
							bSouscripteur_Desire_IQEE	BIT		IQEE voulu « OUI » ou « NON »

Note :			
					ADX0000810	IA	2006-11-13	Bruno Lapointe		Création.
					ADX0002426	BR	2007-05-23	Bruno Lapointe		Gestion de la table Un_CESP.
					ADX0001355	IA	2007-06-06	Alain Quirion		Utilisation de dtRegEndDateAdjust en remplacement de RegEndDateAddyear
									2008-07-18	Pierre-Luc Simard	Ajout de la province et suppression de la taxe de 9% si province = Québec
									2008-11-24	Josée Parent		Modification pour utiliser la fonction "fnCONV_ObtenirDateFinRegime"
									2009-07-07	Pierre-Luc Simard	Ajout de l'IQEE
									2009-07-15	Pierre-Luc Simard	Remettre le bon montant d'assurance, sans taxe
									2010-07-19	Pierre-Luc Simard	Utilisation de la table Un_ConventionOper pour l'IQEE
									2015-01-05	Donald Huppé		Demande de Anne Mainguy : enlever les toutes les exclusions qui font débalancer le total des cotisations avec le rapprot des cotisation
									2016-06-01	Donald Huppé		Modification pour qu'il balance avec le rapport des cotisation par plan
									2017-08-04	Donald Huppé		Ajout de PmtQty
									2018-08-21	Donald Huppé		jira prod-11573 ajout des rendements, ratio par unité et ratio PAE demandé, et refaire quelque sections pour plus de vitesse
									2018-09-11	Donald Huppé		jira prod-11573 ajout de MontantSouscrit

exec RP_UN_ScholarshipProjection '2018-09-11'

drop proc RP_UN_ScholarshipProjection_new

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_ScholarshipProjection] (	
	@dtProjection DATETIME ) -- Date de la projection.
AS
BEGIN

	--DECLARE @dtProjection DATETIME = '2018-07-31'
	--select t = '0-', GETDATE()
	SELECT @dtProjection = dbo.FN_CRQ_DateNoTime(@dtProjection)
	
	CREATE TABLE #tUnitProjection  (
		UnitID INTEGER PRIMARY KEY,
		dtEstimateRI DATETIME,
		MontantSouscrit MONEY )

	-- Filtre le plus possible les unités recherchés pour la projection.
	INSERT INTO #tUnitProjection  
		SELECT
			U.UnitID,
			dtEstimateRI = dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, U.IntReimbDateAdjust)
			,MontantSouscrit = 			CONVERT(MONEY,CASE
													WHEN P.PlanTypeID = 'IND' THEN ISNULL(V1.Cotisation,0)
													ELSE (ROUND( (U.UnitQty +isnull(qtyreduct,0)) * M.PmtRate,2) * M.PmtQty) + U.SubscribeAmountAjustment
												END)
		FROM dbo.Un_Unit U
		--JOIN ( -- Va chercher la date d'entrée en vigueur de la convention
		--	SELECT 
		--		ConventionID, 
		--		InForceDate = MIN(InForceDate)
		--	FROM dbo.Un_Unit 
		--	GROUP BY
		--		ConventionID
		--	) U2 ON U2.ConventionID = U.ConventionID
		JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
		JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(@dtProjection, NULL) CSS ON CSS.ConventionID = c.ConventionID AND CSS.ConventionStateID IN ('REE','TRA')
		JOIN Un_Plan P ON P.PlanID = C.PlanID
		JOIN Un_Modal M ON M.ModalID = U.ModalID
		LEFT JOIN (SELECT qtyreduct = sum(unitqty), unitid FROM Un_UnitReduction WHERE ReductionDate > @dtProjection GROUP BY UnitID) R ON R.UnitID = U.UnitID
		LEFT JOIN (
			SELECT 
				U.UnitID,Cotisation = SUM(Ct.Cotisation),CotisationFee = SUM(Ct.Cotisation + Ct.Fee)
			FROM 
				dbo.Un_Unit U
				JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
				JOIN Un_Oper O ON O.OperID = Ct.OperID
			WHERE O.OperDate <= @dtProjection
			GROUP BY 
				U.UnitID
				) V1 ON V1.UnitID = U.UnitID
		--WHERE U.TerminatedDate IS NULL -- Exclu les groupes d'unités entièrement résiliés
			-- 2015-01-05
			--AND U.InForceDate <= @dtProjection -- Exclu les groupes d'unités dont la date de vigueur est supérieur à la date de projection
			--AND YEAR(@dtProjection) <= (SELECT YEAR([dbo].[fnCONV_ObtenirDateFinRegime](C.ConventionID,'R',NULL))) -- Exclu les groupes d'unités dont le 25 + ajustement du régime est terminé
			--AND P.PlanTypeID <> 'IND' -- Exclu les conventions individuelles
			-- Fin 2015-01-05

	CREATE INDEX #IND1 ON #tUnitProjection(UnitID)

	--select t = '1-', GETDATE()
	--select COUNT(*) from #tUnitProjection --RETURN

	CREATE TABLE #tUnitModal  (
		UnitID INTEGER PRIMARY KEY,
		ModalID INTEGER NOT NULL )

	-- Va chercher la modalité de dépôt active pour chaque groupe d'unités à la date saisie.
	INSERT INTO #tUnitModal
		SELECT DISTINCT -- Prend le UnitID et le ModalID du plus récent historique avant la date saisie pour la projection.
			UM2.UnitID,
			UM2.ModalID
		FROM (
			SELECT -- S'il y a plus d'un historique avec la même date pour un même groupe d'unités, il va chercher celui avec le plus grand ID.
				U.UnitID,
				UnitModalHistoryID = MAX(UM.UnitModalHistoryID)
			FROM ( -- Historique le plus récent pour chaque groupe d'unité
				SELECT
					U.UnitID,
					StartDate = MAX(UM1.StartDate)
				FROM #tUnitProjection U
				JOIN Un_UnitModalHistory UM1 ON UM1.UnitID = U.UnitID
				WHERE /*dbo.FN_CRQ_DateNoTime*/(UM1.StartDate) <= /*'2018-07-31'*/@dtProjection
				GROUP BY U.UnitID
				) U
			JOIN Un_UnitModalHistory UM ON UM.UnitID = U.UnitID AND UM.StartDate = U.StartDate
			GROUP BY U.UnitID
			) V
		JOIN Un_UnitModalHistory UM2 ON UM2.UnitModalHistoryID = V.UnitModalHistoryID

	--SELECT count(*) from #tUnitModal --RETURN

	-- Va chercher les unités résiliés après la date de projection. Il faut additionner ces unités à ceux actuel des
	-- groupes d'unités pour connaître le nombre d'unités à la date de projection
	CREATE TABLE #tUnitReduction  (
		UnitID INTEGER PRIMARY KEY,
		UnitQty MONEY NOT NULL )

	INSERT INTO #tUnitReduction
 		SELECT
			UP.UnitID,
			SUM(UR.UnitQty)
		FROM Un_UnitReduction UR
		JOIN #tUnitProjection UP ON UR.UnitID = UP.UnitID
		WHERE UR.ReductionDate > @dtProjection -- Résiliation d'unités faites après la date de projection.
		GROUP BY UP.UnitID

	-- Va chercher l'année de qualification qu'avait la convention selon l'historique des années de qualification de la
	-- convention.
	CREATE TABLE #tConventionYearQualif (
		ConventionID INTEGER PRIMARY KEY,
		YearQualif INTEGER NOT NULL )

	INSERT INTO #tConventionYearQualif
 		SELECT
			Y.ConventionID,
			Y.YearQualif
		FROM ( -- Filtre sur les conventions qui ont au moins une convention qui fait partie de la projection
			SELECT U.ConventionID
			FROM #tUnitProjection UP
			JOIN dbo.Un_Unit U ON U.UnitID = UP.UnitID
			GROUP BY U.ConventionID
			) C
		JOIN Un_ConventionYearQualif Y ON Y.ConventionID = C.ConventionID
		WHERE @dtProjection BETWEEN Y.EffectDate AND ISNULL(Y.TerminatedDate,@dtProjection) -- Historique actif à la date de projection

	-- Va chercher les soldes des épargnes et des frais de tous les groupes d'unités de la projection.
	CREATE TABLE #tUnitCotisationFee (
		UnitID INTEGER PRIMARY KEY,
		Cotisation MONEY NOT NULL,
		Fee MONEY NOT NULL )

	INSERT INTO #tUnitCotisationFee
 		SELECT
			Ct.UnitID,
			SUM(Ct.Cotisation),
			SUM(Ct.Fee)
		FROM Un_Cotisation Ct
		JOIN #tUnitProjection UP ON UP.UnitID = Ct.UnitID
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		JOIN Un_OperType  OT ON OT.OperTypeID = O.OperTypeID
		WHERE O.OperDate <= @dtProjection -- Opération faite avant ou le jour de la projection

		AND		(
					( OT.TotalZero = 0 -- Exclu les opérations de type BEC ou TFR
					OR O.OperTypeID = 'TRA' -- Inclus les TRA
					)
				OR
					(O.OperTypeID = 'TFR')
				)

		GROUP BY Ct.UnitID

		CREATE INDEX #IND2 ON #tUnitCotisationFee(UnitID)

		--SELECT COUNT(*) FROM #tUnitCotisationFee --RETURN
		--select t = '2-', GETDATE()

	CREATE TABLE #tRatioCotisation (
		UnitID INTEGER PRIMARY KEY,
		RatioCotisation FLOAT NOT NULL)

	INSERT INTO #tRatioCotisation

		SELECT 
			t1.UnitID
			--,c.ConventionNo
			,RatioCotisation =	CAST (
									CASE 
									WHEN CotisationfeeCONV > 0 THEN 1.0 * (ISNULL(T2.Cotisation,0) + ISNULL(T2.Fee,0)) / CotisationfeeCONV
									ELSE 1.0 / NbGrUnite
									END
								AS FLOAT)
			--,Cotisation = ISNULL(T2.Cotisation,0) + ISNULL(T2.Fee,0) 
			--,CotisationfeeCONV
		FROM #tUnitProjection t1
		JOIN Un_Unit u1	on u1.UnitID = t1.UnitID
		JOIN (
			SELECT U.ConventionID, CotisationfeeCONV = SUM( ISNULL(t.Cotisation,0) + ISNULL(t.Fee,0)), NbGrUnite = COUNT(DISTINCT P.UnitID)
			FROM #tUnitProjection P
			JOIN Un_Unit U ON U.UnitID = P.UnitID
			LEFT JOIN #tUnitCotisationFee T on T.UnitID = P.UnitID
			GROUP BY U.ConventionID
			)V on V.ConventionID = u1.ConventionID
		JOIN Un_Convention c on c.ConventionID = v.ConventionID
		LEFT JOIN #tUnitCotisationFee T2 on T2.UnitID = t1.UnitID
		--order by c.ConventionNo, t1.UnitID
	--RETURN

	--SELECT COUNT(*) FROM #tRatioCotisation
	--select t = '22-', GETDATE()

	-- Va chercher les soldes de SCEE, SCEE+ et BEC des conventions à la date de la projection.
	CREATE TABLE #tConventionCESP (
		ConventionID INTEGER PRIMARY KEY,
		fCESG MONEY NOT NULL,
		fACESG MONEY NOT NULL,
		fCLB MONEY NOT NULL )

	INSERT INTO #tConventionCESP
 		SELECT
			CE.ConventionID,
			SUM(CE.fCESG),
			SUM(CE.fACESG),
			SUM(CE.fCLB)
		FROM Un_CESP CE
		JOIN Un_Oper O ON O.OperID = CE.OperID
		WHERE O.OperDate <= @dtProjection -- Opération faite avant ou le jour de la projection
		GROUP BY CE.ConventionID


		--select t = '3-', GETDATE()

	-- Va chercher les soldes de IQEE et IQEE majoré des conventions à la date de la projection
	--CREATE TABLE #tConventionIQEE (
	--	ConventionID INTEGER PRIMARY KEY,
	--	fIQEE MONEY NOT NULL,
	--	fIQEEMaj MONEY NOT NULL)

	--INSERT INTO #tConventionIQEE
	--	SELECT 
	--		CO.ConventionID,
	--		mMntIQEECB = SUM(mMntIQEECB),
	--		mMntIQEEMaj = SUM(mMntIQEEMaj)
	--	FROM (
	--		SELECT
	--			CO.ConventionID, 
	--			mMntIQEECB	= (CASE WHEN EXISTS(SELECT 1 FROM fntOPER_ObtenirOperationsCategorie('OPER_MONTANTS_CREDITBASE') f WHERE f.cID_Type_Oper_Convention = co.ConventionOperTypeID) THEN co.ConventionOperAmount ELSE 0 END),
	--			mMntIQEEMaj	= (CASE WHEN EXISTS(SELECT 1 FROM fntOPER_ObtenirOperationsCategorie('OPER_MONTANTS_MAJORATION') f WHERE f.cID_Type_Oper_Convention = co.ConventionOperTypeID) THEN co.ConventionOperAmount ELSE 0 END)
	--		FROM Un_ConventionOPER CO
	--		JOIN (
	--			SELECT DISTINCT U.ConventionID
	--			FROM #tUnitProjection p
	--			JOIN Un_Unit U on U.UnitID = P.UnitID
	--			)vv on vv.ConventionID = CO.ConventionID
	--		JOIN Un_OPER O ON CO.OperID = O.OperID
	--		WHERE O.OperDate <= @dtProjection
	--		) CO
	--	GROUP BY CO.ConventionID


	--	SELECT COUNT(*) from #tConventionIQEE --RETURN
	--	select t = '4-', GETDATE()

	CREATE TABLE #tRendement (
		ConventionID INTEGER PRIMARY KEY,
		fIQEE MONEY NOT NULL,
		fIQEEMaj MONEY NOT NULL,
		Rend_Cotisation MONEY NOT NULL,
		Rend_SCEE MONEY NOT NULL,
		Rend_SCEEmajoree MONEY NOT NULL,
		Rend_BEC MONEY NOT NULL,
		Rend_IQEE MONEY NOT NULL,
		Rend_IQEEmajoree MONEY NOT NULL
		)

	INSERT INTO #tRendement

		SELECT
			cO.conventionid,
			fIQEE = sum(case when CO.conventionopertypeid  IN ( 'CBQ') then ConventionOperAmount else 0 end ),
			fIQEEMaj = sum(case when CO.conventionopertypeid  IN ( 'MMQ') then ConventionOperAmount else 0 end ),

			Rend_Cotisation = sum(case when CO.conventionopertypeid  IN ( 'INM','ITR') then ConventionOperAmount else 0 end ),
			Rend_SCEE = sum(case when CO.conventionopertypeid  IN ( 'INS','IST') then ConventionOperAmount else 0 end ),
			Rend_SCEEmajoree = sum(case when CO.conventionopertypeid  IN ( 'IS+') then ConventionOperAmount else 0 end ),
			Rend_BEC = sum(case when CO.conventionopertypeid  IN ( 'IBC') then ConventionOperAmount else 0 end ),

			Rend_IQEE = sum(case when CO.conventionopertypeid  IN ( 'ICQ','MIM','IQI','IIQ','III') then ConventionOperAmount else 0 end ),
			Rend_IQEEmajoree = sum(case when CO.conventionopertypeid  IN ( 'IMQ') then ConventionOperAmount else 0 end )
		FROM 
			un_oper o
			join un_conventionoper co on co.operid = o.operid
			--join un_conventionopertype ot on co.conventionopertypeid = ot.conventionopertypeid
			--join un_convention c on co.conventionid = c.conventionid
			JOIN (
				SELECT DISTINCT U.ConventionID
				FROM #tUnitProjection p
				JOIN Un_Unit U on U.UnitID = P.UnitID
				)vv on vv.ConventionID = co.ConventionID
		WHERE 
			1=1

			and o.operdate <= @dtProjection
			--and ot.conventionopertypeid in( 'IBC','ICQ','III','IIQ','IMQ','INS','IS+','IST','INM','MIM','IQI','ITR')
			AND CharIndex(CO.ConventionOperTypeID, 'IBC,ICQ,III,IIQ,IMQ,INS,IS+,IST,INM,MIM,IQI,ITR,CBQ,MMQ', 1) > 0

		GROUP by cO.conventionid

		--select t = '5-', GETDATE()
		--select	COUNT(*) from #tRendement --RETURN


	CREATE TABLE #tRatioPAE (
		ConventionID INTEGER PRIMARY KEY,
		mQuantite_UniteDemande FLOAT NOT NULL,
		RatioDemandePAE FLOAT NOT NULL)

	INSERT INTO #tRatioPAE
		SELECT 
			S.ConventionID, 
			mQuantite_UniteDemande =	CASE WHEN TU.TotalUniteConv <= SUM(ISNULL(S.mQuantite_UniteDemande, 0)) 
												THEN TU.TotalUniteConv -- SI ON A DONNE PLUS D'UNTIÉ EN PAE QUE LE NB TOTAL DANS LA CONV ALORS C'EST PAS LOGIQUE MAIS ON RETOURNE TotalUniteConv
										ELSE SUM(ISNULL(S.mQuantite_UniteDemande, 0)) 
										END
			-- ratio d'unité demandé en PAE en date du
			,RatioDemandePAE =		CASE WHEN TU.TotalUniteConv > 0 THEN
								(
										CASE WHEN TU.TotalUniteConv <= SUM(ISNULL(S.mQuantite_UniteDemande, 0)) 
												THEN TU.TotalUniteConv -- SI ON A DONNE PLUS D'UNTIÉ EN PAE QUE LE NB TOTAL DANS LA CONV ALORS C'EST PAS LOGIQUE MAIS ON RETOURNE TotalUniteConv
										ELSE SUM(ISNULL(S.mQuantite_UniteDemande, 0)) 
										END
								) / TU.TotalUniteConv * 1.0
								ELSE 0 END
		FROM 
			Un_Scholarship S
			JOIN (
				SELECT DISTINCT U.ConventionID
				FROM #tUnitProjection p
				JOIN Un_Unit U on U.UnitID = P.UnitID
				)vv on vv.ConventionID = S.ConventionID
			JOIN (
				SELECT U2.ConventionID, TotalUniteConv = sum(UnitQty)
				from Un_Unit u2
				group by U2.ConventionID
				)TU	 on TU.ConventionID = S.ConventionID
			JOIN (
				SELECT S1.ScholarshipID, MAXOperDate = MAX(O1.OperDate)
				FROM Un_Scholarship S1
				JOIN Un_ScholarshipPmt SP1 ON SP1.ScholarshipID = S1.ScholarshipID
				JOIN UN_OPER O1 ON O1.OperID = SP1.OperID
				LEFT JOIN Un_OperCancelation OC11 ON OC11.OperSourceID = O1.OperID
				LEFT JOIN Un_OperCancelation OC21 ON OC21.OperID = O1.OperID
				WHERE 1=1
					AND O1.OperDate <= @dtProjection
					AND OC11.OperSourceID IS NULL
					AND OC21.OperID IS NULL
				GROUP BY S1.ScholarshipID
				)MO ON MO.ScholarshipID = S.ScholarshipID
		WHERE 1=1
			AND S.ScholarshipStatusID IN ('24Y','25Y','DEA','PAD','REN')
			--AND MAXOperDate <= @dtDateTo -- comme la valeur de quotee part est en date du jour, alors on prend tous les PAE en date du jour, et non en date de fin
		GROUP BY S.ConventionID,TU.TotalUniteConv

	--SELECT COUNT(*) from #tRatioPAE

	--select t = '6-', GETDATE()

	--RETURN


	SELECT
		U.UnitID, -- ID du groupe d’unités.
		P.PlanDesc, -- Description du plan.
		C.ConventionNo, -- Numéro de convention
		U.InForceDate, -- Date d’entrée en vigueur du groupe d’unités
		HB.BirthDate, -- Date de naissance du bénéficiaire
		UnitQty = U.UnitQty + ISNULL(UR.UnitQty,0), -- Nombre d’unités
		CotisationFee = ROUND(M.PmtRate*(U.UnitQty + ISNULL(UR.UnitQty,0)),2), -- Montant d’épargne et frais par dépôt
		M.PmtByYearID, -- Nombre de dépôt par année
		M.PmtQty,
		/*SubscInsurRate = 
			CASE 
				WHEN U.WantSubscriberInsurance = 0 THEN 0
			ELSE ROUND(M.SubscriberInsuranceRate*(U.UnitQty + ISNULL(UR.UnitQty,0)),2)
			END, -- Prime d’assurance par dépôt*/
		SubscInsurRate = 
			CASE 
				WHEN U.WantSubscriberInsurance = 0 THEN 0
			ELSE 
				--CASE 
					--WHEN A.StateName IN ('Québec', 'Québeca', 'Québeco', 'QC') THEN ROUND((M.SubscriberInsuranceRate*(U.UnitQty + ISNULL(UR.UnitQty,0))) * 0.91,2) 
				--ELSE 
					ROUND(M.SubscriberInsuranceRate*(U.UnitQty + ISNULL(UR.UnitQty,0)),2) 
				--END
			END, -- Prime d’assurance par dépôt
		fTotCotisation = ISNULL(UCF.Cotisation,0), -- Total des épargnes
		fTotFee = ISNULL(UCF.Fee,0), -- Total des frais
		UP.dtEstimateRI, -- Date estimée de remboursement intégral
		fCESG = ISNULL(CESP.fCESG,0) * RC.RatioCotisation, -- SCEE
		C.bCESGRequested, -- SCEE voulue « OUI » ou « NON »
		dtLastDeposit = DATEADD(DAY,DAY(C.FirstPmtDate)-DAY(U.InForceDate),DATEADD(MONTH,(12/M.PmtByYearID)*(M.PmtQTY-1),U.InForceDate)), -- Date prévue du dernier dépôt
		YearQualif = ISNULL(Y.YearQualif,C.YearQualif), -- Année de qualification
		fACESG = ISNULL(CESP.fACESG,0) * RC.RatioCotisation, -- SCEE+
		C.bACESGRequested, -- SCEE+ voulue « OUI » ou « NON »
		fCLB = ISNULL(CESP.fCLB,0) * RC.RatioCotisation, -- BEC
		C.bCLBRequested, -- BEC voulue « OUI » ou « NON »
		StateName = CASE WHEN A.StateName IN ('Québeca', 'Québeco', 'QC') THEN 'Québec' ELSE ISNULL(A.StateName,'') END,
		fIQEE = ISNULL(R.fIQEE,0) * RC.RatioCotisation, -- IQEE (Crédit de base)
		fIQEEMaj = ISNULL(R.fIQEEMaj,0) * RC.RatioCotisation, -- IQEE (Majoration)
		C.bSouscripteur_Desire_IQEE, -- IQEE voulue « OUI » ou « NON »

		Rend_Cotisation = ISNULL(R.Rend_Cotisation ,0) * RC.RatioCotisation,
		Rend_SCEE = ISNULL(R.Rend_SCEE ,0) * RC.RatioCotisation,
		Rend_SCEEmajoree = ISNULL(R.Rend_SCEEmajoree ,0) * RC.RatioCotisation,
		Rend_BEC = ISNULL(R.Rend_BEC ,0) * RC.RatioCotisation,
		Rend_IQEE = ISNULL(R.Rend_IQEE ,0) * RC.RatioCotisation,
		Rend_IQEEmajoree = ISNULL(R.Rend_IQEEmajoree ,0) * RC.RatioCotisation,
		RatioDemandePAE = ISNULL(RP.RatioDemandePAE,0),
		UP.MontantSouscrit

	--into tmpProj -- drop table tmpProj
	FROM #tUnitProjection UP
	JOIN #tRatioCotisation RC on RC.UnitID = UP.UnitID
	JOIN dbo.Un_Unit U ON UP.UnitID = U.UnitID
	JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
	JOIN Un_Plan P ON P.PlanID = C.PlanID
	JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID
	LEFT JOIN dbo.Mo_Adr A ON A.AdrID = HB.AdrID
	LEFT JOIN #tUnitModal UM ON UM.UnitID = U.UnitID
	left JOIN Un_Modal M ON M.ModalID = ISNULL(UM.ModalID,U.ModalID)
	LEFT JOIN #tUnitReduction UR ON UR.UnitID = U.UnitID
	LEFT JOIN #tUnitCotisationFee UCF ON UCF.UnitID = U.UnitID
	LEFT JOIN #tConventionCESP CESP ON CESP.ConventionID = C.ConventionID
	--LEFT JOIN #tConventionIQEE IQEE ON IQEE.ConventionID = C.ConventionID
	LEFT JOIN #tConventionYearQualif Y ON Y.ConventionID = C.ConventionID
	LEFT JOIN #tRendement R ON R.ConventionID = C.ConventionID
	LEFT JOIN #tRatioPAE RP on RP.ConventionID = C.ConventionID
	-- 2015-01-05
	--WHERE UP.dtEstimateRI >= @dtProjection
	-- fin 2015-01-05

	ORDER BY C.ConventionNo, U.UnitID

	--	AND P.PlanID = 10
END

-- exec RP_UN_ScholarshipProjection 'Jun 30 2010 12:00:00:000AM'


