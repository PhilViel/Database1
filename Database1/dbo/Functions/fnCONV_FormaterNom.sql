/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : fnCONV_FormaterNom
Nom du service  : Construire le format du nom du déposant.
But             : S'assuper qu'il n'y pas plus d'un espace entre le nom et le prénom
                  et enlever les espaces avant et après une chaîne de caractère
                  qui comprend un nom et un prénom.
Facette         : CONV

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -------------------------------------
                      @vcNomComplet              Chaîne de caractères qui contient un
                                                 nom et un prénom (avec ou sans virgule)

Paramètres de sortie: Paramètre                  Description
                      -------------------------- -------------------------------------
                      @vcResultat               Chaîne de caractères qui contient un nom
                                                complet format [nom prenom]

Exemple d’appel     : SELECT [dbo].[fnCONV_FormaterNom](' PRUD''HOMME ?&Céline-Lise   ')
                      Retourne 'CÔTÉ Céline-Lise'
Historique des modifications:
        Date            Programmeur                        Description
        ------------    ---------------------------------- ---------------------------
        2010-03-01      Danielle Côté                      Création du service

****************************************************************************************************/
CREATE FUNCTION [dbo].[fnCONV_FormaterNom]
(
   @vcNomComplet VARCHAR(35)
)
RETURNS VARCHAR(50)
AS
BEGIN

   -- Enlever les espaces avant et après la chaîne
   SET @vcNomComplet = LTRIM(RTRIM(@vcNomComplet))

   DECLARE
      @vcChaine                 VARCHAR(50)
     ,@vcCaracteres_Admissibles VARCHAR(200)
     ,@iCompteur                INT
     ,@vcCaractere_Espace       VARCHAR(1)
     ,@iPos_Caractere           INT
     ,@vcResultat               VARCHAR(50)

   -----------------------------------------------------------------------
   -- On s'assure que la chaîne ne contient que des caractères admissibles
   -----------------------------------------------------------------------
   SET @vcCaracteres_Admissibles = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz' +
                                   'ÇçÀàÂâÄäÉéÈèÊêËëÌìÎîÏïíÒòÔôÖöóÙùÛûÜüúYyŸÿÑñ' +
                                   CHAR(32) + -- Espace
                                   CHAR(39) + -- Apostrophe
                                   CHAR(45) -- Trait d'union
   SET @iCompteur = 1
   SET @vcChaine  = ''

   WHILE @iCompteur <= LEN(@vcNomComplet)
   BEGIN
      IF CHARINDEX(SUBSTRING(@vcNomComplet,@iCompteur,1),@vcCaracteres_Admissibles) > 0
      BEGIN
         SET @vcChaine = @vcChaine + SUBSTRING(@vcNomComplet,@iCompteur,1)
      END
      SET @iCompteur = @iCompteur + 1
   END

   -----------------------------------------------------------------------
   -- Lorsque la chaîne ne contient que des caractère admissibles, on 
   -- enlève les espaces en trop, cad tous les espaces sauf celui qui 
   -- sépare le nom et le prénom s'il est présent dans la chaîne reçue en 
   -- paramètre.
   -----------------------------------------------------------------------
   SET @iCompteur          = 1
   SET @vcResultat         = ''
   SET @vcCaractere_Espace = CHAR(32)
   SET @iPos_Caractere     = 0

   --Trouver la première occurence "Espace"
   SET @iPos_Caractere = CHARINDEX(@vcCaractere_Espace,@vcChaine)
   SET @iCompteur = @iPos_Caractere + 1

   WHILE @iCompteur <= LEN(@vcChaine)
   BEGIN
      -- S'il n'a pas trouvé le caractère "Espace", mais un caractère valides
      IF CHARINDEX(SUBSTRING(@vcChaine,@iCompteur,1),@vcCaractere_Espace) = 0
      BEGIN
         SET @vcResultat = @vcResultat + SUBSTRING(@vcChaine,@iCompteur,1)
      END
      SET @iCompteur = @iCompteur + 1
   END
   SET @vcResultat = SUBSTRING(@vcChaine,1,@iPos_Caractere) + @vcResultat  

   RETURN @vcResultat

END

