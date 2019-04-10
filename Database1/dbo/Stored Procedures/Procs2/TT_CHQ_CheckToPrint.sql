/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc

Nom                 : TT_CHQ_CheckToPrint
Description         : Procédure qui fait l’impression d’un lot de chèques.

Valeurs de retours  : Dataset :
iCheckID         INTEGER			ID du cheque.
iTemplateID      INTEGER			ID du template.
iCheckNumer      INTEGER			Numéro du chèque
dtEmission       DATETIME		   La date du chèque.
vcLastName       VARCHAR(50)		Nom de famille du destinataire du chèque.
vcFirstName      VARCHAR(35)		Prénom du destinataire du chèque.
vcAddress        VARCHAR(75)		Adresse du destinataire du chèque
vcCity           VARCHAR(100)	   La ville du destinataire du chèque.
vcProvOrState    VARCHAR(75)		Le province du destinataire du chèque.
vcCountry        VARCHAR(75)		Le pays du destinataire du chèque.
vcPostalCode     VARCHAR(10)		Le code postal du destinataire du chèque.
fAmount          DECIMAL(18,4)	Le montant du chèque.
vcRefType        VARCHAR(75)		Le type des opérations liées au chèque.
iOperationID     INTEGER			ID de l’opération
vcDescription    VARCHAR(50)		Description de l’opération (Ex : U-20010101001).
fOperationAmount DECIMAL(18,4)	Le montant de l’opération chèque.

@ReturnValue :
					> 0 : Le traitement a réussi.
					< 0 : Le traitement a échoué.

Historique des modifications:
               Date        Programmeur       Description
               ----------  ----------------- ---------------------------
ADX0000714	IA	2005-09-13	Bruno Lapointe		Création
ADX0001058	IA	2006-08-01	Alain Quirion		Modification : Renvoit bIsCompany
ADX0001098	IA	2006-09-11	Bruno Lapointe		Gestion des talons de chèques détaillés.
ADX0001169	IA	2006-10-27	Alain Quirion		Modification : Envoi des lettres de chèques de résiliation automatiquement
ADX0002478	BR	2007-06-11	Alain Quirion     Utilisation d'un clé primaire sur le champ OperID et UnitID pour la table temporaire tOperCheck
               2010-06-09  Danielle Côté     Ajout traitement fiducies distinctes par régime

