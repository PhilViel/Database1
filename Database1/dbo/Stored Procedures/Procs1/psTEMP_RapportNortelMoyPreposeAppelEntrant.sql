/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	psTEMP_RapportNortelMoyPreposeAppelEntrant

Description         :	Rapport Nortel des appel entrant - moyenne par préposé
Valeurs de retours  :	Dataset :

Note                :	2013-02-08	Donald Huppé	Création
						2013-04-08	Donald Huppé	GLPI 9457 : convertir cd.pegtimestart en YYYY-mm-dd dans la clause where 
													car c'est un bug  qui emp^che de sortir les données pour une seule journée
													Et ça comble le besoin du glpi.
						2013-11-05	Donald Huppé	Modification de la liste des agent pour gérer le doublon de L'agent ID 9 (FREDERIQUE  et STEPHANIE)
						2013-12-13	Donald Huppé	pointe sur alias srvsql13
								
exec psTEMP_RapportNortelMoyPreposeAppelEntrant_new '2013-01-01' , '2013-01-31'
exec psTEMP_RapportNortelMoyPreposeAppelEntrant '2013-12-01' , '2013-12-31'
				
drop proc psTEMP_RapportNortelMoyPreposeAppelEntrant_new
								
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psTEMP_RapportNortelMoyPreposeAppelEntrant] 
	(
	@DateDe datetime,
	@DateA	datetime
	)
	
AS
BEGIN
--=Format(TimeSerial(0,0,avg(Fields!SecondeDuree.Value)),"HH:mm:ss")
/*
	( select agentID, name /*into #tAgt*/ from [srvsql13].ccrdb.dbo.rptagentdata group by agentID, name )

	select 
		Prepose = agt.name,
		reason = case when reason = 'ManTrans' then 'Tr' else '' end,
		langue = ssid,
		ID = cd.rptcalldataactivitycode_id
		,Qte = 1
		,DureeSeconde = cast( datediff(s,cd.pegtimestart,cd.pegtimeend) as float)

	from 
		[srvsql13].ccrdb.dbo.rptcalldataactivitycode cd
		join [srvsql13].ccrdb.dbo.rptcalldataagentinfo da on cd.rptcalldataagentinfo_id = da.rptcalldataagentinfo_id
		join #tAgt agt on da.agentinfoid = agt.agentID
		join [srvsql13].ccrdb.dbo.rptcalldataconnection dc on dc.rptcalldataconnection_id = da.rptcalldataconnection_id
	where 
		LEFT(CONVERT(VARCHAR, cd.pegtimestart, 120), 10) BETWEEN @DateDe AND @DateA
		--and agt.name = 'FREDERIQUE'

	order by agt.name,reason,ssid -- Pour la moyenne par préposé

*/


	declare @MySQL varchar (2000)


	select @MySQL = 

	-- Pour la liste des agent dans la table #t1, je prend la liste des agents dans la table rptagentdata car je n'ai pas trouvé la table spécifique des agents
	-- on prend le dernier name par agentId dans la plage de date car
	-- Johanne a renommer un agent au lieu d'en créer un nouveau alors l'ID 9 appartient a un ancien agent et l'agent actuel

	

	'
	
	SELECT ID.agentid, ID.name
	into #tAgt
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

	
	
	select 
		Prepose = agt.name,
		reason = case when reason = ''ManTrans'' then ''Tr'' else '''' end,
		langue = ssid,
		ID = cd.rptcalldataactivitycode_id
		,Qte = 1
		,DureeSeconde = cast( datediff(s,cd.pegtimestart,cd.pegtimeend) as float)

	from 
		[srvsql13].ccrdb.dbo.rptcalldataactivitycode cd
		join [srvsql13].ccrdb.dbo.rptcalldataagentinfo da on cd.rptcalldataagentinfo_id = da.rptcalldataagentinfo_id
		join #tAgt agt on da.agentinfoid = agt.agentID
		join [srvsql13].ccrdb.dbo.rptcalldataconnection dc on dc.rptcalldataconnection_id = da.rptcalldataconnection_id
		where 
		LEFT(CONVERT(VARCHAR, cd.pegtimestart, 120), 10) BETWEEN ''' +  LEFT(CONVERT(VARCHAR, @DateDe, 120), 10) + ''' and ''' + LEFT(CONVERT(VARCHAR, @DateA, 120), 10) + ''' ' +
	'ORDER by agt.name,timestart'

	--print @MySQL

	exec (@MySQL)



END
