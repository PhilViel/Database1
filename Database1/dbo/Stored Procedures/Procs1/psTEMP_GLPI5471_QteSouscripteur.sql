/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psTEMP_ObtenirMontantIQEEPourPAE
Nom du service		: Obtenir les montants d'IQÉÉ pour la production d'un PAE.
But 				: Mesure temporaire qui a pour objectif de sortir les montants d'IQÉÉ avec les PAE avant que les
					  montants d'IQÉÉ soient injectés dans les conventions.  Elle donne les montants d'IQÉÉ à sortir
					  et enregistre les chiffres dans une table temporaire afin de faciliter la finalisation des
					  données lors de l'injection des données dans les conventions.
Facette				: IQÉÉ

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2009-07-13		Éric Deshaies						Création du service
		2009-12-03		Éric Deshaies						L'IQÉÉ est maintenant dans les conventions
															- Calculer les montants à partir des conventions
															  au lieu des réponses de l'IQÉÉ
															- Créer les transactions IQÉÉ et d'intérêts d'IQÉÉ
															  dans les conventions
															- Mettre les intérêts générés par GUI dans le chèque
		2010-08-17		Éric Deshaies						Laisser passer l'IQÉÉ pour les conventions
															fermée et avec retrait prématuré dans les
															conventions "T" à cause du paiement des frais
															dans le TFR.
		2011-04-15		Éric Deshaies						Ne pas sortir l’IQÉÉ reçu entre la 
															date d’importation et la date de dépôt.
		2012-05-17		Éric Michaud						Changement de la variable @dtDate_Debut_Cotisation

exec psTEMP_GLPI5471_QteSouscripteur '2012-06-30'

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psTEMP_GLPI5471_QteSouscripteur]
(
	@dtDateFin datetime
)
AS
BEGIN

	--declare @Ladate datetime
	--set @Ladate = '2012-03-31'

	select 
		--c.ConventionNo,
		EnDateDu = LEFT(CONVERT(VARCHAR, @dtDateFin, 120), 10),
		QteSouscripteur = count(DISTINCT c.subscriberID)
		--,QteUnitésAnnuelles = sum(u.UnitQty)
	FROM dbo.Un_Convention c
	JOIN dbo.Un_Subscriber s ON c.SubscriberID = s.SubscriberID 
	join ( -- groupe d'unité SANS RIN à une date donnée
		select conventionid, UnitQty = sum(u1.unitqty + isnull(ur.qteres,0))
		FROM dbo.Un_Unit u1
		LEFT JOIN (select unitid,qteres = sum(UnitQty) from Un_UnitReduction where ReductionDate > @dtDateFin group BY UnitID) ur ON u1.UnitID = ur.UnitID
		--join Un_Modal m ON u1.ModalID = m.ModalID AND m.PmtByYearID = 1 AND m.PmtQty > 1
		where 
			isnull(u1.IntReimbDate,'3000-01-01') > @dtDateFin -- sans RIN
			AND isnull(u1.TerminatedDate,'3000-01-01') > @dtDateFin -- non résilié
		group by conventionid
		) u on u.conventionid = c.conventionid
	join (  -- La plus récente d'état de convention par convention à une date donnée
			select 
				cs.conventionid,
				LaDate = max(cs.StartDate)
			from UN_ConventionConventionState cs
			where LEFT(CONVERT(VARCHAR, cs.StartDate, 120), 10) <= @dtDateFin
			group by cs.conventionid
		) csDate on c.conventionid = csDate.conventionid 
	join UN_ConventionConventionState cs on c.conventionid = cs.conventionid 
				and cs.StartDate = csDate.Ladate 
				and cs.ConventionStateID in ('REE')
	--GROUP by c.ConventionNo

END


