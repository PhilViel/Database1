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
Nom                 :	TT_UN_EstimatedRIOnAddedUnit_IR
Description         :	Correction d'anomalies : 
						Corrige les conventions dont :
									- la date de RI estimée d'un ajout d'unité est différente de la date de RI estimé du premier groupe d'unités de la convention
Valeurs de retours  :	
Note                :			
						ADX0000047	UR	2004-06-14 	Bruno Lapointe		Création
						ADX0001243	IA	2007-02-21	Alain Quirion		Modification : ajout des paramètres d'entrées @ObjectType et @iBlobID
                                        2018-01-19  Pierre-Luc Simard   N'est plus utilisé
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_EstimatedRIOnAddedUnit_IR] (
	@ConnectID INTEGER,			-- ID unique de la connection de l'usager
	@ObjectType VARCHAR(75),	-- C’est une chaîne de caractère qui identifie le type des objets. La valeur de ce champ doit être une des suivantes :
									--TUnConvention	L’objet est une convention
									--TUnSubscriber	L’objet est un souscripteur
									--TUnBeneficiary	L’objet est un bénéficiaire
	@iBlobID INTEGER)			-- ID du blob de la table CRI_Blob contenant les ID des objets (ObjectCodeID) séparés par des virgules.
AS
BEGIN	
    
    SELECT 1/0
    /*
	DECLARE @ConventionIDs TABLE(
		ConventionID INTEGER PRIMARY KEY)

	IF @ObjectType = 'TUnConvention'
	BEGIN
		INSERT INTO @ConventionIDs
			SELECT DISTINCT iVal
			FROM dbo.FN_CRI_BlobToIntegerTable(@iBlobID)
	END

	DECLARE 
		@IrregularityTypeCorrection INTEGER,
		@IrregularityTypeID INTEGER,
		@CorrectingCount INTEGER

	SET @CorrectingCount = 0
	
	SET @IrregularityTypeID = 0

	SELECT 
		@IrregularityTypeID = IrregularityTypeID
	FROM Un_IrregularityType
	WHERE CorrectingStoredProcedure = 'TT_UN_EstimatedRIOnAddedUnit_IR'

	IF @IrregularityTypeID > 0 
		AND EXISTS( SELECT ConventionID
					FROM @ConventionIDs)
	BEGIN 
		SELECT @CorrectingCount = COUNT(UnitID)
		FROM (
			SELECT DISTINCT
				U.UnitID
			FROM dbo.Un_Unit U
			JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			JOIN @ConventionIDs C2 ON C2.ConventionID = C.ConventionID
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

		IF @CorrectingCount > 0
		BEGIN
			UPDATE dbo.Un_Unit 
			SET 
				Un_Unit.IntReimbDateAdjust = dbo.fn_Un_EstimatedIntReimbDate(MF.PmtByYearID, MF.PmtQty, MF.BenefAgeOnBegining, UF.InForceDate, PF.IntReimbAge, UF.IntReimbDateAdjust)
			FROM dbo.Un_Unit 
			JOIN dbo.Un_Convention C ON C.ConventionID = Un_Unit.ConventionID
			JOIN @ConventionIDs C2 ON C2.ConventionID = C.ConventionID
			JOIN Un_Modal M ON M.ModalID = Un_Unit.ModalID
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
				) I ON I.ConventionID = Un_Unit.ConventionID AND Un_Unit.InForceDate > I.InForceDate
			JOIN dbo.Un_Unit UF ON UF.UnitID = I.UnitID
			JOIN Un_Modal MF ON MF.ModalID = UF.ModalID
			JOIN Un_Plan PF ON PF.PlanID = MF.PlanID
			WHERE ISNULL(Un_Unit.TerminatedDate,0) < 1
			  AND ISNULL(UF.TerminatedDate,0) < 1
			  AND ISNULL(Un_Unit.IntReimbDate,0) < 1
			  AND ISNULL(UF.IntReimbDate,0) < 1
			  AND dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, Un_Unit.InForceDate, P.IntReimbAge, Un_Unit.IntReimbDateAdjust)
				<> dbo.fn_Un_EstimatedIntReimbDate(MF.PmtByYearID, MF.PmtQty, MF.BenefAgeOnBegining, UF.InForceDate, PF.IntReimbAge, UF.IntReimbDateAdjust)

			IF @@ERROR = 0 
			BEGIN
				INSERT INTO Un_IrregularityTypeCorrection (
					IrregularityTypeID, 
					CorrectingStoredProcedure, 
					CorrectingCount, 
					CorrectingDate)
				VALUES (
					@IrregularityTypeID, 
					'TT_UN_EstimatedRIOnAddedUnit_IR',
					@CorrectingCount,
					GETDATE())
			END
		END
	END
    */
END