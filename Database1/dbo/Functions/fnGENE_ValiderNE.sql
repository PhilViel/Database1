/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fnGENE_ValiderNE
Nom du service		: Valider un numéro d’entreprise du Canada
But 				: Déterminer si un NE est valide.
Facette				: GENE
Référence			: UniAccès-Noyau-GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				vcNE						NE à valider

Exemple d’appel		:	exec [dbo].fnGENE_ValiderNE ''

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							bNEValide						« 0 » = NE non valide,
																							« 1 » = NE valide

Historique des modifications :
		Date				Programmeur							Description									Référence
		------------		----------------------------------	-----------------------------------------	------------
		2014-11-06	Pierre-Luc Simard					Création du service							

****************************************************************************************************/
CREATE FUNCTION [dbo].[fnGENE_ValiderNE]
(
	@vcNE varchar(75)
)
RETURNS Bit
AS
BEGIN
	-- NULL est nécessairement invalide
	IF @vcNE IS NULL
		RETURN 0

	DECLARE
		@vcNETempo varchar(75)

	-- Retirer les espaces à droite
	SET @vcNETempo = RTRIM(@vcNE)

	-- NE invalide si pas 15 caractères
	IF LEN(@vcNETempo) <> 15
		RETURN 0

	-- NE invalide si pas dans le format "999999999AA9999"
	IF NOT SUBSTRING(@vcNETempo,1,1) BETWEEN '0' AND '9' OR
	   NOT SUBSTRING(@vcNETempo,2,1) BETWEEN '0' AND '9' OR
	   NOT SUBSTRING(@vcNETempo,3,1) BETWEEN '0' AND '9' OR
	   NOT SUBSTRING(@vcNETempo,4,1) BETWEEN '0' AND '9' OR
	   NOT SUBSTRING(@vcNETempo,5,1) BETWEEN '0' AND '9' OR
	   NOT SUBSTRING(@vcNETempo,6,1) BETWEEN '0' AND '9' OR
	   NOT SUBSTRING(@vcNETempo,7,1) BETWEEN '0' AND '9' OR
	   NOT SUBSTRING(@vcNETempo,8,1) BETWEEN '0' AND '9' OR
	   NOT SUBSTRING(@vcNETempo,9,1) BETWEEN '0' AND '9' OR
	   NOT SUBSTRING(@vcNETempo,10,1) BETWEEN 'A' AND 'Z' OR
	   NOT SUBSTRING(@vcNETempo,11,1) BETWEEN 'A' AND 'Z' OR
	   NOT SUBSTRING(@vcNETempo,12,1) BETWEEN '0' AND '9' OR
	   NOT SUBSTRING(@vcNETempo,13,1) BETWEEN '0' AND '9' OR
	   NOT SUBSTRING(@vcNETempo,14,1) BETWEEN '0' AND '9' OR
	   NOT SUBSTRING(@vcNETempo,15,1) BETWEEN '0' AND '9' 
		RETURN 0
	
	-- NE valide
	RETURN 1
END

