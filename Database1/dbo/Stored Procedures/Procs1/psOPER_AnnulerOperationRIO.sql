/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc

Code de service		:		psOPER_AnnulerOperationRIO
Nom du service		:		Annuler une opération RIO.
But					:		Annuler une opération RIO.
							dans les tables d'uniAccés.
Facette				:		OPER
Reférence			:		UniAccés-Noyau-OPER

Parametres d'entrée :	Parametres					Description
						-----------------------------------------------------------------------------------------------------
						@iID_Connexion			Identifiant de la connexion
						@iID_Oper_RIO			Identifiant de l'opération RIO à annuler
Exemple d'appel:
						@iID_Connexion = 1, --ID de connection de l'usager
						@iID_Oper_RIO = 17184475, --ID de l'opération RIO

Parametres de sortie : Table						Champs								Description
					   -----------------			---------------------------			--------------------------
													@iCode_Retour						C'est un code de retour qui indique si le traitement :
																						 s'est terminée avec succès et si les frais sont couverts
																						@iCode_Retour < 0  : Echec
																						@iCode_Retour = 0  : traitement s'est bien deroulé
			
Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2008-06-20					Nassim Rekkab							Création de procédure stockée
						2008-11-24					Josée Parent							Modification pour utiliser la fonction "fnCONV_ObtenirDateFinRegime"
						2008-11-25					Éric Deshaies							Activation du trigger sur les unités
						2010-10-04					Steve Gouin								Gestion des disable trigger par #DisableTrigger
						2011-03-11					Frédérick Thibault						Ajout des nouvelles fonctionnalités du prospectus 2010-2011 (FT1)
						2011-10-14					Éric Deshaies							Correction d'une erreur de doublons dans la table "Un_OperCancelation"
						2011-12-19					Éric Deshaies							S'assurer que les annulations vont dans Un_OperCancelation et que la date d'effectivité
																							soit la même dans l'annulation que dans la transaction originale. GLPIs# 2364, 2365, 1622
																							S'assurer qu'il y a un ordre logique dans l'annulation des différentes
																							annulations (FRS, TFR, IN+) avant l'annulation du RIO/RIM/TRI
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_AnnulerOperationRIO]
( 
	@iID_Connexion INTEGER,
	@iID_Oper_RIO INTEGER
) 
AS
BEGIN
		DECLARE 
				@iCodeRetour INTEGER,
				@iOperID INTEGER,
				@iIDConventionSource INTEGER,
				@iIDConventionDestination INTEGER,
				@iIDUniteSource INTEGER,
				@iIDUniteDestination INTEGER,
				@mtCotisationInversee MONEY,
				@mtFraisInverse MONEY,
				@iUnitIDCotisation INTEGER,
				@iCotisationID INTEGER,
				@mtMontInverseConvention MONEY,
				@iIDConvention INTEGER,
				@vcConventionOperTypeID VARCHAR(3),
				@vcUnitIDs VARCHAR(8000),
				@dtAujourdhui DATETIME, --Date du Jour
				@iCode_Retour INTEGER,
				@dtRegEndDateAdjust DATETIME,
				@dtDate_Effective DATETIME
				,@vcOperType				VARCHAR(3)	-- FT1
				,@iID_Operation_Enfant		INTEGER		-- FT1
				,@iID_Raison_Association	INTEGER		-- FT1
				,@iID_Operation_Enfant_Annu	INTEGER		-- FT1
				,@vcOperType_Enfant			VARCHAR(3)	-- FT1
				,@vcCode_Message			VARCHAR(10)	-- FT1
				,@dtDate_Operation			DATETIME	-- FT1

		--Desactiver le service (Trigger)TUn_Cotisation_State
		IF object_id('tempdb..#DisableTrigger') is null
			CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))

		--;DISABLE TRIGGER TUn_Cotisation_State ON Un_Cotisation
		INSERT INTO #DisableTrigger VALUES('TUn_Cotisation_State')				

		--Desactiver le service (Trigger)TUn_Cotisation_Doc
		--;DISABLE TRIGGER TUn_Cotisation_Doc ON Un_Cotisation
		INSERT INTO #DisableTrigger VALUES('TUn_Cotisation_Doc')				

		--Desactiver le service (Trigger)TUn_Unit_State
		--;DISABLE TRIGGER TUn_Unit_State ON Un_Unit 
		INSERT INTO #DisableTrigger VALUES('TUn_Unit_State')				

	CREATE TABLE #tblTEMP_AssociationOperations
		(iID_Operation_Enfant INT,
		 iID_Raison_Association INT)

	----------------------------
	BEGIN TRANSACTION
	----------------------------
	
	SET @iCode_Retour = 0

	SET @dtAujourdhui = GETDATE()
	
	-- Obtention du type et de la date d'opération de conversion - FT1
	SELECT	 @vcOperType		= OperTypeID
			,@dtDate_Operation	= OperDate
	FROM Un_Oper
	WHERE OperID = @iID_Oper_RIO

	--Initialiser les variables:
	SELECT @iIDConventionSource = OpRIO.iID_Convention_Source,
		   @iIDConventionDestination = OpRIO.iID_Convention_Destination,
		   @iIDUniteSource = OpRIO.iID_Unite_Source,
		   @iIDUniteDestination = OpRIO.iID_Unite_Destination
	FROM tblOPER_OperationsRIO OpRIO
	WHERE OpRIO.iID_Oper_RIO = @iID_Oper_RIO

	------------------------------------------------------------------------------------
	-- Annulation des opérations enfants (si présentes) - FT1
	------------------------------------------------------------------------------------
		DECLARE curOperEnf CURSOR FOR
			--Initialiser les variables 
			SELECT	 iID_Operation_Enfant
					,iID_Raison_Association
			FROM tblOPER_AssociationOperations
			WHERE iID_Operation_Parent = @iID_Oper_RIO
			
		OPEN curOperEnf
		
		FETCH NEXT FROM curOperEnf INTO  @iID_Operation_Enfant
										,@iID_Raison_Association
		
		WHILE @@FETCH_STATUS = 0
			BEGIN
			
			SET @vcOperType_Enfant = (	SELECT OperTypeID
										FROM Un_Oper
										WHERE OperID = @iID_Operation_Enfant)
			
			-- Annulation d'une opération de frais
			IF @vcOperType_Enfant = 'FRS'
				BEGIN
				
				EXEC @iCodeRetour = psOPER_AnnulerOperationFrais	 @iID_Connexion
																	,@iID_Operation_Enfant
																	,NULL
																	,@vcCode_Message
				
				IF @iCodeRetour > 0
					BEGIN
					
					SET @iID_Operation_Enfant_Annu = (	SELECT OperID 
														FROM Un_OperCancelation
														WHERE OperSourceID = @iID_Operation_Enfant
													)
					
					END
				
				END
				
			-- Annulation d'une opération de rendement INM (IN+)
			IF @vcOperType_Enfant = 'IN+'
				BEGIN
				
				DECLARE @iOperIDRend INTEGER
				
				-- Création d'une opération d'annulation
				EXEC @iOperIDRend = SP_IU_UN_Oper	 @iID_Connexion
													,0
													,'IN+'
													,@dtAujourdhui
				
				SET @iID_Operation_Enfant_Annu = @iOperIDRend

				-- Identifier les transactions annulées		
				INSERT INTO Un_OperCancelation
					   (OperSourceID,
						OperID)
				VALUES
					   (@iID_Operation_Enfant,
						@iID_Operation_Enfant_Annu)
				
				-- Création d'une opération d'annulation sur la convention
				INSERT INTO	dbo.Un_ConventionOper
							(
							 OperID
							,ConventionID
							,ConventionOperTypeID
							,ConventionOperAmount
							) 
				SELECT 
							 @iOperIDRend
							,@iIDConventionDestination
							,'INM'
							,sum(CO.ConventionOperAmount) *-1
				FROM Un_ConventionOper CO
				WHERE CO.OperID = @iID_Operation_Enfant
				
				END
				
			IF @@Error <> 0 OR @iCodeRetour <= 0
				BEGIN

				CLOSE curOperEnf
				DEALLOCATE curOperEnf
				GOTO ROLLBACK_SECTION
				
				END
				
			---- Création d'une association pour les opérations d'annulation
			--SET @iID_Operation_Enfant_Annu = (	SELECT OperID 
			--									FROM Un_OperCancelation
			--									WHERE OperSourceID = @iID_Operation_Enfant
			--									)
			IF @iID_Operation_Enfant_Annu IS NOT NULL
				BEGIN
