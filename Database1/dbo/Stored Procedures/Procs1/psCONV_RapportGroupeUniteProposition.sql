/****************************************************************************************************
Copyrights (c) 2016 Gestion Universitas inc.

Code du service		: psCONV_RapportGroupeUniteProposition
Nom du service		: Rapport des groupes d'unité en proposition
But 				: Obtenir la liste des goupes d'unité qui sont en proposition  jira ti-3717
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXECUTE psCONV_RapportGroupeUniteProposition @EnDateDu = '2016-06-30'

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2016-06-30		Donald Huppé						Création du service			

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportGroupeUniteProposition] 
(
	@EnDateDu datetime

)
AS
BEGIN


set ARITHABORT on

	SELECT DISTINCT
		v.ConventionNo
		,v.ConventionID
		,UnitID
		,DateDebutOperFinanc = CAST(DateDebutOperFinanc AS DATE)
		,SoldeEpargne = ISNULL(Epargne,0)
		,SoldeFrais = ISNULL(frais,0)
		--,EstimatedCotisationAndFee = ISNULL(EstimatedCotisationAndFee,0)
		--,EstimatedCotisation = ISNULL(EstimatedCotisationAndFee,0) - ISNULL(EstimatedFee,0)
		--,EstimatedFee = ISNULL(EstimatedFee,0)
		,EcartEpargne = ISNULL(Epargne,0) - ( ISNULL(EstimatedCotisationAndFee,0) - ISNULL(EstimatedFee,0) )
		,EcartFrais =  ISNULL(frais,0) - ISNULL(EstimatedFee,0)
		,c.SubscriberID
		,NomSousc = hs.LastName
		,PrenomSousc = hs.FirstName
		,Representant = hr.FirstName + ' ' + hr.LastName
		,Directeur = hbos.FirstName + ' ' + hbos.LastName

	FROM (
		SELECT 
			c.ConventionNo,
			c.ConventionID,
			u.UnitID,
			DateDebutOperFinanc = u.InForceDate,
			Epargne,
			Frais,
			EstimatedCotisationAndFee = SUM(dbo.FN_UN_EstimatedCotisationAndFee(U.InForceDate,@EnDateDu,DAY(c.FirstPmtDate),u.UnitQty + ISNULL(qteres,0),m.PmtRate,m.PmtByYearID,m.PmtQty,u.InForceDate)) ,
			EstimatedFee = SUM(dbo.fn_Un_EstimatedFee(dbo.fn_Un_EstimatedCotisationANDFee(
																U.InForceDate, 
																@EnDateDu, 
																DAY(C.FirstPmtDate), 
																U.UnitQty + ISNULL(qteres,0), 
																M.PmtRate, 
																M.PmtByYearID, 
																M.PmtQty, 
																U.InForceDate), 
													U.UnitQty + ISNULL(qteres,0), 
													M.FeeSplitByUnit, 
													M.FeeByUnit)
								)
		FROM Un_Convention c
		JOIN Un_Unit u ON c.ConventionID = u.ConventionID
		LEFT JOIN (SELECT unitid, qteres = SUM(UnitQty) FROM Un_UnitReduction WHERE ReductionDate > @EnDateDu GROUP BY UnitID) ur ON u.UnitID = ur.UnitID
		JOIN (
			SELECT 
				us.unitid,
				uus.startdate,
				us.UnitStateID
			FROM 
				Un_UnitunitState us
				JOIN (
					SELECT 
					unitid,
					startdate = MAX(startDate)
					FROM un_unitunitstate
					WHERE startDate < DATEADD(d,1 ,@EnDateDu)
					GROUP BY unitid
					) uus ON uus.unitid = us.unitid 
						AND uus.startdate = us.startdate 
						AND us.UnitStateID = 'PTR'
			)uus ON uus.unitID = u.UnitID
		JOIN (
			SELECT umh.UnitID, ModalID = MAX(umh.ModalID )
			FROM Un_UnitModalHistory umh
			WHERE umh.StartDate = (
								SELECT MAX(StartDate)
								FROM Un_UnitModalHistory umh2
								WHERE umh.UnitID = umh2.UnitID
								AND umh2.StartDate <= @EnDateDu
								)
			GROUP BY umh.UnitID
			) mh ON mh.UnitID = u.UnitID
		JOIN Un_Modal m ON mh.ModalID = m.ModalID
		JOIN Un_Plan p ON c.PlanID = p.PlanID
		LEFT JOIN (
				SELECT
					U.UnitID,
					DateDebutOperFinanc = MIN(u.InForceDate),
					Epargne = SUM(Ct.Cotisation),
					Frais = SUM(Ct.Fee)
				FROM Un_Unit U
				JOIN (
					SELECT 
						us.unitid,
						uus.startdate,
						us.UnitStateID
					FROM 
						Un_UnitunitState us
						JOIN (
							SELECT 
							unitid,
							startdate = MAX(startDate)
							FROM un_unitunitstate
							WHERE startDate < DATEADD(d,1 ,@EnDateDu)
							GROUP BY unitid
							) uus ON uus.unitid = us.unitid 
								AND uus.startdate = us.startdate 
								AND us.UnitStateID = 'PTR'
					)uus ON uus.unitID = u.UnitID
				JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
				JOIN un_oper o ON ct.operid = o.operid
				WHERE o.operdate <= @EnDateDu
				GROUP BY U.UnitID
			)ep ON u.UnitID = ep.UnitID

		WHERE  c.PlanID <> 4
		--AND c.ConventionNo = 'R-20060131014'
		GROUP BY c.ConventionNo,c.ConventionID,u.UnitID, u.InForceDate,Epargne,Frais
		) v
	JOIN un_convention c ON v.conventionid = c.conventionid
	JOIN Un_Subscriber s ON c.SubscriberID = s.SubscriberID
	JOIN Mo_Human hs ON s.SubscriberID = hs.HumanID
	JOIN Mo_Human hr ON s.RepID = hr.HumanID
	JOIN (
		SELECT
			RB.RepID,
			BossID = MAX(BossID) -- au cas ou il y a 2 boss avec le même %.  alors ON prend l'id le + haut. ex : repid = 497171
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
					AND LEFT(CONVERT(VARCHAR, StartDate, 120), 10) <= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10)
					AND (EndDate IS NULL OR LEFT(CONVERT(VARCHAR, EndDate, 120), 10) >= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10)) 
				GROUP BY
						RepID
				) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
			WHERE RB.RepRoleID = 'DIR'
				AND RB.StartDate IS NOT NULL
				AND LEFT(CONVERT(VARCHAR, RB.StartDate, 120), 10) <= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10)
				AND (RB.EndDate IS NULL OR LEFT(CONVERT(VARCHAR, RB.EndDate, 120), 10) >= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10))
			GROUP BY
				RB.RepID
		)BR ON BR.RepID = s.RepID
	JOIN Mo_Human hbos ON hbos.HumanID = br.BossID

	ORDER BY DateDebutOperFinanc desc

set ARITHABORT off
END