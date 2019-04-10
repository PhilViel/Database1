/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_IntReimbAdjustment
Description         :	Procédure d’insertion d’ajustements de date estimée de RI.
Valeurs de retours  :	@ReturnValue :
				>0 = Pas d’erreur
				<=0 = Erreur SQL
Note                :	ADX0000694	IA	2005-06-08	Bruno Lapointe		Création
			ADX0001114	IA	2006-11-17	Alain Quirion		Modification : Repousse la date estimé au prochain 15 septembre	
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_IntReimbAdjustment] (
	@ConnectID INTEGER, 	-- ID unique de l’usager qui a provoqué cette insertion.
	@UnitIDs INTEGER) 	-- ID du blob contenant les UnitID séparés par des « , » des groupes d’unités dont il faut incrémenter l’ajustement de la date estimé de RI.
AS
BEGIN
	DECLARE @iResult INTEGER
	
	SET @iResult = 1

	BEGIN TRANSACTION

	UPDATE dbo.Un_Unit 
	SET IntReimbDateAdjust =CAST(CASE
					WHEN MONTH(dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, Un_Unit.InForceDate, P.IntReimbAge, Un_Unit.IntReimbDateAdjust)) < 9 THEN CAST(YEAR(dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, Un_Unit.InForceDate, P.IntReimbAge, Un_Unit.IntReimbDateAdjust)) AS VARCHAR)
					ELSE CAST(YEAR(dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, Un_Unit.InForceDate, P.IntReimbAge, Un_Unit.IntReimbDateAdjust))+1 AS VARCHAR)
				END + '-09-15' AS DATETIME)					
	FROM dbo.Un_Unit 
	JOIN dbo.FN_CRQ_BlobToIntegerTable(@UnitIDs) V ON V.Val = Un_Unit.UnitID
	JOIN Un_Modal M ON M.ModalID = Un_Unit.ModalID
	JOIN Un_Plan P ON P.PlanID = M.PlanID
	JOIN Un_IntReimbStep USt ON USt.UnitID = Un_Unit.UnitID

	IF @@ERROR <> 0
		SET @iResult = -1

	IF @iResult = 1
	BEGIN
		DECLARE @Today DATETIME
			
		SET @Today = GETDATE()
		
		--On remet les unité à l'étape 1 de l'outil des RIN
		INSERT INTO UN_IntReimbStep (UnitID,
									iIntReimbStep,
									dtIntReimbStepTime,
									ConnectID)
			SELECT 
					UnitID,
					1,
					@Today,
					@ConnectID
			FROM dbo.Un_Unit 
			JOIN dbo.FN_CRQ_BlobToIntegerTable(@UnitIDs) V ON V.Val = Un_Unit.UnitID	
		
		IF @@ERROR <> 0
			SET @iResult = -2
	END

	IF @iResult = 1
		COMMIT TRANSACTION
	ELSE
		ROLLBACK TRANSACTION	

	RETURN @iResult
END


