/****************************************************************************************************
Copyrights (c) 2013 Gestion Universitas inc
Nom                 :	psREPR_Rapport_OVNT_VerificationSignatureSurRencontreProspect
Description         :	Rapport sur sur les vente faite suite à une rencontre inscrite et confirmé dans un formulaire de rencontre dans l'OVNT

Valeurs de retours  :	Dataset 
Note                :	2013-08-30	Donald Huppé		Création
						2013-10-30	Donald Huppé		glpi 10300 - ajout de  QteTelSigne et AbsenceSignature
						2014-06-26	Donald Huppé		si pas de signature, on met les info du prospects
                        2017-01-10  Steeve Picard       Renommage de l'index sur la table «tbl_TEMP_OVNTRencontreProspect» pour respecter le standard
						2017-11-17	Donald Huppé		réparer bug qui tronque le no de tel dans le champs ConventionNO
*********************************************************************************************************************/

--  exec psREPR_Rapport_OVNT_VerificationSignatureSurRencontreProspect '2017-01-01', '2017-11-16', 738340

CREATE procedure [dbo].[psREPR_Rapport_OVNT_VerificationSignatureSurRencontreProspect] 
	(
	@StartDate DATETIME, -- Date de début
	@EndDate DATETIME, -- Date de fin
	@RepID int
	) 

