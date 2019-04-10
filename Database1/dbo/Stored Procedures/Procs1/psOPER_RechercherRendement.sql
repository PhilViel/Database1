/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psOPER_RechercherRendement
Nom du service		: TBLOPER_RENDEMENTS (Rechercher les taux de rendement)
But 				: Permet de rechercher des taux de rendement selon les critères reçus en paramètre
Description			: Cette fonction est appelée pour chaque recherche effectuée dans les pages de "Gestion
					  des taux de rendement". Pour chacun des rendements trouvés, ne retourner que le plus
					  récent pour l'année et le mois sélectionnés.
Facette				: OPER
Référence			: Noyau-OPER

Paramètres d’entrée	:	Paramètre					Obligatoire	Description
						--------------------------	-----------	-----------------------------------------------------------------
						VCLANGUE					Oui			Détermine la langue des informations retournées
						SIANNEE						Non			Année de la date du calcul
						TIMOIS						Non			Mois de la date du calcul
						DTDATE_CALCUL_RENDEMENT		Non			Date du calcul du rendement
						IID_TAUX_RENDEMENT			Non			Identifiant unique d’un taux de rendement
						IID_RENDEMENT				Non			Identifiant unique du rendement
						TIID_TYPE_RENDEMENT			Non			Type de rendement
						cEtat						Non			Si le taux a été généré ou pas

		  			

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						tblOPER_Rendements			Tous les champs					Date du calcul pour la génération des rendements
						tblOPER_TauxRendement		Tous les champs					Taux du rendement retourné
						Un_Oper						OperTypeID						Type d’opération
						MO_Human					FirstName + LastName			Prénom et nom de l’utilisateur
						tblOPER_TypesRendement		vcCode_Rendement				Code du type de rendement
													vcDescription				    Description du type de rendement
													siOrdrePresentation				Ordre de présentation
													siOrdreGenererRendement			Ordre de calcul
						Un_Convention_Oper			SUM(ConventionOperAmount)		Montant généré dans Un_Convention_Oper
						S/O							cEtat							Indique l’état du rendement
																						S : Saisi
																						M : Modifier
																						C : Calculer
						S/O							iCode_Retour					0 = Traitement réussi
																					-1 = Erreur de traitement

Exemple d'appel : RÉSULTATS AVEC LES DONNÉES DE TEST FONCTIONNEL
				EXEC dbo.psOPER_RechercherRendement 'FRA',NULL,NULL,NULL,NULL,NULL,NULL,'C',1

				EXEC dbo.psOPER_RechercherRendement 'FRA',NULL,NULL,NULL,NULL,NULL,NULL,'S'

				EXEC dbo.psOPER_RechercherRendement 'FRA',NULL,NULL,NULL,NULL,NULL,NULL,'M' 



Historique des modifications:
		Date			Programmeur					Description						Référence
		------------	-------------------------	---------------------------  	------------
		2009-11-27		Jean-François Gauthier		Création du service
		2010-04-21		Jean-François Gauthier		Ajout du paramètre @bAfficheMntOper

****************************************************************************************************/
CREATE PROCEDURE dbo.psOPER_RechercherRendement
	(
		@vcLangue					VARCHAR(3)	
		,@siAnnee					SMALLINT
		,@tiMois					TINYINT
		,@dtDate_Calcul_Rendement	DATETIME
		,@iID_Taux_Rendement		INT
		,@iID_Rendement				INT
		,@tiID_Type_Rendement		TINYINT
		,@cEtat						CHAR(1)
		,@bAfficheMntOper			BIT			 = 1
	)
AS
	BEGIN
		SET NOCOUNT ON

		SELECT 
			iID_Taux_Rendement			
			,iID_Rendement				 
			,dtDate_Calcul_Rendement	 
			,tiID_Type_Rendement		
			,dtDate_Debut_Application	
			,dtDate_Fin_Application				
			,dtDate_Operation			 
			,dTaux_Rendement			
			,dtDate_Creation			 
			,iID_Utilisateur_Creation	 
			,iID_Operation				 
			,mMontant_Genere			 
			,dtDate_Generation			
			,tCommentaire				
			,cID_OperType				
			,vcPrenomNom				
			,vcCode_Rendement			
			,vcDescription				
			,cEtat						
			,iCode_Retour				
			,siOrdrePresentation		
			,siOrdreGenererRendement	
			,mMontantUnConventionOper	
		FROM 
			dbo.fntOPER_RechercherRendement(@vcLangue,@siAnnee,@tiMois,@dtDate_Calcul_Rendement,@iID_Taux_Rendement,@iID_Rendement,@tiID_Type_Rendement,@cEtat, ISNULL(@bAfficheMntOper,1))
	END
