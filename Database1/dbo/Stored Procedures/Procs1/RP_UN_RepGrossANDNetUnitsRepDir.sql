/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	RP_UN_RepGrossANDNetUnits
Description         :	Rapport des unités brutes et nettes vendus dans une période par représentants et par directeurs
Valeurs de retours  :	Dataset 
Note                :	ADX0001206	IA	2006-11-06	Bruno Lapointe		Optimisation.
						ADX0001285	BR	2006-12-07	Bruno Lapointe		Optimisation.
						2008-07-31 Patrick Robitaille		Utiliser le champ bReduitTauxConservationRep de la table
															Un_UnitReductionReason au lieu d'une liste d'IDs
						2008-11-18 Patrick Robitaille		Intégrer le calcul des rétentions sur le nb. d'unités brutes
						2008-12-22 Patrick Robitaille		Utiliser une table temporaire pour les rétentions de clients
															Utiliser COALESCE pour tester le RepID au lieu d'un OR.
						2009-01-14 Patrick Robitaille		Correction d'un bug qui faisait en sorte qu'on avait un écart entre la version Rep
															et directeur au niveau des différents nombres d'unités dans les colonnes.
						2009-01-30 Patrick Robitaille		Correction sur le calcul du Cumulatif brut sur 24 mois et du calcul
															des résiliations d'unités.  Si une partie ou toutes les unités résiliées
															ont été réutilisées, le nb d'unités résiliées est diminué du nb d'unités réutilisées.
						2009-03-18 Patrick Robitaille		Correction sur le calcul des unités réutilisées afin de reculer de 24 mois au lieu de 
															seulement reculer au début de l'année de la période

						2009-05-13 Donald Huppé				-Correction du calcul de #tYearRepTreatment24Months. (il manquait une semaine)

															-Correction de l'utilisation de #tYearRepTreatment24Months : au lieu de reculer de 6 jours (car ce n'est pas toujours le cas entre 2 traitements), on utilise maintenant LasRepTreatmentDate

															-Correction du calcul de la rétention dans #tTransferedUnits.  
															 On part maintenant des unités brutes (UnitQty + réduction) au lieu des unités nettes (UnitQty). 
															 Cela et plus logique et stabilise les résultats peu importe quand on sort le rapport

															-Correction du calcul de la rétention.  On vérifie qu'il s'agit du même rep et même souscripteur.  
															 On ne vérifie pas le bénéficiaire à la demande de Pascal Gilbert.

															-Modification des Réinscriptions de frais non couverts.  (Demande de Pascal Gilbert)
															 On les sépare des retraits de frais non couverts eu lieu de les soustraire de ceux-ci. 
															 Et on les sort à la date de la réinscription (et non à la date du retrait). 
															 Cela stabilise les résultats peu importe quand on sort le rapport. 

															-Intégration de la SP RP_UN_RepGrossANDNetUnitsDir afin d'avoir une seule SP pour le rapport d'unité brutes et nettes

															-Retiré le 2009-07-15 : Ajout des paramètres @StartDate et @EndDate, qui peuvent être utilisés à la place du @ReptreatmentID.
															 Cela permet de demander le rapport par plage de date.  Sera utile pour d'autre rapport tel que le Club du président, etc.
						2016-10-28	Donald Huppé			jira ti-1893 : Ajuster l'appel de SL_UN_RepGrossANDNetUnits

exec RP_UN_RepGrossANDNetUnitsRepDir 1, 341, 436381
exec RP_UN_RepGrossANDNetUnitsRepDir 1, 733, 0

select * from Un_RepTreatment order by reptreatmentDate desc

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_RepGrossANDNetUnitsRepDir] (
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@ReptreatmentID INTEGER, -- ID du traitement de commissions
	--@StartDate DATETIME, -- Date de début
	--@EndDate DATETIME, -- Date de fin
	@RepID INTEGER) -- ID du représentant
AS
BEGIN

