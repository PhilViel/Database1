/****************************************************************************************************
Code de service		:		psCONV_ObtenirListeConventions
Nom du service		:		Obtenir les conventions 
But					:		Récupérer les conventions REE d'un souscripteur
							Récupérer les conventions REE d'un bénéficiaire
							Récupérer les conventions d'un bénéficiaire ainsi que les conventions lui ayant déjà appartenue
							
Facette				:		P171U
Reférence			:		Relevé de dépôt

Parametres d'entrée :	Parametres					Description                                 Obligatoire
                        ----------                  ----------------                            --------------                       
                        dtDateReleve	            La date du relevé	                        Oui
						iIDSouscripteur             Identifiant unique du souscripteur          Non, mais doit être passé à NULL si non utilisé
						iIDBeneficiaire				Identifiant unique du bénéficiaire			Non, mais doit être passé à NULL si non utilisé
						bListeComplete				Indique si on doit retourner la liste		Oui
													complète des conventions d'un bénéficiaire	

N.B.
	Les paramètres 	iIDSouscripteur et iIDBeneficiaire sont indépendants l'un de l'autre. Autrement dit,
	ils ne devraient jamais recevoir une valeur spécifique en même temps. Si jamais c'est le cas, la requête
	liée à iIDSouscripteur aura préséance. Il en sera de même si les 2 paramètres sont passés avec la valeur
	NULL.


Exemple d'appel:
					-- Recherche des conventions REE pour un souscripteur donné
                    EXEC dbo.psCONV_ObtenirListeConventions '2008-12-31',380489, NULL, 0 -- retourne 3 enregistrements

					-- Recherche des conventions REE pour tous les souscripteurs
                    EXEC dbo.psCONV_ObtenirListeConventions '2008-12-31',NULL, NULL, 0

					-- Recherche des conventions REE pour un bénéficiaire
					EXEC dbo.psCONV_ObtenirListeConventions '2009-10-15', NULL, 556263, 0

					-- Recherche de l'ensemble des conventions ayant appartenu à un bénéficiaire
					EXEC dbo.psCONV_ObtenirListeConventions '2009-10-15', NULL, 556263, 1           

Parametres de sortie :  Table						Champs										Description
					    -----------------			---------------------------					--------------------------
                        Un_Convention	            ConventionID	                            Identifiant unique de la convention
										            SubscriberID	                            Identifiant unique du souscripteur
										            BeneficiaryID	                            Identifiant unique du bénéficiaire
									                ConventionNo								Numéro de la convention
                        Un_Plan                     PlanDesc                                    Description du régime            
								                    PlanTypeID                                  Code du régime
						N/A							bBeneficiaireActuel							Indique si le bénéficiaire passé en paramètre est celui en cours sur la convention
													bFormulaireRecu								Indique si le formulaire RHDSC est reçu sur la convention
													bBECActif									Indique si le BEC est actif sur la convention
													bConventionResilie							Indique si la convention est résiliée
													mMontantBEC									Montant du BEC
                    
Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-11-27					Jean-François Gauthier					Création de la procédure
                        2018-02-27                  Pierre-Luc Simard                       N'est pas appelée
						2018-04-16					Donald Huppé							Enlever deprecated car utilisé pas outil de gestion du BEC. À vérifier
 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[psCONV_ObtenirListeConventions] 
						(	
							@dtDateReleve		DATETIME
							,@iIDSouscripteur	INT
							,@iIDBeneficiaire	INT	
							,@bListeComplete	BIT	
						)
AS
	BEGIN
			SET NOCOUNT ON

            --SELECT 1/0
            
			SELECT 
				ConventionID					
				,SubscriberID					
				,BeneficiaryID					
				,ConventionNo					
				,PlanDesc						
				,PlantypeID						
				,TextDiploma					
				,bBeneficiaireActuel			
				,bFormulaireRecu				
				,bBECActif						
				,bConventionResilie				
				,mMontantBEC					
				,vcNomBeneficiaire				
				,vcPrenomBeneficiaire			
				,vcNomSouscripteur				
				,vcPrenomSouscripteur			
				,bPrincipalResponsablePresent	
				,vcStatutConvention				
				,iIDConventionBEC				
				,iIDConventionBECSuggere		
				,iIDUniteBEC					
			FROM 
				dbo.fntCONV_ObtenirListeConventions(@dtDateReleve,@iIDSouscripteur, @iIDBeneficiaire, @bListeComplete)
            
	END