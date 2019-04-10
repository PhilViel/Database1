/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : psOPER_RDI_CalculerMontantAAssigner
Nom du service  : Calculer le montant à assigner à une date
But             : Connaître le montant en suspens à une date donnée.
                  Le montant en suspens correspond à l'opération "souscripteur à payer"
                  Si la date est NULL, la date du jour est considérée.

Facette         : OPER

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -----------------------------------
                      @dtDate                    Montant assigné en date du

Paramètres de sortie: Paramètre                  Description
                      -------------------------- -----------------------------------
                      mMontantAAssignerTotal    Montant

Exemple d’appel     : 
exec psOPER_RDI_CalculerMontantAAssigner '2010-07-26'

Historique des modifications:
        Date            Programmeur                         Description
        ------------    ---------------------------------- ---------------------------
        2010-05-20      Danielle Côté                       Création du service
        2010-07-26      Donald Huppé                        Modification de la fonction en SP, pour utilisation dans SSRS
        2010-10-13      Danielle Côté                       Correction de la variable @mMontantDepot de type INT à MONEY
        2010-10-13      Danielle Côté                       Ajout d'une date maximale dans la sélection des dépôts
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_RDI_CalculerMontantAAssigner]
(
   @dtDate DATETIME
)
AS
BEGIN
   DECLARE
      @iID_RDI_Depot          INT
     ,@mMontantDepot          MONEY
     ,@mMontantAAssigner      MONEY
     ,@mMontantAAssignerTotal MONEY

   SET @mMontantAAssigner = 0
   SET @mMontantAAssignerTotal = 0

   IF @dtDate IS NULL
      SET @dtDate = [dbo].[fn_Mo_DateNoTime](getDate())
   ELSE
      SET @dtDate = [dbo].[fn_Mo_DateNoTime](@dtDate)

   -----------------------------------------------------------------------------------------------------
   -- Recherche tous les dépôts qui ont un montant à assigner plus grand que zéro.
   -- Additionne tous les montants à assigner.
   -----------------------------------------------------------------------------------------------------
   DECLARE curID_Depot CURSOR FOR
      SELECT D.iID_RDI_Depot
            ,D.mMontant_Depot
        FROM tblOPER_RDI_Depots D
        JOIN tblOPER_EDI_Fichiers F ON F.iID_EDI_Fichier = D.iID_EDI_Fichier
       WHERE [dbo].[fnOPER_RDI_CalculerMontantAssigneDepot](D.iID_RDI_Depot,@dtDate) < D.mMontant_Depot
         AND [dbo].[fn_Mo_DateNoTime](F.dtDate_Creation) <= @dtDate
       ORDER BY D.iID_RDI_Depot     

   OPEN curID_Depot
   FETCH NEXT FROM curID_Depot INTO @iID_RDI_Depot, @mMontantDepot
   WHILE @@FETCH_STATUS = 0
   BEGIN
      SET @mMontantAAssigner = @mMontantDepot - [dbo].[fnOPER_RDI_CalculerMontantAssigneDepot](@iID_RDI_Depot,@dtDate)
      SET @mMontantAAssignerTotal = @mMontantAAssignerTotal + @mMontantAAssigner
      FETCH NEXT FROM curID_Depot INTO @iID_RDI_Depot, @mMontantDepot
   END
   CLOSE curID_Depot
   DEALLOCATE curID_Depot

   IF @mMontantAAssignerTotal IS NULL
      SET @mMontantAAssignerTotal = 0

   SELECT mMontantAAssignerTotal = @mMontantAAssignerTotal
END 
