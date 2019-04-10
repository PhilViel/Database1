/****************************************************************************************************
Copyrights (c) 2016 Gestion Universitas inc.

Code du service       : psCONV_ListeConventionTRA
Nom du service        : Liste des Conventions en état TRA à une date donnée
But                   : Pour la carte : PROD-1194 Production du diplôme en tout temps (PROD-2683)


Facette                : CONV

Paramètres d’entrée    :    
    Paramètre                    Description
    --------------------    ------------------------------------------------------------------------------------------

Exemple d’appel     :   EXEC dbo.psCONV_ListeConventionTRA '2016-08-09'

Historique des modifications:
    Date			Programmeur					Description														Référence
    ----------		--------------------		---------------------------------------------------------		--------------
    2016-08-09		Donald Huppé				Création

**********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_ListeConventionTRA] (
	@EnDateDu     DATE = NULL
) AS
BEGIN


	select 
		c.ConventionNo,
		DateTRA = css.startdate,
		c.SubscriberID,
		NomSouscripteur = hs.LastName,
		PrenomSouscripteur = hs.FirstName,
		PrenomBeneficiaire = hb.FirstName
	from Un_Convention c
	join Mo_Human hs on c.SubscriberID = hs.HumanID
	join Mo_Human hb on c.BeneficiaryID = hb.HumanID
	join (
		select 
			Cs.conventionid ,
			ccs.startdate,
			cs.ConventionStateID
		from 
			un_conventionconventionstate cs
			join (
				select 
				conventionid,
				startdate = max(startDate)
				from un_conventionconventionstate
				where startDate < DATEADD(d,1 ,@EnDateDu)
				group by conventionid
				) ccs on ccs.conventionid = cs.conventionid 
					and ccs.startdate = cs.startdate 
					and cs.ConventionStateID = 'TRA'
		) css on C.conventionid = css.conventionid

END
