/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : psOPER_RDI_ImporterDepots
Nom du service  : Importer les dépôts RDI.
But             : Extraire des lignes des fichiers EDI importés, les informations
                  relatives aux dépôts.
Facette         : OPER

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -----------------------------------
                      Aucun

Paramètres de sortie: Paramètre   Champ(s)               Description
                      ----------- ---------------------- ---------------------------
                      S/O         iCode_Retour           0 = Traitement réussi
                                                         -1 = Les dépôts n'ont pas été importés
                                                         -2 = Erreur de traitement

Exemple d’appel     : EXECUTE [dbo].[psOPER_RDI_ImporterDepots]

Historique des modifications:
        Date            Programmeur                         Description
        ------------    ---------------------------------- ---------------------------
        2010-01-20      Danielle Côté                       Création du service

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_RDI_ImporterDepots]
AS
BEGIN
   -- Variables de travail "Dépôt"
   DECLARE
      @iID_EDI_Fichier        INT
     ,@tiID_RDI_Statut_Depot  TINYINT
     ,@vcDate_Depot           VARCHAR(10)
     ,@dtDate_Depot           DATETIME
     ,@mMontant_Depot         MONEY
     ,@cDevise                CHAR(3)
     ,@tiID_EDI_Banque        TINYINT
     ,@vcNo_Cheque            VARCHAR(30)
     ,@vcNo_Trace             VARCHAR(30)
     ,@vcNom_Payeur           VARCHAR(35)
     ,@vcNom_Beneficiaire     VARCHAR(35)
     ,@cTest                  CHAR(1)

   -- Variables de travail pour les positions et occurences
   ,@tiPos_Depot      TINYINT
   ,@tiOcc_Depot      TINYINT
   ,@tiPos_Date       TINYINT
   ,@tiOcc_Date       TINYINT
   ,@tiPos_Montant    TINYINT
   ,@tiOcc_Montant    TINYINT
   ,@tiPos_Devise     TINYINT
   ,@tiOcc_Devise     TINYINT
   ,@tiPos_Cheque     TINYINT
   ,@tiOcc_Cheque     TINYINT
   ,@tiPos_Trace      TINYINT
   ,@tiOcc_Trace      TINYINT
   ,@tiPos_Nom_Payeur TINYINT
   ,@tiOcc_Nom_Payeur TINYINT
   ,@tiPos_Nom_Benef  TINYINT
   ,@tiOcc_Nom_Benef  TINYINT
   ,@tiPos_Test       TINYINT
   ,@tiOcc_Test       TINYINT

   -- Variables de travail GENE
   ,@vcNom_Fichier            VARCHAR(50)
   ,@vcTexte_Ligne            VARCHAR(152)
   ,@tiID_EDI_Statut_Fichier  TINYINT

   --Affectation des valeurs de délimitations position et occurence
   SET @tiPos_Depot      = 1
   SET @tiOcc_Depot      = 152
   SET @tiPos_Date       = 1
   SET @tiOcc_Date       = 10
   SET @tiPos_Montant    = @tiPos_Date + @tiOcc_Date             --11
   SET @tiOcc_Montant    = 8
   SET @tiPos_Devise     = @tiPos_Montant + @tiOcc_Montant       --19
   SET @tiOcc_Devise     = 3
   SET @tiPos_Cheque     = @tiPos_Devise + @tiOcc_Devise         --22
   SET @tiOcc_Cheque     = 30
   SET @tiPos_Trace      = @tiPos_Cheque + @tiOcc_Cheque         --52
   SET @tiOcc_Trace      = 30
   SET @tiPos_Nom_Payeur = @tiPos_Trace + @tiOcc_Trace           --82
   SET @tiOcc_Nom_Payeur = 35
   SET @tiPos_Nom_Benef  = @tiPos_Nom_Payeur + @tiOcc_Nom_Payeur --117
   SET @tiOcc_Nom_Benef  = 35
   SET @tiPos_Test       = @tiPos_Nom_Benef + @tiOcc_Nom_Benef   --152
   SET @tiOcc_Test       = 1

   SET @vcNom_Fichier = [dbo].[fnOPER_RDI_GenererNomFichier]()

   -------------------------------------------------------------------------
   -- S'assurer que le fichier a été importé
   ------------------------------------------------------------------------- 
   IF NOT EXISTS (SELECT 1
                    FROM tblOPER_EDI_Fichiers f,
                         tblOPER_EDI_StatutsFichier s
                   WHERE UPPER(vcNom_Fichier) = UPPER(@vcNom_Fichier)
                     AND f.tiID_EDI_Statut_Fichier = s.tiID_EDI_Statut_Fichier
                     AND s.vcCode_Statut <> 'ERR')
   BEGIN
      -- OPERE0011 Les dépôts n’ont pas été importés.
      RETURN -1
   END
   ELSE
   BEGIN
   
      SET XACT_ABORT ON
      BEGIN TRANSACTION
      BEGIN TRY
         -------------------------------------------------------------------------
         -- Lecture de la zone d'une ligne de fichier qui délimite
         -- les informations du dépôt (1 à 152)
         -------------------------------------------------------------------------
         DECLARE curLignesFichier CURSOR FOR
            SELECT FIC.iID_EDI_Fichier, 
                   SUBSTRING(LIG.cLigne,@tiPos_Depot,@tiOcc_Depot)
              FROM tblOPER_EDI_Fichiers FIC,
                   tblOPER_EDI_LignesFichier LIG,
                   tblOPER_EDI_StatutsFichier STA
             WHERE FIC.iID_EDI_Fichier = LIG.iID_EDI_Fichier
               AND FIC.vcNom_Fichier = @vcNom_Fichier
               AND FIC.tiID_EDI_Statut_Fichier = STA.tiID_EDI_Statut_Fichier
               AND STA.vcCode_Statut <> 'ERR'
             GROUP BY FIC.iID_EDI_Fichier, 
                   SUBSTRING(LIG.cLigne,@tiPos_Depot,@tiOcc_Depot)

         OPEN curLignesFichier
         FETCH NEXT FROM curLignesFichier INTO @iID_EDI_Fichier, @vcTexte_ligne
         WHILE @@FETCH_STATUS = 0
         BEGIN 
            -------------------------------------------------------------------------
            -- Affecter le ID statut du dépôt
            -- Si avant 18 heures, il s'agit d'une importation par l'usager
            -- Si après 18 heures, il s'agit d'une importation automatique
            -------------------------------------------------------------------------
            IF (SELECT SUBSTRING(CONVERT(CHAR(8),CURRENT_TIMESTAMP,8),1,2)) < 18
               SELECT @tiID_RDI_Statut_Depot = tiID_RDI_Statut_Depot
                 FROM tblOPER_RDI_StatutsDepot
                WHERE UPPER(LTRIM(LTRIM(vcCode_Statut))) = 'NOU'
            ELSE
                SELECT @tiID_RDI_Statut_Depot = tiID_RDI_Statut_Depot
                 FROM tblOPER_RDI_StatutsDepot
                WHERE UPPER(LTRIM(LTRIM(vcCode_Statut))) = 'AUT'           

            SET @vcDate_Depot       = SUBSTRING(@vcTexte_ligne,@tiPos_Date,@tiOcc_Date)
            SET @dtDate_Depot       = CAST(([dbo].[fnGENE_VerifierFormatDate](@vcDate_Depot)) as DATETIME)
            SET @mMontant_Depot     = CAST(SUBSTRING(@vcTexte_ligne,@tiPos_Montant,@tiOcc_Montant) as MONEY)
            SET @cDevise            = SUBSTRING(@vcTexte_ligne,@tiPos_Devise,@tiOcc_Devise)
            SET @vcNom_Payeur       = SUBSTRING(@vcTexte_ligne,@tiPos_Nom_Payeur,@tiOcc_Nom_Payeur)
            IF [dbo].[fnOPER_EDI_VerifierBanqueExiste](@vcNom_Payeur) = 0
               EXECUTE [dbo].[psOPER_EDI_AjouterBanque] @vcNom_Payeur
            SET @tiID_EDI_Banque    = [dbo].[fnOPER_EDI_VerifierBanqueExiste](@vcNom_Payeur)
            SET @vcNo_Cheque        = SUBSTRING(@vcTexte_ligne,@tiPos_Cheque,@tiOcc_Cheque)
            SET @vcNo_Trace         = SUBSTRING(@vcTexte_ligne,@tiPos_Trace,@tiOcc_Trace)
            SET @vcNom_Beneficiaire = SUBSTRING(@vcTexte_ligne,@tiPos_Nom_Benef,@tiOcc_Nom_Benef)
            SET @cTest              = SUBSTRING(@vcTexte_ligne,@tiPos_Test,@tiOcc_Test)

            -------------------------------------------------------------------------
            -- INSERER DANS LA TABLE tblOPER_RDI_Depots
            -------------------------------------------------------------------------
            INSERT INTO [dbo].[tblOPER_RDI_Depots]
                       ([iID_EDI_Fichier]
                       ,[tiID_RDI_Statut_Depot]
                       ,[dtDate_Depot]
                       ,[mMontant_Depot]
                       ,[cDevise]
                       ,[tiID_EDI_Banque]
                       ,[vcNo_Cheque]
                       ,[vcNo_Trace]
                       ,[vcNom_Beneficiaire]
                       ,[cTest])
                VALUES (@iID_EDI_Fichier
                       ,@tiID_RDI_Statut_Depot
                       ,@dtDate_Depot
                       ,@mMontant_Depot
                       ,@cDevise
                       ,@tiID_EDI_Banque 
                       ,@vcNo_Cheque
                       ,@vcNo_Trace
                       ,@vcNom_Beneficiaire
                       ,@cTest)
            FETCH NEXT FROM curLignesFichier INTO @iID_EDI_Fichier, @vcTexte_ligne
         END
         CLOSE curLignesFichier
         DEALLOCATE curLignesFichier 

         -- Mettre à jour le statut du fichier
         EXECUTE [dbo].[psOPER_EDI_ModifierStatutFichier] 'IMP',@vcNom_Fichier

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

         CLOSE curLignesFichier
         DEALLOCATE curLignesFichier

         -- Mettre à jour le statut du fichier
         EXECUTE [dbo].[psOPER_EDI_ModifierStatutFichier] 'ERR',@vcNom_Fichier

         -- OPERE0012 Une erreur est survenue dans l’importation de(s) dépôt(s). 
         RETURN -2

      END CATCH
   END
END
