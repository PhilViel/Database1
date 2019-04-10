/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc

Code de service		:		psOPER_SupprimerOperationRIO
Nom du service		:		Supprimer une opération RIO 
But					:		Supprimer toutes les informations relatives à une opération RIO.
							
Facette				:		OPER
Reférence			:		UniAccès-Unité-OPER

Parametres d'entrée :	Parametres					Description
						------------------     -------------------------------------------------------------------------------
						iID_Oper_RIO			Identifiant de l'operation RIO à supprimer
						iID_Connexion			Identifiant de la connection

Exemple d'appel:
				@iID_Oper_RIO = 17184476, --ID de l'opération RIO à supprimer
				@iID_Connexion = 1, --ID de la connection
						
Parametres de sortie : Table						Champs								Description
					   -----------------			---------------------------			--------------------------
					   S/O							iCode_Retour						Code de deroulement du traitement :
																						0 = Opération réussie
																						< 0 = Erreur de traitement

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2008-06-19					Nassim Rekkab							Création de procédure stockée
						2008-11-24					Josée Parent							Modification pour utiliser la fonction "fnCONV_ObtenirDateFinRegime"
						2010-10-04					Steve Gouin								Gestion des disable trigger par #DisableTrigger
						2011-03-30					Frédérick Thibault						Ajout des fonctionnalité du prospectus 2010-2011 (FT1)
						2011-7-28					Frédérick Thibault						Modification pour les statuts des bourses sur RIM et TRI
						
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_SupprimerOperationRIO] (

	@iID_Oper_RIO INTEGER,  
	@iID_Connexion INTEGER
)
AS
BEGIN
	DECLARE 
			@iCodeSuppression INTEGER,
			@iUnitDestination INTEGER,
			@iUnitSource INTEGER,
			@vcUnitIDs VARCHAR(800),
			@dtFinRegime DATETIME,	
			@iConventionDest INTEGER,
			@iConventionSource INTEGER,
			@bSupprime BIT,
			@iCode_Retour INTEGER
			,@vcOperType			VARCHAR(3)	-- FT1
			,@dtDate_Operation		DATETIME	-- FT1
			,@iIDConventionSource	INTEGER		-- FT1
			,@iID_Operation_Enfant	INTEGER		-- FT1
			,@vcOperType_Enfant		VARCHAR(3)	-- FT1
			,@vcCode_Message		VARCHAR(10)	-- FT1

	----------------------------
	BEGIN TRANSACTION
	----------------------------
		
	SET @iCode_Retour = 0
	
	-- Obtention du type et de la date d'opération de conversion - FT1
	SELECT	 @vcOperType		= OperTypeID
			,@dtDate_Operation	= OperDate
	FROM Un_Oper
	WHERE OperID = @iID_Oper_RIO
	
	------------------------------------------------------------------------------------
	-- Suppression des opérations enfants (si présentes) - FT1
	------------------------------------------------------------------------------------
		DECLARE curOperEnf CURSOR FOR
			--Initialiser les variables 
			SELECT iID_Operation_Enfant
			FROM tblOPER_AssociationOperations
			WHERE iID_Operation_Parent = @iID_Oper_RIO

		OPEN curOperEnf

		FETCH NEXT FROM curOperEnf 
			INTO @iID_Operation_Enfant
		
		WHILE @@FETCH_STATUS = 0
			BEGIN
			
			SET @vcOperType_Enfant = (	SELECT OperTypeID
										FROM Un_Oper
										WHERE OperID = @iID_Operation_Enfant)
