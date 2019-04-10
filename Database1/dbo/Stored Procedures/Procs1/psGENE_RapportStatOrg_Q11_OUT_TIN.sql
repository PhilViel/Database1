
/****************************************************************************************************
Code de service		:		psGENE_RapportStatOrg_Q11_OUT_TIN
Nom du service		:		psGENE_RapportStatOrg_Q11_OUT_TIN
But					:		Pour le rapport de statistiques orrganisationelles - Q11
Facette				:		GENE
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						N/A

Exemple d'appel:
						exec psGENE_RapportStatOrg_Q11_OUT_TIN '2016-05-31', 1
                

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------


Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2016-06-14					Donald Huppé							Création du Service
						
 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_RapportStatOrg_Q11_OUT_TIN] (
	@EnDateDu datetime
	,@QtePeriodePrecedent int = 0
	)

AS
BEGIN

set @QtePeriodePrecedent = case when @QtePeriodePrecedent > 5 then 5 ELSE @QtePeriodePrecedent end

	create table #Result (
			DateFrom datetime
			,DateTo datetime
			,OUT_QteSousc INT
			,OUT_QteConvention INT
			,OUT_QteUniteOUT INT
			,OUT_QteBeneficiaire_0 INT
			,OUT_QteBeneficiaire_1 INT
			,OUT_QteBeneficiaire_2 INT
			,OUT_QteBeneficiaire_3 INT
			,OUT_QteBeneficiaire_4 INT
			,OUT_QteBeneficiaire_5 INT
			,OUT_QteBeneficiaire_6 INT
			,OUT_QteBeneficiaire_7 INT
			,OUT_QteBeneficiaire_8 INT
			,OUT_QteBeneficiaire_9 INT
			,OUT_QteBeneficiaire_10 INT
			,OUT_QteBeneficiaire_11 INT
			,OUT_QteBeneficiaire_12 INT
			,OUT_QteBeneficiaire_13 INT
			,OUT_QteBeneficiaire_14 INT
			,OUT_QteBeneficiaire_15 INT
			,OUT_QteBeneficiaire_16 INT
			,OUT_QteBeneficiaire_17_Plus INT

			,TIN_QteSousc INT
			,TIN_QteConvention INT
			,TIN_QteUniteTIN INT
			,TIN_QteBeneficiaire_0 INT
			,TIN_QteBeneficiaire_1 INT
			,TIN_QteBeneficiaire_2 INT
			,TIN_QteBeneficiaire_3 INT
			,TIN_QteBeneficiaire_4 INT
			,TIN_QteBeneficiaire_5 INT
			,TIN_QteBeneficiaire_6 INT
			,TIN_QteBeneficiaire_7 INT
			,TIN_QteBeneficiaire_8 INT
			,TIN_QteBeneficiaire_9 INT
			,TIN_QteBeneficiaire_10 INT
			,TIN_QteBeneficiaire_11 INT
			,TIN_QteBeneficiaire_12 INT
			,TIN_QteBeneficiaire_13 INT
			,TIN_QteBeneficiaire_14 INT
			,TIN_QteBeneficiaire_15 INT
			,TIN_QteBeneficiaire_16 INT
			,TIN_QteBeneficiaire_17_Plus INT	
			)

	create table #Final (
		Sort FLOAT,
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

		

		set @DateFrom = cast(year(@EnDateDu)-@i as VARCHAR(4))+ '-01-01'
		set @DateTo = cast(year(@EnDateDu)-@i as VARCHAR(4)) + '-12-31'

		if @i = 0
			set @DateTo  = @EnDateDu

	
		insert into #Result
		SELECT 
			DateFrom = @DateFrom
			,DateTo = @DateTo
			,OUT_QteSousc = sum(OUT_QteSousc)
			,OUT_QteConvention = SUM(OUT_QteConvention )
			,OUT_QteUniteOUT = SUM(OUT_QteUniteOUT)
			,OUT_QteBeneficiaire_0 = SUM(OUT_QteBeneficiaire_0 )
			,OUT_QteBeneficiaire_1 = SUM(OUT_QteBeneficiaire_1 )
			,OUT_QteBeneficiaire_2 = SUM(OUT_QteBeneficiaire_2 )
			,OUT_QteBeneficiaire_3 = SUM(OUT_QteBeneficiaire_3 )
			,OUT_QteBeneficiaire_4 = SUM(OUT_QteBeneficiaire_4 )
			,OUT_QteBeneficiaire_5 = SUM(OUT_QteBeneficiaire_5 )
			,OUT_QteBeneficiaire_6 = SUM(OUT_QteBeneficiaire_6 )
			,OUT_QteBeneficiaire_7 = SUM(OUT_QteBeneficiaire_7 )
			,OUT_QteBeneficiaire_8 = SUM(OUT_QteBeneficiaire_8 )
			,OUT_QteBeneficiaire_9 = SUM(OUT_QteBeneficiaire_9 )
			,OUT_QteBeneficiaire_10 = SUM(OUT_QteBeneficiaire_10 )
			,OUT_QteBeneficiaire_11 = SUM(OUT_QteBeneficiaire_11 )
			,OUT_QteBeneficiaire_12 = SUM(OUT_QteBeneficiaire_12 )
			,OUT_QteBeneficiaire_13 = SUM(OUT_QteBeneficiaire_13 )
			,OUT_QteBeneficiaire_14 = SUM(OUT_QteBeneficiaire_14 )
			,OUT_QteBeneficiaire_15 = SUM(OUT_QteBeneficiaire_15 )
			,OUT_QteBeneficiaire_16 = SUM(OUT_QteBeneficiaire_16 )
			,OUT_QteBeneficiaire_17_Plus = SUM(Q.OUT_QteBeneficiaire_17_Plus )

			,TIN_QteSousc = SUM(TIN_QteSousc)
			,TIN_QteConvention = SUM(TIN_QteConvention )
			,TIN_QteUniteTIN = SUM(TIN_QteUniteTIN)
			,TIN_QteBeneficiaire_0 = SUM(TIN_QteBeneficiaire_0 )
			,TIN_QteBeneficiaire_1 = SUM(TIN_QteBeneficiaire_1 )
			,TIN_QteBeneficiaire_2 = SUM(TIN_QteBeneficiaire_2 )
			,TIN_QteBeneficiaire_3 = SUM(TIN_QteBeneficiaire_3 )
			,TIN_QteBeneficiaire_4 = SUM(TIN_QteBeneficiaire_4 )
			,TIN_QteBeneficiaire_5 = SUM(TIN_QteBeneficiaire_5 )
			,TIN_QteBeneficiaire_6 = SUM(TIN_QteBeneficiaire_6 )
			,TIN_QteBeneficiaire_7 = SUM(TIN_QteBeneficiaire_7 )
			,TIN_QteBeneficiaire_8 = SUM(TIN_QteBeneficiaire_8 )
			,TIN_QteBeneficiaire_9 = SUM(TIN_QteBeneficiaire_9 )
			,TIN_QteBeneficiaire_10 = SUM(TIN_QteBeneficiaire_10 )
			,TIN_QteBeneficiaire_11 = SUM(TIN_QteBeneficiaire_11 )
			,TIN_QteBeneficiaire_12 = SUM(TIN_QteBeneficiaire_12 )
			,TIN_QteBeneficiaire_13 = SUM(TIN_QteBeneficiaire_13 )
			,TIN_QteBeneficiaire_14 = SUM(TIN_QteBeneficiaire_14 )
			,TIN_QteBeneficiaire_15 = SUM(TIN_QteBeneficiaire_15 )
			,TIN_QteBeneficiaire_16 = SUM(TIN_QteBeneficiaire_16 )
			,TIN_QteBeneficiaire_17_Plus = SUM(Q.TIN_QteBeneficiaire_17_Plus)	

		FROM (
			SELECT 
				OUT_QteSousc = count(DISTINCT SubscriberID)
				,OUT_QteConvention = count(DISTINCT ConventionNo)
				,OUT_QteUniteOUT = SUM(QteUniteOUT)
				,OUT_QteBeneficiaire_0 = count(DISTINCT BeneficiaryID_0)
				,OUT_QteBeneficiaire_1 = count(DISTINCT BeneficiaryID_1)
				,OUT_QteBeneficiaire_2 = count(DISTINCT BeneficiaryID_2)
				,OUT_QteBeneficiaire_3 = count(DISTINCT BeneficiaryID_3)
				,OUT_QteBeneficiaire_4 = count(DISTINCT BeneficiaryID_4)
				,OUT_QteBeneficiaire_5 = count(DISTINCT BeneficiaryID_5)
				,OUT_QteBeneficiaire_6 = count(DISTINCT BeneficiaryID_6)
				,OUT_QteBeneficiaire_7 = count(DISTINCT BeneficiaryID_7)
				,OUT_QteBeneficiaire_8 = count(DISTINCT BeneficiaryID_8)
				,OUT_QteBeneficiaire_9 = count(DISTINCT BeneficiaryID_9)
				,OUT_QteBeneficiaire_10 =count(DISTINCT BeneficiaryID_10)
				,OUT_QteBeneficiaire_11 =count(DISTINCT BeneficiaryID_11)
				,OUT_QteBeneficiaire_12 =count(DISTINCT BeneficiaryID_12)
				,OUT_QteBeneficiaire_13 = count(DISTINCT BeneficiaryID_13)
				,OUT_QteBeneficiaire_14 = count(DISTINCT BeneficiaryID_14)
				,OUT_QteBeneficiaire_15 = count(DISTINCT BeneficiaryID_15)
				,OUT_QteBeneficiaire_16 =count(DISTINCT BeneficiaryID_16)
				,OUT_QteBeneficiaire_17_Plus = count(DISTINCT BeneficiaryID_17_Plus)

				,TIN_QteSousc = 0
				,TIN_QteConvention = 0
				,TIN_QteUniteTIN = 0
				,TIN_QteBeneficiaire_0 = 0
				,TIN_QteBeneficiaire_1 = 0
				,TIN_QteBeneficiaire_2 = 0
				,TIN_QteBeneficiaire_3 = 0
				,TIN_QteBeneficiaire_4 = 0
				,TIN_QteBeneficiaire_5 = 0
				,TIN_QteBeneficiaire_6 = 0
				,TIN_QteBeneficiaire_7 = 0
				,TIN_QteBeneficiaire_8 = 0
				,TIN_QteBeneficiaire_9 = 0
				,TIN_QteBeneficiaire_10 = 0
				,TIN_QteBeneficiaire_11 = 0
				,TIN_QteBeneficiaire_12 = 0
				,TIN_QteBeneficiaire_13 = 0
				,TIN_QteBeneficiaire_14 = 0
				,TIN_QteBeneficiaire_15 = 0
				,TIN_QteBeneficiaire_16 = 0
				,TIN_QteBeneficiaire_17_Plus = 0	

			from (

				select DISTINCT c.ConventionNo
					, c.BeneficiaryID
					,BeneficiaryID_0 = case when dbo.fn_Mo_Age(hb.BirthDate,o.OperDate) = 0 then bh.iID_Nouveau_Beneficiaire else null end
					,BeneficiaryID_1 = case when dbo.fn_Mo_Age(hb.BirthDate,o.OperDate) = 1 then bh.iID_Nouveau_Beneficiaire else null end
					,BeneficiaryID_2 = case when dbo.fn_Mo_Age(hb.BirthDate,o.OperDate) = 2 then bh.iID_Nouveau_Beneficiaire else null end
					,BeneficiaryID_3 = case when dbo.fn_Mo_Age(hb.BirthDate,o.OperDate) = 3 then bh.iID_Nouveau_Beneficiaire else null end
					,BeneficiaryID_4 = case when dbo.fn_Mo_Age(hb.BirthDate,o.OperDate) = 4 then bh.iID_Nouveau_Beneficiaire else null end
					,BeneficiaryID_5 = case when dbo.fn_Mo_Age(hb.BirthDate,o.OperDate) = 5 then bh.iID_Nouveau_Beneficiaire else null end
					,BeneficiaryID_6 = case when dbo.fn_Mo_Age(hb.BirthDate,o.OperDate) = 6 then bh.iID_Nouveau_Beneficiaire else null end
					,BeneficiaryID_7 = case when dbo.fn_Mo_Age(hb.BirthDate,o.OperDate) = 7 then bh.iID_Nouveau_Beneficiaire else null end
					,BeneficiaryID_8 = case when dbo.fn_Mo_Age(hb.BirthDate,o.OperDate) = 8 then bh.iID_Nouveau_Beneficiaire else null end
					,BeneficiaryID_9 = case when dbo.fn_Mo_Age(hb.BirthDate,o.OperDate) = 9 then bh.iID_Nouveau_Beneficiaire else null end
					,BeneficiaryID_10 = case when dbo.fn_Mo_Age(hb.BirthDate,o.OperDate) = 10 then bh.iID_Nouveau_Beneficiaire else null end
					,BeneficiaryID_11 = case when dbo.fn_Mo_Age(hb.BirthDate,o.OperDate) = 11 then bh.iID_Nouveau_Beneficiaire else null end
					,BeneficiaryID_12 = case when dbo.fn_Mo_Age(hb.BirthDate,o.OperDate) = 12 then bh.iID_Nouveau_Beneficiaire else null end
					,BeneficiaryID_13 = case when dbo.fn_Mo_Age(hb.BirthDate,o.OperDate) = 13 then bh.iID_Nouveau_Beneficiaire else null end
					,BeneficiaryID_14 = case when dbo.fn_Mo_Age(hb.BirthDate,o.OperDate) = 14 then bh.iID_Nouveau_Beneficiaire else null end
					,BeneficiaryID_15 = case when dbo.fn_Mo_Age(hb.BirthDate,o.OperDate) = 15 then bh.iID_Nouveau_Beneficiaire else null end
					,BeneficiaryID_16 = case when dbo.fn_Mo_Age(hb.BirthDate,o.OperDate) = 16 then bh.iID_Nouveau_Beneficiaire else null end
					,BeneficiaryID_17_Plus = case when dbo.fn_Mo_Age(hb.BirthDate,o.OperDate) >= 17 then bh.iID_Nouveau_Beneficiaire else null end
					,c.SubscriberID, o.OperTypeID, o.OperDate, u.UnitID, QteUniteOUT = ur.UnitQty
				FROM Un_Convention C
				--join Mo_Human hb on c.BeneficiaryID = hb.HumanID
				JOIN Un_Unit U ON C.ConventionID= U.ConventionID
				--left join (	select UnitID,QtyRES =  sum(UnitQty) from Un_UnitReduction GROUP by UnitID	) ur on u.UnitID = ur.UnitID
				JOIN Un_Cotisation CT ON U.UnitID = CT.UnitID
				JOIN Un_Oper O ON CT.OperID = O.OperID
				JOIN Un_UnitReductionCotisation URC ON URC.CotisationID = Ct.CotisationID
				JOIN Un_UnitReduction ur ON urc.UnitReductionID = ur.UnitReductionID
				LEFT join Un_TIO tioOut  on o.OperID = tioOut.iOUTOperID
				LEFT join Un_TIO tioTin  on o.OperID = tioTin.iTINOperID
				LEFT JOIN Un_OperCancelation OC1 ON O.OperID = OC1.OperSourceID
				LEFT JOIN Un_OperCancelation OC2 ON O.OperID = OC2.OperID

				left join (
							select cbAvant.iID_Convention, cbAvant.iID_Nouveau_Beneficiaire, DateDu = cbAvant.dtDate_Changement_Beneficiaire, DateAu = isnull(CBapres.dtDate_Changement_Beneficiaire,'9999-12-31')
							from (
								select cb.iID_Convention, cb.iID_Changement_Beneficiaire, MIN_iID_Changement_Beneficiaire = min(CB2.iID_Changement_Beneficiaire)
								from tblCONV_ChangementsBeneficiaire CB
								left join tblCONV_ChangementsBeneficiaire CB2 on cb.iID_Convention = CB2.iID_Convention and CB2.iID_Changement_Beneficiaire > cb.iID_Changement_Beneficiaire
								GROUP by cb.iID_Convention, cb.iID_Changement_Beneficiaire
								)t
							JOIN tblCONV_ChangementsBeneficiaire cbAvant on t.iID_Changement_Beneficiaire = cbAvant.iID_Changement_Beneficiaire
							LEFT JOIN tblCONV_ChangementsBeneficiaire CBapres on t.MIN_iID_Changement_Beneficiaire = CBapres.iID_Changement_Beneficiaire
							--order by cbAvant.iID_Convention
					)bh on bh.iID_Convention = c.ConventionID and o.OperDate >= bh.DateDu and o.OperDate < bh.DateAu
				left join Mo_Human hb on hb.HumanID = bh.iID_Nouveau_Beneficiaire

				WHERE 1=1
					--AND C.ConventionNo = ''
					and o.OperDate BETWEEN @DateFrom and @DateTo
					and o.OperTypeID in ('OUT')
					AND OC1.OperSourceID IS NULL
					AND OC2.OperID IS NULL
					and tioOut.iOUTOperID IS NULL
					and tioTin.iTINOperID is NULL
				)OUTE


			UNION ALL

			SELECT 
				OUT_QteSousc = 0
				,OUT_QteConvention = 0
				,OUT_QteUniteOUT = 0
				,OUT_QteBeneficiaire_0 = 0
				,OUT_QteBeneficiaire_1 = 0
				,OUT_QteBeneficiaire_2 = 0
				,OUT_QteBeneficiaire_3 = 0
				,OUT_QteBeneficiaire_4 = 0
				,OUT_QteBeneficiaire_5 = 0
				,OUT_QteBeneficiaire_6 = 0
				,OUT_QteBeneficiaire_7 = 0
				,OUT_QteBeneficiaire_8 = 0
				,OUT_QteBeneficiaire_9 = 0
				,OUT_QteBeneficiaire_10 = 0
				,OUT_QteBeneficiaire_11 = 0
				,OUT_QteBeneficiaire_12 = 0
				,OUT_QteBeneficiaire_13 = 0
				,OUT_QteBeneficiaire_14 = 0
				,OUT_QteBeneficiaire_15 = 0
				,OUT_QteBeneficiaire_16 = 0
				,OUT_QteBeneficiaire_17_Plus = 0

				,TIN_QteSousc = COUNT(DISTINCT TIN.SubscriberID)
				,TIN_QteConvention = count(DISTINCT ConventionNo)
				,TIN_QteUniteTIN = 0
				,TIN_QteBeneficiaire_0 = count(DISTINCT BeneficiaryID_0)
				,TIN_QteBeneficiaire_1 = count(DISTINCT BeneficiaryID_1)
				,TIN_QteBeneficiaire_2 = count(DISTINCT BeneficiaryID_2)
				,TIN_QteBeneficiaire_3 = count(DISTINCT BeneficiaryID_3)
				,TIN_QteBeneficiaire_4 = count(DISTINCT BeneficiaryID_4)
				,TIN_QteBeneficiaire_5 = count(DISTINCT BeneficiaryID_5)
				,TIN_QteBeneficiaire_6 = count(DISTINCT BeneficiaryID_6)
				,TIN_QteBeneficiaire_7 = count(DISTINCT BeneficiaryID_7)
				,TIN_QteBeneficiaire_8 = count(DISTINCT BeneficiaryID_8)
				,TIN_QteBeneficiaire_9 = count(DISTINCT BeneficiaryID_9)
				,TIN_QteBeneficiaire_10 =count(DISTINCT BeneficiaryID_10)
				,TIN_QteBeneficiaire_11 =count(DISTINCT BeneficiaryID_11)
				,TIN_QteBeneficiaire_12 =count(DISTINCT BeneficiaryID_12)
				,TIN_QteBeneficiaire_13 = count(DISTINCT BeneficiaryID_13)
				,TIN_QteBeneficiaire_14 = count(DISTINCT BeneficiaryID_14)
				,TIN_QteBeneficiaire_15 = count(DISTINCT BeneficiaryID_15)
				,TIN_QteBeneficiaire_16 =count(DISTINCT BeneficiaryID_16)
				,TIN_QteBeneficiaire_17_Plus = count(DISTINCT BeneficiaryID_17_pLUS)
	
			from (

				select DISTINCT c.ConventionNo
					,c.BeneficiaryID
					,BeneficiaryID_0 = case when dbo.fn_Mo_Age(hb.BirthDate,o.OperDate) = 0 then bh.iID_Nouveau_Beneficiaire else null end
					,BeneficiaryID_1 = case when dbo.fn_Mo_Age(hb.BirthDate,o.OperDate) = 1 then bh.iID_Nouveau_Beneficiaire else null end
					,BeneficiaryID_2 = case when dbo.fn_Mo_Age(hb.BirthDate,o.OperDate) = 2 then bh.iID_Nouveau_Beneficiaire else null end
					,BeneficiaryID_3 = case when dbo.fn_Mo_Age(hb.BirthDate,o.OperDate) = 3 then bh.iID_Nouveau_Beneficiaire else null end
					,BeneficiaryID_4 = case when dbo.fn_Mo_Age(hb.BirthDate,o.OperDate) = 4 then bh.iID_Nouveau_Beneficiaire else null end
					,BeneficiaryID_5 = case when dbo.fn_Mo_Age(hb.BirthDate,o.OperDate) = 5 then bh.iID_Nouveau_Beneficiaire else null end
					,BeneficiaryID_6 = case when dbo.fn_Mo_Age(hb.BirthDate,o.OperDate) = 6 then bh.iID_Nouveau_Beneficiaire else null end
					,BeneficiaryID_7 = case when dbo.fn_Mo_Age(hb.BirthDate,o.OperDate) = 7 then bh.iID_Nouveau_Beneficiaire else null end
					,BeneficiaryID_8 = case when dbo.fn_Mo_Age(hb.BirthDate,o.OperDate) = 8 then bh.iID_Nouveau_Beneficiaire else null end
					,BeneficiaryID_9 = case when dbo.fn_Mo_Age(hb.BirthDate,o.OperDate) = 9 then bh.iID_Nouveau_Beneficiaire else null end
					,BeneficiaryID_10 = case when dbo.fn_Mo_Age(hb.BirthDate,o.OperDate) = 10 then bh.iID_Nouveau_Beneficiaire else null end
					,BeneficiaryID_11 = case when dbo.fn_Mo_Age(hb.BirthDate,o.OperDate) = 11 then bh.iID_Nouveau_Beneficiaire else null end
					,BeneficiaryID_12 = case when dbo.fn_Mo_Age(hb.BirthDate,o.OperDate) = 12 then bh.iID_Nouveau_Beneficiaire else null end
					,BeneficiaryID_13 = case when dbo.fn_Mo_Age(hb.BirthDate,o.OperDate) = 13 then bh.iID_Nouveau_Beneficiaire else null end
					,BeneficiaryID_14 = case when dbo.fn_Mo_Age(hb.BirthDate,o.OperDate) = 14 then bh.iID_Nouveau_Beneficiaire else null end
					,BeneficiaryID_15 = case when dbo.fn_Mo_Age(hb.BirthDate,o.OperDate) = 15 then bh.iID_Nouveau_Beneficiaire else null end
					,BeneficiaryID_16 = case when dbo.fn_Mo_Age(hb.BirthDate,o.OperDate) = 16 then bh.iID_Nouveau_Beneficiaire else null end
					,BeneficiaryID_17_Plus = case when dbo.fn_Mo_Age(hb.BirthDate,o.OperDate) >= 17 then bh.iID_Nouveau_Beneficiaire else null end

					,c.SubscriberID, o.OperTypeID, o.OperDate, u.UnitID, QteUniteTIN = u.UnitQty + isnull( ur.QtyRES,0)
				FROM Un_Convention C
				--join Mo_Human hb on c.BeneficiaryID = hb.HumanID
				JOIN Un_Unit U ON C.ConventionID= U.ConventionID
				left join (	select UnitID,QtyRES =  sum(UnitQty) from Un_UnitReduction GROUP by UnitID	) ur on u.UnitID = ur.UnitID
				JOIN Un_Cotisation CT ON U.UnitID = CT.UnitID
				JOIN Un_Oper O ON CT.OperID = O.OperID
				LEFT join Un_TIO tioOut  on o.OperID = tioOut.iOUTOperID
				LEFT join Un_TIO tioTin  on o.OperID = tioTin.iTINOperID
				LEFT JOIN Un_OperCancelation OC1 ON O.OperID = OC1.OperSourceID
				LEFT JOIN Un_OperCancelation OC2 ON O.OperID = OC2.OperID

				left join (
							select cbAvant.iID_Convention, cbAvant.iID_Nouveau_Beneficiaire, DateDu = cbAvant.dtDate_Changement_Beneficiaire, DateAu = isnull(CBapres.dtDate_Changement_Beneficiaire,'9999-12-31')
							from (
								select cb.iID_Convention, cb.iID_Changement_Beneficiaire, MIN_iID_Changement_Beneficiaire = min(CB2.iID_Changement_Beneficiaire)
								from tblCONV_ChangementsBeneficiaire CB
								left join tblCONV_ChangementsBeneficiaire CB2 on cb.iID_Convention = CB2.iID_Convention and CB2.iID_Changement_Beneficiaire > cb.iID_Changement_Beneficiaire
								GROUP by cb.iID_Convention, cb.iID_Changement_Beneficiaire
								)t
							JOIN tblCONV_ChangementsBeneficiaire cbAvant on t.iID_Changement_Beneficiaire = cbAvant.iID_Changement_Beneficiaire
							LEFT JOIN tblCONV_ChangementsBeneficiaire CBapres on t.MIN_iID_Changement_Beneficiaire = CBapres.iID_Changement_Beneficiaire
							--order by cbAvant.iID_Convention
					)bh on bh.iID_Convention = c.ConventionID and o.OperDate >= bh.DateDu and o.OperDate < bh.DateAu
				left join Mo_Human hb on hb.HumanID = bh.iID_Nouveau_Beneficiaire

				WHERE 1=1
					--AND C.ConventionNo = ''
					and o.OperDate BETWEEN @DateFrom and @DateTo
					and o.OperTypeID in ('TIN')
					AND OC1.OperSourceID IS NULL
					AND OC2.OperID IS NULL
					and tioOut.iOUTOperID IS NULL
					and tioTin.iTINOperID is NULL
				)TIN

			UNION ALL

			SELECT 
				OUT_QteSousc = 0
				,OUT_QteConvention = 0
				,OUT_QteUniteOUT = 0
				,OUT_QteBeneficiaire_0 = 0
				,OUT_QteBeneficiaire_1 = 0
				,OUT_QteBeneficiaire_2 = 0
				,OUT_QteBeneficiaire_3 = 0
				,OUT_QteBeneficiaire_4 = 0
				,OUT_QteBeneficiaire_5 = 0
				,OUT_QteBeneficiaire_6 = 0
				,OUT_QteBeneficiaire_7 = 0
				,OUT_QteBeneficiaire_8 = 0
				,OUT_QteBeneficiaire_9 = 0
				,OUT_QteBeneficiaire_10 = 0
				,OUT_QteBeneficiaire_11 = 0
				,OUT_QteBeneficiaire_12 = 0
				,OUT_QteBeneficiaire_13 = 0
				,OUT_QteBeneficiaire_14 = 0
				,OUT_QteBeneficiaire_15 = 0
				,OUT_QteBeneficiaire_16 = 0
				,OUT_QteBeneficiaire_17_Plus = 0

				,TIN_QteSousc = 0
				,TIN_QteConvention = 0
				,TIN_QteUniteTIN = SUM(QteUniteTIN)
				,TIN_QteBeneficiaire_0 = 0
				,TIN_QteBeneficiaire_1 = 0
				,TIN_QteBeneficiaire_2 = 0
				,TIN_QteBeneficiaire_3 = 0
				,TIN_QteBeneficiaire_4 = 0
				,TIN_QteBeneficiaire_5 = 0
				,TIN_QteBeneficiaire_6 = 0
				,TIN_QteBeneficiaire_7 = 0
				,TIN_QteBeneficiaire_8 = 0
				,TIN_QteBeneficiaire_9 = 0
				,TIN_QteBeneficiaire_10 =0
				,TIN_QteBeneficiaire_11 =0
				,TIN_QteBeneficiaire_12 =0
				,TIN_QteBeneficiaire_13 = 0
				,TIN_QteBeneficiaire_14 = 0
				,TIN_QteBeneficiaire_15 = 0
				,TIN_QteBeneficiaire_16 =0
				,TIN_QteBeneficiaire_17_Plus = 0
	
			from (

				select DISTINCT u.UnitID, QteUniteTIN = u.UnitQty + isnull( ur.QtyRES,0)
				FROM Un_Convention C
				JOIN Un_Unit U ON C.ConventionID= U.ConventionID
				left join (	select UnitID,QtyRES =  sum(UnitQty) from Un_UnitReduction GROUP by UnitID	) ur on u.UnitID = ur.UnitID
				JOIN Un_Cotisation CT ON U.UnitID = CT.UnitID
				JOIN Un_Oper O ON CT.OperID = O.OperID
				LEFT join Un_TIO tioOut  on o.OperID = tioOut.iOUTOperID
				LEFT join Un_TIO tioTin  on o.OperID = tioTin.iTINOperID
				LEFT JOIN Un_OperCancelation OC1 ON O.OperID = OC1.OperSourceID
				LEFT JOIN Un_OperCancelation OC2 ON O.OperID = OC2.OperID

				WHERE 1=1
					--AND C.ConventionNo = ''
					and o.OperDate BETWEEN @DateFrom and @DateTo
					and o.OperTypeID in ('TIN')
					AND OC1.OperSourceID IS NULL
					AND OC2.OperID IS NULL
					and tioOut.iOUTOperID IS NULL
					and tioTin.iTINOperID is NULL
				)TIN


			)Q	



		set @i = @i + 1
	end	 --while @i

	
	--select * from #Result --ORDER BY DateTo,AgeBenef

	/*
			,OUT_QteConvention INT
			,OUT_QteBeneficiaire_0 INT
			,OUT_QteBeneficiaire_1 INT
			,OUT_QteBeneficiaire_2 INT
			,OUT_QteBeneficiaire_3 INT
			,OUT_QteBeneficiaire_4 INT
			,OUT_QteBeneficiaire_5 INT
			,OUT_QteBeneficiaire_6 INT
			,OUT_QteBeneficiaire_7 INT
			,OUT_QteBeneficiaire_8 INT
			,OUT_QteBeneficiaire_9 INT
			,OUT_QteBeneficiaire_10 INT
			,OUT_QteBeneficiaire_11 INT
			,OUT_QteBeneficiaire_12 INT
			,OUT_QteBeneficiaire_13 INT
			,OUT_QteBeneficiaire_14 INT
			,OUT_QteBeneficiaire_15 INT
			,OUT_QteBeneficiaire_16 INT
			,OUT_QteBeneficiaire_17_Plus INT

			,TIN_QteConvention INT
			,TIN_QteBeneficiaire_0 INT
			,TIN_QteBeneficiaire_1 INT
			,TIN_QteBeneficiaire_2 INT
			,TIN_QteBeneficiaire_3 INT
			,TIN_QteBeneficiaire_4 INT
			,TIN_QteBeneficiaire_5 INT
			,TIN_QteBeneficiaire_6 INT
			,TIN_QteBeneficiaire_7 INT
			,TIN_QteBeneficiaire_8 INT
			,TIN_QteBeneficiaire_9 INT
			,TIN_QteBeneficiaire_10 INT
			,TIN_QteBeneficiaire_11 INT
			,TIN_QteBeneficiaire_12 INT
			,TIN_QteBeneficiaire_13 INT
			,TIN_QteBeneficiaire_14 INT
			,TIN_QteBeneficiaire_15 INT
			,TIN_QteBeneficiaire_16 INT
			,TIN_QteBeneficiaire_17_Plus INT
	*/

	INSERT into #Final values (
		1
		,'OUT_QteConvention'
		,(select OUT_QteConvention from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select OUT_QteConvention from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select OUT_QteConvention from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select OUT_QteConvention from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select OUT_QteConvention from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select OUT_QteConvention from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		2
		,'TIN_QteConvention'
		,(select TIN_QteConvention from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select TIN_QteConvention from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select TIN_QteConvention from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select TIN_QteConvention from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select TIN_QteConvention from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select TIN_QteConvention from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)

	INSERT into #Final values (
		2.3
		,'OUT_QteUniteOUT'
		,(select OUT_QteUniteOUT from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select OUT_QteUniteOUT from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select OUT_QteUniteOUT from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select OUT_QteUniteOUT from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select OUT_QteUniteOUT from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select OUT_QteUniteOUT from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)

	INSERT into #Final values (
		2.5
		,'TIN_QteUniteTIN'
		,(select TIN_QteUniteTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select TIN_QteUniteTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select TIN_QteUniteTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select TIN_QteUniteTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select TIN_QteUniteTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select TIN_QteUniteTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)

	INSERT into #Final values (
		3
		,'OUT_QteBeneficiaire_0'
		,(select OUT_QteBeneficiaire_0 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select OUT_QteBeneficiaire_0 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select OUT_QteBeneficiaire_0 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select OUT_QteBeneficiaire_0 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select OUT_QteBeneficiaire_0 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select OUT_QteBeneficiaire_0 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		4
		,'OUT_QteBeneficiaire_1'
		,(select OUT_QteBeneficiaire_1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select OUT_QteBeneficiaire_1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select OUT_QteBeneficiaire_1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select OUT_QteBeneficiaire_1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select OUT_QteBeneficiaire_1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select OUT_QteBeneficiaire_1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		5
		,'OUT_QteBeneficiaire_2'
		,(select OUT_QteBeneficiaire_2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select OUT_QteBeneficiaire_2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select OUT_QteBeneficiaire_2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select OUT_QteBeneficiaire_2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select OUT_QteBeneficiaire_2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select OUT_QteBeneficiaire_2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		6
		,'OUT_QteBeneficiaire_3'
		,(select OUT_QteBeneficiaire_3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select OUT_QteBeneficiaire_3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select OUT_QteBeneficiaire_3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select OUT_QteBeneficiaire_3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select OUT_QteBeneficiaire_3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select OUT_QteBeneficiaire_3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		7
		,'OUT_QteBeneficiaire_4'
		,(select OUT_QteBeneficiaire_4 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select OUT_QteBeneficiaire_4 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select OUT_QteBeneficiaire_4 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select OUT_QteBeneficiaire_4 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select OUT_QteBeneficiaire_4 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select OUT_QteBeneficiaire_4 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		8
		,'OUT_QteBeneficiaire_5'
		,(select OUT_QteBeneficiaire_5 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select OUT_QteBeneficiaire_5 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select OUT_QteBeneficiaire_5 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select OUT_QteBeneficiaire_5 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select OUT_QteBeneficiaire_5 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select OUT_QteBeneficiaire_5 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		9
		,'OUT_QteBeneficiaire_6'
		,(select OUT_QteBeneficiaire_6 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select OUT_QteBeneficiaire_6 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select OUT_QteBeneficiaire_6 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select OUT_QteBeneficiaire_6 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select OUT_QteBeneficiaire_6 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select OUT_QteBeneficiaire_6 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		10
		,'OUT_QteBeneficiaire_7'
		,(select OUT_QteBeneficiaire_7 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select OUT_QteBeneficiaire_7 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select OUT_QteBeneficiaire_7 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select OUT_QteBeneficiaire_7 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select OUT_QteBeneficiaire_7 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select OUT_QteBeneficiaire_7 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		11
		,'OUT_QteBeneficiaire_8'
		,(select OUT_QteBeneficiaire_8 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select OUT_QteBeneficiaire_8 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select OUT_QteBeneficiaire_8 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select OUT_QteBeneficiaire_8 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select OUT_QteBeneficiaire_8 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select OUT_QteBeneficiaire_8 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		12
		,'OUT_QteBeneficiaire_9'
		,(select OUT_QteBeneficiaire_9 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select OUT_QteBeneficiaire_9 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select OUT_QteBeneficiaire_9 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select OUT_QteBeneficiaire_9 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select OUT_QteBeneficiaire_9 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select OUT_QteBeneficiaire_9 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		13
		,'OUT_QteBeneficiaire_10'
		,(select OUT_QteBeneficiaire_10 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select OUT_QteBeneficiaire_10 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select OUT_QteBeneficiaire_10 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select OUT_QteBeneficiaire_10 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select OUT_QteBeneficiaire_10 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select OUT_QteBeneficiaire_10 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		14
		,'OUT_QteBeneficiaire_11'
		,(select OUT_QteBeneficiaire_11 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select OUT_QteBeneficiaire_11 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select OUT_QteBeneficiaire_11 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select OUT_QteBeneficiaire_11 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select OUT_QteBeneficiaire_11 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select OUT_QteBeneficiaire_11 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		15
		,'OUT_QteBeneficiaire_12'
		,(select OUT_QteBeneficiaire_12 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select OUT_QteBeneficiaire_12 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select OUT_QteBeneficiaire_12 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select OUT_QteBeneficiaire_12 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select OUT_QteBeneficiaire_12 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select OUT_QteBeneficiaire_12 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		16
		,'OUT_QteBeneficiaire_13'
		,(select OUT_QteBeneficiaire_13 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select OUT_QteBeneficiaire_13 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select OUT_QteBeneficiaire_13 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select OUT_QteBeneficiaire_13 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select OUT_QteBeneficiaire_13 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select OUT_QteBeneficiaire_13 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		17
		,'OUT_QteBeneficiaire_14'
		,(select OUT_QteBeneficiaire_14 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select OUT_QteBeneficiaire_14 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select OUT_QteBeneficiaire_14 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select OUT_QteBeneficiaire_14 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select OUT_QteBeneficiaire_14 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select OUT_QteBeneficiaire_14 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		18
		,'OUT_QteBeneficiaire_15'
		,(select OUT_QteBeneficiaire_15 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select OUT_QteBeneficiaire_15 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select OUT_QteBeneficiaire_15 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select OUT_QteBeneficiaire_15 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select OUT_QteBeneficiaire_15 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select OUT_QteBeneficiaire_15 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		19
		,'OUT_QteBeneficiaire_16'
		,(select OUT_QteBeneficiaire_16 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select OUT_QteBeneficiaire_16 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select OUT_QteBeneficiaire_16 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select OUT_QteBeneficiaire_16 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select OUT_QteBeneficiaire_16 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select OUT_QteBeneficiaire_16 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		20
		,'OUT_QteBeneficiaire_17_Plus'
		,(select OUT_QteBeneficiaire_17_Plus from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select OUT_QteBeneficiaire_17_Plus from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select OUT_QteBeneficiaire_17_Plus from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select OUT_QteBeneficiaire_17_Plus from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select OUT_QteBeneficiaire_17_Plus from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select OUT_QteBeneficiaire_17_Plus from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
		

	INSERT into #Final values (
		21
		,'TIN_QteBeneficiaire_0'
		,(select TIN_QteBeneficiaire_0 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select TIN_QteBeneficiaire_0 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select TIN_QteBeneficiaire_0 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select TIN_QteBeneficiaire_0 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select TIN_QteBeneficiaire_0 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select TIN_QteBeneficiaire_0 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		22
		,'TIN_QteBeneficiaire_1'
		,(select TIN_QteBeneficiaire_1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select TIN_QteBeneficiaire_1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select TIN_QteBeneficiaire_1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select TIN_QteBeneficiaire_1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select TIN_QteBeneficiaire_1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select TIN_QteBeneficiaire_1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		23
		,'TIN_QteBeneficiaire_2'
		,(select TIN_QteBeneficiaire_2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select TIN_QteBeneficiaire_2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select TIN_QteBeneficiaire_2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select TIN_QteBeneficiaire_2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select TIN_QteBeneficiaire_2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select TIN_QteBeneficiaire_2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		24
		,'TIN_QteBeneficiaire_3'
		,(select TIN_QteBeneficiaire_3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select TIN_QteBeneficiaire_3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select TIN_QteBeneficiaire_3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select TIN_QteBeneficiaire_3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select TIN_QteBeneficiaire_3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select TIN_QteBeneficiaire_3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		25
		,'TIN_QteBeneficiaire_4'
		,(select TIN_QteBeneficiaire_4 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select TIN_QteBeneficiaire_4 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select TIN_QteBeneficiaire_4 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select TIN_QteBeneficiaire_4 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select TIN_QteBeneficiaire_4 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select TIN_QteBeneficiaire_4 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		26
		,'TIN_QteBeneficiaire_5'
		,(select TIN_QteBeneficiaire_5 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select TIN_QteBeneficiaire_5 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select TIN_QteBeneficiaire_5 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select TIN_QteBeneficiaire_5 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select TIN_QteBeneficiaire_5 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select TIN_QteBeneficiaire_5 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		27
		,'TIN_QteBeneficiaire_6'
		,(select TIN_QteBeneficiaire_6 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select TIN_QteBeneficiaire_6 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select TIN_QteBeneficiaire_6 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select TIN_QteBeneficiaire_6 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select TIN_QteBeneficiaire_6 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select TIN_QteBeneficiaire_6 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		28
		,'TIN_QteBeneficiaire_7'
		,(select TIN_QteBeneficiaire_7 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select TIN_QteBeneficiaire_7 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select TIN_QteBeneficiaire_7 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select TIN_QteBeneficiaire_7 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select TIN_QteBeneficiaire_7 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select TIN_QteBeneficiaire_7 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		29
		,'TIN_QteBeneficiaire_8'
		,(select TIN_QteBeneficiaire_8 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select TIN_QteBeneficiaire_8 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select TIN_QteBeneficiaire_8 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select TIN_QteBeneficiaire_8 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select TIN_QteBeneficiaire_8 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select TIN_QteBeneficiaire_8 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		30
		,'TIN_QteBeneficiaire_9'
		,(select TIN_QteBeneficiaire_9 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select TIN_QteBeneficiaire_9 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select TIN_QteBeneficiaire_9 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select TIN_QteBeneficiaire_9 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select TIN_QteBeneficiaire_9 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select TIN_QteBeneficiaire_9 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		31
		,'TIN_QteBeneficiaire_10'
		,(select TIN_QteBeneficiaire_10 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select TIN_QteBeneficiaire_10 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select TIN_QteBeneficiaire_10 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select TIN_QteBeneficiaire_10 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select TIN_QteBeneficiaire_10 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select TIN_QteBeneficiaire_10 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		32
		,'TIN_QteBeneficiaire_11'
		,(select TIN_QteBeneficiaire_11 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select TIN_QteBeneficiaire_11 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select TIN_QteBeneficiaire_11 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select TIN_QteBeneficiaire_11 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select TIN_QteBeneficiaire_11 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select TIN_QteBeneficiaire_11 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		33
		,'TIN_QteBeneficiaire_12'
		,(select TIN_QteBeneficiaire_12 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select TIN_QteBeneficiaire_12 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select TIN_QteBeneficiaire_12 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select TIN_QteBeneficiaire_12 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select TIN_QteBeneficiaire_12 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select TIN_QteBeneficiaire_12 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		34
		,'TIN_QteBeneficiaire_13'
		,(select TIN_QteBeneficiaire_13 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select TIN_QteBeneficiaire_13 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select TIN_QteBeneficiaire_13 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select TIN_QteBeneficiaire_13 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select TIN_QteBeneficiaire_13 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select TIN_QteBeneficiaire_13 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		35
		,'TIN_QteBeneficiaire_14'
		,(select TIN_QteBeneficiaire_14 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select TIN_QteBeneficiaire_14 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select TIN_QteBeneficiaire_14 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select TIN_QteBeneficiaire_14 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select TIN_QteBeneficiaire_14 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select TIN_QteBeneficiaire_14 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		36
		,'TIN_QteBeneficiaire_15'
		,(select TIN_QteBeneficiaire_15 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select TIN_QteBeneficiaire_15 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select TIN_QteBeneficiaire_15 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select TIN_QteBeneficiaire_15 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select TIN_QteBeneficiaire_15 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select TIN_QteBeneficiaire_15 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		37
		,'TIN_QteBeneficiaire_16'
		,(select TIN_QteBeneficiaire_16 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select TIN_QteBeneficiaire_16 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select TIN_QteBeneficiaire_16 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select TIN_QteBeneficiaire_16 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select TIN_QteBeneficiaire_16 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select TIN_QteBeneficiaire_16 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		38
		,'TIN_QteBeneficiaire_17_Plus'
		,(select TIN_QteBeneficiaire_17_Plus from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select TIN_QteBeneficiaire_17_Plus from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select TIN_QteBeneficiaire_17_Plus from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select TIN_QteBeneficiaire_17_Plus from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select TIN_QteBeneficiaire_17_Plus from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select TIN_QteBeneficiaire_17_Plus from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		39
		,'OUT_QteSousc'
		,(select OUT_QteSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select OUT_QteSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select OUT_QteSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select OUT_QteSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select OUT_QteSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select OUT_QteSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		40
		,'TIN_QteSousc'
		,(select TIN_QteSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select TIN_QteSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select TIN_QteSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select TIN_QteSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select TIN_QteSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select TIN_QteSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)

	select * from #Final order by sort

END

-- exec psGENE_StatOrg_Q2_BrutParAge '2016-05-31'