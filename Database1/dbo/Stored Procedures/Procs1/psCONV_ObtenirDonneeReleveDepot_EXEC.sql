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
Code de service		:		psCONV_ObtenirDonneeReleveDepot_EXEC
Nom du service		:		Obtenir toutes les données nécessaire pour l'impression du relevé de dépôt    
But					:		Récupérer toutes les données nécessaire pour l'impression du relevé de dépôt
Facette				:		P171U
Reférence			:		Relevé de dépôt

Parametres d'entrée :	Parametres					Description                                 Obligatoire
                        ----------                  ----------------                            --------------                       
                        dtDateDebut                 Date début du relevé de dépôt               Non
						dtDateFin                   Date fin du relevé de dépôt                 Oui
                        iSubscriberID               Identifiant unique du souscripteur          Non
                        @bIsSave                    Indique si on doit sauvegarder les données
                                                    dans une table physique


Exemple d'appel:
		EXECUTE dbo.psCONV_ObtenirDonneeReleveDepot_EXEC '2010-01-01','2010-12-31',431902,1,1,-1

Parametres de sortie :  Table						Champs										Description
					    -----------------			---------------------------					--------------------------

Historique des modifications :

						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2008-12-05					Fatiha Araar							Création de la fonction 
                        2009-01-27                  Fatiha Araar                            Corrcection 
                        2009-02-03                  Fatiha Araar                            Ajouter les montants IQEE         
						2009-03-13					Dan Trifan								Diviser le traitement en 2 parties : _Prep et _EXEC
																							pour implanter le traitement en plusieurs soustraitements parallèles
						2009-04-20					Jean-François Gauthier					Ajout du champ vcNASBenef lors de l'obtention des infos du bénéficiaire
																							Ajout des champs non précisés lors des instructions INSERT où ils manquaient
						2009-04-23					Jean-François Gauthier					Insertion du nombre de paiement dans @iPmtByYearID lors que ce dernier est NULL
																							Initialise de @iPmtByYearID à 1 lorsqu'égal à 2
						2009-04-24					Jean-François Gauthier					Ajout du DELETE supprimant les valeurs à zéro pour les lignes de type = 'D'
						2009-04-26					Dan Trifan								Optimisation
						2009-04-28					Jean-François Gauthier					Modification pour remplacer l'appel à la fonction fnCONV_ObtenirAnneeQualification
																							et pour intégre les règles suivantes :
																								- Si convention Universitas => Année de qualification = Date de naissance + 19
																								- Si convention Reflex => Année de qualification = Date de naissance + 18
																								- Si plus d'une convention => Il faut prendre l'année de qualification la plus "rapprochée" (donc + 18).
						2009-06-22					Jean-François Gauthier					Modification afin d'établir le solde de l'année précédente au 31 décembre et non au 30 juin
						2009-09-14					Jean-François Gauthier					Ajout de la variable @mMntIQEEMaj 												
						2009-09-29					Jean-François Gauthier					Ajout du traitement pour remplir la date tblCONV_DonneeReleveDepotAvecDetailParUnite
																							nécessaire à l'estimation des montants versés futurs 
																							Ajout du nombre de groupe d'unité dans la table tblCONV_DonneeReleveDe^pot (c.f. @iNbGroupeUniteConvention)
						2009-10-01					Jean-François Gauthier					Ajout du critére de date de début et date de fin sur les cotisations dans le calcul du montant théorique mensuel
						2009-10-06					Jean-François Gauthier					Modification de la date de début lors du traitement par unité afin que celle-ci prenne toutes les conventions (1900-01-01)
						2009-10-09					Jean-François Gauthier					Modification afin de passe la date de début du relevé lors de calcul du montant théorique mensuel par unité
						2009-10-16					Jean-François Gauthier					Ajout de la variable @mFraisCotisationTotal afin d'avoir le montant total des frais / cotisations pour la convention.
																							Ce montant sert ensuite à effectuer le prorata du montant IQEE versé depuis le 2007-02-21	
						2009-10-20					Jean-François Gauthier					Correction d'un problème de calcul du montant théorique mensuel pour les calculs de projection
																							Ajout de validation pour contourner les divisions par zéro éventuelles
						2009-10-23					Jean-François Gauthier					Ajout des 4 champs :dDiffMoisIQEE
																												dDiffMoisSCEE
																												bEntreeVigueurIQEE
																												bEntreeVigueurSCEE
																							Ajout du traitement pour remplir ces 4 champs
						2009-10-28					Jean-François Gauthier					Modification du calcul du différenciel de mois 
						2009-10-29					Jean-François Gauthier					Correction d'un bug avec le calcul du montant théorique mensuel pour certains souscripteurs
						2009-11-03					Jean-François Gauthier					Modification afin d'avoir les montants IQEE pour le sommaire (depuis le début) et pour le détails (période du relevé)
						2009-11-05					Jean-François Gauthier					Ajout du champ dtEcheance																	
						2009-11-16					Jean-François Gauthier					Ajout de dtReleveDepot lors de l'extraction des valeurs @bPrincipalResponsableManquant et @bPrincipalResponsableErreur
						2009-11-17					Jean-François Gauthier					Ajout des lignes PRJ (pour les projections) via une union
						2009-11-27					Jean-François Gauthier					Modification pour aller chercher les cotisations non encore effectuée pour le calcul de la projection
						2009-12-01					Jean-François Gauthier					Modification pour l'obtention du nombre de paiement et du nombre de paiement par année sur les lignes 'PRJ'
						2010-01-07					Jean-François Gauthier					Modification pour retourner le champ bSouscripteur_Desire_Releve_Elect
						2010-02-08					Jean-François Gauthier					Remplacement de fntIQEE_ObtenirIQEE par fntOPER_ObtenirMntIQEERelDep
						2010-03-01					Jean-François Gauthier					Élimination des lignes BEC dans le calcul de la projection
						2010-03-10					Jean-François Gauthier					Ajout du souscripteur dans la validation de l'âge de qualification
						2010-03-12					Jean-François Gauthier					Modification afin TOUJOURS afficher les frais sur la ligne sommaire
																							pour les conventions individuelles de type I,T,F
																							Modification de l'appel à fntOPER_ObtenirCotisationFraisConvention
						2010-03-15					Jean-François Gauthier					Modification pour la gestion des frais de 200 $ pour les convention T de plus de 12 mois
						2010-03-31					Jean-François Gauthier					Modification afin d'éviter une division par zéro potentielle lors du calcul du montant théorique mensuel
						2010-04-08					Jean-François Gauthier					Correctif pour le calcul de l'âge de qualification quand le SubscriberID est NULL, on utilise le iIDSouscripteur
						2010-05-21					Jean-François Gauthier					Exclusion des 'TFR', 'TIN', 'OUT' dans le calcul des projections
						2010-05-28					Jean-François Gauthier					Ajout de la valeur dans le champ dtDateFinGeneration
						2010-06-01					Jean-François Gauthier					Rajout des 'TFR', 'TIN', 'OUT' dans le calcul des projections
						2010-06-04					Jean-François Gauthier					Modification concernant la mise à jour du champ dtDateFinGeneration
						2010-07-09					Jean-François Gauthier					Ajout du calcul des intérêts sur les transactions BNA
						2010-07-15					Jean-François Gauthier					Modification de l'appel à fnCONV_ObtenirBourse qui doit maintenant avoir la date de fin
																							en paramètre
																							Élimination du calcul sur les intérêts du BNA
						2010-10-07					Jean-Francois Arial						Enlever une condition au niveau de la vérification sur le 2500 annuel
						2011-02-28					Jean-François Gauthier					Gestion des montants IQEE sur la ligne PAE (mMntIQEEPae et mMntIntIQEEPae)
						2011-03-04					Jean-François Gauthier					Ajout des montants IQEE liés à des RIO
						2011-03-08					Jean-François Gauthier					Création d'un montant PCEE_TIN juste pour le sommaire
						2011-03-11					Jean-François Gauthier					Correction du calcul du montant PCEE_TIN
						2011-03-15					Jean-François Gauthier					Modification afin de ne pas considérer les conventions fermées dans le calcul de l'année de qualification
						2011-03-18					Jean-François Gauthier					Modification afin de ne pas inclure les intérêts des transferts RIO dans les revenus annuels de l'IQEE
						2011-03-21					Jean-François Gauthier					Élimination du montant PAE (RIO) dans le montant IQEE			
						2011-03-29					Jean-François Gauthier					Correction pour les calculs des montants IQEE qui se retrouvent sur la ligne de bonification gouvernementale
						2011-03-31					Jean-François Gauthier					Élimination des montants IQEE sur les lignes TFR du régime individuel 
																							Souscription du montant IQEE TIN de la ligne REV	
						2011-04-01					Jean-François Gauthier					Correction pour les autres revenus 				
						2011-06-23					Corentin Menthonnex						Prise en charge de la date de début (on enlève la date @dtDateFinSomaire pour la remplacer par @dtDateDebut)
																							Modification de la récupération des valeurs de vcDerniereAnnee
																							Correction de l'affichage des intérêts "Autre revenus" pour RIM
						2011-07-12					Frederick Thibault						Correction de la répartition de certains montants (FT1)
						2011-08-09					Frederick Thibault						Modification de l'âge de qualif des régimes Universitas et REEEFlex pour 17 ans
						2011-12-07					Radu Trandafir							Corrections sur la date de debut pour les soldes initiaux
						2011-12-09                  Mbaye Diakhate                          Ajout de la variable @mIntPCEETINDiffere pour les interêts TIN dont le transfert est anti-daté (effectiveDate < OperDate)						
                        2011-12-14                  Mbaye Diakhate							Commentaire du code:
					                                                                            -Traitement basé sur une unité regroupé
																									>>T1: RECHERCHE DU NUMERO DE LA CONVENTION
																									>>T2: CALCUL DES COTISATIONS ET FRAIS LA CONVENTION
																										  -fntOPER_ObtenirCotisationFraisConvention
																									>>T3: CALCUL DES MONTANTS DES INCITATIFS
																										  -fntPCEE_ObtenirSubventionSIBons
																									>>T4: RECHERCHE DES INFORMATIONS SUR LA CONVENTION, LE SOUCRIPTEUR ET LE REPRESENTANT
																										  - fntCONV_ObtenirUnitesConvention
																										  - fntCONV_ObtenirDonneeCiviqueHumain
																										  - fnGENE_ObtenirCoutEtude
																										  -	fnCONV_ObtenirBourse
																										  -	fnCONV_ObtenirMontantSouscritConvention
																									>>T5: CALCUL DES DES SOLDES INITIAL DES INTERETS DES INCITATIFS
																											-fntOPER_ObtenirMontantConvention
																											-fntOPER_ObtenirMontantConventionTINDiffere
																									>>T6: CALCUL POUR LES PROJECTIONS
																									>>T7: RECHERCHE DES INFORMATIONS DU BENEFICIAIRE
																											-fntCONV_ObtenirDonneeCiviqueHumain
																									>>T8: CALCUL IQEE
																											-fntOPER_ObtenirMntIQEERelDep
																											-fntOPER_ObtenirOperationsCategorie
																									>>T9: INSERTION DES DONNEES RELEVES DEPOTS
																											-fntOPER_ObtenirMontantConvention
																											-fntOPER_ObtenirOperationsCategorie
																											-fntOPER_ObtenirMontantConvention
																											-fntCONV_ObtenirReleveDepotDetails
																											-fnCONV_ObtenirMontantSouscritConvention																									
																											-fntOPER_ObtenirMntIQEERelDep
																								-Traitement basé sur un groupe d'unité
						                                                                                 <<T10:DETAILS DE LA CONVENTION PAR GROUPE D'UNITÉS
																											-fntOPER_ObtenirCotisationFraisConvention
																											-fntCONV_ObtenirReleveDepotDetailsAvecGroupeUnite
																											-fntCONV_ObtenirDatesConvention
																											-fnCONV_ObtenirMontantSouscritConvention
																											-fnCONV_ObtenirMontantTheoriqueMensuel
																											-fntOPER_ObtenirMntIQEERelDep
																											-fntCONV_ObtenirReleveDepotDetails
						2013-02-12					Pierre-Luc Simard							Modification a l'appel de la fonction fnCONV_ObtenirBourse
						2013-03-19					Pierre-Luc Simard							Appel de fntOPER_ObtenirMntIQEERelDep en date du PAE au lieu de prendre le montant annuel
                        2015-12-01                  Steeve Picard                               Utilisation de la nouvelle fonction «fntCONV_ObtenirStatutConventionEnDate_PourTous»
                        2017-09-27                  Pierre-Luc Simard                           Deprecated - Cette procédure n'est plus utilisée

 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_ObtenirDonneeReleveDepot_EXEC]
