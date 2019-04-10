/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : fnOPER_RDI_CalculerMontantAssigne
Nom du service  : Calculer le montant associé à une opération.
But             : Retourne le montant d'une opération lié à un paiement RDI.
                  L'opération doit contenir que des cotisations et/ou des intérêts.
Facette         : OPER

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -----------------------------------
                      @iID_UnOper                Identifiant unique d'une opération

Paramètres de sortie: Paramètre                  Description
                      -------------------------- -----------------------------------
                      @mMontantAssigne           Montant de l'opération

Exemple d’appel     : SELECT [dbo].[fnOPER_RDI_CalculerMontantAssigne](19524408)

Historique des modifications:
        Date            Programmeur                        Description
        ------------    ---------------------------------- ---------------------------
        2010-09-01      Danielle Côté                      Création du service
        2010-12-13      Danielle Côté                      Correction requête croisée
        2016-05-16      Steeve Picard                      Optimisation par réécriture du code
****************************************************************************************************/
CREATE FUNCTION [dbo].[fnOPER_RDI_CalculerMontantAssigne]
(
   @iID_UnOper INT
)
RETURNS MONEY
AS
BEGIN
   DECLARE  @mCotisation MONEY,
            @mConventionAmount MONEY

    SELECT @mCotisation = SUM(
                              ISNULL(C.Cotisation,0) + ISNULL(C.Fee,0) + 
                              ISNULL(C.BenefInsur,0) + ISNULL(C.SubscInsur,0) + ISNULL(C.TaxOnInsur,0)
                             )
    FROM Un_Cotisation C      
    WHERE C.OperID = @iID_UnOper

    SELECT @mConventionAmount = SUM(ISNULL(V.ConventionOperAmount,0))
    FROM Un_ConventionOPER V
    WHERE V.OperID = @iID_UnOper AND V.ConventionOperTypeID = 'INC'

    RETURN ISNULL(@mCotisation,0) + ISNULL(@mConventionAmount,0)

/*  2016-05-16
   DECLARE
     @mMontantAssigne MONEY

   SELECT @mMontantAssigne = R.somme
     FROM
  --Une opération est dans Un_Cotisation et/ou peut-être une autre est dans Un_ConventionOPER   
  (SELECT (ISNULL(unCotisation.total,0) + ISNULL(unConventionOper.total,0)) AS somme
     FROM Un_Oper unOper
    INNER JOIN 
         (SELECT C.OperID
                ,(ISNULL(SUM(C.Cotisation),0) + 
                  ISNULL(SUM(C.Fee),0) + 
                  ISNULL(SUM(C.BenefInsur),0) + 
                  ISNULL(SUM(C.SubscInsur),0) + 
                  ISNULL(SUM(C.TaxOnInsur),0)) AS total
            FROM Un_Cotisation C      
           GROUP BY C.OperID) unCotisation ON unCotisation.OperID = unOper.OperID
     LEFT JOIN
         (SELECT V.OperID
                ,(ISNULL(SUM(V.ConventionOperAmount),0)) AS total
            FROM Un_ConventionOPER V
           WHERE V.ConventionOperTypeID = 'INC'
           GROUP BY V.OperID) unConventionOper ON unConventionOper.OperID = unOper.OperID
    WHERE unOper.OperID = @iID_UnOper
    UNION
   --Une opération est dans Un_ConventionOPER et/ou peut-être une autre est dans Un_cotisation 
   SELECT (ISNULL(unCotisation.total,0) + ISNULL(unConventionOper.total,0)) AS somme
     FROM Un_Oper unOper
    INNER JOIN
         (SELECT V.OperID
                ,(ISNULL(SUM(V.ConventionOperAmount),0)) AS total
            FROM Un_ConventionOPER V
           WHERE V.ConventionOperTypeID = 'INC'
           GROUP BY V.OperID) unConventionOper ON unConventionOper.OperID = unOper.OperID           
     LEFT JOIN 
         (SELECT C.OperID
                ,(ISNULL(SUM(C.Cotisation),0) + 
                  ISNULL(SUM(C.Fee),0) + 
                  ISNULL(SUM(C.BenefInsur),0) + 
                  ISNULL(SUM(C.SubscInsur),0) + 
                  ISNULL(SUM(C.TaxOnInsur),0)) AS total
            FROM Un_Cotisation C      
           GROUP BY C.OperID) unCotisation ON unCotisation.OperID = unOper.OperID
    WHERE unOper.OperID = @iID_UnOper) R    

   IF @mMontantAssigne IS NULL
      SET @mMontantAssigne = 0

   RETURN @mMontantAssigne
*/
END 
          
