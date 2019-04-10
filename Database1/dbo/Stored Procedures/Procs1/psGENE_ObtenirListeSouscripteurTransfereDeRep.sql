/****************************************************************************************************
Code de service		:		psGENE_ObtenirListeSouscripteurTransfereDeRep
Nom du service		:		Obtenir la liste des souscripteur qui ont changé de rep entre 2 date
But					:		
Facette				:		GENE
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------

Exemple d'appel:
                
                EXEC psGENE_ObtenirListeSouscripteurTransfereDeRep '2011-01-01', 0, 0, 0 
                EXEC psGENE_ObtenirListeSouscripteurTransfereDeRep '2011-03-04','2011-03-04', 0, 0, 559035
				EXEC psGENE_ObtenirListeSouscripteurTransfereDeRep '2011-01-01', '2011-03-04' , 546640, 439395
                EXEC psGENE_ObtenirListeSouscripteurTransfereDeRep '2011-01-01', '2011-03-04' , 0, 559035    

Parametres de sortie :	Table						Champs										Description
						-----------------			---------------------------					-----------------------------
                   
Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2011-05-12					Donald Huppé							Création du service
						
						
	
 ****************************************************************************************************/
	
create PROCEDURE [dbo].[psGENE_ObtenirListeSouscripteurTransfereDeRep] (
	@dtDateFrom DATETIME,
	@dtDateTo DATETIME,
	@iUserIDWhoTransfert INT,
	@iRepIDOri INT,
	@iRepIDNew INT
	)
AS

BEGIN


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
			and LEFT(CONVERT(VARCHAR, logtime, 120), 10) between @dtDateFrom AND @dtDateTo
			and (cn.userID = @iUserIDWhoTransfert OR @iUserIDWhoTransfert = 0)
		) V1


	SELECT 
		*
	from 
		#V2
	WHERE 
		(@iRepIDOri =0 OR OldRepID = @iRepIDOri)
		AND
		(@iRepIDNew =0 OR NewRepID = @iRepIDNew)
	

END