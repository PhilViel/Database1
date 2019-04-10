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
Nom                 :	SL_UN_2CESGForOneTransaction_IR
Description         :	Recherche d'anomalies : Retourne les transactions qui ont été subventionnées plus d’une fois.
						Une transaction subventionnées plus d’une fois étant une transaction pour laquelle on a  plus 
						d’un enregistrement 400 qui n’est pas annulé et pour lesquelles on a reçu un enregistrement 
						900 de réponse.
Valeurs de retours  :	Dataset de données
							ObjectCodeID 				INTEGER			ID unique de l'objet
							IrregularityLevel			TINYINT			Degrée de gravité
							ObjectType					VARCHAR(75)		Type d'objet (TUn_Convention, TUn_Subscriber, TUn_Beneficairy, etc.)
							No convention				VARCHAR(75)		Numéro de la convention.
							Souscripteur				VARCHAR(87)		Prénom et nom du souscripteur séparé par une espace.
							Date effective				DATETIME		Date effective de l’opération qui a été subventionné plus d’une fois.
							SCEE à rembourser			MONEY			Montant de SCEE à rembourser. Il s’agit d’un estimé.

Note                :	ADX0000746	IA	2005-06-14	Bruno Lapointe		Création
						ADX0001201	IA	2006-11-16	Bruno Lapointe		Adaptation PCEE 4.3 : 12.099.02.07.
						ADX0001243	IA	2007-02-21	Alain Quirion		Modification : Ajout des colonnes No convention, Souscripteur, Date effective, SCEE à rembourser et suppression de la colonne Description
						ADX00		BR	2007-05-22	Alain Quirion		Modification : Un_CESP au lieu de Un_CESP900
                                        2018-01-19  Pierre-Luc Simard   N'est plus utilisé
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_2CESGForOneTransaction_IR] (
	@SearchType CHAR(3),	-- Type de recherche ('Lvl'= Gravité, 'Obj'= Type d'objet,'ALL' = Aucun)
	@Search VARCHAR(75) )	-- String recherché
AS
BEGIN
    
    SELECT 1/0
    /*
	CREATE TABLE #tCotisation  (
		CotisationID INTEGER,
		iCnt400 INTEGER NOT NULL )

	INSERT INTO #tCotisation
		SELECT 
			G4.CotisationID,
			COUNT(G4.iCESP400ID)
		FROM Un_CESP400 G4
		LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
		WHERE G4.CotisationID IS NOT NULL
			AND R4.iCESP400ID IS NULL
			AND G4.iReversedCESP400ID IS NULL
			AND G4.iCESP800ID IS NULL
		GROUP BY G4.CotisationID
		HAVING COUNT(G4.iCESP400ID) > 1

	CREATE INDEX PK_tCotisation
	ON #tCotisation (CotisationID)

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
				FROM #tCotisation tCt
				JOIN Un_Cotisation Ct ON Ct.CotisationID = tCt.CotisationID
				JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
				JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
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
		[Type],
		[Épargne et frais],
		[Reçu],
		[Prévu (20%)],
		[Différence],
		[SCEE à retourner]
	FROM (
		SELECT  
			ObjectCodeID = C.ConventionID,
			IrregularityLevel = 
				CASE 
					WHEN T.Amount <= 10.00 THEN 1
					WHEN T.Amount <= 25.00 THEN 2
					WHEN T.Amount <= 50.00 THEN 3
					WHEN T.Amount <= 100.00 THEN 4
				ELSE 5
				END,
			ObjectType = 'TUnConvention',  
			[No convention] = C.ConventionNo,
			[Souscripteur] = H.LastName + ', ' + H.FirstName,
			[État] = CSt.ConventionStateName,
			[Date SCEE] = T.EffectDate,
			[Type] = T.OperTypeID,
			[Épargne et frais] = T.CotisationFee,
			[Reçu] = T.fCESG,
			[Prévu (20%)] = T.CotisationFee * 0.2,
			[Différence] = T.fCESG - (T.CotisationFee * 0.2),
			[SCEE à retourner] = T.Amount
		FROM dbo.Un_Convention C 
		JOIN dbo.Mo_Human H ON C.SubscriberID = H.HumanID
		JOIN (
			-- Total des subventions par convention
			SELECT 
				U.ConventionID,
				Ct.CotisationID,
				O.OperTypeID,
				Ct.EffectDate,
				CotisationFee = Ct.Cotisation + Ct.Fee,
				fCESG = SUM(ISNULL(CE.fCESG,0)+ISNULL(CE.fACESG,0)),
				Amount = SUM(ISNULL(CE.fCESG,0)+ISNULL(CE.fACESG,0))/tCt.iCnt400 * (tCt.iCnt400-1)
			FROM #tCotisation tCt
			JOIN Un_Cotisation Ct ON Ct.CotisationID = tCt.CotisationID
			JOIN Un_Oper O ON O.OperID = Ct.OperID
			JOIN Un_CESP400 C4 ON C4.CotisationID = Ct.CotisationID
			LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID
			LEFT JOIN Un_CESP CE ON CE.iCESPID = C9.iCESPID
			JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID			
			WHERE Ct.EffectDate > '1998-01-30'
			GROUP BY
				U.ConventionID,
				Ct.EffectDate,
				Ct.CotisationID,
				Ct.Cotisation,
				Ct.Fee,
				O.OperTypeID,
				tCt.iCnt400
			) T ON C.ConventionID = T.ConventionID	
		JOIN #tConventionState CSt ON CSt.ConventionID = C.ConventionID	
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