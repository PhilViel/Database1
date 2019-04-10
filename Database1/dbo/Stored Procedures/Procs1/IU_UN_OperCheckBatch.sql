/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_OperCheckBatch
Description         :	Inscrit ou modfie l'opération du module des chèques suite à l'ajout ou la modification d'une
								opération du système de convention.
Valeurs de retours  :	@Return_Value
									<0	: Erreur à la sauvegarde.
									>0	: Sauvegarde réussie.
									
Historique des modifications:
               Date        Programmeur       Description
               ----------  ----------------- ---------------------------
ADX0000753	IA	2005-10-05	Bruno Lapointe		Création
ADX0002426	BR	2007-05-23	Bruno Lapointe		Gestion de la table Un_CESP.
ADX0002494	BR	2007-06-19	Bruno Lapointe		Ne pas créé l,opération dans les chèques si le
															total de l'opération = 0.00$
					2009-07-13	Éric Deshaies		Implantation d'une mesure temporaire pour sortir les montants d'IQÉÉ
															avec les PAE avant que les montants d'IQÉÉ soient injectés dans les
															conventions.
					2009-12-04	Éric Deshaies		Modifier la mesure temporaire parce que l'IQÉÉ et les intérêts de l'IQÉÉ
															sont dans les conventions.
               2010-06-03  Danielle Côté     Ajout traitement fiducies distinctes par régime
****************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_OperCheckBatch] (
	@ConnectID INTEGER, -- ID Unique de connexion de l'usager
	@iSPID INTEGER )
AS
BEGIN
	DECLARE
		@iResult INTEGER,
		@iLastOperationID INTEGER,
		@dtCreated DATETIME,
		@fAmount MONEY,
		@vcAccount VARCHAR(50), 
		@vcDescriptionDtl VARCHAR(50),
		@iOperationDetailID INTEGER,
		@vcBankAccount VARCHAR(50),
		@iRGCRecipient INTEGER,
-------------------------
-- Mesure temporaire IQÉÉ
		@iID_IQEE_PAE INT,
		@iID_Convention INT,
		@iID_Operation INT

	CREATE TABLE #tblIQEE_Montants
		(iID_Operation INT PRIMARY KEY,
		 iID_IQEE_PAE INT)
