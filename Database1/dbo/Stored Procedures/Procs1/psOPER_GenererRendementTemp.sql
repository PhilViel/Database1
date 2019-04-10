/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************   */

/****************************************************************************************************
Code de service		:	psOPER_GenererRendementTemp
Nom du service		:	TBLOPER_RENDEMENTS (Rechercher les taux de rendement)	
But					:	Générer le calcul des rendements	
Description			:	Pour une date de calcul, le service permet de générer les rendements, selon
						les types de rendement saisis
Facette				:	OPER
Référence			:	Noyau-OPER

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@iID_Convention				Identifiant de la convention
						@bActiveDebug				Flag qui permet d'activer le débogage 
													qui retourne le contenu de la table temporaire 
													à chaque étape (type de rendement) de traitement
						@cEtat						Statut des taux à modifier (S = Nouveau, C= Modifié)


Parametres de sortie : Table				Champs							Description
					   -----------------	---------------------------		--------------------------
                       N/A					@iStatut						0 : Réussi
																			-1 : Une erreur est survenue à la désactivation du déclencheur de la table des opérations sur conventions
																			-2 : Une erreur est survenue lors de la création de l’opération
																			-3 : Une erreur est survenue lors de la génération du calcul du rendement @1
																			-4 : Erreur lors de l’ajout dans la table « un_conventionOper » pour le rendement @1
																			-5 : Une erreur est survenue  lors de la mise à jour de la table « tblOper_TauxRendement  » pour le rendement @1
																			-6 : Une erreur imprévue est survenue

Exemple d'appel:
			DECLARE @i INT
			EXECUTE @i = dbo.psOPER_GenererRendementTemp 114404, 'S', 1
			PRINT 'i = ' + CAST(@i AS VARCHAR(6))

			DECLARE @i INT
			EXECUTE @i = dbo.psOPER_GenererRendementTemp NULL, 'C', 0
			PRINT 'i = ' + CAST(@i AS VARCHAR(6))


Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-07-28					Jean-François Gauthier					Création de la procédure			1.3.2 dans le P171U - Services du noyau de la facette OPER - Opérations
						2009-08-25					Jean-Francois Arial						Remplacer la date de prospectus par un paramètre applicatif
						2009-08-25					Jean-Francois Arial						Ajustement des conditions des dates pour les RIO
						2009-08-27					Jean-Francois Arial						Ajout des conditions sur le code de rendement pour les 8 types
						2009-08-28					Jean-Francois Arial						Changement des conditions sur la date de prospectus et ajustement sur la création d'une opération
						2009-08-31					Jean-François Gauthier					Récupération du ConnectID à partir de la table UN_DEF
																							Modifications en fonction des nouveaux éléments du P171	: points 1.3.2.3.1 à 1.3.2.3.9	
						2009-09-02					Jean-François Gauthier					Correction d'un bug du côté de l'initialisation de la variable @dtDateOperation dans la section 1.3.2.3.1
																							Modification du code de rendement pour le point 1.3.2.3.2
						2009-09-03					Jean-François Gauthier					Ajout de mMontantRI2 pour le calcul du type 1.3.2.3.2
																							Ajout du du champ siOrdreGenererRendement dans le select du cursor
						2009-09-09					Jean-François Gauthier					Ajustement de la variable @dTaux_Rendement à décimal(10,3)
																							Optimisation des requêtes
																							Modification au point 1.3.2.3.5 et 1.3.2.3.6 : les transaction IQI
																							passe de l'un à l'autre
						2009-09-10					Jean-François Gauthier					Transfert du traitement AIN du point 1.3.2.3.1 vers le point 1.3.2.3.2
						2009-09-11					Jean-François Gauthier					Modification du point 1.3.2.3.6 : INSERTION DU MONTANT IQI DANS III 
						2009-09-17					Jean-François Gauthier					Élimination du code se référant aux transactions 'AIN'
																							Ajout du traitement pour les taux modifiés
						2009-09-22					Jean-François Gauthier					Ajout de la validation du iID_OPER dans le WHERE des DELETE sur Un_ConventionOPER
																							car dans la même génération, on pouvait effacer des transactions générées dans un taux
																							précédents si le type d'opération est le même (cas 1.3.2.3.7 et 1.3.2.3.8)
																							Modification du WHERE des DELETE pour les taux .7 et .8 afin de passer par la table tblOPER_TauxRendement
																							pour supprimer dans Un_ConventionOPER
						2009-09-23					Jean-François Gauthier					Modification pour l'obtention d'un OperID pour chaque taux traité
																							Modification de la requête de suppression
						2009-09-24					Jean-François Gauthier					Correction dans la requête de génération des taux modifiés
						2009-10-30					Jean-François Gauthier					Élimination de p.PlanTypeID = 'IND' pour le taux .8
						2009-11-03					Jean-François Gauthier					Modification pour la génération des nouveaux rendements en fonction de leur statut
																							La table @tConventionState a été transféré dans le curseur.
																							Ajustement des requêtes de certains taux modifiés qui référençaient des tables non utilisées
						2009-11-04					Jean-François Gauthier					Correction suite aux modifications du 2009-11-03
						2009-12-17					Jean-François Gauthier					Ajout du code pour transférer les rendements générés vers des conventions individuelles
						2010-01-07					Jean-François Gauthier					Modification du ConnectID utilisé lors de l'appel à psOPER_CreerOperationRIO
						2010-01-08					Jean-François Gauthier					Modification afin de ne pas insérer de montant = o dans Un_ConventionOper
																							Modification afin de pas traiter de montant < 0 pour la période antérieure au mois traité
						2010-01-10					Rémy Rouillard			Modification du code IQI pour IIQ dans la section 1.3.2.3.6
						2010-04-19					Éric Deshaies				Faire le retransfert RIO uniquement s'il y a un solde
																							positif.  Analyse de retransfert des soldes négatifs à
																							faire plus tard.
						2010-04-21					Jean-François Gauthier	Modification afin d'effectuer le retransfert RIO uniquement dans les cas de taux modifiés
																								ou de l'ajout de nouveaux taux
																							Modification à l'appel de la fonction fntOPER_RechercherRendement pour lui ajouter
																							le paramètre @bAfficher
						2010-08-18					Éric Deshaies				Empêcher de faire un retransfert RIO s'il y a un compte en perte.
																							Détacher le retransfert RIO du traitement principal en cas d'erreur dans un RIO.
						2010-10-04					Steve Gouin				Gestion des disable trigger par #DisableTrigger
						2011-03-17					Frédérick Thibault		Abolition de la validation des montants > 0.00 pour calculer du rendement.
						2011-04-28					Frederick Thibault		Adaptation de l'appel à psOPER_CreerOperationRIO pour projet Prospectus 2010-2011 (FT1)
						2014-11-20					Pierre-Luc Simard		Ne devrait plus être appelée donc on l'a fait planter

N.B.
	Consulter TT_UN_MonthlyConventionInterest pour avoir une idée du traitement
 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_GenererRendementTemp]
	(
	@iID_Convention INT
	,@cEtat			CHAR(1)
	,@bActiveDebug	BIT	= 0
	)
AS
	BEGIN
	SELECT 0/0
/*		SET NOCOUNT ON	
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
				@iID_Taux_Rendement					INT
				,@dtDate_Calcul_Rendement			DATETIME
				,@dTaux_Rendement					DECIMAL(10,3)
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
				,@dtStartDateForIntAfterEstimatedRI	DATETIME	-- Date de début pour l'intérêt après l'estimé du RI
				,@iMonthNoIntAfterEstimatedRI		INT			-- Mois pour l'intérêt après l'estimé du RI
				,@dtMinOperDate						DATETIME
				,@dtDateOperation					DATETIME
				,@dtDateProspectus					DATETIME
				,@vcCode_Rendement					VARCHAR(3)
				,@dtMaxDateGeneration				DATETIME
				,@bDataPresent						BIT			-- 2010-04-21 : JFG :	Ajout de cette variable pour contrôler si 
																--						des données sont présentes dans le curseur				
				,@vcCode_Message					VARCHAR(10) -- FT1

		-- DÉCLARATION DES TABLES TEMPORAIRES
		DECLARE @tblUniteEligible			TABLE	
												(
												iID_Unit				INT			
												,dtDateEstimeRI			DATETIME
												,dtDateDebutIntRI		DATETIME
												)

		DECLARE @tblTransactionConvention	TABLE
												(
												iID_Convention			INT 
												,iJourOperation			INT
												,mMontantRI				MONEY
												,mMontantRI2			MONEY
												,mMontantCESG			MONEY
												,mMontantACESG			MONEY
												,mMontantCLB			MONEY
												,mMontantIST			MONEY
												,mMontantCBQ			MONEY
												,mMontantMMQ			MONEY
												,mMontantIQI			MONEY
												,mMontantMIM			MONEY
												,mMontantICQ			MONEY
												,mMontantIMQ			MONEY
												,mMontantIII			MONEY
												,mMontantITR			MONEY
												,mMontantIIQ			MONEY	
												)
		BEGIN TRY
			-- ARRÊT DU TRIGGER
			--ALTER TABLE dbo.Un_ConventionOper	DISABLE TRIGGER TUn_ConventionOper
			--ALTER TABLE dbo.Un_Oper				DISABLE TRIGGER TUn_Oper
			--ALTER TABLE dbo.Un_Oper				DISABLE TRIGGER TUn_Oper_dtFirstDeposit

			IF object_id('tempdb..#DisableTrigger') is null
				CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))

			INSERT INTO #DisableTrigger VALUES('TUn_ConventionOper')				
			INSERT INTO #DisableTrigger VALUES('TUn_Oper')				
			INSERT INTO #DisableTrigger VALUES('TUn_Oper_dtFirstDeposit')				

			-----------------
			BEGIN TRANSACTION
			-----------------

			--- RÉCUPÉRATION DU CONNECTID SYSTÈME À PARTIR DE LA TABLE UN_DEF
			SELECT
				@iConnectId = d.iID_Utilisateur_Systeme 
			FROM 
				dbo.Un_Def d

			-- RECHERCHE DES CODE D'OPÉRATIONS
			DECLARE
				@vcConventionOperTypeSCEE					VARCHAR(5)
				,@vcConventionOperTypeSCEEPlus				VARCHAR(5)
				,@vcConventionOperTypeBEC					VARCHAR(5)
				,@vcConventionOperTypeMntSouscrit			VARCHAR(5)
				,@vcConventionOperTypeRendement_III			VARCHAR(5)
				,@vcConventionOperTypeRendement_MIM			VARCHAR(5)
				,@vcConventionOperTypeRendement_ICQ			VARCHAR(5)
				,@vcConventionOperTypeRendement_IMQ			VARCHAR(5)
				,@vcConventionOperTypeRendement_IQI			VARCHAR(5)
				,@vcConventionOperTypeRendement_PCEE_TIN	VARCHAR(5)
				,@vcConventionOperTypeRendement_CBQ			VARCHAR(5)
				,@vcConventionOperTypeRendement_MMQ			VARCHAR(5)
				,@vcConventionOperTypeRendement_IIQ			VARCHAR(5)
				,@vcConventionOperTypeRendement_TIN			VARCHAR(5)

			SELECT
				@vcConventionOperTypeSCEE					= dbo.fnOPER_ObtenirTypesOperationConvCategorie('OPER_CALCUL_RENDEMENT_SCEE')
				,@vcConventionOperTypeSCEEPlus				= dbo.fnOPER_ObtenirTypesOperationConvCategorie('OPER_CALCUL_RENDEMENT_SCEE+')
				,@vcConventionOperTypeBEC					= dbo.fnOPER_ObtenirTypesOperationConvCategorie('OPER_CALCUL_RENDEMENT_BEC')
				,@vcConventionOperTypeMntSouscrit			= dbo.fnOPER_ObtenirTypesOperationConvCategorie('OPER_CALCUL_RENDEMENT_MNT_SOUSCRIT')
				,@vcConventionOperTypeRendement_III			= dbo.fnOPER_ObtenirTypesOperationConvCategorie('OPER_CALCUL_RENDEMENT_III')
				,@vcConventionOperTypeRendement_MIM			= dbo.fnOPER_ObtenirTypesOperationConvCategorie('OPER_CALCUL_RENDEMENT_MIM')	
				,@vcConventionOperTypeRendement_ICQ			= dbo.fnOPER_ObtenirTypesOperationConvCategorie('OPER_CALCUL_RENDEMENT_ICQ')
				,@vcConventionOperTypeRendement_IMQ			= dbo.fnOPER_ObtenirTypesOperationConvCategorie('OPER_CALCUL_RENDEMENT_IMQ')
				,@vcConventionOperTypeRendement_IQI			= dbo.fnOPER_ObtenirTypesOperationConvCategorie('OPER_CALCUL_RENDEMENT_IQI')
				,@vcConventionOperTypeRendement_PCEE_TIN	= dbo.fnOPER_ObtenirTypesOperationConvCategorie('OPER_CALCUL_RENDEMENT_PCEE_TIN')
				,@vcConventionOperTypeRendement_CBQ			= dbo.fnOPER_ObtenirTypesOperationConvCategorie('OPER_CALCUL_RENDEMENT_CBQ')
				,@vcConventionOperTypeRendement_MMQ			= dbo.fnOPER_ObtenirTypesOperationConvCategorie('OPER_CALCUL_RENDEMENT_MMQ')
				,@vcConventionOperTypeRendement_IIQ			= dbo.fnOPER_ObtenirTypesOperationConvCategorie('OPER_CALCUL_RENDEMENT_IIQ')
				,@vcConventionOperTypeRendement_TIN			= dbo.fnOPER_ObtenirTypesOperationConvCategorie('OPER_CALCUL_RENDEMENT_TIN')

			--	CRÉATION D'UNE TABLE TEMPORAIRE POUR LES STATUTS DE CONVENTION
			DECLARE	@tConventionState	TABLE
											(
											ConventionID	INT			PRIMARY KEY CLUSTERED
											,MostRecentDate	DATETIME
											)

/*	MIS EN COMMENTAIRE LE 2009-11-03
			INSERT INTO @tConventionState
			(
			ConventionID	
			,MostRecentDate	
			)
			SELECT
				ccvt.ConventionID, MAX(ccvt.StartDate) AS MostRecentDate
			FROM
				dbo.Un_ConventionConventionState ccvt
				INNER JOIN	dbo.Un_ConventionState cvt
					ON cvt.ConventionStateID = ccvt.ConventionStateID 
			WHERE
				ccvt.ConventionID = ISNULL(@iID_Convention, ccvt.ConventionID)
			GROUP BY
				ccvt.ConventionID
*/

			-- CRÉATION D'UNE TABLE TEMPORAIRE POUR LES RIO
			DECLARE	@tRIO	TABLE
								(
								iID_Convention_Destination	INT	PRIMARY KEY CLUSTERED
								)
			
			INSERT INTO @tRIO
			(
			iID_Convention_Destination
			)
			SELECT 
				DISTINCT rio.iID_Convention_Destination
			FROM 
				dbo.tblOPER_OperationsRIO rio
			WHERE 
				rio.iID_Convention_Destination = ISNULL(@iID_Convention, rio.iID_Convention_Destination)
				AND 
				rio.bRIO_Annulee = 0
				AND 
				rio.bRIO_QuiAnnule = 0
											
			--Initialisation des variables JFA 2009-08-28
			SET @iID_OPER = 0

			-- TRAITEMENT DES RENDEMENT
			IF @cEtat = 'S'		-- NOUVEAUX RENDEMENTS
				BEGIN
					DECLARE curRendement CURSOR LOCAL FAST_FORWARD
					FOR
						SELECT 
							r.iID_Taux_Rendement
							,r.dtDate_Calcul_Rendement
							,r.dTaux_Rendement
							,iAnneeATraiter				= YEAR(r.dtDate_Calcul_Rendement)		-- ANNEE À TRAITER
							,iMoisATraiter				= MONTH(r.dtDate_Calcul_Rendement)		-- MOIS À TRAITER
							,iNbJourAnneeATraiter		= CASE WHEN (
																		CASE	WHEN YEAR(r.dtDate_Calcul_Rendement) % 100 = 0 THEN YEAR(r.dtDate_Calcul_Rendement) % 400	-- VALIDATION DU SIÈCLE
																				ELSE YEAR(r.dtDate_Calcul_Rendement) % 4								
																		END
																	) = 0 THEN 366				-- BISEXTILE
																ELSE	
																		365						-- ANNÉE STANDARD
														  END 
							,iNbJourMoisATraiter			= DAY(DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,r.dtDate_Calcul_Rendement)+1,0)))
							,dtPremierJourDuMoisATraiter	= CAST(LEFT(CONVERT(VARCHAR(10),r.dtDate_Calcul_Rendement,126),7) + CAST('-01' AS VARCHAR(3)) AS DATETIME)
							,dtDernierJourDuMoisATraiter	= CAST(CONVERT(VARCHAR(10),DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,r.dtDate_Calcul_Rendement)+1,0)),126) AS DATETIME)
							,vcTypeOperationCategorie	= CASE WHEN r.dTaux_Rendement > 0 THEN dbo.fnOPER_ObtenirTypesOperationCategorie('OPER_RENDEMENT_POSITIF') ELSE dbo.fnOPER_ObtenirTypesOperationCategorie('OPER_RENDEMENT_NEGATIF') END
							,iID_Connect				= 2
							,vcTypeOperation			= CASE WHEN r.dTaux_Rendement > 0 THEN 'OPER_RENDEMENT_POSITIF' ELSE 'OPER_RENDEMENT_NEGATIF' END
							,r.vcCode_Rendement
							,dtMaxDateGeneration		= NULL
						FROM 
							dbo.fntOPER_RechercherRendement('FRA',NULL,NULL,NULL,NULL,NULL,NULL,@cEtat,0) AS r
						WHERE
							r.dtDate_Calcul_Rendement < GETDATE()
						ORDER BY
							r.dtDate_Calcul_Rendement, r.siOrdreGenererRendement		
				END
			ELSE			-- RENDEMENTS MODIFIÉS (@cEtat = 'C')
				BEGIN
					DECLARE @dtMaxDateGenerationCurseur DATETIME -- Ajout du 2009-09-21 JFG 
					SET @dtMaxDateGenerationCurseur = (SELECT DATEADD(dd,1,MAX(t.dtDate_Generation)) FROM dbo.tblOPER_TauxRendement t WHERE t.dtDate_Generation IS NOT NULL)

					DECLARE curRendement CURSOR LOCAL FAST_FORWARD
					FOR
						SELECT 
							r.iID_Taux_Rendement
							,r.dtDate_Calcul_Rendement
							,r.dTaux_Rendement
							,iAnneeATraiter				= YEAR(r.dtDate_Calcul_Rendement)		-- ANNEE À TRAITER
							,iMoisATraiter				= MONTH(r.dtDate_Calcul_Rendement)		-- MOIS À TRAITER
							,iNbJourAnneeATraiter		= CASE WHEN (
																		CASE	WHEN YEAR(r.dtDate_Calcul_Rendement) % 100 = 0 THEN YEAR(r.dtDate_Calcul_Rendement) % 400	-- VALIDATION DU SIÈCLE
																				ELSE YEAR(r.dtDate_Calcul_Rendement) % 4								
																		END
																	) = 0 THEN 366				-- BISEXTILE
																ELSE	
																		365						-- ANNÉE STANDARD
														  END 
							,iNbJourMoisATraiter			= DAY(DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,r.dtDate_Calcul_Rendement)+1,0)))
							,dtPremierJourDuMoisATraiter	= CAST(LEFT(CONVERT(VARCHAR(10),r.dtDate_Calcul_Rendement,126),7) + CAST('-01' AS VARCHAR(3)) AS DATETIME)
							,dtDernierJourDuMoisATraiter	= CAST(CONVERT(VARCHAR(10),DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,r.dtDate_Calcul_Rendement)+1,0)),126) AS DATETIME)
							,vcTypeOperationCategorie	= CASE WHEN r.dTaux_Rendement > 0 THEN dbo.fnOPER_ObtenirTypesOperationCategorie('OPER_RENDEMENT_POSITIF') ELSE dbo.fnOPER_ObtenirTypesOperationCategorie('OPER_RENDEMENT_NEGATIF') END
							,iID_Connect				= 2
							,vcTypeOperation			= CASE WHEN r.dTaux_Rendement > 0 THEN 'OPER_RENDEMENT_POSITIF' ELSE 'OPER_RENDEMENT_NEGATIF' END
							,r.vcCode_Rendement
							,dtMaxDateGeneration		= @dtMaxDateGenerationCurseur
						FROM 
							dbo.fntOPER_RechercherRendement('FRA',NULL,NULL,NULL,NULL,NULL,NULL,@cEtat,0) AS r
						WHERE
							r.dtDate_Calcul_Rendement	< GETDATE()
							AND					
							r.dtDate_Generation			IS NULL	
						ORDER BY
							r.dtDate_Calcul_Rendement, r.siOrdreGenererRendement		
				END

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
				,@vcTypeOperationCategorie
				,@iConnectId
				,@vcTypeOperation
				,@vcCode_Rendement
				,@dtMaxDateGeneration


			SET @bDataPresent = 0
			IF @@FETCH_STATUS = 0		-- 2010-04-21 : JFG : AJOUT
				BEGIN
					SET @bDataPresent = 1
				END
				
			WHILE @@FETCH_STATUS = 0
				BEGIN
					-- JFG : 2009-11-03 -- RECHERCHE DU STATUT EN FONCTION DE LA DATE DE CALCUL DU RENDEMENT
					DELETE FROM @tConventionState
					INSERT INTO @tConventionState
					(
					ConventionID	
					,MostRecentDate
					)
					SELECT 
						ccvt.ConventionID, MAX(ccvt.StartDate) AS MostRecentDate 
                    FROM 
                         dbo.Un_ConventionConventionState ccvt 
                         INNER JOIN dbo.Un_ConventionState cvt 
                                 ON cvt.ConventionStateID = ccvt.ConventionStateID 
					WHERE 
						ccvt.ConventionID = ISNULL(@iID_Convention, ccvt.ConventionID ) 
						AND 
						ccvt.StartDate <= GETDATE() -- @dtDernierJourDuMoisATraiter  2009-12-16 : Mis en commentaire suite à une discussion avec Rémy et à l'approbation d'Isabelle et d'Éric 
                    GROUP BY 
                       ccvt.ConventionID 

					-- INITIALISATION À ZÉRO DU MONTANT TOTAL GÉNÉRÉ POUR LE RENDEMENT TRAITÉ
					SET @mMontantTotal_Genere = 0
					
					---- APPEL DE SP_IU_UN_OPER POUR OBTENIR UN OPER_ID
					EXECUTE @iID_OPER = dbo.SP_IU_UN_OPER @iConnectId, 0, @vcTypeOperationCategorie, @dtDate_Calcul_Rendement

				
----------------------------------------------------------------------------------------------------------------------------------
-- 1.3.2.3.1		-- DÉBUT DU CALCUL DU RENDEMENT SUR ÉPARGNE ET FRAIS DE CONVENTIONS COLLECTIVES APRÈS LA DATE ESTIMÉE DU RI
					-- ET 
					-- DU RENDEMENT SUR ÉPARGNE ET FRAIS DE CONVENTIONS INDIVIDUELLES ISSUES D'UN RIO (NOUVELLES ET EXISTANTES)
