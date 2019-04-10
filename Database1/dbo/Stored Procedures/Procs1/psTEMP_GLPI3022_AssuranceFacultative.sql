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
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: GLPI5471
Nom du service		: 
But 				: 
Facette				: 

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2012-07-03		Donald Huppé						Création du service
        2018-11-12      Pierre-Luc Simard                   N'est plus utilisée

exec psTEMP_GLPI5471_QteSouscripteur '2012-06-30'

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psTEMP_GLPI3022_AssuranceFacultative]
(
	@dtDateFin datetime
)
AS
BEGIN

SELECT 1/0

/*
--au 31 août 2011 et au 30 septembre 2011 
--declare @date datetime

--set @date = '2012-05-31'

select
	EnDateDu = LEFT(CONVERT(VARCHAR, @dtDateFin, 120), 10),
	RflexTot = sum(RflexTot),
	RflexAss = sum(RflexAss),
	UnivTot = sum(UnivTot),
	UnivAss = sum(UnivAss)
from (

	-- Reeeflex (X-)
	select 
		RflexTot = count(distinct c.conventionid),
		RflexAss = 0,
		UnivTot = 0,
		UnivAss = 0
	from 
		un_convention c
		JOIN dbo.Un_Unit u on c.conventionid = u.conventionid
	where  
		c.planid = 12
		and inforcedate between '2010-01-01' and @dtDateFin
		--and WantSubscriberInsurance = 1 -- avec assurance (mettre en commentaire pour avoir le nb de convention total)

	Union

	select 
		RflexTot = 0,
		RflexAss = count(distinct c.conventionid),
		UnivTot = 0,
		UnivAss = 0
	from 
		un_convention c
		JOIN dbo.Un_Unit u on c.conventionid = u.conventionid
	where  
		c.planid = 12
		and inforcedate between '2010-01-01' and @dtDateFin
		and WantSubscriberInsurance = 1 -- avec assurance (mettre en commentaire pour avoir le nb de convention total)

	union
	-- Modalité du 2009-12-08
	select 
		RflexTot = 0,
		RflexAss = 0,
		UnivTot = count(distinct c.conventionid),
		UnivAss = 0

	from 
		un_convention c
		JOIN dbo.Un_Unit u on c.conventionid = u.conventionid
		join un_modal m on u.modalid = m.modalid 
	where  
		c.planid = 8
		and m.modaldate >= '2009-12-08'
		and inforcedate <= @dtDateFin
		--and WantSubscriberInsurance = 1 -- avec assurance (mettre en commentaire pour avoir le nb de convention total)

	union

	select 
		RflexTot = 0,
		RflexAss = 0,
		UnivTot = 0,
		UnivAss = count(distinct c.conventionid)

	from 
		un_convention c
		JOIN dbo.Un_Unit u on c.conventionid = u.conventionid
		join un_modal m on u.modalid = m.modalid 
	where  
		c.planid = 8
		and m.modaldate >= '2009-12-08'
		and inforcedate <= @dtDateFin
		and WantSubscriberInsurance = 1 -- avec assurance (mettre en commentaire pour avoir le nb de convention total)

	) V
	*/
END