/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	RP_UN_RepTreatmentSumary_New
Description         :	Procédure stockée du rapport : Rapport SSRS sommaire des commissions Nouveau
Valeurs de retours  :	Dataset
Note                :	2009-07-01	Donald Huppé	Création


exec RP_UN_RepTreatmentSumary_New 1, 149653 , 342
exec RP_UN_RepTreatmentSumary_New 1, 0 , 342
exec RP_UN_RepTreatmentSumary 1, 0 , 342
exec RP_UN_RepTreatmentSumary_New 1, 149511 , 342

select * from un_reptreatment
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_RepTreatmentSumary_New] (
	@ConnectID INTEGER,
	@RepID INTEGER,
	@RepTreatmentID INTEGER)
AS 
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT,
		@RepTreatmentDate DATETIME,
		@RepTreatmentDateFrom DATETIME,
		@Periode INTEGER,
		@RepTreatmentIdMin INTEGER,
		@RepTreatmentIdPrec INTEGER,
		@RepTreatmentDatePrec DATETIME,
		@RepTreatmentIdTmp INTEGER

	create table #TSA(
		SpecialAdvance FLOAT,
		TerminatedAdvance FLOAT,
		Advances FLOAT,
		CalcAdvances FLOAT,
		FuturComs FLOAT,
		CommPcts FLOAT,
		CalcCommPcts FLOAT,
		RepID INTEGER
		)

	SET @dtBegin = GETDATE()

	IF @RepID = 0 	
		SET @RepID = NULL

	SELECT @RepTreatmentDate = RepTreatmentDate
	FROM Un_RepTreatment
	WHERE RepTreatmentID = @RepTreatmentID

	-- Date de début de la période demandée
	SELECT @RepTreatmentDateFrom = dateadd(dd,1,RepTreatmentDate)
	FROM Un_RepTreatment
	WHERE RepTreatmentID = @RepTreatmentID - 1

	SELECT @RepTreatmentIdMin = min(reptreatmentid)
	FROM Un_RepTreatment
	WHERE year(RepTreatmentDate) = year(@RepTreatmentDate)

	-- le dernier traitement de l'an passé
	SELECT 
		@RepTreatmentIdPrec = max(reptreatmentid),
		@RepTreatmentDatePrec = max(RepTreatmentDate)
	FROM Un_RepTreatment
	WHERE year(RepTreatmentDate) = year(@RepTreatmentDate)-1

	insert into #TSA
	exec RP_UN_RepTreatmentTerminatedAndSpecialAdvance @ConnectID,@RepID,@RepTreatmentIdPrec



	-- Avance brutes et reprise d'avance
	-- Impossible de faire la somme de PeriodAdvance sur plus d'un reptreatmentid à la fois(le temps de réponse est trp long), 
	-- alors je fait un curseur pour chaque reptreatmentid
	create table #TmpAvcComm (
		RepTreatmentid INTEGER,
		RepTreatmentDate DATETIME,
		repid INTEGER,
		RepRoleDesc VARCHAR(255),
		PeriodUnitQty FLOAT,
		AvanceBrute FLOAT,
		RepriseAvance FLOAT,
		PeriodComm FLOAT,
		PeriodBusinessBonus float,
		Adjustment float,
		Retenu float,
		Advance float,
		FuturComm float )

	DECLARE MyCursor CURSOR FOR

		SELECT reptreatmentid 
		from Un_RepTreatment 
		where reptreatmentid between @RepTreatmentIdPrec and @RepTreatmentID
		order by reptreatmentid

	OPEN MyCursor
	FETCH NEXT FROM MyCursor INTO @RepTreatmentIdTmp

	WHILE @@FETCH_STATUS = 0
	BEGIN
		insert into #TmpAvcComm
		select 
				reptreatmentid
				,RepTreatmentDate
				,RT.repid
				,RT.RepRoleDesc
				,PeriodUnitQty = sum(PeriodUnitQty)
				,AvanceBrute = sum(case when PeriodAdvance >= 0 then PeriodAdvance else 0 end) 
				,RepriseAvance = sum(case when PeriodAdvance < 0 then PeriodAdvance else 0 end)
				,PeriodComm = sum(PeriodComm)
				,PeriodBusinessBonus = sum(PeriodBusinessBonus)
				,Adjustment = isnull(A.Adjustment,0)
				,Retenu = isnull(R.Retenu,0)
				,Advance = sum(CumAdvance)
				,FuturComm = sum(FuturComm) + sum(CumAdvance)
				
		from Un_Dn_RepTreatment RT
		left join (
			SELECT 
				C.RepID, -- ID du représentant
				RepRoleDesc = 'Représentant',--'REP', -- ID du rôle
				Adjustment = SUM(RepChargeAmount) -- Somme des ajustements
			FROM Un_RepCharge C 
			JOIN Un_RepChargeType CT ON CT.RepChargeTypeID = C.RepChargeTypeID AND (CT.RepChargeTypeComm <> 0)-- select * from Un_RepChargeType
			where RepTreatmentID = @RepTreatmentIdTmp
			GROUP BY
				C.RepID
				) A on RT.repid = A.repid and RT.RepRoleDesc = A.RepRoleDesc
		left join (
			SELECT 
				C.RepID, -- ID du représentant
				RepRoleDesc = 'Représentant',--'REP', -- ID du rôle
				Retenu = SUM(RepChargeAmount) -- Somme des retenus
			FROM Un_RepCharge C
			JOIN Un_RepChargeType CT ON CT.RepChargeTypeID = C.RepChargeTypeID AND CT.RepChargeTypeComm = 0
			where RepTreatmentID = @RepTreatmentIdTmp
			GROUP BY
				C.RepID
				) R on RT.repid = R.repid and RT.RepRoleDesc = R.RepRoleDesc
		where reptreatmentid = @RepTreatmentIdTmp
		group by reptreatmentid,RT.repid,RT.RepRoleDesc,RepTreatmentDate,isnull(A.Adjustment,0),isnull(R.Retenu,0)

		FETCH NEXT FROM MyCursor INTO @RepTreatmentIdTmp
	END
	CLOSE MyCursor
	DEALLOCATE MyCursor

	--select * from #TmpAvcComm where repid = 149653
