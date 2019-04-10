
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
                EXEC [dbo].[psGENE_ObtenirListeHumainCreateurNote] 1

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
                       tblGENE_TitreNote	        iID_TitreNote
													vcTitreNote

Historique des modifications :			
						Date						Programmeur								Description							Référence
						2012-02-10					Donald Huppé							Création du service
 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[psGENE_ObtenirListeHumainCreateurNote]
							(	
								@bInclureTous BIT 
                             )
AS
	BEGIN
		SET NOCOUNT ON

	SELECT 
		iID_HumainCreateur
		,Nom
	FROM (

		SELECT 
			DISTINCT 
			TRI = 1
			,iID_HumainCreateur
			,Nom = h.LastName + ', ' + h.FirstName
		FROM 
			tblGENE_Note n
			JOIN dbo.Mo_Human h ON n.iID_HumainCreateur = h.HumanID
			
		UNION ALL
		
		SELECT
			tri = 0
			,iID_HumainCreateur = 0
			,Nom = 'Tous les usagers'
		WHERE @bInclureTous = 1
		
		) V
	ORDER BY 
		tri,
		Nom
			
	END


