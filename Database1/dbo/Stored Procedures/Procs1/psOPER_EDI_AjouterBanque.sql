/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : psOPER_EDI_AjouterBanque
Nom du service  : Ajouter une banque.
But             : Ajouter dans la table de référence de la base de données les 
                  données relatives à une banque non existante.
Facette         : OPER

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -----------------------------------
                      @vcDescription_Court       Description courte du nom de la banque

Paramètres de sortie: Paramètre   Champ(s)               Description
                      ----------- ---------------------- ---------------------------
                      S/O         iCode_Retour            0 = Traitement réussi
                                                         -1 = Banque déjà existante
                                                         -2 = Erreur de traitement

Exemple d’appel     : EXECUTE [dbo].[psOPER_EDI_AjouterBanque] 'BNC'

Historique des modifications:
        Date            Programmeur                         Description
        ------------    ---------------------------------- ---------------------------
        2010-01-25      Danielle Côté                       Création du service

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_EDI_AjouterBanque]
(
   @vcDescription_Court VARCHAR(35)
)
AS
BEGIN
   DECLARE
      @vcCode_Banque VARCHAR(3)

   -- Rendre conforme le contenu du paramètre
   SET @vcDescription_Court = LTRIM(LTRIM(@vcDescription_Court)) 

   IF @vcDescription_Court IS NULL OR @vcDescription_Court = '' OR
      EXISTS (SELECT 1
                FROM tblOPER_EDI_Banques
               WHERE UPPER(vcDescription_Court) = UPPER(@vcDescription_Court))
   BEGIN
      RETURN -1
   END
   ELSE
   BEGIN
      -------------------------------------------------------------------------
      -- Ajouter une nouvelle banque
      -------------------------------------------------------------------------
      SET XACT_ABORT ON
      BEGIN TRANSACTION
      BEGIN TRY 

         -- Construire le code de banque s'il n'est pas déjà utilisé
         IF NOT EXISTS (SELECT 1
                          FROM tblOPER_EDI_Banques
                         WHERE UPPER(vcCode_Banque) = 
                               UPPER(SUBSTRING(@vcDescription_Court,1,3)))
         BEGIN                        
            SET @vcCode_Banque = UPPER(SUBSTRING(@vcDescription_Court,1,3))
         END
         ELSE
         BEGIN
            SET @vcCode_Banque = '' 
         END

         -- Insertion dans la table de références avec mention "Insertion automatique"
         INSERT [dbo].[tblOPER_EDI_Banques] 
               ([vcCode_Banque]
               ,[vcDescription_Court]
               ,[vcDescription_Long])
        VALUES (@vcCode_Banque
               ,UPPER(@vcDescription_Court)
               ,'Insertion automatique') 

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
