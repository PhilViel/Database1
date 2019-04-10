/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : psGENE_EnregistrerErreur_Detectable
Nom du service  : Enregistrer une Erreur détectable
But             : Enregistrer les données d'une erreur détectable
Facette         : GENE

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -----------------------------------
                      @vcMessage_Erreur          Texte du message d'erreur
                      @iResultat                 Résultat retourné par l'objet en erreur
                      @vcNom_Objet               Nom de l'objet en erreur
                      @vcNom_BaseDeDonnee        Nom de la base de données

Paramètres de sortie: Table                 Champ(s)               Description
                      -----------           ---------------------- -----------------
                      S/O

Exemple d'appel: EXECUTE dbo.psGENE_EnregistrerErreur_Detectable 'Les paramètres d'entrés sont nuls',-1,'psOPPO_EnregistrerHumain','OPPO'

Historique des modifications:
Date           Programmeur                   Description
------------   ----------------------------- ---------------------------
2010-10-01     Danielle Côté                 Création du service
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_EnregistrerErreur_Detectable]
(
   @vcMessage_Erreur   NVARCHAR(4000)
  ,@iResultat          INT
  ,@vcNom_Objet    NVARCHAR(126)
  ,@vcNom_BaseDeDonnee NVARCHAR(255)
) 
AS
BEGIN
   SET NOCOUNT ON
   
   SET XACT_ABORT ON
   BEGIN TRANSACTION
   BEGIN TRY   

      INSERT INTO tblGENE_Erreurs
            (vcMessage_Erreur 
            ,iNumero_Erreur
            ,vcNom_Objet
            ,vcNom_BaseDeDonnee)
      VALUES 
            (@vcMessage_Erreur
            ,@iResultat
            ,@vcNom_Objet
            ,@vcNom_BaseDeDonnee)

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