CREATE TABLE #GrossANDNetUnits (
		RepID INTEGER,
		BossID INTEGER,
		RepTreatmentID INTEGER,
		RepTreatmentDate DATETIME,
		Brut_4 FLOAT,
		Brut_8 FLOAT,
		Brut_10 FLOAT,
		Retraits_4 FLOAT,
		Retraits_8 FLOAT,
		Retraits_10 FLOAT,
		Reinscriptions_4 FLOAT,
		Reinscriptions_8 FLOAT,
		Reinscriptions_10 FLOAT,
		Net_4 FLOAT,
		Net_8 FLOAT,
		Net_10 FLOAT,
		Brut24_4 FLOAT,
		Brut24_8 FLOAT,
		Brut24_10 FLOAT,
		Retraits24_4 FLOAT,
		Retraits24_8 FLOAT,
		Retraits24_10 FLOAT,
		Reinscriptions24_4 FLOAT,
		Reinscriptions24_8 FLOAT,
		Reinscriptions24_10 FLOAT,
		Net24_4 FLOAT,
		Net24_8 FLOAT,
		Net24_10 FLOAT)

	CREATE INDEX #DD ON #GrossANDNetUnits(RepTreatmentID)

	-- Données de base par Rep et Directeur
	INSERT #GrossANDNetUnits 
	--EXEC SL_UN_RepGrossANDNetUnits @ReptreatmentID, @StartDate, @EndDate, @RepID, 0
	EXEC SL_UN_RepGrossANDNetUnits --@ReptreatmentID, NULL, NULL, @RepID, 0
		@ReptreatmentID = @ReptreatmentID, -- ID du traitement de commissions
		@StartDate = NULL, -- Date de début
		@EndDate = NULL, -- Date de fin
		@RepID = @RepID, -- ID du représentant
		@ByUnit = 0 -- On veut les résultats par RepID et BossID
		--,@QteMoisRecrue = 12
		,@incluConvT = 1

	select -- Les boss ont des totaux en tant que Rep et en tant que Boss alors on regroupe ces différents totaux par RepID
		RepID,
		BossID,
		RepTreatmentID,
		RepTreatmentDate,
		Brut = SUM(Brut),
		Retraits = SUM(Retraits),
		Reinscriptions = SUM(Reinscriptions),
		Net = SUM(Net),
		BrutDIR = SUM(BrutDIR),
		RetraitsDIR = SUM(RetraitsDIR),
		ReinscriptionsDIR = SUM(ReinscriptionsDIR),
		NetDIR = SUM(NetDIR),
		Brut24 = SUM(Brut24),
		Retraits24 = SUM(Retraits24),
		Reinscriptions24 = SUM(Reinscriptions24),
		Net24 = SUM(Net24),
		Brut24DIR = SUM(Brut24DIR),
		Retraits24DIR = SUM(Retraits24DIR),
		Reinscriptions24DIR = SUM(Reinscriptions24DIR),
		Net24DIR = SUM(Net24DIR)
	INTO #TempRepBoss
	from (
		-- Totaux par Rep
		SELECT 
			RepID,
			BossID,
			RepTreatmentID,
			RepTreatmentDate,
			Brut = SUM(Brut_4 + Brut_8 + Brut_10),
			Retraits = SUM(Retraits_4 + Retraits_8 + Retraits_10),
			Reinscriptions = SUM(Reinscriptions_4 + Reinscriptions_8 + Reinscriptions_10),
			Net = SUM(Net_4 + Net_8 + Net_10),
			BrutDIR = 0,
			RetraitsDIR = 0,
			ReinscriptionsDIR = 0,
			NetDIR = 0,
			Brut24 = SUM(Brut24_4 + Brut24_8 + Brut24_10),
			Retraits24 = SUM(Retraits24_4 + Retraits24_8 + Retraits24_10),
			Reinscriptions24 = SUM(Reinscriptions24_4 + Reinscriptions24_8 + Reinscriptions24_10),
			Net24 = SUM(Net24_4 + Net24_8 + Net24_10),
			Brut24DIR = 0,
			Retraits24DIR = 0,
			Reinscriptions24DIR = 0,
			Net24DIR = 0
		from #GrossANDNetUnits REP
		group by
			RepID,
			BossID,
			RepTreatmentID,
			RepTreatmentDate

		UNION ALL

		-- Totaux par BOSS
		SELECT 
			RepID = BossID ,
			BossID,
			RepTreatmentID,
			RepTreatmentDate,
			Brut = 0,
			Retraits = 0,
			Reinscriptions = 0,
			Net = 0,
			BrutDIR = SUM(Brut_4 + Brut_8 + Brut_10),
			RetraitsDIR = SUM(Retraits_4 + Retraits_8 + Retraits_10),
			ReinscriptionsDIR = SUM(Reinscriptions_4 + Reinscriptions_8 + Reinscriptions_10),
			NetDIR = SUM(Net_4 + Net_8 + Net_10),
			Brut24 = 0,
			Retraits24 = 0,
			Reinscriptions24 = 0,
			Net24 = 0,
			Brut24DIR = SUM(Brut24_4 + Brut24_8 + Brut24_10),
			Retraits24DIR = SUM(Retraits24_4 + Retraits24_8 + Retraits24_10),
			Reinscriptions24DIR = SUM(Reinscriptions24_4 + Reinscriptions24_8 + Reinscriptions24_10),
			Net24DIR = SUM(Net24_4 + Net24_8 + Net24_10)
		from #GrossANDNetUnits BOSS
		WHERE BOSSID <> 0
		group by
			BOSSID,
			RepTreatmentID,
			RepTreatmentDate
		) V

	group by
			RepID,
			BossID,
			RepTreatmentID,
			RepTreatmentDate

	-- Totaux par Rep
	SELECT 
		RepID,
		RepTreatmentID,
		RepTreatmentDate,
		Brut = SUM(Brut),
		Retraits = SUM(Retraits),
		Reinscriptions = SUM(Reinscriptions),
		Net = SUM(Net),
		BrutDIR = SUM(BrutDIR),
		RetraitsDIR = SUM(RetraitsDIR),
		ReinscriptionsDIR = SUM(ReinscriptionsDIR),
		NetDIR = SUM(NetDIR),
		Brut24 = SUM(Brut24),
		Retraits24 = SUM(Retraits24),
		Reinscriptions24 = SUM(Reinscriptions24),
		Net24 = SUM(Net24),
		Brut24DIR = SUM(Brut24DIR),
		Retraits24DIR = SUM(Retraits24DIR),
		Reinscriptions24DIR = SUM(Reinscriptions24DIR),
		Net24DIR = SUM(Net24DIR)
	into #TempRep
	from #TempRepBoss
	group by
		RepID,
		RepTreatmentID,
		RepTreatmentDate

