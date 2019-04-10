/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : fnGENE_RetirerCaracteresInadmissibles
Nom du service  : Retire les caractères inadmissibles d'une chaîne
But             : Retire les caractères inadmissibles d'une chaîne
                  Utilitaire de gestion pour les mots qui proviennent de saisie de 
                  texte libre tel que le nom du déposant (RDI) et les formulaires du 
                  site Universitas.
Facette         : GENE

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -------------------------------------
                      @vcTexte                   Chaîne de caractères 

Paramètres de sortie: Paramètre                  Description
                      -------------------------- -------------------------------------
                      @vcResultat                Chaîne de caractères sans les caractères inadmissibles

Exemple d’appel     : SELECT [dbo].[fnGENE_RetirerCaracteresInadmissibles](' ?&Céline-Lise   ')
                      Retourne 'Céline-Lise'
                      SELECT [dbo].[fnGENE_RetirerCaracteresInadmissibles]('Danie)&%$lle')
                      Retourne 'Danielle'

Historique des modifications:
        Date            Programmeur                        Description
        ------------    ---------------------------------- ---------------------------
        2010-10-01      Danielle Côté                      Création du service

****************************************************************************************************/
CREATE FUNCTION [dbo].[fnGENE_RetirerCaracteresInadmissibles]
(
   @vcTexte VARCHAR(100)
)
RETURNS VARCHAR(100)
AS
BEGIN

   SET @vcTexte = LTRIM(RTRIM(@vcTexte))

   DECLARE
      @vcCaracteres_Admissibles VARCHAR(200)
     ,@iCompteur                INT
     ,@vcResultat               VARCHAR(100)

   SET @vcCaracteres_Admissibles = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz' +
                                   'ÇçÀàÂâÄäÉéÈèÊêËëÌìÎîÏïíÒòÔôÖöóÙùÛûÜüúYyŸÿÑñ' +
                                   CHAR(32) + -- Espace
                                   CHAR(39) + -- Apostrophe
                                   CHAR(45)   -- Trait d'union
   SET @iCompteur = 1
   SET @vcResultat = ''

   -----------------------------------------------------------------------
   -- Retrait de la chaîne des caractères inadmissibles
   -----------------------------------------------------------------------
   WHILE @iCompteur <= LEN(@vcTexte)
   BEGIN
      IF CHARINDEX(SUBSTRING(@vcTexte,@iCompteur,1),@vcCaracteres_Admissibles) > 0
      BEGIN
         SET @vcResultat = @vcResultat + SUBSTRING(@vcTexte,@iCompteur,1)
      END
      SET @iCompteur = @iCompteur + 1
   END 

   RETURN @vcResultat

END

