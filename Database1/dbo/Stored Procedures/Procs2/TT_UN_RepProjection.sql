/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	TT_UN_RepProjection
Description         :	Traitement de projection des commissions. Rassemblement de données et calculs des commission 
								et bonis d'affaire dans le future pour remplir la table Un_RepProjection pour les rapports de
								projection des commissions.
Valeurs de retours  :	@ReturnValue :
									> 0 : Le traitement a réussi.
									<= 0 : Le traitement a échoué
Note                :	ADX0000752	IA	2005-07-28	Bruno Lapointe		17.14 - Migration
						2011-08-29	Donald Huppé		GLPI 5657 : Modifications et corrections pour réduire l'écart entre les Futures COM projetées dans cette sp, 
														et les futur com du traitement des comissions
						2013-06-25	Donald Huppé	    glpi 9750 : ajouter la clause where suivante pour cette table #tBasicUnitValues : and U.InForceDate <= @dtLastTreatmentDate
						2013-10-18	Donald Huppé	    glpi 10390 : Ne plus vérifier si les projections sont commandées.  On calcule les projection à chaque traitement
						2014-10-07	Donald Huppé	    glpi 10655 (voir dans le code)
						2018-02-01	Donald Huppé	    faireun select -->DISTINCT<-- dans #tBasicCommAndBonusInfoForPeriod				
                        2018-02-16  Pierre-Luc Simard   Exclure aussi les groupes d'unités avec un RIN partiel				
						2018-04-12	Maxime Martel		JIRA: MC-379 Utilisé le nombre d'unité selon les frais pour l'individuel
                        2018-05-17  Pierre-Luc Simard   Ajout des PlanID dans Un_RepLevelBracket
                        2018-05-25	Donald Huppé		Ajout de UnitID dans Un_RepProjection			

exec TT_UN_RepProjection @iTreatmentID = 625
														
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_RepProjection]
	(@iTreatmentID integer = NULL -- pour indiquer à partir de quel traitement on fait les projections.  Si NULL alors c'est à partir du dernier traitement)
	--@Conventionno VARCHAR(30) = NULL
	)
