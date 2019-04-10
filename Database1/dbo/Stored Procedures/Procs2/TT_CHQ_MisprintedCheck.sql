/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc

Nom                 : TT_CHQ_MisprintedCheck
Description         : Procédure qui traite les chèques défectueux.
Valeurs de retours  : @ReturnValue :
                      > 0 : Le traitement a réussi. Retourne le dernier numéro de chèque disponible.
                      < 0 : Le traitement a échoué.

Historique des modifications:
               Date          Programmeur              Description
               ------------  ------------------------ ---------------------------
ADX0000714	IA	2005-09-13    Bruno Lapointe           Création
ADX0001169	IA	2006-10-27    Alain Quirion            Modification : Suppresions des lettres de remboursement d'Épargne 
                                                      commandées automatiquement par le module des chèques
               2010-06-09  Danielle Côté              Ajout traitement fiducies distinctes par régime

****************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_CHQ_MisprintedCheck]
(
   @iConnectID	INTEGER -- ID unique de la connexion.
  ,@iBlobID	INTEGER  -- ID du blob qui contient les objets de chèques manquant.
  ,@iID_Regroupement_Regime INT
)
AS
BEGIN
   DECLARE
      @iResult INTEGER
     ,@iSPID INTEGER
     ,@iNewCheckID INTEGER
     ,@iCheckID INTEGER
     ,@iCheckNumber INTEGER
     ,@vcReason VARCHAR(50)
     ,@bPropose BIT
     ,@bLost BIT
     ,@iID_Regime INT

   -- Cette valeur doit être un paramètre d'entrée	suite au modifications de LGS 07-2010
   SET @iID_Regroupement_Regime = @iID_Regroupement_Regime

   SET @iResult = 1
   SET @iSPID = @@SPID

   DECLARE @DocToDeleteTable TABLE
          (DocID INTEGER)

   CREATE TABLE #tCHQ_MisprintedCheck
               (iStartCheckNumber INTEGER
               ,iEndCheckNumber INTEGER
               ,vcReason VARCHAR(50)
               ,bPropose BIT
               ,bLost BIT)

   INSERT INTO CRI_ObjectOfBlob
              (iSPID
              ,iObjectID
              ,vcClassName
              ,vcFieldName
              ,txValue)
        SELECT @iSPID
              ,iObjectID
              ,vcClassName
              ,vcFieldName
              ,txValue
          FROM dbo.FN_CRI_DecodeBlob(@iBlobID)

   INSERT INTO #tCHQ_MisprintedCheck
              (iStartCheckNumber
              ,iEndCheckNumber
              ,vcReason
              ,bPropose
              ,bLost)
        SELECT iStartCheckNumber
              ,iEndCheckNumber
              ,vcReason
              ,bPropose
              ,bLost
          FROM dbo.FN_CHQ_MisprintedCheck(@iSPID)

   DELETE FROM CRI_ObjectOfBlob
    WHERE iSPID = @iSPID

   -----------------
   BEGIN TRANSACTION
   -----------------

   /*-----------------------------------------------------------------------------------
   -- Supprimer les lettres de remboursement d'épargne liées au chèques mal imprimés ainsi
   -- que les lettres de résiliation sans NAS - chèque émis.  A partir du chèque, trouver 
   -- la/les conventions et supprimer le document lié a cette convention ainsi que l'historique.
   -------------------------------------------------------------------------------------*/
   INSERT INTO @DocToDeleteTable
   SELECT DISTINCT D.DocID
     FROM CHQ_Check C
     JOIN #tCHQ_MisprintedCheck M ON C.iCheckNumber BETWEEN M.iStartCheckNumber AND M.iEndCheckNumber
     JOIN CHQ_CheckOperationDetail COP ON C.iCheckID = COP.iCheckID
     JOIN CHQ_OperationDetail OD ON COP.iOperationDetailID = OD.iOperationDetailID
     JOIN CHQ_Operation CP ON OD.iOperationID = CP.iOperationID
     JOIN Un_OperLinkToCHQOperation OL ON CP.iOperationID = OL.iOperationID
     JOIN Un_Oper OP ON OL.OperID = OP.OperID
     JOIN Un_Cotisation CT ON OP.OperID = CT.OperID
     JOIN dbo.Un_Unit UN ON CT.UnitID = UN.UnitID
     JOIN dbo.Un_Convention V ON UN.ConventionID = V.ConventionID
     JOIN CRQ_DocLink L ON L.DocLinkID = V.ConventionID
     JOIN CRQ_Doc D ON L.DocID = D.DocID
     JOIN CRQ_DocTemplate DTp ON DTp.DocTemplateID = D.DocTemplateID
     JOIN CRQ_DocType DT ON DT.DocTypeID = DTp.DocTypeID
     LEFT JOIN CRQ_DocPrinted DP ON D.DocID = DP.DocID
    WHERE L.DocLinkType = 1 -- ConventionID lié à une convention
      AND (DT.DocTypeCode  = 'RESCheckLetter_1' -- Lettre de remboursement d'épargne
       OR  DT.DocTypeCode  = 'RESCheckLetter_2'
       OR  DT.DocTypeCode  = 'RESCheckLetter_3'
       OR  DT.DocTypeCode  = 'RESCheckLetter_4'
       OR  DT.DocTypeCode  = 'RESCheckWithoutNAS') -- Lettre de résiliation sans NAS
      AND  DP.DocPrintedID IS NULL -- Non imprimé

   -- Suppresion des documents
   DELETE CRQ_DocLink
     FROM CRQ_DocLink
     JOIN @DocToDeleteTable C ON C.DocID = CRQ_DocLink.DocID

   DELETE CRQ_Doc
     FROM CRQ_Doc
     JOIN @DocToDeleteTable C ON C.DocID = CRQ_Doc.DocID

   -- Récupère les id de la table CHQ_Check compris dans l'intervalle des no de chèque
   -- afin de mettre à jour les informations suite au changement
   DECLARE crMisprintedCheck CURSOR FOR
      SELECT C.iCheckID
            ,M.vcReason
            ,M.bPropose
            ,M.bLost
        FROM CHQ_Check C
        JOIN #tCHQ_MisprintedCheck M ON C.iCheckNumber BETWEEN M.iStartCheckNumber AND M.iEndCheckNumber
		 WHERE C.iID_Regime IN (SELECT iID_Plan FROM [dbo].[fntCONV_ObtenirRegimes](@iID_Regroupement_Regime))

   OPEN crMisprintedCheck
   FETCH NEXT FROM crMisprintedCheck INTO @iCheckID, @vcReason, @bPropose, @bLost

   WHILE @@FETCH_STATUS = 0 AND @iResult > 0
   BEGIN
      IF @bLost = 1
      BEGIN
         -- Chèques perdus
         UPDATE CHQ_Check
            SET iCheckStatusID = 5
          WHERE iCheckID = @iCheckID

         IF @@ERROR <> 0
            SET @iResult = -1

         IF @iResult > 0
         BEGIN
            -- Insère l'historique du changement au statut de chèque 5
            INSERT INTO CHQ_CheckHistory
                       (iCheckID
                       ,iCheckStatusID
                       ,iConnectID
                       ,dtHistory
                       ,vcReason)
                VALUES (@iCheckID
                       ,5
                       ,@iConnectID
                       ,GETDATE()
                       ,@vcReason)

            IF @@ERROR <> 0
               SET @iResult = -2
         END

         -- Si le chèque perdu doit aussi être reproduit
         IF @iResult > 0 AND @bPropose = 1
         BEGIN
            -- Insère un chèque identique sans numéro de chèque 
            -- et statut = Proposition - Accepté.
            INSERT INTO CHQ_Check 
                  (iCheckNumber
                  ,iCheckStatusID
                  ,iLangID
                  ,iPayeeID
                  ,iTemplateID
                  ,dtEmission
                  ,fAmount
                  ,vcFirstName
                  ,vcLastName
                  ,vcAddress
                  ,vcCity
                  ,vcStateName
                  ,vcCountry
                  ,vcZipCode
                  ,iID_Regime)
            SELECT NULL
                  ,2
                  ,iLangID
                  ,iPayeeID
                  ,iTemplateID
                  ,dtEmission
                  ,fAmount
                  ,vcFirstName
                  ,vcLastName
                  ,vcAddress
                  ,vcCity
                  ,vcStateName
                  ,vcCountry
                  ,vcZipCode
                  ,iID_Regime
              FROM CHQ_Check
             WHERE iCheckID = @iCheckID

            SET @iNewCheckID = SCOPE_IDENTITY()

            IF @@ERROR <> 0 OR @iNewCheckID <= 0
               SET @iResult = -3

            IF @iResult > 0
      BEGIN
               -- Insère le détail de l'opération
               INSERT INTO CHQ_CheckOperationDetail
                          (iCheckID
                          ,iOperationDetailID)
                    SELECT @iNewCheckID
                          ,iOperationDetailID
                      FROM CHQ_CheckOperationDetail
                     WHERE iCheckID = @iCheckID

               IF @@ERROR <> 0
                  SET @iResult = -4
            END

            SELECT @iCheckNumber = iCheckNumber
              FROM CHQ_Check
             WHERE iCheckID = @iCheckID

            IF @iResult > 0
            BEGIN
               -- Insère l'historique du changement au statut de chèque 1
               INSERT INTO CHQ_CheckHistory
                          (iCheckID
                          ,iCheckStatusID
                          ,iConnectID
                          ,dtHistory
                          ,vcReason)
                   VALUES (@iNewCheckID
                          ,1
                          ,@iConnectID
                          ,GETDATE()
                          ,'En remplacement du chèque ' + CAST(@iCheckNumber AS VARCHAR(30)))

               IF @@ERROR <> 0
                  SET @iResult = -5
            END

            IF @iResult > 0
            BEGIN
               -- Insère l'historique du changement au statut de chèque 2
               INSERT INTO CHQ_CheckHistory
                          (iCheckID
                          ,iCheckStatusID
                          ,iConnectID
                          ,dtHistory
                          ,vcReason)
                   VALUES (@iNewCheckID
                          ,2
                          ,@iConnectID
                          ,GETDATE()
                          ,'En remplacement du chèque ' + CAST(@iCheckNumber AS VARCHAR(30)))

               IF @@ERROR <> 0
                  SET @iResult = -6
            END
         END
      END
      ELSE
      BEGIN
         -- Chèques à reproduire qui ne sont pas perdus
         IF @bPropose = 1
         BEGIN
            UPDATE CHQ_Check
               SET iCheckNumber = NULL
                  ,iCheckStatusID = 2
             WHERE iCheckID = @iCheckID

            IF @@ERROR <> 0
               SET @iResult = -7

            IF @iResult > 0
            BEGIN
               -- Insère l'historique du changement au statut de chèque 2
               INSERT INTO CHQ_CheckHistory
                          (iCheckID
                          ,iCheckStatusID
                          ,iConnectID
                          ,dtHistory
                          ,vcReason)
                   VALUES (@iCheckID
                          ,2
                          ,@iConnectID
                          ,GETDATE()
                          ,@vcReason)

               IF @@ERROR <> 0
                  SET @iResult = -8
            END
         END
         ELSE
         BEGIN
            -- Chèques refusés
            UPDATE CHQ_Check
               SET iCheckNumber = NULL
                  ,iCheckStatusID = 3
             WHERE iCheckID = @iCheckID

            IF @@ERROR <> 0
               SET @iResult = -9

            IF @iResult > 0
            BEGIN
               -- Insère l'historique de statut du chèque
               INSERT INTO CHQ_CheckHistory
                          (iCheckID
                          ,iCheckStatusID
                          ,iConnectID
                          ,dtHistory
                          ,vcReason)
                   VALUES (@iCheckID
                          ,3
                          ,@iConnectID
                          ,GETDATE()
                          ,@vcReason)

               IF @@ERROR <> 0
                  SET @iResult = -10
            END
         END
      END

      FETCH NEXT FROM crMisprintedCheck INTO @iCheckID, @vcReason, @bPropose, @bLost
   END

   CLOSE crMisprintedCheck
   DEALLOCATE crMisprintedCheck

   IF @iResult > 0
   BEGIN

      SELECT @iResult = ISNULL(MAX(iCheckNumber),1)
        FROM CHQ_Check
       WHERE iID_Regime IN (SELECT iID_Plan FROM [dbo].[fntCONV_ObtenirRegimes](@iID_Regroupement_Regime))
      ------------------
      COMMIT TRANSACTION
      ------------------
   END
   ELSE
      --------------------
      ROLLBACK TRANSACTION
      --------------------

   RETURN(@iResult)
END


