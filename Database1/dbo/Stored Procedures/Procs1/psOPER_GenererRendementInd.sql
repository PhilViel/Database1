
/****************************************************************************************************
Code de service		:	psOPER_GenererRendementInd
But					:	Générer le calcul des rendements TXI et RXI, suite à un transfert du régime REEEFLEX vers l'individuel
Description			:	
Facette				:	OPER
Référence			:	Noyau-OPER

Parametres d'entrée :	Parametres					Description									Obligatoire
                        ----------                  -----------------------------------------	-----------
						@iID_ConventionSource		Identifiant de la convention collective		OUI
						@iID_ConventionCible		Identifiant de la convention individuelle	OUI
						@iValider36Mois				Indicateur pour la validation des 36 mois	OUI
													1:Validation 0:Pas de validation

Parametres de sortie : Table				Champs							Description
					   -----------------	---------------------------		--------------------------
                       N/A					@iStatut						 0 : Réussi
																			-6 : Une erreur imprévue est survenue
																			-7 : Aucun rendement n'a été généré car la convention n'a pas au moins 36 mois d'opérations financières
																			-8 : Aucun rendement n'a été généré car le montant est négatif
											@vcCode_Message					Message de retour lorsque le traitement se termine à 0

Exemple d'appel:
			DECLARE @i INT
			EXECUTE @i = dbo.psOPER_GenererRendementInd 114404
			PRINT 'i = ' + CAST(@i AS VARCHAR(6))

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2011-02-14				Frédérick Thibault						Création de la procédure		1.3.2 dans le P171U - Services du noyau de la facette OPER - Opérations
						2013-01-09				Frédérick Thibault						Ajout du traitement par Fiducie et par délai de date RI estimée
						2013-09-13				Donald Huppé								Enlever la transaction (BEGIN TRANS - ROLLBACK - COMMIT) (ça cause des problèmes de transaction imbriquées).  
																										à la place retourner code d'erreur dans le CATCH, et sera rollbackcé par la sp appelante.
																										Créer l'UN_OPER et tblOPER_AssociationOperations dans le cas de rendement positif seulement
						2014-10-06				Pierre-Luc Simard						Retrait des frais pour les RIM
 ****************************************************************************************************/
