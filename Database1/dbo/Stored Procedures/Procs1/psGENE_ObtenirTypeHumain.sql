
/****************************************************************************************************
Code de service		:		psGENE_ObtenirTypeHumain
Nom du service		:		Ce service est utilisé pour récupérer le types d’un humain
But					:		Récupérer le type 
Facette				:		GENE
Reférence			:		SGRC

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@@iUserId					Critère de recherche : Identifiant de l’humain propriétaire du Type
																		   Si NULL, U est retourné

Exemple d'appel:
                
                EXEC dbo.psGENE_ObtenirTypeHumain 176465

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------
													return										S = Souscripteur
																								B = Bénéficiaire
																								U = Unknow
                    
Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2010-08-12					Eric Michaud							Création du service
 ****************************************************************************************************/
CREATE PROCEDURE dbo.psGENE_ObtenirTypeHumain
				(					
					@iUserId INT
				)
AS
	BEGIN

	SET NOCOUNT ON
	IF EXISTS (SELECT 1 FROM dbo.Un_Subscriber where SubscriberID = @iUserId)
		SELECT 's' as TypeHumain
	ELSE IF EXISTS (SELECT 1 FROM dbo.Un_Beneficiary where BeneficiaryID = @iUserId)
		SELECT 'b' as TypeHumain
	ELSE
		SELECT 'u' as TypeHumain -- UNKNOWN

	END


