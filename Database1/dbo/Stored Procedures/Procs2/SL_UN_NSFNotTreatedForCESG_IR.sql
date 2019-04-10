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
Nom                 :	SL_UN_NSFNotTreatedForCESG_IR
Description         :	Recherche d'anomalies : Retourne les NSF qui n’ont pas été traité pour le PCEE. C’est-à-dire 
						pour lesquelles il n’y a pas remboursement de SCEE et de SCEE+ d’effectué.
Valeurs de retours  :	Dataset de données
							ObjectCodeID 				INTEGER			ID unique de l'objet
							IrregularityLevel			TINYINT			Degrée de gravité
							ObjectType					VARCHAR(75)		Type d'objet (TUn_Convention, TUn_Subscriber, TUn_Beneficairy, etc.)
							No convention				VARCHAR(75)		Numéro de la convention.
							Souscripteur				VARCHAR(87)		Prénom et nom du souscripteur séparé par une espace.
							Date SCEE					DATETIME		Date de réception de la SCEE
							SCEE à rembourser			MONEY			Montant de SCEE à rembourser (20% du montant du NSF).

Note                :	ADX0000746	IA	2005-06-20	Bruno Lapointe		Création
						ADX0001201	IA	2006-11-16	Bruno Lapointe		Adaptation PCEE 4.3 : 12.099.02.07.
						ADX0001243	IA	2007-02-21	Alain Quirion		Modification : Ajout des colonnes No convention, Souscripteur, Date effective, SCEE à rembourser et suppression de la colonne Description
                                        2018-01-19  Pierre-Luc Simard   N'est plus utilisé
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_NSFNotTreatedForCESG_IR] (
	@SearchType CHAR(3),	-- Type de recherche ('Lvl'= Gravité, 'Obj'= Type d'objet,'ALL' = Aucun)
	@Search VARCHAR(75))	-- String recherché
AS
BEGIN
    
    SELECT 1/0
    /*
	-- CotisationID des NSF sans lien 
	DECLARE @tCotisationNSFNotLink TABLE (
		CotisationID INTEGER PRIMARY KEY,
		OperID INTEGER NOT NULL )

	INSERT INTO @tCotisationNSFNotLink
		SELECT
			Ct.CotisationID,
			Ct.OperID
		FROM Un_Cotisation Ct
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		LEFT JOIN Mo_BankReturnLink BRL ON BRL.BankReturnCodeID = O.OperID
		WHERE O.OperTypeID = 'NSF'
			AND BRL.BankReturnCodeID IS NULL

	-- CotisationID des NSF avec lien
	DECLARE @tCotisationNSFLink TABLE (
		CotisationID INTEGER PRIMARY KEY,
		OperID INTEGER NOT NULL,
		UnitID INTEGER NOT NULL,
		BankReturnSourceCodeID INTEGER NOT NULL )

	INSERT INTO @tCotisationNSFLink
		SELECT
			Ct.CotisationID,
			Ct.OperID,
			Ct.UnitID,
			BRL.BankReturnSourceCodeID
		FROM Un_Cotisation Ct
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		JOIN Mo_BankReturnLink BRL ON BRL.BankReturnCodeID = O.OperID
		WHERE O.OperTypeID = 'NSF'

	-- CotisationID des NSF sans lien envoyé
	DECLARE @tCotisationNSFNotLinkSend TABLE (
		CotisationID INTEGER PRIMARY KEY )
		
	INSERT INTO @tCotisationNSFNotLinkSend
		SELECT DISTINCT -- NSF sans lien non remboursé
			Ct.CotisationID
		FROM @tCotisationNSFNotLink Ct
		JOIN Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID
		LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
		WHERE R4.iCESP400ID IS NULL
			AND G4.iReversedCESP400ID IS NULL
			AND G4.iCESP800ID IS NULL

	-- CotisationID des NSF non traité
	DECLARE @tCotisation TABLE (
		CotisationID INTEGER PRIMARY KEY )

	INSERT INTO @tCotisation
		SELECT -- NSF sans lien non remboursé
			Ct.CotisationID
		FROM @tCotisationNSFNotLink Ct
		LEFT JOIN @tCotisationNSFNotLinkSend L ON L.CotisationID = Ct.CotisationID
		WHERE	L.CotisationID IS NULL
		-----
		UNION
		-----
		SELECT -- NSF avec lien dont la source n'a pas été annulée (remboursée)
			Ct.CotisationID
		FROM @tCotisationNSFLink Ct
		JOIN Un_Cotisation Ct2 ON Ct2.OperID = Ct.BankReturnSourceCodeID AND Ct2.UnitID = Ct.UnitID
		JOIN Un_CESP400 G4 ON G4.CotisationID = Ct2.CotisationID
		LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
		WHERE	R4.iCESP400ID IS NULL
			AND G4.iReversedCESP400ID IS NULL
			AND G4.iCESP800ID IS NULL

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
				FROM dbo.Un_Convention C
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
		[SCEE à rembourser]
	FROM (
		SELECT  
			ObjectCodeID = C.ConventionID,
			IrregularityLevel = 
				CASE 
					WHEN (Ct.Cotisation+Ct.Fee)*.2 > -10.00 THEN 1
					WHEN (Ct.Cotisation+Ct.Fee)*.2 > -50.00 THEN 2
					WHEN (Ct.Cotisation+Ct.Fee)*.2 > -100.00 THEN 3
					WHEN (Ct.Cotisation+Ct.Fee)*.2 > -500.00 THEN 4
				ELSE 5
				END,
			ObjectType = 'TUnConvention',  
			[No convention] = C.ConventionNo,
			[Souscripteur] = H.LastName + ', ' + H.FirstName,
			[État] = CSt.ConventionStateName,
			[Date SCEE] = CRF.dtRead,
			[SCEE à rembourser] = (Ct.Cotisation+Ct.Fee)*0.2
		FROM @tCotisation tCt
		JOIN Un_Cotisation Ct ON Ct.CotisationID = tCt.CotisationID
		JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID	
		JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
		JOIN #tConventionState CSt ON CSt.ConventionID = C.ConventionID
		JOIN dbo.Mo_Human H ON C.SubscriberID = H.HumanID
		JOIN Un_Oper O ON O.OperID = Ct.OperID	
		LEFT JOIN Mo_BankReturnLink BRL ON BRL.BankReturnCodeID = O.OperID
		LEFT JOIN Un_Cotisation Ct2 ON Ct2.OperID = BRL.BankReturnSourceCodeID AND Ct2.UnitID = U.UnitID
		LEFT JOIN Un_CESP400 C4 ON Ct2.CotisationID = C4.CotisationID
		LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID
		LEFT JOIN Un_CESPReceiveFile CRF ON CRF.iCESPReceiveFileID = C9.iCESPReceiveFileID
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