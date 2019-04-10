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
Nom                 :	IU_UN_PlanValues
Description         :	Procédure de sauvegarde d’ajout modification de valeur unitaire.
Valeurs de retours  :	@ReturnValue :
									>0 = Pas d’erreur
									<=0 = Erreur SQL
Note                :	ADX0000704	IA	2005-07-05	Bruno Lapointe		Création
						ADX0001778	BR	2005-11-25	Bruno Lapointe		Mise à jour des montants de bourses avec les 
																		nouvelles valeurs unitaires.
										2010-10-04	Steve Gouin			Gestion des disable trigger par #DisableTrigger
                                        2017-09-27  Pierre-Luc Simard   Deprecated - Cette procédure n'est plus utilisée

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_PlanValues] (
	@ConnectID INTEGER, -- ID unique de l’usager qui a coché les groupes d’unités.
	@PlanID INTEGER, -- ID unique du plan.
	@ScholarshipYear INTEGER, -- Année de bourse.
	@ScholarshipNo INTEGER, -- Numéro de bourse.
	@UnitValue MONEY) -- Valeur de la bourse par unité 
AS
BEGIN
    
    SELECT 1/0
    /*
	DECLARE
		@iResult INTEGER

	SET @iResult = @PlanID
	-----------------
	BEGIN TRANSACTION
	-----------------

	IF NOT EXISTS (
		SELECT PlanID
		FROM Un_PlanValues
		WHERE PlanID = @PlanID
			AND ScholarshipYear = @ScholarshipYear
			AND ScholarshipNo = @ScholarshipNo
		)
	BEGIN
		-- Insertion de la valeur unitaire
		INSERT INTO Un_PlanValues (
			PlanID, -- ID unique du plan.
			ScholarshipYear, -- Année de bourse.
			ScholarshipNo, -- Numéro de bourse.
			UnitValue ) -- Valeur de la bourse par unité 
		VALUES (
			@PlanID,
			@ScholarshipYear,
			@ScholarshipNo,
			@UnitValue )

		IF @@ERROR <> 0
			SET @iResult = -1
	END
	ELSE
	BEGIN
		-- Modification de la valeur unitaire
		UPDATE Un_PlanValues
		SET UnitValue = @UnitValue
		WHERE PlanID = @PlanID
			AND ScholarshipYear = @ScholarshipYear
			AND ScholarshipNo = @ScholarshipNo

		IF @@ERROR <> 0
			SET @iResult = -2
	END

	IF @iResult > 0
	BEGIN
		--ALTER TABLE Un_Scholarship
		--	DISABLE TRIGGER TUn_Scholarship_State
		IF object_id('tempdb..#DisableTrigger') is null
			CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))

		INSERT INTO #DisableTrigger VALUES('TUn_Scholarship_State')				
	
		-- Met à jour les bourses
		UPDATE Un_Scholarship 
		SET
			ScholarshipAmount = ROUND(V.UnitQty * @UnitValue,2)
		FROM Un_Scholarship 
		JOIN dbo.Un_Convention C ON C.ConventionID = Un_Scholarship.ConventionID
		JOIN VUn_UnitByConvention V ON V.ConventionID = C.ConventionID
		WHERE Un_Scholarship.ScholarshipStatusID IN ('ADM','RES','TPA','WAI')
			AND C.PlanID = @PlanID
			AND Un_Scholarship.ScholarshipNo = @ScholarshipNo
			AND Un_Scholarship.ScholarshipAmount <> ROUND(V.UnitQty * @UnitValue,2)
	
		--ALTER TABLE Un_Scholarship
		--	ENABLE TRIGGER TUn_Scholarship_State
		Delete #DisableTrigger where vcTriggerName = 'TUn_Scholarship_State'

		IF @@ERROR <> 0
			SET @iResult = -3
	END

	IF @iResult > 0
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
		--------------------

	RETURN @iResult
    */
END