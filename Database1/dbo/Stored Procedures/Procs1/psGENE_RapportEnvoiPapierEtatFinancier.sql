
/****************************************************************************************************
Code de service		:		psGENE_RapportEnvoiPapierEtatFinancier
Nom du service		:		psGENE_RapportEnvoiPapierEtatFinancier
But					:		Liste pour envoi des états financiers annuel ou semestriel
Facette				:		GENE
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						N/A

Exemple d'appel:
						exec psGENE_RapportEnvoiPapierEtatFinancier 'A'
                

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------


Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2018-09-14					Donald Huppé							Création du Service
						
 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[psGENE_RapportEnvoiPapierEtatFinancier] (
	@Type varchar(30) -- A Annuel, S Semestriel
	)


AS
BEGIN



-- convention actives en date du jour

	SELECT 
		GenreLong = sex.LongSexName,
		GenreCourt = sex.ShortSexName,
		Nom = hs.LastName,
		Prenom = hs.FirstName,
		LangueSousc = l.LangName,
		Adresse = a.Address,
		Ville = a.City,
		Province = a.statename,
		CodePostal = case WHEN len(ltrim(rtrim(zipcode))) = 6  then substring(ltrim(rtrim(zipcode)),1,3) + ' ' + substring(ltrim(rtrim(zipcode)),4,3) 
					else ltrim(rtrim(zipcode)) end,
		Pays = cn.CountryName,
		c.SubscriberID,
		regime.Universitas,
		regime.Reeeflex,
		regime.Individuel

	FROM 
		Un_Convention c
		JOIN (
			SELECT 
				c.subscriberid,
			   Universitas = max(case when rr.iID_Regroupement_Regime = 1 THEN 1 ELSE 0 END),
			   Reeeflex = max(case when rr.iID_Regroupement_Regime = 2 THEN 1 ELSE 0 END),
			   Individuel = max(case when rr.iID_Regroupement_Regime = 3 THEN 1 ELSE 0 END)
		   
			FROM
				Un_Convention c 
			JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(GETDATE(), NULL) CSS ON CSS.ConventionID = c.ConventionID AND CSS.ConventionStateID IN ('REE','TRA')
			JOIN dbo.Un_Plan p ON c.PlanID = p.PlanID
			JOIN dbo.tblCONV_RegroupementsRegimes rr ON p.iID_Regroupement_Regime = rr.iID_Regroupement_Regime
			GROUP by  c.subscriberid
			) regime on c.subscriberid = regime.subscriberid
		JOIN Un_Subscriber S ON S.SubscriberID = c.subscriberid
		JOIN Mo_Human hs on s.SubscriberID = hs.HumanID
		JOIN Mo_Lang l on hs.LangID = l.LangID --
		JOIN mo_sex  sex on sex.LangID = hs.LangID and sex.SexID = hs.SexID
		JOIN Mo_Adr a on hs.AdrID = a.AdrID
		JOIN Mo_Country cn on a.CountryID = cn.CountryID
		LEFT JOIN tblGENE_PortailAuthentification PA ON PA.iUserId = S.SubscriberID
	WHERE 1=1
		AND S.AddressLost = 0
		AND (
				(
					@Type = 'A' AND ISNULL(S.bEtats_Financiers_Annuels,0) = 1
				)
				OR
				(
					@Type = 'S' AND (
									ISNULL(S.bEtats_Financiers_Semestriels,0) = 1
									OR 
									ISNULL(s.SemiAnnualStatement,0) = 1 -- On considère ce flag aussi car on ne sait pas s'il a déjà servi à ça ou si on a oublié de le reconduire dans bEtats_Financiers_Semestriels. Claude Decaries est d'accord
									)
				)
			)
		
	GROUP BY 
		sex.LongSexName,
		sex.ShortSexName,
		hs.LastName,
		hs.FirstName,
		l.LangName,
		s.AddressLost,
		a.Address,
		a.City,
		a.statename,
		case WHEN len(ltrim(rtrim(zipcode))) = 6  then substring(ltrim(rtrim(zipcode)),1,3) + ' ' + substring(ltrim(rtrim(zipcode)),4,3) 
					else ltrim(rtrim(zipcode)) end,
		cn.CountryName,
		c.SubscriberID,
		regime.Universitas,
		regime.Reeeflex,
		regime.Individuel

END