--SELECT @iID_Operation_Enfant_Annu AS iID_Operation_Enfant_Annu
					INSERT INTO #tblTEMP_AssociationOperations
					VALUES (@iID_Operation_Enfant_Annu,@iID_Raison_Association)
				END
				
			-- Lecture de l'enregistrement suivant
			FETCH NEXT FROM curOperEnf INTO  @iID_Operation_Enfant
										,@iID_Raison_Association
				
			END
			
		CLOSE curOperEnf
		DEALLOCATE curOperEnf
	
	--------------------------------------------------------------------------------------------------
	-- Annulation de toute opération de résilisation (RES) et transfert de frais (TFR) post TRI - FT1
	--------------------------------------------------------------------------------------------------
		SELECT @iID_Raison_Association = iID_Raison_Association
		FROM tblOPER_RaisonsAssociation
		WHERE vcCode_Raison = @vcOperType
		
		SELECT @iIDConventionSource = iID_Convention_Source
		FROM tblOPER_OperationsRIO
		WHERE iID_Oper_RIO = @iID_Oper_RIO
		
		DECLARE curOperRes CURSOR FOR
			SELECT OP.OperID
			FROM Un_Convention	CN
			JOIN Un_Unit		UN ON UN.ConventionID = CN.ConventionID
			JOIN Un_Cotisation	CT ON CT.UnitID = UN.UnitID
			JOIN Un_Oper		OP ON OP.OperID = CT.OperID
			LEFT JOIN Un_OperCancelation OC1 on OC1.OperSourceID = OP.OperID
			LEFT JOIN Un_OperCancelation OC2 on OC2.OperID = OP.OperID
			WHERE	UN.ConventionID	=  @iIDConventionSource
			AND		OP.OperDate		>= @dtDate_Operation
			--AND		OP.OperTypeID	IN ('RES', 'TFR')
			AND		OP.OperTypeID	= 'TFR'
			AND		OC1.OperSourceID IS NULL
			AND		OC2.OperSourceID IS NULL
			ORDER BY OP.OperID DESC
			
		OPEN curOperRes
		
		FETCH NEXT FROM curOperRes INTO @iID_Operation_Enfant
		
		WHILE @@FETCH_STATUS = 0
			BEGIN
			
			IF @iID_Operation_Enfant IS NOT NULL
				BEGIN
				
				EXEC @iCodeRetour = TT_UN_CancelOperation	 @iID_Connexion
															,@iID_Operation_Enfant
				
				IF @@Error <> 0 OR @iCodeRetour <= 0
					BEGIN
					
					CLOSE curOperRes
					DEALLOCATE curOperRes
					GOTO ROLLBACK_SECTION
					
					END
				ELSE
					BEGIN
