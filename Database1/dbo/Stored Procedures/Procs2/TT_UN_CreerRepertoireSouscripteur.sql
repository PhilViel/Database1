/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	TT_UN_CreerRepertoireSouscripteur 
Description         :	Procédure pour créer les répertoires des souscripteurs dans le plan de Classification 
Valeurs de retours  :	 
Note                :	2009-06-26	Donald Huppé	Créaton
						2009-08-11	Donald Huppé	Modification pour créer les dossiers des souscripteurs qui ont été 
													modifiés dans la plage de date (voir le UNION) et inscrit dans le log avec LogTableName = 'Un_Convention' 
						2009-08-17	Donald Huppé	Dans le nom du répertoire à créer, enlever les . , &
						2009-08-21	Donald Huppé	Gestion des souscrpteur modifié et inscrit dans le log avec LogTableName = 'Un_subscriber' 
						2009-09-14	Donald Huppé	correction de la clause where sur logtime.  on supprime les heures.
						2009-12-10	Donald Huppé	Correction de la clause where sur logtime. on met @DateFrom and @DateTo au lieu de between @StrDateFrom and @StrDateTo.
													ça ne fonctionnait pas sinon...
						2010-01-28	Donald Huppé	On ne créé plus le nouveau dossier dans le cas d'une modification de souscripteur avec même id	
						2011-05-30	Donald Huppé	GLPI 5588 : les dossiers des souscripteurs sont dorénavant créés suite à l’activation des prélèvements (activer le groupe d’unité).
						2012-09-06	Donald Huppé	Gestion des / et \ dans les nom et prenom

exec TT_UN_CreerRepertoireSouscripteur '2011-05-30', '2011-05-30'

****************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_CreerRepertoireSouscripteur] 
	(
	@DateFrom datetime, -- Date limite inférieure inscrite dans le numéro de convention
	@DateTo datetime	-- Date limite supérieure inscrite dans le numéro de convention
	)

AS
BEGIN

set Nocount on

