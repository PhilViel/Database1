/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                : SL_UN_Subscriber
Description        : Procédure retournant l'information au dossier d'un souscripteur.
Valeurs de retours : Dataset de données

Exemple d'appel		:	EXECUTE dbo.SL_UN_Subscriber 601617

Note               :		ADX0001067	BR	2004-08-27	Bruno Lapointe			Migration
							ADX0001457	BR	2005-06-07	Bruno Lapointe			Correction bug du capital assuré qui ne retournait 
																				pas 0, si le résultat du select était null.
							ADX0000826	IA	2006-03-14	Bruno Lapointe			Adaptation des souscripteurs pour PCEE 4.3
							ADX0001241	IA	2007-04-11	Alain Quirion			Ajout des champs Spouse, Contact1, Contact2, Contact1Phone, Contact2Phone
											2008-05-13	Pierre-Luc Simard		Ajout du code du représentant et du mot Inactif au prénom des représentants lorsqu'ils ont une date de fin de contrat
											2008-09-15  Radu Trandafir			Ajout du champ PaysOrigine 
																				Ajout du champ PreferenceSuivi
																				Ajout de la table tblCONV_ProfilSouscripteur
											2008-10-02	Patrick Robitaille		Ajout du champ vcNEQ
											2009-02-12  Patrick Robitaille		Ajout du champ vcNIP dans la table Mo_Human
											2009-06-16	Patrick Robitaille		Ajout des champs bSouscripteur_Accepte_Publipostage
																				et bSouscripteur_Desire_Releve_Elect
											2009-12-18	Jean-François Gauthier	Ajout des champs liés au profil de souscripteur
											2010-01-05	Jean-François Gauthier	Modification des champs liés au profil souscripteur
											2011-04-08	Corentin Menthonnex		2011-12 : ajout des champs suivants aux informations souscripteur
																					- bRapport_Annuel_Direction
																					- bEtats_Financiers_Annuels
																					- vcOccupation
																					- vcEmployeur
																					- tiNbAnneesService
											2011-06-23	Corentin Menthonnex		2011-12 : ajout des champs suivants aux informations souscripteur
																					- bEtats_Financiers_Semestriels
											2011-10-24	Christian Chénard		Modification de la table reliée aux colonnes iID_Identite_Souscripteur et vcIdentiteVerifieeDescription (de tblCONV_ProfilSouscripteur à Un_Subscriber)
											2011-11-01	Christian Chénard		Ajout des champs iID_Estimation_Cout_Etudes et iID_Estimation_Valeur_Nette_Menage
											2011-11-02	Christian Chénard		Ajout du champ bAutorisation_Resiliation
											2012-05-11	Donald Huppé			GLPI 7562 : ajout de bConsentement
																							bSouscripteur_Desire_Releve_Elect retourne l'inverse de bConsentement
											2012-07-17	Eric Michaud			Ajout des champs vcDossierSouscripteur
											2012-09-14	Donald Huppé			Ajout de iID_Tolerance_Risque
											2014-02-20	Pierre-Luc Simard	Utilisation du champ bReleve_Papier au lieu de bConsenement et bSouscripteur_Desire_Releve_Elect
											2014-09-12	Pierre-Luc Simard	Récupérer uniquement le dernier profil souscripteur
                                            2017-12-05  Pierre-Luc Simard   Ne plus valider la table Un_RepBusinessBonusCfg
											
											exec SL_UN_Subscriber 575993
											exec SL_UN_Subscriber 575993
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_Subscriber] (
	@SubscriberID INTEGER) -- Identifiant unique du souscripteur
