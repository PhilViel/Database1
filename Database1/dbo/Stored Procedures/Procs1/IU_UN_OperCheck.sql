/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc

Nom                 : IU_UN_OperCheck
Description         : Inscrit ou modifie l'opération du module des chèques suite à l'ajout ou la modification d'une
                      opération du système de convention.
Valeurs de retours  : @Return_Value
                      <0 : Erreur à la sauvegarde.
                      >0 : Sauvegarde réussie.

Historique des modifications:
               Date        Programmeur            Description
               ----------  ---------------------- ---------------------------
ADX0000753  IA 2005-10-05  Bruno Lapointe         Création
ADX0000861  IA 2006-03-30  Bruno Lapointe         Adaptation PCEE 4.3
ADX0002426  BR 2007-05-23  Bruno Lapointe         Gestion de la table Un_CESP.
				2009-02-13	Patrick Robitaille     Supprimer les détails d'opérations pour les RIN sur les individuels à
																chaque modification de l'opération afin qu'ils soient correctement réinscrits
																car l'ajout/retrait du TFR dans l'opération RIN causait problème dans le module de chèques.
				2009-07-13	Éric Deshaies			Implantation d'une mesure temporaire pour sortir les montants d'IQÉÉ
																avec les PAE avant que les montants d'IQÉÉ soient injectés dans les
																conventions.
				2009-12-04	Éric Deshaies			Modifier la mesure temporaire parce que l'IQÉÉ et les intérêts de l'IQÉÉ
																sont dans les conventions.
				2010-06-03	Danielle Côté			Ajout traitement fiducies distinctes par régime
				2014-04-16	Pierre-Luc Simard	Ajout de la possibilité de changer le destinataire
				2014-04-22	Pierre-Luc Simard	Retrait de la mesure temporaire de l'IQEE pusique déjà calculée via Proacces
				2014-05-06	Pierre-Luc Simard	Ajout d'un distinct pour récupérer le @vcTypePlanConv afin de faire des RIN sur plus d'un groupe d'unité
				2017-07-19	Pierre-Luc Simard	Autorisation du changement de destinataire pour lors d'un prêt REEE
				2017-11-06	Guehel Bouanga		Inserer le destinataire du PAE selon la selection depuis Proacces (CRIT 233)
                2017-11-06  Pierre-Luc Simard   Ajouter le champ @bModifier_DestinataireOriginal pour ne pas créer de changement de destinataire inutilement
                                                Le destinataire par défaut d'un PAE sera le souscripteur au lieu du bénéficiaire
****************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_OperCheck] 
(
   @ConnectID INTEGER -- ID Unique de connexion de l'usager
  ,@OperID INTEGER
  ,@PayeeID INTEGER = NULL
)
AS
BEGIN
   DECLARE
      @iResult INTEGER
     ,@iOperID INTEGER
     ,@dtOperation DATETIME
     ,@vcDescription VARCHAR(100)
     ,@vcRefType VARCHAR(10)
     ,@iOperationID INTEGER
     ,@iOperationPayeeID INTEGER
     ,@iPayeeID INTEGER
     ,@bModifier_DestinataireOriginal BIT
     ,@dtCreated DATETIME
     ,@fAmount MONEY
     ,@vcAccount VARCHAR(50)
     ,@vcDescriptionDtl VARCHAR(75)
     ,@iOperationDetailID INTEGER
     ,@vcBankAccount VARCHAR(50)
     ,@iRGCRecipient INTEGER
     ,@vcTypePlanConv VARCHAR(3)
     ,@vcTypeOper VARCHAR(3),
-------------------------
-- Mesure temporaire IQÉÉ
		@iID_IQEE_PAE INT,
		@iID_Convention INT
