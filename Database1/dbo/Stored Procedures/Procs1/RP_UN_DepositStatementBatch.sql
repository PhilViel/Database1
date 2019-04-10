/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************   */

/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	RP_UN_DepositStatementBatch
Description         :	Rapport de fusion word des relevés de dépôts 
Valeurs de retours  :	Dataset de données	
Note                :					2004-05-26	Bruno Lapointe			Migration
										2004-05-31	Bruno Lapointe			Ne sort pas de relevés pour les souscripteurs dont l'adresse perdue. Point 10.8.7.1 (2.1) 
						ADX0000950	BR	2004-08-23	Bruno Lapointe			Correction de la valeur estimés des bourses.
						ADX0000967	BR	2004-08-23	Bruno Lapointe			Un template par plan.
						ADX0000993	BR	2004-08-25	Bruno Lapointe			Optimisation de la rapidité
						ADX0001046	BR	2004-08-30	Bruno Lapointe			Gestion des 3 décimal
						ADX0001117	BR	2004-10-28	Bruno Lapointe			Optimisation de la rapidité
						ADX0000589	IA	2004-11-19	Bruno Lapointe			Prendre la date de dernier dépôt pour contrat et relevés de dépôts inscrit par l'usager si pas vide.
						ADX0000670	IA	2005-03-14	Bruno Lapointe			Retourne la date de dernier dépôt pour relevés et contrats selon nouvelle formule.
						ADX0001774	UR	2006-03-15	Bruno Lapointe			Modifié les relevés de dépôts pour ajouter 3 champs (Épargne, Frais et Bourse projetée)
						ADX0001850	UR	2006-04-04	Bruno Lapointe			1. Pour les relevés de dépôts individuels : 
																			Le champ de fusion PSEFundsTotal (Total des fons disponibles pour les études postsecondaire) doit 
																			inclure la valeur du champ INMInterests (Intérêts accumulés) 
																			2. Pour les relevés de dépôts individuels : 
																			On doit utiliser l’année du 19ième anniversaire du bénéficiaire pour évaluer le coût des 
																			études au lieu de l’année de fin de régime. 
						ADX0000513	IA	2006-06-20	Bruno Lapointe			Plusieurs modifications. (12.099.01.17)
						ADX0001158	IA	2006-10-10	Alain Quirion			Modification : 	La date utilisée pour calculer les valeurs unitaires de chaque plan sera l’année la plus élevé pour 
																			laquelle des valeurs unitaires ont été saisies et non la date du jour.
																			Les champs de fusion « ThirdANDSecondLastYear » et « LastYear » seront modifiés pour 
																			retourner les années utilisées avec la nouvelle formule du calcul des bourses projetées. 
																			Par exemple quand les années utilisées au calcul seront 2006, 2005 et 2004 le champ de fusion « ThirdANDSecondLastYear » 
																			retournera « 2004, 2005 » et le champ « LastYear » retournera « 2006 ».
						ADX0001114	IA	2006-11-17	Alain Quirion			Utilisé la fonction FN_UN_EstimatedIntReimbDate avec paramètre IntReimbDateAjust.
						ADX0001235	IA	2007-02-14	Alain Quirion			Utilisation de dtRegStartDate pour la date de début de régime
						ADX0002426	BR	2007-05-22	Alain Quirion			Modification : Un_CESP au lieu de Un_CESP900
						ADX0001357	IA	2007-06-04	Alain Quirion			Le champ capital remboursable (MntSouscrit) à l’échéance doit être égal à 0 si la source de vente du groupe d’unités est de type « Gagnant de concours ».
										2008-03-26	Pierre-Luc Simard		Coût des études différents lorsque le souscripteur habite au Nouveau-Brunswick
																			Nom du directeur et son téléphone lorsque le représentant est inactif
																			Format du téléphone selon le pays du représentant et non le pays du souscripteur
																			Note à ajouter pour le coût des études si la province n'est pas Nouveau-Brunswick (2 ans de Cégep)
																			Note à ajouter pour le coût des études si la province n'est pas Nouveau-Brunswick et Québec (au Québec)
																			L'année de qualification affichée où le coût des études ne peut pas être inférieur à l'année du relevé plus an an
																			Intérêts reçus d une autre institution enlevés des champs INMInterest (individuels) et ScholarshipProjection
																			Champs CityStateCPCountry1 et 2 ajoutés pour les villes de plus de 30 caractères
										2008-04-12	Jean-Jacques Levesque	Ajouter champ manquant NAS souscripteur.	
										2008-09-25	Josée Parent			Ne pas produire de DataSet pour les 
																			documents commandés
										2009-12-10	Jean-François Gauthier	Modification pour remplacer INT par IN+/IN-
										2009-12-17	Jean-François Gauthier	Intégration modif. Rémy
										2010-01-11	Donald Huppé			Ajout du plan 12
										2010-01-15	Jean-François Gauthier	Remplacement de fnOPER_ObtenirTypesOperationConvCategorie par fnOPER_ObtenirTypesOperationCategorie
										2010-08-17	Jean-François Gauthier	Modification car le champ StudyCostNB a été renommé StudyCostCA
                                        2017-09-27  Pierre-Luc Simard       Deprecated - Cette procédure n'est plus utilisée

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_DepositStatementBatch] (
	@ConnectID INTEGER, 		-- ID Unique de connexion de l'usager qui a commandé le calcul
	@PlanID INTEGER, 		-- ID du plan
	@Date DATETIME, 		-- Considère uniquement l'argent déposé dont la date d'opération est inférieure ou égal à cette date
	@RecordStart INTEGER, 		-- # du premier record du range
	@RecordEnd INTEGER, 		-- # du dernier record du range
	@OnlySemiAnnual INTEGER, 	-- True si il veut seulement les relevés semi-annuel
	@LangID CHAR(3), 		-- Langue des relevés. 'ALL' = Tous.
	@DocAction INTEGER) 		-- ID de l'action (0 = commander le document, 1 = imprimer, 2 = imprimer et créer un historique dans la gestion des documents
