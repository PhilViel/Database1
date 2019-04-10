/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	psTEMP_RapportNortelProfilAgent

Description         :	Rapport Nortel - Rapport sur le profil de l'agent
Valeurs de retours  :	Dataset :

Note                :	2015-02-06	Donald Huppé	Création
								
exec psTEMP_RapportNortelProfilAgent '2015-01-22' , '2015-01-22', 4, 0

								
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psTEMP_RapportNortelProfilAgent] 
	(
	@DateDu datetime
	,@DateAu datetime
	,@SSID int
	,@AgentID int	
	)
	
AS
BEGIN

	declare @MySQL varchar (5000)



	select @MySQL = 


	'select 

		GroupeQualif
		,ssid
		,agentid
		,Agent
		,EnDateDu = LEFT(CONVERT(VARCHAR, SessionDebut, 120), 10)
		,SessionDebut = right(CONVERT(VARCHAR, SessionDebut, 120),8)
		,SessionFin = right(CONVERT(VARCHAR, SessionFin, 120),8)
		,DureeConnexion = CONVERT(VARCHAR, DATEADD(s, DureeConnexionSeconde, 0), 108)
		,DureeConnexionSeconde
		,DureeDisponible = CONVERT(VARCHAR, DATEADD(s, DureeDisponibleSeconde, 0), 108)
		,DureeDisponibleSeconde
		,DureeNonPret = CONVERT(VARCHAR, DATEADD(s, DureeNonPretSeconde, 0), 108)
		,DureeNonPretSeconde
		,DureePause = CONVERT(VARCHAR, DATEADD(s, DureePauseSeconde, 0), 108)
		,DureePauseSeconde
		,DureeAppelEntrant = CONVERT(VARCHAR, DATEADD(s, DureeAppelEntrantSeconde, 0), 108)
		,DureeAppelEntrantSeconde

	from (


		select 
			GroupeQualif = groupeQualif.skillsetname,
			ad.ssid,
			ad.agentid,
			Agent = agt.name,
			SessionDebut = ad.starttime,
			SessionFin = ad.endtime,
			DureeConnexionSeconde = isnull(cast( datediff(s,ad.starttime,ad.endtime) as int ),0)
			,DureeDisponibleSeconde = case 
						when isnull(cast( datediff(s,ad.starttime,ad.endtime) as int ) - isnull(sum(DureeAppelEntrantSeconde),0) - isnull(EnPause.DureePauseSeconde,0) - DureeNonPretSeconde,0) < 0 then 0 
						else isnull(cast( datediff(s,ad.starttime,ad.endtime) as int ) - isnull(sum(DureeAppelEntrantSeconde),0) - isnull(EnPause.DureePauseSeconde,0) - DureeNonPretSeconde,0)  
						end
			,DureeNonPretSeconde = isnull(DureeNonPretSeconde,0)
			,DureePauseSeconde = isnull(EnPause.DureePauseSeconde,0)
			,DureeAppelEntrantSeconde = isnull(sum(DureeAppelEntrantSeconde),0)
		from 
			[srvsql13].ccrdb.dbo.rptagentdata ad
			join [srvsql13].ccrdb.dbo.skillsets groupeQualif on groupeQualif.id = ad.ssid
			join (
				SELECT ID.agentid, ID.name
				from (
					SELECT agentid, MAXfromdateAgent = MAX(fromdate) 
					FROM [srvsql13].ccrdb.dbo.rptagentdata
					where LEFT(CONVERT(VARCHAR, fromdate, 120), 10) BETWEEN ''' + LEFT(CONVERT(VARCHAR, @DateDu, 120), 10) + ''' and ''' + LEFT(CONVERT(VARCHAR, @DateAu, 120), 10) + '''
					group by agentid
					) A
				JOIN (
					SELECT 
						agentid,name, MAXfromdateName = MAX(fromdate)    
					FROM [srvsql13].ccrdb.dbo.rptagentdata
					where LEFT(CONVERT(VARCHAR, fromdate, 120), 10)  BETWEEN ''' + LEFT(CONVERT(VARCHAR, @DateDu, 120), 10) + ''' and ''' + LEFT(CONVERT(VARCHAR, @DateAu, 120), 10) + '''
					group by agentid,name
					)ID ON A.agentid = ID.agentid AND A.MAXfromdateAgent = ID.MAXfromdateName
				)agt on agt.agentid = ad.agentid
			left join (
				select DISTINCT
					anr.rptagentdata_id,
					DureeNonPretSeconde = sum(cast( datediff(s,anr.startdate,anr.enddate) as int ))
				from [srvsql13].ccrdb.dbo.[rptagentnotreadytime] anr
				group by anr.rptagentdata_id
				)NonPret on NonPret.rptagentdata_id = ad.rptagentdata_id
			left join (
				select
					ad.rptagentdata_id  
					,DureePauseSeconde = sum(cast( datediff(s,idl.startdate,idl.enddate) as int ))
				from [srvsql13].ccrdb.dbo.[rptagentidletime] idl
				join [srvsql13].ccrdb.dbo.[rptagentdata] ad on idl.rptagentdata_id = ad.rptagentdata_id

				GROUP by ad.rptagentdata_id 
				) EnPause on enPause.rptagentdata_id = ad.rptagentdata_id
			left join (
				select 
					da.agentinfoid,
					dc.ssid,
					DateDebut = cd.pegtimestart,
					DureeAppelEntrantSeconde = cast( datediff(s,cd.pegtimestart,cd.pegtimeend) as int )
				from 
					[srvsql13].ccrdb.dbo.rptcalldataactivitycode cd
					join [srvsql13].ccrdb.dbo.rptcalldataagentinfo da on cd.rptcalldataagentinfo_id = da.rptcalldataagentinfo_id
					join [srvsql13].ccrdb.dbo.rptcalldataconnection dc on dc.rptcalldataconnection_id = da.rptcalldataconnection_id
					where 
					LEFT(CONVERT(VARCHAR, cd.pegtimestart, 120), 10) BETWEEN ''' + LEFT(CONVERT(VARCHAR, @DateDu, 120), 10) + ''' and ''' + LEFT(CONVERT(VARCHAR, @DateAu, 120), 10) + '''
				)AppelEntrant on 
					AppelEntrant.agentinfoid = ad.agentid and --même agent
					AppelEntrant.ssid = ad.ssid and --même groupe de qualif
					AppelEntrant.DateDebut BETWEEN ad.starttime and ad.endtime -- appel débute pendant la session
		where 
			LEFT(CONVERT(VARCHAR, ad.starttime, 120), 10) BETWEEN ''' + LEFT(CONVERT(VARCHAR, @DateDu, 120), 10) + ''' and ''' + LEFT(CONVERT(VARCHAR, @DateAu, 120), 10) + '''' 
			+ case when @SSID <> 0 then 'and ad.ssid = ' + cast (@SSID as varchar) else '' end
			+ case when @AgentID <> 0 then 'and ad.agentid = ' + cast (@AgentID as varchar) else '' end
			+ '
		GROUP BY
			groupeQualif.skillsetname
			,ad.agentid
			,ad.rptagentdata_id
			,ad.ssid
			,agt.name
			,ad.starttime
			,ad.endtime
			,cast( datediff(s,ad.starttime,ad.endtime) as int )
			,DureeNonPretSeconde
			,EnPause.DureePauseSeconde
		) v

	order BY
		Agent,
		ssid,
		EnDateDu,
		SessionDebut'

	--print @MySQL
	exec (@MySQL)
	
