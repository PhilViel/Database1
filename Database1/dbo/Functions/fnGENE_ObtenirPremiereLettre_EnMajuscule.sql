/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : fnGENE_ObtenirPremiereLettre_EnMajuscule
Nom du service  : Obtenir la première lettre en majuscule
But             : Obtenir une chaîne de caractères dont tous les mots ont la première
                  lettre en majuscule.  Utile pour les noms propres.
Facette         : GENE

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -------------------------------------
                      @vcChaine                  Chaîne de caractères

Paramètres de sortie: Paramètre                  Description
                      -------------------------- -------------------------------------
                      @vcResultat                Chaîne de caractères

Exemple d’appel     : SELECT [dbo].[fnGENE_ObtenirPremiereLettre_EnMajuscule]('CeCI est un tESt')
                      Retourne 'Ceci Est Un Test'
                      SELECT [dbo].[fnGENE_ObtenirPremiereLettre_EnMajuscule]('EDMOND Gérard-tremblay')

Historique des modifications:
        Date            Programmeur                        Description
        ------------    ---------------------------------- ---------------------------
        2010-11-05      Danielle Côté                      Création du service

****************************************************************************************************/
CREATE FUNCTION [dbo].[fnGENE_ObtenirPremiereLettre_EnMajuscule]
(
   @vcChaine VARCHAR(100)
)
RETURNS VARCHAR(1000)
AS
BEGIN

   DECLARE
      @vcResultat  VARCHAR(1000)
     ,@iCompteur   INT
     ,@cLettre     CHAR(1)
     ,@bLettre     BIT

   SET @vcResultat = ''
   SET @iCompteur  = 1
   SET @cLettre = ''
   SET @bLettre = 0

   WHILE @iCompteur  <= LEN(@vcChaine)
   BEGIN 
      SET @cLettre = SUBSTRING(@vcChaine, @iCompteur , 1)
      IF @cLettre BETWEEN 'A' AND 'Z' COLLATE French_CI_AI
      BEGIN 
         IF @bLettre = 0 
            SET @vcResultat = @vcResultat + UPPER(@cLettre) 
         ELSE  
            SET @vcResultat = @vcResultat + LOWER(@cLettre) 
         SET @bLettre = 1 
      END 
      ELSE 
      BEGIN 
         SET @bLettre = 0 
         SET @vcResultat = @vcResultat + LOWER(@cLettre) 
      END 
      SET @iCompteur  = @iCompteur  + 1 
   END 
   RETURN @vcResultat

END 
