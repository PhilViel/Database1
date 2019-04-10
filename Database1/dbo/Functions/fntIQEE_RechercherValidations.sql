/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fntIQEE_RechercherValidations
Nom du service		: Rechercher les validations
But 				: Rechercher à travers les validations de l’IQÉÉ et obtenir les informations de celles-ci.
Facette				: IQÉÉ

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						cID_Langue					Identifiant unique de la langue de l’utilisateur selon « Mo_Lang ».
													Le français est la langue par défaut si elle n’est pas spécifiée.
						iID_Validation				Identifiant unique de la validation.  S’il est vide, toutes les
													validations sont considérées.
						tiID_Type_Enregistrement	Identifiant du type d’enregistrement relié à la validation.  S’il
													est vide, les validations de tous les types d’enregistrement sont
													considérées.
						iID_Sous_Type				Identifiant d’un sous type d’enregistrement relié à validation.  
													S’il est vide, les validations de tous les sous type sont considérées.
						iCode_Validation			Code de la validation.  S’il est vide, toutes les validations sont
													considérées.
						bActif						Indicateur de validation active.  S’il est vide, toutes les validations
													 sont considérées.  1 = validations actives.  0 = validations inactives.
						bValidation_Speciale		Indicateur de validation spéciale.  S’il est vide, toutes les 
													validations sont considérées.  1 = validations spéciales.  
													0 = validations non spéciale.
						bCorrection_Possible		Indicateur de correction possible.  S’il est vide, toutes les 
													validations sont considérées.  1 = correction possible.  
													0 = correction non possible.
						tiID_Categorie_Erreur		Identifiant unique d’une catégorie d’erreur.  S’il est vide, les 
													validations de toutes les catégories sont considérées.
						cType						Type de validation. S’il est vide, les validations de tous les types
													sont considérées.  « E » =  Erreurs, « A » = Avertissements
						tiID_Categorie_Element		Identifiant unique d’une catégorie d’éléments.  S’il est vide, toutes
													les validations sont considérées.

Exemple d’appel		:	SELECT * FROM [dbo].[fntIQEE_RechercherValidations](NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
																	   NULL, NULL, NULL)

Paramètres de sortie:	Tous les champs de la table « tblIQEE_Validations ».

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2009-06-25		Éric Deshaies						Création du service
		2010-08-03		Éric Deshaies						Mise à niveau sur la traduction des champs

