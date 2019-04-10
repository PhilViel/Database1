/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc.

Code du service		: psCONV_ObtenirInfosPublipostageRep
Nom du service		: Obtenir les raisons des changements de bénéficiaire 
But 				: Obtenir les informations nécessaires à l'outil de publipostage selon le représentant qui est connecté.
Facette				: CONV
Référence			: Noyau-CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				cLoginNameID				Identifiant unique de l’utilisateur selon « Mo_User ».

Exemple d’appel		:	exec [dbo].[psCONV_ObtenirInfosPublipostageRep]
						exec [dbo].[psCONV_ObtenirInfosPublipostageRep] 'ccossette'

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						Toutes les informations nécessaires au publipostege sur les conventions dont le représentant assigné
						au souscripteur est le représentant trouvé selon le paramètre reçu.

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2009-11-09		Pierre-Luc Simard					Création du service							
		2009-11-24		Pierre-Luc Simard					Conventions actives seulement (Statut <> FRM)
		2010-04-30		Pierre-Luc Simard					Modification des compte de cmeilleur et ibiron pour des tests en production
		2012-04-13		Donald Huppé						glpi 7404
		2013-10-30		Donald Huppé						Changer SDufour par VHirt

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_ObtenirInfosPublipostageRep] 
(
	@vcLogin_Utilisateur VARCHAR(85) = NULL  -- Login du représentant connecté 
)
AS
BEGIN
	DECLARE 
		@iRepID INTEGER,
		@vcNom_Utilisateur VARCHAR(85)
	
	IF ISNULL(@vcLogin_Utilisateur,'') = ''
	BEGIN
		SET @vcNom_Utilisateur = SUSER_SNAME()
		SET @vcNom_Utilisateur = SUBSTRING(@vcNom_Utilisateur,CHARINDEX('\',@vcNom_Utilisateur)+1,85)
	END
	ELSE
	BEGIN
		SET @vcNom_Utilisateur = @vcLogin_Utilisateur
	END

	-- Tests effectués par Charles Meilleur au nom de Pascal Gilbert
	IF @vcNom_Utilisateur = 'cmeilleur'
	BEGIN
		SET @vcNom_Utilisateur = 'pgilbert2'
	END
	-- Tests effectués par Isabelle Biron au nom de Marie-Eve Nicolas
	IF @vcNom_Utilisateur = 'ibiron'
	BEGIN
		SET @vcNom_Utilisateur = 'pgilbert2'
	END

	-- Tests effectués par Vanessa Hirt au nom de Pascal Gilgert
	IF @vcNom_Utilisateur = 'vhirt'
	BEGIN
		SET @vcNom_Utilisateur = 'pgilbert2'
	END
	
	SELECT @iRepID = R.RepID
	FROM Un_Rep R
	JOIN Mo_User U ON U.UserID = R.RepID 
	WHERE U.LoginnameID = @vcNom_Utilisateur 
	
	-- Applique le filtre des états de conventions.
	CREATE TABLE #tConventionState (
		ConventionID INTEGER PRIMARY KEY,
		ConventionStateID CHAR(3),
		ConventionStateName VARCHAR(75))

	INSERT INTO #tConventionState
		SELECT 
			V.ConventionID,
			CCS.ConventionStateID,
			CS.ConventionStateName
		FROM ( -- Retourne le plus grand ID pour la plus grande date de début d'un état par convention
			SELECT 		
				T.ConventionID,
				ConventionConventionStateID = MAX(CCS.ConventionConventionStateID)
			FROM (-- Retourne la plus grande date de début d'un état par convention
				SELECT 
					CS.ConventionID,
					MaxDate = MAX(CS.StartDate)
				FROM Un_ConventionConventionState CS
				JOIN dbo.Un_Convention C ON C.ConventionID = CS.ConventionID
				JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
				WHERE CS.StartDate <= GETDATE() -- État à la date de fin de la période
					AND S.RepID = @iRepID
				GROUP BY CS.ConventionID
				) T
			JOIN Un_ConventionConventionState CCS ON T.ConventionID = CCS.ConventionID AND T.MaxDate = CCS.StartDate -- Retrouve l'état correspondant à la plus grande date par convention
			GROUP BY T.ConventionID
			) V
		JOIN Un_ConventionConventionState CCS ON V.ConventionConventionStateID = CCS.ConventionConventionStateID
		JOIN Un_ConventionState CS ON CS.ConventionStateID = CCS.ConventionStateID
		WHERE CCS.ConventionStateID <> 'FRM' -- Convention active (Non résiliée et n'ayant pas toutes ses bourses)
		/*WHERE CCS.ConventionStateID = 'REE' -- L'état REEE
				OR CCS.ConventionStateID = 'FRM' -- Fermé compte comme REE
				OR CCS.ConventionStateID = 'TRA' -- Transitoire
				OR CCS.ConventionStateID = 'PRP' -- En proposition
		*/
		
	SELECT 
		C.ConventionNo, 
		C.ConventionID,
		C.SubscriberID,
		C.BeneficiaryID,
		--C.tiRelationshipTypeID,
		RT.vcRelationshipType,
		--CS.ConventionStateID,
		CS.ConventionStateName,
		T.Transfert, 
		P.PlanDesc, 
		T.Dvigueur, 
		T.DSignature,
		T.Nb_Unit, 
		--NbPaiementAns = T.MAXDePmtByYearID, 
		--T.Nb_Paiement, 
		--T.MntSouscrit, 
		--T.MntDepot, 
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
		RRepCode = R.RepCode, 
		RLastName = HR.LastName , 
		RFirstName = HR.FirstName , 
		RRepID = R.RepID,
		RAddress = RAdr.Address,
		RCity = RAdr.City, 
		RStateName = RAdr.StateName, 
		RCountryID = RAdr.CountryID,
		RZipCode = RAdr.ZipCode,
		RPhone1 = RAdr.Phone1,
		RPhone2 = RAdr.Phone2,
		RSexID = HR.SexID , 
		RLangName = CASE RLang.LangName WHEN 'English' THEN 'Anglais' ELSE ISNULL(RLang.LangName, 'Unknown') END,
		REMail = RAdr.EMail,
		DRepCode = D.RepCode, 
		DLastName = HD.LastName , 
		DFirstName = HD.FirstName , 
		DBossID = D.RepID
	FROM dbo.Un_Convention C 
	JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID
	JOIN dbo.Un_Beneficiary B ON C.BeneficiaryID = B.BeneficiaryID
	JOIN dbo.Mo_Human HS ON S.SubscriberID = HS.HumanID
	JOIN dbo.Mo_Human HB ON B.BeneficiaryID = HB.HumanID
	JOIN dbo.Mo_Adr SAdr ON HS.AdrID = SAdr.AdrID 
	JOIN dbo.Mo_Adr BAdr ON BAdr.AdrID = HB.AdrID
	JOIN Un_Plan P ON C.PlanID = P.PlanID
	JOIN Un_Rep R ON S.RepID = R.RepID 
	JOIN dbo.Mo_Human HR ON R.RepID = HR.HumanID
	JOIN dbo.Mo_Adr RAdr ON RAdr.AdrID = HR.AdrID
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
		) T ON C.ConventionID = T.ConventionID
	LEFT JOIN Mo_Lang SLang ON HS.LangID = SLang.LangID
	LEFT JOIN Mo_Lang BLang ON HB.LangID = BLang.LangID 
	LEFT JOIN Mo_Lang RLang ON HR.LangID = RLang.LangID 
	JOIN #tConventionState CS ON CS.ConventionID = C.ConventionID
	LEFT JOIN (
		SELECT
			RB.RepID,
			BossID = MAX(BossID) -- au cas ou il y a 2 boss avec le même %.  alors on prend l'id le + haut. ex : repid = 497171
		FROM Un_RepBossHist RB
		JOIN (
			SELECT
				RepID,
				RepBossPct = MAX(RepBossPct)
			FROM 
				Un_RepBossHist RB
			WHERE 
				RepRoleID = 'DIR'
				AND StartDate IS NOT NULL
				AND (StartDate <= GETDATE())
				AND (EndDate IS NULL OR EndDate >= GETDATE())
			GROUP BY
				  RepID
			) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
		  WHERE RB.RepRoleID = 'DIR'
				AND RB.StartDate IS NOT NULL
				AND (RB.StartDate <= GETDATE())
				AND (RB.EndDate IS NULL OR RB.EndDate >= GETDATE())
		  GROUP BY
				RB.RepID
		) RD ON RD.RepID = R.RepID
	LEFT JOIN Un_Rep D ON D.RepID = RD.BossID
	LEFT JOIN dbo.Mo_Human HD ON HD.HumanID = D.RepID
	LEFT JOIN Un_RelationshipType RT ON RT.tiRelationshipTypeID = C.tiRelationshipTypeID 
	ORDER BY 
		HR.LastName, 
		HR.FirstName, 
		HS.LastName, 
		HS.FirstName, 
		C.ConventionNo

	DROP TABLE #tConventionState

END


