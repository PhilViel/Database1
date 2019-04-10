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
Nom                 :	SL_UN_NegativeCESGOrIntOnCESG_IR
Description         :	Recherche d'anomalies : Retourne les conventions avec un solde négatif de SCEE, de SCEE+, du 
						BEC, d'intérêt SCEE, d’intérêt SCEE+ ou d’intérêt BEC.
Valeurs de retours  :	
						Dataset de données
							ObjectCodeID 				INTEGER			ID unique de l'objet
							IrregularityLevel			TINYINT			Degrée de gravité
							ObjectType					VARCHAR(75)		Type d'objet (TUn_Convention, TUn_Subscriber, TUn_Beneficairy, etc.)
							No convention				VARCHAR(75)		Numéro de la convention.
							Souscripteur				VARCHAR(87)		Prénom et nom du souscripteur séparé par une espace.
							SCEE						MONEY			Solde de SCEE et de SCEE + de la convention.
							BEC							MONEY			Solde du BEC de la convention.
							Int. PCEE					MONEY			Solde d’intérêt SCEE, d’intérêt SCEE + et d’intérêt BEC de la convention.
		
Note                :	ADX0000746	IA	2005-06-14	Bruno Lapointe		Création
						ADX0001201	IA	2006-11-16	Bruno Lapointe		Adaptation PCEE 4.3 : 12.099.02.07.
						ADX0001243	IA	2007-02-21	Alain Quirion		Modification : Ajout des colonnes No convention, Souscripteur, SCEE, BEC' Int. PCEE et suppression de la colonne Description
						ADX00		BR	2007-05-22	Alain Quirion		Modification : Un_CESP au lieu de Un_CESP900
                                        2018-01-19  Pierre-Luc Simard   N'est plus utilisé
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_NegativeCESGOrIntOnCESG_IR] (
	@SearchType CHAR(3),		-- Type de recherche ('Lvl'= Gravité, 'Obj'= Type d'objet,'ALL' = Aucun)
	@Search VARCHAR(75))		-- String recherché
AS
BEGIN
    
    SELECT 1/0
    /*
	CREATE TABLE #tGlobalConventionAmount (
		ConventionID INTEGER PRIMARY KEY,
		fCESG MONEY NOT NULL,
		fCLB MONEY NOT NULL,
		fIntCESP MONEY NOT NULL )

	CREATE TABLE #tConventionAmount (
		ConventionID INTEGER PRIMARY KEY,
		fCESG MONEY NOT NULL,
		fCLB MONEY NOT NULL,
		fIntCESP MONEY NOT NULL )

	INSERT INTO #tConventionAmount
		SELECT
			ConventionID,
			SUM(fCESG),
			SUM(fCLB),
			SUM(fIntCESP)
		FROM (
			-- Conventions avec un solde SCEE, SCEE+ ou BEC négatif
			SELECT 
				CE.ConventionID,
				fCESG = SUM(CE.fCESG+CE.fACESG),
				fCLB = SUM(CE.fCLB),
				fIntCESP = 0
			FROM Un_CESP CE
			GROUP BY 
				CE.ConventionID
			HAVING SUM(CE.fCESG+CE.fACESG) < 0 -- Total de SCEE est négatif
					OR SUM(CE.fCLB) < 0
			---------
			UNION ALL
			---------
			--Conventions avec un solde d'intérêt SCEE négatif (INS)
			SELECT 
				CO.ConventionID, 
				fCESG = 0,
				fCLB = 0,
				fIntCESP = SUM(CO.ConventionOperAmount)
			FROM Un_ConventionOper CO
			WHERE CO.ConventionOperTypeID = 'INS'
			GROUP BY CO.ConventionID
			HAVING SUM(CO.ConventionOperAmount) < 0 -- Total de l'intérêt est négatif
			---------
			UNION ALL
			---------
			-- Conventions avec un solde d'intérêt SCEE+ négatif (IS+)
			SELECT 
				CO.ConventionID, 
				fCESG = 0,
				fCLB = 0,
				fIntCESP = SUM(CO.ConventionOperAmount)
			FROM Un_ConventionOper CO
			WHERE CO.ConventionOperTypeID = 'IS+'
			GROUP BY CO.ConventionID
			HAVING SUM(CO.ConventionOperAmount) < 0 -- Total de l'intérêt est négatif
			---------
			UNION ALL
			---------
			-- Conventions avec un solde d'intérêt BEC négatif (IBC)
			SELECT 
				CO.ConventionID, 
				fCESG = 0,
				fCLB = 0,
				fIntCESP = SUM(CO.ConventionOperAmount)
			FROM Un_ConventionOper CO
			WHERE CO.ConventionOperTypeID = 'IBC'
			GROUP BY CO.ConventionID
			HAVING SUM(CO.ConventionOperAmount) < 0 -- Total de l'intérêt est négatif
			) V
		GROUP BY ConventionID

	INSERT INTO #tGlobalConventionAmount
		SELECT 
				V.ConventionID,
				SUM(fCESG),
				SUM(fCLB),
				SUM(fIntCESP)				
		FROM (
			SELECT 
				CE.ConventionID,
				fCESG = SUM(CE.fCESG+CE.fACESG),
				fCLB = SUM(CE.fCLB),
				fIntCESP = 0
			FROM Un_CESP CE
			JOIN #tConventionAmount tCA ON tCA.ConventionID = CE.ConventionID
			GROUP BY CE.ConventionID
			---------
			UNION ALL
			---------
			SELECT 
				CO.ConventionID, 
				fCESG = 0,
				fCLB = 0,
				fIntCESP = SUM(CO.ConventionOperAmount)
			FROM Un_ConventionOper CO
			JOIN #tConventionAmount tCA ON tCA.ConventionID = CO.ConventionID
			WHERE CO.ConventionOperTypeID IN ('IBC', 'IS+', 'INS')
			GROUP BY CO.ConventionID) V
		GROUP BY V.ConventionID

	UPDATE #tConventionAmount
	SET fCESG = GA.fCESG,
		fCLB = GA.fCLB,
		fIntCESP = GA.fIntCESP
	FROM #tConventionAmount
	JOIN #tGlobalConventionAmount GA ON GA.ConventionID = #tConventionAmount.ConventionID

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
					WHEN CS.fCESG+CS.fCLB+CS.fIntCESP > -1.00 THEN 1
					WHEN CS.fCESG+CS.fCLB+CS.fIntCESP > -10.00 THEN 2
					WHEN CS.fCESG+CS.fCLB+CS.fIntCESP > -100.00 THEN 3
					WHEN CS.fCESG+CS.fCLB+CS.fIntCESP > -500.00 THEN 4
					ELSE 5
				END,
			ObjectType = 'TUnConvention',  
			[No convention] = C.ConventionNo,
			[Souscripteur] = H.LastName + ', ' + H.FirstName,
			[État] = Cst.ConventionStateName,
			[SCEE] = CS.fCESG, 
			[BEC] = CS.fCLB,
			[Int. PCEE] = CS.fIntCESP
		FROM #tConventionAmount CS
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
		WHERE Cst.ConventionStateName = 'RÉÉÉ'
		) V 
	WHERE 
		CASE @SearchType 
			WHEN 'Lvl' THEN CAST(V.IrregularityLevel AS VARCHAR)
			WHEN 'Obj' THEN V.ObjectType
			ELSE''
		END LIKE @Search		
	ORDER BY
		IrregularityLevel,
		[No convention],
		[Souscripteur],
		[SCEE]		
    */
END