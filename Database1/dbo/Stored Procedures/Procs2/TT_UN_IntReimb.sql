/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************    */

/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	TT_UN_IntReimb
Description         :	Procédure de création des RIN en batch.
Valeurs de retours  :	@ReturnValue :
									>0 = Pas d’erreur
									<=0 = Erreur SQL

Note      :	ADX0000694	IA	2005-06-08	Bruno Lapointe		Création
			ADX0000753	IA	2005-10-04	Bruno Lapointe	Il faut expédier les opérations au module des chèques.  
																				Il faut aussi expédier les destinataires originaux et les changements de destinataire.
			ADX0001602	BR	2005-10-11	Bruno Lapointe	SCOPE_IDENTITY au lieu de IDENT_CURRENT
			ADX0001774	BR	2005-11-24	Bruno Lapointe	Correction mise à jour d'état
			ADX0001095	BR	2005-12-15	Bruno Lapointe	Correction mise à jour d'état suite à Deadlock.
			ADX0000846	IA	2006-04-20	Bruno Lapointe	Adaptation pour PCEE 4.3
			ADX0001114	IA	2006-11-20	Alain Quirion		Utilise d'un blob contenant les date estimés de RI en plus des id des groupes d'unités
			ADX0002273	BR	2007-02-05	Alain Quirion		La validation sur la date de blocage sera faite uniquement sur les groupe d'unité sélectionnées
			ADX0001235	IA	2007-02-14	Alain Quirion		Utilisation de dtRegStartDate pour la date de début de régime
			ADX0002426	BR	2007-05-24	Bruno Lapointe	Gestion de la table Un_CESP.
			ADX0001357	IA	2007-06-04	Alain Quirion		Création automatique de la proposition de chèque au nom de 
																				Gestion Universitas Inc. si l’unité du remboursement intégral 
																				a une source de vente de type « Gagnant de concours ».
			ADX0001418	IA	2007-06-13	Bruno Lapointe	Ajout de la condition du montant souscrit atteint.
			ADX0002502	BR	2007-06-27	Bruno Lapointe	NAS absent mal géré pour les conventions entrées en vigueur avant le 1 janvier 2003
			ADX0001357	IA	2007-06-04	Alain Quirion		Création automatique de la proposition de chèque au nom de 
																				Gestion Universitas Inc. si l’unité du remboursement intégral 
																				a une source de vente de type « Gagnant de concours ».
			ADX0001246	UP	2007-09-20	Bruno Lapointe	Optimisation.
			ADX0001290	UP	2008-03-20	Bruno Lapointe	Optimisation.
							2008-09-25	Josée Parent				Modification pour désactiver et activer le trigger de mise
																				à jour 'TR_U_UN_Unit_A_dtRegStartDate' au lieu du trigger
																				'TR_IUD_UN_Unit_A_dtRegStartDate'
							2010-10-04	Steve Gouin				Gestion des disable trigger par #DisableTrigger
							2011-02-03	Frederick Thibault		Ajout du champ Un_CESP400.fACESGPart pour régler le problème SCEE+
							2011-03-31	Pierre-Luc Simard		Déplacer de la gestion du trigger pour ne pas nuire au SCOPE_IDENTITY 
																				et modifier le INSERT par un DELETE
							2014-05-20	Pierre-Luc Simard		Refonte - Bloquer l'ajout de nouveau RIN via Uniacces
                            2017-09-27  Pierre-Luc Simard       Deprecated - Cette procédure n'est plus utilisée

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_IntReimb] (
	@ConnectID INTEGER, 	-- ID unique de l’usager qui a provoqué ces opérations.
	@iBlobID INTEGER, 	-- ID du blob contenant les UnitID  suivit de la date estimée du RI (IntEstimatedReimbDate) des groupes d’unités dont il faut faire le RIN.  Tous les éléments du blob seront séparés par des « , ». 
	@CESGRenunciation BIT ) -- Indique si ces des RIN avec renonciation (true) ou pas (false).
