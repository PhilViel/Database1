
/****************************************************************************************************
Code de service		:		dbo.fnCONV_ObtenirUnitesConvention
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
                SELECT * FROM dbo.fntCONV_ObtenirUnitesConvention(241420,NULL,'2008-12-31')

				-- Appel pour information générale des unitée
                SELECT * FROM dbo.fntCONV_ObtenirUnitesConvention(241420,NULL,NULL)

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
						2009-01-16					Fatiha Araar							Création de la fonction           
						2009-11-02					Jean-François Gauthier					Modification pour ajouter informations concernant les unités
						2009-11-03					Jean-François Gauthier					Ajout du ConventionID, du ModalID, du SaleSourceID, du PmtEndConnectIDen retour
****************************************************************************************************/

CREATE FUNCTION [dbo].[fntCONV_ObtenirUnitesConvention]
						(	
							    @iIdConvention INT,
								@dtDateDebut DATETIME,
								@dtDateFin DATETIME
						)
RETURNS  @tUnit TABLE 
					(
						UnitID						INT
						,UnitQty					MONEY
						,SignatureDate				DATETIME
						,InForceDate				DATETIME
						,IntReimbDate				DATETIME
						,TerminatedDate				DATETIME
						,LastDepositForDoc			DATETIME
						,IntReimbDateAdjust			DATETIME
						,dtFirstDeposit				DATETIME
						,dtCotisationEndDateAdjust	DATETIME
						,dtInforceDateTIN			DATETIME
						,SubscribeAmountAjustment	MONEY
						,ModalID					INT
						,ConventionID				INT
						,SaleSourceID				INT
						,PmtEndConnectID			INT
					)
BEGIN
	IF @dtDateFin IS NOT NULL		-- APPEL POUR RELEVÉ DE DÉPÔTS : JFG : 2009-11-02
		BEGIN
			INSERT INTO @tUnit
			(
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
			)
			SELECT 
				u.UnitID
				,u.UnitQty 
				,u.SignatureDate				
				,u.InForceDate				
				,u.IntReimbDate				
				,u.TerminatedDate				
				,u.LastDepositForDoc			
				,u.IntReimbDateAdjust			
				,u.dtFirstDeposit				
				,u.dtCotisationEndDateAdjust	
				,u.dtInforceDateTIN			
				,u.SubscribeAmountAjustment	
				,u.ModalID
				,@iIdConvention
				,u.SaleSourceID
				,u.PmtEndConnectID
			FROM 
				dbo.Un_Unit u
			WHERE 
				u.ConventionID = @iIdConvention
				AND 
				ISNULL(u.IntReimbDate,@dtDateFin)>= @dtDateFin	--Pas en rembourssement intgral à la date du relevé
				AND 
				u.InforceDate < @dtDateFin						--Exclus les unitiés entré en vigueur aprés la date du relevé

			UPDATE @tUnit
			SET UnitQty = T.UnitQty + V.UnitQty
			FROM 
				@tUnit T
				INNER JOIN(
							SELECT 
								U.UnitID,
								UnitQty = SUM(UR.UnitQty)
							FROM
								dbo.Un_Unit U
								INNER JOIN dbo.Un_UnitReduction UR 
									ON UR.UnitID = U.UnitID
							WHERE 
								U.conventionID = @iIdConvention
								AND 
								UR.ReductionDate >= @dtDateFin
						   GROUP BY 
								U.UnitID) V 
					ON V.UnitID = T.UnitID 
		END
	ELSE							-- APPEL POUR RECEVOIR L'ENSEMBLE DES INFORMATIONS DES UNITÉS D'UNE CONVENTION POUR LE BEC
		BEGIN
			INSERT INTO @tUnit
			(
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
			)
			SELECT 
				u.UnitID
				,u.UnitQty 
				,u.SignatureDate				
				,u.InForceDate				
				,u.IntReimbDate				
				,u.TerminatedDate				
				,u.LastDepositForDoc			
				,u.IntReimbDateAdjust			
				,u.dtFirstDeposit				
				,u.dtCotisationEndDateAdjust	
				,u.dtInforceDateTIN			
				,u.SubscribeAmountAjustment	
				,u.ModalID
				,@iIdConvention
				,u.SaleSourceID
				,u.PmtEndConnectID
			FROM 
				dbo.Un_Unit u
			WHERE 
				u.ConventionID	= @iIdConvention
				AND
				u.IntReimbDate	IS NULL
				AND 
				u.TerminatedDate IS NULL
			ORDER BY
				u.InForceDate ASC
		END
	
	RETURN
END
