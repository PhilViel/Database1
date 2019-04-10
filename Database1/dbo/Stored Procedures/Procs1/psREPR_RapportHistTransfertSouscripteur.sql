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
Code de service		:		psGENE_RapportTransfertSouscripteurRep
Nom du service		:		Rapport sur les transferts de souscripteur d'un représentant à un autre
But					:		
Facette				:		GENE
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------

Exemple d'appel:
                
                EXEC psGENE_RapportTransfertSouscripteurRep '2011-03-04', '2011-03-04' , 0, 0, 559035
                EXEC psGENE_RapportTransfertSouscripteurRep '2011-03-04', '2011-03-04' , 0, 149602, 559035
				EXEC psGENE_RapportTransfertSouscripteurRep '2011-01-01', '2011-03-04' , 546640, 439395
                EXEC psGENE_RapportTransfertSouscripteurRep '2011-01-01', '2011-03-04' , 0, 559035    

Parametres de sortie :	Table						Champs										Description
						-----------------			---------------------------					-----------------------------
                   
Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2010-11-11					Donald Huppé							Création du service
						2017-09-27                  Pierre-Luc Simard                       Deprecated - Cette procédure n'est plus utilisée

drop procedure psGENE_RapportTransfertSouscripteurRep		

select *
from un_rep r
join mo_human h on r.repid = h.humanid
where h.firstname = 'marielle'

EXEC psREPR_RapportHistTransfertSouscripteur NULL,'1950-03-04', '2012-07-11' , 0,149483, 0

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psREPR_RapportHistTransfertSouscripteur] (
	@LoginNameID VARCHAR (255) = NULL, -- utilisé si appelé par uniaccès
	@dtStartDate DATETIME,
	@dtEndDate DATETIME,
	@iUserIDWhoTransfert INT = 0,  -- NON utilisé si appelé par uniaccès
	@iRepIDOri INT = 0, -- NON utilisé si appelé par uniaccès
	@iRepIDNew INT = 0  -- NON utilisé si appelé par uniaccès
	)
AS

