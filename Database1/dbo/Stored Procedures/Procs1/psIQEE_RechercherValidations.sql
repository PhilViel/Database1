/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psIQEE_RechercherValidations
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

Exemple d’appel		:	EXECUTE [dbo].[psIQEE_RechercherValidations] NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
																	 NULL, NULL, NULL

Paramètres de sortie:	Tous les champs de la fonction « fntIQEE_RechercherValidations ».

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2009-11-23		Éric Deshaies						Création du service		

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_RechercherValidations] 
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
AS
BEGIN
	SET NOCOUNT ON;

	-- Retourner les validations
	SELECT  iID_Validation,
			tiID_Type_Enregistrement,
			iID_Sous_Type,
			iCode_Validation,
			vcDescription,
			vcDescription_Parametrable,
			bActif,
			bValidation_Speciale,
			cType,
			bCorrection_Possible,
			vcDescription_Valeur_Reference,
			vcDescription_Valeur_Erreur,
			vcDescription_Lien_Vers_Erreur_1,
			vcDescription_Lien_Vers_Erreur_2,
			vcDescription_Lien_Vers_Erreur_3,
			tiID_Categorie_Element,
			tiID_Categorie_Erreur
	FROM [dbo].[fntIQEE_RechercherValidations](@cID_Langue, @iID_Validation, @tiID_Type_Enregistrement, @iID_Sous_Type,
											   @iCode_Validation, @bActif, @bValidation_Speciale, @bCorrection_Possible,
											   @tiID_Categorie_Erreur, @cType, @tiID_Categorie_Element)
END

