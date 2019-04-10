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
Copyright (c) 2003 Gestion Universitas inc
Nom 				:	SL_UN_ScholarshipPaidAndCESGOrIntCESG_IR
Description 		:	Recherche d'anomalies : Retourne les conventions dont aucune des bourses (il doit y en avoir 
						au moins une) n’a le statut « Admissible », « En réserve », « En attente » ou « À payer » et 
						pour lesquelles il reste de la SCEE, de la SCEE+, du BEC, de l'intérêt SCEE, de l’intérêt 
						SCEE+ ou de l’intérêt BEC.
Valeurs de retour	:	
						Dataset de données
							ObjectCodeID 			INTEGER			ID unique de l'objet
							IrregularityLevel		TINYINT			Degrée de gravité
							ObjectType				VARCHAR(75)		Type d'objet (TUn_Convention, TUn_Subscriber, TUn_Beneficairy, etc.)
							Souscripteur			VARCHAR(87)		Prénom et nom du souscripteur séparé par une espace.
							SCEE					MONEY			Solde de SCEE et de SCEE + de la convention.
							BEC						MONEY			Solde du BEC de la convention.
							Int. PCEE				MONEY			Solde d’intérêt SCEE, d’intérêt SCEE + et d’intérêt BEC de la convention.

Note				:	ADX0000746	IA	2005-06-14	Bruno Lapointe		Création
						ADX0001201	IA	2006-11-16	Bruno Lapointe		Adaptation PCEE 4.3 : 12.099.02.07.
						ADX0001243	IA	2007-02-21	Alain Quirion		Modification : Ajout des colonnes Souscripteur, SCEE, BEC, Int. PCEE et suppression de la colonne Description
						ADX0002426	BR	2007-05-22	Alain Quirion		Modification : Un_CESP au lieu de Un_CESP900
                                        2018-01-19  Pierre-Luc Simard   N'est plus utilisé
