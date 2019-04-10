/****************************************************************************************************
Code de service		:		psGENE_RapportGestionnaireDemande_OngletTraite
Nom du service		:		Rapport sur le gestionnaire de gestionnaire de demande - onglet  Traité
But					:		
Facette				:		GENE
Reférence			:		

Parametres d'entrée :	Parametres					Description
						----------					----------------
								
Exemple d'appel:
                
                EXEC psGENE_RapportGestionnaireDemande_OngletTraite '2018-01-01' , '2018-07-31'
				
Parametres de sortie :	Table						Champs										Description
						-----------------			---------------------------					-----------------------------

                   
Historique des modifications :
			
						Date						Programmeur					Description							Référence
						----------				--------------------------	----------------------------		---------------
						2016-02-05				Donald Huppé				Création du service
						2016-02-16				Donald Huppé				ajout de ConventionNo
						2018-08-07				Donald Huppé				jira prod-10658 : Ajout du type de demande COT
						
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_RapportGestionnaireDemande_OngletTraite] 
							(	
								@dtDateDu			DATETIME,
								@dtDateAu			DATETIME
                             )
AS

BEGIN



	select
		DemandeType = 'PAE'
		,IdDemande = DP.Id
		,DateTraitee = cast(d.DateTraitee as date)
		,ÉtatTraitement = case 
				when DP.EstQualifiee = 1 and DP.EstAbandonnee = 0 then 'Complétée'
				when DP.EstQualifiee = 0 and DP.EstAbandonnee = 0 then 'Complétée - Non Qualitfiée'
				when DP.EstQualifiee = 0 and DP.EstAbandonnee = 1 then 'Complétée - Abandonnée'
				end
		,IdRaisonRefus = isnull(dp.IdRaisonRefus,0)
		,RaisonRefus = isnull(rr.RaisonRefus,'')
		,RaisonRefusAutre =  REPLACE( replace( isnull(dp.RaisonRefusAutre,''),char(10),' '),char(13),' ' )
		,dp.EstQualifiee
		,dp.EstAbandonnee
		,RaisonAbandon = isnull(dp.RaisonAbandon,'')
		,Agent = replace(d.IdAgent,'UNIVERSITAS\','')
		,c.ConventionNo
	from 
		dbo.PreDemande PD
		join dbo.Demande D on d.IdPreDemande = pd.Id
		join dbo.DemandePAE DP on DP.Id = d.Id
		left join DemandeRaisonRefus rr on rr.ID = dp.IdRaisonRefus
		left join Un_Convention c ON C.ConventionID = dp.IdConvention
		
	where 1=1
		and isnull(d.DateTraitee,'9999-12-31') BETWEEN @dtDateDu and @dtDateAu

	UNION ALL

	select
		DemandeType = 'RIN'
		,IdDemande = DP.Id
		,DateTraitee = cast(d.DateTraitee as date)
		,ÉtatTraitement = case 
				when DP.EstQualifiee = 1 and DP.EstAbandonnee = 0 then 'Complétée'
				when DP.EstQualifiee = 0 and DP.EstAbandonnee = 0 then 'Complétée - Non Qualitfiée'
				when DP.EstQualifiee = 0 and DP.EstAbandonnee = 1 then 'Complétée - Abandonnée'
				end
		,IdRaisonRefus = isnull(dp.IdRaisonRefus,0)
		,RaisonRefus = isnull(rr.RaisonRefus,'')
		,RaisonRefusAutre = REPLACE( replace( isnull(dp.RaisonRefusAutre,''),char(10),' '),char(13),' ' )
		,dp.EstQualifiee
		,dp.EstAbandonnee
		,RaisonAbandon = isnull(dp.RaisonAbandon,'')
		,Agent = replace(d.IdAgent,'UNIVERSITAS\','')
		,c.ConventionNo
	from 
		dbo.PreDemande PD
		join dbo.Demande D on d.IdPreDemande = pd.Id
		join dbo.DemandeRin DP on DP.Id = d.Id
		left join DemandeRaisonRefus rr on rr.ID = dp.IdRaisonRefus
		left join Un_Convention c ON C.ConventionID = dp.IdConvention
		
	where 1=1
		and isnull(d.DateTraitee,'9999-12-31') BETWEEN @dtDateDu and @dtDateAu


	UNION ALL

	select
		DemandeType = 'COT'
		,IdDemande = DP.Id
		,DateTraitee = cast(d.DateTraitee as date)
		,ÉtatTraitement = case 
				when DP.EstQualifiee = 1 and DP.EstAbandonnee = 0 then 'Complétée'
				when DP.EstQualifiee = 0 and DP.EstAbandonnee = 0 then 'Complétée - Non Qualitfiée'
				when DP.EstQualifiee = 0 and DP.EstAbandonnee = 1 then 'Complétée - Abandonnée'
				end
		,IdRaisonRefus = isnull(dp.IdRaisonRefus,0)
		,RaisonRefus = isnull(rr.RaisonRefus,'')
		,RaisonRefusAutre = REPLACE( replace( isnull(dp.RaisonRefusAutre,''),char(10),' '),char(13),' ' )
		,dp.EstQualifiee
		,dp.EstAbandonnee
		,RaisonAbandon = isnull(dp.RaisonAbandon,'')
		,Agent = replace(d.IdAgent,'UNIVERSITAS\','')
		,c.ConventionNo
	from 
		dbo.PreDemande PD
		join dbo.Demande D on d.IdPreDemande = pd.Id
		join dbo.DemandeCOT DP on DP.Id = d.Id
		left join DemandeRaisonRefus rr on rr.ID = dp.IdRaisonRefus
		left join Un_Convention c ON C.ConventionID = dp.IdConvention
		
	where 1=1
		and isnull(d.DateTraitee,'9999-12-31') BETWEEN @dtDateDu and @dtDateAu
END