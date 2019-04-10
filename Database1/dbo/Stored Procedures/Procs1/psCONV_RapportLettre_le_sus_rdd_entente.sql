/****************************************************************************************************
Copyrights (c) 2011 Gestion Universitas inc.

Code du service		: psCONV_RapportLettre_le_sus_rdd_entente
Nom du service		: Générer la lettre d'Entente-Report de dépôts
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	
			EXEC psCONV_RapportLettre_le_sus_rdd_entente 'U-20051223010, U-20080416007, U-20080416008'
						
drop procedure psCONV_RapportLettre_le_sus_rdd_entente

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2014-07-17		Maxime Martel						Création du service	
		2014-08-13		Maxime Martel						Ajustement intérêts
		2017-09-26		Donald Huppé						jira ti-9424 : correction pour aller chercher les INC (intérêt) : 
															Faire un join sur OperID au lieu de OperDate
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettre_le_sus_rdd_entente] @cConventionno varchar(max)
AS
BEGIN
	DECLARE
		@today datetime,
		@nbConv integer,
		@nbDate integer,
		@repID int,
		@finRep date,
		@nbSous integer,
		@humanID integer,
		@nbBenef integer,
		@nbRow integer
	
	SET @today = GETDATE()
	SET @cConventionno = UPPER(LTRIM(RTRIM(ISNULL(@cConventionno,''))))
	
	CREATE TABLE #tbConv (
		ConvNo varchar(15) PRIMARY KEY,
		BenefNom varchar(50),
		BenefPrenom varchar(50),
		SousID integer,
		BenefID integer)

	BEGIN TRANSACTION

		INSERT INTO #tbConv (ConvNo,BenefNom,BenefPrenom,SousID,BenefID)
			SELECT t.val, B.LastName, B.FirstName, C.SubscriberID, C.BeneficiaryID
			FROM fn_Mo_StringTable(@cConventionno) t
			JOIN dbo.Un_Convention C on t.val = C.ConventionNo
			JOIN dbo.Mo_Human B on C.BeneficiaryID = B.HumanID
			
		select @nbRow = @@ROWCOUNT
		select @nbConv = COUNT(*) from fn_Mo_StringTable(@cConventionno)
		select @nbSous = COUNT(distinct t.SousID) from #tbConv t
		select @nbBenef = COUNT(distinct t.BenefID) from #tbConv t
		select top 1 @humanID = t.SousID from #tbConv t
		
	IF @nbRow <> @nbConv or @nbSous > 1
	BEGIN
		ROLLBACK TRANSACTION
		SET @humanID = 0
	END
	ELSE
		COMMIT TRANSACTION
	
	set @repID = (select RepID FROM dbo.Un_Subscriber where SubscriberID = @humanID)
	set @finRep = (select r.BusinessEnd from un_rep r where RepID = @repID)
	
	--si rep inactif repid = directeur
	if @finRep < getdate()
	begin
	set @repID =
		(SELECT
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
				AND RB.RepID = @repID
		  GROUP BY
				RB.RepID
				)
	end	
	
	SELECT 
		o.OperDate,
		ct.Cotisation,
		ct.Fee,
		ct.BenefInsur,
		ct.SubscInsur,
		ct.TaxOnInsur,
		C.ConventionNo,
		interest = t,
		H.FirstName,
		H.LastName into #CPAPostDate
	FROM dbo.Un_Convention C 
		JOIN dbo.Un_Unit U on C.ConventionID = U.ConventionID
		JOIN Un_Cotisation Ct on u.UnitID = Ct.UnitID 
		JOIN Un_Oper O on O.OperID = ct.OperID
		JOIN dbo.Mo_Human H on C.BeneficiaryID = H.HumanID
		LEFT JOIN  (
				select o.ConventionID, t =  sum(O.ConventionOperAmount ), OP.OperDate, OP.OperID
				from 
					Un_ConventionOper O
					JOIN dbo.Un_Convention c1 on o.ConventionID = c1.ConventionID
					join Un_Oper OP on OP.OperID = O.OperID
				where 
					ConventionOperTypeID = 'INC' 
					and c1.SubscriberID = @humanID
				group by o.ConventionID, OperDate, OP.OperID
				)inc  on c.ConventionID = inc.ConventionID and O.OperID = inc.OperID  --O.OperDate = inc.OperDate --jira ti-9424
	WHERE c.SubscriberID = @humanID
		AND ct.EffectDate > GETDATE()
		AND OperTypeID = 'CPA'
		AND C.PmtTypeID = 'AUT'

	select sum(MontantAuto) as montant, day(U.FirstPmtDate) as jour into #CPAMontant
	from (
		SELECT
			MontantAuto = ROUND((U.UnitQty * ISNULL(M.PmtRate,0)),2)
			+ ROUND(ISNULL(BI.BenefInsurRate,0),2)
			+
				CASE U.WantSubscriberInsurance
					WHEN 0 THEN 0
				ELSE
					ROUND((1 * ISNULL(M.SubscriberInsuranceRate,0)),2) +
					ROUND(((U.UnitQty-1) * ISNULL(HSI.HalfSubscriberInsuranceRate,ISNULL(M.SubscriberInsuranceRate,0))),2)
				END
			+
				CASE U.WantSubscriberInsurance
					WHEN 0 THEN ROUND(((ISNULL(BI.BenefInsurRate,0) * ISNULL(St.StateTaxPct,0)) + 0.0049),2)
				ELSE 
					ROUND((((ISNULL(BI.BenefInsurRate,0) +
					(1 * ISNULL(M.SubscriberInsuranceRate,0)) +
					((U.UnitQty-1) * ISNULL(HSI.HalfSubscriberInsuranceRate,ISNULL(M.SubscriberInsuranceRate,0)))) *
					ISNULL(St.StateTaxPct,0)) + 0.0049),2)
				END,
			S.SubscriberID,
			C.firstPmtDate,
			C.ConventionNo
			FROM dbo.Un_Convention C
			JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
			JOIN Un_Modal M ON M.ModalID = U.ModalID
			LEFT JOIN Un_HalfSubscriberInsurance HSI ON HSI.ModalID = M.ModalID
			JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
			LEFT JOIN Mo_State St ON St.StateID = S.StateID
			LEFT JOIN Un_BenefInsur BI ON BI.BenefInsurID = U.BenefInsurID
			WHERE  
			 (ISNULL(U.TerminatedDate,0) <= 0) AND 
			 (ISNULL(U.IntReimbDate,0) <= 0)AND 
			  (U.ActivationConnectID > 0)
			  AND C.PmtTypeID = 'AUT'
			  AND M.PmtByYearID = 12
			  AND U.PmtEndConnectID IS NULL
			  AND C.SubscriberID = @humanID
			  GROUP BY 
				C.ConventionNo,
				C.FirstPmtDate,
				S.SubscriberID,
				U.WantSubscriberInsurance, 
				M.PmtQty,
				U.UnitQty, 
				M.PmtRate, 
				M.PmtByYearID, 
				BI.BenefInsurRate, 
				St.StateTaxPct, 
				M.SubscriberInsuranceRate,
				HSI.HalfSubscriberInsuranceRate
				) U
	group by
		day(U.FirstPmtDate)
		
	--select @nbConv = count(distinct conventionNo) from #CPAPostDate
	select @nbDate = COUNT(distinct OperDate) from #CPAPostDate

	SELECT distinct
		nbDate = @nbDate,
		humanID = C.SubscriberID,
		Address = a.vcNom_Rue,
		City = a.vcVille,
		ZipCode = dbo.fn_Mo_FormatZIP( a.vcCodePostal,A.cId_Pays),
		StateName = a.vcProvince,
		nomSous = HS.LastName,
		prenomSous = HS.FirstName,
		HS.LangID,
		appelLong = sex.LongSexName,
		appelCourt = sex.ShortSexName,
		HS.SexID,
		nomRep = HR.firstName + ' ' + HR.lastName,
		sexRep = HR.SexID,
		nbConv = @nbConv,
		noConv = (SELECT STUFF((    SELECT ', ' + t.ConvNo + ' (' + t.BenefPrenom + ')' AS [text()]
                        FROM #tbConv t
						FOR XML PATH('')
                        ), 1, 2, '' ))
					,
		PlanClassification = [dbo].[fnCONV_ObtenirDossierClient](c.SubscriberID,1) + '\' + replace(LEFT(CONVERT(VARCHAR, @today, 120), 10),'-','')
							+ case HS.langID when 'FRA' then '_le_sus_rdd_entente' when 'ENU' then '_le_sus_rdd_entente_ang' end,
		montantPostDate = sum(t.Cotisation + t.BenefInsur + t.Fee + t.SubscInsur + t.TaxOnInsur + isnull(t.interest,0)),
		t.OperDate,
		Montant = isnull(CM.Montant,0)
	FROM #CPAPostDate t JOIN dbo.Un_Convention C on t.ConventionNo = C.ConventionNo
	JOIN dbo.Un_Subscriber S on C.SubscriberID = S.SubscriberID
	JOIN dbo.Mo_Human HS on S.SubscriberID = HS.HumanID
	join Mo_Sex sex ON sex.SexID = HS.SexID AND sex.LangID = HS.LangID
	join dbo.fntGENE_ObtenirAdresseEnDate(@humanID,1,GETDATE(),1) A on A.iID_Source = HS.HumanID
	JOIN dbo.Mo_Human HR on  HR.HumanID = @repID
	left join #CPAMontant CM on CM.jour = day(t.OperDate) 
	group by t.OperDate, C.subscriberId, a.vcNom_Rue, a.vcVille, a.vcCodePostal, a.cId_Pays, a.vcProvince,
	HS.LastName, HS.FirstName, HS.LangID,sex.LongSexName, sex.ShortSexName, HS.SexID, HR.firstName, HR.lastName,
	HR.SexID, CM.montant
	ORDER BY t.OperDate
END