*************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_ScholarshipPaidAndCESGOrIntCESG_IR] (
	@SearchType CHAR(3),	-- Type de recherche ('Lvl'= Gravité, 'Obj'= Type d'objet,'ALL' = Aucun)
	@Search VARCHAR(75))	-- String recherché
AS
BEGIN

    SELECT 1/0
    /*
	DECLARE @tConventionScholarship TABLE (
		ConventionID INTEGER PRIMARY KEY )

	INSERT INTO @tConventionScholarship
		-- Retourne les conventions qui n'ont plus de bourses à verser
		SELECT DISTINCT S.ConventionID 
		FROM Un_Scholarship S
		WHERE ScholarshipStatusID IN ('PAD','DEA','REN','25Y','24Y') -- Bourse qui ne sont plus a payer 
			AND S.ConventionID NOT IN 
					(
					SELECT ConventionID
					FROM Un_Scholarship
					WHERE ScholarshipStatusID IN ('TPA','RES','WAI','ADM')
					)

	DECLARE @tConventionAmount TABLE (
		ConventionID INTEGER PRIMARY KEY,
		fCESG MONEY NOT NULL,
		fCLB MONEY NOT NULL,
		fIntCESP MONEY NOT NULL )

	INSERT INTO @tConventionAmount
		SELECT
			ConventionID,
			SUM(fCESG),
			SUM(fCLB),
			SUM(fIntCESP)
		FROM (
			-- Conventions avec un solde de SCEE et SCEE+ ou un solde de BEC
			SELECT 
				CE.ConventionID,
				fCESG = SUM(CE.fCESG+CE.fACESG),
				fCLB = SUM(CE.fCLB),
				fIntCESP = 0
			FROM @tConventionScholarship CS
			JOIN Un_CESP CE ON CE.ConventionID = CS.ConventionID
			GROUP BY 
				CE.ConventionID
			HAVING SUM(CE.fCESG+CE.fACESG) > 0 -- Solde de SCEE et SCEE+ positif
				OR	SUM(CE.fCLB) > 0 -- Solde de BEC positif
			---------
			UNION ALL
			---------
			-- Conventions avec un solde d'intérêt SCEE (INS)
			SELECT 
				CO.ConventionID, 
				fCESG = 0,
				fCLB = 0,
				fIntCESP = SUM(CO.ConventionOperAmount)
			FROM @tConventionScholarship CS
			JOIN Un_ConventionOper CO ON CO.ConventionID = CS.ConventionID
			WHERE CO.ConventionOperTypeID = 'INS'
			GROUP BY CO.ConventionID
			HAVING SUM(CO.ConventionOperAmount) > 0 -- Solde d'intérêt positif
			---------
			UNION ALL
			---------
			-- Conventions avec un solde d'intérêt SCEE+ (IS+)
			SELECT 
				CO.ConventionID, 
				fCESG = 0,
				fCLB = 0,
				fIntCESP = SUM(CO.ConventionOperAmount)
			FROM @tConventionScholarship CS
			JOIN Un_ConventionOper CO ON CO.ConventionID = CS.ConventionID
			WHERE CO.ConventionOperTypeID = 'IS+'
			GROUP BY CO.ConventionID
			HAVING SUM(CO.ConventionOperAmount) > 0 -- Solde d'intérêt positif
			---------
			UNION ALL
			---------
			-- Conventions avec un solde d'intérêt BEC (IBC)
			SELECT 
				CO.ConventionID, 
				fCESG = 0,
				fCLB = 0,
				fIntCESP = SUM(CO.ConventionOperAmount)
			FROM @tConventionScholarship CS
			JOIN Un_ConventionOper CO ON CO.ConventionID = CS.ConventionID
			WHERE CO.ConventionOperTypeID = 'IBC'
			GROUP BY CO.ConventionID
			HAVING SUM(CO.ConventionOperAmount) > 0 -- Solde d'intérêt positif
			) V
		GROUP BY ConventionID

	SELECT
		ObjectCodeID,
		IrregularityLevel,
		ObjectType,
		[No convention],
		[Souscripteur],
		[État],
		[SCEE],
		[BEC],
		[Int. PCEE]
	FROM (
		SELECT  
			ObjectCodeID = C.ConventionID,
			IrregularityLevel  =
				CASE 
					WHEN CS.fCESG+CS.fCLB+CS.fIntCESP < 1.00 THEN 1
					WHEN CS.fCESG+CS.fCLB+CS.fIntCESP < 10.00 THEN 2
					WHEN CS.fCESG+CS.fCLB+CS.fIntCESP < 50.00 THEN 3
					WHEN CS.fCESG+CS.fCLB+CS.fIntCESP < 100.00 THEN 4
					ELSE 5
				END,
			ObjectType = 'TUnConvention', 
			[No convention] = C.ConventionNo,
			[Souscripteur] = H.LastName + ', ' + H.FirstName,
			[État] = Cst.ConventionStateName,
			[SCEE] = CS.fCESG,
			[BEC] = CS.fCLB,
			[Int. PCEE] = CS.fIntCESP
		FROM @tConventionAmount CS
		JOIN dbo.Un_Convention C ON CS.ConventionID = C.ConventionID
		JOIN (
				SELECT
						ConventionID,
						ConventionConventionStateID = MAX(ConventionConventionStateID)
				FROM Un_ConventionConventionState CCS
				GROUP BY ConventionID) CCS1 ON CCS1.COnventionID = C.ConventionID
		JOIN Un_ConventionConventionState CCS2 ON CCS1.ConventionConventionStateID = CCS2.ConventionConventionStateID
		JOIN Un_ConventionState CSt ON Cst.ConventionStateID = CCS2.ConventionStateID
		JOIN dbo.Mo_Human H ON C.SubscriberID = H.HumanID
   	) V 
	WHERE 
		CASE @SearchType 
			WHEN 'Lvl' THEN CAST(V.IrregularityLevel AS VARCHAR)
			WHEN 'Obj' THEN V.ObjectType
			ELSE ''		-- Aucun critères de recherche
		END LIKE @Search
	ORDER BY
		IrregularityLevel,
		[Souscripteur],
		[SCEE]
    */
END