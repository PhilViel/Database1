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
Copyrights (c) 2008 Gestion Universitas inc

Code de service		:		psOPER_CreerOperationRIO
Nom du service		:		Créer une operation RIO
But					:		Créer une operation individuelle et une opertaion RIO à travers differentes transactions 
							dans les tables d'uniAccés.
Facette				:		OPER
Reférence			:		UniAccés-Noyau-OPER

Parametres d'entrée :	Parametres					Description
						-----------------------------------------------------------------------------------------------------
						iID_Connexion			Identifiant
						iID_Convention			ID qui correspond au numéro de la convention collective
						iID_Unite				ID du groupe d'unités
						dtDateEstimeeRembInt	Date estimée du remboursement intégral
						dtDateConvention		Date de création et de validité de la nouvelle convention individuelle
						iID_Convention_			Identifiant de la convention de destination lorsqu'il y a déjà eu un transfert
							Destination			RIO et que l'on veux forcer la destination d'un retransfert RIO.  Cela peut
												être utilisé pour transférer les montants dans une convention individuelle
												"T" fermée par exemple.  Cette fonctionnalité n'est pas disponible aux
												utilisateurs du département des bourses.  Ce paramètre est optionnel.
						vcType_Conversion		Code du type de conversion à effectuer (RIO, RIM ou TRI). Optionnel.
						@tiByPassFrais			Indicateur pour savoir si on veut contourner la génération de frais de service

Exemple d'appel:
			DECLARE @i INT
			EXECUTE @i = [dbo].[psOPER_CreerOperationRIO]
										@iID_Connexion = 1, --ID de connection de l'usager
										@iID_Convention = 118696, --ID de la convention Source (Collective)
										@iID_Unite = 255766, -- ID de l'unite Source
										@dtDateEstimeeRembInt = N'1976-05-02', --Date estimée de remboursement
										@dtDateConvention = N'2001-06-18'-- Date de convention,
										NULL,
										'RIO',
										0
			SELECT @i

select * from un_convention order by conventionid desc

Parametres de sortie : Table						Champs								Description
					   -----------------			---------------------------			--------------------------
													@iCode_Retour						C'est un code de retour qui indique si la requête s'est terminée avec succès et si les frais sont couverts
																						= 0 erreur gérée
																						= -1 si erreur de traitement
																						
													@vcCode_Message						Message de retour lorsque le traitement se termine à 0