/*

select 

		GroupeQualif
		,ssid
		,agentid
		,Agent
		,EnDateDu = LEFT(CONVERT(VARCHAR, SessionDebut, 120), 10)
		,SessionDebut = right(CONVERT(VARCHAR, SessionDebut, 120),8)
		,SessionFin = right(CONVERT(VARCHAR, SessionFin, 120),8)
		,DureeConnexion = CONVERT(VARCHAR, DATEADD(s, DureeConnexionSeconde, 0), 108)
		,DureeConnexionSeconde
		,DureeDisponible = CONVERT(VARCHAR, DATEADD(s, DureeDisponibleSeconde, 0), 108)
		,DureeDisponibleSeconde
		,DureeNonPret = CONVERT(VARCHAR, DATEADD(s, DureeNonPretSeconde, 0), 108)
		,DureeNonPretSeconde
		,DureePause = CONVERT(VARCHAR, DATEADD(s, DureePauseSeconde, 0), 108)
		,DureePauseSeconde
		,DureeAppelEntrant = CONVERT(VARCHAR, DATEADD(s, DureeAppelEntrantSeconde, 0), 108)
		,DureeAppelEntrantSeconde

	from (


		select 
			GroupeQualif = groupeQualif.skillsetname,
			ad.ssid,
			ad.agentid,
			Agent = agt.name,
			SessionDebut = ad.starttime,
			SessionFin = ad.endtime,
			DureeConnexionSeconde = isnull(cast( datediff(s,ad.starttime,ad.endtime) as int ),0)
			,DureeDisponibleSeconde = isnull(cast( datediff(s,ad.starttime,ad.endtime) as int ) - isnull(sum(DureeAppelEntrantSeconde),0) - isnull(EnPause.DureePauseSeconde,0) - DureeNonPretSeconde,0)
			,DureeNonPretSeconde = isnull(DureeNonPretSeconde,0)
			,DureePauseSeconde = isnull(EnPause.DureePauseSeconde,0)
			,DureeAppelEntrantSeconde = isnull(sum(DureeAppelEntrantSeconde),0)
		from 
			[srvsql13].ccrdb.dbo.rptagentdata ad
			join [srvsql13].ccrdb.dbo.skillsets groupeQualif on groupeQualif.id = ad.ssid
			join (
				SELECT ID.agentid, ID.name
				from (
					SELECT agentid, MAXfromdateAgent = MAX(fromdate) 
					FROM [srvsql13].ccrdb.dbo.rptagentdata
					where LEFT(CONVERT(VARCHAR, fromdate, 120), 10) BETWEEN '2015-01-19' and '2015-01-23'
					group by agentid
					) A
				JOIN (
					SELECT 
						agentid,name, MAXfromdateName = MAX(fromdate)    
					FROM [srvsql13].ccrdb.dbo.rptagentdata
					where LEFT(CONVERT(VARCHAR, fromdate, 120), 10)  BETWEEN '2015-01-19' and '2015-01-23'
					group by agentid,name
					)ID ON A.agentid = ID.agentid AND A.MAXfromdateAgent = ID.MAXfromdateName
				)agt on agt.agentid = ad.agentid
			left join (
				select DISTINCT
					anr.rptagentdata_id,
					DureeNonPretSeconde = sum(cast( datediff(s,anr.startdate,anr.enddate) as int ))
				from [srvsql13].ccrdb.dbo.[rptagentnotreadytime] anr
				group by anr.rptagentdata_id
				)NonPret on NonPret.rptagentdata_id = ad.rptagentdata_id
			left join (
				select
					ad.rptagentdata_id  
					,DureePauseSeconde = sum(cast( datediff(s,idl.startdate,idl.enddate) as int ))
				from [srvsql13].ccrdb.dbo.[rptagentidletime] idl
				join [srvsql13].ccrdb.dbo.[rptagentdata] ad on idl.rptagentdata_id = ad.rptagentdata_id

				GROUP by ad.rptagentdata_id 
				) EnPause on enPause.rptagentdata_id = ad.rptagentdata_id
			left join (
				select 
					da.agentinfoid,
					dc.ssid,
					DateDebut = cd.pegtimestart,
					DureeAppelEntrantSeconde = cast( datediff(s,cd.pegtimestart,cd.pegtimeend) as int )
				from 
					[srvsql13].ccrdb.dbo.rptcalldataactivitycode cd
					join [srvsql13].ccrdb.dbo.rptcalldataagentinfo da on cd.rptcalldataagentinfo_id = da.rptcalldataagentinfo_id
					join [srvsql13].ccrdb.dbo.rptcalldataconnection dc on dc.rptcalldataconnection_id = da.rptcalldataconnection_id
					where 
					LEFT(CONVERT(VARCHAR, cd.pegtimestart, 120), 10) BETWEEN '2015-01-19' and '2015-01-23'
				)AppelEntrant on 
					AppelEntrant.agentinfoid = ad.agentid and --même agent
					AppelEntrant.ssid = ad.ssid and --même groupe de qualif
					AppelEntrant.DateDebut BETWEEN ad.starttime and ad.endtime -- appel débute pendant la session
		where 
			LEFT(CONVERT(VARCHAR, ad.starttime, 120), 10) BETWEEN '2015-01-19' and '2015-01-23'
		GROUP BY
			groupeQualif.skillsetname
			,ad.agentid
			,ad.rptagentdata_id
			,ad.ssid
			,agt.name
			,ad.starttime
			,ad.endtime
			,cast( datediff(s,ad.starttime,ad.endtime) as int )
			,DureeNonPretSeconde
			,EnPause.DureePauseSeconde
		) v

	order BY
		Agent,
		ssid,
		EnDateDu,
		SessionDebut

*/


END
