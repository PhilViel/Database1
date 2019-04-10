
/****************************************************************************************************
Code de service		:		psGENE_RapportStatistiquesPortail
Nom du service		:		Rapport sur les statistiques du portail souscripteurs / bénéficiaires
But					:		Rapport sur les statistiques du portail souscripteurs / bénéficiaires
Facette				:		GENE
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------

Exemple d'appel:
                
				EXEC psGENE_RapportStatistiquesPortail

Parametres de sortie :	Champs						Description
						-----------------			---------------------------	
						inscrits					Souscripteurs / Bénéficiaires inscrits au portail
						inscnonconf					Souscripteurs / Bénéficiaires inscrits dont l’inscription n’est pas confirmée
						ann30jours					Inscriptions non confirmées/annulées après 30 jours
						moins18						Utilisateurs moins de 18 ans
						entre18_35					Utilisateurs entre 18 et 35 ans
						entre36_50					Utilisateurs entre 36 et 50 ans
						entre51_60					Utilisateurs entre 51 et 60 ans
						plus60						Utilisateurs plus de 60 ans
						(A venir)					Changement d’adresse courriel
						(A venir)					Changement d’adresse postale (fonctionnalité portail à venir d'ici la fin de l'année)											
                   
Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2011-07-08					Eric Michaud							Création du service
						2012-04-11					Eric Michaud							Correction date pour calcul de l'age
						2012-07-05					Donald Huppé							glpi 7862 : utiliser état 7 pour ann30jours + les totaux avant l'implantation de ce statut 7.
						2012-07-19					Donald Huppé							Modification du calcul du nombre de demande de bourse
						2012-10-11					Donald Huppé							Ajout des quantités de changement d'adresse postale

exec psGENE_RapportStatistiquesPortail '2012-04-16', '2012-09-14'

 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[psGENE_RapportStatistiquesPortail]

	(
	@StartDate DATETIME, -- Date de début
	@EndDate DATETIME -- Date de fin
	) 

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE 
		@QteDemandeDeBourse int,
		@QteChangementAdrPostalBenef int,
		@QteChangementAdrPostalSousc int

	-- Demande de bourse
	SELECT @QteDemandeDeBourse = count(*) -- + 1087
	FROM (
		SELECT 
			P.iIDBeneficiaire,
			dtDateCreationDemandePrecedente = max(P2.dtDateCreationDemande),
			P.dtDateCreationDemande, 
			DélaiMois = cast(datediff(dd, max(P2.dtDateCreationDemande),P.dtDateCreationDemande) AS float) / 30.42
		from tblGENE_DemandeBoursePortail P
		LEFT join tblGENE_DemandeBoursePortail P2 ON P.iIDBeneficiaire = P2.iIDBeneficiaire AND P2.dtDateCreationDemande < P.dtDateCreationDemande

		WHERE LEFT(CONVERT(VARCHAR, P.dtDateCreationDemande, 120), 10) BETWEEN @StartDate AND @EndDate

		GROUP by P.iIDBeneficiaire,P.dtDateCreationDemande
		) V
	where 
		1=1
		AND (
			dtDateCreationDemandePrecedente IS NULL -- premiere demande
			OR year(dtDateCreationDemande) <> year(dtDateCreationDemandePrecedente) -- avant dernière demande était année différente
			OR (DélaiMois >= 6 AND year(dtDateCreationDemande) = year(dtDateCreationDemandePrecedente)) -- même année mais au moins 6 mois de délai
			)

	-- Changement d'adresse postale souscripteur
	select @QteChangementAdrPostalBenef = count(*)
	from (
		SELECT DISTINCT
			C.BeneficiaryID,
			c.SubscriberID,
			adb.InForce
		FROM 
			Un_Convention c
			JOIN dbo.Mo_Human hb ON c.BeneficiaryID = hb.HumanID
			JOIN dbo.Mo_Human hs ON c.SubscriberID = hs.HumanID
			JOIN dbo.Mo_Adr adb ON hb.HumanID = adb.SourceID
			JOIN (
				SELECT 
					a.SourceID, a.AdrID, adrIDBefore = max(aBefore.AdrID)
				FROM 
					Mo_Adr a
					JOIN dbo.Mo_Adr aBefore ON a.SourceID = aBefore.SourceID AND aBefore.AdrID < a.AdrID
				GROUP by a.SourceID, a.AdrID
				) link ON ADB.AdrID = link.AdrID
			JOIN dbo.Mo_Adr ab ON ab.AdrID = link.adrIDBefore 
				-- le changement passe par le code postal ou un numéro de téléphone
				AND (isnull(ab.ZipCode,'') <> isnull(adb.ZipCode,'') OR isnull(ab.Phone1,'') <> isnull(adb.Phone1,'') OR isnull(ab.Phone2,'') <> isnull(adb.Phone2,'')  OR isnull(ab.Fax,'') <> isnull(adb.Fax,'') OR isnull(ab.Mobile,'') <> isnull(adb.Mobile,'') OR isnull(ab.OtherTel,'') <> isnull(adb.OtherTel,''))
			-- vérifier présence d'adresse du souscripteur créé à la même date
			LEFT JOIN dbo.Mo_Adr ads ON hs.HumanID = ads.SourceID AND LEFT(CONVERT(VARCHAR, ads.InForce, 120), 10) = LEFT(CONVERT(VARCHAR, adb.InForce, 120), 10)
		WHERE 1=1
			AND LEFT(CONVERT(VARCHAR, adB.InForce, 120), 10) BETWEEN @StartDate AND @EndDate
			AND ads.AdrID IS NULL -- pas d'adresse de sousc à la même date
			and adb.ConnectID = 711375  -- changement fait par le bénéf via le portail
		) V

	-- Changement d'adresse postale bénéficiaire
	select @QteChangementAdrPostalSousc = count(*)
	from (
		SELECT DISTINCT
			c.SubscriberID,
			ads.InForce
		FROM 
			Un_Convention c
			JOIN dbo.Mo_Human hs ON c.SubscriberID = hs.HumanID
			JOIN dbo.Mo_Adr ads ON hs.HumanID = ads.SourceID
			JOIN (
				SELECT 
					a.SourceID, a.AdrID, adrIDBefore = max(aBefore.AdrID)
				FROM 
					Mo_Adr a
					JOIN dbo.Mo_Adr aBefore ON a.SourceID = aBefore.SourceID AND aBefore.AdrID < a.AdrID
				GROUP by a.SourceID, a.AdrID
				) link ON ADs.AdrID = link.AdrID
			JOIN dbo.Mo_Adr ab ON ab.AdrID = link.adrIDBefore 
				-- le changement passe par le code postal ou un numéro de téléphone
				AND (isnull(ab.ZipCode,'') <> isnull(ads.ZipCode,'') OR isnull(ab.Phone1,'') <> isnull(ads.Phone1,'') OR isnull(ab.Phone2,'') <> isnull(ads.Phone2,'')  OR isnull(ab.Fax,'') <> isnull(ads.Fax,'') OR isnull(ab.Mobile,'') <> isnull(ads.Mobile,'') OR isnull(ab.OtherTel,'') <> isnull(ads.OtherTel,''))
		WHERE 1=1
			AND LEFT(CONVERT(VARCHAR, ads.InForce, 120), 10) BETWEEN @StartDate AND @EndDate
			and ads.ConnectID = 711374 -- changement fait par le souscripteur via le portail
		) V

	select 
		inscrits,
		QteInscrits,
		inscnonconf = isnull(inscnonconf,0),
		ann30jours = isnull(ann30jours,0),
		moins18 = isnull(moins18,0),
		entre18_35 = isnull(entre18_35,0),
		entre36_50 = isnull(entre36_50,0),
		entre51_60 = isnull(entre51_60,0),
		plus60 = isnull(plus60,0),
		demandebourse,
		QteChangementAdrPostal

	from (

		select inscrits = 'S',
			QteInscrits = count(DISTINCT pa.iUserId),
			inscnonconf = sum(case when pe.IidEtat = 0 then 1 else 0 end),
			ann30jours = sum(case when pe.IidEtat = 7 then 1 else 0 end) /* + 608*/,
			moins18 = sum(case when dbo.fn_Mo_Age(mh.birthdate,pa.dtInscription) <= 17 then 1 else 0 end),
			entre18_35 = sum(case when dbo.fn_Mo_Age(mh.birthdate,pa.dtInscription) BETWEEN 18 and 35 then 1 else 0 end),
			entre36_50 = sum(case when dbo.fn_Mo_Age(mh.birthdate,pa.dtInscription) BETWEEN 36 and 50 then 1 else 0 end),
			entre51_60 = sum(case when dbo.fn_Mo_Age(mh.birthdate,pa.dtInscription) BETWEEN 51 and 60 then 1 else 0 end),
			plus60 = sum(case when dbo.fn_Mo_Age(mh.birthdate,pa.dtInscription) >= 61 then 1 else 0 end),
			demandebourse = 0,
			QteChangementAdrPostal = @QteChangementAdrPostalSousc
		from tblGENE_PortailAuthentification pa
		join tblGENE_PortailEtat pe on pa.iEtat = pe.IidEtat
		JOIN dbo.Mo_Human mh on pa.iUserId = mh.HumanId
		JOIN dbo.Un_Subscriber us on us.SubscriberID = mh.HumanId
		where pa.dtInscription between @StartDate AND @EndDate
		
		union all
		
		select inscrits = 'B',
			QteInscrits = count(DISTINCT pa.iUserId),
			inscnonconf = sum(case when pe.IidEtat = 0 then 1 else 0 end),
			ann30jours = sum(case when pe.IidEtat = 7 then 1 else 0 end) /*+ 129*/,
			moins18 = sum(case when dbo.fn_Mo_Age(mh.birthdate,pa.dtInscription) <= 17 then 1 else 0 end),
			entre18_35 = sum(case when dbo.fn_Mo_Age(mh.birthdate,pa.dtInscription) BETWEEN 18 and 35 then 1 else 0 end),
			entre36_50 = sum(case when dbo.fn_Mo_Age(mh.birthdate,pa.dtInscription) BETWEEN 36 and 50 then 1 else 0 end),
			entre51_60 = sum(case when dbo.fn_Mo_Age(mh.birthdate,pa.dtInscription) BETWEEN 51 and 60 then 1 else 0 end),
			plus60 = sum(case when dbo.fn_Mo_Age(mh.birthdate,pa.dtInscription) >= 61 then 1 else 0 end),
			demandebourse = @QteDemandeDeBourse,
			QteChangementAdrPostal = @QteChangementAdrPostalBenef
		from tblGENE_PortailAuthentification pa
		join tblGENE_PortailEtat pe on pa.iEtat = pe.IidEtat
		JOIN dbo.Mo_Human mh on pa.iUserId = mh.HumanId
		JOIN dbo.Un_Beneficiary ub on ub.BeneficiaryID = mh.HumanId
		where pa.dtInscription between @StartDate AND @EndDate
		) T
		
END


