
--
--Copyrights (c) 2008 Gestion Universitas inc.
--
--Code du service		: fntOPER_RechercherRendements
--Nom du service		: TBLOPER_RENDEMENTS (Rechercher les taux de rendement)
--But 				: Permet de rechercher des taux de rendement selon les critères reçus en paramètre
--Description			: Cette fonction est appelée pour chaque recherche effectuée dans les pages de "Gestion
--					  des taux de rendement". Pour chacun des rendements trouvés, ne retourner que le plus
--					  récent pour l'année et le mois sélectionnés.
--Facette				: OPER
--Référence			: Noyau-OPER
--
--Paramètres d’entrée	:	Paramètre					Obligatoire	Description
--						--------------------------	-----------	-----------------------------------------------------------------
--						VCLANGUE					Oui			Détermine la langue des informations retournées
--						SIANNEE						Non			Année de la date du calcul
--						TIMOIS						Non			Mois de la date du calcul
--						DTDATE_CALCUL_RENDEMENT		Non			Date du calcul du rendement
--						IID_TAUX_RENDEMENT			Non			Identifiant unique d’un taux de rendement
--						IID_RENDEMENT				Non			Identifiant unique du rendement
--						TIID_TYPE_RENDEMENT			Non			Type de rendement
--						cEtat						Non			Si le taux a été généré ou pas
--
--		  			
--
--Paramètres de sortie:	Table						Champ							Description
--		  				-------------------------	--------------------------- 	---------------------------------
--						tblOPER_Rendements			Tous les champs					Date du calcul pour la génération des rendements
--						tblOPER_TauxRendement		Tous les champs					Taux du rendement retourné
--						Un_Oper						OperTypeID						Type d’opération
--						MO_Human					FirstName + LastName			Prénom et nom de l’utilisateur
--						tblOPER_TypesRendement		vcCode_Rendement				Code du type de rendement
--													vcDescription				    Description du type de rendement
--													siOrdrePresentation				Ordre de présentation
--													siOrdreGenererRendement			Ordre de calcul
--						Un_Convention_Oper			SUM(ConventionOperAmount)		Montant généré dans Un_Convention_Oper
--						S/O							cEtat							Indique l’état du rendement
--																						S : Saisi
--																						M : Modifier
--																						C : Calculer
--						S/O							iCode_Retour					0 = Traitement réussi
--																					-1 = Erreur de traitement
--
--Exemple d'appel : RÉSULTATS AVEC LES DONNÉES DE TEST FONCTIONNEL
--				/* Retourne 9 enregistrements */
--				SELECT * FROM fntOPER_RechercherRendement('FRA',NULL,NULL,NULL,NULL,NULL,NULL,'C',1)
--
--				/* Retourne 6 enregistrements */
--				SELECT * FROM fntOPER_RechercherRendement('FRA',NULL,NULL,NULL,NULL,NULL,NULL,'S',1)
--
--				/* Retourne 1 enregistrement*/
--				SELECT * FROM fntOPER_RechercherRendement('FRA',NULL,NULL,NULL,NULL,NULL,NULL,'M',0) 
--
--				/* Tous les enregistrements de la table Taux_Rendement*/
--				SELECT * FROM fntOPER_RechercherRendement('FRA',NULL,NULL,NULL,NULL,NULL,NULL,NULL,null)
--
--
--Historique des modifications:
--		Date			Programmeur					Description						Référence
--		------------	-------------------------	---------------------------  	------------
--		2009-07-28		Jean-François Gauthier		Création de la fonction			1.4.1 dans le P171U - Services du noyau de la facette OPER - Opérations
--		2009-07-29		Jean-François Gauthier		Modification afin de retourner 
--													l'enregistrement le plus récent
--													en présence de plus d'un de rendement
--													Ajout du Order By
--		2009-09-03		Jean-François Gauthier		Ajout des champs siOrdrePresentation et siOrdreGenererRendement en sortiee
--		2009-09-09		Jean-François Gauthier		Passage à décimal(10,3)
--		2009-09-18		Jean-François Gauthier		Ajout du montant génération dans Un_ConventionOper
--		2009-09-21		Jean-François Gauthier		Modification au niveau de la sous-requête qui somme les montants de Un_ConventionOper
--		2009-09-29		Jean-François Gauthier		Remplacement du type TEXT par VARCHAR(MAX)
--		2010-02-09		Jean-François Gauthier		Remplacer les /* */ dans l'entête à la demande de Pierre-Luc
--		2010-04-14		Jean-François Gauthier		Modification afin d'améliorer la performance
--		2010-04-16		Jean-François Gauthier		Modification de la structure de traitement afin d'améliorer la performance
--		2010-04-21		Jean-François Gauthier		Ajout du paramètre @bAfficheMntOper
--		2010-12-14		Jean-François Gauthier		Modification afin d'améliorer la performance pour les états de type C. L'insertion s'effectue en 2 étapes dans @tHistoMontantOper.