as
BEGIN

	DECLARE @sql NVarChar(4000)
	
	if exists (SELECT * FROM sysobjects where name = 'tbl_TEMP_OVNTRencontreProspect')
		begin
		drop TABLE tbl_TEMP_OVNTRencontreProspect
		end
	
	SET @sql = N'SELECT lnnte.*
				INTO tbl_TEMP_OVNTRencontreProspect
				FROM OPENQUERY(LNNTE,''
					SELECT 
						id
						,tel_maison
						,tel_travail
						,tel_cellulaire
						,prenom
						,nom
						,ville
						,date_rencontre
						,convert(date_confirme,char(25)) as date_confirme
						,numero_rep as RepCode
					from
						reservation_formulaire as f
					'') lnnte
				where date_confirme > ''0000-00-00 00:00:00'''
	
	exec sp_executesql @sql

	CREATE index IX_TEMP_OVNTRencontreProspect_TelMaison_TelTravail_TelCellulaire on tbl_TEMP_OVNTRencontreProspect (tel_maison,tel_travail,tel_cellulaire)

	SELECT 
		v.RepID, QteTelSigne = COUNT(DISTINCT v.Phone1)	
	into #tblQteTelSigne
	FROM (

		select u.RepID, a.Phone1 --, MIN(u.SignatureDate)
		FROM dbo.Un_Convention c
		JOIN dbo.Un_Unit u ON c.ConventionID = u.ConventionID
		join Un_Rep r ON u.RepID = r.RepID
		JOIN dbo.Mo_Human hs on c.SubscriberID = hs.HumanID
		JOIN dbo.Mo_Adr a on hs.AdrID = a.AdrID
		/*
		WHERE 
			u.RepID = 149813
		and a.Phone1 = '4188161879'
		*/
		group by a.Phone1,u.RepID
		HAVING MIN(u.SignatureDate) BETWEEN @StartDate AND @EndDate
		)v
	GROUP BY v.RepID

	select 
		RangSignature
		,PresenceSignature = CASE WHEN V.SubscriberID is not null then 1 ELSE 0 end
		,id_rencontre = id
		,tel_maison
		,tel_travail
		,tel_cellulaire
		,prenom
		,nom
		,ville
		,date_rencontre
		,date_confirme
		,RepCode
		,v.RepID
		,RepOVNT
		,AgenceOVNT
		,SubscriberID
		,ConventionID
		,ConventionNo
		,UnitID
		,SignatureDate
		,Phone1
		,Mobile
		,RepVenteNom
		,RepVentePrenom
		,AgenceVente
		,SouscVentenom
		,SouscVentePrenom
		,QteTelSigne = isnull(ts.QteTelSigne,0)
		,AbsenceSignature = CASE WHEN V.SubscriberID is null then 1 ELSE 0 end
	--into #Final
	from (

		select 
			RangSignature = DENSE_RANK() OVER (
									partition by p.tel_maison /*u1.SubscriberID*/ -- #2 : basé sur tel_maison
									ORDER BY u1.SignatureDate,u1.ConventionID, u1.UnitID,u1.SubscriberID -- #1 : on numérote les signature
							),
			p.id
			,p.tel_maison
			,p.tel_travail
			,p.tel_cellulaire
			,p.prenom
			,p.nom
			,p.ville
			,p.date_rencontre
			,date_confirme = LEFT(CONVERT(VARCHAR, p.date_confirme, 120), 10)
			,p.RepCode
			
			,RepOVNT = hrOVNT.FirstName + ' ' + hrOVNT.LastName
			,AgenceOVNT = hbOVNT.FirstName + ' ' + hbOVNT.LastName
			
			,u1.SubscriberID
			,u1.ConventionID
			,ConventionNo =  isnull(CAST(u1.ConventionNo as VARCHAR(100)), case  --2014-06-26 si pas de signature on met le 1er numnéro de tel <> 0 --2017-11-17 : ajout du CAST as  VARCHAR(100)
												when p.tel_maison <> '0' then '(Mais) '+ p.tel_maison
												when p.tel_cellulaire <> '0' then '(Cell) '+ p.tel_cellulaire
												when p.tel_travail <> '0' then '(Trav) '+ p.tel_travail
												end)
									
								
			,u1.UnitID
			,u1.SignatureDate
			,u1.Phone1
			,u1.Mobile
			,u1.RepVenteNom
			,u1.RepVentePrenom
			,u1.AgenceVente
			,SouscVentenom = isnull(u1.SouscVentenom,p.nom) --2014-06-26 si pas de signature on met le nom du prospect
			,SouscVentePrenom = isnull(u1.SouscVentePrenom,p.prenom)--2014-06-26 si pas de signature on met le prenom du prospect
			,rOVNT.RepID

		from 
			tbl_TEMP_OVNTRencontreProspect p
			JOIN Un_Rep rOVNT ON p.RepCode = rOVNT.RepCode
			JOIN dbo.Mo_Human hrOVNT on rOVNT.RepID = hrOVNT.HumanID
			left JOIN (
				SELECT 
					c.SubscriberID,
					c.ConventionID,
					c.ConventionNo,
					u.UnitID,
					u.SignatureDate,
					a.Phone1,
					a.Mobile,
					RepVenteNom = hr.LastName,
					RepVentePrenom = hr.FirstName,
					AgenceVente = hbv.FirstName + ' ' + hbv.LastName,
					SouscVentenom = hs.LastName,
					SouscVentePrenom = hs.FirstName
					,r.RepID
				FROM dbo.Un_Convention c
				JOIN dbo.Un_Unit u on c.ConventionID = u.ConventionID
				JOIN Un_Rep r ON u.RepID = r.RepID --and r.BusinessStart is not null
				JOIN dbo.Mo_Human hr ON r.RepID = hr.HumanID
				JOIN dbo.Mo_Human hs ON c.SubscriberID = hs.HumanID
				JOIN dbo.Mo_Adr a ON hs.AdrID = a.AdrID
				LEFT JOIN (
						SELECT
							RB.RepID,
							BossID = MAX(BossID) -- au cas ou il y a 2 boss avec le même %.  alors on prend l'id le + haut. ex : repid = 497171
						FROM 
							Un_RepBossHist RB
							JOIN (
								SELECT
									RepID,
									RepBossPct = MAX(RepBossPct)
								FROM 
									Un_RepBossHist RB
								WHERE 
									RepRoleID = 'DIR'
									AND StartDate IS NOT NULL
									AND LEFT(CONVERT(VARCHAR, StartDate, 120), 10) <= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10)
									AND (EndDate IS NULL OR LEFT(CONVERT(VARCHAR, EndDate, 120), 10) >= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10)) 
								GROUP BY
									  RepID
								) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
						  WHERE RB.RepRoleID = 'DIR'
								AND RB.StartDate IS NOT NULL
								AND LEFT(CONVERT(VARCHAR, RB.StartDate, 120), 10) <= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10)
								AND (RB.EndDate IS NULL OR LEFT(CONVERT(VARCHAR, RB.EndDate, 120), 10) >= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10))
						  GROUP BY
								RB.RepID
					) bVente ON bVente.repid = r.RepID
				left JOIN dbo.Mo_Human hbv ON bVente.BossID = hbv.HumanID
				where u.SignatureDate >= @StartDate
				) u1 on (p.tel_maison = u1.Phone1  OR p.tel_cellulaire = u1.Mobile )and u1.SignatureDate >= p.date_rencontre and u1.RepID = rOVNT.RepID
		
			left JOIN (
					SELECT
						RB.RepID,
						BossID = MAX(BossID)
					FROM 
						Un_RepBossHist RB
						JOIN (
							SELECT
								RepID,
								RepBossPct = MAX(RepBossPct)
							FROM 
								Un_RepBossHist RB
							WHERE 
								RepRoleID = 'DIR'
								AND StartDate IS NOT NULL
								AND LEFT(CONVERT(VARCHAR, StartDate, 120), 10) <= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10)
								AND (EndDate IS NULL OR LEFT(CONVERT(VARCHAR, EndDate, 120), 10) >= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10)) 
							GROUP BY
								  RepID
							) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
					  WHERE RB.RepRoleID = 'DIR'
							AND RB.StartDate IS NOT NULL
							AND LEFT(CONVERT(VARCHAR, RB.StartDate, 120), 10) <= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10)
							AND (RB.EndDate IS NULL OR LEFT(CONVERT(VARCHAR, RB.EndDate, 120), 10) >= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10))
					  GROUP BY
							RB.RepID
				) bOVNT ON bOVNT.repid = rOVNT.RepID
			left JOIN dbo.Mo_Human hbOVNT ON bOVNT.BossID = hbOVNT.HumanID
		where
			p.date_confirme between @StartDate and @EndDate
			and (rOVNT.RepID = @RepID OR bOVNT.BossID = @RepID OR @RepID = 0)
		) V
	left JOIN #tblQteTelSigne ts ON ts.RepID = V.RepID
	where V.RangSignature = 1

	order BY
		V.repid,id,tel_maison,SignatureDate,ConventionID, UnitID

	return

END	


