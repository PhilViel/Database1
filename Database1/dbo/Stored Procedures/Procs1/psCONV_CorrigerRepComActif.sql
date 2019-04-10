/****************************************************************************************************
Copyrights (c) 2017 Gestion Universitas inc.

Code du service		: psCONV_CorrigerRepComActif
Nom du service		: Corriger le représentant sur l'actif des groupe d'untié qui EST Siège Social sur l'épargne dans les régimes T (frais 11,50 $) 
But 				: Corriger le représentant sur l'actif des groupe d'untié qui EST Siège Social sur l'épargne dans les régimes T (frais 11,50 $) 
Facette				: CONV
Référence			: JIRA TI-4934

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------

Exemple utilisation:	
	
	EXEC psCONV_CorrigerRepComActif
	
TODO:
	
Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2017-05-31		Donald Huppé						Création du service			
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_CorrigerRepComActif] 
AS
BEGIN



	declare 
		@LeUpdate varchar(1000),
		@UnitID int
	declare @list table (UnitID int, LeUpdate varchar(1000))

		insert into @list(UnitID,LeUpdate) 
		select DISTINCT
			u.UnitID
			,LeUpdate = 'update ProAcces.Un_Unit set iID_RepComActif = ' + cast (s.RepID as VARCHAR(15)) + ' where unitid = ' + cast(u.UnitID as VARCHAR)
		from Un_Convention c
		join Un_Subscriber s on s.SubscriberID = c.SubscriberID
		JOIN ProAcces.Un_Unit U ON U.ConventionID = C.ConventionID
		join Un_Cotisation ct on CT.UnitID = U.UnitID
		join Un_Oper o on o.OperID = ct.OperID
		left join Un_OperCancelation oc1 on o.OperID = oc1.OperSourceID
		left join Un_OperCancelation oc2 on o.OperID = oc2.OperID
		where 
			c.ConventionNo like 'T%'
			and o.OperTypeID = 'FRS'
			and ct.Cotisation = -11.50
			and u.dtFirstDeposit >= '2016-08-01'
			and oc1.OperSourceID is NULL -- non annulé
			and oc2.OperID is null -- pas une annulation
			and u.iID_RepComActif = 149876
		order by u.UnitID	

	while (select count(*) from @list) > 0
	begin
		select top 1 @UnitID = UnitID, @LeUpdate = LeUpdate from @list
		exec(@LeUpdate)
		--print @LeUpdate
		delete from @list where UnitID = @UnitID
	end



END
