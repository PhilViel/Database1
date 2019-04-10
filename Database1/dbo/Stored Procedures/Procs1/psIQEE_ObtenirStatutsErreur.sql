/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psIQEE_ObtenirStatutsErreur
Nom du service		: Obtenir les statuts des erreurs 
But 				: Obtenir les statuts possibles pour les erreurs de l’IQÉÉ selon la langue de l’utilisateur.
Facette				: IQÉÉ

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				cID_Langue					Identifiant unique de la langue de l’utilisateur selon « Mo_Lang ».
													Le français est la langue par défaut si elle n’est pas spécifiée.

Exemple d’appel		:	EXECUTE [dbo].[psIQEE_ObtenirStatutsErreur] 'FRA'

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						Tous les champs de la table « tblIQEE_StatutsErreur ». Les statuts sont triés selon l’ordre de présentation.

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2008-09-29		Éric Deshaies						Création du service							
		2009-04-16		Éric Deshaies						Ajout des champs
															bInd_Selectionnable_Utilisateur et
															bInd_Modifiable_Utilisateur
		2009-11-05		Éric Deshaies						Mise à niveau du service.
		2010-08-03		Éric Deshaies						Mise à niveau sur la traduction des champs

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_ObtenirStatutsErreur] 
(
	@cID_Langue CHAR(3)
)
AS
BEGIN
	-- Considérer le français comme la langue par défaut
	IF @cID_Langue IS NULL
		SET @cID_Langue = 'FRA'

	SET NOCOUNT ON;

	-- Retourner les statuts d'erreur
	SELECT SE.tiID_Statuts_Erreur,
		   SE.vcCode_Statut,
		   ISNULL(T1.vcTraduction,SE.vcDescription) AS vcDescription,
		   SE.bInd_Retourner_RQ,
		   SE.bInd_Selectionnable_Utilisateur,
		   SE.bInd_Modifiable_Utilisateur
	FROM tblIQEE_StatutsErreur SE
		 LEFT JOIN tblGENE_Traductions T1 ON T1.vcNom_Table = 'tblIQEE_StatutsErreur'
										 AND T1.vcNom_Champ = 'vcDescription'
										 AND T1.iID_Enregistrement = SE.tiID_Statuts_Erreur
										 AND T1.vcID_Langue = @cID_Langue
	ORDER BY SE.tiOrdre_Presentation
END