----------------------------------------------------------------------------------------------------------------------------------
	IF @cEtat = 'S' -- nouveau rendement
		BEGIN
		-- RENDEMENT SUR ÉPARGNE ET FRAIS DE CONVENTIONS COLLECTIVES APRÈS LA DATE ESTIMÉE DU RI
					--Valide si c'est le bon code de rendement pour ce traitement
					IF @vcCode_Rendement = 'TRI'
					BEGIN
						-- RECHERCHE DES PARAMÈTRES PERMETTANT DE CALCULER LES RENDEMENTS APRÈS LA DATE ESTIMÉE DU RI
						-- À PARTIR DE LA TABLE UN_DEF
						SELECT
								@dtStartDateForIntAfterEstimatedRI	=	StartDateForIntAfterEstimatedRI
								,@iMonthNoIntAfterEstimatedRI		=	MonthNoIntAfterEstimatedRI
						FROM
							dbo.Un_Def

						-- DÉTERMINER LES UNITÉS QUI ONT DROIT À L'INTÉRÊT  APRÈS LA DATE ESTIMÉE
						-- DU REMBOURSEMENT INTÉGRAL (RI)
						-- 1. Vérifier s'il existe  une date d'opération où le type d'opération sur la
						--    convention est "INM", que le type d'opération est "IN+", "IN-" ou "INT"
						--	  et que le régime est "COL"
						SELECT
							@dtDateOperation = MIN(o.OperDate)
						FROM
							dbo.Un_Convention c
							INNER JOIN dbo.Un_ConventionOPER co
								ON c.ConventionID = co.ConventionID
							INNER JOIN dbo.Un_Oper o
								ON co.OperID = o.OperID
							INNER JOIN dbo.Un_Plan p
								ON c.PlanID = p.PlanID
						WHERE
							c.ConventionID			= ISNULL(@iID_Convention, c.ConventionID)
							AND
							co.ConventionOperTypeID = @vcConventionOperTypeMntSouscrit
							AND
							o.OperTypeID			= @vcTypeOperationCategorie
							AND
							p.PlanTypeID			= 'COL'
						HAVING MIN(O.OperDate) > @dtStartDateForIntAfterEstimatedRI

						-- Si existe, assigner  à la date de début pour intérêts après l'estimé du RI 
						-- la date d'opération + 1 journée
						IF @dtDateOperation IS NOT NULL	
							BEGIN		
								SELECT 
									@dtMinOperDate = MIN(O.OperDate)
								FROM 
									@tblTransactionConvention tc
									INNER JOIN
									dbo.Un_Convention c
										ON tc.iID_Convention = c.ConventionID
									INNER JOIN dbo.Un_ConventionOPER co
										ON c.ConventionID = co.ConventionID
									INNER JOIN dbo.Un_Oper o
										ON co.OperID = o.OperID
									INNER JOIN dbo.Un_Plan p
										ON c.PlanID = p.PlanID
								WHERE 
									c.ConventionID			= ISNULL(@iID_Convention, c.ConventionID)
									AND
									co.ConventionOperTypeID = @vcConventionOperTypeMntSouscrit
									AND
									o.OperTypeID			= @vcTypeOperationCategorie
									AND
									p.PlanTypeID			= 'COL'

								SELECT 
									@dtStartDateForIntAfterEstimatedRI = DATEADD(dd, 1, MAX(O.OperDate))
								FROM 
									dbo.Un_Oper o
									INNER JOIN dbo.Un_InterestRate i 
										ON i.OperID = o.OperID
								WHERE 
									o.OperDate < @dtMinOperDate
							END

						-- Sélection les groupes d'unités éligibles à l'intérêt du RI. Pour cela, faire
						-- une sélection des groupes d'unités (UnitID) de la table des groupes d'unités 
						-- dans la table Un_Unit
						DELETE FROM @tblUniteEligible

						INSERT INTO @tblUniteEligible
						(	
							iID_Unit
							,dtDateEstimeRI
							,dtDateDebutIntRI
						)
						SELECT 
							u.UnitID
							,DATEADD(mm, @iMonthNoIntAfterEstimatedRI, dbo.fn_Un_EstimatedIntReimbDate(m.PmtByYearID, m.PmtQty, m.BenefAgeOnBegining, u.InForceDate, p.IntReimbAge, NULL))
							,CASE 
								WHEN 
									DATEADD(mm, @iMonthNoIntAfterEstimatedRI, dbo.fn_Un_EstimatedIntReimbDate(m.PmtByYearID, M.PmtQty, m.BenefAgeOnBegining, u.InForceDate, p.IntReimbAge, NULL)) > @dtStartDateForIntAfterEstimatedRI 
										THEN 
											DATEADD(mm, @iMonthNoIntAfterEstimatedRI, dbo.fn_Un_EstimatedIntReimbDate(m.PmtByYearID, m.PmtQty, m.BenefAgeOnBegining, u.InForceDate, p.IntReimbAge, NULL))
								ELSE 
									@dtStartDateForIntAfterEstimatedRI
							END
						FROM 
								dbo.Un_Unit u
								INNER JOIN dbo.Un_Modal m
									ON m.ModalID = u.ModalID
								INNER JOIN dbo.Un_Plan p 
									ON p.PlanID = m.PlanID
						WHERE 
							(ISNULL(u.IntReimbDate, @dtDernierJourDuMoisATraiter + 1) > @dtDernierJourDuMoisATraiter)
							AND 
							(ISNULL(u.TerminatedDate, @dtDernierJourDuMoisATraiter + 1) > @dtDernierJourDuMoisATraiter)
							AND 
							p.PlanTypeID = 'COL'
							AND 
							(DATEADD(mm, @iMonthNoIntAfterEstimatedRI, dbo.fn_Un_EstimatedIntReimbDate(m.PmtByYearID, m.PmtQty, m.BenefAgeOnBegining, u.InForceDate, p.IntReimbAge, NULL)) <= @dtDernierJourDuMoisATraiter)

					DELETE ue FROM @tblUniteEligible AS ue
					WHERE 
						 NOT EXISTS
										(
											SELECT 
												1
											FROM 
												dbo.Un_Unit u
												INNER JOIN dbo.Un_Modal m
													ON m.ModalID = u.ModalID
												INNER JOIN dbo.Un_Cotisation ct 
													ON ct.UnitID = u.UnitID
												INNER JOIN dbo.Un_Oper o
													ON o.OperID = ct.OperID 
											WHERE 
												o.OperDate < DATEADD(MONTH,-@iMonthNoIntAfterEstimatedRI, @dtDernierJourDuMoisATraiter + 1)
												AND
												u.UnitID = ue.iID_Unit
											GROUP BY 
												u.UnitID,
												u.PmtEndConnectID,
												u.UnitQty,
												m.PmtRate,
												m.PmtQty
											HAVING 
												u.PmtEndConnectID > 0
												OR 
												SUM(ct.Cotisation + ct.Fee) >= ROUND(u.UnitQty * m.PmtRate,2)* m.PmtQty
										)

						-- OBTENIR TOUTES LES TRANSACTIONS ADMISSIBLE AU CALCUL DE RENDEMENT
						-- (EN FONCTION DES UNITÉS ÉLIGIBLES)

						--  ****** DÉBUT DU TRAITEMENT POUR LES TRANSACTIONS ANTÉRIEURES AU PREMIER JOUR DU MOIS À TRAITER ********

						-- 1.	Insertion  des soldes d'épargnes et frais des conventions collectives après la date
						--		estimée du RI en date du premier jour du mois à traiter pour la date d'opération
						--		plus petite que la date du premier jour du mois à traiter
						INSERT INTO @tblTransactionConvention
						(
							iID_Convention
							,iJourOperation
							,mMontantRI  
						)
						SELECT						-- Transactions ANTÉRIEURES au mois à traiter (soldes d'épargnes et frais)
							c.ConventionID
							,0
							,SUM(ct.Cotisation + ct.Fee)
						FROM
							@tblUniteEligible ue
							INNER JOIN dbo.Un_Unit u
								ON u.UnitID = ue.iID_Unit
							INNER JOIN dbo.Un_Convention c
								ON u.ConventionID = c.ConventionID 
							INNER JOIN	dbo.Un_ConventionConventionState ccs
								ON c.ConventionID = ccs.ConventionID
							INNER JOIN	dbo.Un_ConventionState cs
								ON cs.ConventionStateID = ccs.ConventionStateID
							INNER JOIN dbo.Un_Cotisation ct
								ON ct.UnitId = u.UnitId
							INNER JOIN dbo.Un_Oper o
								ON ct.OperID = o.OperID	
							INNER JOIN @tConventionState tmp
								ON ccs.ConventionID = tmp.ConventionID AND	ccs.StartDate = tmp.MostRecentDate
						WHERE
							c.ConventionID = ISNULL(@iID_Convention, c.ConventionID)
							AND
							cs.ConventionStateID IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire
							AND
							o.OperDate < @dtPremierJourDuMoisATraiter
						GROUP BY
							c.ConventionID
						HAVING 
							SUM(ct.Cotisation + ct.Fee) <> 0 -- > 0 FT 2011-03-17

						--  ****** FIN DU TRAITEMENT POUR LES TRANSACTIONS EN DATE DU PREMIER JOUR DU MOIS À TRAITER ********

						--  ****** DÉBUT DU TRAITEMENT POUR LE MOIS À TRAITER *******
						-- 1.	Insertion des soldes d'épargnes et frais des conventions collectives après la date
						--		estimée du RI en date du premier jour du mois à traiter
						INSERT INTO @tblTransactionConvention
						(
							iID_Convention
							,iJourOperation
							,mMontantRI  
						)
						SELECT						-- Transactions du MOIS à traiter
							c.ConventionID
							,DAY(o.OperDate)
							,SUM(ct.Cotisation + ct.Fee)
						FROM
							@tblUniteEligible ue
							INNER JOIN dbo.Un_Unit u
								ON u.UnitID = ue.iID_Unit
							INNER JOIN dbo.Un_Convention c
								ON u.ConventionID = c.ConventionID
							INNER JOIN	dbo.Un_ConventionConventionState ccs
								ON c.ConventionID = ccs.ConventionID		
							INNER JOIN dbo.Un_Cotisation ct
								ON ct.UnitId = u.UnitId
							INNER JOIN dbo.Un_Oper o
								ON ct.OperID = o.OperID	
							INNER JOIN @tConventionState tmp
								ON ccs.ConventionID = tmp.ConventionID AND	ccs.StartDate = tmp.MostRecentDate
							INNER JOIN	dbo.Un_ConventionState cs
								ON cs.ConventionStateID = ccs.ConventionStateID 
						WHERE
							c.ConventionID = ISNULL(@iID_Convention, c.ConventionID)
							AND
							cs.ConventionStateID IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire
							AND
							o.OperDate BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter
						GROUP BY
							c.ConventionID,
							o.OperDate
						--  ****** FIN DU TRAITEMENT POUR LE MOIS À TRAITER *******

						-- GÉNÉRER LES RENDEMENTS SUR LES ÉPARGNES ET SUR LES FRAIS DES CONVENTIONS COLLECTIVES
						-- APRÈS LA DATE ESTIMÉE DU RI,	SI LE RI N'A PAS ENCORE EU LIEU DANS LA TABLES DES
						-- OPÉRATIONS SUR LES CONVENTIONS "Un_ConventionOper"

						-- CALCUL DU MONTANT ET INSERTION DES TRANSACTIONS DANS LA TABLE DES OPÉRATIONS SUR CONVENTIONS
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						) 
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeMntSouscrit
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantRI,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc						
						GROUP BY
							tc.iID_Convention
						HAVING 
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantRI,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantRI,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)

						IF @bActiveDebug = 1
							BEGIN
								IF (SELECT COUNT(*) FROM @tblTransactionConvention) > 0
									BEGIN
										SELECT '1.3.2.3.1 NEW : Rendement sur épargne et frais de conventions collectives après la date estimée du RI', tc.* 
										FROM @tblTransactionConvention tc
									END
								ELSE
									BEGIN
										SELECT '1.3.2.3.1 NEW : Rendement sur épargne et frais de conventions collectives après la date estimée du RI'
									END							
							END
																						
						-- SUPPRESSION DU CONTENU DE LA TABLE TEMPO
						DELETE FROM @tblTransactionConvention

	 -- RENDEMENT SUR ÉPARGNE ET FRAIS DE CONVENTIONS INDIVIDUELLES ISSUES D'UN RIO (NOUVELLES ET EXISTANTES)
						--  ****** DÉBUT DU TRAITEMENT POUR LES TRANSACTIONS ANTÉRIEURES AU PREMIER JOUR DU MOIS À TRAITER ********
						--	1.	Calculer le solde de l'épargnes des nouvelles conventions individuelles en date du premier jour du 
						--		du mois à traiter "Date d'opération est plus petite que la date du premier jour du mois à traiter"
						--	N.B.
						--		Vérifier si les conventions sont issues d'un RIO et que la période de probation est
						--		couverte. Si la date de début de régime additionnée au nombre de mois avant le remboursement
						--		intégral après le RIO, est plus petite que la date de fin du mois à traiter.
						--
						--		Calculer la somme du champ "Cotisation" de la table "Un_Cotisation"
						--		et ajouter la somme des frais ("Fee") pour les conventions issues d'un RIO
						INSERT INTO @tblTransactionConvention	
						(
							iID_Convention			
							,iJourOperation			
							,mMontantRI
						)
						SELECT 
							u.ConventionID
							,0
							,CASE 
								WHEN rio.iID_Convention_Destination IS NOT NULL
									THEN SUM(ct.Cotisation + ct.Fee)
								ELSE
									SUM(ct.Cotisation)
								END
						FROM 
							dbo.Un_Unit u
							INNER JOIN dbo.Un_Convention co 
								ON co.ConventionID = u.ConventionID
							INNER JOIN	dbo.Un_ConventionConventionState ccs
								ON co.ConventionID = ccs.ConventionID
							INNER JOIN	dbo.Un_ConventionState cs
								ON cs.ConventionStateID = ccs.ConventionStateID
							INNER JOIN dbo.Un_Modal m 
								ON m.ModalID = u.ModalID
							INNER JOIN dbo.Un_Plan p 
								ON p.PlanID = m.PlanID
							INNER JOIN dbo.Un_Cotisation ct 
								ON ct.UnitID = u.UnitID
							INNER JOIN dbo.Un_Oper o 
								ON o.OperID = ct.OperID 
							INNER JOIN @tConventionState tmp
								ON ccs.ConventionID = tmp.ConventionID AND	ccs.StartDate = tmp.MostRecentDate
							INNER JOIN @tRIO rio
								ON rio.iID_Convention_Destination = u.ConventionID
						WHERE 
							u.ConventionId = ISNULL(@iID_Convention, u.ConventionID)
							AND
							p.PlanTypeID = 'IND'
							AND 
							cs.ConventionStateID IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire
							AND
							o.OperDate < @dtPremierJourDuMoisATraiter -- modifié par JFA 2009-08-28	
						GROUP BY 
							u.ConventionID
							,rio.iID_Convention_Destination
						HAVING
							(CASE 
								WHEN rio.iID_Convention_Destination IS NOT NULL
									THEN SUM(ct.Cotisation + ct.Fee)
								ELSE
									SUM(ct.Cotisation)
								END) <> 0 -- > 0 FT 2011-03-17

						INSERT INTO @tblTransactionConvention	
						(
							iID_Convention			
							,iJourOperation			
							,mMontantRI
						)
						SELECT
							u.ConventionID
							,0
							,SUM(ISNULL(ct.Cotisation,0) + ISNULL(ct.Fee,0))							
						FROM 
							dbo.Un_Unit u
							INNER JOIN dbo.Un_Convention co 
								ON co.ConventionID = u.ConventionID
							INNER JOIN	dbo.Un_ConventionConventionState ccs
								ON co.ConventionID = ccs.ConventionID
							INNER JOIN	dbo.Un_ConventionState cs
								ON cs.ConventionStateID = ccs.ConventionStateID
							INNER JOIN dbo.Un_Modal m 
								ON m.ModalID = u.ModalID
							INNER JOIN dbo.Un_Plan p 
								ON p.PlanID = m.PlanID
							INNER JOIN dbo.Un_Cotisation ct 
								ON ct.UnitID = u.UnitID
							INNER JOIN dbo.Un_Oper o 
								ON o.OperID = ct.OperID 
							INNER JOIN @tConventionState tmp
								ON ccs.ConventionID = tmp.ConventionID AND	ccs.StartDate = tmp.MostRecentDate
							INNER JOIN @tRIO rio
								ON rio.iID_Convention_Destination = u.ConventionID
						WHERE 
							u.ConventionId = ISNULL(@iID_Convention, u.ConventionID)
							AND
							p.PlanTypeID = 'IND'
							AND 
							cs.ConventionStateID IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire
							AND
							o.OperDate < @dtPremierJourDuMoisATraiter	-- modifié par JFA 2009-08-28
							AND 
							co.dtDateProspectus >= @dtDateProspectus
						GROUP BY 
							u.ConventionID
							,rio.iID_Convention_Destination
						HAVING
							SUM(ISNULL(ct.Cotisation,0) + ISNULL(ct.Fee,0)) <> 0 -- > 0 FT 2011-03-17

						--  ****** FIN DU TRAITEMENT POUR LES TRANSACTIONS EN DATE DU PREMIER JOUR DU MOIS À TRAITER ********

						--  ****** DÉBUT DU TRAITEMENT POUR LE MOIS À TRAITER *******	
						--	1. Mêmes calculs, mais pour le mois à traiter
						INSERT INTO @tblTransactionConvention	
						(
							iID_Convention			
							,iJourOperation			
							,mMontantRI
						)
						SELECT
							u.ConventionID
							,DAY(o.OperDate)
							,SUM(ISNULL(ct.Cotisation,0) + ISNULL(ct.Fee,0))							
						FROM 
							dbo.Un_Unit u
							INNER JOIN dbo.Un_Convention co 
								ON co.ConventionID = u.ConventionID
							INNER JOIN	dbo.Un_ConventionConventionState ccs
								ON co.ConventionID = ccs.ConventionID
							INNER JOIN	dbo.Un_ConventionState cs
								ON cs.ConventionStateID = ccs.ConventionStateID
							INNER JOIN dbo.Un_Modal m 
								ON m.ModalID = u.ModalID
							INNER JOIN dbo.Un_Plan p 
								ON p.PlanID = m.PlanID
							INNER JOIN dbo.Un_Cotisation ct 
								ON ct.UnitID = u.UnitID
							INNER JOIN dbo.Un_Oper o 
								ON o.OperID = ct.OperID 
							INNER JOIN @tConventionState tmp
								ON ccs.ConventionID = tmp.ConventionID AND	ccs.StartDate = tmp.MostRecentDate
							INNER JOIN @tRIO rio
								ON rio.iID_Convention_Destination = u.ConventionID
						WHERE 
							u.ConventionId = ISNULL(@iID_Convention, u.ConventionID)
							AND
							p.PlanTypeID = 'IND'
							AND
							cs.ConventionStateID IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire
							AND 
							o.OperDate BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter 
						GROUP BY 
							u.ConventionID
							,o.OperDate
							,rio.iID_Convention_Destination
						--  ****** FIN DU TRAITEMENT POUR LE MOIS À TRAITER *******	
				
						-- CALCUL DU MONTANT ET INSERTION DES TRANSACTIONS DANS LA TABLE DES OPÉRATIONS SUR CONVENTIONS
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						)
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeMntSouscrit
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantRI,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention
						HAVING
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantRI,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantRI,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)
																					
						IF @bActiveDebug = 1
							BEGIN
								IF (SELECT COUNT(*) FROM @tblTransactionConvention) > 0
									BEGIN
										SELECT '1.3.2.3.1 NEW : Rendement sur épargne et frais de conventions individuelles issues d''un RIO (Nouvelles et existantes)', tc.* 
										FROM @tblTransactionConvention tc
									END
								ELSE
									BEGIN
										SELECT '1.3.2.3.1 NEW : Rendement sur épargne et frais de conventions individuelles issues d''un RIO (Nouvelles et existantes)'
									END			
							END

						-- SUPPRESSION DU CONTENU DE LA TABLE TEMPO
						DELETE FROM @tblTransactionConvention
					END
		END
	ELSE	-- TAUX MODIFIÉ @cEtat = 'C'
		BEGIN
			IF @vcCode_Rendement = 'TRI'
				BEGIN
						-- RECHERCHE DES PARAMÈTRES PERMETTANT DE CALCULER LES RENDEMENTS APRÈS LA DATE ESTIMÉE DU RI
						-- À PARTIR DE LA TABLE UN_DEF
						SELECT
								@dtStartDateForIntAfterEstimatedRI	=	StartDateForIntAfterEstimatedRI
								,@iMonthNoIntAfterEstimatedRI		=	MonthNoIntAfterEstimatedRI
						FROM
							dbo.Un_Def

						-- DÉTERMINER LES UNITÉS QUI ONT DROIT À L'INTÉRÊT  APRÈS LA DATE ESTIMÉE
						-- DU REMBOURSEMENT INTÉGRAL (RI)
						SELECT
							@dtDateOperation = MIN(o.OperDate)
						FROM
							dbo.Un_Convention c
							INNER JOIN dbo.Un_ConventionOPER co
								ON c.ConventionID = co.ConventionID
							INNER JOIN dbo.Un_Oper o
								ON co.OperID = o.OperID
							INNER JOIN dbo.Un_Plan p
								ON c.PlanID = p.PlanID
						WHERE
							c.ConventionID			= ISNULL(@iID_Convention, c.ConventionID)
							AND
							co.ConventionOperTypeID = @vcConventionOperTypeMntSouscrit
							AND
							o.OperTypeID			= @vcTypeOperationCategorie
							AND
							p.PlanTypeID			= 'COL'
						HAVING MIN(O.OperDate) > @dtStartDateForIntAfterEstimatedRI

						-- Si existe, assigner  à la date de début pour intérêts après l'estimé du RI 
						-- la date d'opération + 1 journée
						IF @dtDateOperation IS NOT NULL	
							BEGIN		
								SELECT 
									@dtMinOperDate = MIN(O.OperDate)
								FROM 
									@tblTransactionConvention tc
									INNER JOIN
									dbo.Un_Convention c
										ON tc.iID_Convention = c.ConventionID
									INNER JOIN dbo.Un_ConventionOPER co
										ON c.ConventionID = co.ConventionID
									INNER JOIN dbo.Un_Oper o
										ON co.OperID = o.OperID
									INNER JOIN dbo.Un_Plan p
										ON c.PlanID = p.PlanID
								WHERE 
									c.ConventionID			= ISNULL(@iID_Convention, c.ConventionID)
									AND
									co.ConventionOperTypeID = @vcConventionOperTypeMntSouscrit
									AND
									o.OperTypeID			= @vcTypeOperationCategorie
									AND
									p.PlanTypeID			= 'COL'

								SELECT 
									@dtStartDateForIntAfterEstimatedRI = DATEADD(dd, 1, MAX(O.OperDate))
								FROM 
									dbo.Un_Oper o
									INNER JOIN dbo.Un_InterestRate i 
										ON i.OperID = o.OperID
								WHERE 
									o.OperDate < @dtMinOperDate
							END

						-- Sélection les groupes d'unités éligibles à l'intérêt du RI. Pour cela, faire
						-- une sélection des groupes d'unités (UnitID) de la table des groupes d'unités 
						-- dans la table Un_Unit
						DELETE FROM @tblUniteEligible

						INSERT INTO @tblUniteEligible
						(	
							iID_Unit
							,dtDateEstimeRI
							,dtDateDebutIntRI
						)
						SELECT 
							u.UnitID
							,DATEADD(mm, @iMonthNoIntAfterEstimatedRI, dbo.fn_Un_EstimatedIntReimbDate(m.PmtByYearID, m.PmtQty, m.BenefAgeOnBegining, u.InForceDate, p.IntReimbAge, NULL))
							,CASE 
								WHEN 
									DATEADD(mm, @iMonthNoIntAfterEstimatedRI, dbo.fn_Un_EstimatedIntReimbDate(m.PmtByYearID, M.PmtQty, m.BenefAgeOnBegining, u.InForceDate, p.IntReimbAge, NULL)) > @dtStartDateForIntAfterEstimatedRI 
										THEN 
											DATEADD(mm, @iMonthNoIntAfterEstimatedRI, dbo.fn_Un_EstimatedIntReimbDate(m.PmtByYearID, m.PmtQty, m.BenefAgeOnBegining, u.InForceDate, p.IntReimbAge, NULL))
								ELSE 
									@dtStartDateForIntAfterEstimatedRI
							END
						FROM 
								dbo.Un_Unit u
								INNER JOIN dbo.Un_Modal m
									ON m.ModalID = u.ModalID
								INNER JOIN dbo.Un_Plan p 
									ON p.PlanID = m.PlanID
						WHERE 
							(ISNULL(u.IntReimbDate, @dtDernierJourDuMoisATraiter + 1) > @dtDernierJourDuMoisATraiter)
							AND 
							(ISNULL(u.TerminatedDate, @dtDernierJourDuMoisATraiter + 1) > @dtDernierJourDuMoisATraiter)
							AND 
							p.PlanTypeID = 'COL'
							AND 
							(DATEADD(mm, @iMonthNoIntAfterEstimatedRI, dbo.fn_Un_EstimatedIntReimbDate(m.PmtByYearID, m.PmtQty, m.BenefAgeOnBegining, u.InForceDate, p.IntReimbAge, NULL)) <= @dtDernierJourDuMoisATraiter)

					DELETE ue FROM @tblUniteEligible AS ue
					WHERE 
						 NOT EXISTS
										(
											SELECT 
												1
											FROM 
												dbo.Un_Unit u
												INNER JOIN dbo.Un_Modal m
													ON m.ModalID = u.ModalID
												INNER JOIN dbo.Un_Cotisation ct 
													ON ct.UnitID = u.UnitID
												INNER JOIN dbo.Un_Oper o
													ON o.OperID = ct.OperID 
											WHERE 
												o.OperDate < DATEADD(MONTH,-@iMonthNoIntAfterEstimatedRI, @dtDernierJourDuMoisATraiter + 1)
												AND
												u.UnitID = ue.iID_Unit
											GROUP BY 
												u.UnitID,
												u.PmtEndConnectID,
												u.UnitQty,
												m.PmtRate,
												m.PmtQty
											HAVING 
												u.PmtEndConnectID > 0
												OR 
												SUM(ct.Cotisation + ct.Fee) >= ROUND(u.UnitQty * m.PmtRate,2)* m.PmtQty
										)

						-- OBTENIR TOUTES LES TRANSACTIONS ADMISSIBLE AU CALCUL DE RENDEMENT
						-- (EN FONCTION DES UNITÉS ÉLIGIBLES)

						--  ****** DÉBUT DU TRAITEMENT POUR LES TRANSACTIONS ANTÉRIEURES AU PREMIER JOUR DU MOIS À TRAITER ********
						INSERT INTO @tblTransactionConvention
						(
							iID_Convention
							,iJourOperation
							,mMontantRI  
						)
						SELECT						-- Transactions ANTÉRIEURES au mois à traiter (soldes d'épargnes et frais)
							c.ConventionID
							,0
							,SUM(ct.Cotisation + ct.Fee)
						FROM
							@tblUniteEligible ue
							INNER JOIN dbo.Un_Unit u
								ON u.UnitID = ue.iID_Unit
							INNER JOIN dbo.Un_Convention c
								ON u.ConventionID = c.ConventionID 
							INNER JOIN dbo.Un_Cotisation ct
								ON ct.UnitId = u.UnitId
							INNER JOIN dbo.Un_Oper o
								ON ct.OperID = o.OperID	
						WHERE
							c.ConventionID = ISNULL(@iID_Convention, c.ConventionID)
							AND
							dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, c.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour
							AND
							o.OperDate < @dtPremierJourDuMoisATraiter
						GROUP BY
							c.ConventionID
						HAVING
							SUM(ct.Cotisation + ct.Fee) <> 0 -- > 0 FT 2011-03-17

						--  ****** FIN DU TRAITEMENT POUR LES TRANSACTIONS EN DATE DU PREMIER JOUR DU MOIS À TRAITER ********
						
						-- SUPPRESSION DES TRANSACTIONS DANS UN_CONVENTION_OPER
						DELETE cop
						FROM 
							dbo.Un_ConventionOper cop
							INNER JOIN dbo.Un_Oper o 
								ON o.OperID = cop.OperID 
						WHERE 
								cop.ConventionId = ISNULL(@iID_Convention, cop.ConventionID)
								AND
								dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, cop.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour
								AND
								cop.OperID IN (	SELECT 
													ISNULL(tx.iID_Operation,-1) 
												FROM 
													dbo.tblOper_TauxRendement tx
													INNER JOIN dbo.tblOPER_Rendements r
														ON tx.iID_Rendement = r.iID_Rendement
													INNER JOIN dbo.tblOPER_TypesRendement tr
														ON tr.tiID_Type_Rendement = r.tiID_Type_Rendement
												WHERE 
													ISNULL(tx.dtDate_Operation, '1900-01-01') BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter
													AND
													tr.vcCode_Rendement = @vcCode_Rendement)
						
						--  ****** DÉBUT DU TRAITEMENT POUR LE MOIS À TRAITER *******
						-- 1.	Insertion des soldes d'épargnes et frais des conventions collectives après la date
						--		estimée du RI en date du premier jour du mois à traiter
						INSERT INTO @tblTransactionConvention
						(
							iID_Convention
							,iJourOperation
							,mMontantRI  
						)
						SELECT						-- Transactions du MOIS à traiter
							c.ConventionID
							,DAY(o.OperDate)
							,SUM(ct.Cotisation + ct.Fee)
						FROM
							@tblUniteEligible ue
							INNER JOIN dbo.Un_Unit u
								ON u.UnitID = ue.iID_Unit
							INNER JOIN dbo.Un_Convention c
								ON u.ConventionID = c.ConventionID
							INNER JOIN dbo.Un_Cotisation ct
								ON ct.UnitId = u.UnitId
							INNER JOIN dbo.Un_Oper o
								ON ct.OperID = o.OperID	
						WHERE
							c.ConventionID = ISNULL(@iID_Convention, c.ConventionID)
							AND
							dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, c.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour				
							AND 
							o.OperDate BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter
						GROUP BY
							c.ConventionID,
							o.OperDate
						--  ****** FIN DU TRAITEMENT POUR LE MOIS À TRAITER *******

						-- GÉNÉRER LES RENDEMENTS SUR LES ÉPARGNES ET SUR LES FRAIS DES CONVENTIONS COLLECTIVES
						-- APRÈS LA DATE ESTIMÉE DU RI,	SI LE RI N'A PAS ENCORE EU LIEU DANS LA TABLES DES
						-- OPÉRATIONS SUR LES CONVENTIONS "Un_ConventionOper"

						-- CALCUL DU MONTANT ET INSERTION DES TRANSACTIONS DANS LA TABLE DES OPÉRATIONS SUR CONVENTIONS
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						) 
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeMntSouscrit
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantRI,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention
						HAVING
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantRI,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantRI,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)

						IF @bActiveDebug = 1
							BEGIN
								IF (SELECT COUNT(*) FROM @tblTransactionConvention) > 0
									BEGIN
										SELECT '1.3.2.3.1 MOD : Rendement sur épargne et frais de conventions collectives après la date estimée du RI', tc.* 
										FROM @tblTransactionConvention tc
									END
								ELSE
									BEGIN
										SELECT '1.3.2.3.1 MOD : Rendement sur épargne et frais de conventions collectives après la date estimée du RI'
									END							
							END
																						
						-- SUPPRESSION DU CONTENU DE LA TABLE TEMPO
						DELETE FROM @tblTransactionConvention

	 -- RENDEMENT SUR ÉPARGNE ET FRAIS DE CONVENTIONS INDIVIDUELLES ISSUES D'UN RIO (NOUVELLES ET EXISTANTES)
						--  ****** DÉBUT DU TRAITEMENT POUR LES TRANSACTIONS ANTÉRIEURES AU PREMIER JOUR DU MOIS À TRAITER ********
						INSERT INTO @tblTransactionConvention	
						(
							iID_Convention			
							,iJourOperation			
							,mMontantRI
						)
						SELECT 
							u.ConventionID
							,0
							,CASE 
								WHEN rio.iID_Convention_Destination IS NOT NULL
									THEN SUM(ct.Cotisation + ct.Fee)
								ELSE
									SUM(ct.Cotisation)
								END
						FROM 
							dbo.Un_Unit u
							INNER JOIN dbo.Un_Convention co 
								ON co.ConventionID = u.ConventionID
							INNER JOIN dbo.Un_Modal m 
								ON m.ModalID = u.ModalID
							INNER JOIN dbo.Un_Plan p 
								ON p.PlanID = m.PlanID
							INNER JOIN dbo.Un_Cotisation ct 
								ON ct.UnitID = u.UnitID
							INNER JOIN dbo.Un_Oper o 
								ON o.OperID = ct.OperID 
							INNER JOIN @tRIO rio
								ON rio.iID_Convention_Destination = u.ConventionID
						WHERE 
							u.ConventionId = ISNULL(@iID_Convention, u.ConventionID)
							AND
							p.PlanTypeID = 'IND'
							AND 
							dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, co.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour
							AND
							o.OperDate < @dtPremierJourDuMoisATraiter -- modifié par JFA 2009-08-28	
						GROUP BY 
							u.ConventionID
							,rio.iID_Convention_Destination
						HAVING
							(CASE 
								WHEN rio.iID_Convention_Destination IS NOT NULL
									THEN SUM(ct.Cotisation + ct.Fee)
								ELSE
									SUM(ct.Cotisation)
								END) <> 0 -- > 0 FT 2011-03-17

						INSERT INTO @tblTransactionConvention	
						(
							iID_Convention			
							,iJourOperation			
							,mMontantRI
						)
						SELECT
							u.ConventionID
							,0
							,SUM(ISNULL(ct.Cotisation,0) + ISNULL(ct.Fee,0))							
						FROM 
							dbo.Un_Unit u
							INNER JOIN dbo.Un_Convention co 
								ON co.ConventionID = u.ConventionID
							INNER JOIN dbo.Un_Modal m 
								ON m.ModalID = u.ModalID
							INNER JOIN dbo.Un_Plan p 
								ON p.PlanID = m.PlanID
							INNER JOIN dbo.Un_Cotisation ct 
								ON ct.UnitID = u.UnitID
							INNER JOIN dbo.Un_Oper o 
								ON o.OperID = ct.OperID 
							INNER JOIN @tRIO rio
								ON rio.iID_Convention_Destination = u.ConventionID
						WHERE 
							u.ConventionId = ISNULL(@iID_Convention, u.ConventionID)
							AND
							p.PlanTypeID = 'IND'
							AND 
							dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, co.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour
							AND
							o.OperDate < @dtPremierJourDuMoisATraiter	-- modifié par JFA 2009-08-28
							AND 
							co.dtDateProspectus >= @dtDateProspectus
						GROUP BY 
							u.ConventionID
							,rio.iID_Convention_Destination
						HAVING
							SUM(ISNULL(ct.Cotisation,0) + ISNULL(ct.Fee,0)) <> 0 -- > 0 FT 2011-03-17

						--  ****** FIN DU TRAITEMENT POUR LES TRANSACTIONS EN DATE DU PREMIER JOUR DU MOIS À TRAITER ********
					
						-- SUPPRESSION DES TRANSACTIONS DANS UN_CONVENTION_OPER
						DELETE cop
						FROM 
							dbo.Un_ConventionOper cop
							INNER JOIN dbo.Un_Oper o 
								ON o.OperID = cop.OperID 
						WHERE 
								cop.ConventionId = ISNULL(@iID_Convention, cop.ConventionID)
								AND
								dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, cop.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour
								AND
								cop.OperID IN (	SELECT 
													ISNULL(tx.iID_Operation,-1) 
												FROM 
													dbo.tblOper_TauxRendement tx
													INNER JOIN dbo.tblOPER_Rendements r
														ON tx.iID_Rendement = r.iID_Rendement
													INNER JOIN dbo.tblOPER_TypesRendement tr
														ON tr.tiID_Type_Rendement = r.tiID_Type_Rendement
												WHERE 
													ISNULL(tx.dtDate_Operation, '1900-01-01') BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter
													AND
													tr.vcCode_Rendement = @vcCode_Rendement)
						
						--  ****** DÉBUT DU TRAITEMENT POUR LE MOIS À TRAITER *******	
						INSERT INTO @tblTransactionConvention	
						(
							iID_Convention			
							,iJourOperation			
							,mMontantRI
						)
						SELECT
							u.ConventionID
							,DAY(o.OperDate)
							,SUM(ISNULL(ct.Cotisation,0) + ISNULL(ct.Fee,0))							
						FROM 
							dbo.Un_Unit u
							INNER JOIN dbo.Un_Convention co 
								ON co.ConventionID = u.ConventionID
							INNER JOIN dbo.Un_Modal m 
								ON m.ModalID = u.ModalID
							INNER JOIN dbo.Un_Plan p 
								ON p.PlanID = m.PlanID
							INNER JOIN dbo.Un_Cotisation ct 
								ON ct.UnitID = u.UnitID
							INNER JOIN dbo.Un_Oper o 
								ON o.OperID = ct.OperID 
							INNER JOIN @tRIO rio
								ON rio.iID_Convention_Destination = u.ConventionID
						WHERE 
							u.ConventionId = ISNULL(@iID_Convention, u.ConventionID)
							AND
							p.PlanTypeID = 'IND'
							AND
							dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, co.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour				
							AND 
							o.OperDate BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter
						GROUP BY 
							u.ConventionID
							,o.OperDate
							,rio.iID_Convention_Destination
						--  ****** FIN DU TRAITEMENT POUR LE MOIS À TRAITER *******	
				
						-- CALCUL DU MONTANT ET INSERTION DES TRANSACTIONS DANS LA TABLE DES OPÉRATIONS SUR CONVENTIONS
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						)
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeMntSouscrit
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantRI,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention
						HAVING
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantRI,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantRI,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)
																					
						IF @bActiveDebug = 1
							BEGIN
								IF (SELECT COUNT(*) FROM @tblTransactionConvention) > 0
									BEGIN
										SELECT '1.3.2.3.1 MOD : Rendement sur épargne et frais de conventions individuelles issues d''un RIO (Nouvelles et existantes)', tc.* 
										FROM @tblTransactionConvention tc
									END
								ELSE
									BEGIN
										SELECT '1.3.2.3.1 MOD : Rendement sur épargne et frais de conventions individuelles issues d''un RIO (Nouvelles et existantes)'
									END			
							END

						-- SUPPRESSION DU CONTENU DE LA TABLE TEMPO
						DELETE FROM @tblTransactionConvention
				END
		END
