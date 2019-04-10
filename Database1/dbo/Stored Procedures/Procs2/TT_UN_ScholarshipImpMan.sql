/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************    */

/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	TT_UN_ScholarshipImpMan
Description         :	Traitement d’importation manuel de convention aux bourses.  Il fera ceci :
									-	Création des bourses.  La première aura le statut admissible et les autres seront en réserve. 
									-	La première bourse apparaîtra dans la liste à l’étape #1.
Valeurs de retours  :	@ReturnValue :
									>0 = Pas d’erreur
									<=0 = Erreur SQL
Note                :	ADX0000704	IA	2005-07-05	Bruno Lapointe		Création
								ADX0001777	BR	2005-11-25	Bruno Lapointe		Insert un enregistrement dans la table contenant 
																							les valeurs unitaires si la convention importé 
																							n'est pas un plan déjà géré.
								ADX0002043	UR	2006-05-29	Bruno Lapointe		Modification de la condition de création des 
																							valeurs unitaires (Un_PlanValues)
                                                2017-09-27  Pierre-Luc Simard   Deprecated - Cette procédure n'est plus utilisée

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_ScholarshipImpMan] (
	@ConnectID INTEGER, -- ID unique de l’usager qui a lancé l’importation.
	@ConventionIDs INTEGER ) -- ID du blob contenant les ConventionID séparés par des « , » des conventions qu’il faut traiter.
AS
BEGIN

    SELECT 1/0
    /*
	DECLARE
		@iResult INTEGER,
		@iScholarshipYear INTEGER

	SET @iResult = 1

	SELECT @iScholarshipYear = MAX(ScholarshipYear)
	FROM Un_Def

	-----------------
	BEGIN TRANSACTION
	-----------------

	-- Crée les bourses pour les conventions.  La première bourse a le statut « Admissible » et les autres « En réserve »
	IF @iResult > 0
	BEGIN
		-- Met à jour les champs d'historique des conventions à importer
		UPDATE dbo.Un_Convention 
		SET
			ScholarshipYear = @iScholarshipYear,
			ScholarshipEntryID = 'G'
		WHERE ConventionID IN 
				(
				SELECT 
					Val
				FROM dbo.FN_CRQ_BlobToIntegerTable(@ConventionIDs)
				)

		IF @@ERROR <> 0
			SET @iResult = -1
	END

	IF @iResult > 0
	BEGIN
		-- Crée les nouvelles bourses
		DECLARE
			@iScholarshipNo INTEGER,
			@iMaxScholarshipNo INTEGER

		SET @iScholarshipNo = 1

		-- Table temporaire contenant toutes les conventions pour lesquelles on doit créer des bourses et le 
		-- nombre de bourses à créer.
		CREATE TABLE #NewScholarship (
			iConventionID INTEGER PRIMARY KEY,
			iPlanScholarshipQty INTEGER )
		INSERT INTO #NewScholarship
			SELECT 
				C.ConventionID,
				P.PlanScholarshipQty
			FROM dbo.Un_Convention C
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			JOIN dbo.FN_CRQ_BlobToIntegerTable(@ConventionIDs) V ON V.Val = C.ConventionID
			WHERE C.ConventionID NOT IN 
					(
					SELECT DISTINCT ConventionID
					FROM Un_Scholarship
					)

		-- Va chercher le plus grand nombre de bourse à créer
		SET @iMaxScholarshipNo = 0
		SELECT @iMaxScholarshipNo = MAX(iPlanScholarshipQty)
		FROM #NewScholarship

		-- Boucle pour crée en ordre les bourses (1, 2, 3, etc.)
		WHILE @iScholarshipNo <= @iMaxScholarshipNo
			AND @iResult > 0
		BEGIN
			INSERT INTO Un_Scholarship (
					ConventionID,
					ScholarshipNo,
					ScholarshipStatusID,
					ScholarshipAmount,
					YearDeleted)
				SELECT
					iConventionID,
					@iScholarshipNo,
					CASE @iScholarshipNo
						WHEN 1 THEN 'ADM'
					ELSE 'RES'
					END,
					0,
					0
				FROM #NewScholarship
				WHERE @iScholarshipNo <= iPlanScholarshipQty

			-- Passe au prochain numéro de bourse
			SET @iScholarshipNo = @iScholarshipNo + 1

			IF @@ERROR <> 0
				SET @iResult = -2
		END
		DROP TABLE #NewScholarship
	END

	-- Insére le premier enregistrement de l’historique des étapes de paiement de bourses 
	IF @iResult > 0
	BEGIN
		INSERT INTO Un_ScholarshipStep (
				ScholarshipID,
				iScholarshipStep,
				dtScholarshipStepTime,
				ConnectID )
			SELECT
				S.ScholarshipID,
				1,
				GETDATE(),
				@ConnectID
			FROM Un_Scholarship S
			JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
			JOIN dbo.FN_CRQ_BlobToIntegerTable(@ConventionIDs) V ON V.Val = C.ConventionID
			WHERE S.ScholarshipStatusID = 'ADM'

		IF @@ERROR <> 0
			SET @iResult = -3
	END

	-- Insére un enregistrement dans la table contenant les valeurs unitaires pour chaque régime et numéro
	-- de bourse à l’année de qualification traitée pour lesquelles il y aura au moins une bourse
	-- admissible à la fin du traitement.
	IF @iResult > 0
	BEGIN
		-- Insertion de la valeur unitaire
		INSERT INTO Un_PlanValues (
				PlanID, -- ID unique du plan.
				ScholarshipYear, -- Année de bourse.
				ScholarshipNo, -- Numéro de bourse.
				UnitValue ) -- Valeur de la bourse par unité
			SELECT DISTINCT
				P.PlanID,
				@iScholarshipYear,
				S.ScholarshipNo,
				0
			FROM Un_Plan P
			JOIN dbo.Un_Convention C ON C.PlanID = P.PlanID
			JOIN Un_Scholarship S ON S.ConventionID = C.ConventionID AND S.ScholarshipStatusID IN ('ADM', 'RES')
			LEFT JOIN Un_PlanValues V ON V.PlanID = P.PlanID AND V.ScholarshipYear = @iScholarshipYear AND V.ScholarshipNo = S.ScholarshipNo
			WHERE C.ScholarshipYear <= @iScholarshipYear
				AND P.PlanTypeID = 'COL'
				AND V.PlanID IS NULL -- Pas déjà existant.

		IF @@ERROR <> 0
			SET @iResult = -4
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