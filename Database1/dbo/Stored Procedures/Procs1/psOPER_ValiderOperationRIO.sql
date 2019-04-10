/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc

Code de service		:		psOPER_ValiderOperationRIO
Nom du service		:		Valider une opération RIO
But					:		Effectuer les validations pour les opérations de conversion RIO et RIM
							
Facette				:		OPER
Reférence			:		UniAccés-Noyau-OPER

Parametres d'entrée :	Parametres					Description
						-----------------------------------------------------------------------------------------------------
						iID_Connexion				ID de connexion de l’usager qui demande la liste.
						vcType_Conversion			Code du type de conversion (RIO, RIM ou TRI) - FT1
						iIDs_Convention				Liste des conventions à valider, séparées par des points virgules
						iIDs_GroupeUnites			Liste des groupes d'unité à valider, séparés par des points virgules
						iByPassJVM					Indicateur pour surpasser la validation de la JVM
						vcListeMessages				Liste des messages retournés par la validation sous ce format:

Exemple d'appel:

Parametres de sortie : Table						Champs								Description
					   -----------------			---------------------------			--------------------------
													@vcDescTransaction					Description de la transaction.selon :
																						si c’est une cotisation :
																							[Un_Convention.ConventionNo] + “ -> “ + [Un_Unit.InForceDate] + “ (“ + [Un_Unit.UnitQty] + “)“
																						si c’est une transaction sur la convention ou sur la subvention canadienne : 
Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2011-04-11					Frédérick Thibault 						Création de la procédure stockée
						2011-07-01					Frédérick Thibault						Ajouté Validation #5
						2011-07-26					Frédérick Thibault						Ajouté paramètre @iIDs_GroupeUnites
						2011-12-15					Frédérick Thibault						Ajouté validations @vcMsgValid7 et @vcMsgValid8
						
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_ValiderOperationRIO] (
	 @iID_Connexion		INTEGER				-- ID de connexion de l’usager qui demande la liste.
	,@vcType_Conversion	VARCHAR(3)			-- Code du type de conversion (RIO, RIM ou TRI)
	,@iIDs_Convention	VARCHAR(MAX)		-- Liste des conventions à valider, séparées par des points virgules
	,@iIDs_GroupeUnites	VARCHAR(MAX)		-- Liste des groupes d'unité à valider, séparés par des points virgules
	,@iByPassJVM		INTEGER = 0			-- Indicateur pour surpasser la validation de la JVM
	,@vcListeMessages	VARCHAR(MAX)		-- Liste des messages retournés par la validation sous ce format:
	
											--	Format:
											--	[CodeMessage];[ConventionID];[ConventionID];[ConventionID]#[CodeMessage];[ConventionID];[ConventionID];[ConventionID]#
											--	Exemple:
											--	'CONVQ0013;11111;22222;33333#CONVE9999;22222;44444;66666#'
)
AS
	BEGIN
	
	DECLARE  @iID_Utilisateur		INTEGER
			,@mMontant_Frais_TTC	MONEY
			,@iCode_Retour			INTEGER
			,@vcCode_Message		VARCHAR(9)
			,@tiValid_12Mois		TINYINT
			,@iID_Convention		INTEGER
			,@iID_GroupeUnites		INTEGER
			,@dtDateConvention		DATETIME
			,@iPosDebut				INT
			,@iPosFin				INT
			,@iStr_Len				INTEGER
			,@vcCode_Type_Frais		VARCHAR(3)
			,@CotisationCol			MONEY
			,@FeeCol				MONEY
			,@FeeInd				MONEY
			,@FeeByUnitInd			MONEY
			,@vcMsgValid1			VARCHAR(MAX)
			,@vcMsgValid2			VARCHAR(MAX)
			,@vcMsgValid3			VARCHAR(MAX)
			,@vcMsgValid4			VARCHAR(MAX)
			,@vcMsgValid5			VARCHAR(MAX)
			,@vcMsgValid6			VARCHAR(MAX)
			,@vcMsgValid7			VARCHAR(MAX)
			,@vcMsgValid8			VARCHAR(MAX)
	
	-- Creation de la table temporaire contenant les groupes d'unités à valider
	DECLARE @tblUnitIds TABLE
					(
					iID_Unite	INTEGER
					)
					
	SET @iPosDebut = 1
	SET	@iPosFin = CHARINDEX(';', @iIDs_GroupeUnites, @iPosDebut) - 1
	SET @iID_GroupeUnites = SUBSTRING(@iIDs_GroupeUnites, @iPosDebut, @iPosFin - @iPosDebut + 1)
	
	WHILE @iPosFin > 0
		BEGIN
		
		INSERT INTO @tblUnitIds
			VALUES	(
					@iID_GroupeUnites
					)

		-- Passe au groupe d'unité suivant
		SET	@iPosDebut = @iPosFin + 2
		SET	@iPosFin = CHARINDEX(';', @iIDs_GroupeUnites, @iPosDebut) - 1
		
		IF @iPosFin > 0
			SET @iID_GroupeUnites = SUBSTRING(@iIDs_GroupeUnites, @iPosDebut, @iPosFin - @iPosDebut + 1)

		END

	-- Va chercher le cout des frais pour une unité du plan individuel
	SELECT @FeeByUnitInd = M.FeeByUnit
	FROM Un_Modal M 
	JOIN Un_Plan P ON P.PlanID = M.PlanID
	WHERE P.PlanTypeID = 'IND'
	GROUP BY M.ModalDate
			,M.FeeByUnit
	HAVING M.ModalDate = max(M.ModalDate)
	
	-- Initialisation des variables
	SET @mMontant_Frais_TTC = 0
	SET	@iID_Convention = NULL
	SET @iCode_Retour = 0
	
	SET @iID_Utilisateur = (SELECT UserID FROM Mo_Connect WHERE ConnectID = @iID_Connexion)
	
	DECLARE @tblMois	TABLE
		(
		 iMois	INTEGER
		,vcMois	VARCHAR(15)
		)
			
	INSERT INTO @tblMois VALUES (1, 'Janvier')
	INSERT INTO @tblMois VALUES (2, 'Février')
	INSERT INTO @tblMois VALUES (3, 'Mars')
	INSERT INTO @tblMois VALUES (4, 'Avril')
	INSERT INTO @tblMois VALUES (5, 'Mai')
	INSERT INTO @tblMois VALUES (6, 'Juin')
	INSERT INTO @tblMois VALUES (7, 'Juillet')
	INSERT INTO @tblMois VALUES (8, 'Août')
	INSERT INTO @tblMois VALUES (9, 'Septembre')
	INSERT INTO @tblMois VALUES (10, 'Octobre')
	INSERT INTO @tblMois VALUES (11, 'Novembre')
	INSERT INTO @tblMois VALUES (12, 'Décembre')
	
	-- Traitement de chaque convention
	IF RIGHT(@iIDs_Convention, 1) <> ';' 
		SET @iIDs_Convention = @iIDs_Convention + ';'
		
	SET @iPosDebut = 1
	SET	@iPosFin = CHARINDEX(';', @iIDs_Convention, @iPosDebut) - 1
	SET @iID_Convention = SUBSTRING(@iIDs_Convention, @iPosDebut, @iPosFin - @iPosDebut + 1)

	WHILE @iPosFin > 0
		BEGIN
		
		SELECT @dtDateConvention = dtRegStartDate
		FROM dbo.Un_Convention 
		WHERE ConventionID = @iID_Convention
		
		-- Recherche du montant de frais de service
		SET @tiValid_12Mois = (SELECT dbo.fnGENE_ObtenirParametre (
							'OPER_VALIDATION_12_MOIS'
							,@dtDateConvention
							,NULL
							,NULL
							,NULL
							,NULL
							,NULL))
			
		IF @tiValid_12Mois = 0 -- Appliquer des frais de service
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
			EXEC @iCode_Retour = dbo.psOPER_SimulerMontantOperationFrais
												 @vcCode_Type_Frais = @vcCode_Type_Frais
												,@mMontant_Frais = NULL
												,@mMontant_Frais_TTC	= @mMontant_Frais_TTC OUTPUT
												,@vcCode_Message		= @vcCode_Message OUTPUT

			IF @iCode_Retour <> 1
				BEGIN
				
				SET @iCode_Retour = -2
				GOTO END_TRANSACTION
				
				END
			
			END
		ELSE
			BEGIN
			
			-- Aucun frais de service car l'ouverture de la conversion individuelle n'entre pas dans 
			-- le délai spécifié par le paramètre @tiValid_12Mois
			SET @mMontant_Frais_TTC = 0 
			
			END
		
		-- Inversion du montant pour le rendre négatif
		SET @mMontant_Frais_TTC = @mMontant_Frais_TTC * -1

		IF @iByPassJVM = 0
			BEGIN
			
			-- Appel à la procédure de validation de la JVM
			EXEC @iCode_Retour = dbo.psCONV_VerifierJVM
							 @iID_Utilisateur = @iID_Utilisateur
							,@iID_Convention = @iID_Convention
							,@cCode_Type_Retrait = NULL
							,@mMontant_Operation = @mMontant_Frais_TTC
							,@vcCode_Message = @vcCode_Message OUTPUT

			-- JVM non respectée
			IF @iCode_Retour = 0
				BEGIN
				
				IF @vcCode_Message = 'CONVQ0011'
					BEGIN
					
					IF @vcMsgValid1 IS NULL OR @vcMsgValid1 = ''
						SET @vcMsgValid1 = 'CONVQ0013'
						
					SET @vcMsgValid1 = @vcMsgValid1 + ';' + CAST(@iID_Convention AS VARCHAR(10))
					
					END
				
				IF @vcCode_Message = 'CONVE0026'
					BEGIN

					IF @vcMsgValid1 IS NULL OR @vcMsgValid1 = ''
						SET @vcMsgValid1 = 'CONVE0028'
						
					SET @vcMsgValid1 = @vcMsgValid1 + ';' + CAST(@iID_Convention AS VARCHAR(10))
					
					END
		
				END
			
			END
		
			-------------------------------------------------------------------------------
			---- Validation 60 jours sur TRI - FT1
			-------------------------------------------------------------------------------
			--IF	@vcType_Conversion = 'TRI'
			--	BEGIN
				
			--	DECLARE @dtDate_Debut_Convention DATETIME
				
			--	SELECT @dtDate_Debut_Convention = MAX(UN.InForceDate)
			--	FROM dbo.Un_Convention CN
			--	JOIN dbo.Un_Unit UN ON UN.ConventionID = CN.ConventionID 
			--	WHERE CN.ConventionID = @iID_Convention

			--	-- SI LA CONVENTION SOURCE N'A PAS AU MOINS 60 JOURS DE VIE
			--	IF DATEDIFF(day, @dtDate_Debut_Convention, GETDATE()) < 60
			--		BEGIN
					
			--		SET @vcCode_Message = 'OPERE0026'
			--		SET @iCode_Retour = 0
			--		GOTO ROLLBACK_SECTION
					
			--		END
				
			--	END

		--------------------------------------------------------------------------------
		-- Valider si les frais d'unité ont tous été comblés lors d'un TRI - FT1
		--------------------------------------------------------------------------------
		IF	@vcType_Conversion = 'TRI'
			BEGIN
			
			IF NOT EXISTS(	SELECT 1
							FROM dbo.Un_Unit U
							JOIN Un_Modal M ON M.ModalID = U.ModalID
							JOIN dbo.Un_Convention CN ON CN.ConventionID = U.ConventionID
							JOIN Un_Cotisation CT ON CT.UnitID = U.UnitID
							WHERE CN.ConventionID = @iID_Convention
							GROUP BY CN.ConventionID
							HAVING SUM(CT.Fee) >= (	SELECT SUM(M.FeeByUnit * U.UnitQty)
													FROM dbo.Un_Unit U
													JOIN Un_Modal M ON M.ModalID = U.ModalID
													WHERE U.ConventionID = @iID_Convention
													)
							)
			
				BEGIN

				-- Si l'utilisateur peut bypasser la vérification
				IF dbo.fnSECU_ObtenirAccessibiliteDroitUtilisateur
												(
												 @iID_Utilisateur
												,'OPER_SURPASSER_VERIFICATION_FRAIS'
												) = 1
					BEGIN

					IF @vcMsgValid2 IS NULL OR @vcMsgValid2 = ''
						SET @vcMsgValid2 = 'OPERQ0008'
					
					SET @vcMsgValid2 = @vcMsgValid2 + ';' + CAST(@iID_Convention AS VARCHAR(10))

					END
				ELSE 
					BEGIN

					IF @vcMsgValid2 IS NULL OR @vcMsgValid2 = ''
						SET @vcMsgValid2 = 'OPERE0027'
					
					SET @vcMsgValid2 = @vcMsgValid2 + ';' + CAST(@iID_Convention AS VARCHAR(10))
					
					END
					
				END
			
			END

		-----------------------------------------------------------------------------------------------------------
		-- Valider si la convention collective a assez d'épargne et frais pour combler les frais de l'individuelle
		-----------------------------------------------------------------------------------------------------------
		IF @vcType_Conversion = 'TRI'
			BEGIN
			
			-- Va chercher le total d'épargne et de frais des groupes d'unités sélectionnés
			SELECT	 @CotisationCol = SUM(ISNULL(CT.Cotisation, 0))
					,@FeeCol = SUM(ISNULL(CT.Fee, 0))
			FROM Un_Unit		UN
			JOIN @tblUnitIds	tUI	ON tUI.iID_Unite = UN.UnitID
			JOIN Un_Cotisation	CT	ON CT.UnitID = UN.UnitID
			WHERE UN.ConventionID = @iID_Convention
			GROUP BY UN.ConventionID
			
			-- Va chercher le total des frais dans la convention individuelle déjà existante (s'il y a lieu)
			SELECT @FeeInd = ISNULL(SUM(ISNULL(CT.Fee, 0)), @FeeByUnitInd)
			FROM Un_Unit		UN
			JOIN Un_Cotisation	CT	ON CT.UnitID = UN.UnitID
			JOIN tblOPER_OperationsRIO RIO ON RIO.iID_Convention_Source = UN.ConventionID
			WHERE UN.ConventionID = @iID_Convention
			
			-- Si le montant total des épargnes et frais des groupes d'unités sélectionnés sont
			-- insuffisants pour combler les frais de la convention individuelle on retourne une erreur
			IF @CotisationCol + @FeeCol < @FeeInd
				BEGIN
				
				IF @vcMsgValid6 IS NULL OR @vcMsgValid6 = ''
					SET @vcMsgValid6 = 'OPERE0031'
				
				SET @vcMsgValid6 = @vcMsgValid6 + ';' + CAST(@iID_Convention AS VARCHAR(10))
				
				END
			ELSE
				BEGIN
				
				-- Si le montant total des frais des groupes d'unités sélectionnés sont insuffisants pour combler
				-- les frais de la convention individuelle on retourne une erreur ou un message d'avertissement
				IF @FeeCol < @FeeInd
					BEGIN

					-- Si l'utilisateur peut bypasser la vérification
					IF dbo.fnSECU_ObtenirAccessibiliteDroitUtilisateur
													(
													 @iID_Utilisateur
													,'OPER_SURPASSER_VALIDATION_NB_UNITES'
													) = 1
						BEGIN

						IF @vcMsgValid3 IS NULL OR @vcMsgValid3 = ''
							SET @vcMsgValid3 = 'OPERQ0009'
						
						SET @vcMsgValid3 = @vcMsgValid3 + ';' + CAST(@iID_Convention AS VARCHAR(10))

						END
					ELSE 
						BEGIN

						IF @vcMsgValid3 IS NULL OR @vcMsgValid3 = ''
							SET @vcMsgValid3 = 'OPERE0028'
						
						SET @vcMsgValid3 = @vcMsgValid3 + ';' + CAST(@iID_Convention AS VARCHAR(10))
						
						END
					END
				END
			END

		--------------------------------------------------------------------------------
		-- Valider si le bénéficiaire de la convention a un NAS
		--------------------------------------------------------------------------------
		IF @vcType_Conversion = 'TRI'
			BEGIN

			IF NOT EXISTS(	SELECT 1
							FROM dbo.Mo_Human HU
							JOIN dbo.Un_Convention CN ON CN.BeneficiaryID = HU.HumanID 
							WHERE	CN.ConventionID = @iID_Convention
							AND		HU.SocialNumber IS NOT NULL
							)
				
				BEGIN
				
				IF @vcMsgValid4 IS NULL OR @vcMsgValid4 = ''
					SET @vcMsgValid4 = 'OPERE0029'
				
				SET @vcMsgValid4 = @vcMsgValid4 + ';' + CAST(@iID_Convention AS VARCHAR(10))
				
				END
			
			END

		--------------------------------------------------------------------------------
		-- Valider si des opérations futures sont prévues à la convention
		--------------------------------------------------------------------------------
		IF @vcType_Conversion = 'TRI'
			BEGIN
			
			IF EXISTS (	SELECT 1
						FROM Un_Oper OP
						JOIN Un_Cotisation CT ON CT.OperID = OP.OperID
						JOIN dbo.Un_Unit UN ON UN.UnitID = CT.UnitID
						JOIN dbo.Un_Convention CN ON CN.ConventionID = UN.ConventionID
						WHERE	CN.ConventionID = @iID_Convention
						AND		OP.OperDate > getdate()
						)
				
				BEGIN
				
				IF @vcMsgValid5 IS NULL OR @vcMsgValid5 = ''
					SET @vcMsgValid5 = 'OPERE0030'
				
				SET @vcMsgValid5 = @vcMsgValid5 + ';' + CAST(@iID_Convention AS VARCHAR(10))
				
				END

			END
			
		--------------------------------------------------------------------------------
		-- Valider si tous les taux de rendements ont été saisis
		--------------------------------------------------------------------------------
		IF @vcType_Conversion = 'TRI' OR @vcType_Conversion = 'RIM'
			BEGIN
			
			-- Si convention collective REEEFLEX
			IF (SELECT vcCode_Regroupement
				FROM tblCONV_RegroupementsRegimes RR
				JOIN Un_Plan PL ON PL.iID_Regroupement_Regime = RR.iID_Regroupement_Regime 
				JOIN dbo.Un_Convention CN ON CN.PlanID = PL.PlanID
				WHERE CN.ConventionID = @iID_Convention
				) = 'REF'
				
				BEGIN
			
				/*
				En date de la transaction de conversion, on recule jusqu’au [20]e (paramètre) jour du mois le plus proche, 
				et si le mois précédent ce mois n’a pas été calculé on affiche le message.

				Exemples :

				1.	On est le 8 décembre.  Le [20]e jour antérieur le plus proche est le [20] novembre.  
					Le mois qui précède est octobre.  Si les taux d’OCTOBRE n’ont pas été saisis on affiche le message.

				2.	On est le 25 décembre.  Le [20]e jour antérieur le plus proche est le [20] décembre.  
					Le mois qui précède est novembre.  Si les taux de NOVEMBRE n’ont pas été saisis on affiche le message.
				*/
				
				DECLARE	 @dtDate			DATETIME
						,@iJourDuMois		INTEGER
						,@iMoisManquants	VARCHAR(MAX)
						,@iCompteur			INTEGER
						
				SET @dtDate = getdate()
				SET @iJourDuMois = day(@dtDate)

				WHILE @iJourDuMois <> 20 --param
					BEGIN
					
					SET @dtDate = dateadd(day, -1, @dtDate)
					SET @iJourDuMois = datepart(day, @dtDate)
					
					END
				
				---------------------------------------------------------------------------------
				-- TXI - 10. Épargne des conventions individuelles issues d'un régime REEEFLEX
				---------------------------------------------------------------------------------
				SET @iCompteur = 0
				SET @iMoisManquants = ''
				SET @dtDate = dateadd(month, -12, @dtDate)

				-- On vérifie 12 mois en arrière
				WHILE @iCompteur < 12
					BEGIN

					IF NOT EXISTS(	SELECT 1
									FROM tblOPER_Rendements RN
									JOIN tblOPER_TypesRendement TpR ON TpR.tiID_Type_Rendement = RN.tiID_Type_Rendement
									WHERE CAST(datepart(year, dtDate_Calcul_Rendement) AS VARCHAR) + CAST(datepart(month, dtDate_Calcul_Rendement) AS VARCHAR) = CAST(datepart(year, @dtDate) AS VARCHAR) + CAST(datepart(month, @dtDate) AS VARCHAR)
									AND TpR.vcCode_Rendement = 'TXI'
									)
						BEGIN
						
						-- Mois absent
						SET @iMoisManquants = @iMoisManquants + ' ' + (	SELECT vcMois
																		FROM @tblMois
																		WHERE iMois = datepart(month, @dtDate)
																		)
						
						END
					
					SET @dtDate = dateadd(month, 1, @dtDate)
					SET @iCompteur = @iCompteur + 1
					
					END
				
				IF @iMoisManquants <> ''
					BEGIN
					
					IF @vcMsgValid7 IS NULL OR @vcMsgValid7 = ''
						BEGIN
						SET @vcMsgValid7 = 'OPERQ0010'
						SET @vcMsgValid7 = @vcMsgValid7 + ';' + CAST(@iMoisManquants AS VARCHAR(10))
						END
				
					END
					
				-----------------------------------------------------------------------------------------------------
				-- RXI - 11. Revenus acc. sur l'épargne des conventions individuelles issues d'un régime REEEFLEX
				-----------------------------------------------------------------------------------------------------
				SET @iCompteur = 0
				SET @iMoisManquants = ''
				SET @dtDate = dateadd(month, -12, @dtDate)
				
				-- On vérifie 12 mois en arrière
				WHILE @iCompteur < 12
					BEGIN

					IF NOT EXISTS(	SELECT 1
									FROM tblOPER_Rendements RN
									JOIN tblOPER_TypesRendement TpR ON TpR.tiID_Type_Rendement = RN.tiID_Type_Rendement
									WHERE CAST(datepart(year, dtDate_Calcul_Rendement) AS VARCHAR) + CAST(datepart(month, dtDate_Calcul_Rendement) AS VARCHAR) = CAST(datepart(year, @dtDate) AS VARCHAR) + CAST(datepart(month, @dtDate) AS VARCHAR)
									AND TpR.vcCode_Rendement = 'RXI'
									)
						BEGIN
						
						-- Mois absent
						SET @iMoisManquants = @iMoisManquants + ' ' + (	SELECT vcMois
																		FROM @tblMois
																		WHERE iMois = datepart(month, @dtDate)
																		)
						
						END
					
					SET @dtDate = dateadd(month, 1, @dtDate)
					SET @iCompteur = @iCompteur + 1
					
					END
				
				IF @iMoisManquants <> ''
					BEGIN
					
					IF @vcMsgValid8 IS NULL OR @vcMsgValid8 = ''
						BEGIN
						SET @vcMsgValid8 = 'OPERQ0011'
						SET @vcMsgValid8 = @vcMsgValid8 + ';' + CAST(@iMoisManquants AS VARCHAR(10))
						END
				
					END
				END
			END
		
		-- Passe à la convention suivante
		SET	@iPosDebut = @iPosFin + 2
		SET	@iPosFin = CHARINDEX(';', @iIDs_Convention, @iPosDebut) - 1
		
		IF @iPosFin > 0
			SET @iID_Convention = SUBSTRING(@iIDs_Convention, @iPosDebut, @iPosFin - @iPosDebut + 1)
		
		END 
		
	SET @vcListeMessages =	ISNULL(@vcMsgValid1,'') + '#' + 
							ISNULL(@vcMsgValid2,'') + '#' + 
							ISNULL(@vcMsgValid3,'') + '#' + 
							ISNULL(@vcMsgValid4,'') + '#' + 
							ISNULL(@vcMsgValid5,'') + '#' + 
							ISNULL(@vcMsgValid6,'') + '#' + 
							ISNULL(@vcMsgValid7,'') + '#' + 
							ISNULL(@vcMsgValid8,'')
							
	SELECT @vcListeMessages as vcCodeMessage
	--SELECT '' as vcCodeMessage -- TEST

END_TRANSACTION:

	END
	