-------------------------------------------------------------
					-- FIN DU CALCUL DU RENDEMENT POUR LES RI
-------------------------------------------------------------
					
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- 1.3.2.3.2	-- DÉBUT DU CALCUL DU RENDEMENT SUR LES REVENUS ACCUMULÉS SUR L'ÉPARGNE ET FRAIS DES CONVENTIONS COLLECTIVES APRÈS LA DATE ESTIMÉE DU RI
				-- ET
				-- DU RENDEMENT  SUR LES REVENUS ACCUMULÉS SUR L'ÉPARGNE ET FRAIS DES CONVENTIONS INDIVIDUELLES ISSUES D'UN RIO (NOUVELLES ET EXISTANTES)	
--------------------------------------------------------------------------------------------------------------------------------------------------------

	IF @cEtat = 'S' -- nouveau rendement
		BEGIN
	-- RENDEMENT SUR LES REVENUS ACCUMULÉS SUR L'ÉPARGNE ET FRAIS DES CONVENTIONS COLLECTIVES APRÈS LA DATE ESTIMÉE DU RI						
		--  ****** DÉBUT DU TRAITEMENT POUR LES TRANSACTIONS ANTÉRIEURES AU PREMIER JOUR DU MOIS À TRAITER ********
					--Valide si c'est le bon code de rendement pour ce traitement
					IF @vcCode_Rendement = 'RRI'
					BEGIN
						-- SUPPRESSION DES UNITÉS DU POINT 1.3.2.3.1
						DELETE FROM @tblUniteEligible

						-- RECHERCHE DES PARAMÈTRES PERMETTANT DE CALCULER LES RENDEMENTS APRÈS LA DATE ESTIMÉE DU RI
						-- À PARTIR DE LA TABLE UN_DEF
						SELECT
								@dtStartDateForIntAfterEstimatedRI	=	StartDateForIntAfterEstimatedRI
								,@iMonthNoIntAfterEstimatedRI		=	MonthNoIntAfterEstimatedRI
						FROM
							dbo.Un_Def

						-- DÉTERMINER LES UNITÉS QUI ONT DROIT À L'INTÉRÊT  APRÈS LA DATE ESTIMÉE
						-- DU REMBOURSEMENT INTÉGRAL (RI)
						-- 1. Vérifier s'il existe  une date d'opération où le type d'opération sur la
						--    convention est "INM", que le type d'opération est "IN+", "IN-" ou "INT"
						--	  et que le régime est "COL"
						SELECT
							@dtDateOperation = MIN(o.OperDate)
						FROM
							@tblTransactionConvention tc
							INNER JOIN
							dbo.Un_Convention c
								ON tc.iID_Convention = c.ConventionID
							INNER JOIN dbo.Un_ConventionOPER co
								ON c.ConventionID = co.ConventionID
							INNER JOIN dbo.Un_Oper o
								ON co.OperID = o.OperID
							INNER JOIN dbo.Un_Plan p
								ON c.PlanID = p.PlanID
						WHERE
							c.ConventionID			= ISNULL(@iID_Convention, c.ConventionID)
							AND
							co.ConventionOperTypeID = @vcConventionOperTypeMntSouscrit
							AND
							o.OperTypeID			= @vcTypeOperationCategorie
							AND
							p.PlanTypeID			= 'COL'
						HAVING MIN(O.OperDate) > @dtStartDateForIntAfterEstimatedRI

						-- Si existe, assigner  à la date de début pour intérêts après l'estimé du RI 
						-- la date d'opération + 1 journée
						IF @dtDateOperation IS NOT NULL	
							BEGIN		
								SELECT 
									@dtMinOperDate = MIN(O.OperDate)
								FROM 
									@tblTransactionConvention tc
									INNER JOIN
									dbo.Un_Convention c
										ON tc.iID_Convention = c.ConventionID
									INNER JOIN dbo.Un_ConventionOPER co
										ON c.ConventionID = co.ConventionID
									INNER JOIN dbo.Un_Oper o
										ON co.OperID = o.OperID
									INNER JOIN dbo.Un_Plan p
										ON c.PlanID = p.PlanID
								WHERE 
									c.ConventionID			= ISNULL(@iID_Convention, c.ConventionID)
									AND
									co.ConventionOperTypeID = @vcConventionOperTypeMntSouscrit
									AND
									o.OperTypeID			= @vcTypeOperationCategorie
									AND
									p.PlanTypeID			= 'COL'

								SELECT 
									@dtStartDateForIntAfterEstimatedRI = DATEADD(dd, 1, MAX(O.OperDate))
								FROM 
									dbo.Un_Oper o
									INNER JOIN dbo.Un_InterestRate i 
										ON i.OperID = o.OperID
								WHERE 
									o.OperDate < @dtMinOperDate
							END

						-- Sélection les groupes d'unités éligibles à l'intérêt du RI. Pour cela, faire
						-- une sélection des groupes d'unités (UnitID) de la table des groupes d'unités 
						-- dans la table Un_Unit
						DELETE FROM @tblUniteEligible

						INSERT INTO @tblUniteEligible
						(	
							iID_Unit
							,dtDateEstimeRI
							,dtDateDebutIntRI
						)
						SELECT 
							U.UnitID
							,DATEADD(mm, @iMonthNoIntAfterEstimatedRI, dbo.fn_Un_EstimatedIntReimbDate(m.PmtByYearID, m.PmtQty, m.BenefAgeOnBegining, u.InForceDate, p.IntReimbAge, NULL))
							,CASE 
								WHEN 
									DATEADD(mm, @iMonthNoIntAfterEstimatedRI, dbo.fn_Un_EstimatedIntReimbDate(m.PmtByYearID, M.PmtQty, m.BenefAgeOnBegining, u.InForceDate, p.IntReimbAge, NULL)) > @dtStartDateForIntAfterEstimatedRI 
										THEN 
											DATEADD(mm, @iMonthNoIntAfterEstimatedRI, dbo.fn_Un_EstimatedIntReimbDate(m.PmtByYearID, m.PmtQty, m.BenefAgeOnBegining, u.InForceDate, p.IntReimbAge, NULL))
								ELSE 
									@dtStartDateForIntAfterEstimatedRI
							END
						FROM 
								dbo.Un_Unit u
								INNER JOIN dbo.Un_Modal m
									ON m.ModalID = u.ModalID
								INNER JOIN dbo.Un_Plan p 
									ON p.PlanID = m.PlanID
						WHERE 
							(ISNULL(u.IntReimbDate, @dtDernierJourDuMoisATraiter + 1) > @dtDernierJourDuMoisATraiter)
							AND 
							(ISNULL(u.TerminatedDate, @dtDernierJourDuMoisATraiter + 1) > @dtDernierJourDuMoisATraiter)
							AND 
							p.PlanTypeID = 'COL'
							AND 
							(DATEADD(mm, @iMonthNoIntAfterEstimatedRI, dbo.fn_Un_EstimatedIntReimbDate(m.PmtByYearID, m.PmtQty, m.BenefAgeOnBegining, u.InForceDate, p.IntReimbAge, NULL)) <= @dtDernierJourDuMoisATraiter)

						DELETE ue FROM @tblUniteEligible AS ue
						WHERE 
							 NOT EXISTS
									(
										SELECT 
											1
										FROM 
											dbo.Un_Unit u
											INNER JOIN dbo.Un_Modal m
												ON m.ModalID = u.ModalID
											INNER JOIN dbo.Un_Cotisation ct 
												ON ct.UnitID = u.UnitID
											INNER JOIN dbo.Un_Oper o
												ON o.OperID = ct.OperID 
										WHERE 
											o.OperDate < DATEADD(MONTH,-@iMonthNoIntAfterEstimatedRI, @dtDernierJourDuMoisATraiter + 1)
											AND
											u.UnitID = ue.iID_Unit
										GROUP BY 
											u.UnitID,
											u.PmtEndConnectID,
											u.UnitQty,
											m.PmtRate,
											m.PmtQty
										HAVING 
											u.PmtEndConnectID > 0
											OR 
											SUM(ct.Cotisation + ct.Fee) >= ROUND(u.UnitQty * m.PmtRate,2)* m.PmtQty
									)

						-- OBTENIR TOUTES LES TRANSACTIONS ADMISSIBLE AU CALCUL DE RENDEMENT
						-- (EN FONCTION DES UNITÉS ÉLIGIBLES)

						--  ****** DÉBUT DU TRAITEMENT POUR LES TRANSACTIONS ANTÉRIEURES AU PREMIER JOUR DU MOIS À TRAITER ********
						-- Insertion des soldes d'intérêts RI
						INSERT INTO @tblTransactionConvention
						(
							iID_Convention
							,iJourOperation
							,mMontantRI2  
						)
						SELECT						-- Transactions ANTÉRIEURES au mois à traiter
							c.ConventionID
							,0
							,SUM(co.ConventionOperAmount) 	
						FROM
							@tblUniteEligible ue
							INNER JOIN dbo.Un_Unit u
								ON u.UnitID = ue.iID_Unit
							INNER JOIN dbo.Un_Convention c
								ON u.ConventionID = c.ConventionID 
							INNER JOIN	dbo.Un_ConventionConventionState ccs
								ON c.ConventionID = ccs.ConventionID
							INNER JOIN	dbo.Un_ConventionState cs
								ON cs.ConventionStateID = ccs.ConventionStateID
							INNER JOIN dbo.Un_ConventionOper co
								ON c.ConventionID = co.ConventionID
							INNER JOIN dbo.Un_Oper o
								ON co.OperID = o.OperID		
							INNER JOIN @tConventionState tmp
								ON ccs.ConventionID = tmp.ConventionID AND	ccs.StartDate = tmp.MostRecentDate
						WHERE
							c.ConventionID = ISNULL(@iID_Convention, c.ConventionID)
							AND
							cs.ConventionStateID IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire
							AND
							o.OperDate < @dtPremierJourDuMoisATraiter
							AND
							co.ConventionOperTypeID = @vcConventionOperTypeMntSouscrit	-- Type INM							
						GROUP BY
							c.ConventionID
						HAVING
							SUM(co.ConventionOperAmount) <> 0 -- > 0 FT 2011-03-17
						
						--  ****** FIN DU TRAITEMENT POUR LES TRANSACTIONS EN DATE DU PREMIER JOUR DU MOIS À TRAITER ********

						--  ****** DÉBUT DU TRAITEMENT POUR LE MOIS À TRAITER *******
						-- Calculer les soldes d'intérêts RI
						INSERT INTO @tblTransactionConvention
						(
							iID_Convention
							,iJourOperation
							,mMontantRI2  
						)
						SELECT						-- Transactions ANTÉRIEURES au mois à traiter
							c.ConventionID
							,DAY(o.OperDate)
							,SUM(co.ConventionOperAmount) 	
						FROM
							@tblUniteEligible ue
							INNER JOIN dbo.Un_Unit u
								ON u.UnitID = ue.iID_Unit
							INNER JOIN dbo.Un_Convention c
								ON u.ConventionID = c.ConventionID 
							INNER JOIN	dbo.Un_ConventionConventionState ccs
								ON c.ConventionID = ccs.ConventionID
							INNER JOIN	dbo.Un_ConventionState cs
								ON cs.ConventionStateID = ccs.ConventionStateID
							INNER JOIN dbo.Un_ConventionOper co
								ON c.ConventionID = co.ConventionID
							INNER JOIN dbo.Un_Oper o
								ON co.OperID = o.OperID		
							INNER JOIN @tConventionState tmp
								ON ccs.ConventionID = tmp.ConventionID AND	ccs.StartDate = tmp.MostRecentDate
						WHERE
							c.ConventionID = ISNULL(@iID_Convention, c.ConventionID)
							AND
							cs.ConventionStateID IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire
							AND
							o.OperDate BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter 
							AND
							co.ConventionOperTypeID = @vcConventionOperTypeMntSouscrit	-- Type INM							
						GROUP BY
							c.ConventionID
							,o.OperDate
						--  ****** FIN DU TRAITEMENT POUR LE MOIS À TRAITER *******

						-- GÉNÉRER LES RENDEMENTS SUR LES ÉPARGNES ET SUR LES FRAIS DES CONVENTIONS COLLECTIVES
						-- APRÈS LA DATE ESTIMÉE DU RI,	SI LE RI N'A PAS ENCORE EU LIEU DANS LA TABLES DES
						-- OPÉRATIONS SUR LES CONVENTIONS "Un_ConventionOper"

						-- CALCUL DU MONTANT ET INSERTION DES TRANSACTIONS DANS LA TABLE DES OPÉRATIONS SUR CONVENTIONS
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						) 
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeMntSouscrit
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantRI2,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention
						HAVING
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantRI2,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantRI2,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)

						IF @bActiveDebug = 1
							BEGIN
								IF (SELECT COUNT(*) FROM @tblTransactionConvention) > 0
									BEGIN
										SELECT '1.3.2.3.2 NEW : Rendement sur les revenus accumulés sur l''épargne et frais des conventions collectives après la date estimée du RI', tc.* 
										FROM @tblTransactionConvention tc
									END
								ELSE
									BEGIN
										SELECT '1.3.2.3.2 NEW : Rendement sur les revenus accumulés sur l''épargne et frais des conventions collectives après la date estimée du RI'
									END							
							END
																						
						-- SUPPRESSION DU CONTENU DE LA TABLE TEMPO
						DELETE FROM @tblTransactionConvention
		--  ****** FIN DU TRAITEMENT POUR LES TRANSACTIONS EN DATE DU PREMIER JOUR DU MOIS À TRAITER ********

		-- RENDEMENT SUR REVENUS ACCUMULÉS DES CONVENTIONS NOUVELLES ET EXISTANTES
						--  ****** DÉBUT DU TRAITEMENT POUR LES TRANSACTIONS ANTÉRIEURES AU PREMIER JOUR DU MOIS À TRAITER ********
						--	1. Calculer le solde de rendement de l'épargnes des conventions individuelles nouvelles et existantes
						--	   en date du premier jour du mois à traiter 
						--
						--	N.B.
						--		Calculer la somme de "ConventionOperAmount" dont le type 
						--		de régime est individuel. 
						INSERT INTO @tblTransactionConvention	
						(
							iID_Convention			
							,iJourOperation			
							,mMontantITR
						)
						SELECT
							c.ConventionID
							,0
							,SUM(co.ConventionOperAmount)
						FROM
							dbo.Un_Convention c
							INNER JOIN dbo.Un_ConventionOper co
								ON c.ConventionID = co.ConventionID
							INNER JOIN	dbo.Un_ConventionConventionState ccs
								ON c.ConventionID = ccs.ConventionID
							INNER JOIN	dbo.Un_ConventionState cs
								ON cs.ConventionStateID = ccs.ConventionStateID
							INNER JOIN dbo.Un_Plan p 
								ON p.PlanID = c.PlanID
							INNER JOIN dbo.Un_Oper o 
								ON o.OperID = co.OperID 
							INNER JOIN @tConventionState tmp
								ON ccs.ConventionID = tmp.ConventionID AND	ccs.StartDate = tmp.MostRecentDate
							INNER JOIN @tRIO rio
								ON rio.iID_Convention_Destination = c.ConventionID
						WHERE 
							c.ConventionId = ISNULL(@iID_Convention, c.ConventionID)
							AND
							p.PlanTypeID = 'IND'
							AND
							cs.ConventionStateID IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire
							AND 
							o.OperDate < @dtPremierJourDuMoisATraiter		
							AND
							co.ConventionOperTypeID = @vcConventionOperTypeMntSouscrit	
						GROUP BY 
							c.ConventionID
						HAVING
							SUM(co.ConventionOperAmount) <> 0 -- > 0 FT 2011-03-17
						
						--  ****** FIN DU TRAITEMENT POUR LES TRANSACTIONS EN DATE DU PREMIER JOUR DU MOIS À TRAITER ********

						--  ****** DÉBUT DU TRAITEMENT POUR LE MOIS À TRAITER *******	
						-- 1. Obtenir les nouvelles opérations d'épargne des nouvelles conventions
						--	  individuelles comprise dans le mois à traiter et dont la date de prospectus
						--	  est plus grande ou égale "A DÉTERMINER"
						--
						-- N.B.
						--	Calculer la somme du champ "ConventionOperAmount" de la table
						--	des opérations sur conventions dont le régime est individuel.
						INSERT INTO @tblTransactionConvention	
						(
							iID_Convention			
							,iJourOperation			
							,mMontantITR
						)
						SELECT
							c.ConventionID
							,DAY(o.OperDate)
							,SUM(co.ConventionOperAmount)
						FROM
							dbo.Un_Convention c
							INNER JOIN dbo.Un_ConventionOper co
								ON c.ConventionID = co.ConventionID
							INNER JOIN	dbo.Un_ConventionConventionState ccs
								ON c.ConventionID = ccs.ConventionID
							INNER JOIN	dbo.Un_ConventionState cs
								ON cs.ConventionStateID = ccs.ConventionStateID
							INNER JOIN dbo.Un_Plan p 
								ON p.PlanID = c.PlanID
							INNER JOIN dbo.Un_Oper o 
								ON o.OperID = co.OperID 
							INNER JOIN @tConventionState tmp
								ON ccs.ConventionID = tmp.ConventionID AND	ccs.StartDate = tmp.MostRecentDate
							INNER JOIN @tRIO rio
								ON rio.iID_Convention_Destination = c.ConventionID
						WHERE 
							c.ConventionId = ISNULL(@iID_Convention, c.ConventionID)
							AND
							p.PlanTypeID = 'IND'
							AND
							cs.ConventionStateID IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire
							AND 
							o.OperDate BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter 	
							AND
							co.ConventionOperTypeID = @vcConventionOperTypeMntSouscrit	
						GROUP BY 
							c.ConventionID
							,o.OperDate
						--  ****** FIN DU TRAITEMENT POUR LE MOIS À TRAITER *******
					

						-- CALCUL DU MONTANT ET INSERTION DES TRANSACTIONS DANS LA TABLE DES OPÉRATIONS SUR CONVENTIONS
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						) 
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeMntSouscrit
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantITR,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention
						HAVING
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantITR,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantITR,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)
																					
						IF @bActiveDebug = 1
							BEGIN
								IF (SELECT COUNT(*) FROM @tblTransactionConvention) > 0
									BEGIN
										SELECT '1.3.2.3.2 NEW : Rendement sur les revenus accumulés sur l''épargne et frais des conventions individuelles issues d''un RIO (Nouvelles et existantes)', tc.* 
										FROM @tblTransactionConvention tc
									END
								ELSE
									BEGIN
										SELECT '1.3.2.3.2 NEW : Rendement sur les revenus accumulés sur l''épargne et frais des conventions individuelles issues d''un RIO (Nouvelles et existantes)'
									END
							END

						-- SUPPRESSION DU CONTENU DE LA TABLE TEMPO
						DELETE FROM @tblTransactionConvention
					END
		END
	ELSE	-- TAUX MODIFIÉ @CETAT = 'C'
		BEGIN
			IF @vcCode_Rendement = 'RRI'
				BEGIN
					-- SUPPRESSION DES UNITÉS DU POINT 1.3.2.3.1
						DELETE FROM @tblUniteEligible

						-- RECHERCHE DES PARAMÈTRES PERMETTANT DE CALCULER LES RENDEMENTS APRÈS LA DATE ESTIMÉE DU RI
						-- À PARTIR DE LA TABLE UN_DEF
						SELECT
								@dtStartDateForIntAfterEstimatedRI	=	StartDateForIntAfterEstimatedRI
								,@iMonthNoIntAfterEstimatedRI		=	MonthNoIntAfterEstimatedRI
						FROM
							dbo.Un_Def

						-- DÉTERMINER LES UNITÉS QUI ONT DROIT À L'INTÉRÊT  APRÈS LA DATE ESTIMÉE
						-- DU REMBOURSEMENT INTÉGRAL (RI)
						SELECT
							@dtDateOperation = MIN(o.OperDate)
						FROM
							@tblTransactionConvention tc
							INNER JOIN
							dbo.Un_Convention c
								ON tc.iID_Convention = c.ConventionID
							INNER JOIN dbo.Un_ConventionOPER co
								ON c.ConventionID = co.ConventionID
							INNER JOIN dbo.Un_Oper o
								ON co.OperID = o.OperID
							INNER JOIN dbo.Un_Plan p
								ON c.PlanID = p.PlanID
						WHERE
							c.ConventionID			= ISNULL(@iID_Convention, c.ConventionID)
							AND
							co.ConventionOperTypeID = @vcConventionOperTypeMntSouscrit
							AND
							o.OperTypeID			= @vcTypeOperationCategorie
							AND
							p.PlanTypeID			= 'COL'
						HAVING MIN(O.OperDate) > @dtStartDateForIntAfterEstimatedRI

						-- Si existe, assigner  à la date de début pour intérêts après l'estimé du RI 
						-- la date d'opération + 1 journée
						IF @dtDateOperation IS NOT NULL	
							BEGIN		
								SELECT 
									@dtMinOperDate = MIN(O.OperDate)
								FROM 
									@tblTransactionConvention tc
									INNER JOIN
									dbo.Un_Convention c
										ON tc.iID_Convention = c.ConventionID
									INNER JOIN dbo.Un_ConventionOPER co
										ON c.ConventionID = co.ConventionID
									INNER JOIN dbo.Un_Oper o
										ON co.OperID = o.OperID
									INNER JOIN dbo.Un_Plan p
										ON c.PlanID = p.PlanID
								WHERE 
									c.ConventionID			= ISNULL(@iID_Convention, c.ConventionID)
									AND
									co.ConventionOperTypeID = @vcConventionOperTypeMntSouscrit
									AND
									o.OperTypeID			= @vcTypeOperationCategorie
									AND
									p.PlanTypeID			= 'COL'

								SELECT 
									@dtStartDateForIntAfterEstimatedRI = DATEADD(dd, 1, MAX(O.OperDate))
								FROM 
									dbo.Un_Oper o
									INNER JOIN dbo.Un_InterestRate i 
										ON i.OperID = o.OperID
								WHERE 
									o.OperDate < @dtMinOperDate
							END

						-- Sélection les groupes d'unités éligibles à l'intérêt du RI. Pour cela, faire
						-- une sélection des groupes d'unités (UnitID) de la table des groupes d'unités 
						-- dans la table Un_Unit
						DELETE FROM @tblUniteEligible

						INSERT INTO @tblUniteEligible
						(	
							iID_Unit
							,dtDateEstimeRI
							,dtDateDebutIntRI
						)
						SELECT 
							U.UnitID
							,DATEADD(mm, @iMonthNoIntAfterEstimatedRI, dbo.fn_Un_EstimatedIntReimbDate(m.PmtByYearID, m.PmtQty, m.BenefAgeOnBegining, u.InForceDate, p.IntReimbAge, NULL))
							,CASE 
								WHEN 
									DATEADD(mm, @iMonthNoIntAfterEstimatedRI, dbo.fn_Un_EstimatedIntReimbDate(m.PmtByYearID, M.PmtQty, m.BenefAgeOnBegining, u.InForceDate, p.IntReimbAge, NULL)) > @dtStartDateForIntAfterEstimatedRI 
										THEN 
											DATEADD(mm, @iMonthNoIntAfterEstimatedRI, dbo.fn_Un_EstimatedIntReimbDate(m.PmtByYearID, m.PmtQty, m.BenefAgeOnBegining, u.InForceDate, p.IntReimbAge, NULL))
								ELSE 
									@dtStartDateForIntAfterEstimatedRI
							END
						FROM 
								dbo.Un_Unit u
								INNER JOIN dbo.Un_Modal m
									ON m.ModalID = u.ModalID
								INNER JOIN dbo.Un_Plan p 
									ON p.PlanID = m.PlanID
						WHERE 
							(ISNULL(u.IntReimbDate, @dtDernierJourDuMoisATraiter + 1) > @dtDernierJourDuMoisATraiter)
							AND 
							(ISNULL(u.TerminatedDate, @dtDernierJourDuMoisATraiter + 1) > @dtDernierJourDuMoisATraiter)
							AND 
							p.PlanTypeID = 'COL'
							AND 
							(DATEADD(mm, @iMonthNoIntAfterEstimatedRI, dbo.fn_Un_EstimatedIntReimbDate(m.PmtByYearID, m.PmtQty, m.BenefAgeOnBegining, u.InForceDate, p.IntReimbAge, NULL)) <= @dtDernierJourDuMoisATraiter)

						DELETE ue FROM @tblUniteEligible AS ue
						WHERE 
							 NOT EXISTS
									(
										SELECT 
											1
										FROM 
											dbo.Un_Unit u
											INNER JOIN dbo.Un_Modal m
												ON m.ModalID = u.ModalID
											INNER JOIN dbo.Un_Cotisation ct 
												ON ct.UnitID = u.UnitID
											INNER JOIN dbo.Un_Oper o
												ON o.OperID = ct.OperID 
										WHERE 
											o.OperDate < DATEADD(MONTH,-@iMonthNoIntAfterEstimatedRI, @dtDernierJourDuMoisATraiter + 1)
											AND
											u.UnitID = ue.iID_Unit
										GROUP BY 
											u.UnitID,
											u.PmtEndConnectID,
											u.UnitQty,
											m.PmtRate,
											m.PmtQty
										HAVING 
											u.PmtEndConnectID > 0
											OR 
											SUM(ct.Cotisation + ct.Fee) >= ROUND(u.UnitQty * m.PmtRate,2)* m.PmtQty
									)

						-- OBTENIR TOUTES LES TRANSACTIONS ADMISSIBLE AU CALCUL DE RENDEMENT
						-- (EN FONCTION DES UNITÉS ÉLIGIBLES)

						--  ****** DÉBUT DU TRAITEMENT POUR LES TRANSACTIONS ANTÉRIEURES AU PREMIER JOUR DU MOIS À TRAITER ********
						-- Insertion des soldes d'intérêts RI
						INSERT INTO @tblTransactionConvention
						(
							iID_Convention
							,iJourOperation
							,mMontantRI2  
						)
						SELECT						-- Transactions ANTÉRIEURES au mois à traiter
							c.ConventionID
							,0
							,SUM(co.ConventionOperAmount) 	
						FROM
							@tblUniteEligible ue
							INNER JOIN dbo.Un_Unit u
								ON u.UnitID = ue.iID_Unit
							INNER JOIN dbo.Un_Convention c
								ON u.ConventionID = c.ConventionID 
							INNER JOIN dbo.Un_ConventionOper co
								ON c.ConventionID = co.ConventionID
							INNER JOIN dbo.Un_Oper o
								ON co.OperID = o.OperID		
						WHERE
							c.ConventionID = ISNULL(@iID_Convention, c.ConventionID)
							AND
							dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, c.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour
							AND
							o.OperDate < @dtPremierJourDuMoisATraiter
							AND
							co.ConventionOperTypeID = @vcConventionOperTypeMntSouscrit	-- Type INM							
						GROUP BY
							c.ConventionID
						HAVING
							SUM(co.ConventionOperAmount) <> 0 -- > 0 FT 2011-03-17
						
						--  ****** FIN DU TRAITEMENT POUR LES TRANSACTIONS EN DATE DU PREMIER JOUR DU MOIS À TRAITER ********

						-- SUPPRESION DES TRANSACTIONS DANS UN_CONVENTION_OPER
						DELETE cop
						FROM 
							dbo.Un_ConventionOper cop
							INNER JOIN dbo.Un_Oper o 
								ON o.OperID = cop.OperID 
						WHERE 
								cop.ConventionOperTypeID = @vcConventionOperTypeMntSouscrit	-- Type INM	
								AND
								cop.ConventionId = ISNULL(@iID_Convention, cop.ConventionID)
								AND
								dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, cop.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour
								AND
								cop.OperID IN (	SELECT 
													ISNULL(tx.iID_Operation,-1) 
												FROM 
													dbo.tblOper_TauxRendement tx
													INNER JOIN dbo.tblOPER_Rendements r
														ON tx.iID_Rendement = r.iID_Rendement
													INNER JOIN dbo.tblOPER_TypesRendement tr
														ON tr.tiID_Type_Rendement = r.tiID_Type_Rendement
												WHERE 
													ISNULL(tx.dtDate_Operation, '1900-01-01') BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter
													AND
													tr.vcCode_Rendement = @vcCode_Rendement)

						--  ****** DÉBUT DU TRAITEMENT POUR LE MOIS À TRAITER *******
						-- Calculer les soldes d'intérêts RI
						INSERT INTO @tblTransactionConvention
						(
							iID_Convention
							,iJourOperation
							,mMontantRI2  
						)
						SELECT						-- Transactions ANTÉRIEURES au mois à traiter
							c.ConventionID
							,DAY(o.OperDate)
							,SUM(co.ConventionOperAmount) 	
						FROM
							@tblUniteEligible ue
							INNER JOIN dbo.Un_Unit u
								ON u.UnitID = ue.iID_Unit
							INNER JOIN dbo.Un_Convention c
								ON u.ConventionID = c.ConventionID 
							INNER JOIN dbo.Un_ConventionOper co
								ON c.ConventionID = co.ConventionID
							INNER JOIN dbo.Un_Oper o
								ON co.OperID = o.OperID		
						WHERE
							c.ConventionID = ISNULL(@iID_Convention, c.ConventionID)
							AND
							dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, c.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour				
							AND 
							o.OperDate BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter
							AND
							co.ConventionOperTypeID = @vcConventionOperTypeMntSouscrit	-- Type INM							
						GROUP BY
							c.ConventionID
							,o.OperDate
						--  ****** FIN DU TRAITEMENT POUR LE MOIS À TRAITER *******

						-- GÉNÉRER LES RENDEMENTS SUR LES ÉPARGNES ET SUR LES FRAIS DES CONVENTIONS COLLECTIVES
						-- APRÈS LA DATE ESTIMÉE DU RI,	SI LE RI N'A PAS ENCORE EU LIEU DANS LA TABLES DES
						-- OPÉRATIONS SUR LES CONVENTIONS "Un_ConventionOper"

						-- CALCUL DU MONTANT ET INSERTION DES TRANSACTIONS DANS LA TABLE DES OPÉRATIONS SUR CONVENTIONS
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						) 
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeMntSouscrit
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantRI2,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention
						HAVING
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantRI2,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantRI2,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)

						IF @bActiveDebug = 1
							BEGIN
								IF (SELECT COUNT(*) FROM @tblTransactionConvention) > 0
									BEGIN
										SELECT '1.3.2.3.2 MOD : Rendement sur les revenus accumulés sur l''épargne et frais des conventions collectives après la date estimée du RI', tc.* 
										FROM @tblTransactionConvention tc
									END
								ELSE
									BEGIN
										SELECT '1.3.2.3.2 MOD : Rendement sur les revenus accumulés sur l''épargne et frais des conventions collectives après la date estimée du RI'
									END							
							END
																						
						-- SUPPRESSION DU CONTENU DE LA TABLE TEMPO
						DELETE FROM @tblTransactionConvention
		--  ****** FIN DU TRAITEMENT POUR LES TRANSACTIONS EN DATE DU PREMIER JOUR DU MOIS À TRAITER ********

		-- RENDEMENT SUR REVENUS ACCUMULÉS DES CONVENTIONS NOUVELLES ET EXISTANTES
						--  ****** DÉBUT DU TRAITEMENT POUR LES TRANSACTIONS ANTÉRIEURES AU PREMIER JOUR DU MOIS À TRAITER ********
						--	1. Calculer le solde de rendement de l'épargnes des conventions individuelles nouvelles et existantes
						--	   en date du premier jour du mois à traiter 
						--
						--	N.B.
						--		Calculer la somme de "ConventionOperAmount" dont le type 
						--		de régime est individuel. 
						INSERT INTO @tblTransactionConvention	
						(
							iID_Convention			
							,iJourOperation			
							,mMontantITR
						)
						SELECT
							c.ConventionID
							,0
							,SUM(co.ConventionOperAmount)
						FROM
							dbo.Un_Convention c
							INNER JOIN dbo.Un_ConventionOper co
								ON c.ConventionID = co.ConventionID							
							INNER JOIN dbo.Un_Plan p 
								ON p.PlanID = c.PlanID
							INNER JOIN dbo.Un_Oper o 
								ON o.OperID = co.OperID 
							INNER JOIN @tRIO rio
								ON rio.iID_Convention_Destination = c.ConventionID
						WHERE 
							c.ConventionId = ISNULL(@iID_Convention, c.ConventionID)
							AND
							p.PlanTypeID = 'IND'
							AND
							dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, c.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour
							AND 
							o.OperDate < @dtPremierJourDuMoisATraiter		
							AND
							co.ConventionOperTypeID = @vcConventionOperTypeMntSouscrit	
						GROUP BY 
							c.ConventionID
						HAVING
							SUM(co.ConventionOperAmount) <> 0 -- > 0 FT 2011-03-17
						
						--  ****** FIN DU TRAITEMENT POUR LES TRANSACTIONS EN DATE DU PREMIER JOUR DU MOIS À TRAITER ********

						-- SUPPRESSION DES TRANSACTIONS DANS UN_CONVENTION_OPER
						DELETE cop
						FROM 
							dbo.Un_ConventionOper cop
							INNER JOIN dbo.Un_Oper o 
								ON o.OperID = cop.OperID 
						WHERE 
								cop.ConventionOperTypeID = @vcConventionOperTypeMntSouscrit	-- Type INM	
								AND
								cop.ConventionId = ISNULL(@iID_Convention, cop.ConventionID)
								AND
								dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, cop.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour
								AND
								cop.OperID IN (	SELECT 
													ISNULL(tx.iID_Operation,-1) 
												FROM 
													dbo.tblOper_TauxRendement tx
													INNER JOIN dbo.tblOPER_Rendements r
														ON tx.iID_Rendement = r.iID_Rendement
													INNER JOIN dbo.tblOPER_TypesRendement tr
														ON tr.tiID_Type_Rendement = r.tiID_Type_Rendement
												WHERE 
													ISNULL(tx.dtDate_Operation, '1900-01-01') BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter
													AND
													tr.vcCode_Rendement = @vcCode_Rendement)

						--  ****** DÉBUT DU TRAITEMENT POUR LE MOIS À TRAITER *******	
						INSERT INTO @tblTransactionConvention	
						(
							iID_Convention			
							,iJourOperation			
							,mMontantITR
						)
						SELECT
							c.ConventionID
							,DAY(o.OperDate)
							,SUM(co.ConventionOperAmount)
						FROM
							dbo.Un_Convention c
							INNER JOIN dbo.Un_ConventionOper co
								ON c.ConventionID = co.ConventionID
							INNER JOIN dbo.Un_Plan p 
								ON p.PlanID = c.PlanID
							INNER JOIN dbo.Un_Oper o 
								ON o.OperID = co.OperID 
							INNER JOIN @tRIO rio
								ON rio.iID_Convention_Destination = c.ConventionID
						WHERE 
							c.ConventionId = ISNULL(@iID_Convention, c.ConventionID)
							AND
							p.PlanTypeID = 'IND'
							AND
							dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, c.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour				
							AND 
							o.OperDate BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter
							AND
							co.ConventionOperTypeID = @vcConventionOperTypeMntSouscrit	
						GROUP BY 
							c.ConventionID
							,o.OperDate
						--  ****** FIN DU TRAITEMENT POUR LE MOIS À TRAITER *******
					

						-- CALCUL DU MONTANT ET INSERTION DES TRANSACTIONS DANS LA TABLE DES OPÉRATIONS SUR CONVENTIONS
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						) 
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeMntSouscrit
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantITR,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention
						HAVING
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantITR,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantITR,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)
																					
						IF @bActiveDebug = 1
							BEGIN
								IF (SELECT COUNT(*) FROM @tblTransactionConvention) > 0
									BEGIN
										SELECT '1.3.2.3.2 MOD : Rendement sur les revenus accumulés sur l''épargne et frais des conventions individuelles issues d''un RIO (Nouvelles et existantes)', tc.* 
										FROM @tblTransactionConvention tc
									END
								ELSE
									BEGIN
										SELECT '1.3.2.3.2 MOD : Rendement sur les revenus accumulés sur l''épargne et frais des conventions individuelles issues d''un RIO (Nouvelles et existantes)'
									END
							END

						-- SUPPRESSION DU CONTENU DE LA TABLE TEMPO
						DELETE FROM @tblTransactionConvention
				END
		END
