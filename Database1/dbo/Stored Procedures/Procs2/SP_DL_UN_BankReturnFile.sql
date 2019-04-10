/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SP_DL_UN_BankReturnFile
Description         :	Suppression d'un fichier de retour de la banque.
Valeurs de retours  : 	>0		: Pas d'erreurs.  Correspond au Id du fichier supprimé
								<=0	: Erreurs
									0		: Pas trouver le fichier dans la base de données
									-1		: Erreurs lors de la réexpédition des 400
									-2		: Erreur lors de la désactivation de la date de blocage
									-3		: Erreur lors de la suppression des cotisations des CPA de reprise
									-4		: Erreur lors de la suppression des opérations sur conventions des CPA de reprise
									-5		: Erreur lors de la suppression des opérations des CPA de reprise
									-6		: Erreur lors de la suppression des cotisations des NSF
									-7		: Erreur lors de la suppression des opérations sur conventions des NSF
									-8		: Erreur lors de la suppression des liens des NSF
									-9		: Erreur lors de la suppression des opérations des NSF
									-10	: rreur lors de la suppression du fichier d'effets retournés
									-11	: Erreur lors de la réactivation de la date de blocage
Note                :	ADX0000479	IA	2004-10-19	Bruno Lapointe		Création
								ADX0002024	BR	2006-07-11	Bruno Lapointe		Adaptation PCEE 4.3
								ADX0001929	BR 2006-08-04	Bruno Lapointe		Supprimer les docuements liés aux NSF qui ne sont
																							pas imprimés.
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_DL_UN_BankReturnFile] (
	@ConnectID MoID, -- Id unique de la connection de l'usager
	@BankReturnFileName MoDesc) -- Id unique du fichier de retour de la banque
