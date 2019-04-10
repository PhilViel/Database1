/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : psOPER_RDI_AjouterOperation
Nom du service  : Ajouter ou modifier une opération RDI.
But             : Sauvegarde l'information suite à l'ajout ou la modification d'une
                  opération RDI. Ce service est dérivé de IU_UN_OperCHQ.
Facette         : OPER

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -------------------------------------
                      ConnectID                  Numéro de la connexion
                      iBlobID                    Identifiant unique du blob
                      iID_RDI_Paiement           Identifiant unique d'un paiement

Paramètres de sortie: 
Paramètre Champ(s)         Description
--------- --------------   -------------------------------------
S/O       iCode_Retour     >  0 = Réussite
                           <= 0 = Erreurs
                           -3  Le montant disponible est insuffisant
                           -4  Erreur dans l'insertion de l'ajout d'une opération
                           -5  Erreur dans la mise à jour de la modification d'une opération
                           -6  Erreur dans la suppression des cotisations
                           -7  Erreur dans la suppression des opérations sur conventions
                           -8  Erreur dans la mise à jour des cotisations
                           -9  Erreur dans la mise à jour des opérations sur conventions
                           -10 Erreur dans l'insertion d'une cotisation
                           -11 Erreur dans l'insertion d'une opération sur convention
                           -12 Erreur dans la suppression Un_CESP400 

Exemple d’appel     : EXECUTE [dbo].[psOPER_RDI_AjouterOperation] 1, 1, 217

