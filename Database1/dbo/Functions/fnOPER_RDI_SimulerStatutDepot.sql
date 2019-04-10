/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : fnOPER_RDI_SimulerStatutDepot
Nom du service  : Simuler le statut d'un dépôt.
But             : Simule le statut d'un dépôt en comparant le montant assigné et le 
                  montant du dépôt.
Facette         : OPER

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -----------------------------------
                      @iID_RDI_Depot             Identifiant unique d'un dépôt

Paramètres de sortie: Paramètre                  Description
                      -------------------------- -----------------------------------
                      @tiID_RDI_Statut_Depot     Identifiant unique d'un statut de dépôt

Exemple d’appel     : SELECT [dbo].[fnOPER_RDI_SimulerStatutDepot](43)

Historique des modifications:
        Date            Programmeur                         Description
        ------------    ---------------------------------- ---------------------------
        2010-02-25      Danielle Côté                       Création du service

****************************************************************************************************/
CREATE FUNCTION [dbo].[fnOPER_RDI_SimulerStatutDepot]
(
   @iID_RDI_Depot INT
)
RETURNS TINYINT
AS
BEGIN
   DECLARE 
      @tiID_RDI_Statut_Depot TINYINT
     ,@montantDepot          MONEY
     ,@montantAssigneDepot   MONEY

   SET @montantAssigneDepot = [dbo].[fnOPER_RDI_CalculerMontantAssigneDepot](@iID_RDI_Depot,NULL)

   IF @montantAssigneDepot = 0
   BEGIN
      -- Dépôt non assigné (Nouveau fichier)
      SET @tiID_RDI_Statut_Depot = 3 
   END
   ELSE
   BEGIN
      SET @montantDepot = (SELECT mMontant_Depot
                             FROM tblOPER_RDI_Depots
                            WHERE iID_RDI_Depot = @iID_RDI_Depot)
      IF @montantAssigneDepot < @montantDepot
      BEGIN
         --Dépôt partiellement assigné
         SET @tiID_RDI_Statut_Depot = 2
      END
      ELSE
      BEGIN
         IF @montantAssigneDepot = @montantDepot
         BEGIN
            --Dépôt totalement assigné
            SET @tiID_RDI_Statut_Depot = 1
         END
         ELSE
         BEGIN
            SET @tiID_RDI_Statut_Depot = 4
         END
      END
   END

   RETURN @tiID_RDI_Statut_Depot
END 
