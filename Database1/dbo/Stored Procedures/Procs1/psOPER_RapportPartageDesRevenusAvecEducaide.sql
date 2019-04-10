/****************************************************************************************************
Copyrights (c) 2014 Gestion Universitas inc
Nom                 :	psOPER_RapportPartageDesRevenusAvecEducaide
Description         :	Rapport de Partage Des Revenus Avec Educaide
Valeurs de retours  :	Dataset de données

Note                :	
					2014-05-08	Donald Huppé	    Création (glpi 11378)
					2015-09-17	Donald Huppé	    Gestion des divisions par 0
                    2018-05-17  Pierre-Luc Simard   Ajout des PlanID dans Un_RepLevelBracket

exec psOPER_RapportPartageDesRevenusAvecEducaide '2015-09-17'
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_RapportPartageDesRevenusAvecEducaide] (
	@dtDateTo DATETIME -- En date du
	)
AS
BEGIN

--DECLARE @dtDateTo datetime = '2014-05-01'

	--Frais de BEC

	SELECT 
		C.ConventionID,
		FraisDeBEC	= SUM(C9.fCLBFee)
	INTO #tFraisDeBEC
	FROM Un_CESP900 C9
	JOIN dbo.Un_Convention C ON C.ConventionID = C9.ConventionID
	JOIN Un_CESPReceiveFile CRF ON CRF.iCESPReceiveFileID = c9.iCESPReceiveFileID
	JOIN Un_CESP400 C4 ON C4.iCESP400ID = C9.iCESP400ID
	JOIN Un_CESPSendFile CSF ON CSF.iCESPSendFileID = C4.iCESPSendFileID
	WHERE C9.fCLBFee <> 0
	AND CRF.dtPeriodEnd <= @dtDateTo
	GROUP BY C.ConventionID

-------------------------- Pour avoir la réduction --------------------------

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
	EXEC SL_UN_RepGrossANDNetUnits NULL, '1950-01-01', @dtDateTo, 0, 1

	SELECT 
		Remun.repid,
		Directeur = hb.LastName + ' ' + hb.FirstName,
		c.ConventionNo,
		Remun.Niveau,
		RemunUnitaire = TotalLevelCommAmount + TotalLevelAdvanceAmount,
		Reduction = sum(Brut - Retraits + Reinscriptions) * (TotalLevelCommAmount + TotalLevelAdvanceAmount) * 0.5,
		brut = sum(brut),
		net = sum(Brut - Retraits + Reinscriptions),
		Reinscription = sum(Reinscriptions)
	INTO #Reduction
	from 
		#GrossANDNetUnits gnu
		JOIN dbo.Un_Unit u2 ON gnu.unitid = u2.UnitID AND u2.SaleSourceID = 235 --UNI-EPP-Éducaide Programme Persevera
		
		JOIN dbo.Un_Convention c ON u2.ConventionID = c.ConventionID
		join (
			SELECT 
				V.UnitID, -- ID du groupe d'unités
				V.RepID, -- ID du représentant
				V.RepLevelID, -- ID du niveau
				V.RepPct, -- Pourcentage de commissions pour ce niveau
				Niveau,
				TotalLevelCommAmount = SUM(V.SumComByUnit), -- Total de commissions de service que devrait toucher ce supérieur (% pas calculé) pour ce niveau par unité de ce groupe d'unités 
				TotalLevelAdvanceAmount = SUM(V.SumAdvByUnit) -- Total des avances que devrait toucher ce supérieur (% pas calculé) pour ce niveau par unité de ce groupe d'unités 
			FROM (
				SELECT DISTINCT
					U.UnitID, -- ID du groupe d'unités
					RepID = RH.BossID, -- ID du supérieur
					RLH.RepLevelID, -- ID du niveau
					VRB.SumComByUnit, -- Montant de la tombés de commissions de service
					VRB.SumAdvByUnit, -- Montant de la tombés d'avance
					RepPct = RH.RepBossPct -- Pourcentage de commissions du supérieur
					,Niveau = RL.LevelDesc
				FROM dbo.Un_Unit U
                JOIN Un_Convention C ON C.ConventionID = U.ConventionID
				JOIN (select DISTINCT g1.unitid from #GrossANDNetUnits g1 JOIN dbo.Un_Unit u1 ON g1.unitid = u1.UnitID WHERE U1.SaleSourceID = 235) g ON g.UnitID = U.UnitID
				JOIN Un_RepBossHist RH ON RH.RepID = U.RepID
				JOIN Un_RepLevelHist RLH ON RLH.RepID = RH.BossID
				JOIN Un_RepLevel RL ON RL.RepLevelID = RLH.RepLevelID AND RL.RepRoleID = RH.RepRoleID AND (RL.RepRoleID <> 'REP')
				JOIN (
					-- Retourne les configurations des tombés dans on format de définition de colonne différent
					SELECT  
						RepLevelID, -- ID du niveau
                        PlanID, -- Plan de la convention
						TargetFeeByUnit, -- Frais par unités à atteindre pour que la tombé soit versée
						EffectDate, -- Date d'Entrée en vigueur de la configuration 
						TerminationDate, -- Date de fin de vigueur de la configuration 
						SumComByUnit = AdvanceByUnit, -- Montant de la tombés de commissions de service
						SumAdvByUnit = 0 -- Montant de la tombés d'avances
					FROM Un_RepLevelBracket 
					WHERE RepLevelBracketTypeID = 'COM' -- Configuration de tombés de commissions de service seulement
					-----
					UNION
					----- 
					SELECT  
						RepLevelID, -- ID du niveau
                        PlanID, -- Plan de la convention
						TargetFeeByUnit, -- Frais par unités à atteindre pour que la tombé soit versée
						EffectDate, -- Date d'Entrée en vigueur de la configuration
						TerminationDate, -- Date de fin de vigueur de la configuration 
						SumComByUnit = 0, -- Montant de la tombés de commissions de service
						SumAdvByUnit = AdvanceByUnit -- Montant de la tombés d'avances
					FROM Un_RepLevelBracket 
					WHERE RepLevelBracketTypeID = 'ADV' -- Configuration de tombés d'avances seulement
					) VRB ON VRB.RepLevelID = RL.RepLevelID AND VRB.PlanID = C.PlanID
				-- Filtre sur le niveau qu'avait le supérieur lors de la vente (Date d'entrée en vigueur du groupe d'unités)
				WHERE ( U.InForceDate > = RLH.StartDate
						AND( U.InForceDate <= RLH.EndDate
							OR RLH.EndDate IS NULL
							)
						)
					-- Filtre sur les supérieurs qu'avait le représentant lors de la vente (Date d'entrée en vigueur du groupe d'unités)
					AND( U.InForceDate > = RH.StartDate
						AND( U.InForceDate <= RH.EndDate
							OR RH.EndDate IS NULL
							)
						)
					-- Filtre les configurations de tombés pour avoir seulement ceux en vigueur pour le groupe d'unités
					AND( U.InForceDate > = VRB.EffectDate
						AND( U.InForceDate <= VRB.TerminationDate
							OR VRB.TerminationDate IS NULL
							)
						)
					--and U.UnitID = 599692
				) V
			GROUP BY
				V.UnitID,
				V.RepID,
				V.RepLevelID,
				V.RepPct
				,Niveau
			) Remun ON Remun.UnitID = u2.UnitID
	JOIN dbo.Mo_Human hb ON Remun.RepID = hb.HumanID
	GROUP by 
		Remun.repid,
		hb.LastName + ' ' + hb.FirstName,
		c.ConventionNo,
		Remun.Niveau,
		TotalLevelCommAmount + TotalLevelAdvanceAmount
	having sum(Brut - Retraits + Reinscriptions) <> 0

----------------------------------------------------------------------------

	SELECT 
		c.ConventionNo,
		QteUniteSouscrite = u.UnitQty + ISNULL(ur.QteUniteResALL,0),
		QteUniteActive = u.UnitQty + ISNULL(ur.QteUniteResAfter,0),
		StatutConvention = case when css.ConventionStateID = 'FRM' then 'Inactive' ELSE 'Active' end,
		DateDeResiliation = u.TerminatedDate,
		DateNaissanceBenef = LEFT(CONVERT(VARCHAR, hb.BirthDate, 120), 10),
		AgeDuBenef = dbo.fn_Mo_Age(hb.BirthDate,@dtDateTo),
		/*
		Si la convention est active:

		Si âge du bénéficiaire <= 9 ans  alors 0$
		Si âge du bénéficiaire = 10 ans alors 20$
		Si âge du bénéficiaire = 11 ans alors 50$
		Si âge du bénéficiaire = 12 ans alors 80$
		Si âge du bénéficiaire = 13 ans alors 110$
		Si âge du bénéficiaire = 14 ans alors 125$
		Si âge du bénéficiaire = 15 ans alors 140$
		Si âge du bénéficiaire = 16 ans alors 155$
		Si âge du bénéficiaire = 17 ans alors 162,50$

		Si la convention est inactive:

		On arrête le calcul à la date de la résiliation (donc calculé sur l'âge du bénéficiaire à la date de résiliation)
*/
		HonoraireAdmPayable =	case when isnull(u.TerminatedDate,'3000-01-01') > @dtDateTo then
									case 
										when dbo.fn_Mo_Age(hb.BirthDate,@dtDateTo) <= 9 then 0
										when dbo.fn_Mo_Age(hb.BirthDate,@dtDateTo) = 10 then 20
										when dbo.fn_Mo_Age(hb.BirthDate,@dtDateTo) = 11 then 50
										when dbo.fn_Mo_Age(hb.BirthDate,@dtDateTo) = 12 then 80
										when dbo.fn_Mo_Age(hb.BirthDate,@dtDateTo) = 13 then 110
										when dbo.fn_Mo_Age(hb.BirthDate,@dtDateTo) = 14 then 125
										when dbo.fn_Mo_Age(hb.BirthDate,@dtDateTo) = 15 then 140
										when dbo.fn_Mo_Age(hb.BirthDate,@dtDateTo) = 16 then 155
										when dbo.fn_Mo_Age(hb.BirthDate,@dtDateTo) >= 17 then 162.5
									END
								ELSE
									case 
										when dbo.fn_Mo_Age(hb.BirthDate,u.TerminatedDate) <= 9 then 0
										when dbo.fn_Mo_Age(hb.BirthDate,u.TerminatedDate) = 10 then 20
										when dbo.fn_Mo_Age(hb.BirthDate,u.TerminatedDate) = 11 then 50
										when dbo.fn_Mo_Age(hb.BirthDate,u.TerminatedDate) = 12 then 80
										when dbo.fn_Mo_Age(hb.BirthDate,u.TerminatedDate) = 13 then 110
										when dbo.fn_Mo_Age(hb.BirthDate,u.TerminatedDate) = 14 then 125
										when dbo.fn_Mo_Age(hb.BirthDate,u.TerminatedDate) = 15 then 140
										when dbo.fn_Mo_Age(hb.BirthDate,u.TerminatedDate) = 16 then 155
										when dbo.fn_Mo_Age(hb.BirthDate,u.TerminatedDate) >= 17 then 162.5
									END									
								end,
								
		HonoraireAdmAVenir = 162.5 - 
								case when isnull(u.TerminatedDate,'3000-01-01') > @dtDateTo then
									case 
										when dbo.fn_Mo_Age(hb.BirthDate,@dtDateTo) <= 9 then 0
										when dbo.fn_Mo_Age(hb.BirthDate,@dtDateTo) = 10 then 20
										when dbo.fn_Mo_Age(hb.BirthDate,@dtDateTo) = 11 then 50
										when dbo.fn_Mo_Age(hb.BirthDate,@dtDateTo) = 12 then 80
										when dbo.fn_Mo_Age(hb.BirthDate,@dtDateTo) = 13 then 110
										when dbo.fn_Mo_Age(hb.BirthDate,@dtDateTo) = 14 then 125
										when dbo.fn_Mo_Age(hb.BirthDate,@dtDateTo) = 15 then 140
										when dbo.fn_Mo_Age(hb.BirthDate,@dtDateTo) = 16 then 155
										when dbo.fn_Mo_Age(hb.BirthDate,@dtDateTo) >= 17 then 162.5
									END
								ELSE
									0
							
								end,
		Frais = case when (u.UnitQty + ISNULL(ur.QteUniteResAfter,0)) <>0 then  frais.Frais / (u.UnitQty + ISNULL(ur.QteUniteResAfter,0)) else 0 end,

		/*
		si Frais de souscription par unité = 200$ alors nb d'unités souscrites x 30$
		Si non alors 0$
		*/
		HonoraireSouscPayable = case 
									WHEN case when (u.UnitQty + ISNULL(ur.QteUniteResAfter,0)) <>0 then  frais.Frais / (u.UnitQty + ISNULL(ur.QteUniteResAfter,0)) else 0 end
										= 200 
											THEN (u.UnitQty + ISNULL(ur.QteUniteResALL,0)) * 30
									ELSE 0 
								END,
		FraisDeBEC = ISNULL(fb.FraisDeBEC,0),
		CommVentePayable = cast(re.Reduction as money)
									
	FROM dbo.Un_Convention c
	JOIN dbo.Un_Unit u ON c.ConventionID = u.ConventionID
	JOIN dbo.Mo_Human hb on c.BeneficiaryID = hb.HumanID
	join (
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
				where startDate < DATEADD(d,1 ,@dtDateTo)
				group by conventionid
				) ccs on ccs.conventionid = cs.conventionid 
					and ccs.startdate = cs.startdate 
					--and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
		) css on C.conventionid = css.conventionid
	LEFT join (
		SELECT 
			r.UnitID, 
			QteUniteResALL = SUM(r.UnitQty),
			QteUniteResAfter = SUM(case when r.ReductionDate > @dtDateTo then r.UnitQty ELSE 0 end)
		from Un_UnitReduction r
		JOIN dbo.Un_Unit u1 on r.UnitID = u1.UnitID
		where u1.SaleSourceID = 235
		--and r.ReductionDate > @dtDateTo
		GROUP by r.UnitID
		)ur ON u.UnitID = ur.UnitID

	LEFT join (
		SELECT 
			u2.UnitID,
			Frais = SUM(ct.Fee)
		FROM dbo.Un_Unit u2 
		join Un_Cotisation ct ON u2.UnitID = ct.UnitID
		join Un_Oper o ON ct.OperID = o.OperID
		where u2.SaleSourceID = 235
		 AND o.OperDate <= @dtDateTo
		GROUP by u2.UnitID
		)frais ON u.UnitID = frais.UnitID
	LEFT join #Reduction re on re.conventionno = c.ConventionNo
	LEFT JOIN #tFraisDeBEC fb ON fb.conventionid = c.ConventionID

	where u.SaleSourceID = 235
	ORDER BY c.ConventionNo

END