-------------------------
	SET @iResult = @iSPID
	SET @dtCreated = GETDATE()

	SELECT @iRGCRecipient = MAX(R.iRecipientID)
	FROM Un_Recipient R
	JOIN dbo.Mo_Human H ON H.HumanID = R.iRecipientID
	WHERE H.LastName = 'Receveur Général du Canada'

	CREATE TABLE #tOperCheckBatch (
		iAddToLastOperationID INTEGER PRIMARY KEY IDENTITY(1,1),
		iOperID INTEGER,
		dtOperation DATETIME NOT NULL,
		vcDescription VARCHAR(50) NULL,
		vcRefType VARCHAR(10) NOT NULL,
		iPayeeID INTEGER NOT NULL,
		iID_Regime INT,
		CONSTRAINT U_tOperCheckBatch UNIQUE (iOperID)
		)

   INSERT INTO #tOperCheckBatch 
              (iOperID,
               dtOperation,
               vcDescription,
               vcRefType,
               iPayeeID,
               iID_Regime)
        SELECT O.OperID,
               O.OperDate,
               C.ConventionNo,
               O.OperTypeID,
               CASE
                  WHEN O.OperTypeID IN ('PAE', 'AVC') THEN C.BeneficiaryID
                  WHEN O.OperTypeID IN ('RGC') THEN @iRGCRecipient
                  ELSE C.SubscriberID
               END,
               C.PlanID 
          FROM (SELECT V.OperID,
                       ConventionID = MIN(V.ConventionID)
                  FROM (SELECT Ct.OperID,
                               U.ConventionID,
                               iID = Ct.CotisationID,
                               fAmount = Ct.Cotisation + Ct.Fee + Ct.SubscInsur + Ct.BenefInsur + Ct.TaxOnInsur
                          FROM Un_Cotisation Ct
                          JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
                          JOIN Un_OperToExportInCHQ O ON O.OperID = Ct.OperID
                         WHERE @iSPID = O.iSPID
                        -----
                        UNION
                        -----
                        SELECT CO.OperID,
 CO.ConventionID,
             iID = CO.ConventionOperID,
                               fAmount = CO.ConventionOperAmount
                          FROM Un_ConventionOper CO
                          JOIN Un_OperToExportInCHQ O ON O.OperID = CO.OperID
                         WHERE @iSPID = O.iSPID
                        -----
                        UNION
                        -----
                        SELECT GG.OperID,
                               GG.ConventionID,
                               iID = GG.iCESPID,
                               fAmount = GG.fCESG + GG.fACESG + GG.fCLB + GG.fPG
                          FROM Un_CESP GG 
                          JOIN Un_OperToExportInCHQ O ON O.OperID = GG.OperID
                         WHERE @iSPID = O.iSPID
                       ) V
                 GROUP BY V.OperID
                HAVING SUM(fAmount) <> 0
               ) V 
          JOIN Un_Oper O ON O.OperID = V.OperID
          JOIN (SELECT Ct.OperID
                  FROM Un_Cotisation Ct
                  JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
                  JOIN Un_OperToExportInCHQ O ON O.OperID = Ct.OperID
                 WHERE @iSPID = O.iSPID
                   AND (Ct.Cotisation <> 0
                    OR Ct.Fee <> 0
                    OR Ct.SubscInsur <> 0
                    OR Ct.BenefInsur <> 0
                    OR Ct.TaxOnInsur <> 0)
                -----
                UNION
                -----
                SELECT CO.OperID
                  FROM Un_ConventionOper CO
                  JOIN Un_OperToExportInCHQ O ON O.OperID = CO.OperID
                 WHERE @iSPID = O.iSPID
                   AND CO.ConventionOperAmount <> 0
                -----
                UNION
                -----
                SELECT GG.OperID
                  FROM Un_CESP GG 
                  JOIN Un_OperToExportInCHQ O ON O.OperID = GG.OperID
                 WHERE @iSPID = O.iSPID
                -----
                UNION
                -----
                SELECT PO.OperID
                  FROM Un_PlanOper PO
                  JOIN Un_OperToExportInCHQ O ON O.OperID = PO.OperID
                 WHERE @iSPID = O.iSPID
                   AND PO.PlanOperAmount <> 0
               ) OV ON OV.OperID = O.OperID -- Exclus les opérations dont le total est 0.00$
          LEFT JOIN Un_OperLinkToCHQOperation L ON L.OperID = V.OperID
          JOIN dbo.Un_Convention C ON C.ConventionID = V.ConventionID
         WHERE O.OperTypeID IN ('RES', 'OUT', 'RIN', 'RET', 'PAE', 'RGC', 'AVC')
           AND L.OperID IS NULL

	-- Insère ou modifie les opérations dans la gestion des chèques (CHQ_Operation)
	SET @iLastOperationID = IDENT_CURRENT('CHQ_Operation')

   INSERT INTO CHQ_Operation 
              (bStatus,
               iConnectID,
               dtOperation,
               vcDescription,
               vcRefType,
               vcAccount)
        SELECT 0,
               @ConnectID,
               dtOperation,
               vcDescription,
               vcRefType,
               [dbo].[fnCONV_ObtenirCompteFiducie]([dbo].[fnCONV_ObtenirRegroupementRegime](iID_Regime))
          FROM #tOperCheckBatch		 

	IF @@ERROR <> 0
		SET @iResult = -1
	ELSE IF @iLastOperationID = 1
		SELECT @iLastOperationID = 0

	-- Crée le lien entre l'opération du système de convention (Un_Oper) et l'opération du module des chèques (CHQ_Operation),
	-- s'il n'y en avait pas.
	IF @iResult > 0
	BEGIN
		INSERT INTO Un_OperLinkToCHQOperation (
				OperID,
				iOperationID )
			SELECT
				iOperID,
				@iLastOperationID+iAddToLastOperationID
			FROM #tOperCheckBatch

		IF @@ERROR <> 0
			SET @iResult = -2
	END

	-- Inscrit l'humain comme destinataire dans le module des chèques s'il ne l'ai pas déjà
	IF @iResult > 0
	BEGIN
		INSERT INTO CHQ_Payee (
				iPayeeID )
			SELECT DISTINCT
				O.iPayeeID
			FROM #tOperCheckBatch O
			LEFT JOIN CHQ_Payee P ON P.iPayeeID = O.iPayeeID
			WHERE P.iPayeeID IS NULL

		IF @@ERROR <> 0
			SET @iResult = -3
	END

	-- Inscrit le destinataire dans le module des chèques s'il ne l'ai pas déjà
	IF @iResult > 0
	BEGIN
		INSERT INTO CHQ_OperationPayee (
				iPayeeID,
				iOperationID,
				dtCreated,
				vcReason,
				iPayeeChangeAccepted )
			SELECT DISTINCT
				iPayeeID,
				@iLastOperationID+iAddToLastOperationID,
				@dtCreated,
				'',
				1
			FROM #tOperCheckBatch O

		IF @@ERROR <> 0
			SET @iResult = -4
	END

	-- Inscrit l'humain du changement de destinataire comme destinataire dans le module des chèques s'il ne l'ai pas déjà
	IF @iResult > 0
	BEGIN
		INSERT INTO CHQ_Payee (
				iPayeeID )
			SELECT DISTINCT
				CS.iHumanID
			FROM #tOperCheckBatch O
			JOIN Un_ChequeSuggestion CS ON CS.OperID = O.iOperID
			LEFT JOIN CHQ_Payee P ON P.iPayeeID = CS.iHumanID
			WHERE P.iPayeeID IS NULL

		IF @@ERROR <> 0
			SET @iResult = -5
	END

	-- Inscrit le destinataire dans le module des chèques s'il ne l'ai pas déjà
	IF @iResult > 0
	BEGIN
		INSERT INTO CHQ_OperationPayee (
				iPayeeID,
				iOperationID,
				dtCreated,
				vcReason,
				iPayeeChangeAccepted )
			SELECT DISTINCT
				iHumanID,
				@iLastOperationID+iAddToLastOperationID,
				@dtCreated,
				'',
				0
			FROM #tOperCheckBatch O
			JOIN Un_ChequeSuggestion CS ON CS.OperID = O.iOperID

		IF @@ERROR <> 0
			SET @iResult = -6
	END

	-- Détail des opérations
	IF @iResult > 0
	BEGIN
		-- Table temporaire du détail des opérations
		CREATE TABLE #tCHQ_OperationDetail (
			iOperationID INTEGER,
			fAmount MONEY,
			vcAccount VARCHAR(75), 
			vcDescription VARCHAR(75),
			iID_Regime INT)

