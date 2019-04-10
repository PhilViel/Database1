/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : psOPER_EDI_ObtenirBanques
Nom du service  : Obtenir la liste des noms des banques.
But             : Obtenir la liste des noms des banques selon la langue de l'utilisateur.
Facette         : OPER

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -----------------------------------
                      cID_Langue                 Identifiant unique de la langue de 
                                                 l’utilisateur selon « Mo_Lang ».
                                                 Le français est la langue par défaut.

Paramètres de sortie: Table               Champ(s)               Description
                      ------------------- ---------------------- ---------------------------
                      tblOPER_EDI_Banques tiID_EDI_Banque        Identifiant unique d''une banque
                      tblOPER_EDI_Banques vcCode_Banque          Code unique de la banque
                      tblOPER_EDI_Banques vcDescription_Court    Description courte de la banque
                      Les noms des banques sont triés par ordre ALPHABÉTIQUE

Exemple d’appel     : EXECUTE [dbo].[psOPER_EDI_ObtenirBanques] 'FRA'

Historique des modifications:
        Date            Programmeur                         Description
        ------------    ---------------------------------- ---------------------------
        2010-01-25      Danielle Côté                       Création du service

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_EDI_ObtenirBanques] 
(
   @cID_Langue CHAR(3)
)
AS
BEGIN
   -- Considérer le français comme la langue par défaut
   IF @cID_Langue IS NULL
      SET @cID_Langue = 'FRA'

   SET NOCOUNT ON;

   -- Retourner les information sur les banques
   SELECT tiID_EDI_Banque
         ,vcCode_Banque
         ,CASE 
             ISNULL(dbo.fnGENE_ObtenirParametre('TRADUCTION',NULL,'tblOPER_EDI_Banques','vcDescription_Court',
                                                 tiID_EDI_Banque,@cID_Langue,NULL),'-2')
             WHEN '-2' THEN vcDescription_Court
             ELSE (dbo.fnGENE_ObtenirParametre('TRADUCTION',NULL,'tblOPER_EDI_Banques','vcDescription_Court',
                                                 tiID_EDI_Banque,@cID_Langue,NULL))
          END AS vcDescription_Court
     FROM tblOPER_EDI_Banques
    ORDER BY vcDescription_Court
END