Historique des modifications :
			
						Date		Programmeur								Description							Référence
						----------	-------------------------------------	----------------------------		---------------
						2008-06-16	Nassim Rekkab							Création de procédure stockée
						2008-08-04	Éric Deshaies							
						2008-08-15	Jean-Francois Arial						Ajout de la validation sur la table de dépôts
						2008-11-24	Josée Parent							Modification pour utiliser la fonction "fnCONV_ObtenirDateFinRegime"
						2009-09-24	Jean-François Gauthier					Remplacement de @@Identity par Scope_Identity()
						2009-10-05	Jean-François Gauthier					Ajustement des appels à IU_UN_UNIT et IU_UN_CONVENTION afin de tenir compte des nouveaux paramètres ajoutés à ces procédures (@bTuteurDesireReleveElect et @iSous_Cat_ID_Resp_Prelevement)
						2010-01-21	Éric Deshaies							Ajout d'un paramètre pour forcer la
																			convention de destination du RIO.
						2010-01-25	Jean-François Gauthier					Modification des appels à IU_UN_CONVENTION afin d'utiliser les valeurs de la convention originales pour les
																			les champs (DiplomaTextID, bSendToCESP, iDestinationRemboursementID' vcDestinationRemboursementAutre, dtDateProspectus, bSouscripteurDesireIQEE, tiLienCoSouscripteur, bTuteurDesireReleveElect)
																			et lors de l'appel à IU_UN_UNIT pour le champ ID Unique du réprensentant responsable
			
						2010-06-02	Pierre Paquet							Ajout de la gestion du bFormulaireRecu
						2010-11-24	Donald Huppé							Ajout des iIDSourceVente de Reeeflex et "Select 2000 Plan B" (GLPI 4661)
						2010-12-01	Pierre-Luc Simard						Gestion des disable trigger par #DisableTrigger
						2011-03-11	Frédérick Thibault						Ajout des nouvelles fonctionnalités du prospectus 2010-2011 (FT1)
						2011-07-13	Frédérick Thibault						Modification des paramètres d'entrées (ajout de l'option pour bypass des frais de services pour retransferts)
						2011-07-14	Frédérick Thibault						Ajout de la convention source pour la validation pour frais de gestion (FT2)
						2011-08-11	Frédérick Thibault						Modification de l'algorithme pour le transfert de l'épargne et des frais
						2011-12-07	Frédérick Thibault						Correction Un_UnitReduction ajout des montants FeeSumByUnit et SubscInsurSumByUnit
						2012-01-04	Frédérick Thibault						Correction de l'insertion dans Un_UnitReductionCotisation pour les retransferts sur TRI et RIM
						2012-01-17	Frédérick Thibault						Transférer les subventions et les rendements en proportion des cotisations/frais transférés pour le groupe d'unité.
						2012-03-29	Frédérick Thibault						Désactivation des frais de services sur RIO et RIM (GLPI #0007309)
						2012-08-14	Frédérick Thibault						Ajout des frais disponibles utilisés sur TRI (FT3)
						2012-10-30	Frédérick Thibault						Vérification de la présence d'une convention individuelle dans la table tblCONV_ConventionConventionCategorie
						2013-01-11	Pierre-Luc Simard						Validation du nombre d'unité lors du calcul des frais par unité, pour éviter les divisions par zéro
						2013-09-13	Donald Huppé								Valider le code de retour de psOPER_GenererRendementInd et faire un ROLLBACK au besoin
						2013-10-18	Donald Huppé + Frédérick Thibault		Si on passe @iID_Convention_Destination, on ne la cherche plus dans tblOPER_OperationsRIO (voir 2013-10-18)
																							On considère que si @iID_Convention_Destination est passé en paramètre, il s'agit d'un convention valide pour un transfert RIO
						2014-10-06	Pierre-Luc Simard						On permet uniquement la création de RIM car les RIO ne sont plus permis
																							Appeler la lettre de confirmation de RIM
						2014-11-11	Pierre-Luc Simard						Ne plus enregistrer la valeur des champs tiCESPState, et CESGRequest qui sont maintenant gérés par la procédure psCONV_EnregistrerPrevalidationPCEE				
						2015-01-20	Pierre-Luc Simard						Appeler la procédure TT_UN_CESPOfConventions pour créer les 100 et les 200 car pas toujours prêt à être appelé via la IU_UN_Convention
						2015-07-29	Steve Picard							Utilisation du "Un_Convention.TexteDiplome" au lieu de la table UN_DiplomaText
                        2017-03-14  Pierre-Luc Simard                       Deprecated - On ne doit plus faire de RIO, de RIM ou de TRI
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_CreerOperationRIO]
(
	 @iID_Connexion					INTEGER				-- ID de connexion de l’usager qui demande la liste.
	,@iID_Convention				INTEGER				-- ID qui correspond au numéro de la convention collective
	,@iID_Unite						INTEGER				-- ID du groupe d'unités
	,@dtDateEstimeeRembInt			DATETIME			-- Date estimée du remboursement intégral
	,@dtDateConvention				DATETIME			-- Date de création et de validité de la nouvelle convention individuelle
	,@iID_Convention_Destination	INT			= NULL
	,@vcType_Conversion				VARCHAR(3)	= NULL	-- Code du type de conversion (RIO, RIM ou TRI) - FT1
	,@tiByPassFrais					TINYINT				-- Indicateur pour savoir si on veut contourner la génération de frais de service
)
AS
BEGIN
	/*
	DECLARE 
		@iResult							INTEGER,
		@iCode_Retour						INTEGER,
		@dtDateConventionAncienne			DATETIME,
		@iConventionDestination				INTEGER,
		@iUniteDestination					INTEGER,
		@iSousScripteur						INTEGER, 
		@iCoSousScripteur					INTEGER,
		@iBeneficiaireID					INTEGER,
		@bCESGDemande						BIT, 
		@bACESGDemande						BIT,
		@bCLBDemande						BIT,
		@tiCESPEtat							TINYINT,
		@tiRapportTypeID					TINYINT,
		@dtOperDate							DATETIME,
		@iOperRIO							INTEGER,
		@iOperTFR							INTEGER,
		@iCotisationIdRetrait				INTEGER,
		@iCotisationIdDepot					INTEGER,
		@mSommeCotisation					MONEY,

		@nRatio								DECIMAL(10,4), -- FT1
		@mCotisation						MONEY, -- FT1
		@mSommeFEE							MONEY,
		@mFeeByUnit							MONEY, -- FT1
		@mFeeSumByUnit						MONEY, -- FT3
		@mUnitUsed							MONEY, -- FT3
		@mCotisDest							MONEY, -- FT1
		@mSommeFeeDest						MONEY, -- FT1
		@mFeeDest							MONEY, -- FT1
		@vcConventionDestNo					VARCHAR(15), --FT1
		
		@bNouvelleConvention				BIT,
		@iAgeBeneficiaire					INT,
		@iPlanID							INTEGER,
		@dtDateElevee						DATETIME,
		@iIDReSiegeSocial					INTEGER,
		@iIDSourceVente						INTEGER,
		@iModalID							INTEGER,
		@vcTypeTransaction					VARCHAR(3),
		@mMontantConvention					MONEY,
		@dtDateRembours						DATETIME,
		@mfCESG								MONEY,
		@mfACESG							MONEY,
		@mfCLB								MONEY,
		@mfPG								MONEY,
		@vcStatusGroupes					VARCHAR(100),
		@dtDateNaissance					DATETIME,
		@dtAujourdhui						DATETIME,
		@dtDate_Fin_Convention_Collective	DATETIME,
		@dtDate_Fin_Convention_Individuelle	DATETIME,
		@iSousCatID							INT						-- 2009-10-05 : JFG
		,@vcConventionPrefix				VARCHAR(1)	-- FT1
		,@UnitReductionID					INT			-- FT1
		,@mMontant_Frais_TTC				MONEY		-- FT1
		,@iCode_Retour_Temp					INT			-- FT1
		,@vcCode_Type_Frais					VARCHAR(3)	-- FT1
		,@tiValid_12Mois					TINYINT		-- FT1
		,@vcCode_Message					VARCHAR(10)
		
		-- 2010-01-25 : JFG
		,@iDiplomaTextID					INT = -1		-- 2015-07-29
		,@vcDiplomaText						VARCHAR(150)	-- 2015-07-29
		,@bSendToCESP						BIT
		,@iDestinationRemboursementID		INT
		,@vcDestinationRemboursementAutre	VARCHAR(50)
		,@dtDateduProspectus				DATETIME
		,@bSouscripteurDesireIQEE			BIT
		,@tiLienCoSouscripteur				TINYINT
		,@bTuteurDesireReleveElect			BIT
		,@iRepResponsableID					INT
		,@bFormulaireRecu					INT

		,@iPlanIDCollectif					INT
	
	-- On permet uniquement la création de RIM car les RIO ne sont plus permis
	IF @vcType_Conversion <> 'RIM' 
		RETURN -1
        
	SET @iCode_Retour = 1
	SET @iModalID = -1
	
	-- Désactivation des frais de services sur RIO et RIM (GLPI #0007309)
	SET @tiByPassFrais = 1
	
	-- Déterminer la date de fin de la convention collective
	SET @dtDate_Fin_Convention_Collective = (SELECT [dbo].[fnCONV_ObtenirDateFinRegime](@iID_Convention,'R',NULL))

	-- Détermine la date de l'opération
	IF GETDATE() < @dtDateEstimeeRembInt AND @vcType_Conversion <> 'TRI' -- FT1
		SET @dtOperDate = @dtDateEstimeeRembInt
	ELSE
		SET @dtOperDate = GETDATE()

	-- Desactiver Trigger TUn_Convention_State
	IF object_id('tempdb..#DisableTrigger') is null
		CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))

	----------------------------
	BEGIN TRANSACTION
	----------------------------
	
	-------------------------------------------------------------------------------------------				
	-- Dynamique No 2 : Recherche une Convention individuelle
	-------------------------------------------------------------------------------------------
	IF @iID_Convention_Destination IS NOT NULL
		BEGIN
		/* --2013-10-18
		SELECT  @iConventionDestination		= R.iID_Convention_Destination,
				@iUniteDestination			= R.iID_Unite_Destination, 
				@dtDateConventionAncienne	= MIN(R.dtDate_Enregistrement)
				,@vcConventionDestNo		= CN.ConventionNo -- FT1
		
		FROM tblOPER_OperationsRIO R
		JOIN dbo.Un_Convention CN ON CN.ConventionID = R.iID_Convention_Destination
		
		WHERE	R.iID_Convention_Source			= @iID_Convention
		AND		R.iID_Convention_Destination	= @iID_Convention_Destination
		AND		R.bRIO_QuiAnnule				= 0
		
		GROUP BY R.iID_Convention_Destination
				,R.iID_Unite_Destination
				,CN.ConventionNo
		*/

		SELECT  @iConventionDestination		= CN.conventionid,
				@iUniteDestination			= max(u.UnitID),
				@vcConventionDestNo		= CN.ConventionNo -- FT1
		
		FROM dbo.Un_Convention CN 
		join dbo.Un_Unit u ON CN.conventionid = u.ConventionID
		
		WHERE	CN.conventionid			= @iID_Convention_Destination
		group by CN.conventionID, CN.ConventionNo 
		
		IF @@ROWCOUNT = 0 
			SET @vcConventionDestNo = NULL
		
		END
	ELSE
		BEGIN
		
		SELECT   @iConventionDestination		= OperRIO.iID_Convention_Destination
				,@iUniteDestination				= OperRIO.iID_Unite_Destination
				,@dtDateConventionAncienne		= MIN(OperRIO.dtDate_Enregistrement)
				,@vcConventionDestNo			= C2.ConventionNo -- FT1
		
		FROM		tblOPER_OperationsRIO OperRIO
		JOIN		Un_Convention C					ON C.ConventionID  = @iID_Convention
		JOIN		Un_Convention C2				ON C2.ConventionID = OperRIO.iID_Convention_Destination
		JOIN		Un_ConventionConventionState CS	ON CS.ConventionID = C2.ConventionID 
		LEFT JOIN	Mo_Human H						ON C.BeneficiaryID = H.HumanId
		LEFT JOIN	Mo_Human H2						ON C2.BeneficiaryID = H2.HumanId
		LEFT JOIN	Mo_Adr AH						ON H.AdrID = AH.AdrId
		LEFT JOIN	Mo_Adr AH2						ON H2.AdrId = AH2.AdrId
		LEFT JOIN	Mo_Human HS						ON C.SubscriberID = HS.HumanId
		LEFT JOIN	Mo_Human HS2					ON C2.SubscriberID = HS2.HumanId
		LEFT JOIN	Mo_Adr AHS						ON HS.AdrID = AHS.AdrId
		LEFT JOIN	Mo_Adr AHS2						ON HS2.AdrId = AHS2.AdrId
		LEFT JOIN	Mo_Human HCS					ON C.CoSubscriberID = HCS.HumanId
		LEFT JOIN	Mo_Human HCS2					ON C2.CoSubscriberID = HCS2.HumanId
		LEFT JOIN	Mo_Adr AHCS						ON HCS.AdrID = AHCS.AdrId
		LEFT JOIN	Mo_Adr AHCS2					ON HCS2.AdrId = AHCS2.AdrId
		
		WHERE	OperRIO.bRIO_QuiAnnule = 0
		
		AND		(C.BeneficiaryID		= C2.BeneficiaryID 
					OR H.SocialNumber	= H2.SocialNumber 
					OR (H.LastName		= H2.LastName 
								AND H.FirstName = H2.FirstName 
								AND H.BirthDate= H2.BirthDate 
								AND H.SexId = H2.SexId 
								AND AH.ZipCode=AH2.ZipCode))
		
		AND		(ISNULL(C.SubscriberID,0)	= ISNULL(C2.SubscriberID,0)
					OR HS.SocialNumber		= HS2.SocialNumber 
					OR (HS.LastName			= HS2.LastName 
								AND HS.FirstName	= HS2.FirstName 
								AND HS.BirthDate	= HS2.BirthDate 
								AND HS.SexId		= HS2.SexId 
								AND AHS.ZipCode		= AHS2.ZipCode))
		
		AND		(ISNULL(C.CoSubscriberID,0)	= ISNULL(C2.CoSubscriberID,0)
					OR HCS.SocialNumber		= HCS2.SocialNumber 
					OR (HCS.LastName		= HCS2.LastName 
								AND HCS.FirstName	= HCS2.FirstName 
								AND HCS.BirthDate	= HCS2.BirthDate 
								AND HCS.SexId		= HCS2.SexId 
								AND AHCS.ZipCode	= AHCS2.ZipCode))
		
		AND		CS.StartDate = (SELECT MAX(StartDate)
								FROM Un_ConventionConventionState CS2
								WHERE CS2.ConventionID = C2.ConventionID)
		
		AND		CS.ConventionStateID <> 'FRM'
		
		GROUP BY OperRIO.iID_Convention_Destination
				,OperRIO.iID_Unite_Destination 
				,C2.ConventionNo
		
		IF @@ROWCOUNT > 0 
			BEGIN
			
			-- Pour regrouper les types de conversion avec les bonnes conventions individuelles - FT1
			IF @vcType_Conversion = 'RIO'
				IF left(@vcConventionDestNo, 1) <> 'T'
					SET @vcConventionDestNo = NULL
			IF @vcType_Conversion = 'RIM'
				IF left(@vcConventionDestNo, 1) <> 'M'
					SET @vcConventionDestNo = NULL
			IF @vcType_Conversion = 'TRI'
				IF left(@vcConventionDestNo, 1) <> 'I'
					SET @vcConventionDestNo = NULL
			
			END
		ELSE
			BEGIN
			
			-- FT 2012-10-30 - Si rien trouvé on "fouille" dans la catégorie de convention R17
			SELECT   @iConventionDestination		= CCC.ConventionId
					,@iUniteDestination				= U.UnitID
					,@vcConventionDestNo			= C2.ConventionNo
			
			FROM		tblCONV_ConventionConventionCategorie CCC
			JOIN		tblCONV_ConventionCategorie	CC	ON CC.ConventionCategoreId = CCC.ConventionCategorieId
			JOIN		Un_Convention C					ON C.ConventionID  = @iID_Convention
			JOIN		Un_Convention C2				ON C2.ConventionID = CCC.ConventionId
			JOIN		Un_Unit U						ON U.ConventionID = CCC.ConventionId
			JOIN		Un_ConventionConventionState CS	ON CS.ConventionID = C2.ConventionID 
			LEFT JOIN	Mo_Human H						ON C.BeneficiaryID = H.HumanId
			LEFT JOIN	Mo_Human H2						ON C2.BeneficiaryID = H2.HumanId
			LEFT JOIN	Mo_Adr AH						ON H.AdrID = AH.AdrId
			LEFT JOIN	Mo_Adr AH2						ON H2.AdrId = AH2.AdrId
			LEFT JOIN	Mo_Human HS						ON C.SubscriberID = HS.HumanId
			LEFT JOIN	Mo_Human HS2					ON C2.SubscriberID = HS2.HumanId
			LEFT JOIN	Mo_Adr AHS						ON HS.AdrID = AHS.AdrId
			LEFT JOIN	Mo_Adr AHS2						ON HS2.AdrId = AHS2.AdrId
			LEFT JOIN	Mo_Human HCS					ON C.CoSubscriberID = HCS.HumanId
			LEFT JOIN	Mo_Human HCS2					ON C2.CoSubscriberID = HCS2.HumanId
			LEFT JOIN	Mo_Adr AHCS						ON HCS.AdrID = AHCS.AdrId
			LEFT JOIN	Mo_Adr AHCS2					ON HCS2.AdrId = AHCS2.AdrId
			
			WHERE	CC.CategorieCode = 'R17'
			
			AND		(C.BeneficiaryID		= C2.BeneficiaryID 
						OR H.SocialNumber	= H2.SocialNumber 
						OR (H.LastName		= H2.LastName 
									AND H.FirstName = H2.FirstName 
									AND H.BirthDate= H2.BirthDate 
									AND H.SexId = H2.SexId 
									AND AH.ZipCode=AH2.ZipCode))
			
			AND		(ISNULL(C.SubscriberID,0)	= ISNULL(C2.SubscriberID,0)
						OR HS.SocialNumber		= HS2.SocialNumber 
						OR (HS.LastName			= HS2.LastName 
									AND HS.FirstName	= HS2.FirstName 
									AND HS.BirthDate	= HS2.BirthDate 
									AND HS.SexId		= HS2.SexId 
									AND AHS.ZipCode		= AHS2.ZipCode))
			
			AND		(ISNULL(C.CoSubscriberID,0)	= ISNULL(C2.CoSubscriberID,0)
						OR HCS.SocialNumber		= HCS2.SocialNumber 
						OR (HCS.LastName		= HCS2.LastName 
									AND HCS.FirstName	= HCS2.FirstName 
									AND HCS.BirthDate	= HCS2.BirthDate 
									AND HCS.SexId		= HCS2.SexId 
									AND AHCS.ZipCode	= AHCS2.ZipCode))
			
			AND		CS.StartDate = (SELECT MAX(StartDate)
									FROM Un_ConventionConventionState CS2
									WHERE CS2.ConventionID = C2.ConventionID)
			
			AND		CS.ConventionStateID <> 'FRM'
			
			GROUP BY C2.ConventionNo
					,CCC.ConventionId
					,U.UnitID

			IF @@ROWCOUNT = 0 
				SET @vcConventionDestNo = NULL

			END
			
		END
	
	-- Pour un TRI, on vérifie la présence d'une convention "I" existante (n'ayant PAS fait l'objet d'une conversion)
	IF @vcConventionDestNo IS NULL AND @vcType_Conversion = 'TRI'
		BEGIN
		
		SELECT   @iConventionDestination		= CInd.ConventionID 
				,@iUniteDestination				= UInd.UnitID
				,@vcConventionDestNo			= CInd.ConventionNo
		
		FROM		Un_Convention CInd
		JOIN		Un_Convention CCol				ON CCol.ConventionID  = @iID_Convention
		JOIN		Un_Unit UInd					ON UInd.ConventionID = CInd.ConventionID 
		JOIN		Un_ConventionConventionState CS	ON CS.ConventionID = CInd.ConventionID
		LEFT JOIN	Mo_Human H						ON CCol.BeneficiaryID = H.HumanId
		LEFT JOIN	Mo_Human H2						ON CInd.BeneficiaryID = H2.HumanId
		LEFT JOIN	Mo_Adr AH						ON H.AdrID = AH.AdrId
		LEFT JOIN	Mo_Adr AH2						ON H2.AdrId = AH2.AdrId
		LEFT JOIN	Mo_Human HS						ON CCol.SubscriberID = HS.HumanId
		LEFT JOIN	Mo_Human HS2					ON CInd.SubscriberID = HS2.HumanId
		LEFT JOIN	Mo_Adr AHS						ON HS.AdrID = AHS.AdrId
		LEFT JOIN	Mo_Adr AHS2						ON HS2.AdrId = AHS2.AdrId
		LEFT JOIN	Mo_Human HCS					ON CCol.CoSubscriberID = HCS.HumanId
		LEFT JOIN	Mo_Human HCS2					ON CInd.CoSubscriberID = HCS2.HumanId
		LEFT JOIN	Mo_Adr AHCS						ON HCS.AdrID = AHCS.AdrId
		LEFT JOIN	Mo_Adr AHCS2					ON HCS2.AdrId = AHCS2.AdrId
		
		WHERE CInd.ConventionNo LIKE 'I-%'
		
		AND		(CCol.BeneficiaryID		= CInd.BeneficiaryID 
					OR H.SocialNumber	= H2.SocialNumber 
					OR (H.LastName		= H2.LastName AND H.FirstName = H2.FirstName AND H.BirthDate= H2.BirthDate AND H.SexId = H2.SexId AND AH.ZipCode=AH2.ZipCode))
		
		AND		(ISNULL(CCol.SubscriberID,0)	= ISNULL(CInd.SubscriberID,0)
					OR HS.SocialNumber		= HS2.SocialNumber 
					OR (HS.LastName			= HS2.LastName 
								AND HS.FirstName	= HS2.FirstName 
								AND HS.BirthDate	= HS2.BirthDate 
								AND HS.SexId		= HS2.SexId 
								AND AHS.ZipCode		= AHS2.ZipCode))
		
		AND		(ISNULL(CCol.CoSubscriberID,0)	= ISNULL(CInd.CoSubscriberID,0)
					OR HCS.SocialNumber		= HCS2.SocialNumber 
					OR (HCS.LastName		= HCS2.LastName 
								AND HCS.FirstName	= HCS2.FirstName 
								AND HCS.BirthDate	= HCS2.BirthDate 
								AND HCS.SexId		= HCS2.SexId 
								AND AHCS.ZipCode	= AHCS2.ZipCode))
		
		AND		CS.StartDate = (SELECT MAX(StartDate)
								FROM Un_ConventionConventionState CS2
								WHERE CS2.ConventionID = CInd.ConventionID)
		
		AND		CS.ConventionStateID <> 'FRM'
		
		GROUP BY CInd.ConventionID 
				,UInd.UnitID
				,CInd.ConventionNo
		
		IF @@ROWCOUNT = 0
			SET @vcConventionDestNo = NULL
		
		END

	-- Si une convention individuelle (destination) a été trouvée on utilise celle-ci
	IF @vcConventionDestNo IS NOT NULL
		BEGIN

		-------------------------------------------------------------------------------------------
		-- Dynamique No 3 : Mise à jour de la date de fin du régime
		-------------------------------------------------------------------------------------------
		-- Pour indiquer qu'il ne s'agit pas d'une nouvelle convention
		SET @bNouvelleConvention = 0

		-- Déterminer la date de fin de la convention individuelle
		SET @dtDate_Fin_Convention_Individuelle = (SELECT [dbo].[fnCONV_ObtenirDateFinRegime](@iConventionDestination,'R',NULL))

		IF @dtDate_Fin_Convention_Collective < @dtDate_Fin_Convention_Individuelle
			EXEC @iCode_Retour = IU_UN_ConvRegEndDateAdjust @iConventionDestination, @dtDate_Fin_Convention_Collective

		IF @@Error <> 0
			GOTO END_TRANSACTION
		
		-------------------------------------------------------------------------------------------
		-- Mise à jour du code de type de conversion - FT1
		-------------------------------------------------------------------------------------------
		IF @vcType_Conversion IS NULL
			SET @vcType_Conversion = (	SELECT MAX(OperTypeID)
										FROM tblOPER_OperationsRIO
										WHERE iID_Convention_Destination = @iConventionDestination
									 )
		
		IF @@Error <> 0 OR @vcType_Conversion IS NULL
			GOTO END_TRANSACTION
			
		-------------------------------------------------------------------------------------------
		-- Dynamique No 5 : Vérification si des frais de gestion doivent être appliqués - FT1
		-------------------------------------------------------------------------------------------
		-- Si transfert RIO ou RIM on va chercher le montant de frais de gestion
		IF	(@vcType_Conversion = 'RIO' OR @vcType_Conversion = 'RIM') AND @tiByPassFrais = 0
			BEGIN
			
			SET @tiValid_12Mois = (SELECT dbo.fnGENE_ObtenirParametre (
							'OPER_VALIDATION_12_MOIS'
							
							--,(	SELECT Un_Convention.dtRegStartDate 
							--	FROM dbo.Un_Convention 
							--	WHERE ConventionID = @iConventionDestination)
							,@dtOperDate
							
							,NULL
							,NULL
							,NULL
							,NULL
							,NULL))
			
			IF @tiValid_12Mois = 0
				BEGIN
				
				-- Vérification : Doit être une convention collective ET une date RI des unités différentes
				DECLARE	 @dtRioOperDate		DATETIME
						,@vcIDConventionSrc	INTEGER

				SELECT	 @dtRioOperDate		= MIN(OP.OperDate)
						,@vcIDConventionSrc	= RIO.iID_Convention_Source
				FROM Un_Unit				UN
				JOIN Un_Convention			CN	ON		CN.ConventionID = UN.ConventionID 
				JOIN tblOPER_OperationsRIO	RIO	ON		RIO.iID_Convention_Destination = CN.ConventionID 
												AND		RIO.iID_Convention_Source = @iID_Convention -- (FT2)
												AND		RIO.bRIO_QuiAnnule = 0
												AND		RIO.bRIO_Annulee = 0
				JOIN Un_Oper OP ON OP.OperID = RIO.iID_Oper_RIO 
				WHERE	CN.ConventionID = @iConventionDestination
				GROUP BY RIO.iID_Convention_Source
				
				IF ISNULL(@vcIDConventionSrc, '') <> @iID_Convention
				OR datediff(day, @dtRioOperDate, @dtOperDate) > 1
					BEGIN
					
					IF (SELECT UPPER(PlanDesc)
						FROM Un_Plan PL
						JOIN dbo.Un_Convention CN ON CN.PlanID = PL.PlanID
						WHERE CN.ConventionID = @iID_Convention
						) NOT LIKE '%REEEFLEX%'
							BEGIN
							
							SET @vcCode_Type_Frais = 'CUI'
							
							END
					ELSE
							BEGIN
							
							SET @vcCode_Type_Frais = 'CRI'
							
							END

					-- Obtention du montant de frais qui sera soutiré du capital suite au transfert
					EXEC @iCode_Retour_Temp = dbo.psOPER_SimulerMontantOperationFrais
													 @vcCode_Type_Frais = @vcCode_Type_Frais
													,@mMontant_Frais = NULL
													,@mMontant_Frais_TTC	= @mMontant_Frais_TTC OUTPUT
													,@vcCode_Message		= @vcCode_Message OUTPUT

					IF @iCode_Retour_Temp <> 1
						BEGIN
						
						SET @mMontant_Frais_TTC = 0
						
						END
					
					END
				ELSE
					BEGIN
					
					SET @mMontant_Frais_TTC = 0
					
					END
				END
			ELSE
				BEGIN
				
				SET @mMontant_Frais_TTC = 0
				
				END
			
			END												
		ELSE
			BEGIN
			
			SET @mMontant_Frais_TTC = 0
			
			END

		END
	ELSE
		BEGIN
		
		-- Pour indiquer qu'il s'agit d'une nouvelle convention
		SET @bNouvelleConvention = 1

		-------------------------------------------------------------------------------------------
		-- Dynamique No 5 : Vérification si des frais de gestion doivent être appliqués - FT1
		-------------------------------------------------------------------------------------------
		-- Si transfert RIO ou RIM on va chercher le montant de frais de gestion
		IF	(@vcType_Conversion = 'RIO' OR @vcType_Conversion = 'RIM') AND @tiByPassFrais = 0
			BEGIN
			
			SET @tiValid_12Mois = (SELECT dbo.fnGENE_ObtenirParametre (
							'OPER_VALIDATION_12_MOIS'
							--,@dtDateConvention
							,@dtOperDate
							,NULL
							,NULL
							,NULL
							,NULL
							,NULL))
			
			IF @tiValid_12Mois = 0
				BEGIN
				
				IF (SELECT UPPER(PlanDesc)
					FROM Un_Plan PL
					JOIN dbo.Un_Convention CN ON CN.PlanID = PL.PlanID
					WHERE CN.ConventionID = @iID_Convention
					) NOT LIKE '%REEEFLEX%'
						BEGIN
						
						SET @vcCode_Type_Frais = 'CUI'
						
						END
				ELSE
						BEGIN
						
						SET @vcCode_Type_Frais = 'CRI'
						
						END

				-- Obtention du montant de frais qui sera soutiré du capital suite au transfert
				EXEC @iCode_Retour_Temp = dbo.psOPER_SimulerMontantOperationFrais
												 @vcCode_Type_Frais = @vcCode_Type_Frais
												,@mMontant_Frais = NULL
												,@mMontant_Frais_TTC	= @mMontant_Frais_TTC OUTPUT
												,@vcCode_Message		= @vcCode_Message OUTPUT

				IF @iCode_Retour_Temp <> 1
					BEGIN
					
					--SET @iCode_Retour = -2
					--GOTO END_TRANSACTION
					SET @mMontant_Frais_TTC = 0
					
					END
				
				END
			ELSE
				BEGIN
				
				SET @mMontant_Frais_TTC = 0
				
				END
			
			END												
		ELSE
			BEGIN
			
			SET @mMontant_Frais_TTC = 0
			
			END
			
		-------------------------------------------------------------------------------------------
		-- Dynamique No 7 : Créer la nouvelle convention individuelle
		---------------------------------------------------------------------------------------------
		SELECT	 @iSousScripteur	= C.SubscriberID
				,@iCoSousScripteur	= C.CoSubscriberID
				,@iBeneficiaireID	= C.BeneficiaryID
				,@bCESGDemande		= C.bCESGRequested
				,@bACESGDemande		= C.bACESGRequested
				,@bCLBDemande		= C.bCLBRequested
				,@tiCESPEtat		= C.tiCESPState
				,@tiRapportTypeID	= C.tiRelationshipTypeID
				,@iSousCatID		= C.iSous_Cat_ID_Resp_Prelevement					-- 2009-10-05 JFG
				,@bFormulaireRecu	= C.bFormulaireRecu
		
		FROM	dbo.Un_Convention C
		WHERE C.ConventionID = @iID_Convention
		
		--;DISABLE TRIGGER TUn_Convention_State ON Un_Convention 
		INSERT INTO #DisableTrigger VALUES('TUn_Convention_State')		
		
		--Appel de la storedProc IU_UN_Convention pour créer nouvelle convention
		-- EXEC  @iConventionDestination = IU_UN_Convention @iID_Connexion,0,@iSousScripteur,@iCoSousScripteur,@iBeneficiaireID,4,'T',@dtDateConvention,'CHQ',NULL,0,1,@bCESGDemande,@bACESGDemande,@bCLBDemande,@tiCESPEtat,@tiRapportTypeID,NULL,NULL,NULL,NULL,NULL,NULL
		
		-- 2009-10-05	: JFG
		IF (@iSousCatID IS NULL) AND (@iID_Unite IS NOT NULL)	-- RECHERCHE DANS LES UNITÉS
			BEGIN
			
			SELECT @iSousCatID = u.iSous_Cat_ID
			FROM dbo.Un_Unit u
			WHERE u.UnitID = @iID_Unite
			
			END

		-- 2010-01-25 : JFG : RÉCUPÉRER LES INFORMATIONS DE LA CONVENTION INITIALE
		SELECT	 @vcDiplomaText						= c.TexteDiplome				-- 2015-07-29
				--,@iDiplomaTextID					= c.DiplomaTextID				-- 2015-07-29
				,@bSendToCESP						= c.bSendToCESP
				,@iDestinationRemboursementID		= c.iID_Destinataire_Remboursement
				,@vcDestinationRemboursementAutre	= c.vcDestinataire_Remboursement_Autre
				,@dtDateduProspectus				= c.dtDateProspectus
				,@bSouscripteurDesireIQEE			= c.bSouscripteur_Desire_IQEE
				,@tiLienCoSouscripteur				= c.tiID_Lien_CoSouscripteur
				,@bTuteurDesireReleveElect			= c.bTuteur_Desire_Releve_Elect
				,@iPlanIDCollectif					= c.PlanID
		
		FROM dbo.Un_Convention c
		
		WHERE c.ConventionID = @iID_Convention
		
		-- 2011-03-11 : FT : Sélection du préfix de convention selon le type de conversion
		SELECT @vcConventionPrefix = CASE
										WHEN @vcType_Conversion = 'RIO' THEN
											'T'
										WHEN @vcType_Conversion = 'RIM' THEN
											'M'
										WHEN @vcType_Conversion = 'TRI' THEN
											'I'
									END
									
		IF @vcConventionPrefix IS NULL
			GOTO ROLLBACK_SECTION
		
		EXEC  @iConventionDestination = dbo.IU_UN_Convention 
												@iID_Connexion		-- @ConnectID 
												,0					-- @ConventionID
												,@iSousScripteur	-- @SubscriberID
												,@iCoSousScripteur	-- @CoSubscriberID
												,@iBeneficiaireID	-- @BeneficiaryID
												,4					-- @PlanID
												
												-- FT1
												--,'T'				-- @ConventionNo
												,@vcConventionPrefix
												
												,@dtDateConvention	-- @PmtDate
												,'CHQ'				-- @PmtTypeID
												,NULL				-- @GovernmentRegDate
												,@iDiplomaTextID	-- @DiplomaTextID
												,@bSendToCESP		-- @bSendToCESP			-- Champ boolean indiquant si la convention doit être envoyée au PCEE (1) ou non (0).
												,0 --@bCESGDemande		-- @bCESGRequested		-- SCEE voulue (1) ou non (2)
												,0 --@bACESGDemande		-- @bACESGRequested		-- SCEE+ voulue (1) ou non (2)
												,0 --@bCLBDemande		-- @bCLBRequested		-- BEC voulu (1) ou non (2)
												,0 --@tiCESPEtat		-- @tiCESPState			-- État de la convention au niveau des pré-validations. (0 = Rien ne passe , 1 = Seul la SCEE passe, 2 = SCEE et BEC passe, 3 = SCEE et SCEE+ passe et 4 = SCEE, BEC et SCEE+ passe)
												,@tiRapportTypeID	-- @tiRelationshipTypeID -- ID du lien de parenté entre le souscripteur et le bénéficiaire.
												,@vcDiplomaText		-- 2015-07-29		NULL				-- @DiplomaText			-- Texte du diplòme
												,@iDestinationRemboursementID		-- @iDestinationRemboursementID
												,@vcDestinationRemboursementAutre	-- @vcDestinationRemboursementAutre
												,@dtDateduProspectus				-- @dtDateduProspectus
												,@bSouscripteurDesireIQEE			-- @bSouscripteurDesireIQEE
												,@tiLienCoSouscripteur				-- @tiLienCoSouscripteur
												,@bTuteurDesireReleveElect			-- @bTuteurDesireReleveElect	
												,@iSousCatID						-- @iSous_Cat_ID_Resp_Prelevement	
												,0 --@bFormulaireRecu					-- @FormulaireRecu

		IF @@Error <> 0
			GOTO ROLLBACK_SECTION

		-- Mettre à jour l'état des prévalidations et les CESRequest de la convention
		EXEC @iCode_Retour = psCONV_EnregistrerPrevalidationPCEE @iID_Connexion, @iConventionDestination, NULL, NULL, NULL

		IF @@Error <> 0 OR @iCode_Retour <= 0
			GOTO ROLLBACK_SECTION

		-------------------------------------------------------------------------------------------
		-- Dynamique No 8 : Mise à jour de la date de debut du régime de la convention individuelle
		-------------------------------------------------------------------------------------------
		UPDATE dbo.Un_Convention 
		SET dtRegStartDate = @dtDateConvention
		WHERE ConventionID  = @iConventionDestination 

		IF @@Error <> 0
			GOTO ROLLBACK_SECTION
		
		-------------------------------------------------------------------------------------------
		-- Dynamique No 9 : Mise à jour de la date de fin du régime de la convention individuelle
		-------------------------------------------------------------------------------------------
		EXEC @iCode_Retour = IU_UN_ConvRegEndDateAdjust @iConventionDestination,@dtDate_Fin_Convention_Collective

		IF @@Error <> 0
			GOTO ROLLBACK_SECTION
		
		-------------------------------------------------------------------------------------------
		-- Dynamique No 10 : Creer Groupe d'unités à la nouvelle convention individuelle
		-------------------------------------------------------------------------------------------
		--Identifiant de Modalite de Paiement PlanID
		SELECT @iPlanID = C.PlanID
		FROM dbo.Un_Convention C
		WHERE C.ConventionID = @iConventionDestination

		--Date de naissance du bénéficiaire
		SELECT @dtDateNaissance = MH.BirthDate
		FROM dbo.Mo_Human MH
		WHERE HumanId = @iBeneficiaireID

		SET @dtAujourdhui = GETDATE()

		-- Appel de la fonction pour avoir l'age du beneficiaire
		EXEC @iAgeBeneficiaire = fn_Mo_Age @dtDateNaissance, @dtAujourdhui

		IF @@Error <> 0
			GOTO ROLLBACK_SECTION

		--Va chercher la date la plus élevée pour la modalité
		SELECT @dtDateElevee = MAX(Mod.ModalDate)
		FROM Un_Modal Mod
		
		WHERE	Mod.PlanID				= @iPlanID
		AND		Mod.PmtbyYearID			= 1
		AND		Mod.PmtQty				= 1 
		AND		Mod.BenefAgeOnBegining	= @iAgeBeneficiaire
		
		-- Identifiant unique de modalite  ModalID
		SELECT @iModalID = Mod.ModalID
		FROM Un_Modal Mod
		
		WHERE	Mod.PlanID = @iPlanID
		AND		Mod.ModalDate = @dtDateElevee
		AND		Mod.PmtbyYearID = 1
		AND		Mod.PmtQty = 1 
		AND		Mod.BenefAgeOnBegining = @iAgeBeneficiaire
		
		IF @iModalID < 0 
			BEGIN
			
			SET @iCode_Retour = -2
			GOTO ROLLBACK_SECTION
			
			END

		--Identifiant du representant du Siege Social
		SELECT @iIDReSiegeSocial = de.iID_Rep_Siege_Social
		FROM Un_Def de

		IF @vcType_Conversion = 'RIO' -- FT1
			BEGIN
		
			--Identifiant de la souce de vente avec une description commencant par SYS-RIO
			IF @iPlanIDCollectif IN(8)
				BEGIN
			
				SELECT @iIDSourceVente = sas.SaleSourceID
				FROM Un_SaleSource sas
				WHERE SaleSourceDesc LIKE ('SYS-RIO%') AND SaleSourceDesc LIKE ('%Universitas%')
				
				END
			
			IF @iPlanIDCollectif IN (10,12)
				BEGIN
			
				SELECT @iIDSourceVente = sas.SaleSourceID
				FROM Un_SaleSource sas
				WHERE SaleSourceDesc LIKE ('SYS-RIO%') AND SaleSourceDesc LIKE ('%Reeeflex%')
				
				END
			
			IF @iPlanIDCollectif IN (11)
				BEGIN
			
				SELECT @iIDSourceVente = sas.SaleSourceID
				FROM Un_SaleSource sas
				WHERE SaleSourceDesc LIKE ('SYS-RIO%') AND SaleSourceDesc LIKE ('%Plan B%')
				
				END
			
			END
			
		-- FT1
		IF @vcType_Conversion = 'RIM'
			BEGIN
		
			--Identifiant de la souce de vente avec une description commencant par SYS-RIM
			SELECT @iIDSourceVente = sas.SaleSourceID
			FROM Un_SaleSource sas
			WHERE SaleSourceDesc LIKE ('SYS-RIM%')
			
			END

		-- FT1
		IF @vcType_Conversion = 'TRI'
			BEGIN
		
			--Identifiant de la souce de vente avec une description commencant par SYS-TRI
			SELECT @iIDSourceVente = sas.SaleSourceID
			FROM Un_SaleSource sas
			WHERE SaleSourceDesc LIKE ('SYS-TRI%')
			
			END
			
		-- Desactiver Trigger TUn_Unit_State
		--;DISABLE TRIGGER TUn_Unit_State ON Un_Unit 
		INSERT INTO #DisableTrigger VALUES('TUn_Unit_State')

		--Appel du service IU_UN_Unit
		-- EXEC @iUniteDestination = IU_UN_Unit @iID_Connexion,0,@iConventionDestination,@iModalID,1,@dtDateConvention,@dtDateConvention,NULL,NULL,NULL,0,@iID_Connexion,@iID_Connexion,@iIDReSiegeSocial,NULL,0,@iIDSourceVente,NULL
		
		-- 2010-01-25 : JFG : RÉCUPÉRATION DU REPRÉSENTANT RESPONSABLE DE LA CONVENTION ORIGINAL
		SELECT @iRepResponsableID = u.RepResponsableID
		FROM dbo.Un_Unit u
		WHERE u.ConventionID = @iID_Convention

		-- 2009-10-05 : JFG
		EXEC @iUniteDestination = IU_UN_Unit 
										@iID_Connexion				-- ID unique de connexion de l'usager
										,0							-- ID Unique du groupe d'unités (= 0 si on veut le créer)
										,@iConventionDestination	-- ID Unique de la convention à laquel appartient le groupe d'unités
										,@iModalID					-- ID Unique de la modalité de paiement
										,1							-- Quantité d'unités
										,@dtDateConvention			-- Date de mise en vigueur
										,@dtDateConvention			-- Date de la signature du contrat
										,NULL						-- Date du remboursement intégral (Null s'il n'a pas encore eu lieu)
										,NULL						-- Date de la résiliation (Null si elle n'a pas encore eu lieu)
										,NULL						-- ID Unique de l'assurance bénéficiaire (Null s'il n'y en a pas)
										,0							-- Champ boolean déterminant si le souscripteur à de l'assurance souscripteur ou non
										,@iID_Connexion				-- ID Unique de connection de l'usager qui à activé le groupe d'unités (Null si pas actif)
										,@iID_Connexion				-- ID Unique de connection de l'usager qui à validé le groupe d'unités (Null si pas valid‚)
										,@iIDReSiegeSocial			-- ID Unique du représentant qui a fait la vente
										,@iRepResponsableID			-- ID Unique du représentant responsable du représentant qui a fait la ventes s'il y a lieu.
										,0							-- Montant à ajouter au montant souscrit réel dans les relevés de dépôts
										,@iIDSourceVente			-- ID unique d'une source de vente de la table Un_SaleSource
										,NULL						-- Date de dernier dépôt pour relevé et contrat
										,@iSousCatID				-- ID de catégorie de groupe d'unités

		IF @@Error <> 0
				GOTO ROLLBACK_SECTION

		-------------------------------------------------------------------------------------------
		-- Dynamique No 11 : Mise à jour du groupe d'unite crée à l'etape 6
		-------------------------------------------------------------------------------------------
		-- mise à jour de la table Unit (StopRepComConnectID)
		UPDATE dbo.Un_Unit 
		SET StopRepComConnectID = @iID_Connexion
		WHERE UnitID = @iUniteDestination
		
		IF @@Error <> 0
				GOTO ROLLBACK_SECTION

		END

	-------------------------------------------------------------------------------------------
	-- Dynamique No 12 : Création de l'opération (RIO, RIM ou TRI)
	-------------------------------------------------------------------------------------------
	--IF GETDATE() < @dtDateEstimeeRembInt AND @vcType_Conversion <> 'TRI' -- FT1
	--	SET @dtOperDate = @dtDateEstimeeRembInt
	--ELSE
	--	SET @dtOperDate = GETDATE()

	--Appel de la storedProc SP_IU_UN_Oper pour créer l'opération
	EXEC @iOperRIO = SP_IU_UN_Oper	 @iID_Connexion
									,0
									
									--  FT1
									--,'RIO'
									,@vcType_Conversion
									
									,@dtOperDate

	IF @@Error <> 0
			GOTO ROLLBACK_SECTION

	-------------------------------------------------------------------------------------------
	-- Dynamique No 13 : Création la transaction de retrait des épargnes et frais des cotisations pour la convention collective
	-------------------------------------------------------------------------------------------
	-- Desactiver Trigger TUn_Cotisation_State et TUn_Cotisation_Doc
	--;DISABLE TRIGGER TUn_Cotisation_State ON Un_Cotisation
	--;DISABLE TRIGGER TUn_Cotisation_Doc ON Un_Cotisation
	INSERT INTO #DisableTrigger VALUES('TUn_Cotisation_Doc')				
	INSERT INTO #DisableTrigger VALUES('TUn_Cotisation_State')		
	
	--Calcul de la somme des cotisations et des fee déjà inscrits
	SELECT	 @mSommeCotisation	= SUM(C.Cotisation)
			,@mSommeFee			= SUM(C.Fee)
			,@mFeeSumByUnit		= round(SUM(C.Fee) / CASE WHEN U.UnitQty = 0 THEN 1 ELSE U.UnitQty END, 2)
	FROM Un_Cotisation C
	JOIN dbo.Un_Unit U ON U.UnitID = C.UnitID
	WHERE C.UnitID = @iID_Unite
	GROUP BY U.UnitQty
	
	-- Calcul du ratio des cotisations transférées versus les cotisations totales à la convention
	-- Cette valeur sera utilisée plus loin afin de déterminer les montants de subventions à transférer
	IF @mSommeCotisation + @mSommeFee > 0.00
		SET @nRatio = (@mSommeCotisation + @mSommeFee) / ISNULL((	SELECT SUM(CT.Cotisation) + SUM(CT.Fee)
																	FROM Un_Cotisation CT
																	JOIN dbo.Un_Unit UN ON UN.UnitID = CT.UnitID
																	JOIN dbo.Un_Convention CN ON CN.ConventionID = UN.ConventionID
																	WHERE CN.ConventionID = @iID_Convention
																	), @mSommeCotisation + @mSommeFee)
	ELSE
		SET @nRatio = 1.0
	
	-- Inversion des montants pour le retrait
	SET @mSommeCotisation = @mSommeCotisation * -1
	SET @mSommeFee = @mSommeFee * -1
	
	SET @iCotisationIdRetrait	= NULL
	SET @iCotisationIdDepot		= NULL

	-- FT1
	IF @vcType_Conversion = 'TRI'
		BEGIN
		
		DECLARE @tblFDI TABLE
					(
					 mSommeFDI MONEY
					,iID_Unite INTEGER
					)
		
		-- Frais disponibles pour le souscripteur
		INSERT INTO @tblFDI
			(
			 iID_Unite
			,mSommeFDI
			)
		SELECT
			 SUM(CO.ConventionOperAmount)
			,CT.UnitId
		FROM Un_ConventionOper CO
		JOIN Un_Oper OP ON OP.OperID = CO.OperID
		JOIN Un_Cotisation CT ON CT.OperID = OP.OperID
		JOIN dbo.Un_Convention CN ON CN.ConventionID = CO.ConventionID
		WHERE	CO.ConventionOperTypeID = 'FDI'
		AND		CN.SubscriberID = (	SELECT SubscriberID
									FROM dbo.Un_Convention 
									WHERE ConventionID = @iID_Convention
									)
		GROUP BY CT.UnitId
		
		SET @mSommeCotisation	= @mSommeCotisation * -1
		SET @mSommeFee			= @mSommeFee * -1
		
		-- 200.00
		SELECT @mFeeByUnit = M.FeeByUnit
		FROM dbo.Un_Unit U
		JOIN Un_Modal M ON M.ModalID = U.ModalID
		WHERE U.UnitID = @iUniteDestination
		
		-- Frais déjà dans le compte destination
		SELECT @mSommeFeeDest = ISNULL(SUM(Fee), 0)
		FROM Un_Cotisation
		WHERE UnitID = @iUniteDestination
		
		-- Si les frais destination sont déjà comblés
		IF @mSommeFeeDest = @mFeeByUnit
			BEGIN
			
			-- Alors on transfert 0.00 en frais 
			SET @mFeeDest = 0
			-- ...et le total de l'épargne
			SET @mCotisDest = @mSommeCotisation
			-- ...et on conserve les frais pour TFR
			SET @mSommeFee = 0
			
			END
		ELSE
			BEGIN
			
			-- Si on couvre les frais dest avec les frais src
			IF @mSommeFeeDest + @mSommeFee >= @mFeeByUnit
				BEGIN
				
				-- Alors on transfert la portion manquante à partir des frais
				SET @mFeeDest = @mFeeByUnit - @mSommeFeeDest
				-- ...et on conserve la balance pour TFR
				SET @mSommeFee = @mFeeDest
				-- Transfert total de l'épargne
				SET @mCotisDest = @mSommeCotisation

				END
			ELSE
				BEGIN
				
				-- Si le total des frais et cotisations src peuvent combler les frais dest
				IF @mSommeFeeDest + @mSommeFee + @mSommeCotisation >= @mFeeByUnit
					BEGIN

					-- Alors on transfert le total des frais
					SET @mFeeDest = @mSommeFee
					-- ...puis on pige dans l'épargne
					SET @mFeeDest = @mFeeByUnit - @mSommeFeeDest
					SET @mCotisDest = (@mSommeCotisation + @mSommeFee) - @mFeeDest
					
					END 
				ELSE
					BEGIN
					
					-- Sinon on transfert tout dans les frais
					SET @mFeeDest = @mSommeFee + @mSommeCotisation
					-- ..et rien en épargne
					SET @mCotisDest = 0
					
					END
				END
			END
			
		SET @mSommeCotisation	= @mSommeCotisation * -1
		SET @mSommeFee			= @mSommeFee * -1
		
		END
		
	IF @mSommeCotisation <= 0 OR @mSommeFee <= 0
		BEGIN
		
		--Appel de la storedProc SP_IU_UN_Cotisation pour créer la transaction
		EXEC @iCotisationIdRetrait = SP_IU_UN_Cotisation	 @iID_Connexion
															,0
															,@iOperRIO
															,@iID_Unite
															,@dtOperDate
															,@mSommeCotisation
															,@mSommeFee
															,0
															,0
															,0
		
		IF @@Error <> 0
			GOTO ROLLBACK_SECTION

		----------------------------------------------------------------------------------------------------------------------------
		-- Dynamique No 14 : Création la transaction de dépôt des épargnes et frais des cotisations pour la convention individuelle
		----------------------------------------------------------------------------------------------------------------------------
		SET @mSommeCotisation = @mSommeCotisation * -1
		SET @mSommeFee = @mSommeFee * -1

		IF @vcType_Conversion <> 'TRI' -- RIO et RIM : Aucun frais par unité, tout est transféré dans les cotisations
			BEGIN
			
			SET @mCotisDest = @mSommeCotisation + @mSommeFee
			SET @mFeeDest = 0
			
			END
		ELSE
			SET @mUnitUsed = @mFeeDest / @mFeeByUnit -- FT3

		--Appel dela store Proc SP_IU_UN_Cotisation pour creer la transaction
		EXEC @iCotisationIdDepot = SP_IU_UN_Cotisation	 @iID_Connexion
														,0
														,@iOperRIO
														,@iUniteDestination
														,@dtOperDate
														,@mCotisDest
														,@mFeeDest
														,0
														,0
														,0
		
		IF @@Error <> 0
			GOTO ROLLBACK_SECTION
		
		END

		---------------------------------------------------------------------------------------------
		--	Dynamique No 15 : Application des frais de service si RIO ou RIM - FT1
		---------------------------------------------------------------------------------------------
		IF	(@vcType_Conversion = 'RIO' OR @vcType_Conversion = 'RIM')
		AND @mMontant_Frais_TTC <> 0
		AND @mMontant_Frais_TTC IS NOT NULL
			BEGIN
			
			DECLARE	 @return_value		INT
					,@iID_Oper			INT
					,@vcCode_Msg		VARCHAR(10)
			
			EXEC	@return_value = psOPER_GenererOperationFrais
											 @iID_Connexion = @iID_Connexion
											,@iID_Convention = @iConventionDestination
											,@vcCode_Type_Frais = @vcCode_Type_Frais
											,@mMontant_Frais = NULL
											,@iID_Utilisateur_Creation = NULL
											,@dtDate_Operation = @dtOperDate
											,@dtDate_Effective = @dtOperDate
											,@iID_Oper = @iID_Oper OUTPUT
											,@vcCode_Message = @vcCode_Msg OUTPUT
			
			IF @@Error <> 0
				GOTO ROLLBACK_SECTION

			--IF @return_value = 0
			--	BEGIN
				
			--	SET @vcCode_Message = @vcCode_Msg
			--	SET @iCode_Retour = 0
			--	GOTO ROLLBACK_SECTION
				
			--	END
				
			IF @return_value = 1
				-- Ajout d'un lien d'association entre les opérations de conversion et de frais de gestion
				INSERT INTO tblOPER_AssociationOperations
								(
								 iID_Operation_Parent
								,iID_Operation_Enfant
								,iID_Raison_Association
								)
							SELECT
								 @iOperRIO
								,@iID_Oper
								,RA.iID_Raison_Association
							FROM tblOPER_RaisonsAssociation RA
							WHERE vcCode_Raison = @vcType_Conversion
			
			END
		
		---------------------------------------------------------------------------------------------
		-- Dynamique No 16 et Dynamique No 17  : Création des transactions de retraits et dépôts
		--	dans les conventions collectives et individuelles pour les intérêts, subventions, etc...
		---------------------------------------------------------------------------------------------
		--Declarer un Curseur
		DECLARE CurTransactions CURSOR FOR 		
			SELECT	 Cop.ConventionOperTypeID
					,(SUM(Cop.ConventionOperAmount) * @nRatio) AS Montants
			
			FROM Un_ConventionOper Cop 
			JOIN tblOPER_OperationsCategorie OpCat ON Cop.ConventionOperTypeID = OpCat.cID_Type_Oper_Convention
			JOIN tblOPER_CategoriesOperation CatOp ON OpCat.iID_Categorie_Oper = CatOp.iID_Categorie_Oper
			
			WHERE	Cop.ConventionID		= @iID_Convention
			AND		CatOp.vcCode_Categorie	= 'RIO-TRANSFERT-TRANSAC-CONVENTION'
			
			GROUP BY Cop.ConventionOperTypeID
			HAVING SUM(Cop.ConventionOperAmount)>0

		OPEN CurTransactions
		FETCH NEXT FROM CurTransactions INTO @vcTypeTransaction
											,@mMontantConvention
											
		WHILE @@FETCH_STATUS = 0
			BEGIN 
			
			--pour les retraits inverser les montants de transactions
			SET @mMontantConvention = @mMontantConvention * -1
	
			--Appel du service SP_IU_UN_ConventionOper
			EXEC SP_IU_UN_ConventionOper	 @iID_Connexion
											,0
											,@iID_Convention
											,@iOperRIO
											,@vcTypeTransaction
											,@mMontantConvention				

			IF @@Error <> 0
				GOTO ROLLBACK_SECTION

			--pour les depots mettre les montants de transactions en signe positif 
			SET @mMontantConvention = @mMontantConvention * -1

			--Appel du service SP_IU_UN_ConventionOper
			EXEC SP_IU_UN_ConventionOper	 @iID_Connexion
											,0
											,@iConventionDestination
											,@iOperRIO
											,@vcTypeTransaction
											,@mMontantConvention
			
			IF @@Error <> 0
				GOTO ROLLBACK_SECTION
		
			FETCH NEXT FROM CurTransactions INTO @vcTypeTransaction
												,@mMontantConvention

			END

		CLOSE CurTransactions
		DEALLOCATE CurTransactions

		-----------------------------------------------------------------------------------------------------------
		-- Dynamique No 18 : Générer des rendements sur capital pour une convention source de type REEEFLEX
		-----------------------------------------------------------------------------------------------------------
		IF @vcType_Conversion = 'RIM' OR @vcType_Conversion = 'TRI'
  			BEGIN
  			
			-- Si convention collective REEEFLEX
			IF (SELECT vcCode_Regroupement
				FROM tblCONV_RegroupementsRegimes RR
				JOIN Un_Plan PL ON PL.iID_Regroupement_Regime = RR.iID_Regroupement_Regime 
				JOIN dbo.Un_Convention CN ON CN.PlanID = PL.PlanID
				WHERE CN.ConventionID = @iID_Convention
				) = 'REF'

				BEGIN
				
  				-- Si la convention collective (source) n'a encore jamais fait l'objet d'une converstion
  				IF NOT EXISTS(	SELECT OperTypeID
								FROM tblOPER_OperationsRIO
								WHERE	iID_Convention_Source = @iID_Convention
								AND		bRIO_Annulee = 0
								AND		bRIO_QuiAnnule = 0
								)

					BEGIN
					
					IF @vcType_Conversion = 'RIM'
						BEGIN
							EXEC @return_value = psOPER_GenererRendementInd
															 @iID_Convention
															,@iConventionDestination
															,0
															,@iOperRIO
															,'RIM'
															,@vcCode_Message
							IF @return_value < 0
								BEGIN
								SET @iCode_Retour = @return_value
								GOTO ROLLBACK_SECTION
								
								END
						END
					ELSE
						IF @vcType_Conversion = 'TRI'
							BEGIN
								EXEC @return_value = psOPER_GenererRendementInd
																 @iID_Convention
																,@iConventionDestination
																,1
																,@iOperRIO
																,'TRI'
																,@vcCode_Message

								IF @return_value < 0
									BEGIN
									SET @iCode_Retour = @return_value
									GOTO ROLLBACK_SECTION
									
									END
							END
					END
				
				END
			
			END
			
		-----------------------------------------------------------------------------------------------------------
		-- Inscrire la réduction d'unités
		-----------------------------------------------------------------------------------------------------------
		-- FT1
		IF @vcType_Conversion = 'RIM' OR @vcType_Conversion = 'TRI'
			BEGIN
			
			-- Insère les nouvelles réduction d'unités de l'opération
			INSERT INTO Un_UnitReduction
					(
					 UnitID
					,ReductionConnectID
					,ReductionDate
					,UnitQty
					,FeeSumByUnit
					,SubscInsurSumByUnit
					,UnitReductionReasonID
					,NoChequeReasonID
					)
			SELECT
					 @iID_Unite
					,@iID_Connexion
					,@dtOperDate
					,UN.UnitQty
					,CASE
						WHEN @vcType_Conversion = 'TRI' THEN
							--ROUND(SUM(CT.Fee) / UN.UnitQty, 2)
							@mFeeSumByUnit -- FT3
						ELSE
							0
						END
					,CASE
						WHEN @vcType_Conversion = 'TRI' THEN
							ROUND(SUM(CT.SubscInsur) / UN.UnitQty, 2)
						ELSE
							0
						END
					,URR.UnitReductionReasonID
					,NULL
			FROM		Un_Unit UN
			JOIN		Un_Cotisation CT ON CT.UnitID = UN.UnitID
			JOIN		Un_Modal MO ON MO.ModalID = UN.ModalID
			LEFT JOIN	Un_UnitReductionReason URR ON UPPER(URR.UnitReductionReason) = 'TRANSFERT ' + @vcType_Conversion
			WHERE	UN.UnitID = @iID_Unite
			AND		UN.UnitQty <> 0
			GROUP BY UN.UnitID
					,UN.UnitQty
					,URR.UnitReductionReasonID
			
			SET @UnitReductionID = SCOPE_IDENTITY()

			IF @UnitReductionID IS NOT NULL
				BEGIN

				-- Diminue le nombre d'unité sur le groupe d'unités
				-- Met la date de résiliation sur le groupe d'unités
				UPDATE dbo.Un_Unit 
				SET	 UnitQty = 0
					,TerminatedDate = @dtOperDate
				WHERE UnitID = @iID_Unite
			
				-- Insère les nouveaux liens cotisations vs réductions d'unités de l'opération
				INSERT INTO Un_UnitReductionCotisation
									(
									 CotisationID
									,UnitReductionID
									)
					SELECT DISTINCT
										 CT.CotisationID
										,@UnitReductionID
					FROM Un_Cotisation CT
					JOIN dbo.Un_Unit UN ON UN.UnitID = CT.UnitID
					WHERE	UN.UnitID = @iID_Unite
					AND		NOT EXISTS (SELECT 1
										FROM Un_UnitReductionCotisation
										WHERE CotisationID = CT.CotisationID
										)
				
				-- Ajout d'une nouvelle utilisation de frais disponibles (FT3)
				IF ISNULL(@mUnitUsed, 0) > 0
					INSERT INTO Un_AvailableFeeUse
									(
									 UnitReductionID
									,OperID
									,fUnitQtyUse
									)
								VALUES
									(
									 @UnitReductionID
									,@iOperRIO
									,@mUnitUsed
									)
				
				END

			IF @@Error <> 0
				GOTO ROLLBACK_SECTION
			
			END

		-----------------------------------------------------------------------------------------------------------
		-- Dynamique No 19 : Mettre à jour le groupe d'unités et indiquer que le remboursement intégral a ete fait
		-----------------------------------------------------------------------------------------------------------
		UPDATE dbo.Un_Unit 
		SET IntReimbDate = @dtOperDate
		WHERE	UnitID			= @iID_Unite
		AND		IntReimbDate	IS NULL

		IF @@Error <> 0
			GOTO ROLLBACK_SECTION
		
		-----------------------------------------------------------------------------------------------------------
		-- Mise à jour du statut des bourses s'il y a lieu
		-----------------------------------------------------------------------------------------------------------
		IF @vcType_Conversion = 'RIM' OR @vcType_Conversion = 'TRI'
			BEGIN

			-- Sauvegarde des bourses à modifier
			DECLARE @tBourses TABLE
						(
						iID_Bourse INT
						)

			INSERT INTO @tBourses
			SELECT ScholarshipID
			FROM Un_Scholarship
			WHERE ConventionID = @iID_Convention
			AND ScholarshipStatusID IN ('ADM', 'RES', 'WAI', 'TPA')
			
			-- Mise à jour du statut des bourses concernées
			UPDATE Un_Scholarship
			SET	 ScholarshipStatusID = 'REN'
				,YearDeleted = YEAR(GETDATE())
			FROM @tBourses tB
			WHERE ScholarshipID = tB.iID_Bourse
			
			-- Ajout d'un lien avec l'opération
			INSERT INTO tblOPER_LienOperationHistoriqueStatutBourse
				(
				 iID_Operation
				,iID_Historique_Statut
				)
			SELECT	 @iOperRIO
					,max(iID_Historique_Statut)
			FROM tblCONV_HistoriqueStatutBourse HSB
			JOIN @tBourses tB ON tB.iID_Bourse = HSB.iID_Bourse
			GROUP BY HSB.iID_Bourse
			
			END

		-----------------------------------------------------------------------------------------------------------
		-- Dynamique No 20 : Créer un enregistrement dans la table des opération
		-----------------------------------------------------------------------------------------------------------
		INSERT INTO tblOPER_OperationsRIO
									(
									 dtDate_Enregistrement
									,iID_Oper_RIO
									,iID_Convention_Source
									,iID_Unite_Source
									,iID_Convention_Destination
									,iID_Unite_Destination
									,bRIO_Annulee
									,bRIO_QuiAnnule
									,OperTypeID -- FT1
									)
								VALUES
									(
									 GETDATE()
									,@iOperRIO
									,@iID_Convention
									,@iID_Unite
									,@iConventionDestination
									,@iUniteDestination
									,0
									,0
									,@vcType_Conversion -- FT1
									)

		IF @iCode_Retour = 0
			SELECT @iCode_Retour = SCOPE_IDENTITY() --Nassim

		IF @@Error <> 0
			GOTO ROLLBACK_SECTION

        -----------------------------------------------------------------------------------------------------------
        -- Dynamique No 21 : Créer une transaction de retrait dans les subventions canadiennes
        -----------------------------------------------------------------------------------------------------------
        SELECT		 @mfCESG		= ROUND(SUM(fCESG)	* @nRatio, 2)
                    ,@mfACESG		= ROUND(SUM(fACESG)	* @nRatio, 2)
                    ,@mfCLB			= SUM(fCLB) -- Transfert la totalité du BEC dès le premier groupe d'unités
                    ,@mfPG			= ROUND(SUM(fPG)	* @nRatio, 2)
        FROM Un_CESP CE
        WHERE CE.ConventionID = @iID_Convention

        IF @mfCESG > 0 OR @mfACESG > 0 OR  @mfCLB > 0 OR @mfPG > 0 OR @mCotisation > 0  --Si tous les montants sont nuls alors passer à l'étape 19 (Dynamique)
			BEGIN
			
			IF @mfCESG > 0 
				SET @mfCESG = @mfCESG * -1
			ELSE
				SET @mfCESG = 0

			IF @mfACESG > 0
				SET @mfACESG = @mfACESG * -1
			ELSE
				SET @mfACESG = 0

			IF @mfCLB > 0
				SET @mfCLB = @mfCLB * -1
			ELSE
				SET @mfCLB = 0

			IF @mfPG > 0
				SET @mfPG = @mfPG * -1
			ELSE
				SET @mfPG = 0

			INSERT INTO Un_CESP
							(
							 ConventionID
							,OperID
							,CotisationID
							,OperSourceID
							,fCESG
							,fACESG
							,fCLB
							,fCLBFee
							,fPG
							,vcPGProv
							,fCotisationGranted
							)
						VALUES
							(
							 @iID_Convention
							,@iOperRIO
							,@iCotisationIdRetrait
							,@iOperRIO
							,@mfCESG
							,@mfACESG
							,@mfCLB
							,0
							,@mfPG
							,NULL
							,0
							) 

			IF @@Error <> 0
				GOTO ROLLBACK_SECTION

			-----------------------------------------------------------------------------------------------------------
			-- Dynamique No 22 : Créer une transaction de dépôt dans les subventions canadiennes
			-----------------------------------------------------------------------------------------------------------
			SET @mfCESG		= @mfCESG * -1
			SET @mfACESG	= @mfACESG * -1
			SET @mfCLB		= @mfCLB * -1
			SET @mfPG		= @mfPG * -1

			INSERT INTO Un_CESP
							(
							 ConventionID
							,OperID
							,CotisationID
							,OperSourceID
							,fCESG
							,fACESG
							,fCLB
							,fCLBFee
							,fPG
							,vcPGProv
							,fCotisationGranted
							)
						VALUES 
							(
							 @iConventionDestination
							,@iOperRIO
							,@iCotisationIdDepot
							,@iOperRIO
							,@mfCESG
							,@mfACESG
							,@mfCLB
							,0
							,@mfPG
							,NULL
							,0
							) 

			IF @@Error <> 0
				GOTO ROLLBACK_SECTION

			-----------------------------------------------------------------------------------------------------------
			-- Dynamique No 23 : Créer une transaction 400 à la subvention canadienne pour la sortie
			-----------------------------------------------------------------------------------------------------------
			EXEC IU_UN_CESP400ForOper	 @iID_Connexion
										,@iOperRIO
										,230
										,0

			IF @@Error <> 0
					GOTO ROLLBACK_SECTION

			-----------------------------------------------------------------------------------------------------------
			-- Dynamique No 24 : Créer une transaction 400 à la subvention canadienne pour l'entrée
			-----------------------------------------------------------------------------------------------------------
			EXEC IU_UN_CESP400ForOper	 @iID_Connexion
										,@iOperRIO
										,190
										,0

			IF @@Error <> 0
					GOTO ROLLBACK_SECTION

			END

		-------------------------------------------------------------------------------------------------------
		-- Effectuer un transfert de frais (TFR) sur TRI - FT1
		-------------------------------------------------------------------------------------------------------
		IF @vcType_Conversion = 'TRI'
			BEGIN
			
			DECLARE @SumFee MONEY
			
			---- Si le transfert a été complété en totalité (cotisations à 0)
			--IF (SELECT sum(Cotisation)
			--	FROM Un_Cotisation	CT
			--	JOIN Un_Unit		UN ON UN.UnitID = CT.UnitID
			--	WHERE UN.ConventionID = @iID_Convention
			--	) = 0
				
			--	BEGIN
				
			-- Insère l'opération TFR
			EXEC @iOperTFR = SP_IU_UN_Oper	 @iID_Connexion
											,0
											,'TFR'
											,@dtOperDate
			
			IF @@Error <> 0
					GOTO ROLLBACK_SECTION
			
			-- Récupère le montant total de frais disponible à transférer
			SELECT @SumFee = sum(Fee)
			FROM Un_Cotisation	CT
			JOIN Un_Unit		UN ON UN.UnitID = CT.UnitID
			WHERE UN.UnitID = @iID_Unite
			
			-- Insère la cotisation sur l'opération TFR
			INSERT INTO Un_Cotisation
					(
					OperID,
					UnitID,
					EffectDate,
					Cotisation,
					Fee,
					BenefInsur,
					SubscInsur,
					TaxOnInsur
					)
				VALUES 
					(
					 @iOperTFR
					,@iID_Unite
					,@dtOperDate
					,0
					,-@SumFee
					,0
					,0
					,0
					)
			
			IF @@Error <> 0
					GOTO ROLLBACK_SECTION

			-- Inscrit une opération de convention de frais disponible (FDI)
			INSERT INTO Un_ConventionOper
					(
					 OperID
					,ConventionID
					,ConventionOperTypeID
					,ConventionOperAmount
					)
				VALUES
					(
					 @iOperTFR
					,@iID_Convention
					,'FDI'
					,@SumFee
					)

			IF @@Error <> 0
					GOTO ROLLBACK_SECTION
 				
			-- Ajoute un lien d'association avec l'opération de conversion
			INSERT INTO tblOPER_AssociationOperations
							(
							 iID_Operation_Parent
							,iID_Operation_Enfant
							,iID_Raison_Association
							)
						SELECT
							 @iOperRIO
							,@iOperTFR
							,RA.iID_Raison_Association
						FROM tblOPER_RaisonsAssociation RA
						WHERE vcCode_Raison = @vcType_Conversion
 			
			END

		-------------------------------------------------------------------------------------------------------
		-- Remise à NULL de la date de RI si des cotisations sont présentes à la convention individuelle - FT1
		-------------------------------------------------------------------------------------------------------
		IF (SELECT SUM(ISNULL(Cotisation, 0)) + SUM(ISNULL(Fee, 0))
			FROM Un_Cotisation CT
			WHERE CT.UnitID = @iUniteDestination
			) > 0
			
			BEGIN
			
			UPDATE dbo.Un_Unit 
			SET IntReimbDate = NULL
			WHERE UnitID = @iUniteDestination
			
			END
		
		-----------------------------------------------------------------------------------------------------------
		-- Dynamique No 25 : Réviser les statuts des groupes d'unités et les status
		-----------------------------------------------------------------------------------------------------------
		--Indique les status des groupes  d'unités
		SET @vcStatusGroupes  = CAST(@iID_Unite AS VARCHAR) + ',' + CAST(@iUniteDestination AS VARCHAR)
		
		--Appel du service TT_UN_ConventionAndUnitStateForUnit
		EXEC TT_UN_ConventionAndUnitStateForUnit @vcStatusGroupes

		IF @@Error <> 0
			GOTO ROLLBACK_SECTION	

		-- Appelle de la procédure stockée qui gère les enregistrements 100, 200, et 400 de toutes les conventions du bénéficiaire.
		EXEC @iCode_Retour = TT_UN_CESPOfConventions @iID_Connexion, 0, 0, @iConventionDestination

		IF @@Error <> 0 OR @iCode_Retour <= 0
			GOTO ROLLBACK_SECTION

		-- Appel de la lettre de confirmation du RIM
		--IF @vcType_Conversion = 'RIM' 
		--     	EXEC psOPER_ObtenirLettreConfirmationRIM @iID_Connexion, NULL, 0, @iID_Unite
		
		IF @@Error <> 0
			GOTO ROLLBACK_SECTION	

COMMIT_SECTION:

	COMMIT TRANSACTION
	GOTO END_TRANSACTION	

--=====================================================================================================
-- A ce point, la transaction n'a pas fonctionné.  On effectue un ROLLBACK et on quitte la procédure.
--=====================================================================================================
ROLLBACK_SECTION:

	IF @iCode_Retour <> -2
		SET @iCode_Retour = -3

	ROLLBACK TRANSACTION
--=====================================================================================================
-- Libellé de fin de procédure.
--=====================================================================================================
END_TRANSACTION:	
--===========================================

-- Activer Trigger TUn_Convention_State
	IF object_id('tempdb..#DisableTrigger') is not null
		BEGIN
		
		--;ENABLE TRIGGER TUn_Convention_State ON Un_Convention 
		Delete #DisableTrigger where vcTriggerName = 'TUn_Convention_State'

		-- Activer Trigger TUn_Unit_State
		--;ENABLE TRIGGER TUn_Unit_State ON Un_Unit 
		Delete #DisableTrigger where vcTriggerName = 'TUn_Unit_State'

		-- Activer Trigger TUn_Cotisation_Doc
		--;ENABLE TRIGGER TUn_Cotisation_Doc ON Un_Cotisation
		Delete #DisableTrigger where vcTriggerName = 'TUn_Cotisation_Doc'

		-- Activer Trigger TUn_Cotisation_State
		--;ENABLE TRIGGER TUn_Cotisation_State ON Un_Cotisation
		Delete #DisableTrigger where vcTriggerName = 'TUn_Cotisation_State'
		
		END
	
	-- TESTS
	IF @iCode_Retour = 0 
		RETURN 0
	IF @iCode_Retour < 0 
		RETURN -1
	IF @iCode_Retour > 0 
		RETURN @iCode_Retour
	
	--RETURN @iCode_Retour 
	*/
    RETURN 0/0
END