--return


	SELECT 
		EachRepTreatmentID = Rt.RepTreatmentID,

		S.RepTreatmentID,
		S.RepId,
		S.RepName,
		Ac.RepRoleDesc,
		S.TreatmentYear,
		S.RepCode,
		S.RepTreatmentDate,
		Ac.PeriodUnitQty,
		--S.RepPeriodUnit,
		--S.DirPeriodUnit,
		S.RepConsPct,
		S.DirConsPct,

		Statut = 
			CASE
				WHEN R.BusinessEnd < @RepTreatmentDate THEN 'Inactif'
			ELSE 'Actif'
			END,
		FinActivite = R.BusinessEnd,
		Ac.AvanceBrute, 
		Ac.RepriseAvance,
		Ac.PeriodComm,
		Ac.PeriodBusinessBonus,

		Ac.Adjustment,
		Ac.Retenu,
		Ac.Advance,
		Ac.FuturComm,

		AvcSpec = isnull(AvcSpec.AvcSpec,0),
		AvcResil = isnull(AvcResil.AvcResil,0)
	into #TmpS
	FROM Un_Dn_RepTreatmentSumary S
	JOIN Un_Rep R ON S.RepId = R.RepID
	JOIN Un_RepTreatment RT on S.RepTreatmentDate = RT.RepTreatmentDate
	JOIN #TmpAvcComm  AC on S.repid = AC.RepId and S.RepTreatmentDate = AC.RepTreatmentDate

	left JOIN (
		-- Avance spéciale
		SELECT 
			RepID,
			RepTreatmentID,
			SUM(Amount) AS AvcSpec
		FROM Un_SpecialAdvance -- select * from Un_SpecialAdvance
		GROUP BY RepID ,RepTreatmentID
		) AvcSpec on AvcSpec.repid = S.repid and AvcSpec.RepTreatmentID = Rt.RepTreatmentID

	left JOIN (
		-- Avance sur résiliation
		SELECT 
			RepID,
			RepTreatmentID,
			SUM(RepChargeAmount) AS AvcResil
		FROM Un_RepCharge -- select * from Un_RepCharge
		WHERE RepChargeTypeID = 'AVR'  
		GROUP BY RepID,RepTreatmentID
		) AvcResil on AvcResil.repid = S.repid and AvcResil.RepTreatmentID = Rt.RepTreatmentID

	JOIN (
		SELECT 
			ReptreatmentID,
			RepID
		FROM Un_Dn_RepTreatment U
		-----
		UNION 
		-----
		SELECT 
			RepTreatmentID,
			RepID
		FROM Un_RepCharge
		) T ON S.RepTreatmentID = T.RepTreatmentID AND S.RepID = T.RepID
	LEFT JOIN (
		SELECT 
			REPID,
			reprole = max(rl.reprole)
		FROM UN_RepLevelHist RLH
		JOIN (
			SELECT 
				RepLevelID, 
				RepRole  = CASE WHEN reproleid = 'REP' THEN 0 ELSE 1 END 
			FROM un_replevel
			) RL ON RLH.replevelID = RL.replevelID
		WHERE ENDDATE IS NULL 
		GROUP BY RLH.REPID
			) RR ON RR.RepID = R.RepID
	WHERE (S.RepTreatmentID = @RepTreatmentID or (S.RepTreatmentID = @RepTreatmentIdPrec and S.RepTreatmentDate = @RepTreatmentDatePrec))
		AND S.RepID = COALESCE(@RepID, S.RepID)



	-- Avance Spéciale et Résiliation de la période 0
	update #TmpS
	set AvcSpec = #TSA.SpecialAdvance, AvcResil = #TSA.TerminatedAdvance
	from #TmpS
	join #TSA on #TmpS.repid = #TSA.repid and #TmpS.EachRepTreatmentID = @RepTreatmentIdPrec



	-- Variation des avances à couvrir
	alter table #TmpS add 
			VarAdvance float, 
			CommPct2 float, 
			FuturComNet float, 
			VarFuturComNet float, 
			NoPeriod integer,
			AvcSpecCum float,
			AvcResilCum float

	update s set VarAdvance = isnull(S.Advance,0) - isnull(S1.Advance,0)
	from #TmpS s
	left join #TmpS s1 on s1.repid = s.repid and s1.RepRoleDesc = s.RepRoleDesc and s1.EachRepTreatmentID = s.EachRepTreatmentID - 1

	-- Calcul : AvcSpecCum , AvcResilCum
	update s1 set AvcSpecCum = s2.AvcSpecCum, AvcResilCum = s2.AvcResilCum
	from #TmpS s1
	join (
		select
			s.Repid,s.EachRepTreatmentID,s.RepRoleDesc,
			AvcSpecCum = sum(s1.AvcSpec),
			AvcResilCum = sum(s1.AvcResil)
		from #TmpS s
		left join #TmpS s1 on s1.repid = s.repid and s.RepRoleDesc = s1.RepRoleDesc and s1.EachRepTreatmentID <= s.EachRepTreatmentID 
		group by s.Repid,s.EachRepTreatmentID,s.FuturComm,s.RepRoleDesc
		) s2 on s1.repid = s2.repid  and s1.RepRoleDesc = s2.RepRoleDesc and s1.EachRepTreatmentID = s2.EachRepTreatmentID


	-- Calcul : Com. à venir / Total avances
	update s1 set CommPct2 = s2.CommPct2
	from #TmpS s1
	join (
		select
			s.Repid,s.EachRepTreatmentID,s.RepRoleDesc,
			CommPct2 = case when s.FuturComm <> 0 then (sum(s1.AvcSpec) + sum(s1.AvcResil) + sum(s1.VarAdvance)) / s.FuturComm else 0 end
		from #TmpS s
		left join #TmpS s1 on s1.repid = s.repid and s.RepRoleDesc = s1.RepRoleDesc and s1.EachRepTreatmentID <= s.EachRepTreatmentID 
		group by s.Repid,s.EachRepTreatmentID,s.FuturComm,s.RepRoleDesc
		) s2 on s1.repid = s2.repid  and s1.RepRoleDesc = s2.RepRoleDesc and s1.EachRepTreatmentID = s2.EachRepTreatmentID


	-- Calcul FuturComNet

	update s1 set FuturComNet = s2.FuturComNet
	from #TmpS s1
	join (
		select
			s.Repid,s.EachRepTreatmentID,s.RepRoleDesc,
			FuturComNet = s.FuturComm - (sum(s1.AvcSpec) + sum(s1.AvcResil) + sum(s1.VarAdvance))  
		from #TmpS s
		left join #TmpS s1 on s1.repid = s.repid and s1.RepRoleDesc = s.RepRoleDesc and s1.EachRepTreatmentID <= s.EachRepTreatmentID 
		group by s.Repid,s.EachRepTreatmentID,s.FuturComm,s.RepRoleDesc
		) s2 on s1.repid = s2.repid  and s1.RepRoleDesc = s2.RepRoleDesc and s1.EachRepTreatmentID = s2.EachRepTreatmentID


	-- Calcul de variation de FuturComNet
	update s set VarFuturComNet = isnull(S.FuturComNet,0) - isnull(S1.FuturComNet,0)
	from #TmpS s
	left join #TmpS s1 on s1.repid = s.repid  and s1.RepRoleDesc = s.RepRoleDesc and s1.EachRepTreatmentID = s.EachRepTreatmentID - 1

	-- Calcul du no de période
	update s1 set NoPeriod = s2.NoPeriod
	from #TmpS s1
	join (
		select
			s.Repid,s.EachRepTreatmentID,s.RepRoleDesc,
			NoPeriod = count(*) - 1
		from #TmpS s
		left join #TmpS s1 on s1.repid = s.repid and s1.RepRoleDesc = s.RepRoleDesc and s1.EachRepTreatmentID <= s.EachRepTreatmentID 
		group by s.Repid,s.EachRepTreatmentID,s.RepRoleDesc
		) s2 on s1.repid = s2.repid  and s1.RepRoleDesc = s2.RepRoleDesc and s1.EachRepTreatmentID = s2.EachRepTreatmentID

	-- Les valeurs suivantes sont vides pour la période 0
	update #TmpS set  
		PeriodUnitQty = 0,
		--RepPeriodUnit = 0,
		--DirPeriodUnit = 0,
		AvanceBrute = 0,
		PeriodComm = 0, --CommANDBonus = 0,
		RepriseAvance = 0,
		Retenu = 0,
		Adjustment = 0,
		PeriodBusinessBonus = 0
	where NoPeriod = 0

	-- Effacer les avances sur résiliation et spéciale pour les Représentant qui sont directeur
	-- NB : les avances sur résiliation et spéciale sont inscrite pour un Rep sans dicernement qu'il est rep ou directeur.
	-- alors on met ces montant dans sa section "Directeur"
	update #TmpS
	set AvcResil = 0,
		AvcSpec = 0
	where 
		repid in (select repid from #TmpS where RepRoleDesc = 'Directeur') 
		and RepRoleDesc <> 'Directeur'


	-- La période demandée. pour mettre dans le titre du rapport
	Select @Periode = max(NoPeriod) from #TmpS 

	Select 
		total = 0,
		DateFrom = @RepTreatmentDateFrom,
		Periode = @Periode,
		NoPeriod,
		EachRepTreatmentID,
		RepTreatmentID,
		RepId,
		RepRoleDesc,
		RepName,
		Statut,
		FinActivite,
		TreatmentYear,
		RepCode,
		RepTreatmentDate,
		--PeriodUnitQty,
		RepPeriodUnit = case when RepRoleDesc = 'Représentant' then PeriodUnitQty else 0 end ,
		DirPeriodUnit = case when RepRoleDesc <> 'Représentant' then PeriodUnitQty else 0 end ,
		RepConsPct,
		DirConsPct,
		AvanceBrute,
		PeriodComm,
		RepriseAvance,
		Retenu,
		Adjustment,
		PeriodBusinessBonus,
		Advance,
		VarAdvance,
		AvcResil,
		AvcResilCum,
		AvcSpec,
		AvcSpecCum,
		VarFuturComNet,
		FuturComm
	from #TmpS	

	UNION

	-- Ajouter un total de tous les rôles
	Select 
		total = 1,
		DateFrom = @RepTreatmentDateFrom,
		Periode = @Periode,
		NoPeriod,
		EachRepTreatmentID,
		RepTreatmentID,
		RepId,
		RepRoleDesc = 'Tous les rôles',
		RepName,
		Statut,
		FinActivite,
		TreatmentYear,
		RepCode,
		RepTreatmentDate,
		--PeriodUnitQty,
		RepPeriodUnit = sum(case when RepRoleDesc = 'Représentant' then PeriodUnitQty else 0 end ),
		DirPeriodUnit = sum(case when RepRoleDesc <> 'Représentant' then PeriodUnitQty else 0 end ),
		RepConsPct,
		DirConsPct,
		AvanceBrute = sum(AvanceBrute),
		PeriodComm = sum(PeriodComm),
		RepriseAvance = sum(RepriseAvance),
		Retenu = sum(Retenu),
		Adjustment  = sum(Adjustment) ,
		PeriodBusinessBonus = sum(PeriodBusinessBonus),
		Advance = sum(Advance),
		VarAdvance = sum(VarAdvance),
		AvcResil = sum(AvcResil),
		AvcResilCum = sum(AvcResilCum),
		AvcSpec = sum(AvcSpec),
		AvcSpecCum = sum(AvcSpecCum),
		VarFuturComNet = sum(VarFuturComNet),
		FuturComm = sum(FuturComm)
	from #TmpS	
	group by
		NoPeriod,
		EachRepTreatmentID,
		RepTreatmentID,
		RepId,
		RepName,
		Statut,
		FinActivite,
		TreatmentYear,
		RepCode,
		RepTreatmentDate,
		RepConsPct,
		DirConsPct
	having count(*) > 1 -- seulement pour les rep qui ont plus qu'un rôle
	order by
		Statut,
 		RepRoleDesc,
		RepName,
		EachRepTreatmentID







	SET @dtEnd = GETDATE()
	SELECT @siTraceReport = siTraceReport FROM Un_Def

	IF DATEDIFF(SECOND, @dtBegin, @dtEnd) > @siTraceReport
		-- Insère une trace de l'ewxécution si la durée de celle-ci a dépassé le temps minimum défini dans Un_Def.siTraceReport.
		INSERT INTO Un_Trace (
				ConnectID, -- ID de connexion de l’usager
				iType, -- Type de trace (1 = recherche, 2 = rapport)
				fDuration, -- Temps d’exécution de la procédure
				dtStart, -- Date et heure du début de l’exécution.
				dtEnd, -- Date et heure de la fin de l’exécution.
				vcDescription, -- Description de l’exécution (en texte)
				vcStoredProcedure, -- Nom de la procédure stockée
				vcExecutionString ) -- Ligne d’exécution (inclus les paramètres)
			SELECT
				@ConnectID,
				2,
				DATEDIFF(MILLISECOND, @dtBegin, @dtEnd)/1000,
				@dtBegin,
				@dtEnd,
				'Rapport sommaire des commissions',
				'RP_UN_RepTreatmentSumary',
				'EXECUTE RP_UN_RepTreatmentSumary @ConnectID = '+CAST(@ConnectID AS VARCHAR)+
					', @RepTreatmentID = '+CAST(@RepTreatmentID AS VARCHAR)+
					', @RepID = '+CAST(isnull(@RepID,0) AS VARCHAR)
END



