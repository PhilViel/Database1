/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : psGENE_EnregistrerErreur_Indetectable
Nom du service  : Enregistrer une Erreur indétectable
But             : Enregistrer les données d'une erreur indétectable
Facette         : GENE

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -----------------------------------
                      S/O

Paramètres de sortie: Table                 Champ(s)               Description
                      -----------           ---------------------- -----------------
                      S/O

Exemple d'appel: EXECUTE dbo.psGENE_EnregistrerErreur_Indetectable

Historique des modifications:
Date           Programmeur                   Description
------------   ----------------------------- ---------------------------
2010-10-01     Danielle Côté                 Création du service
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_EnregistrerErreur_Indetectable] 
AS
BEGIN
   SET NOCOUNT ON
   
   SET XACT_ABORT ON
   BEGIN TRANSACTION
   BEGIN TRY   

      INSERT INTO tblGENE_Erreurs
            (iLigne_Erreur
            ,vcMessage_Erreur 
            ,iNumero_Erreur
            ,vcNom_Objet
            ,iSeverite_Erreur
            ,iEtat_Erreur
            ,vcNom_BaseDeDonnee)
      VALUES 
            (ERROR_LINE()
            ,ERROR_MESSAGE()
            ,ERROR_NUMBER()
            ,ERROR_PROCEDURE()
            ,ERROR_SEVERITY()
            ,ERROR_STATE()
            ,DB_NAME())

      COMMIT TRANSACTION
   END TRY
   BEGIN CATCH

      DECLARE
         @ErrorMessage NVARCHAR(4000)
        ,@ErrorSeverity INT
        ,@ErrorState INT

      SET @ErrorMessage  = ERROR_MESSAGE()
      SET @ErrorSeverity = ERROR_SEVERITY()
      SET @ErrorState    = ERROR_STATE()

      IF (XACT_STATE()) = -1 AND @@TRANCOUNT > 0
         ROLLBACK TRANSACTION
      RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState) WITH LOG

   END CATCH
END   
