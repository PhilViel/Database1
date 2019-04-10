/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fnCONV_ObtenirEntreeVigueurObligationLegale
Nom du service		: Obtenir la date d'entrée en vigueur de l'obligation légale
But 				: Obtenir la date d'entrée en vigueur de l'obligation légale du souscripteur d'une convention.  Elle
					  débute généralement à la signature du contrat sauf si le contrat a été signé avant la naissance
					  du bénéficiaire originale (initial).  Cette date est utilisé pour les façades (convention de bourse)
					  remises à l'émission du contrat et est affichée à l'interface d'UniAccès.
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						iID_Convention				Identifiant unique de la convention pour laquelle la date est désiré

Exemple d’appel		:	SELECT [dbo].[fnCONV_ObtenirEntreeVigueurObligationLegale](300000)

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							dtDate_Entree_Vigueur			Si le service se réalise avec succès,
																					c’est la date d'entrée en vigueur de
																					la convention.

Historique des modifications:
		Date				Programmeur							Description									Référence
		------------		------------------------------	-----------------------------------------	------------
		2012-02-14	Éric Deshaies						Création du service		
		2014-09-29	Pierre-Luc Simard				Utiliser la date de signature du premier groupe d'unité et non la plus petite des groupes d'unités 	

*********************************************************************************************************************/
CREATE FUNCTION [dbo].[fnCONV_ObtenirEntreeVigueurObligationLegale]
(
	@iID_Convention	INT
)
RETURNS DATETIME
AS
BEGIN
	-- Valider les paramètres
	IF @iID_Convention IS NULL OR
	   NOT EXISTS(SELECT *
				  FROM dbo.Un_Convention 
				  WHERE ConventionID = @iID_Convention)
		RETURN NULL
	
	-- Déterminer la date de signature de la convention (plus petite des groupes d'unités)
	DECLARE @dtDate_Entree_Vigueur DATETIME,
			@dtDate_Naissance_Beneficiaire_Originale DATETIME
	
	SELECT @dtDate_Entree_Vigueur = U.SignatureDate
	FROM (
		SELECT 
			U.ConventionID,
			Min_UnitID = MIN(U.UnitID)
		FROM dbo.Un_Unit U
		WHERE U.ConventionID = @iID_Convention
			AND U.SignatureDate IS NOT NULL
		GROUP BY	
			U.ConventionID
		) Min_U
	JOIN dbo.Un_Unit U ON U.UnitID = Min_U.Min_UnitID

	-- Déterminer la date de naissance du bénéficiaire originale
	SELECT @dtDate_Naissance_Beneficiaire_Originale = H.BirthDate
	FROM [dbo].[fntCONV_RechercherChangementsBeneficiaire](NULL, NULL, @iID_Convention, NULL, NULL, NULL, NULL, 'INI', NULL, NULL, NULL, NULL, NULL) CB
	JOIN dbo.Mo_Human H ON H.HumanID = CB.iID_Nouveau_Beneficiaire

	-- Prendre la date la plus récente
	IF @dtDate_Naissance_Beneficiaire_Originale IS NOT NULL AND
	   @dtDate_Naissance_Beneficiaire_Originale > @dtDate_Entree_Vigueur
		SET @dtDate_Entree_Vigueur = @dtDate_Naissance_Beneficiaire_Originale

	-- Retourner la date de début de régime
	RETURN @dtDate_Entree_Vigueur
END


