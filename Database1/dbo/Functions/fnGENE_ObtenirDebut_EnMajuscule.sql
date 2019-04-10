/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : fnGENE_ObtenirDebut_EnMajuscule
Nom du service  : Obtenir une chaîne avec la première lettre en majuscule
But             : Obtenir une chaîne de caractères avec la première lettre de la chaîne en majuscule
Facette         : GENE

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -------------------------------------
                      @vcChaine                  Chaîne de caractères

Paramètres de sortie: Paramètre                  Description
                      -------------------------- -------------------------------------
                      @vcResultat                Chaîne de caractères 

Exemple d’appel     :  
SELECT [dbo].[fnGENE_ObtenirDebut_EnMajuscule]('il était une fois une histoire vraie')

Historique des modifications:
        Date            Programmeur                        Description
        ------------    ---------------------------------- ---------------------------
        2010-11-28      Danielle Côté                      Création du service

****************************************************************************************************/
CREATE FUNCTION [dbo].[fnGENE_ObtenirDebut_EnMajuscule]
(  
   @vcChaine VARCHAR(500)
)
RETURNS VARCHAR(500)
AS
BEGIN

   DECLARE
      @vcResultat VARCHAR(500)

   IF LEN(@vcChaine) > 0
   BEGIN
      SET @vcResultat = UPPER(substring(@vcChaine,1,1)) + substring(@vcChaine,2,LEN(@vcChaine)-1)
   END
   ELSE
   BEGIN
      SET @vcResultat = ''
   END
   
   RETURN @vcResultat

END 
