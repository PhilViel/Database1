/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fnGENE_ObtenirTelephonePrincipal
Nom du service		: Obtenir le téléphone principal
But 				: Obtenir le téléphone principal d’une personne ou d’une compagnie.
Facette				: GENE
Référence			: UniAccès-Noyau-GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				vcTelephone1				Numéro de téléphone 1 (résidence)
		  				vcCellulaire				Numéro de téléphone cellulaire
		  				vcTelephone2				Numéro de téléphone 2 (bureau)
		  				vcSans_Frais				Numéro de téléphone sans frais
		  				vcAutre						Autre numéro de téléphone
						vcPagette					Numéro de pagette

Exemple d’appel		:	exec [dbo].fnGENE_ObtenirTelephonePrincipal '8192982233','','','','',''

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							vcTelephonePrincipal			Numéro de téléphone principal.

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2008-05-27		Éric Deshaies						Création du service							

****************************************************************************************************/
CREATE FUNCTION [dbo].[fnGENE_ObtenirTelephonePrincipal]
(
	@vcTelephone1 VARCHAR(27),
	@vcCellulaire VARCHAR(27),
	@vcTelephone2 VARCHAR(27),
	@vcSans_Frais VARCHAR(27),
	@vcAutre VARCHAR(27),
	@vcPagette VARCHAR(27)
)
RETURNS VARCHAR(27)
AS
BEGIN
	DECLARE
		@vcTelephoneTempo VARCHAR(27)

	-- Retourner le téléphone 1 comme principale s'il est présent
	SET @vcTelephoneTempo = LTRIM(RTRIM(@vcTelephone1))
	IF @vcTelephoneTempo IS NOT NULL AND LTRIM(RTRIM(@vcTelephoneTempo)) <> ''
		RETURN @vcTelephoneTempo

	-- Retourner le téléphone cellulaire comme principale s'il est présent
	SET @vcTelephoneTempo = LTRIM(RTRIM(@vcCellulaire))
	IF @vcTelephoneTempo IS NOT NULL AND LTRIM(RTRIM(@vcTelephoneTempo)) <> ''
		RETURN @vcTelephoneTempo

	-- Retourner le téléphone 2 comme principale s'il est présent
	SET @vcTelephoneTempo = LTRIM(RTRIM(@vcTelephone2))
	IF @vcTelephoneTempo IS NOT NULL AND LTRIM(RTRIM(@vcTelephoneTempo)) <> ''
		RETURN @vcTelephoneTempo

	-- Retourner le téléphone sans frais comme principale s'il est présent
	SET @vcTelephoneTempo = LTRIM(RTRIM(@vcSans_Frais))
	IF @vcTelephoneTempo IS NOT NULL AND LTRIM(RTRIM(@vcTelephoneTempo)) <> ''
		RETURN @vcTelephoneTempo

	-- Retourner l'autre téléphone comme principale s'il est présent
	SET @vcTelephoneTempo = LTRIM(RTRIM(@vcAutre))
	IF @vcTelephoneTempo IS NOT NULL AND LTRIM(RTRIM(@vcTelephoneTempo)) <> ''
		RETURN @vcTelephoneTempo

	-- Retourner la pagette comme principale s'il est présent
	SET @vcTelephoneTempo = LTRIM(RTRIM(@vcPagette))
	IF @vcTelephoneTempo IS NOT NULL AND LTRIM(RTRIM(@vcTelephoneTempo)) <> ''
		RETURN @vcTelephoneTempo
	
	-- Retourner null s'il n'y aucun téléphone
	RETURN NULL
END