BEGIN
    
    SELECT 1/0
    /*
	declare @SubscriberIDList varchar(8000)
	declare @SubscriberID int
	declare @UserID INTEGER
	declare @tRep TABLE (RepID INTEGER)
	declare @AskedByDirector int

	set @LoginNameID = substring(@LoginNameID, CHARINDEX ( '\' ,@LoginNameID , 1 ) + 1   , 99)

	select @UserID = UserID from mo_user where LoginNameID =  @LoginNameID

	IF EXISTS (	-- si c'est un rep (ou un boss) 
		SELECT u.UserID 
		FROM 
			mo_user u
			JOIN dbo.Mo_Human h on u.userid = h.humanid
			join un_rep r on h.humanid = r.repid
		WHERE u.userid = @UserID
			)
		BEGIN -- on va chercher les rep du boss ou le rep tout court
			INSERT @tRep
			EXECUTE SL_UN_BossOfRep @UserID
			SET @AskedByDirector = 1
		END
	ELSE
		BEGIN -- sinon, on insère tous les reps
			INSERT INTO @tRep SELECT REPID FROM UN_REP
			SET @AskedByDirector = 0
		END

	select
		OldRepID = case when isnumeric(SecondRecord)=0 then -1 else cast(FirstRecord as int) end,
		NewRepID = case when isnumeric(SecondRecord)=0 then cast(FirstRecord as int) else cast(SecondRecord as int) end,
		SubscriberID,
		logtime,
		userID
	into #V2
	from (
		select 
			SubscriberID = l.logcodeid,
			FirstRecord = Replace(
						SUBSTRING(
							LOGTEXT, 
							CHARINDEX('RepID',logtext,1) + 6, 
							CHARINDEX(CHAR(30),logtext,  CHARINDEX('RepID',logtext,1) + 9  ) -1  - (CHARINDEX('RepID',logtext,1) + 5))
							,char(30),''),
			
			SecondRecord = Replace(
						SUBSTRING(
							LOGTEXT, 
							CHARINDEX(CHAR(30),logtext,  CHARINDEX('RepID',logtext,1) + 9  ) + 1, 
							CHARINDEX(CHAR(30),logtext,  CHARINDEX('RepID',logtext,1) + 18  )  - CHARINDEX(CHAR(30),logtext,  CHARINDEX('RepID',logtext,1) + 9  )  )
						,char(30),''),
			logtime,
			userID
		from 
			crq_log l
			join mo_connect cn on l.ConnectID = cn.ConnectID -- select * from mo_connect
		where 
			logtablename = 'Un_Subscriber'
			and logtext like '%RepID%'
			and logactionid = 2
			and LEFT(CONVERT(VARCHAR, logtime, 120), 10) between @dtStartDate and @dtEndDate
			and (cn.userID = @iUserIDWhoTransfert OR @iUserIDWhoTransfert = 0)
			--and CHARINDEX(CHAR(30),logtext,1) not in (6,9,10)
		) V1

	SET @SubscriberIDList = ''

	DECLARE MyCursor CURSOR FOR

		SELECT SubscriberID from #V2

	OPEN MyCursor
	FETCH NEXT FROM MyCursor INTO @SubscriberID

	WHILE @@FETCH_STATUS = 0
	BEGIN
		
		set @SubscriberIDList = @SubscriberIDList + ltrim(rtrim(cast(@SubscriberID as varchar(7)))) + ','

		FETCH NEXT FROM MyCursor INTO @SubscriberID
	END
	CLOSE MyCursor
	DEALLOCATE MyCursor
	--set @SubscriberIDList = @SubscriberIDList + 'fin'

	--print @SubscriberIDList
	--return

	select 
		userID,
		UsagerTransfert = ht.FirstName + ' ' + ht.LastName,
		logtime, -- = LEFT(CONVERT(VARCHAR, logtime, 120), 10),
		V2.SubscriberID,
		Subscriber = hs.lastname + ' ' + hs.FirstName,
		BossOri.OldBossID,
		DirOri = CASE WHEN BossOri.OldBossID IS NULL THEN 'ND' ELSE hob.FirstName + ' ' + hob.LastName END,
		V2.OldRepID,
		RepOri = CASE WHEN V2.OldRepID = -1 THEN 'ND' ELSE hor.FirstName + ' ' + hor.LastName END,
		BossNew.NewBossID,
		DirNew = hbn.FirstName + ' ' + hbn.LastName,
		V2.NewRepID,
		RepNew = hnr.FirstName + ' ' + hnr.LastName,
		LastSignatureDateWithNewRep = LEFT(CONVERT(VARCHAR, vnr.LastSignatureDate, 120), 10),
		DateResil = LEFT(CONVERT(VARCHAR, sr.DateResil, 120), 10),
		--DateRI = case when Ferme.DateFerme IS NULL THEN LEFT(CONVERT(VARCHAR, SRI.DateRI, 120), 10) ELSE NULL end,
		DateRI = LEFT(CONVERT(VARCHAR, SRI.DateRI, 120), 10),
		SouscActif_dtFirstDeposit = LEFT(CONVERT(VARCHAR, Sv.dtFirstDeposit, 120), 10),
		DateFerme = LEFT(CONVERT(VARCHAR, Ferme.DateFerme, 120), 10)
	from 
		#V2 V2
		left JOIN @tRep RN ON V2.NewRepID = RN.RepID
		left JOIN @tRep RO ON V2.OldRepID = RO.RepID
		left join (
			SELECT
				RB.RepID,
				RB.StartDate,
				EndDate = isnull(RB.EndDate,'3000-01-01'),
				OldBossID = MAX(BossID) -- au cas ou il y a 2 boss avec le même %.  alors on prend l'id le + haut. ex : repid = 497171
			FROM 
				Un_RepBossHist RB
				JOIN (
					SELECT
						RepID,
						StartDate,
						EndDate,
						RepBossPct = MAX(RepBossPct)
					FROM 
						Un_RepBossHist RB
					WHERE 
						RepRoleID = 'DIR'
						AND StartDate IS NOT NULL
						--AND (StartDate <= @dtEndDate)
						--AND (EndDate IS NULL OR EndDate >= @dtEndDate)
					GROUP BY
						RepID,
						StartDate,
						EndDate
					) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct AND MRB.StartDate = RB.StartDate AND isnull(MRB.EndDate,'3000-01-01') = isnull(RB.EndDate,'3000-01-01')
			  WHERE RB.RepRoleID = 'DIR'
					AND RB.StartDate IS NOT NULL
					--AND (RB.StartDate <= @dtEndDate)
					--AND (RB.EndDate IS NULL OR RB.EndDate >= @dtEndDate)
			  GROUP BY
				RB.RepID,
				RB.StartDate,
				isnull(RB.EndDate,'3000-01-01')
			)BossOri on V2.OldRepID = BossOri.RepID and V2.logtime between BossOri.StartDate and BossOri.EndDate
		left join (
			SELECT
				RB.RepID,
				RB.StartDate,
				EndDate = isnull(RB.EndDate,'3000-01-01'),
				NewBossID = MAX(BossID) -- au cas ou il y a 2 boss avec le même %.  alors on prend l'id le + haut. ex : repid = 497171
			FROM 
				Un_RepBossHist RB
				JOIN (
					SELECT
						RepID,
						StartDate,
						EndDate,
						RepBossPct = MAX(RepBossPct)
					FROM 
						Un_RepBossHist RB
					WHERE 
						RepRoleID = 'DIR'
						AND StartDate IS NOT NULL
						--AND (StartDate <= @dtEndDate)
						--AND (EndDate IS NULL OR EndDate >= @dtEndDate)
					GROUP BY
						RepID,
						StartDate,
						EndDate
					) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct AND MRB.StartDate = RB.StartDate AND isnull(MRB.EndDate,'3000-01-01') = isnull(RB.EndDate,'3000-01-01')
			  WHERE RB.RepRoleID = 'DIR'
					AND RB.StartDate IS NOT NULL
					--AND (RB.StartDate <= @dtEndDate)
					--AND (RB.EndDate IS NULL OR RB.EndDate >= @dtEndDate)
			  GROUP BY
				RB.RepID,
				RB.StartDate,
				isnull(RB.EndDate,'3000-01-01')
			)BossNew on V2.NewRepID = BossNew.RepID and V2.logtime between BossNew.StartDate and BossNew.EndDate
		left JOIN dbo.Mo_Human hnr on V2.NewRepID = hnr.humanID
		left JOIN dbo.Mo_Human hs on V2.SubscriberID = hs.humanID
		left JOIN dbo.Mo_Human hbn on BossNew.NewBossID = hbn.humanID
		left JOIN dbo.Mo_Human ht ON ht.HumanID = V2.userid

		LEFT JOIN dbo.Mo_Human hob on BossOri.OldBossID = hob.HumanID
		LEFT JOIN dbo.Mo_Human hor on V2.OldRepID = hor.humanID

		left JOIN ( -- Dernier rep ayant signé avec le souscripteur
			SELECT c4.SubscriberID, u4.RepID, mu.LastSignatureDate
			FROM dbo.Un_Convention c4
			JOIN dbo.Un_Unit u4 ON c4.ConventionID = u4.ConventionID
			JOIN ( -- dernière signature
				SELECT c3.SubscriberID, LastSignatureDate = max(u3.SignatureDate)
				FROM dbo.Un_Convention c3
				JOIN dbo.Un_Unit u3 ON c3.ConventionID = u3.ConventionID
				GROUP by c3.SubscriberID
				)mu ON c4.SubscriberID = mu.SubscriberID AND u4.SignatureDate = mu.LastSignatureDate
			JOIN (-- dernier unitid par signature
				SELECT c5.SubscriberID, SignatureDate, maxunitid = max(u5.unitid)
				FROM dbo.Un_Convention c5
				JOIN dbo.Un_Unit u5 ON c5.ConventionID = u5.ConventionID
				GROUP by c5.SubscriberID, SignatureDate
				)mu2 ON c4.SubscriberID = mu2.SubscriberID AND mu.LastSignatureDate = mu2.SignatureDate AND u4.UnitID = mu2.maxunitid
			)vnr ON vnr.RepID = V2.NewRepID AND vnr.SubscriberID = V2.SubscriberID
		LEFT JOIN ( --sousc avec au moins un contrat non résilié
			SELECT c6.subscriberid
			FROM dbo.Un_Convention c6
			LEFT JOIN dbo.Un_Unit u6 ON c6.ConventionID = u6.ConventionID AND u6.TerminatedDate IS NOT null
			WHERE u6.ConventionID IS null
			GROUP by c6.subscriberid
			) nr ON V2.SubscriberID = nr.SubscriberID

		LEFT JOIN ( -- sousc complètement résilié
			select C7.SubscriberID,DateResil , NbGrUnit = count(*)
			FROM dbo.Un_Unit U7
			JOIN dbo.Un_Convention C7 ON U7.ConventionID = C7.ConventionID
			join (
				select C8.SubscriberID, nbResil = count(*), DateResil = max(terminateddate)
				FROM dbo.Un_Unit un8
				JOIN dbo.Un_Convention C8 ON Un8.ConventionID = C8.ConventionID
				join (
					select 
						us.unitid,
						uus.startdate,
						us.UnitStateID
					from 
						Un_UnitunitState us
						join (
							select 
							unitid,
							startdate = max(startDate)
							from un_unitunitstate
							--where LEFT(CONVERT(VARCHAR, startDate, 120), 10) <= '2010-06-01'
							group by unitid
							) uus on uus.unitid = us.unitid 
								and uus.startdate = us.startdate 
								and us.UnitStateID <> 'OUT'
					)uss ON un8.UnitID = uss.UnitID
				where terminateddate is not null
				group by C8.SubscriberID
				) Resil on C7.SubscriberID = Resil.SubscriberID
			group by C7.SubscriberID, Resil.nbResil,Resil.DateResil
			having count(*) = Resil.nbResil
			) sr ON V2.SubscriberID = sr.SubscriberID

		LEFT JOIN ( -- sousc complètement RI
			select C7.SubscriberID,DateRI , NbGrUnit = count(*)
			FROM dbo.Un_Unit U7
			JOIN dbo.Un_Convention C7 ON U7.ConventionID = C7.ConventionID
			join (
				select C8.SubscriberID, nbRI = count(*), DateRI = max(IntReimbDate)
				FROM dbo.Un_Unit un8
				JOIN dbo.Un_Convention C8 ON Un8.ConventionID = C8.ConventionID
				where IntReimbDate is not null
				group by C8.SubscriberID
				) RI on C7.SubscriberID = RI.SubscriberID
			group by C7.SubscriberID, RI.nbRI,RI.DateRI
			having count(*) = RI.nbRI
			) SRI ON V2.SubscriberID = SRI.SubscriberID

		LEFT JOIN ( --ACTIF : Souscripteur dont au moins un groupe d’unités est en vigueur et pour lequel il n’a pas reçu sont RI.
			SELECT c8.subscriberid, dtFirstDeposit = min(u9.dtFirstDeposit)
			FROM dbo.Un_Convention c8
			--au moins un groupe d’unités est en vigueur et pour lequel il n’a pas reçu sont RI.
			JOIN dbo.Un_Unit u8 ON c8.ConventionID = u8.ConventionID AND u8.IntReimbDate is null AND u8.TerminatedDate IS null
			--tous les groupoe d'unité
			JOIN dbo.Un_Unit u9 ON c8.ConventionID = u9.ConventionID
			GROUP by c8.subscriberid
			) Sv ON V2.SubscriberID = Sv.SubscriberID
			
		LEFT JOIN ( -- Fermé
			SELECT 
				s14.SubscriberID,
				Raison3brs = CASE when b3.subscriberid is not null then 1 ELSE 0 end,
				Raison35ans = CASE WHEN v35.subscriberid is not null then 1 ELSE 0 END,
				RaisonOut = CASE when COut.subscriberid is not null then 1 ELSE 0 end,
				DateFerme = CASE 
							WHEN isnull(LastDateBrs3,'1900-01-01') > isnull(Date35ans,'1900-01-01') AND isnull(LastDateBrs3,'1900-01-01') > isnull(DateOut,'1900-01-01') THEN LastDateBrs3
							WHEN isnull(Date35ans,'1900-01-01') > isnull(LastDateBrs3,'1900-01-01') AND isnull(Date35ans,'1900-01-01') > isnull(DateOut,'1900-01-01') THEN Date35ans
							when isnull(DateOut,'1900-01-01') > isnull(LastDateBrs3,'1900-01-01') AND isnull(DateOut,'1900-01-01') > isnull(Date35ans,'1900-01-01') THEN DateOut
							end
			FROM dbo.Un_Subscriber s14
			LEFT JOIN (
				-- toutes les bourses 3 sont payées
				select S.subscriberid,nb10.LastDateBrs3
				FROM dbo.Un_Subscriber s
				JOIN (
					SELECT c10.SubscriberID, NbConvNonResilie = count(DISTINCT c10.ConventionID)
					FROM dbo.Un_Convention c10
					JOIN dbo.Un_Unit u10 ON c10.ConventionID = u10.ConventionID
					WHERE u10.TerminatedDate IS null
					GROUP by c10.SubscriberID
					)nc10 ON s.SubscriberID = nc10.SubscriberID
				join (
					SELECT c11.SubscriberID, nbBrs3 = count(DISTINCT c11.ConventionID), LastDateBrs3 = max(op.OperDate)
					FROM dbo.Un_Convention c11 
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
							-- !!! mettre une journée de plus que la date demandée car on fait < ou lieu de <= !!!
							--where startDate < "Une Date Dans le temps" -- Si je veux l'état à une date précise 
							group by conventionid
							) ccs on ccs.conventionid = cs.conventionid 
								and ccs.startdate = cs.startdate 
								--and cs.ConventionStateID = 'FRM' -- je veux les convention qui ont cet état
					) css on C11.conventionid = css.conventionid
					JOIN Un_Scholarship sc11 ON c11.ConventionID = sc11.ConventionID AND ((sc11.ScholarshipNo >= 1 AND c11.PlanID = 4 AND css.ConventionStateID = 'FRM') OR (sc11.ScholarshipNo = 3 AND c11.PlanID <> 4)) AND sc11.ScholarshipStatusID = 'PAD'
					join Un_ScholarshipPmt Bp on Bp.ScholarshipID = sc11.ScholarshipID
					join un_oper op on bp.operid = op.operid
					group by c11.SubscriberID
					)nb10 ON s.SubscriberID = nb10.SubscriberID AND nc10.NbConvNonResilie = nb10.nbBrs3
				)b3 ON b3.subscriberid = s14.SubscriberID

			LEFT JOIN (	
				-- 35 ans vie de régime atteint
				SELECT c11.SubscriberID, Date35ans = cast(year(u11.signaturedate)+35 as varchar) + '-12-31'
				FROM dbo.Un_Convention c11
				JOIN (
					select Cs.conventionid,ccs.startdate,cs.ConventionStateID
					from un_conventionconventionstate cs
						join (select conventionid,startdate = max(startDate)
							from un_conventionconventionstate
							--where LEFT(CONVERT(VARCHAR, startDate, 120), 10) <= @LaDate
							group by conventionid
							) ccs on ccs.conventionid = cs.conventionid and ccs.startdate = cs.startdate and cs.ConventionStateID in ('REE','TRA')
					) css ON C11.ConventionID = css.conventionid
				left JOIN dbo.Un_Unit u11 ON c11.ConventionID = u11.ConventionID and u11.TerminatedDate IS null AND cast(year(u11.signaturedate)+35 as varchar) + '-12-31' < getdate()
				WHERE u11.ConventionID IS not null
				)v35 ON v35.SubscriberID = s14.SubscriberID
			LEFT JOIN (	
				-- Sousc complement OUT
				select C7.SubscriberID,DateOut , NbGrUnit = count(*)
				FROM dbo.Un_Unit U7
				JOIN dbo.Un_Convention C7 ON U7.ConventionID = C7.ConventionID
				join (
					select C8.SubscriberID, nbOut = count(*), DateOut = max(terminateddate)
					FROM dbo.Un_Unit un8
					JOIN dbo.Un_Convention C8 ON Un8.ConventionID = C8.ConventionID
					join (
						select 
							us.unitid,uus.startdate,us.UnitStateID
						from 
							Un_UnitunitState us
							join (select unitid, startdate = max(startDate)
								from un_unitunitstate
								--where LEFT(CONVERT(VARCHAR, startDate, 120), 10) <= '2010-06-01'
								group by unitid
								) uus on uus.unitid = us.unitid and uus.startdate = us.startdate and us.UnitStateID = 'OUT'
						)uss ON un8.UnitID = uss.UnitID
					where terminateddate is not null
					group by C8.SubscriberID
					) Resil on C7.SubscriberID = Resil.SubscriberID
				group by C7.SubscriberID, Resil.nbOut,Resil.DateOut
				having count(*) = Resil.nbOut
				) COut ON COut.SubscriberID = s14.SubscriberID
			WHERE b3.subscriberid is not null OR v35.subscriberid is not null or COut.subscriberid is not null
			) ferme on ferme.SubscriberID = V2.SubscriberID
		
	WHERE 
		(
			(@iRepIDOri =0 OR V2.OldRepID = @iRepIDOri OR BossOri.OldBossID = @iRepIDOri)
			AND
			(@iRepIDNew =0 OR V2.NewRepID = @iRepIDNew OR BossNew.NewBossID = @iRepIDNew)
		)
		AND
		(
		
			(@AskedByDirector = 1 AND (RN.Repid is NOT NULL  OR RO.Repid is NOT NULL) )
			OR
			(@AskedByDirector = 0)
		)
	ORDER BY
		ht.FirstName + ' ' + ht.LastName,
		logtime,
		CASE WHEN BossOri.OldBossID IS NULL THEN 'ND' ELSE hob.FirstName + ' ' + hob.LastName END,
		CASE WHEN V2.OldRepID = -1 THEN 'ND' ELSE hor.FirstName + ' ' + hor.LastName END,
		hbn.FirstName + ' ' + hbn.LastName,
		hnr.FirstName + ' ' + hnr.LastName
    */
End