-------------------------------------------------------------------------------------------------------------------------------
					-- FIN DU CALCUL DU RENDEMENT POUR LES SUBVENTIONS FÉDÉRALES DES CONVENTIONS COLLECTIVES ET INDIVIDUELLES
-------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------------------
-- 1.3.2.3.3		-- DÉBUT DU CALCUL DU RENDEMENT POUR LES SUBVENTIONS FÉDÉRALES DES CONVENTIONS COLLECTIVES ET INDIVIDUELLES
-------------------------------------------------------------------------------------------------------------------------------
	IF @cEtat = 'S' -- nouveau rendement
		BEGIN
					--Valide si c'est le bon code de rendement pour ce traitement
					IF @vcCode_Rendement = 'TSF'
					BEGIN
					--  ****** DÉBUT DU TRAITEMENT POUR LES TRANSACTIONS ANTÉRIEURES AU PREMIER JOUR DU MOIS À TRAITER ********				

					--	1. Calculer les soldes des subventions fédérales en date du premier jour du mois à traiter
					--	   "Date d'opération est plus petite que la date du premier jour du mois à traiter"
					--		
					--	N.B.
					--	Calculer la somme des champs "fCESG", "fACESG" et "fCLB" de la table des entrées et sorties
					--	d'argent du PCEE "Un_CESP". Additionner le montant de la subvention provinciales de l'Alberta
					-- "fPG" à celui de la subvention fédérale de base "fCESG"
						INSERT INTO @tblTransactionConvention
						(
							iID_Convention			
							,iJourOperation			
							,mMontantCESG			
							,mMontantACESG			
							,mMontantCLB			
						)	
						SELECT
							c.ConventionID
							,0
							
							-- FT 2011-03-17
							--,CASE WHEN (SUM(ce.fCESG) + SUM(ce.fPG)) > 0 THEN (SUM(ce.fCESG) + SUM(ce.fPG))
							--	  ELSE 0
							-- END
							,(SUM(ce.fCESG) + SUM(ce.fPG))
							--,CASE	WHEN SUM(ce.fACESG) > 0 THEN SUM(ce.fACESG)
							--		ELSE 0
							-- END	
							,SUM(ce.fACESG)
							
							--,CASE WHEN SUM(ce.fCLB)	> 0 THEN SUM(ce.fCLB)
							--	  ELSE 0
							-- END
							,SUM(ce.fCLB)
						FROM
							dbo.Un_Convention c
							INNER JOIN	dbo.Un_ConventionConventionState ccs
								ON c.ConventionID = ccs.ConventionID
							INNER JOIN	dbo.Un_ConventionState cs
								ON cs.ConventionStateID = ccs.ConventionStateID
							INNER JOIN dbo.Un_CESP ce
								ON c.ConventionID = ce.ConventionID
							INNER JOIN dbo.Un_Oper o
								ON o.OperID = ce.OperID 
							INNER JOIN @tConventionState tmp
								ON ccs.ConventionID = tmp.ConventionID AND	ccs.StartDate = tmp.MostRecentDate
						WHERE
							c.ConventionID = ISNULL(@iID_Convention, c.ConventionID)
							AND
							cs.ConventionStateID IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire
							AND
							o.OperDate < @dtPremierJourDuMoisATraiter
						GROUP BY
							c.ConventionID				
						--  ****** FIN DU TRAITEMENT POUR LES TRANSACTIONS EN DATE DU PREMIER JOUR DU MOIS À TRAITER ********

						--  ****** DÉBUT DU TRAITEMENT POUR LE MOIS À TRAITER *******
					
						-- 1. Obtenir toutes les nouvelles opérations des subventions fédérales pour le mois
						--	  à traiter "Date d'opération comprise entre date du premier jour et date du dernier
						--	  jour du mois à traiter"
						--		
						--	N.B.
						--	Calculer la somme des champs "fCESG", "fACESG" et "fCLB" de la table des entrées et sorties
						--	d'argent du PCEE "Un_CESP". Additionner le montant de la subvention provinciales de l'Alberta
						-- "fPG" à celui de la subvention fédérale de base "fCESG"			
						INSERT INTO @tblTransactionConvention
						(
							iID_Convention			
							,iJourOperation			
							,mMontantCESG			
							,mMontantACESG			
							,mMontantCLB			
						)	
						SELECT
							c.ConventionID
							,DAY(o.OperDate)
							,SUM(ce.fCESG) + SUM(ce.fPG)		
							,SUM(ce.fACESG)	
							,SUM(ce.fCLB)	
						FROM
							dbo.Un_Convention c
							INNER JOIN	dbo.Un_ConventionConventionState ccs
								ON c.ConventionID = ccs.ConventionID
							INNER JOIN	dbo.Un_ConventionState cs
								ON cs.ConventionStateID = ccs.ConventionStateID
							INNER JOIN dbo.Un_CESP ce
								ON c.ConventionID = ce.ConventionID
							INNER JOIN dbo.Un_Oper o
								ON o.OperID = ce.OperID 
							INNER JOIN @tConventionState tmp
								ON ccs.ConventionID = tmp.ConventionID AND	ccs.StartDate = tmp.MostRecentDate
						WHERE
							c.ConventionID = ISNULL(@iID_Convention, c.ConventionID)
							AND
							cs.ConventionStateID IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire
							AND
							o.OperDate BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter 
						GROUP BY
							c.ConventionID			
							,o.OperDate
						--  ****** FIN DU TRAITEMENT POUR LE MOIS À TRAITER *******

						-- CALCUL DU MONTANT ET INSERTION DES TRANSACTIONS DANS LA TABLE DES OPÉRATIONS SUR CONVENTIONS
						-- 1. Insertion des rendements générés pour les SCEE de base "INS"
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						) 
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeSCEE
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantCESG,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention
						HAVING 
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantCESG,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantCESG,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)
																			 
						
						-- 2. Insertion des rendements générés pour les SCEE bonifié "IS+"
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						) 
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeSCEEPlus
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantACESG,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention
						HAVING
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantACESG,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantACESG,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)
																					
																						
						-- 3. Insertion des rendements générés pour les types BEC "IBC"
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						) 
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeBEC
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantCLB,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention
						HAVING
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantCLB,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantCLB,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)
																					

						IF @bActiveDebug = 1
							BEGIN
								IF (SELECT COUNT(*) FROM @tblTransactionConvention) > 0
									BEGIN
										SELECT '1.3.2.3.3 NEW : INS, IS+, IBC', tc.* 
										FROM @tblTransactionConvention tc
									END
								ELSE
									BEGIN
										SELECT '1.3.2.3.3 NEW : INS, IS+, IBC'
									END			
							END

						-- SUPPRESSION DU CONTENU DE LA TABLE TEMPO
						DELETE FROM @tblTransactionConvention
					END
		END
	ELSE	-- TAUX MODIFIÉ @CETAT = 'C'
		BEGIN
			IF @vcCode_Rendement = 'TSF'
				BEGIN
					--  ****** DÉBUT DU TRAITEMENT POUR LES TRANSACTIONS ANTÉRIEURES AU PREMIER JOUR DU MOIS À TRAITER ********				
						INSERT INTO @tblTransactionConvention
						(
							iID_Convention			
							,iJourOperation			
							,mMontantCESG			
							,mMontantACESG			
							,mMontantCLB			
						)	
						SELECT
							c.ConventionID
							,0
							
							-- FT 2011-03-17
							--,CASE	WHEN (SUM(ce.fCESG) + SUM(ce.fPG)) > 0 THEN (SUM(ce.fCESG) + SUM(ce.fPG))
							--		ELSE 0
							-- END
							,(SUM(ce.fCESG) + SUM(ce.fPG))
							
							--,CASE	WHEN SUM(ce.fACESG) > 0 THEN 	SUM(ce.fACESG)
							--		ELSE 0
							-- END
							,SUM(ce.fACESG)
							
							--,CASE	WHEN SUM(ce.fCLB)	> 0 THEN SUM(ce.fCLB)
							--		ELSE 0
							-- END
							,SUM(ce.fCLB)
						FROM
							dbo.Un_Convention c
							INNER JOIN dbo.Un_CESP ce
								ON c.ConventionID = ce.ConventionID
							INNER JOIN dbo.Un_Oper o
								ON o.OperID = ce.OperID 
						WHERE
							c.ConventionID = ISNULL(@iID_Convention, c.ConventionID)
							AND
							dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, c.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour
							AND
							o.OperDate < @dtPremierJourDuMoisATraiter
						GROUP BY
							c.ConventionID				
						--  ****** FIN DU TRAITEMENT POUR LES TRANSACTIONS EN DATE DU PREMIER JOUR DU MOIS À TRAITER ********

						-- SUPPRESION DES TRANSACTIONS DANS UN_CONVENTION_OPER
						DELETE cop
						FROM 
							dbo.Un_ConventionOper cop
							INNER JOIN dbo.Un_Oper o 
								ON o.OperID = cop.OperID 
						WHERE 
								cop.ConventionId = ISNULL(@iID_Convention, cop.ConventionID)
								AND
								dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, cop.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour
								AND
								cop.OperID IN (	SELECT ISNULL(tx.iID_Operation,-1) 
												FROM 
													dbo.tblOper_TauxRendement tx
													INNER JOIN dbo.tblOPER_Rendements r
														ON tx.iID_Rendement = r.iID_Rendement
													INNER JOIN dbo.tblOPER_TypesRendement tr
														ON tr.tiID_Type_Rendement = r.tiID_Type_Rendement
												WHERE 
													ISNULL(tx.dtDate_oPERATION, '1900-01-01') BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter
													AND
													tr.vcCode_Rendement = @vcCode_Rendement)

						--  ****** DÉBUT DU TRAITEMENT POUR LE MOIS À TRAITER *******
						INSERT INTO @tblTransactionConvention
						(
							iID_Convention			
							,iJourOperation			
							,mMontantCESG			
							,mMontantACESG			
							,mMontantCLB			
						)	
						SELECT
							c.ConventionID
							,DAY(o.OperDate)
							,SUM(ce.fCESG) + SUM(ce.fPG)		
							,SUM(ce.fACESG)	
							,SUM(ce.fCLB)	
						FROM
							dbo.Un_Convention c
							INNER JOIN dbo.Un_CESP ce
								ON c.ConventionID = ce.ConventionID
							INNER JOIN dbo.Un_Oper o
								ON o.OperID = ce.OperID 
						WHERE
							c.ConventionID = ISNULL(@iID_Convention, c.ConventionID)
							AND
							dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, c.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour				
							AND 
							o.OperDate BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter
						GROUP BY
							c.ConventionID			
							,o.OperDate
						--  ****** FIN DU TRAITEMENT POUR LE MOIS À TRAITER *******

						-- CALCUL DU MONTANT ET INSERTION DES TRANSACTIONS DANS LA TABLE DES OPÉRATIONS SUR CONVENTIONS
						-- 1. Insertion des rendements générés pour les SCEE de base "INS"
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						) 
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeSCEE
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantCESG,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention
						HAVING 
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantCESG,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantCESG,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)
																			 
						
						-- 2. Insertion des rendements générés pour les SCEE bonifié "IS+"
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						) 
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeSCEEPlus
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantACESG,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention
						HAVING 
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantACESG,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantACESG,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)
																					
																						
						-- 3. Insertion des rendements générés pour les types BEC "IBC"
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						) 
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeBEC
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantCLB,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention
						HAVING
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantCLB,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantCLB,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)
																					

						IF @bActiveDebug = 1
							BEGIN
								IF (SELECT COUNT(*) FROM @tblTransactionConvention) > 0
									BEGIN
										SELECT '1.3.2.3.3 MOD : INS, IS+, IBC', tc.* 
										FROM @tblTransactionConvention tc
									END
								ELSE
									BEGIN
										SELECT '1.3.2.3.3 MOD : INS, IS+, IBC'
									END			
							END

						-- SUPPRESSION DU CONTENU DE LA TABLE TEMPO
						DELETE FROM @tblTransactionConvention
				END
		END
-------------------------------------------------------------------------------------------------------------------------------
					-- FIN DU CALCUL DU RENDEMENT POUR LES SUBVENTIONS FÉDÉRALES DES CONVENTIONS COLLECTIVES ET INDIVIDUELLES
-------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------------------------
-- 1.3.2.3.4		-- DÉBUT DU CALCUL DU RENDEMENT POUR LES SUBVENTIONS FÉDÉRALES DES CONVENTIONS COLLECTIVES ET INDIVIDUELLES
					-- ET SUR LES REVENUS ACCUMULÉS SUR SUBVENTIONS PROVENANT D'UN TRANSFERT IN (INS, IS+, IBC, IST)	
---------------------------------------------------------------------------------------------------------------------------------
	IF @cEtat = 'S' -- nouveau rendement
		BEGIN
					--Valide si c'est le bon code de rendement pour ce traitement
					IF @vcCode_Rendement = 'RSF'
					BEGIN
						-- A. RENDEMENT SUR TYPES D'OPÉRATIONS INS, IS+, IBC
						--  ****** DÉBUT DU TRAITEMENT POUR LES TRANSACTIONS ANTÉRIEURES AU PREMIER JOUR DU MOIS À TRAITER ********				

						-- 1. Calculer les soldes des rendements des subventions fédérales en date du premier jour du mois à traiter
						--    "Date d'opération plus petite que la date du premier jour du mois à traiter"
						INSERT INTO @tblTransactionConvention	
						(
							iID_Convention			
							,iJourOperation			
							,mMontantCESG			
							,mMontantACESG			
							,mMontantCLB			
						)
						SELECT						-- INS, IS+, IBC
							c.ConventionID
							,0

							-- FT 2011-03-17
							--,CASE	WHEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeSCEE THEN co.ConventionOperAmount ELSE 0 END) > 0 THEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeSCEE THEN co.ConventionOperAmount ELSE 0 END)
							--		ELSE 0
							-- END
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeSCEE THEN co.ConventionOperAmount ELSE 0 END)
							 
							--,CASE	WHEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeSCEEPlus THEN co.ConventionOperAmount ELSE 0 END) > 0 THEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeSCEEPlus THEN co.ConventionOperAmount ELSE 0 END)
							--		ELSE 0
							-- END
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeSCEEPlus THEN co.ConventionOperAmount ELSE 0 END)
							
							--,CASE	WHEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeBEC THEN co.ConventionOperAmount ELSE 0 END) > 0 THEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeBEC THEN co.ConventionOperAmount ELSE 0 END)
							--		ELSE 0
							-- END
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeBEC THEN co.ConventionOperAmount ELSE 0 END)
						FROM
							dbo.Un_Convention c
							INNER JOIN	dbo.Un_ConventionConventionState ccs
								ON c.ConventionID = ccs.ConventionID
							INNER JOIN	dbo.Un_ConventionState cs
								ON cs.ConventionStateID = ccs.ConventionStateID
							INNER JOIN dbo.Un_ConventionOper co
								ON c.ConventionID = co.ConventionID
							INNER JOIN dbo.Un_Oper o
								ON co.OperID = o.OperID		
							INNER JOIN @tConventionState tmp
								ON ccs.ConventionID = tmp.ConventionID AND	ccs.StartDate = tmp.MostRecentDate
						WHERE
							c.ConventionID = ISNULL(@iID_Convention, c.ConventionID)
							AND
							cs.ConventionStateID IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire
							AND
							o.OperDate < @dtPremierJourDuMoisATraiter
							AND
							(
								co.ConventionOperTypeID = @vcConventionOperTypeSCEE	-- 'INS'
								OR
								co.ConventionOperTypeID = @vcConventionOperTypeSCEEPlus	-- IS+
								OR
								co.ConventionOperTypeID = @vcConventionOperTypeBEC	-- IBC
							)
						GROUP BY
							c.ConventionID	
					
						--  ****** FIN DU TRAITEMENT POUR LES TRANSACTIONS EN DATE DU PREMIER JOUR DU MOIS À TRAITER ********

						--  ****** DÉBUT DU TRAITEMENT POUR LE MOIS À TRAITER *******	
						INSERT INTO @tblTransactionConvention
						(
							iID_Convention			
							,iJourOperation			
							,mMontantCESG			
							,mMontantACESG			
							,mMontantCLB			
						)	
						SELECT						-- INS, IS+, IBC
							c.ConventionID
							,DAY(o.OperDate)
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeSCEE THEN co.ConventionOperAmount ELSE 0 END)
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeSCEEPlus THEN co.ConventionOperAmount ELSE 0 END)
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeBEC THEN co.ConventionOperAmount ELSE 0 END)
						FROM
							dbo.Un_Convention c
							INNER JOIN	dbo.Un_ConventionConventionState ccs
								ON c.ConventionID = ccs.ConventionID
							INNER JOIN	dbo.Un_ConventionState cs
								ON cs.ConventionStateID = ccs.ConventionStateID
							INNER JOIN dbo.Un_ConventionOper co
								ON c.ConventionID = co.ConventionID
							INNER JOIN dbo.Un_Oper o
								ON co.OperID = o.OperID		
							INNER JOIN @tConventionState tmp
								ON ccs.ConventionID = tmp.ConventionID AND	ccs.StartDate = tmp.MostRecentDate
						WHERE
							c.ConventionID = ISNULL(@iID_Convention, c.ConventionID)
							AND
							cs.ConventionStateID IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire
							AND
							o.OperDate BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter 
							AND
							(
								co.ConventionOperTypeID = @vcConventionOperTypeSCEE	-- 'INS'
								OR
								co.ConventionOperTypeID = @vcConventionOperTypeSCEEPlus	-- IS+
								OR
								co.ConventionOperTypeID = @vcConventionOperTypeBEC	-- IBC
							)
						GROUP BY
							c.ConventionID
							,o.OperDate					
						--  ****** FIN DU TRAITEMENT POUR LE MOIS À TRAITER *******

						-- CALCUL DU MONTANT ET INSERTION DES TRANSACTIONS DANS LA TABLE DES OPÉRATIONS SUR CONVENTIONS
						-- 1. Insertion des rendements générés pour les SCEE de base "INS"
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						)  
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeSCEE
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantCESG,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention
						HAVING
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantCESG,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantCESG,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)
																					
						
						-- 2. Insertion des rendements générés pour les SCEE bonifié "IS+"
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						)  
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeSCEEPlus
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantACESG,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention
						HAVING
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantACESG,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantACESG,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)
																					
																						
						-- 3. Insertion des rendements générés pour les types BEC "IBC"
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						) 
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeBEC
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantCLB,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention
						HAVING
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantCLB,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantCLB,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)
																					

						IF @bActiveDebug = 1
							BEGIN
								IF (SELECT COUNT(*) FROM @tblTransactionConvention) > 0
									BEGIN
										SELECT '1.3.2.3.4 NEW : INS, IS+, IBC', tc.* 
										FROM @tblTransactionConvention tc
									END
								ELSE
									BEGIN
										SELECT '1.3.2.3.4 NEW : INS, IS+, IBC'
									END			
							END

						-- SUPPRESSION DU CONTENU DE LA TABLE TEMPO
						DELETE FROM @tblTransactionConvention


						-- B. RENDEMENT SUR OPÉRATION IST (REVENUS ACCUMULÉS SUR SUBVENTION PROVENANT D'UN TRANSFERT TIN)
						--  ****** DÉBUT DU TRAITEMENT POUR LES TRANSACTIONS ANTÉRIEURES AU PREMIER JOUR DU MOIS À TRAITER ********				
						INSERT INTO @tblTransactionConvention
						(
							iID_Convention			
							,iJourOperation			
							,mMontantIST		
						)
						SELECT						-- IST
							c.ConventionID
							,0
							,SUM(co.ConventionOperAmount)
						FROM
							dbo.Un_Convention c
							INNER JOIN	dbo.Un_ConventionConventionState ccs
								ON c.ConventionID = ccs.ConventionID
							INNER JOIN	dbo.Un_ConventionState cs
								ON cs.ConventionStateID = ccs.ConventionStateID
							INNER JOIN dbo.Un_ConventionOper co
								ON c.ConventionID = co.ConventionID
							INNER JOIN dbo.Un_Oper o
								ON co.OperID = o.OperID		
							INNER JOIN @tConventionState tmp
								ON ccs.ConventionID = tmp.ConventionID AND	ccs.StartDate = tmp.MostRecentDate
						WHERE
							c.ConventionID = ISNULL(@iID_Convention, c.ConventionID)
							AND
							cs.ConventionStateID IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire
							AND
							o.OperDate < @dtPremierJourDuMoisATraiter
							AND
							co.ConventionOperTypeID = @vcConventionOperTypeRendement_PCEE_TIN	
						GROUP BY
							c.ConventionID
						HAVING
							SUM(co.ConventionOperAmount) <> 0 -- > 0 FT 2011-03-17
						
						--  ****** FIN DU TRAITEMENT POUR LES TRANSACTIONS EN DATE DU PREMIER JOUR DU MOIS À TRAITER ********

						--  ****** DÉBUT DU TRAITEMENT POUR LE MOIS À TRAITER *******	
						INSERT INTO @tblTransactionConvention
						(
							iID_Convention			
							,iJourOperation			
							,mMontantIST		
						)
						SELECT						-- IST
							c.ConventionID
							,DAY(o.OperDate)
							,SUM(co.ConventionOperAmount)
						FROM
							dbo.Un_Convention c
							INNER JOIN	dbo.Un_ConventionConventionState ccs
								ON c.ConventionID = ccs.ConventionID
							INNER JOIN	dbo.Un_ConventionState cs
								ON cs.ConventionStateID = ccs.ConventionStateID
							INNER JOIN dbo.Un_ConventionOper co
								ON c.ConventionID = co.ConventionID
							INNER JOIN dbo.Un_Oper o
								ON co.OperID = o.OperID		
							INNER JOIN @tConventionState tmp
								ON ccs.ConventionID = tmp.ConventionID AND	ccs.StartDate = tmp.MostRecentDate
						WHERE
							c.ConventionID = ISNULL(@iID_Convention, c.ConventionID)
							AND
							cs.ConventionStateID IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire
							AND
							o.OperDate BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter 
							AND
							co.ConventionOperTypeID = @vcConventionOperTypeRendement_PCEE_TIN	
						GROUP BY
							c.ConventionID
							,o.OperDate
						--  ****** FIN DU TRAITEMENT POUR LE MOIS À TRAITER *******

						-- Insertion des rendements générés pour le type ist
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						)
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeRendement_PCEE_TIN
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantIST,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention
						HAVING
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantIST,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantIST,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)
																					

						IF @bActiveDebug = 1
							BEGIN
								IF (SELECT COUNT(*) FROM @tblTransactionConvention) > 0
									BEGIN
										SELECT '1.3.2.3.4 NEW : IST', tc.* 
										FROM @tblTransactionConvention tc
									END
								ELSE
									BEGIN
										SELECT '1.3.2.3.4 NEW : IST'
									END			
							END

						-- SUPPRESSION DU CONTENU DE LA TABLE TEMPO
						DELETE FROM @tblTransactionConvention
					END					
		END
	ELSE -- TAUX MODIFIÉ @CETAT = 'C'
		BEGIN
			IF @vcCode_Rendement = 'RSF'
				BEGIN