CREATE PROCEDURE dbo.psOPER_GenererRendementInd
	(
	 @iID_ConventionSource	INT
	,@iID_ConventionCible	INT
	,@iValider36Mois		INT
	,@iOperRIO				INT
	,@vcTypeConversion		VARCHAR(3)
	,@vcCode_Message		VARCHAR(10) OUTPUT
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
			,@iStatut			INT

		-- DÉFINITION DES VARIABLES DE TRAITEMENT
		DECLARE
				 @iID_Taux_Rendement				INT
				,@dtDate_Operation					DATETIME
				,@dtDate_Calcul_Rendement			DATETIME
				,@dTaux_Rendement					DECIMAL(10,3)
				,@mRendementTotal_Epargne			MONEY
				,@mRendementTotal_Revenus			MONEY
				,@mMontantTotal_Genere				MONEY
				,@iAnneeATraiter					INT
				,@iMoisATraiter						INT
				,@iNbJourAnneeATraiter				INT
				,@iNbJourMoisATraiter				INT
				,@dtPremierJourDuMoisATraiter		DATETIME
				,@dtDernierJourDuMoisATraiter		DATETIME
				,@vcTypeOperationCategorie			VARCHAR(10)
				,@iConnectId						INT
				,@vcTypeOperation					VARCHAR(100)
				,@iID_OPER							INT
				,@vcCode_Rendement					VARCHAR(3)
				,@dtDate_Debut_Convention			DATETIME
				,@vcConventionOperTypeMntSouscrit	VARCHAR(5)
				,@tiValide							TINYINT

		-- DÉCLARATION DES TABLES TEMPORAIRES
		DECLARE @tblTransactionConvention	TABLE
												(
												 iJourOperation			INT
												,mMontantRI				MONEY
												)

		-- ARRÊT DU TRIGGER
		IF object_id('tempdb..#DisableTrigger') is null
			CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))

		INSERT INTO #DisableTrigger VALUES('TUn_ConventionOper')				
		INSERT INTO #DisableTrigger VALUES('TUn_Oper')				
		INSERT INTO #DisableTrigger VALUES('TUn_Oper_dtFirstDeposit')				

		BEGIN TRY
			
			SET @dtDate_Debut_Convention = (SELECT MIN(InForceDate)
											FROM dbo.Un_Unit 
											WHERE ConventionID = @iID_ConventionSource)
			
			IF @iValider36Mois = 0
				SET @tiValide = 1
			ELSE
				-- SI LA CONVENTION SOURCE (REEEFLEX) A PLUS DE 36 D'OPÉRATIONS FINANCIÈRES
				IF DATEDIFF(month, @dtDate_Debut_Convention, GETDATE()) >= 36
					SET @tiValide = 1
				ELSE
					SET @tiValide = 0
			
			IF @tiValide = 1
				BEGIN
				--print '@iStatut -1 = ' + cast (isnull(@iStatut,0) as varchar(10))
				-----------------
				--BEGIN TRANSACTION
				
				-----------------
				--print '@iStatut -2 = ' + cast (isnull(@iStatut,0) as varchar(10))
				-- RÉCUPÉRATION DU CONNECTID SYSTÈME À PARTIR DE LA TABLE UN_DEF
				SELECT
					@iConnectId = d.iID_Utilisateur_Systeme 
				FROM 
					dbo.Un_Def d

				-- INITIALISATION DES VARIABLES
				SELECT	 @mRendementTotal_Epargne = 0
						,@mRendementTotal_Revenus = 0
						,@vcTypeOperationCategorie = dbo.fnOPER_ObtenirTypesOperationCategorie('OPER_RENDEMENT_POSITIF')
						,@vcConventionOperTypeMntSouscrit = dbo.fnOPER_ObtenirTypesOperationConvCategorie('OPER_CALCUL_RENDEMENT_MNT_SOUSCRIT')
				
				---- SUPPRESSION DES TRANSACTIONS DE RENDEMENTS SUR LA CONVENTION
				--DELETE COP
				--FROM Un_ConventionOper COP
				--JOIN Un_Oper o ON o.OperID = COP.OperID 
				--WHERE	COP.ConventionId = @iID_ConventionCible
				--AND		COP.ConventionOperTypeID = @vcConventionOperTypeMntSouscrit --'INM'
				
				-- TRAITEMENT DES RENDEMENT
				DECLARE curRendement CURSOR LOCAL FAST_FORWARD
				FOR
					SELECT	 R.iID_Taux_Rendement
							,R.dtDate_Calcul_Rendement
							,R.dTaux_Rendement
							,iAnneeATraiter					= YEAR(R.dtDate_Calcul_Rendement)		-- ANNEE À TRAITER
							,iMoisATraiter					= MONTH(R.dtDate_Calcul_Rendement)		-- MOIS À TRAITER
							,iNbJourAnneeATraiter			=	CASE WHEN (
																		CASE	WHEN YEAR(R.dtDate_Calcul_Rendement) % 100 = 0 THEN YEAR(R.dtDate_Calcul_Rendement) % 400	-- VALIDATION DU SIÈCLE
																				ELSE YEAR(R.dtDate_Calcul_Rendement) % 4								
																		END
																	) = 0 THEN 366				-- BISEXTILE
																ELSE	
																		365						-- ANNÉE STANDARD
																END 
							,iNbJourMoisATraiter			= DAY(DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,R.dtDate_Calcul_Rendement)+1,0)))
							,dtPremierJourDuMoisATraiter	= CAST(LEFT(CONVERT(VARCHAR(10),R.dtDate_Calcul_Rendement,126),7) + CAST('-01' AS VARCHAR(3)) AS DATETIME)
							,dtDernierJourDuMoisATraiter	= CAST(CONVERT(VARCHAR(10),DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,R.dtDate_Calcul_Rendement)+1,0)),126) AS DATETIME)
							,iID_Connect					= 2
							,vcTypeOperation				=	CASE WHEN R.dTaux_Rendement > 0 THEN 
																		'OPER_RENDEMENT_POSITIF' 
																ELSE 
																		'OPER_RENDEMENT_NEGATIF' 
																END
							,R.vcCode_Rendement
					
					FROM dbo.fntOPER_RechercherRendement('FRA',NULL,NULL,NULL,NULL,NULL,NULL,'C',0) AS R
					
					WHERE	R.dtDate_Calcul_Rendement	<	GETDATE()
					AND		R.dtDate_Debut_Application	>=	@dtDate_Debut_Convention
					AND		R.vcCode_Rendement			IN	('TXI', 'RXI')
					
					ORDER BY R.dtDate_Calcul_Rendement
							,R.siOrdreGenererRendement		
				
				-- OUVERTURE DU CURSEUR DES RENDEMENTS
				OPEN curRendement
				FETCH NEXT FROM curRendement INTO
					@iID_Taux_Rendement
					,@dtDate_Calcul_Rendement
					,@dTaux_Rendement
					,@iAnneeATraiter
					,@iMoisATraiter
					,@iNbJourAnneeATraiter
					,@iNbJourMoisATraiter
					,@dtPremierJourDuMoisATraiter
					,@dtDernierJourDuMoisATraiter
					,@iConnectId
					,@vcTypeOperation
					,@vcCode_Rendement
				
				/*
				IF @@FETCH_STATUS = 0
					-- AJOUT D'UNE NOUVELLE OPÉRATION DE RENDEMENT IN+
					BEGIN
					
					---- Si opération de conversion a été effectuée on utilise cette opération - FT1
					--SET @iID_OPER = @iOperRIO
					
					--IF @iID_OPER IS NULL
					--	BEGIN
						
					--	SET @dtDate_Operation = GETDATE()
					--	EXECUTE @iID_OPER = dbo.SP_IU_UN_OPER @iConnectId, 0, @vcTypeOperationCategorie, @dtDate_Operation
						
					--	END
					SET @dtDate_Operation = GETDATE()
					EXECUTE @iID_OPER = dbo.SP_IU_UN_OPER @iConnectId, 0, 'IN+', @dtDate_Operation

					-- AJOUT D'UN LIEN D'ASSOCIATION ENTRE L'OPÉRATION DE CONVERSION ET DE RENDEMENT
					DECLARE @iID_Raison_Association INTEGER
					
					SET @iID_Raison_Association = (	SELECT iID_Raison_Association
													FROM tblOPER_RaisonsAssociation
													WHERE	vcCode_Raison = @vcTypeConversion
													)

					INSERT INTO tblOPER_AssociationOperations
							(
							 iID_Operation_Parent
							,iID_Operation_Enfant
							,iID_Raison_Association
							)
							
						VALUES
							(
							 @iOperRIO
							,@iID_OPER
							,@iID_Raison_Association
							)
					
					END
				*/
				WHILE @@FETCH_STATUS = 0
					BEGIN
					
					------------------------------------------------------------------------------------------------------------------------------
					-- DÉBUT DU CALCUL DES RENDEMENTS TXI ET RXI POUR LA CONVENTION
					------------------------------------------------------------------------------------------------------------------------------
					
					IF @vcCode_Rendement = 'TXI'
						BEGIN

						/*************
							ÉPARGNE 
						 ************/
						
						--  ****** DÉBUT DU TRAITEMENT POUR LES TRANSACTIONS ANTÉRIEURES AU PREMIER JOUR DU MOIS À TRAITER ********
						INSERT INTO @tblTransactionConvention	
							(
							 iJourOperation			
							,mMontantRI
							)
						SELECT 
							 0
							,SUM(ct.Cotisation)
						
						FROM dbo.Un_Unit u
						JOIN dbo.Un_Convention co	ON co.ConventionID = u.ConventionID
						JOIN dbo.Un_Modal m			ON m.ModalID = u.ModalID
						JOIN dbo.Un_Plan p			ON p.PlanID = m.PlanID
						JOIN dbo.Un_Cotisation ct	ON ct.UnitID = u.UnitID
						JOIN dbo.Un_Oper o			ON o.OperID = ct.OperID 
						
						WHERE	u.ConventionId = @iID_ConventionSource
						AND		o.OperDate < @dtPremierJourDuMoisATraiter -- modifié par JFA 2009-08-28	
						
						GROUP BY u.ConventionID
						
						HAVING SUM(ct.Cotisation) > 0
						
						--  ****** FIN DU TRAITEMENT POUR LES TRANSACTIONS EN DATE DU PREMIER JOUR DU MOIS À TRAITER ********

						--  ****** DÉBUT DU TRAITEMENT POUR LE MOIS À TRAITER *******	
						INSERT INTO @tblTransactionConvention	
									(
									 iJourOperation
									,mMontantRI
									)
						SELECT
									 DAY(o.OperDate)
									,SUM(ct.Cotisation)
						
						FROM dbo.Un_Unit u
						JOIN dbo.Un_Convention co	ON co.ConventionID = u.ConventionID
						JOIN dbo.Un_Modal m			ON m.ModalID = u.ModalID
						JOIN dbo.Un_Plan p			ON p.PlanID = m.PlanID
						JOIN dbo.Un_Cotisation ct	ON ct.UnitID = u.UnitID
						JOIN dbo.Un_Oper o			ON o.OperID = ct.OperID 
						
						WHERE	u.ConventionId = @iID_ConventionSource
						AND		o.OperDate BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter

						GROUP BY u.ConventionID
								,o.OperDate
						
