/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : psOPER_EDI_ModifierStatutFichier
Nom du service  : Modifier le statut du fichier.
But             : Modifier le statut du fichier selon les étapes de traitement 
                  automatique ou via l'interface utilisateur.
Facette         : OPER

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -----------------------------------
                      @vcCode_Statut             Code unique du statut du fichier
                      @vcNom_Fichier             Nom du fichier à mettre à jour

Paramètres de sortie: Paramètre   Champ(s)               Description
                      ----------- ---------------------- ---------------------------
                      S/O         iCode_Retour            0 = Traitement réussi
                                                         -1 = Le statut n'existe pas
                                                         -2 = Erreur de traitement

Exemple d’appel     : EXECUTE [dbo].[psOPER_EDI_ModifierStatutFichier] 'IMP','20100122.txt'

Historique des modifications:
        Date            Programmeur                         Description
        ------------    ---------------------------------- ---------------------------
        2010-01-26      Danielle Côté                       Création du service

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_EDI_ModifierStatutFichier]
(
   @vcCode_Statut  VARCHAR(35)
  ,@vcNom_Fichier VARCHAR(50)
)
AS
BEGIN
   DECLARE
      @tiID_EDI_Statut_Fichier TINYINT 

   -- Rendre conforme le contenu du paramètre
   SET @vcCode_Statut = LTRIM(LTRIM(@vcCode_Statut)) 
   SET @vcNom_Fichier = LTRIM(LTRIM(@vcNom_Fichier))

   IF NOT EXISTS (SELECT 1
                    FROM tblOPER_EDI_StatutsFichier
                   WHERE UPPER(vcCode_Statut) = UPPER(@vcCode_Statut))
   BEGIN
      RETURN -1
   END
   ELSE
   BEGIN
      -------------------------------------------------------------------------
      -- Mettre à jour le statut du fichier
      -------------------------------------------------------------------------
      SET XACT_ABORT ON
      BEGIN TRANSACTION
      BEGIN TRY

         -- Récupérer le ID du statut du fichier   
         SELECT @tiID_EDI_Statut_Fichier = tiID_EDI_Statut_Fichier
           FROM tblOPER_EDI_StatutsFichier
          WHERE UPPER(LTRIM(LTRIM(vcCode_Statut))) = @vcCode_Statut

         -- Mettre à jour le fichier
         UPDATE tblOPER_EDI_Fichiers
            SET tiID_EDI_Statut_Fichier = @tiID_EDI_Statut_Fichier
          WHERE UPPER(vcNom_Fichier) = UPPER(@vcNom_Fichier)
            AND tiID_EDI_Statut_Fichier NOT IN
               (SELECT tiID_EDI_Statut_Fichier
                  FROM tblOPER_EDI_StatutsFichier
                 WHERE vcCode_Statut = 'ERR')

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