-- A. RENDEMENT SUR TYPES D'OPÉRATIONS INS, IS+, IBC
						--  ****** DÉBUT DU TRAITEMENT POUR LES TRANSACTIONS ANTÉRIEURES AU PREMIER JOUR DU MOIS À TRAITER ********				
						INSERT INTO @tblTransactionConvention	
						(
							iID_Convention			
							,iJourOperation			
							,mMontantCESG			
							,mMontantACESG			
							,mMontantCLB			
						)
						SELECT						-- INS, IS+, IBC
							c.ConventionID
							,0
							
							-- FT 2011-03-17
							--,CASE	WHEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeSCEE THEN co.ConventionOperAmount ELSE 0 END) > 0 THEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeSCEE THEN co.ConventionOperAmount ELSE 0 END)
							--		ELSE 0
							-- END
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeSCEE THEN co.ConventionOperAmount ELSE 0 END)

							--,CASE	WHEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeSCEEPlus THEN co.ConventionOperAmount ELSE 0 END) > 0 THEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeSCEEPlus THEN co.ConventionOperAmount ELSE 0 END)
							--		ELSE 0
							-- END
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeSCEEPlus THEN co.ConventionOperAmount ELSE 0 END)

							--,CASE	WHEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeBEC THEN co.ConventionOperAmount ELSE 0 END) > 0 THEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeBEC THEN co.ConventionOperAmount ELSE 0 END)
							--		ELSE 0
							-- END
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeBEC THEN co.ConventionOperAmount ELSE 0 END)
						FROM
							dbo.Un_Convention c
							INNER JOIN dbo.Un_ConventionOper co
								ON c.ConventionID = co.ConventionID
							INNER JOIN dbo.Un_Oper o
								ON co.OperID = o.OperID		
						WHERE
							c.ConventionID = ISNULL(@iID_Convention, c.ConventionID)
							AND
							dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, c.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour
							AND
							o.OperDate < @dtPremierJourDuMoisATraiter
							AND
							(
								co.ConventionOperTypeID = @vcConventionOperTypeSCEE	-- 'INS'
								OR
								co.ConventionOperTypeID = @vcConventionOperTypeSCEEPlus	-- IS+
								OR
								co.ConventionOperTypeID = @vcConventionOperTypeBEC	-- IBC
							)
						GROUP BY
							c.ConventionID	
					
						--  ****** FIN DU TRAITEMENT POUR LES TRANSACTIONS EN DATE DU PREMIER JOUR DU MOIS À TRAITER ********

						-- SUPPRESSION DES TRANSACTIONS DANS UN_CONVENTION_OPER
						DELETE cop
						FROM 
							dbo.Un_ConventionOper cop
							INNER JOIN dbo.Un_Oper o 
								ON o.OperID = cop.OperID 
						WHERE 
								cop.ConventionId = ISNULL(@iID_Convention, cop.ConventionID)
								AND
								dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, cop.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour
								AND
								cop.OperID IN (	SELECT ISNULL(tx.iID_Operation,-1) 
												FROM 
													dbo.tblOper_TauxRendement tx
													INNER JOIN dbo.tblOPER_Rendements r
														ON tx.iID_Rendement = r.iID_Rendement
													INNER JOIN dbo.tblOPER_TypesRendement tr
														ON tr.tiID_Type_Rendement = r.tiID_Type_Rendement
												WHERE 
													ISNULL(tx.dtDate_oPERATION, '1900-01-01') BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter
													AND
													tr.vcCode_Rendement = @vcCode_Rendement)

						--  ****** DÉBUT DU TRAITEMENT POUR LE MOIS À TRAITER *******	
						INSERT INTO @tblTransactionConvention
						(
							iID_Convention			
							,iJourOperation			
							,mMontantCESG			
							,mMontantACESG			
							,mMontantCLB			
						)	
						SELECT						-- INS, IS+, IBC
							c.ConventionID
							,DAY(o.OperDate)
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeSCEE THEN co.ConventionOperAmount ELSE 0 END)
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeSCEEPlus THEN co.ConventionOperAmount ELSE 0 END)
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeBEC THEN co.ConventionOperAmount ELSE 0 END)
						FROM
							dbo.Un_Convention c
							INNER JOIN dbo.Un_ConventionOper co
								ON c.ConventionID = co.ConventionID
							INNER JOIN dbo.Un_Oper o
								ON co.OperID = o.OperID									
						WHERE
							c.ConventionID = ISNULL(@iID_Convention, c.ConventionID)
							AND
							dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, c.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour				
							AND 
							o.OperDate BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter
							AND
							(
								co.ConventionOperTypeID = @vcConventionOperTypeSCEE	-- 'INS'
								OR
								co.ConventionOperTypeID = @vcConventionOperTypeSCEEPlus	-- IS+
								OR
								co.ConventionOperTypeID = @vcConventionOperTypeBEC	-- IBC
							)
						GROUP BY
							c.ConventionID
							,o.OperDate					
						--  ****** FIN DU TRAITEMENT POUR LE MOIS À TRAITER *******

						-- CALCUL DU MONTANT ET INSERTION DES TRANSACTIONS DANS LA TABLE DES OPÉRATIONS SUR CONVENTIONS
						-- 1. Insertion des rendements générés pour les SCEE de base "INS"
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						)  
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeSCEE
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantCESG,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention
						HAVING
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantCESG,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantCESG,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)
																					
						
						-- 2. Insertion des rendements générés pour les SCEE bonifié "IS+"
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						)  
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeSCEEPlus
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantACESG,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention
						HAVING
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantACESG,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantACESG,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)
																					
																						
						-- 3. Insertion des rendements générés pour les types BEC "IBC"
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						) 
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeBEC
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantCLB,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention
						HAVING
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantCLB,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantCLB,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)
																					

						IF @bActiveDebug = 1
							BEGIN
								IF (SELECT COUNT(*) FROM @tblTransactionConvention) > 0
									BEGIN
										SELECT '1.3.2.3.4 MOD : INS, IS+, IBC', tc.* 
										FROM @tblTransactionConvention tc
									END
								ELSE
									BEGIN
										SELECT '1.3.2.3.4 MOD : INS, IS+, IBC'
									END			
							END

						-- SUPPRESSION DU CONTENU DE LA TABLE TEMPO
						DELETE FROM @tblTransactionConvention


						-- B. RENDEMENT SUR OPÉRATION IST (REVENUS ACCUMULÉS SUR SUBVENTION PROVENANT D'UN TRANSFERT TIN)
						--  ****** DÉBUT DU TRAITEMENT POUR LES TRANSACTIONS ANTÉRIEURES AU PREMIER JOUR DU MOIS À TRAITER ********				
						INSERT INTO @tblTransactionConvention
						(
							iID_Convention			
							,iJourOperation			
							,mMontantIST		
						)
						SELECT						-- IST
							c.ConventionID
							,0
							,SUM(co.ConventionOperAmount)
						FROM
							dbo.Un_Convention c
							INNER JOIN dbo.Un_ConventionOper co
								ON c.ConventionID = co.ConventionID
							INNER JOIN dbo.Un_Oper o
								ON co.OperID = o.OperID									
						WHERE
							c.ConventionID = ISNULL(@iID_Convention, c.ConventionID)
							AND
							dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, c.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour
							AND
							o.OperDate < @dtPremierJourDuMoisATraiter
							AND
							co.ConventionOperTypeID = @vcConventionOperTypeRendement_PCEE_TIN	
						GROUP BY
							c.ConventionID
						HAVING
							SUM(co.ConventionOperAmount) <> 0 -- > 0 FT 2011-03-17
						
						--  ****** FIN DU TRAITEMENT POUR LES TRANSACTIONS EN DATE DU PREMIER JOUR DU MOIS À TRAITER ********

						-- SUPPRESSION DES TRANSACTIONS DANS UN_CONVENTION_OPER
						DELETE cop
						FROM 
							dbo.Un_ConventionOper cop
							INNER JOIN dbo.Un_Oper o 
								ON o.OperID = cop.OperID 
						WHERE 
								cop.ConventionOperTypeID = @vcConventionOperTypeRendement_PCEE_TIN
								AND
								cop.ConventionId = ISNULL(@iID_Convention, cop.ConventionID)
								AND
								dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, cop.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour
								AND
								cop.OperID IN (	SELECT ISNULL(tx.iID_Operation,-1) 
												FROM 
													dbo.tblOper_TauxRendement tx
													INNER JOIN dbo.tblOPER_Rendements r
														ON tx.iID_Rendement = r.iID_Rendement
													INNER JOIN dbo.tblOPER_TypesRendement tr
														ON tr.tiID_Type_Rendement = r.tiID_Type_Rendement
												WHERE 
													ISNULL(tx.dtDate_oPERATION, '1900-01-01') BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter
													AND
													tr.vcCode_Rendement = @vcCode_Rendement)
						
						--  ****** DÉBUT DU TRAITEMENT POUR LE MOIS À TRAITER *******	
						INSERT INTO @tblTransactionConvention
						(
							iID_Convention			
							,iJourOperation			
							,mMontantIST		
						)
						SELECT						-- IST
							c.ConventionID
							,DAY(o.OperDate)
							,SUM(co.ConventionOperAmount)
						FROM
							dbo.Un_Convention c
							INNER JOIN dbo.Un_ConventionOper co
								ON c.ConventionID = co.ConventionID
							INNER JOIN dbo.Un_Oper o
								ON co.OperID = o.OperID		
						WHERE
							c.ConventionID = ISNULL(@iID_Convention, c.ConventionID)
							AND
							dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, c.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour				
							AND 
							o.OperDate BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter
							AND
							co.ConventionOperTypeID = @vcConventionOperTypeRendement_PCEE_TIN	
						GROUP BY
							c.ConventionID
							,o.OperDate
						--  ****** FIN DU TRAITEMENT POUR LE MOIS À TRAITER *******

						-- Insertion des rendements générés pour le type ist
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						)
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeRendement_PCEE_TIN
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantIST,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention
						HAVING
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantIST,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantIST,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)
																					

						IF @bActiveDebug = 1
							BEGIN
								IF (SELECT COUNT(*) FROM @tblTransactionConvention) > 0
									BEGIN
										SELECT '1.3.2.3.4 MOD : IST', tc.* 
										FROM @tblTransactionConvention tc
									END
								ELSE
									BEGIN
										SELECT '1.3.2.3.4 MOD : IST'
									END			
							END

						-- SUPPRESSION DU CONTENU DE LA TABLE TEMPO
						DELETE FROM @tblTransactionConvention
				END
		END
---------------------------------------------------------------------------------------------------------------------------------
					-- FIN DU CALCUL DU RENDEMENT POUR LES SUBVENTIONS FÉDÉRALES DES CONVENTIONS COLLECTIVES ET INDIVIDUELLES
					-- ET SUR LES REVENUS ACCUMULÉS SUR SUBVENTIONS PROVENANT D'UN TRANSFERT IN (INS, IS+, IBC, IST)
---------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------------------------
-- 1.3.2.3.5		-- DÉBUT DU CALCUL DU RENDEMENT SUR LES SUBVENTIONS PROVINCIALES DES CONVENTIONS COLLECTIVES ET INDIVIDUELLES
					-- (TYPES D'OPÉRATIONS SUR CONVENTIONS IMPLIQUÉS : CBQ, MMQ, IQI)
---------------------------------------------------------------------------------------------------------------------------------
	IF @cEtat = 'S' -- nouveau rendement
		BEGIN
					--Valide si c'est le bon code de rendement pour ce traitement
					IF @vcCode_Rendement = 'TSP'
					BEGIN					
						--  ****** DÉBUT DU TRAITEMENT POUR LES TRANSACTIONS ANTÉRIEURES AU PREMIER JOUR DU MOIS À TRAITER ********				
						-- 1. Calculer les soldes des rendements des subventions provinciales en date du premier jour du mois à traiter
						--	  "Date d'opération plus petite que la date du premier jour du mois à traiter"
						--
						-- N.B.
						-- Pour les crédit de base du Québec, calculer la somme du champ "ConventionOperAmount" de la table "Un_ConventionOper"
						-- lorsque le type d'opération sur convention est CBQ
						--
						-- Pour le monde de majoration du Québec, calculer la somme du champ "ConventionOperAmount" de la table "Un_ConventionOper"
						-- lorsque le type d'opération sur convention est MMQ
						INSERT INTO @tblTransactionConvention	
						(
							iID_Convention			
							,iJourOperation			
							,mMontantCBQ
							,mMontantMMQ
						)
						SELECT
							c.ConventionID
							,0

							-- FT 2011-03-17
							--,CASE	WHEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_CBQ THEN co.ConventionOperAmount ELSE 0 END) > 0 THEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_CBQ THEN co.ConventionOperAmount ELSE 0 END)
							--		ELSE 0
							-- END
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_CBQ THEN co.ConventionOperAmount ELSE 0 END)

							--,CASE	WHEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_MMQ THEN co.ConventionOperAmount ELSE 0 END) > 0 THEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_MMQ THEN co.ConventionOperAmount ELSE 0 END)
							--		ELSE 0
							-- END
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_MMQ THEN co.ConventionOperAmount ELSE 0 END)
						FROM
							dbo.Un_Convention c
							INNER JOIN	dbo.Un_ConventionConventionState ccs
								ON c.ConventionID = ccs.ConventionID
							INNER JOIN	dbo.Un_ConventionState cs
								ON cs.ConventionStateID = ccs.ConventionStateID
							INNER JOIN dbo.Un_ConventionOper co
								ON c.ConventionID = co.ConventionID
							INNER JOIN dbo.Un_Oper o
								ON co.OperID = o.OperID		
							INNER JOIN @tConventionState tmp
								ON ccs.ConventionID = tmp.ConventionID AND	ccs.StartDate = tmp.MostRecentDate
						WHERE
							c.ConventionID = ISNULL(@iID_Convention, c.ConventionID)
							AND
							cs.ConventionStateID IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire
							AND
							o.OperDate < @dtPremierJourDuMoisATraiter
							AND
							(
								co.ConventionOperTypeID = @vcConventionOperTypeRendement_CBQ	
								OR
								co.ConventionOperTypeID = @vcConventionOperTypeRendement_MMQ
							)
						GROUP BY
							c.ConventionID
						--  ****** FIN DU TRAITEMENT POUR LES TRANSACTIONS EN DATE DU PREMIER JOUR DU MOIS À TRAITER ********

						--  ****** DÉBUT DU TRAITEMENT POUR LE MOIS À TRAITER *******	
						-- 1. Obtenir les nouvelles opérations des subventions provinciales pour le mois à traiter
						--	  "Date d'opération comprise entre le premier jour et le dernier jour du mois à traiter"
						--
						-- N.B.
						-- Même traitement CBQ, MMQ que pour les transactions en date du premier jour du mois à traiter
						INSERT INTO @tblTransactionConvention	
						(
							iID_Convention			
							,iJourOperation			
							,mMontantCBQ
							,mMontantMMQ							
						)
						SELECT
							c.ConventionID
							,DAY(o.OperDate)
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_CBQ THEN co.ConventionOperAmount ELSE 0 END)
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_MMQ THEN co.ConventionOperAmount ELSE 0 END)
						FROM
							dbo.Un_Convention c
							INNER JOIN	dbo.Un_ConventionConventionState ccs
								ON c.ConventionID = ccs.ConventionID
							INNER JOIN	dbo.Un_ConventionState cs
								ON cs.ConventionStateID = ccs.ConventionStateID
							INNER JOIN dbo.Un_ConventionOper co
								ON c.ConventionID = co.ConventionID
							INNER JOIN dbo.Un_Oper o
								ON co.OperID = o.OperID		
							INNER JOIN @tConventionState tmp
								ON ccs.ConventionID = tmp.ConventionID AND	ccs.StartDate = tmp.MostRecentDate
						WHERE
							c.ConventionID = ISNULL(@iID_Convention, c.ConventionID)
							AND
							cs.ConventionStateID IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire
							AND
							o.OperDate BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter 
							AND
							(
								co.ConventionOperTypeID = @vcConventionOperTypeRendement_CBQ	
								OR
								co.ConventionOperTypeID = @vcConventionOperTypeRendement_MMQ
							)
						GROUP BY
							c.ConventionID
							,o.OperDate
						--  ****** FIN DU TRAITEMENT POUR LE MOIS À TRAITER *******
							
						-- CALCUL DU MONTANT ET INSERTION DES TRANSACTIONS DANS LA TABLE DES OPÉRATIONS SUR CONVENTIONS
						
						-- Insertion des CBQ dans le type d'opération sur convention ICQ
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						) 
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeRendement_ICQ
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantCBQ,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention
						HAVING
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantCBQ,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantCBQ,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)
																					
																						
						-- Insertion des MMQ dans le type d'opération sur convention IMQ
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						) 
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeRendement_IMQ
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantMMQ,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention
						HAVING
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantMMQ,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantMMQ,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)
																																				
						IF @bActiveDebug = 1
							BEGIN
								IF (SELECT COUNT(*) FROM @tblTransactionConvention) > 0
									BEGIN
										SELECT '1.3.2.3.5 NEW : CBQ, MMQ', tc.* 
										FROM @tblTransactionConvention tc
									END
								ELSE
									BEGIN
										SELECT '1.3.2.3.5 NEW : CBQ, MMQ'
									END			
							END
																						
						-- SUPPRESSION DU CONTENU DE LA TABLE TEMPO
						DELETE FROM @tblTransactionConvention
					END
		END
	ELSE
		BEGIN
			IF @vcCode_Rendement = 'TSP'
				BEGIN
					--  ****** DÉBUT DU TRAITEMENT POUR LES TRANSACTIONS ANTÉRIEURES AU PREMIER JOUR DU MOIS À TRAITER ********				
						INSERT INTO @tblTransactionConvention	
						(
							iID_Convention			
							,iJourOperation			
							,mMontantCBQ
							,mMontantMMQ
						)
						SELECT
							c.ConventionID
							,0

							-- FT 2011-03-17
							--,CASE	WHEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_CBQ THEN co.ConventionOperAmount ELSE 0 END) > 0 THEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_CBQ THEN co.ConventionOperAmount ELSE 0 END)
							--		ELSE 0
							-- END
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_CBQ THEN co.ConventionOperAmount ELSE 0 END)
							
							--,CASE	WHEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_MMQ THEN co.ConventionOperAmount ELSE 0 END) > 0 THEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_MMQ THEN co.ConventionOperAmount ELSE 0 END)
							--		ELSE 0
							-- END
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_MMQ THEN co.ConventionOperAmount ELSE 0 END)
						FROM
							dbo.Un_Convention c
							INNER JOIN dbo.Un_ConventionOper co
								ON c.ConventionID = co.ConventionID
							INNER JOIN dbo.Un_Oper o
								ON co.OperID = o.OperID		
						WHERE
							c.ConventionID = ISNULL(@iID_Convention, c.ConventionID)
							AND
							dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, c.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour
							AND
							o.OperDate < @dtPremierJourDuMoisATraiter
							AND
							(
								co.ConventionOperTypeID = @vcConventionOperTypeRendement_CBQ	
								OR
								co.ConventionOperTypeID = @vcConventionOperTypeRendement_MMQ
							)
						GROUP BY
							c.ConventionID
						--  ****** FIN DU TRAITEMENT POUR LES TRANSACTIONS EN DATE DU PREMIER JOUR DU MOIS À TRAITER ********

						-- SUPPRESSION DES TRANSACTIONS DANS UN_CONVENTION_OPER
						DELETE cop
						FROM 
							dbo.Un_ConventionOper cop
							INNER JOIN dbo.Un_Oper o 
								ON o.OperID = cop.OperID 
						WHERE 
								cop.ConventionId = ISNULL(@iID_Convention, cop.ConventionID)
								AND
								dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, cop.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour
								AND
								cop.OperID IN (	SELECT ISNULL(tx.iID_Operation,-1) 
												FROM 
													dbo.tblOper_TauxRendement tx
													INNER JOIN dbo.tblOPER_Rendements r
														ON tx.iID_Rendement = r.iID_Rendement
													INNER JOIN dbo.tblOPER_TypesRendement tr
														ON tr.tiID_Type_Rendement = r.tiID_Type_Rendement
												WHERE 
													ISNULL(tx.dtDate_oPERATION, '1900-01-01') BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter
													AND
													tr.vcCode_Rendement = @vcCode_Rendement)

						--  ****** DÉBUT DU TRAITEMENT POUR LE MOIS À TRAITER *******	
						-- 1. Obtenir les nouvelles opérations des subventions provinciales pour le mois à traiter
						--	  "Date d'opération comprise entre le premier jour et le dernier jour du mois à traiter"
						--
						-- N.B.
						-- Même traitement CBQ, MMQ que pour les transactions en date du premier jour du mois à traiter
						INSERT INTO @tblTransactionConvention	
						(
							iID_Convention			
							,iJourOperation			
							,mMontantCBQ
							,mMontantMMQ							
						)
						SELECT
							c.ConventionID
							,DAY(o.OperDate)
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_CBQ THEN co.ConventionOperAmount ELSE 0 END)
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_MMQ THEN co.ConventionOperAmount ELSE 0 END)
						FROM
							dbo.Un_Convention c
							INNER JOIN dbo.Un_ConventionOper co
								ON c.ConventionID = co.ConventionID
							INNER JOIN dbo.Un_Oper o
								ON co.OperID = o.OperID		
						WHERE
							c.ConventionID = ISNULL(@iID_Convention, c.ConventionID)
							AND
							dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, c.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour				
							AND 
							o.OperDate BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter
							AND
							(
								co.ConventionOperTypeID = @vcConventionOperTypeRendement_CBQ	
								OR
								co.ConventionOperTypeID = @vcConventionOperTypeRendement_MMQ
							)
						GROUP BY
							c.ConventionID
							,o.OperDate
						--  ****** FIN DU TRAITEMENT POUR LE MOIS À TRAITER *******
							
						-- CALCUL DU MONTANT ET INSERTION DES TRANSACTIONS DANS LA TABLE DES OPÉRATIONS SUR CONVENTIONS
						
						-- Insertion des CBQ dans le type d'opération sur convention ICQ
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						) 
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeRendement_ICQ
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantCBQ,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention
						HAVING
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantCBQ,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantCBQ,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)
																					
																						
						-- Insertion des MMQ dans le type d'opération sur convention IMQ
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						) 
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeRendement_IMQ
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantMMQ,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention
						HAVING
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantMMQ,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantMMQ,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)
																																				
						IF @bActiveDebug = 1
							BEGIN
								IF (SELECT COUNT(*) FROM @tblTransactionConvention) > 0
									BEGIN
										SELECT '1.3.2.3.5 MOD : CBQ, MMQ', tc.* 
										FROM @tblTransactionConvention tc
									END
								ELSE
									BEGIN
										SELECT '1.3.2.3.5 MOD : CBQ, MMQ'
									END			
							END
																						
						-- SUPPRESSION DU CONTENU DE LA TABLE TEMPO
						DELETE FROM @tblTransactionConvention
				END
		END
