/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : psOPER_RDI_ObtenirMontantModification
Nom du service  : Obtenir le montant disponible d'une opération RDI liée à un paiement
But             : Récupérer l’information sur le montant disponible d'un paiement afin
                  de procéder à la modification d'une opération liée à un paiement RDI.
Facette         : OPER

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -----------------------------------
                      @iID_UnOper                Identifiant unique d'une opération

Paramètres de sortie:
        Paramètre(s)             Champ(s)                Description
        ------------------------ ----------------------  ---------------------------
        S/O                      mMontantDisponible      Montant maximum pouvant servir 
                                                         à l’opération demandée   

Exemple d’appel     : EXECUTE [dbo].[psOPER_RDI_ObtenirMontantModification] 19062180

Historique des modifications:
        Date            Programmeur                         Description
        ------------    ---------------------------------- --------------------------
        2010-02-02      Danielle Côté                       Création du service

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_RDI_ObtenirMontantModification]
(
   @iID_UnOper INT
)
AS
BEGIN

   DECLARE
      @iID_RDI_Paiement INT
     ,@mMontant_Oper     MONEY
     
   SELECT @mMontant_Oper = [dbo].[fnOPER_RDI_CalculerMontantAssigne] (@iID_UnOper)
   
   -------------------------------------------------------------------------
   -- Récupérer le ID du paiement relié à l'opération
   -------------------------------------------------------------------------
   SELECT @iID_RDI_Paiement = iID_RDI_Paiement 
     FROM tblOPER_RDI_liens
    WHERE OperID = @iID_UnOper

   -------------------------------------------------------------------------
   -- Additionner le montant de l'opération sélectionnée et 
   -- la somme disponible du paiement
   -------------------------------------------------------------------------
   SELECT (mMontant_Solde + @mMontant_Oper) as mMontantDisponible
     FROM [dbo].[fntOPER_RDI_ObtenirMontantDisponible](@iID_RDI_Paiement)

END 
