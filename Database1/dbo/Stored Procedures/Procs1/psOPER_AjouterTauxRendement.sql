/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psOPER_AjouterTauxRendement
Nom du service		: TBLOPER_RENDEMENTS 
But 				: Permet d'ajouter un taux de rendement selon les paramètres entrants.
Description			: Cette fonction est appelé lorsque l'utilisateur ajoute ou modifie un taux de rendement

Facette				: OPER
Référence			: Noyau-OPER

Paramètres d’entrée	:	Paramètre					Obligatoire	Description
						--------------------------	-----------	-----------------------------------------------------------------
						iID_Rendement							Identifiant unique du rendement
													Oui			Si cAction = 'M'
													Non			Si cAction = 'A'
						dtDate_Calcul_Rendement		Oui			Date de calcul du rendement
						tiID_Type_Rendement			Oui			Type de rendement
						dTaux_Rendement				Oui			Taux de rendement sur lequel sera basé la génération des rendements		
		  				iID_Utilisateur_Creation	Oui			Identifiant de l'utilisateur qui ajoute le rendement
						tCommentaire				Non			Commentaire de l'utilisateur suite à l'ajout ou à la modification du taux de rendement
						cAction						Oui			Permet de savoir si l'on ajoute (A) ou modifie (M) un taux de rendement 

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						N/A							iCode_Retour					0	= traitement réussi
																					-1	= erreur de traitement
Exemple d'appel : 
					DECLARE @i	INT
					EXECUTE @i = dbo.psOPER_AjouterTauxRendement NULL, '2009-08-06', 9, -9.99, 149463, NULL, 'A'
					PRINT @i

					DECLARE @i	INT
					EXECUTE @i = dbo.psOPER_AjouterTauxRendement 3833, '2009-01-31', 7, -1, 2, NULL, 'M'
					PRINT @i



Historique des modifications:
		Date			Programmeur					Description						Référence
		------------	-------------------------	---------------------------  	------------
		2009-08-07		Jean-François Gauthier		Création de la procédure		1.4.2 dans le P171U - Services du noyau de la facette OPER - Opérations
		2009-08-31		Jean-François Gauthier		Ajout de la gestion pour l'erreur potentielle 
													concernant l'index unique sur les 2 champs 
													dtDate_Calcul_Rendement et tiID_Type_Rendement
		2009-09-09		Jean-François Gauthier		Ajustement de la variable @dTaux_Rendement à décimal(10,3) 
		2009-09-17		Jean-François Gauthier		Ajout de la validation avec l'année financière pour les taux modifiés
													Ajout de la condition permettant de ne pas modifier un taux enfant si la date de calcul correspond 
													à la dernière date d'opération
		2009-09-22		Jean-François Gauthier		Modification pour modifier l’enfant du mois suivant et non celui du mois modifié car il y a aucune incidence pour le mois en cours
													lorsqu'on modifie un taux "parent" existant
		2009-09-24		Jean-François Gauthier		Modification afin d'insérer une nouvel enregistrement dans tblOper_TauxRendement
													pour les rendements subséquents à un taux modifié
													Ajout de la variable @tiID_Type_RendementEnfant
		2009-09-25		Jean-François Gauthier		Ajout d'un critère sur la date de calcul du rendement dans le where pour les taux modifiés
		2009-09-28		Jean-François Gauthier		Ajout de la condition AND trd.vcCode_Rendement_Enfant IS NULL
		2009-09-29		Jean-François Gauthier		Correction d'un problème de doublons lors de la modification d'un taux parent qui avait déjà été modifié dans le passé
		2010-01-19		Rémy Rouillard				Correctif pour éviter de recréer un taux qui n'est pas encore calculé. 
		2010-03-31		Éric Deshaies				Barrer l'option de modification de taux parce qu'incompatible avec le calcul de la JVM de l'application.
													Doit faire l'objet d'une correction.   L'utilisateur aurait le message "50010 : Paramètre(s) incorect(s)"
													s'il tente une modification de taux
*********************************************************************************************************************/
CREATE PROCEDURE dbo.psOPER_AjouterTauxRendement
	(
		@iID_Rendement				INT
		,@dtDate_Calcul_Rendement	DATETIME
		,@tiID_Type_Rendement		TINYINT
		,@dTaux_Rendement			DECIMAL(10,3)
		,@iID_Utilisateur_Creation	INT
		,@tCommentaire				VARCHAR(MAX)
		,@cAction					CHAR(1)
	)