---------------------------------------------------------------------------------------------------------------------------------
					-- FIN DU CALCUL DU RENDEMENT SUR LES SUBVENTIONS PROVINCIALES DES CONVENTIONS COLLECTIVES ET INDIVIDUELLES
					-- (TYPES D'OPÉRATIONS SUR CONVENTIONS IMPLIQUÉS : CBQ, MMQ, IQI
---------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------------------------
-- 1.3.2.3.6		-- DÉBUT DU CALCUL POUR LES RENDEMENTS SUR LES REVENUS ACCUMULÉS SUR SUBVENTIONS PROVINCIALES DES CONVENTIONS
					-- COLLECTIVES ET INDIVIDUELLES (MIM, ICQ, IMQ)
					-- ET
					-- POUR LES RENDEMENTS  SUR LES REVENUS ACCUMULÉS SUR SUBVENTIONS PROVINCIALES PROVENANT D'UN TRANSFERT IN
					-- DES CONVENTIONS COLLECTIVES ET INDIVIDUELLES (III)
---------------------------------------------------------------------------------------------------------------------------------
	IF @cEtat = 'S' -- nouveau rendement
		BEGIN
					--Valide si c'est le bon code de rendement pour ce traitement
					IF @vcCode_Rendement = 'RSP'
					BEGIN
						--	RENDEMENTS SUR MIM, ICQ, IMQ
						--  ****** DÉBUT DU TRAITEMENT POUR LES TRANSACTIONS ANTÉRIEURES AU PREMIER JOUR DU MOIS À TRAITER ********				
						-- 1. Calculer les soldes des rendements sur les subventions provinciales en date du premier jour du mois
						--	  à traiter
						-- N.B.
						--	Pour le montant d'intérêts de RQ, calculer la somme du champ "ConventionOperAmount" de la table "Un_ConventionOper"
						--  pour le type d'opération MIM
						--
						--	Pour le rendement sur le crédit de base du Québec, calculer la somme du champ "ConventionOperAmount" de la table "Un_ConventionOper"
						--	pour le type d'opération ICQ
						--
						--	Pour le rendement sur le montant de majoration du Québec, calculer la somme du champ "ConventionOperAmount" de la table "Un_ConventionOper"
						--	pour le type d'opération IMQ
						--
						-- Pour les montants regroupés de IQEE (TIN), calculer la somme du champ "ConventionOperAmount" de la table "Un_ConventionOper"
						-- lorsque le type d'opération sur convention est IQI
						--
						INSERT INTO @tblTransactionConvention	
						(
							iID_Convention			
							,iJourOperation			
							,mMontantMIM
							,mMontantICQ
							,mMontantIMQ
							,mMontantIIQ --mMontantIQI --> Modification du code
						)
						SELECT
							c.ConventionID
							,0
							
							-- FT 2011-03-17
							--,CASE	WHEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_MIM THEN co.ConventionOperAmount ELSE 0 END) > 0 THEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_MIM THEN co.ConventionOperAmount ELSE 0 END)
							--		ELSE 0
							-- END
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_MIM THEN co.ConventionOperAmount ELSE 0 END)
							--,CASE	WHEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_ICQ THEN co.ConventionOperAmount ELSE 0 END) > 0 THEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_ICQ THEN co.ConventionOperAmount ELSE 0 END)
							--		ELSE 0
							-- END
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_ICQ THEN co.ConventionOperAmount ELSE 0 END)
							--,CASE	WHEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_IMQ THEN co.ConventionOperAmount ELSE 0 END) > 0 THEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_IMQ THEN co.ConventionOperAmount ELSE 0 END)
							--		ELSE 0
							-- END
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_IMQ THEN co.ConventionOperAmount ELSE 0 END)
							--,CASE	WHEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_IIQ THEN co.ConventionOperAmount ELSE 0 END) > 0 THEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_IIQ THEN co.ConventionOperAmount ELSE 0 END)
							--		ELSE 0
							-- END
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_IIQ THEN co.ConventionOperAmount ELSE 0 END)
						FROM
							dbo.Un_Convention c
							INNER JOIN	dbo.Un_ConventionConventionState ccs
								ON c.ConventionID = ccs.ConventionID
							INNER JOIN	dbo.Un_ConventionState cs
								ON cs.ConventionStateID = ccs.ConventionStateID
							INNER JOIN dbo.Un_ConventionOper co
								ON c.ConventionID = co.ConventionID
							INNER JOIN dbo.Un_Oper o
								ON co.OperID = o.OperID		
							INNER JOIN @tConventionState tmp
								ON ccs.ConventionID = tmp.ConventionID AND	ccs.StartDate = tmp.MostRecentDate
						WHERE
							c.ConventionID = ISNULL(@iID_Convention, c.ConventionID)
							AND
							cs.ConventionStateID IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire
							AND
							o.OperDate < @dtPremierJourDuMoisATraiter
							AND
							(
								co.ConventionOperTypeID = @vcConventionOperTypeRendement_MIM	
								OR
								co.ConventionOperTypeID = @vcConventionOperTypeRendement_ICQ
								OR
								co.ConventionOperTypeID = @vcConventionOperTypeRendement_IMQ
								OR
								co.ConventionOperTypeID = @vcConventionOperTypeRendement_IIQ --@vcConventionOperTypeRendement_IQI  Modification du code
							)
						GROUP BY
							c.ConventionID	
						
						--  ****** FIN DU TRAITEMENT POUR LES TRANSACTIONS EN DATE DU PREMIER JOUR DU MOIS À TRAITER ********

						--  ****** DÉBUT DU TRAITEMENT POUR LE MOIS À TRAITER *******	
						--  Mêmes calculs que précédemment en précisant le date d'opération
						INSERT INTO @tblTransactionConvention	
						(
							iID_Convention			
							,iJourOperation			
							,mMontantMIM
							,mMontantICQ
							,mMontantIMQ
							,mMontantIIQ  --mMontantIQI --> Modification du code
						)
						SELECT
							c.ConventionID
							,DAY(o.OperDate)
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_MIM THEN co.ConventionOperAmount ELSE 0 END)
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_ICQ THEN co.ConventionOperAmount ELSE 0 END)
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_IMQ THEN co.ConventionOperAmount ELSE 0 END)
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_IIQ THEN co.ConventionOperAmount ELSE 0 END)
						FROM
							dbo.Un_Convention c
							INNER JOIN	dbo.Un_ConventionConventionState ccs
								ON c.ConventionID = ccs.ConventionID
							INNER JOIN	dbo.Un_ConventionState cs
								ON cs.ConventionStateID = ccs.ConventionStateID
							INNER JOIN dbo.Un_ConventionOper co
								ON c.ConventionID = co.ConventionID
							INNER JOIN dbo.Un_Oper o
								ON co.OperID = o.OperID		
							INNER JOIN @tConventionState tmp
								ON ccs.ConventionID = tmp.ConventionID AND	ccs.StartDate = tmp.MostRecentDate
						WHERE
							c.ConventionID = ISNULL(@iID_Convention, c.ConventionID)
							AND
							cs.ConventionStateID IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire
							AND
							o.OperDate BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter 
							AND
							(
								co.ConventionOperTypeID = @vcConventionOperTypeRendement_MIM	
								OR
								co.ConventionOperTypeID = @vcConventionOperTypeRendement_ICQ
								OR
								co.ConventionOperTypeID = @vcConventionOperTypeRendement_IMQ
								OR
								co.ConventionOperTypeID = @vcConventionOperTypeRendement_IIQ --@vcConventionOperTypeRendement_IQI  Modification du code
							)
						GROUP BY
							c.ConventionID
							,o.OperDate
						--  ****** FIN DU TRAITEMENT POUR LE MOIS À TRAITER *******
						-- CALCUL DU MONTANT ET INSERTION DES TRANSACTIONS DANS LA TABLE DES OPÉRATIONS SUR CONVENTIONS
						
						-- Insertion des MIM dans le type d'opération sur convention IIQ
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						) 
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeRendement_IIQ
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantMIM,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention
						HAVING
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantMIM,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantMIM,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)
																					
						
						-- Insertion des ICQ dans le type d'opération sur convention ICQ
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						) 
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeRendement_ICQ
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantICQ,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention
						HAVING
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantICQ,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantICQ,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)
																					
						
						-- Insertion des IMQ dans le type d'opération sur convention IMQ
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						) 
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeRendement_IMQ
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantIMQ,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention
						HAVING
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantIMQ,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantIMQ,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)
																					

						-- Insertion des IIQ dans le type d'opération sur convention IIQ
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						) 
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeRendement_IIQ -- @vcConventionOperTypeRendement_IQI --> Modification du code
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantIIQ,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention
						HAVING
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantIIQ,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantIIQ,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)
						

						IF @bActiveDebug = 1
							BEGIN
								IF (SELECT COUNT(*) FROM @tblTransactionConvention) > 0
									BEGIN
										SELECT '1.3.2.3.6 NEW : MIM, ICQ, IMQ, IQI', tc.* 
										FROM @tblTransactionConvention tc
									END
								ELSE
									BEGIN
										SELECT '1.3.2.3.6 NEW : MIM, ICQ, IMQ, IQI'
									END			
							END

						-- SUPPRESSION DU CONTENU DE LA TABLE TEMPO
						DELETE FROM @tblTransactionConvention

		
					--	RENDEMENTS SUR III
						--  ****** DÉBUT DU TRAITEMENT POUR LES TRANSACTIONS ANTÉRIEURES AU PREMIER JOUR DU MOIS À TRAITER ********				
						--	1. Calculer les soldes de rendements sur les subventions provinciales provenant d'un transfert IN en du
						--	   premier jour du mois à traiter
						--	
						--	N.B.
						--		Calculer la somme du champ "ConventionOperAmount" de la table des opérations sur conventions "Un_ConventionOper"
						--		pour le type d'opération III
						--
						INSERT INTO @tblTransactionConvention	
						(
							iID_Convention			
							,iJourOperation			
							,mMontantIII
							,mMontantIQI
						)
						SELECT
							c.ConventionID
							,0
							
							-- FT 2011-03-17
							--,CASE	WHEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_III THEN co.ConventionOperAmount ELSE 0 END) > 0 THEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_III THEN co.ConventionOperAmount ELSE 0 END)
							--		ELSE 0
							-- END
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_III THEN co.ConventionOperAmount ELSE 0 END)
							--,CASE	WHEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_IQI THEN co.ConventionOperAmount ELSE 0 END) > 0 THEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_IQI THEN co.ConventionOperAmount ELSE 0 END)
							--		ELSE 0
							-- END
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_IQI THEN co.ConventionOperAmount ELSE 0 END)
						FROM
							dbo.Un_Convention c
							INNER JOIN	dbo.Un_ConventionConventionState ccs
								ON c.ConventionID = ccs.ConventionID
							INNER JOIN	dbo.Un_ConventionState cs
								ON cs.ConventionStateID = ccs.ConventionStateID
							INNER JOIN dbo.Un_ConventionOper co
								ON c.ConventionID = co.ConventionID
							INNER JOIN dbo.Un_Oper o
								ON co.OperID = o.OperID		
							INNER JOIN @tConventionState tmp
								ON ccs.ConventionID = tmp.ConventionID AND	ccs.StartDate = tmp.MostRecentDate
						WHERE
							c.ConventionID = ISNULL(@iID_Convention, c.ConventionID)
							AND
							cs.ConventionStateID IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire
							AND
							o.OperDate < @dtPremierJourDuMoisATraiter
							AND
							(
							co.ConventionOperTypeID = @vcConventionOperTypeRendement_III	
							OR
							co.ConventionOperTypeID = @vcConventionOperTypeRendement_IQI
							)	
						GROUP BY
							c.ConventionID	

						--  ****** FIN DU TRAITEMENT POUR LES TRANSACTIONS EN DATE DU PREMIER JOUR DU MOIS À TRAITER ********

						--  ****** DÉBUT DU TRAITEMENT POUR LE MOIS À TRAITER *******	
						--	1. Obtenir les nouvelles opérations de rendement sur les subventions provinciales provenant d'un transfert IN
						--	   pour le mois à traiter
						--
						--	N.B.
						--		Pour le rendement sur les montants regroupés de IQEE (TIN), calculer la somme du champ "ConventionOperAmount"
						--		de la table "Un_ConventionOper" pour le type III
						INSERT INTO @tblTransactionConvention	
						(
							iID_Convention			
							,iJourOperation			
							,mMontantIII
							,mMontantIQI
						)
						SELECT
							c.ConventionID
							,DAY(o.OperDate)
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_III THEN co.ConventionOperAmount ELSE 0 END)
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_IQI THEN co.ConventionOperAmount ELSE 0 END)
						FROM
							dbo.Un_Convention c
							INNER JOIN	dbo.Un_ConventionConventionState ccs
								ON c.ConventionID = ccs.ConventionID
							INNER JOIN	dbo.Un_ConventionState cs
								ON cs.ConventionStateID = ccs.ConventionStateID
							INNER JOIN dbo.Un_ConventionOper co
								ON c.ConventionID = co.ConventionID
							INNER JOIN dbo.Un_Oper o
								ON co.OperID = o.OperID		
							INNER JOIN @tConventionState tmp
								ON ccs.ConventionID = tmp.ConventionID AND	ccs.StartDate = tmp.MostRecentDate
						WHERE
							c.ConventionID = ISNULL(@iID_Convention, c.ConventionID)
							AND
							cs.ConventionStateID IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire
							AND
							o.OperDate BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter 
							AND
							(
							co.ConventionOperTypeID = @vcConventionOperTypeRendement_III	
							OR
							co.ConventionOperTypeID = @vcConventionOperTypeRendement_IQI
							)
						GROUP BY
							c.ConventionID
							,o.OperDate					
						
						--  ****** FIN DU TRAITEMENT POUR LE MOIS À TRAITER *******
							
						-- CALCUL DU MONTANT ET INSERTION DES TRANSACTIONS DANS LA TABLE DES OPÉRATIONS SUR CONVENTIONS
						-- 2009-09-11 insertion des montants III et IQI sommés
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						)
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeRendement_III
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantIII,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
							+
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantIQI,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))	
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention
						HAVING
							(SUM(dbo.fnOPER_CalculerRendement(tc.mMontantIII,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
							+
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantIQI,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantIII,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)
																					
						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantIQI,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)
						
						IF @bActiveDebug = 1
							BEGIN
								IF (SELECT COUNT(*) FROM @tblTransactionConvention) > 0
									BEGIN
										SELECT '1.3.2.3.6 NEW : III, IQI', tc.* 
										FROM @tblTransactionConvention tc
									END
								ELSE
									BEGIN
										SELECT '1.3.2.3.6 NEW : III, IQI'
									END			
							END

						-- SUPPRESSION DU CONTENU DE LA TABLE TEMPO
						DELETE FROM @tblTransactionConvention
					END
		END
	ELSE	-- TAUX MODIFIÉ @CETAT = 'C'
		BEGIN
			IF @vcCode_Rendement = 'RSP'
				BEGIN
					--	RENDEMENTS SUR MIM, ICQ, IMQ
						--  ****** DÉBUT DU TRAITEMENT POUR LES TRANSACTIONS ANTÉRIEURES AU PREMIER JOUR DU MOIS À TRAITER ********				
						INSERT INTO @tblTransactionConvention	
						(
							iID_Convention			
							,iJourOperation			
							,mMontantMIM
							,mMontantICQ
							,mMontantIMQ
							,mMontantIIQ
						)
						SELECT
							c.ConventionID
							,0
							
							-- FT 2011-03-17
							--,CASE	WHEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_MIM THEN co.ConventionOperAmount ELSE 0 END) > 0 THEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_MIM THEN co.ConventionOperAmount ELSE 0 END)
							--		ELSE 0
							-- END
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_MIM THEN co.ConventionOperAmount ELSE 0 END)
							--,CASE	WHEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_ICQ THEN co.ConventionOperAmount ELSE 0 END) > 0 THEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_ICQ THEN co.ConventionOperAmount ELSE 0 END)
							--		ELSE 0
							-- END
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_ICQ THEN co.ConventionOperAmount ELSE 0 END)
							--,CASE	WHEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_IMQ THEN co.ConventionOperAmount ELSE 0 END) > 0 THEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_IMQ THEN co.ConventionOperAmount ELSE 0 END)
							--		ELSE 0
							-- END
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_IMQ THEN co.ConventionOperAmount ELSE 0 END)
							--,CASE	WHEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_IIQ THEN co.ConventionOperAmount ELSE 0 END) > 0 THEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_IIQ THEN co.ConventionOperAmount ELSE 0 END)
							--		ELSE 0
							-- END
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_IIQ THEN co.ConventionOperAmount ELSE 0 END)
						FROM
							dbo.Un_Convention c
							INNER JOIN dbo.Un_ConventionOper co
								ON c.ConventionID = co.ConventionID
							INNER JOIN dbo.Un_Oper o
								ON co.OperID = o.OperID		
						WHERE
							c.ConventionID = ISNULL(@iID_Convention, c.ConventionID)
							AND
							dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, c.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour
							AND
							o.OperDate < @dtPremierJourDuMoisATraiter
							AND
							(
								co.ConventionOperTypeID = @vcConventionOperTypeRendement_MIM	
								OR
								co.ConventionOperTypeID = @vcConventionOperTypeRendement_ICQ
								OR
								co.ConventionOperTypeID = @vcConventionOperTypeRendement_IMQ
								OR
								co.ConventionOperTypeID = @vcConventionOperTypeRendement_IIQ
							)
						GROUP BY
							c.ConventionID	
						
						--  ****** FIN DU TRAITEMENT POUR LES TRANSACTIONS EN DATE DU PREMIER JOUR DU MOIS À TRAITER ********

						-- SUPPRESSION DES TRANSACTIONS DANS UN_CONVENTION_OPER
						DELETE cop
						FROM 
							dbo.Un_ConventionOper cop
							INNER JOIN dbo.Un_Oper o 
								ON o.OperID = cop.OperID 
						WHERE 
								cop.ConventionId = ISNULL(@iID_Convention, cop.ConventionID)
								AND
								dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, cop.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour
								AND
								cop.OperID IN (	SELECT ISNULL(tx.iID_Operation,-1) 
												FROM 
													dbo.tblOper_TauxRendement tx
													INNER JOIN dbo.tblOPER_Rendements r
														ON tx.iID_Rendement = r.iID_Rendement
													INNER JOIN dbo.tblOPER_TypesRendement tr
														ON tr.tiID_Type_Rendement = r.tiID_Type_Rendement
												WHERE 
													ISNULL(tx.dtDate_oPERATION, '1900-01-01') BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter
													AND
													tr.vcCode_Rendement = @vcCode_Rendement)
							
						--  ****** DÉBUT DU TRAITEMENT POUR LE MOIS À TRAITER *******	
						INSERT INTO @tblTransactionConvention	
						(
							iID_Convention			
							,iJourOperation			
							,mMontantMIM
							,mMontantICQ
							,mMontantIMQ
							,mMontantIIQ
						)
						SELECT
							c.ConventionID
							,DAY(o.OperDate)
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_MIM THEN co.ConventionOperAmount ELSE 0 END)
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_ICQ THEN co.ConventionOperAmount ELSE 0 END)
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_IMQ THEN co.ConventionOperAmount ELSE 0 END)
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_IIQ THEN co.ConventionOperAmount ELSE 0 END)
						FROM
							dbo.Un_Convention c							
							INNER JOIN dbo.Un_ConventionOper co
								ON c.ConventionID = co.ConventionID
							INNER JOIN dbo.Un_Oper o
								ON co.OperID = o.OperID		
						WHERE
							c.ConventionID = ISNULL(@iID_Convention, c.ConventionID)
							AND
							dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, c.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour				
							AND 
							o.OperDate BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter
							AND
							(
								co.ConventionOperTypeID = @vcConventionOperTypeRendement_MIM	
								OR
								co.ConventionOperTypeID = @vcConventionOperTypeRendement_ICQ
								OR
								co.ConventionOperTypeID = @vcConventionOperTypeRendement_IMQ
								OR
								co.ConventionOperTypeID = @vcConventionOperTypeRendement_IIQ
							)
						GROUP BY
							c.ConventionID
							,o.OperDate
						--  ****** FIN DU TRAITEMENT POUR LE MOIS À TRAITER *******
						-- CALCUL DU MONTANT ET INSERTION DES TRANSACTIONS DANS LA TABLE DES OPÉRATIONS SUR CONVENTIONS
						
						-- Insertion des MIM dans le type d'opération sur convention IIQ
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						) 
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeRendement_IIQ
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantMIM,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention
						HAVING
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantMIM,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantMIM,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)
																					
						-- Insertion des ICQ dans le type d'opération sur convention ICQ
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						) 
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeRendement_ICQ
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantICQ,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention
						HAVING
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantICQ,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantICQ,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)
																					
						-- Insertion des IMQ dans le type d'opération sur convention IMQ
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						) 
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeRendement_IMQ
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantIMQ,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention
						HAVING
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantIMQ,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantIMQ,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)
																					
						-- Insertion des IIQ dans le type d'opération sur convention IIQ
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						) 
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeRendement_IIQ
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantIIQ,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention
						HAVING
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantIIQ,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantIIQ,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)
						
						IF @bActiveDebug = 1
							BEGIN
								IF (SELECT COUNT(*) FROM @tblTransactionConvention) > 0
									BEGIN
										SELECT '1.3.2.3.6 MOD : MIM, ICQ, IMQ, IQI', tc.* 
										FROM @tblTransactionConvention tc
									END
								ELSE
									BEGIN
										SELECT '1.3.2.3.6 MOD : MIM, ICQ, IMQ, IQI'
									END			
							END

						-- SUPPRESSION DU CONTENU DE LA TABLE TEMPO
						DELETE FROM @tblTransactionConvention

		
				--	RENDEMENTS SUR III
						--  ****** DÉBUT DU TRAITEMENT POUR LES TRANSACTIONS ANTÉRIEURES AU PREMIER JOUR DU MOIS À TRAITER ********				
						INSERT INTO @tblTransactionConvention	
						(
							iID_Convention			
							,iJourOperation			
							,mMontantIII
							,mMontantIQI
						)
						SELECT
							c.ConventionID
							,0
							
							-- FT 2011-03-17
							--,CASE	WHEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_III THEN co.ConventionOperAmount ELSE 0 END) > 0 THEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_III THEN co.ConventionOperAmount ELSE 0 END)
							--		ELSE 0
							-- END
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_III THEN co.ConventionOperAmount ELSE 0 END)
							--,CASE	WHEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_IQI THEN co.ConventionOperAmount ELSE 0 END) > 0 THEN SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_IQI THEN co.ConventionOperAmount ELSE 0 END)
							--		ELSE 0
							-- END
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_IQI THEN co.ConventionOperAmount ELSE 0 END)
						FROM
							dbo.Un_Convention c
							INNER JOIN dbo.Un_ConventionOper co
								ON c.ConventionID = co.ConventionID
							INNER JOIN dbo.Un_Oper o
								ON co.OperID = o.OperID		
						WHERE
							c.ConventionID = ISNULL(@iID_Convention, c.ConventionID)
							AND
							dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, c.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour
							AND
							o.OperDate < @dtPremierJourDuMoisATraiter
							AND
							(
							co.ConventionOperTypeID = @vcConventionOperTypeRendement_III	
							OR
							co.ConventionOperTypeID = @vcConventionOperTypeRendement_IQI
							)	
						GROUP BY
							c.ConventionID	

						--  ****** FIN DU TRAITEMENT POUR LES TRANSACTIONS EN DATE DU PREMIER JOUR DU MOIS À TRAITER ********
						-- SUPPRESSION DES TRANSACTIONS DANS UN_CONVENTION_OPER
						DELETE cop
						FROM dbo.Un_ConventionOper cop
							INNER JOIN dbo.Un_Oper o 
								ON o.OperID = cop.OperID 
						WHERE 
								cop.ConventionId = ISNULL(@iID_Convention, cop.ConventionID)
								AND
								dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, cop.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour
								AND
								cop.OperID IN (	SELECT 
													ISNULL(tx.iID_Operation,-1) 
												FROM 
													dbo.tblOper_TauxRendement tx
													INNER JOIN dbo.tblOPER_Rendements r
														ON tx.iID_Rendement = r.iID_Rendement
													INNER JOIN dbo.tblOPER_TypesRendement tr
														ON tr.tiID_Type_Rendement = r.tiID_Type_Rendement
												WHERE 
													ISNULL(tx.dtDate_oPERATION, '1900-01-01') BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter
													AND
													tr.vcCode_Rendement = @vcCode_Rendement)	
									
						--  ****** DÉBUT DU TRAITEMENT POUR LE MOIS À TRAITER *******	
						--	1. Obtenir les nouvelles opérations de rendement sur les subventions provinciales provenant d'un transfert IN
						--	   pour le mois à traiter
						--
						--	N.B.
						--		Pour le rendement sur les montants regroupés de IQEE (TIN), calculer la somme du champ "ConventionOperAmount"
						--		de la table "Un_ConventionOper" pour le type III
						INSERT INTO @tblTransactionConvention	
						(
							iID_Convention			
							,iJourOperation			
							,mMontantIII
							,mMontantIQI
						)
						SELECT
							c.ConventionID
							,DAY(o.OperDate)
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_III THEN co.ConventionOperAmount ELSE 0 END)
							,SUM(CASE WHEN co.ConventionOperTypeID = @vcConventionOperTypeRendement_IQI THEN co.ConventionOperAmount ELSE 0 END)
						FROM
							dbo.Un_Convention c
							INNER JOIN dbo.Un_ConventionOper co
								ON c.ConventionID = co.ConventionID
							INNER JOIN dbo.Un_Oper o
								ON co.OperID = o.OperID		
						WHERE
							c.ConventionID = ISNULL(@iID_Convention, c.ConventionID)
							AND
							dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, c.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour				
							AND 
							o.OperDate BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter
							AND
							(
							co.ConventionOperTypeID = @vcConventionOperTypeRendement_III	
							OR
							co.ConventionOperTypeID = @vcConventionOperTypeRendement_IQI
							)
						GROUP BY
							c.ConventionID
							,o.OperDate					
						
						--  ****** FIN DU TRAITEMENT POUR LE MOIS À TRAITER *******
							
						-- CALCUL DU MONTANT ET INSERTION DES TRANSACTIONS DANS LA TABLE DES OPÉRATIONS SUR CONVENTIONS
						-- 2009-09-11 insertion des montants III et IQI sommés
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						)
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeRendement_III
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantIII,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
							+
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantIQI,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))	
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention
						HAVING
							(SUM(dbo.fnOPER_CalculerRendement(tc.mMontantIII,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
							+
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantIQI,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantIII,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantIQI,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)
						
						IF @bActiveDebug = 1
							BEGIN
								IF (SELECT COUNT(*) FROM @tblTransactionConvention) > 0
									BEGIN
										SELECT '1.3.2.3.6 MOD : III, IQI', tc.* 
										FROM @tblTransactionConvention tc
									END
								ELSE
									BEGIN
										SELECT '1.3.2.3.6 MOD : III, IQI'
									END			
							END

						-- SUPPRESSION DU CONTENU DE LA TABLE TEMPO
						DELETE FROM @tblTransactionConvention
				END
		END			
---------------------------------------------------------------------------------------------------------------------------------
					-- FIN DU CALCUL POUR LES RENDEMENTS SUR LES REVENUS ACCUMULÉS SUR SUBVENTIONS PROVINCIALES DES CONVENTIONS
					-- COLLECTIVES ET INDIVIDUELLES (MIM, ICQ, IMQ)
					-- ET
					-- POUR LES RENDEMENTS  SUR LES REVENUS ACCUMULÉS SUR SUBVENTIONS PROVINCIALES PROVENANT D'UN TRANSFERT IN
					-- DES CONVENTIONS COLLECTIVES ET INDIVIDUELLES (III)	
---------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------
-- 1.3.2.3.7		-- DÉBUT DU CALCUL DU  RENDEMENT SUR L'ÉPARGNE DES NOUVELLES CONVENTIONS INDIVIDUELLES QUI NE SONT PAS ISSUES D'UN RIO
------------------------------------------------------------------------------------------------------------------------------------------À
--Valide si c'est le bon code de rendement pour ce traitement
	IF @cEtat = 'S' -- nouveau rendement
		BEGIN
					IF @vcCode_Rendement = 'TEN'
					BEGIN
						--  ****** DÉBUT DU TRAITEMENT POUR LES TRANSACTIONS ANTÉRIEURES AU PREMIER JOUR DU MOIS À TRAITER ********
						--	1.	Calculer le solde de l'épargnes des nouvelles conventions individuelles en date du premier jour du 
						--		du mois à traiter "Date d'opération est plus petite que la date du premier jour du mois à traiter"
						--		et que la date de la convention "dtDateProspectus" est plus grande ou égale à "A DÉTERMINER"   
						--	N.B.
						--		Vérifier que les conventions ne proviennent pas d'un RIO 
						--		Calculer la somme du champ "Cotisation" de la table "Un_Cotisation"
						
						SET @dtDateProspectus = dbo.fnGENE_ObtenirParametre('OPER_DATE_PROSPECTUS', null, null, null, null, null, null)
						INSERT INTO @tblTransactionConvention	
						(
							iID_Convention			
							,iJourOperation			
							,mMontantRI
						)
						SELECT
							u.ConventionID
							,0
							,SUM(ct.Cotisation)
						FROM 
							dbo.Un_Unit u
							INNER JOIN dbo.Un_Convention co 
								ON co.ConventionID = u.ConventionID
							INNER JOIN	dbo.Un_ConventionConventionState ccs
								ON co.ConventionID = ccs.ConventionID
							INNER JOIN	dbo.Un_ConventionState cs
								ON cs.ConventionStateID = ccs.ConventionStateID
							INNER JOIN dbo.Un_Modal m 
								ON m.ModalID = u.ModalID
							INNER JOIN dbo.Un_Plan p 
								ON p.PlanID = m.PlanID
							INNER JOIN dbo.Un_Cotisation ct 
								ON ct.UnitID = u.UnitID
							INNER JOIN dbo.Un_Oper o 
								ON o.OperID = ct.OperID 
							INNER JOIN @tConventionState tmp
								ON ccs.ConventionID = tmp.ConventionID AND	ccs.StartDate = tmp.MostRecentDate
						WHERE 
							u.ConventionId = ISNULL(@iID_Convention, u.ConventionID)
							AND
							NOT EXISTS (
										SELECT 
											1
										FROM 
											@tRIO rio
										WHERE 
											rio.iID_Convention_Destination = u.ConventionID
										)
							AND
							p.PlanTypeID = 'IND'
							AND 
							cs.ConventionStateID IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire
							AND
							o.OperDate < @dtPremierJourDuMoisATraiter	-- modifié par JFA 2009-08-28
							AND 
							co.dtDateProspectus >= @dtDateProspectus
						GROUP BY 
							u.ConventionID
						HAVING 
							SUM(ct.Cotisation) <> 0 -- > 0 FT 2011-03-17

						--  ****** FIN DU TRAITEMENT POUR LES TRANSACTIONS EN DATE DU PREMIER JOUR DU MOIS À TRAITER ********

						--  ****** DÉBUT DU TRAITEMENT POUR LE MOIS À TRAITER *******	
						--	1. Mêmes calculs, mais pour le mois à traiter
						
						INSERT INTO @tblTransactionConvention	
						(
							iID_Convention			
							,iJourOperation			
							,mMontantRI
						)
						SELECT
							u.ConventionID
							,DAY(o.OperDate)
							,SUM(ct.Cotisation)
						FROM 
							dbo.Un_Unit u
							INNER JOIN dbo.Un_Convention co 
								ON co.ConventionID = u.ConventionID
							INNER JOIN	dbo.Un_ConventionConventionState ccs
								ON co.ConventionID = ccs.ConventionID
							INNER JOIN	dbo.Un_ConventionState cs
								ON cs.ConventionStateID = ccs.ConventionStateID
							INNER JOIN dbo.Un_Modal m 
								ON m.ModalID = u.ModalID
							INNER JOIN dbo.Un_Plan p 
								ON p.PlanID = m.PlanID
							INNER JOIN dbo.Un_Cotisation ct 
								ON ct.UnitID = u.UnitID
							INNER JOIN dbo.Un_Oper o 
								ON o.OperID = ct.OperID 
							INNER JOIN @tConventionState tmp
								ON ccs.ConventionID = tmp.ConventionID AND	ccs.StartDate = tmp.MostRecentDate
						WHERE 
							u.ConventionId = ISNULL(@iID_Convention, u.ConventionID)
							AND
							NOT EXISTS (
										SELECT 
											1
										FROM 
											@tRIO rio
										WHERE 
											rio.iID_Convention_Destination = u.ConventionID
										)
							AND
							p.PlanTypeID = 'IND'
							AND
							cs.ConventionStateID IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire
							AND 
							o.OperDate BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter 
							AND 
							co.dtDateProspectus >= @dtDateProspectus
						GROUP BY 
							u.ConventionID
							,o.OperDate
			
						--  ****** FIN DU TRAITEMENT POUR LE MOIS À TRAITER *******
							
						-- CALCUL DU MONTANT ET INSERTION DES TRANSACTIONS DANS LA TABLE DES OPÉRATIONS SUR CONVENTIONS
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						)
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeMntSouscrit
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantRI,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention
						HAVING
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantRI,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantRI,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)
																					

						IF @bActiveDebug = 1
							BEGIN
								IF (SELECT COUNT(*) FROM @tblTransactionConvention) > 0
									BEGIN
										SELECT '1.3.2.3.7 NEW : Rendement sur épargne des nouvelles conventions individuelles ne provenant pas d''un RIO', tc.* 
										FROM @tblTransactionConvention tc
									END
								ELSE
									BEGIN
										SELECT '1.3.2.3.7 NEW : Rendement sur épargne des nouvelles conventions individuelles ne provenant pas d''un RIO'
									END			
							END

						-- SUPPRESSION DU CONTENU DE LA TABLE TEMPO
						DELETE FROM @tblTransactionConvention
					END
		END
	ELSE		-- RENDEMENT MODIFIÉ -> @cEtat = 'C'
		BEGIN
			IF @vcCode_Rendement = 'TEN'
				BEGIN
					--  ****** DÉBUT DU TRAITEMENT POUR LES TRANSACTIONS ANTÉRIEURES AU PREMIER JOUR DU MOIS À TRAITER ********	
					SET @dtDateProspectus = dbo.fnGENE_ObtenirParametre('OPER_DATE_PROSPECTUS', null, null, null, null, null, null)
					INSERT INTO @tblTransactionConvention	
					(
						iID_Convention			
						,iJourOperation			
						,mMontantRI
					)
					SELECT
						u.ConventionID
						,0
						,SUM(ct.Cotisation)
					FROM 
						dbo.Un_Unit u
						INNER JOIN dbo.Un_Convention co 
							ON co.ConventionID = u.ConventionID
						INNER JOIN dbo.Un_Modal m 
							ON m.ModalID = u.ModalID
						INNER JOIN dbo.Un_Plan p 
							ON p.PlanID = m.PlanID
						INNER JOIN dbo.Un_Cotisation ct 
							ON ct.UnitID = u.UnitID
						INNER JOIN dbo.Un_Oper o 
							ON o.OperID = ct.OperID 
					WHERE 
						u.ConventionId = ISNULL(@iID_Convention, u.ConventionID)
						AND
						NOT EXISTS (
									SELECT 
										1
									FROM 
										@tRIO rio
									WHERE 
										rio.iID_Convention_Destination = u.ConventionID
									)
						AND
						p.PlanTypeID = 'IND'
						AND 
						dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, u.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour
						AND
						o.OperDate < @dtPremierJourDuMoisATraiter	-- modifié par JFA 2009-08-28
						AND 
						co.dtDateProspectus >= @dtDateProspectus
					GROUP BY 
						u.ConventionID
					HAVING 
						SUM(ct.Cotisation) <> 0 -- > 0 FT 2011-03-17
					--  ****** FIN DU TRAITEMENT POUR LES TRANSACTIONS EN DATE DU PREMIER JOUR DU MOIS À TRAITER ********

					--  SUPPRESSION DES TRANSACTIONS DONT LE STATUT EST REE OU TRA
					DELETE cop
					FROM 
						dbo.Un_ConventionOper cop
						INNER JOIN dbo.Un_Oper o 
							ON o.OperID = cop.OperID 
					WHERE 
							cop.ConventionOperTypeID = @vcConventionOperTypeMntSouscrit
							AND
							cop.ConventionId = ISNULL(@iID_Convention, cop.ConventionID)
							AND
							dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, cop.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour
							AND
							cop.OperID IN (	SELECT 
												ISNULL(tx.iID_Operation,-1) 
											FROM 
												dbo.tblOper_TauxRendement tx
												INNER JOIN dbo.tblOPER_Rendements r
													ON tx.iID_Rendement = r.iID_Rendement
												INNER JOIN dbo.tblOPER_TypesRendement tr
													ON tr.tiID_Type_Rendement = r.tiID_Type_Rendement
											WHERE 
												ISNULL(tx.dtDate_Operation, '1900-01-01') BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter
												AND
												tr.vcCode_Rendement = @vcCode_Rendement)
							
					-- POUR CHAQUE MOIS, À PARTIR DE LA DATE DU PREMIER JOUR DU MOIS À TRAITER,
					-- IL FAUT RECALCULER LES INTÉRÊTS 
					INSERT INTO @tblTransactionConvention	
					(
						iID_Convention			
						,iJourOperation			
						,mMontantRI
					)
					SELECT
						u.ConventionID
						,DAY(o.OperDate)
						,SUM(ct.Cotisation)
					FROM 
						dbo.Un_Unit u
						INNER JOIN dbo.Un_Convention co 
							ON co.ConventionID = u.ConventionID
						INNER JOIN dbo.Un_Modal m 
							ON m.ModalID = u.ModalID
						INNER JOIN dbo.Un_Plan p 
							ON p.PlanID = m.PlanID
						INNER JOIN dbo.Un_Cotisation ct 
							ON ct.UnitID = u.UnitID
						INNER JOIN dbo.Un_Oper o 
							ON o.OperID = ct.OperID 
					WHERE 
						u.ConventionId = ISNULL(@iID_Convention, u.ConventionID)
						AND
						NOT EXISTS (
									SELECT 
										1
									FROM 
										@tRIO rio
									WHERE 
										rio.iID_Convention_Destination = u.ConventionID
									)
						AND
						p.PlanTypeID = 'IND'
						AND
						dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, u.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour
						AND										-- CALCUL ENTRE LE PREMIER JOUR DU MOIS À TRAITER ET LE DERNIER JOUR DU MOIS PRÉCÉDENT LA DATE DE CALCUL (DATE D'EXÉCUTION DE LA PROCÉDURE)
						o.OperDate BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter
						AND 
						co.dtDateProspectus >= @dtDateProspectus
					GROUP BY 
						u.ConventionID
						,o.OperDate
					
					-- CALCUL DU MONTANT ET INSERTION DES TRANSACTIONS DANS LA TABLE DES OPÉRATIONS SUR CONVENTIONS
					INSERT INTO	dbo.Un_ConventionOper
					(
						OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
					)
					SELECT 
						@iID_Oper
						,tc.iID_Convention						
						,@vcConventionOperTypeMntSouscrit
						,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantRI,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
					FROM
						@tblTransactionConvention tc
					GROUP BY
						tc.iID_Convention
					HAVING
						SUM(dbo.fnOPER_CalculerRendement(tc.mMontantRI,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

					-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
					SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantRI,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																				FROM	@tblTransactionConvention tc),0)
																				
					IF @bActiveDebug = 1
						BEGIN
							IF (SELECT COUNT(*) FROM @tblTransactionConvention) > 0
								BEGIN
									SELECT '1.3.2.3.7 MOD : Rendement sur épargne des nouvelles conventions individuelles ne provenant pas d''un RIO', tc.* 
									FROM @tblTransactionConvention tc
								END
							ELSE
								BEGIN
									SELECT '1.3.2.3.7 MOD : Rendement sur épargne des nouvelles conventions individuelles ne provenant pas d''un RIO'
								END			
						END

					-- SUPPRESSION DU CONTENU DE LA TABLE TEMPO
					DELETE FROM @tblTransactionConvention
				END
		END
------------------------------------------------------------------------------------------------------------------------------------------
					-- FIN DU CALCUL DU  RENDEMENT SUR L'ÉPARGNE DES NOUVELLES CONVENTIONS INDIVIDUELLES QUI NE SONT PAS ISSUES D'UN RIO
------------------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------------------------
-- 1.3.2.3.8	-- DÉBUT DU CALCUL DU  RENDEMENT SUR LES REVENUS ACCUMULÉS SUR L'ÉPARGNE PROVENANT D'UN TRANFERT IN
				-- DES CONVENTIONS INDIVIDUELLES (ITR)
				-- ET DU RENDEMENT SUR LES REVENUS ACCUMULÉS SUR L'ÉPARGNE DES NOUVELLES CONVENTIONS QUI NE SONT PAS ISSUES D'UN RIO	
---------------------------------------------------------------------------------------------------------------------------------
--Valide si c'est le bon code de rendement pour ce traitement
	IF @cEtat = 'S' -- nouveau rendement
		BEGIN
					IF @vcCode_Rendement = 'REN'
					BEGIN
	--	RENDEMENT ITR
						--  ****** DÉBUT DU TRAITEMENT POUR LES TRANSACTIONS ANTÉRIEURES AU PREMIER JOUR DU MOIS À TRAITER ********
						-- 1. Calculer la somme du champ "ConventionOperAmount" de la table "Un_ConventionOper" dont
						--	  le type de régime est indivuel. 
						-- N.B.
						--	Additionner tous les montants générés, de la table des taux de rendement, dont la table de
						--	calcul, de la table des rendements, est antérieure à la date du premier jour du mois à traiter

						INSERT INTO @tblTransactionConvention	
						(
							iID_Convention			
							,iJourOperation			
							,mMontantITR
						)
						SELECT 
							c.ConventionID
							,0
							,SUM(co.ConventionOperAmount)
						FROM 
							dbo.Un_Convention c
							INNER JOIN dbo.Un_ConventionOper co
								ON c.ConventionID = co.ConventionID
							INNER JOIN	dbo.Un_ConventionConventionState ccs
								ON c.ConventionID = ccs.ConventionID
							INNER JOIN	dbo.Un_ConventionState cs
								ON cs.ConventionStateID = ccs.ConventionStateID
							INNER JOIN dbo.Un_Plan p 
								ON c.PlanID = p.PlanID
							INNER JOIN dbo.Un_Oper o 
								ON o.OperID = co.OperID 
							INNER JOIN @tConventionState tmp
								ON ccs.ConventionID = tmp.ConventionID AND	ccs.StartDate = tmp.MostRecentDate
						WHERE 
							c.ConventionId = ISNULL(@iID_Convention, c.ConventionID)
					--		AND
					--		p.PlanTypeID = 'IND'	-- JFG : 2009-10-30
							AND
							cs.ConventionStateID IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire
							AND 
							o.OperDate < @dtPremierJourDuMoisATraiter		
							AND
							co.ConventionOperTypeID = @vcConventionOperTypeRendement_TIN	
						GROUP BY 
							c.ConventionID	
						HAVING 
							SUM(co.ConventionOperAmount) <> 0 -- > 0 FT 2011-03-17
							
						--  ****** FIN DU TRAITEMENT POUR LES TRANSACTIONS EN DATE DU PREMIER JOUR DU MOIS À TRAITER ********

						--  ****** DÉBUT DU TRAITEMENT POUR LE MOIS À TRAITER *******	
							INSERT INTO @tblTransactionConvention	
							(
								iID_Convention			
								,iJourOperation			
								,mMontantITR
							)
							SELECT 
								c.ConventionID
								,DAY(o.OperDate)
								,SUM(CO.ConventionOperAmount)
							FROM 
								dbo.Un_Convention c
								INNER JOIN dbo.Un_ConventionOper co
									ON c.ConventionID = co.ConventionID
								INNER JOIN	dbo.Un_ConventionConventionState ccs
									ON c.ConventionID = ccs.ConventionID
								INNER JOIN	dbo.Un_ConventionState cs
									ON cs.ConventionStateID = ccs.ConventionStateID
								INNER JOIN dbo.Un_Plan p 
									ON p.PlanID = c.PlanID
								INNER JOIN dbo.Un_Oper o 
									ON o.OperID = co.OperID 
								INNER JOIN @tConventionState tmp
									ON ccs.ConventionID = tmp.ConventionID AND	ccs.StartDate = tmp.MostRecentDate
							WHERE 
								c.ConventionId = ISNULL(@iID_Convention, c.ConventionID)
							--	AND
							--	p.PlanTypeID = 'IND' -- JFG : 2009-10-30
								AND 
								o.OperDate BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter 	
								AND
								co.ConventionOperTypeID = @vcConventionOperTypeRendement_TIN	
							GROUP BY 
								c.ConventionID
								,o.OperDate
						--  ****** FIN DU TRAITEMENT POUR LE MOIS À TRAITER *******
							
						-- CALCUL DU MONTANT ET INSERTION DES TRANSACTIONS DANS LA TABLE DES OPÉRATIONS SUR CONVENTIONS
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						) 
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeRendement_TIN
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantITR,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention
						HAVING
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantITR,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantITR,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)
																					

						IF @bActiveDebug = 1
							BEGIN
								IF (SELECT COUNT(*) FROM @tblTransactionConvention) > 0
									BEGIN
										SELECT '1.3.2.3.8 NEW : Rendement sur les revenus accumulés sur épargne provenant d''un TIN des conventions individuelles (existantes et nouvelles, type ITR)', tc.* 
										FROM @tblTransactionConvention tc
									END
								ELSE
									BEGIN
										SELECT '1.3.2.3.8 NEW : Rendement sur les revenus accumulés sur épargne provenant d''un TIN des conventions individuelles (existantes et nouvelles, type ITR)'
									END		
							END

						-- SUPPRESSION DU CONTENU DE LA TABLE TEMPO
						DELETE FROM @tblTransactionConvention

		-- RENDEMENT SUR REVENUS ACCUMULÉS DES NOUVELLES CONVENTIONS
						--  ****** DÉBUT DU TRAITEMENT POUR LES TRANSACTIONS ANTÉRIEURES AU PREMIER JOUR DU MOIS À TRAITER ********
						--	1. Calculer le solde de rendement de l'épargnes des nouvelles conventions individuelles
						--	   en date du premier jour du mois à traiter et que la date du prospectus de la convention
						--	   est plus grande ou égale à "A DÉTERMINER"
						--
						--	N.B.
						--		Calculer la somme de "ConventionOperAmount" dont le type 
						--		de régime est individuel.
						--
						--		Les transactions NE DOIVENT PAS être issues d'un RIO

						SET @dtDateProspectus = dbo.fnGENE_ObtenirParametre('OPER_DATE_PROSPECTUS', null, null, null, null, null, null)

						INSERT INTO @tblTransactionConvention	
						(
							iID_Convention			
							,iJourOperation			
							,mMontantITR
						)
						SELECT
							c.ConventionID
							,0
							,SUM(co.ConventionOperAmount)
						FROM
							dbo.Un_Convention c
							INNER JOIN dbo.Un_ConventionOper co
								ON c.ConventionID = co.ConventionID
							INNER JOIN	dbo.Un_ConventionConventionState ccs
								ON c.ConventionID = ccs.ConventionID
							INNER JOIN	dbo.Un_ConventionState cs
								ON cs.ConventionStateID = ccs.ConventionStateID
							INNER JOIN dbo.Un_Plan p 
								ON p.PlanID = c.PlanID
							INNER JOIN dbo.Un_Oper o 
								ON o.OperID = co.OperID 
							INNER JOIN @tConventionState tmp
								ON ccs.ConventionID = tmp.ConventionID AND	ccs.StartDate = tmp.MostRecentDate
						WHERE 
							c.ConventionId = ISNULL(@iID_Convention, c.ConventionID)
							AND
							NOT EXISTS (
										SELECT 
											1
										FROM 
											@tRIO rio
										WHERE 
											rio.iID_Convention_Destination = c.ConventionID
										)
							AND
							p.PlanTypeID = 'IND'
							AND
							cs.ConventionStateID IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire
							AND 
							o.OperDate < @dtPremierJourDuMoisATraiter		
							AND
							co.ConventionOperTypeID = @vcConventionOperTypeMntSouscrit	
							AND
							c.dtDateProspectus >= @dtDateProspectus
						GROUP BY 
							c.ConventionID
						HAVING
							SUM(co.ConventionOperAmount) <> 0 -- > 0 FT 2011-03-17
						
						--  ****** FIN DU TRAITEMENT POUR LES TRANSACTIONS EN DATE DU PREMIER JOUR DU MOIS À TRAITER ********

						--  ****** DÉBUT DU TRAITEMENT POUR LE MOIS À TRAITER *******	
						INSERT INTO @tblTransactionConvention	
						(
							iID_Convention			
							,iJourOperation			
							,mMontantITR
						)
						SELECT
							c.ConventionID
							,DAY(o.OperDate)
							,SUM(co.ConventionOperAmount)
						FROM
							dbo.Un_Convention c
							INNER JOIN dbo.Un_ConventionOper co
								ON c.ConventionID = co.ConventionID
							INNER JOIN	dbo.Un_ConventionConventionState ccs
								ON c.ConventionID = ccs.ConventionID
							INNER JOIN	dbo.Un_ConventionState cs
								ON cs.ConventionStateID = ccs.ConventionStateID
							INNER JOIN dbo.Un_Plan p 
								ON p.PlanID = c.PlanID
							INNER JOIN dbo.Un_Oper o 
								ON o.OperID = co.OperID 
							INNER JOIN @tConventionState tmp
								ON ccs.ConventionID = tmp.ConventionID AND	ccs.StartDate = tmp.MostRecentDate
						WHERE 
							c.ConventionId = ISNULL(@iID_Convention, c.ConventionID)
							AND
							NOT EXISTS (
										SELECT 
											1
										FROM 
											@tRIO rio
										WHERE 
											rio.iID_Convention_Destination = c.ConventionID
										)
							AND
							p.PlanTypeID = 'IND'
							AND
							cs.ConventionStateID IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire
							AND 
							o.OperDate BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter 	
							AND
							co.ConventionOperTypeID = @vcConventionOperTypeMntSouscrit	
							AND
							c.dtDateProspectus >= @dtDateProspectus
						GROUP BY 
							c.ConventionID
							,o.OperDate
						--  ****** FIN DU TRAITEMENT POUR LE MOIS À TRAITER *******
							
						-- CALCUL DU MONTANT ET INSERTION DES TRANSACTIONS DANS LA TABLE DES OPÉRATIONS SUR CONVENTIONS
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						) 
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeMntSouscrit
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantITR,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention
						HAVING
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantITR,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantITR,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)
																					

						IF @bActiveDebug = 1
							BEGIN
								IF (SELECT COUNT(*) FROM @tblTransactionConvention) > 0
									BEGIN
										SELECT '1.3.2.3.8 NEW : Rendement sur les revenus accumulés sur épargne des nouvelles conventions individuelles non issues d''un RIO', tc.* 
										FROM @tblTransactionConvention tc
									END
								ELSE
									BEGIN
										SELECT '1.3.2.3.8 NEW : Rendement sur les revenus accumulés sur épargne des nouvelles conventions individuelles non issues d''un RIO'
									END
							END

						-- SUPPRESSION DU CONTENU DE LA TABLE TEMPO
						DELETE FROM @tblTransactionConvention
					END							
		END
	ELSE		-- RENDEMENT MODIFIÉ -> @cEtat = 'C'
		BEGIN
			IF @vcCode_Rendement = 'REN'
				BEGIN
				--	RENDEMENT ITR
					--  ****** DÉBUT DU TRAITEMENT POUR LES TRANSACTIONS ANTÉRIEURES AU PREMIER JOUR DU MOIS À TRAITER ********
					INSERT INTO @tblTransactionConvention	
					(
						iID_Convention			
						,iJourOperation			
						,mMontantITR
					)
					SELECT 
						c.ConventionID
						,0
						,SUM(co.ConventionOperAmount)
					FROM 
						dbo.Un_Convention c
						INNER JOIN dbo.Un_ConventionOper co
							ON c.ConventionID = co.ConventionID
						INNER JOIN dbo.Un_Plan p 
							ON c.PlanID = p.PlanID
						INNER JOIN dbo.Un_Oper o 
							ON o.OperID = co.OperID 
					WHERE 
						c.ConventionId = ISNULL(@iID_Convention, c.ConventionID)
					--	AND
					--	p.PlanTypeID = 'IND'	-- JFG : 2009-10-30
						AND
						dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, c.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour
						AND 
						o.OperDate < @dtPremierJourDuMoisATraiter		
						AND
						co.ConventionOperTypeID = @vcConventionOperTypeRendement_TIN	
					GROUP BY 
						c.ConventionID		
					HAVING
						SUM(co.ConventionOperAmount) <> 0 -- > 0 FT 2011-03-17
					--  ****** FIN DU TRAITEMENT POUR LES TRANSACTIONS EN DATE DU PREMIER JOUR DU MOIS À TRAITER ********

					-- SUPPRESSION DANS UN_CONVENTION_OPER
					DELETE cop
					FROM 
						dbo.Un_ConventionOper cop
						INNER JOIN dbo.Un_Oper o 
							ON o.OperID = cop.OperID 
					WHERE 
							cop.ConventionOperTypeID = @vcConventionOperTypeRendement_TIN
							AND
							cop.ConventionId = ISNULL(@iID_Convention, cop.ConventionID)
							AND
							dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, cop.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour
							AND
							cop.OperID IN (	SELECT 
												ISNULL(tx.iID_Operation,-1) 
											FROM 
												dbo.tblOper_TauxRendement tx
												INNER JOIN dbo.tblOPER_Rendements r
													ON tx.iID_Rendement = r.iID_Rendement
												INNER JOIN dbo.tblOPER_TypesRendement tr
													ON tr.tiID_Type_Rendement = r.tiID_Type_Rendement
											WHERE 
												ISNULL(tx.dtDate_Operation, '1900-01-01') BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter
												AND
												tr.vcCode_Rendement = @vcCode_Rendement)


					--  ****** DÉBUT DU TRAITEMENT POUR LE MOIS À TRAITER *******	
					INSERT INTO @tblTransactionConvention	
					(
						iID_Convention			
						,iJourOperation			
						,mMontantITR
					)
					SELECT 
						c.ConventionID
						,DAY(o.OperDate)
						,SUM(CO.ConventionOperAmount)
					FROM 
						dbo.Un_Convention c
						INNER JOIN dbo.Un_ConventionOper co
							ON c.ConventionID = co.ConventionID
						INNER JOIN dbo.Un_Plan p 
							ON p.PlanID = c.PlanID
						INNER JOIN dbo.Un_Oper o 
							ON o.OperID = co.OperID 
					WHERE 
						c.ConventionId = ISNULL(@iID_Convention, c.ConventionID)
					--	AND
					--	p.PlanTypeID = 'IND' -- JFG : 2009-10-30
						AND 
						o.OperDate BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter
						AND
						co.ConventionOperTypeID = @vcConventionOperTypeRendement_TIN	
						AND
						dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, c.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour
					GROUP BY 
						c.ConventionID
						,o.OperDate
					--  ****** FIN DU TRAITEMENT POUR LE MOIS À TRAITER *******
						
					-- CALCUL DU MONTANT ET INSERTION DES TRANSACTIONS DANS LA TABLE DES OPÉRATIONS SUR CONVENTIONS
					INSERT INTO	dbo.Un_ConventionOper
					(
						OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
					) 
					SELECT 
						@iID_Oper
						,tc.iID_Convention						
						,@vcConventionOperTypeRendement_TIN
						,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantITR,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
					FROM
						@tblTransactionConvention tc
					GROUP BY
						tc.iID_Convention
					HAVING
						SUM(dbo.fnOPER_CalculerRendement(tc.mMontantITR,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

					-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
					SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantITR,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																				FROM	@tblTransactionConvention tc),0)

					IF @bActiveDebug = 1
						BEGIN
							IF (SELECT COUNT(*) FROM @tblTransactionConvention) > 0
								BEGIN
									SELECT '1.3.2.3.8 MOD : Rendement sur les revenus accumulés sur épargne provenant d''un TIN des conventions individuelles (existantes et nouvelles, type ITR)', tc.* 
									FROM @tblTransactionConvention tc
								END
							ELSE
								BEGIN
									SELECT '1.3.2.3.8 MOD : Rendement sur les revenus accumulés sur épargne provenant d''un TIN des conventions individuelles (existantes et nouvelles, type ITR)'
								END		
						END

					-- SUPPRESSION DU CONTENU DE LA TABLE TEMPO
					DELETE FROM @tblTransactionConvention

			-- RENDEMENT SUR REVENUS ACCUMULÉS DES NOUVELLES CONVENTIONS
					--  ****** DÉBUT DU TRAITEMENT POUR LES TRANSACTIONS ANTÉRIEURES AU PREMIER JOUR DU MOIS À TRAITER ********
					SET @dtDateProspectus = dbo.fnGENE_ObtenirParametre('OPER_DATE_PROSPECTUS', null, null, null, null, null, null)

					INSERT INTO @tblTransactionConvention	
					(
						iID_Convention			
						,iJourOperation			
						,mMontantITR
					)
					SELECT
						c.ConventionID
						,0
						,SUM(co.ConventionOperAmount)
					FROM
						dbo.Un_Convention c
						INNER JOIN dbo.Un_ConventionOper co
							ON c.ConventionID = co.ConventionID
						INNER JOIN dbo.Un_Plan p 
							ON p.PlanID = c.PlanID
						INNER JOIN dbo.Un_Oper o 
							ON o.OperID = co.OperID 
					WHERE 
						c.ConventionId = ISNULL(@iID_Convention, c.ConventionID)
						AND
						NOT EXISTS (
									SELECT 
										1
									FROM 
										@tRIO rio
									WHERE 
										rio.iID_Convention_Destination = c.ConventionID
									)
						AND
						p.PlanTypeID = 'IND'
						AND
						dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, c.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour
						AND 
						o.OperDate < @dtPremierJourDuMoisATraiter		
						AND
						co.ConventionOperTypeID = @vcConventionOperTypeMntSouscrit	
						AND
						c.dtDateProspectus >= @dtDateProspectus
						AND
						o.OperID <> @iID_OPER
					GROUP BY 
						c.ConventionID
					HAVING
						SUM(co.ConventionOperAmount) <> 0 -- > 0 FT 2011-03-17

					--  ****** FIN DU TRAITEMENT POUR LES TRANSACTIONS EN DATE DU PREMIER JOUR DU MOIS À TRAITER ********

					-- SUPPRESION DANS UN_CONVENTION_OPER
					DELETE cop
					FROM 
						dbo.Un_ConventionOper cop
						INNER JOIN dbo.Un_Oper o 
							ON o.OperID = cop.OperID 
					WHERE 
							cop.ConventionOperTypeID = @vcConventionOperTypeMntSouscrit
							AND
							cop.ConventionId = ISNULL(@iID_Convention, cop.ConventionID)
							AND
							dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, cop.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour
							AND
							cop.OperID IN (	SELECT 
												ISNULL(tx.iID_Operation,-1) 
											FROM 
												dbo.tblOper_TauxRendement tx
												INNER JOIN dbo.tblOPER_Rendements r
													ON tx.iID_Rendement = r.iID_Rendement
												INNER JOIN dbo.tblOPER_TypesRendement tr
													ON tr.tiID_Type_Rendement = r.tiID_Type_Rendement
											WHERE 
												ISNULL(tx.dtDate_Operation, '1900-01-01') BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter
												AND
												tr.vcCode_Rendement = @vcCode_Rendement)


					--  ****** DÉBUT DU TRAITEMENT POUR LE MOIS À TRAITER *******	
					INSERT INTO @tblTransactionConvention	
					(
						iID_Convention			
						,iJourOperation			
						,mMontantITR
					)
					SELECT
						c.ConventionID
						,DAY(o.OperDate)
						,SUM(co.ConventionOperAmount)
					FROM
						dbo.Un_Convention c
						INNER JOIN dbo.Un_ConventionOper co
							ON c.ConventionID = co.ConventionID
						INNER JOIN dbo.Un_Plan p 
							ON p.PlanID = c.PlanID
						INNER JOIN dbo.Un_Oper o 
							ON o.OperID = co.OperID 
					WHERE 
						c.ConventionId = ISNULL(@iID_Convention, c.ConventionID)
						AND
						NOT EXISTS (
									SELECT 
										1
									FROM 
										@tRIO rio
									WHERE 
										rio.iID_Convention_Destination = c.ConventionID
									)
						AND
						p.PlanTypeID = 'IND'
						AND
						dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, c.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour				
						AND 
						o.OperDate BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter
						AND
						co.ConventionOperTypeID = @vcConventionOperTypeMntSouscrit	
						AND
						c.dtDateProspectus >= @dtDateProspectus
					GROUP BY 
						c.ConventionID
						,o.OperDate
					--  ****** FIN DU TRAITEMENT POUR LE MOIS À TRAITER *******
						
					-- CALCUL DU MONTANT ET INSERTION DES TRANSACTIONS DANS LA TABLE DES OPÉRATIONS SUR CONVENTIONS
					INSERT INTO	dbo.Un_ConventionOper
					(
						OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
					) 
					SELECT 
						@iID_Oper
						,tc.iID_Convention						
						,@vcConventionOperTypeMntSouscrit
						,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantITR,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
					FROM
						@tblTransactionConvention tc
					GROUP BY
						tc.iID_Convention
					HAVING
						SUM(dbo.fnOPER_CalculerRendement(tc.mMontantITR,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

					-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
					SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantITR,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																				FROM	@tblTransactionConvention tc),0)
																				
					IF @bActiveDebug = 1
						BEGIN
							IF (SELECT COUNT(*) FROM @tblTransactionConvention) > 0
								BEGIN
									SELECT '1.3.2.3.8 MOD : Rendement sur les revenus accumulés sur épargne des nouvelles conventions individuelles non issues d''un RIO', tc.* 
									FROM @tblTransactionConvention tc
								END
							ELSE
								BEGIN
									SELECT '1.3.2.3.8 MOD : Rendement sur les revenus accumulés sur épargne des nouvelles conventions individuelles non issues d''un RIO'
								END
						END

					-- SUPPRESSION DU CONTENU DE LA TABLE TEMPO
					DELETE FROM @tblTransactionConvention
				END
		END			
