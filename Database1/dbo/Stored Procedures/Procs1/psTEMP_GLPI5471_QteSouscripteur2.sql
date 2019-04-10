/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psTEMP_GLPI5471_QteSouscripteur2
Nom du service		: 
But 				: pour le rapport RapStatistiquesMensuellesGLPI utilisé par S Dupèré
Facette				: 

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
	
		2013-11-07		Donald Huppé		glpi 10470 : ajout de QteSouscAvecSeulementDesConvCollectiveREEEAvecRI
		2014-05-01		Donald Huppé		glpi 11449 : ajout de QteNouvSouscDansAnneeFinissantEnDateDu_glpi11449
											glpi 11450 : ajout de QteSouscRIDansAnneeFinissantEnDateDu_glpi11450
exec psTEMP_GLPI5471_QteSouscripteur2 '2014-12-31'

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psTEMP_GLPI5471_QteSouscripteur2]
(
	@dtDateFin datetime
)
AS
BEGIN

	select 
		c.ConventionNo,
		C.SubscriberID,
		EnDateDu = LEFT(CONVERT(VARCHAR, @dtDateFin, 120), 10), p.iID_regroupement_regime 
	into #test
	FROM dbo.Un_Convention c join Un_Plan p on c.PlanID = p.PlanID
	JOIN dbo.Un_Subscriber s ON c.SubscriberID = s.SubscriberID 
	join ( -- groupe d'unité SANS RIN à une date donnée
		select conventionid, UnitQty = sum(u1.unitqty + isnull(ur.qteres,0))
		FROM dbo.Un_Unit u1
		LEFT JOIN (select unitid,qteres = sum(UnitQty) from Un_UnitReduction where ReductionDate > @dtDateFin group BY UnitID) ur ON u1.UnitID = ur.UnitID
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

	select --GLPI 5471
		EnDateDu,
			
		qteTotalSouscripteur = MAX(qteTotalSouscripteur), 
		qteSouscripteurUniv = MAX(qteSouscripteurUniv),
		qteSouscripteurReeeflex = MAX(qteSouscripteurReeeflex),  
		qteSouscripteurIndiv = MAX(qteSouscripteurIndiv)
		
		,QteSouscAvecSeulementDesConvCollectiveREEEAvecRI = MAX(QteSouscAvecSeulementDesConvCollectiveREEEAvecRI)
		
		,QteSouscActifGLPI10712 = MAX(QteSouscActifGLPI10712)
		
		,QteBoursier_GLPI10829 = MAX(QteBoursier_GLPI10829)
		
		,QteSousc_GLPI10829 = MAX(QteSousc_GLPI10829)
		
		,QteBoursier_GLPI10894 = MAX(QteBoursier_GLPI10894)
			
		,QteNouvSouscDansAnneeFinissantEnDateDu_glpi11449 = MAX(QteNouvSouscDansAnneeFinissantEnDateDu_glpi11449)
			
		,QteSouscRIDansAnneeFinissantEnDateDu_glpi11450 = MAX(QteSouscRIDansAnneeFinissantEnDateDu_glpi11450)
		
	from (

		select
			EnDateDu = LEFT(CONVERT(VARCHAR, @dtDateFin, 120), 10), 
			a.qteSouscripteur as qteTotalSouscripteur, 
			b.qteSouscripteur as qteSouscripteurUniv,
			c.qteSouscripteur as qteSouscripteurReeeflex,  
			d.qteSouscripteur as qteSouscripteurIndiv
			
			,QteSouscAvecSeulementDesConvCollectiveREEEAvecRI = 0
			
			,QteSouscActifGLPI10712 = 0
			
			,QteBoursier_GLPI10829 = 0
			
			,QteSousc_GLPI10829 = 0
			
			,QteBoursier_GLPI10894 = 0
			
			,QteNouvSouscDansAnneeFinissantEnDateDu_glpi11449 = 0
			
			,QteSouscRIDansAnneeFinissantEnDateDu_glpi11450 = 0
			
		from 
			(	select count(distinct subscriberID) as "qteSouscripteur"
				from #test
			) as a,

			(	select count(distinct subscriberID) as "qteSouscripteur", iID_Regroupement_Regime 
				from #test 
				group by iID_Regroupement_Regime 
				having iID_Regroupement_Regime = 1
			) as b, 

			(	select count(distinct subscriberID) as "qteSouscripteur", iID_Regroupement_Regime 
				from #test 
				group by iID_Regroupement_Regime 
				having iID_Regroupement_Regime = 2
			) as c,

			(	select count(distinct subscriberID) as "qteSouscripteur", iID_Regroupement_Regime 
				from #test 
				group by iID_Regroupement_Regime 
				having iID_Regroupement_Regime = 3
			) as d
		
		union ALL
		
		SELECT -- glpi 10470
			EnDateDu = LEFT(CONVERT(VARCHAR, @dtDateFin, 120), 10),
			
			qteTotalSouscripteur = 0, 
			qteSouscripteurUniv = 0,
			qteSouscripteurReeeflex = 0,  
			qteSouscripteurIndiv = 0
			
			,QteSouscAvecSeulementDesConvCollectiveREEEAvecRI = COUNT(DISTINCT s.SubscriberID)
			
			,QteSouscActifGLPI10712 = 0
			
			,QteBoursier_GLPI10829 = 0
			
			,QteSousc_GLPI10829 = 0
			
			,QteBoursier_GLPI10894 = 0
			
			,QteNouvSouscDansAnneeFinissantEnDateDu_glpi11449 = 0
			
			,QteSouscRIDansAnneeFinissantEnDateDu_glpi11450 = 0

		FROM dbo.Un_Subscriber s
		join ( --sousc avec RI
			SELECT DISTINCT c.SubscriberID
			FROM dbo.Un_Convention c
			JOIN dbo.Un_Unit u ON c.ConventionID = u.ConventionID
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
						where LEFT(CONVERT(VARCHAR, startDate, 120), 10) <= @dtDateFin -- Si je veux l'état à une date précise 
						group by conventionid
						) ccs on ccs.conventionid = cs.conventionid 
							and ccs.startdate = cs.startdate 
							and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
				) css on C.conventionid = css.conventionid
			where c.PlanID <> 4
			and isnull(u.IntReimbDate,'3000-01-01') <= @dtDateFin
			) sRI ON s.SubscriberID = sRI.SubscriberID		
		left join ( --sousc sans RI
			SELECT DISTINCT c.SubscriberID
			FROM dbo.Un_Convention c
			JOIN dbo.Un_Unit u ON c.ConventionID = u.ConventionID
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
						where LEFT(CONVERT(VARCHAR, startDate, 120), 10) <= @dtDateFin -- Si je veux l'état à une date précise 
						group by conventionid
						) ccs on ccs.conventionid = cs.conventionid 
							and ccs.startdate = cs.startdate 
							and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
				) css on C.conventionid = css.conventionid
			where c.PlanID <> 4
			and isnull(u.IntReimbDate,'3000-01-01') > @dtDateFin
			) sSansRI ON s.SubscriberID = sSansRI.SubscriberID	
		where sSansRI.SubscriberID is null
		
		UNION
		
		SELECT 
		
			EnDateDu = LEFT(CONVERT(VARCHAR, @dtDateFin, 120), 10),
			
			qteTotalSouscripteur = 0, 
			qteSouscripteurUniv = 0,
			qteSouscripteurReeeflex = 0,  
			qteSouscripteurIndiv = 0
			
			,QteSouscAvecSeulementDesConvCollectiveREEEAvecRI = 0
		
			,QteSouscActifGLPI10712 = count(DISTINCT c.SubscriberID)
			
			,QteBoursier_GLPI10829 = 0
			
			,QteSousc_GLPI10829 = 0
			
			,QteBoursier_GLPI10894 = 0
			
			,QteNouvSouscDansAnneeFinissantEnDateDu_glpi11449 = 0
			
			,QteSouscRIDansAnneeFinissantEnDateDu_glpi11450 = 0
			
		FROM dbo.Un_Convention c
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
						where LEFT(CONVERT(VARCHAR, startDate, 120), 10) <= @dtDateFin
						group by conventionid
						) ccs on ccs.conventionid = cs.conventionid 
							and ccs.startdate = cs.startdate 
							and cs.ConventionStateID in ('REE','TRA')
				) css on C.conventionid = css.conventionid

		UNION
		
		SELECT 
		
			EnDateDu = LEFT(CONVERT(VARCHAR, @dtDateFin, 120), 10),
			
			qteTotalSouscripteur = 0, 
			qteSouscripteurUniv = 0,
			qteSouscripteurReeeflex = 0,  
			qteSouscripteurIndiv = 0
			
			,QteSouscAvecSeulementDesConvCollectiveREEEAvecRI = 0
		
			,QteSouscActifGLPI10712 =0
			
			,QteBoursier_GLPI10829 = COUNT(DISTINCT C.BeneficiaryID)
			
			,QteSousc_GLPI10829 = 0
			
			,QteBoursier_GLPI10894 = 0
			
			,QteNouvSouscDansAnneeFinissantEnDateDu_glpi11449 = 0
			
			,QteSouscRIDansAnneeFinissantEnDateDu_glpi11450 = 0
		
		FROM dbo.Un_Convention C
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
		WHERE 
			isnull(U.SignatureDate,'1950-01-01') <= @dtDateFin
			AND (U.TerminatedDate IS NULL OR U.TerminatedDate > @dtDateFin)

		UNION

		--2
		SELECT 
			EnDateDu = LEFT(CONVERT(VARCHAR, @dtDateFin, 120), 10),
			
			qteTotalSouscripteur = 0, 
			qteSouscripteurUniv = 0,
			qteSouscripteurReeeflex = 0,  
			qteSouscripteurIndiv = 0
			
			,QteSouscAvecSeulementDesConvCollectiveREEEAvecRI = 0
		
			,QteSouscActifGLPI10712 =0
			
			,QteBoursier_GLPI10829 = 0
			
			,QteSousc_GLPI10829 = count(DISTINCT c.SubscriberID )
			
			,QteBoursier_GLPI10894 = 0
			
			,QteNouvSouscDansAnneeFinissantEnDateDu_glpi11449 = 0
			
			,QteSouscRIDansAnneeFinissantEnDateDu_glpi11450 = 0
			
		FROM dbo.Un_Convention c
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
		WHERE 1=1
			and isnull(U.SignatureDate,'1950-01-01') <= @dtDateFin
		
		UNION
	
		SELECT 
		
			EnDateDu = LEFT(CONVERT(VARCHAR, @dtDateFin, 120), 10),
			
			qteTotalSouscripteur = 0, 
			qteSouscripteurUniv = 0,
			qteSouscripteurReeeflex = 0,  
			qteSouscripteurIndiv = 0
			
			,QteSouscAvecSeulementDesConvCollectiveREEEAvecRI = 0
		
			,QteSouscActifGLPI10712 =0
			
			,QteBoursier_GLPI10829 = 0
			
			,QteSousc_GLPI10829 = 0
		
			,QteBoursier_GLPI10894 = count(DISTINCT c.BeneficiaryID)
			
			,QteNouvSouscDansAnneeFinissantEnDateDu_glpi11449 = 0
			
			,QteSouscRIDansAnneeFinissantEnDateDu_glpi11450 = 0
		FROM 
			Un_Convention c
			join Un_Scholarship s on c.ConventionID = s.ConventionID AND s.ScholarshipStatusID = 'PAD'
			join Un_ScholarshipPmt sp ON s.ScholarshipID = sp.ScholarshipID
			join Un_Oper o ON sp.OperID= o.OperID
			LEFT JOIN Un_OperCancelation oc1 on o.OperID = oc1.OperSourceID
			LEFT join Un_OperCancelation oc2 on o.OperID = oc2.OperID
		WHERE 
			o.OperDate <=@dtDateFin
			and oc1.OperID IS null
			and oc2.OperID IS null

		UNION
		
		SELECT 
			EnDateDu = LEFT(CONVERT(VARCHAR, @dtDateFin, 120), 10),
			
			qteTotalSouscripteur = 0, 
			qteSouscripteurUniv = 0,
			qteSouscripteurReeeflex = 0,  
			qteSouscripteurIndiv = 0
			
			,QteSouscAvecSeulementDesConvCollectiveREEEAvecRI = 0
		
			,QteSouscActifGLPI10712 =0
			
			,QteBoursier_GLPI10829 = 0
			
			,QteSousc_GLPI10829 = 0
		
			,QteBoursier_GLPI10894 = 0
			
			,QteNouvSouscDansAnneeFinissantEnDateDu_glpi11449 = COUNT(*)
			
			,QteSouscRIDansAnneeFinissantEnDateDu_glpi11450 = 0	
		from (
			select c.SubscriberID
			FROM dbo.Un_Convention c
			JOIN (
				SELECT DISTINCT c.SubscriberID
				from  Un_Convention c
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
							where LEFT(CONVERT(VARCHAR, startDate, 120), 10) <= LEFT(CONVERT(VARCHAR, @dtDateFin, 120), 10) -- Si je veux l'état à une date précise 
							group by conventionid
							) ccs on ccs.conventionid = cs.conventionid 
								and ccs.startdate = cs.startdate 
								and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
					) css on C.conventionid = css.conventionid
				)sub ON c.SubscriberID = sub.SubscriberID -- le souscripteur a une convention ouverte au 31 décembre 2013
			JOIN dbo.Un_Subscriber s ON c.SubscriberID = s.SubscriberID
			JOIN dbo.Un_Unit u ON c.ConventionID = u.ConventionID
			GROUP by c.SubscriberID
			HAVING year(MIN(u.SignatureDate)) = YEAR(@dtDateFin) -- la 1ere date de signature est en 2013		
			) V

		UNION
		
	---------------------------------------------------
			--- Pour les années dont la date du 31 décembre est passée
		SELECT 
			EnDateDu = LEFT(CONVERT(VARCHAR, @dtDateFin, 120), 10),
			
			qteTotalSouscripteur = 0, 
			qteSouscripteurUniv = 0,
			qteSouscripteurReeeflex = 0,  
			qteSouscripteurIndiv = 0
			
			,QteSouscAvecSeulementDesConvCollectiveREEEAvecRI = 0
		
			,QteSouscActifGLPI10712 =0
			
			,QteBoursier_GLPI10829 = 0
			
			,QteSousc_GLPI10829 = 0
		
			,QteBoursier_GLPI10894 = 0
			
			,QteNouvSouscDansAnneeFinissantEnDateDu_glpi11449	= 0
			
			,QteSouscRIDansAnneeFinissantEnDateDu_glpi11450 = MAX(QteSouscRI)
			from (
			
					SELECT QteSouscRI = COUNT(*)
					from (
						SELECT s.SubscriberID
						from (

							SELECT DISTINCT c.SubscriberID
							FROM dbo.Un_Convention c
							JOIN dbo.Un_Unit u ON c.ConventionID = u.ConventionID
							WHERE year(u.IntReimbDate) = YEAR(@dtDateFin)
							)s
						LEFT JOIN (
							SELECT DISTINCT c.SubscriberID
							FROM dbo.Un_Convention c
							JOIN dbo.Un_Unit u ON c.ConventionID = u.ConventionID
							WHERE isnull(u.IntReimbDate,'3000-01-01') > @dtDateFin
							AND isnull(u.TerminatedDate,'3000-01-01') > @dtDateFin
								) sEPG ON s.SubscriberID = sEPG.SubscriberID
						WHERE sEPG.SubscriberID IS null
						-- Pour les années dont la date du 31 décembre est passée
						and @dtDateFin <= LEFT(CONVERT(VARCHAR, getdate(), 120), 10)
					 ) V

					UNION

					--- Pour les années dont la date du 31 décembre est dans le futur
					SELECT 
						QteSouscRI = count(*)
					from (
						select DISTINCT
							c.SubscriberID 
						FROM dbo.Un_Convention c
						JOIN dbo.Un_Unit u ON c.ConventionID = u.ConventionID  and u.TerminatedDate IS null
						join Un_Modal m ON u.ModalID = m.ModalID
						join Un_Plan p ON c.PlanID = p.PlanID
						WHERE YEAR(dbo.FN_UN_EstimatedIntReimbDate (m.PmtByYearID,m.PmtQty,m.BenefAgeOnBegining, u.InForceDate,p.IntReimbAge,u.IntReimbDateAdjust)) = YEAR(@dtDateFin)
						) s
					left JOIN (
						select DISTINCT
							c.SubscriberID 
						FROM dbo.Un_Convention c
						JOIN dbo.Un_Unit u ON c.ConventionID = u.ConventionID and u.TerminatedDate IS null
						join Un_Modal m ON u.ModalID = m.ModalID
						join Un_Plan p ON c.PlanID = p.PlanID
						WHERE YEAR(dbo.FN_UN_EstimatedIntReimbDate (m.PmtByYearID,m.PmtQty,m.BenefAgeOnBegining, u.InForceDate,p.IntReimbAge,u.IntReimbDateAdjust)) > YEAR(@dtDateFin)
						) sRiAfter ON s.SubscriberID = sRiAfter.SubscriberID
					WHERE sRiAfter.SubscriberID IS null	
					-- Pour les années dont la date du 31 décembre est dans le futur
					and @dtDateFin > LEFT(CONVERT(VARCHAR, getdate(), 120), 10)
				) k
	
	---------------------FIN ------------------------
	
	) V
	group by EnDateDu
END