CREATE FUNCTION dbo.fntOPER_RechercherRendement
	(
		@vcLangue					VARCHAR(3)	
		,@siAnnee					SMALLINT
		,@tiMois					TINYINT
		,@dtDate_Calcul_Rendement	DATETIME
		,@iID_Taux_Rendement		INT
		,@iID_Rendement				INT
		,@tiID_Type_Rendement		TINYINT
		,@cEtat						CHAR(1)
		,@bAfficheMntOper			BIT
	)
RETURNS @tRendement TABLE
						(
						iID_Taux_Rendement			INT
						,iID_Rendement				INT 
						,dtDate_Calcul_Rendement	DATETIME 
						,tiID_Type_Rendement		TINYINT
						,dtDate_Debut_Application	DATETIME
						,dtDate_Fin_Application		DATETIME		
						,dtDate_Operation			DATETIME 
						,dTaux_Rendement			DECIMAL(10,3) 
						,dtDate_Creation			DATETIME 
						,iID_Utilisateur_Creation	INT 
						,iID_Operation				INT 
						,mMontant_Genere			MONEY 
						,dtDate_Generation			DATETIME
						,tCommentaire				VARCHAR(MAX)
						,cID_OperType				CHAR(3)
						,vcPrenomNom				VARCHAR(85)
						,vcCode_Rendement			VARCHAR(3)
						,vcDescription				VARCHAR(100)
						,cEtat						CHAR(1)
						,iCode_Retour				INT
						,siOrdrePresentation		SMALLINT
						,siOrdreGenererRendement	SMALLINT
						,mMontantUnConventionOper	MONEY
						)
