/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psIQEE_ObtenirTypesErreurRQ
Nom du service		: Obtenir les types d’erreurs de RQ 
But 				: Obtenir les types possibles pour les erreurs de l’IQÉÉ selon la langue de l’utilisateur.
Facette				: IQÉÉ

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				cID_Langue					Identifiant unique de la langue de l’utilisateur selon « Mo_Lang ».
													Le français est la langue par défaut si elle n’est pas spécifiée.

Exemple d’appel		:	EXECUTE [dbo].[psIQEE_ObtenirTypesErreurRQ] 'FRA'

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						Tous les champs de la table « tblIQEE_TypesErreurRQ ».  Les types d’erreur RQ sont triés en
						ordre de code d’erreur.

Historique des modifications:
	Date		Programmeur				Description
	----------	--------------------    ------------------------------------------------------------
	2008-09-29	Éric Deshaies			Création du service	
	2009-11-05	Éric Deshaies			Mise à niveau du service.
	2010-08-03  Éric Deshaies			Mise à niveau sur la traduction des champs
    2018-06-06  Steeve Picard           Modificiation de la gestion des retours d'erreur par RQ
****************************************************************************************************/
CREATE PROCEDURE dbo.psIQEE_ObtenirTypesErreurRQ 
(
	@cID_Langue CHAR(3)
)
AS
BEGIN
	-- Considérer le français comme la langue par défaut
	IF @cID_Langue IS NULL
		SET @cID_Langue = 'FRA'

	SET NOCOUNT ON;

	-- Retourner les types des erreurs de RQ
	SELECT TE.siCode_Erreur AS iID_Type_Erreur_RQ,
		   TE.siCode_Erreur,
		   ISNULL(T1.vcTraduction,TE.vcDescription) AS vcDescription,
		   TE.tiID_Categorie_Erreur,
		   TE.bInd_Erreur_Grave
	FROM tblIQEE_TypesErreurRQ TE
		 LEFT JOIN tblGENE_Traductions T1 ON T1.vcNom_Table = 'tblIQEE_TypesErreurRQ'
										 AND T1.vcNom_Champ = 'vcDescription'
										 AND T1.iID_Enregistrement = TE.siCode_Erreur
										 AND T1.vcID_Langue = @cID_Langue
	ORDER BY TE.siCode_Erreur
END