AS
	BEGIN
		SET NOCOUNT ON
		SET XACT_ABORT ON

		-- DÉFINITION DES VARIABLES DE CONTRÔLE DE LA PROCÉDURE
		DECLARE
			@iErrno				INT
			,@iErrSeverity		INT
			,@iErrState			INT
			,@vErrmsg			VARCHAR(1024)
			,@iCode_Retour		INT

		-- DÉFINITION DES VARIABLES DE TRAITEMENT
		DECLARE
			@dtDateTransaction			DATETIME
			,@iID_NewRendement			INT			
			,@vcCode_Rendement_Enfant	VARCHAR(3)
			,@tiID_Type_RendementEnfant	INT
		
		BEGIN TRY

			-- VALIDATION DES PARAMÈTRES OBLIGATOIRES
			IF	@cAction						NOT IN ('A')--,'M')
				OR 	@iID_Utilisateur_Creation	IS NULL
				OR	@dTaux_Rendement			IS NULL
				OR	@tiID_Type_Rendement		IS NULL
				OR	@dtDate_Calcul_Rendement	IS NULL
				OR  (CASE 
						WHEN @cAction = 'M' THEN ISNULL(@iID_Rendement,0)
						ELSE 1
					 END) = 0
				BEGIN
					SELECT
						@vErrmsg		= '50010 : Paramètre(s) incorect(s)'
						,@iErrSeverity	= 10
						,@iErrState		= 1
						,@iCode_Retour = -1

					RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState)
					RETURN @iCode_Retour
				END			
			
			-----------------
			BEGIN TRANSACTION
			-----------------
			
			-- CONSERVE LA DATE DE TRAITEMENT
			SET @dtDateTransaction = GETDATE()

			IF @cAction = 'A'		-- AJOUT D'UN NOUVEAU TAUX
				BEGIN
					IF EXISTS(	SELECT 1 FROM dbo.tblOPER_Rendements 
								WHERE 
									dtDate_Calcul_Rendement = @dtDate_Calcul_Rendement
									AND
									tiID_Type_Rendement		= 	@tiID_Type_Rendement )
						BEGIN
							SELECT
								@vErrmsg		= '50020 : Rendement déjà existant pour la date de calcul spécifiée'
								,@iErrSeverity	= 10
								,@iErrState		= 1
								,@iCode_Retour = -1

							RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState)
							RETURN @iCode_Retour
						END
								
					INSERT INTO dbo.tblOPER_Rendements
					(
						dtDate_Calcul_Rendement
						,tiID_Type_Rendement
					)
					VALUES
					(
						@dtDate_Calcul_Rendement
						,@tiID_Type_Rendement
					)

					-- CONSERVE L'IDENTIFIANT DU NOUVEAU RENDEMENT INSÉRÉ
					SET @iID_NewRendement = SCOPE_IDENTITY()

					INSERT INTO dbo.tblOPER_TauxRendement
					(
						iID_Rendement
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
					)
					VALUES
					(
						@iID_NewRendement
						,@dtDateTransaction	
						,NULL
						,@dtDate_Calcul_Rendement
						,@dTaux_Rendement
						,GETDATE()
						,@iID_Utilisateur_Creation
						,NULL
						,NULL
						,NULL
						,@tCommentaire
					)
				END
			ELSE					-- MODIFICATION D'UN TAUX EXISTANT
				BEGIN
					-- VALIDATION SI LA DATE DE CALCUL DU TAUX MODIFIÉ EST À L'INTÉRIEUR DE L'ANNÉE 
					-- FINANCIÈRE EN COURS
					IF @dtDate_Calcul_Rendement NOT BETWEEN CAST(CAST((YEAR(GETDATE()) - 1) AS VARCHAR(4)) + '-01-01' AS DATETIME) AND CAST(CAST(YEAR(GETDATE()) AS VARCHAR(4)) + '-12-31' AS DATETIME)
						BEGIN
							SELECT
								@vErrmsg		= '50030 : Date de calcul incorrecte. Impossible de modifier un taux dans une année financière fermée !'
								,@iErrSeverity	= 10
								,@iErrState		= 1
								,@iCode_Retour = -1

							RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState)
							RETURN @iCode_Retour
						END

					/*
						Lors d'une modification, il faut vérifier si le rendement modifié (maître) est lié
						à un autre rendement (enfant). Par exemple si le rendement 2 (maître) est modifié, alors il
						faut automatiquement recalculer le taux 3 (enfant).
					*/

