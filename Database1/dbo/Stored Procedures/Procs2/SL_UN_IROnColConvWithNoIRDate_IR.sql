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
Nom                 :	SL_UN_IROnColConvWithNoIRDate_IR
Description         :	Recherche d'anomalies : Convention collective avec une ou des opérations de type RIN et sans
						date de RI.

Valeurs de retours  :	Dataset de données
							ObjectCodeID 			INTEGER			ID unique de l'objet
							IrregularityLevel		TINYINT			Degrée de gravité
							ObjectType				VARCHAR(75)		Type d'objet (TUn_Convention, TUn_Subscriber, TUn_Beneficairy, etc.)
							No convention			VARCHAR(75)		Numéro de la convention
							
Note                :	ADX0000496	IA	2005-02-03	Bruno Lapointe		Création
						ADX0001243	IA	2007-02-21	Alain Quirion		Modification : Ajout des colonnes No convention et suppression de la colonne Description
                                        2018-01-19  Pierre-Luc Simard   N'est plus utilisé
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_IROnColConvWithNoIRDate_IR] (
	@SearchType CHAR(3),	-- Type de recherche ('Lvl'= Gravité, 'Obj'= Type d'objet,'ALL' = Aucun)
	@Search VARCHAR(75))	-- String recherché
AS
BEGIN

    SELECT 1/0
    /*
	SELECT
		ObjectCodeID,
		IrregularityLevel,
		ObjectType,
		[No convention],
		[État]
	FROM (
		SELECT 
			ObjectCodeID = C.ConventionID, 
			IrregularityLevel = 
				CASE 
					WHEN DATEDIFF(MONTH, MAX(O.OperDate), GetDate()) > 12 THEN 5
					WHEN DATEDIFF(MONTH, MAX(O.OperDate), GetDate()) > 6 THEN 4
					WHEN DATEDIFF(MONTH, MAX(O.OperDate), GetDate()) > 3 THEN 3
					WHEN DATEDIFF(MONTH, MAX(O.OperDate), GetDate()) > 1 THEN 2
				ELSE 1
				END,
			ObjectType = 'TUnConvention',
			[No convention] = C.ConventionNo,
			[État] = CSt.ConventionStateName
		FROM dbo.Un_Convention C
		JOIN (
				SELECT
						ConventionID,
						ConventionConventionStateID = MAX(ConventionConventionStateID)
				FROM Un_ConventionConventionState
				GROUP BY ConventionID) CCS1 ON CCS1.COnventionID = C.ConventionID
		JOIN Un_ConventionConventionState CCS2 ON CCS1.ConventionConventionStateID = CCS2.ConventionConventionStateID
		JOIN Un_ConventionState CSt ON Cst.ConventionStateID = CCS2.ConventionStateID
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
		JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		JOIN Un_Plan P ON P.PlanID = C.PlanID AND P.PlanTypeID <> 'IND'
		WHERE O.OperTypeID = 'RIN'
			AND U.IntReimbDate IS NULL
		GROUP BY
			C.ConventionID,
			C.ConventionNo,
			CSt.ConventionStateName
		) V 
	WHERE CASE @SearchType
			WHEN 'Lvl' THEN CAST(V.IrregularityLevel AS VARCHAR)
			WHEN 'Obj' THEN V.ObjectType
			ELSE ''
		END LIKE @Search
	ORDER BY 
		IrregularityLevel,
		[No convention]
    */
END