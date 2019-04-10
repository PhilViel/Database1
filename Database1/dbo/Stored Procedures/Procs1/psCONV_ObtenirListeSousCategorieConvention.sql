/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc

Code de service		:		psCONV_ObtenirListeSousCategorieConvention
Nom du service		:		Ce service retourne l'identifiant et la description des sous-catégories d'unité
							triés en ordre de description pour les bGene_Liste_Pres = true
But					:		Obtenir la description des sous-catégories d'unité
Facette				:		CONV
Reférence			:		

Parametres d'entrée :	Parametres							Description
						-----------------------------------------------------------------------------------------------------
						iIDSous_Cat							Identifiant unique  de la sous catégorie

Exemple d'appel:
			EXECUTE [dbo].[psCONV_ObtenirListeSousCategorieConvention] 

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						Un_Unit_Sous_Cat			iSous_Cat_ID					Identifiant de la sous-catégorie
													vcSous_Cat_Desc					Description de la sous-catégorie

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2010-01-25					Jean-François Gauthier					Création de la procédure
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_ObtenirListeSousCategorieConvention] 
									(
									@iIDSous_Cat INT = 0
									)
AS
	BEGIN
			SELECT
				sc.iSous_Cat_ID	
				,sc.vcSous_Cat_Desc
			FROM
				dbo.Un_Unit_Sous_Cat sc
			WHERE
				sc.bGene_Liste_Pres = 1 
				AND 
				sc.iSous_Cat_ID = ISNULL(NULLIF(@iIDSous_Cat, 0), sc.iSous_Cat_ID) -- (0 pour tous)
			ORDER BY
				sc.iSous_Cat_ID
	END