-- TRAITEMENT DU RENDEMENT MAITRE
					-- DÉSACTIVATION DU TAUX DE RENDEMENT EN COURS (dtDate_Fin_Application = NULL)
					UPDATE dbo.tblOPER_TauxRendement
					SET	
						dtDate_Fin_Application = DATEADD(ms, -2, @dtDateTransaction) 
					WHERE
						iID_Rendement  = @iID_Rendement
						AND
						dtDate_Fin_Application IS NULL

					-- INSÉRER UN NOUVEAU TAUX 
					INSERT INTO dbo.tblOPER_TauxRendement
					(
						iID_Rendement
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
					)
					VALUES
					(
						@iID_Rendement
						,@dtDateTransaction	
						,NULL
						,@dtDate_Calcul_Rendement
						,@dTaux_Rendement
						,GETDATE()
						,@iID_Utilisateur_Creation
						,NULL
						,NULL
						,NULL
						,@tCommentaire
					)

					-- INSERTION DES TAUX SUBSÉQUENTS LIÉS À CE RENDEMENT
					-- désactivation des vieux taux
					UPDATE dbo.tblOPER_TauxRendement
					SET	
						dtDate_Fin_Application = DATEADD(ms, -2, @dtDateTransaction) 
					WHERE
						dtDate_Fin_Application IS NULL 
						AND
						iID_Operation IS NOT NULL -- Ajout Remy 2010-01-19
						AND
						iID_Rendement  IN
										(
										SELECT
											rd.iID_Rendement
										FROM
											dbo.tblOPER_Rendements rd
										WHERE
											rd.dtDate_Calcul_Rendement	> @dtDate_Calcul_Rendement
											AND
											rd.tiID_Type_Rendement =	(
																		SELECT
																			tr.tiID_Type_Rendement
																		FROM
																			dbo.tblOPER_Rendements r
																			INNER JOIN dbo.tblOPER_TypesRendement tr
																				ON tr.tiID_Type_Rendement = r.tiID_Type_Rendement
																		WHERE
																			r.iID_Rendement = @iID_Rendement
																			AND 
																			tr.vcCode_Rendement_Enfant IS NULL
																		)
										)
						AND iID_Rendement <> @iID_Rendement

					-- insertion des taux modifiés subséquents
					INSERT INTO dbo.tblOPER_TauxRendement
					(
						iID_Rendement
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
					)
					SELECT
						DISTINCT 
							trd.iID_Rendement
							,@dtDateTransaction
							,NULL
							,trd.dtDate_Operation
							,trd.dTaux_Rendement
							,GETDATE()
							,@iID_Utilisateur_Creation
							,NULL
							,NULL
							,NULL
							,(SELECT TOP 1 tx.tCommentaire FROM dbo.tblOPER_TauxRendement tx WHERE tx.iID_Rendement = @iID_Rendement AND tx.dtDate_Fin_Application IS NOT NULL ORDER BY tx.dtDate_Fin_Application)
					FROM 
						dbo.tblOPER_TauxRendement trd
					WHERE
						trd.iID_Rendement IN 
											(
											SELECT
												rd.iID_Rendement
											FROM
												dbo.tblOPER_Rendements rd
											WHERE
												rd.dtDate_Calcul_Rendement	> @dtDate_Calcul_Rendement
												AND
												rd.tiID_Type_Rendement =	(
																			SELECT
																				tr.tiID_Type_Rendement
																			FROM
																				dbo.tblOPER_Rendements r
																				INNER JOIN dbo.tblOPER_TypesRendement tr
																					ON tr.tiID_Type_Rendement = r.tiID_Type_Rendement
																			WHERE
																				r.iID_Rendement = @iID_Rendement
																				AND
																				tr.vcCode_Rendement_Enfant IS NULL
																			)
											)
						AND
						trd.iID_Rendement <> @iID_Rendement
						AND
						iID_Operation IS NOT NULL -- Ajout Remy 2010-01-19
						