AS
BEGIN
	DECLARE
		@dtLastTreatmentDate DATETIME, --Date du dernier traitement de commission
		@iLastTreatmentID integer,
		@dtMaxDepositDate DATETIME, --Date maximum de projection de commission 
		@dtWorkDate DATETIME, --Date servant pour une boucle sur les dates possibles de dépôt 
		@iProjectionType UnProjectionType, --Type de projection (Mensuel=12, Trimestriel=4, Semi-Annuel=2, Annuel=1)
		@iProjectionCount INTEGER, --Nombre de projection dépendament du type Ex: Si type = mensuel donc nombre = 60 = mois 
		@dMaxRepRisk MoPctPos --Pourcentage de risque maximum d'un représentant

	--Vérifie si la projection a été commendée
	/* --glpi 10390
	IF (SELECT ProjectionOnNextRepTreatment FROM Un_Def) = 0 
		RETURN(0)
	*/
	-- Vide les trace de toutes projections et remet les statistiques à jour concernant ces tables 
	-- avant de faire le traitement
	TRUNCATE TABLE Un_RepProjection
	UPDATE STATISTICS Un_RepProjection
	TRUNCATE TABLE Un_RepProjectionSumary
	UPDATE STATISTICS Un_RepProjectionSumary

	-- Va chercher la date du dernier traitement de commissions
	SELECT 
		@dtLastTreatmentDate = ISNULL(MAX(RepTreatmentDate), 0) ,
		@iLastTreatmentID = max(RepTreatmentID) 
	FROM Un_RepTreatment
	where	(
			@iTreatmentID is NULL 
			OR 
			RepTreatmentID <= @iTreatmentID
			)

	--set @dtLastTreatmentDate = '2011-07-31' -- correction glpi 5657
	--set @iLastTreatmentID = 455 -- correction glpi 5657

	-- Remise à 0 la commande de projection dans la table de configuration et mise à jour de la 
	-- date de traitement.
	UPDATE Un_Def 
	SET 
		ProjectionOnNextRepTreatment = 0,
		RepProjectionTreatmentDate = @dtLastTreatmentDate
    
	-- Va chercher la configuration de la projection
	SELECT 
		@iProjectionType = ProjectionType,
		@iProjectionCount = ISNULL(ProjectionCount, 0),
		@dMaxRepRisk = MAX(MaxRepRisk) 
	FROM Un_Def
	GROUP BY
		ProjectionType,
		ProjectionCount

	SET @dtWorkDate  = @dtLastTreatmentDate
	
	--SET @dtWorkDate = '2011-07-03' 
	--set @dtLastTreatmentDate = '2011-07-03'
	--set @iLastTreatmentID = 451

	-- Détermine la date de la dernière projection
	IF @iProjectionType = 1 
		SET @dtMaxDepositDate = DATEADD(YEAR, @iProjectionCount, @dtLastTreatmentDate)
	ELSE IF @iProjectionType = 2 
		SET @dtMaxDepositDate = DATEADD(MONTH, (@iProjectionCount * 6), @dtLastTreatmentDate)
	ELSE IF @iProjectionType = 4 
		SET @dtMaxDepositDate = DATEADD(MONTH, (@iProjectionCount * 3), @dtLastTreatmentDate)
	ELSE IF @iProjectionType = 12 
		SET @dtMaxDepositDate = DATEADD(MONTH, @iProjectionCount, @dtLastTreatmentDate)

	-- Table temporaire avec toutes les données de base pour un group d'unité en date du dernier
	-- traitement de commission
	CREATE TABLE #tBasicUnitValues (
		UnitID INTEGER PRIMARY KEY, --Clé unique du groupe d'unité
		RepID INTEGER, --Clé du représentant responsable
		SubscriberID INTEGER, --Clé du souscripteur
		SubscriberName VARCHAR(90), --Nom du souscripteur
		ConventionID INTEGER, --Clé de la convention
		ConventionNo VARCHAR(75), --No de la convention
		InForceDate DATETIME, --Date vigueur du groupe d'unité
		NextDepositDate DATETIME, --Date du premier prochain dépôt par rappot au dernier traitement de commission
		FirstDepositDate DATETIME, --Date du premier dépôt. Si la date = 1998-01-30(équivalant transfert Sobeco) on met la date en vigueur du group d'unité  
		RealUnitQty MONEY, --Donne le nombre d'unités par groupe d'unités au dernier traitement de commission
		BasicCotSum MONEY, --Solde des cotisations, en date du dernier traitement de commission
		BasicFeeSum MONEY, --Solde des frais, en date du dernier traitement de commission
		SubsAmount MONEY, --Montant souscrit du group d'unité
		DepositPmt MONEY, --Montant du dépôt
		MonthLaps INTEGER, --Interval de dépôt par mois  
		NbDeposit FLOAT, --Nombre de dépôt restant sur le group d'unité  
		PmtRate DECIMAL(10,4), --Coût par unité d'après la modalité du group d'unité
		PmtByYearID SMALLINT, --Nombre de paiement par année d'après la modalité du group d'unité
		PmtQty INTEGER, --Nombre de paiement total d'après la modalité du group d'unité
		FeeSplitByUnit MONEY, --Quand cette limite des frais est dépassé 50% du dépôt va dans les frais d'adhésion
		FeeByUnit MONEY, --Montant de frais par unité d'après la modalité du group d'unité
		SubscInsurSum MONEY, --Somme des assurances souscripteur moin les somme des assurances d'unités qui ont été déduit (Résiliation Etc.) 
		BenefInsurSum MONEY, --Somme des assurances bénéficiaire 
		BusinessBonusToPay BIT, --Indique si la modalité peut avoir des boni d'affaire à verser
		BenefInsurFaceValue MONEY, --Capital assuré sur l'assurance bénéficiaire
		BenefInsurRate MONEY,  --Taux d'assurance chargé par dépôt pour le bénéficiaire
		SubscInsurRate MONEY, --Taux d'assurance chargé par dépôt pour le souscripteur
		WantSubscInsur BIT --Indique si le souscripteur veur de l'assurance ou non 
	)

	-- Récupération de toute les données de base d'un groupe d'unité
	INSERT INTO #tBasicUnitValues
		SELECT 
			U.UnitID,
			U.RepID,
			C.SubscriberID,
			H.LastName + ', ' + H.FirstName AS SubscriberName,
			U.ConventionID,
			C.ConventionNo,
			U.InforceDate,
			NextDepositDate = 
				CASE 
					WHEN MONTH(U.InForceDate) % (12/M.PmtByYearID) = 0 THEN
						CASE 
							WHEN DATEADD(MONTH, (12/M.PmtByYearID) + ((12/M.PmtByYearID)) + ((MONTH(@dtLastTreatmentDate) - ((12/M.PmtByYearID)))-((MONTH(@dtLastTreatmentDate) - ((12/M.PmtByYearID))) % (12/M.PmtByYearID)))-1, DATEADD(DAY, DAY(C.FirstPmtDate)-1, DATEADD(YEAR, YEAR(@dtLastTreatmentDate)-1900, 0))) < @dtLastTreatmentDate THEN
								DATEADD(MONTH, (12/M.PmtByYearID) + ((12/M.PmtByYearID)) + ((MONTH(@dtLastTreatmentDate) - ((12/M.PmtByYearID)))-((MONTH(@dtLastTreatmentDate) - ((12/M.PmtByYearID))) % (12/M.PmtByYearID)))-1, DATEADD(DAY, DAY(C.FirstPmtDate)-1, DATEADD(YEAR, YEAR(@dtLastTreatmentDate)-1900, 0))) 
						ELSE 
							DATEADD(MONTH, ((12/M.PmtByYearID)) + ((MONTH(@dtLastTreatmentDate) - ((12/M.PmtByYearID)))-((MONTH(@dtLastTreatmentDate) - ((12/M.PmtByYearID))) % (12/M.PmtByYearID)))-1, DATEADD(DAY, DAY(C.FirstPmtDate)-1, DATEADD(YEAR, YEAR(@dtLastTreatmentDate)-1900, 0))) 
						END
				ELSE 
					CASE 
						WHEN DATEADD(MONTH, (MONTH(U.InForceDate) % (12/M.PmtByYearID)) + ((MONTH(@dtLastTreatmentDate) - (MONTH(U.InForceDate) % (12/M.PmtByYearID)))-((MONTH(@dtLastTreatmentDate) - (MONTH(U.InForceDate) % (12/M.PmtByYearID))) % (12/M.PmtByYearID)))-1, DATEADD(DAY, DAY(C.FirstPmtDate)-1, DATEADD(YEAR, YEAR(@dtLastTreatmentDate)-1900, 0))) < @dtLastTreatmentDate THEN
							DATEADD(MONTH, (12/M.PmtByYearID) + (MONTH(U.InForceDate) % (12/M.PmtByYearID)) + ((MONTH(@dtLastTreatmentDate) - (MONTH(U.InForceDate) % (12/M.PmtByYearID)))-((MONTH(@dtLastTreatmentDate) - (MONTH(U.InForceDate) % (12/M.PmtByYearID))) % (12/M.PmtByYearID)))-1, DATEADD(DAY, DAY(C.FirstPmtDate)-1, DATEADD(YEAR, YEAR(@dtLastTreatmentDate)-1900, 0))) 
					ELSE 
						DATEADD(MONTH, (MONTH(U.InForceDate) % (12/M.PmtByYearID)) + ((MONTH(@dtLastTreatmentDate) - (MONTH(U.InForceDate) % (12/M.PmtByYearID)))-((MONTH(@dtLastTreatmentDate) - (MONTH(U.InForceDate) % (12/M.PmtByYearID))) % (12/M.PmtByYearID)))-1, DATEADD(DAY, DAY(C.FirstPmtDate)-1, DATEADD(YEAR, YEAR(@dtLastTreatmentDate)-1900, 0))) 
					END
				END,
			FirstDepositDate = 
				CASE 
					WHEN F.FirstDepositDate = '1998-01-30' THEN U.InForceDate 
				ELSE F.FirstDepositDate
				END,
			RealUnitQty = UQ.UnitQty,
			BasicCotSum = F.CotisationSolde,
			BasicFeeSum = F.FeeSolde,
			SubsAmount = M.PmtQty * ROUND(M.PmtRate * UQ.UnitQty,2),
			DepositPmt = ROUND(M.PmtRate * UQ.UnitQty,2),
			MonthLaps = 12/M.PmtByYearID,
			NbDeposit = ((M.PmtQty * ROUND(M.PmtRate * UQ.UnitQty,2)) - (F.CotisationSolde + F.FeeSolde)) / ROUND(M.PmtRate * UQ.UnitQty,2),
			M.PmtRate,
			M.PmtByYearID,
			M.PmtQty,      
			M.FeeSplitByUnit,
			M.FeeByUnit,     
			SubscInsurSum = F.SubscInsurSum - ISNULL(FR.SubscInsurReduct, 0),
			F.BenefInsurSum,
			M.BusinessBonusToPay,
			BenefInsurFaceValue = ISNULL(BI.BenefInsurFaceValue, 0),
			BenefInsurRate = ISNULL(BI.BenefInsurRate, 0),
			SubscInsurRate = M.SubscriberInsuranceRate,
			WantSubscInsur = U.WantSubscriberInsurance
		FROM dbo.Un_Unit U 
        LEFT JOIN dbo.fntCONV_ObtenirStatutRINUnite(NULL, NULL, @dtLastTreatmentDate) RIN ON RIN.UnitID = U.UnitID
		LEFT JOIN dbo.fntCONV_ObtenirNombreUniteIndividuelSelonFraisEnDate(@dtLastTreatmentDate, NULL) UI on UI.UnitID = U.UnitID
		JOIN Un_Modal M ON M.ModalID = U.ModalID
		JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
		JOIN dbo.Mo_Human H ON H.HumanID = C.SubscriberID
		JOIN (
			SELECT 
				U.UnitID,
				UnitQty = CASE WHEN C.PlanID = 4 THEN ISNULL(UI.UnitQty,0) ELSE U.UnitQty + SUM(ISNULL(UR.UnitQty,0)) END
			FROM dbo.Un_Unit U
			JOIN Un_Convention C On C.ConventionID = U.ConventionID
			LEFT JOIN Un_UnitReduction UR ON U.UnitID = UR.UnitID AND (UR.ReductionDate > @dtLastTreatmentDate)
			LEFT JOIN dbo.fntCONV_ObtenirNombreUniteIndividuelSelonFraisEnDate(@dtLastTreatmentDate, NULL) UI on UI.UnitID = U.UnitID
			GROUP BY
				U.UnitID,
				C.planId,
				ISNULL(UI.UnitQty,0),
				U.UnitQty
			HAVING CASE WHEN C.PlanID = 4 THEN ISNULL(UI.UnitQty,0) ELSE U.UnitQty + SUM(ISNULL(UR.UnitQty,0)) END > 0
			) UQ ON UQ.UnitID = U.UnitID
		JOIN Un_Plan P ON P.PlanID = M.PlanID
		JOIN (
			SELECT 
				C.UnitID,  
				FirstDepositDate = MIN(O.OperDate),
				FeeSolde = SUM( C.Fee),
				CotisationSolde = SUM(C.Cotisation),
				SubscInsurSum = SUM(C.SubscInsur),
				BenefInsurSum = SUM(C.BenefInsur)
			FROM Un_Cotisation C 
			JOIN Un_Oper O ON O.OperID = C.OperID
			WHERE O.OperDate <= @dtLastTreatmentDate
				AND O.OperTypeID NOT IN ('RIN')
			GROUP BY C.UnitID
			) F ON F.UnitID = U.UnitID
			
		-------------------------- glpi 10655
		join (

			SELECT unitid
			FROM (
				SELECT 
					C.UnitID, -- ID du groupe d'unités
					FirstDepositDate = -- Date du premier dépôt (Correspond à la premier transaction pour le groupe d'unités)
						CASE 
							-- On n'a pas l'historique des transactions avant le 30 janvier 1998.  Quand on a une transaction à cette date, c'est une
							-- somme des transaction fait avant.  Dans ce cas on prend la date d'entrée en vigueur de groupe d'unités comme date
							-- de premier dépôt.
							WHEN MIN(O.OperDate) = CAST('1998-01-30' AS DATETIME) THEN MIN(U.InForceDate)
						ELSE MIN(O.OperDate) 
						END 
				FROM dbo.Un_Unit U 
				JOIN Un_Cotisation C ON U.UnitID = C.UnitID
				JOIN Un_Oper O ON O.OperID = C.OperID
				WHERE O.OperTypeID NOT IN ('BEC') -- Exclus les remboursements intégraux.  Les commissions ne sont pas affectés par les variations de frais du à des remboursements intégraux
				GROUP BY C.UnitID
				)v
			where FirstDepositDate <= @dtLastTreatmentDate
			)FD ON FD.UnitID = u.UnitID
		-----------------------------------------------------------
			
		LEFT JOIN (
			SELECT 
				UnitID,
				SubscInsurReduct = SUM(SubscInsurSumByUnit*UnitQty)
			FROM Un_UnitReduction        
			WHERE ReductionDate <= @dtLastTreatmentDate 
			GROUP BY UnitID
			) FR ON FR.UnitID = U.UnitID
		LEFT JOIN Un_BenefInsur BI ON BI.BenefInsurID = U.BenefInsurID AND BI.BenefInsurFaceValue IN (10000, 20000)
		WHERE 1=1
			AND (M.PmtRate * UQ.UnitQty > 0)
			--AND (M.PmtQty > 1 OR (M.PmtQty = 1 AND U.TerminatedDate IS NULL AND p.PlanID <> 4) )
			--AND (P.PlanTypeID <> 'IND')
			--AND U.IntReimbDate IS NULL
            AND ISNULL(RIN.iStatut_RIN, 0) NOT IN (2, 3) -- Exclure les groupes d'unités avec un RIN partiel ou complet
			-- 10655 -- on enlève cette clause
			--AND isnull(U.TerminatedDate,'3000-01-01') > @dtLastTreatmentDate-- IS NULL -- correction glpi 5657  --glpi 10655
			--AND U.ActivationConnectID IS NOT NULL --glpi 10655
			--AND U.StopRepComConnectID IS NULL --glpi 10655
			--and U.InForceDate <= @dtLastTreatmentDate --glpi 10655
			--AND ((M.PmtQty * ROUND(M.PmtRate * UQ.UnitQty,2) - (F.CotisationSolde + F.FeeSolde)) / ROUND(M.PmtRate * UQ.UnitQty,2) > 0) -- correction glpi 5657 
			--AND (C.ConventionNo = @Conventionno OR @Conventionno IS NULL)

	--SELECT '#tBasicUnitValues',* from #tBasicUnitValues --WHERE UnitID = 544717
	--return

	-- Cette table énumère toute les dates possibles de dépôt entre le date de dernier traitement 
	-- de commissions et de la dernière date de projection 
	DECLARE @tDepositDate TABLE (
		DepositDate DATETIME PRIMARY KEY --Dates possibles de dépôt 
	)
	-- Récupération des dates possibles de dépôt
	WHILE @dtWorkDate <= @dtMaxDepositDate
	BEGIN
		INSERT INTO @tDepositDate
		VALUES (@dtWorkDate)

		SET @dtWorkDate = DATEADD(DAY, 1, @dtWorkDate)
	END

	-- Cette table énumère toute les dates de projections de commissions entre le date de dernier traitement 
	-- de commissions et de la dernière date de projection 
	CREATE TABLE #tProjectionDate (
		ProjectionDate DATETIME PRIMARY KEY, --Dates de projection 
		PreviousProjectionDate DATETIME --Date de projection précédente
	)
	-- Récupération des dates de projection de commission
	INSERT INTO #tProjectionDate
		SELECT DISTINCT
			V1.ProjectionDate,
			PreviousProjectionDate = MAX(ISNULL(D2.DepositDate, 0))
		FROM (
			SELECT 
				D1.DepositDate AS ProjectionDate
			FROM @tDepositDate D1
			WHERE CASE 
						WHEN @iProjectionType = 1 THEN 
							DATEDIFF(YEAR, @dtLastTreatmentDate+1, D1.DepositDate) % (@iProjectionType)
					ELSE DATEDIFF(MONTH, @dtLastTreatmentDate+1, D1.DepositDate) % (12/@iProjectionType)
					END = 0
				AND CASE --Si c'est le dernier mois de l'année
						WHEN @iProjectionType = 1 THEN 
							CAST(MONTH(D1.DepositDate) AS INTEGER) - 12
					ELSE 0
					END = 0 --Recherche du dernier jour du mois 
				AND DAY(D1.DepositDate) = DAY(DATEADD(DAY, -1, CAST(CAST(YEAR(DATEADD(MONTH, 1, D1.DepositDate)) AS CHAR)+'-'+CAST(MONTH(DATEADD(MONTH, 1, D1.DepositDate)) AS CHAR) +'-01' AS DATETIME)))
			) V1
		LEFT JOIN @tDepositDate D2 ON CASE 
													WHEN @iProjectionType = 1 THEN 
														DATEDIFF(YEAR, @dtLastTreatmentDate+1, D2.DepositDate) % (@iProjectionType)
												ELSE DATEDIFF(MONTH, @dtLastTreatmentDate+1, D2.DepositDate) % (12/@iProjectionType)
												END = 0
											AND	CASE -- Si c'est le dernier mois de l'année
														WHEN @iProjectionType = 1 THEN 
															CAST(MONTH(D2.DepositDate) AS INTEGER) - 12
													ELSE 0
													END = 0 -- Recherche du dernier jour du mois 
											AND DAY(D2.DepositDate) = DAY(DATEADD(DAY, -1, CAST(CAST(YEAR(DATEADD(MONTH, 1, D2.DepositDate)) AS CHAR)+'-'+CAST(MONTH(DATEADD(MONTH, 1, D2.DepositDate)) AS CHAR) +'-01' AS DATETIME)))
											AND (D2.DepositDate < V1.ProjectionDate)
		GROUP BY V1.ProjectionDate
	
	-- Cette table contient tout les dépôts théoriques à venir pour la durée de la projection
	-- ce par date et groupe d'unités
	CREATE TABLE #tFuturDeposit (
		UnitID INTEGER, --Clé unique du groupe d'unité
		FuturDepositDate DATETIME, --Date futur du dépôt
		FuturCot MONEY, --Montant futur de cotisation
		FuturFee MONEY, --Montant futur de frais d'adhésion
		FuturSubscInsur MONEY, --Montant d'assurance souscripteur
		FuturBenefInsur MONEY --Montant d'assurance bénéficiaire
		--PRIMARY KEY (UnitID, FuturDepositDate)
	)
	CREATE INDEX #tFuturDepositFuturDepositDate ON #tFuturDeposit(FuturDepositDate) WITH FILLFACTOR = 90

	create table #FuturFee (
			modal varchar(25),
			conventionno varchar(50),
			UnitID int,
			UnitQty float,
			FeePaid money,
			PmtDate datetime,
			Pmt money
			)
	-- correction glpi 5657		
	insert into #FuturFee exec psREPR_FutursEncaissementsFrais @dtLastTreatmentDate

	INSERT into #tFuturDeposit
	SELECT 
		F.unitid,
		FuturDepositDate = PmtDate,
		FuturCot = ROUND(M.PmtRate * (CASE WHEN C.PlanID = 4 THEN ISNULL(UI.UnitQty,0) ELSE U.UnitQty+ isnull(UR.QtyReduite,0)END),2) - Pmt,
		FuturFee = Pmt,
		FuturSubscInsur = dbo.FN_CRQ_TaxRounding
					((	CASE U.WantSubscriberInsurance -- Assurance souscripteur
							WHEN 0 THEN 0
						ELSE ROUND(M.SubscriberInsuranceRate * (CASE WHEN C.PlanID = 4 THEN ISNULL(UI.UnitQty,0) ELSE U.UnitQty + isnull(UR.QtyReduite,0) END),2)
						END )),
		FuturBenefInsur = ISNULL(BI.BenefInsurRate,0) 
	FROM #FuturFee F
	JOIN dbo.Un_Unit U on F.UnitID = U.UnitID
	JOIN Un_Modal M ON U.ModalID = M.ModalID
	JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
	JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
	LEFT JOIN dbo.fntCONV_ObtenirNombreUniteIndividuelSelonFraisEnDate(@dtLastTreatmentDate, NULL) UI on UI.UnitID = U.UnitID
	LEFT JOIN Mo_State St ON St.StateID = S.StateID
	LEFT JOIN Un_BenefInsur BI ON BI.BenefInsurID = U.BenefInsurID
	LEFT JOIN (select unitid, QtyReduite = sum(unitqty) from Un_UnitReduction WHERE /*glpi 10655*/ ReductionDate > @dtLastTreatmentDate group by unitid ) UR on UR.unitid = u.unitID
	
	WHERE PmtDate IS NOT NULL
	--AND (C.ConventionNo = @Conventionno OR @Conventionno IS NULL)
	
	/*

	-- Récupération des dépôts futur pour un groupe d'unité
	INSERT INTO #tFuturDeposit
		SELECT
			V.UnitID,
			V.FuturDepositDate,
			Cotisation = V.Cotisation - V.Fee,
			V.Fee,
			V.FuturSubscInsur,
			V.FuturBenefInsur      
		FROM (
			SELECT 
				V.UnitID,
				V.FuturDepositDate,
				V.Cotisation,
				Fee = 
					CASE 
						WHEN V.BasicFeeSum >= ROUND(V.RealUnitQty * V.FeeByUnit,2) OR (V.BasicFeeSum >= V.ActualFeeSum) THEN 0
					ELSE
						CASE 
							WHEN (V.BasicFeeSum > V.PreviousFeeSum) AND (V.BasicFeeSum <= V.ActualFeeSum ) THEN 
								V.ActualFeeSum - V.BasicFeeSum
						ELSE   
							V.ActualFeeSum - V.PreviousFeeSum
						END
					END,
				V.FuturSubscInsur,
				V.FuturBenefInsur
			FROM (      
				SELECT 
					B.UnitID,
					FuturDepositDate = D.DepositDate,      
					Cotisation = B.DepositPmt,
					PreviousFeeSum =
						CASE 
							WHEN B.NextDepositDate = D.DepositDate THEN B.BasicFeeSum
							WHEN DAY(B.NextDepositDate) <> DAY(D.DepositDate) THEN -- Gère le cas des dépôts mensuels avec un jour de prélèvement le 29, 30 ou 31.
								dbo.fn_Un_EstimatedFee(                         
									(	(	( dbo.fn_Un_EstimatedNumberOfDeposit(       
													B.NextDepositDate,                      
													DATEADD(DAY,1,D.DepositDate),
													DAY(B.NextDepositDate),
													B.PmtByYearID,
													B.PmtQty,
													B.InforceDate)-1
											) * B.DepositPmt
										) + B.BasicCotSum + B.BasicFeeSum
									),
									B.RealUnitQty,
									B.FeeSplitByUnit,
									B.FeeByUnit )
						ELSE
							dbo.fn_Un_EstimatedFee(                         
								(	(	( dbo.fn_Un_EstimatedNumberOfDeposit(       
												B.NextDepositDate,                      
												D.DepositDate,                          
												DAY(B.NextDepositDate),
												B.PmtByYearID,
												B.PmtQty,
												B.InforceDate)-1
										) * B.DepositPmt
									) + B.BasicCotSum + B.BasicFeeSum
								),
								B.RealUnitQty,
								B.FeeSplitByUnit,
								B.FeeByUnit )
						END,
					ActualFeeSum = 
						CASE --Frais du calcul du depot actuel 
							WHEN DAY(B.NextDepositDate) <> DAY(D.DepositDate) THEN -- Gère le cas des dépôts mensuels avec un jour de prélèvement le 29, 30 ou 31. 
								dbo.fn_Un_EstimatedFee(                                    
									(	( dbo.fn_Un_EstimatedNumberOfDeposit(                            
												B.NextDepositDate, 
												DATEADD(DAY,1,D.DepositDate),
												DAY(B.NextDepositDate),
												B.PmtByYearID,
												B.PmtQty,
												B.InforceDate) * B.DepositPmt
										) + B.BasicCotSum + B.BasicFeeSum
									),
									B.RealUnitQty,
									B.FeeSplitByUnit,  
									B.FeeByUnit )
						ELSE
							dbo.fn_Un_EstimatedFee(                                   
								(	( dbo.fn_Un_EstimatedNumberOfDeposit(                            
											B.NextDepositDate, 
											D.DepositDate,
											DAY(B.NextDepositDate),
											B.PmtByYearID,
											B.PmtQty,
											B.InforceDate) * B.DepositPmt
									) + B.BasicCotSum + B.BasicFeeSum
								),
								B.RealUnitQty,
								B.FeeSplitByUnit,  
								B.FeeByUnit)
						END,
					FuturSubscInsur = ROUND(B.SubscInsurRate * B.RealUnitQty,2),
					FuturBenefInsur = B.BenefInsurRate,
					B.BasicFeeSum,
					B.RealUnitQty,
					B.FeeByUnit
				FROM #tBasicUnitValues B 
				JOIN @tDepositDate D ON ( DATEDIFF(MONTH, B.NextDepositDate, D.DepositDate) % B.MonthLaps = 0
		      								AND( DAY(B.NextDepositDate) = DAY(D.DepositDate)
													OR	( DAY(B.NextDepositDate) IN (29,30,31) -- Gère le cas des dépôts mensuels avec un jour de prélèvement le 29, 30 ou 31.
														AND (DAY(D.DepositDate) < DAY(B.NextDepositDate))
														AND (DAY(DATEADD(DAY,1,D.DepositDate)) = 1)
														)
													)
												AND( D.DepositDate <= DATEADD(MONTH, B.MonthLaps * CAST(B.NbDeposit AS INTEGER), B.NextDepositDate))
												)
				) V
			) V
		---------
		UNION ALL
		---------
		SELECT
			UnitID,
			DepositDate,
			Cotisation = Cotisation - Fee,
			Fee,
			FuturSubscInsur,
			FuturBenefInsur     
		FROM ( 
			SELECT 
				B.UnitID,
				DepositDate = DATEADD(MONTH, B.MonthLaps * (CAST(B.NbDeposit AS INTEGER)+1), B.NextDepositDate),      
				Cotisation = B.SubsAmount - (B.BasicCotSum + B.BasicFeeSum + (CAST(B.NbDeposit AS INTEGER) * B.DepositPmt)),
				Fee = 
					dbo.fn_Un_EstimatedFee(
						B.SubsAmount - (B.BasicCotSum + B.BasicFeeSum + (CAST(B.NbDeposit AS INTEGER) * B.DepositPmt)),
						B.RealUnitQty,
						B.FeeSplitByUnit,
						B.FeeByUnit),
				FuturSubscInsur = ROUND(B.SubscInsurRate * B.RealUnitQty,2),
				FuturBenefInsur = B.BenefInsurRate     
			FROM #tBasicUnitValues B
			WHERE (CAST(B.NbDeposit AS INTEGER) <>  B.NbDeposit)
				AND (DATEADD(MONTH, B.MonthLaps * (CAST(B.NbDeposit AS INTEGER)+1), B.NextDepositDate) < @dtMaxDepositDate)
			) D 
		ORDER BY
			V.UnitID,
			V.FuturDepositDate

*/

	--SELECT '#tFuturDeposit',* FROM #tFuturDeposit
	
	--return

	-- Cette table contient les unités comportant des transactions non commissionnable pour appliquer 
	-- la règle des commissions 0.01$ frais pour 0.01$ commission   
	CREATE TABLE #tUnitNotComm (
		UnitID INTEGER PRIMARY KEY --Clé unique du groupe d'unité
	)
	-- Récupération des groupes d'unités comportant des transactions non commissionnable
	INSERT INTO #tUnitNotComm
		SELECT DISTINCT
			C.UnitID
		FROM Un_Cotisation C
		JOIN Un_Oper O ON O.OperID = C.OperID
		JOIN Un_OperType OT ON OT.OperTypeID = O.OperTypeID
		WHERE OT.CommissionToPay = 0
			AND C.Fee > 0
			AND O.OperDate <= @dtLastTreatmentDate

	--SELECT '#tUnitNotComm',* FROM #tUnitNotComm

	-- Cette table contient la somme des commissions + avances versé au représentant et au directeur
	-- par groupe d'unité et la somme maximum par niveau de commission + avance
	CREATE TABLE #tBasicCommByRep (
		UnitID INTEGER, --Clé unique du groupe d'unité  
		RepID INTEGER, --Clé unique du représentant du groupe d'unité
		RepLevelID INTEGER, --Niveau du représentant à la date en vigueur du groupe d'unité 
		RepRoleID CHAR(3), --Role du représentant
		RepPct DECIMAL(10,4), --Pourcentage de commission dont le représentant a droit d'après son niveau
		RepName VARCHAR(90), --Nom, prénom du représentant
		RepCode VARCHAR(75), --Code du représentant 
		RepLicenseNo VARCHAR(75), --No de license du représentant
		RepRoleDesc VARCHAR(75), --Description du rôle du représentant
		RepLevelShortDesc VARCHAR(75), --Description du niveau du représentant
		TotalLevelAdvance MONEY, --Total maximum d'avance pour le niveau concerné
		TotalLevelCommission MONEY, --Total maximum de commission pour le niveau concerné
		TotalCommPaid MONEY, --Somme des commissions payées en date du dernier traitement de commission
		TotalAdvancePaid MONEY, --Somme des avances payées en date du dernier traitement de commission
		TotalCoveredAdvancePaid MONEY, --Somme des avances couverte payées en date du dernier traitement de commission
		ISBBusinessBonusPaid MONEY, --Somme des bonis d'affaire sur les assurance souscripteur
		IB5BusinessBonusPaid MONEY, --Somme des bonis d'affaire ser les assurance bénéficiaire avec 5000$ de capital assuré
		IB1BusinessBonusPaid MONEY, --Somme des bonis d'affaire ser les assurance bénéficiaire avec 10000$ de capital assuré
		IB2BusinessBonusPaid MONEY,  --Somme des bonis d'affaire ser les assurance bénéficiaire avec 20000$ de capital assuré 
		TotalBusinessBonus MONEY --Total maximum de boni d'affaire pour les assurance bénéficiaire et souscripteur
		PRIMARY KEY (UnitID, RepID, RepLevelID, RepPct) 
	)
	-- Récupération de toute les données de base des commission pour un groupe d'unité, un 
	-- représentant et le niveau associé
	
	INSERT INTO #tBasicCommByRep
		SELECT
			V1.UnitID,
			V1.RepID,
			V1.RepLevelID,
			V1.RepRoleID,     
			V1.RepPct,
			RepName = H.LastName + ', ' + H.FirstName,   
			R.RepCode,    
			R.RepLicenseNo,   
			RR.RepRoleDesc,   
			V1.RepLevelShortDesc,  
			V1.TotalLevelAdvance,
			V1.TotalLevelCommission,
			TotalCommPaid = ISNULL(V2.TotalCommPaid, 0),
			TotalAdvancePaid = ISNULL(V2.TotalAdvancePaid, 0),
			TotalCoveredAdvancePaid = ISNULL(V2.TotalCoveredAdvancePaid, 0),
			ISBBusinessBonusPaid = ISNULL(V3.ISBBusinessBonusPaid, 0),
			IB5BusinessBonusPaid = ISNULL(V3.IB5BusinessBonusPaid, 0),
			IB1BusinessBonusPaid = ISNULL(V3.IB1BusinessBonusPaid, 0), 
			IB2BusinessBonusPaid = ISNULL(V3.IB2BusinessBonusPaid, 0),
			TotalBusinessBonus = ROUND(ISNULL(RBBB.BusinessBonusByUnit, 0) * V1.RealUnitQty,2) * ISNULL(RBBB.BusinessBonusNbrOfYears, 0) +
										ROUND(ISNULL(RBBS.BusinessBonusByUnit, 0) * V1.RealUnitQty,2) * ISNULL(RBBS.BusinessBonusNbrOfYears, 0)
		FROM (
			SELECT 
				U.UnitID,
				U.RepID,
				U.InforceDate,
				U.WantSubscInsur,
				U.BenefInsurFaceValue,
				U.RealUnitQty, 
				RL.RepLevelID,
				RepLevelShortDesc = ISNULL(RL.LevelShortDesc, ''),
				RL.RepRoleID,
				RepPct = 100.00,
				TotalLevelAdvance = 
					SUM(
						CASE 
							WHEN ISNULL(VT.UnitID, 0) = 0 AND RLB.RepLevelBracketTypeID = 'ADV' THEN 
								ROUND(RLB.AdvanceByUnit * U.RealUnitQty,2)
						ELSE 0
						END
						),
				TotalLevelCommission =
					SUM(
						CASE 
							WHEN (ISNULL(VT.UnitID, 0) <> 0) OR RLB.RepLevelBracketTypeID = 'COM' THEN
								ROUND(RLB.AdvanceByUnit * U.RealUnitQty,2)
						ELSE 0
						END
						)
			FROM #tBasicUnitValues U
            JOIN dbo.Un_Unit UC ON UC.UnitID = U.UnitID
            JOIN dbo.Un_Convention C ON C.ConventionID = UC.ConventionID 
			JOIN Un_RepLevelHist RLH ON RLH.RepID = U.RepID
			JOIN Un_RepLevel RL ON RL.RepLevelID = RLH.RepLevelID
			JOIN Un_RepLevelBracket RLB ON RLB.RepLevelID = RL.RepLevelID AND RLB.PlanID = C.PlanID
			LEFT JOIN #tUnitNotComm VT ON VT.UnitID = U.UnitID
			WHERE (RLH.StartDate <= U.InForceDate)
				AND( RLH.EndDate IS NULL 
					OR RLH.EndDate >= U.InForceDate
					)
				AND RL.RepRoleID = 'REP'
				AND (RLB.EffectDate <= U.InForceDate)
				AND( RLB.TerminationDate IS NULL
					OR RLB.TerminationDate >= U.InForceDate
					)	
			GROUP BY 
				U.UnitID,
				U.RepID,
				U.InforceDate,
				U.WantSubscInsur,
				U.BenefInsurFaceValue,
				U.RealUnitQty,
				RL.RepLevelID,
				RL.RepRoleID,
				RL.LevelShortDesc
			-----
			UNION
			-----
			SELECT 
				U.UnitID,
				RepID = RBH.BossID,
				U.InforceDate,
				U.WantSubscInsur,
				U.BenefInsurFaceValue,
				U.RealUnitQty, 
				RL.RepLevelID,
				RepLevelShortDesc = RL.LevelShortDesc,
				RL.RepRoleID,
				RepPct = RBH.RepBossPct,
				TotalLevelAdvance =
					SUM(
						CASE 
							WHEN ISNULL(VT.UnitID, 0) = 0 AND RLB.RepLevelBracketTypeID = 'ADV' THEN
								ROUND(RLB.AdvanceByUnit * U.RealUnitQty,2)
						ELSE 0
						END
						),
				TotalLevelCommission =
					SUM(
						CASE 
							WHEN (ISNULL(VT.UnitID, 0) <> 0) OR RLB.RepLevelBracketTypeID = 'COM' THEN
								ROUND(RLB.AdvanceByUnit * U.RealUnitQty,2)
						ELSE 0
						END
						)
			FROM #tBasicUnitValues U
            JOIN dbo.Un_Unit UC ON UC.UnitID = U.UnitID
            JOIN dbo.Un_Convention C ON C.ConventionID = UC.ConventionID 
			JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID
			JOIN Un_RepLevel RL ON RL.RepRoleID = RBH.RepRoleID
			JOIN Un_RepLevelHist RLH ON RLH.RepID = RBH.BossID
			JOIN Un_RepLevelBracket RLB ON RLB.RepLevelID = RL.RepLevelID AND RLB.PlanID = C.PlanID AND (RLB.EffectDate <= U.InForceDate) AND (RLB.TerminationDate IS NULL OR (RLB.TerminationDate >= U.InForceDate))
			LEFT JOIN #tUnitNotComm VT ON VT.UnitID = U.UnitID
			WHERE (RBH.StartDate <= U.InForceDate) 
				AND( RBH.EndDate IS NULL
					OR (RBH.EndDate >= U.InForceDate)
					)
				AND (RL.RepRoleID <> 'REP' )--AND RL.RepRoleID <> 'CND')
				AND RL.RepLevelID = RLH.RepLevelID
				AND (RLH.StartDate <= U.InForceDate)
				AND( RLH.EndDate IS NULL
					OR (RLH.EndDate >= U.InForceDate)
					)
			GROUP BY
				U.UnitID,
				RBH.BossID,
				U.InforceDate,
				U.WantSubscInsur,
				U.BenefInsurFaceValue,
				U.RealUnitQty,
				RL.RepLevelID,
				RL.RepRoleID,
				RL.LevelShortDesc,
				RBH.RepBossPct 
			) V1
		JOIN Un_RepRole RR ON RR.RepRoleID = V1.RepRoleID
		JOIN Un_Rep R ON R.RepID = V1.RepID
		JOIN dbo.MO_Human H ON H.HumanID = V1.RepID
		LEFT JOIN (
			SELECT 
				R.UnitID,
				R.RepID,
				R.RepLevelID,
				TotalCommPaid = SUM(R.CommissionAmount),
				TotalAdvancePaid = SUM(R.AdvanceAmount),
				TotalCoveredAdvancePaid = SUM(R.CoveredAdvanceAmount) 
			FROM Un_RepCommission R 
			where R.RepTreatmentID <= @iLastTreatmentID -- correction glpi 5657
			GROUP BY
				R.UnitID,
				R.RepID,
				R.RepLevelID
			) V2 ON V2.UnitID = V1.UnitID AND V2.RepID = V1.RepID AND V2.RepLevelID = V1.RepLevelID
		LEFT JOIN (
			SELECT 
				UnitID,
				RepID,
				RepLevelID,
				ISBBusinessBonusPaid =
					SUM( 	CASE 
								WHEN InsurTypeID = 'ISB' THEN SumBusinessBonusAmount
							ELSE 0
							END
						),
				IB5BusinessBonusPaid =
					SUM( 	CASE 
								WHEN InsurTypeID = 'IB5' THEN SumBusinessBonusAmount
							ELSE 0
							END
						),
				IB1BusinessBonusPaid =
					SUM( 	CASE 
								WHEN InsurTypeID = 'IB1' THEN SumBusinessBonusAmount
							ELSE 0
							END
						),
				IB2BusinessBonusPaid =
					SUM( 	CASE 
								WHEN InsurTypeID = 'IB2' THEN SumBusinessBonusAmount
							ELSE 0
							END
						)
			FROM (
				SELECT 
					UnitID,
					RepID,
					RepLevelID,
					SumBusinessBonusAmount = SUM(BusinessBonusAmount),
					InsurTypeID
				FROM Un_RepBusinessBonus
				GROUP BY
					RepID,
					UnitID,
					InsurTypeID,
					RepLevelID
				) V
			GROUP BY
				UnitID,
				RepID,
				RepLevelID 
			) V3 ON V3.UnitID = V1.UnitID AND V3.RepID = V1.RepID AND V3.RepLevelID = V1.RepLevelID 
		LEFT JOIN Un_RepBusinessBonusCfg RBBB	ON RBBB.RepRoleID = V1.RepRoleID 
															AND(RBBB.StartDate <= V1.InForceDate)
															AND( RBBB.EndDate IS NULL
																OR (RBBB.EndDate >= V1.InForceDate)
																)
															AND(	( RBBB.InsurTypeID = 'IB1' 
																	AND V1.BenefInsurFaceValue = 10000
																	)
																OR ( RBBB.InsurTypeID = 'IB2'
																	AND V1.BenefInsurFaceValue = 20000
																	)
																)
		LEFT JOIN Un_RepBusinessBonusCfg RBBS	ON (V1.WantSubscInsur <> 0)
															AND RBBS.RepRoleID = V1.RepRoleID
															AND RBBS.InsurTypeID = 'ISB'
															AND (RBBS.StartDate <= V1.InForceDate)
															AND( RBBS.EndDate IS NULL
																OR (RBBS.EndDate >= V1.InForceDate)
																)
			/*		-- glpi 10655											
		WHERE (ISNULL(V2.TotalCommPaid, 0) < V1.TotalLevelCommission)
			OR (ISNULL(V2.TotalCoveredAdvancePaid, 0) < V1.TotalLevelAdvance) 
			OR (	ISNULL(V3.ISBBusinessBonusPaid, 0) + 
					ISNULL(V3.IB5BusinessBonusPaid, 0) + 
					ISNULL(V3.IB1BusinessBonusPaid, 0) + 
					ISNULL(V3.IB2BusinessBonusPaid, 0)
				< 	(	ROUND(ISNULL(RBBB.BusinessBonusByUnit, 0) * V1.RealUnitQty,2) * 
						ISNULL(RBBB.BusinessBonusNbrOfYears, 0) 
					) +
					(	ROUND(ISNULL(RBBS.BusinessBonusByUnit, 0) * V1.RealUnitQty,2) * 
						ISNULL(RBBS.BusinessBonusNbrOfYears, 0)
					)
				)
*/
	--SELECT '#tBasicCommByRep',* FROM #tBasicCommByRep

	--SELECT '#tBasicCommByRep',* FROM #tBasicCommByRep

	-- Cette table contient tout les sommes de frais d'adhésion et d'assurance théoriques à venir pour la durée de la projection 
	-- ce par date et groupe d'unités
	CREATE TABLE #tFuturSumFeeInsur (
		UnitID INTEGER, --Clé unique du groupe d'unité
		ProjectionDate DATETIME, --Date futur du dépôt
		PreviousProjectionDate DATETIME, --Date De projection précédente 
		FuturSumFee MONEY, --Somme des montants futur de frais d'adhésion pour chaque date de projection
		FuturSumSubscInsur MONEY, --Somme des montant d'assurance souscripteur pour chaque date de projection
		FuturSumBenefInsur MONEY --Somme des montant d'assurance bénéficiaire pour chaque date de projection
		PRIMARY KEY (UnitID, ProjectionDate)
	)
	-- Récupération de toute les sommes de frais d'adhésion par date de projection
	INSERT INTO #tFuturSumFeeInsur
		SELECT 
			F.UnitID,
			P.ProjectionDate,
			P.PreviousProjectionDate,     
			FuturSumFee = SUM(F.FuturFee),
			FuturSumSubscInsur = SUM(F.FuturSubscInsur),
			FuturSumBenefInsur = SUM(F.FuturBenefInsur) 
		FROM #tFuturDeposit F
		JOIN #tProjectionDate P ON F.FuturDepositDate <= P.ProjectionDate
		GROUP BY
			F.UnitID,
			P.ProjectionDate,
			P.PreviousProjectionDate 

	--SELECT '#tFuturSumFeeInsur', * FROM #tFuturSumFeeInsur
	
	-- Libert l'espace pris par cette table puisque quel n'est plus utilisé dans le reste du traitement.
	DROP TABLE #tFuturDeposit
  
	-- Table des échelles des niveaux de représentants avec trois colonnes pour le AdvanceByUnit (Une par type)
	CREATE TABLE #tRepLevelBracket3Col (
		RepLevelBracketID INTEGER PRIMARY KEY, -- ID unique de la bracket
		RepLevelID INTEGER, -- ID du niveau du représentant
        PlanID INTEGER, -- ID du plan de la convention
		TargetFeeByUnit MONEY, -- Frais sur unités à atteindre pour toucher la commission
		EffectDate DATETIME, -- Date d'effectivité de la barcket
		TerminationDate DATETIME, -- Date de fin de la bracket
		SumComByUnit MONEY, -- Montant de commission de service touchée
		SumAdvByUnit MONEY, -- Montant d'avance touchée
		SumCadByUnit MONEY -- Montant d'avance couverte touchée
	)
	INSERT INTO #tRepLevelBracket3Col
		SELECT  
			RepLevelBracketID,
			RepLevelID, 
            PlanID,
			TargetFeeByUnit,
			EffectDate, 
			TerminationDate,
			SumComByUnit = 
				CASE 
					WHEN RepLevelBracketTypeID = 'COM' THEN AdvanceByUnit 
				ELSE 0
				END,
			SumAdvByUnit = 
				CASE 
					WHEN RepLevelBracketTypeID = 'ADV' THEN AdvanceByUnit
				ELSE 0
				END,
			SumCadByUnit =
				CASE
					WHEN RepLevelBracketTypeID = 'CAD' THEN AdvanceByUnit
				ELSE 0
				END
		FROM Un_RepLevelBracket 
	
	-- Table des exceptions
	CREATE TABLE #tRepException (
		UnitID INTEGER, -- ID du groupe d'unités
		RepID INTEGER, -- ID du représentant
		RepLevelID INTEGER, -- ID du niveau du représentant
		ComException MONEY, -- Exception sur commission de service
		AdvException MONEY, -- Exception sur avance
		CadException MONEY, -- Exception sur avance couverte
		PRIMARY KEY (UnitID,RepID,RepLevelID)
	)
	INSERT INTO #tRepException
		SELECT 
			E.UnitID,
			E.RepID,
			E.RepLevelID,
			ComException =
				SUM(
					CASE ET.RepExceptionTypeTypeID
						WHEN 'COM' THEN E.RepExceptionAmount
					ELSE 0
					END),
			AdvException =
				SUM(
					CASE ET.RepExceptionTypeTypeID 
						WHEN 'ADV' THEN E.RepExceptionAmount
					ELSE 0
					END),
			CadException = 
				SUM(
					CASE ET.RepExceptionTypeTypeID
						WHEN 'CAD' THEN E.RepExceptionAmount
					ELSE 0 
					END)
		FROM Un_RepException E  
		JOIN Un_RepExceptionType ET ON ET.RepExceptionTypeID = E.RepExceptionTypeID
		JOIN #tBasicCommByRep BR ON BR.UnitID = E.UnitID AND BR.RepID = E.RepID AND BR.RepLevelID = E.RepLevelID
		WHERE E.RepExceptionDate <= @dtLastTreatmentDate
		GROUP BY
			E.UnitID,
			E.RepID,
			E.RepLevelID

	-- Cette table contient toutes les sommes de frais d'adhésion, de commission, d'avance et 
	-- d'avance couverte à venir pour la durée de la projection ce par dates, groupe d'unités, 
	-- représentant et niveau du représentant
	CREATE TABLE #tFuturCommSumByProjection (
		UnitID INTEGER, --Clé unique du groupe d'unité
		RepID INTEGER, --Clé unique du représentant ou directeur
		RepLevelID INTEGER, --Clé unique du niveau du représentant
		ProjectionDate DATETIME,  --Date de projection de commission
		TotalFee MONEY, --Somme des frais d'adhésion à la date de la projection de commission
		SumCom MONEY, --Somme des commissions dû en date de la projection de commission
		SumAdv MONEY, --Somme des Avance dû en date de la projection de commission 
		SumCad MONEY --Somme des Avance couverte dû en date de la projection de commission 
		PRIMARY KEY (UnitID, RepID, RepLevelID, ProjectionDate)
	)

	-- Récupération de toute les sommes de commission dû, d'avance dû et avance couverte dû par group d'unité,
	-- représentant ou directeur et par date de projection
  INSERT INTO #tFuturCommSumByProjection
		SELECT DISTINCT
			BU.UnitID,
			RepID = 
				CASE 
					WHEN BR.RepRoleID = 'REP' THEN BU.RepID 
				ELSE BR.RepID
				END,
			BR.RepLevelID,
			F.ProjectionDate,
			TotalFee = BU.BasicFeeSum + F.FuturSumFee,
			SumCom =
				CASE  
					WHEN ISNULL(VT.UnitID, 0) = 0 THEN 
					/*  ici */
						ROUND(ROUND(SUM(VRL.SumComByUnit) * BU.RealUnitQty,2) * (ISNULL(BR.RepPct, 0)/100),2) + ISNULL(E.ComException, 0)/* 0 */  - BR.TotalCommPaid /*0*/
				ELSE 
					CASE 
						WHEN BR.RepRoleID = 'REP' THEN 
							CASE 
								WHEN ROUND(SUM(VRL.SumAdvByUnit) * BU.RealUnitQty,2) >= BU.BasicFeeSum + F.FuturSumFee THEN 
									ROUND(ROUND(SUM(VRL.SumComByUnit) * BU.RealUnitQty,2) * (ISNULL(BR.RepPct, 0)/100),2) + ISNULL(E.ComException, 0) + F.FuturSumFee - BR.TotalCommPaid
							ELSE 
								ROUND((ROUND(SUM(VRL.SumComByUnit) * BU.RealUnitQty,2) + ROUND(SUM(VRL.SumAdvByUnit) * BU.RealUnitQty,2)) * (ISNULL(BR.RepPct, 0)/100),2) + ISNULL(E.ComException, 0) - BR.TotalCommPaid
							END
					ELSE ROUND(ROUND(SUM(VRL.SumComByUnit + VRL.SumCadByUnit) * BU.RealUnitQty,2) * (ISNULL(BR.RepPct, 0)/100),2) + ISNULL(E.ComException, 0) - BR.TotalCommPaid
					END
				END,
			SumAdv = 
				CASE  
					WHEN ISNULL(VT.UnitID, 0) = 0 THEN
						ROUND(ROUND(SUM(VRL.SumAdvByUnit) * BU.RealUnitQty,2) * (ISNULL(BR.RepPct, 0)/100),2) + ISNULL(E.AdvException, 0) - BR.TotalAdvancePaid
				ELSE BR.TotalAdvancePaid * -1
				END, 
			SumCad = 
				CASE 
					WHEN ISNULL(VT.UnitID, 0) = 0 THEN
						CASE
							WHEN BR.RepRoleID = 'REP' THEN
								CASE
									WHEN BU.BasicFeeSum + F.FuturSumFee >= 0 AND BR.TotalLevelAdvance >= BU.BasicFeeSum + F.FuturSumFee THEN 
										F.FuturSumFee
								ELSE 
									CASE 
										WHEN BR.TotalLevelAdvance + ISNULL(E.CadException, 0) - BR.TotalCoveredAdvancePaid < 0 THEN 0.000
									ELSE BR.TotalLevelAdvance + ISNULL(E.CadException, 0) - BR.TotalCoveredAdvancePaid
									END
								END 
						ELSE ROUND(ROUND(SUM(VRL.SumCadByUnit) * BU.RealUnitQty,2) * (ISNULL(BR.RepPct, 0)/100),2) + ISNULL(E.CadException, 0) - BR.TotalCoveredAdvancePaid
						END
				ELSE BR.TotalCoveredAdvancePaid * -1
				END  
		FROM #tBasicUnitValues BU 
		JOIN #tBasicCommByRep BR ON BR.UnitID = BU.UnitID
        JOIN dbo.Un_Unit UC ON UC.UnitID = BU.UnitID
        JOIN dbo.Un_Convention C ON C.ConventionID = UC.ConventionID 
		JOIN #tRepLevelBracket3Col VRL ON VRL.RepLevelID = BR.RepLevelID AND VRL.PlanID = C.PlanID
		JOIN #tFuturSumFeeInsur F ON F.UnitID = BU.UnitID
		LEFT JOIN #tRepException E ON E.UnitID = BR.UnitID AND E.RepID = BR.RepID AND E.RepLevelID = BR.RepLevelID
		LEFT JOIN #tUnitNotComm VT ON VT.UnitID = BU.UnitID
		WHERE
			1=1
			
			and	( BU.RealUnitQty = 0 
				OR (VRL.TargetFeeByUnit <= ROUND((BU.BasicFeeSum + ISNULL(F.FuturSumFee, 0))/ BU.RealUnitQty,2))
				)
			AND BU.InForceDate >= VRL.EffectDate
			AND( VRL.TerminationDate IS NULL 
				OR BU.InForceDate <= VRL.TerminationDate
				)
		GROUP BY
			BU.UnitID,
			BU.RepID,
			BU.BasicFeeSum,
			BU.RealUnitQty,
			BR.RepLevelID,
			BR.RepPct,
			BR.RepRoleID,
			BR.RepID,
			BR.TotalCommPaid,
			BR.TotalAdvancePaid,
			BR.TotalCoveredAdvancePaid,
			BR.TotalLevelAdvance,
			F.ProjectionDate,
			F.FuturSumFee,
			F.PreviousProjectionDate,
			E.ComException,
			E.AdvException,
			E.CadException,
			VT.UnitID 

