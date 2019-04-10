/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc

Nom                 : TT_CHQ_ProposeOperForCheckBlob
Description         : Procédure qui fera la sauvegarde des détails d'opération pour en faire une proposition de chèque.
Valeurs de retours  : @ReturnValue :
                      = 0 : L’opération a réussie.
                      < 0 : L’opération a échouée.
Valeurs de retours  : Dataset :
                     iOperationID INTEGER ID des opérations dont le chèque est en erreur à cause d’opération(s) en erreur.
                     iError       INTEGER ID de l’erreur de l’opération
                                  (0 = Pas d’erreur, 1 = Effacé, 2 = Modifié et 3 = Destinataire)

Exemple d’appel     : EXEC [dbo].[dbo].[TT_CHQ_ProposeOperForCheckBlob] 0, 0, 0

Historique des modifications:
               Date          Programmeur              Description
               ------------  ------------------------ ---------------------------
ADX0000709	IA	2005-08-09    Bernie MacIntyre         Création
ADX0000709	IA	2005-09-30    Bruno Lapointe           Gestion des erreurs
ADX0000709	IA	2005-12-14    Bernie MacIntyre         CountryID au lieu de CountryName dans SELECT juste avant l'INSERT INTO CHQ_Check
ADX0001058	IA	2006-08-01    Alain Quirion            Modification : vcReason adapté aux destinataires compagnies
ADX0001179	IA	2006-10-25    Alain Quirion            Modification : Ajout et gestion du paramètre @bCheckDateIsToday
               2010-06-03    Danielle Côté            ajout traitement fiducies distinctes par régime

