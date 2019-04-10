/****************************************************************************************************
Copyrights (c) 2012 Gestion Universitas inc.

Code du service : fnGENE_RetirerCaracteresNonAffichable
Nom du service  : Retire les caractères non-affichable d'une chaîne
But             : Retire les caractères non-affichable d'une chaîne
                 
Facette         : GENE

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -------------------------------------
                      @vcTexte                   Chaîne de caractères 

Paramètres de sortie: Paramètre                  Description
                      -------------------------- -------------------------------------
                      @vcResultat                Chaîne de caractères sans les caractères inadmissibles

Exemple d’appel     : SELECT dbo.fnGENE_RetirerCaracteresNonAffichable('coxyizy@hotmail.com') -- Caractère invisible CHR(31) après le y
					  Résultat: coxyizy@hotmail.com
					  	
Historique des modifications:
        Date            Programmeur                        Description
        ------------    ---------------------------------- ---------------------------
        2012-12-12      Pierre-Luc Simard                  Création du service

****************************************************************************************************/
CREATE FUNCTION [dbo].[fnGENE_RetirerCaracteresNonAffichable]
(
   @vcTexte VARCHAR(8000)
)
RETURNS VARCHAR(8000)
AS
BEGIN
DECLARE 
	@Position SMALLINT, 
 	@cCaracteres CHAR(37)

SET @vcTexte = LTRIM(RTRIM(@vcTexte))
 	
SELECT @cCaracteres = 
			'%['
			+ CHAR(0)+CHAR(1)+CHAR(2)+CHAR(3)+CHAR(4)
			+ CHAR(5)+CHAR(6)+CHAR(7)+CHAR(8)+CHAR(9)
			+ CHAR(10)+CHAR(11)+CHAR(12)+CHAR(13)+CHAR(14)
			+ CHAR(15)+CHAR(16)+CHAR(17)+CHAR(18)+CHAR(19)
			+ CHAR(20)+CHAR(21)+CHAR(22)+CHAR(23)+CHAR(24)
			+ CHAR(25)+CHAR(26)+CHAR(27)+CHAR(28)+CHAR(29)
			+ CHAR(30)+CHAR(31)+CHAR(127)
			+ ']%',
        @Position = PATINDEX(@cCaracteres, @vcTexte)

WHILE @Position > 0
	SELECT 
		@vcTexte = STUFF(@vcTexte, @Position, 1, ''),
		@Position = PATINDEX(@cCaracteres, @vcTexte)
		
RETURN @vcTexte
END