---------------------------------------------------------------------------------------------------------------------------------
				-- FIN DU CALCUL DU  RENDEMENT SUR LES REVENUS ACCUMULÉS SUR L'ÉPARGE PROVENANT D'UN TRANFERT IN
				-- DES CONVENTIONS INDIVIDUELLES (ITR)
				-- ET DU RENDEMENT SUR LES REVENUS ACCUMULÉS SUR L'ÉPARGNE DES NOUVELLES CONVENTIONS QUI NE SONT PAS ISSUES D'UN RIO						
---------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------------------------
-- 1.3.2.3.9	-- DÉBUT DU CALCUL DU RENDEMENT DES CONVENTIONS INDIVIDUELLES EXISTANTES QUI NE SONT PAS ISSUES D'UN RIO
				-- ET
				-- DU RENDEMENT SUR LES REVENUS ACCUMULÉS SUR L'ÉPARGNE DES CONVENTIONS INDIVIDUELLES EXISTANTES QUI NE SONT
				-- PAS ISSUES D'UN RIO (OPÉRATION : INM)
---------------------------------------------------------------------------------------------------------------------------------
	IF @cEtat = 'S' -- nouveau rendement
		BEGIN
					--Valide si c'est le bon code de rendement pour ce traitement
					IF @vcCode_Rendement = 'REE'
					BEGIN

						SET @dtDateProspectus = dbo.fnGENE_ObtenirParametre('OPER_DATE_PROSPECTUS', null, null, null, null, null, null)

	-- ÉPARGNE DES CONVENTIONS INDIVIDUELLES EXISTANTES
						--  ****** DÉBUT DU TRAITEMENT POUR LES TRANSACTIONS ANTÉRIEURES AU PREMIER JOUR DU MOIS À TRAITER ********
						--	1.	Calculer le solde de l'épargne des conventions individuelles existantes en date du premier jour du
						--		à traiter et que la date du prospectus de la convention est plus petite que "A DETERMINER"
						--
						--	N.B.
						--		Vérifier que la convention n'est pas issue d'un RIO
						--		Calculer la somme du champ "Cotisation" de la table "Un_Cotisation" dont le type de régime est IND
						INSERT INTO @tblTransactionConvention	
						(
							iID_Convention			
							,iJourOperation			
							,mMontantRI
						)
						SELECT 
							u.ConventionID
							,0
							,SUM(ct.Cotisation)
						FROM 
							dbo.Un_Unit u
							INNER JOIN dbo.Un_Convention co 
								ON co.ConventionID = u.ConventionID
							INNER JOIN	dbo.Un_ConventionConventionState ccs
								ON co.ConventionID = ccs.ConventionID
							INNER JOIN	dbo.Un_ConventionState cs
								ON cs.ConventionStateID = ccs.ConventionStateID
							INNER JOIN dbo.Un_Modal m 
								ON m.ModalID = u.ModalID
							INNER JOIN dbo.Un_Plan p 
								ON p.PlanID = m.PlanID
							INNER JOIN dbo.Un_Cotisation ct 
								ON ct.UnitID = u.UnitID
							INNER JOIN dbo.Un_Oper o 
								ON o.OperID = ct.OperID 
							INNER JOIN @tConventionState tmp
								ON ccs.ConventionID = tmp.ConventionID AND	ccs.StartDate = tmp.MostRecentDate
						WHERE 
							u.ConventionId = ISNULL(@iID_Convention, u.ConventionID)
							AND
							NOT EXISTS (
										SELECT 
											1
										FROM 
											@tRIO rio
										WHERE 
											rio.iID_Convention_Destination = u.ConventionID
										)
							AND
							p.PlanTypeID = 'IND'
							AND 
							cs.ConventionStateID IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire
							AND
							o.OperDate < @dtPremierJourDuMoisATraiter -- modifié par JFA 2009-08-28	
							AND 
							(co.dtDateProspectus < @dtDateProspectus OR co.dtDateProspectus IS NULL) --JFA 2009-08-28
						GROUP BY 
							u.ConventionID
						HAVING
							SUM(ct.Cotisation) <> 0 -- > 0 FT 2011-03-17
						
						--  ****** FIN DU TRAITEMENT POUR LES TRANSACTIONS EN DATE DU PREMIER JOUR DU MOIS À TRAITER ********

						--  ****** DÉBUT DU TRAITEMENT POUR LE MOIS À TRAITER *******	
						--	1.	Obtenir les nouvelles opérations sur l'épargne des conventions individuelles existantes
						--		dans le mois à traiter et que la date de prospectus est plus petite que "A DETERMINER"
						--
						--	N.B.
						--		Vérifier si les conventions sont issues d'un RIO et que la période de probation est
						--		couverte. Si la date de début de régime additionné au nombre de mois avant le remboursement
						--		intégral après le RIO est plus petite que la date de fin du mois à traiter.
						--
						--		Calculer la somme du champ "Cotisation" de la table "Un_Cotisation" dont le type
						--		de régime est individuel.
						INSERT INTO @tblTransactionConvention	
						(
							iID_Convention			
							,iJourOperation			
							,mMontantRI
						)
						SELECT 
							u.ConventionID
							,DAY(o.OperDate)
							,SUM(ct.Cotisation)
						FROM 
							dbo.Un_Unit u
							INNER JOIN dbo.Un_Convention co 
								ON co.ConventionID = u.ConventionID
							INNER JOIN	dbo.Un_ConventionConventionState ccs
								ON co.ConventionID = ccs.ConventionID
							INNER JOIN	dbo.Un_ConventionState cs
								ON cs.ConventionStateID = ccs.ConventionStateID
							INNER JOIN dbo.Un_Modal m 
								ON m.ModalID = u.ModalID
							INNER JOIN dbo.Un_Plan p 
								ON p.PlanID = m.PlanID
							INNER JOIN dbo.Un_Cotisation ct 
								ON ct.UnitID = u.UnitID
							INNER JOIN dbo.Un_Oper o 
								ON o.OperID = ct.OperID 
							INNER JOIN @tConventionState tmp
								ON ccs.ConventionID = tmp.ConventionID AND	ccs.StartDate = tmp.MostRecentDate
						WHERE 
							u.ConventionId = ISNULL(@iID_Convention, u.ConventionID)
							AND
							NOT EXISTS (
										SELECT 
											1
										FROM 
											@tRIO rio
										WHERE 
											rio.iID_Convention_Destination = u.ConventionID
										)
							AND
							p.PlanTypeID = 'IND'
							AND
							cs.ConventionStateID IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire
							AND 
							o.OperDate BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter 
							AND 
							(co.dtDateProspectus < @dtDateProspectus OR co.dtDateProspectus IS NULL) --JFA 2009-08-28
						GROUP BY 
							u.ConventionID
							,o.OperDate
							
						--  ****** FIN DU TRAITEMENT POUR LE MOIS À TRAITER *******

						-- CALCUL DU MONTANT ET INSERTION DES TRANSACTIONS DANS LA TABLE DES OPÉRATIONS SUR CONVENTIONS
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						)
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeMntSouscrit
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantRI,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention 
						HAVING
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantRI,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0
						
						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantRI,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)
																					
						
						IF @bActiveDebug = 1
							BEGIN
								IF (SELECT COUNT(*) FROM @tblTransactionConvention) > 0
									BEGIN
										SELECT '1.3.2.3.9 NEW : Rendement sur les revenus accumulés sur épargne des conventions individuelles existantes non issues d''un RIO de type INM', tc.* 
										FROM @tblTransactionConvention tc
									END
								ELSE
									BEGIN
										SELECT '1.3.2.3.9 NEW : Rendement sur les revenus accumulés sur épargne des conventions individuelles existantes non issues d''un RIO de type INM'
									END
							END

						-- SUPPRESSION DU CONTENU DE LA TABLE TEMPO
						DELETE FROM @tblTransactionConvention

	-- REVENUS ACCUMULÉS SUR L'ÉPARGNE DES CONVENTIONS INDIVIDUELLES EXISTANTES
						--  ****** DÉBUT DU TRAITEMENT POUR LES TRANSACTIONS ANTÉRIEURES AU PREMIER JOUR DU MOIS À TRAITER ********
						--	N.B.
						--		Calculer la somme du champ "ConventionOperAmount" de la table "Un_ConventionOper"
						--		dont le régime est individuel.
						--	
						INSERT INTO @tblTransactionConvention	
						(
							iID_Convention			
							,iJourOperation			
							,mMontantRI
						)
						SELECT
							c.ConventionID
							,0
							,SUM(co.ConventionOperAmount)
						FROM
							dbo.Un_Convention c
							INNER JOIN dbo.Un_ConventionOper co
								ON c.ConventionID = co.ConventionID
							INNER JOIN	dbo.Un_ConventionConventionState ccs
								ON c.ConventionID = ccs.ConventionID
							INNER JOIN	dbo.Un_ConventionState cs
								ON cs.ConventionStateID = ccs.ConventionStateID
							INNER JOIN dbo.Un_Plan p 
								ON p.PlanID = c.PlanID
							INNER JOIN dbo.Un_Oper o 
								ON o.OperID = co.OperID 
							INNER JOIN @tConventionState tmp
								ON ccs.ConventionID = tmp.ConventionID AND	ccs.StartDate = tmp.MostRecentDate
						WHERE 
							c.ConventionId = ISNULL(@iID_Convention, c.ConventionID)
							AND
							NOT EXISTS (
										SELECT 
											1
										FROM 
											@tRIO rio
										WHERE 
											rio.iID_Convention_Destination = c.ConventionID
										)
							AND
							p.PlanTypeID = 'IND'
							AND
							cs.ConventionStateID IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire
							AND 
							o.OperDate < @dtPremierJourDuMoisATraiter		
							AND
							co.ConventionOperTypeID = @vcConventionOperTypeMntSouscrit	
							AND
							(c.dtDateProspectus < @dtDateProspectus OR c.dtDateProspectus IS NULL)--JFA 2009-08-28
						GROUP BY 
							c.ConventionID
						HAVING 
							SUM(co.ConventionOperAmount) <> 0 -- > 0 FT 2011-03-17
						--  ****** FIN DU TRAITEMENT POUR LES TRANSACTIONS EN DATE DU PREMIER JOUR DU MOIS À TRAITER ********

						--  ****** DÉBUT DU TRAITEMENT POUR LE MOIS À TRAITER *******	
						INSERT INTO @tblTransactionConvention	
						(
							iID_Convention			
							,iJourOperation			
							,mMontantRI
						)
						SELECT
							c.ConventionID
							,DAY(o.OperDate)
							,SUM(co.ConventionOperAmount)
						FROM
							dbo.Un_Convention c
							INNER JOIN dbo.Un_ConventionOper co
								ON c.ConventionID = co.ConventionID
							INNER JOIN	dbo.Un_ConventionConventionState ccs
								ON c.ConventionID = ccs.ConventionID
							INNER JOIN	dbo.Un_ConventionState cs
								ON cs.ConventionStateID = ccs.ConventionStateID
							INNER JOIN dbo.Un_Plan p 
								ON p.PlanID = c.PlanID
							INNER JOIN dbo.Un_Oper o 
								ON o.OperID = co.OperID 
							INNER JOIN @tConventionState tmp
								ON ccs.ConventionID = tmp.ConventionID AND	ccs.StartDate = tmp.MostRecentDate
						WHERE 
							c.ConventionId = ISNULL(@iID_Convention, c.ConventionID)
							AND
							NOT EXISTS (
										SELECT 
											1
										FROM 
											@tRIO rio
										WHERE 											
											rio.iID_Convention_Destination = c.ConventionID
										)
							AND
							p.PlanTypeID = 'IND'
							AND
							cs.ConventionStateID IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire
							AND 
							o.OperDate BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter 	
							AND
							co.ConventionOperTypeID = @vcConventionOperTypeMntSouscrit	
							AND
							(c.dtDateProspectus < @dtDateProspectus OR c.dtDateProspectus IS NULL)--JFA 2009-08-28
						GROUP BY 
							c.ConventionID
							,o.OperDate
						--  ****** FIN DU TRAITEMENT POUR LE MOIS À TRAITER *******


						-- CALCUL DU MONTANT ET INSERTION DES TRANSACTIONS DANS LA TABLE DES OPÉRATIONS SUR CONVENTIONS
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						) 
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeMntSouscrit
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantRI,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention
						HAVING
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantRI,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantRI,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)
																					

						IF @bActiveDebug = 1
							BEGIN
								IF (SELECT COUNT(*) FROM @tblTransactionConvention) > 0
									BEGIN
										SELECT '1.3.2.3.9 NEW : Rendement sur l''épargne des conventions individuelles existantes non issues d''un RIO', tc.* 
										FROM @tblTransactionConvention tc
									END
								ELSE
									BEGIN
										SELECT '1.3.2.3.9 NEW : Rendement sur l''épargne des conventions individuelles existantes non issues d''un RIO'
									END
							END

						-- SUPPRESSION DU CONTENU DE LA TABLE TEMPO
						DELETE FROM @tblTransactionConvention
					END
		END
	ELSE	-- TAUX MODIFIÉ @CETAT = 'C'
		BEGIN
			IF @vcCode_Rendement = 'REE'
				BEGIN
					SET @dtDateProspectus = dbo.fnGENE_ObtenirParametre('OPER_DATE_PROSPECTUS', null, null, null, null, null, null)

				-- ÉPARGNE DES CONVENTIONS INDIVIDUELLES EXISTANTES
						--  ****** DÉBUT DU TRAITEMENT POUR LES TRANSACTIONS ANTÉRIEURES AU PREMIER JOUR DU MOIS À TRAITER ********
						INSERT INTO @tblTransactionConvention	
						(
							iID_Convention			
							,iJourOperation			
							,mMontantRI
						)
						SELECT 
							u.ConventionID
							,0
							,SUM(ct.Cotisation)
						FROM 
							dbo.Un_Unit u
							INNER JOIN dbo.Un_Convention co 
								ON co.ConventionID = u.ConventionID
							INNER JOIN dbo.Un_Modal m 
								ON m.ModalID = u.ModalID
							INNER JOIN dbo.Un_Plan p 
								ON p.PlanID = m.PlanID
							INNER JOIN dbo.Un_Cotisation ct 
								ON ct.UnitID = u.UnitID
							INNER JOIN dbo.Un_Oper o 
								ON o.OperID = ct.OperID 
						WHERE 
							u.ConventionId = ISNULL(@iID_Convention, u.ConventionID)
							AND
							NOT EXISTS (
										SELECT 
											1
										FROM 
											@tRIO rio
										WHERE 
											rio.iID_Convention_Destination = u.ConventionID
										)
							AND
							p.PlanTypeID = 'IND'
							AND 
							dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, u.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour
							AND
							o.OperDate < @dtPremierJourDuMoisATraiter -- modifié par JFA 2009-08-28	
							AND 
							(co.dtDateProspectus < @dtDateProspectus OR co.dtDateProspectus IS NULL) --JFA 2009-08-28
						GROUP BY 
							u.ConventionID
						HAVING
							SUM(ct.Cotisation) <> 0 -- > 0 FT 2011-03-17
						
						--  ****** FIN DU TRAITEMENT POUR LES TRANSACTIONS EN DATE DU PREMIER JOUR DU MOIS À TRAITER ********

						-- SUPPRESSION DES TRANSACTIONS 
						DELETE cop
						FROM dbo.Un_ConventionOper cop
							INNER JOIN dbo.Un_Oper o 
								ON o.OperID = cop.OperID 
						WHERE 
								cop.ConventionId = ISNULL(@iID_Convention, cop.ConventionID)
								AND
								dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, cop.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour
								AND
								cop.OperID IN (	SELECT 
													ISNULL(tx.iID_Operation,-1) 
												FROM 
													dbo.tblOper_TauxRendement tx
													INNER JOIN dbo.tblOPER_Rendements r
														ON tx.iID_Rendement = r.iID_Rendement
													INNER JOIN dbo.tblOPER_TypesRendement tr
														ON tr.tiID_Type_Rendement = r.tiID_Type_Rendement
												WHERE 
													ISNULL(tx.dtDate_oPERATION, '1900-01-01') BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter
													AND
													tr.vcCode_Rendement = @vcCode_Rendement)
						
						--  ****** DÉBUT DU TRAITEMENT POUR LE MOIS À TRAITER *******	
						INSERT INTO @tblTransactionConvention	
						(
							iID_Convention			
							,iJourOperation			
							,mMontantRI
						)
						SELECT 
							u.ConventionID
							,DAY(o.OperDate)
							,SUM(ct.Cotisation)
						FROM 
							dbo.Un_Unit u
							INNER JOIN dbo.Un_Convention co 
								ON co.ConventionID = u.ConventionID
							INNER JOIN dbo.Un_Modal m 
								ON m.ModalID = u.ModalID
							INNER JOIN dbo.Un_Plan p 
								ON p.PlanID = m.PlanID
							INNER JOIN dbo.Un_Cotisation ct 
								ON ct.UnitID = u.UnitID
							INNER JOIN dbo.Un_Oper o 
								ON o.OperID = ct.OperID 
						WHERE 
							u.ConventionId = ISNULL(@iID_Convention, u.ConventionID)
							AND
							NOT EXISTS (
										SELECT 
											1
										FROM 
											@tRIO rio
										WHERE 
											rio.iID_Convention_Destination = u.ConventionID
										)
							AND
							p.PlanTypeID = 'IND'
							AND
							dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, co.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour				
							AND 
							o.OperDate BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter
							AND 
							(co.dtDateProspectus < @dtDateProspectus OR co.dtDateProspectus IS NULL) --JFA 2009-08-28
						GROUP BY 
							u.ConventionID
							,o.OperDate
							
						--  ****** FIN DU TRAITEMENT POUR LE MOIS À TRAITER *******

						-- CALCUL DU MONTANT ET INSERTION DES TRANSACTIONS DANS LA TABLE DES OPÉRATIONS SUR CONVENTIONS
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						)
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeMntSouscrit
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantRI,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention 
						HAVING
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantRI,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

						
						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantRI,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)
																					
						
						IF @bActiveDebug = 1
							BEGIN
								IF (SELECT COUNT(*) FROM @tblTransactionConvention) > 0
									BEGIN
										SELECT '1.3.2.3.9 MOD : Rendement sur les revenus accumulés sur épargne des conventions individuelles existantes non issues d''un RIO de type INM', tc.* 
										FROM @tblTransactionConvention tc
									END
								ELSE
									BEGIN
										SELECT '1.3.2.3.9 MOD : Rendement sur les revenus accumulés sur épargne des conventions individuelles existantes non issues d''un RIO de type INM'
									END
							END

						-- SUPPRESSION DU CONTENU DE LA TABLE TEMPO
						DELETE FROM @tblTransactionConvention

	-- REVENUS ACCUMULÉS SUR L'ÉPARGNE DES CONVENTIONS INDIVIDUELLES EXISTANTES
						--  ****** DÉBUT DU TRAITEMENT POUR LES TRANSACTIONS ANTÉRIEURES AU PREMIER JOUR DU MOIS À TRAITER ********
						INSERT INTO @tblTransactionConvention	
						(
							iID_Convention			
							,iJourOperation			
							,mMontantRI
						)
						SELECT
							c.ConventionID
							,0
							,SUM(co.ConventionOperAmount)
						FROM
							dbo.Un_Convention c
							INNER JOIN dbo.Un_ConventionOper co
								ON c.ConventionID = co.ConventionID
							INNER JOIN dbo.Un_Plan p 
								ON p.PlanID = c.PlanID
							INNER JOIN dbo.Un_Oper o 
								ON o.OperID = co.OperID 
						WHERE 
							c.ConventionId = ISNULL(@iID_Convention, c.ConventionID)
							AND
							NOT EXISTS (
										SELECT 
											1
										FROM 
											@tRIO rio
										WHERE 
											rio.iID_Convention_Destination = c.ConventionID
										)
							AND
							p.PlanTypeID = 'IND'
							AND
							dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, c.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour
							AND 
							o.OperDate < @dtPremierJourDuMoisATraiter		
							AND
							co.ConventionOperTypeID = @vcConventionOperTypeMntSouscrit	
							AND
							(c.dtDateProspectus < @dtDateProspectus OR c.dtDateProspectus IS NULL)--JFA 2009-08-28
						GROUP BY 
							c.ConventionID
						HAVING
							SUM(co.ConventionOperAmount) <> 0 -- > 0 FT 2011-03-17
						--  ****** FIN DU TRAITEMENT POUR LES TRANSACTIONS EN DATE DU PREMIER JOUR DU MOIS À TRAITER ********

						-- SUPPRESION DES TRASACTIONS DANS UN_CONVENTION_OPER
						DELETE cop
						FROM dbo.Un_ConventionOper cop
							INNER JOIN dbo.Un_Oper o 
								ON o.OperID = cop.OperID 
						WHERE 
								cop.ConventionOperTypeID = @vcConventionOperTypeMntSouscrit
								AND
								cop.ConventionId = ISNULL(@iID_Convention, cop.ConventionID)
								AND
								dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, cop.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour
								AND
								cop.OperID IN (	SELECT 
													ISNULL(tx.iID_Operation,-1) 
												FROM 
													dbo.tblOper_TauxRendement tx
													INNER JOIN dbo.tblOPER_Rendements r
														ON tx.iID_Rendement = r.iID_Rendement
													INNER JOIN dbo.tblOPER_TypesRendement tr
														ON tr.tiID_Type_Rendement = r.tiID_Type_Rendement
												WHERE 
													ISNULL(tx.dtDate_oPERATION, '1900-01-01') BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter
													AND
													tr.vcCode_Rendement = @vcCode_Rendement)

						--  ****** DÉBUT DU TRAITEMENT POUR LE MOIS À TRAITER *******	
						INSERT INTO @tblTransactionConvention	
						(
							iID_Convention			
							,iJourOperation			
							,mMontantRI
						)
						SELECT
							c.ConventionID
							,DAY(o.OperDate)
							,SUM(co.ConventionOperAmount)
						FROM
							dbo.Un_Convention c
							INNER JOIN dbo.Un_ConventionOper co
								ON c.ConventionID = co.ConventionID
							INNER JOIN dbo.Un_Plan p 
								ON p.PlanID = c.PlanID
							INNER JOIN dbo.Un_Oper o 
								ON o.OperID = co.OperID 
						WHERE 
							c.ConventionId = ISNULL(@iID_Convention, c.ConventionID)
							AND
							NOT EXISTS (
										SELECT 
											1
										FROM 
											@tRIO rio
										WHERE 											
											rio.iID_Convention_Destination = c.ConventionID
										)
							AND
							p.PlanTypeID = 'IND'
							AND
							dbo.fnCONV_ObtenirStatutConventionEnDate(ISNULL(@iID_Convention, c.ConventionID), GETDATE()) IN ('REE','TRA')	-- Type RÉÉÉ ou Transitoire en date du jour				
							AND 
							o.OperDate BETWEEN @dtPremierJourDuMoisATraiter AND @dtDernierJourDuMoisATraiter
							AND
							co.ConventionOperTypeID = @vcConventionOperTypeMntSouscrit	
							AND
							(c.dtDateProspectus < @dtDateProspectus OR c.dtDateProspectus IS NULL)--JFA 2009-08-28
						GROUP BY 
							c.ConventionID
							,o.OperDate
						--  ****** FIN DU TRAITEMENT POUR LE MOIS À TRAITER *******


						-- CALCUL DU MONTANT ET INSERTION DES TRANSACTIONS DANS LA TABLE DES OPÉRATIONS SUR CONVENTIONS
						INSERT INTO	dbo.Un_ConventionOper
						(
							OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
						) 
						SELECT 
							@iID_Oper
							,tc.iID_Convention						
							,@vcConventionOperTypeMntSouscrit
							,SUM(dbo.fnOPER_CalculerRendement(tc.mMontantRI,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
						FROM
							@tblTransactionConvention tc
						GROUP BY
							tc.iID_Convention
						HAVING
							SUM(dbo.fnOPER_CalculerRendement(tc.mMontantRI,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation)) <> 0

						-- AJOUT DU MONTANT AU MONTANT TOTAL GÉNÉRÉ
						SET @mMontantTotal_Genere = @mMontantTotal_Genere + ISNULL((SELECT	SUM(dbo.fnOPER_CalculerRendement(tc.mMontantRI,@dTaux_Rendement, @iNbJourMoisATraiter, tc.iJourOperation))
																					FROM	@tblTransactionConvention tc),0)
																					

						IF @bActiveDebug = 1
							BEGIN
								IF (SELECT COUNT(*) FROM @tblTransactionConvention) > 0
									BEGIN
										SELECT '1.3.2.3.9 MOD : Rendement sur l''épargne des conventions individuelles existantes non issues d''un RIO', tc.* 
										FROM @tblTransactionConvention tc
									END
								ELSE
									BEGIN
										SELECT '1.3.2.3.9 MOD : Rendement sur l''épargne des conventions individuelles existantes non issues d''un RIO'
									END
							END

						-- SUPPRESSION DU CONTENU DE LA TABLE TEMPO
						DELETE FROM @tblTransactionConvention
				END
		END
---------------------------------------------------------------------------------------------------------------------------------
				-- FIN DU CALCUL DU RENDEMENT DES CONVENTIONS INDIVIDUELLES EXISTANTES QUI NE SONT PAS ISSUES D'UN RIO
				-- ET
				-- DU RENDEMENT SUR LES REVENUS ACCUMULÉS SUR L'ÉPARGNE DES CONVENTIONS INDIVIDUELLES EXISTANTES QUI NE SONT
				-- PAS ISSUES D'UN RIO (OPÉRATION : INM)
---------------------------------------------------------------------------------------------------------------------------------

					-- APRÈS TOUS LES CALCULS, MISE À JOUR DE LA TABLE tblOPER_TauxRendement
					IF @bActiveDebug = 1
						BEGIN
							SELECT 
								'Information de mise à jour de tblOper_TauxRendement pour le Code de rendement : ' + @vcCode_Rendement
								,'OperId = ' + CAST(@iID_OPER AS VARCHAR(20)) -- FT
								,'Montant total généré = ' + CAST(@mMontantTotal_Genere AS VARCHAR(20)) -- FT
								,GETDATE()
						END


					UPDATE	dbo.tblOPER_TauxRendement
					SET		iID_Operation		= @iID_OPER
							,mMontant_Genere	= @mMontantTotal_Genere
							,dtDate_Generation	= GETDATE()
					WHERE
							iID_Taux_Rendement	= @iID_Taux_Rendement						 
	
					FETCH NEXT FROM curRendement INTO
						@iID_Taux_Rendement,@dtDate_Calcul_Rendement
						,@dTaux_Rendement,@iAnneeATraiter,@iMoisATraiter
						,@iNbJourAnneeATraiter,@iNbJourMoisATraiter,@dtPremierJourDuMoisATraiter,@dtDernierJourDuMoisATraiter
						,@vcTypeOperationCategorie,@iConnectId,@vcTypeOperation,@vcCode_Rendement,@dtMaxDateGeneration
				END

			-- FERMETURE ET DESTRUCTION DU CURSEUR DES RENDEMENTS
			CLOSE curRendement
			DEALLOCATE curRendement

			-- 2009-12-17 : Ajout du code de Rémy Rouillard
			------------------------------------------------------------------------------------------------
			-- Retransférer les rendements générés vers les conventions individuelles issues d'un RIO 
			-- Seul les codes d'opération sur convention suivants sont à vérifier --> INS,IS+,IBC,IST,ITR,INM
			-- Les codes d'opération sur convention IQEE seront gérés dans un autre script.
			------------------------------------------------------------------------------------------------
			IF @bDataPresent = 1	-- 2010-04-01 : JFG : Si les données sont présentes dans le curseur, on fait le calcul
				BEGIN
					BEGIN TRANSACTION
					BEGIN TRY
						DECLARE @iID_Convention_Source INT,
								@iID_Unite_Source INT,
								@dtDateDuJour DATETIME,
								@vcRIO_TRANSFERT_TRANSAC_CONVENTION VARCHAR(200),
								@iID_Connexion INT
								,@OperTypeID	VARCHAR(3) -- FT1

						SET @vcRIO_TRANSFERT_TRANSAC_CONVENTION = [dbo].[fnOPER_ObtenirTypesOperationConvCategorie]('RIO-TRANSFERT-TRANSAC-CONVENTION')

						SET @dtDateDuJour = GETDATE()

						DECLARE curRIO_Sans_IQEE CURSOR LOCAL FAST_FORWARD FOR
							SELECT DISTINCT R.iID_Convention_Source, R.iID_Unite_Source
											,R.OperTypeID -- FT1
							FROM tblOPER_OperationsRIO R
							WHERE R.bRIO_Annulee = 0
							  AND R.bRIO_QuiAnnule = 0
							  AND R.dtDate_Enregistrement = (SELECT MIN(R2.dtDate_Enregistrement)
															 FROM tblOPER_OperationsRIO R2
															 WHERE R2.iID_Convention_Source = R.iID_Convention_Source AND
																   R2.bRIO_Annulee = 0 AND
																   R2.bRIO_QuiAnnule = 0)
							  -- qui ont un solde transférable par le RIO...
							  AND 0 < (SELECT ISNULL(SUM(OC.ConventionOperAmount),0)
										FROM dbo.Un_ConventionOper OC
										WHERE OC.ConventionID = R.iID_Convention_Source
										  AND (CHARINDEX(OC.ConventionOperTypeID,@vcRIO_TRANSFERT_TRANSAC_CONVENTION) > 0))
							  -- qui n'ont pas de compte en perte
							  AND NOT EXISTS (SELECT CO.ConventionOperTypeID,SUM(CO.ConventionOperAmount)
											  FROM Un_ConventionOper CO
											  WHERE CO.ConventionID = R.iID_Convention_Source
												AND (CHARINDEX(CO.ConventionOperTypeID,@vcRIO_TRANSFERT_TRANSAC_CONVENTION) > 0)
											  GROUP BY CO.ConventionOperTypeID
											  HAVING SUM(CO.ConventionOperAmount) < 0)

						OPEN curRIO_Sans_IQEE
						FETCH NEXT FROM curRIO_Sans_IQEE INTO @iID_Convention_Source, @iID_Unite_Source
																,@OperTypeID -- FT1
						WHILE @@FETCH_STATUS = 0
							BEGIN
							
								EXECUTE [dbo].[psOPER_CreerOperationRIOTemp] @iConnectId
																		,@iID_Convention_Source
																		,@iID_Unite_Source
																		,@dtDateDuJour
																		,@dtDateDuJour
																		,NULL
																		,@OperTypeID
																		,1
																		,1
																		,1
																		,@vcCode_Message
																		
								FETCH NEXT FROM curRIO_Sans_IQEE INTO @iID_Convention_Source, @iID_Unite_Source
																		,@OperTypeID -- FT1
							END
						CLOSE curRIO_Sans_IQEE
						DEALLOCATE curRIO_Sans_IQEE
						
						IF @@TRANCOUNT > 0
							COMMIT TRANSACTION
					END TRY
					BEGIN CATCH
						IF @@TRANCOUNT > 0
							ROLLBACK TRANSACTION
					END CATCH
				END
			-------------------------------------------
			-- FIN MODIFICATION DU 2009-12-17
			-------------------------------------------


			--------------------
			COMMIT TRANSACTION		
			--------------------

			SET @iStatut = 0
		END TRY
		BEGIN CATCH
			-- RÉCUPÉRATION DES INFORMATIONS CONCERNANT L'ERREUR
			SELECT										
					@vErrmsg		= REPLACE(ERROR_MESSAGE(),'%',' '),
					@iErrState		= ERROR_STATE(),
					@iErrSeverity	= ERROR_SEVERITY(),
					@iErrno			= ERROR_NUMBER();

			-- LA TRANSACTION EST TOUJOURS ACTIVE, ON PEUT FAIRE UN ROLLBACK
			IF (XACT_STATE()) = -1	
				BEGIN
					-----------------------
					ROLLBACK TRANSACTION
					-----------------------						
				END

			-- CONCATÉNATION DU NUMÉRO D'ERREUR INTERNE À SQL SERVEUR
			SET @vErrmsg = CAST(@iErrno AS VARCHAR(6)) + ' : ' + @vErrmsg
			RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState) WITH LOG

			SET @iStatut = -6
		END CATCH

		-- RÉACTIVATION DU TRIGGER
		--ALTER TABLE dbo.Un_ConventionOper	ENABLE TRIGGER TUn_ConventionOper
		--ALTER TABLE dbo.Un_Oper				ENABLE TRIGGER TUn_Oper
		--ALTER TABLE dbo.Un_Oper				ENABLE TRIGGER TUn_Oper_dtFirstDeposit
		
		Delete #DisableTrigger where vcTriggerName = 'TUn_ConventionOper'
		Delete #DisableTrigger where vcTriggerName = 'TUn_Oper'
		Delete #DisableTrigger where vcTriggerName = 'TUn_Oper_dtFirstDeposit'

		RETURN @iStatut
		*/
	END