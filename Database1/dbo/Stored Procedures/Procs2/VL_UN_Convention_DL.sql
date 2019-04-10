

/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	VL_UN_Convention_DL
Description         :	Valide si l'on peut supprimer une convention
Valeurs de retours  :	>0  : Tout à fonctionné
                     	<=0 : Erreur SQL
									-1		: Erreur à la suppression des groupes d'unités
									-2		: Erreur à la suppression du compte souscripteur
									-3		: Erreur à la suppression de la convention
									-4		: Erreur à la suppression de l'historique des états des groupes d'unités
									-5		: Erreur à la suppression des horaires de prélèvements
									-6		: Erreur à la suppression de l'historique des états de la convention
									-7		: Erreur à la suppression de l'historique de modalité de paiement
									-8		: Erreur à la suppression d'arrêt de paiement
									-9		: Erreur à l'insertion du log de suppression de la convention
									-10	: Erreur à l'insertion du log de suppression de compte bancaire de la convention
									-11   : Erreur à la suppression de l'historique des années de qualification de la convention
									-12   : Erreur à la suppression des enregistrements 400 non-expédiés
									-13   : Erreur à la suppression des enregistrements 200 non-expédiés
									-14   : Erreur à la suppression des enregistrements 100 non-expédiés
Note               :				
									2004-05-26	Bruno Lapointe	Création
					ADX0000831	IA	2006-03-20	Bruno Lapointe	Adaptation des conventions pour PCEE 4.3
					ADX0002426	BR	2007-05-22	Alain Quirion	Modification : Un_CESP au lieu de Un_CESP900							
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[VL_UN_Convention_DL] (
	@ConventionID INTEGER,
	@TypeResult INTEGER=0)
