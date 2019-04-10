
/****************************************************************************************************
Code de service		:		psGENE_ObtenirMembreEquipe
Nom du service		:		Ce service est utilisé pour récupérer les membres d’une équipe
But					:		Récupérer les membres d’une équipe 
Facette				:		GENE
Reférence			:		SGRC

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@iId_Equipe				Critère de recherche : Identifiant de l’équipe à renvoyer
						@iId_HumainResponsable	Critère de recherche : Identifiant de l’humain responsable de l'équipe


Exemple d'appel:
                
                EXEC dbo.psGENE_ObtenirMembreEquipe null,NULL

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------
                        MoHuman						HumanID										Identifiant de l'humain
						MoHuman						FirstName									Prénom de l’humain 
						MoHuman						LastName									Nom de l’humain 
                    
Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-11-27					Jean-Francois Gauthier					Création du service
						
 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_ObtenirMembreEquipe]
				(					
					@iId_Equipe INT = NULL,
					@iId_HumainResponsable INT = NULL
				)
AS
	BEGIN
		SET NOCOUNT ON

		SELECT 
			HumanID
			,HumainName
			,LastName
			,FirstName
		FROM 
			dbo.fntGENE_ObtenirMembreEquipe(@iId_Equipe,@iId_HumainResponsable)
	END
