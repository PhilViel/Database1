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
Nom                 :	TT_UN_ScholarshipImpAut
Description         :	Traitement d’importation automatique de conventions aux bourses.  Il fera ceci :
									-	Incrémentera de un l’année de qualification traitée, cela aura pour effet de mettre à 
										jour la liste de l’outil.
									-	Réinitialisera l’information boursière contenu sur le bénéficiaire : Le champ preuve
										d’inscription, relevé de notes et cas de janvier seront mis à non (décoché).  La date
										de début des études sera réinitialisée au premier septembre de l’année de qualification
										traitée.
									-	Traitera les cas de 25 ans de régime.  Ce traitement consistera à fermer les bourses
										dont le statut sera « Admissible », « En attente », « En réserve » ou « À payer » qu’il
										sera impossible de payer avant la fin du régime.  Cela en considérant qu’on ne peut pas
										verser plus d’une bourse par année.  La fin de régime étant le 31 décembre du 25ième
										anniversaire de la convention.  La fermeture changera le statut de la bourse à « 25 ans
										de régime ».  Le système s’assurera ainsi qu’il n’y ait pas plus de bourse en statut :
										« Admissible », « En attente », « En réserve » ou « À payer » que d’années restantes
										avant la fin de régime, l’année courante incluse.  Ce fonctionnement est le même
										qu’actuellement dans UniSQL.
									-	Traitera les cas de 24 ans d’âge.  Ce traitement consistera à fermer toutes les bourses
										dont le statut sera « Admissible », « En attente » ou « En réserve » des conventions
										dont la première bourse sera dans un de ces trois statut et dont le 24ième anniversaire
										du bénéficiaire aura eu lieu avant le 1 octobre de l’année précédente.  La fermeture
										changera le statut de la bourse à « 24 ans d’âge ».
									-	Changera le statut à « Admissible » de toutes les bourses dont le statut sera « En
										attente » ou « À payer ».
									-	Créera les bourses de toutes les conventions nouvellement qualifiées.  La première
										bourse aura le statut « Admissible » et les autres « En réserve »
									-	Insérera un enregistrement dans la table contenant les valeurs unitaires pour chaque
										régime et numéro de bourse à l’année de qualification traitée pour lesquelles il y aura
										au moins une bourse admissible à la fin du traitement.
									-	Commandera tout les avis de bourses : « Avis de première bourse », « Avis de 2ième et
										3ième bourse » et « Avis de première bourse 24 ans d’âge ».  
									-	Insérera le premier enregistrement de l’historique des étapes de paiement de bourses
Valeurs de retours  :	@ReturnValue :
									>0 = Pas d’erreur
									<=0 = Erreur SQL
		
Note                :			
	ADX0000704	IA	2005-07-05	Bruno Lapointe		Création
	ADX0002043	UR	2006-05-29	Bruno Lapointe		Modification de la condition de création des valeurs unitaires 
																(Un_PlanValues)
	ADX0001355	IA	2007-06-06	Alain Quirion		Utilisation de dtRegEndDateAdjust en remplacement de RegEndDateAddYear
	ADX0001255	UP	2007-10-10	Bruno Lapointe		Probème avec le YearDeleted qui est mis avec une année de trop.
					2008-11-24	Josée Parent		Modification pour utiliser la fonction "fnCONV_ObtenirDateFinRegime"
					2010-10-04	Steve Gouin			Gestion des disable trigger par #DisableTrigger
					2011-05-02	Pierre-Luc Simard	Ne plus traiter les 24 ans d'âge et commander la lettre RP_UN_Scholarship24YearNoticeBatch
                    2017-09-27  Pierre-Luc Simard   Deprecated - Cette procédure n'est plus utilisée

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_ScholarshipImpAut] (
	@ConnectID INTEGER ) -- ID unique de l’usager qui a lancé l’importation.