****************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_CHQ_ProposeOperForCheckBlob]
(
   @iConnectID INTEGER,      -- ID de connexion de l'usager
   @iBlobID INTEGER,         -- ID du blob qui contient l'opération
   @bCheckDateIsToday BIT =0 -- Indique si le chèque doit être fait en date du jour (1) ou en date des opérations (0).
)
AS
BEGIN
	SET NOCOUNT ON  -- Ne pas retourner de rowcount.

	DECLARE
		@iSPID INTEGER,
		@iResult INTEGER

	SELECT 
		@iSPID = @@SPID,
		@iResult = 1

	-----------------
	BEGIN TRANSACTION
	-----------------

	-- Remplir la table avec les objets (en verticale)
	INSERT INTO CRI_ObjectOfBlob(
		iSPID,
		iObjectID,
		vcClassName,
		vcFieldName,
		txValue)
	SELECT
		@iSPID,
		iObjectID,
		vcClassName,
		vcFieldName,
		txValue
	FROM dbo.FN_CRI_DecodeBlob(@iBlobID)

	IF @@ERROR <> 0
		SET @iResult = -1

	IF @iResult > 0
	BEGIN
		CREATE TABLE #tCHQ_CheckProposal (
			iCheckID INT,
			iPayeeID INT,
			dtEmission DATETIME,
			fAmount DECIMAL(18,4),
			bError BIT DEFAULT 0, -- 0 = Pas d'erreur, 1 = Erreur(s)
			iID_Regime INT)
	
		CREATE TABLE #tCHQ_OperProposal (
			iCheckID INT,
			iOperationID INT,
			fAmount DECIMAL(18,4),
			iError INTEGER DEFAULT 0) -- 1 = Effacé, 2=Modifié, 3=Changement de destinataire
	
		-- Ramène les objets (en horizontale)
		INSERT INTO #tCHQ_CheckProposal (
			iCheckID,
			iPayeeID,
			dtEmission,
			fAmount)
		SELECT
			iCheckID,
			iPayeeID,
			dtEmission,
			fAmount
		FROM dbo.FN_CHQ_CheckProposal(@iSPID)
	
		IF @@ERROR <> 0
			SET @iResult = -2
	END

	IF @iResult > 0
	BEGIN
		INSERT INTO #tCHQ_OperProposal (
			iCheckID,
			iOperationID,
			fAmount)
		SELECT
			iCheckID,
			iOperationID,
			fAmount
		FROM dbo.FN_CHQ_OperProposal(@iSPID)

		IF @@ERROR <> 0
			SET @iResult = -3
	END

	IF @iResult > 0
	BEGIN
		DELETE CRI_ObjectOfBlob
		WHERE iSPID = @iSPID

		IF @@ERROR <> 0
			SET @iResult = -4
	END

	-- Gestion des cas d'erreurs : Opération effacée.
	IF @iResult > 0
	BEGIN
		UPDATE #tCHQ_OperProposal
		SET iError = 1 -- Effacé
		FROM #tCHQ_OperProposal
		JOIN CHQ_Operation O ON O.iOperationID = #tCHQ_OperProposal.iOperationID
		WHERE O.bStatus = 1

		IF @@ERROR <> 0
			SET @iResult = -5
	END

	-- Gestion des cas d'erreurs : Opération modifiée.
	IF @iResult > 0
	BEGIN
		UPDATE #tCHQ_OperProposal
		SET iError = 2 -- Modifié
		FROM #tCHQ_OperProposal
		WHERE iOperationID IN (
			SELECT P.iOperationID
			FROM #tCHQ_OperProposal P
			JOIN CHQ_Operation O ON O.iOperationID = P.iOperationID
			JOIN CHQ_OperationDetail D ON D.iOperationID = P.iOperationID AND O.vcAccount = D.vcAccount
			GROUP BY P.iOperationID, P.fAmount
			HAVING SUM(D.fAmount) <> P.fAmount
			)
			
		IF @@ERROR <> 0
			SET @iResult = -6
	END

	-- Gestion des cas d'erreurs : Changement de destinataire.
	IF @iResult > 0
	BEGIN
		UPDATE #tCHQ_OperProposal
		SET iError = 3 -- Changement de destinataire
		FROM #tCHQ_OperProposal
		JOIN #tCHQ_CheckProposal C ON C.iCheckID = #tCHQ_OperProposal.iCheckID
		JOIN (
			SELECT
				P.iOperationID,
				iOperationPayeeID = MAX(iOperationPayeeID)
			FROM #tCHQ_OperProposal P
			JOIN CHQ_OperationPayee OP ON OP.iOperationID = P.iOperationID
			WHERE OP.iPayeeChangeAccepted <> 2 -- Pas refusé
			GROUP BY P.iOperationID
			) V ON V.iOperationID = #tCHQ_OperProposal.iOperationID
		JOIN CHQ_OperationPayee OP ON OP.iOperationPayeeID = V.iOperationPayeeID
		WHERE OP.iPayeeID <> C.iPayeeID
			OR OP.iPayeeChangeAccepted <> 1

		IF @@ERROR <> 0
			SET @iResult = -7
	END

	-- Indique sur le chèque si sa sauvegarde a échouée.
	IF @iResult > 0
	BEGIN
		UPDATE #tCHQ_CheckProposal
		SET bError = 1 -- Erreur sur opérations du chèques
		FROM #tCHQ_CheckProposal
		WHERE iCheckID IN ( -- Cherche les chèques qui ont des opérations en erreur.
			SELECT iCheckID
			FROM #tCHQ_OperProposal
			WHERE iError <> 0
			)

		IF @@ERROR <> 0
			SET @iResult = -8
	END
	
	-- Ajoute d'id de régime
	IF @iResult > 0
	BEGIN

      UPDATE #tCHQ_CheckProposal
         SET #tCHQ_CheckProposal.iId_Regime = C.PlanID
        FROM #tCHQ_CheckProposal
        JOIN #tCHQ_OperProposal O ON O.iCheckID = #tCHQ_CheckProposal.iCheckId
        JOIN CHQ_Operation Q ON Q.IOperationID  = O.IOperationID
        JOIN dbo.Un_Convention C ON C.ConventionNo  = Q.vcDescription

		IF @@ERROR <> 0
			SET @iResult = -9
	END

	-- Sauvegarde de chèque
	DECLARE 
		@iNewCheckID INT,
		@iCheckID INT,
		@iPayeeID INT,
		@dtEmission DATETIME,
		@fAmount DECIMAL(18,4),
		@iOperationDetailID INT,
		@vcFirstName VARCHAR(35),
		@vcLastName VARCHAR(50),
		@vcAddress VARCHAR(75),
		@vcCity VARCHAR(100),
		@vcStateName VARCHAR(75),
		@vcCountry VARCHAR(75),
		@vcZipCode VARCHAR(10),
		@bIsCompany BIT,
		@iID_Regime INT
	SELECT @iCheckID = 0

	-- Loop avec curseur
	DECLARE crChecks CURSOR
	FOR 
		SELECT
			iCheckID,
			iPayeeID,
			dtEmission,
			fAmount,
			iID_Regime
		FROM #tCHQ_CheckProposal
		WHERE bError = 0

	OPEN crChecks

	FETCH NEXT FROM crChecks
	INTO
		@iCheckID,
		@iPayeeID,
		@dtEmission,
		@fAmount,
		@iID_Regime

	WHILE (@@FETCH_STATUS = 0) 
		AND (@iCheckID < 0) 
		AND (@iResult > 0)
	BEGIN
		SELECT
			@vcFirstName = H.FirstName,
			@vcLastName = H.LastName,
			@vcAddress = A.Address,
			@vcCity = A.City,
			@vcStateName = A.StateName,
			@vcCountry = C.CountryID,
			@vcZipCode = A.ZipCode,
			@bIsCompany = H.IsCompany
		FROM
			Mo_Human H INNER JOIN
			Mo_Adr A ON H.AdrID = A.AdrID LEFT JOIN
			Mo_Country C ON A.CountryID = C.CountryID
		WHERE
			H.HumanID = @iPayeeID

		-- Sauvegarde de chèque
		INSERT INTO CHQ_Check (
			iCheckNumber,
			iCheckStatusID,
			iPayeeID,
			iTemplateID,
			fAmount,
			dtEmission,
			iLangID,
			vcFirstName,
			vcLastName,
			vcAddress,
			vcCity,
			vcStateName,
			vcCountry,
			vcZipCode,
			iID_Regime)
		VALUES (
			NULL,
			1,
			@iPayeeID,
			NULL,
			@fAmount,
			CASE @bCheckDateIsToday 
				WHEN 0 THEN @dtEmission
				ELSE dbo.FN_CRQ_DateNoTime(GETDATE())
			END,
			NULL,
			@vcFirstName,
			@vcLastName,
			@vcAddress,
			@vcCity,
			@vcStateName,
			@vcCountry,
			@vcZipCode,
			@iID_Regime)

		IF @@ERROR <> 0
			SET @iResult = -9
		ELSE
			-- Récuperer le ID du chèque
			SELECT @iNewCheckID = SCOPE_IDENTITY()

		IF @iResult > 0
		BEGIN
			-- Sauvegarde d'historique pour le chèque
			INSERT INTO CHQ_CheckHistory (
				iCheckID,
				iCheckStatusID,
				dtHistory,
				iConnectID,
				vcReason )
			VALUES (
				@iNewCheckID,
				1,
				GETDATE(),
				@iConnectID,
				'Destinataire : '+ 
						CASE @bIsCompany
							WHEN 0 THEN ISNULL(@vcFirstName,'')+' '+ISNULL(@vcLastName,'') 
							WHEN 1 THEN ISNULL(@vcLastName,'')
						END
				)

			IF @@ERROR <> 0
				SET @iResult = -10
		END

		IF @iResult > 0
		BEGIN
			-- Sauvegarde des détails d'operation pour faire une proposition de chèque
			INSERT INTO CHQ_CheckOperationDetail (
					iOperationDetailID,
					iCheckID )
				SELECT
					OD.iOperationDetailID,
					@iNewCheckID
				FROM #tCHQ_OperProposal OP
				JOIN CHQ_OperationDetail OD ON OP.iOperationID = OD.iOperationID
				WHERE OP.iCheckID = @iCheckID

			IF @@ERROR <> 0
				SET @iResult = -11
		END

		FETCH NEXT FROM crChecks
		INTO
			@iCheckID,
			@iPayeeID,
			@dtEmission,
			@fAmount,
			@iID_Regime
	END

	CLOSE crChecks
	DEALLOCATE crChecks

	SELECT
		OP.iOperationID,
		OP.iError
	FROM #tCHQ_CheckProposal CP
	JOIN #tCHQ_OperProposal OP ON OP.iCheckID = CP.iCheckID
	WHERE CP.bError = 1

	IF @iResult > 0
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
		--------------------

	RETURN @iResult
END


