
/****************************************************************************************************
Code de service		:		psGENE_ObtenirListeTypeNote
Nom du service		:		psGENE_ObtenirListeTypeNote
But					:		fournir la liste des Types de notes pour populer une liste déroulante dans un paramètre de rapport sur les notes
Facette				:		GENE 
Reférence			:		Système de gestion de la relation client

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
                        bInclureTous	            Indique si on veut avoir la veleur "Tous les types" dans le premier élément de la liste
						bActif						=0 (Tous les types sont retournés)
													=1 (Seuls les types actifs sont retournés)

Exemple d'appel:
		EXEC psGENE_ObtenirListeTypeNote 1,0

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
                       tblGENE_TypeNote	            iId_TypeNote
													tNoteTypeDesc

Historique des modifications :			
						Date						Programmeur								Description							Référence
						2012-02-10					Donald Huppé		 					Création du service
 ****************************************************************************************************/

creaTE PROCEDURE [dbo].[psGENE_ObtenirListeTypeNote]
							(	
								@bInclureTous BIT,
								@bActif	BIT
                             )
AS
	BEGIN
		SET NOCOUNT ON


		IF @bActif IS NULL
			BEGIN
				SET @bActif = 0
			END
			
	
	SELECT 
		iId_TypeNote
		,tNoteTypeDesc
	FROM (
	
		SELECT 
			TRI = 1
			,iId_TypeNote
			,tNoteTypeDesc
		FROM 
			dbo.fntGENE_RechercherTypeNote(NULL,NULL, @bActif)
		
		UNION ALL
		
		SELECT 
			TRI = 0
			,iId_TypeNote = 0
			,tNoteTypeDesc = 'Tous les types'
		WHERE @bInclureTous = 1
		) V
	ORDER BY 
		TRI
		,tNoteTypeDesc
		

	END
