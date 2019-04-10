/****************************************************************************************************
Copyrights (c) 2012 Gestion Universitas inc.

Code du service : fnGENE_AfficherCaracteresNonAffichable
Nom du service  : Affiche les caractères non-affichable d'une chaîne
But             : Affiche les caractères non-affichable d'une chaîne
                 
Facette         : GENE

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -------------------------------------
                      @vcTexte                   Chaîne de caractères 

Paramètres de sortie: Paramètre                  Description
                      -------------------------- -------------------------------------
                      @vcResultat                Chaîne de caractères avec les caractères inadmissibles

Exemple d’appel     : SELECT dbo.fnGENE_AfficherCaracteresNonAffichable('coxyizy@hotmail.com') -- Caractère invisible CHR(31) après coxy
					  Résultat: coxy CHR(31) izy@hotmail.com
					  	
Historique des modifications:
        Date            Programmeur                        Description
        ------------    ---------------------------------- ---------------------------
        2012-12-12      Pierre-Luc Simard                  Création du service

****************************************************************************************************/
CREATE FUNCTION [dbo].[fnGENE_AfficherCaracteresNonAffichable]
(
   @vcTexte VARCHAR(8000)
)
RETURNS VARCHAR(8000)
AS
BEGIN
DECLARE 
	@Position SMALLINT, 
 	@cCaracteres CHAR(37),
 	@vcResultat VARCHAR(8000),
 	@iCompteur INT

SET @iCompteur = 1
SET @vcResultat = ''
  
WHILE @iCompteur <= LEN(@vcTexte)
	BEGIN
		IF ASCII(SUBSTRING(@vcTexte,@iCompteur,1)) BETWEEN 0 AND 31 OR ASCII(SUBSTRING(@vcTexte,@iCompteur,1)) = 127
			BEGIN
				SET @vcResultat = @vcResultat + ' CHR(' + CAST(ASCII(SUBSTRING(@vcTexte,@iCompteur,1)) AS VARCHAR(3)) + ') '
			END
		ELSE
			BEGIN
				SET @vcResultat = @vcResultat + SUBSTRING(@vcTexte,@iCompteur,1)
			END
      SET @iCompteur = @iCompteur + 1
   END 
	
RETURN @vcResultat
END
