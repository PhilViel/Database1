/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psIQEE_ObtenirSousTypeEnregistrement
Nom du service		: Obtenir les sous type d’enregistrement 
But 				: Obtenir les sous type d’enregistrement de l’IQÉÉ selon la langue de l’utilisateur.
Facette				: IQÉÉ

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				cID_Langue					Identifiant unique de la langue de l’utilisateur selon « Mo_Lang ».
													Le français est la langue par défaut si elle n’est pas spécifiée.

Exemple d’appel		:	EXECUTE [dbo].[psIQEE_ObtenirSousTypeEnregistrement] 'FRA'

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						Tous les champs de la table « tblIQEE_SousTypeEnregistrement ».  Les sous type d’enregistrement
						sont triés en ordre de code d’enregistrement et de code de sous type d’enregistrement.

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2009-06-23		Éric Deshaies						Création du service							
		2009-11-05		Éric Deshaies						Mise à niveau du service.
		2010-08-03		Éric Deshaies						Mise à niveau sur la traduction des champs

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_ObtenirSousTypeEnregistrement] 
(
	@cID_Langue CHAR(3)
)
AS
BEGIN
	-- Considérer le français comme la langue par défaut
	IF @cID_Langue IS NULL
		SET @cID_Langue = 'FRA'

	SET NOCOUNT ON;

	-- Retourner les sous-types d'enregistrement
	SELECT ST.iID_Sous_Type,
		   ST.tiID_Type_Enregistrement,
		   ST.cCode_Sous_Type,
		   ISNULL(T1.vcTraduction,ST.vcDescription) AS vcDescription
	FROM tblIQEE_SousTypeEnregistrement ST
		 JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = ST.tiID_Type_Enregistrement
		 LEFT JOIN tblGENE_Traductions T1 ON T1.vcNom_Table = 'tblIQEE_SousTypeEnregistrement'
										 AND T1.vcNom_Champ = 'vcDescription'
										 AND T1.iID_Enregistrement = ST.iID_Sous_Type
										 AND T1.vcID_Langue = @cID_Langue
	ORDER BY TE.cCode_Type_Enregistrement, ST.cCode_Sous_Type
END

