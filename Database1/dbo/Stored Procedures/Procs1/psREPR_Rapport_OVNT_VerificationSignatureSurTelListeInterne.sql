/****************************************************************************************************
Copyrights (c) 2013 Gestion Universitas inc
Nom                 :	psREPR_Rapport_OVNT_VerificationSignatureSurTelListeInterne
Description         :	Rapport sur sur les vente faite à un numéro de téléphone préalablement inscrit sur la liste interne des numéro interdit
						-- sert à voir ceux qui vendent à des numéro interdit ou qui ont peut-être inscrit le numéro sur la liste afin de se le réserver.
Valeurs de retours  :	Dataset 
Note                :	2013-08-23	Donald Huppé		Créaton
					2013-08-23	Frédérick Thibault	Utilisation d'une string pour le script de création de tables temporaire
													(Problème avec serveur lié lors de l'intégration continue)
                         2017-01-10     Steeve Picard       Renommage de l'index sur la table «tbl_TEMP_Lnnte» pour respecter le standard

*********************************************************************************************************************/
--  exec psREPR_Rapport_OVNT_VerificationSignatureSurTelListeInterne '2007-01-01', '2013-08-01', 0
CREATE procedure [dbo].[psREPR_Rapport_OVNT_VerificationSignatureSurTelListeInterne] 
	(
	@StartDate DATETIME, -- Date de début
	@EndDate DATETIME, -- Date de fin
	@RepID int
	) 

