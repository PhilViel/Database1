/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc

Nom                 : TT_CHQ_MissingCheckNumber
Description         : Procédure qui traite les chèques manquants.
Valeurs de retours  : @ReturnValue :
                         > 0 : Le traitement a réussi.
                         < 0 : Le traitement a échoué.

Exemple d’appel     : EXECUTE [dbo].[TT_CHQ_MissingCheckNumber] 0, 0, 1

Historique des modifications:
               Date        Programmeur            Description
               ----------  ---------------------- ---------------------------
ADX0000714  IA 2005-09-13  Bruno Lapointe         Création
ADX0001421  IA 2007-06-13  Bruno Lapointe         Status Externe.
               2010-06-09  Danielle Côté          Ajout traitement fiducies distinctes par régime

****************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_CHQ_MissingCheckNumber] 
(
   @iConnectID              INT -- ID unique de la connexion.
  ,@iBlobID                 INT -- ID du blob qui contient les objets de chèques manquant.
  ,@iID_Regroupement_Regime INT
)
AS
BEGIN
   DECLARE
      @iResult      INTEGER
     ,@iSPID        INTEGER
     ,@iCheckID     INTEGER
     ,@iCheckNumber INTEGER
     ,@vcReason     VARCHAR(50)
     ,@iID_Regime   INT

   SET @iResult = 1
   SET @iSPID = @@SPID

   CREATE TABLE #tCHQ_MissingCheckNumber 
               (iCheckNumber INTEGER
               ,vcReason VARCHAR(50))

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

   INSERT INTO #tCHQ_MissingCheckNumber 
              (iCheckNumber
              ,vcReason)
        SELECT iCheckNumber
              ,vcReason
          FROM dbo.FN_CHQ_MissingCheckNumber(@iSPID)

   DELETE FROM CRI_ObjectOfBlob
    WHERE iSPID = @iSPID

   -----------------
   BEGIN TRANSACTION
   -----------------

   -- Sélection d'un seul ID de régime pour CHQ_Check.iID_Regime
   SELECT @iID_Regime = iID_Plan
     FROM (SELECT iID_Plan
                 ,ROW_NUMBER() OVER (ORDER BY iID_Plan) AS ROWID
             FROM [dbo].[fntCONV_ObtenirRegimes](@iID_Regroupement_Regime)) AS ROW
    WHERE ROW.ROWID = 1

   -- Le numéro de chèque est déjà utilisé.
   IF EXISTS (SELECT iCheckID
                FROM CHQ_Check C
                JOIN #tCHQ_MissingCheckNumber T ON T.iCheckNumber = C.iCheckNumber
               WHERE iID_Regime IN (SELECT iID_Plan FROM [dbo].[fntCONV_ObtenirRegimes](@iID_Regroupement_Regime)))
      SET @iResult = -1

      -- Boucle pour insérer un chèque bidon par chèque manquant
      DECLARE crMissingCheckNumber CURSOR FOR
         SELECT iCheckNumber
               ,vcReason
           FROM #tCHQ_MissingCheckNumber

      OPEN crMissingCheckNumber
      FETCH NEXT FROM crMissingCheckNumber INTO @iCheckNumber, @vcReason

      WHILE @@FETCH_STATUS = 0 AND @iResult > 0
      BEGIN

         -- Insère un chèque
         INSERT INTO CHQ_Check
                    (iCheckNumber
                    ,dtEmission
                    ,fAmount
                    ,iCheckStatusID
                    ,iID_Regime)
             VALUES (@iCheckNumber
                    ,GETDATE()
                    ,0
                    ,7
                    ,@iID_Regime)

         SET @iCheckID = SCOPE_IDENTITY()

         IF @@ERROR = 0 AND @iCheckID > 0
         BEGIN
            -- Insère l'historique de statut du chèque
            INSERT INTO CHQ_CheckHistory 
                       (iCheckID
                       ,iCheckStatusID
                       ,iConnectID
                       ,dtHistory
                       ,vcReason)
                VALUES (@iCheckID
                       ,7
                       ,@iConnectID
                       ,GETDATE()
                       ,@vcReason)

            IF @@ERROR <> 0
               SET @iResult = -2
            END
            ELSE
               SET @iResult = -3

      FETCH NEXT FROM crMissingCheckNumber INTO @iCheckNumber, @vcReason
   END

   CLOSE crMissingCheckNumber
   DEALLOCATE crMissingCheckNumber

   IF @iResult > 0
      ------------------
      COMMIT TRANSACTION
      ------------------
   ELSE
      --------------------
      ROLLBACK TRANSACTION
      --------------------

   RETURN(@iResult)
END
