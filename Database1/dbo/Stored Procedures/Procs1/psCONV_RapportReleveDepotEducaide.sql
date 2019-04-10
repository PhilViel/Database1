/****************************************************************************************************
Copyrights (c) 2011 Gestion Universitas inc.

Code du service		: psCONV_RapportReleveDepotEducaide
Nom du service		: Bénérer relevé de dépôt des conventions centraide et Persevera
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXECUTE psCONV_RapportReleveDepotEducaide '2012-12-31', 'Persevera'
						EXECUTE psCONV_RapportReleveDepotEducaide '2012-12-31', 'CentraideEstrie'

drop procedure psCONV_RapportReleveDepotCentraide

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2013-01-17		Donald Huppé						Création du service		
		2014-06-26		Donald Huppé						Ajout de IQI + MIM 	
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportReleveDepotEducaide] 
(
	@EnDatedu datetime,
	@Programme varchar(20)

)
AS
BEGIN

--221                         UNI-ECE - Éducaide Centraide Estrie
--222                         UNI-ECS - Éducaide Centraide Côte-Sud = KRTB

		SELECT DISTINCT
			c.ConventionID,
			DateRIestime = max(dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, U.IntReimbDateAdjust))
		into #conv
		FROM dbo.Un_Convention c
		JOIN dbo.Un_Unit u on c.ConventionID = u.ConventionID
		JOIN Un_Modal M ON M.ModalID = U.ModalID
		JOIN Un_Plan P ON P.PlanID = M.PlanID
		JOIN Un_SaleSource ss ON u.SaleSourceID = ss.SaleSourceID
		WHERE 
			(@Programme = 'CentraideEstrie' and ss.SaleSourceID in (221))
			OR
			(@Programme = 'CentraideKRTB' and ss.SaleSourceID in (222))
			OR
			(@Programme = 'Persevera' and ss.SaleSourceID = 235)
		GROUP by c.ConventionID

SELECT --top 1
	conventionno,
	
	TuteurLongSexName,
	TuteurShortSexName,
	
	TuteurNom,
	TuteurPrenom,
	
	TuteurAdresse,
	TuteurVille,
	TuteurProv,
	TuteurCodePostal,
	TuteurPays,
	
	BenefNom,
	BenefPrenom,
	
	DateRIestime,
	
	Epargne,
	
	SCEE = SCEE + INS + IST ,
	SCEEPlus = SCEEPlus + ISPlus,
	BEC = BEC + IBC,
	IQEE = IQEEBase + IQEEMajore + ICQ + III + IIQ + IQI + MIM + IMQ
	
FROM (

	select 
		
		c.conventionno, 
		
		TuteurLongSexName =  sext.LongSexName,
		TuteurShortSexName =  sext.ShortSexName,
		
		TuteurNom = ht.LastName,
		TuteurPrenom = ht.FirstName,
		
		TuteurAdresse = at.Address,
		TuteurVille = at.City,
		TuteurProv= at.StateName,
		TuteurCodePostal = at.ZipCode,
		TuteurPays = at.CountryID,
		
		BenefNom = hb.LastName,
		BenefPrenom = hb.FirstName,
		
		cent.DateRIestime,
		
		Epargne = isnull(ep.Epargne,0),
		
		SCEE = isnull(SCEE,0),
		SCEEPlus = isnull(SCEEPlus,0),
		BEC = isnull(BEC,0),

		IQEEBase = sum(case when ot.conventionopertypeid = 'CBQ' then ConventionOperAmount else 0 end ),
		IQEEMajore = sum(case when ot.conventionopertypeid = 'MMQ' then ConventionOperAmount else 0 end ),
		
		RendInd = sum(case when ot.conventionopertypeid = 'INM' AND c.PlanID = 4 then ConventionOperAmount else 0 end ),
		IBC = sum(case when ot.conventionopertypeid = 'IBC' then ConventionOperAmount else 0 end ),
		ICQ = sum(case when ot.conventionopertypeid = 'ICQ' then ConventionOperAmount else 0 end ),
		III = sum(case when ot.conventionopertypeid = 'III' then ConventionOperAmount else 0 end ),
		IIQ = sum(case when ot.conventionopertypeid = 'IIQ' then ConventionOperAmount else 0 end ),
		IQI = sum(case when ot.conventionopertypeid = 'IQI' then ConventionOperAmount else 0 end ),
		MIM = sum(case when ot.conventionopertypeid = 'MIM' then ConventionOperAmount else 0 end ),
		IMQ = sum(case when ot.conventionopertypeid = 'IMQ' then ConventionOperAmount else 0 end ),
		INS = sum(case when ot.conventionopertypeid = 'INS' then ConventionOperAmount else 0 end ),
		ISPlus = sum(case when ot.conventionopertypeid = 'IS+' then ConventionOperAmount else 0 end ),
		IST = sum(case when ot.conventionopertypeid = 'IST' then ConventionOperAmount else 0 end )
	from 
		un_conventionoper co
		join un_conventionopertype ot on co.conventionopertypeid = ot.conventionopertypeid
		JOIN dbo.Un_Convention c on co.conventionid = c.conventionid
		JOIN dbo.Un_Beneficiary b ON c.BeneficiaryID = b.BeneficiaryID
		JOIN dbo.Mo_Human hb ON b.BeneficiaryID = hb.HumanID
		JOIN dbo.Mo_Human ht on b.iTutorID = ht.HumanID
		JOIN dbo.Mo_Adr at on ht.AdrID = at.AdrID
		JOIN Mo_Sex sext ON sext.SexID = ht.SexID AND sext.LangID = ht.LangID
		join #conv cent on c.ConventionID = cent.ConventionID
	
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
					where LEFT(CONVERT(VARCHAR, startDate, 120), 10) < @EnDatedu 
					group by conventionid
					) ccs on ccs.conventionid = cs.conventionid 
						and ccs.startdate = cs.startdate 
						--and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
			) css on C.conventionid = css.conventionid
		
		join un_oper o on co.operid = o.operid
		left join (
				SELECT
					U.ConventionID,
					Epargne = SUM(Ct.Cotisation + Ct.Fee)
				FROM dbo.Un_Unit U (readuncommitted)
				JOIN Un_Cotisation Ct (readuncommitted) ON Ct.UnitID = U.UnitID
				JOIN Un_Oper o ON ct.operid = O.operid
				where O.operdate <= @EnDatedu
				group by U.ConventionID
			)ep on c.conventionid = ep.conventionid
		left join (
			select 
				conventionid,
				SCEE = sum(fcesg),
				SCEEPlus = sum(facesg),
				BEC = sum(fCLB)
			from un_cesp ce
			join un_oper op on ce.operid = op.operid
			where op.operdate <= @EnDatedu
			group by conventionid
			)scee on c.conventionid = scee.conventionid
	where 1=1
	and o.operdate <= @EnDatedu
	and ot.conventionopertypeid in( 'CBQ','MMQ','IBC','ICQ','III','IIQ','IMQ','INS','IS+','IST','INM','IQI','MIM')

	group by 
		c.conventionno,
		sext.LongSexName,
		sext.ShortSexName,
		
		ht.LastName,
		ht.FirstName,
		
		at.Address,
		at.City,
		at.StateName,
		at.ZipCode,
		at.CountryID,
		
		hb.LastName,
		hb.FirstName,
		
		cent.DateRIestime,
		isnull(ep.Epargne,0),
		isnull(SCEE,0),
		isnull(SCEEPlus,0),
		isnull(BEC,0)
	) V

order by 	
	TuteurNom,
	TuteurPrenom

END


