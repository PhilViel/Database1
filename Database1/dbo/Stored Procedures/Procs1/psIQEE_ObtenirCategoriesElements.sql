/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psIQEE_ObtenirCategoriesElements
Nom du service		: Obtenir les catégories d’éléments
But 				: Obtenir les catégories d’éléments validés des rejets de l’IQÉÉ selon la langue de l’utilisateur.
Facette				: IQÉÉ

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				cID_Langue					Identifiant unique de la langue de l’utilisateur selon « Mo_Lang ».
													Le français est la langue par défaut si elle n’est pas spécifiée.

Exemple d’appel		:	EXECUTE [dbo].[psIQEE_ObtenirCategoriesElements] 'FRA'

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						Tous les champs de la table « tblIQEE_CategoriesElements ».  Les catégories d’éléments sont
						triées en ordre alphabétique de la description.

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2009-06-25		Éric Deshaies						Création du service							
		2009-11-05		Éric Deshaies						Mise à niveau du service.
		2010-08-03		Éric Deshaies						Mise à niveau sur la traduction des champs

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_ObtenirCategoriesElements] 
(
	@cID_Langue CHAR(3)
)
AS
BEGIN
	-- Considérer le français comme la langue par défaut
	IF @cID_Langue IS NULL
		SET @cID_Langue = 'FRA'

	SET NOCOUNT ON;

	-- Retourner les catégories d'éléments
	SELECT CE.tiID_Categorie_Element,
		   CE.vcCode_Categorie,
		   ISNULL(T1.vcTraduction,CE.vcDescription) AS vcDescription
	FROM tblIQEE_CategoriesElements CE
		 LEFT JOIN tblGENE_Traductions T1 ON T1.vcNom_Table = 'tblIQEE_CategoriesElements'
										 AND T1.vcNom_Champ = 'vcDescription'
										 AND T1.iID_Enregistrement = CE.tiID_Categorie_Element
										 AND T1.vcID_Langue = @cID_Langue
	ORDER BY ISNULL(T1.vcTraduction,CE.vcDescription)
END