AS
BEGIN

	DECLARE 
		@TotalCapitalInsured MONEY,
		@Today DATETIME

	SET @Today = GetDate()
	SET @TotalCapitalInsured = 0
	
	SELECT 
		@TotalCapitalInsured = ISNULL(SubscribAmount,0) - ISNULL(AmountToDate,0) 
	FROM (-- Retourne le total des montants versés par souscripteur                                                                     
		SELECT 
			C.SubscriberID, 
			SubscribAmount = SUM(ROUND(M.PmtRate*U.UnitQty,2) * PmtQty)
		FROM dbo.Un_Convention C               
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
		JOIN Un_Modal M ON M.ModalID = U.ModalID                                                
		WHERE C.SubscriberID = @SubscriberID
		  AND U.WantSubscriberInsurance <> 0
		  AND M.SubscriberInsuranceRate > 0
		GROUP BY C.SubscriberID 
		) V1                                                                   
   LEFT JOIN (-- Retourne les cotisations versées jusqu'à présent par souscripteurs
		SELECT 
			C.SubscriberID,
			AmountToDate = SUM(Co.Cotisation + Co.Fee)
		FROM dbo.Un_Convention C
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
		JOIN Un_Cotisation Co ON Co.UnitID = U.UnitID
		JOIN Un_Modal M ON M.ModalID = U.ModalID
		WHERE C.SubscriberID = @SubscriberID
		  AND U.WantSubscriberInsurance <> 0
		  AND M.SubscriberInsuranceRate > 0
		GROUP BY C.SubscriberID
		) V2 ON V1.SubscriberID = V2.SubscriberID

	-- Retourne les valeurs nécessaire à TUnSubscriber (objet du souscripteur)
	SELECT
		S.RepID,
		S.StateID,
		ScholarshipLevelID = ISNULL(S.ScholarshipLevelID, '') ,
		AnnualIncome = ISNULL(S.AnnualIncome, 0),
		S.SemiAnnualStatement,
		tiCESPState, -- État du souscripteur au niveau des pré-validations. (0 = Rien ne passe et 1 = La SCEE passe)
		/*--Ligne remplacée par celle ci-dessous pour ajouter le mot inactif lorsqu'il y a une date de fin de contrat
		RepName = 
			CASE 
				WHEN HR.HumanID IS NULL THEN '' 
			ELSE ISNULL(HR.LastName,'') + ', ' + ISNULL(HR.FirstName,'')
			END,*/		
		RepName = CASE WHEN REP.BusinessEnd IS NULL THEN 
				CASE WHEN HR.HumanID IS NULL THEN '' ELSE ISNULL(HR.LastName,'') + ', ' + ISNULL(HR.FirstName,'') + ' (' + ISNULL(REP.Repcode,'') + ')' END
				ELSE CASE WHEN HR.HumanID IS NULL THEN '' ELSE ISNULL(HR.LastName,'') + ', ' + ISNULL(HR.FirstName,'') + ' (' + ISNULL(REP.Repcode,'') + ')' + ' (Inactif)' END 
				END,
		FirstName = ISNULL(H.FirstName,''),
		OrigName = ISNULL(H.OrigName,''),		
		LastName = ISNULL(H.LastName,''),
		BirthDate = dbo.FN_CRQ_IsDateNull(H.BirthDate),
		DeathDate = dbo.FN_CRQ_IsDateNull(H.DeathDate),
		SexID = ISNULL(H.SexID,'U'),
		LangID = ISNULL(H.LangID,'U') ,
		CivilID = ISNULL(H.CivilID,'U') ,
		SocialNumber = ISNULL(H.SocialNumber,'') ,
		ResidID = ISNULL(H.ResidID,'UNK') ,
		H.DriverLicenseNo,
		H.WebSite,
		H.CompanyName,
		H.CourtesyTitle,
		H.UsingSocialNumber,
		H.SharePersonalInfo,
		H.MarketingMaterial,
		H.IsCompany,
		vcNIP = ISNULL(H.vcNIP, ''),
		SourceID = A.AdrID,
		A.AdrTypeID,
		A.InForce,
		A.Address,
		A.City,
		A.StateName,
		A.CountryID,
		A.ZipCode,
		Phone1 = dbo.FN_CRQ_FormatPhoneNo(A.Phone1, A.CountryID),
		Phone2 = dbo.FN_CRQ_FormatPhoneNo(A.Phone2, A.CountryID),
		Fax = dbo.FN_CRQ_FormatPhoneNo(A.Fax, A.CountryID),
		Mobile = dbo.FN_CRQ_FormatPhoneNo(A.Mobile, A.CountryID),
		WattLine = dbo.FN_CRQ_FormatPhoneNo(A.WattLine, A.CountryID),
		OtherTel = dbo.FN_CRQ_FormatPhoneNo(A.OtherTel, A.CountryID),
		Pager = dbo.FN_CRQ_FormatPhoneNo(A.Pager, A.CountryID),
		A.EMail,
		vcOccupation = H.vcOccupation,				-- 2011-04-08 : + 2011-12 - CM
		vcEmployeur = H.vcEmployeur,				-- 2011-04-08 : + 2011-12 - CM
		tiNbAnneesService = H.tiNbAnneesService,	-- 2011-04-08 : + 2011-12 - CM
		ResidCountryName = R.CountryName,
		ResidCountryTaxPct = R.CountryTaxPct,
		C.CountryName,
		C.CountryTaxPct,
		St.StateCode,
		St.StateTaxPct,
		TotalCapitalInsured = @TotalCapitalInsured,
		BirthLangID = ISNULL(WorldLanguageCodeID,''),
		BirthLangName = ISNULL(WorldLanguage,''),
		S.AddressLost,
		DirName = CASE ISNULL(SDIR.BossID,0) WHEN 0 THEN '' ELSE HSDIR.LastName + ', ' + HSDIR.FirstName END,
		Spouse = ISNULL(S.Spouse,''),
		Contact1 = ISNULL(S.Contact1,''),
		Contact2 = ISNULL(S.Contact2,''),
		Contact1Phone = ISNULL(S.Contact1Phone,''),
		Contact2Phone = ISNULL(S.Contact2Phone,''),
		PaysOrigine = ISNULL(Corg.CountryName, ''), --Pays d'origine
		PreferenceSuiviID = ISNULL(S.iID_Preference_Suivi, 0), --Preference suivi
		NoPersonnesaCharge=ISNULL(PS.tiNB_Personnes_A_Charge,0), --Ajout de la table tblCONV_ProfilSouscripteur
		ConnaisancePlacementID=ISNULL(PS.iID_Connaissance_Placements,0),
		ToleranceRisqueID=ISNULL(PS.iID_Tolerance_Risque,0),
		RevenuFamilialID=ISNULL(PS.iID_Revenu_Familial,0),
		DepassementBaremeID=ISNULL(PS.iID_Depassement_Bareme,0),
		IdentiteSouscripteurID=ISNULL(S.iID_Identite_Souscripteur,0),
		ObjectifInvestissementLigne1ID=ISNULL(PS.iID_ObjectifInvestissementLigne1,0),
		ObjectifInvestissementLigne2ID=ISNULL(PS.iID_ObjectifInvestissementLigne2,0),
		ObjectifInvestissementLigne3ID=ISNULL(PS.iID_ObjectifInvestissementLigne3,0),
		IdentiteDescription=ISNULL(S.vcIdentiteVerifieeDescription,''),
		AutorisationResiliation=ISNULL(S.bAutorisation_Resiliation,0),
		DepassementJustification=ISNULL(PS.vcDepassementbaremeJustification,''),
		vcNEQ = H.StateCompanyNo,
		bSouscripteur_Desire_Releve_Elect = ISNULL(S.bReleve_Papier,0), 
		bSouscripteur_Accepte_Publipostage = H.bHumain_Accepte_Publipostage,
		bRapport_Annuel_Direction = S.bRapport_Annuel_Direction,			-- 2011-04-08 : + 2011-12 - CM
		bEtats_Financiers_Annuels = S.bEtats_Financiers_Annuels,			-- 2011-04-08 : + 2011-12 - CM
		bEtats_Financiers_Semestriels = S.bEtats_Financiers_Semestriels,	-- 2011-06-23 : + 2011-12 - CM
		PS.iIDNiveauEtudeMere,				-- 2010-01-05 : JFG :Modification des champs du profil souscripteur
		PS.iIDNiveauEtudePere,
		PS.iIDNiveauEtudeTuteur,
		PS.iIDImportanceEtude,
		PS.iIDEpargneEtudeEnCours,
		PS.iIDContributionFinanciereParent,
		EstimationCoutEtudesID = ISNULL(PS.iID_Estimation_Cout_Etudes, 0),
		EstimationValeurNetteMenageID = ISNULL(PS.iID_Estimation_Valeur_Nette_Menage, 0)	
	/*	PS.iIDNiveauEtudeParent,				-- 2009-12-18 : JFG :Ajout des champs suivants
		PS.iIDImportanceEtudeMetier,
		PS.iIDImportanceEtudeCollege,
		PS.iIDImportanceEtudeUniversite,
		PS.iIDEpargneEtudeEnCours,
		PS.iIDContributionFinanciereParent*/
		,bConsentement_Souscripteur = CASE WHEN ISNULL(PAS.iEtat, 0) = 5 THEN CAST('1' AS bit) ELSE cast('0' AS bit) END 
		,vcDossierSouscripteur = GPS.vcValeur_Parametre +'\'+ dbo.fn_Mo_FormatStringWithoutAccent(substring(LTRIM(RTRIM(h.lastname)),1,1)) + '\' + replace(replace(replace(dbo.fn_Mo_FormatStringWithoutAccent(upper(replace(LTRIM(RTRIM(h.lastname)),' ','_')) + '_' + replace(LTRIM(RTRIM(h.firstname)),' ','_') + '_' + cast(h.humanid as varchar(20))),'.',''),',',''),'&','Et')									
	FROM dbo.Un_Subscriber S
	JOIN dbo.Mo_Human H ON H.HumanID = S.SubscriberID
    LEFT JOIN tblCONV_ProfilSouscripteur PS ON PS.iID_Souscripteur = S.SubscriberID AND PS.DateProfilInvestisseur = (
		SELECT	
			MAX(PSM.DateProfilInvestisseur)
		FROM tblCONV_ProfilSouscripteur PSM
		WHERE PSM.iID_Souscripteur = PS.iID_Souscripteur
			AND PSM.DateProfilInvestisseur <= GETDATE()
		)
	--LEFT JOIN dbo.Mo_Human HR ON HR.HumanID = S.RepID
	LEFT JOIN Un_Rep REP ON REP.RepID = S.RepID
	LEFT JOIN dbo.Mo_Human HR ON HR.HumanID = REP.RepID
	LEFT JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
	LEFT JOIN Mo_Country R ON R.CountryID = H.ResidID
	LEFT JOIN Mo_Country C ON C.CountryID = A.CountryID
	LEFT JOIN Mo_State St ON St.StateID = S.StateID
	LEFT JOIN CRQ_WorldLang W ON S.BirthLangID = W.WorldLanguageCodeID
	LEFT JOIN tblGENE_TypesParametre GTPS on GTPS.vcCode_Type_Parametre = 'REPERTOIRE_DOSSIER_CLIENT_SOUSCRIPTEUR'
	LEFT JOIN tblGENE_Parametres GPS ON GTPS.iID_Type_Parametre = GPS.iID_Type_Parametre
	LEFT JOIN (
		SELECT
			M.SubscriberID,
			BossID = MAX(RBH.BossID)
		FROM (
			SELECT
				S.SubscriberID,
				S.RepID,
				RepBossPct = MAX(RBH.RepBossPct)
			FROM dbo.Un_Subscriber S
			JOIN Un_RepBossHist RBH ON (RBH.RepID = S.RepID) AND (@Today >= RBH.StartDate) AND (@Today <= RBH.EndDate OR RBH.EndDate IS NULL) AND (RBH.RepRoleID = 'DIR')
			JOIN Un_RepLevel BRL ON (BRL.RepRoleID = RBH.RepRoleID)
			JOIN Un_RepLevelHist BRLH ON (BRLH.RepLevelID = BRL.RepLevelID) AND (BRLH.RepID = RBH.BossID) AND (@Today >= BRLH.StartDate)  AND (@Today <= BRLH.EndDate  OR BRLH.EndDate IS NULL)
			--JOIN Un_RepBusinessBonusCfg RBB ON (RBB.RepRoleID = RBH.RepRoleID) AND (@Today >= RBB.StartDate) AND (@Today <= RBB.EndDate OR RBB.EndDate IS NULL)
			WHERE S.SubscriberID = @SubscriberID
			GROUP BY S.SubscriberID, S.RepID
			) M
		JOIN dbo.Un_Subscriber S ON (S.SubscriberID = M.SubscriberID)
		JOIN Un_RepBossHist RBH ON (RBH.RepID = M.RepID) AND (RBH.RepBossPct = M.RepBossPct) AND (@Today >= RBH.StartDate) AND (@Today <= RBH.EndDate OR RBH.EndDate IS NULL) AND (RBH.RepRoleID = 'DIR')
		WHERE S.SubscriberID = @SubscriberID
		GROUP BY M.SubscriberID
		) SDIR ON (SDIR.SubscriberID = S.SubscriberID)
	LEFT JOIN dbo.Mo_Human HSDIR ON (HSDIR.HumanID = SDIR.BossID)
	LEFT JOIN Mo_Country Corg ON Corg.CountryID = H.cID_Pays_Origine --Pays d'origine
	LEFT JOIN tblGENE_PortailAuthentification PAS ON PAS.iUserId = S.SubscriberID 
	WHERE S.SubscriberID = @SubscriberID

END


