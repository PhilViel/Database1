/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_RelationshipType
Description         :	Liste des relations souscripteur/bénéficiaire

Exemple d'appel		:	EXECUTE dbo.SL_UN_RelationshipType 'ENU'
						EXECUTE dbo.SL_UN_RelationshipType 'FRA'
						EXECUTE dbo.SL_UN_RelationshipType 

Valeurs de retours  :	Dataset :
									tiRelationshipTypeID	INTEGER 			ID unique du lien de parenté entre le souscripteur et 
																					le bénéficiaire
									vcRelationshipType	VARCHAR(200)	Lien de parenté.
Note                :	ADX0000831	IA	2006-03-27	Bruno Lapointe			Création
										2010-03-05	Jean-François Gauthier	Ajout du traitement pour traduire les libellés
****************************************************************************************************/
CREATE PROCEDURE dbo.SL_UN_RelationshipType
							(
								@cLangueID	CHAR(3) = NULL
							)
AS
	BEGIN

		SET @cLangueID = ISNULL(@cLangueID,'FRA')
			
		SELECT
			rt.tiRelationshipTypeID,
			vcRelationshipType =
			CASE 
				WHEN dbo.fnGENE_ObtenirParametre('TRADUCTION',NULL,'Un_RelationshipType','vcRelationshipType', ISNULL(rt.vcRelationshipType,''), @cLangueID,NULL) = '-2' THEN ISNULL(rt.vcRelationshipType,'') 
				ELSE 
					dbo.fnGENE_ObtenirParametre('TRADUCTION',NULL,'Un_RelationshipType','vcRelationshipType', ISNULL(rt.vcRelationshipType,''), @cLangueID,NULL)			
			END
		FROM 
			dbo.Un_RelationshipType rt

	END
