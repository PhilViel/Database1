/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************   */
/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	GU_RP_SuiviRep 
Description         :	Rapport Statistique des ventes et taux de conservation des 12 dernier mois
Valeurs de retours  :	Dataset 
Note                :		2009-06-10	Donald Huppé			Créaton
							2009-10-21	Donald Huppé			Modification pour ajuster la date demandée à la fin du mois (ex : si on demande 2009-10-20 alors cette date devient 2009-10-31)
							2010-04-29	Donald Huppé			GLPI 3343 - Modification pour 2010
							2013-04-19	Pierre-Luc Simard	    Vider les tables tblTEMP_SuiviRep (anciennement TMPsuiviRep) et tblTEMP_SuiviRepUnit (anciennement TMPGrossANDNetUnitsU) au lieu de les supprimer et les refaire
                            2018-10-29  Pierre-Luc Simard       N'est plus utilisé
exec GU_RP_SuiviRep '2013-03-31'
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[GU_RP_SuiviRep] (
	@EndDate DATETIME) -- Date de fin (doit être une date de fin de mois)
AS
BEGIN

SELECT 1/0
/*
	DECLARE

		@FromDate DATETIME,
		@FirstOfMonth DATETIME,
		@ToDate DATETIME,
		@i INTEGER,
		@DaysInMonth INTEGER,
		@FirstCons varchar(5),
		@LastCons varchar(5),
		@NbOfMonthWithData integer,
		@MySql varchar(5000)

	--if exists(select name from sysobjects where name = 'TMPsuiviRep')
	--	drop table TMPsuiviRep
	TRUNCATE TABLE tblTEMP_SuiviRep
	
	--if exists(select name from sysobjects where name = 'TMPGrossANDNetUnitsU')
	--	drop table TMPGrossANDNetUnitsU
	TRUNCATE TABLE tblTEMP_SuiviRepUnit

	---------------- 2009-10-21 ----------------------
	-- Au cas où la date demandée n'est pas une date de fin de mois, on l'ajuste à la fin du mois de la date demandée
	set @DaysInMonth = CASE WHEN MONTH(@EndDate) IN (1, 3, 5, 7, 8, 10, 12) THEN 31
					WHEN MONTH(@EndDate) IN (4, 6, 9, 11) THEN 30
					ELSE CASE WHEN (YEAR(@EndDate) % 4    = 0 AND
									YEAR(@EndDate) % 100 != 0) OR
								   (YEAR(@EndDate) % 400  = 0)
							  THEN 29
							  ELSE 28
						 END
			   END
	set @EndDate = cast(year(@EndDate) as varchar(4)) + '-' + cast(month(@EndDate) as varchar(2)) + '-' + cast(@DaysInMonth as varchar(2))
	--------------------------------------------------

	set @FromDate = dateadd(mm,-1,dateadd(yy,-1,@EndDate))

/*		create table tblTEMP_SuiviRep (
		repid INTEGER, 
		repcode VARCHAR(75), 
		firstname VARCHAR(35),
		lastname VARCHAR(35),
		DIRfirstname VARCHAR(35),
		DIRlastname VARCHAR(35),
		businessstart DATETIME, 
		FirstDateSale DATETIME,
		NbMois INTEGER,
		RepVille varchar(100),
		CM0 FLOAT, -- NE SERT PLUS À PARTIR DE 2010
		CM1 FLOAT, -- POUR LES TAUX DE CONSERVATION À LA FIN DE CHAQUE MOIS
		RM1 FLOAT, -- Résilitation pendant le mois qui se termine
		CM2 FLOAT,
		RM2 FLOAT,
		CM3 FLOAT,
		RM3 FLOAT,
		CM4 FLOAT,
		RM4 FLOAT,
		CM5 FLOAT,
		RM5 FLOAT,
		CM6 FLOAT,
		RM6 FLOAT,
		CM7 FLOAT,
		RM7 FLOAT,
		CM8 FLOAT,
		RM8 FLOAT,
		CM9 FLOAT,
		RM9 FLOAT,
		CM10 FLOAT,
		RM10 FLOAT,
		CM11 FLOAT,
		RM11 FLOAT,
		CM12 FLOAT,
		RM12 FLOAT,
		YearBrut FLOAT, -- Depuis le début de l'année (1er janvier de l'année en cours)
		YearRetrait FLOAT,
		YearReinsc FLOAT,
		YearNet FLOAT,
		YearAvgRetrait FLOAT,
		Month24Brut FLOAT, -- Depuis 24 mois
		Month24Retrait FLOAT,
		Month24Reinsc FLOAT,
		Month24Net FLOAT,
		Month24AvgRetrait FLOAT,
		DiffCons FLOAT,
		NM1 FLOAT, -- NM1 à 12 : POUR LES NET PAR MOIS des 12 derniers mois (sert seulement au calcul des champs mois3, mois6, mois12 et AVGmois.  Sauf NM12 qui sert pour dernier mois)
		NMUniv1 FLOAT,
		NMRflex1 FLOAT,
		NM2 FLOAT,
		NMUniv2 FLOAT,
		NMRflex2 FLOAT,
		NM3 FLOAT,
		NMUniv3 FLOAT,
		NMRflex3 FLOAT,
		NM4 FLOAT,
		NMUniv4 FLOAT,
		NMRflex4 FLOAT,
		NM5 FLOAT,
		NMUniv5 FLOAT,
		NMRflex5 FLOAT,
		NM6 FLOAT,
		NMUniv6 FLOAT,
		NMRflex6 FLOAT,
		NM7 FLOAT,
		NMUniv7 FLOAT,
		NMRflex7 FLOAT,
		NM8 FLOAT,
		NMUniv8 FLOAT,
		NMRflex8 FLOAT,
		NM9 FLOAT,
		NMUniv9 FLOAT,
		NMRflex9 FLOAT,
		NM10 FLOAT,
		NMUniv10 FLOAT,
		NMRflex10 FLOAT,
		NM11 FLOAT,
		NMUniv11 FLOAT,
		NMRflex11 FLOAT,
		NM12 FLOAT,
		NMUniv12 FLOAT,
		NMRflex12 FLOAT,

		moisLastPctUniv FLOAT,
		moisLastPctRflex FLOAT,

		mois3 FLOAT,
		mois3PctUniv FLOAT,
		mois3PctRflex FLOAT,
		mois3Resil FLOAT,
		mois6 FLOAT,
		mois6PctUniv FLOAT,
		mois6PctRflex FLOAT,
		mois6Resil FLOAT,
		mois12 FLOAT,
		mois12PctUniv FLOAT,
		mois12PctRflex FLOAT,
		mois12Resil FLOAT,
		AVGmois FLOAT )

	create table tblTEMP_SuiviRepUnit (
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
*/

	INSERT INTO tblTEMP_SuiviRep(
		repid, 
		repcode, 
		firstname,
		lastname,
		DIRfirstname,
		DIRlastname,
		businessstart, 
		FirstDateSale,
		NbMois,
		RepVille)

	select 
		r.repid, 
		r.repcode, 
		h.firstname, 
		h.lastname,
		DIRfirstname = HDIR.firstname,
		DIRlastname = HDIR.lastname,
		businessstart = convert(char(10),r.businessstart,126), 
		FirstDateSale = FD.FirstDeposit,
		DateDiff(mm,r.businessstart,@EndDate),
		RepVille = arep.city 
	from un_rep r
	JOIN dbo.mo_human h on r.repid = h.humanid
	JOIN dbo.Mo_Adr arep on h.adrid = arep.adrid
	join (
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
					AND (StartDate <= GETDATE())
					AND (EndDate IS NULL OR EndDate >= GETDATE())
				GROUP BY
					  RepID
				) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
		  WHERE RB.RepRoleID = 'DIR'
				AND RB.StartDate IS NOT NULL
				AND (RB.StartDate <= GETDATE())
				AND (RB.EndDate IS NULL OR RB.EndDate >= GETDATE())
		  GROUP BY
				RB.RepID
	) RepDIR on r.repID = RepDIR.RepID
	join Un_Rep DIR on RepDIR.BossID = DIR.RepId
	JOIN dbo.Mo_human HDIR on DIR.repid = HDIR.humanid
	left join (
		select Repid, FirstDeposit = min(dtfirstdeposit) FROM dbo.Un_Unit group by Repid
		) FD on FD.RepID = r.repid

	where r.businessstart <= @EndDate
		and isnull(r.BusinessEnd,'3000-01-01') >= @EndDate

	------------------------------------------------------------------------------------------
	-- CALCUL DU TAUX DE CONSERVATION À LA FIN DE CHAQUE MOIS
	-- CALCUL DU TOTAL DES RETRAIT PAR MOIS
	-- Début du CALCUL Des Net de chaque mois pour les 12 derniers mois avant la date demandé
	------------------------------------------------------------------------------------------

	set @i = 0
	while DATEADD(mm, DATEDIFF(mm,0,@EndDate) -12 + @i, 0) < @EndDate --dateadd(mm,@i,@FromDate) < @EndDate
	begin

		TRUNCATE TABLE tblTEMP_SuiviRepUnit

		-- Début du mois
		set @FirstOfMonth = DATEADD(mm, DATEDIFF(mm,0,@EndDate) -12 + @i, 0) 
		
		-- Fin du mois
		set @ToDate = dateadd(dd,-1,dateadd(mm,1,@FirstOfMonth))

		-- Les données des Rep
		INSERT tblTEMP_SuiviRepUnit
		EXEC SL_UN_RepGrossANDNetUnits NULL, @FirstOfMonth, @ToDate ,0 ,1

		-- Résultat final

		set @MySql = '

			update SR 
			set CM' +  cast(@i as varchar(2))  + ' = RP.ConsPct ' 
			+ case when @i > 0 then ', RM' + cast(@i as varchar(2)) + ' = RP.Resil'    else ' ' end

			-- Début du CALCUL du total Net de chaque mois pour les 12 dernier mois avant la date demandé
			+ case when @i > 0 then ', NM' + cast(@i as varchar(2)) + ' = RP.Net'    else ' ' end

			-- Début du CALCUL du total Net de chaque mois pour les 12 dernier mois avant la date demandé
			+ case when @i > 0 then ', NMUniv' + cast(@i as varchar(2)) + ' = RP.NetUniv'    else ' ' end

			-- Début du CALCUL du total Net de chaque mois pour les 12 dernier mois avant la date demandé
			+ case when @i > 0 then ', NMRflex' + cast(@i as varchar(2)) + ' = RP.NetRflex'    else ' ' end

			+ ' from tblTEMP_SuiviRep SR 
			join (
				select  
					t.RepID,
					ConsPct =	
						CASE
							WHEN SUM(Brut24) <= 0 THEN 0
							ELSE ROUND((sum(Brut24 - Retraits24 + reinscriptions24) / SUM(Brut24)) * 100, 2)
						END,
					Resil = SUM (Retraits * (case when (c.planid in (10,12) and u.dtfirstdeposit <= ''2010-01-10'') then 1.35 else 1 end)),
					Net = SUM((Brut - Retraits + reinscriptions) * (case when (c.planid in (10,12) and u.dtfirstdeposit <= ''2010-01-10'') then 1.35 else 1 end)),

					NetUniv = SUM(case when planid = 8 then (Brut - Retraits + reinscriptions) else 0 END),
					NetRflex = SUM( (case when u.dtfirstdeposit <= ''2010-01-10'' then 1.35 else 1 end) * (case when planid in (10,12) then (Brut - Retraits + reinscriptions) else 0 END))

				from 
					tblTEMP_SuiviRepUnit t
					JOIN dbo.Un_Unit U on U.UnitID = t.UnitID
					JOIN dbo.Un_Convention C ON	C.Conventionid = U.ConventionID
				group by
					t.RepID
				) RP on RP.repID = SR.RepID	'

		exec (@MySql)

		set @i = @i + 1

	end

