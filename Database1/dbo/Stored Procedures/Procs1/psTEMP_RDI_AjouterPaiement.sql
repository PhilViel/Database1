/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : psTEMP_RDI_AjouterPaiement
Nom du service  : Ajouter temporairement un paiement.
But             : Ajouter dans la table temporaire des paiements les informations
                  nécessaires à l'assignement.
                  Cette procédure est nécessaire pour conserver temporairement
                  l'information d'un paiement lors de l'assignation, qui à partir
                  d'une page WEB (Paiements) doit continuer le traitement vers une 
                  page DELPHI. Comme il n'est pas possible de passer les valeurs en 
                  paramètres pour des raisons techniques (WEB à DELPHI), les éléments 
                  nécessaires au traitement sont mis dans une table pour ensuite être
                  récupérés par DELPHI.
                  La procédure pourra être détruite lorsque la fenêtre des encaissements
                  sera convertie en WEB.
Facette         : TEMP

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -----------------------------------
                      @iID_RDI_Paiement          Identifiant unique d'un paiement
                      @iID_Utilisateur           ID de l'utilisateur

Paramètres de sortie: Paramètre   Champ(s)               Description
                      ----------- ---------------------- ---------------------------
                      S/O         iCode_Retour            0 = Traitement réussi
                                                         -1 = Aucun ajout
                                                         -2 = Erreur de traitement

Exemple d’appel     : EXECUTE [dbo].[psTEMP_RDI_AjouterPaiement] 123, 575752

Historique des modifications:
        Date            Programmeur                        Description
        ------------    ---------------------------------- ---------------------------
        2010-03-02      Danielle Côté                      Création du service

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psTEMP_RDI_AjouterPaiement]
(
   @iID_RDI_Paiement INT
  ,@iID_Utilisateur  INT
)
AS
BEGIN

   -- Un seul paiement à la fois est permis par utilisateur.
   DELETE
     FROM tblTEMP_RDI_Paiements 
    WHERE iID_Utilisateur = @iID_Utilisateur

   IF @iID_RDI_Paiement IS NULL OR @iID_RDI_Paiement = 0
   BEGIN
      RETURN -1
   END
   ELSE
   BEGIN   

      SET XACT_ABORT ON
      BEGIN TRANSACTION
      BEGIN TRY

         INSERT [dbo].[tblTEMP_RDI_Paiements]
               ([iID_RDI_Paiement]
               ,[iID_RDI_Depot]
               ,[mMontantAjout]
               ,[vcNo_Document]
               ,[iID_Utilisateur])
         SELECT @iID_RDI_Paiement
               ,iID_RDI_Depot
               ,(mMontant_Paiement_Final - 
                ([dbo].[fnOPER_RDI_CalculerMontantAssignePaiement](iID_RDI_Paiement,NULL)))
               ,vcNo_Document
               ,@iID_Utilisateur
           FROM tblOPER_RDI_Paiements
          WHERE iID_RDI_Paiement = @iID_RDI_Paiement

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
