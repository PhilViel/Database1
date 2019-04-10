/****************************************************************************************************
Copyrights (c) 2011 Gestion Universitas inc.

Code du service		: psCONV_RapportLettreRetardAvisAnnuel
Nom du service		: Générer la lettre d'avis de retard annuel
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXECUTE psCONV_RapportLettreRetardAvisAnnuel 'u-20030618034'

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2013-06-27		Donald Huppé						Création du service	 ( à partir de SL_UN_SearchConventionWithVariance )	
		2013-09-25		Maxime Martel						Ajout du plan de classification	
		2013-11-26		Donald Huppé						Enlever 3 clause where qui bloque inutilement la production de la lettre
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettreRetardAvisAnnuel] 
(
	@cConventionno varchar(15) --Filtre sur un numéro de convention

)
AS
BEGIN

	DECLARE 
		@Today DATETIME,
		@OpenDays INTEGER,
		@dateExec datetime
		
	set @dateExec = GETDATE()

	SET @OpenDays = 0

	SELECT 
		@OpenDays = DaysAfterToTreat+DaysAddForNextTreatment
	FROM Un_AutomaticDepositTreatmentCfg
	WHERE DATEPART(dw, GETDATE()) = TreatmentDay

	SET @Today = dbo.FN_CRQ_DateNoTime(GETDATE())

	SELECT   
		c.ConventionNo,
		c.SubscriberID, 
		Langue = hs.LangID,
		AppelLong = sex.LongSexName,
		AppelCourt = sex.ShortSexName,
		SouscPrenom = hs.FirstName,
		SouscNom = hs.LastName,
		SouscAdresse = a.Address,
		SouscVille = a.City,
		SouscCodePostal = dbo.fn_Mo_FormatZIP( a.ZipCode,a.countryID),
		SouscProvince = a.StateName,
		SouscPays = a.CountryID,
		BenefPrenom = hb.FirstName,
		Ecart =  -1* ( SUM(T.RealCotisation) + SUM(T.RealFee) - SUM(T.TheoricCotisation)),
		PlanClassification = [dbo].[fnCONV_ObtenirDossierClient](c.subscriberID,1) + '\' + replace(LEFT(CONVERT(VARCHAR, @dateExec, 120), 10),'-','') + '_le_ret_ann'
		
	FROM dbo.Un_Convention C  
	JOIN dbo.Mo_Human hs ON c.SubscriberID = hs.HumanID
	join Mo_Sex sex ON sex.SexID = hs.SexID AND sex.LangID = hs.LangID
	JOIN dbo.Mo_Human hb ON c.BeneficiaryID = hb.HumanID
	JOIN dbo.Mo_Adr a ON hs.AdrID = a.AdrID
	JOIN (  
		SELECT   
			U.ConventionID,  
			RealCotisation = ISNULL(Ct.Cotisation,0),
			RealFee = ISNULL(Ct.Fee,0),
			TheoricCotisation = 
				CASE 
					WHEN ISNULL(U.PmtEndConnectID,0) > 0 THEN ISNULL(Ct.Cotisation,0) + ISNULL(Ct.Fee,0)
					WHEN C.PmtTypeID = 'AUT' THEN 
						dbo.fn_Un_EstimatedCotisationANDFee(
													U.InForceDate, 
													DATEADD(DAY, 
															@OpenDays, 
															/*@Today*/CAST( CAST(YEAR(getdate()) as varchar(4)) + '-'+ CAST(month(dbo.fn_Un_LastDepositDate(U.inforcedate,C.FirstPmtDate,m.PmtQty,m.PmtByYearID)) as varchar(4))  + '-'+ CAST(day(dbo.fn_Un_LastDepositDate(U.inforcedate,C.FirstPmtDate,m.PmtQty,m.PmtByYearID)) as varchar(4)) as datetime)
															), 
													DAY(C.FirstPmtDate), 
													U.UnitQty, 
													M.PmtRate, 
													M.PmtByYearID, 
													M.PmtQty, 
													U.InForceDate)
				ELSE
					dbo.fn_Un_EstimatedCotisationANDFee(
													U.InForceDate,
													/*@Today*/CAST( CAST(YEAR(getdate()) as varchar(4)) + '-'+ CAST(month(dbo.fn_Un_LastDepositDate(U.inforcedate,C.FirstPmtDate,m.PmtQty,m.PmtByYearID)) as varchar(4))  + '-'+ CAST(day(dbo.fn_Un_LastDepositDate(U.inforcedate,C.FirstPmtDate,m.PmtQty,m.PmtByYearID)) as varchar(4)) as datetime), 
													DAY(C.FirstPmtDate), 
													U.UnitQty, 
													M.PmtRate, 
													M.PmtByYearID, 
													M.PmtQty, 
													U.InForceDate)
				END,
			TheoricFee = 
				CASE 
					WHEN ISNULL(U.PmtEndConnectID,0) > 0 THEN ISNULL(Ct.Fee,0)
					WHEN C.PmtTypeID = 'AUT' THEN 
						dbo.fn_Un_EstimatedFee(dbo.fn_Un_EstimatedCotisationANDFee(
														U.InForceDate, 
														DATEADD(DAY, 
																@OpenDays, 
																/*@Today*/CAST( CAST(YEAR(getdate()) as varchar(4)) + '-'+ CAST(month(dbo.fn_Un_LastDepositDate(U.inforcedate,C.FirstPmtDate,m.PmtQty,m.PmtByYearID)) as varchar(4))  + '-'+ CAST(day(dbo.fn_Un_LastDepositDate(U.inforcedate,C.FirstPmtDate,m.PmtQty,m.PmtByYearID)) as varchar(4)) as datetime)
																), 
														DAY(C.FirstPmtDate), 
														U.UnitQty, 
														M.PmtRate, 
														M.PmtByYearID, 
														M.PmtQty, 
														U.InForceDate), 
												U.UnitQty, 
												M.FeeSplitByUnit, 
												M.FeeByUnit)
				ELSE
					dbo.fn_Un_EstimatedFee(dbo.fn_Un_EstimatedCotisationANDFee(
														U.InForceDate, 
														/*@Today*/CAST( CAST(YEAR(getdate()) as varchar(4)) + '-'+ CAST(month(dbo.fn_Un_LastDepositDate(U.inforcedate,C.FirstPmtDate,m.PmtQty,m.PmtByYearID)) as varchar(4))  + '-'+ CAST(day(dbo.fn_Un_LastDepositDate(U.inforcedate,C.FirstPmtDate,m.PmtQty,m.PmtByYearID)) as varchar(4)) as datetime), 
														DAY(C.FirstPmtDate), 
														U.UnitQty, 
														M.PmtRate, 
														M.PmtByYearID, 
														M.PmtQty, 
														U.InForceDate), 
												U.UnitQty, 
												M.FeeSplitByUnit, 
												M.FeeByUnit)
				END,
			Deposit = ROUND(U.UnitQty * M.PmtRate,2),						
			U.UnitQty, 
			M.PmtRate, 
			Bi.BenefInsurRate, 
			M.SubscriberInsuranceRate,
			H.HalfSubscriberInsuranceRate, 
			St.StateTaxPct,
			U.InForceDate,
			EnDateDu = CAST( CAST(YEAR(getdate()) as varchar(4)) + '-'+ CAST(month(dbo.fn_Un_LastDepositDate(U.inforcedate,C.FirstPmtDate,m.PmtQty,m.PmtByYearID)) as varchar(4))  + '-'+ CAST(day(dbo.fn_Un_LastDepositDate(U.inforcedate,C.FirstPmtDate,m.PmtQty,m.PmtByYearID)) as varchar(4)) as datetime)
		FROM dbo.Un_Convention C  
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
		JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
		JOIN Un_Modal M ON M.ModalID = U.ModalID
		LEFT JOIN Mo_State St ON St.StateID = S.StateID
		LEFT JOIN Un_BenefInsur Bi ON Bi.BenefInsurID = U.BenefInsurID
		LEFT JOIN Un_HalfSubscriberInsurance H ON H.ModalID = M.ModalID
		LEFT JOIN (  
			SELECT   
				U.UnitID,  
				Cotisation = SUM(Ct.Cotisation),  
				Fee = SUM(Ct.Fee)
			FROM dbo.Un_Unit U  
			JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
			JOIN Un_Oper O ON O.OperID = Ct.OperID
			LEFT JOIN Un_OperBankFile OBF ON OBF.OperID = O.OperID
			WHERE O.OperTypeID <> 'CPA'
				OR OBF.OperID IS NOT NULL
				OR O.OperDate <= GETDATE()
			GROUP BY U.UnitID  
			) Ct ON Ct.UnitID = U.UnitID
		WHERE C.ConventionNo = @cConventionno
			-------------------- 2013-11-26 ------------------------
			--AND ISNULL(U.TerminatedDate,0) <= 0
			--AND ISNULL(U.IntReimbDate,0) <= 0
			--AND dbo.FN_UN_EstimatedNumberOfDeposit(U.InForceDate, @Today, DAY(C.FirstPmtDate), M.PmtByYearID, M.PmtQty, U.InForceDate) < M.PmtQty	
			--------------------------------------------------------
		) T ON T.ConventionID = C.ConventionID
	GROUP BY 
		hs.LangID,
		c.ConventionNo,
		sex.LongSexName,
		sex.ShortSexName,
		hs.FirstName,
		hs.LastName,
		a.Address,
		a.City,
		dbo.fn_Mo_FormatZIP( a.ZipCode,a.countryID),
		a.StateName,
		a.CountryID,
		hb.FirstName,
		c.SubscriberID
		
END