-------------------------
-- Mesure temporaire IQÉÉ
	IF @iResult > 0
		BEGIN
			DECLARE cur_tOperCheckBatch CURSOR FOR
				SELECT iOperID
				FROM #tOperCheckBatch
				WHERE vcRefType = 'PAE'

			OPEN cur_tOperCheckBatch
			FETCH NEXT FROM cur_tOperCheckBatch INTO @iID_Operation
			WHILE @@FETCH_STATUS = 0
				BEGIN
					IF @iResult > 0
					BEGIN
						-- Déterminer l'ID de la convention
						SET @iID_Convention = NULL

						SELECT @iID_Convention = MAX(CO.ConventionID)
						FROM Un_ConventionOper CO
						WHERE CO.OperID = @iID_Operation

						IF @iID_Convention IS NULL
							SELECT @iID_Convention = MAX(C.ConventionID)
							FROM Un_CESP C
							WHERE C.OperID = @iID_Operation
						
						-- Calculer les montant d'IQÉÉ du PAE
						EXECUTE @iID_IQEE_PAE = [dbo].[psTEMP_ObtenirMontantIQEEPourPAE] @iID_Convention, @iID_Operation 
					END

					IF @iID_IQEE_PAE = 0
						SET @iResult = -18
					ELSE
						INSERT INTO #tblIQEE_Montants (iID_Operation, iID_IQEE_PAE) VALUES (@iID_Operation, @iID_IQEE_PAE)

					FETCH NEXT FROM cur_tOperCheckBatch INTO @iID_Operation
				END
			CLOSE cur_tOperCheckBatch
			DEALLOCATE cur_tOperCheckBatch
		END
