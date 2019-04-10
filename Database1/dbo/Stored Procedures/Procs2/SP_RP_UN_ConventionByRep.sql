/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 : SP_RP_UN_ConventionByRep
Description         : Procedure stockée du rapport des conventions par représentant
Valeurs de retours  : >0  :	Tout à fonctionné
                      <=0 :	Erreur SQL
								-1	: Erreur lors de la sauvegarde de l'ajout
								-2 : Cette année de qualification est déjà en vigueur pour cette convention
Note                :						2004-05-12	Dominic Létourneau	Création de la procedure pour CRQ-INT-00003
								ADX0000309	BR	2004-06-03 	Bruno Lapointe			Correction
								ADX0000631	IA	2005-01-03	Bruno Lapointe			Ajout du paramètre @SubscriberIDs pour filtre
									supplémentaire.
								ADX0001285	BR	2005-02-15	Bruno Lapointe			Optimisation.
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_RP_UN_ConventionByRep] (	
	@RepID INTEGER = 0, -- Limiter les résultats selon un représentant, 0 pour tous
	@SubscriberIDs VARCHAR(8000)) -- IDs de souscripteur du représentant à afficher séparés par des virgules. '' = tous
AS
BEGIN
	SET @SubscriberIDs = LTRIM(RTRIM(ISNULL(@SubscriberIDs,'')))

	DECLARE @tbSubscriber TABLE (
		SubscriberID INTEGER PRIMARY KEY)

	IF ISNULL(@SubscriberIDs,'') = ''
		INSERT INTO @tbSubscriber
			SELECT SubscriberID
			FROM dbo.Un_Subscriber 
			WHERE RepID = ISNULL(NULLIF(@RepID,0), RepID)
	ELSE
		INSERT INTO @tbSubscriber
			SELECT Val
			FROM dbo.FN_CRQ_IntegerTable(@SubscriberIDs) tS
			JOIN dbo.Un_Subscriber S ON S.SubscriberID = tS.Val
			WHERE S.RepID = ISNULL(NULLIF(@RepID,0), S.RepID)

	DECLARE @tConventionByRep TABLE (
		ConventionID INTEGER PRIMARY KEY,
		MntSouscrit MONEY NOT NULL,
		Transfert TINYINT NOT NULL,
		DSignature DATETIME NOT NULL,
		Dvigueur DATETIME NOT NULL,
		Nb_Unit MONEY NOT NULL,
		Nb_Paiement INTEGER NOT NULL,
		MntDepot MONEY NOT NULL,
		MAXDePmtByYearID INTEGER NOT NULL )
		
	INSERT INTO @tConventionByRep
		SELECT 
			ConventionID, 
			MntSouscrit = SUM(	
				CASE 
					WHEN PlanTypeID = 'IND' THEN SommeCotisation 
					WHEN PmtEndConnectID IS NULL THEN (SommeFee + SommeCotisation)
					WHEN PmtQty = 1 THEN (SommeFee + SommeCotisation)
				ELSE (PmtQty * ROUND((UnitQty * PmtRate),2))
				END), 
			Transfert = MAX(
				CASE 
					WHEN UN.RepID <> UN.SRepID THEN 1
				ELSE 0
				END), 
			DSignature = MAX(SignatureDate), 
			Dvigueur = MAX(InForceDate),
			Nb_Unit = SUM(UnitQty), 
			Nb_Paiement = MAX(PmtQty), 
			MntDepot = SUM(
				CASE 
					WHEN PlanTypeID = 'IND' THEN SommeCotisation 
					WHEN PmtQty = 1 AND (PmtEndConnectID IS NULL) THEN (SommeFee + SommeCotisation)
				ELSE ROUND(UnitQty * PmtRate,2) + dbo.FN_CRQ_TaxRounding((SubscrInsur + BenefInsur) * (1+StateTaxPct))
				END), 
			MAXDePmtByYearID = MAX(PmtByYearID)  
		FROM (
			-- RETROUVE LES UNITÉS DE CONVENTION 
			SELECT 
				U.ConventionID, 
				P.PlanTypeID, 
				U.SignatureDate, 
				U.InForceDate, 
				U.RepID, 
				SRepID = S.RepID,
				U.PmtEndConnectID, 
				M.PmtQty, 
				M.PmtByYearID, 
				U.UnitQty, 
				M.PmtRate,
				StateTaxPct = ISNULL(St.StateTaxPct,0), 
				SommeFee = ISNULL(SUM(CT.Fee),0), 
				SommeCotisation = ISNULL(SUM(CT.Cotisation),0),
				SubscrInsur =
					CASE
						WHEN U.WantSubscriberInsurance = 0 THEN 0
					ELSE ROUND(U.UnitQty * M.SubscriberInsuranceRate,2)
					END,
				BenefInsur = ISNULL(BI.BenefInsurRate,0)
			FROM @tbSubscriber tS
			JOIN dbo.Un_Subscriber S ON tS.SubscriberID = S.SubscriberID 
			JOIN dbo.Un_Convention C ON S.SubscriberID = C.SubscriberID
			JOIN dbo.Un_Unit U ON C.ConventionID = U.ConventionID
			JOIN Un_Modal M ON U.ModalID = M.ModalID
			JOIN Un_Plan P ON M.PlanID = P.PlanID
			LEFT JOIN Un_Cotisation CT ON U.UnitID = CT.UnitID
			LEFT JOIN Mo_State St ON St.StateID = S.StateID
			LEFT JOIN Un_BenefInsur BI ON BI.BenefInsurID = U.BenefInsurID
			WHERE U.TerminatedDate IS NULL
			GROUP BY 
				U.ConventionID, 
				U.UnitID, 
				U.SignatureDate, 
				U.InForceDate, 
				U.RepID, 
				U.PmtEndConnectID, 
				U.WantSubscriberInsurance,
				U.UnitQty, 
				M.PmtQty, 
				M.PmtByYearID, 
				M.PmtRate,
				M.SubscriberInsuranceRate,
				P.PlanTypeID, 
				St.StateTaxPct, 
				S.RepID,
				BI.BenefInsurRate
			) UN
		GROUP BY UN.ConventionID
		ORDER BY UN.ConventionID

	-- Retourne les données aux rapport des conventions par représentant 
	SELECT  
		C.ConventionNo, 
		T.Transfert, 
		P.PlanDesc, 
		T.Dvigueur, 
		T.Nb_Unit, 
		NbPaiementAns = T.MAXDePmtByYearID, 
		T.Nb_Paiement, 
		T.MntSouscrit, 
		T.MntDepot, 
		SLastName = HS.LastName, 
		SFirstName = HS.FirstName , 
		SAddress = SAdr.Address, 
		SCity = SAdr.City, 
		SStateName = SAdr.StateName,
		SCountryID = SAdr.CountryID, 
		SZipCode = SAdr.ZipCode,
		SPhone1 = SAdr.Phone1,
		SPhone2 = SAdr.Phone2,
		SSexID = HS.SexID , 
		SLangName = CASE SLang.LangName WHEN 'English' THEN 'Anglais' ELSE ISNULL(SLang.LangName, 'Unknown') END, 
		SBirthDate = HS.BirthDate , 
		SSocialNumber = HS.SocialNumber , 
		BLastName = HB.LastName , 
		BFirstName = HB.FirstName , 
		BAddress = BAdr.Address, 
		BCity = BAdr.City, 
		BStateName = BAdr.StateName, 
		BCountryID = BAdr.CountryID,
		BZipCode = BAdr.ZipCode,
		BPhone1 = BAdr.Phone1,
		BPhone2 = BAdr.Phone2,
		BSexID = HB.SexID , 
		BLangName = CASE BLang.LangName WHEN 'English' THEN 'Anglais' ELSE ISNULL(BLang.LangName, 'Unknown') END , 
		BBirthDate = HB.BirthDate , 
		BSocialNumber = HB.SocialNumber , 
		R.RepCode, 
		RLastName = HR.LastName , 
		RFirstName = HR.FirstName , 
		R.RepID
	FROM @tConventionByRep T 
	JOIN dbo.Un_Convention C ON C.ConventionID = T.ConventionID 
	JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID
	JOIN dbo.Un_Beneficiary B ON C.BeneficiaryID = B.BeneficiaryID
	JOIN dbo.Mo_Human HS ON S.SubscriberID = HS.HumanID
	JOIN dbo.Mo_Human HB ON B.BeneficiaryID = HB.HumanID
	JOIN dbo.Mo_Adr SAdr ON HS.AdrID = SAdr.AdrID 
	JOIN dbo.Mo_Adr BAdr ON BAdr.AdrID = HB.AdrID
	JOIN Un_Plan P ON C.PlanID = P.PlanID
	JOIN Un_Rep R ON S.RepID = R.RepID 
	JOIN dbo.Mo_Human HR ON R.RepID = HR.HumanID
	LEFT JOIN Mo_Lang SLang ON HS.LangID = SLang.LangID
	LEFT JOIN Mo_Lang BLang ON HB.LangID = BLang.LangID 
	ORDER BY 
		HR.LastName, 
		HR.FirstName, 
		HS.LastName, 
		HS.FirstName, 
		C.ConventionNo

	-- FIN DES TRAITEMENTS 
	RETURN 0

END