--------------------------------------------------
------------------- MAIN -------------------------
--------------------------------------------------
	-- Résultat par Rep
	SELECT 
		SequenceID = 0,
		T.RepID,
		BossID = 0,
		H.FirstName,
		H.LastName,
		R.RepCode,
		YearTreatment = YEAR(MAX(T.RepTreatmentDate)),
		T.RepTreatmentID,
		T.RepTreatmentDate,
		T.Brut,
		T.BrutDIR,
		CumBrut = SUM(T2.Brut),
		CumBrutDIR = SUM(T2.BrutDIR),
		T.Brut24,
		T.Brut24DIR,
		T.Retraits,
		T.Reinscriptions, --
		T.RetraitsDIR,
		T.ReinscriptionsDIR,
		CumRetraits = SUM(T2.Retraits),
		CumReinscriptions = SUM(T2.Reinscriptions),
		CumRetraitsDIR = SUM(T2.RetraitsDIR),
		CumReinscriptionsDIR = SUM(T2.ReinscriptionsDIR),
		T.Retraits24,
		T.Reinscriptions24,
		T.Retraits24DIR,
		T.Reinscriptions24DIR,
		T.Net,
		T.NetDIR,
		CumNet = SUM(T2.Net),
		CumNetDIR = SUM(T2.NetDIR),
		T.Net24,
		T.Net24DIR,
		Cons = 
			CASE
				WHEN T.Brut24 <= 0 THEN 0
			ELSE ROUND((T.Net24 / T.Brut24) * 100, 2)
			END,
		ConsDIR = 
			CASE
				WHEN T.Brut24DIR <= 0 THEN 0
			ELSE ROUND((T.Net24DIR / T.Brut24DIR) * 100, 2)
			END
	INTO #FinaleRep
	FROM #TempRep T
	JOIN #TempRep T2 On T.RepID = T2.RepID AND T.RepTreatmentDate >= T2.RepTreatmentDate
	JOIN dbo.Mo_Human H ON H.HumanID = T.RepID
	JOIN Un_Rep R ON R.RepID = T.RepID
	GROUP BY 
		T.RepID,
		T.RepTreatmentID,
		T.RepTreatmentDate,
		T.Brut,
		T.BrutDIR,
		T.Retraits,
		T.Reinscriptions,
		T.RetraitsDIR,
		T.ReinscriptionsDIR,
		T.Net,
		T.NetDIR,
		T.Net24,
		T.Net24DIR,
		T.Retraits24,
		T.Reinscriptions24,
		T.Retraits24DIR,
		T.Reinscriptions24DIR,
		T.Brut24,
		T.Brut24DIR,
		H.FirstName,
		H.LastName,
		R.RepCode

	-- Résultat par Rep et Boss
	SELECT 
		SequenceID = 0,
		T.RepID,
		T.BossID,
		H.FirstName,
		H.LastName,
		R.RepCode,
		YearTreatment = YEAR(MAX(T.RepTreatmentDate)),
		T.RepTreatmentID,
		T.RepTreatmentDate,
		T.Brut,
		T.BrutDIR,
		CumBrut = SUM(T2.Brut),
		CumBrutDIR = SUM(T2.BrutDIR),
		T.Brut24,
		T.Brut24DIR,
		T.Retraits,
		T.Reinscriptions, --
		T.RetraitsDIR,
		T.ReinscriptionsDIR,
		CumRetraits = SUM(T2.Retraits),
		CumReinscriptions = SUM(T2.Reinscriptions),
		CumRetraitsDIR = SUM(T2.RetraitsDIR),
		CumReinscriptionsDIR = SUM(T2.ReinscriptionsDIR),
		T.Retraits24,
		T.Reinscriptions24,
		T.Retraits24DIR,
		T.Reinscriptions24DIR,
		T.Net,
		T.NetDIR,
		CumNet = SUM(T2.Net),
		CumNetDIR = SUM(T2.NetDIR),
		T.Net24,
		T.Net24DIR,
		Cons = 
			CASE
				WHEN T.Brut24 <= 0 THEN 0
			ELSE ROUND((T.Net24 / T.Brut24) * 100, 2)
			END,
		ConsDIR = 
			CASE
				WHEN T.Brut24DIR <= 0 THEN 0
			ELSE ROUND((T.Net24DIR / T.Brut24DIR) * 100, 2)
			END
	INTO #FinaleRepBoss
	FROM #TempRepBoss T
	JOIN #TempRepBoss T2 On T.RepID = T2.RepID AND T.RepTreatmentDate >= T2.RepTreatmentDate
	JOIN dbo.Mo_Human H ON H.HumanID = T.RepID
	JOIN Un_Rep R ON R.RepID = T.RepID
	GROUP BY 
		T.RepID,
		T.BossID,
		T.RepTreatmentID,
		T.RepTreatmentDate,
		T.Brut,
		T.BrutDIR,
		T.Retraits,
		T.Reinscriptions,
		T.RetraitsDIR,
		T.ReinscriptionsDIR,
		T.Net,
		T.NetDIR,
		T.Net24,
		T.Net24DIR,
		T.Retraits24,
		T.Reinscriptions24,
		T.Retraits24DIR,
		T.Reinscriptions24DIR,
		T.Brut24,
		T.Brut24DIR,
		H.FirstName,
		H.LastName,
		R.RepCode

	-- Grand Totaux
	SELECT
		SequenceID = 1,
		RepID = 0,
		BossID = 0,
		LastName = 'Grands totaux',
		FirstName = ' ',
		RepCode = ' ',
		YearTreatment,
		RepTreatmentID,
		RepTreatmentDate,
		Brut = SUM(Brut),
		BrutDIR = SUM(BrutDIR),
		CumBrut = SUM(CumBrut),
		CumBrutDIR = SUM(CumBrutDIR),
		Brut24 = SUM(Brut24),
		Brut24DIR = SUM(Brut24DIR),
		Retraits = SUM(Retraits),
		Reinscriptions = SUM(Reinscriptions),
		RetraitsDIR = SUM(RetraitsDIR),
		ReinscriptionsDIR = SUM(ReinscriptionsDIR),
		CumRetraits = SUM(CumRetraits),
		CumReinscriptions = SUM(CumReinscriptions),
		CumRetraitsDIR = SUM(CumRetraitsDIR),
		CumReinscriptionsDIR = SUM(CumReinscriptionsDIR),
		Retraits24 = SUM(Retraits24),
		Reinscriptions24 = SUM(Reinscriptions24),
		Retraits24DIR = SUM(Retraits24DIR),
		Reinscriptions24DIR = SUM(Reinscriptions24DIR),
		Net = SUM(Net),
		NetDIR = SUM(NetDIR),
		CumNet = SUM(CumNet),
		CumNetDIR = SUM(CumNetDIR),
		Net24 = SUM(Net24),
		Net24DIR = SUM(Net24DIR),
		Cons = 
			CASE 
				WHEN SUM(Brut24) = 0 THEN 0
			ELSE ROUND((SUM(Net24) / SUM(Brut24) * 100), 2) 
			END,
		ConsDIR =
			CASE
				WHEN SUM(Brut24DIR) = 0 THEN 0
			ELSE ROUND((SUM(Net24DIR) / SUM(Brut24DIR) * 100), 2)
			END
	INTO #FinaleTotal
	FROM #FinaleRep
	where (@repid = 0) or  (RepID = @RepID)
	GROUP BY
		YearTreatment,
		RepTreatmentID,
		RepTreatmentDate

	-- Résultat Final
	SELECT
		SequenceID,
		RepID,
		BossID,
		BOSS = 0,
		RepName = FirstName+' '+LastName,
		DateOrRep = convert(Char(10),RepTreatmentDate,121),
		FirstName,
		LastName,
		RepCode,
		YearTreatment,
		RepTreatmentID,
		RepTreatmentDate,
		Brut,
		BrutDIR,
		CumBrut,
		CumBrutDIR,
		Brut24,
		Brut24DIR,
		Retraits,
		Reinscriptions,
		RetraitsDIR,
		ReinscriptionsDIR,
		CumRetraits,
		CumReinscriptions,
		CumRetraitsDIR,
		CumReinscriptionsDIR,
		Retraits24,
		Reinscriptions24,
		Retraits24DIR,
		Reinscriptions24DIR,
		Net,
		NetDIR,
		CumNet,
		CumNetDIR,
		Net24,
		Net24DIR,
		Cons,
		ConsDIR

