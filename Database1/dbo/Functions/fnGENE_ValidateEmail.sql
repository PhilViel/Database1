/****************************************************************************************************
Copyrights (c) Calvin Lawson (on SQLServerCentral.com)

Code du service	: fnGENE_ValidateEmail
Nom du service		: Validation d'un courriel
But 				: Valide que le courriel ne contient pas de caractères inadmissibles.
                        
Facette		     : GENE

Paramètres d’entrée	:
        Paramètre                   Description
        ------------------------    ----------------------------------------------------------------
        @email                      Courriel à valider

Exemple d’appel     :   SELECT dbo.fnGENE_ValidateEmail('test@toto.com')
                        SELECT dbo.fnGENE_ValidateEmail('test@t@oto.com')

Paramètres de sortie:	Retourne 1 si le email est valide, sinon 0
        
Historique des modifications:
        Date        Programmeur                 Description
        ----------  ------------------------    -----------------------------------------------------
        2016-09-20  Steeve Picard               Création du service (https://en.wikipedia.org/wiki/Email_address)
        2016-11-10  Steeve Picard               Correction pour accepter le «-» soit accepté
****************************************************************************************************/
CREATE FUNCTION [dbo].[fnGENE_ValidateEmail] (
    @email varChar(255)
) RETURNS bit AS
begin
    return (
        select 
	        Case 
		        -- Check for null or empty
		        When @Email is null then 0				
		        -- Check for invalid character
		        When PatIndex('%[^A-Z,^0-9,^@^.^!^#^$^%^&^''^*^+^[-]^/^=^?^\^_^`^{^|^}^~]%', @email) <> 0 then 0
		        -- Check for '.' at begin or end of string
		        When Left(@Email, 1) = '.' OR RIGHT(@Email, 1) = '.' then 0
		        -- Check for '..' at begin or end of string
		        When @Email Like '%..%' then 0
		        -- Check for duplicate @
		        When @Email like '%@%@%' then 0
		        -- Check for invalid format
		        When @Email Not Like '%@%.%' then 0
		        Else 1
	        END
        )
end
