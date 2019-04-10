/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psIQEE_ObtenirCategoriesErreur
Nom du service		: Obtenir les catégories des erreurs 
But 				: Obtenir les catégories possibles pour les erreurs de l’IQÉÉ selon la langue de l’utilisateur.
Facette				: IQÉÉ

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				cID_Langue					Identifiant unique de la langue de l’utilisateur selon « Mo_Lang ».
													Le français est la langue par défaut si elle n’est pas spécifiée.
						bCategorie_Erreur_RQ		Indicateur si l’on retourne uniquement les catégories pour les
													erreurs provenant de RQ.  0 = Les catégories pour les rejets.
													1 = Les catégories pour les erreurs RQ.  Si pas spécifié, ce sont
													les catégories pour les erreurs RQ.

Exemple d’appel		:	EXECUTE [dbo].[psIQEE_ObtenirCategoriesErreur] 'FRA',NULL

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						Tous les champs de la table « tblIQEE_CategoriesErreur  ». Les catégories sont triées selon
						l’ordre de présentation.

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2008-09-29		Éric Deshaies						Création du service							
		2009-06-15		Éric Deshaies						Ajout d'un critère pour séparer les caté-
															gories des erreurs RQ des catégories des
															rejets.
		2009-11-05		Éric Deshaies						Mise à niveau du service.
		2010-08-03		Éric Deshaies						Mise à niveau sur la traduction des champs

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_ObtenirCategoriesErreur] 
(
	@cID_Langue CHAR(3),
	@bCategorie_Erreur_RQ BIT
)
AS
BEGIN
	-- Considérer le français comme la langue par défaut
	IF @cID_Langue IS NULL
		SET @cID_Langue = 'FRA'

	-- Considérer les catégories des erreurs RQ par défaut
	IF @bCategorie_Erreur_RQ IS NULL
		SET @bCategorie_Erreur_RQ = 1

	SET NOCOUNT ON;

	-- Retourner les catégories des erreurs
	SELECT CE.tiID_Categorie_Erreur,
		   CE.vcCode_Categorie,
		   ISNULL(T1.vcTraduction,CE.vcDescription) AS vcDescription,
		   CE.vcResponsable
	FROM tblIQEE_CategoriesErreur CE
		 LEFT JOIN tblGENE_Traductions T1 ON T1.vcNom_Table = 'tblIQEE_CategoriesErreur'
										 AND T1.vcNom_Champ = 'vcDescription'
										 AND T1.iID_Enregistrement = CE.tiID_Categorie_Erreur
										 AND T1.vcID_Langue = @cID_Langue
	WHERE CE.bCategorie_Erreur_RQ = @bCategorie_Erreur_RQ
	ORDER BY CE.tiOrdre_Presentation
END

