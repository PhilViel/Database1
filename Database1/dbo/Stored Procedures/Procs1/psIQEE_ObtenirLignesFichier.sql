/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psIQEE_ObtenirLignesFichier
Nom du service		: Obtenir les lignes d’un fichier
But 				: Obtenir l’ensemble des lignes d’un fichier de l’IQÉÉ.
Facette				: IQÉÉ

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				iID_Fichier_IQEE			Identifiant unique du fichier à sauvegarder.

Exemple d’appel		:	EXECUTE [dbo].[psIQEE_ObtenirLignesFichier] 1

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						tblIQEE_LignesFichier		cLigne							Ligne du fichier

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2008-06-02		Éric Deshaies						Création du service							
		2009-11-05		Éric Deshaies						Mise à niveau du service.

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_ObtenirLignesFichier] 
(
	@iID_Fichier_IQEE INT
)
AS
BEGIN
	-- Sélectionner le fichier 0 s'il n'est pas spécifié (retourne rien)
	IF @iID_Fichier_IQEE IS NULL
		SET @iID_Fichier_IQEE = 0

	SET NOCOUNT ON;

	-- Retourner les lignes du fichier spécifié en paramètre
	SELECT cLigne
	FROM tblIQEE_LignesFichier
	WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE
	ORDER BY iSequence
END