-- DEBUG
--SELECT @dtDate_Calcul_Rendement, * FROM @tblTransactionConvention
						
						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mRendementTotal_Epargne = @mRendementTotal_Epargne + ISNULL((SELECT SUM(dbo.fnOPER_CalculerRendement
																										(
																										 tc.mMontantRI
																										,@dTaux_Rendement
																										,@iNbJourMoisATraiter
																										,tc.iJourOperation
																										,@iID_Taux_Rendement
																										,@iID_ConventionCible
																										,1
																										))
																					FROM @tblTransactionConvention tc), 0)

-- DEBUG
--SELECT @mRendementTotal_Epargne AS RendementEpargne
						
						-- SUPPRESSION DU CONTENU DE LA TABLE TEMPO
						DELETE FROM @tblTransactionConvention
						
						END
					
					IF @vcCode_Rendement = 'RXI'
						BEGIN

						/**************************************
							REVENUS ACCUMULÉS SUR L'ÉPARGNE 
						 **************************************/

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mRendementTotal_Revenus = @mRendementTotal_Revenus + ISNULL((SELECT SUM(dbo.fnOPER_CalculerRendement(@mRendementTotal_Epargne, @dTaux_Rendement, @iNbJourMoisATraiter, 0, @iID_Taux_Rendement, @iID_ConventionCible, 1))), 0)
						
