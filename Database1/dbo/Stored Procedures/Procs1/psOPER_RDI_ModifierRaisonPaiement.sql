/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : psOPER_RDI_ModifierRaisonPaiement
Nom du service  : Modifier la raison du paiement.
But             : Modifier la raison du paiement suite aux opérations d'assignement.
Facette         : OPER

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -------------------------------------
                      @iID_RDI_Paiement          Identifiant unique d'un paiement.

Paramètres de sortie: Paramètre   Champ(s)               Description
                      ----------- ---------------------- -----------------------------
                      S/O         iCode_Retour            0 = Traitement réussi
                                                         -1 = Le dépôt n'existe pas
                                                         -2 = Erreur de traitement

Exemple d’appel     : EXECUTE dbo.psOPER_RDI_ModifierRaisonPaiement 12

Historique des modifications:
        Date            Programmeur                         Description
        ------------    ---------------------------------- ---------------------------
        2016-05-16      Steeve Picard                      Création du service

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_RDI_ModifierRaisonPaiement]
(
   @iID_RDI_Paiement INT,
   @tiID_Raison_Paiement TINYINT,
   @vcDescription_Raison varchar(100)
)
AS
BEGIN
    -------------------
    -- Mettre à jour
    -------------------
    BEGIN TRY

        UPDATE tblOPER_RDI_Paiements
           SET tiID_RDI_Raison_Paiement = @tiID_Raison_Paiement,
               vcDescription_Raison = @vcDescription_Raison
         WHERE iID_RDI_Paiement = @iID_RDI_Paiement

        RETURN 0

    END TRY
    BEGIN CATCH

        DECLARE @ErrorMessage NVARCHAR(4000)
               ,@ErrorSeverity INT
               ,@ErrorState INT

        SET @ErrorMessage = ERROR_MESSAGE()
        SET @ErrorSeverity = ERROR_SEVERITY()
        SET @ErrorState = ERROR_STATE()

        RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState) WITH LOG;
        RETURN -2
    END CATCH
END 