--SELECT @iCodeRetour	AS iCodeRetour
						INSERT INTO #tblTEMP_AssociationOperations
						VALUES (@iCodeRetour,@iID_Raison_Association)
					END
				
				END

			FETCH NEXT FROM curOperRes 
				INTO @iID_Operation_Enfant
				
			END
			
		CLOSE curOperRes
		DEALLOCATE curOperRes
	
	------------------------------------------------------------------------------------
	-- Dynamique 1: Créer une opération « RIO » d’annulation.
	------------------------------------------------------------------------------------
		IF @dtDate_Operation > @dtAujourdhui -- FT1
			EXEC @iOperID = SP_IU_UN_Oper	 @iID_Connexion
											,0
											,@vcOperType
											,@dtDate_Operation
		ELSE
			EXEC @iOperID = SP_IU_UN_Oper	 @iID_Connexion
											,0
											,@vcOperType
											,@dtAujourdhui

		IF @@Error <> 0
				GOTO ROLLBACK_SECTION
	
	-------------------------------------------
	-- Actualiser les associations d'opérations
	-------------------------------------------
		INSERT INTO tblOPER_AssociationOperations
			(
			 iID_Operation_Parent
			,iID_Operation_Enfant
			,iID_Raison_Association
			)
		SELECT @iOperID,
			   AO.iID_Operation_Enfant,
			   AO.iID_Raison_Association
		FROM #tblTEMP_AssociationOperations AO

	----------------------------------------------------------------------------------------------------
	-- Dynamique 2: Créer un enregistrement de lien entre l’opération d’annulation et l’opération annulée 
	----------------------------------------------------------------------------------------------------
		INSERT INTO Un_OperCancelation
			   (OperSourceID,
				OperID)
		VALUES
			   (@iID_Oper_RIO, @iOperID)

		IF @@Error <> 0
				GOTO ROLLBACK_SECTION

	----------------------------------------------------------------------------------------------------
	-- Dynamique 3: Créer un enregistrement dans la table des détails des opérations RIO  
	--					(tblOPER_OperationsRIO) pour l’opération d’annulation)
	----------------------------------------------------------------------------------------------------

		-- Creer l'enregistrement dans la table des details
		INSERT INTO tblOPER_OperationsRIO
			   (dtDate_Enregistrement
			   ,iID_Oper_RIO
			   ,iID_Convention_Source
			   ,iID_Unite_Source
			   ,iID_Convention_Destination
			   ,iID_Unite_Destination
			   ,bRIO_Annulee
			   ,bRIO_QuiAnnule
			   ,tblOPER_OperationsRIO.OperTypeID)
		 VALUES
			   (GETDATE()
			   ,@iOperID
			   ,@iIDConventionDestination
			   ,@iIDUniteDestination
			   ,@iIDConventionSource
			   ,@iIDUniteSource
			   ,0
			   ,1
			   ,@vcOperType)

		IF @@Error <> 0
				GOTO ROLLBACK_SECTION

	----------------------------------------------------------------------------------------------------
	-- Dynamique 4: Mettre à jour le détail de la transaction RIO annulée pour identifier qu’elle a été annulée
	----------------------------------------------------------------------------------------------------

		-- Mettre à jour le detail de la transaction RIO 
		UPDATE tblOPER_OperationsRIO
		SET bRIO_Annulee = 1
		WHERE iID_Oper_RIO = @iID_Oper_RIO 

		IF @@Error <> 0
				GOTO ROLLBACK_SECTION
		
	----------------------------------------------------------------------------------------------------
	-- Dynamique 5: Renverser chaque transaction de cotisation (Un_Cotisation)
	----------------------------------------------------------------------------------------------------

		DECLARE curTransactions CURSOR FOR
			--Initialiser les variables 
			SELECT C.Cotisation, C.Fee ,C.UnitID, C.EffectDate
			FROM Un_Cotisation C
			WHERE C.OperID = @iID_Oper_RIO

		OPEN curTransactions
		
		FETCH NEXT FROM curTransactions INTO @mtCotisationInversee, @mtFraisInverse, @iUnitIDCotisation, @dtDate_Effective

		WHILE @@FETCH_STATUS = 0
		BEGIN
			--signe inversé des cotisations	
			SET @mtCotisationInversee = @mtCotisationInversee * -1

			--signe inversé des frais	
			SET @mtFraisInverse = @mtFraisInverse * -1

			--Utiliser le service SP_IU_UN_Cotisation 
			EXEC @iCotisationID = SP_IU_UN_Cotisation @iID_Connexion,0,@iOperID,@iUnitIDCotisation,@dtDate_Effective,@mtCotisationInversee,@mtFraisInverse,0,0,0

			IF @@Error <> 0
			BEGIN	
					CLOSE curTransactions
					DEALLOCATE curTransactions
					GOTO ROLLBACK_SECTION
			END

			FETCH NEXT FROM curTransactions INTO @mtCotisationInversee, @mtFraisInverse, @iUnitIDCotisation, @dtDate_Effective
		END

		CLOSE curTransactions
		DEALLOCATE curTransactions

	-----------------------------------------------------------------------------------------------------------
	-- Dynamique 6: Renverser chaque transaction sur la convention (Un_ConventionOper) de l’opération à annuler
	------------------------------------------------------------------------------------------------------------
	
		DECLARE curTransactions CURSOR FOR
			--Initialiser les variables 
			SELECT Cop.ConventionOperAmount,
				   Cop.ConventionID,
				   Cop.ConventionOperTypeID  	
			FROM Un_ConventionOper Cop
			WHERE Cop.OperID = @iID_Oper_RIO

		OPEN curTransactions

		FETCH NEXT FROM curTransactions INTO @mtMontInverseConvention, @iIDConvention, @vcConventionOperTypeID

		WHILE @@FETCH_STATUS = 0
		BEGIN
			--Signe inversé des montant dela transaction à renverser	
			SET @mtMontInverseConvention = @mtMontInverseConvention * -1

			--Utiliser le service SP_IU_UN_ConventionOper 
			EXEC SP_IU_UN_ConventionOper @iID_Connexion,0,@iIDConvention,@iOperID,@vcConventionOperTypeID,@mtMontInverseConvention

			IF @@Error <> 0
			BEGIN
					CLOSE curTransactions
					DEALLOCATE curTransactions
					GOTO ROLLBACK_SECTION
			END

			FETCH NEXT FROM curTransactions INTO @mtMontInverseConvention, @iIDConvention, @vcConventionOperTypeID
		END

		CLOSE curTransactions
		DEALLOCATE curTransactions		

	-----------------------------------------------------------------------------------------------------------
	-- Dynamique 8:Renverser chaque transaction sur les subventions fédérale (Un_CESP) de l’opération à annuler
	------------------------------------------------------------------------------------------------------------

		INSERT INTO Un_CESP	
				 ([ConventionID]
				   ,[OperID]
				   ,[CotisationID]
				   ,[OperSourceID]
				   ,[fCESG]
				   ,[fACESG]
				   ,[fCLB]
				   ,[fCLBFee]
				   ,[fPG]
				   ,[vcPGProv]
				   ,[fCotisationGranted])
		(SELECT ConventionID,
				@iOperID,
				CotisationID,
				@iOperID,
				(fCESG * -1),
				(fACESG * -1),
				(fCLB * -1),
				(fCLBFee * -1),
				(fPG * -1),
				 vcPGProv,
				fCotisationGranted
				FROM Un_CESP
		WHERE OperID = @iID_Oper_RIO)

		IF @@Error <> 0
				GOTO ROLLBACK_SECTION

	--------------------------------------------------------------------------------------------
	-- Dynamique 9 : Supprimer les transactions 400 à la subvention canadienne (Un_CESP400) 
	--------------------------------------------------------------------------------------------
		DELETE FROM Un_CESP400	
		WHERE  iCESPSendFileID IS NULL
				AND OperID = @iID_Oper_RIO

		IF @@Error <> 0
				GOTO ROLLBACK_SECTION

	--------------------------------------------------------------------------------------------
	-- Dynamique 10 : créer de nouvelles transactions 400 de transfert pour chaque transfert associé à l’opération 
	--------------------------------------------------------------------------------------------
		-- Test s'il existent des transactions 400 a la subvention canadienne (Un_CESP400)
		IF EXISTS(SELECT *
				  FROM Un_CESP400
				  WHERE iCESPSendFileID IS NOT NULL	
				  AND OperID = @iID_Oper_RIO)
			BEGIN			
				--Creer nouvelle transaction 400 de type 23 (transfert sortie)
				EXEC IU_UN_CESP400ForOper @iID_Connexion,@iOperID,230,0

				IF @@Error <> 0
						GOTO ROLLBACK_SECTION

				--Creer nouvelle transaction 400 de type 23 (transfert entrée)
				EXEC IU_UN_CESP400ForOper @iID_Connexion,@iOperID,190,0

				IF @@Error <> 0
						GOTO ROLLBACK_SECTION
			END

	--------------------------------------------------------------------------------------------
	-- Renverser les réductions d'unités
	--------------------------------------------------------------------------------------------
		--IF @vcOperType = 'RIO' OR @vcOperType = 'RIM'
		IF @vcOperType = 'RIM' OR @vcOperType = 'TRI'
			BEGIN
			
			DECLARE  @iOldUnitReductionID	INTEGER
					,@iUnitReductionID		INTEGER
			
			SET @iOldUnitReductionID = 0
			SET @iUnitReductionID = 0

			SELECT @iOldUnitReductionID = UR.UnitReductionID
			FROM Un_Cotisation CT
			JOIN Un_UnitReductionCotisation UR ON UR.CotisationID = CT.CotisationID
			WHERE CT.OperID = @iID_Oper_RIO

			IF 	@iOldUnitReductionID > 0
				BEGIN

				INSERT INTO Un_UnitReduction
								(
								UnitID,
								ReductionConnectID,
								ReductionDate,
								UnitQty,
								FeeSumByUnit,
								SubscInsurSumByUnit,
								UnitReductionReasonID,
								NoChequeReasonID
								)
							SELECT
								UnitID,
								@iID_Connexion,
								dbo.FN_CRQ_DateNoTime(GETDATE()),
								UnitQty * -1,
								FeeSumByUnit,
								SubscInsurSumByUnit,
								UnitReductionReasonID,
								NoChequeReasonID
							FROM Un_UnitReduction
							WHERE UnitReductionID = @iOldUnitReductionID

				-- Erreur l'insertion d'un historique de réduction d'unités
				IF @@ERROR <> 0
					GOTO ROLLBACK_SECTION
				ELSE
					SET @iUnitReductionID = SCOPE_IDENTITY()
			
				END

			IF 	@iUnitReductionID > 0
				BEGIN
				
				INSERT INTO Un_UnitReductionCotisation
								(
								UnitReductionID,
								CotisationID
								)
							SELECT
								@iUnitReductionID,
								CT.CotisationID
							FROM Un_Cotisation CT
							WHERE CT.CotisationID = @iCotisationID

				-- Erreur l'insertion de lien entre historique de réduction d'unités et les cotisations
				IF @@ERROR <> 0
					GOTO ROLLBACK_SECTION
				
				END

			IF	@iOldUnitReductionID > 0
				BEGIN
				
				UPDATE dbo.Un_Unit 
				SET	TerminatedDate = NULL,
					UnitQty = UN.UnitQty + (UR.UnitQty * -1)
				FROM dbo.Un_Unit UN
				JOIN Un_UnitReduction UR ON UR.UnitID = UN.UnitID
				WHERE UR.UnitReductionID = @iUnitReductionID
				
				-- Erreur lors de la mise à jour de groupe d'unités
				IF @@ERROR <> 0
					GOTO ROLLBACK_SECTION
				
				END

			END
			
	--------------------------------------------------------------------------------------------
	-- Dynamique 11 : Mettre à jour le groupe d’unités de la convention collective de l’opération 
	--------------------------------------------------------------------------------------------

		--Initialiser les variables 
		SELECT @iIDUniteSource = OpRIO.iID_Unite_Source,
			   @iIDUniteDestination = OpRIO.iID_Unite_Destination,
			   @iIDConventionDestination = OpRIO.iID_Convention_Destination 
		FROM tblOPER_OperationsRIO OpRIO
		WHERE OpRIO.iID_Oper_RIO = @iID_Oper_RIO

		IF NOT EXISTS (SELECT *
						FROM tblOPER_OperationsRIO
						WHERE iID_Unite_Source = @iIDUniteSource AND
							  bRIO_Annulee = 0 AND
							  bRIO_QuiAnnule = 0)
			BEGIN
				UPDATE dbo.Un_Unit 
				SET IntReimbDate = NULL
				WHERE UnitID = @iIDUniteSource

				IF @@Error <> 0
						GOTO ROLLBACK_SECTION
			END

	--------------------------------------------------------------------------------------------
	-- Dynamique 12 : Ramener le groupe d’unités de la convention collective de l’opération à annuler 
	--			(tblOPER_OperationsRIO.iID_Unite_Source) à l’étape 3 de l’outil RIN 
	--------------------------------------------------------------------------------------------

		IF @vcOperType = 'RIO' OR @vcOperType = 'RIM' -- FT1
			BEGIN
			
			IF NOT EXISTS (SELECT *
							FROM tblOPER_OperationsRIO
							WHERE iID_Unite_Source = @iIDUniteSource AND
								  bRIO_Annulee = 0 AND
								  bRIO_QuiAnnule = 0)
				BEGIN
					INSERT INTO Un_IntReimbStep (
							UnitID,
							iIntReimbStep,
							dtIntReimbStepTime,
							ConnectID )
					SELECT
							@iIDUniteSource,
							3,
							@dtAujourdhui,
							@iID_Connexion
					
					IF @@Error <> 0
							GOTO ROLLBACK_SECTION
				END
			
			END
			
	--------------------------------------------------------------------------------------------
	-- Dynamique 13 : Réévaluer la date de fin du régime de la convention individuelle 
	--						de destination de l’opération RIO annulée
	--------------------------------------------------------------------------------------------

	-- S'il y des opérations RIO restante dans l'individuel
	IF EXISTS(  SELECT O.iID_Oper_RIO
				FROM tblOPER_OperationsRIO O
					 JOIN dbo.Un_Convention C ON C.ConventionID = O.iID_Convention_Source
				WHERE O.iID_Convention_Destination = @iIDConventionDestination AND
					  O.bRIO_Annulee = 0 AND
					  O.bRIO_QuiAnnule = 0 AND
					  O.iID_Oper_RIO <> @iID_Oper_RIO)
		BEGIN
			-- Déterminer la date de fin la plus ancienne des conventions collectives sources
			-- ayant menée à la convention individuelle de destination
			DECLARE 
				@iID_Convention_Restante INT,
				@dtDateTMP DATETIME

			DECLARE curConventionsRestantes CURSOR FOR
				SELECT C.ConventionID
				FROM tblOPER_OperationsRIO O
					 JOIN dbo.Un_Convention C ON C.ConventionID = O.iID_Convention_Source
				WHERE O.iID_Convention_Destination = @iIDConventionDestination AND
					  O.bRIO_Annulee = 0 AND
					  O.bRIO_QuiAnnule = 0 AND
					  O.iID_Oper_RIO <> @iID_Oper_RIO

			OPEN curConventionsRestantes
			FETCH NEXT FROM curConventionsRestantes INTO @iID_Convention_Restante
			SET @dtRegEndDateAdjust = NULL
			WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @dtDateTMP = (SELECT [dbo].[fnCONV_ObtenirDateFinRegime](@iID_Convention_Restante,'R',NULL))

				IF @dtRegEndDateAdjust IS NULL OR @dtDateTMP < @dtRegEndDateAdjust
					SET @dtRegEndDateAdjust = @dtDateTMP

				FETCH NEXT FROM curConventionsRestantes INTO @iID_Convention_Restante
			END
			CLOSE curConventionsRestantes
			DEALLOCATE curConventionsRestantes

			-- Mettre à jour la date de fin de régime de la convention individuelle
			EXEC IU_UN_ConvRegEndDateAdjust @iIDConventionDestination,@dtRegEndDateAdjust
			
			IF @@Error <> 0
				GOTO ROLLBACK_SECTION
		END
		
	--------------------------------------------------------------------------------------------
	-- Dynamique 14 : Réviser les statuts des groupes d’unités et les statuts autant de la 
	--					convention collective que de la convention individuelle
	--------------------------------------------------------------------------------------------

		SET @vcUnitIDs = CAST(@iIDUniteSource AS VARCHAR) + ','+ CAST(@iIDUniteDestination AS VARCHAR)

		--Utiliser le service TT_UN_ConventionAndUnitStateForUnit
		EXEC  TT_UN_ConventionAndUnitStateForUnit @vcUnitIDs 

		IF @@Error <> 0
				GOTO ROLLBACK_SECTION

