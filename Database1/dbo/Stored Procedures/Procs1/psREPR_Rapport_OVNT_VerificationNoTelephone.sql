/****************************************************************************************************
Copyrights (c) 2013 Gestion Universitas inc
Nom                 :	psREPR_Rapport_OVNT_VerificationNoTelephone
Description         :	Rapport sur la vérification du numéro de téléphone faite par un représentasnt avant la date de signature du souscripteur
Valeurs de retours  :	Dataset 
Note                :	2013-08-09	Donald Huppé	Créaton
						2013-10-25	Donald Huppé	GLPI 10301 : AJOUT DE LA QTÉ DE TÉLÉPHONE VÉRIFIÉE
						2014-04-03	Donald Huppé	GLPI 11332 : Vérifier aussi le no tel cellulaire et OtherTel
						2014-05-20	Donald Huppé	GLPI 11526 : Ajout de ListeNoTel

*********************************************************************************************************************/

--  exec psREPR_Rapport_OVNT_VerificationNoTelephone '2013-01-01', '2013-08-01', 0

CREATE procedure [dbo].[psREPR_Rapport_OVNT_VerificationNoTelephone] 
	(
	@StartDate DATETIME, -- Date de début
	@EndDate DATETIME, -- Date de fin
	@RepID int
	) 