AS
	BEGIN
		-- VALIDATION DU PARAMÈTRE OBLIGATOIRE
		IF NULLIF(LTRIM(RTRIM(@vcLangue)),'') IS NULL
			BEGIN
				-- ON NE PEUT EFFECTUER LA RECHERCHE, ON RETOURNE DES NULL AVEC UN CODE DE RETOUR = -1
				INSERT INTO @tRendement
					(
					iID_Rendement,dtDate_Calcul_Rendement,tiID_Type_Rendement	
					,dtDate_Debut_Application,dtDate_Fin_Application,dtDate_Operation		
					,dTaux_Rendement,dtDate_Creation,iID_Utilisateur_Creation
					,iID_Operation,mMontant_Genere,dtDate_Generation,tCommentaire			
					,cID_OperType,vcPrenomNom,vcCode_Rendement,vcDescription			
					,cEtat,iCode_Retour,siOrdrePresentation,siOrdreGenererRendement,mMontantUnConventionOper			
					)
				SELECT
					NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL		
					,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL		
					,NULL,NULL,-1,NULL,NULL,NULL
			
			END
		ELSE
			BEGIN
				-- SÉLECTION DES VALEURS EN FONCTION DES CRITÈRES DE RECHERCHE PASSÉS EN PARAMÈTRE
				IF @cEtat IS NULL 
					BEGIN
						-- ON RETOURNE TOUS LES RENDEMENTS
						-- ON RETOURNE TOUS LES RENDEMENTS
						INSERT INTO @tRendement
						(
						iID_Taux_Rendement, iID_Rendement,dtDate_Calcul_Rendement,tiID_Type_Rendement	
						,dtDate_Debut_Application,dtDate_Fin_Application,dtDate_Operation		
						,dTaux_Rendement,dtDate_Creation,iID_Utilisateur_Creation
						,iID_Operation,mMontant_Genere,dtDate_Generation		
						,tCommentaire,cID_OperType,vcPrenomNom			
						,vcCode_Rendement,vcDescription
						,cEtat					
						,iCode_Retour
						,siOrdrePresentation
						,siOrdreGenererRendement
						,mMontantUnConventionOper
						)
						SELECT
							tr.iID_Taux_Rendement, r.iID_Rendement,r.dtDate_Calcul_Rendement,r.tiID_Type_Rendement	
							,tr.dtDate_Debut_Application,tr.dtDate_Fin_Application,tr.dtDate_Operation		
							,tr.dTaux_Rendement,tr.dtDate_Creation,tr.iID_Utilisateur_Creation
							,tr.iID_Operation,tr.mMontant_Genere,tr.dtDate_Generation		
							,tCommentaire,o.OperTypeID,ISNULL(h.FirstName, '') + ' ' + ISNULL(h.LastName, '')
							,tyr.vcCode_Rendement,tyr.vcDescription
							,Etat.cEtat				
							,1	
							,tyr.siOrdrePresentation
							,tyr.siOrdreGenererRendement
							,CASE
								WHEN @bAfficheMntOper = 0 THEN 0
								ELSE
									ISNULL(	(	
											SELECT SUM(cop.ConventionOperAmount) 
											FROM dbo.Un_ConventionOper cop 
											WHERE cop.OperID IN (SELECT tx.iID_Operation FROM dbo.tblOPER_TauxRendement tx WHERE tx.iID_Rendement = r.iID_Rendement)
											)	,0)
							 END
						FROM
							dbo.tblOPER_TypesRendement tyr
							INNER JOIN	dbo.tblOPER_Rendements r
								ON tyr.tiID_Type_Rendement = r.tiID_Type_Rendement
							INNER JOIN dbo.tblOPER_TauxRendement tr
								ON r.iID_Rendement = tr.iID_Rendement
							LEFT OUTER JOIN dbo.Un_Oper o
								ON o.OperID = tr.iID_Operation
							INNER JOIN dbo.Mo_Human h
								ON h.HumanID = tr.iID_Utilisateur_Creation
							INNER JOIN
							(
								SELECT
									tr.iID_Rendement 
									,AnneeRendement	= YEAR(r.dtDate_Calcul_Rendement)
									,MoisRendement	= MONTH(r.dtDate_Calcul_Rendement)
									,NbTaux			= COUNT(tr.iID_Taux_Rendement)
									,DateCreation	= MAX(tr.dtDate_Creation)
									,CASE 
										WHEN COUNT(tr.iID_Taux_Rendement) = 1 AND (SELECT txr.dtDate_Generation FROM dbo.tblOPER_TauxRendement txr WHERE txr.iID_Rendement = tr.iID_Rendement) IS NULL THEN 'S'
										WHEN COUNT(tr.iID_Taux_Rendement) = 1 AND (SELECT txr.dtDate_Generation FROM dbo.tblOPER_TauxRendement txr WHERE txr.iID_Rendement = tr.iID_Rendement) IS NOT NULL THEN 'C'
										WHEN COUNT(tr.iID_Taux_Rendement) > 1 AND EXISTS(SELECT 1 FROM dbo.tblOPER_TauxRendement txr WHERE txr.iID_Rendement = tr.iID_Rendement AND txr.dtDate_Generation IS NULL) THEN 'C'
										WHEN COUNT(tr.iID_Taux_Rendement) > 1 AND EXISTS(SELECT 1 FROM dbo.tblOPER_TauxRendement txr WHERE txr.iID_Rendement = tr.iID_Rendement AND txr.dtDate_Creation = MAX(tr.dtDate_Creation) AND txr.dtDate_Generation IS NOT NULL) THEN 'M'
									END AS cEtat
								FROM
									dbo.tblOPER_Rendements r
									INNER JOIN dbo.tblOPER_TauxRendement tr
										ON r.iID_Rendement = tr.iID_Rendement
								GROUP BY
									tr.iID_Rendement 
									,YEAR(r.dtDate_Calcul_Rendement)
									,MONTH(r.dtDate_Calcul_Rendement)
							) AS Etat
							ON tr.iID_Rendement = Etat.iID_Rendement
						WHERE
							YEAR(r.dtDate_Calcul_Rendement)		= ISNULL(@siAnnee,YEAR(r.dtDate_Calcul_Rendement))
							AND 
							MONTH(r.dtDate_Calcul_Rendement)	= ISNULL(@tiMois,MONTH(r.dtDate_Calcul_Rendement))
							AND
							r.dtDate_Calcul_Rendement			= ISNULL(@dtDate_Calcul_Rendement, r.dtDate_Calcul_Rendement)
							AND
							tr.iID_Taux_Rendement				= ISNULL(@iID_Taux_Rendement, tr.iID_Taux_Rendement)
							AND
							r.iID_Rendement						= ISNULL(@iID_Rendement, r.iID_Rendement)
							AND
							r.tiID_Type_Rendement				= ISNULL(@tiID_Type_Rendement, r.tiID_Type_Rendement)
							AND
							Etat.cEtat							= ISNULL(@cEtat, Etat.cEtat)
						ORDER BY
							tr.iID_Rendement
					END
				ELSE
					BEGIN
						IF @cEtat = 'S'
							BEGIN
								-- ON NE RETOURNE QUE LES PLUS RÉCENTS
								INSERT INTO @tRendement
								(
								iID_Taux_Rendement, iID_Rendement,dtDate_Calcul_Rendement,tiID_Type_Rendement	
								,dtDate_Debut_Application,dtDate_Fin_Application,dtDate_Operation		
								,dTaux_Rendement,dtDate_Creation,iID_Utilisateur_Creation
								,iID_Operation,mMontant_Genere,dtDate_Generation		
								,tCommentaire,cID_OperType,vcPrenomNom			
								,vcCode_Rendement,vcDescription,
								cEtat					
								,iCode_Retour			
								,siOrdrePresentation
								,siOrdreGenererRendement
								,mMontantUnConventionOper
								)
								SELECT
									tr.iID_Taux_Rendement, r.iID_Rendement,r.dtDate_Calcul_Rendement,r.tiID_Type_Rendement	
									,tr.dtDate_Debut_Application,tr.dtDate_Fin_Application,tr.dtDate_Operation		
									,tr.dTaux_Rendement,tr.dtDate_Creation,tr.iID_Utilisateur_Creation
									,tr.iID_Operation,tr.mMontant_Genere,tr.dtDate_Generation		
									,tCommentaire,o.OperTypeID,ISNULL(h.FirstName, '') + ' ' + ISNULL(h.LastName, '')
									,tyr.vcCode_Rendement,tyr.vcDescription
									,Etat.cEtat				
									,1	
									,tyr.siOrdrePresentation
									,tyr.siOrdreGenererRendement
									,
									CASE
										WHEN @bAfficheMntOper = 0 THEN 0
										ELSE
											ISNULL(	(	
														SELECT SUM(cop.ConventionOperAmount) 
														FROM dbo.Un_ConventionOper cop 
														WHERE cop.OperID IN (SELECT tx.iID_Operation FROM dbo.tblOPER_TauxRendement tx WHERE tx.iID_Rendement = r.iID_Rendement)
														)	,0)
									END
								FROM
									dbo.tblOPER_TypesRendement tyr
									INNER JOIN	dbo.tblOPER_Rendements r
										ON tyr.tiID_Type_Rendement = r.tiID_Type_Rendement
									INNER JOIN dbo.tblOPER_TauxRendement tr
										ON r.iID_Rendement = tr.iID_Rendement
									LEFT OUTER JOIN dbo.Un_Oper o
										ON o.OperID = tr.iID_Operation
									INNER JOIN dbo.Mo_Human h
										ON h.HumanID = tr.iID_Utilisateur_Creation
									INNER JOIN
									(
										SELECT
											tr.iID_Rendement 
											,AnneeRendement	= YEAR(r.dtDate_Calcul_Rendement)
											,MoisRendement	= MONTH(r.dtDate_Calcul_Rendement)
											,NbTaux			= COUNT(tr.iID_Taux_Rendement)
											,DateCreation	= MAX(tr.dtDate_Creation)
											,CASE 
												WHEN COUNT(tr.iID_Taux_Rendement) = 1 AND (SELECT txr.dtDate_Generation FROM dbo.tblOPER_TauxRendement txr WHERE txr.iID_Rendement = tr.iID_Rendement) IS NULL THEN 'S'
												WHEN COUNT(tr.iID_Taux_Rendement) = 1 AND (SELECT txr.dtDate_Generation FROM dbo.tblOPER_TauxRendement txr WHERE txr.iID_Rendement = tr.iID_Rendement) IS NOT NULL THEN 'C'
												WHEN COUNT(tr.iID_Taux_Rendement) > 1 AND EXISTS(SELECT 1 FROM dbo.tblOPER_TauxRendement txr WHERE txr.iID_Rendement = tr.iID_Rendement AND txr.dtDate_Generation IS NULL) THEN 'C'
												WHEN COUNT(tr.iID_Taux_Rendement) > 1 AND EXISTS(SELECT 1 FROM dbo.tblOPER_TauxRendement txr WHERE txr.iID_Rendement = tr.iID_Rendement AND txr.dtDate_Creation = MAX(tr.dtDate_Creation) AND txr.dtDate_Generation IS NOT NULL) THEN 'M'
											END AS cEtat
										FROM
											dbo.tblOPER_Rendements r
											INNER JOIN dbo.tblOPER_TauxRendement tr
												ON r.iID_Rendement = tr.iID_Rendement
										GROUP BY
											tr.iID_Rendement 
											,YEAR(r.dtDate_Calcul_Rendement)
											,MONTH(r.dtDate_Calcul_Rendement)
									) AS Etat
									ON tr.iID_Rendement = Etat.iID_Rendement
								WHERE
									YEAR(r.dtDate_Calcul_Rendement)		= ISNULL(@siAnnee,YEAR(r.dtDate_Calcul_Rendement))
									AND 
									MONTH(r.dtDate_Calcul_Rendement)	= ISNULL(@tiMois,MONTH(r.dtDate_Calcul_Rendement))
									AND
									r.dtDate_Calcul_Rendement			= ISNULL(@dtDate_Calcul_Rendement, r.dtDate_Calcul_Rendement)
									AND
									tr.iID_Taux_Rendement				= ISNULL(@iID_Taux_Rendement, tr.iID_Taux_Rendement)
									AND
									r.iID_Rendement						= ISNULL(@iID_Rendement, r.iID_Rendement)
									AND
									r.tiID_Type_Rendement				= ISNULL(@tiID_Type_Rendement, r.tiID_Type_Rendement)
									AND
									Etat.cEtat							= ISNULL(@cEtat, Etat.cEtat)
									AND
									tr.dtDate_Creation					= Etat.DateCreation  
								ORDER BY
									tr.iID_Rendement
							END
					
						IF @cEtat = 'C'
							BEGIN
								-- 2010-04-14 : JFG : Ajout de cette section pour tenter d'optimiser les performances
								DECLARE @tHistoMontantOper TABLE
											(
												iID_Rendement	INT			PRIMARY KEY
												,mMntOper		MONEY
											)


								IF @bAfficheMntOper = 1 
									BEGIN
