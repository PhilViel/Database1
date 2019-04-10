/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psIQEE_RechercherParametres
Nom du service		: Rechercher des paramètres
But 				: Rechercher à travers l’historique des paramètres de l’IQÉÉ et obtenir les informations des 
					  séries de paramètres.
Facette				: IQÉÉ

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				siAnnee_Fiscale				Rechercher les séries de paramètres de l’IQÉÉ selon une année 
													fiscale en particulier.  S’il est vide, toutes les années
													sont considérées.
						bSeulementParamVigueur		Indicateur qui permet de rechercher oui ou non uniquement les
													séries de paramètres en vigueur à la date du jour
													(dtDate_Fin_Application est nul).

Exemple d’appel		:	EXECUTE [dbo].[psIQEE_RechercherParametres] 2007, 1

Paramètres de sortie:	Tous les champs de la fonction "fntIQEE_RechercherParametres"

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2009-11-23		Éric Deshaies						Création du service					

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_RechercherParametres] 
(
	@siAnnee_Fiscale SMALLINT,
	@bSeulementParamVigueur BIT
)
AS
BEGIN
	SET NOCOUNT ON;

	-- Retourner les paramètres
	SELECT  iID_Parametres_IQEE,
			siAnnee_Fiscale,
			dtDate_Debut_Application,
			dtDate_Fin_Application,
			dtDate_Debut_Cotisation,
			dtDate_Fin_Cotisation,
			siNb_Jour_Limite_Demande,
			tiNb_Maximum_Annee_Fiscale_Anterieur,
			iID_Utilisateur_Creation,
			iID_Utilisateur_Modification,
			dtDate_Modification,
			vcNom_Utilisateur_Creation,
			vcNom_Utilisateur_Modification,
			bUtilise_Par_Fichier
	FROM [dbo].[fntIQEE_RechercherParametres](@siAnnee_Fiscale, @bSeulementParamVigueur)
END

