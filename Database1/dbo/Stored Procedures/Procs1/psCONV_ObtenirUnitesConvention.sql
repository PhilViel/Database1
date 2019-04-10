
/****************************************************************************************************
Code de service		:		dbo.psCONV_ObtenirUnitesConvention
Nom du service		:		Obtenir les unités d’une convention 
But					:		Récupérer les unités d’une convention
Facette				:		P171U
Reférence			:		Relevé de dépôt
Parametres d'entrée :	Parametres					Description                              Obligatoire
                        ----------                  ----------------                         --------------                       
                        iIdConvention	            Identifiant unique de la convention      Oui
						dtDateDebut	                Date du début du relevé des cotisations	 Non			
						dtDateFin	                Date de fin du relevé des cotisations	 Non (	Si préciser alors les information pour le reléve de dépôt sont retournées. 
																									Si NULL, les infos générales des unitées de la conventions sont renvoyées POUR LE BEC SEULEMENT)



Exemple d'appel:
                -- Appel pour relevé de dépôt
                EXEC dbo.psCONV_ObtenirUnitesConvention 241420,NULL,'2008-12-31'

				-- Appel pour information générale des unitée
                EXEC dbo.psCONV_ObtenirUnitesConvention 241420,NULL,NULL

Parametres de sortie :  Table						Champs										Description
					    -----------------			---------------------------					--------------------------
                        Un_Unit						UnitID										ID unique du groupe d'unités.
													UnitQty										Nombre d'unités que possède actuellement le groupe d'unités.
													SignatureDate								Date de signature
													InForceDate									Date d'entrée en vigueur
													IntReimbDate								Date de remboursement intégral
													TerminatedDate								Date de résiliation
													LastDepositForDoc							Date de dernier dépôt qui doit apparaître sur le contrat et sur les relevés de dépôts.  Si elle est vide on affiche celle calculée dans les documents.
													IntReimbDateAdjust							Date ajustée de RI. Il ce peut qu''on est à modifier la date extimée de remboursement intégral pour certaines raisons (Changement de bénéficiaire, Cotisation pas complète suite à un retard, etc.)
													dtFirstDeposit								Date du premier dépôt, il s'agit de la plus petite date d''opération qui n''est pas un BEC et qui est lié par une cotisation au groupe d'unités. Le champ est calculé par un trigger sur Un_Cotisation et un autre sur Un_Oper
													dtCotisationEndDateAdjust					Ajustement de la date de fin de cotisation
													dtInforceDateTIN							Date d’entrée en vigueur minimale des opérations TIN
													SubscribeAmountAjustment					Ajustement au montant souscrit affiché sur le relevé de dépôt.  Cela ne change pas le montant souscrit, mais uniquement sont affichage sur le relevé de dépôt.  Le montant affiché dans le relevé est la somme de ce champs et du vrai montant souscrit
													ModalID										Identifiant unique des modalités
													ConventionID								Identifiant unique de la convention passée en paramètre
													SaleSourceID								ID unique de la source de vente (Un_SaleSource) du groupe d'unités. NULL = inconnu.
													PmtEndConnectID								ID unique de connexion de l'usager (Mo_Connect.ConnectID) qui a mis en arrêt de paiement forcé ce groupe d'unités. NULL = pas en arrêt de paiement forcé.  Ce champs a été créé pour gérer les cas de décès de souscripteur assuré par Universitas.  Gestion Universitas au lieu d'émettre un chèque pour le montant restant d'épargnes et de frais à cotiser, décende le montant souscrit au montant actuel cotisé.
					

                    
Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-11-27					Jean-François Gauthier					Création du service
****************************************************************************************************/

CREATE PROCEDURE [dbo].[psCONV_ObtenirUnitesConvention]
						(	
							    @iIdConvention INT,
								@dtDateDebut DATETIME,
								@dtDateFin DATETIME
						)
AS
	BEGIN
		SET NOCOUNT ON

		SELECT 
			UnitID						
			,UnitQty					
			,SignatureDate				
			,InForceDate				
			,IntReimbDate				
			,TerminatedDate				
			,LastDepositForDoc			
			,IntReimbDateAdjust			
			,dtFirstDeposit				
			,dtCotisationEndDateAdjust	
			,dtInforceDateTIN			
			,SubscribeAmountAjustment	
			,ModalID					
			,ConventionID				
			,SaleSourceID				
			,PmtEndConnectID			 
		FROM 
			dbo.fntCONV_ObtenirUnitesConvention(@iIdConvention,@dtDateDebut,@dtDateFin)
	END