--return
	------------------------------------------------------------------------------------------
	-- CALCUL DES DONNÉES TOTALES DEPUIS 12 MOIS et 24 MOIS
	------------------------------------------------------------------------------------------

	TRUNCATE TABLE tblTEMP_SuiviRepUnit

	-- Début de l'année
	set @FirstOfMonth = dateadd(dd,1,dateadd(yy,-1,@EndDate)) -- depuis 12 mois (le nom de la variable n'a pas rapport)

	-- Les données des Rep
	INSERT tblTEMP_SuiviRepUnit
	EXEC SL_UN_RepGrossANDNetUnits NULL, @FirstOfMonth, @EndDate ,0 ,1

	update SR set 
		YearBrut = Round(Brut,3),
		YearRetrait = Round(Retraits,3),
		YearReinsc = Round(Reinscriptions,3),
		YearNet = Round(Net,3),
		Month24Brut = Round(Brut24,3),
		Month24Retrait = Round(Retraits24,3),
		Month24Reinsc = Round(Reinscriptions24,3),
		Month24Net = Round(Net24,3)
	From tblTEMP_SuiviRep SR
	Join (
		SELECT  
			t.RepID,
			Brut = SUM(Brut* (CASE WHEN(c.planid in (10,12) and u.dtfirstdeposit <= '2010-01-10') THEN 1.35 ELSE 1 END)),
			Retraits = SUM(Retraits* (CASE WHEN(c.planid in (10,12) and u.dtfirstdeposit <= '2010-01-10') THEN 1.35 ELSE 1 END)),
			Reinscriptions = SUM(Reinscriptions* (CASE WHEN(c.planid in (10,12) and u.dtfirstdeposit <= '2010-01-10') THEN 1.35 ELSE 1 END)),
			Net = SUM((Brut - Retraits + reinscriptions) * (CASE WHEN(c.planid in (10,12) and u.dtfirstdeposit <= '2010-01-10') THEN 1.35 ELSE 1 END)),
			Brut24 = SUM(Brut24* (CASE WHEN(c.planid in (10,12) and u.dtfirstdeposit <= '2010-01-10') THEN 1.35 ELSE 1 END)),
			Retraits24 = SUM(Retraits24* (CASE WHEN(c.planid in (10,12) and u.dtfirstdeposit <= '2010-01-10') THEN 1.35 ELSE 1 END)),
			Reinscriptions24 = SUM(Reinscriptions24* (CASE WHEN(c.planid in (10,12) and u.dtfirstdeposit <= '2010-01-10') THEN 1.35 ELSE 1 END)),
			Net24 = SUM((Brut24 - Retraits24 + reinscriptions24) * (CASE WHEN (c.planid in (10,12) and u.dtfirstdeposit <= '2010-01-10') THEN 1.35 ELSE 1 END))
		FROM 
			tblTEMP_SuiviRepUnit t
			JOIN dbo.Un_Unit U ON U.UnitID = t.UnitID
			JOIN dbo.Un_Convention C ON	C.Conventionid = U.ConventionID
		GROUP BY
			t.RepID
		) V on SR.RepID = V.RepID

	-- Pour chaque RepID, Calculer la différence de taux de conservation entre le dernier mois et le premier mois où il y a une valeur
	-- Le premier mois est celui où on trouve une valeur
	declare
	@Repid integer,
	@CM0 FLOAT,
	@CM1 FLOAT,
	@CM2 FLOAT,
	@CM3 FLOAT,
	@CM4 FLOAT,
	@CM5 FLOAT,
	@CM6 FLOAT,
	@CM7 FLOAT,
	@CM8 FLOAT,
	@CM9 FLOAT,
	@CM10 FLOAT,
	@CM11 FLOAT,
	@CM12 FLOAT,
	@FirstDateSale Datetime

	DECLARE MyCursor CURSOR FOR

		SELECT repid,
			CM0, CM1, CM2, CM3, CM4, CM5, CM6, CM7, CM8, CM9, CM10, CM11, CM12, FirstDateSale
		from tblTEMP_SuiviRep

	OPEN MyCursor
	FETCH NEXT FROM MyCursor INTO 		
		@Repid , @CM0 , @CM1 , @CM2 , @CM3 , @CM4 , @CM5 , @CM6 , @CM7 , @CM8 , @CM9 , @CM10 , @CM11 , @CM12 , @FirstDateSale

	WHILE @@FETCH_STATUS = 0
	BEGIN

	-- trouver Le premier taux de conservation entre CM0 et CM12 (autre que Null)
	set @FirstCons = case
			-- when @CM0 is not null then 'CM0'
			 when @CM1 is not null then 'CM1'
			 when @CM2 is not null then 'CM2'
			 when @CM3 is not null then 'CM3'
			 when @CM4 is not null then 'CM4'
			 when @CM5 is not null then 'CM5'
			 when @CM6 is not null then 'CM6'
			 when @CM7 is not null then 'CM7'
			 when @CM8 is not null then 'CM8'
			 when @CM9 is not null then 'CM9'
			 when @CM10 is not null then 'CM10'
			 when @CM11 is not null then 'CM11'
			 when @CM12 is not null then 'CM12'
			end

	-- trouver Le dernier taux de conservation entre CM0 et CM12 (autre que Null)
	set @LastCons = case
			 when @CM12 is not null then 'CM12'
			 when @CM11 is not null then 'CM11'
			 when @CM10 is not null then 'CM10'
			 when @CM9 is not null then 'CM9'
			 when @CM8 is not null then 'CM8'
			 when @CM7 is not null then 'CM7'
			 when @CM6 is not null then 'CM6'
			 when @CM5 is not null then 'CM5'
			 when @CM4 is not null then 'CM4'
			 when @CM3 is not null then 'CM3'
			 when @CM2 is not null then 'CM2'
			 when @CM1 is not null then 'CM1'
			 --when @CM0 is not null then 'CM0'
			end

		-- déterminer la quantité de mois où on a des données. Pour le calcul de la moyenne des résil par mois (YearAvgRetrait)
		set @NbOfMonthWithData = case 
								when @FirstCons = 'CM1' /*'CM0'*/ then cast(substring(@LastCons,3,2) as integer)
								when @FirstCons <> 'CM1' /*'CM0'*/ then cast(substring(@LastCons,3,2) as integer) + 1 - cast(substring(@FirstCons,3,2) as integer)
								End

		-- Calcul de la différence de taux de cons entre le premier et le dernier mois où il y a des données
		-- Calcul de la moyenne des résiliations par mois entre le premier et le dernier mois où il y a des données 
		-- Calcul de la moyenne des résiliations par mois depuis 24 mois
		set @MySql = 
			'  update tblTEMP_SuiviRep set DiffCons = round(' +@LastCons + ' - ' + @FirstCons + ',2) ' + 
			'	, YearAvgRetrait =Round( (isnull(RM1,0) + isnull(RM2,0) + isnull(RM3,0) + isnull(RM4,0) + isnull(RM5,0) + isnull(RM6,0) + isnull(RM7,0) + isnull(RM8,0) + isnull(RM9,0) + isnull(RM10,0) + isnull(RM11,0) + isnull(RM12,0)   ) / ' + cast(@NbOfMonthWithData as varchar(10)) + ',3) ' + 
			'	, Month24AvgRetrait = Round(  (Month24Retrait    / ' + cast(case when (Datediff(mm,@FirstDateSale, @EndDate)+1) >= 24 then 24 else (Datediff(mm,@FirstDateSale, @EndDate)+1) end  as varchar(10))+ '),3) ' + 
			' where repid = ' + cast(@repid as varchar(10))

		exec (@MySql)

		FETCH NEXT FROM MyCursor INTO 
				@Repid , @CM0 , @CM1 , @CM2 , @CM3 , @CM4 , @CM5 , @CM6 , @CM7 , @CM8 , @CM9 , @CM10 , @CM11 , @CM12  , @FirstDateSale

	END
	CLOSE MyCursor
	DEALLOCATE MyCursor

	-- Calcul des Nets moyens 

	update tblTEMP_SuiviRep
	set 
	
		mois3 = isnull(nm10,0) + isnull(nm11,0) + isnull(nm12,0),
		mois6 = isnull(nm7,0) + isnull(nm8,0) + isnull(nm9,0) + isnull(nm10,0) + isnull(nm11,0) + isnull(nm12,0),
		mois12 = isnull(nm1,0) + isnull(nm2,0) + isnull(nm3,0) + isnull(nm4,0) + isnull(nm5,0) + isnull(nm6,0) + isnull(nm7,0) + isnull(nm8,0) + isnull(nm9,0) + isnull(nm10,0) + isnull(nm11,0) + isnull(nm12,0),

		moisLastPctUniv  = case when (isnull(nm12,0)) = 0 then 0
					else (isnull(NMUniv12,0)) / (isnull(nm12,0)) end,
					
		moisLastPctRflex = case when (isnull(nm12,0)) = 0 then 0
					else (isnull(nmRflex12,0)) / (isnull(nm12,0)) end,

		mois3PctUniv = case when (isnull(nm10,0) + isnull(nm11,0) + isnull(nm12,0)) = 0 then 0
					else (isnull(NMUniv10,0) + isnull(NMUniv11,0) + isnull(NMUniv12,0)) / (isnull(nm10,0) + isnull(nm11,0) + isnull(nm12,0)) end,
					
		mois3PctRflex = case when (isnull(nm10,0) + isnull(nm11,0) + isnull(nm12,0)) = 0 then 0
					else (isnull(nmRflex10,0) + isnull(nmRflex11,0) + isnull(nmRflex12,0)) / (isnull(nm10,0) + isnull(nm11,0) + isnull(nm12,0)) end,
					
		mois3Resil = isnull(rm10,0) + isnull(rm11,0) + isnull(rm12,0),

		mois6PctUniv = case when (isnull(nm7,0) + isnull(nm8,0) + isnull(nm9,0) + isnull(nm10,0) + isnull(nm11,0) + isnull(nm12,0)) = 0 then 0
					else (isnull(NMUniv7,0) + isnull(NMUniv8,0) + isnull(NMUniv9,0) + isnull(NMUniv10,0) + isnull(NMUniv11,0) + isnull(NMUniv12,0)) / (isnull(nm7,0) + isnull(nm8,0) + isnull(nm9,0) + isnull(nm10,0) + isnull(nm11,0) + isnull(nm12,0)) end,
					
		mois6PctRflex = case when (isnull(nm7,0) + isnull(nm8,0) + isnull(nm9,0) + isnull(nm10,0) + isnull(nm11,0) + isnull(nm12,0)) = 0 then 0
					else (isnull(nmRflex7,0) + isnull(nmRflex8,0) + isnull(nmRflex9,0) + isnull(nmRflex10,0) + isnull(nmRflex11,0) + isnull(nmRflex12,0)) / (isnull(nm7,0) + isnull(nm8,0) + isnull(nm9,0) + isnull(nm10,0) + isnull(nm11,0) + isnull(nm12,0)) end,

		mois6Resil = isnull(rm7,0) + isnull(rm8,0) + isnull(rm9,0) + isnull(rm10,0) + isnull(rm11,0) + isnull(rm12,0),

		mois12PctUniv = case when (isnull(nm1,0) + isnull(nm2,0) + isnull(nm3,0) + isnull(nm4,0) + isnull(nm5,0) + isnull(nm6,0) + isnull(nm7,0) + isnull(nm8,0) + isnull(nm9,0) + isnull(nm10,0) + isnull(nm11,0) + isnull(nm12,0)) = 0 then 0
					else (isnull(NMUniv1,0) + isnull(NMUniv2,0) + isnull(NMUniv3,0) + isnull(NMUniv4,0) + isnull(NMUniv5,0) + isnull(NMUniv6,0) + isnull(NMUniv7,0) + isnull(NMUniv8,0) + isnull(NMUniv9,0) + isnull(NMUniv10,0) + isnull(NMUniv11,0) + isnull(NMUniv12,0)) / (isnull(nm1,0) + isnull(nm2,0) + isnull(nm3,0) + isnull(nm4,0) + isnull(nm5,0) + isnull(nm6,0) + isnull(nm7,0) + isnull(nm8,0) + isnull(nm9,0) + isnull(nm10,0) + isnull(nm11,0) + isnull(nm12,0)) end,

		mois12PctRflex = case when (isnull(nm1,0) + isnull(nm2,0) + isnull(nm3,0) + isnull(nm4,0) + isnull(nm5,0) + isnull(nm6,0) + isnull(nm7,0) + isnull(nm8,0) + isnull(nm9,0) + isnull(nm10,0) + isnull(nm11,0) + isnull(nm12,0)) = 0 then 0
					else (isnull(nmRflex1,0) + isnull(nmRflex2,0) + isnull(nmRflex3,0) + isnull(nmRflex4,0) + isnull(nmRflex5,0) + isnull(nmRflex6,0) + isnull(nmRflex7,0) + isnull(nmRflex8,0) + isnull(nmRflex9,0) + isnull(nmRflex10,0) + isnull(nmRflex11,0) + isnull(nmRflex12,0)) / (isnull(nm1,0) + isnull(nm2,0) + isnull(nm3,0) + isnull(nm4,0) + isnull(nm5,0) + isnull(nm6,0) + isnull(nm7,0) + isnull(nm8,0) + isnull(nm9,0) + isnull(nm10,0) + isnull(nm11,0) + isnull(nm12,0)) end,

		mois12Resil = isnull(rm1,0) + isnull(rm2,0) + isnull(rm3,0) + isnull(rm4,0) + isnull(rm5,0) + isnull(rm6,0) + isnull(rm7,0) + isnull(rm8,0) + isnull(rm9,0) + isnull(rm10,0) + isnull(rm11,0) + isnull(rm12,0)

	-- Calculer la différence entre le dernier mois et le premier mois
	-- Le premier mois est celui où on trouve une valeur
	declare
	@NM1 FLOAT,
	@NM2 FLOAT,
	@NM3 FLOAT,
	@NM4 FLOAT,
	@NM5 FLOAT,
	@NM6 FLOAT,
	@NM7 FLOAT,
	@NM8 FLOAT,
	@NM9 FLOAT,
	@NM10 FLOAT,
	@NM11 FLOAT,
	@NM12 FLOAT

	DECLARE MyCursor CURSOR FOR

		SELECT repid,
			NM1,
			NM2,
			NM3,
			NM4,
			NM5,
			NM6,
			NM7,
			NM8,
			NM9,
			NM10,
			NM11,
			NM12
		from tblTEMP_SuiviRep

	OPEN MyCursor
	FETCH NEXT FROM MyCursor INTO 		
		@Repid ,
		@NM1 ,
		@NM2 ,
		@NM3 ,
		@NM4 ,
		@NM5 ,
		@NM6 ,
		@NM7 ,
		@NM8 ,
		@NM9 ,
		@NM10 ,
		@NM11 ,
		@NM12 

	WHILE @@FETCH_STATUS = 0
	BEGIN

		update tblTEMP_SuiviRep set AVGMois = case 
			when @NM12 is null then 0
			when @NM11 is null then Round(isnull(nm12,0),3)
			when @NM10 is null then Round((isnull(nm11,0) + isnull(nm12,0)) / 2,3)
			when @NM9 is null then Round((isnull(nm10,0) + isnull(nm11,0) + isnull(nm12,0)) / 3,3)
			when @NM8 is null then Round((isnull(nm9,0) + isnull(nm10,0) + isnull(nm11,0) + isnull(nm12,0)) / 4,3)
			when @NM7 is null then Round((isnull(nm8,0) + isnull(nm9,0) + isnull(nm10,0) + isnull(nm11,0) + isnull(nm12,0)) / 5,3)
			when @NM6 is null then Round((isnull(nm7,0) + isnull(nm8,0) + isnull(nm9,0) + isnull(nm10,0) + isnull(nm11,0) + isnull(nm12,0)) / 6,3)
			when @NM5 is null then Round((isnull(nm6,0) + isnull(nm7,0) + isnull(nm8,0) + isnull(nm9,0) + isnull(nm10,0) + isnull(nm11,0) + isnull(nm12,0)) / 7,3)
			when @NM4 is null then Round((isnull(nm5,0) + isnull(nm6,0) + isnull(nm7,0) + isnull(nm8,0) + isnull(nm9,0) + isnull(nm10,0) + isnull(nm11,0) + isnull(nm12,0)) / 8,3)
			when @NM3 is null then Round((isnull(nm4,0) + isnull(nm5,0) + isnull(nm6,0) + isnull(nm7,0) + isnull(nm8,0) + isnull(nm9,0) + isnull(nm10,0) + isnull(nm11,0) + isnull(nm12,0)) / 9,3)
			when @NM2 is null then Round((isnull(nm3,0) + isnull(nm4,0) + isnull(nm5,0) + isnull(nm6,0) + isnull(nm7,0) + isnull(nm8,0) + isnull(nm9,0) + isnull(nm10,0) + isnull(nm11,0) + isnull(nm12,0)) / 10,3)
			when @NM1 is null then Round((isnull(nm2,0) + isnull(nm3,0) + isnull(nm4,0) + isnull(nm5,0) + isnull(nm6,0) + isnull(nm7,0) + isnull(nm8,0) + isnull(nm9,0) + isnull(nm10,0) + isnull(nm11,0) + isnull(nm12,0)) / 11,3)
			else Round((isnull(nm1,0) + isnull(nm2,0) + isnull(nm3,0) + isnull(nm4,0) + isnull(nm5,0) + isnull(nm6,0) + isnull(nm7,0) + isnull(nm8,0) + isnull(nm9,0) + isnull(nm10,0) + isnull(nm11,0) + isnull(nm12,0)) / 12,3) 
			end
		where repid = @repid

		FETCH NEXT FROM MyCursor INTO 
			@Repid ,
			@NM1 ,
			@NM2 ,
			@NM3 ,
			@NM4 ,
			@NM5 ,
			@NM6 ,
			@NM7 ,
			@NM8 ,
			@NM9 ,
			@NM10 ,
			@NM11 ,
			@NM12 

	END
	CLOSE MyCursor
	DEALLOCATE MyCursor

	-- Résultat final
	SELECT * FROM tblTEMP_SuiviRep order by lastname

	--Drop table TMPsuiviRep
	--Drop table TMPGrossANDNetUnitsU
	TRUNCATE TABLE tblTEMP_SuiviRep
	TRUNCATE TABLE tblTEMP_SuiviRepUnit
*/
END