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
Nom                 :	TT_UN_ImpAutRI
Description         :	Traitement d’importation automatique des remboursements intégraux.  Il fera ceci :
									-	Incrémentera la date de RI traitée , cela aura pour effet de mettre à jour la liste de l’outil.
									-	Mettra date estimée de remboursement intégral des groupes d’unités dont cette dernière 
										sera inférieure à la nouvelle date traitée et dont le RI n’a pas encore été effectué à
										la date traitée.  Pour cela on incrémentera l’ajustement de la date estimée.
									-	Insérera le premier enregistrement de l’historique des étapes de remboursement intégral 
										(voir plus loin).
Valeurs de retours  :	@ReturnValue :
									>0 = Pas d’erreur
									<=0 = Erreur SQL

Note                :	ADX0000694	IA	2005-06-08	Bruno Lapointe		Création
			ADX0000779	UP 	2006-07-24	Bruno Lapointe		Date de début des études du bénéficiaire au prochain 1 septembre par défaut.
			ADX0001114	IA	2006-11-20	Alain Quirion		Modifier le champ dtIntReimbTreatedDate pour dtRINTollLastTreatedDate, Ajuster la date dtRINToolLastTreatedDate dans la table Un_IntReimbStep.
											                Gestion des deux périodes de calcul de date estimée de RI (FN_UN_EstimatedIntReimbDate), 
											                Ajout du champ ConventionIDs
                            2018-01-25  Pierre-Luc Simard   N'est plus utilisé
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_ImpAutRI] (
	@ConnectID INTEGER, 		-- ID unique de l’usager qui a lancé le traitement.
	@ConventionIDs INTEGER=0)	-- ID du blob contenant les conventions à importer (ID = 0 : blob vide et il faut importer toutes les conventions de la prochaine période de RI)
AS
BEGIN
    
    SELECT 1/0
    /*
	DECLARE 
		@iResult INTEGER,
		@dtRINToolLastImportedDate DATETIME

	SET @iResult = 1

	-----------------
	BEGIN TRANSACTION
	-----------------

	IF @ConventionIDs = 0	-- Augmente la dernière date d'importation seulement si l'on ne définit pas explicitement les conventions à importées
	BEGIN
		UPDATE Un_Def
		SET dtRINToolLastImportedDate = dbo.FN_UN_IncreaseReimbDate(dtRINToolLastImportedDate)
	END

	SELECT
		@dtRINToolLastImportedDate =  MAX(dtRINToolLastImportedDate)
	FROM Un_Def
	
	IF @ConventionIDs = 0
		INSERT INTO Un_IntReimbStep (
				UnitID,
				ConnectID,
				iIntReimbStep,
				dtIntReimbStepTime )
			SELECT
				U.UnitID,
				@ConnectID,
				1,
				GETDATE()
			FROM dbo.Un_Unit U
			JOIN Un_Modal M ON M.ModalID = U.ModalID
			JOIN Un_Plan P ON P.PlanID = M.PlanID
			LEFT JOIN Un_IntReimbStep U2 ON U2.UnitID = U.UnitID
			WHERE P.PlanTypeID = 'COL'
				AND U.IntReimbDate IS NULL
				AND U.TerminatedDate IS NULL
				AND @dtRINToolLastImportedDate = dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, U.IntReimbDateAdjust)
				AND U2.UnitID IS NULL --Exlcus ceux qui sont déja la
	ELSE
	BEGIN
		INSERT INTO Un_IntReimbStep (
				UnitID,
				ConnectID,
				iIntReimbStep,
				dtIntReimbStepTime )
			SELECT
				U.UnitID,
				@ConnectID,
				1,
				GETDATE()
			FROM dbo.Un_Unit U
			JOIN dbo.FN_CRI_BlobToIntegerTable(@ConventionIDs) C ON U.ConventionID = C.iVal
			JOIN Un_Modal M ON M.ModalID = U.ModalID
			JOIN Un_Plan P ON P.PlanID = M.PlanID
			LEFT JOIN Un_IntReimbStep U2 ON U2.UnitID = U.UnitID
			WHERE P.PlanTypeID = 'COL'
				AND U.IntReimbDate IS NULL
				AND U.TerminatedDate IS NULL
				AND U2.UnitID IS NULL --Exlcus ceux qui sont déja la
	END

	IF @@ERROR <> 0
		SET @iResult = -1

	IF @iResult > 0
	BEGIN
		DELETE 
		FROM Un_IntReimbBatchCheck

		IF @@ERROR <> 0
			SET @iResult = -2
	END

	-- La date de début des études sera réinitialisée au prochain premier septembre
	IF @iResult > 0
	BEGIN
		UPDATE dbo.Un_Beneficiary SET 
			StudyStart = 
				CASE 
					WHEN MONTH(GETDATE()) >= 9 THEN '09-01-' + CAST(YEAR(GETDATE())+1 AS CHAR(4))
					ELSE '09-01-' + CAST(YEAR(GETDATE()) AS CHAR(4))
				END
		WHERE BeneficiaryID IN 
			(
			SELECT DISTINCT B.BeneficiaryID
			FROM dbo.Un_Beneficiary B
			JOIN dbo.Un_Convention C ON C.BeneficiaryID = B.BeneficiaryID
			JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
			JOIN Un_Modal M ON M.ModalID = U.ModalID
			JOIN Un_Plan P ON P.PlanID = M.PlanID
			WHERE P.PlanTypeID = 'COL'
				AND U.IntReimbDate IS NULL
				AND U.TerminatedDate IS NULL
				AND @dtRINToolLastImportedDate = dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, U.IntReimbDateAdjust)
				AND B.StudyStart IS NULL
			)

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