AS
BEGIN
	DECLARE @ICodeRetour INTEGER
	-- DU01 = Il y a une ou des transactions de liés sur un groupe d'unités
	-- DU02 = Il y a des commissions de liés sur un groupe d'unités
	-- DU03 = Il y a des bonis d'affaires de liés sur un groupe d'unités
	-- DU04 = Il y a une ou des résiliations de liés sur un groupe d'unités
	-- DU05 = Il y a un ou des remboursements intégral de liés sur un groupe d'unités

	-- DC01 = Il y a une ou des bourses de liés
	-- DC02 = Il y a une ou des opérations sur conventions
	-- DC03 = Il y a une ou des enregistrements 100 (Demande d'enregistrement de convention à la SCÉÉ)
	-- DC04 = Il y a une ou des enregistrements 200 (Demande d'enregistrement de bénéficiaire ou souscripteur à la SCÉÉ)
	-- DC05 = Il y a une ou des enregistrements 400 (Demande de subvention à la SCÉÉ)
	-- DC06 = Il y a une ou des envois d'enregistrements 700 (Valeur marchande de la convention envoyée à la SCÉÉ)
	-- DC07 = Il y a une ou des enregistrements 950 ( à la SCÉÉ)
	-- DC08 = Il y a de la subventions de liées

	CREATE TABLE #WngAndErr(
		Code VARCHAR(4),
		NbRecord INTEGER
	)

	-- DU01 = Il y a une ou des transactions de liés sur un groupe d'unités
	-- DU02 = Il y a des commissions de liés sur un groupe d'unités
	-- DU03 = Il y a des bonis d'affaires de liés sur un groupe d'unités
	-- DU04 = Il y a une ou des résiliations de liés sur un groupe d'unités
	-- DU05 = Il y a un ou des remboursements intégral de liés sur un groupe d'unités
	DECLARE 
		@UnitID INTEGER

	DECLARE cVL_UN_Convention_DL CURSOR FOR
		SELECT 
			UnitID
		FROM Un_Unit
		WHERE ConventionID = @ConventionID

	OPEN cVL_UN_Convention_DL

	-- Ce positionne sur le premier groupe d'unités de la convention
   FETCH NEXT FROM cVL_UN_Convention_DL
   INTO @UnitID

	-- Boucle sur les groupes d'unités de la convention pour déterminer si on peut les supprimers
	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- Valide si on peut supprimer le groupe d'unités
		INSERT INTO #WngAndErr
		EXEC VL_UN_Unit_DL @UnitID	

		
		-- Passe au prochain groupe d'unités
	   FETCH NEXT FROM cVL_UN_Convention_DL
	   INTO @UnitID
	END

	CLOSE cVL_UN_Convention_DL
	DEALLOCATE cVL_UN_Convention_DL


	-- DC01 = Il y a une ou des bourses de liés
	INSERT INTO #WngAndErr
		SELECT 
			'DC01',
			COUNT(ConventionID)
		FROM Un_Scholarship
		WHERE ConventionID = @ConventionID
		HAVING COUNT(ConventionID) > 0

	-- DC02 = Il y a une ou des opérations sur conventions
	INSERT INTO #WngAndErr
		SELECT 
			'DC02',
			COUNT(ConventionID)
		FROM Un_ConventionOper
		WHERE ConventionID = @ConventionID
		HAVING COUNT(ConventionID) > 0

	-- DC03 = Il y a une ou des enregistrements 100 (Demande d'enregistrement de convention à la SCÉÉ)
	INSERT INTO #WngAndErr
		SELECT 
			'DC03',
			COUNT(ConventionID)
		FROM Un_CESP100
		WHERE ConventionID = @ConventionID
			AND iCESPSendFileID IS NOT NULL
		HAVING COUNT(ConventionID) > 0

	-- DC04 = Il y a une ou des enregistrements 200 (Demande d'enregistrement de bénéficiaire ou souscripteur à la SCÉÉ)
	INSERT INTO #WngAndErr
		SELECT 
			'DC04',
			COUNT(ConventionID)
		FROM Un_CESP200
		WHERE ConventionID = @ConventionID
			AND iCESPSendFileID IS NOT NULL
		HAVING COUNT(ConventionID) > 0

	-- DC05 = Il y a une ou des enregistrements 400 (Demande de subvention à la SCÉÉ)
	INSERT INTO #WngAndErr
		SELECT 
			'DC05',
			COUNT(ConventionID)
		FROM Un_CESP400
		WHERE ConventionID = @ConventionID
			AND iCESPSendFileID IS NOT NULL
		HAVING COUNT(ConventionID) > 0

	-- DC06 = Il y a une ou des envois d'enregistrements 700 (Valeur marchande de la convention envoyée à la SCÉÉ)
	INSERT INTO #WngAndErr
		SELECT 
			'DC06',
			COUNT(ConventionID)
		FROM Un_CESP700
		WHERE ConventionID = @ConventionID
			AND iCESPSendFileID IS NOT NULL
		HAVING COUNT(ConventionID) > 0

	-- DC07 = Il y a une ou des enregistrements 950 ( à la SCÉÉ)
	INSERT INTO #WngAndErr
		SELECT 
			'DC07',
			COUNT(ConventionID)
		FROM Un_CESP950
		WHERE ConventionID = @ConventionID
		HAVING COUNT(ConventionID) > 0

	-- DC08 = Il y a de la subventions de liées
	INSERT INTO #WngAndErr
		SELECT  V.Code,
				NbRecord = SUM(V.NbRecord)
		FROM (
			SELECT 
				Code = 'DC08',
				NbRecord = COUNT(ConventionID)
			FROM Un_CESP900
			WHERE ConventionID = @ConventionID
			HAVING COUNT(ConventionID) > 0
			---------
			UNION ALL
			---------
			SELECT 
				Code = 'DC08',
				NbRecord = COUNT(ConventionID)
			FROM Un_CESP
			WHERE ConventionID = @ConventionID
			HAVING COUNT(ConventionID) > 0) V	
		GROUP BY V.Code
		HAVING SUM(V.NbRecord) > 0

	IF @TypeResult = 0 
	BEGIN
		SELECT *
		FROM #WngAndErr

		DROP TABLE #WngAndErr
	END
	ELSE
	BEGIN
		SELECT TOP 1 @iCodeRetour = NbRecord
		FROM #WngAndErr

		SET @iCodeRetour = @@ROWCOUNT

		DROP TABLE #WngAndErr

		RETURN @iCodeRetour
	END
	
END

