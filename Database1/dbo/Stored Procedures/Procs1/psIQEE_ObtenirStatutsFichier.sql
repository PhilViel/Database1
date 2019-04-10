/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psIQEE_ObtenirStatutsFichier
Nom du service		: Obtenir les statuts de fichier 
But 				: Obtenir les statuts possibles pour les fichiers de l’IQÉÉ selon la langue de l’utilisateur.
Facette				: IQÉÉ

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				cID_Langue					Identifiant unique de la langue de l’utilisateur selon « Mo_Lang ».
													Le français est la langue par défaut si elle n’est pas spécifiée.

Exemple d’appel		:	EXECUTE [dbo].[psIQEE_ObtenirStatutsFichier] 'FRA'

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						Tous les champs de la table « tblIQEE_StatutsFichier ».  Les statuts de fichier sont triés en
						 ordre de présentation.

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2008-10-26		Éric Deshaies						Création du service							
		2009-11-05		Éric Deshaies						Mise à niveau du service.
		2010-08-03		Éric Deshaies						Mise à niveau sur la traduction des champs

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_ObtenirStatutsFichier] 
(
	@cID_Langue CHAR(3)
)
AS
BEGIN
	-- Considérer le français comme la langue par défaut
	IF @cID_Langue IS NULL
		SET @cID_Langue = 'FRA'

	SET NOCOUNT ON;

	-- Retourner les statuts de fichier
	SELECT	SF.tiID_Statut_Fichier,
			SF.vcCode_Statut,
			ISNULL(T1.vcTraduction,SF.vcDescription) AS vcDescription,
			SF.tiID_Type_Fichier
	FROM tblIQEE_StatutsFichier SF
		 LEFT JOIN tblGENE_Traductions T1 ON T1.vcNom_Table = 'tblIQEE_StatutsFichier'
										 AND T1.vcNom_Champ = 'vcDescription'
										 AND T1.iID_Enregistrement = SF.tiID_Statut_Fichier
										 AND T1.vcID_Langue = @cID_Langue
	ORDER BY SF.tiOrdre_Presentation
END