@dtDateDebut datetime, @dtDateFin datetime, @iSubscriberID int, @bIsSave bit, @inbProcesses int, @iNoprocess int
WITH EXEC AS CALLER
AS
BEGIN
	
    SELECT 1/0
    /*
	BEGIN TRY

	IF @iSubscriberID =  -1
		SET @iSubscriberID =  NULL

	IF @bIsSave IS NULL
		SET @bIsSave =  0


	-- Vérifie si on doit générer des données
	IF @bIsSave = 1 
		BEGIN
		
		-- Déclaration des variables
		DECLARE @iIDConvention					INT,
		        @iIDSouscripteur				INT,
		        @iIDBeneficiaire				INT,
		        @vcNumeroConvention				VARCHAR(20),
		        @mFraisCotisation				MONEY,
				@mFrais							MONEY,
				@mSCEE							MONEY,
		        @mIntSCEE						MONEY,
				@mSCEESup						MONEY,
		        @mIntSCEESup					MONEY,
				@mBEC							MONEY,
				@mIntBEC						MONEY,
				@mPAE							MONEY,
				@mIntPAE						MONEY,
				@mAutreRev						MONEY,
				@mIntAutreRev					MONEY,
				@mIntAutreRevTINDiffere         MONEY, -- 2010-12-09: Mbaye Diakhate - Calcul des interets TIN dans le cas de transfert anti-daté (effectiveDate < OperDate)
				@mIntPCEETIN					MONEY,
				@mMntTheoMens					MONEY,
				@vcAnneeQualif					INT,
				@mBourse						MONEY,
				@mMntSouscrit					MONEY,
				@dtEntreeVigueur				DATETIME,
				@dtRembEstime					DATETIME,
				@dtFinCotisation				DATETIME,
				@dtFinRegime					DATETIME,
				@vcPrenomRep					VARCHAR(100),
				@vcNomRep						VARCHAR(100),
				@vcTelRep						VARCHAR(20),
				@vcPrenomDir					VARCHAR(100),
				@vcNomDir						VARCHAR(100),
				@vcTelDir						VARCHAR(20),
		        @mCoutEtude						MONEY,
			    @vcPrenomSouscripteur			VARCHAR(100),
				@vcNomSouscripteur				VARCHAR(100),
				@vcAdresseSouscripteur			VARCHAR(200),
				@vcVilleSouscripteur			VARCHAR(100),
				@vcCodePostalSouscripteur		VARCHAR(20),
				@cSexeSouscripteur				CHAR(1),
		        @vcPaysSouscripteur				VARCHAR(50),
				@vcPrenomBeneficiaire			VARCHAR(100),
				@vcNomBeneficiaire				VARCHAR(100),
		        @iQuantiteUnite					MONEY,
				@vcRegime						VARCHAR(50),
		        @iIDRegime						VARCHAR(3),
		        @vcNomEtat						VARCHAR(3),
		        @mMntIQEE						MONEY,
		        @mMntIntIQEE					MONEY,
		        @vcLangue						VARCHAR(50),
		        @vcTextDiploma					VARCHAR(150),
		        @vcDerniereAnnee				VARCHAR(4),
		        @vcAvantDerniereAnnee			VARCHAR(50),
		        --@iAnneeEtudeMax					INT,		-- - 2010-25 - CM : n'est plus nécessaire.
		        @vcParamDateBourse				VARCHAR(5),		-- + 2010-25 - CM : Valeur du paramètre récupéré
		        @iDerniereAnnee					INT,			-- + 2010-25 - CM : Dernière année des trois dates de projection pour le calcul des bourses.
		        @dtDateVigueurProjection		DATETIME,		-- + 2010-25 - CM : Date de mise en vigueur des nouvelles projections de bourse
		        @vcCourrielSouscripteur			VARCHAR(100),
		        @vcTypeContact					VARCHAR(3),
		        --@dtDateFinSomaire				DATETIME,		-- Represente la date de fin pour le somaire du rapport
				@dtDateCalcul					DATETIME,
				@iNbEnreg						INT,
				@hTime							VARCHAR(18),
				@dtStartBatch					DATETIME,
				@itmpID							INT,
				@bPrincipalResponsableErreur	BIT,
				@bPrincipalResponsableManquant	BIT,
				@iNbRecFrom						INT,
				@iNbRecTo						INT,
				@iPmtByYearID					INT,
				@vcNASBenef						VARCHAR(75),
				@mMntIQEEMaj					MONEY,
				@mMntIQEECdb					MONEY,
				@iNbGroupeUniteConvention		INT,
				@mFraisCotisationTotal			MONEY,
				@dtDateEntreeVigueurIQEE		DATETIME,
				@dtDateEntreeVigueurSCEE		DATETIME,
				@mMntSomIQEE					MONEY,
				@mMntSomIntIQEE					MONEY,
				@mMntSomIQEEMaj					MONEY,
				@mMntSomIQEECdb					MONEY,
				@dtEcheance						DATETIME,
				@mFraisCotisationTotalPrj		MONEY,
				@mMntTheoMensPrj				MONEY,
				@iPmtByYearIDPrj				INT,
				@bSouscripteur_Desire_Releve_Elect BIT,
				@vcConventionNo					VARCHAR(15),
				@mIntPCEETIN_ITR				MONEY,
				@mIntIQEETIN					MONEY -- recuperer l'interet IQEE pour le TIN cas Trainor Blaine
		
		SET NOCOUNT ON

		-- Récupérer les dates d'entrée en vigueur des programmes IQEE et SCEE
		SELECT
			@dtDateEntreeVigueurIQEE	= '2007-02-21'
			,@dtDateEntreeVigueurSCEE	= '1998-01-01'

		-- - 2010-25 : CM : On n'utilise plus cette variable mais directement la date de début @dtDateDebut
		-- Initialisation de la date de fin pour le sommaire du rapport
		--SET @dtDateFinSomaire = CAST(CAST(YEAR(DATEADD(YEAR,-1,@dtDateFin)) as varchar) +  '-12-31' as datetime)
		SELECT @dtDateDebut  = isnull(@dtDateDebut,'1900-01-01')

		SET @dtDateCalcul = getdate()
		
		IF @iNoprocess <> -1
			BEGIN	
			
			SELECT @iNbRecFrom =  (@iNoprocess-1)*FLOOR(count(*)/@inbProcesses)+1 ,
				   @iNbRecTo = (@iNoprocess)*FLOOR(count(*)/@inbProcesses) 
					from tblCONV_TMPRelDep 
			
			Insert into tblCONV_MessagesDonneeReleveDepot (dtDtTime,vfacette,vmodule,vmess)
			
			select getdate(),'CONV','Calcul relevé de depôt', 'Start ObtenirDonneeReleveDepot_EXEC - procès no: ' + CAST (@iNoprocess as varchar(10)) +
			' Du enreg. no.: ' + CAST (@iNbRecFrom as varchar(10)) +
			' À  enreg. no.: ' + CAST (@iNbRecTo as varchar(10))
			
		END
		
		SELECT  @iNbEnreg = 1, @hTime = '', @dtStartBatch = getdate()

		WHILE @iNbEnreg > 0
			BEGIN

			SELECT  @iNbEnreg = 0, @hTime = '', @dtStartBatch = getdate()

			-- Creation du curseur

			DECLARE crDepositStattement CURSOR FORWARD_ONLY   FOR
			
			SELECT 
					   V.iID,
					   V.ConventionID,
					   V.SubscriberID ,
					   V.BeneficiaryID ,
					   V.ConventionNo,
					   V.PlanDesc,
					   V.PlantypeID,
					   V.TextDiploma,
					   V.bSouscripteur_Desire_Releve_Elect
			FROM tblCONV_TMPRelDep V
			WHERE	PROCESSED = 0
			AND		(iID >= @iNbRecFrom 
			          --mbaye pour prendre le cas de nombre impaire
			          --and iID <= @iNbRecTo 
			           AND iID <=  CASE WHEN @iNoprocess = 10 THEN @iNbRecTo +1
				                          ELSE @iNbRecTo END
			          OR @iNoprocess = -1)
	 
			OPEN crDepositStattement

			FETCH NEXT FROM crDepositStattement INTO @itmpID
													,@iIDConvention
													,@iIDSouscripteur
													,@iIDBeneficiaire
													,@vcNumeroConvention
													,@vcRegime
													,@iIDRegime
													,@vcTextDiploma
													,@bSouscripteur_Desire_Releve_Elect

			WHILE @@FETCH_STATUS = 0
				BEGIN
				
-- ********************** DÉBUT DU TRAITEMENT BASÉ SUR LES CONVENTIONS (UNITÉS REGROUPÉES) ************************

					-->>T1: RECHERCHE DU NUMERO DE LA CONVENTION
					SELECT
						@vcConventionNo = c.ConventionNo
					FROM
						dbo.Un_Convention c
					WHERE
						c.ConventionID = @iIDConvention
					--<<T1
					
					-->>T2: CALCUL DES COTISATIONS ET FRAIS LA CONVENTION
					-- 2010-03-12 : JFG Modification pour toujours afficher les frais
					--					sur la ligne de sommaire dans les cas des conventions individuelles
					--					de type I, F, T
					
					IF UPPER(LEFT(CAST(@vcConventionNo AS VARCHAR(15)),1)) IN ('I','F','T') -- SI LA CONVENTION COMMENCE PAR I, F, OU T, IL CALCULE DES FRAIS ET COTISATION SEPAREREMENT
						BEGIN   
							SELECT 
								@mFrais = ISNULL(mfrais,0)
							FROM 
								dbo.fntOPER_ObtenirCotisationFraisConvention(@iIDConvention,NULL,NULL,@dtDateFin,'E',NULL,'S')
							SELECT 
								@mFraisCotisation = SUM(ISNULL(mCotisation,0))+ @mFrais
							FROM 
								-- Radu Trandafir
								--dbo.fntOPER_ObtenirCotisationFraisConvention(@iIDConvention,NULL,NULL,@dtDateDebut,'E',NULL,'S')
								dbo.fntOPER_ObtenirCotisationFraisConvention(@iIDConvention,NULL,NULL,DATEADD(dd, -1, @dtDateDebut),'E',NULL,'S')								
						END
						
					--ELSE IF UPPER(LEFT(CAST(@vcConventionNo AS VARCHAR(15)),1)) = 'T'  
					--BEGIN
					--END
					ELSE -- SINON IL CALCULE ENSEMBLE LES COTISATIONS  ET FRAIS ENSUITE 
					                        
						BEGIN
							SELECT 
								@mFraisCotisation = SUM(ISNULL(mCotisation,0))+ SUM(ISNULL(mfrais,0)),
								@mFrais = SUM(ISNULL(mfrais,0))
							FROM 
								--dbo.fntOPER_ObtenirCotisationFraisConvention(@iIDConvention,NULL,NULL,@dtDateDebut,'E',NULL,'S')
								dbo.fntOPER_ObtenirCotisationFraisConvention(@iIDConvention,NULL,NULL,DATEADD(dd, -1, @dtDateDebut),'E',NULL,'S')								
						END
						
					SELECT	-- EVITE LES VALEURS NULLES
							@mFraisCotisation = ISNULL(@mFraisCotisation,0), 
							@mFrais = ISNULL(@mFrais,0)
                     --<<T2: 
							
                    -->>T3: CALCUL DES MONTANTS DES INCITATIFS
					-- Montants des subventions
					SELECT 
						   @mSCEE		= SUM(fCESG + fCESGINT),
						   --Radu Trandafir  
						   --@mSCEE		= SUM(fCESG), 
						   --@mSCEESup	= SUM(fACESG + fACESGINT),
						   --Radu Trandafir 
						   @mSCEESup	= SUM(fACESG), 
						   @mBEC		= SUM(fCLB)
					--FROM fntPCEE_ObtenirSubventionBons (@iIDConvention,NULL,@dtDateDebut)
					--Radu Trandafir
					--FROM fntPCEE_ObtenirSubventionSIBons (@iIDConvention,NULL,@dtDateDebut)
					FROM fntPCEE_ObtenirSubventionSIBons (@iIDConvention,NULL,DATEADD(dd, -1, @dtDateDebut))

					SELECT 
						@mSCEE		= ISNULL(@mSCEE,0)
						,@mSCEESup  = ISNULL(@mSCEESup,0)
						,@mBEC		= ISNULL(@mBEC,0)
                     --<<T3
					 
					 -->>T4: CALCUL INFORMATION SUR LA CONVENTION ET LE BENEFICIAIRE
					-- Année de qualification
					-- SELECT @vcAnneeQualif = dbo.fnCONV_ObtenirAnneeQualification (@iIDConvention,@dtDateFin)
					IF @iIDConvention IS NOT NULL AND @dtDateFin IS NOT NULL
					    BEGIN
							SELECT 
								@vcAnneeQualif = ISNULL((YEAR(hb.BirthDate)+ ml.Multiplicateur),c.YearQualif)
							FROM 
								dbo.Un_convention c
								INNER JOIN dbo.Un_plan p ON p.PlanID = c.PlanID
							    INNER JOIN dbo.Mo_Human hb ON hb.HumanID = c.BeneficiaryID
								INNER JOIN
								(
									SELECT
										uh.HumanId, 
										CASE WHEN (SELECT COUNT(*) 
													 FROM	dbo.Un_convention cr 
                                                            INNER JOIN  dbo.Un_plan pr ON pr.PlanID = cr.PlanID 
                                                            INNER JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(@dtDateFin, NULL) s ON s.conventionID = cr.ConventionID
													 WHERE	
														cr.BeneficiaryID = uh.HumanID AND pr.PlanDesc = 'Reeeflex' AND cr.SubscriberID = @iIDSouscripteur
														AND s.ConventionStateID <> 'FRM'
												   ) > 0 THEN 17  -- dès qu'on a un Reflex
											 ELSE 17
										END AS Multiplicateur
									FROM 
										dbo.Un_convention uc
										INNER JOIN dbo.Un_plan up ON up.PlanID = uc.PlanID
										INNER JOIN  dbo.Mo_Human uh ON uh.HumanID = uc.BeneficiaryID
									GROUP BY
										uh.HumanId
								) AS ml
									ON ml.HumanId = hb.HumanId
							WHERE 
								c.ConventionID = @iIDConvention
								
							--l'année de qualification ne peut pas être antérieur à l'année du relevé plus un an
							IF @vcAnneeQualif < YEAR(@dtDateFin) + 1
								SET @vcAnneeQualif = YEAR(@dtDateFin) + 1
						END
					ELSE
						BEGIN
							SET @vcAnneeQualif = -1
						END
					
					-- Le nombre total d'unités
					SELECT @iQuantiteUnite			 = SUM(uc.UnitQty) FROM dbo.fntCONV_ObtenirUnitesConvention(@iIDConvention,NULL,@dtDateFin) uc
					
					-- le nombre de groupe d'unités
					SELECT @iNbGroupeUniteConvention = ISNULL(COUNT(uc.UnitID),0) FROM  dbo.fntCONV_ObtenirUnitesConvention(@iIDConvention, NULL, @dtDateFin) uc
	
					-- Informations du souscripteur
					SELECT @vcPrenomSouscripteur = vcPrenom,
						   @vcNomSouscripteur = vcNom,
						   @vcAdresseSouscripteur = vcAdresse,
						   @vcVilleSouscripteur = vcVille,
						   @vcCodePostalSouscripteur = vcCodePostal,
						   @vcPaysSouscripteur = vcPays,
						   @vcNomEtat = vcProvince,
						   @vcLangue = vcLangue,
						   @vcCourrielSouscripteur = vcCourriel,
						   @cSexeSouscripteur = cSexe
					  FROM 
							dbo.fntCONV_ObtenirDonneeCiviqueHumain(@iIDSouscripteur)

					SET @vcTypeContact = (	SELECT isnull(PS.vcCode_Preference_Suivi,'P')
											FROM 
												dbo.un_subscriber S
												 LEFT OUTER JOIN dbo.tblCONV_preferencesuivi PS 
													ON PS.iID_Preference_Suivi=S.iID_Preference_Suivi
											WHERE 
												subscriberID=@iIDSouscripteur)

					-- Le cout des études
					SELECT @mCoutEtude = dbo.fnGENE_ObtenirCoutEtude(@vcNomEtat,@vcAnneeQualif)

					-- Bourse
					SELECT @mBourse = dbo.fnCONV_ObtenirBourse (@iIDConvention,@iQuantiteUnite)

					-- Montant Souscrit
					SELECT @mMntSouscrit = dbo.fnCONV_ObtenirMontantSouscritConvention (@iIDConvention,NULL,@dtDateFin)
					
					--2010-03-12 : JFG : 
					DECLARE 
						@dtMinOperDate					DATETIME
						,@iNb_Mois_Avant_RIN_Apres_RIO	INT
						
					SELECT @iNb_Mois_Avant_RIN_Apres_RIO = iNb_Mois_Avant_RIN_Apres_RIO FROM dbo.Un_Def
						
					SELECT
						@dtMinOperDate = MIN(U.InForceDate)
					FROM
						dbo.Un_Unit U
					WHERE
						U.ConventionID = @iIDConvention
				
					SELECT 
						@iNb_Mois_Avant_RIN_Apres_RIO = iNb_Mois_Avant_RIN_Apres_RIO 
					FROM 
						dbo.Un_Def
					
					IF UPPER(LEFT(CAST(@vcConventionNo AS VARCHAR(15)),1)) = 'T'
						BEGIN
							IF DATEDIFF(mm,@dtMinOperDate, @dtDateFin) > @iNb_Mois_Avant_RIN_Apres_RIO
								BEGIN
									SET @mMntSouscrit = @mMntSouscrit + 200
									SET @mFraisCotisation = @mFraisCotisation + 200 
								END
							--ELSE
							--	BEGIN
							--		SET @mMntSouscrit = @mMntSouscrit + @mFrais
									--SET @mFraisCotisation = @mFraisCotisation + (SELECT ISNULL(mfrais,0) FROM dbo.fntOPER_ObtenirCotisationFraisConvention(@iIDConvention,NULL,NULL,@dtDateFin,'E',NULL,'D'))
									--SET @mMntSouscrit = @mMntSouscrit + (SELECT ISNULL(mfrais,0) FROM dbo.fntOPER_ObtenirCotisationFraisConvention(@iIDConvention,NULL,NULL,@dtDateFin,'E',NULL,'D'))
							--	END
						END		
		
					-- Dates de conventions
					SELECT 
						   @dtEntreeVigueur = MIN(dtEntreeVigueur),		-- DU GROUPE D'UNITÉS
						   @dtEcheance		= MAX(dtEcheance),
						   @dtRembEstime	= MAX(dtRembEstime),
						   @dtFinCotisation = MAX(dtFinCotisation),
						   @dtFinRegime		= MAX(dtFinRegime)
					FROM dbo.fntCONV_ObtenirDatesConvention (@iIDConvention,@dtDateFin)

					-- Informations du representant et directeur
					SELECT @vcPrenomRep  = vcPrenomRep,
						   @vcNomRep = vcNomRep,
						   @vcTelRep = vcTelRep,
						   @vcPrenomDir = vcPrenomDir,
						   @vcNomDir  = vcNomDir,
						   @vcTelDir  = vcTelDir
					  FROM dbo.fntCONV_ObtenirRepresentantSouscripteur (@iIDConvention)
					 
				--<<T4
				
			    -->>T5: CALCUL DES SOLDES INITIAL DES INTERETS DES INCITATIFS
					-- Montant des intérêts BNA : 2010-07-09 : Ajout : JFG 
					--SELECT @mIntBNA = SUM(ISNULL(conventionOperAmount,0)) 
					--  FROM fntOPER_ObtenirMontantConvention(@iIDConvention,NULL,@dtDateFinSomaire,'INT_BNA')
 
					-- Montant des intrêts SCEE et SCEE+
					SELECT @mIntSCEE = SUM(ISNULL(f.conventionOperAmount,0))  
					  --Radu Trandafir
					  --FROM fntOPER_ObtenirMontantConvention(@iIDConvention,NULL,@dtDateDebut,'INT_SCEE') f
					  FROM fntOPER_ObtenirMontantConvention(@iIDConvention,NULL,DATEADD(dd, -1, @dtDateDebut),'INT_SCEE') f
					 WHERE 
						NOT EXISTS(SELECT 1 FROM dbo.Un_CESP c WHERE f.iID_Oper = c.OperID)		-- 2011-03-04 : JFG
										
					-- Montant des intrêts SCEE et SCEE+
					--2011-12-16 MBAYE DIAKHATE: Prendre en compte les interets RIO   dans le calcul des incitatifs
					--SELECT @mIntSCEESup = SUM(ISNULL(conventionOperAmount,0)) 
					--  --FROM fntOPER_ObtenirMontantConvention(@iIDConvention,NULL,@dtDateDebut,'INT_SCEE_SUP') f
					-- FROM fntOPER_ObtenirMontantConvention(@iIDConvention,NULL,DATEADD(dd, -1, @dtDateDebut),'INT_SCEE_SUP') f
					--    WHERE
					--	NOT EXISTS(SELECT 1 FROM dbo.Un_CESP c WHERE f.iID_Oper = c.OperID)		-- 2011-03-04 : JFG
					SELECT @mIntSCEESup = SUM(ISNULL(conventionOperAmount,0)) 
					FROM fntOPER_ObtenirMontantConventionAvecRio(@iIDConvention,NULL,DATEADD(dd, -1, @dtDateDebut),'INT_SCEE_SUP')
					
					-- Montant des intrêts BEC
					SELECT @mIntBEC = SUM(ISNULL(conventionOperAmount,0)) 
					  --FROM fntOPER_ObtenirMontantConvention(@iIDConvention,NULL,@dtDateDebut,'INT_BEC')
					  FROM fntOPER_ObtenirMontantConvention(@iIDConvention,NULL,DATEADD(dd, -1, @dtDateDebut),'INT_BEC')
					SELECT @mIntBEC = ISNULL(@mIntBEC,0)

					-- Montant des intrêts Autre Revenu
					SELECT @mIntAutreRev = SUM(ISNULL(conventionOperAmount,0)) 
					  --FROM fntOPER_ObtenirMontantConvention(@iIDConvention,NULL,@dtDateDebut,'INT_AUTREREV')
					  FROM fntOPER_ObtenirMontantConvention(@iIDConvention,NULL,DATEADD(dd, -1, @dtDateDebut),'INT_AUTREREV')
					SELECT @mIntAutreRev=ISNULL(@mIntAutreRev,0)

					-- 2011-12-09: Mbaye Diakhate - Calcul des interets TIN dans le cas de transfert anti-daté (effectiveDate < OperDate)
					SELECT 
						@mIntAutreRevTINDiffere = ISNULL(SUM(ConventionOperAmount),0) 
					FROM 
						-- fntOPER_ObtenirMontantConventionTINDiffere(@iIDConvention,@dtDateDebut,@dtDateFin);
           fntOPER_ObtenirMontantConventionTINDiffere(@iIDConvention,NULL,DATEADD(dd, -1, @dtDateDebut));

					-- 2011-03-08: JFG
					-- Montant des intrêts PCEE sur TIN
					SELECT @mIntPCEETIN_ITR = ISNULL(SUM(ISNULL(conventionOperAmount,0)),0)
					--FROM fntOPER_ObtenirMontantConvention(@iIDConvention,NULL,@dtDateDebut,'INT_PCEE_TIN_ITR')
					FROM fntOPER_ObtenirMontantConvention(@iIDConvention,NULL,DATEADD(dd, -1, @dtDateDebut),'INT_PCEE_TIN_ITR')

					-- 2011-03-04 : JFG : Modification, car calcul incorrect
					SELECT 	@mIntPCEETIN = ISNULL(SUM(conventionOperAmount),0)
					-- FROM 	fntOPER_ObtenirMontantConvention(@iIdConvention,@dtDateDebut,@dtDateFin,'INT_PCEE_TIN');
          FROM 	fntOPER_ObtenirMontantConvention(@iIdConvention,NULL,DATEADD(dd, -1, @dtDateDebut),'INT_PCEE_TIN');

					SELECT 	@mIntPCEETIN = ISNULL(@mIntPCEETIN + SUM(conventionOperAmount),0)
					 -- FROM 	fntOPER_ObtenirMontantConvention(@iIdConvention,@dtDateDebut,@dtDateFin,'INT_PCEE_TIN_TFR');
           FROM 	fntOPER_ObtenirMontantConvention(@iIdConvention,NULL,DATEADD(dd, -1, @dtDateDebut),'INT_PCEE_TIN_TFR');
					-- Montant PAE
					SELECT @mPAE = SUM(ISNULL(conventionOperAmount,0)) 
					  --FROM fntOPER_ObtenirMontantConvention(@iIDConvention,NULL,@dtDateDebut,'PAE')
					  FROM fntOPER_ObtenirMontantConvention(@iIDConvention,NULL,DATEADD(dd, -1, @dtDateDebut),'PAE')
					SELECT @mPAE = ISNULL(@mPAE,0)

					-- Interets sur le PAE
					SELECT @mIntPAE = SUM(conventionOperAmount)
					  --FROM fntOPER_ObtenirMontantConvention(@iIDConvention,NULL,@dtDateDebut,'INT_PAE')
					  FROM fntOPER_ObtenirMontantConvention(@iIDConvention,NULL,DATEADD(dd, -1, @dtDateDebut),'INT_PAE')
					SELECT @mIntPAE = ISNULL(@mIntPAE,0)
                --<<T5
				
				-->>T6: CALCUL POUR LES PROJECTIONS
					SELECT 
						@mMntTheoMens = SUM(ROUND(M.PmtRate * U.UnitQty, 3)),
						@iPmtByYearID = M.PmtByYearID
					FROM 
						dbo.Un_Unit U 
						INNER JOIN dbo.Un_Modal M 
							ON U . ModalID = M.ModalID
						LEFT OUTER JOIN (
										SELECT	
											U.UnitID,
											CotisationFee = SUM(Ct.Fee + Ct.Cotisation)
										FROM 
											dbo.Un_Unit U
											INNER JOIN Un_Cotisation Ct 
												ON U.UnitID = Ct.UnitID
										WHERE 
											U.ConventionID = @iIDConvention
											AND 
											Ct.EffectDate between @dtDateDebut and @dtDateFin
										GROUP BY 
											U.UnitID
										) Ct ON U.UnitID = Ct.UnitID
					WHERE 
						U.ConventionID = @iIDConvention
						AND 
						ISNULL (Ct.CotisationFee, 0) < M.PmtQty * ROUND (M.PmtRate * U.UnitQty, 3)
					GROUP BY 
						U.ConventionID, M.PmtByYearID

						--CALCUL DES MONTANTS
					SELECT @mMntTheoMens = CASE 
												WHEN @dtFinCotisation <= @dtDateFin THEN 0
												WHEN ISNULL(@mMntTheoMens,0) >  2500 THEN 2500
												ELSE
													ISNULL(@mMntTheoMens,0)
											END

					IF @iPmtByYearID IS NULL
						BEGIN
							SELECT @iPmtByYearID =  m.PmtByYearID
							FROM
								dbo.Un_Modal m
								INNER JOIN
								dbo.Un_Unit u
									ON u.ModalID = m.ModalID
								LEFT OUTER JOIN
								dbo.Un_Cotisation ct
									ON ct.UnitId = u.UnitId 
							WHERE
								u.ConventionID = @iIDConvention
						END

					IF @iPmtByYearID = 2
						SET @iPmtByYearID = 1

					-- 2009-11-17 : POUR LE CALCUL DES PROJECTIONS ****************
					SELECT 
						@mMntTheoMensPrj = SUM(ROUND(M.PmtRate * U.UnitQty, 3)),
						@iPmtByYearIDPrj = M.PmtByYearID
					FROM 
						dbo.Un_Unit U 
						INNER JOIN dbo.Un_Modal M 
							ON U . ModalID = M.ModalID
						LEFT OUTER JOIN (
										SELECT	
											U.UnitID,
											CotisationFee = SUM(Ct.Fee + Ct.Cotisation)
										FROM 
											dbo.Un_Unit U
											INNER JOIN Un_Cotisation Ct 
												ON U.UnitID = Ct.UnitID
										WHERE 
											U.ConventionID = @iIDConvention
											AND 
											-- +/- 2010-25 - CM : Prise en compte des paramètres de date et non pas en dur
											--Ct.EffectDate BETWEEN CAST(CAST(YEAR(@dtDateFin) AS VARCHAR(4))+ '-01-01' AS DATETIME) AND CAST(CAST(YEAR(@dtDateFin) AS VARCHAR(4))+ '-12-31' AS DATETIME)
											Ct.EffectDate BETWEEN @dtDateDebut AND @dtDateFin
										GROUP BY 
											U.UnitID
										) Ct ON U.UnitID = Ct.UnitID
					WHERE 
						U.ConventionID = @iIDConvention
						AND 
						ISNULL (Ct.CotisationFee, 0) < M.PmtQty * ROUND (M.PmtRate * U.UnitQty, 3)
					GROUP BY 
						U.ConventionID, M.PmtByYearID

					SELECT @mMntTheoMensPrj = CASE 
												WHEN @dtFinCotisation <= CAST(CAST(YEAR(@dtDateFin) AS VARCHAR(4))+ '-12-31' AS DATETIME) THEN 0
												WHEN ISNULL(@mMntTheoMensPrj * CAST(@iPmtByYearIDPrj AS NUMERIC(18,10)) , 0) >  2500 THEN (CAST(2500 AS NUMERIC(18,10)) / ISNULL(NULLIF(CAST(@iPmtByYearIDPrj AS NUMERIC(18,10)),0),1))
												ELSE
													ISNULL(@mMntTheoMensPrj,0)
											END

					IF @iPmtByYearIDPrj IS NULL
						BEGIN
							SELECT @iPmtByYearIDPrj =  m.PmtByYearID
							FROM
								dbo.Un_Modal m
								INNER JOIN
								dbo.Un_Unit u
									ON u.ModalID = m.ModalID
								LEFT OUTER JOIN
								dbo.Un_Cotisation ct
									ON ct.UnitId = u.UnitId 
							WHERE
								u.ConventionID = @iIDConvention
						END

					IF @iPmtByYearIDPrj = 2
						SET @iPmtByYearIDPrj = 1
				--<<T6
				
				-->>T7: RECHERCHE DES INFORMATIONS DU BENEFICIAIRE
				   		-- *************************************************************

					-- Information du bénéficaire
					SELECT 
							@vcPrenomBeneficiaire	= vcPrenom,
							@vcNomBeneficiaire		= vcNom,
							@vcNASBenef				= vcNAS
					FROM fntCONV_ObtenirDonneeCiviqueHumain(@iIDBeneficiaire)
                --<<T7
				
				-->>T8: CALCUL IQEE
					-- JFG : 2009-11-03 le montant IQEE doit être calculé en fonction de la période et pour le sommaire
					-- Montants IQEE pour le sommaire pour l'année précédente
					DECLARE 
						@mMntSomIQEEPae		MONEY
						,@mMntIQEEPae		MONEY
						,@mMntIntIQEEPae	MONEY
						
					SELECT 
						--@mMntSomIQEE		= mMntIQEE 
						--,@mMntSomIntIQEE	= mMntIntIQEE 
						-- Lalonde Jocelyne A.
  						@mMntSomIQEE		= mMntIQEE + ISNULL(mMntIQEEPae, 0)
						,@mMntSomIntIQEE	= mMntIntIQEE
						,@mMntSomIQEEMaj	= mMntIQEEMaj
						,@mMntSomIQEECdb	= mMntIQEECdb
						,@mMntSomIQEEPae	= mMntIQEEPae
						,@mMntIntIQEEPae	= mMntIntIQEEPae
					FROM 
						dbo.fntOPER_ObtenirMntIQEERelDep(@iIDConvention, NULL, DATEADD(dd,-1,@dtDateDebut))

					-- Montants IQÉÉ pour la période du relevé
					SELECT 
						@mMntIQEE		= mMntIQEE
						,@mMntIntIQEE	= mMntIntIQEE
						,@mMntIQEEMaj	= mMntIQEEMaj
						,@mMntIQEECdb	= mMntIQEECdb
						,@mMntIQEEPae	= mMntIQEEPae
						,@mMntIntIQEEPae = mMntIntIQEEPae
					FROM 
						dbo.fntOPER_ObtenirMntIQEERelDep(@iIDConvention, @dtDateDebut, @dtDateFin)
				
				    -- recuperer l'interet IQEE pour le TIN
					SELECT 
						@mIntIQEETIN = mMntIntIQEE 
					FROM 
						dbo.fntOPER_ObtenirMntIQEETINRelDep(@iIDConvention, @dtDateDebut, @dtDateFin)
					-- +/- 2010-25 - CM :Récupération de la dernière année pour le calcul des bourses projetés
					-- Derniére année : Année la plus élevé pour laquelle une valeur unitaire a été saisie
					--SELECT @iAnneeEtudeMax = dbo.fnCONV_ObtenirMaxAnneeScolaire()

					-- +/- 2010-25 - CM : Prise en charge des paramètres applicatifs
					--SET @vcDerniereAnnee = CAST( @iAnneeEtudeMax AS CHAR(4))

					-- +/- 2010-25 - CM : Prise en charge des paramètres applicatifs
					-- Avant derniére année et avant avant derniére année pour laquelle une valeur unitaire a été saisie
					--SET @vcAvantDerniereAnnee = CAST( (@iAnneeEtudeMax - 2) AS CHAR(4)) + ', ' + CAST( (@iAnneeEtudeMax - 1) AS CHAR(4))
				
					-- On récupère la date de mise en vigueur des projections pour l'année courante
					SELECT @vcParamDateBourse = dbo.fnGENE_ObtenirParametre('CONV_RDEP_DATE_BOURSE', @dtDateFin, NULL, NULL, NULL, NULL, NULL)
					SET @dtDateVigueurProjection =	CAST(CAST(YEAR(@dtDateFin) AS VARCHAR(4)) + '-' + @vcParamDateBourse AS DATETIME)
					
					-- Calcul de la bonne année en fonction de la date de fin du relevé
					IF @dtDateFin >= @dtDateVigueurProjection
						SET @iDerniereAnnee = YEAR(@dtDateFin)
					ELSE
						SET @iDerniereAnnee = YEAR(@dtDateFin) - 1

					-- On set les années
					SET @vcDerniereAnnee = CAST( @iDerniereAnnee AS CHAR(4))
					SET @vcAvantDerniereAnnee = CAST( (@iDerniereAnnee - 2) AS CHAR(4)) + ', ' + CAST( (@iDerniereAnnee - 1) AS CHAR(4))

					-- Responsable en erreur
					SET @bPrincipalResponsableErreur = ISNULL((SELECT Case When isnull(dtDateReleve,0)=0 then 0 else 1 end
															 FROM dbo.tblCONV_ReleveDepotPrincipalResponsableErreur RDPR
															WHERE RDPR.iIDSouscripteur=@iIDSouscripteur
															  AND RDPR.iIDBeneficiaire=@iIDBeneficiaire AND RDPR.dtdatereleve >= @dtDateFin),0)

					-- responsable manquant
					SET @bPrincipalResponsableManquant = ISNULL((	SELECT Case When isnull(dtDateReleve,0)=0 then 0 else 1 end
																	FROM dbo.tblCONV_ReleveDepotPrincipalResponsableManquant RDPR
																	WHERE RDPR.iIDConvention=@iIDConvention AND RDPR.dtDateReleve >= @dtDateFin ),0)

					-- 2011-03-04 : JFG : Recherche des montants IQEE liés à des RIO pour affichage dans le détail
					DECLARE @tIQEERio TABLE
										(
										 mntIQEERio	MONEY
										,OperDate	DATETIME
										,OperID		INT
										)

					INSERT INTO @tIQEERio
									(
									 mntIQEERio
									,OperDate
									,OperID
									)
					SELECT	 mntIQEERio = SUM(ConventionOperAmount)
							,OP.OperDate
							,OP.OperID
					
					FROM	Un_ConventionOPER		CO
					JOIN	Un_OPER					OP	ON CO.OperID = OP.OperID
					JOIN	tblOPER_OperationsRIO	RIO	ON	RIO.iID_Oper_RIO = OP.OperID 
														AND	CO.ConventionID = RIO.iID_Convention_Destination
					
					WHERE	CO.ConventionID = @iIDConvention
					AND		OP.OperDate BETWEEN @dtDateDebut AND ISNULL(@dtDateFin, GETDATE())
					AND		(OP.OperTypeID = 'RIO' OR OP.OperTypeID = 'RIM' OR OP.OperTypeID = 'TRI')
					AND		CO.ConventionOperTypeId IN (SELECT cID_Type_Oper_Convention FROM fntOPER_ObtenirOperationsCategorie('OPER_RENDEMENTS_IQEE')
														UNION
														SELECT cID_Type_Oper_Convention FROM fntOPER_ObtenirOperationsCategorie('OPER_MONTANTS_CREDITBASE')
														UNION
														SELECT cID_Type_Oper_Convention FROM fntOPER_ObtenirOperationsCategorie('OPER_MONTANTS_MAJORATION')
														)
					GROUP BY OP.OperDate
							,OP.OperID
            --<<T8
			
			-->>T9: INSERTION DES DONNEES RELEVES DEPOTS

					-- Ajouter l'enregistrement du sommaire du relevé de dépôt à la table temporaire
					INSERT INTO dbo.tblCONV_DonneeReleveDepot 
						(
						 iIDConvention							,iIDSouscripteur					,iIDBeneficiaire
						,vcNumeroConvention						,mQuantiteUnite						,mFraisCotisation
						,mFrais
						,mSCEE
						,mSCEESup
						,mIQEE
						,mIntIQEE
						,mBec									,mIntBEC							,mPAE
						,mIntPAE								,mAutreRev							,mIntAutreRev
						,vcAnneeQualif							,mBourse							,mMntSouscrit
						,mMntTheoMens							,dtEntreeVigueur					,dtRembEstime
						,dtFinCotisation						,dtFinRegime						,vcPrenomRep
						,vcNomRep								,vcTelRep							,vcPrenomDir
						,vcNomDir								,vcTelDir							,mIntSCEE
						,mIntSCEESup							,mCoutEtude							,cSexeSouscripteur
						,vcPrenomSouscripteur					,vcNomSouscripteur					,vcAdresseSouscripteur
						,vcVilleSouscripteur					,vcProvinceSouscripteur				,vcPaysSouscripteur
						,vcCodePostSouscripteur					,bPrincipalResponsableErreur		,bPrincipalResponsableManquant
						,vcLangue								,vcPrenomBenef						,vcNomBenef
						,vcNASBenef								,dtDateOperation					,vcRegime
						,vcTypeDonnee							,vcTexteDiplome						,iIDRegime
						,vcDerniereAnnee						,vcAvantDernAnnee					,vcCourrielSouscripteur
						,vcTypeContact							,dtDateCalcul						,iPayementParAnnee
						,dtDateFin								,mIQEEMaj							,iNbGroupeUnite
						,dtEcheance								,bSouscripteur_Desire_Releve_Elect ,dtDateFinGeneration
						,mIntAutreRevTINDiffere					, mIntIQEETIN
						)

					SELECT ------------------------------------------------------------------------------------------------------
					
						 @iIDConvention							,@iIDSouscripteur					,@iIDBeneficiaire
						,@vcNumeroConvention					,@iQuantiteUnite					,@mFraisCotisation
						,@mFrais

						,@mSCEE
            --20120314 MBD cas Josee dumas (x-20100331043)
           /* + (SELECT 	ISNULL(SUM(conventionOperAmount),0)
								   -- Radu Trandafir
								   --FROM 	fntOPER_ObtenirMontantConvention(@iIdConvention,NULL,@dtDateDebut,'INT_PCEE_TIN'))
								   FROM 	fntOPER_ObtenirMontantConvention(@iIdConvention,NULL,DATEADD(dd,-1,@dtDateDebut),'INT_PCEE_TIN'))
								   
								+
								  (SELECT 	ISNULL(SUM(conventionOperAmount),0)
								  --FROM 	fntOPER_ObtenirMontantConvention(@iIdConvention,NULL,@dtDateDebut,'INT_PCEE_TIN_TFR'))
								  FROM 	fntOPER_ObtenirMontantConvention(@iIdConvention,NULL,DATEADD(dd,-1,@dtDateDebut),'INT_PCEE_TIN_TFR'))*/
						,@mSCEESup
						,@mMntSomIQEE		-- 0 : JFG 2009-11-03
						,@mMntSomIntIQEE	-- 0 : JFG 2009-11-03
						,@mBEC									,@mIntBEC							,@mPAE
           --20120314 MBD cas Josee dumas (x-20100331043)
           -- ,@mIntPAE								,ISNULL(@mAutreRev,0)				,@mIntAutreRev + @mIntPCEETIN_ITR
           ,@mIntPAE								,ISNULL(@mAutreRev,0)				,@mIntAutreRev + @mIntPCEETIN_ITR +@mIntPCEETIN
						,ISNULL(@vcAnneeQualif,0)				,ISNULL(@mBourse,0)					,ISNULL(@mMntSouscrit,0)
						,@mMntTheoMens							,@dtEntreeVigueur					,@dtRembEstime			
						,@dtFinCotisation						,@dtFinRegime						,ISNULL(@vcPrenomRep,'')
						,ISNULL(@vcNomRep,'')					,ISNULL(@vcTelRep,'')				,ISNULL(@vcPrenomDir,'')
						,ISNULL(@vcNomDir,'')					,ISNULL(@vcTelDir,'')				,ISNULL(@mIntSCEE,0)
						,ISNULL(@mIntSCEESup,0)					,ISNULL(@mCoutEtude,0)				,ISNULL(@cSexeSouscripteur,'')
						,ISNULL(@vcPrenomSouscripteur,'')		,ISNULL(@vcNomSouscripteur,'')		,ISNULL(@vcAdresseSouscripteur,'')
						,ISNULL(@vcVilleSouscripteur,'')		,ISNULL(@vcNomEtat,'QC')			,ISNULL(@vcPaysSouscripteur,'')
						,ISNULL(@vcCodePostalSouscripteur,'')	,@bPrincipalResponsableErreur		,@bPrincipalResponsableManquant
						,ISNULL(@vcLangue,'')					,ISNULL(@vcPrenomBeneficiaire,'')	,ISNULL(@vcNomBeneficiaire,'')
						,ISNULL(@vcNASBenef,'')					,@dtDateDebut						,ISNULL(@vcRegime,'')
						,'S'									,ISNULL(@vcTextDiploma,'')			,ISNULL(@iIDRegime,'')
						,ISNULL(@vcDerniereAnnee,'')			,ISNULL(@vcAvantDerniereAnnee,'')	,@vcCourrielSouscripteur
						,@vcTypeContact							,getdate()							,@iPmtByYearID
						,@dtDateFin								,@mMntSomIQEEMaj					,@iNbGroupeUniteConvention
						,@dtEcheance							,@bSouscripteur_Desire_Releve_Elect	,@dtDateFin
						,0										, 0

			
					SET @iNbEnreg = @@ROWCOUNT + @iNbEnreg


					-- Ajouter le détails de la convention
					 INSERT INTO dbo.tblCONV_DonneeReleveDepot 
						(
						 iIDConvention						,iIDSouscripteur					,iIDBeneficiaire
						,vcNumeroConvention					,mQuantiteUnite						,vcTypeOperation
						,mFraisCotisation					,mFrais								,mSCEE
						,mIntSCEE
						,mSCEESup
						,mIntSCEESup
						,mIQEE
						,mIntIQEE
						,mBec
						,mIntBEC
						,mPAE
						,mIntPAE
						,mAutreRev
						,mIntAutreRev
						,vcAnneeQualif						,mBourse							,mMntSouscrit
						,mMntTheoMens						,dtEntreeVigueur					,dtRembEstime
						,dtFinCotisation					,dtFinRegime						,vcPrenomRep
						,vcNomRep							,vcTelRep							,vcPrenomDir
						,vcNomDir							,vcTelDir							,mCoutEtude
						,vcPrenomSouscripteur				,vcNomSouscripteur					,vcAdresseSouscripteur
						,vcVilleSouscripteur				,vcProvinceSouscripteur				,vcPaysSouscripteur
						,vcCodePostSouscripteur				,bPrincipalResponsableErreur		,bPrincipalResponsableManquant
						,vcLangue							,vcPrenomBenef						,vcNomBenef
						,vcNASBenef							,dtDateOperation					,vcCompagnie
						,vcRegime							,vcTypeDonnee						,vcTexteDiplome
						,iIDRegime							,vcDerniereAnnee					,vcAvantDernAnnee
						,vcCourrielSouscripteur				,vcTypeContact						,cSexeSouscripteur
						,iPayementParAnnee					,iNombrePayement					,dtDateCalcul
						,dtDateFin							,mIQEEMaj							,iNbGroupeUnite
						,bEntreeVigueurIQEE
						,bEntreeVigueurSCEE
						,nDiffAnneeIQEE
						,nDiffAnneeSCEE
						,dtEcheance
						,dtDateFinGeneration
						,mIntAutreRevTINDiffere
						,mIntIQEETIN
						) 
					 
					 SELECT -------------------------------------------------------------------------------------------------
					 
						 @iIDConvention							,@iIDSouscripteur					,@iIDBeneficiaire
						,@vcNumeroConvention					,ISNULL(mQuantiteUnite,0)			,vcTypeOperation
						,ISNULL(mFraisCotisation,0)				,ISNULL(mFrais,0)					
						
						
						,ISNULL(mSCEE,0)
						-- Mbaye Diakhate: 2012-12-19 Correction sur le calcul des incitatifs liés au TIN cas Arseneault, Rodrigue
						--,CASE 
						--     WHEN vcTypeOperation= 'TIN' THEN
						--       ISNULL((SELECT SUM(fCESG + fCESGINT)	FROM fntPCEE_ObtenirSubventionSIBons (@iIDConvention,@dtDateDebut,@dtDateFin)  WHERE OperTypeID='TIN') --AND f.iIDOper = OperID)
						--              ,0)
						--      ELSE
						--      ISNULL(mSCEE,0)
						--  END
						,CASE
							WHEN vcTypeOperation = 'RIO' THEN
								0
							WHEN vcTypeOperation = 'RIM' THEN
								0
							WHEN vcTypeOperation = 'TRI' THEN
								0
							ELSE
								ISNULL(mIntSCEE,0)
							END
				        
						,ISNULL(mSCEESup,0)	
						-- Mbaye Diakhate: 2012-12-19 Correction sur le calcul des incitatifs liés au TIN cas Arseneault, Rodrigue				
						--,CASE 
						--     WHEN vcTypeOperation= 'TIN' THEN
						--       ISNULL((SELECT SUM(fACESG + fACESGINT)	FROM fntPCEE_ObtenirSubventionSIBons (@iIDConvention,@dtDateDebut,@dtDateFin)  WHERE OperTypeID='TIN' )--AND f.iIDOper = OperID)
						--              ,0)
						--      ELSE
						--      ISNULL(mSCEESup,0)
						--  END
						,CASE
							WHEN vcTypeOperation = 'RIO' THEN
								0
							WHEN vcTypeOperation = 'RIM' THEN
								0
							WHEN vcTypeOperation = 'TRI' THEN
								0
							ELSE
								ISNULL(mIntSCEESup, 0) /*+ ISNULL((
																SELECT SUM(ConventionOperAmount)	-- 2011-03-21 : JFG : Les intérêts provenant des RIO ne comportant aucune épargne ne doivent pas être inclus dans les revenus
																FROM		dbo.un_conventionoper c
																INNER JOIN	dbo.un_oper o ON c.OperId = o.OperId 
																WHERE	o.OperDate BETWEEN @dtDateDebut AND @dtDateFin
																AND		c.ConventionId = @iIDConvention
																AND		c.ConventionOperTypeID = 'IS+'
																AND 	(o.OperTypeID = 'RIO' OR o.OperTypeID = 'RIM' OR o.OperTypeID = 'TRI')
																AND		NOT EXISTS(
																					SELECT 1 
																					FROM dbo.Un_CESP ce 
																					WHERE	c.ConventionID = ce.ConventionID 
																					AND		ce.OperId = o.OperId
																					)
																), 0)*/
							END		
							
						,CASE
							WHEN vcTypeOperation = 'PAE' THEN 
								--ISNULL(@mMntIQEEPae,0)
								(SELECT mMntIQEEPae
											FROM dbo.fntOPER_ObtenirMntIQEERelDep(@iIDConvention, ISNULL(dtDateOperation,@dtDateDebut), ISNULL(dtDateOperation,@dtDateFin)))
							WHEN vcTypeOperation = 'OUT' THEN 
								ISNULL((SELECT mMntIQEE FROM fntOPER_ObtenirMntIQEERelDepParOperType(@iIDConvention, @dtDateDebut, @dtDateFin,'OUT')),0)
							WHEN (vcTypeOperation = 'RIO' OR vcTypeOperation = 'RIM' OR vcTypeOperation = 'TRI') THEN
								(
								mIQEERio
								--SELECT TOP 1 mntIQEERio 
								--FROM @tIQEERio t 
								--WHERE	t.OperDate = dtDateOperation 
								--AND		t.OperID = ISNULL(f.iIDOper, -1)
								) 
							WHEN vcTypeOperation = 'TFR' THEN
								0
							ELSE
								CASE
									WHEN	(ISNULL(@mMntIQEEPae,0) <> 0) 
									OR		(	SELECT COUNT(*) 
												FROM		dbo.UN_ConventionOper co 
												INNER JOIN	dbo.UN_Oper o ON co.operid = o.operid 
												WHERE	co.conventionid = @iIDConvention 
												AND 	o.operdate BETWEEN @dtDateDebut AND @dtDateFin 
												AND 	o.OperTypeID NOT IN ('IN+','IN-','RIO','RIM','TRI','PAE')
												) = 0 THEN   -- 2011-03-29 : JFG : On enlève le montant si c'est juste des revenus porvenant du RIO
													---(ISNULL(@mMntIQEEPae,0) <> 0) THEN 
										ISNULL(@mMntIQEE,0) - ISNULL((	SELECT SUM(ConventionOperAmount)	-- 2011-03-18 : JFG : Les intérêts provenant des RIO ne comportant aucune épargne ne doivent pas être inclus dans les revenus IQEE
																		FROM		dbo.un_conventionoper c
																		INNER JOIN	dbo.un_oper o ON c.OperId = o.OperId
																		INNER JOIN (	SELECT TOP 1 f2.dtDateOperation
																						FROM dbo.fntCONV_ObtenirReleveDepotDetails
																									(
																									 @iIDConvention
																									,@dtDateDebut
																									,@dtDateFin
																									) f2
																						WHERE f2.vcTypeOperation = 'RIO' OR f2.vcTypeOperation = 'RIM' OR f2.vcTypeOperation = 'TRI'
																						) f3 ON o.OperDate = ISNULL(f3.dtDateOperation,'1900-01-01')
																		WHERE	c.ConventionId = @iIDConvention
																		AND		c.ConventionOperTypeID IN (	SELECT cID_Type_Oper_Convention
																											FROM dbo.fntOPER_ObtenirOperationsCategorie('OPER_MONTANTS_CREDITBASE')
																											UNION
																											SELECT cID_Type_Oper_Convention
																											FROM dbo.fntOPER_ObtenirOperationsCategorie('OPER_MONTANTS_MAJORATION')
																											)
																		AND (o.OperTypeId = 'RIO' OR o.OperTypeId = 'RIM' OR o.OperTypeId = 'TRI')
																		), 0)					
									ELSE 
										CASE 
											WHEN vcTypeOperation <> 'TIN' AND ISNULL(@vcRegime, '') = 'Individuel' THEN
												ISNULL(@mMntIQEE, 0) - ISNULL((	SELECT SUM(ConventionOperAmount)	-- 2011-03-18 : JFG : Les intérêts provenant des RIO ne comportant aucune épargne ne doivent pas être inclus dans les revenus IQEE
																				FROM		dbo.un_conventionoper c
																				INNER JOIN	dbo.un_oper o ON c.OperId = o.OperId
																				INNER JOIN (
																							SELECT TOP 1 f2.dtDateOperation 
																							FROM dbo.fntCONV_ObtenirReleveDepotDetails
																										(
																										 @iIDConvention
																										,@dtDateDebut
																										,@dtDateFin
																										) f2
																							WHERE f2.vcTypeOperation = 'TIN'
																							) f3 ON o.OperDate = ISNULL(f3.dtDateOperation, '1900-01-01')
																				WHERE	c.ConventionId = @iIDConvention
																				AND		c.ConventionOperTypeID IN (	SELECT cID_Type_Oper_Convention
																													FROM dbo.fntOPER_ObtenirOperationsCategorie('OPER_MONTANTS_CREDITBASE')
																													UNION
																													SELECT cID_Type_Oper_Convention
																													FROM dbo.fntOPER_ObtenirOperationsCategorie('OPER_MONTANTS_MAJORATION')
																													)
																				AND		o.OperTypeId = 'TIN'
																				), 0)
											
											ELSE
											 CASE WHEN vcTypeOperation = 'TIN' THEN
											   ISNULL((SELECT mMntIQEE FROM fntOPER_ObtenirMntIQEERelDepParOperType(@iIDConvention, @dtDateDebut, @dtDateFin,'TIN')),0)
											 ELSE
												ISNULL(@mMntIQEE,0)
											 END
											END
									END
							END				--ISNULL(@mMntIQEE,0) : 2011-02-28 : JFG : Gestion de l'IQEE sur la ligne PAE 				
						
						,CASE 
							WHEN vcTypeOperation = 'PAE' THEN
								--ISNULL(@mMntIntIQEEPae, 0)
											(SELECT mMntIntIQEEPae
											FROM dbo.fntOPER_ObtenirMntIQEERelDep(@iIDConvention, ISNULL(dtDateOperation,@dtDateDebut), ISNULL(dtDateOperation,@dtDateFin)))
							WHEN vcTypeOperation = 'OUT' THEN 
								ISNULL((SELECT mMntIntIQEE FROM fntOPER_ObtenirMntIQEERelDepParOperType(@iIDConvention, @dtDateDebut, @dtDateFin,'OUT')),0)
							--WHEN vcTypeOperation = 'RIO' THEN
							--	0
							--WHEN vcTypeOperation = 'RIM' THEN
							--	0
							--WHEN vcTypeOperation = 'TRI' THEN
							--	0
							WHEN vcTypeOperation = 'TFR' THEN
								0
							WHEN vcTypeOperation = 'TIN' THEN
								 ISNULL((SELECT mMntIntIQEE FROM fntOPER_ObtenirMntIQEERelDepParOperType(@iIDConvention, @dtDateDebut, @dtDateFin,'TIN')),0)
							ELSE
								ISNULL(@mMntIntIQEE,0) - ISNULL((	SELECT SUM(ConventionOperAmount)	-- 2011-03-18 : JFG : Les intérêts provenant des RIO ne comportant aucune épargne ne doivent pas être inclus dans les revenus IQEE
																	FROM		dbo.un_conventionoper c
																	INNER JOIN	dbo.un_oper o ON c.OperId = o.OperId
																	INNER JOIN (
																				SELECT TOP 1 f2.dtDateOperation
																				FROM dbo.fntCONV_ObtenirReleveDepotDetails
																							(
																							 @iIDConvention
																							,@dtDateDebut
																							,@dtDateFin
																							) f2
																				WHERE f2.vcTypeOperation = 'RIO' OR f2.vcTypeOperation = 'RIM' OR f2.vcTypeOperation = 'TRI'
																				) f3 ON o.OperDate = ISNULL(f3.dtDateOperation, '1900-01-01')
																	WHERE	c.ConventionId = @iIDConvention
																	AND		c.ConventionOperTypeID IN (
																										SELECT cID_Type_Oper_Convention
																										FROM dbo.fntOPER_ObtenirOperationsCategorie('OPER_RENDEMENTS_IQEE')
																										)
																	AND (o.OperTypeId = 'RIO' OR o.OperTypeId = 'RIM' OR o.OperTypeId = 'TRI')
																	), 0)
				
							END			-- ISNULL(@mMntIntIQEE,0) : 2011-02-28 : JFG : Gestion de l'IQEE sur la ligne PAE 									
						
						,ISNULL(mBec,0)							

						,CASE
							WHEN vcTypeOperation = 'RIO' THEN
								0
							WHEN vcTypeOperation = 'RIM' THEN
								0
							WHEN vcTypeOperation = 'TRI' THEN
								0
							ELSE
								ISNULL(mIntBEC,0)
							END
						
						,ISNULL(mPAE,0)
						,ISNULL(mIntPAE,0)						,ISNULL(mAutreRev,0)
						
						,ISNULL(mIntAutreRev,0) + CASE
													WHEN ISNULL(@iIDRegime,'') = 'COL' THEN
														(	SELECT ISNULL(SUM(co.ConventionOperAmount),0)
															FROM		dbo.UN_ConventionOper co
															INNER JOIN	dbo.UN_Oper o ON co.OperId = o.OperID
															WHERE	co.ConventionID = @iIDConvention
															AND		o.OperDate BETWEEN @dtDateDebut AND @dtDateFin
															AND		co.ConventionOperTypeID = 'ITR' 
															AND		NOT EXISTS(	SELECT 1
																				FROM		dbo.UN_ConventionOper co
																				INNER JOIN	dbo.UN_Oper o ON co.OperId = o.OperID
																				WHERE	co.ConventionID = @iIDConvention
																				AND		o.OperDate BETWEEN @dtDateDebut AND @dtDateFin
																				AND		o.OperTypeID = 'TIN'
																				)
															)
													ELSE
														0
													END
						
						,ISNULL(@vcAnneeQualif,0)					,ISNULL(@mBourse,0)						,ISNULL(@mMntSouscrit,0)
						,@mMntTheoMens								,@dtEntreeVigueur						,@dtRembEstime
						,@dtFinCotisation							,@dtFinRegime							,ISNULL(@vcPrenomRep,'')
						,ISNULL(@vcNomRep,'')						,ISNULL(@vcTelRep,'')					,ISNULL(@vcPrenomDir,'')
						,ISNULL(@vcNomDir,'')						,ISNULL(@vcTelDir,'')					,ISNULL(@mCoutEtude,0)
						,ISNULL(@vcPrenomSouscripteur,'')			,ISNULL(@vcNomSouscripteur,'')			,ISNULL(@vcAdresseSouscripteur,'')
						,ISNULL(@vcVilleSouscripteur,'')			,ISNULL(@vcNomEtat,'QC')				,ISNULL(@vcPaysSouscripteur,'')
						,ISNULL(@vcCodePostalSouscripteur,'')		,@bPrincipalResponsableErreur			,@bPrincipalResponsableManquant
						,ISNULL(@vcLangue,'')						,ISNULL(@vcPrenomBeneficiaire,'')		,ISNULL(@vcNomBeneficiaire,'')
						,ISNULL(@vcNASBenef,'')						,ISNULL(dtDateOperation,@dtDateDebut)	,ISNULL(vcCompagnie,'')
						,ISNULL(@vcRegime,'')						,vcTypeDonnee							,ISNULL(@vcTextDiploma,'')
						,ISNULL(@iIDRegime,'')						,ISNULL(@vcDerniereAnnee,'')			,ISNULL(@vcAvantDerniereAnnee,'')
						,@vcCourrielSouscripteur					,@vcTypeContact							,ISNULL(@cSexeSouscripteur,'')
						,ISNULL(iPayementParAnnee,0)				,ISNULL(iNombrePayement,0)				,GETDATE()
						,@dtDateFin									,ISNULL(@mMntIQEEMaj,0)					,@iNbGroupeUniteConvention
						,CASE
							WHEN @dtEntreeVigueur > @dtDateEntreeVigueurIQEE THEN
								1
							ELSE 
								0
							END
						,CASE
							WHEN @dtEntreeVigueur > @dtDateEntreeVigueurSCEE THEN
								1
							ELSE
								0
							END
						,CAST(DATEDIFF(dd, @dtDateEntreeVigueurIQEE, @dtFinCotisation) AS NUMERIC(18, 10)) / CAST(365 AS NUMERIC(18, 10))
						,CAST(DATEDIFF(dd, @dtDateEntreeVigueurSCEE, @dtFinCotisation) AS NUMERIC(18, 10)) / CAST(365 AS NUMERIC(18, 10))
						,@dtEcheance
						,@dtDateFin
						,@mIntAutreRevTINDiffere
					    ,@mIntIQEETIN -- recuperer l'interet IQEE pour le TIN
					FROM dbo.fntCONV_ObtenirReleveDepotDetails(@iIDConvention, @dtDateDebut, @dtDateFin) f
					WHERE NOT (
								mFraisCotisation=0
							AND mFrais=0
							AND mSCEE=0
							AND mIntSCEE=0
							AND mSCEESup=0
							AND mIntSCEESup=0
							AND @mMntIQEE=0
							AND @mMntIntIQEE=0
							AND mBec=0
							AND mIntBEC=0
							AND mPAE=0
							AND mIntPAE=0
							AND mAutreRev=0
							AND mIntAutreRev=0
							AND vcTypeDonnee = 'D'
							)
	
					
					-- AJOUT DES LIGNES 'PRJ' POUR LE CALCUL DE PROJECTION SUR L'ANNÉE COMPLÈTE POUR LES CONVENTIONS AUTRES QU'INDIVIDUELLES
					IF @iIDRegime <> 'IND'
						BEGIN
						
						INSERT INTO dbo.tblCONV_DonneeReleveDepot 
							(
							 iIDConvention						,iIDSouscripteur					,iIDBeneficiaire
							,vcNumeroConvention					,mQuantiteUnite						,vcTypeOperation
							,mFraisCotisation					,mFrais								
							
							,mSCEE
							,mIntSCEE							
							,mSCEESup							
							,mIntSCEESup
							
							,mIQEE								,mIntIQEE							,mBec
							,mIntBEC							,mPAE								,mIntPAE
							,mAutreRev							,mIntAutreRev						,vcAnneeQualif
							,mBourse
							,mMntSouscrit
							,mMntTheoMens								,dtEntreeVigueur						,dtRembEstime
							,dtFinCotisation							,dtFinRegime							,vcPrenomRep
							,vcNomRep									,vcTelRep								,vcPrenomDir
							,vcNomDir									,vcTelDir								,mCoutEtude
							,vcPrenomSouscripteur						,vcNomSouscripteur						,vcAdresseSouscripteur
							,vcVilleSouscripteur						,vcProvinceSouscripteur					,vcPaysSouscripteur
							,vcCodePostSouscripteur						,bPrincipalResponsableErreur			,bPrincipalResponsableManquant
							,vcLangue									,vcPrenomBenef							,vcNomBenef
							,vcNASBenef									,dtDateOperation						,vcCompagnie
							,vcRegime									,vcTypeDonnee							,vcTexteDiplome
							,iIDRegime									,vcDerniereAnnee						,vcAvantDernAnnee
							,vcCourrielSouscripteur						,vcTypeContact							,cSexeSouscripteur
							,iPayementParAnnee
							,iNombrePayement
							,dtDateCalcul
							,dtDateFin
							,mIQEEMaj
							,iNbGroupeUnite
							,bEntreeVigueurIQEE
							,bEntreeVigueurSCEE
							,nDiffAnneeIQEE
							,nDiffAnneeSCEE
							,dtEcheance
							,dtDateFinGeneration
							)
						SELECT 
							@iIDConvention						,@iIDSouscripteur					,@iIDBeneficiaire
							,@vcNumeroConvention				,ISNULL(d.mQuantiteUnite, 0)		,'PRJ'
							,ISNULL(d.mFraisCotisation, 0)		,ISNULL(d.mFrais, 0)				
							
							--,ISNULL(d.mSCEE, 0)
							,CASE
								WHEN vcTypeOperation = 'RIO' OR vcTypeOperation = 'RIM' OR vcTypeOperation = 'TRI' THEN
									ISNULL(d.mSCEE, 0) + ISNULL(d.mIntSCEE, 0)
								ELSE
									ISNULL(d.mSCEE, 0)
								END
							
							--,ISNULL(d.mIntSCEE, 0)				
							,CASE
								WHEN vcTypeOperation = 'RIO' OR vcTypeOperation = 'RIM' OR vcTypeOperation = 'TRI' THEN
									0
								ELSE
									ISNULL(d.mIntSCEE, 0)
								END
							
							--,ISNULL(d.mSCEESup, 0)				
							,CASE
								WHEN vcTypeOperation = 'RIO' OR vcTypeOperation = 'RIM' OR vcTypeOperation = 'TRI' THEN
									ISNULL(d.mSCEESup, 0) + ISNULL(d.mIntSCEESup, 0)
								ELSE
									ISNULL(d.mSCEESup, 0)
								END
							
							--,ISNULL(d.mIntSCEESup, 0)
							,CASE
								WHEN vcTypeOperation = 'RIO' OR vcTypeOperation = 'RIM' OR vcTypeOperation = 'TRI' THEN
									0
								ELSE
									ISNULL(d.mIntSCEESup, 0)
								END
							
							
							,ISNULL(iq.mMntIQEE, 0)				,ISNULL(iq.mMntIntIQEE, 0)			,ISNULL(d.mBec, 0)
							,ISNULL(d.mIntBEC, 0)				,ISNULL(d.mPAE, 0)					,ISNULL(d.mIntPAE, 0)
							,ISNULL(d.mAutreRev, 0)				,ISNULL(d.mIntAutreRev, 0)			,ISNULL(@vcAnneeQualif, 0)
							,ISNULL(@mBourse, 0)						
							,ISNULL(dbo.fnCONV_ObtenirMontantSouscritConvention
											(
											 @iIDConvention
											,NULL
											,CAST(CAST(YEAR(@dtDateFin) AS VARCHAR(4)) + '-12-31' AS DATETIME)
											), 0)			
							
							,@mMntTheoMensPrj							,@dtEntreeVigueur						,@dtRembEstime
							,@dtFinCotisation							,@dtFinRegime							,ISNULL(@vcPrenomRep, '')
							,ISNULL(@vcNomRep, '')						,ISNULL(@vcTelRep, '')					,ISNULL(@vcPrenomDir, '')
							,ISNULL(@vcNomDir, '')						,ISNULL(@vcTelDir, '')					,ISNULL(@mCoutEtude, 0)
							,ISNULL(@vcPrenomSouscripteur, '')			,ISNULL(@vcNomSouscripteur, '')			,ISNULL(@vcAdresseSouscripteur, '')
							,ISNULL(@vcVilleSouscripteur, '')			,ISNULL(@vcNomEtat, 'QC')				,ISNULL(@vcPaysSouscripteur, '')
							,ISNULL(@vcCodePostalSouscripteur, '')		,@bPrincipalResponsableErreur			,@bPrincipalResponsableManquant
							,ISNULL(@vcLangue, '')						,ISNULL(@vcPrenomBeneficiaire, '')		,ISNULL(@vcNomBeneficiaire, '')
							,ISNULL(@vcNASBenef, '')					,ISNULL(d.dtDateOperation, @dtDateDebut),ISNULL(d.vcCompagnie,'')
							,ISNULL(@vcRegime,'')						,d.vcTypeDonnee							,ISNULL(@vcTextDiploma,'')
							,ISNULL(@iIDRegime,'')						,ISNULL(@vcDerniereAnnee,'')			,ISNULL(@vcAvantDerniereAnnee,'')
							,@vcCourrielSouscripteur					,@vcTypeContact							,ISNULL(@cSexeSouscripteur,'')
							,(	SELECT MAX(M.pmtByYearID) 
								FROM		dbo.Un_Unit U 
								INNER JOIN	dbo.Un_Modal M ON M.ModalID=U.ModalID
								WHERE U.ConventionID = @iIdConvention
								)
							,(	SELECT MAX(M.pmtQty) 
								FROM		dbo.Un_Unit U 
								INNER JOIN	dbo.Un_Modal M ON M.ModalID=U.ModalID 
								WHERE U.ConventionID = @iIdConvention
								)
							,GETDATE()
							,@dtDateFin
							,ISNULL(iq.mMntIQEEMaj, 0)
							,(	SELECT ISNULL(COUNT(UnitID), 0)
								FROM  dbo.fntCONV_ObtenirUnitesConvention
											(
											 d.iIDConvention
											,NULL
											,CAST(CAST(YEAR(@dtDateFin) AS VARCHAR(4))+ '-12-31' AS DATETIME)
											)
								)  -- ,@iNbGroupeUniteConvention
							,CASE
								WHEN @dtEntreeVigueur > @dtDateEntreeVigueurIQEE THEN
									1
								ELSE 
									0
								END
							,CASE
								WHEN @dtEntreeVigueur > @dtDateEntreeVigueurSCEE THEN 
									1
								ELSE 
									0
								END
							,CAST(DATEDIFF(dd, @dtDateEntreeVigueurIQEE, @dtFinCotisation) AS NUMERIC(18,10)) / CAST(365 AS NUMERIC(18,10))
							,CAST(DATEDIFF(dd, @dtDateEntreeVigueurSCEE, @dtFinCotisation) AS   NUMERIC(18,10)) / CAST(365 AS NUMERIC(18,10))
							,@dtEcheance
							,@dtDateFin
						-- +/- 2010-25 - CM : Prise en compte des paramètres de date et non pas en dur
						--FROM dbo.fntCONV_ObtenirReleveDepotDetails(@iIDConvention,CAST(CAST(YEAR(@dtDateFin) AS VARCHAR(4)) + '-01-01' AS DATETIME),CAST(CAST(YEAR(@dtDateFin) AS VARCHAR(4))+ '-12-31' AS DATETIME)) d
						FROM		dbo.fntCONV_ObtenirReleveDepotDetails
											(
											 @iIDConvention
											,@dtDateDebut
											,@dtDateFin
											) d
						INNER JOIN	dbo.fntOPER_ObtenirMntIQEERelDep
											(
											 @iIDConvention
											,@dtDateDebut
											,@dtDateFin
											) iq ON iq.iIDConvention = d.iIDConvention
						WHERE	NOT (
										d.mFraisCotisation	= 0
									AND d.mFrais			= 0
									AND d.mSCEE				= 0
									AND d.mIntSCEE			= 0
									AND d.mSCEESup			= 0
									AND d.mIntSCEESup		= 0
									AND iq.mMntIQEE			= 0
									AND iq.mMntIntIQEE		= 0
									AND d.mBec				= 0
									AND d.mIntBEC			= 0
									AND d.mPAE				= 0
									AND d.mIntPAE			= 0
									AND d.mAutreRev			= 0
									AND d.mIntAutreRev		= 0
									AND vcTypeDonnee		= 'D'
									)
						AND		(
									-- +/- 2010-25 - CM : Prise en compte des paramètres de date et non pas en dur
											--( SELECT COUNT(*) FROM dbo.fntCONV_ObtenirReleveDepotDetails(d.iIDConvention,CAST(CAST(YEAR(@dtDateFin) AS VARCHAR(4)) + '-01-01' AS DATETIME),CAST(CAST(YEAR(@dtDateFin) AS VARCHAR(4))+ '-12-31' AS DATETIME)) 
								(	SELECT COUNT(*)
									FROM dbo.fntCONV_ObtenirReleveDepotDetails
														(
														 d.iIDConvention
														,@dtDateDebut
														,@dtDateFin
														) 
									WHERE	vcTypeOperation NOT IN('REV','BEC')) = 0		-- 2010-05-21 : JFG : Ajout TRF, TIN, OUT
									OR		d.vcTypeOperation NOT IN ('REV','BEC')			-- 2010-05-21 : JFG : Ajout TRF, TIN, OUT
										
								)
						
						END
						
					
					SET @iNbEnreg = @@ROWCOUNT + @iNbEnreg
					
			--<<T9		
-- ********************** FIN DU TRAITEMENT BASÉ SUR LES CONVENTIONS (UNITÉS REGROUPÉES) ************************					

-- ********************** DEBUT DU TRAITEMENT BASÉ SUR LES GROUPES D'UNITÉS  POUR L'ESTIMÉ DES MONTANTS VERSÉS FUTURS **********************			


--<<T10:DETAILS DE LA CONVENTION PAR GROUPE D'UNITÉS
	IF @iNbGroupeUniteConvention > 1 AND @iIDRegime <> 'IND' -- TRAITEMENT EFFECTUÉ SEULEMENT POUR LES CONVENTIONS QUI ONT PLUS D'UN GROUPE D'UNITÉS
		BEGIN

		-- SOMME DES FRAIS ET DES COTISATIONS À PARTIR DU 2007-02-02
		-- AFIN DE FAIRE UN PRORATA	
		SET @mFraisCotisationTotal =	(SELECT
											SUM(ISNULL(ct.mCotisation,0) + ISNULL(ct.mFrais,0)) 
										FROM
											dbo.fntOPER_ObtenirCotisationFraisConvention (@iIdConvention,NULL,@dtDateEntreeVigueurIQEE ,@dtDateFin,'E',NULL,'D') ct)

		SET @mFraisCotisationTotalPrj =	(SELECT
											SUM(ISNULL(ct.mCotisation,0) + ISNULL(ct.mFrais,0)) 
										FROM
											dbo.fntOPER_ObtenirCotisationFraisConvention (@iIdConvention,NULL,@dtDateEntreeVigueurIQEE ,@dtDateFin,'E',NULL,'D') ct)
											--dbo.fntOPER_ObtenirCotisationFraisConvention (@iIdConvention,NULL,@dtDateEntreeVigueurIQEE ,CAST(CAST(YEAR(@dtDateFin) AS VARCHAR(4))+ '-12-31' AS DATETIME),'E',NULL) ct)

		-- ON DOIT BOUCLER SUR LES UNITÉS ASSOCIÉS À LA CONVENTION
		-- Ajouter le détails de la convention par groupe d'unité
		 INSERT INTO dbo.tblCONV_DonneeReleveDepotAvecDetailParUnite 
		 (
			iIDConvention,			iIDSouscripteur,		iIDBeneficiaire,			vcNumeroConvention, 
			mQuantiteUnite,			vcTypeOperation,		mFraisCotisation, 			mFrais, 
			mSCEE, 					mIntSCEE,				mSCEESup, 					mIntSCEESup, 
			mIQEE, 					
			mIntIQEE, 				
			mBec, 						mIntBEC, 
			mPAE, 					mIntPAE, 				mAutreRev, 					mIntAutreRev, 
			vcAnneeQualif, 			mBourse, 				mMntSouscrit, 				
			mMntTheoMens, 
			dtEntreeVigueur,		dtRembEstime, 			dtFinCotisation, 			dtFinRegime, 
			vcPrenomRep, 			vcNomRep, 				vcTelRep, 					vcPrenomDir, 
			vcNomDir, 				vcTelDir, 				mCoutEtude, 				vcPrenomSouscripteur, 
			vcNomSouscripteur,		vcAdresseSouscripteur, 	vcVilleSouscripteur,		vcProvinceSouscripteur, 
			vcPaysSouscripteur,		vcCodePostSouscripteur, bPrincipalResponsableErreur, bPrincipalResponsableManquant, 
			vcLangue, 				vcPrenomBenef, 			vcNomBenef, 				vcNASBenef, 
			dtDateOperation, 		vcCompagnie, 			vcRegime, 					vcTypeDonnee, 
			vcTexteDiplome, 		iIDRegime, 				vcDerniereAnnee, 			vcAvantDernAnnee, 
			vcCourrielSouscripteur, vcTypeContact, 			cSexeSouscripteur, 			iPayementParAnnee, 
			iNombrePayement, 		dtDateCalcul,			dtDateFin,					mIQEEMaj,
			iNbGroupeUnite,
			bEntreeVigueurIQEE,
			bEntreeVigueurSCEE,
			nDiffAnneeIQEE,
			nDiffAnneeSCEE,
			dtEcheance
		 )
		 SELECT 
			 @iIDConvention							,@iIDSouscripteur						,@iIDBeneficiaire
			,@vcNumeroConvention					,ISNULL(fnt.fQuantiteUnite, 0)			,NULL
			,ISNULL(SUM(fnt.mFraisCotisation), 0)	,SUM(fnt.mFrais)						,ISNULL(fnt.mSCEE, 0)
			,ISNULL(fnt.mIntSCEE, 0)				,ISNULL(fnt.mSCEESup, 0)				,ISNULL(fnt.mIntSCEESup, 0)

			,ROUND(ISNULL(@mMntIQEE, 0) * ((	SELECT SUM(f.mCotisation + f.mFrais)
												FROM dbo.fntOPER_ObtenirCotisationFraisConvention
															(
															 @iIDConvention
															,fnt.iIDUnite
															,@dtDateEntreeVigueurIQEE
															,@dtDateFin
															,'E'
															,NULL
															,'D'
															) f) / NULLIF(@mFraisCotisationTotal,0)),3)			

			,ROUND(ISNULL(@mMntIntIQEE, 0) * ((	SELECT SUM(f.mCotisation + f.mFrais) 
												FROM dbo.fntOPER_ObtenirCotisationFraisConvention
															(
															 @iIDConvention
															,fnt.iIDUnite
															,@dtDateEntreeVigueurIQEE
															,@dtDateFin
															,'E'
															,NULL
															,'D'
															) f) / NULLIF(@mFraisCotisationTotal,0)),3)					

			,ISNULL(fnt.mBec, 0)				,ISNULL(fnt.mIntBEC, 0)				,ISNULL(fnt.mPAE, 0)
			,ISNULL(fnt.mIntPAE, 0)				,ISNULL(fnt.mAutreRev, 0)			,ISNULL(fnt.mIntAutreRev, 0)
			,ISNULL(@vcAnneeQualif, 0)			,ISNULL(@mBourse, 0)				,ISNULL(@mMntSouscrit, 0)

			,mMntTheoMens = CASE						-- calcul basé sur une somme par groupe d'unité afin de vérifier le 2500 
								WHEN (odc.dtFinCotisation) <= @dtDateFin THEN 
									0
								WHEN (	SELECT SUM(ISNULL(ct.mCotisation,0) + ISNULL(ct.mFrais,0)) 
										FROM dbo.fntOPER_ObtenirCotisationFraisConvention
													(
													 fnt.iIDConvention
													,fnt.iIDUnite
													,@dtDateDebut
													,@dtDateFin
													,'E'
													,NULL
													,'D'
													) ct) < 2500 THEN 
									ROUND((	SELECT SUM(ISNULL(ct.mCotisation, 0) + ISNULL(ct.mFrais,0)) 
											FROM dbo.fntOPER_ObtenirCotisationFraisConvention
														(
														 fnt.iIDConvention
														,fnt.iIDUnite
														,@dtDateDebut
														,@dtDateFin
														,'E'
														,null
														,'D'
														) ct) / ISNULL(NULLIF((	SELECT ISNULL(COUNT(f.iNombrePayement), 0) 
																				FROM dbo.fntCONV_ObtenirReleveDepotDetailsAvecGroupeUnite
																							(
																							 fnt.iIDConvention
																							,DATEADD(dd,-1,@dtDateDebut)
																							,@dtDateFin
																							) f 
																				WHERE f.iIDUnite = fnt.iIDUnite
																				), 0), 1), 3)
								ELSE
									CASE
										WHEN (	SELECT SUM(ISNULL(ct.mCotisation, 0) + ISNULL(ct.mFrais, 0)) 
												FROM dbo.fntOPER_ObtenirCotisationFraisConvention
															(
															 fnt.iIDConvention
															,fnt.iIDUnite
															,@dtDateDebut
															,@dtDateFin
															,'E'
															,NULL
															,'D'
															) ct) IS NULL THEN
											0
										ELSE
											ROUND(CAST(2500 AS NUMERIC(18, 10)) / ISNULL(NULLIF(CAST(fnt.iPayementParAnnee AS NUMERIC(18, 10)),0),1) ,3)
										END
								END	 
			
			,odc.dtEntreeVigueur				,odc.dtRembEstime						,odc.dtFinCotisation				
			,odc.dtFinRegime					,ISNULL(@vcPrenomRep, '')				,ISNULL(@vcNomRep, '')
			,ISNULL(@vcTelRep, '')				,ISNULL(@vcPrenomDir, '')				,ISNULL(@vcNomDir, '')
			,ISNULL(@vcTelDir, '')				,ISNULL(@mCoutEtude, 0)					,ISNULL(@vcPrenomSouscripteur, '')
			,ISNULL(@vcNomSouscripteur, '')		,ISNULL(@vcAdresseSouscripteur, '')		,ISNULL(@vcVilleSouscripteur, '')
			,ISNULL(@vcNomEtat, 'QC')			,ISNULL(@vcPaysSouscripteur, '')		,ISNULL(@vcCodePostalSouscripteur, '')
			,@bPrincipalResponsableErreur		,@bPrincipalResponsableManquant			,ISNULL(@vcLangue, '')
			,ISNULL(@vcPrenomBeneficiaire, '')	,ISNULL(@vcNomBeneficiaire, '')			,ISNULL(@vcNASBenef, '')
			,fnt.dtDateOperation				,ISNULL(fnt.vcCompagnie, '')			,ISNULL(@vcRegime, '')
			,fnt.vcTypeDonnee					,ISNULL(@vcTextDiploma, '')				,ISNULL(@iIDRegime, '')
			,ISNULL(@vcDerniereAnnee, '')		,ISNULL(@vcAvantDerniereAnnee, '')		,@vcCourrielSouscripteur
			,@vcTypeContact						,ISNULL(@cSexeSouscripteur, '')			,ISNULL(fnt.iPayementParAnnee, 0)
			,ISNULL(fnt.iNombrePayement, 0)		,GETDATE()								,@dtDateFin
			
			,ROUND(ISNULL(@mMntIQEEMaj, 0) * ((	SELECT SUM(f.mCotisation + f.mFrais) 
												FROM dbo.fntOPER_ObtenirCotisationFraisConvention
															(
															 @iIDConvention
															,fnt.iIDUnite
															,@dtDateEntreeVigueurIQEE
															,@dtDateFin
															,'E'
															,NULL
															,'D'
															) f) / ISNULL(NULLIF(@mFraisCotisationTotal, 0), 1)), 3) 
			,fnt.iIDUnite
			,CASE
				WHEN odc.dtEntreeVigueur > @dtDateEntreeVigueurIQEE THEN 
					1
				ELSE 
					0
				END
			,CASE
				WHEN odc.dtEntreeVigueur > @dtDateEntreeVigueurSCEE THEN 
					1
				ELSE 
					0
				END
			,CAST(DATEDIFF(dd, @dtDateEntreeVigueurIQEE, odc.dtFinCotisation) AS NUMERIC(18, 10)) / CAST(365 AS NUMERIC(18, 10))
			,CAST(DATEDIFF(dd, @dtDateEntreeVigueurSCEE, odc.dtFinCotisation) AS NUMERIC(18, 10)) / CAST(365 AS NUMERIC(18, 10))
			,@dtEcheance
		
		FROM		dbo.fntCONV_ObtenirReleveDepotDetailsAvecGroupeUnite
							(
							 @iIDConvention
							,'1900-01-01'
							,@dtDateFin
							) fnt
		INNER JOIN	dbo.fntCONV_ObtenirDatesConvention
							(
							 @iIDConvention
							,@dtDateFin
							) odc ON fnt.iIDUnite = odc.UnitID
		WHERE NOT	(
						mFraisCotisation=0
					AND mFrais=0
					AND mSCEE=0
					AND mIntSCEE=0
					AND mSCEESup=0
					AND mIntSCEESup=0
					AND @mMntIQEE=0
					AND @mMntIntIQEE=0
					AND mBec=0
					AND mIntBEC=0
					AND mPAE=0
					AND mIntPAE=0
					AND mAutreRev=0
					AND mIntAutreRev=0
					AND vcTypeDonnee = 'D'
					)
		GROUP BY
				fnt.iIDUnite, 
				fnt.iIDConvention, 
				fnt.fQuantiteUnite,
				fnt.mIntSCEESup,
				fnt.mSCEE,
				fnt.mIntSCEE,
				fnt.mSCEESup,
				fnt.mBec,
				fnt.mIntBEC, 
				fnt.mPAE, 
				fnt.mIntPAE,
				fnt.vcCompagnie, 
				fnt.mAutreRev, 
				fnt.mIntAutreRev, 
				fnt.vcTypeDonnee, 
				fnt.iPayementParAnnee, 
				fnt.iNombrePayement,
				fnt.vcCompagnie,
				fnt.dtDateOperation,				
				odc.dtEntreeVigueur,
				odc.dtRembEstime,
				odc.dtFinCotisation,
				odc.dtFinRegime
		
		UNION ALL				-- AJOUT DES ENREGISTREMENTS POUR LA PROJECTION
		
		SELECT 
				 @iIDConvention							,@iIDSouscripteur						,@iIDBeneficiaire
				,@vcNumeroConvention					,ISNULL(fnt.fQuantiteUnite, 0)			,'PRJ'
				,ISNULL(SUM(fnt.mFraisCotisation), 0)	,SUM(fnt.mFrais)						,ISNULL(fnt.mSCEE, 0)
				,ISNULL(fnt.mIntSCEE, 0)				,ISNULL(fnt.mSCEESup, 0)				,ISNULL(fnt.mIntSCEESup, 0)
				
				,ROUND(ISNULL(iq.mMntIQEE, 0) * ((	SELECT SUM(f.mCotisation + f.mFrais) 
													FROM dbo.fntOPER_ObtenirCotisationFraisConvention
																	(
																	 @iIDConvention
																	,fnt.iIDUnite
																	,@dtDateEntreeVigueurIQEE
																	,@dtDateFin
																	,'E'
																	,NULL
																	,'D'
																	) f) / NULLIF(@mFraisCotisationTotalPrj, 0)), 3)
				
				,ROUND(ISNULL(iq.mMntIntIQEE, 0) * ((	SELECT SUM(f.mCotisation + f.mFrais) 
														FROM dbo.fntOPER_ObtenirCotisationFraisConvention
																	(
																	 @iIDConvention
																	,fnt.iIDUnite
																	,@dtDateEntreeVigueurIQEE
																	,@dtDateFin
																	,'E'
																	,NULL
																	,'D'
																	) f) / NULLIF(@mFraisCotisationTotalPrj, 0)), 3)					
				
				,ISNULL(fnt.mBec, 0)					,ISNULL(fnt.mIntBEC, 0)					,ISNULL(fnt.mPAE, 0)
				,ISNULL(fnt.mIntPAE, 0)					,ISNULL(fnt.mAutreRev, 0)				,ISNULL(fnt.mIntAutreRev, 0)
				,ISNULL(@vcAnneeQualif, 0)				,ISNULL(@mBourse, 0)					,ISNULL(dbo.fnCONV_ObtenirMontantSouscritConvention (@iIDConvention, NULL, @dtDateFin), 0)

				-- 2009-11-27 : JFG : Changement de fonction pour le calcul du montant théorique mensuel
				/*
				,mMntTheoMens = CASE		
									WHEN (odc.dtFinCotisation) <= CAST(CAST(YEAR(@dtDateFin) AS VARCHAR(4)) + '-12-31' AS DATETIME) THEN 0
									WHEN (SELECT SUM(ISNULL(ct.mCotisation,0) + ISNULL(ct.mFrais,0)) FROM dbo.fntOPER_ObtenirCotisationFraisConvention(fnt.iIDConvention,fnt.iIDUnite,CAST(CAST(YEAR(@dtDateDebut) AS VARCHAR(4))+ '-01-01' AS DATETIME), CAST(CAST(YEAR(@dtDateFin) AS VARCHAR(4)) + '-12-31' AS DATETIME),'E',NULL) ct) < 2500 THEN ROUND((SELECT SUM(ISNULL(ct.mCotisation,0) + ISNULL(ct.mFrais,0)) FROM dbo.fntOPER_ObtenirCotisationFraisConvention(fnt.iIDConvention,fnt.iIDUnite,CAST(CAST(YEAR(@dtDateFin) AS VARCHAR(4)) + '-01-01' AS DATETIME),CAST(CAST(YEAR(@dtDateFin) AS VARCHAR(4)) + '-12-31' AS DATETIME),'E',null) ct) / ( SELECT COUNT(f.iNombrePayement) FROM dbo.fntCONV_ObtenirReleveDepotDetailsAvecGroupeUnite(fnt.iIDConvention,DATEADD(dd,-1,CAST(CAST(YEAR(@dtDateFin) AS VARCHAR(4)) + '-01-01' AS DATETIME)),CAST(CAST(YEAR(@dtDateFin) AS VARCHAR(4)) + '-12-31' AS DATETIME)) f WHERE f.iIDUnite = fnt.iIDUnite),3)
									ELSE
										CASE	WHEN (SELECT SUM(ISNULL(ct.mCotisation,0) + ISNULL(ct.mFrais,0)) FROM dbo.fntOPER_ObtenirCotisationFraisConvention(fnt.iIDConvention,fnt.iIDUnite,CAST(CAST(YEAR(@dtDateDebut) AS VARCHAR(4))+ '-01-01' AS DATETIME),CAST(CAST(YEAR(@dtDateFin) AS VARCHAR(4)) + '-12-31' AS DATETIME),'E',NULL) ct) IS NULL THEN 0
												ELSE
													ROUND(CAST(2500 AS   NUMERIC(18,10)) / ISNULL(NULLIF(CAST(fnt.iPayementParAnnee AS   NUMERIC(18,10)),0),1)  ,3)
										END
								END	 */
				,mMntTheoMens = CASE		
									WHEN (odc.dtFinCotisation) <= CAST(CAST(YEAR(@dtDateFin) AS VARCHAR(4)) + '-12-31' AS DATETIME) THEN 
										0
									--WHEN (SELECT dbo.fnCONV_ObtenirMontantTheoriqueMensuel(fnt.iIDConvention,fnt.iIDUnite,CAST(CAST(YEAR(@dtDateDebut) AS VARCHAR(4))+ '-01-01' AS DATETIME), CAST(CAST(YEAR(@dtDateFin) AS VARCHAR(4)) + '-12-31' AS DATETIME)) ct) < 2500 THEN ROUND((SELECT dbo.fnCONV_ObtenirMontantTheoriqueMensuel(fnt.iIDConvention,fnt.iIDUnite,CAST(CAST(YEAR(@dtDateFin) AS VARCHAR(4)) + '-01-01' AS DATETIME),CAST(CAST(YEAR(@dtDateFin) AS VARCHAR(4)) + '-12-31' AS DATETIME)) ct)  / ( SELECT COUNT(f.iNombrePayement) FROM dbo.fntCONV_ObtenirReleveDepotDetailsAvecGroupeUnite(fnt.iIDConvention,DATEADD(dd,-1,CAST(CAST(YEAR(@dtDateFin) AS VARCHAR(4)) + '-01-01' AS DATETIME)),CAST(CAST(YEAR(@dtDateFin) AS VARCHAR(4)) + '-12-31' AS DATETIME)) f WHERE f.iIDUnite = fnt.iIDUnite),3) 
									-- +/- 2010-25 - CM : Prise en compte des paramètres de date et non pas en dur
									--WHEN (SELECT dbo.fnCONV_ObtenirMontantTheoriqueMensuel(fnt.iIDConvention,fnt.iIDUnite,CAST(CAST(YEAR(@dtDateDebut) AS VARCHAR(4))+ '-01-01' AS DATETIME), CAST(CAST(YEAR(@dtDateFin) AS VARCHAR(4)) + '-12-31' AS DATETIME)) ct) < 2500 THEN ROUND((SELECT dbo.fnCONV_ObtenirMontantTheoriqueMensuel(fnt.iIDConvention,fnt.iIDUnite,CAST(CAST(YEAR(@dtDateFin) AS VARCHAR(4)) + '-01-01' AS DATETIME),CAST(CAST(YEAR(@dtDateFin) AS VARCHAR(4)) + '-12-31' AS DATETIME)) ct) ,3)
									
									WHEN (	SELECT dbo.fnCONV_ObtenirMontantTheoriqueMensuel
															(
															 fnt.iIDConvention
															,fnt.iIDUnite
															,@dtDateDebut
															,@dtDateFin
															) ct) < 2500 THEN 
										ROUND((	SELECT dbo.fnCONV_ObtenirMontantTheoriqueMensuel
																(
																 fnt.iIDConvention
																,fnt.iIDUnite
																,@dtDateDebut
																,@dtDateFin
																) ct) ,3)
									ELSE
										--JFA 2010-10-07 Désactiver cette vérification car elle fausse la projection
										--CASE	WHEN (SELECT SUM(ISNULL(ct.mCotisation,0) + ISNULL(ct.mFrais,0)) FROM dbo.fntOPER_ObtenirCotisationFraisConvention(fnt.iIDConvention,fnt.iIDUnite,CAST(CAST(YEAR(@dtDateDebut) AS VARCHAR(4))+ '-01-01' AS DATETIME),CAST(CAST(YEAR(@dtDateFin) AS VARCHAR(4)) + '-12-31' AS DATETIME),'E',NULL,'D') ct) IS NULL THEN 0
										--		ELSE
										ROUND(CAST(2500 AS   NUMERIC(18,10)) / ISNULL(NULLIF(CAST(fnt.iPayementParAnnee AS   NUMERIC(18,10)),0),1)  ,3)
										--END
									END

				,odc.dtEntreeVigueur					,odc.dtRembEstime						,odc.dtFinCotisation
				,odc.dtFinRegime						,ISNULL(@vcPrenomRep, '')				,ISNULL(@vcNomRep, '')
				,ISNULL(@vcTelRep, '')					,ISNULL(@vcPrenomDir, '')				,ISNULL(@vcNomDir, '')
				,ISNULL(@vcTelDir, '')					,ISNULL(@mCoutEtude, 0)					,ISNULL(@vcPrenomSouscripteur, '')
				,ISNULL(@vcNomSouscripteur, '')			,ISNULL(@vcAdresseSouscripteur, '')		,ISNULL(@vcVilleSouscripteur, '')
				,ISNULL(@vcNomEtat, 'QC')				,ISNULL(@vcPaysSouscripteur, '')		,ISNULL(@vcCodePostalSouscripteur, '')
				,@bPrincipalResponsableErreur			,@bPrincipalResponsableManquant			,ISNULL(@vcLangue, '')
				,ISNULL(@vcPrenomBeneficiaire, '')		,ISNULL(@vcNomBeneficiaire, '')			,ISNULL(@vcNASBenef, '')
				,fnt.dtDateOperation					,ISNULL(fnt.vcCompagnie, '')			,ISNULL(@vcRegime, '')
				,fnt.vcTypeDonnee						,ISNULL(@vcTextDiploma, '')				,ISNULL(@iIDRegime, '')
				,ISNULL(@vcDerniereAnnee, '')			,ISNULL(@vcAvantDerniereAnnee, '')		,@vcCourrielSouscripteur
				,@vcTypeContact							,ISNULL(@cSexeSouscripteur, '')
				
				,(	SELECT M.pmtByYearID 
					FROM		dbo.Un_Unit U 
					INNER JOIN	dbo.Un_Modal M ON M.ModalID = U.ModalID 
					WHERE	U.ConventionID = @iIdConvention 
					AND		U.UnitID = fnt.iIDUnite
					)
				,(	SELECT M.pmtQty 
					FROM		dbo.Un_Unit U 
					INNER JOIN	dbo.Un_Modal M ON M.ModalID = U.ModalID 
					WHERE	U.ConventionID = @iIdConvention 
					AND		U.UnitID = fnt.iIDUnite
					)
				,GETDATE()
				,@dtDateFin
				,ROUND(ISNULL(iq.mMntIQEEMaj, 0) * ((	SELECT SUM(f.mCotisation + f.mFrais) 
														FROM dbo.fntOPER_ObtenirCotisationFraisConvention
																	(
																	 @iIDConvention
																	,fnt.iIDUnite
																	,@dtDateEntreeVigueurIQEE
																	,@dtDateFin
																	,'E'
																	,NULL
																	,'D'
																	) f) / ISNULL(NULLIF(@mFraisCotisationTotalPrj, 0), 1)), 3) 
				,fnt.iIDUnite
				,CASE	
					WHEN odc.dtEntreeVigueur > @dtDateEntreeVigueurIQEE THEN 
						1
					ELSE 
						0
					END
				,CASE
					WHEN odc.dtEntreeVigueur > @dtDateEntreeVigueurSCEE THEN 
						1
					ELSE 
						0
					END
				,CAST(DATEDIFF(dd, @dtDateEntreeVigueurIQEE, odc.dtFinCotisation) AS NUMERIC(18, 10)) / CAST(365 AS NUMERIC(18, 10))
				,CAST(DATEDIFF(dd, @dtDateEntreeVigueurSCEE, odc.dtFinCotisation) AS NUMERIC(18, 10)) / CAST(365 AS NUMERIC(18, 10))
				,@dtEcheance
			
			FROM		dbo.fntCONV_ObtenirReleveDepotDetailsAvecGroupeUnite
								(
								 @iIDConvention
								,'1900-01-01'
								,@dtDateFin
								) fnt
			INNER JOIN	dbo.fntCONV_ObtenirDatesConvention
								(
								 @iIDConvention
								,@dtDateFin
								) odc ON fnt.iIDUnite = odc.UnitID
			INNER JOIN	dbo.fntOPER_ObtenirMntIQEERelDep
								(
								 @iIDConvention
								,'1900-01-01'
								,@dtDateFin
								) iq ON iq.iIDConvention = fnt.iIDConvention
			WHERE	NOT	(
							fnt.mFraisCotisation	= 0
						AND fnt.mFrais				= 0
						AND fnt.mSCEE				= 0
						AND fnt.mIntSCEE			= 0
						AND fnt.mSCEESup			= 0
						AND fnt.mIntSCEESup			= 0
						AND iq.mMntIQEE				= 0
						AND iq.mMntIntIQEE			= 0
						AND fnt.mBec				= 0
						AND fnt.mIntBEC				= 0
						AND fnt.mPAE				= 0
						AND fnt.mIntPAE				= 0
						AND fnt.mAutreRev			= 0
						AND fnt.mIntAutreRev		= 0
						AND fnt.vcTypeDonnee		= 'D'
						)
			AND		((	SELECT COUNT(*) 
						-- +/- 2010-25 - CM : Prise en compte des paramètres de date et non pas en dur
						--FROM dbo.fntCONV_ObtenirReleveDepotDetails(fnt.iIDConvention,CAST(CAST(YEAR(@dtDateFin) AS VARCHAR(4)) + '-01-01' AS DATETIME),CAST(CAST(YEAR(@dtDateFin) AS VARCHAR(4))+ '-12-31' AS DATETIME)) 
						FROM dbo.fntCONV_ObtenirReleveDepotDetails
									(
									 fnt.iIDConvention
									,@dtDateDebut
									,@dtDateFin
									) 
						WHERE vcTypeOperation NOT IN('REV', 'BEC')
						) = 0
					
			OR		(fnt.vcTypeOperation NOT IN ('REV','BEC'))
					
					)
		   
		   GROUP BY
				fnt.iIDUnite, 
				fnt.iIDConvention, 
				fnt.fQuantiteUnite,
				fnt.mIntSCEESup,
				fnt.mSCEE,
				fnt.mIntSCEE,
				fnt.mSCEESup,
				fnt.mBec,
				fnt.mIntBEC, 
				fnt.mPAE, 
				fnt.mIntPAE,
				fnt.vcCompagnie, 
				fnt.mAutreRev, 
				fnt.mIntAutreRev, 
				fnt.vcTypeDonnee, 
				fnt.iPayementParAnnee, 
				fnt.iNombrePayement,
				fnt.vcCompagnie,
				fnt.dtDateOperation,				
				odc.dtEntreeVigueur,
				odc.dtRembEstime,
				odc.dtFinCotisation,
				odc.dtFinRegime,
				iq.mMntIQEE,
				iq.mMntIntIQEE,
				iq.mMntIQEEMaj
		
		
		-- SUPPRESSION DES ENREGISTREMENTS INUTILES
		DELETE dbo.tblCONV_DonneeReleveDepotAvecDetailParUnite WHERE iIDConvention IS NULL

		END 