Historique des modifications:
               Date          Programmeur        Description
               ------------  ------------------ --------------------------------------
               2010-03-11    Danielle Côté      Création
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_RDI_AjouterOperation]
(
    @ConnectID        INT
   ,@iBlobID          INT
   ,@iID_RDI_Paiement INT
)
AS
BEGIN
   DECLARE
      @iCodeRetour      INT
     ,@OperID           INT
     ,@CotisationID     INT
     ,@bConventionOper  BIT
     ,@mMontantOper     MONEY

     ,@iID_UnOperRDI           INT
     ,@mMontantDisponibleAjout MONEY
     ,@mMontantDisponibleModif MONEY
     ,@iID_RDI_Depot           INT

   -- Valider le blob
   EXECUTE @iCodeRetour = VL_UN_BlobFormatOfOper @iBlobID

   IF @iCodeRetour > 0
   BEGIN
      -------------------------------------------------------------------------
      -- IMPORTER la partie du blob qui contient l'opération
      -------------------------------------------------------------------------
      DECLARE @OperTable 
        TABLE (LigneTrans INTEGER
              ,OperID     INTEGER
              ,NewOperID  INTEGER
              ,ConnectID  INTEGER
              ,OperTypeID CHAR(3)
              ,OperDate   DATETIME
              ,IsDelete   BIT)

      INSERT INTO @OperTable
      SELECT LigneTrans
            ,OperID
            ,OperID
            ,ConnectID
            ,OperTypeID
            ,OperDate
            ,IsDelete = 0
        FROM dbo.FN_UN_OperOfBlob(@iBlobID)
       WHERE OperTypeID = 'RDI'

      -------------------------------------------------------------------------
      -- IMPORTER la partie du blob qui contient les cotisations
      -------------------------------------------------------------------------
      DECLARE @CotisationTable
        TABLE (LigneTrans    INTEGER
              ,CotisationID  INTEGER
              ,OperID        INTEGER
              ,UnitID        INTEGER
              ,EffectDate    DATETIME
              ,Cotisation    MONEY
              ,Fee           MONEY
              ,BenefInsur    MONEY
              ,SubscInsur    MONEY
              ,TaxOnInsur    MONEY
              ,bReSendToCESP BIT)

      INSERT INTO @CotisationTable
      SELECT V.LigneTrans
            ,V.CotisationID
            ,V.OperID
            ,V.UnitID
            ,V.EffectDate
            ,V.Cotisation
            ,V.Fee
            ,V.BenefInsur
            ,V.SubscInsur
            ,V.TaxOnInsur
            ,CAST (CASE
                      WHEN Ct.CotisationID IS NULL
                        OR Ct.Cotisation + Ct.Fee = V.Cotisation + V.Fee THEN 0
                      ELSE 1
                   END AS BIT)
        FROM dbo.FN_UN_CotisationOfBlob(@iBlobID) V
        LEFT JOIN Un_Cotisation Ct ON Ct.CotisationID = V.CotisationID

      -------------------------------------------------------------------------
      -- IMPORTER la partie du blob qui contient les 
      -- opérations sur conventions et les subventions
      -------------------------------------------------------------------------
      DECLARE @ConventionOperTable
        TABLE (LigneTrans           INTEGER
              ,ConventionOperID     INTEGER
              ,OperID               INTEGER
              ,ConventionID         INTEGER
              ,ConventionOperTypeID VARCHAR(3)
              ,ConventionOperAmount MONEY)

      INSERT INTO @ConventionOperTable
      SELECT *
        FROM dbo.FN_UN_ConventionOperOfBlob(@iBlobID)

      IF EXISTS (SELECT * FROM @ConventionOperTable)
         SET @bConventionOper = 1
      ELSE
         SET @bConventionOper = 0

      -------------------------------------------------------------------------
      -- Calculer le montant de l'opération RDI demandée
      -------------------------------------------------------------------------
      SELECT @mMontantOper =
            (SUM(Ct.Cotisation) +
             SUM(Ct.Fee) +
             SUM(Ct.BenefInsur) +
             SUM(Ct.SubscInsur) +
             SUM(Ct.TaxOnInsur))
       FROM @CotisationTable Ct 

      -------------------------------------------------------------------------
      -- Établir le montant RDI disponible pour un ajout
      -------------------------------------------------------------------------
      SELECT @mMontantDisponibleAjout = 
             P.mMontant_Paiement_Final - 
            ([dbo].[fnOPER_RDI_CalculerMontantAssignePaiement](@iID_RDI_Paiement,NULL))
        FROM tblOPER_RDI_Paiements P
       WHERE P.iID_RDI_Paiement = @iID_RDI_Paiement

      -------------------------------------------------------------------------
      -- Établir le montant RDI disponible pour une modification
      -------------------------------------------------------------------------
      SET @mMontantDisponibleModif = @mMontantDisponibleAjout + @mMontantOper

      -------------------------------------------------------------------------
      BEGIN TRANSACTION
      -------------------------------------------------------------------------

      -------------------------------------------------------------------------
      -- Il s'agit d'une nouvelle opération (OperID <=0)
      -------------------------------------------------------------------------
      IF EXISTS (SELECT OperID
                   FROM @OperTable
                  WHERE OperID <= 0)
      BEGIN
         -- Vérifier si le montant disponible est suffisant
         IF @mMontantOper > @mMontantDisponibleAjout
         BEGIN
            SET @iCodeRetour = -3
         END
         ELSE
         BEGIN
            DECLARE Cur_UnOper CURSOR FOR
               SELECT OperID
                 FROM @OperTable
                WHERE OperID <= 0

            OPEN Cur_UnOper
            FETCH NEXT FROM Cur_UnOper INTO @OperID

            WHILE @@FETCH_STATUS = 0
            BEGIN
               INSERT INTO Un_Oper
                          (ConnectID
                          ,OperTypeID
                          ,OperDate)
                    SELECT ConnectID
                          ,OperTypeID
                          ,OperDate
                      FROM @OperTable
                     WHERE OperID = @OperID

               -- Récupérer l'identifiant unique de l'opération AJOUT
               IF @@ERROR = 0
               BEGIN
                  SET @iID_UnOperRDI = SCOPE_IDENTITY()

                  UPDATE @OperTable
                     SET NewOperID = @iID_UnOperRDI
                   WHERE OperID = @OperID
               END

               INSERT INTO tblOPER_RDI_Liens
                          (iID_RDI_Paiement
                          ,OperID)
                    VALUES (@iID_RDI_Paiement, @iID_UnOperRDI)

               IF @@ERROR <> 0
                  SET @iCodeRetour = -4

               FETCH NEXT FROM Cur_UnOper INTO @OperID
            END
            CLOSE Cur_UnOper
            DEALLOCATE Cur_UnOper
         END
                 
      END
      ------------------------------------------------------------------------
      -- Il s'agit d'une opération existante (OperID >0)
      ------------------------------------------------------------------------
      ELSE IF EXISTS (SELECT OperID
                        FROM @OperTable
                       WHERE OperID > 0)
      BEGIN
         -- Vérifier si le montant disponible est suffisant
         IF @mMontantOper > @mMontantDisponibleModif
         BEGIN
            SET @iCodeRetour = -3
         END
         ELSE
         BEGIN  
            -- Récupérer l'identifiant unique de l'opération MODIF
            SELECT @iID_UnOperRDI = OperID
              FROM @OperTable

            UPDATE Un_Oper 
               SET OperTypeID = O.OperTypeID
                  ,OperDate = O.OperDate
              FROM Un_Oper
              JOIN @OperTable O ON O.OperID = Un_Oper.OperID
              
            -- Récupérer le id du paiement en lien avec l'opération
            SELECT @iID_RDI_Paiement = iID_RDI_Paiement
              FROM tblOPER_RDI_Liens
             WHERE OperID = @iID_UnOperRDI

            IF @@ERROR <> 0
               SET @iCodeRetour = -5
         END
      END

      -------------------------------------------------------------------------
      -- Supprimer et/ou mettre à jour les enregistrements  
      -------------------------------------------------------------------------
      IF @iID_UnOperRDI > 0 AND @iCodeRetour > 0
      BEGIN
         -- 400 non-expédiés
         DELETE Un_CESP400
           FROM Un_CESP400
           JOIN Un_Cotisation Ct ON Un_CESP400.CotisationID = Ct.CotisationID
           JOIN @OperTable O ON O.NewOperID = Ct.OperID
          WHERE Un_CESP400.iCESPSendFileID IS NULL

         IF @@ERROR <> 0
            SET @iCodeRetour = -12

         -- Cotisations
         DELETE Un_Cotisation
           FROM Un_Cotisation
           JOIN @OperTable O ON O.OperID = Un_Cotisation.OperID
           LEFT JOIN @CotisationTable C ON C.CotisationID = Un_Cotisation.CotisationID
          WHERE C.CotisationID IS NULL

         IF @@ERROR <> 0 
            SET @iCodeRetour = -6

         -- Opérations sur conventions
         DELETE Un_ConventionOper
           FROM Un_ConventionOper
           JOIN @OperTable O ON O.OperID = Un_ConventionOper.OperID
      LEFT JOIN @ConventionOperTable C ON C.ConventionOperID = Un_ConventionOper.ConventionOperID
          WHERE C.ConventionOperID IS NULL

         IF @@ERROR <> 0 
            SET @iCodeRetour = -7

         -- Cotisations
         UPDATE Un_Cotisation 
            SET UnitID = C.UnitID
               ,EffectDate = C.EffectDate
               ,Cotisation = C.Cotisation
               ,Fee = C.Fee
               ,BenefInsur = C.BenefInsur
               ,SubscInsur = C.SubscInsur
               ,TaxOnInsur = C.TaxOnInsur
           FROM Un_Cotisation
           JOIN @CotisationTable C ON C.CotisationID = Un_Cotisation.CotisationID

         IF @@ERROR <> 0 
            SET @iCodeRetour = -8 

         -- Opérations sur conventions
         UPDATE Un_ConventionOper 
            SET ConventionID = C.ConventionID
               ,ConventionOperTypeID = C.ConventionOperTypeID
               ,ConventionOperAmount = C.ConventionOperAmount
           FROM Un_ConventionOper
           JOIN @ConventionOperTable C ON C.ConventionOperID = Un_ConventionOper.ConventionOperID 
            AND C.ConventionOperTypeID NOT IN ('SUB','SU+','BEC')

         IF @@ERROR <> 0 
            SET @iCodeRetour = -9
         
      END

      -------------------------------------------------------------------------
      -- Insèrer les nouvelles transactions de cotisations
      -------------------------------------------------------------------------
      IF @iID_UnOperRDI > 0 AND @iCodeRetour > 0
      BEGIN
         INSERT INTO Un_Cotisation
                    (UnitID
                    ,OperID
                    ,EffectDate
                    ,Cotisation
                    ,Fee
                    ,BenefInsur
                    ,SubscInsur
                    ,TaxOnInsur)
             SELECT Ct.UnitID
                    ,O.NewOperID
                    ,Ct.EffectDate
                    ,Ct.Cotisation
                    ,Ct.Fee
                    ,Ct.BenefInsur
                    ,Ct.SubscInsur
                    ,Ct.TaxOnInsur
               FROM @CotisationTable Ct
               JOIN @OperTable O ON O.OperID = Ct.OperID
              WHERE Ct.CotisationID <= 0

         IF @@ERROR <> 0
            SET @iCodeRetour = -10
      END

      -------------------------------------------------------------------------
      -- Insèrer les nouvelles transactions d'opération sur convention
      -------------------------------------------------------------------------
      IF @iID_UnOperRDI > 0 AND @iCodeRetour > 0 AND @bConventionOper = 1
      BEGIN
         INSERT INTO Un_ConventionOper
                    (ConventionID
                    ,OperID
                    ,ConventionOperTypeID
                    ,ConventionOperAmount)
              SELECT CO.ConventionID
                    ,O.NewOperID
                    ,CO.ConventionOperTypeID
                    ,CO.ConventionOperAmount
                FROM @ConventionOperTable CO
                JOIN @OperTable O ON O.OperID = CO.OperID
               WHERE CO.ConventionOperID <= 0 
                 AND CO.ConventionOperTypeID NOT IN ('SUB','SU+','BEC')

         IF @@ERROR <> 0 
            SET @iCodeRetour = -11
      END

      -------------------------------------------------------------------------
      -- Renverser les enregistrements 400 déjà expédiés qui ont été modifié
      -------------------------------------------------------------------------      
      IF @iID_UnOperRDI > 0 AND @iCodeRetour > 0
      BEGIN
         -- Renverser les enregistrements 400 des cotisations dont la somme des frais et des épargnes a changé
         DECLARE crCHQ_Reverse400 CURSOR FOR
            SELECT CotisationID
              FROM @CotisationTable
             WHERE bReSendToCESP = 1

         OPEN crCHQ_Reverse400
         FETCH NEXT FROM crCHQ_Reverse400 INTO @CotisationID

         WHILE @@FETCH_STATUS = 0
         BEGIN
            -- Appeller la procédure de renversement pour la cotisation
            EXECUTE @iID_UnOperRDI = IU_UN_ReverseCESP400 @ConnectID, @CotisationID, 0
            FETCH NEXT FROM crCHQ_Reverse400 INTO @CotisationID
         END

         CLOSE crCHQ_Reverse400
         DEALLOCATE crCHQ_Reverse400
      END

      -- Insère les enregistrements 400 de type 11 sur l'opération
      EXECUTE @iCodeRetour = IU_UN_CESP400ForOper @ConnectID, @iID_UnOperRDI, 11, 0

      IF @iCodeRetour <= 0
      BEGIN
         ROLLBACK TRANSACTION
      END
      ELSE
      BEGIN
         COMMIT TRANSACTION
         -- Retourne le ID en mode DEBUG lors d'un succès
         SET @iCodeRetour = @iID_UnOperRDI

     END
   END
   
   -------------------------------------------------------------------------
   -- Mettre à jour le statut du dépôt suite à l'opération
   -------------------------------------------------------------------------
   SELECT @iID_RDI_Depot = iID_RDI_Depot
     FROM tblOPER_RDI_Paiements 
    WHERE iID_RDI_Paiement = @iID_RDI_Paiement

   IF @iID_RDI_Depot > 0
      EXECUTE [dbo].[psOPER_RDI_ModifierStatutDepot] @iID_RDI_Depot  

   -------------------------------------------------------------------------
   -- Supprime le blob des objets
   -------------------------------------------------------------------------
   IF @iCodeRetour <> -1
   BEGIN
      DELETE 
        FROM CRI_Blob
       WHERE iBlobID = @iBlobID
          OR dtBlob <= DATEADD(DAY,-2,GETDATE())

      IF @@ERROR <> 0
         SET @iCodeRetour = -16
   END

   RETURN @iCodeRetour

END
