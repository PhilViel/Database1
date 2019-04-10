/********************************************************************************************************************
Copyrights (c) 2009 Gestion Universitas Inc.
Nom                 :	RP_UN_CommForAccounting_FromTo
Description         :	PROCEDURE DU RAPPORT DES COMMISSIONS POUR ÉCRITURE COMPTABLE pour traitement de la paie (fait à partir de RP_UN_CommForAccounting_FromTo)
Valeurs de retours  :	dataset
Note                :	2011-06-08	Donald Huppé	Création à partir de RP_UN_CommForAccounting_FromTo
						**** La sp originale était concue pour une plage de traitement mais ici, on ne prend que 1 traitement.
						toutefois, pour ne pas refaire la sp au complet, je prend un seul traitement en paramètre mais je le met dans 
						les variables (anciens paramètres) @RepTreatmentIDFrom et @RepTreatmentIDTo
						
						2011-10-24	Donald Huppé			GLPI	233 
															Et Modification de l'accès aux données de Greatplains (COMDiff)
						2011-11-03	Donald Huppé			GLPI 6311			
						2012-11-29	Donald Huppé	glpi	8643 - Ajout du role DCC pour les directeurs, afin d'afficher Thérèse Coupal dans les directeurs	
						2013-05-01	Donald Huppé			GLPI 9570 : mettre  « Agence Nouveau Brunswick #7910 » dans Autre		
						2013-05-13	Donald Huppé			GLPI 9571 : Ne plus afficher les rep (comme Groupe CGL #50003 ) dont tous les montants sont à zéro.
						2015-12-01	Donald Huppé			glpi 16134 : ajout de RepCodeNumber
                        2016-06-09  Pierre-Luc Simard       Ajout des COMFIX et renommer la table tblTEMP_GreatPlainsCOMDIF pour tblREPR_CumulatifsGreatPlains
						2018-10-05	Donald Huppé			Ajout de DUIPAD (jira prod-12208)
					
exec RP_UN_CommForAccounting_PourTraitementDePaie 1, 713, 3, 'Nom'
select * from Un_RepTreatment
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_CommForAccounting_PourTraitementDePaie] (
	@ConnectID INTEGER,
	@RepTreatmentID INTEGER,
	@RepActivite INTEGER,   -- 1 = actif, 2 = Inactif, 3 = Tous
	@Tri varchar(5)) -- 'Code' = Code du Rep, 'Nom' = Nom de famille du rep
	
--WITH EXECUTE AS 'sa'
	
AS
BEGIN

	DECLARE @RepTreatmentIDFrom INT
	DECLARE @RepTreatmentIDTo INT
	
	SET @RepTreatmentIDFrom = @RepTreatmentID
	SET @RepTreatmentIDTo = @RepTreatmentID
	
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

/*
	-- lorsque ce sera possible via SSRS, on fera ceci :
	CREATE table #GreatPlainsCOMDIF (RepCode varchar(75), Lastname varchar(50), FirstName varchar(35), ComDif float)
	INSERT INTO #GreatPlainsCOMDIF --VALUES ('1','','',0)
		EXEC GUI.[dbo].psGP_ObtenirCumCOMDIF @RepTreatmentDateTo
*/
	create table #RepTreatmentTerminatedAndSpecialAdvance(
		SpecialAdvance FLOAT,
		TerminatedAdvance FLOAT,
		Advances FLOAT,
		CalcAdvances FLOAT,
		FuturComs FLOAT,
		CommPcts FLOAT,
		CalcCommPcts FLOAT,
		RepID INTEGER
		)
	insert into #RepTreatmentTerminatedAndSpecialAdvance
	exec RP_UN_RepTreatmentTerminatedAndSpecialAdvance @ConnectID,0,@RepTreatmentIDTo

	-- Retrouve les dossiers qui seront affichés dans le rapport
	SELECT
		S.RepTreatmentID,
		S.RepTreatmentDate,
		Statut = CASE WHEN R.BusinessEnd < RT.RepTreatmentDate THEN 'Inactif' ELSE 'Actif' END,
		DirOrRep = CASE -- si on demande un tri par nom alors on fait un groupe dir et rep dans le rapport
				
				WHEN R.RepCode NOT IN ('0000','6141','7910') and RD.RepID is not null and @Tri = 'Nom' THEN '1' -- 'DIR' 
				WHEN R.RepCode NOT IN ('0000','6141','7910') and RD.RepID is null and @Tri = 'Nom' THEN '3' -- 'REP'
				WHEN R.RepCode IN ('0000','6141','7910') and @Tri = 'Nom' THEN '2'  -- Autre
				
				else 'ND'
				END, 
		S.RepID,
		R.RepCode,
		S.RepName,
		RepNomFamille = HR.Lastname + ' ' + HR.FirstName,
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
	FROM Un_Dn_RepTreatmentSumary S -- select * from Un_Dn_RepTreatmentSumary where reptreatmentid = 445 and dirperiodunit > 0
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
	LEFT JOIN (
		SELECT distinct
			rlh.repid
		FROM Un_RepLevelHist RLH
		join Un_RepLevel RL ON RLH.RepLevelID = RL.RepLevelID 
		where RL.RepRoleID IN( 'DIR','CAB','DEV','DCC') --glpi 8643 (DCC)
			AND @RepTreatmentDateFrom BETWEEN RLH.StartDate AND isnull(RLH.EndDate,'3000-01-01')
		)RD on RD.RepID = R.RepID 
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

	--SELECT * from #TmpCommForAccounting order BY repname
	--return

	-- Les champs dont on veut la somme pour tous les traitement
	select
		Statut,
		DirOrRep,
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
		DirOrRep,
		RepID,
		RepCode,
		RepName,
		RepNomFamille,
		BusinessEnd

	-- Les champs dont on veut les valeurs pour le dernier traitement
	select
		Statut,
		DirOrRep,
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
		DirOrRep,
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
	INTO #TmpFinal
	from (
		select * from #TmpSum
		UNION ALL
		select * from #TmpLast
		) V
	left join (select RepInatif = repid from #TmpSum group by repid having count(*) > 1) Rep on V.repid = Rep.RepInatif
	group by
		Statut,
		DirOrRep,
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
	
	SELECT 
		compteur = row_number() OVER(PARTITION BY  t.Repcode,T.repname ORDER BY t.Repcode,T.repname),
		T.*,
		TT.FuturComs,
		TT.CalcCommPcts,
		Ret.RetenuType,
		Ret.RetenuDesc,
		Ret.RetenuMontant,
		Aj.AjustementType,
		Aj.AjustementDesc,
		Aj.AjustementMontant,
		COMDIF = ISNULL(CD.COMDIF, 0),
        COMFIX = ISNULL(CD.COMFIX, 0),
		DUIPAD = ISNULL(CD.DUIPAD, 0)
		
	into #FinalWithNoDuplicate
	FROM 
		#TmpFinal T
		LEFT JOIN #RepTreatmentTerminatedAndSpecialAdvance TT ON T.repID = TT.RepID
		--LEFT JOIN #GreatPlainsCOMDIF CD ON T.RepCode = CD.RepCode
		LEFT JOIN tblREPR_CumulatifsGreatPlains CD ON T.RepCode = CD.RepCode AND CD.RepTreatmentID = @RepTreatmentIDTo
		LEFT JOIN (-- Retenu
			SELECT 
				C1.RepID, -- ID du représentant
				RetenuType = C1.RepChargeTypeID, -- ID du type de charge.
				RetenuDesc = C1.RepChargeDesc,
				RetenuMontant = SUM(RepChargeAmount) -- Somme des retenus
			FROM Un_RepCharge C1 
			JOIN Un_RepChargeType CT1 ON CT1.RepChargeTypeID = C1.RepChargeTypeID AND CT1.RepChargeTypeComm = 0
			WHERE C1.RepTreatmentID = @RepTreatmentIDTo
			GROUP BY
				C1.RepID,
				C1.RepChargeTypeID, -- ID du type de charge.
				C1.RepChargeDesc
			)Ret ON T.repID = Ret.RepID
		LEFT JOIN (-- Ajustement
			SELECT 
				C2.RepID, -- ID du représentant
				AjustementType = C2.RepChargeTypeID, -- ID du type de charge.
				AjustementDesc = C2.RepChargeDesc,
				AjustementMontant = SUM(RepChargeAmount) -- Somme des retenus
			FROM Un_RepCharge C2 
			JOIN Un_RepChargeType CT2 ON CT2.RepChargeTypeID = C2.RepChargeTypeID AND CT2.RepChargeTypeComm <> 0
			WHERE C2.RepTreatmentID = @RepTreatmentIDTo
			GROUP BY
				C2.RepID,
				C2.RepChargeTypeID, -- ID du type de charge.
				C2.RepChargeDesc
			)Aj ON T.repID = Aj.RepID
		order by 
			case 
				when @Tri = 'Code' then T.RepCode
				when @Tri = 'Nom' then RepNomFamille
				else T.repcode
			end
		
	-- on enlève les montants dupliqué afin d'avoir des totaux exact
	-- Le problème vient du fait qu'on veut afficher les descriptions données pas les champs AjustementDesc et RetenuDesc et cela créé des doublons
	update #FinalWithNoDuplicate 
	set 
		RepName = '',
		Statut = '',
		NewAdvance = 0,
		CommAndBonus = 0,
		Adjustment = 0,
		Retenu = 0,
		ChqNet = 0,
		COMDIF = 0,
        COMFIX = 0,
		DUIPAD = 0,
		Advance= 0,
		TerminatedAdvance = 0,
		SpecialAdvance = 0,
		TotalAdvance = 0,
		CoveredAdvance = 0,
		FuturComs = 0,
		CalcCommPcts = 0
	where compteur > 1

	SELECT 
	
		compteur,
			
		ReptreatmentDateFrom,
		ReptreatmentDateTo,
		RepTreatmentIDFrom,
		RepTreatmentIDTo,
		Statut,
		DirOrRep,
		RepID,
		RepCode,
		RepName,
		RepNomFamille,
		BusinessEnd,
		NewAdvance,	
		CommAndBonus,
		Adjustment,
		Retenu,
		ChqNet,

		Advance,	
		TerminatedAdvance,
		SpecialAdvance,
		TotalAdvance,

		CoveredAdvance,
		CommissionFee,
		FuturComs,
		CalcCommPcts,
		RetenuType,
		RetenuDesc,
		RetenuMontant,
		AjustementType,
		AjustementDesc,
		AjustementMontant,
		COMDIF,
        COMFIX,	
		DUIPAD, 
		RepCodeNumber = case when ISNUMERIC(repcode) = 1 THEN CAST(repcode as int) else null end

	from #FinalWithNoDuplicate
	
	where not(-- glpi 9571
		NewAdvance = 0 and
		CommAndBonus = 0 and
		Adjustment = 0 and
		Retenu = 0 and
		ChqNet = 0 and
		Advance= 0 and
		TerminatedAdvance = 0 and
		SpecialAdvance = 0 and
		TotalAdvance = 0 and
		CoveredAdvance = 0 and
		FuturComs = 0 and
		CalcCommPcts = 0 AND 
        COMDIF = 0 AND 
        COMFIX = 0 AND
		DUIPAD = 0
		)
	
END


