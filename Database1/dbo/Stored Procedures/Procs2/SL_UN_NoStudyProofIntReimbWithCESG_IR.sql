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
Nom                 :	SL_UN_NoStudyProofIntReimbWithCESG_IR
Description         :	Recherche d'anomalies : Retourne les conventions avec le remboursement intégral (RIN) sans 
						preuve d’inscription et pour lesquelles la SCEE, la SCEE+ ou le BEC n’a pas été retourné au 
						PCEE. Donc pour lesquelles il y a un solde de SCEE, de SCEE+ ou du BEC.
Valeurs de retours  :	
						Dataset de données
							ObjectCodeID 				INTEGER			ID unique de l'objet
							IrregularityLevel			TINYINT			Degrée de gravité
							ObjectType					VARCHAR(75)		Type d'objet (TUn_Convention, TUn_Subscriber, TUn_Beneficairy, etc.)
							No convention				VARCHAR(75)		Numéro de la convention.
							Souscripteur				VARCHAR(87)		Prénom et nom du souscripteur séparé par une espace.
							SCEE						MONEY			Solde de SCEE et de SCEE + de la convention.
							BEC							MONEY			Solde du BEC de la convention.
							
Note                :	ADX0000746	IA	2005-06-14	Bruno Lapointe		Création
						ADX0001201	IA	2006-11-16	Bruno Lapointe		Adaptation PCEE 4.3 : 12.099.02.07.
						ADX0001243	IA	2007-02-21	Alain Quirion		Modification : Ajout des colonnes No convention, Souscripteur, SCEE, BEC et suppression de la colonne Description
						ADX0002426	BR	2007-05-22	Alain Quirion		Modification : Un_CESP au lieu de Un_CESP900
                                        2018-01-19  Pierre-Luc Simard   N'est plus utilisé
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_NoStudyProofIntReimbWithCESG_IR] (
	@SearchType CHAR(3),	-- Type de recherche ('Lvl'= Gravité, 'Obj'= Type d'objet,'ALL' = Aucun)
	@Search VARCHAR(75) )	-- String recherché
AS
BEGIN
    
    SELECT 1/0
    /*
	DECLARE @tConventionRI TABLE (
		ConventionID INTEGER PRIMARY KEY )

	INSERT INTO @tConventionRI
		-- Retourne les conventions avec RIN sans preuve d'inscription
		SELECT DISTINCT
			U.ConventionID
		FROM dbo.Un_Unit U
		JOIN Un_IntReimb IR ON IR.UnitID = U.UnitID
		WHERE ISNULL(CollegeID,0) <= 0
			OR ISNULL(ProgramID,0) <= 0
			OR ISNULL(StudyStart,0) <= 0
			OR ISNULL(ProgramYear,0) <= 0
			OR ISNULL(ProgramLength,0) <= 0

	DECLARE @tConventionAmount TABLE (
		ConventionID INTEGER PRIMARY KEY,
		fCESG MONEY NOT NULL,
		fCLB MONEY NOT NULL )

	INSERT INTO @tConventionAmount
		-- Conventions avec un solde de SCEE et SCEE+ ou un solde de BEC
		SELECT 
			CE.ConventionID,
			fCESG = SUM(CE.fCESG+CE.fACESG),
			fCLB = SUM(CE.fCLB)
		FROM @tConventionRI CS
		JOIN Un_CESP CE ON CE.ConventionID = CS.ConventionID
		GROUP BY 
			CE.ConventionID
		HAVING SUM(CE.fCESG+CE.fACESG) > 0 -- Solde de SCEE et SCEE+ positif
			OR	SUM(CE.fCLB) > 0 -- Solde de BEC positif

	SELECT
		ObjectCodeID,
		IrregularityLevel,
		ObjectType,
		[No convention],
		[Souscripteur],
		[État],
		[SCEE],		
		[BEC]
	FROM (
		SELECT  
			ObjectCodeID = C.ConventionID,
			IrregularityLevel  =
				CASE 
					WHEN CA.fCESG+CA.fCLB <= 10.00 THEN 1
					WHEN CA.fCESG+CA.fCLB <= 100.00 THEN 2
					WHEN CA.fCESG+CA.fCLB <= 250.00 THEN 3
					WHEN CA.fCESG+CA.fCLB <= 500.00 THEN 4
				ELSE 5
				END,
			ObjectType = 'TUnConvention',	
			[No convention] = C.ConventionNo,
			[Souscripteur] = H.LastName + ', ' + H.FirstName,
			[État] = CSt.ConventionStateName,
			[SCEE] = CA.fCESG,
			[BEC] = CA.fCLB
		FROM @tConventionAmount CA
		JOIN dbo.Un_Convention C ON CA.ConventionID = C.ConventionID
		JOIN (
				SELECT
						C.ConventionID,
						ConventionConventionStateID = MAX(ConventionConventionStateID)
				FROM @tConventionAmount C
				JOIN Un_ConventionConventionState CCS ON CCS.ConventionID = C.ConventionID
				GROUP BY C.ConventionID) CCS1 ON CCS1.COnventionID = C.ConventionID
		JOIN Un_ConventionConventionState CCS2 ON CCS1.ConventionConventionStateID = CCS2.ConventionConventionStateID
		JOIN Un_ConventionState CSt ON CSt.ConventionStateID = CCS2.ConventionStateID	
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
    */
END