-- DEBUG
--SELECT @mRendementTotal_Revenus AS RendementRevenus
						
						-- SUPPRESSION DU CONTENU DE LA TABLE TEMPO
						DELETE FROM @tblTransactionConvention
						
						END

					-- LECTURE DU PROCHAIN RENDEMENT
					FETCH NEXT FROM curRendement INTO
						@iID_Taux_Rendement
						,@dtDate_Calcul_Rendement
						,@dTaux_Rendement
						,@iAnneeATraiter
						,@iMoisATraiter
						,@iNbJourAnneeATraiter
						,@iNbJourMoisATraiter
						,@dtPremierJourDuMoisATraiter
						,@dtDernierJourDuMoisATraiter
						,@iConnectId
						,@vcTypeOperation
						,@vcCode_Rendement

					END
				
				-- FERMETURE ET DESTRUCTION DU CURSEUR DES RENDEMENTS
				CLOSE curRendement
				DEALLOCATE curRendement
				
				SET @mMontantTotal_Genere = @mRendementTotal_Epargne + @mRendementTotal_Revenus
				
				-- On retranche l'équivalent des frais de la convention au complet
				
				IF @vcTypeConversion = 'RIM'
					SELECT 
						@mMontantTotal_Genere = @mMontantTotal_Genere - ISNULL((SUM(U.UnitQty) * 200),0)
					FROM dbo.Un_Unit U 
					WHERE U.ConventionID = @iID_ConventionSource 
				