-- TEST
--SELECT @vcOperType_Enfant, @iID_Operation_Enfant
			
			-- Suppression d'une opération de frais
			IF @vcOperType_Enfant = 'FRS'
				EXEC @iCode_Retour = psOPER_SupprimerOperationFrais	 @iID_Operation_Enfant
																	,@vcCode_Message

			-- Suppression d'une opération de rendement INM (IN+)
			IF @vcOperType_Enfant = 'IN+'
				BEGIN

				DELETE FROM Un_ConventionOper
				WHERE OperID = @iID_Operation_Enfant

				DELETE FROM Un_Oper 
				WHERE OperID = @iID_Operation_Enfant
				
				END
				
			IF @@Error <> 0 --OR @iCode_Retour <= 0
				BEGIN

				CLOSE curOperEnf
				DEALLOCATE curOperEnf

				GOTO ROLLBACK_SECTION

				END
				
			FETCH NEXT FROM curOperEnf 
				INTO @iID_Operation_Enfant
			
			END
			
		CLOSE curOperEnf
		DEALLOCATE curOperEnf
	
	--------------------------------------------------------------------------------------------------
	-- Suppression de toute opération de résilisation (RES) et transfert de frais (TFR) post TRI - FT1
	--------------------------------------------------------------------------------------------------
		SELECT @iIDConventionSource = iID_Convention_Source
		FROM tblOPER_OperationsRIO
		WHERE iID_Oper_RIO = @iID_Oper_RIO
		
		DECLARE curOperTFR CURSOR FOR
			SELECT OP.OperID
			FROM Un_Convention	CN
			JOIN Un_Unit		UN ON UN.ConventionID = CN.ConventionID
			JOIN Un_Cotisation	CT ON CT.UnitID = UN.UnitID
			JOIN Un_Oper		OP ON OP.OperID = CT.OperID
			WHERE	UN.ConventionID	=  @iIDConventionSource
			AND		OP.OperDate		>= @dtDate_Operation
			--AND		OP.OperTypeID	IN ('RES', 'TFR')
			AND		OP.OperTypeID	= 'TFR'
			ORDER BY OP.OperID DESC
			
		OPEN curOperTFR
		
		FETCH NEXT FROM curOperTFR 
			INTO @iID_Operation_Enfant
		
		WHILE @@FETCH_STATUS = 0
			BEGIN
			
			IF @iID_Operation_Enfant IS NOT NULL
				BEGIN
				
				EXEC @iCode_Retour = DL_UN_Operation	 @iID_Connexion
													,@iID_Operation_Enfant

				IF @@Error <> 0 OR @iCode_Retour <= 0
					GOTO ROLLBACK_SECTION
				
				END

			FETCH NEXT FROM curOperTFR 
				INTO @iID_Operation_Enfant
				
			END
			
		CLOSE curOperTFR
		DEALLOCATE curOperTFR
	
	------------------------------------------------------------------------------------
	-- Dynamique 4: Supprime les transactions 400 à la subvention canadienne (Un_CESP400)
	-------------------------------------------------------------------------------------

		DELETE FROM Un_CESP400
		WHERE OperID = @iID_Oper_RIO

		IF @@Error <> 0
				GOTO ROLLBACK_SECTION

	--------------------------------------------------------------------------------
	-- Dynamique 3: Supprime les transactions de la subvention federale (Un_CESP)
	--------------------------------------------------------------------------------
	
		DELETE FROM  Un_CESP
		WHERE OperID = @iID_Oper_RIO

		IF @@Error <> 0
				GOTO ROLLBACK_SECTION

	--------------------------------------------------------------------------------
	-- Suppression des réduction d'unité 
	--------------------------------------------------------------------------------
		DELETE Un_UnitReductionCotisation
		FROM Un_UnitReductionCotisation URC
		JOIN Un_Cotisation CT ON CT.CotisationID = URC.CotisationID
		WHERE CT.OperID = @iID_Oper_RIO
		
	--------------------------------------------------------------------------------
	-- Dynamique 1 : Supprime les transactions de cotisation
	--------------------------------------------------------------------------------
		-- Suppression de la cotisation
		DELETE FROM Un_Cotisation
		WHERE OperID = @iID_Oper_RIO      

		IF @@Error <> 0
				GOTO ROLLBACK_SECTION
	
	--------------------------------------------------------------------------------
	-- Dynamique 2: Supprime les transactions sur la convention
	--------------------------------------------------------------------------------
	
		DELETE FROM Un_ConventionOper
		WHERE OperID = @iID_Oper_RIO

		IF @@Error <> 0
				GOTO ROLLBACK_SECTION

	------------------------------------------------------------------------------------
	-- Dynamique 8: mettre à jour le groupe d’unités de la convention collective de 
	--		l’opération (tblOPER_OperationsRIO.iID_Unite_Source
	-------------------------------------------------------------------------------------
		-- Desactiver Trigger TUn_Convention_State
		-- ;DISABLE TRIGGER TUn_Unit_State ON Un_Unit 
		IF object_id('tempdb..#DisableTrigger') is null
			CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))

		INSERT INTO #DisableTrigger VALUES('TUn_Unit_State')				

		SELECT @iUnitDestination = OpRIO.iID_Unite_Destination ,@iUnitSource = OpRIO.iID_Unite_Source,@iConventionDest = OpRIo.iID_Convention_Destination
		FROM tblOPER_OperationsRIO OpRIO
		WHERE OpRIO.iID_Oper_RIO = @iID_Oper_RIO		

		IF NOT EXISTS (SELECT *
						FROM tblOPER_OperationsRIO
						WHERE iID_Unite_Source = @iUnitSource AND
							  iID_Oper_RIO <> @iID_Oper_RIO AND
							  bRIO_Annulee = 0 AND
							  bRIO_QuiAnnule = 0)
			BEGIN
				UPDATE dbo.Un_Unit 
				SET IntReimbDate = NULL
				WHERE UnitID = @iUnitSource

				IF @@Error <> 0
						GOTO ROLLBACK_SECTION
			END

	-------------------------------------------------------------------------------------------------
	-- Dynamique 10 : Supprimer la convention et son groupe d’unités avec le service «DL_UN_Convention»
	-------------------------------------------------------------------------------------------------
		EXEC @iCode_Retour = VL_UN_Convention_DL @iConventionDest,1

		IF @@Error <> 0
				GOTO ROLLBACK_SECTION
		
		SET @bSupprime  = 0

		IF @iCode_Retour = 0  --si l'operation à supprimer rencontre les criteres de suppression
		BEGIN
			--Supprimer la convention et son groupe d'unités avec le service DL_UN_Convention
			EXEC @iCode_Retour = DL_UN_Convention @iID_Connexion,@iConventionDest

			IF @@Error <> 0
				GOTO ROLLBACK_SECTION

			IF  @iCode_Retour > 0 --si la suppression a reussie
						SET @bSupprime = 1
				
		END
		
	-------------------------------------------------------------------------------------------------
	-- Dynamique 11 : Si la convention individuelle de destination n'a pas été supprimée à l'étape 9, réévaluer
	-- la date de fin du régime de celle-ci
	-------------------------------------------------------------------------------------------------
		IF @bSupprime = 0
		BEGIN
			-- Il existe d'autres RIO sur la convention individuelle
			IF EXISTS(SELECT C.ConventionID
							FROM dbo.Un_Convention C JOIN tblOPER_OperationsRIO OpRIO ON (C.ConventionID=OpRIO.iID_Convention_source)
							WHERE OpRIO.iID_Convention_Destination = @iConventionDest AND
								  OpRIO.bRIO_Annulee = 0 AND
								  OpRIO.bRIO_QuiAnnule = 0 AND
								  OpRIO.iID_Oper_RIO <> @iID_Oper_RIO)
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
					WHERE O.iID_Convention_Destination = @iConventionDest AND
						  O.bRIO_Annulee = 0 AND
						  O.bRIO_QuiAnnule = 0 AND
						  O.iID_Oper_RIO <> @iID_Oper_RIO

				OPEN curConventionsRestantes
				FETCH NEXT FROM curConventionsRestantes INTO @iID_Convention_Restante
				SET @dtFinRegime = NULL
				WHILE @@FETCH_STATUS = 0
				BEGIN
					SET @dtDateTMP = (SELECT [dbo].[fnCONV_ObtenirDateFinRegime](@iID_Convention_Restante,'R',NULL))

					IF @dtFinRegime IS NULL OR @dtDateTMP < @dtFinRegime
						SET @dtFinRegime = @dtDateTMP

					FETCH NEXT FROM curConventionsRestantes INTO @iID_Convention_Restante
				END
				CLOSE curConventionsRestantes
				DEALLOCATE curConventionsRestantes

				-- Mettre à jour la date de fin de régime de la convention individuelle
				EXEC @iCode_Retour = IU_UN_ConvRegEndDateAdjust @iConventionDest,@dtFinRegime

				IF @@Error <> 0
						GOTO ROLLBACK_SECTION
			END
		END

	------------------------------------------------------------------------------------
	-- Ramener les unités au groupe d'unité
	-------------------------------------------------------------------------------------
		IF @vcOperType = 'RIM' OR @vcOperType = 'TRI' 
			BEGIN
			
			DECLARE  @UnitReductionID	MONEY
					,@UnitID			INTEGER
					,@UnitQty			MONEY
			
			SELECT	 @UnitReductionID	= max(UnitReductionID)
					,@UnitID			= UnitID
					,@UnitQty			= UnitQty
			FROM Un_UnitReduction UR
			JOIN tblOPER_OperationsRIO OpRIO ON OpRIO.iID_Unite_Source = UR.UnitID 
			WHERE OpRIO.iID_Oper_RIO = @iID_Oper_RIO
			GROUP BY	 UnitID
						,UnitQty
			
			-- Ramène les unités
			UPDATE dbo.Un_Unit 
			SET	 UnitQty = @UnitQty
				,TerminatedDate = NULL
			WHERE UnitID = @UnitID
			
			-- Supprime la réduction d'unités sur cotisation
			DELETE FROM Un_UnitReductionCotisation
			WHERE UnitReductionID = @UnitReductionID
			
			-- Supprime la réduction d'unités
			DELETE FROM Un_UnitReduction
			WHERE UnitReductionID = @UnitReductionID
			
			END

	------------------------------------------------------------------------------------
	-- Dynamique 5: Supprime le detail des operations RIO (tblOPER_OperationsRIO)
	-------------------------------------------------------------------------------------
		DELETE FROM tblOPER_OperationsRIO
		WHERE iID_Oper_RIO = @iID_Oper_RIO

		IF @@Error <> 0
				GOTO ROLLBACK_SECTION
	
	------------------------------------------------------------------------------------
	-- Dynamique 6: Supprimer le lien d’annulation entre l’opération RIO d’annulation et
	-- l’opération RIO annulée. (Un_OperCancelation) 
	-------------------------------------------------------------------------------------

		DELETE FROM Un_OperCancelation
		WHERE OperID = @iID_Oper_RIO OR OperSourceID = @iID_Oper_RIO

	------------------------------------------------------------------------------------
	-- Dynamique 7: Supprimer l’opération RIO (Un_Oper) 
	-------------------------------------------------------------------------------------

		DELETE FROM Un_Oper
		WHERE OperID = @iID_Oper_RIO

		IF @@Error <> 0
				GOTO ROLLBACK_SECTION

	------------------------------------------------------------------------------------
	-- Dynamique 9: Ramener le groupe d’unités de la convention collective de l’opération
	-- (tblOPER_OperationsRIO.iID_Unite_Source) à l’étape 3 
	-------------------------------------------------------------------------------------
		IF @vcOperType = 'RIO' OR @vcOperType = 'RIM' -- FT1
			BEGIN
			
			IF NOT EXISTS (SELECT *
							FROM tblOPER_OperationsRIO
							WHERE iID_Unite_Source = @iUnitSource AND
								  bRIO_Annulee = 0 AND
								  bRIO_QuiAnnule = 0)
				BEGIN
					INSERT INTO Un_IntReimbStep (
							UnitID,
							iIntReimbStep,
							dtIntReimbStepTime,
							ConnectID )
					SELECT
							@iUnitSource,
							3,
							GETDATE(),
							@iID_Connexion

					IF @@Error <> 0
							GOTO ROLLBACK_SECTION
				END

			END

	-----------------------------------------------------------------------------------------------------------
	-- Ramener le statut des bourses s'il y a lieu
	-----------------------------------------------------------------------------------------------------------
		IF @vcOperType = 'RIM' OR @vcOperType = 'TRI'
			BEGIN
			
			-- Sauvegarde des bourses à modifier
			DECLARE @tStatutBourses TABLE
						(
						 iID_Historique_Statut	INT
						,iID_Bourse				INT
						)
			
			INSERT INTO @tStatutBourses
						(
						 iID_Historique_Statut
						,iID_Bourse
						)
			SELECT	 HSB.iID_Historique_Statut
					,HSB.iID_Bourse
			FROM tblCONV_HistoriqueStatutBourse HSB
			JOIN tblOPER_LienOperationHistoriqueStatutBourse LHS ON LHS.iID_Historique_Statut = HSB.iID_Historique_Statut
			WHERE LHS.iID_Operation = @iID_Oper_RIO
			
			-- Va chercher les anciens code de statut des bourses à modifier
			DECLARE  @iID_Historique_Statut	INT
					,@iID_Bourse			INT
					,@vcCode_Statut			VARCHAR(3)
					
			DECLARE curStatut CURSOR FOR
				SELECT	 max(HSB.iID_Historique_Statut), HSB.iID_Bourse, SB.vcCode_Statut
				FROM tblCONV_HistoriqueStatutBourse HSB
				JOIN @tStatutBourses tSB ON tSB.iID_Bourse = HSB.iID_Bourse
				JOIN tblCONV_StatutBourse SB ON SB.iID_Statut = HSB.iID_Statut
				JOIN Un_Scholarship S ON S.ScholarshipID = tSB.iID_Bourse
				WHERE HSB.iID_Historique_Statut NOT IN (SELECT iID_Historique_Statut
														FROM @tStatutBourses
														)
				GROUP BY HSB.iID_Bourse, SB.vcCode_Statut

			OPEN curStatut

			FETCH NEXT FROM curStatut
				INTO @iID_Historique_Statut
					,@iID_Bourse
					,@vcCode_Statut
					
			WHILE @@FETCH_STATUS = 0
				BEGIN

				-- Mise à jour du statut dans la table des bourses
				UPDATE Un_Scholarship
				SET ScholarshipStatusID = @vcCode_Statut
				WHERE ScholarshipID = @iID_Bourse

				FETCH NEXT FROM curStatut
					INTO @iID_Historique_Statut
						,@iID_Bourse
						,@vcCode_Statut
				
				END
				
			CLOSE curStatut
			DEALLOCATE curStatut
			
			END
			
	-------------------------------------------------------------------------------------------------
	-- Dynamique 12: Réviser les statuts des groupes d'unités et les statuts autant de la convention 
	--	collective que la convention individuelle
	-------------------------------------------------------------------------------------------------

		if @bSupprime = 1
			SET @vcUnitIDs = CAST(@iUnitSource AS VARCHAR)
		else
			SET @vcUnitIDs = CAST(@iUnitSource AS VARCHAR) + ',' + CAST(@iUnitDestination AS VARCHAR)

		--Utiliser le service TT_UN_ConventionAndUnitStateForUnit pour reviser les statuts		
		EXEC @iCode_Retour = TT_UN_ConventionAndUnitStateForUnit @vcUnitIDs 							

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
	-- ;ENABLE TRIGGER TUn_Unit_State ON Un_Unit 
	Delete #DisableTrigger where vcTriggerName = 'TUn_Unit_State'
			
	RETURN @iCode_Retour 

END


