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
Nom                 :	TT_UN_CloseAutRI
Description         :	Traitement de fermeture automatique d’une période de RI.  
				-	Incrémentera la date de RI traitée, cela aura pour effet de mettre à jour la liste de l’outil.
				-	Mettra date estimée de remboursement intégral des groupes d’unités dont cette dernière sera inférieure à la nouvelle date traitée et dont le RI n’a pas encore été effectué à la date traitée.  
					Pour cela on incrémentera l’ajustement de la date estimée.

Valeurs de retours  :	@ReturnValue :
				>0 = Pas d’erreur
				<=0 = Erreur SQL

Note                :			
					ADX0001114	IA	2006-11-20	Alain Quirion		Création
									2010-10-04	Steve Gouin			Gestion des disable trigger par #DisableTrigger
		                            2018-01-25  Pierre-Luc Simard   N'est plus utilisé
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_CloseAutRI] (
	@ConnectID INTEGER) -- Identifiant unique de la connection	
AS
BEGIN

    SELECT 1/0
    /*
	DECLARE 
		@iResult INTEGER,
		@dtRINToolLastTreatedDate DATETIME,
		@Today DATETIME

	SET @iResult = 1

	BEGIN TRANSACTION

	UPDATE Un_Def
	SET dtRINToolLastTreatedDate = dbo.FN_UN_IncreaseReimbDate(dtRINToolLastTreatedDate)	

	IF @@ERROR <> 0
		SET @iResult = -1

	IF @iResult > 0
	BEGIN
		SELECT @dtRINToolLastTreatedDate = MAX(dtRINToolLastTreatedDate)
		FROM Un_Def
			
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
			JOIN Un_Modal M ON M.ModalID = Un_Unit.ModalID
			JOIN Un_Plan P ON P.PlanID = M.PlanID
			WHERE P.PlanTypeID = 'COL'
				AND Un_Unit.IntReimbDate IS NULL
				AND Un_Unit.TerminatedDate IS NULL
				AND @dtRINToolLastTreatedDate > dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, Un_Unit.InForceDate, P.IntReimbAge, Un_Unit.IntReimbDateAdjust)

		IF @@ERROR <> 0
			SET @iResult = -2
	END
	IF @iResult > 0
	BEGIN
		SELECT @dtRINToolLastTreatedDate = MAX(dtRINToolLastTreatedDate)
		FROM Un_Def

		--ALTER TABLE Un_Unit 
		--	DISABLE TRIGGER TUn_Unit_State
		IF object_id('tempdb..#DisableTrigger') is null
			CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))

		INSERT INTO #DisableTrigger VALUES('TUn_Unit_State')				
		
		UPDATE dbo.Un_Unit 
		SET IntReimbDateAdjust = @dtRINToolLastTreatedDate
		FROM dbo.Un_Unit 
		JOIN Un_Modal M ON M.ModalID = Un_Unit.ModalID
		JOIN Un_Plan P ON P.PlanID = M.PlanID
		WHERE P.PlanTypeID = 'COL'
			AND Un_Unit.IntReimbDate IS NULL
			AND Un_Unit.TerminatedDate IS NULL
			AND @dtRINToolLastTreatedDate > dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, Un_Unit.InForceDate, P.IntReimbAge, Un_Unit.IntReimbDateAdjust)

		--ALTER TABLE Un_Unit 
		--	ENABLE TRIGGER TUn_Unit_State
		Delete #DisableTrigger where vcTriggerName = 'TUn_Unit_State'

		IF @@ERROR <> 0
			SET @iResult = -3
	END	

	IF @iResult > 0
		COMMIT TRANSACTION
	ELSE
		ROLLBACK TRANSACTION

	RETURN @iResult
    */
END