****************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_CHQ_CheckToPrint]
(
   @iConnectID        INTEGER  -- ID unique de la connexion.
  ,@iCheckBookID      INTEGER  -- ID du chéquier
  ,@iStartCheckNumber INTEGER  -- Début de l’intervalle de numéro de chèque.
  ,@iBlobID           INTEGER  -- ID du blob qui contient les iCheckID séparés par des virgules des chèques qu’il faut imprimer.
)
AS
BEGIN
   DECLARE
      @iResult INTEGER
     ,@iResultLetter INTEGER
     ,@iTemplateID INTEGER
     ,@cLastCharacter CHAR(1)
     ,@iBlobPtr varbinary(16)
     ,@BlobID INTEGER
     ,@iCheckID INTEGER
     ,@TmpString VARCHAR(20)

   SET @BlobID = -1

   SELECT @iTemplateID = MAX(iTemplateID)
     FROM CHQ_Template
    WHERE iCheckBookID = @iCheckBookID

   -- S'assure que le dernier caractères est une virgule.
   SELECT @cLastCharacter = SUBSTRING(txBlob, DATALENGTH(txBlob), 1), @iBlobPtr = TEXTPTR(txBlob) FROM CRI_Blob WHERE iBlobID = @iBlobID

   IF @cLastCharacter <> ',' BEGIN
      UPDATETEXT CRI_Blob.txBlob @iBlobPtr NULL NULL ','
   END

   BEGIN TRANSACTION

   -- Change le statut des chèques à imprimer
   EXECUTE @iResult = IU_CHQ_CheckChangeStatus @iConnectID, @iBlobID, 4

   DECLARE @RESCheckTable TABLE
          (iCheckID INTEGER)  --Id du chèque

   DECLARE @RESCheckWithoutNASTable TABLE
          (iCheckID INTEGER)  --Id du chèque

   -- Table qui contient tout les groupes d'unités liés aux chèques
   CREATE TABLE #tOperOfCheck
               (OperID INTEGER NOT NULL
               ,iCheckID INTEGER NOT NULL
               ,UnitID INTEGER NOT NULL
               ,CONSTRAINT PK_OperUnit PRIMARY KEY CLUSTERED (OperID, UnitID))

   CREATE TABLE #tCheckToPrint
               (iCheckID INTEGER PRIMARY KEY
     ,iAddToNumber INTEGER IDENTITY(0,1)
               ,vcRefType VARCHAR(10) NULL
               ,iCheckStubDtlLines INTEGER NULL)

   IF @iResult > 0
   BEGIN
      INSERT INTO #tOperOfCheck
           SELECT DISTINCT Ct.OperID
                 ,CH.iCheckID
                 ,Ct.UnitID
             FROM CHQ_Check CH
             JOIN CHQ_CheckOperationDetail COP ON CH.iCheckID = COP.iCheckID
             JOIN CHQ_OperationDetail OD ON COP.iOperationDetailID = OD.iOperationDetailID
             JOIN Un_OperLinkToCHQOperation OL ON OD.iOperationID = OL.iOperationID
             JOIN Un_Cotisation Ct ON Ct.OperID = OL.OperID
             JOIN dbo.FN_CRI_BlobToIntegerTable(@iBlobID) BC ON BC.iVal = CH.iCheckID

      IF @@ERROR <> 0 
         SET @iResult = -1
   END

   IF @iResult > 0
   BEGIN
      -- Recherche des chèques pour la lettre de remboursement d'épargne
      INSERT INTO @RESCheckTable
           SELECT OC.iCheckID
             FROM #tOperOfCheck OC
             JOIN Un_Cotisation Ct ON Ct.OperID = OC.OperID AND Ct.UnitID = OC.UnitID
             JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
             JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
             JOIN Un_UnitReductionCotisation URC ON URC.CotisationID = Ct.CotisationID
             JOIN Un_UnitReduction UR ON UR.UnitReductionID = URC.UnitReductionID
             JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID
             JOIN (SELECT CCS.ConventionID
                         ,MaxDate = MAX(CCS.StartDate)
                     FROM #tOperOfCheck OC
                     JOIN dbo.Un_Unit U ON U.UnitID = OC.UnitID
                     JOIN Un_ConventionConventionState CCS ON CCS.ConventionID = U.ConventionID
                    GROUP BY CCS.ConventionID
                  ) CS ON U.ConventionID = CS.ConventionID
             JOIN Un_ConventionConventionState CCS ON CCS.ConventionID = CS.ConventionID AND CCS.StartDate = CS.MaxDate
             JOIN Un_UnitReductionCotisation URC2 ON UR.UnitReductionID = URC2.UnitReductionID AND URC2.CotisationID <> URC.CotisationID
             JOIN Un_Cotisation Ct2 ON Ct2.CotisationID = URC2.CotisationID
             JOIN Un_Oper O2 ON O2.OperID = Ct2.OperID AND O2.OperTypeID = 'TFR' -- Transfert de frais
            WHERE UR.ReductionDate = ISNULL(U.TerminatedDate,0) -- La résiliation est complète
              AND URR.UnitReductionReasonID <> 7 -- La raison de résiliation n'est pas "sans NAS après un (1) an"
              --AND URR.UnitReductionReason <> 'sans NAS après un (1) an' -- La raison de résiliation n'est pas "sans NAS après un (1) an"
              AND CCS.ConventionStateID = 'FRM' -- La convention est résilié.
            GROUP BY OC.iCheckID
           HAVING COUNT(DISTINCT C.ConventionID) <= 4 -- Quatre conventions et moins

      IF @@ERROR <> 0 
         SET @iResult = -2
   END

   IF @iResult > 0
   BEGIN
      -- Recherche des chèques pour la lettre de remboursement d'épargne
      INSERT INTO @RESCheckWithoutNASTable
           SELECT OC.iCheckID
             FROM #tOperOfCheck OC
             JOIN Un_Cotisation Ct ON Ct.OperID = OC.OperID AND Ct.UnitID = OC.UnitID
             JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
             JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
             JOIN Un_UnitReductionCotisation URC ON URC.CotisationID = Ct.CotisationID
             JOIN Un_UnitReduction UR ON UR.UnitReductionID = URC.UnitReductionID
             JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID
             JOIN (SELECT CCS.ConventionID
                         ,MaxDate = MAX(CCS.StartDate)
                     FROM #tOperOfCheck OC
                     JOIN dbo.Un_Unit U ON U.UnitID = OC.UnitID
                     JOIN Un_ConventionConventionState CCS ON CCS.ConventionID = U.ConventionID
                    GROUP BY CCS.ConventionID
) CS ON U.ConventionID = CS.ConventionID
             JOIN Un_ConventionConventionState CCS ON CCS.ConventionID = CS.ConventionID AND CCS.StartDate = CS.MaxDate
             JOIN Un_UnitReductionCotisation URC2 ON UR.UnitReductionID = URC2.UnitReductionID AND URC2.CotisationID <> URC.CotisationID
             JOIN Un_Cotisation Ct2 ON Ct2.CotisationID = URC2.CotisationID
             JOIN Un_Oper O2 ON O2.OperID = Ct2.OperID AND O2.OperTypeID = 'TFR'
            WHERE UR.ReductionDate = ISNULL(U.TerminatedDate,0) -- La résiliation n'est pas complète
              AND URR.UnitReductionReasonID = 7 -- La raison de résiliation n'est pas "sans NAS après un (1) an"
              --AND URR.UnitReductionReason = 'sans NAS après un (1) an' -- La raison de résiliation est "sans NAS après un (1) an"
              AND CCS.ConventionStateID = 'FRM' -- La convention est résilié.
            GROUP BY OC.iCheckID
         --HAVING COUNT(DISTINCT C.ConventionID) = 1 -- Une seule convention

      IF @@ERROR <> 0 
         SET @iResult = -3
   END

   IF @iResult > 0
   BEGIN
      -- Insertion des chèques dans un blob
      DECLARE CUR_CheckID CURSOR FOR
         SELECT iCheckID
           FROM @RESCheckTable

      OPEN CUR_CheckID
      FETCH NEXT FROM CUR_CheckID INTO @iCheckID

      WHILE @@FETCH_STATUS = 0
      BEGIN
         IF @BlobID < 0
         BEGIN
            INSERT INTO CRI_Blob(txBlob) VALUES (CAST(@iCheckID AS VARCHAR)+',')
            SET @BlobID = SCOPE_IDENTITY()
         END
         ELSE
         BEGIN
            SELECT @iBlobPtr = TEXTPTR(txBlob)
              FROM CRI_Blob 
             WHERE iBlobID = @BlobID

            SET @TmpString = CAST(@iCheckID AS VARCHAR)+','
            UPDATETEXT CRI_Blob.txBlob @iBlobPtr NULL NULL @TmpString
         END

         FETCH NEXT FROM CUR_CheckID INTO @iCheckID
      END

      CLOSE CUR_CheckID
      DEALLOCATE CUR_CheckID

      -- Commande des lettres de remboursement d'épargne
      IF @BlobID > 0
         EXECUTE @iResultLetter = RP_UN_RESCheckLetter @iConnectID, @BlobID, 3
   END

   IF @iResult > 0
   BEGIN
      SET @BlobID = -1

      -- Insertion des chèques dans un blob
      DECLARE CUR_CheckWithoutNASID CURSOR FOR
         SELECT iCheckID
           FROM @RESCheckWithoutNASTable

      OPEN CUR_CheckWithoutNASID
      FETCH NEXT FROM CUR_CheckWithoutNASID INTO @iCheckID

		WHILE @@FETCH_STATUS = 0 AND @iResult > 0
		BEGIN
			IF @BlobID < 0
			BEGIN
				INSERT INTO CRI_Blob(txBlob) VALUES (CAST(@iCheckID AS VARCHAR)+',')

				SET @BlobID = SCOPE_IDENTITY()
			END
			ELSE
			BEGIN
				SELECT @iBlobPtr = TEXTPTR(txBlob) 
				FROM CRI_Blob 
				WHERE iBlobID = @BlobID
			
				SET @TmpString = CAST(@iCheckID AS VARCHAR)+','

				UPDATETEXT CRI_Blob.txBlob @iBlobPtr NULL NULL @TmpString
			END

			FETCH NEXT FROM CUR_CheckWithoutNASID
			INTO
				@iCheckID
		END

		CLOSE CUR_CheckWithoutNASID
		DEALLOCATE CUR_CheckWithoutNASID	

		-- Commande des lettres de résiliation sans NAS - chèque émis
		IF @BlobID > 0 AND @iResult > 0
			EXECUTE @iResultLetter = RP_UN_RESCheckWithoutNAS @iConnectID, @BlobID, 3
	END

	IF @iResult > 0
	BEGIN
		-- Va chercher les numéros de chèques de la chaîne de caractères
		INSERT INTO #tCheckToPrint (
				iCheckID )
			SELECT iVal
			FROM dbo.FN_CRI_BlobToIntegerTable(@iBlobID)

		IF @@ERROR <> 0 
			SET @iResult = -4
	END

	IF @iResult > 0
	BEGIN
		-- Va chercher le type d'opération du chèque (Retrait, Résiliation, etc.)
		UPDATE #tCheckToPrint
		SET vcRefType = V.vcRefType
		FROM #tCheckToPrint P
		JOIN (
			SELECT 
				P.iCheckID,
				vcRefType = MAX(O.vcRefType)
			FROM #tCheckToPrint P
			JOIN CHQ_CheckOperationDetail COD ON COD.iCheckID = P.iCheckID
			JOIN CHQ_OperationDetail OD ON OD.iOperationDetailID = COD.iOperationDetailID
			JOIN CHQ_Operation O ON O.iOperationID = OD.iOperationID
			GROUP BY P.iCheckID
			) V ON V.iCheckID = P.iCheckID

		IF @@ERROR <> 0 
			SET @iResult = -5	
	END

	IF @iResult > 0
	BEGIN
		-- Compte le nombre de lignes du talon des chèques pour les chèques dont le talon n'est pas détaillé
		UPDATE #tCheckToPrint
		SET iCheckStubDtlLines = V.iCheckStubDtlLines
		FROM #tCheckToPrint P
		JOIN (
			SELECT 
				CT.iCheckID, -- ID du chèque
				iCheckStubDtlLines = COUNT(DISTINCT OD.iOperationID)
			FROM #tCheckToPrint CT
			JOIN CHQ_CheckOperationDetail COD ON COD.iCheckID = CT.iCheckID
			JOIN CHQ_OperationDetail OD ON OD.iOperationDetailID = COD.iOperationDetailID
			WHERE CT.vcRefType NOT IN (SELECT vcRefType FROM CHQ_CheckStubWithDetail)
			GROUP BY CT.iCheckID
			) V ON V.iCheckID = P.iCheckID
	
		IF @@ERROR <> 0 
			SET @iResult = -6	
	END

	IF @iResult > 0
	BEGIN
		-- Compte le nombre de lignes du talon des chèques pour les chèques dont le talon est détaillé
		UPDATE #tCheckToPrint
		SET iCheckStubDtlLines = V.iCheckStubDtlLines
		FROM #tCheckToPrint P
		JOIN (
			SELECT 
				iCheckID,
				iCheckStubDtlLines = COUNT(*)
			FROM (
				SELECT DISTINCT
					CT.iCheckID, -- ID du chèque
					OD.iOperationID,
					A.vcClientDescription
            FROM CHQ_Check C
            JOIN #tCheckToPrint CT ON CT.iCheckID = C.iCheckID
				JOIN CHQ_CheckOperationDetail COD ON COD.iCheckID = CT.iCheckID
				JOIN CHQ_OperationDetail OD ON OD.iOperationDetailID = COD.iOperationDetailID
				JOIN CHQ_Operation O ON O.iOperationID = OD.iOperationID
				JOIN Un_AccountNumber AN ON AN.vcAccountNumber = OD.vcAccount AND O.dtOperation BETWEEN AN.dtStart AND ISNULL(AN.dtEnd,GETDATE())
				JOIN Un_Account A ON A.iAccountID = AN.iAccountID AND A.iID_Regime = C.iID_Regime
				WHERE CT.vcRefType IN (SELECT vcRefType FROM CHQ_CheckStubWithDetail)
				) V
			GROUP BY iCheckID
			) V ON V.iCheckID = P.iCheckID

		IF @@ERROR <> 0 
			SET @iResult = -7	
	END

	IF @iResult > 0
	BEGIN
		-- Met à jour le chèque avec l'information qu'on a collecté
		UPDATE CHQ_Check
		SET
			iTemplateID = @iTemplateID, -- Modèle du chèque
			iCheckNumber = @iStartCheckNumber+T.iAddToNumber, -- Numéro du chèque
			bCheckStubDetailled =  -- Niveau de détail du talon
				CASE 
					WHEN D.vcRefType IS NULL THEN 0
				ELSE 1
				END,
			iCheckStubDtlLines = T.iCheckStubDtlLines -- Nombre de ligne de détails sur le talon
		FROM CHQ_Check
		JOIN #tCheckToPrint T ON T.iCheckID = CHQ_Check.iCheckID
		LEFT JOIN CHQ_CheckStubWithDetail D ON D.vcRefType = T.vcRefType

		IF @@ERROR <> 0 
			SET @iResult = -8
	END

   SELECT iCheckID -- ID du cheque.
         ,iTemplateID -- ID du template.
         ,iCheckNumber -- Numéro du chèque
         ,dtEmission -- La date du chèque.
         ,vcLastName -- Nom de famille du destinataire du chèque.
         ,vcFirstName -- 	Prénom du destinataire du chèque.
         ,vcAddress -- Adresse du destinataire du chèque
         ,vcCity -- La ville du destinataire du chèque.
         ,vcProvOrState -- Le province du destinataire du chèque.
         ,vcCountry -- Le pays du destinataire du chèque.
         ,vcPostalCode -- Le code postal du destinataire du chèque.
         ,fAmount -- Le montant du chèque.
         ,vcRefType -- Le type des opérations liées au chèque.
         ,iOperationID -- ID de l’opération
         ,vcDescription -- Description de l’opération (Ex : U-20010101001).
         ,fOperationAmount -- Le montant de l’opération chèque.
         ,bIsCompany -- Indique s'il s'agit d'une compagnie.
     FROM (SELECT DISTINCT C.iCheckID -- ID du cheque.
                 ,C.iTemplateID -- ID du template.
                 ,C.iCheckNumber -- Numéro du chèque
                 ,C.dtEmission -- La date du chèque.
                 ,vcLastName = H.LastName -- Nom de famille du destinataire du chèque.
                 ,vcFirstName = H.FirstName --  Prénom du destinataire du chèque.
                 ,vcAddress = ISNULL(A.Address,'') -- Adresse du destinataire du chèque
                 ,vcCity = ISNULL(A.City,'') -- La ville du destinataire du chèque.
                 ,vcProvOrState = ISNULL(A.StateName,'') -- Le province du destinataire du chèque.
                 ,vcCountry = ISNULL(Co.CountryName,'') -- Le pays du destinataire du chèque.
                 ,vcPostalCode = ISNULL(A.ZipCode,'') -- Le code postal du destinataire du chèque.
                 ,C.fAmount -- Le montant du chèque.
                 ,vcRefType = ISNULL(OT.OperTypeDesc,'Détail des talons sur la feuille jointe') -- Le type des opérations liées au chèque.
                 ,O.iOperationID -- ID de l’opération
                 ,O.vcDescription -- Description de l’opération (Ex : U-20010101001).
                 ,fOperationAmount = 
                  CASE 
                     WHEN C.bCheckStubDetailled = 0 THEN ISNULL(ODA.fAmount,0)
                     ELSE 0
                  END -- Le montant de l’opération chèque.
                 ,bIsCompany = H.IsCompany
                 ,vcTri = O.vcDescription+CAST(O.iOperationID AS VARCHAR(10))
             FROM CHQ_Check C
             JOIN #tCheckToPrint CT ON CT.iCheckID = C.iCheckID
             JOIN CHQ_Payee P ON P.iPayeeID = C.iPayeeID
             JOIN dbo.Mo_Human H ON H.HumanID = P.iPayeeID
             LEFT JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
             LEFT JOIN Mo_Country Co ON Co.CountryID = A.CountryID
             JOIN CHQ_Template T ON T.iTemplateID = C.iTemplateID
             LEFT JOIN CHQ_CheckOperationDetail COD ON COD.iCheckID = C.iCheckID AND C.iCheckStubDtlLines <= T.iMaxStubDtlLines
             LEFT JOIN CHQ_OperationDetail OD ON OD.iOperationDetailID = COD.iOperationDetailID
             LEFT JOIN CHQ_Operation O ON O.iOperationID = OD.iOperationID
             LEFT JOIN Un_OperType OT ON OT.OperTypeID = RTRIM(O.vcRefType)
             LEFT JOIN (SELECT ODA.iOperationID
                              ,fAmount = SUM(ODA.fAmount)
                          FROM (SELECT DISTINCT OD.iOperationID
                                  FROM CHQ_Check C
                                  JOIN #tCheckToPrint CT ON CT.iCheckID = C.iCheckID
                                  JOIN CHQ_CheckOperationDetail COD ON COD.iCheckID = C.iCheckID
                                  JOIN CHQ_OperationDetail OD ON OD.iOperationDetailID = COD.iOperationDetailID
                                ) V
                           JOIN CHQ_Operation O ON O.iOperationID = V.iOperationID
                           JOIN CHQ_OperationDetail ODA ON ODA.iOperationID = O.iOperationID AND ODA.vcAccount = O.vcAccount
                          GROUP BY ODA.iOperationID
                       ) ODA ON ODA.iOperationID = O.iOperationID
                 WHERE C.iCheckStatusID = 4
                   AND @iCheckBookID = T.iCheckBookID
           ---------
           UNION ALL
           ---------
           SELECT DISTINCT C.iCheckID -- ID du cheque.
                 ,C.iTemplateID -- ID du template.
                 ,C.iCheckNumber -- Numéro du chèque
                 ,C.dtEmission -- La date du chèque.
                 ,vcLastName = H.LastName -- Nom de famille du destinataire du chèque.
                 ,vcFirstName = H.FirstName -- 	Prénom du destinataire du chèque.
                 ,vcAddress = ISNULL(A.Address,'') -- Adresse du destinataire du chèque
                 ,vcCity = ISNULL(A.City,'') -- La ville du destinataire du chèque.
                 ,vcProvOrState = ISNULL(A.StateName,'') -- Le province du destinataire du chèque.
                 ,vcCountry = ISNULL(Co.CountryName,'') -- Le pays du destinataire du chèque.
                 ,vcPostalCode = ISNULL(A.ZipCode,'') -- Le code postal du destinataire du chèque.
                 ,C.fAmount -- Le montant du chèque.
                 ,vcRefType = '' -- Le type des opérations liées au chèque.
                 ,O.iOperationID -- ID de l’opération
       ,vcDescription = ' '+ODA.vcClientDescription -- Description de l’opération (Ex : U-20010101001).
                 ,fOperationAmount = ODA.fAmount -- Le montant de l’opération chèque.
                 ,bIsCompany = H.IsCompany
                 ,vcTri = O.vcDescription+CAST(O.iOperationID AS VARCHAR(10))+ODA.vcClientDescription
             FROM CHQ_Check C
             JOIN #tCheckToPrint CT ON CT.iCheckID = C.iCheckID
             JOIN CHQ_Payee P ON P.iPayeeID = C.iPayeeID
             JOIN dbo.Mo_Human H ON H.HumanID = P.iPayeeID
             LEFT JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
             LEFT JOIN Mo_Country Co ON Co.CountryID = A.CountryID
             JOIN CHQ_Template T ON T.iTemplateID = C.iTemplateID
             JOIN CHQ_CheckOperationDetail COD ON COD.iCheckID = C.iCheckID AND C.iCheckStubDtlLines <= T.iMaxStubDtlLines
             JOIN CHQ_OperationDetail OD ON OD.iOperationDetailID = COD.iOperationDetailID
             JOIN CHQ_Operation O ON O.iOperationID = OD.iOperationID
             JOIN Un_OperType OT ON OT.OperTypeID = RTRIM(O.vcRefType)
             JOIN (SELECT OD.iOperationID
                         ,A.vcClientDescription
                         ,fAmount = -SUM(OD.fAmount)
                     FROM (SELECT DISTINCT OD.iOperationID, C.iID_Regime
                             FROM CHQ_Check C
                             JOIN #tCheckToPrint CT ON CT.iCheckID = C.iCheckID
                             JOIN CHQ_CheckOperationDetail COD ON COD.iCheckID = C.iCheckID
                             JOIN CHQ_OperationDetail OD ON OD.iOperationDetailID = COD.iOperationDetailID
                            WHERE C.bCheckStubDetailled = 1
                          ) V
                     JOIN CHQ_Operation O ON O.iOperationID = V.iOperationID
                     JOIN CHQ_OperationDetail OD ON OD.iOperationID = O.iOperationID
                     JOIN Un_AccountNumber AN ON AN.vcAccountNumber = OD.vcAccount AND O.dtOperation BETWEEN AN.dtStart AND ISNULL(AN.dtEnd,GETDATE())
                     JOIN Un_Account A ON A.iAccountID = AN.iAccountID 
							 AND A.iID_Regime = V.iID_Regime
                    WHERE OD.vcAccount <> O.vcAccount
                    GROUP BY OD.iOperationID
                         ,A.vcClientDescription
                  ) ODA ON ODA.iOperationID = O.iOperationID
            WHERE C.iCheckStatusID = 4
              AND @iCheckBookID = T.iCheckBookID
          ) V
    ORDER BY iCheckNumber
            ,vcTri

	IF @iResult > 0
		COMMIT TRANSACTION
	ELSE
		ROLLBACK TRANSACTION

	RETURN @iResult 
END


