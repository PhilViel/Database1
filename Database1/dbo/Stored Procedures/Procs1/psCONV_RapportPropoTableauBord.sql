/****************************************************************************************************
Copyrights (c) 2016 Gestion Universitas inc
Nom                 :	psCONV_RapportPropoTableauBord
Description         :	Pour le rapport de des proposition électronique
Valeurs de retours  :	Dataset 
Note                :	2016-03-24	Donald Huppé			Création : JIRA TI-1669
						2016-06-14	Donald Huppé			pointer sur la vue View_Transaction
						2016-08-26	Donald Huppé			jira ti-4405

exec psCONV_RapportPropoTableauBord '2016-08-22' , '2016-08-23'


****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportPropoTableauBord] (
	@StartDate DATETIME
	,@EndDate DATETIME
	)
AS
BEGIN

SET ARITHABORT ON 


DECLARE 
	@SQL VARCHAR(8000),
	@vcServeurPropo VARCHAR(255),
	@vcBDPropo VARCHAR(255)


SET @vcServeurPropo = dbo.fnGENE_ObtenirParametre('GENE_SERVEUR_PROPELECT', NULL, NULL, NULL, NULL, NULL, NULL) 
SET @vcBDPropo = dbo.fnGENE_ObtenirParametre('GENE_BD_PROPELECT', NULL, NULL, NULL, NULL, NULL, NULL) 


/*
J'ai besoin d'un rapport avec une date de début et de fin qui m'identifie le nombre de vente IPAD reçue pendant cette période et l'agent qui a traitée la vente (approuvée ou rejetée)
 Dans mon rapport - statistique suivante 
 Nom du souscripteur 
 nom du représentant 
 date de réception 
 état du traitement 
 agent qui traité la vente 
 note au dossier dans intellifond (si possible) 
*/

SET @sql = '
	select 
		v.*
		,TransactionNotes = isnull(n.TransactionNotes,'''')
	from (

		select 
			t.TransactionID,
			Souscripteur = s.FirstName + '' '' + s.LastName,
			Represenatant = rep.FirstName + '' '' + rep.LastName,
			DateReception = t.TransactionDateTime, 
			EtatTraitement = tas.TransactionApprovalStatusNameFR, 
			Agent = a.FirstName + '' '' + a.LastName
		

		 from 
			' + @vcServeurPropo + '.'  + @vcBDPropo+ '.dbo.[View_Transaction] t
			join ' + @vcServeurPropo + '.'  + @vcBDPropo+ '.dbo.Agent as a on t.AgentID = a.AgentID
			join ' + @vcServeurPropo + '.'  + @vcBDPropo+ '.dbo.TransactionApprovalStatus tas on tas.TransactionApprovalStatusID = t.Approval
			join ' + @vcServeurPropo + '.'  + @vcBDPropo+ '.dbo.Subscriber as s on t.SubscriberID = s.SubscriberID
			join ' + @vcServeurPropo + '.'  + @vcBDPropo+ '.dbo.Representative as rep on rep.RepresentativeID = t.RepresentativeID

		 where 
			t.AgentID not in (2,3,4,42) -- Agents réels
			 and cast(t.TransactionDateTime as date) BETWEEN ''' + LEFT(CONVERT(VARCHAR, @StartDate, 120), 10) + ''' and ''' + LEFT(CONVERT(VARCHAR, @EndDate, 120), 10) + '''
		 
		UNION ALL

		select 
			t.TransactionID,
			Souscripteur = s.FirstName + '' '' + s.LastName,
			Represenatant = rep.FirstName + '' '' + rep.LastName,
			DateReception = t.TransactionDateTime, 
			EtatTraitement = tas.TransactionApprovalStatusNameFR, 
			Agent = a.FirstName + '' '' + a.LastName
			

		 from 
			' + @vcServeurPropo + '.'  + @vcBDPropo+ '.dbo.[View_Transaction] t
			join ' + @vcServeurPropo + '.'  + @vcBDPropo+ '.dbo.Agent as a on cast(right(rtrim(t.Description), len(rtrim(t.Description)) - charindex(''='', t.Description) ) as int) = a.AgentID
			join ' + @vcServeurPropo + '.'  + @vcBDPropo+ '.dbo.TransactionApprovalStatus tas on tas.TransactionApprovalStatusID = t.Approval
			join ' + @vcServeurPropo + '.'  + @vcBDPropo+ '.dbo.Subscriber as s on t.SubscriberID = s.SubscriberID
			join ' + @vcServeurPropo + '.'  + @vcBDPropo+ '.dbo.Representative as rep on rep.RepresentativeID = t.RepresentativeID

		 where 
			t.AgentID = 42 -- Agent de purge
			and cast(t.TransactionDateTime as date) BETWEEN ''' + LEFT(CONVERT(VARCHAR, @StartDate, 120), 10) + ''' and ''' + LEFT(CONVERT(VARCHAR, @EndDate, 120), 10) + '''
		 ) v
	left join (
	
		 -- Les notes concaténées avec un /
		select *
		from (

			Select 
				Main.TransactionID,
				TransactionNotes = ltrim(rtrim(Left(Main.TransactionNotes,Len(Main.TransactionNotes)-1)))
			From
				(
					Select distinct ST2.TransactionID, 
						(
							Select ST1.TransactionNote + ''	'' AS [text()]
							From ' + @vcServeurPropo + '.'  + @vcBDPropo+ '.dbo.TransactionNote ST1
							Where ST1.TransactionID = ST2.TransactionID
							ORDER BY ST1.TransactionID
							For XML PATH ('''')
						) [TransactionNotes]
					From ' + @vcServeurPropo + '.'  + @vcBDPropo+ '.dbo.TransactionNote ST2
				) [Main]
			)all1
		--where ALL1.TransactionID = 15491
		)N on n.TransactionID = v.TransactionID

	order by v.TransactionID
		'
--	print @sql
	exec (@sql)


	

END
