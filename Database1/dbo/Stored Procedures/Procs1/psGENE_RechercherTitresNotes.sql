
/****************************************************************************************************
Code de service		:		psGENE_RechercherTitresNotes
Nom du service		:		1.7.1	Recherche de titres de notes 
But					:		Rechercher les titres de notes correspondant aux critères de recherche.
Facette				:		SGRC 
Reférence			:		Système de gestion de la relation client

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
                        iID_TitreNote	            Critère de recherche : numéro identifiant d’un titre de note

Exemple d'appel:
                EXEC [dbo].[psGENE_RechercherTitresNotes] NULL

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
                       tblGENE_TitreNote	            Tous

Historique des modifications :			
						Date						Programmeur								Description							Référence
						2009-11-27					Jean-François Gauthier					Création du service
 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[psGENE_RechercherTitresNotes]
							(	
								@iID_TitreNote INT 
                             )
AS
	BEGIN
		SET NOCOUNT ON

		SELECT 
			iID_TitreNote
			,vcTitreNote
			,cCodeTitre 
		FROM 
			dbo.fntGENE_RechercherTitresNotes(@iID_TitreNote)
	END
