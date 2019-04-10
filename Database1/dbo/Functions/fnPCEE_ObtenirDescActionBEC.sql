
/****************************************************************************************************
Code de service		:		fnPCEE_ObtenirDescActionBEC
Nom du service		:		
But					:		Ce service est utilisé afin de récupérer l'identifiant unique de l'unité qui est rattachée au BEC
							Lors de la demande de BEC, une cotisation à zéro est créée et celle-ci est rattachée à une unité.
Facette				:		PCEE
Reférence			:		


Parametres d'entrée :	Parametres					Description									Obligatoire
                        ----------                  ----------------							--------------                       
						

Exemples d'appel:
				SELECT dbo.fnPCEE_ObtenirDescActionBEC(NULL, NULL)
				SELECT dbo.fnPCEE_ObtenirDescActionBEC(NULL, 'FRA')
				SELECT dbo.fnPCEE_ObtenirDescActionBEC(NULL, 'ENU')
				SELECT dbo.fnPCEE_ObtenirDescActionBEC('BEC001', 'FRA')
				SELECT dbo.fnPCEE_ObtenirDescActionBEC('BEC001', 'ENU')

Parametres de sortie :  Table						Champs										Description
					    -----------------			---------------------------					--------------------------

Historique des modifications :

						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2010-01-07					Jean-François Gauthier					Création de la fonction
						
 ****************************************************************************************************/

CREATE FUNCTION [dbo].[fnPCEE_ObtenirDescActionBEC]
	(
		@cActionBEC CHAR(6),
		@cLangue	CHAR(3)
	)
RETURNS VARCHAR(255)
AS
	BEGIN
		DECLARE @vcDescActionBEC VARCHAR(255)
	
		SET @cLangue = ISNULL(NULLIF(LTRIM(RTRIM(@cLangue)), ''), 'FRA')

		SELECT
			@vcDescActionBEC = CASE 
									WHEN  (@cLangue = 'FRA') OR (dbo.fnGENE_ObtenirParametre('TRADUCTION',NULL,'tblPCEE_ActionBEC','vcDescActionBEC', ISNULL(ab.vcDescActionBEC,''), @cLangue,NULL) = '-2')	 THEN ab.vcDescActionBEC
									ELSE	-- RECHERCHE DE LA TRADUCTION DANS L'AUTRE LANGUE, SI ELLE EST NON TROUVÉ, ON RETOURNE LA DESCRIPTION FRANÇAISE
										dbo.fnGENE_ObtenirParametre('TRADUCTION',NULL,'tblPCEE_ActionBEC','vcDescActionBEC', ISNULL(ab.vcDescActionBEC,''), @cLangue,NULL)
								END
		FROM
			dbo.tblPCEE_ActionBEC ab
		WHERE
			ab.cCodeActionBEC = @cActionBEC
			
		RETURN @vcDescActionBEC
	END
