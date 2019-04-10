/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : psOPER_RDI_ObtenirStatutsDepot
Nom du service  : Obtenir la liste des statuts de dépôts.
But             : Obtenir la liste des statuts de dépôts selon la langue de l'utilisateur.
Facette         : OPER

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -----------------------------------
                      cID_Langue                 Identifiant unique de la langue de 
                                                 l’utilisateur selon « Mo_Lang ».
                                                 Le français est la langue par défaut.

Paramètres de sortie: Table                    Champ(s)               Description
                      ------------------------ ---------------------- ---------------------------
                      tblOPER_RDI_StatutsDepot tiID_RDI_Statut_Depot  Identifiant unique d''un statut
                      tblOPER_RDI_StatutsDepot vcCode_Statut          Code unique du statut
                      tblOPER_RDI_StatutsDepot vcDescription          Description du statut
                      Les noms des statuts sont triés par ordre ALPHABÉTIQUE

Exemple d’appel     : EXECUTE [dbo].[psOPER_RDI_ObtenirStatutsDepot] 'FRA'

Historique des modifications:
        Date            Programmeur                         Description
        ------------    ---------------------------------- ---------------------------
        2010-02-02      Danielle Côté                       Création du service

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_RDI_ObtenirStatutsDepot]
(
   @cID_Langue CHAR(3)
)
AS
BEGIN
   -- Considérer le français comme la langue par défaut
   IF @cID_Langue IS NULL
      SET @cID_Langue = 'FRA'

   SET NOCOUNT ON;

   -- Retourner les information sur les statuts de dépôts
   SELECT tiID_RDI_Statut_Depot
         ,vcCode_Statut
         ,CASE 
             ISNULL(dbo.fnGENE_ObtenirParametre('TRADUCTION',NULL,'tblOPER_RDI_StatutsDepot','vcDescription',
                                                 tiID_RDI_Statut_Depot,@cID_Langue,NULL),'-2')
             WHEN '-2' THEN vcDescription
             ELSE (dbo.fnGENE_ObtenirParametre('TRADUCTION',NULL,'tblOPER_RDI_StatutsDepot','vcDescription',
                                                tiID_RDI_Statut_Depot,@cID_Langue,NULL))
          END AS vcDescription
     FROM tblOPER_RDI_StatutsDepot
    ORDER BY vcDescription
END
