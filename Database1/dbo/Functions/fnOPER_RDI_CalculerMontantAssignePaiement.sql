/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : fnOPER_RDI_CalculerMontantAssignePaiement
Nom du service  : Calculer le montant encaissé associé à un paiement.
But             : Calcule le montant assigné d'un paiement à une date.
                  Si la date est NULL, la date du jour est considérée.
Facette         : OPER

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -----------------------------------
                      @iID_RDI_Paiement          Identifiant unique d'un paiement
                      @dtDate                    Montant assigné en date du

Paramètres de sortie: Paramètre                  Description
                      -------------------------- -----------------------------------
                      @mMontantAssigne           Montant assigné associé au paiement

Exemple d’appel     : SELECT [dbo].[fnOPER_RDI_CalculerMontantAssignePaiement](43,NULL)

Historique des modifications:
        Date            Programmeur                         Description
        ------------    ---------------------------------- ---------------------------
        2010-01-27      Danielle Côté                       Création du service
        2016-05-16      Steeve Picard                       Optimisation en éliminant le cursor par une table dynamique
****************************************************************************************************/
CREATE FUNCTION [dbo].[fnOPER_RDI_CalculerMontantAssignePaiement]
(
   @iID_RDI_Paiement INT
  ,@dtDate           DATETIME
)
RETURNS MONEY
AS
BEGIN
   DECLARE
      @mMontant        MONEY
     ,@mMontantAssigne MONEY
     ,@iID_RDI_Oper    INT = 0

   SET @mMontantAssigne = 0
   SET @mMontant        = 0
   SET @dtDate          = [dbo].[fn_Mo_DateNoTime](@dtDate)

   IF @dtDate IS NULL
      SET @dtDate = getDate()

   DECLARE @TB_Total_OPER_RDI TABLE (OperID INT)

   -- Rechercher les opérations d'un paiement qui sont dans la table de liens
   INSERT INTO @TB_Total_OPER_RDI
   --DECLARE curTotal_OPER_RDI CURSOR FOR    
      SELECT L.OperID
        FROM tblOPER_RDI_Liens L
        JOIN Un_Oper P ON P.OperID = L.OperID
       WHERE [dbo].[fn_Mo_DateNoTime](P.OperDate) <= @dtDate
         AND L.iID_RDI_Paiement = @iID_RDI_Paiement

   --OPEN curTotal_OPER_RDI
   --FETCH NEXT FROM curTotal_OPER_RDI INTO @iID_RDI_Oper
   --WHILE @@FETCH_STATUS = 0
   WHILE EXISTS(SELECT TOP 1 * FROM @TB_Total_OPER_RDI WHERE OperID > @iID_RDI_Oper)
   BEGIN 
      SELECT @iID_RDI_Oper = Min(OperID)
      FROM @TB_Total_OPER_RDI 
      WHERE OperID > @iID_RDI_Oper
   
      SELECT @mMontant = [dbo].[fnOPER_RDI_CalculerMontantAssigne] (@iID_RDI_Oper)
      SET @mMontantAssigne = @mMontantAssigne + @mMontant

      --FETCH NEXT FROM curTotal_OPER_RDI INTO @iID_RDI_Oper
   END
   --CLOSE curTotal_OPER_RDI
   --DEALLOCATE curTotal_OPER_RDI

   IF @mMontantAssigne IS NULL
      SET @mMontantAssigne = 0

   RETURN @mMontantAssigne
END 
