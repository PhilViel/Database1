
/****************************************************************************************************
Code de service		:		psGENE_ChercherNotes
Nom du service		:		Rechercher des notes
But					:		Rechercher les notes répondant à certain critères
Facette				:		GENE
Reférence			:		Système de gestion des notes

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@iID_Note					Critère de recherche : Identifiant de la Note
						@vcTitre					Critère de recherche : Titre
						@dtDateDebut				Critère de recherche : Date de début des notes
						@dtDateFin					Critère de recherche : Date de fin des notes
						@iID_HumainClient			Critère de recherche : Identifiant de l’humain client de la note
						@iID_HumainCreateur			Critère de recherche : Identifiant de l’humain créateur de la note dont on souhaite récupérer les équipes
						@iID_TypeNote               Critère de recherche : Identifiant du type de note
						@vcListeCodeTypeNote		Critère de recherche : Liste de codes de types de notes (ignoré si @iID_TypeNote est précisé)

Exemple d'appel:
                EXEC dbo.psGENE_ChercherNotes null, null, null, null, null, null, null, NULL
                

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------
                        tblGENE_Note				Tous les champs	                            Tous les champs de la table tblGENE_Note
						Mo_Human					FirstName + LastName						Le nom et prénom de l'humain créateur
						tblGENE_TypeObjet			vcUrlAccess									Lien vers l'objet qui est lié à la note
						Mo_Adr						Email										Adresse email de l'humain créateur
						tblGENE_TypeNote			cCodeTypeNote								Code du type de note
						tblGENE_TypeNote			tNoteTypeDesc								Description du type de note

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-11-27					Jean-Francois Gauthier					Création de la procédure           
						
 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_ChercherNotes]
				(
					@iID_Note				INT,
					@vcTitre				VARCHAR(250),
					@dtDateDebut			DATETIME,
					@dtDateFin				DATETIME,
					@iID_HumainClient		INT,
					@iID_HumainCreateur		INT,
					@iID_TypeNote			INT,
					@vcListeCodeTypeNote	VARCHAR(1000)			
				)
AS
	BEGIN
		SET NOCOUNT ON

		SELECT 
			iID_Note
			,vcTitre		
			,tTexte			
			,iID_TypeNote	
			,dtDateCreation	
			,iID_HumainClient
			,iID_HumainCreateur
			,iID_HumainModifiant
			,dtDateModification
			,iID_ObjetApplication 
			,iID_TypeObjet		
			,vcTexteLienObjetLie
			,vcHumainCreateur
			,vcUrlAccess
			,vcEmail	
			,cCodeTypeNote
			,tNoteTypeDesc
		FROM 
			dbo.fntGENE_ChercherNotes(@iID_Note, @vcTitre, @dtDateDebut, @dtDateFin, @iID_HumainClient, @iID_HumainCreateur, @iID_TypeNote, @vcListeCodeTypeNote)
	END
