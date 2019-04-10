/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	GU_RP_SuiviSiege 
Description         :	Rapport Statistique (pour diffusion au siège social) des ventes depuis le début de l'année
Valeurs de retours  :	Dataset 
Note                :	2009-06-10	Donald Huppé	Créaton

-- exec GU_RP_SuiviSiege '2009-05-31'

****************************************************************************************************/
CREATE PROCEDURE [dbo].[GU_RP_SuiviSiege] (
	@EndDate DATETIME) -- Date de fin
AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT,
		@CurrentTreatmentDate DATETIME,
		@TreatmentYear INTEGER,
		@FromDate DATETIME,
		@ToDate DATETIME,
		@i INTEGER,
		@DaysInMonth INTEGER,
		@FirstCons varchar(5),
		@LastCons varchar(5),
		@MySql varchar(5000)

	SET @dtBegin = GETDATE()

	set @FromDate = cast(year(@EndDate) as varchar(4)) + '-01-31'

--print '1'

	create table #TMPsuiviSiege( -- DROP TABLE #TMPsuiviSiege --SELECT * FROM #TMPsuiviSiege
		Mois INTEGER,	-- Le numéro du mois
		MoisNom	varchar(20), -- Le nom du mois
		Date Datetime, -- la date de fin du mois
		Objectif FLOAT,	-- Objectif du mois fournis par Patricia
		ObjectifCumul FLOAT,	-- Objectif du mois fournis par Patricia
 		Net FLOAT,		-- NET PAR MOIS
		NetCumul FLOAT,	-- NET CUMUL DEPUIS LE PREMIER MOIS
		NetUniv FLOAT,	-- NET UNIVERSITAS
		PctUniv FLOAT, -- % de Universitas
		PctRflex FLOAT, -- 5 de Reefleex 
		NetRflex FLOAT,	-- NET REEFLEX
		Cons FLOAT,		-- % CONSERVATION À LA FIN DU MOIS
		ConsObj FLOAT, -- Objectif du tuax de conservation
		RepFrancoCumul INTEGER,
		RepAngloCumul INTEGER,
		Benef INTEGER,
		BenefCumul INTEGER)

	SET @I = 1
	WHILE @i <= 12
	begin
		insert into #TMPsuiviSiege(Mois,MoisNom,Objectif) 
		values (@i,
		case  
			when @i = 1 then 'Janv.' -- + cast(year(@EndDate) as varchar(4))
			when @i = 2 then 'Févr.' -- + cast(year(@EndDate) as varchar(4))
			when @i = 3 then 'Mars' -- + cast(year(@EndDate) as varchar(4))
			when @i = 4 then 'Avr.' -- + cast(year(@EndDate) as varchar(4))
			when @i = 5 then 'Mai' -- + cast(year(@EndDate) as varchar(4))
			when @i = 6 then 'Juin' -- + cast(year(@EndDate) as varchar(4))
			when @i = 7 then 'Juil.' -- + cast(year(@EndDate) as varchar(4))
			when @i = 8 then 'Août' -- + cast(year(@EndDate) as varchar(4))
			when @i = 9 then 'Sept.' -- + cast(year(@EndDate) as varchar(4))
			when @i = 10 then 'Oct.' --+ cast(year(@EndDate) as varchar(4))
			when @i = 11 then 'Nov.' -- + cast(year(@EndDate) as varchar(4))
			when @i = 12 then 'Déc.' -- + cast(year(@EndDate) as varchar(4))
		else null
		end,
		case  
			when @i = 1 then 3697.5
			when @i = 2 then 6307.5
			when @i = 3 then 5655
			when @i = 4 then 7177.5
			when @i = 5 then 6177
			when @i = 6 then 6133.5
			when @i = 7 then 4698
			when @i = 8 then 6090
			when @i = 9 then 6960
			when @i = 10 then 8526
			when @i = 11 then 7656
			when @i = 12 then 7482
		else null
		end
		)

		update #TMPsuiviSiege set ObjectifCumul = (select sum(Objectif) from #TMPsuiviSiege) where mois = @I

		SET @I = @I + 1
	end

--select * from #TMPsuiviSiege
--return

	create table #GrossANDNetUnits (
		RepID INTEGER,
		BossID INTEGER,
		RepTreatmentID INTEGER,
		RepTreatmentDate DATETIME,
		Brut_4 FLOAT, Brut_8 FLOAT, Brut_10 FLOAT,
		Retraits_4 FLOAT, Retraits_8 FLOAT,	Retraits_10 FLOAT,
		Reinscriptions_4 FLOAT,	Reinscriptions_8 FLOAT,	Reinscriptions_10 FLOAT,
		Net_4 FLOAT, Net_8 FLOAT, Net_10 FLOAT,
		Brut24_4 FLOAT, Brut24_8 FLOAT, Brut24_10 FLOAT,
		Retraits24_4 FLOAT, Retraits24_8 FLOAT,	Retraits24_10 FLOAT,
		Reinscriptions24_4 FLOAT, Reinscriptions24_8 FLOAT,	Reinscriptions24_10 FLOAT,
		Net24_4 FLOAT, Net24_8 FLOAT, Net24_10 FLOAT)

