/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas Inc.
Nom                 :	RP_UN_CommForAccounting_FromTo
Description         :	PROCEDURE DU RAPPORT DES COMMISSIONS POUR ÉCRITURE COMPTABLE par palge de traitement
Valeurs de retours  :	dataset
Note                :	2009-09-24	Donald Huppé	Création	
						2011-03-17	Donald Huppé	Ajout de tri (glpi 5229)
					
exec RP_UN_CommForAccounting_FromTo 1, 327, 359, 1, 'Nom'
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_CommForAccounting_FromTo] (
	@ConnectID INTEGER,
	@RepTreatmentIDFrom INTEGER,-- Numéro du traitement des commissions De
	@RepTreatmentIDTo INTEGER, -- Numéro du traitement des commissions À
	@RepActivite INTEGER,   -- 1 = actif, 2 = Inactif, 3 = Tous
	@Tri varchar(5)) -- 'Code' = Code du Rep, 'Nom' = Nom de famille du rep
AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT

	SET @dtBegin = GETDATE()

	DECLARE @RepTreatmentDateFrom MoDate
	DECLARE @RepTreatmentDateTo MoDate
	
	-- Lecture de la date du premier traitement choisi
	SELECT @RepTreatmentDateFrom = RepTreatmentDate
	FROM Un_Reptreatment
	WHERE RepTreatmentID = @RepTreatmentIDFrom
	
	-- Lecture de la date du dernier traitement choisi
	SELECT @RepTreatmentDateTo = RepTreatmentDate
	FROM Un_Reptreatment
	WHERE RepTreatmentID = @RepTreatmentIDTo

	-- Retrouve les dossiers qui seront affichés dans le rapport
	SELECT
		S.RepTreatmentID,
		S.RepTreatmentDate,
		Statut = CASE WHEN R.BusinessEnd < RT.RepTreatmentDate THEN 'Inactif' ELSE 'Actif' END,
		S.RepID,
		R.RepCode,
		S.RepName,
		RepNomFamille = HR.Lastname,
		S.NewAdvance,	
		S.CommAndBonus,
		S.Adjustment,
		S.Retenu,
		S.ChqNet,
		S.Advance,	
		TerminatedAdvance = ISNULL(AVR.AVRAmount,0) ,
		SpecialAdvance = ISNULL(SA.Amount,0) ,
		TotalAdvance = ISNULL(S.Advance,0) + ISNULL(SA.Amount,0) + ISNULL(AVR.AVRAmount,0) ,
		S.CoveredAdvance,
		CommissionFee = S.CommAndBonus + S.Adjustment + S.CoveredAdvance,
		BusinessEnd =
			CASE 
				WHEN R.BusinessEnd >= RT.RepTreatmentDate THEN NULL
			ELSE R.BusinessEnd
			END
	into #TmpCommForAccounting
	FROM Un_Dn_RepTreatmentSumary S -- select * from Un_Dn_RepTreatmentSumary
	JOIN Un_Rep R ON S.RepId = R.RepID
	JOIN dbo.Mo_Human HR on S.RepID = HR.HumanID
	JOIN (-- Retrouve tous les représentants ayant eu des commissions de chaque traitement de l'année à ce jour 
					SELECT DISTINCT
						ReptreatmentID,
						RepID
					FROM Un_Dn_RepTreatment 
					-----
					UNION
					-----
					-- Retrouve aussi tous les représentants ayant eu des charges de chaque traitement des commissions de l'année à ce jour 
					SELECT DISTINCT
						RepTreatmentID,
						RepID
					FROM Un_RepCharge
				) T 
		ON S.RepTreatmentID = T.RepTreatmentID 
		AND S.RepID = T.RepID
	JOIN Un_RepTreatment RT 
		ON RT.RepTreatmentID = S.RepTreatmentID 
		AND RT.RepTreatmentDate = S.RepTreatmentDate
	LEFT JOIN (-- Retrouve les montants d'avances sur résiliations par représentant 
				SELECT
					RepID,
					AVRAmount = SUM(RepChargeAmount)
				FROM Un_RepCharge
				WHERE RepChargeTypeID = 'AVR'
					AND RepChargeDate <= @RepTreatmentDateTo
				GROUP BY RepID
			) AVR 
		ON AVR.RepID = S.RepID
	LEFT JOIN (-- Retrouve les montants d'avance spéciale par représentants 
				SELECT
					RepID,
					Amount = SUM(Amount)
				FROM Un_SpecialAdvance
				WHERE EffectDate <= @RepTreatmentDateTo
				GROUP BY RepID
			) SA 
		ON SA.RepID = S.RepID
	WHERE RT.RepTreatmentID between @RepTreatmentIDFrom and @RepTreatmentIDTo
	and (
		(@RepActivite = 1 and (ISNULL(R.BusinessEnd,'3000-01-01') >= RT.RepTreatmentDate))
			or
		(@RepActivite = 2 and (ISNULL(R.BusinessEnd,'3000-01-01') < RT.RepTreatmentDate))
			or 
		(@RepActivite = 3)
		)
	ORDER BY
		R.RepCode,
		RepName,
		S.RepID,
		S.RepTreatmentDate,
		S.RepTreatmentID

	-- Les champs dont on veut la somme pour tous les traitement
	select
		Statut,
		RepID,
		RepCode,
		RepName,
		RepNomFamille,
		NewAdvance = sum(NewAdvance),	
		CommAndBonus = sum(CommAndBonus),
		Adjustment = sum(Adjustment),
		Retenu = sum(Retenu),
		ChqNet = sum(ChqNet),
		Advance = 0,	
		TerminatedAdvance = 0,
		SpecialAdvance = 0,
		TotalAdvance = 0,
		CoveredAdvance = sum(CoveredAdvance),
		CommissionFee = sum(CommissionFee),
		BusinessEnd
	into #TmpSum
	from #TmpCommForAccounting
	group by
		Statut,
		RepID,
		RepCode,
		RepName,
		RepNomFamille,
		BusinessEnd

	-- Les champs dont on veut les valeurs pour le dernier traitement
	select
		Statut,
		RepID,
		RepCode,
		RepName,
		RepNomFamille,
		NewAdvance = 0,	
		CommAndBonus = 0,
		Adjustment = 0,
		Retenu = 0,
		ChqNet = 0,
		Advance,	
		TerminatedAdvance,
		SpecialAdvance,
		TotalAdvance,
		CoveredAdvance = 0,
		CommissionFee = 0,
		BusinessEnd
	into #TmpLast
	from #TmpCommForAccounting
	where RepTreatmentID = @RepTreatmentIDTo

	SELECT @RepTreatmentDateFrom = RepTreatmentDate
	FROM Un_Reptreatment
	WHERE RepTreatmentID = @RepTreatmentIDFrom

	select
		ReptreatmentDateFrom = @RepTreatmentDateFrom,
		ReptreatmentDateTo = @RepTreatmentDateTo,
		RepTreatmentIDFrom = @RepTreatmentIDFrom,
		RepTreatmentIDTo = @RepTreatmentIDTo,
		Statut,
		RepID,
		RepCode,
		RepName = RepName + case 
					when Statut = 'Actif' and @RepActivite = 3 then ' (a)' 
					when Statut = 'Inactif' and @RepActivite = 3 then ' (i)' 
					else '' end,
		RepNomFamille,
		BusinessEnd,
		--Rep.RepInatif,
		NewAdvance = sum(NewAdvance),	
		CommAndBonus = sum(CommAndBonus) ,
		Adjustment = sum(Adjustment),
		Retenu = sum(Retenu),
		ChqNet = sum(ChqNet) ,
		-- Dans le cas où un rep passe de actif à inactif pendant les période demandé, inscrire des montants dans la groupe inactif
		Advance = case when Rep.RepInatif is not null and Statut = 'Actif' then 0 else sum(Advance) end,	
		TerminatedAdvance = case when Rep.RepInatif is not null and Statut = 'Actif' then 0 else sum(TerminatedAdvance) end,
		SpecialAdvance = case when Rep.RepInatif is not null and Statut = 'Actif' then 0 else sum(SpecialAdvance) end,
		TotalAdvance = case when Rep.RepInatif is not null and Statut = 'Actif' then 0 else sum(TotalAdvance) end,
		---------------------------------------------------------------------------------------------------------------
		CoveredAdvance = sum(CoveredAdvance),
		CommissionFee = sum(CommissionFee)
	from (
		select * from #TmpSum
		UNION ALL
		select * from #TmpLast
		) V
	left join (select RepInatif = repid from #TmpSum group by repid having count(*) > 1) Rep on V.repid = Rep.RepInatif
	group by
		Statut,
		RepID,
		RepCode,
		RepName,
		RepNomFamille,
		BusinessEnd,
		Rep.RepInatif
	order by 
		case 
			when @Tri = 'Code' then RepCode
			when @Tri = 'Nom' then RepNomFamille
			else repcode
		end
		--RepCode,
		--RepName
	
	SET @dtEnd = GETDATE()
	SELECT @siTraceReport = siTraceReport FROM Un_Def

	IF DATEDIFF(SECOND, @dtBegin, @dtEnd) > @siTraceReport
	BEGIN
		-- Insère un log de l'objet inséré.
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
				DATEDIFF(SECOND, @dtBegin, @dtEnd),
				@dtBegin,
				@dtEnd,
				'Rapport des commissions pour la comptabilité selon le numéro de traitement '+CAST(@RepTreatmentIDTo AS VARCHAR),
				'RP_UN_CommForAccounting_FromTo',
				'EXECUTE RP_UN_CommForAccounting @ConnectID ='+CAST(@ConnectID AS VARCHAR)+
				', @RepTreatmentID ='+CAST(@RepTreatmentIDTo AS VARCHAR)			
	END	
END


