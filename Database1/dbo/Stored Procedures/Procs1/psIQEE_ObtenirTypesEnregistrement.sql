/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psIQEE_ObtenirTypesEnregistrement
Nom du service		: Obtenir les types d’enregistrement 
But 				: Obtenir les types d’enregistrement de l’IQÉÉ selon la langue de l’utilisateur.
Facette				: IQÉÉ

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				cID_Langue					Identifiant unique de la langue de l’utilisateur selon « Mo_Lang ».
													Le français est la langue par défaut si elle n’est pas spécifiée.

Exemple d’appel		:	EXECUTE [dbo].[psIQEE_ObtenirTypesEnregistrement] 'FRA'

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						Tous les champs de la table « tblIQEE_TypesEnregistrement ».  Les types d’enregistrements sont
						triés en ordre de code d’enregistrement.

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2008-10-02		Éric Deshaies						Création du service							
		2009-11-05		Éric Deshaies						Mise à niveau du service.
		2010-08-03		Éric Deshaies						Mise à niveau sur la traduction des champs
		
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_ObtenirTypesEnregistrement] 
(
	@cID_Langue CHAR(3)
)
AS
BEGIN
	-- Considérer le français comme la langue par défaut
	IF @cID_Langue IS NULL
		SET @cID_Langue = 'FRA'

	SET NOCOUNT ON;

	-- Retourner les types d'enregistrement
	SELECT TE.tiID_Type_Enregistrement,
		   TE.cCode_Type_Enregistrement,
		   ISNULL(T1.vcTraduction,TE.vcDescription) AS vcDescription
	FROM tblIQEE_TypesEnregistrement TE
		 LEFT JOIN tblGENE_Traductions T1 ON T1.vcNom_Table = 'tblIQEE_TypesEnregistrement'
										 AND T1.vcNom_Champ = 'vcDescription'
										 AND T1.iID_Enregistrement = TE.tiID_Type_Enregistrement
										 AND T1.vcID_Langue = @cID_Langue
	ORDER BY TE.cCode_Type_Enregistrement
END

