/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : fntOPER_RDI_ObtenirDonneeOperation
Nom du service  : Structurer les données d'une opération liée à un paiement
But             : Pour un paiement, identifier la date et le numéro de
                  convention pour chaque opération liée.
Facette         : OPER

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -----------------------------------
                      iID_RDI_Paiement           Identifiant unique d'un paiement

Paramètres de sortie: @tblOPER_Resultats
Paramètre(s)            Champ(s)                                         Description
----------------------- ------------------------------------------------ ----------------------------
iID_UnOper              Un_Oper.OperID                                   Identifiant unique d'une opération
dtDate_UnOper           Un_Oper.OperDate                                 Date de l'opération
mMontant                [dbo].[fnOPER_RDI_CalculerMontantAssigne]        Somme
vcNo_UnConvention       Un_Convention.ConventionNo                       Numéro de convention

Exemple d’appel     : SELECT * FROM [dbo].[fntOPER_RDI_ObtenirDonneeOperation](235)

Historique des modifications:
               Date          Programmeur        Description
               ------------  ------------------ ---------------------------
               2010-03-20    Danielle Côté      Création
               2010-12-12    Danielle Côté      Correction requête croisée
****************************************************************************************************/
CREATE FUNCTION [dbo].[fntOPER_RDI_ObtenirDonneeOperation]
(
   @iID_RDI_Paiement INT
) 
RETURNS @tblOPER_Resultats
        TABLE
        (iID_UnOper        INT
        ,dtDate_UnOper     DATETIME
        ,mMontant          MONEY
        ,vcNo_UnConvention VARCHAR(15))
BEGIN

   INSERT INTO @tblOPER_Resultats
        SELECT OP.OperID
              ,OP.OperDate
              ,ISNULL(SUM(V.total),0)
              ,CV.ConventionNo
          FROM tblOPER_RDI_Liens RDI
          JOIN Un_Oper OP ON OP.OperID = RDI.OperID
          JOIN (SELECT C.OperID
                      ,U.ConventionID
                      ,(ISNULL(SUM(C.Cotisation),0) + 
                        ISNULL(SUM(C.Fee),0) + 
                        ISNULL(SUM(C.BenefInsur),0) + 
                        ISNULL(SUM(C.SubscInsur),0) + 
                        ISNULL(SUM(C.TaxOnInsur),0)) AS total          
                  FROM Un_Cotisation C
                  JOIN dbo.Un_Unit U ON U.UnitID = C.UnitID
                 GROUP BY C.OperID, U.ConventionID
                -----
                UNION
                -----
                SELECT C.OperID
                      ,C.ConventionID
                      ,(ISNULL(SUM(C.ConventionOperAmount),0)) AS total
                  FROM Un_ConventionOper C
                 WHERE C.ConventionOperTypeID = 'INC'
                 GROUP BY C.OperID, C.ConventionID) V ON V.OperID = RDI.OperID
          JOIN dbo.Un_Convention CV ON CV.ConventionID = V.ConventionID
         WHERE RDI.iID_RDI_Paiement = @iID_RDI_Paiement
         GROUP BY CV.ConventionNo 
              ,OP.OperID
              ,OP.OperDate

  RETURN

END 


