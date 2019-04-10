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
Nom                 :	SL_UN_WithAmountAfterRegimeEnd_IR
Description         :	Recherche d'anomalies : Retrouver le numéro de convention et le nom du souscripteur pour les 
						conventions avec 25 ans de régime dont il reste de l'argent quelconque(épargne, frais, SCEE, intérêt de SCEE)
Valeurs de retours  :	
					Dataset :
						ObjectCodeID 			INTEGER			ID unique de l'objet
						IrregularityLevel		TINYINT			Degrée de gravité
						ObjectType				VARCHAR(75)		Type d'objet (TUn_Convention, TUn_Subscriber, TUn_Beneficairy, etc.)
						No convention			VARCHAR(75)		Numéro de la convention.
						Souscripteur			VARCHAR(87)		Prénom et nom du souscripteur séparé par une espace.

Note                :	
						ADX0000496	IA	2005-02-04	Bruno Lapointe		Création
						ADX0001243	IA	2007-02-21	Alain Quirion		Modification : Ajout des colonnes No convention et Souscripteur et suppression de la colonne Description
						ADX0002426	BR	2007-05-22	Alain Quirion		Modification : Un_CESP au lieu de Un_CESP900
						ADX0001355	IA	2007-06-06	Alain Quirion		Utilisation de dtRegEndDateAdjust en remplacement de RegEndDateAddyear
										2008-11-24	Josée Parent		Modification pour utiliser la fonction "fnCONV_ObtenirDateFinRegime"
                                        2018-01-19  Pierre-Luc Simard   N'est plus utilisé
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_WithAmountAfterRegimeEnd_IR] (
	@SearchType CHAR(3),	-- Type de recherche ('Lvl'= Gravité, 'Obj'= Type d'objet,'ALL' = Aucun)
	@Search VARCHAR(75) )	-- String recherché 
AS
BEGIN
    
    SELECT 1/0
    /*
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
			FROM Un_CESP CE
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
			FROM Un_ConventionOper CO
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
			FROM Un_ConventionOper CO 
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
			FROM Un_ConventionOper CO 
			WHERE CO.ConventionOperTypeID = 'IBC'
			GROUP BY CO.ConventionID
			HAVING SUM(CO.ConventionOperAmount) > 0 -- Solde d'intérêt positif
			) V
		GROUP BY ConventionID

	CREATE TABLE #tConventionWithCotisation(
		ConventionID INTEGER PRIMARY KEY NOT NULL,
		Amount MONEY)

	CREATE TABLE #tConventionWithFee(
		ConventionID INTEGER PRIMARY KEY NOT NULL,
		Amount MONEY)

	CREATE TABLE #tConventionWithCESP(
		ConventionID INTEGER PRIMARY KEY NOT NULL,
		Amount MONEY)

	CREATE TABLE #tConventionWithInt(
		ConventionID INTEGER PRIMARY KEY NOT NULL,
		Amount MONEY)

	CREATE TABLE #tConventionMaxAmount(
		ConventionID INTEGER PRIMARY KEY NOT NULL,
		Amount MONEY)	

	INSERT INTO #tConventionWithCotisation
		SELECT 
			U.ConventionID,
			Amount = SUM(Cotisation+Fee) --épargne et frais
		FROM dbo.Un_Unit U 
		JOIN Un_Cotisation Ct ON U.UnitID = Ct.UnitID			
		GROUP BY U.ConventionID
		HAVING SUM(Ct.Cotisation) > 0
				OR SUM(Ct.Fee) > 0
		--104 secondes

	INSERT INTO #tConventionWithFee
		SELECT 
			ConventionID,
			Amount = SUM(ConventionOperAmount)
		FROM Un_ConventionOper
		WHERE ConventionOperTypeID = 'FDI' -- frais disponibles
		GROUP BY ConventionID
		HAVING SUM(ConventionOperAmount) > 0
		--0 secondes

	INSERT INTO #tConventionWithCESP
		SELECT 
			CE.ConventionID,
			Amount = SUM(CE.fCotisationGranted) -- subvention
		FROM Un_CESP CE
		JOIN Un_Oper O ON CE.OperID = O.OperID
		JOIN Un_OperType OT ON O.OperTypeID = OT.OperTypeID
		GROUP BY CE.ConventionID 
		HAVING SUM(CE.fCotisationGranted) > 0 
		--23 secondes

	INSERT INTO #tConventionWithInt
		SELECT 
			ConventionID,
			Amount = SUM(ConventionOperAmount)
		FROM Un_ConventionOper
		WHERE ConventionOperTypeID = 'INS' -- intérêt sur subvention
		GROUP BY ConventionID 
		HAVING SUM(ConventionOperAmount) > 0
		--9 secondes	

	INSERT INTO #tConventionMaxAmount
		SELECT 
				V.ConventionID,
				MAX(V.Amount)
		FROM (
				SELECT	ConventionID,
						Amount
				FROM #tConventionWithCotisation
				---------
				UNION ALL
				---------
				SELECT	ConventionID,
						Amount
				FROM #tConventionWithFee
				---------
				UNION ALL
				---------
				SELECT	ConventionID,
						Amount
				FROM #tConventionWithCESP	
				---------
				UNION ALL
				---------
				SELECT	ConventionID,
						Amount
				FROM #tConventionWithInt) V	
		GROUP BY V.COnventionID
		--1 seconde

	DROP TABLE #tConventionWithCotisation
	DROP TABLE #tConventionWithFee
	DROP TABLE #tConventionWithCESP
	DROP TABLE #tConventionWithInt

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
			IrregularityLevel =
				CASE 
					WHEN SUM(T.Amount) < 5.00 THEN 1
					WHEN SUM(T.Amount) < 50.00 THEN 2
					WHEN SUM(T.Amount) < 100.00 THEN 3
					WHEN SUM(T.Amount) < 500.00 THEN 4
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
		JOIN dbo.Mo_Human H ON C.SubscriberID = H.HumanID
		JOIN (
			-- Date de vigueur de la convention			
			SELECT 
					U.ConventionID,
					InforceDate = MIN(U.InforceDate),
					dtInforceDateTIN = MIN(U.dtInforceDateTIN)
			FROM dbo.Un_Unit U
			GROUP BY U.ConventionID			
			) U2 ON U2.ConventionID = C.ConventionID	-- 4 sec
		JOIN #tConventionMaxAmount T ON C.ConventionID = T.ConventionID
		JOIN (
				SELECT
						ConventionID,
						ConventionConventionStateID = MAX(ConventionConventionStateID)
				FROM Un_ConventionConventionState CCS
				GROUP BY ConventionID) CCS1 ON CCS1.COnventionID = C.ConventionID
		JOIN Un_ConventionConventionState CCS2 ON CCS1.ConventionConventionStateID = CCS2.ConventionConventionStateID
		JOIN Un_ConventionState CSt ON Cst.ConventionStateID = CCS2.ConventionStateID
		WHERE (SELECT [dbo].[fnCONV_ObtenirDateFinRegime](C.ConventionID,'R',NULL)) < GETDATE() /* Avec 25 ans de régime */
		GROUP BY
			C.ConventionID,
			C.ConventionNo,
			H.FirstName,
			H.LastName,
			Cst.ConventionStateName,
			CS.fCESG,
			CS.fCLB,
			CS.fIntCESP
		) V 
	WHERE CASE @SearchType 
				WHEN 'Lvl' THEN CAST(V.IrregularityLevel AS VARCHAR)
				WHEN 'Obj' THEN V.ObjectType
				ELSE ''		-- Aucun critères de recherche
			END LIKE @Search
	ORDER BY
		IrregularityLevel,
		[No convention],
		[Souscripteur]	
	--3 secondes

	DROP TABLE #tConventionMaxAmount	
    */
END