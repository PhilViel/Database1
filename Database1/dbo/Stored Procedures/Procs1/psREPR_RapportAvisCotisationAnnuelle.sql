/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service		: psREPR_RapportAvisCotisationAnnuelle
Nom du service		: psREPR_RapportAvisCotisationAnnuelle
But 				: GLPI 7301 : Ce nouveau rapport est nécessaire afin d'éviter que l'agent qui traite ces avis annuels les consulte un par un à l'écran avant l'envoi 
					  au client (procédure faite présentement par l'agent et qui demande énormément de temps...).
Facette				: REPR

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	exec psREPR_RapportAvisCotisationAnnuelle '2018-10-01','2018-10-31', 'CHQ'

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2012-03-28		Donald Huppé						Création du service	(glpi 7301)
		2012-05-24		Donald Huppé						Ajout de #Notice.SubscriberID suite à la modif dans RP_UN_NoticeOfDeposit
		2012-06-12		Donald Huppé						Remplacer 31 par 30 car il peut arriver qu'on génère une date impossible ex : 2012-09-31
		2013-10-31		Donald Huppé						gérer les cas ou on aurait 30 et 31 février
		2015-08-18		Donald Huppé						Ajout du paramètre @PmtTypeID (glpi 14897)
		2015-12-21		Donald Huppé						GLPI 16348 : ajout de LongSexName + split des prénom et nom 
		2018-11-08		Donald Huppé						jira prod-12857 : ne pas sortir les convention CPT (capital atteint)
*********************************************************************************************************************/
CREATE procedure [dbo].[psREPR_RapportAvisCotisationAnnuelle] 
	(
	@StartDate DATETIME, -- Date de début
	@EndDate DATETIME,
	@PmtTypeID varchar(3) = 'CHQ'
	) 

as
BEGIN

	CREATE TABLE #Notice(
		DocTemplateID INTEGER,
		LangID VARCHAR(3),
		ConventionNo VARCHAR(75),
		SubscriberName VARCHAR(77),
		SubscriberAddress VARCHAR(75),
		SubscriberCity VARCHAR(100),
		SubscriberState VARCHAR(75),
		SubscriberZipCode VARCHAR(75),
		SubscriberCountry VARCHAR(75),
		PlanName VARCHAR(75),
		YearQualif INTEGER,
		BeneficiaryName VARCHAR(77),	
		DepositDate VARCHAR(75),
		ReelAmount VARCHAR(75), 
		EstimatedAmount VARCHAR(75), 
		AssAmount VARCHAR(75),
		TaxeAmount VARCHAR(75),
		Amount VARCHAR(75), 
		TotalAmount VARCHAR(75),
		SubscriberID int
	)

	INSERT INTO #Notice
	exec RP_UN_NoticeOfDeposit 1,@StartDate,@EndDate,1,@PmtTypeID

	SELECT 
		c.SubscriberID,
		N.ConventionNo,
		SubscriberLastName = hs.LastName,
		SubscriberFirstName = hs.FirstName,
		N.SubscriberAddress,
		N.SubscriberCity,
		N.SubscriberState,
		N.SubscriberZipCode,
		N.SubscriberCountry,
		N.PlanName,
		N.YearQualif,
		BeneficiaryLastName = hb.LastName,	
		BeneficiaryFirsName = hb.FirstName,	
		DepositDate = cast(DepositDate AS VARCHAR(75)),
		N.ReelAmount, 
		N.EstimatedAmount, 
		N.AssAmount,
		N.TaxeAmount,
		N.Amount, 
		N.TotalAmount,
		-- ici on remplace 31 par 30 car il peut arriver qu'on génère une date impossible ex : 2012-09-31
		FirstDepositDate = CAST(
								CAST(YEAR(u.InForceDate) AS VARCHAR(4))+'-'+
								CAST(MONTH(u.InForceDate) AS VARCHAR(2))+'-'+  
								case 
									when month(u.InForceDate) = 2 and day(c.FirstPmtDate) > 28 then '28'
									when month(u.InForceDate) in (4,6,9,11) and day(c.FirstPmtDate) = 31 then '30' 
									else CAST(day(c.FirstPmtDate) AS VARCHAR(2)) end
							AS DATETIME),
		u.SignatureDate,
		DatePrelevement = 'Le ' +CAST(day(c.FirstPmtDate) AS VARCHAR(2)) + '/' + CAST(MONTH(u.InForceDate) AS VARCHAR(2)),-- + ' annuellement',
		V.CotisationEtFraisReel,	

		CotisationEtFraisEstimé = ROUND(u.UnitQty * ISNULL(m.PmtRate, 0),2) * dbo.fn_Un_EstimatedNumberOfDepositSinceBeginning(
																				LEFT(CONVERT(VARCHAR, getdate()-1, 120), 10), -- en date de la veille pour éviter d'avoir un montant en retard si demandé en date du paiment théorique
																				-- ici on remplace 31 par 30 car il peut arriver qu'on génère une date impossible ex : 2012-09-31
																				--case when day(c.FirstPmtDate) = 31 then 30 else day(c.FirstPmtDate) end,
																				case 
																					when month(u.InForceDate) = 2 and day(c.FirstPmtDate) > 28 then 28 
																					when month(u.InForceDate) in (4,6,9,11) and day(c.FirstPmtDate) = 31 then 30 
																					else day(c.FirstPmtDate) end,
																				m.PmtByYearID,
																				m.PmtQty, 
																				u.InForceDate),

		NombreDepot = m.PmtQty,
		ArretDePaiement = CASE WHEN br.ConventionID IS NULL THEN 'Non' ELSE 'Oui' end

		,LastDepositDate = dbo.fn_Un_LastDepositDate(
			u.InForceDate,
			-- ici on remplace 31 par 30 car il peut arriver qu'on génère une date impossible ex : 2012-09-31
			 CAST(
					CAST(YEAR(u.InForceDate) AS VARCHAR(4))+'-'+
					CAST(MONTH(u.InForceDate) AS VARCHAR(2))+'-'+  
					case 
						when month(u.InForceDate) = 2 and day(c.FirstPmtDate) > 28 then '28'
						when month(u.InForceDate) in (4,6,9,11) and day(c.FirstPmtDate) = 31 then '30' 
						else CAST(day(c.FirstPmtDate) AS VARCHAR(2)) end
				AS DATETIME),
			m.PmtQty,
			m.PmtByYearID)
		,ss.LongSexName

	from (
		select
			c1.ConventionID,
			u1.UnitID,
			CotisationEtFraisReel = sum(ct.Cotisation + ct.Fee)
		from 
			Un_Convention c1
			JOIN #Notice N1 ON c1.ConventionNo = N1.ConventionNo
			JOIN dbo.Un_Unit u1 ON c1.ConventionID = u1.ConventionID
			JOIN Un_Modal m1 ON u1.ModalID = m1.ModalID
			JOIN Un_Cotisation ct ON u1.UnitID = ct.UnitID

		WHERE 1=1
			AND m1.PmtByYearID= 1
			AND m1.PmtQty > 1
			AND ct.EffectDate <= getdate()
		GROUP BY
			c1.ConventionID,
			u1.UnitID
		) V
	JOIN dbo.Un_Unit u ON U.unitID = V.UnitID	
	JOIN dbo.Un_Convention c on c.ConventionID = u.ConventionID
	JOIN dbo.Mo_Human hs ON c.SubscriberID = hs.HumanID
	join mo_sex ss on ss.SexID = hs.SexID and ss.LangID = hs.LangID
	JOIN dbo.Mo_Human hb ON c.BeneficiaryID = hb.HumanID
	JOIN #Notice N ON c.ConventionNo = N.ConventionNo
	JOIN Un_Modal m ON u.ModalID = m.ModalID
	LEFT JOIN dbo.fnCONV_ObtenirStatutUnitEnDatePourTous(@StartDate, NULL) UUS ON UUS.UnitID = U.UnitID
	LEFT JOIN un_breaking br ON c.ConventionID = br.ConventionID AND getdate() BETWEEN br.BreakingStartDate  and isnull(br.BreakingEndDate,'5000-01-01')
	WHERE ISNULL(uus.UnitStateID,'') <> 'CPT'


	END


