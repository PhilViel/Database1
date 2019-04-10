/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : psOPER_EDI_ImporterRDI
Nom du service  : Regrouper les importations RDI.
But             : Regroupe l'importation des fichiers, dépôts et paiements pour
                  le traitement des EDI-RDI.
Facette         : OPER

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -----------------------------------
                      @vcTypeFichier             Code unique permettant de définir le
                                                 type de fichier EDI traité
                      @iID_Utilisateur           ID de l'utilisateur

Paramètres de sortie: Paramètre Champ(s)
                      --------- --------------
                      S/O       iCode_Retour

                      Description
                      --------------------------------------------------------------
                      0 = Le fichier de dépôts de ce jour a été importé avec succès dans UniAccès.
                      1 = Le fichier de dépôts d'aujourd'hui a déjà été importé dans UniAccès.
                      2 = Une erreur est survenue dans l’importation du fichier.
                      3 = Il n'y a pas de fichier en date du jour.  Veuillez vérifier l'importation de Liaison Clients.
                      4 = Les dépôts n’ont pas été importés.
                      5 = Une erreur est survenue dans l’importation de(s) dépôt(s).
                      6 = Les paiements n’ont pas été importés.
                      7 = Une erreur est survenue dans l’importation de(s) paiement(s).

Exemple d’appel     : EXECUTE [dbo].[psOPER_EDI_ImporterRDI] 'RDI', 575752