COMMIT_SECTION:

	COMMIT TRANSACTION
	GOTO END_TRANSACTION	

--=====================================================================================================
-- A ce point, la transaction n'a pas fonctionné.  On effectue un ROLLBACK et on quitte la procédure.
--=====================================================================================================
ROLLBACK_SECTION:

	SET @iCode_Retour = -1
	
	ROLLBACK TRANSACTION
--=====================================================================================================
-- Libellé de fin de procédure.
--=====================================================================================================
END_TRANSACTION:	
--===========================================
	
	-- Activer Trigger TUn_Unit_State
	--;ENABLE TRIGGER TUn_Unit_State ON Un_Unit 
	Delete #DisableTrigger where vcTriggerName = 'TUn_Unit_State'

	--Activer le service (Trigger)TUn_Cotisation_State
	--;ENABLE TRIGGER TUn_Cotisation_State ON Un_Cotisation
	Delete #DisableTrigger where vcTriggerName = 'TUn_Cotisation_State'

	--Activer le service (Trigger)TUn_Cotisation_Doc
	--;ENABLE TRIGGER TUn_Cotisation_Doc ON Un_Cotisation
	Delete #DisableTrigger where vcTriggerName = 'TUn_Cotisation_Doc'

	RETURN @iCode_Retour 

END