--										INSERT INTO @tHistoMontantOper
--										(
--											iID_Rendement
--											,mMntOper
--										)				
--										SELECT
--											r.iID_Rendement,
--											ISNULL(SUM(cop.ConventionOperAmount),0)
--										FROM
--											dbo.tblOPER_Rendements r
--											INNER JOIN dbo.tblOPER_TauxRendement tr
--												ON r.iID_Rendement = tr.iID_Rendement
--											LEFT OUTER JOIN dbo.Un_ConventionOper cop 
--												ON tr.iID_Operation = cop.OperID
--										GROUP BY
--											r.iID_Rendement
									
										-- 2010-12-14 : Modification afin d'améliorer la performance. L'insertion s'effectue en 2 étapes dans @tHistoMontantOper.
										INSERT INTO @tHistoMontantOper
										(
											iID_Rendement
											,mMntOper
										)				
										SELECT
											r.iID_Rendement,
											ISNULL(SUM(cop.ConventionOperAmount),0)
										FROM
											dbo.tblOPER_Rendements r
											INNER JOIN dbo.tblOPER_TauxRendement tr
												ON r.iID_Rendement = tr.iID_Rendement
											INNER JOIN dbo.Un_ConventionOper cop 
												ON tr.iID_Operation = cop.OperID
										GROUP BY
											r.iID_Rendement

										INSERT INTO @tHistoMontantOper
										(
											iID_Rendement
											,mMntOper
										)				
										SELECT
											r.iID_Rendement,
											ISNULL(SUM(cop.ConventionOperAmount),0)
										FROM
											dbo.tblOPER_Rendements r
											INNER JOIN dbo.tblOPER_TauxRendement tr
												ON r.iID_Rendement = tr.iID_Rendement
											LEFT OUTER JOIN dbo.Un_ConventionOper cop 
												ON tr.iID_Operation = cop.OperID
										WHERE
											NOT EXISTS(SELECT 1 FROM @tHistoMontantOper t WHERE t.iID_Rendement = r.iID_Rendement)
										GROUP BY
											r.iID_Rendement
									END
								ELSE
									BEGIN
										INSERT INTO @tHistoMontantOper
										(
											iID_Rendement
											,mMntOper
										)				
										SELECT
											DISTINCT 
												r.iID_Rendement,
												0
										FROM
											dbo.tblOPER_Rendements r
											INNER JOIN dbo.tblOPER_TauxRendement tr
												ON r.iID_Rendement = tr.iID_Rendement
									END
											
								DECLARE @tTableRendement  TABLE
										(
											iID_Rendement	INT		PRIMARY KEY
											,AnneeRendement INT
											,MoisRendement	INT		
											,NbTaux			INT
											,DateCreation	DATETIME
											,cEtat			CHAR(1)
											
										)
					
								INSERT INTO @tTableRendement
								(
									iID_Rendement	
									,AnneeRendement 
									,MoisRendement	
									,NbTaux			
									,DateCreation	
									,cEtat			
								)
								SELECT
									tr.iID_Rendement 
									,AnneeRendement	= YEAR(r.dtDate_Calcul_Rendement)
									,MoisRendement	= MONTH(r.dtDate_Calcul_Rendement)
									,NbTaux			= COUNT(tr.iID_Taux_Rendement)
									,DateCreation	= MAX(tr.dtDate_Creation)
									,CASE 
										WHEN COUNT(tr.iID_Taux_Rendement) = 1 AND (SELECT txr.dtDate_Generation FROM dbo.tblOPER_TauxRendement txr WHERE txr.iID_Rendement = tr.iID_Rendement) IS NULL THEN 'S'
										WHEN COUNT(tr.iID_Taux_Rendement) = 1 AND (SELECT txr.dtDate_Generation FROM dbo.tblOPER_TauxRendement txr WHERE txr.iID_Rendement = tr.iID_Rendement) IS NOT NULL THEN 'C'
										WHEN COUNT(tr.iID_Taux_Rendement) > 1 AND EXISTS(SELECT 1 FROM dbo.tblOPER_TauxRendement txr WHERE txr.iID_Rendement = tr.iID_Rendement AND txr.dtDate_Generation IS NULL) THEN 'C'
										WHEN COUNT(tr.iID_Taux_Rendement) > 1 AND EXISTS(SELECT 1 FROM dbo.tblOPER_TauxRendement txr WHERE txr.iID_Rendement = tr.iID_Rendement AND txr.dtDate_Creation = MAX(tr.dtDate_Creation) AND txr.dtDate_Generation IS NOT NULL) THEN 'M'
									END AS cEtat
								FROM
									dbo.tblOPER_Rendements r
									INNER JOIN dbo.tblOPER_TauxRendement tr
										ON r.iID_Rendement = tr.iID_Rendement
								GROUP BY
									tr.iID_Rendement 
									,YEAR(r.dtDate_Calcul_Rendement)
									,MONTH(r.dtDate_Calcul_Rendement)
												
								-- **********************************************************************************
			
								-- ON NE RETOURNE QUE LES PLUS RÉCENTS
								INSERT INTO @tRendement
								(
								iID_Taux_Rendement, iID_Rendement,dtDate_Calcul_Rendement,tiID_Type_Rendement	
								,dtDate_Debut_Application,dtDate_Fin_Application,dtDate_Operation		
								,dTaux_Rendement,dtDate_Creation,iID_Utilisateur_Creation
								,iID_Operation,mMontant_Genere,dtDate_Generation		
								,tCommentaire,cID_OperType,vcPrenomNom			
								,vcCode_Rendement,vcDescription,
								cEtat					
								,iCode_Retour			
								,siOrdrePresentation
								,siOrdreGenererRendement
								,mMontantUnConventionOper
								)
								SELECT
									tr.iID_Taux_Rendement, r.iID_Rendement,r.dtDate_Calcul_Rendement,r.tiID_Type_Rendement	
									,tr.dtDate_Debut_Application,tr.dtDate_Fin_Application,tr.dtDate_Operation		
									,tr.dTaux_Rendement,tr.dtDate_Creation,tr.iID_Utilisateur_Creation
									,tr.iID_Operation,tr.mMontant_Genere,tr.dtDate_Generation		
									,tCommentaire,o.OperTypeID,ISNULL(h.FirstName, '') + ' ' + ISNULL(h.LastName, '')
									,tyr.vcCode_Rendement,tyr.vcDescription
									,Etat.cEtat				
									,1	
									,tyr.siOrdrePresentation
									,tyr.siOrdreGenererRendement
									,ISNULL(tmo.mMntOper,0) 
								FROM
									dbo.tblOPER_TypesRendement tyr
									INNER JOIN	dbo.tblOPER_Rendements r
										ON tyr.tiID_Type_Rendement = r.tiID_Type_Rendement
									INNER JOIN dbo.tblOPER_TauxRendement tr
										ON r.iID_Rendement = tr.iID_Rendement
									LEFT OUTER JOIN dbo.Un_Oper o
										ON o.OperID = tr.iID_Operation
									INNER JOIN dbo.Mo_Human h
										ON h.HumanID = tr.iID_Utilisateur_Creation
									INNER JOIN @tTableRendement AS Etat
										ON tr.iID_Rendement = Etat.iID_Rendement
									LEFT OUTER JOIN @tHistoMontantOper tmo
										ON tmo.iID_Rendement = r.iID_Rendement
								WHERE
									YEAR(r.dtDate_Calcul_Rendement)		= ISNULL(@siAnnee,YEAR(r.dtDate_Calcul_Rendement))
									AND 
									MONTH(r.dtDate_Calcul_Rendement)	= ISNULL(@tiMois,MONTH(r.dtDate_Calcul_Rendement))
									AND
									r.dtDate_Calcul_Rendement			= ISNULL(@dtDate_Calcul_Rendement, r.dtDate_Calcul_Rendement)
									AND
									tr.iID_Taux_Rendement				= ISNULL(@iID_Taux_Rendement, tr.iID_Taux_Rendement)
									AND
									r.iID_Rendement						= ISNULL(@iID_Rendement, r.iID_Rendement)
									AND
									r.tiID_Type_Rendement				= ISNULL(@tiID_Type_Rendement, r.tiID_Type_Rendement)
									AND
									Etat.cEtat							= ISNULL(@cEtat, Etat.cEtat)
									AND
									tr.dtDate_Creation					= Etat.DateCreation  
								ORDER BY
									tr.iID_Rendement
							END
							
					END
			END
		RETURN
	END
