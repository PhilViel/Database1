/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fnGENE_ObtenirTraduction
Nom du service		: Obtenir une traduction
But 				: Obtenir une traduction simple d'une description française de l'une des tables de la base de données.
Facette				: GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						vcNom_Table					Nom de la table de références contenant le champ à traduire.
						vcNom_Champ					Nom du champ de la table de référence qui doit être traduit.
						iID_Enregistrement			Identifiant unique numérique de l'enregistrement contenant le champ
													à traduire.  Les nouvelles tables utilisent nécessairement un
													identifiant unique.
						vcID_Enregistrement			Identifiant unique en format alpha numérique de l'enregistrement
													contenant le champ à traduire.  Ce champ est utilisé pour traduire
													les descriptions des anciennes tables où l'identifiant unique n'est
													pas numérique.
						vcID_Langue					Identifiant unique de la langue de traduction.

Exemple d’appel		:	SELECT [dbo].[fnGENE_ObtenirTraduction]('Un_ConventionState','ConventionStateName',NULL,'REE','ENU')

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						tblGENE_Traductions			vcTraduction					Texte de la traduction selon la
																					langue.

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2010-08-02		Éric Deshaies						Création du service							

****************************************************************************************************/
CREATE FUNCTION [dbo].[fnGENE_ObtenirTraduction]
(
	@vcNom_Table VARCHAR(150),
	@vcNom_Champ VARCHAR(150),
	@iID_Enregistrement	INT,
	@vcID_Enregistrement VARCHAR(15),
	@vcID_Langue VARCHAR(3)
)
RETURNS VARCHAR(8000)
AS
BEGIN
	DECLARE @vcTraduction VARCHAR(8000)

	-- Rechercher la traduction
	SELECT @vcTraduction = T.vcTraduction
	FROM tblGENE_Traductions T
	WHERE T.vcNom_Table = @vcNom_Table
	  AND T.vcNom_Champ = @vcNom_Champ
	  AND ISNULL(T.iID_Enregistrement,0) = ISNULL(@iID_Enregistrement,0)
	  AND ISNULL(T.vcID_Enregistrement,'') = ISNULL(@vcID_Enregistrement,'')
	  AND T.vcID_Langue = @vcID_Langue

	--  Retourner la valeur recherchée
	RETURN @vcTraduction
END

