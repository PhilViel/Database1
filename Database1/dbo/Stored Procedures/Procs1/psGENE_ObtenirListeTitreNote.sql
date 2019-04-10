
/****************************************************************************************************
Code de service		:		psGENE_ObtenirListeTitreNote
Nom du service		:		psGENE_ObtenirListeTitreNote 
But					:		fournir la liste des titres de notes pour populer un liste déroulante dans un paramètre de rapport sur les notes
Facette				:		SGRC 
Reférence			:		Système de gestion de la relation client

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
                        @bInclureTous	            Indique si on veut avoir la veleur "Tous les titres" dans le premier élément de la liste

Exemple d'appel:
                EXEC [dbo].[psGENE_ObtenirListeTitreNote] 1

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
                       tblGENE_TitreNote	        iID_TitreNote
													vcTitreNote

Historique des modifications :			
						Date						Programmeur								Description							Référence
						2012-02-10					Donald Huppé							Création du service
 ****************************************************************************************************/

create PROCEDURE [dbo].[psGENE_ObtenirListeTitreNote]
							(	
								@bInclureTous BIT 
                             )
AS
	BEGIN
		SET NOCOUNT ON


	SELECT 
		iID_TitreNote
		,vcTitreNote
	FROM (

		SELECT 
			tri = 1
			,iID_TitreNote
			,vcTitreNote
		FROM 
			dbo.fntGENE_RechercherTitresNotes(NULL)
			
		UNION ALL
		
		SELECT
			tri = 0
			,iID_TitreNote = 0
			,vcTitreNote = 'Tous les titres'
		WHERE @bInclureTous = 1
		) V
	ORDER BY 
		tri,
		vcTitreNote
			
	END