as
BEGIN
		DECLARE @sql VarChar(2000)

		-- select top 5000 * from tblLNNTE_tracage order by date desc
	-- populer la table à partir de la bd LNNTE	
	
		-- les donnée sont trop vieille
	if exists(SELECT TOP 1 tel from  tblLNNTE_tracage where LEFT(CONVERT(VARCHAR, DateMAJ, 120), 10) < LEFT(CONVERT(VARCHAR, getdate(), 120), 10) )
		-- ou il n'y a pas de données dans la table
		or not exists(SELECT TOP 1 tel from  tblLNNTE_tracage)
	begin
		--select * from tblLNNTE_tracage
		
		Delete FROM tblLNNTE_tracage
		
		select @sql = N'INSERT INTO tblLNNTE_tracage
		SELECT l.* , GETDATE()
		FROM OPENQUERY(LNNTE,''
			SELECT 
				tel, 
				min(date) as date, 
				u.matricule
			from
				nos_tracage as t
				left join jos_users as u on t.auteur = u.id
			group by tel,auteur
			order by tel
			'') l'
		
		exec (@sql)
	end
	
	select 
		a.Phone1, 
		r.RepCode, 
		u3.SignatureDate,
		c3.ConventionNo, 
		Rep = hr.FirstName + ' ' + hr.LastName, 
		VerificationFaite = case WHEN t.matricule is null then 0 else 1 end,
		dateverif =  min(t2.date),
		Directeur = hb.FirstName + ' ' + hb.LastName,
		bu.BossID,
		c3.SubscriberID,
		NomSousc = hs.LastName,
		PrenomSousc = hs.FirstName,
		NomRep = hr.LastName,
		PrenomRep = hr.FirstName,
		VerificationNONFaite = case WHEN t.matricule is null then 1 else 0 end,
		QteTelVerifie = ISNULL(QteTelVerifie,0),
		ListeNoTel = 
			CASE WHEN ISNULL(a.phone1,'') <> '' then dbo.fn_Mo_FormatPhoneNo(a.phone1,'CAN')  + ' (Maison)'  ELSE '' end + 
			CASE WHEN ISNULL(a.phone2,'') <> '' then CHAR(10) + dbo.fn_Mo_FormatPhoneNo(a.phone2,'CAN')  + ' (Travail)'  ELSE '' end + 
			CASE WHEN ISNULL(a.mobile,'') <> '' then CHAR(10) + dbo.fn_Mo_FormatPhoneNo(a.mobile,'CAN')  + ' (Portable)'  ELSE '' end + 
			CASE WHEN ISNULL(a.othertel,'') <> '' then CHAR(10) + dbo.fn_Mo_FormatPhoneNo(a.othertel,'CAN')  + ' (Autre)'  ELSE '' end 
	from 
		Un_Convention c3
		JOIN dbo.Mo_Human hs ON c3.SubscriberID = hs.HumanID
		JOIN dbo.Mo_Adr a ON hs.AdrID = a.AdrID
		JOIN dbo.Un_Unit u3 ON c3.ConventionID = u3.ConventionID
		JOIN Un_Rep r ON u3.RepID = r.RepID
		JOIN dbo.Mo_Human hr ON r.RepID = hr.HumanID
		left JOIN tblLNNTE_tracage t on t.matricule = r.RepCode and LEFT(CONVERT(VARCHAR, t.date, 120), 10) <= u3.SignatureDate AND (t.tel = a.Phone1 or t.tel = a.Phone2 OR t.tel = a.Mobile or a.OtherTel = t.tel)
		left JOIN tblLNNTE_tracage t2 on t2.matricule = r.RepCode AND (t2.tel = a.Phone1 or t2.tel = a.Phone2 OR t2.tel = a.Mobile or a.OtherTel = t2.tel)
		JOIN (
			SELECT c2.SubscriberID, firstUnitID = MIN(u.UnitID)
			from 
				Un_Convention c2
				JOIN dbo.Un_Unit u ON c2.ConventionID = u.ConventionID
				JOIN (
					SELECT c.SubscriberID, firstSignature = MIN(u.SignatureDate)
					from 
						Un_Convention c
						JOIN dbo.Un_Unit u ON c.ConventionID = u.ConventionID
					GROUP by c.SubscriberID
					) mus ON u.SignatureDate = mus.firstSignature and mus.SubscriberID = c2.SubscriberID
			--where c2.SubscriberID = 575993
			GROUP by c2.SubscriberID	
			)su ON  su.firstUnitID = u3.UnitID		
		JOIN (
			SELECT 
				M.UnitID,
				BossID = MAX(RBH.BossID)
			FROM (
				SELECT 
					U.UnitID,
					U.RepID,
					RepBossPct = MAX(RBH.RepBossPct)
				FROM dbo.Un_Unit U
				JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND (RBH.RepRoleID = 'DIR')
				JOIN Un_RepLevel BRL ON (BRL.RepRoleID = RBH.RepRoleID)
				JOIN Un_RepLevelHist BRLH ON (BRLH.RepLevelID = BRL.RepLevelID) AND (BRLH.RepID = RBH.BossID) AND (U.InForceDate >= BRLH.StartDate)  AND (U.InForceDate <= BRLH.EndDate  OR BRLH.EndDate IS NULL)
				GROUP BY U.UnitID, U.RepID
				) M
			JOIN dbo.Un_Unit U ON U.UnitID = M.UnitID
			JOIN Un_RepBossHist RBH ON RBH.RepID = M.RepID AND RBH.RepBossPct = M.RepBossPct AND (U.InForceDate >= RBH.StartDate)  AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
			GROUP BY 
				M.UnitID
		) bu on bu.UnitID = u3.UnitID
		JOIN dbo.Mo_Human hb on bu.BossID = hb.HumanID
		left JOIN (
			SELECT 
				matricule,
				QteTelVerifie = count(DISTINCT tel)	 
			from tblLNNTE_tracage
			where date BETWEEN @StartDate and @EndDate
			group by matricule
			)qv on r.RepCode = qv.matricule
	where 
		1=1
		AND u3.SignatureDate BETWEEN @StartDate and @EndDate
		and (u3.RepID = @RepID OR bu.BossID = @RepID OR @RepID = 0)
	group BY
	
		a.Phone1, 
		r.RepCode, 
		u3.SignatureDate,
		c3.ConventionNo, 
		hr.FirstName + ' ' + hr.LastName, 
		case WHEN t.matricule is null then 0 else 1 end,
		hb.FirstName + ' ' + hb.LastName,
		bu.BossID,
		c3.SubscriberID,
		hs.LastName,
		hs.FirstName,
		hr.LastName,
		hr.FirstName,
		case WHEN t.matricule is null then 1 else 0 end
		,ISNULL(QteTelVerifie,0)
		,a.phone1,
		a.phone2,
		a.mobile,
		a.othertel
	
	ORDER by hr.LastName + ', ' + hr.FirstName	,u3.SignatureDate

end