--	into #resultatFinal

	FROM #FinaleRep
	where (@repid = 0) or  (RepID = @RepID)

	---------
	UNION ALL
	---------
	SELECT
		SequenceID,
		RepID,
		BossID,
		BOSS = 0,
		RepName = FirstName+' '+LastName,
		DateOrRep = convert(Char(10),RepTreatmentDate,121),
		FirstName,
		LastName,
		RepCode,
		YearTreatment,
		RepTreatmentID,
		RepTreatmentDate,
		Brut,
		BrutDIR,
		CumBrut,
		CumBrutDIR,
		Brut24,
		Brut24DIR,
		Retraits,
		Reinscriptions,
		RetraitsDIR,
		ReinscriptionsDIR,
		CumRetraits,
		CumReinscriptions,
		CumRetraitsDIR,
		CumReinscriptionsDIR,
		Retraits24,
		Reinscriptions24,
		Retraits24DIR,
		Reinscriptions24DIR,
		Net,
		NetDIR,
		CumNet,
		CumNetDIR,
		Net24,
		Net24DIR,
		Cons,
		ConsDIR
	FROM #FinaleTotal

	---------
	UNION ALL
	---------
	-- Totaux pour la semaine demandée de chaque Rep par Boss.
	select 
		SequenceID = 0,
		RepID = BossID,
		BossID,
		Boss = 1,
		RepName = HB1.FirstName + ' ' + HB1.LastName, -- le directeur
		DateOrRep = FRB.LastName + ',' + FRB.FirstName, -- le rep du directeur
		FirstName = HB1.FirstName,
		LastName = HB1.LastName,
		RepCode = RB1.RepCode,
		YearTreatment,
		RepTreatmentID,
		RepTreatmentDate,
		Brut,
		BrutDIR,
		CumBrut,
		CumBrutDIR,
		Brut24,
		Brut24DIR,
		Retraits,
		Reinscriptions,
		RetraitsDIR,
		ReinscriptionsDIR,
		CumRetraits,
		CumReinscriptions,
		CumRetraitsDIR,
		CUMReinscriptionsDIR,
		Retraits24,
		Reinscriptions24,
		Retraits24DIR,
		Reinscriptions24DIR,
		Net,
		NetDIR,
		CumNet,
		CumNetDIR,
		Net24, 
		Net24DIR,
		Cons,
		ConsDIR
	from #FinaleRepBoss FRB
	join un_rep RB1 on FRB.BossID = RB1.RepID
	JOIN dbo.mo_human HB1 on RB1.RepID = HB1.humanID
	where RepTreatmentID = @ReptreatmentID
	and ((@repid = 0) or  (BossID =@RepID))
	order by
		SequenceID,
		LastName,
		FirstName,
		DateOrRep

 --select * from #resultatFinal 

End


