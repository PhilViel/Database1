/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fnGENE_ValiderCodePostal
Nom du service		: Valider un code postal 
But 				: Déterminer si un code postal est valide selon le pays du code postal.
Facette				: GENE
Référence			: UniAccès-Noyau-GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				vcCode_Postal				Code postal à valider
						cID_Pays					Identifiant unique du pays du code postal

Exemple d’appel		:	exec [dbo].[fnGENE_ValiderCodePostal] 'G1S 2P4', 'CAN'

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							bCodePostalValide				« 0 » = Code postal non valide,
																					« 1 » = Code postal valide

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2008-05-27		Éric Deshaies						Création du service							

****************************************************************************************************/
CREATE FUNCTION [dbo].[fnGENE_ValiderCodePostal]
(
	@vcCode_Postal varchar(10),
	@cID_Pays char(4)
)
RETURNS Bit
AS
BEGIN
	-- NULL est nécessairement invalide dans tous les pays
	IF @vcCode_Postal IS NULL
		RETURN 0

	DECLARE
		@vcCodeTempo varchar(10)

	-- Code postal du Canada
	IF @cID_Pays = 'CAN '
		BEGIN
			-- Retirer les espaces et mettre en majuscule
			SET @vcCodeTempo = UPPER(REPLACE(@vcCode_Postal,' ',''))

			-- Code postal invalide si pas 6 caractères
			IF LEN(@vcCodeTempo) <> 6
				RETURN 0

			-- Code postal invalide si pas dans le format "A9A9A9" sinon il est valide
			IF NOT SUBSTRING(@vcCodeTempo,1,1) BETWEEN 'A' AND 'Z' OR
			   NOT SUBSTRING(@vcCodeTempo,2,1) BETWEEN '0' AND '9' OR
			   NOT SUBSTRING(@vcCodeTempo,3,1) BETWEEN 'A' AND 'Z' OR
			   NOT SUBSTRING(@vcCodeTempo,4,1) BETWEEN '0' AND '9' OR
			   NOT SUBSTRING(@vcCodeTempo,5,1) BETWEEN 'A' AND 'Z' OR
			   NOT SUBSTRING(@vcCodeTempo,6,1) BETWEEN '0' AND '9'
				RETURN 0
			ELSE
				RETURN 1
		END
	
	-- Code postal valide si pays inconnu
	RETURN 1
END

