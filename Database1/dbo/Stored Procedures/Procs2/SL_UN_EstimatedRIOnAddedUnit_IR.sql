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
Nom                 :	SL_UN_EstimatedRIOnAddedUnit_IR
Description         :	Recherche d'anomalies : Retrouver le numéro de convention et le nom du souscripteur pour les 
						conventions dont :
											-	dont la date de RI estimée d'un ajout d'unité est différente de la date de RI estimé du
												premier groupe d'unités de la convention
Valeurs de retours  :	Dataset de données
							ObjectCodeID 			INTEGER			ID unique de l'objet
							IrregularityLevel		TINYINT			Degrée de gravité
							ObjectType				VARCHAR(75)		Type d'objet (TUn_Convention, TUn_Subscriber, TUn_Beneficairy, etc.)
							No convention			VARCHAR(75)		Numéro de la convention
							Date RI convention		DATETIME		Date de remboursement intégral estimée du premier groupe d’unités.
							Date RI ajout			DATETIME		Date de remboursement intégral estimée du groupe d’unités ajouté.

Note                :		ADX0000047	BR	2004-06-14	Bruno Lapointe		Création
							ADX0000496	IA	2005-02-04	Bruno Lapointe		Normalisation et enlever le paramètre ConnectID
							ADX0001114	IA	2006-11-20	Alain Quirion		Gestion des deux périodes de calcul de date estimée de RI (FN_UN_EstimatedIntReimbDate)
							ADX0001243	IA	2007-02-21	Alain Quirion		Modification : Ajout des colonnes No convention, Date RI convention, Date RI ajout et suppression de la colonne Description
                                            2018-01-19  Pierre-Luc Simard   N'est plus utilisé
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_EstimatedRIOnAddedUnit_IR] (
	@SearchType CHAR(3), -- Type de recherche ('Lvl'= Gravité, 'Obj'= Type d'objet,'ALL' = Aucun)
	@Search VARCHAR(75)) -- string recherché 
AS
BEGIN
    
    SELECT 1/0
    /*
	SELECT 
		ObjectCodeID,
		IrregularityLevel,
		ObjectType,
		[No convention],
		[État],
		[Date RI convention],
		[Date RI ajout]
	FROM (
		SELECT DISTINCT
			ObjectCodeID = C.ConventionID,			
			IrregularityLevel = 
				CASE
					WHEN dbo.fn_Un_EstimatedIntReimbDate(MF.PmtByYearID, MF.PmtQty, MF.BenefAgeOnBegining, UF.InForceDate, PF.IntReimbAge, UF.IntReimbDateAdjust) > 
						  dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, U.IntReimbDateAdjust) THEN 1
				ELSE 5
				END,
			ObjectType = 'TUnConvention',
			[No convention] = C.ConventionNo,
			[État] = Cst.ConventionStateName,
			[Date RI convention] = dbo.fn_Un_EstimatedIntReimbDate(MF.PmtByYearID, MF.PmtQty, MF.BenefAgeOnBegining, UF.InForceDate, PF.IntReimbAge, UF.IntReimbDateAdjust),
			[Date RI ajout] = dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, U.IntReimbDateAdjust) 
		FROM dbo.Un_Unit U
		JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
		JOIN (
				SELECT
						ConventionID,
						ConventionConventionStateID = MAX(ConventionConventionStateID)
				FROM Un_ConventionConventionState
				GROUP BY ConventionID) CCS1 ON CCS1.COnventionID = C.ConventionID
		JOIN Un_ConventionConventionState CCS2 ON CCS1.ConventionConventionStateID = CCS2.ConventionConventionStateID
		JOIN Un_ConventionState CSt ON Cst.ConventionStateID = CCS2.ConventionStateID
		JOIN Un_Modal M ON M.ModalID = U.ModalID
		JOIN Un_Plan P ON P.PlanID = M.PlanID
		JOIN (
			SELECT 
				I.ConventionID,
				UnitID = MIN(UnitID),	
				I.InForceDate
			FROM dbo.Un_Unit U
			JOIN (	
				SELECT 
					ConventionID,
					InForceDate = MIN(InForceDate)
				FROM dbo.Un_Unit 
				WHERE ISNULL(TerminatedDate,0) < 1
				GROUP BY ConventionID
				) I ON I.ConventionID = U.ConventionID AND I.InForceDate = U.InForceDate
			WHERE ISNULL(U.TerminatedDate,0) < 1
			GROUP BY 
				I.ConventionID,
				I.InForceDate
			) I ON I.ConventionID = U.ConventionID AND U.InForceDate > I.InForceDate
		JOIN dbo.Un_Unit UF ON UF.UnitID = I.UnitID
		JOIN Un_Modal MF ON MF.ModalID = UF.ModalID
		JOIN Un_Plan PF ON PF.PlanID = MF.PlanID
		WHERE ISNULL(U.TerminatedDate,0) < 1
			AND ISNULL(UF.TerminatedDate,0) < 1
			AND ISNULL(U.IntReimbDate,0) < 1
			AND ISNULL(UF.IntReimbDate,0) < 1
			AND dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, U.IntReimbDateAdjust)
				<> dbo.fn_Un_EstimatedIntReimbDate(MF.PmtByYearID, MF.PmtQty, MF.BenefAgeOnBegining, UF.InForceDate, PF.IntReimbAge, UF.IntReimbDateAdjust)
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
		[Date RI convention]
    */
END