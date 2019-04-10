
/****************************************************************************************************
Code de service		:		psGENE_RapportStatOrg_Q6_MontantSouscrit_BRUT_RES
Nom du service		:		psGENE_RapportStatOrg_Q6_MontantSouscrit_BRUT_RES
But					:		Pour le rapport de statistiques orrganisationelles - Q6
Facette				:		GENE
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						N/A

Exemple d'appel:
						 exec psGENE_RapportStatOrg_Q6_MontantSouscrit_BRUT_RES '2016-12-31', 1
                

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------


Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2016-06-14					Donald Huppé							Création du Service
						2017-01-24					Donald Huppé							jira ti-6503 : exclure du brut et du net les unités résiliées avec la raison "erreur administrative" et "1er dépôt"
 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[psGENE_RapportStatOrg_Q6_MontantSouscrit_BRUT_RES] (
	@EnDateDu datetime
	,@QtePeriodePrecedent int = 0
	)


AS
BEGIN

set @QtePeriodePrecedent = case when @QtePeriodePrecedent > 5 then 5 ELSE @QtePeriodePrecedent end

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

	create table #Result (
			DateFrom datetime
			,DateTo datetime
			,MontantSouscritBRUT FLOAT
			,MontantSouscritRES FLOAT
			)

	create table #Final (
		Sort int,
		Quoi varchar(100),
		v0 float,
		v1 float,
		v2 float,
		v3 float,
		v4 float,
		v5 float
		)

	
	--declare	 @EnDateDu datetime = '2016-05-31'
	declare	 @DateFrom datetime
	declare	 @DateTo datetime
	declare @i int = 0
	declare @j int = 0
	

	while @i <= @QtePeriodePrecedent
	begin 

		delete from #GrossANDNetUnits
			

		set @DateFrom = cast(year(@EnDateDu)-@i as VARCHAR(4))+ '-01-01'
		set @DateTo = cast(year(@EnDateDu)-@i as VARCHAR(4)) + '-12-31'

		if @i = 0
			set @DateTo  = @EnDateDu

		INSERT #GrossANDNetUnits
		EXEC SL_UN_RepGrossANDNetUnits NULL, @DateFrom, @DateTo, 0, 1
		DELETE FROM #GrossANDNetUnits WHERE BRUT <= 0

		insert into #Result
		SELECT 
			DateFrom = @DateFrom
			,DateTo = @DateTo
			,MontantSouscritBRUT = sum(MontantSouscritBRUT )
			,MontantSouscritRES = sum(MontantSouscritRES)

		from (
			SELECT 
				DateFrom = @DateFrom
				,DateTo = @DateTo
				,gnu.unitID
				,MontantSouscritBRUT = sum	( 
												(ROUND( (brut - isnull(RES.QteRES,0)) * M.PmtRate,2) * M.PmtQty) 
												+	(	-- on additionne cette valeur seulement si le brut est  <> 0
														U.SubscribeAmountAjustment * (case when (brut - isnull(RES.QteRES,0)) = 0 then 0 ELSE 1 end )
													)
											) 
				,MontantSouscritRES = 0
			from #GrossANDNetUnits gnu
			join Un_Unit u on gnu.UnitID = u.UnitID
			join Un_Convention c on u.ConventionID= c.ConventionID
			join Mo_Human hb on c.BeneficiaryID = hb.HumanID
			LEFT JOIN (
					select umh.UnitID, ModalID = max(umh.ModalID )
					from Un_UnitModalHistory umh
					join Un_Unit u on umh.UnitID = u.UnitID
					join Un_Convention c on u.ConventionID = c.ConventionID --and c.SubscriberID = 575993 
					where umh.StartDate = (
										select max(StartDate)
										from Un_UnitModalHistory umh2
										where umh.UnitID = umh2.UnitID
										and cast(umh2.StartDate as date) <= cast(u.dtFirstDeposit as date)
										)
					GROUP BY umh.UnitID
					) mh on u.UnitID = mh.UnitID
			left join ( -- les rares cas ou il N'y a pas de modalité en date du 1er depot, on prend la 1ere modalité dans l'historique
					select umh.UnitID, ModalID = min(umh.ModalID )
					from Un_UnitModalHistory umh
					GROUP by umh.UnitID
					)FirstModal on u.UnitID = FirstModal.UnitID
			left join Un_Modal M on m.ModalID = isnull(mh.ModalID,FirstModal.ModalID)

			left join (
				select 
					ur.UnitID,QteRES =  sum(ur.UnitQty)
				from 
					Un_UnitReduction ur
				where 
					ur.UnitReductionReasonID in (42,42)
					and ur.ReductionDate BETWEEN @DateFrom and @DateTo
				GROUP by ur.UnitID
				)RES on RES.UnitID = gnu.UnitID

			where c.PlanID <> 4
			GROUP by gnu.unitID

			union ALL

			select 
				DateFrom = @DateFrom
				,DateTo = @DateTo
				,v.UnitID
				,MontantSouscritBRUT = 0
				,MontantSouscritRES =cast( SUM(	
										(ROUND( (v.QteUniteRES ) * M.PmtRate,2) * M.PmtQty) + U.SubscribeAmountAjustment
											)		 
									as MONEY)
			
			from (

				select DISTINCT
					ur.UnitReductionID
					,c.ConventionNo, u.UnitID, c.ConventionID
					,QteUniteRES =case when o.OperTypeID <> 'TRI' then ur.UnitQty else ur.UnitQty - 1 end
			
				from 
					Un_Convention c
					join Un_Unit u on c.ConventionID = u.ConventionID
					join Un_UnitReduction ur on u.UnitID = ur.UnitID
					join Un_UnitReductionCotisation urc on ur.UnitReductionID = urc.UnitReductionID
					join Un_Cotisation ct on urc.CotisationID = ct.CotisationID
					join un_oper o on ct.OperID = o.OperID 
					left join Un_Tio TIOt on TIOt.iTINOperID = o.operid
					left join Un_Tio TIOo on TIOo.iOUTOperID = o.operid
					left join Un_OperCancelation oc1 on o.OperID = oc1.OperID
					left join Un_OperCancelation oc2 on o.OperID = oc2.OperSourceID
				where  
					ur.ReductionDate BETWEEN @DateFrom and @DateTo
					and o.OperTypeID in ( 'TRI', 'OUT','RES','RET')
					and ur.UnitReductionReasonID not in (42,42)
					and tioo.iOUTOperID is NULL -- OUT qui n'est pas un TIO
					and oc1.OperID is NULL
					and oc2.OperSourceID is NULL
					--and c.ConventionNo = '1333395'
				) V
			join Un_Convention c on v.ConventionID = c.ConventionID
			join Un_Unit u on u.UnitID = v.UnitID
			JOIN dbo.Un_Modal M ON M.ModalID = U.ModalID
			--JOIN dbo.Un_Plan P ON P.PlanID = C.PlanID
			--LEFT JOIN dbo.Mo_Connect Co ON Co.ConnectID = U.PmtEndConnectID --AND Co.ConnectStart BETWEEN ISNULL(null,'1900/01/01') AND ISNULL(null,GETDATE())
			--LEFT JOIN dbo.Un_SaleSource SS ON SS.SaleSourceID = U.SaleSourceID

			GROUP by v.UnitID

			)v



		set @i = @i + 1
	end	 --while @i

	
	--select * from #Result --ORDER BY DateTo,AgeBenef

	/*
			,MontantSouscritBRUT = sum(MontantSouscritBRUT )
			,MontantSouscritRES = sum(MontantSouscritRES)	
	*/

	INSERT into #Final values (
		1
		,'MontantSouscritBRUT'
		,(select MontantSouscritBRUT from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select MontantSouscritBRUT from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select MontantSouscritBRUT from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select MontantSouscritBRUT from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select MontantSouscritBRUT from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select MontantSouscritBRUT from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)

	INSERT into #Final values (
		2
		,'MontantSouscritRES'
		,(select MontantSouscritRES from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select MontantSouscritRES from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select MontantSouscritRES from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select MontantSouscritRES from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select MontantSouscritRES from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select MontantSouscritRES from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	
	select * from #Final order by sort

END

-- exec psGENE_StatOrg_Q2_BrutParAge '2016-05-31'
