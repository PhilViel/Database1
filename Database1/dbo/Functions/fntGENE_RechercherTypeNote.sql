
/****************************************************************************************************
Code de service		:		fntGENE_RechercherTypeNote
Nom du service		:		Ce service est utilisé pour obtenir les information des types de notes
But					:		Rechercher les titres de notes correspondant aux critères de recherche.
Facette				:		GENE 
Reférence			:		Système de gestion de la relation client

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
                        iID_TypeNote	            Critère de recherche : numéro identifiant d’un titre de note (non obligatoire)
						cCodeTypeNote				Critère de recherche : Code d’un type de note (non obligatoire)

Exemple d'appel:
		SELECT * FROM DBO.fntGENE_RechercherTypeNote(NULL,NULL,1)

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
                       tblGENE_TypeNote	            Tous

Historique des modifications :			
						Date						Programmeur								Description							Référence
						2009-07-09					Jean-François Gauthier					Création de la fonction
						2010-03-26					Jean-François Gauthier					Ajout d'un filtre pour ne pas faire 
																							faire afficher les types inactif
						2010-03-30					Jean-François Gauthier					Ajout d'un paramètre afin de spécifier si on 
																							retourne tous les types de notes (Modification) ou
																							seulement les actifs (Ajout)
 ****************************************************************************************************/
CREATE FUNCTION [dbo].[fntGENE_RechercherTypeNote]
							(	
								@iID_TypeNote		INT,
								@cCodeTypeNote		VARCHAR(75),
								@bActif				BIT
                             )
RETURNS  @tTypeNote  TABLE(	
								iId_TypeNote	INT,
								tNoteTypeDesc	VARCHAR(MAX), 
								cCodeTypeNote	VARCHAR(75)
							  )
AS
	BEGIN
		INSERT INTO @tTypeNote
		(
			iId_TypeNote,
			tNoteTypeDesc, 
			cCodeTypeNote
		)
		SELECT
			iId_TypeNote,
			tNoteTypeDesc, 
			cCodeTypeNote
		FROM
			dbo.tblGENE_TypeNote tn
		WHERE
			tn.iID_TypeNote		= ISNULL(@iID_TypeNote, tn.iID_TypeNote)
			AND
			tn.cCodeTypeNote	= ISNULL(@cCodeTypeNote, tn.cCodeTypeNote)
			AND 
			tn.bActif			= ISNULL(NULLIF(@bActif,0),tn.bActif)
		ORDER BY
			CAST(tNoteTypeDesc AS VARCHAR(4000)) ASC
			
		RETURN
	END