--print '2'

	declare 
		@Cons FLOAT,
		@Net FLOAT,
		@Cumul Float,
		@ObjectifCumul Float,
		@Net_8 FLOAT,
		@Net_10 FLOAT,
		@RF INTEGER,
		@RA INTEGER,
		@NbBenef INTEGER,
		@BenefCumul	INTEGER
	
	-- Calcul des Net des 12 mois de l'année en cours

	-- Le premier jour du premier mois
	set @FromDate = cast(year(@EndDate) as varchar(4)) + '-01-01' -- dateadd(dd,1,dateadd(YY,-1,@enddate))

	set @i = 1
	while @FromDate < @EndDate
	begin

		Delete from #GrossANDNetUnits

		-- Le nombre de jour dans le mois en cours
		set @DaysInMonth = CASE WHEN MONTH(@FromDate) IN (1, 3, 5, 7, 8, 10, 12) THEN 31
						WHEN MONTH(@FromDate) IN (4, 6, 9, 11) THEN 30
						ELSE CASE WHEN (YEAR(@FromDate) % 4    = 0 AND
										YEAR(@FromDate) % 100 != 0) OR
									   (YEAR(@FromDate) % 400  = 0)
								  THEN 29
								  ELSE 28
							 END
				   END

		-- La date de fin du mois en cours
		set @ToDate = dateadd(dd,@DaysInMonth-1,@FromDate)

		--print convert(varchar(25),@FromDate) + ' ' + convert(varchar(25),@ToDate)

		-- Les ventes
		INSERT #GrossANDNetUnits
		EXEC SL_UN_RepGrossANDNetUnits NULL, @FromDate, @ToDate ,0 ,0

		select  
			@Cons = CASE
					WHEN SUM(Brut24_4 + Brut24_8 + Brut24_10) <= 0 THEN 0
					ELSE ROUND((sum(Net24_4 + Net24_8 + Net24_10) / SUM(Brut24_4 + Brut24_8 + Brut24_10)) * 100, 2)
					END,
			@Net =	sum(Net_4 + Net_8 + Net_10),
			@Net_8 = sum(Net_8),
			@Net_10 = sum(Net_10)
		from 
			#GrossANDNetUnits t

		-- Nouveau Rep Francophone depuis le début de l'année
		SELECT @RF = COUNT(*) 
		FROM UN_REP R
		JOIN dbo.MO_HUMAN H ON R.REPID = H.HUMANID
		WHERE R.BUSINESSSTART BETWEEN cast(year(@EndDate) as varchar(4)) + '-01-01' AND @ToDate
		AND H.LANGID = 'FRA'

		-- Nouveau Rep Anglophone depuis le début de l'année
		SELECT @RA = COUNT(*) 
		FROM UN_REP R
		JOIN dbo.MO_HUMAN H ON R.REPID = H.HUMANID
		WHERE R.BUSINESSSTART BETWEEN cast(year(@EndDate) as varchar(4)) + '-01-01' AND @ToDate
		AND H.LANGID = 'ENU'

		-- Nouveaux boursiers (bénéficiaire)
		SELECT 
			@NbBenef = COUNT(NB.BeneficiaryID)
		FROM ( -- Va chercher la liste des nouveaux bénéficiaires avec son premier groupe d'unité
			SELECT -- Premier unitID de la première date de premier dépôt
				NB.BeneficiaryID,
				MinUnitID = MIN(UnitID)
			FROM ( -- Première date du premier dépôt par bénéficaire
				SELECT 
					C.BeneficiaryID,
					MindtFirstDeposit = MIN(U.dtFirstDeposit)
				FROM dbo.Un_Convention C
				JOIN dbo.Un_Unit U ON U.conventionID = C.ConventionID
				GROUP BY C.BeneficiaryID
				HAVING MIN(U.dtFirstDeposit) BETWEEN @FromDate AND @ToDate -- doit être prendant cette période
				) NB 
			JOIN dbo.Un_Convention C ON C.BeneficiaryID = NB.BeneficiaryID
			JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID AND U.dtFirstDeposit = NB.MindtFirstDeposit
			GROUP BY NB.BeneficiaryID
			) NB
		JOIN dbo.Un_Unit U ON U.UnitID = NB.MinUnitID

		select 
			@Cumul = sum(Net), 
			@ObjectifCumul = Sum(Objectif),
			@BenefCumul = sum(Benef) 
		from #TMPsuiviSiege 
		where mois < @I

		UPDATE #TMPsuiviSiege SET 
			Date = @ToDate,
 			Net = @Net,		-- NET PAR MOIS
			NetCumul = @Net + isnull(@Cumul,0),	-- NET CUMUL DEPUIS LE PREMIER MOIS
			NetUniv = @Net_8,	-- NET UNIVERSITAS
			NetRflex = @Net_10,	-- NET REEFLEX
			PctUniv = round(/*100 * */ ((@Net_8)/(@Net_8 + @Net_10)),2),
			PctRflex = round(/*100 * */ ((@Net_10)/(@Net_8 + @Net_10)),2),
			Cons = @Cons,		-- % CONSERVATION À LA FIN DU MOIS
			ConsObj = 89,
			RepFrancoCumul = @RF,
			RepAngloCumul = @RA,
			Benef = @NbBenef,
			BenefCumul = @NbBenef + isnull(@BenefCumul,0)
		WHERE Mois = @I

		set @i = @i + 1

		-- On avance d'un jour pour arriver au début du mois suivant
		set @FromDate = dateadd(dd,1,@ToDate)

	end

	-- Si on veut voir seulement lesm ois où il y a des données
	delete from #TMPsuiviSiege where date is null

	SELECT * FROM #TMPsuiviSiege 

END


