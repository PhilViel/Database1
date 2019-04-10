/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : psOPER_RDI_ImporterPaiements
Nom du service  : Importer les paiements RDI.
But             : Extraire des lignes des fichiers EDI importés, les informations 
                  relatives au paiement.
Facette         : OPER

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -----------------------------------
                      Aucun

Paramètres de sortie: Paramètre   Champ(s)               Description
                      ----------- ---------------------- ---------------------------
                      S/O         iCode_Retour            0 = Traitement réussi
                                                         -1 = Les paiements n'ont pas été importés 
                                                         -2 = Erreur de traitement

Exemple d’appel     : EXECUTE [dbo].[psOPER_RDI_ImporterPaiements]

Historique des modifications:
        Date            Programmeur                         Description
        ------------    ---------------------------------- ---------------------------
        2010-01-26      Danielle Côté                       Création du service

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_RDI_ImporterPaiements]
AS
BEGIN
   -- Variables de travail "Paiement"
   DECLARE
      @iID_RDI_Depot           INT
     ,@vcNom_Deposant          VARCHAR(35)
     ,@mMontant_Paiement       MONEY
     ,@mMontant_Reduction      MONEY
     ,@mMontant_Paiement_Final MONEY
     ,@vcNo_Document           VARCHAR(30)
     ,@vcDesc_Document         VARCHAR(100)
     ,@vcNo_Oper               VARCHAR(50)
     ,@vcDesc_Oper             VARCHAR(50)
     ,@vcAutre_Texte           VARCHAR(500)

     -- Variables de travail pour les positions et occurences
     ,@tiPos_Paiement               SMALLINT
     ,@tiOcc_Paiement               SMALLINT
     ,@tiPos_Nom_Deposant           SMALLINT
     ,@tiOcc_Nom_Deposant           SMALLINT
     ,@tiPos_Montant_Paiement       SMALLINT
     ,@tiOcc_Montant_Paiement       SMALLINT
     ,@tiPos_Montant_Reduction      SMALLINT
     ,@tiOcc_Montant_Reduction      SMALLINT
     ,@tiPos_Montant_Paiement_Final SMALLINT
     ,@tiOcc_Montant_Paiement_Final SMALLINT
     ,@tiPos_No_Document            SMALLINT
     ,@tiOcc_No_Document            SMALLINT
     ,@tiPos_Desc_Document          SMALLINT
     ,@tiOcc_Desc_Document          SMALLINT
     ,@tiPos_No_Oper                SMALLINT
     ,@tiOcc_No_Oper                SMALLINT
     ,@tiPos_Desc_Oper              SMALLINT
     ,@tiOcc_Desc_Oper              SMALLINT
     ,@tiPos_Autre_Texte            SMALLINT
     ,@tiOcc_Autre_Texte            SMALLINT

     -- Variables de travail GENE   
     ,@vcNom_Fichier            VARCHAR(50)
     ,@vcTexte_Ligne            VARCHAR(800)
     ,@tiID_EDI_Statut_Fichier  TINYINT

   --Affectation des valeurs de délimitations position et occurence
   SET @tiPos_Paiement               = 153
   SET @tiOcc_Paiement               = 800
   SET @tiPos_Nom_Deposant           = 1
   SET @tiOcc_Nom_Deposant           = 35
   SET @tiPos_Montant_Paiement       = @tiPos_Nom_Deposant + @tiOcc_Nom_Deposant
   SET @tiOcc_Montant_Paiement       = 8
   SET @tiPos_Montant_Reduction      = @tiPos_Montant_Paiement + @tiOcc_Montant_Paiement
   SET @tiOcc_Montant_Reduction      = 8
   SET @tiPos_Montant_Paiement_Final = @tiPos_Montant_Reduction + @tiOcc_Montant_Reduction
   SET @tiOcc_Montant_Paiement_Final = 8
   SET @tiPos_No_Document            = @tiPos_Montant_Paiement_Final + @tiOcc_Montant_Paiement_Final
   SET @tiOcc_No_Document            = 30
   SET @tiPos_Desc_Document          = @tiPos_No_Document + @tiOcc_No_Document
   SET @tiOcc_Desc_Document          = 100
   SET @tiPos_Desc_Oper              = @tiPos_Desc_Document + @tiOcc_Desc_Document
   SET @tiOcc_Desc_Oper              = 50   
   SET @tiPos_No_Oper                = @tiPos_Desc_Oper + @tiOcc_Desc_Oper
   SET @tiOcc_No_Oper                = 50
   SET @tiPos_Autre_Texte            = @tiPos_No_Oper + @tiOcc_No_Oper
   SET @tiOcc_Autre_Texte            = 500

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
      -- OPERE0013 Les paiements n’ont pas été importés.
      RETURN -1
   END
   ELSE
   BEGIN
   
      SET XACT_ABORT ON
      BEGIN TRANSACTION
      BEGIN TRY
         -------------------------------------------------------------------------
         -- Lecture de la zone d'une ligne de fichier qui délimite
         -- les informations du paiement(153 à la fin)
         -------------------------------------------------------------------------
         DECLARE curLignesFichier CURSOR FOR
            SELECT DEP.iID_RDI_Depot, 
                   SUBSTRING(LIG.cLigne,@tiPos_Paiement,@tiOcc_Paiement)
              FROM tblOPER_RDI_Depots DEP
              JOIN tblOPER_EDI_LignesFichier LIG ON SUBSTRING(LIG.cLigne,22,30) = DEP.vcNo_Cheque
              JOIN tblOPER_EDI_Fichiers FIC ON FIC.iID_EDI_Fichier = DEP.iID_EDI_Fichier 
               AND FIC.iID_EDI_Fichier = LIG.iID_EDI_Fichier
               AND FIC.vcNom_Fichier = @vcNom_Fichier
              JOIN tblOPER_EDI_StatutsFichier STA ON STA.tiID_EDI_Statut_Fichier = FIC.tiID_EDI_Statut_Fichier
               AND STA.vcCode_Statut <> 'ERR'
             ORDER BY DEP.iID_RDI_Depot             

         OPEN curLignesFichier
         FETCH NEXT FROM curLignesFichier INTO @iID_RDI_Depot, @vcTexte_ligne
         WHILE @@FETCH_STATUS = 0
         BEGIN    

            SET @vcNom_Deposant          = SUBSTRING(@vcTexte_ligne,@tiPos_Nom_Deposant,@tiOcc_Nom_Deposant)
            SET @mMontant_Paiement       = CAST(SUBSTRING(@vcTexte_ligne,@tiPos_Montant_Paiement,@tiOcc_Montant_Paiement) as MONEY)
            SET @mMontant_Reduction      = CAST(SUBSTRING(@vcTexte_ligne,@tiPos_Montant_Reduction,@tiOcc_Montant_Reduction) as MONEY)
            SET @mMontant_Paiement_Final = CAST(SUBSTRING(@vcTexte_ligne,@tiPos_Montant_Paiement_Final,@tiOcc_Montant_Paiement_Final) as MONEY)
            SET @vcNo_Document           = SUBSTRING(@vcTexte_ligne,@tiPos_No_Document,@tiOcc_No_Document)
            SET @vcDesc_Document         = SUBSTRING(@vcTexte_ligne,@tiPos_Desc_Document,@tiOcc_Desc_Document)
            SET @vcNo_Oper               = SUBSTRING(@vcTexte_ligne,@tiPos_No_Oper,@tiOcc_No_Oper)
            SET @vcDesc_Oper             = SUBSTRING(@vcTexte_ligne,@tiPos_Desc_Oper,@tiOcc_Desc_Oper)
            SET @vcAutre_Texte           = SUBSTRING(@vcTexte_ligne,@tiPos_Autre_Texte,@tiOcc_Autre_Texte)

            -------------------------------------------------------------------------
            -- INSERER DANS LA TABLE tblOPER_RDI_Paiements
            -------------------------------------------------------------------------
            INSERT INTO [dbo].[tblOPER_RDI_Paiements]
                       ([iID_RDI_Depot]
                       ,[vcNom_Deposant]
                       ,[mMontant_Paiement]
                       ,[mMontant_Reduction]
                       ,[mMontant_Paiement_Final]
                       ,[vcNo_Document]
                       ,[vcDesc_Document]
                       ,[vcNo_Oper]
                       ,[vcDesc_Oper]
                       ,[vcAutreTexte])
                VALUES (@iID_RDI_Depot
                       ,@vcNom_Deposant
                       ,@mMontant_Paiement
                       ,@mMontant_Reduction
                       ,@mMontant_Paiement_Final
                       ,@vcNo_Document
                       ,@vcDesc_Document
                       ,@vcNo_Oper
                       ,@vcDesc_Oper
                       ,@vcAutre_Texte)
            FETCH NEXT FROM curLignesFichier INTO @iID_RDI_Depot, @vcTexte_ligne
         END
         CLOSE curLignesFichier
         DEALLOCATE curLignesFichier 

         -- Mettre à jour le statut du fichier
         EXECUTE [dbo].[psOPER_EDI_ModifierStatutFichier] 'ATR',@vcNom_Fichier

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

         -- OPERE0014 Une erreur est survenue dans l’importation de(s) paiement(s).
         RETURN -2

      END CATCH
   END
END