AS
BEGIN  
    
    SELECT 1/0
    /*
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT,
		@vcOPER_RENDEMENT_POSITIF_NEGATIF VARCHAR(200)

	SET @vcOPER_RENDEMENT_POSITIF_NEGATIF = [dbo].[fnOPER_ObtenirTypesOperationCategorie]('OPER_RENDEMENT_POSITIF_NEGATIF')

	SET @dtBegin = GETDATE()

	DECLARE 
		@DatePlus1 DATETIME,
		@Today DATETIME,
		@DocTypeID INTEGER,
		@Range VARCHAR(100),
		@Count INTEGER,
		@ThirdANDSecondLastYear CHAR(10),
		@LastYear CHAR(4),
		@UnitValue MONEY,
		@PlanTypeID CHAR(3),
		@MaxScholarShipYear INTEGER
	
	SET @DatePlus1 = @Date + 1
	
	SET @Today = GETDATE()

	SET @DocTypeID = 0

	-- Va chercher l'année la plus élevée pour laquelle des valeurs unitaires ont été saisies
	SELECT @MaxScholarShipYear = MIN(V.ScholarshipYear)-1
	FROM Un_PlanValues V
	JOIN Un_Plan P ON P.PlanID = V.PlanID
	WHERE UnitValue = 0
		AND P.PlanTypeID = 'COL'

	IF @MaxScholarShipYear IS NULL -- Aucune entrée à 0
	BEGIN
		SELECT @MaxScholarShipYear = MAX(V.ScholarshipYear)
		FROM Un_PlanValues V
		JOIN Un_Plan P ON P.PlanID = V.PlanID
		WHERE P.PlanTypeID = 'COL'
	END

	-- Utilise l'année la plus élevée pour laquelle des valeurs unitaires ont été saisies dans le calcul des année précédentes
	SET @ThirdANDSecondLastYear = CAST((@MaxScholarShipYear)-2 AS CHAR(4)) + ', ' + CAST((@MaxScholarShipYear)-1 AS CHAR(4))
	SET @LastYear = CAST((@MaxScholarShipYear) AS CHAR(4))

	-- Va chercher la valeur unitaire estimé des bourses selon ceux des dernières années
	SET @UnitValue = 0
	SELECT 
		@UnitValue = SUM(UnitValue)
	FROM Un_PlanValues
	WHERE PlanID = @PlanID
	  AND ScholarshipYear = @MaxScholarShipYear - (3 - ScholarshipNo)

	-- Va chercher le type de plan (Collectif='COL' ou Individuel='IND')
	SELECT 
		@PlanTypeID = PlanTypeID
	FROM Un_Plan
	WHERE PlanID = @PlanID

	-- Va chercher le bon type de document
	SELECT 
		@DocTypeID = DocTypeID
	FROM CRQ_DocType
	WHERE (DocTypeCode = 'ReleveDepIND' AND @PlanID = 4)
		OR (DocTypeCode = 'ReleveDepREE' AND @PlanID in (10,12))
		OR (DocTypeCode = 'ReleveDepSPB' AND @PlanID = 11)
		OR (DocTypeCode = 'ReleveDepUNI' AND @PlanID = 8)

	-- Va chercher les templates les plus récents et qui n'entrent pas en vigueur dans le futur
	CREATE TABLE #DocTemplate_DepStatement(
		LangID VARCHAR(3) PRIMARY KEY, 
		DocTemplateID INTEGER)

	INSERT INTO #DocTemplate_DepStatement
		SELECT 
			T.LangID,
			T.DocTemplateID
		FROM CRQ_DocTemplate T
		JOIN (
			SELECT 
				LangID,
				DocTypeID,
				DocTemplateTime = MAX(DocTemplateTime)
			FROM CRQ_DocTemplate
			WHERE DocTypeID = @DocTypeID
			  AND (DocTemplateTime < @Today)
			GROUP BY LangID, DocTypeID
			) V ON V.DocTypeID = T.DocTypeID AND V.DocTemplateTime = T.DocTemplateTime AND V.LangID = T.LangID

	CREATE TABLE #tUnitQty (
		UnitID INTEGER PRIMARY KEY,
		UnitQty MONEY NOT NULL,
		MntSouscrit MONEY NOT NULL,
		Cotisation MONEY NOT NULL,
		Fee MONEY NOT NULL,
		EstimatedIntReimbDate DATETIME NOT NULL,
		LastDepositDate DATETIME NOT NULL )

	-- Va chercher le nombre d'unités actuelle d'unités
	INSERT INTO #tUnitQty
		SELECT
			U.UnitID,
			U.UnitQty,
			0,
			SUM(Ct.Cotisation),
			SUM(Ct.Fee),
			0,
			0
		FROM dbo.Un_Unit U
		JOIN dbo.Un_Convention C ON C.ConventionID	= U.ConventionID
		JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
		JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
		JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		WHERE C.PlanID = @PlanID
			AND( HS.LangID = @LangID 
				OR 'ALL' = @LangID
				)
			AND( (S.SemiAnnualStatement <> 0) 
				OR @OnlySemiAnnual = 0
				) 
			AND S.AddressLost = 0
			AND ISNULL(U.TerminatedDate, @DatePlus1) >= @DatePlus1
			AND ISNULL(U.IntReimbDate, @DatePlus1) >= @DatePlus1
			AND O.OperDate < @DatePlus1
			AND U.InForceDate < @DatePlus1 -- Exclus les unités des groupes d'unités entrés en vigueur après la date du relevé
		GROUP BY U.UnitID, U.UnitQty 

	-- Additionne les unités résilié depuis la date du relevé pour obtenir le nombre d'unités à la date du relevé.
	UPDATE #tUnitQty
	SET UnitQty = #tUnitQty.UnitQty + V.UnitQty
	FROM #tUnitQty
	JOIN (
		SELECT 
			U.UnitID,
			UnitQty = SUM(UR.UnitQty)
		FROM #tUnitQty UQ
		JOIN dbo.Un_Unit U ON U.UnitID = UQ.UnitID
		JOIN Un_UnitReduction UR ON UR.UnitID = U.UnitID
		WHERE UR.ReductionDate >= @DatePlus1
		GROUP BY U.UnitID
		) V ON V.UnitID = #tUnitQty.UnitID

	UPDATE #tUnitQty
	SET 
		MntSouscrit = 
					CASE
						WHEN ISNULL(SS.bIsContestWinner,0) = 1 THEN 0
						WHEN P.PlanTypeID = 'IND' THEN #tUnitQty.Cotisation
						WHEN ISNULL(Co.ConnectStart, @DatePlus1) >= @DatePlus1 THEN 
							(ROUND(#tUnitQty.UnitQty * M.PmtRate,2) * M.PmtQty) + U.SubscribeAmountAjustment
						ELSE #tUnitQty.Cotisation + #tUnitQty.Fee + U.SubscribeAmountAjustment
					END,
		EstimatedIntReimbDate = dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, U.IntReimbDateAdjust),
		LastDepositDate =  	CASE 
								WHEN ISNULL(U.LastDepositForDoc,0) <= 0 THEN
									dbo.fn_Un_LastDepositDate(U.InForceDate, C.FirstPmtDate, M.PmtQTY, M.PmtByYearID)
								ELSE 
									U.LastDepositForDoc
							END
	FROM #tUnitQty
	JOIN dbo.Un_Unit U ON U.UnitID = #tUnitQty.UnitID
	JOIN Un_Modal M ON M.ModalID = U.ModalID
	JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
	JOIN Un_Plan P ON P.PlanID = C.PlanID
	LEFT JOIN Mo_Connect Co ON Co.ConnectID = U.PmtEndConnectID
	LEFT JOIN Un_SaleSource SS ON SS.SaleSourceID = U.SaleSourceID

	CREATE TABLE #tConvInForce (
		ConventionID INTEGER PRIMARY KEY,
		InForceDate DATETIME NOT NULL,
		UnitQty MONEY NOT NULL,
		MntSouscrit MONEY NOT NULL,
		Cotisation MONEY NOT NULL,
		Fee MONEY NOT NULL,
		EstimatedIntReimbDate DATETIME NOT NULL,
		LastDepositDate DATETIME NOT NULL )

	INSERT INTO #tConvInForce
		SELECT 
			U.ConventionID,
			InForceDate = MIN(U.InForceDate),
			UnitQty = SUM(UQ.UnitQty),
			MntSouscrit = SUM(UQ.MntSouscrit),
			Cotisation = SUM(UQ.Cotisation),
			Fee = SUM(UQ.Fee),
			EstimatedIntReimbDate = MAX(UQ.EstimatedIntReimbDate),
			LastDepositDate = MAX(UQ.LastDepositDate)
		FROM #tUnitQty UQ
		JOIN dbo.Un_Unit U ON U.UnitID = UQ.UnitID
		GROUP BY U.ConventionID

	DROP TABLE #tUnitQty

	-- Fait la liste des conventions qui n'étaient pas en proposition à la date du relevé demandé.
	CREATE TABLE #Convention(
		ConventionID INTEGER PRIMARY KEY,
		InForceDate DATETIME NOT NULL,
		YearQualif INTEGER NOT NULL,
		UnitQty MONEY NOT NULL,
		MntSouscrit MONEY NOT NULL,
		Cotisation MONEY NOT NULL,
		Fee MONEY NOT NULL,
		EstimatedIntReimbDate DATETIME NOT NULL,
		LastDepositDate DATETIME NOT NULL)

	IF EXISTS (
		SELECT *
		FROM Un_Plan
		WHERE PlanID = @PlanID
			AND PlanTypeID = 'IND'
		)
		-- Individuel
		INSERT INTO #Convention  
			SELECT DISTINCT 
				C.ConventionID,
				I.InForceDate,
				YearQualif = ISNULL(YEAR(HB.BirthDate)+19,C.YearQualif), -- Année de qualification de la convention
				I.UnitQty,
				I.MntSouscrit,
				I.Cotisation,
				I.Fee,
				I.EstimatedIntReimbDate,
				I.LastDepositDate
			FROM dbo.Un_Convention C
			JOIN #tConvInForce I ON I.ConventionID = C.ConventionID
			JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID
			WHERE ISNULL(C.dtRegStartDate, @DatePlus1)  < @DatePlus1
	ELSE
		-- Collectif
		INSERT INTO #Convention  
			SELECT DISTINCT 
				C.ConventionID,
				I.InForceDate,
				C.YearQualif,
				I.UnitQty,
				I.MntSouscrit,
				I.Cotisation,
				I.Fee,
				I.EstimatedIntReimbDate,
				I.LastDepositDate
			FROM dbo.Un_Convention C
			JOIN #tConvInForce I ON I.ConventionID = C.ConventionID
			WHERE ISNULL(C.dtRegStartDate, @DatePlus1)  < @DatePlus1

	DROP TABLE #tConvInForce

	-- L'année de qualification ne peut pas être antérieure à l'année du relevé plus un an 
	UPDATE #Convention
	SET YearQualif = YEAR(@Date) + 1
	WHERE YearQualif < YEAR(@Date) + 1

	-- Table temporaire qui contient les documents
	CREATE TABLE #DepositStatement(
		ConventionID INTEGER PRIMARY KEY,
		IdentityID INTEGER IDENTITY(1,1),
		DocTemplateID INTEGER,
		LangID VARCHAR(3),
		DepositStatementDate VARCHAR(75),
		LongSexName VARCHAR(75),
		ShortSexName VARCHAR(75),
		SubscriberFirstName VARCHAR(35),
		SubscriberLastName VARCHAR(50),
		Address VARCHAR(75),
		City VARCHAR(100),
		StateName VARCHAR(75),
		ZipCode VARCHAR(10),
		BeneficiaryFirstName VARCHAR(35),
		BeneficiaryLastName VARCHAR(50),
		SocialNumber VARCHAR(75),
		ConventionNo VARCHAR(75),
		YearQualif INTEGER,
		RepresentativeFirstName VARCHAR(35),
		RepresentativeLastName VARCHAR(50),
		RepPhone VARCHAR(27),
		UnitQty MONEY,
		InForceDate VARCHAR(75),
		LastDepositDate VARCHAR(75),
		CotisationFee VARCHAR(75),
		INMInterests VARCHAR(75),
		EstimatedIntReimbDate VARCHAR(75),
		MntSouscritMoney MONEY,
		MntSouscrit VARCHAR(75),
		Bourse VARCHAR(75),
		BourseANDMntSouscrit VARCHAR(75),
		StudyCost VARCHAR(75),
		ThirdANDSecondLastYear VARCHAR(10),
		LastYear VARCHAR(4),
		Saving VARCHAR(75),
		Fee VARCHAR(75),
		ScholarshipProjection VARCHAR(75),
		CESPTotal VARCHAR(75),
		PSEFundsTotal VARCHAR(75),
		SCEE VARCHAR(75), -- Solde du compte de subvention standard (20%).
		IntPCEE VARCHAR(75), -- La somme des comptes d’intérêt SCEE, d’intérêt SCEE+, d’intérêt BEC et d’intérêt PCEE provenant d’un transfert IN.
		IntTIN VARCHAR(75), -- La somme du solde des comptes d’intérêt sur capital provenant d’un transfert IN et d’intérêt sur l’intérêt sur capital provenant d’un transfert IN.
		SCEESupp VARCHAR(75), -- Solde du compte de SCEE+.
		BEC VARCHAR(75), -- Solde du compte de BEC.
		BourseVSStudyCost VARCHAR(75), -- Différence entre le total du fonds potentiellement disponibles pour les études et le coût estimé des études postsecondaires.  Le montant sera 0.00$ quand le coût estimé des études postsecondaires sera moins élevé que le total du fonds potentiellement disponibles pour les études.
		NoneResidentCountry VARCHAR(75), -- Nom du pays. Si le pays est le Canada alors le champ sera vide.
		StudyCostNoteNotNB VARCHAR(50), -- Note a ajouter pour le coût des études si la province n'est pas Nouveau-Brunswick
		StudyCostNoteNotNBQC VARCHAR(50), -- Note a ajouter pour le coût des études si la province n'est pas Nouveau-Brunswick ou Québec
		CityStateCPCountry1 VARCHAR(200), -- Si Ville > 30 caratères = Ville, province, code postal Sinon Ville 
		CityStateCPCountry2 VARCHAR(200), -- Si Ville > 30 caratères = Province, code postal Sinon Vide + Pays
		SSocialNumber VARCHAR(75)  -- NAS du Souscripteur. Absent avant le 12042008.
	)

	-- Insère les données initiales du relevés
	INSERT INTO #DepositStatement ( 
		ConventionID,
		DocTemplateID,
		LangID,
		DepositStatementDate,
		LongSexName,
		ShortSexName,
		SubscriberFirstName,
		SubscriberLastName,
		Address,
		City,
		StateName,
		ZipCode,
		BeneficiaryFirstName,
		BeneficiaryLastName,
		SocialNumber,
		ConventionNo,
		YearQualif,
		RepresentativeFirstName,
		RepresentativeLastName,
		RepPhone,
		UnitQty,
		InForceDate,
		LastDepositDate,
		CotisationFee,
		INMInterests,
		EstimatedIntReimbDate,
		MntSouscritMoney,
		MntSouscrit,
		Bourse,
		BourseANDMntSouscrit,
		StudyCost,
		ThirdANDSecondLastYear,
		LastYear,
		Saving,
		Fee,
		ScholarshipProjection,
		CESPTotal,
		PSEFundsTotal,
		SCEE, -- Solde du compte de subvention standard (20%).
		IntPCEE, -- La somme des comptes d’intérêt SCEE, d’intérêt SCEE+, d’intérêt BEC et d’intérêt PCEE provenant d’un transfert IN.
		IntTIN, -- La somme du solde des comptes d’intérêt sur capital provenant d’un transfert IN et d’intérêt sur l’intérêt sur capital provenant d’un transfert IN.
		SCEESupp, -- Solde du compte de SCEE+.
		BEC, -- Solde du compte de BEC.
		BourseVSStudyCost, -- Différence entre le total du fonds potentiellement disponibles pour les études et le coût estimé des études postsecondaires.  Le montant sera 0.00$ quand le coût estimé des études postsecondaires sera moins élevé que le total du fonds potentiellement disponibles pour les études.
		NoneResidentCountry, -- Nom du pays. Si le pays est le Canada alors le champ sera vide.
		StudyCostNoteNotNB, -- Note a ajouter pour le coût des études si la province n'est pas Nouveau-Brunswick
		StudyCostNoteNotNBQC, -- Note a ajouter pour le coût des études si la province n'est pas Nouveau-Brunswick ou Québec
		CityStateCPCountry1, -- Si Ville > 30 caratères = Ville, province, code postal Sinon Ville 
		CityStateCPCountry2, -- Si Ville > 30 caratères = Province, code postal Sinon Vide + Pays
		SSocialNumber)      -- Ajoute le NAS du SOuscripteur.
		SELECT 
			C.ConventionID, -- ID de la convention
			T.DocTemplateID, -- ID du template
			HS.LangID, -- Langue du souscripteur (utiliser pour déterminer la langue du document)
			DepositStatementDate = dbo.fn_mo_DateToLongDateStr(@Date, HS.LangID), -- Date du relevé de dépôt
			SX.LongSexName, -- Appel du souscripteur : 'Monsieur', 'Sir', 'Madame' et 'Madam' selon la langue et le sexe. 
			SX.ShortSexName, -- Appel abbrégé du souscripteur : 'M.', 'Mr.', 'Mme.' et 'Ms.' selon la langue et le sexe. 
			SubscriberFirstName = HS.FirstName, -- Prénom du souscripteur
			SubscriberLastName = HS.LastName, -- Nom du souscripteur
			SA.Address, -- Adresse (# civique et rue) du souscripteur
			SA.City, -- Ville du souscripteur
			SA.StateName, -- Province du souscripteur
			ZipCode = dbo.fn_Mo_FormatZIP(SA.ZipCode, SA.CountryID), -- Code postal du souscripteur
			BeneficiaryFirstName = HB.FirstName, -- Prénom du bénéficaire
			BeneficiaryLastName = HB.LastName, -- Nom du bénéficiaire
			SocialNumber = dbo.fn_Mo_FormatSIN(HB.SocialNumber, SA.CountryID), -- # assurance social
			C.ConventionNo, -- # convention	
			RC.YearQualif, -- Année de qualification de la convention
			RepresentativeFirstName = ISNULL(HR.FirstName,''), -- Prénom du représentant
			RepresentativeLastName = ISNULL(HR.LastName,''), -- Nom du représentant 
			RepPhone = dbo.fn_Mo_FormatPhoneNo(ISNULL(SR.Phone1,''), SA.CountryID), -- Téléphone du représentant
			RC.UnitQty, -- Nombre d'unités de la convention 
			InForceDate = dbo.fn_mo_DateToLongDateStr(RC.InForceDate, HS.LangID), -- Date de vigueur de la convention
			LastDepositDate = dbo.fn_mo_DateToLongDateStr(RC.LastDepositDate, HS.LangID), -- Date théoriqur du dernier dépôt
			CotisationFee = dbo.fn_Mo_MoneyToStr(RC.Cotisation + RC.Fee, HS.LangID,0),
			INMInterests = '', -- Intérêt sur capital additionné des intérêts sur capital provenant de transfert IN
			EstimatedIntReimbDate = dbo.fn_mo_DateToLongDateStr(RC.EstimatedIntReimbDate, HS.LangID), -- Date théorique du remboursement intégral
			MntSouscritMoney = RC.MntSouscrit, 
			MntSouscrit = dbo.fn_Mo_MoneyToStr(RC.MntSouscrit,HS.LangID,0), -- Montant souscrit de la convention
			Bourse = dbo.fn_Mo_MoneyToStr(@UnitValue * RC.UnitQty,HS.LangID,0), -- Bourse estimés selon le bourses versées lors des trois dernières années 
			BourseANDMntSouscrit = '', -- Bourse estimés selon le bourses versées lors des trois dernières années additionné du montant souscrit
			StudyCost = '', -- Valeur estimé du coûts des études selon une projection basé sur le coûts moyen des études actuelles.
			ThirdANDSecondLastYear = @ThirdANDSecondLastYear, -- Avant dernière année et avant avant dernière année
			LastYear = @LastYear, -- Année passée
			Saving = '',
			Fee = '',
			ScholarshipProjection = '',
			CESPTotal = '',
			PSEFundsTotal = '',
			SCEE = '', -- Solde du compte de subvention standard (20%).
			IntPCEE = '', -- La somme des comptes d’intérêt SCEE, d’intérêt SCEE+, d’intérêt BEC et d’intérêt PCEE provenant d’un transfert IN.
			IntTIN = '', -- La somme du solde des comptes d’intérêt sur capital provenant d’un transfert IN et d’intérêt sur l’intérêt sur capital provenant d’un transfert IN.
			SCEESupp = '', -- Solde du compte de SCEE+.
			BEC = '', -- Solde du compte de BEC.
			BourseVSStudyCost = '', -- Différence entre le total du fonds potentiellement disponibles pour les études et le coût estimé des études postsecondaires.  Le montant sera 0.00$ quand le coût estimé des études postsecondaires sera moins élevé que le total du fonds potentiellement disponibles pour les études.
			NoneResidentCountry =
				CASE 
					WHEN SA.CountryID = 'CAN' THEN ''
				ELSE SCo.CountryName
				END, -- Nom du pays. Si le pays est le Canada alors le champ sera vide.
			StudyCostNoteNotNB =
				CASE 
					WHEN (SA.StateName = 'N.-B.' OR SA.StateName = 'Nouveau-Brunswick') THEN ''
				ELSE CASE WHEN HS.LangID = 'ENU' THEN ' & 2 years of a technical program' ELSE ' pour 2 années de cégep, et' END
				END, -- Note a ajouter pour le coût des études si la province n'est pas Nouveau-Brunswick
			StudyCostNoteNotNBQC =
				CASE 
					WHEN (SA.StateName = 'N.-B.' OR SA.StateName = 'Nouveau-Brunswick') THEN CASE WHEN HS.LangID = 'ENU' THEN ' in the province of NB' ELSE ' au N.-B.' END
				ELSE CASE WHEN HS.LangID = 'ENU' THEN ' in the province of Quebec' ELSE ' au Québec' END
				END, -- Note a ajouter pour le coût des études si la province n'est pas Nouveau-Brunswick ou Québec
			CityStateCPCountry1 = 	
				CASE 
					WHEN LEN(ISNULL(SA.City,'')) + LEN(ISNULL(SA.StateName,'')) >= 40 THEN SA.City 
				ELSE ISNULL(SA.City,'') + CASE WHEN SA.StateName IS NOT NULL THEN ' (' + SA.StateName + ') ' ELSE '' END + ' ' + dbo.fn_Mo_FormatZIP(SA.ZipCode, SA.CountryID) 	
				END,
			CityStateCPCountry2 = 
				CASE 
					WHEN LEN(ISNULL(SA.City,'')) + LEN(ISNULL(SA.StateName,'')) >= 40 THEN CASE WHEN SA.StateName IS NOT NULL THEN '(' + SA.StateName + ')  ' ELSE '' END + ' ' + dbo.fn_Mo_FormatZIP(SA.ZipCode, SA.CountryID) + ' ' 	
				ELSE ''
				END + CASE WHEN SA.CountryID = 'CAN' THEN '' ELSE ISNULL(SCo.CountryName,'') END,
			SSocialNumber = dbo.fn_Mo_FormatSIN(HS.SocialNumber, SA.CountryID) -- # assurance social souscripteur 

		FROM #Convention RC
		JOIN dbo.Un_Convention C ON RC.ConventionID = C.ConventionID
		--------------------------------------------------------------
		--JOIN TGU_ConvRD ON TGU_ConvRD.ConventionNo = C.ConventionNo  --Utilisé lors des tests pour imprimer seulements les conventions inscrites dans la table TGU_ConvRD
		--------------------------------------------------------------
		JOIN Un_Plan P ON P.PlanID = C.PlanID
		JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
		JOIN dbo.Mo_Human HS ON HS.HumanID = S.SubscriberID
		JOIN Mo_Sex SX ON HS.LangID = SX.LangID AND HS.SexID = SX.SexID
		JOIN dbo.Mo_Adr SA ON SA.AdrID = HS.AdrID
		LEFT JOIN Mo_Country SCo ON SCo.CountryID = SA.CountryID
		JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID
		LEFT JOIN dbo.Mo_Human HR ON HR.HumanID = S.RepID
		LEFT JOIN dbo.Mo_Adr SR ON SR.AdrID = HR.AdrID
		JOIN #DocTemplate_DepStatement T ON T.LangID = HS.LangID
		ORDER BY 
			T.DocTemplateID,
			HS.LangID, 
			HS.LastName, 
			HS.FirstName, 
			SA.ZipCode, 
			SA.Address, 
			SA.City, 
			SA.StateName, 
			C.ConventionNo

	SELECT 
		@Count = COUNT(*) 
	FROM #DepositStatement

	-- Supprime les relevés qui ne sont pas dans le range demandé, pour ne pas faire des calculs inutiles.
	DELETE 
	FROM #DepositStatement
	WHERE	( IdentityID < @RecordStart 
			OR IdentityID > @RecordEnd
			)
		AND @RecordEnd <> 0
	
	-- Va chercher les données manquant pour les relevés restant.
	UPDATE #DepositStatement
	SET
		INMInterests = 
			CASE  
				WHEN @PlanTypeID = 'IND' THEN 
					dbo.fn_Mo_MoneyToStr(ISNULL(INM.INMInterests, 0) 
											 	--+ ISNULL(TIN.TINInterests, 0)
												--+ ISNULL(IntTIN.IntOnTINInterests, 0)
												,#DepositStatement.LangID,0)
			ELSE
				dbo.fn_Mo_MoneyToStr(ISNULL(INM.INMInterests,0) 
											+ ISNULL(TIN.TINInterests,0), #DepositStatement.LangID, 0) 
			END, -- Intérêt sur capital additionné des intérêts sur capital provenant de transfert IN
		BourseANDMntSouscrit = dbo.fn_Mo_MoneyToStr(RC.MntSouscrit
																+ ISNULL(TIN.TINInterests, 0)
																+ ISNULL(IntTIN.IntOnTINInterests, 0)
																+ (@UnitValue * #DepositStatement.UnitQty), #DepositStatement.LangID, 0), -- Bourse estimés selon le bourses versées lors des trois dernières années additionné du montant souscrit
		StudyCost = CASE 
						WHEN (SA.StateName NOT IN ('QC','Québec')) THEN									-- 2010-08-17
							dbo.fn_Mo_MoneyToStr(ISNULL(SC.StudyCostCA,0), #DepositStatement.LangID, 0)	
						ELSE 
							dbo.fn_Mo_MoneyToStr(ISNULL(SC.StudyCost,0), #DepositStatement.LangID, 0)
					END, -- Valeur estimé du coûts des études selon une projection basé sur le coûts moyen des études actuelles.
		Saving = dbo.fn_Mo_MoneyToStr(RC.Cotisation, #DepositStatement.LangID, 0),
		Fee = dbo.fn_Mo_MoneyToStr(RC.Fee, #DepositStatement.LangID, 0),
		ScholarshipProjection = dbo.fn_Mo_MoneyToStr(	--ISNULL(TIN.TINInterests, 0)
																	--+	
																	ISNULL(INM.INMInterests, 0) 
																	--+	ISNULL(IntTIN.IntOnTINInterests, 0)
																	+	(@UnitValue * #DepositStatement.UnitQty),#DepositStatement.LangID,0),
		CESPTotal = dbo.fn_Mo_MoneyToStr(	ISNULL(INS.IntCESP, 0)
		            							+	ISNULL(GG.fCESG, 0)
		            							+	ISNULL(GG.fACESG, 0)
		            							+	ISNULL(GG.fCLB, 0), #DepositStatement.LangID, 0),
		PSEFundsTotal = 
				CASE 
					WHEN P.PlanTypeID = 'IND' THEN
						dbo.fn_Mo_MoneyToStr(	RC.MntSouscrit
													+	ISNULL(INM.INMInterests, 0) 
													+	ISNULL(TIN.TINInterests, 0)
													+	ISNULL(IntTIN.IntOnTINInterests, 0)
													+	ISNULL(INS.IntCESP,0)
		            							+	ISNULL(GG.fCESG,0)
		            							+	ISNULL(GG.fACESG,0)
		            							+	ISNULL(GG.fCLB,0), #DepositStatement.LangID, 0)
				ELSE
					dbo.fn_Mo_MoneyToStr(	RC.MntSouscrit
												+	ISNULL(INM.INMInterests, 0) 
												+	ISNULL(TIN.TINInterests, 0)
												+	ISNULL(IntTIN.IntOnTINInterests, 0)
												+	(@UnitValue * #DepositStatement.UnitQty)
												+	ISNULL(INS.IntCESP,0)
	            							+	ISNULL(GG.fCESG,0)
	            							+	ISNULL(GG.fACESG,0)
	            							+	ISNULL(GG.fCLB,0), #DepositStatement.LangID, 0)
				END,
		SCEE = dbo.fn_Mo_MoneyToStr(ISNULL(GG.fCESG, 0) + ISNULL(INSofARI.IntCESPARI, 0), #DepositStatement.LangID, 0), -- Solde du compte de subvention standard (20%). (Sont ajouté les intérêts sur subventions entrés manuellement)
		IntPCEE = dbo.fn_Mo_MoneyToStr(ISNULL(INS.IntCESP, 0) - ISNULL(INSofARI.IntCESPARI, 0), #DepositStatement.LangID, 0), -- La somme des comptes d’intérêt SCEE, d’intérêt SCEE+, d’intérêt BEC et d’intérêt PCEE provenant d’un transfert IN. (Sont exclu les intérêts entrés manuellement)
		IntTIN = dbo.fn_Mo_MoneyToStr(ISNULL(TIN.TINInterests, 0) + ISNULL(IntTIN.IntOnTINInterests, 0), #DepositStatement.LangID, 0), -- La somme du solde des comptes d’intérêt sur capital provenant d’un transfert IN et d’intérêt sur l’intérêt sur capital provenant d’un transfert IN.
		SCEESupp = dbo.fn_Mo_MoneyToStr(ISNULL(GG.fACESG, 0), #DepositStatement.LangID, 0), -- Solde du compte de SCEE+.
		BEC = dbo.fn_Mo_MoneyToStr(ISNULL(GG.fCLB, 0), #DepositStatement.LangID, 0), -- Solde du compte de BEC.
		BourseVSStudyCost = 
				dbo.fn_Mo_MoneyToStr(	CASE 
													WHEN P.PlanTypeID = 'IND' 
													AND CASE 
															WHEN (SA.StateName NOT IN ('QC','Québec')) THEN -- 2010-08-17 : JFG
																ISNULL(SC.StudyCostCA,0)
															ELSE 
																ISNULL(SC.StudyCost,0)
															END 
														-	( ISNULL(RC.Cotisation, 0)
															+ ISNULL(INM.INMInterests, 0) 
															+ ISNULL(TIN.TINInterests, 0)
															+ ISNULL(IntTIN.IntOnTINInterests, 0)
															+ ISNULL(INS.IntCESP,0)
						      							+ ISNULL(GG.fCESG,0)
						      							+ ISNULL(GG.fACESG,0)
						      							+ ISNULL(GG.fCLB,0)
															) > 0	THEN
														CASE 
															WHEN (SA.StateName NOT IN ('QC','Québec')) THEN -- 2010-08-17 : JFG
																ISNULL(SC.StudyCostCA,0)
															ELSE ISNULL(SC.StudyCost,0)
														END
														-	( ISNULL(RC.Cotisation, 0)
															+ ISNULL(INM.INMInterests, 0) 
															+ ISNULL(TIN.TINInterests, 0)
															+ ISNULL(IntTIN.IntOnTINInterests, 0)
															+ ISNULL(INS.IntCESP,0)
						      							+ ISNULL(GG.fCESG,0)
						      							+ ISNULL(GG.fACESG,0)
						      							+ ISNULL(GG.fCLB,0)
															)
													WHEN P.PlanTypeID = 'IND' THEN 0
													WHEN CASE 
															WHEN (SA.StateName NOT IN ('QC','Québec')) THEN  -- 2010-08-17 : JFG
																ISNULL(SC.StudyCostCA,0)
															ELSE ISNULL(SC.StudyCost,0)
															END
														-	( RC.MntSouscrit
															+ ISNULL(INM.INMInterests, 0) 
															+ ISNULL(TIN.TINInterests, 0)
															+ ISNULL(IntTIN.IntOnTINInterests, 0)
															+	( @UnitValue
																* #DepositStatement.UnitQty
																)
															+ ISNULL(INS.IntCESP,0)
				            							+ ISNULL(GG.fCESG,0)
				            							+ ISNULL(GG.fACESG,0)
				            							+ ISNULL(GG.fCLB,0)
															) > 0	THEN
														CASE 
															WHEN (SA.StateName NOT IN ('QC','Québec')) THEN -- 2010-08-17 : JFG
																ISNULL(SC.StudyCostCA,0)
															ELSE ISNULL(SC.StudyCost,0)
														END
														-	( RC.MntSouscrit
															+ ISNULL(INM.INMInterests, 0) 
															+ ISNULL(TIN.TINInterests, 0)
															+ ISNULL(IntTIN.IntOnTINInterests, 0)
															+	( @UnitValue
																* #DepositStatement.UnitQty
																)
															+ ISNULL(INS.IntCESP,0)
				            							+ ISNULL(GG.fCESG,0)
				            							+ ISNULL(GG.fACESG,0)
				            							+ ISNULL(GG.fCLB,0)
															)
													ELSE 0
												END, #DepositStatement.LangID, 0), -- Différence entre le total du fonds potentiellement disponibles pour les études et le coût estimé des études postsecondaires.  Le montant sera 0.00$ quand le coût estimé des études postsecondaires sera moins élevé que le total du fonds potentiellement disponibles pour les études.
		RepresentativeFirstName = CASE WHEN R.BusinessEnd IS NULL THEN ISNULL(HR.FirstName,'') ELSE ISNULL(HD.FirstName,'') END, -- Prénom du représentant ou du directeur
		RepresentativeLastName = CASE WHEN R.BusinessEnd IS NULL THEN ISNULL(HR.LastName,'') ELSE ISNULL(HD.LastName,'') END, -- Nom du représentant ou du directeur 
		RepPhone = CASE WHEN R.BusinessEnd IS NULL THEN dbo.fn_Mo_FormatPhoneNo(ISNULL(SR.Phone1,''), SR.CountryID) ELSE dbo.fn_Mo_FormatPhoneNo(ISNULL(SD.Phone1,''), SD.CountryID) END -- Téléphone du représentant ou du directeur	
	FROM #DepositStatement
	JOIN dbo.Un_Convention C ON C.ConventionID = #DepositStatement.ConventionID
	JOIN #Convention RC ON RC.ConventionID = C.ConventionID
	JOIN Un_Plan P ON P.PlanID = C.PlanID
	JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID
	LEFT JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
	LEFT JOIN dbo.Mo_Human HS ON HS.HumanID = S.SubscriberID
	LEFT JOIN dbo.Mo_Adr SA ON SA.AdrID = HS.AdrID
	LEFT JOIN Un_Rep R ON R.RepID = S.RepID
	LEFT JOIN dbo.Mo_Human HR ON HR.HumanID = R.RepID
	LEFT JOIN dbo.Mo_Adr SR ON SR.AdrID = HR.AdrID
	LEFT JOIN (-- Directeur du représentant
		SELECT 
			RB.RepID, 
			BossID = MAX(BossID)
		FROM Un_RepBossHist RB
		JOIN (
			SELECT 
				RB.RepID, 
				RepBossPct = MAX(RB.RepBossPct)
			FROM Un_RepBossHist RB
			WHERE RepRoleID = 'DIR'
				AND RB.StartDate <= GETDATE()
				AND ISNULL(RB.EndDate,GETDATE()) >= GETDATE()
			GROUP BY 
				RB.RepID
			) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
		WHERE RB.RepRoleID = 'DIR'
			AND RB.StartDate <= GETDATE()
			AND ISNULL(RB.EndDate,GETDATE()) >= GETDATE()
		GROUP BY 
			RB.RepID
		) RD ON RD.RepID = HR.HumanID
	LEFT JOIN dbo.Mo_Human HD ON HD.HumanID = RD.BossID
	LEFT JOIN dbo.Mo_Adr SD ON SD.AdrID = HD.AdrID
	LEFT JOIN (
		SELECT 
			CO.ConventionID, 
			TINInterests = SUM(CO.ConventionOperAmount)
		FROM #DepositStatement D
		JOIN Un_ConventionOper CO ON D.ConventionID = CO.ConventionID
		JOIN Un_Oper O ON O.OperID = CO.OperID
		WHERE CO.ConventionOperTypeID = 'ITR'
			AND (CHARINDEX(O.OperTypeID,@vcOPER_RENDEMENT_POSITIF_NEGATIF) = 0)
			AND O.OperDate < @DatePlus1
		GROUP BY CO.ConventionID
		) TIN ON TIN.ConventionID = C.ConventionID
	LEFT JOIN (
		SELECT 
			CO.ConventionID, 
			IntOnTINInterests = SUM(CO.ConventionOperAmount)
		FROM #DepositStatement D
		JOIN Un_ConventionOper CO ON D.ConventionID = CO.ConventionID
		JOIN Un_Oper O ON O.OperID = CO.OperID
		WHERE CO.ConventionOperTypeID = 'ITR'
			AND (CHARINDEX(O.OperTypeID,@vcOPER_RENDEMENT_POSITIF_NEGATIF) > 0)
			AND O.OperDate < @DatePlus1
		GROUP BY CO.ConventionID
		) IntTIN ON IntTIN.ConventionID = C.ConventionID
	LEFT JOIN (
		SELECT 
			CO.ConventionID, 
			INMInterests = SUM(CO.ConventionOperAmount)
		FROM #DepositStatement D
		JOIN Un_ConventionOper CO ON D.ConventionID = CO.ConventionID
		JOIN Un_Oper O ON O.OperID = CO.OperID
		WHERE CO.ConventionOperTypeID = 'INM'
			AND O.OperDate < @DatePlus1
		GROUP BY CO.ConventionID
		) INM ON INM.ConventionID = C.ConventionID
	LEFT JOIN (
		SELECT 
			CO.ConventionID, 
			IntCESP = SUM(CO.ConventionOperAmount)
		FROM #DepositStatement D
		JOIN Un_ConventionOper CO ON D.ConventionID = CO.ConventionID
		JOIN Un_Oper O ON O.OperID = CO.OperID
		WHERE ( CO.ConventionOperTypeID = 'INS'
				OR CO.ConventionOperTypeID = 'IST'
				OR CO.ConventionOperTypeID = 'IS+'
				OR CO.ConventionOperTypeID = 'IBC'
				)
			AND O.OperDate < @DatePlus1
		GROUP BY CO.ConventionID
		) INS ON INS.ConventionID = C.ConventionID
	--Va chercher les intérêts sur subventions qui ont été entré manuellement
	LEFT JOIN (
		SELECT 
			CO.ConventionID, 
			IntCESPARI = SUM(CO.ConventionOperAmount)
		FROM #DepositStatement D
		JOIN Un_ConventionOper CO ON D.ConventionID = CO.ConventionID
		JOIN Un_Oper O ON O.OperID = CO.OperID
		WHERE CO.ConventionOperTypeID = 'INS'
			AND O.OperTypeID = 'ARI'
			AND O.OperDate < @DatePlus1
		GROUP BY CO.ConventionID
		) INSofARI ON INSofARI.ConventionID = C.ConventionID
	LEFT JOIN (
		SELECT 
			CE.ConventionID, 
			fCESG = SUM(CE.fCESG),
			fACESG = SUM(CE.fACESG),
			fCLB = SUM(CE.fCLB)
		FROM #DepositStatement D
		JOIN Un_CESP CE ON D.ConventionID = CE.ConventionID
		JOIN Un_Oper O ON O.OperID = CE.OperID
		WHERE O.OperDate < @DatePlus1
		GROUP BY CE.ConventionID
		) GG ON GG.ConventionID = C.ConventionID
	LEFT JOIN Un_StudyCost SC ON SC.YearQualif = RC.YearQualif

	IF @RecordEnd = 0
		SET @Range = 'Tous'
	ELSE
		SET @Range = 'De '+CAST(@RecordStart AS VARCHAR(7)) + ' à ' + CAST(@RecordEnd AS VARCHAR(7)) + ' sur ' + CAST(@Count AS VARCHAR(7))

	-- Gestion des documents
	IF @DocAction IN (0,2)
	BEGIN

		-- Crée le document dans la gestion des documents
		INSERT INTO CRQ_Doc (DocTemplateID, DocOrderConnectID, DocOrderTime, DocGroup1, DocGroup2, DocGroup3, Doc)
			SELECT 
				DocTemplateID,
				@ConnectID,
				@Today,
				ISNULL(ConventionNO,''),
				ISNULL(SubscriberLastName,'')+', '+ISNULL(SubscriberFirstName,''),
				@Range,
				ISNULL(LangID,'')+';'+
				ISNULL(DepositStatementDate,'')+';'+
				ISNULL(LongSexName,'')+';'+
				ISNULL(ShortSexName,'')+';'+
				ISNULL(SubscriberFirstName,'')+';'+
				ISNULL(SubscriberLastName,'')+';'+
				ISNULL(Address,'')+';'+
				ISNULL(City,'')+';'+
				ISNULL(StateName,'')+';'+
				ISNULL(ZipCode,'')+';'+
				ISNULL(BeneficiaryFirstName,'')+';'+
				ISNULL(BeneficiaryLastName,'')+';'+
				ISNULL(SocialNumber,'')+';'+
				ISNULL(ConventionNo,'')+';'+
				ISNULL(CAST(YearQualif AS VARCHAR),'')+';'+
				ISNULL(RepresentativeFirstName,'')+';'+
				ISNULL(RepresentativeLastName,'')+';'+
				ISNULL(RepPhone,'')+';'+
				ISNULL(CAST(CAST(UnitQty AS FLOAT) AS VARCHAR),'')+';'+
				ISNULL(InForceDate,'')+';'+
				ISNULL(LastDepositDate,'')+';'+
				ISNULL(CotisationFee,'')+';'+
				ISNULL(INMInterests,'')+';'+
				ISNULL(EstimatedIntReimbDate,'')+';'+
				ISNULL(MntSouscrit,'')+';'+
				ISNULL(Bourse,'')+';'+
				ISNULL(BourseANDMntSouscrit,'')+';'+
				ISNULL(StudyCost,'')+';'+
				ISNULL(ThirdANDSecondLastYear,'')+';'+
				ISNULL(LastYear,'')+';'+
				ISNULL(Saving,'')+';'+
				ISNULL(Fee,'')+';'+
				ISNULL(ScholarshipProjection,'')+';'+
				ISNULL(CESPTotal,'')+';'+
				ISNULL(PSEFundsTotal,'')+';'+
				ISNULL(SCEE,'')+';'+
				ISNULL(IntPCEE,'')+';'+
				ISNULL(IntTIN,'')+';'+
				ISNULL(SCEESupp,'')+';'+
				ISNULL(BEC,'')+';'+
				ISNULL(BourseVSStudyCost,'')+';'+
				ISNULL(NoneResidentCountry,'')+';'+
				ISNULL(StudyCostNoteNotNB,'')+';'+
				ISNULL(StudyCostNoteNotNBQC,'')+';'+
				ISNULL(CityStateCPCountry1,'')+';'+
				ISNULL(CityStateCPCountry2,'')+';'
			FROM #DepositStatement

		-- Fait un lient entre le document et la convention pour que retrouve le document 
		-- dans l'historique des documents de la convention
		INSERT INTO CRQ_DocLink 
			SELECT
				C.ConventionID,
				1,
				D.DocID
			FROM CRQ_Doc D 
			JOIN CRQ_DocTemplate T ON (T.DocTemplateID = D.DocTemplateID)
			JOIN dbo.Un_Convention C ON (C.ConventionNo = D.DocGroup1)
			LEFT JOIN CRQ_DocLink L ON L.DocLinkID = C.ConventionID AND L.DocLinkType = 1 AND L.DocID = D.DocID
			WHERE L.DocID IS NULL
			  AND T.DocTypeID = @DocTypeID
			  AND D.DocOrderTime = @Today
			  AND D.DocOrderConnectID = @ConnectID	

		IF @DocAction = 2
			-- Dans le cas que l'usager a choisi imprimer et garder la trace dans la gestion 
			-- des documents, on indique qu'il a déjà été imprimé pour ne pas le voir dans 
			-- la queue d'impression
			INSERT INTO CRQ_DocPrinted(DocID, DocPrintConnectID, DocPrintTime)
				SELECT
					D.DocID,
					@ConnectID,
					@Today
				FROM CRQ_Doc D 
				JOIN CRQ_DocTemplate T ON (T.DocTemplateID = D.DocTemplateID)
				LEFT JOIN CRQ_DocPrinted P ON P.DocID = D.DocID AND P.DocPrintConnectID = @ConnectID AND P.DocPrintTime = @Today
				WHERE P.DocID IS NULL
				  AND T.DocTypeID = @DocTypeID
				  AND D.DocOrderTime = @Today
				  AND D.DocOrderConnectID = @ConnectID					
	END

	IF @DocAction <> 0
	BEGIN
		-- Produit un dataset pour la fusion
		SELECT 
			DocTemplateID,
			LangID,
			DepositStatementDate,
			LongSexName,
			ShortSexName,
			SubscriberFirstName,
			SubscriberLastName,
			Address,
			City,
			StateName,
			ZipCode,
			BeneficiaryFirstName,
			BeneficiaryLastName,
			SocialNumber,
			ConventionNo,
			YearQualif,
			RepresentativeFirstName,
			RepresentativeLastName,
			RepPhone,
			UnitQty,
			InForceDate,
			LastDepositDate,
			CotisationFee,
			INMInterests,
			EstimatedIntReimbDate,
			MntSouscrit,
			Bourse,
			BourseANDMntSouscrit,
			StudyCost,
			ThirdANDSecondLastYear,
			LastYear,
			Saving,
			Fee,
			ScholarshipProjection,
			CESPTotal,
			PSEFundsTotal,
			SCEE, -- Solde du compte de subvention standard (20%).
			IntPCEE, -- La somme des comptes d’intérêt SCEE, d’intérêt SCEE+, d’intérêt BEC et d’intérêt PCEE provenant d’un transfert IN.
			IntTIN, -- La somme du solde des comptes d’intérêt sur capital provenant d’un transfert IN et d’intérêt sur l’intérêt sur capital provenant d’un transfert IN.
			SCEESupp, -- Solde du compte de SCEE+.
			BEC, -- Solde du compte de BEC.
			BourseVSStudyCost, -- Différence entre le total du fonds potentiellement disponibles pour les études et le coût estimé des études postsecondaires.  Le montant sera 0.00$ quand le coût estimé des études postsecondaires sera moins élevé que le total du fonds potentiellement disponibles pour les études.
			NoneResidentCountry, -- Nom du pays. Si le pays est le Canada alors le champ sera vide.
			StudyCostNoteNotNB, -- Note a ajouter pour le coût des études si la province n'est pas Nouveau-Brunswick
			StudyCostNoteNotNBQC, -- Note a ajouter pour le coût des études si la province n'est pas Nouveau-Brunswick ou Québec
			CityStateCPCountry1, -- Si Ville > 30 caratères = Ville, province, code postal Sinon Ville 
			CityStateCPCountry2, -- Si Ville > 30 caratères = Province, code postal Sinon Vide + Pays
			SSocialNumber,  -- NAS du souscripteur.
			Range = @Range
		FROM #DepositStatement 
		WHERE @DocAction IN (1,2)
		ORDER BY 
			DocTemplateID,
			LangID, 
			SubscriberLastName, 
			SubscriberFirstName, 
			ZipCode, 
			Address, 
			City, 
			StateName, 
			ConventionNo
	END

	IF NOT EXISTS (
			SELECT 
				DocTemplateID
			FROM CRQ_DocTemplate
			WHERE (DocTypeID = @DocTypeID)
			  AND (DocTemplateTime < @Today))
		RETURN -1 -- Pas de template d'entré ou en vigueur pour ce type de document
	IF NOT EXISTS (
			SELECT 
				DocTemplateID
			FROM #DepositStatement)
		RETURN -2 -- Pas de document(s) de généré(s)
	ELSE 
		RETURN 1 -- Tout a bien fonctionné

	-- RETURN VALUE
	---------------
	-- >0  : Tout ok
	-- <=0 : Erreurs
	-- 	-1 : Pas de template d'entré ou en vigueur pour ce type de document
	-- 	-2 : Pas de document(s) de généré(s)

	DROP TABLE #DocTemplate_DepStatement
	DROP TABLE #DepositStatement
	DROP TABLE #Convention

	SET @dtEnd = GETDATE()
	SELECT @siTraceReport = siTraceReport FROM Un_Def

	IF DATEDIFF(SECOND, @dtBegin, @dtEnd) > @siTraceReport
	BEGIN
		-- Insère un log de l'objet inséré.
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
				DATEDIFF(SECOND, @dtBegin, @dtEnd),
				@dtBegin,
				@dtEnd,
				'Rapport du relevé de dépôt selon le plan ' + CAST(@PlanID AS VARCHAR) + ' avant le ' + CAST(@Date AS VARCHAR),
				'RP_UN_DepositStatementBatch',
				'EXECUTE RP_UN_DepositStatementBatch @ConnectID ='+CAST(@ConnectID AS VARCHAR)+
				', @PlanID ='+CAST(@PlanID AS VARCHAR)+
				', @Date ='+CAST(@Date AS VARCHAR)+
				', @RecordStart ='+CAST(@RecordStart AS VARCHAR)+
				', @RecordEnd ='+CAST(@RecordEnd AS VARCHAR)+
				', @OnlySemiAnnual ='+CAST(@OnlySemiAnnual AS VARCHAR)+
				', @LangID ='+@LangID+
				', @DocAction ='+CAST(@DocAction AS VARCHAR)
	END	
    */
END

--  EXEC RP_UN_DepositStatementBatch 1, 4, '2007-12-31', 1, 120000, 0, 'ALL', 1