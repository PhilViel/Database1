/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psIQEE_ObtenirRaisonsAnnulationUtilisateur
Nom du service		: Obtenir les raisons d'annulation utilisateur
But 				: Rechercher et retourner les raisons d'annulation qui sont accessibles à un utilisateur selon le
					  type et sous-type d'enregistrement pour une demande d'annulation/reprise manuelle.
Facette				: IQÉÉ

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						cID_Langue					Identifiant unique de la langue de l’utilisateur selon « Mo_Lang ».
													Le français est la langue par défaut si elle n’est pas spécifiée.
						tiID_Type_Enregistrement	Identifiant du type d'enregistrement de la raison d'annulation.
						iID_Sous_Type				Identifiant du sous-type d'enregistrement de la raison d'annulation.

Exemple d’appel		:	EXECUTE [dbo].[psIQEE_ObtenirRaisonsAnnulationUtilisateur] NULL, NULL, NULL

Paramètres de sortie:	Uniquement les champs de la fonction "fntIQEE_RechercherRaisonsAnnulation" qui sont utiles à
						l'interface utilisateur.

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2010-09-10		Éric Deshaies						Création du service						

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_ObtenirRaisonsAnnulationUtilisateur]
(
	@cID_Langue CHAR(3),
	@tiID_Type_Enregistrement TINYINT,
	@iID_Sous_Type INT
)
AS
BEGIN
	SET NOCOUNT ON;

	-- Retourner les fichiers
	SELECT iID_Raison_Annulation,
		   vcCode_Raison,
		   vcDescription,
		   tCommentaires_Utilisateur
	FROM [dbo].[fntIQEE_RechercherRaisonsAnnulation](@cID_Langue, NULL, NULL, 1, NULL, 'MAN', @tiID_Type_Enregistrement, @iID_Sous_Type, 1, NULL)
END

