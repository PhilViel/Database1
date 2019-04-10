/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 : RP_UN_ConventionByRep
Description         : Procédure stockée du rapport : Détail des souscripteurs du représentant
Valeurs de retours  : >0  :	Tout à fonctionné
                      <=0 :	Erreur SQL
								-1	: Erreur lors de la sauvegarde de l'ajout
								-2 : Cette année de qualification est déjà en vigueur pour cette convention
Note                :						2004-05-12	Dominic Létourneau	Création de la procedure pour CRQ-INT-00003
								ADX0000309	BR	2004-06-03 	Bruno Lapointe			Correction
								ADX0000631	IA	2005-01-03	Bruno Lapointe			Ajout du paramètre @SubscriberIDs pour filtre
									supplémentaire.
								ADX0001285	BR	2005-02-15	Bruno Lapointe			Optimisation.
												2008-12-10  Patrick Robitaille  	Afficher Oui/Non au lieu des NAS s'ils sont valides ou non
																					et ajouter les adresses de courriel
												2009-08-13	Donald Huppé	Inscrire "*** adresse perdue ***" dans adresse, tel et email du souscripteur et bébéficiaire si AddressLost = 1
												2010-10-15	Donald Huppé	Ajout d'un champ "Actif" indiquant si le sousc est actif,
																			Modification de la clause where pour sortir aussi les données de sousc inactif quand on passe une liste de subscriberID
exec RP_UN_ConventionByRep 1, 559035, '', '2011-03-04','2011-03-04'
exec RP_UN_ConventionByRep 1, 559035, '', NULL,NULL
exec RP_UN_ConventionByRep 1, 559035, '', '1900-01-01','1900-01-01'
exec RP_UN_ConventionByRep 1, 0, '308239'

exec RP_UN_ConventionByRep 1, 0, '399934'
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_ConventionByRep_NewGLPI5376] (	
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@RepID INTEGER = 0, -- Limiter les résultats selon un représentant, 0 pour tous
	@SubscriberIDs VARCHAR(8000), -- IDs de souscripteur du représentant à afficher séparés par des virgules. '' = tous
	@DtDateTransfertFrom datetime = '1900-01-01',
	@DtDateTransfertTo datetime = '1900-01-01'
	)
AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT

	SET @dtBegin = GETDATE()

	SET @SubscriberIDs = LTRIM(RTRIM(ISNULL(@SubscriberIDs,'')))

	CREATE TABLE #tbSubscriber (
		SubscriberID INTEGER PRIMARY KEY)

	INSERT INTO #tbSubscriber (SubscriberID)
		SELECT Val
		FROM dbo.FN_CRQ_IntegerTable(@SubscriberIDs)

	CREATE TABLE #ListeSouscripteurTransfereDeRep(
		OldRepID INT,
		NewRepID INT,
		SubscriberID INT,
		logtime DATETIME,
		userID INT
		)

	IF isnull(@DtDateTransfertFrom,'1900-01-01') <> '1900-01-01' AND @SubscriberIDs = ''
	BEGIN

		set @DtDateTransfertTo = isnull(@DtDateTransfertTo,@DtDateTransfertFrom)
		INSERT #ListeSouscripteurTransfereDeRep
		EXEC psGENE_ObtenirListeSouscripteurTransfereDeRep @DtDateTransfertFrom,@DtDateTransfertTo , 0, 0, @RepID

		INSERT INTO #tbSubscriber
		SELECT SubscriberID FROM #ListeSouscripteurTransfereDeRep

		SET @SubscriberIDs = 'CHAINE NON VIDE POUR QUE LA CONDITION PASSE'

	END

	-- Retourne les données aux rapport des conventions par représentant 
	SELECT  
		C.ConventionNo, 
		T.Transfert, 
		P.PlanDesc, 
		T.Dvigueur, 
		T.DSignature,
		T.Nb_Unit, 
		NbPaiementAns = T.MAXDePmtByYearID, 
		T.Nb_Paiement, 
		T.MntSouscrit, 
		T.MntDepot, 
		SLastName = HS.LastName, 
		SFirstName = HS.FirstName , 
		SAddress = case when S.AddressLost = 0 then SAdr.Address else '*** adresse perdue ***' end, 
		SCity = case when S.AddressLost = 0 then SAdr.City else '' end, 
		SStateName = case when S.AddressLost = 0 then SAdr.StateName else '' end , 
		SCountryID = case when S.AddressLost = 0 then SAdr.CountryID else '' end ,
		SZipCode = case when S.AddressLost = 0 then SAdr.ZipCode else '' end ,
		SPhone1 = case when S.AddressLost = 0 then SAdr.Phone1 else '' end ,
		SPhone2 = case when S.AddressLost = 0 then SAdr.Phone2 else '' end ,
		SSexID = HS.SexID , 
		SLangName = CASE SLang.LangName WHEN 'English' THEN 'Anglais' ELSE ISNULL(SLang.LangName, 'Unknown') END, 
		SBirthDate = HS.BirthDate , 
		SSocialNumber = CASE
							WHEN dbo.FN_CRI_CheckSin(ISNULL(HS.SocialNumber, HS.IsCompany), 0) = 1 THEN
								'Oui'
							ELSE
								'Non'
						END,
		SEMail = case when S.AddressLost = 0 then SAdr.EMail else '' end ,
		BLastName = HB.LastName , 
		BFirstName = HB.FirstName , 
		BAddress = case when B.bAddressLost = 0 then BAdr.Address else '*** adresse perdue ***' end, 
		BCity = case when B.bAddressLost = 0 then BAdr.City else '' end, 
		BStateName = case when B.bAddressLost = 0 then BAdr.StateName else '' end , 
		BCountryID = case when B.bAddressLost = 0 then BAdr.CountryID else '' end ,
		BZipCode = case when B.bAddressLost = 0 then BAdr.ZipCode else '' end ,
		BPhone1 = case when B.bAddressLost = 0 then BAdr.Phone1 else '' end ,
		BPhone2 = case when B.bAddressLost = 0 then BAdr.Phone2 else '' end ,
		BSexID = HB.SexID , 
		BLangName = CASE BLang.LangName WHEN 'English' THEN 'Anglais' ELSE ISNULL(BLang.LangName, 'Unknown') END , 
		BBirthDate = HB.BirthDate , 
		BSocialNumber = CASE
							WHEN dbo.FN_CRI_CheckSin(ISNULL(HB.SocialNumber, ''), 0) = 1 THEN
								'Oui'
							ELSE
								'Non'
						END,
		BEMail = case when B.bAddressLost = 0 then BAdr.EMail else '' end ,
		R.RepCode, 
		RLastName = HR.LastName , 
		RFirstName = HR.FirstName , 
		R.RepID
		,ACTIF = CASE WHEN ACTIF.SUBSCRIBERID IS NOT NULL THEN 1 ELSE 0 END
		,DateTransfert = st.logtime
	FROM dbo.Un_Convention C 
	JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID
	LEFT JOIN #tbSubscriber SR ON SR.SubscriberID = S.SubscriberID
	JOIN dbo.Un_Beneficiary B ON C.BeneficiaryID = B.BeneficiaryID
	JOIN dbo.Mo_Human HS ON S.SubscriberID = HS.HumanID
	JOIN dbo.Mo_Human HB ON B.BeneficiaryID = HB.HumanID
	JOIN dbo.Mo_Adr SAdr ON HS.AdrID = SAdr.AdrID 
	JOIN dbo.Mo_Adr BAdr ON BAdr.AdrID = HB.AdrID
	JOIN Un_Plan P ON C.PlanID = P.PlanID
	JOIN Un_Rep R ON S.RepID = R.RepID 
	JOIN dbo.Mo_Human HR ON R.RepID = HR.HumanID
	LEFT JOIN #ListeSouscripteurTransfereDeRep st ON st.subscriberid = C.SubscriberID
	JOIN (
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
			DSignature = MIN(SignatureDate), 
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
			FROM dbo.Un_Unit U 
			JOIN Un_Modal M ON U.ModalID = M.ModalID
			LEFT JOIN Un_Cotisation CT ON U.UnitID = CT.UnitID
			JOIN Un_Plan P ON M.PlanID = P.PlanID
			JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
			LEFT JOIN #tbSubscriber SR ON SR.SubscriberID = S.SubscriberID
			LEFT JOIN Mo_State St ON St.StateID = S.StateID
			LEFT JOIN Un_BenefInsur BI ON BI.BenefInsurID = U.BenefInsurID
			WHERE (@SubscriberIDs <> '' OR ( @SubscriberIDs = '' and U.TerminatedDate IS NULL))
				AND S.RepID = ISNULL(NULLIF(@RepID,0), S.RepID)
				AND 	(	@SubscriberIDs = ''
						OR	SR.SubscriberID IS NOT NULL
						)
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
		) T ON C.ConventionID = T.ConventionID
	LEFT JOIN (
		SELECT -- Sousc avec au moins une convention ouverte
			C2.SUBSCRIBERID
		FROM 
			UN_CONVENTION C2
			JOIN dbo.Un_Unit U2 ON C2.CONVENTIONID = U2.CONVENTIONID
			JOIN dbo.Un_Subscriber S2 ON C2.SUBSCRIBERID = S2.SUBSCRIBERID
		WHERE
			U2.TERMINATEDDATE IS NULL
		GROUP BY 
			C2.SUBSCRIBERID
				)ACTIF ON ACTIF.SUBSCRIBERID = S.SUBSCRIBERID
	LEFT JOIN Mo_Lang SLang ON HS.LangID = SLang.LangID
	LEFT JOIN Mo_Lang BLang ON HB.LangID = BLang.LangID 
	WHERE	R.RepID = ISNULL(NULLIF(@RepID,0), R.RepID)
		AND 	(	@SubscriberIDs = ''
				OR	SR.SubscriberID IS NOT NULL
				)
	ORDER BY 
		HR.LastName, 
		HR.FirstName, 
		HS.LastName, 
		HS.FirstName, 
		C.ConventionNo

	SET @dtEnd = GETDATE()
	SELECT @siTraceReport = siTraceReport FROM Un_Def

	IF DATEDIFF(SECOND, @dtBegin, @dtEnd) > @siTraceReport
		-- Insère une trace de l'ewxécution si la durée de celle-ci a dépassé le temps minimum défini dans Un_Def.siTraceReport.
		INSERT INTO Un_Trace (
				ConnectID, -- ID de connexion de l’usager
				iType, -- Type de trace (1 = recherche, 2 = rapport)
				fDuration, -- Temps d’exécution de la procédure
				dtStart, -- Date et heure du début de l’exécution.
				dtEnd, -- Date et heure de la fin de l’exécution.
				vcDescription, -- Description de l’exécution (en texte)
				vcStoredProcedure, -- Nom de la procédure stockée
				vcExecutionString ) -- Ligne d’exécution (inclus les paramètres)
			SELECT
				@ConnectID,
				2,
				DATEDIFF(MILLISECOND, @dtBegin, @dtEnd)/1000,
				@dtBegin,
				@dtEnd,
				'Détail des souscripteurs du représentant',
				'RP_UN_ConventionByRep',
				'EXECUTE RP_UN_ConventionByRep @ConnectID = '+CAST(@ConnectID AS VARCHAR)+
					', @RepID = '+CAST(@RepID AS VARCHAR)+
					', @SubscriberIDs = '+@SubscriberIDs
END

/*  Sequence de test - par: PLS - 09-05-2008
	exec [dbo].[RP_UN_ConventionByRep] 	
	@ConnectID = 1, -- ID de connexion de l'usager
	@RepID = 149653, -- Limiter les résultats selon un représentant, 0 pour tous, 149653 pour Claude Cossette 
	@SubscriberIDs = '' -- IDs de souscripteur du représentant à afficher séparés par des virgules. '' = tous
*/