-- DEBUG
--SELECT @mRendementTotal_Epargne, @mRendementTotal_Revenus, @mMontantTotal_Genere

				-- SI LE MONTANT GÉNÉRÉ EST POSITIF ON CRÉÉ L'OPÉRATION DE RENDEMENT
				IF @mMontantTotal_Genere > 0
					BEGIN
					
					SET @dtDate_Operation = GETDATE()
					EXECUTE @iID_OPER = dbo.SP_IU_UN_OPER @iConnectId, 0, 'IN+', @dtDate_Operation

					-- AJOUT D'UN LIEN D'ASSOCIATION ENTRE L'OPÉRATION DE CONVERSION ET DE RENDEMENT
					DECLARE @iID_Raison_Association INTEGER
					
					SET @iID_Raison_Association = (	SELECT iID_Raison_Association
													FROM tblOPER_RaisonsAssociation
													WHERE	vcCode_Raison = @vcTypeConversion
													)

					INSERT INTO tblOPER_AssociationOperations
							(
							 iID_Operation_Parent
							,iID_Operation_Enfant
							,iID_Raison_Association
							)
							
						VALUES
							(
							 @iOperRIO
							,@iID_OPER
							,@iID_Raison_Association
							)

					-- INSERTION DU MONTANT GÉNÉRÉ TOTAL DANS LA TABLE DES OPÉRATIONS SUR CONVENTIONS
					INSERT INTO	dbo.Un_ConventionOper
								(
								 OperID
								,ConventionID
								,ConventionOperTypeID
								,ConventionOperAmount
								) 
					SELECT 
								@iID_Oper
								,@iID_ConventionCible
								,@vcConventionOperTypeMntSouscrit
								,@mMontantTotal_Genere
					
					--------------------
					--COMMIT TRANSACTION		
					--------------------
				
					SET @iStatut = 0
					
					END
				
				END --IF @tiValide = 1
			/*
			ELSE
				BEGIN
				
				SET @iStatut = -7
				
				END
			*/	
		END TRY
		
		BEGIN CATCH
			--print '@iStatut = ' + cast (isnull(@iStatut,0) as varchar(10))
			-- RÉCUPÉRATION DES INFORMATIONS CONCERNANT L'ERREUR
			SELECT										
					@vErrmsg		= REPLACE(ERROR_MESSAGE(),'%',' '),
					@iErrState		= ERROR_STATE(),
					@iErrSeverity	= ERROR_SEVERITY(),
					@iErrno			= ERROR_NUMBER();

			-- LA TRANSACTION EST TOUJOURS ACTIVE, ON PEUT FAIRE UN ROLLBACK
			/*
			IF (XACT_STATE()) = -1	
				BEGIN
					-----------------------
					ROLLBACK TRANSACTION
					-----------------------						
				END
			*/
			-- CONCATÉNATION DU NUMÉRO D'ERREUR INTERNE À SQL SERVEUR
			SET @vErrmsg = CAST(@iErrno AS VARCHAR(6)) + ' : ' + @vErrmsg
			RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState) WITH LOG

			SET @iStatut = -1
		
		END CATCH

		-- RÉACTIVATION DU TRIGGER
		Delete #DisableTrigger where vcTriggerName = 'TUn_ConventionOper'
		Delete #DisableTrigger where vcTriggerName = 'TUn_Oper'
		Delete #DisableTrigger where vcTriggerName = 'TUn_Oper_dtFirstDeposit'

		RETURN @iStatut

	END


