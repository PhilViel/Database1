/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : fntOPER_RDI_ObtenirMontantDisponible
Nom du service  : Obtenir les données financières d'un paiement
But             : Récupérer les données financières d'un paiement.
Facette         : OPER

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -----------------------------------
                      @iID_RDI_Paiement          Identifiant unique d'un paiement

Paramètres de sortie: @tblOPER_Resultats
Paramètre(s)            Champ(s)                                         Description
----------------------- ------------------------------------------------ ----------------------------
iID_RDI_Paiement        tblOPER_RDI_Paiements.iID_RDI_Paiement           Identifiant unique d'un paiement
mMontant_Solde          tblOPER_RDI_Paiements.mMontant_Paiement_Final    Solde disponible
                        moins le montant relié à de(s) opération(s)
mMontant_Paiement_Final tblOPER_RDI_Paiements.mMontant_Paiement_Final    Montant total reçu du déposant

Exemple d’appel     : SELECT * FROM [dbo].[fntOPER_RDI_ObtenirMontantDisponible](273)

Historique des modifications:
        Date            Programmeur                         Description
        ------------    ---------------------------------- ---------------------------
        2010-03-20      Danielle Côté                       Création du service

****************************************************************************************************/
CREATE FUNCTION [dbo].[fntOPER_RDI_ObtenirMontantDisponible]
(
   @iID_RDI_Paiement INT
)
RETURNS @tblOPER_Resultats
        TABLE
        (iID_RDI_Paiement        INT
        ,mMontant_Solde          MONEY
        ,mMontant_Paiement_Final MONEY)
BEGIN

   INSERT INTO @tblOPER_Resultats
              (iID_RDI_Paiement
              ,mMontant_Solde
              ,mMontant_Paiement_Final)
        SELECT iID_RDI_Paiement
              ,(mMontant_Paiement_Final - 
               ([dbo].[fnOPER_RDI_CalculerMontantAssignePaiement](@iID_RDI_Paiement,NULL)))
              ,mMontant_Paiement_Final
          FROM tblOPER_RDI_Paiements
         WHERE iID_RDI_Paiement = @iID_RDI_Paiement

   RETURN

END 
