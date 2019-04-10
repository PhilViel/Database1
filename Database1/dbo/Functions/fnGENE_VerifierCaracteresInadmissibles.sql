/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : fnGENE_VerifierCaracteresInadmissibles
Nom du service  : fnGENE_VerifierCaracteresInadmissibles
But             : Vérifie si une chaîne contient des caractères inadmissibles 
                  
Facette         : GENE

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -------------------------------------
                      @vcTexte                   Chaîne de caractères 

Paramètres de sortie: Paramètre                  Description
                      -------------------------- -------------------------------------
                      @vcResultat                Chaîne de caractères sans les caractères inadmissibles

Exemple d’appel     : SELECT [dbo].[fnGENE_VerifierCaracteresInadmissibles](' ?&Céline-Lise   ')
                      Retourne 1

Historique des modifications:
        Date            Programmeur                        Description
        ------------    ---------------------------------- ---------------------------
        2015-10-08      Stéphane Barbeau					Création du service
		2015-10-22		Steeve Picard						Optimisation
**************************************************************************************/
CREATE FUNCTION [dbo].[fnGENE_VerifierCaracteresInadmissibles] (
   @vcTexte VARCHAR(100)
)
RETURNS INT AS
BEGIN
	DECLARE @Value VARCHAR(100) = LTrim(RTrim(dbo.fn_Mo_FormatStringWithoutAccent(IsNull(@vcTexte, ''))))

	IF PatIndex('%[^A-Z,^0-9,^&^/^''^ ^.^-]%', SubString(@Value,1,1)) <> 0
	--IF dbo.fnGENE_EvaluerRegEx('[^A-Z]', Upper(SubString(@Value,1,1)), 0) = 1
		Return 1

	IF PatIndex('%[^A-Z,^0-9,^&^/^''^ ^.^-]%', @Value) <> 0
	--IF dbo.fnGENE_EvaluerRegEx('[^/^''^a-z^&^A-Z^`^0-9^\s^\.^,^-]', @Value, 0) = 1
		Return 1
	
	Return 0
END
