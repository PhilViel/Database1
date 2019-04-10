
/****************************************************************************************************
Code de service		:		fntGENE_ObtenirConventionHumain
Nom du service		:		Ce service est utilisé pour récupérer les conventions d’un humain
But					:		Récupérer les conventions
Facette				:		GENE
Reférence			:		SGRC

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@iHumanID					Critère de recherche : Identifiant de l’humain propriétaire de la convention
																		   Si NULL, toutes les conventions sont retournées

Exemple d'appel:
                
                SELECT * FROM fntGENE_ObtenirConventionHumain(176465)

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
						2009-07-10					Jean-François Gauthier					Création de la fonction
 ****************************************************************************************************/
CREATE FUNCTION [dbo].[fntGENE_ObtenirConventionHumain]
				(					
					@iHumanID INT
				)
RETURNS 
	@tConvention TABLE  (
						ConventionID		INT,	
						ConventionNo		VARCHAR(75),
						SubscriberID		INT,
						SubscriberName		VARCHAR(87),
						BeneficiaryID		INT,	
						BeneficiaryName		VARCHAR(87)	
						)
	
AS
BEGIN
		INSERT INTO @tConvention
		(
			ConventionID,
			ConventionNo,
			SubscriberID,
			SubscriberName,
			BeneficiaryID,
			BeneficiaryName
		)
		SELECT
			ConventionID	= c.ConventionID,
			ConventionNo	= c.ConventionNO,
			SubscriberID	= c.SubscriberID,
			SubscriberName	= hs.FirstName + ' ' + hs.LastName,
			BeneficiaryID	= c.BeneficiaryID,
			BeneficiaryName	= hb.FirstName + ' ' + hb.LastName
		FROM 
			dbo.Un_Convention c
			INNER JOIN dbo.Mo_Human hs
				ON c.SubscriberID = hs.HumanID
			INNER JOIN dbo.Mo_Human hb
				ON c.BeneficiaryID = hb.HumanID	
		WHERE	
			c.SubscriberId = ISNULL(@iHumanID, c.SubscriberId) 
	RETURN
END