-------------------------
     ,@iID_Regroupement_Regime INT
     ,@iID_Regime INT

   SET @iResult = @OperID
   SET @dtCreated = GETDATE()

   SELECT @iRGCRecipient = MAX(R.iRecipientID)
     FROM Un_Recipient R
     JOIN dbo.Mo_Human H ON H.HumanID = R.iRecipientID
    WHERE H.LastName = 'Receveur Général du Canada'

   SELECT @iOperID = O.OperID,
          @dtOperation = O.OperDate,
          @vcDescription = C.ConventionNo,
          @vcRefType = O.OperTypeID,
          @iOperationID = ISNULL(L.iOperationID,-1),
          @iPayeeID =   CASE
			                WHEN O.OperTypeID = 'PAE' 
                                    AND ISNULL(@PayeeID, 0) <> 0 
                                    AND (ISNULL(@PayeeID, 0) = C.SubscriberID 
                                    OR ISNULL(@PayeeID, 0) = C.BeneficiaryID) 
                                THEN @PayeeID -- Utilise le destinataire passé en paramètre comme bénéficiaire original
                            --WHEN O.OperTypeID IN ('PAE', 'AVC') THEN C.BeneficiaryID
                            WHEN O.OperTypeID IN ('RGC') THEN @iRGCRecipient
                            ELSE C.SubscriberID
                        END,
          @bModifier_DestinataireOriginal = 
                        CASE WHEN O.OperTypeID = 'PAE' 
                                    AND ISNULL(@PayeeID, 0) <> 0 
                                    AND (ISNULL(@PayeeID, 0) = C.SubscriberID
                                        OR ISNULL(@PayeeID, 0) = C.BeneficiaryID) 
                        THEN 1
                        ELSE 0 END,    -- Indique si on doit modifier le destinataire original pour celui demandé au lieu de créer un changement de destinataire inutilement
                                    -- Le champ @PayeeID pourra ensuite être réinitialiser     
         @iID_Regime = C.PlanID
    FROM (SELECT V.OperID,
                 ConventionID = MIN(V.ConventionID)
            FROM (SELECT Ct.OperID,
                         U.ConventionID
      FROM Un_Cotisation Ct
                    JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
                   WHERE @OperID = Ct.OperID
                  -----
                  UNION
                  -----
                  SELECT CO.OperID,
                         CO.ConventionID
                    FROM Un_ConventionOper CO
                   WHERE @OperID = CO.OperID
                  -----
                  UNION
                  -----
                  SELECT GG.OperID,
                         GG.ConventionID
                    FROM Un_CESP GG 
                   WHERE @OperID = GG.OperID
                 ) V
           GROUP BY V.OperID
         ) V 
    JOIN Un_Oper O ON O.OperID = V.OperID
    LEFT JOIN Un_OperLinkToCHQOperation L ON L.OperID = V.OperID
    JOIN dbo.Un_Convention C ON C.ConventionID = V.ConventionID
   WHERE O.OperTypeID IN ('RES', 'TFR', 'OUT', 'RIN', 'RET', 'PAE', 'RGC', 'AVC')

   -- Si le destinataire demandé a déjà remplacé le bénéficiaire original on ne fera pas de changement de destinataire 
   IF ISNULL(@bModifier_DestinataireOriginal, 0) = 1
        SET @PayeeID = 0

   SELECT @iID_Regroupement_Regime = [dbo].[fnCONV_ObtenirRegroupementRegime](@iID_Regime)
   SELECT @vcBankAccount = [dbo].[fnCONV_ObtenirCompteFiducie](@iID_Regroupement_Regime)

   -- Insère ou modifie les opérations dans la gestion des chèques (CHQ_Operation)
   EXECUTE @iOperationID = IU_CHQ_Operation 0, @iOperationID, 0, @ConnectID, @dtOperation, @vcDescription, @vcRefType, @vcBankAccount

   IF @iOperationID <= 0
      SET @iResult = -1

   -- Crée le lien entre l'opération du système de convention (Un_Oper) et l'opération du module des chèques (CHQ_Operation),
   -- s'il n'y en avait pas.
   IF @iResult > 0
   AND NOT EXISTS (SELECT iOperationID
                     FROM Un_OperLinkToCHQOperation
                    WHERE iOperationID = @iOperationID)
   BEGIN
      INSERT INTO Un_OperLinkToCHQOperation (OperID, iOperationID)
      VALUES (@iOperID, @iOperationID)

      IF @@ERROR <> 0
         SET @iResult = -2
   END

   -- Inscrit ou modifie le destinataire original dans le module des chèques, s'il ne l'est pas.
   IF @iResult > 0
   AND NOT EXISTS (SELECT iOperationID
                     FROM CHQ_OperationPayee
                    WHERE iOperationID = @iOperationID)
   BEGIN
      -- Inscrit l'humain comme destinataire dans le module des chèques s'il ne l'est pas déjà
      EXECUTE @iPayeeID = IU_CHQ_Payee @ConnectID, @iPayeeID

      IF @iPayeeID <= 0
         SET @iResult = -3
      ELSE
      BEGIN
         -- Inscrit le destinataire dans le module des chèques s'il ne l'est pas déjà
    			EXECUTE @iOperationPayeeID = IU_CHQ_OperationPayee 0, -1, @iPayeeID, @iOperationID, @dtCreated, 1, ''
			
         IF @iOperationPayeeID <= 0
            SET @iResult = -4
      END
   END

   -- Inscrit ou modifie le changement de destinataire dans le module des chèques
   IF @iResult > 0 
   AND (EXISTS (SELECT ChequeSuggestionID
                 FROM Un_ChequeSuggestion
                WHERE OperID = @iOperID)
        OR ISNULL(@PayeeID,0) <> 0)
   BEGIN
      SET @iOperationPayeeID = -1

      -- Va chercher le changement de destinataire s'il est inscrit
      SELECT @iOperationPayeeID = MAX(iOperationPayeeID)
        FROM CHQ_OperationPayee
       WHERE iOperationID = @iOperationID
       GROUP BY iOperationID
      HAVING COUNT(iOperationPayeeID) > 1

      -- Va chercher le destinataire du changement de destinataire.
      SELECT @iPayeeID = iHumanID
        FROM Un_ChequeSuggestion
       WHERE OperID = @iOperID
		
	  IF ISNULL(@PayeeID, 0) <> 0 -- Le changement de destinataire devra être approuvé lors d'une demande provenant du paramètre @PayeeID pour Proacces
		SET @iPayeeID = @PayeeID

      -- Inscrit l'humain du changement de destinataire comme destinataire dans le module des chèques s'il ne l'ai pas déjà
      EXECUTE @iPayeeID = IU_CHQ_Payee @ConnectID, @iPayeeID

      IF @iPayeeID <= 0
         SET @iResult = -5
      ELSE
      BEGIN
		    -- Inscrit le changement de destinataire dans le module des chèques s'il ne l'ai pas déjà
            -- Si le destinataire est "Fondation Universitas Prêt REEE" le changement sera pré-autorisé
            IF @iPayeeID = dbo.fnGENE_ObtenirParametre('OPER_DESTINATAIRE_CHEQUE_PRET_REEE', GETDATE(), NULL, NULL, NULL, NULL, NULL) 
                EXECUTE @iOperationPayeeID = IU_CHQ_OperationPayee 0, @iOperationPayeeID, @iPayeeID, @iOperationID, @dtCreated, 1, ''
			ELSE
                EXECUTE @iOperationPayeeID = IU_CHQ_OperationPayee 0, @iOperationPayeeID, @iPayeeID, @iOperationID, @dtCreated, 0, ''
	
		IF @iOperationPayeeID <= 0
            SET @iResult = -6
      END
   END

   -- Détail des opérations
   IF @iResult > 0
   BEGIN
      -- Table temporaire du détail des opérations
      CREATE TABLE #tCHQ_OperationDetail 
                  (iOperationID INTEGER
                  ,fAmount MONEY
                  ,vcAccount VARCHAR(50) 
                  ,vcDescription VARCHAR(75))
