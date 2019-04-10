/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	psTEMP_RapportNortelMoyPreposeAppelSortant

Description         :	Rapport Nortel des appel sortant - moyenne par préposé
Valeurs de retours  :	Dataset :

Note                :	2013-02-08	Donald Huppé	Création
						2013-04-08	Donald Huppé	GLPI 9457 : convertir da.timestart en YYYY-mm-dd dans la clause where 
													car c'est un bug  qui emp^che de sortir les données pour une seule journée
													Et ça comble le besoin du glpi.
						2013-12-13	Donald Huppé	pointe sur alias srvsql13

								
exec psTEMP_RapportNortelMoyPreposeAppelSortant '2013-12-01' , '2013-12-31'
								
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psTEMP_RapportNortelMoyPreposeAppelSortant] 
	(
	@DateDe datetime,
	@DateA	datetime
	)
	
AS
BEGIN
	declare @MySQL varchar (2000)


	select @MySQL = '
	
	select agentID, name into #tAgt from [srvsql13].ccrdb.dbo.rptagentdata group by agentID, name 

	SELECT 

		préposé = agt.name
		,Qte = 1
		,DureeSeconde = cast( datediff(s,da.timestart,da.timeend) as float)

	FROM 
		[srvsql13].ccrdb.dbo.rptcalldataconnection da
		join [srvsql13].ccrdb.dbo.rptcalldataagentinfo dc on dc.rptcalldataconnection_id = da.rptcalldataconnection_id
		join #tAgt agt on dc.agentinfoid = agt.agentID
	where 
		LEFT(CONVERT(VARCHAR, da.timestart, 120), 10) between  ''' +  LEFT(CONVERT(VARCHAR, @DateDe, 120), 10) + ''' and ''' + LEFT(CONVERT(VARCHAR, @DateA, 120), 10) + '''
		and da.calltype = ''out'' and da.devtype = ''Agnt''
	order by 
		agt.name '

	exec (@MySQL)

END