-----------------------------------------début
--		SELECT DISTINCT
--			SumComByUnit = SUM(VRL.SumComByUnit),
--			BU.RealUnitQty,
--			E.ComException,
--			BR.TotalCommPaid,
--			BU.BasicFeeSum, F.FuturSumFee,
--			BU.UnitID,
--			RepID = 
--				CASE 
--					WHEN BR.RepRoleID = 'REP' THEN BU.RepID 
--				ELSE BR.RepID
--				END,
--			BR.RepLevelID,
--			F.ProjectionDate,
--			TotalFee = BU.BasicFeeSum + F.FuturSumFee,
--			SumCom =
--				CASE  
--					WHEN ISNULL(VT.UnitID, 0) = 0 THEN 
--					/*  ici */
--						ROUND(ROUND(SUM(VRL.SumComByUnit) * BU.RealUnitQty,2) * (ISNULL(BR.RepPct, 0)/100),2) + ISNULL(E.ComException, 0)/* 0 */  - BR.TotalCommPaid /*0*/
--				ELSE 
--					CASE 
--						WHEN BR.RepRoleID = 'REP' THEN 
--							CASE 
--								WHEN ROUND(SUM(VRL.SumAdvByUnit) * BU.RealUnitQty,2) >= BU.BasicFeeSum + F.FuturSumFee THEN 
--									ROUND(ROUND(SUM(VRL.SumComByUnit) * BU.RealUnitQty,2) * (ISNULL(BR.RepPct, 0)/100),2) + ISNULL(E.ComException, 0) + F.FuturSumFee - BR.TotalCommPaid
--							ELSE 
--								ROUND((ROUND(SUM(VRL.SumComByUnit) * BU.RealUnitQty,2) + ROUND(SUM(VRL.SumAdvByUnit) * BU.RealUnitQty,2)) * (ISNULL(BR.RepPct, 0)/100),2) + ISNULL(E.ComException, 0) - BR.TotalCommPaid
--							END
--					ELSE ROUND(ROUND(SUM(VRL.SumComByUnit + VRL.SumCadByUnit) * BU.RealUnitQty,2) * (ISNULL(BR.RepPct, 0)/100),2) + ISNULL(E.ComException, 0) - BR.TotalCommPaid
--					END
--				END,
--			SumAdv = 
--				CASE  
--					WHEN ISNULL(VT.UnitID, 0) = 0 THEN
--						ROUND(ROUND(SUM(VRL.SumAdvByUnit) * BU.RealUnitQty,2) * (ISNULL(BR.RepPct, 0)/100),2) + ISNULL(E.AdvException, 0) - BR.TotalAdvancePaid
--				ELSE BR.TotalAdvancePaid * -1
--				END, 
--			SumCad = 
--				CASE 
--					WHEN ISNULL(VT.UnitID, 0) = 0 THEN
--						CASE
--							WHEN BR.RepRoleID = 'REP' THEN
--								CASE
--									WHEN BU.BasicFeeSum + F.FuturSumFee >= 0 AND BR.TotalLevelAdvance >= BU.BasicFeeSum + F.FuturSumFee THEN 
--										F.FuturSumFee
--								ELSE 
--									CASE 
--										WHEN BR.TotalLevelAdvance + ISNULL(E.CadException, 0) - BR.TotalCoveredAdvancePaid < 0 THEN 0.000
--									ELSE BR.TotalLevelAdvance + ISNULL(E.CadException, 0) - BR.TotalCoveredAdvancePaid
--									END
--								END 
--						ELSE ROUND(ROUND(SUM(VRL.SumCadByUnit) * BU.RealUnitQty,2) * (ISNULL(BR.RepPct, 0)/100),2) + ISNULL(E.CadException, 0) - BR.TotalCoveredAdvancePaid
--						END
--				ELSE BR.TotalCoveredAdvancePaid * -1
--				END  
--		FROM #tBasicUnitValues BU 
--		JOIN #tBasicCommByRep BR ON BR.UnitID = BU.UnitID
--		JOIN #tRepLevelBracket3Col VRL ON VRL.RepLevelID = BR.RepLevelID
--		JOIN #tFuturSumFeeInsur F ON F.UnitID = BU.UnitID
--		LEFT JOIN #tRepException E ON E.UnitID = BR.UnitID AND E.RepID = BR.RepID AND E.RepLevelID = BR.RepLevelID
--		LEFT JOIN #tUnitNotComm VT ON VT.UnitID = BU.UnitID
--		WHERE
--			1=1
			
