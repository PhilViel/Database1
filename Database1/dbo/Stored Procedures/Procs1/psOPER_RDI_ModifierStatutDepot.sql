/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : psOPER_RDI_ModifierStatutDepot
Nom du service  : Modifier le statut du dépôt.
But             : Modifier le statut du dépôt suite aux opérations d'assignement
                  (Encaissement, correction et annulation).
Facette         : OPER

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -------------------------------------
                      @iID_RDI_Depot             Identifiant unique d'un dépôt.

Paramètres de sortie: Paramètre   Champ(s)               Description
                      ----------- ---------------------- -----------------------------
                      S/O         iCode_Retour            0 = Traitement réussi
                                                         -1 = Le dépôt n'existe pas
                                                         -2 = Erreur de traitement

Exemple d’appel     : EXECUTE [dbo].[psOPER_RDI_ModifierStatutDepot] 12

Historique des modifications:
        Date            Programmeur                         Description
        ------------    ---------------------------------- ---------------------------
        2010-02-25      Danielle Côté                       Création du service

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_RDI_ModifierStatutDepot]
(
   @iID_RDI_Depot INT
)
AS
BEGIN
   DECLARE
      @tiID_RDI_Statut_Depot TINYINT

   -------------------------------------------------------------------------
   -- Simuler le statut du dépôt en comparant le montant assigné et le 
   -- montant du dépôt
   -------------------------------------------------------------------------
   SET @tiID_RDI_Statut_Depot = [dbo].[fnOPER_RDI_SimulerStatutDepot](@iID_RDI_Depot)

   IF NOT EXISTS (SELECT 1
                    FROM tblOPER_RDI_Depots
                   WHERE iID_RDI_Depot =  @iID_RDI_Depot)
   BEGIN
      RETURN -1
   END
   ELSE
   BEGIN
      -------------------------------------------------------------------------
      -- Mettre à jour le statut du dépôt
      -------------------------------------------------------------------------
      SET XACT_ABORT ON
      BEGIN TRANSACTION
      BEGIN TRY

         UPDATE tblOPER_RDI_Depots
            SET tiID_RDI_Statut_Depot = @tiID_RDI_Statut_Depot
          WHERE iID_RDI_Depot = @iID_RDI_Depot

         COMMIT TRANSACTION
         RETURN 0

      END TRY
      BEGIN CATCH

         DECLARE
            @ErrorMessage NVARCHAR(4000)
           ,@ErrorSeverity INT
           ,@ErrorState INT

         SET @ErrorMessage = ERROR_MESSAGE()
         SET @ErrorSeverity = ERROR_SEVERITY()
         SET @ErrorState = ERROR_STATE()

         IF (XACT_STATE()) = -1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION
         RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState) WITH LOG;
         RETURN -2
      END CATCH
   END
END 
