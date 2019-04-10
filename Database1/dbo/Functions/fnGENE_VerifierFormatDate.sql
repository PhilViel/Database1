/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : fnGENE_VerifierFormatDate
Nom du service  : Vérifier le format de la date.
But             : Vérifier si une chaîne de caractères qui contiennent une date présente
                  les données sous le format AAAA-MM-JJ ou JJ-MM-AAAA.
Facette         : GENE

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -------------------------------------
                      @vcDate                    Chaîne de caractères qui contient une date

Paramètres de sortie: Paramètre                  Description
                      -------------------------- -------------------------------------
                      @vcDateFormat              Chaîne de caractères qui contient une date
                                                 avec le format AAAA-MM-JJ

Exemple d’appel     : SELECT [dbo].[fnGENE_VerifierFormatDate]('2010-01-01')
                      SELECT [dbo].[fnGENE_VerifierFormatDate]('01-01-2010')

Historique des modifications:
        Date            Programmeur                        Description
        ------------    ---------------------------------- ---------------------------
        2010-01-27      Danielle Côté                      Création du service

****************************************************************************************************/
CREATE FUNCTION [dbo].[fnGENE_VerifierFormatDate]
(
   @vcDate VARCHAR(10)
)
RETURNS VARCHAR(10)
AS
BEGIN

   DECLARE
      @vcDateFormat VARCHAR(10)
     ,@tiPos        TINYINT 

   -- Recherche la position de l'année de la décennie 2010
   SELECT @tiPos = CHARINDEX('201', @vcDate)
   IF @tiPos = 1
      SET @vcDateFormat = @vcDate

   IF @tiPos = 7
      SET @vcDateFormat = SUBSTRING(@vcDate,7,4) + '-' + 
                          SUBSTRING(@vcDate,4,3) + 
                          SUBSTRING(@vcDate,1,2)

   RETURN @vcDateFormat

END
   
