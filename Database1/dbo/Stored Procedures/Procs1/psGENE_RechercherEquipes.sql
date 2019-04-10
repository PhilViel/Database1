
/****************************************************************************************************
Code de service		:		psGENE_RechercherEquipes
Nom du service		:		Rechercher des équipes de travail 
But					:		Rechercher les équipes répondant à certain critères
Facette				:		GENE
Reférence			:		SGRC

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@iId_Humain					Critère de recherche : Identifiant de l’humain dont on souhaite récupérer les équipes
						@iId_Equipe				Critère de recherche : Identifiant de l’équipe à renvoyer
						@iId_HumainResponsable		Critère de recherche : Identifiant de l’humain dont on cherche les équipes sous sa responsabilité


Exemple d'appel:
                
                EXEC dbo.psGENE_RechercherEquipes 1, null, null
				EXEC dbo.[psGENE_RechercherEquipes] NULL, NULL,546654

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------
                        tblGENE_EquipeTravail		Tous les champs	                            Tous les champs de la table tblGENE_Note
						MoHuman						FirstName									Prénom de l’humain responsable de l’équipe
						MoHuman						LastName									Nom de l’humain responsable de l’équipe
                    
Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-11-27					Jean-Francois Gauthier					Création du service
						
 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[psGENE_RechercherEquipes]
				(
					@iId_Humain INT,
					@iId_Equipe INT,
					@iId_HumainResponsable INT

				)
AS
	BEGIN
		SET NOCOUNT ON

		SELECT 
			iID_Equipe
			,vcNomEquipe
			,vcDescription
			,iID_HumainResponsable
			,iID_EquipeResponsable
			,LastName
			,FirstName
			,vcNomResponsable
		FROM 
			dbo.fntGENE_RechercherEquipes(@iId_Humain, @iId_Equipe,@iId_HumainResponsable)

	END