-------------------------

      IF @iResult > 0
      BEGIN
         -- Un_Cotisation.Cotisation
         INSERT INTO #tCHQ_OperationDetail
                    (iOperationID
                    ,fAmount
                    ,vcAccount
                    ,vcDescription
                    ,iID_Regime)
              SELECT @iLastOperationID+O.iAddToLastOperationID
                    ,Ct.Cotisation
                    ,AN.vcAccountNumber
                    ,A.vcAccount
                    ,O.iID_Regime
                FROM #tOperCheckBatch O
                JOIN Un_Cotisation Ct ON O.iOperID = Ct.OperID
                JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
                JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
                JOIN Un_Plan P ON P.PlanID = C.PlanID
                JOIN Un_Account A ON A.iID_Regime = O.iID_Regime
                JOIN Un_AccountNumber AN ON AN.iAccountID = A.iAccountID
                 AND @dtCreated BETWEEN  AN.dtStart AND ISNULL(AN.dtEnd, GETDATE()) 
                JOIN Un_AccountMoneyType AMT ON AMT.iAccountID = A.iAccountID
                 AND @dtCreated BETWEEN AMT.dtStart AND ISNULL(AMT.dtEnd, GETDATE())
                JOIN Un_MoneyType MT ON MT.iMoneyTypeID = AMT.iMoneyTypeID
                 AND MT.OperTypeID  = O.vcRefType
                 AND MT.vcTableName = 'Un_Cotisation' 
                 AND MT.vcFieldName = 'Cotisation'
               WHERE Ct.Cotisation <> 0

         IF @@ERROR <> 0
            SET @iResult = -7
      END

      IF @iResult > 0
      BEGIN
         -- Un_Cotisation.Fee
         INSERT INTO #tCHQ_OperationDetail
                    (iOperationID
                    ,fAmount
                    ,vcAccount
                    ,vcDescription
                    ,iID_Regime)
              SELECT @iLastOperationID+O.iAddToLastOperationID
                    ,Ct.Fee
                    ,AN.vcAccountNumber
                    ,A.vcAccount
                    ,O.iID_Regime
                FROM #tOperCheckBatch O
                JOIN Un_Cotisation Ct ON O.iOperID = Ct.OperID
                JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
                JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
                JOIN Un_Plan P ON P.PlanID = C.PlanID
                JOIN Un_Account A ON A.iID_Regime = O.iID_Regime
                JOIN Un_AccountNumber AN ON AN.iAccountID = A.iAccountID
                 AND @dtCreated BETWEEN  AN.dtStart AND ISNULL(AN.dtEnd, GETDATE()) 
                JOIN Un_AccountMoneyType AMT ON AMT.iAccountID = A.iAccountID
                 AND @dtCreated BETWEEN AMT.dtStart AND ISNULL(AMT.dtEnd, GETDATE())
                JOIN Un_MoneyType MT ON MT.iMoneyTypeID = AMT.iMoneyTypeID
                 AND MT.OperTypeID  = O.vcRefType
                 AND MT.vcTableName = 'Un_Cotisation' 
                 AND MT.vcFieldName = 'Fee'
               WHERE Ct.Fee <> 0

         IF @@ERROR <> 0
            SET @iResult = -8
      END

      IF @iResult > 0
      BEGIN
         -- Un_Cotisation.SubscInsur
         INSERT INTO #tCHQ_OperationDetail
                    (iOperationID
                    ,fAmount
                    ,vcAccount
                    ,vcDescription
                    ,iID_Regime)
              SELECT @iLastOperationID+O.iAddToLastOperationID
                    ,Ct.SubscInsur
                    ,AN.vcAccountNumber
                    ,A.vcAccount
                    ,O.iID_Regime
                FROM #tOperCheckBatch O
                JOIN Un_Cotisation Ct ON O.iOperID = Ct.OperID
                JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
                JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
                JOIN Un_Plan P ON P.PlanID = C.PlanID
                JOIN Un_Account A ON A.iID_Regime = O.iID_Regime
                JOIN Un_AccountNumber AN ON AN.iAccountID = A.iAccountID
                 AND @dtCreated BETWEEN  AN.dtStart AND ISNULL(AN.dtEnd, GETDATE()) 
                JOIN Un_AccountMoneyType AMT ON AMT.iAccountID = A.iAccountID
                 AND @dtCreated BETWEEN AMT.dtStart AND ISNULL(AMT.dtEnd, GETDATE())
                JOIN Un_MoneyType MT ON MT.iMoneyTypeID = AMT.iMoneyTypeID
                 AND MT.OperTypeID  = O.vcRefType
                 AND MT.vcTableName = 'Un_Cotisation' 
                 AND MT.vcFieldName = 'SubscInsur'
               WHERE Ct.SubscInsur <> 0

         IF @@ERROR <> 0
            SET @iResult = -9
      END

      IF @iResult > 0
      BEGIN
         -- Un_Cotisation.BenefInsur
         INSERT INTO #tCHQ_OperationDetail
                    (iOperationID
                    ,fAmount
                    ,vcAccount
                    ,vcDescription
                    ,iID_Regime)
              SELECT @iLastOperationID+O.iAddToLastOperationID
                    ,Ct.BenefInsur
                    ,AN.vcAccountNumber
                    ,A.vcAccount
                  ,O.iID_Regime
                FROM #tOperCheckBatch O
                JOIN Un_Cotisation Ct ON O.iOperID = Ct.OperID
                JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
                JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
                JOIN Un_Plan P ON P.PlanID = C.PlanID
                JOIN Un_Account A ON A.iID_Regime = O.iID_Regime
                JOIN Un_AccountNumber AN ON AN.iAccountID = A.iAccountID
                 AND @dtCreated BETWEEN  AN.dtStart AND ISNULL(AN.dtEnd, GETDATE()) 
                JOIN Un_AccountMoneyType AMT ON AMT.iAccountID = A.iAccountID
                 AND @dtCreated BETWEEN AMT.dtStart AND ISNULL(AMT.dtEnd, GETDATE())
                JOIN Un_MoneyType MT ON MT.iMoneyTypeID = AMT.iMoneyTypeID
                 AND MT.OperTypeID  = O.vcRefType
                 AND MT.vcTableName = 'Un_Cotisation' 
                 AND MT.vcFieldName = 'BenefInsur'
               WHERE Ct.BenefInsur <> 0

         IF @@ERROR <> 0
            SET @iResult = -10
      END

      IF @iResult > 0
      BEGIN
         -- Un_Cotisation.TaxOnInsur
         INSERT INTO #tCHQ_OperationDetail
                    (iOperationID
                    ,fAmount
                    ,vcAccount
                    ,vcDescription
                    ,iID_Regime)
              SELECT @iLastOperationID+O.iAddToLastOperationID
                    ,Ct.TaxOnInsur
                    ,AN.vcAccountNumber
                    ,A.vcAccount
                    ,O.iID_Regime
                FROM #tOperCheckBatch O
                JOIN Un_Cotisation Ct ON O.iOperID = Ct.OperID
                JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
                JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
                JOIN Un_Plan P ON P.PlanID = C.PlanID
                JOIN Un_Account A ON A.iID_Regime = O.iID_Regime
                JOIN Un_AccountNumber AN ON AN.iAccountID = A.iAccountID
                 AND @dtCreated BETWEEN  AN.dtStart AND ISNULL(AN.dtEnd, GETDATE()) 
                JOIN Un_AccountMoneyType AMT ON AMT.iAccountID = A.iAccountID
                 AND @dtCreated BETWEEN AMT.dtStart AND ISNULL(AMT.dtEnd, GETDATE())
                JOIN Un_MoneyType MT ON MT.iMoneyTypeID = AMT.iMoneyTypeID
                 AND MT.OperTypeID  = O.vcRefType
                 AND MT.vcTableName = 'Un_Cotisation' 
                 AND MT.vcFieldName = 'TaxOnInsur'
               WHERE Ct.TaxOnInsur <> 0

         IF @@ERROR <> 0
            SET @iResult = -11
      END

      IF @iResult > 0
      BEGIN
         -- Un_ConventionOper.ConventionOperAmount
         INSERT INTO #tCHQ_OperationDetail
                    (iOperationID
                    ,fAmount
                    ,vcAccount
                    ,vcDescription
                    ,iID_Regime)
              SELECT @iLastOperationID+O.iAddToLastOperationID
                    ,CO.ConventionOperAmount
                    ,AN.vcAccountNumber
                    ,A.vcAccount
                    ,O.iID_Regime
                FROM #tOperCheckBatch O
                JOIN Un_ConventionOper CO ON O.iOperID = CO.OperID
                JOIN Un_ConventionOperType T ON T.ConventionOperTypeID = CO.ConventionOperTypeID
                JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
                JOIN Un_Plan P ON P.PlanID = C.PlanID
                JOIN Un_Account A ON A.iID_Regime = O.iID_Regime
                JOIN Un_AccountNumber AN ON AN.iAccountID = A.iAccountID
                 AND @dtCreated BETWEEN  AN.dtStart AND ISNULL(AN.dtEnd, GETDATE()) 
                JOIN Un_AccountMoneyType AMT ON AMT.iAccountID = A.iAccountID
                 AND @dtCreated BETWEEN AMT.dtStart AND ISNULL(AMT.dtEnd, GETDATE())
                JOIN Un_MoneyType MT ON MT.iMoneyTypeID = AMT.iMoneyTypeID
                 AND MT.vcValueType = CO.ConventionOperTypeID
                 AND MT.OperTypeID  = O.vcRefType
           AND MT.vcTableName = 'Un_ConventionOper'
                 AND MT.vcFieldName = 'ConventionOperAmount'
               WHERE CO.ConventionOperAmount <> 0

         IF @@ERROR <> 0
            SET @iResult = -12
      END

      IF @iResult > 0
      BEGIN
         -- Un_PlanOper.PlanOperAmount
         INSERT INTO #tCHQ_OperationDetail
                    (iOperationID
                    ,fAmount
                    ,vcAccount
                    ,vcDescription
                    ,iID_Regime)
              SELECT @iLastOperationID+O.iAddToLastOperationID
                    ,PO.PlanOperAmount
                    ,AN.vcAccountNumber
                    ,A.vcAccount
                    ,O.iID_Regime
                FROM #tOperCheckBatch O
                JOIN Un_PlanOper PO ON O.iOperID = PO.OperID
                JOIN Un_PlanOperType T ON T.PlanOperTypeID = PO.PlanOperTypeID
                JOIN Un_Plan P ON P.PlanID = PO.PlanID
                JOIN Un_Account A ON A.iID_Regime = O.iID_Regime
                JOIN Un_AccountNumber AN ON AN.iAccountID = A.iAccountID
                 AND @dtCreated BETWEEN  AN.dtStart AND ISNULL(AN.dtEnd, GETDATE()) 
                JOIN Un_AccountMoneyType AMT ON AMT.iAccountID = A.iAccountID
                 AND @dtCreated BETWEEN AMT.dtStart AND ISNULL(AMT.dtEnd, GETDATE())
                JOIN Un_MoneyType MT ON MT.iMoneyTypeID = AMT.iMoneyTypeID
                 AND MT.vcValueType = PO.PlanOperTypeID
                 AND MT.OperTypeID  = O.vcRefType
                 AND MT.vcTableName = 'Un_PlanOper'
                 AND MT.vcFieldName = 'PlanOperAmount'
               WHERE PO.PlanOperAmount <> 0

			IF @@ERROR <> 0
				SET @iResult = -13
		END
	
		IF @iResult > 0
		BEGIN
			-- Un_CESP.fACESG
			INSERT INTO #tCHQ_OperationDetail
                    (iOperationID
                    ,fAmount
                    ,vcAccount
                    ,vcDescription
						  ,iID_Regime)
              SELECT @iLastOperationID+O.iAddToLastOperationID
                    ,GG.fCESG
                    ,AN.vcAccountNumber
                    ,A.vcAccount
						  ,O.iID_Regime
                FROM #tOperCheckBatch O
                JOIN Un_CESP GG ON O.iOperID = GG.OperID
                JOIN dbo.Un_Convention C ON C.ConventionID =  GG.ConventionID
                JOIN Un_Plan P ON P.PlanID = C.PlanID
                JOIN Un_Account A ON A.iID_Regime = O.iID_Regime
                JOIN Un_AccountNumber AN ON AN.iAccountID = A.iAccountID
                 AND @dtCreated BETWEEN  AN.dtStart AND ISNULL(AN.dtEnd, GETDATE()) 
                JOIN Un_AccountMoneyType AMT ON AMT.iAccountID = A.iAccountID
                 AND @dtCreated BETWEEN AMT.dtStart AND ISNULL(AMT.dtEnd, GETDATE())
                JOIN Un_MoneyType MT ON MT.iMoneyTypeID = AMT.iMoneyTypeID
                 AND MT.OperTypeID  = O.vcRefType
                 AND MT.vcTableName = 'Un_CESP' 
                 AND MT.vcFieldName = 'fCESG'
               WHERE GG.fCESG <> 0
              ---------
              UNION ALL
              ---------
              SELECT @iLastOperationID+O.iAddToLastOperationID
                    ,GG.fACESG
                    ,AN.vcAccountNumber
                    ,A.vcAccount
						  ,O.iID_Regime
                FROM #tOperCheckBatch O
                JOIN Un_CESP GG ON O.iOperID = GG.OperID
                JOIN dbo.Un_Convention C ON C.ConventionID = GG.ConventionID
                JOIN Un_Plan P ON P.PlanID = C.PlanID
                JOIN Un_Account A ON A.iID_Regime = O.iID_Regime
                JOIN Un_AccountNumber AN ON AN.iAccountID = A.iAccountID
                 AND @dtCreated BETWEEN  AN.dtStart AND ISNULL(AN.dtEnd, GETDATE()) 
                JOIN Un_AccountMoneyType AMT ON AMT.iAccountID = A.iAccountID
                 AND @dtCreated BETWEEN AMT.dtStart AND ISNULL(AMT.dtEnd, GETDATE())
            JOIN Un_MoneyType MT ON MT.iMoneyTypeID = AMT.iMoneyTypeID
                 AND MT.OperTypeID  = O.vcRefType
                 AND MT.vcTableName = 'Un_CESP' 
                 AND MT.vcFieldName = 'fACESG'
               WHERE GG.fACESG <> 0
              ---------
              UNION ALL
              ---------
              SELECT @iLastOperationID+O.iAddToLastOperationID
                    ,GG.fCLB
                    ,AN.vcAccountNumber
                    ,A.vcAccount
						  ,O.iID_Regime
                FROM #tOperCheckBatch O
                JOIN Un_CESP GG ON O.iOperID = GG.OperID
                JOIN dbo.Un_Convention C ON C.ConventionID = GG.ConventionID
                JOIN Un_Plan P ON P.PlanID = C.PlanID
                JOIN Un_Account A ON A.iID_Regime = O.iID_Regime
                JOIN Un_AccountNumber AN ON AN.iAccountID = A.iAccountID
                 AND @dtCreated BETWEEN  AN.dtStart AND ISNULL(AN.dtEnd, GETDATE()) 
                JOIN Un_AccountMoneyType AMT ON AMT.iAccountID = A.iAccountID
                 AND @dtCreated BETWEEN AMT.dtStart AND ISNULL(AMT.dtEnd, GETDATE())
                JOIN Un_MoneyType MT ON MT.iMoneyTypeID = AMT.iMoneyTypeID
                 AND MT.OperTypeID  = O.vcRefType
                 AND MT.vcTableName = 'Un_CESP' 
                 AND MT.vcFieldName = 'fCLB'
               WHERE GG.fCLB <> 0

			IF @@ERROR <> 0
				SET @iResult = -14
		END

      IF @iResult > 0
      BEGIN

         -- Banque = Sum de tous les autres * -1
         INSERT INTO #tCHQ_OperationDetail
                    (iOperationID
                    ,fAmount
                    ,vcAccount
                    ,vcDescription)
              SELECT O.iOperationID
                    ,-SUM(O.fAmount)
                    ,R.vcCode_Compte_Comptable_Fiducie
                    ,R.vcDescription
                FROM #tCHQ_OperationDetail O
                JOIN tblCONV_RegroupementsRegimes R ON R.iID_Regroupement_Regime = [dbo].[fnCONV_ObtenirRegroupementRegime](O.iID_Regime)
               GROUP BY O.iOperationID, O.iID_Regime, R.vcCode_Compte_Comptable_Fiducie, R.vcDescription

         IF @@ERROR <> 0
            SET @iResult = -15
      END

		IF @iResult > 0
		BEGIN
			INSERT INTO CHQ_OperationDetail (
					iOperationID,
					fAmount,
					vcAccount,
					vcDescription )
				SELECT
					iOperationID,
					fAmount,
					vcAccount,
					vcDescription
				FROM #tCHQ_OperationDetail

			IF @@ERROR <> 0
				SET @iResult = -16
		END

		DROP TABLE #tCHQ_OperationDetail
	END

	IF @iResult > 0
	BEGIN
		DELETE 
		FROM Un_OperToExportInCHQ
		WHERE iSPID = @iSPID

		IF @@ERROR <> 0
			SET @iResult = -17
	END

	RETURN @iResult
END