AS
BEGIN
	DECLARE
		@iResult INTEGER,
		@UnitID INTEGER,
		@BeforeOperID INTEGER,
		@AfterOperID INTEGER,
		@BeforeIntReimbID INTEGER,
		@AfterIntReimbID INTEGER

	SET @iResult = -1 --1
/*
	-----------------
	BEGIN TRANSACTION
	-----------------
	IF object_id('tempdb..#DisableTrigger') is null
		CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))

	CREATE TABLE #tBatchRIN (
		UnitID INTEGER PRIMARY KEY,
		IntEstimatedReimbDate DATETIME,
		AddToOperID INTEGER IDENTITY(1,1),
		CollegeID INTEGER,
		ProgramID INTEGER,
		StudyStart DATETIME,
		ProgramYear INTEGER,
		ProgramLength INTEGER,
		Cotisation MONEY,
		Fee MONEY )

	DECLARE @tUnitDate TABLE (
		UnitID INTEGER PRIMARY KEY,
		IntEstimatedReimbDate DATETIME)

	DECLARE @LastVerifDate DATETIME 

	-- Insertion dans une table des groupes d'unités et date de remboursement intégral
	INSERT INTO @tUnitDate(UnitID, IntEstimatedReimbDate)
		SELECT
				V.Val,
				V.dtValDate
		FROM dbo.FN_CRQ_BlobToIntegerDateTable(@iBlobID) V
		JOIN dbo.Un_Unit U ON U.UnitID = V.Val
		JOIN Un_Modal M ON M.ModalID = U.ModalID
		JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
		GROUP BY
			V.Val,
			V.dtValDate,
			U.PmtEndConnectID,
			M.PmtRate,
			U.UnitQty,
			M.PmtQty
		HAVING U.PmtEndConnectID IS NOT NULL
			OR ROUND(M.PmtRate*U.UnitQty,2)*M.PmtQty <= SUM(Ct.Cotisation+Ct.Fee)

	-- Va chercher la date de blocage
	SELECT TOP 1 @LastVerifDate = LastVerifDate
	FROM Un_Def

	-- Validation sur la date de blocage
	IF EXISTS (
			SELECT *
			FROM @tUnitDate
			WHERE IntEstimatedReimbDate <= @LastVerifDate )
		SET @iResult = -1
	ELSE
	BEGIN
		INSERT INTO #tBatchRIN (
				UnitID,
				IntEstimatedReimbDate,
				CollegeID,
				ProgramID,
				StudyStart,
				ProgramYear,
				ProgramLength,
				Cotisation,
				Fee )
			SELECT
				U.UnitID,
				V.IntEstimatedReimbDate,
				B.CollegeID,
				B.ProgramID,
				B.StudyStart,
				B.ProgramYear,
				B.ProgramLength,
				Cotisation = -SUM(Ct.Cotisation),
				Fee = -SUM(Ct.Fee)
			FROM @tUnitDate V
			JOIN dbo.Un_Unit U ON U.UnitID = V.UnitID
			JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
			JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
			GROUP BY 
				U.UnitID,
				V.IntEstimatedReimbDate,
				B.CollegeID,
				B.ProgramID,
				B.StudyStart,
				B.ProgramYear,
				B.ProgramLength
			HAVING SUM(Ct.Cotisation+Ct.Fee) <> 0
			ORDER BY U.UnitID

		SET @BeforeOperID = IDENT_CURRENT('Un_Oper')

		--ALTER TABLE Un_Oper
		--	DISABLE TRIGGER TUn_Oper_dtFirstDeposit
		INSERT INTO #DisableTrigger VALUES('TUn_Oper_dtFirstDeposit')				

		-- Insère les opérations
		INSERT INTO Un_Oper (
				OperDate,
				OperTypeID,
				ConnectID )
			SELECT
				IntEstimatedReimbDate,
				'RIN',
				@ConnectID
			FROM #tBatchRIN

		IF @@ERROR = 0
			SET @AfterOperID = SCOPE_IDENTITY()
		ELSE
			SET @iResult = -2

		--ALTER TABLE Un_Oper
		--	ENABLE TRIGGER TUn_Oper_dtFirstDeposit

		--INSERT INTO #DisableTrigger VALUES('TUn_Oper_dtFirstDeposit')				
		Delete #DisableTrigger where vcTriggerName = 'TUn_Oper_dtFirstDeposit'

	END

	IF @iResult > 0
	BEGIN
		--ALTER TABLE Un_Cotisation
		--	DISABLE TRIGGER TUn_Cotisation_State

		--ALTER TABLE Un_Cotisation
		--	DISABLE TRIGGER TUn_Cotisation_Doc

		--ALTER TABLE Un_Cotisation
		--	DISABLE TRIGGER TUn_Cotisation_dtFirstDeposit

		INSERT INTO #DisableTrigger VALUES('TUn_Cotisation_State')				
		INSERT INTO #DisableTrigger VALUES('TUn_Cotisation_Doc')				
		INSERT INTO #DisableTrigger VALUES('TUn_Cotisation_dtFirstDeposit')				

		-- Insère le montant de cotisation
		INSERT INTO Un_Cotisation (
				UnitID,
				OperID,
				EffectDate,
				Cotisation,
				Fee,
				SubscInsur,
				BenefInsur,
				TaxOnInsur )
			SELECT
				UnitID,
				@BeforeOperID+AddToOperID,
				IntEstimatedReimbDate,
				Cotisation,
				Fee,
				0,
				0,
				0
			FROM #tBatchRIN

		--ALTER TABLE Un_Cotisation
		--	ENABLE TRIGGER TUn_Cotisation_dtFirstDeposit

		--ALTER TABLE Un_Cotisation
		--	ENABLE TRIGGER TUn_Cotisation_Doc

		--ALTER TABLE Un_Cotisation
		--	ENABLE TRIGGER TUn_Cotisation_State
	Delete #DisableTrigger where vcTriggerName = 'TUn_Cotisation_State'
	Delete #DisableTrigger where vcTriggerName = 'TUn_Cotisation_Doc'
	Delete #DisableTrigger where vcTriggerName = 'TUn_Cotisation_dtFirstDeposit'

		IF @@ERROR <> 0
			SET @iResult = -3
	END

	IF @iResult > 0
	BEGIN
		SET @BeforeIntReimbID = IDENT_CURRENT('Un_IntReimb')

		INSERT INTO Un_IntReimb (
				UnitID,
				CollegeID,
				ProgramID,
				IntReimbDate,
				StudyStart,
				ProgramYear,
				ProgramLength,
				CESGRenonciation,
				FullRIN )
			SELECT
				BR.UnitID,
				BR.CollegeID,
				BR.ProgramID,
				BR.IntEstimatedReimbDate,
				BR.StudyStart,
				BR.ProgramYear,
				BR.ProgramLength,
				@CESGRenunciation,
				1 
			FROM #tBatchRIN BR
			JOIN Un_Cotisation Ct ON Ct.UnitID = BR.UnitID
			JOIN Un_Oper O ON O.OperID = Ct.OperID
			WHERE Ct.OperID BETWEEN @BeforeOperID AND @AfterOperID
				AND O.OperDate = BR.IntEstimatedReimbDate
				AND O.OperTypeID = 'RIN'
				AND O.ConnectID = @ConnectID

		IF @@ERROR <> 0
			SET @iResult = -4
		ELSE
			SET @AfterIntReimbID = SCOPE_IDENTITY()
	END

	IF @iResult > 0
	BEGIN
		INSERT INTO Un_IntReimbOper (
				OperID,
				IntReimbID )
			SELECT
				O.OperID,
				IR.IntReimbID
			FROM #tBatchRIN BR
			JOIN Un_Cotisation Ct ON Ct.UnitID = BR.UnitID
			JOIN Un_Oper O ON O.OperID = Ct.OperID
			JOIN Un_IntReimb IR ON IR.UnitID = BR.UnitID
			WHERE O.OperID BETWEEN @BeforeOperID+1 AND @AfterOperID
				AND O.OperDate = BR.IntEstimatedReimbDate
				AND O.OperTypeID = 'RIN'
				AND O.ConnectID = @ConnectID
				AND IR.IntReimbID BETWEEN @BeforeIntReimbID+1 AND @AfterIntReimbID
				AND IR.IntReimbDate = BR.IntEstimatedReimbDate

		IF @@ERROR <> 0
			SET @iResult = -5
	END

	IF @iResult > 0
	BEGIN
		--ALTER TABLE Un_Unit 
		--	DISABLE TRIGGER TUn_Unit_State

		--ALTER TABLE Un_Unit 
		--	DISABLE TRIGGER TR_U_UN_Unit_A_dtRegStartDate -- Josée Parent

		INSERT INTO #DisableTrigger VALUES('TUn_Unit_State')				
		INSERT INTO #DisableTrigger VALUES('TR_U_UN_Unit_A_dtRegStartDate')				

		UPDATE dbo.Un_Unit 
		SET IntReimbDate = BR.IntEstimatedReimbDate
		FROM dbo.Un_Unit 
		JOIN #tBatchRIN BR ON BR.UnitID = Un_Unit.UnitID

		--ALTER TABLE Un_Unit 
		--	ENABLE TRIGGER TR_U_UN_Unit_A_dtRegStartDate -- Josée Parent

		--ALTER TABLE Un_Unit 
		--	ENABLE TRIGGER TUn_Unit_State
	Delete #DisableTrigger where vcTriggerName = 'TR_U_UN_Unit_A_dtRegStartDate'
	Delete #DisableTrigger where vcTriggerName = 'TUn_Unit_State'

		IF @@ERROR <> 0
			SET @iResult = -6
	END

	--Création de la proposition de chèque au nom de Gestion Universitas Inc. si la source de vente
	--du groupe d'unités est de type "gagnant de concours"
	IF @iResult > 0
		AND EXISTS (	SELECT U.UnitID
						FROM #tBatchRIN T
						JOIN dbo.Un_Unit U ON U.UnitID = T.UnitID
						JOIN Un_SaleSource SS ON SS.SaleSourceID = U.SaleSourceID
						WHERE SS.bIsContestWinner = 1
					)
	BEGIN
		DECLARE @HumanID INTEGER

		SELECT TOP 1 @HumanID = HumanID
		FROM dbo.Mo_Human H		
		WHERE H.LastName + ' ' + H.Firstname = 'Gestion Universitas Inc.'
		ORDER BY H.HumanID			

		INSERT INTO Un_ChequeSuggestion (
			OperID,
			iHumanID )
		SELECT 
			O.OperID,
			@HumanID
		FROM #tBatchRIN BR
		JOIN Un_Cotisation Ct ON Ct.UnitID = BR.UnitID
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		JOIN dbo.Un_Unit U ON U.UnitID = BR.UnitID
		JOIN Un_SaleSource SS ON SS.SaleSourceID = U.SaleSourceID
		JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID		
		WHERE Ct.OperID BETWEEN @BeforeOperID AND @AfterOperID
			AND O.OperDate = BR.IntEstimatedReimbDate
			AND O.OperTypeID = 'RIN'
			AND O.ConnectID = @ConnectID
			AND SS.bIsContestWinner = 1
			AND C.SubscriberID <> @HumanID --Le souscripteur n'est pas déjà Gestion Universitas Inc.

		IF @@ERROR <> 0 
			SET @iResult = -30
	END

	IF @iResult > 0
	BEGIN
		DECLARE
			@iSPID INTEGER,
			@iCheckResultID INTEGER
	
		SET @iSPID = @@SPID
	
		INSERT INTO Un_OperToExportInCHQ (
				OperID,
				iSPID )
			SELECT
				@BeforeOperID+AddToOperID,
				@iSPID
			FROM #tBatchRIN
	
		EXECUTE @iCheckResultID = IU_UN_OperCheckBatch 1, @iSPID
	
		IF @iCheckResultID <> @iSPID
			SET @iResult = -7
	END	

	IF @iResult > 0
	BEGIN
		DECLARE @tCESP400ToDo TABLE (
			UnitID INT PRIMARY KEY,
			OperID INT NOT NULL,
			CotisationID INT NOT NULL,
			EffectDate DATETIME NOT NULL,
			Cotisation MONEY NOT NULL,
			Fee MONEY NOT NULL )

		INSERT INTO @tCESP400ToDo
			SELECT
				Ct.UnitID,
				Ct.OperID,
				Ct.CotisationID,
				Ct.EffectDate,
				Ct.Cotisation,
				Ct.Fee
			FROM #tBatchRIN BR
			JOIN Un_Cotisation Ct ON Ct.OperID = @BeforeOperID+AddToOperID

		IF @@ERROR <> 0
			SET @iResult = -8
	END

	-- Génération des enregistrements 400 de retrait EPS 
	IF @iResult > 0
	AND @CESGRenunciation = 0 -- On ne renonce pas au PCEE
	BEGIN
		INSERT INTO Un_CESP400 (
				OperID,
				CotisationID,
				ConventionID,
				tiCESP400TypeID,
				vcTransID,
				dtTransaction,
				iPlanGovRegNumber,
				ConventionNo,
				vcSubscriberSINorEN,
				vcBeneficiarySIN,
				fCotisation,
				bCESPDemand,
				dtStudyStart,
				tiStudyYearWeek,
				fCESG,
				fACESGPart,
				fEAPCESG,
				fEAP,
				fPSECotisation,
				tiProgramLength,
				cCollegeTypeID,
				vcCollegeCode,
				siProgramYear,
				fCLB,
				fEAPCLB,
				fPG,
				fEAPPG )
			SELECT
				C4t.OperID,
				C4t.CotisationID,
				C.ConventionID,
				14,
				'FIN',
				C4t.EffectDate,
				P.PlanGovernmentRegNo,
				C.ConventionNo,
				ISNULL(HS.SocialNumber,''),
				HB.SocialNumber,
				0,
				C.bCESGRequested,
				IR.StudyStart,		--dtStudyStart
				CASE CL.CollegeTypeID	--tiStudyYearWeek
					WHEN '01' THEN 30
				ELSE 34 
				END,			
				0,
				0,
				0,
				0,
				-(C4t.Cotisation+C4t.Fee),
				IR.ProgramLength,	--tiProgramLength
				CL.CollegeTypeID,		--cCollegeTypeID
				CL.CollegeCode,		--vcCollegeCode
				IR.ProgramYear,		--siProgramYear
				0,
				0,
				0,
				0
			FROM @tCESP400ToDo C4t
			JOIN dbo.Un_Unit U ON U.UnitID = C4t.UnitID
			JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
			JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
			JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
			JOIN Un_IntReimbOper IRO ON IRO.OperID = C4t.OperID
			JOIN Un_IntReimb IR ON IR.IntReimbID = IRO.IntReimbID
			JOIN Un_College CL ON CL.CollegeID = IR.CollegeID
			WHERE dbo.FN_CRQ_DateNoTime(ISNULL(C.dtRegStartDate,C4t.EffectDate+1)) <= C4t.EffectDate	
				AND HB.HumanID IN (
					SELECT HumanID
					FROM dbo.Mo_Human
					WHERE HumanID = B.BeneficiaryID
						AND ISNULL(SocialNumber,'') <> ''
						)
			
		IF @@ERROR <> 0
			SET @iResult = -9
	END

	-- Génération des enregistrements 400 de remboursement 
	IF @iResult > 0
	AND @CESGRenunciation = 1 -- On renonce au PCEE
	BEGIN
		DECLARE @tCESGTot TABLE (
			ConventionID INT PRIMARY KEY,
			fCESG MONEY NOT NULL,
			fACESG MONEY NOT NULL,
			fCotisationGranted MONEY NOT NULL )

		DECLARE @tCESG400Tot TABLE (
			ConventionID INT PRIMARY KEY,
			fCESG MONEY NOT NULL,
			fACESGPart MONEY NOT NULL )

		INSERT INTO @tCESGTot
			-- Solde SCEE et SCEE+ et solde de cotisations subventionnées
			SELECT
				U.ConventionID,
				
				-- Solde de la SCEE et SCEE+
				fCESG = SUM(fCESG), 
				fACESG = SUM(fACESG), 
				
				fCotisationGranted = SUM(fCotisationGranted) -- Solde des cotisations subventionnées
			FROM #tBatchRIN BR
			JOIN dbo.Un_Unit U ON BR.UnitID = U.UnitID
			JOIN Un_CESP G ON G.ConventionID = U.ConventionID
			GROUP BY U.ConventionID
		
		INSERT INTO @tCESG400Tot
			-- Solde SCEE et SCEE+ à rembourser
			SELECT
				U.ConventionID,
				
				-- Solde de la SCEE et SCEE+
				fCESG = SUM(C4.fCESG),
				fACESGPart = SUM(C4.fACESGPart) 
				
			FROM #tBatchRIN BR
			JOIN dbo.Un_Unit U ON BR.UnitID = U.UnitID
			JOIN Un_CESP400 C4 ON C4.ConventionID = U.ConventionID
			LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID
			LEFT JOIN Un_CESP CE ON CE.OperID = C4.OperID
			WHERE C9.iCESP900ID IS NULL
				AND C4.iCESP800ID IS NULL
				AND CE.iCESPID IS NULL
			GROUP BY U.ConventionID

		INSERT INTO Un_CESP400 (
				OperID,
				CotisationID,
				ConventionID,
				tiCESP400TypeID,
				tiCESP400WithdrawReasonID,
				vcTransID,
				dtTransaction,
				iPlanGovRegNumber,
				ConventionNo,
				vcSubscriberSINorEN,
				vcBeneficiarySIN,
				fCotisation,
				bCESPDemand,
				fCESG,
				fACESGPart,
				fEAPCESG,
				fEAP,
				fPSECotisation,
				fCLB,
				fEAPCLB,
				fPG,
				fEAPPG )
			SELECT
				C4t.OperID,
				C4t.CotisationID,
				C.ConventionID,
				21,
				1,
				'FIN',
				C4t.EffectDate,
				P.PlanGovernmentRegNo,
				C.ConventionNo,
				ISNULL(HS.SocialNumber,''),
				HB.SocialNumber,
				0,
				C.bCESGRequested,
				
				-- SCEE
				CASE
					-- Rembourse rien 0.00 si le solde de subvention et négatif ou à 0.00
					WHEN ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0) <= 0 
						THEN 0
					-- Rembourse tout s'il n'y a pas de cotisations subventionnées
					WHEN ISNULL(G.fCotisationGranted, 0) = 0 
						THEN -(ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0))
					-- Rembourse tout si on retire toutes les cotisations subventionnées
					WHEN C4t.Cotisation + C4t.Fee > ISNULL(G.fCotisationGranted, 0) 
						THEN -(ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0))
					-- Rembourse tout si le proprata selon la formule A/B*C du règlement sur l’épargne-études est plus élevé que le total de la SCEE
					WHEN ROUND((ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0)) / ISNULL(G.fCotisationGranted, 0) * ((C4t.Cotisation + C4t.Fee)*-1), 2) > ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0) 
						THEN -(ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0))
					-- Rembourse au proprata selon la formule A/B*C du règlement sur l’épargne-études si on retire seulement une partie des cotisations subventionnées
					ELSE 
						-(ROUND((ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0)) / ISNULL(G.fCotisationGranted, 0) * ((C4t.Cotisation + C4t.Fee)*-1), 2))
				END,

				-- SCEE+
				CASE
					-- Rembourse rien 0.00 si le solde de subvention et négatif ou à 0.00
					WHEN ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0) <= 0 
						THEN 0
					-- Rembourse tout s'il n'y a pas de cotisations subventionnées
					WHEN ISNULL(G.fCotisationGranted, 0) = 0 
						THEN -(ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0))
					-- Rembourse tout si on retire toutes les cotisations subventionnées
					WHEN C4t.Cotisation + C4t.Fee > ISNULL(G.fCotisationGranted, 0) 
						THEN -(ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0))
					-- Rembourse tout si le proprata selon la formule A/B*C du règlement sur l’épargne-études est plus élevé que le total de la SCEE
					WHEN ROUND((ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0)) / ISNULL(G.fCotisationGranted, 0) * ((C4t.Cotisation + C4t.Fee)*-1), 2) > ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0) 
						THEN -(ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0))
					-- Rembourse au proprata selon la formule A/B*C du règlement sur l’épargne-études si on retire seulement une partie des cotisations subventionnées
					ELSE 
						-(ROUND((ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0)) / ISNULL(G.fCotisationGranted, 0) * ((C4t.Cotisation+C4t.Fee)*-1), 2))
				END,

				0,
				0,
				0,
				0,
				0,
				0,
				0
			FROM @tCESP400ToDo C4t
			JOIN dbo.Un_Unit U ON U.UnitID = C4t.UnitID
			JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
			JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
			JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
			LEFT JOIN @tCESGTot G ON G.ConventionID = C.ConventionID
			LEFT JOIN @tCESG400Tot C4 ON C4.ConventionID = C.ConventionID
			WHERE dbo.FN_CRQ_DateNoTime(ISNULL(C.dtRegStartDate,C4t.EffectDate+1)) <= C4t.EffectDate		
				AND HB.HumanID IN (
					SELECT HumanID
					FROM dbo.Mo_Human
					WHERE HumanID = B.BeneficiaryID
						AND ISNULL(SocialNumber,'') <> ''
						)
						
		IF @@ERROR <> 0
			SET @iResult = -10
	END

	IF @iResult > 0
	BEGIN
		-- Inscrit le vcTransID avec le ID FIN + <iCESP400ID>.
		UPDATE Un_CESP400
		SET vcTransID = 'FIN'+CAST(iCESP400ID AS VARCHAR(12))
		WHERE vcTransID = 'FIN' 

		IF @@ERROR <> 0
			SET @iResult = -11
	END

	IF @iResult > 0
		--------------------
		COMMIT TRANSACTION
		--------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
    	--------------------

	-- Mise à jour des états de conventions et unités
	IF @iResult > 0
	BEGIN
		DECLARE 
			@vcUnitIDs VARCHAR(8000)

		-- Crée une chaîne de caractère avec tout les groupes d'unités affectés
		DECLARE UnitIDs CURSOR FOR
			SELECT
				I.UnitID
			FROM #tBatchRIN I
			JOIN dbo.Un_Unit U ON U.UnitID = I.UnitID
	
		OPEN UnitIDs
	
		FETCH NEXT FROM UnitIDs
		INTO
			@UnitID
	
		SET @vcUnitIDs = ''
	
		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			SET @vcUnitIDs = @vcUnitIDs + CAST(@UnitID AS VARCHAR(30)) + ','
		
			FETCH NEXT FROM UnitIDs
			INTO
				@UnitID
		END
	
		CLOSE UnitIDs
		DEALLOCATE UnitIDs
	
		-- Appelle la procédure qui met à jour les états des groupes d'unités et des conventions
		EXECUTE TT_UN_ConventionAndUnitStateForUnit @vcUnitIDs 
	END

	-- Retourne les UnitID des groupes d'unités dont le montant souscrit n'est pas atteint
	SELECT
		UnitID = V.Val
	FROM dbo.FN_CRQ_BlobToIntegerDateTable(@iBlobID) V
	WHERE Val NOT IN (SELECT UnitID FROM @tUnitDate)
		AND @iResult = 1 -- Seulement si le traitement c'est effectué.
*/
	RETURN @iResult
END