as
BEGIN

		DECLARE @sql NVarChar(4000)
		
		if exists (SELECT * FROM sysobjects where name = 'tbl_TEMP_Lnnte')
			begin
			drop TABLE tbl_TEMP_Lnnte
			end
		
		SET @sql = N'SELECT lnnte.*
					INTO tbl_TEMP_Lnnte
					FROM OPENQUERY(LNNTE,''
						SELECT 
							no_tel_interne
							,matricule as RepCode
							,convert(date_effective,char(25)) as date_effective

						from
							nos_exclus_UN as n
							left join jos_users as u on n.id_rep = u.id
						'') lnnte
					where date_effective > ''0000-00-00 00:00:00'''
		
		exec sp_executesql @sql

	--SELECT lnnte.*
	--INTO tbl_TEMP_Lnnte
	--FROM OPENQUERY(LNNTE,'
	--	SELECT 
	--		no_tel_interne
	--		,matricule as RepCode
	--		,convert(date_effective,char(25)) as date_effective

	--	from
	--		nos_exclus_UN as n
	--		left join jos_users as u on n.id_rep = u.id
	--	') lnnte
	--where date_effective > '0000-00-00 00:00:00'

	CREATE index IX_TEMP_Lnnte_NoTelInterne on tbl_TEMP_Lnnte (no_tel_interne)

	--SELECT * FROM Un_Rep where RepCode = 6141
	
	/*
ID souscripteur
Nom souscripteur
Prénom souscripteur
Tous les téléphones
Date de la demande d’ajout à la liste interne
Code Représentant ayant demandé l’ajout (requérant inscrit sur la liste)
Nom Représentant ayant demandé l’ajout
Prénom Représentant ayant demandé l’ajout
Directeur d’agence du représentant ayant demandé l’ajout
Date de signature
# convention
Code Représentant signataire
Nom Représentant signataire
Prénom Représentant signataire
Directeur d’agence du représentant signataire

	*/
	
	select *
	from (
	
	SELECT 
		RangSignature = DENSE_RANK() OVER (
								partition by c.SubscriberID -- #2 : basé sur le SubscriberID
								ORDER BY u.SignatureDate,c.ConventionID, u.UnitID -- #1 : on numérote les signature
						),
		c.SubscriberID,
		SouscNom = hs.LastName,
		SouscPrenom = hs.FirstName,
		a.Phone1,
		a.Phone2,
		a.Fax,
		a.Mobile,
		a.WattLine,
		a.OtherTel,
		a.Pager,
	
		Date_effectiveListeInterne = LEFT(CONVERT(VARCHAR, l.date_effective, 120), 10),
		No_InterditListeInterne = l.no_tel_interne, 
				
		RepCodeListeInterne = l.RepCode,
		RepNomListeInterne = hrL.LastName,
		RepPrenomListeInterne = hrL.FirstName,
		DirecteurListeInterne = hblnnte.FirstName + ' ' + hblnnte.LastName,
		
		u.SignatureDate,
		c.ConventionNo,
		RepCodeSign = r.RepCode,
		RepNomSign = hr.LastName,
		RepPrenomSign = hr.FirstName,
		DiecteurSign = hbv.FirstName + ' ' + hbv.LastName
		
	--SELECT *	
	FROM dbo.Un_Convention c
	JOIN dbo.Un_Unit u on c.ConventionID = u.ConventionID
	JOIN Un_Rep r ON u.RepID = r.RepID and r.BusinessStart is not null
	JOIN dbo.Mo_Human hr ON r.RepID = hr.HumanID
	JOIN dbo.Mo_Human hs ON c.SubscriberID = hs.HumanID
	JOIN dbo.Mo_Adr a ON hs.AdrID = a.AdrID
	/*
	join (
		SELECT a2.Phone, firstUnitID = MIN(u.UnitID)
		from 
			Un_Convention c2
			JOIN dbo.Un_Unit u ON c2.ConventionID = u.ConventionID
			JOIN dbo.Mo_Human hs2 on c2.SubscriberID = hs2.HumanID
			JOIN TmpAdr a2 ON hs2.AdrID = a2.AdrID
			JOIN (
				SELECT a.Phone, firstSignature = MIN(u.SignatureDate)
				from 
					Un_Convention c
					JOIN dbo.Un_Unit u ON c.ConventionID = u.ConventionID
					JOIN dbo.Mo_Human hs on c.SubscriberID = hs.HumanID
					JOIN TmpAdr a ON hs.AdrID = a.AdrID
				GROUP by a.Phone
				) mus ON u.SignatureDate = mus.firstSignature and mus.Phone = a2.Phone
		where a2.Phone = '4188445000'
		GROUP by a2.Phone	
		) t ON u.UnitID = t.firstUnitID
	*/
	--JOIN tbl_TEMP_Lnnte l ON l.no_tel_interne = a.Phone1 OR  l.no_tel_interne = a.Phone2
	JOIN tbl_TEMP_Lnnte l ON l.no_tel_interne = a.Phone1 OR l.no_tel_interne = a.Phone2 OR l.no_tel_interne = a.Fax OR l.no_tel_interne = a.Mobile OR l.no_tel_interne = a.WattLine OR l.no_tel_interne = a.OtherTel OR l.no_tel_interne = a.Pager
	--JOIN tbl_TEMP_Lnnte l ON l.no_tel_interne = t.Phone 
	JOIN Un_Rep rlnnte ON l.repcode = rlnnte.repcode and rlnnte.BusinessStart is not null
	JOIN dbo.Mo_Human hrL ON rlnnte.RepID = hrL.HumanID
	
	left JOIN (
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
		) bLnnte ON bLnnte.repid = rlnnte.RepID
	left JOIN dbo.Mo_Human hblnnte ON bLnnte.BossID = hblnnte.HumanID
	
	left JOIN (
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
	
	LEFT join tblOPER_OperationsRIO rio ON c.ConventionID = rio.iID_Convention_Destination AND rio.bRIO_Annulee = 0 AND rio.bRIO_QuiAnnule = 0			
	where 
		rio.iID_Convention_Destination IS null
		AND u.SignatureDate >=l.date_effective
		AND l.date_effective BETWEEN @StartDate and @EndDate
		and (u.RepID = @RepID OR bVente.BossID = @RepID OR @RepID = 0)
		--AND a.Phone1 = '4507609874'
		--and c.SubscriberID = 571231
	/*
	ORDER by 
		hr.FirstName + ' ' + hr.LastName
		,l.date_effective
		,c.SubscriberID
		*/
	) V	
	where 
		V.RangSignature = 1
		
	order by 
		RepCodeSign,
		V.SubscriberID
	
END	


