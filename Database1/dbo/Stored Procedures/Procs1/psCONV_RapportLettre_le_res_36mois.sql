/****************************************************************************************************
Copyrights (c) 2018 Gestion Universitas inc.

Code du service		: psCONV_RapportLettre_le_res_36mois 
Nom du service		: Générer la lettre de résiliation après 36 mois
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						@SubscriberID
						

Exemple d’appel		:	

EXEC psCONV_RapportLettre_le_res_36mois 649740 


Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2018-11-30		Donald Huppé						Création du service	
		2018-12-05		Donald Huppé						Ajout de NbBenef
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettre_le_res_36mois] 
	@SubscriberID INT
AS
BEGIN
	DECLARE
		@today datetime,
		@humanID integer
	
	set @today = GETDATE()
	
	CREATE TABLE #tbConv (
		TypeRegime VARCHAR (100),
		ConventionNo VARCHAR(40),
		ConventionID INT,
		EpargneRES MONEY,
		FraisTFR MONEY
			)

	-- Retrouver les RES
	INSERT INTO #tbConv
	SELECT
		TypeRegime = RR.vcCode_Regroupement,
		c.ConventionNo,
		c.ConventionID,
		EpargneRES = SUM(ct.Cotisation) * -1,
		FraisTFR = SUM(ISNULL(ct2.Fee,0)) * -1
	FROM Un_Unit U
	JOIN Un_Convention c on u.ConventionID = c.ConventionID
	JOIN Un_Plan P ON P.PlanID = C.PlanID
	JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
	JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
	JOIN Un_Oper O ON O.OperID = Ct.OperID
	JOIN Un_UnitReductionCotisation URC ON URC.CotisationID = Ct.CotisationID
	JOIN Un_UnitReduction ur ON urc.UnitReductionID = ur.UnitReductionID
	LEFT JOIN Un_UnitReductionCotisation URC2 ON URC2.UnitReductionID = URC.UnitReductionID AND URC2.CotisationID <> Ct.CotisationID
	LEFT JOIN Un_Cotisation Ct2 ON Ct2.CotisationID = URC2.CotisationID
	LEFT JOIN Un_Oper O2 ON O2.OperID = Ct2.OperID AND	O2.OperTypeID = 'TFR'
	WHERE 	
		O.OperTypeID in ( 'RES')
		AND c.SubscriberID = @SubscriberID
		AND o.OperDate = (
				-- TOUTES LES DERNIÈRES RES
				SELECT
					OperDate = MAX(O2.OperDate)
				FROM Un_Unit U2
				JOIN Un_Convention c2 on u2.ConventionID = c2.ConventionID
				JOIN Un_Cotisation Ct2 ON Ct2.UnitID = U2.UnitID
				JOIN Un_Oper O2 ON O2.OperID = Ct2.OperID
				WHERE c2.SubscriberID = @SubscriberID
					AND O2.OperTypeID = 'RES'
			)
	GROUP BY
		RR.vcCode_Regroupement,
		c.ConventionNo,
		c.ConventionID

	SELECT distinct
		humanID = S.SubscriberID,
		Adresse = ad.Address,
		Ville = ad.City,
		CodePostal = dbo.fn_Mo_FormatZIP( ad.ZipCode,ad.CountryID),
		Province = ad.StateName,
		SouscNom = HS.LastName,
		SouscPrenom = HS.FirstName,
		Langue = HS.LangID,
		appelLong = sex.LongSexName,
		appelCourt = sex.ShortSexName,
		HS.SexID,
		nomRep = HR.firstName + ' ' + HR.lastName,
		sexRep = HR.SexID,
		EpargneRES = P.EpargneRES,
		P.FraisTFR,
		SoldeSUB = ISNULL(SCEE.SCEE,0) + ISNULL(IQEE.IQEE,0),
		P.NbConv,
		p.NbBenef,
		P.NbRegime,
		DernierCPA_PlusDe24Mois = CASE WHEN DATEDIFF(MONTH,DateDernierCPA,GETDATE()) > 24 THEN 1 ELSE 0 END,
		EpgTransfereEnInteretSurRES = CASE WHEN ISNULL(INC.INC,0) = 0 THEN 0 ELSE 1 END,
		noConv = (SELECT STUFF((    SELECT ', ' + t.ConventionNo + ' (' + h.FirstName + ')'  AS [text()]
                        FROM #tbConv t 
						JOIN dbo.Un_Convention c ON t.ConventionNo = c.ConventionNo 
						JOIN dbo.Mo_Human h	ON c.BeneficiaryID = h.HumanID  
						FOR XML PATH('')
                        ), 1, 2, '' )
					),
		PlanClassification = [dbo].[fnCONV_ObtenirDossierClient](s.SubscriberID,1) + '\' + replace(LEFT(CONVERT(VARCHAR, @today, 120), 10),'-','')
							+ case HS.langID when 'FRA' then '_le_res_36mois' when 'ENU' then '_le_res_36mois_ang' end
	FROM dbo.Un_Subscriber S
	JOIN dbo.Mo_Human HS on S.SubscriberID = HS.HumanID
	JOIN Mo_Sex sex ON sex.SexID = HS.SexID AND sex.LangID = HS.LangID
	JOIN Mo_Adr ad on ad.AdrID = HS.AdrID
	JOIN dbo.Mo_Human HR on S.RepID = HR.HumanID
	LEFT JOIN (
		SELECT 
			EpargneRES = SUM(EpargneRES),
			FraisTFR = SUM(FraisTFR),
			NbConv = SUM(NbConv),
			NbBenef = SUM(NbBenef),
			NbRegime = COUNT(DISTINCT TypeRegime)
		FROM (
			SELECT
				TypeRegime,
				-- Par régime, le montant à rembourser doit être suppérieur à 10 $
				EpargneRES = CASE WHEN SUM(EpargneRES) < 10 THEN 0 ELSE SUM(EpargneRES) END,
				FraisTFR = SUM(FraisTFR),
				NbConv = COUNT(DISTINCT t.ConventionID),
				NbBenef = COUNT(DISTINCT c.BeneficiaryID)
			FROM #tbConv t
			JOIN Un_Convention c on c.ConventionID = t.ConventionID
			GROUP BY TypeRegime	
			)V2
		) P ON 1=1

	LEFT JOIN (
		SELECT
			DateDernierCPA = MAX(ct.EffectDate)
		FROM Un_Unit U
		JOIN Un_Convention c on u.ConventionID = c.ConventionID
		JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		WHERE 	
			O.OperTypeID in ( 'CPA')
			and c.SubscriberID = @SubscriberID
		GROUP BY
			c.ConventionNo,
			c.ConventionID
	) CPA ON 1=1

	LEFT JOIN (
		SELECT INC = SUM(co.ConventionOperAmount)
		FROM Un_ConventionOper CO
		WHERE CO.ConventionOperTypeID = 'INC'
			AND CO.OperID = (
				SELECT
					MAX_OperIdRES = MAX(o.OperID)
				FROM Un_Unit U
				JOIN Un_Convention c on u.ConventionID = c.ConventionID
				JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
				JOIN Un_Oper O ON O.OperID = Ct.OperID
				WHERE 	
					O.OperTypeID in ( 'RES')
					and c.SubscriberID = @SubscriberID
				)
		) INC ON 1=1
	LEFT JOIN (
		SELECT SCEE = SUM(CE.fCESG + CE.fACESG + CE.fCLB)
		FROM Un_CESP CE
		JOIN Un_Convention C ON C.ConventionID = CE.ConventionID
		JOIN #tbConv T ON T.ConventionID = C.ConventionID
		) SCEE ON 1=1
	LEFT JOIN (
		SELECT IQEE = SUM(CO.ConventionOperAmount)
		FROM Un_Convention C
		JOIN #tbConv T ON T.ConventionID = C.ConventionID
		JOIN Un_ConventionOper CO ON CO.ConventionID = C.ConventionID
		WHERE CO.ConventionOperTypeID IN ('CBQ','MMQ')
		) IQEE ON 1=1
	WHERE S.SubscriberID = @SubscriberID

END


