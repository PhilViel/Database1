
/****************************************************************************************************
Code de service		:		psGENE_ObtenirConventionHumain
Nom du service		:		Ce service est utilisé pour récupérer les conventions d’un humain
But					:		Récupérer les conventions
Facette				:		GENE
Reférence			:		SGRC

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@iHumanID					Critère de recherche : Identifiant de l’humain propriétaire de la convention
																		   Si NULL, toutes les conventions sont retournées

Exemple d'appel:
                
                EXEC dbo.psGENE_ObtenirConventionHumain 176465

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------
													ConventionID		INTEGER					ID de la convention
													ConventionNo		VARCHAR(75)				Numéro de convention
													SubscriberID		INTEGER					ID du souscripteur
													SubscriberName		VARCHAR(87)				Nom et prénom du souscripteur.
													BeneficiaryID		INTEGER					ID du bénéficiaire.
													BeneficiaryName		VARCHAR(87)				Nom et prénom du bénéficiaire.
                    
Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-07-27					Jean-François Gauthier					Création du service
 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_ObtenirConventionHumain]
				(					
					@iHumanID INT
				)
AS
	BEGIN
			SET NOCOUNT ON
		
			SELECT 
				ConventionID
				,ConventionNo
				,SubscriberID
				,SubscriberName
				,BeneficiaryID
				,BeneficiaryName
			FROM 
				dbo.fntGENE_ObtenirConventionHumain(@iHumanID)
	END
