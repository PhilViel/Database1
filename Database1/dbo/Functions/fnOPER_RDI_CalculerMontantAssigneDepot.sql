/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : fnOPER_RDI_CalculerMontantAssigneDepot
Nom du service  : Calculer le montant encaissé associé à un dépôt.
But             : Calcule le montant assigné d'un dépôt à une date.
                  Si la date est NULL, la date du jour est considérée.
                  Lors de l'affichage dans l'application, ce service utilise la valeur
                  NULL pour la date, mais pour les besoins des rapports, une date
                  spécifique est nécessaire pour connaître la situation à une date donnée.

Facette         : OPER

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -----------------------------------
                      @iID_RDI_Depot             Identifiant unique d'un dépot
                      @dtDate                    Montant assigné en date du

Paramètres de sortie: Paramètre                  Description
                      -------------------------- -----------------------------------
                      @mMontantAssigneTotal      Montant

Exemple d’appel     : SELECT [dbo].[fnOPER_RDI_CalculerMontantAssigneDepot](12,NULL)

Historique des modifications:
        Date            Programmeur                         Description
        ------------    ---------------------------------- ---------------------------
        2010-01-27      Danielle Côté                       Création du service

****************************************************************************************************/
CREATE FUNCTION [dbo].[fnOPER_RDI_CalculerMontantAssigneDepot]
(
   @iID_RDI_Depot INT
  ,@dtDate        DATETIME
)
RETURNS MONEY
AS
BEGIN
   DECLARE
      @iID_RDI_Paiement     INT
     ,@mMontantAssigne      MONEY
     ,@mMontantAssigneTotal MONEY

   SET @mMontantAssigneTotal = 0
   SET @mMontantAssigne = 0

   IF @dtDate IS NULL
      SET @dtDate = getDate()

   -----------------------------------------------------------------------------------------------------
   -- Additionne tous les montants encaissés et associés au dépôt pour
   -- lesquels des opérations sur ses paiements (dans UniAccès) ont été effectuées.
   -- Totalise toutes les valeurs de retour du calcul par paiement.
   ----------------------------------------------------------------------------------------------------- 
   DECLARE curID_Paiement CURSOR FOR
      SELECT iID_RDI_Paiement
        FROM tblOPER_RDI_Paiements
       WHERE iID_RDI_Depot = @iID_RDI_Depot

      OPEN curID_Paiement
      FETCH NEXT FROM curID_Paiement INTO @iID_RDI_Paiement
      WHILE @@FETCH_STATUS = 0
      BEGIN
         SET @mMontantAssigne = [dbo].[fnOPER_RDI_CalculerMontantAssignePaiement](@iID_RDI_Paiement,@dtDate)
         SET @mMontantAssigneTotal = @mMontantAssigneTotal + @mMontantAssigne
         FETCH NEXT FROM curID_Paiement INTO @iID_RDI_Paiement
      END
      CLOSE curID_Paiement
      DEALLOCATE curID_Paiement 

   IF @mMontantAssigneTotal IS NULL
      SET @mMontantAssigneTotal = 0

   RETURN @mMontantAssigneTotal
END 
