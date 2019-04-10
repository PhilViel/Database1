/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	psTEMP_RapportNortelAppelPresenteRepondu

Description         :	Rapport Nortel - appel répondu
Valeurs de retours  :	Dataset :

Note                :	2013-02-08	Donald Huppé	Création
						2013-04-22	Donald Huppé	enlever plage d'heure dans clause where (demande de J Gendron)
						2013-10-22	donald Huppé	glpi 10410 : Ajout de l'agent
						2013-12-13	Donald Huppé	pointe sur alias srvsql13
								
exec psTEMP_RapportNortelAppelPresenteRepondu '2013-12-01' , '2013-12-31'

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psTEMP_RapportNortelAppelPresenteRepondu] 
	(
	@DateDe datetime,
	@DateA	datetime
	)
	
AS
BEGIN

	declare @MySQL varchar (2000)


	select @MySQL = 

	-- Pour la liste des agent dans la table #t1, je prend la liste des agents dans la table rptagentdata car je n'ai pas trouvé la table spécifique des agents
	-- on prend le dernier name par agentId dans la plage de date car
	-- Johanne a renommer un agent au lieu d'en créer un nouveau alors l'ID 9 appartient a un ancien agent et l'agent actuel

	

	'
	
	SELECT ID.agentid, ID.name
	into #t1
	from (
		SELECT agentid, MAXfromdateAgent = MAX(fromdate) 
		FROM [srvsql13].ccrdb.dbo.rptagentdata
		where fromdate BETWEEN ''' +  LEFT(CONVERT(VARCHAR, @DateDe, 120), 10) + ''' and ''' + LEFT(CONVERT(VARCHAR, @DateA, 120), 10) + '''
		group by agentid
		) A
	JOIN (
		SELECT 
			agentid,name, MAXfromdateName = MAX(fromdate)    
		FROM [srvsql13].ccrdb.dbo.rptagentdata
		where fromdate BETWEEN ''' +  LEFT(CONVERT(VARCHAR, @DateDe, 120), 10) + ''' and ''' + LEFT(CONVERT(VARCHAR, @DateA, 120), 10) + '''
		group by agentid,name
		)ID ON A.agentid = ID.agentid AND A.MAXfromdateAgent = ID.MAXfromdateName


	SELECT DISTINCT 
			ssid, 
			GroupeDequalification =  name + '' ('' + cast (ssid AS VARCHAR(1)) + '')''
			into #t2
	from [srvsql13].ccrdb.dbo.rptssdata
	
	
	select 
		LaDate = LEFT(CONVERT(VARCHAR, starttime, 120), 10)
		,Heure =  LEFT(CONVERT(VARCHAR, starttime, 114), 5)
		,cd.clid
		,cd.dnis
		,ss.GroupeDequalification
		,Qte= 1
		,DuréeDeLaRéponseSeconde = cast( datediff(s,cd.starttime, cdc.timestart) as float)
		,AgentName = a.name
	from 
		[srvsql13].ccrdb.dbo.rptcalldataconnection cdc
		join [srvsql13].ccrdb.dbo.rptcalldata cd ON cdc.rptcalldata_id = cd.rptcalldata_id
		left join [srvsql13].ccrdb.dbo.rptcalldataagentinfo ai on ai.rptcalldataconnection_id = cdc.rptcalldataconnection_id
		left join [srvsql13].ccrdb.dbo.rptcalldataactivitycode ac ON ac.rptcalldataagentinfo_id = ai.rptcalldataagentinfo_id
		join #t2 ss ON ss.ssid = cdc.ssid
		LEFT JOIN #t1 a on a.agentid = ai.agentinfoid
	where 
		1=1
		and LEFT(CONVERT(VARCHAR, timestart, 120), 10) BETWEEN ''' +  LEFT(CONVERT(VARCHAR, @DateDe, 120), 10) + ''' and ''' + LEFT(CONVERT(VARCHAR, @DateA, 120), 10) +
		''' AND dntypeinfo <> ''CDN''
	ORDER by timestart'

	--print @MySQL

	exec (@MySQL)

END
