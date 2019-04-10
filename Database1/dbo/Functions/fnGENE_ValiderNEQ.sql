/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fnGENE_ValiderNEQ
Nom du service		: Valider un numéro d’entreprise du Québec 
But 				: Déterminer si un NEQ est valide.
Facette				: GENE
Référence			: UniAccès-Noyau-GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				vcNEQ						NEQ à valider

Exemple d’appel		:	exec [dbo].fnGENE_ValiderNEQ '1234567890'

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							bNEQValide						« 0 » = NEQ non valide,
																					« 1 » = NEQ valide

Historique des modifications :
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2008-05-27		Éric Deshaies						Création du service							

****************************************************************************************************/
CREATE FUNCTION [dbo].[fnGENE_ValiderNEQ]
(
	@vcNEQ varchar(75)
)
RETURNS Bit
AS
BEGIN
	-- NULL est nécessairement invalide
	IF @vcNEQ IS NULL
		RETURN 0

	DECLARE
		@vcNEQTempo varchar(75)

	-- Retirer les espaces à droite
	SET @vcNEQTempo = RTRIM(@vcNEQ)

	-- NEQ invalide si pas 10 caractères
	IF LEN(@vcNEQTempo) <> 10
		RETURN 0

	-- NEQ invalide si pas dans le format "9999999999"
	IF NOT SUBSTRING(@vcNEQTempo,1,1) BETWEEN '0' AND '9' OR
	   NOT SUBSTRING(@vcNEQTempo,2,1) BETWEEN '0' AND '9' OR
	   NOT SUBSTRING(@vcNEQTempo,3,1) BETWEEN '0' AND '9' OR
	   NOT SUBSTRING(@vcNEQTempo,4,1) BETWEEN '0' AND '9' OR
	   NOT SUBSTRING(@vcNEQTempo,5,1) BETWEEN '0' AND '9' OR
	   NOT SUBSTRING(@vcNEQTempo,6,1) BETWEEN '0' AND '9' OR
	   NOT SUBSTRING(@vcNEQTempo,7,1) BETWEEN '0' AND '9' OR
	   NOT SUBSTRING(@vcNEQTempo,8,1) BETWEEN '0' AND '9' OR
	   NOT SUBSTRING(@vcNEQTempo,9,1) BETWEEN '0' AND '9' OR
	   NOT SUBSTRING(@vcNEQTempo,10,1) BETWEEN '0' AND '9'
		RETURN 0
	
	-- NEQ valide
	RETURN 1
END