declare @FNom varchar(255)
declare @Repertoire varchar(255)
declare @cmd varchar(3000)
declare @StrDateFrom varchar(8)
declare @StrDateTo varchar(8)

	set @StrDateFrom = convert(varchar(8),@DateFrom,112)
	set @StrDateTo = convert(varchar(8),@DateTo,112)

	CREATE TABLE #tHuman (
			FPrenom varchar(1),
			Repertoire VARCHAR (500))

	insert into #tHuman

	-- Les nouvelles conventions
	select distinct
		FPrenom = dbo.fn_Mo_FormatStringWithoutAccent(substring(LTRIM(RTRIM(h.lastname)),1,1)),
		Repertoire = replace(replace(replace(replace(replace(dbo.fn_Mo_FormatStringWithoutAccent(upper(replace(LTRIM(RTRIM(h.lastname)),' ','_')) + '_' + replace(LTRIM(RTRIM(h.firstname)),' ','_') + '_' + cast(h.humanid as varchar(20))),'.',''),',',''),'&','Et'),'/',''),'\','')
	FROM dbo.Un_Convention c
	JOIN dbo.Un_Subscriber s on c.subscriberid = s.subscriberid
	JOIN dbo.mo_human h on s.subscriberid = h.humanid
	JOIN dbo.Un_Unit u ON c.ConventionID = u.ConventionID
	join Mo_Connect cn ON u.ActivationConnectID = cn.ConnectID
	where LEFT(CONVERT(VARCHAR, cn.ConnectStart, 120), 10) BETWEEN LEFT(CONVERT(VARCHAR, @DateFrom, 120), 10) AND LEFT(CONVERT(VARCHAR, @DateTo, 120), 10)
		OR LEFT(CONVERT(VARCHAR, cn.ConnectEnd, 120), 10) BETWEEN LEFT(CONVERT(VARCHAR, @DateFrom, 120), 10) AND LEFT(CONVERT(VARCHAR, @DateTo, 120), 10)
		--substring(c.conventionno,3,8) between @StrDateFrom and @StrDateTo
	
	UNION

	-- Les conventions modifiés au niveau du souscripteur
	select distinct
		FPrenom = dbo.fn_Mo_FormatStringWithoutAccent(substring(LTRIM(RTRIM(h.lastname)),1,1)),
		Repertoire = replace(replace(replace(replace(replace(dbo.fn_Mo_FormatStringWithoutAccent(upper(replace(LTRIM(RTRIM(h.lastname)),' ','_')) + '_' + replace(LTRIM(RTRIM(h.firstname)),' ','_') + '_' + cast(h.humanid as varchar(20))),'.',''),',',''),'&','Et'),'/',''),'\','')
	FROM dbo.Un_Convention c
	JOIN dbo.Un_Subscriber s on c.subscriberid = s.subscriberid
	JOIN dbo.mo_human h on s.subscriberid = h.humanid
	where h.humanid in (
		SELECT 
			NewhumanId = convert(int,replace(SUBSTRING(L.LogText, 20, 7),CHAR(30),''))
		FROM 
			CRQ_Log L
		WHERE 
			L.LogTableName = 'Un_Convention' 
			AND L.LogActionID = 2
			AND L.LogText LIKE 'SubscriberID%'
			and convert(varchar(10),l.logtime,127) between @DateFrom and @DateTo -- between @StrDateFrom and @StrDateTo -- corrigé le 2009-12-10
		)

	/*  -- 2010-01-28 : On ne créé plus le nouveau dossier.  Ils vont plutot renommer l'ancien.  
		-- C'est ce qu'ils faisaient déjà et faisaient supprimer le nouveau dossier, donc on le créait pour rien....
	union
	-- Les souscrpteurs modifiés
	select distinct
		FPrenom = dbo.fn_Mo_FormatStringWithoutAccent(substring(LTRIM(RTRIM(h.lastname)),1,1)),
		Repertoire = replace(replace(replace(dbo.fn_Mo_FormatStringWithoutAccent(upper(replace(LTRIM(RTRIM(h.lastname)),' ','_')) + '_' + replace(LTRIM(RTRIM(h.firstname)),' ','_') + '_' + cast(h.humanid as varchar(20))),'.',''),',',''),'&','Et')
	FROM dbo.Un_Convention c
	JOIN dbo.Un_Subscriber s on c.subscriberid = s.subscriberid
	JOIN dbo.mo_human h on s.subscriberid = h.humanid
	where h.humanid in (
		SELECT 
			humanId = logcodeid
		FROM 
			CRQ_Log L
		WHERE 
			L.LogTableName = 'Un_subscriber' 
			AND L.LogActionID = 2
			AND (L.LogText LIKE '%Lastname%' or L.LogText LIKE '%Firstname%')
			and convert(varchar(10),l.logtime,127) between @DateFrom and @DateTo -- @StrDateFrom and @StrDateTo -- corrigé le 2009-12-10
		)
	*/

	DECLARE MyCursor CURSOR FOR

		select FPrenom,Repertoire from #tHuman

	OPEN MyCursor
	FETCH NEXT FROM MyCursor INTO @FNom,@Repertoire

	WHILE @@FETCH_STATUS = 0
	BEGIN
 
		--print @Repertoire
		SET @cmd = 'mkdir \\gestas2\\PlanDeClassification\\8_SERVICES_A_LA_CLIENTELE\\802_GESTION_DES_CONTRATS\\802-100_SOUSCRIPTEUR\\' + @FNom + '\\' + @Repertoire + '\\RELEVES_DEPOTS'
		EXEC XP_CMDSHELL @cmd

		FETCH NEXT FROM MyCursor INTO @FNom,@Repertoire

	END
	CLOSE MyCursor
	DEALLOCATE MyCursor	

	drop table #tHuman

end


