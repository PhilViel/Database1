/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service     : psOPER_RDI_ObtenirDonneeOperation
Nom du service      : Obtenir les données d'une opération liée à un paiement
But                 : Obtenir le détail des opérations sur un paiement
Facette             : OPER

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -----------------------------------
                      @iID_RDI_Paiement          Identifiant unique du paiement

Paramètres de sortie: 
Paramètre(s)      Champ(s)                                              Description
----------------- ----------------------------------------------------- ----------------------------
DateOperation     fntOPER_RDI_ObtenirDonneeOperation.dtDate_UnOper      Date de l'opération liée
Montant           fntOPER_RDI_ObtenirDonneeOperation.mMontant           Montant de l'opération liée
Convention        fntOPER_RDI_ObtenirDonneeOperation.vcNo_UnConvention  Numéro de la convention de l'opération

Exemple d’appel     : EXECUTE [dbo].[psOPER_RDI_ObtenirDonneeOperation] 255

Historique des modifications:
        Date            Programmeur                         Description
        ------------    ---------------------------------- ---------------------------
        2010-03-24      Danielle Côté                       Création du service

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_RDI_ObtenirDonneeOperation] 
(
   @iID_RDI_Paiement INT
)
AS
BEGIN

   SELECT REPLACE(CONVERT(VARCHAR(10), dtDate_UnOper, 102),'.','-') AS DateOperation
         ,mMontant AS Montant 
         ,vcNo_UnConvention AS Convention
     FROM [dbo].[fntOPER_RDI_ObtenirDonneeOperation](@iID_RDI_Paiement)

END 
