/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	SL_UN_SearchBeneficiaryAddressLost
Description         :	Procédure de recherche de bénéficiaire(s) dont l’adresse perdue.
Valeurs de retours  :	
					Dataset :
							BeneficiaryID			INTEGER			ID du bénéficiaire.
							ConventionID			INTEGER			ID de la convention.
							SubscriberID			INTEGER			ID du souscripteur.
							BeneficiaryLastName		VARCHAR(50)		Nom du bénéficiaire.
							BeneficiaryFirstName	VARCHAR(35)		Prénom du bénéficiaire.
							BeneficiaryPhone1		VARCHAR(27)		Téléphone du bénéficiaire à la maison.
							BeneficiaryPhone2		VARCHAR(27)		Téléphone du bénéficiaire au bureau.
							BeneficiaryOtherTel		VARCHAR(27)		Autre téléphone du bénéficiaire.
							SubscriberLastName		VARCHAR(50)		Nom du souscripteur.
							SubscriberFirstName		VARCHAR(35)		Prénom du souscripteur.
							SubscriberPhone1		VARCHAR(27)		Téléphone du souscripteur à la maison.
							SubscriberPhone2		VARCHAR(27)		Téléphone du souscripteur au bureau.
							SubscriberOtherTel		VARCHAR(27)		Autre téléphone du souscripteur.
							BeneficiaryAge			INTEGER			Âge du bénéficiaire à la date d’entrée en vigueur de la convention.
							NbScholarshipPaid		INTEGER			Nombre de bourses payées pour la convention.
							RegEndDateAdjust		DATETIME		Date 25 ans : Date de fin de régime de la convention ajusté.

Note :			
						ADX0000706	IA	2005-07-13	Bruno Lapointe		Création
						ADX0001808	BR	2006-01-02	Bruno Lapointe		Correction de la date de fin de régime.
						ADX0001186	IA	2006-10-13	Bruno Lapointe		Age = Age actuelle du bénéficaire au lieu de l'age 
																		à la date d'entrée en vigueur de la convention.
						ADX0001355	IA	2007-06-06	Alain Quirion		Utilisation de dtRegEndDateAdjust en remplacement de RegEndDateAddyear
										2008-11-24	Josée Parent		Modification pour utiliser la fonction "fnCONV_ObtenirDateFinRegime"
										2008-12-11	Pierre-Luc Simard	Recherche par nom et prénom sans tenir compte des accents
										2010-02-16	Jean-François Gauthier Ajout du critère de recherche IDs afin de chercher avec l'identifiant du bénéficiaire
										2010-02-22	Jean-François Gauthier	Modification pour afficher uniquement les conventions actives (sans date de résiliationo)
																			dont la date du RIN est inférieure à 3 ans
																			Ajout du critère de recherche sur la date de mise en fonction de l'adresse invalide
										2010-02-25	Jean-François Gauthier	Modification afin de retourner la date de mise en fonction dans le dataset
****************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_SearchBeneficiaryAddressLost] (	
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@cSearchType CHAR(3), -- Type de recherche : FNa = Prénom nom, LNa = Nom prénom, Pho = Numéro de téléphone résidentiel, DTf(Date de mise ne fonction)
	@vcSearch VARCHAR(100) ) -- Valeur recherché selon le @cSearchType.