/*
-------------------------
-- Mesure temporaire IQÉÉ
		IF @vcRefType = 'PAE'
			BEGIN
				-- Déterminer l'ID de la convention
				SET @iID_Convention = NULL

				SELECT @iID_Convention = MAX(CO.ConventionID)
				FROM Un_ConventionOper CO
				WHERE CO.OperID = @OperID

				IF @iID_Convention IS NULL
					SELECT @iID_Convention = MAX(C.ConventionID)
					FROM Un_CESP C
					WHERE C.OperID = @OperID
				
				-- Calculer les montants d'IQÉÉ et d'intérêts du PAE et ajouter les transactions dans la convention
				EXECUTE @iID_IQEE_PAE = [dbo].[psTEMP_ObtenirMontantIQEEPourPAE] @iID_Convention, @OperID 
				IF @iID_IQEE_PAE = 0
					SET @iResult = -17
			END
-------------------------
*/
      IF @iResult > 0
      BEGIN
         -- Un_Cotisation.Cotisation
         INSERT INTO #tCHQ_OperationDetail 
                    (iOperationID,
                     fAmount,
                     vcAccount,
                     vcDescription)
              SELECT @iOperationID,
                     Ct.Cotisation,
                     AN.vcAccountNumber,
                     A.vcAccount
                FROM Un_Cotisation Ct
                JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
                JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
                JOIN Un_Plan P ON P.PlanID = C.PlanID
                JOIN Un_MoneyType MT ON MT.OperTypeID = @vcRefType  
                 AND MT.vcTableName = 'Un_Cotisation' AND MT.vcFieldName = 'Cotisation'
                JOIN Un_AccountMoneyType AMT ON AMT.iMoneyTypeID = MT.iMoneyTypeID
                JOIN Un_Account A ON A.iAccountID = AMT.iAccountID AND A.iID_Regime = @iID_Regime
                JOIN Un_AccountNumber AN ON AN.iAccountID = A.iAccountID AND @dtCreated BETWEEN AN.dtStart AND ISNULL(AN.dtEnd,GETDATE())
               WHERE Ct.OperID = @iOperID
                 AND Ct.Cotisation <> 0
                 AND @dtOperation BETWEEN AMT.dtStart AND ISNULL(AMT.dtEnd, @dtOperation)
                 AND @dtOperation BETWEEN AN.dtStart AND ISNULL(AN.dtEnd, @dtOperation)

         IF @@ERROR <> 0
            SET @iResult = -7
      END

      IF @iResult > 0
      BEGIN
         -- Un_Cotisation.Fee
         INSERT INTO #tCHQ_OperationDetail
                    (iOperationID,
                     fAmount,
                     vcAccount,
                     vcDescription)
              SELECT @iOperationID,
                     Ct.Fee,
                     AN.vcAccountNumber,
                     A.vcAccount
                FROM Un_Cotisation Ct
                JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
                JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
                JOIN Un_Plan P ON P.PlanID = C.PlanID
                JOIN Un_MoneyType MT ON MT.OperTypeID = @vcRefType
                 AND MT.vcTableName = 'Un_Cotisation' AND MT.vcFieldName = 'Fee'
                JOIN Un_AccountMoneyType AMT ON AMT.iMoneyTypeID = MT.iMoneyTypeID
                JOIN Un_Account A ON A.iAccountID = AMT.iAccountID AND A.iID_Regime = @iID_Regime
                JOIN Un_AccountNumber AN ON AN.iAccountID = A.iAccountID AND @dtCreated BETWEEN AN.dtStart AND ISNULL(AN.dtEnd,GETDATE())
               WHERE Ct.OperID = @iOperID
                 AND Ct.Fee <> 0
                 AND @dtOperation BETWEEN AMT.dtStart AND ISNULL(AMT.dtEnd, @dtOperation)
                 AND @dtOperation BETWEEN AN.dtStart AND ISNULL(AN.dtEnd, @dtOperation)

      IF @@ERROR <> 0
            SET @iResult = -8
      END

      IF @iResult > 0
      BEGIN
         -- Un_Cotisation.SubscInsur
         INSERT INTO #tCHQ_OperationDetail
                    (iOperationID,
                     fAmount,
                     vcAccount,
                     vcDescription )
              SELECT @iOperationID,
                     Ct.SubscInsur,
                     AN.vcAccountNumber,
                     A.vcAccount
                FROM Un_Cotisation Ct
                JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
                JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
                JOIN Un_Plan P ON P.PlanID = C.PlanID
                JOIN Un_MoneyType MT ON MT.OperTypeID = @vcRefType
                 AND MT.vcTableName = 'Un_Cotisation' AND MT.vcFieldName = 'SubscInsur'
                JOIN Un_AccountMoneyType AMT ON AMT.iMoneyTypeID = MT.iMoneyTypeID
                JOIN Un_Account A ON A.iAccountID = AMT.iAccountID AND A.iID_Regime = @iID_Regime
                JOIN Un_AccountNumber AN ON AN.iAccountID = A.iAccountID AND @dtCreated BETWEEN AN.dtStart AND ISNULL(AN.dtEnd,GETDATE())
               WHERE Ct.OperID = @iOperID
                 AND Ct.SubscInsur <> 0
                 AND @dtOperation BETWEEN AMT.dtStart AND ISNULL(AMT.dtEnd, @dtOperation)
                 AND @dtOperation BETWEEN AN.dtStart AND ISNULL(AN.dtEnd, @dtOperation)

         IF @@ERROR <> 0
            SET @iResult = -9
      END

      IF @iResult > 0
      BEGIN
         -- Un_Cotisation.BenefInsur
            INSERT INTO #tCHQ_OperationDetail
                       (iOperationID,
                        fAmount,
                        vcAccount,
                        vcDescription)
                 SELECT @iOperationID,
                        Ct.BenefInsur,
                        AN.vcAccountNumber,
                        A.vcAccount
                   FROM Un_Cotisation Ct
                   JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
                   JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
                   JOIN Un_Plan P ON P.PlanID = C.PlanID
                   JOIN Un_MoneyType MT ON MT.OperTypeID = @vcRefType
                    AND MT.vcTableName = 'Un_Cotisation' AND MT.vcFieldName = 'BenefInsur'
                   JOIN Un_AccountMoneyType AMT ON AMT.iMoneyTypeID = MT.iMoneyTypeID
                   JOIN Un_Account A ON A.iAccountID = AMT.iAccountID AND A.iID_Regime = @iID_Regime
                   JOIN Un_AccountNumber AN ON AN.iAccountID = A.iAccountID AND @dtCreated BETWEEN AN.dtStart AND ISNULL(AN.dtEnd,GETDATE())
                  WHERE Ct.OperID = @iOperID
                    AND Ct.BenefInsur <> 0
                    AND @dtOperation BETWEEN AMT.dtStart AND ISNULL(AMT.dtEnd, @dtOperation)
                    AND @dtOperation BETWEEN AN.dtStart AND ISNULL(AN.dtEnd, @dtOperation)

         IF @@ERROR <> 0
            SET @iResult = -10
      END

      IF @iResult > 0
      BEGIN
         -- Un_Cotisation.TaxOnInsur
         INSERT INTO #tCHQ_OperationDetail
                    (iOperationID,
                     fAmount,
                     vcAccount,
                     vcDescription)
              SELECT @iOperationID,
                     Ct.TaxOnInsur,
                     AN.vcAccountNumber,
                     A.vcAccount
                FROM Un_Cotisation Ct
                JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
                JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
                JOIN Un_Plan P ON P.PlanID = C.PlanID
                JOIN Un_MoneyType MT ON MT.OperTypeID = @vcRefType 
                 AND MT.vcTableName = 'Un_Cotisation' AND MT.vcFieldName = 'TaxOnInsur'
                JOIN Un_AccountMoneyType AMT ON AMT.iMoneyTypeID = MT.iMoneyTypeID
                JOIN Un_Account A ON A.iAccountID = AMT.iAccountID AND A.iID_Regime = @iID_Regime
                JOIN Un_AccountNumber AN ON AN.iAccountID = A.iAccountID AND @dtCreated BETWEEN AN.dtStart AND ISNULL(AN.dtEnd,GETDATE())
               WHERE Ct.OperID = @iOperID
                 AND Ct.TaxOnInsur <> 0
                 AND @dtOperation BETWEEN AMT.dtStart AND ISNULL(AMT.dtEnd, @dtOperation)
                 AND @dtOperation BETWEEN AN.dtStart AND ISNULL(AN.dtEnd, @dtOperation)

         IF @@ERROR <> 0
            SET @iResult = -11
      END

      IF @iResult > 0
      BEGIN
         -- Un_ConventionOper.ConventionOperAmount
         INSERT INTO #tCHQ_OperationDetail
                    (iOperationID,
                     fAmount,
                     vcAccount,
                     vcDescription)
              SELECT
                     @iOperationID,
                     CO.ConventionOperAmount,
                     AN.vcAccountNumber,
                     A.vcAccount
                FROM Un_ConventionOper CO
                JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
                JOIN Un_Plan P ON P.PlanID = C.PlanID
                JOIN Un_MoneyType MT ON MT.OperTypeID = @vcRefType
                 AND MT.vcTableName = 'Un_ConventionOper' AND MT.vcFieldName = 'ConventionOperAmount' AND MT.vcValueType = CO.ConventionOperTypeID
                JOIN Un_AccountMoneyType AMT ON AMT.iMoneyTypeID = MT.iMoneyTypeID
                JOIN Un_Account A ON A.iAccountID = AMT.iAccountID AND A.iID_Regime = @iID_Regime
                JOIN Un_AccountNumber AN ON AN.iAccountID = A.iAccountID AND @dtCreated BETWEEN AN.dtStart AND ISNULL(AN.dtEnd,GETDATE())
               WHERE CO.OperID = @iOperID
                 AND CO.ConventionOperAmount <> 0
                 AND @dtOperation BETWEEN AMT.dtStart AND ISNULL(AMT.dtEnd, @dtOperation)
                 AND @dtOperation BETWEEN AN.dtStart AND ISNULL(AN.dtEnd, @dtOperation)

         IF @@ERROR <> 0
            SET @iResult = -12
      END

      IF @iResult > 0
      BEGIN
         -- Un_PlanOper.PlanOperAmount
         INSERT INTO #tCHQ_OperationDetail
                    (iOperationID,
                     fAmount,
                     vcAccount,
                     vcDescription)
              SELECT
                     @iOperationID,
                     PO.PlanOperAmount,
                     AN.vcAccountNumber,
                     A.vcAccount
                FROM Un_PlanOper PO
                JOIN Un_Plan P ON P.PlanID = PO.PlanID
                JOIN Un_MoneyType MT ON MT.OperTypeID = @vcRefType
                 AND MT.vcTableName = 'Un_PlanOper' AND MT.vcFieldName = 'PlanOperAmount' AND MT.vcValueType = PO.PlanOperTypeID
                JOIN Un_AccountMoneyType AMT ON AMT.iMoneyTypeID = MT.iMoneyTypeID
                JOIN Un_Account A ON A.iAccountID = AMT.iAccountID AND A.iID_Regime = @iID_Regime
                JOIN Un_AccountNumber AN ON AN.iAccountID = A.iAccountID AND @dtCreated BETWEEN AN.dtStart AND ISNULL(AN.dtEnd,GETDATE())
               WHERE PO.OperID = @iOperID
                 AND PO.PlanOperAmount <> 0
                 AND @dtOperation BETWEEN AMT.dtStart AND ISNULL(AMT.dtEnd, @dtOperation)
                 AND @dtOperation BETWEEN AN.dtStart AND ISNULL(AN.dtEnd, @dtOperation)

         IF @@ERROR <> 0
            SET @iResult = -13
      END

      IF @iResult > 0
      BEGIN
         -- Un_CESP.fCESG
         INSERT INTO #tCHQ_OperationDetail
                    (iOperationID,
                     fAmount,
                     vcAccount,
                     vcDescription)
              SELECT
                     @iOperationID,
                     GG.fCESG,
                     AN.vcAccountNumber,
                     A.vcAccount
                FROM Un_CESP GG
                JOIN dbo.Un_Convention C ON C.ConventionID = GG.ConventionID
                JOIN Un_Plan P ON P.PlanID = C.PlanID
    JOIN Un_MoneyType MT ON MT.OperTypeID = @vcRefType
                 AND MT.vcTableName = 'Un_CESP' AND MT.vcFieldName = 'fCESG'
                JOIN Un_AccountMoneyType AMT ON AMT.iMoneyTypeID = MT.iMoneyTypeID
                JOIN Un_Account A ON A.iAccountID = AMT.iAccountID AND A.iID_Regime = @iID_Regime
                JOIN Un_AccountNumber AN ON AN.iAccountID = A.iAccountID AND @dtCreated BETWEEN AN.dtStart AND ISNULL(AN.dtEnd,GETDATE())
               WHERE GG.OperID = @iOperID
                 AND GG.fCESG <> 0
                 AND @dtOperation BETWEEN AMT.dtStart AND ISNULL(AMT.dtEnd, @dtOperation)
                 AND @dtOperation BETWEEN AN.dtStart AND ISNULL(AN.dtEnd, @dtOperation)

         IF @@ERROR <> 0
            SET @iResult = -14
      END

      IF @iResult > 0
      BEGIN
         -- Un_CESP.fACESG
         INSERT INTO #tCHQ_OperationDetail
                    (iOperationID,
                     fAmount,
                     vcAccount,
                     vcDescription)
              SELECT
                     @iOperationID,
                     GG.fACESG,
                     AN.vcAccountNumber,
                     A.vcAccount
                FROM Un_CESP GG
                JOIN dbo.Un_Convention C ON C.ConventionID = GG.ConventionID
                JOIN Un_Plan P ON P.PlanID = C.PlanID
                JOIN Un_MoneyType MT ON MT.OperTypeID = @vcRefType
                 AND MT.vcTableName = 'Un_CESP' AND MT.vcFieldName = 'fACESG'
                JOIN Un_AccountMoneyType AMT ON AMT.iMoneyTypeID = MT.iMoneyTypeID
                JOIN Un_Account A ON A.iAccountID = AMT.iAccountID AND A.iID_Regime = @iID_Regime
                JOIN Un_AccountNumber AN ON AN.iAccountID = A.iAccountID AND @dtCreated BETWEEN AN.dtStart AND ISNULL(AN.dtEnd,GETDATE())
               WHERE GG.OperID = @iOperID
                 AND GG.fACESG <> 0
                 AND @dtOperation BETWEEN AMT.dtStart AND ISNULL(AMT.dtEnd, @dtOperation)
                 AND @dtOperation BETWEEN AN.dtStart AND ISNULL(AN.dtEnd, @dtOperation)

         IF @@ERROR <> 0
            SET @iResult = -15
      END

      IF @iResult > 0
      BEGIN
         -- Un_CESP.fCLB
         INSERT INTO #tCHQ_OperationDetail
                    (iOperationID,
                     fAmount,
                     vcAccount,
                     vcDescription)
              SELECT
                     @iOperationID,
                     GG.fCLB,
                     AN.vcAccountNumber,
                     A.vcAccount
                FROM Un_CESP GG
                JOIN dbo.Un_Convention C ON C.ConventionID = GG.ConventionID
                JOIN Un_Plan P ON P.PlanID = C.PlanID
                JOIN Un_MoneyType MT ON MT.OperTypeID = @vcRefType
                 AND MT.vcTableName = 'Un_CESP' AND MT.vcFieldName = 'fCLB'
                JOIN Un_AccountMoneyType AMT ON AMT.iMoneyTypeID = MT.iMoneyTypeID
                JOIN Un_Account A ON A.iAccountID = AMT.iAccountID AND A.iID_Regime = @iID_Regime
                JOIN Un_AccountNumber AN ON AN.iAccountID = A.iAccountID AND @dtCreated BETWEEN AN.dtStart AND ISNULL(AN.dtEnd,GETDATE())
               WHERE GG.OperID = @iOperID
                 AND GG.fCLB <> 0
                 AND @dtOperation BETWEEN AMT.dtStart AND ISNULL(AMT.dtEnd, @dtOperation)
                 AND @dtOperation BETWEEN AN.dtStart AND ISNULL(AN.dtEnd, @dtOperation)

         IF @@ERROR <> 0
            SET @iResult = -16
      END

      IF @iResult > 0
      BEGIN
			 
         SELECT @vcDescriptionDtl = vcDescription
           FROM tblCONV_RegroupementsRegimes
          WHERE vcCode_Compte_Comptable_Fiducie = @vcBankAccount

         -- Banque = Sum de tous les autres * -1
         INSERT INTO #tCHQ_OperationDetail
                    (iOperationID,
                     fAmount,
                     vcAccount,
                     vcDescription)
             SELECT
               iOperationID,
                     -SUM(fAmount),
                     @vcBankAccount,
                     @vcDescriptionDtl
                FROM #tCHQ_OperationDetail
               WHERE @iOperationID = iOperationID
               GROUP BY iOperationID

         IF @@ERROR <> 0
            SET @iResult = -15
      END

      SET @vcTypePlanConv = 
         (SELECT DISTINCT
				P.PlanTypeID
            FROM Un_Plan P
            JOIN dbo.Un_Convention C ON C.PlanID = P.PlanID
            JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
            JOIN Un_IntReimb IR ON IR.UnitID = U.UnitID
            JOIN Un_IntReimbOper IRO ON IRO.IntReimbID = IR.IntReimbID
           WHERE IRO.OperID = @OperID)

      SET @vcTypeOper = (SELECT vcRefType FROM CHQ_Operation WHERE iOperationID = @iOperationID)

      IF (@vcTypeOper = 'RIN') AND (@vcTypePlanConv = 'IND')
      BEGIN
         DELETE
           FROM CHQ_CheckOperationDetail
          WHERE iOperationDetailID IN (SELECT iOperationDetailID
                                         FROM CHQ_OperationDetail
                                        WHERE iOperationID = @iOperationID)

         DELETE
           FROM CHQ_OperationDetail
          WHERE iOperationID = @iOperationID

         IF @@ERROR <> 0
            SET @iResult = -15

         -- Curseur d'insertion des détails d'opérations
         DECLARE crCHQ_OperationDetail CURSOR FOR
            SELECT vcAccount,
                   vcDescription,
                   fAmount = SUM(fAmount)
              FROM #tCHQ_OperationDetail
             GROUP BY iOperationID,
                      vcAccount,
                      vcDescription
      END
      ELSE
      BEGIN
         -- Curseur d'insertion des détails d'opérations
         DECLARE crCHQ_OperationDetail CURSOR FOR
            SELECT T.vcAccount,
                   T.vcDescription,
                   fAmount = T.fAmount - ISNULL(OD.fAmount,0)
              FROM (SELECT iOperationID, -- Nouvel opération
                           vcAccount,
                           vcDescription,
                           fAmount = SUM(fAmount)
                      FROM #tCHQ_OperationDetail
                     GROUP BY iOperationID,
                              vcAccount,
                              vcDescription
                   ) T
        LEFT JOIN (SELECT iOperationID,  -- Déjà existant
                          vcAccount,
                          vcDescription,
                          fAmount = SUM(fAmount)
                     FROM CHQ_OperationDetail
                    WHERE iOperationID = @iOperationID
                    GROUP BY iOperationID,
                             vcAccount,
                             vcDescription
                  ) OD ON OD.iOperationID = T.iOperationID AND OD.vcAccount = T.vcAccount AND OD.vcDescription = T.vcDescription -- Exclus les montants des détails déjà existants
             WHERE T.fAmount - ISNULL(OD.fAmount,0) <> 0
      END

      OPEN crCHQ_OperationDetail

      FETCH NEXT FROM crCHQ_OperationDetail INTO @vcAccount, @vcDescriptionDtl, @fAmount

      WHILE @@FETCH_STATUS = 0 AND @iResult > 0
      BEGIN
         -- Insertion du détail d'opération
         EXECUTE @iOperationDetailID = IU_CHQ_OperationDetail 0, -1, @iOperationID, @fAmount, @vcAccount, @vcDescriptionDtl

         IF @iOperationDetailID <= 0
            SET @iResult = -16

         FETCH NEXT FROM crCHQ_OperationDetail INTO @vcAccount, @vcDescriptionDtl, @fAmount
      END

      CLOSE crCHQ_OperationDetail
      DEALLOCATE crCHQ_OperationDetail

      DROP TABLE #tCHQ_OperationDetail
   END

   RETURN @iResult
END