****************************************************************************************************/
CREATE FUNCTION [dbo].[fntIQEE_RechercherValidations]
(
	@cID_Langue CHAR(3),
	@iID_Validation INT,
	@tiID_Type_Enregistrement TINYINT,
	@iID_Sous_Type INT,
	@iCode_Validation INT,
	@bActif BIT,
	@bValidation_Speciale BIT,
	@bCorrection_Possible BIT,
	@tiID_Categorie_Erreur TINYINT,
	@cType CHAR(1),
	@tiID_Categorie_Element TINYINT
)
RETURNS @tblIQEE_Validations TABLE
(
	iID_Validation INT NOT NULL,
	tiID_Type_Enregistrement TINYINT NOT NULL,
	iID_Sous_Type INT NULL,
	iCode_Validation INT NOT NULL,
	vcDescription VARCHAR(300) NOT NULL,
	vcDescription_Parametrable VARCHAR(300) NOT NULL,
	bActif BIT NOT NULL,
	bValidation_Speciale BIT NOT NULL,
	cType CHAR(1) NOT NULL,
	bCorrection_Possible BIT NOT NULL,
	vcDescription_Valeur_Reference VARCHAR(100) NULL,
	vcDescription_Valeur_Erreur VARCHAR(100) NULL,
	vcDescription_Lien_Vers_Erreur_1 VARCHAR(100) NULL,
	vcDescription_Lien_Vers_Erreur_2 VARCHAR(100) NULL,
	vcDescription_Lien_Vers_Erreur_3 VARCHAR(100) NULL,
	tiID_Categorie_Element TINYINT NOT NULL,
	tiID_Categorie_Erreur TINYINT NOT NULL
)
AS
BEGIN
	-- Considérer le français comme la langue par défaut
	IF @cID_Langue IS NULL
		SET @cID_Langue = 'FRA'

	-- Si les valeurs numériques sont à 0, c'est comme si elle n'étaient pas présente
	IF @iID_Validation = 0
		SET @iID_Validation = NULL

	IF @tiID_Type_Enregistrement = 0
		SET @tiID_Type_Enregistrement = NULL

	IF @iID_Sous_Type = 0
		SET @iID_Sous_Type = NULL

	IF @iCode_Validation = 0
		SET @iCode_Validation = NULL

	IF @tiID_Categorie_Erreur = 0
		SET @tiID_Categorie_Erreur = NULL

	IF @tiID_Categorie_Element = 0
		SET @tiID_Categorie_Element = NULL

	-- Rechercher les validations selon les critères de recherche
	INSERT INTO @tblIQEE_Validations
	SELECT  V.iID_Validation,	
			V.tiID_Type_Enregistrement,
			V.iID_Sous_Type,
			V.iCode_Validation,
			ISNULL(T1.vcTraduction,V.vcDescription) AS vcDescription,
			ISNULL(T2.vcTraduction,V.vcDescription_Parametrable) AS vcDescription_Parametrable,
			V.bActif,
			V.bValidation_Speciale,
			V.cType,
			V.bCorrection_Possible,
			ISNULL(T3.vcTraduction,V.vcDescription_Valeur_Reference) AS vcDescription_Valeur_Reference,
			ISNULL(T4.vcTraduction,V.vcDescription_Valeur_Erreur) AS vcDescription_Valeur_Erreur,
			ISNULL(T5.vcTraduction,V.vcDescription_Lien_Vers_Erreur_1) AS vcDescription_Lien_Vers_Erreur_1,
			ISNULL(T6.vcTraduction,V.vcDescription_Lien_Vers_Erreur_2) AS vcDescription_Lien_Vers_Erreur_2,
			ISNULL(T7.vcTraduction,V.vcDescription_Lien_Vers_Erreur_3) AS vcDescription_Lien_Vers_Erreur_3,
			V.tiID_Categorie_Element,
			V.tiID_Categorie_Erreur	
	FROM tblIQEE_Validations V
		 LEFT JOIN tblGENE_Traductions T1 ON T1.vcNom_Table = 'tblIQEE_Validations'
										 AND T1.vcNom_Champ = 'vcDescription'
										 AND T1.iID_Enregistrement = V.iID_Validation
										 AND T1.vcID_Langue = @cID_Langue
		 LEFT JOIN tblGENE_Traductions T2 ON T2.vcNom_Table = 'tblIQEE_Validations'
										 AND T2.vcNom_Champ = 'vcDescription_Parametrable'
										 AND T2.iID_Enregistrement = V.iID_Validation
										 AND T2.vcID_Langue = @cID_Langue
		 LEFT JOIN tblGENE_Traductions T3 ON T3.vcNom_Table = 'tblIQEE_Validations'
										 AND T3.vcNom_Champ = 'vcDescription_Valeur_Reference'
										 AND T3.iID_Enregistrement = V.iID_Validation
										 AND T3.vcID_Langue = @cID_Langue
		 LEFT JOIN tblGENE_Traductions T4 ON T4.vcNom_Table = 'tblIQEE_Validations'
										 AND T4.vcNom_Champ = 'vcDescription_Valeur_Erreur'
										 AND T4.iID_Enregistrement = V.iID_Validation
										 AND T4.vcID_Langue = @cID_Langue
		 LEFT JOIN tblGENE_Traductions T5 ON T5.vcNom_Table = 'tblIQEE_Validations'
										 AND T5.vcNom_Champ = 'vcDescription_Lien_Vers_Erreur_1'
										 AND T5.iID_Enregistrement = V.iID_Validation
										 AND T5.vcID_Langue = @cID_Langue
		 LEFT JOIN tblGENE_Traductions T6 ON T6.vcNom_Table = 'tblIQEE_Validations'
										 AND T6.vcNom_Champ = 'vcDescription_Lien_Vers_Erreur_2'
										 AND T6.iID_Enregistrement = V.iID_Validation
										 AND T6.vcID_Langue = @cID_Langue
		 LEFT JOIN tblGENE_Traductions T7 ON T7.vcNom_Table = 'tblIQEE_Validations'
										 AND T7.vcNom_Champ = 'vcDescription_Lien_Vers_Erreur_3'
										 AND T7.iID_Enregistrement = V.iID_Validation
										 AND T7.vcID_Langue = @cID_Langue
	WHERE (@iID_Validation IS NULL OR V.iID_Validation = @iID_Validation)
	  AND (@iCode_Validation IS NULL OR V.iCode_Validation = @iCode_Validation)
	  AND (@bActif IS NULL OR V.bActif = @bActif)
	  AND (@tiID_Type_Enregistrement IS NULL OR V.tiID_Type_Enregistrement = @tiID_Type_Enregistrement)
	  AND (@iID_Sous_Type IS NULL OR V.iID_Sous_Type = @iID_Sous_Type)
	  AND (@tiID_Categorie_Erreur IS NULL OR V.tiID_Categorie_Erreur = @tiID_Categorie_Erreur)
	  AND (@tiID_Categorie_Element IS NULL OR V.tiID_Categorie_Element = @tiID_Categorie_Element)
	  AND (@cType IS NULL OR V.cType = @cType)
	  AND (@bCorrection_Possible IS NULL OR V.bCorrection_Possible = @bCorrection_Possible)
	  AND (@bValidation_Speciale IS NULL OR V.bValidation_Speciale = @bValidation_Speciale)
	ORDER BY V.iOrdre_Presentation

	-- Retourner les informations
	RETURN 
END