AS
BEGIN
    
    SELECT 1/0
    /*
	DECLARE
		@iResult INTEGER,
		@iScholarshipYear INTEGER

	SET @iResult = 1

	-----------------
	BEGIN TRANSACTION
	-----------------

	--ALTER TABLE Un_Scholarship
	--	DISABLE TRIGGER TUn_Scholarship_State
	IF object_id('tempdb..#DisableTrigger') is null
		CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))

	INSERT INTO #DisableTrigger VALUES('TUn_Scholarship_State')				
	
	-- Incrémente de un l’année de qualification traitée, cela a pour effet de mettre à jour la liste de l’outil.
	UPDATE Un_Def
	SET 
		ScholarshipYear = ScholarshipYear + 1
	SELECT @iScholarshipYear = MAX(ScholarshipYear)
	FROM Un_Def

	IF @@ERROR <> 0
		SET @iResult = -1

	-- Exclus des rapports les bourses résiliés '24Y','25Y','DEA','REN' de l'année précédente
	IF @iResult > 0
	BEGIN
		UPDATE Un_Scholarship
		SET
			YearDeleted = @iScholarshipYear - 1
		WHERE ScholarshipStatusID IN ('24Y','25Y','DEA','REN')
			AND YearDeleted = 0

		IF @@ERROR <> 0
			SET @iResult = -2
	END

	-- Traite les cas de 25 ans de régime.  Ce traitement consiste à fermer les bourses dont le statut est 
	-- « Admissible », « En attente », « En réserve » ou « À payer » qu’il est impossible de payer avant la fin du 
	-- régime.  Cela en considérant qu’on ne peut pas verser plus d’une bourse par année.  La fin de régime étant le
	-- 31 décembre du 25ième anniversaire de la convention.  La fermeture change le statut de la bourse à « 25 ans
	-- de régime ».  Le système s’assure ainsi qu’il n’y ait pas plus de bourse en statut : « Admissible », « En
	-- attente », « En réserve » ou « À payer » que d’années restantes avant la fin de régime, l’année courante incluse.
	-- Ce fonctionnement est le même qu’actuellement dans UniSQL.
	IF @iResult > 0
	BEGIN
		UPDATE Un_Scholarship
		SET
			ScholarshipStatusID = '25Y'
		FROM Un_Scholarship S
		JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
		JOIN ( -- Date d'entrée en vigueur de la convention (Sert pour le calcul de la date de fin de régime
			SELECT
				ConventionID,
				InForceDate = MIN(InForceDate)
			FROM dbo.Un_Unit 
			GROUP BY ConventionID
			) U ON U.ConventionID = C.ConventionID
		JOIN ( -- Plus petite bourse qui n'est pas payées ou résilié.
			SELECT
				S.ConventionID,
				ScholarshipNo = MIN(S.ScholarshipNo)
			FROM Un_Scholarship S
			WHERE S.ScholarshipStatusID IN ('RES','ADM','TPA','WAI')
			GROUP BY S.ConventionID
			) N ON N.ConventionID = C.ConventionID
		WHERE (SELECT YEAR([dbo].[fnCONV_ObtenirDateFinRegime](C.ConventionID,'R',NULL))) - (S.ScholarshipNo - N.ScholarshipNo) + 1 <= @iScholarshipYear
			AND S.ScholarshipStatusID IN ('RES','ADM','TPA','WAI')
			AND S.ScholarshipID NOT IN 
					(
					SELECT DISTINCT ScholarshipID
					FROM Un_ScholarshipPmt
					)

		IF @@ERROR <> 0
			SET @iResult = -3
	END

	-- Traitera les cas de 24 ans d’âge.  Ce traitement consiste à fermer toutes les bourses dont le statut est
	-- « Admissible », « En attente » ou « En réserve » des conventions dont la première bourse est dans un de ces
	-- trois statut et dont le 24ième anniversaire du bénéficiaire a eu lieu avant le 1 octobre de l’année
	-- précédente.  La fermeture change le statut de la bourse à « 24 ans d’âge ».
	/*
	IF @iResult > 0
	BEGIN
		UPDATE Un_Scholarship
		SET
			ScholarshipStatusID = '24Y'
		FROM Un_Scholarship S
		JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
		JOIN dbo.Mo_Human H ON H.HumanID = C.BeneficiaryID
		JOIN ( -- Conventions dont la première bourse est dans un de ces trois statut : « Admissible », « En attente »
				 -- ou « En réserve »
			SELECT DISTINCT
				ConventionID
			FROM Un_Scholarship
			WHERE ScholarshipStatusID IN ('RES','ADM','WAI')
				AND ScholarshipNo = 1
			) V ON V.ConventionID = C.ConventionID
		-- le 24ième anniversaire du bénéficiaire a eu lieu avant le 1 octobre de l’année précédente
		WHERE DATEADD(YEAR, 24, H.BirthDate) < CAST(CAST(@iScholarshipYear - 1 AS CHAR(4)) + '-10-01' AS DATETIME) 

		IF @@ERROR <> 0
			SET @iResult = -4
	END
	*/

	-- Change le statut à « Admissible » de toutes les bourses dont le statut est « En attente » ou « À payer ».
	IF @iResult > 0
	BEGIN
		UPDATE Un_Scholarship
		SET ScholarshipStatusID = 'ADM'
		WHERE ScholarshipStatusID IN ('WAI','TPA')

		IF @@ERROR <> 0
			SET @iResult = -5
	END

	-- Crée les bourses de toutes les conventions nouvellement qualifiées.  La première bourse a le statut
	-- « Admissible » et les autres « En réserve »
	IF @iResult > 0
	BEGIN
		-- Met à jour les champs d'historique des conventions à importer
		UPDATE dbo.Un_Convention 
		SET
			ScholarshipYear = @iScholarshipYear,
			ScholarshipEntryID = 'A'
		WHERE ConventionID IN 
				(
				SELECT 
					C.ConventionID
				FROM dbo.Un_Convention C
				JOIN Un_Plan P ON P.PlanID = C.PlanID
				WHERE P.PlanTypeID = 'COL'
					AND C.YearQualif = @iScholarshipYear
					AND ScholarshipYear = 0
					AND C.ConventionID IN 
							(
							SELECT DISTINCT ConventionID
							FROM dbo.Un_Unit 
							WHERE TerminatedDate IS NULL
							)
				)

		IF @@ERROR <> 0
			SET @iResult = -6
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
			WHERE C.ScholarshipYear = @iScholarshipYear
				AND ScholarshipEntryID = 'A'
				AND C.ConventionID NOT IN 
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
					'RES',
					0,
					0
				FROM #NewScholarship
				WHERE @iScholarshipNo <= iPlanScholarshipQty

			-- Passe au prochain numéro de bourse
			SET @iScholarshipNo = @iScholarshipNo + 1

			IF @@ERROR <> 0
				SET @iResult = -7
		END
		DROP TABLE #NewScholarship
	END
	IF @iResult > 0
	BEGIN
		-- Met la première bourse non payé ou résilié de chaque convention "Admissible"
		UPDATE Un_Scholarship
		SET
			ScholarshipStatusID = 'ADM'
		WHERE ScholarshipID IN
				(
				SELECT 
					MIN(S.ScholarshipID)
				FROM Un_Scholarship S
				JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
				WHERE S.ConventionID NOT IN 
						(
						SELECT DISTINCT ConventionID
						FROM Un_Scholarship 
						WHERE ScholarshipStatusID IN ('ADM','WAI','TPA')
						)
					AND S.ScholarshipStatusID = 'RES'
				GROUP BY S.ConventionID
				)

		IF @@ERROR <> 0
			SET @iResult = -8
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
			SET @iResult = -9
	END

	-- Commande tout les avis de bourses : « Avis de première bourse », « Avis de 2ième et 3ième bourse » 
	-- et « Avis de première bourse 24 ans d’âge ».  
	IF @iResult > 0
	BEGIN
		-- Avis de première bourse
		EXECUTE RP_UN_Scholarship1NoticeBatch @ConnectID, 0
		-- Avis de deuxième et troisième bourse
		EXECUTE RP_UN_Scholarship2And3NoticeBatch @ConnectID, 0
		-- Avis de première bourse, 24 ans d'âge
		--EXECUTE RP_UN_Scholarship24YearNoticeBatch @ConnectID, 0

		IF @@ERROR <> 0
			SET @iResult = -10
	END

	-- Inscrit tous les historiques comme de vieux historiques. 
	IF @iResult > 0
	BEGIN
		UPDATE Un_ScholarshipStep 
		SET bOldPAE = 1

		IF @@ERROR <> 0
			SET @iResult = -11
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
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			WHERE S.ScholarshipStatusID = 'ADM'
				AND C.ScholarshipYear <= @iScholarshipYear
				AND P.PlanTypeID = 'COL'

		IF @@ERROR <> 0
			SET @iResult = -12
	END

	-- Réinitialisera l’information boursière contenu sur le bénéficiaire : Le champ preuve d’inscription, relevé de
	-- notes et cas de janvier seront mis à non (décoché).  La date de début des études sera réinitialisée au premier
	-- septembre de l’année de qualification traitée.
	IF @iResult > 0
	BEGIN
		UPDATE dbo.Un_Beneficiary SET 
			CaseOfJanuary = 0, 
			RegistrationProof = 0, 
			SchoolReport = 0 ,
			StudyStart = '09-01-' + CAST(@iScholarshipYear AS CHAR(4))
		WHERE BeneficiaryID IN 
			(
			SELECT DISTINCT C.BeneficiaryID
			FROM dbo.Un_Convention C
			JOIN Un_Scholarship S ON S.ConventionID = C.ConventionID
			WHERE S.ScholarshipStatusID IN ('RES','ADM','TPA','WAI')
			)

		IF @@ERROR <> 0
			SET @iResult = -13
	END

	-- Efface les bourses cochées précédemment
	IF @iResult > 0
	BEGIN
		DELETE
		FROM Un_ScholarshipBatchCheck

		IF @@ERROR <> 0
			SET @iResult = -14
	END

	--ALTER TABLE Un_Scholarship
	--	ENABLE TRIGGER TUn_Scholarship_State
	Delete #DisableTrigger where vcTriggerName = 'TUn_Scholarship_State'

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