--			and	( BU.RealUnitQty = 0 
--				OR (VRL.TargetFeeByUnit <= ROUND((BU.BasicFeeSum + ISNULL(F.FuturSumFee, 0))/ BU.RealUnitQty,2))
--				)
--			AND BU.InForceDate >= VRL.EffectDate
--			AND( VRL.TerminationDate IS NULL 
--				OR BU.InForceDate <= VRL.TerminationDate
--				)
--		GROUP BY
--			BU.UnitID,
--			BU.RepID,
--			BU.BasicFeeSum,
--			BU.RealUnitQty,
--			BR.RepLevelID,
--			BR.RepPct,
--			BR.RepRoleID,
--			BR.RepID,
--			BR.TotalCommPaid,
--			BR.TotalAdvancePaid,
--			BR.TotalCoveredAdvancePaid,
--			BR.TotalLevelAdvance,
--			F.ProjectionDate,
--			F.FuturSumFee,
--			F.PreviousProjectionDate,
--			E.ComException,
--			E.AdvException,
--			E.CadException,
--			VT.UnitID 

--------------------------------------fin 

	--SELECT '#tRepException',* FROM #tRepException
	--SELECT '#tRepLevelBracket3Col',* FROM #tRepLevelBracket3Col
	--SELECT '#tBasicUnitValues',* from #tBasicUnitValues
	
	---- glpi 10655
	--SELECT '#tBasicCommByRep',* FROM #tBasicCommByRep  --WHERE UnitID = 625069
	--SELECT '#tFuturCommSumByProjection',* from #tFuturCommSumByProjection --WHERE UnitID = 625069

	-- Supprime la table temporaire puisqu'on en a plus besoin
	DROP TABLE #tUnitNotComm
	DROP TABLE #tRepLevelBracket3Col
	DROP TABLE #tRepException

	-- Cette table sert a des fin de calcul pour remplir la table @CommToPayByProjection.
	CREATE TABLE #tCommSumByProjectionTmp (
		UnitID INTEGER, --Clé unique du groupe d'unité
		RepID INTEGER, --Clé unique du représentant ou directeur
		RepLevelID INTEGER, --Clé unique du niveau du représentant
		ProjectionDate DATETIME, --Date de projection de commission
		ComToPay MONEY, --Somme des commissions à payer en date de la projection de commission
		AdvToPay MONEY, --Somme des avances à payer en date de la projection de commission 
		CadToPay MONEY --Somme des avance couverte à payer en date de la projection de commission 
		PRIMARY KEY (UnitID, RepID, RepLevelID, ProjectionDate)
	)
	-- Regroupement des sommes de commission par date de projections
	INSERT INTO #tCommSumByProjectionTmp 
		SELECT 
			V.UnitID,
			V.RepID,
			V.RepLevelID,
			V.ProjectionDate,
			SumCom = MAX(V.SumCom),
			SumAdv = MAX(V.SumAdv),
			SumCad = MAX(V.SumCad)
		FROM (
			SELECT 
				UnitID,
				RepID,
				RepLevelID,
				ProjectionDate = MIN(ProjectionDate),
				SumCom,
				SumAdv = 0,
				SumCad = 0
			FROM #tFuturCommSumByProjection 
			WHERE SumCom > 0
			GROUP BY
				UnitID,
				RepID,
				RepLevelID,
				SumCom
			-----
			UNION
			-----
			SELECT 
				UnitID,
				RepID,
				RepLevelID,
				ProjectionDate = MIN(ProjectionDate),
				SumCom = 0,
				SumAdv,
				SumCad = 0
			FROM #tFuturCommSumByProjection
			WHERE SumAdv > 0
			GROUP BY
				UnitID,
				RepID,
				RepLevelID,
				SumAdv
			-----
			UNION
			-----
			SELECT 
				UnitID,
				RepID,
				RepLevelID,
				ProjectionDate = MIN(ProjectionDate),
				SumCom = 0,
				SumAdv = 0,
				SumCad
			FROM #tFuturCommSumByProjection
			WHERE SumCad > 0
			GROUP BY
				UnitID,
				RepID,
				RepLevelID,
				SumCad
			) V
		GROUP BY
			UnitID,
			RepID,
			RepLevelID,
			ProjectionDate 

	-- Cette table contient le paiements de commission, d'avance et 
	-- d'avance couverte qui doivent etre versé pour la date de projection 
	CREATE TABLE #tCommToPayByProjection (
		UnitID INTEGER, --Clé unique du groupe d'unité
		RepID INTEGER, --Clé unique du représentant ou directeur
		RepLevelID INTEGER, --Clé unique du niveau du représentant
		ProjectionDate DATETIME, --Date de projection de commission
		ComToPay MONEY, --Commissions à payer en date de la projection de commission
		AdvToPay MONEY, --Avance à payer en date de la projection de commission 
		CadToPay MONEY --Avance couverte à payer en date de la projection de commission 
		PRIMARY KEY (UnitID, RepID, RepLevelID, ProjectionDate)
	)
	-- Récupération de toute les paiements de commission dû, d'avance dû et avance couverte dû qui seront versés,ce par group d'unité,
	-- représentant ou directeur et par date de projection
	INSERT INTO #tCommToPayByProjection
		SELECT  
			V.UnitID,
			V.RepID,
			V.RepLevelID,
			V.ProjectionDate,
			V.ComToPay,
			V.AdvToPay,
			V.CadToPay
		FROM (
			SELECT
				C1.UnitID,
				C1.RepID,
				C1.RepLevelID,
				C1.ProjectionDate,
				ComToPay =
					CASE 
						WHEN C1.ComToPay = 0 THEN 0
					ELSE C1.ComToPay - MAX(ISNULL(C2.ComToPay, 0)) 
					END,
				AdvToPay =
					CASE 
						WHEN C1.AdvToPay = 0 THEN 0
					ELSE C1.AdvToPay - MAX(ISNULL(C2.AdvToPay, 0)) 
					END,
				CadToPay =
					CASE 
						WHEN C1.CadToPay = 0 THEN 0
					ELSE C1.CadToPay - MAX(ISNULL(C2.CadToPay, 0)) 
					END,
				PreviousCommToPayDate = MAX(ISNULL(C2.ProjectionDate, 0))
			FROM #tCommSumByProjectionTmp C1
			LEFT JOIN #tCommSumByProjectionTmp C2 ON C2.UnitID = C1.UnitID AND C2.RepID = C1.RepID AND C2.RepLevelID = C1.RepLevelID AND C2.ProjectionDate < C1.ProjectionDate
			GROUP BY
				C1.UnitID,
				C1.RepID,
				C1.RepLevelID,
				C1.ProjectionDate,
				C1.ComToPay,
				C1.AdvToPay,
				C1.CadToPay
			) V

	-- Libert l'espace pris par cette table puisque quel n'est plus utilisé dans le reste du traitement.
	--SELECT '#tCommToPayByProjection',* FROM #tCommToPayByProjection
	
	DROP TABLE #tCommSumByProjectionTmp

	-- Cette table contient la somme dû de boni d'affaire pour la durée de la projection 
	CREATE TABLE #tFuturBonusSumByProjection (
		UnitID INTEGER, --Clé unique du groupe d'unité
		RepID INTEGER, --Clé unique du représentant ou directeur
		RepLevelID INTEGER, --Clé unique du niveau du représentant
		InsurTypeID CHAR(3), --Type d'assurance: ISB = souscripteur, IB5 = benef capital assuré 5000$, IB1 benef capital assuré 10000$, IB2 benef capital assuré 20000$
		ProjectionDate DATETIME, --Date de projection de commission
		SumBusinessBonusAmount MONEY --Somme de Bonus dû en date de la projection de commission
		PRIMARY KEY (UnitID, RepID, RepLevelID, InsurTypeID, ProjectionDate)
	)
	-- Regroupement des sommes de boni d'affaire par date de projections
	INSERT INTO #tFuturBonusSumByProjection
		SELECT  
			UnitID,
			RepID,
			RepLevelID,
			InsurTypeID,
			ProjectionDate,
			BusinessBonusAmount
		FROM (
			SELECT
				BU.UnitID,
				BR.RepID,
				BR.RepLevelID,
				RBB.InsurTypeID, 
				F.ProjectionDate,
				BusinessBonusAmount = 
					CASE 
						WHEN ROUND(BU.RealUnitQty * BU.SubscInsurRate, 2) * BU.PmtByYearID = 0 THEN 
							ISNULL(RBBE.RepExceptionAmount,0) - BR.ISBBusinessBonusPaid
					ELSE 
						CASE  
							WHEN FLOOR((F.FuturSumSubscInsur + BU.SubscInsurSum) / (ROUND(BU.RealUnitQty * BU.SubscInsurRate, 2) * BU.PmtByYearID)) <= RBB.BusinessBonusNbrOfYears THEN
								CASE 
									WHEN FLOOR((F.FuturSumSubscInsur + BU.SubscInsurSum) / (ROUND(BU.RealUnitQty * BU.SubscInsurRate, 2) * BU.PmtByYearID)) > 0 THEN 
										(FLOOR((F.FuturSumSubscInsur + BU.SubscInsurSum) / (ROUND(BU.RealUnitQty * BU.SubscInsurRate, 2) * BU.PmtByYearID)) * ROUND(RBB.BusinessBonusByUnit * BU.RealUnitQty,2)) - BR.ISBBusinessBonusPaid + ISNULL(RBBE.RepExceptionAmount,0)
								ELSE 0
								END
						ELSE (RBB.BusinessBonusNbrOfYears * ROUND((BU.RealUnitQty * RBB.BusinessBonusByUnit),2)) - BR.ISBBusinessBonusPaid + ISNULL(RBBE.RepExceptionAmount,0)
						END
					END
			FROM #tBasicUnitValues BU 
			JOIN #tFuturSumFeeInsur F ON F.UnitID = BU.UnitID
			JOIN (
				SELECT 
					V.UnitID,
					V.RepLevelID,
					V.RepPct,
					BR.RepID,
					BR.ISBBusinessBonusPaid,
					BR.RepRoleID
				FROM (
					SELECT 
						UnitID,
						RepLevelID,
						RepPct = MAX(RepPct)
					FROM #tBasicCommByRep
					WHERE RepRoleID <> 'REP'-- AND RepRoleID <> 'CND'
					GROUP BY
						UnitID,
						RepLevelID
					) V 
				JOIN #tBasicCommByRep BR ON BR.UnitID = V.UnitID AND BR.RepLevelID = V.RepLevelID AND BR.RepPct = V.RepPct
				-----
				UNION 
				-----
				SELECT 
					UnitID,
					RepLevelID,
					RepPct,
					RepID,
					ISBBusinessBonusPaid,
					RepRoleID
				FROM #tBasicCommByRep
				WHERE RepRoleID = 'REP'
				) BR ON BR.UnitID = BU.UnitID
			JOIN Un_Rep R ON R.RepID = BR.RepID --AND (R.BusinessEnd IS NULL OR R.BusinessEnd >= F.ProjectionDate) --Elimine les rep non actif
			JOIN Un_RepBusinessBonusCfg RBB ON RBB.RepRoleID = BR.RepRoleID AND RBB.InsurTypeID = 'ISB' AND (RBB.StartDate <= BU.InForceDate) AND (RBB.EndDate IS NULL OR (RBB.EndDate >= BU.InForceDate)) 
			LEFT JOIN (
				SELECT 
					RE.RepID,
					RE.UnitID,
					RE.RepLevelID,
					RepExceptionAmount = SUM(RE.RepExceptionAmount)
				FROM Un_RepException RE         
				JOIN Un_RepExceptionType RET ON RET.RepExceptionTypeID = RE.RepExceptionTypeID
				WHERE RET.RepExceptionTypeTypeID = 'ISB'
					AND RE.RepExceptionDate <= @dtLastTreatmentDate
				GROUP BY
					RE.RepID,
					RE.UnitID,
					RE.RepLevelID
				) RBBE ON RBBE.UnitID = BU.UnitID AND RBBE.RepID = BR.RepID AND RBBE.RepLevelID = BR.RepLevelID
			WHERE (BU.WantSubscInsur <> 0)
				AND (BU.BusinessBonusToPay <> 0)
			) VV
		WHERE BusinessBonusAmount <> 0
		-----
		UNION
		-----
		-- Boni sur l'assurance bénéficiaire
		SELECT  
			UnitID,
			RepID,
			RepLevelID,
			InsurTypeID,
			ProjectionDate,
			BusinessBonusAmount
		FROM (
			SELECT
				BU.UnitID,
				BR.RepID,
				BR.RepLevelID,
				RBB.InsurTypeID,
				F.ProjectionDate,
				BusinessBonusAmount =
					CASE 
						WHEN RBB.InsurTypeID = 'IB1' THEN
							CASE 
								WHEN BU.PmtByYearID * BU.BenefInsurRate = 0 THEN
									ISNULL(RBBE.RepExceptionAmount,0) - BR.IB1BusinessBonusPaid
							ELSE 
								CASE  
									WHEN FLOOR((F.FuturSumBenefInsur + BU.BenefInsurSum) / (BU.PmtByYearID * BU.BenefInsurRate)) <= RBB.BusinessBonusNbrOfYears THEN
										CASE 
											WHEN FLOOR((F.FuturSumBenefInsur + BU.BenefInsurSum) / (BU.PmtByYearID * BU.BenefInsurRate)) > 0 THEN 
												(FLOOR((F.FuturSumBenefInsur + BU.BenefInsurSum) / (BU.PmtByYearID * BU.BenefInsurRate)) * RBB.BusinessBonusByUnit) - BR.IB1BusinessBonusPaid + ISNULL(RBBE.RepExceptionAmount,0)
										ELSE 0
										END
								ELSE (RBB.BusinessBonusNbrOfYears * RBB.BusinessBonusByUnit) - BR.IB1BusinessBonusPaid + ISNULL(RBBE.RepExceptionAmount,0)
								END 
							END
					ELSE 
						CASE 
							WHEN BU.PmtByYearID * BU.BenefInsurRate = 0 THEN
								ISNULL(RBBE.RepExceptionAmount,0) - BR.IB2BusinessBonusPaid
						ELSE
							CASE
								WHEN FLOOR((F.FuturSumBenefInsur + BU.BenefInsurSum) / (BU.PmtByYearID * BU.BenefInsurRate)) <= RBB.BusinessBonusNbrOfYears THEN
									CASE
										WHEN FLOOR((F.FuturSumBenefInsur + BU.BenefInsurSum) / (BU.PmtByYearID * BU.BenefInsurRate)) > 0 THEN
											(FLOOR((F.FuturSumBenefInsur + BU.BenefInsurSum) / (BU.PmtByYearID * BU.BenefInsurRate)) * RBB.BusinessBonusByUnit) - BR.IB2BusinessBonusPaid + ISNULL(RBBE.RepExceptionAmount,0)
									ELSE 0
									END
							ELSE (RBB.BusinessBonusNbrOfYears * RBB.BusinessBonusByUnit) - BR.IB2BusinessBonusPaid + ISNULL(RBBE.RepExceptionAmount,0)
							END
						END
					END
			FROM #tBasicUnitValues BU 
			JOIN #tFuturSumFeeInsur F ON F.UnitID = BU.UnitID
			JOIN (
				SELECT 
					V.UnitID,
					V.RepLevelID,
					V.RepPct,
					BR.RepID,
					BR.IB1BusinessBonusPaid,
					BR.IB2BusinessBonusPaid,
					BR.RepRoleID
				FROM (
					SELECT 
						UnitID,
						RepLevelID,
						RepPct = MAX(RepPct)
					FROM #tBasicCommByRep
					WHERE RepRoleID <> 'REP'-- AND RepRoleID <> 'CND'
					GROUP BY
						UnitID,
						RepLevelID
					) V 
				JOIN #tBasicCommByRep BR ON BR.UnitID = V.UnitID AND BR.RepLevelID = V.RepLevelID AND BR.RepPct = V.RepPct
				-----
				UNION
				----- 
				SELECT 
					UnitID,
					RepLevelID,
					RepPct,
					RepID,
					IB1BusinessBonusPaid,
					IB2BusinessBonusPaid,
					RepRoleID
				FROM #tBasicCommByRep
				WHERE RepRoleID = 'REP'
			) BR ON BR.UnitID = BU.UnitID
		JOIN Un_Rep R ON R.RepID = BR.RepID --AND (R.BusinessEnd IS NULL OR (R.BusinessEnd >= F.ProjectionDate)) --Elimine les rep non actif
		LEFT JOIN Un_RepBusinessBonusCfg RBB ON (RBB.RepRoleID = BR.RepRoleID AND (RBB.StartDate <= BU.InForceDate) AND (RBB.EndDate IS NULL OR (RBB.EndDate >= BU.InForceDate)) AND ((RBB.InsurTypeID = 'IB1' AND BU.BenefInsurFaceValue = 10000) OR (RBB.InsurTypeID = 'IB2' AND BU.BenefInsurFaceValue = 20000)))
		LEFT JOIN (
			SELECT 
				RE.RepID,
				RE.UnitID,
				RE.RepLevelID,
				RET.RepExceptionTypeTypeID,
				RepExceptionAmount = SUM(RE.RepExceptionAmount)
			FROM Un_RepException RE         
			JOIN Un_RepExceptionType RET ON RET.RepExceptionTypeID = RE.RepExceptionTypeID
			WHERE RET.RepExceptionTypeTypeID IN ('IB1','IB2')
				AND RE.RepExceptionDate <= @dtLastTreatmentDate
			GROUP BY
				RE.RepID,
				RE.UnitID,
				RE.RepLevelID,
				RET.RepExceptionTypeTypeID
			) RBBE ON RBBE.UnitID = BU.UnitID AND RBBE.RepID = BR.RepID AND RBBE.RepLevelID = BR.RepLevelID AND RBB.InsurTypeID = RBBE.RepExceptionTypeTypeID 
		WHERE BU.BenefInsurFaceValue IN (10000, 20000)
			AND (BU.BusinessBonusToPay <> 0)
		) VV
	WHERE BusinessBonusAmount <> 0
	ORDER BY
		UnitID,
		RepID,
		RepLevelID,
		ProjectionDate

	-- Cette table contient le paiements de boni d'affaire qui doivent etre versé pour la date de projection 
	CREATE TABLE #tBusinessBonusToPay (
		UnitID INTEGER, --Clé unique du groupe d'unité
		RepID INTEGER, --Clé unique du représentant ou directeur
		RepLevelID INTEGER, --Clé unique du niveau du représentant
		ProjectionDate DATETIME, --Date de projection de commission
		BusinessBonusAmount MONEY, --Bonus à payer en date de la projection de commission
		InsurTypeID CHAR(3) --Type d'assurance: ISB = souscripteur, IB5 = benef capital assuré 5000$, IB1 benef capital assuré 10000$, IB2 benef capital assuré 20000$
		PRIMARY KEY (UnitID, RepID, RepLevelID, ProjectionDate, InsurTypeID)
	)
	-- Regroupement des sommes à payer de boni d'affaire pour la date de projections
	INSERT INTO #tBusinessBonusToPay
		SELECT  
			UnitID,
			RepID,
			RepLevelID,
			ProjectionDate,
			BusinessBonusAmountToPay = SumBusinessBonusAmount,
			InsurTypeID
		FROM (
			SELECT
				F1.UnitID,
				F1.RepID,
				F1.RepLevelID,
				F1.ProjectionDate,
				F1.InsurTypeID,
				SumBusinessBonusAmount =
					CASE 
						WHEN F1.SumBusinessBonusAmount = 0 THEN 0
					ELSE F1.SumBusinessBonusAmount - MAX(ISNULL(F2.SumBusinessBonusAmount, 0)) 
					END,
				PreviousCommToPayDate = MAX(ISNULL(F2.ProjectionDate, 0))
			FROM #tFuturBonusSumByProjection F1
			LEFT JOIN #tFuturBonusSumByProjection F2 ON F2.UnitID = F1.UnitID AND F2.RepID = F1.RepID AND F2.RepLevelID = F1.RepLevelID AND F2.InsurTypeID = F1.InsurTypeID AND (F2.ProjectionDate < F1.ProjectionDate)
			GROUP BY
				F1.UnitID,
				F1.RepID,
				F1.RepLevelID,
				F1.ProjectionDate,
				F1.InsurTypeID,
				F1.SumBusinessBonusAmount
			) V
		WHERE SumBusinessBonusAmount <> 0

	--SELECT '#tCommToPayByProjection',* from #tCommToPayByProjection
	--return

	-- Cette table contient les montants de commissions, d'avance et de boni d'affaire de base à 
	-- des fin de calcul pour ajouter les montants d'avance spécial et les montant d'exception  
	CREATE TABLE #tBasicCommAndBonusInfoForPeriod (
		UnitID INTEGER, --Clé unique du groupe d'unité
		RepID INTEGER, --Clé unique du représentant ou directeur,
		RepLevelID INTEGER, --Clé unique du niveau du représentant,
		ProjectionDate DATETIME, --Date de projection de commission,
		CoverdAdvance MONEY, --Montant d'avance couverte pour la période de la projection 
		ServiceComm MONEY, --Montant de commission de service (ceci est le total de commision à recevoir pour le niveau du représentant)
		PeriodComm MONEY, --Montant de commission de la période de projection
		CumComm MONEY, --Montant cumulé de commission jusqu'à la  période de projection
		FuturComm MONEY, --Montant future de commission à venir pour les prochaine période de projection ou traitement de commission
		PeriodBusinessBonus MONEY, --Montant de boni d'affaire pour la période de projection 
		CumBusinessBonus MONEY, --Montant cumulé de boni d'affaire jusqu'à la  période de projection
		FuturBusinessBonus MONEY --Montant future de boni d'affaire à venir pour les prochaine période de projection ou traitement de commission
		PRIMARY KEY (UnitID, RepID, RepLevelID, ProjectionDate)
	)
	-- Regroupement de toutes les montant de commissions, d'avance et de boni d'affaire par groupe d'unité, 
	-- représentant, niveau du représentant et de date de projection
	INSERT INTO #tBasicCommAndBonusInfoForPeriod
		SELECT DISTINCT
			BR.UnitID,
			BR.RepID,
			BR.RepLevelID,
			BR.ProjectionDate,
			CoverdAdvance = ISNULL(CP.CadToPay, 0),
			ServiceComm = ROUND(BR.TotalLevelCommission * (BR.RepPct/100),2) + ISNULL(E.ComException, 0),
			PeriodComm = ISNULL(CP.ComToPay, 0),
			CumComm = BR.TotalCommPaid + ISNULL(FC.SumCom, 0),
			FuturComm = ROUND(BR.TotalLevelCommission * (BR.RepPct/100),2) + ISNULL(E.ComException, 0) - (BR.TotalCommPaid + ISNULL(FC.SumCom, 0)),
			PeriodBusinessBonus = ISNULL(BP.CumBusinessBonusAmount, 0),
			CumBusinessBonus = BR.ISBBusinessBonusPaid + BR.IB5BusinessBonusPaid + BR.IB1BusinessBonusPaid + BR.IB2BusinessBonusPaid + ISNULL(FB.SumBusinessBonusAmount, 0),
			FuturBusinessBonus =
				CASE 
					WHEN R.BusinessEnd IS NULL OR (R.BusinessEnd > BR.ProjectionDate) THEN
						BR.TotalBusinessBonus + ISNULL(E.BonusException, 0) - (BR.ISBBusinessBonusPaid + BR.IB5BusinessBonusPaid + BR.IB1BusinessBonusPaid + BR.IB2BusinessBonusPaid + ISNULL(FB.SumBusinessBonusAmount, 0))
				ELSE 0.00
				END
		FROM (
			SELECT 
				ProjectionDate,
				UnitID, 
				RepID,
				RepLevelID,
				RepPct,
				TotalLevelCommission,
				TotalCommPaid,
				TotalBusinessBonus,
				ISBBusinessBonusPaid,
				IB5BusinessBonusPaid,
				IB1BusinessBonusPaid,
				IB2BusinessBonusPaid   
			FROM #tProjectionDate, #tBasicCommByRep
			) BR   
		JOIN Un_Rep R ON R.RepID = BR.RepID
		LEFT JOIN #tCommToPayByProjection CP ON CP.UnitID = BR.UnitID AND CP.RepID = BR.RepID AND CP.RepLevelID = BR.RepLevelID AND CP.ProjectionDate = BR.ProjectionDate
		LEFT JOIN #tFuturCommSumByProjection FC ON FC.UnitID = BR.UnitID AND FC.RepID = BR.RepID AND FC.RepLevelID = BR.RepLevelID AND FC.ProjectionDate = BR.ProjectionDate
		LEFT JOIN (
			SELECT 
				ProjectionDate,
				UnitID, 
				RepID,
				RepLevelID,
				CumBusinessBonusAmount = SUM(BusinessBonusAmount)
			FROM #tBusinessBonusToPay 
			GROUP BY
				ProjectionDate,
				UnitID,
				RepID,
				RepLevelID
			) BP ON BP.UnitID = BR.UnitID AND BP.RepID = BR.RepID AND BP.RepLevelID = BR.RepLevelID AND BP.ProjectionDate = BR.ProjectionDate
		LEFT JOIN (
			SELECT 
				UnitID,
				RepID,
				RepLevelID,
				ProjectionDate,
				SumBusinessBonusAmount = SUM(SumBusinessBonusAmount)
			FROM #tFuturBonusSumByProjection
			GROUP BY
				UnitID,
				RepID,
				RepLevelID,
				ProjectionDate
			) FB ON FB.UnitID = BR.UnitID AND FB.RepID = BR.RepID AND FB.RepLevelID = BR.RepLevelID AND FB.ProjectionDate = BR.ProjectionDate
		LEFT JOIN (
			SELECT 
				V.ProjectionDate,
				V.UnitID,
				V.RepID,
				V.RepLevelID,
				ComException = SUM(V.ComException),
				BonusException = SUM(V.ISBException + V.IBException)
			FROM (
				SELECT 
					BR.ProjectionDate,
					BR.UnitID,
					BR.RepID,
					BR.RepLevelID,
					ComException = 
						CASE ET.RepExceptionTypeTypeID
							WHEN 'COM' THEN SUM(E.RepExceptionAmount) 
						ELSE 0
						END,
					ISBException = 
						CASE ET.RepExceptionTypeTypeID
							WHEN 'ISB' THEN SUM(E.RepExceptionAmount) 
						ELSE 0
						END,
					IBException =
						CASE 
							WHEN ET.RepExceptionTypeTypeID = 'IB1' OR ET.RepExceptionTypeTypeID = 'IB2' THEN SUM(E.RepExceptionAmount) 
						ELSE 0
						END
				FROM (
					SELECT 
						ProjectionDate,
						UnitID,
						RepID,
						RepLevelID
					FROM #tProjectionDate, #tBasicCommByRep
					) BR
				JOIN Un_RepException E ON E.UnitID = BR.UnitID AND E.RepID = BR.RepID AND E.RepLevelID = BR.RepLevelID AND (E.RepExceptionDate <= BR.ProjectionDate)
				JOIN Un_RepExceptionType ET ON ET.RepExceptionTypeID = E.RepExceptionTypeID
				GROUP BY
					BR.ProjectionDate,
					BR.UnitID,
					BR.RepID,
					BR.RepLevelID,
					ET.RepExceptionTypeTypeID
				) V
			GROUP BY
				V.ProjectionDate,
				V.UnitID,
				V.RepID,
				V.RepLevelID 
			) E ON E.UnitID = BR.UnitID AND E.RepID = BR.RepID AND E.RepLevelID = BR.RepLevelID AND E.ProjectionDate = BR.ProjectionDate

	-- Libert l'espace pris par ces tables puisque qu'elles ne sont plus utilisées dans le reste du traitement.
	DROP TABLE #tCommToPayByProjection
	DROP TABLE #tFuturBonusSumByProjection
	DROP TABLE #tBusinessBonusToPay  

	-- Cette table contient les somme de commissions, d'avance d'avance couverte, montant d'avance 
	-- de résiliation et avance spécial ce par représentant et date de projection servant à
	-- des fin de calcul pour déterminer les montants à charger  
	CREATE TABLE #tRepRESAndSpecialAdv (
		RepID INTEGER, --Clé unique du représentant ou directeur,
		ProjectionDate DATETIME, --Date de projection de commission,
		SumCom MONEY, --Somme des commisions d'un représentant incluant toutes les rôles pour une projection
		SumAdv MONEY, --Somme des avances d'un représentant incluant toutes les rôles pour une projection
		SumCad MONEY, --Somme des commisions d'un représentant incluant toutes les rôles pour une projection
		RESAmount MONEY, --Somme des montants d'avance sur résiliation d'unités entre la dernière projection et celle actuelle
		AVRAmount MONEY, --Somme total des montant d'avance sur résiliation d'unités avant la projection actuelle
		AVSAmount MONEY, --Somme d'avance spéciale avant la projection actuelle
		CumADV MONEY, --Montant total d'avances données au représentant 
		CumCAD MONEY, --Montant total d'avances couvertes du représentant 
		FuturComm MONEY --Montant total des commissions à venir du représentant 
		PRIMARY KEY (RepID, ProjectionDate)
	)
	-- Regroupement des sommes pour les calcul des charge au représentant et avance spécial
	INSERT INTO #tRepRESAndSpecialAdv
		SELECT 
			R.RepID,
			R.ProjectionDate,
			R.SumCom,
			R.SumAdv,
			R.SumCad,
			RESAmount = 0,
			AVRAmount = ISNULL(RS.AVRAmount, 0),
			AVSAmount = ISNULL(RS.AVSAmount, 0),
			CumADV = R.SumAdv + ISNULL(BR.TotalAdvancePaid,0),
			CumCAD = R.SumCad + ISNULL(BR.TotalCoveredAdvancePaid,0),
			FuturComm = ISNULL(F.FuturComm,0)
		FROM (
			SELECT 
				FC.RepID,
				FC.ProjectionDate,
				SumCom = SUM(FC.SumCom),
				SumAdv = SUM(FC.SumAdv),
				SumCad = SUM(FC.SumCad)
			FROM #tFuturCommSumByProjection FC
			JOIN Un_RepLevel L ON L.RepLevelID = FC.RepLevelID
			GROUP BY
				FC.RepID,
				FC.ProjectionDate
			) R  
		LEFT JOIN (
			SELECT 
				RepID,
				TotalAdvancePaid = SUM(TotalAdvancePaid),
				TotalCoveredAdvancePaid = SUM(TotalCoveredAdvancePaid)
			FROM #tBasicCommByRep 
			GROUP BY RepID
			) BR ON BR.RepID = R.RepID
		LEFT JOIN (
			SELECT 
				RepID,
				ProjectionDate,
				FuturComm = SUM(FuturComm)
			FROM #tBasicCommAndBonusInfoForPeriod   
			GROUP BY
				RepID,
				ProjectionDate
			) F ON F.RepID = R.RepID AND F.ProjectionDate = R.ProjectionDate
		LEFT JOIN ( 
			SELECT 
				RepID,
				ProjectionDate,
				AVRAmount = SUM(AVRAmount),
				AVSAmount = SUM(AVSAmount)
			FROM (
				SELECT 
					RC.RepID,
					P.ProjectionDate,
					RESAmount = 0,
					AVRAmount = SUM(RepChargeAmount),
					AVSAmount = 0
				FROM #tProjectionDate P
				JOIN Un_RepCharge RC ON RC.RepChargeDate <= P.ProjectionDate
				WHERE RepChargeTypeID = 'AVR'  
				GROUP BY
					RepID,
					P.ProjectionDate
				---------
				UNION ALL
				---------
				SELECT 
					SA.RepID,
					P.ProjectionDate,
					RESAmount = 0,
					AVRAmount = 0,
					AVSAmount = SUM(SA.Amount)
				FROM #tProjectionDate P
				JOIN Un_SpecialAdvance SA ON SA.EffectDate <= P.ProjectionDate
				GROUP BY
					RepID,
					P.ProjectionDate
				) V
			GROUP BY
				RepID,
				ProjectionDate
			) RS ON RS.RepID = R.RepID AND RS.ProjectionDate = R.ProjectionDate
		ORDER BY
			R.RepID,
			R.ProjectionDate

	-- Cette table contient les somme de charge pour chaque projection   
	CREATE TABLE #tProjectionRepChargeSum (
		RepID INTEGER, --Clé unique du représentant ou directeur,
		RepChargeDate DATETIME, --Date de projection sur les charge,
		RepChargeTypeID CHAR(3), --Type de charge (AVR = Abvance sur résiliation, AVS = Avance spécial) 
		RepChargeAmountSum MONEY --Somme des charge
		PRIMARY KEY (RepID, RepChargeDate, RepChargeTypeID)
	)
	-- Regroupement des sommes de charge pour le représentant par date de projection (Avance sur 
	-- résiliation et avance spéciale)
	-- Dans ce cas on utilise une boucle qui traite une projection après l'autre car faut 
	-- connaître les avances spéciales remboursées lors de la projection précédente pour 
	-- calculer le pourcentage de commissions qui sert a déterminer si on doit utiliser les 
	-- commissions de service pour rembourser les avances faites par Universitas.
	INSERT INTO #tProjectionRepChargeSum
		SELECT 
			V.RepID,
			V.RepChargeDate,
			V.RepChargeTypeID,
			RepChargeAmountSum = SUM(V.RepChargeAmountSum)
		FROM (
			SELECT 
				V.RepID,
				RepChargeDate = V.ProjectionDate,
				V.RepChargeTypeID,
				RepChargeAmountSum = V.Amount
			FROM (
				SELECT 
					S.RepID,
					S.ProjectionDate,
					RepChargeTypeID = 'AVR',
					Amount = 
						CASE 
							WHEN S.SumCom > 0 THEN
								CASE 
									WHEN RR.AVRAmount = 0 THEN 0
								ELSE
									CASE 
										WHEN S.SumCom < RR.AVRAmount THEN
											S.SumCom * -1
									ELSE
										RR.AVRAmount * -1
									END
								END 
						ELSE 0
						END
				FROM (        
					SELECT                                
						FC.RepID,
						FC.ProjectionDate,
						SumCom = SUM(FC.SumCom)
					FROM #tFuturCommSumByProjection FC
					JOIN Un_RepLevel RL ON RL.RepLevelID = FC.RepLevelID AND RL.RepRoleID = 'REP'
					GROUP BY
						FC.ProjectionDate,
						FC.RepID
					) S
				JOIN #tRepRESAndSpecialAdv RR ON RR.RepID = S.RepID AND RR.ProjectionDate = S.ProjectionDate 
				) V
			WHERE V.Amount <> 0
			) V
		GROUP BY
			V.RepID,
			V.RepChargeDate,
			V.RepChargeTypeID

	-- Cette table contient les projection sur les Charge   
	CREATE TABLE #tProjectionRepCharge (
		RepID INTEGER, --Clé unique du représentant ou directeur,
		RepChargeDate DATETIME, --Date de projection sur les charge,
		RepChargeTypeID CHAR(3), --Type de charge (AVR = Abvance sur résiliation, AVS = Avance spécial) 
		RepChargeAmount MONEY --Montant de charge pour chaque projection de commission 
		PRIMARY KEY (RepID, RepChargeDate, RepChargeTypeID)
	)
	-- Regroupement des montant de charge pour le représentant par date de projection (Avance sur 
	-- résiliation et avance spéciale)
	INSERT INTO #tProjectionRepCharge
		SELECT 
			S1.RepID,
			S1.RepChargeDate,
			S1.RepChargeTypeID,
			RepChargeAmount = S1.RepChargeAmountSum - ISNULL(S3.RepChargeAmountSum, 0)
		FROM #tProjectionRepChargeSum S1
		LEFT JOIN (
			SELECT 
				S1.RepID,
				S1.RepChargeDate,
				S1.RepChargeTypeID,
				PreviousRepChargeDate = MAX(S2.RepChargeDate)
			FROM #tProjectionRepChargeSum S1
			JOIN #tProjectionRepChargeSum S2 ON S2.RepID = S1.RepID AND S2.RepChargeTypeID = S1.RepChargeTypeID AND S2.RepchargeDate < S1.RepChargeDate
			GROUP BY
				S1.RepID,
				S1.RepChargeDate,
				S1.RepChargeTypeID
			) S2 ON S2.RepID = S1.RepID AND S2.RepChargeTypeID = S1.RepChargeTypeID AND S2.RepChargeDate = S1.RepChargeDate
		LEFT JOIN #tProjectionRepChargeSum S3 ON S3.RepID = S2.RepID AND S3.RepChargeTypeID = S2.RepChargeTypeID AND S3.RepChargeDate = S2.PreviousRepChargeDate
		WHERE S1.RepChargeAmountSum - ISNULL(S3.RepChargeAmountSum, 0) <> 0

	-- Inseretion dans la table Un_RepProjection 
	INSERT INTO Un_RepProjection
		SELECT 
			RepProjectionDate = BCB.ProjectionDate,
			BCB.RepID,
			BCB.RepLevelID,
			BU.ConventionID,
			BU.FirstDepositDate,
			BU.InForceDate,
			BU.SubscriberName,
			BU.ConventionNo,
			BR.RepName,
			BR.RepCode,
			BR.RepLicenseNo,
			BR.RepRoleDesc,
			BR.RepLevelShortDesc,
			UnitQty = BU.RealUnitQty,
			TotalFee = BU.BasicFeeSum + ISNULL(FF.FuturSumFee,0),
			BCB.CoverdAdvance,
			BCB.ServiceComm,
			BCB.PeriodComm,
			BCB.CumComm,
			ServiceBusinessBonus =
				CASE 
					WHEN R.BusinessEnd IS NULL OR (R.BusinessEnd > BCB.ProjectionDate) THEN BR.TotalBusinessBonus 
				ELSE BCB.CumBusinessBonus
				END, 
			BCB.PeriodBusinessBonus,
			BCB.CumBusinessBonus,
			PaidAmount = BCB.PeriodComm + BCB.PeriodBusinessBonus,
			CommExpenses = BCB.PeriodComm + BCB.PeriodBusinessBonus + BCB.CoverdAdvance,
            BCB.UnitID --2018-05-25
		FROM #tBasicCommAndBonusInfoForPeriod BCB
		JOIN Un_Rep R ON R.RepID = BCB.RepID
		JOIN #tBasicUnitValues BU ON BU.UnitID = BCB.UnitID
		JOIN #tBasicCommByRep BR ON BR.UnitID = BCB.UnitID AND BR.RepID = BCB.RepID AND BR.RepLevelID = BCB.RepLevelID
		LEFT JOIN #tFuturSumFeeInsur FF ON FF.UnitID = BCB.UnitID AND FF.ProjectionDate = BCB.ProjectionDate
		WHERE	(BCB.CoverdAdvance <> 0)
			OR	( (BCB.ServiceComm <> 0)
				AND (BCB.ServiceComm <> BCB.CumComm)
				)
			OR (BCB.PeriodComm <> 0)
			OR (
					( R.BusinessEnd IS NULL 
					OR (R.BusinessEnd > BCB.ProjectionDate)
					) 
					
				AND (BR.TotalBusinessBonus <> 0) 
				AND (BR.TotalBusinessBonus <> BCB.CumBusinessBonus)
				)
			OR (BCB.PeriodBusinessBonus <> 0)
     ORDER BY
			BCB.ProjectionDate,
			BCB.RepID,
			BCB.RepLevelID

	-- Libert l'espace pris par ces tables puisque qu'elles ne sont plus utilisées dans le reste du traitement.
	DROP TABLE #tFuturSumFeeInsur
	DROP TABLE #tBasicUnitValues

	-- Inseretion dans la table Un_RepProjectionSumary du sommaire des projection des commissions
	INSERT INTO Un_RepProjectionSumary
		SELECT 
			R.RepProjectionDate,
			R.RepID,
			R.RepName,
			R.RepCode,
			PeriodCommBonus = ISNULL(V1.PeriodCommBonus, 0),
			YearCommBonus = ISNULL(V3.YearCommBonus, 0),
			PeriodCoveredAdvance = ISNULL(V1.PeriodCoveredAdvance, 0),
			YearCoveredAdvance = ISNULL(V3.YearCoveredAdvance, 0),
			AVSAmount = ISNULL(V2.AVSAmount, 0),
			AVRAmount = ISNULL(V2.AVRAmount, 0),
			AdvanceSolde = ISNULL(V4.AdvanceSolde, 0),
			AVSAmountSolde = ISNULL(V5.AVSAmountSolde, 0),
			AVRAmountSolde = ISNULL(V5.AVRAmountSolde, 0)
		FROM (
			SELECT DISTINCT 
				RepProjectionDate = ProjectionDate,
				RepID 
				RepID,
				RepName,
				RepCode
			FROM #tBasicCommByRep, #tProjectionDate
			) R    
		LEFT JOIN (
			SELECT  
				RepProjectionDate = ProjectionDate,
				RepID, 
				PeriodCommBonus = SUM(PeriodComm + PeriodBusinessBonus),
				PeriodCoveredAdvance = SUM(CoverdAdvance)
			FROM #tBasicCommAndBonusInfoForPeriod 
			GROUP BY
				ProjectionDate,
				RepID   
			) V1 ON V1.RepProjectionDate = R.RepProjectionDate AND V1.RepID = R.RepID
		LEFT JOIN (
			SELECT 
				RepProjectionDate = RepChargeDate,
				RepID,
				AVSAmount =
					SUM(
						CASE RepChargeTypeID
							WHEN 'AVS' THEN RepChargeAmount 
						ELSE 0
						END),
				AVRAmount = 
					SUM(
						CASE RepChargeTypeID
							WHEN 'AVR' THEN RepChargeAmount 
						ELSE 0
						END)
			FROM #tProjectionRepCharge
			GROUP BY
				RepChargeDate,
				RepID   
			) V2 ON V2.RepProjectionDate = R.RepProjectionDate AND V2.RepID = R.RepID
		LEFT JOIN (
			SELECT  
				RepProjectionDate = BCB1.ProjectionDate,
				BCB1.RepID, 
				YearCommBonus = SUM(BCB2.PeriodComm + BCB2.PeriodBusinessBonus),
				YearCoveredAdvance = SUM(BCB2.CoverdAdvance)
			FROM #tBasicCommAndBonusInfoForPeriod BCB1
			JOIN #tBasicCommAndBonusInfoForPeriod BCB2 ON BCB2.UnitID = BCB1.UnitID AND BCB2.RepID = BCB1.RepID AND BCB2.RepLevelID = BCB1.RepLevelID AND (BCB2.ProjectionDate <= BCB1.ProjectionDate) AND YEAR(BCB2.ProjectionDate) = YEAR(BCB1.ProjectionDate)
			GROUP BY
				BCB1.ProjectionDate,
				BCB1.RepID   
			) V3 ON V3.RepProjectionDate = R.RepProjectionDate AND V3.RepID = R.RepID
		LEFT JOIN (
			SELECT 
				BR.RepID,
				P.ProjectionDate, 
				AdvanceSolde = SUM(ISNULL(F.SumAdv,0) + BR.TotalAdvancePaid - (ISNULL(F.SumCad,0) + BR.TotalCoveredAdvancePaid))
			FROM #tBasicCommByRep BR
			JOIN #tProjectionDate P ON P.ProjectionDate = P.ProjectionDate
			LEFT JOIN #tFuturCommSumByProjection F ON BR.UnitID = F.UnitID AND BR.RepID = F.RepID AND BR.RepLevelID = F.RepLevelID AND P.ProjectionDate = F.ProjectionDate
			GROUP BY
				BR.RepID,
				P.ProjectionDate      
			HAVING SUM(ISNULL(F.SumAdv,0) + BR.TotalAdvancePaid - (ISNULL(F.SumCad,0) + BR.TotalCoveredAdvancePaid)) <> 0
			) V4 ON V4.RepID = R.RepID AND V4.ProjectionDate = R.RepProjectionDate   
		LEFT JOIN ( 
			SELECT 
				RRS.RepID,
				RRS.ProjectionDate,
				AVSAmountSolde = 
					SUM(
						CASE ISNULL(RCS.RepChargeTypeID, '') 
							WHEN 'AVS' THEN ISNULL(RCS.RepChargeAmountSum, 0) 
						ELSE 0 
						END) + RRS.AVSAmount,
				AVRAmountSolde = 
					SUM(
						CASE ISNULL(RCS.RepChargeTypeID, '') 
							WHEN 'AVR' THEN ISNULL(RCS.RepChargeAmountSum, 0) 
						ELSE 0 
						END) + RRS.AVRAmount
			FROM #tRepRESAndSpecialAdv RRS
			LEFT JOIN #tProjectionRepChargeSum RCS ON RRS.RepID = RCS.RepID AND RRS.ProjectionDate = RCS.RepChargeDate
			GROUP BY
				RRS.RepID,
				RRS.ProjectionDate,
				RRS.AVSAmount,
				RRS.AVRAmount
			) V5 ON V5.RepID = R.RepID AND V5.ProjectionDate = R.RepProjectionDate
		LEFT JOIN (
			SELECT DISTINCT 
				RepID,
				YearProjection = YEAR(RepProjectionDate)
			FROM Un_RepProjection
			) V6 ON V6.RepID = R.RepID AND V6.YearProjection = YEAR(R.RepProjectionDate)
		WHERE (ISNULL(V1.PeriodCommBonus,0) <> 0)
			OR (ISNULL(V3.YearCommBonus, 0) <> 0)
			OR (ISNULL(V1.PeriodCoveredAdvance, 0) <> 0)
			OR (ISNULL(V3.YearCoveredAdvance, 0) <> 0)
			OR (ISNULL(V2.AVSAmount, 0) <> 0)
			OR (ISNULL(V2.AVRAmount, 0) <> 0)
			OR (ISNULL(V4.AdvanceSolde, 0) <> 0)
			OR (ISNULL(V5.AVSAmountSolde, 0) <> 0)
			OR (ISNULL(V5.AVRAmountSolde, 0) <> 0)
			OR V6.RepID IS NOT NULL

	-- Libert l'espace pris par ces tables puisque qu'elles ne sont plus utilisé dans le reste du traitement.
	DROP TABLE #tProjectionDate
	DROP TABLE #tBasicCommByRep
	DROP TABLE #tFuturCommSumByProjection
	DROP TABLE #tBasicCommAndBonusInfoForPeriod
	DROP TABLE #tRepRESAndSpecialAdv
	DROP TABLE #tProjectionRepChargeSum
	DROP TABLE #tProjectionRepCharge

	IF @@ERROR = 0
		RETURN (1)
	ELSE
		RETURN (-1)
END