/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fntGENE_ObtenirListeSousCategorieUnite
Nom du service		: fntGENE_ObtenirListeSousCategorieUnite
But 				: Obtenir la description des sous-catégories d'unité
Description			: Ce service retourne l'identifiant et la description des sous-catégories d'unité
					  triés en ordre de description	pour les bGene_Liste_Pres = true	

Facette				: GENE
Référence			: 

Paramètres d’entrée	:	Paramètre					Obligatoire	Description
						--------------------------	-----------	-----------------------------------------------------------------
						N/A

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						Un_Unit_Sous_Cat			iSous_Cat_ID					Identifiant de la sous-catégorie
													vcSous_Cat_Desc					Description de la sous-catégorie

Exemple d'appel : 
				SELECT * FROM dbo.fntGENE_ObtenirListeSousCategorieUnite()

Historique des modifications:
		Date			Programmeur					Description						Référence
		------------	-------------------------	---------------------------  	------------
		2009-08-06		Jean-François Gauthier				

****************************************************************************************************/
CREATE FUNCTION dbo.fntGENE_ObtenirListeSousCategorieUnite()
RETURNS @tSousCateg TABLE
						(
						iSous_Cat_ID		INT
						,vcSous_Cat_Desc	VARCHAR(250)
						)
AS
	BEGIN
		INSERT INTO @tSousCateg
		SELECT
			sc.iSous_Cat_ID	
			,sc.vcSous_Cat_Desc
		FROM
			dbo.Un_Unit_Sous_Cat sc
		WHERE
			sc.bGene_Liste_Pres = 1
		ORDER BY
			sc.vcSous_Cat_Desc
		RETURN
	END