-- TRAITEMENT DU RENDEMENT ENFANT			
					-- RÉCUPÉRATION DU CODE DE RENDEMENT ENFANT
					SELECT
						@vcCode_Rendement_Enfant	= tr.vcCode_Rendement_Enfant
						,@tiID_Type_RendementEnfant = (SELECT trd.tiID_Type_Rendement FROM dbo.tblOPER_TypesRendement trd WHERE trd.vcCode_Rendement = tr.vcCode_Rendement_Enfant)
					FROM
						dbo.tblOPER_TypesRendement tr
						INNER JOIN dbo.tblOPER_Rendements r
							ON tr.tiID_Type_Rendement = r.tiID_Type_Rendement
					WHERE
						r.iID_Rendement = @iID_Rendement
					
					IF	@vcCode_Rendement_Enfant IS NOT NULL			-- LE TAUX MODIFIÉ A DONC DES ENFANTS
						AND 
						@dtDate_Calcul_Rendement <>	(
														SELECT MAX(t.dtDate_Operation) 
														FROM 
															dbo.tblOPER_TauxRendement t 
															INNER JOIN dbo.tblOPER_Rendements r
																ON t.iID_Rendement = r.iID_Rendement
														WHERE 
															r.tiID_Type_Rendement = @tiID_Type_RendementEnfant
													 )	-- LE DATE DE CALCUL N'EST PAS ÉGALE À LA DERNIERE DATE D'OPERATION DU TAUX
						BEGIN
							-- DÉSACTIVATION DES TAUX DE RENDEMENT EN COURS POUR LES TYPES ENFANTS CONCERNÉS
							UPDATE txr
							SET	
								txr.dtDate_Fin_Application = DATEADD(ms, -2, @dtDateTransaction) 
							FROM
								dbo.tblOPER_TypesRendement tr
								INNER JOIN dbo.tblOPER_Rendements r
									ON tr.tiID_Type_Rendement = r.tiID_Type_Rendement
								INNER JOIN dbo.tblOPER_TauxRendement txr
									ON r.iID_Rendement = txr.iID_Rendement
							WHERE
								txr.dtDate_Fin_Application IS NULL
								AND
								r.dtDate_Calcul_Rendement > @dtDate_Calcul_Rendement
								AND
								tr.vcCode_Rendement = @vcCode_Rendement_Enfant
								AND
								txr.iID_Operation IS NOT NULL -- Ajout Remy 2010-01-19

							-- INSERTION DES TAUX À RECALCULER
							INSERT INTO dbo.tblOPER_TauxRendement
							(
								iID_Rendement
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
							)
							SELECT
								r.iID_Rendement
								,@dtDateTransaction	
								,NULL
								,r.dtDate_Calcul_Rendement
								,txr.dTaux_Rendement
								,GETDATE()
								,@iID_Utilisateur_Creation
								,NULL
								,NULL
								,NULL
								,@tCommentaire
							FROM
								dbo.tblOPER_TypesRendement tr
								INNER JOIN dbo.tblOPER_Rendements r
									ON tr.tiID_Type_Rendement = r.tiID_Type_Rendement
								INNER JOIN dbo.tblOPER_TauxRendement txr
									ON r.iID_Rendement = txr.iID_Rendement
							WHERE
								txr.dtDate_Fin_Application = DATEADD(ms, -2, @dtDateTransaction) -- ON REPREND JUSTE LES TAUX QUE L'ON VIENT DE METRE À JOUR
								AND
								tr.vcCode_Rendement = @vcCode_Rendement_Enfant
								AND
								r.dtDate_Calcul_Rendement > @dtDate_Calcul_Rendement
						END
				END
			------------------
			COMMIT TRANSACTION
			------------------
			SET @iCode_Retour = 0
		END TRY
		BEGIN CATCH
			-- RÉCUPÉRATION DES INFORMATIONS CONCERNANT L'ERREUR
			SELECT										
					@vErrmsg		= REPLACE(ERROR_MESSAGE(),'%',' ')
					,@iErrState		= ERROR_STATE()
					,@iErrSeverity	= ERROR_SEVERITY()
					,@iErrno			= ERROR_NUMBER()

			-- LA TRANSACTION EST TOUJOURS ACTIVE, ON PEUT FAIRE UN ROLLBACK
			IF (XACT_STATE()) = -1	
				BEGIN
					-----------------------
					ROLLBACK TRANSACTION
					-----------------------						
				END

			-- CONCATÉNATION DU NUMÉRO D'ERREUR INTERNE À SQL SERVEUR
			SET @vErrmsg = CAST(@iErrno AS VARCHAR(6)) + ' : ' + @vErrmsg
			RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState)	

			SET @iCode_Retour = -1
		END CATCH

		RETURN @iCode_Retour
	END
