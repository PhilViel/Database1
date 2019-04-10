/****************************************************************************************************
Copyrights (c) 2017 Gestion Universitas inc.

Code du service		: psCONV_RapportLettre_le_arret_paiement
Nom du service		: Générer la lettre d'arrêt de paiement "le_arret_paiement"
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						@SubscriberID
						

Exemple d’appel		:	

EXEC psCONV_RapportLettre_le_arret_paiement 518748 --565950



Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2017-11-09		Donald Huppé						Création du service	
		
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettre_le_arret_paiement] 
	@SubscriberID INT
AS
BEGIN
	DECLARE
		@today datetime,
		@humanID integer
		
	
	set @today = GETDATE()
	
	CREATE TABLE #tbConv (
		ConventionNo varchar(15),
		BenefNom varchar(50),
		BenefPrenom varchar(50),
		SubscriberID integer,
		BeneficiaryID integer)

	-- Retrouver les paiement en NSF associé à la date dernier NSF
	SELECT 
		OperTypeID = MAX(OperTypeID),
		DatePrelevement = MAX(DatePrelevement),
		MontantPrelevement = SUM(V.MontantPrelevement) + SUM(V.INC),
		NbPrelevement= MAX(V.NbPrelevement),
		NbConv = MAX(V.NbConv )
	INTO #Prelevement
	FROM (
		SELECT
			O.OperID,
			O.OperTypeID,
			INC = ISNULL(INC.INC,0),
			DatePrelevement = MAX(o.OperDate), 
			MontantPrelevement = SUM(ct.Cotisation + ct.Fee + ct.BenefInsur + ct.SubscInsur + ct.TaxOnInsur ),
			NbPrelevement = COUNT(DISTINCT ct.OperID),
			NbConv = COUNT(DISTINCT c.ConventionID)
		FROM Mo_BankReturnLink RL
		JOIN Un_Oper oNSF on oNSF.OperID = RL.BankReturnCodeID
		JOIN Un_Oper o on o.OperID = RL.BankReturnSourceCodeID
		JOIN Un_Cotisation CT ON CT.OperID = O.OperID
		JOIN Un_Unit U ON U.UnitID = CT.UnitID
		JOIN Un_Convention C ON C.ConventionID = U.ConventionID
		JOIN Mo_Human HB on HB.HumanID = C.BeneficiaryID
		JOIN (
			--date dernier NSF
			SELECT MaxNSFDate = MAX(oNSF.OperDate)
			FROM Mo_BankReturnLink RL
			JOIN Un_Oper oNSF on oNSF.OperID = RL.BankReturnCodeID
			JOIN Un_Oper o on o.OperID = RL.BankReturnSourceCodeID
			JOIN Un_Cotisation CT ON CT.OperID = O.OperID
			JOIN Un_Unit U ON U.UnitID = CT.UnitID
			JOIN Un_Convention C ON C.ConventionID = U.ConventionID
			WHERE c.SubscriberID = @SubscriberID
			)MAXNSF on MAXNSF.MaxNSFDate = oNSF.OperDate
		LEFT JOIN (
			SELECT O1.OperID, INC =  SUM(co.ConventionOperAmount)
			FROM Un_ConventionOper co
			join Un_Convention c on c.ConventionID = co.ConventionID
			JOIN Un_Oper O1 ON O1.OperID = CO.OperID
			WHERE co.ConventionOperTypeID = 'INC'
				AND c.SubscriberID = @SubscriberID
			GROUP BY O1.OperID
			)INC ON INC.OperID = CT.OperID
		WHERE c.SubscriberID = @SubscriberID
		GROUP BY O.OperTypeID,O.OperID  ,INC.INC
		)V




		INSERT INTO #tbConv (ConventionNo,BenefNom,BenefPrenom,SubscriberID,BeneficiaryID)
		SELECT DISTINCT
			c.ConventionNo,
			hb.LastName,
			hb.FirstName,
			c.SubscriberID,
			c.BeneficiaryID
		FROM Mo_BankReturnLink RL
		JOIN Un_Oper oNSF on oNSF.OperID = RL.BankReturnCodeID
		JOIN Un_Oper o on o.OperID = RL.BankReturnSourceCodeID
		JOIN Un_Cotisation CT ON CT.OperID = O.OperID
		JOIN Un_Unit U ON U.UnitID = CT.UnitID
		JOIN Un_Convention C ON C.ConventionID = U.ConventionID
		JOIN Mo_Human HB on HB.HumanID = C.BeneficiaryID
		JOIN (
			SELECT MaxNSFDate = MAX(oNSF.OperDate)
			FROM Mo_BankReturnLink RL
			JOIN Un_Oper oNSF on oNSF.OperID = RL.BankReturnCodeID
			JOIN Un_Oper o on o.OperID = RL.BankReturnSourceCodeID
			JOIN Un_Cotisation CT ON CT.OperID = O.OperID
			JOIN Un_Unit U ON U.UnitID = CT.UnitID
			JOIN Un_Convention C ON C.ConventionID = U.ConventionID
			WHERE c.SubscriberID = @SubscriberID --C.ConventionNo = 'X-20170816030'
			)MAXNSF on MAXNSF.MaxNSFDate = oNSF.OperDate
		WHERE c.SubscriberID = @SubscriberID --C.ConventionNo = 'X-20170816030'


	SELECT distinct
		humanID = C.SubscriberID,
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
		
		P.OperTypeID,
		P.DatePrelevement,
		P.MontantPrelevement,
		P.NbPrelevement,
		P.NbConv,
		nbBenef = (select NB = COUNT(distinct BeneficiaryID) from #tbConv),
		
		noConv = (SELECT STUFF((    SELECT ', ' + t.ConventionNo + ' (' + h.FirstName + ')'  AS [text()]
                        FROM #tbConv t 
						JOIN dbo.Un_Convention c ON t.ConventionNo = c.ConventionNo 
						JOIN dbo.Mo_Human h	ON c.BeneficiaryID = h.HumanID  
						FOR XML PATH('')
                        ), 1, 2, '' )
					),
		PlanClassification = [dbo].[fnCONV_ObtenirDossierClient](c.SubscriberID,1) + '\' + replace(LEFT(CONVERT(VARCHAR, @today, 120), 10),'-','')
							+ case HS.langID when 'FRA' then '_le_arret_paiement' when 'ENU' then '_le_arret_paiement_ang' end
	FROM #tbConv t JOIN dbo.Un_Convention C on t.ConventionNo = C.ConventionNo
	JOIN dbo.Un_Subscriber S on C.SubscriberID = S.SubscriberID
	JOIN dbo.Mo_Human HS on S.SubscriberID = HS.HumanID
	join Mo_Sex sex ON sex.SexID = HS.SexID AND sex.LangID = HS.LangID
	join Mo_Adr ad on ad.AdrID = HS.AdrID
	JOIN dbo.Mo_Human HR on S.RepID = HR.HumanID
	JOIN #Prelevement P ON 1=1

END


