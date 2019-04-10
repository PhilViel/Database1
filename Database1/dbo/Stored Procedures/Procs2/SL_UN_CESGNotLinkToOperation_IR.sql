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
Nom                 :	SL_UN_CESGNotLinkToOperation_IR
Description         :	Recherche d'anomalies : Retourne les conventions pour lesquelles on a reçue de la SCEE qui 
						n'est pas rattachée à une transaction.

Valeurs de retours  :	Dataset de données
							ObjectCodeID 			INTEGER			ID unique de l'objet
							IrregularityLevel		TINYINT			Degrée de gravité
							ObjectType				VARCHAR(75)		Type d'objet (TUn_Convention, TUn_Subscriber, TUn_Beneficairy, etc.)
							No convention			VARCHAR(75)		Numéro de la convention.
							Souscripteur			VARCHAR(87)		Prénom et nom du souscripteur séparé par une espace.
							Date SCEE				DATETIME		Date à laquelle on a reçu la SCEE.
							SCEE					MONEY			Solde de SCEE et de SCEE + de la convention.

Note                :	ADX0000746	IA	2005-06-21	Bruno Lapointe		Création
						ADX0001201	IA	2006-11-16	Bruno Lapointe		Adaptation PCEE 4.3 : 12.099.02.07.
						ADX0001243	IA	2007-02-21	Alain Quirion		Modification : Ajout des colonnes No convention, Souscripteur, Date reçu, SCEE et suppression de la colonne Description
						ADX0002426	BR	2007-05-22	Alain Quirion		Modification : Un_CESP au lieu de Un_CESP900
                                        2018-01-19  Pierre-Luc Simard   N'est plus utilisé
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_CESGNotLinkToOperation_IR] (
	@SearchType CHAR(3), -- Type de recherche ('Lvl'= Gravité, 'Obj'= Type d'objet,'ALL' = Aucun)
	@Search VARCHAR(75)) -- String recherché
AS
BEGIN

    SELECT 1/0
    /*
	CREATE TABLE #tCESGAmount(
		ConventionID INTEGER PRIMARY KEY,
		fCESG MONEY)

	CREATE TABLE #tCotisationFeeAmount(
		ConventionID INTEGER PRIMARY KEY,
		CotisationFee MONEY)
	
	CREATE TABLE #tConvention(
		ConventionID INTEGER PRIMARY KEY)

	INSERT INTO #tConvention
		SELECT DISTINCT C.ConventionID
		FROM dbo.Un_Convention C 	
		JOIN Un_CESP CE ON C.ConventionID = CE.ConventionID	
		JOIN Un_CESP900 C9 ON C9.iCESPID = CE.iCESPID	
		JOIN Un_Oper O ON O.OperID = CE.OperID
		JOIN Un_CESP400 G4 ON G4.iCESP400ID = C9.iCESP400ID
		WHERE O.OperTypeID = 'SUB'
			AND G4.OperID IS NULL
			AND CE.fCESG <> 0
		
	INSERT INTO #tCESGAMount
		SELECT 
			CE.ConventionID,
			fCESG = SUM(CE.fCESG+CE.fACESG)					
		FROM #tConvention C
		JOIN Un_CESP CE ON CE.ConventionID = C.ConventionID
		GROUP BY 
			CE.ConventionID

	INSERT INTO #tCotisationFeeAmount
		SELECT 
			C.ConventionID,
			CotisationFee = SUM(Ct.Cotisation+Ct.Fee)					
		FROM #tConvention C
		JOIN dbo.Un_Unit U ON C.ConventionID = U.ConventionID
		JOIN UN_Cotisation Ct ON Ct.UnitID = U.UnitID
		GROUP BY 
			C.ConventionID

	CREATE TABLE #tConventionState(
		ConventionID INTEGER PRIMARY KEY,
		ConventionStateName VARCHAR(20))

	INSERT INTO #tConventionState
		SELECT 
				C.ConventionID,
				CSt.ConventionStateName
		FROM dbo.Un_Convention C
		JOIN (
				SELECT
						C.ConventionID,
						ConventionConventionStateID = MAX(ConventionConventionStateID)
				FROM #tConvention C
				JOIN Un_ConventionConventionState CCS ON CCS.ConventionID = C.ConventionID
				GROUP BY C.ConventionID) CCS1 ON CCS1.COnventionID = C.ConventionID
		JOIN Un_ConventionConventionState CCS2 ON CCS1.ConventionConventionStateID = CCS2.ConventionConventionStateID
		JOIN Un_ConventionState CSt ON CSt.ConventionStateID = CCS2.ConventionStateID	

	SELECT
		ObjectCodeID,
		IrregularityLevel,
		ObjectType,
		[No convention],
		[Souscripteur],
		[État],
		[Date SCEE],
		[SCEE],
		[Montant déposé],
		[Reçu],
		[SCEE possible] = [Montant déposé] * 0.2,
		[Différence] = [Reçu] - ([Montant déposé] * 0.2)
	FROM (
		SELECT  
			ObjectCodeID = C.ConventionID,
			IrregularityLevel = 
				CASE 
					WHEN CE.fCESG > -10.00 THEN 1
					WHEN CE.fCESG > -50.00 THEN 2
					WHEN CE.fCESG > -100.00 THEN 3
					WHEN CE.fCESG > -500.00 THEN 4
				ELSE 5
				END,
			ObjectType = 'TUnConvention',  
			[No convention] = C.ConventionNo,
			[Souscripteur] = H.LastName + ', ' + H.FirstName,
			[État] = CSt.ConventionStateName,
			[Date SCEE] = O.OperDate,
			[SCEE] = CE.fCESG,
			[Montant déposé] = CFA.CotisationFee,
			[Reçu] = CG.fCESG
		FROM #tConvention C2
		JOIN dbo.Un_Convention C ON C.ConventionID = C2.ConventionID
		JOIN dbo.Mo_Human H ON C.SubscriberID = H.HumanID
		JOIN Un_CESP CE ON C.ConventionID = CE.ConventionID
		JOIN Un_CESP900 C9 ON C9.iCESPID = CE.iCESPID
		JOIN #tCESGAMount CG ON CG.ConventionID = C.ConventionID
		JOIN #tCotisationFeeAmount CFA ON CFA.ConventionID = C.ConventionID
		JOIN #tConventionState CSt ON CSt.ConventionID = C.ConventionID
		JOIN Un_Oper O ON O.OperID = CE.OperID
		JOIN Un_CESP400 G4 ON G4.iCESP400ID = C9.iCESP400ID
		WHERE O.OperTypeID = 'SUB'
			AND G4.OperID IS NULL
			AND CE.fCESG <> 0
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
		[Date SCEE]
    */
END