/****************************************************************************************************
Copyrights (c) 2011 Gestion Universitas inc.

Code du service : fnOPER_EDI_ObtenirStatutFichier
Nom du service  : Obtenir le statut d'un fichier 
But             : Obtenir le statut d'un fichier à l'aide de l'identifiant unique
Facette         : OPER

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -----------------------------------
                      @iID_EDI_Fichier           Identifiant unique d'un fichier

Paramètres de sortie: Paramètre                  Description
                      -------------------------- -----------------------------------
                      @vcCode_Statut             VARCHAR(3)

Exemple d’appel     : SELECT [dbo].[fnOPER_EDI_ObtenirStatutFichier](106)

Historique des modifications:
        Date            Programmeur                         Description
        ------------    ---------------------------------- -------------------------
        2011-02-28      Danielle Côté                       Création du service

****************************************************************************************************/
CREATE FUNCTION [dbo].[fnOPER_EDI_ObtenirStatutFichier]
(
   @iID_EDI_Fichier INT
)
RETURNS VARCHAR(3)
AS
BEGIN
   DECLARE
      @vcCode_Statut VARCHAR(3)

      SELECT @vcCode_Statut = S.vcCode_Statut
        FROM tblOPER_EDI_Fichiers F
        JOIN tblOPER_EDI_StatutsFichier S ON S.tiID_EDI_Statut_Fichier = F.tiID_EDI_Statut_Fichier
       WHERE F.iID_EDI_Fichier = @iID_EDI_Fichier

   RETURN @vcCode_Statut
END 
