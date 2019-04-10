/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service		: psREPR_RapportResiliation60Jours
Nom du service		: Obtenir un rapport des résiliations avec code de raison "60 jours"
But 				: 
Facette				: REPR

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXECUTE psREPR_RapportResiliation60Jours '2011-01-01','2011-12-31', 0

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2011-11-16		Donald Huppé						Création du service	

*********************************************************************************************************************/
CREATE procedure [dbo].[psREPR_RapportResiliation60Jours] 
	(
	@StartDate DATETIME, -- Date de début
	@EndDate DATETIME, -- Date de fin
	@RepID INTEGER
	) 

as
BEGIN

	create table #GrossANDNetUnits (
		UnitID_Ori INTEGER,
		UnitID INTEGER,
		RepID INTEGER,
		Recrue INTEGER,
		BossID INTEGER,
		RepTreatmentID INTEGER,
		RepTreatmentDate DATETIME,
		Brut FLOAT,
		Retraits FLOAT,
		Reinscriptions FLOAT,
		Brut24 FLOAT,
		Retraits24 FLOAT,
		Reinscriptions24 FLOAT) 

	-- Les données des Rep
	INSERT #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits NULL, @StartDate, @EndDate, @RepID , 1 -- on va chercher toutes les données et on filtre par repid à la fin

	select 

		GNU.repid,

		RepNom = HR.lastname,
		RepPrenom = HR.firstname,
		DirNom = hb.lastname,
		DirPrenom = hb.firstname,

		Brut =  sum(Brut),
		Retraits = sum(Retraits),
		Reinscriptions = sum(Reinscriptions),
		Net = sum(Brut - Retraits + Reinscriptions),
		Retrait60jours = isnull(Retrait60jours,0),
		RatioRetrait = round( case WHEN sum(Retraits) <> 0 THEN (isnull(Retrait60jours,0)/sum(Retraits)) ELSE 0 end,2),
		RatioBrut = round(case when sum(Brut) <> 0 THEN (isnull(Retrait60jours,0)/sum(Brut)) ELSE 0 end,2)
		
	from #GrossANDNetUnits GNU
	JOIN dbo.Un_Unit U on GNU.UnitID = U.UnitID
	JOIN dbo.Mo_Human hr on GNU.repid = hr.humanid
	
	LEFT join ( -- On veut le directeur en date du rapport
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
					AND LEFT(CONVERT(VARCHAR, StartDate, 120), 10) <= LEFT(CONVERT(VARCHAR, getdate(), 120), 10)
					AND (EndDate IS NULL OR LEFT(CONVERT(VARCHAR, EndDate, 120), 10) >= LEFT(CONVERT(VARCHAR, getdate(), 120), 10)) 
				GROUP BY
					  RepID
				) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
		  WHERE RB.RepRoleID = 'DIR'
				AND RB.StartDate IS NOT NULL
				AND LEFT(CONVERT(VARCHAR, RB.StartDate, 120), 10) <= LEFT(CONVERT(VARCHAR, getdate(), 120), 10)
				AND (RB.EndDate IS NULL OR LEFT(CONVERT(VARCHAR, RB.EndDate, 120), 10) >= LEFT(CONVERT(VARCHAR, getdate(), 120), 10))
		  GROUP BY
				RB.RepID
		)boss ON GNU.repid = boss.RepID
	left JOIN dbo.Mo_Human hb ON Boss.bossid = hb.HumanID
	left join (
		select 
			unitid,
			startDate = min(startDate) 
		from Un_UnitUnitState
		group by unitid
		) sd on sd.unitid = U.unitid
	LEFT JOIN (
		SELECT u.RepID, Retrait60jours = sum(ur.UnitQty)
		FROM dbo.Un_Unit u 
		JOIN Un_UnitReduction ur on u.UnitID = ur.UnitID
		join Un_UnitReductionReason urr ON ur.UnitReductionReasonID = urr.UnitReductionReasonID
		WHERE ur.UnitReductionReasonID = 32
		AND ur.ReductionDate BETWEEN @StartDate and @EndDate
		GROUP by u.RepID
		)R60 ON GNU.repid = R60.Repid

	GROUP BY
		GNU.repid,

		HR.lastname,
		HR.firstname,
		hb.lastname,
		hb.firstname,
		isnull(Retrait60jours,0)
	ORDER BY
		HR.lastname,
		HR.firstname

END


