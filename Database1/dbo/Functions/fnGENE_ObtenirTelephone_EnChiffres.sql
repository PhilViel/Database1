/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : fnGENE_ObtenirTelephone_EnChiffres
Nom du service  : Obtenir le numéro de téléphone en chiffres
But             : Obtenir le numéro de téléphone en chiffres en retirant les caractères
                  non numérique et permettre de vérifier si le résultat retourné
                  est < 7 ou > 10. 
Facette         : GENE

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -------------------------------------
                      @vcTelephone               Chaîne de caractères
                      @bValidation               Bit

Paramètres de sortie: Paramètre                  Description
                      -------------------------- -------------------------------------
                      @vcResultat                Chaîne de caractères contenant que des chiffres

                                                 Si la valeur du paramètre d'entrée @vcTelephone retirée
                                                 de ces caractères non admissibles est < 7
                                                 ou > 10, retourne NULL si le paramètre d'entrée
                                                 @bValidation est à 1, pour des fins de rejet.
                                                 Si le paramètre d'entrée @bValidation est à 0,
                                                 retourne la chaîne de caractères contenant des chiffres
                                                 peu importe si le numéro de téléphone est complet.

Exemple d’appel     : SELECT [dbo].[fnGENE_ObtenirTelephone_EnChiffres]('(514)298-4878&',1)
                      Retourne '5142984878'
                      SELECT [dbo].[fnGENE_ObtenirTelephone_EnChiffres]('663-030*',1)
                      Retourne NULL

Historique des modifications:
        Date            Programmeur                        Description
        ------------    ---------------------------------- ---------------------------
        2010-10-26      Danielle Côté                      Création du service

****************************************************************************************************/
CREATE FUNCTION [dbo].[fnGENE_ObtenirTelephone_EnChiffres]
(
   @vcTelephone VARCHAR(35)
  ,@bValidation BIT = NULL
)
RETURNS VARCHAR(10)
AS
BEGIN

   DECLARE
      @noTEL                    VARCHAR(25)
     ,@vcCaracteres_Admissibles VARCHAR(200)
     ,@tiCompteur               TINYINT
     ,@vcResultat               VARCHAR(100)

   SELECT @noTEL = LTRIM(RTRIM(@vcTelephone))  
   SET @vcCaracteres_Admissibles = '0123456789'
   SET @tiCompteur = 1
   SET @vcResultat = ''

   -- S'assure que le contenu n'est que numérique
   IF ISNUMERIC(@noTEL) = 0
   BEGIN
      WHILE @tiCompteur <= LEN(@noTEL)
      BEGIN
         -- Retrait de la chaîne des caractères inadmissibles
         IF CHARINDEX(SUBSTRING(@noTEL,@tiCompteur,1),@vcCaracteres_Admissibles) > 0
         BEGIN
            SET @vcResultat = @vcResultat + SUBSTRING(@noTEL,@tiCompteur,1)
         END
         SET @tiCompteur = @tiCompteur + 1
      END
   END
   ELSE
   BEGIN
      SET @vcResultat = @noTEL
   END

   IF LEN(@vcResultat) = 0
      SET @vcResultat = NULL

   ------------------------------------------------------
   -- Si le paramètre d'entrée @bValidation = 1,
   -- valide si le résultat retirée de ces caractères
   -- non admissibles est >= 7 AND <= 10
   ------------------------------------------------------
   IF @bValidation = 1
   BEGIN
      IF LEN(@vcResultat) < 7 OR LEN(@vcResultat) > 10
      BEGIN
         SET @vcResultat = NULL
      END
   END

   RETURN @vcResultat

END 
