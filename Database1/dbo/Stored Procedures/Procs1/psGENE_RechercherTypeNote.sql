
/****************************************************************************************************
Code de service		:		psGENE_RechercherTypeNote
Nom du service		:		Ce service est utilisé pour obtenir les information des types de notes
But					:		Rechercher les titres de notes correspondant aux critères de recherche.
Facette				:		GENE 
Reférence			:		Système de gestion de la relation client

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
                        iID_TypeNote	            Critère de recherche : numéro identifiant d’un titre de note (non obligatoire)
						cCodeTypeNote				Critère de recherche : Code d’un type de note (non obligatoire)
						bActif						=0 (Tous les types sont retournés)
													=1 (Seuls les types actifs sont retournés)

Exemple d'appel:
		EXEC DBO.psGENE_RechercherTypeNote NULL,NULL,0

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
                       tblGENE_TypeNote	            Tous

Historique des modifications :			
						Date						Programmeur								Description							Référence
						2009-11-27					Jean-François Gauthier					Création du service
						2010-03-30					Jean-François Gauthier					Ajout d'un paramètre afin de spécifier si on 
																							retourne tous les types de notes (Modification) ou
																							seulement les actifs (Ajout)
 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[psGENE_RechercherTypeNote]
							(	
								@iID_TypeNote		INT,
								@cCodeTypeNote		VARCHAR(75),
								@bActif				BIT			= NULL
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
			,cCodeTypeNote
		FROM 
			dbo.fntGENE_RechercherTypeNote(@iID_TypeNote,@cCodeTypeNote, @bActif)

	END
