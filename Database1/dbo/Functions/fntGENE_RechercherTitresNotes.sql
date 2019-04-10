
/****************************************************************************************************
Code de service		:		fntGENE_RechercherTitresNotes
Nom du service		:		1.7.1	Recherche de titres de notes 
But					:		Rechercher les titres de notes correspondant aux critères de recherche.
Facette				:		SGRC 
Reférence			:		Système de gestion de la relation client

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
                        iID_TitreNote	            Critère de recherche : numéro identifiant d’un titre de note

Exemple d'appel:
                SELECT * FROM [dbo].[fntGENE_RechercherTitresNotes](NULL)
Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
                       tblGENE_TitreNote	            Tous

Historique des modifications :			
						Date						Programmeur								Description							Référence
						2009-04-23					D.T.									Création
						2009-06-19					Jean-François Gauthier					Ajout du ORDER BY
 ****************************************************************************************************/
CREATE FUNCTION [dbo].[fntGENE_RechercherTitresNotes]
							(	
								@iID_TitreNote INT 
                             )
RETURNS  @tTitresNotes  TABLE(	
								iID_TitreNote INT,
								vcTitreNote varchar(128), 
								cCodeTitre char(10)
							  )
AS
	BEGIN
		INSERT INTO @tTitresNotes 
		(iID_TitreNote, vcTitreNote, cCodeTitre)
		SELECT 
			iID_TitreNote, vcTitreNote, cCodeTitre
		FROM 
			dbo.tblGENE_TitreNote 
		WHERE 
			iID_TitreNote = @iID_TitreNote 
			OR 
			@iID_TitreNote IS NULL
		ORDER BY
			vcTitreNote ASC
		RETURN
	END
