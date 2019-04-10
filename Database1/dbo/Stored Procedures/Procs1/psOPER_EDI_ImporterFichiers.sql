/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : psOPER_EDI_ImporterFichiers
Nom du service  : Importer les fichiers EDI.
But             : Lire un fichier texte et écrire les informations dans des tables.
Facette         : OPER

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -----------------------------------
                      @vcTypeFichier             Code unique permettant de définir le
                                                 type de fichier EDI traité
                      @iID_Utilisateur           ID de l'utilisateur

Paramètres de sortie: Paramètre   Champ(s)               Description
                      ----------- ---------------------- ---------------------------
                      S/O         iCode_Retour            0 = Traitement réussi
                                                         -1 = Un fichier en date du jour a déjà été importé
                                                         -2 = Erreur de traitement
                                                              dans la lecture du fichier
                                                         -3 = Il n'y a pas de fichier existant en date du jour

Exemple d’appel     : EXEC [dbo].[psOPER_EDI_ImporterFichiers] 'RDI', 575752

Historique des modifications:
        Date            Programmeur                         Description
        ------------    ---------------------------------- ---------------------------
        2010-01-19      Danielle Côté                       Création du service

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_EDI_ImporterFichiers]
(
   @vcTypeFichier   VARCHAR(3)
  ,@iID_Utilisateur INT
)
AS
BEGIN
   -- Variables de travail "Fichier"
   DECLARE
      @tiID_EDI_Type_Fichier     TINYINT
     ,@tiID_EDI_Statut_Fichier   TINYINT
     ,@iID_Utilisateur_Creation  INT
     ,@dtDate_Creation           DATETIME
     ,@vcNom_Fichier             VARCHAR(50)
     ,@vcChemin_Fichier          VARCHAR(150)
     ,@tCommentaires             VARCHAR(250)

      -- Variables de travail "Ligne"
     ,@iID_EDI_Fichier           INT
     ,@iSequence                 INT

     -- Variables de travail GENE
     ,@SQL_EDI                   VARCHAR(2000)
     ,@vcNom_Fichier_Format      VARCHAR(50)
     ,@vcChemin_Fichier_Format   VARCHAR(150)
     ,@iFichierFormat_existe     TINYINT
     ,@iFichierEDI_existe        TINYINT

     -- Rendre conforme le contenu du paramètre
     SET @vcTypeFichier = UPPER(LTRIM(LTRIM(@vcTypeFichier)))

   -------------------------------------------------------------------------
   -- Affecter le ID type de fichier 
   -------------------------------------------------------------------------
   SELECT @tiID_EDI_Type_Fichier = tiID_EDI_Type_Fichier
     FROM tblOPER_EDI_TypesFichier
    WHERE UPPER(LTRIM(LTRIM(vcCode_Type_Fichier))) = @vcTypeFichier

   -------------------------------------------------------------------------
   -- Affecter les variables GÉNÉRIQUES
   -------------------------------------------------------------------------
   SELECT @tiID_EDI_Statut_Fichier = 1
   SET @iID_Utilisateur_Creation = @iID_Utilisateur
   SET @dtDate_Creation = CURRENT_TIMESTAMP
   SET @vcChemin_Fichier =        dbo.fnGENE_ObtenirParametre(
                                  'OPER_EDI_IMPORTER_FICHIER_vcChemin_Fichier',
                                  NULL,@vcTypeFichier,NULL,NULL,NULL,NULL)
   SET @vcNom_Fichier_Format =    dbo.fnGENE_ObtenirParametre(
                                  'OPER_EDI_IMPORTER_FICHIER_vcNom_Fichier_Format',
                                  NULL,@vcTypeFichier,NULL,NULL,NULL,NULL)
   SET @vcChemin_Fichier_Format = dbo.fnGENE_ObtenirParametre(
                                  'OPER_EDI_IMPORTER_FICHIER_vcChemin_Fichier_Format',
                                  NULL,@vcTypeFichier,NULL,NULL,NULL,NULL)

   -------------------------------------------------------------------------
   -- Affecter les variables selon le type RDI
   -------------------------------------------------------------------------
   IF @vcTypeFichier = 'RDI'
   BEGIN
      SET @vcNom_Fichier = [dbo].[fnOPER_RDI_GenererNomFichier]()
      SET @tCommentaires = 'Réception dépôts informatisé'
   END

   -------------------------------------------------------------------------
   -- S'assurer que le fichier de formatage existe
   -------------------------------------------------------------------------
   IF @vcNom_Fichier_Format <> ''
   BEGIN
      EXECUTE @iFichierFormat_existe = 
              [dbo].[psGENE_FichierRepertoireExiste]
              @vcChemin_Fichier_Format, @vcNom_Fichier_Format
   END
   ELSE
   BEGIN
      SET @iFichierFormat_existe = 3
   END

   -------------------------------------------------------------------------
   -- S'assurer que le fichier EDI à lire existe
   -------------------------------------------------------------------------
   EXECUTE @iFichierEDI_existe = 
           [dbo].[psGENE_FichierRepertoireExiste] 
           @vcChemin_Fichier, @vcNom_Fichier

   IF @iFichierEDI_existe = 3
   BEGIN
      IF @iFichierFormat_existe  = 3
      BEGIN
         -- S'assurer que l'import du fichier n'a pas déjà été fait avec succès
         IF EXISTS (SELECT 1
                      FROM tblOPER_EDI_Fichiers f,
                           tblOPER_EDI_StatutsFichier s
                     WHERE UPPER(vcNom_Fichier) = UPPER(@vcNom_Fichier)
                       AND f.tiID_EDI_Statut_Fichier = s.tiID_EDI_Statut_Fichier
                       AND s.vcCode_Statut <> 'ERR')
         BEGIN
            -- OPERE0008 Le fichier de dépôts d'aujourd'hui a déjà été importé dans UniAccès.
            RETURN -1
         END
         ELSE
         BEGIN

            -------------------------------------------------------------------------
            -- INSERER DANS LA TABLE tblOPER_EDI_Fichiers
            -------------------------------------------------------------------------
            INSERT INTO [dbo].[tblOPER_EDI_Fichiers]
                       ([tiID_EDI_Type_Fichier]
                       ,[tiID_EDI_Statut_Fichier]
                       ,[iID_Utilisateur_Creation]
                       ,[dtDate_Creation]
                       ,[vcNom_Fichier]
                       ,[vcChemin_Fichier]
                       ,[tCommentaires])
                VALUES (@tiID_EDI_Type_Fichier
                       ,@tiID_EDI_Statut_Fichier
                       ,@iID_Utilisateur_Creation
                       ,@dtDate_Creation
                       ,@vcNom_Fichier
                       ,@vcChemin_Fichier
                       ,@tCommentaires)

            -- Vérifier si l'insertion a fonctionnée
            IF EXISTS (SELECT 1
                         FROM tblOPER_EDI_Fichiers f,
                              tblOPER_EDI_StatutsFichier s
                        WHERE UPPER(vcNom_Fichier) = UPPER(@vcNom_Fichier)
                          AND f.tiID_EDI_Statut_Fichier = s.tiID_EDI_Statut_Fichier
                          AND s.vcCode_Statut <> 'ERR')
            BEGIN

               -- Récupérer le ID du fichier
               SELECT @iID_EDI_Fichier = iID_EDI_Fichier
                 FROM tblOPER_EDI_Fichiers f,
                      tblOPER_EDI_StatutsFichier s
                WHERE UPPER(vcNom_Fichier) = UPPER(@vcNom_Fichier)
                  AND f.tiID_EDI_Statut_Fichier = s.tiID_EDI_Statut_Fichier
                  AND s.vcCode_Statut <> 'ERR'

               SET @iSequence = 0

               -- Construire les chemins complets
               SET @vcNom_Fichier = @vcChemin_Fichier + @vcNom_Fichier
               SET @vcNom_Fichier_Format = @vcChemin_Fichier_Format + @vcNom_Fichier_Format

               -------------------------------------------------------------------------
               -- Lire le fichier texte
               -------------------------------------------------------------------------
               SET XACT_ABORT ON
               BEGIN TRANSACTION
               BEGIN TRY

                  --------------------------------------------------------------------------------
                  -- INSERER DANS LA TABLE tblOPER_EDI_LignesFichier
                  --------------------------------------------------------------------------------
                  SET @SQL_EDI = 
                     'INSERT INTO tblOPER_EDI_LignesFichier' +
                             '(iID_EDI_Fichier,iSequence,cLigne) ' +
                     'SELECT ' + str(@iID_EDI_Fichier) + ' as iID_EDI_Fichier,'
                               + str(@iSequence) + ' as iSequence,' +
                             '* FROM OPENROWSET(BULK ' + 'N' + '''' + @vcNom_Fichier + '''' +
                             ', FORMATFILE = ' +  '''' + @vcNom_Fichier_Format + '''' + ') as cLigne'
                  EXEC(@SQL_EDI)

                  --  Mettre à jour le numéro de séquence
                  UPDATE [dbo].[tblOPER_EDI_LignesFichier]
                     SET iSequence = iID_EDI_Ligne_Fichier
                   WHERE iID_EDI_Fichier = @iID_EDI_Fichier

                  -- Mettre à jour le statut du fichier
                  EXECUTE [dbo].[psOPER_EDI_ModifierStatutFichier] 'CRE',@vcNom_Fichier
                  
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

                 -- Mettre à jour le statut du fichier
                 EXECUTE [dbo].[psOPER_EDI_ModifierStatutFichier] 'ERR',@vcNom_Fichier

                 -- OPERE0009 Une erreur est survenue dans l’importation du fichier.
                 RETURN -2

               END CATCH
            END
         END
      END
   END
   ELSE
   BEGIN
      -- OPERE0010 Il n'y a pas de fichier en date du jour.  Veuillez vérifier l'importation de Liaison Clients.
      RETURN -3
   END
END
