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
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	RP_UN_FirstScholarshipStatistic
Description         :	Procédure retournant les données pour le rapport de statistique des premières bourses.
Valeurs de retours  :	Dataset :
			tiSection		TINYINT			Indique la section à laquelle appartient l’enregistrement (1 = Ville, 2 = Universitas et 3 = Cégep)
			tiGroupOrder		TINYINT			Emplacement du regroupement dans l’ordre de ceux-ci. Plus le nombre est petit, plus le groupe sera au début. 
			vcGroup			VARCHAR(255)		Nom du regroupement (Tous les régimes, Universitas, Sélect 2000 Plan B, etc.)
			tiNameOrder		TINYINT			Emplacement de l’enregistrement (ville, universités, cégep) dans le regroupement  de cette section. Plus le nombre est petit, plus il sera au début.
			vcName			VARCHAR(255)		Si dans la section 1, c’est le nom de la ville ou de regroupement de ville. Section 2, c’est le nom de l’université ou du regroupement d’universités. Section 3, c’est le nom de la région du regroupement de cégeps ou de collèges communautaires.
			fUnitQty		MONEY			Nombre d’unités.
			iCntBeneficiairy	INTEGER			Nombre de bénéficiaire.
			fScholarship		MONEY			Montant de bourses.
			fPourcentage		MONEY			Pourcentage de montant de bourse total du régime.
Note                :	ADX0000701	IA	2006-10-25	Bruno Lapointe			Création
					BR	
										2008-10-02	Josée Parent			Modification pour prendre en compte toutes
																			les possibilités d'écriture de provinces du quebec
                                        2017-09-27  Pierre-Luc Simard       Deprecated - Cette procédure n'est plus utilisée

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_FirstScholarshipStatistic] (
	@dtPeriodStart DATETIME, -- Date de début de la période voulue.
	@dtPeriodEnd DATETIME ) -- Date de fin de la période voulue.