Historique des modifications:
        Date            Programmeur                         Description
        ------------    ---------------------------------- ---------------------------
        2010-01-29      Danielle Côté                       Création du service

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_EDI_ImporterRDI]
(
   @vcTypeFichier   VARCHAR(3)
  ,@iID_Utilisateur INT
)
AS
BEGIN
   -- Variables de travail
   DECLARE
      @tiCode_Retour_Fichier  INT
     ,@tiCode_Retour_Depot    INT
     ,@tiCode_Retour_Paiement INT
     ,@tiCode_Retour_Erreur   INT
     ,@vcNom_Fichier          VARCHAR(50)
  
   -- Pour le courriel de confirmation  
   DECLARE
      @vcContenuMessageCourriel VARCHAR(250)
     ,@vcSujetCourriel          VARCHAR(100)
     ,@vcNom_Utilisateur        VARCHAR(100)
     ,@vcMessage                VARCHAR(500)
     ,@vcMessageSupport         VARCHAR(100)
     ,@vcIntro                  VARCHAR(100)
     ,@vcHTMLbr                 VARCHAR(10)
     ,@vcDestinataire_Courriel  VARCHAR(100)
     ,@vcDestinataire_Copie     VARCHAR(100) 
     ,@vcDestinataire_Cache     VARCHAR(100)     
     
   SET XACT_ABORT ON
   BEGIN TRANSACTION
   BEGIN TRY  

      -------------------------------------------------------------------------
      -- IMPORTER LES FICHIERS
      -------------------------------------------------------------------------
      EXECUTE @tiCode_Retour_Fichier = [dbo].[psOPER_EDI_ImporterFichiers] @vcTypeFichier, @iID_Utilisateur
      SET @tiCode_Retour_Erreur =
         CASE 
            WHEN @tiCode_Retour_Fichier =  0 THEN 0 -- OPERM0004
            WHEN @tiCode_Retour_Fichier = -1 THEN 1 -- OPERE0008
            WHEN @tiCode_Retour_Fichier = -2 THEN 2 -- OPERE0009
            WHEN @tiCode_Retour_Fichier = -3 THEN 3 -- OPERE0010
         END

      -------------------------------------------------------------------------
      -- IMPORTER LES DÉPÔTS
      -- L'importation des fichiers est réussi
      -------------------------------------------------------------------------
      IF @tiCode_Retour_Erreur = 0
      BEGIN
         EXECUTE @tiCode_Retour_Depot = [dbo].[psOPER_RDI_ImporterDepots]
         SET @tiCode_Retour_Erreur =
         CASE
            WHEN @tiCode_Retour_Depot =  0 THEN 0 -- OPERM0004
            WHEN @tiCode_Retour_Depot = -1 THEN 4 -- OPERE0011
            WHEN @tiCode_Retour_Depot = -2 THEN 5 -- OPERE0012
         END
      END

      -------------------------------------------------------------------------
      -- IMPORTER LES PAIEMENTS
      -- L'importation des fichiers est réussi
      -- L'importation des dépôts est réussi
      -------------------------------------------------------------------------
      IF @tiCode_Retour_Erreur = 0
      BEGIN
         EXECUTE @tiCode_Retour_Paiement = [dbo].[psOPER_RDI_ImporterPaiements]
         SET @tiCode_Retour_Erreur =
         CASE 
            WHEN @tiCode_Retour_Paiement =  0 THEN 0 -- OPERM0004
            WHEN @tiCode_Retour_Paiement = -1 THEN 6 -- OPERE0013
            WHEN @tiCode_Retour_Paiement = -2 THEN 7 -- OPERE0014
         END
      END

      -------------------------------------------------------------------------
      -- COMMIT de toutes les procédures
      -------------------------------------------------------------------------      
      COMMIT TRANSACTION

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

   END CATCH   

   ----------------------------------------------------------------------------
   -- Construction du message du courriel
   ----------------------------------------------------------------------------
   SET @vcNom_Fichier = [dbo].[fnOPER_RDI_GenererNomFichier]()
   
   SET @vcMessage =
   CASE
      WHEN @tiCode_Retour_Erreur = 0 THEN 'RDI - Le fichier de dépôts de ce jour a été importé avec succès dans UniAccès.'
      WHEN @tiCode_Retour_Erreur = 1 THEN 'Le fichier de dépôts d''aujourd''hui a déjà été importé dans UniAccès.'
      WHEN @tiCode_Retour_Erreur = 2 THEN 'Une erreur est survenue dans l''importation du fichier.'
      WHEN @tiCode_Retour_Erreur = 3 THEN 'Il n''y a pas de fichier en date du jour.  Veuillez vérifier l''importation de Liaison Clients.'
      WHEN @tiCode_Retour_Erreur = 4 THEN 'Les dépôts n''ont pas été importés.'
      WHEN @tiCode_Retour_Erreur = 5 THEN 'RDI - Les dépôts de ce fichier n''ont pas été importés.'
      WHEN @tiCode_Retour_Erreur = 6 THEN 'Les paiements n''ont pas été importés.'
      WHEN @tiCode_Retour_Erreur = 7 THEN 'RDI - Les paiements de ce fichier n''ont pas été importés.'
      ELSE ''
   END
   
   SET @vcMessageSupport  = 'Veuillez contacter le support informatique.'
   SET @vcHTMLbr = '<br />'
   SET @vcIntro = 'Ceci est un message automatique provenant de la demande d''importation d''un fichier RDI '
   
   SELECT @vcNom_Utilisateur = H.FirstName + ' ' + H.LastName
     FROM Mo_User U
     JOIN dbo.Mo_Human H ON H.HumanID = U.UserID
      AND U.UserId = @iID_Utilisateur
   
   -- Établir le message du courriel  
   SET @vcContenuMessageCourriel =
   CASE
      WHEN @tiCode_Retour_Erreur = 2 THEN @vcIntro + @vcHTMLbr + @vcMessage + @vcHTMLbr + @vcMessageSupport
      WHEN @tiCode_Retour_Erreur = 4 THEN @vcIntro + @vcHTMLbr + @vcMessage + @vcHTMLbr + @vcMessageSupport
      WHEN @tiCode_Retour_Erreur = 5 THEN @vcIntro + @vcHTMLbr + @vcMessage + @vcHTMLbr + @vcMessageSupport
      WHEN @tiCode_Retour_Erreur = 6 THEN @vcIntro + @vcHTMLbr + @vcMessage + @vcHTMLbr + @vcMessageSupport
      WHEN @tiCode_Retour_Erreur = 7 THEN @vcIntro + @vcHTMLbr + @vcMessage + @vcHTMLbr + @vcMessageSupport
      ELSE @vcIntro + @vcHTMLbr + @vcMessage
   END      
      
   -- Établir le sujet du courriel selon qu'il s'agisse d'un succès ou d'une erreur
   IF @tiCode_Retour_Erreur = 0
      SET @vcSujetCourriel = 'Importation du fichier RDI ' + @vcNom_Fichier + ' réussie. ' +
                             'Demandée par : ' + @vcNom_Utilisateur
   ELSE
      SET @vcSujetCourriel = 'Importation du fichier RDI. Une erreur est survenue. ' +
                             'Demandée par : ' + @vcNom_Utilisateur     

   -- Conserver une trace du résultat de l'importation si succès ou erreur
   UPDATE tblOPER_EDI_Fichiers
      SET tCommentaires = @vcMessage + ' ' + CAST(getDate() as VARCHAR)
    WHERE UPPER(vcNom_Fichier) = UPPER(@vcNom_Fichier)
      AND tiID_EDI_Statut_Fichier NOT IN
         (SELECT tiID_EDI_Statut_Fichier
            FROM tblOPER_EDI_StatutsFichier
           WHERE vcCode_Statut = 'ERR')
 
   -- Récupérer les noms des destinataires dans les paramètres applicatifs 
   SET @vcDestinataire_Courriel = dbo.fnGENE_ObtenirParametre('OPER_RDI_IMPORTER_COURRIEL_vcDestinataire',NULL,'RDI',NULL,NULL,NULL,NULL)
   SET @vcDestinataire_Copie    = dbo.fnGENE_ObtenirParametre('OPER_RDI_IMPORTER_COURRIEL_vcDestinataireCopie',NULL,'RDI',NULL,NULL,NULL,NULL) 
   SET @vcDestinataire_Cache    = dbo.fnGENE_ObtenirParametre('OPER_RDI_IMPORTER_COURRIEL_vcDestinataireCopieCache',NULL,'RDI',NULL,NULL,NULL,NULL)   

   -- Si le fichier a déjà été importé (1) ou si l'importation de la banque n'a pas été fait (3),
   -- ne pas envoyer de message
   IF (@tiCode_Retour_Erreur != 1 OR @tiCode_Retour_Erreur != 3)
   BEGIN   
      EXEC psGENE_EnvoyerCourriel
         @vcDestinataire            = @vcDestinataire_Courriel
         ,@vcDestinataireCopie      = @vcDestinataire_Copie
         ,@vcDestinataireCopieCache = @vcDestinataire_Cache
         ,@vcSujet                  = @vcSujetCourriel
         ,@vcContenuMessage         = @vcContenuMessageCourriel
         ,@bHTML                    = 1
         ,@iImportance              = 1
         ,@vcCheminAttachement      = NULL
         ,@vcProfilCourriel         = NULL
   END

   RETURN @tiCode_Retour_Erreur

END


