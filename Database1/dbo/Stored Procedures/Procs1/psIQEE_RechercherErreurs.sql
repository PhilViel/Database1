/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psIQEE_RechercherErreurs
Nom du service		: Rechercher les erreurs 
But 				: Rechercher à travers les erreurs de l’IQÉÉ et obtenir les informations des erreurs.
Facette				: IQÉÉ

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						cID_Langue					Identifiant unique de la langue de l’utilisateur selon « Mo_Lang ».
													Le français est la langue par défaut si elle n’est pas spécifiée.
						iID_Erreur					Identifiant unique de l’erreur de l’IQÉÉ.  S’il est vide, toutes
													les erreurs sont considérées.
						tiID_Type_Enregistrement	Identifiant du type d’enregistrement relié à l’erreur.  S’il est
													vide, tous les types d’enregistrement sont considérés.
						iID_Enregistrement			Identifiant d’un enregistrement relié à l’erreur.  S’il est vide,
													tous les enregistrements sont considérés.
						iID_Convention				Identifiant unique de la convention relié à l’erreur.  S’il est
													vide, toutes les conventions sont considérées.
						vcNo_Convention				Numéro de la convention relié à l’erreur.  S’il est vide, toutes
													les conventions sont considérées.
						tiID_Categorie_Erreur		Identifiant unique d’une catégorie d’erreur.  S’il est vide, toutes
													les catégories sont considérées.
						siCode_Erreur   			Identifiant unique du type d’erreur. S’il est vide, tous les types
													d’erreur sont considérés.
						siAnnee_Fiscale				Année fiscale du fichier d’où provient l’erreur.  Si elle est vide,
													toutes les années sont considérées.
						iID_Fichier_IQEE			Identifiant du fichier d’où provient l’erreur.  Si elle est vide,
													tous les fichiers sont considérés.
						tiID_Statuts_Erreur			Identifiant du statut de l’erreur.  S’il est vide, tous les statuts
													sont considérés.
						vcCommentaires				Partie de commentaire.  S’il est vide, tous les types de commentaires
													sont considérés.

Exemple d’appel		:	EXECUTE [dbo].[psIQEE_RechercherErreurs] NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
																	   NULL, NULL, NULL, NULL

Paramètres de sortie:	Tous les champs de la fonction « fntIQEE_RechercherErreurs ».

Historique des modifications:
	Date		Programmeur				Description
	----------	--------------------	------------------------------------------------------------
	2009-11-23	Éric Deshaies			Création du service
	2010-08-30	Éric Deshaies			Ajout de champs pour des modifications à l'application Web.
    2018-06-06  Steeve Picard           Modificiation de la gestion des retours d'erreur par RQ
****************************************************************************************************/
CREATE PROCEDURE dbo.psIQEE_RechercherErreurs 
(
	@cID_Langue CHAR(3),
	@iID_Erreur INT,
	@tiID_Type_Enregistrement TINYINT,
	@iID_Enregistrement INT,
	@iID_Convention INT,
	@vcNo_Convention VARCHAR(15),
	@tiID_Categorie_Erreur TINYINT,
	@iID_Type_Erreur_RQ INT, --@siCode_Erreur SMALLINT,
	@siAnnee_Fiscale SMALLINT,
	@iID_Fichier_IQEE INT,
	@tiID_Statuts_Erreur TINYINT,
	@vcCommentaires VARCHAR(75)
)
AS
BEGIN
	SET NOCOUNT ON;

    DECLARE @siCode_Erreur SMALLINT = @iID_Type_Erreur_RQ

	-- Retourner les erreurs
	SELECT  iID_Erreur,
			iID_Fichier_IQEE,
			tiID_Categorie_Erreur,
			siCode_Erreur AS iID_Type_Erreur_RQ,
			tiID_Type_Enregistrement,
			tiID_Statuts_Erreur,
			vcElement_Erreur,
			vcValeur_Erreur,
			tCommentaires,
			iID_Utilisateur_Modification,
			dtDate_Modification,
			vcUtilisateur_Modification,
			iID_Convention,
			vcNo_Convention,
			iID_Enregistrement,
			vcType_Enregistrement,
			vcType_ErreurRQ,
			siCode_Erreur,
			cCode_Type_Enregistrement,
			bInd_Modifiable_Utilisateur,
			iID_Utilisateur_Traite,
			dtDate_Traite,
			vcUtilisateur_Traite,
			dtDate_Transaction,
			iID_Souscripteur,
			iID_Beneficiaire,
			iID_Ancien_Beneficiaire,
			cCode_Sous_Type,
			vcDescription_Sous_Type,
			tiCode_Version,
			vcDescription_Version
	FROM dbo.fntIQEE_RechercherErreurs(@cID_Langue, @iID_Erreur, @tiID_Type_Enregistrement, @iID_Enregistrement, @iID_Convention,
										   @vcNo_Convention, @tiID_Categorie_Erreur, @siCode_Erreur, @siAnnee_Fiscale,
										   @iID_Fichier_IQEE, @tiID_Statuts_Erreur, @vcCommentaires)
END