AS
BEGIN
	DECLARE 
		@dtLastVerifDate MoGetDate,
		@iOperID MoID,
		@iProcResult MoID,
		@iBankReturnFileID MoID

	-- Garde la date de blocage des opérations financières d'avant suppression
	SELECT 
		@dtLastVerifDate = LastVerifDate 
	FROM Un_Def

	-----------------
	BEGIN TRANSACTION
	-----------------

	SET @iBankReturnFileID = 0
	-- Va chercher le ID
	SELECT @iBankReturnFileID = BankReturnFileID
	FROM Mo_BankReturnFile F
	WHERE BankReturnFileName = @BankReturnFileName
 
	IF @iBankReturnFileID > 0
	BEGIN
		-- Crée une table contenant tous les cpas de reprise.
		SELECT DISTINCT 
			O2.OperID
		INTO #CPAToDelete
		FROM Mo_BankReturnFile F
		JOIN Mo_BankReturnLink L ON F.BankReturnFileID = L.BankReturnFileID
		JOIN Un_Oper O ON O.OperID = L.BankReturnSourceCodeID
		JOIN Un_Oper O2 ON O2.OperDate = DATEADD(MONTH, 2, O.OperDate)
		WHERE F.BankReturnFileID = @iBankReturnFileID
		  AND O2.ConnectID IN (
				SELECT 
					V2.ConnectID
				FROM (
					SELECT 
						F.BankReturnFileID, 
						O2.ConnectID, 
						NbCount = COUNT(O2.OperID)
					FROM Mo_BankReturnFile F
					JOIN Mo_BankReturnLink L ON F.BankReturnFileID = L.BankReturnFileID
					JOIN Un_Oper O ON O.OperID = L.BankReturnSourceCodeID
					JOIN Un_Cotisation Ct ON Ct.OperID = O.OperID
					JOIN Un_Oper O2 ON O2.OperDate = DATEADD(MONTH, 2, O.OperDate)
					JOIN Un_Cotisation Ct2 ON Ct2.OperID = O2.OperID
					JOIN Mo_Connect C ON C.ConnectID = O2.ConnectID
					WHERE F.BankReturnFileID = @iBankReturnFileID
					  AND Ct2.UnitID = Ct.UnitID
					GROUP BY 
						F.BankReturnFileID, 
						O2.ConnectID
					) V
				JOIN (
					SELECT 
						F.BankReturnFileID, 
						O2.ConnectID, 
						NbCount = COUNT(O2.OperID)
					FROM Mo_BankReturnFile F
					JOIN Mo_BankReturnLink L ON F.BankReturnFileID = L.BankReturnFileID
					JOIN Un_Oper O ON O.OperID = L.BankReturnSourceCodeID
					JOIN Un_Cotisation Ct ON Ct.OperID = O.OperID
					JOIN Un_Oper O2 ON O2.OperDate = DATEADD(MONTH, 2, O.OperDate)
					JOIN Un_Cotisation Ct2 ON Ct2.OperID = O2.OperID
					JOIN Mo_Connect C ON C.ConnectID = O2.ConnectID
					WHERE F.BankReturnFileID = @iBankReturnFileID
					  AND Ct2.UnitID = Ct.UnitID
					GROUP BY 
						F.BankReturnFileID, 
						O2.ConnectID
					) V2 ON V2.BankReturnFileID = V.BankReturnFileID
				GROUP BY 
					V2.ConnectID, 
					V2.NbCount
				HAVING MAX(V.NbCount) = V2.NbCount)
	
		SELECT 
			BankReturnCodeID
		INTO #OperToDelete 
		FROM Mo_BankReturnFile B
		JOIN Mo_BankReturnLink L ON B.BankReturnFileID = L.BankReturnFileID
		WHERE B.BankReturnFileID = @iBankReturnFileID
	
		-- Boucle pour réexpédier les 400 des CPA sur lesquelles étaient les NSF
		DECLARE ToDoCursor CURSOR FOR
			SELECT 
				BankReturnSourceCodeID
			FROM Mo_BankReturnFile B
			JOIN Mo_BankReturnLink L ON B.BankReturnFileID = L.BankReturnFileID
			WHERE B.BankReturnFileID = @iBankReturnFileID
	
		OPEN ToDoCursor
	
		FETCH NEXT FROM ToDoCursor INTO
			@iOperID
	
		SET @iProcResult = 1
	
		WHILE @@FETCH_STATUS = 0 
		  AND @iProcResult > 0
		BEGIN
			-- Réexpédie les 400 des CPA sur lesquelles étaient les NSF
			EXECUTE @iProcResult = IU_UN_CESP400ForOper @ConnectID, @iOperID, 11, 0
	
			FETCH NEXT FROM ToDoCursor INTO
				@iOperID
		END
	
		CLOSE ToDoCursor
		DEALLOCATE ToDoCursor
	
		-- Vérifie s'il y a eu une erreur lors de la réexpédition des 400
		IF @iProcResult <= 0
			SET @iBankReturnFileID = -1
	END

	IF @iBankReturnFileID > 0
	BEGIN
		-- Désactive la date de blocage le temps de la suppression
		UPDATE Un_Def 
		SET 
			LastVerifDate = 0

		IF @@ERROR <> 0 
			SET @iBankReturnFileID = -2
	END
			
	IF @iBankReturnFileID > 0
	BEGIN
		-- Supprimer les cotisations des CPA de reprise
		DELETE 
		FROM Un_Cotisation
		WHERE OperID IN (
					SELECT DISTINCT OperID 
					FROM #CPAToDelete)

		IF @@ERROR <> 0 
			SET @iBankReturnFileID = -3
	END

	IF @iBankReturnFileID > 0
	BEGIN
		-- Supprimer les opérations sur convention des CPA de reprise
		DELETE 
		FROM Un_ConventionOper
		WHERE OperID IN (
					SELECT DISTINCT OperID 
					FROM #CPAToDelete)

		IF @@ERROR <> 0 
			SET @iBankReturnFileID = -4
	END

	IF @iBankReturnFileID > 0
	BEGIN
		-- Supprimer les opérations des CPA de reprise
		DELETE 
		FROM Un_Oper
		WHERE OperID IN (
					SELECT DISTINCT OperID 
					FROM #CPAToDelete)

		IF @@ERROR <> 0 
			SET @iBankReturnFileID = -5
	END

	IF @iBankReturnFileID > 0
	BEGIN
		-- Supprime les cotisations des NSF
		DELETE 
		FROM Un_Cotisation
		WHERE OperID IN (
					SELECT 
						BankReturnCodeID
					FROM #OperToDelete)

		IF @@ERROR <> 0 
			SET @iBankReturnFileID = -6
	END

	IF @iBankReturnFileID > 0
	BEGIN
		-- Supprimer les opérations sur convention des NSF
		DELETE 
		FROM Un_ConventionOper
		WHERE OperID IN (
					SELECT 
						BankReturnCodeID 
					FROM #OperToDelete)

		IF @@ERROR <> 0 
			SET @iBankReturnFileID = -7
	END

	IF @iBankReturnFileID > 0
	BEGIN
		-- Supprimer les liens des NSF
		DELETE 
		FROM Mo_BankReturnLink
		WHERE BankReturnFileID = @iBankReturnFileID

		IF @@ERROR <> 0 
			SET @iBankReturnFileID = -8
	END

	IF @iBankReturnFileID > 0
	BEGIN
		-- Fait la liste de tous les documents liés aux opérations à supprimer (pas encore imprimé)
		SELECT DISTINCT L.DocID
		INTO #tDocToDel
		FROM #OperToDelete O
		JOIN CRQ_DocLink L ON L.DocLinkID = O.BankReturnCodeID AND L.DocLinkType = 10
		LEFT JOIN CRQ_DocPrinted P ON P.DocID = L.DocID
		WHERE P.DocID IS NULL

		-- Supprime les liens des documents
		DELETE 
		FROM CRQ_DocLink
		WHERE DocID IN (SELECT DocID FROM #tDocToDel)
		
		IF @@ERROR <> 0 
			SET @iBankReturnFileID = -9

		IF @iBankReturnFileID > 0
		BEGIN
			-- Supprime les documents
			DELETE 
			FROM CRQ_Doc
			WHERE DocID IN (SELECT DocID FROM #tDocToDel)

			IF @@ERROR <> 0 
				SET @iBankReturnFileID = -10
		END

		IF @iBankReturnFileID > 0
		BEGIN
			-- Supprime liens des documents qui ont déjà été supprimés.
			DELETE CRQ_DocLink
			FROM CRQ_DocLink L
			JOIN #OperToDelete O ON L.DocLinkID = O.BankReturnCodeID AND L.DocLinkType = 10

			IF @@ERROR <> 0 
				SET @iBankReturnFileID = -11
		END

		DROP TABLE #tDocToDel
	END

	IF @iBankReturnFileID > 0
	BEGIN
		-- Supprimer les opérations des NSF
		DELETE 
		FROM Un_Oper
		WHERE OperID IN (
					SELECT 
						BankReturnCodeID 
					FROM #OperToDelete)

		IF @@ERROR <> 0 
			SET @iBankReturnFileID = -12
	END

	IF @iBankReturnFileID > 0
	BEGIN
		-- Supprimer le fichier de NSF
		DELETE 
		FROM Mo_BankReturnFile
		WHERE BankReturnFileID = @iBankReturnFileID

		IF @@ERROR <> 0 
			SET @iBankReturnFileID = -13
	END

	IF @iBankReturnFileID > 0
	BEGIN
		-- Réactive la date de blocage
		UPDATE Un_Def 
		SET 
			LastVerifDate = @dtLastVerifDate

		IF @@ERROR <> 0 
			SET @iBankReturnFileID = -14
	END

	IF @iBankReturnFileID > 0
	BEGIN
		-- Suppression des tables temporaires
		DROP TABLE #OperToDelete
		DROP TABLE #CPAToDelete
	END

	IF @iBankReturnFileID > 0
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
		--------------------
	
	RETURN @iBankReturnFileID
END