AS
BEGIN
	DECLARE 
		@Today DATETIME,
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceSearch SMALLINT

	SET @dtBegin = GETDATE()
	SET @Today = GETDATE()

	SELECT
		B.BeneficiaryID, -- ID du bénéficiaire.
		C.ConventionID, -- ID de la convention.
		C.SubscriberID, -- ID du souscripteur.
		BeneficiaryLastName = HB.LastName, -- Nom du bénéficiaire.
		BeneficiaryFirstName = HB.FirstName, -- Prénom du bénéficiaire.
		BeneficiaryPhone1 = ISNULL(AB.Phone1,''), -- Téléphone du bénéficiaire à la maison.
		BeneficiaryPhone2 = ISNULL(AB.Phone2,''), -- Téléphone du bénéficiaire au bureau.
		BeneficiaryOtherTel = ISNULL(AB.OtherTel,''), -- Autre téléphone du bénéficiaire.
		SubscriberLastName = HS.LastName, -- Nom du souscripteur.
		SubscriberFirstName = HS.FirstName, -- Prénom du souscripteur.
		SubscriberPhone1 = ISNULL(AdS.Phone1,''), -- Téléphone du souscripteur à la maison.
		SubscriberPhone2 = ISNULL(AdS.Phone2,''), -- Téléphone du souscripteur au bureau.
		SubscriberOtherTel = ISNULL(AdS.OtherTel,''), -- Autre téléphone du souscripteur.
		BeneficiaryAge	= dbo.fn_Mo_Age(HB.BirthDate, GETDATE()), -- Âge du bénéficiaire à la date d’entrée en vigueur de la convention.
		NbScholarshipPaid = COUNT(DISTINCT Sc.ScholarshipID), -- Nombre de bourses payées pour la convention.
		RegEndDateAdjust = (SELECT [dbo].[fnCONV_ObtenirDateFinRegime](C.ConventionID,'R',NULL)), -- Date 25 ans : Date de fin de régime de la convention.
		AB.InForce
	FROM 
		Un_Beneficiary B
		JOIN dbo.Un_Convention C ON C.BeneficiaryID = B.BeneficiaryID
		JOIN Un_Plan P ON P.PlanID = C.PlanID
		JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID
		JOIN dbo.Mo_Human HS ON C.SubscriberID = HS.HumanID
		LEFT JOIN dbo.Mo_Adr AdS ON AdS.AdrID = HS.AdrID
		JOIN dbo.Mo_Human HB ON B.BeneficiaryID = HB.HumanID
		LEFT JOIN dbo.Mo_Adr AB ON AB.AdrID = HB.AdrID
		LEFT JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
		LEFT JOIN Un_Scholarship Sc ON Sc.ConventionID = C.ConventionID AND Sc.ScholarshipStatusID = 'PAD'
	WHERE 
		B.bAddressLost = 1
		AND 
			CASE @cSearchType
				WHEN 'FNa' THEN ISNULL(HB.FirstName, '') + ', ' + ISNULL(HB.LastName, '')
				WHEN 'LNa' THEN ISNULL(HB.LastName, '') + ', ' + ISNULL(HB.FirstName, '')
				WHEN 'Pho' THEN ISNULL(AB.Phone1,0)
				WHEN 'IDs' THEN	CAST(B.BeneficiaryID AS VARCHAR(10))
				WHEN 'DTf' THEN CONVERT(VARCHAR(10), AB.InForce, 121) 
			END COLLATE French_CI_AI LIKE @vcSearch
		AND
		u.TerminatedDate IS NULL		-- AJOUT : JFG : 2010-02-22
		AND
		DATEDIFF(mm,u.IntReimbDate, GETDATE()) < 36
	GROUP BY
		B.BeneficiaryID,	-- ID du bénéficiaire.	
		C.ConventionID, -- ID de la convention.
		C.SubscriberID, -- ID du souscripteur.
		HB.LastName, -- om du bénéficiaire.
		HB.FirstName, -- Prénom du bénéficiaire.
		AB.Phone1, -- Téléphone du bénéficiaire à la maison.
		AB.Phone2, -- Téléphone du bénéficiaire au bureau.
		AB.OtherTel, -- Autre téléphone du bénéficiaire.
		HS.LastName, -- Nom du souscripteur.
		HS.FirstName, -- Prénom du souscripteur.
		AdS.Phone1, -- Téléphone du souscripteur à la maison.
		AdS.Phone2, -- Téléphone du souscripteur au bureau.
		AdS.OtherTel, -- Autre téléphone du souscripteur.
		HB.BirthDate,
		C.dtRegEndDateAdjust,
		AB.InForce
	ORDER BY 
		HB.LastName, -- om du bénéficiaire.
		HB.FirstName, -- Prénom du bénéficiaire.
		HS.LastName, -- Nom du souscripteur.
		HS.FirstName, -- Prénom du souscripteur.
		dbo.fn_Mo_Age(HB.BirthDate, GETDATE()), -- Âge du bénéficiaire à la date d’entrée en vigueur de la convention.
		(SELECT [dbo].[fnCONV_ObtenirDateFinRegime](C.ConventionID,'R',NULL)) -- Date 25 ans : Date de fin de régime de la convention.

	SET @dtEnd = GETDATE()
	SELECT @siTraceSearch = siTraceSearch FROM Un_Def

	IF DATEDIFF(SECOND, @dtBegin, @dtEnd) > @siTraceSearch
		-- Insère une trace de l'ewxécution si la durée de celle-ci a dépassé le temps minimum défini dans Un_Def.siTraceSearch.
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
				1,
				DATEDIFF(SECOND, @dtBegin, @dtEnd), -- Temps en seconde
				@dtBegin,
				@dtEnd,
				'Recherche de bénéf. avec adresse perdue par '+
					CASE @cSearchType
						WHEN 'LNa' THEN 'nom, prénom : ' 
						WHEN 'Pho' THEN 'téléphone : ' 
						WHEN 'FNa' THEN 'prénom, nom : ' 
						WHEN 'IDs' THEN 'identifiant du bénéficiaire : '
						WHEN 'DTf' THEN 'date de mise en fonction : '
					END + @vcSearch,
				'SL_UN_SearchBeneficiaryAddressLost',
				'EXECUTE SL_UN_SearchBeneficiaryAddressLost @ConnectID = '+CAST(@ConnectID AS VARCHAR)+
					', @cSearchType = '+@cSearchType+
					', @vcSearch = '+@vcSearch
END


