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
Nom                 :	SL_UN_TerminatedOrOUTAndCESGOrIntCESG_IR
Description         :	Recherche d'anomalies : Retourne les conventions résiliées qui ont un solde de SCEE, de 
						SCEE+, du BEC, d'intérêt SCEE, d’intérêt SCEE+ ou d’intérêt BEC de plus de 0.00$.
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
						ADX0001243	IA	2007-02-21	Alain Quirion		Modification : Ajout des colonnes No convention, Souscripteur, SCEE, BEC, Int. PCEE et suppression de la colonne Description
						ADX00		BR	2007-05-22	Alain Quirion		Modification : Un_CESP au lieu de Un_CESP900
                                        2018-01-19  Pierre-Luc Simard   N'est plus utilisé
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_TerminatedOrOUTAndCESGOrIntCESG_IR] (
	@SearchType CHAR(3),	-- Type de recherche ('Lvl'= Gravité, 'Obj'= Type d'objet,'ALL' = Aucun)
	@Search VARCHAR(75) )	-- String recherché
AS
BEGIN
    
    SELECT 1/0
    /*
	DECLARE @tConventionTerminated TABLE (
			ConventionID INTEGER PRIMARY KEY )

	DECLARE @tConventionTerminatedWithDate TABLE (
		ConventionID INTEGER PRIMARY KEY,		
		TerminatedDate DATETIME)

	DECLARE @tConventionTerminatedWithOperTypeID TABLE(
		ConventionID INTEGER PRIMARY KEY,
		OperTypeID CHAR(3) NULL)

	INSERT INTO @tConventionTerminated
		-- Retrouve les conventions résiliées
		SELECT DISTINCT ConventionID
		FROM dbo.Un_Unit 
		WHERE TerminatedDate IS NOT NULL
			AND TerminatedDate < DATEADD(MONTH,-2,GETDATE())
			AND ConventionID NOT IN 
					(
					SELECT ConventionID
					FROM dbo.Un_Unit 
					WHERE TerminatedDate IS NULL
					) -- Conventions ayant des units résiliées mais d'autres non résiliées

	INSERT INTO @tConventionTerminatedWithDate
		SELECT 
				U.ConventionID,
				TerminatedDate = MAX(ISNULL(U.TerminatedDate,0))
		FROM @tConventionTerminated  CT
		JOIN dbo.Un_Unit U ON U.ConventionID = CT.ConventionID		
		GROUP BY U.ConventionID

	INSERT INTO @tConventionTerminatedWithOperTypeID
	SELECT 
			V.ConventionID,
			O.OperTypeID
	FROM @tConventionTerminatedWithDate CT
	JOIN (	
		SELECT
			CT.ConventionID,
			OperID = MAX(O.OperID)
		FROM @tConventionTerminatedWithDate CT			
		JOIN Un_ConventionOper CO ON CO.ConventionID = CT.ConventionID
		JOIN Un_Oper O ON O.OperID = CO.OperID
		WHERE O.OperTypeID IN ('RES', 'OUT')
		GROUP BY CT.ConventionID) V ON V.ConventionID = CT.ConventionID
	JOIN Un_Oper O ON O.OperID = V.OperID						

	CREATE TABLE #tConventionAmount (
		ConventionID INTEGER,
		fCESG MONEY NOT NULL,
		fCLB MONEY NOT NULL,
		fIntCESP MONEY NOT NULL )

	CREATE TABLE #tConventionAmountDate (
		ConventionID INTEGER,
		Before1July MONEY NOT NULL,
		After1July MONEY NOT NULL)

	INSERT INTO #tConventionAmount
		SELECT
			ConventionID,
			SUM(fCESG),
			SUM(fCLB),
			SUM(fIntCESP)
		FROM (
			-- Conventions auquelles il reste de la subvention SCEE
			SELECT 
				CE.ConventionID,
				fCESG = SUM(CE.fCESG+CE.fACESG),
				fCLB = SUM(CE.fCLB),
				fIntCESP = 0
			FROM @tConventionTerminated CS
			JOIN Un_CESP CE ON CE.ConventionID = CS.ConventionID
			GROUP BY 
				CE.ConventionID
			HAVING SUM(CE.fCESG+CE.fACESG) > 0 -- Total de SCEE est positif
				OR	SUM(CE.fCLB) > 0
			---------
			UNION ALL
			---------
			-- Conventions auxquelles il reste de l'intérêt SCEE (INS)
			SELECT 
				CO.ConventionID, 
				fCESG = 0,
				fCLB = 0,
				fIntCESP = SUM(CO.ConventionOperAmount)
			FROM @tConventionTerminated CS
			JOIN Un_ConventionOper CO ON CO.ConventionID = CS.ConventionID
			WHERE CO.ConventionOperTypeID = 'INS'
			GROUP BY CO.ConventionID
			HAVING SUM(CO.ConventionOperAmount) > 0 -- Total de l'intérêt est positif
			---------
			UNION ALL
			---------
			-- Conventions auxquelles il reste de l'intérêt SCEE+ (IS+)
			SELECT 
				CO.ConventionID, 
				fCESG = 0,
				fCLB = 0,
				fIntCESP = SUM(CO.ConventionOperAmount)
			FROM @tConventionTerminated CS
			JOIN Un_ConventionOper CO ON CO.ConventionID = CS.ConventionID
			WHERE CO.ConventionOperTypeID = 'IS+'
			GROUP BY CO.ConventionID
			HAVING SUM(CO.ConventionOperAmount) > 0 -- Total de l'intérêt est positif
			---------
			UNION ALL
			---------
			-- Conventions auxquelles il reste de l'intérêt BEC (IBC)
			SELECT 
				CO.ConventionID, 
				fCESG = 0,
				fCLB = 0,
				fIntCESP = SUM(CO.ConventionOperAmount)
			FROM @tConventionTerminated CS
			JOIN Un_ConventionOper CO ON CO.ConventionID = CS.ConventionID
			WHERE CO.ConventionOperTypeID = 'IBC'
			GROUP BY CO.ConventionID
			HAVING SUM(CO.ConventionOperAmount) > 0 -- Total de l'intérêt est positif
			) V
		GROUP BY ConventionID

	CREATE INDEX PK_tConventionAmount
	ON #tConventionAmount (ConventionID) 

	INSERT INTO #tConventionAmountDate
		SELECT
			C.ConventionID,
			Before1Juily = SUM( CASE 
									WHEN O.OperDate < '2006-007-01' THEN (CE.fCESG+CE.fACESG)
									ELSE 0
								END),
			After1Juily = SUM( CASE 
									WHEN O.OperDate >= '2006-007-01' THEN (CE.fCESG+CE.fACESG)
									ELSE 0
								END)
		FROM #tConventionAmount C
		JOIN Un_CESP CE ON CE.ConventionID = C.ConventionID
		JOIN Un_Oper O ON O.OperID = CE.OperID				
		GROUP BY C.ConventionID

	CREATE INDEX PK_tConventionAmountDateConventionID
	ON #tConventionAmountDate (ConventionID) 

	SELECT
		ObjectCodeID,
		IrregularityLevel,
		ObjectType,
		[No convention],
		[Souscripteur],
		[État],
		[SCEE], 
		[SCEE avant 1 juillet],
		[SCEE après 1 juillet],				
		[Int. PCEE],
		[Date de résiliation],
		[RES ou OUT]
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
			[SCEE avant 1 juillet] = CD.Before1July,
			[SCEE après 1 juillet] = CD.After1July,
			[Int. PCEE] = CS.fIntCESP,
			[Date de résiliation] = CT.TerminatedDate,
			[RES ou OUT] = CTOT.OperTypeID	
		FROM #tConventionAmount CS
		JOIN dbo.Un_Convention C ON CS.ConventionID = C.ConventionID
		JOIN #tConventionAmountDate CD ON CD.ConventionID = C.ConventionID	
		JOIN @tConventionTerminatedWithDate CT ON CT.ConventionID = C.ConventionID
		JOIN @tConventionTerminatedWithOperTypeID CTOT ON CTOT.ConventionID = C.ConventionID
		JOIN (
				SELECT
						C.ConventionID,
						ConventionConventionStateID = MAX(ConventionConventionStateID)
				FROM #tConventionAmount C
				JOIN Un_ConventionConventionState CCS ON CCS.ConventionID = C.ConventionID
				GROUP BY C.ConventionID) CCS1 ON CCS1.COnventionID = C.ConventionID
		JOIN Un_ConventionConventionState CCS2 ON CCS1.ConventionConventionStateID = CCS2.ConventionConventionStateID
		JOIN Un_ConventionState CSt ON Cst.ConventionStateID = CCS2.ConventionStateID
		JOIN dbo.Mo_Human H ON C.SubscriberID = H.HumanID
		) V
	WHERE 
		CASE @SearchType 
			WHEN 'Lvl' THEN CAST(V.IrregularityLevel AS VARCHAR)
			WHEN 'Obj' THEN V.ObjectType
			ELSE ''
		END LIKE @Search
	ORDER BY
		IrregularityLevel,
		[No convention],
		[Souscripteur],
		[SCEE]

	DROP TABLE #tConventionAmount
	DROP TABLE #tConventionAmountDate
    */
END