/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	psTEMP_RapportNortelAppelPresenteAbandon

Description         :	Rapport Nortel - appel abandonné
Valeurs de retours  :	Dataset :

Note                :	2013-02-08	Donald Huppé	Création
						2013-04-22	Donald Huppé	enlever plage d'heure dans clause where (demande de J Gendron)
						2013-09-23	Donald Huppé	glpi 10217 : Ajout de clid, et mettre dans @MySQL afin que ça compile dans Maintenance_DEV
						2013-12-13	Donald Huppé	pointe sur alias srvsql13
								
exec psTEMP_RapportNortelAppelPresenteAbandon '2013-12-01' , '2013-12-31'

								
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psTEMP_RapportNortelAppelPresenteAbandon] 
	(
	@DateDe datetime,
	@DateA	datetime
	)
	
AS
BEGIN

	declare @MySQL varchar (2000)


	select @MySQL = 
	
	'select 
		LaDate = LEFT(CONVERT(VARCHAR, starttime, 120), 10)
		,Heure =  LEFT(CONVERT(VARCHAR, starttime, 114), 5)
		,cd.dnis
		,ss.GroupeDequalification
		,Qte = 1
		,DelaiAvantSeconde = cast( datediff(s,starttime, endtime) as float) 
		,cd.clid
	from 
		[srvsql13].ccrdb.dbo.rptcalldataconnection cdc
		join [srvsql13].ccrdb.dbo.rptcalldata cd ON cdc.rptcalldata_id = cd.rptcalldata_id
		join (SELECT DISTINCT ssid, GroupeDequalification =  name + '' ('' + cast (ssid AS VARCHAR(1)) + '')'' from [srvsql13].ccrdb.dbo.rptssdata) ss ON ss.ssid = cdc.ssid
	where 
		1=1
		and LEFT(CONVERT(VARCHAR, timestart, 120), 10) BETWEEN ''' + LEFT(CONVERT(VARCHAR, @DateDe, 120), 10) + ''' and ''' + LEFT(CONVERT(VARCHAR, @DateA, 120), 10) + '''
		and finalconnection = 1
		AND dntypeinfo = ''CDN''
		AND finaldiscreason <> ''RtgStep''
	ORDER by timestart'

	exec (@MySQL)

END