--<<T10
-- ********************** FIN DU TRAITEMENT BASÉ SUR LES GROUPES D'UNITÉS  POUR L'ESTIMÉ DES MONTANTS VERSÉS FUTURS **********************

					-- Initialisationn des variables
					SET @mFraisCotisation  = 0
					SET @mFrais = 0
					SET @mSCEE = 0
					SET @mSCEESup = 0
					SET @mBEC = 0
					SET @mIntBEC = 0
					SET @mPAE = 0
					SET @mIntPAE = 0
					SET @mAutreRev = 0
					SET @mIntAutreRev = 0
					SET @vcAnneeQualif = NULL
					SET @mBourse = 0
					SET @mMntSouscrit = 0
					SET @dtEntreeVigueur = NULL
					SET @dtRembEstime = NULL
					SET @dtFinCotisation = NULL
					SET @vcPrenomRep = NULL
					SET @vcNomRep = NULL
					SET @vcTelRep = NULL
					SET @vcPrenomDir = NULL
					SET @vcNomDir = NULL
					SET @vcTelDir = NULL
					SET @mIntSCEE = 0
					SET @mIntSCEESup = 0
					SET @mCoutEtude = 0
					SET @cSexeSouscripteur = NULL
					SET @vcPrenomSouscripteur = NULL
					SET @vcNomSouscripteur = NULL
					SET @vcAdresseSouscripteur = NULL
					SET @vcVilleSouscripteur = NULL
					SET @vcCodePostalSouscripteur = NULL
					SET @bPrincipalResponsableErreur = 0
					SET @bPrincipalResponsableManquant = 0
					SET @vcPaysSouscripteur = NULL
					SET @vcPrenomBeneficiaire = NULL
					SET @vcNomBeneficiaire = NULL
					SET @iQuantiteUnite = 0
					SET @vcRegime = NULL
					SET @iIDRegime = NULL
					SET @vcNomEtat = NULL
					SET @mMntIQEE = 0
					SET @mMntIntIQEE = 0
					SET @vcLangue = NULL
					SET @vcTextDiploma = NULL
					SET @vcDerniereAnnee = NULL
					SET @vcAvantDerniereAnnee = NULL
					--SET @iAnneeEtudeMax = NULL  
					SEt @vcParamDateBourse = NULL
					SET @iDerniereAnnee	= 0
					SET @iIDConvention  = NULL
					SET @iIDSouscripteur  = NULL
					SET @iIDBeneficiaire  = NULL
					SET @vcNumeroConvention =NULL
					SET @mMntTheoMens = 0
					SET @vcNASBenef = NULL
					SET @mMntIQEEMaj = 0
					SET @mFraisCotisationTotal = 0
					SET @dtEcheance = NULL
					SET @bSouscripteur_Desire_Releve_Elect = NULL

					UPDATE tblCONV_TMPRelDep 
						SET PROCESSED = @iNoprocess,
							dtDtHr = getdate()
					WHERE iID= @itmpID

					FETCH NEXT FROM crDepositStattement INTO @itmpID
															,@iIDConvention
															,@iIDSouscripteur
															,@iIDBeneficiaire
															,@vcNumeroConvention
															,@vcRegime
															,@iIDRegime
															,@vcTextDiploma
															,@bSouscripteur_Desire_Releve_Elect
				
				END -- end cursor

				CLOSE crDepositStattement
				DEALLOCATE crDepositStattement
						
			END  -- end while

		END	-- end if bsave
		
		--2010-05-28 :	Mise à jour du champ permettant de savoir la date de fin de la dernière génération demandée
		--IF @iSubscriberID IS NULL	-- TOUS LES SOUSCRIPTEURS
		--	BEGIN
		--		UPDATE	dbo.tblCONV_DonneeReleveDepot
		--		SET		dtDateFinGeneration	= @dtDateFin		
		--	END
		--ELSE
		--	BEGIN				-- UN SOUSCRIPTEUR EN PARTICULIER
		--		UPDATE	dbo.tblCONV_DonneeReleveDepot
		--		SET		dtDateFinGeneration	= @dtDateFin
		--		WHERE	iIDSouscripteur		= @iSubscriberID
		--	END		

		INSERT INTO tblCONV_MessagesDonneeReleveDepot (dtDtTime,vfacette,vmodule,vmess)
		
		SELECT GETDATE(),'CONV','Calcul relevé de depôt', 'Fin ObtenirDonneeReleveDepot_EXEC -   procès no: ' + CAST (@iNoprocess as varchar(10)) 
	 	 
	END TRY

	BEGIN CATCH
		DECLARE		 
				@iErrSeverite	INT
				,@iErrStatut	INT
				,@vcErrMsg		NVARCHAR(1024)
				
		SELECT
			@vcErrMsg		= REPLACE(ERROR_MESSAGE(),'%',' ')
			,@iErrStatut	= ERROR_STATE()
			,@iErrSeverite	= ERROR_SEVERITY()
			
		RAISERROR	(@vcErrMsg, @iErrSeverite, @iErrStatut) WITH LOG
	END CATCH

	RETURN
	*/
	END