AS
BEGIN
    
    SELECT 1/0
    /*
	-- Table temporaire contenant seulement les bourses sur lesquelles on veut faire des statistiques
	DECLARE @tUnitQtyOfConv TABLE (
		ConventionID INTEGER PRIMARY KEY,
		ScholarshipID INTEGER NOT NULL,
		BeneficiaryID INTEGER NOT NULL,
		SubscriberID INTEGER NOT NULL,
		PlanID INTEGER NOT NULL,
		UnitQty MONEY NOT NULL )
	
	INSERT INTO @tUnitQtyOfConv
		SELECT 
			U.ConventionID,
			S.ScholarshipID,
			C.BeneficiaryID,
			C.SubscriberID,
			C.PlanID,
			SUM(U.UnitQty)
		FROM dbo.Un_Unit U
		JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
		JOIN Un_Scholarship S ON C.ConventionID = S.ConventionID
		LEFT JOIN Un_ScholarshipPmt PM ON S.ScholarshipID = PM.ScholarshipID
 		LEFT JOIN Un_Oper O ON PM.OperID = O.OperID 
		WHERE C.ScholarshipEntryID IN ('A', 'R', 'G') -- Pas un transfert sobecco
 			AND S.ScholarshipNo = 1 --- Numéro de bourse = 1 
  			AND C.ScholarshipYear >= 2000 -- Entré au système en 2000 ou après
			AND(	( O.OperTypeID = 'PAE' 
					AND O.OperDate BETWEEN @dtPeriodStart AND @dtPeriodEnd 
					AND S.ScholarshipStatusID = 'PAD' -- Payé
					)
				OR S.ScholarshipStatusID = 'WAI' -- en attente
				)
		GROUP BY
			U.ConventionID,
			S.ScholarshipID,
			C.PlanID,
			C.SubscriberID,
			C.BeneficiaryID

	-- Table contenant les colleges reliés aux bourses
	DECLARE @tCollegeOfScholarship TABLE (
		ScholarshipID INTEGER PRIMARY KEY,
		CollegeID INTEGER NULL )

	-- Va chercher le college sur la preuve d'inscription du paiement de la bourse s'il y en a un
	INSERT INTO @tCollegeOfScholarship
		SELECT 
			U.ScholarshipID,
			MIN(PM.CollegeID)
		FROM @tUnitQtyOfConv U
		JOIN Un_ScholarshipPmt PM ON U.ScholarshipID = PM.ScholarshipID
 		JOIN Un_Oper O ON PM.OperID = O.OperID 
		WHERE O.OperTypeID = 'PAE'
			AND PM.CollegeID IS NOT NULL
		GROUP BY U.ScholarshipID
		
	-- S'il n'y a pas de paiement de bourse, va chercher le college sur le bénéficiaire
	INSERT INTO @tCollegeOfScholarship
		SELECT 
			U.ScholarshipID,
			B.CollegeID
		FROM @tUnitQtyOfConv U
		JOIN dbo.Un_Beneficiary B ON U.BeneficiaryID = B.BeneficiaryID
		LEFT JOIN @tCollegeOfScholarship PM ON U.ScholarshipID = PM.ScholarshipID
		WHERE PM.ScholarshipID IS NULL

	-- Table temporaire du rapport
	DECLARE @tFirstScholarshipStatistic TABLE (
		tiSection TINYINT NOT NULL, -- Indique la section à laquelle appartient l’enregistrement (1 = Ville, 2 = Universitas et 3 = Cégep)
		tiGroupOrder TINYINT NOT NULL, -- Emplacement du regroupement dans l’ordre de ceux-ci. Plus le nombre est petit, plus le groupe sera au début. 
		vcGroup VARCHAR(255) NOT NULL, -- Nom du regroupement (Tous les régimes, Universitas, Sélect 2000 Plan B, etc.)
		tiNameOrder TINYINT NOT NULL, -- Emplacement de l’enregistrement (ville, universités, cégep) dans le regroupement  de cette section. Plus le nombre est petit, plus il sera au début.
		vcName VARCHAR(255) NOT NULL, -- Si dans la section 1, c’est le nom de la ville ou de regroupement de ville. Section 2, c’est le nom de l’université ou du regroupement d’universités. Section 3, c’est le nom de la région du regroupement de cégeps ou de collèges communautaires.
		fUnitQty MONEY NOT NULL, -- Nombre d’unités.
		iCntBeneficiairy INTEGER NOT NULL, -- Nombre de bénéficiaire.
		fScholarship MONEY NOT NULL ) -- Montant de bourses.
		
	-- Ville
	INSERT INTO @tFirstScholarshipStatistic
		SELECT 
			tiSection = 1, -- Indique la section à laquelle appartient l’enregistrement (1 = Ville, 2 = Universitas et 3 = Cégep)
			tiGroupOrder = P.OrderOfPlanInReport, -- Emplacement du regroupement dans l’ordre de ceux-ci. Plus le nombre est petit, plus le groupe sera au début. 
			vcGroup = P.PlanDesc, -- Nom du regroupement (Tous les régimes, Universitas, Sélect 2000 Plan B, etc.)
			tiNameOrder = 
				CASE
					WHEN A.StateName = 'Québec' THEN 0 
					WHEN A.StateName = 'QC' THEN 0
					WHEN A.StateName = 'qué' THEN 0
					WHEN A.StateName = 'Québeca' THEN 0
					WHEN A.StateName = 'Québecf' THEN 0
					WHEN A.StateName = 'Québeco' THEN 0
					WHEN A.StateName = 'Québecq' THEN 0
					WHEN A.StateName = 'Québecv' THEN 0
					WHEN A.StateName = 'Québeec' THEN 0
					WHEN A.StateName = 'Québerc' THEN 0
					WHEN A.StateName = 'Quéibec' THEN 0
					WHEN A.StateName = 'Qujébec' THEN 0
					WHEN A.StateName = 'N.-B.' THEN 1 
					WHEN A.StateName = 'Nouveau-Brunswick' THEN 1
					WHEN A.StateName = 'Nouveau-Brunswixk' THEN 1
					WHEN A.CountryID = 'CAN' THEN 2
				ELSE 3
				END, -- Emplacement de l’enregistrement (ville, universités, cégep) dans le regroupement  de cette section. Plus le nombre est petit, plus il sera au début.
			vcName = 
				CASE
					WHEN A.StateName = 'Québec' THEN A.City 
					WHEN A.StateName = 'QC' THEN A.City 
					WHEN A.StateName = 'qué' THEN A.City 
					WHEN A.StateName = 'Québeca' THEN A.City 
					WHEN A.StateName = 'Québecf' THEN A.City 
					WHEN A.StateName = 'Québeco' THEN A.City 
					WHEN A.StateName = 'Québecq' THEN A.City 
					WHEN A.StateName = 'Québecv' THEN A.City 
					WHEN A.StateName = 'Québeec' THEN A.City 
					WHEN A.StateName = 'Québerc' THEN A.City 
					WHEN A.StateName = 'Quéibec' THEN A.City 
					WHEN A.StateName = 'Qujébec' THEN A.City 
					WHEN A.StateName = 'N.-B.' THEN 'Nouv.-Brunswick' 
					WHEN A.StateName = 'Nouveau-Brunswick' THEN 'Nouv.-Brunswick'
					WHEN A.StateName = 'Nouveau-Brunswixk' THEN 'Nouv.-Brunswick'
					WHEN A.CountryID = 'CAN' THEN 'AUTRES PROVINCES'
				ELSE 'HORS CANADA'
				END, -- C’est le nom de la région du regroupement de cégeps ou de collèges communautaires.
			fUnitQty = SUM(U.UnitQty), -- Nombre d’unités.
			iCntBeneficiairy = COUNT(U.BeneficiaryID),  -- Nombre de bénéficiaire.
			fScholarship = SUM(S.ScholarshipAmount) -- Montant de bourses.
		FROM @tUnitQtyOfConv U
		JOIN Un_Scholarship S ON S.ScholarshipID = U.ScholarshipID
		JOIN @tCollegeOfScholarship C ON C.ScholarshipID = U.ScholarshipID
		JOIN Un_Plan P ON P.PlanID = U.PlanID
		JOIN Un_College Co ON Co.CollegeID = C.CollegeID
 		JOIN dbo.Mo_Human H ON U.SubscriberID = H.HumanID
 		JOIN dbo.Mo_Adr A ON H.AdrID = A.AdrID
		JOIN Mo_Company Cie 	ON Co.CollegeID = Cie.CompanyID
		WHERE Cie.CompanyName Not LIKE '(Établissement inconnu)'
		GROUP BY 
			P.OrderOfPlanInReport,
			P.PlanDesc,
			CASE
				WHEN A.StateName = 'Québec' THEN 0 
				WHEN A.StateName = 'QC' THEN 0
				WHEN A.StateName = 'qué' THEN 0
				WHEN A.StateName = 'Québeca' THEN 0
				WHEN A.StateName = 'Québecf' THEN 0
				WHEN A.StateName = 'Québeco' THEN 0
				WHEN A.StateName = 'Québecq' THEN 0
				WHEN A.StateName = 'Québecv' THEN 0
				WHEN A.StateName = 'Québeec' THEN 0
				WHEN A.StateName = 'Québerc' THEN 0
				WHEN A.StateName = 'Quéibec' THEN 0
				WHEN A.StateName = 'Qujébec' THEN 0
				WHEN A.StateName = 'N.-B.' THEN 1 
				WHEN A.StateName = 'Nouveau-Brunswick' THEN 1
				WHEN A.StateName = 'Nouveau-Brunswixk' THEN 1
				WHEN A.CountryID = 'CAN' THEN 2
			ELSE 3
			END,
			CASE
				WHEN A.StateName = 'Québec' THEN A.City 
				WHEN A.StateName = 'QC' THEN A.City 
				WHEN A.StateName = 'qué' THEN A.City 
				WHEN A.StateName = 'Québeca' THEN A.City 
				WHEN A.StateName = 'Québecf' THEN A.City 
				WHEN A.StateName = 'Québeco' THEN A.City 
				WHEN A.StateName = 'Québecq' THEN A.City 
				WHEN A.StateName = 'Québecv' THEN A.City 
				WHEN A.StateName = 'Québeec' THEN A.City 
				WHEN A.StateName = 'Québerc' THEN A.City 
				WHEN A.StateName = 'Quéibec' THEN A.City 
				WHEN A.StateName = 'Qujébec' THEN A.City 
				WHEN A.StateName = 'N.-B.' THEN 'Nouv.-Brunswick'
				WHEN A.StateName = 'Nouveau-Brunswick' THEN 'Nouv.-Brunswick'
				WHEN A.StateName = 'Nouveau-Brunswixk' THEN 'Nouv.-Brunswick'
				WHEN A.CountryID = 'CAN' THEN 'AUTRES PROVINCES'
			ELSE 'HORS CANADA'
			END

	-- Université
	INSERT INTO @tFirstScholarshipStatistic
		SELECT
			tiSection = 2, -- Indique la section à laquelle appartient l’enregistrement (1 = Ville, 2 = Universitas et 3 = Cégep)
			tiGroupOrder = P.OrderOfPlanInReport, -- Emplacement du regroupement dans l’ordre de ceux-ci. Plus le nombre est petit, plus le groupe sera au début. 
			vcGroup = P.PlanDesc, -- Nom du regroupement (Tous les régimes, Universitas, Sélect 2000 Plan B, etc.)
			tiNameOrder = 
				CASE
					WHEN Co.tiSpecialInFirstScholarshipStatistic = 1 THEN 4 
					WHEN Co.tiSpecialInFirstScholarshipStatistic = 2 THEN 0 
					WHEN Co.tiSpecialInFirstScholarshipStatistic = 3 THEN 2 
					WHEN Co.tiSpecialInFirstScholarshipStatistic = 4 THEN 1 
					WHEN A.StateName = 'Québec' THEN 0 
					WHEN A.StateName = 'QC' THEN 0
					WHEN A.StateName = 'qué' THEN 0
					WHEN A.StateName = 'Québeca' THEN 0
					WHEN A.StateName = 'Québecf' THEN 0
					WHEN A.StateName = 'Québeco' THEN 0
					WHEN A.StateName = 'Québecq' THEN 0
					WHEN A.StateName = 'Québecv' THEN 0
					WHEN A.StateName = 'Québeec' THEN 0
					WHEN A.StateName = 'Québerc' THEN 0
					WHEN A.StateName = 'Quéibec' THEN 0
					WHEN A.StateName = 'Qujébec' THEN 0
					WHEN A.CountryID = 'CAN' THEN 3
				ELSE 4
				END, -- Emplacement de l’enregistrement (ville, universités, cégep) dans le regroupement  de cette section. Plus le nombre est petit, plus il sera au début.
			vcName = 
				CASE
					WHEN Co.tiSpecialInFirstScholarshipStatistic = 1 THEN 'VARIA QC' 
					WHEN Co.tiSpecialInFirstScholarshipStatistic = 2 THEN 'Université du Québec à Montréal (UQAM)' 
					WHEN Co.tiSpecialInFirstScholarshipStatistic = 3 THEN Cie.CompanyName 
					WHEN Co.tiSpecialInFirstScholarshipStatistic = 4 THEN Cie.CompanyName 
					WHEN A.StateName = 'Québec' THEN Cie.CompanyName 
					WHEN A.StateName = 'QC' THEN Cie.CompanyName 
					WHEN A.StateName = 'qué' THEN Cie.CompanyName 
					WHEN A.StateName = 'Québeca' THEN Cie.CompanyName 
					WHEN A.StateName = 'Québecf' THEN Cie.CompanyName 
					WHEN A.StateName = 'Québeco' THEN Cie.CompanyName 
					WHEN A.StateName = 'Québecq' THEN Cie.CompanyName 
					WHEN A.StateName = 'Québecv' THEN Cie.CompanyName 
					WHEN A.StateName = 'Québeec' THEN Cie.CompanyName 
					WHEN A.StateName = 'Québerc' THEN Cie.CompanyName 
					WHEN A.StateName = 'Quéibec' THEN Cie.CompanyName 
					WHEN A.StateName = 'Qujébec' THEN Cie.CompanyName 
					WHEN A.CountryID = 'CAN' THEN 'AUTRES PROVINCES'
				ELSE 'AUTRES PAYS'
				END, -- C’est le nom de la région du regroupement de cégeps ou de collèges communautaires.
			fUnitQty = SUM(U.UnitQty), -- Nombre d’unités.
			iCntBeneficiairy = COUNT(U.BeneficiaryID),  -- Nombre de bénéficiaire.
			fScholarship = SUM(S.ScholarshipAmount) -- Montant de bourses.
		FROM @tUnitQtyOfConv U
		JOIN Un_Scholarship S ON S.ScholarshipID = U.ScholarshipID
		JOIN @tCollegeOfScholarship C ON C.ScholarshipID = U.ScholarshipID
		JOIN Un_Plan P ON P.PlanID = U.PlanID
		JOIN Un_College Co ON Co.CollegeID = C.CollegeID
		JOIN Mo_Company Cie 	ON Co.CollegeID = Cie.CompanyID
		JOIN Mo_Dep D ON Cie.CompanyID = D.CompanyID
		JOIN dbo.Mo_Adr A ON D.AdrID = A.AdrID
		WHERE ISNULL(Co.cCollegeTypeExceptionInFirstScholarshipStatistic, Co.CollegeTypeID) IN ('01') -- Universités
		GROUP BY
			P.OrderOfPlanInReport,
			P.PlanDesc,
			CASE
				WHEN Co.tiSpecialInFirstScholarshipStatistic = 1 THEN 4 
				WHEN Co.tiSpecialInFirstScholarshipStatistic = 2 THEN 0 
				WHEN Co.tiSpecialInFirstScholarshipStatistic = 3 THEN 2 
				WHEN Co.tiSpecialInFirstScholarshipStatistic = 4 THEN 1 
				WHEN A.StateName = 'Québec' THEN 0 
				WHEN A.StateName = 'QC' THEN 0
				WHEN A.StateName = 'qué' THEN 0
				WHEN A.StateName = 'Québeca' THEN 0
				WHEN A.StateName = 'Québecf' THEN 0
				WHEN A.StateName = 'Québeco' THEN 0
				WHEN A.StateName = 'Québecq' THEN 0
				WHEN A.StateName = 'Québecv' THEN 0
				WHEN A.StateName = 'Québeec' THEN 0
				WHEN A.StateName = 'Québerc' THEN 0
				WHEN A.StateName = 'Quéibec' THEN 0
				WHEN A.StateName = 'Qujébec' THEN 0
				WHEN A.CountryID = 'CAN' THEN 3
			ELSE 4
			END,
			CASE
				WHEN Co.tiSpecialInFirstScholarshipStatistic = 1 THEN 'VARIA QC' 
				WHEN Co.tiSpecialInFirstScholarshipStatistic = 2 THEN 'Université du Québec à Montréal (UQAM)' 
				WHEN Co.tiSpecialInFirstScholarshipStatistic = 3 THEN Cie.CompanyName 
				WHEN Co.tiSpecialInFirstScholarshipStatistic = 4 THEN Cie.CompanyName 
				WHEN A.StateName = 'Québec' THEN Cie.CompanyName 
				WHEN A.StateName = 'QC' THEN Cie.CompanyName 
				WHEN A.StateName = 'qué' THEN Cie.CompanyName 
				WHEN A.StateName = 'Québeca' THEN Cie.CompanyName 
				WHEN A.StateName = 'Québecf' THEN Cie.CompanyName 
				WHEN A.StateName = 'Québeco' THEN Cie.CompanyName 
				WHEN A.StateName = 'Québecq' THEN Cie.CompanyName 
				WHEN A.StateName = 'Québecv' THEN Cie.CompanyName 
				WHEN A.StateName = 'Québeec' THEN Cie.CompanyName 
				WHEN A.StateName = 'Québerc' THEN Cie.CompanyName 
				WHEN A.StateName = 'Quéibec' THEN Cie.CompanyName 
				WHEN A.StateName = 'Qujébec' THEN Cie.CompanyName 
				WHEN A.CountryID = 'CAN' THEN 'AUTRES PROVINCES'
			ELSE 'AUTRES PAYS'
			END

	-- Cegep
	INSERT INTO @tFirstScholarshipStatistic
		SELECT
			tiSection = 3, -- Indique la section à laquelle appartient l’enregistrement (1 = Ville, 2 = Universitas et 3 = Cégep)
			tiGroupOrder = P.OrderOfPlanInReport, -- Emplacement du regroupement dans l’ordre de ceux-ci. Plus le nombre est petit, plus le groupe sera au début. 
			vcGroup = P.PlanDesc, -- Nom du regroupement (Tous les régimes, Universitas, Sélect 2000 Plan B, etc.)
			tiNameOrder = Sc.tiOrderInFirstScholarshipStatistic, -- Emplacement de l’enregistrement (ville, universités, cégep) dans le regroupement  de cette section. Plus le nombre est petit, plus il sera au début.
			vcName = 
				CASE Sc.vcSector 
					WHEN '(inconnu)' THEN 'Varia-Québec' 
				ELSE Sc.vcSector
				END, -- C’est le nom de la région du regroupement de cégeps ou de collèges communautaires.
			fUnitQty = SUM(U.UnitQty), -- Nombre d’unités.
			iCntBeneficiairy = COUNT(U.BeneficiaryID),  -- Nombre de bénéficiaire.
			fScholarship = SUM(S.ScholarshipAmount) -- Montant de bourses.
		FROM @tUnitQtyOfConv U
		JOIN Un_Scholarship S ON S.ScholarshipID = U.ScholarshipID
		JOIN @tCollegeOfScholarship C ON C.ScholarshipID = U.ScholarshipID
		JOIN Un_Plan P ON P.PlanID = U.PlanID
		JOIN Un_College Co ON Co.CollegeID = C.CollegeID
		JOIN Un_Sector Sc ON Sc.iSectorID = Co.iSectorID
		WHERE ISNULL(Co.cCollegeTypeExceptionInFirstScholarshipStatistic, Co.CollegeTypeID) IN ('02', '03', '04') -- Cegeps, collèges privés et autres établissements
		GROUP BY 
			P.OrderOfPlanInReport,
			P.PlanDesc,
			Sc.tiOrderInFirstScholarshipStatistic,
			Sc.vcSector

	-- Regroupement : Tout les régimes des trois sections
	INSERT INTO @tFirstScholarshipStatistic
		SELECT 
			tiSection, -- Indique la section à laquelle appartient l’enregistrement (1 = Ville, 2 = Universitas et 3 = Cégep)
			tiGroupOrder = 0, -- Emplacement du regroupement dans l’ordre de ceux-ci. Plus le nombre est petit, plus le groupe sera au début. 
			vcGroup = 'Tous les régimes', -- Nom du regroupement (Tous les régimes, Universitas, Sélect 2000 Plan B, etc.)
			tiNameOrder, -- Emplacement de l’enregistrement (ville, universités, cégep) dans le regroupement  de cette section. Plus le nombre est petit, plus il sera au début.
			vcName, -- C’est le nom de la région du regroupement de cégeps ou de collèges communautaires.
			fUnitQty = SUM(fUnitQty), -- Nombre d’unités.
			iCntBeneficiairy = SUM(iCntBeneficiairy),  -- Nombre de bénéficiaire.
			fScholarship = SUM(fScholarship) -- Montant de bourses.
		FROM @tFirstScholarshipStatistic
		GROUP BY
			tiSection,
			tiNameOrder,
			vcName

	SELECT
		F.tiSection, -- Indique la section à laquelle appartient l’enregistrement (1 = Ville, 2 = Universitas et 3 = Cégep)
		F.tiGroupOrder, -- Emplacement du regroupement dans l’ordre de ceux-ci. Plus le nombre est petit, plus le groupe sera au début. 
		F.vcGroup, -- Nom du regroupement (Tous les régimes, Universitas, Sélect 2000 Plan B, etc.)
		F.tiNameOrder, -- Emplacement de l’enregistrement (ville, universités, cégep) dans le regroupement  de cette section. Plus le nombre est petit, plus il sera au début.
		F.vcName, -- Si dans la section 1, c’est le nom de la ville ou de regroupement de ville. Section 2, c’est le nom de l’université ou du regroupement d’universités. Section 3, c’est le nom de la région du regroupement de cégeps ou de collèges communautaires.
		F.fUnitQty, -- Nombre d’unités.
		F.iCntBeneficiairy, -- Nombre de bénéficiaire.
		F.fScholarship, -- Montant de bourses.
		fPourcentage = 
			CASE
				WHEN T.fScholarship <= 0 THEN 0
			ELSE
				ROUND(F.fScholarship * 100 / T.fScholarship,2)
			END
	FROM @tFirstScholarshipStatistic F
	JOIN (
		SELECT 
			tiSection,
			tiGroupOrder,
			fScholarship = SUM(fScholarship)
		FROM @tFirstScholarshipStatistic
		GROUP BY
			tiSection,
			tiGroupOrder
			) T ON T.tiSection = F.tiSection AND T.tiGroupOrder = F.tiGroupOrder
	ORDER BY
		F.tiSection, -- Indique la section à laquelle appartient l’enregistrement (1 = Ville, 2 = Universitas et 3 = Cégep)
		F.tiGroupOrder, -- Emplacement du regroupement dans l’ordre de ceux-ci. Plus le nombre est petit, plus le groupe sera au début. 
		F.vcGroup, -- Nom du regroupement (Tous les régimes, Universitas, Sélect 2000 Plan B, etc.)
		F.tiNameOrder, -- Emplacement de l’enregistrement (ville, universités, cégep) dans le regroupement  de cette section. Plus le nombre est petit, plus il sera au début.
		F.vcName -- Si dans la section 1, c’est le nom de la ville ou de regroupement de ville. Section 2, c’est le nom de l’université ou du regroupement d’universités. Section 3, c’est le nom de la région du regroupement de cégeps ou de collèges communautaires.
    */
END